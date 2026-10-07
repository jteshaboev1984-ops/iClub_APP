#!/usr/bin/env node
'use strict';

const fs=require('fs');
const path=require('path');
const ROOT=path.resolve(__dirname,'..');

const files={
  audit:path.join(ROOT,'supabase','migrations','20261007007000_math_practice_v2_tour_invariant_audit_v1.sql'),
  release:path.join(ROOT,'supabase','migrations','20261007007500_math_practice_v2_atomic_release_switch_v1.sql'),
  preflight:path.join(ROOT,'supabase','preflight','math_practice_v2_release_preflight.sql'),
  postPublish:path.join(ROOT,'supabase','preflight','math_practice_v2_post_publish_audit.sql'),
  postCleanup:path.join(ROOT,'supabase','preflight','math_practice_v2_post_cleanup_audit.sql'),
  postRollback:path.join(ROOT,'supabase','preflight','math_practice_v2_post_rollback_audit.sql'),
  schemaCompat:path.join(ROOT,'supabase','preflight','math_practice_v2_schema_compatibility.sql'),
  feedback:path.join(ROOT,'supabase','migrations','20261007006700_math_practice_v2_deterministic_feedback_v5.sql'),
  app:path.join(ROOT,'app.js'),
};

const errors=[];
const fail=m=>errors.push(m);
for(const [name,p] of Object.entries(files)){
  if(!fs.existsSync(p)) fail(`missing ${name}: ${p}`);
}
if(errors.length){for(const e of errors)console.error('ERROR:',e);process.exit(1);}

const audit=fs.readFileSync(files.audit,'utf8');
const release=fs.readFileSync(files.release,'utf8');
const preflight=fs.readFileSync(files.preflight,'utf8');
const postPublish=fs.readFileSync(files.postPublish,'utf8');
const postCleanup=fs.readFileSync(files.postCleanup,'utf8');
const postRollback=fs.readFileSync(files.postRollback,'utf8');
const schemaCompat=fs.readFileSync(files.schemaCompat,'utf8');
const feedback=fs.readFileSync(files.feedback,'utf8');
const app=fs.readFileSync(files.app,'utf8');

for(const table of ['tours','tour_questions','tour_attempts','tour_answers','tour_session_answers_v4']){
  const patterns=[
    new RegExp(`\\binsert\\s+into\\s+(?:public\\.)?${table}\\b`,'i'),
    new RegExp(`\\bupdate\\s+(?:public\\.)?${table}\\b`,'i'),
    new RegExp(`\\bdelete\\s+from\\s+(?:public\\.)?${table}\\b`,'i'),
    new RegExp(`\\btruncate\\s+(?:table\\s+)?(?:public\\.)?${table}\\b`,'i'),
  ];
  for(const re of patterns) if(re.test(release)) fail(`release contains forbidden Tour DML: ${re}`);
}

for(const token of [
  'practice_v2_tour_invariant_snapshot_v1',
  'old_active_membership_ids',
  'old_question_ids',
  'new_membership_ids',
  'practice_reset_then_v2_publish',
  'delete from public.practice_sessions_v4',
  'delete from public.practice_drill_sessions_v4',
  'delete from public.user_answer_diagnosis',
  'delete from public.recommendations',
  "source_type='practice'",
  'delete from public.practice_attempts',
  "legacy_source='practice_answers'",
  'practice_progress_reset',
  'update public.practice_pool_questions ppq\n  set is_active=false',
  'update public.practice_pool_questions ppq\n  set is_active=true',
  "lifecycle_state='published'",
  'is_runtime_allowed=true',
  "quality_status='published'",
  'protected_tour_invariant_changed_during_release',
  'protected_tour_invariant_changed_during_rollback',
  'cleanup_math_practice_v1_questions_v1',
  'protected_tour_invariant_changed_during_legacy_cleanup',
  'rollback_not_available_after_legacy_question_cleanup',
  'release_expected_exactly_one_active_pool_per_practice',
  'release_expected_201_staged_diagnostics',
  'release_expected_868_staged_diagnostic_mappings',
  'release_staged_practice_',
  'order_not_contiguous',
]){
  if(!release.includes(token)) fail(`release/reset migration missing required invariant: ${token}`);
}

for(const protectedPredicate of [
  'not exists(select 1 from public.tour_questions',
  'not exists(select 1 from public.tour_answers',
  'not exists(select 1 from public.tour_session_answers_v4',
]){
  if(!release.includes(protectedPredicate)) fail(`legacy cleanup missing protected reference guard: ${protectedPredicate}`);
}

for(const token of [
  'old_question_ids',
  'rollback_tour_snapshot_before',
  'rollback_tour_snapshot_after',
  'practice_v2_release_switch_audit',
  'tour_answers_md5',
  'tour_recommendations_md5',
  'tour_attempts_md5',
  'tour_questions_md5',
]){
  if(!audit.includes(token)) fail(`Tour audit foundation missing ${token}`);
}

