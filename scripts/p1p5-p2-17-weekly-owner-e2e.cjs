#!/usr/bin/env node
'use strict';
// Reuses ONLY the two disposable PG17 learners and actual Stage0/learning
// evidence already produced by the existing signed HTTP Chromium E2E.
// This test does not create an invented student, fake grade, or study minutes.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const HOST='http://127.0.0.1:3000';
const USER_A='11111111-1111-4111-8111-111111111191';
const USER_B='22222222-2222-4222-8222-222222222292';
const secret=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.P1P5_E2E_ISOLATED==='true','REFUSED: not isolated PG17');
assert(secret&&secret.length>=32,'REFUSED: missing disposable JWT key');
function enc(x){return Buffer.from(JSON.stringify(x)).toString('base64url')}
function token(uid){
 const n=Math.floor(Date.now()/1000);
 const msg=enc({alg:'HS256',typ:'JWT'})+'.'+enc({role:'authenticated',aud:'authenticated',sub:uid,iat:n,exp:n+900});
 return msg+'.'+crypto.createHmac('sha256',secret).update(msg).digest('base64url');
}
async function request(uid){
 const r=await fetch(HOST+'/rpc/get_exam_prep_workload_review_projection_safe_v1',{
   method:'POST',
   headers:{'Content-Type':'application/json',Accept:'application/json',
            ...(uid?{Authorization:'Bearer '+token(uid)}:{})},
   body:'{}'
 });
 let data;try{data=await r.json()}catch{data=null}
 return {ok:r.ok,status:r.status,data};
}

async function signedRpc(name, uid, args={}) {
 const response=await fetch(HOST+'/rpc/'+name,{
  method:'POST',
  headers:{'Content-Type':'application/json',Accept:'application/json',
    ...(uid?{Authorization:'Bearer '+token(uid)}:{})},
  body:JSON.stringify(args)
 });
 let data=null;try{data=await response.json()}catch{}
 return {ok:response.ok,status:response.status,data};
}

const safeISOString=(n)=>new Intl.DateTimeFormat('en-GB',{
 timeZone:'Asia/Tashkent',year:'numeric',month:'2-digit',day:'2-digit'
}).formatToParts(new Date(Date.now()+n*86400000))
 .filter(x=>['year','month','day'].includes(x.type))
 .reduce((o,x)=>(o[x.type]=x.value,o),{});
