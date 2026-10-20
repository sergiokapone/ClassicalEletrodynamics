#!/usr/bin/env python3
"""Prepare the project for the lwarp HTML build (nothing in the chapters is modified).
 1. */Pictures/*.pdf  -> .svg   (lwarp cannot use PDF pictures; runs 'lwarpmk pdftosvg')
 2. */tikz/*.tikz that contain code BEFORE the first picture (\\tikzset, \\def, \\tdplotsetmaincoords...)
    break lwarp, because that code runs in HTML mode where '$' is not a math shift.
      - if the file is [code + one tikzpicture/circuitikz]: a copy in _html/ makes the WHOLE file one image
      - if the file is [code + subfigure/minipage/figure]: the code is hoisted into lwarp-tikzdefs.tex
        (preamble: '$' is still a math shift there) and removed from the copy in _html/
Usage:  python prepare_html.py [--no-pdf] [--placeholder]
        --placeholder: pictures that cannot be built are replaced by a box (the rest of the book still builds)"""
import glob, hashlib, os, re, shutil, subprocess, sys

def read(f):
    b = open(f, 'rb').read()
    try: return b.decode('utf-8').replace('\r', '')
    except UnicodeDecodeError: return b.decode('cp1251', errors='replace').replace('\r', '')

PICT = re.compile(r'\\begin\{(tikzpicture|circuitikz|axis|tikzcd)\}|\\tikz\b')
ANY  = re.compile(r'\\begin\{(tikzpicture|circuitikz|axis|tikzcd|subfigure|subcaptionblock|minipage|figure|SCfigure|wrapstuff)\}|\\tikz\b')

OPT = re.compile(r'\\begin\{(tikzpicture|circuitikz)\}\s*\[((?:[^\[\]{}]|\{(?:[^{}]|\{[^{}]*\})*\})*)\]', re.S)

EXT = '_html/ext'          # forward slashes: this path is written into .tex files
def externalize(code):
    """Compile one picture on its own (print mode) and convert it to SVG; returns (svg path or None, message)."""
    h = hashlib.md5(code.encode('utf-8')).hexdigest()[:10]
    svg = EXT + '/pic-' + h + '.svg'
    if os.path.exists(svg) and os.path.getsize(svg) > 0: return svg, 'cached'
    work = os.path.abspath(os.path.join(EXT, 'work-' + h)); os.makedirs(work, exist_ok=True)
    open(os.path.join(work, 'p.tex'), 'w', encoding='utf-8').write(
        '\\documentclass{ConspectBookHTML}\n\\begin{document}\n\\thispagestyle{empty}\n' + code + '\n\\end{document}\n')
    for aux in ('ConspectBookHTML.cls', 'lwarp-mathjax.tex', 'lwarp-tikzdefs.tex'):
        if os.path.exists(aux): shutil.copy(aux, work)
    for old in glob.glob(os.path.join(work, 'p.*')):          # stale files of an earlier failed run
        if not old.endswith('p.tex'): os.remove(old)
    env = dict(os.environ, TEXINPUTS=os.getcwd().replace(os.sep, '/') + '//' + os.pathsep + os.environ.get('TEXINPUTS', ''))
    def run(cmd):
        try:
            r = subprocess.run(cmd, cwd=work, env=env, capture_output=True, text=True, errors='replace')
        except FileNotFoundError:
            return 'program not found: ' + cmd[0]
        return None if r.returncode == 0 else 'exit code %d' % r.returncode
    for name, cmd in (('lualatex', ['lualatex', '-shell-escape', '-interaction=nonstopmode', '-halt-on-error', 'p.tex']),
                      ('pdfcrop', ['pdfcrop', 'p.pdf', 'pc.pdf']),
                      ('pdftocairo', ['pdftocairo', '-svg', 'pc.pdf', 'out.svg'])):
        err = run(cmd)
        if err:
            detail = ''
            if name == 'lualatex':
                try:
                    lines = open(os.path.join(work, 'p.log'), encoding='utf-8', errors='replace').read().split('\n')
                    i = next(k for k, l in enumerate(lines) if l.startswith('!'))
                    opened = [l.strip()[:120] for l in lines[:i] if 'lwarp' in l.lower() and ('.sty' in l or '.cls' in l or '.tex' in l)]
                    detail = '\n        | ' + '\n        | '.join(l[:110] for l in lines[i:i + 7])
                    detail += '\n        | files with "lwarp" opened before the error (last 10):\n        |   ' + '\n        |   '.join(opened[-10:])
                except (OSError, StopIteration):
                    detail = ' (no error line found in p.log)'
            return None, '%s failed (%s); log: %s%s' % (name, err, os.path.join(work, 'p.log'), detail)
    os.makedirs(EXT, exist_ok=True); shutil.copy(os.path.join(work, 'out.svg'), svg)
    shutil.rmtree(work, ignore_errors=True)
    return svg, 'compiled'

