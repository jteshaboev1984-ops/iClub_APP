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
            <button type="button" data-action="open-exam-prep">
              <span id="subject-hub-exam-prep-badge"></span>
              <span id="subject-hub-exam-prep-title"></span>
              <span id="subject-hub-exam-prep-sub"></span>
              <span id="subject-hub-exam-prep-p1"></span>
              <span id="subject-hub-exam-prep-p5"></span>
              <span id="subject-hub-exam-prep-note"></span>
              <span id="subject-hub-exam-prep-cta"></span>
            </button>
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
        if (name === 'get_my_exam_prep_weekly_flow_status_v1') return { data: { contract_version: 'weekly_flow_status_v1', enabled: false }, error: null };
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

  // No invitation or opt-in may open Mathematics while the server Core gate is OFF.
  // Even a legacy invitation payload is not an entitlement.
  await page.evaluate(() => {
    window.__invite = {
      invited: true,
      invitations: [{ cohort_key: 'math_as_p1_p5_beta_2026_09_01',
        member_status: 'candidate', consent_status: 'missing', open_recruitment: true }]
    };
  });
  result = await page.evaluate(async () => {
    const synced = await window.iClubExamPrep.syncSubjectHub({subjectKey:'mathematics',language:'en'});
    const opened = await window.iClubExamPrep.open({subjectKey:'mathematics',language:'en'});
    return {synced,opened,hidden:document.querySelector('#subject-hub-exam-prep-entry').hidden,
      actionButtons:document.querySelectorAll('[data-ep-beta-action]').length};
  });
  assert(!result.synced && !result.opened && result.hidden && result.actionButtons===0,
    'Legacy invitations must never bypass Core entitlement or show consent buttons');
  assert((await page.evaluate(()=>window.__rpcCalls)).every(x=>
    !['get_my_exam_prep_beta_invitation_v1','grant_my_exam_prep_beta_consent_v1',
      'claim_my_exam_prep_beta_core_seat_v1','revoke_my_exam_prep_beta_consent_v1'].includes(x.name)),
    'No legacy invitation, join, consent or revoke calls are allowed from host');

  // Existing Core access requires only server entitlement, not a consent shell.
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
    const trigger = document.querySelector('[data-action="open-exam-prep"]');
    trigger.focus();
    const opened = await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
    const shellText = document.querySelector('#exam-prep-host-root').textContent;
    const hostOpen = document.querySelector('#courses-subject-hub').classList.contains('exam-prep-host-open');
    const focusMovedIntoHost = document.activeElement?.id === 'exam-prep-host-root';
    const hostTabIndex = document.querySelector('#exam-prep-host-root')?.getAttribute('tabindex');
    const backHandled = window.iClubExamPrep.back();
    const focusReturnedToTrigger = document.activeElement === trigger;
    return {
      synced, entryHidden, opened, hostOpen, backHandled, focusMovedIntoHost, hostTabIndex, focusReturnedToTrigger,
      closed: !window.iClubExamPrep.isOpen(),
      sentinel: localStorage.getItem('p014_sentinel'),
      shellText
    };
  });
  assert(result.synced === true && result.entryHidden === false, 'authorized Math entry must appear');
  assert(result.opened === true && result.hostOpen === true, 'authorized open must mount transient root');
  assert(result.focusMovedIntoHost && result.hostTabIndex === '-1', 'opening Exam Prep must move keyboard focus into the visible host without adding a tab stop');
  assert(result.focusReturnedToTrigger, 'closing Exam Prep with Back must restore focus to the launch control');
  assert(result.shellText.includes('P1 and P5 results are tracked separately'), 'live shell must explain the P1/P5 separation in learner-facing language');
  assert(!result.shellText.includes('Internal alpha') && !result.shellText.includes('host bridge') && !result.shellText.includes('synthetic learner data') && !result.shellText.includes('canonical skills'), 'live shell must not expose internal implementation terminology');
  assert(result.backHandled === true && result.closed === true, 'back must close transient root');
  assert(result.sentinel === 'unchanged', 'host bridge must not pollute localStorage');

  // AI-entitled learners should see the premium capability before opening Exam Prep,
  // without exposing internal service-mode terminology or changing Core access.
  result = await page.evaluate(async () => {
    window.__caps = { ...window.__caps, ai_assist: true };
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    const entry = document.querySelector('#subject-hub-exam-prep-entry');
    return {
      hidden: entry.hidden,
      aiVisible: entry.getAttribute('data-ep-ai-visible'),
      hasAiClass: entry.classList.contains('has-ai-assist'),
      badge: document.querySelector('#subject-hub-exam-prep-badge')?.textContent || '',
      note: document.querySelector('#subject-hub-exam-prep-note')?.textContent || '',
      text: entry.textContent || ''
    };
  });
  assert(result.hidden === false, 'AI-entitled learner lost the Exam Prep entry');
  assert(result.aiVisible === 'true' && result.hasAiClass, 'AI entitlement is not visibly represented on the Exam Prep entry');
  assert(result.badge.includes('AI'), 'AI-enabled Exam Prep entry badge does not surface AI');
  assert(result.note.includes('AI Tutor is available'), 'AI-enabled Exam Prep entry does not explain the premium capability');
  assert(!result.text.includes('AI Assist'), 'learner-facing Exam Prep entry leaked internal AI service-mode terminology');
  await page.evaluate(() => { window.__caps = { ...window.__caps, ai_assist: false }; });

  result = await page.evaluate(async () => {
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'mathematics', language: 'en' });
    await window.iClubExamPrep.open({ subjectKey: 'mathematics', language: 'en' });
    await window.iClubExamPrep.syncSubjectHub({ subjectKey: 'economics', language: 'en' });
    const entry = document.querySelector('#subject-hub-exam-prep-entry');
    return {
      hidden: entry.hidden,
      mode: entry.getAttribute('data-ep-entry-mode'),
      badge: document.querySelector('#subject-hub-exam-prep-badge')?.textContent,
      open: window.iClubExamPrep.isOpen(),
      rootHidden: document.querySelector('#exam-prep-host-root').hidden
    };
  });
  assert(!result.hidden && result.mode === 'coming-soon' &&
    result.badge.includes('In development') && !result.open && result.rootHidden,
    'subject switch must unmount Mathematics and show informational Exam Prep for Economics');

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

  const rpcCalls = await page.evaluate(() => window.__rpcCalls.map(x => ({ name: x.name, args: x.args })));
  const allowedRpcs = new Set([
    'get_exam_prep_capabilities_v1',
    'get_my_exam_prep_weekly_flow_status_v1',
  ]);
  // Existing Economics native shell reads its own configuration on a subject
  // switch. Never treat this as Math beta access or authorize unknown RPCs.
  const notAllowed = rpcCalls.filter(call => !allowedRpcs.has(call.name) &&
    !(call.name === 'get_my_exam_prep_program_shell_v1' &&
      call.args?.p_program_key === 'economics_9708' &&
      ['en','ru','uz'].includes(call.args?.p_language)));
  assert(rpcCalls.length > 0, 'host must call server access RPCs');
  assert(notAllowed.length === 0, 'host called an unauthorized RPC: ' +
    notAllowed.map(call=>call.name).join(', '));

  await browser.close();
  console.log('P0-14 browser matrix: PASS (server entitlement, no consent, cross-subject focus and storage continuity)');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
