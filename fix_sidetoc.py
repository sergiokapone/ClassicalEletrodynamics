import glob
import re

APP_MAP = {
    '.1': 'А',
    '.2': 'Б',
    '.3': 'В',
    '.4': 'Г',
    '.5': 'Д',
    '.6': 'Е',
    '.7': 'Є'
}

def fix_sidetoc_and_mathjax():
    html_files = glob.glob("*.html")
    count = 0

    for filepath in html_files:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        new_content = content

        # 1. Перенесення макросів MathJax на початок <body> (щоб sidetoc одразу їх бачив)
        match = re.search(
            r'(<!--MathJax customizations:-->\s*<div data-nosnippet[^>]*>.*?</div>)',
            new_content,
            re.DOTALL
        )
        if match:
            block = match.group(1)
            content_clean = new_content.replace(block, "")
            new_content = re.sub(
                r'(<body[^>]*>)',
                lambda m: m.group(1) + '\n' + block,
                content_clean,
                count=1
            )

        # 2. Вставка розділювача "Додатки" в sidetoc перед першим додатком (.1)
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

        # 3. Заміна крапкової нумерації .1, .2, .3 на літери А, Б, В...
        for num_str, letter in APP_MAP.items():
            pattern = rf'(<span class="sectionnumber">\s*){re.escape(num_str)}(\s*)'
            replacement = rf'\1{letter}\2'
            new_content = re.sub(pattern, replacement, new_content)

        if new_content != content:
            with open(filepath, "w", encoding="utf-8") as f:
                f.write(new_content)
            count += 1

    print(f"Оновлено {count} HTML-файлів: MathJax перенесено, додатки прономеровано (А, Б, В...).")

if __name__ == "__main__":
    fix_sidetoc_and_mathjax()