def wrap_pic_options(t):
    """A tikzpicture whose option list defines a pic (name/.pic={...}) breaks newer pgf+lwarp in HTML mode
    (\\tikz@smuggle@pics@in): such a picture is compiled alone into an SVG (fallback: wrapped into lateximage)."""
    out, pos, n = [], 0, 0
    for m in OPT.finditer(t):
        if m.start() < pos or not re.search(r'/\.pic\b', m.group(2)): continue
        end = t.find('\\end{%s}' % m.group(1), m.end())
        if end < 0: continue
        end += len('\\end{%s}' % m.group(1))
        code = t[m.start():end]
        svg, msg = externalize(code)                 # preferred: a plain SVG, no tikz in the HTML pass
        print('    picture with .pic in options -> %s' % (('SVG ' + msg) if svg else ('PLACEHOLDER box (--placeholder): ' if '--placeholder' in sys.argv else 'FALLBACK lateximage (the HTML pass will probably fail on new pgf/lwarp): ') + msg))
        if svg: rep = '\\htmlpicture{%s}' % svg
        elif '--placeholder' in sys.argv: rep = '\\fbox{[рисунок не перенесено в HTML]}'
        else:   rep = '\\begin{lateximage}[figure]\n' + code + '\n\\end{lateximage}'   # fallback
        out.append(t[pos:m.start()] + rep)
        pos = end; n += 1
    out.append(t[pos:])
    return ''.join(out), n

CAP = re.compile(r'\\(?:caption|captionof\{[^}]*\}|tabcaption|figcaption)\*?(?:\[[^\]]*\])?\{')
def wrap_ce(s):
    r"""Text-mode \ce{...} -> $\ce{...}$ (lwarp 0.922 breaks on a text-mode \ce inside a caption)."""
    out, i, math, n = [], 0, False, 0
    while i < len(s):
        if s.startswith('\\$', i):  out.append('\\$'); i += 2; continue
        if s[i] == '$':             math = not math; out.append('$'); i += 1; continue
        if s.startswith('\\(', i):  math = True; out.append('\\('); i += 2; continue
        if s.startswith('\\)', i):  math = False; out.append('\\)'); i += 2; continue
        if not math and s.startswith('\\ce{', i):
            j, d = i + 4, 1
            while j < len(s) and d:
                d += (s[j] == '{') - (s[j] == '}'); j += 1
            out.append('$' + s[i:j] + '$'); i = j; n += 1; continue
        out.append(s[i]); i += 1
    return ''.join(out), n
def fix_captions(t):
    out, pos, total = [], 0, 0
    for m in CAP.finditer(t):
        if m.start() < pos: continue
        i, d = m.end(), 1
        while i < len(t) and d:
            if t[i] == '{' and t[i-1] != '\\': d += 1
            elif t[i] == '}' and t[i-1] != '\\': d -= 1
            i += 1
        new, n = wrap_ce(t[m.end():i-1])
        if n: out.append(t[pos:m.end()] + new + '}'); pos = i; total += n
    out.append(t[pos:])
    return ''.join(out), total

# ---------------------------------------------------------------------------------------------
# tabularray (tblr) -> tabularx.  lwarp cannot read tblr; this converter handles what the book uses:
#   colspec with X[..]/Q[..]/l/c/r, row{..}={..}, cell{..}{..}={..} (c/l/r, bg, fg, font, mode=dmath/math),
#   hlines, vlines.  Anything else: the table is left alone (class: it becomes an image).
# ---------------------------------------------------------------------------------------------
KEEP_COLUMN_COLORS = False   # tblr column tints (Q[..,bg=..]): lwarp writes them as <div> inside <p> (invalid HTML)

class Unsupported(Exception): pass

def strip_comments(s):
    return re.sub(r'(?<!\\)%[^\n]*', '', s)

