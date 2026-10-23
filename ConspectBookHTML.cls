% ==============================================================================
%  ConspectBookHTML.cls -- HTML (lwarp) variant of ConspectBook.cls.
%  Print class is NOT touched. Chapters stay identical. Only what HTML needs:
%  lwarp first, then math macros / colours / tikz styles reused verbatim,
%  and simple HTML-friendly definitions of the book's boxes and problems.
% ==============================================================================
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{ConspectBookHTML}[2026/10/15 lwarp variant of ConspectBook]
\LoadClass[onecolumn,twoside]{book}
\RequirePackage{iftex}
\RequirePackage{etoolbox}
% ---- lwarp must be loaded before other packages --------------------------------
\RequirePackage[HTMLFilename={ch},mathjax]{lwarp}
\boolfalse{FileSectionNames}
\setcounter{FileDepth}{0}        % one HTML page per chapter
\setcounter{tocdepth}{1}
\setcounter{secnumdepth}{2}
\HTMLLanguage{uk}
\CSSFilename{conspect.css}   % boxes styles; conspect.css lies next to the project

% ---- language and fonts (fonts matter only for images made by lateximage) ------
\RequirePackage{fontspec}
\IfFontExistsTF{BookmanOldStyle}{\setmainfont{BookmanOldStyle}}{\setmainfont{FreeSerif}}
\IfFontExistsTF{Roboto}{\setsansfont{Roboto}}{\setsansfont{FreeSans}}
% lwarp types the HTML tags in the monospace font. The programming ligatures (calt) of JetBrains Mono make
% --> </ /> // single glyphs, and pdftotext then writes a stray ^ before them: switch them off.
\IfFontExistsTF{JetBrains Mono}{\setmonofont{JetBrains Mono}[RawFeature={-calt,-liga}]}{\setmonofont{FreeMono}}
\defaultfontfeatures{Ligatures={TeX}}
\RequirePackage[english,russian,ukrainian]{babel}

%===============================================================================
%
%                                    INDEX
%
%===============================================================================
% the print class builds an index (indextools); the HTML version has none (\index exists in the LaTeX kernel and is ignored)
\providecommand{\printindex}[1][]{}

