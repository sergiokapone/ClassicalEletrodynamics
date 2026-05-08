# ============================================================
#  .latexmkrc — LuaLaTeX + Biber + upmendex
#  Положи этот файл в корень проекта (рядом с main.tex)
# ============================================================

$max_repeat = 5;
$force_mode = 1;

# --- Тишина ----------------------------------------------
$silent = 1;
$silence_logfile_warnings = 1;

# --- Движок: LuaLaTeX ------------------------------------
$pdf_mode = 4;   # 1=pdflatex, 4=lualatex, 5=xelatex

$lualatex = 'lualatex -shell-escape -synctex=1 -interaction=nonstopmode -file-line-error %O %S';

# --- Пути поиска файлов ----------------------------------
$ENV{'TEXINPUTS'} = '.;./Additions;' . ($ENV{'TEXINPUTS'} // '');

# --- Biber -----------------------------------------------
$biber = 'biber %O %B';

# --- upmendex --------------------------------------------
$makeindex = 'upmendex -o %D %S';

# --- Clean ---------------------------------------------
$clean_ext = 'aux bbl blg bcf idx ind ilg log lof lot out toc acn acr alg glg glo gls fls fdb_latexmk snm nav vrb xdv run.xml thm gnuplot table';

# --- Прочее ----------------------------------------------
$pdf_previewer = 'start %S';
