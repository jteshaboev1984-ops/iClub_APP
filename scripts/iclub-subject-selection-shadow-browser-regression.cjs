const path = require('path');
const { chromium } = require('playwright');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

const SUBJECTS = [
  { subject_key:'mathematics', type:'main' },
  { subject_key:'biology', type:'main' },
  { subject_key:'chemistry', type:'main' },
  { subject_key:'economics', type:'main' },
  { subject_key:'informatics', type:'main' }
];

function planConfig(plan) {
  if (plan === 'pro') return { study_subject_limit:null, all_available_subjects:true, competitive_subject_limit:2 };
  if (plan === 'plus') return { study_subject_limit:3, all_available_subjects:false, competitive_subject_limit:2 };
  return { study_subject_limit:1, all_available_subjects:false, competitive_subject_limit:1 };
}

async function buildPage(browser, { width, height, lang, plan, visible = true }) {
  const page = await browser.newPage({ viewport:{ width, height } });
  const errors = [];
  page.on('pageerror', (error) => errors.push(String(error?.stack || error)));

  await page.setContent(`
    <!doctype html>
    <html lang="${lang}">
      <body>
        <div id="app" class="app-shell">
          <main id="main" class="main">
            <section id="view-profile" class="view is-active" data-view="profile">
              <div class="content">
                <div id="profile-plan" class="profile-screen is-active">
                  <div id="profile-subject-access-entry" class="profile-section iclub-subject-access-entry" hidden>
                    <div class="profile-row-list">
                      <button class="profile-row" type="button" data-action="profile-subject-access">
                        <div class="profile-row-mid">
                          <div class="profile-row-title" data-subject-access-entry-title></div>
                          <div class="muted small" data-subject-access-entry-sub></div>
                        </div>
                        <div class="profile-row-right">›</div>
                      </button>
                    </div>
                  </div>
                </div>

                <div id="profile-subject-access" class="profile-screen is-active">
                  <div class="iclub-subject-access-screen">
                    <div class="iclub-subject-access-intro">
                      <div class="h1" data-subject-access-title></div>
                      <div class="muted" data-subject-access-subtitle></div>
                    </div>
                    <div class="iclub-subject-access-beta">
                      <strong data-subject-access-beta-title></strong>
                      <span data-subject-access-beta-text></span>
                    </div>
                    <div class="iclub-subject-access-plan" data-subject-access-plan></div>
                    <div class="iclub-subject-access-unavailable" data-subject-access-unavailable hidden></div>
                    <div data-subject-access-body hidden>
                      <section class="iclub-subject-access-section" data-subject-access-study></section>
                      <section class="iclub-subject-access-section" data-subject-access-competitive></section>
                    </div>
                  </div>
                </div>
              </div>
            </section>
          </main>
        </div>
        <div id="toast" class="toast" role="status"></div>
      </body>
    </html>
  `);

  await page.addStyleTag({ path:path.resolve('style.css') });
  await page.addStyleTag({ path:path.resolve('subject-access-ui.css') });

  await page.evaluate(({ lang, plan, visible, subjects }) => {
    window.__lang = lang;
    window.__plan = plan;
    window.__visible = visible;
    window.__subjects = subjects;
    window.__selections = new Map();
    window.__writes = [];
    window.__writeDelayMs = 0;
    window.__nextWriteFailure = "";

    window.i18n = { getLang: () => window.__lang };

    const config = () => {
      if (window.__plan === 'pro') {
        return { study_subject_limit:null, all_available_subjects:true, competitive_subject_limit:2 };
      }
      if (window.__plan === 'plus') {
        return { study_subject_limit:3, all_available_subjects:false, competitive_subject_limit:2 };
      }
      return { study_subject_limit:1, all_available_subjects:false, competitive_subject_limit:1 };
    };

    const snapshot = () => {
      const cfg = config();
      const selections = Array.from(window.__selections.entries()).map(([subject_key, value]) => ({
        subject_key,
        study_selected:value.study === true,
        competitive_selected:value.competitive === true
      }));
      return {
        visible:window.__visible,
        reason:window.__visible ? null : 'subject_selection_disabled',
        plan_code:window.__plan,
        study_subject_limit:cfg.study_subject_limit,
        all_available_subjects:cfg.all_available_subjects,
        competitive_subject_limit:cfg.competitive_subject_limit,
        study_selected_count:selections.filter(x => x.study_selected).length,
        competitive_selected_count:selections.filter(x => x.competitive_selected).length,
        subjects:window.__subjects,
        selections,
        migration_state:'legacy_preserved',
        is_school_student:true,
        access_unchanged:true,
        ui_version:'subject_selection_shadow_v1'
      };
    };

    window.sb = {
      rpc: async (name, args) => {
        if (name === 'get_iclub_subject_selection_bootstrap_v1') {
          return { data:structuredClone(snapshot()), error:null };
        }

        if (name === 'choose_iclub_my_free_subject_v2') {
          const key = String(args?.p_subject_key || '');
          const delayMs = Number(window.__writeDelayMs || 0);
          if (delayMs) await new Promise(resolve => setTimeout(resolve,delayMs));
          if (window.__nextWriteFailure) {
            const reason=window.__nextWriteFailure;
            window.__nextWriteFailure='';
            return { data:{ok:false,reason},error:null };
          }
          if (window.__plan !== 'free' || !window.__subjects.some(s=>s.subject_key===key && s.type==='main')) {
            return { data:{ok:false,reason:'subject_unavailable'},error:null };
          }
          window.__selections.clear();
          window.__selections.set(key,{study:true,competitive:true});
          window.__writes.push({key,nextStudy:true,nextCompetitive:true});
          return { data:{ok:true,subject_key:key,study_selected:true,competitive_selected:true,access_unchanged:true},error:null };
        }
        if (name !== 'set_iclub_my_subject_slot_v1') {
          return { data:null, error:{ message:'unexpected rpc ' + name } };
        }

        const key = String(args?.p_subject_key || '');
        const nextStudy = args?.p_study_selected === true;
        const delayMs = Number(window.__writeDelayMs || 0);
        if (delayMs > 0) {
          await new Promise((resolve) => setTimeout(resolve, delayMs));
        }

        if (window.__nextWriteFailure) {
          const reason = String(window.__nextWriteFailure);
          window.__nextWriteFailure = "";
          return { data:{ ok:false, reason }, error:null };
        }
        const nextCompetitive = args?.p_competitive_selected === true;
        const cfg = config();
        const current = window.__selections.get(key) || { study:false, competitive:false };

        const studyUsedOther = Array.from(window.__selections.entries())
          .filter(([k,v]) => k !== key && v.study)
          .length;
        const compUsedOther = Array.from(window.__selections.entries())
          .filter(([k,v]) => k !== key && v.competitive)
          .length;

        if (nextCompetitive && !nextStudy) {
          return { data:{ ok:false, reason:'competitive_requires_study' }, error:null };
        }

        if (nextStudy && cfg.study_subject_limit !== null && !current.study && studyUsedOther >= cfg.study_subject_limit) {
          return { data:{ ok:false, reason:'study_subject_limit_reached' }, error:null };
        }

        if (nextCompetitive && !current.competitive && compUsedOther >= cfg.competitive_subject_limit) {
          return { data:{ ok:false, reason:'competitive_subject_limit_reached' }, error:null };
        }

        window.__writes.push({ key, nextStudy, nextCompetitive });
        window.__selections.set(key, { study:nextStudy, competitive:nextCompetitive });

        return {
          data:{
            ok:true,
            subject_key:key,
            study_selected:nextStudy,
            competitive_selected:nextCompetitive,
            access_unchanged:true
          },
          error:null
        };
      },
      auth:{
        onAuthStateChange: () => ({ data:{ subscription:{ unsubscribe(){} } } })
      }
    };
  }, { lang, plan, visible, subjects:SUBJECTS });

  await page.addScriptTag({ path:path.resolve('subject-access-ui.js') });
  await page.waitForTimeout(100);
  return { page, errors };
}

