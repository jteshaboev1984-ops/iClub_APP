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

(async()=>{
 const result=await request(USER_A);
 assert(result.ok,'Owner could not see real read-only projection: '+result.status+' '+JSON.stringify(result.data));
 const d=result.data;
 const taskResult=await signedRpc('get_exam_prep_remaining_work_by_skill_safe_v1',USER_A);
 assert(taskResult.ok,'Owner could not obtain live result-led skills: '+taskResult.status+' '+JSON.stringify(taskResult.data));
 const remaining=taskResult.data;
 assert.equal(remaining.contract_version,'exam_prep_result_led_remaining_work_v1');
 assert.equal(remaining.numeric_recommendation_available,false);
 assert.equal(remaining.recommended_weekly_hours,null);
 assert.equal(remaining.recommendation_accept_enabled,false);
 assert.equal(remaining.unknown_is_not_weak,true);
 assert.equal(remaining.repeated_errors_deduplicated_by_component_skill_phase,true);
 assert.equal(remaining.shared_mathematics_budget_double_counted,false);
 const timelineResponse=await signedRpc('get_exam_prep_simple_learning_timeline_safe_v1',USER_A);
 assert(timelineResponse.ok,
   'Owner simple timeline unavailable: '+timelineResponse.status+' '+JSON.stringify(timelineResponse.data));
 const timeline=timelineResponse.data;
 assert.equal(timeline.contract_version,'exam_prep_one_line_progress_timeline_v1');
 assert.equal(timeline.required_personal_hours_total,null);
 assert.equal(timeline.planned_calendar_hours_are_not_proven_required_learning_hours,true);
 assert.equal(timeline.p1_p5_hour_budgets_are_not_additive,true);
 assert.equal(timeline.no_progress_mutation,true);
 assert.equal(timeline.no_automatic_schedule_change,true);
 for(const [paper,n] of [['P1',45],['P5',36]]) {
   const t=timeline[paper];
   const o=remaining[paper];
   assert.equal(t.total_syllabus_skills,n);
   assert.equal(t.objectively_covered_skills,o.skills_objective_coverage_confirmed_not_final_mastery);
   assert.equal(t.already_attempted_not_yet_confirmed_skills,o.skills_observed_not_yet_confirmed);
   assert.equal(t.not_yet_checked_skills,o.skills_unobserved);
   assert.equal(t.skills_not_yet_objectively_covered,n-t.objectively_covered_skills);
   assert.equal(t.objectively_covered_skills+
     t.already_attempted_not_yet_confirmed_skills+t.not_yet_checked_skills,n);
   assert.equal(t.required_hours_for_remaining_skills,null);
   assert.equal(t.confirmed_objective_coverage_is_not_final_written_exam_mastery,true);
   assert(['valid_exam_date','exam_date_not_yet_selected','exam_date_mismatch','exam_already_passed']
     .includes(t.exam_date_status));
   if(t.exam_date_status!=='valid_exam_date')
     assert.equal(t.planned_math_hours_available_to_this_exam,null);
 }
 const anonTimeline=await signedRpc('get_exam_prep_simple_learning_timeline_safe_v1',null);
 assert(!anonTimeline.ok,'Anonymous obtained owner timeline');
 const trajectoryResult=await signedRpc('get_exam_prep_conditional_trajectory_status_safe_v1',USER_A);
 assert(trajectoryResult.ok,'Owner trajectory lookup failed: '+trajectoryResult.status+
   ' '+JSON.stringify(trajectoryResult.data));
 const trajectory=trajectoryResult.data;
 assert.equal(trajectory.contract_version,'exam_prep_conditional_trajectory_status_v1');
 assert.equal(trajectory.possible_future_work_not_assigned,true);
 assert.equal(trajectory.unknown_skill_needs_check_not_whole_tuition,true);
 assert.equal(trajectory.wrong_responses_not_multiplied_into_courses,true);
 assert.equal(trajectory.numerical_weekly_hour_recommendation,null);
 assert.equal(trajectory.recommendation_accept_enabled,false);
 assert.equal(trajectory.student_progress_changed,false);
 assert.equal(trajectory.no_written_self_awarded_grade,true);
 for(const [paper,expected] of [['P1',45],['P5',36]]) {
   assert.equal(trajectory[paper].canonical_skills,expected);
   assert.equal(trajectory[paper].current_unique_action_slots,
     remaining[paper].unique_pending_action_slots,
     'Current P2-12 tasks must exactly equal genuine P2-09 actions '+paper);
   assert(Number.isInteger(trajectory[paper].skills_with_possible_downstream_work));
   assert(trajectory[paper].skills_with_possible_downstream_work>=0);
   assert(trajectory[paper].skills_with_possible_downstream_work<=expected);
   assert.equal(trajectory[paper].total_time_to_demonstrated_mastery_minutes_min,null);
   assert.equal(trajectory[paper].total_time_to_demonstrated_mastery_minutes_max,null);
 }
 const anonymousTrajectory=await signedRpc('get_exam_prep_conditional_trajectory_status_safe_v1',null);
 assert(!anonymousTrajectory.ok,'Anonymous access to P2-12 learner work is forbidden');
 const durationStatus=await signedRpc('get_exam_prep_action_time_calibration_status_safe_v1',USER_A);
 assert(durationStatus.ok,'Owner action time coverage unavailable: '+durationStatus.status+
        ' '+JSON.stringify(durationStatus.data));
 const ds=durationStatus.data;
 assert.equal(ds.contract_version,'exam_prep_action_time_calibration_status_v1');
 assert.equal(ds.numeric_recommendation_available,false);
 assert.equal(ds.recommendation_accept_enabled,false);
 assert.equal(ds.recommended_weekly_hours,null);
 assert.equal(ds.no_learning_time_cap,true);
 assert.equal(ds.no_grade_forecast,true);
 assert.equal(ds.shared_p1_p5_calendar_capacity_nonadditive,true);
 for(const paper of ['P1','P5']) {
   assert.equal(ds[paper].unique_pending_action_count,
                remaining[paper].unique_pending_action_slots,
                'Action time coverage must be derived from actual unique pending tasks '+paper);
   assert.equal(ds[paper].academically_approved_action_count,0,
                'Real skill-time ranges must not be approved by CI '+paper);
   assert.equal(ds[paper].unapproved_action_count,
                remaining[paper].unique_pending_action_slots);
   assert.equal(ds[paper].targeted_minutes_min,null);
   assert.equal(ds[paper].targeted_minutes_max,null);
 }
 const anonymousDuration=await signedRpc('get_exam_prep_action_time_calibration_status_safe_v1',null);
 assert(!anonymousDuration.ok,'Anonymous actor could inspect owner study-state coverage');
 for(const [component,expected] of [['P1',45],['P5',36]]) {
   const itemGroup=remaining[component];
   assert.equal(itemGroup.skills_total,expected);
   assert.equal(itemGroup.items.length,expected);
   const uniqueCodes=new Set();
   let sumSlots=0;
   for(const item of itemGroup.items) {
     assert.equal(item.component_code,component);
     assert(!uniqueCodes.has(item.skill_code),'Duplicate canonical skill action: '+item.skill_code);
     uniqueCodes.add(item.skill_code);
     assert(['unobserved','observed_unconfirmed','objective_coverage_confirmed'].includes(item.evidence_status));
     assert.equal(item.remaining_minutes_min,null);
     assert.equal(item.remaining_minutes_max,null);
     assert.equal(item.academic_hours_approved,false);
     assert.equal(item.wrong_answer_multiplication_allowed,false);
     assert.equal(item.unresolved_corrections_counted_as_separate_full_skill_courses,false);
     assert.equal(item.written_activity_is_verified_method_mark,false);
     assert(Array.isArray(item.pending_actions));
     assert.equal(new Set(item.pending_actions).size,item.pending_actions.length);
     sumSlots+=item.pending_actions.length;
     if(item.evidence_status==='unobserved')
       assert.deepEqual(item.pending_actions,['targeted_check'],'Unknown is never an assumed fail');
     if(item.recorded_unresolved_correction_count>0)
       assert.deepEqual(item.pending_actions,['correction'],'Multiple wrong responses may not duplicate whole skill tuition');
   }
   assert.equal(uniqueCodes.size,expected);
   assert.equal(itemGroup.unique_pending_action_slots,sumSlots);
   assert.equal(itemGroup.skills_unobserved,d[component].skills_unknown_objective_level);
   assert.equal(itemGroup.skills_observed_not_yet_confirmed,
                d[component].skills_with_observed_but_unconfirmed_objective_level);
   assert.equal(itemGroup.skills_objective_coverage_confirmed_not_final_mastery,
                d[component].skills_with_confirmed_objective_coverage);
   assert.equal(itemGroup.remaining_study_minutes_min,null);
   assert.equal(itemGroup.individually_recommended_weekly_hours,null);
 }
 const noAccess=await signedRpc('get_exam_prep_remaining_work_by_skill_safe_v1',null);
 assert(!noAccess.ok,'Anonymous actor read a real learner work inventory');
 const crossUser=await signedRpc('get_exam_prep_remaining_work_by_skill_safe_v1',USER_B);
 assert(!crossUser.ok || (crossUser.data.P1?.items?.every(i=>i.evidence_status==='unobserved') &&
                          crossUser.data.P5?.items?.every(i=>i.evidence_status==='unobserved')),
        'Other-user access exposed finished learner evidence');
 assert.equal(d.contract_version,'exam_prep_workload_review_projection_v1');
 assert.equal(d.recommendation_accept_enabled,false,'Academic minute recommendation was not approved');
 assert.equal(d.recommended_daily_minutes,null,'No guessed study-hour requirement');
 assert.equal(d.learning_time_cap,false,'Study budget must never lock learning');
 assert.equal(d.grade_prediction_available,false,'No Cambridge grade forecast');
 for (const [paper,count,examMinutes] of [['P1',45,110],['P5',36,75]]) {
   const p=d[paper];
   assert(p,'Missing '+paper+' real projection');
   assert.equal(p.curriculum_skills,count,'Wrong canonical syllabus count '+paper);
   assert.equal(p.source_mapped_norms,count,'Missing source-bound norms '+paper);
   assert.equal(p.academically_approved_norms,0,'Faked academic approval '+paper);
   assert.equal(p.cambridge_full_paper_exam_minutes,examMinutes,'Wrong official 2026/27 paper duration');
   assert.equal(p.cambridge_paper_time_is_study_quota,false);
   assert.equal(p.numeric_recommendation_available,false);
   assert.equal(p.recommended_daily_minutes,null);
   assert.equal(p.recommended_weekly_hours_min,null);
   assert.equal(p.recommended_weekly_hours_max,null);
   assert.equal(p.learning_time_cap,false);
   assert.equal(p.diagnostic_complete,true,'Existing genuine E2E had finished Stage0 for '+paper);
   assert(p.diagnostic_completed_at,'No actual diagnostic completion anchor '+paper);
   const states=['skills_unknown_objective_level',
       'skills_with_observed_but_unconfirmed_objective_level',
       'skills_with_confirmed_objective_coverage'];
   let classified=0;
   for(const k of states){assert(Number.isInteger(p[k])&&p[k]>=0,'Bad real evidence counter '+k);classified+=p[k]}
   assert.equal(classified,count,'Objective evidence states must cover exactly '+count+' skills without treating unknown as weak');
   assert(p.skills_unknown_objective_level>=0);
   assert.equal(p.status,'exam_date_not_confirmed','No invented official exam date for '+paper);
 }
 const anonymous=await request(null);
 assert(!anonymous.ok,'Anonymous request exposed private Math skill evidence');
 const other=await request(USER_B);
 assert(!other.ok || (other.data.P1?.diagnostic_completed_at===null &&
                      other.data.P5?.diagnostic_completed_at===null),
    'Different user could read another learner diagnostic evidence');
 // Use existing completed Stage0 learner and the real school-confirmed date RPC.
 // Dates are E2E learner inputs, never asserted to be official Cambridge dates.
 const initial=await signedRpc('get_exam_prep_shared_study_capacity_safe_v1',USER_A);
 assert(initial.ok,'Learner capacity lookup denied');
 assert.equal(initial.data.planned_shared_math_hours_to_earliest_exam,null);
 assert.equal(initial.data.recommendation_accept_enabled,false);
 const p1Date='2027-05-12T04:00:00.000Z';
 const p5Date='2027-06-02T04:00:00.000Z';
 for(const [component,date] of [['P1',p1Date],['P5',p5Date]]){
  const saved=await signedRpc('save_my_exam_prep_exam_appointment_v1',USER_A,{
    p_component_code:component,p_scheduled_start_at:date
  });
  assert(saved.ok,'Authenticated date save failed '+component+' HTTP '+saved.status);
 }
 const verified=await signedRpc('get_exam_prep_shared_study_capacity_safe_v1',USER_A);
 assert(verified.ok,'Learner capacity not available after saved dates');
 const plan=verified.data;
 assert.equal(plan.P1.status,'calendar_capacity_available');
 assert.equal(plan.P5.status,'calendar_capacity_available');
 assert.equal(Date.parse(plan.earliest_ready_paper_start_at),Date.parse(p1Date),
   'Earliest paper date changed during PostgreSQL timestamptz serialization');
 assert.equal(Date.parse(plan.latest_ready_paper_start_at),Date.parse(p5Date),
   'Latest paper date changed during PostgreSQL timestamptz serialization');
 const capacity=date=>Math.round(
    Number(plan.chosen_math_hours_per_week) *
    (Date.parse(date)-Date.parse(plan.as_of))/604800000*100)/100;
 assert(Math.abs(Number(plan.planned_shared_math_hours_to_earliest_exam)-capacity(p1Date))<=0.02,
   'Shared capacity until first paper differs from weekly selected hours multiplied by fractional weeks');
 assert(Math.abs(Number(plan.planned_shared_math_hours_to_latest_exam)-capacity(p5Date))<=0.02,
   'Shared capacity until final paper differs from elected weekly hours');
 assert.equal(plan.shared_across_both_papers,true);
 assert.equal(plan.horizon_hours_additive_across_p1_p5,false);
 assert.equal(plan.capacity_is_recommendation,false);
 assert.equal(plan.capacity_is_access_limit,false);
 assert.equal(plan.may_study_above_plan,true);
 assert.equal(plan.recommended_study_hours_per_week,null);
 assert.equal(plan.recommended_daily_minutes,null);
 assert.equal(plan.recommendation_accept_enabled,false);
 assert.equal(plan.progress_notifications_only,'after_completed_week_or_month');
 const anonymousCapacity=await signedRpc('get_exam_prep_shared_study_capacity_safe_v1',null);
 assert(!anonymousCapacity.ok,'Anonymous capacity read allowed');
 const foreignCapacity=await signedRpc('get_exam_prep_shared_study_capacity_safe_v1',USER_B);
 assert(!foreignCapacity.ok || foreignCapacity.data.earliest_ready_paper_start_at===null,
    'Other user sees saved P1/P5 dates');

 // Existing legacy v1 date-save endpoint accepts arbitrary future timestamps.
 // Even when called directly, private learning projections must NOT treat an
 // out-of-series date as additional verified study capacity.
 const offSeries=await signedRpc('save_my_exam_prep_exam_appointment_v1',USER_A,{
   p_component_code:'P1',p_scheduled_start_at:'2028-02-12T04:00:00.000Z'
 });
 assert(offSeries.ok,'Legacy authenticated exam-date route changed unexpectedly');
 const guardedCapacity=await signedRpc('get_exam_prep_shared_study_capacity_safe_v1',USER_A);
 assert(guardedCapacity.ok);
 assert.equal(guardedCapacity.data.P1.status,'exam_date_series_mismatch');
 assert.equal(guardedCapacity.data.P5.status,'calendar_capacity_available');
 assert.equal(Date.parse(guardedCapacity.data.earliest_ready_paper_start_at),Date.parse(p5Date),
   'Off-series date must not inflate available study horizon');
 const guardedProjection=await request(USER_A);
 assert(guardedProjection.ok);
 assert.equal(guardedProjection.data.P1.status,'exam_date_series_mismatch');
 assert.equal(guardedProjection.data.P1.days_to_exam,null,
   'Off-series direct RPC must not give an authoritative exam deadline');
 const repairedDate=await signedRpc('save_my_exam_prep_exam_appointment_v1',USER_A,{
   p_component_code:'P1',p_scheduled_start_at:p1Date
 });
 assert(repairedDate.ok);
 const restored=await signedRpc('get_exam_prep_shared_study_capacity_safe_v1',USER_A);
 assert(restored.ok);
 assert.equal(restored.data.P1.status,'calendar_capacity_available');
 assert.equal(Date.parse(restored.data.earliest_ready_paper_start_at),Date.parse(p1Date));

 console.log('PASS P2 real learner objective/unknown evidence (45+36), official 110/75min papers, zero invented hours or grade forecasts, no study quota, owner-only JWT');
})().catch(err=>{console.error(err);process.exitCode=1});
