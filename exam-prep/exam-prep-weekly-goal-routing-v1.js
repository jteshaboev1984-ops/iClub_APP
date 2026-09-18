/* Pure, read-only routing contract. Never grants access or writes academic state. */
(function (global) {
  'use strict';
  const TYPES = new Set(['learning', 'correction', 'retest', 'mixed_transfer']);
  const isPositiveOrder = n => Number.isInteger(n) && n >= 1 && n <= 3;
  const fail = reason => Object.freeze({ok:false, reason});
  const nonempty = value => typeof value === 'string' && value.trim().length > 0;

  function resolve({component, progress, goal, plan, eligibility, now = Date.now()} = {}) {
    if (component !== 'P1' && component !== 'P5') return fail('bad_component');
    if (!progress || progress.contract_version !== 'progress_ux_v1' || progress.component_code !== component ||
        !Number.isInteger(progress.active_week_no) || !Array.isArray(progress.goals)) return fail('bad_progress');
    if (!goal || !nonempty(goal.goal_id) || goal.component_code !== component ||
        !progress.goals.some(row => row.goal_id === goal.goal_id)) return fail('foreign_goal');
    if (!plan || !nonempty(plan.plan_id) || plan.component_code !== component ||
        plan.active_week_no !== progress.active_week_no || !Array.isArray(plan.items)) return fail('stale_plan');
    if (!isPositiveOrder(goal.action_priority_order)) return fail('no_current_action');
    if (!TYPES.has(goal.item_type) || !nonempty(goal.skill_code)) return fail('not_actionable');
    if (goal.status === 'completed' || goal.status === 'paused' || goal.status === 'replaced' ||
        goal.status === 'unavailable') return fail('goal_not_open');
    const target = plan.items.filter(item => item.priority_order === goal.action_priority_order && item.status === 'pending');
    if (target.length !== 1) return fail('action_not_unique');
    const item = target[0];
    if (item.skill_code !== goal.skill_code) return fail('skill_changed');
    if (!(item.item_type === goal.item_type || (goal.item_type === 'correction' && item.item_type === 'retest')))
      return fail('action_changed');
    // A goal can be re-ordered. A skill/type pair is not an identity if it occurs twice.
    const twins = plan.items.filter(row => row.status === 'pending' && row.skill_code === goal.skill_code &&
      (row.item_type === goal.item_type || (goal.item_type === 'correction' && row.item_type === 'retest')));
    if (twins.length !== 1) return fail('ambiguous_binding');
    const delayedTransition = goal.item_type === 'correction' && item.item_type === 'retest' && goal.status === 'waiting_retest';
    if (goal.item_type === 'correction' && item.item_type === 'retest' && !delayedTransition)
      return fail('retest_transition_unconfirmed');
    if (goal.weekly_commitment_complete === true && !delayedTransition) return fail('goal_not_open');
    if (item.item_type === 'retest') {
      const due = Date.parse(item.due_at || '');
      if (!Number.isFinite(due) || !Number.isFinite(now) || due > now) return fail('retest_not_due');
    }
    if (!eligibility || eligibility.component_code !== component || eligibility.plan_id !== plan.plan_id ||
        eligibility.goal_id !== goal.goal_id || eligibility.priority_order !== item.priority_order ||
        eligibility.skill_code !== item.skill_code || eligibility.item_type !== item.item_type)
      return fail('eligibility_not_verified');
    // Server-side status is a hint for UX only. The existing authorized RPC remains final authority.
    if (eligibility.status === 'resume' && nonempty(eligibility.session_id))
      return Object.freeze({ok:true, action:'resume', sessionId:eligibility.session_id});
    if (eligibility.status !== 'ready') return fail(nonempty(eligibility.reason) ? eligibility.reason : 'server_not_ready');
    return Object.freeze({ok:true, action:'launch', planId:plan.plan_id, priorityOrder:item.priority_order});
  }
  const api = Object.freeze({version:'weekly_goal_routing_v1', resolve});
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  if (global) global.iClubExamPrepWeeklyGoalRouting = api;
})(typeof window === 'undefined' ? null : window);
