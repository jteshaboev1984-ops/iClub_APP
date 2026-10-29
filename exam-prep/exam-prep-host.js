(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const MATHEMATICS_KEY = "mathematics";
  const ECONOMICS_KEY = "economics";
  const CHEMISTRY_KEY = "chemistry";
  const CHEMISTRY_PRELAUNCH_INVITATIONS_ENABLED = false;
  const state = {
    open: false,
    subjectKey: null,
    language: "ru",
    accessToken: 0,
    capabilities: null,
    economicsShell: null,
    chemistryShell: null,
    chemistryEntryShell: null,
    chemistryTheoryCatalog: null,
    chemistryOffer: null,
    chemistryConsentBusy: false,
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
        note: "P1 va P5 natijalari alohida hisoblanadi. Tours tarixi saqlanadi. Mathematics Practice yangilangan savollar bilan yangidan boshlanadi.",
        p1: "P1 · Pure Mathematics 1",
        p5: "P5 · Probability & Statistics 1",
        skills: "ko‘nikma",
        entryBadge: "Cambridge AS · Mathematics",
        entryBadgeAi: "Cambridge AS · Mathematics · AI",
        entryTitle: "Exam Prep",
        comingSoonBadge: "Ishlab chiqilmoqda",
        economicsLimitedBadge: "Kirish cheklangan",
        economicsLimitedDesc: "Economics Exam Prep hozircha faqat sinov ishtirokchilari uchun ochiq.",
        economicsLimitedNote: "Practice orqali o‘rganishni davom ettirishingiz va Toursda jadval bo‘yicha qatnashishingiz mumkin.",
        comingSoonDesc: "Bu fan bo‘yicha imtihonga tayyorgarlik ishlab chiqilmoqda.",
        comingSoonNote: "Hozircha Practice va Tours orqali mashq qilishingiz mumkin.",
        comingSoonCta: "Batafsil",
        comingSoonClose: "Tushunarli",
        entryDesc: "Paper 1 va Paper 5 bo‘yicha shaxsiy tayyorgarlik yo‘li: kirish tekshiruvi, haftalik reja, mavzular, xatolar va vaqtli mashqlar.",
        entryP1: "Pure Mathematics 1 · 45 ko‘nikma",
        entryP5: "Probability & Statistics 1 · 36 ko‘nikma",
        entryNote: "Tours tarixi saqlanadi. Mathematics Practice yangidan boshlanadi.",
        entryAiNote: "AI yordamchisi Exam Prep’da mavjud: natijalar, reja, mavzular va qayd etilgan xatolarni tushuntiradi.",
        entryCta: "Exam Prepni ochish",
      };
    }
    if (lang === "en") {
      return {
        title: "Cambridge AS Mathematics · Exam Prep",
        subtitle: "Paper 1 + Paper 5",
        alpha: "Exam preparation",
        note: "P1 and P5 results are tracked separately. Your Tours history stays unchanged. Mathematics Practice starts fresh with the updated question set.",
        p1: "P1 · Pure Mathematics 1",
        p5: "P5 · Probability & Statistics 1",
        skills: "skills",
        entryBadge: "Cambridge AS · Mathematics",
        entryBadgeAi: "Cambridge AS · Mathematics · AI",
        entryTitle: "Exam Prep",
        comingSoonBadge: "In development",
        economicsLimitedBadge: "Limited access",
        economicsLimitedDesc: "Economics Exam Prep is currently available only to testing participants.",
        economicsLimitedNote: "You can keep learning in Practice and join Tours when they open.",
        comingSoonDesc: "Exam preparation for this subject is in development.",
        comingSoonNote: "You can continue learning through Practice and Tours in the meantime.",
        comingSoonCta: "Learn more",
        comingSoonClose: "Got it",
        entryDesc: "A personal route for Paper 1 and Paper 5: entry check, weekly plan, syllabus work, corrections and timed practice.",
        entryP1: "Pure Mathematics 1 · 45 skills",
        entryP5: "Probability & Statistics 1 · 36 skills",
        entryNote: "Tours history stays unchanged. Mathematics Practice starts fresh.",
        entryAiNote: "AI Tutor is available in Exam Prep for progress, plans, topics and recorded mistakes.",
        entryCta: "Open Exam Prep",
      };
    }
    return {
      title: "Cambridge AS Mathematics · Exam Prep",
      subtitle: "Paper 1 + Paper 5",
      alpha: "Подготовка к экзамену",
      note: "Результаты P1 и P5 учитываются отдельно. История Tours сохраняется. Mathematics Practice начинается заново с обновлёнными вопросами.",
      p1: "P1 · Pure Mathematics 1",
      p5: "P5 · Probability & Statistics 1",
      skills: "навыков",
      entryBadge: "Cambridge AS · Mathematics",
      entryBadgeAi: "Cambridge AS · Mathematics · ИИ",
      entryTitle: "Exam Prep",
      comingSoonBadge: "В разработке",
        economicsLimitedBadge: "Доступ ограничен",
        economicsLimitedDesc: "Economics Exam Prep сейчас доступен только участникам тестирования.",
        economicsLimitedNote: "Вы можете продолжать заниматься в Практике и участвовать в Турах по расписанию.",
      comingSoonDesc: "Экзаменационная подготовка по этому предмету находится в разработке.",
      comingSoonNote: "Пока вы можете продолжать обучение через Practice и Tours.",
      comingSoonCta: "Подробнее",
      comingSoonClose: "Понятно",
      entryDesc: "Персональный маршрут по Paper 1 и Paper 5: входная проверка, недельный план, темы, исправление ошибок и практика на время.",
      entryP1: "Pure Mathematics 1 · 45 навыков",
      entryP5: "Probability & Statistics 1 · 36 навыков",
      entryNote: "История Tours сохраняется. Mathematics Practice начинается заново.",
      entryAiNote: "ИИ-помощник доступен в Exam Prep: объясняет прогресс, план, темы и зафиксированные ошибки.",
      entryCta: "Открыть Exam Prep",
    };
  }

  function entryEl() { return $("#subject-hub-exam-prep-entry"); }
  function entryButtonEl() { return entryEl()?.querySelector('[data-action="open-exam-prep"]') || null; }
  function rootEl() { return $("#exam-prep-host-root"); }
  function hubEl() { return $("#courses-subject-hub"); }

  function canRestoreFocus(el) {
    if (!el || typeof el.focus !== "function" || !el.isConnected) return false;
    if (!state.subjectKey || (state.subjectKey === MATHEMATICS_KEY && !showable())) return false;
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
    const fallback = $("#subject-hub-exam-prep-placeholder");
    if (fallback) {
      fallback.hidden = !!visible;
      fallback.setAttribute("aria-hidden", visible ? "true" : "false");
    }
    if (hub) hub.classList.toggle("exam-prep-available", visible === true);
  }

  function setExamPrepPeerStatus(mode) {
    const fallback = $("#subject-hub-exam-prep-placeholder");
    if (!fallback) return;
    const badge = $("#subject-hub-exam-prep-placeholder-badge");
    const note = $("#subject-hub-exam-prep-placeholder-sub");
    const copy = {
      checking: { ru:["Проверяем доступ","Подготовка к экзаменам Cambridge AS"], uz:["Kirish tekshirilmoqda","Cambridge AS imtihoniga tayyorgarlik"], en:["Checking access","Cambridge AS exam preparation"] },
      restricted: { ru:["Доступ ограничен","Для Mathematics участие в Exam Prep — по приглашению"], uz:["Kirish cheklangan","Mathematics Exam Prep uchun taklif kerak"], en:["Restricted access","Mathematics Exam Prep is invitation-only"] },
      unavailable: { ru:["Сейчас недоступно","Не удалось проверить доступ. Попробуйте открыть предмет позже."], uz:["Hozircha mavjud emas","Kirishni tekshirib bo‘lmadi. Keyinroq qayta urinib ko‘ring."], en:["Currently unavailable","Could not check access. Try reopening the subject later."] }
    };
    const row = (copy[mode] || copy.checking)[state.language] || (copy[mode] || copy.checking).ru;
    fallback.dataset.peerStatus = mode;
    if (badge) badge.textContent = row[0];
    if (note) note.textContent = row[1];
  }

  function allowed(caps) {
    return Boolean(
      caps &&
      caps.coreAccess === true &&
      caps.killSwitch === false &&
      caps.rolloutState !== "off"
    );
  }

  function showable() {
    return (state.subjectKey === MATHEMATICS_KEY && allowed(state.capabilities)) ||
      (state.subjectKey === ECONOMICS_KEY && state.economicsShell?.enabled === true) ||
      (state.subjectKey === CHEMISTRY_KEY && (state.chemistryShell?.enabled === true || state.chemistryEntryShell?.enabled === true || state.chemistryTheoryCatalog?.ok === true));
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
    const aiActive = allowed(state.capabilities) && state.capabilities?.aiAssist === true;
    const econActive = state.subjectKey === ECONOMICS_KEY && state.economicsShell?.enabled === true;
    const chemTheory = state.subjectKey === CHEMISTRY_KEY && state.chemistryTheoryCatalog?.ok === true;
    const chemActive = state.subjectKey === CHEMISTRY_KEY &&
      (state.chemistryShell?.enabled === true || state.chemistryEntryShell?.enabled === true || chemTheory);
    const comingSoon = Boolean(state.subjectKey && state.subjectKey !== MATHEMATICS_KEY && !econActive && !chemActive);
    const economicsLimited = state.subjectKey === ECONOMICS_KEY && !econActive;
    const econSub = state.language === "uz"
      ? "Paper 1 va Paper 3: imtihon, javoblar va natijalar"
      : state.language === "en"
        ? "Paper 1 and Paper 3: exams, answers and results"
        : "Paper 1 и Paper 3: экзамены, ответы и результаты";
    const components = entry?.querySelector('.exam-prep-feature-components');
    if (components) components.style.display = comingSoon ? 'none' : '';
    if (entry) {
      entry.classList.toggle('is-coming-soon', comingSoon);
      entry.classList.toggle("has-ai-assist", aiActive);
      entry.setAttribute("data-ep-entry-mode", comingSoon ? "coming-soon" : "live");
      entry.setAttribute("data-ep-ai-visible", aiActive ? "true" : "false");
    }
    if (badge) badge.textContent = econActive ? "Cambridge · Economics 9708" : (comingSoon ? (economicsLimited ? text.economicsLimitedBadge : text.comingSoonBadge) : (aiActive ? text.entryBadgeAi : text.entryBadge));
    if (title) title.textContent = text.entryTitle;
    if (sub) sub.textContent = econActive ? econSub : (comingSoon ? (economicsLimited ? text.economicsLimitedDesc : text.comingSoonDesc) : text.entryDesc);
    if (p1) p1.textContent = econActive ? "Paper 1 · AS Level · 60 min" : text.entryP1;
    if (p5) p5.textContent = econActive ? "Paper 3 · A Level · 75 min" : text.entryP5;
    if (note) note.textContent = econActive ? econSub : (comingSoon ? (economicsLimited ? text.economicsLimitedNote : text.comingSoonNote) : (aiActive ? text.entryAiNote : text.entryNote));
    if (cta) cta.textContent = comingSoon ? text.comingSoonCta : text.entryCta;
    if (p5?.parentElement) p5.parentElement.style.display = chemActive ? "none" : "";
    if (chemActive) {
      const theoryOnly = chemTheory && state.chemistryShell?.enabled !== true &&
        state.chemistryEntryShell?.enabled !== true;
      if (theoryOnly) {
        if (badge) badge.textContent = "Cambridge · Chemistry 9701";
        if (sub) sub.textContent = state.language === "uz" ? "AS Level nazariyasi · 91 ta mavzu"
          : state.language === "en" ? "AS Level theory · 91 topics" : "Теория AS Level · 91 тема";
        if (p1) p1.textContent = state.language === "uz" ? "AS Level nazariyasi"
          : state.language === "en" ? "AS Level theory" : "Теория AS Level";
        if (note) note.textContent = state.language === "uz" ? "Imtihonlar va Tutor hali mavjud emas."
          : state.language === "en" ? "Exams and Tutor are not yet available."
          : "Экзамены и Tutor пока закрыты.";
        if (cta) cta.textContent = text.entryCta;
        return;
      }
      const entryOnly = state.chemistryEntryShell?.enabled === true &&
        state.chemistryShell?.enabled !== true;
      if (badge) badge.textContent = "Cambridge · Chemistry 9701";
      if (sub) sub.textContent = entryOnly
        ? (state.language === "uz" ? "Kirish tekshiruvi · 22 ta savol · 30 daqiqa"
          : state.language === "en" ? "Entry check · 22 questions · 30 minutes"
          : "Входная проверка · 22 вопроса · 30 минут")
        : (state.language === "uz" ? "Paper 1 · 40 ta savol · 75 daqiqa"
          : state.language === "en" ? "Paper 1 · 40 questions · 75 minutes"
          : "Paper 1 · 40 вопросов · 75 минут");
      if (p1) p1.textContent = entryOnly
        ? (state.language === "uz" ? "Kirish tekshiruvi · AS · 30 min"
          : state.language === "en" ? "Entry check · AS · 30 min"
          : "Входная проверка · AS · 30 мин")
        : "Paper 1 · AS Level · 75 min";
      if (note) note.textContent = state.language === "uz"
        ? "Javoblaringiz va avvalgi natijalaringiz saqlanadi."
        : state.language === "en" ? "Your answers and previous results remain saved."
        : "Ваши ответы и прежние результаты сохраняются.";
      if (cta) cta.textContent = text.entryCta;
    }
  }

  function chemistryBetaLabels() {
    if (state.language === "uz") return {
      headline: "Chemistry sinovida qatnashish",
      invitation: "Siz Mathematics Exam Prep sinovida qatnashyapsiz. Chemistry Paper 1 sinovida ham qatnashishga alohida rozilik bildirishingiz mumkin. Hozircha imtihon ochilmaydi va avvalgi natijalaringiz o‘zgarmaydi.",
      join: "Chemistry sinoviga roziman",pending:"Roziligingiz saqlandi. Chemistry ochilganda alohida xabar beriladi.",
    };
    if (state.language === "en") return {
      headline: "Chemistry beta participation",
      invitation: "You are participating in Mathematics Exam Prep testing. You may separately opt in to Chemistry Paper 1 testing. The paper is not available yet, and your existing results will not change.",
      join:"I agree to Chemistry testing",pending:"Your consent is saved. Chemistry access will be announced separately.",
    };
    return {
      headline:"Участие в тестировании Chemistry",
      invitation:"Вы участвуете в тестировании Mathematics Exam Prep. Вы можете отдельно согласиться попробовать Chemistry Paper 1. Сам экзамен пока закрыт, а прежние результаты останутся без изменений.",
      join:"Согласен участвовать в тестировании Chemistry",
      pending:"Ваше согласие сохранено. Открытие Chemistry будет объявлено отдельно.",
    };
  }

  async function updateChemistryConsent(revoke) {
    if (state.chemistryConsentBusy || state.subjectKey !== CHEMISTRY_KEY) return;
    const lex = chemistryBetaLabels();
    if (revoke && typeof window.confirm === "function" && !window.confirm(lex.confirmation)) return;
    state.chemistryConsentBusy = true;
    const token = state.accessToken;
    const root = rootEl();
    const buttons = root?.querySelectorAll?.('[data-chemistry-beta-action]');
    buttons?.forEach(button => { button.disabled = true; });
    try {
      const name = revoke ? "revoke_my_exam_prep_chemistry_consent_v1"
        : "grant_my_exam_prep_chemistry_consent_v1";
      const args = revoke ? {} : { p_acknowledgement: "I_CONSENT_TO_CHEMISTRY_P1_CONTROLLED_BETA_V1" };
      const response = await window.sb?.rpc?.(name,args);
      if (token !== state.accessToken || state.subjectKey !== CHEMISTRY_KEY) return;
      if (response?.error || response?.data?.ok !== true) throw new Error("not_saved");
      const status = await window.sb?.rpc?.("get_my_exam_prep_chemistry_beta_status_v1",{});
      if (token !== state.accessToken || state.subjectKey !== CHEMISTRY_KEY) return;
      state.chemistryOffer = status?.error ? null : status?.data;
      if (state.open && !state.chemistryShell?.enabled) renderComingSoonShell();
    } catch (_) {
      if (token === state.accessToken && state.open) {
        const note = document.createElement("p");
        note.className = "ep-host-note";
        note.setAttribute("role","alert");
        note.textContent = lex.error;
        root?.querySelector(".ep-host-coming-soon")?.append(note);
      }
    } finally {
      state.chemistryConsentBusy = false;
      buttons?.forEach(button => { button.disabled = false; });
    }
  }

  // STAGE03_EXAM_PREP_ALL_SUBJECTS_V1: presentation only, no assessment APIs.
  function renderComingSoonShell() {
    const root = rootEl();
    if (!root) return false;
    const text = labels(state.language);
    const shell = document.createElement('section');
    shell.className = 'ep-host-shell ep-host-coming-soon';
    shell.setAttribute('aria-label', text.entryTitle);
    const badge = document.createElement('div');
    badge.className = 'ep-host-kicker';
    badge.textContent = state.subjectKey === ECONOMICS_KEY ? text.economicsLimitedBadge : text.comingSoonBadge;
    const heading = document.createElement('h2');
    heading.className = 'ep-host-title';
    heading.textContent = text.entryTitle;
    const description = document.createElement('p');
    description.className = 'ep-host-note';
    description.textContent = state.subjectKey === ECONOMICS_KEY ? text.economicsLimitedDesc : text.comingSoonDesc;
    const note = document.createElement('p');
    note.className = 'ep-host-note';
    note.textContent = state.subjectKey === ECONOMICS_KEY ? text.economicsLimitedNote : text.comingSoonNote;
    const closeBtn = document.createElement('button');
    closeBtn.type = 'button';
    closeBtn.className = 'ep-host-btn ep-host-btn-secondary';
    closeBtn.textContent = text.comingSoonClose;
    closeBtn.addEventListener('click', close);
    shell.append(badge, heading, description, note);
    if (CHEMISTRY_PRELAUNCH_INVITATIONS_ENABLED && state.subjectKey === CHEMISTRY_KEY && state.chemistryOffer?.eligible === true) {
      const lex = chemistryBetaLabels();
      const group = document.createElement("div");
      group.className = "ep-host-component-card ep-host-chemistry-offer";
      const title = document.createElement("h3");
      title.className = "ep-host-chemistry-offer-title";
      title.textContent = lex.headline;
      const details = document.createElement("p");
      details.className = "ep-host-note";
      details.textContent = state.chemistryOffer.consented === true ? lex.pending : lex.invitation;
      group.append(title,details);
      const action = document.createElement("button");
      action.type = "button";
      action.className = state.chemistryOffer.consented === true
        ? "ep-host-btn ep-host-btn-secondary" : "ep-host-btn ep-host-btn-primary";
      action.setAttribute("data-chemistry-beta-action", "");
      action.textContent = state.chemistryOffer.consented === true ? lex.revoke : lex.join;
      action.addEventListener("click", () => updateChemistryConsent(state.chemistryOffer?.consented === true));
      group.append(action);
      shell.append(group);
    }
    shell.append(closeBtn);
    root.replaceChildren(shell);
    return true;
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

  function close() {
    internal.economicsNative?.unmount?.();
    internal.chemistryNative?.unmount?.();
    internal.chemistryEntryNative?.unmount?.();
    internal.chemistryRecheckNative?.unmount?.();
    internal.chemistryLabsNative?.unmount?.();
    internal.chemistryTheoryNative?.unmount?.();
    const shouldRestoreFocus = state.open && (showable() || (state.subjectKey && state.subjectKey !== MATHEMATICS_KEY));
    state.open = false;
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
      setExamPrepPeerStatus("unavailable");
      setEntryVisible(false);
      close();
      return null;
    }
    const capResult = await api.capabilities();
    if (token !== state.accessToken) return state.capabilities;
    state.capabilities = capResult?.ok ? capResult.data : null;
    renderEntryCopy();
    const visible = showable();
    if (!visible) setExamPrepPeerStatus(capResult?.ok ? "restricted" : "unavailable");
    setEntryVisible(visible);
    if (!visible) close();
    return state.capabilities;
  }

  async function refreshCapabilities() {
    if (state.subjectKey === ECONOMICS_KEY || state.subjectKey === CHEMISTRY_KEY) {
      return syncSubjectHub({ subjectKey: state.subjectKey, language: state.language });
    }
    return refreshAccess();
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
      const token = ++state.accessToken;
      state.capabilities = null;
      state.economicsShell = null;
      state.chemistryShell = null;
      state.chemistryEntryShell = null;
      state.chemistryTheoryCatalog = null;
      state.chemistryOffer = null;
      if (state.subjectKey === ECONOMICS_KEY) {
        try {
          const response = await window.sb?.rpc?.("get_my_exam_prep_program_shell_v1", {
            p_program_key: "economics_9708", p_language: state.language
          });
          if (token !== state.accessToken || state.subjectKey !== ECONOMICS_KEY) return false;
          const shell = response?.data;
          if (!response?.error && shell?.enabled === true &&
              shell.program_key === "economics_9708" && Array.isArray(shell.papers) &&
              ["P1","P3"].every(code => shell.papers.some(p => p.code === code && p.assessment_kind === "mcq"))) {
            state.economicsShell = shell;
          }
        } catch (_) { /* Keep the current coming-soon state when access is unavailable. */ }
      }
      if (state.subjectKey === CHEMISTRY_KEY) {
        try {
          const response = await window.sb?.rpc?.("get_my_exam_prep_chemistry_shell_v1", {
            p_language: state.language
          });
          if (token !== state.accessToken || state.subjectKey !== CHEMISTRY_KEY) return false;
          const shell = response?.data;
          if (!response?.error && shell?.enabled === true &&
              shell.program_key === "chemistry_9701" && Array.isArray(shell.papers) &&
              shell.papers.some(p => p.code === "P1" && p.assessment_kind === "mcq" && p.mcq_count === 40)) {
            state.chemistryShell = shell;
          }
        } catch (_) { /* Chemistry remains in development until access is explicitly granted. */ }
        if (token !== state.accessToken || state.subjectKey !== CHEMISTRY_KEY) return false;
        try {
          const response = await window.sb?.rpc?.("get_my_exam_prep_chemistry_entry_shell_v1", {
            p_language: state.language
          });
          if (token !== state.accessToken || state.subjectKey !== CHEMISTRY_KEY) return false;
          const shell = response?.data;
          if (!response?.error && shell?.enabled === true &&
              shell.program_key === "chemistry_9701" &&
              shell.assessment_code === "ENTRY" &&
              shell.item_count === 22 && shell.duration_seconds === 1800) {
            state.chemistryEntryShell = shell;
          }
        } catch (_) { /* Entry remains unavailable unless explicitly released. */ }
        if (CHEMISTRY_PRELAUNCH_INVITATIONS_ENABLED && !state.chemistryShell?.enabled && !state.chemistryEntryShell?.enabled) {
          try {
            const response = await window.sb?.rpc?.("get_my_exam_prep_chemistry_beta_status_v1",{});
            if (token !== state.accessToken || state.subjectKey !== CHEMISTRY_KEY) return false;
            if (!response?.error && response?.data?.eligible === true)
              state.chemistryOffer = response.data;
          } catch (_) { /* Non-eligible users still see normal in-development message. */ }
        }
      }
      if (state.subjectKey === CHEMISTRY_KEY) {
        try {
          const response = await window.sb?.rpc?.("iclub_exam_chemistry_j24_theory_catalog_v1", {p_language:state.language});
          if (token !== state.accessToken || state.subjectKey !== CHEMISTRY_KEY) return false;
          const catalog = response?.data;
          if (!response?.error && catalog?.ok === true && catalog?.scope === "AS_theory_only" &&
              catalog.count === 91 && catalog.locale === state.language &&
              internal.chemistryTheoryNative?.validCatalog?.(catalog) === true) {
            state.chemistryTheoryCatalog = catalog;
          }
        } catch (_) { /* AS Theory remains unavailable without independent owner approval. */ }
      }
      renderEntryCopy();
      if (state.subjectKey === CHEMISTRY_KEY && !subjectChanged && state.open &&
          state.chemistryTheoryCatalog?.ok === true &&
          state.chemistryShell?.enabled !== true && state.chemistryEntryShell?.enabled !== true &&
          internal.chemistryTheoryNative?.mount?.({root:rootEl(),catalog:state.chemistryTheoryCatalog,
            language:state.language,onBack:close}) === true) {
        setEntryVisible(true);
        return true;
      }
      if (state.subjectKey === CHEMISTRY_KEY && !subjectChanged &&
          state.open && (state.chemistryShell?.enabled === true ||
                         state.chemistryEntryShell?.enabled === true)) {
        internal.chemistryNative?.setLanguage?.(state.language);
        internal.chemistryEntryNative?.setLanguage?.(state.language);
        internal.chemistryRecheckNative?.setLanguage?.(state.language);
        setEntryVisible(true);
        return true;
      }
      close();
      setEntryVisible(Boolean(state.subjectKey));
      return Boolean(state.subjectKey);
    }

    setExamPrepPeerStatus("checking");
    setEntryVisible(false);
    const expectedToken = state.accessToken + 1;
    const timeout = setTimeout(() => {
      if (state.subjectKey === MATHEMATICS_KEY && state.accessToken === expectedToken && entryEl()?.hidden) {
        setExamPrepPeerStatus("unavailable");
      }
    }, 15000);
    try {
      await refreshAccess();
      return showable();
    } catch (_) {
      if (state.subjectKey === MATHEMATICS_KEY && state.accessToken === expectedToken) {
        setExamPrepPeerStatus("unavailable");
        setEntryVisible(false);
      }
      return false;
    } finally {
      clearTimeout(timeout);
    }
  }

  async function open(hostContext = {}) {
    // Fail closed when an out-of-date subject card tries to open Mathematics
    // from a different visible subject hub.
    const requestedSubject = String(hostContext.subjectKey || "").trim().toLowerCase();
    const visibleSubject = String(hubEl()?.dataset?.subjectKey || "").trim().toLowerCase();
    if (!requestedSubject || (visibleSubject && requestedSubject !== visibleSubject)) {
      close();
      return false;
    }
    state.subjectKey = requestedSubject;
    state.language = normalizeLanguage(hostContext.language || state.language);
    renderEntryCopy();

    if (state.subjectKey !== MATHEMATICS_KEY) {
      const root = rootEl();
      const hub = hubEl();
      if (!state.subjectKey || !root || !hub) return false;
      const economicsReady = state.subjectKey === ECONOMICS_KEY &&
        state.economicsShell?.enabled === true &&
        internal.economicsNative?.mount?.({
          root, shell: state.economicsShell, language: state.language, onBack: close
        }) === true;
      const mountChemistryEntry = () => internal.chemistryEntryNative?.mount?.({
        root, shell: state.chemistryEntryShell, language: state.language, onBack: close,
        onPaper: state.chemistryShell?.enabled === true ? () => {
          internal.chemistryEntryNative?.unmount?.();
          internal.chemistryNative?.mount?.({
            root, shell: state.chemistryShell, language: state.language,
            onBack: () => {
              internal.chemistryNative?.unmount?.();
              mountChemistryEntry();
            }
          });
        } : null
      }) === true;
      const chemistryEntryReady = state.subjectKey === CHEMISTRY_KEY &&
        state.chemistryEntryShell?.enabled === true && mountChemistryEntry();
      const chemistryPaperReady = state.subjectKey === CHEMISTRY_KEY &&
        !chemistryEntryReady && state.chemistryShell?.enabled === true &&
        internal.chemistryNative?.mount?.({
          root, shell: state.chemistryShell, language: state.language, onBack: close
        }) === true;
      const chemistryTheoryReady = state.subjectKey === CHEMISTRY_KEY &&
        !chemistryEntryReady && !chemistryPaperReady && state.chemistryTheoryCatalog?.ok === true &&
        internal.chemistryTheoryNative?.mount?.({root,catalog:state.chemistryTheoryCatalog,
          language:state.language,onBack:close}) === true;
      if (!economicsReady && !chemistryEntryReady && !chemistryPaperReady &&
          !chemistryTheoryReady && !renderComingSoonShell()) return false;
      state.returnFocusEl = entryButtonEl();
      root.hidden = false;
      root.setAttribute('aria-hidden', 'false');
      hub.classList.add('exam-prep-host-open');
      state.open = true;
      focusHostRoot();
      return true;
    }

    await refreshAccess();
    if (!showable()) return false;

    const root = rootEl();
    const hub = hubEl();
    const rendered = allowed(state.capabilities) && renderLiveShell();
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