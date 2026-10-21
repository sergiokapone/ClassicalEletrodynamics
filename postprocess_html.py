#!/usr/bin/env python3
"""Постобробка HTML після lwarp (запускається з кореня проєкту, змінює *.html на місці).

Кроки (кожен — окрема функція; усі безпечно запускати повторно):

  Сторінка
    move_mathjax_macros      блок макросів MathJax -> на початок <body>
    add_appendix_header      заголовок «Додатки» в бічному змісті
    letter_appendix_numbers  нумерація додатків .1, .2 -> А, Б, ...
    localize_index           «section 1.1» -> «розділ 1.1» у покажчику

  Пошук (Pagefind)
    add_search_assets        підключення pagefind-ui.css/js
    add_search_box           поле пошуку в бічній панелі
    refresh_search_config    оновлення налаштувань пошуку в уже оброблених файлах
    add_search_math          рендеринг формул у результатах (MathJax)
    mark_for_indexing        що індексувати: лише розділи ch*/app*, без бічної панелі та загального h1
"""
import glob
import os
import re

APP_MAP = {
    '.1': 'А', '.2': 'Б', '.3': 'В', '.4': 'Г', '.5': 'Д', '.6': 'Е', '.7': 'Є'
}

TEXTBODY = re.compile(r'<(?:div|section)\b[^>]*\bclass="textbody"[^>]*>')

# ───────────────────────── Пошук: JS-вставки ─────────────────────────

PF_INIT = (
    'new PagefindUI({ element: "#search", showSubResults: true, showImages: false, resetFilters: false, '
    'processResult: function (r) { var n = function (x) { return (x || "").replace(/\\s+/g, " ").trim(); }; '
    'var f = window.pfTexFix || function (x) { return x; }; var t = n(r.meta && r.meta.title); '
    'r.excerpt = f(r.excerpt); '
    'for (var i = 0, a = r.sub_results || []; i < a.length; i++) { '
    'a[i].excerpt = f(a[i].excerpt); '
    'if (n(a[i].title) === t) { a[i].title = "Початок розділу"; } } return r; } });'
)

# Формули в результатах пошуку: Pagefind індексує сирий TeX (\\(...\\)), тож після кожного
# оновлення списку прогоняємо його через MathJax.
SEARCH_MATH = r'''<script id="search-math">
(function () {
  /* Обрізаний уривок міг розірвати формулу: прибираємо «висячі» \\( та \\) */
  window.pfTexFix = function (html) {
    if (!html) { return html; }
    var o = html.indexOf('\\('), c = html.indexOf('\\)');
    if (c >= 0 && (o < 0 || c < o)) { html = '\u2026' + html.slice(c + 2); }
    o = html.lastIndexOf('\\('); c = html.lastIndexOf('\\)');
    if (o > c) { html = html.slice(0, o) + '\u2026'; }
    var b = html.lastIndexOf('\\begin{'), e = html.lastIndexOf('\\end{');
    if (b > e) { html = html.slice(0, b) + '\u2026'; }
    var e0 = html.indexOf('\\end{'), b0 = html.indexOf('\\begin{');
    if (e0 >= 0 && (b0 < 0 || e0 < b0)) { html = '\u2026' + html.slice(html.indexOf('}', e0) + 1); }
    return html;
  };
  function start() {
    var box = document.getElementById('search');
    if (!box || !window.MutationObserver) { return; }
    var timer = null, running = false, again = false;
    function schedule() { if (timer) { clearTimeout(timer); } timer = setTimeout(run, 120); }
    function run() {
      timer = null;
      if (running) { again = true; return; }
      if (!window.MathJax || !MathJax.typesetPromise) { timer = setTimeout(run, 400); return; }
      running = true;
      var p;
      try { if (MathJax.typesetClear) { MathJax.typesetClear([box]); } p = MathJax.typesetPromise([box]); }
      catch (e) { running = false; return; }
      p.catch(function () {}).then(function () { running = false; if (again) { again = false; schedule(); } });
    }
    new MutationObserver(function (ms) {
      for (var i = 0; i < ms.length; i++) {
        var t = ms[i].target;
        if (t.nodeType === 1 && t.closest && t.closest('mjx-container')) { continue; }
        schedule(); return;
      }
    }).observe(box, { childList: true, subtree: true });
  }
  if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', start); } else { start(); }
})();
</script>
'''


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


