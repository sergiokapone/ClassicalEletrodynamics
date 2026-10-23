<#
.SYNOPSIS
    Build script for tex-file: PDF of the book (latexmk + LuaLaTeX), quiet output.

.REQUIREMENTS
    1. TeX Live / MiKTeX: latexmk, lualatex, upmendex, biber
    2. texlogsieve (tlmgr install texlogsieve) -- зведення логу; без нього лише власний підсумок
    3. gnuplot  -- http://www.gnuplot.info
       PATH: d:\Programs\GnuPlot\bin
    4. PowerShell 5.1+ (краще pwsh 7)

.NOTES
    Запуск:
    pwsh -File run.ps1            тихо: один рядок прогресу, у кінці -- зведення texlogsieve
    pwsh -File run.ps1 -Full      повний вивід latexmk (як раніше)

    На першій помилці LaTeX збірка зупиняється (-halt-on-error); помилка з контекстом
    друкується й зберігається в build-error.txt.
    З ced.py (CED_CLI) не чекає Enter і не очищає екран.
#>
param([switch]$Full)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# --- Config ---
$FOLDER  = Split-Path -Leaf $PSScriptRoot

# --- Вибір цільового файлу: "folder" або "main" ---
$MODE = "folder"        # ← змінюйте ТУТ: "folder" або "main"

if ($MODE -eq "main") {
    $BASE = "main"
} else {
    $BASE = $FOLDER
}

$TEXFILE = "$BASE.tex"
$LOGFILE = "$BASE.log"

$OVF_THRESHOLD = 5

# --- ANSI colors ---
$ESC    = [char]27
$R      = "$ESC[0m"
$BOLD   = "$ESC[1m"
$CYAN   = "$ESC[96m"
$GREEN  = "$ESC[92m"
$YELLOW = "$ESC[93m"
$RED    = "$ESC[91m"
$WHITE  = "$ESC[97m"
$GRAY   = "$ESC[90m"

$SEP  = "  ${YELLOW}-------------------------------------------------------${R}"

# Перша помилка LaTeX у лозі: файл, що читався, сама помилка й контекст -> екран і build-error.txt
function Show-FirstError([string]$log) {
    if (-not (Test-Path $log)) { return $false }
    $lines = Get-Content -LiteralPath $log -Encoding UTF8
    $idx = -1
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i].StartsWith('!')) { $idx = $i; break } }
    if ($idx -lt 0) { return $false }
    $file = ''
    for ($j = $idx; $j -ge 0; $j--) {
        if ($lines[$j] -match '\((\.[\\/][^\s()]*\.(tex|tikz|cls|sty))') { $file = $Matches[1]; break }
    }
    $end = [Math]::Min($idx + 9, $lines.Count - 1)
    for ($k = $idx + 1; $k -le $end; $k++) {                 # статистика пам'яті LuaTeX -- не контекст помилки
        if ($lines[$k] -match "^Here is how much of") { $end = $k - 1; break }
    }
    $block = @("log: $log", "file being read: $file") + $lines[$idx..$end]
    $block | Set-Content -LiteralPath 'build-error.txt' -Encoding UTF8
    Write-Host
    Write-Host "  ${BOLD}${RED}FIRST LaTeX ERROR${R} ${GRAY}(also saved to build-error.txt):${R}"
    $block | ForEach-Object { Write-Host "  ${RED}$_${R}" }
    return $true
}

# Зведення texlogsieve: переповнені бокси (сторінки), повторювані попередження, невизначені посилання
function Show-Sieve([string]$log) {
    if (-not (Test-Path $log)) { return }
    if (-not (Get-Command texlogsieve -ErrorAction SilentlyContinue)) {
        Write-Host "  ${GRAY}(texlogsieve not found: tlmgr install texlogsieve)${R}"; return
    }
    $o = @(& texlogsieve --no-color --no-heartbeat --only-summary --no-summary-detail $log 2>&1 |
           ForEach-Object { "$_" } | Where-Object { $_.Trim() -ne '' })
    if ($o.Count -eq 0) { Write-Host "  ${GREEN}texlogsieve: log is clean${R}"; return }
    Write-Host "  ${GRAY}texlogsieve:${R}"
    foreach ($l in $o) {
        if ($l.Length -gt 300) { $l = $l.Substring(0, 300) + ' ...' }   # список сторінок/файлів буває на екран завдовжки
        Write-Host "    ${YELLOW}$l${R}"
    }
}

if (-not $env:CED_CLI) { Clear-Host }   # в оболонці ced.py не стираємо попередній вивід