function dateAfter(n){const x=safeISOString(n);return x.year+'-'+x.month+'-'+x.day;}
let phase='start';
(async()=>{
 phase='baseline';
 const snapshot=await signedRpc('get_exam_prep_simple_learning_timeline_with_hours_safe_v2',USER_A);
 assert(snapshot.ok,'P2-17 baseline unavailable '+snapshot.status);
 const hoursBefore=snapshot.data.estimated_remaining_math_hours;
 const objectiveBefore=[snapshot.data.P1.objectively_covered_skills,snapshot.data.P5.objectively_covered_skills];
 phase='1 choose test-only future exam dates';
 // P2-17: approximate weekly target is ADVISORY until explicit owner click.
 // Use actual signed student and real source-based hours in disposable PG17.
 const studyDays=Math.max(45,Math.ceil(hoursBefore/9*7)+3);
 const weekDates=await signedRpc('save_my_exam_prep_timeline_dates_safe_v1',USER_A,{
   p_p1_date:dateAfter(studyDays-7),p_p5_date:dateAfter(studyDays)
 });
 assert(weekDates.ok,'P2-17 test must use real learner selected days');
 const beforeAccept=weekDates.data;
 assert.equal(beforeAccept.student_total_hours_per_week,12);
 assert.equal(beforeAccept.existing_chosen_math_hours_per_week,6);
 assert(Number.isInteger(beforeAccept.student_budget_profile_revision));
 const initialRevision=beforeAccept.student_budget_profile_revision;
 const suggested=beforeAccept.estimated_joint_math_hours_per_week;
 assert(suggested>6 && suggested<=12,'Test fixture must require a realistic feasible increase');
 assert.equal(beforeAccept.recommended_schedule_applied_automatically,false);
 phase='2 tampered/stale/anonymous safety';
 const staleTarget=await signedRpc('accept_my_exam_prep_timeline_weekly_target_safe_v1',USER_A,{
   p_expected_current_math_hours:6,
   p_expected_profile_revision:initialRevision,
   p_new_math_hours:Math.round((suggested+0.1)*10)/10
 });
 assert(!staleTarget.ok,'Client must not alter suggested number independently');
 const badRevision=await signedRpc('accept_my_exam_prep_timeline_weekly_target_safe_v1',USER_A,{
   p_expected_current_math_hours:6,
   p_expected_profile_revision:initialRevision-1,
   p_new_math_hours:suggested
 });
 assert(!badRevision.ok,'Lost-update profile revision must reject');
 const anonAccept=await signedRpc('accept_my_exam_prep_timeline_weekly_target_safe_v1',null,{
   p_expected_current_math_hours:6,
   p_expected_profile_revision:initialRevision,
   p_new_math_hours:suggested
 });
 assert(!anonAccept.ok,'Anonymous Math budget acceptance not allowed');
 const noWrite=await signedRpc('get_exam_prep_simple_learning_timeline_with_hours_safe_v2',USER_A);
 assert(noWrite.ok);
 assert.equal(noWrite.data.existing_chosen_math_hours_per_week,6,
   'Invalid or anonymous accept must NEVER alter profile');
 phase='3 owner accept budget through existing v2 writer';
 const accepted=await signedRpc('accept_my_exam_prep_timeline_weekly_target_safe_v1',USER_A,{
   p_expected_current_math_hours:6,
   p_expected_profile_revision:initialRevision,
   p_new_math_hours:suggested
 });
 assert(accepted.ok,'Authenticated explicit recommended-hours acceptance failed '+accepted.status+' '+JSON.stringify(accepted.data));
 assert.equal(accepted.data.existing_chosen_math_hours_per_week,suggested);
 assert.equal(accepted.data.student_total_hours_per_week,12);
 assert.equal(accepted.data.student_budget_profile_revision,initialRevision+1);
 assert.equal(accepted.data.estimated_remaining_math_hours,hoursBefore,
   'Accepting schedule must not recalculate academic mastery');
 assert.equal(accepted.data.P1.objectively_covered_skills,objectiveBefore[0]);
 assert.equal(accepted.data.P5.objectively_covered_skills,objectiveBefore[1]);
 phase='4 replay and over-capacity refusal';
 const repeatAccept=await signedRpc('accept_my_exam_prep_timeline_weekly_target_safe_v1',USER_A,{
   p_expected_current_math_hours:6,
   p_expected_profile_revision:initialRevision,
   p_new_math_hours:suggested
 });
 assert(!repeatAccept.ok,'Double-tap old profile must fail closed and not double-write');
 const tight=await signedRpc('save_my_exam_prep_timeline_dates_safe_v1',USER_A,{
   p_p1_date:dateAfter(28),p_p5_date:dateAfter(30)
 });
 assert(tight.ok);
 const impossible=tight.data.estimated_joint_math_hours_per_week;
 assert(impossible>12,'Tight deadline should exceed actual 12h whole-week budget');
 const overCapacity=await signedRpc('accept_my_exam_prep_timeline_weekly_target_safe_v1',USER_A,{
   p_expected_current_math_hours:suggested,
   p_expected_profile_revision:accepted.data.student_budget_profile_revision,
   p_new_math_hours:impossible
 });
 assert(!overCapacity.ok,'Never set more Mathematics hours than full weekly availability');
 const afterNo=await signedRpc('get_exam_prep_simple_learning_timeline_with_hours_safe_v2',USER_A);
 assert(afterNo.ok);
 assert.equal(afterNo.data.existing_chosen_math_hours_per_week,suggested,
   'Capacity rejection cannot partially update profile');
 assert.equal(afterNo.data.estimated_remaining_math_hours,hoursBefore);
 // Restore the ONLY synthetic 6h budget via normal existing governed v2 writer.
 phase='5 restore original synthetic profile';
 const restoredHours=await signedRpc('save_exam_prep_exam_profile_v2',USER_A,{
   p_exam_series:'May/June 2027',p_target_grade:'A',
   p_total_student_hours_available:12,p_mathematics_hours_budget:6
 });
 assert(restoredHours.ok,'Fixture restoration through existing public v2 writer failed');
 const afterRestore=await signedRpc('get_exam_prep_simple_learning_timeline_with_hours_safe_v2',USER_A);
 assert(afterRestore.ok);
 assert.equal(afterRestore.data.existing_chosen_math_hours_per_week,6);
 assert.equal(afterRestore.data.P1.objectively_covered_skills,objectiveBefore[0]);
 assert.equal(afterRestore.data.P5.objectively_covered_skills,objectiveBefore[1]);
 console.log('PASS P2-17: real JWT owner explicit target acceptance, profile audit revision, stale/anon/over-capacity rejection, no progress changes');

})().catch(err=>{
 console.error('P2-17 ISOLATED FAILURE phase='+phase+' cause='+String(err?.message||err).slice(0,480));
 process.exitCode=1;
});
