(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const MATHEMATICS_KEY = "mathematics";
  const state = {
    open: false,
    subjectKey: null,
    language: "ru",
    accessToken: 0,
    capabilities: null,
    invitation: null,
    consentBusy: false,
    consentError: false,
    returnFocusEl: null
  };

  const $ = selector => document.querySelector(selector);

  function normalizeLanguage(value) {
    const lang = String(value || "ru").toLowerCase();
    return ["ru", "uz", "en"].includes(lang) ? lang : "ru";
  }

  function labels(lang) {
    if (lang === "uz") {
      return {
        title: "Cambridge AS Mathematics · Exam Prep",
        subtitle: "Paper 1 + Paper 5",
        alpha: "Imtihonga tayyorgarlik",
        note: "P1 va P5 natijalari alohida hisoblanadi. Mavjud Tours va Practice tarixingiz o‘zgarmaydi.",
        p1: "P1 · Pure Mathematics 1",
        p5: "P5 · Probability & Statistics 1",
        skills: "ko‘nikma",
        entryBadge: "Cambridge AS · Mathematics",
        entryTitle: "Exam Prep",
        entryDesc: "Paper 1 va Paper 5 bo‘yicha shaxsiy tayyorgarlik yo‘li: kirish tekshiruvi, haftalik reja, mavzular, xatolar va vaqtli mashqlar.",
        entryP1: "Pure Mathematics 1 · 45 ko‘nikma",
        entryP5: "Probability & Statistics 1 · 36 ko‘nikma",
        entryNote: "Practice va Tours tarixi o‘zgarmaydi.",
        entryCta: "Exam Prepni ochish",
        inviteBadge: "Yangi imkoniyat",
        inviteCta: "Taklifni ko‘rish",
        inviteTitle: "Exam Prep sinoviga taklif",
        inviteSub: "Ishtirokingizni tasdiqlang",
        inviteKicker: "Yangi imkoniyat sinovi",
        inviteBody: "Siz Cambridge AS Mathematics Exam Prep modulini sinab ko‘rishga taklif qilindingiz. Sinov davomida javoblaringiz, bajarish vaqtingiz va o‘quv progressi modulni yaxshilash uchun ishlatiladi. Ishtirok ixtiyoriy, ayrim xatolar uchrashi mumkin. Mavjud Tours va Practice tarixingiz o‘zgarmaydi.",
        mode: "O‘qish formati",
        components: "Komponentlar",
        history: "Tarix",
        historyKept: "Saqlanadi",
        consent: "Ishtirok etishga roziman",
        consented: "Rozilik qayd etildi",
        consentedBody: "Roziligingiz saqlandi. Exam Prep kirishi sinov boshlanganda alohida faollashtiriladi.",
        revoke: "Rozilikni bekor qilish",
        revokeConfirm: "Exam Prep sinovida ishtirok etishdan voz kechmoqchimisiz?",
        busy: "Saqlanmoqda…",
        error: "Amalni bajarib bo‘lmadi. Qayta urinib ko‘ring.",
        core: "Mustaqil tayyorgarlik",
        ai: "AI yordamida tayyorgarlik",
        mentor: "Mentor ko‘magida tayyorgarlik"
      };
    }
    if (lang === "en") {
      return {
        title: "Cambridge AS Mathematics · Exam Prep",
        subtitle: "Paper 1 + Paper 5",
        alpha: "Exam preparation",
        note: "P1 and P5 results are tracked separately. Your existing Tours and Practice history will not be changed.",
        p1: "P1 · Pure Mathematics 1",
        p5: "P5 · Probability & Statistics 1",
        skills: "skills",
        entryBadge: "Cambridge AS · Mathematics",
        entryTitle: "Exam Prep",
        entryDesc: "A personal route for Paper 1 and Paper 5: entry check, weekly plan, syllabus work, corrections and timed practice.",
        entryP1: "Pure Mathematics 1 · 45 skills",
        entryP5: "Probability & Statistics 1 · 36 skills",
        entryNote: "Practice and Tours history stays unchanged.",
        entryCta: "Open Exam Prep",
        inviteBadge: "New feature",
        inviteCta: "View invitation",
        inviteTitle: "Invitation to test Exam Prep",
        inviteSub: "Confirm your participation",
        inviteKicker: "New feature test",
        inviteBody: "You have been invited to test the Cambridge AS Mathematics Exam Prep module. During the test, your answers, completion time and learning progress will be used to improve the module. Participation is voluntary, and you may encounter errors. Your existing Tours and Practice history will not be changed.",
        mode: "Study format",
        components: "Components",
        history: "History",
        historyKept: "Preserved",
        consent: "I agree to participate",
        consented: "Consent recorded",
        consentedBody: "Your consent has been saved. Exam Prep access will be activated separately when testing begins.",
        revoke: "Withdraw consent",
        revokeConfirm: "Do you want to stop participating in the Exam Prep test?",
        busy: "Saving…",
        error: "The action could not be completed. Please try again.",
        core: "Independent preparation",
        ai: "Preparation with AI support",
        mentor: "Preparation with mentor support"
      };
    }
    return {
      title: "Cambridge AS Mathematics · Exam Prep",
      subtitle: "Paper 1 + Paper 5",
      alpha: "Подготовка к экзамену",
      note: "Результаты P1 и P5 учитываются отдельно. Ваша существующая история в Tours и Practice останется без изменений.",
      p1: "P1 · Pure Mathematics 1",
      p5: "P5 · Probability & Statistics 1",
      skills: "навыков",
      entryBadge: "Cambridge AS · Mathematics",
      entryTitle: "Exam Prep",
      entryDesc: "Персональный маршрут по Paper 1 и Paper 5: входная проверка, недельный план, темы, исправление ошибок и практика на время.",
      entryP1: "Pure Mathematics 1 · 45 навыков",
      entryP5: "Probability & Statistics 1 · 36 навыков",
      entryNote: "История Practice и Tours остаётся без изменений.",
      entryCta: "Открыть Exam Prep",
      inviteBadge: "Новая функция",
      inviteCta: "Посмотреть приглашение",
      inviteTitle: "Приглашение протестировать Exam Prep",
      inviteSub: "Подтвердите участие",
      inviteKicker: "Тестирование новой функции",
      inviteBody: "Вы приглашены протестировать модуль Cambridge AS Mathematics Exam Prep. Во время тестирования ваши ответы, время выполнения и учебный прогресс будут использоваться для улучшения модуля. Участие добровольное, возможны ошибки. Ваша существующая история в Tours и Practice останется без изменений.",
      mode: "Формат подготовки",
      components: "Компоненты",
      history: "История",
      historyKept: "Сохраняется",
      consent: "Я согласен участвовать",
      consented: "Согласие сохранено",
      consentedBody: "Согласие сохранено. Доступ к Exam Prep будет включён отдельно, когда начнётся тестирование.",
      revoke: "Отозвать согласие",
      revokeConfirm: "Вы хотите отказаться от участия в тестировании Exam Prep?",
      busy: "Сохраняем…",
      error: "Не удалось выполнить действие. Попробуйте ещё раз.",
      core: "Самостоятельная подготовка",
      ai: "Подготовка с поддержкой ИИ",
      mentor: "Подготовка с поддержкой ментора"
    };
  }

  function entryEl() { return $("#subject-hub-exam-prep-entry"); }
  function entryButtonEl() { return entryEl()?.querySelector('[data-action="open-exam-prep"]') || null; }
  function rootEl() { return $("#exam-prep-host-root"); }
  function hubEl() { return $("#courses-subject-hub"); }

  function canRestoreFocus(el) {
    if (!el || typeof el.focus !== "function" || !el.isConnected) return false;
    if (state.subjectKey !== MATHEMATICS_KEY || !showable()) return false;
    const entry = entryEl();
    if (!entry || entry.hidden || entry.getAttribute("aria-hidden") === "true") return false;
    return !el.closest?.("[hidden]");
  }

  function restoreEntryFocus() {
    const saved = state.returnFocusEl;
    state.returnFocusEl = null;
    const target = canRestoreFocus(saved) ? saved : entryButtonEl();
    if (!canRestoreFocus(target)) return;
    try { target.focus({ preventScroll: true }); }
    catch (_) { try { target.focus(); } catch (_) {} }
  }

  function focusHostRoot() {
    const root = rootEl();
    if (!root || root.hidden || typeof root.focus !== "function") return;
    root.setAttribute("tabindex", "-1");
    try { root.focus({ preventScroll: false }); }
    catch (_) { try { root.focus(); } catch (_) {} }
  }

  function setEntryVisible(visible) {
    const el = entryEl();
    const hub = hubEl();
    if (!el) return;
    el.hidden = !visible;
    el.setAttribute("aria-hidden", visible ? "false" : "true");
    if (hub) hub.classList.toggle("exam-prep-available", visible === true);
  }

  function allowed(caps) {
    return Boolean(
      caps &&
      caps.coreAccess === true &&
      caps.killSwitch === false &&
      caps.rolloutState !== "off"
    );
  }

  function invitationItem() {
    const items = state.invitation?.invitations;
    if (!state.invitation?.invited || !Array.isArray(items) || items.length === 0) return null;
    return items.find(item => item && item.memberStatus !== "removed") || null;
  }

  function invited() {
    return Boolean(invitationItem());
  }

  function showable() {
    return state.subjectKey === MATHEMATICS_KEY && (allowed(state.capabilities) || invited());
  }

  function serviceModeText(mode, text) {
    if (mode === "ai_assist") return text.ai;
    if (mode === "mentor_care") return text.mentor;
    return text.core;
  }

  function renderEntryCopy() {
    const text = labels(state.language);
    const entry = entryEl();
    const badge = $("#subject-hub-exam-prep-badge");
    const title = $("#subject-hub-exam-prep-title");
    const sub = $("#subject-hub-exam-prep-sub");
    const p1 = $("#subject-hub-exam-prep-p1");
    const p5 = $("#subject-hub-exam-prep-p5");
    const note = $("#subject-hub-exam-prep-note");
    const cta = $("#subject-hub-exam-prep-cta");
    const inviteOnly = invited() && !allowed(state.capabilities);
    if (entry) {
      entry.classList.toggle("is-invitation", inviteOnly);
      entry.setAttribute("data-ep-entry-mode", inviteOnly ? "invitation" : "live");
    }
    if (badge) badge.textContent = inviteOnly ? text.inviteBadge : text.entryBadge;
    if (title) title.textContent = inviteOnly ? text.inviteTitle : text.entryTitle;
    if (sub) sub.textContent = inviteOnly ? text.inviteSub : text.entryDesc;
    if (p1) p1.textContent = text.entryP1;
    if (p5) p5.textContent = text.entryP5;
    if (note) note.textContent = text.entryNote;
    if (cta) cta.textContent = inviteOnly ? text.inviteCta : text.entryCta;
  }

  function renderLiveShell() {
    const root = rootEl();
    if (!root) return false;
    const text = labels(state.language);
    root.innerHTML = `
      <section class="ep-host-shell" aria-label="${text.title}">
        <div class="ep-host-kicker">${text.alpha}</div>
        <h2 class="ep-host-title">${text.title}</h2>
        <div class="ep-host-subtitle">${text.subtitle}</div>
        <p class="ep-host-note">${text.note}</p>
        <div class="ep-host-component-grid">
          <div class="ep-host-component-card"><strong>${text.p1}</strong><span>45 ${text.skills}</span></div>
          <div class="ep-host-component-card"><strong>${text.p5}</strong><span>36 ${text.skills}</span></div>
        </div>
      </section>`;
    return true;
  }

  function renderInvitationShell() {
    const root = rootEl();
    const item = invitationItem();
    if (!root || !item) return false;
    const text = labels(state.language);
    const granted = item.consentStatus === "granted" && !item.revokedAt;
    const disabled = state.consentBusy ? " disabled" : "";
    const action = granted
      ? `<div class="ep-host-consent-state" role="status"><strong>${text.consented}</strong><span>${text.consentedBody}</span></div>
         <button class="ep-host-btn ep-host-btn-secondary" type="button" data-ep-beta-action="revoke"${disabled}>${state.consentBusy ? text.busy : text.revoke}</button>`
      : `<button class="ep-host-btn ep-host-btn-primary" type="button" data-ep-beta-action="grant"${disabled}>${state.consentBusy ? text.busy : text.consent}</button>`;
    const error = state.consentError ? `<div class="ep-host-error" role="alert">${text.error}</div>` : "";

    root.innerHTML = `
      <section class="ep-host-shell ep-host-invite-shell" aria-label="${text.inviteTitle}">
        <div class="ep-host-kicker">${text.inviteKicker}</div>
        <h2 class="ep-host-title">${text.inviteTitle}</h2>
        <p class="ep-host-note">${text.inviteBody}</p>
        <div class="ep-host-invite-facts">
          <div><span>${text.mode}</span><strong>${serviceModeText(item.serviceMode, text)}</strong></div>
          <div><span>${text.components}</span><strong>P1 + P5</strong></div>
          <div><span>${text.history}</span><strong>${text.historyKept}</strong></div>
        </div>
        ${error}
        <div class="ep-host-actions">${action}</div>
      </section>`;

    root.querySelector('[data-ep-beta-action="grant"]')?.addEventListener("click", handleGrantConsent);
    root.querySelector('[data-ep-beta-action="revoke"]')?.addEventListener("click", handleRevokeConsent);
    return true;
  }

  function close() {
    const shouldRestoreFocus = state.open && showable();
    state.open = false;
    state.consentBusy = false;
    state.consentError = false;
    const root = rootEl();
    const hub = hubEl();
    if (hub) hub.classList.remove("exam-prep-host-open");
    if (root) {
      root.hidden = true;
      root.setAttribute("aria-hidden", "true");
      root.innerHTML = "";
    }
    if (shouldRestoreFocus) restoreEntryFocus();
    else state.returnFocusEl = null;
    return true;
  }

  async function refreshAccess() {
    const token = ++state.accessToken;
    const api = internal.api;
    if (!api || typeof api.capabilities !== "function") {
      state.capabilities = null;
      state.invitation = null;
      setEntryVisible(false);
      close();
      return null;
    }

    const [capResult, inviteResult] = await Promise.all([
      api.capabilities(),
      typeof api.betaInvitation === "function" ? api.betaInvitation() : Promise.resolve(null)
    ]);
    if (token !== state.accessToken) return state.capabilities;

    state.capabilities = capResult?.ok ? capResult.data : null;
    state.invitation = inviteResult?.ok ? inviteResult.data : null;
    renderEntryCopy();

    const visible = showable();
    setEntryVisible(visible);
    if (!visible) close();
    return state.capabilities;
  }

  async function refreshCapabilities() {
    return refreshAccess();
  }

  async function refreshInvitationOnly() {
    const api = internal.api;
    if (!api || typeof api.betaInvitation !== "function") {
      state.invitation = null;
      return null;
    }
    const result = await api.betaInvitation();
    state.invitation = result?.ok ? result.data : null;
    renderEntryCopy();
    setEntryVisible(showable());
    return state.invitation;
  }

  async function handleGrantConsent() {
    if (state.consentBusy) return;
    const item = invitationItem();
    const api = internal.api;
    if (!item || !api || typeof api.grantBetaConsent !== "function") return;
    state.consentBusy = true;
    state.consentError = false;
    renderInvitationShell();
    const result = await api.grantBetaConsent(item.cohortKey);
    state.consentBusy = false;
    state.consentError = !result?.ok;
    if (result?.ok) await refreshInvitationOnly();
    if (state.open && invited() && !allowed(state.capabilities)) renderInvitationShell();
  }

  async function handleRevokeConsent() {
    if (state.consentBusy) return;
    const item = invitationItem();
    const api = internal.api;
    const text = labels(state.language);
    if (!item || !api || typeof api.revokeBetaConsent !== "function") return;
    if (typeof window.confirm === "function" && !window.confirm(text.revokeConfirm)) return;
    state.consentBusy = true;
    state.consentError = false;
    renderInvitationShell();
    const result = await api.revokeBetaConsent(item.cohortKey);
    state.consentBusy = false;
    state.consentError = !result?.ok;
    if (result?.ok) await refreshInvitationOnly();
    if (!showable()) {
      close();
      setEntryVisible(false);
      return;
    }
    if (state.open && invited() && !allowed(state.capabilities)) renderInvitationShell();
  }

  async function syncSubjectHub(hostContext = {}) {
    const nextSubject = String(hostContext.subjectKey || "").trim();
    const nextLanguage = normalizeLanguage(hostContext.language);
    const subjectChanged = state.subjectKey !== nextSubject;

    state.subjectKey = nextSubject;
    state.language = nextLanguage;
    renderEntryCopy();

    if (subjectChanged && state.open) close();
    if (state.subjectKey !== MATHEMATICS_KEY) {
      ++state.accessToken;
      state.capabilities = null;
      state.invitation = null;
      setEntryVisible(false);
      close();
      return false;
    }

    setEntryVisible(false);
    await refreshAccess();
    return showable();
  }

  async function open(hostContext = {}) {
    state.subjectKey = String(hostContext.subjectKey || state.subjectKey || "").trim();
    state.language = normalizeLanguage(hostContext.language || state.language);
    renderEntryCopy();

    if (state.subjectKey !== MATHEMATICS_KEY) {
      setEntryVisible(false);
      close();
      return false;
    }

    await refreshAccess();
    if (!showable()) return false;

    const root = rootEl();
    const hub = hubEl();
    const rendered = allowed(state.capabilities) ? renderLiveShell() : renderInvitationShell();
    if (!root || !hub || !rendered) {
      close();
      return false;
    }

    const active = document.activeElement;
    state.returnFocusEl = active && typeof active.focus === "function" && active.closest?.("#subject-hub-exam-prep-entry")
      ? active
      : entryButtonEl();
    root.hidden = false;
    root.setAttribute("aria-hidden", "false");
    hub.classList.add("exam-prep-host-open");
    state.open = true;
    focusHostRoot();
    return true;
  }

  function back() {
    if (!state.open) return false;
    close();
    return true;
  }

  function isOpen() {
    return state.open === true;
  }

  setEntryVisible(false);

  window.iClubExamPrep = Object.freeze({
    syncSubjectHub,
    refreshCapabilities,
    open,
    back,
    close,
    isOpen
  });
})();