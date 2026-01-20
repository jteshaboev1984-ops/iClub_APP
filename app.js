/* =========================================================
   iClub WebApp — app.js (v1 skeleton, aligned to new index.html)
   Plain HTML/CSS/JS, no build tools
   ========================================================= */

(() => {
  "use strict";

  // ---------------------------
  // Helpers
  // ---------------------------
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

  function escapeHTML(value) {
  return String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

  function safeJsonParse(s, fallback) {
    try { return JSON.parse(s); } catch { return fallback; }
  }

  function nowISO() {
    return new Date().toISOString();
  }

  // ---------------------------
  // Storage keys
  // ---------------------------
  const LS = {
    state: "iclub_state_v1",
    profile: "iclub_profile_v1",
    practiceDraft: "iclub_practice_draft_v1"
  };

  // ---------------------------
  // i18n
  // ---------------------------
  const t = (key, vars) => (window.i18n?.t ? window.i18n.t(key, vars) : key);

  // ---------------------------
  // Telegram WebApp integration (safe)
  // ---------------------------
  const tg = (window.Telegram && window.Telegram.WebApp) ? window.Telegram.WebApp : null;
  if (tg) {
    try {
      tg.ready();
      tg.expand();
    } catch {}
  }

  function getTelegramLang() {
    const code = tg?.initDataUnsafe?.user?.language_code;
    return window.i18n?.normalizeLang ? window.i18n.normalizeLang(code) : "ru";
  }

  function openExternal(url) {
    // Prefer Telegram openTelegramLink/openLink if available
    try {
      if (tg?.openTelegramLink && /^(https?:\/\/)?t\.me\//i.test(url)) {
        tg.openTelegramLink(url.replace(/^https?:\/\//i, ""));
        return;
      }
      if (tg?.openLink) {
        tg.openLink(url);
        return;
      }
    } catch {}
    window.open(url, "_blank", "noopener,noreferrer");
  }

  // ---------------------------
  // App state
  // ---------------------------
  const defaultState = {
  tab: "home", // home | courses | ratings | profile
  viewStack: ["home"], // global screens stack
  courses: {
    stack: ["all-subjects"],
    subjectKey: null,
    lessonId: null
  },
  profile: {
    stack: ["main"] // main | settings
  },
  quizLock: null
};

  let state = loadState();

  function loadState() {
    const saved = safeJsonParse(localStorage.getItem(LS.state), null);
    if (!saved) return structuredClone(defaultState);

    // soft merge
    const merged = {
      ...structuredClone(defaultState),
      ...saved,
      courses: { ...structuredClone(defaultState.courses), ...(saved.courses || {}) }
    };
    // Ensure viewStack sane
    if (!Array.isArray(merged.viewStack) || merged.viewStack.length === 0) merged.viewStack = ["home"];
    return merged;
  }

  function saveState() {
    localStorage.setItem(LS.state, JSON.stringify(state));
  }

  // ---------------------------
  // Profile (local demo)
  // later replace with Supabase
  // ---------------------------
  function loadProfile() {
    return safeJsonParse(localStorage.getItem(LS.profile), null);
  }

  function saveProfile(profile) {
    localStorage.setItem(LS.profile, JSON.stringify(profile));
  }

   function togglePinnedSubject(profile, subjectKey) {
  if (!profile) return null;
  const p = structuredClone(profile);
  p.subjects = Array.isArray(p.subjects) ? p.subjects : [];

  const idx = p.subjects.findIndex(s => s.key === subjectKey);

  if (idx === -1) {
    // если предмет не был добавлен — добавляем как study+pinned
    p.subjects.push({ key: subjectKey, mode: "study", pinned: true });
    return p;
  }

  // уже есть — переключаем pinned
  p.subjects[idx].pinned = !p.subjects[idx].pinned;

  // Если выключили pinned и предмет был чисто учебным и "ничем не нужен" —
  // в v1 оставляем его (чтобы не терять режим/историю). Удаление сделаем позже, если потребуется.
  return p;
}

  // ---------------------------
  // Demo subjects (keys match index.html selects)
  // ---------------------------
  const SUBJECTS = [
    { key: "informatics", title: "Информатика", type: "main" },
    { key: "economics", title: "Экономика", type: "main" },
    { key: "biology", title: "Биология", type: "main" },
    { key: "chemistry", title: "Химия", type: "main" },
    { key: "mathematics", title: "Математика", type: "main" },

    { key: "english_a1", title: "English (A1)", type: "additional" },
    { key: "english_a2", title: "English (A2)", type: "additional" },
    { key: "english_b1", title: "English (B1)", type: "additional" },
    { key: "sat", title: "SAT", type: "additional" },
    { key: "ielts", title: "IELTS", type: "additional" }
  ];

  function subjectByKey(key) {
    return SUBJECTS.find(s => s.key === key) || null;
  }

     // ---------------------------
  // Availability rules (v1: local profile-based)
  // ---------------------------
  function isSchoolUser(profile) {
    return !!profile?.is_school_student;
  }

  function getUserSubject(profile, subjectKey) {
    return profile?.subjects?.find(s => s.key === subjectKey) || null;
  }

  function isMainSubjectKey(subjectKey) {
    return subjectByKey(subjectKey)?.type === "main";
  }

  function isAdditionalSubjectKey(subjectKey) {
    return subjectByKey(subjectKey)?.type === "additional";
  }

  function isCompetitiveForUser(profile, subjectKey) {
    return getUserSubject(profile, subjectKey)?.mode === "competitive";
  }

  // Tours eligibility (ACTIVE tours): school + main + competitive
  function canOpenActiveTours(profile, subjectKey) {
    if (!profile) return { ok: false, reason: "no_profile" };
    if (!isSchoolUser(profile)) return { ok: false, reason: "not_school" };
    if (!isMainSubjectKey(subjectKey)) return { ok: false, reason: "not_main" };
    if (!isCompetitiveForUser(profile, subjectKey)) return { ok: false, reason: "not_competitive" };
    return { ok: true, reason: "ok" };
  }

  function toastToursDenied(reason) {
    if (reason === "not_school") { showToast(t("disabled_not_school")); return; }
    if (reason === "not_competitive") { showToast(t("disabled_not_competitive")); return; }
    if (reason === "not_main") { showToast("Туры доступны только по основным предметам."); return; }
    showToast(t("not_available"));
  }

     // ---------------------------
  // Tour schedule (v1: local stub, later from Supabase)
  // ---------------------------
  // Формат: YYYY-MM-DD (локальное время пользователя)
  const TOUR_SCHEDULE = [
    // Пример (позже заменим на реальные даты из базы/админки):
    // { subjectKey: "economics", tourNo: 1, start: "2026-02-01", end: "2026-02-07" },
  ];

  function parseLocalDateStart(yyyy_mm_dd) {
    const [y, m, d] = String(yyyy_mm_dd).split("-").map(Number);
    return new Date(y, (m - 1), d, 0, 0, 0, 0).getTime();
  }

  function parseLocalDateEnd(yyyy_mm_dd) {
    const [y, m, d] = String(yyyy_mm_dd).split("-").map(Number);
    return new Date(y, (m - 1), d, 23, 59, 59, 999).getTime();
  }

  function getActiveTourEntry(subjectKey) {
    const now = Date.now();
    const list = TOUR_SCHEDULE.filter(x => x.subjectKey === subjectKey);
    for (const e of list) {
      const s = parseLocalDateStart(e.start);
      const t = parseLocalDateEnd(e.end);
      if (now >= s && now <= t) return e;
    }
    return null;
  }

  function hasAnyActiveTourNow() {
    const now = Date.now();
    for (const e of TOUR_SCHEDULE) {
      const s = parseLocalDateStart(e.start);
      const t = parseLocalDateEnd(e.end);
      if (now >= s && now <= t) return true;
    }
    return false;
  }

  function canOpenArchiveNow() {
    // По правилам: архив открывается только когда активный тур завершён (то есть активных сейчас нет)
    return !hasAnyActiveTourNow();
  }

  // ---------------------------
  // Regions / Districts (v1 demo)
  // Later: load from DB
  // ---------------------------
  const REGIONS = {
    "Tashkent": ["Chilonzor", "Yunusobod", "Mirzo Ulug‘bek", "Shaykhontohur", "Yakkasaroy"],
    "Samarkand": ["Samarkand city", "Urgut", "Kattakurgan", "Payariq"],
    "Fergana": ["Fergana city", "Margilan", "Kokand", "Quva"],
    "Andijan": ["Andijan city", "Asaka", "Shahrixon", "Xo‘jaobod"],
    "Bukhara": ["Bukhara city", "G‘ijduvon", "Kogon", "Vobkent"]
  };

  function fillSelectOptions(selectEl, options, placeholder) {
    if (!selectEl) return;

    selectEl.innerHTML = "";

    const ph = document.createElement("option");
    ph.value = "";
    ph.disabled = true;
    ph.selected = true;
    ph.textContent = placeholder;
    selectEl.appendChild(ph);

    options.forEach(v => {
      const o = document.createElement("option");
      o.value = v;
      o.textContent = v;
      selectEl.appendChild(o);
    });
  }

  function initRegionDistrictUI() {
    const regionEl = $("#reg-region");
    const districtEl = $("#reg-district");
    if (!regionEl || !districtEl) return;

    const regionList = Object.keys(REGIONS);
    fillSelectOptions(regionEl, regionList, "Выберите регион…");

    districtEl.disabled = true;
    fillSelectOptions(districtEl, [], "Сначала выберите регион…");

    regionEl.addEventListener("change", () => {
      const r = regionEl.value;
      const districts = REGIONS[r] || [];
      districtEl.disabled = districts.length === 0;
      fillSelectOptions(
        districtEl,
        districts,
        districts.length ? "Выберите район…" : "Нет районов"
      );
    });
  }

  // ---------------------------
  // UI: Views & Tabs
  // ---------------------------
  const VIEWS = [
    "splash",
    "registration",
    "home",
    "courses",
    "ratings",
    "profile",
    // Global screens
    "resources",
    "news",
    "notifications",
    "community",
    "about",
    "certificates",
    "archive"
  ];

  function showView(viewName) {
    VIEWS.forEach(v => {
      const el = $(`#view-${v}`);
      if (!el) return;
      el.classList.toggle("is-active", v === viewName);
    });
    updateTopbarForView(viewName);
  }

  function setTab(tabName) {
    state.tab = tabName;
    saveState();

    // Tabbar active
    $$(".tabbar .tab").forEach(btn => {
      btn.classList.toggle("is-active", btn.dataset.tab === tabName);
    });

    // Maintain global view stack: tab screen becomes "base"
    setGlobalBaseView(tabName);

    if (tabName === "courses") {
      renderCoursesStack();
    }
     if (tabName === "profile") {
  renderProfileStack();
 }
}

  function setGlobalBaseView(tabName) {
    // base view should be one of: home/courses/ratings/profile
    if (!["home", "courses", "ratings", "profile"].includes(tabName)) tabName = "home";
    state.viewStack = [tabName];
    saveState();
    showView(tabName);
  }

  function openGlobal(viewName) {
    // push to stack and show
    if (!VIEWS.includes(viewName)) return;

    // If user is in quiz lock, do not allow leaving
    if (state.quizLock === "tour") {
      showToast("Tour is in progress");
      return;
    }
    if (state.quizLock === "practice") {
      showToast("Pause practice to leave");
      return;
    }

    // base should exist
    if (!Array.isArray(state.viewStack) || state.viewStack.length === 0) {
      state.viewStack = [state.tab || "home"];
    }

    const top = state.viewStack[state.viewStack.length - 1];
    if (top === viewName) {
      showView(viewName);
      return;
    }

    state.viewStack.push(viewName);
    saveState();
    showView(viewName);
  }

  function canGlobalBack() {
    return Array.isArray(state.viewStack) && state.viewStack.length > 1;
  }

  function globalBack() {
    if (!canGlobalBack()) return;
    state.viewStack.pop();
    saveState();
    const top = state.viewStack[state.viewStack.length - 1];
    showView(top);
  }

  // ---------------------------
  // Topbar behavior
  // ---------------------------
  function updateTopbarForView(viewName) {
    const backBtn = $("#topbar-back");
    const titleEl = $("#topbar-title");
    const subEl = $("#topbar-subtitle");

    if (!backBtn || !titleEl || !subEl) return;

    // Default
    titleEl.textContent = t("app_name");
    subEl.textContent = "";
    backBtn.style.visibility = "hidden";

    if (viewName === "splash") {
      titleEl.textContent = t("app_name");
      return;
    }

    if (viewName === "registration") {
      titleEl.textContent = t("reg_title");
      backBtn.style.visibility = "hidden";
      return;
    }

    // Global screens (resources/news/...)
    if (["resources", "news", "notifications", "community", "about", "certificates", "archive"].includes(viewName)) {
      backBtn.style.visibility = canGlobalBack() ? "visible" : "hidden";

      if (viewName === "resources") titleEl.textContent = "Ресурсы";
      if (viewName === "news") titleEl.textContent = "Новости";
      if (viewName === "notifications") titleEl.textContent = "Уведомления";
      if (viewName === "community") titleEl.textContent = "Комьюнити";
      if (viewName === "about") titleEl.textContent = "О проекте";
      if (viewName === "certificates") titleEl.textContent = "Сертификаты";
      if (viewName === "archive") titleEl.textContent = "Архив";
      return;
    }

    if (viewName === "home") {
      titleEl.textContent = t("app_name");
      backBtn.style.visibility = "hidden";
      return;
    }

    if (viewName === "ratings") {
      titleEl.textContent = "Ratings";
      backBtn.style.visibility = "hidden";
      return;
    }

    if (viewName === "profile") {
  const top = getProfileTopScreen();
  titleEl.textContent = (top === "settings") ? "Настройки" : "Profile";
  backBtn.style.visibility = (top === "settings") ? "visible" : "hidden";
  return;
}

    if (viewName === "courses") {
      const canGoBack = canCoursesBack();
      backBtn.style.visibility = (state.quizLock ? "hidden" : (canGoBack ? "visible" : "hidden"));

      const top = getCoursesTopScreen();
      if (top === "all-subjects") titleEl.textContent = "Courses";
      if (top === "subject-hub") titleEl.textContent = "Subject";
      if (top === "lessons") titleEl.textContent = "Lessons";
      if (top === "video") titleEl.textContent = "Video";
      if (top === "practice-start") titleEl.textContent = t("practice");
      if (top === "practice-quiz") titleEl.textContent = t("practice");
      if (top === "practice-result") titleEl.textContent = "Practice Result";
      if (top === "practice-review") titleEl.textContent = "Разбор ошибок";
      if (top === "practice-recs") titleEl.textContent = "Рекомендации";
      if (top === "tours") titleEl.textContent = "Tours";
      if (top === "tour-rules") titleEl.textContent = t("tour_rules_title");
      if (top === "tour-quiz") titleEl.textContent = "Tour";
      if (top === "tour-result") titleEl.textContent = "Tour Result";
      if (top === "tour-review") titleEl.textContent = "Разбор тура";
      if (top === "books") titleEl.textContent = "Books";
      if (top === "my-recs") titleEl.textContent = "My Recommendations";

      const subj = subjectByKey(state.courses.subjectKey);
      if (subj && top !== "all-subjects") subEl.textContent = subj.title;

      return;
    }
  }

  // ---------------------------
  // Courses stack
  // ---------------------------
  const COURSES_SCREENS = [
    "all-subjects",
    "subject-hub",
    "lessons",
    "video",
    "practice-start",
    "practice-quiz",
    "practice-result",
    "practice-review",
    "practice-recs",
    "tours",
    "tour-rules",
    "tour-quiz",
    "tour-result",
    "tour-review",
    "books",
    "my-recs"
  ];

  function getCoursesTopScreen() {
    const s = state.courses.stack;
    return s && s.length ? s[s.length - 1] : "all-subjects";
  }

  function showCoursesScreen(screenName) {
    COURSES_SCREENS.forEach(sc => {
      const el = $(`#courses-${sc}`);
      if (!el) return;
      el.classList.toggle("is-active", sc === screenName);
    });
    updateTopbarForView("courses");
  }

  function pushCourses(screenName) {
    state.courses.stack.push(screenName);
    saveState();
    showCoursesScreen(screenName);
  }

  function replaceCourses(screenName) {
    state.courses.stack = [screenName];
    saveState();
    showCoursesScreen(screenName);
  }

  function popCourses() {
    if (state.quizLock) return;
    if (state.courses.stack.length <= 1) return;
    state.courses.stack.pop();
    saveState();
    showCoursesScreen(getCoursesTopScreen());
  }

  function canCoursesBack() {
    return state.courses.stack.length > 1;
  }

  function renderCoursesStack() {
    const top = getCoursesTopScreen();
    showCoursesScreen(top);
  }

   // ---------------------------
// Profile stack
// ---------------------------
const PROFILE_SCREENS = ["main", "settings"];

function getProfileTopScreen() {
  const s = state.profile?.stack;
  return (s && s.length) ? s[s.length - 1] : "main";
}

function showProfileScreen(screenName) {
  PROFILE_SCREENS.forEach(sc => {
    const el = document.getElementById(`profile-${sc}`);
    if (!el) return;
    el.classList.toggle("is-active", sc === screenName);
  });
  updateTopbarForView("profile");
}

function pushProfile(screenName) {
  state.profile.stack = Array.isArray(state.profile.stack) ? state.profile.stack : ["main"];
  state.profile.stack.push(screenName);
  saveState();
  showProfileScreen(screenName);
}

function replaceProfile(screenName) {
  state.profile.stack = [screenName];
  saveState();
  showProfileScreen(screenName);
}

function popProfile() {
  if (!state.profile?.stack || state.profile.stack.length <= 1) return;
  state.profile.stack.pop();
  saveState();
  showProfileScreen(getProfileTopScreen());
}

function openProfileSettings() {
  replaceProfile("settings");
  renderProfileSettings();
}

function openProfileMain() {
  replaceProfile("main");
}

function renderProfileStack() {
  const top = getProfileTopScreen();
  showProfileScreen(top);
  if (top === "settings") renderProfileSettings();
}

   function renderProfileSettings() {
  const profile = loadProfile();
  const list = document.getElementById("profile-settings-competitive-list");
  const note = document.getElementById("settings-competitive-note");
  if (!list) return;

  list.innerHTML = "";

  if (!profile) {
    list.innerHTML = `<div class="empty muted">Сначала регистрация.</div>`;
    return;
  }

  // Non-school users: competitive is disabled by product rules
  if (!profile.is_school_student) {
    if (note) note.textContent = t("disabled_not_school");
    list.innerHTML = `<div class="empty muted">${t("disabled_not_school")}</div>`;
    return;
  }

  const current = Array.isArray(profile.subjects) ? profile.subjects : [];
  const currentComp = current.filter(s => s.mode === "competitive").map(s => s.key);
  const compCount = currentComp.length;

  if (note) note.textContent = `Можно выбрать максимум 2 предмета в Competitive. Сейчас выбрано: ${compCount}/2.`;

  // Only MAIN subjects can be competitive (per spec)
  const mainSubjects = SUBJECTS.filter(s => s.type === "main");

  mainSubjects.forEach(subj => {
    const isOn = currentComp.includes(subj.key);

    const row = document.createElement("div");
    row.className = "settings-row";

    row.innerHTML = `
      <div>
        <div style="font-weight:800">${escapeHTML(subj.title)}</div>
        <div class="muted small">${isOn ? "Competitive" : "Study"}</div>
      </div>
      <label class="switch">
        <input type="checkbox" ${isOn ? "checked" : ""}>
        <span class="slider"></span>
      </label>
    `;

    const input = row.querySelector('input[type="checkbox"]');

    input.addEventListener("change", () => {
      const fresh = loadProfile();
      if (!fresh) return;

      const subjects = Array.isArray(fresh.subjects) ? structuredClone(fresh.subjects) : [];
      const idx = subjects.findIndex(s => s.key === subj.key);

      // ensure exists
      if (idx === -1) subjects.push({ key: subj.key, mode: "study", pinned: false });

      const next = subjects.map(s => ({ ...s }));

      // toggle
      const was = next.find(s => s.key === subj.key);
      const turningOn = !isCompetitiveForUser(fresh, subj.key);

      if (turningOn) {
        const compNow = next.filter(s => s.mode === "competitive").length;
        if (compNow >= 2) {
          // revert UI
          input.checked = false;
          showToast("Лимит 2 Competitive. Сначала выключите другой предмет.");
          return;
        }
        was.mode = "competitive";
        showToast("Предмет переведён в Competitive");
      } else {
        was.mode = "study";
        showToast("Предмет переведён в Study");
      }

      fresh.subjects = next;
      saveProfile(fresh);

      // refresh dependent UI
      renderHome();
      if (state.tab === "courses") {
        renderAllSubjects();
        if (getCoursesTopScreen() === "subject-hub") renderSubjectHub();
      }

      // re-render settings to update counters
      renderProfileSettings();
    });

    list.appendChild(row);
  });
}

  // ---------------------------
  // Toast
  // ---------------------------
  let toastTimer = null;
  function showToast(message, ms = 2500) {
    const el = $("#toast");
    if (!el) return;
    el.textContent = message;
    el.classList.add("is-show");
    if (toastTimer) clearTimeout(toastTimer);
    toastTimer = setTimeout(() => el.classList.remove("is-show"), ms);
  }

  // ---------------------------
  // Registration UI
  // ---------------------------
  function updateSchoolFieldsVisibility() {
    const isSchool = ($("#reg-is-school")?.value === "yes");
    const block = $("#reg-school-block");
    if (!block) return;
    block.style.display = isSchool ? "grid" : "none";
  }

  function isRegistered() {
    return !!loadProfile();
  }

  // ---------------------------
  // Home rendering (demo)
  // ---------------------------
  function renderHome() {
    const profile = loadProfile();
    const compWrap = $("#home-competitive-list");
    const studyWrap = $("#home-study-list");
    if (!compWrap || !studyWrap) return;

    compWrap.innerHTML = "";
    studyWrap.innerHTML = "";

    if (!profile) {
      compWrap.innerHTML = `<div class="empty muted">Сначала регистрация.</div>`;
      studyWrap.innerHTML = `<div class="empty muted">Сначала регистрация.</div>`;
      return;
    }

    const comp = profile.subjects?.filter(s => s.mode === "competitive") || [];
    const study = profile.subjects?.filter(s => s.mode === "study") || [];

    if (!comp.length) compWrap.innerHTML = `<div class="empty muted">Пока нет соревновательных предметов.</div>`;
    if (!study.length) studyWrap.innerHTML = `<div class="empty muted">Закрепите учебные предметы в Courses.</div>`;

    comp.forEach(s => compWrap.appendChild(subjectCardEl(s)));
    study.forEach(s => studyWrap.appendChild(subjectCardEl(s)));
  }

   function subjectCardEl(userSubject) {
  const subj = subjectByKey(userSubject.key);
  const title = subj ? subj.title : userSubject.key;

  const isComp = userSubject.mode === "competitive";
  const modeLabel = isComp ? "Competitive" : "Study";

  // v1: демо-прогресс (позже заменим на реальные данные из базы)
  // Чтобы карточка не была "пустой", даём 2 строки статуса:
  const demoBest = isComp ? "Best practice: 7/10" : "Best practice: 6/10";
  const demoNext = isComp ? "Tours: 0/7 • Next: Tour 1" : "Next: Practice";

  const el = document.createElement("div");
  el.className = "home-subject-card";

  // Верх кликабельный: открывает Subject Hub
  const header = document.createElement("button");
  header.type = "button";
  header.className = "home-subject-head";
  header.innerHTML = `
    <div class="home-subject-row">
      <div class="card-title" style="margin:0">${escapeHTML(title)}</div>
      <span class="badge ${isComp ? "badge-comp" : "badge-study"}">${modeLabel}</span>
    </div>
    <div class="muted small">${demoBest}</div>
    <div class="muted small">${demoNext}</div>
  `;

  header.addEventListener("click", () => {
    state.courses.subjectKey = userSubject.key;
    saveState();
    setTab("courses");
    replaceCourses("subject-hub");
    renderSubjectHub();
  });

  // CTA ряд (кнопки не должны открывать hub по клику)
  const actions = document.createElement("div");
  actions.className = "home-subject-actions";

  // Практика (всегда)
  const btnPractice = document.createElement("button");
  btnPractice.type = "button";
  btnPractice.className = "mini-btn";
  btnPractice.textContent = "Практика";
  btnPractice.addEventListener("click", (e) => {
    e.stopPropagation();
    state.courses.subjectKey = userSubject.key;
    saveState();
    setTab("courses");
    // Открываем сразу practice start
    replaceCourses("subject-hub");
    renderSubjectHub();
    // имитация перехода как будто нажали "Практика" в hub
    openPracticeStart();
  });

  // Ресурсы (study) или Туры (competitive)
  const btnSecond = document.createElement("button");
  btnSecond.type = "button";
  btnSecond.className = "mini-btn ghost";

    if (isComp) {
    btnSecond.textContent = "Туры";
    btnSecond.addEventListener("click", (e) => {
      e.stopPropagation();

      const profile = loadProfile();
      const eligibility = canOpenActiveTours(profile, userSubject.key);
      if (!eligibility.ok) {
        toastToursDenied(eligibility.reason);
        return;
      }

      state.courses.subjectKey = userSubject.key;
      saveState();
      setTab("courses");
      replaceCourses("subject-hub");
      renderSubjectHub();
      pushCourses("tours");
    });
  } else {
    btnSecond.textContent = "Материалы";
    btnSecond.addEventListener("click", (e) => {
      e.stopPropagation();
      openGlobal("resources");
    });
  }

  actions.appendChild(btnPractice);
  actions.appendChild(btnSecond);

  el.appendChild(header);
  el.appendChild(actions);

  return el;
}

  // ---------------------------
  // Courses: All Subjects rendering
  // ---------------------------
  function renderAllSubjects() {
  const grid = $("#subjects-grid");
  if (!grid) return;

  const profile = loadProfile();

  // Если нет профиля — каталогу нечего делать (но это не должно случаться)
  grid.innerHTML = "";
  if (!profile) {
    grid.innerHTML = `<div class="empty muted">Сначала регистрация.</div>`;
    return;
  }

  const userSubjects = Array.isArray(profile.subjects) ? profile.subjects : [];
  const competitiveCount = userSubjects.filter(s => s.mode === "competitive").length;

  SUBJECTS.forEach(s => {
    const us = userSubjects.find(x => x.key === s.key) || null;
    const isPinned = !!us?.pinned;
    const mode = us?.mode || "study"; // default display
    const isComp = mode === "competitive";

    const card = document.createElement("div");
    card.className = "catalog-card";

    // Top clickable area: open hub (but does NOT change profile)
    const head = document.createElement("button");
    head.type = "button";
    head.className = "catalog-head";
    head.innerHTML = `
      <div class="catalog-row">
        <div>
          <div class="card-title" style="margin:0">${escapeHTML(s.title)}</div>
          <div class="muted small">${s.type === "main" ? "Main (Cambridge)" : "Additional"}</div>
        </div>
        <div class="catalog-badges">
          ${isPinned ? `<span class="badge badge-pin">Pinned</span>` : ``}
          <span class="badge ${isComp ? "badge-comp" : "badge-study"}">${isComp ? "Competitive" : "Study"}</span>
        </div>
      </div>

      <div class="muted small catalog-hint">
        ${us
          ? (isComp
              ? `Competitive управляется в Profile Settings (лимит 2).`
              : `Учебный режим. Можно закрепить или открыть разово.`)
          : `Не добавлен. Можно закрепить или открыть разово.`}
      </div>
    `;

    head.addEventListener("click", () => {
      // "Открыть" — без изменения профиля, как в контракте
      state.courses.subjectKey = s.key;
      saveState();
      pushCourses("subject-hub");
      renderSubjectHub();
    });

    // Actions row
    const actions = document.createElement("div");
    actions.className = "catalog-actions";

    // 1) Pin/Unpin
    const btnPin = document.createElement("button");
    btnPin.type = "button";
    btnPin.className = "mini-btn ghost";
    btnPin.textContent = isPinned ? "Убрать из закреплённых" : "Закрепить";

    btnPin.addEventListener("click", (e) => {
      e.stopPropagation();

      const updated = togglePinnedSubject(profile, s.key);
      if (!updated) {
        showToast(t("error_try_again"));
        return;
      }

      saveProfile(updated);
      renderHome();       // Home должен сразу обновляться
      renderAllSubjects(); // и каталог тоже
      showToast(isPinned ? "Убрано из закреплённых" : "Закреплено");
    });

    // 2) Open once (explicit action)
    const btnOnce = document.createElement("button");
    btnOnce.type = "button";
    btnOnce.className = "mini-btn";
    btnOnce.textContent = "Открыть один раз";
    btnOnce.addEventListener("click", (e) => {
      e.stopPropagation();
      state.courses.subjectKey = s.key;
      saveState();
      pushCourses("subject-hub");
      renderSubjectHub();
    });

    actions.appendChild(btnPin);
    actions.appendChild(btnOnce);

    // 3) Competitive manage (disabled-ish action pointing to Profile Settings)
    const compRow = document.createElement("div");
compRow.className = "catalog-competitive-row";

const compInfo = document.createElement("div");
compInfo.className = "catalog-competitive-info";

const infoText = document.createElement("div");
infoText.className = "muted small";
if (!profile.is_school_student) {
  infoText.textContent = "Competitive/туры недоступны (не школьник).";
} else if (isComp) {
  infoText.textContent = "Competitive включён. Управление — в Profile Settings.";
} else if (competitiveCount >= 2) {
  infoText.textContent = "Лимит 2 Competitive. Управление — в Profile Settings.";
} else {
  infoText.textContent = "Competitive настраивается в Profile Settings (лимит 2).";
}

const btnManage = document.createElement("button");
btnManage.type = "button";
btnManage.className = "link-btn";
btnManage.textContent = "В настройки";
btnManage.addEventListener("click", (e) => {
  e.stopPropagation();
  setTab("profile");
  openProfileSettings();
});

compInfo.appendChild(infoText);
compInfo.appendChild(btnManage);
compRow.appendChild(compInfo);

    card.appendChild(head);
    card.appendChild(actions);
    card.appendChild(compRow);

    grid.appendChild(card);
  });
}

  function openSubjectHub(subjectKey) {
    state.courses.subjectKey = subjectKey;
    saveState();
    pushCourses("subject-hub");
    renderSubjectHub();
  }

  // ---------------------------
  // Subject Hub rendering
  // ---------------------------
  function renderSubjectHub() {
    const profile = loadProfile();
    const subj = subjectByKey(state.courses.subjectKey);

    const titleEl = $("#subject-hub-title");
    const metaEl = $("#subject-hub-meta");
    if (titleEl) titleEl.textContent = subj ? subj.title : "Subject";
    if (metaEl) {
      const us = profile?.subjects?.find(x => x.key === state.courses.subjectKey);
      metaEl.textContent = us ? `${us.mode.toUpperCase()} • ${us.pinned ? "PINNED" : "NOT PINNED"}` : "NOT ADDED";
    }

         // ---- Availability toggles in Subject Hub (Tours only when allowed) ----
    const toursBtn = document.querySelector('#courses-subject-hub [data-action="open-tours"]');
    const toursSub = toursBtn?.querySelector(".muted.small");

    if (toursBtn) {
      const eligibility = canOpenActiveTours(profile, state.courses.subjectKey);

      // Additional subjects: tours do not exist by spec
      if (isAdditionalSubjectKey(state.courses.subjectKey)) {
        toursBtn.disabled = true;
        if (toursSub) toursSub.textContent = "Для дополнительных предметов туры не проводятся.";
      } else if (!eligibility.ok) {
        toursBtn.disabled = true;
        if (toursSub) {
          if (eligibility.reason === "not_school") toursSub.textContent = t("disabled_not_school");
          else if (eligibility.reason === "not_competitive") toursSub.textContent = t("disabled_not_competitive");
          else toursSub.textContent = t("not_available");
        }
      } else {
        toursBtn.disabled = false;
        if (toursSub) toursSub.textContent = "Активные и прошедшие";
      }
    }

    updateTopbarForView("courses");
  }

  // ---------------------------
  // Lessons (demo)
  // ---------------------------
  function renderLessons() {
    const list = $("#lessons-list");
    const subj = subjectByKey(state.courses.subjectKey);
    if (!list) return;

    list.innerHTML = "";

    const demoLessons = [
      { id: "l1", title: "Lesson 1 — Intro", topic: "Basics" },
      { id: "l2", title: "Lesson 2 — Core", topic: "Core" },
      { id: "l3", title: "Lesson 3 — Practice", topic: "Application" }
    ];

    demoLessons.forEach(lesson => {
      const item = document.createElement("div");
      item.className = "list-item";
      item.innerHTML = `
        <div style="font-weight:800">${lesson.title}</div>
        <div class="muted small">${subj ? subj.title : ""} • ${lesson.topic}</div>
      `;
      item.addEventListener("click", () => {
        state.courses.lessonId = lesson.id;
        saveState();
        pushCourses("video");
        renderVideo(lesson);
      });
      list.appendChild(item);
    });
  }

  function renderVideo(lesson) {
    const tEl = $("#video-title");
    const mEl = $("#video-meta");
    if (tEl) tEl.textContent = lesson?.title || "Video";
    if (mEl) mEl.textContent = lesson?.topic || "";
    updateTopbarForView("courses");
  }

  // ---------------------------
  // Practice (pause/resume) — demo logic
  // ---------------------------
  function loadPracticeDraft() {
    return safeJsonParse(localStorage.getItem(LS.practiceDraft), null);
  }

  function savePracticeDraft(draft) {
    localStorage.setItem(LS.practiceDraft, JSON.stringify(draft));
  }

  function clearPracticeDraft() {
    localStorage.removeItem(LS.practiceDraft);
  }

  function buildDemoPracticeQuestions() {
    return Array.from({ length: 10 }).map((_, i) => ({
      id: `pq${i + 1}`,
      text: `Вопрос практики #${i + 1}`,
      options: ["A", "B", "C", "D"].map(o => ({ id: o, label: `Вариант ${o}` })),
      correct: "A"
    }));
  }

  function startPracticeNew() {
    const draft = {
      attempt_id: `p_${Date.now()}`,
      subjectKey: state.courses.subjectKey,
      started_at: nowISO(),
      status: "in_progress",
      qIndex: 0,
      elapsed: 0,
      answers: [],
      questions: buildDemoPracticeQuestions()
    };
    savePracticeDraft(draft);
    openPracticeQuiz(draft);
  }

  function openPracticeStart() {
    const draft = loadPracticeDraft();
    if (draft && draft.status === "in_progress" && draft.subjectKey === state.courses.subjectKey) {
      const ok = confirm(t("practice_resume_prompt"));
      if (ok) {
        openPracticeQuiz(draft);
      } else {
        startPracticeNew();
      }
      return;
    }
    pushCourses("practice-start");
  }

  let practiceTimer = null;

  function openPracticeQuiz(draft) {
    state.quizLock = "practice";
    saveState();

    if (getCoursesTopScreen() !== "practice-quiz") pushCourses("practice-quiz");

    renderPracticeQuestion(draft);
    updateTopbarForView("courses");
    startPracticeTick();
  }

  function renderPracticeQuestion(draft) {
    const q = draft.questions[draft.qIndex];
    const qno = $("#practice-qno");
    const qtext = $("#practice-question");
    const wrap = $("#practice-options");
    if (qno) qno.textContent = `${draft.qIndex + 1}/10`;
    if (qtext) qtext.textContent = q.text;
    if (!wrap) return;

    wrap.innerHTML = "";
    q.options.forEach(opt => {
      const row = document.createElement("label");
      row.className = "option";
      row.innerHTML = `
        <input type="radio" name="practice-opt" value="${opt.id}">
        <span>${opt.label}</span>
      `;
      wrap.appendChild(row);
    });
  }

  function startPracticeTick() {
    stopPracticeTick();
    let remaining = 30;
    const timerEl = $("#practice-timer");
    if (timerEl) timerEl.textContent = `00:${String(remaining).padStart(2, "0")}`;

    practiceTimer = setInterval(() => {
      remaining -= 1;
      if (remaining <= 0) {
        stopPracticeTick();
        handlePracticeSubmit(true);
        return;
      }
      if (timerEl) timerEl.textContent = `00:${String(remaining).padStart(2, "0")}`;
    }, 1000);
  }

  function stopPracticeTick() {
    if (practiceTimer) clearInterval(practiceTimer);
    practiceTimer = null;
  }

  function handlePracticePause() {
    const draft = loadPracticeDraft();
    if (!draft || draft.status !== "in_progress") return;

    stopPracticeTick();
    state.quizLock = null;
    saveState();

    showToast(t("practice_paused"));
    replaceCourses("subject-hub");
    renderSubjectHub();
  }

  function handlePracticeSubmit(isAutoTimeout = false) {
    const draft = loadPracticeDraft();
    if (!draft || draft.status !== "in_progress") return;

    const q = draft.questions[draft.qIndex];

    let selected = null;
    const checked = $('input[name="practice-opt"]:checked');
    if (checked) selected = checked.value;

    draft.answers.push({
      question_id: q.id,
      answer: selected,
      answered: !!selected,
      is_correct: selected ? (selected === q.correct) : false,
      reason: isAutoTimeout ? "time_expired" : "manual_submit"
    });

    draft.qIndex += 1;
    savePracticeDraft(draft);

    if (isAutoTimeout) {
      showToast(selected ? t("toast_time_expired_answer_saved") : t("toast_time_expired_no_answer"));
    }

    if (draft.qIndex >= draft.questions.length) {
      finishPractice(draft);
    } else {
      renderPracticeQuestion(draft);
      startPracticeTick();
    }
  }

  function finishPractice(draft) {
    stopPracticeTick();
    draft.status = "finished";
    draft.finished_at = nowISO();
    savePracticeDraft(draft);

    const score = draft.answers.filter(a => a.is_correct).length;
    const meta = $("#practice-result-meta");
    if (meta) meta.textContent = `Score: ${score}/10`;

    state.quizLock = null;
    saveState();

    pushCourses("practice-result");
  }

  // ---------------------------
  // Tour (demo) — strict: no pause, no back
  // ---------------------------
  let tourTimer = null;

  function openTourRules() {
    pushCourses("tour-rules");
    const cb = $("#tour-rules-accept");
    if (cb) cb.checked = false;
  }

  function openTourQuiz() {
    const accept = $("#tour-rules-accept");
    if (!accept || !accept.checked) {
      showToast(t("tour_rules_accept_required"));
      return;
    }

    state.quizLock = "tour";
state.tourContext = { isArchive: false }; // задел на будущее
saveState();

    pushCourses("tour-quiz");
    startTourTick();
  }

  function startTourTick() {
    stopTourTick();
    let total = 10 * 60;
    renderTourTimer(total);

    tourTimer = setInterval(() => {
      total -= 1;
      renderTourTimer(total);
      if (total <= 0) {
        stopTourTick();
        finishTour();
      }
    }, 1000);
  }

  function renderTourTimer(totalSec) {
    const mm = Math.floor(totalSec / 60);
    const ss = totalSec % 60;
    const el = $("#tour-timer");
    if (el) el.textContent = `${String(mm).padStart(2, "0")}:${String(ss).padStart(2, "0")}`;
  }

  function stopTourTick() {
    if (tourTimer) clearInterval(tourTimer);
    tourTimer = null;
  }

  function finishTour() {
    stopTourTick();
    const meta = $("#tour-result-meta");
    if (meta) meta.textContent = "Score: 0/20";
    if (state.tourContext?.isArchive) {
    showToast("Архивный тур: вне рейтинга");
 }
    state.tourContext = null;
    state.quizLock = null;
    saveState();
    pushCourses("tour-result");
  }

  // ---------------------------
  // Global UI bindings
  // ---------------------------
  function bindTabbar() {
    $$(".tabbar .tab").forEach(btn => {
      btn.addEventListener("click", () => {
        const tab = btn.dataset.tab;
        if (!tab) return;

        if (state.quizLock === "tour") {
          showToast("Tour is in progress");
          return;
        }
        if (state.quizLock === "practice") {
          showToast("Pause practice to leave");
          return;
        }

        setTab(tab);
      });
    });
  }

  function bindTopbar() {
    const backBtn = $("#topbar-back");
    if (!backBtn) return;

    backBtn.addEventListener("click", () => {
      if (state.quizLock) return;

      const topView = state.viewStack?.[state.viewStack.length - 1];

      // If we are on global screen -> go back in global stack
      if (topView && ["resources","news","notifications","community","about","certificates","archive"].includes(topView)) {
        globalBack();
        return;
      }

      // If in profile -> pop profile stack
      if (state.tab === "profile") {
        popProfile();
        return;
      }

      // If in courses -> pop courses stack
      if (state.tab === "courses") {
        popCourses();
        return;
      }
    });
  }

  function bindRegistration() {
    const isSchool = $("#reg-is-school");
    if (isSchool) isSchool.addEventListener("change", updateSchoolFieldsVisibility);
    updateSchoolFieldsVisibility();

    initRegionDistrictUI();

    const form = $("#reg-form");
    if (!form) return;

    form.addEventListener("submit", (e) => {
      e.preventDefault();

      const fullName = $("#reg-fullname")?.value?.trim() || "";
      const lang = $("#reg-language")?.value || "ru";

      const region = $("#reg-region")?.value || "";
      const district = $("#reg-district")?.value || "";

      const isSchoolStudent = ($("#reg-is-school")?.value === "yes");
      const school = $("#reg-school")?.value?.trim() || "";
      const klass = $("#reg-class")?.value?.trim() || "";

      const main1 = $("#reg-main-subject-1")?.value || "";
      const main2 = $("#reg-main-subject-2")?.value || "";
      const add1 = $("#reg-additional-subject")?.value || "";

      if (!fullName || !region || !district || !main1) {
        showToast(t("error_try_again"));
        return;
      }

      const subjects = [];

      subjects.push({
        key: main1,
        mode: isSchoolStudent ? "competitive" : "study",
        pinned: true
      });

      if (main2) {
        subjects.push({
          key: main2,
          mode: isSchoolStudent ? "competitive" : "study",
          pinned: true
        });
      }

      if (add1) {
        subjects.push({
          key: add1,
          mode: "study",
          pinned: true
        });
      }

      if (subjects.filter(s => s.mode === "competitive").length > 2) {
        showToast("Competitive subjects limit is 2");
        return;
      }

      const tgUser = tg?.initDataUnsafe?.user || {};
      const avatar = tgUser?.photo_url || "";

      const profile = {
        created_at: nowISO(),
        full_name: fullName,
        language: lang,
        is_school_student: isSchoolStudent,
        region,
        district,
        school: isSchoolStudent ? school : "",
        class: isSchoolStudent ? klass : "",
        telegram: {
          id: tgUser?.id || null,
          username: tgUser?.username || null,
          first_name: tgUser?.first_name || null,
          last_name: tgUser?.last_name || null,
          photo_url: avatar || null
        },
        subjects
      };

      saveProfile(profile);
      window.i18n?.setLang(lang);

      state.tab = "home";
      state.viewStack = ["home"];
      state.courses.stack = ["all-subjects"];
      state.courses.subjectKey = null;
      state.courses.lessonId = null;
      state.quizLock = null;
      saveState();

      renderAllSubjects();
      renderHome();
      setTab("home");
    });
  }

  function bindActions() {
    document.addEventListener("click", (e) => {
      const btn = e.target.closest("[data-action]");
      if (!btn) return;

      const action = btn.dataset.action;

      // ---------- Global navigation actions (available everywhere) ----------
      if (action === "back") { // generic back
        if (state.quizLock) return;
        const topView = state.viewStack?.[state.viewStack.length - 1];
        if (topView && ["resources","news","notifications","community","about","certificates","archive"].includes(topView)) {
          globalBack();
          return;
        }
        if (state.tab === "courses") {
          popCourses();
          return;
        }
        return;
      }

      if (action === "go-home") { setTab("home"); return; }
      if (action === "go-profile") { setTab("profile"); return; }
      if (action === "open-ratings") { setTab("ratings"); return; }

      if (action === "open-resources") { openGlobal("resources"); return; }
      if (action === "open-news") { openGlobal("news"); return; }
      if (action === "open-notifications") { openGlobal("notifications"); return; }
      if (action === "open-community") { openGlobal("community"); return; }
      if (action === "open-about") { openGlobal("about"); return; }
      if (action === "open-certificates") { openGlobal("certificates"); return; }
      if (action === "open-archive") {
  if (!canOpenArchiveNow()) {
    showToast("Архив откроется после завершения активного тура.");
    return;
  }
  openGlobal("archive");
  return;
}

         // All Subjects from anywhere (Home tile, etc.)
if (action === "open-all-subjects") {
  if (state.quizLock) return;
  setTab("courses");
  replaceCourses("all-subjects");
  renderAllSubjects();
  return;
}

      // Community links
      if (action === "open-channel") {
        openExternal("https://t.me/iClubuzofficial");
        return;
      }
      if (action === "open-chat") {
        openExternal("https://t.me/+yp3GKhnohKQxOTdi");
        return;
      }

      // Resources hub: global books button (still placeholder)
      if (action === "open-books-global") {
        showToast("Books list: подключим через базу");
        return;
      }

      // ---------- Tab-specific / Courses actions ----------
        if (state.tab !== "courses") {
        // Profile quick buttons -> route to global screens
        if (action === "profile-settings") {
          setTab("profile");
          openProfileSettings();
          return;
        }
        if (action === "profile-settings-back") {
          popProfile();
          return;
        }
        if (action === "profile-certificates") { openGlobal("certificates"); return; }
        if (action === "profile-community") { openGlobal("community"); return; }
        if (action === "profile-about") { openGlobal("about"); return; }
        return;
      }

      // Courses actions
      if (action === "to-subject-hub") {
        replaceCourses("subject-hub");
        renderSubjectHub();
        return;
      }

      if (action === "open-all-subjects") {
        replaceCourses("all-subjects");
        renderAllSubjects();
        return;
      }

      if (action === "open-lessons") {
        pushCourses("lessons");
        renderLessons();
        return;
      }

      if (action === "open-practice") {
        openPracticeStart();
        return;
      }

      if (action === "practice-start") {
        startPracticeNew();
        return;
      }

      if (action === "practice-pause") {
        handlePracticePause();
        return;
      }

      if (action === "practice-submit") {
        handlePracticeSubmit(false);
        return;
      }

      if (action === "practice-review") {
        pushCourses("practice-review");
        return;
      }

      if (action === "practice-recommendations") {
        pushCourses("practice-recs");
        return;
      }

      if (action === "practice-back-to-result") {
        // go to result without destroying stack
        // simplest: pop until practice-result
        while (state.courses.stack.length > 0 && getCoursesTopScreen() !== "practice-result") {
          state.courses.stack.pop();
        }
        if (state.courses.stack.length === 0) state.courses.stack = ["practice-result"];
        saveState();
        showCoursesScreen(getCoursesTopScreen());
        return;
      }

      if (action === "practice-again") {
        clearPracticeDraft();
        startPracticeNew();
        return;
      }

      if (action === "open-tours") {
        const profile = loadProfile();
        const eligibility = canOpenActiveTours(profile, state.courses.subjectKey);
        if (!eligibility.ok) {
          toastToursDenied(eligibility.reason);
          return;
        }
        pushCourses("tours");
        return;
      }

       if (action === "open-archive-tours") {
  if (!canOpenArchiveNow()) {
    showToast("Архив откроется после завершения активного тура.");
    return;
  }
  // пока архив — глобальный экран
  openGlobal("archive");
  return;
}

      if (action === "tour-start") {
        openTourQuiz();
        return;
      }

      if (action === "tour-submit") {
        finishTour();
        return;
      }

      if (action === "tour-review") {
        pushCourses("tour-review");
        return;
      }

      if (action === "tour-back-to-result") {
        while (state.courses.stack.length > 0 && getCoursesTopScreen() !== "tour-result") {
          state.courses.stack.pop();
        }
        if (state.courses.stack.length === 0) state.courses.stack = ["tour-result"];
        saveState();
        showCoursesScreen(getCoursesTopScreen());
        return;
      }

      if (action === "tour-certificate") {
        openGlobal("certificates");
        return;
      }

      if (action === "open-books") {
        pushCourses("books");
        return;
      }

      if (action === "open-my-recommendations") {
        pushCourses("my-recs");
        return;
      }

      if (action === "video-skip") {
        showToast("video_skipped logged (demo)");
        openPracticeStart();
        return;
      }

      if (action === "video-complete") {
        showToast("video_completed logged (demo)");
        openPracticeStart();
        return;
      }

      if (action === "resources-archive") {
  if (!canOpenArchiveNow()) {
    showToast("Архив откроется после завершения активного тура.");
    return;
  }
  openGlobal("archive");
  return;
}
    });

    // Tours list click (demo)
    const toursList = $("#tours-list");
    if (toursList) {
      toursList.addEventListener("click", () => {
        openTourRules();
      });
    }
  }

  // ---------------------------
  // Boot
  // ---------------------------
  function boot() {
    const profile = loadProfile();
    const lang = profile?.language || getTelegramLang() || "ru";
    window.i18n?.setLang(lang);

    const statusEl = $("#splash-status");
    if (statusEl) statusEl.textContent = t("loading");

    setTimeout(() => {
      if (!isRegistered()) {
        showView("registration");
        bindRegistration();
        return;
      }

      renderAllSubjects();
      renderHome();

      if (!["home", "courses", "ratings", "profile"].includes(state.tab)) {
        state.tab = "home";
        saveState();
      }

      // Start at base tab view
      setTab(state.tab);

      // Restore Courses stack if needed
      if (state.tab === "courses") {
        renderCoursesStack();
        if (getCoursesTopScreen() === "subject-hub") renderSubjectHub();
        if (getCoursesTopScreen() === "all-subjects") renderAllSubjects();
      }
    }, 250);
  }

  function bindUI() {
    bindTabbar();
    bindTopbar();
    bindActions();
  }

  // Init
  bindUI();
  boot();

})();
