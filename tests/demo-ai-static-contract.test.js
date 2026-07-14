'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const text = file => fs.readFileSync(path.join(root, file), 'utf8');
const runBrowserFiles = files => {
  const sandbox = { window: {}, console };
  vm.createContext(sandbox);
  files.forEach(file => vm.runInContext(text(file), sandbox, { filename: file }));
  return sandbox.window;
};

const windowData = runBrowserFiles([
  'diagnostic-demo-v12-data.js',
  'diagnostic-demo-gate5-cards-a.js',
  'diagnostic-demo-gate5-cards-b.js',
  'diagnostic-demo-gate7-data.js'
]);

const data = windowData.ICLUB_DEMO_V12_DATA;
const cards = windowData.ICLUB_DEMO_GATE5_CARDS;
const activeTour = windowData.ICLUB_DEMO_GATE7_DATA;

assert(data, 'Diagnostic data must load');
assert.strictEqual(data.profile.id, 'demo-sardor', 'One synthetic learner profile is required');
assert.strictEqual(data.questions.length, 7, 'Diagnostic practice must contain 7 questions');
assert.deepStrictEqual(
  data.questions.reduce((acc, item) => ({ ...acc, [item.difficulty]: (acc[item.difficulty] || 0) + 1 }), {}),
  { easy: 2, medium: 3, hard: 2 },
  'Difficulty distribution must be 2 easy / 3 medium / 2 hard'
);
for (const item of data.questions) {
  assert(['A', 'B', 'C', 'D'].includes(item.a), `${item.id}: correct option must be A-D`);
  for (const language of ['ru', 'uz', 'en']) {
    assert(item.q?.[language], `${item.id}: missing ${language} question`);
    assert.strictEqual(item.o?.[language]?.length, 4, `${item.id}: ${language} must have four options`);
    assert(item.ok?.[language] && item.bad?.[language] && item.next?.[language], `${item.id}: missing ${language} explanations`);
  }
}
assert(data.history.some(item => item.id === 't4' && item.score === 6 && item.total === 20), 'Closed Tour 4 history is required');
assert(data.history.some(item => item.id === 'p4' && item.score === 10 && item.total === 10), 'Practice 4 history is required');

assert(Array.isArray(cards) && cards.length >= 30, 'At least 30 verified knowledge cards are required');
for (const card of cards.slice(0, 30)) {
  for (const language of ['ru', 'uz', 'en']) {
    assert(card.short?.[language], `${card.id}: missing ${language} short answer`);
    assert(card.simple?.[language], `${card.id}: missing ${language} simple answer`);
    assert(card.section?.[language], `${card.id}: missing ${language} source section`);
  }
}

assert(activeTour?.questions?.length >= 5, 'Active Tour 5 guard dataset is required');
const forbiddenKeys = ['answer', 'answerKey', 'answer_key', 'correct', 'correctOption', 'correct_option', 'solution'];
for (const item of activeTour.questions) {
  forbiddenKeys.forEach(key => assert(!Object.prototype.hasOwnProperty.call(item, key), `${item.id}: client active-tour payload exposes ${key}`));
  for (const language of ['ru', 'uz', 'en']) {
    assert(item.stem?.[language], `${item.id}: missing ${language} active-tour stem`);
    assert.strictEqual(item.options?.[language]?.length, 4, `${item.id}: ${language} active-tour options must have four entries`);
  }
}

const html = text('diagnostic-demo.html');
assert(html.includes("connect-src 'self'"), 'CSP must allow only same-origin API calls');
assert(!/supabase/i.test(html), 'Demo HTML must not load Supabase');
assert(html.includes('diagnostic-demo-gate6.js'), 'Generated AI controller must be loaded');

const main = text('diagnostic-demo-main-local.js');
assert(main.includes("key?.startsWith(PREFIX)"), 'Reset must delete only the demo namespace');
assert(!/location\.reload\s*\(/.test(main), 'Plan switch must work without reload');

const gate5 = text('diagnostic-demo-gate5-ui-v2.js');
assert(gate5.includes("node('div','demo-ai-bubble',message.text)"), 'User chat text must be rendered through textContent');
assert(!/innerHTML\s*=\s*message\.text/.test(gate5), 'User chat text must never be assigned to innerHTML');

const gate6 = text('diagnostic-demo-gate6.js');
assert(gate6.includes("`${language()}|subject_chat|${contextId}|${normalize(question)}`"), 'Client cache key must not include the plan');
assert(gate6.includes("safe_renderer:'DOM textContent'"), 'Technical state must record the safe renderer');

const endpoint = text('api/diagnostic-ai.js');
assert(endpoint.includes("const MAX_QUESTION = 500"), 'Server prompt length limit is required');
assert(endpoint.includes('one_active_request_per_session'), 'Server must enforce one active request per session');
assert(endpoint.includes('DEMO_AI_GENERATED_ENABLED'), 'Emergency generated-AI flag is required');
assert(endpoint.includes('evaluateActiveTourGuard'), 'Server-side active-tour guard is required');
assert(endpoint.includes('SENSITIVE_INTENT'), 'Instruction-disclosure prompts must be blocked before model call');
assert(endpoint.includes('instruction_disclosure_not_supported'), 'Prompt-injection refusal mode is required');
assert(endpoint.includes('plan_ignored: true'), 'The endpoint must explicitly ignore client plan claims');
assert(!/supabase/i.test(endpoint), 'AI endpoint must not access Supabase');
assert(!/\$\{plan\}/.test(endpoint), 'Server cache must not split the same base answer by plan');

const serverCards = require('../api/_diagnostic-ai-cards');
assert(Array.isArray(serverCards) && serverCards.length >= 10, 'Server retrieval cards must exist');
assert(serverCards.every(card => ['ru', 'uz', 'en'].every(language => card.facts?.[language])), 'Server retrieval cards must contain RU/UZ/EN facts');

console.log('Demo AI static contract checks passed.');