def split_commas(s):
    parts, cur, d = [], [], 0
    for c in s:
        if c in '{[': d += 1
        elif c in '}]': d -= 1
        if c == ',' and d == 0: parts.append(''.join(cur)); cur = []
        else: cur.append(c)
    parts.append(''.join(cur))
    return [p.strip() for p in parts if p.strip()]

def split_top(s, sep):
    """Split at top-level '&' or '\\\\' (outside braces and \\begin..\\end environments)."""
    parts, cur, depth, env, i = [], [], 0, 0, 0
    while i < len(s):
        c = s[i]
        if c == '\\':
            if s.startswith('\\\\', i):
                if sep == '\\\\' and depth == 0 and env == 0:
                    parts.append(''.join(cur)); cur = []; i += 2
                    m = re.match(r'[ \t]*\[[^\]\n]*\]', s[i:])
                    if m: i += m.end()
                    continue
                cur.append('\\\\'); i += 2; continue
            m = re.match(r'\\(begin|end)\{[^}]*\}', s[i:])
            if m:
                env += 1 if m.group(1) == 'begin' else -1
                cur.append(m.group(0)); i += m.end(); continue
            cur.append(s[i:i+2]); i += 2; continue
        if c == '{': depth += 1
        elif c == '}': depth -= 1
        elif c == '&' and sep == '&' and depth == 0 and env == 0:
            parts.append(''.join(cur)); cur = []; i += 1; continue
        cur.append(c); i += 1
    parts.append(''.join(cur))
    return parts

def strip_braces(v):
    v = v.strip()
    return v[1:-1] if v.startswith('{') and v.endswith('}') else v

def parse_selector(sel, n):
    """tabularray index selector -> set of 1-based indices (n = number of rows/columns)."""
    out = set()
    for tok in split_commas(strip_braces(sel)):
        tok = tok.strip()
        if tok == 'odd': out |= set(range(1, n + 1, 2))
        elif tok == 'even': out |= set(range(2, n + 1, 2))
        elif re.fullmatch(r'\d+', tok): out.add(int(tok))
        else:
            m = re.fullmatch(r'(\d*)\s*-\s*(\d*|Z)', tok)
            if not m: raise Unsupported('selector ' + tok)
            a = int(m.group(1)) if m.group(1) else 1
            b = n if (m.group(2) in ('', 'Z')) else int(m.group(2))
            out |= set(range(a, b + 1))
    return out

MEASURE = re.compile(r'^\d*\.?\d+(cm|mm|pt|em|ex|in)$')
def parse_keys(val, allow_width=False):
    """'c, m, fg=white, bg=x, font=\\bfseries' -> dict(align, bg, fg, font, mode, width)."""
    st = {}
    for it in split_commas(strip_braces(val)):
        if '=' in it:
            k, v = [x.strip() for x in it.split('=', 1)]
            if k in ('bg', 'fg', 'font', 'mode'): st[k] = v
            else: raise Unsupported('key ' + k)
        elif it in ('l', 'c', 'r'): st['align'] = it
        elif it in ('m', 't', 'b', 'h', 'f'): pass
        elif re.fullmatch(r'\d*\.?\d+', it): pass                       # weight of X or a row height number
        elif MEASURE.match(it):
            if allow_width: st['width'] = it                            # Q[..,4cm,..]
        else: st['bg'] = it                                             # a bare colour means bg
    return st

ALIGN = {'l': '\\raggedright', 'c': '\\centering', 'r': '\\raggedleft'}
def col_spec(c, vlines, first, color=True):
    kind, al, w = c['kind'], c.get('align', 'l'), c.get('width')
    pre = ('\\columncolor{%s}' % c['bg']) if (c.get('bg') and color and KEEP_COLUMN_COLORS) else ''
    if kind in 'lcr' and not w and not pre: body = kind
    elif w: body = '>{%s%s\\arraybackslash}p{%s}' % (pre, ALIGN[al], w)
    else:   body = '>{%s%s\\arraybackslash}%s' % (pre, ALIGN[al], 'X' if kind in 'XQ' else kind)
    return ('|' if (vlines and first) else '') + body + ('|' if vlines else '')

