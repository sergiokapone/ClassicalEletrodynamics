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
    add_appendix_header      заголовок «Додатки» в бічному змісті
    letter_appendix_numbers  нумерація додатків .1, .2 -> А, Б, ...
    localize_index           «section 1.1» -> «розділ 1.1» у покажчику

  Пошук (Pagefind; поле пошуку й формули в результатах додає book.js, індекс будує build-html.ps1)
    mark_for_indexing        що індексувати: лише розділи ch*/app*, без бічної панелі та загального h1

  Обробляються лише сторінки, створені lwarp (мають <meta name="generator" content="LaTeX Lwarp package">).
  Службовий *_html.html не чіпається. Після цього publish_html.py переносить сайт у docs/ (GitHub Pages).
"""
import glob
import os
import re

APP_MAP = {
    '.1': 'А', '.2': 'Б', '.3': 'В', '.4': 'Г', '.5': 'Д', '.6': 'Е', '.7': 'Є'
}

TEXTBODY = re.compile(r'<(?:div|section)\b[^>]*\bclass="textbody"[^>]*>')

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
        r'<h3[^>]*>\s*Розділ(?:&nbsp;|\s)+(?:<span[^>]*>)?\s*(\d+)(?:&#x2003;)?\s*(?:</span>)?(.*?)</h3>',
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

def process(content, filename, donor=None):
    s = fix_asset_paths(content)
    s = add_head_extras(s)              # першим: решта вставок у <head> лягає після нього — порядок стабільний
    s = add_unicode_support(s)
    s = move_mathjax_macros(s)
    s = add_appendix_header(s)
    s = letter_appendix_numbers(s)
    s = localize_index(s)
    s = wrap_toc_titles(s)
    s = mark_for_indexing(s, filename)
    s = add_home_sidebar(s, donor)      # після mark_for_indexing: сторінка вже в <div data-pagefind-ignore>
    s = localize_nav(s)
    s = set_chapter_title(s)
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
    print(f"Оновлено {count} HTML-файлів (навігація, індексація для пошуку, додатки, покажчик).")

if __name__ == "__main__":
    main()
