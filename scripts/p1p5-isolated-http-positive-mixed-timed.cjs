#!/usr/bin/env node
'use strict';
// Authenticated positive mixed + timed/full-paper real PostgREST E2E.
// Server-graded evidence has ALREADY prepared Stage 3 from published academic
// content in isolated PostgreSQL; neither client nor fixture assigns mastery.
// The result of all scored timed attempts originates in the public finalizer.
// Written responses are learner artifacts, and self-marks are explicit 0,
// NEVER machine/examiner-verified marks or an artificial readiness claim.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const RUN='SV-P1P5-MIXED-TIMED-HTTP-01';
const HOST='http://127.0.0.1:3000';
const SIGNING_KEY=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
 process.env.PGHOST==='127.0.0.1'&&process.env.PGPORT==='5432'&&
 process.env.PGDATABASE==='postgres','REFUSED: not ephemeral local GitHub PG');
assert(SIGNING_KEY?.length>=32,'REFUSED: unsigned test auth');
const e=o=>Buffer.from(JSON.stringify(o)).toString('base64url');
function jwt(uid){
 const h=e({alg:'HS256',typ:'JWT'})+'.'+e({role:'authenticated',aud:'authenticated',sub:uid,iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+3600});
 return h+'.'+crypto.createHmac('sha256',SIGNING_KEY).update(h).digest('base64url');
}
function sql(statement){
 assert(/^\s*SELECT\b/i.test(statement),'REFUSED: SQL reads only');
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',statement],{encoding:'utf8'}).trim();
}
function row(q){const s=sql('SELECT row_to_json(r)::text FROM ('+q+') r');return s?JSON.parse(s):null}
function list(q){const s=sql("SELECT coalesce(json_agg(row_to_json(r)),'[]'::json)::text FROM ("+q+") r");return s?JSON.parse(s):[]}
async function rpc(name,args={},token){
 assert(/^[a-z][a-z_0-9]+$/.test(name));
 const res=await fetch(HOST+'/rpc/'+name,{method:'POST',headers:{
 'Content-Type':'application/json','Accept':'application/json',
 ...(token?{Authorization:'Bearer '+token}:{})
 },body:JSON.stringify(args)});
 const raw=await res.text();let data=null;try{data=raw?JSON.parse(raw):null}catch{}
 return {ok:res.ok,data,status:res.status,code:res.ok?'':data?.code||data?.message||res.status};
}
const ok=(r,label)=>{assert(r.ok&&r.data!=null,label+' HTTP '+r.status+' reason='+r.code);return r.data};

async function proveSignedTimedClock(id,ownerToken,foreignToken,component,expectedType){
 const owner=ok(await rpc('get_exam_prep_session_safe_v1',{
  p_session_id:id,p_language:'en'
 },ownerToken),'owner clock projection '+component);
 assert.equal(owner.component_code,component);
 assert.equal(owner.session_type,expectedType);
 const t=owner.timing_contract;
 assert(t&&typeof t==='object'&&!Array.isArray(t),'Timed/Paper clock missing');
 assert.deepEqual(Object.keys(t).sort(),
  ['deadline_at','time_limit_sec','strict_timing','attempt_kind','server_now'].sort(),
  'Do not expose private comparison, marks or keys');
 assert(Date.parse(t.deadline_at)>Date.parse(t.server_now),'Server deadline must be in future');
 assert(Number.isInteger(t.time_limit_sec)&&t.time_limit_sec>0);
 assert(typeof t.strict_timing==='boolean');
 assert(typeof t.attempt_kind==='string'&&t.attempt_kind.length>0);
 assert(Date.parse(t.deadline_at)-Date.parse(t.server_now)<=t.time_limit_sec*1000,
  'Countdown must use immutable server duration');
 const foreign=await rpc('get_exam_prep_session_safe_v1',{p_session_id:id,p_language:'en'},foreignToken);
 assert(!foreign.ok,'Foreign learner read another Timed/Paper clock');
 const anonymous=await rpc('get_exam_prep_session_safe_v1',{p_session_id:id,p_language:'en'});
 assert(!anonymous.ok,'Anonymous actor read Timed/Paper clock');
 return owner;
}

