const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.route('http://iclub.test/', route => route.fulfill({
    status: 200,
    contentType: 'text/html',
    body: '<!doctype html><html lang="en"><head></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'
  }));
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    window.__calls = [];
    window.i18n = { getLang: () => 'en' };
    window.__caps = { program_key: 'math_as_p1_p5', rollout_state: 'controlled_beta', core_access: true, ai_assist: false, mentor_care_entitled: false, mentor_assignment_active: false, mentor_authority: false, kill_switch: false };
    window.__profile = { exam_series: 'May/June 2027', target_grade: 'A', total_student_hours_available: 12, mathematics_hours_budget: 5, active_week_no: 1 };
    window.__progress = {
      P1: { component_code: 'P1', placement_status: 'screening_incomplete', route: 'pending_evidence', profile_complete: true, content_ready: true, stage0_complete: false, screening: { required_items: 24, required_areas: 8, answered_items: 0, answered_areas: 0 }, active_session: null },
      P5: { component_code: 'P5', placement_status: 'screening_incomplete', route: 'pending_evidence', profile_complete: true, content_ready: true, stage0_complete: false, screening: { required_items: 15, required_areas: 5, answered_items: 0, answered_areas: 0 }, active_session: null }
    };
    window.__state = {
      P1: { components: [{ component_code: 'P1', operational_stage: 0, coverage_pct: 0, levels: { L0: 45, L1: 0, L2: 0, L3: 0 } }], skills: [] },
      P5: { components: [{ component_code: 'P5', operational_stage: 0, coverage_pct: 0, levels: { L0: 36, L1: 0, L2: 0, L3: 0 } }], skills: [] }
    };
    window.__overview = {
      P1: { component_code: 'P1', operational_stage: 0, coverage_count: 0, denominator_count: 45, coverage_pct: 0, last_evidence: null, next_action: { action_code: 'continue_entry_check' } },
      P5: { component_code: 'P5', operational_stage: 0, coverage_count: 0, denominator_count: 36, coverage_pct: 0, last_evidence: null, next_action: { action_code: 'continue_entry_check' } }
    };
    window.__legacy = {
      P1: { component_code: 'P1', available: true, source_type: 'legacy_readonly', academic_credit: false, mastery_effect: 'none', mapping_version: 'p1_existing_bank_v1', reference_count: 3, skills: [] },
      P5: { component_code: 'P5', available: false, source_type: 'legacy_readonly', academic_credit: false, mastery_effect: 'none', mapping_version: null, reference_count: 0, skills: [] }
    };

    window.sb = { rpc: async (name, args = {}) => {
      window.__calls.push({ name, args });
      if (name === 'get_exam_prep_capabilities_v1') return { data: [window.__caps], error: null };
      if (name === 'get_my_exam_prep_beta_invitation_v1') return { data: { invited: false, invitations: [] }, error: null };
      if (name === 'get_exam_prep_exam_profile_v1') return { data: [window.__profile], error: null };
      if (name === 'get_exam_prep_diagnostic_progress_safe_v1') return { data: window.__progress[args.p_component_code], error: null };
      if (name === 'get_exam_prep_state_safe_v1') return { data: window.__state[args.p_component_code], error: null };
      if (name === 'get_exam_prep_overview_safe_v1') return { data: window.__overview[args.p_component_code], error: null };
      if (name === 'get_exam_prep_legacy_reference_summary_safe_v1') return { data: window.__legacy[args.p_component_code], error: null };
      return { data: null, error: { message: `unexpected rpc ${name}` } };
    }};
  });

  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-api.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-host.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-live.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-overview-placement.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-history-note.js') });

  const assert = (condition, message) => { if (!condition) throw new Error(message); };

  await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
  });

  await page.waitForSelector('[data-ep-overview-strip="P1"]');
  await page.waitForSelector('[data-ep-overview-strip="P5"]');
  await page.waitForSelector('[data-ep-history-note="P1"]');

  const p1Text = await page.locator('[data-ep-history-note="P1"]').textContent();
  assert(p1Text.includes('Previous practice'), 'P1 history note must use learner-facing wording');
  assert(p1Text.includes('3 earlier Practice/Tour answers found'), 'P1 history note must report only safe reference count');
  assert(p1Text.includes('does not change confirmed progress or exam readiness'), 'P1 history note must explicitly remain non-crediting');
  assert(await page.locator('[data-ep-history-note="P5"]').count() === 0, 'P5 history note must stay hidden without approved P5 legacy mapping');

  const visible = await page.locator('#exam-prep-host-root').textContent();
  ['legacy_readonly','mapping_version','academic_credit','mastery_effect','p1_existing_bank_v1'].forEach(token => {
    assert(!visible.includes(token), `learner UI leaked internal legacy token: ${token}`);
  });

  const calls = await page.evaluate(() => window.__calls.filter(x => x.name === 'get_exam_prep_legacy_reference_summary_safe_v1'));
  assert(calls.some(x => x.args.p_component_code === 'P1'), 'history adapter must query P1 separately');
  assert(calls.some(x => x.args.p_component_code === 'P5'), 'history adapter must query P5 separately');

  await page.evaluate(() => {
    window.iClubExamPrepHostInternal.lastCapabilities = { ...window.iClubExamPrepHostInternal.lastCapabilities, coreAccess: false };
    document.querySelector('#exam-prep-host-root')?.setAttribute('aria-hidden', 'false');
  });
  await page.waitForFunction(() => document.querySelectorAll('[data-ep-history-note]').length === 0);

  await browser.close();
  console.log('P1-05 previous-practice learner note: PASS');
})().catch(error => { console.error(error); process.exit(1); });