def add_appendix_header(s):
    """Розділювач «Додатки» в sidetoc перед першим додатком (.1)."""
    if '.1' in s and 'sidetoc-appendix-title' not in s:
        appendix_header = (
            '<div class="sidetoc-appendix-title" style="margin-top:1.2rem; padding:.4rem .8rem; '
            'font-weight:600; font-size:.9rem; color:var(--gold,#c99a2e); '
            'border-top:1px solid rgba(255,255,255,.15);">'
            'Додатки</div>\n'
        )
        s = re.sub(
            r'(<p>\s*<a [^>]*>\s*<span class="sectionnumber">\s*\.1\s*</span>)',
            appendix_header + r'\1',
            s,
            count=1
        )
    return s


def letter_appendix_numbers(s):
    """Крапкова нумерація .1, .2 -> А, Б, ..."""
    for num_str, letter in APP_MAP.items():
        pattern = rf'(<span class="sectionnumber">\s*){re.escape(num_str)}(\s*)'
        replacement = rf'\1{letter}\2'
        s = re.sub(pattern, replacement, s)
    return s


# Англійські назви типів посилань, які lwarp пише в предметному покажчику, -> українські.
# Змінюйте праві частини за смаком (наприклад, "section": "розділ" або "п.").
INDEX_REF_WORDS = {
    "chapter": "розділ",
    "section": "§",
    "subsection": "§",
    "subsubsection": "§",
    "paragraph": "п.",
    "footnote": "виноска",
    "appendix": "додаток",
    "equation": "формула",
    "figure": "рис.",
    "table": "табл.",
    "page": "с.",
}
# Тип «problem»: \newtheorem{problem}{} має порожню назву, тому lwarp пише «??».
INDEX_UNKNOWN_REF_WORD = "задача"


def localize_index(s):
    r"""Українізує слова перед номерами в предметному покажчику.

    lwarp пише посилання як  section&nbsp;<a href="ch5.html#LWRindex-44">5.2</a>
    (слово, нерозривний пробіл-ентіті й тег <a>), тому простий регекс «section\s+номер»
    їх не бачив. Замінюємо слово лише перед посиланнями на LWRindex-..., щоб не
    зачепити решту сторінки. Невідомий тип (запис покажчика в задачі) дає «??&nbsp;7.2»
    без тега <a>: його замінюємо тільки всередині записів покажчика.
    """
    words = "|".join(sorted(INDEX_REF_WORDS, key=len, reverse=True))
    s = re.sub(
        rf'\b({words})(?:&nbsp;|\s)+(?=<a href="[^"]*#LWRindex-)',
        lambda m: INDEX_REF_WORDS[m.group(1)] + '&nbsp;',
        s,
    )

    def fix_entry(m):
        return re.sub(r'\?\?(?:&nbsp;|\s)+(?=[A-Za-z\d])', INDEX_UNKNOWN_REF_WORD + '&nbsp;', m.group(0))

    s = re.sub(r'<span class="indexitem">.*?</p>', fix_entry, s, flags=re.DOTALL)
    # старий випадок: звичайний текст «section 1.1» без тега <a>
    return re.sub(r'(>|,\s*)section\s+([a-zA-Z\d\.]+)', r'\1' + INDEX_REF_WORDS["section"] + r'&nbsp;\2', s)


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


# ───────────────────────────── Пошук ─────────────────────────────

def add_search_assets(s):
    if 'pagefind/pagefind-ui.js' not in s:
        search_assets = (
            '<link href="pagefind/pagefind-ui.css" rel="stylesheet">\n'
            '<script src="pagefind/pagefind-ui.js"></script>\n'
        )
        s = s.replace('</head>', f'{search_assets}</head>')
    return s


