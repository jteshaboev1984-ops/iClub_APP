const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const host = fs.readFileSync('exam-prep/exam-prep-host.js', 'utf8');
const live = fs.readFileSync('exam-prep/exam-prep-live.js', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');

for (const token of [
  'class="subject-hub-list exam-prep-host-entry exam-prep-feature-card"',
  'id="subject-hub-exam-prep-badge"',
  'id="subject-hub-exam-prep-p1"',
  'id="subject-hub-exam-prep-p5"',
  'id="subject-hub-exam-prep-note"',
  'id="subject-hub-exam-prep-cta"',
  'data-action="open-exam-prep"'
]) assert(html.includes(token), `Math Exam Prep entry structure missing: ${token}`);

assert(/id="subject-hub-exam-prep-entry"[^>]*hidden[^>]*aria-hidden="true"/.test(html), 'Exam Prep entry must remain fail-closed by default');
assert(host.includes('hub.classList.toggle("exam-prep-available", visible === true)'), 'Host must expose presentation-only availability class');
assert(host.includes('entryDesc: "Персональный маршрут по Paper 1 и Paper 5'), 'RU learner copy missing');
assert(host.includes('entryDesc: "Paper 1 va Paper 5 bo‘yicha shaxsiy tayyorgarlik'), 'UZ learner copy missing');
assert(host.includes('entryDesc: "A personal route for Paper 1 and Paper 5'), 'EN learner copy missing');
assert(live.includes('class="ep-live-card ep-live-component-card"'), 'Live dashboard component architecture missing');
assert(live.includes('class="ep-live-dashboard-intro"'), 'Live dashboard hierarchy block missing');
assert(live.includes('componentP1: "Pure Mathematics 1"') && live.includes('componentP5: "Probability & Statistics 1"'), 'P1/P5 component names missing');
assert(!live.includes('overall readiness percentage') && !live.includes('combined mastery'), 'Combined learner truth must not be introduced');
assert(css.includes('PREMIUM MATHEMATICS EXAM PREP UX v3'), 'Premium Math Exam Prep UX marker missing');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 390, height: 844 }, javaScriptEnabled: false });
  const page = await context.newPage();
  const url = process.env.VISUAL_V3_PREMIUM_URL || 'http://127.0.0.1:4173/index.html';
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  await page.evaluate(() => {
    document.querySelectorAll('.view').forEach(node => node.classList.remove('is-active'));
    const courses = document.getElementById('view-courses');
    courses.classList.add('is-active');
    document.querySelectorAll('#courses-stack .stack-screen').forEach(node => node.classList.remove('is-active'));
    const hub = document.getElementById('courses-subject-hub');
    hub.classList.add('is-active', 'exam-prep-available');
    hub.hidden = false;
    hub.setAttribute('aria-hidden', 'false');
    const entry = document.getElementById('subject-hub-exam-prep-entry');
    entry.hidden = false;
    entry.setAttribute('aria-hidden', 'false');
  });

  const entry = await page.evaluate(() => {
    const el = document.getElementById('subject-hub-exam-prep-entry');
    const title = el.querySelector('.exam-prep-feature-title');
    const componentGrid = el.querySelector('.exam-prep-feature-components');
    return {
      radius: getComputedStyle(el).borderRadius,
      shadow: getComputedStyle(el).boxShadow,
      titleSize: parseFloat(getComputedStyle(title).fontSize),
      componentColumns: getComputedStyle(componentGrid).gridTemplateColumns,
      width: document.documentElement.scrollWidth,
      innerWidth: window.innerWidth
    };
  });
  assert(entry.radius === '12px', `Math feature card radius drift: ${entry.radius}`);
  assert(entry.shadow !== 'none', 'Math feature card must read as a premium product surface');
  assert(entry.titleSize >= 21, `Math feature title hierarchy too weak: ${entry.titleSize}`);
  assert(entry.width <= entry.innerWidth, `Math feature entry overflow: ${JSON.stringify(entry)}`);

  await page.evaluate(() => {
    const hub = document.getElementById('courses-subject-hub');
    hub.classList.add('exam-prep-host-open');
    const root = document.getElementById('exam-prep-host-root');
    root.hidden = false;
    root.setAttribute('aria-hidden', 'false');
    root.innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-dashboard-intro"><div><div class="ep-live-dashboard-eyebrow">Your route</div><h3 class="ep-live-dashboard-title">Preparation for P1 and P5</h3><p class="ep-live-dashboard-text">Each component moves separately with its own phase, evidence and next action.</p></div><div class="ep-live-dashboard-profile">May/June 2027 · A</div></div><div class="ep-live-grid"><article class="ep-live-card ep-live-component-card"><div class="ep-live-component-head"><span class="ep-live-component-code">P1</span><div class="ep-live-component-copy"><strong>Pure Mathematics 1</strong><span>45 skills</span></div></div><div class="ep-live-actions"><button class="ep-live-btn">Open weekly plan</button></div></article><article class="ep-live-card ep-live-component-card"><div class="ep-live-component-head"><span class="ep-live-component-code">P5</span><div class="ep-live-component-copy"><strong>Probability & Statistics 1</strong><span>36 skills</span></div></div><div class="ep-live-actions"><button class="ep-live-btn">Start the next check section</button></div></article></div></section>`;
  });

  const dashboard = await page.evaluate(() => ({
    introRadius: getComputedStyle(document.querySelector('.ep-live-dashboard-intro')).borderRadius,
    cardCount: document.querySelectorAll('.ep-live-component-card').length,
    gridColumns: getComputedStyle(document.querySelector('#exam-prep-host-root .ep-live-grid')).gridTemplateColumns,
    primaryBg: getComputedStyle(document.querySelector('.ep-live-component-card .ep-live-btn')).backgroundColor,
    width: document.documentElement.scrollWidth,
    innerWidth: window.innerWidth
  }));
  assert(dashboard.introRadius === '12px', `Exam Prep dashboard intro radius drift: ${dashboard.introRadius}`);
  assert(dashboard.cardCount === 2, `Exam Prep dashboard must keep P1/P5 as two separate cards: ${dashboard.cardCount}`);
  assert(dashboard.width <= dashboard.innerWidth, `Exam Prep dashboard overflow: ${JSON.stringify(dashboard)}`);

  await browser.close();
  console.log('Visual v3 Math Exam Prep UX regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
