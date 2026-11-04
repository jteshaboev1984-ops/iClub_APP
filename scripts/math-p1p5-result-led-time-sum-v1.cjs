'use strict';
// P2-09: OFFLINE math-only candidate calculation.
// Real results decide which UNIQUE actions remain. Only independently
// approved durations can be added. Nothing changes learner data/grades.
const PHASES = new Set([
  'targeted_check','correction','targeted_practice','delayed_retest',
  'mixed_transfer','written_work_unscored'
]);
function verifiedInterval(row,item,action) {
  if (!row || row.component_code!==item.component_code ||
      row.skill_code!==item.skill_code || row.action_code!==action ||
      row.estimate_status!=='approved' ||
      !Number.isFinite(row.min_minutes) || !Number.isFinite(row.max_minutes) ||
      row.min_minutes<=0 || row.max_minutes<row.min_minutes ||
      !row.method_version || !row.source_evidence_refs?.length ||
      !row.primary_reviewer_ref || !row.independent_approver_ref ||
      row.primary_reviewer_ref===row.independent_approver_ref)
    return null;
  return {min:row.min_minutes,max:row.max_minutes};
}
function calculate(remaining, approvedRows) {
  if (remaining?.contract_version!=='exam_prep_result_led_remaining_work_v1')
    throw Error('Only server-authoritative result-led inventory accepted');
  if (!Array.isArray(approvedRows)) throw Error('Approved timing input required');
  const normMap=new Map();
  for(const row of approvedRows) {
    const k=[row.component_code,row.skill_code,row.action_code].join('/');
    if(normMap.has(k)) throw Error('Duplicate timing norm '+k);
    normMap.set(k,row);
  }
  const seen=new Set();
  let allLow=0,allHigh=0,allCovered=true,allActionCount=0;
  const result={};
  for(const [paper,expected] of [['P1',45],['P5',36]]) {
    const group=remaining[paper];
    if(group?.skills_total!==expected || !Array.isArray(group.items) ||
       group.items.length!==expected)throw Error('Incomplete canonical '+paper+' coverage');
    let low=0,high=0,covered=true,slots=0,missing=0;
    const workKeys=[];
    for(const item of group.items) {
      if(item.component_code!==paper || !item.skill_code ||
         !Array.isArray(item.pending_actions) ||
         !['unobserved','observed_unconfirmed','objective_coverage_confirmed'].includes(item.evidence_status))
        throw Error('Untrusted remaining skill state');
      const skillKey=paper+'/'+item.skill_code;
      if(seen.has(skillKey))throw Error('Duplicate skill '+skillKey);
      seen.add(skillKey);
      if(item.evidence_status==='unobserved' &&
         (item.pending_actions.length!==1 || item.pending_actions[0]!=='targeted_check'))
        throw Error('Untested skill cannot become failed tuition');
      if(item.recorded_unresolved_correction_count>0 &&
         (item.pending_actions.length!==1 || item.pending_actions[0]!=='correction'))
        throw Error('Repeated errors must be one skill correction phase');
      const actionSet=new Set();
      for(const action of item.pending_actions) {
        if(!PHASES.has(action)) {covered=false;missing++;continue;}
        if(actionSet.has(action))throw Error('Duplicate learning phase');
        actionSet.add(action);
        const key=skillKey+'/'+action;
        workKeys.push(key);slots++;allActionCount++;
        const interval=verifiedInterval(normMap.get(key),item,action);
        if(!interval) {missing++;covered=false;continue;}
        low+=interval.min;high+=interval.max;
      }
    }
    result[paper]={
      curriculum_skills:expected,
      distinct_remaining_action_slots:slots,
      missing_approved_action_intervals:missing,
      targeted_work_minutes_min:covered?low:null,
      targeted_work_minutes_max:covered?high:null,
      verified_duration_coverage:covered,
      excludes_full_paper_and_shared_revision_minutes:true,
      automatic_hour_recommendation_available:false,
      action_keys_for_private_audit_only:workKeys
    };
    if(!covered)allCovered=false;
    allLow+=low;allHigh+=high;
  }
  return {
    contract_version:'result_led_remaining_action_intervals_internal_v1',
    skill_rows:seen.size,remaining_action_slots:allActionCount,
    all_targeted_actions_duration_approved:allCovered,
    targeted_action_minutes_min:allCovered?allLow:null,
    targeted_action_minutes_max:allCovered?allHigh:null,
    complete_exam_preparation_hours:null,
    recommended_weekly_hours:null,
    student_consent_button_enabled:false,
    unknown_skill_assigned_full_learning_course:false,
    each_wrong_response_counted_as_new_course:false,
    p1_p5_calendar_capacity_additive:false,
    paper_rehearsal_and_periodic_review_still_required:true,
    P1:result.P1,P5:result.P5
  };
}
module.exports={calculate};
if(require.main===module){
  const assert=require('node:assert/strict');
  const catalog=require('../docs/math-p1p5-package2-81-skill-review-pack-v1.json');
  function mock() {
    const rows={};
    for(const paper of ['P1','P5'])
      rows[paper]={skills_total:paper==='P1'?45:36,
        items:catalog.skills.filter(s=>s.component_code===paper).map(s=>({
          component_code:paper,skill_code:s.skill_code,
          evidence_status:'objective_coverage_confirmed',
          pending_actions:[],recorded_unresolved_correction_count:0
        }))};
    rows.P1.items[0].evidence_status='unobserved';
    rows.P1.items[0].pending_actions=['targeted_check'];
    rows.P1.items[1].evidence_status='observed_unconfirmed';
    rows.P1.items[1].pending_actions=['correction'];
    rows.P1.items[1].recorded_unresolved_correction_count=10;
    rows.P5.items[0].pending_actions=['mixed_transfer'];
    return {contract_version:'exam_prep_result_led_remaining_work_v1',...rows};
  }
  const fixture=mock();
  const norm=(item,action,a,b)=>({
    component_code:item.component_code,skill_code:item.skill_code,action_code:action,
    estimate_status:'approved',min_minutes:a,max_minutes:b,
    method_version:'ci_fake_v1',source_evidence_refs:['only_synthetic_ci'],
    primary_reviewer_ref:'CI_SIM_A',independent_approver_ref:'CI_SIM_B'
  });
  const fake=[
    norm(fixture.P1.items[0],'targeted_check',5,12),
    norm(fixture.P1.items[1],'correction',20,30),
    norm(fixture.P5.items[0],'mixed_transfer',12,18)
  ];
  const incomplete=calculate(fixture,[]);
  assert.equal(incomplete.targeted_action_minutes_min,null);
  assert.equal(incomplete.remaining_action_slots,3);
  assert.equal(incomplete.complete_exam_preparation_hours,null);
  const example=calculate(fixture,fake);
  assert.equal(example.targeted_action_minutes_min,37);
  assert.equal(example.targeted_action_minutes_max,60);
  assert.equal(example.recommended_weekly_hours,null);
  assert.equal(example.P1.distinct_remaining_action_slots,2);
  fixture.P1.items[1].recorded_unresolved_correction_count=3;
  assert.equal(calculate(fixture,fake).targeted_action_minutes_min,37,
    'Ten wrong versus three wrong in the same unresolved skill must never multiply the study duration');
  fixture.P1.items[1].pending_actions=[];
  fixture.P1.items[1].recorded_unresolved_correction_count=0;
  fixture.P1.items[1].evidence_status='objective_coverage_confirmed';
  assert.equal(calculate(fixture,fake).targeted_action_minutes_min,17,
    'Corrections successfully resolved must not remain in future workload');
  assert.equal(calculate(fixture,fake.slice(0,2)).targeted_action_minutes_min,null);
  assert.throws(()=>calculate(fixture,[...fake,fake[0]]),/Duplicate timing norm/);
  const unsafe={...fake[0],primary_reviewer_ref:'CI_SIM_B'};
  assert.equal(calculate(fixture,[unsafe,fake[1],fake[2]]).targeted_action_minutes_min,null);
  fixture.P1.items[0].pending_actions=['targeted_practice'];
  assert.throws(()=>calculate(fixture,fake),/Untested skill/);
  console.log('PASS P2-09: 81 canonical skills; unknown check, duplicate-error dedupe, correction closure, independent approval, safe NULL, P1/P5 separation. Fake minutes ONLY in source-code test; no user recommendation.');
}
