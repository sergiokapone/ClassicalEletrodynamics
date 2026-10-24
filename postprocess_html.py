#!/usr/bin/env python3
"""Постобробка HTML після lwarp (запускається з кореня проєкту, змінює *.html на місці).

Кроки (кожен — окрема функція; усі безпечно запускати повторно):

  Сторінка
    add_home_sidebar         головна сторінка книги отримує ту саму бічну панель (зміст + пошук), що й розділи
    localize_nav             «Contents»/«Home» -> «Про посібник · PDF»/«Головна»; назва книги в панелі — посилання
    set_chapter_title        <title> розділу: «N. Назва — Класична електродинаміка»
    fix_asset_paths          conspect.css / book.js лежать у docs/assets/: шляхи в <head> -> assets/ (повторний запуск безпечний)
    add_head_extras          favicon і assets/book.js (тема, зміст, шухляда на телефоні, «попередній/наступний», пошук,
                             збільшення рисунків, перенесення довгих формул)
    move_mathjax_macros      блок макросів MathJax -> на початок <body>
    wrap_toc_titles          назва пункту змісту -> <span class="toctitle"> (формула не падає під номер)

  Пошук (Pagefind; поле пошуку й формули в результатах додає book.js, індекс будує build-html.ps1)
    mark_for_indexing        як в ElMagConspect: індексується <main> сторінок ch*.html, заголовок результату з <title>

  Обробляються лише сторінки, створені lwarp (мають <meta name="generator" content="LaTeX Lwarp package">).
  Службовий *_html.html не чіпається. Після цього publish_html.py переносить сайт у docs/ (GitHub Pages).
"""
import glob
import re

# ───────────────────────────── Сторінка ─────────────────────────────

def move_mathjax_macros(s):
    match = re.search(
        r'(<!--MathJax customizations:-->\s*<div[^>]*>.*?</div>)',
        s,
        re.DOTALL
    )
    if match and not re.search(r'<body[^>]*>\s*' + re.escape(match.group(1)), s):
        block = match.group(1)
        s_clean = s.replace(block, "")
        s = re.sub(
            r'(<body[^>]*>)',
            lambda m: m.group(1) + '\n' + block,
            s_clean,
            count=1
        )
    return s


def wrap_toc_titles(s):
    r"""Загортає назву пункту змісту в <span class="toctitle">.

    Посилання змісту в CSS — це grid із двома колонками (номер | назва). Якщо в назві
    є формула (\(F_{\mu\nu}\)), MathJax робить із неї окремий елемент grid, і той
    потрапляє у наступний рядок під номер. Один обгортковий span дає рівно два
    елементи: номер і назва (з формулою всередині). Безпечно для повторного запуску.
    """
    pat = re.compile(
        r'(<a [^>]*class="toc(?:chapter|section|subsection|subsubsection)"[^>]*>\s*'
        r'<span class="sectionnumber">[^<]*</span>)(&#x2003;(?:(?!</a>).)*?)(</a>)',
        re.DOTALL,
    )

    def repl(m):
        body = m.group(2)
        if 'class="toctitle"' in body:
            return m.group(0)
        return f'{m.group(1)}<span class="toctitle">{body}</span>{m.group(3)}'

    return pat.sub(repl, s)


# ───────────────────────────── Навігація ─────────────────────────────

HOME_LABEL = "Головна"
SIDETOC_META = (
    '<p class="sidetoc-meta"><a href="index.html">Про посібник</a>'
    '<span aria-hidden="true">·</span><a href="ClassicalElectrodynamics.pdf">PDF</a></p>'
)
BOOK_TITLE = "Класична електродинаміка"


def add_home_sidebar(s, donor):
    """Головна сторінка lwarp (homepagegrid) не має бічної панелі, а отже й пошуку.
    Копіюємо шапку + бічну панель з уже обробленої сторінки розділу (donor): зміст, пошук, тема,
    шухляда на телефоні — усе однакове на всіх сторінках книги. Безпечно для повторного запуску."""
    if not donor or 'class="homepagegrid' not in s or 'class="sidetoccontainer"' in s:
        return s
    m = re.search(
        r'<nav class="topnavigation">.*?</nav>\s*<div class="sidetoccontainer"[^>]*>.*?</nav>\s*</div>',
        donor, re.DOTALL)
    if not m:
        return s
    s = s.replace('<div class="homepagegrid">', '<div class="homepagegrid pagegrid">\n' + m.group(0) + '\n', 1)
    return s


