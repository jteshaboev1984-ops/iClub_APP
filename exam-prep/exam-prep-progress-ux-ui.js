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
      coverage: 'Покрытие программы', skills: 'Навыков с подтверждённым охватом', corrections: 'Открытых ошибок',
      noPlan: 'Недельный план пока не составлен.',
      noProof: 'План этой недели пока не составлен. История занятий сохранена.',
      changed: 'Список доступных заданий изменился. Выполненная работа сохранена.',
      work: 'Работа по этой цели выполнена. Ошибка остаётся открытой до успешной повторной проверки.',
      rework: 'Ранее выполненная работа сохранена. Ошибка снова требует внимания.',
      waitingTitle: 'Ожидается повторная проверка',
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
      coverage: 'Dastur qamrovi', skills: 'Qamrovi tasdiqlangan ko‘nikmalar', corrections: 'Tuzatilmagan xatolar',
      noPlan: 'Haftalik reja hali tuzilmagan.',
      noProof: 'Bu haftalik reja hali tuzilmagan. Mashg‘ulotlar tarixi saqlangan.',
      changed: 'Mavjud topshiriqlar ro‘yxati o‘zgardi. Bajarilgan ishlar saqlangan.',
      work: 'Ushbu maqsad bo‘yicha ish bajarildi. Xato muvaffaqiyatli qayta tekshiruvgacha ochiq qoladi.',
      rework: 'Avval bajarilgan ishlar saqlangan. Xato ustida yana ishlash kerak.',
      waitingTitle: 'Qayta tekshiruv kutilmoqda',
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
      coverage: 'Syllabus coverage', skills: 'Skills with confirmed coverage', corrections: 'Open corrections',
      noPlan: 'Your weekly plan has not been created yet.',
      noProof: 'This week’s plan has not been created yet. Your session history is preserved.',
      changed: 'Available tasks have changed. Your completed work has been preserved.',
      work: 'Work on this goal is complete. The correction remains open until a successful delayed check.',
      rework: 'Your earlier work is preserved. The correction needs more attention.',
      waitingTitle: 'Waiting for a delayed check',
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
  function waitingGoal(goal) {
    return goal.weeklyComplete === true && goal.correctionOpen === true && goal.status === 'waiting_retest';
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
  // Only the server's exact goal/plan/action binding can promote a frozen goal
  // into a primary action. If any binding fails, do not hide the existing UI.
  async function promoteGoalActions(card, section, entries, component, state, c) {
    if (window.iClubExamPrepWeeklyFlowEnabled !== true || !state.hasPlan) return;
    const flow = internal.weeklyFlowApi;
    if (!flow || flow.version !== 'weekly_flow_adapter_v1' || flow.allowed(component)) return;
    const buttons = Array.from(card.querySelectorAll('[data-ep-live-plan-item]'));
    const claimed = entries.filter(entry => entry.goal.actionPriorityOrder !== null);
    if (claimed.length !== buttons.length || new Set(claimed.map(entry => entry.goal.actionPriorityOrder)).size !== claimed.length) return;
    const bound = buttons.map(button => {
      const priority = Number(button.dataset.epLivePlanItem);
      const matching = claimed.filter(entry => entry.goal.actionPriorityOrder === priority);
      return matching.length === 1 ? { button, entry: matching[0], priority } : null;
    });
    if (bound.some(entry => !entry)) return;
    const planResult = await internal.api?.weeklyPlan?.(component);
    const planId = planResult?.ok && planResult.data?.plan_id;
    if (typeof planId !== 'string') return;
    const decisions = await Promise.all(bound.map(({entry}) => flow.goal(component,entry.goal.goalId,planId)));
    if (!card.isConnected || !card.contains(section) || !allowed()) return;
    if (decisions.some((result,index) => {
      if (!result?.ok) return true;
      const status = result.data?.status;
      if (!['ready','resume','waiting','content_exhausted','stale'].includes(status)) return true;
      if (status === 'ready' || status === 'resume') {
        const binding = bound[index];
        return result.data?.goal_id !== binding.entry.goal.goalId ||
          result.data?.plan_id !== planId ||
          result.data?.component_code !== component ||
          result.data?.priority_order !== binding.priority;
      }
      return false;
    })) return;
    bound.forEach(({button,entry},index) => {
      const status = decisions[index].data.status;
      if ((status === 'ready' || status === 'resume') && !button.disabled) {
        const action = node('button','ep-live-btn ep-pux-goal-action',
          ({ru:'Продолжить цель',uz:'Maqsadni davom ettirish',en:'Continue goal'})[lang()]);
        action.type = 'button';
        action.dataset.epPuxGoalAction = entry.goal.goalId;
        action.addEventListener('click', () => {
          if (allowed() && card.contains(button) && !button.disabled) button.click();
        });
        entry.row.append(action);
      } else if (status === 'content_exhausted') {
        entry.row.append(node('small','ep-pux-note',({
          ru:'Эти вопросы уже выполнены. Для новой проверки нужны другие задания. Предыдущий результат сохранён.',
          uz:'Bu savollar avval bajarilgan. Yangi tekshiruv uchun boshqa topshiriqlar kerak. Oldingi natija saqlangan.',
          en:'These questions were completed already. A new check needs different questions. Your previous result is saved.'
        })[lang()]));
      } else if (status === 'waiting' || button.disabled) {
        entry.row.append(node('small','ep-pux-note',({
          ru:'Следующее задание пока недоступно.',uz:'Keyingi topshiriq hozircha mavjud emas.',en:'The next task is not available yet.'
        })[lang()]));
      } else if (status === 'stale') {
        entry.row.append(node('small','ep-pux-note',c.changed));
      }
    });
    // Keep original bound buttons in DOM, with their original listeners and Core
    // contracts. The single goal-card CTA delegates to the already guarded native
    // handler; hiding rows does not erase or alter student history.
    card.querySelectorAll('.ep-live-plan-item').forEach(row => {
      row.hidden = true;
      row.style.display = 'none';
    });
    section.querySelector('.ep-pux-section-caption')?.remove();
    section.dataset.epPuxPrimaryGoals = 'verified';
  }
  async function showPlan(card, data, component) {
    const { state, raw, tracker } = data, c = words();
    latestPlan.set(component,state);
    const actionRows = [];
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
        const row = node('article',`ep-pux-goal${waitingGoal(goal) ? ' ep-pux-goal-waiting' : ''}${goal.status === 'needs_rework' ? ' ep-pux-goal-rework' : ''}`);
        row.append(node('strong','ep-pux-goal-title',`${goal.order}. ${titleFor(source,component,tracker)}`));
        row.append(node('span','ep-pux-goal-state',goalStatus(goal,state.labels)));
        if (goal.finalizedSessions>0) row.append(node('small','ep-pux-note',`${c.total}: ${goal.finalizedSessions}`));
        if (waitingGoal(goal) || (goal.correctionNote && goal.status === 'weekly_work_done'))
          row.append(node('small','ep-pux-note',c.work));
        else if (goal.status === 'needs_rework' && goal.correctionOpen && goal.weeklyComplete)
          row.append(node('small','ep-pux-note',c.rework));
        if (goal.retestDueAt && goal.status === 'waiting_retest')
          row.append(node('small','ep-pux-note',`${c.due}: ${dateText(goal.retestDueAt)}`));
        if (source?.plan_changed === true && !goal.weeklyComplete) row.append(node('small','ep-pux-note',c.changed));
        list.append(row);
        actionRows.push({goal,row});
      }
      section.append(list);
      const hasUnmatchedTask = Array.from(card.querySelectorAll('[data-ep-live-plan-item]')).some(button =>
        !state.goals.some(goal => goal.actionPriorityOrder === Number(button.dataset.epLivePlanItem)));
      if (hasUnmatchedTask) section.append(node('p','ep-pux-note',c.changed));
    }
    const first = card.querySelector('.ep-live-plan-item');
    if (first) {
      const hasAvailableAction = Array.from(card.querySelectorAll('[data-ep-live-plan-item]')).some(button => !button.disabled);
      section.append(node('p','ep-pux-section-caption',hasAvailableAction ? c.available : c.notAvailable));
      first.before(section);
    } else {
      section.append(node('p','ep-pux-note',c.notAvailable));
      const notice = card.querySelector('.ep-live-notice');
      if (notice) notice.before(section); else card.append(section);
    }
    await promoteGoalActions(card,section,actionRows,component,state,c);
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
    const pending = state.goals.find(waitingGoal);
    if (pending) {
      const notice = node('aside','ep-pux-waiting');
      notice.append(node('strong','ep-pux-waiting-heading',c.waitingTitle));
      notice.append(node('p','ep-pux-note',c.work));
      notice.append(node('p','ep-pux-note',`${c.due}: ${dateText(pending.retestDueAt)}`));
      section.append(notice);
    }
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
    else if (kind === 'plan') await showPlan(target,data,component);
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
      // The compact route cards are navigation only. Do not snapshot weekly goals
      // or inject a second progress panel merely because the learner opened Exam Prep.
      if (card.dataset.epComponentEntry === '1') return;
      const component = card.dataset.epLiveComponent;
      if (component === 'P1' || component === 'P5') request('dashboard',card,component);
    });
    // The live planner can render a notice without any item rows. Detect the
    // actual localized plan heading, not the existence of an actionable button.
    const planCard = Array.from(root.querySelectorAll('.ep-live-card')).find(card => {
      const title = String(card.querySelector('.ep-live-head strong')?.textContent || '').trim();
      return /^(P1|P5)\s*·\s*(Недельный план|Haftalik reja|Weekly plan)$/.test(title);
    });
    if (planCard) {
      const component = String(planCard.querySelector('.ep-live-head strong')?.textContent || '').match(/^(P1|P5)\b/)?.[1];
      if (component) request('plan',planCard,component);
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
