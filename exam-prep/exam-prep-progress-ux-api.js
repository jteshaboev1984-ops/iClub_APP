(() => {
  'use strict';
  // Loaded only by the optional Progress UX integration. No automatic academic writes.
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const METHODS = Object.freeze({
    snapshot: 'ensure_exam_prep_weekly_goals_safe_v1',
    progress: 'get_exam_prep_weekly_progress_safe_v1'
  });

  function failure(reason) { return Object.freeze({ ok: false, reason }); }
  function ready(component) {
    if (window.iClubExamPrepProgressUxEnabled !== true) return failure('progress_ux_disabled');
    if (component !== 'P1' && component !== 'P5') return failure('invalid_component');
    const caps = internal.lastCapabilities;
    if (!caps || caps.coreAccess !== true || caps.killSwitch !== false ||
      caps.rolloutState !== 'controlled_beta') return failure('core_access_unavailable');
    return null;
  }
  async function rpc(name, component) {
    const blocked = ready(component);
    if (blocked) return blocked;
    const client = window.sb;
    if (!client || typeof client.rpc !== 'function') return failure('server_unavailable');
    try {
      const { data, error } = await client.rpc(name, { p_component_code: component });
      if (error) return failure('server_rejected');
      if (ready(component)) return failure('access_revoked');
      if (!data || typeof data !== 'object' || data.component_code !== component ||
          data.contract_version !== 'progress_ux_v1') return failure('invalid_server_contract');
      return Object.freeze({ ok: true, data });
    } catch (_) { return failure('network_unavailable'); }
  }
  // Caller first obtains the existing governed plan. A missing plan is never
  // manufactured here. If that plan exists, snapshotting is idempotent and only
  // inserts the NEW private presentation ledger through a Core-entitled RPC.
  async function progress(component) {
    const blocked = ready(component);
    if (blocked) return blocked;
    const existing = internal.api?.weeklyPlan;
    if (typeof existing !== 'function') return failure('planner_unavailable');
    let plan;
    try { plan = await existing(component); } catch (_) { return failure('planner_unavailable'); }
    if (ready(component)) return failure('access_revoked');
    if (!plan?.ok) return failure('planner_unavailable');
    if (plan.data?.plan_id) {
      const anchored = await rpc(METHODS.snapshot, component);
      if (!anchored.ok) return anchored;
    }
    return rpc(METHODS.progress, component);
  }
  internal.progressUxApi = Object.freeze({ progress });
})();
