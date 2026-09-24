const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE_URL = process.env.ICLUB_BASE_URL || 'https://i-club-app.vercel.app/';
const OUT = process.env.ICLUB_MOBILE_QA_OUT || 'mobile-qa-artifacts';
fs.mkdirSync(OUT, { recursive: true });

const report = {
  baseUrl: BASE_URL,
  startedAt: new Date().toISOString(),
  qaUser: null,
  viewports: {},
  consoleErrors: [],
  pageErrors: [],
  notes: []
};

const sleep = ms => new Promise(r => setTimeout(r, ms));
const safeName = s => String(s).replace(/[^a-z0-9_-]+/gi, '-').replace(/^-|-$/g, '').toLowerCase();

async function shot(page, name, fullPage = false) {
  const file = path.join(OUT, safeName(name) + '.png');
  await page.screenshot({ path: file, fullPage });
  return file;
}

async function viewportAudit(page, label) {
  const data = await page.evaluate(() => {
    const root = document.documentElement;
    const body = document.body;
    const interactive = Array.from(document.querySelectorAll('button,a,input,select,textarea,[role="button"]'))
      .filter(el => {
        const cs = getComputedStyle(el);
        const r = el.getBoundingClientRect();
        return cs.display !== 'none' && cs.visibility !== 'hidden' && r.width > 0 && r.height > 0;
      })
      .map(el => {
        const r = el.getBoundingClientRect();
        return {
          tag: el.tagName.toLowerCase(),
          text: String(el.innerText || el.getAttribute('aria-label') || el.name || '').trim().slice(0, 90),
          width: Math.round(r.width),
          height: Math.round(r.height),
          left: Math.round(r.left),
          right: Math.round(r.right),
          top: Math.round(r.top),
          bottom: Math.round(r.bottom)
        };
      });
    const tooSmall = interactive.filter(x => x.width < 40 || x.height < 40);
    const offscreen = interactive.filter(x => x.left < -1 || x.right > innerWidth + 1);
    return {
      innerWidth,
      innerHeight,
      docScrollWidth: Math.max(root.scrollWidth, body?.scrollWidth || 0),
      docScrollHeight: Math.max(root.scrollHeight, body?.scrollHeight || 0),
      horizontalOverflow: Math.max(root.scrollWidth, body?.scrollWidth || 0) > innerWidth + 1,
      tooSmall: tooSmall.slice(0, 30),
      offscreen: offscreen.slice(0, 30)
    };
  });
  report.viewports[label] = report.viewports[label] || { screens: {} };
  report.viewports[label].screens.audit = data;
  return data;
}

async function ensureRegistration(page, qaName) {
  await page.goto(BASE_URL, { waitUntil: 'domcontentloaded', timeout: 45000 });
  await page.waitForFunction(() => {
    const reg = document.querySelector('#view-registration');
    const home = document.querySelector('#view-home');
    return reg?.classList.contains('is-active') || home?.classList.contains('is-active');
  }, null, { timeout: 45000 });

  const isHome = await page.locator('#view-home.is-active').count();
  if (isHome) return;

  await page.selectOption('#reg-language', 'ru');
  await page.fill('#reg-fullname', qaName);

  await page.waitForFunction(() => document.querySelectorAll('#reg-region option').length > 1, null, { timeout: 30000 });
  const regionValue = await page.$eval('#reg-region', el => Array.from(el.options).find(o => o.value)?.value || '');
  if (!regionValue) throw new Error('No registration region option');
  await page.selectOption('#reg-region', regionValue);

  await page.waitForFunction(() => {
    const d = document.querySelector('#reg-district');
    return d && !d.disabled && d.options.length > 1;
  }, null, { timeout: 30000 });
  const districtValue = await page.$eval('#reg-district', el => Array.from(el.options).find(o => o.value)?.value || '');
  if (!districtValue) throw new Error('No registration district option');
  await page.selectOption('#reg-district', districtValue);

  await page.fill('#reg-school', 'QA Mobile');
  await page.selectOption('#reg-class', '11');

  const mathChip = page.locator('#reg-subject-chips [data-subject-key="mathematics"]');
  await mathChip.waitFor({ state: 'visible', timeout: 15000 });
  await mathChip.click();

  await page.check('#reg-consent');
  await page.click('#reg-submit');

  await page.waitForFunction(() => document.querySelector('#view-home')?.classList.contains('is-active'), null, { timeout: 45000 });
  await sleep(1200);
}

async function getUid(page) {
  return await page.evaluate(async () => {
    try {
      const { data } = await window.sb?.auth?.getUser?.();
      return data?.user?.id || null;
    } catch (_) {
      return null;
    }
  });
}

