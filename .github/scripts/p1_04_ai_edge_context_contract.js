const fs = require('fs');

const file = 'supabase/functions/exam-prep-ai/index.ts';
const src = fs.readFileSync(file, 'utf8');
const assert = (condition, message) => { if (!condition) throw new Error(message); };

const guardCall = src.indexOf('get_exam_prep_ai_guard_v1');
const contextCall = src.indexOf('deterministicContext = await learnerContext');
const sourceCall = src.indexOf('get_exam_prep_ai_source_cards_service_v1', contextCall);
const reservationCall = src.indexOf('await reserveProviderCall');
const providerCall = src.indexOf('await callOpenAIProvider');
const finalizeCall = src.indexOf('await finalizeProviderCall');
assert(guardCall >= 0, 'AI guard call missing');
assert(contextCall >= 0, 'deterministic learner context call missing');
assert(sourceCall >= 0, 'approved source-card retrieval missing');
assert(reservationCall >= 0, 'atomic provider reservation call missing');
assert(providerCall >= 0, 'AI-1 provider call missing');
assert(finalizeCall >= 0, 'provider accounting finalizer missing');
assert(guardCall < contextCall, 'deterministic learner context must be resolved only after the AI guard');
assert(contextCall < sourceCall, 'approved source cards must be resolved only after deterministic context');
assert(sourceCall < reservationCall, 'provider budget reservation must follow approved source retrieval');
assert(reservationCall < providerCall, 'provider must never be called before atomic budget/concurrency reservation');
assert(providerCall < finalizeCall, 'provider usage must be finalized after the provider call');

for (const rpc of [
  'get_exam_prep_overview_safe_v1',
  'get_exam_prep_weekly_plan_safe_v1',
  'get_exam_prep_ai_error_context_safe_v1',
  'get_exam_prep_ai_repeated_error_context_safe_v1',
  'get_exam_prep_ai_skill_theory_context_safe_v1'
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
for (const interaction of [
  '"progress_summary"',
  '"weekly_plan_narration"',
  '"established_error_explanation"',
  '"repeated_error_summary"',
  '"theory_explanation"',
  '"multilingual_explanation"',
  '"context_followup"'
]) {
  assert(src.includes(interaction), `provider scope missing reviewed interaction: ${interaction}`);
}
assert(src.includes('error_context_reference_required'), 'established-error route must require a finalized session/item reference');
assert(src.includes('skill_code_required'), 'theory/multilingual routes must require a canonical skill reference');
assert(src.includes('get_exam_prep_ai_thread_parent_service_v1'), 'service-only AI thread parent lookup missing');
assert(src.includes('MAX_FOLLOWUP_TURNS = 2'), 'AI follow-up turn limit drifted');
assert(src.includes('MAX_FOLLOWUP_TEXT_CHARS = 250'), 'AI follow-up text limit drifted');
assert(src.includes('thread_output_mismatch'), 'AI follow-up is not bound to the prior generated output hash');
assert(src.includes('thread_context_changed'), 'AI follow-up does not fail closed when learner/source context changes');
assert(src.includes('prior_assistant_text'), 'AI follow-up prior assistant binding missing');
assert(src.includes('parent_request_id'), 'AI follow-up parent request binding missing');
assert(src.includes('followup_mode'), 'AI follow-up mode allowlist missing');
assert(src.includes('suspiciousFollowupText'), 'AI follow-up prompt-injection prefilter missing');
assert(src.includes('followupBoundary'), 'AI follow-up out-of-scope learner boundary missing');
assert(src.includes('deterministic_mapping_required'), 'unmapped source-bound interactions must fail closed before provider call');
assert(src.includes('":repeated_error_summary:"'), 'repeated-error source-card selector missing');
assert(src.includes('":theory:"'), 'theory source-card selector missing');
assert(src.includes('validateGeneratedMessage'), 'provider output validation missing');
const providerBundleStart = src.indexOf('function providerSourceBundle');
const providerBundleEnd = src.indexOf('function buildProviderInstructions', providerBundleStart);
const providerBundle = src.slice(providerBundleStart, providerBundleEnd);
assert(!providerBundle.includes('source_card_key'), 'provider prompt bundle still exposes internal source-card keys');
assert(!providerBundle.includes('source_version'), 'provider prompt bundle still exposes internal source versions');
assert(src.includes('Do not introduce any digit, percentage, count, threshold, date, or numeric example unless that exact numeric token already appears'), 'provider prompt must prevent unsupported numeric output before validation');
assert(src.includes('buildLearnerFacingProviderContext'), 'provider-facing context minimizer missing');
assert(src.includes('assertLearnerFacingProviderContext'), 'provider-facing internal-identifier firewall missing');
assert(src.includes('provider_context_internal_identifier'), 'provider-facing context leak must fail closed');
assert(src.includes('localizedTheoryTitle'), 'learner-facing localized topic-title resolver missing');
assert(src.includes('current progress'), 'provider prompt lost learner-context personalization boundary');
assert(src.includes('Do not infer a misconception that is not recorded') || src.includes('without guessing why the learner was wrong'), 'provider prompt lost non-inference learner-context boundary');
assert(src.includes('Do not expose implementation vocabulary'), 'provider prompt lost learner-facing terminology boundary');
assert(src.includes('internal_identifier_leak'), 'provider output validator no longer blocks internal identifiers');
assert(src.includes('/\\bP[15]-[A-Z0-9]+-\\d{2}\\b/'), 'skill-code leakage validator missing');
assert(src.includes('reserve_exam_prep_ai_provider_call_service_v1'), 'atomic provider reservation RPC missing');
assert(src.includes('finalize_exam_prep_ai_provider_call_service_v1'), 'provider accounting finalizer RPC missing');
assert(src.includes('conservativeProviderReservationCost'), 'conservative provider cost reservation missing');
assert(src.includes('academic_state_changed: false'), 'AI response lost non-authoritative contract');

console.log('P1-04 AI deterministic context contract: GREEN');
