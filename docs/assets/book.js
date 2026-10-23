/* book.js — необов'язкове покращення для HTML-версії книги.
   Без нього conspect.css працює повністю; зі скриптом додається:
   • бічний зміст розгортає лише поточний розділ (і підсвічує поточний параграф);
   • шухляда змісту на телефонах;
   • перемикач світлої/темної теми (запам'ятовується);
   • кнопки «попередній / наступний розділ» унизу сторінки;
   • пошук по тексту розділів (Pagefind: індекс pagefind/ будує build-html.ps1; потрібен вебсервер, не file://). */
(function () {
  'use strict';
  var root = document.documentElement;
  var KEY = 'elmag-book-theme';
  /* тека сайту (book.js лежить у assets/): там і pagefind/ */
  var SITE = ((document.currentScript && document.currentScript.src) || '').replace(/assets\/book\.js(\?.*)?$/, '');

  /* ── Тема ── */
  function setTheme(t) {
    root.classList.toggle('dark', t === 'dark');
    var b = document.querySelector('.theme-btn');
    if (b) { b.textContent = isDark() ? 'Світла тема' : 'Темна тема'; }
  }
  function isDark() { return root.classList.contains('dark'); }
  try { var saved = localStorage.getItem(KEY); if (saved) { setTheme(saved); } } catch (e) {}

  function init() {
    var title = document.querySelector('.sidetoctitle');
    var actions = null;
    if (title) {
      var tb = document.createElement('button');
      tb.type = 'button'; tb.className = 'theme-btn';
      tb.addEventListener('click', function () {
        var next = isDark() ? 'light' : 'dark';
        setTheme(next);
        try { localStorage.setItem(KEY, next); } catch (e) {}
      });
      actions = document.createElement('div'); actions.className = 'sidetoc-actions';
      actions.appendChild(tb);
      title.appendChild(actions);
      tb.textContent = isDark() ? 'Світла тема' : 'Темна тема';
    }

    var box = document.querySelector('.sidetoccontents');
    if (!box) { return; }
    initSearch(box);

    /* ── Групи «розділ → параграфи» ── */
    var here = (location.pathname.split('/').pop() || '').toLowerCase();
    var groups = [], cur = null;
    box.querySelectorAll('p').forEach(function (p) {
      var a = p.querySelector('a'); if (!a) { return; }
      if (a.classList.contains('tocchapter')) {
        cur = { head: p, link: a, items: [], file: (a.getAttribute('href') || '').split('#')[0].toLowerCase() };
        groups.push(cur);
      } else if (a.classList.contains('tocsection') && cur) {
        cur.items.push(p);
      }
    });

    /* На головній сторінці книги «Передмова» та «Вибір системи одиниць» теж ведуть на цей файл —
       але поточним розділом вона не є: підсвічуємо лише посилання «Головна» */
    var homeLink = box.querySelector('a.linkhome');
    var homeFile = homeLink ? (homeLink.getAttribute('href') || '').split('#')[0].toLowerCase() : '';
    var onHome = !!homeFile && homeFile === here;
    if (onHome) { homeLink.classList.add('is-current'); }

    var openAll = false;
    var current = onHome ? undefined : groups.filter(function (g) { return g.file === here; })[0];
    function render() {
      groups.forEach(function (g) {
        var show = openAll || g === current;
        g.items.forEach(function (p) { p.classList.toggle('toc-collapsed', !show); });
      });
    }
    if (current) { current.link.classList.add('is-current'); }
    render();

    var all = document.createElement('button');
    all.type = 'button'; all.className = actions ? 'theme-btn' : 'toc-all'; all.textContent = 'Усі параграфи';
    all.addEventListener('click', function () {
      openAll = !openAll;
      all.textContent = openAll ? 'Лише поточний' : 'Усі параграфи';
      all.title = openAll ? 'Показати параграфи лише поточного розділу' : 'Показати параграфи всіх розділів';
      render();
    });
    all.title = 'Показати параграфи всіх розділів';
    (actions || box).appendChild(all);   /* поруч із кнопкою теми, угорі панелі */
    if (current) { /* прокручуємо лише сам зміст, а не сторінку */
      var br = box.getBoundingClientRect(), lr = current.link.getBoundingClientRect();
      box.scrollTop += lr.top - br.top - box.clientHeight / 3;
    }

    /* ── Підсвічування поточного параграфа ── */
    var links = {};
    box.querySelectorAll('a[href*="#"]').forEach(function (a) {
      var h = a.getAttribute('href'), f = h.split('#')[0].toLowerCase();
      if (f === here) { links[h.split('#')[1]] = a; }
    });
    var heads = Array.prototype.slice.call(document.querySelectorAll('h3[id],h4[id]'))
      .filter(function (h) { return links[h.id]; });
    if ('IntersectionObserver' in window && heads.length) {
      var active = null;
      var io = new IntersectionObserver(function (es) {
        es.forEach(function (e) {
          if (e.isIntersecting) {
            if (active) { active.classList.remove('is-active'); }
            active = links[e.target.id]; active.classList.add('is-active');
          }
        });
      }, { rootMargin: '0px 0px -75% 0px' });
      heads.forEach(function (h) { io.observe(h); });
    }

    /* ── Попередній / наступний розділ ── */
    var bot = document.querySelector('.botnavigation');
    var idx = groups.indexOf(current);
    if (bot && idx >= 0) {
      function nav(g, cls, label) {
        var a = document.createElement('a');
        a.href = g.link.getAttribute('href'); a.className = cls;
        a.innerHTML = '<small>' + label + '</small>' + g.link.textContent.replace(/\s+/g, ' ').trim();
        return a;
      }
      var home = bot.querySelector('.linkhome');
      bot.textContent = '';
      if (groups[idx - 1]) { bot.appendChild(nav(groups[idx - 1], 'nav-prev', 'Попередній розділ')); }
      if (home) { bot.appendChild(home); }
      if (groups[idx + 1]) { bot.appendChild(nav(groups[idx + 1], 'nav-next', 'Наступний розділ')); }
    }

    /* ── Шухляда на вузьких екранах ── */
    var top = document.querySelector('.topnavigation');
    if (top) {
      var fab = document.createElement('button');
      fab.type = 'button'; fab.className = 'toc-fab'; fab.setAttribute('aria-label', 'Пошук і зміст');
      fab.innerHTML = '<svg width="14" height="14" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" aria-hidden="true" style="vertical-align:-2px;margin-right:.4em"><circle cx="8.5" cy="8.5" r="6"/><path d="M13 13l5 5"/></svg>Пошук і зміст';
      fab.addEventListener('click', function () { root.classList.toggle('toc-open'); });
      top.appendChild(fab);
      box.addEventListener('click', function (e) { if (e.target.closest('a')) { root.classList.remove('toc-open'); } });
      document.body.addEventListener('click', function (e) {
        if (root.classList.contains('toc-open') && !e.target.closest('.sidetoccontainer, .toc-fab')) {
          root.classList.remove('toc-open');
        }
      });
    }
  }

  /* ── Пошук: поле над змістом; поки є запит, результати заступають зміст (conspect.css, #search) ── */
  function initSearch(box) {
    if (!SITE || location.protocol === 'file:') { return; }      /* Pagefind читає індекс через fetch */
    var sb = document.createElement('div');
    sb.id = 'search';
    box.parentNode.insertBefore(sb, box);
    var css = document.createElement('link');
    css.rel = 'stylesheet'; css.href = SITE + 'pagefind/pagefind-ui.css';
    document.head.appendChild(css);
    var js = document.createElement('script');
    js.src = SITE + 'pagefind/pagefind-ui.js';
    js.onerror = function () { sb.remove(); css.remove(); };    /* індексу немає (збірка без node) */
    js.onload = function () {
      var norm = function (x) { return (x || '').replace(/\s+/g, ' ').trim(); };
      new window.PagefindUI({
        element: '#search', showSubResults: true, showImages: false, resetFilters: false,
        baseUrl: new URL(SITE).pathname,                          /* сайт може лежати не в корені домену */
        processResult: function (r) {
          var t = norm(r.meta && r.meta.title);
          r.excerpt = texFix(r.excerpt);
          (r.sub_results || []).forEach(function (s) {
            s.excerpt = texFix(s.excerpt);
            if (norm(s.title) === t) { s.title = 'Початок розділу'; }  /* текст до першого параграфа */
          });
          return r;
        },
        translations: {
          placeholder: 'Пошук у книзі', clear_search: 'Очистити', load_more: 'Показати ще',
          search_label: 'Пошук у книзі', zero_results: 'Нічого не знайдено: «[SEARCH_TERM]»',
          many_results: 'Знайдено: [COUNT] — «[SEARCH_TERM]»', one_result: 'Знайдено: 1 — «[SEARCH_TERM]»',
          alt_search: 'Нічого не знайдено: «[SEARCH_TERM]». Результати для «[DIFFERENT_TERM]»',
          search_suggestion: 'Нічого не знайдено: «[SEARCH_TERM]». Спробуйте інший запит:',
          searching: 'Шукаю «[SEARCH_TERM]»…'
        }
      });
      typesetResults(sb);
    };
    document.head.appendChild(js);
    /* на телефоні перехід до результату закриває шухляду */
    sb.addEventListener('click', function (e) { if (e.target.closest('a')) { root.classList.remove('toc-open'); } });
  }

  /* Уривок обрізано посеред формули: прибираємо «висячі» \( \) і \begin{..} \end{..} з країв, щоб решту зверстав MathJax */
  function texFix(html) {
    if (!html) { return html; }
    var o = html.indexOf('\\('), c = html.indexOf('\\)');
    if (c >= 0 && (o < 0 || c < o)) { html = '…' + html.slice(c + 2); }
    o = html.lastIndexOf('\\('); c = html.lastIndexOf('\\)');
    if (o > c) { html = html.slice(0, o) + '…'; }
    var b = html.lastIndexOf('\\begin{'), e = html.lastIndexOf('\\end{');
    if (b > e) { html = html.slice(0, b) + '…'; }
    var e0 = html.indexOf('\\end{'), b0 = html.indexOf('\\begin{');
    if (e0 >= 0 && (b0 < 0 || e0 < b0)) { html = '…' + html.slice(html.indexOf('}', e0) + 1); }
    return html;
  }

  /* Формули в результатах: після кожного оновлення списку — MathJax (свої зміни MathJax не рахуються) */
  function typesetResults(sb) {
    var timer = null, running = false, again = false;
    function schedule() { if (timer) { clearTimeout(timer); } timer = setTimeout(run, 120); }
    function run() {
      timer = null;
      if (running) { again = true; return; }
      if (!window.MathJax || !MathJax.typesetPromise) { timer = setTimeout(run, 400); return; }
      running = true;
      var p;
      try { if (MathJax.typesetClear) { MathJax.typesetClear([sb]); } p = MathJax.typesetPromise([sb]); }
      catch (e) { running = false; return; }
      p.catch(function () {}).then(function () { running = false; if (again) { again = false; schedule(); } });
    }
    new MutationObserver(function (ms) {
      /* кнопка «Очистити» — лише хрестик (conspect.css), підпис стає підказкою */
      var cl = sb.querySelector('.pagefind-ui__search-clear');
      if (cl && !cl.title) { cl.title = (cl.textContent || '').trim(); }
      for (var i = 0; i < ms.length; i++) {
        var t = ms[i].target;
        if (t.nodeType === 1 && t.closest && t.closest('mjx-container')) { continue; }
        schedule(); return;
      }
    }).observe(sb, { childList: true, subtree: true });
  }

  if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', init); } else { init(); }
})();

