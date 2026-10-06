const fs = require('fs');

const edge = fs.readFileSync('supabase/functions/global-ai/index.ts','utf8');
const migration = fs.readFileSync(
  'supabase/migrations/20261006173000_iclub_global_ai_generation_adapter_v1.sql',
  'utf8'
);
const revert = fs.readFileSync(
  'supabase/reversions/20261006173000_iclub_global_ai_generation_adapter_v1_revert.sql',
  'utf8'
);
const ui = fs.readFileSync('global-ai-ui.js','utf8');

const assert = (condition,message) => {
  if (!condition) throw new Error(message);
};

// Provider is cost-pinned and never stores provider-side conversation state.
for (const token of [
  'OPENAI_API_KEY',
  'OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses"',
  'OPENAI_MODEL = "gpt-5.6-luna"',
  'OPENAI_MAX_OUTPUT_TOKENS = 220',
  'store: false',
  'validateGeneratedMessage',
  'NO_SOURCE_SENTINEL',
  'provider_context_too_large',
  'provider_timeout',
  'provider_rate_limited',
  'provider_accounting_error'
]) {
  assert(edge.includes(token), `Global AI generation missing provider safety token: ${token}`);
}

assert(!edge.includes('payload.route_class'), 'client route_class became trusted');
assert(!edge.includes('payload.interaction_type'), 'client interaction_type became trusted');
assert(!edge.includes('prior_assistant_text'), 'Global AI generation unexpectedly sends raw prior conversation history');
assert(!edge.includes('conversation_history'), 'Global AI generation unexpectedly sends conversation history');

const guard = edge.indexOf('get_iclub_global_ai_guard_service_v1');
const source = edge.indexOf('cards = await theorySourceCards(',guard);
const usage = edge.indexOf('await reserveUsage(requestId,user.id,usagePolicyCode,"generated")');
const providerReserve = edge.indexOf('await reserveProviderCall(');
const providerCall = edge.indexOf('await callOpenAIProvider(');
const providerFinalize = edge.indexOf('await finalizeProviderCall(');
const validate = edge.indexOf('validateGeneratedMessage({');
const usageFinalize = edge.indexOf('finalizedUsage = await finalizeUsage(requestId,"completed")');

assert(guard >= 0, 'Global AI server guard missing');
assert(source > guard, 'approved source lookup occurs before server guard');
assert(usage > source, 'learner usage reservation occurs before approved source lookup');
assert(providerReserve > usage, 'provider reservation occurs before tariff usage reservation');
assert(providerCall > providerReserve, 'provider call occurs before provider budget reservation');
assert(providerFinalize > providerCall, 'provider accounting finalizer must follow provider call');
assert(validate > providerFinalize, 'output validation must occur after real provider cost is finalized');
assert(usageFinalize > validate, 'learner usage must commit only after output validation');

assert(edge.includes('await finalizeUsage(requestId,"released",reason)'), 'failed generation does not release learner usage');
assert(edge.includes('await finalizeProviderCall(requestId,"released",0)'), 'failed provider call does not release provider lease');
assert(edge.includes('reason==="no_source" ? "no_source" : "failed"'), 'provider no-source result is not separated from validation failure');

for (const token of [
  'adapterCode !== "math_exam_prep_v1"',
  'subjectKey !== "mathematics"',
  'scopeCode !== "exam_prep"',
  '["P1","P5"].includes(componentCode)',
  'skillCode.startsWith(componentCode + "-")'
]) {
  assert(edge.includes(token), `Math-only generated adapter boundary missing: ${token}`);
}

assert(
  edge.includes('String(card?.skill_code || "").toUpperCase() === skillCode'),
  'generated route can consume a generic/wrong-skill source card'
);
assert(edge.includes('p_card_type: "theory"'), 'generated route does not request approved theory sources');
assert(edge.includes('p_skill_code: skillCode'), 'generated source lookup is not skill-bound');

for (const forbidden of [
  'tool_call',
  'navigate_to',
  'start_test',
  'submit_answer',
  'mark_complete',
  'update_progress',
  'new_mastery_level',
  'correct_answer',
  'answer_key'
]) {
  assert(!edge.includes(forbidden), `forbidden action/authority token present in Global AI edge: ${forbidden}`);
}
assert(edge.includes('academic_state_changed:false'), 'generated response lost non-authoritative marker');

// Browser still sends only the current turn and authoritative context hints.
assert(ui.includes('user_text: cleanText'), 'current learner text is not sent');
assert(!ui.includes('conversation_history:'), 'browser started sending full chat history');
assert(!ui.includes('prior_assistant_text:'), 'browser started sending prior assistant text');

// Own provider budget pool: no dependency on the Exam Prep lease table/RPC.
for (const token of [
  'private.iclub_global_ai_provider_policy',
  'private.iclub_global_ai_provider_leases',
  "max_daily_provider_cost_usd numeric(10,4) not null default 0.5000",
  "max_user_daily_provider_cost_usd numeric(10,4) not null default 0.0500",
  "max_provider_request_cost_usd numeric(10,4) not null default 0.0100",
  'max_concurrent_provider_calls integer not null default 2',
  "pg_advisory_xact_lock(hashtextextended('iclub-global-ai-provider-v1',0))",
  'generation_upgrade_required',
  'active_assessment',
  'generation_adapter_not_promoted',
  'record_iclub_global_ai_gateway_audit_service_v2'
]) {
  assert(migration.includes(token), `Global AI provider migration missing: ${token}`);
}
assert(!migration.includes('reserve_exam_prep_ai_provider_call_service_v1'), 'Global AI budget still borrows Exam Prep provider RPC');
assert(!migration.includes('finalize_exam_prep_ai_provider_call_service_v1'), 'Global AI finalizer still borrows Exam Prep provider RPC');

// Provider accounting is private and browser roles have no direct authority.
assert(migration.includes('revoke all on private.iclub_global_ai_provider_leases from public,anon,authenticated'), 'provider leases became browser-readable');
assert(migration.includes('revoke all on function public.reserve_iclub_global_ai_provider_call_service_v1'), 'provider reserve privilege boundary missing');
assert(migration.includes('to service_role'), 'provider RPCs are not service-only');

// Rollback is pre-activation only and removes every additive provider object.
assert(revert.includes("v_runtime.generation_enabled"), 'rollback does not refuse active generation');
assert(revert.includes("v_runtime.global_ai_rollout_mode<>'off'"), 'rollback does not refuse active rollout');
assert(revert.includes('drop table if exists private.iclub_global_ai_provider_leases'), 'rollback provider leases cleanup missing');
assert(revert.includes('drop table if exists private.iclub_global_ai_provider_policy'), 'rollback provider policy cleanup missing');
assert(revert.includes('drop column if exists estimated_cost_usd'), 'rollback audit telemetry cleanup missing');

console.log('Global AI generated Mathematics adapter v1 static contract: GREEN');