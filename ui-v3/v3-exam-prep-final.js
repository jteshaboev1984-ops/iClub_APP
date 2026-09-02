(() => {
  "use strict";

  const root = document.getElementById("epv3-root");
  const modeSelect = document.getElementById("epv3-mode");
  const langSelect = document.getElementById("epv3-lang");

  const state = {
    screen: "overview",
    stack: [],
    entryOrigin: "study",
    component: "P1",
    areaId: "DIF",
    skillId: "P1-DIF-02",
    mode: "core",
    lang: "en",
    setupComplete: false,
    placement: { P1: "notStarted", P5: "notStarted" },
    weeklyMode: "normal",
    session: null,
    selectedOption: null,
    feedback: null
  };

  const EN = {
    home:"Home",study:"Study",ratings:"Ratings",profile:"Profile",back:"Back",close:"Close",mathematics:"Mathematics",cambridge:"Cambridge AS Mathematics",
    examPrep:"Exam preparation",learningSyllabus:"Learning the syllabus",learningSyllabusSub:"Build secure syllabus coverage first, then move into mixed and timed evidence.",
    upNext:"Up next",paper1:"Paper 1",paper5:"Paper 5",pure:"Pure Mathematics 1",stats:"Probability & Statistics 1",coverage:"Syllabus coverage",evidence:"Evidence",building:"Building",starting:"Starting",confirmed:"Confirmed",learning:"Learning",needsRetest:"Needs retest",timedEvidence:"Timed evidence",notStarted:"Not started",inProgress:"In progress",completed:"Completed",
    next:"Next",chainRule:"Chain Rule practice",reprData:"Representation of Data",startPractice:"Start practice",quickAccess:"Quick access",weeklyPlan:"Weekly plan",syllabusProgress:"Syllabus progress",corrections:"Corrections & retests",timedHub:"Timed practice & papers",
    setup:"Preparation setup",setupNeeded:"Set up your preparation before relying on the weekly plan.",setupSub:"Planning details change pace and scheduling, not academic truth.",examSeries:"Exam series / target window",weeklyMath:"Mathematics time per week",hours:"hours",experience:"Previous experience",studiedP1:"I have studied parts of Paper 1",studiedP5:"I have studied parts of Paper 5",fullP1:"I have attempted a full Paper 1",fullP5:"I have attempted a full Paper 5",goal:"Personal goal",saveSetup:"Save preparation setup",setupSaved:"Preparation setup saved",
    placement:"Starting-point check",findStart:"Find your starting point",placementIntro:"Paper 1 and Paper 5 are checked separately so one component can move ahead without borrowing evidence from the other.",skills45:"45 syllabus skills",skills36:"36 syllabus skills",startPlacement:"Start check",continuePlacement:"Continue check",viewResult:"View result",separatePlacement:"You can complete Paper 1 and Paper 5 separately.",foundationCheck:"Some foundation skills may be checked, but they never count toward P1/P5 coverage.",
    question:"Question",of:"of",submitAnswer:"Submit answer",answerRecorded:"Answer recorded",nextQuestion:"Next question",leaveSession:"Leave this session?",leaveSessionText:"Confirmed responses are retained where this mode allows resume. Incomplete evidence never creates progress.",continueSession:"Continue session",leave:"Leave",assessmentProtected:"Detailed answer feedback stays hidden during protected assessment.",
    placementResult:"Starting-point result",startingPoint:"Starting point",strongEvidence:"Strong evidence",needsAttention:"Needs attention",recommendedFocus:"Recommended first focus",quadratics:"Quadratics",basicFunctions:"Basic functions",coordinateGeometry:"Coordinate geometry",functions:"Functions",buildPlan:"Build my plan",placementNotDone:"Check not completed",completeOther:"Complete this component to set its own starting point.",foundationReview:"Foundation review",foundationTwo:"2 foundation areas need attention.",foundationNoCredit:"Foundation work does not increase P1 or P5 syllabus coverage.",moreEvidence:"More evidence needed",moreEvidenceText:"A little more evidence is needed before safely skipping this area.",continueCheck:"Continue check",
    foundationSkills:"Foundation skills",foundationSkillsMeta:"Shared foundations • outside P1/P5 coverage",skills:"skills",circular:"Circular measure",trigonometry:"Trigonometry",series:"Series",differentiation:"Differentiation",integration:"Integration",data:"Representation of data",counting:"Permutations & combinations",probability:"Probability",drv:"Discrete random variables",normal:"Normal distribution",
    powers:"Differentiate powers and simple functions",chainSkill:"Applying the chain rule",stationary:"Using derivatives to find stationary points",dataSkill:"Interpret cumulative-frequency information",probSkill:"Use conditional probability",normalSkill:"Use the normal distribution",retest:"Retest",continue:"Continue",skillDetail:"Skill detail",currentEvidence:"Current evidence",learn:"Learn",practice:"Practice",mixedPractice:"Mixed practice",resource:"Resource",evidenceJourney:"Evidence journey",initialCheck:"Initial check",learningPractice:"Learning practice",correction:"Correction",delayedRetest:"Delayed retest",mixedTimed:"Mixed / timed evidence",latestIssue:"Latest issue",substitutionIssue:"Incorrect substitution in the inner function",reviewCorrection:"Review correction",foundationRequirement:"Foundation requirement",algebraConfirmed:"Algebraic manipulation — confirmed",
    thisWeek:"This week",actionsDone:"4 of 6 actions completed",primaryPriorities:"Main priorities",dueToday:"Due today",conditionalProbability:"Conditional probability",functionsMixed:"Functions mixed set",recoveryWeek:"Recovery week",recoveryText:"Volume is temporarily reduced after an interruption. Evidence standards do not change.",lateJoiner:"Focused starting week",lateJoinerText:"The plan starts from evidence instead of skipping stages because of the calendar.",normalWeek:"Normal week",
    needsCorrection:"Needs correction",readyRetest:"Ready for retest",stable:"Confirmed / stable",quadraticIneq:"Quadratic inequalities",endpointIssue:"Incorrect interval endpoint",review:"Review correction",conditionalProb:"Conditional probability",availableNow:"Retest available now",chainStable:"Chain rule",retestPassed:"Delayed retest passed",whatWrong:"What went wrong",whyMatters:"Why it matters",correctMethod:"Correct method",similarPractice:"Similar practice",evidenceConfirmed:"Evidence confirmed",morePractice:"More practice needed",
    timedSections:"Timed section",mixedTimedSets:"Mixed timed set",fullPaper:"Full paper",purpose:"Purpose",duration:"Duration",firstTimed:"Build timing on a focused section",transfer:"Test transfer across mixed skills",fullEvidence:"Collect full-paper evidence",start:"Start",latest:"Latest comparable result",notEnough:"Not enough comparable evidence yet",paperInstructions:"Full-paper instructions",paperInstructionsText:"This attempt is recorded as a component-specific paper session. Leaving early can make it non-comparable.",beginPaper:"Begin full paper",paperSession:"Full paper session",submitPaper:"Submit paper",finishPaper:"Finish paper",paperResult:"Paper result",rawMark:"Raw mark",actualTime:"Actual time",inTimeMarks:"Marks earned in official time",unattempted:"Unattempted marks",lossCauses:"Main loss causes",reviewLosses:"Review important losses",appReadiness:"App readiness estimate",onTrack:"On track",risk:"At risk",readinessNote:"This is an iClub evidence estimate, not a predicted Cambridge grade.",
    aiAssist:"AI Assist",whyNext:"Why this is next",aiNextText:"Your basic differentiation evidence is stable, while Chain Rule transfer still needs reinforcement.",explainDifferent:"Explain this differently",explainMistake:"Explain my mistake",mentorCare:"Mentor Care",nextReview:"Next review: Thursday",latestReview:"Latest review",writtenSolution:"Paper 1 • Chain Rule written solution",reviewed:"Reviewed",mentorText:"Show the substitution step clearly before simplifying.",viewFeedback:"View feedback",mentorReview:"Mentor review",mentorOnly:"Available only for an active Mentor Care assignment.",moreEvidenceNeeded:"More evidence needed",
    mcq:"Multiple choice",learningMode:"Learning",placementMode:"Starting-point check",retestMode:"Retest",timedMode:"Timed assessment",paperMode:"Paper",answer:"Answer",correctDemo:"Answer confirmed. Continue to the next learning step.",incorrectDemo:"This attempt needs correction before the evidence can be closed.",retestPass:"Retest confirmed. This fresh evidence closes the current correction cycle.",retestReopen:"More practice is needed. The correction cycle remains open.",
    preparationMenu:"Preparation settings",safePreview:"Synthetic implementation preview • no Supabase • no production writes"
  };

  const RU = {
    home:"Главная",study:"Учёба",ratings:"Рейтинг",profile:"Профиль",back:"Назад",close:"Закрыть",mathematics:"Математика",cambridge:"Cambridge AS Mathematics",
    examPrep:"Подготовка к экзамену",learningSyllabus:"Изучение syllabus",learningSyllabusSub:"Сначала подтверждаем покрытие syllabus, затем переходим к смешанным и временным заданиям.",
    upNext:"Следующий шаг",paper1:"Paper 1",paper5:"Paper 5",coverage:"Покрытие syllabus",evidence:"Подтверждение",building:"Формируется",starting:"Начало",confirmed:"Подтверждено",learning:"Изучается",needsRetest:"Нужна повторная проверка",timedEvidence:"Есть подтверждение на время",notStarted:"Не начато",inProgress:"В процессе",completed:"Завершено",next:"Далее",chainRule:"Практика Chain Rule",reprData:"Representation of Data",startPractice:"Начать практику",quickAccess:"Быстрый доступ",weeklyPlan:"План недели",syllabusProgress:"Прогресс syllabus",corrections:"Исправления и повторные проверки",timedHub:"Практика на время и Papers",
    setup:"Настройка подготовки",setupNeeded:"Сначала настройте подготовку, чтобы план учитывал ваш реальный режим.",setupSub:"Эти данные меняют темп и расписание, но не академические результаты.",examSeries:"Экзаменационная сессия / ориентир",weeklyMath:"Часов Mathematics в неделю",hours:"часов",experience:"Предыдущий опыт",studiedP1:"Изучал(а) части Paper 1",studiedP5:"Изучал(а) части Paper 5",fullP1:"Пробовал(а) полный Paper 1",fullP5:"Пробовал(а) полный Paper 5",goal:"Личная цель",saveSetup:"Сохранить настройку",setupSaved:"Настройка сохранена",
    placement:"Стартовая проверка",findStart:"Определим стартовую точку",placementIntro:"Paper 1 и Paper 5 проверяются отдельно: один компонент может двигаться дальше без зачёта результатов другого.",skills45:"45 навыков syllabus",skills36:"36 навыков syllabus",startPlacement:"Начать проверку",continuePlacement:"Продолжить",viewResult:"Посмотреть результат",separatePlacement:"Paper 1 и Paper 5 можно пройти отдельно.",foundationCheck:"Могут проверяться базовые навыки, но они не входят в покрытие P1/P5.",question:"Вопрос",of:"из",submitAnswer:"Отправить ответ",answerRecorded:"Ответ сохранён",nextQuestion:"Следующий вопрос",leaveSession:"Выйти из задания?",leaveSessionText:"Подтверждённые ответы сохраняются там, где режим допускает продолжение. Незавершённая работа не создаёт прогресс.",continueSession:"Продолжить",leave:"Выйти",assessmentProtected:"Подробные ответы скрыты во время защищённой проверки.",
    placementResult:"Результат стартовой проверки",startingPoint:"Стартовая точка",strongEvidence:"Уверенные области",needsAttention:"Требует внимания",recommendedFocus:"Первый рекомендуемый фокус",quadratics:"Квадратные выражения",basicFunctions:"Основы функций",coordinateGeometry:"Координатная геометрия",functions:"Функции",buildPlan:"Сформировать план",placementNotDone:"Проверка не завершена",completeOther:"Завершите этот компонент, чтобы определить его собственную стартовую точку.",foundationReview:"Базовая подготовка",foundationTwo:"2 базовые области требуют внимания.",foundationNoCredit:"Базовая работа не увеличивает покрытие Paper 1 или Paper 5.",moreEvidence:"Нужно больше данных",moreEvidenceText:"Нужно ещё немного подтверждений, прежде чем безопасно пропустить эту область.",continueCheck:"Продолжить проверку",
    foundationSkills:"Базовые навыки",foundationSkillsMeta:"Общая база • вне покрытия P1/P5",skills:"навыков",circular:"Круговая мера",trigonometry:"Тригонометрия",series:"Последовательности и ряды",differentiation:"Дифференцирование",integration:"Интегрирование",data:"Представление данных",counting:"Перестановки и сочетания",probability:"Вероятность",drv:"Дискретные случайные величины",normal:"Нормальное распределение",powers:"Дифференцирование степеней и простых функций",chainSkill:"Применение Chain Rule",stationary:"Нахождение стационарных точек",dataSkill:"Интерпретация cumulative-frequency данных",probSkill:"Условная вероятность",normalSkill:"Нормальное распределение",retest:"Повторная проверка",continue:"Продолжить",currentEvidence:"Текущее подтверждение",learn:"Изучить",practice:"Практика",mixedPractice:"Смешанная практика",resource:"Источник",evidenceJourney:"История подтверждений",initialCheck:"Первичная проверка",learningPractice:"Учебная практика",correction:"Исправление",delayedRetest:"Отложенная повторная проверка",mixedTimed:"Смешанное / временное подтверждение",latestIssue:"Последняя проблема",substitutionIssue:"Неверная подстановка внутренней функции",reviewCorrection:"Разобрать исправление",foundationRequirement:"Необходимая база",algebraConfirmed:"Алгебраические преобразования — подтверждено",
    thisWeek:"Эта неделя",actionsDone:"Выполнено 4 из 6 действий",primaryPriorities:"Главные приоритеты",dueToday:"Сегодня",conditionalProbability:"Условная вероятность",functionsMixed:"Смешанный набор по функциям",recoveryWeek:"Восстановительная неделя",recoveryText:"После перерыва объём временно снижен. Требования к подтверждениям не меняются.",lateJoiner:"Сфокусированная стартовая неделя",lateJoinerText:"План начинается с фактических данных, а не пропускает этапы из-за календаря.",normalWeek:"Обычная неделя",
    needsCorrection:"Нужно исправить",readyRetest:"Готово к повторной проверке",stable:"Подтверждено",quadraticIneq:"Квадратные неравенства",endpointIssue:"Неверная граница интервала",review:"Разобрать",conditionalProb:"Условная вероятность",availableNow:"Повторная проверка доступна",chainStable:"Chain Rule",retestPassed:"Повторная проверка пройдена",whatWrong:"Что было неверно",whyMatters:"Почему это важно",correctMethod:"Правильный метод",similarPractice:"Похожая практика",evidenceConfirmed:"Подтверждение получено",morePractice:"Нужно ещё потренироваться",
    timedSections:"Секция на время",mixedTimedSets:"Смешанный набор на время",fullPaper:"Полный Paper",purpose:"Цель",duration:"Время",firstTimed:"Отработать время на выбранной части",transfer:"Проверить перенос навыков в смешанных задачах",fullEvidence:"Получить полное Paper-подтверждение",start:"Начать",latest:"Последний сопоставимый результат",notEnough:"Пока недостаточно сопоставимых данных",paperInstructions:"Перед полным Paper",paperInstructionsText:"Попытка записывается отдельно по компоненту. Досрочный выход может сделать её несопоставимой.",beginPaper:"Начать полный Paper",paperSession:"Полный Paper",submitPaper:"Завершить Paper",paperResult:"Результат Paper",rawMark:"Балл",actualTime:"Фактическое время",inTimeMarks:"Баллы в официальном времени",unattempted:"Не выполнено баллов",lossCauses:"Главные причины потерь",reviewLosses:"Разобрать важные потери",appReadiness:"Оценка готовности iClub",onTrack:"По плану",risk:"Есть риск",readinessNote:"Это оценка iClub по данным, а не прогноз оценки Cambridge.",
    aiAssist:"AI Assist",whyNext:"Почему это следующий шаг",aiNextText:"Базовые навыки differentiation стабильны, а применение Chain Rule ещё нужно укрепить.",explainDifferent:"Объяснить иначе",explainMistake:"Объяснить мою ошибку",mentorCare:"Mentor Care",nextReview:"Следующая проверка: четверг",latestReview:"Последняя проверка",writtenSolution:"Paper 1 • письменное решение Chain Rule",reviewed:"Проверено",mentorText:"Показывайте шаг подстановки яснее перед упрощением.",viewFeedback:"Посмотреть комментарий",mentorReview:"Проверка наставника",mentorOnly:"Доступно только при активном назначении Mentor Care.",moreEvidenceNeeded:"Нужно больше данных",mcq:"Выбор ответа",learningMode:"Обучение",placementMode:"Стартовая проверка",retestMode:"Повторная проверка",timedMode:"Задание на время",paperMode:"Paper",answer:"Ответ",correctDemo:"Ответ подтверждён. Можно переходить к следующему учебному шагу.",incorrectDemo:"Эту попытку нужно исправить, прежде чем закрывать цикл подтверждения.",retestPass:"Повторная проверка подтверждена. Новые данные закрывают текущий цикл исправления.",retestReopen:"Нужно ещё потренироваться. Цикл исправления остаётся открытым.",preparationMenu:"Настройки подготовки",safePreview:"Синтетический preview • без Supabase • без production-записей"
  };

  const UZ = {
    home:"Bosh sahifa",study:"O‘qish",ratings:"Reyting",profile:"Profil",back:"Orqaga",close:"Yopish",mathematics:"Matematika",cambridge:"Cambridge AS Mathematics",
    examPrep:"Imtihonga tayyorgarlik",learningSyllabus:"Syllabusni o‘rganish",upNext:"Keyingi qadam",paper1:"Paper 1",paper5:"Paper 5",coverage:"Syllabus qamrovi",evidence:"Tasdiq",building:"Shakllanmoqda",starting:"Boshlanish",confirmed:"Tasdiqlandi",learning:"O‘rganilmoqda",needsRetest:"Qayta tekshiruv kerak",notStarted:"Boshlanmagan",completed:"Tugallangan",next:"Keyingi",startPractice:"Amaliyotni boshlash",quickAccess:"Tezkor kirish",weeklyPlan:"Haftalik reja",syllabusProgress:"Syllabus progressi",corrections:"Tuzatishlar va qayta tekshiruvlar",timedHub:"Vaqtli amaliyot va Papers",setup:"Tayyorgarlik sozlamalari",saveSetup:"Sozlamani saqlash",placement:"Boshlang‘ich tekshiruv",findStart:"Boshlang‘ich nuqtani aniqlash",startPlacement:"Tekshiruvni boshlash",continuePlacement:"Davom ettirish",viewResult:"Natijani ko‘rish",question:"Savol",of:"dan",submitAnswer:"Javobni yuborish",placementResult:"Boshlang‘ich tekshiruv natijasi",buildPlan:"Rejani tuzish",foundationSkills:"Asosiy ko‘nikmalar",skills:"ko‘nikma",thisWeek:"Bu hafta",normalWeek:"Oddiy hafta",recoveryWeek:"Tiklanish haftasi",lateJoiner:"Yo‘naltirilgan boshlang‘ich hafta",needsCorrection:"Tuzatish kerak",readyRetest:"Qayta tekshiruvga tayyor",stable:"Tasdiqlangan",retest:"Qayta tekshiruv",continue:"Davom etish",timedSections:"Vaqtli bo‘lim",mixedTimedSets:"Aralash vaqtli to‘plam",fullPaper:"To‘liq Paper",start:"Boshlash",paperInstructions:"To‘liq Paper oldidan",beginPaper:"To‘liq Paperni boshlash",paperResult:"Paper natijasi",appReadiness:"iClub tayyorgarlik bahosi",aiAssist:"AI Assist",mentorCare:"Mentor Care",mentorReview:"Mentor tekshiruvi",safePreview:"Sintetik preview • Supabasesiz • production yozuvlarisiz"
  };

  const dict = { en: EN, ru: {...EN, ...RU}, uz: {...EN, ...UZ} };
  const t = key => dict[state.lang][key] || EN[key] || key;
  const esc = value => String(value ?? "").replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));

  const ICONS = {
    back:"<path d='m15 18-6-6 6-6'/>", close:"<path d='m7 7 10 10M17 7 7 17'/>", home:"<path d='M3 10.5 12 3l9 7.5'/><path d='M5 9.5V21h14V9.5'/>",study:"<path d='m3 6 9-3 9 3-9 3-9-3Z'/><path d='M6 8v6c0 2 3 4 6 4s6-2 6-4V8'/>",ratings:"<path d='M4 20V10h4v10M10 20V4h4v16M16 20v-7h4v7'/>",profile:"<circle cx='12' cy='8' r='4'/><path d='M4 21c1-4 3.5-6 8-6s7 2 8 6'/>",practice:"<path d='M8 4h8M9 2h6v4H9zM6 4H5a2 2 0 0 0-2 2v15h18V6a2 2 0 0 0-2-2h-1'/>",repeat:"<path d='m17 2 4 4-4 4M3 11V9a3 3 0 0 1 3-3h15m-4 16 4-4-4-4M21 13v2a3 3 0 0 1-3 3H3'/>",timer:"<circle cx='12' cy='13' r='8'/><path d='M12 9v4l3 2M9 2h6'/>",calendar:"<path d='M4 5h16v16H4zM8 2v6M16 2v6M4 10h16'/>",book:"<path d='M4 5a3 3 0 0 1 3-2h5v17H7a3 3 0 0 0-3 2V5ZM20 5a3 3 0 0 0-3-2h-5v17h5a3 3 0 0 1 3 2V5Z'/>",chevron:"<path d='m9 18 6-6-6-6'/>",check:"<path d='m5 12 4 4 10-10'/>",edit:"<path d='M4 20h4l11-11-4-4L4 16v4Z'/>",sparkle:"<path d='m12 3 1.5 4.5L18 9l-4.5 1.5L12 15l-1.5-4.5L6 9l4.5-1.5L12 3Z'/>",mentor:"<circle cx='9' cy='8' r='3'/><path d='M3 20c.6-3.3 2.6-5 6-5 1.3 0 2.4.2 3.3.7'/><path d='m16 14 2 2 4-4'/>",warning:"<path d='M12 3 2 21h20L12 3ZM12 9v5M12 18h.01'/>",file:"<path d='M6 2h8l4 4v16H6zM14 2v5h5'/>",settings:"<circle cx='12' cy='12' r='3'/><path d='M12 2v3M12 19v3M4.9 4.9 7 7M17 17l2.1 2.1M2 12h3M19 12h3M4.9 19.1 7 17M17 7l2.1-2.1'/>",info:"<circle cx='12' cy='12' r='9'/><path d='M12 11v6M12 7h.01'/>",syllabus:"<path d='M4 4h16v16H4zM8 8h8M8 12h8M8 16h5'/>",corrections:"<path d='m4 17 5-5 4 4 7-8'/><path d='M20 12V8h-4'/>",papers:"<path d='M7 3h7l4 4v14H7zM14 3v5h5M10 13h5M10 17h5'/>",clipboard:"<path d='M8 4h8M9 2h6v4H9zM6 4H5a2 2 0 0 0-2 2v15h18V6a2 2 0 0 0-2-2h-1'/>",arrow:"<path d='M5 12h14m-5-5 5 5-5 5'/>",lock:"<rect x='5' y='10' width='14' height='10' rx='2'/><path d='M8 10V7a4 4 0 0 1 8 0v3'/>",graph:"<path d='M4 20h16M6 17l4-5 4 3 4-8'/>",bulb:"<path d='M9 18h6M10 22h4M8 14c-1.3-1-2-2.7-2-4.5A6 6 0 0 1 18 9.5c0 1.8-.7 3.5-2 4.5-.8.7-1 1.4-1 2H9c0-.6-.2-1.3-1-2Z'/>",
  };
  const icon = name => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[name] || ICONS.info}</svg>`;

  const P1_AREAS = [
    {id:"QUA",name:"quadratics",count:6,done:4,status:"confirmed",skills:["P1-QUA-01","P1-QUA-02","P1-QUA-03"]},
    {id:"FUN",name:"functions",count:8,done:5,status:"needsRetest",skills:["P1-FUN-01","P1-FUN-02","P1-FUN-03"]},
    {id:"COO",name:"coordinateGeometry",count:6,done:2,status:"learning",skills:["P1-COO-01","P1-COO-02"]},
    {id:"CIR",name:"circular",count:3,done:2,status:"confirmed",skills:["P1-CIR-01"]},
    {id:"TRI",name:"trigonometry",count:5,done:3,status:"learning",skills:["P1-TRI-01","P1-TRI-02"]},
    {id:"SER",name:"series",count:5,done:4,status:"confirmed",skills:["P1-SER-01","P1-SER-02"]},
    {id:"DIF",name:"differentiation",count:7,done:3,status:"needsRetest",skills:["P1-DIF-01","P1-DIF-02","P1-DIF-03"]},
    {id:"INT",name:"integration",count:5,done:1,status:"learning",skills:["P1-INT-01","P1-INT-02"]}
  ];
  const P5_AREAS = [
    {id:"DAT",name:"data",count:10,done:4,status:"learning",skills:["P5-DAT-01","P5-DAT-02","P5-DAT-03"]},
    {id:"CNT",name:"counting",count:5,done:1,status:"learning",skills:["P5-CNT-01","P5-CNT-02"]},
    {id:"PRO",name:"probability",count:6,done:2,status:"needsRetest",skills:["P5-PRO-01","P5-PRO-02","P5-PRO-03"]},
    {id:"DRV",name:"drv",count:9,done:0,status:"notStarted",skills:["P5-DRV-01","P5-GEO-01","P5-GEO-02","P5-GEO-03"]},
    {id:"NOR",name:"normal",count:6,done:0,status:"notStarted",skills:["P5-NOR-01","P5-NOR-02"]}
  ];

  const SKILLS = {
    "P1-DIF-01": {title:"powers",status:"confirmed",issue:null},
    "P1-DIF-02": {title:"chainSkill",status:"needsRetest",issue:"substitutionIssue"},
    "P1-DIF-03": {title:"stationary",status:"learning",issue:null},
    "P5-DAT-01": {title:"dataSkill",status:"confirmed",issue:null},
    "P5-PRO-01": {title:"probSkill",status:"needsRetest",issue:"morePractice"},
    "P5-NOR-01": {title:"normalSkill",status:"learning",issue:null}
  };

  const areasFor = comp => comp === "P1" ? P1_AREAS : P5_AREAS;
  const areaById = (comp,id) => areasFor(comp).find(x => x.id === id) || areasFor(comp)[0];
  const componentTitle = comp => comp === "P1" ? t("paper1") : t("paper5");
  const componentCourse = comp => comp === "P1" ? t("pure") : t("stats");
  const componentCoverage = comp => comp === "P1" ? 65 : 15;
  const componentEvidence = comp => comp === "P1" ? t("building") : t("starting");

  function pill(label,kind="blue") { return `<span class="v3-pill v3-pill--${kind}">${esc(label)}</span>`; }
  function progress(pct) { return `<div class="v3-progress"><span style="width:${Math.max(0,Math.min(100,pct))}%"></span></div>`; }
  function listRow(iconName,title,meta,screen,ctx="") { return `<button class="v3-list-row" type="button" data-screen="${screen}" ${ctx}><span class="v3-list-row__icon">${icon(iconName)}</span><span class="v3-list-row__copy"><span class="v3-list-row__title">${esc(title)}</span>${meta?`<span class="v3-list-row__meta">${esc(meta)}</span>`:""}</span><span class="v3-list-row__right">${icon("chevron")}</span></button>`; }

  function nav() {
    return `<nav class="v3-bottom-nav" aria-label="Primary navigation"><button class="v3-nav-btn" data-exit="home">${icon("home")}<span>${esc(t("home"))}</span></button><button class="v3-nav-btn is-active" data-exit="study">${icon("study")}<span>${esc(t("study"))}</span></button><button class="v3-nav-btn" data-exit="ratings">${icon("ratings")}<span>${esc(t("ratings"))}</span></button><button class="v3-nav-btn" data-exit="profile">${icon("profile")}<span>${esc(t("profile"))}</span></button></nav>`;
  }

  function topbar(title=t("mathematics"),subtitle=t("cambridge"),assessment=false) {
    return `<header class="v3-topbar" style="top:42px"><button class="v3-topbar__back" type="button" data-back aria-label="${esc(assessment?t("close"):t("back"))}">${icon(assessment?"close":"back")}</button><div><div class="v3-topbar__title">${esc(title)}</div>${subtitle?`<div class="v3-topbar__subtitle">${esc(subtitle)}</div>`:""}</div><div class="v3-topbar__spacer"></div></header>`;
  }

  function serviceBlock(context="next") {
    if (state.mode === "ai") return `<div class="v3-service"><div class="v3-service__head">${icon("sparkle")}<span>${esc(t("aiAssist"))}</span></div><div class="v3-service__title">${esc(t("whyNext"))}</div><div class="v3-service__text">${esc(t("aiNextText"))}</div><div class="v3-inline"><button class="v3-text-btn">${esc(t("explainDifferent"))}</button><button class="v3-text-btn">${esc(t("explainMistake"))}</button></div></div>`;
    if (state.mode === "mentor") return `<div class="v3-service v3-service--mentor"><div class="v3-service__head">${icon("mentor")}<span>${esc(t("mentorCare"))}</span></div><div class="v3-service__text">${esc(t("nextReview"))}</div><div class="v3-divider"></div><div class="v3-service__title">${esc(t("latestReview"))}</div><div class="v3-service__text"><strong>${esc(t("writtenSolution"))}</strong> · ${esc(t("reviewed"))}<br>${esc(t("mentorText"))}</div><button class="v3-text-btn" data-screen="mentor-review">${esc(t("viewFeedback"))}</button></div>`;
    return "";
  }

  function standardShell(body,{title=t("mathematics"),subtitle=t("cambridge"),assessment=false}={}) {
    return `<div class="epv3-shell">${topbar(title,subtitle,assessment)}<main class="epv3-main">${body}<div class="epv3-preview-note">${esc(t("safePreview"))}</div></main>${assessment?"":nav()}</div>`;
  }

  function paperCard(comp) {
    return `<article class="v3-paper-card"><div class="v3-paper-card__top"><div><div class="v3-paper-label">${esc(componentTitle(comp))}</div><div class="v3-paper-title">${esc(componentCourse(comp))}</div></div>${pill(componentEvidence(comp),"blue")}</div><div class="v3-space"></div><div class="v3-progress-row"><span>${esc(t("coverage"))}</span><strong>${componentCoverage(comp)}%</strong></div>${progress(componentCoverage(comp))}<div class="v3-paper-next">${esc(t("next"))}: <strong>${esc(comp==="P1"?t("chainRule"):t("reprData"))}</strong></div></article>`;
  }

  function overview() {
    const setupCallout = state.setupComplete ? "" : `<section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("setupNeeded"))}</div><div class="v3-card-subtitle">${esc(t("setupSub"))}</div><button class="v3-btn v3-btn--primary v3-btn--full" data-screen="setup">${esc(t("setup"))}</button></article></section>`;
    const body = `<div class="v3-page-head"><div class="v3-kicker">${esc(t("examPrep"))}</div><h1 class="v3-page-title">${esc(t("learningSyllabus"))}</h1><div class="v3-page-subtitle">${esc(t("learningSyllabusSub"))}</div></div>${setupCallout}<section class="v3-action-card"><div class="v3-section-head"><div class="v3-section-title">${esc(t("upNext"))}</div>${pill(t("paper1"),"blue")}</div><div class="v3-task-row"><div class="v3-task-icon">${icon("practice")}</div><div class="v3-task-copy"><div class="v3-task-title">${esc(t("chainRule"))}</div><div class="v3-task-meta">20 min</div></div></div>${state.mode==="ai"?serviceBlock():""}<button class="v3-btn v3-btn--primary v3-btn--full" data-screen="question-learning" data-component="P1" data-skill="P1-DIF-02">${esc(t("startPractice"))}</button></section>${state.mode==="mentor"?serviceBlock():""}<section class="v3-section"><div class="v3-paper-grid">${paperCard("P1")}${paperCard("P5")}</div></section><section class="v3-section"><div class="v3-section-head"><div class="v3-section-title">${esc(t("quickAccess"))}</div></div><div class="v3-list">${listRow("calendar",t("weeklyPlan"),t("actionsDone"),"weekly")}${listRow("syllabus",t("syllabusProgress"),"P1 45 • P5 36","syllabus")}${listRow("corrections",t("corrections"),t("needsRetest"),"corrections")}${listRow("timer",t("timedHub"),"P1 / P5","timed")}</div></section><div class="epv3-menu-link"><button data-screen="placement">${esc(t("placement"))}</button> · <button data-screen="setup">${esc(t("preparationMenu"))}</button>${state.mode==="mentor"?` · <button data-screen="mentor-review">${esc(t("mentorReview"))}</button>`:""}</div>`;
    return standardShell(body);
  }

  function setup() {
    const body = `<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("setup"))}</h1><div class="v3-page-subtitle">${esc(t("setupSub"))}</div></div><article class="v3-card"><div class="epv3-field"><label>${esc(t("examSeries"))}</label><select class="epv3-select"><option>May/June 2027</option><option>Oct/Nov 2027</option></select></div><div class="epv3-field"><label>${esc(t("weeklyMath"))}</label><select class="epv3-select"><option>4 ${esc(t("hours"))}</option><option selected>6 ${esc(t("hours"))}</option><option>8 ${esc(t("hours"))}</option></select></div><div class="epv3-field"><label>${esc(t("experience"))}</label><div class="epv3-check-grid"><label class="epv3-check"><input type="checkbox" checked> ${esc(t("studiedP1"))}</label><label class="epv3-check"><input type="checkbox"> ${esc(t("studiedP5"))}</label><label class="epv3-check"><input type="checkbox"> ${esc(t("fullP1"))}</label><label class="epv3-check"><input type="checkbox"> ${esc(t("fullP5"))}</label></div></div><div class="epv3-field"><label>${esc(t("goal"))}</label><select class="epv3-select"><option>A</option><option>A*</option><option>Complete syllabus confidently</option></select></div><button class="v3-btn v3-btn--primary v3-btn--full" data-save-setup>${esc(t("saveSetup"))}</button></article>`;
    return standardShell(body);
  }

  function placementHub() {
    const card = comp => { const status=state.placement[comp]; const action=status==="completed"?t("viewResult"):status==="inProgress"?t("continuePlacement"):t("startPlacement"); return `<article class="v3-card"><div class="v3-card-head"><div><div class="v3-paper-label">${esc(componentTitle(comp))}</div><div class="v3-card-title">${esc(componentCourse(comp))}</div><div class="v3-card-subtitle">${esc(comp==="P1"?t("skills45"):t("skills36"))}</div></div>${pill(t(status),status==="completed"?"green":"blue")}</div><button class="v3-btn ${status==="completed"?"":"v3-btn--primary"} v3-btn--full" data-screen="${status==="completed"?"placement-result":"placement-session"}" data-component="${comp}">${esc(action)}</button></article>`; };
    const body = `<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("findStart"))}</h1><div class="v3-page-subtitle">${esc(t("placementIntro"))}</div></div>${card("P1")}${card("P5")}<div class="epv3-safe" style="margin-top:12px">${esc(t("separatePlacement"))}<br>${esc(t("foundationCheck"))}</div>`;
    return standardShell(body);
  }

  function placementResult() {
    const comp=state.component; const other=comp==="P1"?"P5":"P1";
    const body = `<div class="v3-page-head"><div class="v3-kicker">${esc(componentTitle(comp))}</div><h1 class="v3-page-title">${esc(t("placementResult"))}</h1></div><section class="v3-card"><div class="v3-eyebrow">${esc(t("startingPoint"))}</div><div class="v3-card-title" style="margin-top:3px">${esc(t("learningSyllabus"))}</div><div class="v3-divider"></div><div class="epv3-split"><div class="epv3-stat"><div class="epv3-stat__label">${esc(t("strongEvidence"))}</div><div class="epv3-stat__value">${esc(comp==="P1"?t("quadratics"):t("data"))}</div><div class="v3-card-subtitle">${esc(comp==="P1"?t("basicFunctions"):t("counting"))}</div></div><div class="epv3-stat"><div class="epv3-stat__label">${esc(t("needsAttention"))}</div><div class="epv3-stat__value">${esc(comp==="P1"?t("coordinateGeometry"):t("probability"))}</div></div></div><div class="v3-divider"></div><div class="v3-eyebrow">${esc(t("recommendedFocus"))}</div><div class="v3-card-title" style="margin-top:3px">${esc(comp==="P1"?t("functions"):t("probability"))}</div><button class="v3-btn v3-btn--primary v3-btn--full" data-screen="weekly">${esc(t("buildPlan"))}</button></section><section class="v3-section"><article class="v3-card"><div class="v3-paper-label">${esc(componentTitle(other))}</div><div class="v3-card-title">${esc(state.placement[other]==="completed"?t("completed"):t("placementNotDone"))}</div><div class="v3-card-subtitle">${esc(state.placement[other]==="completed"?componentCourse(other):t("completeOther"))}</div>${state.placement[other]!=="completed"?`<button class="v3-btn v3-btn--full" data-screen="placement-session" data-component="${other}">${esc(t("startPlacement"))}</button>`:""}</article></section><section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("foundationReview"))}</div><div class="v3-card-subtitle">${esc(t("foundationTwo"))}</div><div class="epv3-note" style="margin-top:10px">${esc(t("foundationNoCredit"))}</div></article></section>`;
    return standardShell(body);
  }

  function componentSwitch() { return `<div class="epv3-component-switch"><button class="${state.component==="P1"?"is-active":""}" data-component-switch="P1">${esc(t("paper1"))}</button><button class="${state.component==="P5"?"is-active":""}" data-component-switch="P5">${esc(t("paper5"))}</button></div>`; }
  function statusPill(status){ if(status==="confirmed") return pill(t("confirmed"),"green"); if(status==="needsRetest") return pill(t("needsRetest"),"amber"); if(status==="notStarted") return `<span class="v3-pill">${esc(t("notStarted"))}</span>`; return pill(t("learning"),"blue"); }

  function syllabus() {
    const areas=areasFor(state.component); const total=state.component==="P1"?45:36;
    const rows=areas.map(a=>`<button class="epv3-area" type="button" data-screen="area" data-area="${a.id}" data-component="${state.component}"><div class="epv3-area__top"><div class="epv3-area__title">${esc(t(a.name))}</div><div class="epv3-area__count">${a.done} / ${a.count}</div></div><div class="epv3-area__bottom">${progress(Math.round(a.done/a.count*100))}${statusPill(a.status)}</div></button>`).join("");
    const body = `<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("syllabusProgress"))}</h1><div class="v3-page-subtitle">${total} ${esc(t("skills"))} • ${esc(componentTitle(state.component))}</div></div>${componentSwitch()}<div class="epv3-area-list">${rows}</div><section class="v3-section"><div class="v3-list">${listRow("book",t("foundationSkills"),t("foundationSkillsMeta"),"foundation")}</div></section>`;
    return standardShell(body);
  }

  function area() {
    const area=areaById(state.component,state.areaId);
    const skillRows=(area.skills.length?area.skills:[`${state.component}-${area.id}-01`]).map((code,i)=>{ const known=SKILLS[code]; const title=known?t(known.title):`${t(area.name)} • skill ${i+1}`; const status=known?known.status:(i===0?"confirmed":"learning"); return `<div class="epv3-skill"><div class="v3-list-row__icon">${icon(status==="confirmed"?"check":status==="needsRetest"?"repeat":"practice")}</div><div class="epv3-skill__copy"><div class="epv3-skill__title">${esc(title)}</div><div class="epv3-skill__meta">${esc(t(status))}</div></div><button class="v3-btn v3-btn--compact" data-screen="skill" data-skill="${code}" data-component="${state.component}" data-area="${area.id}">${esc(status==="needsRetest"?t("retest"):t("continue"))}</button></div>`; }).join("");
    const body = `<div class="epv3-breadcrumb"><span>${esc(componentTitle(state.component))}</span><span>›</span><strong>${esc(t(area.name))}</strong></div><div class="v3-page-head"><h1 class="v3-page-title">${esc(t(area.name))}</h1><div class="v3-page-subtitle">${area.done} / ${area.count} ${esc(t("confirmed"))}</div></div><div class="epv3-skill-list">${skillRows}</div>`;
    return standardShell(body);
  }

  function timelineRow(title,meta,kind){ return `<div class="epv3-timeline__row"><div class="epv3-timeline__dot ${kind}">${kind==="is-done"?icon("check"):kind==="is-current"?icon("repeat"):""}</div><div><div class="epv3-timeline__title">${esc(title)}</div><div class="epv3-timeline__meta">${esc(meta)}</div></div></div>`; }

  function skill() {
    const skill=SKILLS[state.skillId] || {title:state.component==="P1"?"chainSkill":"probSkill",status:"learning",issue:null};
    const primary=skill.status==="needsRetest"?"question-retest":"question-learning";
    const body = `<div class="epv3-breadcrumb"><span>${esc(componentTitle(state.component))}</span><span>›</span><span>${esc(t(areaById(state.component,state.areaId).name))}</span></div><div class="v3-page-head"><h1 class="v3-page-title">${esc(t(skill.title))}</h1><div class="v3-page-subtitle">${esc(t("currentEvidence"))}: ${esc(t(skill.status))}</div></div><section class="v3-action-card"><div class="v3-section-head"><div class="v3-section-title">${esc(t("upNext"))}</div>${statusPill(skill.status)}</div><div class="v3-card-title">${esc(skill.status==="needsRetest"?t("delayedRetest"):t("learningPractice"))}</div><button class="v3-btn v3-btn--primary v3-btn--full" data-screen="${primary}" data-component="${state.component}" data-skill="${state.skillId}">${esc(skill.status==="needsRetest"?t("retest"):t("practice"))}</button></section><section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("resource"))}</div><div class="v3-card-subtitle">${esc(state.component==="P1"?"Complete Pure Mathematics 1":"Complete Probability & Statistics 1")}</div><button class="v3-text-btn">${esc(t("learn"))}</button></article></section><section class="v3-section"><div class="v3-section-title">${esc(t("evidenceJourney"))}</div><div class="v3-card"><div class="epv3-timeline">${timelineRow(t("initialCheck"),t("completed"),"is-done")}${timelineRow(t("learningPractice"),t("completed"),"is-done")}${timelineRow(t("correction"),skill.issue?t("completed"):t("notStarted"),skill.issue?"is-done":"")}${timelineRow(t("delayedRetest"),skill.status==="needsRetest"?t("needsRetest"):t("notStarted"),skill.status==="needsRetest"?"is-current":"")}${timelineRow(t("mixedTimed"),t("notStarted"),"")}</div></div></section>${skill.issue?`<section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("latestIssue"))}</div><div class="v3-card-subtitle">${esc(t(skill.issue))}</div><button class="v3-text-btn" data-screen="correction-detail">${esc(t("reviewCorrection"))}</button></article></section>`:""}<section class="v3-section"><div class="epv3-note">${esc(t("foundationRequirement"))}: <strong>${esc(t("algebraConfirmed"))}</strong></div></section>${state.mode!=="core"?serviceBlock():""}`;
    return standardShell(body);
  }

  function priority(num,comp,type,title,mins,reason,screen,skill="") { return `<div class="epv3-priority"><div class="epv3-priority__num">${num}</div><div class="epv3-priority__copy"><div class="epv3-priority__title">${esc(componentTitle(comp))} • ${esc(type)}<br>${esc(title)}</div><div class="epv3-priority__meta">${esc(mins)}${reason?` • ${esc(reason)}`:""}</div></div><button class="v3-btn v3-btn--compact epv3-priority__action" data-screen="${screen}" data-component="${comp}" ${skill?`data-skill="${skill}"`:""}>${esc(num===1?t("start"):t("continue"))}</button></div>`; }

  function weekly() {
    const modeCopy = state.weeklyMode==="recovery"?`<div class="epv3-safe"><strong>${esc(t("recoveryWeek"))}</strong><br>${esc(t("recoveryText"))}</div>`:state.weeklyMode==="late"?`<div class="epv3-safe"><strong>${esc(t("lateJoiner"))}</strong><br>${esc(t("lateJoinerText"))}</div>`:"";
    const body = `<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("thisWeek"))}</h1><div class="v3-page-subtitle">${esc(t("actionsDone"))}</div></div><div class="epv3-mini-tabs"><button class="${state.weeklyMode==="normal"?"is-active":""}" data-week-mode="normal">${esc(t("normalWeek"))}</button><button class="${state.weeklyMode==="recovery"?"is-active":""}" data-week-mode="recovery">${esc(t("recoveryWeek"))}</button><button class="${state.weeklyMode==="late"?"is-active":""}" data-week-mode="late">${esc(t("lateJoiner"))}</button></div>${modeCopy}<div class="v3-card" style="margin-top:12px"><div class="v3-progress-row"><span>${esc(t("weeklyPlan"))}</span><strong>4 / 6</strong></div>${progress(67)}</div><section class="v3-section"><div class="v3-section-title">${esc(t("primaryPriorities"))}</div>${priority(1,"P1",t("retest"),t("chainSkill"),"15 min",t("dueToday"),"question-retest","P1-DIF-02")}${priority(2,"P5",t("learn"),t("conditionalProbability"),"25 min","","skill","P5-PRO-01")}${priority(3,"P1",t("mixedPractice"),t("functionsMixed"),"30 min","","question-learning","P1-FUN-02")}</section>${state.mode!=="core"?serviceBlock():""}`;
    return standardShell(body);
  }

  function corrections() {
    const item=(comp,title,meta,action,screen,kind="amber",skill="")=>`<div class="epv3-skill"><div class="v3-list-row__icon">${icon(kind==="green"?"check":"repeat")}</div><div class="epv3-skill__copy"><div class="epv3-skill__title">${esc(comp)} • ${esc(title)}</div><div class="epv3-skill__meta">${esc(meta)}</div></div>${screen?`<button class="v3-btn v3-btn--compact" data-screen="${screen}" data-component="${comp}" ${skill?`data-skill="${skill}"`:""}>${esc(action)}</button>`:pill(action,kind)}</div>`;
    const body = `<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("corrections"))}</h1></div><div class="v3-tabs"><button class="v3-tab is-active">All</button><button class="v3-tab">P1</button><button class="v3-tab">P5</button></div><div class="epv3-correction-group"><div class="epv3-correction-group__title">${esc(t("needsCorrection"))}</div>${item("P1",t("quadraticIneq"),t("endpointIssue"),t("review"),"correction-detail","amber","P1-QUA-03")}</div><div class="epv3-correction-group"><div class="epv3-correction-group__title">${esc(t("readyRetest"))}</div>${item("P5",t("conditionalProb"),t("availableNow"),t("retest"),"question-retest","amber","P5-PRO-01")}</div><div class="epv3-correction-group"><div class="epv3-correction-group__title">${esc(t("stable"))}</div>${item("P1",t("chainStable"),t("retestPassed"),t("confirmed"),null,"green")}</div>`;
    return standardShell(body);
  }

  function correctionDetail() {
    const steps=[["whatWrong","endpointIssue"],["whyMatters","quadraticIneq"],["correctMethod","functions"],["similarPractice","practice"],["delayedRetest","readyRetest"],["evidenceConfirmed","notStarted"]];
    const body = `<div class="v3-page-head"><div class="v3-kicker">${esc(componentTitle(state.component))}</div><h1 class="v3-page-title">${esc(t("quadraticIneq"))}</h1><div class="v3-page-subtitle">${esc(t("correction"))}</div></div><div class="v3-card"><div class="epv3-timeline">${steps.map((s,i)=>timelineRow(t(s[0]),t(s[1]),i<3?"is-done":i===3?"is-current":"")).join("")}</div></div>${state.mode==="ai"?serviceBlock():""}<button class="v3-btn v3-btn--primary v3-btn--full" data-screen="question-learning" data-component="${state.component}" data-skill="${state.skillId}">${esc(t("similarPractice"))}</button>`;
    return standardShell(body);
  }

  function timed() {
    const body = `<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("timedHub"))}</h1></div>${componentSwitch()}<div class="v3-list">${listRow("timer",t("timedSections"),`${t("purpose")}: ${t("firstTimed")} • 25 min`,"timed-session",`data-session-type="timed" data-component="${state.component}"`)}${listRow("practice",t("mixedTimedSets"),`${t("purpose")}: ${t("transfer")} • 35 min`,"timed-session",`data-session-type="mixed" data-component="${state.component}"`)}${listRow("file",t("fullPaper"),`${t("duration")}: ${state.component==="P1"?"1 h 50 min":"1 h 15 min"}`,"paper-instructions",`data-component="${state.component}"`)}</div><section class="v3-section"><div class="epv3-note">${esc(t("latest"))}: ${esc(t("notEnough"))}</div></section>`;
    return standardShell(body);
  }

  function paperInstructions() {
    const body = `<div class="v3-page-head"><div class="v3-kicker">${esc(componentTitle(state.component))}</div><h1 class="v3-page-title">${esc(t("paperInstructions"))}</h1><div class="v3-page-subtitle">${esc(componentCourse(state.component))}</div></div><article class="v3-card"><div class="v3-card-title">${esc(t("fullPaper"))}</div><div class="v3-card-subtitle">${esc(t("paperInstructionsText"))}</div><div class="epv3-divider-line"></div><div class="v3-progress-row"><span>${esc(t("duration"))}</span><strong>${state.component==="P1"?"1 h 50 min":"1 h 15 min"}</strong></div><button class="v3-btn v3-btn--primary v3-btn--full" data-screen="paper-session" data-component="${state.component}">${esc(t("beginPaper"))}</button></article>`;
    return standardShell(body);
  }

  function paperResult() {
    const max=state.component==="P1"?75:50; const raw=state.component==="P1"?54:36; const intime=state.component==="P1"?50:33; const unattempted=state.component==="P1"?6:4;
    const body = `<div class="v3-page-head"><div class="v3-kicker">${esc(componentTitle(state.component))}</div><h1 class="v3-page-title">${esc(t("paperResult"))}</h1></div><div class="epv3-result-grid"><div class="epv3-result-metric"><div class="epv3-result-metric__label">${esc(t("rawMark"))}</div><div class="epv3-result-metric__value">${raw} / ${max}</div></div><div class="epv3-result-metric"><div class="epv3-result-metric__label">${esc(t("actualTime"))}</div><div class="epv3-result-metric__value">${state.component==="P1"?"1 h 52 min":"1 h 16 min"}</div></div><div class="epv3-result-metric"><div class="epv3-result-metric__label">${esc(t("inTimeMarks"))}</div><div class="epv3-result-metric__value">${intime}</div></div><div class="epv3-result-metric"><div class="epv3-result-metric__label">${esc(t("unattempted"))}</div><div class="epv3-result-metric__value">${unattempted}</div></div></div><section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("lossCauses"))}</div><ul class="epv3-loss-list"><li>${esc(state.component==="P1"?"Chain Rule transfer":"Conditional probability setup")}</li><li>${esc(state.component==="P1"?"Coordinate geometry accuracy":"Normal-distribution interpretation")}</li><li>${esc("Timing in final section")}</li></ul><button class="v3-btn v3-btn--primary v3-btn--full" data-screen="corrections">${esc(t("reviewLosses"))}</button></article></section><section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("appReadiness"))} · ${esc(componentTitle(state.component))}</div><div class="v3-card-subtitle">${esc(state.component==="P1"?t("onTrack"):t("risk"))}</div><div class="epv3-note" style="margin-top:10px">${esc(t("readinessNote"))}</div></article></section>${state.mode==="mentor"?`<section class="v3-section"><button class="v3-list-row" data-screen="mentor-review"><span class="v3-list-row__icon">${icon("mentor")}</span><span class="v3-list-row__copy"><span class="v3-list-row__title">${esc(t("mentorReview"))}</span><span class="v3-list-row__meta">${esc(t("moreEvidenceNeeded"))}</span></span><span class="v3-list-row__right">${icon("chevron")}</span></button></section>`:""}`;
    return standardShell(body);
  }

  function mentorReview() {
    const body = state.mode!=="mentor" ? `<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("mentorReview"))}</h1></div><div class="epv3-warning">${esc(t("mentorOnly"))}</div>` : `<div class="v3-page-head"><div class="v3-kicker">${esc(componentTitle(state.component))}</div><h1 class="v3-page-title">${esc(t("mentorReview"))}</h1></div>${serviceBlock()}<section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("appReadiness"))} · ${esc(componentTitle(state.component))}</div><div class="v3-card-subtitle">${esc(t("moreEvidenceNeeded"))}</div><div class="epv3-note" style="margin-top:10px">${esc(t("readinessNote"))}</div></article></section>`;
    return standardShell(body);
  }

  function foundation() {
    const body = `<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("foundationSkills"))}</h1><div class="v3-page-subtitle">${esc(t("foundationSkillsMeta"))}</div></div><div class="v3-list">${listRow("check","Algebraic manipulation",t("confirmed"),"overview")}${listRow("check","Equations",t("confirmed"),"overview")}${listRow("repeat","Graphs",t("needsRetest"),"overview")}${listRow("book","Calculator basics",t("learning"),"overview")}</div><div class="epv3-note" style="margin-top:12px">${esc(t("foundationNoCredit"))}</div>`;
    return standardShell(body);
  }

  function beginSession(kind,comp,total=4) {
    state.component=comp || state.component;
    state.session={kind,step:1,total,answers:[],startedAt:Date.now()};
    state.selectedOption=null;
    state.feedback=null;
    if(kind==="placement") state.placement[state.component]="inProgress";
  }

  function sessionQuestion(kind) {
    if(!state.session || state.session.kind!==kind) beginSession(kind,state.component,kind==="paper"?6:4);
    const s=state.session; const protectedMode=["placement","timed","paper"].includes(kind); const retest=kind==="retest"; const learning=kind==="learning";
    const modeLabel=kind==="placement"?t("placementMode"):kind==="timed"?t("timedMode"):kind==="paper"?t("paperMode"):kind==="retest"?t("retestMode"):t("learningMode");
    const qText = state.component==="P1" ? "For f(x) = x² − 6x + 11, find the coordinates of the vertex." : "A and B are events with P(A)=0.6 and P(A∩B)=0.24. Find P(B|A).";
    const opts = state.component==="P1" ? ["(3, 2)","(−3, 2)","(3, 11)","(6, 2)"] : ["0.40","0.24","0.60","0.84"];
    const feedback = state.feedback ? `<div class="epv3-question-feedback ${state.feedback.kind==='good'?'is-good':'is-attn'}"><strong>${esc(state.feedback.title)}</strong><div style="margin-top:4px">${esc(state.feedback.text)}</div></div>` : "";
    return `<div class="epv3-question-shell"><div class="epv3-question-head"><button class="v3-topbar__back" type="button" data-back aria-label="${esc(t("close"))}">${icon("close")}</button><div class="epv3-question-head__copy"><div class="epv3-question-head__title">${esc(componentTitle(state.component))} • ${esc(modeLabel)}</div><div class="epv3-question-head__meta">${esc(t("question"))} ${s.step} ${esc(t("of"))} ${s.total}</div></div>${["timed","paper"].includes(kind)?pill(kind==="paper"?"1:42:18":"18:42","blue"):""}</div><div class="epv3-question-progress"><span style="width:${Math.round((s.step-1)/s.total*100)}%"></span></div><main class="epv3-question-body"><div class="epv3-question-kicker">${esc(t("mcq"))}</div><div class="epv3-question-text">${esc(qText)}</div><div class="epv3-options">${opts.map((x,i)=>`<button class="epv3-option${state.selectedOption===i?" is-selected":""}" type="button" data-option="${i}" ${state.feedback?"disabled":""}><span class="epv3-option__letter">${String.fromCharCode(65+i)}</span><span class="epv3-option__text">${esc(x)}</span></button>`).join("")}</div>${protectedMode?`<div class="epv3-note" style="margin-top:18px">${esc(t("assessmentProtected"))}</div>`:""}${feedback}</main><footer class="epv3-question-footer">${state.feedback?`<button class="v3-btn v3-btn--primary v3-btn--full" data-next-after-feedback>${esc(t("continue"))}</button>`:`<button class="v3-btn v3-btn--primary v3-btn--full" data-submit-session="${kind}" ${state.selectedOption===null?"disabled":""}>${esc(t("submitAnswer"))}</button>`}</footer></div>`;
  }

  function renderScreen() {
    switch(state.screen) {
      case "overview": return overview();
      case "setup": return setup();
      case "placement": return placementHub();
      case "placement-result": return placementResult();
      case "syllabus": return syllabus();
      case "area": return area();
      case "skill": return skill();
      case "weekly": return weekly();
      case "corrections": return corrections();
      case "correction-detail": return correctionDetail();
      case "timed": return timed();
      case "paper-instructions": return paperInstructions();
      case "paper-result": return paperResult();
      case "mentor-review": return mentorReview();
      case "foundation": return foundation();
      case "placement-session": return sessionQuestion("placement");
      case "question-learning": return sessionQuestion("learning");
      case "question-retest": return sessionQuestion("retest");
      case "timed-session": return sessionQuestion(state.session?.kind==="mixed"?"timed":"timed");
      case "paper-session": return sessionQuestion("paper");
      default: return overview();
    }
  }

  function pushScreen(screen,ctx={}) {
    if(state.screen!==screen) state.stack.push({screen:state.screen,component:state.component,areaId:state.areaId,skillId:state.skillId});
    if(ctx.component) state.component=ctx.component;
    if(ctx.areaId) state.areaId=ctx.areaId;
    if(ctx.skillId) state.skillId=ctx.skillId;
    state.screen=screen;
    state.selectedOption=null;
    state.feedback=null;
    if(["placement-session","question-learning","question-retest","timed-session","paper-session"].includes(screen)) {
      const kind=screen==="placement-session"?"placement":screen==="question-learning"?"learning":screen==="question-retest"?"retest":screen==="paper-session"?"paper":ctx.sessionType||"timed";
      beginSession(kind,state.component,kind==="paper"?6:4);
    }
    render();
  }

  function back() {
    if(state.screen==="overview") { window.location.href="ui-v3-preview.html"; return; }
    const prev=state.stack.pop();
    if(prev){ state.screen=prev.screen; state.component=prev.component; state.areaId=prev.areaId; state.skillId=prev.skillId; state.session=null; state.selectedOption=null; state.feedback=null; render(); return; }
    state.screen="overview"; state.session=null; render();
  }

  function finalizeSession(kind) {
    const s=state.session;
    if(!s) return;
    if(kind==="placement") {
      if(s.step < s.total) { s.answers.push(state.selectedOption); s.step += 1; state.selectedOption=null; state.feedback=null; render(); return; }
      s.answers.push(state.selectedOption); state.placement[state.component]="completed"; state.session=null; state.screen="placement-result"; render(); return;
    }
    if(kind==="timed") {
      if(s.step < s.total) { s.answers.push(state.selectedOption); s.step += 1; state.selectedOption=null; render(); return; }
      state.session=null; state.screen="paper-result"; render(); return;
    }
    if(kind==="paper") {
      if(s.step < s.total) { s.answers.push(state.selectedOption); s.step += 1; state.selectedOption=null; render(); return; }
      state.session=null; state.screen="paper-result"; render(); return;
    }
    if(kind==="learning") {
      state.feedback={kind:"attn",title:t("correction"),text:t("incorrectDemo")}; render(); return;
    }
    if(kind==="retest") {
      state.feedback={kind:"good",title:t("confirmed"),text:t("retestPass")}; render(); return;
    }
  }

  function afterFeedback() {
    const kind=state.session?.kind;
    if(kind==="learning") { state.session=null; state.screen="corrections"; state.feedback=null; render(); return; }
    if(kind==="retest") { state.session=null; state.screen="skill"; state.feedback=null; render(); return; }
  }

  function bind() {
    root.querySelectorAll("[data-screen]").forEach(el=>el.addEventListener("click",()=>pushScreen(el.dataset.screen,{component:el.dataset.component,areaId:el.dataset.area,skillId:el.dataset.skill,sessionType:el.dataset.sessionType})));
    root.querySelectorAll("[data-back]").forEach(el=>el.addEventListener("click",back));
    root.querySelectorAll("[data-exit]").forEach(el=>el.addEventListener("click",()=>{ window.location.href="ui-v3-preview.html"; }));
    root.querySelectorAll("[data-component-switch]").forEach(el=>el.addEventListener("click",()=>{ state.component=el.dataset.componentSwitch; const first=areasFor(state.component)[0]; state.areaId=first.id; state.skillId=first.skills[0] || `${state.component}-${first.id}-01`; render(); }));
    root.querySelectorAll("[data-week-mode]").forEach(el=>el.addEventListener("click",()=>{ state.weeklyMode=el.dataset.weekMode; render(); }));
    root.querySelectorAll("[data-save-setup]").forEach(el=>el.addEventListener("click",()=>{ state.setupComplete=true; state.screen="overview"; state.stack=[]; render(); }));
    root.querySelectorAll("[data-option]").forEach(el=>el.addEventListener("click",()=>{ state.selectedOption=Number(el.dataset.option); root.querySelectorAll("[data-option]").forEach(x=>x.classList.toggle("is-selected",Number(x.dataset.option)===state.selectedOption)); const submit=root.querySelector("[data-submit-session]"); if(submit) submit.disabled=false; }));
    root.querySelectorAll("[data-submit-session]").forEach(el=>el.addEventListener("click",()=>finalizeSession(el.dataset.submitSession)));
    root.querySelectorAll("[data-next-after-feedback]").forEach(el=>el.addEventListener("click",afterFeedback));
  }

  function render() {
    root.innerHTML=renderScreen();
    bind();
    window.scrollTo({top:0,behavior:"instant"});
  }

  function selfTest() {
    const failures=[]; const ok=(v,m)=>{if(!v)failures.push(m);};
    ok(P1_AREAS.reduce((a,x)=>a+x.count,0)===45,"P1 denominator must be 45");
    ok(P5_AREAS.reduce((a,x)=>a+x.count,0)===36,"P5 denominator must be 36");
    ok(P5_AREAS.some(x=>x.id==="DRV"&&x.count===9&&x.skills.includes("P5-GEO-01")&&x.skills.includes("P5-GEO-03")),"P5 DRV/BIN/GEO must retain geometric distribution");
    ok(typeof setup==="function","EP-01 Preparation Setup must exist");
    ok(typeof paperInstructions==="function" && typeof sessionQuestion==="function" && typeof paperResult==="function","Full paper must have instructions → session → result");
    ok(["normal","recovery","late"].includes(state.weeklyMode),"Weekly state must be mutually exclusive");
    ok(areaById("P1","DIF").id==="DIF" && areaById("P5","PRO").id==="PRO","Area routing must respect component context");
    ok(!document.documentElement.innerHTML.includes("correct_answer"),"No answer-key field may appear in preview");
    ok(!document.documentElement.innerHTML.toLowerCase().includes("supabase"),"Preview must have no Supabase dependency");
    ok(["core","ai","mentor"].includes(state.mode),"Service mode must remain isolated");
    if(failures.length){ console.error("Exam Prep final logic self-test failed",failures); return false; }
    console.info("Exam Prep final logic self-test passed",{p1:45,p5:36,ep01:true,paperFlow:true,serviceModes:3});
    return true;
  }

  modeSelect.addEventListener("change",()=>{ state.mode=modeSelect.value; render(); });
  langSelect.addEventListener("change",()=>{ state.lang=langSelect.value; render(); });
  selfTest();
  render();
})();