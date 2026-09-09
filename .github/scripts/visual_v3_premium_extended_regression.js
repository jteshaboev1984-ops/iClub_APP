const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');

for (const token of [
  'PREMIUM EXTENDED SCREENS v3',
  '#view-registration .reg-form',
  '#view-registration .reg-subject-card',
  '#view-ratings .lb-segment',
  '#view-ratings .lb-list-wrap',
  '#view-support-topic .support-textarea',
  '#view-community .card-btn'
]) {
  assert(css.includes(token), `Premium extended CSS missing ${token}`);
}

assert((html.match(/class="v3-ratings-icon"/g) || []).length === 3, 'Ratings must use three line SVG icons');
assert(!/<button class="lb-search-btn"[^>]*>🔍<\/button>/.test(html), 'Ratings header search emoji leaked');
assert(!/<span class="lb-search-ico">🔍<\/span>/.test(html), 'Ratings search panel emoji leaked');

for (const forbidden of [/localStorage/i, /sessionStorage/i, /supabase/i, /\.rpc\s*\(/, /\.from\s*\(/, /operational_stage\s*=/, /innerHTML\s*=/]) {
  assert(!forbidden.test(css), `Premium extended CSS is not presentation-only: ${forbidden}`);
}

async function show(page, id) {
  await page.evaluate((id) => {
    document.querySelectorAll('.view').forEach(v => v.classList.remove('is-active'));
    const el = document.getElementById(id);
    if (!el) throw new Error(`missing ${id}`);
    el.classList.add('is-active');
  }, id);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, javaScriptEnabled: false });
  const url = process.env.VISUAL_V3_PREMIUM_URL || 'http://127.0.0.1:4173/index.html';
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  await show(page, 'view-registration');
  let s = await page.evaluate(() => ({
    titleSize: getComputedStyle(document.querySelector('#view-registration .h1')).fontSize,
    cardRadius: getComputedStyle(document.querySelector('#view-registration .reg-subject-card')).borderRadius,
    submitRadius: getComputedStyle(document.querySelector('#view-registration #reg-submit')).borderRadius,
    width: document.documentElement.scrollWidth,
    innerWidth: innerWidth
  }));
  assert(s.titleSize === '24px', `Registration mobile title drift: ${s.titleSize}`);
  assert(s.cardRadius === '12px', `Registration card radius drift: ${s.cardRadius}`);
  assert(s.submitRadius === '10px', `Registration submit radius drift: ${s.submitRadius}`);
  assert(s.width <= s.innerWidth, `Registration overflow: ${JSON.stringify(s)}`);

  await show(page, 'view-ratings');
  s = await page.evaluate(() => ({
    titleSize: getComputedStyle(document.querySelector('#view-ratings .lb-title')).fontSize,
    segmentRadius: getComputedStyle(document.querySelector('#view-ratings .lb-segment')).borderRadius,
    activeColor: getComputedStyle(document.querySelector('#view-ratings .seg-btn.is-active')).color,
    iconCount: document.querySelectorAll('#view-ratings .v3-ratings-icon').length,
    width: document.documentElement.scrollWidth,
    innerWidth: innerWidth
  }));
  assert(s.titleSize === '20px', `Ratings mobile title drift: ${s.titleSize}`);
  assert(s.segmentRadius === '10px', `Ratings segment radius drift: ${s.segmentRadius}`);
  assert(s.activeColor === 'rgb(36, 87, 214)', `Ratings active state drift: ${s.activeColor}`);
  assert(s.iconCount === 3, `Ratings line icons missing: ${s.iconCount}`);
  assert(s.width <= s.innerWidth, `Ratings overflow: ${JSON.stringify(s)}`);

  await show(page, 'view-support-topic');
  s = await page.evaluate(() => ({
    titleSize: getComputedStyle(document.querySelector('#view-support-topic .h1')).fontSize,
    cardRadius: getComputedStyle(document.querySelector('#view-support-topic .card')).borderRadius,
    textareaMinHeight: getComputedStyle(document.querySelector('#view-support-topic .support-textarea')).minHeight,
    width: document.documentElement.scrollWidth,
    innerWidth: innerWidth
  }));
  assert(s.titleSize === '23px', `Global screen title drift: ${s.titleSize}`);
  assert(s.cardRadius === '12px', `Support card radius drift: ${s.cardRadius}`);
  assert(s.textareaMinHeight === '120px', `Support textarea geometry drift: ${s.textareaMinHeight}`);
  assert(s.width <= s.innerWidth, `Support overflow: ${JSON.stringify(s)}`);

  const routes = await page.locator('#tabbar .tab').evaluateAll(nodes => nodes.map(n => n.getAttribute('data-tab')));
  assert(JSON.stringify(routes) === JSON.stringify(['home', 'courses', 'ratings', 'profile']), `Routes changed: ${JSON.stringify(routes)}`);

  await browser.close();
  console.log('Visual v3 premium extended screen regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