def add_search_box(s):
    """Поле пошуку в sidetoc під заголовком."""
    if 'id="search"' not in s:
        search_box = (
            '<div id="search" style="padding: 0.8rem 0.6rem 0.2rem;"></div>\n'
            '<script>\n'
            '  window.addEventListener("DOMContentLoaded", (event) => {\n'
            f'    {PF_INIT}\n'
            '  });\n'
            '</script>\n'
        )
        s = re.sub(
            r'(<div class="sidetoctitle">.*?</div>)',
            lambda m: m.group(1) + '\n' + search_box,
            s,
            flags=re.DOTALL
        )
    return s


def refresh_search_config(s):
    """Оновлює налаштування пошуку й у вже оброблених файлах."""
    return re.sub(r'new PagefindUI\(\{.*?\}\);', lambda m: PF_INIT, s)


def add_search_math(s):
    """Рендеринг формул у результатах (блок оновлюється при кожному запуску)."""
    s = re.sub(r'<script id="search-math">.*?</script>\n?', '', s, flags=re.DOTALL)
    return s.replace('</head>', SEARCH_MATH + '</head>', 1)


def mark_for_indexing(s, filename):
    """Чітке розмежування індексації для Pagefind."""
    # А) Завжди ігноруємо бокову панель
    if 'data-pagefind-ignore' not in s:
        s = s.replace(
            '<div class="sidetoccontainer"',
            '<div class="sidetoccontainer" data-pagefind-ignore'
        )

    # Б) Окремий файл розділу/додатка (ch1.html, ch10.html, app1.html)?
    is_chapter_file = bool(re.match(r'^(ch|app)\d+.*\.html$', filename, re.IGNORECASE))

    if is_chapter_file:
        # Блок тексту може бути <section class="textbody"> або <div class="textbody">
        m = TEXTBODY.search(s)
        if m:
            tag = m.group(0)
            # Позначаємо контент розділу для індексу
            if 'data-pagefind-body' not in tag:
                s = s.replace(tag, tag[:-1] + ' data-pagefind-body>', 1)
                m = TEXTBODY.search(s)

            # Ховаємо загальний h1 "Класична електродинаміка" від Pagefind
            s = re.sub(
                r'(<(?:div|section)\b[^>]*\bclass="textbody"[^>]*>\s*)(<h1>.*?</h1>)',
                r'\1<div data-pagefind-ignore>\2</div>',
                s,
                count=1,
                flags=re.DOTALL
            )

            # Заголовком картки в пошуку стає назва розділу (перший h3 тексту)
            m = TEXTBODY.search(s)
            head, body = s[:m.end()], s[m.end():]
            if 'data-pagefind-meta="title"' not in body:
                body = re.sub(r'<h3 (id="[^"]*")>', r'<h3 \1 data-pagefind-meta="title">', body, count=1)
            s = head + body
    else:
        # Всі інші сукупні файли (ClassicalElectrodynamics.html, index.html) блокуємо повністю
        if 'data-pagefind-ignore' not in s:
            s = re.sub(r'(<body[^>]*>)', r'\1\n<div data-pagefind-ignore>', s, count=1)
            s = s.replace('</body>', '</div>\n</body>')
    return s


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

def process(content, filename):
    s = add_unicode_support(content)
    s = add_search_assets(s)            # <--- ВИПРАВЛЕНО (було content)
    s = add_search_box(s)
    s = refresh_search_config(s)
    s = add_search_math(s)
    s = move_mathjax_macros(s)
    s = add_appendix_header(s)
    s = letter_appendix_numbers(s)
    s = localize_index(s)
    s = wrap_toc_titles(s)
    s = mark_for_indexing(s, filename)
    return s


def main():
    count = 0
    for filepath in glob.glob("*.html"):
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
        new_content = process(content, os.path.basename(filepath))
        if new_content != content:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
            count += 1
    print(f"Оновлено {count} HTML-файлів (пошук, індексація, додатки, покажчик).")


if __name__ == "__main__":
    main()
