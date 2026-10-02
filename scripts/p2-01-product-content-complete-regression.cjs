const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = read('supabase/migrations/20261002030000_exam_prep_p2_01_product_content_complete_gate_v1.sql');

for (const token of [
  'private.exam_prep_product_content_complete_audits',
  "'p2_01_product_content_complete_v1'",
  "milestone_key='product_content_complete'",
  "product_label='Product Content-Complete'",
  "milestone_status='met'",
  "private.exam_prep_skill_content_ready_v1",
  "public.get_exam_prep_content_runway_v1(24::smallint)",
  "P5-GEO-01",
  "P5-GEO-02",
  "P5-GEO-03",
  "m.reserve_role='diagnostic'",
  "m.reserve_role in ('learning','mixed')",
  "m.reserve_role='retest'",
  "resource_kind='official_past_paper_portal'",
  "rights_status='metadata_only_external'",
  "t.attempt_kind='timed_section'",
  "t.attempt_kind='modified_paper'",
  "t.attempt_kind='full_paper'",
  "never_exposed_transfer_retest_pct",
  "annual_holdout_rotation_target_pct",
  "product_content_complete_is_syllabus_closure",
  "product_content_complete_is_learner_exam_ready"
]) {
  assert(migration.includes(token), `P2-01 gate missing contract token: ${token}`);
}

for (const forbidden of [
  /update\s+private\.exam_prep_skill_states/i,
  /insert\s+into\s+private\.exam_prep_skill_states/i,
  /delete\s+from\s+private\.exam_prep_skill_states/i,
  /update\s+private\.exam_prep_stage_states/i,
  /insert\s+into\s+private\.exam_prep_stage_states/i,
  /delete\s+from\s+private\.exam_prep_stage_states/i,
  /update\s+private\.exam_prep_evidence_events/i,
  /insert\s+into\s+private\.exam_prep_evidence_events/i,
  /delete\s+from\s+private\.exam_prep_evidence_events/i,
  /update\s+private\.exam_prep_correction_cases/i,
  /insert\s+into\s+private\.exam_prep_correction_cases/i,
  /delete\s+from\s+private\.exam_prep_correction_cases/i,
  /update\s+private\.exam_prep_responses/i,
  /insert\s+into\s+private\.exam_prep_responses/i,
  /delete\s+from\s+private\.exam_prep_responses/i,
  /update\s+private\.exam_prep_sessions/i,
  /insert\s+into\s+private\.exam_prep_sessions/i,
  /delete\s+from\s+private\.exam_prep_sessions/i,
  /update\s+private\.exam_prep_timed_attempt_results/i,
  /insert\s+into\s+private\.exam_prep_timed_attempt_results/i,
  /delete\s+from\s+private\.exam_prep_timed_attempt_results/i,
  /update\s+public\.practice_attempts/i,
  /insert\s+into\s+public\.practice_attempts/i,
  /delete\s+from\s+public\.practice_attempts/i,
  /update\s+public\.practice_answers/i,
  /insert\s+into\s+public\.practice_answers/i,
  /delete\s+from\s+public\.practice_answers/i,
  /update\s+public\.tour_attempts/i,
  /insert\s+into\s+public\.tour_attempts/i,
  /delete\s+from\s+public\.tour_attempts/i,
  /update\s+public\.tour_answers/i,
  /insert\s+into\s+public\.tour_answers/i,
  /delete\s+from\s+public\.tour_answers/i,
  /update\s+public\.certificates/i,
  /insert\s+into\s+public\.certificates/i,
  /delete\s+from\s+public\.certificates/i,
  /set\s+core_enabled\s*=/i,
  /set\s+ai_enabled\s*=/i,
  /set\s+mentor_enabled\s*=/i,
  /set\s+kill_switch\s*=/i
]) {
  assert(!forbidden.test(migration), `P2-01 forbidden learner/legacy/service mutation: ${forbidden}`);
}

assert(!/product_label\s*=\s*'[^']*(?:AS READY|Exam Ready)[^']*'/i.test(migration),
  'P2-01 must never assign learner-readiness terminology to the product milestone');

const milestoneUpdates = migration.match(/update\s+private\.exam_prep_product_roadmap_milestones/ig) || [];
assert(milestoneUpdates.length === 1, `P2-01 expected exactly one product milestone update, got ${milestoneUpdates.length}`);

console.log('P2-01 Product Content-Complete static regression: GREEN');
