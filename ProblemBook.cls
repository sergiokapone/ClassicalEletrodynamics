\NeedsTeXFormat{LaTeX2e}[1994/06/01]
\ProvidesClass{ProblemBook}[2018/01/21]
\LoadClass[onecolumn, twoside, 14pt]{extbook}
%========================================================================================================
%
%										Налаштування опцій класу
%
%========================================================================================================
\newif\ifelectronic
\newif\ifbiblatex
\newif\ifmarginversioninfo

\DeclareOption{print}{
	\PassOptionsToPackage{colorlinks=false}{hyperref}
	\PassOptionsToPackage{pdfsubject={Version for Printing}}{hyperref}
	\electronicfalse
}

\DeclareOption{electronic}{\def\defcolor{\RequirePackage[usenames,dvipsnames,svgnames,table]{xcolor}\definecolor{malina}{rgb}{0.6,0.0,0.0}}
	\PassOptionsToPackage{linkcolor=malina}{hyperref}
	\PassOptionsToPackage{colorlinks=true}{hyperref}
	\PassOptionsToPackage{urlcolor=blue}{hyperref}
	\PassOptionsToPackage{citecolor=green!60!black}{hyperref}
	\PassOptionsToPackage{pdfsubject={Electronic Version}}{hyperref}
	\electronictrue
}

\DeclareOption{marginversioninfo}{%
	\marginversioninfotrue
}

\DeclareOption{biblatex}{
	\biblatextrue
}

\ExecuteOptions{electronic}
\ProcessOptions\relax
\defcolor{}

%========================================================================================================
%
%										Геометрія сторінки
%
%========================================================================================================
\newlength{\topspace}
\setlength{\topspace}{2cm}
\RequirePackage[%
	a4paper,%
	footskip=1cm,%
	headsep=1cm,%
	top=2cm, %поле сверху
	bottom=2cm, %поле снизу
	left=2cm, %поле ліворуч
	right=2cm, %поле праворуч
]{geometry}

%========================================================================================================
%
%										Налаштування мови та компіляторів
%
%========================================================================================================

\RequirePackage{ifluatex,ifxetex}
\newif\ifxetexorluatex
\ifxetex
	\xetexorluatextrue
\else
	\ifluatex
		\xetexorluatextrue
	\else
		\xetexorluatexfalse
	\fi
\fi
\ifxetexorluatex
	\RequirePackage{fontspec}
	\setsansfont{CMU Sans Serif}%{Arial}
	\setmainfont{stix}%{CMU Serif}%{Times New Roman}
	\setmonofont{CMU Typewriter Text}%{Consolas}
	\defaultfontfeatures{Ligatures={TeX}}
	\newfontfamily\Annabelle{Annabelle}
	\RequirePackage{luacolor}
	\usepackage{luatexbase} % TexLive2018 bug
\else
	\RequirePackage[T2A,T1]{fontenc}
	\RequirePackage[utf8]{inputenc}
	\input{glyphtounicode}
	\pdfgentounicode=1
	%\RequirePackage{pscyr}
	\RequirePackage{cmap}
	\renewcommand{\sfdefault}{fos}
	\renewcommand{\bfdefault}{b}
\fi
\RequirePackage[english,russian,ukrainian]{babel}


%========================================================================================================
%
%										Логічні змінні
%
%========================================================================================================

\newif\ifappendix
\newif\ifanswers
\newif\iftoc
\newif\ifbibliography
\newif\ifintro

%========================================================================================================
%
%										Налаштування типографських вимог
%
%========================================================================================================

\RequirePackage{microtype}
%\RequirePackage[nosingleletter, hyphenation, lastparline]{impnattypo}
%\usepackage[defaultlines=4,all]{nowidow}
%\clubpenalty =1000
%\widowpenalty=1000
%\setlength{\parskip}{0.5ex}%
\setlength{\parindent}{2.5em}%
%\renewcommand{\baselinestretch}{1.1}
\def\@textbottom{\vskip \z@ \@plus 1pt}
\let\@texttop\relax
%\setlength{\emergencystretch}{1em}

%========================================================================================================
%
%										Кольори
%
%========================================================================================================