# --- Header ---
Write-Host "${BOLD}${CYAN}PDF build${R}  ${WHITE}${TEXFILE}${R}  ${GRAY}$((Get-Date).ToString('yyyy-MM-dd HH:mm'))  latexmk + LuaLaTeX${R}"

# --- Compile ---
$lualatex = 'lualatex --shell-escape -interaction=nonstopmode -halt-on-error %O %S'
$sw = [System.Diagnostics.Stopwatch]::StartNew()
if ($Full) {
    latexmk -g -pdflua "-lualatex=$lualatex" $TEXFILE
    $EC = $LASTEXITCODE
    $out = @()
} else {
    # тихо: вивід збирається, на екрані лише поточний крок latexmk (lualatex 1, biber, lualatex 2 ...)
    $out = New-Object System.Collections.Generic.List[string]
    $step = 'starting'; $shown = ''
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    & latexmk -g -pdflua "-lualatex=$lualatex" $TEXFILE 2>&1 | ForEach-Object {
        $line = "$_"; $out.Add($line)
        if ($line -match "Run number (\d+) of rule '([^']+)'") { $step = "$($Matches[2]) $($Matches[1])" }
        elseif ($line -match "^Latexmk: applying rule '([^']+)'") { $step = $Matches[1] }
        $s = "`r  - {0,-40} {1,4}s" -f $step, [int]$sw.Elapsed.TotalSeconds
        if ($s -ne $shown) { Write-Host $s -NoNewline; $shown = $s }
    }
    $EC = $LASTEXITCODE
    $ErrorActionPreference = $old
    Write-Host ("`r" + (' ' * 60) + "`r") -NoNewline
}
$sw.Stop()
$elapsed = [int]$sw.Elapsed.TotalSeconds

if ($EC -ne 0) {
    Write-Host "  ${BOLD}${RED}[ FAILED ]${R}  ${GRAY}latexmk exit code ${RED}$EC${GRAY}, ${elapsed} s${R}"
    # помилка LaTeX -- з логу; інакше (biber, upmendex, latexmk) -- хвіст виводу без стандартних порад latexmk
    if (-not (Show-FirstError $LOGFILE) -and $out.Count -gt 0) {
        Write-Host "  ${GRAY}last lines of the latexmk output:${R}"
        $out | Where-Object { $_ -notmatch '^\s*(Latexmk: Sometimes|to try to force|But normally|error, and then|In some cases|latexmk after|Reverting Windows|perl\.exe|.*runscript\.tlu)' } |
            Select-Object -Last 15 | ForEach-Object { Write-Host "    ${GRAY}$_${R}" }
    }
    Write-Host "  ${GRAY}Log: ${YELLOW}${LOGFILE}${GRAY}   full output: pwsh -File run.ps1 -Full${R}"
    if (-not $env:CED_CLI) { Read-Host "Press Enter to continue" }
    exit $EC
}
Remove-Item -LiteralPath 'build-error.txt' -ErrorAction SilentlyContinue

# --- Summary ---
$log = Get-Content $LOGFILE -Encoding UTF8
Show-Sieve $LOGFILE

$ovf = @($log | Select-String "Overfull .hbox \((\d+\.\d+)pt too wide\)(.*)" |
         Where-Object { [double]$_.Matches[0].Groups[1].Value -gt $OVF_THRESHOLD })
if ($ovf.Count -gt 0) {
    Write-Host "  ${GRAY}Overfull hbox > ${OVF_THRESHOLD}pt: ${YELLOW}$($ovf.Count)${R}"
    $ovf | Select-Object -First 10 | ForEach-Object { Write-Host "    ${YELLOW}$($_.Line.Trim())${R}" }
    if ($ovf.Count -gt 10) { Write-Host "    ${GRAY}... and $($ovf.Count - 10) more ($LOGFILE)${R}" }
}
$nMiss = @($log | Select-String "missing character" | Where-Object { $_.Line -notmatch "nullfont" }).Count
if ($nMiss -gt 0) { Write-Host "  ${GRAY}Missing characters: ${RED}$nMiss${R}" }

$pdfInfo = ($log | Select-String "\((\d+) pages?, (\d+) bytes\)" | Select-Object -Last 1)
$pdfText = if ($pdfInfo) { "{0} pages, {1:N1} MB" -f $pdfInfo.Matches[0].Groups[1].Value, ([double]$pdfInfo.Matches[0].Groups[2].Value / 1MB) } else { '' }
Write-Host "  ${BOLD}${GREEN}[ OK ]${R}  ${WHITE}$BASE.pdf${R}  ${GRAY}$pdfText, ${elapsed} s${R}"

if (-not $env:CED_CLI) { Read-Host "Press Enter to continue" }
exit $EC
