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
    if (!['authorized', 'stale', 'waiting', 'resume', 'attempt_already_saved', 'content_exhausted'].includes(result.data.status)) {
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

  // Exam-series, target and time edits use the existing Exam Plan UI/API.
  // No parallel manual weekly-replan entrypoint is exported.
  internal.weeklyFlowApi = Object.freeze({ version: CONTRACT, allowed, recover, plan, goal, authorize, start });
})();
