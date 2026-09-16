// Isolated browser regression: no real Supabase, user data, localStorage or production site.
const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.route('http://iclub.test/', route => route.fulfill({
      status: 200, contentType: 'text/html',
      body: '<!doctype html><html lang="en"><body><div id="exam-prep-host-root"></div></body></html>'
    }));
    await page.goto('http://iclub.test/');
    await page.evaluate(() => {
      const root = document.querySelector('#exam-prep-host-root');
      window.__pendingProfiles = [];
      window.__dashboard = () => '<section class="ep-host-shell ep-live"><div class="ep-live-dashboard-intro">Dashboard</div><div class="ep-live-grid"><button data-ep-live-plan="P1">P1</button><button data-ep-live-plan="P5">P5</button></div></section>';
      window.__profileResult = {ok: true, data: {
        exam_series: 'May/June 2027', target_grade: 'A',
        total_student_hours_available: 12, mathematics_hours_budget: 6
      }};
      window.iClubExamPrepHostInternal = {
        lastCapabilities: {coreAccess: true, killSwitch: false, rolloutState: 'controlled_beta'},
        api: {examProfile: () => new Promise(resolve => window.__pendingProfiles.push(resolve))}
      };
      root.setAttribute('aria-hidden', 'false');
      root.innerHTML = window.__dashboard();
    });
    await page.addScriptTag({path: path.resolve('exam-prep/exam-prep-exam-map.js')});
    const assert = (value, message) => { if (!value) throw new Error(message); };
    const waitForRequests = async count => page.waitForFunction(n => window.__pendingProfiles.length >= n, count);
    const cardCount = () => page.locator('[data-ep-exam-plan-card]').count();
    const editCount = () => page.locator('[data-ep-exam-plan-edit]').count();
    const resolveRequest = index => page.evaluate(i => {
      window.__pendingProfiles[i](window.__profileResult);
    }, index);
    const flush = async () => { await page.evaluate(() => new Promise(resolve => setTimeout(resolve, 0))); };

    // Two observer-triggered fetches both see an empty dashboard. Latest response wins;
    // older response must not append a second card or edit button.
    await waitForRequests(1);
    await page.evaluate(() => {
      document.querySelector('#exam-prep-host-root').appendChild(document.createElement('span'));
    });
    await waitForRequests(2);
    await resolveRequest(1);
    await page.waitForSelector('[data-ep-exam-plan-card]');
    await resolveRequest(0);
    await flush();
    assert(await cardCount() === 1, 'concurrent profile fetches created duplicate cards');
    assert(await editCount() === 1, 'concurrent profile fetches created duplicate edit controls');

    // Replacing a dashboard while the request is pending invalidates that response.
    await page.evaluate(() => { document.querySelector('#exam-prep-host-root').innerHTML = window.__dashboard(); });
    await waitForRequests(3);
    await page.evaluate(() => { document.querySelector('#exam-prep-host-root').innerHTML = window.__dashboard(); });
    await waitForRequests(4);
    await resolveRequest(2);
    await flush();
    assert(await cardCount() === 0, 'stale dashboard received a card');
    await resolveRequest(3);
    await page.waitForSelector('[data-ep-exam-plan-card]');
    assert(await cardCount() === 1, 'fresh dashboard did not hydrate exactly once');

    // Closing the host during the request must not recreate an invisible plan card.
    await page.evaluate(() => { document.querySelector('#exam-prep-host-root').innerHTML = window.__dashboard(); });
    await waitForRequests(5);
    await page.evaluate(() => {
      const root = document.querySelector('#exam-prep-host-root');
      root.hidden = true;
      root.setAttribute('aria-hidden', 'true');
    });
    await resolveRequest(4);
    await flush();
    assert(await cardCount() === 0, 'closed host was repainted');
    await page.evaluate(() => {
      const root = document.querySelector('#exam-prep-host-root');
      root.hidden = false;
      root.setAttribute('aria-hidden', 'false');
    });
    await waitForRequests(6);
    await resolveRequest(5);
    await page.waitForSelector('[data-ep-exam-plan-card]');
    assert(await cardCount() === 1, 'reopened host did not recover one plan card');

    // Revoked Core access while fetching must fail closed.
    await page.evaluate(() => { document.querySelector('#exam-prep-host-root').innerHTML = window.__dashboard(); });
    await waitForRequests(7);
    await page.evaluate(() => { window.iClubExamPrepHostInternal.lastCapabilities.coreAccess = false; });
    await resolveRequest(6);
    await flush();
    assert(await cardCount() === 0, 'revoked Core access received a plan card');

    console.log('Exam Prep plan card race: PASS (concurrency, stale view, close/reopen, Core revocation)');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
