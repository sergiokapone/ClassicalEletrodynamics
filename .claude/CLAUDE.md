# ClassicalElectrodynamics: notes for Claude

Reply in Russian (the user writes in Ukrainian or Russian). Comments in `book.js` / `conspect.css` / `postprocess_html.py`
are Ukrainian, in the other Python / PowerShell scripts English: keep that. Commits go straight to `main`; commit and push
only when asked. Sister project with the same tooling: `d:\Projects\LaTeX\ElMag\ElMagConspect` (keep the two in step).

## HTML build
`build-html.ps1` -> `prepare_html.py` (fixed copies in `_html/`) -> lwarp (`ConspectBookHTML.cls`) ->
`postprocess_html.py` (edits the pages in the root) -> `publish_html.py` (moves the site to `docs/`, GitHub Pages serves
`main:/docs`) -> Pagefind index `docs/pagefind/`.

- The HTML version has no subject index (`\printindex` is empty in `ConspectBookHTML.cls`). Додатки (sections А, Б, ...)
  and Література are pages of their own (`\schapterpage` = `\ForceHTMLPage` + `\schapter`, as in ElMagConspect).
- Search marks as in ElMagConspect (`mark_for_indexing`): `<main>` of every `ch*.html` is indexed, the result title is
  the chapter from `<title>`; the book home page is not marked, so Pagefind skips it.

- `docs/` is wiped on every publish except `SITE_OWN` in `publish_html.py` (`index.html`, `google*.html`, `assets/`,
  `serve.py`), the PDF, CNAME and dot-files. So a fix to the generated pages goes into `postprocess_html.py` /
  `prepare_html.py` / the class, never into `docs/*.html` by hand (patching `docs/` directly is fine only as a preview).
- The source of `book.js`, `conspect.css` (book) and `styles.css` (landing page `index.html`) is `docs/assets/`; there is
  no copy in the project root (a root copy, if newer, would replace it on publish). `book.js` and `conspect.css` come
  from ElMagConspect; differences on purpose: the home page of the book has the side panel (`add_home_sidebar`), there
  only «Головна» is highlighted; the drawer button says «Пошук і зміст»; part headings (`.tocpart`) in the side panel.
- The search field is made by `book.js` (not written into the pages); it needs http: `python docs/serve.py`
  (git-ignored). Pagefind is pinned (`pagefind@1.3.0`, as in ElMagConspect).
- The PDF (`docs/ClassicalElectrodynamics.pdf`, linearized by `publish_pdf.ps1`) stays in the repo on purpose: the
  landing page and the side panel link to it. Old PDF / docs/ versions are cleaned from the history with
  `clean_repo.py` (`--dry-run` first; paths in `purge-paths.txt`).
- `ced.py` is the entry point for everything (pdf, html, serve, clean, purge, size, status, push): an interactive shell
  or one command; it only calls the scripts. A new script of the project gets a command there.
  `run.ps1` skips its pause and Clear-Host when `CED_CLI` is set.

## PDF contents
Page breaks of the contents come from penalties in `ConspectBook.cls` (as in ElMagConspect): no break after a part
entry, a chapter entry keeps its first section. No manual `\addtocontents{toc}{\clearpage}` in the .tex.
Додатки, Література and the index are part-level entries (bookmarks at the root, not inside part II); `\tocnopartname`
drops the «Частина» prefix for them, the `bookmark` package keeps А, Б, ... siblings under Додатки. Running heads
(style `main`): part on even pages, chapter on odd ones.

## MathJax
- lwarp hard-codes MathJax 3 (`tex-svg.js`); MathJax 3 has no line breaking: `book.js` splits long display formulas
  itself (top-level TeX break points -> `aligned`).
- Macros for MathJax: `mathjax-macros.tex` -> `mathjax2lwarp.py` -> `lwarp-mathjax.tex`. `postprocess_html.py` adds the
  `unicode` and `boldsymbol` packages to lwarp's MathJax config.
