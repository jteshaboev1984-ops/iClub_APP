const fs = require('fs');

const js = fs.readFileSync('global-ai-ui.js', 'utf8');
const css = fs.readFileSync('global-ai-ui.css', 'utf8');
const html = fs.readFileSync('index.html', 'utf8');
const edge = fs.readFileSync('supabase/functions/global-ai/index.ts', 'utf8');
const migration = fs.readFileSync(
  'supabase/migrations/20261006133000_iclub_global_ai_conversation_ui_v1.sql',
  'utf8'
);

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

assert(html.includes('global-ai-ui.css?v=globalaichat1'), 'conversation CSS cache tag missing');
assert(html.includes('global-ai-ui.js?v=globalaichat1'), 'conversation JS cache tag missing');
assert(!html.includes('globalaishell1'), 'old Global AI shell cache tag remains');
assert(!html.includes('\\n<script src="global-ai-ui.js'), 'literal escaped newline leaked into HTML');

const tabbarStart = html.indexOf('<nav id="tabbar"');
const tabbarEnd = html.indexOf('</nav>', tabbarStart);
assert(tabbarStart >= 0 && tabbarEnd > tabbarStart, 'bottom navigation not found');
const tabs = [...html.slice(tabbarStart, tabbarEnd).matchAll(/data-tab="([^"]+)"/g)].map((m) => m[1]);
assert(JSON.stringify(tabs) === JSON.stringify(['home','courses','ratings','profile']), 'Global AI changed the four-tab navigation');

for (const token of [
  'const MAX_THREAD_MESSAGES = 40',
  'threads: new Map()',
  'function resolveContext()',
  'function quickPrompts(ctx)',
  'function sendMessage',
  'client.functions.invoke("global-ai"',
  'data-global-ai-quick',
  'data-global-ai-input',
  'data-global-ai-messages',
  'usage_exhausted',
  'reset_at',
  'topic_main',
  'topic_simple',
  'topic_alternative',
  'topic_focus'
]) {
  assert(js.includes(token), `conversation shell missing required token: ${token}`);
}

assert(js.includes('button.addEventListener("click"'), 'quick-prompt immediate send handler missing');
assert(js.includes('appendMessage(threadKey, "user", cleanDisplay)'), 'user message is not rendered before request');
assert(js.includes('if (state.busy) body.appendChild(typingNode())'), 'inline AI working state missing');
assert(js.includes('previousThread !== next.threadKey'), 'subject-thread switch collapse missing');
assert(js.includes('data-ep-ai-skill-detail') && js.includes('data-ep-ai-skill-component'), 'Math Exam Prep skill context missing');
assert(js.includes('subjectKey: "general"'), 'General iClub thread missing');

for (const forbidden of [
  'localStorage',
  'sessionStorage',
  'allowance_units',
  'prepared_weight',
  'generation_weight',
  'provider_cost',
  'tool_call',
  'navigate_to',
  'start_test',
  'submit_answer',
  'mark_complete',
  'update_progress'
]) {
  assert(!js.includes(forbidden), `conversation shell contains forbidden internal/action token: ${forbidden}`);
}

assert(!js.includes('plan_code'), 'conversation shell must not expose plan code');
assert(!js.includes('Free 3') && !js.includes('Plus 9') && !js.includes('Pro 14'), 'conversation shell exposes hidden counters');

for (const token of [
  '.iclub-global-ai-message.is-user',
  '.iclub-global-ai-message.is-assistant',
  '.iclub-global-ai-message.is-typing',
  '.iclub-global-ai-quick-btn',
  '.iclub-global-ai-limit',
  '.iclub-global-ai-composer textarea',
  'html.iclub-global-ai-active #exam-prep-host-root [data-ep-ai-context-action]',
  'html.iclub-global-ai-active #exam-prep-host-root [data-ep-ai-topic-action-wrap]'
]) {
  assert(css.includes(token), `conversation CSS missing required rule: ${token}`);
}

assert(
  css.includes('@media (max-width: 340px)') && css.includes('@media (max-width: 600px)'),
  '320px/390px responsive boundaries missing'
);
assert(css.includes('@media (prefers-reduced-motion: reduce)'), 'reduced motion boundary missing');

for (const token of [
  'app_help_here',
  'app_help_practice',
  'app_help_tours',
  'app_help_results',
  'function matchPreparedPrompt',
  'normalizeIntentText',
  'usage_exhausted: finalizedUsage?.exhausted === true'
]) {
  assert(edge.includes(token), `Global AI edge missing prepared conversation behavior: ${token}`);
}

assert(edge.includes('const matchedPromptKey = explicitPromptKey || matchPreparedPrompt(userText, locale)'), 'typed exact-intent routing missing');
assert(edge.includes('const preparedPrompt = promptKey ? PREPARED_PROMPTS[promptKey] : null'), 'prepared intent resolution missing');
assert(edge.includes('const routeClass: "prepared" | "generated" = preparedPrompt ? "prepared" : "generated"'), 'route class is not server-derived');
assert(!edge.includes('payload.route_class'), 'client route_class is trusted');
assert(!edge.includes('payload.interaction_type'), 'client interaction_type is trusted');

assert(migration.includes("'general','global','basic',false"), 'General iClub BASIC readiness missing');
assert(migration.includes("'usage_exhausted',v_exhausted"), 'browser bootstrap exhausted state missing');
assert(migration.includes("'reset_at',v_reset_at"), 'browser bootstrap reset time missing');

for (const forbidden of ['allowance_units','prepared_weight','generation_weight','monthly_price_uzs','plan_code','user_text','raw_chat']) {
  assert(!migration.includes(`'${forbidden}'`), `browser bootstrap migration exposes forbidden field: ${forbidden}`);
}

console.log('Global AI contextual conversations static contract: GREEN');
