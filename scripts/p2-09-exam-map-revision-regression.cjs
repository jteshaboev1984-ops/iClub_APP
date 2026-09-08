const fs = require('fs');

function read(path) { return fs.readFileSync(path, 'utf8'); }
function assert(condition, message) { if (!condition) throw new Error(message); }

const migration = read('supabase/migrations/20260908103000_exam_prep_p2_09_exam_map_revision_v1.sql');

for (const token of [
  'profile_revision integer not null default 1',
  'paper_comparability_epoch integer not null default 1',
  'private.exam_prep_exam_map_revisions',
  'progress_retained boolean not null default true check(progress_retained is true)',
  'prior_papers_remain_history boolean not null default true check(prior_papers_remain_history is true)',
  'save_exam_prep_exam_profile_v2',
  'v_revision:=v_old.profile_revision + case when v_changed then 1 else 0 end',
  'v_epoch:=v_old.paper_comparability_epoch + case when v_series_changed then 1 else 0 end',
  "'prior_papers_count_toward_current_trend',case when v_series_changed then false else true end",
  "'plan_rebuild_required',(v_series_changed or v_target_changed or v_hours_changed)",
  "'timetable_reconfirmation_required',v_series_changed",
  "'exam_profile_revision',v_ep.profile_revision",
  "'paper_comparability_epoch',v_ep.paper_comparability_epoch",
  "'exam_series_snapshot',v_ep.exam_series",
  "'target_grade_snapshot',v_ep.target_grade",
  "coalesce(nullif(s.timing_contract->>'paper_comparability_epoch','')::int,1)=coalesce(p.paper_comparability_epoch,1)",
  'exam_series_snapshot text null',
  'profile_revision_snapshot integer null',
  'get_exam_prep_exam_map_status_safe_v1',
  "'calendar_can_reduce_progress',false",
  "'hours_change_action','rebuild_weekly_plan_preserve_corrections_retests'"
]) assert(migration.includes(token), `P2-09 contract missing: ${token}`);

assert(/v_series_changed\s*:=/i.test(migration), 'series-change detector missing');
assert(/v_hours_changed\s*:=/i.test(migration), 'hours-change detector missing');
assert(/v_target_changed\s*:=/i.test(migration), 'target-change detector missing');
assert(migration.includes("a.exam_series_snapshot is null\n      or lower(trim(a.exam_series_snapshot))=lower(trim(coalesce(v_profile.exam_series,'')))"), 'exam appointment must be scoped to the current series');
assert(migration.includes("s.session_type='paper' and s.status='finalized' and t.attempt_kind='full_paper'"), 'Exam Map status must count only finalized full papers');

for (const forbidden of [
  /delete\s+from\s+private\.exam_prep_evidence_events/i,
  /delete\s+from\s+private\.exam_prep_skill_states/i,
  /delete\s+from\s+private\.exam_prep_stage_states/i,
  /delete\s+from\s+private\.exam_prep_timed_attempt_results/i,
  /update\s+private\.exam_prep_evidence_events/i,
  /update\s+private\.exam_prep_skill_states/i,
  /update\s+private\.exam_prep_stage_states\s+set\s+(?!derived_at)/i,
  /insert\s+into\s+private\.exam_prep_stage5_thresholds/i,
  /update\s+private\.exam_prep_stage5_thresholds/i,
  /set\s+mentor_enabled\s*=\s*true/i,
  /set\s+ai_enabled\s*=\s*true/i,
  /correct_answer/i
]) assert(!forbidden.test(migration), `forbidden P2-09 mutation/surface: ${forbidden}`);

console.log('P2-09 Exam Map revision regression: GREEN');
