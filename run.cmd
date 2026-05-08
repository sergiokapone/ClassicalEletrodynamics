::=======================================================
:: Build script for ClassicalElectrodynamics (LuaLaTeX)
::=======================================================
::
:: Requirements:
::
::   1. MiKTeX  -- https://miktex.org/
::      latexmk, lualatex, upmendex, biber
::
::   2. Cygwin  -- https://www.cygwin.com/
::      Packages: grep, gawk, tail
::      PATH: C:\cygwin64\bin  має бути в системному PATH
::
::   3. platex  -- https://github.com/stefanhepp/pplatex
::      Packages: pplatex
::      PATH: d:\Programs\LaTeX\pplatex\bin  має бути в системному PATH
::
::   4. gnuplot  -- http://www.gnuplot.info
::      Packages: gnuplot
::      PATH: d:\Programs\GnuPlot\bin  має бути в системному PATH
::
:: Додати зміннів PATH можна через команду
::   rundll32.exe sysdm.cpl,EditEnvironmentVariables
::
::=======================================================

@echo off
chcp 65001 > nul
title Project Build — ClassicalElectrodynamics

SETLOCAL enabledelayedexpansion

:: === Отримати реальний ESC-символ (0x1B) ===
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"

set "R=%ESC%[0m"
set "BOLD=%ESC%[1m"
set "CYAN=%ESC%[96m"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "WHITE=%ESC%[97m"
set "GRAY=%ESC%[90m"

cls

echo %BOLD%%CYAN%+------------------------------------------------------+%R%
echo %BOLD%%CYAN%^|   LaTeXmk Build  --  Classical Electrodynamics       ^|%R%
echo %BOLD%%CYAN%^|   NN FTI, KPI im. Ihoria Sikorskoho                  ^|%R%
echo %BOLD%%CYAN%+------------------------------------------------------+%R%
echo.

for /f "tokens=1-3 delims=/.-" %%a in ("%date%") do set "TODAY=%%c-%%b-%%a"
for /f "tokens=1-2 delims=:." %%a in ("%time%")  do set "NOW=%%a:%%b"

echo  %GRAY%Started : %WHITE%%TODAY%  %NOW%%R%
echo  %GRAY%Target  : %WHITE%ClassicalElectrodynamics.tex%R%
echo  %GRAY%Engine  : %WHITE%LuaLaTeX  (latexmk -f -g)%R%
echo  %GRAY%Output  : %WHITE%ClassicalElectrodynamics.pdf%R%
echo.
echo  %YELLOW%-------------------------------------------------------%R%
echo  %BOLD%%YELLOW%  Compiling ...%R%
echo  %YELLOW%-------------------------------------------------------%R%
echo.

for /f "tokens=1-3 delims=:." %%a in ("%TIME%") do set /a "T0=%%a*3600+%%b*60+%%c"

latexmk -f -g -lualatex ClassicalElectrodynamics.tex
set "EC=%ERRORLEVEL%"

set "LOGFILE=ClassicalElectrodynamics.log"
set "PPLATEX=ppluatex.exe"

echo.
echo  %YELLOW%-------------------------------------------------------%R%
echo  %BOLD%%WHITE%  pplatex log summary:%R%
echo  %YELLOW%-------------------------------------------------------%R%
echo.
"%PPLATEX%" -i "%LOGFILE%"
echo.

echo  %YELLOW%-------------------------------------------------------%R%
echo  %BOLD%%WHITE%  Build summary:%R%
echo  %YELLOW%-------------------------------------------------------%R%

:: --- Overfull hbox report ---
set "OVF_THRESHOLD=5"

set "found_ovf=0"
set "OVF_LINES="
for /f "delims=" %%w in ('grep -nE "Overfull .hbox \([0-9]+\.[0-9]+pt too wide\)" "%LOGFILE%" ^| gawk "match($0, /[0-9]+\.[0-9]+pt/, a) && substr(a[0], 1, length(a[0])-2)+0 > %OVF_THRESHOLD%"') do (
    if !found_ovf!==0 (
        echo  %YELLOW%-------------------------------------------------------%R%
        echo  %BOLD%%WHITE%  Overfull hbox ^> %OVF_THRESHOLD%pt :%R%
        echo  %YELLOW%-------------------------------------------------------%R%
    )
    echo  %RED%  %%w%R%
    set "found_ovf=1"
)
echo.


:: --- Warnings ---
for /f %%n in ('grep -c "LaTeX Warning" "%LOGFILE%"') do (
    if %%n GTR 0 (
        echo  %GRAY%  Warnings: %YELLOW%%%n%R%
    ) else (
        echo  %GRAY%  Warnings: %GREEN%0%R%
    )
)

:: --- Nullfont ---
for /f %%n in ('grep -c "nullfont" "%LOGFILE%"') do (
    if %%n GTR 0 (
        echo  %GRAY%  Nullfont: %YELLOW%%%n ^(pgfplots^)%R%
    ) else (
        echo  %GRAY%  Nullfont: %GREEN%0%R%
    )
)

:: --- Missing chars ---
for /f %%n in ('grep -ic "missing character" "%LOGFILE%"') do (
    if %%n GTR 0 (
        echo  %GRAY%  Missing : %RED%%%n char^(s^)%R%
    ) else (
        echo  %GRAY%  Missing : %GREEN%none%R%
    )
)

:: --- Pages + size ---
for /f "tokens=*" %%s in ('grep -oE "[0-9]+ pages, [0-9]+ bytes" "%LOGFILE%"') do (
    echo  %GRAY%  PDF     : %WHITE%%%s%R%
)

for /f "tokens=1-3 delims=:." %%a in ("%TIME%") do set /a "T1=%%a*3600+%%b*60+%%c"
set /a "ELAPSED=T1-T0"

echo.
echo  %YELLOW%-------------------------------------------------------%R%

if %EC%==0 (
    echo  %BOLD%%GREEN%  [ SUCCESS ]  Build completed%R%
    echo  %GRAY%  Elapsed : %WHITE%%ELAPSED% s%R%
    echo  %GRAY%  Code    : %GREEN%0%R%
) else (
    echo  %BOLD%%RED%  [ FAILED ]   Build error%R%
    echo  %GRAY%  Code    : %RED%%EC%%R%
    echo  %GRAY%  Elapsed : %WHITE%%ELAPSED% s%R%
    echo  %GRAY%  Log     : %YELLOW%ClassicalElectrodynamics.log%R%
    echo.
    echo  %YELLOW%  Hint: grep "^!" ClassicalElectrodynamics.log%R%
)

echo  %YELLOW%-------------------------------------------------------%R%
echo.

pause
