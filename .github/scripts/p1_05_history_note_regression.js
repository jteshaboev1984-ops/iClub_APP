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
    window.__caps = {
      program_key: 'math_as_p1_p5',
      rollout_state: 'controlled_beta',
      core_access: true,
      ai_assist: false,
      mentor_care_entitled: false,
      mentor_assignment_active: false,
      mentor_authority: false,
      kill_switch: false
    };
    window.__legacy = {
      P1: {
        component_code: 'P1',
        available: true,
        source_type: 'legacy_readonly',
        academic_credit: false,
        mastery_effect: 'none',
        mapping_version: 'p1_existing_bank_v1',
        reference_count: 3,
        skills: []
      },
      P5: {
        component_code: 'P5',
        available: false,
        source_type: 'legacy_readonly',
        academic_credit: false,
        mastery_effect: 'none',
        mapping_version: null,
        reference_count: 0,
        skills: []
      }
    };

    window.sb = { rpc: async (name, args = {}) => {
      window.__calls.push({ name, args });
      if (name === 'get_exam_prep_capabilities_v1') return { data: [window.__caps], error: null };
      if (name === 'get_my_exam_prep_beta_invitation_v1') return { data: { invited: false, invitations: [] }, error: null };
      if (name === 'get_my_exam_prep_weekly_flow_status_v1') return { data: { contract_version: 'weekly_flow_status_v1', enabled: false }, error: null };
      if (name === 'get_exam_prep_legacy_reference_summary_safe_v1') return { data: window.__legacy[args.p_component_code], error: null };
      return { data: null, error: { message: `unexpected rpc ${name}` } };
    }};
  });

  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-api.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-host.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-history-note.js') });

  const assert = (condition, message) => { if (!condition) throw new Error(message); };

  const opened = await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    const result = await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });

    const root = document.querySelector('#exam-prep-host-root');
    const p1 = document.createElement('div');
    p1.dataset.epOverviewStrip = 'P1';
    const p5 = document.createElement('div');
    p5.dataset.epOverviewStrip = 'P5';
    root.append(p1, p5);
    return result;
  });
  assert(opened === true, 'Core learner host must open before the history note is hydrated');

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
    window.iClubExamPrepHostInternal.lastCapabilities = {
      ...window.iClubExamPrepHostInternal.lastCapabilities,
      coreAccess: false
    };
    const root = document.querySelector('#exam-prep-host-root');
    root.setAttribute('aria-hidden', root.getAttribute('aria-hidden') === 'true' ? 'false' : 'true');
  });
  await page.waitForFunction(() => document.querySelectorAll('[data-ep-history-note]').length === 0);

  await browser.close();
  console.log('P1-05 previous-practice learner note: PASS');
})().catch(error => { console.error(error); process.exit(1); });
