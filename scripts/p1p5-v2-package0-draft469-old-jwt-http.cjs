#!/usr/bin/env node
// Issue #450 P0-18: pinned draft PR #469 three real migrated writer RPCs.
// Signed localhost PostgREST + disposable fake-user PostgreSQL 17 ONLY.
'use strict';
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const HOST='http://127.0.0.1:3000';
const A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
const OLD=Number(process.env.P0_18_OLD_IAT);
assert(process.env.P1P5_E2E_ISOLATED==='true','P0-18 must be isolated');
assert(process.env.PGDATABASE==='postgres'&&process.env.PGHOST==='127.0.0.1',
 'P0-18 refuses remote database');
assert(SECRET?.length>=32&&Number.isSafeInteger(OLD)&&OLD>1700000000,
 'P0-18 local signed token prerequisites missing');
const enc=v=>Buffer.from(JSON.stringify(v)).toString('base64url');
function jwt(uid,iat){
 const p=enc({alg:'HS256',typ:'JWT'})+'.'+
   enc({role:'authenticated',aud:'authenticated',sub:uid,iat,exp:iat+1800});
 return p+'.'+crypto.createHmac('sha256',SECRET).update(p).digest('base64url');
}
function snapshot(){
 const q=String.raw`SELECT jsonb_build_object(
  'sessions',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_sessions t),
  'authorizations',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_session_authorizations t),
  'profiles',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_exam_profiles t),
  'receipts',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_periodic_study_report_receipts_v1 t),
  'entitlements',(SELECT md5(coalesce(string_agg(to_jsonb(t)::text,'|' ORDER BY to_jsonb(t)::text),'')) FROM private.exam_prep_feature_entitlements t),
  'other_program',(SELECT epoch::text||':'||paused::text FROM private.p0_16_academic_epoch_gate WHERE program_key='economics_as')
 )::text`;
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',q],
  {encoding:'utf8',timeout:15000}).trim();
}
async function rpc(name,args,token){
 const permitted=[
  'save_my_exam_prep_exam_appointment_v2',
  'save_exam_prep_study_schedule_safe_v1',
  'claim_exam_prep_periodic_study_report_safe_v1',
  'get_exam_prep_personal_horizon_safe_v1',
  'get_exam_prep_study_schedule_safe_v1'
 ];
 assert(permitted.includes(name),'unknown draft RPC');
 const result=await fetch(HOST+'/rpc/'+name,{
  method:'POST',signal:AbortSignal.timeout(15000),
  headers:{'Content-Type':'application/json','Accept':'application/json',
   ...(token?{Authorization:'Bearer '+token}:{})},body:JSON.stringify(args)
 });
 const raw=await result.text();let data;
 try{data=raw?JSON.parse(raw):null;}catch{data=null;}
 return {status:result.status,ok:result.ok,data};
}
const writers=[
 ['save_my_exam_prep_exam_appointment_v2',
  {p_component_code:'P1',p_scheduled_start_at:'2027-05-12T08:00:00+05:00',
   p_school_confirmed:true}],
 ['save_exam_prep_study_schedule_safe_v1',
  {p_minutes_per_day:30,p_days_per_week:7}],
 ['claim_exam_prep_periodic_study_report_safe_v1',{}]
];
(async()=>{
 const original=snapshot();
 const oldJwt=jwt(A,OLD);
 for(const [route,args] of writers){
  const denied=await rpc(route,args,oldJwt);
  assert(denied.status===409&&denied.data?.code==='PT409'&&
    denied.data?.message==='p0_16_old_signed_jwt',
    'P0-18 old valid JWT altered/entered actual draft writer: '+
      route+' '+JSON.stringify(denied));
 }
 assert.equal(snapshot(),original,'P0-18 old signed attempts mutated protected rows');
 const now=Math.floor(Date.now()/1000);
 assert(now>OLD,'P0-18 must use a fresh signed JWT issued after cutoff');
 const newJwt=jwt(A,now);
 const saved=await rpc(writers[1][0],writers[1][1],newJwt);
 assert(saved.ok,'P0-18 current signed owner cannot update explicit study cadence: '+JSON.stringify(saved));
 const study=await rpc('get_exam_prep_study_schedule_safe_v1',{},newJwt);
 assert(study.ok,'P0-18 newly migrated read-only study cadence unavailable: '+JSON.stringify(study));
 assert(study.data?.study_minutes_per_day===30&&study.data?.study_days_per_week===7,
   'P0-18 read projection does not match expressly saved cadence');
 const horizon=await rpc('get_exam_prep_personal_horizon_safe_v1',{},newJwt);
 assert(horizon.ok,'P0-18 actual new read-only horizon unavailable: '+JSON.stringify(horizon));
 const other=await rpc(writers[1][0],writers[1][1],jwt(B,OLD));
 assert(!other.ok,'P0-18 another learner should not reuse stale JWT after cutover');
 const anon=await rpc(writers[1][0],writers[1][1],null);
 assert(!anon.ok,'P0-18 anonymous must not alter study cadence');
 console.log('PASS P0-18 pinned PR469: 3 actual new writers reject old JWT, fresh owner schedule saves, 2 projections operate, protected pre/post fingerprint preserved');
})().catch(e=>{console.error('P0-18 FAIL: '+e.message);process.exitCode=1;});
