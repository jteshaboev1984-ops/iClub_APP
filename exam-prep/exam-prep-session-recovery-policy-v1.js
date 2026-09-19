/* Pure policy only: no RPCs, no storage, no academic writes, not loaded in production. */
(function (global) {
  'use strict';
  const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  const fail = reason => Object.freeze({ok:false,reason});

  function decide({component,lookup,goalRoute} = {}) {
    if (!['P1','P5'].includes(component)) return fail('bad_component');
    if (!lookup || lookup.contract_version !== 'active_plan_session_v1' ||
        lookup.component_code !== component || !Number.isInteger(lookup.active_session_count) ||
        lookup.active_session_count < 0) return fail('unverified_session_lookup');

    if (lookup.status === 'multiple_active') return fail('multiple_active_sessions');
    if (lookup.status === 'resume' || lookup.status === 'ready_to_finalize') {
      if (lookup.active_session_count !== 1 || typeof lookup.session_id !== 'string' ||
          !uuid.test(lookup.session_id) || !['learning','mixed','retest'].includes(lookup.session_type) ||
          !Number.isInteger(lookup.total_items) || lookup.total_items < 1 ||
          !Number.isInteger(lookup.answered_items) || lookup.answered_items < 0 ||
          lookup.answered_items > lookup.total_items ||
          lookup.resume_independent_of_current_plan !== true) return fail('invalid_resume_evidence');
      const next = lookup.first_unanswered_item_order;
      if (lookup.status === 'resume' && (!Number.isInteger(next) || next < 1 || next > lookup.total_items ||
          lookup.answered_items >= lookup.total_items)) return fail('invalid_resume_position');
      if (lookup.status === 'ready_to_finalize' && (next != null ||
          lookup.answered_items !== lookup.total_items)) return fail('invalid_finalize_position');
      // An active session takes precedence even when its plan was superseded/rolled over.
      // The existing server getSession RPC must still authenticate the returned session ID.
      return Object.freeze({ok:true,action:'resume',sessionId:lookup.session_id,
        firstUnansweredItemOrder:next == null ? null : next});
    }
    if (lookup.status !== 'none' || lookup.active_session_count !== 0 || lookup.session_id != null)
      return fail('unexpected_lookup_state');
    if (!goalRoute || goalRoute.ok !== true || goalRoute.action !== 'launch' ||
        typeof goalRoute.planId !== 'string' || !uuid.test(goalRoute.planId) ||
        !Number.isInteger(goalRoute.priorityOrder) || goalRoute.priorityOrder < 1 || goalRoute.priorityOrder > 3)
      return fail('no_verified_new_action');
    return Object.freeze({ok:true,action:'launch',planId:goalRoute.planId,
      priorityOrder:goalRoute.priorityOrder});
  }

  function reconcileUnknownWrite({writeStatus,serverItem} = {}) {
    if (writeStatus !== 'unknown') return fail('not_unknown_write');
    if (!serverItem || typeof serverItem !== 'object' || typeof serverItem.answered !== 'boolean')
      return fail('server_read_required');
    // A server-confirmed saved response must never be submitted a second time.
    if (serverItem.answered) return Object.freeze({ok:true,action:'saved_do_not_replay'});
    // An unresolved in-flight write may still commit after a read: never auto-replay it.
    return Object.freeze({ok:false,reason:'uncertain_write_do_not_auto_retry'});
  }

  const api = Object.freeze({version:'session_recovery_policy_v1',decide,reconcileUnknownWrite});
  if (typeof module !== 'undefined' && module.exports) module.exports=api;
  if (global) global.iClubExamPrepSessionRecoveryPolicy=api;
})(typeof window === 'undefined' ? null : window);
