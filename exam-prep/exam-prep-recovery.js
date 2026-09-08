(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p208preserve1";
  let observer = null;
  let queued = false;
  let busy = false;
  let hydrationToken = 0;
  let itemStartedAt = 0;

  function rootEl() { return document.querySelector("#exam-prep-host-root"); }
  function language() {
    try {
      const value = String(window.i18n?.getLang?.() || document.documentElement.lang || "ru").toLowerCase();
      return ["ru", "uz", "en"].includes(value) ? value : "ru";
    } catch (_) { return "ru"; }
  }

  function copy() {
    if (language() === "uz") return {
      title: "O‘qish jadvali o‘zgardimi?",
      body: "Tanaffusning o‘zi oldingi natijalaringizni bekor qilmaydi. Davrni kiriting — tizim faqat keyingi rejangizni moslashtiradi.",
      adjust: "Rejani moslashtirish", active: "Reja tanaffusdan keyin moslashtirilgan", days: "kun",
      formTitle: "Tanaffus davri", from: "Qaysi kundan", resumed: "Qachon o‘qishga qaytdingiz", reason: "Sabab",
      absence: "Darslarni o‘tkazib yuborish", holiday: "Ta’til yoki safar", other: "Boshqa",
      save: "Saqlash va rejani yangilash", back: "Orqaga", returnOverview: "Umumiy ko‘rinishga qaytish",
      invalid: "Sanalarni tekshiring: qaytish sanasi boshlanish sanasidan keyin va bugundan kech bo‘lmasligi kerak.",
      error: "Amalni bajarib bo‘lmadi. Qayta urinib ko‘ring.", done: "Reja moslashtirildi",
      reserve: "Qisqa tanaffus: zaxira vaqtdan foydalanamiz, muhim qayta tekshiruvlar saqlanadi.",
      gentle: "Rejaga ehtiyotkorlik bilan qaytamiz. Avvalgi natijalar saqlanadi; bosqich faqat vaqt o‘tgani uchun o‘zgarmaydi.",
      twoThree: "Keyingi 14 kun: 50% majburiy o‘tilmagan mavzular, 25% shu mavzular bo‘yicha masalalar, 15% oldingi mavzular, 10% vaqtli mashq. Muhim qayta tekshiruvlar saqlanadi.",
      extended: "Kengaytirilgan tiklanish rejasi tuziladi. Avvalgi natijalar saqlanadi; kerak bo‘lsa tizim bir necha qisqa savol bilan hozirgi bilimingizni tekshirishni taklif qiladi.",
      long: "P1 va P5 alohida qayta rejalashtiriladi. Bu progressni qayta boshlash emas: oldingi natijalar saqlanadi, kerak bo‘lsa hozirgi bilim qisqa tekshiruv bilan tasdiqlanadi.",
      preserved: "Tasdiqlangan progress va oldingi natijalar saqlanadi. Vaqtning o‘zi progressni kamaytirmaydi.",
      checkTitle: "Saqlangan bilimlarni qisqa tekshirish", checkBody: "Bu qisqa tekshiruv oldingi natijalaringizni o‘chirmaydi. U faqat qaysi bilimlar saqlanganini va nimani qisqacha takrorlash foydali ekanini aniqlaydi.",
      checkStart: "Bilimlarni tekshirish", checkContinue: "Tekshiruvni davom ettirish", question: "Savol", submit: "Javobni yuborish",
      correct: "To‘g‘ri", incorrect: "Bu mavzuni qisqacha yangilash foydali bo‘ladi.",
      confirmed: "Bilimlar tasdiqlandi. Oldingi progress saqlangan.",
      refresh: "Ayrim mavzularni qisqacha takrorlash tavsiya qilindi. Oldingi progress va tarix o‘chirilmaydi; takrorlash keyingi rejaga qo‘shiladi.",
      checkOf: "Qisqa tekshiruv", noCheck: "Hozir qo‘shimcha tekshiruv kerak emas."
    };
    if (language() === "en") return {
      title: "Has your study schedule changed?",
      body: "A study break does not cancel your previous results. Add the dates and the system will adjust only what you do next.",
      adjust: "Adjust my plan", active: "Plan adjusted after a study break", days: "days",
      formTitle: "Study break period", from: "From", resumed: "Returned to study", reason: "Reason",
      absence: "Missed study time", holiday: "Holiday or travel", other: "Other",
      save: "Save and update plan", back: "Back", returnOverview: "Return to overview",
      invalid: "Check the dates: the return date must be after the start date and cannot be in the future.",
      error: "The action could not be completed. Try again.", done: "Plan adjusted",
      reserve: "Short break: reserve time is used and important delayed checks stay in place.",
      gentle: "Return to the plan gently. Previous results stay recorded; your phase does not change just because time passed.",
      twoThree: "For the next 14 days: 50% required uncovered topics, 25% questions on them, 15% older topics and 10% timed practice. Important delayed checks remain.",
      extended: "An extended recovery plan is used. Previous results stay recorded; if useful, the system can offer a few short questions to confirm what you still know.",
      long: "P1 and P5 are replanned separately. This is not a progress reset: previous results stay recorded and, where useful, current knowledge can be confirmed with a short check.",
      preserved: "Confirmed progress and previous results are kept. Time alone does not reduce progress.",
      checkTitle: "Short check of retained knowledge", checkBody: "This short check cannot erase previous results. It only confirms what is still secure and what would benefit from a brief refresh.",
      checkStart: "Check retained knowledge", checkContinue: "Continue the check", question: "Question", submit: "Submit answer",
      correct: "Correct", incorrect: "A brief refresh of this topic will be useful.",
      confirmed: "Knowledge confirmed. Your previous progress is retained.",
      refresh: "A brief refresh is recommended for some topics. Previous progress and history are not deleted; the refresh is added to your next plan.",
      checkOf: "Short check", noCheck: "No additional check is needed now."
    };
    return {
      title: "Изменился учебный график?",
      body: "Сам перерыв не отменяет ваши прежние результаты. Укажите период — система скорректирует только дальнейший план.",
      adjust: "Скорректировать план", active: "План адаптирован после перерыва", days: "дн.",
      formTitle: "Период перерыва", from: "С какого дня", resumed: "Когда вернулись к занятиям", reason: "Причина",
      absence: "Пропуск занятий", holiday: "Каникулы или поездка", other: "Другое",
      save: "Сохранить и обновить план", back: "Назад", returnOverview: "Вернуться к обзору",
      invalid: "Проверьте даты: дата возвращения должна быть позже даты начала и не может быть в будущем.",
      error: "Не удалось выполнить действие. Попробуйте ещё раз.", done: "План адаптирован",
      reserve: "Короткий перерыв: используем резерв времени, важные повторные проверки сохраняются.",
      gentle: "Возвращаемся к плану мягко. Прежние результаты сохраняются; этап не меняется только из-за прошедшего времени.",
      twoThree: "На следующие 14 дней: 50% — обязательные непройденные темы, 25% — задачи по ним, 15% — более ранние темы, 10% — практика на время. Важные повторные проверки сохраняются.",
      extended: "Включается расширенный режим восстановления. Прежние результаты сохраняются; при необходимости система предложит несколько коротких вопросов, чтобы подтвердить сохранившиеся знания.",
      long: "P1 и P5 перепланируются отдельно. Это не сброс прогресса: прежние результаты сохраняются, а актуальные знания при необходимости подтверждаются короткой проверкой.",
      preserved: "Подтверждённый прогресс и прежние результаты сохраняются. Само течение времени не уменьшает прогресс.",
      checkTitle: "Короткая проверка сохранённых знаний", checkBody: "Эта проверка не может удалить прежние результаты. Она только подтверждает, что знания сохранились, и показывает, что полезно быстро освежить.",
      checkStart: "Проверить сохранённые знания", checkContinue: "Продолжить проверку", question: "Вопрос", submit: "Отправить ответ",
      correct: "Верно", incorrect: "Эту тему полезно коротко освежить.",
      confirmed: "Знания подтверждены. Прежний прогресс сохранён.",
      refresh: "По нескольким темам рекомендовано короткое повторение. Прежний прогресс и история не удаляются; повторение добавляется в следующий план.",
      checkOf: "Короткая проверка", noCheck: "Сейчас дополнительная проверка не требуется."
    };
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;").replaceAll("'", "&#039;");
  }
  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }
  function isDashboard(root) {
    return Boolean(root?.querySelector('[data-ep-live-plan="P1"], [data-ep-live-start="P1"]')) &&
      Boolean(root?.querySelector('[data-ep-live-plan="P5"], [data-ep-live-start="P5"]'));
  }
  function todayIso() {
    const d = new Date();
    const local = new Date(d.getTime() - d.getTimezoneOffset() * 60000);
    return local.toISOString().slice(0, 10);
  }
  function key(prefix) {
    const random = globalThis.crypto?.randomUUID?.() || `${Date.now()}-${Math.random().toString(16).slice(2)}`;
    return `${prefix}-${random}`;
  }
  function modeMessage(row) {
    const c = copy();
    const days = Number(row?.missed_days || 0);
    if (days <= 7) return c.reserve;
    if (days <= 13) return c.gentle;
    if (days <= 21) return c.twoThree;
    if (days <= 30) return c.extended;
    return c.long;
  }

  function checkStatusHtml(row, component) {
    const c = copy();
    const check = row?.revalidation;
    if (!check?.available || Number(check.selected_skill_count || 0) < 1) return "";
    if (check.status === "confirmed") return `<div class="ep-live-notice"><strong>${component}</strong><div class="ep-live-meta">${esc(c.confirmed)}</div></div>`;
    if (check.status === "refresh_recommended") return `<div class="ep-live-notice"><strong>${component}</strong><div class="ep-live-meta">${esc(c.refresh)}</div></div>`;
    const label = check.status === "in_progress" ? c.checkContinue : c.checkStart;
    return `<div class="ep-live-notice"><strong>${component} · ${esc(c.checkTitle)}</strong><div class="ep-live-meta">${esc(c.checkBody)}</div><div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-recovery-check="${component}">${esc(label)}</button></div></div>`;
  }

  async function hydrateDashboard() {
    queued = false;
    const root = rootEl();
    if (!root || root.hidden || busy || !canUse() || !isDashboard(root)) return;
    if (root.querySelector("[data-ep-recovery-card]")) return;
    if (typeof internal.api?.recovery !== "function") return;

    const token = ++hydrationToken;
    let p1 = null, p5 = null;
    try {
      const results = await Promise.all([internal.api.recovery("P1"), internal.api.recovery("P5")]);
      if (token !== hydrationToken || !isDashboard(rootEl())) return;
      p1 = results[0]?.ok ? results[0].data : null;
      p5 = results[1]?.ok ? results[1].data : null;
    } catch (_) { return; }

    const c = copy();
    const activeRows = [p1, p5].filter(row => row?.active === true);
    const active = activeRows.length > 0;
    const days = active ? Math.max(...activeRows.map(row => Number(row?.missed_days || 0))) : 0;
    const status = active
      ? `<div class="ep-live-notice"><strong>${esc(c.active)}${days ? ` · ${days} ${esc(c.days)}` : ""}</strong><div class="ep-live-meta">${esc(modeMessage(activeRows[0]))}</div><div class="ep-live-meta">${esc(c.preserved)}</div></div>`
      : "";
    const checks = `${checkStatusHtml(p1, "P1")}${checkStatusHtml(p5, "P5")}`;

    const card = document.createElement("div");
    card.className = "ep-live-card";
    card.dataset.epRecoveryCard = "true";
    card.innerHTML = `<strong>${esc(c.title)}</strong><div class="ep-live-meta">${esc(c.body)}</div>${status}${checks}<div class="ep-live-actions"><button class="ep-live-btn secondary" type="button" data-ep-recovery-open>${esc(c.adjust)}</button></div>`;
    const shell = root.querySelector(".ep-host-shell.ep-live") || root.firstElementChild || root;
    shell.appendChild(card);
    card.querySelector("[data-ep-recovery-open]")?.addEventListener("click", renderForm);
    card.querySelectorAll("[data-ep-recovery-check]").forEach(button => button.addEventListener("click", () => openKnowledgeCheck(button.dataset.epRecoveryCheck)));
  }

  function renderForm() {
    const root = rootEl();
    if (!root || busy) return;
    const c = copy(), today = todayIso();
    root.innerHTML = `<section class="ep-host-shell ep-live" data-ep-recovery-form-view><div class="ep-live-card">
      <div class="ep-live-head"><strong>${esc(c.formTitle)}</strong><button class="ep-live-btn secondary" type="button" data-ep-recovery-back>${esc(c.back)}</button></div>
      <div class="ep-live-meta">${esc(c.body)}</div>
      <form class="ep-live-form" data-ep-recovery-form>
        <label class="ep-live-field"><span>${esc(c.from)}</span><input type="date" name="started_on" max="${esc(today)}" required></label>
        <label class="ep-live-field"><span>${esc(c.resumed)}</span><input type="date" name="resumed_on" max="${esc(today)}" value="${esc(today)}" required></label>
        <label class="ep-live-field"><span>${esc(c.reason)}</span><select name="kind" required><option value="absence">${esc(c.absence)}</option><option value="planned_holiday">${esc(c.holiday)}</option><option value="other">${esc(c.other)}</option></select></label>
        <div class="ep-live-actions"><button class="ep-live-btn" type="submit">${esc(c.save)}</button></div>
      </form><div data-ep-recovery-error></div>
    </div></section>`;
    root.querySelector("[data-ep-recovery-back]")?.addEventListener("click", reopenOverview);
    root.querySelector("[data-ep-recovery-form]")?.addEventListener("submit", submitInterruption);
  }

  async function submitInterruption(event) {
    event.preventDefault();
    if (busy) return;
    const form = event.currentTarget;
    const startedOn = String(form.elements.started_on.value || "").trim();
    const resumedOn = String(form.elements.resumed_on.value || "").trim();
    const kind = String(form.elements.kind.value || "absence");
    const error = rootEl()?.querySelector("[data-ep-recovery-error]");
    const startMs = Date.parse(`${startedOn}T00:00:00`), resumeMs = Date.parse(`${resumedOn}T00:00:00`), todayMs = Date.parse(`${todayIso()}T23:59:59`);
    if (!startedOn || !resumedOn || !Number.isFinite(startMs) || !Number.isFinite(resumeMs) || resumeMs <= startMs || resumeMs > todayMs) {
      if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().invalid)}</div>`;
      return;
    }

    busy = true;
    try {
      const result = await internal.api.recordInterruption({ startedOn, resumedOn, kind });
      if (!result?.ok || !result.data) {
        if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().error)}</div>`;
        return;
      }
      await Promise.allSettled([internal.api.generateWeeklyPlan("P1"), internal.api.generateWeeklyPlan("P5")]);
      renderSuccess(result.data);
    } catch (_) {
      if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().error)}</div>`;
    } finally { busy = false; }
  }

  function renderSuccess(data) {
    const root = rootEl(); if (!root) return;
    const c = copy();
    root.innerHTML = `<section class="ep-host-shell ep-live" data-ep-recovery-success><div class="ep-live-card">
      <strong>${esc(c.done)}</strong><div class="ep-live-notice">${esc(modeMessage(data || {}))}</div>
      <div class="ep-live-meta">${esc(c.preserved)}</div>
      <div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-recovery-return>${esc(c.returnOverview)}</button></div>
    </div></section>`;
    root.querySelector("[data-ep-recovery-return]")?.addEventListener("click", reopenOverview);
  }

  async function openKnowledgeCheck(component) {
    if (busy) return;
    busy = true;
    try {
      const result = await internal.api.recovery(component);
      if (!result?.ok) { renderCheckError(); return; }
      const check = result.data?.revalidation;
      if (!check?.available) { renderCheckResult(component, "none"); return; }
      if (["confirmed", "refresh_recommended"].includes(check.status)) { renderCheckResult(component, check.status); return; }
      const next = (Array.isArray(check.items) ? check.items : []).find(item => item?.status !== "completed");
      if (!next) {
        const refreshed = await internal.api.recovery(component);
        renderCheckResult(component, refreshed?.data?.revalidation?.status || "none");
        return;
      }
      const auth = await internal.api.authorizeRevalidationItem(check.case_id, next.item_order);
      if (!auth?.ok || !auth.data?.authorization_id) { renderCheckError(); return; }
      let sessionId = auth.data.session_id || null;
      if (!sessionId) {
        const started = await internal.api.startSession(auth.data.authorization_id, key(`ep-retained-${component.toLowerCase()}`));
        if (!started?.ok || !started.data?.session_id) { renderCheckError(); return; }
        sessionId = started.data.session_id;
      }
      await renderCheckSession(component, sessionId);
    } catch (_) { renderCheckError(); }
    finally { busy = false; }
  }

  async function renderCheckSession(component, sessionId) {
    const c = copy();
    const result = await internal.api.getSession(sessionId, language());
    if (!result?.ok || !result.data) { renderCheckError(); return; }
    const session = result.data;
    if (session.status === "finalized") { await finishKnowledgeCheck(component); return; }
    const items = Array.isArray(session.items) ? session.items : [];
    const next = items.find(item => item?.answered !== true);
    if (!next) {
      const finalized = await internal.api.finalizeSession(sessionId, key("ep-retained-final"));
      if (!finalized?.ok) { renderCheckError(); return; }
      await finishKnowledgeCheck(component); return;
    }

    const root = rootEl(); if (!root) return;
    let answer = "";
    if (String(next.qtype || "").toLowerCase() === "mcq" && Array.isArray(next.options)) {
      answer = `<div class="ep-live-options">${next.options.map((option, index) => `<label class="ep-live-option"><input type="radio" name="ep_recovery_answer" value="${index}"><span>${esc(option)}</span></label>`).join("")}</div>`;
    } else if (next.item_kind === "question") {
      answer = `<input class="ep-live-input" name="ep_recovery_text_answer" autocomplete="off">`;
    } else {
      renderCheckError(); return;
    }
    const answered = items.filter(item => item?.answered === true).length;
    root.innerHTML = `<section class="ep-host-shell ep-live" data-ep-recovery-check-view><div class="ep-live-card">
      <div class="ep-live-head"><strong>${component} · ${esc(c.checkTitle)}</strong><button class="ep-live-btn secondary" type="button" data-ep-recovery-back>${esc(c.back)}</button></div>
      <div class="ep-live-meta">${esc(c.checkBody)}</div><div class="ep-live-qtext"><strong>${esc(c.question)} ${answered + 1}/${items.length}</strong><br>${esc(next.text || "")}</div>
      ${answer}<div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-recovery-submit>${esc(c.submit)}</button></div><div data-ep-recovery-feedback></div>
    </div></section>`;
    itemStartedAt = Date.now();
    root.querySelector("[data-ep-recovery-back]")?.addEventListener("click", reopenOverview);
    root.querySelector("[data-ep-recovery-submit]")?.addEventListener("click", () => submitKnowledgeAnswer(component, sessionId, next));
  }

  async function submitKnowledgeAnswer(component, sessionId, item) {
    if (busy) return;
    let payload;
    if (String(item.qtype || "").toLowerCase() === "mcq") {
      const chosen = rootEl()?.querySelector('input[name="ep_recovery_answer"]:checked');
      if (!chosen) return;
      payload = { picked_index: Number(chosen.value) };
    } else {
      const value = rootEl()?.querySelector('input[name="ep_recovery_text_answer"]')?.value?.trim();
      if (!value) return;
      payload = { answer: value };
    }
    busy = true;
    try {
      const result = await internal.api.submitResponse(sessionId, item.item_order, payload, key("ep-retained-answer"), Date.now() - itemStartedAt, language());
      if (!result?.ok) { renderCheckError(); return; }
      const feedback = rootEl()?.querySelector("[data-ep-recovery-feedback]");
      if (feedback && typeof result.data?.is_correct === "boolean") feedback.innerHTML = `<div class="ep-live-notice">${esc(result.data.is_correct ? copy().correct : copy().incorrect)}</div>`;
      await renderCheckSession(component, sessionId);
    } catch (_) { renderCheckError(); }
    finally { busy = false; }
  }

  async function finishKnowledgeCheck(component) {
    const refreshed = await internal.api.recovery(component);
    const status = refreshed?.ok ? refreshed.data?.revalidation?.status : null;
    if (status === "refresh_recommended") await internal.api.generateWeeklyPlan(component);
    if (status === "in_progress" || status === "recommended") {
      await openKnowledgeCheck(component);
      return;
    }
    renderCheckResult(component, status || "none");
  }

  function renderCheckResult(component, status) {
    const root = rootEl(); if (!root) return;
    const c = copy();
    const message = status === "confirmed" ? c.confirmed : status === "refresh_recommended" ? c.refresh : c.noCheck;
    root.innerHTML = `<section class="ep-host-shell ep-live" data-ep-recovery-check-result><div class="ep-live-card">
      <strong>${component} · ${esc(c.checkTitle)}</strong><div class="ep-live-notice">${esc(message)}</div><div class="ep-live-meta">${esc(c.preserved)}</div>
      <div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-recovery-return>${esc(c.returnOverview)}</button></div>
    </div></section>`;
    root.querySelector("[data-ep-recovery-return]")?.addEventListener("click", reopenOverview);
  }

  function renderCheckError() {
    const root = rootEl(); if (!root) return;
    const c = copy();
    root.innerHTML = `<section class="ep-host-shell ep-live"><div class="ep-live-card"><div class="ep-live-error">${esc(c.error)}</div><div class="ep-live-actions"><button class="ep-live-btn secondary" type="button" data-ep-recovery-return>${esc(c.returnOverview)}</button></div></div></section>`;
    root.querySelector("[data-ep-recovery-return]")?.addEventListener("click", reopenOverview);
  }

  async function reopenOverview() {
    hydrationToken += 1;
    try {
      if (typeof window.iClubExamPrep?.open === "function") await window.iClubExamPrep.open({ language: language() });
      else if (typeof window.iClubExamPrep?.refreshCapabilities === "function") await window.iClubExamPrep.refreshCapabilities();
    } catch (_) { /* Core host owns fallback behavior. */ }
  }

  function queueHydrate() { if (!queued) { queued = true; queueMicrotask(hydrateDashboard); } }
  function attach() {
    const root = rootEl();
    if (!root) { setTimeout(attach, 50); return; }
    if (observer) observer.disconnect();
    observer = new MutationObserver(queueHydrate);
    observer.observe(root, { childList: true, subtree: true, attributes: true, attributeFilter: ["hidden", "aria-hidden"] });
    queueHydrate();
    internal.recoveryFlowVersion = VERSION;
  }

  attach();
})();
