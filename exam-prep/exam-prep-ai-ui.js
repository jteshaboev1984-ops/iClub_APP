(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p304ux1";
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
      note: "Natijalaringiz, rejangiz va iClub o‘quv materiallarini sodda tushuntiradi. Tekshiruv natijalarini o‘zgartirmaydi.",
      homeTitle: "iClub AI yordamchisi",
      homeNote: "AI yordamchisi Exam Prep’da mavjud. Natijalar, reja, qiyin mavzular yoki qayd etilgan xatolarni tushunish uchun P1 yoki P5 ni oching.",
      openP1: "P1 uchun ochish",
      openP5: "P5 uchun ochish",
      progress: "Nimaga ko‘proq e’tibor beray?",
      plan: "Joriy rejamni tushuntirish",
      repeated: "Takrorlanayotgan qiyinchiliklarni ko‘rib chiqish",
      topic: "Bu mavzuni tushuntirish",
      topicNote: "Bu mavzu bo‘yicha hozirgi natijalaringizga mos tushuntirish.",
      mistake: "Bu xatoni tushunishga yordam ber",
      outputLabel: "AI tushuntirishi",
      sourceNote: "iClub o‘quv materiallari va ilovadagi natijalaringiz asosida.",
      working: "Tushuntirish tayyorlanmoqda…",
      close: "Yopish",
      unavailable: "AI tushuntirishi hozir mavjud emas. Asosiy tayyorgarlik odatdagidek davom etadi.",
      error: "AI tushuntirishini yuklab bo‘lmadi. Keyinroq qayta urinib ko‘ring."
    };
    if (language === "en") return {
      title: "iClub AI Tutor",
      note: "Explains your progress, plan and iClub learning material in simpler terms. It never changes assessment results.",
      homeTitle: "iClub AI Tutor",
      homeNote: "AI Tutor is available in Exam Prep. Open P1 or P5 for help understanding your progress, plan, difficult topics or recorded mistakes.",
      openP1: "Open with P1",
      openP5: "Open with P5",
      progress: "What should I focus on?",
      plan: "Explain my current plan",
      repeated: "Review recurring difficulties",
      topic: "Explain this topic to me",
      topicNote: "A focused explanation for this skill, adapted to your current progress.",
      mistake: "Help me understand this mistake",
      outputLabel: "AI explanation",
      sourceNote: "Based on iClub learning material and your work in the app.",
      working: "Preparing your explanation…",
      close: "Close",
      unavailable: "AI explanation is unavailable right now. Your core exam preparation continues normally.",
      error: "The AI explanation could not be loaded. Try again later."
    };
    return {
      title: "ИИ-помощник iClub",
      note: "Простыми словами объясняет ваш прогресс, план и учебные материалы iClub. Результаты проверок не меняет.",
      homeTitle: "ИИ-помощник iClub",
      homeNote: "ИИ-помощник доступен в Exam Prep. Откройте P1 или P5, чтобы разобраться в прогрессе, плане, сложных темах или зафиксированных ошибках.",
      openP1: "Открыть с P1",
      openP5: "Открыть с P5",
      progress: "На чём мне сосредоточиться?",
      plan: "Объяснить мой текущий план",
      repeated: "Разобрать повторяющиеся трудности",
      topic: "Объяснить мне эту тему",
      topicNote: "Объяснение этой темы с учётом вашего текущего прогресса.",
      mistake: "Помочь понять эту ошибку",
      outputLabel: "Объяснение ИИ",
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


  function componentFromStrip(strip) {
    const value = String(strip?.getAttribute("data-ep-overview-strip") || "").toUpperCase();
    return value === "P1" || value === "P5" ? value : null;
  }

  function isProtectedAssessment(root) {
    return Boolean(root?.querySelector("[data-ep-live-active-assessment]"));
  }

  function buildHomeBanner() {
    const c = copy();
    const banner = document.createElement("section");
    banner.className = "ep-ai-home-banner";
    banner.setAttribute("data-ep-ai-home-banner", "");
    banner.setAttribute("aria-label", c.homeTitle);
    banner.innerHTML = `
      <div class="ep-ai-home-main">
        <span class="ep-ai-spark" aria-hidden="true">✦</span>
        <div class="ep-ai-home-copy">
          <div class="ep-ai-home-title"></div>
          <div class="ep-ai-home-note"></div>
        </div>
      </div>
      <div class="ep-ai-home-actions">
        <button class="ep-ai-home-btn" type="button" data-ep-ai-open-component="P1"></button>
        <button class="ep-ai-home-btn" type="button" data-ep-ai-open-component="P5"></button>
      </div>`;
    banner.querySelector(".ep-ai-home-title").textContent = c.homeTitle;
    banner.querySelector(".ep-ai-home-note").textContent = c.homeNote;
    banner.querySelector('[data-ep-ai-open-component="P1"]').textContent = c.openP1;
    banner.querySelector('[data-ep-ai-open-component="P5"]').textContent = c.openP5;
    banner.querySelectorAll("[data-ep-ai-open-component]").forEach(button => {
      button.addEventListener("click", () => {
        const component = button.getAttribute("data-ep-ai-open-component");
        const target = rootEl()?.querySelector(`[data-ep-live-open-component="${component}"]`);
        if (target instanceof HTMLElement) target.click();
      });
    });
    return banner;
  }

  function renderHomeBanner(root) {
    const intro = root.querySelector(".ep-live-dashboard-intro");
    const grid = root.querySelector(".ep-live-grid");
    if (!intro || !grid) {
      root.querySelectorAll("[data-ep-ai-home-banner]").forEach(node => node.remove());
      return;
    }
    if (!root.querySelector("[data-ep-ai-home-banner]")) {
      intro.insertAdjacentElement("afterend", buildHomeBanner());
    }
  }

  function renderComponentHomePanel(root) {
    const home = root.querySelector("[data-ep-component-home]");
    if (!home) return false;
    const component = String(home.getAttribute("data-ep-component-home") || "").toUpperCase();
    if (!["P1", "P5"].includes(component)) return false;
    const existing = root.querySelector(`[data-ep-ai-panel="${component}"]`);
    if (!existing) {
      const mount = home.querySelector(".ep-component-next") || home.querySelector(".ep-component-hero");
      const panel = buildPanel(component, {
        planAvailable: home.getAttribute("data-ep-ai-plan-available") === "true",
        repeatedAvailable: home.getAttribute("data-ep-ai-repeated-available") === "true"
      });
      panel.classList.add("ep-ai-panel-featured");
      if (mount) mount.insertAdjacentElement("afterend", panel);
      else home.prepend(panel);
    }
    root.querySelectorAll("[data-ep-ai-panel]").forEach(panel => {
      if (panel.getAttribute("data-ep-ai-panel") !== component) panel.remove();
    });
    return true;
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

  function buildPanel(component, options = {}) {
    const c = copy();
    const panel = document.createElement("section");
    panel.className = "ep-ai-panel";
    panel.setAttribute("data-ep-ai-panel", component);
    panel.setAttribute("aria-label", c.title);
    panel.innerHTML = `
      <div class="ep-ai-panel-head"><span class="ep-ai-spark" aria-hidden="true">✦</span><div class="ep-ai-panel-copy">
        <div class="ep-ai-panel-title"></div>
        <div class="ep-ai-panel-note"></div></div>
      </div>
      <div class="ep-ai-actions">
        <button class="ep-ai-btn" type="button" data-ep-ai-action="progress_summary"></button>
        <button class="ep-ai-btn" type="button" data-ep-ai-action="weekly_plan_narration"></button>
        <button class="ep-ai-btn" type="button" data-ep-ai-action="repeated_error_summary"></button>
      </div>
      <div class="ep-ai-output" data-ep-ai-output role="status" aria-live="polite" hidden>
        <div class="ep-ai-output-head"><strong data-ep-ai-output-label></strong></div>
        <div data-ep-ai-output-text></div>
        <div class="ep-ai-output-note" data-ep-ai-output-note></div>
        <button class="ep-ai-output-close" type="button" data-ep-ai-close></button>
      </div>`;

    panel.querySelector(".ep-ai-panel-title").textContent = c.title;
    panel.querySelector(".ep-ai-panel-note").textContent = c.note;
    panel.querySelector('[data-ep-ai-action="progress_summary"]').textContent = c.progress;
    panel.querySelector('[data-ep-ai-action="weekly_plan_narration"]').textContent = c.plan;
    panel.querySelector('[data-ep-ai-action="repeated_error_summary"]').textContent = c.repeated;
    if (options.planAvailable === false) {
      panel.querySelector('[data-ep-ai-action="weekly_plan_narration"]')?.setAttribute("hidden", "");
    }
    if (options.repeatedAvailable === false) {
      panel.querySelector('[data-ep-ai-action="repeated_error_summary"]')?.setAttribute("hidden", "");
    }
    applyOutputCopy(panel, c);

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
        <div class="ep-ai-output-head"><strong data-ep-ai-output-label></strong></div>
        <div data-ep-ai-output-text></div>
        <div class="ep-ai-output-note" data-ep-ai-output-note></div>
        <button class="ep-ai-output-close" type="button" data-ep-ai-close></button>
      </div>`;
    wrap.querySelector("[data-ep-ai-action]").textContent = c.mistake;
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
      <div class="ep-ai-topic-head">
        <span class="ep-ai-spark" aria-hidden="true">✦</span>
        <div><strong data-ep-ai-topic-title></strong><span data-ep-ai-topic-note></span></div>
      </div>
      <button class="ep-ai-btn ep-ai-inline-btn" type="button" data-ep-ai-action="theory_explanation"></button>
      <div class="ep-ai-output ep-ai-inline-output" data-ep-ai-output role="status" aria-live="polite" hidden>
        <div class="ep-ai-output-head"><strong data-ep-ai-output-label></strong></div>
        <div data-ep-ai-output-text></div>
        <div class="ep-ai-output-note" data-ep-ai-output-note></div>
        <button class="ep-ai-output-close" type="button" data-ep-ai-close></button>
      </div>`;
    wrap.querySelector("[data-ep-ai-topic-title]").textContent = c.title;
    wrap.querySelector("[data-ep-ai-topic-note]").textContent = c.topicNote;
    wrap.querySelector("[data-ep-ai-action]").textContent = c.topic;
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
      root?.querySelectorAll("[data-ep-ai-home-banner]").forEach(node => node.remove());
      removePanels();
      removeErrorActions();
      removeTopicActions();
      return;
    }

    renderHomeBanner(root);

    const componentHomeMounted = renderComponentHomePanel(root);
    if (!componentHomeMounted) {
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

    if (languageObserver) languageObserver.disconnect();
    languageObserver = new MutationObserver(() => {
      rootEl()?.querySelectorAll("[data-ep-ai-home-banner]").forEach(node => node.remove());
      removePanels();
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
