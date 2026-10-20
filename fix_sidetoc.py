import glob
import os
import re

APP_MAP = {
    '.1': 'А', '.2': 'Б', '.3': 'В', '.4': 'Г', '.5': 'Д', '.6': 'Е', '.7': 'Є'
}

PF_INIT = 'new PagefindUI({ element: "#search", showSubResults: true, showImages: false, resetFilters: false });'
TEXTBODY = re.compile(r'<(?:div|section)\b[^>]*\bclass="textbody"[^>]*>')


def fix_sidetoc_and_mathjax():
    html_files = glob.glob("*.html")
    count = 0

    for filepath in html_files:
        filename = os.path.basename(filepath)
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        new_content = content

        # 1. Підключення CSS та JS для Pagefind у <head>
        if 'pagefind/pagefind-ui.js' not in new_content:
            search_assets = (
                '<link href="pagefind/pagefind-ui.css" rel="stylesheet">\n'
                '<script src="pagefind/pagefind-ui.js"></script>\n'
            )
            new_content = new_content.replace('</head>', f'{search_assets}</head>')

        # 2. Вставка вікна пошуку в sidetoc під заголовком
        if 'id="search"' not in new_content:
            search_box = (
                '<div id="search" style="padding: 0.8rem 0.6rem 0.2rem;"></div>\n'
                '<script>\n'
                '  window.addEventListener("DOMContentLoaded", (event) => {\n'
                f'    {PF_INIT}\n'
                '  });\n'
                '</script>\n'
            )
            new_content = re.sub(
                r'(<div class="sidetoctitle">.*?</div>)',
                r'\1\n' + search_box,
                new_content,
                flags=re.DOTALL
            )

        # 2б. Оновлюємо налаштування пошуку й у вже оброблених файлах
        new_content = re.sub(r'new PagefindUI\(\{[^}]*\}\);', lambda m: PF_INIT, new_content)

        # 3. Перенесення макросів MathJax на початок <body>
        match = re.search(
            r'(<!--MathJax customizations:-->\s*<div data-nosnippet[^>]*>.*?</div>)',
            new_content,
            re.DOTALL
        )
        if match and not re.search(r'<body[^>]*>\s*' + re.escape(match.group(1)), new_content):
            block = match.group(1)
            content_clean = new_content.replace(block, "")
            new_content = re.sub(
                r'(<body[^>]*>)',
                lambda m: m.group(1) + '\n' + block,
                content_clean,
                count=1
            )

        # 4. Вставка розділювача "Додатки" в sidetoc перед першим додатком (.1)
        if '.1' in new_content and 'sidetoc-appendix-title' not in new_content:
            appendix_header = (
                '<div class="sidetoc-appendix-title" style="margin-top:1.2rem; padding:.4rem .8rem; '
                'font-weight:600; font-size:.9rem; color:var(--gold,#c99a2e); '
                'border-top:1px solid rgba(255,255,255,.15);">'
                'Додатки</div>\n'
            )
            new_content = re.sub(
                r'(<p>\s*<a [^>]*>\s*<span class="sectionnumber">\s*\.1\s*</span>)',
                appendix_header + r'\1',
                new_content,
                count=1
            )

        # 5. Заміна крапкової нумерації .1, .2 на літери А, Б...
        for num_str, letter in APP_MAP.items():
            pattern = rf'(<span class="sectionnumber">\s*){re.escape(num_str)}(\s*)'
            replacement = rf'\1{letter}\2'
            new_content = re.sub(pattern, replacement, new_content)

        # 6. Безпечна заміна "section 1.1" / "section A.1" на "розділ 1.1" у покажчику
        new_content = re.sub(r'(>|,\s*)section\s+([a-zA-Z\d\.]+)', r'\1розділ \2', new_content)

        # 7. Чітке розмежування індексації для Pagefind
        # А) Завжди ігноруємо бокову панель
        if 'data-pagefind-ignore' not in new_content:
            new_content = new_content.replace(
                '<div class="sidetoccontainer"',
                '<div class="sidetoccontainer" data-pagefind-ignore'
            )

        # Б) Перевіряємо, чи це окремий файл розділу/додатка (наприклад, ch1.html, ch10.html, app1.html)
        is_chapter_file = bool(re.match(r'^(ch|app)\d+.*\.html$', filename, re.IGNORECASE))

        if is_chapter_file:
            # Блок тексту може бути <section class="textbody"> або <div class="textbody">
            m = TEXTBODY.search(new_content)
            if m:
                tag = m.group(0)
                # Позначаємо контент розділу для індексу
                if 'data-pagefind-body' not in tag:
                    new_content = new_content.replace(tag, tag[:-1] + ' data-pagefind-body>', 1)
                    m = TEXTBODY.search(new_content)

                # Ховаємо загальний h1 "Класична електродинаміка" від Pagefind
                new_content = re.sub(
                    r'(<(?:div|section)\b[^>]*\bclass="textbody"[^>]*>\s*)(<h1>.*?</h1>)',
                    r'\1<div data-pagefind-ignore>\2</div>',
                    new_content,
                    count=1,
                    flags=re.DOTALL
                )

                # Заголовком картки в пошуку стає назва розділу (перший h3 тексту)
                m = TEXTBODY.search(new_content)
                head, body = new_content[:m.end()], new_content[m.end():]
                if 'data-pagefind-meta="title"' not in body:
                    body = re.sub(r'<h3 (id="[^"]*")>', r'<h3 \1 data-pagefind-meta="title">', body, count=1)
                new_content = head + body

        else:
            # Всі інші сукупні файли (ClassicalElectrodynamics.html, index.html) блокуємо повністю
            if 'data-pagefind-ignore' not in new_content:
                new_content = re.sub(r'(<body[^>]*>)', r'\1\n<div data-pagefind-ignore>', new_content, count=1)
                new_content = new_content.replace('</body>', '</div>\n</body>')

        if new_content != content:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
            count += 1

    print(f"Оновлено {count} HTML-файлів: додано пошук Pagefind, покажчик, додатки А, Б, В та налаштовано унікальну індексацію.")

if __name__ == "__main__":
    fix_sidetoc_and_mathjax()
