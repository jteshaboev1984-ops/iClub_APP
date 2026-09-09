const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

// Post-activation verification marker: this regression is intentionally rerun after the bot release commit.
const html = fs.readFileSync('index.html', 'utf8');
const i18n = fs.readFileSync('i18n.js', 'utf8');
const css = fs.readFileSync('visual/iclub-visual-v3.css', 'utf8');

assert(html.includes('<body class="iclub-visual-v3">'), 'Visual v3 body activation class missing');
const oldCssPos = html.indexOf('style.css?v=');
const v3CssPos = html.indexOf('visual/iclub-visual-v3.css?v=v3foundation1');
assert(oldCssPos >= 0 && v3CssPos > oldCssPos, 'Visual v3 stylesheet must load after legacy style.css');

const tabbarStart = html.indexOf('<nav id="tabbar"');
const tabbarEnd = html.indexOf('</nav>', tabbarStart);
assert(tabbarStart >= 0 && tabbarEnd > tabbarStart, 'Primary tabbar markup missing');
const tabbar = html.slice(tabbarStart, tabbarEnd + 6);
const tabs = [...tabbar.matchAll(/data-tab="([^"]+)"/g)].map(match => match[1]);
assert(JSON.stringify(tabs) === JSON.stringify(['home', 'courses', 'ratings', 'profile']), `Internal routes changed: ${JSON.stringify(tabs)}`);
assert(tabbar.includes('data-i18n="tab_study">Study</span>'), 'Study learner-facing nav label missing');
assert(!/[⌂▦▤]/.test(tabbar), 'Legacy navigation glyph leaked after Visual v3 activation');
assert((tabbar.match(/class="v3-shell-nav-icon"/g) || []).length === 4, 'Bottom navigation must have four line SVG icons');

const topbarStart = html.indexOf('<header id="topbar"');
const topbarEnd = html.indexOf('</header>', topbarStart);
const topbar = html.slice(topbarStart, topbarEnd + 9);
assert(topbarStart >= 0 && topbarEnd > topbarStart, 'Topbar markup missing');
assert((topbar.match(/class="v3-shell-icon"/g) || []).length === 3, 'Topbar must use line SVG icons for back, notifications and actions');
assert(!topbar.includes('🔔') && !topbar.includes('<span class="icon">←</span>'), 'Legacy topbar glyph/emoji leaked after Visual v3 activation');

for (const token of [
  'tab_study: "Учёба"',
  'tab_study: "O‘qish"',
  'tab_study: "Study"'
]) {
  assert(i18n.includes(token), `Missing Visual v3 navigation translation: ${token}`);
}
assert((i18n.match(/tab_study:/g) || []).length === 3, 'tab_study must exist exactly once per RU/UZ/EN dictionary');

for (const token of [
  'LIVE FOUNDATION v3',
  'body.iclub-visual-v3',
  '.iclub-visual-v3 .topbar',
  '.iclub-visual-v3 .card',
  '.iclub-visual-v3 .input',
  '.iclub-visual-v3 .tabbar',
  '.iclub-visual-v3 #exam-prep-host-root .ep-live-card',
  '.iclub-visual-v3 #exam-prep-host-root .ep-placement-card'
]) {
  assert(css.includes(token), `Visual v3 live override missing: ${token}`);
}

for (const forbidden of [
  /data-tab="study"/,
  /localStorage/i,
  /sessionStorage/i,
  /\.from\s*\(/,
  /\.rpc\s*\(/
]) {
  assert(!forbidden.test(css), `Visual v3 CSS contains forbidden state/data behavior: ${forbidden}`);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    javaScriptEnabled: false
  });
  const page = await context.newPage();
  await page.route('https://**/*', route => route.abort());
  const url = process.env.VISUAL_V3_LIVE_URL || 'http://127.0.0.1:4173/index.html';
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle').catch(() => {});

  const computed = await page.evaluate(() => {
    const body = getComputedStyle(document.body);
    const card = getComputedStyle(document.querySelector('.card'));
    const input = getComputedStyle(document.querySelector('.input'));
    const tabbar = getComputedStyle(document.querySelector('#tabbar'));
    const activeTab = getComputedStyle(document.querySelector('#tabbar .tab.is-active'));
    return {
      bodyBg: body.backgroundColor,
      bodyText: body.color,
      cardRadius: card.borderRadius,
      cardBorder: card.borderTopColor,
      inputRadius: input.borderRadius,
      tabbarPosition: tabbar.position,
      tabbarBg: tabbar.backgroundColor,
      activeTabColor: activeTab.color,
      width: document.documentElement.scrollWidth,
      innerWidth: window.innerWidth
    };
  });

  assert(computed.bodyBg === 'rgb(247, 249, 254)', `Live Visual v3 background drift: ${computed.bodyBg}`);
  assert(computed.bodyText === 'rgb(15, 23, 42)', `Live Visual v3 text drift: ${computed.bodyText}`);
  assert(computed.cardRadius === '12px', `Live Visual v3 card radius drift: ${computed.cardRadius}`);
  assert(computed.cardBorder === 'rgb(226, 232, 240)', `Live Visual v3 card border drift: ${computed.cardBorder}`);
  assert(computed.inputRadius === '10px', `Live Visual v3 input radius drift: ${computed.inputRadius}`);
  assert(computed.tabbarPosition === 'fixed', `Tabbar routing shell positioning changed: ${computed.tabbarPosition}`);
  assert(computed.tabbarBg === 'rgba(255, 255, 255, 0.97)', `Live Visual v3 tabbar background drift: ${computed.tabbarBg}`);
  assert(computed.activeTabColor === 'rgb(36, 87, 214)', `Live Visual v3 active nav color drift: ${computed.activeTabColor}`);
  assert(computed.width <= computed.innerWidth, `Live Visual v3 mobile horizontal overflow: ${JSON.stringify(computed)}`);

  const liveTabs = await page.locator('#tabbar .tab').evaluateAll(nodes => nodes.map(node => ({
    route: node.getAttribute('data-tab'),
    label: node.querySelector('.tab-txt')?.textContent?.trim(),
    svg: Boolean(node.querySelector('svg.v3-shell-nav-icon'))
  })));
  assert(JSON.stringify(liveTabs.map(x => x.route)) === JSON.stringify(['home', 'courses', 'ratings', 'profile']), 'Browser internal tab routes changed');
  assert(JSON.stringify(liveTabs.map(x => x.label)) === JSON.stringify(['Home', 'Study', 'Ratings', 'Profile']), `Browser nav labels mismatch: ${JSON.stringify(liveTabs)}`);
  assert(liveTabs.every(x => x.svg), 'Browser navigation has a non-SVG icon');

  await browser.close();
  console.log('Visual Foundation v3 live shell regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
