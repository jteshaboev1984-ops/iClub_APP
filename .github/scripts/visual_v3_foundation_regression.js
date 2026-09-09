const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

// Re-run after live activation to prove the static preview remains isolated and visually stable.
const html = fs.readFileSync('visual-v3-preview.html', 'utf8');
const css = fs.readFileSync('visual/iclub-visual-v3.css', 'utf8');

for (const forbidden of [
  /supabase/i,
  /app\.js/i,
  /localStorage/i,
  /sessionStorage/i,
  /window\.sb/i,
  /\.from\s*\(/,
  /\.rpc\s*\(/
]) {
  assert(!forbidden.test(html), `Visual v3 preview must stay static: ${forbidden}`);
}

for (const token of [
  '--v3-brand: #2F6FD6',
  '--v3-primary: #2457D6',
  '--v3-bg: #F7F9FE',
  '--v3-text: #0F172A',
  '--v3-border: #E2E8F0',
  '--v3-radius-lg: 12px',
  '--v3-radius-md: 10px',
  '--v3-radius-sm: 8px',
  '.iclub-visual-v3 .v3-card',
  '.iclub-visual-v3 .v3-tabbar'
]) {
  assert(css.includes(token), `Visual v3 CSS missing approved token/rule: ${token}`);
}

assert(!/(^|\n)\s*(?:body|html|:root|\.card|\.tabbar)\s*\{/m.test(css), 'Visual v3 CSS contains an unscoped production selector');
assert((html.match(/class="v3-nav-icon"/g) || []).length === 4, 'Visual v3 preview must use four line SVG navigation icons');
assert(!/[⌂▦▤]/.test(html), 'Legacy glyph navigation leaked into Visual v3 preview');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
  const url = process.env.VISUAL_V3_URL || 'http://127.0.0.1:4173/visual-v3-preview.html';
  await page.goto(url, { waitUntil: 'networkidle' });

  assert(await page.locator('[data-v3-preview-shell]').count() === 1, 'Visual v3 preview shell missing');
  assert(await page.locator('script').count() === 0, 'Visual v3 preview unexpectedly contains runtime scripts');

  const navLabels = await page.locator('[data-v3-nav]').evaluateAll(nodes => nodes.map(node => node.getAttribute('data-v3-nav')));
  assert(JSON.stringify(navLabels) === JSON.stringify(['Home', 'Study', 'Ratings', 'Profile']), `Visual v3 nav mismatch: ${JSON.stringify(navLabels)}`);
  assert(await page.locator('.v3-tabbar svg.v3-nav-icon').count() === 4, 'Visual v3 nav line icons missing');

  const tokens = await page.evaluate(() => {
    const s = getComputedStyle(document.body);
    return {
      brand: s.getPropertyValue('--v3-brand').trim(),
      primary: s.getPropertyValue('--v3-primary').trim(),
      bg: s.getPropertyValue('--v3-bg').trim(),
      text: s.getPropertyValue('--v3-text').trim(),
      border: s.getPropertyValue('--v3-border').trim(),
      rLg: s.getPropertyValue('--v3-radius-lg').trim(),
      rMd: s.getPropertyValue('--v3-radius-md').trim(),
      rSm: s.getPropertyValue('--v3-radius-sm').trim()
    };
  });
  assert(tokens.brand === '#2F6FD6', `Brand token drift: ${tokens.brand}`);
  assert(tokens.primary === '#2457D6', `Primary token drift: ${tokens.primary}`);
  assert(tokens.bg === '#F7F9FE', `Background token drift: ${tokens.bg}`);
  assert(tokens.text === '#0F172A', `Text token drift: ${tokens.text}`);
  assert(tokens.border === '#E2E8F0', `Border token drift: ${tokens.border}`);
  assert(tokens.rLg === '12px' && tokens.rMd === '10px' && tokens.rSm === '8px', `Radius scale drift: ${JSON.stringify(tokens)}`);

  const componentBoxes = await Promise.all(['P1', 'P5'].map(code => page.locator(`[data-v3-component="${code}"]`).boundingBox()));
  assert(componentBoxes.every(Boolean), 'P1/P5 component preview cards missing');
  assert(Math.abs(componentBoxes[0].width - componentBoxes[1].width) <= 1, `P1/P5 component cards are asymmetric: ${componentBoxes[0].width} vs ${componentBoxes[1].width}`);

  const radii = await page.evaluate(() => ({
    card: getComputedStyle(document.querySelector('.v3-card')).borderRadius,
    button: getComputedStyle(document.querySelector('.v3-btn')).borderRadius,
    iconBox: getComputedStyle(document.querySelector('.v3-list-icon')).borderRadius
  }));
  assert(radii.card === '12px', `Card radius drift: ${radii.card}`);
  assert(radii.button === '10px', `Button radius drift: ${radii.button}`);
  assert(radii.iconBox === '8px', `Small radius drift: ${radii.iconBox}`);

  const overflow = await page.evaluate(() => ({
    scrollWidth: document.documentElement.scrollWidth,
    innerWidth: window.innerWidth
  }));
  assert(overflow.scrollWidth <= overflow.innerWidth, `Visual v3 mobile horizontal overflow: ${JSON.stringify(overflow)}`);

  const languageLines = await page.locator('.v3-language-line').count();
  assert(languageLines === 3, `RU/UZ/EN visual language check incomplete: ${languageLines}`);

  const shadows = await page.evaluate(() => getComputedStyle(document.querySelector('.v3-card')).boxShadow);
  assert(!shadows.includes('rgba(15, 23, 42, 0.2') && !shadows.includes('rgba(15, 23, 42, 0.3'), `Visual v3 shadow is too heavy: ${shadows}`);

  await browser.close();
  console.log('Visual Foundation v3 static preview regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
