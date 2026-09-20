/* Optional, read-only missed-week notice. Never edits a goal, grade, exam series,
 * time budget, localStorage or academic evidence. A failed RPC displays nothing.
 * One existing Exam Plan editor remains the only place to change preferences.
 */
(() => {
  'use strict';
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = 'weekly_adherence_ui_v1';
  if (internal.weeklyAdherenceUi) return;
  const checked = new WeakSet();
  const COPY = {
    ru: {
      header: 'Недельный план требует внимания',
      count: (component,done,total) => `${component}: выполнено ${done} из ${total} целей`,
      body: 'Продолжите доступные задания. Если времени недостаточно, используйте «Изменить план» выше: вы сами выбираете учебную нагрузку, целевую оценку или другую доступную экзаменационную сессию. Официальные даты Cambridge не меняются.'
    },
    uz: {
      header: 'Haftalik rejaga e’tibor kerak',
      count: (component,done,total) => `${component}: ${total} ta maqsaddan ${done} tasi bajarilgan`,
      body: 'Mavjud topshiriqlarni davom ettiring. Vaqt yetmasa, yuqoridagi «Rejani o‘zgartirish» tugmasidan foydalaning: o‘qish yuklamasi, maqsad baho yoki boshqa mavjud imtihon sessiyasini faqat o‘zingiz tanlaysiz. Cambridge rasmiy imtihon sanalari o‘zgarmaydi.'
    },
    en: {
      header: 'Your weekly plan needs attention',
      count: (component,done,total) => `${component}: ${done} of ${total} goals completed`,
      body: 'Continue the available tasks. If your time is insufficient, use “Change exam plan” above: you choose the workload, target grade or another available exam series. Official Cambridge exam dates do not change.'
    }
  };
  function language() {
    let current = '';
    try { current = String(window.i18n?.getLang?.() || document.documentElement.lang || 'ru').toLowerCase(); }
    catch (_) { current = 'ru'; }
    return current.startsWith('uz') ? 'uz' : current.startsWith('en') ? 'en' : 'ru';
  }
  function ready(root) {
    const c = internal.lastCapabilities;
    return window.iClubExamPrepWeeklyFlowEnabled === true &&
      window.iClubExamPrepProgressUxEnabled === true &&
      internal.weeklyFlowApi?.version === 'weekly_flow_adapter_v1' &&
      typeof internal.weeklyFlowApi.adherence === 'function' &&
      c?.coreAccess === true && c?.killSwitch === false &&
      c?.rolloutState === 'controlled_beta' && root && !root.hidden &&
      root.getAttribute('aria-hidden') !== 'true';
  }
  function cardFor(root) {
    return root?.querySelector('[data-ep-exam-plan-card]');
  }
  function validAlert(result,component) {
    const d = result?.ok ? result.data : null;
    if (!d || d.contract_version !== 'previous_week_adherence_v1' ||
        d.component_code !== component || d.status !== 'missed' || d.can_alert !== true ||
        !Number.isInteger(d.scheduled_goals) || d.scheduled_goals < 1 || d.scheduled_goals > 3 ||
        !Number.isInteger(d.completed_now) || d.completed_now < 0 ||
        d.completed_now >= d.scheduled_goals ||
        !Number.isInteger(d.completed_by_deadline) || d.completed_by_deadline < 0 ||
        d.completed_by_deadline > d.completed_now ||
        !Number.isInteger(d.active_week_no) || d.active_week_no < 1 || d.active_week_no > 35) return null;
    return d;
  }
  async function hydrate() {
    const root = document.querySelector('#exam-prep-host-root');
    const card = cardFor(root);
    if (!ready(root) || !card || checked.has(card)) return;
    checked.add(card);
    const lang = language();
    // Both components are read separately, and neither may borrow credit from the other.
    const results = await Promise.allSettled(['P1','P5'].map(component =>
      internal.weeklyFlowApi.adherence(component)));
    if (!ready(root) || cardFor(root) !== card || !card.isConnected || language() !== lang) return;
    const missed = ['P1','P5'].map((component,index) =>
      results[index].status === 'fulfilled' ? validAlert(results[index].value,component) : null
    ).filter(Boolean);
    if (!missed.length || card.querySelector('[data-ep-weekly-adherence-notice]')) return;
    const c = COPY[lang];
    const notice = document.createElement('div');
    notice.className = 'ep-live-notice';
    notice.dataset.epWeeklyAdherenceNotice = 'true';
    notice.setAttribute('role','status');
    notice.setAttribute('aria-live','polite');
    const title = document.createElement('strong');
    title.textContent = c.header;
    notice.append(title);
    for (const entry of missed) {
      const line = document.createElement('div');
      line.className = 'ep-live-meta';
      line.textContent = c.count(entry.component_code,entry.completed_now,entry.scheduled_goals);
      notice.append(line);
    }
    const body = document.createElement('p');
    body.className = 'ep-live-meta';
    body.textContent = c.body;
    notice.append(body);
    // Notice belongs inside the existing exam-plan card. No second edit button.
    card.append(notice);
  }
  let scheduled = false;
  function scan() {
    if (scheduled) return;
    scheduled = true;
    queueMicrotask(() => { scheduled = false; void hydrate(); });
  }
  const root = document.querySelector('#exam-prep-host-root');
  if (root) {
    const observer = new MutationObserver(scan);
    observer.observe(root,{childList:true,subtree:true,attributes:true,attributeFilter:['hidden','aria-hidden']});
    scan();
  }
  internal.weeklyAdherenceUi = Object.freeze({version:VERSION});
})();
