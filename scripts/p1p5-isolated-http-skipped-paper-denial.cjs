#!/usr/bin/env node
'use strict';
// Issue #450 P4-05 no-credit negative: official Paper started and submitted
// with ZERO learner responses. Its result may exist for audit, but MUST NOT
// count as executed, advance state, or create an exam-readiness claim.
// Uses real JWT -> PostgREST -> published authored Paper. Disposable PG17 only.
const assert=require('node:assert/strict');
const {
 RUN,jwt,rpc,ok,row,list,proveSignedTimedClock
}=require('./p1p5-isolated-http-positive-mixed-timed.cjs');
async function run(){
 const ident=row("SELECT user_id::text uid,identity_status FROM private.exam_prep_synthetic_identities WHERE run_id='"+RUN+"'");
 assert(ident?.identity_status==='active' && /^[a-f0-9-]{36}$/.test(ident.uid),
  'P4-05 negative run requires signed disposable learner');
 const token=jwt(ident.uid),other=jwt('22222222-2222-4222-8222-222222222292');
 for(const component of ['P1','P5']){
   const baseline=row("SELECT operational_stage stage,app_readiness_estimate estimate "+
     "FROM private.exam_prep_stage_states WHERE user_id='"+ident.uid+"'::uuid "+
     "AND component_code='"+component+"' AND engine_version='objective_state_v1'");
   assert(baseline?.stage===6 && baseline.estimate==='INSUFFICIENT_EVIDENCE',
     'P4-05 blank negative requires operational Stage6 but ungraded written readiness');
   const used=new Set(list(
     "SELECT s.assessment_id id FROM private.exam_prep_sessions s "+
     "JOIN private.exam_prep_timed_attempt_results t ON t.session_id=s.id "+
     "WHERE s.user_id='"+ident.uid+"'::uuid AND s.component_code='"+component+"' "+
     "AND s.status='finalized' AND t.attempt_kind='full_paper'"
   ).map(x=>x.id));
   assert(used.size===3,'three distinct legitimate Papers expected before blank negative');
   const catalog=ok(await rpc('get_exam_prep_timed_catalog_safe_v1',{
     p_component_code:component
   },token),'P4-05 governed negative Paper catalog');
   const candidates=catalog.assessments.filter(x=>
     x.attempt_kind==='full_paper' && x.comparison_scope==='full'
     && x.strict_timing===true);
   // A completed, published Paper can be retaken with a NEW real authorization.
   // Prefer an unused form; never fabricate or activate new source content.
   const candidate=candidates.find(x=>!used.has(x.assessment_id))
     || candidates.find(x=>used.has(x.assessment_id));
   assert(candidate,'P4-05 no governed published full Paper for blank negative');
   const prefix='p405-empty-'+component.toLowerCase();
   const auth=ok(await rpc('authorize_exam_prep_timed_safe_v1',{
     p_assessment_id:candidate.assessment_id
   },token),'P4-05 empty paper authorization');
   const start=ok(await rpc('start_exam_prep_session_safe_v1',{
     p_authorization_id:auth.authorization_id,p_idempotency_key:prefix+'-start'
   },token),'P4-05 empty paper signed start');
   await proveSignedTimedClock(start.session_id,token,other,component,'paper');
   // Intentionally submit ZERO item answers. Do not fake any written marks.
   await new Promise(resolve=>setTimeout(resolve,1300));
   const result=ok(await rpc('finalize_exam_prep_timed_safe_v1',{
     p_session_id:start.session_id,p_idempotency_key:prefix+'-final',
     p_completion_reason:'submitted'
   },token),'P4-05 finalize fully unattempted signed paper');
   assert(result.replayed===false,'P4-05 first empty finalization unexpectedly replayed');
   const replay=ok(await rpc('finalize_exam_prep_timed_safe_v1',{
     p_session_id:start.session_id,p_idempotency_key:prefix+'-final',
     p_completion_reason:'submitted'
   },token),'P4-05 empty finalizer same-key replay');
   assert(replay.replayed===true,'P4-05 blank finalization not idempotent');
   const latest=ok(await rpc('get_exam_prep_timed_result_safe_v1',{
     p_session_id:start.session_id
   },token),'P4-05 empty paper result');
   assert(latest.answered_items===0 && latest.unattempted_items>0 &&
     latest.objective_marks_in_time===0,
     'P4-05 paper without answers gained completion or marks');
   const evidence=row("SELECT private.exam_prep_timed_execution_comparable_v1('"+
     start.session_id+"'::uuid) AS executed, "+
     "(SELECT count(*)::int FROM private.exam_prep_responses WHERE session_id='"+
       start.session_id+"'::uuid) AS saved");
   assert(evidence?.executed===false && evidence.saved===0,
     'P4-05 blank Paper falsely execution-comparable');
   const stage=row("SELECT operational_stage stage,app_readiness_estimate estimate "+
     "FROM private.exam_prep_stage_states WHERE user_id='"+ident.uid+"'::uuid "+
     "AND component_code='"+component+"' AND engine_version='objective_state_v1'");
   assert(stage?.stage===6 && stage.estimate==='INSUFFICIENT_EVIDENCE',
     'P4-05 blank paper changed operational stage or fabricated readiness');
   const foreign=await rpc('get_exam_prep_timed_result_safe_v1',{
     p_session_id:start.session_id
   },other);
   assert(!foreign.ok,'P4-05 cross-user blank-paper result exposure');

   // P4-07 adversarial E2E: the PUBLIC signed RPC still records a student's
   // whitespace-only text artifact for audit, but it must not earn an
   // execution-comparable Paper, a mark, or additional Paper-count credit.
   // This closes an existing false positive, not a new learner access gate.
   const next=candidates.find(x=>!used.has(x.assessment_id)
      && x.assessment_id!==candidate.assessment_id) || candidate;
   const wp='p407-space-'+component.toLowerCase();
   const wa=ok(await rpc('authorize_exam_prep_timed_safe_v1',{
     p_assessment_id:next.assessment_id
   },token),'P4-07 signed whitespace paper authorization '+component);
   const ws=ok(await rpc('start_exam_prep_session_safe_v1',{
     p_authorization_id:wa.authorization_id,p_idempotency_key:wp+'-start'
   },token),'P4-07 signed whitespace paper start '+component);
   await proveSignedTimedClock(ws.session_id,token,other,component,'paper');
   const firstWritten=list("SELECT item_order ord FROM private.exam_prep_session_items "+
     "WHERE session_id='"+ws.session_id+"'::uuid AND item_kind='written' "+
     "ORDER BY item_order LIMIT 1")[0];
   assert(firstWritten?.ord>0,'P4-07 expected original written Paper content');
   ok(await rpc('submit_exam_prep_response_safe_v1',{
     p_session_id:ws.session_id,p_item_order:firstWritten.ord,
     p_payload:{artifact:{text:'  \t\n  '}},
     p_idempotency_key:wp+'-item-1',p_elapsed_ms:1200,
     p_language:component==='P1'?'ru':'uz'
   },token),'P4-07 genuine persisted whitespace written response '+component);
   await new Promise(resolve=>setTimeout(resolve,1300));
   const wf=ok(await rpc('finalize_exam_prep_timed_safe_v1',{
     p_session_id:ws.session_id,p_idempotency_key:wp+'-final',
     p_completion_reason:'submitted'
   },token),'P4-07 real whitespace-paper finalization '+component);
   assert(wf.replayed===false,'P4-07 whitespace first finalizer replayed');
   const wr=ok(await rpc('get_exam_prep_timed_result_safe_v1',{
     p_session_id:ws.session_id
   },token),'P4-07 whitespace Paper result '+component);
   assert(wr.answered_items===1 && wr.unattempted_items>0 &&
     wr.objective_marks_in_time===0,
     'P4-07 whitespace Paper was not persisted as one ungraded historical response');
   const wproof=row("SELECT private.exam_prep_timed_execution_comparable_v1('"+
      ws.session_id+"'::uuid) AS executed, "+
      "private.exam_prep_timed_score_comparable_v1('"+
      ws.session_id+"'::uuid) AS scored, "+
      "(SELECT count(*)::int FROM private.exam_prep_responses WHERE session_id='"+
      ws.session_id+"'::uuid AND response_kind='written') AS saved");
   assert(wproof?.saved===1 && wproof.executed===false && wproof.scored===false,
     'P4-07 whitespace-only task improperly counted as performed or scored');
   const unchanged=row("SELECT operational_stage stage,app_readiness_estimate estimate "+
     "FROM private.exam_prep_stage_states WHERE user_id='"+ident.uid+"'::uuid "+
     "AND component_code='"+component+"' AND engine_version='objective_state_v1'");
   const count=row("SELECT private.exam_prep_stage4_raw_evidence_v1("+
     "p.user_id,p.program_version_id,'"+component+"') AS data "+
     "FROM private.exam_prep_exam_profiles p WHERE p.user_id='"+ident.uid+"'::uuid");
   assert(unchanged?.stage===6 && unchanged.estimate==='INSUFFICIENT_EVIDENCE'
     && Number(count?.data?.max_compatible_family_attempt_count)===3,
     'P4-07 whitespace Paper changed Stage6, readiness or genuine three-Paper count');
   const foreignWhitespace=await rpc('get_exam_prep_timed_result_safe_v1',{
     p_session_id:ws.session_id
   },other);
   assert(!foreignWhitespace.ok,'P4-07 foreign actor saw whitespace Paper result');
 }
 console.log('P4-05 EMPTY SIGNED PAPER NEGATIVE PASS',
  JSON.stringify({components:['P1','P5'],realJwt:true,zeroResponses:true,
    executionComparatorDenied:true,sameKeyReplay:true,
    gradeStillUnknown:true,operationalStagesPreserved:true}));
}
run().catch(e=>{console.error('P4-05 EMPTY PAPER NEGATIVE FAILED:',e.message);process.exitCode=1;});
