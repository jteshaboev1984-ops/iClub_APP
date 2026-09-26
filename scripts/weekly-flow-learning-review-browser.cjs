'use strict';
// Synthetic-only native learner UI acceptance. HTTP(S) is blocked; no Supabase credentials,
// production users, localStorage restoration, or database writes.
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');
const file = name => path.resolve(name);
const PLAN = '11111111-1111-4111-8111-111111111111';
const GOAL = '22222222-2222-4222-8222-222222222222';
const SESSION = '33333333-3333-4333-8333-333333333333';
const notes = {
  ru: 'Это учебное повторение, а не новая независимая проверка знаний.',
  uz: 'Bu o‘quv takrori, yangi mustaqil bilim tekshiruvi emas.',
  en: 'This is learning review, not a new independent knowledge check.'
};
async function scenario(browser, language, width) {
  const page = await browser.newPage({ viewport: { width, height: 850 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.route(/^https?:\/\//, route => route.abort());
  try {
    await page.setContent(`<!doctype html><html lang="${language}"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="exam-prep-host-root" aria-hidden="false"></div></body></html>`);
    await page.addStyleTag({ path: file('exam-prep/exam-prep-host.css') });
    await page.evaluate(([lang, planId, goalId, sessionId]) => {
      window.iClubExamPrepWeeklyFlowEnabled = true;
      window.i18n = { getLang: () => lang };
      const s = window.__reviewTest = {
        planId, goalId, sessionId, active: false, finalized: false,
        answered: [false, false, false, false], reviewStarts: 0, regularStarts: 0,
        oldPlanGenerators: 0, submitCalls: 0, finalizes: 0, notes: [],
        authorizationCalls: 0, componentWrites: [], academicCredit: 0
      };
      const ok = data => ({ ok: true, data });
      window.iClubExamPrepHostInternal = {
        lastCapabilities: { coreAccess: true, killSwitch: false, rolloutState: 'controlled_beta' },
        progressUxApi: { progress: async component => ok({ goals: component === 'P5' ? [{
          goal_id: goalId, component_code: 'P5', action_priority_order: 1,
          item_type: 'learning', status: 'not_started'
        }] : [] }) },
        api: {
          examProfile: async () => ok({ exam_series: 'May/June 2027', target_grade: 'A',
            total_student_hours_available: 10, mathematics_hours_budget: 5 }),
          diagnosticProgress: async () => ok({ stage0_complete: true,
            screening: { required_items: 3, answered_items: 3, required_areas: 1, answered_areas: 1 } }),
          getState: async component => ok({ components: [{ component_code: component,
            operational_stage: 2, coverage_pct: 0 }] }),
          weeklyPlan: async component => component === 'P5' ? ok({ plan_id: planId,
            active_week_no: 1, items: [{ priority_order: 1, item_type: 'learning',
              status: s.finalized ? 'completed' : 'pending' }] }) : ok({
                plan_id: planId, active_week_no: 1, items: [] }),
          getSession: async (id) => {
            if (id !== sessionId) return { ok: false };
            const texts = ['Original question 1', 'Original question 2', 'Original question 3', 'Original written solution'];
            return ok({ session_id: sessionId, component_code: 'P5', session_type: 'learning',
              status: s.finalized ? 'finalized' : 'active', items: texts.map((text, i) => ({
                item_order: i + 1, item_kind: i === 3 ? 'written' : 'objective',
                qtype: i === 3 ? 'written' : 'mcq', text,
                options: i === 3 ? undefined : ['Right', 'Wrong'], answered: s.answered[i]
              })) });
          },
          submitResponse: async (id, order, answer) => {
            s.submitCalls++;
            if (id !== sessionId || !Number.isInteger(order) || order < 1 || order > 4 ||
                s.answered[order - 1] || (order < 4 && answer?.picked_index !== 0) ||
                (order === 4 && answer?.artifact?.text !== 'Original written working')) return { ok: false };
            s.answered[order - 1] = true;
            return ok({ is_correct: order < 4, next_action: 'Continue learning' });
          },
          finalizeSession: async id => {
            if (id !== sessionId || s.answered.some(v => !v) || s.finalized) return { ok: false };
            s.finalizes++; s.finalized = true; s.active = false;
            return ok({ status: 'finalized' });
          },
          generateWeeklyPlan: async () => { s.oldPlanGenerators++; return { ok: false }; },
          authorizePlanItem: async () => { s.regularStarts++; return { ok: false }; },
          startSession: async () => { s.regularStarts++; return { ok: false }; }
        }
      };
      window.iClubExamPrep = {
        open: async () => true, isOpen: () => true, back: () => true, close: () => true,
        syncSubjectHub: async () => true, refreshCapabilities: async () => true
      };
      window.sb = { rpc: async (name, args) => {
        const success = data => ({ data, error: null });
        const reject = () => ({ data: null, error: { message: 'unexpected synthetic RPC' } });
        const component = args?.p_component_code;
        if (name === 'get_exam_prep_active_plan_session_safe_v1') return success(s.active ? {
          status: 'resume', component_code: component, session_id: sessionId,
          learning_review: true, first_unanswered_item_order: s.answered.findIndex(v => !v) + 1
        } : { status: 'none', component_code: component });
        if (name === 'ensure_exam_prep_balanced_weekly_plan_safe_v1') return success({
          contract_version: 'stable_weekly_plan_v1', status: 'existing', component_code: component,
          plan_id: planId, created: false
        });
        if (name === 'authorize_exam_prep_goal_once_safe_v1') {
          s.authorizationCalls++;
          if (component !== 'P5' || args.p_goal_id !== goalId || args.p_plan_id !== planId) return reject();
          return success({ status: 'review_ready', reason: 'same_pack_learning_review',
            component_code: 'P5', goal_id: goalId, plan_id: planId, priority_order: 1,
            item_type: 'learning', fresh_assessment: false });
        }
        if (name === 'start_exam_prep_learning_review_safe_v1') {
          if (component !== 'P5' || args.p_goal_id !== goalId || args.p_plan_id !== planId ||
              s.active || s.finalized) return reject();
          s.reviewStarts++; s.active = true;
          return success({ status: 'started', session_id: sessionId, component_code: 'P5',
            goal_id: goalId, plan_id: planId, repeat_learning: true, academic_credit: false,
            prior_progress_retained: true, not_a_new_independent_check: true });
        }
        s.regularStarts++;
        return reject();
      }};
    }, [language, PLAN, GOAL, SESSION]);
    for (const script of ['exam-prep/exam-prep-weekly-flow-adapter.js',
      'exam-prep/exam-prep-weekly-review-ui.js', 'exam-prep/exam-prep-live.js']) {
      await page.addScriptTag({ path: file(script) });
    }
    await page.evaluate(lang => window.iClubExamPrep.open({ language: lang }), language);
    await page.waitForSelector('[data-ep-live-plan="P5"]', { state: 'attached' });
    await page.evaluate(() => document.querySelector('[data-ep-live-plan="P5"]').click());
    await page.waitForSelector('[data-ep-live-plan-item="1"]');
    await page.click('[data-ep-live-plan-item="1"]');
    await page.waitForSelector('.ep-live-qtext');
    for (let i = 0; i < 4; i++) {
      await page.waitForFunction(text => document.querySelector('.ep-live-qtext')?.textContent === text,
        `Original ${i === 3 ? 'written solution' : 'question ' + (i + 1)}`);
      await page.waitForSelector('[data-ep-learning-review-note]');
      assert.ok((await page.locator('[data-ep-learning-review-note]').innerText()).includes(notes[language]),
        `${language}/${width} missing honest learning-review note for item ${i + 1}`);
      if (i === 3) await page.fill('textarea[name="ep_live_written_answer"]', 'Original written working');
      else await page.check('input[name="ep_live_answer"][value="0"]');
      await page.click('[data-ep-live-submit]');
    }
    await page.waitForFunction(() => window.__reviewTest.finalized === true);
    await page.waitForSelector('[data-ep-live-dashboard]');
    const s = await page.evaluate(() => window.__reviewTest);
    assert.equal(s.reviewStarts, 1, 'One noncredit review starter only');
    assert.equal(s.submitCalls, 4, 'Three objective and saved written responses');
    assert.equal(s.finalizes, 1, 'One finalization only');
    assert.equal(s.regularStarts, 0, 'Never call original fresh session start');
    assert.equal(s.oldPlanGenerators, 0, 'Never replace saved weekly plan');
    assert.equal(s.planId, PLAN);
    assert.equal(s.academicCredit, 0, 'Mock academic credit not increased by review');
    assert.deepEqual(errors, [], 'Browser JS errors');
    console.log(`PASS ${language}/${width}: original pack, transparent noncredit review, written saved, plan stable`);
  } finally { await page.close(); }
}
(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    for (const language of ['ru','uz','en']) for (const width of [390,1280]) {
      await scenario(browser, language, width);
    }
    console.log('GREEN: six isolated native review browser journeys; production network blocked.');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });