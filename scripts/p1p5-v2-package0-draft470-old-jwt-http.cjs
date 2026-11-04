#!/usr/bin/env node
// Issue #450 P0-19: signed HTTP for real PR470 P2-16/P2-17, fake PG17 ONLY.
// Student-chosen personal dates, not official Cambridge/school confirmation.
'use strict';
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const HOST='http://127.0.0.1:3000';
const A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
const OLD=Number(process.env.P0_19_OLD_IAT);
assert(process.env.P1P5_E2E_ISOLATED==='true','P0-19 isolated only');
assert(process.env.PGDATABASE==='postgres' && process.env.PGHOST==='127.0.0.1','P0-19 nonlocal database');
assert(SECRET?.length>=32&&Number.isSafeInteger(OLD)&&OLD>1700000000,'P0-19 fake signed key absent');
const enc=v=>Buffer.from(JSON.stringify(v)).toString('base64url');
function jwt(uid,iat){
 const p=enc({alg:'HS256',typ:'JWT'})+'.'+
  enc({role:'authenticated',aud:'authenticated',sub:uid,iat,exp:iat+1800});
 return p+'.'+crypto.createHmac('sha256',SECRET).update(p).digest('base64url');
}
function read(query){
 assert(query.trimStart().toLowerCase().startsWith('select'),'P0-19 SQL read only');
 return execFileSync('psql',['-X','-At','-v','ON_ERROR_STOP=1','-c',query],
  {encoding:'utf8',timeout:15000}).trim();
}
const snapshotQuery=`SELECT jsonb_build_object(
 'appointments',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_exam_appointments x),
 'dates',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_learner_exam_dates_v1 x),
 'profiles',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_exam_profiles x),
 'sessions',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_sessions x),
 'consent',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_beta_consents x),
 'grants',(SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_feature_entitlements x)
)::text`;
async function rpc(name,args,token){
 assert(['save_my_exam_prep_timeline_dates_safe_v1',
   'accept_my_exam_prep_timeline_weekly_target_safe_v1',
   'get_exam_prep_simple_learning_timeline_safe_v1'].includes(name));
 const resp=await fetch(HOST+'/rpc/'+name,{
  method:'POST',signal:AbortSignal.timeout(15000),
  headers:{'Content-Type':'application/json','Accept':'application/json',
   ...(token?{Authorization:'Bearer '+token}:{})},
  body:JSON.stringify(args)
 });
 const txt=await resp.text();let data;
 try{data=txt?JSON.parse(txt):null;}catch{data=null;}
 return {status:resp.status,ok:resp.ok,data};
}
const personal=['save_my_exam_prep_timeline_dates_safe_v1',
 {p_p1_date:'2027-05-12',p_p5_date:'2027-05-21'}];
const acceptance=['accept_my_exam_prep_timeline_weekly_target_safe_v1',
 {p_expected_current_math_hours:null,p_expected_profile_revision:null,p_new_math_hours:null}];
(async()=>{
 const before=read(snapshotQuery);
 for(const [route,args] of [personal,acceptance]){
  const denied=await rpc(route,args,jwt(A,OLD));
  assert(denied.status===409&&denied.data?.code==='PT409'&&
     denied.data?.message==='p0_16_old_signed_jwt',
     'P0-19 old signed token may write to actual P2 RPC '+route+' '+JSON.stringify(denied));
 }
 assert.equal(read(snapshotQuery),before,'P0-19 rejected prelaunch requests changed fake academic/legacy state');
 const legacyBefore=read(`SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_exam_appointments x`);
 const now=Math.floor(Date.now()/1000);
 assert(now>OLD,'P0-19 new signed token must be issued after stale token');
 const currentJwt=jwt(A,now);
 const saved=await rpc(...personal,currentJwt);
 assert(saved.ok,'P0-19 owner cannot save current personal dates: '+JSON.stringify(saved));
 const db=JSON.parse(read(`SELECT jsonb_build_object(
 'p1',(SELECT exam_date::text FROM private.exam_prep_learner_exam_dates_v1 WHERE user_id='11111111-1111-4111-8111-111111111191'::uuid AND component_code='P1' LIMIT 1),
 'p5',(SELECT exam_date::text FROM private.exam_prep_learner_exam_dates_v1 WHERE user_id='11111111-1111-4111-8111-111111111191'::uuid AND component_code='P5' LIMIT 1),
 'other',(SELECT count(*) FROM private.exam_prep_learner_exam_dates_v1 WHERE user_id='22222222-2222-4222-8222-222222222292'::uuid)
)::text`));
 assert(db.p1==='2027-05-12'&&db.p5==='2027-05-21'&&db.other===0,
  'P0-19 private per-owner separate P1/P5 chosen dates corrupted: '+JSON.stringify(db));
 const legacyAfter=read(`SELECT md5(coalesce(string_agg(to_jsonb(x)::text,'|' ORDER BY to_jsonb(x)::text),'')) FROM private.exam_prep_exam_appointments x`);
 assert.equal(legacyAfter,legacyBefore,'P0-19 personal dates overwrote legacy school-confirmed appointments');
 const projection=await rpc('get_exam_prep_simple_learning_timeline_safe_v1',{},currentJwt);
 assert(projection.ok,'P0-19 actual current simple timeline cannot read personally saved dates: '+JSON.stringify(projection));
 const freshInvalid=await rpc(...acceptance,currentJwt);
 assert(!/p0_16_/.test(freshInvalid.data?.message||''),
  'P0-19 current signed client was rejected by previous academic epoch');
 const anon=await rpc(...personal,null);
 assert(!anon.ok,'P0-19 anonymous changed personal date preferences');
 const other=await rpc(...personal,jwt(B,OLD));
 assert(!other.ok,'P0-19 foreign learner old signed JWT bypassed gate');
 console.log('PASS P0-19 pinned PR470: 2 real new writer RPC old-JWT deny, fresh chosen P1/P5 dates, historical appointment fingerprint intact, owner-scoped read');
})().catch(e=>{console.error('P0-19 FAIL: '+e.message);process.exitCode=1;});
