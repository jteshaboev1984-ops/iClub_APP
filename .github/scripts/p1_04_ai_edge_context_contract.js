const fs = require('fs');

const file = 'supabase/functions/exam-prep-ai/index.ts';
const src = fs.readFileSync(file, 'utf8');
const assert = (condition, message) => { if (!condition) throw new Error(message); };

const guardCall = src.indexOf('get_exam_prep_ai_guard_v1');
const contextCall = src.indexOf('deterministicContext = await learnerContext');
const sourceCall = src.indexOf('get_exam_prep_ai_source_cards_service_v1');
const providerCall = src.indexOf('await callOpenAIProvider');
assert(guardCall >= 0, 'AI guard call missing');
assert(contextCall >= 0, 'deterministic learner context call missing');
assert(sourceCall >= 0, 'approved source-card retrieval missing');
assert(providerCall >= 0, 'AI-1 provider call missing');
assert(guardCall < contextCall, 'deterministic learner context must be resolved only after the AI guard');
assert(contextCall < sourceCall, 'approved source cards must be resolved only after deterministic context');
assert(sourceCall < providerCall, 'provider must be called only after guard, deterministic context and approved source retrieval');

for (const rpc of [
  'get_exam_prep_overview_safe_v1',
  'get_exam_prep_weekly_plan_safe_v1',
  'get_exam_prep_correction_queue_safe_v1',
  'get_exam_prep_skill_detail_safe_v1'
]) {
  assert(src.includes(rpc), `safe deterministic context RPC missing: ${rpc}`);
}

for (const forbidden of [
  'correct_answer',
  'submit_exam_prep_response_safe_v1',
  'finalize_exam_prep_session_safe_v1',
  'save_exam_prep_exam_profile_v1',
  'generate_exam_prep_weekly_plan_safe_v1',
  'new_mastery_level',
  'payload.context',
  'payload.deterministic_context',
  '(payload as any).context',
  '(payload as any).deterministic_context'
]) {
  assert(!src.includes(forbidden), `forbidden AI authority/client-context token present: ${forbidden}`);
}

assert(src.includes('p_deterministic_snapshot_hash'), 'deterministic context hash is not audited');
assert(src.includes('context_bound: Boolean(deterministicContext)'), 'client transparency flag for bound context missing');
assert(!/deterministicContext\s*[,}]/.test(src.split('return response(200').slice(-1)[0] || ''), 'raw deterministic context appears to be returned to the client');
assert(src.includes('generated: false'), 'safe fallback must remain explicit that no generation occurred');
assert(src.includes('generated: true'), 'AI-1 generated response contract missing');
assert(src.includes('model_not_configured'), 'safe model-not-configured fallback missing');
assert(src.includes('OPENAI_API_KEY'), 'server-only provider credential hook missing');
assert(src.includes('OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses"'), 'pinned OpenAI Responses endpoint missing');
assert(src.includes('OPENAI_MODEL = "gpt-5.6-luna"'), 'AI-1 cost-pinned model missing');
assert(src.includes('PROVIDER_ENABLED_INTERACTIONS'), 'AI-1 provider scope allowlist missing');
assert(src.includes('"progress_summary"') && src.includes('"weekly_plan_narration"'), 'AI-1 provider scope must include progress and weekly plan');
assert(src.includes('validateGeneratedMessage'), 'provider output validation missing');
assert(src.includes('academic_state_changed: false'), 'AI response lost non-authoritative contract');

console.log('P1-04 AI deterministic context contract: GREEN');