async function openExamPrep(page) {
  await page.click('[data-tab="courses"]');
  await page.waitForFunction(() => document.querySelector('#view-courses')?.classList.contains('is-active'), null, { timeout: 15000 });
  await page.waitForFunction(() => document.querySelectorAll('#subjects-grid .catalog-card').length > 0, null, { timeout: 20000 });

  const mathCard = page.locator('#subjects-grid .catalog-card').filter({ hasText: /Математика|Mathematics|Matematika/i }).first();
  await mathCard.locator('.catalog-head').click();

  await page.waitForFunction(() => document.querySelector('#courses-subject-hub')?.classList.contains('is-active'), null, { timeout: 15000 });
  await page.waitForFunction(() => {
    const e = document.querySelector('#subject-hub-exam-prep-entry');
    return e && !e.hidden && e.getAttribute('aria-hidden') !== 'true';
  }, null, { timeout: 20000 });
  await page.click('[data-action="open-exam-prep"]');
  await page.waitForFunction(() => {
    const r = document.querySelector('#exam-prep-host-root');
    return r && !r.hidden && r.textContent.trim().length > 0;
  }, null, { timeout: 25000 });

  const profileForm = page.locator('[data-ep-live-profile-form]');
  if (await profileForm.count()) {
    await page.fill('[data-ep-live-profile-form] [name="exam_series"]', 'May/June 2027');
    await page.fill('[data-ep-live-profile-form] [name="target_grade"]', 'A');
    await page.fill('[data-ep-live-profile-form] [name="total_hours"]', '10');
    await page.fill('[data-ep-live-profile-form] [name="math_hours"]', '5');
    await page.click('[data-ep-live-save-profile]');
  }

  await page.waitForSelector('[data-ep-live-component="P1"]', { state: 'visible', timeout: 30000 });
  await page.waitForSelector('[data-ep-live-component="P5"]', { state: 'visible', timeout: 30000 });
}

async function answerCurrentQuestion(page) {
  const radio = page.locator('input[name="ep_live_answer"]');
  const text = page.locator('input[name="ep_live_text_answer"]');
  const written = page.locator('textarea[name="ep_live_written_answer"]');
  if (await radio.count()) {
    await radio.first().check();
  } else if (await text.count()) {
    await text.fill('0');
  } else if (await written.count()) {
    await written.fill('QA mobile layout response');
  } else {
    throw new Error('No answer control on visible question');
  }
  await page.click('[data-ep-live-submit]');
}

async function completeCurrentSession(page, maxItems = 12) {
  let answered = 0;
  while (answered < maxItems) {
    if (await page.locator('[data-ep-live-submit]').count()) {
      await answerCurrentQuestion(page);
      answered += 1;
      await page.waitForFunction(() => {
        return Boolean(document.querySelector('[data-ep-live-submit]')) ||
               Boolean(document.querySelector('[data-ep-component-home]')) ||
               Boolean(document.querySelector('[data-ep-live-component="P1"]'));
      }, null, { timeout: 20000 });
      await sleep(250);
      continue;
    }
    break;
  }
  return answered;
}

async function openP1Home(page) {
  if (await page.locator('[data-ep-live-component="P1"]').count()) {
    await page.click('[data-ep-live-component="P1"]');
  }
  await page.waitForSelector('[data-ep-component-home="P1"]', { state: 'visible', timeout: 25000 });
}

