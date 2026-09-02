(() => {
  "use strict";

  const root = document.getElementById("v3-app");
  const modeSelect = document.getElementById("v3-mode-select");
  const langSelect = document.getElementById("v3-lang-select");

  const state = {
    screen: "home",
    mode: "core",
    lang: "en",
    entryOrigin: null
  };

  const ROUTE_GROUP = {
    home: "home",
    study: "study",
    "math-hub": "study",
    resources: "study",
    tours: "study",
    ratings: "ratings",
    profile: "profile",
    achievements: "profile",
    saved: "profile",
    settings: "profile",
    support: "profile",
    information: "profile"
  };

  const copy = {
    en: {
      home:"Home",study:"Study",ratings:"Ratings",profile:"Profile",today:"Today",continue:"Continue",open:"Open",back:"Back",
      greeting:"Let’s continue",weekly:"This week",planned:"4 of 6 planned actions completed",upcoming:"Upcoming",continueLearning:"Continue learning",
      mathematics:"Mathematics",chemistry:"Chemistry",biology:"Biology",informatics:"Informatics",economics:"Economics",practice:"Practice",lessons:"Lessons",
      delayedRetest:"Delayed retest",paper1Functions:"Paper 1 • Functions",minutes15:"15 min",examCheckpoint:"Exam Prep checkpoint",aiAssist:"AI Assist",whyNext:"Why this is next",
      aiWhy:"Your earlier Functions evidence is stable, but this delayed retest is needed to confirm that the skill still holds after time.",mentorCare:"Mentor Care",
      mentorReviewed:"Your Paper 1 written solution was reviewed.",mentorText:"Show the substitution step more clearly before simplifying.",nextReview:"Next review: Thursday",
      viewFeedback:"View feedback",studyTitle:"Study",mine:"Mine",all:"All",examPrep:"EXAM PREP",competition:"COMPETITION",course:"COURSE",
      cambridge:"Cambridge AS Mathematics",p1p5:"P1 + P5",nextP5:"Next: continue P5",practiceTour2:"Practice • Tour 2 preparation",learningAvailable:"Lessons • Practice available",
      examPreparation:"Exam preparation",examPreparationSub:"Structured preparation for Paper 1 and Paper 5.",continueExamPrep:"Continue exam preparation",
      p1:"Paper 1",p5:"Paper 5",pure:"Pure Mathematics 1",stats:"Probability & Statistics 1",coverage:"Syllabus coverage",evidence:"Evidence",building:"Building",starting:"Starting",
      learning:"Learning",materials:"Materials",resources:"Resources",tours:"Tours",current:"Current",results:"Results",archive:"Archive",noTour:"No active Tour right now.",
      resourcesSub:"Coursebook and approved study materials.",book:"Coursebook",approvedMaterials:"Approved materials",externalResources:"External resources",
      ratingTitle:"Rating",district:"District",region:"Region",republic:"Republic",subject:"Subject",tour:"Tour",yourPosition:"Your position",leaderboard:"Leaderboard",
      profileTitle:"Profile",myStudy:"My study",achievements:"Achievements",services:"Services",saved:"Saved",settings:"Settings",support:"Support",information:"Information",
      certificates:"Certificates",recommendations:"Recommendations",news:"News",community:"Community",about:"About",notAvailable:"Not available in this preview",
      core:"Core",ai:"AI Assist",mentor:"Mentor Care",studyMath:"Cambridge AS Mathematics",studyBio:"Practice • Tour 2",studyCourse:"Lessons • Practice",
      openExamPrep:"Open Exam Prep",activeTour:"Tour 3",opens:"Opens 24 Oct",tourResult:"Tour 2 • 17/20",archiveItem:"Tour 1 • self-check available",
      notifications:"Notifications"
    },
    ru: {
      home:"Главная",study:"Учёба",ratings:"Рейтинг",profile:"Профиль",today:"Сегодня",continue:"Продолжить",open:"Открыть",back:"Назад",
      greeting:"Продолжим",weekly:"На этой неделе",planned:"Выполнено 4 из 6 запланированных действий",upcoming:"Скоро",continueLearning:"Продолжить обучение",
      mathematics:"Математика",chemistry:"Химия",biology:"Биология",informatics:"Информатика",economics:"Экономика",practice:"Практика",lessons:"Уроки",
      delayedRetest:"Повторная проверка",paper1Functions:"Paper 1 • Functions",minutes15:"15 мин",examCheckpoint:"Контрольная точка Exam Prep",aiAssist:"AI Assist",whyNext:"Почему это следующий шаг",
      aiWhy:"Предыдущие результаты по Functions стабильны, но повторная проверка нужна, чтобы подтвердить сохранение навыка спустя время.",mentorCare:"Mentor Care",
      mentorReviewed:"Наставник проверил письменное решение по Paper 1.",mentorText:"Показывайте шаг подстановки яснее перед упрощением.",nextReview:"Следующая проверка: четверг",
      viewFeedback:"Посмотреть комментарий",studyTitle:"Учёба",mine:"Мои",all:"Все",examPrep:"EXAM PREP",competition:"СОРЕВНОВАНИЕ",course:"КУРС",
      cambridge:"Cambridge AS Mathematics",p1p5:"P1 + P5",nextP5:"Далее: продолжить P5",practiceTour2:"Практика • подготовка к Туру 2",learningAvailable:"Уроки • Практика доступна",
      examPreparation:"Подготовка к экзамену",examPreparationSub:"Структурированная подготовка к Paper 1 и Paper 5.",continueExamPrep:"Продолжить подготовку",
      p1:"Paper 1",p5:"Paper 5",pure:"Pure Mathematics 1",stats:"Probability & Statistics 1",coverage:"Покрытие syllabus",evidence:"Подтверждение",building:"Формируется",starting:"Начало",
      learning:"Обучение",materials:"Материалы",resources:"Ресурсы",tours:"Туры",current:"Текущий",results:"Результаты",archive:"Архив",noTour:"Сейчас активного Тура нет.",
      resourcesSub:"Книга курса и утверждённые учебные материалы.",book:"Книга курса",approvedMaterials:"Учебные материалы",externalResources:"Внешние ресурсы",
      ratingTitle:"Рейтинг",district:"Район",region:"Регион",republic:"Республика",subject:"Предмет",tour:"Тур",yourPosition:"Ваша позиция",leaderboard:"Участники",
      profileTitle:"Профиль",myStudy:"Моя учёба",achievements:"Достижения",services:"Сервисы",saved:"Сохранённое",settings:"Настройки",support:"Поддержка",information:"Информация",
      certificates:"Сертификаты",recommendations:"Рекомендации",news:"Новости",community:"Сообщество",about:"О проекте",notAvailable:"Недоступно в этом preview",
      core:"Core",ai:"AI Assist",mentor:"Mentor Care",studyMath:"Cambridge AS Mathematics",studyBio:"Практика • Тур 2",studyCourse:"Уроки • Практика",
      openExamPrep:"Открыть Exam Prep",activeTour:"Тур 3",opens:"Откроется 24 окт",tourResult:"Тур 2 • 17/20",archiveItem:"Тур 1 • доступна самопроверка",
      notifications:"Уведомления"
    },
    uz: {
      home:"Bosh sahifa",study:"O‘qish",ratings:"Reyting",profile:"Profil",today:"Bugun",continue:"Davom etish",open:"Ochish",back:"Orqaga",
      greeting:"Davom etamiz",weekly:"Bu hafta",planned:"Rejalashtirilgan 6 harakatdan 4 tasi bajarildi",upcoming:"Yaqinda",continueLearning:"O‘qishni davom ettirish",
      mathematics:"Matematika",chemistry:"Kimyo",biology:"Biologiya",informatics:"Informatika",economics:"Iqtisodiyot",practice:"Amaliyot",lessons:"Darslar",
      delayedRetest:"Qayta tekshiruv",paper1Functions:"Paper 1 • Functions",minutes15:"15 daq",examCheckpoint:"Exam Prep nazorat nuqtasi",aiAssist:"AI Assist",whyNext:"Nega bu keyingi qadam",
      aiWhy:"Functions bo‘yicha oldingi natijalar barqaror, lekin ko‘nikma vaqt o‘tib ham saqlanganini tasdiqlash uchun qayta tekshiruv kerak.",mentorCare:"Mentor Care",
      mentorReviewed:"Paper 1 yozma yechimingiz mentor tomonidan tekshirildi.",mentorText:"Soddalashtirishdan oldin o‘rniga qo‘yish qadamini aniqroq ko‘rsating.",nextReview:"Keyingi tekshiruv: payshanba",
      viewFeedback:"Izohni ko‘rish",studyTitle:"O‘qish",mine:"Mening",all:"Barchasi",examPrep:"EXAM PREP",competition:"MUSOBAQA",course:"KURS",
      cambridge:"Cambridge AS Mathematics",p1p5:"P1 + P5",nextP5:"Keyingi: P5 ni davom ettirish",practiceTour2:"Amaliyot • 2-turga tayyorgarlik",learningAvailable:"Darslar • Amaliyot mavjud",
      examPreparation:"Imtihonga tayyorgarlik",examPreparationSub:"Paper 1 va Paper 5 uchun tizimli tayyorgarlik.",continueExamPrep:"Tayyorgarlikni davom ettirish",
      p1:"Paper 1",p5:"Paper 5",pure:"Pure Mathematics 1",stats:"Probability & Statistics 1",coverage:"Syllabus qamrovi",evidence:"Tasdiq",building:"Shakllanmoqda",starting:"Boshlanish",
      learning:"O‘qish",materials:"Materiallar",resources:"Resurslar",tours:"Turlar",current:"Joriy",results:"Natijalar",archive:"Arxiv",noTour:"Hozir faol Tur yo‘q.",
      resourcesSub:"Kurs kitobi va tasdiqlangan o‘quv materiallari.",book:"Kurs kitobi",approvedMaterials:"O‘quv materiallari",externalResources:"Tashqi resurslar",
      ratingTitle:"Reyting",district:"Tuman",region:"Viloyat",republic:"Respublika",subject:"Fan",tour:"Tur",yourPosition:"Sizning o‘rningiz",leaderboard:"Ishtirokchilar",
      profileTitle:"Profil",myStudy:"Mening o‘qishim",achievements:"Yutuqlar",services:"Xizmatlar",saved:"Saqlangan",settings:"Sozlamalar",support:"Yordam",information:"Ma’lumot",
      certificates:"Sertifikatlar",recommendations:"Tavsiyalar",news:"Yangiliklar",community:"Hamjamiyat",about:"Loyiha haqida",notAvailable:"Bu previewda mavjud emas",
      core:"Core",ai:"AI Assist",mentor:"Mentor Care",studyMath:"Cambridge AS Mathematics",studyBio:"Amaliyot • 2-tur",studyCourse:"Darslar • Amaliyot",
      openExamPrep:"Exam Prep ni ochish",activeTour:"3-tur",opens:"24 oktabrda ochiladi",tourResult:"2-tur • 17/20",archiveItem:"1-tur • o‘zini tekshirish mavjud",
      notifications:"Bildirishnomalar"
    }
  };

  const icons = {
    home:"⌂",study:"▦",ratings:"▤",profile:"◯",bell:"○",back:"‹",math:"∑",book:"□",practice:"✓",tour:"◇",resources:"▱",chevron:"›",repeat:"↻",calendar:"□",mentor:"◇",sparkle:"✦",certificate:"◇",settings:"⚙",info:"i"
  };

  const t = key => (copy[state.lang] && copy[state.lang][key]) || copy.en[key] || key;
  const esc = value => String(value ?? "").replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
  const icon = name => `<span aria-hidden="true">${icons[name] || "•"}</span>`;
  const routeGroup = screen => ROUTE_GROUP[screen] || "study";

  function go(screen) {
    state.screen = screen;
    render();
    window.scrollTo({top:0, behavior:"instant"});
  }

  function navButton(key, iconName) {
    const active = routeGroup(state.screen) === key;
    return `<button class="v3-nav-btn${active ? " is-active" : ""}" type="button" data-nav="${key}">${icon(iconName)}<span>${esc(t(key))}</span></button>`;
  }

  function bottomNav() {
    return `<nav class="v3-bottom-nav" aria-label="Primary navigation">${navButton("home","home")}${navButton("study","study")}${navButton("ratings","ratings")}${navButton("profile","profile")}</nav>`;
  }

  function topBar({back=null,title="iClub",subtitle="",notifications=true}={}) {
    return `<header class="v3-topbar">${back ? `<button class="v3-topbar__back" data-back="${back}" aria-label="${esc(t("back"))}">${icon("back")}</button><div><div class="v3-topbar__title">${esc(title)}</div>${subtitle?`<div class="v3-topbar__subtitle">${esc(subtitle)}</div>`:""}</div>` : `<div class="v3-topbar__brand"><img class="v3-topbar__logo" src="logo.png" alt="iClub"><div class="v3-topbar__title">iClub</div></div>`}<div class="v3-topbar__spacer"></div>${notifications?`<button class="v3-icon-btn" aria-label="${esc(t("notifications"))}">${icon("bell")}</button>`:""}</header>`;
  }

  function listRow(iconName,title,meta="",screen=null) {
    return `<button class="v3-list-row" type="button"${screen?` data-screen="${screen}"`:""}><span class="v3-list-row__icon">${icon(iconName)}</span><span class="v3-list-row__copy"><span class="v3-list-row__title">${esc(title)}</span>${meta?`<span class="v3-list-row__meta">${esc(meta)}</span>`:""}</span><span class="v3-list-row__right">${icon("chevron")}</span></button>`;
  }

  function serviceBlock() {
    if (state.mode === "ai") return `<div class="v3-service"><div class="v3-service__head">${icon("sparkle")}<span>${esc(t("aiAssist"))}</span></div><div class="v3-service__title">${esc(t("whyNext"))}</div><div class="v3-service__text">${esc(t("aiWhy"))}</div></div>`;
    if (state.mode === "mentor") return `<div class="v3-service v3-service--mentor"><div class="v3-service__head">${icon("mentor")}<span>${esc(t("mentorCare"))}</span></div><div class="v3-service__title">${esc(t("mentorReviewed"))}</div><div class="v3-service__text">${esc(t("mentorText"))}<br>${esc(t("nextReview"))}</div><button class="v3-text-btn">${esc(t("viewFeedback"))}</button></div>`;
    return "";
  }

  function homeView() {
    return `<div class="v3-shell">${topBar()}<main class="v3-main"><div class="v3-page-head"><div class="v3-greeting">${esc(t("greeting"))}</div><h1 class="v3-page-title">${esc(t("today"))}</h1></div><section class="v3-action-card"><div class="v3-card-head"><div><div class="v3-kicker">${esc(t("mathematics"))}</div><div class="v3-card-title">${esc(t("paper1Functions"))}</div></div><span class="v3-pill v3-pill--amber">${esc(t("delayedRetest"))}</span></div><div class="v3-task-row"><div class="v3-task-icon">${icon("repeat")}</div><div class="v3-task-copy"><div class="v3-task-title">${esc(t("delayedRetest"))}</div><div class="v3-task-meta">${esc(t("minutes15"))}</div></div></div>${state.mode!=="core"?serviceBlock():""}<button class="v3-btn v3-btn--primary v3-btn--full" data-screen="math-hub">${esc(t("continue"))}</button></section><section class="v3-section"><div class="v3-section-title">${esc(t("weekly"))}</div><div class="v3-card"><div class="v3-progress-row"><span>${esc(t("planned"))}</span><strong>4 / 6</strong></div><div class="v3-progress"><span style="width:66.67%"></span></div></div></section><section class="v3-section"><div class="v3-section-title">${esc(t("upcoming"))}</div><div class="v3-list">${listRow("calendar",t("examCheckpoint"),"24 Oct","math-hub")}</div></section><section class="v3-section"><div class="v3-section-title">${esc(t("continueLearning"))}</div><div class="v3-list">${listRow("practice",t("chemistry"),t("practice"))}${listRow("book",t("biology"),t("lessons"))}</div></section></main>${bottomNav()}</div>`;
  }

  const SUBJECTS = [
    ["examPrep","mathematics","studyMath","nextP5","math-hub"],
    ["competition","biology","studyBio","",null],
    ["course","chemistry","studyCourse","",null],
    ["course","informatics","studyCourse","",null],
    ["course","economics","studyCourse","",null]
  ];

  function studyView() {
    const rows = SUBJECTS.map(([badge,title,meta,next,screen]) => `<article class="v3-subject-card"><div class="v3-subject-card__icon">${icon(title==="mathematics"?"math":"book")}</div><div class="v3-subject-card__copy"><div class="v3-subject-card__badge">${esc(t(badge))}</div><div class="v3-subject-card__title">${esc(t(title))}</div><div class="v3-subject-card__meta">${esc(t(meta))}${next?` · ${esc(t(next))}`:""}</div></div><button class="v3-text-btn"${screen?` data-screen="${screen}"`:""}>${esc(t(screen?"continue":"open"))} →</button></article>`).join("");
    return `<div class="v3-shell">${topBar()}<main class="v3-main"><div class="v3-page-head"><h1 class="v3-page-title">${esc(t("studyTitle"))}</h1></div><div class="v3-tabs"><button class="v3-tab is-active">${esc(t("mine"))}</button><button class="v3-tab">${esc(t("all"))}</button></div><div class="v3-subject-list">${rows}</div></main>${bottomNav()}</div>`;
  }

  function paperCard(component,title,pct,evidence) {
    return `<article class="v3-paper-card"><div class="v3-paper-card__top"><div><div class="v3-paper-label">${esc(component)}</div><div class="v3-paper-title">${esc(title)}</div></div><span class="v3-pill v3-pill--blue">${esc(evidence)}</span></div><div class="v3-progress-row"><span>${esc(t("coverage"))}</span><strong>${pct}%</strong></div><div class="v3-progress"><span style="width:${pct}%"></span></div></article>`;
  }

  function mathHubView() {
    return `<div class="v3-shell">${topBar({back:"study",title:t("mathematics"),subtitle:t("cambridge")})}<main class="v3-main"><section class="v3-action-card"><div class="v3-kicker">${esc(t("examPrep"))}</div><div class="v3-card-title">${esc(t("examPreparation"))}</div><div class="v3-card-subtitle">${esc(t("examPreparationSub"))}</div><div class="v3-space"></div><div class="v3-paper-grid">${paperCard(t("p1"),t("pure"),65,t("building"))}${paperCard(t("p5"),t("stats"),15,t("starting"))}</div><a class="v3-btn v3-btn--primary v3-btn--full" href="ui-v3-exam-prep.html" style="text-decoration:none;text-align:center">${esc(t("continueExamPrep"))}</a></section><section class="v3-section"><div class="v3-section-title">${esc(t("learning"))}</div><div class="v3-list">${listRow("book",t("lessons"))}${listRow("practice",t("practice"))}</div></section><section class="v3-section"><div class="v3-section-title">${esc(t("competition"))}</div><div class="v3-list">${listRow("tour",t("tours"),"","tours")}</div></section><section class="v3-section"><div class="v3-section-title">${esc(t("materials"))}</div><div class="v3-list">${listRow("resources",t("resources"),"","resources")}</div></section></main>${bottomNav()}</div>`;
  }

  function toursView() {
    return `<div class="v3-shell">${topBar({back:"math-hub",title:t("tours"),subtitle:t("mathematics")})}<main class="v3-main"><div class="v3-tabs"><button class="v3-tab is-active">${esc(t("current"))}</button><button class="v3-tab">${esc(t("results"))}</button><button class="v3-tab">${esc(t("archive"))}</button></div><div class="v3-list">${listRow("tour",t("activeTour"),t("opens"))}${listRow("practice",t("tourResult"),t("results"))}${listRow("book",t("archiveItem"),t("archive"))}</div></main>${bottomNav()}</div>`;
  }

  function resourcesView() {
    return `<div class="v3-shell">${topBar({back:"math-hub",title:t("resources"),subtitle:t("mathematics")})}<main class="v3-main"><div class="v3-page-head"><h1 class="v3-page-title">${esc(t("resources"))}</h1><div class="v3-page-subtitle">${esc(t("resourcesSub"))}</div></div><div class="v3-list">${listRow("book",t("book"),"Complete Pure Mathematics 1")}${listRow("resources",t("approvedMaterials"))}${listRow("resources",t("externalResources"))}</div></main>${bottomNav()}</div>`;
  }

  function ratingsView() {
    return `<div class="v3-shell">${topBar()}<main class="v3-main"><div class="v3-page-head"><h1 class="v3-page-title">${esc(t("ratingTitle"))}</h1></div><div class="v3-tabs"><button class="v3-tab is-active">${esc(t("district"))}</button><button class="v3-tab">${esc(t("region"))}</button><button class="v3-tab">${esc(t("republic"))}</button></div><div class="v3-card"><div class="v3-section-title">${esc(t("yourPosition"))}</div><div class="v3-card-title" style="margin-top:8px">#12 · 17 / 20</div></div><section class="v3-section"><div class="v3-section-title">${esc(t("leaderboard"))}</div><div class="v3-list">${listRow("tour","#1 · Student A","19 / 20")}${listRow("tour","#2 · Student B","18 / 20")}${listRow("tour","#3 · Student C","18 / 20")}</div></section></main>${bottomNav()}</div>`;
  }

  function profileView() {
    return `<div class="v3-shell">${topBar()}<main class="v3-main"><div class="v3-page-head"><h1 class="v3-page-title">${esc(t("profileTitle"))}</h1><div class="v3-page-subtitle">Student · Grade 11 · Uzbekistan</div></div><section class="v3-section"><div class="v3-section-title">${esc(t("myStudy"))}</div><div class="v3-list">${listRow("math",t("mathematics"),t("cambridge"),"math-hub")}${listRow("book",t("chemistry"),t("studyCourse"))}</div></section><section class="v3-section"><div class="v3-section-title">${esc(t("achievements"))}</div><div class="v3-list">${listRow("certificate",t("certificates"),"3", "achievements")}</div></section><section class="v3-section"><div class="v3-section-title">${esc(t("services"))}</div><div class="v3-list">${state.mode!=="core"?listRow(state.mode==="ai"?"sparkle":"mentor",t(state.mode),state.mode==="ai"?"Active":"Assigned"):listRow("info",t("core"),"Active")}</div></section><section class="v3-section"><div class="v3-list">${listRow("book",t("recommendations"),"","saved")}${listRow("settings",t("settings"),"","settings")}${listRow("info",t("support"),"","support")}${listRow("info",t("information"),"","information")}</div></section></main>${bottomNav()}</div>`;
  }

  function simpleProfileSubscreen(title, rows=[]) {
    return `<div class="v3-shell">${topBar({back:"profile",title,notifications:false})}<main class="v3-main"><div class="v3-list">${rows.join("") || `<div class="v3-card v3-empty">${esc(t("notAvailable"))}</div>`}</div></main>${bottomNav()}</div>`;
  }

  function render() {
    const screens = {
      home:homeView,
      study:studyView,
      "math-hub":mathHubView,
      tours:toursView,
      resources:resourcesView,
      ratings:ratingsView,
      profile:profileView,
      achievements:()=>simpleProfileSubscreen(t("achievements"),[listRow("certificate",t("certificates"),"Mathematics · Tour 2")]),
      saved:()=>simpleProfileSubscreen(t("recommendations"),[listRow("book","Functions","Saved after Practice")]),
      settings:()=>simpleProfileSubscreen(t("settings"),[listRow("settings","Interface language","RU / UZ / EN"),listRow("settings","Content language","RU / UZ / EN · non-destructive")]),
      support:()=>simpleProfileSubscreen(t("support"),[listRow("info","Practice"),listRow("info","Tours"),listRow("info","Exam Prep"),listRow("info","Technical issue")]),
      information:()=>simpleProfileSubscreen(t("information"),[listRow("info",t("news")),listRow("info",t("community")),listRow("info",t("about"))])
    };
    root.innerHTML = (screens[state.screen] || homeView)();
    root.querySelectorAll("[data-nav]").forEach(el => el.addEventListener("click",()=>go(el.dataset.nav)));
    root.querySelectorAll("[data-screen]").forEach(el => el.addEventListener("click",()=>go(el.dataset.screen)));
    root.querySelectorAll("[data-back]").forEach(el => el.addEventListener("click",()=>go(el.dataset.back || routeGroup(state.screen))));
  }

  function selfTest() {
    const errors=[];
    const ok=(value,msg)=>{ if(!value) errors.push(msg); };
    ok(ROUTE_GROUP["math-hub"]==="study","Math Hub must remain owned by Study tab");
    ok(ROUTE_GROUP.resources==="study" && ROUTE_GROUP.tours==="study","Nested learning routes must remain in Study");
    ok(!JSON.stringify(copy).includes("Olympiad Practice"),"No duplicate Olympiad Practice destination");
    ok(!JSON.stringify(copy).includes("Tour archive"),"Tour archive must live inside Tours");
    ok(["core","ai","mentor"].includes(state.mode),"Service mode must be isolated");
    ok(!document.documentElement.innerHTML.includes("correct_answer"),"No answer-key field in UI preview");
    ok(!document.documentElement.innerHTML.toLowerCase().includes("supabase"),"Preview must remain synthetic/no Supabase");
    if(errors.length){ console.error("iClub v3 final global self-test failed",errors); return false; }
    console.info("iClub v3 final global self-test passed",{routes:Object.keys(ROUTE_GROUP).length,serviceModes:3});
    return true;
  }

  modeSelect.addEventListener("change",()=>{ state.mode=modeSelect.value; render(); });
  langSelect.addEventListener("change",()=>{ state.lang=langSelect.value; render(); });
  selfTest();
  render();
})();