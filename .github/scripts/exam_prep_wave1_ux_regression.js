const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  await page.setContent(`<!doctype html><html lang="ru"><head></head><body class="iclub-visual-v3">
    <div id="exam-prep-host-root">
      <section class="ep-host-shell ep-live">
        <div class="ep-live-dashboard-profile">
          <strong>Сохранённый план</strong>
          <span>October 2027 · Цель: A · Всего: 5 ч/нед · Математика: 1 ч/нед</span>
        </div>
        <form data-ep-live-profile-form>
          <label class="ep-live-field"><input name="exam_series" value="October 2027" required aria-required="true"></label>
          <label class="ep-live-field"><input name="target_grade" value="A" required aria-required="true"></label>
        </form>
      </section>
    </div>
  </body></html>`);

  await page.evaluate(() => {
    window.__outerBack = 0;
    window.__internalBack = 0;
    window.__edit = 0;
    window.__correction = null;
    window.iClubExamPrepHostInternal = {
      learnerViews: {
        openCorrections(component) { window.__correction = component; }
      }
    };
    window.iClubExamPrep = Object.freeze({
      liveFlowVersion: 'test-live',
      back() { window.__outerBack += 1; return true; },
      open: async () => true,
      refreshCapabilities: async () => true,
      close: () => true,
      isOpen: () => true,
      syncSubjectHub: async () => true
    });
  });

  await page.addStyleTag({ path: path.resolve('exam-prep/exam-prep-wave1-ux.css') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-wave1-ux.js') });
  await page.waitForFunction(() => window.iClubExamPrep?.wave1UxVersion === 'wave1ux1');

  const assert = (condition, message) => { if (!condition) throw new Error(message); };

  let state = await page.evaluate(() => ({
    seriesTag: document.querySelector('[name="exam_series"]')?.tagName,
    gradeTag: document.querySelector('[name="target_grade"]')?.tagName,
    seriesValue: document.querySelector('[name="exam_series"]')?.value,
    gradeValue: document.querySelector('[name="target_grade"]')?.value,
    seriesOptions: Array.from(document.querySelector('[name="exam_series"]')?.options || []).map(o => o.value),
    gradeOptions: Array.from(document.querySelector('[name="target_grade"]')?.options || []).map(o => o.value)
  }));
  assert(state.seriesTag === 'SELECT' && state.gradeTag === 'SELECT', 'exam series and target grade must be selects');
  assert(state.seriesValue === 'October 2027', 'existing exam-series value must be preserved');
  assert(state.gradeValue === 'A', 'existing target grade must be preserved');
  assert(state.seriesOptions.includes('May/June 2027') && state.seriesOptions.includes('October/November 2027'), 'future exam-series options missing');
  assert(['A','B','C','D','E'].every(v => state.gradeOptions.includes(v)), 'AS target grades A-E missing');

  await page.evaluate(() => {
    const root = document.querySelector('#exam-prep-host-root');
    for (let i = 0; i < 3; i += 1) {
      const card = document.createElement('div');
      card.className = 'ep-live-card';
      card.dataset.epExamPlanCard = 'true';
      card.innerHTML = `<button class="ep-live-btn secondary" data-ep-exam-plan-edit>Изменить план</button>`;
      card.querySelector('button').addEventListener('click', () => { window.__edit += 1; });
      root.querySelector('.ep-host-shell').appendChild(card);
    }
  });
  await page.waitForFunction(() => document.querySelectorAll('.ep-live-card[data-ep-exam-plan-card]').length === 0 && document.querySelectorAll('.ep-live-dashboard-profile [data-ep-exam-plan-edit]').length === 1);

  state = await page.evaluate(() => ({
    duplicateCards: document.querySelectorAll('.ep-live-card[data-ep-exam-plan-card]').length,
    editButtons: document.querySelectorAll('.ep-live-dashboard-profile [data-ep-exam-plan-edit]').length,
    marker: document.querySelector('.ep-live-dashboard-profile')?.getAttribute('data-ep-exam-plan-card')
  }));
  assert(state.duplicateCards === 0, 'duplicate Exam plan cards must be removed');
  assert(state.editButtons === 1, 'Change plan must exist exactly once under Saved plan');
  assert(state.marker === 'true', 'dashboard profile must block duplicate exam-plan hydration');
  await page.click('.ep-live-dashboard-profile [data-ep-exam-plan-edit]');
  assert(await page.evaluate(() => window.__edit) === 1, 'moved Change plan button must retain its handler');

  await page.evaluate(() => {
    const root = document.querySelector('#exam-prep-host-root');
    const internalBack = document.createElement('button');
    internalBack.dataset.epMaterialsBack = 'true';
    internalBack.textContent = 'Обзор';
    internalBack.addEventListener('click', () => { window.__internalBack += 1; internalBack.remove(); });
    root.appendChild(internalBack);
  });
  await page.evaluate(() => window.iClubExamPrep.back());
  state = await page.evaluate(() => ({ internal: window.__internalBack, outer: window.__outerBack }));
  assert(state.internal === 1 && state.outer === 0, 'top back must return inside Exam Prep before exiting to subject hub');
  await page.evaluate(() => window.iClubExamPrep.back());
  assert(await page.evaluate(() => window.__outerBack) === 1, 'top back may exit only from Exam Prep root/dashboard');

  await page.evaluate(() => {
    document.querySelector('#exam-prep-host-root').innerHTML = `<section data-ep-placement-screen><div class="ep-placement-sub">P1 · Cambridge AS Mathematics</div><button data-ep-placement-next>Разобрать ошибку</button></section>`;
  });
  await page.click('[data-ep-placement-next]');
  assert(await page.evaluate(() => window.__correction) === 'P1', 'Work on correction must open the correction view for the same component');

  await page.evaluate(() => {
    document.querySelector('#exam-prep-host-root').innerHTML = `<div class="ep-live-actions">
      <button class="ep-live-btn">Основное действие</button>
      <button class="ep-placement-btn">Результат</button>
      <button class="ep-views-btn">Ошибки</button>
      <button class="ep-materials-btn">Материалы</button>
    </div>`;
  });
  state = await page.evaluate(() => {
    const selectors = ['.ep-live-btn','.ep-placement-btn','.ep-views-btn','.ep-materials-btn'];
    return selectors.map(selector => {
      const style = getComputedStyle(document.querySelector(selector));
      return { minHeight: style.minHeight, radius: style.borderRadius, fontSize: style.fontSize };
    });
  });
  assert(new Set(state.map(x => x.minHeight)).size === 1, 'Exam Prep button minimum heights must be unified');
  assert(new Set(state.map(x => x.radius)).size === 1, 'Exam Prep button radii must be unified');
  assert(new Set(state.map(x => x.fontSize)).size === 1, 'Exam Prep button typography must be unified');

  await browser.close();
  console.log('Exam Prep Wave 1 learner UX regression: PASS');
})().catch(error => { console.error(error); process.exit(1); });