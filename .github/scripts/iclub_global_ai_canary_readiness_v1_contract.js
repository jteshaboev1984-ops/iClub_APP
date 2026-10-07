const fs = require('fs');

const edge = fs.readFileSync('supabase/functions/global-ai/index.ts','utf8');
const matrix = fs.readFileSync('supabase/tests/iclub_global_ai_canary_readiness_v1_matrix.sql','utf8');
const doc = fs.readFileSync('docs/iclub-global-ai-controlled-canary-readiness-v1.md','utf8');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

for (const token of [
  "Default Free",
  "exactly three enabled canaries",
  "generation_upgrade_required",
  "generation_not_entitled",
  "Free fourth prepared reply escaped exhaustion",
  "Plus duplicate request double-charged",
  "Limited mode leaked after Plus exhaustion",
  "Failed first response started usage clock",
  "Protected assessment did not block before usage",
  "Plus fourth subject escaped limit",
  "Downgrade erased subject-slot history"
]) {
  assert(matrix.includes(token), 'cross-stack readiness matrix missing: ' + token);
}

const guardIndex = edge.indexOf('guard = await rpc("get_iclub_global_ai_guard_service_v1"');
const reserveIndex = edge.indexOf('reservation = await reserveUsage(');
assert(guardIndex >= 0 && reserveIndex > guardIndex,
  'Global AI gateway does not guard before usage reservation');

const blockedReturnIndex = edge.indexOf('if (guard?.allowed !== true)');
assert(blockedReturnIndex > guardIndex && blockedReturnIndex < reserveIndex,
  'blocked Global AI request could reach usage reservation');

assert(edge.includes('reason: "generation_adapter_not_promoted"'),
  'Global AI generation HOLD boundary is missing');
assert(!edge.includes('OPENAI_API_KEY'),
  'Global AI gateway unexpectedly contains a direct provider credential path');
assert(!edge.includes('api.openai.com'),
  'Global AI gateway unexpectedly calls a provider directly');

for (const token of [
  'Live Global AI generation is intentionally NOT ready yet.',
  'generation_adapter_not_promoted',
  'provider spend reservation and finalization',
  'no provider call for Free',
  'no provider call during protected assessment',
  'Global AI UI OFF',
  'canary subject enforcement OFF'
]) {
  assert(doc.includes(token), 'readiness document missing HOLD/safety statement: ' + token);
}

console.log('iClub Global AI controlled canary readiness static contract: GREEN');
