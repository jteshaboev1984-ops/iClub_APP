const { chromium } = require('playwright');
const path = require('path');

const DASHBOARD = '<section class="ep-host-shell ep-live"><div class="ep-live-dashboard-intro">Overview</div><div class="ep-live-grid"><article class="ep-live-card"><div class="ep-live-actions"><button type="button" data-ep-live-plan="P1">P1 plan</button></div></article><article class="ep-live-card"><div class="ep-live-actions"><button type="button" data-ep-live-plan="P5">P5 plan</button></div></article></div></section>';
const RESULT = {
  ok: true,
  data: {
    rights_respected: true,
    protected_content_embedded: false,
    materials: [{
      material_key: 'cambridge_9709_syllabus_2026_2027',
      component_code: null,
      resource_kind: 'official_syllabus',
      title: 'Cambridge 9709 syllabus 2026–2027',
      note: 'Official syllabus reference.',
      external_url: 'https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf',
      licensed_copy_required: false,
      school_request_required: false
    }]
  }
};

(async () => {
  const browser = await chromium.launch({ headless: true });
  const errors = [];
  try {
    const page = await browser.newPage();
    page.on('pageerror', error => errors.push(error.message));
    await page.route('http://iclub.test/', route => route.fulfill({
      status: 200, contentType: 'text/html',
      body: `<!doctype html><html lang="en"><body><div id="exam-prep-host-root">${DASHBOARD}</div></body></html>`
    }));
    await page.goto('http://iclub.test/');
    await page.evaluate(dashboard => {
      window.__dashboard = dashboard;
      window.__requests = [];
      window.__opens = 0;
      window.iClubExamPrepHostInternal = {
        lastCapabilities: { coreAccess: true, killSwitch: false, rolloutState: 'controlled_beta' },
        api: {
          materialsLibrary: language => new Promise((resolve, reject) => {
            window.__requests.push({ resolve, reject, language });
          })
        }
      };
      window.iClubExamPrep = {
        open: async () => {
          window.__opens++;
          const root = document.querySelector('#exam-prep-host-root');
          root.innerHTML = dashboard;
          root.hidden = false;
          return true;
        },
        isOpen: () => true
      };
    }, DASHBOARD);
    await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-materials.js') });
    const assert = (value, message) => { if (!value) throw new Error(message); };
    const open = async () => {
      await page.waitForSelector('[data-ep-materials-open="P1"]');
      await page.click('[data-ep-materials-open="P1"]');
      await page.waitForSelector('[data-ep-materials-screen]');
    };
    const settle = () => page.waitForTimeout(35);

    // Leaving during a pending read must not repaint the dashboard when it completes.
    await open();
    await page.click('[data-ep-materials-back]');
    await page.waitForSelector('.ep-live-dashboard-intro');
    await page.evaluate(result => window.__requests[0].resolve(result), RESULT);
    await settle();
    assert(await page.locator('[data-ep-materials-screen]').count() === 0, 'stale response replaced dashboard after Back');
    assert(await page.locator('.ep-live-dashboard-intro').count() === 1, 'dashboard lost after Back');

    // An unexpected rejection must release busy, show a recoverable error, and permit another open.
    await open();
    await page.evaluate(() => window.__requests[1].reject(new Error('simulated offline read')));
    await page.waitForSelector('[data-ep-materials-screen] [role="alert"]');
    assert(await page.locator('[data-ep-materials-back]').count() === 1, 'fetch failure left no route back');
    await page.click('[data-ep-materials-back]');
    await open();
    await page.evaluate(result => window.__requests[2].resolve(result), RESULT);
    await page.waitForSelector('[data-ep-material="cambridge_9709_syllabus_2026_2027"]');
    assert(await page.locator('[data-ep-materials-external]').count() === 1, 'verified official external link lost');
    assert(errors.length === 0, `unhandled promise rejection: ${errors.join('; ')}`);

    // The first in-flight request must neither paint nor unlock a later request.
    await page.click('[data-ep-materials-back]');
    await open();
    await page.click('[data-ep-materials-back]');
    await open();
    await page.evaluate(result => window.__requests[3].resolve(result), RESULT);
    await settle();
    assert(await page.locator('[data-ep-material]').count() === 0, 'superseded request painted over newer loading screen');
    await page.evaluate(result => window.__requests[4].resolve(result), RESULT);
    await page.waitForSelector('[data-ep-material="cambridge_9709_syllabus_2026_2027"]');
    assert(await page.locator('[data-ep-materials-back]').count() === 1, 'current request failed to complete');

    // A revoked Core permission must not allow a response to paint content.
    await page.click('[data-ep-materials-back]');
    await open();
    await page.evaluate(() => { window.iClubExamPrepHostInternal.lastCapabilities.coreAccess = false; });
    await page.evaluate(result => window.__requests[5].resolve(result), RESULT);
    await settle();
    assert(await page.locator('[data-ep-material]').count() === 0, 'content painted after access revocation');

    // Isolated interaction-polish route replaces loading with a held dashboard clone.
    const held = await browser.newPage();
    held.on('pageerror', error => errors.push(error.message));
    await held.route('http://iclub.test/', route => route.fulfill({
      status: 200, contentType: 'text/html',
      body: `<!doctype html><html lang="en"><body><div id="exam-prep-host-root">${DASHBOARD}</div></body></html>`
    }));
    await held.goto('http://iclub.test/');
    await held.evaluate(() => {
      window.__requests = [];
      window.iClubExamPrepHostInternal = {
        lastCapabilities: { coreAccess: true, killSwitch: false, rolloutState: 'controlled_beta' },
        api: { materialsLibrary: language => new Promise((resolve, reject) => window.__requests.push({ resolve, reject, language })) }
      };
      window.iClubExamPrep = { open: async () => true, isOpen: () => true };
    });
    await held.addScriptTag({ path: path.resolve('exam-prep/exam-prep-materials.js') });
    await held.addScriptTag({ path: path.resolve('exam-prep/exam-prep-interaction-polish.js') });
    await held.waitForSelector('[data-ep-materials-open="P1"]');
    await held.click('[data-ep-materials-open="P1"]');
    await held.waitForSelector('[data-ep-transition-hold="1"]');
    await held.evaluate(result => window.__requests[0].resolve(result), RESULT);
    await held.waitForSelector('[data-ep-material="cambridge_9709_syllabus_2026_2027"]');
    assert(errors.length === 0, `browser errors: ${errors.join('; ')}`);
    assert((await page.evaluate(() => window.__requests.length)) === 6, 'unexpected extra requests or writes');
    console.log('Exam Prep materials async navigation, rejection, access and held-view: PASS');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