const sessionItems=id=>list("SELECT si.item_order ord,si.item_kind kind,si.reserve_role role,q.qtype qtype,q.correct_answer ans,ti.max_marks max_marks FROM private.exam_prep_session_items si LEFT JOIN public.questions q ON q.id=si.question_id LEFT JOIN private.exam_prep_timed_assessment_items ti ON ti.assessment_id=(SELECT assessment_id FROM private.exam_prep_sessions WHERE id=si.session_id) AND ti.item_order=si.item_order WHERE si.session_id='"+id+"'::uuid ORDER BY si.item_order");
async function finishSession(id,token,prefix,timed=false){
 assert(/^[a-f0-9-]{36}$/.test(id),'bad uuid');
 const frozen=sessionItems(id);
 assert(frozen.length>0&&frozen.length<=240,'missing server-issued academic pack');
 let written=0,objective=0;
 for(const v of frozen){
  let payload;
  if(v.kind==='question'){
   assert(typeof v.ans==='string'&&v.ans.trim(),'test-only local answer oracle unavailable');
   payload={answer:v.ans};objective++;
  }else{
   // Real written content remains unverified. No automatic examination mark.
   payload={artifact:{working:'CI-only synthetic written working',method:'learner_self_review',conclusion:'noncredit evidence'}};
   written++;
  }
  ok(await rpc('submit_exam_prep_response_safe_v1',{
   p_session_id:id,p_item_order:v.ord,p_payload:payload,
   p_idempotency_key:prefix+'-item-'+v.ord,p_elapsed_ms:1200,p_language:'en'
  },token),'server accepted '+prefix+' item '+v.ord);
 }
 if(!timed){
  const done=ok(await rpc('finalize_exam_prep_session_safe_v1',{
   p_session_id:id,p_idempotency_key:prefix+'-final'
  },token),'finalize mixed');
  assert(done.status==='finalized','mixed finalizer did not persist');
  return {objective,written,total:frozen.length};
 }
 // Timing comparability uses actual server clock and requires >0 seconds.
 await new Promise(resolve=>setTimeout(resolve,1300));
 const done=ok(await rpc('finalize_exam_prep_timed_safe_v1',{
   p_session_id:id,p_idempotency_key:prefix+'-final',p_completion_reason:'submitted'
 },token),'finalize real timed');
 const replay=ok(await rpc('finalize_exam_prep_timed_safe_v1',{
   p_session_id:id,p_idempotency_key:prefix+'-final',p_completion_reason:'submitted'
 },token),'idempotent finalizer replay');
 assert(replay.replayed===true,'timed duplicate finalization not idempotent');
 const selfChecks=frozen.filter(i=>i.kind==='written');
 const reviewBefore=ok(await rpc('get_exam_prep_timed_result_safe_v1',{p_session_id:id},token),'timed before self review');
 if(selfChecks.length)assert(reviewBefore.score_status==='pending_self_review',
  'unreviewed written content was incorrectly treated as machine-scored');
 for(const i of selfChecks){
  const marked=ok(await rpc('submit_exam_prep_timed_written_self_mark_safe_v1',{
   p_session_id:id,p_item_order:i.ord,p_marks_awarded:0,
   p_idempotency_key:prefix+'-selfmark-'+i.ord,
   p_review_note:'CI synthetic learner self review; deliberately no verified marks'
  },token),'explicit self-review '+i.ord);
  assert(marked.readiness_claim!==true,'self-mark cannot award readiness');
 }
 const after=ok(await rpc('get_exam_prep_timed_result_safe_v1',{p_session_id:id},token),'timed result after self review');
 assert(after.readiness_claim!==true,'test result promoted to human-certified readiness');
 assert(after.answered_items===frozen.length,'timed server did not count all submitted answers');
 assert(after.unattempted_items===0,'timed server lost answered item');
 const db=row("SELECT status,session_type,component_code FROM private.exam_prep_sessions WHERE id='"+id+"'::uuid");
 assert(db.status==='finalized'&&['timed','paper'].includes(db.session_type),'frozen real timed record not finalized');
 return {objective,written,total:frozen.length,scoreStatus:after.score_status,
  timingComparable:after.timing_comparable,scoreComparable:after.score_comparable,
  attempted:after.answered_items,component:db.component_code,
  paper:db.session_type==='paper'};
}
async function run(){
 const identity=row("SELECT user_id::text uid,identity_status FROM private.exam_prep_synthetic_identities WHERE run_id='"+RUN+"'");
 assert(identity?.identity_status==='active','P2-67 canonical learner missing');
 const uid=identity.uid,token=jwt(uid);
 const other=jwt('22222222-2222-4222-8222-222222222292');
 const before=list("SELECT component_code component,operational_stage stage,l2_count FROM private.exam_prep_stage_states WHERE user_id='"+uid+"'::uuid AND engine_version='objective_state_v1' ORDER BY component_code");
 assert(before.length===2&&before.every(x=>x.stage>=3),'server-graded Stage 3 requirement not met');
 const mixed=[];
 for(const component of ['P1','P5']){
  let result=ok(await rpc('generate_exam_prep_weekly_plan_safe_v3',{p_component_code:component},token),'governed mixed plan '+component);
  let planId=result.plan_id;
  assert(planId,'weekly plan missing '+component);
  let plans=list("SELECT priority_order ord,item_type item,action_code action FROM private.exam_prep_weekly_plan_items WHERE plan_id='"+planId+"'::uuid ORDER BY priority_order");
  const selected=plans.find(x=>x.item==='mixed_transfer');
  assert(selected,'real P1/P5 weekly plan has no authorized mixed_transfer for '+component+'; do not insert a test-only mixed authorization');
  const a=ok(await rpc('authorize_exam_prep_plan_item_safe_v1',{p_plan_id:planId,p_priority_order:selected.ord},token),'authorize mixed '+component);
  assert(a.purpose==='mixed'&&a.authorization_id,'mixed was not authorized by real weekly plan');
  const begin=ok(await rpc('start_exam_prep_session_safe_v1',{
   p_authorization_id:a.authorization_id,p_idempotency_key:'real-http-mixed-'+component+'-start'
  },token),'start mixed '+component);
  const pack=row("SELECT component_code,session_type,assessment_id FROM private.exam_prep_sessions WHERE id='"+begin.session_id+"'::uuid");
  assert(pack.component_code===component&&pack.session_type==='mixed','mixed package crossed paper boundary');
  const nonTimed=ok(await rpc('get_exam_prep_session_safe_v1',{p_session_id:begin.session_id,p_language:'en'},token),'non-timed projection');
  assert.equal(nonTimed.timing_contract,null,'Non-timed session must return JSON null clock');
  const done=await finishSession(begin.session_id,token,'real-http-mixed-'+component);
  const foreign=await rpc('get_exam_prep_session_safe_v1',{p_session_id:begin.session_id,p_language:'en'},other);
  assert(!foreign.ok||!foreign.data?.items?.length,'other learner accessed mixed package');
  mixed.push({component,items:done.total,serverAuthorized:true});
 }
 const papers=[];
 for(const component of ['P1','P5']){
  const catalog=ok(await rpc('get_exam_prep_timed_catalog_safe_v1',{p_component_code:component},token),'published timed catalog '+component);
  const options=catalog.assessments||[];
  const full=options.find(x=>x.assessment_key===(component.toLowerCase()+'_stage3_full_paper_01'));
  assert(full,'positive full-paper catalog not offered at real Stage 3 for '+component);
  const auth=ok(await rpc('authorize_exam_prep_timed_safe_v1',{p_assessment_id:full.assessment_id},token),'authorize full paper '+component);
  assert(auth.authorization_id&&auth.purpose==='paper','full-paper public authorization missing');
  const start=ok(await rpc('start_exam_prep_session_safe_v1',{
   p_authorization_id:auth.authorization_id,p_idempotency_key:'real-http-paper-'+component+'-start'
  },token),'start paper '+component);
  assert(start.session_id,'timed start missing session ID');
  await proveSignedTimedClock(start.session_id,token,other,component,'paper');
  const result=await finishSession(start.session_id,token,'real-http-paper-'+component,true);
  const foreign=await rpc('get_exam_prep_timed_result_safe_v1',{p_session_id:start.session_id},other);
  assert(!foreign.ok||!foreign.data?.session_id,'other learner read foreign full-paper result');
  papers.push({component,marksAvailable:full.marks_available,fullPaper:true,...result});
 }
 const timedSections=[];
 for(const component of ['P1','P5']){
  const catalog=ok(await rpc('get_exam_prep_timed_catalog_safe_v1',{p_component_code:component},token),'timed-section catalog '+component);
  const timed=(catalog.assessments||[]).find(x=>x.attempt_kind==='timed_section');
  assert(timed,'server-authorized timed-section option missing '+component);
  const a=ok(await rpc('authorize_exam_prep_timed_safe_v1',{p_assessment_id:timed.assessment_id},token),
   'public timed-section authorization '+component);
  assert(a.authorization_id&&a.purpose==='timed','timed training did not use server authorization');
  const start=ok(await rpc('start_exam_prep_session_safe_v1',{
   p_authorization_id:a.authorization_id,p_idempotency_key:'real-http-section-'+component+'-start'
  },token),'start timed-section '+component);
  await proveSignedTimedClock(start.session_id,token,other,component,'timed');
  const done=await finishSession(start.session_id,token,'real-http-section-'+component,true);
  assert(!done.paper,'timed section was incorrectly recorded as a full paper');
  const foreign=await rpc('get_exam_prep_timed_result_safe_v1',{p_session_id:start.session_id},other);
  assert(!foreign.ok||!foreign.data?.session_id,'foreign user read timed section');
  timedSections.push({component,items:done.total,objective:done.objective,written:done.written,
   scoreStatus:done.scoreStatus,timingComparable:done.timingComparable});
 }
 assert(timedSections.length===2&&timedSections.every(x=>x.items>0),
  'P1/P5 separate timed section proof missing');
 assert(papers.every(x=>x.attempted===x.total&&x.fullPaper),'not all full-paper questions submitted');
 const after=list("SELECT component_code component,operational_stage stage FROM private.exam_prep_stage_states WHERE user_id='"+uid+"'::uuid AND engine_version='objective_state_v1' ORDER BY component_code");
 assert(after.length===2,'P1/P5 states not independent');
 console.log('STAGE B REAL HTTP POSITIVE MIXED AND FULL PAPER PASS',JSON.stringify({
  realSignedHttp:true,serverGradedStage3Prep:true,fullPaperAuthorizedByServer:true,
  mixed,papers,timedSections,stageBefore:before.map(x=>({component:x.component,stage:x.stage})),stageAfter:after
 }));
}
run().catch(err=>{console.error('STAGE B MIXED/TIMED HTTP FAILED:',err.message);process.exitCode=1});
