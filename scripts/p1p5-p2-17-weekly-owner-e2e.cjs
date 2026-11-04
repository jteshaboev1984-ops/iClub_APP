#!/usr/bin/env node
'use strict';
// Only synthetic disposable 2-user PG17 over signed localhost HTTP.
// Each phase is a separate GitHub Actions step: failure is visible without logs.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const HOST='http://127.0.0.1:3000',UID='11111111-1111-4111-8111-111111111191';
const secret=process.env.P1P5_E2E_JWT_SECRET,phase=String(process.argv[2]||'');
assert(process.env.P1P5_E2E_ISOLATED==='true','REFUSED: disposable PG17 only');
assert(secret&&secret.length>=32,'REFUSED: missing disposable JWT key');
assert(['dates','tampered','stale','anonymous','accept','replay','restore'].includes(phase),'Expected one named phase');
function tok(o){return Buffer.from(JSON.stringify(o)).toString('base64url')}
function jwt(uid){
 const now=Math.floor(Date.now()/1000),data=tok({alg:'HS256',typ:'JWT'})+'.'+tok({
  role:'authenticated',aud:'authenticated',sub:uid,iat:now,exp:now+600
 });
 return data+'.'+crypto.createHmac('sha256',secret).update(data).digest('base64url');
}
async function rpc(name,args={},uid=UID){
 const r=await fetch(HOST+'/rpc/'+name,{method:'POST',headers:{
  'Content-Type':'application/json',Accept:'application/json',
  ...(uid?{Authorization:'Bearer '+jwt(uid)}:{})
 },body:JSON.stringify(args),signal:AbortSignal.timeout(20000)});
 let d=null;try{d=await r.json()}catch{}
 return {ok:r.ok,status:r.status,data:d};
}
async function ok(name,args={},uid=UID){
 const r=await rpc(name,args,uid);
 assert(r.ok,name+' HTTP '+r.status+' '+JSON.stringify(r.data).slice(0,250));
 return r.data;
}
async function timeline(){return ok('get_exam_prep_simple_learning_timeline_with_hours_safe_v2')}
async function dates(p1,p5){
 return ok('save_my_exam_prep_timeline_dates_safe_v1',{p_p1_date:p1,p_p5_date:p5})
}
function dateAfter(n){
 const p=Object.fromEntries(new Intl.DateTimeFormat('en-GB',{
  timeZone:'Asia/Tashkent',year:'numeric',month:'2-digit',day:'2-digit'
 }).formatToParts(new Date(Date.now()+86400000*n))
  .filter(x=>['year','month','day'].includes(x.type)).map(x=>[x.type,x.value]));
 return p.year+'-'+p.month+'-'+p.day;
}
function baseline(m){
 assert.equal(m.student_total_hours_per_week,12);
 assert.equal(m.existing_chosen_math_hours_per_week,6);
 assert(m.estimated_remaining_math_hours>0);
 assert(Number.isInteger(m.student_budget_profile_revision));
}
async function main(){
 if(phase==='dates'){
  const m=await timeline();baseline(m);
  const n=Math.max(45,Math.ceil(m.estimated_remaining_math_hours/9*7)+3);
  const selected=await dates(dateAfter(n-7),dateAfter(n));
  baseline(selected);
  assert(selected.estimated_joint_math_hours_per_week>6 &&
   selected.estimated_joint_math_hours_per_week<=12,
   'No feasible weekly target for actual source-based content');
 }
 if(['tampered','stale','anonymous'].includes(phase)){
  const m=await timeline();baseline(m);
  const rec=m.estimated_joint_math_hours_per_week,rev=m.student_budget_profile_revision;
  assert(rec>6&&rec<=12,'Source-based suggested hours outside test bounds');
  const checks={
   tampered:{uid:UID,expected:'altered value',
    args:{p_expected_current_math_hours:6,p_expected_profile_revision:rev,
     p_new_math_hours:Math.round((rec+.1)*10)/10}},
   stale:{uid:UID,expected:'outdated revision',
    args:{p_expected_current_math_hours:6,p_expected_profile_revision:rev-1,
     p_new_math_hours:rec}},
   anonymous:{uid:null,expected:'unauthenticated actor',
    args:{p_expected_current_math_hours:6,p_expected_profile_revision:rev,
     p_new_math_hours:rec}}
  };
  const test=checks[phase];
  const response=await rpc('accept_my_exam_prep_timeline_weekly_target_safe_v1',test.args,test.uid);
  assert(!response.ok,phase+' must be rejected for '+test.expected);
  const after=await timeline();baseline(after);
  assert.equal(after.student_budget_profile_revision,rev);
 }
 if(phase==='accept'){
  const before=await timeline();baseline(before);
  const rec=before.estimated_joint_math_hours_per_week,rev=before.student_budget_profile_revision;
  assert(rec>6&&rec<=12);
  const after=await ok('accept_my_exam_prep_timeline_weekly_target_safe_v1',{
   p_expected_current_math_hours:6,p_expected_profile_revision:rev,p_new_math_hours:rec
  });
  assert.equal(after.existing_chosen_math_hours_per_week,rec);
  assert.equal(after.student_budget_profile_revision,rev+1);
  assert.equal(after.estimated_remaining_math_hours,before.estimated_remaining_math_hours);
  for(const k of ['P1','P5'])
   assert.equal(after[k].objectively_covered_skills,before[k].objectively_covered_skills);
 }
 if(phase==='replay'){
  const m=await timeline(),rec=m.existing_chosen_math_hours_per_week;
  assert(rec>6&&rec<=12);
  const bad=await rpc('accept_my_exam_prep_timeline_weekly_target_safe_v1',{
   p_expected_current_math_hours:6,p_expected_profile_revision:m.student_budget_profile_revision-1,
   p_new_math_hours:rec
  });
  assert(!bad.ok,'Stale double-tap must be denied');
  const urgent=await dates(dateAfter(28),dateAfter(30));
  assert(urgent.estimated_joint_math_hours_per_week>12);
  const cap=await rpc('accept_my_exam_prep_timeline_weekly_target_safe_v1',{
   p_expected_current_math_hours:rec,
   p_expected_profile_revision:m.student_budget_profile_revision,
   p_new_math_hours:urgent.estimated_joint_math_hours_per_week
  });
  assert(!cap.ok,'Over-capacity budget change must be denied');
  const after=await timeline();
  assert.equal(after.existing_chosen_math_hours_per_week,rec);
  assert.equal(after.student_budget_profile_revision,m.student_budget_profile_revision);
 }
 if(phase==='restore'){
  const before=await timeline();
  assert(before.existing_chosen_math_hours_per_week>6);
  const response=await ok('save_exam_prep_exam_profile_v2',{
   p_exam_series:'May/June 2027',p_target_grade:'A',
   p_total_student_hours_available:12,p_mathematics_hours_budget:6
  });
  assert.equal(response.mathematics_hours_budget,6);
  const restored=await timeline();baseline(restored);
  assert.equal(restored.student_budget_profile_revision,before.student_budget_profile_revision+1);
  assert.equal(restored.estimated_remaining_math_hours,before.estimated_remaining_math_hours);
  for(const k of ['P1','P5'])
   assert.equal(restored[k].objectively_covered_skills,before[k].objectively_covered_skills);
 }
 console.log('PASS P2-17 phase='+phase);
}
main().catch(e=>{
 console.error('FAIL P2-17 phase='+phase+' '+String(e?.message||e).slice(0,300));
 process.exitCode=1;
});
