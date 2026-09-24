const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });

  await page.setContent(`<!doctype html><html lang="ru"><head></head><body class="iclub-visual-v3">
    <div id="exam-prep-host-root"></div>
  </body></html>`);

  await page.evaluate(() => {
    window.i18n = { getLang: () => 'ru' };
    window.__startedPriority = null;
    window.__queueStep = 'review_error';
    window.__planType = 'correction';

    const skill = {
      sequence_no: 21,
      skill_code: 'P1-CIR-01',
      description: 'Переводить degrees ↔ radians и использовать radians как естественную угловую меру.',
      evidence_total: 2,
      official_syllabus_section: '1.4 Circular measure'
    };
    const tracker = {
      component_code: 'P1',
      areas: [{ official_syllabus_section: '1.4 Circular measure', skills: [skill] }]
    };

    function currentPlan() {
      return {
        plan_id: '00000000-0000-4000-8000-000000000301',
        component_code: 'P1',
        active_week_no: 1,
        items: [{
          priority_order: 1,
          item_type: window.__planType,
          skill_code: 'P1-CIR-01',
          correction_case_id: '00000000-0000-4000-8000-000000000401',
          status: 'pending',
          due_at: null
        }]
      };
    }

    function currentQueue() {
      const step = window.__queueStep;
      return {
        component_code: 'P1',
        active_count: 1,
        cases: [{
          correction_case_id: '00000000-0000-4000-8000-000000000401',
          skill_code: 'P1-CIR-01',
          official_syllabus_section: '1.4 Circular measure',
          description: 'Переводить degrees ↔ radians и использовать radians как естественную угловую меру.',
          status: step === 'delayed_retest' ? 'retest_due' : (step === 'practice_analogues' ? 'remediating' : 'open'),
          process_step: step,
          can_start_correction: step === 'review_error' || step === 'practice_analogues',
          can_start_retest: step === 'delayed_retest'
        }],
        recent_resolved: []
      };
    }

    window.iClubExamPrepHostInternal = {
      lastCapabilities: { coreAccess: true, killSwitch: false, rolloutState: 'controlled_beta' },
      learnerCopy: {
        skillRu(code) {
          return code === 'P1-CIR-01' ? 'Переводить градусы в радианы и обратно и использовать радианную меру угла.' : '';
        }
      },
      api: {
        async syllabusTracker(component) { return { ok: true, data: { ...tracker, component_code: component } }; },
        async weeklyPlan(component) { return { ok: true, data: { ...currentPlan(), component_code: component } }; },
        async correctionQueue(component) { return { ok: true, data: { ...currentQueue(), component_code: component } }; }
      },
      overviewPlacementViews: {
        async openPlacement(component) {
          document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-placement-shell" data-ep-placement-screen>
            <div class="ep-placement-top"><div><div class="ep-placement-sub">${component} · Cambridge AS Mathematics</div><div class="ep-placement-title">Результат входной проверки</div></div><button class="ep-placement-btn" data-ep-placement-back>Вернуться к обзору</button></div>
            <div class="ep-placement-card"><strong>Проверка продолжается</strong></div>
            <div class="ep-placement-actions"><button class="ep-placement-btn primary" data-ep-placement-next>Продолжить входную проверку</button></div>
          </section>`;
          return true;
        }
      }
    };

    window.__renderDashboard = () => {
      const root = document.querySelector('#exam-prep-host-root');
      root.innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-grid"><article class="ep-live-card" data-ep-live-component="P1">
        <div class="ep-live-actions"><button class="ep-live-btn" data-ep-live-plan="P1">Открыть недельный план</button></div>
      </article></div></section>`;
      root.querySelector('[data-ep-live-plan="P1"]').addEventListener('click', () => window.__renderPlan());
    };

    window.__renderPlan = () => {
      const root = document.querySelector('#exam-prep-host-root');
      root.innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-card">
        <div class="ep-live-head"><div><strong>P1 · Недельный план</strong><div class="ep-live-meta">Неделя 1</div></div><button class="ep-live-btn secondary" data-ep-live-dashboard>Обзор</button></div>
        <div class="ep-live-plan-item"><div><strong>Разобрать ошибку</strong></div><button class="ep-live-btn" data-ep-live-plan-item="1">Начать</button></div>
      </div></section>`;
      root.querySelector('[data-ep-live-plan-item="1"]').addEventListener('click', () => { window.__startedPriority = 1; });
      root.querySelector('[data-ep-live-dashboard]').addEventListener('click', () => window.__renderDashboard());
    };

    window.iClubExamPrep = {
      async open() { window.__renderDashboard(); return true; },
      isOpen() { return true; }
    };
  });

  await page.addStyleTag({ path: path.resolve('exam-prep/exam-prep-wave1-ux.css') });
  await page.addStyleTag({ path: path.resolve('exam-prep/exam-prep-learner-flow-ux.css') });
  await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-learner-flow-ux.js') });
  await page.waitForFunction(() => window.iClubExamPrepHostInternal?.learnerFlowUx?.version === 'flowux4');

  const assert = (condition, message) => { if (!condition) throw new Error(message); };

  await page.evaluate(() => {
    document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-views-shell" data-ep-views-screen>
      <div class="ep-views-top"><div><div class="ep-views-sub">P1 · Cambridge AS Mathematics</div><div class="ep-views-title">Прогресс по программе</div></div><button class="ep-views-btn" data-ep-views-back="dashboard">Обзор</button></div>
      <div class="ep-views-card"><button class="ep-views-skill" data-ep-views-skill="P1-CIR-01"><span><strong>Навык 21</strong><span class="ep-views-skill-meta"> · Проверок: 2</span></span><span class="ep-views-badge">Формируется</span></button></div>
    </section>`;
  });
  await page.waitForFunction(() => document.querySelector('[data-ep-views-skill] strong')?.textContent.includes('градусы'));
  let state = await page.evaluate(() => ({
    title: document.querySelector('[data-ep-views-skill] strong')?.textContent,
    meta: document.querySelector('[data-ep-views-skill] .ep-views-skill-meta')?.textContent,
    back: document.querySelector('[data-ep-views-back]')?.textContent
  }));
  assert(state.title.includes('градусы') && state.title.includes('радианы'), 'tracker must display learner-facing Russian skill meaning as the primary label');
  assert(!state.title.includes('degrees') && !state.title.includes('radians'), 'tracker must not expose mixed canonical wording');
  assert(state.meta.includes('Навык 21'), 'skill number may remain only as secondary metadata');
  assert(state.back === 'К подготовке', 'dashboard navigation must be named by destination, not generic Overview');

  await page.evaluate(() => window.__renderPlan());
  await page.waitForFunction(() => document.querySelector('.ep-flow-task-name')?.textContent.includes('радианы'));
  state = await page.evaluate(() => ({
    type: document.querySelector('.ep-flow-task-type')?.textContent,
    name: document.querySelector('.ep-flow-task-name')?.textContent,
    action: document.querySelector('[data-ep-live-plan-item]')?.textContent,
    intro: document.querySelector('.ep-flow-plan-intro')?.textContent,
    back: document.querySelector('[data-ep-live-dashboard]')?.textContent
  }));
  assert(state.type === 'Разобрать ошибку', 'open correction must have a clear task type');
  assert(state.name.includes('радианы'), 'weekly plan must show which skill/error the learner is working on');
  assert(!state.name.includes('degrees') && !state.name.includes('radians'), 'weekly plan must not expose mixed canonical wording');
  assert(state.action === 'Начать разбор', 'weekly-plan CTA must describe the actual action');
  assert(state.intro.includes('трёх'), 'weekly plan must explain its priority role');
  assert(state.back === 'К подготовке', 'weekly-plan root navigation must say where it goes');

  await page.evaluate(() => {
    window.__queueStep = 'review_error';
    document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-views-shell" data-ep-views-screen>
      <div class="ep-views-top"><div><div class="ep-views-sub">P1 · Cambridge AS Mathematics</div><div class="ep-views-title">Работа над ошибками</div></div><button class="ep-views-btn" data-ep-views-back="dashboard">Обзор</button></div>
      <div class="ep-views-summary"><div>1</div></div>
      <div class="ep-views-card"><div class="ep-views-area-head"><strong>Радианная мера и окружность</strong><span class="ep-views-badge">Разобрать ошибку</span></div><div class="ep-views-sub">Переводить degrees ↔ radians и использовать radians как естественную угловую меру.</div></div>
      <div class="ep-views-actions"><button class="ep-views-btn primary" data-ep-views-open-plan="P1">Открыть недельный план</button></div>
    </section>`;
  });
  await page.waitForFunction(() => document.querySelector('[data-ep-flow-correction-action]'));
  state = await page.evaluate(() => ({
    badgeTag: document.querySelector('.ep-flow-status-badge')?.tagName,
    badge: document.querySelector('.ep-flow-status-badge')?.textContent,
    action: document.querySelector('[data-ep-flow-correction-action]')?.textContent,
    title: document.querySelector('.ep-flow-correction-title')?.textContent
  }));
  assert(state.badgeTag === 'SPAN' && state.badge === 'Требует разбора', 'correction state must read as status, not a dead action');
  assert(state.action === 'Начать разбор', 'planned correction must expose a real button');
  assert(state.title.includes('радианы'), 'correction card must explain the exact skill/error');
  assert(!state.title.includes('degrees') && !state.title.includes('radians'), 'correction card must not reintroduce mixed canonical wording');
  await page.click('[data-ep-flow-correction-action]');
  await page.waitForFunction(() => window.__startedPriority === 1);
  assert(await page.evaluate(() => window.__startedPriority) === 1, 'correction CTA must route to and start the matching governed weekly-plan item');

  await page.evaluate(() => {
    document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-live"><button data-ep-live-submit>Отправить ответ</button></section>`;
  });
  await page.click('[data-ep-live-submit]');
  await page.evaluate(() => {
    document.querySelector('#exam-prep-host-root').innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-card" role="status" aria-live="polite">Загрузка…</div></section>`;
  });
  await page.waitForSelector('.ep-flow-spinner');
  state = await page.evaluate(() => ({
    text: document.querySelector('.ep-flow-loader strong')?.textContent,
    hint: document.querySelector('.ep-flow-loader small')?.textContent
  }));
  assert(state.text === 'Сохраняем ответ…', 'answer loading must describe the active operation');
  assert(state.hint.includes('Прогресс сохраняется'), 'loading must reassure without implying completion');

  await page.evaluate(() => {
    const session = {
      session_id: '00000000-0000-4000-8000-000000000501', component_code: 'P1', session_type: 'diagnostic',
      items: [{ answered: true }, { answered: true }, { answered: true }]
    };
    window.dispatchEvent(new CustomEvent('iclub:exam-prep-session', { detail: { session, language: 'ru' } }));
    window.dispatchEvent(new CustomEvent('iclub:exam-prep-session-ended', { detail: { sessionId: session.session_id } }));
    window.__renderDashboard();
  });
  await page.waitForSelector('.ep-flow-diagnostic-complete', { timeout: 8000 });
  state = await page.evaluate(() => ({
    banner: document.querySelector('.ep-flow-diagnostic-complete')?.textContent,
    result: document.querySelector('.ep-placement-title')?.textContent,
    next: document.querySelector('[data-ep-placement-next]')?.textContent
  }));
  assert(state.banner.includes('3 / 3'), 'diagnostic completion must confirm the saved chunk');
  assert(state.result === 'Результат входной проверки', 'diagnostic completion must stay in a result context');
  assert(state.next === 'Продолжить входную проверку', 'diagnostic result must expose the server-derived next action');

  await page.evaluate(() => {
    window.__queueStep = 'review_error';
    window.__renderPlan();
  });
  await page.waitForFunction(() => document.querySelector('[data-ep-live-plan-item]')?.textContent === 'Начать разбор');
  await page.click('[data-ep-live-plan-item]');
  await page.evaluate(() => {
    window.__queueStep = 'practice_analogues';
    const session = {
      session_id: '00000000-0000-4000-8000-000000000601', component_code: 'P1', session_type: 'learning',
      items: [{ answered: true }, { answered: true }, { answered: true }, { answered: true }]
    };
    window.dispatchEvent(new CustomEvent('iclub:exam-prep-session', { detail: { session, language: 'ru' } }));
    window.dispatchEvent(new CustomEvent('iclub:exam-prep-session-ended', { detail: { sessionId: session.session_id } }));
    window.__renderPlan();
  });
  await page.waitForSelector('.ep-flow-completion-screen', { timeout: 8000 });
  state = await page.evaluate(() => ({
    title: document.querySelector('.ep-flow-completion-screen .ep-host-title')?.textContent,
    body: document.querySelector('.ep-flow-completion-card')?.textContent,
    next: document.querySelector('.ep-flow-next-card')?.textContent,
    action: document.querySelector('[data-ep-flow-next-plan]')?.textContent,
    back: document.querySelector('.ep-flow-completion-screen [data-ep-live-dashboard]')?.textContent
  }));
  assert(state.title === 'Разбор ошибки сохранён', 'correction completion needs a clear result state');
  assert(state.body.includes('Следующий шаг — закрепить этот навык'), 'completion must explain the correction cycle instead of silently claiming closure');
  assert(state.next.includes('Закрепить после разбора') && state.next.includes('радианы'), 'completion must name the next task and skill');
  assert(!state.next.includes('degrees') && !state.next.includes('radians'), 'completion must keep learner-facing copy');
  assert(state.action === 'Открыть следующий шаг', 'completion must offer the next action');
  assert(state.back === 'К подготовке', 'completion must keep a clear secondary route back to preparation');

  await browser.close();
  console.log('Exam Prep learner-flow clarity regression: PASS');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
