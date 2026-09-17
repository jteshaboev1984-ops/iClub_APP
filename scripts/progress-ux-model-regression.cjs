'use strict';
const assert = require('node:assert/strict');
const model = require('../exam-prep/exam-prep-progress-ux-model.js');
const base = () => ({
  contract_version: 'progress_ux_v1', component_code: 'P1', active_week_no: 1,
  plan_available: true, completed_goals: 1, finalized_study_sessions: 5,
  open_corrections: 3, confirmed_skills: 0, coverage_pct: 0,
  goals: [
    { goal_id: 'stable-circles', component_code: 'P1', priority_order: 1,
      status: 'weekly_work_done', weekly_commitment_complete: true,
      correction_open: true, finalized_sessions: 5, action_priority_order: 1, retest_due_at: null },
    { goal_id: 'stable-coordinate', component_code: 'P1', priority_order: 2,
      status: 'not_started', weekly_commitment_complete: false,
      correction_open: true, finalized_sessions: 0, action_priority_order: 2, retest_due_at: null },
    { goal_id: 'stable-trig', component_code: 'P1', priority_order: 3,
      status: 'not_started', weekly_commitment_complete: false,
      correction_open: true, finalized_sessions: 0, action_priority_order: 3, retest_due_at: null }
  ]
});
function check(fixture, component = 'P1', language = 'ru') { return model.normalize(fixture, component, language); }
const first = check(base());
assert.equal(first.ok, true);
assert.equal(first.goalCounter, '1 из 3');
assert.equal(first.finalizedSessions, 5);
assert.equal(first.confirmedSkills, 0, 'sessions must never grant skill mastery');
assert.equal(first.goals[0].correctionOpen, true, 'weekly work never closes a correction');
assert.match(first.goals[0].correctionNote, /остаётся открытой/);
for (const lang of ['ru', 'uz', 'en']) {
  const result = check(base(), 'P1', lang);
  assert.ok(result.goals.every(goal => goal.statusLabel && !/\bL[0-5]\b/.test(goal.statusLabel)));
}
assert.equal(check(base(), 'P1', 'en').goalCounter, '1 of 3');
assert.equal(check(base(), 'P1', 'uz').goalCounter, '3 tadan 1 tasi');
const repeat = base();
repeat.finalized_study_sessions = 8;
repeat.goals[0].finalized_sessions = 8;
assert.equal(check(repeat).goalCounter, '1 из 3', 'new sessions must not reset weekly goals');
const complete = base();
complete.goals[1].weekly_commitment_complete = true;
complete.goals[1].status = 'completed';
complete.completed_goals = 2;
assert.equal(check(complete).goalCounter, '2 из 3');
const badCross = base();
badCross.goals[0].component_code = 'P5';
assert.equal(check(badCross).reason, 'invalid_goal');
assert.equal(check(base(), 'P5').reason, 'component_mismatch');
const duplicate = base();
duplicate.goals[2].goal_id = 'stable-circles';
assert.equal(check(duplicate).reason, 'invalid_goal');
const falseCount = base();
falseCount.completed_goals = 3;
assert.equal(check(falseCount).reason, 'completion_mismatch');
const noPlan = base();
noPlan.goals = [];
noPlan.completed_goals = 0;
noPlan.plan_available = false;
assert.equal(check(noPlan).goalCounter, null, 'no plan must not be shown as zero of three');
const changed = base();
changed.goals[1].status = 'replaced';
changed.goals[1].action_priority_order = null;
assert.equal(check(changed).totalGoals, 3, 'a replaced action cannot change frozen weekly denominator');
const newWeek = base();
newWeek.active_week_no = 2;
newWeek.goals = [{ ...newWeek.goals[2], goal_id: 'new-week-trig', priority_order: 1, action_priority_order: 1 }];
newWeek.completed_goals = 0;
assert.equal(check(newWeek).goalCounter, '0 из 1');
const badDate = base();
badDate.goals[0].retest_due_at = 'tomorrow-ish';
assert.equal(check(badDate).reason, 'bad_retest_date');
const badCoverage = base();
badCoverage.coverage_pct = 145;
assert.equal(check(badCoverage).reason, 'bad_coverage');
console.log('Progress UX pure model: PASS (component firewall, frozen goals, counts, repeat, correction, replanning, rollover, 3 languages, invalid payload)');
