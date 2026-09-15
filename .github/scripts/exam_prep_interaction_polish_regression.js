const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.setContent(`<!doctype html><html lang="ru"><body class="iclub-visual-v3"><div id="exam-prep-host-root"></div><div id="toast" class="toast" role="status" aria-live="polite"></div></body></html>`);
  await page.evaluate(() => { window.i18n = { getLang: () => 'ru' }; window.iClubExamPrepHostInternal = {}; });
  await page.addStyleTag({ path: path.resolve('exam-prep/exam-prep-interaction-polish.css') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-interaction-polish.js') });
  await page.waitForFunction(() => window.iClubExamPrepHostInternal?.interactionPolish?.version === 'polish2');
  const assert = (condition, message) => { if (!condition) throw new Error(message); };

  await page.evaluate(() => {
    document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-card"><div class="ep-live-head"><div><strong>P1 · Недельный план</strong><div class="ep-live-meta">Неделя 1</div></div><button class="ep-live-btn secondary" data-ep-live-dashboard>К подготовке</button></div><div class="ep-flow-plan-intro">План показывает до трёх самых важных заданий. Начните с первого.</div><div class="ep-live-plan-item"><div><strong class="ep-flow-task-type">Закрепить после разбора</strong><div class="ep-flow-task-name">Переводить degrees ↔ radians и использовать radians как естественную угловую меру.</div><div class="ep-flow-task-meta">Радианная мера и окружность · Навык 21</div></div><button class="ep-live-btn" data-ep-live-plan-item="1">Начать закрепление</button></div></div></section>`;
  });
  await page.waitForFunction(() => !document.querySelector('.ep-flow-plan-intro'));
  let state = await page.evaluate(() => ({
    backHidden: document.querySelector('[data-ep-live-dashboard]')?.hidden,
    title: document.querySelector('.ep-flow-task-name')?.textContent,
    meta: document.querySelector('.ep-flow-task-meta')?.textContent,
    hasLocalScreenAnimation: Boolean(document.querySelector('.ep-flow-screen-enter'))
  }));
  assert(state.backHidden === true, 'weekly plan must rely on the app top back control instead of duplicating a large in-card back button');
  assert(state.title.includes('градусы') && state.title.includes('радианы') && !state.title.includes('degrees'), 'learner-facing Russian skill title must be humanized');
  assert(state.meta === 'Радианная мера и окружность', 'internal skill number must not be exposed in weekly-plan metadata');
  assert(state.hasLocalScreenAnimation === false, 'Exam Prep must not add a local fade/translate transition that the main app does not use');

  await page.evaluate(() => {
    const root = document.querySelector('#exam-prep-host-root');
    root.innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-card"><div class="ep-live-head"><strong>Вопрос 1 / 3</strong></div><div class="ep-live-qtext">2 + 2 = ?</div><div class="ep-live-actions"><button class="ep-live-btn" data-ep-live-submit>Отправить ответ</button></div></div></section>`;
    root.querySelector('[data-ep-live-submit]').addEventListener('click', () => {
      root.innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-card" role="status" aria-live="polite">Загрузка…</div></section>`;
    });
  });
  await page.click('[data-ep-live-submit]');
  await page.waitForSelector('.ep-flow-pending-visual');
  state = await page.evaluate(() => ({
    question: document.querySelector('.ep-live-qtext')?.textContent,
    pending: document.querySelector('.ep-flow-submit-pending')?.textContent,
    hasFullscreenLoading: Boolean(document.querySelector('.ep-flow-loading-surface')),
    opacity: getComputedStyle(document.querySelector('.ep-flow-pending-visual')).opacity,
    animation: getComputedStyle(document.querySelector('.ep-flow-pending-visual')).animationName
  }));
  assert(state.question === '2 + 2 = ?', 'answer submit must keep the question visually stable while saving');
  assert(state.pending.includes('Сохраняем ответ'), 'submit button must show inline saving progress');
  assert(state.hasFullscreenLoading === false, 'answer submit must not flash a full-screen loading card');
  assert(state.opacity === '1', `question surface must not dim while saving; got opacity ${state.opacity}`);
  assert(state.animation === 'none', `question surface must not animate while saving; got ${state.animation}`);

  await page.evaluate(() => {
    const session = { session_id: 's1', session_type: 'diagnostic' };
    window.dispatchEvent(new CustomEvent('iclub:exam-prep-session', { detail: { session } }));
    document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-notice" role="status" aria-live="polite">Верно — технический длинный текст — next action</div><div class="ep-live-card"><div class="ep-live-head"><strong>Вопрос 2 / 3</strong></div><div class="ep-live-qtext">3 + 3 = ?</div><button data-ep-live-submit>Отправить ответ</button></div></section>`;
  });
  await page.waitForFunction(() => !document.querySelector('#exam-prep-host-root .ep-live-notice'));
  state = await page.evaluate(() => ({
    toast: document.querySelector('#toast')?.textContent,
    toastShown: document.querySelector('#toast')?.classList.contains('is-show'),
    customToast: Boolean(document.querySelector('.ep-flow-answer-toast')),
    question: document.querySelector('.ep-live-qtext')?.textContent,
    hasLocalScreenAnimation: Boolean(document.querySelector('.ep-flow-screen-enter'))
  }));
  assert(state.toastShown === true && state.toast === 'Ответ сохранён', 'diagnostic feedback must use the shared app toast with short learner-facing copy');
  assert(state.customToast === false, 'Exam Prep must not create its own toast surface outside the app visual system');
  assert(state.question === '3 + 3 = ?', 'next question must remain visible and stable');
  assert(state.hasLocalScreenAnimation === false, 'question-to-question change must match the main app direct stack transition');

  await page.evaluate(() => {
    document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-card ep-flow-loading-surface" role="status"><div class="ep-flow-loader"><span class="ep-flow-spinner"></span><div><strong>Обновляем недельный план…</strong><small>Прогресс сохраняется. Не закрывайте экран.</small></div></div></div></section>`;
  });
  await page.waitForFunction(() => document.querySelector('.ep-flow-loading-compact') && !document.querySelector('.ep-flow-loader small'));
  assert(await page.evaluate(() => Boolean(document.querySelector('.ep-flow-loading-compact'))), 'general loading must be compact and visually active without technical helper text');

  await browser.close();
  console.log('Exam Prep interaction polish regression: GREEN');
})().catch(error => { console.error(error); process.exit(1); });