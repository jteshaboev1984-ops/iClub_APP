/* Optional controlled-beta Progress UX API. Never updates canonical evidence. */
(() => {
  'use strict';
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const METHODS = Object.freeze({
    snapshot: 'ensure_exam_prep_weekly_goals_safe_v1',
    progress: 'get_exam_prep_weekly_progress_safe_v1'
  });
  const READ_DEADLINE_MS = 15000;
  const WRITE_DEADLINE_MS = 30000;
  const WATCHDOG_VERSION = 'exam_prep_request_deadlines_v1';
  const WRITE_METHODS = new Set([
    'grantBetaConsent', 'revokeBetaConsent', 'saveExamProfile',
    'startNextDiagnostic', 'startSession', 'submitResponse', 'finalizeSession',
    'recordIntegrityEvent', 'recordInterruption', 'authorizeRevalidationItem',
    'generateWeeklyPlan', 'authorizePlanItem', 'authorizeTimed',
    'finalizeTimed', 'submitTimedSelfMark'
  ]);

  function failure(reason) { return Object.freeze({ ok: false, reason }); }
  function ready(component) {
    if (window.iClubExamPrepProgressUxEnabled !== true) return failure('progress_ux_disabled');
    if (component !== 'P1' && component !== 'P5') return failure('invalid_component');
    const caps = internal.lastCapabilities;
    if (!caps || caps.coreAccess !== true || caps.killSwitch !== false ||
      caps.rolloutState !== 'controlled_beta') return failure('core_access_unavailable');
    return null;
  }
  // Bound the wait without automatically retrying a potentially committed write.
  // A write deadline means its final state is UNKNOWN; reopening reads the server.
  function bounded(operation, duration, timeoutReason) {
    let timer;
    const work = Promise.resolve().then(operation).catch(() => failure('network_unavailable'));
    const deadline = new Promise(resolve => {
      timer = setTimeout(() => resolve(failure(timeoutReason)), duration);
    });
    return Promise.race([work, deadline]).finally(() => clearTimeout(timer));
  }
  function guardCoreApi() {
    if (window.iClubExamPrepProgressUxEnabled !== true) return;
    const base = internal.api;
    if (!base || base.requestDeadlineVersion === WATCHDOG_VERSION) return;
    const next = { ...base };
    Object.entries(base).forEach(([name, method]) => {
      if (typeof method !== 'function') return;
      const write = WRITE_METHODS.has(name);
      next[name] = (...args) => bounded(
        () => method.apply(base, args),
        write ? WRITE_DEADLINE_MS : READ_DEADLINE_MS,
        write ? 'write_status_unknown' : 'rpc_timeout'
      );
    });
    next.requestDeadlineVersion = WATCHDOG_VERSION;
    internal.api = Object.freeze(next);
  }
  guardCoreApi();

  async function rpc(name, component) {
    const blocked = ready(component);
    if (blocked) return blocked;
    const client = window.sb;
    if (!client || typeof client.rpc !== 'function') return failure('server_unavailable');
    const result = await bounded(
      () => client.rpc(name, { p_component_code: component }),
      name === METHODS.snapshot ? WRITE_DEADLINE_MS : READ_DEADLINE_MS,
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
  // Existing Core plan is authoritative; a goal snapshot never fabricates one.
  async function progress(component) {
    const blocked = ready(component);
    if (blocked) return blocked;
    guardCoreApi();
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
  internal.progressUxRequestDeadlines = Object.freeze({ version: WATCHDOG_VERSION,
    readMs: READ_DEADLINE_MS, writeMs: WRITE_DEADLINE_MS });
})();
