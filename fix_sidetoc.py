import glob
import re

def fix_mathjax_order():
    html_files = glob.glob("*.html")
    count = 0
    for filepath in html_files:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()

        # Шукаємо блок макросів MathJax
        match = re.search(
            r'(<!--MathJax customizations:-->\s*<div data-nosnippet[^>]*>.*?</div>)',
            content,
            re.DOTALL
        )
        if match:
            block = match.group(1)
            # Видаляємо його з початкового місця
            content_clean = content.replace(block, "")

            # Використовуємо lambda, щоб re.sub не інтерпретував LaTeX-слеші (\d, \d...) як свої спецсимволи
            new_content = re.sub(
                r'(<body[^>]*>)',
                lambda m: m.group(1) + '\n' + block,
                content_clean,
                count=1
            )

            if new_content != content:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(new_content)
                count += 1

    print(f"Оновлено {count} HTML-файлів: макроси MathJax перенесено на початок <body>.")

if __name__ == "__main__":
    fix_mathjax_order()
