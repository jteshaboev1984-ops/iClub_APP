const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');

const foundationPos = html.indexOf('visual/iclub-visual-v3.css?v=v3foundation1');
const premiumPos = html.indexOf('visual/iclub-premium-v3.css?v=premium1');
assert(foundationPos >= 0 && premiumPos > foundationPos, 'Premium stylesheet must load after Visual Foundation v3');

const premiumRowSvgCount = (html.match(/<svg viewBox="0 0 24 24" width="18" height="18"/g) || []).length;
assert(premiumRowSvgCount >= 12, `Premium learner rows must use line SVG icons: ${premiumRowSvgCount}`);
assert(!/<span class="settings-nav-ico">(?:ℹ️|📰|💬|🎯|🎬|📚|🎓|🗂️|🧭)<\/span>/.test(html), 'Premium settings rows still contain emoji icons');
assert(!/<div class="profile-row-ico">(?:🎓|📄|🛟)<\/div>/.test(html), 'Premium profile rows still contain emoji icons');

for (const token of [
  '#view-home .home-block-title',
  '#courses-all-subjects .section-title',
  '#courses-subject-hub .subject-hub-head',
  '#exam-prep-host-root .ep-live-card',
  '#view-profile .profile-hero',
  '#view-profile .overview-card',
  '--v3-premium-shadow'
]) {
  assert(css.includes(token), `Premium v3 CSS missing required screen contract: ${token}`);
}

for (const forbidden of [
  /localStorage/i,
  /sessionStorage/i,
  /supabase/i,
  /\.rpc\s*\(/,
  /\.from\s*\(/,
  /data-tab\s*=/,
  /operational_stage\s*=/,
  /innerHTML\s*=/
]) {
  assert(!forbidden.test(css), `Premium v3 must stay visual-only: ${forbidden}`);
}

assert(!/(^|\n)\s*(?:html|body|:root)\s*\{/m.test(css), 'Premium CSS contains an unscoped global selector');

async function activate(page, viewId, stackScreenId = null) {
  await page.evaluate(({ viewId, stackScreenId }) => {
    document.querySelectorAll('.view').forEach(node => node.classList.remove('is-active'));
    const view = document.getElementById(viewId);
    if (!view) throw new Error(`missing view ${viewId}`);
    view.classList.add('is-active');
    if (viewId === 'view-courses') {
      document.querySelectorAll('#courses-stack .stack-screen').forEach(node => node.classList.remove('is-active'));
      const screen = document.getElementById(stackScreenId || 'courses-all-subjects');
      if (!screen) throw new Error(`missing stack screen ${stackScreenId}`);
      screen.classList.add('is-active');
      screen.hidden = false;
      screen.setAttribute('aria-hidden', 'false');
    }
  }, { viewId, stackScreenId });
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, javaScriptEnabled: false });
  const page = await context.newPage();
  const url = process.env.VISUAL_V3_PREMIUM_URL || 'http://127.0.0.1:4173/index.html';
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  await activate(page, 'view-home');
  const home = await page.evaluate(() => ({
    titleWeight: getComputedStyle(document.querySelector('#view-home .home-block-title')).fontWeight,
    titleSize: getComputedStyle(document.querySelector('#view-home .home-block-title')).fontSize,
    extraRadius: getComputedStyle(document.querySelector('#home-extra-card')).borderRadius,
    extraShadow: getComputedStyle(document.querySelector('#home-extra-card')).boxShadow,
    width: document.documentElement.scrollWidth,
    innerWidth: window.innerWidth
  }));
  assert(Number(home.titleWeight) >= 700, `Home title is not premium-weight: ${home.titleWeight}`);
  assert(home.titleSize === '17px', `Home title size drift: ${home.titleSize}`);
  assert(home.extraRadius === '12px', `Home card radius drift: ${home.extraRadius}`);
  assert(home.extraShadow !== 'none', 'Home premium surface shadow missing');
  assert(home.width <= home.innerWidth, `Home overflow: ${JSON.stringify(home)}`);

  await activate(page, 'view-courses', 'courses-all-subjects');
  const study = await page.evaluate(() => ({
    titleSize: getComputedStyle(document.querySelector('#courses-all-subjects .section-title')).fontSize,
    filterRadius: getComputedStyle(document.querySelector('#courses-filter-row')).borderRadius,
    width: document.documentElement.scrollWidth,
    innerWidth: window.innerWidth
  }));
  assert(study.titleSize === '22px', `Study title size drift: ${study.titleSize}`);
  assert(study.width <= study.innerWidth, `Study overflow: ${JSON.stringify(study)}`);

  await activate(page, 'view-courses', 'courses-subject-hub');
  await page.evaluate(() => {
    const entry = document.getElementById('subject-hub-exam-prep-entry');
    entry.hidden = false;
    entry.setAttribute('aria-hidden', 'false');
  });
  const hub = await page.evaluate(() => ({
    headRadius: getComputedStyle(document.querySelector('#courses-subject-hub .subject-hub-head')).borderRadius,
    headShadow: getComputedStyle(document.querySelector('#courses-subject-hub .subject-hub-head')).boxShadow,
    primaryColumns: getComputedStyle(document.querySelector('#courses-subject-hub .subject-hub-primary-modes')).gridTemplateColumns,
    entryRadius: getComputedStyle(document.querySelector('#subject-hub-exam-prep-entry')).borderRadius,
    width: document.documentElement.scrollWidth,
    innerWidth: window.innerWidth
  }));
  assert(hub.headRadius === '12px', `Subject hub radius drift: ${hub.headRadius}`);
  assert(hub.headShadow !== 'none', 'Subject hub premium surface shadow missing');
  assert(hub.entryRadius === '12px', `Exam Prep entry radius drift: ${hub.entryRadius}`);
  assert(hub.width <= hub.innerWidth, `Subject hub overflow: ${JSON.stringify(hub)}`);

  await activate(page, 'view-profile');
  const profile = await page.evaluate(() => ({
    heroRadius: getComputedStyle(document.querySelector('#view-profile .profile-hero')).borderRadius,
    heroShadow: getComputedStyle(document.querySelector('#view-profile .profile-hero')).boxShadow,
    avatarRadius: getComputedStyle(document.querySelector('#view-profile .profile-avatar')).borderRadius,
    overviewRadius: getComputedStyle(document.querySelector('#view-profile .overview-card')).borderRadius,
    width: document.documentElement.scrollWidth,
    innerWidth: window.innerWidth
  }));
  assert(profile.heroRadius === '12px', `Profile hero radius drift: ${profile.heroRadius}`);
  assert(profile.heroShadow !== 'none', 'Profile premium hero shadow missing');
  assert(profile.avatarRadius === '12px', `Profile avatar radius drift: ${profile.avatarRadius}`);
  assert(profile.overviewRadius === '12px', `Profile overview radius drift: ${profile.overviewRadius}`);
  assert(profile.width <= profile.innerWidth, `Profile overflow: ${JSON.stringify(profile)}`);

  const routes = await page.locator('#tabbar .tab').evaluateAll(nodes => nodes.map(node => node.getAttribute('data-tab')));
  assert(JSON.stringify(routes) === JSON.stringify(['home', 'courses', 'ratings', 'profile']), `Premium pass changed routes: ${JSON.stringify(routes)}`);

  await browser.close();
  console.log('Visual v3 premium screen regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
