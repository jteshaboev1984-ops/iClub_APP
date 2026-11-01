#!/usr/bin/env node
'use strict';
// True signed localhost JWT -> PostgREST -> versioned Exam Prep RPC/PG17.
// The academic clock can advance ONLY for this registered canonical synthetic
// identity using P2-68's guarded private service-side API; never edit due date.
// All answer keys remain local to this disposable DB and are never logged.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const HOST='http://127.0.0.1:3000';
const RUN='SV-P1P5-RETEST-HTTP-CI-01';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true','REFUSED non-CI run');
assert(process.env.PGHOST==='127.0.0.1'&&process.env.PGPORT==='5432'&&process.env.PGDATABASE==='postgres','REFUSED non-local PostgreSQL');
assert(SECRET&&SECRET.length>=32,'REFUSED missing disposable JWT secret');
const encode=o=>Buffer.from(JSON.stringify(o)).toString('base64url');
function sign(uid){
 const str=encode({alg:'HS256',typ:'JWT'})+'.'+encode({role:'authenticated',aud:'authenticated',sub:uid,iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+3600});
 return str+'.'+crypto.createHmac('sha256',SECRET).update(str).digest('base64url');
}
function psql(sql){
 assert(/^(\s*SELECT|\s*WITH)\b/i.test(sql),'REFUSED: standalone local DB reads only');
 return execFileSync('psql',['-X','-A','-t','-v','ON_ERROR_STOP=1','-c',sql],{encoding:'utf8'}).trim();
}
function json(sql){const x=psql(sql);return x?JSON.parse(x):null}
async function rpc(name,args={},token){
 assert(/^[a-z][a-z_0-9]+$/.test(name),'bad RPC identifier');
 const response=await fetch(HOST+'/rpc/'+name,{method:'POST',headers:{
   'Content-Type':'application/json','Accept':'application/json',
   ...(token?{Authorization:'Bearer '+token}:{})
 },body:JSON.stringify(args)});
 const raw=await response.text();let data=null;try{data=raw?JSON.parse(raw):null}catch{}
 return {ok:response.ok,status:response.status,data,reason:response.ok?null:(data?.code||data?.message||response.status)};
}
function requireOK(x,label){assert(x.ok&&x.data!==null,label+' rejected HTTP '+x.status+' '+x.reason);return x.data}
function row(sql){return json('SELECT row_to_json(z)::text FROM ('+sql+') z')}
function synthetic(){
 const a=row("SELECT user_id::text uid,run_id,identity_status FROM private.exam_prep_synthetic_identities WHERE run_id='"+RUN+"'");
 assert(a&&a.identity_status==='active'&&/^[a-f0-9-]{36}$/.test(a.uid),'dedicated canonical fake user missing');
 assert(a.run_id===RUN,'wrong synthetic run');
 return a.uid;
}
function due(caseId){
 return row("SELECT id::text id,status,due_not_before::text due_at,(due_not_before>private.exam_prep_effective_academic_now_v1(user_id)) future FROM private.exam_prep_retest_events WHERE correction_case_id='"+caseId+"'::uuid ORDER BY created_at DESC LIMIT 1");
}
function correction(uid,component){
 return json("SELECT coalesce(json_agg(row_to_json(z)),'[]'::json)::text FROM (SELECT id::text id,component_code component,status FROM private.exam_prep_correction_cases WHERE user_id='"+uid+"'::uuid AND component_code='"+component+"' AND status IN('open','remediating','retest_due','reopened') ORDER BY opened_at) z");
}
function issuedItems(sessionId){
 return json("SELECT coalesce(json_agg(row_to_json(z) ORDER BY z.ord),'[]'::json)::text FROM (SELECT si.item_order ord,si.item_kind kind,q.qtype type,q.correct_answer ans FROM private.exam_prep_session_items si LEFT JOIN public.questions q ON q.id=si.question_id WHERE si.session_id='"+sessionId+"'::uuid ORDER BY si.item_order) z");
}
async function complete(sessionId,token,prefix,wrong=false){
 const items=issuedItems(sessionId);
 assert(items.length>=1&&items.length<=240,'no actual issued items or anomalous pack size');
 let changed=false;
 for(const v of items){
   let payload;
   if(v.kind==='question'){
     assert(typeof v.ans==='string'&&v.ans.trim(),'isolated question missing validated correct-answer oracle');
     let answer=v.ans;
     if(wrong&&!changed&&v.type==='mcq'){answer=v.ans.trim().toUpperCase()==='A'?'B':'A';changed=true}
     payload={answer};
   }else{
     payload={artifact:{working:'Isolated learner worked example',method:'self_review',conclusion:'noncredit'}};
   }
   requireOK(await rpc('submit_exam_prep_response_safe_v1',{
     p_session_id:sessionId,p_item_order:v.ord,p_payload:payload,
     p_idempotency_key:prefix+'-item-'+v.ord,p_elapsed_ms:1500,p_language:'en'
   },token),'answer '+v.ord);
 }
 if(wrong)assert(changed,'no MCQ available to create a genuine correction case');
 requireOK(await rpc('finalize_exam_prep_session_safe_v1',{
   p_session_id:sessionId,p_idempotency_key:prefix+'-final'
 },token),'finalize');
 return items.length;
}
function clockInfo(uid){
 return row("SELECT private.exam_prep_effective_academic_now_v1('"+uid+"'::uuid)::text actual,virtual_now::text virtual,step_no FROM private.exam_prep_synthetic_run_clocks WHERE run_id='"+RUN+"'");
}
function advanceClock(uid,seconds) {
 assert(Number.isInteger(seconds)&&seconds>0&&seconds<=1209600,'advance must satisfy existing 14d cap');
 const info=clockInfo(uid);
 assert(info.actual===info.virtual,'canonical learner is not bound to synthetic time');
 // This is a tightly guarded canonical P2-68 admin operation on disposable CI.
 // It is NOT reachable via the authenticated browser or REST role.
 const result=row("SELECT private.advance_exam_prep_synthetic_clock_v1('"+RUN+"',"+
 " (SELECT virtual_now FROM private.exam_prep_synthetic_run_clocks WHERE run_id='"+RUN+"'),"+
 seconds+",'p1p5-authenticated-postdue-real-http-proof') AS result");
 assert(result.result?.clock_status==='active','governed clock operation failed');
 const after=clockInfo(uid);
 assert(Date.parse(after.actual)>Date.parse(info.actual),'synthetic clock did not advance');
 return {seconds,step:after.step_no};
}
async function run(){
 const uid=synthetic(),token=sign(uid),otherToken=sign('22222222-2222-4222-8222-222222222292');
 const runState=row("SELECT run_status,cleanup_status FROM private.exam_prep_synthetic_validation_runs WHERE run_id='"+RUN+"'");
 assert(runState.run_status==='running'&&runState.cleanup_status==='not_started','synthetic run not clean/running');
 const profile=requireOK(await rpc('save_exam_prep_exam_profile_v2',{
   p_exam_series:'May/June 2027',p_target_grade:'A',
   p_total_student_hours_available:12,p_mathematics_hours_budget:6
 },token),'exam profile');
 assert(profile,'profile absent');
 const diagnosticCount={};
 for(const component of ['P1','P5']){
   let done=false,attempts=0;
   for(;attempts<28;attempts++){
     const p=requireOK(await rpc('get_exam_prep_diagnostic_progress_safe_v1',{p_component_code:component},token),'stage0 '+component);
     if(p.stage0_complete){done=true;break}
     const s=requireOK(await rpc('start_exam_prep_next_diagnostic_safe_v1',{
       p_component_code:component,p_idempotency_key:'postdue-'+component+'-stage0-'+attempts
     },token),'start '+component);
     assert(s.session_id,'server issued no session '+component);
     await complete(s.session_id,token,'postdue-'+component+'-stage0-'+attempts);
   }
   assert(done,'real server Stage 0 did not converge for '+component);
   diagnosticCount[component]=attempts;
 }
 assert(diagnosticCount.P1>0&&diagnosticCount.P5>0,'P1/P5 not independently screened');
 const plan=requireOK(await rpc('generate_exam_prep_weekly_plan_safe_v3',{p_component_code:'P1'},token),'P1 plan');
 assert(plan.plan_id,'missing governed P1 plan');
 const available=json("SELECT coalesce(json_agg(row_to_json(x)),'[]'::json)::text FROM (SELECT priority_order ord FROM private.exam_prep_weekly_plan_items WHERE plan_id='"+plan.plan_id+"'::uuid AND item_type='learning' AND status='pending' ORDER BY priority_order) x");
 assert(available.length>0,'no server-issued P1 learning');
 let caseRow=null,learningCount=0;
 for(const p of available){
   const authorization=await rpc('authorize_exam_prep_plan_item_safe_v1',{p_plan_id:plan.plan_id,p_priority_order:p.ord},token);
   if(!authorization.ok||!authorization.data?.authorization_id)continue;
   const start=requireOK(await rpc('start_exam_prep_session_safe_v1',{
     p_authorization_id:authorization.data.authorization_id,p_idempotency_key:'postdue-learning-'+p.ord
   },token),'P1 learning start');
   await complete(start.session_id,token,'postdue-learning-'+p.ord,true);
   learningCount++;
   caseRow=correction(uid,'P1')[0]||null;
   if(caseRow)break;
 }
 assert(caseRow?.id,'real wrong P1 learning did not generate a governed correction');
 const corrective=requireOK(await rpc('authorize_exam_prep_correction_safe_v1',{p_correction_case_id:caseRow.id},token),'correction auth');
 const corrStart=requireOK(await rpc('start_exam_prep_session_safe_v1',{
   p_authorization_id:corrective.authorization_id,p_idempotency_key:'postdue-correction-start'
 },token),'correction start');
 await complete(corrStart.session_id,token,'postdue-correction');
 const before=due(caseRow.id);assert(before&&before.future===true,'governed due event not scheduled for future');
 const tooEarly=await rpc('authorize_exam_prep_retest_safe_v1',{p_correction_case_id:caseRow.id},token);
 assert(!tooEarly.ok,'server improperly allowed retest before academic due time');
 const foreign=await rpc('authorize_exam_prep_retest_safe_v1',{p_correction_case_id:caseRow.id},otherToken);
 assert(!foreign.ok,'other signed learner can authorize correction retest');
 let steps=0;
 for(let i=0;i<4;i++){
   if(!due(caseRow.id).future)break;
   advanceClock(uid,7*24*3600);steps++;
 }
 assert(!due(caseRow.id).future,'clock advanced but due gate remains future; never modify real due timestamp');
 const retest=requireOK(await rpc('authorize_exam_prep_retest_safe_v1',{p_correction_case_id:caseRow.id},token),'positive post-due retest');
 assert(retest.authorization_id&&retest.assessment_id,'no actual fresh retest authorization');
 const started=requireOK(await rpc('start_exam_prep_session_safe_v1',{
   p_authorization_id:retest.authorization_id,p_idempotency_key:'postdue-fresh-retest-start'
 },token),'retest start');
 assert(started.session_id!==corrStart.session_id,'retest recycled correction session');
 const reassessment=row("SELECT session_type,component_code,status,assessment_id FROM private.exam_prep_sessions WHERE id='"+started.session_id+"'::uuid");
 assert(reassessment.session_type==='retest'&&reassessment.component_code==='P1',
 'fresh session not P1 retest');
 assert(String(reassessment.assessment_id)===String(retest.assessment_id),'retest assessment changed after authorization');
 const retestCount=await complete(started.session_id,token,'postdue-fresh-retest');
 const resolved=row("SELECT status FROM private.exam_prep_correction_cases WHERE id='"+caseRow.id+"'::uuid");
 assert(resolved.status==='resolved','valid fresh retest did not resolve correction case');
 const oldResponseCount=Number(psql("SELECT count(*) FROM private.exam_prep_responses WHERE session_id='"+corrStart.session_id+"'::uuid"));
 assert(oldResponseCount>=1,'prior corrected evidence was damaged');
 const p5Untouched=Number(psql("SELECT count(*) FROM private.exam_prep_sessions WHERE user_id='"+uid+"'::uuid AND component_code='P5' AND session_type IN('correction','retest')"));
 assert(p5Untouched===0,'P1 correction leaked into P5');
 console.log('STAGE B AUTHENTIC HTTP POST-DUE RETEST PASS',JSON.stringify({
   realHttpJwt:true,canonicalSyntheticClock:true,
   stage0DiagnosticCycles:diagnosticCount,learningSessions:learningCount,
   beforeDueDenied:true,crossUserDenied:true,clockSteps:steps,
   distinctIssuedRetest:true,freshRetestItems:retestCount,caseResolved:true,
   previousCorrectionResponsesPreserved:true,p5Untouched:true
 }));
}
run().catch(e=>{console.error('STAGE B POST-DUE TEST FAILED:',e.message);process.exitCode=1});