/* ── Збільшення рисунків за кліком (для слабкозорих) ──
   У тексті рисунок обмежений за висотою (conspect.css); клік відкриває його на весь екран, повторний клік —
   у натуральному розмірі (з прокруткою). Esc, ×, клік поза рисунком — закрити. Ctrl/Shift/середня кнопка — як було
   (відкрити файл у новій вкладці). */
(function () {
  'use strict';
  var SEL = 'figure a[href] > img.inlineimage';
  var box = null, big = null, lastFocus = null;

  function close() {
    if (!box) { return; }
    document.documentElement.classList.remove('lightbox-open');
    box.remove(); box = big = null;
    if (lastFocus && lastFocus.focus) { lastFocus.focus(); }
  }
  function open(a, img) {
    lastFocus = a;
    box = document.createElement('div');
    box.className = 'lightbox'; box.setAttribute('role', 'dialog'); box.setAttribute('aria-modal', 'true');
    box.setAttribute('aria-label', 'Збільшений рисунок');
    var x = document.createElement('button');
    x.type = 'button'; x.className = 'lightbox-close'; x.textContent = '×'; x.setAttribute('aria-label', 'Закрити');
    big = document.createElement('img');
    big.src = a.getAttribute('href'); big.alt = img.alt || '';
    big.title = 'Клік — натуральний розмір / вписати';
    box.appendChild(x); box.appendChild(big);
    box.addEventListener('click', function (e) {
      if (e.target === big) { box.classList.toggle('zoomed'); return; }
      close();
    });
    document.documentElement.classList.add('lightbox-open');
    document.body.appendChild(box);
    x.focus();
  }

  document.addEventListener('click', function (e) {
    if (e.defaultPrevented || e.button !== 0 || e.ctrlKey || e.metaKey || e.shiftKey || e.altKey) { return; }
    var img = e.target.closest && e.target.closest(SEL);
    if (!img) { return; }
    var a = img.parentNode;
    if (!/\.(jpe?g|png|gif|webp|svg|avif)(\?.*)?$/i.test(a.getAttribute('href') || '')) { return; }
    e.preventDefault();
    open(a, img);
  });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') { close(); } });
  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll(SEL).forEach(function (img) {
      img.parentNode.title = 'Клік — збільшити';
    });
  });
})();

