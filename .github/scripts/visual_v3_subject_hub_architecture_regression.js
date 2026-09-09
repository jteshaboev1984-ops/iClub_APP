const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');
const i18n = fs.readFileSync('i18n.js', 'utf8');

for (const token of [
  'PREMIUM SUBJECT HUB LEARNING MODES v3.4',
  '#courses-subject-hub > .subject-hub-primary-modes',
  '.subject-mode-card-practice',
  '.subject-mode-card-tours',
  '.subject-mode-status-practice',
  '.subject-mode-status-tours',
  '#courses-subject-hub > .subject-hub-panels'
]) {
  assert(css.includes(token), `Subject Hub learning-mode CSS missing ${token}`);
}

for (const forbidden of [/localStorage/i, /sessionStorage/i, /supabase/i, /\.rpc\s*\(/, /\.from\s*\(/, /operational_stage\s*=/, /innerHTML\s*=/]) {
  assert(!forbidden.test(css), `Subject Hub architecture layer is not presentation-only: ${forbidden}`);
}

const hubMatch = html.match(/<section id="courses-subject-hub"[\s\S]*?<\/section>/);
assert(hubMatch, 'Subject Hub markup missing');
const hubHtml = hubMatch[0];
assert(!hubHtml.includes('class="subject-hub-tabs"'), 'Legacy Content/Practice/Tours/Resources tab strip must be removed from Subject Hub');
assert((hubHtml.match(/data-action="open-lessons"/g) || []).length === 1, 'Video lessons must have exactly one Subject Hub entry');
for (const action of ['open-lessons', 'open-practice', 'open-tours', 'open-books', 'open-subject-mentor', 'open-exam-prep']) {
  assert(hubHtml.includes(`data-action="${action}"`), `Subject Hub action contract missing: ${action}`);
}
for (const key of ['hub_preparation_section', 'hub_practice_status', 'hub_practice_sub', 'hub_tours_status', 'hub_tours_sub', 'hub_materials_section', 'hub_resources_sub']) {
  assert((i18n.match(new RegExp(`${key}:`, 'g')) || []).length === 3, `i18n key ${key} must exist in RU/UZ/EN`);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, javaScriptEnabled: false });
  const url = process.env.VISUAL_V3_PREMIUM_URL || 'http://127.0.0.1:4173/index.html';
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  await page.evaluate(() => {
    document.querySelectorAll('.view').forEach(node => node.classList.remove('is-active'));
    const courses = document.getElementById('view-courses');
    courses.classList.add('is-active');
    document.querySelectorAll('#courses-stack .stack-screen').forEach(node => {
      node.classList.remove('is-active');
      node.hidden = true;
      node.setAttribute('aria-hidden', 'true');
    });
    const hub = document.getElementById('courses-subject-hub');
    hub.hidden = false;
    hub.removeAttribute('aria-hidden');
    hub.classList.add('is-active', 'exam-prep-available');
    const entry = document.getElementById('subject-hub-exam-prep-entry');
    entry.hidden = false;
    entry.setAttribute('aria-hidden', 'false');
  });

  let state = await page.evaluate(() => {
    const hub = document.getElementById('courses-subject-hub');
    const head = hub.querySelector('.subject-hub-head');
    const panels = hub.querySelector('.subject-hub-panels');
    const primary = hub.querySelector('.subject-hub-primary-modes');
    const entry = document.getElementById('subject-hub-exam-prep-entry');
    const practice = hub.querySelector('.subject-mode-card-practice');
    const tours = hub.querySelector('.subject-mode-card-tours');
    const practiceStatus = practice.querySelector('.subject-mode-status-practice');
    const toursStatus = tours.querySelector('.subject-mode-status-tours');
    const materials = hub.querySelector('.subject-hub-materials-section');
    const actions = hub.querySelector('.subject-hub-actions');
    const system = hub.querySelector('.subject-hub-system-section');
    const bottom = hub.querySelector('.subject-hub-bottom');
    return {
      display: getComputedStyle(hub).display,
      orders: {
        head: Number(getComputedStyle(head).order),
        panels: Number(getComputedStyle(panels).order),
        primary: Number(getComputedStyle(primary).order),
        materials: Number(getComputedStyle(materials).order),
        actions: Number(getComputedStyle(actions).order),
        system: Number(getComputedStyle(system).order),
        bottom: Number(getComputedStyle(bottom).order)
      },
      primaryColumns: getComputedStyle(primary).gridTemplateColumns.split(' ').length,
      practiceHeight: practice.getBoundingClientRect().height,
      toursHeight: tours.getBoundingClientRect().height,
      practiceRadius: getComputedStyle(practice).borderRadius,
      toursRadius: getComputedStyle(tours).borderRadius,
      examRadius: getComputedStyle(entry).borderRadius,
      practiceStatusBackground: getComputedStyle(practiceStatus).backgroundColor,
      toursStatusBackground: getComputedStyle(toursStatus).backgroundColor,
      mentorBeforePrimary: panels.getBoundingClientRect().top < primary.getBoundingClientRect().top,
      materialsAfterPrimary: materials.getBoundingClientRect().top > primary.getBoundingClientRect().top,
      secondaryGroupBorder: getComputedStyle(actions).borderTopStyle,
      width: document.documentElement.scrollWidth,
      innerWidth: innerWidth
    };
  });

  assert(state.display === 'flex', `Subject Hub active layout must be flex, got ${state.display}`);
  assert(JSON.stringify(state.orders) === JSON.stringify({ head: 10, panels: 15, primary: 20, materials: 30, actions: 40, system: 60, bottom: 80 }), `Subject Hub hierarchy drift: ${JSON.stringify(state.orders)}`);
  assert(state.primaryColumns === 1, `Primary preparation products must be full-width on mobile, got ${state.primaryColumns} columns`);
  assert(state.practiceHeight >= 108 && state.toursHeight >= 108, `Practice/Tours lost primary visual weight: ${JSON.stringify(state)}`);
  assert(state.practiceRadius === state.toursRadius && state.practiceRadius === state.examRadius, `Preparation product family radius mismatch: ${JSON.stringify(state)}`);
  assert(state.practiceStatusBackground !== state.toursStatusBackground, 'Practice and Tours access properties must remain visually distinct');
  assert(state.mentorBeforePrimary === true, 'Mentor card must stay directly after the subject header');
  assert(state.materialsAfterPrimary === true, 'Materials must remain secondary to Exam Prep / Practice / Tours');
  assert(state.secondaryGroupBorder === 'solid', `Materials actions must read as one grouped list, border=${state.secondaryGroupBorder}`);
  assert(state.width <= state.innerWidth, `Subject Hub mobile overflow: ${JSON.stringify(state)}`);

  await page.evaluate(() => {
    const hub = document.getElementById('courses-subject-hub');
    const root = document.getElementById('exam-prep-host-root');
    root.hidden = false;
    root.setAttribute('aria-hidden', 'false');
    hub.classList.add('exam-prep-host-open');
  });

  state = await page.evaluate(() => ({
    primary: getComputedStyle(document.querySelector('#courses-subject-hub .subject-hub-primary-modes')).display,
    head: getComputedStyle(document.querySelector('#courses-subject-hub .subject-hub-head')).display,
    root: getComputedStyle(document.getElementById('exam-prep-host-root')).display,
    width: document.documentElement.scrollWidth,
    innerWidth: innerWidth
  }));
  assert(state.primary === 'none' && state.head === 'none', `Exam Prep open state must hide Subject Hub siblings: ${JSON.stringify(state)}`);
  assert(state.root !== 'none', 'Exam Prep host root must remain visible when open');
  assert(state.width <= state.innerWidth, `Exam Prep open overflow after Subject Hub learning-mode pass: ${JSON.stringify(state)}`);

  await page.evaluate(() => {
    const hub = document.getElementById('courses-subject-hub');
    hub.classList.remove('exam-prep-host-open', 'is-active');
    hub.hidden = true;
  });
  state = await page.evaluate(() => getComputedStyle(document.getElementById('courses-subject-hub')).display);
  assert(state === 'none', `Inactive/hidden Subject Hub leaked into layout: ${state}`);

  await browser.close();
  console.log('Visual v3 Subject Hub learning modes regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
