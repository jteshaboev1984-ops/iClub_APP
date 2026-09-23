const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const host = fs.readFileSync('exam-prep/exam-prep-host.js', 'utf8');
const live = fs.readFileSync('exam-prep/exam-prep-live.js', 'utf8');
const hostCss = fs.readFileSync('exam-prep/exam-prep-host.css', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');

for (const token of [
  'id="subject-hub-exam-prep-entry"',
  'class="subject-hub-list exam-prep-host-entry exam-prep-feature-card subject-mode-card subject-mode-card-exam"',
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
assert(live.includes('class="ep-live-card ep-live-component-card ep-live-component-entry"'), 'Live dashboard tappable component architecture missing');
assert(live.includes('data-ep-live-open-component="'), 'Live dashboard component navigation missing');
assert(live.includes('data-ep-component-primary="'), 'Component home primary next-action contract missing');
assert(live.includes('class="ep-live-dashboard-intro"'), 'Live dashboard hierarchy block missing');
assert(live.includes('componentP1: "Pure Mathematics 1"') && live.includes('componentP5: "Probability & Statistics 1"'), 'P1/P5 component names missing');
assert(!live.includes('overall readiness percentage') && !live.includes('combined mastery'), 'Combined learner truth must not be introduced');
assert(hostCss.includes('.ep-live-dashboard-profile{width:100%;max-width:100%;min-width:0;box-sizing:border-box}'), 'Exam Prep mobile profile width guard missing');
assert(css.includes('PREMIUM MATHEMATICS EXAM PREP UX v3'), 'Premium Math Exam Prep UX marker missing');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 320, height: 740 }, javaScriptEnabled: false });
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
  assert(entry.titleSize >= 17, `Math feature title hierarchy too weak for peer preparation modes: ${entry.titleSize}`);
  assert(entry.width <= entry.innerWidth, `Math feature entry overflow: ${JSON.stringify(entry)}`);

  await page.evaluate(() => {
    const hub = document.getElementById('courses-subject-hub');
    hub.classList.add('exam-prep-host-open');
    const root = document.getElementById('exam-prep-host-root');
    root.hidden = false;
    root.setAttribute('aria-hidden', 'false');
    root.innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-dashboard-intro"><div><div class="ep-live-dashboard-eyebrow">Your route</div><h3 class="ep-live-dashboard-title">Preparation for P1 and P5</h3><p class="ep-live-dashboard-text">Each component moves separately with its own phase, evidence and next action.</p></div><div class="ep-live-dashboard-profile"><strong>Saved plan</strong><span>Target grade: A · Total: 16 h/week · Mathematics: 8 h/week</span></div></div><div class="ep-live-grid"><article class="ep-live-card ep-live-component-card"><div class="ep-live-component-head"><span class="ep-live-component-code">P1</span><div class="ep-live-component-copy"><strong>Pure Mathematics 1</strong><span>45 skills</span></div></div><div class="ep-live-actions"><button class="ep-live-btn">Open weekly plan</button></div></article><article class="ep-live-card ep-live-component-card"><div class="ep-live-component-head"><span class="ep-live-component-code">P5</span><div class="ep-live-component-copy"><strong>Probability & Statistics 1</strong><span>36 skills</span></div></div><div class="ep-live-actions"><button class="ep-live-btn">Start the next check section</button></div></article></div></section>`;
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

  const localizedProfiles = [
    { lang: 'en', label: 'Saved plan', value: 'Target grade: A · Total: 16 h/week · Mathematics: 8 h/week' },
    { lang: 'ru', label: 'Сохранённый план', value: 'Целевая оценка: A · Всего: 16 ч/неделю · Математика: 8 ч/неделю' },
    { lang: 'uz', label: 'Saqlangan reja', value: 'Maqsad baho: A · Jami: 16 soat/hafta · Matematika: 8 soat/hafta' }
  ];

  for (const profile of localizedProfiles) {
    const mobile = await page.evaluate(({ label, value }) => {
      const node = document.querySelector('.ep-live-dashboard-profile');
      node.querySelector('strong').textContent = label;
      node.querySelector('span').textContent = value;
      const root = document.getElementById('exam-prep-host-root');
      const rect = node.getBoundingClientRect();
      const rootRect = root.getBoundingClientRect();
      return {
        documentWidth: document.documentElement.scrollWidth,
        innerWidth: window.innerWidth,
        profileWidth: rect.width,
        rootWidth: rootRect.width,
        profileScrollWidth: node.scrollWidth,
        profileClientWidth: node.clientWidth
      };
    }, profile);
    assert(mobile.documentWidth <= mobile.innerWidth, `${profile.lang.toUpperCase()} Exam Prep mobile overflow: ${JSON.stringify(mobile)}`);
    assert(mobile.profileWidth <= mobile.rootWidth + 1, `${profile.lang.toUpperCase()} saved-plan card exceeds Exam Prep root: ${JSON.stringify(mobile)}`);
    assert(mobile.profileScrollWidth <= mobile.profileClientWidth + 1, `${profile.lang.toUpperCase()} saved-plan text does not wrap safely: ${JSON.stringify(mobile)}`);
  }

  await browser.close();
  console.log('Visual v3 Math Exam Prep UX regression: GREEN (320px EN/RU/UZ locale width safe)');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
