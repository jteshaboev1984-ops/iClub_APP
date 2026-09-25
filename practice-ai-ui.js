(() => {
  "use strict";

  const capabilityCache = new Map();
  let renderQueued = false;

  const COPY = {
    ru: {
      title: "Помощник по практике",
      note: "Разберу только подтверждённые данные этой практики.",
      resultAction: "Объяснить результат",
      questionAction: "Объяснить",
      working: "Готовлю объяснение…",
      unavailable: "Дополнительное объяснение сейчас недоступно.",
      close: "Скрыть"
    },
    uz: {
      title: "Amaliyot yordamchisi",
      note: "Faqat ushbu amaliyotning tasdiqlangan ma’lumotlarini tushuntiraman.",
      resultAction: "Natijani tushuntirish",
      questionAction: "Tushuntirish",
      working: "Izoh tayyorlanmoqda…",
      unavailable: "Qo‘shimcha izoh hozir mavjud emas.",
      close: "Yopish"
    },
    en: {
      title: "Practice assistant",
      note: "I explain only the confirmed data from this Practice.",
      resultAction: "Explain my result",
      questionAction: "Explain",
      working: "Preparing an explanation…",
      unavailable: "Additional explanation is unavailable right now.",
      close: "Hide"
    }
  };

  function language() {
    const value = String(window.i18n?.getLang?.() || "ru").toLowerCase();
    return value === "uz" || value === "en" ? value : "ru";
  }

  function copy() {
    return COPY[language()] || COPY.ru;
  }

  function positiveInt(value) {
    const n = Number(value);
    return Number.isInteger(n) && n > 0 ? n : null;
  }

  function attemptIdFrom(screen) {
    return positiveInt(screen?.dataset?.practiceAiAttemptId);
  }

  function setBusy(button, busy) {
    if (!button) return;
    button.disabled = !!busy;
    button.setAttribute("aria-busy", busy ? "true" : "false");
  }

  function setOutput(output, text, hidden = false) {
    if (!output) return;
    output.textContent = String(text || "");
    output.hidden = !!hidden;
  }

  async function capabilities(attemptId) {
    const locale = language();
    const key = `${attemptId}:${locale}`;
    if (capabilityCache.has(key)) return capabilityCache.get(key);

    const promise = (async () => {
      const client = window.sb;
      if (!client?.rpc) return { enabled: false, result_summary_enabled: false, explainable_question_ids: [] };
      try {
        const { data, error } = await client.rpc("get_practice_ai_ui_context_v1", {
          p_attempt_id: attemptId,
          p_locale: locale
        });
        if (error || !data || typeof data !== "object") {
          return { enabled: false, result_summary_enabled: false, explainable_question_ids: [] };
        }
        return {
          enabled: data.enabled === true,
          result_summary_enabled: data.result_summary_enabled === true,
          explainable_question_ids: Array.isArray(data.explainable_question_ids)
            ? data.explainable_question_ids.map(positiveInt).filter(Boolean)
            : []
        };
      } catch {
        return { enabled: false, result_summary_enabled: false, explainable_question_ids: [] };
      }
    })();

    capabilityCache.set(key, promise);
    return promise;
  }

  async function invoke(button, output, body) {
    if (!button || button.disabled) return;
    const c = copy();
    const client = window.sb;
    if (!client?.functions?.invoke) {
      setOutput(output, c.unavailable);
      return;
    }

    setBusy(button, true);
    setOutput(output, c.working);
    try {
      const { data, error } = await client.functions.invoke("practice-ai", {
        body: {
          ...body,
          locale: language()
        }
      });
      if (error) {
        setOutput(output, c.unavailable);
        return;
      }
      const message = data && typeof data === "object" ? String(data.message || "") : "";
      setOutput(output, message || c.unavailable);
    } catch {
      setOutput(output, c.unavailable);
    } finally {
      setBusy(button, false);
    }
  }

  function removeResultCard(screen) {
    screen?.querySelector("[data-practice-ai-result-card]")?.remove();
  }

  function renderResultCard(screen, attemptId, caps) {
    if (!screen?.classList.contains("is-active") || !caps.enabled || !caps.result_summary_enabled) {
      removeResultCard(screen);
      return;
    }
    if (screen.querySelector("[data-practice-ai-result-card]")) return;

    const c = copy();
    const card = document.createElement("section");
    card.className = "practice-ai-card";
    card.setAttribute("data-practice-ai-result-card", "1");
    card.innerHTML = `
      <div class="practice-ai-card-head">
        <div>
          <div class="practice-ai-title"></div>
          <div class="practice-ai-note"></div>
        </div>
      </div>
      <button class="btn practice-ai-action" type="button" data-practice-ai-result-action></button>
      <div class="practice-ai-output" data-practice-ai-result-output role="status" aria-live="polite" hidden></div>
    `;
    card.querySelector(".practice-ai-title").textContent = c.title;
    card.querySelector(".practice-ai-note").textContent = c.note;
    const button = card.querySelector("[data-practice-ai-result-action]");
    const output = card.querySelector("[data-practice-ai-result-output]");
    button.textContent = c.resultAction;
    button.addEventListener("click", () => invoke(button, output, {
      interaction_type: "practice_result_summary",
      attempt_id: attemptId
    }));

    const grid = screen.querySelector(".cards-grid");
    if (grid) grid.insertAdjacentElement("beforebegin", card);
    else screen.appendChild(card);
  }

  function removeReviewControls(screen) {
    screen?.querySelectorAll("[data-practice-ai-question-control]").forEach(node => node.remove());
  }

  function renderReviewControls(screen, attemptId, caps) {
    if (!screen?.classList.contains("is-active") || !caps.enabled) {
      removeReviewControls(screen);
      return;
    }

    const allowed = new Set(caps.explainable_question_ids.map(String));
    const c = copy();

    screen.querySelectorAll("[data-practice-ai-question-id]").forEach(row => {
      const questionId = positiveInt(row.dataset.practiceAiQuestionId);
      const existing = row.querySelector("[data-practice-ai-question-control]");
      if (!questionId || !allowed.has(String(questionId))) {
        existing?.remove();
        return;
      }
      if (existing) return;

      const control = document.createElement("div");
      control.className = "practice-ai-inline";
      control.setAttribute("data-practice-ai-question-control", "1");
      control.innerHTML = `
        <button class="btn practice-ai-inline-action" type="button" data-practice-ai-question-action></button>
        <div class="practice-ai-output practice-ai-inline-output" data-practice-ai-question-output role="status" aria-live="polite" hidden></div>
      `;
      const button = control.querySelector("[data-practice-ai-question-action]");
      const output = control.querySelector("[data-practice-ai-question-output]");
      button.textContent = c.questionAction;
      button.addEventListener("click", () => invoke(button, output, {
        interaction_type: "post_answer_explanation",
        attempt_id: attemptId,
        question_id: questionId
      }));
      row.appendChild(control);
    });
  }

  async function render() {
    renderQueued = false;
    const resultScreen = document.getElementById("courses-practice-result");
    const reviewScreen = document.getElementById("courses-practice-review");

    const resultAttemptId = attemptIdFrom(resultScreen);
    if (resultAttemptId) {
      const caps = await capabilities(resultAttemptId);
      if (attemptIdFrom(resultScreen) === resultAttemptId) {
        renderResultCard(resultScreen, resultAttemptId, caps);
      }
    } else {
      removeResultCard(resultScreen);
    }

    const reviewAttemptId = attemptIdFrom(reviewScreen);
    if (reviewAttemptId) {
      const caps = await capabilities(reviewAttemptId);
      if (attemptIdFrom(reviewScreen) === reviewAttemptId) {
        renderReviewControls(reviewScreen, reviewAttemptId, caps);
      }
    } else {
      removeReviewControls(reviewScreen);
    }
  }

  function queueRender() {
    if (renderQueued) return;
    renderQueued = true;
    queueMicrotask(render);
  }

  function attach() {
    const resultScreen = document.getElementById("courses-practice-result");
    const reviewScreen = document.getElementById("courses-practice-review");
    if (!resultScreen || !reviewScreen) return;

    const observer = new MutationObserver(queueRender);
    observer.observe(resultScreen, {
      attributes: true,
      attributeFilter: ["class", "data-practice-ai-attempt-id"],
      childList: true,
      subtree: true
    });
    observer.observe(reviewScreen, {
      attributes: true,
      attributeFilter: ["class", "data-practice-ai-attempt-id"],
      childList: true,
      subtree: true
    });

    document.addEventListener("iclub:practice-ai-context-changed", queueRender);
    queueRender();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", attach, { once: true });
  } else {
    attach();
  }
})();