def tblr_to_tabularx(opts, body):
    opts = strip_comments(opts)
    cols, rowstyles, cellstyles, hl, vl = None, [], [], False, False
    for item in split_commas(opts):
        m = re.match(r'(\w+)\s*((?:\{[^{}]*\}\s*)*)(?:=\s*(.*))?$', item, re.S)
        if not m: raise Unsupported('option ' + item[:30])
        key, sels, val = m.group(1), re.findall(r'\{([^{}]*)\}', m.group(2)), m.group(3)
        if key == 'colspec':
            cols = []
            cs = strip_braces(val).replace('|', '')
            for cm in re.finditer(r'([XQ])\s*\[((?:[^\[\]{}]|\{[^{}]*\})*)\]|([lcrXQ])', cs):
                if cm.group(3): cols.append({'kind': cm.group(3)}); continue
                d = parse_keys(cm.group(2), allow_width=True); d['kind'] = cm.group(1); cols.append(d)
        elif key == 'hlines': hl = True
        elif key == 'vlines': vl = True
        elif key == 'row' and len(sels) == 1: rowstyles.append((sels[0], parse_keys(val)))
        elif key == 'cell' and len(sels) == 2: cellstyles.append((sels[0], sels[1], parse_keys(val)))
        else: raise Unsupported(key)
    if not cols: raise Unsupported('no colspec')
    rows = [r for r in split_top(strip_comments(body), '\\\\')]
    rows = [r for r in rows if r.strip()]
    cells = [[c.strip() for c in split_top(r, '&')] for r in rows]
    width = max(len(c) for c in cells)
    cols += [{'kind': 'l'}] * (width - len(cols))       # tabularray adds missing columns (default l)
    ncol = len(cols)
    cells = [cs + [''] * (ncol - len(cs)) for cs in cells]
    nrow = len(cells)
    out = ['\\begin{tabularx}{\\linewidth}{%s}' % ''.join(col_spec(c, vl, i == 0) for i, c in enumerate(cols))]
    if hl: out.append('\\hline')
    for ri, cs in enumerate(cells, 1):
        rst = {}
        for sel, st in rowstyles:
            if ri in parse_selector(sel, nrow): rst.update(st)
        line = ['\\rowcolor{%s}' % rst['bg']] if 'bg' in rst else []
        parts = []
        for ci, txt in enumerate(cs, 1):
            col = cols[ci - 1]
            st = {k: col[k] for k in ('fg', 'font') if k in col}
            st['align'] = col.get('align', 'l')
            st.update({k: v for k, v in rst.items() if k != 'bg'})
            for rsel, csel, cst in cellstyles:
                if ri in parse_selector(rsel, nrow) and ci in parse_selector(csel, ncol): st.update(cst)
            t = wrap_ce(txt)[0] if txt else ''
            if t and st.get('mode') == 'dmath': t = '$\\displaystyle ' + t + '$'
            elif t and st.get('mode') == 'math': t = '$' + t + '$'
            if t and st.get('font'):
                fnt = st['font']
                if '\\bfseries' in fnt: t = '\\textbf{%s}' % t
                if '\\itshape' in fnt: t = '\\textit{%s}' % t
                # size and family declarations have no inline form in lwarp (<div> inside <p>): dropped in HTML
            if t and st.get('fg'): t = '\\textcolor{%s}{%s}' % (st['fg'], t)
            if 'bg' not in rst and st.get('bg'): t = '\\cellcolor{%s}%s' % (st['bg'], t)   # only for cell{..}{..}={bg=..}
            if st['align'] != col.get('align', 'l') or col['kind'] in 'lcr' and st['align'] != col['kind']:
                spec = ('|' if (vl and ci == 1) else '') + st['align'] + ('|' if vl else '')   # plain c/l/r: lwarp does not parse >{\centering}
                t = '\\multicolumn{1}{%s}{%s}' % (spec, t)
            parts.append(t)
        out.append(''.join(line) + ' & '.join(parts) + ' \\\\' + (' \\hline' if hl else ''))
    out.append('\\end{tabularx}')
    return '\n'.join(out)

