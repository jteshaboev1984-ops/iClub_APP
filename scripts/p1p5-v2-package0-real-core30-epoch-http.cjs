#!/usr/bin/env node
// Issue #450 P0-17: authenticated real RPC HTTP for 24 additional Core writer
// entrypoints, after P0-16 six real RPCs passed. Locally hosted fake PG17 ONLY.
'use strict';
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
const ISSUED_AT=Number(process.env.P0_17_OLD_IAT);
const HOST='http://127.0.0.1:3000';
const UID='11111111-1111-4111-8111-111111111191';
assert(process.env.P1P5_E2E_ISOLATED==='true','P0-17 disposable flag absent');
assert(process.env.PGDATABASE==='postgres' && process.env.PGHOST==='127.0.0.1',
  'P0-17 refuses external database');
assert(SECRET?.length>=32,'P0-17 local JWT secret missing');
assert(Number.isSafeInteger(ISSUED_AT) && ISSUED_AT>1700000000,
  'P0-17 requires actual signed pre-cutover issued-at');
const names=[
  'advance_exam_prep_written_step_safe_v1',
  'authorize_exam_prep_correction_safe_v1',
  'authorize_exam_prep_goal_once_safe_v1',
  'authorize_exam_prep_mixed_safe_v1',
  'authorize_exam_prep_plan_item_safe_v1',
  'authorize_exam_prep_retest_safe_v1',
  'authorize_exam_prep_revalidation_item_safe_v1',
  'ensure_exam_prep_balanced_weekly_plan_safe_v1',
  'ensure_exam_prep_stable_weekly_plan_safe_v1',
  'ensure_exam_prep_weekly_goals_safe_v1',
  'finalize_exam_prep_session_written_v1',
  'finalize_exam_prep_timed_safe_v1',
  'generate_exam_prep_weekly_plan_safe_v1',
  'generate_exam_prep_weekly_plan_safe_v2',
  'generate_exam_prep_weekly_plan_safe_v3',
  'record_exam_prep_integrity_event_safe_v1',
  'record_my_exam_prep_interruption_v1',
  'record_my_exam_prep_interruption_v2',
  'save_exam_prep_exam_profile_v1',
  'save_my_exam_prep_exam_appointment_v1',
  'set_my_exam_prep_exam_ops_confirmation_v1',
  'start_exam_prep_learning_review_safe_v1',
  'start_exam_prep_plan_session_once_safe_v1',
  'submit_exam_prep_timed_written_self_mark_safe_v1'
];
assert(names.length===24&&new Set(names).size===24,'P0-17 allowlist changed');
function sqlRead(text){
 assert(text.trimStart().toUpperCase().startsWith('SELECT') ||
        text.trimStart().toUpperCase().startsWith('WITH'),
   'P0-17 never performs DML/DDL through psql');
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',text],
  {encoding:'utf8',timeout:20000}).trim();
}
const fingerprintSQL=`SELECT jsonb_build_object(
 'users',(SELECT count(*) FROM public.users),
 'auth_users',(SELECT count(*) FROM auth.users),
 'sessions',(SELECT count(*) FROM private.exam_prep_sessions),
 'authorizations',(SELECT count(*) FROM private.exam_prep_session_authorizations),
 'responses',(SELECT count(*) FROM private.exam_prep_responses),
 'beta_consents',(SELECT count(*) FROM private.exam_prep_beta_consents),
 'ai_grants',(SELECT count(*) FROM private.exam_prep_feature_entitlements WHERE ai_assist AND entitlement_status='active'),
 'math_gate',(SELECT epoch::text||':'||paused::text FROM private.p0_16_academic_epoch_gate WHERE program_key='math_as_p1_p5'),
 'other_gate',(SELECT epoch::text||':'||paused::text FROM private.p0_16_academic_epoch_gate WHERE program_key='economics_as'),
 'users_digest',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM public.users x),
 'auth_digest',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM auth.users x),
 'sessions_digest',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_sessions x),
 'authorizations_digest',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_session_authorizations x),
 'responses_digest',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_responses x),
 'profiles_digest',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_exam_profiles x),
 'consents_digest',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_beta_consents x),
 'entitlements_digest',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_feature_entitlements x),
 'practice_digest',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM public.practice_attempts x),
 'tours_digest',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM public.tour_attempts x),
 'certificates_digest',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM public.certificates x)
)::text`;
const before=sqlRead(fingerprintSQL);
const sql= `SELECT COALESCE(jsonb_agg(jsonb_build_object(
 'name',p.proname,'args',p.proargnames[1:p.pronargs]
) ORDER BY p.proname),'[]'::jsonb)::text
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname='public' AND p.proname=ANY(ARRAY[
'advance_exam_prep_written_step_safe_v1','authorize_exam_prep_correction_safe_v1','authorize_exam_prep_goal_once_safe_v1','authorize_exam_prep_mixed_safe_v1','authorize_exam_prep_plan_item_safe_v1','authorize_exam_prep_retest_safe_v1','authorize_exam_prep_revalidation_item_safe_v1','ensure_exam_prep_balanced_weekly_plan_safe_v1','ensure_exam_prep_stable_weekly_plan_safe_v1','ensure_exam_prep_weekly_goals_safe_v1','finalize_exam_prep_session_written_v1','finalize_exam_prep_timed_safe_v1','generate_exam_prep_weekly_plan_safe_v1','generate_exam_prep_weekly_plan_safe_v2','generate_exam_prep_weekly_plan_safe_v3','record_exam_prep_integrity_event_safe_v1','record_my_exam_prep_interruption_v1','record_my_exam_prep_interruption_v2','save_exam_prep_exam_profile_v1','save_my_exam_prep_exam_appointment_v1','set_my_exam_prep_exam_ops_confirmation_v1','start_exam_prep_learning_review_safe_v1','start_exam_prep_plan_session_once_safe_v1','submit_exam_prep_timed_written_self_mark_safe_v1'
])`;
const routes=JSON.parse(sqlRead(sql));
assert(routes.length===24,'P0-17 function count drift: '+routes.length);
const enc=o=>Buffer.from(JSON.stringify(o)).toString('base64url');
function token(iat) {
 const h=enc({alg:'HS256',typ:'JWT'});
 const b=enc({role:'authenticated',aud:'authenticated',sub:UID,iat,exp:iat+1800});
 const msg=h+'.'+b;
 return msg+'.'+crypto.createHmac('sha256',SECRET).update(msg).digest('base64url');
}
async function httpRpc(name,args,jwt){
 assert(names.includes(name),'P0-17 unknown RPC URL');
 const r=await fetch(HOST+'/rpc/'+name,{
  method:'POST',signal:AbortSignal.timeout(15000),
  headers:{'Content-Type':'application/json','Accept':'application/json',
   Authorization:'Bearer '+jwt},
  body:JSON.stringify(args)
 });
 const raw=await r.text();let data;
 try{data=raw?JSON.parse(raw):null;}catch{data=null;}
 return {status:r.status,ok:r.ok,data};
}
(async()=>{
 const oldJwt=token(ISSUED_AT);
 let attempted=0;
 for(const route of routes){
   assert(names.includes(route.name),'unlisted RPC returned from local PG catalog');
   assert(Array.isArray(route.args)&&route.args.length>0,
     'P0-17 unnamed or missing RPC arguments: '+route.name);
   const args=Object.fromEntries(route.args.map(name=>[name,null]));
   const result=await httpRpc(route.name,args,oldJwt);
   assert(result.status===409&&result.data?.code==='PT409'&&
       /p0_16_old_signed_jwt/.test(result.data?.message||''),
     'P0-17 old valid signed JWT did not reach epoch gate for REAL '+route.name+
     ': '+JSON.stringify(result));
   attempted++;
 }
 const current=Math.floor(Date.now()/1000);
 assert(current>ISSUED_AT,'P0-17 must not forge a future JWT');
 const sampled=routes.find(r=>r.name==='advance_exam_prep_written_step_safe_v1');
 const freshArgs=Object.fromEntries(sampled.args.map(name=>[name,null]));
 const freshResult=await httpRpc(sampled.name,freshArgs,token(current));
 assert(!/p0_16_/.test(freshResult.data?.message||''),
   'P0-17 current JWT unexpectedly trapped by previous epoch fence');
 const after=sqlRead(fingerprintSQL);
 assert.equal(after,before,'P0-17 old-token negative calls changed protected fixture counts');
 assert.equal(attempted,24);
 console.log('PASS P0-17 24 additional REAL Core RPCs reject old signed JWT; 30/30 actual Core writer roots shadow-covered, 7 non-Core retained separately');
})().catch(e=>{console.error('P0-17 FAIL: '+e.message);process.exitCode=1;});
