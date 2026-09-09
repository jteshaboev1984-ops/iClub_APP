const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');

for (const token of [
  'PREMIUM ASSESSMENT FLOWS v3',
  '#courses-practice-start .practice-hero',
  '#courses-practice-quiz .option',
  '#courses-tours .tours-hero',
  '#courses-tour-rules .checkbox',
  '#courses-tour-quiz .tour-head',
  '#courses-tour-quiz .tour-timer-card',
  '#courses-tour-quiz .v3-tour-warning-icon'
]) {
  assert(css.includes(token), `Assessment premium CSS missing ${token}`);
}

assert(html.includes('id="tour-warn-btn"'), 'Tour warning button missing');
assert(html.includes('class="v3-tour-warning-icon"'), 'Tour warning line SVG missing');
assert(!/<button id="tour-warn-btn"[^>]*>[\s\n]*⚠️/.test(html), 'Tour warning emoji leaked');

for (const forbidden of [
  /localStorage/i,
  /sessionStorage/i,
  /supabase/i,
  /\.rpc\s*\(/,
  /\.from\s*\(/,
  /operational_stage\s*=/,
  /innerHTML\s*=/,
  /data-action\s*=/
]) {
  assert(!forbidden.test(css), `Assessment premium CSS is not visual-only: ${forbidden}`);
}

async function activateCourseScreen(page, id) {
  await page.evaluate((id) => {
    document.querySelectorAll('.view').forEach(v => v.classList.remove('is-active'));
    const courses = document.getElementById('view-courses');
    courses.classList.add('is-active');
    document.querySelectorAll('#courses-stack .stack-screen').forEach(s => {
      s.classList.remove('is-active');
      s.hidden = true;
      s.setAttribute('aria-hidden', 'true');
    });
    const screen = document.getElementById(id);
    if (!screen) throw new Error(`missing ${id}`);
    screen.classList.add('is-active');
    screen.hidden = false;
    screen.setAttribute('aria-hidden', 'false');
  }, id);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, javaScriptEnabled: false });
  const url = process.env.VISUAL_V3_ASSESSMENT_URL || 'http://127.0.0.1:4173/index.html';
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  await activateCourseScreen(page, 'courses-practice-start');
  let state = await page.evaluate(() => ({
    heroRadius: getComputedStyle(document.querySelector('#courses-practice-start .practice-hero')).borderRadius,
    heroBg: getComputedStyle(document.querySelector('#courses-practice-start .practice-hero')).backgroundImage,
    heroText: getComputedStyle(document.querySelector('#courses-practice-start .practice-hero')).color,
    metricRadius: getComputedStyle(document.querySelector('#courses-practice-start .practice-metric')).borderRadius,
    tableRadius: getComputedStyle(document.querySelector('#courses-practice-start .practice-table-wrap')).borderRadius,
    width: document.documentElement.scrollWidth,
    innerWidth: innerWidth
  }));
  assert(state.heroRadius === '12px', `Practice hero radius drift: ${state.heroRadius}`);
  assert(state.heroBg.includes('linear-gradient'), 'Practice premium hero background missing');
  assert(state.heroText === 'rgb(15, 23, 42)', `Practice hero text contrast drift: ${state.heroText}`);
  assert(state.metricRadius === '10px', `Practice metric radius drift: ${state.metricRadius}`);
  assert(state.tableRadius === '10px', `Practice table radius drift: ${state.tableRadius}`);
  assert(state.width <= state.innerWidth, `Practice start overflow: ${JSON.stringify(state)}`);

  await activateCourseScreen(page, 'courses-practice-quiz');
  await page.evaluate(() => {
    const options = document.getElementById('practice-options');
    options.innerHTML = '<button class="option is-selected"><span class="dot"></span><span class="opt-text">Sample answer used only by visual regression</span></button><button class="option"><span class="dot"></span><span class="opt-text">Second sample answer</span></button>';
  });
  state = await page.evaluate(() => ({
    cardRadius: getComputedStyle(document.querySelector('#courses-practice-quiz > .card')).borderRadius,
    optionRadius: getComputedStyle(document.querySelector('#courses-practice-quiz .option')).borderRadius,
    selectedBg: getComputedStyle(document.querySelector('#courses-practice-quiz .option.is-selected')).backgroundColor,
    questionSize: getComputedStyle(document.querySelector('#courses-practice-quiz .question-text')).fontSize,
    width: document.documentElement.scrollWidth,
    innerWidth: innerWidth
  }));
  assert(state.cardRadius === '12px', `Practice quiz card radius drift: ${state.cardRadius}`);
  assert(state.optionRadius === '10px', `Practice option radius drift: ${state.optionRadius}`);
  assert(state.selectedBg === 'rgb(238, 243, 255)', `Practice selected state drift: ${state.selectedBg}`);
  assert(state.questionSize === '14px', `Practice mobile question size drift: ${state.questionSize}`);
  assert(state.width <= state.innerWidth, `Practice quiz overflow: ${JSON.stringify(state)}`);

  await activateCourseScreen(page, 'courses-tours');
  state = await page.evaluate(() => ({
    heroRadius: getComputedStyle(document.querySelector('#courses-tours .tours-hero')).borderRadius,
    heroText: getComputedStyle(document.querySelector('#courses-tours .tours-hero')).color,
    metricRadius: getComputedStyle(document.querySelector('#courses-tours .tours-metric')).borderRadius,
    historyRadius: getComputedStyle(document.querySelector('#courses-tours .tours-history')).borderRadius,
    width: document.documentElement.scrollWidth,
    innerWidth: innerWidth
  }));
  assert(state.heroRadius === '12px', `Tours hero radius drift: ${state.heroRadius}`);
  assert(state.heroText === 'rgb(15, 23, 42)', `Tours hero contrast drift: ${state.heroText}`);
  assert(state.metricRadius === '10px', `Tours metric radius drift: ${state.metricRadius}`);
  assert(state.historyRadius === '12px', `Tours history radius drift: ${state.historyRadius}`);
  assert(state.width <= state.innerWidth, `Tours overview overflow: ${JSON.stringify(state)}`);

  await activateCourseScreen(page, 'courses-tour-quiz');
  await page.evaluate(() => {
    const warning = document.getElementById('tour-warn-btn');
    warning.style.display = 'grid';
    const options = document.getElementById('tour-options');
    options.innerHTML = '<button class="option is-selected"><span class="dot"></span><span class="opt-text">Sample tour answer</span></button>';
  });
  state = await page.evaluate(() => ({
    headRadius: getComputedStyle(document.querySelector('#courses-tour-quiz .tour-head')).borderRadius,
    warningRadius: getComputedStyle(document.querySelector('#courses-tour-quiz .tour-warn')).borderRadius,
    warningIcons: document.querySelectorAll('#courses-tour-quiz .v3-tour-warning-icon').length,
    badgeBg: getComputedStyle(document.querySelector('#courses-tour-quiz .tour-badge')).backgroundColor,
    timerRadius: getComputedStyle(document.querySelector('#courses-tour-quiz .tour-timer-card')).borderRadius,
    dangerBg: getComputedStyle(document.querySelector('#courses-tour-quiz .tour-timer-card.danger')).backgroundColor,
    optionRadius: getComputedStyle(document.querySelector('#courses-tour-quiz .option')).borderRadius,
    width: document.documentElement.scrollWidth,
    innerWidth: innerWidth
  }));
  assert(state.headRadius === '12px', `Tour head radius drift: ${state.headRadius}`);
  assert(state.warningRadius === '10px', `Tour warning radius drift: ${state.warningRadius}`);
  assert(state.warningIcons === 1, `Tour warning SVG count drift: ${state.warningIcons}`);
  assert(state.badgeBg === 'rgb(238, 243, 255)', `Tour badge state drift: ${state.badgeBg}`);
  assert(state.timerRadius === '10px', `Tour timer radius drift: ${state.timerRadius}`);
  assert(state.dangerBg === 'rgb(255, 245, 243)', `Tour danger timer semantics drift: ${state.dangerBg}`);
  assert(state.optionRadius === '10px', `Tour option radius drift: ${state.optionRadius}`);
  assert(state.width <= state.innerWidth, `Tour quiz overflow: ${JSON.stringify(state)}`);

  const routes = await page.locator('#tabbar .tab').evaluateAll(nodes => nodes.map(n => n.getAttribute('data-tab')));
  assert(JSON.stringify(routes) === JSON.stringify(['home', 'courses', 'ratings', 'profile']), `Assessment premium pass changed routes: ${JSON.stringify(routes)}`);

  await browser.close();
  console.log('Visual v3 premium assessment flow regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
