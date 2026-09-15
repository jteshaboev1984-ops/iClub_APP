(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "flowux3";
  const trackerCache = new Map();
  let observer = null;
  let reconcileTimer = null;
  let operation = null;
  let lastSession = null;
  let activeSkillCode = null;
  let pendingPlanContext = null;
  let completionToken = 0;

  const AREA_LABELS = Object.freeze({
    "1.1 Quadratics": { ru: "Квадратные выражения и уравнения", uz: "Kvadrat ifodalar va tenglamalar", en: "Quadratics" },
    "1.2 Functions": { ru: "Функции", uz: "Funksiyalar", en: "Functions" },
    "1.3 Coordinate geometry": { ru: "Координатная геометрия", uz: "Koordinata geometriyasi", en: "Coordinate geometry" },
    "1.4 Circular measure": { ru: "Радианная мера и окружность", uz: "Radian o‘lchov va aylana", en: "Circular measure" },
    "1.5 Trigonometry": { ru: "Тригонометрия", uz: "Trigonometriya", en: "Trigonometry" },
    "1.6 Series": { ru: "Последовательности и ряды", uz: "Ketma-ketliklar va qatorlar", en: "Series" },
    "1.7 Differentiation": { ru: "Дифференцирование", uz: "Differensiallash", en: "Differentiation" },
    "1.8 Integration": { ru: "Интегрирование", uz: "Integrallash", en: "Integration" },
    "5.1 Representation of data": { ru: "Представление данных", uz: "Ma’lumotlarni tasvirlash", en: "Representation of data" },
    "5.2 Permutations and combinations": { ru: "Перестановки и сочетания", uz: "O‘rin almashtirish va kombinatsiyalar", en: "Permutations and combinations" },
    "5.3 Probability": { ru: "Вероятность", uz: "Ehtimollik", en: "Probability" },
    "5.4 Discrete random variables": { ru: "Дискретные случайные величины", uz: "Diskret tasodifiy miqdorlar", en: "Discrete random variables" },
    "5.5 The normal distribution": { ru: "Нормальное распределение", uz: "Normal taqsimot", en: "The normal distribution" }
  });

  function rootEl() {
    return document.querySelector("#exam-prep-host-root");
  }

  function language() {
    try {
      const value = String(window.i18n?.getLang?.() || document.documentElement.lang || "").toLowerCase();
      if (value.startsWith("uz")) return "uz";
      if (value.startsWith("en")) return "en";
      if (value.startsWith("ru")) return "ru";
    } catch (_) {}
    const text = String(rootEl()?.textContent || "");
    if (/Umumiy ko‘rinish|Haftalik|Imtihon tayyorgarligi|Dastur bo‘yicha/i.test(text)) return "uz";
    if (/\bOverview\b|weekly plan|exam preparation|entry check|syllabus progress/i.test(text)) return "en";
    return "ru";
  }

  function copy() {
    const l = language();
    if (l === "uz") return {
      backPreparation: "Tayyorgarlikka",
      backPreparationLong: "Tayyorgarlikka qaytish",
      loadingHint: "Natijangiz saqlanadi. Sahifani yopmang.",
      loadingDefault: "Ma’lumotlar yangilanmoqda…",
      loadingAnswer: "Javob saqlanmoqda…",
      loadingCheck: "Tekshiruvning keyingi qismi tayyorlanmoqda…",
      loadingTask: "Topshiriq tayyorlanmoqda…",
      loadingPlan: "Haftalik reja yangilanmoqda…",
      loadingProgress: "Dastur bo‘yicha progress yuklanmoqda…",
      loadingCorrections: "Xatolar bo‘yicha holat yuklanmoqda…",
      loadingPlacement: "Kirish tekshiruvi natijasi yangilanmoqda…",
      loadingMaterials: "Materiallar yuklanmoqda…",
      loadingProfile: "Imtihon rejasi saqlanmoqda…",
      loadingTimed: "Vaqtli mashq tayyorlanmoqda…",
      loadingReadiness: "Imtihon tayyorgarligi yangilanmoqda…",
      loadingResult: "Natija saqlanmoqda…",
      loadingRecovery: "Qaytish rejasi yangilanmoqda…",
      diagnosticDone: "Tekshiruv qismi yakunlandi",
      answersSaved: "Javoblar saqlandi",
      resultBelow: "Quyida joriy natija va keyingi qadam ko‘rsatilgan.",
      result: "Natija",
      taskDone: "Topshiriq yakunlandi",
      correctionDone: "Xato ustidagi ish saqlandi",
      retestDone: "Qayta tekshiruv yakunlandi",
      mixedDone: "Aralash mashq yakunlandi",
      evidenceSaved: "Natija o‘quv tarixiga saqlandi.",
      correctionStillOpen: "Bu xato hali yopilmagan. U faqat kechiktirilgan qayta tekshiruv yangi natijani tasdiqlagandan keyin yopiladi.",
      correctionPractice: "Tahlil saqlandi. Keyingi qadam — o‘xshash masalalarda mustahkamlash.",
      correctionWait: "Asosiy ish bajarildi. Keyingi qayta tekshiruv belgilangan vaqtda ochiladi.",
      correctionResolved: "Qayta tekshiruv xatoni yopdi.",
      nextStep: "Keyingi qadam",
      noNext: "Bu hafta uchun majburiy keyingi topshiriq yo‘q.",
      openNext: "Keyingi qadamni ochish",
      openPlan: "Haftalik rejaga o‘tish",
      skill: "Ko‘nikma",
      checks: "Tekshiruvlar",
      whatToFix: "Nimani to‘g‘rilash kerak",
      startCorrection: "Tahlilni boshlash",
      startPractice: "Mustahkamlashni boshlash",
      startRetest: "Qayta tekshirish",
      startLearning: "Mavzuni boshlash",
      startMixed: "Mashqni boshlash",
      reviewError: "Xatoni tahlil qilish",
      practiceAfterReview: "Tahlildan keyin mustahkamlash",
      waitRetest: "Qayta tekshiruvni kutish",
      delayedRetest: "Qayta tekshirish",
      learning: "Mavzuni o‘rganish",
      mixed: "Aralash mashq",
      planIntro: "Reja eng muhim uchta vazifani ko‘rsatadi. Birinchi vazifadan boshlang.",
      priority: "Ustuvor",
      due: "Qayta tekshiruv",
      statusNeedsReview: "Tahlil kerak",
      statusNeedsPractice: "Mustahkamlash kerak",
      statusWaitRetest: "Qayta tekshiruv keyinroq",
      statusRetestReady: "Qayta tekshiruvga tayyor"
    };
    if (l === "en") return {
      backPreparation: "Preparation",
      backPreparationLong: "Back to preparation",
      loadingHint: "Your progress is being preserved. Keep this screen open.",
      loadingDefault: "Updating your information…",
      loadingAnswer: "Saving your answer…",
      loadingCheck: "Preparing the next check section…",
      loadingTask: "Preparing the task…",
      loadingPlan: "Updating your weekly plan…",
      loadingProgress: "Loading syllabus progress…",
      loadingCorrections: "Loading correction status…",
      loadingPlacement: "Updating the entry-check result…",
      loadingMaterials: "Loading materials…",
      loadingProfile: "Saving your exam plan…",
      loadingTimed: "Preparing timed practice…",
      loadingReadiness: "Updating exam readiness…",
      loadingResult: "Saving your result…",
      loadingRecovery: "Updating your return plan…",
      diagnosticDone: "Check section complete",
      answersSaved: "Answers saved",
      resultBelow: "Your current result and next step are shown below.",
      result: "Result",
      taskDone: "Task complete",
      correctionDone: "Correction work saved",
      retestDone: "Delayed check complete",
      mixedDone: "Mixed practice complete",
      evidenceSaved: "The result has been added to your learning history.",
      correctionStillOpen: "This correction is still open. It closes only after a later check confirms the new result.",
      correctionPractice: "Your review is saved. The next step is to secure it on similar questions.",
      correctionWait: "The main correction work is complete. The delayed check will open when it is due.",
      correctionResolved: "The delayed check closed this correction.",
      nextStep: "Next step",
      noNext: "There is no required next task for this week.",
      openNext: "Open next step",
      openPlan: "Go to weekly plan",
      skill: "Skill",
      checks: "Checks",
      whatToFix: "What to fix",
      startCorrection: "Start review",
      startPractice: "Start consolidation",
      startRetest: "Start delayed check",
      startLearning: "Start topic",
      startMixed: "Start practice",
      reviewError: "Review the mistake",
      practiceAfterReview: "Consolidate after review",
      waitRetest: "Waiting for delayed check",
      delayedRetest: "Delayed check",
      learning: "Study the topic",
      mixed: "Mixed practice",
      planIntro: "The plan shows up to three highest-priority tasks. Start with the first task.",
      priority: "Priority",
      due: "Delayed check",
      statusNeedsReview: "Needs review",
      statusNeedsPractice: "Needs consolidation",
      statusWaitRetest: "Delayed check later",
      statusRetestReady: "Ready for delayed check"
    };
    return {
      backPreparation: "К подготовке",
      backPreparationLong: "Вернуться к подготовке",
      loadingHint: "Прогресс сохраняется. Не закрывайте экран.",
      loadingDefault: "Обновляем данные…",
      loadingAnswer: "Сохраняем ответ…",
      loadingCheck: "Готовим следующую часть проверки…",
      loadingTask: "Готовим задание…",
      loadingPlan: "Обновляем недельный план…",
      loadingProgress: "Загружаем прогресс по программе…",
      loadingCorrections: "Загружаем работу над ошибками…",
      loadingPlacement: "Обновляем результат входной проверки…",
      loadingMaterials: "Загружаем материалы…",
      loadingProfile: "Сохраняем план экзамена…",
      loadingTimed: "Готовим практику на время…",
      loadingReadiness: "Обновляем готовность к экзамену…",
      loadingResult: "Сохраняем результат…",
      loadingRecovery: "Обновляем план после перерыва…",
      diagnosticDone: "Часть входной проверки завершена",
      answersSaved: "Ответы сохранены",
      resultBelow: "Ниже показаны текущий результат и следующий шаг.",
      result: "Результат",
      taskDone: "Задание завершено",
      correctionDone: "Разбор ошибки сохранён",
      retestDone: "Повторная проверка завершена",
      mixedDone: "Смешанная практика завершена",
      evidenceSaved: "Результат добавлен в вашу учебную историю.",
      correctionStillOpen: "Эта ошибка пока не закрыта. Она закроется только после отложенной повторной проверки, если новый результат подтвердит исправление.",
      correctionPractice: "Разбор сохранён. Следующий шаг — закрепить этот навык на похожих задачах.",
      correctionWait: "Основная работа выполнена. Повторная проверка откроется в назначенное время.",
      correctionResolved: "Повторная проверка подтвердила исправление. Ошибка закрыта.",
      nextStep: "Следующий шаг",
      noNext: "На этой неделе обязательных следующих заданий больше нет.",
      openNext: "Открыть следующий шаг",
      openPlan: "Перейти к недельному плану",
      skill: "Навык",
      checks: "Проверок",
      whatToFix: "Что нужно исправить",
      startCorrection: "Начать разбор",
      startPractice: "Начать закрепление",
      startRetest: "Пройти повторную проверку",
      startLearning: "Начать тему",
      startMixed: "Начать практику",
      reviewError: "Разобрать ошибку",
      practiceAfterReview: "Закрепить после разбора",
      waitRetest: "Ожидает повторной проверки",
      delayedRetest: "Повторная проверка",
      learning: "Изучить тему",
      mixed: "Смешанная практика",
      planIntro: "План показывает до трёх самых важных заданий. Начните с первого.",
      priority: "Приоритет",
      due: "Повторная проверка",
      statusNeedsReview: "Требует разбора",
      statusNeedsPractice: "Нужно закрепить",
      statusWaitRetest: "Повторная проверка позже",
      statusRetestReady: "Готово к повторной проверке"
    };
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function areaLabel(source) {
    const raw = String(source || "");
    return AREA_LABELS[raw]?.[language()] || raw.replace(/^\d+\.\d+\s+/, "");
  }

  function componentFromScreen() {
    const root = rootEl();
    if (!root) return pendingPlanContext?.component || null;
    const candidates = [
      root.querySelector(".ep-placement-sub"),
      root.querySelector(".ep-views-sub"),
      root.querySelector(".ep-materials-sub"),
      root.querySelector(".ep-live-head strong")
    ];
    for (const node of candidates) {
      const match = String(node?.textContent || "").match(/\b(P1|P5)\b/);
      if (match) return match[1];
    }
    return pendingPlanContext?.component || null;
  }

  function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async function waitFor(selector, attempts = 80, delay = 30) {
    for (let i = 0; i < attempts; i += 1) {
      const node = rootEl()?.querySelector(selector) || document.querySelector(selector);
      if (node) return node;
      await sleep(delay);
    }
    return null;
  }

  async function dashboard() {
    const app = window.iClubExamPrep;
    if (!app || typeof app.open !== "function") return false;
    return Boolean(await app.open({ subjectKey: "mathematics", language: language() }));
  }

  function trackerMap(data) {
    const map = new Map();
    (Array.isArray(data?.areas) ? data.areas : []).forEach(area => {
      (Array.isArray(area?.skills) ? area.skills : []).forEach(skill => {
        if (!skill?.skill_code) return;
        map.set(String(skill.skill_code), Object.assign({}, skill, { official_syllabus_section: area.official_syllabus_section }));
      });
    });
    return map;
  }

  async function getTracker(component, force = false) {
    if (!component || typeof internal.api?.syllabusTracker !== "function") return null;
    const cached = trackerCache.get(component);
    if (!force && cached && Date.now() - cached.at < 30000) return cached.data;
    const result = await internal.api.syllabusTracker(component);
    if (!result?.ok) return null;
    trackerCache.set(component, { at: Date.now(), data: result.data || {} });
    return result.data || {};
  }

  function humanSkill(meta) {
    const c = copy();
    if (!meta) return "";
    if (language() === "ru" && meta.description) return String(meta.description);
    return `${c.skill} ${Number(meta.sequence_no || 0)}`;
  }

  function correctionStateLabel(row) {
    const c = copy();
    if (!row) return c.reviewError;
    if (row.process_step === "practice_analogues") return c.practiceAfterReview;
    if (row.process_step === "wait_delayed_retest" || row.process_step === "retest_content_wait") return c.waitRetest;
    if (row.process_step === "delayed_retest") return c.delayedRetest;
    return c.reviewError;
  }

  function correctionStatusLabel(row) {
    const c = copy();
    if (!row) return c.statusNeedsReview;
    if (row.process_step === "practice_analogues") return c.statusNeedsPractice;
    if (row.process_step === "wait_delayed_retest" || row.process_step === "retest_content_wait") return c.statusWaitRetest;
    if (row.process_step === "delayed_retest") return c.statusRetestReady;
    return c.statusNeedsReview;
  }

  function planTypeLabel(item, correctionRow = null) {
    const c = copy();
    if (item?.item_type === "correction") return correctionStateLabel(correctionRow);
    if (item?.item_type === "retest") return c.delayedRetest;
    if (item?.item_type === "mixed_transfer") return c.mixed;
    return c.learning;
  }

  function planButtonLabel(item, correctionRow = null) {
    const c = copy();
    if (item?.item_type === "correction") {
      return correctionRow?.process_step === "practice_analogues" ? c.startPractice : c.startCorrection;
    }
    if (item?.item_type === "retest") return c.startRetest;
    if (item?.item_type === "mixed_transfer") return c.startMixed;
    return c.startLearning;
  }

  function describePlanItem(item, skillMap, correctionRows = []) {
    if (!item) return "";
    const correction = correctionRows.find(row => String(row?.correction_case_id || "") === String(item.correction_case_id || "") || (item.skill_code && row?.skill_code === item.skill_code));
    const meta = skillMap.get(String(item.skill_code || ""));
    const type = planTypeLabel(item, correction);
    const name = humanSkill(meta);
    return [type, name].filter(Boolean).join(" · ");
  }

  function operationMessage(node) {
    const c = copy();
    if (node?.closest?.("[data-ep-placement-screen]")) return c.loadingPlacement;
    if (node?.closest?.("[data-ep-materials-screen]")) return c.loadingMaterials;
    const views = node?.closest?.("[data-ep-views-screen]");
    if (views) {
      const title = String(views.querySelector(".ep-views-title")?.textContent || "").toLowerCase();
      if (/ошиб|correction|xato/.test(title)) return c.loadingCorrections;
      if (/прогресс|progress|dastur/.test(title)) return c.loadingProgress;
      return c.loadingDefault;
    }
    return ({
      answer: c.loadingAnswer,
      diagnostic: c.loadingCheck,
      task: c.loadingTask,
      plan: c.loadingPlan,
      progress: c.loadingProgress,
      corrections: c.loadingCorrections,
      placement: c.loadingPlacement,
      materials: c.loadingMaterials,
      profile: c.loadingProfile,
      timed: c.loadingTimed,
      readiness: c.loadingReadiness,
      result: c.loadingResult,
      recovery: c.loadingRecovery
    })[operation] || c.loadingDefault;
  }

  function decorateLoading() {
    const root = rootEl();
    if (!root) return;
    const loadingWords = new Set(["Загрузка…", "Загрузка...", "Loading…", "Loading...", "Yuklanmoqda…", "Yuklanmoqda..."]);
    root.querySelectorAll('[role="status"]').forEach(node => {
      if (node.querySelector(".ep-flow-loader")) return;
      if (!loadingWords.has(String(node.textContent || "").trim())) return;
      const c = copy();
      node.innerHTML = `<div class="ep-flow-loader"><span class="ep-flow-spinner" aria-hidden="true"></span><div><strong>${esc(operationMessage(node))}</strong><small>${esc(c.loadingHint)}</small></div></div>`;
      node.classList.add("ep-flow-loading-surface");
    });
  }

  function renameNavigation() {
    const root = rootEl();
    if (!root) return;
    const c = copy();
    const selectors = [
      "[data-ep-live-dashboard]",
      "[data-ep-live-home]",
      "[data-ep-placement-back]",
      "[data-ep-materials-back]",
      "[data-ep-recovery-back]",
      '[data-ep-views-back="dashboard"]'
    ];
    selectors.forEach(selector => root.querySelectorAll(selector).forEach(button => {
      button.textContent = button.matches("[data-ep-live-home]") ? c.backPreparationLong : c.backPreparation;
      button.setAttribute("aria-label", c.backPreparationLong);
    }));
  }

  async function decorateTracker() {
    const root = rootEl();
    const buttons = root?.querySelectorAll("[data-ep-views-skill]");
    if (!root || !buttons?.length) return;
    const component = componentFromScreen();
    if (!component) return;
    const data = await getTracker(component);
    if (!data || !root.isConnected || !root.querySelector("[data-ep-views-skill]")) return;
    const map = trackerMap(data);
    const c = copy();
    buttons.forEach(button => {
      const meta = map.get(String(button.dataset.epViewsSkill || ""));
      if (!meta || button.dataset.epFlowTracker === VERSION) return;
      const strong = button.querySelector("strong");
      const metaNode = button.querySelector(".ep-views-skill-meta");
      if (strong) strong.textContent = humanSkill(meta);
      if (metaNode) metaNode.textContent = ` · ${c.skill} ${Number(meta.sequence_no || 0)} · ${c.checks}: ${Number(meta.evidence_total || 0)}`;
      button.dataset.epFlowTracker = VERSION;
    });
  }

  async function decoratePlan(force = false) {
    const root = rootEl();
    const rows = Array.from(root?.querySelectorAll(".ep-live-plan-item") || []);
    if (!rows.length || root?.querySelector(".ep-flow-completion-screen")) return;
    const component = componentFromScreen();
    if (!component || typeof internal.api?.weeklyPlan !== "function") return;
    if (!force && rows.every(row => row.dataset.epFlowPlan === VERSION)) return;

    const [planResult, trackerData] = await Promise.all([internal.api.weeklyPlan(component), getTracker(component)]);
    if (!planResult?.ok || !trackerData || !rootEl()?.querySelector(".ep-live-plan-item")) return;
    const plan = planResult.data || {};
    const items = Array.isArray(plan.items) ? plan.items : [];
    const skillMap = trackerMap(trackerData);
    let correctionRows = [];
    if (items.some(item => ["correction", "retest"].includes(item?.item_type)) && typeof internal.api?.correctionQueue === "function") {
      const correctionResult = await internal.api.correctionQueue(component);
      if (correctionResult?.ok) correctionRows = Array.isArray(correctionResult.data?.cases) ? correctionResult.data.cases : [];
    }
    const c = copy();
    const currentRows = Array.from(rootEl()?.querySelectorAll(".ep-live-plan-item") || []);
    currentRows.forEach(row => {
      const button = row.querySelector("[data-ep-live-plan-item]");
      const priority = Number(button?.dataset.epLivePlanItem || 0);
      const item = items.find(x => Number(x?.priority_order || 0) === priority);
      if (!item) return;
      const correction = correctionRows.find(x => String(x?.correction_case_id || "") === String(item.correction_case_id || "") || (item.skill_code && x?.skill_code === item.skill_code));
      const meta = skillMap.get(String(item.skill_code || ""));
      const copyBlock = row.firstElementChild;
      if (copyBlock) {
        const typeNode = copyBlock.querySelector("strong");
        if (typeNode) {
          typeNode.textContent = planTypeLabel(item, correction);
          typeNode.classList.add("ep-flow-task-type");
        }
        let title = copyBlock.querySelector(".ep-flow-task-name");
        if (!title) {
          title = document.createElement("div");
          title.className = "ep-flow-task-name";
          const due = copyBlock.querySelector(".ep-live-due");
          copyBlock.insertBefore(title, due || null);
        }
        title.textContent = humanSkill(meta) || areaLabel(meta?.official_syllabus_section) || c.skill;
        let secondary = copyBlock.querySelector(".ep-flow-task-meta");
        if (!secondary) {
          secondary = document.createElement("div");
          secondary.className = "ep-flow-task-meta";
          const due = copyBlock.querySelector(".ep-live-due");
          copyBlock.insertBefore(secondary, due || null);
        }
        secondary.textContent = [areaLabel(meta?.official_syllabus_section), meta?.sequence_no ? `${c.skill} ${Number(meta.sequence_no)}` : ""].filter(Boolean).join(" · ");
      }
      if (button && !button.disabled) button.textContent = planButtonLabel(item, correction);
      row.dataset.epFlowPlan = VERSION;
      row.dataset.epFlowPriority = String(priority);
      row.dataset.epFlowSkill = String(item.skill_code || "");
      row.dataset.epFlowType = String(item.item_type || "");
      row.dataset.epFlowCorrection = String(item.correction_case_id || "");
    });

    const card = rootEl()?.querySelector(".ep-live-card");
    if (card && !card.querySelector(".ep-flow-plan-intro")) {
      const head = card.querySelector(".ep-live-head");
      const note = document.createElement("div");
      note.className = "ep-flow-plan-intro";
      note.textContent = c.planIntro;
      if (head?.nextSibling) card.insertBefore(note, head.nextSibling); else card.appendChild(note);
    }
  }

  async function decorateCorrections() {
    const root = rootEl();
    const screen = root?.querySelector("[data-ep-views-screen]");
    const title = String(screen?.querySelector(".ep-views-title")?.textContent || "").toLowerCase();
    if (!screen || !/ошиб|correction|xato/.test(title) || typeof internal.api?.correctionQueue !== "function") return;
    if (screen.dataset.epFlowCorrections === VERSION) return;
    const component = componentFromScreen();
    if (!component) return;
    const [queueResult, planResult, trackerData] = await Promise.all([
      internal.api.correctionQueue(component),
      typeof internal.api?.weeklyPlan === "function" ? internal.api.weeklyPlan(component) : Promise.resolve(null),
      getTracker(component)
    ]);
    if (!queueResult?.ok || !rootEl()?.querySelector("[data-ep-views-screen]")) return;
    const cases = Array.isArray(queueResult.data?.cases) ? queueResult.data.cases : [];
    const planItems = Array.isArray(planResult?.data?.items) ? planResult.data.items : [];
    const skillMap = trackerMap(trackerData || {});
    const cards = Array.from(rootEl().querySelectorAll(".ep-views-summary ~ .ep-views-card")).slice(0, cases.length);
    const c = copy();
    cards.forEach((card, index) => {
      const row = cases[index];
      if (!row) return;
      const meta = skillMap.get(String(row.skill_code || ""));
      const description = language() === "ru" ? String(row.description || meta?.description || "") : "";
      const sub = card.querySelector(".ep-views-sub");
      if (sub && description) {
        sub.innerHTML = `<span class="ep-flow-correction-label">${esc(c.whatToFix)}</span><strong class="ep-flow-correction-title">${esc(description)}</strong>`;
      } else if (!sub) {
        const areaHead = card.querySelector(".ep-views-area-head");
        const block = document.createElement("div");
        block.className = "ep-views-sub";
        block.innerHTML = `<span class="ep-flow-correction-label">${esc(c.whatToFix)}</span><strong class="ep-flow-correction-title">${esc(humanSkill(meta) || areaLabel(row.official_syllabus_section))}</strong>`;
        areaHead?.insertAdjacentElement("afterend", block);
      }
      const badge = card.querySelector(".ep-views-badge");
      if (badge) {
        badge.textContent = correctionStatusLabel(row);
        badge.classList.add("ep-flow-status-badge");
      }
      const planned = planItems.find(item => item?.status === "pending" && (String(item.correction_case_id || "") === String(row.correction_case_id || "") || (item.skill_code && item.skill_code === row.skill_code)));
      if (planned && !card.querySelector("[data-ep-flow-correction-action]")) {
        const action = document.createElement("button");
        action.type = "button";
        action.className = "ep-views-btn primary ep-flow-correction-action";
        action.dataset.epFlowCorrectionAction = String(row.correction_case_id || "");
        action.textContent = planned.item_type === "retest" ? c.startRetest : (row.process_step === "practice_analogues" ? c.startPractice : c.startCorrection);
        action.addEventListener("click", () => openPlanAndStart(component, planned.skill_code, planned.item_type, planned.correction_case_id));
        card.appendChild(action);
      }
      card.dataset.epFlowCorrectionCard = VERSION;
    });
    const bottom = rootEl().querySelector("[data-ep-views-open-plan]");
    if (bottom) bottom.textContent = c.openPlan;
    screen.dataset.epFlowCorrections = VERSION;
  }

  function capturePlanContext(button) {
    const row = button?.closest?.(".ep-live-plan-item");
    if (!row) return;
    pendingPlanContext = {
      component: componentFromScreen(),
      priorityOrder: Number(row.dataset.epFlowPriority || button.dataset.epLivePlanItem || 0),
      skillCode: String(row.dataset.epFlowSkill || ""),
      itemType: String(row.dataset.epFlowType || ""),
      correctionCaseId: String(row.dataset.epFlowCorrection || "") || null,
      skillTitle: String(row.querySelector(".ep-flow-task-name")?.textContent || ""),
      area: String(row.querySelector(".ep-flow-task-meta")?.textContent || "")
    };
  }

  async function openWeeklyPlan(component, focus = null) {
    operation = "plan";
    const ok = await dashboard();
    if (!ok) return false;
    const button = await waitFor(`[data-ep-live-plan="${component}"]`);
    if (!button) return false;
    button.click();
    const row = await waitFor(".ep-live-plan-item");
    if (!row) return false;
    await decoratePlan(true);
    if (focus?.skillCode) {
      const target = Array.from(rootEl()?.querySelectorAll(".ep-live-plan-item") || []).find(item => {
        const skillOk = String(item.dataset.epFlowSkill || "") === String(focus.skillCode || "");
        const typeOk = !focus.itemType || String(item.dataset.epFlowType || "") === String(focus.itemType);
        const correctionOk = !focus.correctionCaseId || String(item.dataset.epFlowCorrection || "") === String(focus.correctionCaseId);
        return skillOk && typeOk && correctionOk;
      });
      if (target) {
        target.classList.add("ep-flow-focus");
        try { target.scrollIntoView({ behavior: "smooth", block: "center" }); } catch (_) {}
        setTimeout(() => target.classList.remove("ep-flow-focus"), 2400);
      }
    }
    return true;
  }

  async function openPlanAndStart(component, skillCode, itemType, correctionCaseId = null) {
    const opened = await openWeeklyPlan(component, { skillCode, itemType, correctionCaseId });
    if (!opened) return;
    const target = Array.from(rootEl()?.querySelectorAll(".ep-live-plan-item") || []).find(item => {
      const skillOk = String(item.dataset.epFlowSkill || "") === String(skillCode || "");
      const typeOk = !itemType || String(item.dataset.epFlowType || "") === String(itemType);
      const correctionOk = !correctionCaseId || String(item.dataset.epFlowCorrection || "") === String(correctionCaseId);
      return skillOk && typeOk && correctionOk;
    });
    const button = target?.querySelector("[data-ep-live-plan-item]");
    if (button && !button.disabled) button.click();
  }

  async function routeCorrectionAction(component) {
    if (!component) return;
    if (typeof internal.api?.weeklyPlan === "function") {
      const plan = await internal.api.weeklyPlan(component);
      const item = (Array.isArray(plan?.data?.items) ? plan.data.items : []).find(row => row?.status === "pending" && row?.item_type === "correction");
      if (item) {
        await openPlanAndStart(component, item.skill_code, item.item_type, item.correction_case_id);
        return;
      }
    }
    if (typeof internal.learnerViews?.openCorrections === "function") internal.learnerViews.openCorrections(component);
  }

  function onCaptureClick(event) {
    const root = rootEl();
    const button = event.target?.closest?.("button");
    if (!root || !button || !root.contains(button)) return;

    if (button.matches("[data-ep-live-submit]")) operation = "answer";
    else if (button.matches("[data-ep-live-start]")) operation = "diagnostic";
    else if (button.matches("[data-ep-live-plan-item]")) { operation = "task"; capturePlanContext(button); }
    else if (button.matches("[data-ep-live-plan], [data-ep-views-open-plan]")) operation = "plan";
    else if (button.matches("[data-ep-views-tracker], [data-ep-views-skill]")) operation = "progress";
    else if (button.matches("[data-ep-views-corrections]")) operation = "corrections";
    else if (button.matches("[data-ep-placement-open]")) operation = "placement";
    else if (button.matches("[data-ep-materials-open]")) operation = "materials";
    else if (button.matches("[data-ep-live-save-profile], [data-ep-exam-plan-save], [data-ep-profile-completion-save]")) operation = "profile";
    else if (button.matches("[data-ep-live-timed], [data-ep-live-timed-start], [data-ep-live-end], [data-ep-live-back-timed]")) operation = "timed";
    else if (button.matches("[data-ep-live-readiness], [data-ep-live-calibration]")) operation = "readiness";
    else if (button.matches("[data-ep-live-save-self]")) operation = "result";
    else if (button.matches("[data-ep-recovery-open], [data-ep-recovery-submit], [data-ep-recovery-check]")) operation = "recovery";
    else operation = null;

    if (button.matches("[data-ep-views-skill]")) activeSkillCode = String(button.dataset.epViewsSkill || "");

    const label = String(button.textContent || "").trim();
    const correctionLabels = new Set(["Разобрать ошибку", "Work on a correction", "Xato ustida ishlash"]);
    if (correctionLabels.has(label) && button.matches("[data-ep-placement-next]")) {
      const component = componentFromScreen();
      event.preventDefault();
      event.stopImmediatePropagation();
      routeCorrectionAction(component);
    }
  }

  function completionTitle(context, correctionRow, resolved) {
    const c = copy();
    if (resolved) return c.retestDone;
    if (context?.itemType === "correction") return c.correctionDone;
    if (context?.itemType === "retest") return c.retestDone;
    if (context?.itemType === "mixed_transfer") return c.mixedDone;
    return c.taskDone;
  }

  function completionMessage(context, correctionRow, resolved) {
    const c = copy();
    if (resolved) return c.correctionResolved;
    if (context?.itemType === "correction") {
      if (correctionRow?.process_step === "practice_analogues") return c.correctionPractice;
      if (["wait_delayed_retest", "retest_content_wait", "delayed_retest"].includes(correctionRow?.process_step)) return c.correctionWait;
      return c.correctionStillOpen;
    }
    if (context?.itemType === "retest") return correctionRow ? c.correctionStillOpen : c.evidenceSaved;
    return c.evidenceSaved;
  }

  async function showTaskCompletion(session, context, token) {
    const component = context?.component || session?.component_code;
    if (!component || token !== completionToken) return;
    await sleep(120);
    await waitFor(".ep-live-plan-item, .ep-live-error", 120, 50);
    if (token !== completionToken) return;
    const api = internal.api;
    if (!api) return;
    const [planResult, trackerData, queueResult] = await Promise.all([
      typeof api.weeklyPlan === "function" ? api.weeklyPlan(component) : Promise.resolve(null),
      getTracker(component, true),
      ["correction", "retest"].includes(context?.itemType) && typeof api.correctionQueue === "function" ? api.correctionQueue(component) : Promise.resolve(null)
    ]);
    if (token !== completionToken) return;

    const planItems = Array.isArray(planResult?.data?.items) ? planResult.data.items : [];
    const skillMap = trackerMap(trackerData || {});
    const cases = Array.isArray(queueResult?.data?.cases) ? queueResult.data.cases : [];
    const resolvedRows = Array.isArray(queueResult?.data?.recent_resolved) ? queueResult.data.recent_resolved : [];
    const correctionRow = cases.find(row => String(row?.correction_case_id || "") === String(context?.correctionCaseId || "") || (context?.skillCode && row?.skill_code === context.skillCode));
    const resolved = resolvedRows.find(row => String(row?.correction_case_id || "") === String(context?.correctionCaseId || "") || (context?.skillCode && row?.skill_code === context.skillCode));
    const next = planItems.find(item => item?.status === "pending");
    const nextCorrectionRows = cases;
    const nextText = next ? describePlanItem(next, skillMap, nextCorrectionRows) : "";
    const meta = skillMap.get(String(context?.skillCode || ""));
    const skillTitle = context?.skillTitle || humanSkill(meta);
    const answered = Array.isArray(session?.items) ? session.items.filter(item => item?.answered === true).length : 0;
    const total = Array.isArray(session?.items) ? session.items.length : Number(session?.total_items || 0);
    const c = copy();
    const root = rootEl();
    if (!root) return;

    root.innerHTML = `<section class="ep-host-shell ep-live ep-flow-completion-screen" data-ep-flow-completion="${esc(VERSION)}">
      <div class="ep-live-head"><div><div class="ep-host-kicker">${esc(c.result)}</div><h2 class="ep-host-title">${esc(completionTitle(context, correctionRow, Boolean(resolved)))}</h2></div></div>
      <div class="ep-flow-completion-card">
        ${skillTitle ? `<div class="ep-flow-completion-skill"><span>${esc(c.skill)}</span><strong>${esc(skillTitle)}</strong></div>` : ""}
        <p>${esc(completionMessage(context, correctionRow, Boolean(resolved)))}</p>
        ${total ? `<div class="ep-flow-completion-metric"><span>${esc(c.answersSaved)}</span><strong>${answered} / ${total}</strong></div>` : ""}
      </div>
      <div class="ep-flow-next-card"><span>${esc(c.nextStep)}</span><strong>${esc(nextText || c.noNext)}</strong></div>
      <div class="ep-live-actions">
        ${next ? `<button class="ep-live-btn" type="button" data-ep-flow-next-plan>${esc(c.openNext)}</button>` : ""}
        <button class="ep-live-btn secondary" type="button" data-ep-live-dashboard>${esc(c.backPreparation)}</button>
      </div>
    </section>`;
    root.querySelector("[data-ep-flow-next-plan]")?.addEventListener("click", () => openWeeklyPlan(component, {
      skillCode: next?.skill_code || null,
      itemType: next?.item_type || null,
      correctionCaseId: next?.correction_case_id || null
    }));
    root.querySelector("[data-ep-live-dashboard]")?.addEventListener("click", dashboard);
    pendingPlanContext = null;
    operation = null;
  }

  async function showPostDiagnostic(session, token) {
    const component = session?.component_code;
    if (!component || token !== completionToken) return;
    operation = "placement";
    await sleep(120);
    await waitFor(".ep-live-grid, .ep-live-error", 120, 50);
    if (token !== completionToken) return;
    if (typeof internal.overviewPlacementViews?.openPlacement === "function") {
      await internal.overviewPlacementViews.openPlacement(component);
    } else {
      await dashboard();
      return;
    }
    const screen = await waitFor("[data-ep-placement-screen]");
    if (!screen || token !== completionToken) return;
    const top = screen.querySelector(".ep-placement-top");
    if (!top || screen.querySelector(".ep-flow-diagnostic-complete")) return;
    const c = copy();
    const answered = Array.isArray(session?.items) ? session.items.filter(item => item?.answered === true).length : 0;
    const total = Array.isArray(session?.items) ? session.items.length : Number(session?.total_items || 0);
    const banner = document.createElement("div");
    banner.className = "ep-flow-diagnostic-complete";
    banner.innerHTML = `<div><strong>${esc(c.diagnosticDone)}</strong><span>${esc(c.resultBelow)}</span></div>${total ? `<div class="ep-flow-completion-metric"><span>${esc(c.answersSaved)}</span><strong>${answered} / ${total}</strong></div>` : ""}`;
    top.insertAdjacentElement("afterend", banner);
    operation = null;
    renameNavigation();
  }

  function onSession(event) {
    const session = event?.detail?.session;
    if (session?.session_id) lastSession = session;
  }

  function onSessionEnded(event) {
    const sessionId = String(event?.detail?.sessionId || "");
    const session = lastSession && String(lastSession.session_id || "") === sessionId ? lastSession : null;
    if (!session) return;
    const token = ++completionToken;
    if (session.session_type === "diagnostic") {
      setTimeout(() => showPostDiagnostic(session, token), 40);
      return;
    }
    if (["timed", "paper"].includes(String(session.session_type || ""))) return;
    if (pendingPlanContext?.component === session.component_code) {
      setTimeout(() => showTaskCompletion(session, Object.assign({}, pendingPlanContext), token), 40);
    }
  }

  function reconcile() {
    decorateLoading();
    renameNavigation();
    decorateTracker();
    decoratePlan();
    decorateCorrections();
  }

  function scheduleReconcile() {
    if (reconcileTimer) return;
    reconcileTimer = setTimeout(() => {
      reconcileTimer = null;
      reconcile();
    }, 25);
  }

  function attach() {
    const root = rootEl();
    if (!root) {
      setTimeout(attach, 50);
      return;
    }
    if (observer) return;
    document.addEventListener("click", onCaptureClick, true);
    window.addEventListener("iclub:exam-prep-session", onSession);
    window.addEventListener("iclub:exam-prep-session-ended", onSessionEnded);
    observer = new MutationObserver(scheduleReconcile);
    observer.observe(root, { childList: true, subtree: true, characterData: true });
    scheduleReconcile();
    internal.learnerFlowUx = Object.freeze({ version: VERSION, openWeeklyPlan, openPlanAndStart });
  }

  attach();
})();
