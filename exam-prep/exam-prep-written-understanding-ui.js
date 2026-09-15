(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const MARKER = "written-understanding-v1";
  if (window.__iclubExamPrepWrittenUnderstanding === MARKER) return;
  window.__iclubExamPrepWrittenUnderstanding = MARKER;

  const state = { session: null, language: "ru", apiWrapped: false };

  function lang(value) {
    const v = String(value || "ru").toLowerCase();
    return ["ru", "uz", "en"].includes(v) ? v : "ru";
  }

  function copy(language = state.language) {
    const l = lang(language);
    if (l === "uz") return {
      title: "Tushunishni tekshiring",
      help: "Qisqa savollar matematik asosni tekshiradi. Keyin yechimingizni o‘z so‘zlaringiz bilan yozing.",
      item: "Savol",
      incomplete: "Avval tushunishni tekshirishdagi barcha savollarga javob bering.",
      result: "Tushunish tekshiruvi"
    };
    if (l === "en") return {
      title: "Check your understanding",
      help: "These short questions check the mathematical idea. Then explain your solution in your own words.",
      item: "Check",
      incomplete: "Answer all understanding checks before submitting your explanation.",
      result: "Understanding check"
    };
    return {
      title: "Проверьте понимание",
      help: "Короткие вопросы проверяют математическую основу. Затем объясните решение своими словами.",
      item: "Пункт",
      incomplete: "Сначала ответьте на все пункты проверки понимания.",
      result: "Проверка понимания"
    };
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function sessionItem(sessionId, itemOrder) {
    if (!state.session || String(state.session.session_id || "") !== String(sessionId || "")) return null;
    const items = Array.isArray(state.session.items) ? state.session.items : [];
    return items.find(item => Number(item?.item_order) === Number(itemOrder)) || null;
  }

  function currentWrittenItem() {
    const root = document.querySelector("#exam-prep-host-root");
    if (!root?.querySelector('textarea[name="ep_live_written_answer"]')) return null;
    const items = Array.isArray(state.session?.items) ? state.session.items : [];
    return items.find(item => item?.item_kind === "written" && item?.answered !== true) || null;
  }

  function checksFor(item) {
    return Array.isArray(item?.understanding_checks) ? item.understanding_checks.filter(Boolean) : [];
  }

  function collectAnswers(item) {
    const root = document.querySelector("#exam-prep-host-root");
    if (!root) return null;
    const checks = checksFor(item);
    if (!checks.length) return [];
    const answers = [];
    for (const check of checks) {
      const order = Number(check.check_order);
      const chosen = root.querySelector(`input[name="ep_written_understanding_${order}"]:checked`);
      if (!chosen) return null;
      answers.push({ check_order: order, picked_index: Number(chosen.value) });
    }
    return answers;
  }

  function renderChecks() {
    const root = document.querySelector("#exam-prep-host-root");
    const textarea = root?.querySelector('textarea[name="ep_live_written_answer"]');
    if (!root || !textarea || root.querySelector("[data-ep-written-understanding]")) return;
    const item = currentWrittenItem();
    const checks = checksFor(item);
    if (!checks.length) return;

    const c = copy();
    const wrapper = document.createElement("div");
    wrapper.setAttribute("data-ep-written-understanding", "true");
    wrapper.className = "ep-live-written-understanding";
    wrapper.innerHTML = `<div class="ep-live-notice"><strong>${esc(c.title)}</strong><div class="ep-live-meta">${esc(c.help)}</div></div>${checks.map((check, index) => {
      const order = Number(check.check_order);
      const options = Array.isArray(check.options) ? check.options : [];
      return `<div class="ep-live-field" data-ep-written-understanding-check="${order}"><span><strong>${esc(c.item)} ${index + 1}</strong></span><div class="ep-live-qtext">${esc(check.prompt || "")}</div><div class="ep-live-options">${options.map((option, optionIndex) => `<label class="ep-live-option"><input type="radio" name="ep_written_understanding_${order}" value="${optionIndex}"><span>${esc(option)}</span></label>`).join("")}</div></div>`;
    }).join("")}<div class="ep-live-error" data-ep-written-understanding-error hidden role="alert" aria-live="assertive"></div>`;

    const label = textarea.closest("label") || textarea;
    label.parentNode?.insertBefore(wrapper, label);
  }

  function showIncomplete() {
    const error = document.querySelector("#exam-prep-host-root [data-ep-written-understanding-error]");
    if (!error) return;
    error.textContent = copy().incomplete;
    error.hidden = false;
  }

  function formatFeedback(check) {
    if (!check?.submitted) return "";
    const c = copy();
    const total = Number(check.total || 0);
    const correct = Number(check.correct || 0);
    const missed = Array.isArray(check.results)
      ? check.results.filter(row => row?.is_correct === false && row?.rationale).map(row => String(row.rationale))
      : [];
    return [`${c.result}: ${correct}/${total}`, ...missed].filter(Boolean).join(". ");
  }

  function wrapApi() {
    if (state.apiWrapped) return;
    const base = internal.api;
    if (!base || typeof base.getSession !== "function" || typeof base.submitResponse !== "function") {
      setTimeout(wrapApi, 25);
      return;
    }

    const getSession = base.getSession.bind(base);
    const submitResponse = base.submitResponse.bind(base);
    const next = { ...base };

    next.getSession = async (sessionId, language = "en") => {
      state.language = lang(language);
      const result = await getSession(sessionId, language);
      if (result?.ok && result.data) state.session = result.data;
      queueMicrotask(renderChecks);
      return result;
    };

    next.submitResponse = async (sessionId, itemOrder, payload, idempotencyKey, elapsedMs = null, language = "en") => {
      state.language = lang(language);
      const item = sessionItem(sessionId, itemOrder);
      let outgoing = payload && typeof payload === "object" ? { ...payload } : {};
      if (item?.item_kind === "written" && checksFor(item).length) {
        const answers = collectAnswers(item);
        if (!answers) return Object.freeze({ ok: false, reason: "understanding_checks_incomplete", error: null });
        outgoing = { ...outgoing, understanding_checks: answers };
      }
      const result = await submitResponse(sessionId, itemOrder, outgoing, idempotencyKey, elapsedMs, language);
      if (!result?.ok || !result.data?.understanding_check?.submitted) return result;
      const explanation = formatFeedback(result.data.understanding_check);
      if (!explanation) return result;
      const data = Object.freeze({ ...result.data, explanation: [result.data.explanation, explanation].filter(Boolean).join(" — ") });
      return Object.freeze({ ...result, data });
    };

    internal.api = Object.freeze(next);
    state.apiWrapped = true;
  }

  document.addEventListener("click", event => {
    const button = event.target?.closest?.("[data-ep-live-submit]");
    if (!button) return;
    const item = currentWrittenItem();
    if (!item || !checksFor(item).length) return;
    if (collectAnswers(item)) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    showIncomplete();
  }, true);

  const observer = new MutationObserver(() => renderChecks());
  const startObserver = () => {
    const root = document.querySelector("#exam-prep-host-root");
    if (!root) { setTimeout(startObserver, 50); return; }
    observer.observe(root, { childList: true, subtree: true });
    renderChecks();
  };

  wrapApi();
  startObserver();
})();
