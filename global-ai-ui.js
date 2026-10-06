(() => {
  "use strict";

  const ROOT_ID = "iclub-global-ai-root";
  const MARK_ID = "iclub-global-ai-mark";
  const PANEL_ID = "iclub-global-ai-panel";
  const HIDDEN_VIEWS = new Set(["splash", "registration", "certificate-verify"]);
  const PROTECTED_EXAM_PREP_TYPES = new Set(["diagnostic", "retest", "mixed", "timed", "paper"]);

  const COPY = {
    ru: {
      title: "iClub AI",
      subtitle: "Учебный помощник",
      open: "Открыть iClub AI",
      close: "Закрыть iClub AI",
      emptyTitle: "Чем помочь?",
      emptyCopy: "Спроси о текущей теме, результате или ошибке.",
      input: "Спросить iClub AI…",
      assessmentStart: "AI Tutor свёрнут на время экзамена. Он снова станет доступен после завершения.",
      assessmentTap: "AI Tutor недоступен во время экзамена. После завершения ты сможешь разобрать результат и ошибки."
    },
    uz: {
      title: "iClub AI",
      subtitle: "O‘quv yordamchisi",
      open: "iClub AI'ni ochish",
      close: "iClub AI'ni yopish",
      emptyTitle: "Qanday yordam beray?",
      emptyCopy: "Joriy mavzu, natija yoki xato haqida so‘ra.",
      input: "iClub AI'dan so‘rash…",
      assessmentStart: "AI Tutor imtihon vaqtida yig‘ildi. Imtihon tugagach yana mavjud bo‘ladi.",
      assessmentTap: "AI Tutor imtihon vaqtida mavjud emas. Tugagach natija va xatolarni tahlil qilishing mumkin."
    },
    en: {
      title: "iClub AI",
      subtitle: "Learning assistant",
      open: "Open iClub AI",
      close: "Close iClub AI",
      emptyTitle: "How can I help?",
      emptyCopy: "Ask about the current topic, result, or error.",
      input: "Ask iClub AI…",
      assessmentStart: "AI Tutor is collapsed during the exam. It will be available again after you finish.",
      assessmentTap: "AI Tutor is unavailable during the exam. After you finish, you can review your result and errors."
    }
  };

  const state = {
    bootstrap: null,
    serverBlocked: false,
    examPrepBlocked: false,
    tourBlocked: false,
    lastBlocked: false,
    toastTimer: null,
    bootstrapInFlight: null,
    observer: null,
    destroyed: false
  };

  function locale() {
    const appLang = String(window.i18n?.getLang?.() || "").toLowerCase();
    if (appLang === "ru" || appLang === "uz" || appLang === "en") return appLang;
    const serverLang = String(state.bootstrap?.locale || "").toLowerCase();
    return serverLang === "uz" || serverLang === "en" ? serverLang : "ru";
  }

  function copy() {
    return COPY[locale()] || COPY.ru;
  }

  function activeViewName() {
    const active = document.querySelector(".view.is-active");
    return String(active?.dataset?.view || "").trim().toLowerCase();
  }

  function isEligibleView() {
    const name = activeViewName();
    return Boolean(name) && !HIDDEN_VIEWS.has(name);
  }

  function showToast(text, duration = 3000) {
    const toast = document.getElementById("toast");
    if (!toast || !text) return;
    toast.textContent = text;
    toast.classList.add("is-show");
    if (state.toastTimer) clearTimeout(state.toastTimer);
    state.toastTimer = setTimeout(() => {
      toast.classList.remove("is-show");
      state.toastTimer = null;
    }, duration);
  }

  function currentBlocked() {
    return state.serverBlocked || state.examPrepBlocked || state.tourBlocked;
  }

  function root() {
    return document.getElementById(ROOT_ID);
  }

  function mark() {
    return document.getElementById(MARK_ID);
  }

  function panel() {
    return document.getElementById(PANEL_ID);
  }

  function destroyShell() {
    root()?.remove();
    state.lastBlocked = false;
  }

  function panelCopyRefresh() {
    const c = copy();
    const p = panel();
    if (!p) return;
    const title = p.querySelector("[data-global-ai-title]");
    const subtitle = p.querySelector("[data-global-ai-subtitle]");
    const emptyTitle = p.querySelector("[data-global-ai-empty-title]");
    const emptyCopy = p.querySelector("[data-global-ai-empty-copy]");
    const input = p.querySelector("[data-global-ai-input-shell]");
    const close = p.querySelector("[data-global-ai-close]");
    if (title) title.textContent = c.title;
    if (subtitle) subtitle.textContent = c.subtitle;
    if (emptyTitle) emptyTitle.textContent = c.emptyTitle;
    if (emptyCopy) emptyCopy.textContent = c.emptyCopy;
    if (input) input.textContent = c.input;
    if (close) close.setAttribute("aria-label", c.close);
  }

  function ensurePanel() {
    const existing = panel();
    if (existing) {
      panelCopyRefresh();
      return existing;
    }

    const host = root();
    if (!host) return null;

    const p = document.createElement("section");
    p.id = PANEL_ID;
    p.className = "iclub-global-ai-panel";
    p.setAttribute("role", "dialog");
    p.setAttribute("aria-modal", "false");
    p.setAttribute("aria-label", "iClub AI");
    p.hidden = true;
    p.innerHTML = `
      <header class="iclub-global-ai-head">
        <div class="iclub-global-ai-head-copy">
          <div class="iclub-global-ai-title" data-global-ai-title></div>
          <div class="iclub-global-ai-subtitle" data-global-ai-subtitle></div>
        </div>
        <button class="iclub-global-ai-close" type="button" data-global-ai-close>
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 7l10 10M17 7 7 17"/></svg>
        </button>
      </header>
      <div class="iclub-global-ai-body" data-global-ai-body>
        <div class="iclub-global-ai-empty">
          <div class="iclub-global-ai-empty-title" data-global-ai-empty-title></div>
          <div class="iclub-global-ai-empty-copy" data-global-ai-empty-copy></div>
        </div>
      </div>
      <div class="iclub-global-ai-composer" aria-hidden="true">
        <div class="iclub-global-ai-input-shell" data-global-ai-input-shell></div>
      </div>
    `;

    p.querySelector("[data-global-ai-close]")?.addEventListener("click", closePanel);
    host.appendChild(p);
    panelCopyRefresh();
    return p;
  }

  function closePanel() {
    const p = panel();
    if (!p || p.hidden) return;
    p.hidden = true;
    mark()?.setAttribute("aria-expanded", "false");
  }

  function openPanel() {
    if (currentBlocked()) {
      showToast(copy().assessmentTap);
      return;
    }
    if (!isEligibleView()) return;
    const p = ensurePanel();
    if (!p) return;
    p.hidden = false;
    mark()?.setAttribute("aria-expanded", "true");
    p.querySelector("[data-global-ai-close]")?.focus({ preventScroll: true });
  }

  function ensureShell() {
    let host = root();
    if (host) return host;

    host = document.createElement("div");
    host.id = ROOT_ID;
    host.className = "iclub-global-ai-root";
    host.setAttribute("data-global-ai-shell-version", "v1");

    const button = document.createElement("button");
    button.id = MARK_ID;
    button.className = "iclub-global-ai-mark";
    button.type = "button";
    button.setAttribute("aria-haspopup", "dialog");
    button.setAttribute("aria-expanded", "false");
    button.innerHTML = '<img class="iclub-global-ai-mark-logo" src="logo.png" alt="" aria-hidden="true">';
    button.addEventListener("click", () => {
      if (currentBlocked()) {
        showToast(copy().assessmentTap);
        return;
      }
      const p = panel();
      if (p && !p.hidden) closePanel();
      else openPanel();
    });

    host.appendChild(button);
    document.body.appendChild(host);
    return host;
  }

  function reconcileShell({ announceBlock = false } = {}) {
    const allowed = state.bootstrap?.visible === true;
    if (!allowed || !isEligibleView()) {
      closePanel();
      const host = root();
      if (host) host.hidden = true;
      state.lastBlocked = currentBlocked();
      return;
    }

    const host = ensureShell();
    host.hidden = false;

    const blocked = currentBlocked();
    const m = mark();
    if (m) {
      const c = copy();
      m.classList.toggle("is-assessment-blocked", blocked);
      m.setAttribute("aria-label", c.open);
      m.setAttribute("aria-disabled", blocked ? "true" : "false");
      if (blocked) m.setAttribute("aria-expanded", "false");
    }

    if (blocked) closePanel();

    if (announceBlock && blocked && !state.lastBlocked) {
      showToast(copy().assessmentStart);
    }

    state.lastBlocked = blocked;
    panelCopyRefresh();
  }

  function reconcileTourBlock({ announce = false } = {}) {
    const tourQuiz = document.getElementById("courses-tour-quiz");
    const blocked = Boolean(tourQuiz?.classList.contains("is-active"));
    const changed = blocked !== state.tourBlocked;
    state.tourBlocked = blocked;
    reconcileShell({ announceBlock: announce && changed && blocked });
  }

  function handleExamPrepSession(event) {
    const session = event?.detail?.session || {};
    const type = String(session?.session_type || "").toLowerCase();
    const status = String(session?.status || "active").toLowerCase();
    const blocked = status === "active" && PROTECTED_EXAM_PREP_TYPES.has(type);
    const changed = blocked !== state.examPrepBlocked;
    state.examPrepBlocked = blocked;
    reconcileShell({ announceBlock: changed && blocked });
  }

  function handleExamPrepEnded() {
    state.examPrepBlocked = false;
    reconcileTourBlock();
    void refreshBootstrap();
  }

  async function refreshBootstrap() {
    if (state.bootstrapInFlight) return state.bootstrapInFlight;
    const client = window.sb;
    if (!client?.rpc) {
      state.bootstrap = null;
      destroyShell();
      return null;
    }

    state.bootstrapInFlight = (async () => {
      try {
        const { data, error } = await client.rpc("get_iclub_ai_ui_bootstrap_v1");
        if (error || !data || typeof data !== "object") {
          state.bootstrap = null;
          destroyShell();
          return null;
        }
        state.bootstrap = data;
        state.serverBlocked = data.assessment_blocked === true;
        reconcileTourBlock();
        reconcileShell();
        return data;
      } catch {
        state.bootstrap = null;
        destroyShell();
        return null;
      } finally {
        state.bootstrapInFlight = null;
      }
    })();

    return state.bootstrapInFlight;
  }

  function attachObservers() {
    const tourQuiz = document.getElementById("courses-tour-quiz");
    if (tourQuiz) {
      const observer = new MutationObserver(() => reconcileTourBlock({ announce: true }));
      observer.observe(tourQuiz, { attributes: true, attributeFilter: ["class"] });
      state.observer = observer;
    }

    const main = document.getElementById("main");
    if (main) {
      const viewObserver = new MutationObserver(() => reconcileShell());
      viewObserver.observe(main, {
        attributes: true,
        subtree: true,
        attributeFilter: ["class"]
      });
    }
  }

  function attach() {
    if (state.destroyed) return;

    window.addEventListener("iclub:exam-prep-session", handleExamPrepSession);
    window.addEventListener("iclub:exam-prep-session-ended", handleExamPrepEnded);
    window.addEventListener("iclub:global-ai-bootstrap-refresh", () => { void refreshBootstrap(); });
    window.addEventListener("focus", () => { void refreshBootstrap(); });

    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape") closePanel();
    });

    try {
      window.sb?.auth?.onAuthStateChange?.(() => {
        queueMicrotask(() => { void refreshBootstrap(); });
      });
    } catch {}

    attachObservers();
    setTimeout(() => { void refreshBootstrap(); }, 0);
  }

  window.iClubGlobalAiShell = Object.freeze({
    version: "global_ai_shell_v1",
    refresh: () => refreshBootstrap(),
    close: () => closePanel()
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", attach, { once: true });
  } else {
    attach();
  }
})();
