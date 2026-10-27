(() => {
  "use strict";

  const ROOT_ID = "iclub-global-ai-root";
  const MARK_ID = "iclub-global-ai-mark";
  const PANEL_ID = "iclub-global-ai-panel";
  const HIDDEN_VIEWS = new Set(["splash", "registration", "certificate-verify"]);
  const PROTECTED_EXAM_PREP_TYPES = new Set(["diagnostic", "retest", "mixed", "timed", "paper"]);
  const MAX_INPUT_CHARS = 2000;
  const MAX_THREAD_MESSAGES = 40;
  const REQUEST_TIMEOUT_MS = 15000;

  const SUBJECT_ALIASES = {
    mathematics: ["mathematics", "математика", "matematika"],
    biology: ["biology", "биология", "biologiya"],
    chemistry: ["chemistry", "химия", "kimyo"],
    economics: ["economics", "экономика", "iqtisodiyot"],
    informatics: ["informatics", "информатика", "informatika"],
    english_a1: ["english a1", "английский a1", "ingliz tili a1"],
    english_a2: ["english a2", "английский a2", "ingliz tili a2"],
    english_b1: ["english b1", "английский b1", "ingliz tili b1"],
    sat: ["sat"],
    ielts: ["ielts"]
  };

  const COPY = {
    ru: {
      titleGeneral: "iClub AI",
      titleAcademic: "iClub AI Tutor",
      subtitleGeneral: "Помощник по iClub",
      open: "Открыть iClub AI",
      close: "Закрыть iClub AI",
      expand: "Развернуть на весь экран",
      restore: "Обычный размер",
      emptyTitle: "Чем помочь?",
      emptyCopy: "Выбери быстрый запрос или напиши свой вопрос.",
      betaIntro: "Помогу освоить Practice, разбор ошибок и учебные материалы. Объяснения учебных задач пока готовятся.",
      betaScope: "Пока доступны проверенные подсказки по работе с iClub. Учебные объяснения подключаем постепенно.",
      input: "Спросить iClub AI…",
      send: "Отправить",
      appHere: "Что можно делать здесь?",
      appPractice: "Как работает Practice?",
      appTours: "Как работают Tours?",
      appResults: "Где смотреть результаты?",
      topicMain: "Объясни эту тему",
      topicSimple: "Объясни проще",
      topicAlternative: "Объясни по-другому",
      topicFocus: "Что важно запомнить?",
      assessmentStart: "AI Tutor недоступен во время экзамена. Он вернётся после завершения.",
      assessmentTap: "AI Tutor недоступен во время экзамена. После завершения ты сможешь разобрать результат и ошибки.",
      unavailable: "iClub AI сейчас недоступен. Попробуй позже.",
      timeout: "Ответ занял слишком много времени. Попробуй ещё раз.",
      limitTitle: "Лимит iClub AI достигнут",
      limitReset: "Доступ восстановится в {time}.",
      limitPending: "Доступ восстановится после текущего периода.",
      routeInsufficient: "Для этого ответа сейчас недостаточно доступного лимита. Готовые объяснения могут быть доступны.",
      inDevelopment: "В разработке. AI-помощь по этой теме пока готовится.",
      practiceRules: "Как работает Practice?",
      practiceAfter: "Когда можно разобрать ошибки?",
      practiceResult: "Объяснить результат",
      practiceError: "Объяснить ошибку",
      practiceNext: "Что делать после Practice?",
      tourRules: "Правила Tours",
      tourArchive: "Когда открывается разбор тура?",
      topicStudy: "Как изучать эту тему?",
      homeNext: "Что делать дальше?",
      subjectStudy: "Как изучать предмет?",
      catalogHelp: "Как открыть предмет?",
      profileMeaning: "Что означают показатели?",
      ratings: "Как работает рейтинг?",
      notifications: "Как устроены уведомления?",
      community: "Как пользоваться сообществом?",
      certificates: "Как получить сертификат?",
      support: "Как обратиться за помощью?",
      about: "Что такое iClub?",
      books: "Как пользоваться книгами?",
      recs: "Как работают рекомендации?",
      archive: "Когда доступен архив?",
      video: "Как открыть видеоуроки?",
      appNav: "Помоги разобраться в разделе",
      subtitle: "Помощь в этом разделе",
      sectionNames: {"home":"Главная","ratings":"Рейтинг","profile":"Профиль","notifications":"Уведомления","community":"Сообщество","certificates":"Сертификаты","support":"Поддержка","support-topic":"Поддержка","about":"О проекте","archive":"Архив","courses":"Обучение"},
      subjectNames: {
        mathematics: "Математика",
        biology: "Биология",
        chemistry: "Химия",
        economics: "Экономика",
        informatics: "Информатика",
        english_a1:"Английский A1",english_a2:"Английский A2",
        english_b1:"Английский B1",sat:"SAT",ielts:"IELTS"
      }
    },
    uz: {
      titleGeneral: "iClub AI",
      titleAcademic: "iClub AI Tutor",
      subtitleGeneral: "iClub bo‘yicha yordamchi",
      open: "iClub AI'ni ochish",
      close: "iClub AI'ni yopish",
      expand: "To‘liq ekranga ochish",
      restore: "Odatdagi o‘lcham",
      emptyTitle: "Qanday yordam beray?",
      emptyCopy: "Tezkor so‘rovni tanla yoki o‘z savolingni yoz.",
      betaIntro: "Practice, xatolar tahlili va o‘quv materiallaridan foydalanishga yordam beraman. Masalalar izohi hali tayyorlanmoqda.",
      betaScope: "Hozircha iClub’dan foydalanish bo‘yicha tekshirilgan yordam mavjud. Fanlarga oid izohlar keyinroq qo‘shiladi.",
      input: "iClub AI'dan so‘rash…",
      send: "Yuborish",
      appHere: "Bu yerda nima qilish mumkin?",
      appPractice: "Practice qanday ishlaydi?",
      appTours: "Tours qanday ishlaydi?",
      appResults: "Natijalarni qayerda ko‘raman?",
      topicMain: "Shu mavzuni tushuntir",
      topicSimple: "Soddaroq tushuntir",
      topicAlternative: "Boshqacha tushuntir",
      topicFocus: "Nimani eslab qolish kerak?",
      assessmentStart: "AI Tutor imtihon vaqtida mavjud emas. Imtihon tugagach yana ishlaydi.",
      assessmentTap: "AI Tutor imtihon vaqtida mavjud emas. Tugagach natija va xatolarni tahlil qilishing mumkin.",
      unavailable: "iClub AI hozir mavjud emas. Keyinroq qayta urinib ko‘r.",
      timeout: "Javob juda uzoq davom etdi. Qayta urinib ko‘r.",
      limitTitle: "iClub AI limiti tugadi",
      limitReset: "Kirish {time} da tiklanadi.",
      limitPending: "Kirish joriy davrdan keyin tiklanadi.",
      routeInsufficient: "Bu javob uchun limit yetarli emas. Tayyor izohlar hali mavjud bo‘lishi mumkin.",
      inDevelopment: "Ishlab chiqilmoqda. Bu mavzu bo‘yicha AI yordami hali tayyorlanmoqda.",
      practiceRules: "Practice qanday ishlaydi?",
      practiceAfter: "Xatolarni qachon tahlil qilaman?",
      practiceResult: "Natijani tushuntir",
      practiceError: "Xatoni tushuntir",
      practiceNext: "Practice'dan keyin nima qilaman?",
      tourRules: "Tours qoidalari",
      tourArchive: "Tur tahlili qachon ochiladi?",
      topicStudy: "Bu mavzuni qanday o‘rganaman?",
      homeNext: "Keyin nima qilaman?",
      subjectStudy: "Fanni qanday o‘rganaman?",
      catalogHelp: "Fanni qanday ochaman?",
      profileMeaning: "Ko‘rsatkichlar nimani anglatadi?",
      ratings: "Reyting qanday ishlaydi?",
      notifications: "Bildirishnomalar qanday ishlaydi?",
      community: "Hamjamiyatdan qanday foydalanaman?",
      certificates: "Sertifikatni qanday olaman?",
      support: "Qanday yordam so‘rayman?",
      about: "iClub nima?",
      books: "Kitoblardan qanday foydalanaman?",
      recs: "Tavsiyalar qanday ishlaydi?",
      archive: "Arxiv qachon ochiladi?",
      video: "Video darslarni qanday ochaman?",
      appNav: "Shu bo‘limni tushuntir",
      subtitle: "Ushbu bo‘lim bo‘yicha yordam",
      sectionNames: {"home":"Bosh sahifa","ratings":"Reyting","profile":"Profil","notifications":"Bildirishnomalar","community":"Hamjamiyat","certificates":"Sertifikatlar","support":"Yordam","support-topic":"Yordam","about":"Loyiha haqida","archive":"Arxiv","courses":"O‘qish"},
      subjectNames: {
        mathematics: "Matematika",
        biology: "Biologiya",
        chemistry: "Kimyo",
        economics: "Iqtisodiyot",
        informatics: "Informatika",
        english_a1:"Ingliz tili A1",english_a2:"Ingliz tili A2",
        english_b1:"Ingliz tili B1",sat:"SAT",ielts:"IELTS"
      }
    },
    en: {
      titleGeneral: "iClub AI",
      titleAcademic: "iClub AI Tutor",
      subtitleGeneral: "iClub assistant",
      open: "Open iClub AI",
      close: "Close iClub AI",
      expand: "Expand to full screen",
      restore: "Restore panel size",
      emptyTitle: "How can I help?",
      emptyCopy: "Choose a quick prompt or type your own question.",
      betaIntro: "I can guide you through Practice, mistake review and study resources. Subject explanations are being prepared.",
      betaScope: "Verified help with iClub is available now. Subject explanations are being added gradually.",
      input: "Ask iClub AI…",
      send: "Send",
      appHere: "What can I do here?",
      appPractice: "How does Practice work?",
      appTours: "How do Tours work?",
      appResults: "Where can I see results?",
      topicMain: "Explain this topic",
      topicSimple: "Explain more simply",
      topicAlternative: "Explain it differently",
      topicFocus: "What should I remember?",
      assessmentStart: "AI Tutor is unavailable during the exam. It will return after you finish.",
      assessmentTap: "AI Tutor is unavailable during the exam. After you finish, you can review your result and errors.",
      unavailable: "iClub AI is unavailable right now. Try again later.",
      timeout: "The answer took too long. Try again.",
      limitTitle: "iClub AI limit reached",
      limitReset: "Access will return at {time}.",
      limitPending: "Access will return after the current period.",
      routeInsufficient: "There is not enough allowance for this answer. Prepared explanations may still be available.",
      inDevelopment: "In development. AI help for this topic is being prepared.",
      practiceRules: "How does Practice work?",
      practiceAfter: "When can I review mistakes?",
      practiceResult: "Explain the result",
      practiceError: "Explain the mistake",
      practiceNext: "What next after Practice?",
      tourRules: "Tours rules",
      tourArchive: "When does Tour review open?",
      topicStudy: "How do I study this topic?",
      homeNext: "What should I do next?",
      subjectStudy: "How do I study this subject?",
      catalogHelp: "How do I open a subject?",
      profileMeaning: "What do the indicators mean?",
      ratings: "How do leaderboards work?",
      notifications: "How do notifications work?",
      community: "How do I use Community?",
      certificates: "How do I earn certificates?",
      support: "How do I get support?",
      about: "What is iClub?",
      books: "How do I use Books?",
      recs: "How do recommendations work?",
      archive: "When does the archive open?",
      video: "How do I open video lessons?",
      appNav: "Help with this section",
      subtitle: "Help with this section",
      sectionNames: {"home":"Home","ratings":"Leaderboard","profile":"Profile","notifications":"Notifications","community":"Community","certificates":"Certificates","support":"Support","support-topic":"Support","about":"About","archive":"Archive","courses":"Study"},
      subjectNames: {
        mathematics: "Mathematics",
        biology: "Biology",
        chemistry: "Chemistry",
        economics: "Economics",
        informatics: "Informatics",
        english_a1:"English A1",english_a2:"English A2",
        english_b1:"English B1",sat:"SAT",ielts:"IELTS"
      }
    }
  };

  const state = {
    bootstrap: null,
    serverBlocked: false,
    examPrepBlocked: false,
    tourBlocked: false,
    practiceQuizBlocked: false,
    lastBlocked: false,
    toastTimer: null,
    bootstrapInFlight: null,
    viewObserver: null,
    tourObserver: null,
    practiceQuizObserver: null,
    contextObserver: null,
    contextTimer: null,
    resetTimer: null,
    busy: false,
    activeRequestId: null,
    practicePending: null,
    authUserId: null,
    authEpoch: 0,
    contextEpoch: 0,
    context: null,
    usageExhausted: false,
    resetAt: null,
    threads: new Map(),
    destroyed: false,
    introShown: false,
    introRead: false,
    firstOpenNote: false,
    introTimer: null
  };

  function locale() {
    const appLang = String(window.i18n?.getLang?.() || "").toLowerCase();
    if (appLang === "ru" || appLang === "uz" || appLang === "en") return appLang;
    const serverLang = String(state.bootstrap?.locale || "").toLowerCase();
    return serverLang === "uz" || serverLang === "en" ? serverLang : "ru";
  }

  function copy() {
    return COPY[locale()] || COPY.ru;
  }

  function activeViewName() {
    const active = document.querySelector(".view.is-active");
    return String(active?.dataset?.view || "").trim().toLowerCase();
  }

  function isEligibleView() {
    const name = activeViewName();
    return Boolean(name) && !HIDDEN_VIEWS.has(name);
  }

  function normalizeSubjectText(value) {
    return String(value || "").toLowerCase().replace(/\s+/g, " ").trim();
  }

  function subjectKeyFromText(value) {
    const text = normalizeSubjectText(value);
    for (const [key, aliases] of Object.entries(SUBJECT_ALIASES)) {
      if (aliases.some((alias) => text === alias || text.includes(alias))) return key;
    }
    return "";
  }

  function subjectName(key) {
    return copy().subjectNames?.[key] || key || "";
  }

  function examPrepSkillContext() {
    const host = document.getElementById("exam-prep-host-root");
    if (!host || host.hidden || host.getAttribute("aria-hidden") === "true") return null;
    const screen = host.querySelector("[data-ep-ai-skill-detail][data-ep-ai-skill-component]");
    if (!screen) return null;

    const skillCode = String(screen.getAttribute("data-ep-ai-skill-detail") || "").trim().toUpperCase();
    const componentCode = String(screen.getAttribute("data-ep-ai-skill-component") || "").trim().toUpperCase();
    if (!["P1", "P5"].includes(componentCode) || !skillCode.startsWith(componentCode + "-")) return null;

    return {
      threadKey: "mathematics",
      subjectKey: "mathematics",
      scopeCode: "exam_prep",
      academic: true,
      componentCode,
      skillCode,
      subjectLabel: subjectName("mathematics"),
      subtitle: `${subjectName("mathematics")} · ${componentCode}`
    };
  }

  function activeCoursesScreen() {
    const active = document.querySelector("#view-courses .stack-screen.is-active");
    return String(active?.id || "").replace(/^courses-/, "").trim();
  }

  function resolveContext() {
    const view = activeViewName();
    if (view === "courses") {
      const screenCode = activeCoursesScreen() || "all-subjects";
      // A separately named thread keeps the illustrative example away from
      // actual subject discussions, even within the offline QA Preview.
      if (screenCode === "practice-review" &&
          window.__ICLUB_AI_QA_DEMO__?.active === true) {
        return {
          threadKey: "qa_original_practice_demo",
          subjectKey: "mathematics",scopeCode: "global",
          screenCode,academic: true,componentCode: "",skillCode: "",
          subjectLabel: subjectName("mathematics"),
          subtitle: subjectName("mathematics") + " · Demo"
        };
      }
      const skill = examPrepSkillContext();
      if (skill) return { ...skill, screenCode: "exam_prep_skill" };
      // Never infer a current subject from a stale hub heading on the catalogue.
      if (screenCode !== "all-subjects") {
        const title = String(document.getElementById("subject-hub-title")?.textContent || "").trim();
        const key = subjectKeyFromText(title);
        if (key) return {
          threadKey: key, subjectKey: key, scopeCode: "global",
          screenCode, academic: true, componentCode: "", skillCode: "",
          subjectLabel: subjectName(key), subtitle: subjectName(key)
        };
      }
      return {
        // An unknown subject is NEVER the same conversation as the
        // catalogue. Keep the screen boundary explicit and fail closed.
        threadKey: screenCode === "all-subjects"
          ? "app_study_catalog" : "app_course_" + screenCode,
        subjectKey: "general", scopeCode: "global",
        screenCode, academic: false, componentCode: "", skillCode: "",
        subjectLabel: "", subtitle: copy().sectionNames?.courses || copy().subtitleGeneral
      };
    }
    return {
      threadKey: "app_" + view, subjectKey: "general", scopeCode: "global",
      screenCode: view, academic: false, componentCode: "", skillCode: "",
      subjectLabel: "", subtitle: copy().sectionNames?.[view] || copy().subtitleGeneral
    };
  }

  function currentBlocked() {
    return state.serverBlocked || state.examPrepBlocked || state.tourBlocked || state.practiceQuizBlocked;
  }

  function root() {
    return document.getElementById(ROOT_ID);
  }

  function mark() {
    return document.getElementById(MARK_ID);
  }

  function panel() {
    return document.getElementById(PANEL_ID);
  }

  // Friendly, strictly ephemeral onboarding; no localStorage, cookie, quota
  // reservation or permanent user tracking. Show once per app runtime.
  const INTRO_COPY = Object.freeze({
    ru:{
      title:"Знакомьтесь, iClub AI",
      message:"Помогу разобраться в iClub и доступных материалах. Нажмите, чтобы задать вопрос.",
      short:"iClub AI поможет с вопросами по приложению.",
      dismiss:"Закрыть подсказку",
      about:"О помощнике",
      infoTitle:"Как работает iClub AI",
      info:"Выберите готовый вопрос или напишите свой. Помощник использует только разрешённые данные и не меняет оценки или прогресс. Ответы могут быть неточными.",
      demo:"Демо · готовые подсказки по iClub",
      online:"Помощь по iClub доступна",
      offline:"AI временно недоступен",
      limits:"Лимит ответов достигнут"
    },
    uz:{
      title:"iClub AI bilan tanishing",
      message:"iClub va mavjud materiallarni tushunishga yordam beraman. Savol berish uchun belgini bosing.",
      short:"iClub AI ilova bo‘yicha savollarga yordam beradi.",
      dismiss:"Yopish",
      about:"Yordamchi haqida",
      infoTitle:"iClub AI qanday ishlaydi",
      info:"Tayyor savolni tanlang yoki o‘zingiz yozing. Yordamchi faqat ruxsat etilgan ma’lumotlardan foydalanadi va ballar yoki o‘quv jarayonini o‘zgartirmaydi. Javoblar xato bo‘lishi mumkin.",
      demo:"Namuna · iClub bo‘yicha tayyor javoblar",
      online:"iClub bo‘yicha yordam mavjud",
      offline:"AI vaqtincha ishlamayapti",
      limits:"Javoblar limiti tugadi"
    },
    en:{
      title:"Meet iClub AI",
      message:"I can help you navigate iClub and available learning resources. Tap the icon to ask.",
      short:"iClub AI can help with app questions.",
      dismiss:"Dismiss tip",
      about:"About the assistant",
      infoTitle:"How iClub AI works",
      info:"Choose a suggested question or type your own. The assistant uses only permitted information and never changes your grades or progress. Answers may be inaccurate.",
      demo:"Demo · prepared iClub guidance",
      online:"iClub help available",
      offline:"AI temporarily unavailable",
      limits:"Answer limit reached"
    }
  });
  const introCopy = () => INTRO_COPY[locale()] || INTRO_COPY.ru;
  function hideIntro() {
    if (state.introTimer) clearTimeout(state.introTimer);
    state.introTimer = null;
    const tip = root()?.querySelector("[data-global-ai-intro]");
    if (tip) tip.hidden = true;
  }
  function maybeShowIntro() {
    if (state.introShown || state.destroyed ||
        state.bootstrap?.visible !== true || currentBlocked() ||
        !isEligibleView() || activeViewName() !== "home" ||
        !mark() || mark().hidden || (panel() && !panel().hidden)) return;
    state.introShown = true;
    const tip = root()?.querySelector("[data-global-ai-intro]");
    if (!tip) return;
    const t = introCopy();
    tip.querySelector("[data-global-ai-intro-title]").textContent = t.title;
    tip.querySelector("[data-global-ai-intro-text]").textContent = t.message;
    tip.querySelector("[data-global-ai-intro-close]").setAttribute("aria-label",t.dismiss);
    tip.hidden = false;
    state.introTimer = setTimeout(hideIntro,5000);
  }
  function showToast(text, duration = 3000) {
    const toast = document.getElementById("toast");
    if (!toast || !text) return;
    toast.textContent = text;
    toast.classList.add("is-show");
    if (state.toastTimer) clearTimeout(state.toastTimer);
    state.toastTimer = setTimeout(() => {
      toast.classList.remove("is-show");
      state.toastTimer = null;
    }, duration);
  }

  function thread(key) {
    const threadKey = key || "general";
    if (!state.threads.has(threadKey)) {
      state.threads.set(threadKey, { messages: [] });
    }
    return state.threads.get(threadKey);
  }

  function appendMessage(threadKey, role, text, kind = "message") {
    const target = thread(threadKey);
    target.messages.push({
      role,
      kind,
      text: String(text || "").trim()
    });
    if (target.messages.length > MAX_THREAD_MESSAGES) {
      target.messages.splice(0, target.messages.length - MAX_THREAD_MESSAGES);
    }
  }

  function formatResetTime(value) {
    if (!value) return "";
    const date = new Date(value);
    if (!Number.isFinite(date.getTime())) return "";
    try {
      return new Intl.DateTimeFormat(locale() === "uz" ? "uz-UZ" : locale() === "en" ? "en-GB" : "ru-RU", {
        hour: "2-digit",
        minute: "2-digit"
      }).format(date);
    } catch {
      return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    }
  }

  function limitText() {
    const c = copy();
    const time = formatResetTime(state.resetAt);
    return time ? c.limitReset.replace("{time}", time) : c.limitPending;
  }

  function scheduleResetRefresh() {
    if (state.resetTimer) clearTimeout(state.resetTimer);
    state.resetTimer = null;
    if (!state.usageExhausted || !state.resetAt) return;

    const at = new Date(state.resetAt).getTime();
    if (!Number.isFinite(at)) return;
    const delay = Math.max(250, Math.min(2147480000, at - Date.now() + 500));
    state.resetTimer = setTimeout(() => {
      state.usageExhausted = false;
      state.resetAt = null;
      renderPanel();
      void refreshBootstrap();
    }, delay);
  }

  function setUsageExhausted(resetAt) {
    state.usageExhausted = true;
    state.resetAt = resetAt || state.resetAt || null;
    scheduleResetRefresh();
  }

  function destroyShell() {
    root()?.remove();
    document.documentElement.classList.remove("iclub-global-ai-active");
    state.lastBlocked = false;
  }

  function closePanel() {
    state.firstOpenNote = false;
    const p = panel();
    if (!p) return;
    p.setAttribute("data-expanded", "false");
    p.querySelector("[data-global-ai-expand]")?.setAttribute("aria-pressed", "false");
    if (p.hidden) return;
    p.hidden = true;
    mark()?.setAttribute("aria-expanded", "false");
  }

  function togglePanelExpanded() {
    const p = panel();
    if (!p || p.hidden || currentBlocked()) return;
    const expanded = p.getAttribute("data-expanded") !== "true";
    p.setAttribute("data-expanded", expanded ? "true" : "false");
    renderHeader();
  }

  // The single existing Tutor chat receives Practice context after a
  // server-side owner/finalization/consent preflight. No separate result card.
  let practiceGate = {key:"",allowed:false,pending:false};
  let practiceRecoveryCheckedKey="";
  let practiceRecoveryBusy=false;
  const practiceScope = () => {
    if(activeViewName()!=="courses")return null;
    const screen=activeCoursesScreen();
    if(screen!=="practice-result"&&screen!=="practice-review")return null;
    const el=document.getElementById("courses-"+screen);
    const id=Number(el?.dataset?.practiceAiAttemptId||0);
    if(!el?.classList.contains("is-active")||!Number.isSafeInteger(id)||id<=0)
      return null;
    return {screen,attemptRef:id,locale:locale()};
  };
  const practiceScopeKey = x => x ? [x.screen,x.attemptRef,x.locale].join("|") : "";
  async function checkPracticeChatGate(){
    const scope=practiceScope();
    const beta=window.iClubAiV21BetaClient;
    if(!scope||typeof beta?.practiceContextAvailable!=="function")return;
    const key=practiceScopeKey(scope);
    if(practiceGate.key===key)return;
    practiceGate={key,allowed:false,pending:true};
    const authEpoch=state.authEpoch,contextEpoch=state.contextEpoch;
    const allowed=await beta.practiceContextAvailable({
      attemptRef:scope.attemptRef,locale:scope.locale
    }).catch(()=>false);
    if(practiceGate.key!==key||authEpoch!==state.authEpoch||
       contextEpoch!==state.contextEpoch||
       practiceScopeKey(practiceScope())!==key)return;
    practiceGate={key,allowed:allowed===true,pending:false};
    if(panel()&&!panel().hidden){
      renderQuickPrompts();
      if(allowed===true)void recoverSavedPracticeReply();
    }
  }
  // Recovered replies live only in service-side PC4 receipts.
  // Nothing is persisted on the device or replayed from another learner.
  async function recoverSavedPracticeReply(retryAck=false){
    const scope=practiceScope(),beta=window.iClubAiV21BetaClient;
    if(!scope||!beta?.recoverPracticeFreeform||!beta?.ackRecoveredPracticeFreeform||
       panel()?.hidden||!practiceGate.allowed||
       practiceGate.key!==practiceScopeKey(scope)||
       state.bootstrap?.visible!==true||state.busy||
       practiceRecoveryBusy||currentBlocked())return;
    const key=practiceScopeKey(scope);
    const existing=state.practicePending;
    if(existing && (!existing.restored||existing.scopeKey!==key))return;
    if(!retryAck && practiceRecoveryCheckedKey===key)return;
    practiceRecoveryCheckedKey=key;
    practiceRecoveryBusy=true;
    const authEpoch=state.authEpoch,contextEpoch=state.contextEpoch;
    const threadKey=state.context?.threadKey;
    const stillCurrent=()=>authEpoch===state.authEpoch&&
      contextEpoch===state.contextEpoch&&
      state.context?.threadKey===threadKey&&
      practiceScopeKey(practiceScope())===key&&
      practiceGate.allowed&&practiceGate.key===key&&
      state.bootstrap?.visible===true&&!currentBlocked()&&
      panel()&&!panel().hidden;
    try{
      if(existing?.restored&&retryAck){
        const ack=await beta.ackRecoveredPracticeFreeform({
          requestId:existing.requestId,
          attemptRef:scope.attemptRef,locale:scope.locale
        });
        if(stillCurrent()&&ack?.ok===true&&
           state.practicePending?.requestId===existing.requestId)
          state.practicePending=null;
        return;
      }
      const recovered=await beta.recoverPracticeFreeform({
        attemptRef:scope.attemptRef,locale:scope.locale
      });
      if(!stillCurrent()||state.practicePending||recovered?.ok!==true||
         recovered.recovered!==true||recovered.mode!=="generated"||
         recovered.delivery_state!=="pending_ack"||
         typeof recovered.message!=="string"||
         typeof recovered.request_id!=="string")return;
      const recoveryHeading={
        ru:"Восстановлен ответ на предыдущий вопрос.",
        uz:"Oldingi savolga javob tiklandi.",
        en:"Your previous answer was recovered."
      }[scope.locale];
      const requestId=recovered.request_id;
      appendMessage(threadKey,"assistant",
        recoveryHeading+"\n"+recovered.message,"message");
      state.practicePending={scopeKey:key,requestId,
        question:"",messageShown:true,restored:true};
      renderPanel();
      const acknowledged=await beta.ackRecoveredPracticeFreeform({
        requestId,attemptRef:scope.attemptRef,locale:scope.locale
      });
      if(stillCurrent()&&acknowledged?.ok===true&&
         state.practicePending?.requestId===requestId)
        state.practicePending=null;
    }catch{/* Fail closed: no fallback to a new paid request. */}
    finally{
      practiceRecoveryBusy=false;
      if(stillCurrent())renderPanel();
    }
  }
  function quickPrompts(ctx) {
    const c = copy();
    const scope=practiceScope();
    if(scope&&practiceGate.allowed&&practiceGate.key===practiceScopeKey(scope)){
      const compare={
        ru:"Сравнить с прошлой попыткой",
        uz:"Oldingi urinish bilan solishtirish",
        en:"Compare with a previous attempt"
      };
      return [
        {key:"",label:c.practiceResult,practicePurpose:"practice_result"},
        {key:"",label:c.practiceNext,practicePurpose:"practice_next_step"},
        {key:"",label:compare[locale()]||compare.ru,
          practicePurpose:"practice_history_comparison"}
      ];
    }
    // Prepared-only beta: practical, editorially verified product guidance,
    // never fake personalized academic answers. Keep original panel/design.
    if (window.iClubAiV21BetaClient?.askPrepared) {
      const labels = {
        ru:{
          catalog_help:"С чего начать обучение?",
          practice_rules:"Как эффективнее проходить Practice?",
          practice_after:"Как разобрать и исправить ошибки?",
          recs_help:"Что повторять после тренировки?",
          tour_rules:"Как подготовиться к туру?",
          books_help:"Где найти материал для повторения?",
          support_help:"Как получить помощь?"
        },
        uz:{
          catalog_help:"O‘qishni nimadan boshlash kerak?",
          practice_rules:"Practice’dan samarali foydalanish yo‘li?",
          practice_after:"Xatolarni qanday tahlil qilaman?",
          recs_help:"Mashqdan keyin nimani takrorlash kerak?",
          tour_rules:"Turga qanday tayyorlanaman?",
          books_help:"Takrorlash uchun materiallar qayerda?",
          support_help:"Qanday yordam olish mumkin?"
        },
        en:{
          catalog_help:"Where should I begin studying?",
          practice_rules:"How can I use Practice effectively?",
          practice_after:"How do I review and fix mistakes?",
          recs_help:"What should I revisit after Practice?",
          tour_rules:"How should I prepare for a Tour?",
          books_help:"Where can I find review materials?",
          support_help:"How can I get support?"
        }
      };
      const context=ctx?.screenCode||activeViewName();
      const screens={
        home:["catalog_help","practice_after","tour_rules"],
        "all-subjects":["catalog_help","practice_rules","books_help"],
        "subject-hub":["catalog_help","practice_rules","books_help"],
        "practice-start":["practice_rules","practice_after","recs_help"],
        "practice-result":["practice_after","recs_help","practice_rules"],
        "practice-review":["practice_after","recs_help","books_help"],
        "practice-recs":["recs_help","practice_rules","books_help"],
        tours:["tour_rules","practice_rules","books_help"],
        "tour-rules":["tour_rules","practice_rules"],
        "tour-result":["tour_rules","support_help"],
        "tour-review":["tour_rules","support_help"],
        lessons:["catalog_help","books_help","practice_rules"],
        video:["books_help","catalog_help"],
        books:["books_help","practice_rules"],
        "my-recs":["recs_help","practice_after","books_help"],
        "my-rec-detail":["recs_help","practice_after"],
        profile:["recs_help","support_help","catalog_help"],
        ratings:["practice_rules","tour_rules","support_help"],
        support:["support_help","catalog_help"],
        "support-topic":["support_help"],
        about:["catalog_help","support_help"],
        community:["support_help","catalog_help"],
        certificates:["tour_rules","support_help"],
        archive:["tour_rules","support_help"],
        notifications:["support_help","catalog_help"]
      };
      const keys=screens[context]||["catalog_help","practice_after","tour_rules"];
      const t=labels[locale()]||labels.ru;
      return keys.map(key=>({key,label:t[key]}));
    }
    if (ctx?.subjectKey === "mathematics"
        && ctx?.scopeCode === "exam_prep"
        && ctx?.componentCode
        && ctx?.skillCode) {
      return [
        { key: "topic_main", label: c.topicMain },
        { key: "topic_simple", label: c.topicSimple },
        { key: "topic_alternative", label: c.topicAlternative },
        { key: "topic_focus", label: c.topicFocus }
      ];
    }

    const screen = ctx?.screenCode || activeViewName();
    const prompts = {
      "practice-start": [["practice_rules",c.practiceRules],["practice_after",c.practiceAfter]],
      "practice-result": [["practice_result",c.practiceResult],["practice_next",c.practiceNext]],
      "practice-review": [["practice_error",c.practiceError],["practice_next",c.practiceNext]],
      "practice-recs": [["practice_next",c.practiceNext],["practice_rules",c.practiceRules]],
      "tours": [["tour_rules",c.tourRules],["tour_archive",c.tourArchive]],
      "tour-rules": [["tour_rules",c.tourRules],["tour_archive",c.tourArchive]],
      "tour-result": [["tour_rules",c.tourRules],["tour_archive",c.tourArchive]],
      "tour-review": [["tour_archive",c.tourArchive],["tour_rules",c.tourRules]],
      "lessons": [["topic_study",c.topicStudy]],
      "video": [["video_help",c.video]],
      "books": [["books_help",c.books]],
      "my-recs": [["recs_help",c.recs]],
      "my-rec-detail": [["recs_help",c.recs]],
      "subject-hub": [["subject_study",c.subjectStudy],["practice_rules",c.practiceRules]],
      "all-subjects": [["catalog_help",c.catalogHelp],["app_help_here",c.appHere]],
      "home": [["home_next",c.homeNext],["practice_rules",c.practiceRules]],
      "profile": [["profile_meaning",c.profileMeaning],["app_help_results",c.appResults]],
      "ratings": [["ratings_help",c.ratings],["app_help_results",c.appResults]],
      "notifications": [["notifications_help",c.notifications]],
      "community": [["community_help",c.community]],
      "certificates": [["certificates_help",c.certificates]],
      "archive": [["archive_help",c.archive]],
      "support": [["support_help",c.support]],
      "support-topic": [["support_help",c.support]],
      "about": [["about_help",c.about]]
    };
    if (Object.prototype.hasOwnProperty.call(prompts, screen)) {
      return prompts[screen].map(([key,label])=>({key,label}));
    }
    const view = activeViewName();
    if (["profile", "ratings", "certificates", "archive"].includes(view)) {
      return [
        { key: "app_help_results", label: c.appResults },
        { key: "app_help_here", label: c.appHere },
        { key: "app_help_practice", label: c.appPractice }
      ];
    }

    return [
      { key: "app_help_here", label: c.appHere },
      { key: "app_help_practice", label: c.appPractice },
      { key: "app_help_tours", label: c.appTours }
    ];
  }

  function createMessageNode(message) {
    const row = document.createElement("div");
    row.className = `iclub-global-ai-message is-${message.role}${message.kind === "notice" ? " is-notice" : ""}`;
    const bubble = document.createElement("div");
    bubble.className = "iclub-global-ai-bubble";
    if (message.kind === "qa_practice_explanation" &&
        window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites === true &&
        window.__ICLUB_AI_QA_DEMO__?.active === true) {
      const lang = locale();
      const verifiedSample = window.__ICLUB_AI_QA_DEMO__.reply(lang);
      const content = window.__ICLUB_AI_QA_DEMO__.presentation?.(lang);
      if (verifiedSample === message.text && content) {
        row.classList.add("is-qa-explanation");
        const label = document.createElement("span");
        label.className = "iclub-qa-explain-label";
        label.textContent = content.label;
        const title = document.createElement("h3");
        title.className = "iclub-qa-explain-title";
        title.textContent = content.title;
        const intro = document.createElement("p");
        intro.className = "iclub-qa-explain-intro";
        intro.textContent = content.intro;
        bubble.append(label, title, intro);
        const steps = document.createElement("ol");
        steps.className = "iclub-qa-explain-steps";
        for (const step of content.steps) {
          const item = document.createElement("li");
          const heading = document.createElement("strong");
          heading.textContent = step.title;
          const formula = document.createElement("div");
          formula.className = "iclub-qa-explain-formula";
          formula.textContent = step.formula;
          const detail = document.createElement("p");
          detail.textContent = step.detail;
          item.append(heading,formula,detail);
          steps.append(item);
        }
        const check = document.createElement("div");
        check.className = "iclub-qa-explain-check";
        const checkTitle = document.createElement("strong");
        checkTitle.textContent = content.checkTitle;
        const checkQuestion = document.createElement("p");
        checkQuestion.textContent = content.checkQuestion;
        const checkAnswer = document.createElement("p");
        checkAnswer.className = "iclub-qa-explain-check-answer";
        checkAnswer.textContent = content.checkAnswer;
        const footer = document.createElement("small");
        footer.className = "iclub-qa-explain-disclosure";
        footer.textContent = content.disclosure;
        check.append(checkTitle,checkQuestion,checkAnswer);
        bubble.append(steps,check,footer);
      } else {
        bubble.textContent = message.text;
      }
    } else {
      bubble.textContent = message.text;
    }
    row.appendChild(bubble);
    return row;
  }

  function typingNode() {
    const row = document.createElement("div");
    row.className = "iclub-global-ai-message is-assistant is-typing";
    row.setAttribute("aria-label", "iClub AI");
    const bubble = document.createElement("div");
    bubble.className = "iclub-global-ai-bubble";
    bubble.innerHTML = '<span></span><span></span><span></span>';
    row.appendChild(bubble);
    return row;
  }

  function renderMessages() {
    const p = panel();
    if (!p || !state.context) return;
    const body = p.querySelector("[data-global-ai-messages]");
    const empty = p.querySelector("[data-global-ai-empty]");
    if (!body || !empty) return;

    // Keep existing message nodes in place: rebuilding the entire chat on each
    // state update replays animations and causes visible jumpiness.
    const threadKey = state.context.threadKey;
    const scroll = p.querySelector("[data-global-ai-scroll]");
    const autoScroll = !scroll || scroll.scrollHeight - scroll.scrollTop -
      scroll.clientHeight < 72;
    if (body.dataset.threadKey !== threadKey) {
      body.replaceChildren();
      body.dataset.threadKey = threadKey;
    }
    const typing = body.querySelector(":scope > .is-typing");
    if (typing) typing.remove();
    const messages = thread(threadKey).messages;
    empty.hidden = messages.length > 0 || state.busy;
    let changed = false;
    messages.forEach((message, i) => {
      const existing = body.children[i];
      if (existing?.__iclubMessageRef === message) return;
      const node = createMessageNode(message);
      node.__iclubMessageRef = message;
      if (existing) existing.replaceWith(node); else body.appendChild(node);
      changed = true;
    });
    while (body.children.length > messages.length) {
      body.lastElementChild.remove();
      changed = true;
    }
    if (state.busy) {
      body.appendChild(typingNode());
      changed = true;
    }
    if (changed && autoScroll) {
      const last = messages[messages.length - 1];
      const newest = body.children[messages.length - 1];
      queueMicrotask(() => {
        if (!scroll?.isConnected) return;
        if (last?.kind === "qa_practice_explanation" && newest?.isConnected) {
          // A long pedagogical explanation opens at STEP ONE, not its footer.
          const top = newest.getBoundingClientRect().top -
            scroll.getBoundingClientRect().top + scroll.scrollTop - 8;
          scroll.scrollTo({ top, behavior: window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
            ? "instant" : "smooth" });
        } else {
          scroll.scrollTop = scroll.scrollHeight;
        }
      });
    }
  }

  function renderQuickPrompts() {
    const p = panel();
    if (!p || !state.context) return;
    const host = p.querySelector("[data-global-ai-quick]");
    if (!host) return;
    host.replaceChildren();
    // An action already selected in Practice should not ask for the same
    // action again inside the conversation.
    const isSelectedDemo = window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites === true &&
      state.context.threadKey === "qa_original_practice_demo" &&
      window.__ICLUB_AI_QA_DEMO__?.active === true;
    host.hidden = isSelectedDemo;
    if (isSelectedDemo) return;

    const prompts = quickPrompts(state.context);
    const pending=state.practicePending,scope=practiceScope();
    if(pending&&scope&&practiceScopeKey(scope)===pending.scopeKey&&
       practiceGate.allowed&&practiceGate.key===pending.scopeKey){
      const retryLabel={ru:"Восстановить ответ",uz:"Javobni tiklash",
        en:"Recover my answer"}[locale()];
      prompts.unshift({key:"",label:retryLabel,practiceRetry:true});
    }
    for (const prompt of prompts) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "iclub-global-ai-quick-btn";
      button.textContent = prompt.label;
      button.disabled = state.busy || state.usageExhausted || currentBlocked();
      button.addEventListener("click", () => {
        if (button.disabled) return;
        button.classList.add("is-sent");
        if(prompt.practiceRetry){
          const pending=state.practicePending;
          if(pending?.restored)void recoverSavedPracticeReply(true);
          else if(pending)void sendMessage({promptKey:"",displayText:pending.question,
            userText:pending.question,practiceRetry:true});
          return;
        }
        if(prompt.practicePurpose){
          const scope=practiceScope();
          if(!scope||!practiceGate.allowed||
             practiceGate.key!==practiceScopeKey(scope))return;
          void sendMessage({promptKey:"",displayText:prompt.label,userText:"",
            practiceContext:{purpose:prompt.practicePurpose,attemptRef:scope.attemptRef}});
          return;
        }
        void sendMessage({ promptKey: prompt.key, displayText: prompt.label, userText: "" });
      });
      host.appendChild(button);
    }
  }

  function renderLimit() {
    const p = panel();
    if (!p) return;
    const box = p.querySelector("[data-global-ai-limit]");
    const title = p.querySelector("[data-global-ai-limit-title]");
    const text = p.querySelector("[data-global-ai-limit-text]");
    if (!box || !title || !text) return;
    box.hidden = !state.usageExhausted;
    if (state.usageExhausted) {
      title.textContent = copy().limitTitle;
      text.textContent = limitText();
    }
  }

  function renderComposer() {
    const p = panel();
    if (!p) return;
    const input = p.querySelector("[data-global-ai-input]");
    const send = p.querySelector("[data-global-ai-send]");
    if (!input || !send) return;

    input.placeholder = copy().input;
    input.maxLength = MAX_INPUT_CHARS;
    input.disabled = state.busy || state.usageExhausted || currentBlocked();
    send.disabled = input.disabled || !String(input.value || "").trim();
    send.setAttribute("aria-label", copy().send);
  }

  function renderHeader() {
    const p = panel();
    if (!p || !state.context) return;
    const title = p.querySelector("[data-global-ai-title]");
    const subtitle = p.querySelector("[data-global-ai-subtitle]");
    const close = p.querySelector("[data-global-ai-close]");
    const expand = p.querySelector("[data-global-ai-expand]");
    if (expand) {
      const expanded = p.getAttribute("data-expanded") === "true";
      expand.setAttribute("aria-pressed", expanded ? "true" : "false");
      expand.setAttribute("aria-label", expanded ? copy().restore : copy().expand);
    }
    if (title) title.textContent = state.context.academic ? copy().titleAcademic : copy().titleGeneral;
    if (subtitle) subtitle.textContent = state.context.subtitle || copy().subtitleGeneral;
    const status = p.querySelector("[data-global-ai-status]");
    if (status) {
      const t = introCopy();
      status.textContent = state.usageExhausted ? t.limits :
        window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites === true ? t.demo :
        state.bootstrap?.visible === true ? t.online : t.offline;
    }
    if (close) close.setAttribute("aria-label", copy().close);
  }

  function renderEmpty() {
    const p = panel();
    if (!p) return;
    const title = p.querySelector("[data-global-ai-empty-title]");
    const text = p.querySelector("[data-global-ai-empty-copy]");
    if (title) title.textContent = copy().emptyTitle;
    if (text) text.textContent = window.iClubAiV21BetaClient ? copy().betaIntro : copy().emptyCopy;
    const info = p.querySelector("[data-global-ai-first-info]");
    if (info) {
      info.hidden = !state.firstOpenNote;
      if (state.firstOpenNote) {
        const c = introCopy();
        info.querySelector("[data-global-ai-first-title]").textContent = c.infoTitle;
        info.querySelector("[data-global-ai-first-text]").textContent = c.info;
      }
    }
  }

  function renderDemoContext() {
    const p = panel();
    const host = p?.querySelector("[data-qa-practice-context]");
    if (!host) return;
    const isDemo = state.context?.threadKey === "qa_original_practice_demo" &&
      window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites === true &&
      window.__ICLUB_AI_QA_DEMO__?.active === true;
    host.hidden = !isDemo;
    if (!isDemo) return;
    const c = window.__ICLUB_AI_QA_DEMO__.context?.(locale());
    if (!c) { host.hidden = true; return; }
    host.replaceChildren();
    const title = document.createElement("span");
    title.className = "iclub-qa-context-label";
    title.textContent = c.label;
    const question = document.createElement("strong");
    question.className = "iclub-qa-context-question";
    question.textContent = c.question;
    const answer = document.createElement("span");
    answer.className = "iclub-qa-context-answer";
    answer.textContent = c.answer;
    host.append(title,question,answer);
  }

  function renderPanel() {
    if (!panel()) return;
    renderHeader();
    renderEmpty();
    renderDemoContext();
    renderMessages();
    renderQuickPrompts();
    renderLimit();
    renderComposer();
  }

  function ensurePanel() {
    const existing = panel();
    if (existing) {
      renderPanel();
      return existing;
    }

    const host = root();
    if (!host) return null;

    const p = document.createElement("section");
    p.id = PANEL_ID;
    p.className = "iclub-global-ai-panel";
    p.setAttribute("data-expanded", "false");
    p.setAttribute("role", "dialog");
    p.setAttribute("aria-modal", "false");
    p.setAttribute("aria-label", "iClub AI");
    p.hidden = true;
    p.innerHTML = `
      <header class="iclub-global-ai-head">
        <img class="iclub-global-ai-head-logo" src="iclub-ai-tutor-a.webp" alt="" aria-hidden="true" width="32" height="32" decoding="async">
        <div class="iclub-global-ai-head-copy">
          <div class="iclub-global-ai-title" data-global-ai-title></div>
          <div class="iclub-global-ai-subtitle" data-global-ai-subtitle></div>
          <div class="iclub-global-ai-status" data-global-ai-status></div>
        </div>
        <div class="iclub-global-ai-head-actions">
          <button class="iclub-global-ai-expand" type="button" data-global-ai-expand aria-pressed="false">
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M8 3H3v5M16 3h5v5M3 16v5h5M21 16v5h-5"/></svg>
          </button>
          <button class="iclub-global-ai-close" type="button" data-global-ai-close>
            <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 7l10 10M17 7 7 17"/></svg>
          </button>
        </div>
      </header>
      <div class="iclub-global-ai-scroll" data-global-ai-scroll>
        <div class="iclub-global-ai-empty" data-global-ai-empty>
          <div class="iclub-global-ai-empty-title" data-global-ai-empty-title></div>
          <div class="iclub-global-ai-empty-copy" data-global-ai-empty-copy></div>
          <aside class="iclub-global-ai-first-info" data-global-ai-first-info hidden>
            <strong data-global-ai-first-title></strong>
            <p data-global-ai-first-text></p>
          </aside>
        </div>
        <div class="iclub-qa-practice-context" data-qa-practice-context hidden></div>
        <div class="iclub-global-ai-messages" data-global-ai-messages aria-live="polite"></div>
      </div>
      <div class="iclub-global-ai-quick" data-global-ai-quick></div>
      <div class="iclub-global-ai-limit" data-global-ai-limit hidden>
        <strong data-global-ai-limit-title></strong>
        <span data-global-ai-limit-text></span>
      </div>
      <div class="iclub-global-ai-composer">
        <textarea rows="1" maxlength="2000" data-global-ai-input></textarea>
        <button type="button" class="iclub-global-ai-send" data-global-ai-send>
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12h13M13 7l5 5-5 5"/></svg>
        </button>
      </div>
    `;

    p.querySelector("[data-global-ai-close]")?.addEventListener("click", closePanel);
    p.querySelector("[data-global-ai-expand]")?.addEventListener("click", togglePanelExpanded);
    const input = p.querySelector("[data-global-ai-input]");
    const send = p.querySelector("[data-global-ai-send]");

    input?.addEventListener("input", () => renderComposer());
    input?.addEventListener("keydown", (event) => {
      if (event.key !== "Enter" || event.shiftKey || event.isComposing) return;
      event.preventDefault();
      const text = String(input.value || "").trim();
      if (text) void sendMessage({ promptKey: "", displayText: text, userText: text });
    });
    send?.addEventListener("click", () => {
      const text = String(input?.value || "").trim();
      if (text) void sendMessage({ promptKey: "", displayText: text, userText: text });
    });

    host.appendChild(p);
    renderPanel();
    return p;
  }

  function openPanel() {
    if (currentBlocked()) {
      showToast(copy().assessmentTap);
      return;
    }
    if (!isEligibleView()) return;
    if (!state.context) state.context = resolveContext();
    const p = ensurePanel();
    if (!p) return;
    hideIntro();
    if (!state.introRead) {
      state.introRead = true;
      state.firstOpenNote = true;
    }
    p.hidden = false;
    mark()?.setAttribute("aria-expanded", "true");
    renderPanel();
    void checkPracticeChatGate();
    if(practiceGate.allowed)void recoverSavedPracticeReply();
  }

  // QA-only, context-aware one-click help available across existing iClub
  // screens. The same existing AI panel is reused; no new tutoring provider.
  // Never submits grades, alters progress, or infers unverified results.
  const QA_CONTEXT_HELP = Object.freeze({
    home:"home_next","all-subjects":"catalog_help","subject-hub":"subject_study",
    video:"video_help",lessons:"topic_study",books:"books_help",
    "my-recs":"recs_help","my-rec-detail":"recs_help",
    "practice-start":"practice_rules","practice-result":"practice_next",
    "practice-recs":"practice_next",tours:"tour_rules",
    "tour-rules":"tour_rules","tour-result":"tour_archive",
    "tour-review":"tour_archive",ratings:"ratings_help",
    profile:"profile_meaning",notifications:"notifications_help",
    community:"community_help",certificates:"certificates_help",
    archive:"archive_help",support:"support_help",
    "support-topic":"support_help",about:"about_help"
  });
  let qaContextHelpBusy = false;
  async function runQaContextHelp(screenExpected) {
    if (qaContextHelpBusy || state.busy ||
        window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites !== true ||
        currentBlocked() || !isEligibleView() ||
        state.bootstrap?.visible !== true ||
        window.__ICLUB_AI_QA_DEMO__?.active === true) return false;
    reconcileContext();
    const context = { ...state.context };
    const screen = context.screenCode;
    if (screen !== screenExpected || context.scopeCode === "exam_prep") return false;
    const key = QA_CONTEXT_HELP[screen];
    if (!key) return false;
    const suggested = quickPrompts(context).find(p => p.key === key);
    if (!suggested) return false;
    qaContextHelpBusy = true;
    try {
      const authEpoch = state.authEpoch, contextEpoch = state.contextEpoch;
      openPanel();
      if (panel()?.hidden || currentBlocked() ||
          authEpoch !== state.authEpoch ||
          contextEpoch !== state.contextEpoch ||
          state.context?.screenCode !== screen) return false;
      await sendMessage({
        promptKey:key,displayText:suggested.label,userText:suggested.label
      });
      return true;
    } finally { qaContextHelpBusy = false; }
  }

  // QA only: a selected Practice action opens ONE contextual conversation.
  // No fake keystrokes, no redundant in-chat confirmation and no user writes.
  let qaDemoHandoffBusy = false;
  const QA_DEMO_PROMPT = Object.freeze({
    ru: "Почему ответ 6 неверный?",
    uz: "Nega 6 javobi noto‘g‘ri?",
    en: "Why is the answer 6 incorrect?"
  });

  async function runQaPracticeDemo() {
    if (qaDemoHandoffBusy || state.busy ||
        window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites !== true ||
        window.__ICLUB_AI_QA_DEMO__?.ready?.() !== true ||
        currentBlocked() || !isEligibleView()) return false;
    qaDemoHandoffBusy = true;
    try {
      reconcileContext();
      if (state.context?.screenCode !== "practice-review" ||
          state.context?.threadKey !== "qa_original_practice_demo" ||
          state.bootstrap?.visible !== true) return false;
      const epoch = state.contextEpoch;
      const auth = state.authEpoch;
      const stillValid = () => epoch === state.contextEpoch &&
        auth === state.authEpoch && !currentBlocked() &&
        window.__ICLUB_AI_QA_DEMO__?.ready?.() === true &&
        state.context?.threadKey === "qa_original_practice_demo" &&
        !panel()?.hidden;
      // The approved QA sample is a separate conversation. A new selection
      // clears only this sample thread, never subject-specific learner chats.
      state.threads.delete("qa_original_practice_demo");
      openPanel();
      if (!stillValid()) return false;
      // Request is already explicit in the clicked "Explain" action.
      // The contextual question is displayed immediately above the messages.
      const prompt = QA_DEMO_PROMPT[locale()] || QA_DEMO_PROMPT.ru;
      await sendMessage({
        promptKey: "practice_error", displayText: prompt, userText: prompt
      });
      return true;
    } finally {
      qaDemoHandoffBusy = false;
    }
  }

  function requestId() {
    try {
      return crypto.randomUUID();
    } catch {
      const part = () => Math.floor(Math.random() * 0xffffffff).toString(16).padStart(8, "0");
      return `${part()}-${part().slice(0,4)}-4${part().slice(1,4)}-8${part().slice(1,4)}-${part()}${part().slice(0,4)}`;
    }
  }

  async function invokeGlobalAi(body) {
    // Only an explicitly loaded, separately authorized connected-beta adapter
    // can route this QA copy to the real prepared-only server.
    const beta = window.iClubAiV21BetaClient;
    if(body?.intent==="practice_context"){
      if(typeof beta?.askPracticePrepared!=="function")
        return {data:null,error:{message:"practice_unavailable"}};
      const answer=await beta.askPracticePrepared({
        purpose:body.practice_purpose,attemptRef:body.attempt_ref,
        locale:body.locale,requestId:body.request_id
      });
      return {data:answer,error:null};
    }
    if (body?.intent === "practice_freeform") {
      if(typeof beta?.askPracticeFreeform!=="function")
        return {data:null,error:{message:"practice_unavailable"}};
      const answer=await beta.askPracticeFreeform({
        requestId:body.request_id,purpose:body.practice_purpose,
        attemptRef:body.attempt_ref,locale:body.locale,
        userText:body.user_text
      });
      return {data:answer,error:null};
    }
    if (body?.intent === "academic") {
      if (typeof beta?.askAcademic !== "function")
        return {data:null,error:{message:"academic_unavailable"}};
      const answer = await beta.askAcademic({
        surface:body.surface,recordId:body.record_id,
        questionId:body.question_id,locale:body.locale
      });
      return {data:answer,error:null};
    }
    // Only General Help can use the separately budgeted, real-model beta.
    // Keep ready-made buttons, protected academic routes and Tutor unchanged.
    if (beta && typeof beta.askGenerated === "function" &&
        body?.intent !== "academic" &&
        body?.subject_key === "general" &&
        body?.prompt_key === "" &&
        typeof body?.user_text === "string" &&
        body.user_text.trim().length >= 8) {
      const answer = await beta.askGenerated({
        requestId:body.request_id,locale:body.locale,
        userText:body.user_text
      });
      return {data:answer,error:null};
    }
    if (beta && typeof beta.askPrepared === "function") {
      const answer = await beta.askPrepared({
        promptKey: body?.prompt_key, locale: body?.locale,
        userText: body?.user_text
      });
      return { data: answer, error: null };
    }
    const client = window.sb;
    if (!client?.functions || typeof client.functions.invoke !== "function") {
      return { data: null, error: { message: "functions_unavailable" } };
    }

    return await Promise.race([
      client.functions.invoke("global-ai", { body }),
      new Promise((resolve) => setTimeout(() => resolve({ __globalAiTimedOut: true }), REQUEST_TIMEOUT_MS))
    ]);
  }

  async function sendMessage({
    promptKey,displayText,userText,academicContext=null,practiceContext=null,
    practiceRetry=false
  }) {
    if (state.busy || currentBlocked() || state.usageExhausted || !state.context) return;

    const context = { ...state.context };
    const threadKey = context.threadKey;
    const cleanDisplay = String(displayText || "").trim();
    const cleanText = String(userText || "").trim().slice(0, MAX_INPUT_CHARS);
    if (!cleanDisplay) return;
    const currentPractice = practiceScope();
    const contextOk = !!currentPractice && practiceGate.allowed &&
      practiceGate.key===practiceScopeKey(currentPractice);
    // A finalized Practice with no current server grant must NEVER fall back
    // to paid General Help, which could be charged for a stale/wrong attempt.
    if(currentPractice && !contextOk && !academicContext && !practiceContext &&
       promptKey==="" && cleanText.length>0){
      const label={ru:"Проверяем доступ к результату. Попробуйте снова после появления подсказок.",
        uz:"Natijaga kirish tekshirilmoqda. Tavsiyalar chiqqach, qayta urinib ko‘ring.",
        en:"Checking access to this result. Please retry once the suggestions appear."}[locale()];
      appendMessage(threadKey,"assistant",label,"notice");
      void checkPracticeChatGate();
      renderPanel();
      return;
    }
    const typedPractice = !academicContext && !practiceContext &&
      promptKey==="" && cleanText.length>=8 && contextOk
      ? {purpose:"practice_result",attemptRef:currentPractice.attemptRef,
         locale:currentPractice.locale,question:cleanText,
         scopeKey:practiceScopeKey(currentPractice)} : null;
    if (practiceRetry && (!typedPractice||!state.practicePending||
        state.practicePending.scopeKey!==typedPractice.scopeKey||
        state.practicePending.question!==typedPractice.question)) return;
    if(typedPractice && state.practicePending &&
       (state.practicePending.scopeKey!==typedPractice.scopeKey ||
        state.practicePending.question!==typedPractice.question)){
      const label={ru:"Сначала восстановите предыдущий ответ.",
        uz:"Avval oldingi javobni tiklang.",
        en:"Recover the previous answer first."}[locale()];
      appendMessage(threadKey,"assistant",label,"notice");
      renderPanel();
      return;
    }
    if (!practiceRetry) appendMessage(threadKey, "user", cleanDisplay);
    state.busy = true;
    const pending=typedPractice&&state.practicePending&&
      state.practicePending.scopeKey===typedPractice.scopeKey&&
      state.practicePending.question===typedPractice.question
      ?state.practicePending:null;
    const sentId=pending?.requestId||requestId();
    if(typedPractice)state.practicePending={...typedPractice,requestId:sentId,
      messageShown:pending?.messageShown===true};
    const sentAuthEpoch = state.authEpoch;
    const sentContextEpoch = state.contextEpoch;
    state.activeRequestId = sentId;
    const isStillCurrent = () => (
      state.authEpoch === sentAuthEpoch &&
      state.contextEpoch === sentContextEpoch &&
      state.activeRequestId === sentId &&
      state.bootstrap?.visible === true &&
      !currentBlocked() &&
      isEligibleView() &&
      (!practiceContext || (()=>{
        const current=practiceScope();
        return current?.attemptRef===practiceContext.attemptRef&&
          practiceGate.key===practiceScopeKey(current)&&practiceGate.allowed===true;
      })()) &&
      (!typedPractice || (()=>{
        const current=practiceScope();
        return practiceGate.allowed===true&&
          practiceScopeKey(current)===typedPractice.scopeKey&&
          (!state.practicePending ||
           state.practicePending.requestId===sentId);
      })())
    );

    const p = panel();
    const input = p?.querySelector("[data-global-ai-input]");
    if (input) input.value = "";
    renderPanel();

    const started = performance.now();
    try {
      const result = await invokeGlobalAi({
        request_id: sentId,
        locale: locale(),
        subject_key: context.subjectKey,
        scope_code: context.scopeCode,
        prompt_key: promptKey || "",
        user_text: cleanText,
        ...(academicContext ? {
          intent:"academic",surface:academicContext.surface,
          record_id:academicContext.recordId,
          question_id:academicContext.questionId
        } : {}),
        ...(practiceContext ? {
          intent:"practice_context",
          practice_purpose:practiceContext.purpose,
          attempt_ref:practiceContext.attemptRef
        } : {}),
        ...(typedPractice ? {
          intent:"practice_freeform",
          practice_purpose:typedPractice.purpose,
          attempt_ref:typedPractice.attemptRef
        } : {}),
        component_code: context.componentCode || "",
        skill_code: context.skillCode || "",
        ...(window.__ICLUB_AI_QA_PREVIEW__ ? {screen_code: context.screenCode || ""} : {})
      });

      // A response from an old account, exam or screen is NEVER rendered,
      // even if its legacy request succeeded before navigation.
      if (!isStillCurrent()) return;
      if (result?.__globalAiTimedOut === true) {
        appendMessage(threadKey, "assistant", copy().timeout, "notice");
        return;
      }

      const { data, error } = result || {};
      if (error || !data || typeof data !== "object") {
        appendMessage(threadKey, "assistant", copy().unavailable, "notice");
        return;
      }

      if (data.academic_state_changed !== false) {
        appendMessage(threadKey, "assistant", copy().unavailable, "notice");
        return;
      }

      const reason = String(data.reason || "");
      const message = String(data.message || "").trim();

      if (data.ok === true && message) {
        const isApprovedQaSample = promptKey === "practice_error" &&
          context.threadKey === "qa_original_practice_demo" &&
          window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites === true &&
          window.__ICLUB_AI_QA_DEMO__?.ready?.() === true &&
          window.__ICLUB_AI_QA_DEMO__.reply(locale()) === message;
        if(!typedPractice || state.practicePending?.messageShown!==true)
          appendMessage(threadKey, "assistant", message,
            isApprovedQaSample ? "qa_practice_explanation" : "message");
        if(typedPractice && state.practicePending?.requestId===sentId)
          state.practicePending.messageShown=true;
        // ACK only after insertion into the still-current existing Tutor thread.
        // An ACK timeout does not create a new request UUID: the original
        // in-memory receipt remains eligible for a same-ID recovery.
        if(typedPractice && data.delivery_state==="pending_ack" &&
           data.request_id===sentId && isStillCurrent()){
          const acknowledged=await window.iClubAiV21BetaClient?.ackPracticeFreeform?.({
            requestId:sentId,purpose:typedPractice.purpose,
            attemptRef:typedPractice.attemptRef,locale:typedPractice.locale,
            userText:typedPractice.question
          });
          if(acknowledged?.ok===true &&
             state.practicePending?.requestId===sentId)
            state.practicePending=null;
        }
        if (data.usage_exhausted === true) {
          setUsageExhausted(data.reset_at || null);
        }
        return;
      }

      if (reason === "active_assessment") {
        state.serverBlocked = true;
        closePanel();
        showToast(copy().assessmentStart);
        void refreshBootstrap();
        return;
      }

      // New route-specific shortfall never closes the remaining inexpensive routes.
      // Legacy usage_exhausted remains separate until backend parity is complete.
      if (reason === "route_insufficient") {
        appendMessage(threadKey, "assistant", copy().routeInsufficient, "notice");
        return;
      }

      if (reason === "usage_exhausted") {
        setUsageExhausted(data.reset_at || null);
        appendMessage(threadKey, "assistant", message || copy().limitTitle, "notice");
        return;
      }

      // An unpublished topic is not a quota failure and cannot trigger
      // a guessed model response. General Help has its own release gate.
      if (["in_development", "subject_not_ready", "approved_source_missing",
           "source_not_ready", "no_source", "topic_not_released"].includes(reason)
          || data.mode === "in_development") {
        appendMessage(threadKey, "assistant", window.iClubAiV21BetaClient ? copy().betaScope : copy().inDevelopment, "notice");
        return;
      }

      appendMessage(threadKey, "assistant", message || copy().unavailable, "notice");
    } catch {
      if (isStillCurrent()) appendMessage(threadKey, "assistant", copy().unavailable, "notice");
    } finally {
      const elapsed = performance.now() - started;
      if (elapsed < 180) {
        await new Promise((resolve) => setTimeout(resolve, 180 - elapsed));
      }
      if (isStillCurrent()) {
        state.busy = false;
        state.activeRequestId = null;
        renderPanel();
        if (state.usageExhausted) scheduleResetRefresh();
      }
    }
  }

  function ensureShell() {
    let host = root();
    if (host) return host;

    host = document.createElement("div");
    host.id = ROOT_ID;
    host.className = "iclub-global-ai-root";
    host.setAttribute("data-global-ai-shell-version", "conversations-v1");

    const button = document.createElement("button");
    button.id = MARK_ID;
    button.className = "iclub-global-ai-mark";
    button.type = "button";
    button.setAttribute("aria-haspopup", "dialog");
    button.setAttribute("aria-expanded", "false");
    // Architect-approved iClub AI Tutor mark A; local, QA-only, no external resources.
    button.innerHTML = '<img class="iclub-global-ai-mark-logo" src="iclub-ai-tutor-a.webp" alt="" aria-hidden="true" width="40" height="40" decoding="async">';
    button.addEventListener("click", () => {
      if (currentBlocked()) {
        showToast(copy().assessmentTap);
        return;
      }
      const p = panel();
      if (p && !p.hidden) {
        closePanel();
        return;
      }
      // Global AI icon is navigation ONLY: opening the chat cannot submit,
      // generate, charge quota or replay a previous suggestion.
      openPanel();
    });

    // Single discreet button anchored to the app shell, with no additional
    // bottom panel, stripe, fifth tab or full-width UI surface.
    host.appendChild(button);
    const tip = document.createElement("aside");
    tip.className = "iclub-global-ai-intro";
    tip.setAttribute("data-global-ai-intro","");
    tip.setAttribute("aria-label","iClub AI");
    tip.hidden = true;
    tip.innerHTML =
      '<div class="iclub-global-ai-intro-content">'+
      '<strong data-global-ai-intro-title></strong>'+
      '<p data-global-ai-intro-text></p></div>'+
      '<button type="button" data-global-ai-intro-close aria-label="Close">×</button>';
    tip.querySelector("[data-global-ai-intro-close]").addEventListener("click",hideIntro);
    host.appendChild(tip);
    document.body.appendChild(host);
    return host;
  }

  function contextIdentity(ctx) {
    if (!ctx) return "";
    return [ctx.threadKey,ctx.subjectKey,ctx.scopeCode,
      ctx.componentCode||"",ctx.skillCode||"",ctx.screenCode||""].join("|");
  }

  function invalidatePendingAnswer() {
    state.contextEpoch += 1;
    state.activeRequestId = null;
    state.busy = false;
  }

  function reconcileContext() {
    const current=practiceScope();
    if(!current || practiceGate.key!==practiceScopeKey(current)){
      practiceGate={key:"",allowed:false,pending:false};
    }
    const next = resolveContext();
    const previous = contextIdentity(state.context);
    const nextKey = contextIdentity(next);
    if (previous && previous !== nextKey) {
      invalidatePendingAnswer();
      closePanel();
    }
    state.context = next;
    if (panel() && !panel().hidden){
      renderPanel();
      void checkPracticeChatGate();
    }
  }

  function scheduleContextReconcile() {
    if (state.contextTimer) clearTimeout(state.contextTimer);
    state.contextTimer = setTimeout(() => {
      state.contextTimer = null;
      reconcilePracticeQuizBlock();
      reconcileContext();
      reconcileShell();
    }, 35);
  }

  function reconcileShell({ announceBlock = false } = {}) {
    const allowed = state.bootstrap?.visible === true;
    if (!allowed || !isEligibleView()) {
      closePanel();
      const host = root();
      if (host) host.hidden = true;
      hideIntro();
      document.documentElement.classList.remove("iclub-global-ai-active");
      state.lastBlocked = currentBlocked();
      return;
    }

    if (!state.context) state.context = resolveContext();
    const host = ensureShell();
    host.hidden = false;
    document.documentElement.classList.add("iclub-global-ai-active");

    const blocked = currentBlocked();
    const m = mark();
    if (m) {
      const c = copy();
      // Decision 33B: completely hide the mark during protected assessment.
      // CSS [hidden] override is required because this button normally uses inline-flex.
      m.hidden = blocked;
      m.setAttribute("aria-label", c.open);
      m.removeAttribute("aria-disabled");
      if (blocked) m.setAttribute("aria-expanded", "false");
    }

    if (blocked) { closePanel(); hideIntro(); }
    if (announceBlock && blocked && !state.lastBlocked) {
      showToast(copy().assessmentStart);
    }

    state.lastBlocked = blocked;
    renderPanel();
    if (!blocked) maybeShowIntro();
  }

  function reconcileTourBlock({ announce = false } = {}) {
    const tourQuiz = document.getElementById("courses-tour-quiz");
    const blocked = Boolean(tourQuiz?.classList.contains("is-active"));
    const changed = blocked !== state.tourBlocked;
    if (blocked && changed) invalidatePendingAnswer();
    state.tourBlocked = blocked;
    reconcileShell({ announceBlock: announce && changed && blocked });
  }

  // Ordinary Practice is an active assessment until the server finalizes it.
  // Both the floating button AND all pending AI replies must disappear.
  function reconcilePracticeQuizBlock() {
    const practiceQuiz = document.getElementById("courses-practice-quiz");
    const blocked = activeViewName() === "courses" &&
      Boolean(practiceQuiz?.classList.contains("is-active"));
    const changed = blocked !== state.practiceQuizBlocked;
    if (blocked && changed) invalidatePendingAnswer();
    state.practiceQuizBlocked = blocked;
    if (changed) reconcileShell();
  }

  function handleExamPrepSession(event) {
    const session = event?.detail?.session || {};
    const type = String(session?.session_type || "").toLowerCase();
    const status = String(session?.status || "active").toLowerCase();
    const blocked = status === "active" && PROTECTED_EXAM_PREP_TYPES.has(type);
    const changed = blocked !== state.examPrepBlocked;
    if (blocked && changed) invalidatePendingAnswer();
    state.examPrepBlocked = blocked;
    reconcileShell({ announceBlock: changed && blocked });
  }

  function handleExamPrepEnded() {
    state.examPrepBlocked = false;
    reconcileTourBlock();
    scheduleContextReconcile();
    void refreshBootstrap();
  }

  function onAuthStateChanged(event, session) {
    const id = typeof session?.user?.id === "string" ? session.user.id : null;
    const logout = event === "SIGNED_OUT" || event === "USER_DELETED";
    const initialEmpty = event === "INITIAL_SESSION" && !session;
    if (logout || initialEmpty || id) {
      const nextUserId = logout || initialEmpty ? null : id;
      if (logout || state.authUserId !== nextUserId) {
        state.authUserId = nextUserId;
        state.authEpoch += 1;
        state.practicePending=null;
        practiceRecoveryCheckedKey="";
        practiceRecoveryBusy=false;
        practiceGate={key:"",allowed:false,pending:false};
        invalidatePendingAnswer();
        state.threads.clear();
        state.context = null;
        state.bootstrap = null;
        state.usageExhausted = false;
        state.resetAt = null;
        if (state.resetTimer) clearTimeout(state.resetTimer);
        state.resetTimer = null;
        destroyShell();
      }
    }
    // TOKEN_REFRESHED for the same account preserves the current chat.
    queueMicrotask(() => { void refreshBootstrap(); });
  }

  async function refreshBootstrap() {
    if (state.bootstrapInFlight) return state.bootstrapInFlight;
    const epoch = state.authEpoch;
    const client = window.sb;
    if (!client?.rpc) {
      state.bootstrap = null;
      destroyShell();
      return null;
    }

    state.bootstrapInFlight = (async () => {
      try {
        const beta = window.iClubAiV21BetaClient;
        let data, error;
        if (beta && typeof beta.status === "function") {
          const permission = await beta.status();
          data = {
            visible: permission?.eligible === true,
            locale: locale(),
            assessment_blocked: false,
            usage_exhausted: false
          };
          error = permission?.ok === true ? null : { message: "beta_gate_unavailable" };
        } else {
          ({ data, error } = await client.rpc("get_iclub_ai_ui_bootstrap_v1"));
        }
        // An old account's in-flight bootstrap must not show its UI in the
        // newly signed-in account, even when its request finishes last.
        if (epoch !== state.authEpoch) return null;
        if (error || !data || typeof data !== "object") {
          state.bootstrap = null;
          destroyShell();
          return null;
        }
        state.bootstrap = data;
        state.serverBlocked = data.assessment_blocked === true;
        state.usageExhausted = data.usage_exhausted === true;
        state.resetAt = state.usageExhausted ? (data.reset_at || null) : null;
        if (state.usageExhausted) scheduleResetRefresh();
        reconcileTourBlock();
        reconcilePracticeQuizBlock();
        reconcileContext();
        reconcileShell();
        return data;
      } catch {
        if (epoch !== state.authEpoch) return null;
        state.bootstrap = null;
        destroyShell();
        return null;
      } finally {
        state.bootstrapInFlight = null;
        if (epoch !== state.authEpoch && !state.destroyed) {
          queueMicrotask(() => { void refreshBootstrap(); });
        }
      }
    })();

    return state.bootstrapInFlight;
  }

  function attachObservers() {
    const tourQuiz = document.getElementById("courses-tour-quiz");
    if (tourQuiz) {
      state.tourObserver?.disconnect?.();
      state.tourObserver = new MutationObserver(() => reconcileTourBlock({ announce: true }));
      state.tourObserver.observe(tourQuiz, { attributes: true, attributeFilter: ["class"] });
    }

    const practiceQuiz = document.getElementById("courses-practice-quiz");
    if (practiceQuiz) {
      state.practiceQuizObserver?.disconnect?.();
      state.practiceQuizObserver = new MutationObserver(reconcilePracticeQuizBlock);
      state.practiceQuizObserver.observe(practiceQuiz, {
        attributes: true, attributeFilter: ["class", "hidden", "aria-hidden"]
      });
    }
    state.viewObserver?.disconnect?.();
    state.viewObserver = new MutationObserver(scheduleContextReconcile);
    document.querySelectorAll(".view[data-view]").forEach((view) => {
      state.viewObserver.observe(view, { attributes: true, attributeFilter: ["class"] });
    });

    state.contextObserver?.disconnect?.();
    state.contextObserver = new MutationObserver(scheduleContextReconcile);
    const courseView = document.getElementById("view-courses");
    if (courseView) {
      state.viewObserver.observe(courseView, {
        subtree: true, attributes: true, attributeFilter: ["class"]
      });
    }
    const subjectTitle = document.getElementById("subject-hub-title");
    if (subjectTitle) {
      state.contextObserver.observe(subjectTitle, { childList: true, subtree: true, characterData: true });
    }
    const examRoot = document.getElementById("exam-prep-host-root");
    if (examRoot) {
      state.contextObserver.observe(examRoot, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["hidden", "aria-hidden", "data-ep-ai-skill-detail", "data-ep-ai-skill-component"]
      });
    }
  }

  function attach() {
    if (state.destroyed) return;

    window.addEventListener("iclub:exam-prep-session", handleExamPrepSession);
    window.addEventListener("iclub:exam-prep-session-ended", handleExamPrepEnded);
    window.addEventListener("iclub:global-ai-bootstrap-refresh", () => { void refreshBootstrap(); });
    window.addEventListener("focus", () => { void refreshBootstrap(); });

    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape") closePanel();
    });

    try {
      window.sb?.auth?.onAuthStateChange?.(onAuthStateChanged);
    } catch {}

    attachObservers();
    state.context = resolveContext();
    setTimeout(() => { void refreshBootstrap(); }, 0);
  }

  // One source-driven launch hook for Practice, Lessons and Tour archive.
  // The service derives the owner and all academic facts, never the browser.
  function explainAcademic({surface,recordId,questionId=null,displayText}={}){
    // Video is a subject-level Telegram hub, not a confirmed lesson view.
    // Keep the generic server lesson contract for the future true lesson screen,
    // but never bind the first/primary lesson ID to this content.
    const views={practice_error:"practice-review",tour_archive:"tour-review"};
    const code=views[surface];
    if(!code||!Number.isSafeInteger(recordId)||recordId<=0||
       (surface==="practice_error"
        ?!Number.isSafeInteger(questionId)||questionId<=0
        :questionId!==null)||
       state.bootstrap?.visible!==true||state.busy||
       currentBlocked()||!isEligibleView()||
       activeViewName()!=="courses"||activeCoursesScreen()!==code)
      return false;
    reconcileContext();
    openPanel();
    const c=copy();
    const label=surface==="practice_error"?c.practiceError:
      surface==="lesson_topic"?c.topicMain:c.tourArchive;
    void sendMessage({promptKey:"",displayText:displayText||label,
      userText:"",academicContext:{surface,recordId,questionId}});
    return true;
  }

  window.iClubGlobalAiShell = Object.freeze({
    version: "global_ai_conversations_v1",
    refresh: () => refreshBootstrap(),
    open: () => openPanel(),
    close: () => closePanel(),
    explainAcademic,
    // Does not bypass any protected Practice/Tour/source checks.
    runQaPracticeDemo,
    runQaContextHelp,
    context: () => ({ ...(state.context || resolveContext()) })
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", attach, { once: true });
  } else {
    attach();
  }
})();