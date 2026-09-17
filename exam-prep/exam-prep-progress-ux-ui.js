/* Progress UX v1: isolated, opt-in presentation only. Never writes academic state. */
(() => {
  'use strict';
  if (window.iClubExamPrepProgressUxEnabled !== true) return;
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const model = window.iClubExamPrepProgressUxModel;
  if (!model || typeof model.normalize !== 'function') return;
  const seen = new WeakMap();
  const latestPlan = new Map();
  let pendingBefore = null;
  let lastSession = null;
  let completionSession = null;
  let observer = null;
  let debounce = null;

  const WORDS = Object.freeze({
    ru: {
      goals: 'Цели этой недели', available: 'Доступные задания', total: 'Завершено занятий',
      coverage: 'Покрытие программы', skills: 'Подтверждено навыков', corrections: 'Открытых ошибок',
      noPlan: 'Недельный план пока не составлен.',
      noProof: 'План этой недели пока не составлен. История занятий сохранена.',
      changed: 'Список доступных заданий изменился. Выполненная работа сохранена.',
      work: 'Работа этой недели завершена. Исправление ошибки ожидает повторной проверки.',
      next: 'Следующий шаг показан ниже', unavailable: 'Проверенный прогресс временно недоступен.',
      retry: 'Повторить', goal: 'Цель', mixed: 'Смешанная практика', learning: 'Изучение темы',
      correction: 'Работа над ошибкой', retest: 'Повторная проверка', other: 'Учебная цель',
      beforeAfter: 'Изменения с момента открытия плана', newSession: 'Занятий добавлено',
      newGoals: 'Дополнительно выполнено целей', newCoverage: 'Покрытие программы',
      deltaNote: 'Изменения могут включать занятия с других устройств.',
      noChange: 'После обновления подтверждённые показатели пока не изменились.',
      current: 'Текущий подтверждённый прогресс', dateUnknown: 'Дата уточняется',
      due: 'Повторная проверка', currentTask: 'Текущий шаг', notAvailable: 'Сейчас нет доступного шага'
    },
    uz: {
      goals: 'Bu haftadagi maqsadlar', available: 'Mavjud topshiriqlar', total: 'Yakunlangan mashg‘ulotlar',
      coverage: 'Dastur qamrovi', skills: 'Tasdiqlangan ko‘nikmalar', corrections: 'Tuzatilmagan xatolar',
      noPlan: 'Haftalik reja hali tuzilmagan.',
      noProof: 'Bu haftalik reja hali tuzilmagan. Mashg‘ulotlar tarixi saqlangan.',
      changed: 'Mavjud topshiriqlar ro‘yxati o‘zgardi. Bajarilgan ishlar saqlangan.',
      work: 'Bu haftadagi ish bajarildi. Xato qayta tekshiruvgacha ochiq qoladi.',
      next: 'Keyingi qadam quyida ko‘rsatilgan', unavailable: 'Tasdiqlangan natijalar vaqtincha mavjud emas.',
      retry: 'Qayta urinish', goal: 'Maqsad', mixed: 'Aralash mashq', learning: 'Mavzuni o‘rganish',
      correction: 'Xato ustida ishlash', retest: 'Qayta tekshirish', other: 'O‘quv maqsadi',
      beforeAfter: 'Reja ochilganidan beri o‘zgarishlar', newSession: 'Yangi mashg‘ulotlar',
      newGoals: 'Qo‘shimcha bajarilgan maqsadlar', newCoverage: 'Dastur qamrovi',
      deltaNote: 'O‘zgarishlar boshqa qurilmalardagi mashg‘ulotlarni ham o‘z ichiga olishi mumkin.',
      noChange: 'Yangilangandan so‘ng tasdiqlangan ko‘rsatkichlar hozircha o‘zgarmadi.',
      current: 'Hozirgi tasdiqlangan natijalar', dateUnknown: 'Sana aniqlanmoqda',
      due: 'Qayta tekshiruv', currentTask: 'Hozirgi qadam', notAvailable: 'Hozircha mavjud qadam yo‘q'
    },
    en: {
      goals: 'This week’s goals', available: 'Available tasks', total: 'Sessions completed',
      coverage: 'Syllabus coverage', skills: 'Confirmed skills', corrections: 'Open corrections',
      noPlan: 'Your weekly plan has not been created yet.',
      noProof: 'This week’s plan has not been created yet. Your session history is preserved.',
      changed: 'Available tasks have changed. Your completed work has been preserved.',
      work: 'This week’s work is done. The correction remains open pending a later check.',
      next: 'Your next step is shown below', unavailable: 'Verified progress is temporarily unavailable.',
      retry: 'Retry', goal: 'Goal', mixed: 'Mixed practice', learning: 'Study the topic',
      correction: 'Work on a correction', retest: 'Delayed check', other: 'Study goal',
      beforeAfter: 'Changes since you opened the plan', newSession: 'New sessions',
      newGoals: 'Additional goals completed', newCoverage: 'Syllabus coverage',
      deltaNote: 'Changes may include sessions completed on other devices.',
      noChange: 'The verified indicators have not changed since the last update.',
      current: 'Current verified progress', dateUnknown: 'Date to be confirmed',
      due: 'Delayed check', currentTask: 'Current step', notAvailable: 'No available step right now'
    }
  });
  const AREA = Object.freeze({
    '1.1 Quadratics': ['Квадратные выражения и уравнения','Kvadrat ifodalar va tenglamalar','Quadratics'],
    '1.2 Functions': ['Функции','Funksiyalar','Functions'],
    '1.3 Coordinate geometry': ['Координатная геометрия','Koordinata geometriyasi','Coordinate geometry'],
    '1.4 Circular measure': ['Радианная мера и окружность','Radian o‘lchov va aylana','Circular measure'],
    '1.5 Trigonometry': ['Тригонометрия','Trigonometriya','Trigonometry'],
    '1.6 Series': ['Последовательности и ряды','Ketma-ketliklar va qatorlar','Series'],
    '1.7 Differentiation': ['Дифференцирование','Differensiallash','Differentiation'],
    '1.8 Integration': ['Интегрирование','Integrallash','Integration'],
    '5.1 Representation of data': ['Представление данных','Ma’lumotlarni tasvirlash','Representation of data'],
    '5.2 Permutations and combinations': ['Перестановки и сочетания','O‘rin almashtirish va kombinatsiyalar','Permutations and combinations'],
    '5.3 Probability': ['Вероятность','Ehtimollik','Probability'],
    '5.4 Discrete random variables': ['Дискретные случайные величины','Diskret tasodifiy miqdorlar','Discrete random variables'],
    '5.5 The normal distribution': ['Нормальное распределение','Normal taqsimot','The normal distribution']
  });
  const UZ_MONTHS = Object.freeze(['yanvar','fevral','mart','aprel','may','iyun','iyul','avgust','sentabr','oktabr','noyabr','dekabr']);
  const rootEl = () => document.querySelector('#exam-prep-host-root');
  function lang() {
    let value = '';
    try { value = String(window.i18n?.getLang?.() || document.documentElement.lang || 'ru').toLowerCase(); } catch (_) {}
    return value.startsWith('uz') ? 'uz' : value.startsWith('en') ? 'en' : 'ru';
  }
  const words = () => WORDS[lang()];
  function allowed() {
    const c = internal.lastCapabilities, r = rootEl();
    return window.iClubExamPrepProgressUxEnabled === true && !!r && !r.hidden &&
      r.getAttribute('aria-hidden') !== 'true' && c?.coreAccess === true &&
      c?.killSwitch === false && c?.rolloutState === 'controlled_beta';
  }
  function node(tag, cls, text) {
    const n = document.createElement(tag);
    if (cls) n.className = cls;
    if (text !== undefined && text !== null) n.textContent = String(text);
    return n;
  }
  function metric(parent, name, value) {
    const r = node('div','ep-pux-metric');
    r.append(node('span','ep-pux-label',name),node('strong','ep-pux-value',value));
    parent.append(r);
  }
  function localizedArea(area) {
    const arr = AREA[area];
    if (!arr) return null;
    return arr[lang() === 'ru' ? 0 : lang() === 'uz' ? 1 : 2];
  }
  function titleFor(item, component, tracker) {
    const c = words();
    if (item?.item_type === 'mixed_transfer') return c.mixed;
    const code = String(item?.skill_code || '');
    if (code && code.startsWith(`${component}-`)) {
      for (const area of (Array.isArray(tracker?.areas) ? tracker.areas : [])) {
        const skill = (Array.isArray(area.skills) ? area.skills : []).find(x => x?.skill_code === code);
        if (skill) {
          if (lang() === 'ru' && typeof skill.description === 'string' && skill.description.trim()) return skill.description.trim();
          return localizedArea(area.official_syllabus_section) || c.other;
        }
      }
    }
    return ({ correction: c.correction, retest: c.retest, learning: c.learning })[item?.item_type] || c.other;
  }
  function dateText(value) {
    if (!value || !Number.isFinite(Date.parse(value))) return words().dateUnknown;
    const date = new Date(value);
    if (lang() === 'uz') return `${date.getFullYear()}-yil ${date.getDate()}-${UZ_MONTHS[date.getMonth()]}`;
    return new Intl.DateTimeFormat(lang() === 'en' ? 'en-GB' : 'ru-RU', {
      day: 'numeric', month: 'long', year: 'numeric'
    }).format(date);
  }
  async function obtain(component, withTracker = false) {
    if (!allowed() || typeof internal.progressUxApi?.progress !== 'function') return null;
    const [result, detail] = await Promise.all([
      internal.progressUxApi.progress(component),
      withTracker && typeof internal.api?.syllabusTracker === 'function'
        ? internal.api.syllabusTracker(component).catch(() => null) : Promise.resolve(null)
    ]);
    if (!allowed() || !result?.ok) return null;
    const state = model.normalize(result.data,component,lang());
    return state.ok ? { state, raw: result.data, tracker: detail?.ok ? detail.data : null } : null;
  }
  function markError(target, component, kind) {
    if (!target?.isConnected || !allowed()) return;
    const c = words();
    const panel = node('div','ep-pux-panel ep-pux-error');
    panel.setAttribute('role','status');
    panel.append(node('span','',c.unavailable));
    const retry = node('button','ep-live-btn secondary',c.retry);
    retry.type = 'button';
    retry.addEventListener('click', () => {
      panel.remove(); seen.delete(target); request(kind,target,component);
    });
    panel.append(retry);
    target.append(panel);
  }
  function goalStatus(goal, c) {
    return c.goal[goal.status] || c.goal.unavailable;
  }
  function missingPlanText(state, c) {
    return state.finalizedSessions > 0 ? c.noProof : c.noPlan;
  }
  function showConfirmedMetrics(panel, state, c) {
    if (state.coveragePct != null) metric(panel,c.coverage,`${state.coveragePct}%`);
    if (state.confirmedSkills != null) metric(panel,c.skills,`${state.confirmedSkills} / ${state.totalCanonicalSkills}`);
  }
  function showDashboard(card, data) {
    const { state } = data, c = words();
    const panel = node('section','ep-pux-panel ep-pux-overview');
    panel.setAttribute('aria-label',c.goals);
    if (state.hasPlan) {
      metric(panel,c.goals,state.goalCounter);
    } else {
      panel.append(node('p','ep-pux-note',missingPlanText(state,c)));
    }
    metric(panel,c.total,state.finalizedSessions);
    showConfirmedMetrics(panel,state,c);
    metric(panel,c.corrections,state.openCorrections);
    const actions = card.querySelector('.ep-live-actions');
    if (actions) actions.before(panel); else card.append(panel);
  }
  function showPlan(card, data, component) {
    const { state, raw, tracker } = data, c = words();
    latestPlan.set(component,state);
    const section = node('section','ep-pux-panel ep-pux-week');
    section.setAttribute('aria-label',c.goals);
    section.append(node('h3','ep-pux-heading',c.goals));
    if (!state.hasPlan) {
      section.append(node('p','ep-pux-note',missingPlanText(state,c)));
    } else {
      section.append(node('div','ep-pux-counter',state.goalCounter));
      const list = node('div','ep-pux-goals');
      for (const goal of state.goals) {
        const source = raw.goals.find(row => row.goal_id === goal.goalId);
        const row = node('article','ep-pux-goal');
        row.append(node('strong','ep-pux-goal-title',`${goal.order}. ${titleFor(source,component,tracker)}`));
        row.append(node('span','ep-pux-goal-state',goalStatus(goal,state.labels)));
        if (goal.finalizedSessions>0) row.append(node('small','ep-pux-note',`${c.total}: ${goal.finalizedSessions}`));
        if (goal.correctionNote) row.append(node('small','ep-pux-note',c.work));
        if (goal.retestDueAt) row.append(node('small','ep-pux-note',`${c.due}: ${dateText(goal.retestDueAt)}`));
        if (source?.plan_changed === true && !goal.weeklyComplete) row.append(node('small','ep-pux-note',c.changed));
        list.append(row);
      }
      section.append(list);
      const hasUnmatchedTask = Array.from(card.querySelectorAll('[data-ep-live-plan-item]')).some(button =>
        !state.goals.some(goal => goal.actionPriorityOrder === Number(button.dataset.epLivePlanItem)));
      if (hasUnmatchedTask) section.append(node('p','ep-pux-note',c.changed));
    }
    const first = card.querySelector('.ep-live-plan-item');
    if (first) {
      section.append(node('p','ep-pux-section-caption',c.available));
      first.before(section);
    } else card.append(section);
  }
  function showCompletion(screen, data, component) {
    const { state } = data, c = words();
    const before = pendingBefore?.component === component ? pendingBefore.state : null;
    const comparable = before && before.activeWeek === state.activeWeek;
    const section = node('section','ep-pux-panel ep-pux-finish');
    section.setAttribute('aria-label', comparable ? c.beforeAfter : c.current);
    section.append(node('h3','ep-pux-heading',comparable ? c.beforeAfter : c.current));
    if (comparable) {
      section.append(node('p','ep-pux-note',c.deltaNote));
      const gainedSessions = state.finalizedSessions - before.finalizedSessions;
      const gainedGoals = state.completedGoals - before.completedGoals;
      if (gainedSessions > 0) metric(section,c.newSession,`+${gainedSessions}`);
      if (gainedGoals > 0) metric(section,c.newGoals,`+${gainedGoals}`);
      if (state.coveragePct != null && before.coveragePct != null && state.coveragePct !== before.coveragePct)
        metric(section,c.newCoverage,`${before.coveragePct}% → ${state.coveragePct}%`);
      if (gainedSessions === 0 && gainedGoals === 0 && state.coveragePct === before.coveragePct)
        section.append(node('p','ep-pux-note',c.noChange));
    }
    if (state.hasPlan) metric(section,c.goals,state.goalCounter);
    metric(section,c.total,state.finalizedSessions);
    showConfirmedMetrics(section,state,c);
    metric(section,c.corrections,state.openCorrections);
    const next = screen.querySelector('.ep-flow-next-card');
    if (next) next.before(section); else screen.append(section);
    pendingBefore = null;
    completionSession = null;
  }
  async function request(kind,target,component) {
    if (!allowed() || seen.has(target)) return;
    seen.set(target,'loading');
    const expectedRoot = rootEl();
    const data = await obtain(component,kind === 'plan');
    if (!target.isConnected || rootEl() !== expectedRoot || !allowed()) { seen.delete(target); return; }
    if (!data) { markError(target,component,kind); seen.set(target,'error'); return; }
    if (kind === 'dashboard') showDashboard(target,data);
    else if (kind === 'plan') showPlan(target,data,component);
    else if (kind === 'completion') showCompletion(target,data,component);
    seen.set(target,'done');
  }
  function reconcile() {
    if (!allowed()) {
      rootEl()?.querySelectorAll('.ep-pux-panel').forEach(n=>n.remove());
      return;
    }
    const root = rootEl();
    root.querySelectorAll('.ep-live-component-card[data-ep-live-component]').forEach(card => {
      const component = card.dataset.epLiveComponent;
      if (component === 'P1' || component === 'P5') request('dashboard',card,component);
    });
    const planRows = root.querySelectorAll('.ep-live-plan-item');
    if (planRows.length) {
      const card = planRows[0].closest('.ep-live-card');
      const component = String(card?.querySelector('.ep-live-head strong')?.textContent || '').match(/\b(P1|P5)\b/)?.[1];
      if (card && component) request('plan',card,component);
    }
    const completion = root.querySelector('.ep-flow-completion-screen');
    const component = completionSession?.component || pendingBefore?.component;
    if (completion && component) request('completion',completion,component);
  }
  function onClick(event) {
    const button = event.target?.closest?.('[data-ep-live-plan-item]');
    if (!button || !allowed() || !rootEl()?.contains(button)) return;
    const card = button.closest('.ep-live-card');
    const component = String(card?.querySelector('.ep-live-head strong')?.textContent || '').match(/\b(P1|P5)\b/)?.[1];
    if (!component) return;
    const state = latestPlan.get(component);
    pendingBefore = state ? {component,state} : null;
  }
  function onSession(event) {
    if (event.detail?.session?.session_id) lastSession = event.detail.session;
  }
  function onEnded(event) {
    if (lastSession?.session_id && String(lastSession.session_id) === String(event.detail?.sessionId) &&
        !['diagnostic','timed','paper'].includes(lastSession.session_type) &&
        ['P1','P5'].includes(lastSession.component_code)) {
      completionSession = {component:lastSession.component_code,sessionId:lastSession.session_id};
    }
  }
  function attach() {
    const root = rootEl();
    if (!root) { setTimeout(attach,50); return; }
    if (observer) return;
    document.addEventListener('click',onClick,true);
    window.addEventListener('iclub:exam-prep-session',onSession);
    window.addEventListener('iclub:exam-prep-session-ended',onEnded);
    observer = new MutationObserver(() => {
      if (debounce) return;
      debounce = setTimeout(() => { debounce = null; reconcile(); },40);
    });
    observer.observe(root,{childList:true,subtree:true});
    reconcile();
    internal.progressUxViews = Object.freeze({version:'progress_ux_v1',reconcile});
  }
  attach();
})();