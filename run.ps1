<#
.SYNOPSIS
    Build script for tex-file

.REQUIREMENTS
    1. MiKTeX  -- https://miktex.org/
       latexmk, lualatex, upmendex, biber

    2. pplatex  -- https://github.com/stefanhepp/pplatex
       Бінарник ppluatex.exe в PATH
       PATH: d:\Programs\LaTeX\pplatex\bin

    3. gnuplot  -- http://www.gnuplot.info
       PATH: d:\Programs\GnuPlot\bin

    4. PowerShell 5.1+
       Перевірити: $PSVersionTable.PSVersion

.NOTES
    Додати змінні PATH:
    rundll32.exe sysdm.cpl,EditEnvironmentVariables

    Запуск:
    pwsh -File run.ps1
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# --- Config ---
$FOLDER        = Split-Path -Leaf $PSScriptRoot
$TEXFILE       = "$FOLDER.tex"
$LOGFILE       = "$FOLDER.log"
$PPLATEX       = "ppluatex.exe"

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
# $SEP2 = "  ${YELLOW}-------------------------------------------------------${R}"

Clear-Host

# --- Header ---
Write-Host "${BOLD}${CYAN}+------------------------------------------------------+${R}"
Write-Host "${BOLD}${CYAN}|   LaTeXmk Build  --  ${WHITE}${FOLDER}${R}"
Write-Host "${BOLD}${CYAN}+------------------------------------------------------+${R}"
Write-Host

$now = Get-Date
Write-Host "  ${GRAY}Started : ${WHITE}$($now.ToString('yyyy-MM-dd  HH:mm'))${R}"
Write-Host "  ${GRAY}Target  : ${WHITE}${TEXFILE}${R}"
Write-Host "  ${GRAY}Engine  : ${WHITE}LuaLaTeX  (latexmk -f -g)${R}"
Write-Host "  ${GRAY}Output  : ${WHITE}$FOLDER.pdf${R}"
Write-Host
Write-Host $SEP
Write-Host "  ${BOLD}${YELLOW}Compiling ...${R}"
Write-Host $SEP
Write-Host

# --- Compile ---
$sw = [System.Diagnostics.Stopwatch]::StartNew()
latexmk -f -g -lualatex $TEXFILE
$EC = $LASTEXITCODE
$sw.Stop()
$elapsed = [int]$sw.Elapsed.TotalSeconds

# --- pplatex ---
Write-Host
Write-Host $SEP
Write-Host "  ${BOLD}${WHITE}pplatex log summary:${R}"
Write-Host $SEP
Write-Host
& $PPLATEX -i $LOGFILE
Write-Host

Write-Host $SEP
Write-Host "  ${GRAY}  Overfull hbox  : acceptable < 2pt, tolerant < 5pt${R}"
Write-Host "  ${GRAY}  Underfull vbox : badness 0-1000 ok, 1000-5000 tolerant, 5000+ badly, 10000 = hopeless${R}"
Write-Host $SEP
Write-Host

# --- Parse log ---
$log = Get-Content $LOGFILE -Encoding UTF8

# Overfull
$ovfLines = $log | Select-String "Overfull .hbox \((\d+\.\d+)pt too wide\)" |
    Where-Object { [double]$_.Matches[0].Groups[1].Value -gt $OVF_THRESHOLD }

if ($ovfLines.Count -gt 0) {
    Write-Host $SEP
    Write-Host "  ${BOLD}${WHITE}Overfull hbox > ${OVF_THRESHOLD}pt :${R}"
    Write-Host $SEP
    $ovfLines | ForEach-Object { Write-Host "  ${RED}$($_.Line)${R}" }
    Write-Host
}

# Summary
Write-Host $SEP
Write-Host "  ${BOLD}${WHITE}Build summary:${R}"
Write-Host $SEP

# Warnings
$nWarn = ($log | Select-String "LaTeX Warning").Count
$warnColor = if ($nWarn -gt 0) { $YELLOW } else { $GREEN }
Write-Host "  ${GRAY}Warnings: ${warnColor}${nWarn}${R}"

# Nullfont
$nNull = ($log | Select-String "nullfont").Count
$nullColor = if ($nNull -gt 0) { $YELLOW } else { $GREEN }
Write-Host "  ${GRAY}Nullfont: ${nullColor}${nNull}$(if ($nNull -gt 0) { ' (pgfplots)' })${R}"

# Missing chars (без nullfont)
$nMiss = ($log | Select-String "missing character" |
    Where-Object { $_.Line -notmatch "nullfont" }).Count
$missColor = if ($nMiss -gt 0) { $RED } else { $GREEN }
$missText  = if ($nMiss -gt 0) { "$nMiss char(s)" } else { "none" }
Write-Host "  ${GRAY}Missing : ${missColor}${missText}${R}"

# PDF info
$pdfInfo = ($log | Select-String "(\d+ pages, \d+ bytes)" | Select-Object -Last 1)
if ($pdfInfo) {
    Write-Host "  ${GRAY}PDF     : ${WHITE}$($pdfInfo.Matches[0].Groups[1].Value)${R}"
}

Write-Host
Write-Host $SEP

if ($EC -eq 0) {
    Write-Host "  ${BOLD}${GREEN}[ SUCCESS ]  Build completed${R}"
    Write-Host "  ${GRAY}Elapsed : ${WHITE}${elapsed} s${R}"
    Write-Host "  ${GRAY}Code    : ${GREEN}0${R}"
} else {
    Write-Host "  ${BOLD}${RED}[ FAILED ]   Build error${R}"
    Write-Host "  ${GRAY}Code    : ${RED}${EC}${R}"
    Write-Host "  ${GRAY}Elapsed : ${WHITE}${elapsed} s${R}"
    Write-Host "  ${GRAY}Log     : ${YELLOW}${LOGFILE}${R}"
    Write-Host
    Write-Host "  ${YELLOW}  Hint: Select-String '^\!' ${LOGFILE}${R}"
}

Write-Host $SEP
Write-Host
Read-Host "Press Enter to continue"
