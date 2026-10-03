(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p302ux1";
  let observer = null;
  let renderQueued = false;

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
      title: "Tayyorgarlik yordamchisi",
      note: "Tasdiqlangan natijalaringiz va joriy rejangizni sodda qilib tushuntiradi. Natijalaringizni o‘zgartirmaydi.",
      progress: "Natijalarimni tushuntirish",
      plan: "Joriy rejani tushuntirish",
      repeated: "Takroriy qiyinchiliklarni tushuntirish",
      topic: "Bu mavzuni tushuntirish",
      mistake: "Bu xatoni tushuntirish",
      working: "Tayyorlanmoqda…",
      close: "Yopish",
      unavailable: "Qo‘shimcha tushuntirish hozir mavjud emas. Asosiy tayyorgarlik odatdagidek davom etadi.",
      error: "Tushuntirishni yuklab bo‘lmadi. Keyinroq qayta urinib ko‘ring."
    };
    if (language === "en") return {
      title: "Study assistant",
      note: "Explains your confirmed progress and current plan in simpler terms. It does not change your results.",
      progress: "Explain my progress",
      plan: "Explain my current plan",
      repeated: "Explain repeated difficulties",
      topic: "Explain this topic",
      mistake: "Explain this mistake",
      working: "Preparing…",
      close: "Close",
      unavailable: "Extra explanation is unavailable right now. Your core exam preparation continues normally.",
      error: "The explanation could not be loaded. Try again later."
    };
    return {
      title: "Помощник по подготовке",
      note: "Объясняет подтверждённый прогресс и текущий план простыми словами. Ваши результаты он не меняет.",
      progress: "Объяснить мой прогресс",
      plan: "Объяснить текущий план",
      repeated: "Объяснить повторяющиеся трудности",
      topic: "Объяснить эту тему",
      mistake: "Разобрать эту ошибку",
      working: "Готовим объяснение…",
      close: "Закрыть",
      unavailable: "Дополнительное объяснение сейчас недоступно. Основная подготовка продолжает работать как обычно.",
      error: "Не удалось загрузить объяснение. Попробуйте позже."
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


  function componentFromStrip(strip) {
    const value = String(strip?.getAttribute("data-ep-overview-strip") || "").toUpperCase();
    return value === "P1" || value === "P5" ? value : null;
  }

  function setBusy(panel, busy) {
    panel.dataset.epAiBusy = busy ? "true" : "false";
    panel.querySelectorAll("[data-ep-ai-action]").forEach(button => {
      button.disabled = busy;
    });
  }

  function showOutput(panel, message) {
    const output = panel.querySelector("[data-ep-ai-output]");
    const text = panel.querySelector("[data-ep-ai-output-text]");
    if (!output || !text) return;
    text.textContent = String(message || "");
    output.hidden = false;
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
      const { data, error } = await client.functions.invoke("exam-prep-ai", {
        body: {
          ...extraBody,
          component_code: component,
          interaction_type: interactionType,
          locale: currentLanguage(),
          user_text: ""
        }
      });
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

  function buildPanel(component) {
    const c = copy();
    const panel = document.createElement("section");
    panel.className = "ep-ai-panel";
    panel.setAttribute("data-ep-ai-panel", component);
    panel.setAttribute("aria-label", c.title);
    panel.innerHTML = `
      <div class="ep-ai-panel-head">
        <div class="ep-ai-panel-title"></div>
        <div class="ep-ai-panel-note"></div>
      </div>
      <div class="ep-ai-actions">
        <button class="ep-ai-btn" type="button" data-ep-ai-action="progress_summary"></button>
        <button class="ep-ai-btn" type="button" data-ep-ai-action="weekly_plan_narration"></button>
        <button class="ep-ai-btn" type="button" data-ep-ai-action="repeated_error_summary"></button>
      </div>
      <div class="ep-ai-output" data-ep-ai-output role="status" aria-live="polite" hidden>
        <div data-ep-ai-output-text></div>
        <button class="ep-ai-output-close" type="button" data-ep-ai-close></button>
      </div>`;

    panel.querySelector(".ep-ai-panel-title").textContent = c.title;
    panel.querySelector(".ep-ai-panel-note").textContent = c.note;
    panel.querySelector('[data-ep-ai-action="progress_summary"]').textContent = c.progress;
    panel.querySelector('[data-ep-ai-action="weekly_plan_narration"]').textContent = c.plan;
    panel.querySelector('[data-ep-ai-action="repeated_error_summary"]').textContent = c.repeated;
    panel.querySelector("[data-ep-ai-close]").textContent = c.close;

    panel.querySelectorAll("[data-ep-ai-action]").forEach(button => {
      button.addEventListener("click", () => invoke(panel, component, button.getAttribute("data-ep-ai-action")));
    });
    panel.querySelector("[data-ep-ai-close]")?.addEventListener("click", () => hideOutput(panel));
    return panel;
  }

  function removePanels() {
    document.querySelectorAll("[data-ep-ai-panel]").forEach(node => node.remove());
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
    wrap.className = "ep-ai-inline";
    wrap.setAttribute("data-ep-ai-error-action-wrap", "");
    wrap.innerHTML = `
      <button class="ep-ai-btn ep-ai-inline-btn" type="button" data-ep-ai-action="established_error_explanation"></button>
      <div class="ep-ai-output ep-ai-inline-output" data-ep-ai-output role="status" aria-live="polite" hidden>
        <div data-ep-ai-output-text></div>
        <button class="ep-ai-output-close" type="button" data-ep-ai-close></button>
      </div>`;
    wrap.querySelector("[data-ep-ai-action]").textContent = c.mistake;
    wrap.querySelector("[data-ep-ai-close]").textContent = c.close;
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
      <button class="ep-ai-btn ep-ai-inline-btn" type="button" data-ep-ai-action="theory_explanation"></button>
      <div class="ep-ai-output ep-ai-inline-output" data-ep-ai-output role="status" aria-live="polite" hidden>
        <div data-ep-ai-output-text></div>
        <button class="ep-ai-output-close" type="button" data-ep-ai-close></button>
      </div>`;
    wrap.querySelector("[data-ep-ai-action]").textContent = c.topic;
    wrap.querySelector("[data-ep-ai-close]").textContent = c.close;
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
    if (!root || root.hidden || !canShow()) {
      removePanels();
      removeErrorActions();
      removeTopicActions();
      return;
    }

    const strips = Array.from(root.querySelectorAll("[data-ep-overview-strip]"));
    if (!strips.length) {
      removePanels();
    } else {
      strips.forEach(strip => {
        const component = componentFromStrip(strip);
        if (!component) return;
        const existing = root.querySelector(`[data-ep-ai-panel="${component}"]`);
        if (existing) return;
        strip.insertAdjacentElement("afterend", buildPanel(component));
      });

      root.querySelectorAll("[data-ep-ai-panel]").forEach(panel => {
        const component = panel.getAttribute("data-ep-ai-panel");
        if (!root.querySelector(`[data-ep-overview-strip="${component}"]`)) panel.remove();
      });
    }

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
    queueRender();
  }

  window.addEventListener("iclub:exam-prep-capabilities", queueRender);

  internal.aiUiVersion = VERSION;
  attach();
})();
