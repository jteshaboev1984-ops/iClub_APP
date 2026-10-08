const fs = require('fs');

const js = fs.readFileSync('global-ai-ui.js', 'utf8');
const css = fs.readFileSync('global-ai-ui.css', 'utf8');
const html = fs.readFileSync('index.html', 'utf8');
const migration = fs.readFileSync(
  'supabase/migrations/20261006124000_iclub_global_ai_ui_bootstrap_v1.sql',
  'utf8'
);

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

assert(html.includes('global-ai-ui.css?v=globalaichat1'), 'Integrated Global AI stylesheet not loaded');
assert(html.includes('global-ai-ui.js?v=globalaichat1'), 'Integrated Global AI script not loaded');
assert(
  html.indexOf('global-ai-ui.js?v=globalaichat1') > html.indexOf('practice-ai-ui.js?v=ai2review1'),
  'Global AI shell must load after existing app/Practice AI controllers'
);

assert(js.includes('get_iclub_ai_ui_bootstrap_v1'), 'server UI bootstrap is not used');
assert(js.includes('const ROOT_ID = "iclub-global-ai-root"'), 'single root identity missing');
assert(js.includes('ensurePanel()'), 'lazy panel factory missing');
assert(js.includes('PROTECTED_EXAM_PREP_TYPES'), 'Exam Prep protected session list missing');
assert(js.includes('iclub:exam-prep-session'), 'Exam Prep start event guard missing');
assert(js.includes('iclub:exam-prep-session-ended'), 'Exam Prep end event guard missing');
assert(js.includes('courses-tour-quiz'), 'Tour active-screen collapse guard missing');
assert(js.includes('assessmentStart'), 'assessment-collapse notification copy missing');
assert(js.includes('assessmentTap'), 'assessment tap boundary copy missing');
assert(js.includes('HIDDEN_VIEWS'), 'sensitive/public view hiding missing');
assert(js.includes('"splash", "registration", "certificate-verify"'), 'required hidden view set missing');
assert(js.includes('setTimeout(() => { void refreshBootstrap(); }, 0)'), 'lazy bootstrap start missing');

for (const forbidden of [
  'localStorage',
  'sessionStorage',
  'OPENAI_API_KEY',
  'api.openai.com',
  '/v1/responses',
  'allowance_units',
  'prepared_weight',
  'generation_weight',
  'usage_policy_code',
  'provider_cost',
  'tool_call',
  'navigate_to',
  'submit_answer',
  'update_progress'
]) {
  assert(!js.includes(forbidden), `learner shell contains forbidden internal/action token: ${forbidden}`);
}

assert(js.includes('.functions.invoke("global-ai"'), 'Integrated conversation shell must invoke the governed Global AI function');
assert(js.includes('data.academic_state_changed !== false'), 'Integrated conversation shell must reject authoritative AI state changes');
assert(js.includes('REQUEST_TIMEOUT_MS'), 'Integrated conversation shell timeout boundary missing');
assert(
  (js.match(/document\.body\.appendChild\(host\)/g) || []).length === 1,
  'Global AI shell should mount one root only'
);

assert(css.includes('.iclub-global-ai-root'), 'root shell CSS missing');
assert(css.includes('z-index: 40'), 'AI shell must stay below toast/modal safety surfaces');
assert(css.includes('bottom: calc(78px + var(--safe-bottom))'), 'AI mark is not positioned above bottom navigation');
assert(css.includes('min-width: 48px') && css.includes('min-height: 48px'), 'AI mark touch target is below 44px');
assert(!/(^|\n)\s*(?:body|html|:root|\.tabbar|\.toast|\.modal-root)\s*\{/m.test(css), 'Global AI CSS contains unscoped app-shell overrides');

assert(migration.includes('auth.uid()'), 'UI bootstrap must resolve current authenticated learner server-side');
assert(migration.includes('private.iclub_ai_has_active_protected_assessment_v1(v_uid)'), 'UI bootstrap missing server assessment state');
assert(migration.includes("'visible',false"), 'UI bootstrap missing fail-closed hidden state');
assert(!migration.includes("'plan_code'"), 'UI bootstrap leaks plan name');
assert(!migration.includes('allowance_units'), 'UI bootstrap leaks hidden allowance');

console.log('Global AI learner shell static contract: GREEN');
