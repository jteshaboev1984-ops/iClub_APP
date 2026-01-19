/* =========================================================
   iClub WebApp — app.js (v1 skeleton)
   Plain HTML/CSS/JS, no build tools
   ========================================================= */

(() => {
  "use strict";

  // ---------------------------
  // Helpers
  // ---------------------------
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

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

  // ---------------------------
  // App state (minimal)
  // ---------------------------
  const defaultState = {
    tab: "home", // home | courses | ratings | profile
    courses: {
      stack: ["all-subjects"], // stack of screens in Courses tab
      subjectKey: null,        // current selected subject
      lessonId: null
    },
    quizLock: null // "practice" | "tour" | null
  };

  let state = loadState();

  function loadState() {
    const saved = safeJsonParse(localStorage.getItem(LS.state), null);
    if (!saved) return structuredClone(defaultState);

    // soft-merge
    return {
      ...structuredClone(defaultState),
      ...saved,
      courses: { ...structuredClone(defaultState.courses), ...(saved.courses || {}) }
    };
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
  // UI: Views & Tabs
  // ---------------------------
  const VIEWS = ["splash", "registration", "home", "courses", "ratings", "profile"];

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

    // Splash/Registration are not in tabbar
    showView(tabName);

    // Tabbar active
    $$(".tabbar .tab").forEach(btn => {
      btn.classList.toggle("is-active", btn.dataset.tab === tabName);
    });

    if (tabName === "courses") {
      renderCoursesStack(); // ensure stack screen rendered
    }
  }

  // ---------------------------
  // Topbar behavior
  // ---------------------------
  function updateTopbarForView(viewName) {
    const backBtn = $("#topbar-back");
    const titleEl = $("#topbar-title");
    const subEl = $("#topbar-subtitle");

    // Default
    titleEl.textContent = t("app_name");
    subEl.textContent = "";
    backBtn.style.visibility = "hidden";

    // Splash: hide back
    if (viewName === "splash") {
      titleEl.textContent = t("app_name");
      return;
    }

    if (viewName === "registration") {
      titleEl.textContent = t("reg_title");
      backBtn.style.visibility = "hidden";
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
      titleEl.textContent = "Profile";
      backBtn.style.visibility = "hidden";
      return;
    }

    if (viewName === "courses") {
      // Courses stack decides back visibility
      const canGoBack = canCoursesBack();
      backBtn.style.visibility = (state.quizLock ? "hidden" : (canGoBack ? "visible" : "hidden"));

      // Title based on stack screen
      const top = getCoursesTopScreen();
      if (top === "all-subjects") titleEl.textContent = "Courses";
      if (top === "subject-hub") titleEl.textContent = "Subject";
      if (top === "lessons") titleEl.textContent = "Lessons";
      if (top === "video") titleEl.textContent = "Video";
      if (top === "practice-start") titleEl.textContent = t("practice");
      if (top === "practice-quiz") titleEl.textContent = t("practice");
      if (top === "practice-result") titleEl.textContent = "Practice Result";
      if (top === "tours") titleEl.textContent = "Tours";
      if (top === "tour-rules") titleEl.textContent = t("tour_rules_title");
      if (top === "tour-quiz") titleEl.textContent = "Tour";
      if (top === "tour-result") titleEl.textContent = "Tour Result";
      if (top === "books") titleEl.textContent = "Books";
      if (top === "my-recs") titleEl.textContent = "My Recommendations";

      // Subtitle: subject name when available
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
    "tours",
    "tour-rules",
    "tour-quiz",
    "tour-result",
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
    // quiz lock: do not allow navigation away by stack push/pop
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
    if (state.quizLock) return; // quiz-lock
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
    const el = document.createElement("button");
    el.type = "button";
    el.className = "card-btn";
    el.innerHTML = `
      <div class="card-title">${subj ? subj.title : userSubject.key}</div>
      <div class="muted small">${userSubject.mode === "competitive" ? "Competitive" : "Study"} • ${userSubject.pinned ? "Pinned" : "Not pinned"}</div>
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

    grid.innerHTML = "";
    SUBJECTS.forEach(s => {
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "card-btn";
      btn.dataset.subject = s.key;
      btn.innerHTML = `
        <div class="card-title">${s.title}</div>
        <div class="muted small">${s.type === "main" ? "Main (Cambridge)" : "Additional"}</div>
      `;
      btn.addEventListener("click", () => openSubjectHub(s.key));
      grid.appendChild(btn);
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

    // Ensure topbar updates
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

    // Demo lessons
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
    $("#video-title").textContent = lesson?.title || "Video";
    $("#video-meta").textContent = lesson?.topic || "";
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
    // If there is an in-progress draft for current subject -> offer resume
    const draft = loadPracticeDraft();
    if (draft && draft.status === "in_progress" && draft.subjectKey === state.courses.subjectKey) {
      // show a simple confirm using native confirm (modal system later)
      const ok = confirm(t("practice_resume_prompt"));
      if (ok) {
        openPracticeQuiz(draft);
      } else {
        // start over
        startPracticeNew();
      }
      return;
    }
    pushCourses("practice-start");
  }

  let practiceTimer = null;

  function openPracticeQuiz(draft) {
    // quiz-lock ON for practice (but we allow pause via button)
    state.quizLock = "practice";
    saveState();

    // ensure we are on quiz screen
    // if current top isn't practice-quiz, push it
    if (getCoursesTopScreen() !== "practice-quiz") pushCourses("practice-quiz");

    renderPracticeQuestion(draft);
    updateTopbarForView("courses");
    startPracticeTick();
  }

  function renderPracticeQuestion(draft) {
    const q = draft.questions[draft.qIndex];
    $("#practice-qno").textContent = `${draft.qIndex + 1}/10`;
    $("#practice-question").textContent = q.text;

    const wrap = $("#practice-options");
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
    // demo: 30s per question
    stopPracticeTick();
    let remaining = 30;
    $("#practice-timer").textContent = `00:${String(remaining).padStart(2, "0")}`;

    practiceTimer = setInterval(() => {
      remaining -= 1;
      if (remaining <= 0) {
        stopPracticeTick();
        // auto-save empty answer and move next
        handlePracticeSubmit(true);
        return;
      }
      $("#practice-timer").textContent = `00:${String(remaining).padStart(2, "0")}`;
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
    state.quizLock = null; // unlock so back works after pausing
    saveState();

    showToast(t("practice_paused"));
    // return to subject hub
    // keep draft for resume
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

    // next
    draft.qIndex += 1;

    // save draft
    savePracticeDraft(draft);

    // toast for timeout
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

    // compute score
    const score = draft.answers.filter(a => a.is_correct).length;
    $("#practice-result-meta").textContent = `Score: ${score}/10`;

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
    $("#tour-rules-accept").checked = false;
  }

  function openTourQuiz() {
    // require accept
    if (!$("#tour-rules-accept").checked) {
      showToast(t("tour_rules_accept_required"));
      return;
    }

    state.quizLock = "tour";
    saveState();

    pushCourses("tour-quiz");
    startTourTick();
  }

  function startTourTick() {
    // demo: 10 minutes total
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
    $("#tour-timer").textContent = `${String(mm).padStart(2, "0")}:${String(ss).padStart(2, "0")}`;
  }

  function stopTourTick() {
    if (tourTimer) clearInterval(tourTimer);
    tourTimer = null;
  }

  function finishTour() {
    stopTourTick();
    $("#tour-result-meta").textContent = "Score: 0/20";
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

        // quiz lock: prevent switching away during quiz
        if (state.quizLock === "tour") {
          showToast("Tour is in progress");
          return;
        }
        // practice: allow switching only if paused; while in quiz we keep lock
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
    backBtn.addEventListener("click", () => {
      if (state.quizLock) return;
      if (state.tab === "courses") {
        popCourses();
      }
    });
  }

  function bindRegistration() {
    const isSchool = $("#reg-is-school");
    if (isSchool) isSchool.addEventListener("change", updateSchoolFieldsVisibility);
    updateSchoolFieldsVisibility();

    const form = $("#reg-form");
    if (!form) return;

    form.addEventListener("submit", (e) => {
      e.preventDefault();

      const fullName = $("#reg-fullname").value.trim();
      const lang = $("#reg-language").value;
      const region = $("#reg-region").value.trim();
      const district = $("#reg-district").value.trim();
      const isSchoolStudent = ($("#reg-is-school").value === "yes");
      const school = $("#reg-school").value.trim();
      const klass = $("#reg-class").value.trim();

      const main1 = $("#reg-main-subject-1").value;
      const main2 = $("#reg-main-subject-2").value;
      const add1 = $("#reg-additional-subject").value;

      if (!fullName || !region || !district || !main1) {
        showToast(t("error_try_again"));
        return;
      }

      // Build initial user subjects
      // Rule: main1 becomes competitive #1 ONLY if school student; else treat as main but study mode.
      const subjects = [];

      subjects.push({
        key: main1,
        mode: isSchoolStudent ? "competitive" : "study",
        pinned: true
      });

      // optional second main subject: if school student -> competitive #2; else study
      if (main2) {
        subjects.push({
          key: main2,
          mode: isSchoolStudent ? "competitive" : "study",
          pinned: true
        });
      }

      // optional additional: always study
      if (add1) {
        subjects.push({
          key: add1,
          mode: "study",
          pinned: true
        });
      }

      // Enforce max 2 competitive
      if (subjects.filter(s => s.mode === "competitive").length > 2) {
        // Should not happen via UI, but safe
        showToast("Competitive subjects limit is 2");
        return;
      }

      // Telegram info (optional)
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

      // After registration -> Home tab
      state.tab = "home";
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

  function bindCoursesActions() {
    // Subject Hub actions
    document.addEventListener("click", (e) => {
      const btn = e.target.closest("[data-action]");
      if (!btn) return;
      const action = btn.dataset.action;

      // Global actions
      if (action === "open-news") { showToast("News: soon"); return; }
      if (action === "open-notifications") { showToast("Notifications: soon"); return; }
      if (action === "open-community") { showToast("Community: soon"); return; }

      // Courses-specific
      if (state.tab !== "courses") return;

      if (action === "to-subject-hub") {
        // Return to subject hub (no stack spam)
        replaceCourses("subject-hub");
        renderSubjectHub();
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
        // start new or resume prompt is handled in openPracticeStart before reaching start screen
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
        showToast("Review screen: next step");
        return;
      }

      if (action === "practice-recommendations") {
        showToast("Recommendations: next step");
        return;
      }

      if (action === "practice-again") {
        clearPracticeDraft();
        startPracticeNew();
        return;
      }

      if (action === "open-tours") {
        pushCourses("tours");
        return;
      }

      if (action === "tour-start") {
        openTourQuiz();
        return;
      }

      if (action === "tour-submit") {
        // demo: finish immediately
        finishTour();
        return;
      }

      if (action === "tour-certificate") {
        showToast("Certificate: soon");
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
        // practice available after skip
        openPracticeStart();
        return;
      }

      if (action === "video-complete") {
        showToast("video_completed logged (demo)");
        openPracticeStart();
        return;
      }
    });

    // Tours list click -> rules
    const toursList = $("#tours-list");
    if (toursList) {
      toursList.addEventListener("click", () => {
        // For now open rules directly
        openTourRules();
      });
    }
  }

  function bindProfileActions() {
    document.addEventListener("click", (e) => {
      const btn = e.target.closest("[data-action]");
      if (!btn) return;
      const a = btn.dataset.action;

      if (a === "profile-settings") { showToast("Settings: soon"); return; }
      if (a === "profile-certificates") { showToast("Certificates: soon"); return; }
      if (a === "profile-community") { showToast("Community: soon"); return; }
      if (a === "profile-about") { showToast("About: soon"); return; }
    });
  }

  // ---------------------------
  // Boot
  // ---------------------------
  function boot() {
    // Set language early
    const profile = loadProfile();
    const lang = profile?.language || getTelegramLang() || "ru";
    window.i18n?.setLang(lang);

    // Splash -> decide registration vs home
    const statusEl = $("#splash-status");
    if (statusEl) statusEl.textContent = t("loading");

    // Minimal delay for nicer feel
    setTimeout(() => {
      if (!isRegistered()) {
        showView("registration");
        bindRegistration();
        return;
      }

      // Registered: show last tab or home
      renderAllSubjects();
      renderHome();

      // If state tab somehow is splash/registration -> normalize
      if (!["home", "courses", "ratings", "profile"].includes(state.tab)) {
        state.tab = "home";
        saveState();
      }

      setTab(state.tab);

      // If courses tab restored, render stack
      if (state.tab === "courses") {
        renderCoursesStack();
        // If top is subject-hub etc. ensure hub renders
        if (getCoursesTopScreen() === "subject-hub") renderSubjectHub();
      }
    }, 450);
  }

  function bindUI() {
    bindTabbar();
    bindTopbar();
    bindCoursesActions();
    bindProfileActions();
  }

  // Init
  bindUI();
  boot();

})();

