%===============================================================================
% ConspectBook.cls — клас для підручника з класичної електродинаміки.
% Побудований поверх стандартного класу book (однаколонковий, двосторонній
% друк). Підтримує два режими виводу: print та electronic.
% Компілятор: LuaLaTeX (основний), pdfLaTeX (запасний).
%===============================================================================
\NeedsTeXFormat{LaTeX2e}[1994/06/01]
\ProvidesClass{ConspectBook}[2024/12/21]
% Базовий клас: book, одна колонка, двосторонній друк (twoside — різні
% поля для парних/непарних сторінок, що важливо для палітурки).
\LoadClass[onecolumn, twoside]{book}
% Закоментований альтернативний варіант на базі tufte-book (широкі
% поля для нотаток на полях) — не використовується.
%\LoadClass[]{tufte-book}

%===============================================================================
%
%                           Налаштування опцій класу
%
%===============================================================================
% Оголошення логічних змінних для перемикання режимів:
%   \ifelectronic   — true якщо обраний режим electronic (кольорові посилання)
%   \ifbiblatex     — true якщо використовується biblatex замість bibtex
%   \ifmarginversioninfo — true якщо треба виводити інфо про версію на полях
\newif\ifelectronic
\newif\ifbiblatex
\newif\ifmarginversioninfo

% Попереджати про символи, яких немає у поточному шрифті (рівень 1 = warning).
\tracinglostchars=1

% Опція print: вимикає кольорові гіперпосилання (для друку на папері),
% встановлює підпис PDF-документа «Version for Printing».
\DeclareOption{print}{
  \PassOptionsToPackage{colorlinks=false}{hyperref}
  \PassOptionsToPackage{pdfsubject={Version for Printing}}{hyperref}
  \electronicfalse
}

% Опція electronic: вмикає кольорові посилання.
%   - Визначає колір «малина» (темно-червоний) для внутрішніх посилань.
%   - linkcolor=malina  — посилання всередині документа
%   - urlcolor=blue     — зовнішні URL
%   - citecolor=green!60!black — посилання на бібліографію
%   - pdfsubject=«Electronic Version» — метадані PDF
\DeclareOption{electronic}{\def\defcolor{\RequirePackage[dvipsnames,svgnames,table]{xcolor}\definecolor{malina}{rgb}{0.6,0.0,0.0}}
  \PassOptionsToPackage{linkcolor=malina}{hyperref}
  \PassOptionsToPackage{colorlinks=true}{hyperref}
  \PassOptionsToPackage{urlcolor=blue}{hyperref}
  \PassOptionsToPackage{citecolor=green!60!black}{hyperref}
  \PassOptionsToPackage{pdfsubject={Electronic Version}}{hyperref}
  \electronictrue
}

% Опція marginversioninfo: вмикає відображення інформації про версію
% на полях сторінки (зручно при розробці для відстеження змін).
\DeclareOption{marginversioninfo}{%
  \marginversioninfotrue
}

% Опція biblatex: вмикає режим з пакетом biblatex (розширена
% бібліографія через biber замість стандартного bibtex).
\DeclareOption{biblatex}{
  \biblatextrue
}

% За замовчуванням активується опція electronic (кольорова версія).
\ExecuteOptions{electronic}
% Обробити всі передані опції.
\ProcessOptions\relax
% Виконати визначення кольору malina (якщо вибрано electronic —
% \defcolor містить потрібний код; для print — порожня команда).
\defcolor{}

%===============================================================================
%
%                               Геометрія сторінки
%
%===============================================================================
% Допоміжна довжина для відступу зверху — дозволяє легко змінювати
% верхнє поле в одному місці.
\newlength{\topspace}
\setlength{\topspace}{2cm}
% Налаштування геометрії через пакет geometry:
%   a4paper     — формат A4
%   footskip    — відстань від нижньої лінії тексту до низу колонтитула
%   headsep     — відстань від верхнього колонтитула до тексту
%   top/bottom/left/right — поля сторінки
\RequirePackage[%
  a4paper,%
  footskip=1cm,%
  headsep=0.5cm,%
  top=\topspace, %поле сверху
  bottom=2cm, %поле снизу
  left=2cm, %поле ліворуч
  right=2cm, %поле праворуч
]{geometry}
% Закоментований альтернативний варіант: широке ліве поле (8cm) для
% нотаток на полях у стилі tufte.
%\usepackage[lmargin=8cm,rmargin=1cm,marginparwidth=6cm,marginparsep=2em]{geometry}


%===============================================================================
%
%                       Налаштування мови та компіляторів
%
%===============================================================================

% fontsize: встановлює базовий розмір шрифту 14pt незалежно від класу
% (стандартний book підтримує лише 10/11/12pt).
\RequirePackage[fontsize=14pt]{fontsize}
% iftex: надає умовні команди \ifluatex, \ifpdftex тощо для
% розгалуження залежно від компілятора.
\RequirePackage{iftex}


% Гілка для LuaLaTeX (основний компілятор проекту):
\ifluatex
  % fontspec: завантаження довільних OpenType/TrueType шрифтів.
  \RequirePackage{fontspec}
  % Основний шрифт тексту: BookmanOldStyle (serif, академічний стиль).
  % Закоментовані альтернативи: alegreya, CMU Serif.
  %    \RequirePackage[sfdefault,regular]{roboto}
  \setmainfont{BookmanOldStyle}%{alegreya}%{CMU Serif}
  % Рубрикаційний (sans-serif) шрифт: Roboto (сучасний, добре читається
  % у заголовках). Закоментована альтернатива: Arial.
  \setsansfont{Roboto}%{Arial}
  % Моноширинний шрифт: JetBrains Mono (для коду).
  % Закоментована альтернатива: Consolas.
  \setmonofont{JetBrains Mono}%{Consolas}
  % Вмикає лігатури TeX-стилю (fi, fl, тощо) для всіх шрифтів.
  \defaultfontfeatures{Ligatures={TeX}}
  % luacolor: коректна підтримка кольорів при компіляції LuaLaTeX
  % (усуває конфлікти з деякими пакетами кольорів).
  \RequirePackage{luacolor}
\else
  % Гілка для pdfLaTeX:
  % T2A — кирилиця, T1 — розширена латиниця.
  \RequirePackage[T2A,T1]{fontenc}
  % Кодування вхідного файлу UTF-8.
  \RequirePackage[utf8]{inputenc}
  % Забезпечує коректний пошук та копіювання тексту з PDF
  % (відображення гліфів у Unicode).
  \input{glyphtounicode}
  \pdfgentounicode=1
  % Закоментований пакет pscyr — альтернативні кириличні шрифти PS.
  %\RequirePackage{pscyr}
  % cmap: вбудовує таблицю відображення символів для пошуку у PDF.
  \RequirePackage{cmap}
  % Встановлює sans-serif шрифт за замовчуванням (fos — Fourier Sans).
  \renewcommand{\sfdefault}{fos}
  % Встановлює жирний шрифт (b = bold, а не bx = bold extended).
  \renewcommand{\bfdefault}{b}
