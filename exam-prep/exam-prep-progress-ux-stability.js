/* Optional, presentation-only loading gate. It never changes academic state or stores data. */
(() => {
  'use strict';
  if (window.iClubExamPrepProgressUxEnabled !== true) return;
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = 'progress_ux_stability_v1';
  if (internal.progressUxStability?.version === VERSION) return;
  const rootEl = () => document.querySelector('#exam-prep-host-root');
  let observer = null;
  let mode = null;
  let readyTimer = null;
  let deadlineTimer = null;
  let startedAt = 0;
  let lastSessionType = '';
  let suspendedScreen = null;

  function permitted(root) {
    const caps = internal.lastCapabilities;
    return window.iClubExamPrepProgressUxEnabled === true && !!root && !root.hidden &&
      root.getAttribute('aria-hidden') !== 'true' && caps?.coreAccess === true &&
      caps?.killSwitch === false && caps?.rolloutState === 'controlled_beta';
  }
  function language() {
    let value = 'ru';
    try { value = String(window.i18n?.getLang?.() || document.documentElement.lang || 'ru').toLowerCase(); } catch (_) {}
    return value.startsWith('uz') ? 'uz' : value.startsWith('en') ? 'en' : 'ru';
  }
  function label(kind) {
    const text = {
      ru: { dashboard:'Загружаем результаты…', plan:'Готовим цели этой недели…', question:'Готовим задания…' },
      uz: { dashboard:'Natijalar yuklanmoqda…', plan:'Haftalik maqsadlar tayyorlanmoqda…', question:'Topshiriqlar tayyorlanmoqda…' },
      en: { dashboard:'Loading your results…', plan:'Preparing this week’s goals…', question:'Preparing your questions…' }
    };
    return text[language()][kind] || text[language()].question;
  }
  function clear() {
    clearTimeout(readyTimer); clearTimeout(deadlineTimer);
    readyTimer = deadlineTimer = null;
    mode = null;
    const root = rootEl();
    if (!root) return;
    delete root.dataset.epPuxLoading;
    delete root.dataset.epPuxLabel;
    if (root.dataset.epPuxBusy === '1') {
      root.removeAttribute('aria-busy');
      delete root.dataset.epPuxBusy;
    }
  }
  function arm(kind) {
    const root = rootEl();
    if (!permitted(root)) return;
    clearTimeout(readyTimer);
    clearTimeout(deadlineTimer);
    readyTimer = null;
    suspendedScreen = null;
    mode = kind;
    startedAt = Date.now();
    root.dataset.epPuxLoading = kind;
    root.dataset.epPuxLabel = label(kind);
    if (!root.hasAttribute('aria-busy')) {
      root.setAttribute('aria-busy','true');
      root.dataset.epPuxBusy = '1';
    }
    // A failed or missing optional RPC must never trap the learner behind a loader.
    deadlineTimer = setTimeout(() => {
      suspendedScreen = rootEl()?.firstElementChild || null;
      clear();
    },12000);
  }
  function currentView(root) {
    // The existing interaction layer retains a disabled copy of the previous screen
    // while the server is loading. Never mistake that copy for a newly ready view.
    if (root.querySelector('.ep-flow-pending-visual, [data-ep-transition-hold="1"]')) return 'loading';
    if (root.querySelector('.ep-live-error')) return 'error';
    if (root.querySelector('.ep-live-grid')) return 'dashboard';
    const heading = Array.from(root.querySelectorAll('.ep-live-card .ep-live-head strong'))
      .some(el => /^(P1|P5)\s*·\s*(Недельный план|Haftalik reja|Weekly plan)$/.test(String(el.textContent || '').trim()));
    if (heading) return 'plan';
    if (root.querySelector('.ep-flow-completion-screen')) return 'completion';
    if (root.querySelector('[data-ep-live-submit]')) return 'question';
    if (root.querySelector('[role="status"] .ep-flow-loader') ||
        Array.from(root.querySelectorAll('[role="status"]')).some(el =>
          /^(Загрузка|Loading|Yuklanmoqda)/.test(String(el.textContent || '').trim()))) return 'loading';
    return 'other';
  }
  function ready(root) {
    const view = currentView(root);
    if (view === 'error') return true;
    if (mode === 'dashboard') {
      if (view !== 'dashboard') return false;
      const cards = Array.from(root.querySelectorAll('.ep-live-component-card[data-ep-live-component]'));
      if (cards.length !== 2) return false;
      return cards.every(card => card.querySelector('.ep-pux-overview, .ep-pux-error')) &&
        (!root.querySelector('.ep-live-dashboard-profile') ||
         !!root.querySelector('.ep-live-dashboard-profile [data-ep-exam-plan-edit]'));
    }
    if (mode === 'plan') {
      if (view !== 'plan') return false;
      const card = Array.from(root.querySelectorAll('.ep-live-card')).find(el =>
        /^(P1|P5)\s*·\s*(Недельный план|Haftalik reja|Weekly plan)$/.test(
          String(el.querySelector('.ep-live-head strong')?.textContent || '').trim()));
      if (!card || !card.querySelector('.ep-pux-week, .ep-pux-error')) return false;
      const rows = Array.from(card.querySelectorAll('.ep-live-plan-item'));
      return rows.every(row => row.dataset.epFlowPlan === 'flowux3');
    }
    if (mode === 'question') {
      if (view === 'completion') {
        return ['diagnostic','timed','paper'].includes(lastSessionType) ||
          !!root.querySelector('.ep-pux-finish, .ep-pux-error');
      }
      if (view === 'dashboard') return !!root.querySelector('.ep-live-grid');
      if (view === 'plan') return !!root.querySelector('.ep-pux-week, .ep-pux-error');
      return view === 'question' && !!root.querySelector('.ep-live-qtext') &&
        !!root.querySelector('.ep-live-options, .ep-live-textarea, .ep-live-input');
    }
    return view !== 'loading';
  }
  function examine() {
    const root = rootEl();
    if (!permitted(root)) { if (mode) clear(); return; }
    const view = currentView(root);
    if (!mode) {
      if (suspendedScreen && root.firstElementChild === suspendedScreen) return;
      suspendedScreen = null;
      if (view === 'dashboard' && root.querySelectorAll('.ep-live-component-card').length === 2 &&
          root.querySelectorAll('.ep-pux-overview, .ep-pux-error').length < 2) arm('dashboard');
      else if (view === 'plan' && !root.querySelector('.ep-pux-week, .ep-pux-error')) arm('plan');
      else if (view === 'loading') arm('question');
      else return;
    }
    if (mode === 'question' && view === 'plan') {
      // Finishing an exercise may route directly to a newly generated plan.
      arm('plan');
    } else if (mode === 'question' && view === 'dashboard') {
      arm('dashboard');
    }
    if (!ready(root)) { clearTimeout(readyTimer); readyTimer = null; return; }
    if (readyTimer) return;
    // Other existing UI decorators get one quiet frame to finish before reveal.
    const ticket = startedAt;
    readyTimer = setTimeout(() => {
      readyTimer = null;
      if (mode && ticket === startedAt && permitted(root) && ready(root)) clear();
    },100);
  }
  function onClick(event) {
    const root = rootEl();
    if (!permitted(root)) return;
    const button = event.target?.closest?.('button');
    if (!button || !root.contains(button) || button.disabled) return;
    if (button.matches('[data-ep-live-plan], [data-ep-flow-next-plan]')) arm('plan');
    else if (button.matches('[data-ep-live-dashboard], [data-ep-live-home]')) arm('dashboard');
    else if (button.matches('[data-ep-live-start], [data-ep-live-plan-item], [data-ep-live-timed-start], [data-ep-live-submit]')) arm('question');
  }
  function onSession(event) {
    lastSessionType = String(event.detail?.session?.session_type || '');
  }
  function attach() {
    const root = rootEl();
    if (!root) { setTimeout(attach,50); return; }
    if (observer) return;
    document.addEventListener('click',onClick,true);
    window.addEventListener('iclub:exam-prep-session',onSession);
    observer = new MutationObserver(examine);
    observer.observe(root,{childList:true,subtree:true,characterData:true,attributes:true,attributeFilter:['hidden','aria-hidden']});
    examine();
    internal.progressUxStability = Object.freeze({version:VERSION,stop:() => {
      observer?.disconnect(); observer = null;
      document.removeEventListener('click',onClick,true);
      window.removeEventListener('iclub:exam-prep-session',onSession);
      clear();
    }});
  }
  attach();
})();