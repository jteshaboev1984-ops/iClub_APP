(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const MATHEMATICS_KEY = "mathematics";
  const state = {
    open: false,
    subjectKey: null,
    language: "ru",
    capabilityToken: 0,
    capabilities: null
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
        p5: "P5 · Probability & Statistics 1"
      };
    }
    if (lang === "en") {
      return {
        title: "Cambridge AS Mathematics · Exam Prep",
        subtitle: "Paper 1 + Paper 5",
        alpha: "Internal alpha",
        note: "This host bridge opens only after server authorization. No synthetic learner data is shown here.",
        p1: "P1 · Pure Mathematics 1",
        p5: "P5 · Probability & Statistics 1"
      };
    }
    return {
      title: "Cambridge AS Mathematics · Exam Prep",
      subtitle: "Paper 1 + Paper 5",
      alpha: "Внутренняя alpha",
      note: "Этот host bridge открывается только после серверного разрешения. Synthetic learner data здесь не показываются.",
      p1: "P1 · Pure Mathematics 1",
      p5: "P5 · Probability & Statistics 1"
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

  function renderEntryCopy() {
    const text = labels(state.language);
    const title = $("#subject-hub-exam-prep-title");
    const sub = $("#subject-hub-exam-prep-sub");
    if (title) title.textContent = text.title;
    if (sub) sub.textContent = text.subtitle;
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

  function close() {
    state.open = false;
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

  async function refreshCapabilities() {
    const token = ++state.capabilityToken;
    const api = internal.api;
    if (!api || typeof api.capabilities !== "function") {
      state.capabilities = null;
      setEntryVisible(false);
      close();
      return null;
    }

    const result = await api.capabilities();
    if (token !== state.capabilityToken) return state.capabilities;

    if (!result?.ok) {
      state.capabilities = null;
      setEntryVisible(false);
      close();
      return null;
    }

    state.capabilities = result.data;
    const visible = state.subjectKey === MATHEMATICS_KEY && allowed(state.capabilities);
    setEntryVisible(visible);
    if (!visible) close();
    return state.capabilities;
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
      ++state.capabilityToken;
      state.capabilities = null;
      setEntryVisible(false);
      close();
      return false;
    }

    setEntryVisible(false);
    await refreshCapabilities();
    return allowed(state.capabilities);
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

    await refreshCapabilities();
    if (!allowed(state.capabilities)) return false;

    const root = rootEl();
    const hub = hubEl();
    if (!root || !hub || !renderLiveShell()) {
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
