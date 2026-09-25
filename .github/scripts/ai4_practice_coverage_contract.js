const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };
const migration = fs.readFileSync(
  'supabase/migrations/20260925201500_practice_ai4_coverage_snapshot_v1.sql',
  'utf8'
);

for (const token of [
  'get_practice_ai_coverage_snapshot_service_v1',
  "c.card_type='answer_explanation'",
  "c.approval_status='approved'",
  'c.is_runtime_allowed',
  "c.rights_status in ('original_iclub','official_public_metadata','licensed')",
  "d.quality_status='published'",
  'd.is_correct=false',
  'd.mistake_type is not null',
  "'source_all_locales_questions'",
  "'diagnostic_source_ready_questions'",
]) {
  assert(migration.includes(token), `AI-4 coverage contract token missing: ${token}`);
}

assert(
  migration.includes('revoke all on function public.get_practice_ai_coverage_snapshot_service_v1(text)') &&
  migration.includes('to service_role;'),
  'AI-4 coverage snapshot is not service-role only'
);

for (const forbidden of ["'correct_answer'", "'answer_key'", "'body_text'", "'feedback_en'", "'user_answer'"]) {
  assert(!migration.includes(forbidden), `AI-4 coverage snapshot must be count-only: ${forbidden}`);
}

console.log('AI-4 Practice AI coverage contract: GREEN');
