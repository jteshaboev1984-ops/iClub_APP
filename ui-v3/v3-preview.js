(() => {
  "use strict";

  const root = document.getElementById("v3-app");
  const modeSelect = document.getElementById("v3-mode-select");
  const langSelect = document.getElementById("v3-lang-select");

  const state = {
    screen: "home",
    mode: "core",
    lang: "en",
    mathTab: "mine"
  };

  const COPY = {
    en: {
      home: "Home", study: "Study", ratings: "Ratings", profile: "Profile",
      greeting: "Let’s continue", today: "Today", weekly: "Weekly progress", upcoming: "Upcoming",
      continueLearning: "Continue learning", continue: "Continue", open: "Open", viewFeedback: "View feedback",
      examCheckpoint: "Exam Prep checkpoint", planned: "4 of 6 planned actions completed",
      math: "Mathematics", chemistry: "Chemistry", biology: "Biology", informatics: "Informatics", economics: "Economics",
      practice: "Practice", lessons: "Lessons", retest: "Delayed retest", tourPrep: "Prepare for Tour 3",
      paper1Functions: "Paper 1 • Functions", minutes15: "15 min", minutes20: "20 min",
      aiAssist: "AI Assist", whyNext: "Why this is next",
      aiHomeText: "Your earlier Functions evidence is stable, but this delayed retest is needed to confirm that the skill still holds after time.",
      mentorCare: "Mentor Care", mentorHomeTitle: "Your Paper 1 written solution was reviewed.",
      mentorHomeText: "Show the substitution step more clearly before simplifying.", nextReview: "Next review: Thursday",
      studyTitle: "Study", mine: "Mine", all: "All", examPrep: "EXAM PREP", olympiad: "OLYMPIAD", course: "COURSE",
      cambridgeP1P5: "Cambridge AS • P1 + P5", nextP5: "Next: continue P5", practiceTour2: "Practice • Tour 2",
      lessonsPractice: "Lessons • Practice available",
      mathHubSub: "Cambridge AS Mathematics", examPreparation: "Exam preparation",
      examPreparationSub: "Structured preparation for Paper 1 and Paper 5.", continueExamPrep: "Continue exam preparation",
      p1: "Paper 1", p5: "Paper 5", pure: "Pure Mathematics 1", stats: "Probability & Statistics 1",
      coverage: "Syllabus coverage", evidence: "Evidence", building: "Building", starting: "Starting",
      learning: "Learning", olympiadSection: "Olympiad", resources: "Resources", more: "More",
      olympiadPractice: "Olympiad Practice", tours: "Tours", book: "Book", recommendations: "Recommendations",
      certificates: "Certificates", tourArchive: "Tour archive",
      learningSyllabus: "Learning the syllabus", learningSyllabusSub: "Building syllabus coverage before entering the revision phase.",
      upNext: "Up next", chainRule: "Chain Rule practice", startPractice: "Start practice",
      next: "Next", reprData: "Representation of Data", quickAccess: "Quick access",
      syllabusProgress: "Syllabus progress", corrections: "Corrections & retests", timedPractice: "Timed practice", papers: "Papers",
      aiExamText: "Your basic differentiation evidence is stable, while Chain Rule transfer still needs reinforcement.",
      explainDifferent: "Explain this differently", explainMistake: "Explain my mistake",
      latestReview: "Latest review", reviewed: "Reviewed", writtenSolution: "Paper 1 • Chain Rule written solution",
      tour3: "Mathematics • Tour 3", opens24: "Opens 24 Oct", continuePractice: "Continue practice",
      notImplemented: "This destination is outside the current visual-foundation slice."
    },
    ru: {
      home: "Главная", study: "Учёба", ratings: "Рейтинг", profile: "Профиль",
      greeting: "Продолжим", today: "Сегодня", weekly: "Прогресс недели", upcoming: "Предстоящее",
      continueLearning: "Продолжить обучение", continue: "Продолжить", open: "Открыть", viewFeedback: "Посмотреть комментарий",
      examCheckpoint: "Контрольная точка Exam Prep", planned: "Выполнено 4 из 6 запланированных действий",
      math: "Математика", chemistry: "Химия", biology: "Биология", informatics: "Информатика", economics: "Экономика",
      practice: "Практика", lessons: "Уроки", retest: "Отложенная повторная проверка", tourPrep: "Подготовка к Туру 3",
      paper1Functions: "Paper 1 • Functions", minutes15: "15 мин", minutes20: "20 мин",
      aiAssist: "AI Assist", whyNext: "Почему это следующий шаг",
      aiHomeText: "Предыдущие результаты по Functions стабильны, но эта повторная проверка нужна, чтобы подтвердить сохранение навыка спустя время.",
      mentorCare: "Mentor Care", mentorHomeTitle: "Наставник проверил письменное решение по Paper 1.",
      mentorHomeText: "Показывай шаг подстановки яснее перед упрощением.", nextReview: "Следующая проверка: четверг",
      studyTitle: "Учёба", mine: "Мои", all: "Все", examPrep: "EXAM PREP", olympiad: "ОЛИМПИАДА", course: "КУРС",
      cambridgeP1P5: "Cambridge AS • P1 + P5", nextP5: "Далее: продолжить P5", practiceTour2: "Практика • Тур 2",
      lessonsPractice: "Уроки • Практика доступна",
      mathHubSub: "Cambridge AS Mathematics", examPreparation: "Подготовка к экзамену",
      examPreparationSub: "Структурированная подготовка к Paper 1 и Paper 5.", continueExamPrep: "Продолжить подготовку",
      p1: "Paper 1", p5: "Paper 5", pure: "Pure Mathematics 1", stats: "Probability & Statistics 1",
      coverage: "Покрытие syllabus", evidence: "Подтверждение", building: "Формируется", starting: "Начало",
      learning: "Обучение", olympiadSection: "Олимпиада", resources: "Ресурсы", more: "Ещё",
      olympiadPractice: "Олимпиадная практика", tours: "Туры", book: "Книга", recommendations: "Рекомендации",
      certificates: "Сертификаты", tourArchive: "Архив туров",
      learningSyllabus: "Изучение syllabus", learningSyllabusSub: "Сейчас основная задача — уверенно закрывать syllabus до этапа повторения.",
      upNext: "Следующий шаг", chainRule: "Практика Chain Rule", startPractice: "Начать практику",
      next: "Далее", reprData: "Representation of Data", quickAccess: "Быстрый доступ",
      syllabusProgress: "Прогресс syllabus", corrections: "Исправления и повторные проверки", timedPractice: "Практика на время", papers: "Papers",
      aiExamText: "Базовые навыки differentiation уже стабильны, а применение Chain Rule ещё нужно укрепить.",
      explainDifferent: "Объяснить иначе", explainMistake: "Объяснить мою ошибку",
      latestReview: "Последняя проверка", reviewed: "Проверено", writtenSolution: "Paper 1 • письменное решение Chain Rule",
      tour3: "Математика • Тур 3", opens24: "Откроется 24 окт", continuePractice: "Продолжить практику",
      notImplemented: "Этот раздел пока вне текущего этапа визуальной интеграции."
    },
    uz: {
      home: "Bosh sahifa", study: "O‘qish", ratings: "Reyting", profile: "Profil",
      greeting: "Davom etamiz", today: "Bugun", weekly: "Haftalik progress", upcoming: "Yaqinlashmoqda",
      continueLearning: "O‘qishni davom ettirish", continue: "Davom etish", open: "Ochish", viewFeedback: "Izohni ko‘rish",
      examCheckpoint: "Exam Prep nazorat nuqtasi", planned: "Rejalashtirilgan 6 harakatdan 4 tasi bajarildi",
      math: "Matematika", chemistry: "Kimyo", biology: "Biologiya", informatics: "Informatika", economics: "Iqtisodiyot",
      practice: "Amaliyot", lessons: "Darslar", retest: "Kechiktirilgan qayta tekshiruv", tourPrep: "3-turga tayyorgarlik",
      paper1Functions: "Paper 1 • Functions", minutes15: "15 daq", minutes20: "20 daq",
      aiAssist: "AI Assist", whyNext: "Nega aynan shu keyingi qadam",
      aiHomeText: "Functions bo‘yicha oldingi natijalar barqaror, lekin ko‘nikma vaqt o‘tib ham saqlanganini tasdiqlash uchun qayta tekshiruv kerak.",
      mentorCare: "Mentor Care", mentorHomeTitle: "Paper 1 yozma yechimingiz mentor tomonidan tekshirildi.",
      mentorHomeText: "Soddalashtirishdan oldin o‘rniga qo‘yish qadamini aniqroq ko‘rsating.", nextReview: "Keyingi tekshiruv: payshanba",
      studyTitle: "O‘qish", mine: "Mening", all: "Barchasi", examPrep: "EXAM PREP", olympiad: "OLIMPIADA", course: "KURS",
      cambridgeP1P5: "Cambridge AS • P1 + P5", nextP5: "Keyingi: P5 ni davom ettirish", practiceTour2: "Amaliyot • 2-tur",
      lessonsPractice: "Darslar • Amaliyot mavjud",
      mathHubSub: "Cambridge AS Mathematics", examPreparation: "Imtihonga tayyorgarlik",
      examPreparationSub: "Paper 1 va Paper 5 uchun tizimli tayyorgarlik.", continueExamPrep: "Tayyorgarlikni davom ettirish",
      p1: "Paper 1", p5: "Paper 5", pure: "Pure Mathematics 1", stats: "Probability & Statistics 1",
      coverage: "Syllabus qamrovi", evidence: "Tasdiq", building: "Shakllanmoqda", starting: "Boshlanish",
      learning: "O‘qish", olympiadSection: "Olimpiada", resources: "Resurslar", more: "Yana",
      olympiadPractice: "Olimpiada amaliyoti", tours: "Turlar", book: "Kitob", recommendations: "Tavsiyalar",
      certificates: "Sertifikatlar", tourArchive: "Turlar arxivi",
      learningSyllabus: "Syllabusni o‘rganish", learningSyllabusSub: "Hozirgi vazifa — takrorlash bosqichidan oldin syllabus qamrovini mustahkamlash.",
      upNext: "Keyingi qadam", chainRule: "Chain Rule amaliyoti", startPractice: "Amaliyotni boshlash",
      next: "Keyingi", reprData: "Representation of Data", quickAccess: "Tezkor kirish",
      syllabusProgress: "Syllabus progressi", corrections: "Tuzatishlar va qayta tekshiruvlar", timedPractice: "Vaqtli amaliyot", papers: "Papers",
      aiExamText: "Differentiation asoslari barqaror, Chain Rule qo‘llashni esa yana mustahkamlash kerak.",
      explainDifferent: "Boshqacha tushuntirish", explainMistake: "Xatomni tushuntirish",
      latestReview: "Oxirgi tekshiruv", reviewed: "Tekshirildi", writtenSolution: "Paper 1 • Chain Rule yozma yechimi",
      tour3: "Matematika • 3-tur", opens24: "24 oktabrda ochiladi", continuePractice: "Amaliyotni davom ettirish",
      notImplemented: "Bu bo‘lim hozirgi vizual integratsiya bosqichiga kirmaydi."
    }
  };

  const ICONS = {
    home: "<path d='M3 10.5 12 3l9 7.5'/><path d='M5 9.5V21h14V9.5'/><path d='M9 21v-7h6v7'/>",
    study: "<path d='m3 6 9-3 9 3-9 3-9-3Z'/><path d='M6 7.5V13c0 2 2.7 4 6 4s6-2 6-4V7.5'/><path d='M21 6v7'/>",
    ratings: "<path d='M4 20V10h4v10'/><path d='M10 20V4h4v16'/><path d='M16 20v-7h4v7'/>",
    profile: "<circle cx='12' cy='8' r='4'/><path d='M4 21c.8-4 3.5-6 8-6s7.2 2 8 6'/>",
    bell: "<path d='M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9'/><path d='M10 21h4'/>",
    back: "<path d='m15 18-6-6 6-6'/>",
    math: "<path d='M5 5h14'/><path d='M5 12h14'/><path d='M8 3v4'/><path d='M16 10v4'/><path d='M13 17h6'/><path d='M5 19h4'/>",
    flask: "<path d='M9 3h6'/><path d='M10 3v6l-5 9a2 2 0 0 0 2 3h10a2 2 0 0 0 2-3l-5-9V3'/><path d='M7 16h10'/>",
    leaf: "<path d='M20 4C11 4 5 9 5 16c0 2 1 4 3 5'/><path d='M5 19c5-8 9-10 15-15'/>",
    code: "<path d='m8 9-4 3 4 3'/><path d='m16 9 4 3-4 3'/><path d='m14 5-4 14'/>",
    chart: "<path d='M4 19h16'/><path d='M6 16V9'/><path d='M12 16V5'/><path d='M18 16v-4'/>",
    book: "<path d='M4 5a3 3 0 0 1 3-2h5v17H7a3 3 0 0 0-3 2V5Z'/><path d='M20 5a3 3 0 0 0-3-2h-5v17h5a3 3 0 0 1 3 2V5Z'/>",
    practice: "<path d='M8 4h8'/><path d='M9 2h6v4H9z'/><path d='M6 4H5a2 2 0 0 0-2 2v15h18V6a2 2 0 0 0-2-2h-1'/><path d='m7 12 2 2 4-4'/><path d='M14 14h3'/>",
    tour: "<path d='M8 4h8v4a4 4 0 0 1-8 0V4Z'/><path d='M8 6H4v2c0 3 2 5 5 5'/><path d='M16 6h4v2c0 3-2 5-5 5'/><path d='M12 12v5'/><path d='M8 21h8'/><path d='M10 17h4v4h-4z'/>",
    chevron: "<path d='m9 18 6-6-6-6'/>",
    sparkle: "<path d='m12 3 1.5 4.5L18 9l-4.5 1.5L12 15l-1.5-4.5L6 9l4.5-1.5L12 3Z'/><path d='m19 15 .8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8L19 15Z'/>",
    mentor: "<circle cx='9' cy='8' r='3'/><path d='M3 20c.6-3.3 2.6-5 6-5 1.3 0 2.4.2 3.3.7'/><path d='m16 14 2 2 4-4'/>",
    clock: "<circle cx='12' cy='12' r='9'/><path d='M12 7v5l3 2'/>",
    list: "<path d='M8 6h12'/><path d='M8 12h12'/><path d='M8 18h12'/><path d='M4 6h.01'/><path d='M4 12h.01'/><path d='M4 18h.01'/>",
    repeat: "<path d='m17 2 4 4-4 4'/><path d='M3 11V9a3 3 0 0 1 3-3h15'/><path d='m7 22-4-4 4-4'/><path d='M21 13v2a3 3 0 0 1-3 3H3'/>",
    timer: "<circle cx='12' cy='13' r='8'/><path d='M12 9v4l3 2'/><path d='M9 2h6'/>",
    file: "<path d='M6 2h8l4 4v16H6z'/><path d='M14 2v5h5'/><path d='M9 13h6'/><path d='M9 17h6'/>",
    certificate: "<circle cx='12' cy='9' r='5'/><path d='m9 14-2 8 5-3 5 3-2-8'/>",
    archive: "<path d='M4 7h16v14H4z'/><path d='M3 3h18v4H3z'/><path d='M9 11h6'/>",
    bulb: "<path d='M9 18h6'/><path d='M10 22h4'/><path d='M8 14c-1.3-1-2-2.7-2-4.5A6 6 0 0 1 18 9.5c0 1.8-.7 3.5-2 4.5-.8.7-1 1.4-1 2H9c0-.6-.2-1.3-1-2Z'/>",
    resources: "<path d='M4 5h16v14H4z'/><path d='M8 9h8'/><path d='M8 13h5'/>",
    calendar: "<path d='M4 5h16v16H4z'/><path d='M8 2v6'/><path d='M16 2v6'/><path d='M4 10h16'/>",
    check: "<path d='m5 12 4 4 10-10'/>",
    edit: "<path d='M4 20h4l11-11-4-4L4 16v4Z'/><path d='m13 7 4 4'/>",
    papers: "<path d='M7 3h7l4 4v14H7z'/><path d='M14 3v5h5'/><path d='M10 13h5'/><path d='M10 17h5'/>",
    syllabus: "<path d='M4 4h16v16H4z'/><path d='M8 8h8'/><path d='M8 12h8'/><path d='M8 16h5'/>",
    warning: "<path d='M12 3 2 21h20L12 3Z'/><path d='M12 9v5'/><path d='M12 18h.01'/>",
    info: "<circle cx='12' cy='12' r='9'/><path d='M12 11v6'/><path d='M12 7h.01'/>",
    notification: "<path d='M5 12h14'/><path d='m13 6 6 6-6 6'/>",
    trophy: "<path d='M8 4h8v4a4 4 0 0 1-8 0V4Z'/><path d='M12 12v5'/><path d='M8 21h8'/>",
    settings: "<circle cx='12' cy='12' r='3'/><path d='M19 13.5v-3l-2-.7-.8-2 1-1.9-2.1-2.1-1.9 1-.2-.1-1.8-.7L10.5 2h-3l-.7 2-2 .8-1.9-1L.8 5.9l1 1.9-.8 2-2 .7v3l2 .7.8 2-1 1.9 2.1 2.1 1.9-1 2 .8.7 2h3l.7-2 2-.8 1.9 1 2.1-2.1-1-1.9.8-2 2-.7Z' transform='translate(2.2 -.1) scale(.82)'/>",
  };

  function icon(name) {
    return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[name] || ICONS.info}</svg>`;
  }

  function t(key) {
    return COPY[state.lang][key] || COPY.en[key] || key;
  }

  function escapeHtml(value) {
    return String(value ?? "").replace(/[&<>"']/g, ch => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"})[ch]);
  }

  function navButton(key, iconName) {
    const active = state.screen === key;
    return `<button class="v3-nav-btn${active ? " is-active" : ""}" type="button" data-nav="${key}">${icon(iconName)}<span>${escapeHtml(t(key))}</span></button>`;
  }

  function bottomNav() {
    return `<nav class="v3-bottom-nav" aria-label="Primary navigation">
      ${navButton("home","home")}
      ${navButton("study","study")}
      ${navButton("ratings","ratings")}
      ${navButton("profile","profile")}
    </nav>`;
  }

  function topBar({ back = null, title = "iClub", subtitle = "", notifications = true } = {}) {
    return `<header class="v3-topbar">
      ${back ? `<button class="v3-topbar__back" type="button" data-back="${back}" aria-label="Back">${icon("back")}</button>` : `<div class="v3-topbar__brand"><img class="v3-topbar__logo" src="logo.png" alt="iClub"><div><div class="v3-topbar__title">${escapeHtml(title)}</div>${subtitle ? `<div class="v3-topbar__subtitle">${escapeHtml(subtitle)}</div>` : ""}</div></div>`}
      ${back ? `<div><div class="v3-topbar__title">${escapeHtml(title)}</div>${subtitle ? `<div class="v3-topbar__subtitle">${escapeHtml(subtitle)}</div>` : ""}</div>` : `<div></div>`}
      ${notifications ? `<button class="v3-icon-btn" type="button" aria-label="Notifications">${icon("bell")}</button>` : `<div class="v3-topbar__spacer"></div>`}
    </header>`;
  }

  function serviceBlock(kind, context) {
    if (kind === "ai") {
      const text = context === "exam" ? t("aiExamText") : t("aiHomeText");
      return `<div class="v3-service"><div class="v3-service__head">${icon("sparkle")}<span>${escapeHtml(t("aiAssist"))}</span></div><div class="v3-service__title">${escapeHtml(t("whyNext"))}</div><div class="v3-service__text">${escapeHtml(text)}</div>${context === "exam" ? `<div class="v3-inline"><button class="v3-text-btn" type="button">${escapeHtml(t("explainDifferent"))}</button><button class="v3-text-btn" type="button">${escapeHtml(t("explainMistake"))}</button></div>` : ""}</div>`;
    }
    if (kind === "mentor") {
      if (context === "exam") {
        return `<div class="v3-service v3-service--mentor"><div class="v3-service__head">${icon("mentor")}<span>${escapeHtml(t("mentorCare"))}</span></div><div class="v3-service__text">${escapeHtml(t("nextReview"))}</div><div class="v3-divider"></div><div class="v3-service__title">${escapeHtml(t("latestReview"))}</div><div class="v3-service__text"><strong>${escapeHtml(t("writtenSolution"))}</strong> · ${escapeHtml(t("reviewed"))}<br>${escapeHtml(t("mentorHomeText"))}</div><button class="v3-text-btn" type="button">${escapeHtml(t("viewFeedback"))}</button></div>`;
      }
      return `<div class="v3-service v3-service--mentor"><div class="v3-service__head">${icon("mentor")}<span>${escapeHtml(t("mentorCare"))}</span></div><div class="v3-service__title">${escapeHtml(t("mentorHomeTitle"))}</div><div class="v3-service__text">${escapeHtml(t("mentorHomeText"))}<br>${escapeHtml(t("nextReview"))}</div><button class="v3-text-btn" type="button">${escapeHtml(t("viewFeedback"))}</button></div>`;
    }
    return "";
  }

  function homeView() {
    return `<div class="v3-shell">
      ${topBar()}
      <main class="v3-main">
        <div class="v3-page-head"><div class="v3-greeting">${escapeHtml(t("greeting"))}</div><h1 class="v3-page-title">${escapeHtml(t("today"))}</h1></div>

        <section class="v3-action-card">
          <div class="v3-card-head"><div><div class="v3-kicker">${escapeHtml(t("math"))}</div><div class="v3-card-title">${escapeHtml(t("paper1Functions"))}</div></div><span class="v3-pill v3-pill--amber">${escapeHtml(t("retest"))}</span></div>
          <div class="v3-task-row"><div class="v3-task-icon">${icon("repeat")}</div><div class="v3-task-copy"><div class="v3-task-title">${escapeHtml(t("retest"))}</div><div class="v3-task-meta">${escapeHtml(t("minutes15"))}</div></div></div>
          ${state.mode === "ai" ? serviceBlock("ai","home") : ""}
          <button class="v3-btn v3-btn--primary v3-btn--full" type="button" data-screen="exam">${escapeHtml(t("continue"))}</button>
        </section>

        <section class="v3-section">
          <div class="v3-section-head"><div class="v3-section-title">${escapeHtml(t("weekly"))}</div></div>
          <div class="v3-card"><div class="v3-progress-row"><span>${escapeHtml(t("planned"))}</span><strong>4 / 6</strong></div><div class="v3-progress"><span style="width:66.67%"></span></div></div>
          ${state.mode === "mentor" ? serviceBlock("mentor","home") : ""}
        </section>

        <section class="v3-section">
          <div class="v3-section-head"><div class="v3-section-title">${escapeHtml(t("upcoming"))}</div></div>
          <div class="v3-list"><button class="v3-list-row" type="button" data-screen="exam"><span class="v3-list-row__icon">${icon("calendar")}</span><span class="v3-list-row__copy"><span class="v3-list-row__title">${escapeHtml(t("examCheckpoint"))}</span><span class="v3-list-row__meta">24 Oct</span></span><span class="v3-list-row__right">${icon("chevron")}</span></button></div>
        </section>

        <section class="v3-section">
          <div class="v3-section-head"><div class="v3-section-title">${escapeHtml(t("continueLearning"))}</div></div>
          <div class="v3-list">
            <button class="v3-list-row" type="button"><span class="v3-list-row__icon">${icon("flask")}</span><span class="v3-list-row__copy"><span class="v3-list-row__title">${escapeHtml(t("chemistry"))}</span><span class="v3-list-row__meta">${escapeHtml(t("practice"))}</span></span><span class="v3-list-row__right">${icon("chevron")}</span></button>
            <button class="v3-list-row" type="button"><span class="v3-list-row__icon">${icon("leaf")}</span><span class="v3-list-row__copy"><span class="v3-list-row__title">${escapeHtml(t("biology"))}</span><span class="v3-list-row__meta">${escapeHtml(t("lessons"))}</span></span><span class="v3-list-row__right">${icon("chevron")}</span></button>
          </div>
        </section>
      </main>
      ${bottomNav()}
    </div>`;
  }

  const SUBJECTS = [
    {key:"math",badge:"examPrep",title:"math",meta:"cambridgeP1P5",next:"nextP5",icon:"math",action:"continue",screen:"math-hub"},
    {key:"biology",badge:"olympiad",title:"biology",meta:"practiceTour2",next:null,icon:"leaf",action:"continue"},
    {key:"chemistry",badge:"course",title:"chemistry",meta:"lessonsPractice",next:null,icon:"flask",action:"open"},
    {key:"informatics",badge:"course",title:"informatics",meta:"lessonsPractice",next:null,icon:"code",action:"open"},
    {key:"economics",badge:"course",title:"economics",meta:"lessonsPractice",next:null,icon:"chart",action:"open"}
  ];

  function subjectCard(s) {
    return `<article class="v3-subject-card"><div class="v3-subject-card__icon">${icon(s.icon)}</div><div class="v3-subject-card__copy"><div class="v3-subject-card__badge">${escapeHtml(t(s.badge))}</div><div class="v3-subject-card__title">${escapeHtml(t(s.title))}</div><div class="v3-subject-card__meta">${escapeHtml(t(s.meta))}${s.next ? ` · ${escapeHtml(t(s.next))}` : ""}</div></div><button class="v3-text-btn" type="button"${s.screen ? ` data-screen="${s.screen}"` : ""}>${escapeHtml(t(s.action))} →</button></article>`;
  }

  function studyView() {
    return `<div class="v3-shell">${topBar()}<main class="v3-main"><div class="v3-page-head"><h1 class="v3-page-title">${escapeHtml(t("studyTitle"))}</h1></div><div class="v3-tabs"><button class="v3-tab is-active" type="button">${escapeHtml(t("mine"))}</button><button class="v3-tab" type="button">${escapeHtml(t("all"))}</button></div><div class="v3-subject-list">${SUBJECTS.map(subjectCard).join("")}</div></main>${bottomNav()}</div>`;
  }

  function listRow(iconName, title, meta = "", screen = null) {
    return `<button class="v3-list-row" type="button"${screen ? ` data-screen="${screen}"` : ""}><span class="v3-list-row__icon">${icon(iconName)}</span><span class="v3-list-row__copy"><span class="v3-list-row__title">${escapeHtml(title)}</span>${meta ? `<span class="v3-list-row__meta">${escapeHtml(meta)}</span>` : ""}</span><span class="v3-list-row__right">${icon("chevron")}</span></button>`;
  }

  function paperCard(component, title, coverage, evidence, next) {
    return `<article class="v3-paper-card"><div class="v3-paper-card__top"><div><div class="v3-paper-label">${escapeHtml(component)}</div><div class="v3-paper-title">${escapeHtml(title)}</div></div><span class="v3-pill v3-pill--blue">${escapeHtml(evidence)}</span></div><div class="v3-space"></div><div class="v3-progress-row"><span>${escapeHtml(t("coverage"))}</span><strong>${coverage}%</strong></div><div class="v3-progress"><span style="width:${coverage}%"></span></div><div class="v3-paper-next"><span>${escapeHtml(t("next"))}: </span><strong>${escapeHtml(next)}</strong></div></article>`;
  }

  function mathHubView() {
    return `<div class="v3-shell">${topBar({back:"study",title:t("math"),subtitle:t("mathHubSub")})}<main class="v3-main"><div class="v3-page-head"><h1 class="v3-page-title">${escapeHtml(t("math"))}</h1><div class="v3-page-subtitle">${escapeHtml(t("mathHubSub"))}</div></div><section class="v3-action-card"><div class="v3-kicker">${escapeHtml(t("examPreparation"))}</div><div class="v3-card-title">${escapeHtml(t("examPreparation"))}</div><div class="v3-card-subtitle">${escapeHtml(t("examPreparationSub"))}</div><div class="v3-space"></div><div class="v3-paper-grid">${paperCard(t("p1"),t("pure"),65,t("building"),t("chainRule"))}${paperCard(t("p5"),t("stats"),15,t("starting"),t("reprData"))}</div><button class="v3-btn v3-btn--primary v3-btn--full" type="button" data-screen="exam">${escapeHtml(t("continueExamPrep"))}</button></section><section class="v3-section"><div class="v3-section-head"><div class="v3-section-title">${escapeHtml(t("learning"))}</div></div><div class="v3-list">${listRow("book",t("lessons"))}${listRow("practice",t("practice"))}</div></section><section class="v3-section"><div class="v3-section-head"><div class="v3-section-title">${escapeHtml(t("olympiadSection"))}</div></div><div class="v3-list">${listRow("practice",t("olympiadPractice"))}${listRow("tour",t("tours"))}</div></section><section class="v3-section"><div class="v3-section-head"><div class="v3-section-title">${escapeHtml(t("resources"))}</div></div><div class="v3-list">${listRow("book",t("book"))}${listRow("resources",t("resources"))}</div></section><section class="v3-section"><div class="v3-section-head"><div class="v3-section-title">${escapeHtml(t("more"))}</div></div><div class="v3-list">${listRow("bulb",t("recommendations"))}${listRow("certificate",t("certificates"))}${listRow("archive",t("tourArchive"))}</div></section></main>${bottomNav()}</div>`;
  }

  function examView() {
    return `<div class="v3-shell">${topBar({back:"math-hub",title:t("math"),subtitle:t("mathHubSub")})}<main class="v3-main"><div class="v3-page-head"><div class="v3-kicker">${escapeHtml(t("examPreparation"))}</div><h1 class="v3-page-title">${escapeHtml(t("learningSyllabus"))}</h1><div class="v3-page-subtitle">${escapeHtml(t("learningSyllabusSub"))}</div></div><section class="v3-action-card"><div class="v3-section-head"><div class="v3-section-title">${escapeHtml(t("upNext"))}</div><span class="v3-pill v3-pill--blue">${escapeHtml(t("p1"))}</span></div><div class="v3-task-row"><div class="v3-task-icon">${icon("practice")}</div><div class="v3-task-copy"><div class="v3-task-title">${escapeHtml(t("chainRule"))}</div><div class="v3-task-meta">${escapeHtml(t("minutes20"))}</div></div></div>${state.mode === "ai" ? serviceBlock("ai","exam") : ""}<button class="v3-btn v3-btn--primary v3-btn--full" type="button">${escapeHtml(t("startPractice"))}</button></section>${state.mode === "mentor" ? serviceBlock("mentor","exam") : ""}<section class="v3-section"><div class="v3-paper-grid">${paperCard(t("p1"),t("pure"),65,t("building"),t("chainRule"))}${paperCard(t("p5"),t("stats"),15,t("starting"),t("reprData"))}</div></section><section class="v3-section"><div class="v3-section-head"><div class="v3-section-title">${escapeHtml(t("quickAccess"))}</div></div><div class="v3-list">${listRow("syllabus",t("syllabusProgress"))}${listRow("repeat",t("corrections"))}${listRow("timer",t("timedPractice"))}${listRow("papers",t("papers"))}</div></section></main>${bottomNav()}</div>`;
  }

  function placeholderView(screen) {
    return `<div class="v3-shell">${topBar()}<main class="v3-main"><div class="v3-page-head"><h1 class="v3-page-title">${escapeHtml(t(screen))}</h1><div class="v3-page-subtitle">${escapeHtml(t("notImplemented"))}</div></div><div class="v3-card v3-empty">${escapeHtml(t("notImplemented"))}</div></main>${bottomNav()}</div>`;
  }

  function render() {
    if (state.screen === "home") root.innerHTML = homeView();
    else if (state.screen === "study") root.innerHTML = studyView();
    else if (state.screen === "math-hub") root.innerHTML = mathHubView();
    else if (state.screen === "exam") root.innerHTML = examView();
    else root.innerHTML = placeholderView(state.screen);

    root.querySelectorAll("[data-nav]").forEach(btn => btn.addEventListener("click", () => {
      state.screen = btn.dataset.nav;
      render();
      window.scrollTo({top:0,behavior:"instant"});
    }));
    root.querySelectorAll("[data-screen]").forEach(btn => btn.addEventListener("click", () => {
      state.screen = btn.dataset.screen;
      render();
      window.scrollTo({top:0,behavior:"instant"});
    }));
    root.querySelectorAll("[data-back]").forEach(btn => btn.addEventListener("click", () => {
      state.screen = btn.dataset.back;
      render();
      window.scrollTo({top:0,behavior:"instant"});
    }));
  }

  function runSelfTests() {
    const errors = [];
    const invariant = (ok, message) => { if (!ok) errors.push(message); };
    invariant(SUBJECTS.map(x => x.key).join(",") === "math,biology,chemistry,informatics,economics", "Only real main-subject preview set may be shown");
    invariant(["core","ai","mentor"].includes(state.mode), "Service mode must be isolated");
    invariant(!document.documentElement.innerHTML.includes("correct_answer"), "Preview must not contain answer-key field names");
    invariant(!document.documentElement.innerHTML.includes("supabase"), "UI v3 preview must not connect to Supabase");
    invariant(COPY.en.p1 !== COPY.en.p5, "P1/P5 labels must remain separate");
    if (errors.length) {
      console.error("UI v3 self-tests failed", errors);
      return false;
    }
    console.info("UI v3 self-tests passed", {subjects:5, serviceModes:3, p1p5Separate:true, supabase:false});
    return true;
  }

  modeSelect.addEventListener("change", () => {
    state.mode = modeSelect.value;
    render();
  });
  langSelect.addEventListener("change", () => {
    state.lang = langSelect.value;
    render();
  });

  runSelfTests();
  render();
})();
