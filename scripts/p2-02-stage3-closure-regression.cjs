const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = read('supabase/migrations/20261002040000_exam_prep_p2_02_stage3_closure_tooling_v1.sql');
const api = read('exam-prep/exam-prep-api.js');
const views = read('exam-prep/exam-prep-learner-views.js');

for (const token of [
  'private.exam_prep_stage3_closure_payload_v1',
  'public.get_exam_prep_stage3_closure_safe_v1',
  'private.exam_prep_stage3_exit_status_v1',
  'private.exam_prep_syllabus_tracker_payload_v1',
  "'coverage_required_pct',100",
  "'all_skills_min_level',2",
  "'key_skills_min_level',3",
  "'component_separate',true",
  "'calendar_can_close',false",
  "'product_content_complete_can_close',false",
  "'cross_component_compensation',false",
  "'modified_paper_available_count'",
  "'full_paper_available_count'",
  "'comparable_full_baseline_count'",
  "key_registry_status<>'approved'",
  "P5-GEO-01"
]) {
  assert(migration.includes(token), `P2-02 closure tooling missing contract token: ${token}`);
}

for (const forbidden of [
  /insert\s+into\s+private\.exam_prep_skill_states/i,
  /update\s+private\.exam_prep_skill_states/i,
  /delete\s+from\s+private\.exam_prep_skill_states/i,
  /insert\s+into\s+private\.exam_prep_stage_states/i,
  /update\s+private\.exam_prep_stage_states/i,
  /delete\s+from\s+private\.exam_prep_stage_states/i,
  /insert\s+into\s+private\.exam_prep_evidence_events/i,
  /update\s+private\.exam_prep_evidence_events/i,
  /delete\s+from\s+private\.exam_prep_evidence_events/i,
  /insert\s+into\s+private\.exam_prep_sessions/i,
  /update\s+private\.exam_prep_sessions/i,
  /delete\s+from\s+private\.exam_prep_sessions/i,
  /insert\s+into\s+private\.exam_prep_timed_attempt_results/i,
  /update\s+private\.exam_prep_timed_attempt_results/i,
  /delete\s+from\s+private\.exam_prep_timed_attempt_results/i,
  /insert\s+into\s+public\.practice_answers/i,
  /update\s+public\.practice_answers/i,
  /delete\s+from\s+public\.practice_answers/i,
  /insert\s+into\s+public\.tour_answers/i,
  /update\s+public\.tour_answers/i,
  /delete\s+from\s+public\.tour_answers/i,
  /insert\s+into\s+public\.certificates/i,
  /update\s+public\.certificates/i,
  /delete\s+from\s+public\.certificates/i,
  /milestone_status\s*=\s*'met'/i,
  /set\s+core_enabled\s*=/i,
  /set\s+ai_enabled\s*=/i,
  /set\s+mentor_enabled\s*=/i,
  /set\s+kill_switch\s*=/i
]) {
  assert(!forbidden.test(migration), `P2-02 forbidden learner/history/service/product mutation: ${forbidden}`);
}

assert(/revoke all on function public\.get_exam_prep_stage3_closure_safe_v1\(text\)[\s\S]*from public,anon;/i.test(migration),
  'P2-02 public closure API must revoke public/anon execution');
assert(/grant execute on function public\.get_exam_prep_stage3_closure_safe_v1\(text\)[\s\S]*to authenticated,service_role;/i.test(migration),
  'P2-02 public closure API must be authenticated/service only');


for (const token of [
  'async function stage3Closure(componentCode)',
  'get_exam_prep_stage3_closure_safe_v1',
  'syllabusTracker, stage3Closure, skillDetail',
  'exam-prep-learner-views.js?v=p302aivalue1'
]) {
  assert(api.includes(token), `P2-02 learner API integration missing token: ${token}`);
}

for (const token of [
  'const VERSION = "p302aivalue1"',
  'function closureReason(copyRow, reason, ready)',
  'function renderClosureCard(data)',
  'internal.api.stage3Closure(component)',
  'closureReasonCoverage',
  'closureReasonLevel',
  'closureReasonPriority',
  'closureReasonBaseline',
  'closureReasonSections',
  'closurePracticeOptions',
  'closureBaselineNeeded',
  'closureBaselineDone'
]) {
  assert(views.includes(token), `P2-02 learner closure surface missing token: ${token}`);
}

for (const copyToken of [
  'Завершение программы',
  'Все темы подтверждены',
  'Первый полный вариант',
  'Complete syllabus coverage',
  'All topics confirmed',
  'First full-paper baseline',
  'Dastur qamrovini yakunlash',
  'Barcha mavzular tasdiqlangan',
  'Birinchi to‘liq variant'
]) {
  assert(views.includes(copyToken), `P2-02 trilingual learner copy missing: ${copyToken}`);
}

assert(!views.includes('closureTitle: "Stage 3 Syllabus Closure"'),
  'P2-02 learner surface must not expose the internal Stage 3 label as its title');
assert(!views.includes('closurePriority: "Key skills'),
  'P2-02 learner surface must not expose internal key-skill terminology');
assert(!views.includes('closureAllSkills: "L2') && !views.includes('closurePriority: "L3'),
  'P2-02 learner surface must not expose internal L2/L3 labels');
assert(views.includes('typeof internal.api?.stage3Closure === "function"'),
  'P2-02 tracker must degrade safely if the new closure API is not present during rollback');
assert(views.includes('closureResult?.ok ? closureResult.data : null'),
  'P2-02 closure read must remain optional and must not break the existing tracker');

console.log('P2-02 Stage 3 closure static regression: GREEN');
