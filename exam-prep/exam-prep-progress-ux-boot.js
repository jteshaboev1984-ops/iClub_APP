/* Optional Progress UX asset bootstrap. The existing Exam Prep remains authoritative. */
(() => {
  'use strict';
  if (window.iClubExamPrepProgressUxEnabled !== true) return;
  const script = document.currentScript;
  const src = String(script?.src || '');
  if (!/^https?:\/\//i.test(src) || !/exam-prep-progress-ux-boot\.js(?:\?|$)/.test(src)) return;
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  if (internal.progressUxBootstrapStatus) return;
  internal.progressUxBootstrapStatus = 'loading';
  const base = src.replace(/exam-prep-progress-ux-boot\.js(?:\?.*)?$/, '');
  const root = document.head;
  const stillEnabled = () => window.iClubExamPrepProgressUxEnabled === true;
  const fail = () => {
    internal.progressUxBootstrapStatus = 'unavailable';
    internal.progressUxStability?.stop?.();
  };

  function loadScript(name, datasetKey, expected) {
    return new Promise((resolve, reject) => {
      if (!stillEnabled()) { reject(new Error('disabled')); return; }
      if (expected()) { resolve(); return; }
      const selector = `script[data-exam-prep-progress-ux-${name}]`;
      if (document.querySelector(selector)) { reject(new Error('asset already loading without completion proof')); return; }
      const el = document.createElement('script');
      el.dataset[datasetKey] = 'true';
      el.src = `${base}exam-prep-progress-ux-${name}.js?v=progressux2`;
      el.async = false;
      el.onload = () => expected() && stillEnabled() ? resolve() : reject(new Error('asset not ready'));
      el.onerror = () => reject(new Error('asset unavailable'));
      root.appendChild(el);
    });
  }

  function stylesheet(name, token) {
    const selector = `link[data-exam-prep-progress-ux-${name}]`;
    if (document.querySelector(selector)) return;
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.dataset[token] = 'true';
    link.href = `${base}exam-prep-progress-ux-${name}.css?v=progressux2`;
    root.appendChild(link);
  }

  async function boot() {
    try {
      stylesheet('stability','examPrepProgressUxStability');
      await loadScript('stability','examPrepProgressUxStability', () =>
        internal.progressUxStability?.version === 'progress_ux_stability_v1');
      await loadScript('model', 'examPrepProgressUxModel', () =>
        typeof window.iClubExamPrepProgressUxModel?.normalize === 'function');
      await loadScript('api', 'examPrepProgressUxApi', () =>
        typeof internal.progressUxApi?.progress === 'function');
      if (!stillEnabled()) { fail(); return; }
      if (!document.querySelector('link[data-exam-prep-progress-ux-style]')) {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.dataset.examPrepProgressUxStyle = 'true';
        link.href = `${base}exam-prep-progress-ux.css?v=progressux2`;
        root.appendChild(link);
      }
      await loadScript('ui', 'examPrepProgressUxUi', () =>
        internal.progressUxViews?.version === 'progress_ux_v1');
      internal.progressUxBootstrapStatus = stillEnabled() ? 'ready' : 'unavailable';
      if (!stillEnabled()) fail();
    } catch (_) { fail(); }
  }
  void boot();
})();