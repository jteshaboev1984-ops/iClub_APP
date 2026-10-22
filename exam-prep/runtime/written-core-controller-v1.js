/*
 * iClub Exam Prep — dormant written Core controller v1.
 * NOT imported by production. Injected API must server-authorize plan/task,
 * enforce criteria visibility and guarantee idempotent advancement.
 */
(function (root, make) {
  'use strict';
  if (typeof module === 'object' && module.exports) module.exports = make();
  else root.iClubWrittenCoreControllerV1 = make();
}(typeof globalThis === 'object' ? globalThis : this, function () {
  'use strict';
  const text = v => typeof v === 'string' && v.trim() ? v.trim() : null;
  function validate(d) {
    if (!d || d.task_kind !== 'written_external'
      || ![d.task_token,d.task_key,d.task_version,d.plan_item_id,d.program_key,d.program_version].every(text))
      throw new Error('written_task_unavailable');
    if (d.runtime_enabled !== true || d.can_advance !== true)
      throw new Error('written_core_disabled');
    return Object.freeze({
      task_token:d.task_token,task_key:d.task_key,task_version:d.task_version,
      plan_item_id:d.plan_item_id,program_key:d.program_key,program_version:d.program_version,
      paper_code:text(d.paper_code),question:d.question,
      status:d.status === 'advanced' ? 'advanced' : 'active'
    });
  }
  function create({api,createActionKey} = {}) {
    if (!api || !['open','criteria','advance','status'].every(k=>typeof api[k]==='function')
      || typeof createActionKey !== 'function') throw new Error('written_core_api_incomplete');
    let task=null,pending=null,criteriaCache=null;
    const snapshot=()=>Object.freeze({
      loaded:!!task,task_key:task?.task_key||null,plan_item_id:task?.plan_item_id||null,
      status:task?.status||'unloaded',saving:!!pending,criteria_loaded:!!criteriaCache
    });
    function payload() {
      if (!task) throw new Error('task_not_open');
      return {task_token:task.task_token,task_key:task.task_key,
        task_version:task.task_version,plan_item_id:task.plan_item_id};
    }
    async function open(planItemId) {
      if (pending) throw new Error('advance_in_progress');
      if (!text(planItemId)) throw new Error('invalid_plan_item');
      const result=validate(await api.open({plan_item_id:planItemId}));
      if (result.plan_item_id!==planItemId) throw new Error('plan_item_mismatch');
      task=result;criteriaCache=null;return snapshot();
    }
    async function criteria() {
      if (!task) throw new Error('task_not_open');
      if (criteriaCache) return criteriaCache;
      // Server enforces study/timed access and task/version QA status.
      const result=await api.criteria(payload());
      if (!result || result.available!==true || result.task_key!==task.task_key
        || result.task_version!==task.task_version
        || !Array.isArray(result.requirements) || !result.requirements.length
        || !result.requirements.every(text)) throw new Error('criteria_unavailable');
      criteriaCache=Object.freeze({
        title:text(result.title),requirements:Object.freeze([...result.requirements])
      });
      return criteriaCache;
    }
    async function reconcile(params) {
      const response=await api.status(params);
      if (!response || response.task_key!==task.task_key
        || response.task_version!==task.task_version
        || response.plan_item_id!==task.plan_item_id
        || response.program_version!==task.program_version)
        throw new Error('reconcile_mismatch');
      return response.status==='advanced';
    }
    async function next() {
      if (!task) throw new Error('task_not_open');
      if (task.status==='advanced') return Object.freeze({status:'advanced',replayed:true});
      if (pending) return pending;
      const key=text(createActionKey());
      if (!key) throw new Error('missing_action_key');
      const params=Object.freeze({...payload(),idempotency_key:key});
      pending=(async()=>{
        try {
          const response=await api.advance(params);
          if (!response || response.status!=='advanced'
            || response.plan_item_id!==task.plan_item_id
            || response.task_key!==task.task_key
            || response.task_version!==task.task_version)
            throw new Error('advance_not_confirmed');
          // Untrusted grade/mastery/mentor/AI metadata is never surfaced.
          task=Object.freeze({...task,status:'advanced'});
          return Object.freeze({status:'advanced',replayed:!!response.replayed});
        } catch (_) {
          // The network may lose a response after the write committed.
          try {
            if (await reconcile(payload())) {
              task=Object.freeze({...task,status:'advanced'});
              return Object.freeze({status:'advanced',recovered:true});
            }
          } catch (_) { /* status not confirmed */ }
          throw new Error('advance_unconfirmed');
        } finally { pending=null; }
      })();
      return pending;
    }
    return Object.freeze({open,criteria,next,snapshot});
  }
  return Object.freeze({create});
}));