\RequirePackage[unicode]{hyperref}   % lwarp patches it
% ---- ссылки на части: \partref{part:I} -> "Частина I: <назва>" ----
\NewDocumentCommand{\partref}{m}{\partname~\ref{#1}:~\nameref{#1}}
\RequirePackage{csquotes}            % \enquote
\RequirePackage[dvipsnames,svgnames,table]{xcolor}
\definecolor{malina}{rgb}{0.6,0.0,0.0}
\newcommand{\Alexander}{\itshape}    % decorative font is print-only


%===============================================================================
%
%										Кольори
%
%===============================================================================
% Загальна палітра книги: акцентні кольори тексту/боксів (themecolor*),
% кольори секцій титульних сторінок (titlebg*) та кольори для фізичних рисунків
% (efield/dfield/jfield — використовуються у tikz-ілюстраціях полів).
\definecolor{malina}{RGB}{153,0.0,0.0}
%\definecolor{lighbluecolor}{RGB}{0,163,243}
%\definecolor{iptgreen}{RGB}{34,102,101}
%\definecolor{themecolordark}{RGB}{0,163,243}
%\definecolor{themecolorlight}{RGB}{191,233,251}
\definecolor{themecolormain}{RGB}{51,51,178}
\definecolor{themecolordark}{RGB}{0,46,100}
\definecolor{themecolorlight}{RGB}{0,100,170}
\definecolor{paper}{RGB}{239,227,157}
\colorlet{glasscol}{cyan!40}
\definecolor{rowfill}{RGB}{219, 229, 241}
\definecolor{infotablecolor}{RGB}{149,179,215}
% ------------- Кольори секцій ------------------------------
\definecolor{titlebgdark}{RGB}{0,103,102}
\definecolor{titlebglight}{RGB}{191,233,251}
% ------------- Кольори рисунків ----------------------------
\definecolor{efield}{rgb}{1, 0, 0}   % колір вектора E на рисунках
\definecolor{dfield}{rgb}{0, 0, 1}   % колір вектора D на рисунках
\definecolor{jfield}{named}{teal}    % колір густини струму j на рисунках
% Цвет для тетрадных клеточек (бледно-голубой)
\definecolor{gridcolor}{rgb}{0.8, 0.88, 0.95}

%===============================================================================
%  Math: same definitions as the print class (used by LaTeX / lateximage);
%  MathJax gets its own copy through lwarp-mathjax.tex (see \input at the end).
%===============================================================================
\RequirePackage[math-style=TeX,bold-style=TeX]{unicode-math}
\IfFontExistsTF{Stix Two Math}{\setmathfont{Stix Two Math}}{\setmathfont{Latin Modern Math}}
\RequirePackage{amsmath}
\RequirePackage{esint}
\RequirePackage{nicefrac}\let\nfrac\nicefrac
\RequirePackage{emf}
\newcommand{\vect}[1]{\symbf{#1}}
\def\Efield{\vect{E}}\def\Dfield{\vect{D}}\def\Bfield{\vect{B}}\def\Hfield{\vect{H}}
\def\rot{\symbf{\nabla}\times}\def\divg{\symbf{\nabla}\cdot}\def\grad{\vect{\nabla}}
\def\diff#1#2{\frac{\partial #1}{\partial #2}}
\def\ddiff#1#2{\frac{\partial^2 #1}{\partial #2^2}}
\def\parttime#1{\frac{\partial{#1}}{\partial t}}
\def\pparttime#1{\frac{\partial^2{#1}}{\partial t^2}}
\def\Dalambertian{\mdlgwhtsquare\,}
\AtBeginDocument{%
  \let\phi\varphi \let\epsilon\varepsilon
  \DeclareMathOperator{\const}{const}\DeclareMathOperator{\Div}{div}
  \DeclareMathOperator{\Rot}{rot}\DeclareMathOperator{\Grad}{grad}\DeclareMathOperator{\inv}{inv}
  \newcommand{\Laplasian}{\Delta}
\newcommand{\D}{\varDelta}
  \let\iiint\int \let\iint\int \let\oiint\oint}
\newcommand{\tcbhighmath}[1]{\boxed{#1}}   % boxed formula (print uses tcolorbox)
\NewDocumentCommand{\emphx}{m}{\emph{\textcolor{malina}{#1}}}
\RequirePackage[version=4]{mhchem}
\RequirePackage{tabularray}\UseTblrLibrary{booktabs}
% tabularray is not supported by lwarp -> every tblr becomes an image (like tikzpicture does)
\AtBeginDocument{\preto\tblr{\begin{lateximage}[table]}\appto\endtblr{\end{lateximage}}}
\RequirePackage{booktabs,multirow,array,tabularx,colortbl}   % tabularx: HTML replacement of tblr (prepare_html.py)
\RequirePackage[justification=centering,labelsep=period]{caption}
\RequirePackage[outercaption,wide]{sidecap}
\RequirePackage{subcaption}
\RequirePackage[inline]{enumitem}\setlist{nosep}
\RequirePackage{epigraph}
\setlength\epigraphrule{0pt}
\def\tabcaption{\def\@captype{table}\caption}
\def\figcaption{\def\@captype{figure}\caption}
\RequirePackage{currfile}
% prepare_html.py puts fixed copies of some tikz files into _html/ (see there)
\newcommand{\localinput}[1]{\IfFileExists{_html/\currfilebase/tikz/#1}{\input{_html/\currfilebase/tikz/#1}}{\input{\currfilebase/tikz/#1}}}
\def\schapter#1{\chapter*{#1}\addcontentsline{toc}{chapter}{#1}}
% lwarp opens a new HTML page for a starred \chapter* only after \ForceHTMLPage (otherwise the text goes
% to the end of the previous chapter's page): \schapterpage = \schapter on a page of its own
\newcommand{\schapterpage}[1]{\ForceHTMLPage\schapter{#1}}
% ---- appendices: sections А, Б, ... on one page "Додатки" (print: \appendix in ConspectBook.cls) ----
\let\ConspectOrigAppendix\appendix
\renewcommand\appendix{%
  \ConspectOrigAppendix
  \setcounter{section}{0}%
  \gdef\thesection{\@Alph\c@section}%
  \@addtoreset{table}{section}\@addtoreset{equation}{section}%
  \renewcommand\thetable{\thesection.\@arabic\c@table}%
  \renewcommand\theequation{\thesection.\arabic{equation}}%
  \schapterpage{Додатки}}
\ExplSyntaxOn
\NewDocumentCommand{\multiinclude}{ m O{} }
 {\clist_set:Nx \l_Chapters_clist{ #1 }
  \clist_map_inline:Nn \l_Chapters_clist { \IfFileExists{_html/##1/##1#2.tex}{\input{_html/##1/##1#2.tex}}{\InputIfFileExists{##1/##1#2}{}{}}\par}}
\ExplSyntaxOff

\RequirePackage[outline]{contour}
\contourlength{1.1pt}


%===============================================================================
%
%							Рисування: TikZ, PGFPlots, CircuiTikz
%
%===============================================================================
% Увесь графічний інструментарій книги зібрано в одному розділі: базові пакети,
% усі \usetikzlibrary одним викликом, шари малювання, а далі — власні tikz/pic-стилі,
% від найпростіших (contact, magarrow) до складних параметричних (parallelepiped).
\RequirePackage{tikz, pgfplots, tikz-3dplot}
\RequirePackage{circuitikz}    % електричні кола (резистори, батареї тощо) для схем
\usetikzlibrary{babel}
\RequirePackage{fontawesome5}
%---------------------------------------------------
%\usetikzlibrary{external}
%\usepgfplotslibrary{external}
%\tikzexternalize[optimize=false, prefix=figures/]
%---------------------------------------------------
% Примітка: свідомо НЕ підключається \usetikzlibrary{circuits.ee.IEC} — ця бібліотека
% конфліктує з елементами circuitikz (перевизначає ключі кола, напр. "R"), тому
% розділ "Електричні кола" нижче лишається закоментованим.
\usetikzlibrary{%
	decorations.text, decorations.markings, decorations.pathmorphing, % текст/розмітка/фрактальні лінії на шляхах
	intersections, backgrounds,                                       % точки перетину ліній; фонові шари
	arrows, arrows.meta,                                              % стрілки (класичні та сучасні)
	shapes, shapes.geometric, shadows, shadows.blur, shadings,        % фігури-вузли, тіні, градієнти
	quotes, angles, tikzmark,                                         % підписи кутів, позначки для \tikzmark
	calc, fit, positioning,                                           % обчислення координат, обгортання, взаємне розміщення вузлів
	patterns,                                                         % штрихування (використовується у стилі "ground")
	spy,                                                               % лупа/збільшений фрагмент рисунка
}
% Обидва фонові шари класу (bg тут і background — для декору tornpage нижче)
% оголошуються і активуються ОДНИМ спільним \pgfsetlayers. Раніше вони
% реєструвались двома окремими викликами \pgfsetlayers у різних місцях файлу;
% другий виклик мовчки перезаписував список шарів і робив 'bg' невідомим —
% будь-яке \begin{pgfonlayer}{bg} в документі падало з помилкою
% "the requested layer 'bg' is not part of the layer list".
\pgfdeclarelayer{bg}          % фоновий шар для звичайних tikz-рисунків
\pgfdeclarelayer{background}  % фоновий шар під "пергаментну" текстуру tornpage (див. розділ "Оформлення блоків")
\pgfdeclarelayer{pre main}
\pgfsetlayers{bg, background, main}  % порядок малювання: bg -> background -> main (стандартний)
\usepgfplotslibrary{fillbetween}   % заливка області між двома кривими pgfplots/tikz
\pgfplotsset{
	%every tick label/.append style={scale=0.5},
	every axis label/.append style={font=\small},
	compat=newest,
}
\tikzset{every picture/.style={font=\small}}   % єдиний розмір шрифту в усіх tikzpicture

% ------------------------------- Загальні стилі --------------------------------
% partial ellipse={кут1:кут2:радіус} — дуга/сектор еліпса чи кола від кута1 до кута2
\tikzset{
	partial ellipse/.style args={#1:#2:#3}{
			insert path={+ (#1:#3) arc (#1:#2:#3)}
		}
}

% contact — маленька закрашена точка-контакт (кінець провідника, вузол схеми тощо)
\tikzset{contact/.style={circle, fill, inner sep=1.2pt}}

% magarrow — pic-стиль "магнітної стрілки": синій північний і червоний південний
% полюси-трикутники з іменованими координатами (top/north/south/bottom) для прив'язки
\tikzset{
	magarrow/.pic = {
			\fill [blue] (0:1) -- (90:0.2)  -- (270:0.2) -- cycle;
			\fill [red] (-180:1) -- (-270:0.2) -- (-90:0.2) -- cycle;
			\coordinate (-top)     at (90:0.2);
			\coordinate (-north)   at (0:1);
			\coordinate (-south)   at (-180:1);
			\coordinate (-bottom)  at (-270:0.2);
		}
}

% ---------------------------- Паттерни ----------------------------------------
% ground — умовне позначення "землі" на схемах (штрихована ділянка)
\tikzstyle{ground}=[fill,pattern=north east lines,draw=none,minimum width=0.3,minimum height=0.6]

% ------------------------------- Стрілки на лініях -----------------------------
% midarrow/midarrowR — стрілка-маркер посередині лінії (вправо/вліво відповідно) —
% зручно показувати напрямок струму чи руху вздовж контуру
\tikzstyle{midarrow} = [
postaction={ decorate,
		decoration={ markings, mark=at position .5 with {\arrow{>}}}}
]

\tikzstyle{midarrowR} = [
postaction={ decorate,
		decoration={ markings, mark=at position .5 with {\arrow{<}}}}
]

% arrowpos={позиція}{зсув}{довжина} — стрілка в довільній точці шляху з керованим
% зсувом та довжиною наконечника (гнучкіший за midarrow)
\tikzset{
    arrowpos/.code n args={3}{
        \tikzset{
            decoration={markings, mark=at position #1 with {\arrow[xshift=#2]{Latex[length=#3]}}},
            postaction={decorate}
        }
    }
}

% ------------------------------- Допоміжні pic-стилі ---------------------------
% vertical ticks — ряд коротких вертикальних рисочок уздовж шляху (напр. шкала на осі)
% area/.pic — приклад заштрихованої довільної області між двома парами кривих
% (побудованої через fillbetween за іменованими шляхами name path=A/B/C/D)
\tikzset{
	vertical ticks/.style={
			decoration={markings,
					mark=between positions 0 and 1 step 0.05 with {
							\pgftransformresetnontranslations
							\draw[] (0 ,0) -- ++(0, -0.3);
						}
				},
			postaction={decorate}
		},
	area/.pic={
			\node [] (0) at (-3.75, -1.25) {};
			\node [] (1) at (-1.25, 1.5) {};
			\node [] (2) at (1.5, -2) {};
			\node [] (3) at (4, 0.25) {};
			\draw [bend left=15, name path=A] (0.center) to (1.center);
			\draw [bend left=15, looseness=0.75, name path=C] (1.center) to (3.center);
			\draw [bend right, name path=D] (3.center) to (2.center);
			\draw [bend right=15, name path=B] (2.center) to (0.center);
			\tikzfillbetween[of=A and B]{gray!20};
			\tikzfillbetween[of=C and D]{gray!20};
		}
}

% tangent/use tangent — позначити на позиції #1 уздовж шляху локальну систему
% координат (дотична + нормаль), щоб потім малювати щось "прив'язане" до кривої
% командою [use tangent=<номер точки>]
\tikzset{
	tangent/.style={
			decoration={
					markings,% switch on markings
					mark=
					at position #1
					with
						{
							\coordinate (tangent point-\pgfkeysvalueof{/pgf/decoration/mark info/sequence number}) at (0pt,0pt);
							\coordinate (tangent unit vector-\pgfkeysvalueof{/pgf/decoration/mark info/sequence number}) at (1,0pt);
							\coordinate (tangent orthogonal unit vector-\pgfkeysvalueof{/pgf/decoration/mark info/sequence number}) at (0pt,1);
						}
				},
			postaction=decorate
		},
	use tangent/.style={
			shift=(tangent point-#1),
			x=(tangent unit vector-#1),
			y=(tangent orthogonal unit vector-#1)
		},
	use tangent/.default=1,
	>=latex
}

% pics/parallelepiped — параметричний pic для 3D-паралелепіпеда (розміри a,b,c,
% кути theta/phi проєкції, стиль граней pstyle, окремі кольори граней xy/xz/yz
% через ключі "xy face=...", "xz face=...", "yz face=..." та спільний "all faces=...")
\tikzset{pics/parallelepiped/.style={code={
				\tikzset{parallelepiped/.cd,#1}
				\begin{scope}[x={(\pgfkeysvalueof{/tikz/parallelepiped/a}*1cm,0cm)},
						y={({cos(\pgfkeysvalueof{/tikz/parallelepiped/theta})*\pgfkeysvalueof{/tikz/parallelepiped/b}*1cm},
								{sin(\pgfkeysvalueof{/tikz/parallelepiped/theta})*\pgfkeysvalueof{/tikz/parallelepiped/b}*1cm})},
						z={({cos(\pgfkeysvalueof{/tikz/parallelepiped/phi})*\pgfkeysvalueof{/tikz/parallelepiped/c}*1cm},
								{sin(\pgfkeysvalueof{/tikz/parallelepiped/phi})*\pgfkeysvalueof{/tikz/parallelepiped/c}*1cm})}
						,/tikz/parallelepiped/pstyle,pic actions,
						declare function={mysign(\x)=ifthenelse(\x<0,-1,1);}]
					\path[parallelepiped/fall,parallelepiped/fxz] (0,1,0) -- (1,1,0) -- (1,1,1) -- (0,1,1) -- cycle;
					\path[parallelepiped/fall,parallelepiped/fyz,shift={({0.5-0.5*mysign(cos(\pgfkeysvalueof{/tikz/parallelepiped/phi}))},0,0)}]

					(0,0,0) -- (0,0,1) -- (0,1,1) -- (0,1,0) -- cycle;
					\path[parallelepiped/fall,parallelepiped/fxy,shift={(0,0,{0.5-0.5*mysign(sin(\pgfkeysvalueof{/tikz/parallelepiped/theta}))},0,0)}]

					(0,0,0) -- (1,0,0) -- (1,1,0) -- (0,1,0) -- cycle;
					\path[parallelepiped/fall,parallelepiped/fyz,shift={({0.5+0.5*mysign(cos(\pgfkeysvalueof{/tikz/parallelepiped/phi}))},0,0)}]

					(0,0,0) -- (0,0,1) -- (0,1,1) -- (0,1,0) -- cycle;
					\path[parallelepiped/fall,parallelepiped/fxy,shift={(0,0,{0.5+0.5*mysign(sin(\pgfkeysvalueof{/tikz/parallelepiped/theta}))},0,0)}]

					(0,0,0) -- (1,0,0) -- (1,1,0) -- (0,1,0) -- cycle;
					\path[parallelepiped/fall,parallelepiped/fxz] (0,0,0) -- (1,0,0) -- (1,0,1) -- (0,0,1) -- cycle;
				\end{scope}}},parallelepiped/.cd,a/.initial=4,b/.initial=1.5,c/.initial=2,
theta/.initial=30,phi/.initial=70,pstyle/.style={draw,thick,fill opacity=0.6,
		line join=round},fall/.style={draw},all
faces/.code={\tikzset{parallelepiped/fall/.style={#1}}},
fxy/.style={fill=red},xy face/.code={\tikzset{parallelepiped/fxy/.style={#1}}},
fxz/.style={fill=orange},xz face/.code={\tikzset{parallelepiped/fxz/.style={#1}}},
fyz/.style={fill=cyan},yz face/.code={\tikzset{parallelepiped/fyz/.style={#1}}}
}

\tikzstyle{glass}=[top color=glasscol!90!blue,bottom color=glasscol!90!blue,middle color=white,shading angle=40]


% --------------------------- Електричні кола (не використовується) ------------
% Закоментований чорновий стиль на основі рідної tikz-бібліотеки circuits.ee.IEC:
% вимикач/мультиметр/амперметр/вольтметр/гальванометр/джерело змінного струму.
% Свідомо НЕ підключати одночасно з circuitikz (див. коментар вище над
% \usetikzlibrary) — конфлікт ключів кола дає помилку "I do not know the key '/tikz/...'".
%\tikzset{circuit ee IEC,
%	every info/.style=red,
%	semithick,
%	every info/.style={font=\footnotesize},
%	small circuit symbols,
%	circuit declare symbol = ocontact,
%	circuit declare symbol = multimeter,
%	circuit declare symbol = ampermeter,
%	circuit declare symbol = voltmeter,
%	circuit declare symbol = galvanometer,
%	circuit declare symbol = ac source,
%	set ocontact graphic = {draw, fill = white, generic circle IEC, shape=circle, minimum size=1mm},
%	set multimeter graphic = {draw,generic circle IEC, minimum size=5mm},
%	set ampermeter graphic = {draw,generic circle IEC, minimum size=5mm,info=center:A},%
%	set voltmeter graphic = {draw,generic circle IEC, minimum size=5mm,info=center:V},
%	set galvanometer graphic = {draw,generic circle IEC, minimum size=5mm,info=center:G},
%	set ac source graphic = ac source IEC graphic,
%	ac source IEC graphic/.style=
%		{
%			transform shape,
%			circuit symbol lines,
%			circuit symbol size = width 3 height 3,
%			shape=generic circle IEC,
%			/pgf/generic circle IEC/before background=
%				{
%					\pgfpathmoveto{\pgfpoint{-0.575pt}{0pt}}
%					\pgfpathsine{\pgfpoint{0.3pt}{0.3pt}}
%					\pgfpathcosine{\pgfpoint{0.3pt}{-0.3pt}}
%					\pgfpathsine{\pgfpoint{0.3pt}{-0.3pt}}
%					\pgfpathcosine{\pgfpoint{0.3pt}{0.3pt}}
%					\pgfusepathqstroke
%				}
%		}
%}



% ---- bibliography: same biblatex setup as the print class ([biblatex] option) ----
\RequirePackage[backend=biber, bibstyle=gost-numeric, autolang=other, isbn=true, url=false, defernumbers=true]{biblatex}
\newbibmacro{string+url}[1]{\iffieldundef{url}{#1}{\href{\thefield{url}}{#1}}}
\DeclareFieldFormat{title}{\usebibmacro{string+url}{#1}}
\DefineBibliographyStrings{ukrainian}{bibliography = {Література}}
\DeclareBibliographyCategory{Textbooks}
\DeclareBibliographyCategory{Problems}
% the print heading is a part-level entry; in HTML the bibliography is a page of its own
\defbibheading{bibintoc}{\schapterpage{Література}}

%===============================================================================
%  Boxes, questions, problems: simple HTML blocks (styled by CSS classes)
%===============================================================================
\newenvironment{Theory}[1][]{\begin{BlockClass}{cb-theory}\textbf{Теоретичні відомості}\ #1\par}{\end{BlockClass}}
\newenvironment{Attention}[1][]{\begin{BlockClass}{cb-attention}}{\end{BlockClass}}
\newenvironment{Example}[2][]{\begin{BlockClass}{cb-example}\textbf{#2.}\ }{\end{BlockClass}}
\newenvironment{Historical}[1][]{\begin{BlockClass}{cb-historical}\textbf{Історична довідка.}\ }{\end{BlockClass}}
\newenvironment{tornpage}[1][]{\begin{BlockClass}{cb-quote}}{\end{BlockClass}}
\newenvironment{pict}{\begin{BlockClass}{cb-pict}}{\end{BlockClass}}
\newenvironment{Questions}[1][Контрольні питання]{\begin{BlockClass}{cb-questions}\textbf{#1}\par}{\end{BlockClass}}
\newenvironment{postulate}[1]{\begin{BlockClass}{cb-postulate}\textbf{#1.}\par}{\end{BlockClass}}
\newlist{quizlist}{enumerate}{1}
\setlist[quizlist]{label=\arabic*.}
\RequirePackage{ntheorem}
\theoremstyle{plain}\theoremheaderfont{\bfseries}\theorembodyfont{\normalfont}\theoremseparator{.}
\newtheorem{problem}{}[chapter]
% wrapstuff (text wrapped around a figure) has no HTML meaning -> a normal figure
\newenvironment{wrapstuff}[1][]{\begin{figure}[h]}{\end{figure}}
% answers/solution: kept inline in HTML
\newenvironment{solution}{\par\noindent\textbf{Розв'язок.}\ }{\par}
\newenvironment{answerbox}{\begin{BlockClass}{cb-answer}}{\end{BlockClass}}

% ---- macros for MathJax (generated from mathjax-macros.tex by mathjax2lwarp.py) ----
% tikzmark nodes inside formulas cannot go to MathJax: in HTML they are plain text
\begin{warpHTML}
\RenewDocumentCommand{\tikzmarknode}{o m m}{#3}
\RenewDocumentCommand{\tikzmark}{o m}{}
% \tikz[remember picture,overlay]{...} inside a formula: no image inside math in HTML
\let\LWRorigtikz\tikz
\NewDocumentCommand{\LWRtikzinmath}{o m}{}
\renewcommand{\tikz}{\ifmmode\expandafter\LWRtikzinmath\else\expandafter\LWRorigtikz\fi}
\end{warpHTML}
% inside HTML-mode pictures '$' is active (MathJax); tikz calc ($..$) needs it to be a math shift
\begin{warpHTML}
\preto\pgfpicture{\catcode`\$=3 }
\end{warpHTML}
% \htmlpicture{file.svg}: a picture built by prepare_html.py. SVG works only in HTML mode;
% the print pass (lualatex main-html) only creates helper files for lwarp, so a box is enough there.
\newcommand{\htmlpicture}[1]{\fbox{figure}}
\begin{warpHTML}
\renewcommand{\htmlpicture}[1]{\includegraphics{#1}}
\end{warpHTML}
\InputIfFileExists{lwarp-tikzdefs.tex}{}{}
\InputIfFileExists{lwarp-mathjax.tex}{}{\ClassWarning{ConspectBookHTML}{lwarp-mathjax.tex not found: formulas with your macros will be red in HTML}}
\endinput
