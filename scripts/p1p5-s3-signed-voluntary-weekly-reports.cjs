#!/usr/bin/env node
'use strict';
// Voluntary S3 E2E on fake signed learners only. Never connects to production.
const assert=require('node:assert/strict'),crypto=require('node:crypto');
assert(process.env.CI==='true' && process.env.P1P5_E2E_ISOLATED==='true' &&
  process.env.PGHOST==='127.0.0.1' && process.env.PGDATABASE==='postgres',
  'S3 REFUSED: only disposable GitHub PG17 permitted');
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(SECRET && SECRET.length>=32,'S3 ephemeral signing key required');
const A='11111111-1111-4111-8111-111111111191';
const B='22222222-2222-4222-8222-222222222292';
const b64=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function jwt(uid,role='authenticated') {
 const first=b64({alg:'HS256',typ:'JWT'})+'.'+b64({
  aud:'authenticated',sub:uid,role,iat:Math.floor(Date.now()/1000),
  exp:Math.floor(Date.now()/1000)+1800
 });
 return first+'.'+crypto.createHmac('sha256',SECRET).update(first).digest('base64url');
}
async function rpc(name,args={},token=jwt(A)) {
 const res=await fetch('http://127.0.0.1:3000/rpc/'+name,{
  method:'POST',headers:{'Content-Type':'application/json',Accept:'application/json',
   ...(token?{Authorization:'Bearer '+token}:{})},body:JSON.stringify(args)
 });
 let payload=null; try {payload=await res.json();} catch {}
 return {ok:res.ok,status:res.status,data:payload};
}
function ok(r,label) {
 assert(r.ok,label+' HTTP '+r.status+' '+JSON.stringify(r.data).slice(0,400));
 return r.data;
}
async function main() {
 const initial=ok(await rpc('get_my_exam_prep_weekly_choice_s3_safe_v1'),'owner choice');
 assert.equal(initial.contract_version,'voluntary_weekly_choice_s3_v1');
 assert.equal(initial.no_study_cap,true);
 const beforeMinutes=Number(initial.chosen_math_minutes);
 assert(beforeMinutes>0 && beforeMinutes<10080,'real chosen budget required');
 const rev=Number(initial.schedule_revision);
 const mk=(n)=>'s3-test-owner-20261109-'+n+'-abcdefghijklmnop';
 const fields=(choice,p1,p5,day,days,revision,key)=>({
  p_choice_code:choice,p_p1_minutes:p1,p_p5_minutes:p5,
  p_minutes_per_day:day,p_days_per_week:days,
  p_expected_schedule_revision:revision,p_idempotency_key:key
 });
 const keep=fields('keep',null,null,null,null,rev,mk('keep'));
 const first=ok(await rpc('save_my_exam_prep_weekly_choice_s3_safe_v1',keep),'keep');
 assert.equal(first.chosen_math_minutes,beforeMinutes);
 assert.equal(first.academic_marks_changed,false);
 assert.equal(first.replayed,false);
 const retry=ok(await rpc('save_my_exam_prep_weekly_choice_s3_safe_v1',keep),'keep retry');
 assert.equal(retry.replayed,true,'lost ACK must replay without duplicate');
 const wrong=await rpc('save_my_exam_prep_weekly_choice_s3_safe_v1',
  {...keep,p_choice_code:'change'});
 assert(!wrong.ok,'key reuse for changed input must fail');
 const splitBad=await rpc('save_my_exam_prep_weekly_choice_s3_safe_v1',
  fields('redistribute',30,30,null,null,rev,mk('bad')));
 assert(!splitBad.ok,'wrong P1+P5 total must be rejected');
 const p1=Math.round(beforeMinutes/10)*5;
 const p5=beforeMinutes-p1;
 const redistribute=ok(await rpc('save_my_exam_prep_weekly_choice_s3_safe_v1',
   fields('redistribute',p1,p5,null,null,rev,mk('redistribute'))),'redistribute');
 assert.equal(redistribute.chosen_math_minutes,beforeMinutes);
 const unchanged=ok(await rpc('get_exam_prep_study_schedule_safe_v1'),'schedule unchanged');
 assert.equal(Number(unchanged.study_minutes_per_day)*Number(unchanged.study_days_per_week),beforeMinutes);
 const change=ok(await rpc('save_my_exam_prep_weekly_choice_s3_safe_v1',
  fields('change',100,75,35,5,rev,mk('change'))),'explicit new schedule');
 assert.equal(change.chosen_math_minutes,175);
 assert.equal(change.p1_minutes,100);
 assert.equal(change.p5_minutes,75);
 const after=ok(await rpc('get_my_exam_prep_weekly_choice_s3_safe_v1'),'current choice');
 assert.equal(after.chosen_math_minutes,175);
 assert.equal(after.p1_minutes,100);
 assert.equal(after.p5_minutes,75);
 assert.equal(after.no_study_cap,true);
 assert.notEqual(Number(after.schedule_revision),rev,'explicit schedule must increase revision');
 const replay=ok(await rpc('save_my_exam_prep_weekly_choice_s3_safe_v1',
  fields('change',100,75,35,5,rev,mk('change'))),'post-change lost ACK replay');
 assert.equal(replay.replayed,true);
 const stale=await rpc('save_my_exam_prep_weekly_choice_s3_safe_v1',
  fields('keep',null,null,null,null,rev,mk('stale')));
 assert(!stale.ok,'stale device must refresh before writing');
 const reports=ok(await rpc('claim_exam_prep_periodic_study_report_safe_v1'),'claim factual period');
 assert.equal(reports.daily_reminders,false);
 const read=ok(await rpc('get_exam_prep_periodic_study_reports_safe_v1'),'read reports');
 assert(Array.isArray(read.reports),'must return period receipt list');
 assert.equal(read.learner_minutes_verified,false,'never infer minutes from screen opens');
 for(const r of read.reports) {
  assert(['week','month'].includes(r.period_kind));
  assert(r.P1 && r.P5,'paper score must remain separate');
  assert.equal(r.learning_minutes,null,'unknown study duration must remain null');
  assert.equal(r.can_continue_learning,true);
 }
 const noDuplicate=ok(await rpc('claim_exam_prep_periodic_study_report_safe_v1'),'claim retry');
 assert.equal(noDuplicate.reports.length,0,'period must not double-claim');
 const anon=await rpc('get_my_exam_prep_weekly_choice_s3_safe_v1',{},null);
 assert(!anon.ok,'anonymous S3 owner read must be denied');
 const foreign=await rpc('save_my_exam_prep_weekly_choice_s3_safe_v1',keep,jwt(B));
 assert(!foreign.ok || foreign.data?.choice_code==='keep','foreign owner cannot edit owner A');
 const final=ok(await rpc('get_my_exam_prep_weekly_choice_s3_safe_v1'),'owner still isolated');
 assert.equal(final.chosen_math_minutes,175);
 console.log('S3 signed JWT→PostgREST→PG17 PASS: keep/redistribute/change, P1/P5, saved 35×5, idempotent, stale/anon deny, factual period receipts and no study cap/false marks.');
}
main().catch(e=>{console.error('S3 REAL HTTP FAILED:',e.stack||e);process.exitCode=1;});
