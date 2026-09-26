'use strict';
const assert = require('node:assert/strict');
const path = require('path');
const { chromium } = require('playwright');

const file = p => path.resolve(p);
const PLAN = '11111111-1111-4111-8111-111111111111';
const GOAL_DONE = '22222222-2222-4222-8222-222222222222';
const GOAL_NEXT = '33333333-3333-4333-8333-333333333333';
const AUTH = '44444444-4444-4444-8444-444444444444';
const SESSION = '55555555-5555-4555-8555-555555555555';

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  await page.route(/^https?:\/\//, route => route.abort());

  try {
    await page.setContent('<!doctype html><html lang="ru"><body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>');
    await page.evaluate(([planId, doneGoal, nextGoal, authId, sessionId]) => {
      window.iClubExamPrepWeeklyFlowEnabled = true;
      window.iClubExamPrepProgressUxEnabled = true;
      window.i18n = { getLang: () => 'ru' };
      const state = window.__cta = {
        planId, doneGoal, nextGoal, authId, sessionId,
        authorizeGoals: [], sessionStarts: 0, active: false, calls: []
      };
      const ok = data => ({ data: structuredClone(data), error: null });
      const reject = message => ({ data: null, error: { message } });

      const weeklyPlan = {
        plan_id: planId,
        component_code: 'P1',
        active_week_no: 1,
        items: [
          { priority_order: 1, item_type: 'learning', skill_code: 'P1-FUN-01', status: 'pending', due_at: null },
          { priority_order: 2, item_type: 'learning', skill_code: 'P1-FUN-02', status: 'pending', due_at: null }
        ]
      };
      const weeklyProgress = {
        contract_version: 'progress_ux_v1',
        component_code: 'P1',
        active_week_no: 1,
        plan_available: true,
        completed_goals: 1,
        finalized_study_sessions: 1,
        open_corrections: 0,
        confirmed_skills: 1,
        coverage_pct: 2.22,
        goals: [
          {
            goal_id: doneGoal, component_code: 'P1', priority_order: 1,
            item_type: 'learning', skill_code: 'P1-FUN-01', status: 'completed',
            weekly_commitment_complete: true, correction_open: false,
            finalized_sessions: 1, action_priority_order: 1,
            retest_due_at: null, plan_changed: false
          },
          {
            goal_id: nextGoal, component_code: 'P1', priority_order: 2,
            item_type: 'learning', skill_code: 'P1-FUN-02', status: 'not_started',
            weekly_commitment_complete: false, correction_open: false,
            finalized_sessions: 0, action_priority_order: 2,
            retest_due_at: null, plan_changed: false
          }
        ]
      };

      window.iClubExamPrepHostInternal = {
        lastCapabilities: { coreAccess: true, killSwitch: false, rolloutState: 'controlled_beta' }
      };
      window.iClubExamPrep = {
        open: async () => true, isOpen: () => true, back: () => true, close: () => true,
        syncSubjectHub: async () => true, refreshCapabilities: async () => true
      };
      window.sb = { rpc: async (name, args = {}) => {
        state.calls.push({ name, args });
        const component = args.p_component_code;
        switch (name) {
          case 'get_exam_prep_exam_profile_v1':
            return ok({ exam_series: 'May/June 2027', target_grade: 'A',
              total_student_hours_available: 10, mathematics_hours_budget: 5 });
          case 'get_exam_prep_diagnostic_progress_safe_v1':
            return ok({ component_code: component, stage0_complete: true,
              screening: { required_items: 2, answered_items: 2, required_areas: 1, answered_areas: 1 },
              active_session: null });
          case 'get_exam_prep_state_safe_v1':
            return ok({ components: [{ component_code: component, operational_stage: 2, coverage_pct: component === 'P1' ? 2.22 : 0 }], skills: [] });
          case 'get_exam_prep_syllabus_tracker_safe_v1':
            return ok({ component_code: component, denominator_count: component === 'P1' ? 45 : 36,
              coverage_count: component === 'P1' ? 1 : 0, coverage_pct: component === 'P1' ? 2.22 : 0, areas: [] });
          case 'get_exam_prep_correction_queue_safe_v1':
            return ok({ component_code: component, active_count: 0, cases: [] });
          case 'get_exam_prep_weekly_plan_safe_v2':
            return ok(component === 'P1' ? weeklyPlan : { plan_id: null, component_code: 'P5', active_week_no: 1, items: [] });
          case 'ensure_exam_prep_weekly_goals_safe_v1':
            return ok({ contract_version: 'progress_ux_v1', component_code: component, active_week_no: 1,
              plan_available: component === 'P1', created: 0 });
          case 'get_exam_prep_weekly_progress_safe_v1':
            return ok(component === 'P1' ? weeklyProgress : {
              contract_version: 'progress_ux_v1', component_code: 'P5', active_week_no: 1,
              plan_available: false, completed_goals: 0, finalized_study_sessions: 0,
              open_corrections: 0, confirmed_skills: 0, coverage_pct: 0, goals: []
            });
          case 'get_exam_prep_active_plan_session_safe_v1':
            return ok(state.active
              ? { status: 'resume', component_code: component, session_id: sessionId, first_unanswered_item_order: 1 }
              : { status: 'none', component_code: component });
          case 'ensure_exam_prep_balanced_weekly_plan_safe_v1':
            return ok({ contract_version: 'stable_weekly_plan_v1', status: 'existing',
              plan_id: planId, component_code: component, created: false });
          case 'authorize_exam_prep_goal_once_safe_v1':
            state.authorizeGoals.push(args.p_goal_id);
            if (args.p_goal_id === doneGoal) return ok({ status: 'waiting', reason: 'attempt_already_saved' });
            if (args.p_goal_id !== nextGoal || args.p_plan_id !== planId) return ok({ status: 'stale', reason: 'goal_or_plan_changed' });
            return ok({ status: 'authorized', authorization_id: authId, component_code: 'P1' });
          case 'start_exam_prep_plan_session_once_safe_v1':
            if (args.p_authorization_id !== authId) return reject('wrong authorization');
            state.sessionStarts += 1;
            state.active = true;
            return ok({ status: state.sessionStarts === 1 ? 'started' : 'resume', component_code: 'P1', session_id: sessionId });
          case 'get_exam_prep_session_safe_v1':
            return ok({ session_id: sessionId, component_code: 'P1', session_type: 'learning', status: 'active',
              items: [{ item_order: 1, item_kind: 'objective', qtype: 'mcq',
                text: 'Second weekly goal question', options: ['A','B'], answered: false }] });
          default:
            return reject('unexpected RPC ' + name);
        }
      }};
    }, [PLAN, GOAL_DONE, GOAL_NEXT, AUTH, SESSION]);

    for (const js of [
      'exam-prep/exam-prep-api.js',
      'exam-prep/exam-prep-weekly-flow-adapter.js',
      'exam-prep/exam-prep-live.js',
      'exam-prep/exam-prep-progress-ux-api.js'
    ]) await page.addScriptTag({ path: file(js) });

    await page.evaluate(() => window.iClubExamPrep.open({ language: 'ru' }));
    await page.waitForSelector('[data-ep-live-open-component="P1"]');
    await page.click('[data-ep-live-open-component="P1"]');
    await page.waitForSelector('[data-ep-component-home="P1"]');

    const label = await page.locator('[data-ep-component-primary="task"]').innerText();
    assert.equal(label, 'Начать задание');

    await page.evaluate(() => {
      const button = document.querySelector('[data-ep-component-primary="task"]');
      button.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      button.dispatchEvent(new MouseEvent('click', { bubbles: true }));
    });

    await page.waitForSelector('.ep-live-qtext');
    assert.equal(await page.locator('.ep-live-qtext').innerText(), 'Second weekly goal question');

    const state = await page.evaluate(() => window.__cta);
    assert.deepEqual(state.authorizeGoals, [GOAL_NEXT], 'completed goal must never be re-authorized by component CTA');
    assert.equal(state.sessionStarts, 1, 'double click must start exactly one session');
    assert.equal(state.active, true);
    assert.equal(state.calls.filter(x => x.name === 'start_exam_prep_plan_session_once_safe_v1').length, 1);
    assert.equal(state.calls.filter(x => x.name === 'authorize_exam_prep_goal_once_safe_v1').length, 1);
    assert.deepEqual(errors, []);

    console.log('PASS component-first CTA: stale pending item skipped, next weekly goal starts once under double click');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