async function collectPrimaryScreens(page, label) {
  report.viewports[label] = { screens: {} };

  await openExamPrep(page);
  report.viewports[label].screens.overview = {
    screenshot: await shot(page, `${label}-01-overview`),
    audit: await viewportAudit(page, label + '-overview')
  };

  await openP1Home(page);
  report.viewports[label].screens.p1Home = {
    screenshot: await shot(page, `${label}-02-p1-home`),
    fullScreenshot: await shot(page, `${label}-02b-p1-home-full`, true),
    audit: await viewportAudit(page, label + '-p1-home')
  };

  const firstDetails = page.locator('.ep-component-area').first();
  if (await firstDetails.count()) {
    await firstDetails.locator('summary').click();
    report.viewports[label].screens.topicExpanded = {
      screenshot: await shot(page, `${label}-03-topic-expanded`),
      audit: await viewportAudit(page, label + '-topic')
    };

    const skill = page.locator('[data-ep-component-skill]').first();
    if (await skill.count()) {
      await skill.click();
      await page.waitForSelector('[data-ep-views-back]', { state: 'visible', timeout: 20000 });
      report.viewports[label].screens.skillDetail = {
        screenshot: await shot(page, `${label}-04-skill-detail`),
        fullScreenshot: await shot(page, `${label}-04b-skill-detail-full`, true),
        audit: await viewportAudit(page, label + '-skill')
      };
      await page.click('[data-ep-views-back]');
      await page.waitForSelector('[data-ep-views-back]', { state: 'visible', timeout: 20000 }).catch(() => null);
      // Return to component home rather than tracker for consistent continuation.
      if (await page.locator('[data-ep-views-back]').count()) {
        await page.click('[data-ep-views-back]');
      }
      await page.waitForSelector('[data-ep-live-component="P1"]', { state: 'visible', timeout: 20000 }).catch(() => null);
      await openP1Home(page);
    }
  }

  const materials = page.locator('[data-ep-component-link="materials"]');
  if (await materials.count()) {
    await materials.click();
    await page.waitForTimeout(800);
    report.viewports[label].screens.materials = {
      screenshot: await shot(page, `${label}-05-materials`),
      fullScreenshot: await shot(page, `${label}-05b-materials-full`, true),
      audit: await viewportAudit(page, label + '-materials')
    };
    const matBack = page.locator('[data-ep-materials-back], [data-ep-views-back], [data-ep-live-home]').first();
    if (await matBack.count()) await matBack.click();
    await page.waitForTimeout(500);
    if (await page.locator('[data-ep-live-component="P1"]').count()) await openP1Home(page);
  }

  // Start diagnostic and capture real protected question.
  const primary = page.locator('[data-ep-component-primary]');
  if (await primary.count()) {
    await primary.click();
    await page.waitForSelector('[data-ep-live-submit]', { state: 'visible', timeout: 30000 });
    report.viewports[label].screens.question = {
      screenshot: await shot(page, `${label}-06-question`),
      fullScreenshot: await shot(page, `${label}-06b-question-full`, true),
      audit: await viewportAudit(page, label + '-question')
    };
  }
}

async function navigateExistingUserToP1(page) {
  await page.goto(BASE_URL, { waitUntil: 'domcontentloaded', timeout: 45000 });
  await page.waitForFunction(() => document.querySelector('#view-home')?.classList.contains('is-active'), null, { timeout: 45000 });
  await openExamPrep(page);
  await openP1Home(page);
}

async function smokeViewport(browser, storagePath, width, height, label) {
  const context = await browser.newContext({
    viewport: { width, height },
    isMobile: true,
    hasTouch: true,
    deviceScaleFactor: 2,
    storageState: storagePath
  });
  const page = await context.newPage();
  page.on('console', msg => { if (msg.type() === 'error') report.consoleErrors.push({ label, text: msg.text() }); });
  page.on('pageerror', err => report.pageErrors.push({ label, text: String(err) }));
  await navigateExistingUserToP1(page);
  const screens = {};
  screens.p1Home = { screenshot: await shot(page, `${label}-p1-home`), audit: await viewportAudit(page, label + '-p1') };
  const details = page.locator('.ep-component-area').first();
  if (await details.count()) {
    await details.locator('summary').click();
    screens.topic = { screenshot: await shot(page, `${label}-topic`), audit: await viewportAudit(page, label + '-topic') };
  }
  report.viewports[label] = { width, height, screens };
  await context.close();
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const primaryLabel = '390x844';
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    isMobile: true,
    hasTouch: true,
    deviceScaleFactor: 2
  });
  const page = await context.newPage();
  page.setDefaultTimeout(20000);
  page.on('console', msg => { if (msg.type() === 'error') report.consoleErrors.push({ label: primaryLabel, text: msg.text() }); });
  page.on('pageerror', err => report.pageErrors.push({ label: primaryLabel, text: String(err) }));

  const qaName = 'QA Mobile Exam Prep 20260924';
  await ensureRegistration(page, qaName);
  report.qaUser = { name: qaName, uid: await getUid(page) };
  await collectPrimaryScreens(page, primaryLabel);

  const storagePath = path.join(OUT, 'storage-state.json');
  await context.storageState({ path: storagePath });
  await context.close();

  await smokeViewport(browser, storagePath, 360, 800, '360x800');
  await smokeViewport(browser, storagePath, 430, 932, '430x932');

  report.finishedAt = new Date().toISOString();
  fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
  console.log(JSON.stringify({
    status: 'MOBILE_QA_CAPTURED',
    qaUser: report.qaUser,
    viewports: Object.keys(report.viewports),
    consoleErrors: report.consoleErrors.length,
    pageErrors: report.pageErrors.length
  }, null, 2));

  await browser.close();
})().catch(err => {
  report.finishedAt = new Date().toISOString();
  report.fatal = String(err && err.stack || err);
  fs.writeFileSync(path.join(OUT, 'report.json'), JSON.stringify(report, null, 2));
  console.error(err);
  process.exit(1);
});
