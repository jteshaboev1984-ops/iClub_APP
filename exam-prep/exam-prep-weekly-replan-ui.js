/* Draft-only weekly plan revision control. Loads only after the opt-in adapter.
 * A verified goal card is the only entry; never changes global Core APIs,
 * never writes localStorage and never silently retries an uncertain mutation.
 */
(() => {
  'use strict';
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  if (internal.weeklyReplanUi) return;
  const WORDS = {
    ru: {
      review: 'Пересмотреть план', question: 'Пересмотреть недельный план? Система обновит его только в том случае, если ваши текущие цели останутся прежними. Ответы и результаты сохранятся.',
      confirm: 'Да, пересмотреть', cancel: 'Отмена', loading: 'Проверяем план…',
      changed: 'План обновлён. Все цели и результаты сохранены. Откройте недельный план заново через обзор.',
      ongoing: 'Сначала завершите начатое занятие. Оно и ваши ответы сохранены.',
      work: 'В этой неделе уже есть выполненные задания. Текущий план сохранён; результаты не изменены.',
      goals: 'Обновление изменило бы ваши текущие цели. План оставлен без изменений.',
      stale: 'План изменился в другой вкладке. Откройте его заново через обзор.',
      uncertain: 'Не удалось подтвердить результат. Не повторяйте действие: откройте план заново через обзор.',
      overview: 'К обзору'
    },
    uz: {
      review: 'Rejani qayta ko‘rib chiqish', question: 'Haftalik rejani qayta ko‘rib chiqasizmi? Tizim uni faqat joriy maqsadlaringiz o‘zgarmasa yangilaydi. Javoblar va natijalar saqlanadi.',
      confirm: 'Ha, qayta ko‘rish', cancel: 'Bekor qilish', loading: 'Reja tekshirilmoqda…',
      changed: 'Reja yangilandi. Barcha maqsad va natijalar saqlandi. Umumiy ko‘rinish orqali haftalik rejani qayta oching.',
      ongoing: 'Avval boshlangan mashg‘ulotni yakunlang. U va javoblaringiz saqlangan.',
      work: 'Bu haftada bajarilgan topshiriqlar bor. Joriy reja va natijalar o‘zgarmadi.',
      goals: 'Yangilash joriy maqsadlaringizni o‘zgartiradi. Reja o‘zgarishsiz qoldirildi.',
      stale: 'Reja boshqa oynada o‘zgargan. Uni umumiy ko‘rinish orqali qayta oching.',
      uncertain: 'Natijani tasdiqlab bo‘lmadi. Amalni takrorlamang: rejani umumiy ko‘rinish orqali qayta oching.',
      overview: 'Umumiy ko‘rinish'
    },
    en: {
      review: 'Review weekly plan', question: 'Review this weekly plan? It will change only if your existing goals remain the same. Your answers and results will be kept.',
      confirm: 'Yes, review', cancel: 'Cancel', loading: 'Checking your plan…',
      changed: 'Plan updated. All goals and results were preserved. Reopen the weekly plan from Overview.',
      ongoing: 'Finish your current study session first. It and your answers are saved.',
      work: 'You have already completed work this week. Your current plan and results have been preserved.',
      goals: 'The update would change your existing goals, so the plan was left unchanged.',
      stale: 'The plan changed in another tab. Reopen it from Overview.',
      uncertain: 'The outcome could not be confirmed. Do not repeat the action; reopen the plan from Overview.',
      overview: 'Overview'
    }
  };
  const processed = new WeakSet();
  function enabled(component) {
    return window.iClubExamPrepWeeklyFlowEnabled === true &&
      internal.weeklyFlowApi?.version === 'weekly_flow_adapter_v1' &&
      typeof internal.weeklyFlowApi.replan === 'function' &&
      !internal.weeklyFlowApi.allowed(component);
  }
  function words() {
    let language = String(document.documentElement.lang || 'ru').slice(0,2).toLowerCase();
    if (!WORDS[language]) language = String(window.iClubCurrentLanguage || 'ru').slice(0,2).toLowerCase();
    return WORDS[language] || WORDS.ru;
  }
  function element(tag, className, text) {
    const el = document.createElement(tag);
    el.className = className;
    if (text !== undefined) el.textContent = text;
    return el;
  }
  function overview(card, area, text) {
    area.replaceChildren(element('p','ep-pux-note',text));
    const back = element('button','ep-live-btn secondary',words().overview);
    back.type = 'button';
    back.addEventListener('click',() => card.querySelector('[data-ep-live-dashboard]')?.click());
    area.append(back);
  }
  async function enhance(section) {
    if (processed.has(section)) return;
    processed.add(section);
    const card = section.closest('.ep-live-card');
    const heading = card?.querySelector('.ep-live-head strong')?.textContent || '';
    const component = /^\s*(P1|P5)\s*·/.exec(heading)?.[1];
    if (!card || !component || !enabled(component)) return;
    const initial = await internal.api?.weeklyPlan?.(component);
    if (!section.isConnected || !enabled(component) || section.dataset.epPuxPrimaryGoals !== 'verified'
        || !initial?.ok || typeof initial.data?.plan_id !== 'string') return;
    const expectedPlanId = initial.data.plan_id;
    const area = element('div','ep-live-actions ep-weekly-review-actions');
    const primary = element('button','ep-live-btn secondary',words().review);
    primary.type='button';
    function reset() { area.replaceChildren(primary); }
    primary.addEventListener('click', async () => {
      if (!section.isConnected || !enabled(component)) return;
      const current = await internal.api.weeklyPlan(component);
      if (!current?.ok || current.data?.plan_id !== expectedPlanId) {
        overview(card,area,words().stale); return;
      }
      const c=words();
      const question=element('p','ep-pux-note',c.question);
      const yes=element('button','ep-live-btn',c.confirm);
      const no=element('button','ep-live-btn secondary',c.cancel);
      yes.type=no.type='button';
      no.addEventListener('click',reset);
      area.replaceChildren(question,yes,no);
      yes.addEventListener('click',async () => {
        if (!section.isConnected || !enabled(component)) return;
        yes.disabled=true; no.disabled=true;
        area.replaceChildren(element('p','ep-pux-note',words().loading));
        const requestKey=`ep-explicit-review-${Date.now()}-${Math.random().toString(36).slice(2,11)}`;
        const result=await internal.weeklyFlowApi.replan(component,expectedPlanId,requestKey);
        if (!section.isConnected) return;
        const status=result?.ok ? result.data?.status : null;
        const text=status==='replanned' || status==='already_applied' ? words().changed
          : status==='finish_current_session_first' ? words().ongoing
          : status==='weekly_work_preserved' ? words().work
          : status==='goal_review_required' ? words().goals
          : status==='stale' ? words().stale : words().uncertain;
        if (status==='replanned' || status==='already_applied') {
          card.querySelectorAll('[data-ep-live-plan-item],.ep-pux-goal-action').forEach(button => { button.disabled=true; });
        }
        overview(card,area,text);
      },{once:true});
    });
    area.append(primary);
    section.append(area);
  }
  function scan() {
    if (window.iClubExamPrepWeeklyFlowEnabled !== true) return;
    document.querySelectorAll('#exam-prep-host-root .ep-pux-week[data-ep-pux-primary-goals="verified"]')
      .forEach(section => { void enhance(section); });
  }
  const root = document.querySelector('#exam-prep-host-root') || document.body;
  if (root) {
    const observer = new MutationObserver(scan);
    observer.observe(root,{subtree:true,childList:true,attributes:true,attributeFilter:['data-ep-pux-primary-goals']});
    scan();
  }
  internal.weeklyReplanUi=Object.freeze({version:'weekly_replan_ui_v1'});
})();