def convert_tables(t):
    """Replace every convertible tblr environment; returns (text, converted, [(reason, line)])."""
    res, pos, conv, skipped = [], 0, 0, []
    for m in re.finditer(r'\\begin\{tblr\}', t):
        if m.start() < pos: continue
        ls = t.rfind('\n', 0, m.start()) + 1
        if re.search(r'(?<!\\)%', t[ls:m.start()]): continue                 # commented-out table
        i = m.end()
        while i < len(t) and t[i] in ' \t\n': i += 1
        if t[i:i+1] == '[':                                                  # [outer, inner] spec of tblr
            skipped.append(('outer specification [..]', t[:m.start()].count('\n') + 1)); continue
        if t[i:i+1] != '{': continue
        j, d = i + 1, 1
        while j < len(t) and d:
            d += (t[j] == '{') - (t[j] == '}'); j += 1
        end = t.find('\\end{tblr}', j)
        if end < 0: continue
        try:
            new = tblr_to_tabularx(t[i+1:j-1], t[j:end])
        except Unsupported as e:
            skipped.append((str(e), t[:m.start()].count('\n') + 1)); continue
        res.append(t[pos:m.start()] + new); pos = end + len('\\end{tblr}'); conv += 1
    res.append(t[pos:])
    return ''.join(res), conv, skipped

hoisted, wrapped, hoistfiles, picwrapped = [], [], [], []
os.makedirs('_html', exist_ok=True)
for f in sorted(glob.glob('*/tikz/*.tikz')):
    t = read(f)
    content, mode = None, None
    m = ANY.search(t)
    if m:
        head, body = t[:m.start()], t[m.start():]
        code = [l for l in head.split('\n') if l.strip() and not l.strip().startswith('%')]
        if code and '\\documentclass' not in head:
            if PICT.match(body):                           # code + picture -> whole file is an image
                content, mode = '\\begin{lateximage}[figure]\n' + t + '\n\\end{lateximage}\n', 'wrap'
            else:                                          # code + subfigure/minipage -> hoist the code
                content, mode = body, 'hoist'
                hoisted.append('%% from %s\n%s\n' % (f, head.strip())); hoistfiles.append(f)
    if mode != 'wrap':                                     # pictures that define pics in their options
        new, n = wrap_pic_options(content if content is not None else t)
        if n: content, mode = new, (mode or 'pic'); picwrapped.append((f, n))
    if content is None: continue
    if mode == 'wrap': wrapped.append(f)
    out = os.path.join('_html', f)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    open(out, 'w', encoding='utf-8').write(content)

# chapter copies: _html/<Dir>/<Dir>.tex  (\ce in captions wrapped in $..$; tblr tables -> tabularx)
capfixed, tabfixed, tabskipped = [], [], []
for f in sorted(glob.glob('*/*.tex')):
    d, b = os.path.split(f)
    if d.startswith(('_html', '.')) or b != d + '.tex': continue
    raw = open(f, 'rb').read().decode('utf-8', errors='surrogateescape')
    new, n = fix_captions(raw)
    new, nt, sk = convert_tables(new)
    for reason, line in sk: tabskipped.append((f, line, reason))
    if n or nt:
        out = os.path.join('_html', d, b); os.makedirs(os.path.dirname(out), exist_ok=True)
        open(out, 'wb').write(new.encode('utf-8', errors='surrogateescape'))
        if n: capfixed.append((f, n))
        if nt: tabfixed.append((f, nt))

with open('lwarp-tikzdefs.tex', 'w', encoding='utf-8') as g:
    g.write('% Generated by prepare_html.py. Code hoisted from tikz files into the preamble (there a dollar sign is still a math shift).\n')
    g.write('\n'.join(hoisted))
print('tikz files wrapped as one image: %d, code hoisted: %d, pictures with .pic options wrapped: %d' % (len(wrapped), len(hoistfiles), sum(n for _, n in picwrapped)))
for f in wrapped: print('  wrap  ', f)
for f in hoistfiles: print('  hoist ', f)
for f, n in picwrapped: print('  pic    %s (%d)' % (f, n))
for f, n in tabfixed: print('  tblr -> tabularx: %s (%d)' % (f, n))
for f, line, reason in tabskipped: print('  tblr NOT converted (%s): %s line %d -> stays an image' % (reason, f, line))
for f, n in capfixed: print('  \\ce in captions wrapped in $..$: %s (%d)' % (f, n))
if '--no-pdf' not in sys.argv:
    pdfs = [p for p in glob.glob('*/Pictures/*.pdf') if not os.path.exists(p[:-4] + '.svg')]
    print('PDF pictures to convert: %d' % len(pdfs))
    if pdfs: subprocess.run(['lwarpmk', 'pdftosvg'] + pdfs)
