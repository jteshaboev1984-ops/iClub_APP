'use strict';
// Genuine native Exam Prep UI in an isolated Chromium page. All RPCs are synthetic;
// network is blocked, and no production DB/user or localStorage is accessed.
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');
const file = name => path.resolve(name);
const PLAN = '11111111-1111-4111-8111-111111111111';
const NEW_PLAN = '22222222-2222-4222-8222-222222222222';
const GOAL_ONE = '33333333-3333-4333-8333-333333333333';
const GOAL_TWO = '44444444-4444-4444-8444-444444444444';
const AUTH = '55555555-5555-4555-8555-555555555555';
const SESSION = '66666666-6666-4666-8666-666666666666';
const html = language => `<!doctype html><html lang="${language}"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>`;

async function scenario(browser, language, width) {
  const page = await browser.newPage({ viewport: { width, height: 840 } });
  const errors = [];
  page.on('pageerror', err => errors.push(err.message));
  await page.route(/^https?:\/\//, route => route.abort());
  try {
    await page.setContent(html(language));
    for (const css of ['exam-prep/exam-prep-host.css', 'exam-prep/exam-prep-progress-ux.css'])
      await page.addStyleTag({ path: file(css) });
    await page.evaluate(([lang, planId, newer, goalOne, goalTwo, authId, sessionId]) => {
      window.iClubExamPrepWeeklyFlowEnabled = true;
      window.iClubExamPrepProgressUxEnabled = true;
      window.i18n = { getLang: () => lang };
      const state = window.__test = {
        planId, planOriginal: planId, newPlan: newer, goalOne, goalTwo, authId, sessionId,
        active: false, answered: false, finalized: false, throwAfterStart: false,
        calls: [], authorizationIds: [], sessionStarts: 0, generated: 0, p5Count: 2
      };
      const ok = data => ({ data: structuredClone(data), error: null });
      const reject = message => ({ data: null, error: { message } });
      const progress = comp => ({
        contract_version: 'progress_ux_v1', component_code: comp,
        active_week_no: 1, plan_available: true,
        finalized_study_sessions: comp === 'P1' && state.finalized ? 1 : comp === 'P5' ? state.p5Count : 0,
        open_corrections: 0, confirmed_skills: 0, coverage_pct: 0,
        completed_goals: comp === 'P1' && state.finalized ? 1 : 0,
        goals: comp === 'P1' ? [
          { goal_id: goalOne, component_code: 'P1', priority_order: 1,
            item_type: 'learning', skill_code: 'P1-CIR-01', status: state.finalized ? 'completed':'not_started',
            weekly_commitment_complete: state.finalized, correction_open: false,
            finalized_sessions: state.finalized ? 1 : 0,
            action_priority_order: state.finalized ? null : 2,
            retest_due_at: null, plan_changed: false },
          { goal_id: goalTwo, component_code: 'P1', priority_order: 2,
            item_type: 'learning', skill_code: 'P1-COO-02', status: 'not_started',
            weekly_commitment_complete: false, correction_open: false, finalized_sessions: 0,
            action_priority_order: 1, retest_due_at: null, plan_changed: false }
        ] : [{ goal_id: goalTwo, component_code: 'P5', priority_order: 1,
          status: 'not_started', weekly_commitment_complete: false, correction_open: false,
          finalized_sessions: 0, action_priority_order: 1, retest_due_at: null }]
      });
      const plan = comp => ({ plan_id: state.planId, active_week_no: 1, items: comp === 'P1' ? [
        { priority_order: 1, item_type: 'learning', skill_code: 'P1-COO-02', status: 'pending' },
        { priority_order: 2, item_type: 'learning', skill_code: 'P1-CIR-01', status: state.finalized ? 'completed' : 'pending' }
      ] : [{ priority_order: 1, item_type: 'learning', skill_code: 'P5-DAT-01', status: 'pending' }] });
      window.iClubExamPrepHostInternal = { lastCapabilities: {
        coreAccess: true, killSwitch: false, rolloutState: 'controlled_beta'
      }};
      window.iClubExamPrep = { open: async () => true, isOpen: () => true,
        back: () => true, close: () => true, syncSubjectHub: async () => true,
        refreshCapabilities: async () => true };
      window.sb = { rpc: async (name, args = {}) => {
        state.calls.push({ name, args });
        const comp = args.p_component_code;
        switch(name) {
          case 'get_exam_prep_exam_profile_v1': return ok({ exam_series: 'May/June 2027',
            target_grade: 'A', total_student_hours_available: 10, mathematics_hours_budget: 5 });
          case 'get_exam_prep_diagnostic_progress_safe_v1': return ok({ stage0_complete: true,
            screening: { required_items: 2, answered_items: 2, required_areas: 1, answered_areas: 1 } });
          case 'get_exam_prep_state_safe_v1': return ok({ components: [
            { component_code: comp, operational_stage: 2, coverage_pct: 0 }] });
          case 'get_exam_prep_active_plan_session_safe_v1': return ok(state.active ? {
            status: 'resume', component_code: comp, session_id: sessionId, first_unanswered_item_order: 1
          } : { status: 'none', component_code: comp });
          case 'ensure_exam_prep_stable_weekly_plan_safe_v1': return ok({
            contract_version: 'stable_weekly_plan_v1', status: 'existing',
            plan_id: state.planId, component_code: comp, created: false });
          case 'get_exam_prep_weekly_plan_safe_v2': return ok(plan(comp));
          case 'ensure_exam_prep_weekly_goals_safe_v1': return ok({ contract_version: 'progress_ux_v1',
            component_code: comp, active_week_no: 1, plan_available: true, created: 0 });
          case 'get_exam_prep_weekly_progress_safe_v1': return ok(progress(comp));
          case 'authorize_exam_prep_goal_once_safe_v1': {
            state.authorizationIds.push({ goal: args.p_goal_id, plan: args.p_plan_id });
            if (args.p_goal_id !== goalOne || args.p_plan_id !== state.planId || state.finalized)
              return ok({ status: 'stale', reason: 'goal_or_plan_changed' });
            return ok({ status: 'authorized', authorization_id: authId, component_code: comp });
          }
          case 'start_exam_prep_plan_session_once_safe_v1':
            if (args.p_authorization_id !== authId) return reject('invalid authorization');
            state.sessionStarts++;
            state.active = true;
            if (state.throwAfterStart) {
              state.throwAfterStart = false;
              throw Error('Lost connection after server commit');
            }
            return ok({ status: 'started', component_code: 'P1', session_id: sessionId });
          case 'get_exam_prep_session_safe_v1':
            if (args.p_session_id !== sessionId) return reject('wrong session');
            return ok({ session_id: sessionId, component_code: 'P1', session_type: 'learning',
              status: state.finalized ? 'finalized' : 'active', items: [{ item_order: 1,
              item_kind: 'objective', qtype: 'mcq', text: 'Convert 90° to radians.',
              options: ['π / 2', 'π'], answered: state.answered }] });
          case 'submit_exam_prep_response_safe_v1':
            if (args.p_session_id !== sessionId || args.p_item_order !== 1 ||
                args.p_payload?.picked_index !== 0) return reject('wrong response');
            state.answered = true;
            return ok({ is_correct: true });
          case 'finalize_exam_prep_session_safe_v1':
            if (!state.answered || args.p_session_id !== sessionId) return reject('incomplete');
            state.finalized = true; state.active = false;
            return ok({ status: 'finalized' });
          case 'generate_exam_prep_weekly_plan_safe_v3':
            state.generated++; return reject('OLD GENERATOR MUST NEVER BE CALLED');
          case 'authorize_exam_prep_plan_item_safe_v1':
            return reject('OLD AUTHORIZE MUST NEVER BE CALLED');
          case 'start_exam_prep_session_safe_v1':
            return reject('OLD SESSION START MUST NEVER BE CALLED');
          default: return reject(`unexpected RPC ${name}`);
        }
      }};
    }, [language, PLAN, NEW_PLAN, GOAL_ONE, GOAL_TWO, AUTH, SESSION]);
    for (const js of ['exam-prep/exam-prep-api.js',
      'exam-prep/exam-prep-weekly-flow-adapter.js',
      'exam-prep/exam-prep-live.js',
      'exam-prep/exam-prep-progress-ux-api.js']) await page.addScriptTag({ path: file(js) });
    await page.evaluate(lang => window.iClubExamPrep.open({ language: lang }), language);
    await page.waitForSelector('[data-ep-live-plan="P1"]', { state: 'attached' });
    await page.evaluate(() => document.querySelector('[data-ep-live-plan="P1"]').click());
    await page.waitForSelector('[data-ep-live-plan-item="2"]');
    assert.equal(await page.locator('[data-ep-live-plan-item]').count(), 2);
    // Frozen first goal is current SECOND action. Never use its frozen ordinal.
    await page.click('[data-ep-live-plan-item="2"]');
    await page.waitForSelector('.ep-live-qtext');
    assert.equal(await page.locator('.ep-live-qtext').innerText(), 'Convert 90° to radians.');
    await page.check('input[name="ep_live_answer"][value="0"]');
    await page.click('[data-ep-live-submit]');
    await page.waitForFunction(() => window.__test.finalized === true);
    await page.waitForSelector('.ep-live-card [data-ep-live-dashboard]');
    let state = await page.evaluate(() => window.__test);
    assert.deepEqual(state.authorizationIds, [{ goal: GOAL_ONE, plan: PLAN }],
      `${language}/${width}: frozen goal must bind to real action`);
    assert.equal(state.planId, PLAN, `${language}/${width}: plan changed`);
    assert.equal(state.generated, 0, `${language}/${width}: legacy generator called`);
    assert.equal(state.sessionStarts, 1, `${language}/${width}: repeated start`);
    assert.equal(state.p5Count, 2, `${language}/${width}: P5 affected`);
    assert.equal(state.calls.filter(x => x.name === 'finalize_exam_prep_session_safe_v1').length, 1);
    assert.equal(state.calls.filter(x => x.name === 'authorize_exam_prep_plan_item_safe_v1').length, 0);
    assert.equal(state.calls.filter(x => x.name === 'start_exam_prep_session_safe_v1').length, 0);
    // Reopening still does not generate or replace the weekly plan.
    await page.click('[data-ep-live-dashboard]');
    await page.evaluate(() => document.querySelector('[data-ep-live-plan="P1"]').click());
    await page.waitForSelector('[data-ep-live-plan-item="1"]');
    state = await page.evaluate(() => window.__test);
    assert.equal(state.planId, PLAN);
    assert.equal(state.generated, 0);
    // After a read-only plan swap, a stale click cannot start a session.
    await page.evaluate(newId => { window.__test.planId = newId; }, NEW_PLAN);
    await page.click('[data-ep-live-plan-item="1"]');
    await page.waitForSelector('.ep-live-error');
    state = await page.evaluate(() => window.__test);
    assert.equal(state.sessionStarts, 1);
    // Restore plan, simulate cold return into an existing ACTIVE session.
    await page.evaluate(original => {
      const s = window.__test;
      s.planId = original; s.active = true; s.finalized = false; s.answered = false;
    }, PLAN);
    await page.click('[data-ep-live-home]');
    await page.evaluate(() => document.querySelector('[data-ep-live-plan="P1"]').click());
    await page.waitForSelector('.ep-live-qtext');
    state = await page.evaluate(() => window.__test);
    assert.equal(state.sessionStarts, 1, `${language}/${width}: resume created another session`);
    assert.equal(state.generated, 0);
    assert.deepEqual(errors, [], `${language}/${width}: page exceptions`);
    console.log(`PASS guarded native browser journey: ${language} ${width}px, goal order, submit, stable plan, stale click and cold resume`);
  } finally { await page.close(); }
}
(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    for (const language of ['ru', 'uz', 'en']) for (const width of [390, 1280])
      await scenario(browser, language, width);
    console.log('GREEN: six genuine native UI journeys with synthetic RPCs; production network blocked.');
  } finally { await browser.close(); }
})().catch(e => { console.error(e); process.exitCode = 1; });