async function toggle(page, subjectKey, mode) {
  const rowSelector = '.iclub-subject-access-row[data-subject-key="' + subjectKey + '"][data-selection-mode="' + mode + '"]';
  const row = page.locator(rowSelector);
  const input = row.locator('input');
  const control = row.locator('.iclub-subject-access-switch');
  assert(await input.count() === 1, 'missing toggle ' + subjectKey + '/' + mode);
  assert(!(await input.isDisabled()), 'attempted to toggle disabled control ' + subjectKey + '/' + mode);
  await control.click();
  await page.waitForTimeout(80);
}

async function runHidden(browser) {
  const { page, errors } = await buildPage(browser, {
    width:390,height:844,lang:'ru',plan:'free',visible:false
  });
  assert(await page.locator('#profile-subject-access-entry').isHidden(), 'subject entry visible while UI disabled');
  assert(await page.locator('[data-subject-access-body]').isHidden(), 'subject body visible while UI disabled');
  assert(errors.length === 0, 'hidden-state page errors: ' + JSON.stringify(errors));
  await page.close();
}

async function runFree(browser) {
  const { page, errors } = await buildPage(browser, {
    width:390,height:844,lang:'ru',plan:'free',visible:true
  });
  await page.waitForFunction(() => !document.getElementById('profile-subject-access-entry').hidden);
  assert((await page.locator('[data-subject-access-entry-sub]').textContent()).includes('1'),
    'Free single-subject summary missing');
  assert((await page.locator('[data-subject-access-competitive] input').count()) === 0,
    'Free incorrectly asks to choose Competitive a second time');
  assert((await page.locator('[data-subject-access-competitive]').textContent()).includes('автоматически'),
    'Free automatic Competitive explanation is missing');

  await page.evaluate(() => { window.__writeDelayMs = 180; });
  const mathControl = page.locator('.iclub-subject-access-row[data-subject-key="mathematics"][data-selection-mode="study"] .iclub-subject-access-switch');
  await mathControl.click();
  await page.waitForTimeout(25);
  assert(await page.locator('.iclub-subject-access-row[data-subject-key="biology"][data-selection-mode="study"] input').isDisabled(),
    'Free rapid tap was not locked');
  await page.waitForTimeout(240);
  await page.evaluate(() => { window.__writeDelayMs = 0; });
  assert(await page.locator('.iclub-subject-access-row[data-subject-key="mathematics"][data-selection-mode="study"] input').isChecked(),
    'Free chosen subject not selected');
  assert(await page.locator('.iclub-subject-access-row[data-subject-key="mathematics"][data-selection-mode="study"] input').isDisabled(),
    'Free can deselect their only subject');
  const first = await page.evaluate(() => Array.from(window.__selections.entries()));
  assert(first.length === 1 && first[0][1].study && first[0][1].competitive,
    'Free selection failed to pair study and competition');

  // Failure while replacing the Free subject must leave the old choice intact.
  await page.evaluate(() => { window.__nextWriteFailure = 'network'; });
  await toggle(page,'biology','study');
  const failed = await page.evaluate(() => Array.from(window.__selections.entries()));
  assert(failed.length === 1 && failed[0][0] === 'mathematics',
    'Failed Free subject swap erased previous subject');

  await toggle(page,'biology','study');
  const after = await page.evaluate(() => Array.from(window.__selections.entries()));
  assert(after.length === 1 && after[0][0] === 'biology'
    && after[0][1].study && after[0][1].competitive,
    'Free one-click subject switch was not atomic');

  const writes = await page.evaluate(() => window.__writes);
  assert(writes.length===2 && writes.every(x => x.nextStudy && x.nextCompetitive),
    'Free selection made duplicate or partial writes');
  const metrics = await page.evaluate(() => ({
    scrollWidth:document.documentElement.scrollWidth,
    clientWidth:document.documentElement.clientWidth
  }));
  assert(metrics.scrollWidth <= metrics.clientWidth + 1,
    'Free 390px screen has horizontal overflow');
  assert(errors.length === 0, 'Free page errors: ' + JSON.stringify(errors));
  await page.screenshot({ path:'artifacts/subject-selection-free-390.png', fullPage:true });
  await page.close();
}

