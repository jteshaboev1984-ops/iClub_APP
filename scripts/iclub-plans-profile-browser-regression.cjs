const path = require('path');
const { chromium } = require('playwright');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

const bootstraps = {
  hidden: {
    visible: false,
    reason: 'plans_ui_disabled',
    checkout_enabled: false,
    ui_version: 'iclub_plans_v1'
  },
  free: {
    visible: true,
    reason: null,
    current_plan_code: 'free',
    checkout_enabled: false,
    ui_version: 'iclub_plans_v1',
    plans: [
      { plan_code:'free', monthly_price_uzs:0, study_subject_limit:1, all_available_subjects:false, competitive_subject_limit:1, ai_generation_entitled:false, priority_support:false, early_access_entitled:false },
      { plan_code:'plus', monthly_price_uzs:35000, study_subject_limit:3, all_available_subjects:false, competitive_subject_limit:2, ai_generation_entitled:true, priority_support:false, early_access_entitled:false },
      { plan_code:'pro', monthly_price_uzs:50000, study_subject_limit:null, all_available_subjects:true, competitive_subject_limit:2, ai_generation_entitled:true, priority_support:true, early_access_entitled:true }
    ]
  }
};

async function buildPage(browser, width, height, lang, bootstrapKey) {
  const page = await browser.newPage({ viewport:{ width, height } });
  const errors = [];
  page.on('pageerror', (err) => errors.push(String(err?.stack || err)));

  await page.setContent(`
    <!doctype html>
    <html lang="${lang}">
      <body>
        <div id="app" class="app-shell">
          <header class="topbar">
            <button id="topbar-back" class="topbar-back" type="button">‹</button>
            <div class="topbar-titles"><div class="topbar-title">iClub</div><div class="topbar-sub">Smarter together</div></div>
          </header>
          <main id="main" class="main">
            <section id="view-profile" class="view is-active" data-view="profile">
              <div class="content">
                <div id="profile-main" class="profile-screen is-active">
                  <div id="profile-plan-entry" class="profile-section iclub-plan-entry" hidden>
                    <div class="profile-row-list">
                      <button class="profile-row" type="button" data-action="profile-plan">
                        <div class="profile-row-left"><div class="profile-row-ico">▣</div></div>
                        <div class="profile-row-mid">
                          <div class="profile-row-title" data-plan-row-title>Тариф</div>
                          <div class="muted small" data-plan-row-sub>Free</div>
                        </div>
                        <div class="profile-row-right">›</div>
                      </button>
                    </div>
                  </div>
                </div>

                <div id="profile-plan" class="profile-screen" hidden>
                  <div class="iclub-plan-screen">
                    <div class="iclub-plan-intro">
                      <div class="h1" data-plan-title></div>
                      <div class="muted" data-plan-subtitle></div>
                    </div>
                    <div class="iclub-plan-unavailable" data-plan-unavailable hidden></div>
                    <div data-plan-body hidden>
                      <div class="iclub-plan-cards" data-plan-cards></div>
                      <div class="iclub-plan-compare-wrap" data-plan-compare></div>
                      <div class="iclub-plan-info" data-plan-info></div>
                    </div>
                  </div>
                </div>
              </div>
            </section>
          </main>
          <nav id="tabbar" class="tabbar">
            <button class="tab">Home</button><button class="tab">Study</button><button class="tab">Ratings</button><button class="tab is-active">Profile</button>
          </nav>
        </div>
        <div id="toast" class="toast"></div>
      </body>
    </html>
  `);

  await page.addStyleTag({ path:path.resolve('style.css') });
  await page.addStyleTag({ path:path.resolve('plans-ui.css') });

  await page.evaluate(({ lang, bootstrap }) => {
    window.__lang = lang;
    window.__planBootstrap = bootstrap;
    window.i18n = { getLang: () => window.__lang };
    window.sb = {
      rpc: async (name) => {
        if (name !== 'get_iclub_plan_ui_bootstrap_v1') {
          return { data:null, error:{ message:'unexpected rpc' } };
        }
        return { data:structuredClone(window.__planBootstrap), error:null };
      },
      auth: {
        onAuthStateChange: () => ({ data:{ subscription:{ unsubscribe(){} } } })
      }
    };
  }, { lang, bootstrap:bootstraps[bootstrapKey] });

  await page.addScriptTag({ path:path.resolve('plans-ui.js') });
  await page.waitForTimeout(80);

  return { page, errors };
}

