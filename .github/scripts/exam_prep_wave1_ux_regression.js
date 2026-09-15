const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.setContent(`<!doctype html><html lang="ru"><head></head><body class="iclub-visual-v3">
    <button id="topbar-back" type="button">Back</button>
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
    window.__readCalls = 0;
    window.__writeCalls = [];
    window.__recovered = 0;

    document.querySelector('#topbar-back').addEventListener('click', () => {
      window.__outerBack += 1;
    });

    window.iClubExamPrepHostInternal = {
      api: {
        async diagnosticProgress(component) {
          window.__readCalls += 1;
          if (window.__readCalls === 1) return { ok: false, reason: 'temporary_network' };
          return { ok: true, data: { component_code: component } };
        },
        async submitResponse(...args) {
          window.__writeCalls.push(args);
          if (window.__writeCalls.length === 1) return { ok: false, reason: 'temporary_network' };
          return { ok: true, data: { accepted: true } };
        }
      },
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
  await page.waitForFunction(() => window.iClubExamPrep?.wave1UxVersion === 'wave1ux2');

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

  const retryState = await page.evaluate(async () => {
    const read = await window.iClubExamPrepHostInternal.api.diagnosticProgress('P1');
    const write = await window.iClubExamPrepHostInternal.api.submitResponse('session-1', 1, { picked_index: 2 }, 'same-idempotency-key', 1500, 'ru');
    return {
      read,
      write,
      readCalls: window.__readCalls,
      writeCalls: window.__writeCalls.map(args => ({ sessionId: args[0], itemOrder: args[1], key: args[3] }))
    };
  });
  assert(retryState.read?.ok === true && retryState.readCalls === 2, 'transient read failure must recover with bounded retry');
  assert(retryState.write?.ok === true && retryState.writeCalls.length === 2, 'idempotent response write must retry once');
  assert(retryState.writeCalls.every(call => call.key === 'same-idempotency-key'), 'write retry must reuse the exact idempotency key');

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
  await page.click('#topbar-back');
  state = await page.evaluate(() => ({ internal: window.__internalBack, outer: window.__outerBack }));
  assert(state.internal === 1 && state.outer === 0, 'real topbar back must handle an internal Exam Prep screen before the app shell');

  await page.click('#topbar-back');
  assert(await page.evaluate(() => window.__outerBack) === 1, 'topbar back must fall through to the app shell from the Exam Prep root');

  await page.evaluate(() => {
    document.querySelector('#exam-prep-host-root').innerHTML = `<section data-ep-placement-screen><div class="ep-placement-sub">P1 · Cambridge AS Mathematics</div><button data-ep-placement-next>Разобрать ошибку</button></section>`;
  });
  await page.click('[data-ep-placement-next]');
  assert(await page.evaluate(() => window.__correction) === 'P1', 'Work on correction must open the correction view for the same component');

  await page.evaluate(() => {
    const root = document.querySelector('#exam-prep-host-root');
    root.innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-error">Не удалось выполнить действие. Попробуйте ещё раз.</div><button class="ep-live-btn secondary" data-ep-live-home>Обзор</button></section>`;
    root.querySelector('[data-ep-live-home]').addEventListener('click', () => {
      window.__recovered += 1;
      root.innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-grid">Recovered dashboard</div></section>`;
    });
  });
  await page.waitForFunction(() => window.__recovered === 1 && document.querySelector('.ep-live-grid'));
  assert(await page.evaluate(() => window.__recovered) === 1, 'generic transient live error must recover once without learner progress reset');

  await page.evaluate(() => {
    document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-card">
      <div class="ep-live-options">
        <label class="ep-live-option"><input type="radio" name="answer" value="0"><span>2</span></label>
        <label class="ep-live-option"><input type="radio" name="answer" value="1"><span>Longer answer option that wraps safely on a narrow mobile screen</span></label>
        <label class="ep-live-option"><input type="radio" name="answer" value="2"><span>16</span></label>
      </div>
      <div class="ep-live-actions"><button class="ep-live-btn">Ответить</button><button class="ep-live-btn secondary">Назад</button></div>
      <div class="ep-placement-actions"><button class="ep-placement-btn primary">Продолжить</button></div>
      <div class="ep-views-actions"><button class="ep-views-btn">Ошибки</button><button class="ep-materials-btn">Материалы</button></div>
    </div></section>`;
  });

  state = await page.evaluate(() => {
    const actionSelectors = ['.ep-live-btn','.ep-placement-btn','.ep-views-btn','.ep-materials-btn'];
    const actions = actionSelectors.map(selector => {
      const style = getComputedStyle(document.querySelector(selector));
      return { minHeight: style.minHeight, radius: style.borderRadius, fontSize: style.fontSize };
    });
    const optionRects = Array.from(document.querySelectorAll('.ep-live-option')).map(node => node.getBoundingClientRect());
    const actionRects = Array.from(document.querySelectorAll('.ep-live-actions > button')).map(node => node.getBoundingClientRect());
    return {
      actions,
      optionWidths: optionRects.map(rect => Math.round(rect.width)),
      optionMinHeights: Array.from(document.querySelectorAll('.ep-live-option')).map(node => getComputedStyle(node).minHeight),
      actionWidths: actionRects.map(rect => Math.round(rect.width))
    };
  });
  assert(new Set(state.actions.map(x => x.minHeight)).size === 1, 'Exam Prep action button minimum heights must be unified');
  assert(new Set(state.actions.map(x => x.radius)).size === 1, 'Exam Prep action button radii must be unified');
  assert(new Set(state.actions.map(x => x.fontSize)).size === 1, 'Exam Prep action button typography must be unified');
  assert(new Set(state.optionWidths).size === 1, 'all answer choices must use the same full width');
  assert(new Set(state.optionMinHeights).size === 1 && state.optionMinHeights[0] === '52px', 'answer choices must share one minimum tap height');
  assert(new Set(state.actionWidths).size === 1, 'question action buttons must use equal widths');

  await browser.close();
  console.log('Exam Prep Wave 1 stability and learner UX regression: PASS');
})().catch(error => { console.error(error); process.exit(1); });