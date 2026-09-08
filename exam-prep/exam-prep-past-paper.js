(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p203paper1";
  let observer = null;
  let queued = false;
  let loading = false;
  let lastSignature = "";

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
      title: "Oldingi imtihon ishlari",
      official: "Cambridge rasmiy materiallarini ochish",
      original: "iClub original to‘liq sinovlari",
      similar: "O‘xshash vaqtli mashqlar",
      note: "Rasmiy Cambridge materiallari ularning saytida ochiladi. iClub imtihon ishlari yoki baholash sxemalarining nusxalarini saqlamaydi."
    };
    if (language() === "en") return {
      title: "Past exam papers",
      official: "Open official Cambridge materials",
      original: "Original iClub full simulations",
      similar: "Similar timed practice",
      note: "Official Cambridge materials open on the Cambridge website. iClub does not store copies of exam papers or mark schemes."
    };
    return {
      title: "Прошлые экзаменационные работы",
      official: "Открыть официальные материалы Cambridge",
      original: "Оригинальные полные симуляции iClub",
      similar: "Похожая практика на время",
      note: "Официальные материалы Cambridge открываются на сайте Cambridge. iClub не хранит копии экзаменационных работ или схем оценивания."
    };
  }

  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }

  function ensureStyle() {
    if (document.querySelector("#ep-past-paper-style")) return;
    const style = document.createElement("style");
    style.id = "ep-past-paper-style";
    style.textContent = `
      .ep-past-paper{display:grid;gap:10px;margin-top:12px;padding:14px;border:1px solid rgba(127,127,127,.16);border-radius:14px;background:rgba(127,127,127,.045)}
      .ep-past-paper-head{display:flex;align-items:center;justify-content:space-between;gap:10px}.ep-past-paper-head strong{font-size:14px}
      .ep-past-paper-stats{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}.ep-past-paper-stat{display:grid;gap:2px;padding:10px;border-radius:10px;background:rgba(127,127,127,.06)}
      .ep-past-paper-stat span{font-size:11px;line-height:1.35;opacity:.72}.ep-past-paper-stat strong{font-size:16px}.ep-past-paper-note{font-size:11px;line-height:1.45;opacity:.74}
      .ep-past-paper-link{display:inline-flex;align-items:center;justify-content:center;text-decoration:none;text-align:center}
      @media(max-width:520px){.ep-past-paper-stats{grid-template-columns:1fr}.ep-past-paper-head{align-items:flex-start;flex-direction:column}}
    `;
    document.head.appendChild(style);
  }

  function removePanel() {
    rootEl()?.querySelectorAll("[data-ep-past-paper]").forEach(node => node.remove());
    lastSignature = "";
  }

  function assessmentIds(payload) {
    return new Set([
      ...(Array.isArray(payload?.original_full_simulations) ? payload.original_full_simulations : []),
      ...(Array.isArray(payload?.similar_practice) ? payload.similar_practice : [])
    ].map(row => Number(row?.assessment_id)).filter(Number.isFinite));
  }

  async function resolveComponent(buttonIds) {
    const api = internal.api;
    if (typeof api?.pastPaperCompanion !== "function") return null;
    const [p1, p5] = await Promise.all([
      api.pastPaperCompanion("P1", language()),
      api.pastPaperCompanion("P5", language())
    ]);
    const candidates = [p1, p5].filter(result => result?.ok && result.data);
    for (const result of candidates) {
      const ids = assessmentIds(result.data);
      if (buttonIds.some(id => ids.has(id))) return result.data;
    }
    return null;
  }

  function renderPanel(card, payload) {
    if (!card?.isConnected || !payload) return;
    const external = Array.isArray(payload.external_resources) ? payload.external_resources : [];
    const resource = external.find(row =>
      row?.rights_status === "metadata_only_external" &&
      /^https:\/\/www\.cambridgeinternational\.org\//i.test(String(row?.official_url || ""))
    );
    if (!resource) return;

    const copyright = payload.copyright_boundary || {};
    if (copyright.stores_official_question_content === true || copyright.stores_official_mark_schemes === true || copyright.stores_official_answer_keys === true || copyright.external_metadata_only !== true) return;

    ensureStyle();
    card.querySelectorAll("[data-ep-past-paper]").forEach(node => node.remove());
    const c = copy();
    const fullCount = Array.isArray(payload.original_full_simulations) ? payload.original_full_simulations.length : 0;
    const similarCount = Array.isArray(payload.similar_practice) ? payload.similar_practice.length : 0;
    const panel = document.createElement("section");
    panel.className = "ep-past-paper";
    panel.dataset.epPastPaper = String(payload.component_code || "");

    const head = document.createElement("div");
    head.className = "ep-past-paper-head";
    const title = document.createElement("strong");
    title.textContent = c.title;
    const link = document.createElement("a");
    link.className = "ep-live-btn secondary ep-past-paper-link";
    link.href = String(resource.official_url);
    link.target = "_blank";
    link.rel = "noopener noreferrer";
    link.textContent = c.official;
    head.append(title, link);

    const stats = document.createElement("div");
    stats.className = "ep-past-paper-stats";
    const stat1 = document.createElement("div");
    stat1.className = "ep-past-paper-stat";
    stat1.innerHTML = `<span></span><strong>${fullCount}</strong>`;
    stat1.querySelector("span").textContent = c.original;
    const stat2 = document.createElement("div");
    stat2.className = "ep-past-paper-stat";
    stat2.innerHTML = `<span></span><strong>${similarCount}</strong>`;
    stat2.querySelector("span").textContent = c.similar;
    stats.append(stat1, stat2);

    const note = document.createElement("div");
    note.className = "ep-past-paper-note";
    note.textContent = c.note;
    panel.append(head, stats, note);
    card.appendChild(panel);
  }

  async function hydrate() {
    queued = false;
    const root = rootEl();
    if (!root || root.hidden || !canUse()) {
      removePanel();
      return;
    }
    const buttons = Array.from(root.querySelectorAll("[data-ep-live-timed-start]"));
    if (!buttons.length || root.querySelector("[data-ep-live-submit]")) {
      removePanel();
      return;
    }
    const ids = buttons.map(button => Number(button.dataset.epLiveTimedStart)).filter(Number.isFinite).sort((a,b) => a-b);
    const signature = `${language()}|${ids.join(",")}`;
    if (loading || (lastSignature === signature && root.querySelector("[data-ep-past-paper]"))) return;
    loading = true;
    try {
      const payload = await resolveComponent(ids);
      if (!payload) { removePanel(); return; }
      const card = buttons[0]?.closest(".ep-live-card");
      if (!card?.isConnected) return;
      renderPanel(card, payload);
      lastSignature = signature;
    } catch (_) {
      removePanel();
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
    internal.pastPaperUiVersion = VERSION;
  }

  attach();
})();
