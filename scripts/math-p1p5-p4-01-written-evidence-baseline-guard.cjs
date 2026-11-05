// Issue #450 P4-01: source-only NEGATIVE baseline (NOT a Stage3–6 release pass).
// No network, database credentials, question keys, question text, or user data.
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const read = p => fs.readFileSync(path.join(root,p),'utf8');
const sql = read('supabase/tests/p1p5_p4_01_full_paper_content_inventory_readonly.sql');
const policy = read('docs/math-p1p5-v2-1-stage3-6-written-evidence-recovery-plan-20261105.md');
const migration = read('supabase/migrations/20261104110000_exam_prep_p1p5_disable_written_self_marks_v1.sql');
const stage3 = read('supabase/migrations/20260905152500_exam_prep_p1_03_stage3_exit_evaluator_v1.sql');
const raw5 = read('supabase/migrations/20260906113000_exam_prep_p1_03_stage5_raw_readiness_v1.sql');
const signedHttp = read('scripts/p1p5-isolated-http-positive-mixed-timed.cjs');
function readonlyGuard(input) {
  const stripped = input.replace(/--[^\n]*/g,'').replace(/'(?:''|[^'])*'/g,"''");
  assert(/\bSELECT\b/i.test(stripped),'source audit must SELECT');
  assert(!/\b(?:INSERT|UPDATE|DELETE|TRUNCATE|CREATE|ALTER|DROP|GRANT|REVOKE|EXECUTE|CALL|DO|COPY|VACUUM)\b/i.test(stripped),
    'source audit must not write or alter production');
  assert(!/\b(?:FROM|JOIN)\s+(?:public\.(?:users|questions)|private\.exam_prep_(?:sessions|responses|attempts|session_items|timed_attempt_results))\b/i.test(stripped),
    'source audit must not read learner history or answer content');
  for(const needed of [
    'READ ONLY','private.exam_prep_assessments','private.exam_prep_timed_assessment_contracts',
    'private.exam_prep_timed_assessment_items','private.exam_prep_assessment_items',
    "c.attempt_kind='full_paper'", "a.component_code IN ('P1','P5')",
    'written_task_id','question_id','NO_GO_EXISTING_STATE'
  ]) assert(input.includes(needed),'source inventory missing '+needed);
}
readonlyGuard(sql);
assert.throws(()=>readonlyGuard(sql+'\nDELETE FROM private.exam_prep_sessions;'),/write or alter/);
assert.throws(()=>readonlyGuard(sql+'\nSELECT * FROM private.exam_prep_sessions;'),/learner history/);
assert.throws(()=>readonlyGuard(sql+'\nUPDATE public.questions SET is_active=false;'),/write or alter/);
for(const needed of [
 '2026-11-05','P4-01','P4-02','P4-03','P4-04','P4-05','P4-06',
 'Core','Mentor','16/16','0/0','NO_GO','new-chat'
]) assert(policy.toLowerCase().includes(needed.toLowerCase()),'new roadmap missing '+needed);
assert(migration.includes('exam_prep_written_self_marks_disabled'),
 'D03 learner self-mark RPC denial must stay in draft');
assert(/coalesce\(t\.pending_review_in_time_marks,0\)=0/i.test(migration) &&
       /coalesce\(t\.pending_review_after_time_marks,0\)=0/i.test(migration),
 'P4-01 baseline: old score-comparable requires ungraded pending=0 (must be split in P4-02)');
assert(stage3.includes('private.exam_prep_timed_score_comparable_v1(t.session_id)'),
 'Stage 3 baseline uses scored comparability for full-paper practice');
assert(raw5.includes('private.exam_prep_timed_score_comparable_v1(t.session_id)'),
 'Stage 5 baseline uses scored comparability for full-paper practice');
assert(migration.includes('100.0*v_marks_in_time/v_marks_available'),
 'Baseline still contains the mathematically invalid objective/whole-paper ratio');
assert(signedHttp.includes("assert.equal(beforeResult.score_comparable,false"),
 'Signed integration test must not pretend self-ungraded papers are scored');
function scoreOrUnknown(earned, objectiveAvailable) {
  return objectiveAvailable>0 ? 100*earned/objectiveAvailable : null;
}
assert.equal(scoreOrUnknown(0,0),null,
 'All-written 0/0 MUST remain unknown, not a grade or automatic zero');
assert.equal(scoreOrUnknown(7,10),70,
 'Only observed objective marks may be scored within their own real denominator');
console.log('P4-01 SOURCE BASELINE DETECTED: written-only paper is currently unscored and Stage3/Stage5 depend on scored comparator.');
console.log('P4-01 PASS: safe live-inventory SQL and 3 negative mutation probes, normative 0/0=unknown, current bug explicitly NOT FIXED.');
