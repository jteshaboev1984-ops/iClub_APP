(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p205threshold1";
  let observer = null;
  let queued = false;
  let loading = false;

  function rootEl() {
    return document.querySelector("#exam-prep-host-root");
  }

  function language() {
    try {
      const value = String(window.i18n?.getLang?.() || document.documentElement.lang || "ru").toLowerCase();
      return ["ru", "uz", "en"].includes(value) ? value : "ru";
    } catch (_) {
      return "ru";
    }
  }

  function copy() {
    if (language() === "uz") return {
      readiness: "Imtihon tayyorgarligi",
      title: "Joriy mezon",
      grade: "baho",
      note: "Bu Cambridge ushbu variant uchun e’lon qilgan eng so‘nggi chegaradir. iClub uni faqat joriy yo‘nalish sifatida ko‘rsatadi: kelajakdagi imtihon sessiyangiz uchun chegarani Cambridge alohida belgilaydi. Bu baho prognozi yoki kafolati emas.",
      separate: "P1 va P5 alohida baholanadi: bir komponentdagi kuchli natija ikkinchisining talablarini almashtirmaydi.",
      p1Special: "June 2026 sessiyasida 9709/12 ning dastlabki ishi 3–4 zonalarda bekor qilinib, imtihon xavfsizligi buzilgani sabab yangi ish bilan almashtirilgan.",
      p5Special: "June 2026 sessiyasida 9709/52 uchun 3–4 zonalarda imtihon xavfsizligi buzilgani sabab Cambridge maxsus hisoblangan ballardan foydalangan.",
      source: "Cambridge rasmiy jadvali"
    };
    if (language() === "en") return {
      readiness: "Exam readiness",
      title: "Current reference",
      grade: "grade",
      note: "This is the latest threshold published by Cambridge for this paper variant. iClub shows it only as a current reference: Cambridge sets the threshold for each future exam series separately. It is not a grade prediction or guarantee.",
      separate: "P1 and P5 are assessed separately: a strong result in one component does not replace the requirements of the other.",
      p1Special: "In the June 2026 series, the original 9709/12 paper in Zones 3–4 was cancelled and replaced after an exam-security breach.",
      p5Special: "In the June 2026 series, Cambridge used assessed marks for 9709/52 in Zones 3–4 after an exam-security breach.",
      source: "Official Cambridge table"
    };
    return {
      readiness: "Готовность к экзамену",
      title: "Текущий ориентир",
      grade: "оценка",
      note: "Это последний опубликованный Cambridge порог для данного варианта. iClub показывает его только как текущий ориентир: порог вашей будущей экзаменационной сессии Cambridge определит отдельно. Это не прогноз и не гарантия оценки.",
      separate: "P1 и P5 оцениваются отдельно: сильный результат одного компонента не заменяет требования другого.",
      p1Special: "В сессии June 2026 первоначальная работа 9709/12 в зонах 3–4 была отменена и заменена новой после нарушения безопасности экзамена.",
      p5Special: "В сессии June 2026 для 9709/52 в зонах 3–4 Cambridge применил специальный расчёт баллов после нарушения безопасности экзамена.",
      source: "Официальная таблица Cambridge"
    };
  }

  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }

  function removePanel() {
    rootEl()?.querySelectorAll("[data-ep-threshold-reference]").forEach(node => node.remove());
  }

  function readinessCard() {
    const root = rootEl();
    if (!root) return null;
    const c = copy();
    return Array.from(root.querySelectorAll(".ep-live-card")).find(card => {
      const heading = card.querySelector(".ep-live-head > strong");
      const text = String(heading?.textContent || "").trim();
      return /^(P1|P5)\b/.test(text) && text.includes(c.readiness);
    }) || null;
  }

  function componentFrom(card) {
    const text = String(card?.querySelector(".ep-live-head > strong")?.textContent || "").trim();
    const match = text.match(/^(P1|P5)\b/);
    return match ? match[1] : null;
  }

  function safeCambridgeUrl(value) {
    const url = String(value || "");
    return /^https:\/\/www\.cambridgeinternational\.org\//i.test(url) ? url : "";
  }

  function percent(value) {
    const number = Number(value);
    if (!Number.isFinite(number)) return "";
    const text = number.toFixed(1);
    return language() === "en" ? text : text.replace(".", ",");
  }

  function specialNote(code) {
    const c = copy();
    if (code === "paper12_replacement") return c.p1Special;
    if (code === "paper52_assessed_marks") return c.p5Special;
    return "";
  }

  function render(card, reference) {
    if (!card?.isConnected || !reference?.available) return;
    card.querySelectorAll("[data-ep-threshold-reference]").forEach(node => node.remove());

    const c = copy();
    const panel = document.createElement("section");
    panel.className = "ep-threshold-reference";
    panel.dataset.epThresholdReference = String(reference.reference_version || "latest");

    const title = document.createElement("strong");
    title.textContent = c.title;

    const main = document.createElement("div");
    main.className = "ep-threshold-reference-main";
    main.textContent = `${reference.paper_code || reference.component_code} · ${reference.exam_series || ""} · ${c.grade} ${reference.target_grade || ""}: ${Number(reference.raw_threshold_mark || 0)}/${Number(reference.maximum_raw_mark || 0)} (${percent(reference.threshold_pct)}%)`;

    const note = document.createElement("div");
    note.className = "ep-threshold-reference-note";
    const special = specialNote(reference.special_note_code);
    note.textContent = [c.note, special, c.separate].filter(Boolean).join(" ");

    panel.append(title, main, note);

    const sourceUrl = safeCambridgeUrl(reference.source_url);
    if (sourceUrl) {
      const link = document.createElement("a");
      link.href = sourceUrl;
      link.target = "_blank";
      link.rel = "noopener noreferrer";
      link.textContent = c.source;
      panel.appendChild(link);
    }

    const stats = card.querySelector(".ep-live-stats");
    if (stats) card.insertBefore(panel, stats);
    else card.appendChild(panel);
  }

  async function hydrate() {
    queued = false;
    const root = rootEl();
    if (!root || root.hidden || !canUse()) {
      removePanel();
      return;
    }

    const card = readinessCard();
    if (!card) {
      removePanel();
      return;
    }

    const component = componentFrom(card);
    if (!component || loading || typeof internal.api?.readiness !== "function") return;
    if (card.querySelector("[data-ep-threshold-reference]")) return;

    loading = true;
    try {
      const result = await internal.api.readiness(component);
      const reference = result?.ok ? result.data?.threshold_reference : null;
      if (!reference?.available || reference.reference_only !== true) return;
      if (!card.isConnected || componentFrom(card) !== component) return;
      render(card, reference);
    } catch (_) {
      // Read-only enhancement: readiness remains usable without this note.
    } finally {
      loading = false;
    }
  }

  function queueHydrate() {
    if (queued) return;
    queued = true;
    queueMicrotask(hydrate);
  }

  function attach() {
    const root = rootEl();
    if (!root) { setTimeout(attach, 50); return; }
    if (observer) observer.disconnect();
    observer = new MutationObserver(queueHydrate);
    observer.observe(root, { childList: true, subtree: true, attributes: true, attributeFilter: ["hidden", "aria-hidden"] });
    queueHydrate();
    internal.thresholdReferenceUiVersion = VERSION;
  }

  function loadRecoveryLayer() {
    try {
      const src = document?.currentScript?.src || "";
      if (!src || !/exam-prep-threshold-reference\.js(?:\?|$)/.test(src)) return;
      if (document.querySelector('script[data-exam-prep-recovery]')) return;
      const script = document.createElement("script");
      script.dataset.examPrepRecovery = "true";
      script.src = src.replace(/exam-prep-threshold-reference\.js(?:\?.*)?$/, "exam-prep-recovery.js?v=p207recovery1");
      document.head.appendChild(script);
    } catch (_) {
      // Recovery UI is additive; Core remains available if this optional layer cannot load.
    }
  }

  loadRecoveryLayer();
  attach();
})();
