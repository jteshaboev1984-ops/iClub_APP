(() => {
  "use strict";

  const ROOT_ID = "iclub-global-ai-root";
  const MARK_ID = "iclub-global-ai-mark";
  const PANEL_ID = "iclub-global-ai-panel";
  const HIDDEN_VIEWS = new Set(["splash", "registration", "certificate-verify"]);
  const PROTECTED_EXAM_PREP_TYPES = new Set(["diagnostic", "retest", "mixed", "timed", "paper"]);
  const MAX_INPUT_CHARS = 2000;
  const MAX_THREAD_MESSAGES = 40;
  const REQUEST_TIMEOUT_MS = 15000;

  const SUBJECT_ALIASES = {
    mathematics: ["mathematics", "математика", "matematika"],
    biology: ["biology", "биология", "biologiya"],
    chemistry: ["chemistry", "химия", "kimyo"],
    economics: ["economics", "экономика", "iqtisodiyot"],
    informatics: ["informatics", "информатика", "informatika"]
  };

  const COPY = {
    ru: {
      titleGeneral: "iClub AI",
      titleAcademic: "iClub AI Tutor",
      subtitleGeneral: "Помощник по iClub",
      open: "Открыть iClub AI",
      close: "Закрыть iClub AI",
      emptyTitle: "Чем помочь?",
      emptyCopy: "Выбери быстрый запрос или напиши свой вопрос.",
      input: "Спросить iClub AI…",
      send: "Отправить",
      appHere: "Что можно делать здесь?",
      appPractice: "Как работает Practice?",
      appTours: "Как работают Tours?",
      appResults: "Где смотреть результаты?",
      topicMain: "Объясни эту тему",
      topicSimple: "Объясни проще",
      topicAlternative: "Объясни по-другому",
      topicFocus: "Что важно запомнить?",
      assessmentStart: "AI Tutor свёрнут на время экзамена. Он снова станет доступен после завершения.",
      assessmentTap: "AI Tutor недоступен во время экзамена. После завершения ты сможешь разобрать результат и ошибки.",
      unavailable: "iClub AI сейчас недоступен. Попробуй позже.",
      timeout: "Ответ занял слишком много времени. Попробуй ещё раз.",
      limitTitle: "Лимит iClub AI достигнут",
      limitReset: "Доступ восстановится в {time}.",
      limitPending: "Доступ восстановится после текущего периода.",
      subjectNames: {
        mathematics: "Математика",
        biology: "Биология",
        chemistry: "Химия",
        economics: "Экономика",
        informatics: "Информатика"
      }
    },
    uz: {
      titleGeneral: "iClub AI",
      titleAcademic: "iClub AI Tutor",
      subtitleGeneral: "iClub bo‘yicha yordamchi",
      open: "iClub AI'ni ochish",
      close: "iClub AI'ni yopish",
      emptyTitle: "Qanday yordam beray?",
      emptyCopy: "Tezkor so‘rovni tanla yoki o‘z savolingni yoz.",
      input: "iClub AI'dan so‘rash…",
      send: "Yuborish",
      appHere: "Bu yerda nima qilish mumkin?",
      appPractice: "Practice qanday ishlaydi?",
      appTours: "Tours qanday ishlaydi?",
      appResults: "Natijalarni qayerda ko‘raman?",
      topicMain: "Shu mavzuni tushuntir",
      topicSimple: "Soddaroq tushuntir",
      topicAlternative: "Boshqacha tushuntir",
      topicFocus: "Nimani eslab qolish kerak?",
      assessmentStart: "AI Tutor imtihon vaqtida yig‘ildi. Imtihon tugagach yana mavjud bo‘ladi.",
      assessmentTap: "AI Tutor imtihon vaqtida mavjud emas. Tugagach natija va xatolarni tahlil qilishing mumkin.",
      unavailable: "iClub AI hozir mavjud emas. Keyinroq qayta urinib ko‘r.",
      timeout: "Javob juda uzoq davom etdi. Qayta urinib ko‘r.",
      limitTitle: "iClub AI limiti tugadi",
      limitReset: "Kirish {time} da tiklanadi.",
      limitPending: "Kirish joriy davrdan keyin tiklanadi.",
      subjectNames: {
        mathematics: "Matematika",
        biology: "Biologiya",
        chemistry: "Kimyo",
        economics: "Iqtisodiyot",
        informatics: "Informatika"
      }
    },
    en: {
      titleGeneral: "iClub AI",
      titleAcademic: "iClub AI Tutor",
      subtitleGeneral: "iClub assistant",
      open: "Open iClub AI",
      close: "Close iClub AI",
      emptyTitle: "How can I help?",
      emptyCopy: "Choose a quick prompt or type your own question.",
      input: "Ask iClub AI…",
      send: "Send",
      appHere: "What can I do here?",
      appPractice: "How does Practice work?",
      appTours: "How do Tours work?",
      appResults: "Where can I see results?",
      topicMain: "Explain this topic",
      topicSimple: "Explain more simply",
      topicAlternative: "Explain it differently",
      topicFocus: "What should I remember?",
      assessmentStart: "AI Tutor is collapsed during the exam. It will be available again after you finish.",
      assessmentTap: "AI Tutor is unavailable during the exam. After you finish, you can review your result and errors.",
      unavailable: "iClub AI is unavailable right now. Try again later.",
      timeout: "The answer took too long. Try again.",
      limitTitle: "iClub AI limit reached",
      limitReset: "Access will return at {time}.",
      limitPending: "Access will return after the current period.",
      subjectNames: {
        mathematics: "Mathematics",
        biology: "Biology",
        chemistry: "Chemistry",
        economics: "Economics",
        informatics: "Informatics"
      }
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
    viewObserver: null,
    tourObserver: null,
    contextObserver: null,
    contextTimer: null,
    resetTimer: null,
    busy: false,
    activeRequestId: null,
    context: null,
    usageExhausted: false,
    resetAt: null,
    threads: new Map(),
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

  function normalizeSubjectText(value) {
    return String(value || "").toLowerCase().replace(/\s+/g, " ").trim();
  }

  function subjectKeyFromText(value) {
    const text = normalizeSubjectText(value);
    for (const [key, aliases] of Object.entries(SUBJECT_ALIASES)) {
      if (aliases.some((alias) => text === alias || text.includes(alias))) return key;
    }
    return "";
  }

  function subjectName(key) {
    return copy().subjectNames?.[key] || key || "";
  }

  function examPrepSkillContext() {
    const host = document.getElementById("exam-prep-host-root");
    if (!host || host.hidden || host.getAttribute("aria-hidden") === "true") return null;
    const screen = host.querySelector("[data-ep-ai-skill-detail][data-ep-ai-skill-component]");
    if (!screen) return null;

    const skillCode = String(screen.getAttribute("data-ep-ai-skill-detail") || "").trim().toUpperCase();
    const componentCode = String(screen.getAttribute("data-ep-ai-skill-component") || "").trim().toUpperCase();
    if (!["P1", "P5"].includes(componentCode) || !skillCode.startsWith(componentCode + "-")) return null;

    return {
      threadKey: "mathematics",
      subjectKey: "mathematics",
      scopeCode: "exam_prep",
      academic: true,
      componentCode,
      skillCode,
      subjectLabel: subjectName("mathematics"),
      subtitle: `${subjectName("mathematics")} · ${componentCode}`
    };
  }

  function resolveContext() {
    const view = activeViewName();
    if (view === "courses") {
      const skill = examPrepSkillContext();
      if (skill) return skill;

      const title = String(document.getElementById("subject-hub-title")?.textContent || "").trim();
      const key = subjectKeyFromText(title);
      if (key) {
        return {
          threadKey: key,
          subjectKey: key,
          scopeCode: "global",
          academic: true,
          componentCode: "",
          skillCode: "",
          subjectLabel: subjectName(key),
          subtitle: subjectName(key)
        };
      }
    }

    return {
      threadKey: "general",
      subjectKey: "general",
      scopeCode: "global",
      academic: false,
      componentCode: "",
      skillCode: "",
      subjectLabel: "",
      subtitle: copy().subtitleGeneral
    };
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

  function thread(key) {
    const threadKey = key || "general";
    if (!state.threads.has(threadKey)) {
      state.threads.set(threadKey, { messages: [] });
    }
    return state.threads.get(threadKey);
  }

  function appendMessage(threadKey, role, text, kind = "message") {
    const target = thread(threadKey);
    target.messages.push({
      role,
      kind,
      text: String(text || "").trim()
    });
    if (target.messages.length > MAX_THREAD_MESSAGES) {
      target.messages.splice(0, target.messages.length - MAX_THREAD_MESSAGES);
    }
  }

  function formatResetTime(value) {
    if (!value) return "";
    const date = new Date(value);
    if (!Number.isFinite(date.getTime())) return "";
    try {
      return new Intl.DateTimeFormat(locale() === "uz" ? "uz-UZ" : locale() === "en" ? "en-GB" : "ru-RU", {
        hour: "2-digit",
        minute: "2-digit"
      }).format(date);
    } catch {
      return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    }
  }

  function limitText() {
    const c = copy();
    const time = formatResetTime(state.resetAt);
    return time ? c.limitReset.replace("{time}", time) : c.limitPending;
  }

  function scheduleResetRefresh() {
    if (state.resetTimer) clearTimeout(state.resetTimer);
    state.resetTimer = null;
    if (!state.usageExhausted || !state.resetAt) return;

    const at = new Date(state.resetAt).getTime();
    if (!Number.isFinite(at)) return;
    const delay = Math.max(250, Math.min(2147480000, at - Date.now() + 500));
    state.resetTimer = setTimeout(() => {
      state.usageExhausted = false;
      state.resetAt = null;
      renderPanel();
      void refreshBootstrap();
    }, delay);
  }

  function setUsageExhausted(resetAt) {
    state.usageExhausted = true;
    state.resetAt = resetAt || state.resetAt || null;
    scheduleResetRefresh();
  }

  function destroyShell() {
    root()?.remove();
    document.documentElement.classList.remove("iclub-global-ai-active");
    state.lastBlocked = false;
  }

  function closePanel() {
    const p = panel();
    if (!p || p.hidden) return;
    p.hidden = true;
    mark()?.setAttribute("aria-expanded", "false");
  }

  function quickPrompts(ctx) {
    const c = copy();
    if (ctx?.subjectKey === "mathematics"
        && ctx?.scopeCode === "exam_prep"
        && ctx?.componentCode
        && ctx?.skillCode) {
      return [
        { key: "topic_main", label: c.topicMain },
        { key: "topic_simple", label: c.topicSimple },
        { key: "topic_alternative", label: c.topicAlternative },
        { key: "topic_focus", label: c.topicFocus }
      ];
    }

    const view = activeViewName();
    if (["profile", "ratings", "certificates", "archive"].includes(view)) {
      return [
        { key: "app_help_results", label: c.appResults },
        { key: "app_help_here", label: c.appHere },
        { key: "app_help_practice", label: c.appPractice }
      ];
    }

    return [
      { key: "app_help_here", label: c.appHere },
      { key: "app_help_practice", label: c.appPractice },
      { key: "app_help_tours", label: c.appTours }
    ];
  }

  function createMessageNode(message) {
    const row = document.createElement("div");
    row.className = `iclub-global-ai-message is-${message.role}${message.kind === "notice" ? " is-notice" : ""}`;
    const bubble = document.createElement("div");
    bubble.className = "iclub-global-ai-bubble";
    bubble.textContent = message.text;
    row.appendChild(bubble);
    return row;
  }

  function typingNode() {
    const row = document.createElement("div");
    row.className = "iclub-global-ai-message is-assistant is-typing";
    row.setAttribute("aria-label", "iClub AI");
    const bubble = document.createElement("div");
    bubble.className = "iclub-global-ai-bubble";
    bubble.innerHTML = '<span></span><span></span><span></span>';
    row.appendChild(bubble);
    return row;
  }

  function renderMessages() {
    const p = panel();
    if (!p || !state.context) return;
    const body = p.querySelector("[data-global-ai-messages]");
    const empty = p.querySelector("[data-global-ai-empty]");
    if (!body || !empty) return;

    body.replaceChildren();
    const messages = thread(state.context.threadKey).messages;
    empty.hidden = messages.length > 0 || state.busy;
    messages.forEach((message) => body.appendChild(createMessageNode(message)));
    if (state.busy) body.appendChild(typingNode());

    queueMicrotask(() => {
      const scroll = p.querySelector("[data-global-ai-scroll]");
      if (scroll) scroll.scrollTop = scroll.scrollHeight;
    });
  }

  function renderQuickPrompts() {
    const p = panel();
    if (!p || !state.context) return;
    const host = p.querySelector("[data-global-ai-quick]");
    if (!host) return;
    host.replaceChildren();

    const prompts = quickPrompts(state.context);
    for (const prompt of prompts) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "iclub-global-ai-quick-btn";
      button.textContent = prompt.label;
      button.disabled = state.busy || state.usageExhausted || currentBlocked();
      button.addEventListener("click", () => {
        if (button.disabled) return;
        button.classList.add("is-sent");
        void sendMessage({ promptKey: prompt.key, displayText: prompt.label, userText: "" });
      });
      host.appendChild(button);
    }
  }

  function renderLimit() {
    const p = panel();
    if (!p) return;
    const box = p.querySelector("[data-global-ai-limit]");
    const title = p.querySelector("[data-global-ai-limit-title]");
    const text = p.querySelector("[data-global-ai-limit-text]");
    if (!box || !title || !text) return;
    box.hidden = !state.usageExhausted;
    if (state.usageExhausted) {
      title.textContent = copy().limitTitle;
      text.textContent = limitText();
    }
  }

  function renderComposer() {
    const p = panel();
    if (!p) return;
    const input = p.querySelector("[data-global-ai-input]");
    const send = p.querySelector("[data-global-ai-send]");
    if (!input || !send) return;

    input.placeholder = copy().input;
    input.maxLength = MAX_INPUT_CHARS;
    input.disabled = state.busy || state.usageExhausted || currentBlocked();
    send.disabled = input.disabled || !String(input.value || "").trim();
    send.setAttribute("aria-label", copy().send);
  }

  function renderHeader() {
    const p = panel();
    if (!p || !state.context) return;
    const title = p.querySelector("[data-global-ai-title]");
    const subtitle = p.querySelector("[data-global-ai-subtitle]");
    const close = p.querySelector("[data-global-ai-close]");
    if (title) title.textContent = state.context.academic ? copy().titleAcademic : copy().titleGeneral;
    if (subtitle) subtitle.textContent = state.context.subtitle || copy().subtitleGeneral;
    if (close) close.setAttribute("aria-label", copy().close);
  }

  function renderEmpty() {
    const p = panel();
    if (!p) return;
    const title = p.querySelector("[data-global-ai-empty-title]");
    const text = p.querySelector("[data-global-ai-empty-copy]");
    if (title) title.textContent = copy().emptyTitle;
    if (text) text.textContent = copy().emptyCopy;
  }

  function renderPanel() {
    if (!panel()) return;
    renderHeader();
    renderEmpty();
    renderMessages();
    renderQuickPrompts();
    renderLimit();
    renderComposer();
  }

  function ensurePanel() {
    const existing = panel();
    if (existing) {
      renderPanel();
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
      <div class="iclub-global-ai-scroll" data-global-ai-scroll>
        <div class="iclub-global-ai-empty" data-global-ai-empty>
          <div class="iclub-global-ai-empty-title" data-global-ai-empty-title></div>
          <div class="iclub-global-ai-empty-copy" data-global-ai-empty-copy></div>
        </div>
        <div class="iclub-global-ai-messages" data-global-ai-messages aria-live="polite"></div>
      </div>
      <div class="iclub-global-ai-quick" data-global-ai-quick></div>
      <div class="iclub-global-ai-limit" data-global-ai-limit hidden>
        <strong data-global-ai-limit-title></strong>
        <span data-global-ai-limit-text></span>
      </div>
      <div class="iclub-global-ai-composer">
        <textarea rows="1" maxlength="2000" data-global-ai-input></textarea>
        <button type="button" class="iclub-global-ai-send" data-global-ai-send>
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h13M13 7l5 5-5 5"/></svg>
        </button>
      </div>
    `;

    p.querySelector("[data-global-ai-close]")?.addEventListener("click", closePanel);
    const input = p.querySelector("[data-global-ai-input]");
    const send = p.querySelector("[data-global-ai-send]");

    input?.addEventListener("input", () => renderComposer());
    input?.addEventListener("keydown", (event) => {
      if (event.key !== "Enter" || event.shiftKey || event.isComposing) return;
      event.preventDefault();
      const text = String(input.value || "").trim();
      if (text) void sendMessage({ promptKey: "", displayText: text, userText: text });
    });
    send?.addEventListener("click", () => {
      const text = String(input?.value || "").trim();
      if (text) void sendMessage({ promptKey: "", displayText: text, userText: text });
    });

    host.appendChild(p);
    renderPanel();
    return p;
  }

  function openPanel() {
    if (currentBlocked()) {
      showToast(copy().assessmentTap);
      return;
    }
    if (!isEligibleView()) return;
    if (!state.context) state.context = resolveContext();
    const p = ensurePanel();
    if (!p) return;
    p.hidden = false;
    mark()?.setAttribute("aria-expanded", "true");
    renderPanel();
  }

  function requestId() {
    try {
      return crypto.randomUUID();
    } catch {
      const part = () => Math.floor(Math.random() * 0xffffffff).toString(16).padStart(8, "0");
      return `${part()}-${part().slice(0,4)}-4${part().slice(1,4)}-8${part().slice(1,4)}-${part()}${part().slice(0,4)}`;
    }
  }

  async function invokeGlobalAi(body) {
    const client = window.sb;
    if (!client?.functions || typeof client.functions.invoke !== "function") {
      return { data: null, error: { message: "functions_unavailable" } };
    }

    return await Promise.race([
      client.functions.invoke("global-ai", { body }),
      new Promise((resolve) => setTimeout(() => resolve({ __globalAiTimedOut: true }), REQUEST_TIMEOUT_MS))
    ]);
  }

  async function sendMessage({ promptKey, displayText, userText }) {
    if (state.busy || currentBlocked() || state.usageExhausted || !state.context) return;

    const context = { ...state.context };
    const threadKey = context.threadKey;
    const cleanDisplay = String(displayText || "").trim();
    const cleanText = String(userText || "").trim().slice(0, MAX_INPUT_CHARS);
    if (!cleanDisplay) return;

    appendMessage(threadKey, "user", cleanDisplay);
    state.busy = true;
    state.activeRequestId = requestId();

    const p = panel();
    const input = p?.querySelector("[data-global-ai-input]");
    if (input) input.value = "";
    renderPanel();

    const started = performance.now();
    try {
      const result = await invokeGlobalAi({
        request_id: state.activeRequestId,
        locale: locale(),
        subject_key: context.subjectKey,
        scope_code: context.scopeCode,
        prompt_key: promptKey || "",
        user_text: cleanText,
        component_code: context.componentCode || "",
        skill_code: context.skillCode || ""
      });

      if (result?.__globalAiTimedOut === true) {
        appendMessage(threadKey, "assistant", copy().timeout, "notice");
        return;
      }

      const { data, error } = result || {};
      if (error || !data || typeof data !== "object") {
        appendMessage(threadKey, "assistant", copy().unavailable, "notice");
        return;
      }

      if (data.academic_state_changed !== false) {
        appendMessage(threadKey, "assistant", copy().unavailable, "notice");
        return;
      }

      const reason = String(data.reason || "");
      const message = String(data.message || "").trim();

      if (data.ok === true && message) {
        appendMessage(threadKey, "assistant", message);
        if (data.usage_exhausted === true) {
          setUsageExhausted(data.reset_at || null);
        }
        return;
      }

      if (reason === "active_assessment") {
        state.serverBlocked = true;
        closePanel();
        showToast(copy().assessmentStart);
        void refreshBootstrap();
        return;
      }

      if (reason === "usage_exhausted") {
        setUsageExhausted(data.reset_at || null);
        appendMessage(threadKey, "assistant", message || copy().limitTitle, "notice");
        return;
      }

      appendMessage(threadKey, "assistant", message || copy().unavailable, "notice");
    } catch {
      appendMessage(threadKey, "assistant", copy().unavailable, "notice");
    } finally {
      const elapsed = performance.now() - started;
      if (elapsed < 180) {
        await new Promise((resolve) => setTimeout(resolve, 180 - elapsed));
      }
      state.busy = false;
      state.activeRequestId = null;
      renderPanel();
      if (state.usageExhausted) scheduleResetRefresh();
    }
  }

  function ensureShell() {
    let host = root();
    if (host) return host;

    host = document.createElement("div");
    host.id = ROOT_ID;
    host.className = "iclub-global-ai-root";
    host.setAttribute("data-global-ai-shell-version", "conversations-v1");

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

  function reconcileContext() {
    const next = resolveContext();
    const previousThread = state.context?.threadKey || "";
    state.context = next;

    if (previousThread && previousThread !== next.threadKey) {
      closePanel();
    }

    if (panel() && !panel().hidden) renderPanel();
  }

  function scheduleContextReconcile() {
    if (state.contextTimer) clearTimeout(state.contextTimer);
    state.contextTimer = setTimeout(() => {
      state.contextTimer = null;
      reconcileContext();
      reconcileShell();
    }, 35);
  }

  function reconcileShell({ announceBlock = false } = {}) {
    const allowed = state.bootstrap?.visible === true;
    if (!allowed || !isEligibleView()) {
      closePanel();
      const host = root();
      if (host) host.hidden = true;
      document.documentElement.classList.remove("iclub-global-ai-active");
      state.lastBlocked = currentBlocked();
      return;
    }

    if (!state.context) state.context = resolveContext();
    const host = ensureShell();
    host.hidden = false;
    document.documentElement.classList.add("iclub-global-ai-active");

    const blocked = currentBlocked();
    const m = mark();
    if (m) {
      const c = copy();
      m.classList.toggle("is-assessment-blocked", blocked);
      m.setAttribute("aria-label", blocked ? c.assessmentTap : c.open);
      m.removeAttribute("aria-disabled");
      if (blocked) m.setAttribute("aria-expanded", "false");
    }

    if (blocked) closePanel();
    if (announceBlock && blocked && !state.lastBlocked) {
      showToast(copy().assessmentStart);
    }

    state.lastBlocked = blocked;
    renderPanel();
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
    scheduleContextReconcile();
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
        state.usageExhausted = data.usage_exhausted === true;
        state.resetAt = state.usageExhausted ? (data.reset_at || null) : null;
        if (state.usageExhausted) scheduleResetRefresh();
        reconcileTourBlock();
        reconcileContext();
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
      state.tourObserver?.disconnect?.();
      state.tourObserver = new MutationObserver(() => reconcileTourBlock({ announce: true }));
      state.tourObserver.observe(tourQuiz, { attributes: true, attributeFilter: ["class"] });
    }

    state.viewObserver?.disconnect?.();
    state.viewObserver = new MutationObserver(scheduleContextReconcile);
    document.querySelectorAll(".view[data-view]").forEach((view) => {
      state.viewObserver.observe(view, { attributes: true, attributeFilter: ["class"] });
    });

    state.contextObserver?.disconnect?.();
    state.contextObserver = new MutationObserver(scheduleContextReconcile);
    const subjectTitle = document.getElementById("subject-hub-title");
    if (subjectTitle) {
      state.contextObserver.observe(subjectTitle, { childList: true, subtree: true, characterData: true });
    }
    const examRoot = document.getElementById("exam-prep-host-root");
    if (examRoot) {
      state.contextObserver.observe(examRoot, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["hidden", "aria-hidden", "data-ep-ai-skill-detail", "data-ep-ai-skill-component"]
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
    state.context = resolveContext();
    setTimeout(() => { void refreshBootstrap(); }, 0);
  }

  window.iClubGlobalAiShell = Object.freeze({
    version: "global_ai_conversations_v1",
    refresh: () => refreshBootstrap(),
    close: () => closePanel(),
    context: () => ({ ...(state.context || resolveContext()) })
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", attach, { once: true });
  } else {
    attach();
  }
})();