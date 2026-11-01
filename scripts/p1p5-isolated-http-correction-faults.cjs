#!/usr/bin/env node
'use strict';
// Stage B batch 2: genuine signed JWT/PostgREST/PG17 learner correction, due-time
// denial, stage-locked timed and cross-user write isolation. Runs ONLY after
// scripts/p1p5-isolated-http-auth-e2e.cjs in same disposable GitHub runner DB.
// No live Supabase, production tokens, key export, fake time progression or grades.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const HOST='http://127.0.0.1:3000';
const A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.P1P5_E2E_ISOLATED==='true'&&process.env.CI==='true','REFUSED non-CI isolated environment');
assert(SECRET&&SECRET.length>=32,'REFUSED no disposable JWT secret');
assert(process.env.PGHOST==='127.0.0.1'&&process.env.PGPORT==='5432','REFUSED non-local database');
const encode=obj=>Buffer.from(JSON.stringify(obj)).toString('base64url');
function sign(uid) {
 const v=encode({alg:'HS256',typ:'JWT'})+'.'+encode({aud:'authenticated',role:'authenticated',sub:uid,iat:Math.floor(Date.now()/1000),exp:Math.floor(Date.now()/1000)+1800});
 return v+'.'+crypto.createHmac('sha256',SECRET).update(v).digest('base64url');
}
async function rpc(name,args,token) {
 assert(/^[a-z][a-z_0-9]+$/.test(name),'invalid RPC identifier');
 const res=await fetch(HOST+'/rpc/'+name,{method:'POST',headers:{'Content-Type':'application/json',Accept:'application/json',Authorization:'Bearer '+token},body:JSON.stringify(args||{})});
 let data=null;try{data=await res.json()}catch{}
 return {ok:res.ok,status:res.status,data,error:res.ok?'':String(data?.message||data?.code||res.status)};
}
function rows(sql) {
 // READ-ONLY local queries. Never logs canonical answers or student details.
 assert(/^(\s*SELECT|\s*WITH)\b/i.test(sql),'REFUSED non-read-only query');
 const raw=execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',sql],{encoding:'utf8'}).trim();
 return raw?JSON.parse(raw):[];
}
function corrections(){
 return rows("SELECT coalesce(json_agg(json_build_object('id',id,'component',component_code,'status',status) order by opened_at),'[]'::json)::text FROM private.exam_prep_correction_cases WHERE user_id='"+A+"'::uuid AND status IN ('open','remediating','retest_due','reopened')");
}
function pendingLearning(){
 return rows("SELECT coalesce(json_agg(json_build_object('plan',p.id,'component',p.component_code,'order',i.priority_order) order by p.component_code,i.priority_order),'[]'::json)::text FROM private.exam_prep_weekly_plan_items i JOIN private.exam_prep_weekly_plans p ON p.id=i.plan_id WHERE p.user_id='"+A+"'::uuid AND p.status='active' AND i.item_type='learning' AND i.status='pending'");
}
function sessionItems(sessionId){
 assert(/^[0-9a-f-]{36}$/.test(sessionId));
 return rows("SELECT coalesce(json_agg(json_build_object('order',si.item_order,'kind',si.item_kind,'qtype',q.qtype,'answer',q.correct_answer) ORDER BY si.item_order),'[]'::json)::text FROM private.exam_prep_session_items si LEFT JOIN public.questions q ON q.id=si.question_id WHERE si.session_id='"+sessionId+"'::uuid");
}
function firstSyntheticSession(){
 const raw=execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',"SELECT id FROM private.exam_prep_sessions WHERE user_id='"+A+"'::uuid AND status='finalized' ORDER BY started_at LIMIT 1"],{encoding:'utf8'}).trim();
 assert(/^[0-9a-f-]{36}$/.test(raw),'no completed isolated baseline');
 return raw;
}
async function answerSession(sessionId,token,prefix,wrongOne=false) {
 const items=sessionItems(sessionId);assert(items.length>0,'no issued session items');
 let wrongUsed=false, submitted=0, written=0;
 for(const row of items) {
   let payload;
   if(row.kind==='question'){
     assert(typeof row.answer==='string'&&row.answer.trim(),'missing synthetic-only correct-answer oracle');
     let answer=row.answer;
     if(wrongOne&&!wrongUsed&&row.qtype==='mcq'){
       answer=row.answer.trim().toUpperCase()==='A'?'B':'A';
       wrongUsed=true;
     }
     payload={answer};
   } else {
     // No academic credit is manufactured by a generic written artifact.
     written++;
     payload={artifact:{working:'Disposable diagnostic correction working',method:'synthetic',conclusion:'noncredit'}};
   }
   const out=await rpc('submit_exam_prep_response_safe_v1',
     {p_session_id:sessionId,p_item_order:row.order,p_payload:payload,
      p_idempotency_key:prefix+'-'+row.order,p_elapsed_ms:1200,p_language:'en'},token);
   assert(out.ok,'real submission rejected at '+row.order+' reason='+out.error);
   submitted++;
 }
 if(wrongOne)assert(wrongUsed,'selected learning pack had no objective MCQ to open correction');
 const finalized=await rpc('finalize_exam_prep_session_safe_v1',
   {p_session_id:sessionId,p_idempotency_key:prefix+'-final'},token);
 assert(finalized.ok,'correction/learning finalization failed: '+finalized.error);
 return {submitted,written,oneWrong:wrongUsed};
}
async function createCorrectionIfMissing(token){
 let current=corrections();
 if(current.length)return {cases:current,forcedWrong:false};
 for(const item of pendingLearning()){
   const a=await rpc('authorize_exam_prep_plan_item_safe_v1',
     {p_plan_id:item.plan,p_priority_order:item.order},token);
   if(!a.ok||!a.data?.authorization_id)continue;
   const s=await rpc('start_exam_prep_session_safe_v1',
     {p_authorization_id:a.data.authorization_id,p_idempotency_key:'isolated-more-learning-'+item.component+'-'+item.order},token);
   assert(s.ok&&s.data?.session_id,'pending plan auth did not start real session '+item.component);
   const result=await answerSession(s.data.session_id,token,'isolated-learning-wrong-'+item.component+'-'+item.order,true);
   current=corrections();
   if(current.length)return {cases:current,forcedWrong:true,learning:result};
 }
 assert(current.length>0,'NO governed correction case from existing real-learning sessions or pending learning; no fake case inserted');
}
(async()=>{
 const tokenA=sign(A),tokenB=sign(B);
 const own=firstSyntheticSession();
 const badWrite=await rpc('submit_exam_prep_response_safe_v1',
   {p_session_id:own,p_item_order:1,p_payload:{answer:'B'},p_idempotency_key:'unauthorized-foreign',p_elapsed_ms:1000,p_language:'en'},tokenB);
 assert(!badWrite.ok,'user B changed user A academic evidence');
 const foreignReview=await rpc('get_exam_prep_session_review_safe_v1',{p_session_id:own,p_language:'en'},tokenB);
 assert(!foreignReview.ok||!foreignReview.data?.items?.length,'user B read user A assessment review');
 const catalog=await rpc('get_exam_prep_timed_catalog_safe_v1',{p_component_code:'P1'},tokenA);
 assert(catalog.ok,'real owned timed catalog unavailable: '+catalog.error);
 const future=rows("SELECT coalesce(json_agg(id ORDER BY id),'[]'::json)::text FROM (SELECT a.id FROM private.exam_prep_assessments a JOIN private.exam_prep_timed_assessment_contracts c ON c.assessment_id=a.id AND c.status='published' WHERE a.component_code='P1' AND a.status='published' AND c.attempt_kind='full_paper' ORDER BY a.id LIMIT 1) q");
 assert(future.length===1,'no published P1 full paper for negative stage test');
 const deniedTimed=await rpc('authorize_exam_prep_timed_safe_v1',{p_assessment_id:future[0]},tokenA);
 assert(!deniedTimed.ok,'full-paper authorization bypassed current stage gate');
 const source=await createCorrectionIfMissing(tokenA);
 const caseId=source.cases.find(c=>c.component==='P1')?.id||source.cases[0]?.id;
 assert(caseId,'no correction case available');
 const remediation=await rpc('authorize_exam_prep_correction_safe_v1',{p_correction_case_id:caseId},tokenA);
 assert(remediation.ok&&remediation.data?.authorization_id,'correction authorization failed: '+remediation.error);
 const start=await rpc('start_exam_prep_session_safe_v1',
   {p_authorization_id:remediation.data.authorization_id,p_idempotency_key:'isolated-real-correction-start'},tokenA);
 assert(start.ok&&start.data?.session_id,'correction start failed '+start.error);
 const foreignCorrection=await rpc('get_exam_prep_session_safe_v1',
   {p_session_id:start.data.session_id,p_language:'en'},tokenB);
 assert(!foreignCorrection.ok||!foreignCorrection.data?.items?.length,'user B read user A active correction');
 // Reopen the same still-active session from a new signed HTTP client,
 // independent of the original browser page and cookies.
 const reopen=await rpc('get_exam_prep_session_safe_v1',
   {p_session_id:start.data.session_id,p_language:'en'},sign(A));
 assert(reopen.ok&&reopen.data?.status==='active'&&reopen.data?.component_code===source.cases.find(c=>c.id===caseId)?.component,
   'same authenticated learner could not resume frozen active correction session');
 const answered=await answerSession(start.data.session_id,tokenA,'isolated-real-correction');
 const caseStatus=rows("SELECT json_build_array(status)::text FROM private.exam_prep_correction_cases WHERE id='"+caseId+"'::uuid");
 assert(caseStatus.length===1,'correction case vanished after real finalization');
 const early=await rpc('authorize_exam_prep_retest_safe_v1',{p_correction_case_id:caseId},tokenA);
 assert(!early.ok,'delayed fresh retest was authorized immediately after correction; real time gate bypassed');
 const scheduled=rows("SELECT coalesce(json_agg(json_build_object('status',status,'due_future',due_not_before>now())),'[]'::json)::text FROM private.exam_prep_retest_events WHERE correction_case_id='"+caseId+"'::uuid");
 assert(scheduled.length>0&&scheduled.some(x=>x.due_future===true),
   'no server scheduled future-due retest after governed correction');
 console.log('STAGE B REAL HTTP correction/security/early-retest PASS',
  JSON.stringify({userBWriteDenied:true,userBReviewDenied:true,userBActiveCorrectionDenied:true,
   paperStageGateDenied:true,authenticatedResume:true,correctionAnswered:answered.submitted,
   correctedComponent:source.cases.find(c=>c.id===caseId).component,
   scheduleCreated:scheduled.length,tooEarlyDenied:true,contentCaseSource:source.forcedWrong?'server-approved-learning-miss':'prior-real-learning-miss'}));
})().catch(e=>{console.error('REAL HTTP CORRECTION TEST FAILED:',e.message);process.exitCode=1;});
