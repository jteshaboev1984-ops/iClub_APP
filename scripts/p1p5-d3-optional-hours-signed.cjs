#!/usr/bin/env node
'use strict';
// Issue #450 D3: disposable PG17 + actual signed JWT/PostgREST only.
// NEVER connect to production; all states from the isolated fixture.
const assert=require('node:assert/strict'),crypto=require('node:crypto');
assert(process.env.CI==='true' && process.env.P1P5_E2E_ISOLATED==='true' &&
 process.env.PGHOST==='127.0.0.1' && process.env.PGDATABASE==='postgres',
 'D3 refused outside ephemeral PostgreSQL17');
const secret=process.env.P1P5_E2E_JWT_SECRET;
assert(secret?.length>=32,'D3 ephemeral JWT key required');
const C='33333333-3333-4333-8333-333333333393';
const D='44444444-4444-4444-8444-444444444494';
const b=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function jwt(uid) {
 const head=b({alg:'HS256',typ:'JWT'})+'.'+b({aud:'authenticated',sub:uid,
  role:'authenticated',iat:Math.floor(Date.now()/1000),
  exp:Math.floor(Date.now()/1000)+1800});
 return head+'.'+crypto.createHmac('sha256',secret).update(head).digest('base64url');
}
async function rpc(name,args={},token=jwt(C)){
 const response=await fetch('http://127.0.0.1:3000/rpc/'+name,{
  method:'POST',headers:{'Content-Type':'application/json',Accept:'application/json',
   ...(token?{Authorization:'Bearer '+token}:{})},
  body:JSON.stringify(args)
 });
 let data;try{data=await response.json()}catch{data=null}
 return {ok:response.ok,status:response.status,data};
}
function valid(result,label){
 assert(result.ok,label+' '+result.status+' '+JSON.stringify(result.data).slice(0,450));
 return result.data;
}
async function main(){
 const profileArgs={
  p_exam_series:'May/June 2027',p_target_grade:'A',
  p_total_student_hours_available:null,p_mathematics_hours_budget:null
 };
 const created=valid(await rpc('save_exam_prep_exam_profile_v2',profileArgs),
   'create profile without compulsory hours');
 assert.equal(created.total_student_hours_available,null);
 assert.equal(created.mathematics_hours_budget,null);
 assert.equal(created.progress_retained,true);
 const profile=valid(await rpc('get_exam_prep_exam_profile_v1'),
  'read unsigned hours profile');
 const first=Array.isArray(profile)?profile[0]:profile;
 assert.equal(first.total_student_hours_available,null);
 assert.equal(first.mathematics_hours_budget,null);

 const weekly=valid(await rpc('get_my_exam_prep_weekly_choice_s3_safe_v1'),
  'read no-budget S3 choice');
 assert.equal(weekly.chosen_math_minutes,null,
  'unknown budget must stay null, never zero or fabricated 150');
 assert.equal(weekly.choice_recorded,false);
 const schedule=valid(await rpc('get_exam_prep_study_schedule_safe_v1'),
  'read optional study schedule');
 assert.equal(schedule.study_minutes_per_day,null);
 assert.equal(schedule.study_days_per_week,null);
 assert.equal(schedule.schedule_confirmed,false);

 const capacity=valid(await rpc('get_exam_prep_shared_study_capacity_safe_v1'),
  'no-budget capacity must not block');
 assert.equal(capacity.chosen_math_hours_per_week,null);
 assert.equal(capacity.planned_shared_math_hours_to_earliest_exam,null);
 const placement=valid(await rpc('get_exam_prep_placement_safe_v1',
  {p_component_code:null}),'placement should not need hour budget');
 assert(placement && typeof placement==='object');

 for(const component of ['P1','P5']){
   const progress=valid(await rpc('get_exam_prep_diagnostic_progress_safe_v1',
    {p_component_code:component}),'diagnostic progress without hours '+component);
   assert(progress,'diagnostic response without weekly budget');
   const started=valid(await rpc('start_exam_prep_next_diagnostic_safe_v1',
    {p_component_code:component,
     p_idempotency_key:'d3-optional-'+component.toLowerCase()+'-start-20261111'}),
    'diagnostic starts without hours '+component);
   assert(started,'diagnostic must return data '+component);
 }
 const before=valid(await rpc('get_my_exam_prep_weekly_choice_s3_safe_v1'),
   'still no schedule after P1/P5 entry');
 assert.equal(before.chosen_math_minutes,null);

 const denied=await rpc('save_exam_prep_exam_profile_v2',{
   ...profileArgs,p_total_student_hours_available:2,
   p_mathematics_hours_budget:3
 });
 assert(!denied.ok,'invalid positive Math>total hours must fail');

 const chosen=valid(await rpc('save_exam_prep_study_schedule_safe_v1',{
  p_minutes_per_day:40,p_days_per_week:5
 }),'voluntary schedule after diagnostics without total hours');
 assert.equal(chosen.study_minutes_per_day,40);
 assert.equal(chosen.study_days_per_week,5);
 assert.equal(chosen.total_student_hours_per_week,null,
  'choosing math cadence may not invent total study hours');
 assert.equal(Math.round(Number(chosen.mathematics_hours_per_week)*60),200,
  'legacy 2-decimal budget must round to exact chosen cadence minutes');
 const current=valid(await rpc('get_my_exam_prep_weekly_choice_s3_safe_v1'),
  'S3 after voluntary explicit schedule');
 assert.equal(current.chosen_math_minutes,200);
 assert.equal(current.total_available_minutes,null);
 assert.equal(current.no_study_cap,true);
 const choice=valid(await rpc('save_my_exam_prep_weekly_choice_s3_safe_v1',{
  p_choice_code:'redistribute',p_p1_minutes:110,p_p5_minutes:90,
  p_minutes_per_day:null,p_days_per_week:null,
  p_expected_schedule_revision:current.schedule_revision,
  p_idempotency_key:'d3-optional-redistribute-20261111'
 }),'redistribute exact 200min without chosen total');
 assert.equal(choice.chosen_math_minutes,200);
 assert.equal(choice.academic_marks_changed,false);
 const after=valid(await rpc('get_exam_prep_exam_profile_v1'),
  'exam profile after voluntary schedule');
 const afterRow=Array.isArray(after)?after[0]:after;
 assert.equal(afterRow.total_student_hours_available,null);
 assert.equal(Math.round(Number(afterRow.mathematics_hours_budget)*60),200,
  'legacy numeric(8,2) still represents 200 rounded cadence minutes');

 const foreign=valid(await rpc('get_exam_prep_exam_profile_v1',{},jwt(D)),
  'separate browser-only profile stays empty');
 assert(Array.isArray(foreign)&&foreign.length===0,
   'C cannot create a profile for D');
 const anon=await rpc('save_exam_prep_exam_profile_v2',profileArgs,null);
 assert(!anon.ok,'unauthenticated cannot create optional-hours profile');
 console.log('D3 signed JWT/PostgREST/PG17 PASS: nullable profile, P1/P5 entry, unknown budget, late exact 200min schedule, S3 split, preserved total, anonymous deny.');
}
main().catch(e=>{console.error(e.stack||e);process.exitCode=1;});
