const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const flowSource = fs.readFileSync(path.resolve('exam-prep/exam-prep-learner-flow-ux.js'), 'utf8');
  if (!flowSource.includes('backPreparation: "К подготовке"') || !flowSource.includes('backPreparationLong: "Вернуться к подготовке"')) {
    throw new Error('Russian overview navigation labels are no longer the expected learner-facing labels');
  }

  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
    await page.setContent(`<!doctype html><html lang="ru"><body>
      <button id="topbar-back" type="button">Назад</button>
      <div id="exam-prep-host-root"><section class="ep-host-shell ep-live">
        <div class="ep-live-card"><div class="ep-live-head">
          <strong>P1 · Недельный план</strong>
          <button hidden aria-hidden="true" data-ep-live-dashboard type="button">К подготовке</button>
        </div><div class="ep-live-plan-item">Задание</div></div>
      </section></div>
    </body></html>`);
    await page.evaluate(() => {
      window.__planBack = 0;
      window.__outerBack = 0;
      window.__recovered = 0;
      window.iClubExamPrepHostInternal = {
        lastCapabilities: { coreAccess: true, killSwitch: false, rolloutState: 'controlled_beta' },
        api: {}
      };
      window.iClubExamPrep = Object.freeze({
        liveFlowVersion: 'test-live',
        back() { window.__outerBack += 1; return true; },
        open: async () => true,
        isOpen: () => true
      });
      const root = document.querySelector('#exam-prep-host-root');
      root.querySelector('[data-ep-live-dashboard]').addEventListener('click', () => {
        window.__planBack += 1;
        root.innerHTML = '<section class="ep-host-shell ep-live"><div class="ep-live-grid">Подготовка P1 и P5</div></section>';
      });
    });
    await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-wave1-ux.js') });
    await page.waitForFunction(() => window.iClubExamPrep?.wave1UxVersion === 'wave1ux3');
    await page.click('#topbar-back');
    const nav = await page.evaluate(() => ({
      plan: window.__planBack, outer: window.__outerBack,
      dashboard: Boolean(document.querySelector('#exam-prep-host-root .ep-live-grid'))
    }));
    if (nav.plan !== 1 || nav.outer !== 0 || !nav.dashboard) {
      throw new Error('Renamed plan-back must return to Exam Prep dashboard, never Mathematics');
    }

    await page.evaluate(() => {
      const root = document.querySelector('#exam-prep-host-root');
      root.innerHTML = '<section class="ep-host-shell ep-live"><div class="ep-live-error">Не удалось выполнить действие. Попробуйте ещё раз.</div><button data-ep-live-home type="button">К подготовке</button></section>';
      root.querySelector('[data-ep-live-home]').addEventListener('click', () => {
        window.__recovered += 1;
        root.innerHTML = '<section class="ep-host-shell ep-live"><div class="ep-live-grid">Подготовка P1 и P5</div></section>';
      });
    });
    await page.waitForFunction(() => window.__recovered === 1 && Boolean(document.querySelector('#exam-prep-host-root .ep-live-grid')), { timeout: 5000 });
    const recovered = await page.evaluate(() => ({ recovered: window.__recovered, outer: window.__outerBack }));
    if (recovered.recovered !== 1 || recovered.outer !== 0) {
      throw new Error('Transient-error recovery must occur once and stay inside Exam Prep');
    }
    console.log('Exam Prep renamed overview and transient-error route: PASS (mock DOM, no learner writes)');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exit(1); });
