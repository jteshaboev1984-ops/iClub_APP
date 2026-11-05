#!/usr/bin/env node
'use strict';
// Stage A: deterministic SOURCE trace contract. Does not connect to production,
// simulate a human sign-off, or claim to exercise HTTP/Auth/PostgREST.
// To change an audited RPC or runtime route, update the trace report and manifest.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const ROOT=path.resolve(__dirname,'..');
const read=(p)=>fs.readFileSync(path.join(ROOT,p),'utf8');
const PATHS=[
  "exam-prep/exam-prep-api.js",
  "exam-prep/exam-prep-weekly-flow-adapter.js",
  "exam-prep/exam-prep-progress-ux-api.js"
];
const EXPECTED=[
  "advance_exam_prep_written_step_safe_v1",
  "authorize_exam_prep_goal_once_safe_v1",
  "authorize_exam_prep_plan_item_safe_v1",
  "authorize_exam_prep_revalidation_item_safe_v1",
  "authorize_exam_prep_timed_safe_v1",
  "claim_exam_prep_periodic_study_report_safe_v1",
  "ensure_exam_prep_balanced_weekly_plan_safe_v1",
  "ensure_my_exam_prep_weekly_budget_safe_v1",
  "finalize_exam_prep_session_safe_v1",
  "finalize_exam_prep_session_written_v1",
  "finalize_exam_prep_timed_safe_v1",
  "generate_exam_prep_weekly_plan_safe_v3",
  "get_exam_prep_active_plan_session_safe_v1",
  "get_exam_prep_capabilities_v1",
  "get_exam_prep_correction_queue_safe_v1",
  "get_exam_prep_diagnostic_progress_safe_v1",
  "get_exam_prep_exam_map_status_safe_v1",
  "get_exam_prep_exam_ops_safe_v1",
  "get_exam_prep_exam_profile_v1",
  "get_exam_prep_final_calibration_safe_v1",
  "get_exam_prep_goal_action_state_safe_v1",
  "get_exam_prep_integrity_status_safe_v1",
  "get_exam_prep_legacy_reference_summary_safe_v1",
  "get_exam_prep_materials_library_safe_v1",
  "get_exam_prep_overview_safe_v1",
  "get_exam_prep_past_paper_companion_safe_v1",
  "get_exam_prep_personal_horizon_safe_v1",
  "get_exam_prep_placement_result_safe_v1",
  "get_exam_prep_placement_safe_v1",
  "get_exam_prep_previous_week_adherence_safe_v1",
  "get_exam_prep_readiness_safe_v1",
  "get_exam_prep_readiness_summary_safe_v1",
  "get_exam_prep_recent_results_safe_v1",
  "get_exam_prep_recent_results_written_v1",
  "get_exam_prep_recovery_safe_v2",
  "get_exam_prep_session_review_safe_v1",
  "get_exam_prep_session_review_written_v1",
  "get_exam_prep_session_safe_v1",
  "get_exam_prep_session_written_v1",
  "get_exam_prep_skill_detail_safe_v1",
  "get_exam_prep_stage0_workflow_safe_v1",
  "get_exam_prep_stage3_closure_safe_v1",
  "get_exam_prep_stage4_consolidation_safe_v1",
  "get_exam_prep_state_safe_v1",
  "get_exam_prep_study_schedule_safe_v1",
  "get_exam_prep_syllabus_tracker_safe_v1",
  "get_exam_prep_timed_catalog_safe_v1",
  "get_exam_prep_timed_result_safe_v1",
  "get_exam_prep_timed_review_pack_safe_v1",
  "get_exam_prep_weekly_plan_safe_v2",
  "get_exam_prep_weekly_progress_safe_v1",
  "get_exam_prep_written_criteria_safe_v1",
  "get_exam_prep_written_step_status_safe_v1",
  "get_my_exam_prep_extra_hard_attempt_safe_v1",
  "get_my_exam_prep_extra_hard_catalog_safe_v1",
  "get_my_exam_prep_weekly_flow_status_v1",
  "start_my_exam_prep_extra_hard_safe_v1",
  "submit_my_exam_prep_extra_hard_safe_v1",
  "record_exam_prep_integrity_event_safe_v1",
  "record_my_exam_prep_interruption_v2",
  "save_exam_prep_exam_profile_v2",
  "save_exam_prep_study_schedule_safe_v1",
  "save_my_exam_prep_exam_appointment_v1",
  "save_my_exam_prep_exam_appointment_v2",
  "set_my_exam_prep_exam_ops_confirmation_v1",
  "start_exam_prep_learning_review_safe_v1",
  "start_exam_prep_next_diagnostic_safe_v1",
  "start_exam_prep_plan_session_once_safe_v1",
  "start_exam_prep_session_safe_v1",
  "submit_exam_prep_response_safe_v1"
];
const LIVE='exam-prep/exam-prep-live.js';
const HOST='exam-prep/exam-prep-host.js';
const HTML='index.html';
function namesFromSource(src,extra=false){
 const names=new Set([...src.matchAll(/\brpc\s*\(\s*(?:component\s*,\s*)?['"]([a-z_0-9]+)['"]/g)].map(m=>m[1]));
 if(extra) for(const m of src.matchAll(/['"](get_exam_prep_[a-z_0-9]+)['"]/g))names.add(m[1]);
 return names;
}
const found=new Set();
for(const [i,p] of PATHS.entries()){
 const code=read(p);
 assert.match(code,/window\.sb/,'supabase client not bound in '+p);
 assert.match(code,/client\.rpc\(/,'server RPC transport missing in '+p);
 assert.doesNotMatch(code,/\.from\s*\(/,'new direct table access in '+p+'; review RLS/data boundary first');
 for(const n of namesFromSource(code,i===2))found.add(n);
}
// All five Package 1 routes must have a reviewed scope, caller, and negative gate.
const package1Review=read('docs/math-p1p5-package1-five-rpc-source-trace-and-receipt-epoch-20261104.md');
for(const n of [
 'claim_exam_prep_periodic_study_report_safe_v1',
 'get_exam_prep_personal_horizon_safe_v1',
 'get_exam_prep_study_schedule_safe_v1',
 'save_exam_prep_study_schedule_safe_v1',
 'save_my_exam_prep_exam_appointment_v2'
]){
 assert(package1Review.includes('`'+n+'`'),'Package 1 new RPC has no reviewed contract: '+n);
}
const missing=EXPECTED.filter(n=>!found.has(n));
const added=[...found].filter(n=>!EXPECTED.includes(n)).sort();
assert.deepEqual(missing,[],'historical RPC removed/renamed; first reconcile actual backend signature');
assert.deepEqual(added,[],'new untraced RPC; first document path, permissions and invariant');
assert.equal(EXPECTED.length,70,'P1/P5 time-budget snapshot adds one reviewed optional RPC');
const api=read(PATHS[0]),weekly=read(PATHS[1]),progress=read(PATHS[2]);
const live=read(LIVE),host=read(HOST),html=read(HTML);
for(const n of [
 'startNextDiagnostic','getSession','startSession','submitResponse','finalizeSession',
 'weeklyPlan','generateWeeklyPlan','authorizePlanItem','timedCatalog','authorizeTimed',
 'finalizeTimed','writtenCriteria','advanceWrittenStep','getSessionWritten',
 'sessionReview','timedResult','readinessSummary',
 'extraHardCatalog','extraHardStart','extraHardSubmit','extraHardAttempt'
]){
 assert(api.includes(n),'public client method missing: '+n);
}
for(const n of [
 'startNextDiagnostic','getSession','startSession','submitResponse','finalizeSession',
 'weeklyPlan','generateWeeklyPlan','authorizePlanItem','timedCatalog','authorizeTimed',
 'finalizeTimed','writtenCriteria','advanceWrittenStep'
]){
 assert(live.includes('internal.api.'+n),'Math live view no longer connects to '+n);
}
for(const n of ['get_exam_prep_active_plan_session_safe_v1',
 'ensure_exam_prep_balanced_weekly_plan_safe_v1','authorize_exam_prep_goal_once_safe_v1',
 'start_exam_prep_plan_session_once_safe_v1','start_exam_prep_learning_review_safe_v1']){
 assert(weekly.includes(n),'weekly flow endpoint untraced: '+n);
}
for(const n of ['get_exam_prep_weekly_progress_safe_v1','get_exam_prep_weekly_goal_snapshot_safe_v1']){
 // Snapshot method is bound through explicit METHODS config (its current name can vary).
 if(n==='get_exam_prep_weekly_progress_safe_v1')assert(progress.includes(n),'progress RPC missing');
}
assert.match(weekly,/window\.iClubExamPrepWeeklyFlowEnabled\s*!==\s*true/,'weekly fail-closed cutover missing');
assert.match(host,/state\.subjectKey\s*!==\s*MATHEMATICS_KEY/,'subject isolation missing');
assert.match(live,/writtenNotAuto/,'non-grading policy label missing');
const timeAllocation=read('supabase/migrations/20261104122000_exam_prep_p1p5_shared_weekly_time_snapshot_v1.sql');
const flowAdapter=read('exam-prep/exam-prep-weekly-flow-adapter.js');
assert(timeAllocation.includes('CREATE TABLE IF NOT EXISTS private.exam_prep_weekly_budget_snapshots_v1'),
 'Shared P1/P5 weekly capacity table missing');
assert(timeAllocation.includes('p1_available_minutes+p5_available_minutes=available_math_minutes'),
 'Double-counting Math hours is forbidden');
assert(timeAllocation.includes('current_week_snapshot_not_rewritten'),
 'Current-week time must not silently change');
assert(!/UPDATE private\.exam_prep_weekly_plans|DELETE FROM private\.exam_prep_weekly_plan_items/i.test(timeAllocation),
 'Weekly-budget overlay must not change stable plan priorities');
assert(flowAdapter.includes('ensure_my_exam_prep_weekly_budget_safe_v1'),
 'Shared budget RPC not wired after normal weekly plan');
const secureMigration=read('supabase/migrations/20261104120000_exam_prep_p1p5_extra_hard_optional_noncredit_v1.sql');
const extraView=read('exam-prep/exam-prep-extra-hard-ui.js');
assert(secureMigration.includes('enabled boolean NOT NULL DEFAULT false'),
 'Extra Hard public release must default OFF');
assert(!/INSERT INTO private\.exam_prep_extra_hard_tasks_v1\s*\(/i.test(secureMigration),
 'Protected tasks or solutions must NEVER be seeded from PUBLIC repository');
assert(!extraView.includes('localStorage.setItem') && !extraView.includes('marks_awarded'),
 'Extra Hard route must not alter legacy progress or award scores');
assert(html.includes('exam-prep/exam-prep-extra-hard-ui.js'),
 'Extra Hard view not loaded by optional learner shell');
assert(live.includes('data-ep-component-link="extra-hard"'),
 'P1/P5 voluntary challenge link missing');
for(const [label,src] of [['API',api],['learner UI',live]]) {
 assert(!src.includes('submitTimedSelfMark') && !src.includes('submit_exam_prep_timed_written_self_mark_safe_v1'),
   'D03 forbids callable self-mark endpoint: '+label);
}
assert(live.includes('writtenNotGraded') && live.includes('data-ep-live-next-written'),
  'D03 rubric-only review missing');
assert.match(live,/pendingSubmission/,'answer ACK preservation missing');
for(const s of ['exam-prep/exam-prep-api.js','exam-prep/exam-prep-host.js',
 'exam-prep/runtime/written-core-controller-v1.js']){
 assert(html.includes(s),'production index is not loading '+s);
}
assert(html.includes('id="exam-prep-host-root"'),'learner host root missing');
console.log('Stage A source RPC trace GREEN: '+EXPECTED.length+'/'+EXPECTED.length+' named RPCs; 3 transports; Math live API wiring, access, non-grading, retry and host bootstrapping present.');
console.log('NOTE: source-only regression; real authenticated HTTP→PostgREST→DB and actual device journeys are Stage B/C, NOT implied by GREEN.');
