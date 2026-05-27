#!/usr/bin/env python3
"""
sync_toc.py — генерує index.html з шаблону та оновлює README.md з LaTeX .toc файлу.

Використання:
    python sync_toc.py ClassicalElectrodynamics.toc

Опційно:
    python sync_toc.py ClassicalElectrodynamics.toc \
        --template index.html.j2 \
        --html index.html \
        --readme README.md
"""

import re
import sys
import argparse
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

try:
    from jinja2 import Environment, FileSystemLoader, StrictUndefined
except ImportError:
    print('[ERR] Потрібен пакет jinja2: pip install jinja2')
    sys.exit(1)


# ── Структури даних ───────────────────────────────────────────────────────────

@dataclass
class Section:
    number: str
    title: str

@dataclass
class Chapter:
    number: str
    title: str
    sections: list[Section] = field(default_factory=list)

@dataclass
class Part:
    title: str
    chapters: list[Chapter] = field(default_factory=list)

@dataclass
class TocEntry:
    level: str    # part / chapter / section / subsection / ...
    number: str
    title: str
    page: str


# ── LaTeX → Unicode очищення ──────────────────────────────────────────────────

_GREEK_MAP = {
    'mitalpha': 'α', 'mitbeta': 'β', 'mitgamma': 'γ', 'mitdelta': 'δ',
    'mitepsilon': 'ε', 'mitvarepsilon': 'ε', 'mitzeta': 'ζ', 'miteta': 'η',
    'mittheta': 'θ', 'mitiota': 'ι', 'mitkappa': 'κ', 'mitlambda': 'λ',
    'mitmu': 'μ', 'mitnu': 'ν', 'mitxi': 'ξ', 'mitpi': 'π',
    'mitrho': 'ρ', 'mitsigma': 'σ', 'mittau': 'τ', 'mitupsilon': 'υ',
    'mitphi': 'φ', 'mitvarphi': 'φ', 'mitchi': 'χ', 'mitpsi': 'ψ', 'mitomega': 'ω',
    'mitAlpha': 'Α', 'mitBeta': 'Β', 'mitGamma': 'Γ', 'mitDelta': 'Δ',
    'mitEpsilon': 'Ε', 'mitZeta': 'Ζ', 'mitEta': 'Η', 'mitTheta': 'Θ',
    'mitIota': 'Ι', 'mitKappa': 'Κ', 'mitLambda': 'Λ', 'mitMu': 'Μ',
    'mitNu': 'Ν', 'mitXi': 'Ξ', 'mitPi': 'Π', 'mitRho': 'Ρ',
    'mitSigma': 'Σ', 'mitTau': 'Τ', 'mitUpsilon': 'Υ', 'mitPhi': 'Φ',
    'mitChi': 'Χ', 'mitPsi': 'Ψ', 'mitOmega': 'Ω',
}

def _replace_math(text: str) -> str:
    """$...$ → читабельний Unicode."""
    def convert(m):
        expr = m.group(1)
        expr = re.sub(r'\\symbb\{(\w+)\}',
                      lambda x: {'R': 'ℝ', 'C': 'ℂ', 'N': 'ℕ', 'Z': 'ℤ'}.get(x.group(1), x.group(1)), expr)
        expr = re.sub(r'\\(mit\w+)', lambda x: _GREEK_MAP.get(x.group(1), x.group(1)), expr)
        expr = re.sub(r'\\[a-zA-Z]+\s*', '', expr)
        expr = re.sub(r'[{}]', '', expr)
        expr = re.sub(r'\s+', '', expr)   # у math пробіли не потрібні (F_μ ν → F_μν)
        return expr.strip()
    return re.sub(r'\$([^$]+)\$', convert, text)

def clean_latex(text: str) -> str:
    """Прибирає LaTeX-команди, повертає читабельний Unicode-рядок."""
    text = _replace_math(text)
    # \part у LaTeX: "I\hspace {1em}Назва" — прибираємо префікс разом із \hspace
    text = re.sub(r'\S+\\hspace\s*\*?\s*\{[^}]*\}', '', text)
    text = re.sub(r'\\hspace\s*\*?\s*\{[^}]*\}', ' ', text)
    # м'який дефіс \- і примусовий перенос \\
    text = re.sub(r'\\-', '', text)
    text = re.sub(r'\\\\', ' ', text)
    # \texorpdfstring{A}{B} → A
    text = re.sub(r'\\texorpdfstring\{([^}]*)\}\{[^}]*\}', r'\1', text)
    # \cmd{text} → text
    text = re.sub(r'\\[a-zA-Z]+\*?\{([^}]*)\}', r'\1', text)
    # поодинокі команди
    text = re.sub(r'\\[a-zA-Z]+\s*', '', text)
    # залишкові дужки, нормалізація пробілів
    text = re.sub(r'[{}]', '', text)
    text = re.sub(r'\s+', ' ', text)
    return text.strip()


