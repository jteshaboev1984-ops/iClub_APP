const fs = require('fs');

const file = 'supabase/functions/practice-ai/index.ts';
const src = fs.readFileSync(file, 'utf8');
const assert = (condition, message) => { if (!condition) throw new Error(message); };

const guardCall = src.indexOf('get_practice_ai_guard_v1');
const contextCall = src.indexOf('context = await loadContext');
const sourceCall = src.indexOf('get_practice_ai_source_cards_service_v1');
const reserveCall = src.indexOf('await reserveProviderCall');
const providerCall = src.indexOf('await callOpenAIProvider');
assert(guardCall >= 0, 'Practice AI guard missing');
assert(contextCall >= 0, 'Practice AI server context missing');
assert(sourceCall >= 0, 'Practice AI approved source retrieval missing');
assert(reserveCall >= 0, 'Practice AI atomic provider reservation missing');
assert(providerCall >= 0, 'Practice AI provider call missing');
assert(guardCall < contextCall, 'Practice AI context resolved before guard');
assert(contextCall < sourceCall, 'Practice AI source retrieval must follow owned context');
assert(sourceCall < reserveCall, 'Practice AI provider admission must follow approved source retrieval');
assert(reserveCall < providerCall, 'Practice AI provider call appears before atomic reservation');

for (const token of [
  'post_answer_explanation',
  'practice_result_summary',
  'get_practice_ai_answer_context_service_v1',
  'get_practice_ai_result_context_service_v1',
  'record_practice_ai_audit_service_v1',
  'model_not_configured',
  'academic_state_changed: false',
  'generated: false',
  'generated: true',
  'OPENAI_API_KEY',
  'https://api.openai.com/v1/responses',
  'OPENAI_MODEL = "gpt-5.6-luna"',
  'validateGeneratedMessage',
  'reserve_practice_ai_provider_call_service_v1',
  'finalize_practice_ai_provider_call_service_v1',
]) {
  assert(src.includes(token), `missing Practice AI foundation token: ${token}`);
}

for (const forbidden of [
  'correct_answer',
  'answer_key',
  'ANTHROPIC_API_KEY',
  'GEMINI_API_KEY',
  'api.anthropic.com',
  'generativelanguage.googleapis.com',
  'new_mastery_level',
  'change_score',
  'update practice_attempts',
  'update tour_attempts',
]) {
  assert(!src.toLowerCase().includes(forbidden.toLowerCase()), `forbidden Practice AI Edge token present: ${forbidden}`);
}

assert(!src.includes('(payload as any).subject_id'), 'client supplied subject authority must not be trusted');
assert(!src.includes('(payload as any).is_correct'), 'client supplied correctness must not be trusted');

console.log('AI-2 Practice AI Edge contract: GREEN');
