(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p017live1";
  let attached = false;

  const state = {
    language: "ru",
    busy: false,
    profile: null,
    progress: { P1: null, P5: null },
    session: null,
    itemStartedAt: 0,
    notice: null
  };

  function lang(value) {
    const v = String(value || "ru").toLowerCase();
    return ["ru", "uz", "en"].includes(v) ? v : "ru";
  }

  function copy() {
    if (state.language === "uz") return {
      title: "Cambridge AS Mathematics · Exam Prep",
      safe: "Faqat server ruxsati bilan ishlaydi. Synthetic o‘quvchi ma’lumotlari yo‘q.",
      profileTitle: "Avval imtihon rejangizni kiriting",
      profileText: "Bu ma’lumotlar haftalik matematik vaqt byudjetini to‘g‘ri tuzish uchun kerak.",
      series: "Imtihon seriyasi", target: "Maqsad baho", total: "Haftalik umumiy bo‘sh vaqt (soat)", math: "Matematikaga ajratiladigan vaqt (soat)",
      save: "Saqlash va diagnosticni boshlash", saving: "Saqlanmoqda…", invalid: "Soatlarni tekshiring: matematika vaqti 0 dan katta va umumiy vaqtdan oshmasligi kerak.",
      diagnostic: "Diagnostic", items: "savol", areas: "bo‘lim", start: "Keyingi diagnosticni boshlash", resume: "Diagnosticni davom ettirish", complete: "Screening yakunlandi", route: "Yo‘nalish", loading: "Yuklanmoqda…",
      question: "Savol", submit: "Javobni yuborish", submitting: "Yuborilmoqda…", next: "Keyingi savol", correct: "To‘g‘ri", incorrect: "Tekshirish kerak", finish: "Paket yakunlandi. Keyingi diagnostic aniqlanmoqda…",
      error: "Amalni bajarib bo‘lmadi. Qayta urinib ko‘ring.", back: "Diagnosticdan chiqish", answered: "Bajarildi"
    };
    if (state.language === "en") return {
      title: "Cambridge AS Mathematics · Exam Prep",
      safe: "Server-authorized only. No synthetic learner data.",
      profileTitle: "Set your exam plan first",
      profileText: "This is used to build a realistic weekly mathematics time budget.",
      series: "Exam series", target: "Target grade", total: "Total weekly study time (hours)", math: "Mathematics budget (hours)",
      save: "Save and start diagnostic", saving: "Saving…", invalid: "Check the hours: mathematics time must be above 0 and cannot exceed total time.",
      diagnostic: "Diagnostic", items: "questions", areas: "areas", start: "Start next diagnostic", resume: "Continue diagnostic", complete: "Screening complete", route: "Route", loading: "Loading…",
      question: "Question", submit: "Submit answer", submitting: "Submitting…", next: "Next question", correct: "Correct", incorrect: "Needs review", finish: "Package complete. Finding the next diagnostic…",
      error: "The action could not be completed. Try again.", back: "Exit diagnostic", answered: "Completed"
    };
    return {
      title: "Cambridge AS Mathematics · Exam Prep",
      safe: "Работает только с серверным разрешением. Synthetic learner data не используются.",
      profileTitle: "Сначала задайте план экзамена",
      profileText: "Это нужно, чтобы система строила реалистичный недельный бюджет времени на математику.",
      series: "Экзаменационная сессия", target: "Целевая оценка", total: "Общее учебное время в неделю (часы)", math: "Бюджет на математику (часы)",
      save: "Сохранить и начать diagnostic", saving: "Сохраняем…", invalid: "Проверьте часы: время на математику должно быть больше 0 и не превышать общее время.",
      diagnostic: "Diagnostic", items: "вопросов", areas: "разделов", start: "Начать следующий diagnostic", resume: "Продолжить diagnostic", complete: "Screening завершён", route: "Маршрут", loading: "Загрузка…",
      question: "Вопрос", submit: "Отправить ответ", submitting: "Отправляем…", next: "Следующий вопрос", correct: "Верно", incorrect: "Нужно разобрать", finish: "Пакет завершён. Определяю следующий diagnostic…",
      error: "Не удалось выполнить действие. Попробуйте ещё раз.", back: "Выйти из diagnostic", answered: "Выполнено"
    };
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;").replaceAll("'", "&#039;");
  }

  function key(prefix) {
    return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
  }

  function rootEl() { return document.querySelector("#exam-prep-host-root"); }

  function canMount() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }

  function ensureStyle() {
    if (document.querySelector("#ep-live-flow-style")) return;
    const style = document.createElement("style");
    style.id = "ep-live-flow-style";
    style.textContent = `
      .ep-live{display:grid;gap:14px}.ep-live-head{display:flex;justify-content:space-between;gap:12px;align-items:flex-start}.ep-live-safe{font-size:12px;opacity:.72}
      .ep-live-card{border:1px solid rgba(127,127,127,.24);border-radius:14px;padding:14px;display:grid;gap:10px;background:rgba(127,127,127,.04)}
      .ep-live-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}.ep-live-form{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}
      .ep-live-field{display:grid;gap:5px;font-size:13px}.ep-live-field input{width:100%;box-sizing:border-box;padding:10px 11px;border:1px solid rgba(127,127,127,.35);border-radius:10px;background:transparent;color:inherit}
      .ep-live-btn{border:0;border-radius:11px;padding:10px 14px;font-weight:700;cursor:pointer;background:#111827;color:#fff}.ep-live-btn:disabled{opacity:.55;cursor:default}.ep-live-btn.secondary{background:transparent;color:inherit;border:1px solid rgba(127,127,127,.35)}
      .ep-live-progress{height:7px;border-radius:999px;background:rgba(127,127,127,.18);overflow:hidden}.ep-live-progress>span{display:block;height:100%;background:currentColor;opacity:.7}
      .ep-live-meta{font-size:12px;opacity:.72}.ep-live-options{display:grid;gap:8px}.ep-live-option{display:flex;gap:9px;align-items:flex-start;padding:10px;border:1px solid rgba(127,127,127,.25);border-radius:10px}
      .ep-live-input{width:100%;box-sizing:border-box;padding:11px;border:1px solid rgba(127,127,127,.35);border-radius:10px;background:transparent;color:inherit}.ep-live-notice{padding:10px;border-radius:10px;background:rgba(127,127,127,.1);font-size:13px}
      .ep-live-error{padding:10px;border-radius:10px;background:rgba(180,30,30,.12);font-size:13px}.ep-live-qtext{white-space:pre-wrap;line-height:1.5}.ep-live-actions{display:flex;gap:8px;flex-wrap:wrap}
      @media(max-width:680px){.ep-live-grid,.ep-live-form{grid-template-columns:1fr}.ep-live-head{display:grid}}
    `;
    document.head.appendChild(style);
  }

  function shell(body) {
    const c = copy();
    return `<section class="ep-host-shell ep-live" aria-label="${esc(c.title)}">
      <div class="ep-live-head"><div><div class="ep-host-kicker">Core beta</div><h2 class="ep-host-title">${esc(c.title)}</h2></div><div class="ep-live-safe">${esc(c.safe)}</div></div>
      ${body}
    </section>`;
  }

  function renderLoading() {
    const root = rootEl(); if (!root) return;
    root.innerHTML = shell(`<div class="ep-live-card">${esc(copy().loading)}</div>`);
  }

  function renderError(message = null) {
    const root = rootEl(); if (!root) return;
    root.innerHTML = shell(`<div class="ep-live-error">${esc(message || copy().error)}</div>`);
  }

  function renderProfile() {
    const root = rootEl(); if (!root) return;
    const c = copy();
    root.innerHTML = shell(`<div class="ep-live-card"><strong>${esc(c.profileTitle)}</strong><div class="ep-live-meta">${esc(c.profileText)}</div>
      <form class="ep-live-form" data-ep-live-profile-form>
        <label class="ep-live-field"><span>${esc(c.series)}</span><input name="exam_series" maxlength="80" placeholder="Oct/Nov 2026"></label>
        <label class="ep-live-field"><span>${esc(c.target)}</span><input name="target_grade" maxlength="40" placeholder="A"></label>
        <label class="ep-live-field"><span>${esc(c.total)}</span><input name="total_hours" type="number" min="0.5" max="168" step="0.5" required></label>
        <label class="ep-live-field"><span>${esc(c.math)}</span><input name="math_hours" type="number" min="0.5" max="168" step="0.5" required></label>
        <div class="ep-live-actions"><button class="ep-live-btn" type="submit" data-ep-live-save-profile>${esc(state.busy ? c.saving : c.save)}</button></div>
      </form><div data-ep-live-profile-error></div></div>`);
    root.querySelector("[data-ep-live-profile-form]")?.addEventListener("submit", saveProfile);
  }

  async function saveProfile(event) {
    event.preventDefault();
    if (state.busy) return;
    const form = event.currentTarget;
    const total = Number(form.elements.total_hours.value);
    const math = Number(form.elements.math_hours.value);
    if (!(total > 0) || !(math > 0) || math > total || total > 168) {
      const el = rootEl()?.querySelector("[data-ep-live-profile-error]");
      if (el) el.innerHTML = `<div class="ep-live-error">${esc(copy().invalid)}</div>`;
      return;
    }
    state.busy = true; renderProfile();
    const result = await internal.api.saveExamProfile({ examSeries: form.elements.exam_series.value, targetGrade: form.elements.target_grade.value, totalHours: total, mathHours: math });
    state.busy = false;
    if (!result?.ok) { renderError(); return; }
    const profile = await internal.api.examProfile();
    state.profile = profile?.ok ? profile.data : null;
    await renderDashboard();
  }

  function componentCard(component, progress) {
    const c = copy();
    const s = progress?.screening || {};
    const reqItems = Number(s.required_items || 0), ansItems = Number(s.answered_items || 0);
    const reqAreas = Number(s.required_areas || 0), ansAreas = Number(s.answered_areas || 0);
    const pct = reqItems > 0 ? Math.min(100, Math.round(100 * ansItems / reqItems)) : 0;
    const complete = progress?.stage0_complete === true;
    const active = progress?.active_session;
    const button = complete
      ? `<div class="ep-live-notice"><strong>${esc(c.complete)}</strong><div class="ep-live-meta">${esc(c.route)}: ${esc(progress?.route || "foundation")}</div></div>`
      : `<button class="ep-live-btn" type="button" data-ep-live-start="${component}" ${state.busy ? "disabled" : ""}>${esc(active ? c.resume : c.start)}</button>`;
    return `<div class="ep-live-card"><strong>${component}</strong><div>${ansItems} / ${reqItems} ${esc(c.items)}</div><div class="ep-live-progress"><span style="width:${pct}%"></span></div><div class="ep-live-meta">${ansAreas} / ${reqAreas} ${esc(c.areas)}</div>${button}</div>`;
  }

  async function renderDashboard() {
    const root = rootEl(); if (!root) return;
    renderLoading();
    const [p1, p5] = await Promise.all([internal.api.diagnosticProgress("P1"), internal.api.diagnosticProgress("P5")]);
    if (!p1?.ok || !p5?.ok) { renderError(); return; }
    state.progress.P1 = p1.data; state.progress.P5 = p5.data;
    const profile = state.profile || {};
    const profileLine = [profile.exam_series, profile.target_grade].filter(Boolean).join(" · ");
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice">${esc(state.notice)}</div>` : ""}<div class="ep-live-meta">${esc(profileLine)}</div><div class="ep-live-grid">${componentCard("P1", p1.data)}${componentCard("P5", p5.data)}</div>`);
    state.notice = null;
    root.querySelectorAll("[data-ep-live-start]").forEach(button => button.addEventListener("click", () => startDiagnostic(button.dataset.epLiveStart)));
  }

  async function startDiagnostic(component) {
    if (state.busy) return;
    state.busy = true; await renderDashboard();
    const result = await internal.api.startNextDiagnostic(component, key(`ep-diag-${component.toLowerCase()}`));
    state.busy = false;
    if (!result?.ok || !result.data?.session_id) { renderError(); return; }
    await loadSession(result.data.session_id);
  }

  async function loadSession(sessionId) {
    renderLoading();
    const result = await internal.api.getSession(sessionId, state.language);
    if (!result?.ok) { renderError(); return; }
    state.session = result.data;
    const items = Array.isArray(state.session?.items) ? state.session.items : [];
    const next = items.find(item => item && item.answered !== true);
    if (!next && state.session?.status === "active") {
      const finalized = await internal.api.finalizeSession(sessionId, key("ep-diag-finalize"));
      if (!finalized?.ok) { renderError(); return; }
      state.notice = copy().finish;
      state.session = null;
      await renderDashboard();
      return;
    }
    if (!next) { state.session = null; await renderDashboard(); return; }
    state.itemStartedAt = Date.now();
    renderQuestion(next, items);
  }

  function renderQuestion(item, items) {
    const root = rootEl(); if (!root) return;
    const c = copy();
    const answered = items.filter(x => x?.answered === true).length;
    const total = items.length;
    let answerControl = "";
    if (String(item.qtype || "").toLowerCase() === "mcq" && Array.isArray(item.options)) {
      answerControl = `<div class="ep-live-options">${item.options.map((option, index) => `<label class="ep-live-option"><input type="radio" name="ep_live_answer" value="${index}"><span>${esc(option)}</span></label>`).join("")}</div>`;
    } else {
      answerControl = `<input class="ep-live-input" name="ep_live_text_answer" autocomplete="off">`;
    }
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice">${esc(state.notice)}</div>` : ""}<div class="ep-live-card"><div class="ep-live-head"><strong>${esc(c.question)} ${answered + 1} / ${total}</strong><span class="ep-live-meta">${esc(item.primary_skill_code || "")}</span></div><div class="ep-live-qtext">${esc(item.text || item.written_prompt || "")}</div>${answerControl}<div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-live-submit ${state.busy ? "disabled" : ""}>${esc(state.busy ? c.submitting : c.submit)}</button><button class="ep-live-btn secondary" type="button" data-ep-live-exit>${esc(c.back)}</button></div></div>`);
    state.notice = null;
    root.querySelector("[data-ep-live-submit]")?.addEventListener("click", () => submitAnswer(item));
    root.querySelector("[data-ep-live-exit]")?.addEventListener("click", () => { state.session = null; renderDashboard(); });
  }

  async function submitAnswer(item) {
    if (state.busy || !state.session) return;
    let payload;
    if (String(item.qtype || "").toLowerCase() === "mcq") {
      const chosen = rootEl()?.querySelector('input[name="ep_live_answer"]:checked');
      if (!chosen) return;
      payload = { picked_index: Number(chosen.value) };
    } else {
      const value = rootEl()?.querySelector('input[name="ep_live_text_answer"]')?.value?.trim();
      if (!value) return;
      payload = { answer: value };
    }
    state.busy = true;
    const result = await internal.api.submitResponse(state.session.session_id, item.item_order, payload, key("ep-diag-answer"), Date.now() - state.itemStartedAt, state.language);
    state.busy = false;
    if (!result?.ok) { renderError(); return; }
    const data = result.data || {};
    const c = copy();
    const parts = [];
    if (typeof data.is_correct === "boolean") parts.push(data.is_correct ? c.correct : c.incorrect);
    if (data.diagnostic_feedback) parts.push(data.diagnostic_feedback);
    else if (data.explanation) parts.push(data.explanation);
    if (data.next_action) parts.push(data.next_action);
    state.notice = parts.filter(Boolean).join(" — ");
    await loadSession(state.session.session_id);
  }

  async function mount(context = {}) {
    state.language = lang(context.language || state.language);
    if (!canMount()) return false;
    const root = rootEl();
    if (!root || root.hidden || root.querySelector("[data-ep-beta-action]")) return false;
    ensureStyle(); renderLoading();
    const profile = await internal.api.examProfile();
    if (!profile?.ok) { renderError(); return false; }
    state.profile = profile.data;
    if (!state.profile) renderProfile(); else await renderDashboard();
    return true;
  }

  function reset() {
    state.busy = false; state.profile = null; state.progress = { P1: null, P5: null }; state.session = null; state.notice = null;
  }

  function attach() {
    if (attached) return;
    const host = window.iClubExamPrep;
    if (!host || typeof host.open !== "function") { setTimeout(attach, 0); return; }
    attached = true;
    const wrapped = Object.freeze({
      syncSubjectHub: async context => {
        state.language = lang(context?.language || state.language);
        const result = await host.syncSubjectHub(context);
        if (!result) reset();
        return result;
      },
      refreshCapabilities: async () => {
        const result = await host.refreshCapabilities();
        if (host.isOpen() && canMount()) await mount({ language: state.language });
        return result;
      },
      open: async context => {
        state.language = lang(context?.language || state.language);
        const result = await host.open(context);
        if (result && canMount()) await mount(context || {});
        return result;
      },
      back: () => { reset(); return host.back(); },
      close: () => { reset(); return host.close(); },
      isOpen: () => host.isOpen(),
      liveFlowVersion: VERSION
    });
    window.iClubExamPrep = wrapped;
  }

  attach();
})();