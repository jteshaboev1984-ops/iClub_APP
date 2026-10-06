const fs = require('fs');

const edgePath = 'supabase/functions/global-ai/index.ts';
const migrationPath = 'supabase/migrations/20261006113000_iclub_global_ai_gateway_foundation_v1.sql';
const generationMigrationPath = 'supabase/migrations/20261006173000_iclub_global_ai_generation_adapter_v1.sql';

const edge = fs.readFileSync(edgePath,'utf8');
const migration = fs.readFileSync(migrationPath,'utf8');
const generationPromoted = fs.existsSync(generationMigrationPath);

const assert = (condition,message) => {
  if (!condition) throw new Error(message);
};

assert(edge.includes('const PREPARED_PROMPTS'), 'prepared quick-prompt map missing');
for (const token of ['topic_main','topic_simple','topic_alternative','topic_focus']) {
  assert(edge.includes(token), `prepared route missing: ${token}`);
}

assert(!edge.includes('payload.route_class'), 'client route_class must not be trusted');
assert(!edge.includes('payload.interaction_type'), 'client interaction_type must not be trusted');
assert(
  edge.includes('const routeClass: "prepared" | "generated" = preparedPrompt ? "prepared" : "generated"'),
  'gateway does not derive route class server-side'
);

const guardCall = edge.indexOf('get_iclub_global_ai_guard_service_v1');
const tutorCall = edge.indexOf('card = await tutorCard(',guardCall);
const preparedReserve = edge.indexOf('reserveUsage(requestId, user.id, usagePolicyCode, "prepared")',tutorCall);

assert(guardCall >= 0, 'global guard invocation missing');
assert(tutorCall > guardCall, 'Tutor source lookup must occur after global guard');
assert(preparedReserve > tutorCall, 'prepared usage reservation must occur after Tutor source lookup');
assert(edge.includes('finalizeUsage(requestId, "completed")'), 'hidden usage completion missing');
assert(edge.includes('finalizeUsage(requestId, "released"'), 'usage release path missing');

if (generationPromoted) {
  const generationMigration = fs.readFileSync(generationMigrationPath,'utf8');
  assert(edge.includes('OPENAI_API_KEY'), 'promoted generation lost provider secret boundary');
  assert(edge.includes('https://api.openai.com/v1/responses'), 'promoted generation provider route missing');
  assert(edge.includes('get_exam_prep_ai_source_cards_service_v1'), 'generated path lost approved source lookup');
  assert(edge.includes('reserve_iclub_global_ai_provider_call_service_v1'), 'generated provider budget reservation missing');
  assert(edge.includes('validateGeneratedMessage'), 'generated output validation missing');
  assert(generationMigration.includes('private.iclub_global_ai_provider_leases'), 'atomic provider lease table missing');
  assert(generationMigration.includes('generation_upgrade_required'), 'paid generation entitlement gate missing');
} else {
  assert(edge.includes('generation_adapter_not_promoted'), 'Phase-2 generation fail-closed boundary missing');
  assert(!edge.includes('OPENAI_API_KEY'), 'dormant Phase-2 gateway unexpectedly has a model key');
  assert(!edge.includes('api.openai.com'), 'dormant Phase-2 gateway unexpectedly calls a provider');
}

for (const forbidden of [
  'tool_call','start_test','mark_complete','update_progress','submit_answer','navigate_to'
]) {
  assert(!edge.includes(forbidden), `forbidden action capability present: ${forbidden}`);
}

assert(edge.includes('academic_state_changed: false') || edge.includes('academic_state_changed:false'), 'non-authoritative response marker missing');
assert(edge.includes('record_iclub_global_ai_gateway_audit_service_'), 'gateway audit call missing');
assert(edge.includes('reserve_iclub_ai_usage_service_v1'), 'hidden usage reservation missing');
assert(edge.includes('finalize_iclub_ai_usage_service_v1'), 'hidden usage finalization missing');

const assessment = migration.indexOf('private.iclub_ai_has_active_protected_assessment_v1(p_user_id)');
const readiness = migration.indexOf('from private.iclub_ai_subject_readiness',assessment);
assert(assessment >= 0, 'protected assessment guard missing');
assert(readiness > assessment, 'subject readiness is evaluated before protected assessment');

assert(
  migration.includes("return jsonb_build_object('allowed',false,'mode','blocked','reason','active_assessment')"),
  'protected assessment does not fail closed'
);
assert(
  migration.includes("return jsonb_build_object('allowed',false,'mode','unavailable','reason','generation_upgrade_required')"),
  'Free generation upgrade gate missing'
);
assert(migration.includes("adapter_code='math_exam_prep_v1'"), 'Mathematics Exam Prep adapter registry missing');

console.log('Global AI gateway static contract: GREEN');
