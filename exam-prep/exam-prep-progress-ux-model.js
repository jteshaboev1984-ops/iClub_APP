/* Presentation-only normalization. Academic truth is supplied by the authenticated server. */
(function (global) {
  'use strict';

  const COMPONENT_COUNTS = Object.freeze({ P1: 45, P5: 36 });
  const GOAL_STATES = new Set([
    'not_started', 'in_progress', 'weekly_work_done', 'waiting_retest',
    'completed', 'needs_rework', 'paused', 'replaced', 'unavailable'
  ]);
  const COPY = Object.freeze({
    ru: Object.freeze({
      weekly: 'Недельные цели', noPlan: 'Недельный план ещё не создан',
      countUnavailable: 'Прогресс пока недоступен', session: 'Занятий завершено',
      correction: 'Открытые ошибки', goal: Object.freeze({
        not_started: 'Ещё не начато', in_progress: 'В работе',
        weekly_work_done: 'Работа на этой неделе выполнена',
        waiting_retest: 'Ожидает повторной проверки', completed: 'Выполнено',
        needs_rework: 'Нужна дополнительная работа', paused: 'Временно отложено',
        replaced: 'План изменён', unavailable: 'Пока недоступно'
      }),
      correctionPending: 'Работа на неделе выполнена. Ошибка остаётся открытой до успешной повторной проверки.'
    }),
    uz: Object.freeze({
      weekly: 'Haftalik maqsadlar', noPlan: 'Haftalik reja hali tuzilmagan',
      countUnavailable: 'Hozircha natija mavjud emas', session: 'Yakunlangan mashg‘ulotlar',
      correction: 'Hali tuzatilmagan xatolar', goal: Object.freeze({
        not_started: 'Hali boshlanmagan', in_progress: 'Bajarilmoqda',
        weekly_work_done: 'Bu haftadagi ish bajarildi',
        waiting_retest: 'Qayta tekshiruv kutilmoqda', completed: 'Bajarildi',
        needs_rework: 'Qo‘shimcha mashq kerak', paused: 'Vaqtincha qoldirildi',
        replaced: 'Reja o‘zgardi', unavailable: 'Hozircha mavjud emas'
      }),
      correctionPending: 'Bu haftadagi ish bajarildi. Xato muvaffaqiyatli qayta tekshiruvdan keyingina yopiladi.'
    }),
    en: Object.freeze({
      weekly: 'Weekly goals', noPlan: 'Your weekly plan has not been created yet',
      countUnavailable: 'Progress is not available yet', session: 'Sessions completed',
      correction: 'Open corrections', goal: Object.freeze({
        not_started: 'Not started', in_progress: 'In progress',
        weekly_work_done: 'This week’s work is complete',
        waiting_retest: 'Awaiting a later check', completed: 'Completed',
        needs_rework: 'More work needed', paused: 'Paused',
        replaced: 'Plan changed', unavailable: 'Not available yet'
      }),
      correctionPending: 'This week’s work is complete. The correction stays open until a successful delayed check.'
    })
  });

  const validNonnegativeInteger = value => Number.isSafeInteger(value) && value >= 0;
  const bad = reason => Object.freeze({ ok: false, reason });

  function normalize(payload, component, language = 'ru') {
    if (!Object.hasOwn(COMPONENT_COUNTS, component)) return bad('bad_requested_component');
    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) return bad('missing_payload');
    if (payload.contract_version !== 'progress_ux_v1') return bad('unsupported_contract');
    if (payload.component_code !== component) return bad('component_mismatch');
    if (!Number.isInteger(payload.active_week_no) || payload.active_week_no < 1 || payload.active_week_no > 36) return bad('bad_week');
    if (!Array.isArray(payload.goals) || payload.goals.length > 3) return bad('bad_goals');
    if (typeof payload.plan_available !== 'boolean' || (!payload.plan_available && payload.goals.length > 0)) return bad('bad_plan_availability');
    if (!validNonnegativeInteger(payload.finalized_study_sessions) ||
        !validNonnegativeInteger(payload.open_corrections)) return bad('bad_counters');
    if (payload.confirmed_skills !== null && (!validNonnegativeInteger(payload.confirmed_skills) ||
        payload.confirmed_skills > COMPONENT_COUNTS[component])) return bad('bad_confirmed_skills');
    if (payload.coverage_pct !== null && (typeof payload.coverage_pct !== 'number' ||
        !Number.isFinite(payload.coverage_pct) || payload.coverage_pct < 0 || payload.coverage_pct > 100)) return bad('bad_coverage');

    const seenGoals = new Set();
    const seenOrders = new Set();
    let completed = 0;
    const goals = [];
    for (const goal of payload.goals) {
      if (!goal || typeof goal !== 'object' || typeof goal.goal_id !== 'string' || goal.goal_id.length < 1 ||
          seenGoals.has(goal.goal_id) || !Number.isInteger(goal.priority_order) ||
          goal.priority_order < 1 || goal.priority_order > 3 || seenOrders.has(goal.priority_order) ||
          goal.component_code !== component || !GOAL_STATES.has(goal.status) ||
          typeof goal.weekly_commitment_complete !== 'boolean' ||
          typeof goal.correction_open !== 'boolean' ||
          !validNonnegativeInteger(goal.finalized_sessions)) return bad('invalid_goal');
      if (goal.action_priority_order !== null && (!Number.isInteger(goal.action_priority_order) ||
          goal.action_priority_order < 1 || goal.action_priority_order > 3)) return bad('bad_action_binding');
      if (goal.retest_due_at !== null && (typeof goal.retest_due_at !== 'string' ||
          !Number.isFinite(Date.parse(goal.retest_due_at)))) return bad('bad_retest_date');
      if (goal.weekly_commitment_complete) completed += 1;
      seenGoals.add(goal.goal_id);
      seenOrders.add(goal.priority_order);
      goals.push(Object.freeze({
        goalId: goal.goal_id, order: goal.priority_order, status: goal.status,
        statusLabel: (COPY[language] || COPY.ru).goal[goal.status],
        weeklyComplete: goal.weekly_commitment_complete,
        correctionOpen: goal.correction_open,
        finalizedSessions: goal.finalized_sessions,
        actionPriorityOrder: goal.action_priority_order,
        retestDueAt: goal.retest_due_at,
        correctionNote: goal.weekly_commitment_complete && goal.correction_open
          ? (COPY[language] || COPY.ru).correctionPending : null
      }));
    }
    if (!validNonnegativeInteger(payload.completed_goals) || completed !== payload.completed_goals) return bad('completion_mismatch');
    goals.sort((a, b) => a.order - b.order);
    const c = COPY[language] || COPY.ru;
    return Object.freeze({
      ok: true, component, activeWeek: payload.active_week_no,
      totalGoals: goals.length, completedGoals: completed,
      hasPlan: payload.plan_available === true && goals.length > 0,
      goalCounter: payload.plan_available === true && goals.length > 0
        ? (language === 'en' ? `${completed} of ${goals.length}` : language === 'uz'
          ? `${goals.length} tadan ${completed} tasi` : `${completed} из ${goals.length}`) : null,
      finalizedSessions: payload.finalized_study_sessions,
      openCorrections: payload.open_corrections,
      confirmedSkills: payload.confirmed_skills,
      totalCanonicalSkills: COMPONENT_COUNTS[component],
      coveragePct: payload.coverage_pct,
      labels: c,
      goals: Object.freeze(goals),
      note: payload.plan_available === true && goals.length > 0 ? null : c.noPlan
    });
  }

  const api = Object.freeze({ normalize, componentCounts: COMPONENT_COUNTS });
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (global) global.iClubExamPrepProgressUxModel = api;
})(typeof window === 'undefined' ? null : window);