def localize_nav(s):
    """Англійські написи lwarp -> українські; шапка панелі веде на головну, а «Contents» стає посиланнями
    на інформаційну сторінку книги та PDF."""
    s = re.sub(r'(class="linkhome"\s*>\s*)Home(\s*</a>)', r'\g<1>' + HOME_LABEL + r'\g<2>', s)
    if 'sidetoc-meta' not in s:
        s = re.sub(
            r'(<div class="sidetoctitle">(?:(?!</div>).)*?)<p>\s*Contents\s*</p>',
            lambda m: m.group(1) + SIDETOC_META, s, count=1, flags=re.DOTALL)
    if 'class="sidetoc-home"' not in s:
        home = re.search(r'<a href="([^"]*)"\s+class="linkhome"', s)
        if home:
            s = re.sub(
                r'(<span class="sidetocthetitle">.*?</span>)',
                lambda m: f'<a href="{home.group(1)}" class="sidetoc-home">{m.group(1)}</a>',
                s, count=1, flags=re.DOTALL)
    return s


def set_chapter_title(s):
    """lwarp дає першому розділу <title> «Класична електродинаміка — Класична електродинаміка» (береться
    назва частини), а решті — без номера. Робимо «N. Назва розділу — Класична електродинаміка»."""
    m = re.search(
        r'<h3[^>]*>\s*(?:Розділ(?:&nbsp;|\s)+)?(?:<span class="sectionnumber">)\s*(\d+)(?:&#x2003;)?\s*</span>(.*?)</h3>',
        s, re.DOTALL)
    if not m:
        return s
    name = re.sub(r'\s+', ' ', re.sub(r'<[^>]+>', '', m.group(2))).strip()
    if not name or '\\(' in name:      # формула в назві розділу в <title> не відрендериться
        return s
    new = f'<title>{m.group(1)}. {name} — {BOOK_TITLE}</title>'
    return re.sub(r'<title>.*?</title>', lambda _: new, s, count=1, flags=re.DOTALL)


def fix_asset_paths(s):
    """lwarp пише <link href="conspect.css">; сам файл (і book.js) лежить у docs/assets/. Правимо шляхи на місці."""
    s = re.sub(r'(href=\")(?!assets/)(conspect\.css\")', r'\1assets/\2', s)
    s = re.sub(r'(src=\")(?!assets/)(book\.js\")', r'\1assets/\2', s)
    return s


def add_head_extras(s):
    """favicon (EM.ico з кореня проєкту publish_html.py копіює в docs/) і book.js. Скрипт у <head> без defer: клас теми ставиться
    до першого малювання сторінки (немає «миготіння»), а решту book.js робить на DOMContentLoaded."""
    extra = ''
    if 'rel="icon"' not in s:
        extra += '<link rel="icon" href="EM.ico">\n'
    if 'book.js' not in s:
        extra += '<script src="assets/book.js"></script>\n'
    if extra:
        s = s.replace('</head>', extra + '</head>', 1)
    return s


# ───────────────────────────── Пошук ─────────────────────────────

def mark_for_indexing(s, filename):
    """Пошук (Pagefind, індекс будує build-html.ps1) -- як в ElMagConspect: індексується лише текст сторінок розділів
    (ch*.html: розділи, Додатки, Література), уся <main class="bodycontainer">. Заголовок результату -- назва розділу
    з <title> («N. Назва — книга» після set_chapter_title), а не <h1>, який на кожній сторінці -- назва книги.
    Сторінки без data-pagefind-body (головна книги) Pagefind пропускає, бо інші сторінки його мають."""
    if not re.fullmatch(r'ch\d+\.html', filename) or 'data-pagefind-body' in s:
        return s
    m = re.search(r'<title>(.*?)</title>', s, re.DOTALL)
    parts = [p.strip() for p in (m.group(1) if m else filename).split(' — ')]
    title = next((p for p in parts if p != BOOK_TITLE), parts[0]).replace('"', '&quot;')
    s = s.replace('<main class="bodycontainer">', '<main class="bodycontainer" data-pagefind-body '
                  'data-pagefind-meta="title[data-title]" data-title="%s">' % title, 1)
    return s.replace('<h1>', '<h1 data-pagefind-ignore>', 1)


# MathJax-розширення, які треба явно підключити (автозавантаження у цій конфігурації не спрацьовує):
#   unicode    - \\unicode{x1D70C} (символи unicode-math, які видає lwarp)
#   boldsymbol - \\boldsymbol, яким визначені макроси \\grad, \\divg, \\rot
MATHJAX_EXTRA_PACKAGES = ("unicode", "boldsymbol")


