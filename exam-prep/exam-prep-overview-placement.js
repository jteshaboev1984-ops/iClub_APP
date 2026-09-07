(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p021overview1";
  let observer = null;
  let busy = false;
  let activeLanguage = "ru";

  function rootEl() { return document.querySelector("#exam-prep-host-root"); }

  function detectLanguage() {
    const value = String(rootEl()?.textContent || "");
    if (/Umumiy ko‘rinish|Haftalik|Imtihon tayyorgarligi|Dastur bo‘yicha/i.test(value)) return "uz";
    if (/\bOverview\b|weekly plan|exam preparation|entry check|syllabus progress/i.test(value)) return "en";
    return "ru";
  }

  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;").replaceAll("'", "&#039;");
  }

  function copy() {
    if (activeLanguage === "uz") return {
      overview: "Umumiy ko‘rinish", currentPhase: "Joriy bosqich", confirmedCoverage: "Tasdiqlangan qamrov", lastCheck: "Oxirgi tasdiq", nextStep: "Keyingi qadam",
      noLastCheck: "Hali tasdiqlangan natija yo‘q", placementResult: "Kirish tekshiruvi natijasi", placementIntro: "Natija faqat shu komponent uchun hisoblanadi. Paper 1 va Paper 5 bir-birini ko‘tarmaydi.",
      checkProgress: "Tekshiruv progressi", checkedAreas: "Tekshirilgan bo‘limlar", currentDirection: "Hozirgi yo‘nalish", confidence: "Tasdiqlash holati", foundationChecks: "Tayanch bilimlar",
      moreEvidence: "Yana dalil kerak", currentRouteConfirmed: "Joriy yo‘nalish uchun dalil yetarli", notStarted: "Boshlanmagan", inProgress: "Tekshiruv davom etmoqda", foundationRoute: "Hozircha asoslarni mustahkamlash yo‘li", confirmedRoute: "Yo‘nalish tasdiqlangan", contentUnavailable: "Hozircha mavjud emas",
      directionPending: "Yetarli dalil yig‘ilmoqda", directionFoundation: "Asoslarni mustahkamlash", directionAccelerated: "Tezlashtirilgan dastur yo‘li", directionConsolidation: "Mustahkamlash va aralash mashqlar", directionExam: "Imtihon rejimi",
      unknownFoundations: "hali tekshirilmagan", foundationBlockers: "mustahkamlash kerak", continueCheck: "Kirish tekshiruvini davom ettirish", openPlan: "Haftalik rejani ochish", workCorrection: "Xato ustida ishlash", delayedRetest: "Qayta tekshirish", mixedPractice: "Aralash mashq", learning: "Keyingi mavzuni o‘rganish", strengthenFoundation: "Tayanch bilimni mustahkamlash", updatePlan: "Rejani yangilash", readiness: "Imtihon tayyorgarligini ko‘rish", finalCalibration: "Yakuniy moslashuv", noResult: "Natija hali mavjud emas.", loading: "Yuklanmoqda…", error: "Ma’lumotni yuklab bo‘lmadi. Qayta urinib ko‘ring.",
      stage0: "Kirish tekshiruvi", stage1: "Asoslarni mustahkamlash", stage2: "Dastur bo‘yicha o‘rganish", stage3: "Dastur qamrovini yopish", stage4: "Vaqt ostida mustahkamlash", stage5: "Imtihon tayyorgarligi", stage6: "Yakuniy moslashuv",
      diagnostic: "Kirish tekshiruvi", evidenceCorrect: "to‘g‘ri", evidenceIncorrect: "xato", evidenceRecorded: "saqlangan", placementNote: "Noaniq natija tezroq yo‘lni avtomatik ochmaydi. Kerak bo‘lsa qo‘shimcha tekshiruv bilan tasdiqlanadi.", back: "Umumiy ko‘rinishga qaytish"
    };
    if (activeLanguage === "en") return {
      overview: "Overview", currentPhase: "Current phase", confirmedCoverage: "Confirmed coverage", lastCheck: "Last confirmation", nextStep: "Next step",
      noLastCheck: "No confirmed result yet", placementResult: "Entry check result", placementIntro: "This result belongs only to this component. Paper 1 and Paper 5 do not raise each other.",
      checkProgress: "Check progress", checkedAreas: "Areas checked", currentDirection: "Current direction", confidence: "Confirmation status", foundationChecks: "Foundation checks",
      moreEvidence: "More evidence is needed", currentRouteConfirmed: "Evidence is sufficient for the current route", notStarted: "Not started", inProgress: "Check in progress", foundationRoute: "Foundation route for now", confirmedRoute: "Route confirmed", contentUnavailable: "Temporarily unavailable",
      directionPending: "Gathering enough evidence", directionFoundation: "Strengthen foundations", directionAccelerated: "Accelerated syllabus route", directionConsolidation: "Consolidation and mixed practice", directionExam: "Exam mode",
      unknownFoundations: "not checked yet", foundationBlockers: "need work", continueCheck: "Continue entry check", openPlan: "Open weekly plan", workCorrection: "Work on a correction", delayedRetest: "Complete delayed check", mixedPractice: "Mixed practice", learning: "Study the next topic", strengthenFoundation: "Strengthen a foundation", updatePlan: "Update weekly plan", readiness: "Review exam readiness", finalCalibration: "Final calibration", noResult: "No result is available yet.", loading: "Loading…", error: "Could not load this information. Try again.",
      stage0: "Entry check", stage1: "Foundation", stage2: "Syllabus learning", stage3: "Syllabus closure", stage4: "Timed consolidation", stage5: "Exam readiness", stage6: "Final calibration",
      diagnostic: "Entry check", evidenceCorrect: "correct", evidenceIncorrect: "needs review", evidenceRecorded: "recorded", placementNote: "Ambiguous evidence never unlocks a faster route automatically. Extra evidence can be used to confirm the route when needed.", back: "Back to overview"
    };
    return {
      overview: "Обзор", currentPhase: "Текущий этап", confirmedCoverage: "Подтверждённое покрытие", lastCheck: "Последнее подтверждение", nextStep: "Следующий шаг",
      noLastCheck: "Подтверждённых результатов пока нет", placementResult: "Результат входной проверки", placementIntro: "Этот результат относится только к выбранному компоненту. Paper 1 и Paper 5 не повышают результат друг друга.",
      checkProgress: "Прогресс проверки", checkedAreas: "Проверено разделов", currentDirection: "Текущее направление", confidence: "Статус подтверждения", foundationChecks: "Базовые знания",
      moreEvidence: "Нужно больше подтверждений", currentRouteConfirmed: "Подтверждений достаточно для текущего маршрута", notStarted: "Не начато", inProgress: "Проверка продолжается", foundationRoute: "Пока маршрут через укрепление основ", confirmedRoute: "Маршрут подтверждён", contentUnavailable: "Временно недоступно",
      directionPending: "Собираем достаточно подтверждений", directionFoundation: "Укрепление основ", directionAccelerated: "Ускоренное прохождение программы", directionConsolidation: "Закрепление и смешанная практика", directionExam: "Экзаменационный режим",
      unknownFoundations: "ещё не проверено", foundationBlockers: "нужно укрепить", continueCheck: "Продолжить входную проверку", openPlan: "Открыть недельный план", workCorrection: "Разобрать ошибку", delayedRetest: "Пройти повторную проверку", mixedPractice: "Смешанная практика", learning: "Изучить следующую тему", strengthenFoundation: "Укрепить базовое знание", updatePlan: "Обновить недельный план", readiness: "Посмотреть готовность к экзамену", finalCalibration: "Финальная калибровка", noResult: "Результат пока недоступен.", loading: "Загрузка…", error: "Не удалось загрузить данные. Попробуйте ещё раз.",
      stage0: "Входная проверка", stage1: "Фундамент", stage2: "Изучение программы", stage3: "Закрытие программы", stage4: "Закрепление на время", stage5: "Готовность к экзамену", stage6: "Финальная калибровка",
      diagnostic: "Входная проверка", evidenceCorrect: "верно", evidenceIncorrect: "нужно разобрать", evidenceRecorded: "сохранено", placementNote: "Неоднозначный результат не открывает ускоренный маршрут автоматически. При необходимости маршрут подтверждается дополнительными заданиями.", back: "Вернуться к обзору"
    };
  }

  function ensureStyle() {
    if (document.querySelector("#ep-overview-placement-style")) return;
    const style = document.createElement("style");
    style.id = "ep-overview-placement-style";
    style.textContent = `
      .ep-overview-strip{display:grid;gap:9px;border-top:1px solid rgba(127,127,127,.14);padding-top:10px}.ep-overview-mini{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px}.ep-overview-stat{display:grid;gap:3px;padding:8px;border-radius:10px;background:rgba(127,127,127,.055)}.ep-overview-stat span{font-size:10px;opacity:.7}.ep-overview-stat strong{font-size:13px;line-height:1.25}.ep-overview-last{font-size:11px;opacity:.76;line-height:1.35}
      .ep-placement-shell{display:grid;gap:12px}.ep-placement-top{display:flex;justify-content:space-between;gap:10px;align-items:flex-start}.ep-placement-title{font-size:20px;font-weight:800}.ep-placement-sub{font-size:12px;opacity:.72;margin-top:3px}.ep-placement-card{display:grid;gap:10px;border:1px solid rgba(127,127,127,.22);border-radius:14px;padding:13px;background:rgba(127,127,127,.035)}.ep-placement-summary{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}.ep-placement-stat{display:grid;gap:3px;border:1px solid rgba(127,127,127,.16);border-radius:10px;padding:10px}.ep-placement-stat span{font-size:11px;opacity:.72}.ep-placement-stat strong{font-size:15px;line-height:1.3}.ep-placement-note{padding:10px;border-radius:10px;background:rgba(127,127,127,.08);font-size:12px;line-height:1.45}.ep-placement-actions{display:flex;gap:8px;flex-wrap:wrap}.ep-placement-btn{border:1px solid rgba(127,127,127,.28);border-radius:10px;padding:8px 10px;background:transparent;color:inherit;font:inherit;font-weight:700;cursor:pointer}.ep-placement-btn.primary{background:#111827;color:#fff;border-color:#111827}.ep-placement-error{padding:10px;border-radius:10px;background:rgba(180,30,30,.12);font-size:13px}
      @media(max-width:680px){.ep-overview-mini,.ep-placement-summary{grid-template-columns:1fr}.ep-placement-top{display:grid}.ep-placement-actions .ep-placement-btn{flex:1 1 auto}}
    `;
    document.head.appendChild(style);
  }

  function stageLabel(value) {
    const c = copy();
    const n = Math.max(0, Math.min(6, Number(value || 0)));
    return c[`stage${n}`] || c.stage0;
  }

  function nextActionLabel(code) {
    const c = copy();
    return ({
      continue_entry_check: c.continueCheck,
      open_weekly_plan: c.openPlan,
      delayed_retest: c.delayedRetest,
      work_correction: c.workCorrection,
      mixed_practice: c.mixedPractice,
      learning: c.learning,
      foundation_prerequisite: c.strengthenFoundation,
      update_plan: c.updatePlan,
      view_readiness: c.readiness,
      final_calibration: c.finalCalibration
    })[String(code || "")] || c.openPlan;
  }

  function evidenceText(row) {
    const c = copy();
    if (!row) return c.noLastCheck;
    const type = String(row.evidence_type || "") === "diagnostic" ? c.diagnostic : c.lastCheck;
    const outcome = typeof row.is_correct === "boolean" ? (row.is_correct ? c.evidenceCorrect : c.evidenceIncorrect) : c.evidenceRecorded;
    const date = row.created_at ? new Date(row.created_at).toLocaleDateString() : "";
    return [type, outcome, date].filter(Boolean).join(" · ");
  }

  function placementStatus(data) {
    const c = copy();
    const status = String(data?.placement_status || "not_started");
    if (status === "content_blocked") return c.contentUnavailable;
    if (status === "screening_incomplete" || status === "targeted_required") return c.inProgress;
    if (status === "conservative_foundation") return c.foundationRoute;
    if (status === "confirmed") return c.confirmedRoute;
    return c.notStarted;
  }

  function routeLabel(route) {
    const c = copy();
    return ({
      pending_evidence: c.directionPending,
      foundation: c.directionFoundation,
      accelerated_coverage: c.directionAccelerated,
      consolidation: c.directionConsolidation,
      exam_mode: c.directionExam
    })[String(route || "")] || c.directionPending;
  }

  async function dashboard() {
    const app = window.iClubExamPrep;
    if (!app || typeof app.open !== "function") return false;
    return Boolean(await app.open({ subjectKey: "mathematics", language: activeLanguage }));
  }

  async function waitFor(selector, attempts = 40) {
    for (let i = 0; i < attempts; i += 1) {
      const node = document.querySelector(selector);
      if (node) return node;
      await new Promise(resolve => setTimeout(resolve, 25));
    }
    return null;
  }

  async function runNextAction(component, actionCode) {
    const ok = await dashboard();
    if (!ok) return;
    const selector = actionCode === "continue_entry_check" ? `[data-ep-live-start="${component}"]` : `[data-ep-live-plan="${component}"]`;
    const button = await waitFor(selector);
    if (button) button.click();
  }

  function renderPlacementLoading(component) {
    const root = rootEl(); if (!root) return;
    const c = copy();
    root.innerHTML = `<section class="ep-host-shell ep-placement-shell" data-ep-placement-screen><div class="ep-placement-top"><div><div class="ep-placement-sub">${esc(component)} · Cambridge AS Mathematics</div><div class="ep-placement-title">${esc(c.placementResult)}</div></div><button class="ep-placement-btn" type="button" data-ep-placement-back>${esc(c.back)}</button></div><div class="ep-placement-card">${esc(c.loading)}</div></section>`;
    root.querySelector("[data-ep-placement-back]")?.addEventListener("click", dashboard);
  }

  function renderPlacementError(component) {
    const root = rootEl(); if (!root) return;
    const c = copy();
    root.innerHTML = `<section class="ep-host-shell ep-placement-shell" data-ep-placement-screen><div class="ep-placement-top"><div><div class="ep-placement-sub">${esc(component)} · Cambridge AS Mathematics</div><div class="ep-placement-title">${esc(c.placementResult)}</div></div><button class="ep-placement-btn" type="button" data-ep-placement-back>${esc(c.back)}</button></div><div class="ep-placement-error">${esc(c.error)}</div></section>`;
    root.querySelector("[data-ep-placement-back]")?.addEventListener("click", dashboard);
  }

  async function openPlacement(component) {
    if (busy || !canUse() || typeof internal.api?.placementResult !== "function") return;
    busy = true;
    activeLanguage = detectLanguage();
    ensureStyle();
    renderPlacementLoading(component);
    const result = await internal.api.placementResult(component);
    busy = false;
    if (!result?.ok) { renderPlacementError(component); return; }
    renderPlacement(component, result.data || {});
  }

  function renderPlacement(component, data) {
    const root = rootEl(); if (!root) return;
    const c = copy();
    const screening = data?.screening || {};
    const prerequisites = data?.prerequisites || {};
    const available = data?.available !== false;
    const actionCode = String(data?.next_action_code || "continue_entry_check");
    const body = !available
      ? `<div class="ep-placement-card"><div class="ep-placement-note">${esc(c.noResult)}</div></div>`
      : `<div class="ep-placement-card"><div class="ep-placement-summary">
          <div class="ep-placement-stat"><span>${esc(c.checkProgress)}</span><strong>${Number(screening.answered_items || 0)} / ${Number(screening.required_items || 0)}</strong></div>
          <div class="ep-placement-stat"><span>${esc(c.checkedAreas)}</span><strong>${Number(screening.answered_areas || 0)} / ${Number(screening.required_areas || 0)}</strong></div>
          <div class="ep-placement-stat"><span>${esc(c.currentDirection)}</span><strong>${esc(routeLabel(data?.provisional_route))}</strong></div>
          <div class="ep-placement-stat"><span>${esc(c.confidence)}</span><strong>${esc(data?.ambiguity === false ? c.currentRouteConfirmed : c.moreEvidence)}</strong></div>
        </div><div class="ep-placement-note"><strong>${esc(placementStatus(data))}</strong><br>${esc(c.placementNote)}</div>
        <div class="ep-placement-note">${esc(c.foundationChecks)}: ${Number(prerequisites.unknown_count || 0)} ${esc(c.unknownFoundations)} · ${Number(prerequisites.blocker_count || 0)} ${esc(c.foundationBlockers)}</div></div>`;
    root.innerHTML = `<section class="ep-host-shell ep-placement-shell" data-ep-placement-screen><div class="ep-placement-top"><div><div class="ep-placement-sub">${esc(component)} · Cambridge AS Mathematics</div><div class="ep-placement-title">${esc(c.placementResult)}</div><div class="ep-placement-sub">${esc(c.placementIntro)}</div></div><button class="ep-placement-btn" type="button" data-ep-placement-back>${esc(c.back)}</button></div>${body}<div class="ep-placement-actions"><button class="ep-placement-btn primary" type="button" data-ep-placement-next>${esc(nextActionLabel(actionCode))}</button></div></section>`;
    root.querySelector("[data-ep-placement-back]")?.addEventListener("click", dashboard);
    root.querySelector("[data-ep-placement-next]")?.addEventListener("click", () => runNextAction(component, actionCode));
  }

  async function hydrateOverview(card, component) {
    if (!card?.isConnected || typeof internal.api?.overview !== "function") return;
    const result = await internal.api.overview(component);
    if (!result?.ok || !card.isConnected || card.querySelector("[data-ep-overview-strip]")) return;
    const c = copy();
    const data = result.data || {};
    const denominator = Number(data.denominator_count || (component === "P1" ? 45 : 36));
    const count = Number(data.coverage_count || 0);
    const pct = Number(data.coverage_pct || 0);
    const actionCode = data?.next_action?.action_code;
    const strip = document.createElement("div");
    strip.className = "ep-overview-strip";
    strip.dataset.epOverviewStrip = component;
    strip.innerHTML = `<div class="ep-overview-mini">
        <div class="ep-overview-stat"><span>${esc(c.currentPhase)}</span><strong>${esc(stageLabel(data.operational_stage))}</strong></div>
        <div class="ep-overview-stat"><span>${esc(c.confirmedCoverage)}</span><strong>${count} / ${denominator} · ${Math.max(0, Math.min(100, pct)).toFixed(0)}%</strong></div>
        <div class="ep-overview-stat"><span>${esc(c.nextStep)}</span><strong>${esc(nextActionLabel(actionCode))}</strong></div>
      </div><div class="ep-overview-last">${esc(c.lastCheck)}: ${esc(evidenceText(data.last_evidence))}</div>`;
    const actions = card.querySelector(".ep-live-actions");
    if (actions) card.insertBefore(strip, actions); else card.append(strip);
  }

  function injectDashboard() {
    const root = rootEl();
    if (!root || root.hidden || !canUse() || root.querySelector("[data-ep-placement-screen]") || root.querySelector("[data-ep-views-screen]")) return;
    activeLanguage = detectLanguage();
    ensureStyle();
    root.querySelectorAll(".ep-live-card").forEach(card => {
      const component = card.querySelector("[data-ep-live-plan]")?.dataset.epLivePlan || card.querySelector("[data-ep-live-start]")?.dataset.epLiveStart;
      if (!component || !["P1", "P5"].includes(component)) return;
      if (card.dataset.epOverviewInjected !== "1") {
        const actions = card.querySelector(".ep-live-actions");
        if (actions) {
          const button = document.createElement("button");
          button.type = "button";
          button.className = "ep-placement-btn";
          button.dataset.epPlacementOpen = component;
          button.textContent = copy().placementResult;
          button.addEventListener("click", () => openPlacement(component));
          actions.append(button);
        }
        card.dataset.epOverviewInjected = "1";
      }
      hydrateOverview(card, component);
    });
  }

  function attach() {
    const root = rootEl();
    if (!root) { setTimeout(attach, 50); return; }
    if (observer) return;
    observer = new MutationObserver(() => injectDashboard());
    observer.observe(root, { childList: true, subtree: true });
    injectDashboard();
    internal.overviewPlacementViews = Object.freeze({ version: VERSION, openPlacement });
  }

  attach();
})();