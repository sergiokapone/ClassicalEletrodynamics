import os
import re
from html.parser import HTMLParser

lwarp_file = 'ClassicalElectrodynamics-html.html'
index_file = 'index.html'

start_marker = '<!-- ── Зміст (генерується з .toc) ─────────────────────────────── -->'
end_marker = '<!-- ── /Зміст ──────────────────────────────────────────────────── -->'

class LwarpTOCParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_nav = False
        self.in_a = False
        self.in_span = False
        self.current_href = ""
        self.current_class = ""
        self.current_num = ""
        self.current_title = ""

        self.preamble = []
        self.parts = []
        self.appendices = []
        self.current_part = None
        self.current_chapter = None

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        if tag == "nav" and attrs_dict.get("class") == "toc":
            self.in_nav = True
        elif self.in_nav and tag == "a":
            self.in_a = True
            self.current_href = attrs_dict.get("href", "#")
            self.current_class = attrs_dict.get("class", "")
            self.current_num = ""
            self.current_title = ""
        elif self.in_a and tag == "span" and attrs_dict.get("class") == "sectionnumber":
            self.in_span = True

    def handle_endtag(self, tag):
        if tag == "span" and self.in_span:
            self.in_span = False
        elif tag == "a" and self.in_a:
            self.in_a = False
            self.process_item()
        elif tag == "nav" and self.in_nav:
            self.in_nav = False

    def handle_data(self, data):
        if self.in_span:
            self.current_num += data
        elif self.in_a:
            self.current_title += data

    def process_item(self):
        num_str = self.current_num.strip()
        title_str = self.current_title.strip()
        title_str = re.sub(r'^[ \s\xa0]+', '', title_str)
        cls = self.current_class
        href = self.current_href

        if 'tocpart' in cls:
            self.current_part = {
                'num': num_str,
                'title': title_str,
                'href': href,
                'chapters': []
            }
            self.parts.append(self.current_part)
            self.current_chapter = None

        elif 'tocchapter' in cls:
            if not num_str and not self.current_part:
                self.preamble.append({'title': title_str, 'href': href})
            else:
                ch_item = {
                    'num': num_str,
                    'title': title_str,
                    'href': href,
                    'sections': []
                }
                if self.current_part:
                    self.current_part['chapters'].append(ch_item)
                else:
                    if not self.parts:
                        self.current_part = {'num': '', 'title': '', 'href': '', 'chapters': []}
                        self.parts.append(self.current_part)
                    self.current_part['chapters'].append(ch_item)
                self.current_chapter = ch_item

        elif 'tocsection' in cls:
            if num_str.startswith('.'):
                app_num_map = {'.1': 'А', '.2': 'Б', '.3': 'В', '.4': 'Г', '.5': 'Д', '.6': 'Е', '.7': 'Є'}
                app_letter = app_num_map.get(num_str, num_str)
                self.appendices.append({'num': app_letter, 'title': title_str, 'href': href})
            else:
                sec_item = {
                    'num': num_str,
                    'title': title_str,
                    'href': href
                }
                if self.current_chapter:
                    self.current_chapter['sections'].append(sec_item)

def render_beautiful_toc(parser):
    out = []

    if parser.preamble:
        out.append('<ul class="toc-list toc-preamble">')
        for item in parser.preamble:
            out.append(f'    <li><a href="{item["href"]}"><span class="toc-title">{item["title"]}</span></a></li>')
        out.append('</ul>\n')

    for part in parser.parts:
        out.append('<div class="section">')
        part_header = f'<span class="part-num">Частина {part["num"]}:</span> ' if part["num"] else ''
        out.append(f'    <h2 class="section-heading"><a href="{part["href"]}">{part_header}{part["title"]}</a></h2>')
        out.append('    <ul class="toc-list">')
        for ch in parser.parts[0]['chapters'] if part == parser.parts[0] else part['chapters']:
            out.append('        <li>')
            if ch["num"]:
                out.append(f'            <span class="toc-num">{ch["num"]}</span>')
            out.append(f'            <a href="{ch["href"]}" class="toc-title">{ch["title"]}</a>')
            if ch['sections']:
                out.append('            <ul class="sub-list">')
                for sec in ch['sections']:
                    out.append(f'                <li><a href="{sec["href"]}"><span class="sub-num">{sec["num"]}</span> {sec["title"]}</a></li>')
                out.append('            </ul>')
            out.append('        </li>')
        out.append('    </ul>')
        out.append('</div>\n')

    if parser.appendices:
        out.append('<div class="section section-appendix">')
        out.append('    <h2 class="section-heading">Додатки</h2>')
        out.append('    <ul class="toc-list">')
        for app in parser.appendices:
            out.append(f'        <li><a href="{app["href"]}"><span class="toc-num">{app["num"]}</span> {app["title"]}</a></li>')
        out.append('    </ul>')
        out.append('</div>')

    return '\n'.join(out)

try:
    if not os.path.exists(lwarp_file):
        print(f"Помилка: файл '{lwarp_file}' не знайдено.")
        exit(1)

    with open(lwarp_file, 'r', encoding='utf-8') as f:
        html_content = f.read()

    parser = LwarpTOCParser()
    parser.feed(html_content)
    beautiful_toc = render_beautiful_toc(parser)

    with open(index_file, 'r', encoding='utf-8') as f:
        index_content = f.read()

    if start_marker in index_content and end_marker in index_content:
        before = index_content.split(start_marker)[0]
        after = index_content.split(end_marker)[1]

        new_index = before + start_marker + "\n" + beautiful_toc + "\n" + end_marker + after

        with open(index_file, 'w', encoding='utf-8') as f:
            f.write(new_index)

        print("Успішно згенеровано красивий зміст у index.html!")
    else:
        print("Маркери не знайдено в index.html.")

except Exception as e:
    print(f"Помилка: {e}")