# ── Парсинг .toc → список TocEntry ───────────────────────────────────────────

_NUMBERLINE = re.compile(r'\\numberline\s*\{([^}]*)\}')

# Службові глави без змістового значення для сайту
_SKIP_TITLES = {'Література', 'Алфавітний покажчик'}

def parse_toc(toc_path: Path) -> list[TocEntry]:
    raw = toc_path.read_text(encoding='utf-8', errors='replace')
    raw = re.sub(r'%.*', '', raw).replace('\n', ' ')

    pattern = re.compile(
        r'\\contentsline\s*\{(\w+)\}'
        r'\s*\{((?:[^{}]|\{[^{}]*\})*)\}'
        r'\s*\{([^}]*)\}'
        r'(?:\s*\{[^}]*\})?'
    )
    entries: list[TocEntry] = []
    for m in pattern.finditer(raw):
        level, content, page = m.group(1), m.group(2), m.group(3).strip()

        num_m = _NUMBERLINE.search(content)
        if num_m:
            number = num_m.group(1).strip()
            title  = clean_latex(_NUMBERLINE.sub('', content))
        else:
            number = ''
            title  = clean_latex(content)

        if not title or title in _SKIP_TITLES:
            continue

        entries.append(TocEntry(level=level, number=number, title=title, page=page))

    return entries


# ── Перетворення TocEntry → ієрархічну структуру Part/Chapter/Section ─────────

# Глави без номера, які виводимо але без посилання
_UNNUMBERED_CHAPTERS = {'Передмова', 'Вибір системи одиниць', 'Додатки'}

# Глави без номера, які виносимо за межі частин
_STANDALONE_CHAPTERS = {'Додатки'}

def build_toc_tree(entries: list[TocEntry]) -> tuple[list[Chapter], list[Part], list[Chapter]]:
    r"""
    Повертає (preamble, parts, postamble):
      preamble  — глави до першого \part (Передмова, Вибір системи одиниць)
      parts     — список Part із Chapter-ами та Section-ами
      postamble — іменовані глави-viniatki з _STANDALONE_CHAPTERS (Додатки)
    """
    preamble:  list[Chapter] = []
    parts:     list[Part]    = []
    postamble: list[Chapter] = []

    current_part: Optional[Part] = None
    current_chapter: Optional[Chapter] = None

    for e in entries:
        if e.level == 'part':
            current_part = Part(title=e.title)
            parts.append(current_part)
            current_chapter = None

        elif e.level == 'chapter':
            current_chapter = Chapter(number=e.number, title=e.title)
            if current_part is None:
                preamble.append(current_chapter)
            elif e.title in _STANDALONE_CHAPTERS:
                # Вириваємо з поточної частини і кладемо в postamble
                postamble.append(current_chapter)
            else:
                current_part.chapters.append(current_chapter)

        elif e.level == 'section':
            sec = Section(number=e.number, title=e.title)
            if current_chapter is not None:
                current_chapter.sections.append(sec)

        # subsection і нижче — ігноруємо

    return preamble, parts, postamble


# ── Відповідність назва глави → папка репозиторію ────────────────────────────

_CHAPTER_FOLDERS: dict[str, str] = {
    # Частина I
    'Базові поняття та рівняння':                                'Basics',
    "Розв'язки рівнянь Максвелла":                               'Solutions',
    'Вільне електромагнітне поле':                               'FreeField',
    'Випромінювання':                                            'Radiation',
    # Частина II
    'Перетворення Лоренца як наслідок постулатів Айнштайна':     'LorentzTransform',
    'Співвідношення СТВ у просторі Мінковського':                'Minkovsky',
    'Електродинаміка у просторі Мінковського':                   'RelElectrodynamics',
    'Варіаційний принцип для рівнянь електродинаміки':           'VariationPrinciple',
    'Тензор енергії-імпульсу і закони збереження':               'TEI',
    'Реакція випромінювання':                                    'RadiationReaction',
}


# ── Рендер index.html через Jinja2 ────────────────────────────────────────────

def render_html(template_path: Path, preamble: list[Chapter], parts: list[Part], postamble: list[Chapter]) -> str:
    env = Environment(
        loader=FileSystemLoader(str(template_path.parent)),
        undefined=StrictUndefined,
        autoescape=True,           # HTML-escape автоматично
        keep_trailing_newline=True,
    )
    tmpl = env.get_template(template_path.name)
    return tmpl.render(preamble=preamble, toc=parts, postamble=postamble)

def write_html(html_path: Path, content: str) -> bool:
    """Повністю перезаписує index.html. Повертає True якщо файл змінився."""
    if html_path.exists() and html_path.read_text(encoding='utf-8') == content:
        return False
    html_path.write_text(content, encoding='utf-8')
    return True


