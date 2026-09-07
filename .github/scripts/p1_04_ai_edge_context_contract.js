const fs = require('fs');

const file = 'supabase/functions/exam-prep-ai/index.ts';
const src = fs.readFileSync(file, 'utf8');
const assert = (condition, message) => { if (!condition) throw new Error(message); };

const guardCall = src.indexOf('get_exam_prep_ai_guard_v1');
const contextCall = src.indexOf('deterministicContext = await learnerContext');
assert(guardCall >= 0, 'AI guard call missing');
assert(contextCall >= 0, 'deterministic learner context call missing');
assert(guardCall < contextCall, 'deterministic learner context must be resolved only after the AI guard');

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
assert(src.includes('generated: false'), 'foundation must remain explicit that model generation is off');
assert(src.includes('model_not_configured'), 'safe model-not-configured fallback missing');

console.log('P1-04 AI deterministic context contract: GREEN');
