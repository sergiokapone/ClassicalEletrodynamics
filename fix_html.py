#!/usr/bin/env python3
import glob
import os
import re
import sys

# Файлы, которые скрипт не трогает
EXCLUDE_FILES = {'index.html'}


def clean_lwarp_html(content: str) -> str:
    s = content

    # 1. Исправление макросов MathJax: ##1 -> #1 (артефакт Lwarp)
    s = re.sub(r'##(\d)', r'#\1', s)

    # 2. БЕЗОПАСНОЕ исправление структуры \frac {A} ^ {B} -> \frac {A} {B}
    # Учитывает вложенные скобки. Степень ПОСЛЕ дроби (\frac{A}{B}^2) или ВНУТРИ числителя (\frac{mv^2}{2}) НЕ ТРОГАЕТСЯ.
    def fix_frac_erroneous_caret(text):
        result = []
        i, n = 0, len(text)
        while i < n:
            if text[i : i + 5] == '\\frac':
                j = i + 5
                while j < n and text[j].isspace():
                    j += 1
                if j < n and text[j] == '{':
                    depth, k = 0, j
                    while k < n:
                        if text[k] == '{':
                            depth += 1
                        elif text[k] == '}':
                            depth -= 1
                        k += 1
                        if depth == 0:
                            break
                    # Закончился первый аргумент \frac{...}
                    m = k
                    while m < n and text[m].isspace():
                        m += 1
                    # Если СРАЗУ после первого аргумента идет '^', а за ним '{' (второй аргумент)
                    if m < n and text[m] == '^':
                        m2 = m + 1
                        while m2 < n and text[m2].isspace():
                            m2 += 1
                        if m2 < n and text[m2] == '{':
                            # Удаляем только ошибочный '^' между аргументами \frac
                            result.append(text[i:m])
                            i = m + 1
                            continue
            result.append(text[i])
            i += 1
        return ''.join(result)

    s = fix_frac_erroneous_caret(s)

    # 3. БЕЗОПАСНОЕ удаление висячих кареток '^' БЕЗ аргументов.
    # Удаляет '^', ТОЛЬКО если сразу за ним идет '|', '}', '&apos;', '</', пробел или конец строки.
    # Все законные степени (x^2, e^{x}, a^{\dagger}, r^3) содержат после '^' цифру, букву, '\' или '{',
    # поэтому этот regex их ВООБЩЕ НЕ КАСАЕТСЯ.
    s = re.sub(r'\^+(?=[\|\}]|&apos;|</|\s|$)', '', s)

    # 4. Исправление обратных слэшей в путях к картинкам (\ -> /)
    def fix_url_path(m):
        attr, quote, path = m.group(1), m.group(2), m.group(3)
        return f'{attr}={quote}{path.replace("\\", "/")}{quote}'

    s = re.sub(r'\b(src|href)=(["\'])([^"\']*?\\[^"\']*?)\2', fix_url_path, s)

    # 5. Исправление закрытия HTML-комментариев Lwarp: -^-> -> -->
    s = re.sub(r'-\^->', '-->', s)

    # 6. Восстановление случайно заэкранированных URL и спецсимволов HTML
    s = re.sub(r'https?:\^//', 'https://', s)
    s = re.sub(r'\^([/<>=+#%])', r'\1', s)

    return s


def process_file(filepath: str) -> bool:
    filename = os.path.basename(filepath)

    if filename in EXCLUDE_FILES or (
        filename.startswith('google') and filename.endswith('.html')
    ):
        print(f'[SKIP] Пропущен файл: {filepath}')
        return False

    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        cleaned = clean_lwarp_html(content)

        if cleaned != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(cleaned)
            print(f'[OK] Исправлен: {filepath}')
            return True
        else:
            print(f'[SKIP] Без изменений: {filepath}')
            return False
    except Exception as e:
        print(f'[ERROR] Ошибка при обработке {filepath}: {e}', file=sys.stderr)
        return False


def main():
    print('Запуск очистки HTML-файлов...')
    patterns = ['*.html', '_html/**/*.html', '**/*.html']
    found_files = set()

    for pattern in patterns:
        for filepath in glob.glob(pattern, recursive=True):
            found_files.add(os.path.normpath(filepath))

    if not found_files:
        print('HTML-файлы не найдены.')
        return

    modified_count = 0
    for filepath in sorted(found_files):
        if process_file(filepath):
            modified_count += 1

    print(
        f'\nЗавершено. Обновлено файлов: {modified_count} из {len(found_files)}.'
    )


if __name__ == '__main__':
    main()
