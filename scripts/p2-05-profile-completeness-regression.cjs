const fs = require('fs');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const api = fs.readFileSync('exam-prep/exam-prep-api.js', 'utf8');
const guard = fs.readFileSync('exam-prep/exam-prep-profile-completeness.js', 'utf8');

assert(api.includes('exam-prep-profile-completeness.js?v=p205profile3'), 'profile completeness guard is not loaded by Exam Prep API');
assert(api.includes('data-exam-prep-profile-completeness'), 'profile completeness loader marker missing');
assert(guard.includes('replaceWithSelect(form, "exam_series", seriesChoices())'), 'new Exam Profile exam-series field is not selectable');
assert(guard.includes('replaceWithSelect(form, "target_grade", targetChoices())'), 'new Exam Profile target-grade field is not selectable');
assert(guard.includes('return ["A", "B", "C", "D", "E"]'), 'target-grade choice set must be A-E');
assert(guard.includes('{ value: "June 2027", label: "May/June 2027" }'), 'May/June 2027 exam-session choice missing');
assert(guard.includes('{ value: "November 2027", label: "Oct/Nov 2027" }'), 'Oct/Nov 2027 exam-session choice missing');
assert(guard.includes('if (current && !known)'), 'existing non-standard exam-series value must be preserved instead of silently rewritten');
assert(guard.includes('String(profile.exam_series || "").trim()'), 'existing profile exam-series completeness check missing');
assert(guard.includes('String(profile.target_grade || "").trim()'), 'existing profile target-grade completeness check missing');
assert(guard.includes('data-ep-profile-completion-form'), 'incomplete existing profile repair form missing');
assert(guard.includes('shell.insertBefore(panel, grid)'), 'incomplete profile repair must be additive and preserve dashboard progress');
assert(!guard.includes('root.innerHTML = `<section class="ep-host-shell ep-live" data-ep-profile-completion>'), 'profile repair must not replace the live dashboard');
assert(guard.includes('await internal.api.saveExamProfile'), 'repair flow does not use the governed Exam Profile API');
assert(guard.includes('await window.iClubExamPrep.refreshCapabilities()'), 'repair flow does not remount the governed learner flow after save');
assert(!/localStorage|sessionStorage/.test(guard), 'profile guard must not mutate local/session storage');
assert(!/practice_attempts|practice_answers|tour_attempts|tour_answers|certificates/.test(guard), 'profile guard must not reference legacy learner data stores');
assert(!/delete\s+from|truncate\s+|drop\s+table/i.test(guard), 'destructive data operation detected in learner guard');

for (const text of [
  'Дополните план экзамена',
  'Imtihon rejasini to‘ldiring',
  'Complete your exam plan',
  'Ваши ответы и прогресс сохранены',
  'Javoblaringiz va progressingiz saqlangan',
  'Your answers and progress are saved'
]) assert(guard.includes(text), `required learner-safe copy missing: ${text}`);

console.log('P2-05 Exam Profile completeness and selectable-field regression: GREEN');
