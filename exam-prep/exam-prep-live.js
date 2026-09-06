(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p018plan1";
  let attached = false;

  const state = {
    language: "ru",
    busy: false,
    profile: null,
    progress: { P1: null, P5: null },
    session: null,
    returnView: null,
    itemStartedAt: 0,
    notice: null
  };

  function lang(value) {
    const v = String(value || "ru").toLowerCase();
    return ["ru", "uz", "en"].includes(v) ? v : "ru";
  }

  function copy() {
    if (state.language === "uz") return {
      title: "Cambridge AS Mathematics · Exam Prep", safe: "Faqat server ruxsati bilan ishlaydi. Synthetic o‘quvchi ma’lumotlari yo‘q.",
      profileTitle: "Avval imtihon rejangizni kiriting", profileText: "Bu ma’lumotlar haftalik matematik vaqt byudjetini to‘g‘ri tuzish uchun kerak.",
      series: "Imtihon seriyasi", target: "Maqsad baho", total: "Haftalik umumiy bo‘sh vaqt (soat)", math: "Matematikaga ajratiladigan vaqt (soat)",
      save: "Saqlash va diagnosticni boshlash", saving: "Saqlanmoqda…", invalid: "Soatlarni tekshiring: matematika vaqti 0 dan katta va umumiy vaqtdan oshmasligi kerak.",
      items: "savol", areas: "bo‘lim", start: "Keyingi diagnosticni boshlash", resume: "Diagnosticni davom ettirish", complete: "Screening yakunlandi", route: "Yo‘nalish", loading: "Yuklanmoqda…",
      question: "Savol", submit: "Javobni yuborish", submitting: "Yuborilmoqda…", correct: "To‘g‘ri", incorrect: "Tekshirish kerak", finish: "Paket yakunlandi. Natija yangilandi.",
      error: "Amalni bajarib bo‘lmadi. Qayta urinib ko‘ring.", back: "Orqaga", plan: "Haftalik reja", openPlan: "Haftalik rejani ochish", buildPlan: "Rejani tuzish", priority: "Ustuvorlik",
      learning: "Mavzuni mustahkamlash", correction: "Xatoni tuzatish", retest: "Kechiktirilgan qayta test", mixed: "Aralash transfer", rebaseline: "Rejani qayta hisoblash", startTask: "Boshlash", notDue: "Hali vaqti kelmagan", noPlan: "Faol reja yo‘q.", written: "Yechimingizni yozing", completedTask: "Topshiriq tugadi. Reja yangilandi."
    };
    if (state.language === "en") return {
      title: "Cambridge AS Mathematics · Exam Prep", safe: "Server-authorized only. No synthetic learner data.",
      profileTitle: "Set your exam plan first", profileText: "This is used to build a realistic weekly mathematics time budget.",
      series: "Exam series", target: "Target grade", total: "Total weekly study time (hours)", math: "Mathematics budget (hours)",
      save: "Save and start diagnostic", saving: "Saving…", invalid: "Check the hours: mathematics time must be above 0 and cannot exceed total time.",
      items: "questions", areas: "areas", start: "Start next diagnostic", resume: "Continue diagnostic", complete: "Screening complete", route: "Route", loading: "Loading…",
      question: "Question", submit: "Submit answer", submitting: "Submitting…", correct: "Correct", incorrect: "Needs review", finish: "Package complete. Progress updated.",
      error: "The action could not be completed. Try again.", back: "Back", plan: "Weekly plan", openPlan: "Open weekly plan", buildPlan: "Build weekly plan", priority: "Priority",
      learning: "Build first coverage", correction: "Correct this skill", retest: "Delayed retest", mixed: "Mixed transfer", rebaseline: "Rebaseline plan", startTask: "Start", notDue: "Not due yet", noPlan: "No active plan yet.", written: "Write your solution", completedTask: "Task complete. Plan refreshed."
    };
    return {
      title: "Cambridge AS Mathematics · Exam Prep", safe: "Работает только с серверным разрешением. Synthetic learner data не используются.",
      profileTitle: "Сначала задайте план экзамена", profileText: "Это нужно, чтобы система строила реалистичный недельный бюджет времени на математику.",
      series: "Экзаменационная сессия", target: "Целевая оценка", total: "Общее учебное время в неделю (часы)", math: "Бюджет на математику (часы)",
      save: "Сохранить и начать diagnostic", saving: "Сохраняем…", invalid: "Проверьте часы: время на математику должно быть больше 0 и не превышать общее время.",
      items: "вопросов", areas: "разделов", start: "Начать следующий diagnostic", resume: "Продолжить diagnostic", complete: "Screening завершён", route: "Маршрут", loading: "Загрузка…",
      question: "Вопрос", submit: "Отправить ответ", submitting: "Отправляем…", correct: "Верно", incorrect: "Нужно разобрать", finish: "Пакет завершён. Прогресс обновлён.",
      error: "Не удалось выполнить действие. Попробуйте ещё раз.", back: "Назад", plan: "Недельный план", openPlan: "Открыть недельный план", buildPlan: "Составить недельный план", priority: "Приоритет",
      learning: "Закрыть первый пробел", correction: "Исправить ошибку", retest: "Отложенный ретест", mixed: "Смешанный перенос", rebaseline: "Пересчитать план", startTask: "Начать", notDue: "Ретест ещё не наступил", noPlan: "Активного плана пока нет.", written: "Запишите своё решение", completedTask: "Задание завершено. План обновлён."
    };
  }

  function esc(value) {
    return String(value == null ? "" : value).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&#039;");
  }
  function key(prefix) { return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`; }
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
      .ep-live-field{display:grid;gap:5px;font-size:13px}.ep-live-field input,.ep-live-input,.ep-live-textarea{width:100%;box-sizing:border-box;padding:10px 11px;border:1px solid rgba(127,127,127,.35);border-radius:10px;background:transparent;color:inherit}
      .ep-live-textarea{min-height:140px;resize:vertical}.ep-live-btn{border:0;border-radius:11px;padding:10px 14px;font-weight:700;cursor:pointer;background:#111827;color:#fff}.ep-live-btn:disabled{opacity:.55;cursor:default}.ep-live-btn.secondary{background:transparent;color:inherit;border:1px solid rgba(127,127,127,.35)}
      .ep-live-progress{height:7px;border-radius:999px;background:rgba(127,127,127,.18);overflow:hidden}.ep-live-progress>span{display:block;height:100%;background:currentColor;opacity:.7}
      .ep-live-meta{font-size:12px;opacity:.72}.ep-live-options{display:grid;gap:8px}.ep-live-option{display:flex;gap:9px;align-items:flex-start;padding:10px;border:1px solid rgba(127,127,127,.25);border-radius:10px}
      .ep-live-notice{padding:10px;border-radius:10px;background:rgba(127,127,127,.1);font-size:13px}.ep-live-error{padding:10px;border-radius:10px;background:rgba(180,30,30,.12);font-size:13px}.ep-live-qtext{white-space:pre-wrap;line-height:1.5}.ep-live-actions{display:flex;gap:8px;flex-wrap:wrap}
      .ep-live-plan-item{display:grid;grid-template-columns:auto 1fr auto;gap:10px;align-items:center;padding:11px;border:1px solid rgba(127,127,127,.2);border-radius:11px}.ep-live-priority{font-weight:800;font-size:18px}.ep-live-due{font-size:11px;opacity:.7}
      @media(max-width:680px){.ep-live-grid,.ep-live-form{grid-template-columns:1fr}.ep-live-head{display:grid}.ep-live-plan-item{grid-template-columns:auto 1fr}.ep-live-plan-item .ep-live-btn{grid-column:1/-1}}
    `;
    document.head.appendChild(style);
  }

  function shell(body) {
    const c = copy();
    return `<section class="ep-host-shell ep-live" aria-label="${esc(c.title)}"><div class="ep-live-head"><div><div class="ep-host-kicker">Core beta</div><h2 class="ep-host-title">${esc(c.title)}</h2></div><div class="ep-live-safe">${esc(c.safe)}</div></div>${body}</section>`;
  }
  function renderLoading() { const root = rootEl(); if (root) root.innerHTML = shell(`<div class="ep-live-card">${esc(copy().loading)}</div>`); }
  function renderError(message = null) { const root = rootEl(); if (root) root.innerHTML = shell(`<div class="ep-live-error">${esc(message || copy().error)}</div><button class="ep-live-btn secondary" data-ep-live-home>${esc(copy().back)}</button>`); root?.querySelector('[data-ep-live-home]')?.addEventListener('click', renderDashboard); }

  function renderProfile() {
    const root = rootEl(); if (!root) return; const c = copy();
    root.innerHTML = shell(`<div class="ep-live-card"><strong>${esc(c.profileTitle)}</strong><div class="ep-live-meta">${esc(c.profileText)}</div><form class="ep-live-form" data-ep-live-profile-form>
      <label class="ep-live-field"><span>${esc(c.series)}</span><input name="exam_series" maxlength="80" placeholder="Oct/Nov 2026"></label>
      <label class="ep-live-field"><span>${esc(c.target)}</span><input name="target_grade" maxlength="40" placeholder="A"></label>
      <label class="ep-live-field"><span>${esc(c.total)}</span><input name="total_hours" type="number" min="0.5" max="168" step="0.5" required></label>
      <label class="ep-live-field"><span>${esc(c.math)}</span><input name="math_hours" type="number" min="0.5" max="168" step="0.5" required></label>
      <div class="ep-live-actions"><button class="ep-live-btn" type="submit" data-ep-live-save-profile>${esc(state.busy ? c.saving : c.save)}</button></div></form><div data-ep-live-profile-error></div></div>`);
    root.querySelector("[data-ep-live-profile-form]")?.addEventListener("submit", saveProfile);
  }

  async function saveProfile(event) {
    event.preventDefault(); if (state.busy) return;
    const form = event.currentTarget;
    const values = { examSeries: form.elements.exam_series.value, targetGrade: form.elements.target_grade.value, totalHours: Number(form.elements.total_hours.value), mathHours: Number(form.elements.math_hours.value) };
    if (!(values.totalHours > 0) || !(values.mathHours > 0) || values.mathHours > values.totalHours || values.totalHours > 168) {
      const el = rootEl()?.querySelector("[data-ep-live-profile-error]"); if (el) el.innerHTML = `<div class="ep-live-error">${esc(copy().invalid)}</div>`; return;
    }
    state.busy = true; renderLoading();
    const result = await internal.api.saveExamProfile(values); state.busy = false;
    if (!result?.ok) { renderError(); return; }
    const profile = await internal.api.examProfile(); state.profile = profile?.ok ? profile.data : null; await renderDashboard();
  }

  function componentCard(component, progress) {
    const c = copy(), s = progress?.screening || {};
    const reqItems = Number(s.required_items || 0), ansItems = Number(s.answered_items || 0), reqAreas = Number(s.required_areas || 0), ansAreas = Number(s.answered_areas || 0);
    const pct = reqItems > 0 ? Math.min(100, Math.round(100 * ansItems / reqItems)) : 0;
    const complete = progress?.stage0_complete === true, active = progress?.active_session;
    const action = complete
      ? `<div class="ep-live-notice"><strong>${esc(c.complete)}</strong><div class="ep-live-meta">${esc(c.route)}: ${esc(progress?.route || "foundation")}</div></div><button class="ep-live-btn" type="button" data-ep-live-plan="${component}">${esc(c.openPlan)}</button>`
      : `<button class="ep-live-btn" type="button" data-ep-live-start="${component}" ${state.busy ? "disabled" : ""}>${esc(active ? c.resume : c.start)}</button>`;
    return `<div class="ep-live-card"><strong>${component}</strong><div>${ansItems} / ${reqItems} ${esc(c.items)}</div><div class="ep-live-progress"><span style="width:${pct}%"></span></div><div class="ep-live-meta">${ansAreas} / ${reqAreas} ${esc(c.areas)}</div>${action}</div>`;
  }

  async function renderDashboard() {
    const root = rootEl(); if (!root) return; renderLoading();
    const [p1, p5] = await Promise.all([internal.api.diagnosticProgress("P1"), internal.api.diagnosticProgress("P5")]);
    if (!p1?.ok || !p5?.ok) { renderError(); return; }
    state.progress.P1 = p1.data; state.progress.P5 = p5.data;
    const profileLine = [state.profile?.exam_series, state.profile?.target_grade].filter(Boolean).join(" · ");
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice">${esc(state.notice)}</div>` : ""}<div class="ep-live-meta">${esc(profileLine)}</div><div class="ep-live-grid">${componentCard("P1", p1.data)}${componentCard("P5", p5.data)}</div>`);
    state.notice = null;
    root.querySelectorAll("[data-ep-live-start]").forEach(b => b.addEventListener("click", () => startDiagnostic(b.dataset.epLiveStart)));
    root.querySelectorAll("[data-ep-live-plan]").forEach(b => b.addEventListener("click", () => openPlan(b.dataset.epLivePlan)));
  }

  async function startDiagnostic(component) {
    if (state.busy) return; state.busy = true; renderLoading();
    const result = await internal.api.startNextDiagnostic(component, key(`ep-diag-${component.toLowerCase()}`)); state.busy = false;
    if (!result?.ok || !result.data?.session_id) { renderError(); return; }
    state.returnView = { kind: "dashboard", component }; await loadSession(result.data.session_id);
  }

  function itemTypeLabel(type) {
    const c = copy(); return ({ learning: c.learning, correction: c.correction, retest: c.retest, mixed_transfer: c.mixed, rebaseline: c.rebaseline })[type] || type;
  }

  async function openPlan(component) {
    renderLoading();
    let planResult = await internal.api.weeklyPlan(component);
    if (!planResult?.ok) { renderError(); return; }
    let plan = planResult.data;
    if (!plan?.plan_id) {
      const generated = await internal.api.generateWeeklyPlan(component, "normal");
      if (!generated?.ok) { renderError(); return; }
      planResult = await internal.api.weeklyPlan(component); plan = planResult?.data;
    }
    if (!planResult?.ok || !plan?.plan_id) { renderError(copy().noPlan); return; }
    renderPlan(component, plan);
  }

  function renderPlan(component, plan) {
    const root = rootEl(); if (!root) return; const c = copy(); const items = Array.isArray(plan.items) ? plan.items : [];
    const rows = items.length ? items.map(item => {
      const due = item.due_at ? new Date(item.due_at) : null;
      const future = item.item_type === "retest" && due && due.getTime() > Date.now();
      const actionable = ["learning","correction","retest","mixed_transfer"].includes(item.item_type) && item.status === "pending";
      const button = actionable ? `<button class="ep-live-btn" data-ep-live-plan-item="${Number(item.priority_order)}" ${future ? "disabled" : ""}>${esc(future ? c.notDue : c.startTask)}</button>` : "";
      return `<div class="ep-live-plan-item"><div class="ep-live-priority">${Number(item.priority_order)}</div><div><strong>${esc(itemTypeLabel(item.item_type))}</strong><div class="ep-live-meta">${esc(item.skill_code || item.action_code || "")}</div>${due ? `<div class="ep-live-due">${esc(due.toLocaleString())}</div>` : ""}</div>${button}</div>`;
    }).join("") : `<div class="ep-live-notice">${esc(c.noPlan)}</div>`;
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice">${esc(state.notice)}</div>` : ""}<div class="ep-live-card"><div class="ep-live-head"><div><strong>${component} · ${esc(c.plan)}</strong><div class="ep-live-meta">Week ${Number(plan.active_week_no || 1)} · v${Number(plan.plan_version || 1)}</div></div><button class="ep-live-btn secondary" data-ep-live-dashboard>${esc(c.back)}</button></div>${rows}</div>`);
    state.notice = null;
    root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard);
    root.querySelectorAll('[data-ep-live-plan-item]').forEach(b => b.addEventListener('click', () => launchPlanItem(component, plan.plan_id, Number(b.dataset.epLivePlanItem))));
  }

  async function launchPlanItem(component, planId, priorityOrder) {
    if (state.busy) return; state.busy = true; renderLoading();
    const auth = await internal.api.authorizePlanItem(planId, priorityOrder);
    if (!auth?.ok || !auth.data?.authorization_id) { state.busy = false; renderError(); return; }
    const started = await internal.api.startSession(auth.data.authorization_id, key("ep-plan-session")); state.busy = false;
    if (!started?.ok || !started.data?.session_id) { renderError(); return; }
    state.returnView = { kind: "plan", component }; await loadSession(started.data.session_id);
  }

  async function loadSession(sessionId) {
    renderLoading(); const result = await internal.api.getSession(sessionId, state.language);
    if (!result?.ok) { renderError(); return; }
    state.session = result.data;
    const items = Array.isArray(state.session?.items) ? state.session.items : [], next = items.find(item => item && item.answered !== true);
    if (!next && state.session?.status === "active") {
      const finalized = await internal.api.finalizeSession(sessionId, key("ep-session-finalize"));
      if (!finalized?.ok) { renderError(); return; }
      const finishedType = state.session.session_type, component = state.session.component_code;
      state.session = null;
      if (finishedType === "diagnostic") { state.notice = copy().finish; await renderDashboard(); }
      else {
        await internal.api.generateWeeklyPlan(component, "normal");
        state.notice = copy().completedTask; await openPlan(component);
      }
      return;
    }
    if (!next) { state.session = null; if (state.returnView?.kind === "plan") await openPlan(state.returnView.component); else await renderDashboard(); return; }
    state.itemStartedAt = Date.now(); renderQuestion(next, items);
  }

  function renderQuestion(item, items) {
    const root = rootEl(); if (!root) return; const c = copy(), answered = items.filter(x => x?.answered === true).length, total = items.length;
    let answerControl = "";
    if (item.item_kind === "written") {
      answerControl = `<label class="ep-live-field"><span>${esc(c.written)}</span><textarea class="ep-live-textarea" name="ep_live_written_answer"></textarea></label>`;
    } else if (String(item.qtype || "").toLowerCase() === "mcq" && Array.isArray(item.options)) {
      answerControl = `<div class="ep-live-options">${item.options.map((option, index) => `<label class="ep-live-option"><input type="radio" name="ep_live_answer" value="${index}"><span>${esc(option)}</span></label>`).join("")}</div>`;
    } else answerControl = `<input class="ep-live-input" name="ep_live_text_answer" autocomplete="off">`;
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice">${esc(state.notice)}</div>` : ""}<div class="ep-live-card"><div class="ep-live-head"><strong>${esc(c.question)} ${answered + 1} / ${total}</strong><span class="ep-live-meta">${esc(item.primary_skill_code || "")}</span></div><div class="ep-live-qtext">${esc(item.text || item.written_prompt || "")}</div>${answerControl}<div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-live-submit>${esc(c.submit)}</button><button class="ep-live-btn secondary" type="button" data-ep-live-exit>${esc(c.back)}</button></div></div>`);
    state.notice = null;
    root.querySelector('[data-ep-live-submit]')?.addEventListener('click', () => submitAnswer(item));
    root.querySelector('[data-ep-live-exit]')?.addEventListener('click', async () => { state.session = null; if (state.returnView?.kind === "plan") await openPlan(state.returnView.component); else await renderDashboard(); });
  }

  async function submitAnswer(item) {
    if (state.busy || !state.session) return; let payload;
    if (item.item_kind === "written") {
      const value = rootEl()?.querySelector('textarea[name="ep_live_written_answer"]')?.value?.trim(); if (!value) return; payload = { artifact: { text: value } };
    } else if (String(item.qtype || "").toLowerCase() === "mcq") {
      const chosen = rootEl()?.querySelector('input[name="ep_live_answer"]:checked'); if (!chosen) return; payload = { picked_index: Number(chosen.value) };
    } else {
      const value = rootEl()?.querySelector('input[name="ep_live_text_answer"]')?.value?.trim(); if (!value) return; payload = { answer: value };
    }
    state.busy = true; renderLoading();
    const result = await internal.api.submitResponse(state.session.session_id, item.item_order, payload, key("ep-answer"), Date.now() - state.itemStartedAt, state.language); state.busy = false;
    if (!result?.ok) { renderError(); return; }
    const data = result.data || {}, c = copy(), parts = [];
    if (typeof data.is_correct === "boolean") parts.push(data.is_correct ? c.correct : c.incorrect);
    if (data.diagnostic_feedback) parts.push(data.diagnostic_feedback); else if (data.explanation) parts.push(data.explanation);
    if (data.next_action) parts.push(data.next_action);
    state.notice = parts.filter(Boolean).join(" — "); await loadSession(state.session.session_id);
  }

  async function mount(context = {}) {
    state.language = lang(context.language || state.language); if (!canMount()) return false;
    const root = rootEl(); if (!root || root.hidden || root.querySelector('[data-ep-beta-action]')) return false;
    ensureStyle(); renderLoading(); const profile = await internal.api.examProfile(); if (!profile?.ok) { renderError(); return false; }
    state.profile = profile.data; if (!state.profile) renderProfile(); else await renderDashboard(); return true;
  }
  function reset() { state.busy = false; state.profile = null; state.progress = { P1: null, P5: null }; state.session = null; state.returnView = null; state.notice = null; }

  function attach() {
    if (attached) return; const host = window.iClubExamPrep;
    if (!host || typeof host.open !== "function") { setTimeout(attach, 0); return; }
    attached = true;
    window.iClubExamPrep = Object.freeze({
      syncSubjectHub: async context => { state.language = lang(context?.language || state.language); const result = await host.syncSubjectHub(context); if (!result) reset(); return result; },
      refreshCapabilities: async () => { const result = await host.refreshCapabilities(); if (host.isOpen() && canMount()) await mount({ language: state.language }); return result; },
      open: async context => { state.language = lang(context?.language || state.language); const result = await host.open(context); if (result && canMount()) await mount(context || {}); return result; },
      back: () => { reset(); return host.back(); }, close: () => { reset(); return host.close(); }, isOpen: () => host.isOpen(), liveFlowVersion: VERSION
    });
  }

  attach();
})();