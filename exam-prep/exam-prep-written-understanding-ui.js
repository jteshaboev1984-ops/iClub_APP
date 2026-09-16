(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const MARKER = "written-understanding-v1";
  if (window.__iclubExamPrepWrittenUnderstanding === MARKER) return;
  window.__iclubExamPrepWrittenUnderstanding = MARKER;

  const state = {
    session: null,
    language: "ru",
    apiWrapped: false,
    pendingFeedback: null,
    feedbackFinalized: false,
    pendingAnswers: null
  };

  function lang(value) {
    const v = String(value || "ru").toLowerCase();
    return ["ru", "uz", "en"].includes(v) ? v : "ru";
  }

  function copy(language = state.language) {
    const l = lang(language);
    if (l === "uz") return {
      title: "Tushunishni tekshiring",
      helpOne: "Qisqa savolga javob bering, keyin yechimingizni o‘z so‘zlaringiz bilan tushuntiring.",
      helpMany: "Qisqa savollarga javob bering, keyin yechimingizni o‘z so‘zlaringiz bilan tushuntiring.",
      item: "Savol",
      incompleteOne: "Avval qisqa savolga javob bering.",
      incompleteMany: "Avval barcha qisqa savollarga javob bering.",
      result: "Tushunish tekshiruvi"
    };
    if (l === "en") return {
      title: "Check your understanding",
      helpOne: "Answer the short question, then explain your solution in your own words.",
      helpMany: "Answer the short questions, then explain your solution in your own words.",
      item: "Check",
      incompleteOne: "Answer the short question first.",
      incompleteMany: "Answer all short questions first.",
      result: "Understanding check"
    };
    return {
      title: "Проверьте понимание",
      helpOne: "Ответьте на короткий вопрос, затем объясните решение своими словами.",
      helpMany: "Ответьте на короткие вопросы, затем объясните решение своими словами.",
      item: "Пункт",
      incompleteOne: "Сначала ответьте на короткий вопрос.",
      incompleteMany: "Сначала ответьте на все короткие вопросы.",
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
      const answer = { check_order: order, picked_index: Number(chosen.value) };
      const version = String(check?.check_version || "").trim();
      if (version) answer.check_version = version;
      answers.push(answer);
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
    const single = checks.length === 1;
    const wrapper = document.createElement("div");
    wrapper.setAttribute("data-ep-written-understanding", "true");
    wrapper.className = "ep-live-written-understanding";
    wrapper.innerHTML = `<div class="ep-live-notice"><strong>${esc(c.title)}</strong><div class="ep-live-meta">${esc(single ? c.helpOne : c.helpMany)}</div></div>${checks.map((check, index) => {
      const order = Number(check.check_order);
      const options = Array.isArray(check.options) ? check.options : [];
      const itemLabel = single ? "" : `<span><strong>${esc(c.item)} ${index + 1}</strong></span>`;
      return `<div class="ep-live-field" data-ep-written-understanding-check="${order}">${itemLabel}<div class="ep-live-qtext">${esc(check.prompt || "")}</div><div class="ep-live-options">${options.map((option, optionIndex) => `<label class="ep-live-option"><input type="radio" name="ep_written_understanding_${order}" value="${optionIndex}"><span>${esc(option)}</span></label>`).join("")}</div></div>`;
    }).join("")}<div class="ep-live-error" data-ep-written-understanding-error hidden role="alert" aria-live="assertive"></div>`;

    const label = textarea.closest("label") || textarea;
    label.parentNode?.insertBefore(wrapper, label);
  }

  function clearPendingFeedback() {
    state.pendingFeedback = null;
    state.feedbackFinalized = false;
  }

  function renderPendingFeedback() {
    const message = state.pendingFeedback;
    if (!message) return;
    const root = document.querySelector("#exam-prep-host-root");
    if (!root) return;

    const visible = root.textContent?.includes(message) === true;
    if (!state.feedbackFinalized) {
      if (visible && root.querySelector("[data-ep-live-submit]")) {
        const hasUnanswered = Array.isArray(state.session?.items)
          && state.session.items.some(item => item?.answered !== true);
        if (hasUnanswered) clearPendingFeedback();
      }
      return;
    }

    const stable = root.querySelector('[data-ep-live-plan-item], .ep-live-dashboard-intro, [data-ep-live-back-timed]');
    if (!stable) return;
    if (visible) {
      clearPendingFeedback();
      return;
    }
    if (root.querySelector("[data-ep-written-understanding-feedback]")) return;

    const shell = root.querySelector(".ep-host-shell");
    const head = shell?.querySelector(".ep-live-head");
    if (!shell) return;
    const notice = document.createElement("div");
    notice.className = "ep-live-notice";
    notice.setAttribute("data-ep-written-understanding-feedback", "true");
    notice.setAttribute("role", "status");
    notice.setAttribute("aria-live", "polite");
    notice.textContent = message;
    if (head?.nextSibling) shell.insertBefore(notice, head.nextSibling); else shell.appendChild(notice);
    clearPendingFeedback();
  }

  function showIncomplete() {
    const error = document.querySelector("#exam-prep-host-root [data-ep-written-understanding-error]");
    if (!error) return;
    const c = copy();
    const single = checksFor(currentWrittenItem()).length === 1;
    error.textContent = single ? c.incompleteOne : c.incompleteMany;
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

  function wrappedAnswers(sessionId, itemOrder, item) {
    const cached = state.pendingAnswers;
    if (cached
      && String(cached.sessionId || "") === String(sessionId || "")
      && Number(cached.itemOrder) === Number(itemOrder)) {
      return cached.answers;
    }
    return collectAnswers(item);
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
    const finalizeSession = typeof base.finalizeSession === "function" ? base.finalizeSession.bind(base) : null;
    const next = { ...base };

    next.getSession = async (sessionId, language = "en") => {
      state.language = lang(language);
      const result = await getSession(sessionId, language);
      if (result?.ok && result.data) state.session = result.data;
      queueMicrotask(() => { renderChecks(); renderPendingFeedback(); });
      return result;
    };

    next.submitResponse = async (sessionId, itemOrder, payload, idempotencyKey, elapsedMs = null, language = "en") => {
      state.language = lang(language);
      const item = sessionItem(sessionId, itemOrder);
      let outgoing = payload && typeof payload === "object" ? { ...payload } : {};
      if (item?.item_kind === "written" && checksFor(item).length) {
        const answers = wrappedAnswers(sessionId, itemOrder, item);
        if (!answers) return Object.freeze({ ok: false, reason: "understanding_checks_incomplete", error: null });
        outgoing = { ...outgoing, understanding_checks: answers };
      }
      state.pendingAnswers = null;
      const result = await submitResponse(sessionId, itemOrder, outgoing, idempotencyKey, elapsedMs, language);
      if (!result?.ok || !result.data?.understanding_check?.submitted) return result;
      const explanation = formatFeedback(result.data.understanding_check);
      if (!explanation) return result;
      state.pendingFeedback = explanation;
      state.feedbackFinalized = false;
      const data = Object.freeze({ ...result.data, explanation: [result.data.explanation, explanation].filter(Boolean).join(" — ") });
      return Object.freeze({ ...result, data });
    };

    if (finalizeSession) {
      next.finalizeSession = async (sessionId, idempotencyKey) => {
        const result = await finalizeSession(sessionId, idempotencyKey);
        if (result?.ok && state.pendingFeedback) {
          state.feedbackFinalized = true;
          queueMicrotask(renderPendingFeedback);
        }
        return result;
      };
    }

    internal.api = Object.freeze(next);
    state.apiWrapped = true;
  }

  document.addEventListener("click", event => {
    const button = event.target?.closest?.("[data-ep-live-submit]");
    if (!button) return;
    const item = currentWrittenItem();
    if (!item || !checksFor(item).length) return;
    const answers = collectAnswers(item);
    if (answers) {
      state.pendingAnswers = {
        sessionId: state.session?.session_id || null,
        itemOrder: item.item_order,
        answers
      };
      return;
    }
    state.pendingAnswers = null;
    event.preventDefault();
    event.stopImmediatePropagation();
    showIncomplete();
  }, true);

  const observer = new MutationObserver(() => { renderChecks(); renderPendingFeedback(); });
  const startObserver = () => {
    const root = document.querySelector("#exam-prep-host-root");
    if (!root) { setTimeout(startObserver, 50); return; }
    observer.observe(root, { childList: true, subtree: true });
    renderChecks();
    renderPendingFeedback();
  };

  wrapApi();
  startObserver();
})();