\definecolor{malina}{RGB}{153,0.0,0.0}
%\definecolor{lighbluecolor}{RGB}{0,163,243}
%\definecolor{iptgreen}{RGB}{34,102,101}
%\definecolor{themecolordark}{RGB}{0,163,243}
%\definecolor{themecolorlight}{RGB}{191,233,251}
\definecolor{themecolordark}{RGB}{0,46,100}
\definecolor{themecolorlight}{RGB}{0,100,170}
% ------------- Кольори секцій ------------------------------
\definecolor{titlebgdark}{RGB}{0,103,102}
\definecolor{titlebglight}{RGB}{191,233,251}

%========================================================================================================
%
%										Пакети
%
%========================================================================================================

\RequirePackage[overload]{textcase}
\let\MakeUppercase\MakeTextUppercase
\RequirePackage{indentfirst}
% ------------------------------------ Плаваючі об'єкти -------------------------------------------------
\RequirePackage{subfig}
\renewcommand\thesubfigure{\alph{subfigure}}
\RequirePackage{wrapfig}
% ------------------------------------ Таблиці ----------------------------------------------------------
\usepackage{colortbl}
\usepackage{makecell}
\usepackage{longtable}
\usepackage{array,ragged2e}
\setlength\arrayrulewidth{1pt}
% ------------------------------------ Математика -------------------------------------------------------
\ifluatex
%	\RequirePackage{lualatex-math}
	\RequirePackage{amsmath}
	\RequirePackage[math-style=TeX,bold-style=TeX]{unicode-math}
	\setmathfont[math-style=TeX]{Stix Two Math}

\else
	\RequirePackage{amsfonts}
	\RequirePackage{amssymb}
