/* Optional controlled-beta Progress UX API. Do not replace or wrap Core Exam Prep methods. */
(() => {
  'use strict';
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const METHODS = Object.freeze({
    snapshot: 'ensure_exam_prep_weekly_goals_safe_v1',
    progress: 'get_exam_prep_weekly_progress_safe_v1'
  });
  const READ_DEADLINE_MS = 15000;
  const SNAPSHOT_DEADLINE_MS = 30000;

  function failure(reason) { return Object.freeze({ ok: false, reason }); }
  function ready(component) {
    if (window.iClubExamPrepProgressUxEnabled !== true) return failure('progress_ux_disabled');
    if (component !== 'P1' && component !== 'P5') return failure('invalid_component');
    const caps = internal.lastCapabilities;
    if (!caps || caps.coreAccess !== true || caps.killSwitch !== false ||
      caps.rolloutState !== 'controlled_beta') return failure('core_access_unavailable');
    return null;
  }

  // Only optional presentation requests have deadlines. A timed-out snapshot
  // might have committed; never replay it automatically or change Core state.
  function bounded(operation, duration, timeoutReason) {
    let timer;
    const work = Promise.resolve().then(operation).catch(() => failure('network_unavailable'));
    const deadline = new Promise(resolve => {
      timer = setTimeout(() => resolve(failure(timeoutReason)), duration);
    });
    return Promise.race([work, deadline]).finally(() => clearTimeout(timer));
  }

  async function rpc(name, component) {
    const blocked = ready(component);
    if (blocked) return blocked;
    const client = window.sb;
    if (!client || typeof client.rpc !== 'function') return failure('server_unavailable');
    const result = await bounded(
      () => client.rpc(name, { p_component_code: component }),
      name === METHODS.snapshot ? SNAPSHOT_DEADLINE_MS : READ_DEADLINE_MS,
      name === METHODS.snapshot ? 'write_status_unknown' : 'rpc_timeout'
    );
    if (result?.ok === false) return result;
    const { data, error } = result || {};
    if (error) return failure('server_rejected');
    if (ready(component)) return failure('access_revoked');
    if (!data || typeof data !== 'object' || data.component_code !== component ||
        data.contract_version !== 'progress_ux_v1') return failure('invalid_server_contract');
    return Object.freeze({ ok: true, data });
  }

  // The canonical Core plan and its methods remain owned by Exam Prep.
  async function progress(component) {
    const blocked = ready(component);
    if (blocked) return blocked;
    const existing = internal.api?.weeklyPlan;
    if (typeof existing !== 'function') return failure('planner_unavailable');
    const plan = await bounded(() => existing(component), READ_DEADLINE_MS, 'rpc_timeout');
    if (ready(component)) return failure('access_revoked');
    if (!plan?.ok) return failure(plan?.reason || 'planner_unavailable');
    if (plan.data?.plan_id) {
      const anchored = await rpc(METHODS.snapshot, component);
      if (!anchored.ok) return anchored;
    }
    return rpc(METHODS.progress, component);
  }
  internal.progressUxApi = Object.freeze({ progress });
  internal.progressUxRequestDeadlines = Object.freeze({ readMs: READ_DEADLINE_MS,
    snapshotMs: SNAPSHOT_DEADLINE_MS, coreApiWrapped: false });
})();
