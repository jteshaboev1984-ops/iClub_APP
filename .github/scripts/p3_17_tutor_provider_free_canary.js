const fs = require('fs');

const edge = fs.readFileSync('supabase/functions/exam-prep-ai/index.ts', 'utf8');
const ui = fs.readFileSync('exam-prep/exam-prep-ai-ui.js', 'utf8');
const assert = (condition, message) => { if (!condition) throw new Error(message); };

const sourceLookup = edge.indexOf('get_exam_prep_ai_source_cards_service_v1');
const tutorLookup = edge.indexOf('get_exam_prep_ai_tutor_card_service_v1');
const templateMode = edge.indexOf('const mode = "verified_template"');
const reserve = edge.indexOf('await reserveProviderCall');
const provider = edge.indexOf('await callOpenAIProvider');

assert(sourceLookup >= 0, 'approved source lookup missing');
assert(tutorLookup >= 0, 'Tutor Card lookup missing');
assert(templateMode >= 0, 'verified_template route missing');
assert(reserve >= 0 && provider >= 0, 'provider fallback path missing');
assert(sourceLookup < templateMode, 'curated response must follow approved source binding');
assert(templateMode < reserve, 'curated response must happen before provider budget reservation');
assert(reserve < provider, 'provider call must remain behind budget reservation');

assert(edge.includes('main: "main_explanation"'), 'main Tutor variant missing');
assert(edge.includes('simplify: "simple_explanation"'), 'simple Tutor variant missing');
assert(edge.includes('rephrase: "alternative_explanation"'), 'alternative Tutor variant missing');
assert(edge.includes('focus: "focus_explanation"'), 'focus Tutor variant missing');
assert(edge.includes('["simplify","rephrase","focus"].includes(params.followupMode)'), 'only reviewed chips may use curated variants');
assert(!edge.includes('["simplify","rephrase","focus","question"].includes(params.followupMode)'), 'learner question must not use static Tutor variant');
assert(edge.includes('provider_called: false'), 'curated response must explicitly record no provider call');
assert(edge.includes('generated: false'), 'curated response must remain non-generated');
assert(edge.includes('academic_state_changed: false'), 'curated response must remain non-authoritative');
assert(edge.includes('["generated","verified_template"].includes'), 'thread parent must accept curated root');
assert(edge.includes('followupMode === "question"'), 'learner-written question provider path missing');
assert(edge.includes('await callOpenAIProvider'), 'provider-backed learner clarification path missing');

assert(ui.includes('const VERSION = "p305tutor2"'), 'Tutor follow-up UX version missing');
assert(ui.includes('topic: "Explain this topic"'), 'English curated topic label missing');
assert(ui.includes('topic: "Объяснить эту тему"'), 'Russian curated topic label missing');
assert(ui.includes('topic: "Bu mavzuni tushuntirish"'), 'Uzbek curated topic label missing');
assert(!ui.includes('Explain this topic with AI'), 'first topic action still claims provider generation');
assert(ui.includes('curatedSourceNote'), 'curated source note missing');
assert(ui.includes('data?.mode === "verified_template"'), 'UI does not continue thread from curated response');
assert(ui.includes('data-ep-ai-followup-mode="simplify"'), 'simple follow-up chip missing');
assert(ui.includes('data-ep-ai-followup-mode="rephrase"'), 'alternative follow-up chip missing');
assert(ui.includes('data-ep-ai-followup-mode="focus"'), 'focus follow-up chip missing');
assert(ui.includes('maxlength="250"'), 'bounded learner question input missing');
assert(ui.includes('MAX_GENERATED_FOLLOWUPS = 2'), 'learner-written AI follow-up limit missing');
assert(ui.includes('button.hidden = used'), 'used prepared chip is not removed from the learner UI');
assert(ui.includes('questionLimit'), 'written-question limit is not explained to the learner');
assert(!ui.includes('localStorage'), 'Tutor UI must not write/read legacy localStorage');

console.log('P3-17 provider-free Tutor canary contract: GREEN');
