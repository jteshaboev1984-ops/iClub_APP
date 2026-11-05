#!/usr/bin/env node
'use strict';
// Issue #450 P4-05 — FOUR ADDITIONAL authentic signed full Papers:
// original Stage B has already finalized Paper01 for P1 and P5.
// This script submits Paper02 + Paper03 via JWT -> PostgREST -> real finalizer,
// without manufactured scores or direct state writes. Disposable PG17 ONLY.
const assert=require('node:assert/strict');
const {
  RUN,jwt,rpc,ok,row,list,finishSession,proveSignedTimedClock
}=require('./p1p5-isolated-http-positive-mixed-timed.cjs');
const testKeys=['stage4_full_paper_02','stage4_full_paper_03'];
async function run(){
 const id=row("SELECT user_id::text uid,identity_status FROM private.exam_prep_synthetic_identities WHERE run_id='"+RUN+"'");
 assert(id && id.identity_status==='active' && /^[a-f0-9-]{36}$/.test(id.uid),
  'P4-05 canonical isolated learner missing');
 const owner=jwt(id.uid);
 const foreign=jwt('22222222-2222-4222-8222-222222222292');
 const expired=jwt(id.uid,{iat:Math.floor(Date.now()/1000)-7200,exp:Math.floor(Date.now()/1000)-60});
 const first=list("SELECT t.component_code component,s.assessment_id id, count(r.id)::int saved, "+
   "count(*) FILTER (WHERE r.response_kind='written')::int written "+
   "FROM private.exam_prep_timed_attempt_results t "+
   "JOIN private.exam_prep_sessions s ON s.id=t.session_id "+
   "LEFT JOIN private.exam_prep_responses r ON r.session_id=s.id "+
   "WHERE s.user_id='"+id.uid+"'::uuid AND s.status='finalized' "+
   "AND t.attempt_kind='full_paper' AND s.session_type='paper' "+
   "GROUP BY t.component_code,s.assessment_id ORDER BY t.component_code");
 assert.equal(first.length,2,'exactly one signed Paper01 per component required from P4-04');
 assert(first.every(x=>x.saved>0 && x.saved===x.written),
  'first real Paper must contain ungraded written evidence');
 const attempts=[];
 for(const comp of ['P1','P5']){
   const catalog=ok(await rpc('get_exam_prep_timed_catalog_safe_v1',{
     p_component_code:comp
   },owner),'P4-05 source governed catalog '+comp);
   assert(catalog.component_code===comp && Array.isArray(catalog.assessments),
     'P4-05 catalog mismatch');
   const used=new Set(first.filter(x=>x.component===comp).map(x=>x.id));
   for(const tail of testKeys){
     // Paper03 is correctly gated behind Stage5. Complete the SECOND
     // distinct published timed section after Paper02 to earn the genuine
     // Stage4 exit, never modify stage rows or bypass public authorization.
     if(tail==='stage4_full_paper_03'){
       const sections=ok(await rpc('get_exam_prep_timed_catalog_safe_v1',{
         p_component_code:comp
       },owner),'P4-05 timed section 02 published catalog '+comp);
       const section=sections.assessments.find(x=>
         x.assessment_key===comp.toLowerCase()+'_stage2_timed_block_02'
         && x.attempt_kind==='timed_section' && x.comparison_scope==='section'
         && x.strict_timing===true);
       assert(section,'P4-05 requires second independent timed section '+comp);
       const prefix= 'p405-'+comp.toLowerCase()+'-section02';
       const auth=ok(await rpc('authorize_exam_prep_timed_safe_v1',{
         p_assessment_id:section.assessment_id
       },owner),'P4-05 stage4 second timed-section authorization '+comp);
       assert(auth.purpose==='timed' && auth.attempt_kind==='timed_section',
         'P4-05 timed section not server-authorized');
       const started=ok(await rpc('start_exam_prep_session_safe_v1',{
         p_authorization_id:auth.authorization_id,p_idempotency_key:prefix+'-start'
       },owner),'P4-05 start second timed-section '+comp);
       await proveSignedTimedClock(started.session_id,owner,foreign,comp,'timed');
       const done=await finishSession(started.session_id,owner,prefix,true);
       assert(!done.paper && done.written===done.total && done.objective===0 &&
         done.scoreComparable===false && done.timingComparable===true,
         'P4-05 timed-section 02 must be actual executed noncredit work');
       const stage=row("SELECT operational_stage stage FROM private.exam_prep_stage_states "+
         "WHERE user_id='"+id.uid+"'::uuid AND component_code='"+comp+
         "' AND engine_version='objective_state_v1'");
       assert(stage?.stage===5,
         'P4-05 third source Paper must wait for real Stage5; got '+JSON.stringify(stage));
     }
     const key=comp.toLowerCase()+'_'+tail;
     const paper=catalog.assessments.find(x=>
       x.assessment_key===key && x.attempt_kind==='full_paper'
       && x.comparison_scope==='full' && x.strict_timing===true);
     assert(paper && !used.has(paper.assessment_id),
       'P4-05 requires distinct governed FULL paper: '+key);
     assert(paper.marks_available===(comp==='P1'?75:50),
       'full-paper original Cambridge-style marks contract drift');
     used.add(paper.assessment_id);
     const prefix='p405-'+comp.toLowerCase()+'-'+tail;
     const auth=ok(await rpc('authorize_exam_prep_timed_safe_v1',{
       p_assessment_id:paper.assessment_id
     },owner),'P4-05 signed authorizer '+key);
     assert(auth.authorization_id && auth.purpose==='paper'
       && auth.component_code===comp && auth.attempt_kind==='full_paper',
       'P4-05 incorrect signed authorization purpose '+key);
     const begin=ok(await rpc('start_exam_prep_session_safe_v1',{
       p_authorization_id:auth.authorization_id,
       p_idempotency_key:prefix+'-start'
     },owner),'P4-05 signed start '+key);
     assert(/^[a-f0-9-]{36}$/.test(begin.session_id||''),
       'P4-05 no signed session ID');
     await proveSignedTimedClock(begin.session_id,owner,foreign,comp,'paper');
     for(const lang of ['ru','uz']){
       const translated=ok(await rpc('get_exam_prep_session_safe_v1',{
         p_session_id:begin.session_id,p_language:lang
       },owner),'P4-05 '+lang+' paper owner projection');
       assert(translated.component_code===comp && translated.session_type==='paper',
         'P4-05 translated projection changed paper component/type');
       assert(translated.timing_contract && translated.timing_contract.deadline_at,
         'P4-05 '+lang+' paper lost immutable server deadline');
     }
     const result=await finishSession(begin.session_id,owner,prefix,true);
     assert(result.paper===true && result.component===comp &&
       result.written===result.total && result.objective===0 &&
       result.attempted===result.total && result.timingComparable===true &&
       result.scoreComparable===false && result.scoreStatus==='written_ungraded',
       'P4-05 source written paper must be completed but ungraded');
     const foreignResult=await rpc('get_exam_prep_timed_result_safe_v1',{
       p_session_id:begin.session_id
     },foreign);
     assert(!foreignResult.ok,'P4-05 cross-user result disclosure '+key);
     const staleResult=await rpc('get_exam_prep_timed_result_safe_v1',{
       p_session_id:begin.session_id
     },expired);
     assert(!staleResult.ok,'P4-05 expired SIGNED JWT accepted '+key);
     const unauth=await rpc('get_exam_prep_timed_result_safe_v1',{
       p_session_id:begin.session_id
     });
     assert(!unauth.ok,'P4-05 anonymous result disclosure '+key);
     const review=ok(await rpc('get_exam_prep_timed_review_pack_safe_v1',{
       p_session_id:begin.session_id,p_language:'ru'
     },owner),'P4-05 ungraded review '+key);
     assert(review.items?.length===result.total &&
       review.items.every(i=>i.written_correctness==='unknown' &&
         !Object.hasOwn(i,'self_marks_awarded')),
       'P4-05 translated written marks/grade leak '+key);
     attempts.push({component:comp,assessment_key:key,assessment_id:paper.assessment_id,
       written:result.written,scoreComparable:result.scoreComparable,
       timingComparable:result.timingComparable,session_type:'paper'});
   }
   assert.equal(used.size,3,'P4-05 must have THREE DISTINCT source Papers '+comp);
 }
 assert.equal(attempts.length,4,'four new signed timed papers required');
 const full=list("SELECT t.component_code component, count(*)::int n, "+
   "count(DISTINCT s.assessment_id)::int distinct_forms, "+
   "count(*) FILTER (WHERE private.exam_prep_timed_execution_comparable_v1(s.id))::int executed, "+
   "count(*) FILTER (WHERE private.exam_prep_timed_score_comparable_v1(s.id))::int scored "+
   "FROM private.exam_prep_timed_attempt_results t "+
   "JOIN private.exam_prep_sessions s ON s.id=t.session_id "+
   "WHERE s.user_id='"+id.uid+"'::uuid AND s.status='finalized' "+
   "AND s.session_type='paper' AND t.attempt_kind='full_paper' "+
   "GROUP BY t.component_code ORDER BY t.component_code");
 assert.equal(full.length,2);
 assert(full.every(c=>c.n===3&&c.distinct_forms===3&&c.executed===3&&c.scored===0),
   'P4-05 3 genuine written Paper journeys per P1/P5 required; no scored marks');
 console.log('P4-05 THREE SIGNED FULL PAPERS EACH P1/P5 PASS',
  JSON.stringify({sixGenuineFullPapers:true,noWrittenScore:true,
    noMentorRequired:true,foreignAnonExpiredDenied:true,
    signedReplaysChecked:true,locales:['en','ru','uz'],
    papersPerComponent:full,additionalAttempts:attempts.length}));
}
run().catch(error=>{
 console.error('P4-05 THREE-PAPER SIGNED HTTP FAILED:',error.message);
 process.exitCode=1;
});
