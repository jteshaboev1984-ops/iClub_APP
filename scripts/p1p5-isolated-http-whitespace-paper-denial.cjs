#!/usr/bin/env node
'use strict';
// Issue #450 P4-07: isolated signed P1/P5 HTTP negative AFTER the existing
// three authentic full Papers + exact four-Paper empty negative and P4-06 gate.
// A persisted whitespace-only {text:...} cannot become performed written work.
// Keeps original Paper count, unknown marks, learner history, and Core stage.
// CI disposable PostgreSQL17 only, with no production credentials.
const assert=require('node:assert/strict');
const {
  RUN,jwt,rpc,ok,row,list,proveSignedTimedClock
}=require('./p1p5-isolated-http-positive-mixed-timed.cjs');

async function run(){
  assert.equal(process.env.P1P5_E2E_ISOLATED,'true','disposable E2E only');
  const actor=row("SELECT user_id::text uid,identity_status FROM private.exam_prep_synthetic_identities "+
    "WHERE run_id='"+RUN+"'");
  assert(actor?.identity_status==='active' && /^[a-f0-9-]{36}$/.test(actor.uid),
    'P4-07 signed synthetic learner required');
  const owner=jwt(actor.uid);
  const other=jwt('22222222-2222-4222-8222-222222222292');

  for(const component of ['P1','P5']){
    const before=row("SELECT operational_stage stage,app_readiness_estimate estimate "+
      "FROM private.exam_prep_stage_states WHERE user_id='"+actor.uid+"'::uuid "+
      "AND component_code='"+component+"' AND engine_version='objective_state_v1'");
    assert(before?.stage===6 && before.estimate==='INSUFFICIENT_EVIDENCE',
      'P4-07 needs completed Core stage but ungraded written paper');

    const existing=list("SELECT s.assessment_id id, "+
      "private.exam_prep_timed_execution_comparable_v1(s.id) executed "+
      "FROM private.exam_prep_sessions s "+
      "JOIN private.exam_prep_timed_attempt_results t ON t.session_id=s.id "+
      "WHERE s.user_id='"+actor.uid+"'::uuid AND s.component_code='"+component+"' "+
      "AND s.status='finalized' AND s.session_type='paper' AND t.attempt_kind='full_paper'");
    assert(existing.length===4 && existing.filter(x=>x.executed).length===3,
      'P4-07 cannot alter earlier 3 executed + 1 skipped Paper baseline');
    const catalog=ok(await rpc('get_exam_prep_timed_catalog_safe_v1',{
      p_component_code:component
    },owner),'P4-07 governed timed catalog '+component);
    const used=new Set(existing.map(x=>x.id));
    const candidates=catalog.assessments.filter(x=>
      x.attempt_kind==='full_paper' && x.comparison_scope==='full' && x.strict_timing===true);
    // Stage6 may offer the same four published forms again under a NEW
    // signed authorization. Never require an unavailable fifth form.
    const candidate=candidates.find(x=>!used.has(x.assessment_id))
      || candidates.find(x=>used.has(x.assessment_id));
    assert(candidate,'P4-07 requires a real published Paper, no source fabrication');

    const prefix='p407-whitespace-'+component.toLowerCase();
    const auth=ok(await rpc('authorize_exam_prep_timed_safe_v1',{
      p_assessment_id:candidate.assessment_id
    },owner),'P4-07 signed paper authorization '+component);
    const start=ok(await rpc('start_exam_prep_session_safe_v1',{
      p_authorization_id:auth.authorization_id,
      p_idempotency_key:prefix+'-start'
    },owner),'P4-07 signed paper start '+component);
    await proveSignedTimedClock(start.session_id,owner,other,component,'paper');

    const item=list("SELECT item_order ord FROM private.exam_prep_session_items "+
      "WHERE session_id='"+start.session_id+"'::uuid AND item_kind='written' "+
      "ORDER BY item_order LIMIT 1")[0];
    assert(item?.ord>0,'P4-07 expected source-authentic written Paper item');
    ok(await rpc('submit_exam_prep_response_safe_v1',{
      p_session_id:start.session_id,p_item_order:item.ord,
      p_payload:{artifact:{text:'  \t\n  '}},
      p_idempotency_key:prefix+'-item-1',p_elapsed_ms:1200,
      p_language:component==='P1'?'ru':'uz'
    },owner),'P4-07 genuine persisted whitespace-only answer '+component);

    await new Promise(resolve=>setTimeout(resolve,1300));
    const finalized=ok(await rpc('finalize_exam_prep_timed_safe_v1',{
      p_session_id:start.session_id,p_idempotency_key:prefix+'-final',
      p_completion_reason:'submitted'
    },owner),'P4-07 genuine signed paper finalizer '+component);
    assert(finalized.replayed===false,'P4-07 initial finalization unexpectedly replayed');
    const result=ok(await rpc('get_exam_prep_timed_result_safe_v1',{
      p_session_id:start.session_id
    },owner),'P4-07 learner Paper result '+component);
    assert(result.answered_items===1 && result.unattempted_items>0 &&
      result.objective_marks_in_time===0,
      'P4-07 must preserve ungraded historical answer without fake objective marks');

    const proof=row("SELECT private.exam_prep_timed_execution_comparable_v1('"+
      start.session_id+"'::uuid) AS executed, "+
      "private.exam_prep_timed_score_comparable_v1('"+
      start.session_id+"'::uuid) AS scored, "+
      "(SELECT count(*)::int FROM private.exam_prep_responses WHERE session_id='"+
      start.session_id+"'::uuid AND response_kind='written') AS saved");
    assert(proof?.saved===1 && proof.executed===false && proof.scored===false,
      'P4-07 whitespace-only answer was improperly counted as performed or graded');

    const counted=row("SELECT private.exam_prep_stage4_raw_evidence_v1("+
      "p.user_id,p.program_version_id,'"+component+"') AS data "+
      "FROM private.exam_prep_exam_profiles p WHERE p.user_id='"+actor.uid+"'::uuid");
    const after=row("SELECT operational_stage stage,app_readiness_estimate estimate "+
      "FROM private.exam_prep_stage_states WHERE user_id='"+actor.uid+"'::uuid "+
      "AND component_code='"+component+"' AND engine_version='objective_state_v1'");
    assert(Number(counted?.data?.max_compatible_family_attempt_count)===3 &&
      after?.stage===6 && after.estimate==='INSUFFICIENT_EVIDENCE',
      'P4-07 corrupted separate execution count or made a readiness claim');
    const foreign=await rpc('get_exam_prep_timed_result_safe_v1',{
      p_session_id:start.session_id
    },other);
    const anon=await rpc('get_exam_prep_timed_result_safe_v1',{
      p_session_id:start.session_id
    });
    assert(!foreign.ok && !anon.ok,'P4-07 paper history exposed cross-user or anonymously');
  }
  console.log('P4-07 SIGNED WHITESPACE PAPER NEGATIVE PASS',
    JSON.stringify({P1:true,P5:true,realJwt:true,postgrest:true,
      persistedNoncredit:true,executionFalse:true,scoredFalse:true,
      genuinePaperCount:3,readiness:'INSUFFICIENT_EVIDENCE',
      serverAuthorizedPaper:true,ownerOnly:true}));
}
run().catch(error=>{
  console.error('P4-07 SIGNED WHITESPACE PAPER NEGATIVE FAILED:',error.message);
  process.exitCode=1;
});
