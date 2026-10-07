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
  postRollback:path.join(ROOT,'supabase','preflight','math_practice_v2_post_rollback_audit.sql'),
  feedback:path.join(ROOT,'supabase','migrations','20261007006700_math_practice_v2_deterministic_feedback_v5.sql'),
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
const postRollback=fs.readFileSync(files.postRollback,'utf8');
const feedback=fs.readFileSync(files.feedback,'utf8');

const lower=s=>s.toLowerCase();

for(const table of ['tours','tour_questions','tour_attempts','tour_answers','tour_session_answers_v4']){
  const patterns=[
    new RegExp(`\\binsert\\s+into\\s+(?:public\\.)?${table}\\b`,'i'),
    new RegExp(`\\bupdate\\s+(?:public\\.)?${table}\\b`,'i'),
    new RegExp(`\\bdelete\\s+from\\s+(?:public\\.)?${table}\\b`,'i'),
    new RegExp(`\\btruncate\\s+(?:table\\s+)?(?:public\\.)?${table}\\b`,'i'),
  ];
  for(const re of patterns) if(re.test(release)) fail(`release switch contains forbidden Tour DML: ${re}`);
}

for(const table of ['practice_attempts','practice_answers','practice_sessions_v4','practice_session_answers_v4','practice_drill_sessions_v4','practice_drill_answers_v4','user_answer_diagnosis']){
  const reDelete=new RegExp(`\\bdelete\\s+from\\s+(?:public\\.)?${table}\\b`,'i');
  const reTruncate=new RegExp(`\\btruncate\\s+(?:table\\s+)?(?:public\\.)?${table}\\b`,'i');
  if(reDelete.test(release)||reTruncate.test(release)) fail(`release switch may not delete/truncate Practice history: ${table}`);
}

const requiredRelease=[
  'practice_v2_tour_invariant_snapshot_v1',
  'old_active_membership_ids',
  'new_membership_ids',
  'update public.practice_pool_questions ppq\n  set is_active=false',
  'update public.practice_pool_questions ppq\n  set is_active=true',
  "lifecycle_state='published'",
  'is_runtime_allowed=true',
  "quality_status='published'",
  'protected_tour_invariant_changed_during_release',
  'protected_tour_invariant_changed_during_rollback',
  'membership_switch_no_history_delete',
];
for(const token of requiredRelease) if(!release.includes(token)) fail(`release switch missing required invariant: ${token}`);

for(const token of [
  'rollback_tour_snapshot_before',
  'rollback_tour_snapshot_after',
  'practice_v2_release_switch_audit',
  'tour_answers_md5',
  'tour_attempts_md5',
  'tour_questions_md5',
]){
  if(!audit.includes(token)) fail(`Tour audit foundation missing ${token}`);
}

if(!/begin;\s*set transaction read only;/i.test(preflight)) fail('preflight is not explicitly read-only');
if(!/rollback;\s*$/i.test(preflight.trim())) fail('preflight does not end with rollback');
for(const bad of [/\binsert\s+into\b/i,/\bupdate\s+public\./i,/\bdelete\s+from\b/i,/\btruncate\b/i]){
  if(bad.test(preflight)) fail(`read-only preflight contains DML-like token: ${bad}`);
}
for(const token of [
  'preflight_active_legacy_membership_drift_expected_490',
  'preflight_staged_meta_expected_495',
  'preflight_staged_practice_questions_linked_to_tours',
  'preflight_question_qa_not_passed_count_',
  'membership_order_not_contiguous',
  'practice_v2_tour_invariant_snapshot_v1',
]){
  if(!preflight.includes(token)) fail(`preflight missing ${token}`);
}


if(!/begin;\s*set transaction read only;/i.test(postPublish)) fail('post-publish audit is not explicitly read-only');
if(!/rollback;\s*$/i.test(postPublish.trim())) fail('post-publish audit does not end with rollback');
for(const bad of [/\binsert\s+into\b/i,/\bupdate\s+public\./i,/\bdelete\s+from\b/i,/\btruncate\b/i]){
  if(bad.test(postPublish)) fail(`post-publish audit contains DML-like token: ${bad}`);
}
for(const token of [
  'post_publish_active_bank_expected_495',
  'post_publish_release_tour_invariant_not_proven',
  'post_publish_old_memberships_still_active_',
  'post_publish_new_memberships_expected_495',
  'post_publish_practice_v2_tour_overlap_',
  'post_publish_superseded_oracle_or_selector_rpc_still_exposed',
]){
  if(!postPublish.includes(token)) fail(`post-publish audit missing ${token}`);
}


if(!/begin;\s*set transaction read only;/i.test(postRollback)) fail('post-rollback audit is not explicitly read-only');
if(!/rollback;\s*$/i.test(postRollback.trim())) fail('post-rollback audit does not end with rollback');
for(const bad of [/\binsert\s+into\b/i,/\bupdate\s+public\./i,/\bdelete\s+from\b/i,/\btruncate\b/i]){
  if(bad.test(postRollback)) fail(`post-rollback audit contains DML-like token: ${bad}`);
}
for(const token of [
  'rollback_audit_release_not_rolled_back',
  'rollback_audit_tour_invariant_not_proven',
  'rollback_audit_old_memberships_expected_',
  'rollback_audit_new_memberships_still_active_',
  'rollback_audit_v2_history_rows_expected_495',
]){
  if(!postRollback.includes(token)) fail(`post-rollback audit missing ${token}`);
}

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

console.log(JSON.stringify({
  ok:errors.length===0,
  protectedTourDml:'none',
  practiceHistoryDelete:'none',
  preflightReadOnly:true,
  postPublishAuditReadOnly:true,
  postRollbackAuditReadOnly:true,
  releaseHasRollback:true,
  v5FinalizerReevaluation:'none',
  errors
},null,2));

for(const e of errors)console.error('ERROR:',e);
if(errors.length)process.exit(1);