/* ── Перенесення довгих формул ──
   MathJax 3 не переносить виключені формули: ширша за колонку формула отримує смугу прокрутки (conspect.css).
   Тут така формула ділиться на рядки на верхньому рівні TeX — спершу між частинами (\quad, стрілки ⟺ ⇒),
   потім перед знаками відношень (=, <, ≈ …), нарешті перед + і − — і перемальовується як aligned
   (номер формули і рамка \tcbhighmath зберігаються). Зі зміною ширини вікна розбиття перераховується;
   формула, що знову вміщується, повертається до оригіналу. Що не вдалося розбити — лишається зі смугою прокрутки. */
(function () {
  'use strict';
  var ARROW = /^\\(Longleftrightarrow|Leftrightarrow|Longrightarrow|Rightarrow|Longleftarrow|Leftarrow|iff|implies|impliedby)$/;
  var REL = /^\\(le|leq|ge|geq|leqslant|geqslant|ne|neq|approx|equiv|sim|simeq|cong|propto|ll|gg|to|rightarrow|mapsto|doteq)$/;
  var BIN = /^\\(pm|mp)$/;
  var SPACE = /^(\\(quad|qquad|[,;:! ])|~)$/;
  var OPEN = /^\\(cdot|times|left|middle)$/;           /* після них + і − унарні */
  var TRIM_L = /^(\s|\\quad|\\qquad|\\[,;:! ]|~)+/, TRIM_R = /(\s|\\quad|\\qquad|\\[,;:! ]|~)+$/;

  /* індекс після групи {..}, що починається з tex[k] === '{' (або -1) */
  function group(tex, k) {
    for (var d = 0, i = k; i < tex.length; i++) {
      var c = tex[i];
      if (c === '\\') { i++; continue; }
      if (c === '{') { d++; } else if (c === '}' && --d === 0) { return i + 1; }
    }
    return -1;
  }
  /* прибрати \cmd{..} (\label, \tag) */
  function strip(tex, re) {
    var m;
    while ((m = re.exec(tex))) {
      var e = group(tex, m.index + m[0].length - 1);
      if (e < 0) { break; }
      tex = tex.slice(0, m.index) + tex.slice(e);
    }
    return tex;
  }

  /* TeX формули -> частини [{tier, text}]: tier 1 — між частинами (\quad, стрілка), 2 — відношення, 3 — + і −.
     null — формула вже багаторядкова (& чи \\ на верхньому рівні). */
  function split(tex) {
    var cuts = [], depth = 0, prevOp = true, gap = -1, gapQuad = false, delim = false;
    function cut(pos, tier) {
      var last = cuts[cuts.length - 1];
      if (last && last.pos === pos) { last.tier = Math.min(last.tier, tier); } else { cuts.push({ pos: pos, tier: tier }); }
    }
    for (var i = 0; i < tex.length;) {
      var c = tex[i], tok = c;
      if (c === '\\') { tok = /^\\([a-zA-Z]+|[\s\S])/.exec(tex.slice(i))[0]; }
      var j = i + tok.length;
      if (/\s/.test(c)) { i = j; continue; }
      if (delim) { delim = false; i = j; continue; }      /* роздільник після \left / \right */
      var top = depth === 0;
      if (top && SPACE.test(tok)) {
        if (gap < 0) { gap = i; gapQuad = false; }
        if (/quad/.test(tok)) { gapQuad = true; }
        i = j; continue;
      }
      if (top && gap > 0 && gapQuad) { cut(gap, 1); prevOp = true; }
      var at = gap >= 0 ? gap : i;
      gap = -1;
      if (tok === '\\\\' || tok === '&') { if (top) { return null; } }
      else if (tok === '{' || tok === '(' || tok === '[' || tok === '\\begin') { depth++; prevOp = true; }
      else if (tok === '}' || tok === ')' || tok === ']' || tok === '\\end') { depth--; prevOp = false; }
      else if (tok === '|' || tok === '\\|' || tok === '\\vert' || tok === '\\Vert') {   /* |..|: відкривна стоїть там, де чекаємо операнд */
        if (prevOp) { depth++; } else if (depth > 0) { depth--; }
        prevOp = false;
      }
      else if (tok === '\\left') { depth++; delim = true; prevOp = true; }
      else if (tok === '\\right') { depth--; delim = true; prevOp = false; }
      else if (ARROW.test(tok)) { if (top && i > 0) { cut(at, 1); } prevOp = true; }
      else if (tok === '=' || tok === '<' || tok === '>' || REL.test(tok)) { if (top && !prevOp) { cut(i, 2); } prevOp = true; }
      else if (tok === '+' || tok === '-' || BIN.test(tok)) { if (top && !prevOp) { cut(i, 3); } prevOp = true; }
      else { prevOp = tok === ',' || tok === ';' || tok === '^' || tok === '_' || OPEN.test(tok); }
      i = j;
    }
    /* text — частина без проміжків по краях (початок рядка), raw — з проміжком перед нею (продовження рядка) */
    var parts = [], from = 0, tier = 0;
    cuts.concat({ pos: tex.length }).forEach(function (k) {
      var raw = tex.slice(from, k.pos).replace(TRIM_R, ''), t = raw.replace(TRIM_L, '');
      if (t) { parts.push({ tier: tier, text: t, raw: raw }); }
      from = k.pos; tier = k.tier;
    });
    return parts;
  }

  /* ширина TeX (рядкова формула) в ex */
  function width(tex, m) {
    var svg = MathJax.tex2svg(tex, { display: false, em: m.em, ex: m.ex }).querySelector('svg');
    return svg ? parseFloat(svg.getAttribute('width')) || 0 : 0;
  }
  /* природна ширина зверстаної виключеної формули в ex (з номером ширина — у min-width) */
  function natural(c) {
    var svg = c.querySelector('svg');
    if (!svg) { return 0; }
    var w = svg.getAttribute('width') || '';
    if (/ex$/.test(w)) { return parseFloat(w); }
    var mw = /min-width:\s*([\d.]+)ex/.exec(svg.getAttribute('style') || '');
    return mw ? parseFloat(mw[1]) : 0;
  }
  /* ширина колонки в px: у формули з номером MathJax ставить min-width на сам контейнер, тож міряємо батька */
  function avail(c) {
    var p = c.parentElement, cs = p && getComputedStyle(p);
    return p ? p.clientWidth - parseFloat(cs.paddingLeft) - parseFloat(cs.paddingRight) : 0;
  }
  function exPx(c) {
    var p = document.createElement('span');
    p.style.cssText = 'position:absolute;visibility:hidden;width:100ex;height:0';
    c.appendChild(p);
    var r = p.getBoundingClientRect().width / 100;
    p.remove();
    return r || 8;
  }

  function prepare(item) {
    var tex = item.math.trim(), env = /^\\begin\{(equation|displaymath)(\*?)\}([\s\S]*)\\end\{\1\*?\}$/.exec(tex);
    if (!env && /^\\begin\{/.test(tex)) { return null; }       /* align, gather, multline …: рядки вже задано */
    var body = strip(strip(env ? env[3] : tex, /\\label\s*\{/g), /\\tag\*?\s*\{/g).trim();
    var box = false, bm = /^\\tcbhighmath\s*\{/.exec(body);
    if (bm && group(body, bm[0].length - 1) === body.length) { box = true; body = body.slice(bm[0].length, -1).trim(); }
    var parts = split(body);
    if (!parts || parts.length < 2) { return null; }
    var tag = '';
    try {
      var lt = /<mlabeledtr[^>]*>\s*<mtd[^>]*>([\s\S]*?)<\/mtd>/.exec(MathJax.startup.toMML(item.root));
      if (lt) { tag = lt[1].replace(/<[^>]+>/g, '').replace(/\s+/g, ''); }
    } catch (e) {}
    var m = item.metrics;
    parts.forEach(function (p) {
      p.w = width('{}' + p.text, m);
      p.wj = p.raw === p.text ? p.w : width('{}' + p.raw, m);
    });
    return {
      item: item, orig: item.typesetRoot, cur: item.typesetRoot, natural: natural(item.typesetRoot),
      parts: parts, box: box, tag: tag, tagW: tag ? width('\\text{' + tag + '}', m) + 2 : 0,
      indent: 2 * m.em / m.ex, key: ''
    };
  }

  /* рядки для ширини W (ex): розриви найнижчого рівня, з якими все вміщується */
  function layout(rec, W) {
    var best = null;
    for (var t = 1; t <= 3; t++) {
      /* блоки: частини, між якими на рівні t розривати не можна */
      var units = [];
      rec.parts.forEach(function (p, k) {
        var u = units[units.length - 1];
        if (k > 0 && p.tier > t) { u.text += ' ' + p.raw; u.raw += ' ' + p.raw; u.w += p.wj; u.wj += p.wj; return; }
        units.push({ tier: p.tier, text: p.text, raw: p.raw, w: p.w, wj: p.wj });
      });
      var lines = [], fits = true;
      units.forEach(function (u, k) {
        var cur = lines[lines.length - 1];
        if (cur && cur.w + u.wj <= W) { cur.text += ' ' + u.raw; cur.w += u.wj; return; }
        var ind = k > 0 && u.tier > 1;
        lines.push({ text: u.text, w: u.w + (ind ? rec.indent : 0), ind: ind });
      });
      lines.forEach(function (l) { if (l.w > W) { fits = false; } });
      best = lines;
      if (fits) { break; }
    }
    return best;
  }

  function build(rec, lines) {
    var rows = lines.map(function (l) { return '&' + (l.ind ? '\\qquad' : '') + '{}' + l.text; });
    var tex = '\\begin{aligned}' + rows.join('\\\\') + '\\end{aligned}';
    if (rec.box) { tex = '\\tcbhighmath{' + tex + '}'; }
    if (rec.tag) { tex += '\\tag*{' + rec.tag + '}'; }
    return tex;
  }

  function show(rec, node) {
    if (rec.cur !== node) { rec.cur.replaceWith(node); rec.cur = node; }
  }

  function fit(rec) {
    var aw = avail(rec.cur);
    if (aw <= 0) { return; }                                  /* сховано (згорнутий блок тощо) */
    var ex = exPx(rec.cur);
    if (rec.natural * ex <= aw) { show(rec, rec.orig); rec.key = ''; return; }
    var W = aw / ex - 1 - rec.tagW - (rec.box ? 2 : 0);
    var lines = layout(rec, W);
    if (lines.length < 2) { show(rec, rec.orig); rec.key = ''; return; }
    var key = lines.map(function (l) { return l.text; }).join('\n');
    if (key === rec.key) { return; }
    var m = rec.item.metrics;
    var node = MathJax.tex2svg(build(rec, lines), { display: true, em: m.em, ex: m.ex, containerWidth: aw });
    if (node.querySelector('[data-mjx-error]')) { return; }  /* помилка TeX: лишаємо оригінал */
    rec.key = key;
    show(rec, node);
  }

  var recs = [], seen = typeof WeakSet === 'function' ? new WeakSet() : null;
  function pass() {
    Array.from(MathJax.startup.document.math).forEach(function (item) {
      var c = item.typesetRoot;
      if (!item.display || !c || seen.has(item) || !document.contains(c) || c.closest('#search')) { return; }
      if (natural(c) * exPx(c) <= avail(c)) { return; }   /* вміщується — перевіримо при наступній зміні ширини */
      seen.add(item);
      try { var rec = prepare(item); if (rec) { recs.push(rec); } } catch (e) {}
    });
    recs.forEach(function (rec) { try { fit(rec); } catch (e) {} });
  }

  function start() {
    var MJ = window.MathJax;
    if (!seen || !MJ || !MJ.startup || !MJ.startup.promise) { if (seen) { setTimeout(start, 300); } return; }
    MJ.startup.promise.then(function () {
      if (!MathJax.tex2svg) { return; }
      pass();
      var timer = null, lastW = window.innerWidth;
      window.addEventListener('resize', function () {
        if (window.innerWidth === lastW) { return; }
        lastW = window.innerWidth;
        clearTimeout(timer); timer = setTimeout(pass, 200);
      });
    });
  }
  if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', start); } else { start(); }
})();
