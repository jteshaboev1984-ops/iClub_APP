/* Exam Prep weekly-flow opt-in adapter. NOT enabled by default, not a release switch.
 * Dedicated methods only: never replace internal.api or intercept a Core RPC.
 * Requires separately approved/installed server proposal RPCs before use.
 */
(() => {
  'use strict';
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const CONTRACT = 'weekly_flow_adapter_v1';
  if (internal.weeklyFlowApi) return;

  const fail = (reason, detail) => Object.freeze({ ok: false, reason, ...(detail ? { detail } : {}) });
  function allowed(component) {
    if (window.iClubExamPrepWeeklyFlowEnabled !== true) return fail('weekly_flow_disabled');
    if (component !== 'P1' && component !== 'P5') return fail('invalid_component');
    const caps = internal.lastCapabilities;
    if (!caps || caps.coreAccess !== true || caps.killSwitch !== false || caps.rolloutState !== 'controlled_beta') {
      return fail('core_access_unavailable');
    }
    return null;
  }
  async function rpc(component, name, args) {
    const blocked = allowed(component);
    if (blocked) return blocked;
    const client = window.sb;
    if (!client || typeof client.rpc !== 'function') return fail('server_unavailable');
    try {
      const { data, error } = await client.rpc(name, args);
      if (allowed(component)) return fail('access_revoked');
      if (error) return fail('server_rejected');
      if (!data || typeof data !== 'object' || Array.isArray(data)) return fail('invalid_server_contract');
      if (data.component_code && data.component_code !== component) return fail('component_mismatch');
      return Object.freeze({ ok: true, data });
    } catch (_) {
      return fail('network_unavailable');
    }
  }
  function identity(value) {
    return typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
  }
  function recoveryStatus(data) {
    return data && ['resume', 'ready_to_finalize', 'multiple_active'].includes(data.status);
  }
  // Read server state before a new plan or goal. Never reconstruct from localStorage.
  async function recover(component) {
    const result = await rpc(component, 'get_exam_prep_active_plan_session_safe_v1', { p_component_code: component });
    if (!result.ok) return result;
    const data = result.data;
    if (!['none', 'resume', 'ready_to_finalize', 'multiple_active'].includes(data.status)) return fail('invalid_recovery_state');
    if ((data.status === 'resume' || data.status === 'ready_to_finalize') && !identity(data.session_id)) {
      return fail('invalid_session_identity');
    }
    return result;
  }
  async function plan(component) {
    const recovery = await recover(component);
    if (!recovery.ok) return recovery;
    if (recoveryStatus(recovery.data)) return Object.freeze({ ok: true, data: { status: 'resume_first', recovery: recovery.data } });
    const result = await rpc(component, 'ensure_exam_prep_stable_weekly_plan_safe_v1', { p_component_code: component });
    if (!result.ok) return result;
    if (result.data.status === 'resume_first' && recoveryStatus(result.data.recovery)) return result;
    if (!['existing', 'created'].includes(result.data.status) || !identity(result.data.plan_id) ||
        result.data.contract_version !== 'stable_weekly_plan_v1') return fail('invalid_plan_contract');
    return result;
  }
  async function goal(component, goalId, planId) {
    if (!identity(goalId) || !identity(planId)) return fail('invalid_goal_identity');
    return rpc(component, 'get_exam_prep_goal_action_state_safe_v1', {
      p_component_code: component, p_goal_id: goalId, p_plan_id: planId
    });
  }
  async function authorize(component, goalId, planId) {
    if (!identity(goalId) || !identity(planId)) return fail('invalid_goal_identity');
    const recovery = await recover(component);
    if (!recovery.ok) return recovery;
    if (recoveryStatus(recovery.data)) {
      return Object.freeze({ ok: true, data: { status: 'resume_existing_session_first', recovery: recovery.data } });
    }
    const result = await rpc(component, 'authorize_exam_prep_goal_once_safe_v1', {
      p_component_code: component, p_goal_id: goalId, p_plan_id: planId
    });
    if (!result.ok) return result;
    if (result.data.status === 'authorized' && !identity(result.data.authorization_id)) return fail('invalid_authorization_identity');
    if (result.data.status === 'review_ready' && (
      result.data.component_code !== component || result.data.goal_id !== goalId ||
      result.data.plan_id !== planId || result.data.fresh_assessment !== false ||
      result.data.reason !== 'same_pack_learning_review' ||
      !['learning','correction'].includes(result.data.item_type))) return fail('invalid_review_contract');
    if (!['authorized', 'stale', 'waiting', 'resume', 'attempt_already_saved', 'content_exhausted',
      'review_ready'].includes(result.data.status)) {
      return fail('invalid_authorization_status');
    }
    return result;
  }
  async function start(component, authorizationId, idempotencyKey) {
    if (!identity(authorizationId)) return fail('invalid_authorization_identity');
    if (typeof idempotencyKey !== 'string' || idempotencyKey.length < 8 || idempotencyKey.length > 160) {
      return fail('invalid_idempotency_key');
    }
    const result = await rpc(component, 'start_exam_prep_plan_session_once_safe_v1', {
      p_authorization_id: authorizationId, p_idempotency_key: idempotencyKey
    });
    if (!result.ok) {
      // The start may already have committed when the connection disappeared.
      // Re-read state; never blindly resend a write with a new key.
      if (!['network_unavailable', 'server_rejected', 'invalid_server_contract'].includes(result.reason)) return result;
      const recovery = await recover(component);
      return Object.freeze({ ok: false, reason: 'start_outcome_unknown', recovery: recovery.ok ? recovery.data : null });
    }
    if (['started', 'resume', 'resume_existing_session_first'].includes(result.data.status) &&
        !identity(result.data.session_id)) return fail('invalid_start_session_identity');
    if (!['started', 'resume', 'resume_existing_session_first', 'multiple_active', 'attempt_already_saved',
      'reconciliation_required', 'authorization_unavailable', 'authorization_expired',
      'stale', 'content_exhausted'].includes(result.data.status)) return fail('invalid_start_status');
    return result;
  }

  // The same questions may be repeated for an unresolved learning/correction
  // goal ONLY through the separately enrolled noncredit server endpoint.
  // Do not manufacture a second original authorization or claim fresh evidence.
  async function review(component, goalId, planId, idempotencyKey) {
    if (!identity(goalId) || !identity(planId)) return fail('invalid_goal_identity');
    if (typeof idempotencyKey !== 'string' || idempotencyKey.length < 8 || idempotencyKey.length > 160) {
      return fail('invalid_idempotency_key');
    }
    const recovery = await recover(component);
    if (!recovery.ok) return recovery;
    if (recoveryStatus(recovery.data)) {
      return Object.freeze({ ok: true, data: { status: 'resume_existing_session_first', recovery: recovery.data } });
    }
    const result = await rpc(component, 'start_exam_prep_learning_review_safe_v1', {
      p_component_code: component, p_goal_id: goalId, p_plan_id: planId,
      p_idempotency_key: idempotencyKey
    });
    if (!result.ok) {
      if (!['network_unavailable', 'server_rejected', 'invalid_server_contract'].includes(result.reason)) return result;
      const observed = await recover(component);
      return Object.freeze({ ok: false, reason: 'review_outcome_unknown',
        recovery: observed.ok ? observed.data : null });
    }
    const data = result.data;
    if (data.status === 'started' && (
      !identity(data.session_id) || data.component_code !== component ||
      data.goal_id !== goalId || data.plan_id !== planId ||
      data.repeat_learning !== true || data.academic_credit !== false ||
      data.prior_progress_retained !== true || data.not_a_new_independent_check !== true)) {
      return fail('invalid_review_start_contract');
    }
    if (data.status === 'resume_existing_session_first' && !identity(data.session_id)) {
      return fail('invalid_review_resume_contract');
    }
    if (!['started','resume_existing_session_first','multiple_active','attempt_already_saved',
      'waiting','stale'].includes(data.status)) return fail('invalid_review_status');
    if (data.status !== 'started' && data.status !== 'resume_existing_session_first' && data.session_id) {
      return fail('unexpected_review_session_identity');
    }
    return result;
  }

  // Read-only previous-week verdict. Any incomplete or contradictory backend
  // response must suppress the learner warning, never guess from a local clock.
  async function adherence(component) {
    const result = await rpc(component, 'get_exam_prep_previous_week_adherence_safe_v1', {
      p_component_code: component
    });
    if (!result.ok) return result;
    const data = result.data;
    const quiet = ['not_due','no_verified_plan','ambiguous_plan','unverifiable_goals'];
    const measurable = ['no_due_goals','completed_on_time','caught_up','missed'];
    if (data.contract_version !== 'previous_week_adherence_v1' || data.component_code !== component ||
        typeof data.can_alert !== 'boolean' || ![...quiet,...measurable].includes(data.status) ||
        data.can_alert !== (data.status === 'missed')) return fail('invalid_adherence_contract');
    if (measurable.includes(data.status)) {
      const due = data.scheduled_goals;
      const onTime = data.completed_by_deadline;
      const nowDone = data.completed_now;
      if (!Number.isInteger(data.active_week_no) || data.active_week_no < 1 || data.active_week_no > 35 ||
          !Number.isInteger(due) || due < 0 || due > 3 ||
          !Number.isInteger(onTime) || onTime < 0 || onTime > due ||
          !Number.isInteger(nowDone) || nowDone < onTime || nowDone > due ||
          (data.status === 'missed' && (due === 0 || nowDone === due)) ||
          (data.status === 'caught_up' && (due === 0 || nowDone !== due || onTime === due)) ||
          (data.status === 'completed_on_time' && (due === 0 || onTime !== due)) ||
          (data.status === 'no_due_goals' && due !== 0) ||
          typeof data.week_ended_at !== 'string' || !Number.isFinite(Date.parse(data.week_ended_at))) {
        return fail('invalid_adherence_contract');
      }
    }
    return result;
  }

  // Exam-series, target and time edits use the existing Exam Plan UI/API.
  // No parallel manual weekly-replan entrypoint is exported.
  internal.weeklyFlowApi = Object.freeze({ version: CONTRACT, allowed, recover, plan, goal, authorize, start, review, adherence });
})();
