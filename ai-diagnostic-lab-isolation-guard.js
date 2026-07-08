// AI Diagnostic Lab isolation guard.
// When a practice result appears inside the lab, mark the latest practice attempt as is_lab=true.
// This keeps lab attempts out of normal practice stats/history after reload.

(() => {
  'use strict';

  let inFlight = false;
  let lastMarkedAt = 0;

  function resultScreenIsVisible() {
    const screen = document.getElementById('courses-practice-result');
    if (!screen) return false;
    if (screen.hidden) return false;
    if (screen.classList.contains('hidden')) return false;
    const style = window.getComputedStyle(screen);
    return style.display !== 'none' && style.visibility !== 'hidden';
  }

  async function markLatestLabAttempt() {
    if (inFlight) return;
    if (!window.sb?.rpc) return;
    if (!resultScreenIsVisible()) return;

    const now = Date.now();
    if (now - lastMarkedAt < 2500) return;
    lastMarkedAt = now;
    inFlight = true;

    try {
      await window.sb.rpc('mark_latest_practice_attempt_as_lab');
    } catch (error) {
      console.warn('[AI Diagnosis Lab] mark_latest_practice_attempt_as_lab failed:', error);
    } finally {
      inFlight = false;
    }
  }

  let timer = null;
  function schedule() {
    clearTimeout(timer);
    timer = setTimeout(markLatestLabAttempt, 450);
  }

  document.addEventListener('DOMContentLoaded', schedule);
  window.addEventListener('focus', schedule);
  new MutationObserver(schedule).observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['class', 'hidden', 'style']
  });

  schedule();
})();