def add_unicode_support(s):
    r"""Підключає MathJax-модулі unicode і boldsymbol.

    Важливо: НЕ вставляємо нових ключів loader/tex у MathJax = {...}: у конфізі
    lwarp вони вже є, а при дублі ключа в JS-літералі виграє останній, тому
    вставлений раніше блок просто перекривався. Замість цього дописуємо
    назви у вже наявні списки loader.load та tex.packages['[+]'].
    Функція безпечна для повторного запуску.
    """
    # 1) прибрати старий (хибний) вставлений блок із попередніх запусків
    s = re.sub(
        r'MathJax = \{\s*loader: \{ load: \["\[tex\]/unicode"\] \},\s*'
        r'tex: \{ packages: \{"\[\+\]": \["unicode"\]\} \},',
        'MathJax = {',
        s,
    )
    if 'MathJax = {' not in s:
        return s

    for pkg in MATHJAX_EXTRA_PACKAGES:
        # 2) loader.load: ['[tex]/tagformat', '[tex]/textmacros', ...]
        if f"'[tex]/{pkg}'" not in s:
            s = s.replace(
                "'[tex]/textmacros'",
                f"'[tex]/textmacros', '[tex]/{pkg}'",
                1,
            )
        # 3) tex.packages: {'[+]': ['tagformat', 'Lwarp-macros', 'textmacros', ...]}
        if not re.search(r"'\[\+\]':\s*\[[^\]]*'" + pkg + r"'", s):
            s = s.replace(
                "'Lwarp-macros', 'textmacros'",
                f"'Lwarp-macros', 'textmacros', '{pkg}'",
                1,
            )
    return s


# ───────────────────────────── Запуск ─────────────────────────────

def process(content, filename, donor=None):
    s = fix_asset_paths(content)
    s = add_head_extras(s)              # першим: решта вставок у <head> лягає після нього — порядок стабільний
    s = add_unicode_support(s)
    s = move_mathjax_macros(s)
    s = wrap_toc_titles(s)
    s = set_chapter_title(s)
    s = mark_for_indexing(s, filename)  # після set_chapter_title: заголовок результату пошуку береться з <title>
    s = add_home_sidebar(s, donor)
    s = localize_nav(s)
    return s


def is_book_page(text, filename):
    """Лише сторінки lwarp. index.html (інформаційна) та *_html.html (проміжний повний файл) пропускаємо."""
    if filename.endswith("_html.html"):
        return False
    return 'content="LaTeX Lwarp package"' in text[:3000]


def natural_key(name):
    return [int(t) if t.isdigit() else t for t in re.split(r'(\d+)', name)]


def read_page(path):
    """Текст сторінки й ознака «було виправлено». pdftotext (TeX Live 2026) пише символи поза BMP (математичні
    курсивні літери в коментарях lwarp із текстом формул) як пари сурогатів по 3 байти (CESU-8): це не UTF-8, і
    звичайне читання падає. Сурогати декодуємо окремо й зводимо в справжні символи."""
    raw = open(path, 'rb').read()
    try:
        text, fixed = raw.decode('utf-8'), False
    except UnicodeDecodeError:
        text = raw.decode('utf-8', 'surrogatepass').encode('utf-16', 'surrogatepass').decode('utf-16', 'replace')
        fixed = True
    return text.replace('\r\n', '\n'), fixed


def main():
    pages, repaired = {}, set()
    for filepath in sorted(glob.glob("*.html"), key=natural_key):
        text, fixed = read_page(filepath)
        if fixed:
            repaired.add(filepath)
        if is_book_page(text, filepath):
            pages[filepath] = text
        else:
            print(f"  пропущено (не сторінка lwarp): {filepath}")

    home = [fp for fp, t in pages.items() if 'class="homepagegrid' in t]
    count = 0

    def save(fp, new):
        nonlocal count
        if new != pages[fp] or fp in repaired:
            with open(fp, "w", encoding="utf-8") as f:
                f.write(new)
            count += 1
        pages[fp] = new

    # 1) усі сторінки, крім головної; 2) головна — після них, бо бере готову бічну панель з першого розділу
    for fp in list(pages):
        if fp not in home:
            save(fp, process(pages[fp], fp))
    donor = next((pages[fp] for fp in pages if re.match(r'ch\d+\.html$', fp)), None)
    for fp in home:
        save(fp, process(pages[fp], fp, donor))
    print(f"Оновлено {count} HTML-файлів (навігація, розмітка для пошуку).")

if __name__ == "__main__":
    main()