async function runPlus(browser) {
  const { page, errors } = await buildPage(browser, {
    width:320,height:720,lang:'uz',plan:'plus',visible:true
  });

  await toggle(page,'mathematics','study');
  await toggle(page,'biology','study');
  await toggle(page,'chemistry','study');

  const economicsStudy = page.locator('.iclub-subject-access-row[data-subject-key="economics"][data-selection-mode="study"] input');
  assert(await economicsStudy.isDisabled(), 'Plus fourth study subject remained enabled');

  await toggle(page,'mathematics','competitive');
  await toggle(page,'biology','competitive');

  const chemistryCompetitive = page.locator('.iclub-subject-access-row[data-subject-key="chemistry"][data-selection-mode="competitive"] input');
  assert(await chemistryCompetitive.isDisabled(), 'Plus third Competitive subject remained enabled');

  const counts = await page.locator('.iclub-subject-access-count').allTextContents();
  assert(counts.some(x => x.includes('3 / 3')), 'Plus study counter mismatch');
  assert(counts.some(x => x.includes('2 / 2')), 'Plus Competitive counter mismatch');

  const metrics = await page.evaluate(() => ({
    scrollWidth:document.documentElement.scrollWidth,
    clientWidth:document.documentElement.clientWidth
  }));
  assert(metrics.scrollWidth <= metrics.clientWidth + 1, 'Plus 320px screen has horizontal overflow');
  assert(errors.length === 0, 'Plus page errors: ' + JSON.stringify(errors));

  await page.screenshot({ path:'artifacts/subject-selection-plus-320.png', fullPage:true });
  await page.close();
}

async function runPro(browser) {
  const { page, errors } = await buildPage(browser, {
    width:390,height:844,lang:'en',plan:'pro',visible:true
  });

  const included = page.locator('.iclub-subject-access-row[data-selection-mode="included"]');
  assert(await included.count() === SUBJECTS.length, 'Pro does not show every active subject as included');

  await toggle(page,'mathematics','competitive');
  await toggle(page,'economics','competitive');

  const third = page.locator('.iclub-subject-access-row[data-subject-key="biology"][data-selection-mode="competitive"] input');
  assert(await third.isDisabled(), 'Pro third Competitive subject remained enabled');

  const studySwitches = page.locator('.iclub-subject-access-row[data-selection-mode="study"] input');
  assert(await studySwitches.count() === 0, 'Pro incorrectly asks learner to select study slots');

  assert((await page.locator('[data-subject-access-plan]').textContent()).includes('Pro'), 'Pro plan badge missing');
  assert(errors.length === 0, 'Pro page errors: ' + JSON.stringify(errors));

  await page.screenshot({ path:'artifacts/subject-selection-pro-390.png', fullPage:true });
  await page.close();
}

(async () => {
  const browser = await chromium.launch({ headless:true });
  try {
    await runHidden(browser);
    await runFree(browser);
    await runPlus(browser);
    await runPro(browser);
    console.log('iClub beta subject-selection browser regression: GREEN');
  } finally {
    await browser.close();
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});