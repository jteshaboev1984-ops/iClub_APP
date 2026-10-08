const path = require('path');
const { chromium } = require('playwright');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

async function runLocale(browser, lang) {
  const page = await browser.newPage({ viewport:{ width:390, height:844 } });
  const errors = [];
  page.on('pageerror', (err) => errors.push(String(err?.stack || err)));

  await page.setContent(`
    <!doctype html>
    <html lang="${lang}">
      <body>
        <div id="toast" class="toast"></div>
      </body>
    </html>
  `);

  await page.evaluate((lang) => {
    window.__lang = lang;
    window.__rpcCalls = [];
    window.__mode = 'disabled';
    window.i18n = { getLang: () => window.__lang };
    window.sb = {
      rpc: async (name,args) => {
        if (name !== 'get_iclub_my_subject_access_v1') {
          return { data:null, error:{ message:'unexpected rpc' } };
        }

        window.__rpcCalls.push({ name, args:structuredClone(args) });
        const subject = String(args?.p_subject_key || '');
        const intent = String(args?.p_intent || 'study');

        if (window.__mode === 'network_error') {
          return { data:null, error:{ message:'offline' } };
        }

        if (window.__mode === 'disabled') {
          return { data:{ allowed:true, enforced:false, reason:'access_preview_disabled' }, error:null };
        }

        if (intent === 'legacy_toggle') {
          return { data:{ allowed:false, enforced:true, reason:'manage_in_plan_subjects', plan_code:'free' }, error:null };
        }

        if (intent === 'competitive') {
          if (subject === 'mathematics') {
            return { data:{ allowed:true, enforced:true, reason:'competitive_selected', plan_code:'free' }, error:null };
          }
          return { data:{ allowed:false, enforced:true, reason:'competitive_not_in_plan', plan_code:'free' }, error:null };
        }

        if (subject === 'mathematics') {
          return { data:{ allowed:true, enforced:true, reason:'subject_selected', plan_code:'free' }, error:null };
        }

        if (subject === 'biology') {
          return { data:{ allowed:false, enforced:true, reason:'subject_selection_required', plan_code:'free' }, error:null };
        }

        return { data:{ allowed:false, enforced:true, reason:'subject_not_in_plan', plan_code:'free' }, error:null };
      }
    };
  },lang);

  await page.addScriptTag({ path:path.resolve('commercial-access-ui.js') });

  // Default OFF is invisible and non-blocking.
  let ok = await page.evaluate(() => window.iClubCommercialAccessUI.guardStudy('biology'));
  assert(ok === true, 'disabled preview unexpectedly blocked Study');
  assert((await page.locator('#toast').textContent()) === '', 'disabled preview showed a toast');

  // Enforcement ON: selected study allowed.
  await page.evaluate(() => {
    window.__mode = 'enforced';
    window.iClubCommercialAccessUI.invalidate();
  });
  ok = await page.evaluate(() => window.iClubCommercialAccessUI.guardStudy('mathematics'));
  assert(ok === true, 'selected canary study subject was blocked');

  // Missing selection is blocked with a learner-facing localized explanation.
  ok = await page.evaluate(() => window.iClubCommercialAccessUI.guardStudy('biology'));
  assert(ok === false, 'missing subject selection did not block canary Study');
  let toast = await page.locator('#toast').textContent();
  if (lang === 'ru') assert(toast.includes('Профиль') && toast.includes('Предметы тарифа'), 'RU setup message mismatch');
  if (lang === 'uz') assert(toast.includes('Profil') && toast.includes('Tarif'), 'UZ setup message mismatch');
  if (lang === 'en') assert(toast.includes('Profile') && toast.includes('Plan subjects'), 'EN setup message mismatch');

  // Unselected subject gets the plan-specific explanation.
  await page.evaluate(() => window.iClubCommercialAccessUI.invalidate('chemistry'));
  ok = await page.evaluate(() => window.iClubCommercialAccessUI.guardStudy('chemistry'));
  assert(ok === false, 'unselected canary subject escaped Study guard');

  // Competitive access is independent from Study selection.
  ok = await page.evaluate(() => window.iClubCommercialAccessUI.guardCompetitive('chemistry'));
  assert(ok === false, 'unselected Competitive subject escaped guard');
  toast = await page.locator('#toast').textContent();
  if (lang === 'ru') assert(toast.includes('Competitive'), 'RU Competitive message mismatch');
  if (lang === 'uz') assert(toast.includes('Competitive'), 'UZ Competitive message mismatch');
  if (lang === 'en') assert(toast.includes('Competitive'), 'EN Competitive message mismatch');

  ok = await page.evaluate(() => window.iClubCommercialAccessUI.guardCompetitive('mathematics'));
  assert(ok === true, 'selected Competitive subject was blocked');

  // Legacy catalog toggles are redirected to Plan subjects while canary enforcement is active.
  ok = await page.evaluate(() => window.iClubCommercialAccessUI.guardLegacyToggle('mathematics'));
  assert(ok === false, 'legacy subject toggle remained writable in canary preview');

  // Cache must avoid duplicate requests until a selector change invalidates the subject.
  await page.evaluate(() => {
    window.iClubCommercialAccessUI.invalidate();
    window.__rpcCalls.length = 0;
  });
  await page.evaluate(() => window.iClubCommercialAccessUI.checkStudy('mathematics'));
  await page.evaluate(() => window.iClubCommercialAccessUI.checkStudy('mathematics'));
  let calls = await page.evaluate(() => window.__rpcCalls.length);
  assert(calls === 1, 'subject access cache did not deduplicate repeated checks');

  await page.evaluate(() => {
    window.dispatchEvent(new CustomEvent('iclub:subject-selection-changed', {
      detail:{ subjectKey:'mathematics' }
    }));
  });
  await page.evaluate(() => window.iClubCommercialAccessUI.checkStudy('mathematics'));
  calls = await page.evaluate(() => window.__rpcCalls.length);
  assert(calls === 2, 'subject selection change did not invalidate access cache');

  // Preview guard failure is fail-open so a beta service incident cannot lock Study.
  await page.evaluate(() => {
    window.__mode = 'network_error';
    window.iClubCommercialAccessUI.invalidate();
  });
  ok = await page.evaluate(() => window.iClubCommercialAccessUI.guardStudy('chemistry'));
  assert(ok === true, 'preview RPC failure locked learner Study');

  assert(errors.length === 0, `page errors for ${lang}: ${JSON.stringify(errors)}`);
  await page.close();
}

(async () => {
  const browser = await chromium.launch({ headless:true });
  try {
    for (const lang of ['ru','uz','en']) {
      await runLocale(browser,lang);
    }
    console.log('iClub canary subject access browser regression: GREEN');
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