async function run(browser, width, height) {
  // Default dormant state: no visible plan row at all.
  {
    const { page, errors } = await buildPage(browser,width,height,'ru','hidden');
    assert(await page.locator('#profile-plan-entry').isHidden(), 'plan row visible while plans_ui is OFF');
    assert(errors.length === 0, `page errors in hidden state: ${JSON.stringify(errors)}`);
    await page.close();
  }

  for (const lang of ['ru','uz','en']) {
    const { page, errors } = await buildPage(browser,width,height,lang,'free');

    await page.waitForFunction(() => !document.getElementById('profile-plan-entry').hidden);
    const rowSub = await page.locator('[data-plan-row-sub]').textContent();
    assert(rowSub && /Free/i.test(rowSub), `Free row subtitle missing for ${lang}`);

    // Mini navigation harness mirrors the existing profile stack contract while
    // app.js integration itself is covered by the static contract.
    await page.evaluate(() => {
      const main = document.getElementById('profile-main');
      const plan = document.getElementById('profile-plan');
      const back = document.getElementById('topbar-back');
      document.querySelector('[data-action="profile-plan"]').addEventListener('click', () => {
        main.hidden = true;
        main.classList.remove('is-active');
        plan.hidden = false;
        plan.classList.add('is-active');
        window.iClubPlansUI.render();
      });
      back.addEventListener('click', () => {
        plan.hidden = true;
        plan.classList.remove('is-active');
        main.hidden = false;
        main.classList.add('is-active');
      });
    });

    await page.click('[data-action="profile-plan"]');
    await page.waitForFunction(() => !document.getElementById('profile-plan').hidden);

    assert(await page.locator('.iclub-plan-card').count() === 3, `expected 3 plan cards for ${lang}`);
    assert(await page.locator('.iclub-plan-card.is-pro').count() === 1, `Pro emphasis missing for ${lang}`);

    const text = await page.locator('#profile-plan').textContent();
    assert(text.includes('35') && text.includes('50'), `35k/50k prices missing for ${lang}`);
    assert(!/extended history|deeper analysis|early access|расширенная история|глубокий анализ|ранний доступ|kengaytirilgan tarix|chuqur tahlil|erta kirish/i.test(text),
      `unimplemented benefit shown for ${lang}`);

    const currentButtons = page.locator('.iclub-plan-cta:disabled');
    assert(await currentButtons.count() >= 3, 'checkout OFF should leave all plan CTAs non-operational');

    const metrics = await page.evaluate(() => {
      const body = document.documentElement.getBoundingClientRect();
      const cards = Array.from(document.querySelectorAll('.iclub-plan-card')).map(el => {
        const r = el.getBoundingClientRect();
        return { left:r.left,right:r.right,width:r.width,top:r.top,bottom:r.bottom };
      });
      const wrap = document.querySelector('.iclub-plan-compare-wrap');
      const wr = wrap.getBoundingClientRect();
      return {
        scrollWidth:document.documentElement.scrollWidth,
        clientWidth:document.documentElement.clientWidth,
        bodyLeft:body.left,
        bodyRight:body.right,
        cards,
        compare:{left:wr.left,right:wr.right,width:wr.width,scrollWidth:wrap.scrollWidth,clientWidth:wrap.clientWidth}
      };
    });

    assert(metrics.scrollWidth <= metrics.clientWidth + 1, `page-level horizontal overflow at ${width}px / ${lang}`);
    for (const card of metrics.cards) {
      assert(card.left >= -1 && card.right <= width + 1, `plan card overflow at ${width}px / ${lang}`);
      assert(card.width >= 240 || width <= 340, `plan card unexpectedly narrow at ${width}px / ${lang}`);
    }
    assert(metrics.compare.right <= width + 1, `comparison wrapper overflows page at ${width}px / ${lang}`);
    assert(metrics.compare.scrollWidth >= metrics.compare.clientWidth, 'comparison wrapper metrics invalid');

    await page.click('#topbar-back');
    assert(await page.locator('#profile-plan').isHidden(), `back did not hide plan screen for ${lang}`);
    assert(await page.locator('#profile-main').isVisible(), `back did not restore profile main for ${lang}`);

    if (lang === 'ru') {
      await page.click('[data-action="profile-plan"]');
      await page.screenshot({ path:`artifacts/iclub-plans-${width}.png`, fullPage:true });
    }

    assert(errors.length === 0, `page errors at ${width}px / ${lang}: ${JSON.stringify(errors)}`);
    await page.close();
  }
}

(async () => {
  const browser = await chromium.launch({ headless:true });
  try {
    await run(browser,390,844);
    await run(browser,320,720);
    console.log('iClub Free Plus Pro profile browser regression: GREEN');
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
