#!/usr/bin/env node
'use strict';
// Practical single learner with already-open tab and signed not-yet-expired JWT.
// Runs only after the P4 signed six-full-Paper E2E in isolated PG17.
const assert=require('node:assert/strict');
const {execFileSync}=require('node:child_process');
const {RUN,jwt,rpc,ok,row,list}=require('./p1p5-isolated-http-positive-mixed-timed.cjs');
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
 process.env.PGHOST==='127.0.0.1'&&process.env.PGPORT==='5432'&&
 process.env.PGDATABASE==='postgres'&&process.env.P1P5_E2E_JWT_SECRET,
 'REFUSED: not ephemeral signed PostgREST PG17');
function setCutoff(value){
 assert(value===null||(Number.isInteger(value)&&value>0));
 const n=value===null?'NULL':String(value);
 const sql="DO $p$ BEGIN IF current_database()<>'postgres' OR "+
   "current_setting('iclub.e2e_isolated',true)<>'true' OR "+
   "(SELECT count(*) FROM auth.users)<>3 OR (SELECT count(*) FROM public.users)<>3 "+
   "THEN RAISE EXCEPTION 'not disposable 3-user PG17'; END IF; "+
   "UPDATE private.exam_prep_feature_config SET writer_min_jwt_iat="+n+
   " WHERE program_key='math_as_p1_p5'; END $p$;";
 execFileSync('psql',['-X','-v','ON_ERROR_STOP=1','-c',sql],
  {encoding:'utf8',env:{...process.env,PGOPTIONS:'-c iclub.e2e_isolated=true'}});
}
function snapshot(uid){
 return row("SELECT "+
 "(SELECT count(*)::int FROM private.exam_prep_sessions WHERE user_id='"+uid+"'::uuid) sessions,"+
 "(SELECT count(*)::int FROM private.exam_prep_responses r JOIN private.exam_prep_sessions s ON s.id=r.session_id WHERE s.user_id='"+uid+"'::uuid) answers,"+
 "(SELECT count(*)::int FROM private.exam_prep_session_authorizations WHERE user_id='"+uid+"'::uuid) auths,"+
 "(SELECT count(*)::int FROM private.exam_prep_timed_attempt_results WHERE user_id='"+uid+"'::uuid) results,"+
 "(SELECT md5(coalesce(string_agg(component_code||':'||xmin::text,'|' ORDER BY component_code),'')) FROM private.exam_prep_stage_states WHERE user_id='"+uid+"'::uuid) stage_fingerprint,"+
 "(SELECT md5(coalesce(string_agg(component_code||':'||skill_code||':'||xmin::text,'|' ORDER BY component_code,skill_code),'')) FROM private.exam_prep_skill_states WHERE user_id='"+uid+"'::uuid) skill_fingerprint");
}
async function main(){
 const learner=row("SELECT user_id::text uid FROM private.exam_prep_synthetic_identities "+
   "WHERE run_id='"+RUN+"' AND identity_kind='learner' AND identity_status='active'");
 assert(learner?.uid,'genuine isolated signed learner not found');
 const uid=learner.uid;
 const papers=list("SELECT s.id::text id,s.component_code component,s.assessment_id assessment "+
   "FROM private.exam_prep_sessions s JOIN private.exam_prep_timed_attempt_results t ON t.session_id=s.id "+
   "WHERE s.user_id='"+uid+"'::uuid AND s.status='finalized' AND s.session_type='paper' "+
   "AND t.attempt_kind='full_paper' ORDER BY s.component_code,s.finalized_at");
 const p1=papers.find(x=>x.component==='P1'),p5=papers.find(x=>x.component==='P5');
 assert(p1&&p5,'need actual completed P1 and P5 paper');
 const clock=Math.floor(Date.now()/1000);
 const old=jwt(uid,{iat:clock-600,exp:clock+3600});
 const refreshed=jwt(uid,{iat:clock,exp:clock+3600});
 const prior=row("SELECT writer_min_jwt_iat AS cutoff FROM private.exam_prep_feature_config "+
  "WHERE program_key='math_as_p1_p5'");
 assert(prior&&prior.cutoff===null,'cutoff must be NULL by default');
 const before=snapshot(uid);
 let armed=false;
 try{
  setCutoff(clock-60);armed=true;
  const cases=[
   ['authorize','authorize_exam_prep_timed_safe_v1',{p_assessment_id:p1.assessment}],
   ['start','start_exam_prep_session_safe_v1',{p_authorization_id:'00000000-0000-4000-8000-000000000001',p_idempotency_key:'p016b-oldtab-start'}],
   ['answer','submit_exam_prep_response_safe_v1',{p_session_id:p1.id,p_item_order:1,p_payload:{answer:'A'},p_idempotency_key:'p016b-oldtab-answer',p_elapsed_ms:1200,p_language:'en'}],
   ['finish P1','finalize_exam_prep_timed_safe_v1',{p_session_id:p1.id,p_idempotency_key:'p016b-oldtab-paper1',p_completion_reason:'submitted'}],
   ['finish P5','finalize_exam_prep_timed_safe_v1',{p_session_id:p5.id,p_idempotency_key:'p016b-oldtab-paper5',p_completion_reason:'submitted'}],
   ['next diagnostic','start_exam_prep_next_diagnostic_safe_v1',{p_component_code:'P1',p_idempotency_key:'p016b-oldtab-diagnostic'}],
   ['finish learning','finalize_exam_prep_session_safe_v1',{p_session_id:p1.id,p_idempotency_key:'p016b-oldtab-learning'}],
   ['finish written','finalize_exam_prep_session_written_v1',{p_session_id:p1.id,p_idempotency_key:'p016b-oldtab-written'}],
   ['advance written','advance_exam_prep_written_step_safe_v1',{p_session_id:p1.id,p_item_order:1,p_idempotency_key:'p016b-oldtab-step'}],
   ['weekly action','authorize_exam_prep_plan_item_safe_v1',{p_plan_id:'00000000-0000-4000-8000-000000000001',p_priority_order:1}],
   ['weekly plan','generate_exam_prep_weekly_plan_safe_v3',{p_component_code:'P1'}]
  ];
  for(const [label,name,args] of cases){
   const r=await rpc(name,args,old);
   assert(!r.ok&&JSON.stringify(r.data||{}).includes('exam_prep_writer_epoch_stale'),
    'valid old tab bypassed server epoch on '+label+' '+JSON.stringify(r));
  }
  const stored=ok(await rpc('get_exam_prep_state_safe_v1',{p_component_code:'P1'},old),
    'stale browser may read P1 stored progress');
  assert(stored.components?.length===1 && stored.components[0].component_code==='P1',
    'old browser lost stored P1 component on cutover');
  const storedP5=ok(await rpc('get_exam_prep_state_safe_v1',{p_component_code:'P5'},old),
    'stale browser may read P5 stored progress');
  assert(storedP5.components?.length===1 && storedP5.components[0].component_code==='P5',
    'old browser lost stored P5 component on cutover');
  assert.deepEqual(snapshot(uid),before,'old browser read silently rebuilt state');
  assert.deepEqual(snapshot(uid),before,'old tab changed academic rows');
  for(const paper of [p1,p5]){
   const read=ok(await rpc('get_exam_prep_timed_result_safe_v1',{p_session_id:paper.id},old),
    'existing Paper remains readable');
   assert(read.session_id===paper.id,'existing result lost');
   const replay=ok(await rpc('finalize_exam_prep_timed_safe_v1',
    {p_session_id:paper.id,p_idempotency_key:'p016b-refreshed-'+paper.component,p_completion_reason:'submitted'},
    refreshed),'refreshed token Paper replay');
   assert(replay.replayed===true&&replay.session_id===paper.id,'fresh JWT did not resume saved Paper');
  }
  assert.deepEqual(snapshot(uid),before,'fresh token rewrote previous scores/progress');
 }finally{if(armed)setCutoff(null);}
 const rollback=ok(await rpc('finalize_exam_prep_timed_safe_v1',
  {p_session_id:p1.id,p_idempotency_key:'p016b-fence-off-replay',p_completion_reason:'submitted'},old),
  'cutoff disabled compatibility');
 assert(rollback.replayed===true,'disabled cutoff broke old-token normal behavior');
 assert.deepEqual(snapshot(uid),before,'rollback modified progress');
 console.log('P0-16B PASS: real old tab blocked on ten Core/Paper writes and stale read-rebuild, fresh signed JWT resumes P1/P5, saved scores and progress unchanged, cutoff OFF');
 console.log('P0-16B OPEN: other writers, nested triggers, app-build refresh and release signoff');
}
main().catch(e=>{console.error('P0-16B FAIL',e.stack||e.message);process.exitCode=1});
