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
    window.__rpcCalls = [];
    window.sb = {
      rpc: async (name, args) => {
        window.__rpcCalls.push({ name, args });
        return { data: [window.__caps], error: null };
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
  assert(result.synced === false, 'OFF sync must fail closed');
  assert(result.opened === false, 'OFF direct open must fail closed');
  assert(result.hidden === true && result.isOpen === false, 'OFF entry/root must stay closed');

  await page.evaluate(() => {
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
  assert(result.hidden && !result.open, 'kill switch refresh must close/hide Exam Prep');

  const rpcCalls = await page.evaluate(() => window.__rpcCalls.map(x => x.name));
  assert(rpcCalls.length > 0, 'capability RPC must be called');
  assert(rpcCalls.every(name => name === 'get_exam_prep_capabilities_v1'), 'P0-14 host may call capability RPC only');

  await browser.close();
  console.log('P0-14 browser matrix: PASS');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