# ── Генерація та запис README.md ──────────────────────────────────────────────

_MD_START = '<!-- TOC:START -->'
_MD_END   = '<!-- TOC:END -->'

def generate_md_toc(preamble: list[Chapter], parts: list[Part], postamble: list[Chapter]) -> str:
    lines: list[str] = []

    # Передмова — без номерів, простий список
    for ch in preamble:
        lines.append(f'- {ch.title}')

    for part in parts:
        if part.title:
            if lines:
                lines.append('')
            lines.append(f'### {part.title}')
            lines.append('')
        for ch in part.chapters:
            folder = _CHAPTER_FOLDERS.get(ch.title)
            # numbered list: "1. [Назва](Folder/)" або "1. Назва"
            num = ch.number if ch.number else ''
            if folder:
                lines.append(f'{num}. [{ch.title}]({folder}/)')
            else:
                lines.append(f'- {ch.title}')
            for sec in ch.sections:
                pre = f'{sec.number} ' if sec.number else ''
                lines.append(f'   - {pre}{sec.title}')

    if postamble:
        lines.append('')
        lines.append('### Додатки')
        lines.append('')
        for ch in postamble:
            for sec in ch.sections:
                pre = f'{sec.number} ' if sec.number else ''
                lines.append(f'- {pre}{sec.title}')

    return '\n'.join(lines)


def update_readme(readme_path: Path, toc_md: str) -> bool:
    text = readme_path.read_text(encoding='utf-8')
    new_block = f'{_MD_START}\n{toc_md}\n{_MD_END}'

    if _MD_START in text and _MD_END in text:
        new_text = re.sub(
            re.escape(_MD_START) + r'.*?' + re.escape(_MD_END),
            new_block, text, flags=re.DOTALL
        )
    else:
        block_re = re.compile(r'(## Зміст\s*\n).*', re.DOTALL)
        if block_re.search(text):
            new_text = block_re.sub(r'\1\n' + new_block + '\n', text)
        else:
            new_text = text.rstrip() + f'\n\n## Зміст\n\n{new_block}\n'

    if new_text == text:
        return False
    readme_path.write_text(new_text, encoding='utf-8')
    return True


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description='Генерує index.html з шаблону та оновлює README.md з LaTeX .toc.'
    )
    parser.add_argument('toc',                          help='Шлях до .toc файлу')
    parser.add_argument('--template', default='index.html.j2', help='Jinja2-шаблон')
    parser.add_argument('--html',     default='index.html',    help='Вихідний index.html')
    parser.add_argument('--readme',   default='README.md',     help='Шлях до README.md')
    parser.add_argument('--dry-run',  action='store_true',     help='Не писати файли')
    args = parser.parse_args()

    toc_path      = Path(args.toc)
    template_path = Path(args.template)
    html_path     = Path(args.html)
    readme_path   = Path(args.readme)

    if not toc_path.exists():
        print(f'[ERR] Не знайдено: {toc_path}'); sys.exit(1)
    if not template_path.exists():
        print(f'[ERR] Шаблон не знайдено: {template_path}'); sys.exit(1)

    # ── Парсинг
    print(f'[*] Читаю: {toc_path}')
    entries = parse_toc(toc_path)
    if not entries:
        print('[WARN] TOC порожній.'); sys.exit(0)
    print(f'[*] Записів: {len(entries)}')

    # ── Ієрархія
    preamble, parts, postamble = build_toc_tree(entries)
    for ch in preamble:
        print(f'  [pre]  {ch.number!r:6} {ch.title}')
    for ch in postamble:
        print(f'  [post] {ch.number!r:6} {ch.title}')
    for part in parts:
        indent_p = '' if part.title else '  (без заголовку)'
        print(f'  [part] {part.title!r}{indent_p}')
        for ch in part.chapters:
            print(f'    [ch] {ch.number!r:6} {ch.title}')
            for sec in ch.sections:
                print(f'      [sec] {sec.number!r:8} {sec.title}')

    # ── Рендер HTML
    html_content = render_html(template_path, preamble, parts, postamble)
    toc_md       = generate_md_toc(preamble, parts, postamble)

    if args.dry_run:
        print('\n── HTML (перші 60 рядків) ────────────────────────────────')
        for line in html_content.splitlines()[:60]:
            print(line)
        print('\n── Markdown блок ─────────────────────────────────────────')
        print(toc_md)
        return

    # ── Запис
    changed = write_html(html_path, html_content)
    print(f'[{"OK" if changed else "--"}] {html_path} {"перезаписано" if changed else "без змін"}')

    if readme_path.exists():
        changed = update_readme(readme_path, toc_md)
        print(f'[{"OK" if changed else "--"}] {readme_path} {"оновлено" if changed else "без змін"}')
    else:
        print(f'[SKIP] {readme_path} не існує')


if __name__ == '__main__':
    main()
