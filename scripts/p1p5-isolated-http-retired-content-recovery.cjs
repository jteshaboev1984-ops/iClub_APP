#!/usr/bin/env node
'use strict';
// Real user-facing public RPC workflow via signed HTTP/real local PostgREST/PG17.
// Test-only SQL issues authorized tasks and transiently retires one content version.
// NO production, invented academic grades, real students, external auth or AI.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const host='http://127.0.0.1:3000';
const owner='22222222-2222-4222-8222-222222222292';
const foreign='11111111-1111-4111-8111-111111111191';
const secret=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
 process.env.PGHOST==='127.0.0.1'&&process.env.PGPORT==='5432'&&
 process.env.PGUSER==='postgres'&&process.env.PGDATABASE==='postgres'&&
 process.env.PGOPTIONS==='-c iclub.e2e_isolated=true','Refused outside isolated local runner');
assert(secret&&secret.length>=32,'No local JWT signing key');
const enc=o=>Buffer.from(JSON.stringify(o)).toString('base64url');
function jwt(uid){
 const time=Math.floor(Date.now()/1000);
 const content=enc({alg:'HS256',typ:'JWT'})+'.'+enc({
  aud:'authenticated',role:'authenticated',sub:uid,iat:time-5,exp:time+1800});
 return content+'.'+crypto.createHmac('sha256',secret).update(content).digest('base64url');
}
const b=jwt(owner),a=jwt(foreign);
function query(sql){
 assert(/^\s*SELECT\b/i.test(sql),'Refused arbitrary SQL query');
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',sql],{encoding:'utf8'}).trim();
}
const list=sql=>JSON.parse(query("SELECT coalesce(json_agg(row_to_json(x)),'[]'::json)::text FROM ("+sql+") x"));
const count=where=>Number(query('SELECT count(*) FROM private.exam_prep_sessions WHERE '+where));
function localMutation(cmd){
 // All content status changes are LOCAL and guarded even in an accidental
 // misconfigured runner. Restores are also guarded. Only the explicit
 // published content version used in this synthetic test can be updated.
 const guard="DO $guard$ BEGIN IF current_database()<>'postgres' "+
 "OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true' "+
 "OR (SELECT count(*) FROM public.users)<>2 OR (SELECT count(*) FROM auth.users)<>2 "+
 "OR EXISTS(SELECT 1 FROM private.exam_prep_beta_weekly_reviews) "+
 "OR EXISTS(SELECT 1 FROM public.practice_attempts) "+
 "OR EXISTS(SELECT 1 FROM public.tour_attempts) "+
 "OR EXISTS(SELECT 1 FROM public.certificates) "+
 "OR NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config "+
 "WHERE id=1 AND rollout_state='controlled_beta' AND core_enabled "+
 "AND NOT kill_switch AND NOT ai_enabled AND NOT mentor_enabled "+
 "AND NOT qa_open_all_core AND NOT qa_open_all_weekly) "+
 "OR (SELECT count(*) FROM private.exam_prep_session_authorizations "+
 "WHERE user_id='"+owner+"'::uuid AND reason LIKE 'S466-REAL-HTTP-%')<>3 "+
 "THEN RAISE EXCEPTION 'Refused non-isolated real HTTP content mutation'; END IF; "+
 cmd+" END $guard$;";
 execFileSync('psql',['-X','-q','-v','ON_ERROR_STOP=1','-c',guard],{encoding:'utf8'});
}
function contentState(status,cv){
 assert(Number.isSafeInteger(cv)&&cv>0);
 const target=status==='published'?"status='published',retired_at=NULL":"status='retired',retired_at=clock_timestamp()";
 const old=status==='published'?'retired':'published';
 localMutation("UPDATE private.exam_prep_content_versions SET "+target+
   " WHERE id="+cv+" AND component_code='P1' AND status='"+old+"'; "+
   "IF (SELECT status FROM private.exam_prep_content_versions WHERE id="+cv+
   ")<>'"+status+"' THEN RAISE EXCEPTION 'P1 content transition failed'; END IF;");
}
async function rpc(name,args={},token=b){
 const res=await fetch(host+'/rpc/'+name,{
  method:'POST',headers:{'Content-Type':'application/json','Accept':'application/json',
  Authorization:'Bearer '+token},body:JSON.stringify(args)});
 const raw=await res.text();let body=null;
 try{body=JSON.parse(raw)}catch{}
 return {ok:res.ok,status:res.status,body,error:body?.message||body?.code||''};
}
function good(res,why){
 assert(res.ok,why+' HTTP '+res.status+' '+res.error);
 return res.body;
}
function denied(res,why){
 assert(!res.ok&&res.status>=400,why+' unexpectedly allowed HTTP '+res.status);
}
function sessions(session){
 assert(/^[a-f0-9-]{36}$/.test(session));
 return list("SELECT si.item_order n,si.item_kind kind,q.correct_answer answer "+
  "FROM private.exam_prep_session_items si LEFT JOIN public.questions q "+
  "ON q.id=si.question_id WHERE si.session_id='"+session+"'::uuid ORDER BY si.item_order");
}
async function finish(session,paper){
 const items=sessions(session);
 assert(items.length>0,'Published session has no frozen items');
 let objective=0;
 for(const item of items){
  if(item.kind==='question')objective++;
  const payload=item.kind==='question'?{answer:item.answer}:
    {artifact:{working:'Only test learner external working',method:'self_review',
      conclusion:'Not examiner graded'}};
  if(item.kind==='question')assert(typeof item.answer==='string'&&item.answer.length,
    'No trusted local evaluation input');
  good(await rpc('submit_exam_prep_response_safe_v1',{
    p_session_id:session,p_item_order:item.n,p_payload:payload,
    p_idempotency_key:'s466-'+paper+'-real-answer-'+item.n,
    p_elapsed_ms:1200,p_language:'en'}),'signed HTTP answer '+paper);
 }
 assert(objective>0,'Test needs real machine-scored tasks');
 const final=good(await rpc('finalize_exam_prep_session_safe_v1',{
  p_session_id:session,p_idempotency_key:'s466-'+paper+'-real-finalize'
 }),'finalize '+paper);
 assert(final.status==='finalized','No server finalization');
 const rev=good(await rpc('get_exam_prep_session_review_safe_v1',{
  p_session_id:session,p_language:'en'}),'owner review after completion');
 assert(rev.status==='finalized'&&rev.component_code===paper&&
  rev.summary.machine_total>=objective,'Final academic review incomplete');
 assert(rev.items.some(x=>x.item_kind==='question'&&typeof x.correct_answer==='string'),
  'Owner answer key unavailable after completion');
 denied(await rpc('get_exam_prep_session_review_safe_v1',{
  p_session_id:session,p_language:'en'},a),'foreign finalized review '+paper);
 return {items:items.length,objective};
}
const reasons=['S466-REAL-HTTP-RETIRED-P1','S466-REAL-HTTP-UNAFFECTED-P5',
 'S466-REAL-HTTP-EXPIRED-P1'];
