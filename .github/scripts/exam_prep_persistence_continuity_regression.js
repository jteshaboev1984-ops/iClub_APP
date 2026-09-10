const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });

  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html lang="en"><head></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-badge"></span><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span><span id="subject-hub-exam-prep-p1"></span><span id="subject-hub-exam-prep-p5"></span><span id="subject-hub-exam-prep-note"></span><span id="subject-hub-exam-prep-cta"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'
  }));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    window.i18n = { getLang: () => 'en' };
    window.__calls = [];
    window.__saves = 0;
    window.__profile = {
      exam_series: null,
      target_grade: null,
      total_student_hours_available: 12,
      mathematics_hours_budget: 6,
      active_week_no: 1
    };
    window.__progress = {
      P1: {
        component_code: 'P1', placement_status: 'screening_incomplete', route: 'pending_evidence',
        profile_complete: true, content_ready: true, stage0_complete: false,
        screening: { required_items: 24, required_areas: 8, answered_items: 5, answered_areas: 3, accuracy_pct: 40 },
        active_session: { session_id: '00000000-0000-4000-8000-000000001111', total_items: 2 },
        max_unlocked_stage: 0, foundation_learning_access: false
      },
      P5: {
        component_code: 'P5', placement_status: 'screening_incomplete', route: 'pending_evidence',
        profile_complete: true, content_ready: true, stage0_complete: false,
        screening: { required_items: 15, required_areas: 5, answered_items: 6, answered_areas: 2, accuracy_pct: 50 },
        active_session: null,
        max_unlocked_stage: 0, foundation_learning_access: false
      }
    };
    window.__state = {
      P1: { components: [{ component_code: 'P1', operational_stage: 0, coverage_pct: 0, levels: { L0: 45, L1: 0, L2: 0, L3: 0 } }], skills: [] },
      P5: { components: [{ component_code: 'P5', operational_stage: 0, coverage_pct: 0, levels: { L0: 36, L1: 0, L2: 0, L3: 0 } }], skills: [] }
    };
    window.__session = {
      session_id: '00000000-0000-4000-8000-000000001111',
      status: 'active',
      component_code: 'P1',
      session_type: 'diagnostic',
      total_items: 2,
      items: [
        { item_order: 1, item_kind: 'question', answered: true, qtype: 'mcq', text: 'Saved first question', options: ['A', 'B'] },
        { item_order: 2, item_kind: 'question', answered: false, qtype: 'mcq', text: 'Second question after reopening', options: ['A', 'B'] }
      ]
    };
    window.__caps = {
      program_key: 'math_as_p1_p5', rollout_state: 'controlled_beta', core_access: true,
      ai_assist: false, mentor_care_entitled: false, mentor_assignment_active: false,
      mentor_authority: false, kill_switch: false
    };

    window.sb = { rpc: async (name, args = {}) => {
      window.__calls.push({ name, args });
      if (name === 'get_exam_prep_capabilities_v1') return { data: [window.__caps], error: null };
      if (name === 'get_my_exam_prep_beta_invitation_v1') return { data: { invited: false, invitations: [] }, error: null };
      if (name === 'get_exam_prep_exam_profile_v1') return { data: [window.__profile], error: null };
      if (name === 'save_exam_prep_exam_profile_v2') {
        window.__saves += 1;
        window.__profile = {
          ...window.__profile,
          exam_series: args.p_exam_series,
          target_grade: args.p_target_grade,
          total_student_hours_available: args.p_total_student_hours_available,
          mathematics_hours_budget: args.p_mathematics_hours_budget
        };
        return { data: { ...window.__profile, progress_retained: true, plan_rebuild_required: false }, error: null };
      }
      if (name === 'get_exam_prep_diagnostic_progress_safe_v1') return { data: window.__progress[args.p_component_code], error: null };
      if (name === 'get_exam_prep_state_safe_v1') return { data: window.__state[args.p_component_code], error: null };
      if (name === 'start_exam_prep_next_diagnostic_safe_v1') {
        return { data: { session_id: window.__session.session_id, status: 'active', component_code: 'P1', session_type: 'diagnostic', total_items: 2, resumed: true }, error: null };
      }
      if (name === 'get_exam_prep_session_safe_v1') return { data: window.__session, error: null };
      return { data: null, error: { message: `unexpected rpc ${name}` } };
    }};
  });

  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-api.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-host.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-live.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-profile-completeness.js') });

  const assert = (condition, message) => { if (!condition) throw new Error(message); };

  await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
  });

  await page.waitForSelector('[data-ep-profile-completion]');
  await page.waitForSelector('[data-ep-live-component="P1"]');
  await page.waitForSelector('[data-ep-live-component="P5"]');

  let snapshot = await page.evaluate(() => ({
    text: document.querySelector('#exam-prep-host-root')?.textContent || '',
    cards: document.querySelectorAll('[data-ep-live-component]').length,
    total: document.querySelector('[data-ep-profile-completion-form] input[name="total_hours"]')?.value,
    math: document.querySelector('[data-ep-profile-completion-form] input[name="math_hours"]')?.value,
    p1Action: document.querySelector('[data-ep-live-start="P1"]')?.textContent?.trim(),
    p5Action: document.querySelector('[data-ep-live-start="P5"]')?.textContent?.trim()
  }));

  assert(snapshot.cards === 2, 'profile completion must not hide P1/P5 progress cards');
  assert(snapshot.text.includes('5 / 24'), 'saved P1 progress must remain visible');
  assert(snapshot.text.includes('6 / 15'), 'saved P5 progress must remain visible');
  assert(snapshot.total === '12' && snapshot.math === '6', 'saved workload settings must be prefilled');
  assert(snapshot.p1Action === 'Continue entry check', 'P1 saved work must use a continue action');
  assert(snapshot.p5Action === 'Continue entry check', 'P5 saved work must use a continue action');
  assert(snapshot.text.includes('Your answers and progress are saved'), 'repair copy must explicitly confirm saved work');

  await page.fill('[data-ep-profile-completion-form] input[name="exam_series"]', 'May/June 2027');
  await page.fill('[data-ep-profile-completion-form] input[name="target_grade"]', 'A');
  await page.click('[data-ep-profile-completion-form] button[type="submit"]');
  await page.waitForFunction(() => !document.querySelector('[data-ep-profile-completion]') && document.querySelector('[data-ep-live-component="P1"]'));

  snapshot = await page.evaluate(() => ({
    text: document.querySelector('#exam-prep-host-root')?.textContent || '',
    saves: window.__saves,
    p1Answered: window.__progress.P1.screening.answered_items,
    p5Answered: window.__progress.P5.screening.answered_items
  }));
  assert(snapshot.saves === 1, 'profile completion should save exactly once');
  assert(snapshot.p1Answered === 5 && snapshot.p5Answered === 6, 'profile completion must not mutate diagnostic progress');
  for (const token of ['May/June 2027', 'Target grade: A', 'Total: 12 h/week', 'Mathematics: 6 h/week', '5 / 24', '6 / 15']) {
    assert(snapshot.text.includes(token), `saved dashboard continuity missing: ${token}`);
  }

  await page.evaluate(async () => {
    window.iClubExamPrep.close();
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
  });
  await page.waitForSelector('[data-ep-live-component="P1"]');
  snapshot = await page.evaluate(() => ({ text: document.querySelector('#exam-prep-host-root')?.textContent || '', saves: window.__saves }));
  assert(snapshot.saves === 1, 'close/reopen must not resave or reset the profile');
  assert(snapshot.text.includes('5 / 24') && snapshot.text.includes('6 / 15'), 'close/reopen must restore saved component progress');
  assert(snapshot.text.includes('May/June 2027') && snapshot.text.includes('Total: 12 h/week'), 'close/reopen must restore saved settings');

  await page.click('[data-ep-live-start="P1"]');
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent?.includes('Question 2 / 2'));
  snapshot = await page.evaluate(() => ({ text: document.querySelector('#exam-prep-host-root')?.textContent || '', calls: window.__calls }));
  assert(snapshot.text.includes('Second question after reopening'), 'active diagnostic must resume at the next unanswered item');
  const start = snapshot.calls.filter(x => x.name === 'start_exam_prep_next_diagnostic_safe_v1').at(-1);
  assert(start && start.args.p_component_code === 'P1', 'resume must stay within P1');

  await browser.close();
  console.log('Exam Prep persistence continuity regression: PASS');
})().catch(error => { console.error(error); process.exit(1); });
