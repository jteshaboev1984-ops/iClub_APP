(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "wave1ux3";
  let observer = null;
  let facadeRetry = 0;
  let recoveryResetTimer = null;

  function rootEl() {
    return document.querySelector("#exam-prep-host-root");
  }

  function ensureStylesheet() {
    try {
      if (document.querySelector('link[data-exam-prep-wave1-ux]')) return;
      const src = String(document.currentScript?.src || "");
      if (!/exam-prep-wave1-ux\.js(?:\?|$)/.test(src)) return;
      const link = document.createElement("link");
      link.rel = "stylesheet";
      link.dataset.examPrepWave1Ux = "true";
      link.href = src.replace(/exam-prep-wave1-ux\.js(?:\?.*)?$/, "exam-prep-wave1-ux.css?v=wave1ux3");
      document.head.appendChild(link);
    } catch (_) {}
  }

  function language() {
    try {
      const value = String(window.i18n?.getLang?.() || document.documentElement.lang || "ru").toLowerCase();
      return ["ru", "uz", "en"].includes(value) ? value : "ru";
    } catch (_) {
      return "ru";
    }
  }

  function text() {
    if (language() === "uz") return {
      chooseSeries: "Imtihon sessiyasini tanlang",
      chooseGrade: "Maqsad bahoni tanlang",
      correction: "Xato ustida ishlash"
    };
    if (language() === "en") return {
      chooseSeries: "Choose exam series",
      chooseGrade: "Choose target grade",
      correction: "Work on a correction"
    };
    return {
      chooseSeries: "Выберите экзаменационную сессию",
      chooseGrade: "Выберите целевую оценку",
      correction: "Разобрать ошибку"
    };
  }

  function futureExamSeries(currentValue = "") {
    const current = String(currentValue || "").trim();
    const now = new Date();
    const year = now.getFullYear();
    const values = [];

    for (let y = year; y <= year + 3; y += 1) {
      const mayJuneEnd = new Date(y, 5, 30, 23, 59, 59, 999);
      const octNovEnd = new Date(y, 10, 30, 23, 59, 59, 999);
      if (mayJuneEnd.getTime() >= now.getTime()) values.push(`May/June ${y}`);
      if (octNovEnd.getTime() >= now.getTime()) values.push(`October/November ${y}`);
    }

    if (current && !values.includes(current)) values.unshift(current);
    return [...new Set(values)];
  }

  function replaceWithSelect(input, values, placeholder) {
    if (!input || input.tagName === "SELECT" || input.dataset.epWave1Select === "1") return input;
    const current = String(input.value || input.getAttribute("value") || "").trim();
    const select = document.createElement("select");
    select.name = input.name;
    select.required = input.required;
    select.setAttribute("aria-required", input.getAttribute("aria-required") || "true");
    select.className = input.className || "";
    select.dataset.epWave1Select = "1";

    const empty = document.createElement("option");
    empty.value = "";
    empty.textContent = placeholder;
    empty.disabled = true;
    empty.selected = !current;
    select.appendChild(empty);

    for (const value of values) {
      const option = document.createElement("option");
      option.value = value;
      option.textContent = value;
      option.selected = value === current;
      select.appendChild(option);
    }

    input.replaceWith(select);
    return select;
  }

  function upgradeProfileForms() {
    const root = rootEl();
    if (!root || root.hidden) return;
    const copy = text();
    root.querySelectorAll("[data-ep-live-profile-form], [data-ep-profile-completion-form], [data-ep-exam-plan-form]").forEach(form => {
      const series = form.elements?.exam_series || form.querySelector('[name="exam_series"]');
      if (series?.tagName === "INPUT") {
        const current = String(series.value || series.getAttribute("value") || "").trim();
        replaceWithSelect(series, futureExamSeries(current), copy.chooseSeries);
      }
      const grade = form.elements?.target_grade || form.querySelector('[name="target_grade"]');
      if (grade?.tagName === "INPUT") {
        const current = String(grade.value || grade.getAttribute("value") || "").trim().toUpperCase();
        const grades = ["A", "B", "C", "D", "E"];
        if (current && !grades.includes(current)) grades.unshift(current);
        replaceWithSelect(grade, grades, copy.chooseGrade);
      }
    });
  }

  function consolidateExamPlan() {
    const root = rootEl();
    if (!root || root.hidden) return;
    const profile = root.querySelector(".ep-live-dashboard-profile");
    if (!profile) return;

    const cards = Array.from(root.querySelectorAll(".ep-live-card[data-ep-exam-plan-card]"));
    if (!cards.length) return;

    let edit = profile.querySelector("[data-ep-exam-plan-edit]");
    if (!edit) {
      edit = cards.map(card => card.querySelector("[data-ep-exam-plan-edit]")).find(Boolean) || null;
      if (edit) {
        edit.classList.add("ep-wave1-plan-edit");
        profile.appendChild(edit);
      }
    }

    cards.forEach(card => card.remove());
    if (edit) profile.dataset.epExamPlanCard = "true";
  }

  function visibleButton(selector) {
    const root = rootEl();
    const button = root?.querySelector(selector);
    if (!button || button.disabled) return null;
    if (button.closest("[hidden]") || button.getAttribute("aria-hidden") === "true") return null;
    return button;
  }

  function logicalButton(selector) {
    const root = rootEl();
    const button = root?.querySelector(selector);
    return button && !button.disabled ? button : null;
  }

  function handleInternalBack() {
    const root = rootEl();
    if (!root || root.hidden) return false;

    // The weekly-plan card intentionally hides its duplicate in-card Overview button.
    // The app top arrow must still follow that logical route instead of falling through
    // to the Mathematics subject hub.
    if (root.querySelector(".ep-live-plan-item")) {
      const planBack = logicalButton("[data-ep-live-dashboard]");
      if (planBack) {
        planBack.click();
        return true;
      }
    }

    const selectors = [
      "[data-ep-exam-plan-cancel]",
      "[data-ep-placement-back]",
      "[data-ep-views-back]",
      "[data-ep-materials-back]",
      "[data-ep-recovery-back]",
      "[data-ep-live-home]",
      "[data-ep-live-exit]",
      "[data-ep-live-dashboard]",
      "[data-ep-live-back-timed]"
    ];

    for (const selector of selectors) {
      const button = visibleButton(selector);
      if (button) {
        button.click();
        return true;
      }
    }

    const timedEnd = visibleButton("[data-ep-live-end]");
    if (timedEnd) {
      timedEnd.click();
      return true;
    }
    return false;
  }

  function installTopbarBackBridge() {
    const button = document.querySelector("#topbar-back");
    if (!button || button.dataset.epWave1BackBridge === VERSION) return;
    button.dataset.epWave1BackBridge = VERSION;
    button.addEventListener("click", event => {
      const root = rootEl();
      if (!root || root.hidden) return;
      let open = true;
      try {
        if (typeof window.iClubExamPrep?.isOpen === "function") open = window.iClubExamPrep.isOpen() === true;
      } catch (_) {}
      if (!open || !handleInternalBack()) return;
      event.preventDefault();
      event.stopImmediatePropagation();
    }, true);
  }

  function installBackWrapper() {
    const app = window.iClubExamPrep;
    if (!app || typeof app.back !== "function" || !app.liveFlowVersion) {
      if (facadeRetry < 240) {
        facadeRetry += 1;
        setTimeout(installBackWrapper, 50);
      }
      return;
    }
    if (app.wave1UxVersion === VERSION) return;

    const original = app;
    const wrapped = Object.assign({}, original, {
      back: () => {
        if (handleInternalBack()) return true;
        return original.back();
      },
      wave1UxVersion: VERSION
    });
    window.iClubExamPrep = Object.freeze(wrapped);
  }

  function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async function retryCall(fn, args, attempts, delays) {
    let last = null;
    for (let index = 0; index < attempts; index += 1) {
      try {
        last = await fn(...args);
      } catch (error) {
        last = Object.freeze({ ok: false, reason: "retry_exception", error });
      }
      if (last?.ok) return last;
      if (index < attempts - 1) await sleep(delays[index] || delays[delays.length - 1] || 180);
    }
    return last;
  }

  function installApiResilience() {
    const api = internal.api;
    if (!api || api.wave1ResilienceVersion === VERSION) return;

    const wrapped = Object.assign({}, api);
    const readMethods = [
      "examProfile", "examMapStatus", "diagnosticProgress", "getPlacement", "getState", "overview",
      "legacyReferenceSummary", "placementResult", "stage0Workflow", "syllabusTracker", "skillDetail",
      "correctionQueue", "pastPaperCompanion", "materialsLibrary", "getSession", "integrityStatus", "recovery",
      "weeklyPlan", "timedCatalog", "timedResult", "timedReviewPack", "readiness", "finalCalibration"
    ];
    const idempotentWriteMethods = [
      "startNextDiagnostic", "startSession", "submitResponse", "finalizeSession", "finalizeTimed", "submitTimedSelfMark"
    ];

    readMethods.forEach(name => {
      if (typeof api[name] !== "function") return;
      wrapped[name] = (...args) => retryCall(api[name].bind(api), args, 3, [160, 360]);
    });
    idempotentWriteMethods.forEach(name => {
      if (typeof api[name] !== "function") return;
      wrapped[name] = (...args) => retryCall(api[name].bind(api), args, 2, [180]);
    });

    wrapped.wave1ResilienceVersion = VERSION;
    internal.api = Object.freeze(wrapped);
  }

  function stableViewVisible() {
    const root = rootEl();
    if (!root || root.hidden) return false;
    return Boolean(root.querySelector(
      ".ep-live-grid, [data-ep-component-home], [data-ep-live-profile-form], [data-ep-live-submit], [data-ep-placement-screen], [data-ep-views-screen], [data-ep-materials-screen], [data-ep-recovery-form-view], [data-ep-recovery-check-view]"
    ));
  }

  function resetRecoveryAfterStableView() {
    const root = rootEl();
    if (!root || root.dataset.epWave1AutoRecovery !== "1" || !stableViewVisible()) return;
    if (recoveryResetTimer) clearTimeout(recoveryResetTimer);
    recoveryResetTimer = setTimeout(() => {
      const current = rootEl();
      if (current && stableViewVisible() && !current.querySelector(".ep-live-error")) {
        delete current.dataset.epWave1AutoRecovery;
      }
      recoveryResetTimer = null;
    }, 700);
  }

  function recoverTransientLiveError() {
    const root = rootEl();
    if (!root || root.hidden) return;
    const error = root.querySelector(".ep-live-error");
    const home = visibleButton("[data-ep-live-home]");
    if (!error || !home) {
      resetRecoveryAfterStableView();
      return;
    }
    if (root.dataset.epWave1AutoRecovery === "1") return;
    root.dataset.epWave1AutoRecovery = "1";
    setTimeout(() => {
      const currentRoot = rootEl();
      const retryButton = visibleButton("[data-ep-live-home]");
      if (!currentRoot || currentRoot.hidden || !currentRoot.querySelector(".ep-live-error") || !retryButton) return;
      retryButton.click();
    }, 120);
  }

  function placementComponent() {
    const root = rootEl();
    const screen = root?.querySelector("[data-ep-placement-screen]");
    const value = String(screen?.textContent || "");
    const match = value.match(/\b(P1|P5)\b/);
    return match ? match[1] : null;
  }

  function installCorrectionRouter() {
    const root = rootEl();
    if (!root || root.dataset.epWave1CorrectionRouter === VERSION) return;
    root.dataset.epWave1CorrectionRouter = VERSION;
    root.addEventListener("click", event => {
      const button = event.target.closest?.("[data-ep-placement-next]");
      if (!button || !root.contains(button)) return;
      const label = String(button.textContent || "").trim();
      const correctionLabels = new Set(["Разобрать ошибку", "Work on a correction", "Xato ustida ishlash"]);
      if (!correctionLabels.has(label)) return;
      const component = placementComponent();
      if (!component || typeof internal.learnerViews?.openCorrections !== "function") return;
      event.preventDefault();
      event.stopImmediatePropagation();
      internal.learnerViews.openCorrections(component);
    }, true);
  }

  function reconcile() {
    upgradeProfileForms();
    consolidateExamPlan();
    installApiResilience();
    installBackWrapper();
    installTopbarBackBridge();
    installCorrectionRouter();
    recoverTransientLiveError();
  }

  function attach() {
    const root = rootEl();
    if (!root) {
      setTimeout(attach, 50);
      return;
    }
    if (!observer) {
      observer = new MutationObserver(reconcile);
      observer.observe(root, { childList: true, subtree: true, attributes: true, attributeFilter: ["hidden", "aria-hidden"] });
    }
    reconcile();
    internal.wave1UxVersion = VERSION;
  }

  ensureStylesheet();
  attach();
})();