\fi
\RequirePackage{esint}
\RequirePackage{nicefrac}
\let\nfrac\nicefrac
\allowdisplaybreaks
% -------------------------------- Визначення математичних команд -----------------------------------
\def\EMF{\mathcal{E}}
\newcommand{\vect}[1]{\symbf{#1}}
\def\Efield{\vect{E}}          % --- Визначення вектора електричного поля            ---
\def\Dfield{\vect{D}}          % --- Визначення електричної індукції                 ---
\def\Bfield{\vect{B}}          % --- Визначення вектора магнітногї індукції          ---
\def\Hfield{\vect{H}}          % --- Визначення вектора напруженості магнітного поля ---
\def\rot{\symbf{\nabla}\times} % --- Визначення ротора                               ---
\def\divg{\symbf{\nabla}\cdot} % --- Визначення дівергенції                          ---
\AtBeginDocument{%
    \let\pot\phi
    \let\phi\varphi
	\let\epsilon\varepsilon
	\DeclareMathOperator{\const}{const}
	\DeclareMathOperator{\inv}{inv}
	\newcommand{\Laplasian}{\Delta}
}

\RequirePackage{mhchem}
% ---------------------------------------- Таблиці ------------------------------------------------------
\RequirePackage{booktabs}
\RequirePackage{tabularx}
\newcolumntype{R}{>{\footnotesize}r}
\newcolumntype{L}{>{\footnotesize}l}
\RequirePackage{varwidth}
\newcolumntype{M}[1]{>{\begin{varwidth}[t]{#1}}l<{\end{varwidth}}}
\newcommand{\centercell}[1]{\multicolumn{1}{c}{#1}}
\newcommand{\specialcell}[3][c]{%
	\begin{tabular}[#1]{@{}#2@{}}#3\end{tabular}}
\RequirePackage{colortbl}
\setlength{\aboverulesep}{0pt}
\setlength{\belowrulesep}{0pt}
\setlength{\extrarowheight}{0.75ex}
\RequirePackage[justification=centering,labelsep=period]{caption}
\RequirePackage{multirow}
% ------------------------------------- Фалові операції -------------------------------------------------
\RequirePackage{currfile}
% ------------------------------------- Пакети LaTeX3 ---------------------------------------------------
\RequirePackage{xparse}
% -------------------------------------------------------------------------------------------------------
\RequirePackage{epigraph}
\setlength\epigraphwidth{0.7\textwidth}
\setlength\epigraphrule{0pt}
\renewcommand{\textflush}{flushepinormal}
\RequirePackage{refcount}
\RequirePackage[pagecontinue]{pageslts}
\pagenumbering{arabic}
\RequirePackage[disable]{todonotes}
\RequirePackage{pdftexcmds}
\RequirePackage[most, many]{tcolorbox}

%========================================================================================================
%
%										Рисування
%
%========================================================================================================

\RequirePackage{tikz, pgfplots, tikz-3dplot}
%---------------------------------------------------
%\usetikzlibrary{external}
%\usepgfplotslibrary{external}
%\tikzexternalize[optimize=false, prefix=figures/]
%---------------------------------------------------
\usetikzlibrary{decorations.text, decorations.markings}
\usetikzlibrary{intersections}
\usetikzlibrary{arrows.meta}
\usetikzlibrary{shapes, shadows}
\usetikzlibrary{quotes,angles}
\pgfdeclarelayer{bg}    % declare background layer
\pgfsetlayers{bg,main}  % set the order of the layers (main is the standard layer)
\usetikzlibrary{shapes.geometric,calc}
\usepgfplotslibrary{fillbetween}
\pgfplotsset{
	%every tick label/.append style={scale=0.5},
	every axis label/.append style={font=\small},
	compat=newest,
}
\tikzset{every picture/.style={font=\small}}
\tikzset{
	partial ellipse/.style args={#1:#2:#3}{
			insert path={+ (#1:#3) arc (#1:#2:#3)}
		}
}
% -------------------------------------- Електричні кола ------------------------------------------------
\usetikzlibrary{circuits.ee.IEC}
\tikzset{circuit ee IEC,
	every info/.style=red,
	semithick,
	every info/.style={font=\footnotesize},
	small circuit symbols,
	circuit declare symbol = ocontact,
	circuit declare symbol = multimeter,
	circuit declare symbol = ampermeter,
	circuit declare symbol = voltmeter,
	circuit declare symbol = galvanometer,
	circuit declare symbol = ac source,
	set ocontact graphic = {draw, fill = white, generic circle IEC, shape=circle, minimum size=1mm},
	set multimeter graphic = {draw,generic circle IEC, minimum size=5mm},
	set ampermeter graphic = {draw,generic circle IEC, minimum size=5mm,info=center:A},%
	set voltmeter graphic = {draw,generic circle IEC, minimum size=5mm,info=center:V},
	set galvanometer graphic = {draw,generic circle IEC, minimum size=5mm,info=center:G},
	set ac source graphic = ac source IEC graphic,
	ac source IEC graphic/.style=
		{
			transform shape,
			circuit symbol lines,
			circuit symbol size = width 3 height 3,
			shape=generic circle IEC,
			/pgf/generic circle IEC/before background=
				{
					\pgfpathmoveto{\pgfpoint{-0.575pt}{0pt}}
					\pgfpathsine{\pgfpoint{0.3pt}{0.3pt}}
					\pgfpathcosine{\pgfpoint{0.3pt}{-0.3pt}}
					\pgfpathsine{\pgfpoint{0.3pt}{-0.3pt}}
					\pgfpathcosine{\pgfpoint{0.3pt}{0.3pt}}
					\pgfusepathqstroke
				}
		}
}

% -------------------------------------- Паттерни -------------------------------------------------------
\usetikzlibrary{patterns}
\tikzstyle{ground}=[fill,pattern=north east lines,draw=none,minimum width=0.3,minimum height=0.6]


%========================================================================================================
%
%									      Налаштування для титульних сторінок
%
%========================================================================================================

\newenvironment{alwayssingle}{%
	\thispagestyle{empty}
	\@restonecolfalse
	\if@twocolumn\@restonecoltrue\onecolumn
	\else\if@openright\cleardoublepage\else\clearpage\fi
	\fi}%
{\if@restonecol\twocolumn
	\else\newpage\thispagestyle{empty}\fi
}

\tcbset{%
		titlepagestyle/.style={%
				enhanced,
				colback=themecolordark,
				colframe=themecolorlight,
				arc=0pt,
				outer arc=0pt,
				leftrule=0pt,
				rightrule=0pt,
				enlarge left by=-1in-\hoffset-\oddsidemargin,
				enlarge right by=-\paperwidth+1in+\hoffset+\oddsidemargin+\textwidth,
				width=\paperwidth,
				left=1in+\hoffset+\oddsidemargin,
				right=\paperwidth-1in-\hoffset-\oddsidemargin-\textwidth,
		}%
}%

\ExplSyntaxOn
\RenewDocumentCommand{\title}{m}
 {
  \tl_gset:cn { @title } { #1 } % needed by \maketitle
  \tl_gset:Nn { \realtitle } { #1 }
%  \seq_set_split:Nnn \l_tmpa_seq { \\ } { #1 }
%  \tl_gset:Nx \inlinetitle { \seq_use:Nn \l_tmpa_seq { ~ } }
 }
\ExplSyntaxOff


%========================================================================================================
%
%										   Рубрикація
%
%========================================================================================================

\let\cleardoublepage\clearpage

\def\schapter#1{%
\chapter*{#1}
\addcontentsline{toc}{chapter}{#1}%
}


% ---------------------------------------- Верстка ДОДАТКІВ ---------------------------------------------

\renewcommand\appendix{\par
	\appendixtrue
	\gdef\thesection{\@Alph\c@section}
	\@addtoreset{table}{section}
	\renewcommand\thetable%
	{\thesection.\@arabic\c@table}
	\setcounter{chapter}{0}%
	\setcounter{section}{0}%
	\renewcommand{\theequation}{\thesection.\arabic{equation}}
	\clearpage\pagestyle{appendix}
	\def\@sectiontitlemark{\appendixname}
	\if@twocolumn
		\@restonecoltrue\onecolumn
	\else
		\@restonecolfalse
	\fi
	\chapter*{Додатки}%
    \addcontentsline{toc}{chapter}{Додатки}
	\if@restonecol\twocolumn\fi
}
% ---------------------------------------- Верстка ВІДПОВІДЕЙ -------------------------------------------
\newcommand\answers{\par
	\answerstrue
	\setcounter{chapter}{0}%
	\setcounter{section}{0}%
	\renewcommand{\thesection}{\arabic{section}}
    \clearpage\pagestyle{answers}
	\chapter*{Відповіді}%
    \addcontentsline{toc}{chapter}{Відповіді}
    \renewcommand{\theequation}{\arabic{equation}}
	\if@restonecol\twocolumn\fi
}
% ---------------------------------------- Лічильник зносок починаються з кожної сторінки ---------------
\@newctr{footnote}[page]



\RequirePackage[pagestyles, explicit]{titlesec}
\RequirePackage{titletoc}

\newlength\chapnumb
\setlength\chapnumb{4cm}

\titleformat{\part}[display]{\bfseries\sffamily\huge}{\partname\ \thepart }{0pt}{\addvspace{1em}\Huge\centering #1}

\titlecontents{part}%
[0pt]{\sffamily\bfseries\large\protect\addvspace{25pt}\addvspace{1.5ex}}
{}{\partname~}
{\hfill\contentspage}%
[\addvspace{0.7ex}\titlerule\addvspace{10pt}]%

\titleclass{\part}{top}
\newcommand\partbreak{\clearpage}

\titleformat{\chapter}[block]
{\normalfont\sffamily}{}{0pt}
{\parbox[b]{\chapnumb}{%
   \color{themecolordark}\fontsize{100}{90}\selectfont\thechapter}%
  \parbox[b]{\dimexpr\textwidth-\chapnumb\relax}{%
    \raggedleft%
    \hfill{\LARGE#1}\\
    \rule{\dimexpr\textwidth-\chapnumb\relax}{0.4pt}}}

\titleformat{name=\chapter,numberless}[block]
{\normalfont\sffamily}{}{0pt}
{\parbox[b]{\chapnumb}{%
   \mbox{}}%
  \parbox[b]{\dimexpr\textwidth-\chapnumb\relax}{%
    \raggedleft%
    \hfill{\LARGE#1}\\
    \rule{\dimexpr\textwidth-\chapnumb\relax}{0.4pt}}}

\titleformat{\section}
{\normalsize\bfseries}{\thesection.}{1em}{#1}

\titleformat{\subsection}
{\normalsize\bfseries\itshape}{\thesubsection.}{1em}{#1}



\newpagestyle{main}{\headrule%
  \sethead{\ifodd\thepage\relax\else\itshape\small\thechapter.\ \chaptertitle\fi}{}{\ifodd\thepage\itshape\small\thechapter.\ \chaptertitle\else\relax\fi}
  \setfoot{}{\small\thepage}{}}

\newpagestyle{answers}{\headrule%
  \sethead{\ifodd\thepage\relax\else\itshape\small Відповіді\fi}{}{\ifodd\thepage\itshape\small Відповіді\else\relax\fi}
  \setfoot{}{\small\thepage}{}}

\newpagestyle{appendix}{\headrule%
  \sethead{\ifodd\thepage\relax\else\itshape\small Додатки\fi}{}{\ifodd\thepage\itshape\small Додатки\else\relax\fi}
  \setfoot{}{\small\thepage}{}}

\newpagestyle{bibliography}{\headrule%
  \sethead{\ifodd\thepage\relax\else\itshape\small\bibname\fi}{}{\ifodd\thepage\itshape\small\bibname\else\relax\fi}
  \setfoot{}{\small\thepage}{}}

\renewpagestyle{plain}{%
  \sethead{}{}{}
  \setfoot{}{\small\thepage}{}}

\assignpagestyle{\chapter}{plain}
\assignpagestyle{\part}{empty}

%========================================================================================================
%
%										Підписи під таблицями, рисунками та списки
%
%========================================================================================================

\def\tabcaption{\def\@captype{table}\caption}
\def\figcaption{\def\@captype{figure}\caption}
\RequirePackage[inline]{enumitem}
\setlist{nolistsep}


% ------------------------------------------------ Відступи в формулах ----------------------------------

\setlength\abovedisplayskip{1ex}
\setlength\belowdisplayskip{1ex}
\setlength\abovedisplayshortskip{1ex}
\setlength\belowdisplayshortskip{1ex}

% ----------------------------------------- Відступ між написом та рисунком -----------------------------

\setlength{\textfloatsep}{5pt}

% ---------------------------------------- Підписи до рисунку (розмір тексту) ---------------------------

\captionsetup[figure]{font=small,labelfont=small}
\captionsetup[table]{font=small,labelfont=small}

% --------------------------------------------- Bibliography spacing ------------------------------------
\newlength{\bibitemsep}\setlength{\bibitemsep}{.1\baselineskip plus .05\baselineskip minus .05\baselineskip}
\newlength{\bibparskip}\setlength{\bibparskip}{0pt}
\let\oldthebibliography\thebibliography
\renewcommand\thebibliography[1]{%
	\oldthebibliography{#1}%
	\setlength{\parskip}{\bibitemsep}%
	\setlength{\itemsep}{\bibparskip}%
}

%========================================================================================================
%
%										            HYPERREF
%
%========================================================================================================


\RequirePackage[%
	bookmarks = true,
	bookmarksnumbered=true,
	unicode,
	linktocpage = true,
	hypertexnames=false,
	pdftoolbar=false,
	pdfpagelayout=TwoPageLeft,
	pdfauthor={Ponomarenko S.M.},
	pdfdisplaydoctitle=true,
	pdfkeywords={Electrostatics, Magnetostatics, Electrodynamics, Current, Field},
	pdfencoding=auto
]%
{hyperref}
\RequirePackage[all]{hypcap}
\RequirePackage{bookmark}

% ------------------------------------ Патч для україомовної назви розділу для nameref ------------------ %
\addto\extrasukrainian{%
	\renewcommand{\chapterautorefname}{}%
}
% ------------------------------------------------------------------------------------------------------- %

\ifdefined\inlinetitle%
\AtBeginDocument{\hypersetup{pdftitle={\inlinetitle}}}
\fi

%========================================================================================================
%
%										Налаштування бібліографії
%
%========================================================================================================

\ifbiblatex
  \RequirePackage[backend=biber,
bibstyle=gost-numeric,
maxnames = 10,
 babel=other,
isbn=true,
url=false,
defernumbers=true
]{biblatex}
  \newbibmacro{string+url}[1]{%
  	\iffieldundef{url}{#1}{\href{\thefield{url}}{#1}}%
  }
  \DeclareFieldFormat{title}{\usebibmacro{string+url}{#1}}
  \RequirePackage{csquotes}

  \DefineBibliographyStrings{ukrainian}{%
  	bibliography = {Література},
  }
  \DeclareBibliographyCategory{Textbooks}
  \DeclareBibliographyCategory{Problems}
\else
    \renewcommand{\@biblabel}[1]{#1.}
    \addto\captionsukrainian{%
    \renewcommand{\bibname}{Література}%
    }
\fi

%========================================================================================================
%
%										Верстка теоретичних відомостей
%
%========================================================================================================

\newtcolorbox[auto counter]{Theory}[1][]{
  breakable,
  enhanced,
  outer arc=0pt,
  arc=0pt,
  colframe=themecolordark,
  colback=themecolordark!20,
  attach boxed title to top left,
	fontupper=\small,
	before upper={\parindent15pt},
  boxed title style={
    colback=themecolordark,
    outer arc=0pt,
    arc=0pt,
    top=3pt,
    bottom=3pt,
    },
  fonttitle=\sffamily,
  colback=white,
  rightrule=0pt,
%  toprule=0pt,
	before=\nopagebreak,
  title=Теоретичні відомості,
  overlay unbroken and first={
      \path
        let
        \p1=(title.north east),
        \p2=(frame.north east)
        in
        node[anchor=west,font=\sffamily,color=themecolordark,text width=\x2-\x1]
        at (title.east) {#1};
  }
}

\newtcolorbox{Attention}[1][]{enhanced,
  breakable,
  before skip=2mm,after skip=3mm,
  before upper={\parindent15pt},
  boxrule=0.4pt,left=5mm,right=2mm,top=1mm,bottom=1mm,
  colback=red!10,
  colframe=red!50,
  sharp corners,rounded corners=southeast,arc is angular,arc=3mm,
  underlay={%
    \path[fill=tcbcolback!80!black] ([yshift=3mm]interior.south east)--++(-0.4,-0.1)--++(0.1,-0.2);
    \path[draw=tcbcolframe,shorten <=-0.05mm,shorten >=-0.05mm] ([yshift=3mm]interior.south east)--++(-0.4,-0.1)--++(0.1,-0.2);
    \path[fill=themecolordark,draw=none] (interior.south west) rectangle node[text=white]{\Huge\bfseries !} ([xshift=4mm]interior.north west);
    },
  drop fuzzy shadow,#1}


%========================================================================================================
%
%										Верстка задач
%
%========================================================================================================
%\usepackage[framemethod=tikz]{mdframed}
\RequirePackage{ntheorem}
\RequirePackage{answers}
\RequirePackage{xassoccnt}
\NewTotalDocumentCounter{totalproblems}

\newtheoremstyle{problemstyle}%
{%
	\hypertarget{problem:\@roman{##2}}{}%
	\ifcsname r@solution\@roman{##2}\endcsname
		\item[\theorem@headerfont\hyperlink{solution:\@roman{##2}}{##2\theorem@separator}]
	\else
		\item[\theorem@headerfont##2\theorem@separator]
	\fi
}%
{%
	\hypertarget{problem:\@roman{##2}}{}%
	\ifcsname r@solution\@roman{##2}\endcsname
		\item[\theorem@headerfont\hyperlink{solution:\@roman{##2}}{##2\theorem@separator}] ({\itshape##3})
	\else
		\item[\theorem@headerfont##2\theorem@separator] ({\itshape##3})
	\fi
}

\theoremstyle{problemstyle}
\theoremheaderfont{\hspace{1ex}\bfseries}
\theorembodyfont{\normalfont}
\theoremseparator{.}

\newtheorem{problem}{}[chapter]
\DeclareAssociatedCounters{problem}{totalproblems}

\tcbset{
		answersolutionstyle/.style={
			enhanced jigsaw,colframe=cyan,interior hidden, boxrule=0pt, frame hidden,
				breakable,before skip=10pt,after skip=10pt, parbox=false, ,before upper={\parindent20pt},
				overlay unbroken = {\draw[line width=1pt, themecolorlight, rounded corners] (frame.south west) rectangle (frame.north east);},
				extras first={
		        overlay={%
			            \draw[line width=1pt, themecolorlight, rounded corners] (frame.south west) -- (frame.north west) -- (frame.north east) --(frame.south east);
						},
				},
				extras middle={
		        overlay={%
			            \draw[line width=1pt, themecolorlight, rounded corners] (frame.north west) -- (frame.south west)  (frame.south east) --(frame.north east);
						},
                },
				extras last={
		        overlay={%
			            \draw[line width=1pt, themecolorlight, rounded corners] (frame.north west) -- (frame.south west) -- (frame.south east) --(frame.north east);
						},
				},
			},
}

\tcolorboxenvironment{problem}{answersolutionstyle}


%========================================================================================================
%
%										Генеррування відповідей до задач
%
%========================================================================================================

\newtcolorbox{answerbox}{answersolutionstyle,halign=left}

\Newassociation{solution}{Solution}{answer}
\renewenvironment{Solution}[1]{%
	\begin{answerbox}\setcounter{equation}{0}
\hypertarget{solution:\@roman{#1}}{\hyperlink{problem:\@roman{#1}}{\bfseries#1.}\label{solution\@roman{#1}}}
}{%
	\end{answerbox}
}


%========================================================================================================
%
%									Команда вставки задач та відповідей
%
%       https://tex.stackexchange.com/questions/382776/how-to-create-list-and-assign-it-to-variable
%========================================================================================================
\ExplSyntaxOn
% ---------------------------------------- Another good solution ----------------------------------------
%\NewDocumentCommand{\multiinclude}{ m O{} }
% {
%  \clist_map_inline:cn {chapter_list_#1_clist} { \InputIfFileExists{##1/##1#2}{}{}\par}
% }

%\NewDocumentCommand{\MakeChapterList}{ m m }
% {
%  \clist_set:cn {chapter_list_#1_clist} { #2 }
% }
% -------------------------------------------------------------------------------------------------------
\NewDocumentCommand{\multiinclude}{ m O{} }
{
	\clist_set:Nx \l_Chapters_clist{ #1 }
	\clist_map_inline:Nn \l_Chapters_clist { \InputIfFileExists{##1/##1#2}{}{}\par}
}

%\NewDocumentCommand{\Size}{m}{\int_div_round:nn {\file_size:n{#1}+482454}{1024}}
\ExplSyntaxOff
%========================================================================================================

%========================================================================================================
%
%                                         Друк версії документу на полях
%
%========================================================================================================
\ifmarginversioninfo
	% http://tex.stackexchange.com/questions/54808/rotated-running-text-in-right-margin
	\RequirePackage[contents={},opacity=0.5,scale=1.5,color=gray]{background}
	\newcommand\Texta{\bf\footnotesize Версія від \today\ (число задач \TotalValue{totalproblems})} % odd page
	\newcommand\Textb{\bf\footnotesize Версія від \today\ (число задач \TotalValue{totalproblems})} % even pages
	%-----------------------------------------
	\AddEverypageHook{%
		\ifodd\value{page}
			\backgroundsetup{
				angle=90,
				position={-0.06\textwidth,-0.35\textheight},
				contents={\Texta}
			}%
		\else
			%-----------------------------------------
			\backgroundsetup{
				angle=90,
				position={0.68\textwidth,-0.35\textheight},
				contents={\Textb}
			}%
		\fi
		\BgMaterial}
\fi

\RequirePackage{grabbox}


\newlength\wrapcont@width
\newlength\wrapcont@sep
\newlength\wrapcont@indent
\newlength\wrapcont@hsize
\newcount\wrapcont@lines
\newcount\wrapcont@tempcount
\setlength\wrapcont@sep{5pt}
\newsavebox\wrapcont@box
\newcommand*\wrapcontents[2][]
  {%
    % #1 : width
    % #2 : l/r
    \@ifnextchar[{\wrapcont@a{#1}{#2}}{\wrapcont@a{#1}{#2}[+0]}%
  }
\def\wrapcont@a#1#2[#3]%
  {%
    % #1 : width
    % #2 : l/r
    % #3 : correction
    \if\relax\detokenize{#1}\relax
      \wrapcont@hbox
    \fi
    \wrapcont@vbox{#1}{#2}{#3}%
  }
\def\wrapcont@hbox\fi\wrapcont@vbox#1#2#3%
  {%
    % #1 : width
    % #2 : l/r
    % #3 : correction
    \fi
    \@grabbox{}\wrapcont@box{}\hbox{}{\wrapcont@b{#2}{#3}}%
  }
\newcommand*\wrapcont@vbox[3]
  {%
    % #1 : width
    % #2 : l/r
    % #3 : correction
    \@grabbox{\hsize=#1\relax\linewidth\hsize}\wrapcont@box{}\vbox{}%
      {\wrapcont@b{#2}{#3}}%
  }
\newcommand*\wrapcont@b[2]
  {%
    % #1 : l/r
    % #2 : correction
    \@ifnextchar[{\wrapcont@c{#1}{#2}}{\wrapcont@c{#1}{#2}[0]}%
  }
\newcommand*\wrapcont@parshape{}
\def\wrapcont@c#1#2[#3]%
  {%
    % #1 : l/r
    % #2 : correction
    % #3 : lines skipped
    \wrapcont@width\wd\wrapcont@box\relax
    \advance\wrapcont@width\wrapcont@sep
    \wrapcont@hsize\linewidth
    \advance\wrapcont@hsize-\wrapcont@width
    \ifnum0<0#2\relax
      \wrapcont@lines#2\relax
    \else
      \wrapcont@lines
        \numexpr
          (\ht\wrapcont@box+\dp\wrapcont@box\ifnum#3>0 +\wrapcont@sep\fi+\wrapcont@sep)%
          /\baselineskip#2%
        \relax
    \fi
    \vbox to 0pt
      {%
        \vskip#3\baselineskip
        \ifnum#3>0
          \vskip\wrapcont@sep
        \fi
        \def\@tempa{#1}%
        \def\@tempb{r}%
        \ifx\@tempa\@tempb
          \vtop{\noindent\hbox to\hsize{\hss\usebox\wrapcont@box}}%
        \else
          \def\@tempb{l}%
          \ifx\@tempa\@tempb
          \else
            \GenericError
              {}
              {wrapcontent Error: Unknown alignment '#1', using 'l' as backup.}
              {}{}%
          \fi
          \vtop{\noindent\usebox\wrapcont@box}%
        \fi
        \vss
      }%
    \begingroup
      \def\@tempa{#1}%
      \def\@tempb{r}%
      \ifx\@tempa\@tempb
        \aftergroup\wrapcont@indent\aftergroup\z@
      \else
        \aftergroup\wrapcont@indent\aftergroup\wrapcont@width
      \fi
    \endgroup
    \vglue-\parskip
    \vskip-\baselineskip
    \wrapcont@tempcount0
    \edef\wrapcont@parshape{=\the\numexpr#3+\wrapcont@lines+1\relax\space}%
    \loop\ifnum#3>\wrapcont@tempcount
      \advance\wrapcont@tempcount\@ne
      \edef\wrapcont@parshape
        {\unexpanded\expandafter{\wrapcont@parshape}0pt \the\hsize\space}%
    \repeat
    \wrapcont@tempcount0
    \loop\ifnum\wrapcont@lines>\wrapcont@tempcount
      \advance\wrapcont@tempcount\@ne
      \edef\wrapcont@parshape
        {%
          \unexpanded\expandafter{\wrapcont@parshape}%
          \the\wrapcont@indent\space\the\wrapcont@hsize\space
        }%
    \repeat
    \edef\wrapcont@parshape
      {\unexpanded\expandafter{\wrapcont@parshape}0pt \the\hsize\space}
    \expandafter\parshape\wrapcont@parshape\relax
  }
\newcommand*\restorewrap[1][0]
  {%
    \ifnum0=#1\relax
      \parshape=0
    \else
      \wrapcont@tempcount0
      \edef\wrapcont@parshape{=\the\numexpr#1+1\relax\space}%
      \loop\ifnum#1>\wrapcont@tempcount
        \advance\wrapcont@tempcount\@ne
        \edef\wrapcont@parshape
          {%
            \unexpanded\expandafter{\wrapcont@parshape}%
            \the\wrapcont@indent\space\the\wrapcont@hsize\space
          }%
      \repeat
      \edef\wrapcont@parshape
        {\unexpanded\expandafter{\wrapcont@parshape}0pt \the\hsize\space}%
      \expandafter\parshape\wrapcont@parshape
    \fi
    \relax
  }


\endinput