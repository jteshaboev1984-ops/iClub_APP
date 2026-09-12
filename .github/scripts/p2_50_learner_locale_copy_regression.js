const fs = require('fs');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const views = fs.readFileSync('exam-prep/exam-prep-learner-views.js', 'utf8');
const placement = fs.readFileSync('exam-prep/exam-prep-overview-placement.js', 'utf8');

assert(!views.includes('The Core learning route'), 'learner-facing English copy must not expose the internal Core term');
assert(views.includes('Your learning route continues even when no human review is available.'), 'learner-facing English written-work note missing');

for (const token of ['"uz-UZ"', '"en-GB"', '"ru-RU"', 'new Intl.DateTimeFormat(dateLocale()']) {
  assert(views.includes(token), `learner views locale-safe date contract missing: ${token}`);
  assert(placement.includes(token), `overview locale-safe date contract missing: ${token}`);
}

assert(!views.includes('.toLocaleDateString()'), 'learner views must not format dates from the device locale');
assert(!views.includes('.toLocaleString()'), 'learner views must not format date-times from the device locale');
assert(!placement.includes('.toLocaleDateString()'), 'overview must not format dates from the device locale');

assert(views.includes('class="ep-views-error" role="alert" aria-live="assertive"'), 'learner-view load error must be announced');
assert(views.includes('class="ep-views-card" role="status" aria-live="polite"'), 'learner-view loading state must be announced politely');
assert(placement.includes('class="ep-placement-error" role="alert" aria-live="assertive"'), 'placement load error must be announced');
assert(placement.includes('class="ep-placement-card" role="status" aria-live="polite"'), 'placement loading state must be announced politely');

for (const internalTerm of ['Core beta', 'Synthetic learner data', 'source_gap_review']) {
  assert(!views.includes(internalTerm), `learner views leaked internal term: ${internalTerm}`);
  assert(!placement.includes(internalTerm), `overview/placement leaked internal term: ${internalTerm}`);
}

console.log('P2-50 learner locale/copy/accessibility regression: GREEN');
