const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'
  }));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    const nativeSetInterval = window.setInterval.bind(window);
    const nativeClearInterval = window.clearInterval.bind(window);
    window.__epActiveIntervals = new Set();
    window.setInterval = (fn, ms, ...args) => {
      const id = nativeSetInterval(fn, ms, ...args);
      window.__epActiveIntervals.add(id);
      return id;
    };
    window.clearInterval = id => {
      window.__epActiveIntervals.delete(id);
      return nativeClearInterval(id);
    };

    localStorage.setItem('p240_legacy_sentinel', 'unchanged');
    window.__caps = {
      program_key: 'math_as_p1_p5', rollout_state: 'controlled_beta', core_access: true,
      ai_assist: false, mentor_care_entitled: false, mentor_assignment_active: false,
      mentor_authority: false, kill_switch: false
    };
    window.__profile = {
      exam_series: 'Oct/Nov 2026', target_grade: 'A', total_student_hours_available: 12,
      mathematics_hours_budget: 6, active_week_no: 1
    };
    window.__progress = {
      P1: { component_code: 'P1', placement_status: 'complete', route: 'foundation', profile_complete: true, content_ready: true, stage0_complete: true, screening: { required_items: 24, required_areas: 8, answered_items: 24, answered_areas: 8 }, active_session: null, max_unlocked_stage: 5, foundation_learning_access: true },
      P5: { component_code: 'P5', placement_status: 'screening_incomplete', route: 'pending_evidence', profile_complete: true, content_ready: true, stage0_complete: false, screening: { required_items: 15, required_areas: 5, answered_items: 0, answered_areas: 0 }, active_session: null, max_unlocked_stage: 0, foundation_learning_access: false }
    };
    window.__state = {
      P1: { engine_version: 'objective_state_v1', components: [{ component_code: 'P1', operational_stage: 5, coverage_pct: 100, levels: { L0: 0, L1: 0, L2: 0, L3: 45 } }], skills: [] },
      P5: { engine_version: 'objective_state_v1', components: [{ component_code: 'P5', operational_stage: 0, coverage_pct: 0, levels: { L0: 36, L1: 0, L2: 0, L3: 0 } }], skills: [] }
    };
    window.__session = null;
    window.__calls = [];
    window.sb = { rpc: async (name, args = {}) => {
      window.__calls.push({ name, args });
      if (name === 'get_exam_prep_capabilities_v1') return { data: [window.__caps], error: null };
      if (name === 'get_my_exam_prep_beta_invitation_v1') return { data: { invited: false, invitations: [] }, error: null };
      if (name === 'get_exam_prep_exam_profile_v1') return { data: [window.__profile], error: null };
      if (name === 'get_exam_prep_diagnostic_progress_safe_v1') return { data: window.__progress[args.p_component_code], error: null };
      if (name === 'get_exam_prep_state_safe_v1') return { data: window.__state[args.p_component_code], error: null };
      if (name === 'get_exam_prep_timed_catalog_safe_v1') return { data: { component_code: 'P1', assessments: [{ assessment_id: 501, title_en: 'Full paper practice', assessment_type: 'paper', attempt_kind: 'full_paper', marks_available: 4, time_limit_sec: 120, strict_timing: true, current_operational_stage: 5, min_operational_stage: 5 }] }, error: null };
      if (name === 'authorize_exam_prep_timed_safe_v1') return { data: { authorization_id: '00000000-0000-4000-8000-000000009900', assessment_id: 501, component_code: 'P1', purpose: 'paper', attempt_kind: 'full_paper', marks_available: 4, time_limit_sec: 120 }, error: null };
      if (name === 'start_exam_prep_session_safe_v1') {
        window.__session = {
          session_id: '00000000-0000-4000-8000-000000009901', status: 'active', component_code: 'P1', session_type: 'paper', total_items: 1,
          timing_contract: { deadline_at: new Date(Date.now() + 120000).toISOString(), time_limit_sec: 120, marks_available: 4, attempt_kind: 'full_paper' },
          items: [{ item_order: 1, item_kind: 'written', primary_skill_code: 'P1-QUA-01', answered: false, written_prompt: 'Solve x + 2 = 6.', written_max_marks: 4 }]
        };
        return { data: { session_id: window.__session.session_id, status: 'active' }, error: null };
      }
      if (name === 'get_exam_prep_session_safe_v1') return { data: window.__session, error: null };
      return { data: null, error: { message: `unexpected rpc ${name}` } };
    }};
  });

  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-api.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-host.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-live.js') });

  const assert = (condition, message) => { if (!condition) throw new Error(message); };

  await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
  });
  await page.waitForSelector('[data-ep-live-timed="P1"]');
  await page.click('[data-ep-live-timed="P1"]');
  await page.waitForSelector('[data-ep-live-timed-start="501"]');
  await page.click('[data-ep-live-timed-start="501"]');
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent.includes('Time left'));

  let result = await page.evaluate(() => ({
    intervals: window.__epActiveIntervals.size,
    open: window.iClubExamPrep.isOpen(),
    text: document.querySelector('#exam-prep-host-root').textContent
  }));
  assert(result.open === true && result.intervals === 1, 'active timed attempt must own exactly one live countdown interval');
  assert(result.text.includes('Time left'), 'timed attempt must be visible before teardown');

  result = await page.evaluate(() => {
    const closed = window.iClubExamPrep.close();
    return {
      closed,
      intervals: window.__epActiveIntervals.size,
      open: window.iClubExamPrep.isOpen(),
      hidden: document.querySelector('#exam-prep-host-root').hidden,
      html: document.querySelector('#exam-prep-host-root').innerHTML,
      sentinel: localStorage.getItem('p240_legacy_sentinel')
    };
  });
  assert(result.closed === true, 'host close must succeed');
  assert(result.intervals === 0, 'closing Exam Prep must synchronously clear the active countdown interval');
  assert(result.open === false && result.hidden === true && result.html === '', 'closing Exam Prep must unmount the transient live root');
  assert(result.sentinel === 'unchanged', 'Exam Prep teardown must not touch legacy/local persistence');

  await page.waitForTimeout(1250);
  result = await page.evaluate(() => ({
    intervals: window.__epActiveIntervals.size,
    open: window.iClubExamPrep.isOpen(),
    hidden: document.querySelector('#exam-prep-host-root').hidden,
    html: document.querySelector('#exam-prep-host-root').innerHTML,
    sentinel: localStorage.getItem('p240_legacy_sentinel')
  }));
  assert(result.intervals === 0, 'countdown interval must stay stopped after unmount');
  assert(result.open === false && result.hidden === true && result.html === '', 'stale timer callback must not remount or mutate a closed Exam Prep root');
  assert(result.sentinel === 'unchanged', 'post-close timer wait must not mutate legacy/local persistence');

  await browser.close();
  console.log('P2-40 host lifecycle/timer teardown: PASS');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