\fi

% babel: підтримка мов. Основна мова — ukrainian (остання у списку),
% додаткова — english (для формул, термінів тощо).
\RequirePackage[english,ukrainian]{babel}
% microtype: мікротипографічні покращення (плавніший правий край,
% кернінг між символами) — помітно покращує вигляд набору.
\RequirePackage{microtype}


%===============================================================================
%
%                               Логічні змінні
%
%===============================================================================
% Ці прапорці використовуються в головному файлі книги для умовного
% включення розділів:
%   \ifappendix    — true під час верстки додатків
%   \ifanswers     — true під час верстки розділу відповідей
%   \iftoc         — true якщо треба виводити зміст
%   \ifbibliography — true якщо треба виводити бібліографію
%   \ifintro       — true під час верстки вступу
\newif\ifappendix
\newif\ifanswers
\newif\iftoc
\newif\ifbibliography
\newif\ifintro

%===============================================================================
%
%                       Налаштування типографських вимог
%
%===============================================================================

% Закоментовані пакети для боротьби з «висячими» рядками:
%   impnattypo — типографські вимоги (заборона переносів, останній рядок)
%   nowidow    — усунення «вдів» і «сиріт» (одиночних рядків)
%   clubpenalty/widowpenalty — штрафи LaTeX за «вдів» і «сиріт»
%   parskip    — відстань між абзацами
%\RequirePackage[nosingleletter, hyphenation, lastparline]{impnattypo}
%\usepackage[defaultlines=4,all]{nowidow}
%\clubpenalty =1000
%\widowpenalty=1000
%\setlength{\parskip}{0.5ex}%

% Відступ першого рядка абзацу: 2em (два кегля поточного шрифту).
\setlength{\parindent}{2em}%
% Закоментований міжрядковий інтервал 1.1 (трохи ширший за стандартний).
%\renewcommand{\baselinestretch}{1.1}

% Дозволяє розтягувати останній рядок сторінки на 1pt вниз —
% допомагає уникнути underfull \vbox при верстці.
\def\@textbottom{\vskip \z@ \@plus 1pt}
\let\@texttop\relax
% Закоментований аварійний розтяг для уникнення overfull \hbox.
%\setlength{\emergencystretch}{1em}

%===============================================================================
%
%                                   Кольори
%
%===============================================================================
% Основна палітра книги. Всі кольори визначені через RGB (0–255).

% malina: темно-червоний — для гіперпосилань та акцентів у тексті.
\definecolor{malina}{RGB}{153,0.0,0.0}
% Закоментовані альтернативні варіанти теми оформлення:
%\definecolor{lighbluecolor}{RGB}{0,163,243}
%\definecolor{iptgreen}{RGB}{34,102,101}
%\definecolor{themecolordark}{RGB}{0,163,243}
%\definecolor{themecolorlight}{RGB}{191,233,251}

% themecolormain: середньо-синій — основний акцентний колір теми.
\definecolor{themecolormain}{RGB}{51,51,178}
% themecolordark: темно-синій — для заголовків розділів, рамок tcolorbox.
\definecolor{themecolordark}{RGB}{0,46,100}
% themecolorlight: блакитний — для другорядних елементів, ліній задач.
\definecolor{themecolorlight}{RGB}{0,100,170}
% paper: жовтувато-кремовий — фон для блоків типу «старий папір» (tornpage).
\definecolor{paper}{RGB}{239,227,157}
% titlebgdark/titlebglight: кольори фону для заголовків секцій
% (зараз не використовуються активно, залишені для майбутнього).
\definecolor{titlebgdark}{RGB}{0,103,102}
\definecolor{titlebglight}{RGB}{191,233,251}

%===============================================================================
%
%                                   Пакети
%
%===============================================================================

% textcase: коректне перетворення регістру з урахуванням математики
% та спецсимволів. overload — перевизначає стандартний \MakeUppercase.
\RequirePackage[overload]{textcase}
\let\MakeUppercase\MakeTextUppercase

% indentfirst: абзацний відступ також у першому абзаці після заголовка
% (відповідає українській типографській нормі).
\RequirePackage{indentfirst}
% ------------------------------------ Плаваючі об'єкти ------------------------
% Закоментовані: subfig — для підрисунків (замінено на subcaption).
%\RequirePackage{subfig}
%\renewcommand\thesubfigure{\alph{subfigure}}
% wrapstuff: обтікання плаваючих об'єктів текстом
% (використовується для рисунків у задачах).
\RequirePackage{wrapstuff}
% ------------------------------------ Таблиці ---------------------------------
% tabularray: сучасна заміна tabular/longtable/array з розширеними
% можливостями форматування.
\RequirePackage{tabularray}
% Товщина ліній у таблицях (горизонтальних і вертикальних).
\setlength\arrayrulewidth{1pt}
% ------------------------------------ Математика ------------------------------
% Гілка для LuaLaTeX: unicode-math забезпечує повну підтримку
% математичних Unicode-символів через OpenType Math шрифти.
\ifluatex
  %	\RequirePackage{lualatex-math}  % закоментований патч для LuaLaTeX
  % math-style=TeX: математичний стиль, сумісний зі звичайним LaTeX
  % (латиниця курсивом, греки прямо і т.д.).
  % bold-style=TeX: жирна математика через \mathbf.
  \RequirePackage[math-style=TeX,bold-style=TeX]{unicode-math}
  % Математичний шрифт: Stix Two Math — повний набір символів,
  % добре поєднується з BookmanOldStyle.
  \setmathfont[]{Stix Two Math}
\else
  % Для pdfLaTeX: стандартні математичні пакети AMS.
  \RequirePackage{amsfonts}
  \RequirePackage{amssymb}
\fi
% esint: розширені інтегральні символи (контурні, поверхневі інтеграли —
% активно використовуються в електродинаміці).
\RequirePackage{esint}
% nicefrac: дроби в тексті типу ½ (косий дріб).
\RequirePackage{nicefrac}
% Зручний псевдонім: \nfrac замість \nicefrac.
\let\nfrac\nicefrac
% Дозволяє розривати виведені формули між сторінками (важливо для
% довгих виведень у книзі).
\allowdisplaybreaks

% ------------------------- Визначення математичних команд ---------------------
% \vect{x} — вектор: жирний прямий символ (\symbf з unicode-math).
% Використовується для всіх векторних величин книги.
\newcommand{\vect}[1]{\symbf{#1}}
% Скорочення для основних векторів електродинаміки:
\def\Efield{\vect{E}}          % --- Вектор електричного поля E            ---
\def\Dfield{\vect{D}}          % --- Вектор електричної індукції D          ---
\def\Bfield{\vect{B}}          % --- Вектор магнітної індукції B            ---
\def\Hfield{\vect{H}}          % --- Вектор напруженості магнітного поля H  ---
% Диференціальні оператори через набла:
\def\rot{\symbf{\nabla}\times} % --- Ротор: ∇×                              ---
\def\divg{\symbf{\nabla}\cdot} % --- Дивергенція: ∇·                        ---
\def\grad{\vect{\nabla}}       % --- Градієнт: ∇                            ---
% Скорочення для часткових похідних:
%   \diff{f}{x}   → ∂f/∂x   (перша часткова похідна)
%   \ddiff{f}{x}  → ∂²f/∂x² (друга часткова похідна по одній змінній)
\def\diff#1#2{\frac{\partial #1}{\partial #2}}
\def\ddiff#1#2{\frac{\partial^2 #1}{\partial #2^2}}
% Скорочення для часткових похідних за часом:
%   \parttime{f}  → ∂f/∂t
%   \pparttime{f} → ∂²f/∂t²
\def\parttime#1{\frac{\partial{#1}}{\partial t}}
\def\pparttime#1{\frac{\partial^2{#1}}{\partial t^2}}
% Оператор Даламбера (хвильовий оператор □): символ білого квадрата
% з тонким пробілом після нього.
\def\Dalambertian{\mdlgwhtsquare\, }

% Команди, що визначаються після завантаження всіх пакетів (\AtBeginDocument),
% оскільки деякі залежать від стану після \begin{document}:
\AtBeginDocument{%
  % Закоментоване перевизначення \phi → \varphi (не активне, бо в
  % деяких розділах обидва символи мають різний зміст).
  %	\let\phi\varphi
  % Замінює \epsilon на \varepsilon скрізь (стандартна наукова нотація
  % використовує варіант з хвостиком).
  \let\epsilon\varepsilon
  % Математичні оператори (набираються прямим шрифтом):
  \DeclareMathOperator{\const}{const}  % константа
  \DeclareMathOperator{\Div}{div}      % дивергенція (текстова форма)
  \DeclareMathOperator{\Rot}{rot}      % ротор (текстова форма)
  \DeclareMathOperator{\Grad}{grad}    % градієнт (текстова форма)
  \DeclareMathOperator{\inv}{inv}      % інваріант
  % Лапласіан ∆ — визначено як \Delta (стандартний символ).
  \newcommand{\Laplasian}{\Delta}
}

% \emphx{текст} — виділений текст кольором малина + курсив.
% Використовується для термінів при їх першому введенні.
\NewDocumentCommand{\emphx}{m}{\emph{\textcolor{malina}{#1}}}

% Закоментовані хімічні пакети (не потрібні для електродинаміки):
% \RequirePackage[version=4]{mhchem}
% \RequirePackage{chemfig}
% ------------------------- Таблиці --------------------------------------------
% \localinput{file} — вставка tikz-рисунка з підкаталогу tikz/
% поточного розділу (currfilebase дає ім'я поточного файлу без розширення).
\newcommand{\localinput}[1]{\input{\currfilebase/tikz/#1}}
% booktabs: професійні горизонтальні лінії в таблицях (\toprule,
% \midrule, \bottomrule) — без вертикальних ліній.
\RequirePackage{booktabs}
% Прибирає зайві відступи над і під лініями таблиць.
\setlength{\aboverulesep}{0pt}
\setlength{\belowrulesep}{0pt}
% Додатковий вертикальний простір у рядках таблиці для кращої читабельності.
\setlength{\extrarowheight}{0.75ex}
% caption: налаштування підписів до рисунків і таблиць.
%   justification=centering — підпис по центру
%   labelsep=period         — крапка після номера («Рис. 1.» замість «Рис. 1:»)
\RequirePackage[justification=centering,labelsep=period]{caption}
% sidecap: підписи збоку від рисунка (outercaption — ззовні).
% wide — підпис може виходити за межі рисунка.
\RequirePackage[outercaption, wide]{sidecap}
% Вертикальне вирівнювання підпису збоку: по центру рисунка.
\sidecaptionvpos{figure}{c}
% subcaption: підрисунки (a), (б) тощо — сучасна заміна subfig.
\RequirePackage{subcaption}
% multirow: об'єднання рядків у таблицях по вертикалі.
\RequirePackage{multirow}
% ---------------------------- Файлові операції ---------------------------------
% currfile: надає \currfilebase (ім'я поточного файлу) та інші
% команди для роботи з іменами файлів — використовується у \localinput.
\RequirePackage{currfile}
% ---------------------------- Пакети LaTeX3 -----------------------------------
% expl3: основа для програмування в стилі LaTeX3 (розширені макроси, змінні,
% epigraph: оформлення епіграфів на початку розділів/частин.
\RequirePackage{epigraph}
% Ширина блоку епіграфа — 80% від ширини тексту.
\setlength\epigraphwidth{.8\textwidth}
% Без горизонтальної лінії між текстом епіграфа і підписом.
\setlength\epigraphrule{0pt}
% Вирівнювання тексту епіграфа: по лівому краю (flushepinormal).
\renewcommand{\textflush}{flushepinormal}
% refcount: доступ до числового значення лічильників через \ref.
% Використовується для перехресних посилань задач↔розв'язки.
\RequirePackage{refcount}
% pageslts: розширене керування нумерацією сторінок,
% зокрема підрахунок загальної кількості сторінок.
\RequirePackage[]{pageslts}
% Арабська нумерація сторінок.
\pagenumbering{arabic}
% todonotes: пакет для заміток редактора (disable — всі нотатки
% приховані; змінити на без disable для показу).
\RequirePackage[disable]{todonotes}
% pdftexcmds: сумісність між LuaLaTeX і pdfLaTeX для команд \pdf@...
\RequirePackage{pdftexcmds}
% tcolorbox: основний пакет для кольорових блоків (задачі, теорія,
% увага тощо). most+many завантажують усі бібліотеки.
\RequirePackage[most, many]{tcolorbox}

% Стиль для підсвічування математичних формул у tcolorbox (\tcbhighmath):
%   enhanced jigsaw  — режим рендерингу без артефактів
%   colframe         — колір рамки (themecolormain, синій)
%   opacityback=0.1  — дуже прозорий фон
%   arc=0pt          — прямі кути
%   boxrule=1pt      — тонка рамка
%   boxsep=1pt       — мінімальний відступ
%   Заголовок блоку: маленький, білий фон, чорний текст.
\tcbset{
  highlight math style={
      enhanced jigsaw,
      colframe=themecolormain,
      opacityback=0.1,
      colback=themecolormain!1!white,
      arc=0pt,
      boxrule=1pt,
      boxsep=1pt,
      attach boxed title to top center = {yshift=-\tcboxedtitleheight/2},
      colbacktitle=white,
      coltitle=black,
      fonttitle = \scriptsize,
      boxed title style={
          boxrule=0pt,
          colframe=white,
          colback=white,
          size=fbox,
        },
    },
}

%===============================================================================
%
%                                   Рисування
%
%===============================================================================

% Основні пакети для векторної графіки:
%   tikz        — основний пакет для рисування
%   pgfplots    — графіки функцій та даних
%   tikz-3dplot — тривимірні системи координат
\RequirePackage{tikz, pgfplots, tikz-3dplot}
% contour: обведення тексту (ефект «світіння») для написів на
% кольорових фонах. Товщина контуру 1.1pt.
\RequirePackage[outline]{contour}
\contourlength{1.1pt}

\RequirePackage{fontawesome5}


% Закоментований блок зовнішньої компіляції tikz-рисунків:
% tikzexternalize зберігає рисунки у PDF-файлах для прискорення
% компіляції (корисно при великій кількості складних рисунків).
%---------------------------------------------------
%\usetikzlibrary{external}
%\usepgfplotslibrary{external}
%\tikzexternalize[optimize=false, prefix=figures/]
%---------------------------------------------------

% Бібліотеки tikz:
%   calc         — арифметичні операції з координатами ($(A)+(B)$)
%   bending      — вигинання стрілок уздовж кривих
\usetikzlibrary{calc, bending}
%   decorations.text     — текст уздовж кривої
%   decorations.markings — маркери (стрілки) вздовж шляху
\usetikzlibrary{decorations.text, decorations.markings}
%   intersections — знаходження точок перетину шляхів
%   backgrounds   — малювання за основним шаром
\usetikzlibrary{intersections, backgrounds}
%   arrows.meta   — сучасні стрілки (Latex, Stealth тощо)
\usetikzlibrary{arrows.meta}
%   shapes, shadows — геометричні фігури та тіні
\usetikzlibrary{shapes, shadows}
%   quotes  — підписи до кутів (angle quotes)
%   angles  — відображення кутів між лініями
%   tikzmark — позначення позицій у тексті для з'єднань
\usetikzlibrary{quotes,angles,tikzmark}
% Геометричні фігури: еліпс, прямокутник зі скругленнями тощо.
\usetikzlibrary{shapes.geometric}
% Налаштування pgfplots:
%   every axis label — розмір шрифту підписів осей: \small
%   compat=1.18      — версія сумісності (уникає попереджень)
\pgfplotsset{
  %every tick label/.append style={scale=0.5},
  every axis label/.append style={font=\small},
  compat=1.18,
}
% Оголошення фонового шару «background» для tornpage.
% Шари: background малюється першим (під «main»).
\pgfdeclarelayer{background}
\pgfsetlayers{background, main}

% fillbetween: заливка області між двома кривими на графіку.
\usepgfplotslibrary{fillbetween}

% Розмір шрифту у всіх tikz-рисунках: \small (менший за основний текст).
\tikzset{every picture/.style={font=\small}}

% Стиль partial ellipse: малює дугу еліпса від кута #1 до #2
% з радіусом #3. Зручно для зображення поверхонь обертання.
\tikzset{
  partial ellipse/.style args={#1:#2:#3}{
      insert path={+ (#1:#3) arc (#1:#2:#3)}
    }
}


% Два стилі для ліній з мітками-насічками (vertical ticks) та
% pic «area» для зображення довільної замкненої поверхні:
%   vertical ticks: розставляє вертикальні відрізки вздовж шляху
%                   з кроком 5% для позначення меж інтегрування.
%   area: pic з чотирма вузлами і заливкою між кривими —
%         використовується для позначення об'єму інтегрування.
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
      \tikzfillbetween[of=A and B, on layer=main]{gray!20};
      \tikzfillbetween[of=C and D, on layer=main]{gray!20};
    }
}

% tangent: стиль для визначення дотичного вектора до кривої у заданій
% точці (параметр #1 від 0 до 1 — відносна позиція на шляху).
% Записує координати точки і дотичного вектора у спеціальні вузли,
% які потім можна використати через use tangent для локальних СК.
% use tangent: переміщення у систему координат дотичного вектора —
% дозволяє малювати «вздовж» кривої (наприклад, стрілки потоку).
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

% ---------------------------- Паттерни ----------------------------------------
% Бібліотека штрихувань
\usetikzlibrary{patterns}


% midarrow: стрілка вперед (→) в середині відрізка.
% Використовується для позначення напрямку струму або поля.
\tikzstyle{midarrow} = [
  postaction={ decorate,
      decoration={ markings, mark=at position .5 with {\arrow{>}}}}
]

% midarrowR: стрілка назад (←) в середині відрізка.
\tikzstyle{midarrowR} = [
  postaction={ decorate,
      decoration={ markings, mark=at position .5 with {\arrow{<}}}}
]


% arrowpos: стрілка у довільній позиції на шляху.
%   #1 — позиція (0..1), #2 — зсув по x, #3 — довжина стрілки.
\tikzset{
  arrowpos/.style n args={3}{
      decoration={markings,mark=at position #1 with {\arrow[xshift=#2]{Latex[length=#3]}}},
      postaction={decorate}
    }
}

%===============================================================================
%
%                                   Інтервали
%
%===============================================================================
% \@spase: відстань між маркером розділу і його номером у колонтитулі.
\newlength{\@spase}
\setlength{\@spase}{0.5ex} % space between \@sectiontitlemark and \thesection
% \length@titlemark: ширина маркера розділу у колонтитулі
% (обчислюється динамічно при формуванні колонтитула).
\newlength{\length@titlemark} % length of \@sectiontitlemark
%===============================================================================
%
%                       Налаштування для титульних сторінок
%
%===============================================================================

% alwayssingle: оточення для елементів, що займають окрему сторінку
% (титульна сторінка, присвяти тощо).
%   - Встановлює порожній стиль сторінки (\thispagestyle{empty})
%   - В двоколонковому режимі тимчасово перемикається на одну колонку
%   - Після завершення повертає попередній режим
\newenvironment{alwayssingle}{%
  \thispagestyle{empty}
  \@restonecolfalse
  \if@twocolumn\@restonecoltrue\onecolumn
  \else\if@openright\cleardoublepage\else\clearpage\fi
  \fi}%
{\if@restonecol\twocolumn
  \else\newpage\thispagestyle{empty}\fi
}

% titlepagestyle: стиль tcolorbox для кольорових банерів на
% титульній сторінці (темно-синій фон, блакитна рамка).
% Ключова особливість: блок розтягується на повну ширину сторінки
% незалежно від полів — досягається через negative enlarge і
% компенсацію відступів (hoffset, oddsidemargin, textwidth).
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

% Перевизначення \title для збереження назви одразу у двох формах:
%   @title      — стандартна форма для \maketitle
%   \realtitle  — глобальна змінна для використання у колонтитулах
% Закоментована альтернатива зберігала б «плоску» версію назви
% (без переносів рядка \\) для PDF-метаданих.
\ExplSyntaxOn
\RenewDocumentCommand{\title}{m}
{
  \tl_gset:cn { @title } { #1 } % needed by \maketitle
  \tl_gset:Nn { \realtitle } { #1 }
  %  \seq_set_split:Nnn \l_tmpa_seq { \\ } { #1 }
  %  \tl_gset:Nx \inlinetitle { \seq_use:Nn \l_tmpa_seq { ~ } }
}
\ExplSyntaxOff

%===============================================================================
%
%                                   Рубрикація
%
%===============================================================================

% Замінює \cleardoublepage на \clearpage — нова частина/розділ починається
% на найближчій сторінці (не обов'язково правій), що економить папір.
\let\cleardoublepage\clearpage

% \schapter{назва} — «зіркастий» розділ з додаванням до змісту.
% Аналог \chapter*, але автоматично додає запис до ToC.
% Використовується для: Вступу, Передмови, Відповідей.
\def\schapter#1{%
  \chapter*{#1}
  \addcontentsline{toc}{chapter}{#1}%
}


% ---------------------------------------- Верстка ДОДАТКІВ -------------------

% Перевизначення \appendix для книги:
%   - Встановлює \appendixtrue (для умовних перемикань у стилях)
%   - Нумерація секцій літерами (A, B, C...)
%   - Перезапуск лічильників таблиць і рівнянь з прив'язкою до секції
%   - Очищення сторінки і перехід на стиль «appendix»
%   - Вставляє заголовок «Додатки» з записом у зміст
\renewcommand\appendix{\par
  \appendixtrue
  \gdef\thesection{\@Alph\c@section}
  \@addtoreset{table}{section}
  \renewcommand\thetable%
  {\thesection.\@arabic\c@table}
  \setcounter{chapter}{0}%
  \setcounter{section}{0}%
  \setcounter{equation}{0}
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
% ---------------------------------------- Верстка ВІДПОВІДЕЙ -----------------
% \answers — команда для початку розділу відповідей до задач:
%   - Встановлює \answerstrue
%   - Перезапускає лічильники розділів
%   - Перемикає стиль колонтитула на «answers»
%   - Вставляє заголовок «Відповіді» з записом у зміст
%   - Нумерація рівнянь без прив'язки до розділу (просто arabic)
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
% ---- Лічильник виносок скидається на кожній сторінці -----------------------
% Стандартно виноски нумеруються протягом усього розділу.
% Тут перевизначено: нумерація починається з 1 на кожній сторінці
% (зручно для підручника, де виноски рідкісні і короткі).
\@newctr{footnote}[page]



% titlesec: гнучке налаштування форматів заголовків (\chapter, \section...).
%   pagestyles — дозволяє визначати стилі сторінок через titlesec
%   explicit   — назва розділу передається явно як аргумент (#1)
\RequirePackage[pagestyles, explicit]{titlesec}
% titletoc: налаштування змісту (відступи, шрифти, лідери).
\RequirePackage{titletoc}

% chapnumb: ширина блоку з великим номером розділу (4cm).
\newlength\chapnumb
\setlength\chapnumb{4cm}

% Формат заголовка \part: великий жирний sans-serif, номер частини
% перед назвою, назва — по центру темно-синього кольору.
\titleformat{\part}[display]{\bfseries\sffamily\huge}{\partname\ \thepart }{0pt}{\addvspace{1em}\Huge\centering\color{themecolordark} #1}

% Запис частини у зміст: великий жирний sans-serif, з вертикальним
% відступом, горизонтальною лінією після і номером сторінки праворуч.
\titlecontents{part}%
[0pt]{\sffamily\bfseries\large\protect\addvspace{25pt}\addvspace{1.5ex}}
{}{\partname~}
{\hfill\contentspage}%
[\addvspace{0.7ex}\titlerule\addvspace{10pt}]%

% Кожна частина починається на новій сторінці.
\titleclass{\part}{top}
\newcommand\partbreak{\clearpage}

% Формат заголовка \chapter: нестандартний «великий номер зліва».
%   Лівий parbox (chapnumb=4cm): величезний номер розділу (100pt)
%                                темно-синього кольору.
%   Правий parbox (textwidth-chapnumb): назва розділу вирівняна вправо,
%                                       з горизонтальною лінією знизу.
\titleformat{\chapter}[block]
{\normalfont\sffamily}{}{0pt}
{\parbox[b]{\chapnumb}{%
    \color{themecolordark}\fontsize{100}{90}\selectfont\thechapter}%
  \parbox[b]{\dimexpr\textwidth-\chapnumb\relax}{%
    \raggedleft%
    \hfill{\LARGE#1}\\
    \rule{\dimexpr\textwidth-\chapnumb\relax}{0.4pt}}}

% Формат ненумерованого \chapter* (наприклад, «Відповіді», «Додатки»):
% той самий стиль, але лівий parbox порожній (лише відступ).
\titleformat{name=\chapter,numberless}[block]
{\normalfont\sffamily}{}{0pt}
{\parbox[b]{\chapnumb}{%
    \mbox{}}%
  \parbox[b]{\dimexpr\textwidth-\chapnumb\relax}{%
    \raggedleft%
    \hfill{\LARGE#1}\\
    \rule{\dimexpr\textwidth-\chapnumb\relax}{0.4pt}}}

% Формат \section: звичайний розмір, жирний, номер + крапка + відступ 1em.
\titleformat{\section}
{\normalsize\bfseries}{\thesection.}{1em}{#1}

% Формат \subsection: «runin» — заголовок в одному рядку з текстом,
% після назви крапка (завершальний аргумент [.]).
\titleformat{\subsection}[runin]
{\normalsize\bfseries}
{\thesubsection.}
{1em}
{#1}
[.]


% Стилі колонтитулів (верхній рядок + нижній рядок):
%   main: для основного тексту — зліва або справа (залежно від
%         парності) номер і назва поточного розділу курсивом;
%         знизу по центру — номер сторінки.
%   answers/appendix/bibliography: аналогічна структура, але замість
%         назви розділу — фіксований текст («Відповіді» і т.д.).
%   plain: лише номер сторінки по центру знизу (для першої сторінки
%          розділу, де немає колонтитула зверху).
\newpagestyle{main}{\headrule%
  \sethead{\ifodd\thepage\relax\else\itshape\small\thechapter.\ \chaptertitle\fi}{}{\ifodd\thepage\itshape\small\thechapter.\
      \chaptertitle\else\relax\fi}
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

% Перша сторінка розділу (\chapter) — стиль plain (лише номер знизу).
\assignpagestyle{\chapter}{plain}
% Перша сторінка частини (\part) — порожній стиль (без колонтитулів).
\assignpagestyle{\part}{empty}




%===============================================================================
%
%               Підписи під таблицями, рисунками та списки
%
%===============================================================================

% \tabcaption і \figcaption: дозволяють використовувати \caption
% поза оточеннями table/figure (наприклад, у tcolorbox-блоках).
\def\tabcaption{\def\@captype{table}\caption}
\def\figcaption{\def\@captype{figure}\caption}
% enumitem: гнучке налаштування списків (itemize, enumerate, description).
%   inline — підтримка рядкових списків (item* в одному рядку тексту)
\RequirePackage[inline]{enumitem}
% nosep: прибирає всі вертикальні відступи у списках (компактний вигляд).
\setlist{nosep}
%\setlist{nolistsep}  % закоментований альтернативний варіант


% ------------------------------- Відступи в формулах --------------------------
% Відступи навколо виведених формул (display math).
% Всі встановлені в 1ex для компактного, але читабельного вигляду:
%   abovedisplayskip/belowdisplayskip — стандартний відступ (формула
%                                       не стоїть поруч зі звичайним рядком)
%   abovedisplayshortskip/belowdisplayshortskip — коротка формула
%                                       (попередній рядок коротший)
\setlength\abovedisplayskip{1ex}
\setlength\belowdisplayskip{1ex}
\setlength\abovedisplayshortskip{1ex}
\setlength\belowdisplayshortskip{1ex}

% --------------------- Відступ між написом та рисунком -----------------------
% Зменшений відступ між плаваючим об'єктом (figure/table) і текстом.
\setlength{\textfloatsep}{5pt}

% --------------------- Підписи до рисунку (розмір тексту) -------------------
% Підписи до рисунків і таблиць: маленький шрифт (\small).
\captionsetup[figure]{font=small,labelfont=small}
\captionsetup[table]{font=small,labelfont=small}

% ---------------------------- Bibliography spacing ----------------------------
% Налаштування відступів між елементами бібліографії:
%   bibitemsep — невеликий пружний відступ між записами (0.1 рядка)
%   bibparskip — без відступів між абзацами всередині запису
% Застосовується через перевизначення \thebibliography.
\newlength{\bibitemsep}\setlength{\bibitemsep}{.1\baselineskip plus .05\baselineskip minus .05\baselineskip}
\newlength{\bibparskip}\setlength{\bibparskip}{0pt}
\let\oldthebibliography\thebibliography
\renewcommand\thebibliography[1]{%
  \oldthebibliography{#1}%
  \setlength{\parskip}{\bibitemsep}%
  \setlength{\itemsep}{\bibparskip}%
}

%===============================================================================
%
%                                    INDEX
%
%===============================================================================

% indextools: розширена підтримка предметного покажчика.
% Підключення програми upmendex (краща підтримка Unicode і кирилиці
% порівняно зі стандартним makeindex).
\RequirePackage[]{indextools}
\makeindex[
  program=upmendex,     % використовувати upmendex для сортування
  intoc,                % додати покажчик у зміст
  title={Алфавітний покажчик},
  noautomatic=false     % автоматично генерувати записи через \index{}
]


%===============================================================================
%
%                                    HYPERREF
%
%===============================================================================

% hyperref — пакет для PDF-гіперпосилань. Завантажується після
% більшості пакетів, щоб уникнути конфліктів.
%   bookmarks=true          — PDF-закладки з розділами
%   bookmarksnumbered=true  — нумерація у закладках
%   unicode                 — підтримка Unicode у метаданих PDF
%   linktocpage=true        — у змісті клікабельний номер сторінки,
%                             а не весь рядок заголовка
%   hypertexnames=true      — стабільні імена якорів між компіляціями
%   pdftoolbar=true         — показувати панель інструментів у PDF
%   pdfpagelayout=TwoPageRight — відкривати PDF у режимі розвороту
%                               (ліва сторінка парна, права непарна)
%   pdfauthor               — метадані: автор
%   pdfdisplaydoctitle=true — показувати назву документа у заголовку
%                             вікна PDF-переглядача
%   pdfkeywords             — ключові слова для пошуку
%   pdfencoding=auto        — автоматичне кодування PDF-рядків
%   hyperindex=true         — гіперпосилання з покажчика на сторінки
\RequirePackage[%
  bookmarks = true,
  bookmarksnumbered=true,
  unicode,
  linktocpage = true,
  hypertexnames=true,
  pdftoolbar=true,
  pdfpagelayout=TwoPageRight,
  pdfauthor={Ponomarenko S.M.},
  pdfdisplaydoctitle=true,
  pdfkeywords={Electrostatics, Magnetostatics, Electrodynamics, Current, Field},
  pdfencoding=auto,
  hyperindex=true
]%
{hyperref}
% hypcap: виправляє позицію якоря гіперпосилань для рисунків і таблиць
% (без нього посилання веде до підпису, а не до рисунка).
\RequirePackage[all]{hypcap}

% Патч для \autoref: в українській мові \chapterautorefname дає
% «розділ», але в книзі прийнято не додавати слово «розділ» перед
% номером — тому встановлюємо порожній рядок.
\addto\extrasukrainian{%
  \renewcommand{\chapterautorefname}{}%
}
% --------------------------------------------------------------------------------

% Якщо визначено \inlinetitle (назва без \\), встановити її як
% PDF-title у метаданих. Інакше використовується \@title з \\,
% що може некоректно відображатися у PDF-переглядачах.
\ifdefined\inlinetitle%
  \AtBeginDocument{\hypersetup{pdftitle={\inlinetitle}}}
\fi

%===============================================================================
%
%                           Налаштування бібліографії
%
%===============================================================================

% Умовне розгалуження: biblatex або стандартний bibtex.
\ifbiblatex
  % biblatex з biber:
  %   bibstyle=gost-numeric — стиль ДСТУ ГОСТ 7.1 (числові посилання)
  %   autolang=other        — мова визначається з поля langid запису
  %   isbn=true             — показувати ISBN
  %   url=false             — не показувати URL (бо є doi)
  %   defernumbers=true     — нумерація після сортування
  \RequirePackage[backend=biber, bibstyle=gost-numeric, autolang=other, isbn=true, url=false, defernumbers=true]{biblatex}
  % string+url: якщо є поле url — назва стає гіперпосиланням.
  \newbibmacro{string+url}[1]{%
    \iffieldundef{url}{#1}{\href{\thefield{url}}{#1}}%
  }
  \DeclareFieldFormat{title}{\usebibmacro{string+url}{#1}}
  % csquotes: коректні лапки для кожної мови (потрібен для biblatex).
  \RequirePackage{csquotes}
  % Перейменування стандартної назви «Bibliography» на «Література».
  \DefineBibliographyStrings{ukrainian}{%
    bibliography = {Література},
  }
  % Категорії бібліографії для розділення списку літератури на підрозділи:
  %   Textbooks — підручники
  %   Problems  — збірники задач
  \DeclareBibliographyCategory{Textbooks}
  \DeclareBibliographyCategory{Problems}
\else
  % Стандартний bibtex: мітка у форматі «1.» (крапка, а не дужки).
  \renewcommand{\@biblabel}[1]{#1.}
  % Перейменування заголовка бібліографії на «Література».
  \addto\captionsukrainian{%
    \renewcommand{\bibname}{Література}%
  }
\fi

%===============================================================================
%
%                       Верстка теоретичних відомостей
%
%===============================================================================

% Theory: tcolorbox для блоків «Теоретичні відомості».
%   auto counter    — автоматична нумерація блоків
%   breakable       — блок може розриватися між сторінками
%   enhanced        — режим з розширеними можливостями рамок
%   outer arc=0pt   — прямі зовнішні кути
%   arc=0pt         — прямі внутрішні кути
%   colframe        — колір рамки: themecolordark (темно-синій)
%   colback=white   — білий фон (перевизначає попереднє colback)
%   attach boxed title to top left — заголовок у блоці зліва вгорі
%   fontupper=\small — текст у блоці меншим шрифтом
%   before upper={\parindent15pt} — відступ першого рядка 15pt
%   rightrule=0pt   — права рамка відсутня (лише три сторони)
%   before=\nopagebreak — не розривати перед блоком
%   title=«Теоретичні відомості»
%   overlay: якщо є необов'язковий аргумент #1 — виводить його як
%            підзаголовок праворуч від заголовного блоку.
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

% pict: мінімалістичний tcolorbox для рисунків у задачах —
% білий фон, тонка сіра рамка, нульові відступи, горизонтальне
% вирівнювання по центру, тінь (drop fuzzy shadow), hbox (розмір
% за вмістом).
\newtcolorbox{pict}{
  colback=white,
  colframe=gray,
  boxrule=0.1pt,
  left=0pt,
  right=0pt,
  top=0pt,
  bottom=0pt,
  sharp corners,
  halign=center,
  enhanced,drop fuzzy shadow,
  hbox,
}

% Attention: tcolorbox для блоків «Увага!» / «Зверніть увагу».
%   Жовтий фон, скруглений правий нижній кут (southeast), темно-синя
%   ліва смуга з білим «!». Ефект «загнутого кута» досягається через
%   TikZ underlay: трикутник у правому нижньому куті.
%   drop fuzzy shadow — м'яка тінь під блоком.
\newtcolorbox{Attention}[1][]{enhanced,
  breakable,
  before skip=2mm,after skip=3mm,
  before upper={\parindent15pt},
  boxrule=0.4pt,left=5mm,right=2mm,top=1mm,bottom=1mm,
  colback=yellow!10,
  colframe=yellow!50,
  fontupper=\itshape,
  sharp corners,rounded corners=southeast,arc is angular,arc=3mm,
  underlay={%
      \path[fill=tcbcolback!80!black] ([yshift=3mm]interior.south east)--++(-0.4,-0.1)--++(0.1,-0.2);
      \path[draw=tcbcolframe,shorten <=-0.05mm,shorten >=-0.05mm] ([yshift=3mm]interior.south east)--++(-0.4,-0.1)--++(0.1,-0.2);
      \path[fill=themecolordark,draw=none] (interior.south west) rectangle node[text=white]{\Large\bfseries !} ([xshift=4mm]interior.north west);
    },
  drop fuzzy shadow,#1}


% Закоментований варіант postulate (з підкресленим заголовком і
% кружечком на лівій лінії) — замінений на поточну версію нижче.
%\newtcolorbox{postulate}[1]{
%    enhanced,
%    colback=cyan!6!white,
%    ...
%}

% postulate: tcolorbox для постулатів і аксіом.
%   Блакитний фон (cyan!10), без рамки (colframe=white, boxrule=0pt),
%   жирний підкреслений заголовок, жирний курсивний текст.
%   Ліва смуга themecolorlight товщиною 2.5pt.
%   Кружечок на лівій смузі (overlay з filldraw circle 5pt).
\newtcolorbox{postulate}[1]{
  enhanced,
  colback=cyan!10!white,
  colframe=white,
  boxrule=0pt,
  fonttitle=\bfseries\underline,
  fontupper=\bfseries\itshape,
  title=#1,
  left=8pt,
  borderline west={2.5pt}{0pt}{themecolorlight},
  overlay={
      \filldraw[themecolorlight, draw=themecolorlight]
      ([xshift=1.25pt]frame.north west) circle (5pt);
    },
}

% Фрактальна декорація irregular fractal line: перетворює відрізок
% на ламану лінію через випадкову проміжну точку. При багаторазовому
% застосуванні імітує рваний край паперу (аналог Koch snowflake).
\pgfdeclaredecoration{irregular fractal line}{init}
{
  \state{init}[width=\pgfdecoratedinputsegmentremainingdistance]
  {
    \pgfpathlineto{%
      \pgfpoint{random * \pgfdecoratedinputsegmentremainingdistance}{%
        (random * \pgfdecorationsegmentamplitude - 0.02) *
        \pgfdecoratedinputsegmentremainingdistance}}
    \pgfpathlineto{\pgfpoint{\pgfdecoratedinputsegmentremainingdistance}{0pt}}
  }
}

% Стилі для tornpage:
%   paper: заливка текстурою старого паперу (зображення OLD_PAPER_TEXTURE)
%          з тонкою сірою рамкою.
%   irregular border: застосовує фрактальну декорацію для рваного краю.
%   ragged border: випадкові зламані кроки для менш регулярного краю.
\tikzset{
  paper/.style={%
      draw=black!10,
      %    blur shadow,
      path picture={%
          \node at (path picture bounding box.center) {
            \includegraphics[width=\linewidth]{./Icons/OLD_PAPER_TEXTURE}
          };
        }
    },
  irregular border/.style={%
      decoration={irregular fractal line, amplitude=0.2},
      decorate,
    },
  ragged border/.style={%
      decoration={random steps, segment length=7mm, amplitude=2mm},
      decorate,
    }
}

% tornpage: tcolorbox для блоків у вигляді «рваного аркуша паперу».
%   empty — мінімальний движок (уникає артефактів на деяких PDF-
%           переглядачах, які виникали з enhanced jigsaw).
%   interior code: у фоновому шарі малює форму паперу з рваним
%                  нижнім краєм (4 рівні рекурсивних декорацій).
%   fonttitle=\sffamily\bfseries\LARGE — великий sans-serif заголовок.
%   attach boxed title to top center — заголовок по центру зверху.
\newtcolorbox{tornpage}[1][]{%
  % enhanced jigsaw, <-- Beware, This rendering engine let the
  %                      frame appear on some PDF viewers
  empty, % Better use this rendering engine to avoid the bug
  parbox=true,
  interior code={%
      \begin{pgfonlayer}{background}  % Draw the shape behind
        \fill[paper] % recursively decorate the bottom border
        decorate[irregular border]{%
            decorate{decorate{decorate{decorate[ragged border]{
                            ($(interior.south east) - (0, random * 5mm)$) --
                            ($(interior.south west) - (0, random * 5mm)$)
                          }
                      }
                  }
              }
          }
        -- (interior.north west) -- (interior.north east) -- cycle;
      \end{pgfonlayer}
    },
  sharp corners,
  boxrule=0pt,
  left=5pt,
  right=5pt,
  top=5pt,
  bottom=1em,
  fonttitle=\sffamily\bfseries\LARGE,
  attach boxed title to top center={yshift*=-\tcboxedtitleheight},
  coltitle=black,
  #1
}


%===============================================================================
%
%                               Верстка задач
%
%===============================================================================
% ntheorem: розширена підтримка теорем і теоремоподібних оточень
% (задачі, визначення, леми).
\RequirePackage{ntheorem}
% answers: генерація розділу відповідей — зіставляє задачі з їх
% розв'язками і виводить їх окремо.
\RequirePackage{answers}
% xassoccnt: пов'язані лічильники (для підрахунку загальної кількості
% задач по всьому документу).
\RequirePackage{xassoccnt}
% totalproblems: глобальний лічильник усіх задач у книзі.
\NewTotalDocumentCounter{totalproblems}

% problemstyle: власний стиль ntheorem для оточення problem.
%   Дві форми: без заголовка і з заголовком (##3 — необов'язковий аргумент).
%   Функціонал:
%     - \hypertarget{problem:\@roman{##2}}{} — якір для гіперпосилання
%       «задача → розв'язок»
%     - \ifcsname r@solution\@roman{##2}\endcsname — перевірка: чи існує
%       мітка розв'язку для цієї задачі?
%     - Якщо є розв'язок: номер задачі — клікабельне посилання на нього
%       (\hyperlink{solution:...})
%     - Якщо немає розв'язку: просто жирний номер
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
    \item[\theorem@headerfont\hyperlink{solution:\@roman{##2}}{##2\theorem@separator}] (##3)
  \else
    \item[\theorem@headerfont##2\theorem@separator] (##3)
  \fi
}

% Активація стилю problemstyle та налаштування шрифтів:
%   theoremheaderfont — жирний шрифт із відступом 1ex зліва
%   theorembodyfont   — звичайний шрифт (не курсив як за замовчуванням)
%   theoremseparator  — крапка після номера задачі
\theoremstyle{problemstyle}
\theoremheaderfont{\hspace{1ex}\bfseries}
\theorembodyfont{\normalfont}
\theoremseparator{.}

% Оточення problem: нумерація задач per chapter (1.1, 1.2, 2.1...).
\newtheorem{problem}{}[chapter]
% Пов'язати лічильник problem з totalproblems для підрахунку всіх задач.
\DeclareAssociatedCounters{problem}{totalproblems}

% Закоментований попередній стиль answersolutionstyle з прямокутною
% рамкою навколо розв'язку (три варіанти: нерозірваний, перший, останній
% фрагмент). Замінений на поточний мінімалістичний стиль з лівою лінією.
%\tcbset{
%    answersolutionstyle/.style={
%        ...
%    },
%}

% answersolutionstyle: стиль tcolorbox для оточень задач і розв'язків.
%   enhanced jigsaw    — движок рендерингу
%   colback=yellow!4   — майже білий фон з жовтим відтінком
%   frame hidden       — рамка прихована (лише ліва лінія через overlay)
%   breakable          — розрив між сторінками
%   overlay unbroken/first/last: вертикальна лінія themecolorlight
%     товщиною 2.5pt уздовж лівого краю блоку — для всіх трьох
%     станів розривного блоку (цілий, перший, останній фрагмент).
\tcbset{
  answersolutionstyle/.style={
      enhanced jigsaw,
      colback=yellow!4!white,
      colframe=themecolorlight,
      boxrule=0pt,
      frame hidden,
      breakable,
      before skip=10pt,
      after skip=10pt,
      overlay unbroken = {
          \draw[line width=2.5pt, themecolorlight, line cap=round]
          (frame.south west) -- (frame.north west);
        },
      extras first={
          overlay={
              \draw[line width=2.5pt, themecolorlight, line cap=round]
              (frame.south west) -- (frame.north west);
            },
        },
      extras last={
          overlay={
              \draw[line width=2.5pt, themecolorlight, line cap=round]
              (frame.south west) -- (frame.north west);
            },
        },
    },
}

% Застосувати answersolutionstyle до оточення problem автоматично
% (tcolorboxenvironment огортає існуюче оточення у tcolorbox).
\tcolorboxenvironment{problem}{answersolutionstyle}


%===============================================================================
%
%                       Генерування відповідей до задач
%
%===============================================================================

% answerbox: tcolorbox для одного розв'язку у розділі «Відповіді»
% (той самий стиль answersolutionstyle + вирівнювання по лівому краю).
\newtcolorbox{answerbox}{answersolutionstyle,halign=left}

% Асоціація оточень: solution (у тексті задач) → Solution (у файлі answer).
%   Newassociation з пакету answers: записує вміст solution у файл .ans,
%   який потім вставляється командою \Writefile у розділі «Відповіді».
\Newassociation{solution}{Solution}{answer}
% Перевизначення оточення Solution для відображення у розділі відповідей:
%   - answerbox (жовтуватий фон, ліва лінія)
%   - Заголовок: номер задачі — клікабельне посилання назад на задачу
%     (\hypertarget для якоря solution:..., \hyperlink для посилання
%     на problem:...)
\renewenvironment{Solution}[1]{%
  \begin{answerbox}
  \hypertarget{solution:\@roman{#1}}{\hyperlink{problem:\@roman{#1}}{\bfseries#1.}\label{solution\@roman{#1}}}
}{%
  \end{answerbox}
}


%===============================================================================
%
%                   Команда вставки задач та відповідей
%
%   https://tex.stackexchange.com/questions/382776/how-to-create-list-and-assign-it-to-variable
%===============================================================================
\ExplSyntaxOn
% Закоментований альтернативний варіант \multiinclude з іменованим списком
% (MakeChapterList + multiinclude з ім'ям списку) — не використовується.
%\NewDocumentCommand{\multiinclude}{ m O{} }
% {
%  \clist_map_inline:cn {chapter_list_#1_clist} { \InputIfFileExists{##1/##1#2}{}{}\par}
% }
%\NewDocumentCommand{\MakeChapterList}{ m m }
% {
%  \clist_set:cn {chapter_list_#1_clist} { #2 }
% }
% --------------------------------------------------------------------------------
% \multiinclude{список}{суфікс}: вставляє файли розділів із comma-list.
%   #1 — список імен файлів через кому (наприклад: Basics, Solutions, ...)
%   #2 — необов'язковий суфікс (за замовчуванням порожній).
%   Для кожного імені ##1 у списку виконує:
%     \InputIfFileExists{##1/##1#2}{}{}\par
%   Тобто вставляє файл «ім'я/ім'я.tex» (або «ім'я/ім'я_суфікс.tex»),
%   якщо він існує, і додає \par після кожного розділу.
%   Структура каталогів книги: кожен розділ у власній папці з тим
%   самим ім'ям (Basics/Basics.tex, Solutions/Solutions.tex тощо).
\NewDocumentCommand{\multiinclude}{ m O{} }
{
  \clist_set:Nx \l_Chapters_clist{ #1 }
  \clist_map_inline:Nn \l_Chapters_clist { \InputIfFileExists{##1/##1#2}{}{}\par}
}

\ExplSyntaxOff
%===============================================================================

\endinput