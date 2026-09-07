(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p020views1";
  let observer = null;
  let busy = false;
  let activeLanguage = "ru";

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

  function text() {
    if (activeLanguage === "uz") return {
      tracker: "Dastur bo‘yicha progress", corrections: "Xatolar ustida ishlash", overview: "Umumiy ko‘rinish",
      trackerIntro: "Har bir qism bo‘yicha tasdiqlangan progress alohida ko‘rsatiladi.",
      covered: "Tasdiqlangan", skills: "ko‘nikma", skill: "Ko‘nikma", checks: "Tekshiruvlar",
      noEvidence: "Hali tasdiqlanmagan", developing: "Rivojlanmoqda", confirmed: "Tasdiqlangan", secure: "Barqaror",
      needsWork: "Tuzatish kerak", detail: "Ko‘nikma tafsilotlari", backTracker: "Progressga qaytish",
      history: "Tekshiruv tarixi", prerequisites: "Tayanch bilimlar", resources: "Manbalar", correctionHistory: "Tuzatish tarixi",
      noneYet: "Hozircha ma’lumot yo‘q.", prerequisite: "Tayanch bilim", unknown: "Tekshirilmagan", blocker: "Mustahkamlash kerak", ready: "Yetarli",
      writtenNote: "Yozma yechimlar alohida saqlanadi. Inson tekshiruvi bo‘lmasa ham asosiy o‘quv yo‘li to‘xtamaydi.",
      openCorrections: "Xatolarni ochish", queueIntro: "Xato → mashq → kechiktirilgan qayta tekshiruv. Faqat yangi tekshiruvdan keyin yopiladi.",
      noCorrections: "Hozir tuzatish talab qiladigan xato yo‘q.", reviewError: "Xatoni tahlil qilish", analogues: "O‘xshash masalalarda mashq", waitRetest: "Qayta tekshiruv vaqtini kutish", delayedRetest: "Qayta tekshirish",
      due: "Qayta tekshiruv", openPlan: "Haftalik rejani ochish", recentResolved: "Yaqinda yopilgan", loading: "Yuklanmoqda…", error: "Ma’lumotni yuklab bo‘lmadi. Qayta urinib ko‘ring.",
      attempt: "Urinish", correct: "To‘g‘ri", incorrect: "Xato", recorded: "Yozib olingan", book: "Kitob", pages: "Sahifalar"
    };
    if (activeLanguage === "en") return {
      tracker: "Syllabus progress", corrections: "Corrections", overview: "Overview",
      trackerIntro: "Confirmed progress is shown separately for each component and syllabus area.",
      covered: "Confirmed", skills: "skills", skill: "Skill", checks: "Checks",
      noEvidence: "Not yet confirmed", developing: "Developing", confirmed: "Confirmed", secure: "Secure",
      needsWork: "Needs correction", detail: "Skill detail", backTracker: "Back to progress",
      history: "Check history", prerequisites: "Foundation prerequisites", resources: "Resources", correctionHistory: "Correction history",
      noneYet: "No records yet.", prerequisite: "Prerequisite", unknown: "Not checked", blocker: "Needs work", ready: "Secure",
      writtenNote: "Written solutions are stored separately. The Core learning route continues even when no human review is available.",
      openCorrections: "Open corrections", queueIntro: "Mistake → practice → delayed check. A correction closes only after fresh delayed evidence.",
      noCorrections: "There are no corrections to work on right now.", reviewError: "Review the mistake", analogues: "Practise similar questions", waitRetest: "Wait for the delayed check", delayedRetest: "Check again",
      due: "Check date", openPlan: "Open weekly plan", recentResolved: "Recently completed", loading: "Loading…", error: "Could not load this view. Try again.",
      attempt: "Attempt", correct: "Correct", incorrect: "Incorrect", recorded: "Recorded", book: "Book", pages: "Pages"
    };
    return {
      tracker: "Прогресс по программе", corrections: "Работа над ошибками", overview: "Обзор",
      trackerIntro: "Подтверждённый прогресс показан отдельно по каждому компоненту и разделу программы.",
      covered: "Подтверждено", skills: "навыков", skill: "Навык", checks: "Проверок",
      noEvidence: "Пока не подтверждено", developing: "Формируется", confirmed: "Подтверждено", secure: "Уверенно",
      needsWork: "Нужно исправить", detail: "Детали навыка", backTracker: "Вернуться к прогрессу",
      history: "История проверок", prerequisites: "Базовые знания", resources: "Материалы", correctionHistory: "История исправления",
      noneYet: "Пока данных нет.", prerequisite: "Базовое знание", unknown: "Не проверено", blocker: "Нужно укрепить", ready: "Достаточно",
      writtenNote: "Письменные решения сохраняются отдельно. Отсутствие человеческой проверки не блокирует основной учебный маршрут.",
      openCorrections: "Открыть работу над ошибками", queueIntro: "Ошибка → практика → отложенная повторная проверка. Исправление закрывается только после нового подтверждения.",
      noCorrections: "Сейчас нет ошибок, требующих исправления.", reviewError: "Разобрать ошибку", analogues: "Практика на похожих задачах", waitRetest: "Дождаться повторной проверки", delayedRetest: "Проверить ещё раз",
      due: "Повторная проверка", openPlan: "Открыть недельный план", recentResolved: "Недавно закрыто", loading: "Загрузка…", error: "Не удалось загрузить данные. Попробуйте ещё раз.",
      attempt: "Попытка", correct: "Верно", incorrect: "Ошибка", recorded: "Сохранено", book: "Книга", pages: "Страницы"
    };
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;").replaceAll("'", "&#039;");
  }

  function rootEl() { return document.querySelector("#exam-prep-host-root"); }

  function detectLanguage() {
    const value = String(rootEl()?.textContent || "");
    if (/Umumiy ko‘rinish|Haftalik reja|Imtihon tayyorgarligi/.test(value)) return "uz";
    if (/\bOverview\b|Weekly plan|Exam readiness/.test(value)) return "en";
    return "ru";
  }

  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }

  function areaLabel(source) {
    return AREA_LABELS[String(source || "")]?.[activeLanguage] || String(source || "").replace(/^\d+\.\d+\s+/, "");
  }

  function statusLabel(level, correctionId) {
    const c = text();
    if (correctionId) return c.needsWork;
    const n = Number(level || 0);
    if (n >= 3) return c.secure;
    if (n >= 2) return c.confirmed;
    if (n >= 1) return c.developing;
    return c.noEvidence;
  }

  function ensureStyle() {
    if (document.querySelector("#ep-learner-views-style")) return;
    const style = document.createElement("style");
    style.id = "ep-learner-views-style";
    style.textContent = `
      .ep-views-actions{display:flex;gap:8px;flex-wrap:wrap;margin-top:2px}.ep-views-btn{border:1px solid rgba(127,127,127,.28);border-radius:10px;padding:8px 10px;background:transparent;color:inherit;font:inherit;font-weight:700;cursor:pointer}.ep-views-btn.primary{background:#111827;color:#fff;border-color:#111827}.ep-views-btn:disabled{opacity:.55;cursor:default}
      .ep-views-shell{display:grid;gap:12px}.ep-views-top{display:flex;justify-content:space-between;gap:10px;align-items:flex-start}.ep-views-title{font-size:20px;font-weight:800}.ep-views-sub{font-size:12px;opacity:.72;margin-top:3px}.ep-views-card{display:grid;gap:10px;border:1px solid rgba(127,127,127,.22);border-radius:14px;padding:13px;background:rgba(127,127,127,.035)}
      .ep-views-summary{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px}.ep-views-stat{display:grid;gap:3px;border:1px solid rgba(127,127,127,.16);border-radius:10px;padding:9px}.ep-views-stat span{font-size:11px;opacity:.72}.ep-views-stat strong{font-size:17px}.ep-views-area{display:grid;gap:8px}.ep-views-area-head{display:flex;justify-content:space-between;gap:8px;align-items:center}.ep-views-progress{height:6px;border-radius:999px;background:rgba(127,127,127,.16);overflow:hidden}.ep-views-progress>span{display:block;height:100%;background:currentColor;opacity:.7}
      .ep-views-skill{width:100%;display:grid;grid-template-columns:1fr auto;gap:8px;align-items:center;text-align:left;border:0;border-top:1px solid rgba(127,127,127,.14);padding:9px 0 0;background:transparent;color:inherit;font:inherit;cursor:pointer}.ep-views-skill-meta{font-size:11px;opacity:.7}.ep-views-badge{font-size:11px;font-weight:700;border:1px solid rgba(127,127,127,.22);border-radius:999px;padding:4px 7px;white-space:nowrap}
      .ep-views-list{display:grid;gap:7px}.ep-views-row{display:grid;grid-template-columns:1fr auto;gap:8px;align-items:start;padding:9px;border-radius:10px;background:rgba(127,127,127,.06)}.ep-views-row small{opacity:.7}.ep-views-note{padding:10px;border-radius:10px;background:rgba(127,127,127,.08);font-size:12px;line-height:1.45}.ep-views-error{padding:10px;border-radius:10px;background:rgba(180,30,30,.12);font-size:13px}
      @media(max-width:680px){.ep-views-top{display:grid}.ep-views-summary{grid-template-columns:1fr}.ep-views-skill,.ep-views-row{grid-template-columns:1fr}.ep-views-actions .ep-views-btn{flex:1 1 auto}}
    `;
    document.head.appendChild(style);
  }

  function shell(component, title, subtitle, body, backHandler = "dashboard") {
    const c = text();
    return `<section class="ep-host-shell ep-views-shell" data-ep-views-screen><div class="ep-views-top"><div><div class="ep-views-sub">${esc(component)} · Cambridge AS Mathematics</div><div class="ep-views-title">${esc(title)}</div>${subtitle ? `<div class="ep-views-sub">${esc(subtitle)}</div>` : ""}</div><button class="ep-views-btn" type="button" data-ep-views-back="${esc(backHandler)}">${esc(c.overview)}</button></div>${body}</section>`;
  }

  function renderLoading(component, title) {
    const root = rootEl(); if (!root) return;
    root.innerHTML = shell(component, title, "", `<div class="ep-views-card">${esc(text().loading)}</div>`);
    bindBack(root, component);
  }

  function renderError(component, title) {
    const root = rootEl(); if (!root) return;
    root.innerHTML = shell(component, title, "", `<div class="ep-views-error">${esc(text().error)}</div>`);
    bindBack(root, component);
  }

  async function dashboard() {
    const app = window.iClubExamPrep;
    if (!app || typeof app.open !== "function") return false;
    await app.open({ subjectKey: "mathematics", language: activeLanguage });
    return true;
  }

  async function waitFor(selector, attempts = 30) {
    for (let i = 0; i < attempts; i += 1) {
      const node = document.querySelector(selector);
      if (node) return node;
      await new Promise(resolve => setTimeout(resolve, 25));
    }
    return null;
  }

  function bindBack(root, component, backHandler = "dashboard") {
    root.querySelector("[data-ep-views-back]")?.addEventListener("click", async () => {
      if (backHandler === "tracker") await openTracker(component);
      else await dashboard();
    });
  }

  async function openTracker(component) {
    if (busy || !canUse() || typeof internal.api?.syllabusTracker !== "function") return;
    busy = true; activeLanguage = detectLanguage(); ensureStyle(); renderLoading(component, text().tracker);
    const result = await internal.api.syllabusTracker(component); busy = false;
    if (!result?.ok) { renderError(component, text().tracker); return; }
    renderTracker(component, result.data || {});
  }

  function renderTracker(component, data) {
    const root = rootEl(); if (!root) return; const c = text();
    const areas = Array.isArray(data?.areas) ? data.areas : [];
    const denominator = Number(data?.denominator_count || 0), coverage = Number(data?.coverage_count || 0), pct = Number(data?.coverage_pct || 0);
    const cards = areas.map(area => {
      const skills = Array.isArray(area?.skills) ? area.skills : [];
      const total = Number(area?.skill_count || skills.length || 0), done = Number(area?.coverage_count || 0);
      const rows = skills.map(skill => `<button class="ep-views-skill" type="button" data-ep-views-skill="${esc(skill.skill_code)}"><span><strong>${esc(c.skill)} ${Number(skill.sequence_no || 0)}</strong><span class="ep-views-skill-meta"> · ${esc(c.checks)}: ${Number(skill.evidence_total || 0)}</span></span><span class="ep-views-badge">${esc(statusLabel(skill.objective_level, skill.correction_case_id))}</span></button>`).join("");
      return `<div class="ep-views-card ep-views-area"><div class="ep-views-area-head"><strong>${esc(areaLabel(area.official_syllabus_section))}</strong><span class="ep-views-sub">${done} / ${total}</span></div><div class="ep-views-progress"><span style="width:${total > 0 ? Math.min(100, 100 * done / total) : 0}%"></span></div>${rows}</div>`;
    }).join("");
    const body = `<div class="ep-views-summary"><div class="ep-views-stat"><span>${esc(c.covered)}</span><strong>${coverage} / ${denominator}</strong></div><div class="ep-views-stat"><span>${esc(c.covered)}</span><strong>${pct.toFixed(0)}%</strong></div><div class="ep-views-stat"><span>${esc(c.corrections)}</span><strong>${Number(data?.open_correction_count || 0)}</strong></div></div>${cards}`;
    root.innerHTML = shell(component, c.tracker, c.trackerIntro, body);
    bindBack(root, component);
    root.querySelectorAll("[data-ep-views-skill]").forEach(button => button.addEventListener("click", () => openSkill(component, button.dataset.epViewsSkill)));
  }

  async function openSkill(component, skillCode) {
    if (busy || !canUse() || typeof internal.api?.skillDetail !== "function") return;
    busy = true; ensureStyle(); renderLoading(component, text().detail);
    const result = await internal.api.skillDetail(component, skillCode); busy = false;
    if (!result?.ok) { renderError(component, text().detail); return; }
    renderSkill(component, result.data || {});
  }

  function prerequisiteStatus(row) {
    const c = text();
    if (row?.kind === "foundation") {
      if (row.foundation_status === "secure") return c.ready;
      if (["blocker", "retest_needed"].includes(row.foundation_status)) return c.blocker;
      return c.unknown;
    }
    const level = Number(row?.skill_objective_level || 0);
    return level >= 2 ? c.ready : level >= 1 ? c.developing : c.unknown;
  }

  function evidenceLabel(row) {
    const c = text();
    const kind = String(row?.evidence_type || "");
    const names = activeLanguage === "uz"
      ? { diagnostic: "Kirish tekshiruvi", learning: "O‘rganish", retest: "Qayta tekshirish", mixed: "Aralash mashq", timed: "Vaqtli mashq", written: "Yozma ish" }
      : activeLanguage === "en"
        ? { diagnostic: "Entry check", learning: "Learning", retest: "Delayed check", mixed: "Mixed practice", timed: "Timed practice", written: "Written work" }
        : { diagnostic: "Входная проверка", learning: "Обучение", retest: "Повторная проверка", mixed: "Смешанная практика", timed: "Практика на время", written: "Письменная работа" };
    const outcome = typeof row?.is_correct === "boolean" ? (row.is_correct ? c.correct : c.incorrect) : c.recorded;
    return `${names[kind] || c.attempt} · ${outcome}`;
  }

  function renderSkill(component, data) {
    const root = rootEl(); if (!root) return; const c = text();
    const state = data?.state || {}, prereqs = Array.isArray(data?.prerequisites) ? data.prerequisites : [], evidence = Array.isArray(data?.evidence_history) ? data.evidence_history : [], corrections = Array.isArray(data?.correction_history) ? data.correction_history : [];
    const title = `${c.skill} ${Number(data?.sequence_no || 0)}`;
    const description = activeLanguage === "ru" && data?.description ? `<div class="ep-views-note">${esc(data.description)}</div>` : "";
    const prereqRows = prereqs.length ? prereqs.map((row, index) => `<div class="ep-views-row"><span>${activeLanguage === "ru" && row?.label ? esc(row.label) : `${esc(c.prerequisite)} ${index + 1}`}</span><span class="ep-views-badge">${esc(prerequisiteStatus(row))}</span></div>`).join("") : `<div class="ep-views-note">${esc(c.noneYet)}</div>`;
    const evidenceRows = evidence.length ? evidence.map(row => `<div class="ep-views-row"><span>${esc(evidenceLabel(row))}</span><small>${row?.created_at ? esc(new Date(row.created_at).toLocaleDateString()) : ""}</small></div>`).join("") : `<div class="ep-views-note">${esc(c.noneYet)}</div>`;
    const correctionRows = corrections.length ? corrections.map(row => `<div class="ep-views-row"><span>${esc(statusLabel(0, row.status === "resolved" ? null : row.correction_case_id))}</span><small>${row?.retest_due_at ? `${esc(c.due)}: ${esc(new Date(row.retest_due_at).toLocaleDateString())}` : ""}</small></div>`).join("") : `<div class="ep-views-note">${esc(c.noneYet)}</div>`;
    const resources = data?.resources || {};
    const resourceRows = [resources.book_chapter ? `<div class="ep-views-row"><span>${esc(c.book)}</span><small>${esc(resources.book_chapter)}</small></div>` : "", resources.book_pages ? `<div class="ep-views-row"><span>${esc(c.pages)}</span><small>${esc(resources.book_pages)}</small></div>` : ""].filter(Boolean).join("") || `<div class="ep-views-note">${esc(c.noneYet)}</div>`;
    const body = `${description}<div class="ep-views-summary"><div class="ep-views-stat"><span>${esc(c.covered)}</span><strong>${esc(statusLabel(state.objective_level, Number(state.unresolved_correction_count || 0) > 0 ? "open" : null))}</strong></div><div class="ep-views-stat"><span>${esc(c.checks)}</span><strong>${Number(state.evidence_total || 0)}</strong></div><div class="ep-views-stat"><span>${esc(c.corrections)}</span><strong>${Number(state.unresolved_correction_count || 0)}</strong></div></div><div class="ep-views-card"><strong>${esc(c.prerequisites)}</strong><div class="ep-views-list">${prereqRows}</div></div><div class="ep-views-card"><strong>${esc(c.history)}</strong><div class="ep-views-list">${evidenceRows}</div></div><div class="ep-views-card"><strong>${esc(c.correctionHistory)}</strong><div class="ep-views-list">${correctionRows}</div></div><div class="ep-views-card"><strong>${esc(c.resources)}</strong><div class="ep-views-list">${resourceRows}</div></div><div class="ep-views-note">${esc(c.writtenNote)}</div><div class="ep-views-actions"><button class="ep-views-btn primary" type="button" data-ep-views-corrections="${esc(component)}">${esc(c.openCorrections)}</button><button class="ep-views-btn" type="button" data-ep-views-tracker-back>${esc(c.backTracker)}</button></div>`;
    root.innerHTML = shell(component, c.detail, areaLabel(data?.official_syllabus_section), body, "tracker");
    bindBack(root, component, "tracker");
    root.querySelector("[data-ep-views-corrections]")?.addEventListener("click", () => openCorrections(component));
    root.querySelector("[data-ep-views-tracker-back]")?.addEventListener("click", () => openTracker(component));
  }

  function correctionStepLabel(value) {
    const c = text();
    return ({ review_error: c.reviewError, practice_analogues: c.analogues, wait_delayed_retest: c.waitRetest, delayed_retest: c.delayedRetest })[String(value || "")] || c.reviewError;
  }

  async function openCorrections(component) {
    if (busy || !canUse() || typeof internal.api?.correctionQueue !== "function") return;
    busy = true; activeLanguage = detectLanguage(); ensureStyle(); renderLoading(component, text().corrections);
    const result = await internal.api.correctionQueue(component); busy = false;
    if (!result?.ok) { renderError(component, text().corrections); return; }
    renderCorrections(component, result.data || {});
  }

  function renderCorrections(component, data) {
    const root = rootEl(); if (!root) return; const c = text();
    const cases = Array.isArray(data?.cases) ? data.cases : [], resolved = Array.isArray(data?.recent_resolved) ? data.recent_resolved : [];
    const rows = cases.length ? cases.map(row => `<div class="ep-views-card"><div class="ep-views-area-head"><strong>${esc(areaLabel(row.official_syllabus_section))}</strong><span class="ep-views-badge">${esc(correctionStepLabel(row.process_step))}</span></div>${activeLanguage === "ru" && row?.description ? `<div class="ep-views-sub">${esc(row.description)}</div>` : ""}${row?.retest_due_at ? `<div class="ep-views-note">${esc(c.due)}: ${esc(new Date(row.retest_due_at).toLocaleString())}</div>` : ""}</div>`).join("") : `<div class="ep-views-note">${esc(c.noCorrections)}</div>`;
    const recent = resolved.length ? `<div class="ep-views-card"><strong>${esc(c.recentResolved)}</strong><div class="ep-views-list">${resolved.map(row => `<div class="ep-views-row"><span>${esc(areaLabel(row.official_syllabus_section))}</span><small>${row?.resolved_at ? esc(new Date(row.resolved_at).toLocaleDateString()) : ""}</small></div>`).join("")}</div></div>` : "";
    const body = `<div class="ep-views-note">${esc(c.queueIntro)}</div><div class="ep-views-summary"><div class="ep-views-stat"><span>${esc(c.corrections)}</span><strong>${Number(data?.active_count || 0)}</strong></div><div class="ep-views-stat"><span>${esc(c.due)}</span><strong>${Number(data?.retest_due_count || 0)}</strong></div><div class="ep-views-stat"><span>${esc(c.recentResolved)}</span><strong>${resolved.length}</strong></div></div>${rows}${recent}<div class="ep-views-actions"><button class="ep-views-btn primary" type="button" data-ep-views-open-plan="${esc(component)}">${esc(c.openPlan)}</button></div>`;
    root.innerHTML = shell(component, c.corrections, c.queueIntro, body);
    bindBack(root, component);
    root.querySelector("[data-ep-views-open-plan]")?.addEventListener("click", () => openWeeklyPlan(component));
  }

  async function openWeeklyPlan(component) {
    if (busy) return; busy = true;
    const ok = await dashboard();
    if (!ok) { busy = false; return; }
    const button = await waitFor(`[data-ep-live-plan="${component}"]`);
    busy = false;
    if (button) button.click();
  }

  function injectDashboardActions() {
    const root = rootEl();
    if (!root || root.hidden || !canUse() || root.querySelector("[data-ep-views-screen]")) return;
    activeLanguage = detectLanguage(); ensureStyle(); const c = text();
    root.querySelectorAll(".ep-live-card").forEach(card => {
      if (card.dataset.epViewsInjected === "1") return;
      const component = card.querySelector("[data-ep-live-plan]")?.dataset.epLivePlan || card.querySelector("[data-ep-live-start]")?.dataset.epLiveStart;
      if (!component || !["P1", "P5"].includes(component)) return;
      const actions = card.querySelector(".ep-live-actions");
      if (!actions) return;
      const tracker = document.createElement("button");
      tracker.type = "button"; tracker.className = "ep-views-btn"; tracker.dataset.epViewsTracker = component; tracker.textContent = c.tracker;
      const corrections = document.createElement("button");
      corrections.type = "button"; corrections.className = "ep-views-btn"; corrections.dataset.epViewsCorrections = component; corrections.textContent = c.corrections;
      tracker.addEventListener("click", () => openTracker(component));
      corrections.addEventListener("click", () => openCorrections(component));
      actions.append(tracker, corrections); card.dataset.epViewsInjected = "1";
    });
  }

  function attach() {
    const root = rootEl();
    if (!root) { setTimeout(attach, 50); return; }
    if (observer) return;
    observer = new MutationObserver(() => injectDashboardActions());
    observer.observe(root, { childList: true, subtree: true });
    injectDashboardActions();
    internal.learnerViews = Object.freeze({ version: VERSION, openTracker, openSkill, openCorrections });
  }

  attach();
})();