#!/usr/bin/env node
'use strict';
// Issue #450 D10: real signed owner JWT -> disposable PostgREST -> PG17.
// Previously P2-17 demonstrated opt-in acceptance of *heuristic* Cambridge
// 2020 teacher hours. Academic 81-skill independent-study norms are unapproved.
// Preserve the seven CI phases, but verify current numerical advice is NULL,
// direct accept/keep requests are rejected and profile progress is unchanged.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const HOST='http://127.0.0.1:3000',UID='11111111-1111-4111-8111-111111111191';
const secret=process.env.P1P5_E2E_JWT_SECRET,phase=String(process.argv[2]||'');
assert(process.env.P1P5_E2E_ISOLATED==='true','REFUSED: disposable PG17 only');
assert(secret&&secret.length>=32,'REFUSED: missing disposable JWT key');
assert(['dates','tampered','stale','anonymous','accept','replay','restore'].includes(phase));
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
async function ok(name,args={}) {
  const r=await rpc(name,args);
  assert(r.ok,name+' HTTP '+r.status+' '+JSON.stringify(r.data).slice(0,250));
  return r.data;
}
async function timeline(){return ok('get_exam_prep_simple_learning_timeline_with_hours_safe_v2')}
function baseline(m){
  assert.equal(m.contract_version,'exam_prep_one_line_progress_timeline_v2_academic_review_pending');
  assert.equal(m.numeric_recommendation_enabled,false);
  assert.equal(m.recommendation_accept_enabled,false);
  assert.equal(m.student_total_hours_per_week,12);
  assert.equal(m.existing_chosen_math_hours_per_week,6);
  assert(Number.isInteger(m.student_budget_profile_revision));
  for(const key of ['estimated_remaining_math_hours','estimated_joint_math_hours_per_week',
    'estimated_weekly_hours_difference_from_chosen']) assert.equal(m[key],null,key);
  for(const [code,n] of [['P1',45],['P5',36]]){
    assert.equal(m[code].total_syllabus_skills,n);
    assert.equal(m[code].estimated_remaining_study_hours,null);
    assert.equal(m[code].estimated_component_weekly_hours,null);
    const x=m[code];
    assert.equal(x.objectively_covered_skills+
      x.already_attempted_not_yet_confirmed_skills+x.not_yet_checked_skills,n);
  }
}
function params(revision,number=8){
  return {p_expected_current_math_hours:6,p_expected_profile_revision:revision,
    p_new_math_hours:number};
}
async function rejected(name,args,uid=UID){
  const response=await rpc(name,args,uid);
  assert(!response.ok,name+' must fail closed without independently approved time norms');
  return response;
}
async function main(){
  if(phase==='dates'){
    const m=await timeline();baseline(m);
    // Explicit dates are disposable test inputs, not claimed Cambridge dates.
    const saved=await ok('save_my_exam_prep_timeline_dates_safe_v1',{
      p_p1_date:'2027-05-12',p_p5_date:'2027-05-20'
    });
    baseline(saved);
    assert.equal(saved.P1.exam_date_status,'valid_exam_date');
    assert.equal(saved.P5.exam_date_status,'valid_exam_date');
  }
  if(['tampered','stale','anonymous'].includes(phase)){
    const m=await timeline();baseline(m);
    const args=params(m.student_budget_profile_revision-
      (phase==='stale'?1:0),phase==='tampered'?9:8);
    const bad=await rejected('accept_my_exam_prep_timeline_weekly_target_safe_v1',
      args,phase==='anonymous'?null:UID);
    if(phase==='stale'){
      assert.equal(bad.status,409,'Stale profile should return non-retryable 409');
      assert.equal(bad.data?.code,'PT409');
    }
    const after=await timeline();baseline(after);
    assert.equal(after.student_budget_profile_revision,m.student_budget_profile_revision);
  }
  if(phase==='accept'){
    const before=await timeline();baseline(before);
    await rejected('accept_my_exam_prep_timeline_weekly_target_safe_v1',
      params(before.student_budget_profile_revision));
    const after=await timeline();baseline(after);
    assert.equal(after.student_budget_profile_revision,before.student_budget_profile_revision);
    for(const code of ['P1','P5'])
      assert.equal(after[code].objectively_covered_skills,before[code].objectively_covered_skills);
  }
  if(phase==='replay'){
    const before=await timeline();baseline(before);
    const args={p_expected_current_math_hours:6,
      p_expected_profile_revision:before.student_budget_profile_revision,
      p_expected_suggested_math_hours:8,
      p_idempotency_key:'D10-unapproved-norm-refusal-v1'};
    await rejected('keep_my_exam_prep_timeline_weekly_time_safe_v1',args);
    await rejected('keep_my_exam_prep_timeline_weekly_time_safe_v1',args);
    await rejected('accept_my_exam_prep_timeline_weekly_target_safe_v1',
      params(before.student_budget_profile_revision));
    const after=await timeline();baseline(after);
    assert.equal(after.student_budget_profile_revision,before.student_budget_profile_revision);
  }
  if(phase==='restore'){
    const restored=await timeline();baseline(restored);
    assert.equal(restored.P1.exam_date_status,'valid_exam_date');
    assert.equal(restored.P5.exam_date_status,'valid_exam_date');
    // A separate explicit profile edit remains available; no implicit save
    // is required to "restore" hours after refused heuristic adoption.
  }
  console.log('PASS D10 academic-time refusal, original phase='+phase);
}
main().catch(e=>{
  console.error('FAIL D10 phase='+phase+' '+String(e?.message||e).slice(0,350));
  process.exitCode=1;
});
