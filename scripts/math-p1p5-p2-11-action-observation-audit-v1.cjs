'use strict';

/**
 * P2-11 OFFLINE independent-action measurement QUALITY auditor.
 * A valid shape or pilot is never proof of independently observed learning.
 * It reads only a separately approved local evidence pack, if supplied.
 * No network, student API, DB mutation, question texts or real learner logs.
 */
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const catalog=require('../docs/math-p1p5-package2-81-skill-review-pack-v1.json');
const ACTION_TASK_KIND=Object.freeze({
  targeted_check:'objective_check',
  correction:'independent_correction',
  targeted_practice:'objective_practice',
  delayed_retest:'delayed_check',
  mixed_transfer:'mixed_objective_transfer',
  written_work_unscored:'unmarked_written_method'
});
const EXPECTED_PRIOR=Object.freeze({
  targeted_check:new Set(['unknown']),
  correction:new Set(['observed_gap']),
  targeted_practice:new Set(['observed_gap']),
  delayed_retest:new Set(['previously_confirmed']),
  mixed_transfer:new Set(['previously_confirmed']),
  written_work_unscored:new Set(['observed_gap','previously_confirmed'])
});
const OBSERVED_OUTCOMES=new Set(['completed_correct','completed_incorrect','completed_unmarked']);
const MAX_SEGMENT_SECONDS=4*60*60; // observation sanity, NOT an access/study limit
const SAFE_REF=/^[A-Za-z0-9][A-Za-z0-9_:.~-]{2,127}$/;
function validRef(x){
  return typeof x==='string' && SAFE_REF.test(x) &&
    !/token|password|secret|session_jwt|@|https?:/i.test(x);
}
function buildCatalog(){
  assert.equal(catalog.schema_version,'math-p1p5-skill-workload-review-pack-v1');
  assert.equal(catalog.skills.length,81);
  const map=new Map();
  for(const s of catalog.skills){
    assert(!map.has(s.skill_code),'duplicated canonical source skill');
    assert(['P1','P5'].includes(s.component_code));
    map.set(s.skill_code,s.component_code);
  }
  assert.equal([...map.values()].filter(x=>x==='P1').length,45);
  assert.equal([...map.values()].filter(x=>x==='P5').length,36);
  return map;
}
function validateObservation(o,skills){
  if(!o || typeof o!=='object' || Array.isArray(o)) return 'invalid_record';
  if(o.synthetic!==false || o.provenance_claim!=='direct_independent_observation')
    return 'synthetic_or_unattested_input';
  if(!skills.has(o.skill_code) || skills.get(o.skill_code)!==o.component_code)
    return 'unknown_or_cross_paper_skill';
  if(!Object.hasOwn(ACTION_TASK_KIND,o.action_code))return 'unknown_action';
  if(!EXPECTED_PRIOR[o.action_code].has(o.prior_state))
    return 'incompatible_prior_skill_evidence';
  const refs=['observation_ref','anonymous_actor_ref','observer_ref','consent_receipt_ref',
     'source_evidence_ref','baseline_evidence_ref','method_version'];
  if(!refs.every(k=>validRef(o[k])) || o.anonymous_actor_ref===o.observer_ref)
    return 'missing_consent_provenance_or_privacy';
  if(o.time_source!=='direct_active_work_observation' ||
     o.reconstructed_from_question_timer!==false ||
     o.reconstructed_from_response_elapsed!==false ||
     o.inferred_outside_platform_seconds!==false ||
     o.background_seconds!==0 || o.assisted_seconds!==0 ||
     o.core_student_progress_automatically_changed!==false)
    return 'ineligible_time_measurement';
  if(!Array.isArray(o.segments) || o.segments.length<1 || o.segments.length>24)
    return 'invalid_segments';
  let total=0, matches=0;
  for(const s of o.segments){
    if(!s || typeof s!=='object' ||
       !Number.isSafeInteger(s.active_seconds) ||
       s.active_seconds<1 || s.active_seconds>MAX_SEGMENT_SECONDS ||
       !Number.isSafeInteger(s.paused_seconds) || s.paused_seconds<0)
      return 'invalid_segment_duration';
    if(s.task_kind!==ACTION_TASK_KIND[o.action_code])
      return 'mismatched_action_segment';
    if(!OBSERVED_OUTCOMES.has(s.outcome)) return 'unrecognized_observation_outcome';
    if(o.action_code==='written_work_unscored' && s.outcome!=='completed_unmarked')
      return 'unauthorized_written_method_scoring';
    if(o.action_code!=='written_work_unscored' && s.outcome==='completed_unmarked')
      return 'objective_outcome_not_recorded';
    if(s.work_cycle_complete!==true)return 'incomplete_observation_cycle';
    total+=s.active_seconds;
    matches++;
  }
  if(!matches || total>24*MAX_SEGMENT_SECONDS)
    return 'observation_outside_bounded_scope';
  return null;
}
function audit(pack){
  const skills=buildCatalog();
  if(!pack || pack.schema_version!=='p2-11-independent-action-observations-v1'
     || !Array.isArray(pack.observations))throw Error('invalid academic observation pack schema');
  const keyMap=new Map(),seenIds=new Set(),seenActorActions=new Set(),rejected={};
  for(const o of pack.observations){
    let rejection=validateObservation(o,skills);
    const id=!rejection&&o.observation_ref;
    const actorKey=!rejection&&[o.component_code,o.skill_code,o.action_code,o.anonymous_actor_ref].join('/');
    if(!rejection&&seenIds.has(id)) rejection='duplicate_observation_id';
    if(!rejection&&seenActorActions.has(actorKey))
      rejection='pseudo_replication_same_actor_action';
    if(rejection){rejected[rejection]=(rejected[rejection]||0)+1;continue;}
    seenIds.add(id);
    seenActorActions.add(actorKey);
    const key=[o.component_code,o.skill_code,o.action_code].join('/');
    if(!keyMap.has(key))keyMap.set(key,[]);
    const seconds=o.segments.reduce((a,s)=>a+s.active_seconds,0);
    keyMap.get(key).push({seconds,observer:o.observer_ref,prior:o.prior_state,
      outcome:o.segments[o.segments.length-1].outcome});
  }
  const rows=[];
  for(const s of catalog.skills)for(const a of Object.keys(ACTION_TASK_KIND)){
    const key=[s.component_code,s.skill_code,a].join('/');
    const data=keyMap.get(key)||[];
    const nObservers=new Set(data.map(x=>x.observer)).size;
    const pilot=data.length>=3&&nObservers>=2;
    // A pilot requires further independent academic review. No automatic
    // quantile, time norm, approval, student schedule or grade is ever issued.
    rows.push({component_code:s.component_code,skill_code:s.skill_code,
      action_code:a,observation_records:data.length,
      distinct_observers:nObservers,pilot_minimal_technical_coverage:pilot,
      observed_complete_correct:data.filter(x=>x.outcome==='completed_correct').length,
      observed_complete_incorrect:data.filter(x=>x.outcome==='completed_incorrect').length,
      observed_complete_unmarked:data.filter(x=>x.outcome==='completed_unmarked').length,
      academic_status:pilot?'requires_independent_method_and_sample_review':'awaiting_observations',
      proposed_min_active_minutes:null,proposed_max_active_minutes:null,
      approved_min_active_minutes:null,approved_max_active_minutes:null});
  }
  assert.equal(rows.length,486);
  assert.equal(rows.filter(r=>r.component_code==='P1').length,270);
  assert.equal(rows.filter(r=>r.component_code==='P5').length,216);
  return {schema_version:'p2-11-action-observation-review-v1',source_skills:81,
    possible_calibration_action_rows:486, accepted_observation_records:[...keyMap.values()].reduce((a,v)=>a+v.length,0),
    rejected_records_by_reason:rejected,
    pilot_candidate_actions:rows.filter(r=>r.pilot_minimal_technical_coverage).length,
    source_certified_independent_time_norms:0,
    academic_approvals_issued:0,
    student_recommendations_enabled:false,
    no_student_timing_or_program_write:true,
    rows};
}
function selfTest(){
  const empty=audit({schema_version:'p2-11-independent-action-observations-v1',observations:[]});
  assert.equal(empty.source_skills,81);
  assert.equal(empty.possible_calibration_action_rows,486);
  assert.equal(empty.accepted_observation_records,0);
  assert.equal(empty.pilot_candidate_actions,0);
  assert(empty.rows.every(r=>r.approved_min_active_minutes===null));
  let q=catalog.skills[0],k=0;
  const one=(over={})=>{
    const i=++k;
    return {synthetic:false,provenance_claim:'direct_independent_observation',
      observation_ref:'TEST_OBSERVATION_'+i,anonymous_actor_ref:'TEST_ACTOR_'+i,
      observer_ref:'TEST_OBSERVER_'+(i%2?'A':'B'),
      consent_receipt_ref:'TEST_CONSENT_'+i,
      source_evidence_ref:'TEST_EVIDENCE_'+i,
      baseline_evidence_ref:'TEST_BASELINE_'+i,
      method_version:'TEST_METHOD_v1',
      component_code:q.component_code,skill_code:q.skill_code,
      action_code:'targeted_check',prior_state:'unknown',
      time_source:'direct_active_work_observation',
      reconstructed_from_question_timer:false,
      reconstructed_from_response_elapsed:false,
      inferred_outside_platform_seconds:false,
      background_seconds:0,assisted_seconds:0,
      core_student_progress_automatically_changed:false,
      segments:[{task_kind:'objective_check',active_seconds:180,paused_seconds:12,
        outcome:'completed_incorrect',work_cycle_complete:true}],
      ...over
    };
  };
  // These are SYNTHETIC IN-MEMORY fixtures. The false field above tests only
  // input shape; it NEVER establishes that any real pupil was observed.
  const valid=[one(),one(),one()];
  const pilot=audit({schema_version:'p2-11-independent-action-observations-v1',observations:valid});
  assert.equal(pilot.pilot_candidate_actions,1);
  assert.equal(pilot.academic_approvals_issued,0);
  assert.equal(pilot.student_recommendations_enabled,false);
  assert.equal(pilot.rows[0].observed_complete_incorrect,3);
  const rejectedCases=[
    [one({synthetic:true}),'synthetic_or_unattested_input'],
    [one({component_code:q.component_code==='P1'?'P5':'P1'}),'unknown_or_cross_paper_skill'],
    [one({action_code:'whole_subject_tuition'}),'unknown_action'],
    [one({prior_state:'previously_confirmed'}),'incompatible_prior_skill_evidence'],
    [one({anonymous_actor_ref:'alice@example.com'}),'missing_consent_provenance_or_privacy'],
    [one({reconstructed_from_response_elapsed:true}),'ineligible_time_measurement'],
    [one({segments:[{task_kind:'objective_check',active_seconds:0,paused_seconds:0,
      outcome:'completed_incorrect',work_cycle_complete:true}]}),'invalid_segment_duration'],
    [one({segments:[{task_kind:'unmarked_written_method',active_seconds:80,paused_seconds:0,
      outcome:'completed_unmarked',work_cycle_complete:true}]}),'mismatched_action_segment'],
    [one({segments:[{task_kind:'objective_check',active_seconds:80,paused_seconds:0,
      outcome:'completed_unmarked',work_cycle_complete:true}]}),'objective_outcome_not_recorded'],
    [one({segments:[{task_kind:'objective_check',active_seconds:80,paused_seconds:0,
      outcome:'completed_incorrect',work_cycle_complete:false}]}),'incomplete_observation_cycle']
  ];
  for(const [bad,reason] of rejectedCases){
    let out=audit({schema_version:'p2-11-independent-action-observations-v1',observations:[bad]});
    assert.equal(out.rejected_records_by_reason[reason],1,reason);
  }
  const dupeId=Object.assign({},valid[0],{anonymous_actor_ref:'ANOTHER_ACTOR'});
  assert.equal(audit({schema_version:'p2-11-independent-action-observations-v1',
    observations:[valid[0],dupeId]}).rejected_records_by_reason.duplicate_observation_id,1);
  const dupeActor=Object.assign({},valid[0],{observation_ref:'DIFFERENT_OBSERVATION'});
  assert.equal(audit({schema_version:'p2-11-independent-action-observations-v1',
    observations:[valid[0],dupeActor]}).rejected_records_by_reason.pseudo_replication_same_actor_action,1);
  const written=one({action_code:'written_work_unscored',prior_state:'observed_gap',
    segments:[{task_kind:'unmarked_written_method',active_seconds:110,paused_seconds:0,
      outcome:'completed_correct',work_cycle_complete:true}]});
  assert.equal(audit({schema_version:'p2-11-independent-action-observations-v1',
    observations:[written]}).rejected_records_by_reason.unauthorized_written_method_scoring,1);
  console.log('PASS P2-11: 81x6 calibration inventory; outcome-inclusive observations; anti-PII/dedup/consent; no timer inference, no written self-scoring, no numeric norms or learner advice.');
}
if(require.main===module){
  if(process.argv.includes('--self-test'))selfTest();
  else {
    const input=process.argv[2];
    const pack=input?JSON.parse(fs.readFileSync(path.resolve(input),'utf8')):
      {schema_version:'p2-11-independent-action-observations-v1',observations:[]};
    const out=audit(pack);
    // Never print actor identifiers, private evidence refs or observed timings.
    console.log(JSON.stringify({schema_version:out.schema_version,
      source_skills:out.source_skills,
      possible_calibration_action_rows:out.possible_calibration_action_rows,
      accepted_observation_records:out.accepted_observation_records,
      rejected_records_by_reason:out.rejected_records_by_reason,
      pilot_candidate_actions:out.pilot_candidate_actions,
      academic_approvals_issued:0,student_recommendations_enabled:false},null,2));
  }
}
module.exports={audit,validateObservation};
