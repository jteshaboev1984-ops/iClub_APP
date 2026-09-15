const fs = require('fs');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const profile = fs.readFileSync('exam-prep/exam-prep-profile-completeness.js', 'utf8');
const recovery = fs.readFileSync('exam-prep/exam-prep-recovery.js', 'utf8');
const examMap = fs.readFileSync('exam-prep/exam-prep-exam-map.js', 'utf8');
const materials = fs.readFileSync('exam-prep/exam-prep-materials.js', 'utf8');

assert(profile.includes('data-ep-profile-completion-error role="alert" aria-live="assertive"'), 'profile completion errors must be announced');
assert(profile.includes('return `<select name="${esc(name)}" required aria-required="true">'), 'profile selectable fields must expose required and aria-required');
assert(profile.includes('selectMarkup("exam_series", seriesChoices()'), 'profile exam-series select missing');
assert(profile.includes('selectMarkup("target_grade", targetChoices()'), 'profile target-grade select missing');
assert((profile.match(/required aria-required="true"/g) || []).length >= 3, 'profile completion select/numeric required controls must expose aria-required');

assert(materials.includes('class="ep-materials-card" role="status" aria-live="polite"'), 'materials loading state must be announced politely');
assert(materials.includes('class="ep-materials-safe" role="alert" aria-live="assertive"'), 'materials load failure must be announced as an alert');

assert(examMap.includes('data-ep-exam-plan-error role="alert" aria-live="assertive"'), 'exam-plan validation errors must be announced');
assert(examMap.includes('return `<select name="${esc(name)}" required aria-required="true">'), 'exam-plan selectable fields must expose required and aria-required');
assert(examMap.includes('selectMarkup("exam_series", seriesChoices()'), 'exam-plan exam-series select missing');
assert(examMap.includes('selectMarkup("target_grade", targetChoices()'), 'exam-plan target-grade select missing');
assert((examMap.match(/required aria-required="true"/g) || []).length >= 3, 'exam-plan select/numeric required controls must expose aria-required');
assert(examMap.includes('notice.setAttribute("role", "status")'), 'exam-plan saved notice must be a status');
assert(examMap.includes('notice.setAttribute("aria-live", "polite")'), 'exam-plan saved notice must be polite');

assert(recovery.includes('data-ep-recovery-error role="alert" aria-live="assertive"'), 'recovery-form errors must be announced');
assert(recovery.includes('data-ep-recovery-feedback role="status" aria-live="polite"'), 'recovery check feedback must be announced politely');
assert(recovery.includes('class="ep-live-error" role="alert" aria-live="assertive"'), 'recovery fatal errors must be announced');
assert((recovery.match(/required aria-required="true"/g) || []).length >= 3, 'recovery required fields must expose aria-required');
assert(recovery.includes('data-ep-recovery-success') && recovery.includes('role="status" aria-live="polite"'), 'recovery completion state must be announced politely');

for (const [name, source] of [['profile', profile], ['recovery', recovery], ['exam-map', examMap], ['materials', materials]]) {
  assert(!source.includes('localStorage.setItem('), `${name} accessibility layer must not write localStorage`);
  assert(!source.includes('sessionStorage.setItem('), `${name} accessibility layer must not write sessionStorage`);
}

console.log('P2-52 auxiliary status accessibility regression: GREEN');
