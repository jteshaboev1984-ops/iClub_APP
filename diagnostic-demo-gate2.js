(function () {
  'use strict';

  const PREFIX = 'iclub_demo_v12.';
  const STATE_KEY = PREFIX + 'state';
  const CHAT_KEY = PREFIX + 'chat';
  const TECH_KEY = PREFIX + 'technical';
  const HISTORY_KEY = PREFIX + 'history';
  const VALID_PLANS = new Set(['free', 'plus', 'pro']);
  const VALID_SCENARIOS = new Set(['learning', 'active-tour']);
  const CUSTOM_IDS = new Set([
    'subject-hub-screen',
    'plan-comparison-screen',
    'plus-chat-screen',
    'pro-trajectory-screen',
    'active-tour-preview-screen',
    'show-tools-screen',
    'demo-technical-screen'
  ]);

  const L = window.ICLUB_DEMO_GATE2_COPY;
  Object.assign(L.en, {
    currentDiagnosisSub: '7 multiple-choice questions · 2 easy · 3 medium · 2 hard',
    proFeatures: ['Everything in Plus', 'Question-level learning path', 'Skill states and supporting results', 'Unverified errors and targeted next step'],
    sendLater: 'Sending is not active in this interface preview.',
    chatHello: 'Ask about a topic, formula or concept. The tutor interface is ready; sending answers is not active in this preview.',
    toolsNote: 'Answer autofill and result controls are being prepared. The menu and scenario state are already isolated and persistent.'
  });
  Object.assign(L.ru, {
    currentDiagnosisSub: '7 вопросов с выбором ответа · 2 лёгких · 3 средних · 2 сложных',
    proAttention: 'Pro связывает результаты по вопросам закрытого тура, последующей практики и новой диагностики.',
    proFeatures: ['Всё из Plus', 'Траектория на уровне вопросов', 'Статусы навыков и подтверждающие результаты', 'Непроверенные ошибки и точный следующий шаг'],
    trajectorySub: 'Одна история, интерпретированная с учётом подтверждающих результатов.',
    trajectoryAction: 'Завершить диагностику и обновить результаты проверки',
    chatHello: 'Задайте вопрос по теме, формуле или понятию. Интерфейс репетитора подготовлен; отправка ответов в этом предварительном экране пока недоступна.',
    sendLater: 'Отправка пока недоступна в этом предварительном экране.',
    toolsNote: 'Автозаполнение ответов и управление результатами проверки готовятся. Меню и состояние сценария уже изолированы и сохраняются.'
  });
  Object.assign(L.uz, {
    currentDiagnosisSub: '7 ta variantli savol · 2 oson · 3 o‘rtacha · 2 qiyin',
    proAttention: 'Pro yopilgan tur, keyingi mashq va yangi diagnostika natijalarini bog‘laydi.',
    proFeatures: ['Plus dagi barcha imkoniyatlar', 'Savol darajasidagi o‘quv yo‘li', 'Ko‘nikma holatlari va tasdiqlovchi natijalar', 'Tekshirilmagan xatolar va aniq keyingi qadam'],
    trajectorySub: 'Bitta tarix tasdiqlovchi natijalar bilan talqin qilinadi.',
    trajectoryAction: 'Diagnostikani tugatib tekshiruv natijalarini yangilash',
    chatHello: 'Mavzu, formula yoki tushuncha haqida savol bering. Repetitor interfeysi tayyor; bu oldindan ko‘rish ekranida javob yuborish hozircha o‘chiq.',
    sendLater: 'Bu oldindan ko‘rish ekranida yuborish hozircha o‘chiq.',
    toolsNote: 'Javoblarni avtomatik to‘ldirish va tekshiruv natijalarini boshqarish tayyorlanmoqda. Menyu va ssenariy holati allaqachon izolyatsiya qilingan va saqlanadi.'
  });

  const $ = (id) => document.getElementById(id);
  const currentLang = () => L[document.documentElement.lang] ? document.documentElement.lang : 'ru';
  const t = () => L[currentLang()];
  const readJson = (store, key, fallback) => {
    try { return JSON.parse(store.getItem(key)) || fallback; } catch { return fallback; }
  };
  const writeJson = (store, key, value) => {
    try { store.setItem(key, JSON.stringify(value)); } catch {}
  };

  const initialState = window.ICLUB_DEMO_GATE2_BOOT_STATE || readJson(localStorage, STATE_KEY, {});
  let plan = VALID_PLANS.has(initialState.plan) ? initialState.plan : 'free';
  let scenario = VALID_SCENARIOS.has(initialState.scenario) ? initialState.scenario : 'learning';
  let rememberedScreen = CUSTOM_IDS.has(initialState.screen) ? initialState.screen : 'subject-hub-screen';
  let scenarioOpen = false;
  let trajectoryOrigin = 'hub';
  if (rememberedScreen === 'plus-chat-screen' && plan === 'free') rememberedScreen = 'plan-comparison-screen';
  if (rememberedScreen === 'pro-trajectory-screen' && plan !== 'pro') rememberedScreen = 'subject-hub-screen';
  if (rememberedScreen === 'active-tour-preview-screen' && scenario !== 'active-tour') rememberedScreen = 'subject-hub-screen';

  function persist(extra = {}) {
    const prior = readJson(localStorage, STATE_KEY, {});
    writeJson(localStorage, STATE_KEY, {
      ...prior,
      lang: currentLang(),
      plan,
      scenario,
      screen: visibleScreenId() || rememberedScreen,
      ...extra
    });
  }

  function injectControls() {
    const topbar = document.querySelector('.demo-topbar');
    if (!topbar || $('demo-controls-shell')) return;
    topbar.insertAdjacentHTML('afterend', window.ICLUB_DEMO_GATE2_TEMPLATES.controls);
  }

  function injectScreens() {
    const main = document.querySelector('.demo-main');
    if (!main || $('subject-hub-screen')) return;
    main.insertAdjacentHTML('afterbegin', window.ICLUB_DEMO_GATE2_TEMPLATES.screens);
  }

  function visibleScreenId() {
    const node = [...document.querySelectorAll('.demo-screen')].find((screen) => !screen.classList.contains('hidden'));
    return node?.id || null;
  }

  function hideAllScreens() {
    document.querySelectorAll('.demo-screen').forEach((screen) => screen.classList.add('hidden'));
  }

  function showScreen(id) {
    const node = $(id);
    if (!node) return;
    hideAllScreens();
    node.classList.remove('hidden');
    rememberedScreen = id;
    renderNavigation();
    renderDynamic();
    persist({ screen: id });
    window.scrollTo({ top: 0, behavior: 'auto' });
  }

  function renderNavigation() {
    const id = visibleScreenId();
    const back = $('topbar-back');
    if (!back) return;
    const hidden = id === 'subject-hub-screen' || id === 'practice-quiz-screen';
    back.classList.toggle('hidden', hidden);
  }

  function setText(id, value) {
    const node = $(id);
    if (node && node.textContent !== value) node.textContent = value;
  }

  function renderControls() {
    const x = t();
    setText('demo-mode-copy', x.mode);
    setText('demo-scenario-btn', x.scenario);
    setText('scenario-learning-label', x.learning);
    setText('scenario-tour-label', x.activeTour);
    setText('scenario-tools-label', x.tools);
    setText('scenario-reset-label', x.reset);
    setText('scenario-technical-label', x.technical);
    document.querySelectorAll('.demo-plan-btn').forEach((button) => button.classList.toggle('is-active', button.dataset.demoPlan === plan));
    document.querySelectorAll('.demo-scenario-item').forEach((button) => button.classList.toggle('is-active', button.dataset.scenarioAction === scenario));
    document.body.dataset.demoPlan = plan;
    document.body.dataset.demoScenario = scenario;
    $('demo-scenario-menu')?.classList.toggle('hidden', !scenarioOpen);
    $('demo-scenario-btn')?.setAttribute('aria-expanded', String(scenarioOpen));
  }

  function latestDiagnostic() {
    const history = readJson(localStorage, HISTORY_KEY, { diagnostics: [] });
    return Array.isArray(history.diagnostics) && history.diagnostics.length ? history.diagnostics[history.diagnostics.length - 1] : null;
  }

  function renderHub() {
    const x = t();
    setText('hub-title', x.economics);
    setText('hub-subtitle', x.subtitle);
    setText('hub-plan-badge', `${plan[0].toUpperCase() + plan.slice(1)} · ${x.plan}`);
    setText('demo-profile-name', x.learner);
    setText('demo-profile-status', x.demoStudent);
    setText('demo-profile-progress-label', x.completed);
    const ai = plan === 'free'
      ? [x.aiFreeTitle, x.aiFreeSub, x.aiFreeAction]
      : plan === 'plus'
        ? [x.aiPlusTitle, x.aiPlusSub, x.aiPlusAction]
        : [x.aiProTitle, x.aiProSub, x.aiProAction];
    setText('hub-ai-title', ai[0]); setText('hub-ai-sub', ai[1]); setText('hub-ai-action', ai[2]);
    $('hub-ai-mark')?.classList.toggle('is-available', plan !== 'free');
    setText('hub-diagnostic-title', x.currentDiagnosis); setText('hub-diagnostic-sub', x.currentDiagnosisSub); setText('hub-open-diagnostic', x.openDiagnosis);
    setText('hub-tour-label', x.closedTour); setText('hub-tour-meta', `${x.score} · ${x.closed}`); setText('hub-practice-label', x.afterPractice); setText('hub-practice-meta', `${x.score} · ${x.afterTour}`);
    setText('hub-attention-title', x.attention);
    setText('hub-attention-copy', plan === 'free' ? x.freeAttention : plan === 'plus' ? x.plusAttention : x.proAttention);
    setText('hub-history-title', x.history); setText('hub-history-sub', x.viewHistory);
    setText('hub-history-row-1', x.practice1); setText('hub-history-row-2', x.tour4); setText('hub-history-row-3', x.practice4);
    const tabs = $('hub-history-tabs');
    if (tabs) {
      tabs.innerHTML = '';
      const specs = [
        [x.attempts, true],
        [x.dialogues, plan !== 'free'],
        [x.progress, plan === 'pro']
      ];
      specs.forEach(([label, available]) => {
        const chip = document.createElement('span');
        chip.className = 'hub-history-tab' + (available ? '' : ' is-locked');
        chip.textContent = available ? label : `${label} · ${x.locked}`;
        tabs.appendChild(chip);
      });
    }
  }

  function renderComparison() {
    const x = t();
    setText('compare-title', x.compareTitle); setText('compare-subtitle', x.compareSub); setText('pro-recommended', x.recommended); setText('choose-plus', x.choosePlus); setText('choose-pro', x.choosePro); setText('compare-back', x.backHub);
    const fill = (id, items) => {
      const list = $(id); if (!list) return; list.innerHTML = '';
      items.forEach((item) => { const li = document.createElement('li'); li.textContent = item; list.appendChild(li); });
    };
    fill('plus-feature-list', x.plusFeatures); fill('pro-feature-list', x.proFeatures);
  }

  function renderChat() {
    const x = t();
    setText('chat-title', x.chatTitle); setText('chat-subtitle', x.chatSub); setText('chat-welcome', x.chatHello); setText('chat-pro-layer', x.proLayer); setText('demo-chat-send', x.sendLater); setText('chat-save-note', x.saveDraft); setText('chat-back', x.backHub);
    const draft = $('demo-chat-draft');
    const stored = readJson(localStorage, CHAT_KEY, { draft: '' });
    if (draft && draft !== document.activeElement) draft.value = stored.draft || '';
    if (draft) draft.placeholder = x.draft;
  }

  function renderTrajectory() {
    const x = t();
    setText('trajectory-title', x.trajectoryTitle); setText('trajectory-subtitle', x.trajectorySub); setText('trajectory-tour4', x.tour4); setText('trajectory-practice4', x.practice4); setText('trajectory-current', x.current); setText('trajectory-notice', x.trajectoryNotice); setText('trajectory-action', x.trajectoryAction); setText('trajectory-back', x.backHub);
    const latest = latestDiagnostic();
    const percent = latest && latest.total ? Math.round((latest.score / latest.total) * 100) : 0;
    const fill = $('trajectory-current-fill'); if (fill) fill.style.width = `${percent}%`;
    setText('trajectory-current-value', latest ? `${percent}%` : x.pending);
  }

  function renderActive() {
    const x = t();
    setText('active-title', x.activeTitle); setText('active-subtitle', x.activeSub); setText('active-warning', x.activeWarning); setText('active-theory-action', x.theoryOnly); setText('active-back', x.backLearning);
  }

  function renderTools() {
    const x = t();
    setText('tools-title', x.toolsTitle); setText('tools-subtitle', x.toolsSub); setText('tools-rehearsed', x.rehearsed); setText('tools-free-check', x.freeCheck); setText('tools-note', x.toolsNote); setText('tools-back', x.backHub);
  }

  function renderTechnical() {
    const x = t();
    setText('tech-title', x.techTitle); setText('tech-subtitle', x.techSub); setText('tech-back', x.backHub);
    const actual = window.iClubDemoV12?.getTechnicalState?.() || readJson(sessionStorage, TECH_KEY, {});
    const rows = [
      [x.dataSource, actual.data_source || 'static'],
      [x.productionCalls, String(actual.production_calls ?? 0)],
      [x.storage, actual.storage || 'local/session only'],
      [x.dataset, actual.dataset || '1.2'],
      [x.currentPlan, plan],
      [x.currentScenario, scenario],
      [x.browserGuard, x.blocked]
    ];
    const grid = $('technical-grid');
    if (grid) {
      grid.innerHTML = '';
      rows.forEach(([label, value]) => {
        const row = document.createElement('div'); row.className = 'technical-row';
        const a = document.createElement('span'); a.textContent = label;
        const b = document.createElement('b'); b.textContent = value;
        row.append(a, b); grid.appendChild(row);
      });
    }
  }

  function renderResultAction() {
    const button = $('result-primary-action');
    if (!button) return;
    button.textContent = plan === 'free' ? t().resultFree : plan === 'plus' ? t().resultPlus : t().resultPro;
  }

  function renderDynamic() {
    renderControls(); renderHub(); renderComparison(); renderChat(); renderTrajectory(); renderActive(); renderTools(); renderTechnical(); renderResultAction(); renderNavigation();
  }

  function setPlan(next) {
    if (!VALID_PLANS.has(next) || next === plan) return;
    const from = visibleScreenId();
    plan = next;
    if (from === 'plus-chat-screen' && plan === 'free') showScreen('plan-comparison-screen');
    else if (from === 'pro-trajectory-screen' && plan === 'free') showScreen('subject-hub-screen');
    else if (from === 'pro-trajectory-screen' && plan === 'plus') {
      showScreen(trajectoryOrigin === 'result' ? 'practice-result-screen' : 'subject-hub-screen');
    } else if (from === 'ai-result-screen' && plan === 'free') showScreen('practice-result-screen');
    else if (from === 'ai-result-screen' && plan === 'pro') showScreen('pro-trajectory-screen');
    else { renderDynamic(); persist(); }
  }

  function openHubAi() {
    if (plan === 'free') showScreen('plan-comparison-screen');
    else if (plan === 'plus') showScreen('plus-chat-screen');
    else { trajectoryOrigin = 'hub'; showScreen('pro-trajectory-screen'); }
  }

  function openPracticeStart() {
    scenario = 'learning';
    showScreen('practice-start-screen');
  }

  function handleScenario(action) {
    scenarioOpen = false;
    if (action === 'learning') { scenario = 'learning'; showScreen('subject-hub-screen'); }
    else if (action === 'active-tour') { scenario = 'active-tour'; showScreen('active-tour-preview-screen'); }
    else if (action === 'tools') showScreen('show-tools-screen');
    else if (action === 'technical') showScreen('demo-technical-screen');
    else if (action === 'reset') {
      const ok = window.confirm(currentLang() === 'ru' ? 'Сбросить только локальные данные demo?' : currentLang() === 'uz' ? 'Faqat lokal demo ma’lumotlarini tiklaysizmi?' : 'Reset only local demo data?');
      if (ok) window.iClubDemoV12?.reset?.();
    }
    renderControls(); persist();
  }

  function backFromCurrent(event) {
    const id = visibleScreenId();
    if (id === 'practice-quiz-screen') return;
    if (id === 'practice-start-screen') { event.preventDefault(); event.stopImmediatePropagation(); showScreen('subject-hub-screen'); return; }
    if (CUSTOM_IDS.has(id)) { event.preventDefault(); event.stopImmediatePropagation(); if (id === 'active-tour-preview-screen') { scenario = 'learning'; } showScreen('subject-hub-screen'); }
  }

  function wireEvents() {
    document.addEventListener('click', (event) => {
      const planButton = event.target.closest('[data-demo-plan]');
      if (planButton) { event.preventDefault(); setPlan(planButton.dataset.demoPlan); return; }
      if (event.target.closest('#demo-scenario-btn')) { event.preventDefault(); scenarioOpen = !scenarioOpen; renderControls(); return; }
      const scenarioButton = event.target.closest('[data-scenario-action]');
      if (scenarioButton) { event.preventDefault(); handleScenario(scenarioButton.dataset.scenarioAction); return; }
      if (!event.target.closest('#demo-controls-shell') && scenarioOpen) { scenarioOpen = false; renderControls(); }
      if (event.target.closest('#hub-ai-action')) { event.preventDefault(); openHubAi(); return; }
      if (event.target.closest('#hub-open-diagnostic')) { event.preventDefault(); openPracticeStart(); return; }
      const choose = event.target.closest('[data-choose-plan]');
      if (choose) { event.preventDefault(); setPlan(choose.dataset.choosePlan); showScreen(choose.dataset.choosePlan === 'plus' ? 'plus-chat-screen' : 'pro-trajectory-screen'); return; }
      if (event.target.closest('[data-go-hub]')) { event.preventDefault(); showScreen('subject-hub-screen'); return; }
      if (event.target.closest('#trajectory-action')) { event.preventDefault(); openPracticeStart(); return; }
      if (event.target.closest('#active-theory-action')) { event.preventDefault(); if (plan === 'free') showScreen('plan-comparison-screen'); else showScreen('plus-chat-screen'); return; }
      if (event.target.closest('#active-back')) { event.preventDefault(); scenario = 'learning'; showScreen('subject-hub-screen'); return; }
      if (event.target.closest('#tools-rehearsed')) { event.preventDefault(); scenario = 'learning'; if (plan === 'free') setPlan('pro'); showScreen('subject-hub-screen'); return; }
      if (event.target.closest('#tools-free-check')) { event.preventDefault(); scenario = 'learning'; setPlan('free'); showScreen('subject-hub-screen'); return; }
    });

    document.addEventListener('click', (event) => {
      const resultAction = event.target.closest('#result-primary-action');
      if (!resultAction) return;
      if (plan === 'free') { event.preventDefault(); event.stopImmediatePropagation(); showScreen('plan-comparison-screen'); }
      else if (plan === 'pro') { event.preventDefault(); event.stopImmediatePropagation(); trajectoryOrigin = 'result'; showScreen('pro-trajectory-screen'); }
    }, true);

    $('topbar-back')?.addEventListener('click', backFromCurrent, true);

    $('demo-chat-draft')?.addEventListener('input', (event) => {
      const prior = readJson(localStorage, CHAT_KEY, {});
      writeJson(localStorage, CHAT_KEY, { ...prior, draft: event.target.value });
    });

    document.querySelectorAll('.language-btn').forEach((button) => {
      button.addEventListener('click', () => {
        const screenBeforeLanguageChange = visibleScreenId();
        setTimeout(() => {
          if (CUSTOM_IDS.has(screenBeforeLanguageChange)) showScreen(screenBeforeLanguageChange);
          else { renderDynamic(); persist(); }
        }, 0);
      });
    });
  }

  function observeLegacyScreens() {
    let timer = null;
    const observer = new MutationObserver((records) => {
      if (!records.some((record) => record.type === 'attributes' && record.attributeName === 'class')) return;
      window.clearTimeout(timer);
      timer = window.setTimeout(() => {
        const id = visibleScreenId();
        if (id) rememberedScreen = id;
        renderNavigation(); renderResultAction(); persist();
      }, 25);
    });
    document.querySelectorAll('.demo-screen').forEach((screen) => observer.observe(screen, { attributes: true, attributeFilter: ['class'] }));
  }

  injectControls();
  injectScreens();
  wireEvents();
  observeLegacyScreens();
  renderDynamic();
  showScreen(rememberedScreen);
})();
