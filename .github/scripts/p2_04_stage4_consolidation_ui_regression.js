const fs = require('fs');

const api = fs.readFileSync('exam-prep/exam-prep-api.js', 'utf8');
const live = fs.readFileSync('exam-prep/exam-prep-live.js', 'utf8');
const migration = fs.readFileSync('supabase/migrations/20261002050000_exam_prep_p2_04_stage4_consolidation_safe_v1.sql', 'utf8');

function must(condition, message) {
  if (!condition) throw new Error(`P2-04 UI regression: ${message}`);
}

for (const token of [
  'async function stage4Consolidation(componentCode)',
  'get_exam_prep_stage4_consolidation_safe_v1',
  'timedCatalog, stage4Consolidation, authorizeTimed',
  'exam-prep-live.js?v=p205readiness1'
]) must(api.includes(token), `API integration missing: ${token}`);

for (const token of [
  'const VERSION = "p204stage4"',
  'function renderConsolidationCard(data)',
  'data-ep-live-stage4-consolidation',
  'typeof internal.api?.stage4Consolidation === "function"',
  'internal.api.stage4Consolidation(component)',
  'modified_or_topic_results_count_as_comparable_full',
  'consolidationReasonPaper',
  'consolidationReasonTiming',
  'consolidationReasonTimed',
  'consolidationReasonCorrections',
  'percentShare(data?.previous_unattempted_share)',
  'percentShare(data?.latest_after_time_share)'
]) must(live.includes(token), `learner Stage-4 surface missing: ${token}`);

for (const copy of [
  'Закрепление на время',
  'Полные варианты в сопоставимых условиях',
  'Невыполненные баллы',
  'Timed consolidation',
  'Full papers under comparable conditions',
  'Unattempted marks',
  'Vaqt ostida mustahkamlash',
  'Bir xil sharoitdagi to‘liq variantlar',
  'Bajarilmay qolgan ballar'
]) must(live.includes(copy), `trilingual learner copy missing: ${copy}`);

must(!live.includes('consolidationTitle: "Stage 4'), 'internal Stage-4 label exposed as learner title');
must(!live.includes('consolidationSkills: "L3'), 'internal L3 label exposed in learner copy');
must(live.includes('stage < 4 && data?.stage3_complete !== true'),
  'Stage-4 card must not appear before closure evidence is relevant');
must(live.includes('.catch(() => null)'),
  'Stage-4 learner read must degrade safely during rollback');
must(!live.includes('internal.api.stage4Consolidation(component).then'),
  'Stage-4 learner read must remain part of the guarded Promise flow');

for (const token of [
  'create or replace function public.get_exam_prep_stage4_consolidation_safe_v1',
  'private.exam_prep_require_core_access_v1()',
  'private.exam_prep_stage4_exit_status_v1',
  "'modified_or_topic_results_count_as_comparable_full',false",
  "revoke all on function public.get_exam_prep_stage4_consolidation_safe_v1(text) from public,anon",
  "grant execute on function public.get_exam_prep_stage4_consolidation_safe_v1(text) to authenticated,service_role"
]) must(migration.toLowerCase().includes(token.toLowerCase()), `safe RPC migration contract missing: ${token}`);

must(!migration.includes("'selected_family_key',"), 'safe learner RPC must not expose internal comparison-family key');
must(!migration.includes("'rule_version',v_result"), 'safe learner RPC must not expose internal Stage-4 rule version');

new Function(api);
new Function(live);
console.log('P2-04 Stage 4 consolidation learner UI regression: GREEN');
