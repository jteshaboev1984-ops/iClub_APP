(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p210materials1";
  let observer = null;
  let busy = false;
  let activeLanguage = "ru";

  function rootEl() {
    return document.querySelector("#exam-prep-host-root");
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function detectLanguage() {
    const value = String(rootEl()?.textContent || "");
    if (/Umumiy ko‘rinish|Haftalik|Imtihon tayyorgarligi|Dastur bo‘yicha/i.test(value)) return "uz";
    if (/\bOverview\b|weekly plan|exam preparation|entry check|syllabus progress/i.test(value)) return "en";
    return "ru";
  }

  function copy() {
    if (activeLanguage === "uz") {
      return {
        button: "Materiallar",
        title: "O‘quv materiallari",
        intro: "Bu yerda Cambridge rasmiy havolalari va o‘qishda foydalaniladigan ma’lumot manbalari jamlangan. Imtihon doirasini rasmiy syllabus belgilaydi.",
        overview: "Umumiy ko‘rinish",
        loading: "Yuklanmoqda…",
        error: "Materiallarni yuklab bo‘lmadi. Qayta urinib ko‘ring.",
        officialSyllabus: "Rasmiy syllabus",
        coursebook: "Darslik",
        pastPapers: "Cambridge past papers",
        examinerReports: "Examiner reports",
        official: "Rasmiy manba",
        component: "Komponent",
        open: "Rasmiy manbani ochish",
        licensed: "Sizga qonuniy ravishda mavjud bo‘lgan nusxadan foydalaning.",
        school: "Bu materialga kirish maktab orqali beriladi.",
        safeNote: "iClub bu yerda himoyalangan Cambridge yoki darslik materiallarini nusxalamaydi."
      };
    }
    if (activeLanguage === "en") {
      return {
        button: "Materials",
        title: "Study materials",
        intro: "Official Cambridge links and study references are collected here. The official syllabus defines the examinable scope.",
        overview: "Overview",
        loading: "Loading…",
        error: "Could not load the materials. Try again.",
        officialSyllabus: "Official syllabus",
        coursebook: "Coursebook",
        pastPapers: "Cambridge past papers",
        examinerReports: "Examiner reports",
        official: "Official source",
        component: "Component",
        open: "Open official source",
        licensed: "Use a copy that is legally available to you.",
        school: "Access to this material is provided through your school.",
        safeNote: "iClub does not copy protected Cambridge or coursebook material into this library."
      };
    }
    return {
      button: "Материалы",
      title: "Учебные материалы",
      intro: "Здесь собраны официальные ссылки Cambridge и справочные материалы для обучения. Экзаменационный объём определяется официальным syllabus.",
      overview: "Обзор",
      loading: "Загрузка…",
      error: "Не удалось загрузить материалы. Попробуйте ещё раз.",
      officialSyllabus: "Официальный syllabus",
      coursebook: "Учебник",
      pastPapers: "Cambridge past papers",
      examinerReports: "Отчёты экзаменаторов",
      official: "Официальный источник",
      component: "Компонент",
      open: "Открыть официальный источник",
      licensed: "Используйте законно доступную вам копию.",
      school: "Доступ к этому материалу предоставляется через школу.",
      safeNote: "iClub не копирует сюда защищённые материалы Cambridge или учебников."
    };
  }

  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }

  function resourceKindLabel(kind) {
    const c = copy();
    return ({
      official_syllabus: c.officialSyllabus,
      coursebook_reference: c.coursebook,
      official_past_paper_index: c.pastPapers,
      examiner_feedback_index: c.examinerReports
    })[String(kind || "")] || c.official;
  }

  async function dashboard() {
    const app = window.iClubExamPrep;
    if (!app || typeof app.open !== "function") return false;
    return Boolean(await app.open({ subjectKey: "mathematics", language: activeLanguage }));
  }

  function shell(component, body) {
    const c = copy();
    return `<section class="ep-host-shell ep-materials-shell" data-ep-materials-screen>
      <div class="ep-materials-top">
        <div><div class="ep-materials-sub">${esc(component)} · Cambridge AS Mathematics</div><div class="ep-materials-title">${esc(c.title)}</div><div class="ep-materials-sub">${esc(c.intro)}</div></div>
        <button class="ep-materials-btn" type="button" data-ep-materials-back>${esc(c.overview)}</button>
      </div>
      ${body}
    </section>`;
  }

  function bindBack(root) {
    root.querySelector("[data-ep-materials-back]")?.addEventListener("click", () => dashboard());
  }

  function renderLoading(component) {
    const root = rootEl();
    if (!root) return;
    root.innerHTML = shell(component, `<div class="ep-materials-card">${esc(copy().loading)}</div>`);
    bindBack(root);
  }

  function renderError(component) {
    const root = rootEl();
    if (!root) return;
    root.innerHTML = shell(component, `<div class="ep-materials-safe">${esc(copy().error)}</div>`);
    bindBack(root);
  }

  function safeExternalUrl(value) {
    const url = String(value || "").trim();
    return /^https:\/\//i.test(url) ? url : "";
  }

  function openExternal(url) {
    const safeUrl = safeExternalUrl(url);
    if (!safeUrl) return;
    try {
      if (window.Telegram?.WebApp?.openLink) {
        window.Telegram.WebApp.openLink(safeUrl);
        return;
      }
      window.open(safeUrl, "_blank", "noopener,noreferrer");
    } catch (_) {
      // The learner can retry from the same view; no state is changed by opening a resource.
    }
  }

  function renderMaterials(component, data) {
    const root = rootEl();
    if (!root) return;
    const c = copy();
    const rows = Array.isArray(data?.materials) ? data.materials : [];
    const filtered = rows.filter(row => !row?.component_code || row.component_code === component);
    const cards = filtered.map(row => {
      const externalUrl = safeExternalUrl(row?.external_url);
      const accessNote = row?.licensed_copy_required === true ? c.licensed : row?.school_request_required === true ? c.school : "";
      const chips = [
        row?.component_code ? `<span class="ep-materials-chip">${esc(c.component)} ${esc(row.component_code)}</span>` : "",
        externalUrl ? `<span class="ep-materials-chip">${esc(c.official)}</span>` : ""
      ].filter(Boolean).join("");
      return `<article class="ep-materials-card" data-ep-material="${esc(row?.material_key)}">
        <div class="ep-materials-card-head"><div><div class="ep-materials-kind">${esc(resourceKindLabel(row?.resource_kind))}</div><strong>${esc(row?.title)}</strong></div><div class="ep-materials-meta">${chips}</div></div>
        ${row?.note ? `<div class="ep-materials-note">${esc(row.note)}</div>` : ""}
        ${accessNote ? `<div class="ep-materials-safe">${esc(accessNote)}</div>` : ""}
        ${externalUrl ? `<button class="ep-materials-action" type="button" data-ep-materials-external="${esc(externalUrl)}">${esc(c.open)}</button>` : ""}
      </article>`;
    }).join("");

    root.innerHTML = shell(component, `${cards}<div class="ep-materials-safe">${esc(c.safeNote)}</div>`);
    bindBack(root);
    root.querySelectorAll("[data-ep-materials-external]").forEach(button => {
      button.addEventListener("click", () => openExternal(button.dataset.epMaterialsExternal));
    });
  }

  async function openMaterials(component) {
    if (busy || !canUse() || !["P1", "P5"].includes(component) || typeof internal.api?.materialsLibrary !== "function") return;
    busy = true;
    activeLanguage = detectLanguage();
    renderLoading(component);
    const result = await internal.api.materialsLibrary(activeLanguage);
    busy = false;
    if (!result?.ok || result.data?.rights_respected !== true || result.data?.protected_content_embedded !== false) {
      renderError(component);
      return;
    }
    renderMaterials(component, result.data || {});
  }

  function injectDashboardActions() {
    const root = rootEl();
    if (!root || root.hidden || !canUse() || root.querySelector("[data-ep-materials-screen]")) return;
    activeLanguage = detectLanguage();
    const c = copy();
    root.querySelectorAll(".ep-live-card").forEach(card => {
      if (card.dataset.epMaterialsInjected === "1") return;
      const component = card.querySelector("[data-ep-live-plan]")?.dataset.epLivePlan || card.querySelector("[data-ep-live-start]")?.dataset.epLiveStart;
      if (!component || !["P1", "P5"].includes(component)) return;
      const actions = card.querySelector(".ep-live-actions");
      if (!actions) return;
      const button = document.createElement("button");
      button.type = "button";
      button.className = "ep-materials-btn";
      button.dataset.epMaterialsOpen = component;
      button.textContent = c.button;
      button.addEventListener("click", () => openMaterials(component));
      actions.append(button);
      card.dataset.epMaterialsInjected = "1";
    });
  }

  function attach() {
    const root = rootEl();
    if (!root) {
      setTimeout(attach, 50);
      return;
    }
    if (observer) return;
    observer = new MutationObserver(() => injectDashboardActions());
    observer.observe(root, { childList: true, subtree: true });
    injectDashboardActions();
    internal.materialsView = Object.freeze({ version: VERSION, openMaterials });
  }

  attach();
})();
