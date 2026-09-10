const fs = require('fs');

const api = fs.readFileSync('exam-prep/exam-prep-api.js', 'utf8');
const ui = fs.readFileSync('exam-prep/exam-prep-past-paper.js', 'utf8');
const css = fs.readFileSync('exam-prep/exam-prep-host.css', 'utf8');

function must(condition, message) {
  if (!condition) throw new Error(`P2-03 UI regression: ${message}`);
}

must(api.includes('get_exam_prep_past_paper_companion_safe_v1'), 'safe RPC wrapper missing');
must(api.includes('pastPaperCompanion,'), 'API export missing');
must(api.includes('exam-prep-past-paper.js?v=p203paper1'), 'optional learner panel loader missing');
must(ui.includes('internal.api?.pastPaperCompanion') || ui.includes('api?.pastPaperCompanion'), 'panel does not use Exam Prep API boundary');
must(!/window\.sb|\.rpc\s*\(/.test(ui), 'panel bypasses exam-prep-api.js and calls Supabase directly');
must(ui.includes('https:\\/\\/www\\.cambridgeinternational\\.org\\/'), 'official Cambridge hostname allow-check missing');
must(ui.includes('noopener noreferrer'), 'external link opener isolation missing');
must(ui.includes('stores_official_question_content') && ui.includes('stores_official_mark_schemes') && ui.includes('stores_official_answer_keys'), 'copyright boundary checks missing');
must(ui.includes('Прошлые экзаменационные работы'), 'RU learner copy missing');
must(ui.includes('Oldingi imtihon ishlari'), 'UZ learner copy missing');
must(ui.includes('Past exam papers'), 'EN learner copy missing');
must(!/Core beta|Synthetic learner|screening|alpha\b/i.test(ui), 'internal/test terminology leaked to learner copy');
must(!/correct_answer|rubric_json|mark_scheme/i.test(api), 'protected assessment field referenced in learner API adapter');
must(!/correct_answer|rubric_json/i.test(ui), 'protected assessment field referenced in learner UI');

must(!ui.includes('ensureStyle('), 'runtime Past Paper style helper returned');
must(!ui.includes('ep-past-paper-style'), 'runtime Past Paper style id returned');
must(!ui.includes('document.createElement("style")'), 'runtime Past Paper style injection returned');
must(css.includes('EXAM PREP CENTRALIZED PAST PAPER v1'), 'centralized Past Paper CSS marker missing');
must(css.includes('#exam-prep-host-root .ep-past-paper'), 'Past Paper CSS is not host scoped');

new Function(api);
new Function(ui);
console.log('P2-03 learner UI regression: GREEN');
