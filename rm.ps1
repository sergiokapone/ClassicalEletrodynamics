$base = (Get-Item .).Name

# LaTeX core
'aux', 'log', 'out', 'lof', 'lot',
# makeindex
'idx', 'ind', 'ilg',
# biber
'bbl', 'blg', 'bcf', 'run.xml',
# glossaries
'acn', 'acr', 'alg', 'glg', 'glo', 'gls',
# beamer
'snm', 'nav', 'vrb',
# latexmk
'fdb_latexmk', 'fls',
# інше
'xdv', 'synctex.gz', 'synctex.gz(busy)', 'thm',
# gnuplot (pgfplots)
'*.gnuplot', '*.table' |
    ForEach-Object { Remove-Item -ErrorAction SilentlyContinue "*.$_" }