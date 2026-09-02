(() => {
  "use strict";

  const iframe = document.getElementById("live-app");
  if (!iframe) return;

  const svg = (paths) => `<svg viewBox="0 0 24 24" aria-hidden="true">${paths}</svg>`;
  const ICONS = {
    home: svg("<path d='M3 10.5 12 3l9 7.5'/><path d='M5 9.5V21h14V9.5'/><path d='M9 21v-7h6v7'/ >"),
    study: svg("<path d='m3 6 9-3 9 3-9 3-9-3Z'/><path d='M6 7.5V13c0 2 2.7 4 6 4s6-2 6-4V7.5'/><path d='M21 6v7'/ >"),
    ratings: svg("<path d='M4 20V10h4v10'/><path d='M10 20V4h4v16'/><path d='M16 20v-7h4v7'/ >"),
    profile: svg("<circle cx='12' cy='8' r='4'/><path d='M4 21c.8-4 3.5-6 8-6s7.2 2 8 6'/ >")
  };

  function currentLang(doc) {
    const raw = String(doc?.documentElement?.lang || "ru").toLowerCase();
    if (raw.startsWith("uz")) return "uz";
    if (raw.startsWith("en")) return "en";
    return "ru";
  }

  function labels(lang) {
    if (lang === "uz") return { home: "Bosh sahifa", courses: "O‘qish", ratings: "Reyting", profile: "Profil", coursesTitle: "O‘qish" };
    if (lang === "en") return { home: "Home", courses: "Study", ratings: "Ratings", profile: "Profile", coursesTitle: "Study" };
    return { home: "Главная", courses: "Учёба", ratings: "Рейтинг", profile: "Профиль", coursesTitle: "Учёба" };
  }

  function installStyles(doc) {
    if (!doc || doc.getElementById("ui-v3-live-css")) return;
    const link = doc.createElement("link");
    link.id = "ui-v3-live-css";
    link.rel = "stylesheet";
    link.href = "/ui-v3/live.css?v=1";
    doc.head.appendChild(link);
    doc.documentElement.classList.add("ui-v3-live");
  }

  function upgradeTabbar(doc) {
    const lang = currentLang(doc);
    const l = labels(lang);
    const map = {
      home: ["home", l.home],
      courses: ["study", l.courses],
      ratings: ["ratings", l.ratings],
      profile: ["profile", l.profile]
    };

    doc.querySelectorAll(".tabbar .tab[data-tab]").forEach((btn) => {
      const key = btn.dataset.tab;
      const cfg = map[key];
      if (!cfg) return;
      const ico = btn.querySelector(".tab-ico");
      if (ico && ico.dataset.v3Icon !== cfg[0]) {
        ico.innerHTML = ICONS[cfg[0]] || "";
        ico.dataset.v3Icon = cfg[0];
      }
      const label = btn.querySelector(".tab-label") || Array.from(btn.children).find((x) => x !== ico);
      if (label && label.textContent !== cfg[1]) label.textContent = cfg[1];
    });

    const courseTitle = doc.querySelector("#courses-all-subjects .section-title");
    if (courseTitle && courseTitle.textContent.trim() !== l.coursesTitle) {
      courseTitle.textContent = l.coursesTitle;
    }
  }

  function normalizeLearnerCopy(doc) {
    const lang = currentLang(doc);
    const competitiveTitle = doc.querySelector("#view-home [data-i18n='home_competitive_mode']");
    const competitiveSub = doc.querySelector("#view-home [data-i18n='home_competitive_mode_subtitle']");

    if (competitiveTitle) {
      competitiveTitle.textContent = lang === "uz" ? "Olimpiada" : lang === "en" ? "Olympiad" : "Олимпиада";
    }
    if (competitiveSub) {
      competitiveSub.textContent = lang === "uz"
        ? "Amaliyot va turlardagi joriy holat"
        : lang === "en"
          ? "Current Practice and Tour status"
          : "Текущий статус практики и туров";
    }

    const pinned = doc.querySelector("#view-home [data-i18n='home_pinned_subjects']");
    if (pinned) pinned.textContent = lang === "uz" ? "O‘qishni davom ettirish" : lang === "en" ? "Continue learning" : "Продолжить обучение";
  }

  function markSubjectHub(doc) {
    const hub = doc.getElementById("courses-subject-hub");
    if (!hub) return;
    const title = String(doc.getElementById("subject-hub-title")?.textContent || "").toLowerCase();
    const isMath = /математ|mathemat/.test(title);
    hub.classList.toggle("ui-v3-mathematics-hub", isMath);
  }

  function apply(doc) {
    installStyles(doc);
    upgradeTabbar(doc);
    normalizeLearnerCopy(doc);
    markSubjectHub(doc);
  }

  function boot() {
    let doc;
    try { doc = iframe.contentDocument; } catch { return; }
    if (!doc) return;

    apply(doc);

    const observer = new MutationObserver(() => apply(doc));
    observer.observe(doc.documentElement, { childList: true, subtree: true, characterData: true });

    const langObserver = new MutationObserver(() => apply(doc));
    langObserver.observe(doc.documentElement, { attributes: true, attributeFilter: ["lang", "class"] });
  }

  iframe.addEventListener("load", boot, { once: true });
})();
