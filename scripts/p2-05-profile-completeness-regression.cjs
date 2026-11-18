const fs = require('fs');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const api = fs.readFileSync('exam-prep/exam-prep-api.js', 'utf8');
const guard = fs.readFileSync('exam-prep/exam-prep-profile-completeness.js', 'utf8');
const examMap = fs.readFileSync('exam-prep/exam-prep-exam-map.js', 'utf8');

assert(api.includes('exam-prep-profile-completeness.js?v=p205profile2'), 'profile completeness guard is not loaded by Exam Prep API');
assert(api.includes('data-exam-prep-profile-completeness'), 'profile completeness loader marker missing');
assert(guard.includes('input.required = true'), 'new Exam Profile form fields are not made required');
assert(guard.includes('["exam_series", "target_grade"]'), 'exam series and target grade required-field pair missing');
assert(guard.includes('String(profile.exam_series || "").trim()'), 'existing profile exam-series completeness check missing');
assert(guard.includes('String(profile.target_grade || "").trim()'), 'existing profile target-grade completeness check missing');
assert(guard.includes('data-ep-profile-completion-form'), 'incomplete existing profile repair form missing');
assert(!guard.includes('name="total_hours"')&&!guard.includes('name="math_hours"'),
  'repair may ask only exam series and target, never require weekly hours');
assert(guard.includes('const totalHours = null')&&guard.includes('const mathHours = null'),
  'repair sends NULL hours so server preserves existing choices');
assert(guard.includes('shell.insertBefore(panel, grid)'), 'incomplete profile repair must be additive and preserve dashboard progress');
assert(!guard.includes('root.innerHTML = `<section class="ep-host-shell ep-live" data-ep-profile-completion>'), 'profile repair must not replace the live dashboard');
assert(guard.includes('await internal.api.saveExamProfile'), 'repair flow does not use the governed Exam Profile API');
assert(guard.includes('await window.iClubExamPrep.refreshCapabilities()'), 'repair flow does not remount the governed learner flow after save');
assert(!/localStorage|sessionStorage/.test(guard), 'profile guard must not mutate local/session storage');
assert(!/practice_attempts|practice_answers|tour_attempts|tour_answers|certificates/.test(guard), 'profile guard must not reference legacy learner data stores');
assert(!/delete\s+from|truncate\s+|drop\s+table/i.test(guard), 'destructive data operation detected in learner guard');

for (const text of [
  'Дополните данные об экзамене',
  'Imtihon ma’lumotlarini to‘ldiring',
  'Complete exam details',
  'Ваши ответы и прогресс сохранены',
  'Javoblaringiz va progressingiz saqlangan',
  'Your answers and progress are saved'
]) assert(guard.includes(text), `required learner-safe copy missing: ${text}`);

for (const message of [
  'Imtihon sessiyasi va maqsad bahoni tekshiring.',
  'Check the exam series and target grade.',
  'Проверьте экзаменационную сессию и целевую оценку.'
]) assert(guard.includes(message), 'Repair errors must reference only required exam fields: ' + message);

for (const message of [
  'Agar o‘qish soatlari kiritilsa',
  'If study hours are entered, they must be positive',
  'Если часы указаны, они должны быть больше нуля'
]) assert(examMap.includes(message), 'Plan-editor errors must describe voluntary hours: ' + message);

for (const source of [guard, examMap]) {
  assert(!source.includes('Check all fields. Mathematics time must be above 0'),
    'Outdated mandatory-hour English error text returned');
  assert(!source.includes('Проверьте все поля. Время на математику должно быть больше 0'),
    'Outdated mandatory-hour Russian error text returned');
  assert(!source.includes('Barcha maydonlarni tekshiring. Matematika vaqti 0 dan katta'),
    'Outdated mandatory-hour Uzbek error text returned');
}

console.log('P2-05 Exam Profile completeness regression: GREEN');
