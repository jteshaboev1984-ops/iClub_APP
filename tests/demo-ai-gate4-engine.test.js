'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.resolve(__dirname, '..');
const sandbox = { window: {}, console };
vm.createContext(sandbox);
for (const file of ['diagnostic-demo-v12-data.js', 'diagnostic-demo-gate4-data.js', 'diagnostic-demo-gate4-engine.js']) {
  vm.runInContext(fs.readFileSync(path.join(root, file), 'utf8'), sandbox, { filename: file });
}

const data = sandbox.window.ICLUB_DEMO_V12_DATA;
const engine = sandbox.window.ICLUB_DEMO_DIAGNOSTIC_ENGINE;
assert(data && engine, 'Diagnostic data and engine must load');

function attempt(id, selector) {
  const answers = data.questions.map(question => ({
    questionId: question.id,
    selected: selector(question),
    timeSpent: 35
  }));
  return {
    id,
    total: data.questions.length,
    score: answers.filter(answer => answer.selected === data.questions.find(question => question.id === answer.questionId).a).length,
    answers
  };
}

const scenario = engine.compute({ currentAttempt: attempt('scenario', question => question.scenario) });
assert.strictEqual(scenario.valid, true, `Engine validation failed: ${scenario.validationErrors.join(', ')}`);
assert.strictEqual(scenario.profileId, data.profile.id, 'Pro engine must use the same synthetic learner id');
assert.strictEqual(scenario.currentAttemptSummary.answered, 7, 'Scenario attempt must contain seven answers');
assert(scenario.repeatedErrors.length >= 1, 'Approved scenario must produce at least one repeated error');
assert(scenario.historicalSummary.unverifiedTour4Errors.length > 0, 'Practice 4 at 100% must leave unverified Tour 4 errors');
assert(scenario.whatCanBeConcluded.some(item => item.id === 'coverage_mismatch'), 'Coverage mismatch must be explicit');
assert(scenario.targetedSet.length > 0 && scenario.targetedSet.length <= 6, 'Targeted set must contain 1-6 questions');
assert(scenario.targetedSet.every(item => item.activeTour !== true), 'Targeted set must not include active-tour questions');

const q5Correct = engine.compute({
  currentAttempt: attempt('q5-correct', question => question.id === 'd5' ? question.a : question.scenario)
});
const q5Before = scenario.skills.find(item => item.skillId === 'allocative_efficiency_condition');
const q5After = q5Correct.skills.find(item => item.skillId === 'allocative_efficiency_condition');
assert(q5Before?.repeatedError, 'Approved scenario must repeat the allocative-efficiency pattern');
assert.strictEqual(q5After?.repeatedError, false, 'Changing question 5 to correct must remove the repeated-error status');
assert.strictEqual(q5After?.positiveSignal, true, 'Changing question 5 to correct must create a positive signal');
assert(scenario.repeatedErrors.includes('allocative_efficiency_condition'), 'Scenario must include the repeated allocative-efficiency skill');
assert(!q5Correct.repeatedErrors.includes('allocative_efficiency_condition'), 'Correcting question 5 must remove that skill from repeated errors');
assert(q5Correct.positiveSignals.includes('allocative_efficiency_condition'), 'Correcting question 5 must add that skill to positive signals');

const allCorrect = engine.compute({ currentAttempt: attempt('all-correct', question => question.a) });
assert.strictEqual(allCorrect.currentAttemptSummary.correct, 7, 'All-correct attempt must score 7/7');
assert.strictEqual(allCorrect.repeatedErrors.length, 0, 'All-correct attempt must not retain fixed repeated-error text');
assert(allCorrect.positiveSignals.length >= 3, 'All-correct attempt must create positive signals');
assert(allCorrect.whatCanBeConcluded.some(item => item.id === 'efficiency_pair_current_session'), 'Efficiency pair must be confirmed from current evidence');

const unfinished = engine.compute({ currentAttempt: { id: 'unfinished', total: 7, score: 0, answers: [] } });
assert.strictEqual(unfinished.currentAttemptSummary.answered, 0, 'Unfinished practice must have no current evidence');
assert.strictEqual(unfinished.briefConclusion, 'historical_only', 'Unfinished practice must keep historical-only analysis');
assert(unfinished.whatCannotBeConcluded.some(item => item.id === 'no_current_check'), 'No-current-evidence limitation must be explicit');
assert(unfinished.historicalSummary.unverifiedTour4Errors.length > 0, 'Historical unverified errors must remain visible');

console.log('Gate 4 dynamic engine tests passed.');
