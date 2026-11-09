#!/usr/bin/env node
'use strict';
// S4 HYBRID isolated-owner signed JWT -> real PostgREST -> PostgreSQL17 acceptance.
// EVERYTHING is gated to the disposable GitHub service. No production connections.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
  process.env.PGHOST==='127.0.0.1'&&process.env.PGDATABASE==='postgres'&&
  process.env.PGUSER==='postgres',
  'REFUSED: S4 must only run in free disposable PostgreSQL17 GitHub Action');
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(SECRET&&SECRET.length>32,'ephemeral JWT signing key required');
const A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
const b64=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function jwt(uid,role='authenticated'){
 const t=b64({alg:'HS256',typ:'JWT'})+'.'+b64({aud:'authenticated',
  sub:uid,role,iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+1200});
 return t+'.'+crypto.createHmac('sha256',SECRET).update(t).digest('base64url');
}
async function rpc(name,args={},token=jwt(A)){
 const res=await fetch('http://127.0.0.1:3000/rpc/'+name,{
  method:'POST',headers:{'Content-Type':'application/json',Accept:'application/json',
   ...(token?{Authorization:'Bearer '+token}:{})},body:JSON.stringify(args)
 });
 let payload=null;try{payload=await res.json()}catch{}
 return{ok:res.ok,status:res.status,data:payload};
}
function ok(result,label){
 assert(result.ok,label+' HTTP '+result.status+' '+JSON.stringify(result.data).slice(0,360));
 return result.data;
}
function deny(result,label){assert(!result.ok,label+' unexpectedly succeeded: '+JSON.stringify(result.data).slice(0,240))}
function sql(query){
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',query],
 {encoding:'utf8',env:process.env}).trim();
}
function counts(){
 return sql("SELECT (SELECT count(*) FROM private.exam_prep_sessions)::text||'/'||"+
  "(SELECT count(*) FROM private.exam_prep_timed_attempt_results)::text||'/'||"+
  "(SELECT count(*) FROM public.practice_attempts)::text||'/'||"+
  "(SELECT count(*) FROM public.tour_attempts)::text||'/'||"+
  "(SELECT count(*) FROM public.certificates)::text");
}
const key=(name)=>'s4-hybrid-disposable-'+name+'-abcdefghijklmnop';
async function main(){
 const original=counts();
 const disabled=ok(await rpc('get_exam_prep_hybrid_s4_papers_safe_v1',{p_component_code:'P1'}),'S4 OFF catalog');
 assert.equal(disabled.enabled,false,'S4 must be default OFF');
 deny(await rpc('start_exam_prep_hybrid_s4_paper_safe_v1',{
  p_assessment_id:391,p_idempotency_key:key('disabled')
 }),'off cannot start');
 assert.equal(sql("SELECT stage_gates_enabled::text||'/'||paper_enabled::text FROM private.exam_prep_hybrid_s4_config_v1 WHERE singleton"),'false/false');
 const direct=sql("SELECT has_table_privilege('authenticated','private.exam_prep_hybrid_s4_sessions_v1','SELECT')::text||'/'||"+
  "has_function_privilege('anon','public.start_exam_prep_hybrid_s4_paper_safe_v1(bigint,text)','EXECUTE')::text");
 assert.equal(direct,'false/false','no direct table access and no anonymous start');
 // Scope the temporary enablement to THIS disposable DB. Never in migration.
 sql("UPDATE private.exam_prep_hybrid_s4_config_v1 SET paper_enabled=true,stage_gates_enabled=true,updated_at=now() WHERE singleton");
 const p1=ok(await rpc('get_exam_prep_hybrid_s4_papers_safe_v1',{p_component_code:'P1'}),'P1 catalog');
 const p5=ok(await rpc('get_exam_prep_hybrid_s4_papers_safe_v1',{p_component_code:'P5'}),'P5 catalog');
 assert.equal(p1.enabled,true);assert.equal(p5.enabled,true);
 assert(Array.isArray(p1.papers)&&p1.papers.length>=1&&p1.papers.every(x=>x.component_code==='P1'));
 assert(Array.isArray(p5.papers)&&p5.papers.length>=1&&p5.papers.every(x=>x.component_code==='P5'));
 assert(p1.papers.every(x=>x.available_marks===75&&x.time_limit_sec===6600));
 assert(p5.papers.every(x=>x.available_marks===50&&x.time_limit_sec===4500));
 const stageP1=ok(await rpc('get_exam_prep_hybrid_s4_stage_status_safe_v1',{p_component_code:'P1'}),'hybrid stage P1');
 const stageP5=ok(await rpc('get_exam_prep_hybrid_s4_stage_status_safe_v1',{p_component_code:'P5'}),'hybrid stage P5');
 for(const state of [stageP1,stageP5]){
  assert.equal(state.enabled,true);
  assert.equal(state.full_papers_recommended_not_required,true);
  assert.equal(state.self_scoring,false);
  assert.equal(state.stage3_to_4.paper_rehearsal_required,false);
  assert.equal(state.stage4_to_5.full_papers_required_for_access,false);
  assert.equal(state.stage5_to_6.full_papers_required_for_access,false);
  assert.equal(state.stage5_to_6.app_readiness_estimate,'INSUFFICIENT_EVIDENCE');
  assert.equal(state.stage5_to_6.ready,false,'synthetic enrolment has not earned all L3');
 }
 const A1=p1.papers[0].assessment_id;
 const A5=p5.papers[0].assessment_id;
 const first=ok(await rpc('start_exam_prep_hybrid_s4_paper_safe_v1',{
  p_assessment_id:A1,p_idempotency_key:key('p1-start')
 }),'P1 start');
 assert.equal(first.replayed,false);
 assert(!first.closed_at&&first.session_id);
 const retry=ok(await rpc('start_exam_prep_hybrid_s4_paper_safe_v1',{
  p_assessment_id:A1,p_idempotency_key:key('p1-start')
 }),'start lost-ACK retry');
 assert.equal(retry.replayed,true);assert.equal(retry.session_id,first.session_id);
 deny(await rpc('start_exam_prep_hybrid_s4_paper_safe_v1',{
  p_assessment_id:A5,p_idempotency_key:key('p1-start')
 }),'same key wrong Paper');
 deny(await rpc('get_exam_prep_hybrid_s4_session_safe_v1',{
  p_session_id:first.session_id,p_language:'en'
 },jwt(B)),'foreign owner cannot see P1 paper');
 deny(await rpc('get_exam_prep_hybrid_s4_session_safe_v1',{
  p_session_id:first.session_id,p_language:'en'
 },null),'anonymous cannot see Paper');
 const attempt=ok(await rpc('get_exam_prep_hybrid_s4_session_safe_v1',{
  p_session_id:first.session_id,p_language:'ru'
 }),'owner paper prompts RU');
 assert.equal(attempt.component_code,'P1');
 assert.equal(attempt.items.length,10);
 assert(attempt.items.every(x=>x.prompt&&x.skill_code&&x.max_available_marks>0));
 assert(!JSON.stringify(attempt).includes('rubric_json')&&
  !JSON.stringify(attempt).includes('expected_numeric'));
 assert.equal(attempt.awarded_paper_marks,null);
 deny(await rpc('reveal_exam_prep_hybrid_s4_review_safe_v1',{
  p_session_id:first.session_id,p_language:'ru'
 }),'cannot reveal during running Paper');
 deny(await rpc('check_exam_prep_hybrid_s4_final_safe_v1',{
  p_session_id:first.session_id,p_item_order:1,p_part_label:'test',
  p_answer:'12',p_idempotency_key:key('early-check')
 }),'cannot check during running Paper');
 // Synthetic-only key, never a source answer. Key is in private DB, not Git.
 const stageId=Number(first.session_id?A1:0);
 assert(stageId>0&&Number.isSafeInteger(stageId));
 const taskId=sql("SELECT written_task_id FROM private.exam_prep_assessment_items "+
  "WHERE assessment_id="+stageId+" AND item_order=1");
 const taskVer=sql("SELECT task_version FROM private.exam_prep_written_tasks WHERE id="+taskId);
 assert(/^[0-9]+$/.test(taskId)&&taskVer.length>0);
 // We test exact numeric fraction/rounding plumbing using a deliberately FAKE
 // private fixture, NOT an academic-approved real student-facing question key.
 const cleanVer=taskVer.replaceAll("'","''");
 sql("INSERT INTO private.exam_prep_hybrid_s4_checkpoint_keys_v1 "+
  "(assessment_id,item_order,part_label,written_task_id,source_task_version,"+
  "expected_numeric,absolute_tolerance,review_state,academic_review_ref,approved_at) "+
  "VALUES("+stageId+",1,'test','"+taskId+"','"+cleanVer+
  "',0.5,0,'approved','synthetic-local-only',now())");
 const ended=ok(await rpc('finish_exam_prep_hybrid_s4_paper_safe_v1',{
  p_session_id:first.session_id,p_reason:'finish',p_idempotency_key:key('p1-finish')
 }),'P1 paper finish with ZERO written artifacts');
 assert.equal(ended.paper_marks,null);
 assert.equal(ended.method_verified,false);
 const endedRetry=ok(await rpc('finish_exam_prep_hybrid_s4_paper_safe_v1',{
  p_session_id:first.session_id,p_reason:'finish',p_idempotency_key:key('p1-finish')
 }),'P1 finish ACK retry');
 assert.equal(endedRetry.replayed,true);
 const post=ok(await rpc('get_exam_prep_hybrid_s4_session_safe_v1',{
  p_session_id:first.session_id,p_language:'en'
 }),'finished page');
 assert.equal(post.items.length,10);
 assert.equal(post.checkpoints.length,1);
 assert.equal(post.review_revealed,false);
 assert.equal(post.checkpoints[0].item_order,1);
 deny(await rpc('check_exam_prep_hybrid_s4_final_safe_v1',{
  p_session_id:first.session_id,p_item_order:1,p_part_label:'test',
  p_answer:'1/0',p_idempotency_key:key('bad-fraction')
 }),'invalid fraction denied');
 const match=ok(await rpc('check_exam_prep_hybrid_s4_final_safe_v1',{
  p_session_id:first.session_id,p_item_order:1,p_part_label:'test',
  p_answer:'1/2',p_idempotency_key:key('check-first')
 }),'owner final answer EXACT synthetic fraction match');
 assert.equal(match.matched,true);
 assert.equal(match.paper_marks_awarded,null);
 assert.equal(match.written_method_verified,false);
 const matchRetry=ok(await rpc('check_exam_prep_hybrid_s4_final_safe_v1',{
  p_session_id:first.session_id,p_item_order:1,p_part_label:'test',
  p_answer:'1/2',p_idempotency_key:key('check-first')
 }),'match idempotent retry');
 assert.equal(matchRetry.replayed,true);
 deny(await rpc('check_exam_prep_hybrid_s4_final_safe_v1',{
  p_session_id:first.session_id,p_item_order:1,p_part_label:'test',
  p_answer:'0',p_idempotency_key:key('check-other')
 }),'immutable first answer cannot be regraded');
 deny(await rpc('reveal_exam_prep_hybrid_s4_review_safe_v1',{
  p_session_id:first.session_id,p_language:'en'
 },jwt(B)),'foreign review denied');
 const review=ok(await rpc('reveal_exam_prep_hybrid_s4_review_safe_v1',{
  p_session_id:first.session_id,p_language:'uz'
 }),'P1 after-finish Uzbek criteria');
 assert.equal(review.review_revealed,true);
 assert.equal(review.items.length,10);
 assert(review.items.every(x=>x.review_hint&&Array.isArray(x.requirements)&&x.requirements.length>=1));
 assert(!JSON.stringify(review).includes('expected_numeric'));
 assert.equal(review.paper_marks_awarded,null);
 const recheck=await rpc('check_exam_prep_hybrid_s4_final_safe_v1',{
  p_session_id:first.session_id,p_item_order:1,p_part_label:'test',
  p_answer:'0',p_idempotency_key:key('check-post-reveal')
 });
 deny(recheck,'no new answer after criteria reveal');
 const other=ok(await rpc('start_exam_prep_hybrid_s4_paper_safe_v1',{
  p_assessment_id:A1,p_idempotency_key:key('p1-repeat')
 }),'repeat same paper');
 assert.equal(other.prior_review_seen,true);
 const second=ok(await rpc('start_exam_prep_hybrid_s4_paper_safe_v1',{
  p_assessment_id:A5,p_idempotency_key:key('p5-start')
 }),'P5 start no student score');
 const p5get=ok(await rpc('get_exam_prep_hybrid_s4_session_safe_v1',{
  p_session_id:second.session_id,p_language:'en'
 }),'P5 all paper prompts');
 assert.equal(p5get.items.length,7);
 const stop=ok(await rpc('finish_exam_prep_hybrid_s4_paper_safe_v1',{
  p_session_id:second.session_id,p_reason:'early_exit',p_idempotency_key:key('p5-exit')
 }),'P5 no-response early exit');
 assert.equal(stop.closure_code,'ended_early');
 const p5review=ok(await rpc('reveal_exam_prep_hybrid_s4_review_safe_v1',{
  p_session_id:second.session_id,p_language:'en'
 }),'P5 zero-check skip directly to review');
 assert.equal(p5review.items.length,7);
 const history=ok(await rpc('get_exam_prep_hybrid_s4_history_safe_v1',{
  p_component_code:'P1'
 }),'owner history');
 assert(history.sessions.length>=2&&history.sessions.some(x=>x.session_id===first.session_id));
 const foreignHistory=ok(await rpc('get_exam_prep_hybrid_s4_history_safe_v1',{
  p_component_code:'P1'
 },jwt(B)),'foreign personal history');
 assert(!foreignHistory.sessions.some(x=>x.session_id===first.session_id));
 const stageAfter=ok(await rpc('get_exam_prep_hybrid_s4_stage_status_safe_v1',{
  p_component_code:'P1'
 }),'stage AFTER P1 two rehearsals, still no credit');
 assert.equal(stageAfter.stage3_to_4.ready,stageP1.stage3_to_4.ready);
 assert.equal(stageAfter.stage4_to_5.ready,stageP1.stage4_to_5.ready);
 assert.equal(stageAfter.stage5_to_6.ready,stageP1.stage5_to_6.ready);
 assert.equal(counts(),original,'S4 MUST NOT touch legacy sessions/scores/Practice/Tours/certificates');
 // State disabled must leave already owned sessions retrievable, never open new.
 sql("UPDATE private.exam_prep_hybrid_s4_config_v1 "+
  "SET stage_gates_enabled=false,paper_enabled=false WHERE singleton");
 deny(await rpc('start_exam_prep_hybrid_s4_paper_safe_v1',{
  p_assessment_id:A1,p_idempotency_key:key('off-again')
 }),'S4 OFF after test');
 const saved=ok(await rpc('get_exam_prep_hybrid_s4_session_safe_v1',{
  p_session_id:first.session_id,p_language:'en'
 }),'history persists after S4 OFF');
 assert(saved.review_revealed&&saved.awarded_paper_marks===null);
 assert.equal(counts(),original);
 console.log('S4 HYBRID SIGNED JWT -> POSTGREST -> PG17 PASS: OFF default, P1/P5 written-paper no upload, owner/anon/foreign, exact fractional private check, once-only before reveal, 3 locales, immutable history, noncredit Stage3-6, preserved legacy. NO self marks, mentor or AI.');
}
main().catch(e=>{console.error('S4 HYBRID E2E FAIL:',e.stack||e);process.exitCode=1});
