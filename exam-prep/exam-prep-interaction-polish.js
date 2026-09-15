(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "polish1";
  let observer = null;
  let reconcileTimer = null;
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

  function planVisible() {
    const root = rootEl();
    return Boolean(root?.querySelector(".ep-live-plan-item"));
  }

  function polishPlan() {
    const root = rootEl();
    if (!root || !planVisible()) return;
    const card = root.querySelector(".ep-live-card:has(.ep-live-plan-item)") || root.querySelector(".ep-live-card");
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
      node.textContent = humanizeRu(node.textContent);
    });
    root.querySelectorAll(".ep-flow-task-meta").forEach(node => {
      const parts = String(node.textContent || "").split(" · ").filter(Boolean);
      node.textContent = humanizeRu(parts[0] || "");
    });
  }

  function polishSkillLabels() {
    const root = rootEl();
    if (!root) return;
    root.querySelectorAll(".ep-flow-task-name, .ep-flow-correction-title, .ep-flow-completion-skill strong, [data-ep-views-skill] strong").forEach(node => {
      node.textContent = humanizeRu(node.textContent);
    });

    root.querySelectorAll("[data-ep-views-skill] .ep-views-skill-meta").forEach(node => {
      const cleaned = String(node.textContent || "")
        .replace(/\s*·\s*(Навык|Skill|Ko‘nikma)\s+\d+/gi, "")
        .replace(/^\s*·\s*/, " · ");
      node.textContent = cleaned;
    });

    root.querySelectorAll(".ep-flow-completion-skill > span").forEach(node => {
      node.textContent = copy().topic;
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

  function capturePendingVisual() {
    const root = rootEl();
    if (!root) return;
    const screen = root.firstElementChild;
    const submit = root.querySelector("[data-ep-live-submit]");
    if (!screen || !submit) return;
    pendingVisual = screen.cloneNode(true);
    pendingVisual.classList.add("ep-flow-pending-visual");
    pendingQuestionLabel = String(root.querySelector(".ep-live-head strong")?.textContent || "");
  }

  function applyPendingVisual() {
    const root = rootEl();
    if (!root || !pendingVisual) return false;
    if (root.querySelector(".ep-flow-pending-visual")) return true;
    const status = root.querySelector('[role="status"]');
    const looksLoading = Boolean(status && (/Загрузка|Loading|Yuklanmoqda|Сохраняем|Saving|Saqlanmoqda/i.test(status.textContent || "") || status.querySelector(".ep-flow-loader")));
    if (!looksLoading) return false;

    const clone = pendingVisual.cloneNode(true);
    clone.classList.add("ep-flow-pending-visual");
    clone.setAttribute("aria-busy", "true");
    clone.querySelectorAll("input, textarea, select, button").forEach(node => { node.disabled = true; });
    const submit = clone.querySelector("[data-ep-live-submit]");
    if (submit) {
      submit.classList.add("ep-flow-submit-pending");
      submit.innerHTML = `<span class="ep-flow-mini-spinner" aria-hidden="true"></span><span>${copy().saving}</span>`;
    }
    clone.querySelectorAll(".ep-live-notice[role='status']").forEach(node => node.remove());
    root.replaceChildren(clone);
    return true;
  }

  function feedbackSummary(raw) {
    const c = copy();
    const text = String(raw || "").trim();
    if (lastSessionType === "diagnostic") return { title: c.saved, detail: "" };
    if (/^(Верно|Correct|To‘g‘ri)\b/i.test(text)) {
      const detail = text.split(" — ").slice(1, 2).join("").trim();
      return { title: c.correct, detail: detail.length <= 120 ? detail : "" };
    }
    if (/^(Разберите|Review this mistake|Xatoni)/i.test(text)) {
      const detail = text.split(" — ").slice(1, 2).join("").trim();
      return { title: c.incorrect, detail: detail.length <= 120 ? detail : "" };
    }
    return { title: c.saved, detail: "" };
  }

  function showToast(raw) {
    const root = rootEl();
    if (!root) return;
    const summary = feedbackSummary(raw);
    let toast = document.querySelector(".ep-flow-answer-toast");
    if (!toast) {
      toast = document.createElement("div");
      toast.className = "ep-flow-answer-toast";
      toast.setAttribute("role", "status");
      toast.setAttribute("aria-live", "polite");
      document.body.appendChild(toast);
    }
    toast.innerHTML = `<strong>${summary.title}</strong>${summary.detail ? `<span>${humanizeRu(summary.detail)}</span>` : ""}`;
    toast.classList.add("show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove("show"), summary.detail ? 2600 : 1600);
  }

  function compactQuestionNotice() {
    const root = rootEl();
    if (!root || !root.querySelector("[data-ep-live-submit]") || root.querySelector(".ep-flow-pending-visual")) return;
    const notice = root.querySelector(".ep-live-notice[role='status']");
    if (!notice) return;
    const raw = String(notice.textContent || "");
    notice.remove();
    showToast(raw);
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

  function smoothScreenEntry() {
    const root = rootEl();
    if (!root) return;
    const key = screenKey();
    if (!key || key === lastScreenKey) return;
    const previous = lastScreenKey;
    lastScreenKey = key;
    const screen = root.firstElementChild;
    if (screen) {
      screen.classList.remove("ep-flow-screen-enter");
      void screen.offsetWidth;
      screen.classList.add("ep-flow-screen-enter");
    }
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
    smoothScreenEntry();
  }

  function scheduleReconcile() {
    if (reconcileTimer) return;
    reconcileTimer = setTimeout(() => {
      reconcileTimer = null;
      reconcile();
    }, 16);
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
    observer = new MutationObserver(scheduleReconcile);
    observer.observe(root, { childList: true, subtree: true, characterData: true });
    scheduleReconcile();
    internal.interactionPolish = Object.freeze({ version: VERSION });
  }

  attach();
})();