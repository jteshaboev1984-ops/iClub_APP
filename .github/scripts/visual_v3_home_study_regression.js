const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const app = fs.readFileSync('app.js', 'utf8');
const i18n = fs.readFileSync('i18n.js', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');

for (const token of [
  'PREMIUM HOME STUDY ARCHITECTURE v3.5',
  '#view-home .home-competitive-card',
  '#view-home .home-pinned-tile',
  '#courses-all-subjects .grid-section-filters',
  '#courses-all-subjects .catalog-card',
  '#courses-all-subjects .catalog-toggle-row'
]) {
  assert(css.includes(token), `Home/Study premium CSS missing ${token}`);
}

assert(app.includes('class="v3-home-pinned-icon"'), 'Pinned subject tile must use the premium line icon');
assert(!app.includes('<div class="home-pinned-ico">📘</div>'), 'Legacy pinned-subject emoji must not remain');
assert(i18n.includes('courses_title: "Учёба"'), 'RU Study title missing');
assert(i18n.includes('courses_title: "O‘qish"'), 'UZ Study title missing');
assert(i18n.includes('courses_title: "Study"'), 'EN Study title missing');
assert(html.includes('data-i18n="courses_title">Study</div>'), 'Study screen fallback title is not aligned');

for (const contract of [
  'data-main-filter="competitive"',
  'data-main-filter="study"',
  'home-competitive-card',
  'home-competitive-btn',
  'home-pinned-tile',
  'catalog-card',
  'catalog-toggle-row'
]) {
  assert(app.includes(contract), `Home/Study behavior contract missing ${contract}`);
}

for (const forbidden of [/localStorage/i, /sessionStorage/i, /supabase/i, /\.rpc\s*\(/, /\.from\s*\(/, /operational_stage\s*=/, /innerHTML\s*=/]) {
  assert(!forbidden.test(css), `Home/Study premium layer must stay presentation-only: ${forbidden}`);
}

function sampleCompetitiveCard() {
  return `<div class="home-competitive-card" data-subject="mathematics">
    <div class="home-competitive-badge">ACTIVE TOUR</div>
    <div class="home-competitive-hero"><div class="home-competitive-hero-img"></div></div>
    <div class="home-competitive-body">
      <div class="home-competitive-title">Mathematics</div>
      <div class="home-competitive-note">Practice 1 is open</div>
      <div class="home-competitive-meta"><span class="home-competitive-module">Practice 1</span><span class="home-competitive-rank">12/120</span></div>
      <div class="home-competitive-percent">34%</div>
      <div class="home-progress"><div class="home-progress-fill" style="width:34%"></div></div>
    </div>
    <button class="btn primary home-competitive-btn" type="button">Open subject</button>
  </div>`;
}

function samplePinnedTile(title) {
  return `<button class="home-pinned-tile" type="button">
    <div class="home-pinned-ico" aria-hidden="true"><svg class="v3-home-pinned-icon" viewBox="0 0 24 24"><path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H11v16H6.5A2.5 2.5 0 0 0 4 21z"/><path d="M20 5.5A2.5 2.5 0 0 0 17.5 3H13v16h4.5A2.5 2.5 0 0 1 20 21z"/></svg></div>
    <div class="home-pinned-title">${title}</div>
    <div class="home-pinned-meta"><span>18/70</span> Practice</div>
  </button>`;
}

function sampleCatalogCard(title, active) {
  return `<div class="catalog-card">
    <button class="catalog-head" type="button"><div class="catalog-row"><div class="catalog-left"><div class="catalog-text"><div class="card-title" style="margin:0">${title}</div></div></div></div></button>
    <div class="catalog-toggle-row${active ? ' is-on' : ''}"><div class="catalog-toggle-left"><div class="catalog-toggle-state">${active ? 'Pinned' : 'Not pinned'}</div></div><label class="switch"><input type="checkbox" ${active ? 'checked' : ''}><span class="slider"></span></label></div>
  </div>`;
}

async function activateHome(page) {
  await page.evaluate(({ competitive, pinned1, pinned2 }) => {
    document.querySelectorAll('.view').forEach(node => node.classList.remove('is-active'));
    const home = document.getElementById('view-home');
    home.classList.add('is-active');
    document.getElementById('home-competitive-list').innerHTML = competitive;
    document.getElementById('home-study-list').innerHTML = pinned1 + pinned2;
  }, {
    competitive: sampleCompetitiveCard(),
    pinned1: samplePinnedTile('Mathematics'),
    pinned2: samplePinnedTile('Computer Science and Informatics')
  });
}

async function activateStudy(page) {
  await page.evaluate(({ cards }) => {
    document.querySelectorAll('.view').forEach(node => node.classList.remove('is-active'));
    const courses = document.getElementById('view-courses');
    courses.classList.add('is-active');
    document.querySelectorAll('#courses-stack .stack-screen').forEach(node => {
      node.classList.remove('is-active');
      node.hidden = true;
    });
    const all = document.getElementById('courses-all-subjects');
    all.hidden = false;
    all.classList.add('is-active');
    document.getElementById('courses-filter-row').innerHTML = `<div class="grid-section-filters"><button class="chip is-active">Competitive</button><button class="chip">Study</button></div>`;
    document.getElementById('subjects-grid').innerHTML = `<div class="grid-section-title">Main · Cambridge</div>${cards}`;
  }, {
    cards: sampleCatalogCard('Mathematics', true) + sampleCatalogCard('Computer Science and Informatics', false)
  });
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, javaScriptEnabled: false });
  const url = process.env.VISUAL_V3_PREMIUM_URL || 'http://127.0.0.1:4173/index.html';
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  await activateHome(page);
  let state = await page.evaluate(() => {
    const comp = document.querySelector('#view-home .home-competitive-card');
    const hero = comp.querySelector('.home-competitive-hero');
    const cta = comp.querySelector('.home-competitive-btn');
    const tile = document.querySelector('#view-home .home-pinned-tile');
    const icon = tile.querySelector('.v3-home-pinned-icon');
    return {
      compRadius: getComputedStyle(comp).borderRadius,
      compShadow: getComputedStyle(comp).boxShadow,
      heroHeight: hero.getBoundingClientRect().height,
      ctaHeight: cta.getBoundingClientRect().height,
      tileRadius: getComputedStyle(tile).borderRadius,
      tileDisplay: getComputedStyle(tile).display,
      iconWidth: icon.getBoundingClientRect().width,
      width: document.documentElement.scrollWidth,
      innerWidth: innerWidth
    };
  });
  assert(state.compRadius === '12px', `Home competitive card radius drift: ${state.compRadius}`);
  assert(state.compShadow !== 'none', 'Home competitive card premium surface missing');
  assert(state.heroHeight <= 82 && state.heroHeight >= 68, `Home subject visual is too dominant or too small: ${state.heroHeight}`);
  assert(state.ctaHeight >= 40, `Home primary action target too small: ${state.ctaHeight}`);
  assert(state.tileRadius === '12px', `Pinned tile radius drift: ${state.tileRadius}`);
  assert(state.tileDisplay === 'grid', `Pinned tile must use compact premium grid layout: ${state.tileDisplay}`);
  assert(state.iconWidth >= 17 && state.iconWidth <= 20, `Pinned line icon size drift: ${state.iconWidth}`);
  assert(state.width <= state.innerWidth, `Home mobile overflow: ${JSON.stringify(state)}`);

  await activateStudy(page);
  state = await page.evaluate(() => {
    const filters = document.querySelector('#courses-all-subjects .grid-section-filters');
    const activeChip = filters.querySelector('.chip.is-active');
    const card = document.querySelector('#courses-all-subjects .catalog-card');
    const head = card.querySelector('.catalog-head');
    const toggle = card.querySelector('.catalog-toggle-row');
    return {
      filterColumns: getComputedStyle(filters).gridTemplateColumns.split(' ').length,
      filterRadius: getComputedStyle(document.getElementById('courses-filter-row')).borderRadius,
      activeChipBg: getComputedStyle(activeChip).backgroundColor,
      cardRadius: getComputedStyle(card).borderRadius,
      cardShadow: getComputedStyle(card).boxShadow,
      headMinHeight: head.getBoundingClientRect().height,
      toggleHeight: toggle.getBoundingClientRect().height,
      width: document.documentElement.scrollWidth,
      innerWidth: innerWidth
    };
  });
  assert(state.filterColumns === 2, `Study mode switch must be a two-column segmented control: ${state.filterColumns}`);
  assert(state.filterRadius === '12px', `Study mode switch radius drift: ${state.filterRadius}`);
  assert(state.activeChipBg !== 'rgba(0, 0, 0, 0)', 'Active Study mode chip needs a visible selected surface');
  assert(state.cardRadius === '12px', `Study subject card radius drift: ${state.cardRadius}`);
  assert(state.cardShadow !== 'none', 'Study subject card premium surface missing');
  assert(state.headMinHeight >= 50, `Study subject open target too small: ${state.headMinHeight}`);
  assert(state.toggleHeight >= 46, `Study subject state row too small: ${state.toggleHeight}`);
  assert(state.width <= state.innerWidth, `Study mobile overflow: ${JSON.stringify(state)}`);

  await page.setViewportSize({ width: 320, height: 780 });
  await activateHome(page);
  let smallWidth = await page.evaluate(() => ({ width: document.documentElement.scrollWidth, innerWidth }));
  assert(smallWidth.width <= smallWidth.innerWidth, `Home 320px overflow: ${JSON.stringify(smallWidth)}`);
  await activateStudy(page);
  smallWidth = await page.evaluate(() => ({ width: document.documentElement.scrollWidth, innerWidth }));
  assert(smallWidth.width <= smallWidth.innerWidth, `Study 320px overflow: ${JSON.stringify(smallWidth)}`);

  const routes = await page.locator('#tabbar .tab').evaluateAll(nodes => nodes.map(node => node.getAttribute('data-tab')));
  assert(JSON.stringify(routes) === JSON.stringify(['home', 'courses', 'ratings', 'profile']), `Home/Study pass changed global routes: ${JSON.stringify(routes)}`);

  await browser.close();
  console.log('Visual v3 Home/Study regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
