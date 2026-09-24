const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });

  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html><head></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'
  }));
  await page.goto('http://iclub.test/');
  await page.addStyleTag({ path: path.resolve('exam-prep/exam-prep-host.css') });

  await page.evaluate(() => {
    document.documentElement.lang = 'en';
    window.i18n = { getLang: () => 'en' };
    window.__calls = [];
    window.__profile = { exam_series: 'May/June 2027', target_grade: 'A', total_student_hours_available: 12, mathematics_hours_budget: 5, active_week_no: 1 };
    window.__caps = { program_key: 'math_as_p1_p5', rollout_state: 'controlled_beta', core_access: true, ai_assist: false, mentor_care_entitled: false, mentor_assignment_active: false, mentor_authority: false, kill_switch: false };
    window.__progress = {
      P1: { component_code: 'P1', placement_status: 'screening_incomplete', route: 'pending_evidence', profile_complete: true, content_ready: true, stage0_complete: false, screening: { required_items: 24, required_areas: 8, answered_items: 5, answered_areas: 3 }, active_session: null },
      P5: { component_code: 'P5', placement_status: 'screening_incomplete', route: 'pending_evidence', profile_complete: true, content_ready: true, stage0_complete: false, screening: { required_items: 15, required_areas: 5, answered_items: 6, answered_areas: 2 }, active_session: null }
    };
    window.__state = {
      P1: { engine_version: 'objective_state_v1', components: [{ component_code: 'P1', operational_stage: 0, coverage_pct: 0, levels: { L0: 45, L1: 0, L2: 0, L3: 0 } }], skills: [] },
      P5: { engine_version: 'objective_state_v1', components: [{ component_code: 'P5', operational_stage: 0, coverage_pct: 0, levels: { L0: 36, L1: 0, L2: 0, L3: 0 } }], skills: [] }
    };
    window.__overview = {
      P1: { component_code: 'P1', operational_stage: 0, coverage_count: 0, denominator_count: 45, coverage_pct: 0, stage0_complete: false, open_correction_count: 5, last_evidence: { evidence_type: 'diagnostic', verification_status: 'app_verified', is_correct: false, created_at: '2026-09-07T05:54:25Z' }, next_action: { action_code: 'continue_entry_check', plan_id: null, priority_order: null, item_type: null, due_at: null } },
      P5: { component_code: 'P5', operational_stage: 0, coverage_count: 0, denominator_count: 36, coverage_pct: 0, stage0_complete: false, open_correction_count: 5, last_evidence: { evidence_type: 'diagnostic', verification_status: 'app_verified', is_correct: true, created_at: '2026-09-07T05:55:44Z' }, next_action: { action_code: 'continue_entry_check', plan_id: null, priority_order: null, item_type: null, due_at: null } }
    };
    window.__placement = {
      P1: { component_code: 'P1', available: true, placement_status: 'screening_incomplete', provisional_route: 'pending_evidence', stage0_complete: false, profile_complete: true, content_ready: true, ambiguity: true, advanced_skip_requires_human: true, screening: { required_items: 24, required_areas: 8, answered_items: 5, answered_areas: 3, remaining_items: 19, remaining_areas: 5, accuracy_pct: 0 }, prerequisites: { unknown_count: 8, blocker_count: 0 }, access: { max_unlocked_stage: 0, foundation_learning_access: false, advanced_route_access: false }, next_action_code: 'continue_entry_check' },
      P5: { component_code: 'P5', available: true, placement_status: 'screening_incomplete', provisional_route: 'pending_evidence', stage0_complete: false, profile_complete: true, content_ready: true, ambiguity: true, advanced_skip_requires_human: true, screening: { required_items: 15, required_areas: 5, answered_items: 6, answered_areas: 2, remaining_items: 9, remaining_areas: 3, accuracy_pct: 16.67 }, prerequisites: { unknown_count: 10, blocker_count: 0 }, access: { max_unlocked_stage: 0, foundation_learning_access: false, advanced_route_access: false }, next_action_code: 'continue_entry_check' }
    };

    window.sb = { rpc: async (name, args = {}) => {
      window.__calls.push({ name, args });
      if (name === 'get_exam_prep_capabilities_v1') return { data: [window.__caps], error: null };
      if (name === 'get_my_exam_prep_beta_invitation_v1') return { data: { invited: false, invitations: [] }, error: null };
      if (name === 'get_exam_prep_exam_profile_v1') return { data: [window.__profile], error: null };
      if (name === 'get_exam_prep_diagnostic_progress_safe_v1') return { data: window.__progress[args.p_component_code], error: null };
      if (name === 'get_exam_prep_state_safe_v1') return { data: window.__state[args.p_component_code], error: null };
      if (name === 'get_exam_prep_overview_safe_v1') return { data: window.__overview[args.p_component_code], error: null };
      if (name === 'get_exam_prep_placement_result_safe_v1') return { data: window.__placement[args.p_component_code], error: null };
      if (name === 'get_exam_prep_syllabus_tracker_safe_v1') return { data: { component_code: args.p_component_code, denominator_count: args.p_component_code === 'P1' ? 45 : 36, coverage_count: 0, coverage_pct: 0, open_correction_count: 0, areas: [] }, error: null };
      if (name === 'get_exam_prep_correction_queue_safe_v1') return { data: { component_code: args.p_component_code, active_count: 0, retest_due_count: 0, cases: [], recent_resolved: [] }, error: null };
      if (name === 'get_exam_prep_weekly_plan_safe_v2') return { data: { component_code: args.p_component_code, plan_id: null, items: [] }, error: null };
      if (name === 'start_exam_prep_next_diagnostic_safe_v1') return { data: { session_id: '00000000-0000-4000-8000-000000002101' }, error: null };
      if (name === 'get_exam_prep_session_safe_v1') return { data: { session_id: '00000000-0000-4000-8000-000000002101', status: 'active', component_code: 'P1', session_type: 'diagnostic', total_items: 1, items: [{ item_order: 1, item_kind: 'machine', text: '2 + 2 = ?', qtype: 'mcq', options: ['3','4'], answered: false }] }, error: null };
      return { data: null, error: { message: `unexpected rpc ${name}` } };
    }};
  });

  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-api.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-host.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-live.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-overview-placement.js') });

  const assert = (condition, message) => { if (!condition) throw new Error(message); };

  await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
  });

  await page.waitForSelector('[data-ep-live-open-component="P1"]');
  await page.waitForSelector('[data-ep-live-open-component="P5"]');

  let visible = await page.locator('#exam-prep-host-root').textContent();
  assert(visible.includes('Pure Mathematics 1') && visible.includes('Probability & Statistics 1'), 'overview must keep separate P1/P5 route cards');
  assert(visible.includes('45 skills') && visible.includes('36 skills'), 'overview must preserve the separate P1/P5 denominators');
  assert(visible.includes('5 / 24') && visible.includes('3 / 8'), 'P1 route card must show its own entry-check progress');
  assert(visible.includes('6 / 15') && visible.includes('2 / 5'), 'P5 route card must show its own entry-check progress');
  assert(!visible.includes('81 skills') && !visible.includes('0 / 81'), 'overview must never publish a combined 81-skill result');
  assert(!visible.includes('pending_evidence') && !visible.includes('objective_state_v1'), 'overview must hide internal state codes');

  const overviewPresentation = await page.evaluate(() => {
    const root = document.querySelector('#exam-prep-host-root');
    const p1 = root.querySelector('[data-ep-live-open-component="P1"]');
    const p5 = root.querySelector('[data-ep-live-open-component="P5"]');
    return {
      routeCards: root.querySelectorAll('[data-ep-live-open-component]').length,
      oldStrips: root.querySelectorAll('[data-ep-overview-strip]').length,
      oldPlacementButtons: root.querySelectorAll('[data-ep-placement-open]').length,
      p1Width: p1?.getBoundingClientRect().width || 0,
      p5Width: p5?.getBoundingClientRect().width || 0,
      rootWidth: root.getBoundingClientRect().width,
      scrollWidth: root.scrollWidth
    };
  });
  assert(overviewPresentation.routeCards === 2, 'component-first overview must expose exactly two route cards');
  assert(overviewPresentation.oldStrips === 0 && overviewPresentation.oldPlacementButtons === 0, 'removed dashboard overview/placement controls must not return');
  assert(overviewPresentation.p1Width > 0 && overviewPresentation.p5Width > 0, 'P1/P5 route cards must remain visible');
  assert(overviewPresentation.rootWidth + 1 >= overviewPresentation.scrollWidth, `Overview overflow: ${overviewPresentation.scrollWidth} > ${overviewPresentation.rootWidth}`);

  await page.evaluate(() => window.iClubExamPrepHostInternal.overviewPlacementViews.openPlacement('P1'));
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent.includes('Entry check result'));
  visible = await page.locator('#exam-prep-host-root').textContent();
  assert(visible.includes('5 / 24') && visible.includes('3 / 8'), 'P1 placement result must show P1 screening progress only');
  assert(visible.includes('More evidence is needed') && visible.includes('Gathering enough evidence'), 'ambiguous placement must remain conservative and visibly provisional');
  assert(visible.includes('Paper 1 and Paper 5 do not raise each other'), 'placement result must state the component firewall in learner-facing language');
  assert(!visible.includes('pending_evidence') && !visible.includes('advanced_skip_requires_human'), 'placement result must hide internal route/field names');

  const placementPresentation = await page.evaluate(() => {
    const root = document.querySelector('#exam-prep-host-root');
    const shell = root.querySelector('.ep-placement-shell');
    const card = root.querySelector('.ep-placement-card');
    return { runtimeStyle: Boolean(document.querySelector('#ep-overview-placement-style')), shellDisplay: getComputedStyle(shell).display, cardRadius: getComputedStyle(card).borderRadius, rootWidth: root.getBoundingClientRect().width, scrollWidth: root.scrollWidth };
  });
  assert(placementPresentation.runtimeStyle === false, 'Placement runtime style tag appeared');
  assert(placementPresentation.shellDisplay === 'grid', 'Centralized placement CSS did not apply');
  assert(placementPresentation.cardRadius === '14px', 'Placement card geometry changed during CSS centralization');
  assert(placementPresentation.rootWidth + 1 >= placementPresentation.scrollWidth, `Placement overflow: ${placementPresentation.scrollWidth} > ${placementPresentation.rootWidth}`);

  // The placement CTA must follow the current component-first learner route.
  // It must not depend on the hidden legacy data-ep-live-start compatibility button.
  await page.click('[data-ep-placement-next]');
  await page.waitForSelector('[data-ep-live-submit]', { state: 'visible', timeout: 5000 });
  const afterContinue = await page.evaluate(() => ({
    componentHomeVisible: Boolean(document.querySelector('[data-ep-component-home="P1"]')),
    submitVisible: Boolean(document.querySelector('[data-ep-live-submit]')),
    hiddenLegacyStart: Boolean(document.querySelector('.ep-live-compat-actions[hidden] [data-ep-live-start="P1"]'))
  }));
  assert(afterContinue.submitVisible, 'placement Continue must launch the next real P1 diagnostic block');
  assert(!afterContinue.componentHomeVisible, 'placement Continue must not stop on the component home');
  assert(afterContinue.hiddenLegacyStart === false, 'active diagnostic screen must not rely on hidden legacy start markup');

  let callsAfterContinue = await page.evaluate(() => window.__calls);
  const startCalls = callsAfterContinue.filter(x => x.name === 'start_exam_prep_next_diagnostic_safe_v1');
  assert(startCalls.length === 1 && startCalls[0].args.p_component_code === 'P1', 'placement Continue must start exactly one P1 diagnostic session');

  await page.evaluate(async () => {
    await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
  });
  await page.waitForSelector('[data-ep-live-open-component="P1"]');

  await page.evaluate(() => window.iClubExamPrepHostInternal.overviewPlacementViews.openPlacement('P1'));
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent.includes('Entry check result'));
  await page.click('[data-ep-placement-back]');
  await page.waitForSelector('[data-ep-live-open-component="P5"]');

  await page.evaluate(() => window.iClubExamPrepHostInternal.overviewPlacementViews.openPlacement('P5'));
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent.includes('6 / 15'));
  visible = await page.locator('#exam-prep-host-root').textContent();
  assert(visible.includes('2 / 5'), 'P5 placement result must stay independent from P1');

  const calls = await page.evaluate(() => window.__calls);
  const overviewCalls = calls.filter(x => x.name === 'get_exam_prep_overview_safe_v1');
  const placementCalls = calls.filter(x => x.name === 'get_exam_prep_placement_result_safe_v1');
  assert(overviewCalls.length === 0, 'compact component-first overview must not rehydrate removed legacy overview strips');
  assert(placementCalls.some(x => x.args.p_component_code === 'P1') && placementCalls.some(x => x.args.p_component_code === 'P5'), 'placement result RPCs must stay component-scoped');

  await browser.close();
  console.log('P0-21 live overview / placement result flow: PASS');
})().catch(error => { console.error(error); process.exit(1); });