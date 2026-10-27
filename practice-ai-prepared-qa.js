/* QA-only Practice prepared summaries. Dormant unless explicitly enabled in QA Preview.
   Does not call models, grade answers, write progress or access localStorage. */
(() => {
  "use strict";
  const qaEnabled = () => window.__ICLUB_PRACTICE_PREPARED_QA__ === true;

  const URL = "https://mmmduffgpvwjdpruzikw.supabase.co";
  const ROOT = "courses-practice-result";
  const CARD = "iclub-ai-prepared-qa-card";
  const TEXT = {
    ru: {
      title: "Помощь после практики",
      note: "Объяснение на основе сохранённого результата.",
      result: "Объяснить результат",
      next: "Что делать дальше?",
      loading: "Проверяем результат…",
      unavailable: "Сейчас это объяснение недоступно. Ваш результат сохранён."
    },
    uz: {
      title: "Amaliyotdan keyingi yordam",
      note: "Saqlangan natija asosidagi izoh.",
      result: "Natijani tushuntirish",
      next: "Keyin nima qilaman?",
      loading: "Natija tekshirilmoqda…",
      unavailable: "Bu izoh hozircha mavjud emas. Natijangiz saqlangan."
    },
    en: {
      title: "Help after Practice",
      note: "An explanation based on your saved result.",
      result: "Explain my result",
      next: "What should I do next?",
      loading: "Checking your result…",
      unavailable: "This explanation is unavailable right now. Your result is saved."
    }
  };
  const locale = () => {
    const lang = String(window.i18n?.getLang?.() || "ru");
    return lang === "en" || lang === "uz" ? lang : "ru";
  };
  const validId = x => Number.isSafeInteger(x) && x > 0;
  const screen = () => document.getElementById(ROOT);
  const attemptId = el => Number(el?.dataset?.practiceAiAttemptId || 0);
  let gateKey = "", gateState = "idle", gateTicket = 0;

  function invalidateGate(){
    gateTicket++;
    gateKey = "";
    gateState = "idle";
  }

  async function serverAllows(id, lang) {
    const sb = window.sb;
    if (!sb?.auth?.getSession || !sb?.auth?.getUser ||
        !window.iClubAiV21BetaClient?.status) return false;
    // Consent + beta entitlement must be confirmed before sending a probe.
    const access = await window.iClubAiV21BetaClient.status();
    if (access?.eligible !== true || access?.consented !== true) return false;
    const { data: auth, error: authError } = await sb.auth.getSession();
    const token = String(auth?.session?.access_token || "");
    const owner = String(auth?.session?.user?.id || "");
    const key = String(sb.supabaseKey || "");
    if (authError || token.length < 24 || owner.length < 30 || key.length < 24 ||
        String(sb.supabaseUrl || "").replace(/\/+$/, "") !== URL) return false;
    const response = await fetch(URL + "/functions/v1/iclub-ai-practice-prepared", {
      method:"POST", mode:"cors", cache:"no-store", credentials:"omit",
      headers:{ Authorization:"Bearer " + token, apikey:key,
                "Content-Type":"application/json" },
      body:JSON.stringify({intent:"practice_prepared",
        request_id:window.crypto.randomUUID(),purpose:"practice_visibility",
        attempt_ref:id,question_ref:null,locale:lang}),
      signal:AbortSignal.timeout(7000)
    });
    if (!response.ok) return false;
    const result = await response.json().catch(() => null);
    const { data: now, error: nowError } = await sb.auth.getUser();
    return !nowError && now?.user?.id === owner &&
      result?.ok === true && result?.available === true &&
      result?.mode === "availability" &&
      result?.provider_called === false &&
      result?.academic_state_changed === false;
  }

  async function ask(purpose, id, card) {
    const el = screen();
    if (!el?.classList.contains("is-active") || attemptId(el) !== id ||
        (!qaEnabled() && (gateState !== "ready" ||
          gateKey !== id + ":" + locale()))) return;
    if (card.dataset.busy === "true") return;
    const copy = TEXT[locale()];
    const output = card.querySelector("[data-prepared-output]");
    const buttons = card.querySelectorAll("button");
    const sb = window.sb;
    if (!sb?.auth?.getSession || !sb?.auth?.getUser) {
      output.textContent = copy.unavailable; output.hidden = false; return;
    }
    card.dataset.busy = "true";
    buttons.forEach(b => b.disabled = true);
    output.hidden = false;
    output.textContent = copy.loading;
    try {
      const { data: auth, error: authError } = await sb.auth.getSession();
      const token = String(auth?.session?.access_token || "");
      const userId = String(auth?.session?.user?.id || "");
      const key = String(sb.supabaseKey || "");
      if (authError || token.length < 24 || userId.length < 30 ||
          key.length < 24 || String(sb.supabaseUrl || "").replace(/\/+$/, "") !== URL) {
        throw Error("auth_unavailable");
      }
      const response = await fetch(URL + "/functions/v1/iclub-ai-practice-prepared", {
        method: "POST", mode: "cors", cache: "no-store", credentials: "omit",
        headers: { Authorization: "Bearer " + token, apikey: key,
                   "Content-Type": "application/json" },
        body: JSON.stringify({
          intent: "practice_prepared",
          request_id: window.crypto.randomUUID(),
          purpose, attempt_ref: id, question_ref: null, locale: locale()
        }),
        signal: AbortSignal.timeout(20000)
      });
      const payload = await response.json().catch(() => null);
      const { data: now, error: nowError } = await sb.auth.getUser();
      const access = await window.iClubAiV21BetaClient?.status?.();
      if (access?.eligible !== true || nowError || now?.user?.id !== userId ||
          !el.isConnected || !el.classList.contains("is-active") ||
          attemptId(el) !== id || card.isConnected !== true) return;
      if (!response.ok || payload?.ok !== true ||
          payload?.mode !== "verified_summary" ||
          payload?.provider_called !== false ||
          payload?.academic_state_changed !== false ||
          typeof payload?.message !== "string" ||
          payload.message.length < 20 || payload.message.length > 1200) {
        throw Error("unavailable");
      }
      output.textContent = payload.message;
    } catch {
      if (card.isConnected && attemptId(screen()) === id) {
        output.textContent = copy.unavailable;
      }
    } finally {
      card.dataset.busy = "false";
      buttons.forEach(b => b.disabled = false);
    }
  }

  function render() {
    const el = screen();
    if (!el) return;
    const id = attemptId(el);
    const active = el.classList.contains("is-active");
    const old = el.querySelector("[" + "data-iclub-ai-prepared-qa-card" + "]");
    if (!active || !validId(id)) {
      old?.remove();
      if(gateKey) invalidateGate();
      return;
    }
    const lang = locale();
    const identity = id + ":" + lang;
    if (!qaEnabled() && (gateKey !== identity || gateState !== "ready")) {
      old?.remove();
      if(gateKey === identity) return;
      gateKey = identity;
      gateState = "pending";
      const ticket = ++gateTicket;
      void serverAllows(id,lang).then(approved=>{
        if (ticket !== gateTicket) return;
        const current = screen();
        if (!current?.classList.contains("is-active") ||
            attemptId(current) !== id || locale() !== lang) return;
        gateState = approved ? "ready" : "denied";
        if (approved) render();
      }).catch(()=>{
        if (ticket === gateTicket) gateState = "denied";
      });
      return;
    }
    if (old && Number(old.dataset.attemptId) === id && old.dataset.locale === lang) return;
    old?.remove();

    const copy = TEXT[lang];
    const card = document.createElement("section");
    card.className = "card iclub-ai-prepared-qa";
    card.id = CARD;
    card.dataset.iclubAiPreparedQaCard = "1";
    card.dataset.attemptId = String(id);
    card.dataset.locale = lang;

    const title = document.createElement("h3");
    title.className = "iclub-ai-prepared-qa-title";
    title.textContent = copy.title;
    const note = document.createElement("p");
    note.className = "muted";
    note.textContent = copy.note;
    const actions = document.createElement("div");
    actions.className = "iclub-ai-prepared-qa-actions";
    for (const [purpose, label] of [
      ["practice_result", copy.result], ["practice_next_step", copy.next]
    ]) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "btn";
      button.textContent = label;
      button.addEventListener("click", () => void ask(purpose, id, card));
      actions.appendChild(button);
    }
    const output = document.createElement("div");
    output.className = "iclub-ai-prepared-qa-output";
    output.setAttribute("data-prepared-output", "1");
    output.setAttribute("role", "status");
    output.setAttribute("aria-live", "polite");
    output.hidden = true;
    card.append(title, note, actions, output);
    const grid = el.querySelector(".cards-grid");
    if (grid?.parentNode) grid.parentNode.insertBefore(card, grid);
    else el.appendChild(card);
  }

  let attached = false;
  function attach() {
    if (attached) return false;
    const el = screen();
    if (!el) return false;
    attached = true;
    new MutationObserver(() => render()).observe(el, {
      attributes: true,
      attributeFilter: ["class", "data-practice-ai-attempt-id"]
    });
    document.addEventListener("iclub:practice-ai-context-changed", () => {
      // Re-evaluate eligibility after the app changes the saved attempt.
      if(!qaEnabled()) invalidateGate();
      render();
    });
    window.sb?.auth?.onAuthStateChange?.(() => {
      invalidateGate();
      screen()?.querySelector("[data-iclub-ai-prepared-qa-card]")?.remove();
      render();
    });
    render();
    return true;
  }
  window.iClubPracticePreparedQa = Object.freeze({ enableForQa: attach });
  if (document.readyState === "loading")
    document.addEventListener("DOMContentLoaded", attach, { once: true });
  else attach();
})();