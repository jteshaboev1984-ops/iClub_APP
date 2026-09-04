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
    consentError: false
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
        alpha: "Ichki alpha",
        note: "Bu host bridge faqat server ruxsati bilan ochiladi. Synthetic o‘quvchi ma’lumotlari ishlatilmaydi.",
        p1: "P1 · Pure Mathematics 1",
        p5: "P5 · Probability & Statistics 1",
        inviteTitle: "Exam Prep yopiq beta taklifi",
        inviteSub: "Ishtirokni tasdiqlash kerak",
        inviteKicker: "Controlled beta",
        inviteBody: "Siz Cambridge AS Mathematics Exam Prep yopiq sinoviga taklif qilindingiz. Beta davomida javoblaringiz, bajarish vaqti va o‘quv progressi funksiyani tekshirish va yaxshilash uchun ishlatiladi. Ishtirok ixtiyoriy; beta xatolarni o‘z ichiga olishi mumkin. Mavjud Tours va Practice tarixingiz o‘zgartirilmaydi.",
        wave: "Rejalashtirilgan to‘lqin",
        mode: "Rejim",
        capacity: "Beta sig‘imi",
        consent: "Ishtirok etishga roziman",
        consented: "Rozilik qayd etildi",
        consentedBody: "Sizning roziligingiz saqlandi. Bu hali Exam Prep kirishini yoqmaydi — kirish alohida xavfsiz wave orqali faollashtiriladi.",
        revoke: "Rozilikni bekor qilish",
        revokeConfirm: "Controlled beta ishtirokidan voz kechishni tasdiqlaysizmi?",
        busy: "Saqlanmoqda…",
        error: "Amalni bajarib bo‘lmadi. Qayta urinib ko‘ring.",
        core: "Core",
        ai: "AI Assist",
        mentor: "Mentor Care"
      };
    }
    if (lang === "en") {
      return {
        title: "Cambridge AS Mathematics · Exam Prep",
        subtitle: "Paper 1 + Paper 5",
        alpha: "Internal alpha",
        note: "This host bridge opens only after server authorization. No synthetic learner data is shown here.",
        p1: "P1 · Pure Mathematics 1",
        p5: "P5 · Probability & Statistics 1",
        inviteTitle: "Exam Prep controlled beta invitation",
        inviteSub: "Participation confirmation required",
        inviteKicker: "Controlled beta",
        inviteBody: "You have been invited to the closed Cambridge AS Mathematics Exam Prep beta. During the beta, your answers, completion time and learning progress will be used to test and improve the feature. Participation is voluntary and the beta may contain errors. Your existing Tours and Practice history will not be changed.",
        wave: "Planned wave",
        mode: "Mode",
        capacity: "Beta capacity",
        consent: "I agree to participate",
        consented: "Consent recorded",
        consentedBody: "Your consent has been saved. This does not enable Exam Prep access yet; access is activated separately through a guarded beta wave.",
        revoke: "Withdraw consent",
        revokeConfirm: "Do you want to withdraw from the controlled beta?",
        busy: "Saving…",
        error: "The action could not be completed. Please try again.",
        core: "Core",
        ai: "AI Assist",
        mentor: "Mentor Care"
      };
    }
    return {
      title: "Cambridge AS Mathematics · Exam Prep",
      subtitle: "Paper 1 + Paper 5",
      alpha: "Внутренняя alpha",
      note: "Этот host bridge открывается только после серверного разрешения. Synthetic learner data здесь не показываются.",
      p1: "P1 · Pure Mathematics 1",
      p5: "P5 · Probability & Statistics 1",
      inviteTitle: "Приглашение в закрытую beta Exam Prep",
      inviteSub: "Нужно подтвердить участие",
      inviteKicker: "Controlled beta",
      inviteBody: "Вы приглашены в закрытое тестирование Cambridge AS Mathematics Exam Prep. Во время beta ваши ответы, время выполнения и учебный прогресс будут использоваться для проверки и улучшения функции. Участие добровольное; beta может содержать ошибки. Ваша существующая история Tours и Practice не изменяется.",
      wave: "Планируемая волна",
      mode: "Режим",
      capacity: "Вместимость beta",
      consent: "Я согласен участвовать",
      consented: "Согласие сохранено",
      consentedBody: "Ваше согласие записано. Это ещё не включает доступ к Exam Prep — доступ активируется отдельно через защищённую beta-волну.",
      revoke: "Отозвать согласие",
      revokeConfirm: "Вы подтверждаете отказ от участия в controlled beta?",
      busy: "Сохраняем…",
      error: "Не удалось выполнить действие. Попробуйте ещё раз.",
      core: "Core",
      ai: "AI Assist",
      mentor: "Mentor Care"
    };
  }

  function entryEl() { return $("#subject-hub-exam-prep-entry"); }
  function rootEl() { return $("#exam-prep-host-root"); }
  function hubEl() { return $("#courses-subject-hub"); }

  function setEntryVisible(visible) {
    const el = entryEl();
    if (!el) return;
    el.hidden = !visible;
    el.setAttribute("aria-hidden", visible ? "false" : "true");
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
    const title = $("#subject-hub-exam-prep-title");
    const sub = $("#subject-hub-exam-prep-sub");
    const inviteOnly = invited() && !allowed(state.capabilities);
    if (title) title.textContent = inviteOnly ? text.inviteTitle : text.title;
    if (sub) sub.textContent = inviteOnly ? text.inviteSub : text.subtitle;
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
          <div class="ep-host-component-card"><strong>${text.p1}</strong><span>45 canonical skills</span></div>
          <div class="ep-host-component-card"><strong>${text.p5}</strong><span>36 canonical skills</span></div>
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
          <div><span>${text.wave}</span><strong>${item.activationWave}</strong></div>
          <div><span>${text.capacity}</span><strong>${item.capacity || 12}</strong></div>
        </div>
        ${error}
        <div class="ep-host-actions">${action}</div>
      </section>`;

    root.querySelector('[data-ep-beta-action="grant"]')?.addEventListener("click", handleGrantConsent);
    root.querySelector('[data-ep-beta-action="revoke"]')?.addEventListener("click", handleRevokeConsent);
    return true;
  }

  function close() {
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

    root.hidden = false;
    root.setAttribute("aria-hidden", "false");
    hub.classList.add("exam-prep-host-open");
    state.open = true;
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
