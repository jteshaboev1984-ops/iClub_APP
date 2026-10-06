const path = require('path');
const { chromium } = require('playwright');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

async function runViewport(browser, width, height) {
  const page = await browser.newPage({ viewport: { width, height } });
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(String(error?.stack || error?.message || error)));

  await page.setContent(`
    <!doctype html>
    <html>
      <head>
        <base href="http://127.0.0.1:4173/">
      </head>
      <body>
        <main id="main" class="main">
          <section id="view-home" class="view is-active" data-view="home"><div class="content">Home</div></section>
          <section id="view-registration" class="view" data-view="registration"><div class="content">Registration</div></section>
          <section id="view-certificate-verify" class="view" data-view="certificate-verify"><div class="content">Verify</div></section>
          <section id="view-courses" class="view" data-view="courses">
            <section id="courses-tour-quiz" class="stack-screen" data-screen="tour-quiz"></section>
          </section>
        </main>
        <nav id="tabbar" class="tabbar">
          <button class="tab">Home</button>
          <button class="tab">Study</button>
          <button class="tab">Ratings</button>
          <button class="tab">Profile</button>
        </nav>
        <div id="toast" class="toast" role="status"></div>
        <div id="modal-root" class="modal-root" aria-hidden="false">
          <div class="modal-backdrop"><div class="modal-card">Modal</div></div>
        </div>
      </body>
    </html>
  `);

  await page.addStyleTag({ path: path.resolve('style.css') });
  await page.addStyleTag({ path: path.resolve('global-ai-ui.css') });

  await page.evaluate(() => {
    window.i18n = { getLang: () => 'ru' };
    window.__globalAiBootstrap = {
      visible: true,
      assessment_blocked: false,
      reason: null,
      locale: 'ru',
      ui_version: 'global_ai_shell_v1'
    };
    window.__globalAiRpcCalls = [];
    window.sb = {
      rpc: async (name) => {
        window.__globalAiRpcCalls.push(name);
        if (name !== 'get_iclub_ai_ui_bootstrap_v1') {
          return { data: null, error: { message: 'unexpected RPC' } };
        }
        return { data: structuredClone(window.__globalAiBootstrap), error: null };
      },
      auth: {
        onAuthStateChange: () => ({ data: { subscription: { unsubscribe() {} } } })
      }
    };
  });

  await page.addScriptTag({ path: path.resolve('global-ai-ui.js') });

  await page.waitForSelector('#iclub-global-ai-mark', { state: 'visible' });
  await page.waitForTimeout(50);

  let metrics = await page.evaluate(() => {
    const rect = (el) => {
      const r = el.getBoundingClientRect();
      return { x: r.x, y: r.y, width: r.width, height: r.height, right: r.right, bottom: r.bottom };
    };
    const mark = document.getElementById('iclub-global-ai-mark');
    const tab = document.getElementById('tabbar');
    const root = document.getElementById('iclub-global-ai-root');
    const modal = document.querySelector('.modal-backdrop');
    const toast = document.getElementById('toast');
    return {
      roots: document.querySelectorAll('#iclub-global-ai-root').length,
      mark: rect(mark),
      tab: rect(tab),
      rootZ: Number(getComputedStyle(root).zIndex || 0),
      modalZ: Number(getComputedStyle(modal).zIndex || 0),
      toastZ: Number(getComputedStyle(toast).zIndex || 0),
      rpcCalls: [...window.__globalAiRpcCalls]
    };
  });

  assert(metrics.roots === 1, `expected one Global AI root at ${width}px, got ${metrics.roots}`);
  assert(metrics.mark.width >= 44 && metrics.mark.height >= 44, `AI mark touch target below 44px at ${width}px`);
  assert(metrics.mark.bottom <= metrics.tab.y, `AI mark overlaps tabbar at ${width}px`);
  assert(metrics.rootZ < metrics.toastZ, `AI shell must stay below toast at ${width}px`);
  assert(metrics.rootZ < metrics.modalZ, `AI shell must stay below modal at ${width}px`);
  assert(metrics.rpcCalls.includes('get_iclub_ai_ui_bootstrap_v1'), 'shell did not use server UI bootstrap');

  await page.click('#iclub-global-ai-mark');
  await page.waitForSelector('#iclub-global-ai-panel', { state: 'visible' });

  const panelMetrics = await page.evaluate(() => {
    const p = document.getElementById('iclub-global-ai-panel').getBoundingClientRect();
    const t = document.getElementById('tabbar').getBoundingClientRect();
    return {
      left: p.left,
      right: p.right,
      top: p.top,
      bottom: p.bottom,
      width: p.width,
      height: p.height,
      tabTop: t.top,
      viewportWidth: innerWidth,
      viewportHeight: innerHeight
    };
  });

  assert(panelMetrics.left >= 0 && panelMetrics.right <= panelMetrics.viewportWidth, `AI panel overflows horizontally at ${width}px`);
  assert(panelMetrics.top >= 0 && panelMetrics.bottom <= panelMetrics.viewportHeight, `AI panel overflows viewport at ${width}px`);
  assert(panelMetrics.bottom <= panelMetrics.tabTop, `AI panel overlaps bottom nav at ${width}px`);

  // Protected Exam Prep session must collapse immediately and announce once.
  await page.evaluate(() => {
    window.dispatchEvent(new CustomEvent('iclub:exam-prep-session', {
      detail: {
        session: {
          session_id: 'synthetic-protected',
          session_type: 'diagnostic',
          status: 'active'
        }
      }
    }));
  });

  await page.waitForFunction(() => {
    const panel = document.getElementById('iclub-global-ai-panel');
    return panel?.hidden === true
      && document.getElementById('iclub-global-ai-mark')?.classList.contains('is-assessment-blocked');
  });

  let toastText = await page.locator('#toast').textContent();
  assert(
    toastText.includes('AI Tutor свёрнут на время экзамена'),
    `protected-session collapse toast missing at ${width}px: ${toastText}`
  );

  await page.click('#iclub-global-ai-mark');
  toastText = await page.locator('#toast').textContent();
  assert(
    toastText.includes('AI Tutor недоступен во время экзамена'),
    `blocked mark boundary message missing at ${width}px: ${toastText}`
  );

  // Ending the protected Exam Prep session restores the mark but never auto-opens chat.
  await page.evaluate(() => {
    window.dispatchEvent(new CustomEvent('iclub:exam-prep-session-ended', {
      detail: { sessionId: 'synthetic-protected' }
    }));
  });
  await page.waitForFunction(() => !document.getElementById('iclub-global-ai-mark')?.classList.contains('is-assessment-blocked'));
  assert(await page.locator('#iclub-global-ai-panel').isHidden(), 'chat auto-opened after assessment end');

  // Tour screen activation uses the same collapse UX.
  await page.click('#iclub-global-ai-mark');
  await page.waitForSelector('#iclub-global-ai-panel', { state: 'visible' });
  await page.evaluate(() => document.getElementById('courses-tour-quiz').classList.add('is-active'));
  await page.waitForFunction(() => {
    const panel = document.getElementById('iclub-global-ai-panel');
    return panel?.hidden === true
      && document.getElementById('iclub-global-ai-mark')?.classList.contains('is-assessment-blocked');
  });

  await page.evaluate(() => document.getElementById('courses-tour-quiz').classList.remove('is-active'));
  await page.waitForFunction(() => !document.getElementById('iclub-global-ai-mark')?.classList.contains('is-assessment-blocked'));

  // Sensitive/public views hide the shell without destroying the reusable singleton.
  await page.evaluate(() => {
    document.getElementById('view-home').classList.remove('is-active');
    document.getElementById('view-registration').classList.add('is-active');
  });
  await page.waitForFunction(() => document.getElementById('iclub-global-ai-root')?.hidden === true);

  await page.evaluate(() => {
    document.getElementById('view-registration').classList.remove('is-active');
    document.getElementById('view-home').classList.add('is-active');
  });
  await page.waitForFunction(() => document.getElementById('iclub-global-ai-root')?.hidden === false);

  // Repeated bootstrap refreshes must never duplicate the root.
  await page.evaluate(async () => {
    await window.iClubGlobalAiShell.refresh();
    await window.iClubGlobalAiShell.refresh();
  });
  const rootCount = await page.locator('#iclub-global-ai-root').count();
  assert(rootCount === 1, `refresh duplicated Global AI root at ${width}px`);

  assert(pageErrors.length === 0, `page errors at ${width}px: ${JSON.stringify(pageErrors)}`);
  await page.screenshot({ path: `artifacts/global-ai-shell-${width}.png`, fullPage: true });
  await page.close();
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    await runViewport(browser, 390, 844);
    await runViewport(browser, 320, 720);
    console.log('Global AI learner shell browser regression: GREEN');
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
