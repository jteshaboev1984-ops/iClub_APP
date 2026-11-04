'use strict';

/**
 * P2-08 PRIVATE/OFFLINE academic measurement-quality gate.
 * No networking, no database access, no learner API, no write path.
 * Evaluating observations is NOT approving per-skill workload norms.
 */
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const PACK_FILE = path.join(__dirname,'../docs/math-p1p5-package2-81-skill-review-pack-v1.json');
const VALID_MODES = new Set(['independent_active_work']);
const VALID_PHASES = new Set(['core','revision']);
const VALID_PRIORS = new Set(['novice','previously_exposed']);
const MIN_PILOT_DISTINCT_ACTORS_PER_PHASE = 3; // internal pilot QA floor only; never a normative approval threshold.
const MAX_SEGMENT_SECONDS = 4*60*60; // input sanity check, not student-access limit.

function scalarSafe(x) {
  return typeof x === 'string' && x.length >= 3 && x.length <= 160 &&
    !/[@\s]/.test(x) && !/token|secret|password|key=/i.test(x);
}
function catalogRows(pack) {
  assert.equal(pack.schema_version,'math-p1p5-skill-workload-review-pack-v1');
  assert.equal(pack.skills.length,81);
  const map=new Map();
  for(const skill of pack.skills) {
    assert(!map.has(skill.skill_code),'duplicate canonical skill');
    assert(['P1','P5'].includes(skill.component_code));
    assert.equal(skill.review.approved_for_recommendation,false);
    map.set(skill.skill_code,skill);
  }
  assert.equal([...map.values()].filter(s=>s.component_code==='P1').length,45);
  assert.equal([...map.values()].filter(s=>s.component_code==='P5').length,36);
  return map;
}
function reasonForRejection(o,skills) {
  if (!o || typeof o !== 'object' || Array.isArray(o)) return 'invalid_structure';
  if (o.is_synthetic !== false) return 'synthetic_or_unattested';
  if (o.measurement_basis !== 'direct_observed_active_seconds' || !VALID_MODES.has(o.study_mode)) return 'not_independent_observed_study';
  if (!VALID_PHASES.has(o.phase) || !VALID_PRIORS.has(o.prior_state)) return 'invalid_phase_or_prior';
  if (!scalarSafe(o.observation_ref) || !scalarSafe(o.anonymous_actor_ref) ||
      !scalarSafe(o.consent_receipt_ref) || !scalarSafe(o.source_evidence_ref) ||
      !scalarSafe(o.observer_ref)) return 'missing_provenance_or_privacy_risk';
  if (!Number.isSafeInteger(o.active_seconds) || o.active_seconds <= 0 ||
      o.active_seconds > MAX_SEGMENT_SECONDS || !Number.isSafeInteger(o.paused_seconds) ||
      o.paused_seconds < 0) return 'invalid_elapsed_clock';
  if (o.tutored_seconds !== 0 || o.outside_platform_time_inferred !== false ||
      o.background_time_included !== false || o.session_complete !== true) return 'not_unassisted_completed_evidence';
  const skill=skills.get(o.skill_code);
  if (!skill || skill.component_code !== o.component_code) return 'canonical_component_mismatch';
  return null;
}
function analyze(pack, observations) {
  const skills=catalogRows(pack);
  if (!Array.isArray(observations)) throw new Error('observations must be an array');
  const usedIds=new Set(),usedActorPhase=new Set();
  const grouped=new Map(),rejected={};
  for(const o of observations) {
    let why=reasonForRejection(o,skills);
    if(!why && usedIds.has(o.observation_ref)) why='duplicate_observation';
    const actorKey=!why && [o.skill_code,o.phase,o.anonymous_actor_ref].join(':');
    if(!why && usedActorPhase.has(actorKey)) why='duplicate_actor_for_skill_phase';
    if(why){rejected[why]=(rejected[why]||0)+1;continue;}
    usedIds.add(o.observation_ref);
    usedActorPhase.add(actorKey);
    const groupKey=o.skill_code+'/'+o.phase;
    if(!grouped.has(groupKey))grouped.set(groupKey,[]);
    grouped.get(groupKey).push({seconds:o.active_seconds,prior:o.prior_state,observer:o.observer_ref});
  }
  const report=[];
  for(const skill of skills.values()) {
    const core=grouped.get(skill.skill_code+'/core')||[];
    const revision=grouped.get(skill.skill_code+'/revision')||[];
    const qualified=(records)=>records.length>=MIN_PILOT_DISTINCT_ACTORS_PER_PHASE
      && new Set(records.map(r=>r.observer)).size>=2
      && new Set(records.map(r=>r.prior)).size===2;
    const sufficientPilot=qualified(core)&&qualified(revision);
    // A sample min/max is strictly an unapproved observation envelope, not individual forecast.
    const span=records=>records.length ? {
      low_observed_minutes:Math.floor(Math.min(...records.map(r=>r.seconds))/60),
      high_observed_minutes:Math.ceil(Math.max(...records.map(r=>r.seconds))/60)
    } : null;
    report.push({
      skill_code:skill.skill_code,component_code:skill.component_code,
      core_evidence_count:core.length,revision_evidence_count:revision.length,
      pilot_observation_criteria_met:sufficientPilot,
      academic_review_status:sufficientPilot?'independent_review_still_required':'measurement_evidence_incomplete',
      observed_core_span_for_reviewer_only:sufficientPilot?span(core):null,
      observed_revision_span_for_reviewer_only:sufficientPilot?span(revision):null,
      approved_workload_norms:null,
      recommended_hours_per_week:null
    });
  }
  return {schema_version:'p2-08-measurement-audit-v1',
    direct_student_api_enabled:false,
    academic_approval_issued:false,
    source_rows:report.length,accepted_observations:[...grouped.values()].reduce((a,v)=>a+v.length,0),
    rejected_observations_by_reason:rejected,
    pilot_complete_skills:report.filter(r=>r.pilot_observation_criteria_met).length,
    approved_skill_norms:0,recommendations_enabled:false,
    rows:report};
}
function selfTest() {
  const pack=JSON.parse(fs.readFileSync(PACK_FILE,'utf8'));
  const empty=analyze(pack,[]);
  assert.equal(empty.source_rows,81);
  assert.equal(empty.pilot_complete_skills,0);
  assert.equal(empty.recommendations_enabled,false);
  assert(empty.rows.every(r=>r.approved_workload_norms===null && r.recommended_hours_per_week===null));
  let q=pack.skills[0];
  const sample=(id,phase,prior,observer)=>({
    observation_ref:'OBS_TEST_'+id,anonymous_actor_ref:'ACT_TEST_'+id,
    consent_receipt_ref:'CONSENT_TEST_'+id,source_evidence_ref:'EVID_TEST_'+id,
    observer_ref:'OBSERV_'+observer,skill_code:q.skill_code,component_code:q.component_code,
    phase,prior_state:prior,study_mode:'independent_active_work',
    measurement_basis:'direct_observed_active_seconds',
    active_seconds:180+id*20,paused_seconds:15,tutored_seconds:0,
    outside_platform_time_inferred:false,background_time_included:false,
    session_complete:true,is_synthetic:false
  });
  // Synthetic test objects are in-memory only and never represent genuine measurement records.
  const tested=[];
  for(let i=1;i<=3;i++) {
    tested.push(sample(i,'core',i===1?'novice':'previously_exposed',i===1?'A':'B'));
    tested.push(sample(i+3,'revision',i===1?'novice':'previously_exposed',i===1?'A':'B'));
  }
  let run=analyze(pack,tested);
  assert.equal(run.pilot_complete_skills,1);
  assert.equal(run.approved_skill_norms,0);
  assert.equal(run.recommendations_enabled,false);
  assert.equal(run.rows[0].academic_review_status,'independent_review_still_required');
  assert(run.rows[0].observed_core_span_for_reviewer_only!==null);
  const negative=[
    [Object.assign({},sample(20,'core','novice','A'),{is_synthetic:true}),'synthetic_or_unattested'],
    [Object.assign({},sample(21,'core','novice','A'),{measurement_basis:'question_timer'}),'not_independent_observed_study'],
    [Object.assign({},sample(22,'core','novice','A'),{component_code:q.component_code==='P1'?'P5':'P1'}),'canonical_component_mismatch'],
    [Object.assign({},sample(23,'core','novice','A'),{background_time_included:true}),'not_unassisted_completed_evidence'],
    [Object.assign({},sample(24,'core','novice','A'),{anonymous_actor_ref:'person@example.org'}),'missing_provenance_or_privacy_risk'],
    [Object.assign({},sample(25,'core','novice','A'),{active_seconds:0}),'invalid_elapsed_clock']
  ];
  for(const [bad,expected] of negative) {
    const res=analyze(pack,[bad]);
    assert.equal(res.rejected_observations_by_reason[expected],1);
    assert.equal(res.accepted_observations,0);
  }
  const repeated=sample(31,'core','novice','A');
  const dup=Object.assign({},repeated,{observation_ref:'OBS_TEST_32'});
  const res=analyze(pack,[repeated,dup]);
  assert.equal(res.rejected_observations_by_reason.duplicate_actor_for_skill_phase,1);
  assert.equal(res.approved_skill_norms,0);
  console.log('PASS P2-08: 81-source observation quality guard; empty measurement stays blocked; synthetic cases NEVER approve time norms; 8 negative conditions checked.');
}
if(require.main===module){
  if(process.argv.includes('--self-test'))selfTest();
  else {
    const p=JSON.parse(fs.readFileSync(PACK_FILE,'utf8'));
    // Restricted to an explicitly provided protected data path; do not commit real observations.
    const input=process.argv[2];
    const obs=input?JSON.parse(fs.readFileSync(path.resolve(input),'utf8')):[];
    const summary=analyze(p,obs);
    console.log(JSON.stringify({
      schema_version:summary.schema_version,source_rows:summary.source_rows,
      accepted_observations:summary.accepted_observations,
      rejected_observations_by_reason:summary.rejected_observations_by_reason,
      pilot_complete_skills:summary.pilot_complete_skills,
      approved_skill_norms:0,recommendations_enabled:false
    },null,2));
  }
}
module.exports={analyze,reasonForRejection};
