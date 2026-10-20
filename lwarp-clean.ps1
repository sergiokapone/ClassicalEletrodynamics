# lwarp-clean.ps1 — повне прибирання всіх згенерованих файлів та папок Lwarp

$ErrorActionPreference = 'SilentlyContinue'
Set-Location -LiteralPath $PSScriptRoot

$main = 'ClassicalElectrodynamics-html'

Write-Host "Починаємо повне очищення проектних файлів Lwarp..." -ForegroundColor Cyan

# 1. Згенеровані папки
$foldersToRemove = @(
    # "$main-images",
    # "_html",
    "lateximages"
)

foreach ($folder in $foldersToRemove) {
    if (Test-Path $folder) {
        Remove-Item -LiteralPath $folder -Recurse -Force
        Write-Host "  [Папка видалена] $folder" -ForegroundColor Yellow
    }
}

# 2. Маски всіх службових та тимчасових файлів Lwarp
$patterns = @(
    # Конфіги та скрипти Lwarp
    "lwarpmk.conf",
    "*.lwarpmkconf",
    "lwarp.ist",
    "lwarp.xdy",
    "lwarp_one_limage.cmd",

    # Згенеровані TeX, Cut та Text файли
    "*_html.tex",
    "lwarp-mathjax.tex",
    "lwarp-tikzdefs.tex",
    "*.cut",
    "*-images.txt",
    "lwarp_*.txt",

    # Таблиці, gnuplot, структури змісту та теорем
    "*gnuplot",
    "*table",
    "*.sidetoc",
    "*.thm",

    # Службові файли компіляції LaTeX (aux, log, out, toc тощо)
    "$main*.aux",
    "$main*.log",
    "$main*.out",
    "$main*.toc",
    "$main*.lof",
    "$main*.lot",
    "$main*.bcf",
    "$main*.blg",
    "$main*.run.xml",
    "$main*.bbl",
    "main.log",
    "build-error.txt",
    "sample_project.css"

    # Згенеровані HTML-сторінки
    #"$main*.html",
    #"ch*.html",
)

$deletedCount = 0

foreach ($pattern in $patterns) {
    $files = Get-ChildItem -Path . -File -Filter $pattern
    foreach ($file in $files) {
        Remove-Item -LiteralPath $file.FullName -Force
        $deletedCount++
    }
}

Write-Host "Готово! Видалено файлів: $deletedCount" -ForegroundColor Green