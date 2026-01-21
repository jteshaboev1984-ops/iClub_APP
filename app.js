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
  if (s === null || s === undefined || s === "") return fallback;
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
  practiceDraft: "iclub_practice_draft_v1",
  myRecs: "iclub_my_recs_v1"
};


  // ---------------------------
  // i18n
  // ---------------------------
  const t = (key, vars) => (window.i18n?.t ? window.i18n.t(key, vars) : key);

function applyStaticI18n() {
    document.querySelectorAll("[data-i18n]").forEach(el => {
      const key = el.dataset.i18n;
      if (key) el.textContent = t(key);
    });
    document.querySelectorAll("[data-i18n-placeholder]").forEach(el => {
      const key = el.dataset.i18nPlaceholder;
      if (key) el.setAttribute("placeholder", t(key));
    });
  }
   
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
  prevTab: "home",
  viewStack: ["home"], // global screens stack
  courses: {
    stack: ["all-subjects"],
    subjectKey: null,
    lessonId: null,
    entryTab: "home" 
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
      courses: { ...structuredClone(defaultState.courses), ...(saved.courses || {}) },
      profile: { ...structuredClone(defaultState.profile), ...(saved.profile || {}) }
    };
    // Ensure viewStack sane
    if (!Array.isArray(merged.viewStack) || merged.viewStack.length === 0) merged.viewStack = ["home"];
    if (!["home", "courses", "ratings", "profile"].includes(merged.tab)) merged.tab = "home";
    if (!["home", "courses", "ratings", "profile"].includes(merged.prevTab)) merged.prevTab = merged.tab || "home";
    if (!["home", "courses", "ratings", "profile"].includes(merged.courses.entryTab)) {
      merged.courses.entryTab = merged.prevTab || "home";
    }
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
  // Practice v1 (10Q: 3/5/2 + MCQ+INPUT + per-question timer + attempts history)
  // ---------------------------

  const PRACTICE_CONFIG = {
    total: 10,
    dist: { easy: 3, medium: 5, hard: 2 },
    // таймер по сложности (сек)
    timeByDifficulty: { easy: 45, medium: 60, hard: 90 },
    // максимум сохраняемых попыток
    keepLastAttempts: 5
  };

  // Мини-банк вопросов для практики (позже заменим на базу).
  // ВАЖНО: добавляй/расширяй — но структура должна быть стабильной.
  // type: "mcq" | "input"
  // inputKind: "numeric" | "letter"
  const PRACTICE_BANK = {
    economics: [
      {
        id: "eco_p_001",
        topic: "Basics",
        difficulty: "easy",
        type: "mcq",
        question: "Что такое альтернативная стоимость?",
        options: ["Стоимость производства", "Стоимость упущенной лучшей альтернативы", "Цена товара", "Налог на товар"],
        correctIndex: 1,
        explanation: "Альтернативная стоимость — ценность лучшей упущенной альтернативы при выборе."
      },
      {
        id: "eco_p_002",
        topic: "Elasticity",
        difficulty: "medium",
        type: "input",
        inputKind: "numeric",
        inputHint: "Введите число (например 1.5)",
        question: "Если %ΔQ = 10% и %ΔP = 5%, чему равна эластичность спроса по цене (по модулю)?",
        correctAnswer: "2",
        explanation: "Ed = |%ΔQ / %ΔP| = 10/5 = 2."
      },
      {
        id: "eco_p_003",
        topic: "Demand & Supply",
        difficulty: "hard",
        type: "input",
        inputKind: "letter",
        inputHint: "Введите 1 букву (не a/b/c/d)",
        question: "Какая буква обычно обозначает равновесную цену? (одна буква)",
        correctAnswer: "P",
        explanation: "Чаще всего цену обозначают P (price), равновесную — Pe."
      }
    ],
    mathematics: [
      {
        id: "math_p_001",
        topic: "Algebra",
        difficulty: "easy",
        type: "mcq",
        question: "Чему равно (x^2) * (x^3)?",
        options: ["x^5", "x^6", "x^9", "x^1"],
        correctIndex: 0,
        explanation: "При умножении степеней с одинаковым основанием показатели складываются: 2+3=5."
      },
      {
        id: "math_p_002",
        topic: "Functions",
        difficulty: "medium",
        type: "input",
        inputKind: "numeric",
        inputHint: "Введите число",
        question: "Если f(x)=2x+3, чему равно f(4)?",
        correctAnswer: "11",
        explanation: "2*4+3=11."
      }
    ],
    chemistry: [
      {
        id: "chem_p_001",
        topic: "Basics",
        difficulty: "easy",
        type: "mcq",
        question: "Какой заряд у протона?",
        options: ["-1", "0", "+1", "+2"],
        correctIndex: 2,
        explanation: "Протон имеет заряд +1."
      }
    ],
    biology: [
      {
        id: "bio_p_001",
        topic: "Cells",
        difficulty: "easy",
        type: "mcq",
        question: "Основная функция митохондрий?",
        options: ["Фотосинтез", "Синтез белка", "Производство АТФ", "Хранение ДНК"],
        correctIndex: 2,
        explanation: "Митохондрии — основной источник АТФ."
      }
    ],
    informatics: [
      {
        id: "inf_p_001",
        topic: "Algorithms",
        difficulty: "easy",
        type: "mcq",
        question: "Какой алгоритм обычно имеет сложность O(n log n)?",
        options: ["Binary search", "Merge sort", "Linear search", "Bubble sort (worst)"],
        correctIndex: 1,
        explanation: "Merge sort обычно O(n log n)."
      }
    ]
  };

// ---------------------------
// Reading map (v1 skeleton)
// Later we will fill from конкретных книг по предметам.
// Key idea: topic -> list of reading refs
// ---------------------------
const READING_MAP = {
  // economics: {
  //   "Unemployment": [
  //     { title: "AS Level Economics Coursebook", ref: "Ch 19", pages: "p. 210–225" }
  //   ]
  // }
};

