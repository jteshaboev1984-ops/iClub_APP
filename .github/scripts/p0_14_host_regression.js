const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  await page.route('http://iclub.test/', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'text/html',
      body: `<!doctype html><html><body>
        <section id="courses-subject-hub">
          <div id="subject-hub-exam-prep-entry" hidden aria-hidden="true">
            <span id="subject-hub-exam-prep-title"></span>
            <span id="subject-hub-exam-prep-sub"></span>
          </div>
          <div id="exam-prep-host-root" hidden aria-hidden="true"></div>
        </section>
      </body></html>`
    });
  });
  await page.goto('http://iclub.test/');

  await page.evaluate(() => {
    window.__caps = {
      program_key: 'math_as_p1_p5', rollout_state: 'off', core_access: false,
      ai_assist: false, mentor_care_entitled: false, mentor_assignment_active: false,
      mentor_authority: false, kill_switch: true
    };
    window.__invite = {
      invited: false,
      consent_scope: 'exam_prep_controlled_beta_v1',
      consent_copy_version: 'controlled_beta_v1_2026_09_04',
      invitations: []
    };
    window.__rpcCalls = [];
    window.confirm = () => true;
    window.sb = {
      rpc: async (name, args) => {
        window.__rpcCalls.push({ name, args });
        if (name === 'get_exam_prep_capabilities_v1') return { data: [window.__caps], error: null };
        if (name === 'get_my_exam_prep_beta_invitation_v1') return { data: window.__invite, error: null };
        if (name === 'grant_my_exam_prep_beta_consent_v1') {
          window.__invite = {
            ...window.__invite,
            invited: true,
            invitations: window.__invite.invitations.map(item => ({
              ...item, consent_status: 'granted', consented_at: '2026-09-04T13:00:00Z', revoked_at: null
            }))
          };
          return { data: { consent_status: 'granted' }, error: null };
        }
        if (name === 'revoke_my_exam_prep_beta_consent_v1') {
          window.__invite = { ...window.__invite, invited: false, invitations: [] };
          return { data: { consent_status: 'revoked' }, error: null };
        }
        return { data: null, error: { message: `unexpected rpc ${name}` } };
      }
    };
    localStorage.setItem('p014_sentinel', 'unchanged');
  });

  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-api.js') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-host.js') });

  const assert = (condition, message) => {
    if (!condition) throw new Error(message);
  };

  let result = await page.evaluate(async () => {
    const synced = await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    const opened = await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
    return {
      synced, opened,
      hidden: document.querySelector('#subject-hub-exam-prep-entry').hidden,
      isOpen: window.iClubExamPrep.isOpen()
    };
  });
  assert(result.synced === false, 'OFF sync without invite must fail closed');
  assert(result.opened === false, 'OFF direct open without invite must fail closed');
  assert(result.hidden === true && result.isOpen === false, 'OFF entry/root must stay closed');

  // A real allowlisted candidate must be able to see and explicitly accept the
  // invitation before Core entitlement exists. Merely viewing/opening must not consent.
  await page.evaluate(() => {
    window.__invite = {
      invited: true,
      consent_scope: 'exam_prep_controlled_beta_v1',
      consent_copy_version: 'controlled_beta_v1_2026_09_04',
      invitations: [{
        cohort_key: 'math_as_p1_p5_beta_2026_09_01',
        cohort_status: 'draft', capacity: 12, monitoring_hours: 72,
        service_mode: 'core', activation_wave: 1, member_status: 'candidate',
        consent_status: 'missing', consented_at: null, revoked_at: null,
        consent_scope: 'exam_prep_controlled_beta_v1',
        consent_copy_version: 'controlled_beta_v1_2026_09_04'
      }]
    };
  });

  result = await page.evaluate(async () => {
    const beforeGrant = window.__rpcCalls.filter(x => x.name === 'grant_my_exam_prep_beta_consent_v1').length;
    const synced = await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    const entryText = document.querySelector('#subject-hub-exam-prep-entry').textContent;
    const opened = await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
    const shellText = document.querySelector('#exam-prep-host-root').textContent;
    const afterOpenGrant = window.__rpcCalls.filter(x => x.name === 'grant_my_exam_prep_beta_consent_v1').length;
    return {
      synced, opened, entryText, shellText, beforeGrant, afterOpenGrant,
      hidden: document.querySelector('#subject-hub-exam-prep-entry').hidden
    };
  });
  assert(result.synced === true && result.opened === true && result.hidden === false, 'invited candidate must see/open consent shell while Core is OFF');
  assert(result.entryText.includes('controlled beta invitation'), 'entry must disclose beta invitation state');
  assert(result.shellText.includes('Participation is voluntary'), 'consent shell must disclose voluntary participation');
  assert(result.beforeGrant === 0 && result.afterOpenGrant === 0, 'viewing invitation must never auto-consent');

  await page.click('[data-ep-beta-action="grant"]');
  await page.waitForFunction(() => document.querySelector('#exam-prep-host-root')?.textContent.includes('Consent recorded'));

  result = await page.evaluate(() => {
    const grants = window.__rpcCalls.filter(x => x.name === 'grant_my_exam_prep_beta_consent_v1');
    return {
      count: grants.length,
      args: grants[0]?.args,
      shellText: document.querySelector('#exam-prep-host-root').textContent,
      caps: window.__caps
    };
  });
  assert(result.count === 1, 'explicit consent button must issue exactly one grant RPC');
  assert(result.args?.p_cohort_key === 'math_as_p1_p5_beta_2026_09_01', 'consent must target invited cohort only');
  assert(result.args?.p_acknowledgement === 'I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1', 'consent acknowledgement token mismatch');
  assert(result.shellText.includes('does not enable Exam Prep access yet'), 'consent success must not imply activation');
  assert(result.caps.core_access === false && result.caps.kill_switch === true, 'consent UI must not mutate capability state');

  await page.click('[data-ep-beta-action="revoke"]');
  await page.waitForFunction(() => document.querySelector('#subject-hub-exam-prep-entry')?.hidden === true);
  result = await page.evaluate(() => ({
    revokeCalls: window.__rpcCalls.filter(x => x.name === 'revoke_my_exam_prep_beta_consent_v1'),
    open: window.iClubExamPrep.isOpen(),
    rootHidden: document.querySelector('#exam-prep-host-root').hidden
  }));
  assert(result.revokeCalls.length === 1, 'explicit revoke must issue exactly one revoke RPC');
  assert(result.revokeCalls[0].args?.p_acknowledgement === 'I_REVOKE_EXAM_PREP_CONTROLLED_BETA_V1', 'revoke acknowledgement token mismatch');
  assert(result.open === false && result.rootHidden === true, 'withdrawn candidate must lose invitation shell without gaining access');

  // Existing live Core behavior remains unchanged after consent UI addition.
  await page.evaluate(() => {
    window.__invite = { ...window.__invite, invited: false, invitations: [] };
    window.__caps = {
      program_key: 'math_as_p1_p5', rollout_state: 'internal_alpha', core_access: true,
      ai_assist: false, mentor_care_entitled: false, mentor_assignment_active: false,
      mentor_authority: false, kill_switch: false
    };
  });

  result = await page.evaluate(async () => {
    const synced = await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    const entryHidden = document.querySelector('#subject-hub-exam-prep-entry').hidden;
    const opened = await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
    const shellText = document.querySelector('#exam-prep-host-root').textContent;
    const hostOpen = document.querySelector('#courses-subject-hub').classList.contains('exam-prep-host-open');
    const backHandled = window.iClubExamPrep.back();
    return {
      synced, entryHidden, opened, hostOpen, backHandled,
      closed: !window.iClubExamPrep.isOpen(),
      sentinel: localStorage.getItem('p014_sentinel'),
      shellText
    };
  });
  assert(result.synced === true && result.entryHidden === false, 'alpha Math entry must appear');
  assert(result.opened === true && result.hostOpen === true, 'alpha open must mount transient root');
  assert(result.shellText.includes('No synthetic learner data'), 'live shell must explicitly avoid synthetic learner state');
  assert(result.backHandled === true && result.closed === true, 'back must close transient root');
  assert(result.sentinel === 'unchanged', 'host bridge must not pollute localStorage');

  result = await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'physics', language: 'en' });
    return {
      hidden: document.querySelector('#subject-hub-exam-prep-entry').hidden,
      open: window.iClubExamPrep.isOpen(),
      rootHidden: document.querySelector('#exam-prep-host-root').hidden
    };
  });
  assert(result.hidden && !result.open && result.rootHidden, 'subject switch must unmount Exam Prep');

  result = await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'ru' });
    await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'ru' });
    window.__caps = { ...window.__caps, kill_switch: true, core_access: false, rollout_state: 'off' };
    await window.iClubExamPrep.refreshCapabilities();
    return {
      hidden: document.querySelector('#subject-hub-exam-prep-entry').hidden,
      open: window.iClubExamPrep.isOpen()
    };
  });
  assert(result.hidden && !result.open, 'kill switch refresh without invitation must close/hide Exam Prep');

  const rpcCalls = await page.evaluate(() => window.__rpcCalls.map(x => x.name));
  const allowedRpcs = new Set([
    'get_exam_prep_capabilities_v1',
    'get_my_exam_prep_beta_invitation_v1',
    'grant_my_exam_prep_beta_consent_v1',
    'revoke_my_exam_prep_beta_consent_v1'
  ]);
  assert(rpcCalls.length > 0, 'host must call server access RPCs');
  assert(rpcCalls.every(name => allowedRpcs.has(name)), 'host called an RPC outside capability/invitation consent boundary');

  await browser.close();
  console.log('P0-14 browser matrix: PASS (live access + pre-entitlement consent)');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
