const fs = require('fs');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const live = fs.readFileSync('exam-prep/exam-prep-live.js', 'utf8');

assert(live.includes('const VERSION = "p260results1"'), 'P2-51 live version marker missing');
for (const token of ['"uz-UZ"', '"en-GB"', '"ru-RU"', 'new Intl.DateTimeFormat(dateLocale()']) {
  assert(live.includes(token), `live locale-safe date contract missing: ${token}`);
}
assert(!live.includes('.toLocaleString()'), 'live weekly-plan dates must not follow device locale');
assert(live.includes('class="ep-live-card" role="status" aria-live="polite"'), 'central loading state must be announced politely');
assert(live.includes('class="ep-live-error" role="alert" aria-live="assertive"'), 'central fatal error must be announced as an alert');
assert(live.includes('data-ep-live-profile-error role="alert" aria-live="assertive"'), 'profile validation errors must be announced');
assert(live.includes('class="ep-live-notice" role="status" aria-live="polite"'), 'one-shot learner notices must be announced politely');
assert(live.includes('data-ep-live-home>${esc(copy().overview)}</button>'), 'central error recovery action missing');
assert(live.includes('type="button" data-ep-live-home'), 'central error recovery action must not submit a surrounding form');
assert(live.includes('type="button" data-ep-live-plan-item='), 'weekly-plan actions must use explicit button type');
assert(live.includes('type="button" data-ep-live-timed-start='), 'timed-start actions must use explicit button type');
assert(live.includes('type="button" data-ep-live-save-self'), 'self-review action must use explicit button type');
assert(!/<span class="ep-live-timer"[^>]*aria-live/i.test(live), 'per-second timed countdown must not become a noisy live region');

const renderedButtons = [...live.matchAll(/<button\b[^>]*>/g)].map(match => match[0]);
const missingType = renderedButtons.filter(tag => !/\btype=/.test(tag));
assert(missingType.length === 0, `rendered Exam Prep buttons missing explicit type: ${missingType.join(' | ')}`);

console.log('P2-51 live accessibility/locale regression: GREEN');