function checkReadOnly(name,sql,tokens=[]){
  if(!/begin;\s*set transaction read only;/i.test(sql)) fail(`${name} is not explicitly read-only`);
  if(!/rollback;\s*$/i.test(sql.trim())) fail(`${name} does not end with rollback`);
  for(const bad of [/\binsert\s+into\b/i,/\bupdate\s+public\./i,/\bdelete\s+from\b/i,/\btruncate\b/i]){
    if(bad.test(sql)) fail(`${name} contains DML-like token: ${bad}`);
  }
  for(const token of tokens) if(!sql.includes(token)) fail(`${name} missing ${token}`);
}

checkReadOnly('preflight',preflight,[
  'preflight_expected_exactly_one_active_math_pool_per_practice',
  'preflight_active_legacy_membership_drift_expected_490',
  'preflight_staged_meta_expected_495',
  'preflight_staged_practice_questions_linked_to_tours',
  'preflight_question_qa_not_passed_count_',
  'preflight_diagnostic_catalog_expected_201',
  'preflight_diagnostic_mappings_expected_868',
  'preflight_diagnostic_mappings_not_safely_staged',
  'membership_order_not_contiguous',
  'practice_v2_tour_invariant_snapshot_v1',
]);

checkReadOnly('post-publish audit',postPublish,[
  'post_publish_active_bank_expected_495',
  'post_publish_release_tour_invariant_not_proven',
  'post_publish_old_memberships_still_active_',
  'post_publish_new_memberships_expected_495',
  'post_publish_practice_v2_tour_overlap_',
  'post_publish_practice_attempts_not_reset_',
  'post_publish_practice_sessions_not_reset_',
  'post_publish_practice_drills_not_reset_',
  'post_publish_practice_diagnoses_not_reset_',
  'post_publish_practice_recommendations_not_reset_',
  'post_publish_legacy_practice_evidence_not_reset_',
  'post_publish_superseded_oracle_or_selector_rpc_still_exposed',
]);

checkReadOnly('post-cleanup audit',postCleanup,[
  'post_cleanup_marker_missing',
  'post_cleanup_tour_invariant_not_proven',
  'post_cleanup_legacy_memberships_still_present_',
  'post_cleanup_active_v2_bank_expected_495',
  'post_cleanup_unprotected_legacy_questions_remain_',
  'post_cleanup_tour_linked_question_missing_',
]);

checkReadOnly('post-rollback audit',postRollback,[
  'rollback_audit_release_not_rolled_back',
  'rollback_audit_tour_invariant_not_proven',
  'rollback_audit_practice_progress_should_remain_reset_',
  'rollback_audit_practice_recommendations_should_remain_reset_',
  'rollback_audit_old_memberships_expected_',
  'rollback_audit_new_memberships_still_active_',
  'rollback_audit_v2_history_rows_expected_495',
]);

checkReadOnly('schema compatibility preflight',schemaCompat,[
  'practice_v2_questions_column_contract_drift_',
  'practice_v2_pool_question_uniqueness_missing',
  'practice_v2_required_v4_compatibility_function_missing',
  'practice_v2_expected_seven_active_math_pools_found_',
]);

for(const token of [
  'submit_practice_session_answer_safe_v5',
  'submit_practice_drill_answer_safe_v5',
  'finalize_practice_session_safe_v5',
  'get_practice_review_full_safe_v5',
  'practice_match_answer_diagnostic_v5',
  'diagnostic_status',
]){
  if(!feedback.includes(token)) fail(`feedback migration missing ${token}`);
}
if(/submit_practice_attempt\s*\(/i.test(
  feedback.slice(feedback.indexOf('create or replace function public.finalize_practice_session_safe_v5'))
)) {
  fail('v5 finalizer must not call legacy submit_practice_attempt');
}

if(!app.includes('key === "mathematics" ? "practice_history_v3" : "practice_history_v2"')){
  fail('Mathematics Practice local history namespace is not reset for the new bank');
}
if(!app.includes('String(subjectKey).trim().toLowerCase() !== "mathematics"')){
  fail('Mathematics Practice recommendations may still fall back to stale local v1 recommendations');
}
if(!app.includes('const tourStore = loadMyTourRecs()')){
  fail('Tour recommendation fallback must remain separate from Practice reset');
}

console.log(JSON.stringify({
  ok:errors.length===0,
  protectedTourDml:'none',
  practiceReset:'intentional',
  legacyQuestionCleanup:'protected-reference-gated',
  practiceRecommendationsReset:'server-only-mathematics',
  tourRecommendationsPreserved:true,
  mathematicsLocalHistoryNamespace:'practice_history_v3',
  preflightReadOnly:true,
  postPublishAuditReadOnly:true,
  postCleanupAuditReadOnly:true,
  postRollbackAuditReadOnly:true,
  releaseHasRollbackBeforeCleanup:true,
  v5FinalizerReevaluation:'none',
  errors
},null,2));

for(const e of errors)console.error('ERROR:',e);
if(errors.length)process.exit(1);
