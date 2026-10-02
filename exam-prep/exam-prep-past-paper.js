(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p203paper2";
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
      available: "Hozir mavjud", show: "Ro‘yxatda ko‘rsatish",
      kindFull: "To‘liq variant", kindModified: "Moslashtirilgan variant", kindTimed: "Vaqtli mashq", marks: "ball",
      note: "Rasmiy Cambridge materiallari ularning saytida ochiladi. iClub imtihon ishlari yoki baholash sxemalarining nusxalarini saqlamaydi."
    };
    if (language() === "en") return {
      title: "Past exam papers",
      official: "Open official Cambridge materials",
      original: "Original iClub full simulations",
      similar: "Similar timed practice",
      available: "Available now", show: "Show in list",
      kindFull: "Full paper", kindModified: "Modified paper", kindTimed: "Timed practice", marks: "marks",
      note: "Official Cambridge materials open on the Cambridge website. iClub does not store copies of exam papers or mark schemes."
    };
    return {
      title: "Прошлые экзаменационные работы",
      official: "Открыть официальные материалы Cambridge",
      original: "Оригинальные полные симуляции iClub",
      similar: "Похожая практика на время",
      available: "Доступно сейчас", show: "Показать в списке",
      kindFull: "Полный вариант", kindModified: "Адаптированный вариант", kindTimed: "Практика на время", marks: "баллов",
      note: "Официальные материалы Cambridge открываются на сайте Cambridge. iClub не хранит копии экзаменационных работ или схем оценивания."
    };
  }

  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
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

  function learnerKind(row, c) {
    if (row?.attempt_kind === "full_paper") return c.kindFull;
    if (row?.attempt_kind === "modified_paper") return c.kindModified;
    return c.kindTimed;
  }

  function visiblePracticeRows(card, payload) {
    const visibleIds = new Set(
      Array.from(card?.querySelectorAll?.("[data-ep-live-timed-start]") || [])
        .map(button => Number(button.dataset.epLiveTimedStart))
        .filter(Number.isFinite)
    );
    const merged = [
      ...(Array.isArray(payload?.original_full_simulations) ? payload.original_full_simulations : []),
      ...(Array.isArray(payload?.similar_practice) ? payload.similar_practice : [])
    ];
    const seen = new Set();
    return merged.filter(row => {
      const id = Number(row?.assessment_id);
      if (!Number.isFinite(id) || !visibleIds.has(id) || seen.has(id)) return false;
      seen.add(id);
      return true;
    });
  }

  function focusTimedRow(card, assessmentId) {
    const button = card?.querySelector?.(`[data-ep-live-timed-start="${Number(assessmentId)}"]`);
    if (!button) return;
    button.scrollIntoView?.({ block: "center", behavior: "smooth" });
    button.focus?.({ preventScroll: true });
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

    const availableRows = visiblePracticeRows(card, payload);
    const actions = document.createElement("div");
    actions.className = "ep-past-paper-actions";
    if (availableRows.length) {
      const actionTitle = document.createElement("strong");
      actionTitle.className = "ep-past-paper-actions-title";
      actionTitle.textContent = c.available;
      actions.appendChild(actionTitle);
      const kindCounts = {};
      availableRows.forEach(row => {
        const button = document.createElement("button");
        button.className = "ep-live-btn secondary ep-past-paper-action";
        button.type = "button";
        button.dataset.epPastPaperStart = String(Number(row.assessment_id));
        const kind = String(row?.attempt_kind || "timed_section");
        kindCounts[kind] = Number(kindCounts[kind] || 0) + 1;
        const label = learnerKind(row, c);
        const marks = Number(row.marks_available || 0);
        button.textContent = `${label} ${kindCounts[kind]} · ${marks} ${c.marks} · ${c.show}`;
        button.addEventListener("click", () => focusTimedRow(card, row.assessment_id));
        actions.appendChild(button);
      });
    }

    const note = document.createElement("div");
    note.className = "ep-past-paper-note";
    note.textContent = c.note;
    panel.append(head, stats);
    if (availableRows.length) panel.append(actions);
    panel.append(note);
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