function getReadingRefs(subjectKey, topic) {
  const s = READING_MAP?.[subjectKey] || null;
  if (!s) return [];
  const refs = s?.[topic] || [];
  return Array.isArray(refs) ? refs : [];
}
   
  function getPracticeBankForSubject(subjectKey) {
    return PRACTICE_BANK[subjectKey] || [];
  }

  function shuffle(arr) {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  function normalizeDifficulty(d) {
    const x = String(d || "").toLowerCase();
    if (x === "easy" || x === "medium" || x === "hard") return x;
    return "medium";
  }

  function pickN(pool, n) {
    const s = shuffle(pool);
    return s.slice(0, Math.max(0, n));
  }

    function buildPracticeSet(subjectKey) {
    const bank = getPracticeBankForSubject(subjectKey).map(q => ({ ...q, difficulty: normalizeDifficulty(q.difficulty) }));

    // группируем по сложности
    const by = {
      easy: bank.filter(q => q.difficulty === "easy"),
      medium: bank.filter(q => q.difficulty === "medium"),
      hard: bank.filter(q => q.difficulty === "hard")
    };

    // если банк пустой — делаем fallback (чтобы практика не падала)
    if (bank.length === 0) {
      return Array.from({ length: PRACTICE_CONFIG.total }).map((_, i) => ({
        id: `fallback_${subjectKey}_${i + 1}`,
        topic: "General",
        difficulty: i < 3 ? "easy" : (i < 8 ? "medium" : "hard"),
        type: "mcq",
        question: `Вопрос ${i + 1} (demo)`,
        options: ["A", "B", "C", "D"],
        correctIndex: 0,
        explanation: "Демо-вопрос. Позже заменим на банк/базу."
      }));
    }

    const set = [
      ...pickN(by.easy.length ? by.easy : bank, PRACTICE_CONFIG.dist.easy),
      ...pickN(by.medium.length ? by.medium : bank, PRACTICE_CONFIG.dist.medium),
      ...pickN(by.hard.length ? by.hard : bank, PRACTICE_CONFIG.dist.hard)
    ];

    // если вдруг не набрали 10 — добиваем из общего банка
    const need = PRACTICE_CONFIG.total - set.length;
    if (need > 0) {
      const used = new Set(set.map(x => x.id));
      const rest = bank.filter(x => !used.has(x.id));
      set.push(...pickN(rest.length ? rest : bank, need));
    }

    // “лесенка” сложности: easy -> medium -> hard
    const order = { easy: 1, medium: 2, hard: 3 };
    set.sort((a, b) => (order[a.difficulty] - order[b.difficulty]));

    return set.slice(0, PRACTICE_CONFIG.total);
  }

  function practiceStorageKey(subjectKey) {
    return `practice_history_v1:${subjectKey}`;
  }

  function loadPracticeHistory(subjectKey) {
    try {
      const raw = localStorage.getItem(practiceStorageKey(subjectKey));
      const parsed = raw ? JSON.parse(raw) : null;
      if (!parsed) return { best: null, last: [] };
      return {
        best: parsed.best || null,
        last: Array.isArray(parsed.last) ? parsed.last : []
      };
    } catch {
      return { best: null, last: [] };
    }
  }

  function savePracticeHistory(subjectKey, data) {
    try {
      localStorage.setItem(practiceStorageKey(subjectKey), JSON.stringify(data));
    } catch {}
  }

  function updatePracticeHistory(subjectKey, attempt) {
    const h = loadPracticeHistory(subjectKey);
    const last = [attempt, ...(h.last || [])].slice(0, PRACTICE_CONFIG.keepLastAttempts);

    let best = h.best;
    if (!best || (attempt.percent > best.percent) || (attempt.percent === best.percent && attempt.durationSec < best.durationSec)) {
      best = attempt;
    }

    savePracticeHistory(subjectKey, { best, last });
    return { best, last };
  }

  function formatDateTime(ts) {
    try {
      const d = new Date(ts);
      return d.toLocaleString();
    } catch {
      return "";
    }
  }

  function isValidInputAnswer(q, value) {
    const v = String(value ?? "").trim();
    if (!v) return false;

    if (q.inputKind === "numeric") {
      // допускаем число с точкой/запятой
      return /^-?\d+([.,]\d+)?$/.test(v);
    }

    if (q.inputKind === "letter") {
      // ровно 1 буква, запрещаем a/b/c/d (чтобы не путали с MCQ)
      if (!/^[A-Za-zА-Яа-я]$/.test(v)) return false;
      const low = v.toLowerCase();
      if (low === "a" || low === "b" || low === "c" || low === "d") return false;
      return true;
    }

    return true;
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
    if (!["home", "courses", "ratings", "profile"].includes(tabName)) tabName = "home";
    const prevTab = state.tab;
    if (prevTab && prevTab !== tabName) {
      state.prevTab = prevTab;
      if (tabName === "courses") state.courses.entryTab = prevTab;
    }
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
if (tabName === "ratings") {
  renderRatings(); // ✅ Leaderboard UI skeleton (mock now, DB later)
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
const logoEl = $("#topbar-logo");

if (!backBtn || !titleEl || !subEl) return;
if (logoEl) logoEl.style.display = "none";

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
  subEl.textContent = "Smarter together";
  backBtn.style.visibility = "hidden";
  if (logoEl) logoEl.style.display = "block";
  return;
}

    if (viewName === "ratings") {
      titleEl.textContent = "Ratings";
      backBtn.style.visibility = "hidden";
      return;
    }

        if (viewName === "profile") {
      const top = getProfileTopScreen();

      // Title in ONE place (topbar)
      titleEl.textContent = (top === "settings") ? "Настройки" : t("profile_title");
      subEl.textContent = "";

      // В settings используем внутренний back (внутри экрана), чтобы не было двух стрелок
      backBtn.style.visibility = "hidden";

      // Action справа: ⚙️ показываем только на главном профиле
      const actionBtn = $("#topbar-action");
      if (actionBtn) {
        if (top === "main") {
          actionBtn.style.visibility = "visible";
          actionBtn.innerHTML = `<span class="icon">⚙️</span>`;
        } else {
          actionBtn.style.visibility = "hidden";
        }
      }

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
      if (top === "practice-result") titleEl.textContent = t("practice_result_title");
      if (top === "practice-review") titleEl.textContent = "Разбор ошибок";
      if (top === "practice-recs") titleEl.textContent = "Рекомендации";
      if (top === "tours") titleEl.textContent = "Tours";
      if (top === "tour-rules") titleEl.textContent = t("tour_rules_title");
      if (top === "tour-quiz") titleEl.textContent = "Tour";
      if (top === "tour-result") titleEl.textContent = "Tour Result";
      if (top === "tour-review") titleEl.textContent = "Разбор тура";
      if (top === "books") titleEl.textContent = "Books";
      if (top === "my-recs") titleEl.textContent = t("practice_my_recs_title");

      const subj = subjectByKey(state.courses.subjectKey);
      if (subj && top !== "all-subjects") subEl.textContent = subj.title;

      return;
    }
  }

// ---------------------------
// Ratings (Leaderboard) — UI skeleton now, DB later
// ---------------------------
const ratingsState = {
  scope: "district", // district | region | republic
  q: ""
};

function getLeaderboardDataMock(scope) {
  // Позже заменим на Supabase: district/region/republic + subject/tour + competitive only
  const base = [
    { rank: 1, name: "Shakhzod Alimov", meta: "Tashkent International School", score: 980, time: "12:45", avatar: null },
    { rank: 2, name: "Nilufar Karimova", meta: "Presidential School", score: 975, time: "13:10", avatar: null },
    { rank: 3, name: "Jasur Akhmedov", meta: "Samarkand Lyceum #1", score: 962, time: "14:05", avatar: null },
    { rank: 4, name: "Bekzod Saitov", meta: "School 142, Tashkent", score: 958, time: "14:22", avatar: null },
    { rank: 5, name: "Madina Kenjayeva", meta: "Westminster Academy", score: 944, time: "15:10", avatar: null },
    { rank: 6, name: "Aziz Umarov", meta: "Bukhara State Lyceum", score: 940, time: "15:45", avatar: null },
    { rank: 7, name: "Lola Mansurova", meta: "School 50, Fergana", score: 938, time: "16:02", avatar: null }
  ];

  // Для ощущения “разных” вкладок — слегка двигаем очки
  const delta = (scope === "district") ? 0 : (scope === "region" ? -6 : -12);
  return base.map(x => ({ ...x, score: x.score + delta }));
}

function getMyRankMock(scope) {
  const p = loadProfile();
  const displayName = (p?.full_name || p?.name || "You").trim();
  const district = p?.district || "—";
  const region = p?.region || "—";
  const meta = [district, region].filter(Boolean).join(" • ");

  // Мок “моего” места и очков
  const rank = (scope === "district") ? 12 : (scope === "region" ? 28 : 64);
  const score = (scope === "district") ? 892 : (scope === "region" ? 861 : 820);
  const time = "18:30";

  return { rank, name: displayName, meta, score, time };
}

function renderRatings() {
  const listEl = $("#ratings-list");
  const mybar = $("#ratings-mybar");
  const myRankEl = $("#ratings-mybar-rank");
  const myNameEl = $("#ratings-mybar-name");
  const myMetaEl = $("#ratings-mybar-meta");
  const myScoreEl = $("#ratings-mybar-score");
  const myTimeEl = $("#ratings-mybar-time");

  if (!listEl) return;

  // 1) buttons state
  $$(".lb-segment .seg-btn").forEach(btn => {
    const active = btn.dataset.scope === ratingsState.scope;
    btn.classList.toggle("is-active", active);
    btn.setAttribute("aria-selected", active ? "true" : "false");
  });

  // 2) data (mock now)
  const data = getLeaderboardDataMock(ratingsState.scope);

  // 3) filter by query
  const q = String(ratingsState.q || "").trim().toLowerCase();
  const filtered = q
    ? data.filter(x => String(x.name || "").toLowerCase().includes(q))
    : data;

  // 4) render list
  if (filtered.length === 0) {
    listEl.innerHTML = `<div class="empty muted">Ничего не найдено.</div>`;
  } else {
    listEl.innerHTML = filtered.map(row => {
      const topClass = row.rank === 1 ? "is-top1" : (row.rank === 2 ? "is-top2" : (row.rank === 3 ? "is-top3" : ""));
      const safeName = escapeHTML(row.name);
      const safeMeta = escapeHTML(row.meta || "");
      const safeTime = escapeHTML(row.time || "");
      const score = Number(row.score || 0);

      return `
        <div class="lb-row">
          <div class="lb-rank">
            <div class="lb-rank-badge ${topClass}">${row.rank}</div>
          </div>

          <div class="lb-student">
            <div class="lb-avatar">${row.avatar ? `<img src="${escapeHTML(row.avatar)}" alt="">` : ""}</div>
            <div class="lb-student-txt">
              <div class="lb-name">${safeName}</div>
              <div class="lb-meta">${safeMeta}</div>
            </div>
          </div>

          <div class="lb-score">${score}</div>
          <div class="lb-time">${safeTime}</div>
        </div>
      `;
    }).join("");
  }

  // 5) my rank bar (mock)
  const my = getMyRankMock(ratingsState.scope);
  if (mybar && myRankEl && myNameEl && myMetaEl && myScoreEl && myTimeEl) {
    myRankEl.textContent = String(my.rank ?? "—");
    myNameEl.textContent = String(my.name ?? "—");
    myMetaEl.textContent = String(my.meta ?? "—");
    myScoreEl.textContent = `${String(my.score ?? "—")} pts`;
    myTimeEl.textContent = String(my.time ?? "—");
    mybar.style.display = "flex";
  }
}

function bindRatingsUI() {
  const search = $("#ratings-search");
  const clear = $("#ratings-search-clear");
  const listEl = $("#ratings-list");

  // segmented tabs
  $$(".lb-segment .seg-btn").forEach(btn => {
    btn.addEventListener("click", () => {
      const scope = btn.dataset.scope;
      if (!scope) return;
      ratingsState.scope = scope;
      renderRatings();
    });
  });

  // search
  if (search) {
    search.addEventListener("input", () => {
      ratingsState.q = search.value || "";
      renderRatings();
    });
  }

  // clear
  if (clear && search) {
    clear.addEventListener("click", () => {
      search.value = "";
      ratingsState.q = "";
      renderRatings();
      search.focus();
    });
  }

  // optional: click on list rows later (open student profile) — пока пусто
  if (listEl) {
    listEl.addEventListener("click", (e) => {
      const row = e.target.closest(".lb-row");
      if (!row) return;
      // future: open profile modal
    });
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
    if (state.courses.stack.length > 1) {
      state.courses.stack.pop();
      saveState();
      showCoursesScreen(getCoursesTopScreen());
      return;
    }
    const targetTab = state.courses.entryTab || state.prevTab || "home";
    setTab(targetTab);
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

    const isActive = (sc === screenName);

    // ✅ жёстко управляем видимостью, чтобы экраны не “слипались”
    el.hidden = !isActive;
    el.style.display = isActive ? "block" : "none";
    el.classList.toggle("is-active", isActive);
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
  // ✅ ДЕРЖИМ СТРУКТУРУ: profile.stack
  state.profile = state.profile && typeof state.profile === "object" ? state.profile : { stack: ["main"] };
  state.profile.stack = Array.isArray(state.profile.stack) ? state.profile.stack : ["main"];

  // ✅ replace = один экран в стеке
  state.profile.stack = [screenName];

  saveState();
  showProfileScreen(screenName);

  // ✅ перерендер нужного экрана
  if (screenName === "main") renderProfileMain();
  if (screenName === "settings") renderProfileSettings();
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
  renderProfileMain();
}

function renderProfileStack() {
  const top = getProfileTopScreen();
  showProfileScreen(top);
  if (top === "settings") renderProfileSettings();
  if (top === "main") renderProfileMain();
}

   function renderProfileSettings() {
  const profile = loadProfile();
  const list = document.getElementById("profile-competitive-list");
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
    row.className = `settings-row ${isOn ? "is-on" : ""}`;

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

      input.addEventListener("change", async () => {
      const fresh = loadProfile();
      if (!fresh) return;

      const subjects = Array.isArray(fresh.subjects) ? structuredClone(fresh.subjects) : [];
      const idx = subjects.findIndex(s => s.key === subj.key);

      // ensure exists
      if (idx === -1) subjects.push({ key: subj.key, mode: "study", pinned: false });

      const next = subjects.map(s => ({ ...s }));

      // toggle
            // toggle
      const was = next.find(s => s.key === subj.key);
      const turningOn = !isCompetitiveForUser(fresh, subj.key);

      // ✅ Confirmations (через модалку, чтобы Telegram точно показывал)
      const ok = await uiConfirm({
        title: turningOn ? "Competitive режим" : "Выключить Competitive",
        message: turningOn
          ? "Сделать этот предмет Competitive?\n\nЭто включит: туры, рейтинги, сертификаты.\nУчебный режим останется доступен."
          : "Убрать предмет из Competitive?\n\nТуры/рейтинг/сертификаты по предмету станут недоступны.\nУчебный режим останется.",
        okText: turningOn ? "Включить" : "Выключить",
        cancelText: "Отмена"
      });

      if (!ok) {
        // revert UI to previous state
        input.checked = !turningOn;
        return;
      }

      if (turningOn) {
        const compNow = next.filter(s => s.mode === "competitive").length;
        if (compNow >= 2) {
          // revert UI + alert
          input.checked = false;
          await uiAlert({
            title: "Лимит Competitive",
            message: "Максимум 2 предмета в Competitive.\nСначала выключите другой предмет.",
            okText: "Понял"
          });
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
      // --- Language selector ---
  const langSel = document.getElementById("profile-settings-language");
  if (langSel) {
    langSel.value = profile.language || "ru";
    langSel.onchange = () => {
      const fresh = loadProfile();
      if (!fresh) return;
      const nextLang = String(langSel.value || "ru");
      fresh.language = nextLang;
      saveProfile(fresh);

      window.i18n?.setLang(nextLang);
      applyStaticI18n(); 

      // Перерисуем ключевые места
      renderHome();
      if (state.tab === "courses") {
        renderAllSubjects();
        if (getCoursesTopScreen() === "subject-hub") renderSubjectHub();
      }
      renderProfileMain();
      showToast("Язык обновлён");
    };
  }

  // --- Pinned list ---
    const pinnedToggleBtn = document.getElementById("profile-settings-pinned-toggle");
  if (pinnedToggleBtn) {
    const expanded = !!state.profile?.pinnedExpanded;
    pinnedToggleBtn.textContent = expanded ? "Скрыть" : "Показать все";
    pinnedToggleBtn.onclick = () => {
      state.profile = state.profile && typeof state.profile === "object" ? state.profile : { stack: ["main"] };
      state.profile.pinnedExpanded = !state.profile.pinnedExpanded;
      saveState();
      renderProfileSettings();
    };
  }

  const pinnedWrap = document.getElementById("profile-settings-pinned-list");
  if (pinnedWrap) {
    pinnedWrap.innerHTML = "";

    const expanded = !!state.profile?.pinnedExpanded;

    const userSubjects = Array.isArray(profile.subjects) ? profile.subjects : [];
    const pinnedSet = new Set(userSubjects.filter(s => !!s.pinned).map(s => s.key));

    const listKeys = expanded
      ? SUBJECTS.map(s => s.key)
      : Array.from(pinnedSet);

    if (!listKeys.length) {
      pinnedWrap.innerHTML = `<div class="empty muted">Пока нет закреплённых. Нажмите “Показать все” и выберите.</div>`;
    } else {
      listKeys.forEach(key => {
        const subj = subjectByKey(key);
        const title = subj ? subj.title : key;

        const isPinned = pinnedSet.has(key);

        const row = document.createElement("div");
        row.className = `settings-row ${isPinned ? "is-on" : ""}`;

        row.innerHTML = `
          <div>
            <div style="font-weight:900">${escapeHTML(title)}</div>
            <div class="muted small">${isPinned ? "Pinned" : "Not pinned"}</div>
          </div>
          <label class="switch">
            <input type="checkbox" ${isPinned ? "checked" : ""}>
            <span class="slider"></span>
          </label>
        `;

        const input = row.querySelector('input[type="checkbox"]');
        input.addEventListener("change", () => {
          const fresh = loadProfile();
          if (!fresh) return;

          const updated = togglePinnedSubject(fresh, key);
          saveProfile(updated);

          renderHome();
          if (state.tab === "courses") renderAllSubjects();
          renderProfileMain();
          renderProfileSettings();
        });

        pinnedWrap.appendChild(row);
      });
    }
  }

  function renderProfileMain() {
  const profile = loadProfile();

  const nameEl = document.getElementById("profile-dash-name");
  const metaEl = document.getElementById("profile-dash-meta");
  const avatarEl = document.getElementById("profile-avatar");
  const avatarInitials = document.getElementById("profile-avatar-initials");
  const currentLevelEl = document.getElementById("profile-current-level");
  const slotsCountEl = document.getElementById("profile-competitive-slots-count");
  const slotsListEl = document.getElementById("profile-competitive-slots-list");
     
  const compEl = document.getElementById("profile-metric-competitive");
  const studyEl = document.getElementById("profile-metric-study");

  const bestEl = document.getElementById("profile-metric-best");
  const trendEl = document.getElementById("profile-metric-trend");
  const stabilityEl = document.getElementById("profile-metric-stability");
  const toursEl = document.getElementById("profile-metric-tours");

  const hintEl = document.getElementById("profile-dash-hint");
  const ratingsBtn = document.querySelector('[data-action="profile-open-ratings"]');

  if (!nameEl || !metaEl || !compEl || !studyEl || !bestEl || !trendEl || !stabilityEl || !toursEl) return;

    if (!profile) {
    nameEl.textContent = "Сначала регистрация";
    metaEl.textContent = "—";
    if (avatarEl) avatarEl.style.backgroundImage = "";
    if (avatarInitials) avatarInitials.textContent = "";
    if (currentLevelEl) currentLevelEl.textContent = "—";
    if (slotsCountEl) slotsCountEl.textContent = "0/2";
    if (slotsListEl) slotsListEl.innerHTML = `<div class="empty muted">${t("home_need_registration")}</div>`;
       
    compEl.textContent = "0";
    studyEl.textContent = "0";

    bestEl.textContent = "—";
    trendEl.textContent = "—";
    stabilityEl.textContent = "—";
    toursEl.textContent = "—";

    if (ratingsBtn) ratingsBtn.disabled = true;

    if (hintEl) hintEl.textContent = "После регистрации профиль станет вашим дашбордом.";
    return;
  }


  const fullName = String(profile.full_name || "").trim();
  nameEl.textContent = fullName || "Профиль";

  if (avatarEl) {
    const photo = profile?.telegram?.photo_url || "";
    avatarEl.style.backgroundImage = photo ? `url("${photo}")` : "";
    if (avatarInitials) avatarInitials.textContent = photo ? "" : (fullName.split(" ").map(p => p[0]).slice(0, 2).join("").toUpperCase() || "IC");
  }

  const metaParts = [];
  if (profile.region) metaParts.push(profile.region);
  if (profile.district) metaParts.push(profile.district);
  if (profile.school) metaParts.push(`№${String(profile.school).replace(/^№/,"")}`);
  if (profile.class) metaParts.push(`${profile.class} класс`);
  metaEl.textContent = metaParts.join(" • ") || "—";

    const subjects = Array.isArray(profile.subjects) ? profile.subjects : [];
  const comp = subjects.filter(s => s.mode === "competitive");
  const study = subjects.filter(s => s.mode === "study");
  const pinned = subjects.filter(s => !!s.pinned);

  compEl.textContent = String(comp.length);
  studyEl.textContent = String(study.length);

  // --- Best / Trend / Stability (реальные данные из practice_history_v1:*) ---
  const keys = subjects.map(s => s.key).filter(Boolean);

  // Best (max percent)
  let best = null;
  const allAttempts = [];

  keys.forEach(k => {
    const h = loadPracticeHistory(k);
    if (h?.best) {
      if (!best || (Number(h.best.percent) > Number(best.percent))) best = h.best;
    }
    if (Array.isArray(h?.last)) allAttempts.push(...h.last.map(a => ({ ...a, _subjectKey: k })));
  });

  bestEl.textContent = best ? `${Math.round(Number(best.percent) || 0)}%` : "—";

  // Trend: avg(last 3) - avg(prev 3)
  allAttempts.sort((a, b) => (Number(b.ts) || 0) - (Number(a.ts) || 0));
  const last6 = allAttempts.slice(0, 6);
  if (last6.length >= 4) {
    const a3 = last6.slice(0, 3);
    const b3 = last6.slice(3, 6);

    const avg = arr => arr.reduce((s, x) => s + (Number(x.percent) || 0), 0) / Math.max(1, arr.length);
    const diff = Math.round(avg(a3) - avg(b3));

    trendEl.textContent = (diff === 0) ? "0%" : `${diff > 0 ? "+" : ""}${diff}%`;
  } else {
    trendEl.textContent = "—";
  }

  // Stability: уникальные дни с практикой за последние 7 дней
  const now = Date.now();
  const weekMs = 7 * 24 * 60 * 60 * 1000;
  const days = new Set();
  allAttempts.forEach(a => {
    const ts = Number(a.ts) || 0;
    if (!ts) return;
    if (now - ts > weekMs) return;
    const d = new Date(ts);
    const key = `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`;
    days.add(key);
  });
    const activeDays = days.size;

  if (!allAttempts.length) {
    stabilityEl.textContent = t("profile_stability_no_data");
  } else {
    const pct = Math.round((activeDays / 7) * 100);
    stabilityEl.textContent = (pct > 0) ? `${pct}%` : t("profile_stability_no_activity");
  }

  // Tours: пока нет локальной истории туров в этом фронте — держим “—”
  toursEl.textContent = "—";
  
  if (currentLevelEl) {
    const bestPct = Number(best?.percent || 0);
    const level = bestPct >= 85 ? t("profile_level_advanced") : (bestPct >= 70 ? t("profile_level_intermediate") : (bestPct > 0 ? t("profile_level_beginner") : "—"));
    currentLevelEl.textContent = level;
  }

    if (slotsCountEl) slotsCountEl.textContent = `${comp.length}/2`;
  if (slotsListEl) {
    slotsListEl.innerHTML = "";

    // 1) Активные competitive слоты (0..2)
    comp.forEach(us => {
      const subj = subjectByKey(us.key);
      const row = document.createElement("div");
      row.className = "slot-card";
      row.innerHTML = `
        <div>
          <div class="slot-title">${escapeHTML(subj?.title || us.key)}</div>
          <div class="muted small">${t("profile_slot_hint")}</div>
        </div>
        <button type="button" class="btn mini" data-subject="${escapeHTML(us.key)}">${t("profile_view_btn")}</button>
      `;

      row.querySelector("button")?.addEventListener("click", () => {
        state.courses.subjectKey = us.key;
        saveState();
        setTab("courses");
        replaceCourses("subject-hub");
        renderSubjectHub();
      });

      slotsListEl.appendChild(row);
    });

    // 2) Пустые слоты до 2 (Empty slot + JOIN)
    const emptyCount = Math.max(0, 2 - comp.length);
    for (let i = 0; i < emptyCount; i++) {
      const row = document.createElement("div");
      row.className = "slot-card is-empty";
      row.innerHTML = `
        <div>
          <div class="slot-empty-title">${t("profile_empty_slot")}</div>
          <div class="muted small">${t("reg_competitive_subject_hint")}</div>
        </div>
        <button type="button" class="btn join" data-action="profile-settings">${t("profile_join_btn")}</button>
      `;

      row.querySelector("button")?.addEventListener("click", () => {
        setTab("profile");
        replaceProfile("settings");
      });

      slotsListEl.appendChild(row);
    }
  }
   
  // Disabled state: рейтинг/туры только школьникам
  if (ratingsBtn) {
    const isSchool = !!profile.is_school_student;
    ratingsBtn.disabled = !isSchool;
    if (!isSchool) ratingsBtn.title = t("disabled_not_school");
  }

  if (hintEl) {
    hintEl.textContent = pinned.length
      ? "Закреплённые предметы уже ускоряют доступ. Дальше — стабильность."
      : "Закрепите 1–3 предмета — и вы будете открывать нужное быстрее, чем Telegram.";
  }
 }

     // ---------------------------
  // Modal (for confirmations in Telegram WebApp)
  // ---------------------------
  let modalResolve = null;

  function closeModal(result = null) {
    const root = document.getElementById("modal-root");
    if (!root) return;
    root.innerHTML = "";
    root.setAttribute("aria-hidden", "true");
    document.body.classList.remove("modal-open");
    if (typeof modalResolve === "function") {
      const r = modalResolve;
      modalResolve = null;
      r(result);
    }
  }

  function openModal(html) {
    const root = document.getElementById("modal-root");
    if (!root) return;
    root.innerHTML = html;
    root.setAttribute("aria-hidden", "false");
    document.body.classList.add("modal-open");

    // backdrop close (only if data-close="backdrop")
    const backdrop = root.querySelector("[data-modal-backdrop]");
    if (backdrop) {
      backdrop.addEventListener("click", (e) => {
        if (e.target === backdrop && backdrop.dataset.close === "backdrop") {
          closeModal(false);
        }
      });
    }

    // buttons
    root.querySelectorAll("[data-modal-action]").forEach(btn => {
      btn.addEventListener("click", () => {
        const act = btn.getAttribute("data-modal-action");
        if (act === "ok") closeModal(true);
        if (act === "cancel") closeModal(false);
      });
    });
  }

  function uiConfirm({ title, message, okText = "OK", cancelText = "Cancel" }) {
    return new Promise((resolve) => {
      modalResolve = resolve;

      const html = `
        <div class="modal-backdrop" data-modal-backdrop data-close="none">
          <div class="modal">
            <div class="modal-title">${escapeHTML(title || "")}</div>
            <div class="modal-text">${escapeHTML(message || "")}</div>
            <div class="modal-actions">
              <button type="button" class="btn" data-modal-action="cancel">${escapeHTML(cancelText)}</button>
              <button type="button" class="btn primary" data-modal-action="ok">${escapeHTML(okText)}</button>
            </div>
          </div>
        </div>
      `;

      openModal(html);
    });
  }

  function uiAlert({ title, message, okText = "OK" }) {
    return new Promise((resolve) => {
      modalResolve = resolve;

      const html = `
        <div class="modal-backdrop" data-modal-backdrop data-close="none">
          <div class="modal">
            <div class="modal-title">${escapeHTML(title || "")}</div>
            <div class="modal-text">${escapeHTML(message || "")}</div>
            <div class="modal-actions modal-actions-single">
              <button type="button" class="btn primary" data-modal-action="ok">${escapeHTML(okText)}</button>
            </div>
          </div>
        </div>
      `;

      openModal(html);
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
    const select = $("#reg-is-school");
    const toggle = $("#reg-is-school-toggle");
    const isSchool = toggle ? !!toggle.checked : (select?.value === "yes");
    if (select && toggle) {
      select.value = isSchool ? "yes" : "no";
    }
    const block = $("#reg-school-block");
    if (!block) return;
    block.style.display = isSchool ? "grid" : "none";
  }
  
  function initRegSubjectChips() {
    const wrap = $("#reg-subject-chips");
    const main1 = $("#reg-main-subject-1");
    const main2 = $("#reg-main-subject-2");
    if (!wrap || !main1 || !main2) return;

    const buttons = () => $$("#reg-subject-chips .chip-btn");

    const syncChipsFromSelects = () => {
      const selected = [main1.value, main2.value].filter(Boolean);
      buttons().forEach(btn => {
        btn.classList.toggle("is-active", selected.includes(btn.dataset.subjectKey));
      });
    };

    const syncSelectsFromChips = () => {
      const selected = buttons().filter(b => b.classList.contains("is-active")).map(b => b.dataset.subjectKey);
      main1.value = selected[0] || "";
      main2.value = selected[1] || "";
    };

    wrap.addEventListener("click", (e) => {
      const btn = e.target.closest(".chip-btn");
      if (!btn) return;
      const current = buttons().filter(b => b.classList.contains("is-active"));

      if (btn.classList.contains("is-active")) {
        btn.classList.remove("is-active");
        syncSelectsFromChips();
        return;
      }

      if (current.length >= 2) {
        showToast(t("reg_subjects_limit"));
        return;
      }

      btn.classList.add("is-active");
      syncSelectsFromChips();
    });

    main1.addEventListener("change", syncChipsFromSelects);
    main2.addEventListener("change", syncChipsFromSelects);
    syncChipsFromSelects();
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
    const pinnedWrap = $("#home-study-list");
    if (!compWrap || !pinnedWrap) return;

    compWrap.innerHTML = "";
    pinnedWrap.innerHTML = "";

    if (!profile) {
      compWrap.innerHTML = `<div class="empty muted">${t("home_need_registration")}</div>`;
      pinnedWrap.innerHTML = `<div class="empty muted">${t("home_need_registration")}</div>`;
      return;
    }

    const comp = profile.subjects?.filter(s => s.mode === "competitive") || [];
    const pinned = profile.subjects?.filter(s => !!s.pinned) || [];

    if (!comp.length) compWrap.innerHTML = `<div class="empty muted">${t("home_competitive_empty")}</div>`;
    if (!pinned.length) pinnedWrap.innerHTML = `<div class="empty muted">${t("home_pinned_empty")}</div>`;

    comp.forEach(s => compWrap.appendChild(homeCompetitiveCardEl(s)));
    pinned.slice(0, 4).forEach((s, idx) => pinnedWrap.appendChild(homePinnedTileEl(s, idx)));
  }

   function homeCompetitiveCardEl(userSubject) {
  const subj = subjectByKey(userSubject.key);
  const title = subj ? subj.title : userSubject.key;

    const el = document.createElement("div");
  el.className = "home-competitive-card";

  el.innerHTML = `
    <div class="home-competitive-badge">ACTIVE</div>
    <div class="home-competitive-hero">
      <div class="home-competitive-graph"></div>
    </div>
    <div class="home-competitive-body">
      <div class="home-competitive-module">MODULE 3</div>
      <div class="home-competitive-title">${escapeHTML(title)}</div>
      <div class="home-competitive-meta">
        <span>${t("home_course_completion")}</span>
        <span class="home-competitive-rank">${t("home_rank_label")}: 12th</span>
      </div>
      <div class="home-progress">
        <div class="home-progress-fill" style="width:65%"></div>
      </div>
    </div>
   `;

    const btn = document.createElement("button");
  btn.type = "button";
  btn.className = "btn primary home-competitive-btn";
  btn.textContent = t("home_active_tour");
  btn.addEventListener("click", (e) => {
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

  el.appendChild(btn);
  return el;
}

  function homePinnedTileEl(userSubject, index = 0) {
  const subj = subjectByKey(userSubject.key);
  const title = subj ? subj.title : userSubject.key;
  const lessonCounts = ["8/12", "15/20", "4/10", "2/15"];
  const lessons = lessonCounts[index % lessonCounts.length];

  const el = document.createElement("button");
  el.type = "button";
  el.className = "home-pinned-tile";
  el.innerHTML = `
    <div class="home-pinned-ico">📘</div>
    <div class="home-pinned-title">${escapeHTML(title)}</div>
    <div class="home-pinned-meta">${lessons} ${t("home_lessons_label")}</div>
  `;

  el.addEventListener("click", () => {
    state.courses.subjectKey = userSubject.key;
    saveState();
    setTab("courses");
    replaceCourses("subject-hub");
    renderSubjectHub();
});

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
  // Practice v1 — per spec:
  // 10 questions (3/5/2), MCQ + INPUT, per-question timer, pause/resume,
  // best + last 5 attempts, review + recommendations
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

   function loadMyRecs() {
  return safeJsonParse(localStorage.getItem(LS.myRecs), { bySubject: {} });
}

function saveMyRecs(data) {
  localStorage.setItem(LS.myRecs, JSON.stringify(data));
}

function addMyRecsFromAttempt(attempt) {
  const wrong = (attempt?.details || []).filter(d => !d.isCorrect);
  const topics = Array.from(new Set(wrong.map(d => d.topic || "General")));
  if (!topics.length) return { added: 0, topics: [] };

  const store = loadMyRecs();
  store.bySubject = store.bySubject || {};
  const subjKey = attempt.subjectKey || "unknown";

  const existing = new Set((store.bySubject[subjKey] || []).map(x => x.topic));
  const nowTs = Date.now();

  const add = topics
    .filter(tp => !existing.has(tp))
    .map(tp => ({ topic: tp, ts: nowTs }));

  store.bySubject[subjKey] = [...add, ...(store.bySubject[subjKey] || [])].slice(0, 50);
  saveMyRecs(store);

  return { added: add.length, topics };
}

  function formatMMSS(sec) {
    const s = Math.max(0, Number(sec) || 0);
    const mm = Math.floor(s / 60);
    const ss = s % 60;
    return `${String(mm).padStart(2, "0")}:${String(ss).padStart(2, "0")}`;
  }

  function normalizeNumericInput(v) {
    return String(v ?? "").trim().replace(",", ".");
  }

  // ---- Practice history render (inject into practice-start) ----
  function renderPracticeStart() {
    const subjectKey = state.courses.subjectKey;
    const subj = subjectByKey(subjectKey);
    const section = $("#courses-practice-start");
    if (!section) return;

    // Remove old injected block if exists
    const old = $("#practice-history-card");
    if (old) old.remove();

    const h = loadPracticeHistory(subjectKey);
    const best = h.best;
    const last = h.last || [];

    const card = document.createElement("div");
    card.className = "card";
    card.id = "practice-history-card";

    const bestLine = best
      ? `Лучший результат: ${best.score}/${best.total} (${best.percent}%) • ${best.durationSec}s • ${formatDateTime(best.ts)}`
      : "Лучший результат: пока нет попыток";

    const lastLines = last.length
      ? last.map(a => `• ${a.score}/${a.total} (${a.percent}%) • ${a.durationSec}s • ${formatDateTime(a.ts)}`).join("<br>")
      : "Пока нет попыток";

    card.innerHTML = `
      <div class="card-title">Статистика практики</div>
      <div class="muted small">${escapeHTML(subj?.title || subjectKey || "")}</div>
      <div class="muted" style="margin-top:8px">${bestLine}</div>
      <div class="muted small" style="margin-top:8px">Последние попытки (до 5):<br>${lastLines}</div>
    `;

    // Insert after rules card (second card in section)
    const cards = section.querySelectorAll(".card");
    if (cards && cards.length >= 1) {
      cards[cards.length - 1].after(card);
    } else {
      section.appendChild(card);
    }
  }

  // ---- Practice timer (per-question) ----
  function stopPracticeQuestionTimer() {
    if (state.quiz?.qTimerId) {
      clearInterval(state.quiz.qTimerId);
      state.quiz.qTimerId = null;
    }
  }

  function startPracticeQuestionTimer() {
    stopPracticeQuestionTimer();

    const timerEl = $("#practice-timer");
    if (timerEl) timerEl.textContent = formatMMSS(state.quiz.qTimeLeft);

    state.quiz.qTimerId = setInterval(() => {
      if (!state.quiz || state.quiz.paused) return;

      state.quiz.qTimeLeft -= 1;
      if (timerEl) timerEl.textContent = formatMMSS(state.quiz.qTimeLeft);

      if (state.quiz.qTimeLeft <= 0) {
        stopPracticeQuestionTimer();
        handlePracticeSubmit(true);
      }
    }, 1000);
  }

  // ---- Entry point from Subject Hub ----
  function openPracticeStart() {
  const subjectKey = state.courses.subjectKey;

  // Always open Practice Start screen first (premium UX)
  pushCourses("practice-start");
  renderPracticeStart();

  // If paused draft exists — show Resume button
  const draft = loadPracticeDraft();
  const resumeBtn = $("#practice-resume-btn");
  const restartBtn = $("#practice-restart-btn");

  const canResume = !!(draft?.status === "paused" && draft?.subjectKey === subjectKey && draft?.quiz);

  if (resumeBtn) resumeBtn.style.display = canResume ? "block" : "none";
  if (restartBtn) restartBtn.textContent = canResume ? "Начать заново" : "Начать";

  if (canResume) {
    showToast(t("practice_resume_prompt"));
  }
}

  function startPracticeNew() {
    const subjectKey = state.courses.subjectKey;
    const questions = buildPracticeSet(subjectKey);

    state.quizLock = "practice";
    state.quiz = {
      mode: "practice",
      subjectKey,
      startedAt: Date.now(),
      paused: false,
      pauseStartedAt: null,
      pausedTotalMs: 0,

      index: 0,
      questions,
      // user answers:
      // mcq -> number (selected index), input -> string
      answers: Array.from({ length: questions.length }).map(() => null),
      correct: Array.from({ length: questions.length }).map(() => false),

      // time per question
      qTimeLeft: PRACTICE_CONFIG.timeByDifficulty[questions[0].difficulty] || 60,
      qTimerId: null
    };

    saveState();
    replaceCourses("practice-quiz");
    renderPracticeQuiz();
    startPracticeQuestionTimer();
  }

  // ---- Rendering question (MCQ or INPUT) ----
  function renderPracticeQuiz() {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

    const q = quiz.questions[quiz.index];
    if (!q) return;

    const qno = $("#practice-qno");
    const qtext = $("#practice-question");
    const wrap = $("#practice-options");
    const timerEl = $("#practice-timer");

    if (qno) qno.textContent = `${quiz.index + 1}/${PRACTICE_CONFIG.total}`;
    if (timerEl) timerEl.textContent = formatMMSS(quiz.qTimeLeft);
    if (qtext) qtext.textContent = q.question || "Вопрос…";
    if (!wrap) return;

    wrap.innerHTML = "";

    // Difficulty hint (small)
    const diff = document.createElement("div");
    diff.className = "muted small";
    diff.style.marginBottom = "8px";
    diff.textContent = `Сложность: ${q.difficulty}`;
    wrap.appendChild(diff);

    if (q.type === "mcq") {
      const selectedIndex = quiz.answers[quiz.index];

      (q.options || []).forEach((optText, idx) => {
        const row = document.createElement("label");
        row.className = "option";
        row.innerHTML = `
          <input type="radio" name="practice-opt" value="${idx}">
          <span>${escapeHTML(optText)}</span>
        `;
        const input = row.querySelector('input[type="radio"]');
        if (input && selectedIndex === idx) input.checked = true;

        input?.addEventListener("change", () => {
          quiz.answers[quiz.index] = idx;
          saveState();
          updatePracticeSubmitEnabled();
        });

        wrap.appendChild(row);
      });

      return;
    }

    // INPUT
    const box = document.createElement("div");
    box.className = "input-wrap";
    box.innerHTML = `
      <div class="muted small">${escapeHTML(q.inputHint || "")}</div>
      <input id="practice-input" class="text-input" type="text" placeholder="${escapeHTML(q.inputHint || "")}">
      <div id="practice-input-error" class="muted small" style="margin-top:6px; display:none;"></div>
    `;
    wrap.appendChild(box);

    const inputEl = $("#practice-input");
    const errEl = $("#practice-input-error");
    const prev = quiz.answers[quiz.index];
    if (inputEl && typeof prev === "string") inputEl.value = prev;

    inputEl?.addEventListener("input", () => {
      quiz.answers[quiz.index] = inputEl.value;
      saveState();
      updatePracticeSubmitEnabled();
      if (errEl) errEl.style.display = "none";
    });
     updatePracticeSubmitEnabled();
  }

   function updatePracticeSubmitEnabled() {
  const quiz = state.quiz;
  const btn = $("#practice-submit-btn");
  if (!btn || !quiz || quiz.mode !== "practice") return;

  const q = quiz.questions[quiz.index];
  const ua = quiz.answers[quiz.index];

  let ok = false;

  if (q.type === "mcq") {
    ok = (ua !== null && ua !== undefined);
  } else {
    ok = isValidInputAnswer(q, String(ua ?? "").trim());
  }

  btn.disabled = !ok;
}

  // ---- Pause / Submit / Finish ----
  function handlePracticePause() {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

    stopPracticeQuestionTimer();

    // mark paused time
    quiz.paused = true;
    quiz.pauseStartedAt = Date.now();

    // store snapshot to draft (so even refresh won't kill it)
    savePracticeDraft({
      status: "paused",
      subjectKey: quiz.subjectKey,
      pausedAt: Date.now(),
      quiz
    });

    // unlock UI navigation
    state.quizLock = null;
    state.quiz = null;
    saveState();

    showToast(t("practice_paused"));
    replaceCourses("subject-hub");
    renderSubjectHub();
  }

  function handlePracticeSubmit(isAutoTimeout = false) {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

    const q = quiz.questions[quiz.index];
    const userAns = quiz.answers[quiz.index];

    // Validate: must have answer if manual submit
    if (!isAutoTimeout) {
      if (q.type === "mcq") {
        if (userAns === null || userAns === undefined) {
          showToast("Выберите вариант ответа");
          return;
        }
      } else {
        const val = String(userAns ?? "").trim();
        if (!isValidInputAnswer(q, val)) {
          const errEl = $("#practice-input-error");
          if (errEl) {
            errEl.textContent = "Проверьте формат ответа";
            errEl.style.display = "block";
          } else {
            showToast("Проверьте формат ответа");
          }
          return;
        }
      }
    }

    // Evaluate correctness
    let isCorrect = false;

    if (q.type === "mcq") {
      const idx = (userAns === null || userAns === undefined) ? null : Number(userAns);
      if (idx !== null && idx === Number(q.correctIndex)) isCorrect = true;
    } else {
      const raw = String(userAns ?? "").trim();
      if (raw) {
        if (q.inputKind === "numeric") {
          const u = normalizeNumericInput(raw);
          const c = normalizeNumericInput(q.correctAnswer);
          isCorrect = (u === c);
        } else {
          isCorrect = (raw.toLowerCase() === String(q.correctAnswer || "").trim().toLowerCase());
        }
      }
    }

    quiz.correct[quiz.index] = isCorrect;

    if (isAutoTimeout) {
      showToast(userAns ? t("toast_time_expired_answer_saved") : t("toast_time_expired_no_answer"));
    }

    // Next question or finish
    stopPracticeQuestionTimer();

    const nextIndex = quiz.index + 1;

    if (nextIndex >= quiz.questions.length) {
      finishPractice();
      return;
    }

    quiz.index = nextIndex;
    const nextQ = quiz.questions[quiz.index];
    quiz.qTimeLeft = PRACTICE_CONFIG.timeByDifficulty[nextQ.difficulty] || 60;

    saveState();
    renderPracticeQuiz();
    startPracticeQuestionTimer();
  }

  function finishPractice() {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== "practice") return;

    stopPracticeQuestionTimer();

    // duration excluding pauses
    const finishedAt = Date.now();
    const startedAt = quiz.startedAt || finishedAt;
    const durationMs = Math.max(0, finishedAt - startedAt - (quiz.pausedTotalMs || 0));
    const durationSec = Math.round(durationMs / 1000);

    const total = quiz.questions.length;
    const score = quiz.correct.filter(Boolean).length;
    const percent = Math.round((score / total) * 100);

    // Build details for review/recs
    const details = quiz.questions.map((q, i) => {
      const ua = quiz.answers[i];
      let correctDisplay = "";
      let userDisplay = "";

      if (q.type === "mcq") {
        correctDisplay = (q.options && q.options[q.correctIndex] != null) ? q.options[q.correctIndex] : String(q.correctIndex);
        userDisplay = (ua === null || ua === undefined)
          ? ""
          : ((q.options && q.options[Number(ua)] != null) ? q.options[Number(ua)] : String(ua));
      } else {
        correctDisplay = String(q.correctAnswer ?? "");
        userDisplay = String(ua ?? "").trim();
      }

      return {
        id: q.id,
        topic: q.topic || "General",
        difficulty: q.difficulty,
        type: q.type,
        question: q.question,
        userAnswer: userDisplay,
        correctAnswer: correctDisplay,
        isCorrect: !!quiz.correct[i],
        explanation: q.explanation || ""
      };
    });

    const attempt = {
      ts: finishedAt,
      subjectKey: quiz.subjectKey,
      score,
      total,
      percent,
      durationSec,
      details
    };

    // Save best + last 5
    const hx = updatePracticeHistory(quiz.subjectKey, attempt);

    // Keep last attempt in state for result/review/recs screens
    state.practiceLastAttempt = attempt;

    // Clear paused draft if any
    clearPracticeDraft();

    // Unlock
    state.quizLock = null;
    state.quiz = null;
    saveState();

    // Render result
    const meta = $("#practice-result-meta");

const wrong = attempt.details.filter(d => !d.isCorrect);
const topics = Array.from(new Set(wrong.map(d => d.topic || "General")));

if (meta) {
  meta.textContent =
    `Score: ${attempt.score}/${attempt.total} (${attempt.percent}%) • ${attempt.durationSec}s` +
    ` • ${t("practice_errors")}: ${wrong.length}` +
    ` • ${t("practice_topics")}: ${topics.length}`;
}

// Counters on buttons
const reviewCountEl = $("#practice-review-count");
if (reviewCountEl) reviewCountEl.textContent = String(wrong.length);

const recsCountEl = $("#practice-recs-count");
if (recsCountEl) recsCountEl.textContent = String(topics.length);

// Show result screen (replace quiz screen to avoid "dead" back navigation)
replaceCourses("practice-result");

    // Optional: toast best update
    if (hx.best && hx.best.ts === attempt.ts) {
      showToast("Новый лучший результат");
    }
    syncPracticeResultBadges();
  }

  function renderPracticeReview() {
  const wrap = $("#practice-review-list");
  if (!wrap) return;

  const attempt = state.practiceLastAttempt;
  if (!attempt || !Array.isArray(attempt.details)) {
    wrap.innerHTML = `<div class="empty muted">Нет данных для разбора. Сначала пройдите практику.</div>`;
    return;
  }

  // Group by topic
  const byTopic = new Map();
  attempt.details.forEach((d, idx) => {
    const topic = d.topic || "General";
    if (!byTopic.has(topic)) byTopic.set(topic, []);
    byTopic.get(topic).push({ ...d, _idx: idx });
  });

  // Sort topics: topics with more wrong first, then alphabetically
  const topics = Array.from(byTopic.keys()).sort((a, b) => {
    const wa = byTopic.get(a).filter(x => !x.isCorrect).length;
    const wb = byTopic.get(b).filter(x => !x.isCorrect).length;
    if (wb !== wa) return wb - wa;
    return String(a).localeCompare(String(b));
  });

  wrap.innerHTML = "";

  topics.forEach((topic, tIndex) => {
    const items = byTopic.get(topic);
    const wrongCount = items.filter(x => !x.isCorrect).length;
    const totalCount = items.length;

    const block = document.createElement("div");
    block.className = "card";
    block.style.marginBottom = "10px";

    const head = document.createElement("button");
    head.type = "button";
    head.className = "btn";
    head.style.width = "100%";
    head.style.display = "flex";
    head.style.justifyContent = "space-between";
    head.style.alignItems = "center";
    head.style.gap = "10px";
    head.style.padding = "12px 12px";
    head.style.borderRadius = "16px";

    const left = document.createElement("div");
    left.style.textAlign = "left";
    left.innerHTML = `
      <div style="font-weight:900">${escapeHTML(topic)}</div>
      <div class="muted small">Вопросов: ${totalCount} • Ошибок: ${wrongCount}</div>
    `;

    const right = document.createElement("div");
    right.className = "badge badge-pin";
    right.textContent = wrongCount ? `❌ ${wrongCount}` : `✅ 0`;

    head.appendChild(left);
    head.appendChild(right);

    const body = document.createElement("div");
    body.style.marginTop = "10px";
    body.style.display = (tIndex === 0) ? "block" : "none"; // первая тема раскрыта
    body.dataset.open = (tIndex === 0) ? "1" : "0";

    head.addEventListener("click", () => {
      const open = body.dataset.open === "1";
      body.dataset.open = open ? "0" : "1";
      body.style.display = open ? "none" : "block";
    });

    // Render questions inside topic
    items.forEach(d => {
      const row = document.createElement("div");
      row.className = "list-item";
      row.style.marginBottom = "10px";

      const status = d.isCorrect ? "✅" : "❌";
      const n = d._idx + 1;

      row.innerHTML = `
        <div style="font-weight:900">${status} ${n}. ${escapeHTML(d.difficulty)} • ${escapeHTML(d.type)}</div>
        <div class="muted small" style="margin-top:6px">${escapeHTML(d.question || "")}</div>

        <div class="muted small" style="margin-top:8px">
          Ваш ответ: <b>${escapeHTML(d.userAnswer || "—")}</b>
        </div>
        <div class="muted small">
          Правильно: <b>${escapeHTML(d.correctAnswer || "—")}</b>
        </div>

        ${d.explanation ? `<div class="muted small" style="margin-top:8px">${escapeHTML(d.explanation)}</div>` : ``}
      `;

      body.appendChild(row);
    });

    block.appendChild(head);
    block.appendChild(body);
    wrap.appendChild(block);
  });
}

  function syncPracticeResultBadges() {
  const attempt = state.practiceLastAttempt;
  if (!attempt || !Array.isArray(attempt.details)) return;

  const wrong = attempt.details.filter(d => !d.isCorrect);
  const topics = Array.from(new Set(wrong.map(d => d.topic || "General")));

  const reviewCountEl = $("#practice-review-count");
  if (reviewCountEl) reviewCountEl.textContent = String(wrong.length);

  const recsCountEl = $("#practice-recs-count");
  if (recsCountEl) recsCountEl.textContent = String(topics.length);
}
 
  function renderPracticeRecs() {
    const wrap = $("#practice-recs-list");
    if (!wrap) return;

    const attempt = state.practiceLastAttempt;
    if (!attempt || !Array.isArray(attempt.details)) {
      wrap.innerHTML = `<div class="empty muted">Нет данных для рекомендаций. Сначала пройдите практику.</div>`;
      return;
    }

    // Topics from wrong answers
    const topics = attempt.details
      .filter(d => !d.isCorrect)
      .map(d => d.topic || "General");

    const uniq = Array.from(new Set(topics));

    // Save to "My recommendations" (v1: topics-only)
const res = addMyRecsFromAttempt(attempt);
if (!res.added) {
  // if there are no mistakes -> nothing to save
} else {
  showToast(t("practice_saved_to_my_recs"));
}
     
    if (!uniq.length) {
      wrap.innerHTML = `<div class="empty muted">Ошибок нет — рекомендации не требуются. Неприлично красиво.</div>`;
      return;
    }

    // v1: пока без привязки к книге/страницам — даём структурные “что читать”
    wrap.innerHTML = "";
    uniq.forEach(tp => {
      const item = document.createElement("div");
      item.className = "list-item";
      const refs = getReadingRefs(attempt.subjectKey, tp);

let refsHtml = "";
if (refs.length) {
  refsHtml = `
    <div class="muted small" style="margin-top:6px">
      ${refs.slice(0, 3).map(r =>
        `• ${escapeHTML(r.title || "")}${r.ref ? ` — ${escapeHTML(r.ref)}` : ""}${r.pages ? ` (${escapeHTML(r.pages)})` : ""}`
      ).join("<br>")}
    </div>
  `;
}

item.innerHTML = `
  <div style="font-weight:900">${escapeHTML(tp)}</div>
  <div class="muted small">Рекомендуем повторить теорию и примеры по теме “${escapeHTML(tp)}”.</div>
  ${refsHtml || `<div class="muted small" style="margin-top:6px">Источник: будет добавлен из книги по предмету.</div>`}
  <div style="margin-top:10px">
    <button type="button" class="btn" data-open-books="1">Открыть «Книги»</button>
  </div>
`;

const btn = item.querySelector('button[data-open-books="1"]');
btn?.addEventListener("click", (e) => {
  e.stopPropagation();
  pushCourses("books");
});
      wrap.appendChild(item);
    });
  }

function renderMyRecs() {
  const wrap = $("#my-recs-list");
  if (!wrap) return;

  const subjectKey = state.courses.subjectKey;
  const store = loadMyRecs();
  const list = store?.bySubject?.[subjectKey] || [];

  if (!list.length) {
    wrap.innerHTML = `<div class="empty muted">Пока пусто.</div>`;
    return;
  }

  wrap.innerHTML = "";
  list.forEach(item => {
    const el = document.createElement("div");
    el.className = "list-item";
    el.innerHTML = `
      <div style="font-weight:800">${escapeHTML(item.topic)}</div>
      <div class="muted small">Сохранено: ${escapeHTML(formatDateTime(item.ts))}</div>
    `;
    wrap.appendChild(el);
  });
}
   
    // ---------------------------
  // Tour (strict) — T1+T2+T3 (mock now, DB later)
  // ---------------------------
  const TOUR_CONFIG = {
    total: 20,
    dist: { easy: 6, medium: 9, hard: 5 },
    questionTimeSec: 45,           // per question
    maxViolations: 3,              // anti-cheat threshold
    autoSubmitOnMaxViolations: true
  };

  let tourTick = null;

  function openTourRules() {
    pushCourses("tour-rules");
    const cb = $("#tour-rules-accept");
    if (cb) cb.checked = false;
  }

  // ---------- T3: Data contract ----------
  // UI expects rows in this shape:
  // { id, subject_key, tour_no, difficulty, question_text, options[], correct_index, explanation?, source? }
  function getTourQuestionsMock(subjectKey, tourNo) {
    // 20 вопросов: 6 easy / 9 medium / 5 hard (mock)
    const mk = (i, diff) => ({
      id: `mock_${subjectKey || "subject"}_${tourNo}_${i}`,
      subject_key: subjectKey || "subject",
      tour_no: tourNo || 1,
      difficulty: diff,
      question_text: `Which process occurs during the light-dependent stage of photosynthesis? (Q${i})`,
      options: [
        "Photolysis of water molecules",
        "Fixation of carbon dioxide",
        "Production of glucose",
        "Reduction of NADP to NADPH"
      ],
      correct_index: 0,
      explanation: "Light-dependent reactions include photolysis and formation of ATP/NADPH.",
      source: "Uzbekistan Academic Standards"
    });

    const items = [];
    let i = 1;

    for (let k = 0; k < TOUR_CONFIG.dist.easy; k++) items.push(mk(i++, "easy"));
    for (let k = 0; k < TOUR_CONFIG.dist.medium; k++) items.push(mk(i++, "medium"));
    for (let k = 0; k < TOUR_CONFIG.dist.hard; k++) items.push(mk(i++, "hard"));

    // маленькая перемешка (стабильная)
    return shuffleArrayStable(items, `${subjectKey || "s"}_${tourNo || 1}`);
  }

  function shuffleArrayStable(arr, seedStr) {
    const a = [...arr];
    let seed = 0;
    for (let i = 0; i < seedStr.length; i++) seed = (seed * 31 + seedStr.charCodeAt(i)) >>> 0;
    function rnd() {
      seed = (seed * 1664525 + 1013904223) >>> 0;
      return seed / 0xFFFFFFFF;
    }
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(rnd() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  function initTourSession({ subjectKey = null, tourNo = 1, isArchive = false } = {}) {
    const questions = getTourQuestionsMock(subjectKey, tourNo);

    state.tourContext = {
      isArchive,
      subjectKey,
      tourNo,
      startedAt: Date.now(),
      qStartedAt: Date.now(),
      index: 0,
      correct: 0,
      answers: [],              // {qid, pickedIndex, isCorrect, spentSec}
      violations: 0,
      lastViolationAt: null,
      questionTimeLimit: TOUR_CONFIG.questionTimeSec
    };

    // strict lock only for ACTIVE tour
    state.quizLock = isArchive ? null : "tour";
    saveState();
  }

  function openTourQuiz() {
    const accept = $("#tour-rules-accept");
    if (!accept || !accept.checked) {
      showToast(t("tour_rules_accept_required"));
      return;
    }

    // subjectKey/tourNo можно позже брать из active предмета/тура
    initTourSession({ subjectKey: "biology", tourNo: 4, isArchive: false });

    pushCourses("tour-quiz");
    bindTourAntiCheatOnce();
    startTourTick();
    renderTourQuestion();
  }

  function startTourTick() {
    stopTourTick();
    tourTick = setInterval(() => {
      renderTourHUD();

      // auto-finish if violations too many
      if (!state.tourContext?.isArchive && state.tourContext?.violations >= TOUR_CONFIG.maxViolations) {
        stopTourTick();
        finishTour({ reason: "violations" });
      }

      // auto-finish if question time exceeded and no answer chosen (optional behavior)
      const ctx = state.tourContext;
      if (ctx && !ctx.isArchive) {
        const qElapsed = Math.floor((Date.now() - ctx.qStartedAt) / 1000);
        if (qElapsed >= ctx.questionTimeLimit) {
          // if no selection yet, we keep button disabled; auto mark as wrong and go next
          if (!ctx.answers.some(a => a.index === ctx.index)) {
            submitTourAnswer({ pickedIndex: null, auto: true });
          }
        }
      }
    }, 250);
  }

  function stopTourTick() {
    if (tourTick) clearInterval(tourTick);
    tourTick = null;
  }

  // ---------- T2: Anti-cheat ----------
  let antiCheatBound = false;

  function bindTourAntiCheatOnce() {
    if (antiCheatBound) return;
    antiCheatBound = true;

    document.addEventListener("visibilitychange", () => {
      if (!state.tourContext || state.tourContext.isArchive) return;
      if (document.visibilityState !== "visible") registerTourViolation("visibility");
    });

    window.addEventListener("blur", () => {
      if (!state.tourContext || state.tourContext.isArchive) return;
      registerTourViolation("blur");
    });
  }

  function registerTourViolation(type) {
    const ctx = state.tourContext;
    if (!ctx || ctx.isArchive) return;

    // simple debounce: 1 violation per 2s
    const now = Date.now();
    if (ctx.lastViolationAt && (now - ctx.lastViolationAt) < 2000) return;

    ctx.violations += 1;
    ctx.lastViolationAt = now;
    saveState();

    const warnBtn = $("#tour-warn-btn");
    if (warnBtn) warnBtn.style.display = "inline-flex";

    const warnPill = $("#tour-anti-cheat"); // legacy id might exist elsewhere
    if (warnPill) warnPill.style.display = "inline-flex";

    showToast(`Warning: session monitoring (${ctx.violations}/${TOUR_CONFIG.maxViolations})`);
  }

  // ---------- Render ----------
  function renderTourHUD() {
    const ctx = state.tourContext;
    if (!ctx) return;

    const total = TOUR_CONFIG.total;
    const qNo = Math.min(total, ctx.index + 1);

    const qof = $("#tour-qof");
    if (qof) qof.textContent = `Question ${qNo} of ${total}`;

    const pct = Math.round((qNo / total) * 100);
    const pctEl = $("#tour-progress-pct");
    if (pctEl) pctEl.textContent = `${pct}%`;

    const fill = $("#tour-progress-fill");
    if (fill) fill.style.width = `${pct}%`;

    const badge = $("#tour-badge");
    if (badge) {
      const subjLabel = String(ctx.subjectKey || "SUBJECT").toUpperCase();
      badge.textContent = `CAMBRIDGE ${subjLabel} • TOUR #${ctx.tourNo}`;
    }

    const overall = formatMsToMMSS(Date.now() - ctx.startedAt);
    const overallEl = $("#tour-overall-time");
    if (overallEl) overallEl.textContent = overall;

    const qElapsed = formatMsToMMSS(Date.now() - ctx.qStartedAt);
    const qEl = $("#tour-question-time");
    if (qEl) qEl.textContent = qElapsed;

    // warning visibility
    const warnBtn = $("#tour-warn-btn");
    if (warnBtn) warnBtn.style.display = (!ctx.isArchive && ctx.violations > 0) ? "inline-flex" : "none";
  }

  function renderTourQuestion() {
    const ctx = state.tourContext;
    if (!ctx) return;

    const q = ctx.questions?.[ctx.index];
    if (!q) {
      finishTour({ reason: "done" });
      return;
    }

    ctx.qStartedAt = Date.now();
    saveState();

    const qEl = $("#tour-question");
    if (qEl) qEl.textContent = q.question_text;

    const wrap = $("#tour-options");
    if (wrap) {
      wrap.innerHTML = "";

      q.options.forEach((opt, i) => {
        const btn = document.createElement("button");
        btn.type = "button";
        btn.className = "option";
        btn.dataset.action = "tour-pick";
        btn.dataset.index = String(i);

        btn.innerHTML = `
          <span class="dot" aria-hidden="true"></span>
          <span class="opt-text">${escapeHTML(opt)}</span>
        `;

        wrap.appendChild(btn);
      });
    }

    // disable next until choose
    const next = $("#tour-next-btn");
    if (next) {
      next.disabled = true;
      next.textContent = (ctx.index >= TOUR_CONFIG.total - 1) ? "Finish Tour →" : "Next Question →";
    }

    // clear active option styles
    $$("#tour-options .option").forEach(o => o.classList.remove("is-selected"));
    renderTourHUD();
  }

  function submitTourAnswer({ pickedIndex, auto = false } = {}) {
    const ctx = state.tourContext;
    if (!ctx) return;

    const q = ctx.questions?.[ctx.index];
    if (!q) return;

    const spentSec = Math.max(0, Math.floor((Date.now() - ctx.qStartedAt) / 1000));
    const isCorrect = (pickedIndex !== null && pickedIndex !== undefined) ? (Number(pickedIndex) === Number(q.correct_index)) : false;

    ctx.answers = ctx.answers || [];
    ctx.answers.push({
      qid: q.id,
      pickedIndex: (pickedIndex === null || pickedIndex === undefined) ? null : Number(pickedIndex),
      isCorrect,
      spentSec,
      index: ctx.index
    });

    if (isCorrect) ctx.correct += 1;

    // next index
    ctx.index += 1;
    saveState();

    if (ctx.index >= TOUR_CONFIG.total) {
      finishTour({ reason: auto ? "auto_done" : "done" });
      return;
    }

    renderTourQuestion();
  }

  function finishTour({ reason = "done" } = {}) {
    stopTourTick();

    const ctx = state.tourContext;

    // result meta
    const meta = $("#tour-result-meta");
    if (meta && ctx) {
      meta.textContent = `Score: ${ctx.correct}/${TOUR_CONFIG.total} • Violations: ${ctx.violations || 0}`;
    }

    if (ctx?.isArchive) {
      showToast("Архивный тур: вне рейтинга");
    } else if (reason === "violations") {
      showToast("Tour finished: session violations");
    }

    // unlock
    state.quizLock = null;
    state.tourContext = null;
    saveState();

    pushCourses("tour-result");
  }

  function formatMsToMMSS(ms) {
    const sec = Math.max(0, Math.floor(ms / 1000));
    const mm = Math.floor(sec / 60);
    const ss = sec % 60;
    return `${mm}:${String(ss).padStart(2, "0")}`;
  }

  // ---------------------------
  // Global UI bindings
  // ---------------------------
  function bindTabbar() {
    $$(".tabbar .tab").forEach(btn => {
      btn.addEventListener("click", () => {
        const tab = btn.dataset.tab;
        if (!tab) return;
                 // ✅ Ratings доступен только школьникам
        if (tab === "ratings") {
          const p = loadProfile();
          if (!p || !p.is_school_student) {
            showToast(t("disabled_not_school"));
            return;
          }
        }

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
    const isSchoolToggle = $("#reg-is-school-toggle");
    if (isSchool) isSchool.addEventListener("change", updateSchoolFieldsVisibility);
    if (isSchoolToggle) {
      isSchoolToggle.addEventListener("change", updateSchoolFieldsVisibility);
    }
     updateSchoolFieldsVisibility();

    initRegionDistrictUI();
    initRegSubjectChips(); 

    const form = $("#reg-form");
    if (!form) return;

    form.addEventListener("submit", (e) => {
      e.preventDefault();

      const fullName = $("#reg-fullname")?.value?.trim() || "";
      const lang = $("#reg-language")?.value || "ru";

      const region = $("#reg-region")?.value || "";
      const district = $("#reg-district")?.value || "";

      const isSchoolStudent = ($("#reg-is-school-toggle")?.checked || $("#reg-is-school")?.value === "yes");
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
      applyStaticI18n();

      state.tab = "home";
      state.prevTab = "home";
      state.viewStack = ["home"];
      state.courses.stack = ["all-subjects"];
      state.courses.subjectKey = null;
      state.courses.lessonId = null;
      state.courses.entryTab = "home";
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

            // ===== Profile local navigation (must work from anywhere) =====
      if (action === "profile-settings") {
        setTab("profile");
        replaceProfile("settings");
        return;
      }
    
      if (action === "profile-settings-back") {
        setTab("profile");
        replaceProfile("main");
        return;
      }

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
        if (state.tab === "profile") {
          if (getProfileTopScreen() !== "main") {
            popProfile();
            return;
          }
          setTab(state.prevTab || "home");
          return;
        }
        if (state.tab === "ratings") {
          setTab(state.prevTab || "home");
          return;
        }
        return;
      }

      if (action === "go-home") { setTab("home"); return; }
      if (action === "go-profile") { setTab("profile"); return; }
      if (action === "open-ratings") { setTab("ratings"); return; }
      if (action === "ratings-info") { showToast(t("ratings_info")); return; }
      if (action === "topbar-action") {
       if (state.tab === "profile" && getProfileTopScreen() === "main") {
           replaceProfile("settings");
         }
         return;
       }

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

       if (action === "open-my-recs-global") {
  // логика как из профиля
  const profile = loadProfile();
  const subjects = Array.isArray(profile?.subjects) ? profile.subjects : [];
  const pick =
    subjects.find(s => s.mode === "competitive")?.key ||
    subjects.find(s => s.pinned)?.key ||
    subjects[0]?.key ||
    null;

  if (!pick) {
    showToast("Сначала выберите предметы в Courses.");
    return;
  }

  state.courses.subjectKey = pick;
  saveState();
  setTab("courses");
  replaceCourses("my-recs");
  renderMyRecs();
  return;
}

      // ---------- Tab-specific / Courses actions ----------
        if (action === "profile-certificates") { openGlobal("certificates"); return; }
        if (action === "profile-community") { openGlobal("community"); return; }
        if (action === "profile-about") { openGlobal("about"); return; }
        if (action === "profile-open-my-recs") {
  // открыть "Мои рекомендации" по первому разумному предмету
  const profile = loadProfile();
  const subjects = Array.isArray(profile?.subjects) ? profile.subjects : [];
  const pick =
    subjects.find(s => s.mode === "competitive")?.key ||
    subjects.find(s => s.pinned)?.key ||
    subjects[0]?.key ||
    null;

  if (!pick) {
    showToast("Сначала выберите предметы в Courses.");
    return;
  }

  state.courses.subjectKey = pick;
  saveState();
  setTab("courses");
  replaceCourses("my-recs");
  renderMyRecs();
  return;
}

if (action === "profile-open-courses") {
  setTab("courses");
  replaceCourses("all-subjects");
  renderAllSubjects();
  return;
}

if (action === "profile-open-ratings") {
  setTab("ratings");
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

       if (action === "practice-resume") {
  const subjectKey = state.courses.subjectKey;
  const draft = loadPracticeDraft();
  if (!(draft?.status === "paused" && draft?.subjectKey === subjectKey && draft?.quiz)) {
    showToast(t("not_available"));
    return;
  }

  state.quizLock = "practice";
  state.quiz = draft.quiz;
  state.quiz.paused = false;
  state.quiz.pauseStartedAt = null;
  clearPracticeDraft();

  saveState();
  replaceCourses("practice-quiz");
  renderPracticeQuiz();
  startPracticeQuestionTimer();
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
  renderPracticeReview();
  return;
}

if (action === "practice-recommendations") {
  pushCourses("practice-recs");
  renderPracticeRecs();
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

// pick option
if (action === "tour-pick") {
  const ctx = state.tourContext;
  if (!ctx) return;

  const picked = Number(btn.dataset.index);
  // highlight
  $$("#tour-options .option").forEach(o => o.classList.remove("is-selected"));
  btn.classList.add("is-selected");

  // enable next
  const next = $("#tour-next-btn");
  if (next) next.disabled = false;

  // store temporarily (not final submit yet)
  ctx._pickedIndex = picked;
  saveState();
  return;
}

// next / finish
if (action === "tour-next" || action === "tour-submit") {
  const ctx = state.tourContext;
  if (!ctx) return;

  const picked = (ctx._pickedIndex === null || ctx._pickedIndex === undefined) ? null : Number(ctx._pickedIndex);
  ctx._pickedIndex = null;
  saveState();

  submitTourAnswer({ pickedIndex: picked, auto: false });
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
       renderMyRecs();
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
    applyStaticI18n(); 

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
  bindRatingsUI(); // ✅ Leaderboard controls
}

  // Init
  bindUI();
  boot();

})();
