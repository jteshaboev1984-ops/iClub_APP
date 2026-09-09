const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');

for (const token of [
  'PREMIUM SUBJECT HUB ARCHITECTURE v3.1',
  'PREMIUM SUBJECT HUB ACTION AFFORDANCE v3.2',
  '#courses-subject-hub.is-active:not([hidden])',
  '#courses-subject-hub > #subject-hub-exam-prep-entry',
  '#courses-subject-hub > .subject-hub-tabs',
  '#courses-subject-hub > .subject-hub-panels'
]) {
  assert(css.includes(token), `Subject Hub architecture CSS missing ${token}`);
}

for (const forbidden of [/localStorage/i, /sessionStorage/i, /supabase/i, /\.rpc\s*\(/, /\.from\s*\(/, /operational_stage\s*=/, /innerHTML\s*=/]) {
  assert(!forbidden.test(css), `Subject Hub architecture layer is not presentation-only: ${forbidden}`);
}

for (const action of ['open-lessons', 'open-practice', 'open-tours', 'open-books', 'open-subject-mentor', 'open-exam-prep']) {
  assert(html.includes(`data-action="${action}"`), `Subject Hub action contract missing: ${action}`);
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
    const entry = document.getElementById('subject-hub-exam-prep-entry');
    const tabs = hub.querySelector('.subject-hub-tabs');
    const actions = hub.querySelector('.subject-hub-actions');
    const panels = hub.querySelector('.subject-hub-panels');
    const systemSection = Array.from(hub.children).find(node => node.classList?.contains('section'));
    const bottom = hub.querySelector('.subject-hub-bottom');
    const firstTab = tabs.querySelector('.hub-tab');
    return {
      display: getComputedStyle(hub).display,
      orders: {
        head: Number(getComputedStyle(head).order),
        entry: Number(getComputedStyle(entry).order),
        tabs: Number(getComputedStyle(tabs).order),
        actions: Number(getComputedStyle(actions).order),
        panels: Number(getComputedStyle(panels).order),
        system: Number(getComputedStyle(systemSection).order),
        bottom: Number(getComputedStyle(bottom).order)
      },
      tabsColumns: getComputedStyle(tabs).gridTemplateColumns.split(' ').length,
      tabHeight: firstTab.getBoundingClientRect().height,
      activeTabBackground: getComputedStyle(firstTab).backgroundColor,
      activeTabColor: getComputedStyle(firstTab).color,
      mentorBeforeFeature: panels.getBoundingClientRect().top < entry.getBoundingClientRect().top,
      width: document.documentElement.scrollWidth,
      innerWidth: innerWidth
    };
  });

  assert(state.display === 'flex', `Subject Hub active layout must be flex, got ${state.display}`);
  assert(JSON.stringify(state.orders) === JSON.stringify({ head: 10, entry: 20, tabs: 30, actions: 40, panels: 15, system: 60, bottom: 80 }), `Subject Hub hierarchy drift: ${JSON.stringify(state.orders)}`);
  assert(state.tabsColumns === 2, `Subject Hub mobile primary actions must be 2 columns, got ${state.tabsColumns}`);
  assert(state.tabHeight >= 54, `Subject Hub primary action target too small: ${state.tabHeight}`);
  assert(state.activeTabBackground === 'rgb(255, 255, 255)', `Primary action must not look pre-selected: ${state.activeTabBackground}`);
  assert(state.activeTabColor === 'rgb(15, 23, 42)', `Primary action selected-color leak: ${state.activeTabColor}`);
  assert(state.mentorBeforeFeature === true, 'Mentor card must stay in its original place directly after the subject header');
  assert(state.width <= state.innerWidth, `Subject Hub mobile overflow: ${JSON.stringify(state)}`);

  await page.evaluate(() => {
    const hub = document.getElementById('courses-subject-hub');
    const root = document.getElementById('exam-prep-host-root');
    root.hidden = false;
    root.setAttribute('aria-hidden', 'false');
    hub.classList.add('exam-prep-host-open');
  });

  state = await page.evaluate(() => ({
    head: getComputedStyle(document.querySelector('#courses-subject-hub .subject-hub-head')).display,
    root: getComputedStyle(document.getElementById('exam-prep-host-root')).display,
    width: document.documentElement.scrollWidth,
    innerWidth: innerWidth
  }));
  assert(state.head === 'none', `Exam Prep open state must hide Subject Hub siblings, got head=${state.head}`);
  assert(state.root !== 'none', 'Exam Prep host root must remain visible when open');
  assert(state.width <= state.innerWidth, `Exam Prep open overflow after Subject Hub architecture pass: ${JSON.stringify(state)}`);

  await page.evaluate(() => {
    const hub = document.getElementById('courses-subject-hub');
    hub.classList.remove('exam-prep-host-open', 'is-active');
    hub.hidden = true;
  });
  state = await page.evaluate(() => getComputedStyle(document.getElementById('courses-subject-hub')).display);
  assert(state === 'none', `Inactive/hidden Subject Hub leaked into layout: ${state}`);

  await browser.close();
  console.log('Visual v3 Subject Hub architecture regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
