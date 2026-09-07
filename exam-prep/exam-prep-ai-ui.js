(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p104aiui1";
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
      note: "Tasdiqlangan progress va joriy rejangizni sodda qilib tushuntiradi. Natijalaringizni o‘zgartirmaydi.",
      progress: "Progressni tushuntirish",
      plan: "Joriy rejani tushuntirish",
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

  function ensureStyle() {
    if (document.querySelector("#ep-ai-ui-style")) return;
    const style = document.createElement("style");
    style.id = "ep-ai-ui-style";
    style.textContent = `
      .ep-ai-panel{display:grid;gap:9px;margin-top:10px;padding:11px;border:1px solid rgba(127,127,127,.18);border-radius:12px;background:rgba(127,127,127,.045)}
      .ep-ai-panel-head{display:grid;gap:3px}.ep-ai-panel-title{font-size:13px;font-weight:800;line-height:1.3}.ep-ai-panel-note{font-size:11px;line-height:1.45;opacity:.74}
      .ep-ai-actions{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}.ep-ai-btn{min-height:38px;border:1px solid rgba(127,127,127,.25);border-radius:10px;padding:8px 10px;background:transparent;color:inherit;font:inherit;font-size:12px;font-weight:750;cursor:pointer}.ep-ai-btn:disabled{opacity:.55;cursor:default}
      .ep-ai-output{display:grid;gap:8px;padding:10px;border-radius:10px;background:rgba(127,127,127,.07);font-size:12px;line-height:1.5}.ep-ai-output[hidden]{display:none}.ep-ai-output-close{justify-self:start;border:0;background:transparent;color:inherit;font:inherit;font-size:11px;font-weight:750;opacity:.72;cursor:pointer;padding:0}
      @media(max-width:680px){.ep-ai-actions{grid-template-columns:1fr}.ep-ai-btn{width:100%}}
    `;
    document.head.appendChild(style);
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

  async function invoke(panel, component, interactionType) {
    if (panel.dataset.epAiBusy === "true") return;
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
      </div>
      <div class="ep-ai-output" data-ep-ai-output role="status" aria-live="polite" hidden>
        <div data-ep-ai-output-text></div>
        <button class="ep-ai-output-close" type="button" data-ep-ai-close></button>
      </div>`;

    panel.querySelector(".ep-ai-panel-title").textContent = c.title;
    panel.querySelector(".ep-ai-panel-note").textContent = c.note;
    panel.querySelector('[data-ep-ai-action="progress_summary"]').textContent = c.progress;
    panel.querySelector('[data-ep-ai-action="weekly_plan_narration"]').textContent = c.plan;
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

  function render() {
    renderQueued = false;
    const root = rootEl();
    if (!root || root.hidden || !canShow()) {
      removePanels();
      return;
    }

    const strips = Array.from(root.querySelectorAll("[data-ep-overview-strip]"));
    if (!strips.length) {
      removePanels();
      return;
    }

    ensureStyle();
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

  internal.aiUiVersion = VERSION;
  attach();
})();
