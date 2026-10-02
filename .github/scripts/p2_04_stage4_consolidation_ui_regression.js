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
  'exam-prep-live.js?v=p204stage4'
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
  'percentShare(data?.latest_after_time_share)',
  'function consolidationReferenceMarkup(data, c)',
  'official_reference_series',
  'official_reference_scope',
  'official_reference_used_for_direct_score_calibration',
  'official_reference_question_content_copied',
  'https://www.cambridgeinternational.org/',
  'target="_blank" rel="noopener noreferrer"'
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
  'Bajarilmay qolgan ballar',
  'Ориентир по формату: официальный Cambridge 9709, June 2026.',
  'Format reference: official Cambridge 9709, June 2026.',
  'Format bo‘yicha yo‘nalish: rasmiy Cambridge 9709, June 2026.'
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
  "'official_reference_series','Cambridge International AS & A Level Mathematics 9709 · June 2026'",
  "'official_reference_scope','format_and_timing_context_only'",
  "'official_reference_used_for_direct_score_calibration',false",
  "'official_reference_question_content_copied',false",
  "'cambridge_9709_june_2026_p1_reference'",
  "'cambridge_9709_june_2026_p5_reference'",
  "revoke all on function public.get_exam_prep_stage4_consolidation_safe_v1(text) from public,anon",
  "grant execute on function public.get_exam_prep_stage4_consolidation_safe_v1(text) to authenticated,service_role"
]) must(migration.toLowerCase().includes(token.toLowerCase()), `safe RPC migration contract missing: ${token}`);

must(!migration.includes("'selected_family_key',"), 'safe learner RPC must not expose internal comparison-family key');
must(!migration.includes("'rule_version',v_result"), 'safe learner RPC must not expose internal Stage-4 rule version');

must(migration.includes('rights_status,official_url,status,checked_at'),
  'Cambridge June 2026 source references must remain metadata-only external records');
must(migration.includes('can_support_assessment_evidence=false') || migration.includes('false,false,false,false'),
  'Cambridge June 2026 affected papers must not be promoted to direct assessment-evidence authority');

new Function(api);
new Function(live);
console.log('P2-04 Stage 4 consolidation learner UI regression: GREEN');
