(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "polish2";
  let observer = null;
  let reconcileQueued = false;
  let pendingVisual = null;
  let pendingQuestionLabel = "";
  let lastScreenKey = "";
  let lastSessionType = "";
  let toastTimer = null;

  function rootEl() {
    return document.querySelector("#exam-prep-host-root");
  }

  function language() {
    try {
      const value = String(window.i18n?.getLang?.() || document.documentElement.lang || "ru").toLowerCase();
      if (value.startsWith("uz")) return "uz";
      if (value.startsWith("en")) return "en";
    } catch (_) {}
    return "ru";
  }

  function copy() {
    if (language() === "uz") return {
      saving: "Javob saqlanmoqda…",
      saved: "Javob saqlandi",
      correct: "To‘g‘ri",
      incorrect: "Xatoni keyin ko‘rib chiqamiz",
      topic: "Mavzu"
    };
    if (language() === "en") return {
      saving: "Saving answer…",
      saved: "Answer saved",
      correct: "Correct",
      incorrect: "We’ll review this mistake next",
      topic: "Topic"
    };
    return {
      saving: "Сохраняем ответ…",
      saved: "Ответ сохранён",
      correct: "Верно",
      incorrect: "Есть ошибка — разберём её дальше",
      topic: "Тема"
    };
  }

  function humanizeRu(value) {
    let text = String(value || "");
    if (language() !== "ru" || !text) return text;
    const phrases = [
      [/equation of a straight line/gi, "уравнение прямой"],
      [/equation of a circle/gi, "уравнение окружности"],
      [/circle geometry problems/gi, "задачи по геометрии окружности"],
      [/gradient conditions/gi, "условия для углового коэффициента"],
      [/parallel and perpendicular lines/gi, "параллельных и перпендикулярных прямых"],
      [/expanded form/gi, "развёрнутую форму"],
      [/parameter conditions/gi, "условия на параметр"],
      [/arc length/gi, "длину дуги"],
      [/sector area/gi, "площадь сектора"],
      [/composite sector\/segment problems/gi, "составные задачи на сектор и сегмент"],
      [/graphs of sin, cos (?:и|and) tan/gi, "графики sin, cos и tan"],
      [/simple transformations/gi, "простые преобразования"],
      [/exact values/gi, "точные значения"],
      [/line[–-]circle/gi, "задачи с прямой и окружностью"],
      [/degrees/gi, "градусы"],
      [/radians/gi, "радианы"],
      [/gradient/gi, "угловой коэффициент"],
      [/distance/gi, "расстояние"],
      [/midpoint/gi, "середину отрезка"],
      [/intersections?/gi, "точки пересечения"],
      [/intersection/gi, "точку пересечения"],
      [/tangency/gi, "касание"],
      [/roots/gi, "корни"],
      [/discriminant/gi, "дискриминант"],
      [/centre/gi, "центр"],
      [/radius/gi, "радиус"],
      [/algebra/gi, "алгебру"],
      [/geometry/gi, "геометрию"],
      [/routine/gi, "базовых"],
      [/transfer/gi, "переноса навыка"],
      [/mixed\/timed/gi, "смешанных задач на время"],
      [/delayed retest/gi, "повторной проверки"]
    ];
    phrases.forEach(([pattern, replacement]) => { text = text.replace(pattern, replacement); });
    return text.replace(/\s{2,}/g, " ").trim();
  }

  function setTextIfChanged(node, value) {
    if (!node) return;
    const next = String(value ?? "");
    if (node.textContent !== next) node.textContent = next;
  }

  function planVisible() {
    const root = rootEl();
    return Boolean(root?.querySelector(".ep-live-plan-item"));
  }

  function polishPlan() {
    const root = rootEl();
    if (!root || !planVisible()) return;
    const card = root.querySelector(".ep-live-plan-item")?.closest(".ep-live-card") || root.querySelector(".ep-live-card");
    if (!card) return;
    card.classList.add("ep-flow-plan-clean");

    root.querySelectorAll(".ep-flow-plan-intro").forEach(node => node.remove());

    const dashboardButton = card.querySelector(".ep-live-head [data-ep-live-dashboard]");
    if (dashboardButton) {
      dashboardButton.hidden = true;
      dashboardButton.tabIndex = -1;
      dashboardButton.setAttribute("aria-hidden", "true");
    }

    root.querySelectorAll(".ep-flow-task-name").forEach(node => {
      setTextIfChanged(node, humanizeRu(node.textContent));
    });
    root.querySelectorAll(".ep-flow-task-meta").forEach(node => {
      const parts = String(node.textContent || "").split(" · ").filter(Boolean);
      setTextIfChanged(node, humanizeRu(parts[0] || ""));
    });
  }

  function polishSkillLabels() {
    const root = rootEl();
    if (!root) return;
    root.querySelectorAll(".ep-flow-task-name, .ep-flow-correction-title, .ep-flow-completion-skill strong, [data-ep-views-skill] strong").forEach(node => {
      setTextIfChanged(node, humanizeRu(node.textContent));
    });

    root.querySelectorAll("[data-ep-views-skill] .ep-views-skill-meta").forEach(node => {
      const cleaned = String(node.textContent || "")
        .replace(/\s*·\s*(Навык|Skill|Ko‘nikma)\s+\d+/gi, "")
        .replace(/^\s*·\s*/, " · ");
      setTextIfChanged(node, cleaned);
    });

    root.querySelectorAll(".ep-flow-completion-skill > span").forEach(node => {
      setTextIfChanged(node, copy().topic);
    });
  }

  function compactLoading() {
    const root = rootEl();
    if (!root) return;
    root.querySelectorAll(".ep-flow-loading-surface").forEach(node => {
      node.classList.add("ep-flow-loading-compact");
      node.querySelector(".ep-flow-loader small")?.remove();
    });
  }

  function setPendingState(screen, { disableControls = false } = {}) {
    if (!screen) return;
    screen.classList.add("ep-flow-pending-visual");
    screen.setAttribute("aria-busy", "true");
    if (disableControls) {
      screen.querySelectorAll("input, textarea, select, button").forEach(node => { node.disabled = true; });
    }
    const submit = screen.querySelector("[data-ep-live-submit]");
    if (submit) {
      submit.classList.add("ep-flow-submit-pending");
      submit.setAttribute("aria-busy", "true");
      submit.innerHTML = `<span class="ep-flow-mini-spinner" aria-hidden="true"></span><span>${copy().saving}</span>`;
    }
    screen.querySelectorAll(".ep-live-notice[role='status']").forEach(node => node.remove());
  }

  function capturePendingVisual() {
    const root = rootEl();
    if (!root) return;
    const screen = root.firstElementChild;
    const submit = root.querySelector("[data-ep-live-submit]");
    if (!screen || !submit) return;
    pendingVisual = screen.cloneNode(true);
    pendingQuestionLabel = String(root.querySelector(".ep-live-head strong")?.textContent || "");
    setPendingState(pendingVisual, { disableControls: true });

    // Match the rest of iClub: keep the current surface in place while work happens.
    // Only the submit control changes; no opacity animation or screen replacement is shown to the learner.
    screen.setAttribute("aria-busy", "true");
    submit.classList.add("ep-flow-submit-pending");
    submit.setAttribute("aria-busy", "true");
    submit.innerHTML = `<span class="ep-flow-mini-spinner" aria-hidden="true"></span><span>${copy().saving}</span>`;
  }

  function looksLikeLoading(root = rootEl()) {
    if (!root) return false;
    const status = root.querySelector('[role="status"]');
    return Boolean(status && (/Загрузка|Loading|Yuklanmoqda|Сохраняем|Saving|Saqlanmoqda/i.test(status.textContent || "") || status.querySelector(".ep-flow-loader")));
  }

  function applyPendingVisual() {
    const root = rootEl();
    if (!root || !pendingVisual) return false;
    if (root.querySelector(".ep-flow-pending-visual")) return true;
    if (!looksLikeLoading(root)) return false;

    const clone = pendingVisual.cloneNode(true);
    setPendingState(clone, { disableControls: true });
    root.replaceChildren(clone);
    return true;
  }

  function feedbackTitle(raw) {
    const c = copy();
    const text = String(raw || "").trim();
    if (lastSessionType === "diagnostic") return c.saved;
    if (/^(Верно|Correct|To‘g‘ri)\b/i.test(text)) return c.correct;
    if (/^(Разберите|Review this mistake|Xatoni|Есть ошибка)/i.test(text)) return c.incorrect;
    return c.saved;
  }

  function showAppToast(raw) {
    const toast = document.getElementById("toast");
    if (!toast) return;
    toast.textContent = feedbackTitle(raw);
    toast.classList.add("is-show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove("is-show"), 1600);
  }

  function compactQuestionNotice() {
    const root = rootEl();
    if (!root || !root.querySelector("[data-ep-live-submit]") || root.querySelector(".ep-flow-pending-visual")) return false;
    const notice = root.querySelector(".ep-live-notice[role='status']");
    if (!notice) return false;
    const raw = String(notice.textContent || "");
    notice.remove();
    showAppToast(raw);
    return true;
  }

  function findScrollContainer(node) {
    let current = node?.parentElement || null;
    while (current && current !== document.body && current !== document.documentElement) {
      const style = window.getComputedStyle(current);
      if (/(auto|scroll)/.test(style.overflowY || "") && current.scrollHeight > current.clientHeight + 8) return current;
      current = current.parentElement;
    }
    return document.scrollingElement || document.documentElement;
  }

  function screenKey() {
    const root = rootEl();
    if (!root || root.hidden) return "closed";
    if (root.querySelector(".ep-flow-pending-visual")) return lastScreenKey || "question";
    if (root.querySelector(".ep-flow-completion-screen")) return "completion";
    if (root.querySelector("[data-ep-placement-screen]")) return "placement";
    if (root.querySelector("[data-ep-materials-screen]")) return "materials";
    if (root.querySelector("[data-ep-recovery-screen]")) return "recovery";
    if (root.querySelector("[data-ep-views-screen]")) return `views:${String(root.querySelector(".ep-views-title")?.textContent || "")}`;
    if (root.querySelector(".ep-live-plan-item")) return "plan";
    if (root.querySelector("[data-ep-live-submit]")) return "question";
    if (root.querySelector(".ep-live-grid")) return "dashboard";
    if (root.querySelector(".ep-live-error")) return "error";
    return "other";
  }

  function syncScreenPosition() {
    const root = rootEl();
    if (!root) return;
    const key = screenKey();
    if (!key || key === lastScreenKey) return;
    const previous = lastScreenKey;
    lastScreenKey = key;

    // Global iClub views/stack screens switch directly. Exam Prep follows the same rule:
    // no local fade/translate animation and no forced layout reflow.
    if (key !== "question" && key !== "other" && key !== "closed" && previous) {
      const scroller = findScrollContainer(root);
      try {
        if (scroller === document.scrollingElement || scroller === document.documentElement || scroller === document.body) {
          window.scrollTo({ top: 0, behavior: "auto" });
        } else {
          scroller.scrollTop = 0;
        }
      } catch (_) {}
    }
  }

  function clearPendingIfNextQuestionArrived() {
    const root = rootEl();
    if (!pendingVisual || !root) return;
    if (root.querySelector(".ep-flow-pending-visual")) return;
    const submit = root.querySelector("[data-ep-live-submit]");
    if (!submit) return;
    const label = String(root.querySelector(".ep-live-head strong")?.textContent || "");
    if (label && label !== pendingQuestionLabel) {
      pendingVisual = null;
      pendingQuestionLabel = "";
    }
  }

  function onCaptureClick(event) {
    const root = rootEl();
    const button = event.target?.closest?.("button");
    if (!root || !button || !root.contains(button)) return;
    if (button.matches("[data-ep-live-submit]")) capturePendingVisual();
  }

  function onSession(event) {
    lastSessionType = String(event?.detail?.session?.session_type || lastSessionType || "");
  }

  function reconcile() {
    if (applyPendingVisual()) {
      compactLoading();
      return;
    }
    clearPendingIfNextQuestionArrived();
    compactQuestionNotice();
    polishPlan();
    polishSkillLabels();
    compactLoading();
    syncScreenPosition();
  }

  function scheduleReconcile() {
    if (reconcileQueued) return;
    reconcileQueued = true;
    queueMicrotask(() => {
      reconcileQueued = false;
      reconcile();
    });
  }

  function onMutations() {
    const root = rootEl();
    if (!root) return;

    // These two changes are handled inside the MutationObserver microtask so an
    // intermediate loading card / inline feedback block cannot reach a painted frame.
    if (pendingVisual && !root.querySelector(".ep-flow-pending-visual") && looksLikeLoading(root)) {
      applyPendingVisual();
      return;
    }
    compactQuestionNotice();
    scheduleReconcile();
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
    observer = new MutationObserver(onMutations);
    observer.observe(root, { childList: true, subtree: true, characterData: true });
    scheduleReconcile();
    internal.interactionPolish = Object.freeze({ version: VERSION });
  }

  attach();
})();