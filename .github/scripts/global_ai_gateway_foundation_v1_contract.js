const fs = require('fs');

const edgePath = 'supabase/functions/global-ai/index.ts';
const migrationPath = 'supabase/migrations/20261006113000_iclub_global_ai_gateway_foundation_v1.sql';

const edge = fs.readFileSync(edgePath, 'utf8');
const migration = fs.readFileSync(migrationPath, 'utf8');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

assert(edge.includes('const PREPARED_PROMPTS'), 'prepared quick-prompt map missing');
assert(edge.includes('topic_main'), 'topic_main prepared route missing');
assert(edge.includes('topic_simple'), 'topic_simple prepared route missing');
assert(edge.includes('topic_alternative'), 'topic_alternative prepared route missing');
assert(edge.includes('topic_focus'), 'topic_focus prepared route missing');

assert(!edge.includes('payload.route_class'), 'client route_class must not be trusted');
assert(!edge.includes('payload.interaction_type'), 'client interaction_type must not be trusted');
assert(
  edge.includes('const routeClass: "prepared" | "generated" = preparedPrompt ? "prepared" : "generated"'),
  'gateway does not derive route class server-side'
);

const guardCall = edge.indexOf('get_iclub_global_ai_guard_service_v1');
const tutorCall = edge.indexOf('get_exam_prep_ai_tutor_card_service_v1');
const reserveCall = edge.indexOf('reserve_iclub_ai_usage_service_v1');
const finalizeCall = edge.indexOf('finalize_iclub_ai_usage_service_v1');

assert(guardCall >= 0, 'global guard call missing');
assert(tutorCall > guardCall, 'Tutor source lookup must occur after global guard');
assert(reserveCall > tutorCall, 'usage reservation must occur only after prepared source is confirmed');
assert(finalizeCall > reserveCall, 'usage finalization must follow reservation');

assert(edge.includes('generation_adapter_not_promoted'), 'Phase-2 generation fail-closed boundary missing');
assert(!edge.includes('OPENAI_API_KEY'), 'Global gateway Phase 2 must not have a model API key');
assert(!edge.includes('api.openai.com'), 'Global gateway Phase 2 must not call a model provider');
assert(!edge.includes('/v1/responses'), 'Global gateway Phase 2 must not expose provider route');

for (const forbidden of [
  'tool_call',
  'start_test',
  'mark_complete',
  'update_progress',
  'submit_answer',
  'navigate_to',
]) {
  assert(!edge.includes(forbidden), `forbidden action capability present: ${forbidden}`);
}

assert(edge.includes('academic_state_changed: false'), 'non-authoritative response marker missing');
assert(edge.includes('record_iclub_global_ai_gateway_audit_service_v1'), 'gateway audit call missing');
assert(edge.includes('reserve_iclub_ai_usage_service_v1'), 'hidden usage reservation missing');
assert(edge.includes('finalize_iclub_ai_usage_service_v1'), 'hidden usage finalization missing');

const assessment = migration.indexOf('private.iclub_ai_has_active_protected_assessment_v1(p_user_id)');
const readiness = migration.indexOf('from private.iclub_ai_subject_readiness', assessment);
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
assert(
  migration.includes("adapter_code='math_exam_prep_v1'"),
  'Mathematics Exam Prep adapter registry missing'
);

console.log('Global AI gateway static contract: GREEN');
