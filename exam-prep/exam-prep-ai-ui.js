(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p304ux2";
  let observer = null;
  let languageObserver = null;
  let renderQueued = false;
  const REQUEST_TIMEOUT_MS = Math.min(30000, Math.max(50, Number(internal.aiUiRequestTimeoutMs) || 12000));

  function rootEl() {
    return document.querySelector("#exam-prep-host-root");
  }

  function currentLanguage() {
    try {
      const value = String(window.i18n?.getLang?.() || document.documentElement.lang || "ru").toLowerCase();
      return ["ru", "uz", "en"].includes(value) ? value : "ru";
    } catch (_) {
      return "ru";
    }
  }

  function copy() {
    const language = currentLanguage();
    if (language === "uz") return {
      title: "iClub AI yordamchisi",
      dashboardLabel: "AI yordamchisi",
      dashboardNote: "P1 va P5 ichida kerakli joyda yordam beradi",
      progress: "Progressimni tushuntirish",
      plan: "Nega bu keyingi qadam?",
      repeated: "Takrorlanayotgan qiyinchiliklarni tushuntirish",
      topic: "Bu mavzuni AI bilan tushuntirish",
      topicNote: "Hozirgi natijalaringizga mos, qisqa tushuntirish.",
      mistake: "Bu xatoni tushunishga yordam ber",
      outputLabel: "iClub AI",
      sourceNote: "iClub o‘quv materiallari va ilovadagi natijalaringiz asosida.",
      working: "Tushuntirish tayyorlanmoqda…",
      close: "Yopish",
      unavailable: "AI tushuntirishi hozir mavjud emas. Asosiy tayyorgarlik odatdagidek davom etadi.",
      error: "AI tushuntirishini yuklab bo‘lmadi. Keyinroq qayta urinib ko‘ring."
    };
    if (language === "en") return {
      title: "iClub AI Tutor",
      dashboardLabel: "AI Tutor",
      dashboardNote: "Available inside P1 and P5 when it is useful",
      progress: "Explain my progress",
      plan: "Why is this my next step?",
      repeated: "Explain recurring difficulties",
      topic: "Explain this topic with AI",
      topicNote: "A short explanation adapted to your current progress.",
      mistake: "Help me understand this mistake",
      outputLabel: "iClub AI",
      sourceNote: "Based on iClub learning material and your work in the app.",
      working: "Preparing your explanation…",
      close: "Close",
      unavailable: "AI explanation is unavailable right now. Your core exam preparation continues normally.",
      error: "The AI explanation could not be loaded. Try again later."
    };
    return {
      title: "ИИ-помощник iClub",
      dashboardLabel: "ИИ-помощник",
      dashboardNote: "Помогает внутри P1 и P5 именно там, где это нужно",
      progress: "Объяснить мой прогресс",
      plan: "Почему это мой следующий шаг?",
      repeated: "Объяснить повторяющиеся трудности",
      topic: "Объяснить эту тему с ИИ",
      topicNote: "Короткое объяснение с учётом вашего текущего прогресса.",
      mistake: "Помочь понять эту ошибку",
      outputLabel: "iClub AI",
      sourceNote: "Основано на учебных материалах iClub и вашей работе в приложении.",
      working: "Готовим объяснение…",
      close: "Закрыть",
      unavailable: "Объяснение ИИ сейчас недоступно. Основная подготовка продолжает работать как обычно.",
      error: "Не удалось загрузить объяснение ИИ. Попробуйте позже."
    };
  }

  function canShow() {
    const caps = internal.lastCapabilities;
    return Boolean(
      caps &&
      caps.coreAccess === true &&
      caps.aiAssist === true &&
      caps.killSwitch === false &&
      caps.rolloutState !== "off"
    );
  }


  function isProtectedAssessment(root) {
    return Boolean(root?.querySelector("[data-ep-live-active-assessment]"));
  }

  function outputMarkup() {
    return `
      <div class="ep-ai-output" data-ep-ai-output role="status" aria-live="polite" hidden>
        <div class="ep-ai-output-head"><strong data-ep-ai-output-label></strong></div>
        <div data-ep-ai-output-text></div>
        <div class="ep-ai-output-note" data-ep-ai-output-note></div>
        <button class="ep-ai-output-close" type="button" data-ep-ai-close></button>
      </div>`;
  }

  function buildDashboardStatus() {
    const c = copy();
    const status = document.createElement("div");
    status.className = "ep-ai-dashboard-status";
    status.setAttribute("data-ep-ai-dashboard-status", "");
    status.setAttribute("aria-label", c.title);
    status.innerHTML = `
      <span class="ep-ai-spark ep-ai-spark-compact" aria-hidden="true">✦</span>
      <span class="ep-ai-dashboard-copy"><strong></strong><small></small></span>`;
    status.querySelector("strong").textContent = c.dashboardLabel;
    status.querySelector("small").textContent = c.dashboardNote;
    return status;
  }

  function renderDashboardStatus(root) {
    const intro = root.querySelector(".ep-live-dashboard-intro");
    const grid = root.querySelector(".ep-live-grid");
    if (!intro || !grid) {
      root.querySelectorAll("[data-ep-ai-dashboard-status]").forEach(node => node.remove());
      return;
    }
    if (!intro.querySelector("[data-ep-ai-dashboard-status]")) {
      intro.appendChild(buildDashboardStatus());
    }
  }

  function buildContextAction(component, interactionType, label, tone = "default") {
    const c = copy();
    const wrap = document.createElement("div");
    wrap.className = `ep-ai-context ep-ai-context-${tone}`;
    wrap.setAttribute("data-ep-ai-context-action", interactionType);
    wrap.innerHTML = `
      <button class="ep-ai-context-btn" type="button" data-ep-ai-action="${interactionType}">
        <span class="ep-ai-context-icon" aria-hidden="true">✦</span>
        <span data-ep-ai-context-label></span>
      </button>
      ${outputMarkup()}`;
    wrap.querySelector("[data-ep-ai-context-label]").textContent = label;
    applyOutputCopy(wrap, c);
    wrap.querySelector("[data-ep-ai-action]")?.addEventListener("click", () => invoke(wrap, component, interactionType));
    wrap.querySelector("[data-ep-ai-close]")?.addEventListener("click", () => hideOutput(wrap));
    return wrap;
  }

  function renderComponentContextActions(root) {
    const home = root.querySelector("[data-ep-component-home]");
    if (!home) {
      root.querySelectorAll("[data-ep-ai-context-action]").forEach(node => node.remove());
      return;
    }
    const component = String(home.getAttribute("data-ep-component-home") || "").toUpperCase();
    if (!["P1", "P5"].includes(component)) return;
    const c = copy();

    const next = home.querySelector(".ep-component-next");
    const planAvailable = home.getAttribute("data-ep-ai-plan-available") === "true";
    if (next && planAvailable && !next.querySelector('[data-ep-ai-context-action="weekly_plan_narration"]')) {
      next.appendChild(buildContextAction(component, "weekly_plan_narration", c.plan, "next"));
    }

    const progress = home.querySelector(".ep-component-progress-card");
    if (progress && !progress.querySelector('[data-ep-ai-context-action="progress_summary"]')) {
      progress.appendChild(buildContextAction(component, "progress_summary", c.progress, "progress"));
    }

    const repeatedAvailable = home.getAttribute("data-ep-ai-repeated-available") === "true";
    const correctionLink = home.querySelector('[data-ep-component-link="corrections"]');
    if (repeatedAvailable && correctionLink && !home.querySelector('[data-ep-ai-context-action="repeated_error_summary"]')) {
      correctionLink.insertAdjacentElement("afterend", buildContextAction(component, "repeated_error_summary", c.repeated, "repeated"));
    }
  }

  function removeContextActions() {
    document.querySelectorAll("[data-ep-ai-context-action]").forEach(node => node.remove());
  }

  function setBusy(panel, busy) {
    panel.dataset.epAiBusy = busy ? "true" : "false";
    panel.querySelectorAll("[data-ep-ai-action]").forEach(button => {
      button.disabled = busy;
    });
  }

  function formatMathText(value) {
    return String(value || "")
      .replace(/\^2\b/g, "²")
      .replace(/\^3\b/g, "³");
  }

  function showOutput(panel, message) {
    const output = panel.querySelector("[data-ep-ai-output]");
    const text = panel.querySelector("[data-ep-ai-output-text]");
    if (!output || !text) return;
    text.textContent = formatMathText(message);
    output.hidden = false;
  }

  function applyOutputCopy(container, c) {
    const label = container.querySelector("[data-ep-ai-output-label]");
    const note = container.querySelector("[data-ep-ai-output-note]");
    const close = container.querySelector("[data-ep-ai-close]");
    if (label) label.textContent = c.outputLabel;
    if (note) note.textContent = c.sourceNote;
    if (close) close.textContent = c.close;
  }

  function hideOutput(panel) {
    const output = panel.querySelector("[data-ep-ai-output]");
    if (output) output.hidden = true;
  }

  async function invoke(panel, component, interactionType, extraBody = {}) {
    if (panel.dataset.epAiBusy === "true") return;
    if (!canShow()) {
      queueRender();
      return;
    }
    const c = copy();
    const client = window.sb;
    if (!client?.functions || typeof client.functions.invoke !== "function") {
      showOutput(panel, c.unavailable);
      return;
    }

    setBusy(panel, true);
    showOutput(panel, c.working);
    try {
      const request = client.functions.invoke("exam-prep-ai", {
        body: {
          ...extraBody,
          component_code: component,
          interaction_type: interactionType,
          locale: currentLanguage(),
          user_text: ""
        }
      });
      const result = await Promise.race([
        request,
        new Promise(resolve => setTimeout(() => resolve({ __epAiTimedOut: true }), REQUEST_TIMEOUT_MS))
      ]);
      if (result?.__epAiTimedOut === true) {
        showOutput(panel, c.unavailable);
        return;
      }
      const { data, error } = result || {};
      if (error) {
        showOutput(panel, c.error);
        return;
      }
      if (!canShow()) {
        queueRender();
        return;
      }
      if (data && typeof data === "object" && data.academic_state_changed !== false) {
        showOutput(panel, c.unavailable);
        return;
      }
      const message = data && typeof data === "object"
        ? String(data.message || data.content || "")
        : "";
      showOutput(panel, message || c.unavailable);
    } catch (_) {
      showOutput(panel, c.error);
    } finally {
      setBusy(panel, false);
    }
  }

  function removeErrorActions() {
    document.querySelectorAll("[data-ep-ai-error-action-wrap]").forEach(node => node.remove());
  }

  function removeTopicActions() {
    document.querySelectorAll("[data-ep-ai-topic-action-wrap]").forEach(node => node.remove());
  }

  function buildErrorAction(item) {
    const c = copy();
    const screen = item.closest("[data-ep-session-result]");
    if (!screen || screen.getAttribute("data-ep-result-session-type") !== "diagnostic") return null;
    const component = String(screen.getAttribute("data-ep-result-component") || "").toUpperCase();
    const sessionId = String(screen.getAttribute("data-ep-session-result") || "");
    const itemOrder = Number(item.getAttribute("data-ep-result-item-order") || 0);
    if (!["P1","P5"].includes(component) || !sessionId || !Number.isInteger(itemOrder) || itemOrder < 1) return null;

    const wrap = document.createElement("div");
    wrap.className = "ep-ai-inline ep-ai-error";
    wrap.setAttribute("data-ep-ai-error-action-wrap", "");
    wrap.innerHTML = `
      <button class="ep-ai-context-btn" type="button" data-ep-ai-action="established_error_explanation">
        <span class="ep-ai-context-icon" aria-hidden="true">✦</span>
        <span data-ep-ai-context-label></span>
      </button>
      ${outputMarkup()}`;
    wrap.querySelector("[data-ep-ai-context-label]").textContent = c.mistake;
    applyOutputCopy(wrap, c);
    wrap.querySelector("[data-ep-ai-action]")?.addEventListener("click", () => invoke(
      wrap,
      component,
      "established_error_explanation",
      { session_id: sessionId, item_order: itemOrder }
    ));
    wrap.querySelector("[data-ep-ai-close]")?.addEventListener("click", () => hideOutput(wrap));
    return wrap;
  }

  function renderErrorActions(root) {
    root.querySelectorAll('[data-ep-session-result][data-ep-result-session-type="diagnostic"] .ep-result-item.is-wrong[data-ep-result-item-order]').forEach(item => {
      if (item.querySelector("[data-ep-ai-error-action-wrap]")) return;
      const action = buildErrorAction(item);
      if (action) item.appendChild(action);
    });
    root.querySelectorAll("[data-ep-ai-error-action-wrap]").forEach(action => {
      const item = action.closest('.ep-result-item.is-wrong[data-ep-result-item-order]');
      const screen = action.closest('[data-ep-session-result][data-ep-result-session-type="diagnostic"]');
      if (!item || !screen) action.remove();
    });
  }

  function buildTopicAction(screen) {
    const c = copy();
    const component = String(screen.getAttribute("data-ep-ai-skill-component") || "").toUpperCase();
    const skillCode = String(screen.getAttribute("data-ep-ai-skill-detail") || "");
    const knownTitle = String(internal.learnerCopy?.skillTitle?.(skillCode, currentLanguage()) || "");
    if (!["P1","P5"].includes(component) || !skillCode.startsWith(component + "-") || !knownTitle) return null;

    const wrap = document.createElement("div");
    wrap.className = "ep-ai-inline ep-ai-topic";
    wrap.setAttribute("data-ep-ai-topic-action-wrap", "");
    wrap.innerHTML = `
      <button class="ep-ai-context-btn ep-ai-topic-btn" type="button" data-ep-ai-action="theory_explanation">
        <span class="ep-ai-context-icon" aria-hidden="true">✦</span>
        <span class="ep-ai-topic-copy"><strong data-ep-ai-context-label></strong><small data-ep-ai-topic-note></small></span>
      </button>
      ${outputMarkup()}`;
    wrap.querySelector("[data-ep-ai-context-label]").textContent = c.topic;
    wrap.querySelector("[data-ep-ai-topic-note]").textContent = c.topicNote;
    applyOutputCopy(wrap, c);
    wrap.querySelector("[data-ep-ai-action]")?.addEventListener("click", () => invoke(
      wrap,
      component,
      "theory_explanation",
      { skill_code: skillCode }
    ));
    wrap.querySelector("[data-ep-ai-close]")?.addEventListener("click", () => hideOutput(wrap));
    return wrap;
  }

  function renderTopicActions(root) {
    root.querySelectorAll("[data-ep-ai-skill-detail][data-ep-ai-skill-component]").forEach(screen => {
      if (screen.querySelector("[data-ep-ai-topic-action-wrap]")) return;
      const action = buildTopicAction(screen);
      if (!action) return;
      const firstSummary = screen.querySelector(".ep-views-summary");
      if (firstSummary) firstSummary.insertAdjacentElement("beforebegin", action);
      else screen.appendChild(action);
    });
    root.querySelectorAll("[data-ep-ai-topic-action-wrap]").forEach(action => {
      const screen = action.closest("[data-ep-ai-skill-detail][data-ep-ai-skill-component]");
      if (!screen) action.remove();
    });
  }

  function render() {
    renderQueued = false;
    const root = rootEl();
    if (!root || root.hidden || !canShow() || isProtectedAssessment(root)) {
      root?.querySelectorAll("[data-ep-ai-dashboard-status]").forEach(node => node.remove());
      removeContextActions();
      removeErrorActions();
      removeTopicActions();
      return;
    }

    renderDashboardStatus(root);
    renderComponentContextActions(root);
    renderErrorActions(root);
    renderTopicActions(root);
  }

  function queueRender() {
    if (renderQueued) return;
    renderQueued = true;
    queueMicrotask(render);
  }

  function attach() {
    const root = rootEl();
    if (!root) {
      setTimeout(attach, 50);
      return;
    }
    if (observer) observer.disconnect();
    observer = new MutationObserver(queueRender);
    observer.observe(root, { childList: true, subtree: true, attributes: true, attributeFilter: ["hidden", "aria-hidden"] });

    if (languageObserver) languageObserver.disconnect();
    languageObserver = new MutationObserver(() => {
      rootEl()?.querySelectorAll("[data-ep-ai-dashboard-status]").forEach(node => node.remove());
      removeContextActions();
      removeErrorActions();
      removeTopicActions();
      queueRender();
    });
    languageObserver.observe(document.documentElement, { attributes: true, attributeFilter: ["lang"] });
    queueRender();
  }

  window.addEventListener("iclub:exam-prep-capabilities", queueRender);

  internal.aiUiVersion = VERSION;
  attach();
})();
