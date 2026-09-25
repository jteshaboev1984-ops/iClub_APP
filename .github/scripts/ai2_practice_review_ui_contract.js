const fs = require('fs');

const assert = (condition, message) => { if (!condition) throw new Error(message); };

const edge = fs.readFileSync('supabase/functions/practice-ai/index.ts', 'utf8');
const ui = fs.readFileSync('practice-ai-ui.js', 'utf8');
const app = fs.readFileSync('app.js', 'utf8');
const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('style.css', 'utf8');
const migration = fs.readFileSync('supabase/migrations/20260925183000_practice_ai2_review_ui_contract_v1.sql', 'utf8');

assert(migration.includes('get_practice_ai_review_question_context_service_v1'), 'owned finalized review context RPC missing');
assert(migration.includes('get_practice_ai_ui_context_v1'), 'browser-safe Practice AI UI capability RPC missing');
assert(migration.includes("revoke all on function public.get_practice_ai_review_question_context_service_v1"), 'review context revoke missing');
assert(migration.includes("to service_role"), 'review context is not service-role bound');
assert(migration.includes("grant execute on function public.get_practice_ai_ui_context_v1"), 'UI context execute grant missing');
assert(!/jsonb_build_object\([\s\S]{0,1000}'correct_answer'/i.test(migration), 'correct_answer leaked into AI review context');

assert(edge.includes('get_practice_ai_review_question_context_service_v1'), 'Edge Function cannot consume finalized review context');
assert(edge.includes('if (attemptId)'), 'Edge Function does not distinguish finalized attempt from live session');
assert(!edge.toLowerCase().includes('correct_answer'), 'Practice AI Edge Function references correct_answer');

assert(ui.includes('get_practice_ai_ui_context_v1'), 'Practice AI UI does not use server visibility contract');
assert(ui.includes('interaction_type: "practice_result_summary"'), 'Practice result summary action missing');
assert(ui.includes('interaction_type: "post_answer_explanation"'), 'Practice review explanation action missing');
assert(ui.includes('client.functions.invoke("practice-ai"'), 'Practice UI bypasses governed Edge Function');
assert(ui.includes('button.addEventListener("click"'), 'Practice AI generation is not explicit-tap driven');
assert(!ui.includes('localStorage'), 'Practice AI output must not be persisted in localStorage');
assert(!ui.includes('correctAnswer') && !ui.includes('correct_answer'), 'Practice AI UI reads answer-key material');
assert(!ui.includes('sessionStorage'), 'Practice AI output must remain ephemeral');

assert(app.includes('data-practice-ai-attempt-id') || app.includes('practiceAiAttemptId'), 'Practice host does not expose safe attempt id');
assert(app.includes('practiceAiQuestionId'), 'Practice review rows do not expose safe question ids');
assert(!app.includes('iclub:practice-ai-context-changed', app.indexOf('correctAnswer')), 'invalid host event contract');

const appIndex = html.indexOf('app.js?v=');
const uiIndex = html.indexOf('practice-ai-ui.js?v=ai2review1');
assert(appIndex >= 0 && uiIndex > appIndex, 'Practice AI UI must load after app host');
assert(css.includes('Practice learning assistant — AI-2 dormant learner UI'), 'centralized Practice AI UI CSS missing');
assert(css.includes('.practice-ai-card') && css.includes('.practice-ai-inline'), 'Practice AI UI style surface incomplete');

console.log('AI-2 Practice review UI contract: GREEN');
