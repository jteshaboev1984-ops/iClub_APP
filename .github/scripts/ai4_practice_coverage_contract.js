const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };
const coverageV2 = fs.readFileSync(
  'supabase/migrations/20260925211000_practice_ai4_coverage_precision_v2.sql',
  'utf8'
);
const sourcePack = fs.readFileSync(
  'supabase/migrations/20260925212000_practice_ai4_economics_p1_topic_source_pack_v1.sql',
  'utf8'
);

for (const token of [
  'get_practice_ai_coverage_snapshot_service_v1',
  "'coverage_semantics','v2_any_vs_precise'",
  'source_any_all_locales_questions',
  'source_precise_all_locales_questions',
  'diagnostic_any_source_ready_questions',
  'diagnostic_precise_source_ready_questions',
  "c.card_type='answer_explanation'",
  "c.approval_status='approved'",
  'c.is_runtime_allowed',
  "c.rights_status in ('original_iclub','official_public_metadata','licensed')",
  "d.quality_status='published'",
  'd.is_correct=false',
  'd.mistake_type is not null',
]) {
  assert(coverageV2.includes(token), `AI-4 v2 coverage token missing: ${token}`);
}

assert(
  coverageV2.includes('revoke all on function public.get_practice_ai_coverage_snapshot_service_v1(text)') &&
  coverageV2.includes('to service_role;'),
  'AI-4 coverage snapshot is not service-role only'
);

for (const forbidden of ["'correct_answer'", "'answer_key'", "'body_text'", "'feedback_en'", "'user_answer'"]) {
  assert(!coverageV2.includes(forbidden), `AI-4 coverage snapshot must remain count-only: ${forbidden}`);
}

const keys = [...sourcePack.matchAll(/practice:economics:p1:topic:[a-z]+:(?:ru|uz|en):v1/g)].map(m => m[0]);
assert(keys.length === 33, `Economics P1 topic pack must contain exactly 33 topic-locale cards, got ${keys.length}`);
assert(new Set(keys).size === 33, 'Economics P1 topic pack contains duplicate source_card_key values');

for (const topic of ['intro','basics','systems','ppc','goods','demand','supply','elasticity','equilibrium','market','costs']) {
  for (const locale of ['ru','uz','en']) {
    assert(
      keys.includes(`practice:economics:p1:topic:${topic}:${locale}:v1`),
      `Economics P1 topic source missing: ${topic}/${locale}`
    );
  }
}

assert(
  sourcePack.includes("'approved','original_iclub',true"),
  'Economics P1 topic pack must use approved original_iClub runtime cards'
);
assert(
  sourcePack.includes('Broad fallback only: question_id/subtopic are intentionally NULL.'),
  'Economics P1 topic pack lost its broad-fallback boundary'
);
assert(
  !sourcePack.toLowerCase().includes('correct_answer') &&
  !sourcePack.toLowerCase().includes('answer_key'),
  'Economics P1 topic pack references private answer material'
);

console.log('AI-4 Practice AI coverage + Economics P1 topic pack contract: GREEN');
