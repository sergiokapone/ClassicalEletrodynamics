<#
.SYNOPSIS
    ClassicalElectrodynamics.pdf (з кореня проєкту) -> лінеаризує -> docs/ClassicalElectrodynamics.pdf.
    Сторінка посібника (docs/index.html) і бічна панель HTML-книги посилаються саме на docs/.

.NOTES
    Запуск:
    pwsh -File publish_pdf.ps1

    Потрібен qpdf у PATH:
    winget install qpdf
#>

param(
    [string]$Folder = $PSScriptRoot,
    [string]$DocsSubfolder = "docs",
    [string]$Name = "ClassicalElectrodynamics.pdf"
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

$src   = Join-Path $Folder $Name
$docs  = Join-Path $Folder $DocsSubfolder
$final = Join-Path $docs $Name
$tmp   = Join-Path $docs ($Name + '.tmp')

# --- 1. Перевірка наявності qpdf ---
if (-not (Get-Command qpdf -ErrorAction SilentlyContinue)) {
    Write-Host "qpdf не знайдено в PATH. Встановіть: winget install qpdf" -ForegroundColor Red
    exit 1
}

# --- 2. Перевірка вхідного файлу ---
if (-not (Test-Path $src)) {
    Write-Host "Не знайдено: $src" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $docs)) { New-Item -ItemType Directory -Path $docs | Out-Null }

# --- 3. Лінеаризація у тимчасовий файл (docs/ лишається цілим, якщо qpdf впаде) ---
# Прапорець --warning-exit-0 змушує qpdf повертати код 0, якщо були лише попередження (warnings)
& qpdf --warning-exit-0 --linearize --newline-before-endstream $src $tmp
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $tmp)) {
    Write-Host "qpdf завершився з помилкою (код $LASTEXITCODE)." -ForegroundColor Red
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    exit 1
}

# --- 4. На місце старого PDF; вихідний файл із кореня прибирається ---
Move-Item -Path $tmp -Destination $final -Force
if (-not (Test-Path $final)) {
    Write-Host "Не вдалося записати $final" -ForegroundColor Red
    exit 1
}
Remove-Item $src -Force

$size = (Get-Item $final).Length
Write-Host ("OK: {0} -> {1} (лінеаризовано, {2:N0} байт)" -f $Name, $final, $size) -ForegroundColor Green