async function main(){
 const records=list("SELECT au.reason,au.id::text id,au.valid_until<now() expired,"+
  "cv.id content_id,cv.status content_status "+
  "FROM private.exam_prep_session_authorizations au "+
  "JOIN private.exam_prep_assessments ass ON ass.id=au.assessment_id "+
  "JOIN private.exam_prep_content_versions cv ON cv.id=ass.content_version_id "+
  "WHERE au.user_id='"+owner+"'::uuid AND au.reason LIKE 'S466-REAL-HTTP-%'");
 assert(records.length===3,'Failed to find 3 genuine issued test authorizations');
 const get=name=>records.find(x=>x.reason===name);
 const p1=get(reasons[0]),p5=get(reasons[1]),expired=get(reasons[2]);
 assert(p1&&p5&&expired&&expired.expired===true&&
  p1.content_status==='published'&&p5.content_status==='published'&&
  p1.content_id!==p5.content_id,'Unexpected initial P1/P5 lifecycle state');
 const p1Key='s466-retired-p1-client-001',p5Key='s466-p5-independent-001';
 const expiredKey='s466-expired-p1-client-001';
 const originalForeign=count("user_id='"+foreign+"'::uuid");
 const originalOwner=count("user_id='"+owner+"'::uuid");
 let retired=false;let session1,session5,passed1,passed5;
 try{
  contentState('retired',Number(p1.content_id));retired=true;
  const unavailable=await rpc('start_exam_prep_session_safe_v1',{
    p_authorization_id:p1.id,p_idempotency_key:p1Key});
  denied(unavailable,'P1 start on retired content');
  assert(unavailable.error.includes('exam_prep_content_version_not_published'),
   'Wrong P1 content error: '+unavailable.error);
  assert(count("user_id='"+owner+"'::uuid AND client_idempotency_key='"+p1Key+"'")===0,
   'Failed start created phantom history');

  const p5Start=good(await rpc('start_exam_prep_session_safe_v1',{
    p_authorization_id:p5.id,p_idempotency_key:p5Key}),
    'P5 must remain usable while P1 unavailable');
  assert(p5Start.component_code==='P5'&&p5Start.resumed===false,
   'P5 content isolation broken');
  session5=p5Start.session_id;
  const activeP5=good(await rpc('get_exam_prep_session_safe_v1',{
    p_session_id:session5,p_language:'ru'}),'read unrelated P5 active session');
  assert(activeP5.status==='active'&&activeP5.component_code==='P5',
   'Other paper was corrupted');

  contentState('published',Number(p1.content_id));retired=false;
  const recovered=good(await rpc('start_exam_prep_session_safe_v1',{
    p_authorization_id:p1.id,p_idempotency_key:p1Key}),
    'P1 resumed real learner start after material restored');
  assert(recovered.component_code==='P1'&&recovered.resumed===false,
   'P1 was not a new recovered session');
  session1=recovered.session_id;
  const retry=good(await rpc('start_exam_prep_session_safe_v1',{
    p_authorization_id:p1.id,p_idempotency_key:p1Key}), 'same-key refresh');
  assert(retry.session_id===session1&&retry.resumed===true,
   'Retry duplicated learner session');
  assert(count("user_id='"+owner+"'::uuid AND client_idempotency_key='"+p1Key+"'")===1,
   'Duplicate client retry created multiple P1 sessions');

  const expiredStart=await rpc('start_exam_prep_session_safe_v1',{
    p_authorization_id:expired.id,p_idempotency_key:expiredKey});
  denied(expiredStart,'expired P1 authorization');
  assert(expiredStart.error.includes('exam_prep_authorization_expired'),
   'Wrong expired session error: '+expiredStart.error);
  denied(await rpc('start_exam_prep_session_safe_v1',{
    p_authorization_id:p1.id,p_idempotency_key:'s466-foreign-attempt-001'},a),
    'foreign learner using another learner authorization');

  for(const [paper,session] of [['P1',session1],['P5',session5]]){
   const active=good(await rpc('get_exam_prep_session_safe_v1',{
    p_session_id:session,p_language:'en'}),'active owner '+paper);
   assert(active.status==='active'&&active.items?.length>0,
    'Active frozen session unavailable');
   assert(active.items.every(x=>!Object.hasOwn(x,'correct_answer')&&
      !Object.hasOwn(x,'explanation')),'Unfinished answer leaked via active session');
   denied(await rpc('get_exam_prep_session_review_safe_v1',{
    p_session_id:session,p_language:'en'}),'owner review before final '+paper);
   denied(await rpc('get_exam_prep_session_review_safe_v1',{
    p_session_id:session,p_language:'en'},a),'foreign active review '+paper);
   denied(await rpc('submit_exam_prep_response_safe_v1',{
    p_session_id:session,p_item_order:1,p_payload:{answer:'A',is_correct:true},
    p_idempotency_key:'s466-tamper-'+paper,
    p_elapsed_ms:1000,p_language:'en'}),'client attempted to forge grade '+paper);
  }
  passed1=await finish(session1,'P1');passed5=await finish(session5,'P5');
  assert(count("user_id='"+owner+"'::uuid")===originalOwner+2,
   'Failed/expired/foreign/replayed requests created extra sessions');
  assert(count("user_id='"+foreign+"'::uuid")===originalForeign,
   'Foreign history mutated');
  assert(count("user_id='"+owner+"'::uuid AND client_idempotency_key='"+expiredKey+"'")===0,
   'Expired authorization persisted session');

  console.log('STAGE C REAL HTTP CONTENT RETIREMENT EXPIRY AND PROTECTED REVIEW PASS',JSON.stringify({
   p1RetiredDenied:true,p5Continues:true,p1RestoredAfterRetry:true,
   p1ExactlyOnceResume:true,expiredAuthorizationDenied:true,
   prefinalReviewDeniedBoth:true,clientForgedGradesDeniedBoth:true,
   foreignOwnerIsolation:true,finalizedP1Items:passed1.items,
   finalizedP5Items:passed5.items,syntheticRealDeviceRuns:0,hostedGoTrueRuns:0
  }));
 }finally{
  if(retired)contentState('published',Number(p1.content_id));
 }
 assert(Number(query('SELECT count(*) FROM public.users'))===2&&
  Number(query('SELECT count(*) FROM public.practice_attempts'))===0&&
  Number(query('SELECT count(*) FROM public.tour_attempts'))===0&&
  Number(query('SELECT count(*) FROM public.certificates'))===0&&
  Number(query('SELECT count(*) FROM private.exam_prep_beta_weekly_reviews'))===0,
  'CI isolation changed real-user-like/legacy/beta records');
 assert(list("SELECT cv.status FROM private.exam_prep_content_versions cv "+
  "WHERE cv.id="+Number(p1.content_id)).every(x=>x.status==='published'),
  'Temporarily retired content was not restored');
 console.log('STAGE C REAL HTTP P1 CONTENT RESTORED TWO DISPOSABLE USER BOUNDARY PASS');
}
main().catch(e=>{console.error('Stage C signed HTTP regression:',e.message);process.exitCode=1});
