/* book.js — необов'язкове покращення для HTML-версії книги.
   Без нього conspect.css працює повністю; зі скриптом додається:
   • бічний зміст розгортає лише поточний розділ (і підсвічує поточний параграф);
   • шухляда змісту на телефонах;
   • перемикач світлої/темної теми (запам'ятовується);
   • кнопки «попередній / наступний розділ» унизу сторінки. */
(function () {
  'use strict';
  var root = document.documentElement;
  var KEY = 'elmag-book-theme';

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
    if (title) {
      var tb = document.createElement('button');
      tb.type = 'button'; tb.className = 'theme-btn';
      tb.addEventListener('click', function () {
        var next = isDark() ? 'light' : 'dark';
        setTheme(next);
        try { localStorage.setItem(KEY, next); } catch (e) {}
      });
      title.appendChild(tb);
            tb.textContent = isDark() ? 'Світла тема' : 'Темна тема';
    }

    var box = document.querySelector('.sidetoccontents');
    if (!box) { return; }

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
    all.type = 'button'; all.className = 'toc-all'; all.textContent = 'Показати всі параграфи';
    all.addEventListener('click', function () {
      openAll = !openAll;
      all.textContent = openAll ? 'Лише поточний розділ' : 'Показати всі параграфи';
      render();
    });
    box.appendChild(all);
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

  if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', init); } else { init(); }
})();
