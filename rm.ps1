# rm.ps1 - removes the auxiliary files of a LaTeX build in the CURRENT folder.
# Run it in the project root or in any chapter folder (it does not go into subfolders).
# Not touched: sources, PDFs (only test.pdf is removed), the files lwarp generated (that is clwarp-clean.ps1)
# and the docs folder.
#   .\rm.ps1          auxiliary files
#   .\rm.ps1 -Bak     also the editor backups *.bak* (Charges.bak0 ...); they are kept by default
param([switch]$Bak)

$ext = @(
    'aux', 'log', 'out', 'toc', 'lof', 'lot', 'tmp',          # LaTeX core
    'idx', 'ind', 'ilg',                                      # makeindex
    'bbl', 'blg', 'bcf', 'run.xml',                           # biber
    'acn', 'acr', 'alg', 'glg', 'glo', 'gls',                 # glossaries
    'snm', 'nav', 'vrb',                                      # beamer
    'fdb_latexmk', 'fls',                                     # latexmk
    'xdv', 'synctex.gz', 'synctex(busy)', 'thm',              # other
    'gnuplot', 'table'                                        # pgfplots + gnuplot (*.curve.gnuplot, *.curve.table)
)
$masks = @($ext | ForEach-Object { "*.$_" })
if ($Bak) { $masks += '*.bak*' }
$names = @('test.pdf')

$removed = 0; $locked = 0
foreach ($f in Get-ChildItem -LiteralPath . -File) {
    $hit = $names -contains $f.Name
    foreach ($m in $masks) { if ($f.Name -like $m) { $hit = $true; break } }
    if (-not $hit) { continue }
    Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $f.FullName) { $locked++ } else { $removed++ }
}
foreach ($d in Get-ChildItem -LiteralPath . -Directory -Filter '_minted*') {      # minted cache
    Remove-Item -LiteralPath $d.FullName -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [folder removed] $($d.Name)" -ForegroundColor Yellow
}
Write-Host "Removed files: $removed" -ForegroundColor Green
if ($locked -gt 0) { Write-Host "Could not remove (in use?): $locked" -ForegroundColor Yellow }
