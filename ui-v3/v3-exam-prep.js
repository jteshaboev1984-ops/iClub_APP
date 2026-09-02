(() => {
  "use strict";

  const root = document.getElementById("epv3-root");
  const modeSelect = document.getElementById("epv3-mode");
  const langSelect = document.getElementById("epv3-lang");

  const state = {
    screen: "overview",
    component: "P1",
    mode: "core",
    lang: "en",
    selectedOption: null,
    placementStep: 4,
    questionMode: "placement"
  };

  const copy = {
    en: {
      home:"Home",study:"Study",ratings:"Ratings",profile:"Profile",mathematics:"Mathematics",cambridge:"Cambridge AS Mathematics",
      examPrep:"Exam preparation",learningSyllabus:"Learning the syllabus",learningSyllabusSub:"Building syllabus coverage before entering the revision phase.",
      upNext:"Up next",paper1:"Paper 1",paper5:"Paper 5",pure:"Pure Mathematics 1",stats:"Probability & Statistics 1",coverage:"Syllabus coverage",evidence:"Evidence",building:"Building",starting:"Starting",next:"Next",
      chainRule:"Chain Rule practice",reprData:"Representation of Data",startPractice:"Start practice",quickAccess:"Quick access",syllabusProgress:"Syllabus progress",corrections:"Corrections & retests",timedPractice:"Timed practice",papers:"Papers",
      placement:"Placement",findStart:"Find your starting point",placementIntro:"We’ll check what you already know so your plan starts at the right level.",skills45:"45 syllabus skills",skills36:"36 syllabus skills",notStarted:"Not started",inProgress:"In progress",completed:"Completed",startPlacement:"Start placement",continuePlacement:"Continue placement",viewResult:"View result",separatePlacement:"You can complete Paper 1 and Paper 5 separately.",foundationCheck:"Some foundation skills may be checked before your starting point is confirmed.",
      question:"Question",of:"of",submitAnswer:"Submit answer",answerRecorded:"Answer recorded",nextQuestion:"Next question",leavePlacement:"Leave placement?",leavePlacementText:"Your confirmed answers are saved. You can continue later.",continuePlacementBtn:"Continue placement",leave:"Leave",connectionLost:"Connection lost",waitingConnection:"Your answer will be confirmed when the connection returns.",
      placementResult:"Placement result",startingPoint:"Starting point",strongEvidence:"Strong evidence",needsAttention:"Needs attention",recommendedFocus:"Recommended first focus",quadratics:"Quadratics",basicFunctions:"Basic functions",coordinateGeometry:"Coordinate geometry",functions:"Functions",buildPlan:"Build my plan",placementNotDone:"Placement not completed",completeP5:"Complete Paper 5 placement to set its starting point.",startP5:"Start Paper 5",foundationReview:"Foundation review",foundationTwo:"2 foundation areas need attention.",foundationNoCredit:"These do not count toward Paper 1 or Paper 5 syllabus coverage.",moreEvidence:"More evidence needed",moreEvidenceText:"We need a little more evidence before safely skipping this area.",continueCheck:"Continue check",
      syllabus:"Syllabus progress",foundationSkills:"Foundation skills",foundationSkillsMeta:"Shared foundations • outside P1/P5 coverage",confirmed:"Confirmed",needsRetest:"Needs retest",timedEvidence:"Timed evidence",learning:"Learning",skills:"skills",
      circular:"Circular measure",trigonometry:"Trigonometry",series:"Series",differentiation:"Differentiation",integration:"Integration",data:"Representation of data",counting:"Permutations & combinations",probability:"Probability",drv:"Discrete random variables",normal:"Normal distribution",
      differentiationArea:"Differentiation",powers:"Differentiate powers and simple functions",chainSkill:"Applying the chain rule",stationary:"Using derivatives to find stationary points",retest:"Retest",continue:"Continue",skillDetail:"Skill detail",currentEvidence:"Current evidence",learn:"Learn",practice:"Practice",mixedPractice:"Try mixed practice",resource:"Resource",evidenceJourney:"Evidence journey",initialCheck:"Initial check",learningPractice:"Learning practice",correction:"Correction",delayedRetest:"Delayed retest",mixedTimed:"Mixed / timed evidence",latestIssue:"Latest issue",substitutionIssue:"Incorrect substitution in the inner function",reviewCorrection:"Review correction",foundationRequirement:"Foundation requirement",algebraConfirmed:"Algebraic manipulation — confirmed",
      weeklyPlan:"Weekly plan",thisWeek:"This week",actionsDone:"4 of 6 actions completed",primaryPriorities:"Main priorities",dueToday:"Due today",conditionalProbability:"Conditional probability",functionsMixed:"Functions mixed set",whyTask:"Why this task",retestDue:"Retest due",recoveryWeek:"Recovery week",recoveryText:"This week is lighter after an interruption. Evidence requirements stay the same.",lateJoiner:"Focused starting week",lateJoinerText:"The plan prioritizes the safest high-impact starting work instead of skipping by calendar date.",
      needsCorrection:"Needs correction",readyRetest:"Ready for retest",stable:"Stable",quadraticIneq:"Quadratic inequalities",endpointIssue:"Incorrect interval endpoint",review:"Review correction",conditionalProb:"Conditional probability",availableNow:"Retest available now",chainStable:"Chain rule",retestPassed:"Delayed retest passed",whatWrong:"What went wrong",whyMatters:"Why it matters",correctMethod:"Correct method",similarPractice:"Similar practice",evidenceConfirmed:"Evidence confirmed",morePractice:"More practice needed",
      timedHub:"Timed practice & papers",timedSections:"Timed sections",mixedTimedSets:"Mixed timed sets",fullPaper:"Full-paper practice",purpose:"Purpose",duration:"Duration",latest:"Latest comparable result",firstTimed:"Build timing on a focused section",transfer:"Test transfer across mixed skills",fullEvidence:"Collect full-paper evidence",start:"Start",notEnough:"Not enough evidence yet",paperResult:"Paper result",rawMark:"Raw mark",actualTime:"Actual time",inTimeMarks:"Marks earned in time",unattempted:"Unattempted marks",lossCauses:"Main loss causes",reviewLosses:"Review 3 important losses",appReadiness:"App readiness estimate",onTrack:"On track",strongObjective:"Strong objective evidence",risk:"At risk",mentorReview:"Mentor review",moreEvidenceNeeded:"More evidence needed",
      aiAssist:"AI Assist",whyNext:"Why this is next",aiNextText:"Your basic differentiation evidence is stable, while Chain Rule transfer still needs reinforcement.",explainDifferent:"Explain this differently",explainMistake:"Explain my mistake",mentorCare:"Mentor Care",nextReview:"Next review: Thursday",latestReview:"Latest review",writtenSolution:"Paper 1 • Chain Rule written solution",reviewed:"Reviewed",mentorText:"Show the substitution step clearly before simplifying.",viewFeedback:"View feedback",
      overview:"Overview",weekly:"Weekly plan",close:"Close",back:"Back",mcq:"MCQ",numeric:"Numeric input",shortInput:"Short mathematical input",diagram:"Diagram question",placementMode:"Placement",learningMode:"Learning",retestMode:"Retest",timedMode:"Timed assessment",answer:"Answer",enterAnswer:"Enter answer",submit:"Submit",assessmentProtected:"Detailed answer feedback stays hidden during protected assessment.",
      safePreview:"Static synthetic preview • no Supabase access • no production data"
    },
    ru: {
      home:"Главная",study:"Учёба",ratings:"Рейтинг",profile:"Профиль",mathematics:"Математика",cambridge:"Cambridge AS Mathematics",
      examPrep:"Подготовка к экзамену",learningSyllabus:"Изучение syllabus",learningSyllabusSub:"Сейчас основная задача — уверенно закрывать syllabus до этапа повторения.",
      upNext:"Следующий шаг",paper1:"Paper 1",paper5:"Paper 5",pure:"Pure Mathematics 1",stats:"Probability & Statistics 1",coverage:"Покрытие syllabus",evidence:"Подтверждение",building:"Формируется",starting:"Начало",next:"Далее",
      chainRule:"Практика Chain Rule",reprData:"Representation of Data",startPractice:"Начать практику",quickAccess:"Быстрый доступ",syllabusProgress:"Прогресс syllabus",corrections:"Исправления и повторные проверки",timedPractice:"Практика на время",papers:"Papers",
      placement:"Стартовая проверка",findStart:"Определим стартовую точку",placementIntro:"Проверим, что уже уверенно получается, чтобы план начался с подходящего уровня.",skills45:"45 навыков syllabus",skills36:"36 навыков syllabus",notStarted:"Не начато",inProgress:"В процессе",completed:"Завершено",startPlacement:"Начать проверку",continuePlacement:"Продолжить проверку",viewResult:"Посмотреть результат",separatePlacement:"Paper 1 и Paper 5 можно пройти отдельно.",foundationCheck:"Перед подтверждением стартовой точки могут проверяться базовые навыки.",
      question:"Вопрос",of:"из",submitAnswer:"Отправить ответ",answerRecorded:"Ответ сохранён",nextQuestion:"Следующий вопрос",leavePlacement:"Выйти из проверки?",leavePlacementText:"Подтверждённые ответы сохранены. Можно продолжить позже.",continuePlacementBtn:"Продолжить",leave:"Выйти",connectionLost:"Нет соединения",waitingConnection:"Ответ будет подтверждён после восстановления соединения.",
      placementResult:"Результат стартовой проверки",startingPoint:"Стартовая точка",strongEvidence:"Уверенные области",needsAttention:"Требует внимания",recommendedFocus:"Первый рекомендуемый фокус",quadratics:"Квадратные выражения",basicFunctions:"Основы функций",coordinateGeometry:"Координатная геометрия",functions:"Функции",buildPlan:"Сформировать план",placementNotDone:"Проверка не завершена",completeP5:"Пройдите проверку Paper 5, чтобы определить его стартовую точку.",startP5:"Начать Paper 5",foundationReview:"Базовая подготовка",foundationTwo:"2 базовые области требуют внимания.",foundationNoCredit:"Они не входят в покрытие Paper 1 или Paper 5.",moreEvidence:"Нужно больше данных",moreEvidenceText:"Нужно ещё немного подтверждений, прежде чем безопасно пропустить эту область.",continueCheck:"Продолжить проверку",
      syllabus:"Прогресс syllabus",foundationSkills:"Базовые навыки",foundationSkillsMeta:"Общая база • вне покрытия P1/P5",confirmed:"Подтверждено",needsRetest:"Нужна повторная проверка",timedEvidence:"Есть подтверждение на время",learning:"Изучается",skills:"навыков",
      circular:"Круговая мера",trigonometry:"Тригонометрия",series:"Последовательности и ряды",differentiation:"Дифференцирование",integration:"Интегрирование",data:"Представление данных",counting:"Перестановки и сочетания",probability:"Вероятность",drv:"Дискретные случайные величины",normal:"Нормальное распределение",
      differentiationArea:"Дифференцирование",powers:"Дифференцирование степеней и простых функций",chainSkill:"Применение Chain Rule",stationary:"Нахождение стационарных точек",retest:"Повторная проверка",continue:"Продолжить",skillDetail:"Навык",currentEvidence:"Текущее подтверждение",learn:"Изучить",practice:"Практика",mixedPractice:"Смешанная практика",resource:"Источник",evidenceJourney:"История подтверждений",initialCheck:"Первичная проверка",learningPractice:"Учебная практика",correction:"Исправление",delayedRetest:"Отложенная повторная проверка",mixedTimed:"Смешанное / временное подтверждение",latestIssue:"Последняя проблема",substitutionIssue:"Неверная подстановка внутренней функции",reviewCorrection:"Разобрать исправление",foundationRequirement:"Необходимая база",algebraConfirmed:"Алгебраические преобразования — подтверждено",
      weeklyPlan:"План недели",thisWeek:"Эта неделя",actionsDone:"Выполнено 4 из 6 действий",primaryPriorities:"Главные приоритеты",dueToday:"Сегодня",conditionalProbability:"Условная вероятность",functionsMixed:"Смешанный набор по функциям",whyTask:"Почему это задача",retestDue:"Повторная проверка готова",recoveryWeek:"Восстановительная неделя",recoveryText:"После перерыва нагрузка снижена. Требования к подтверждениям не меняются.",lateJoiner:"Сфокусированная стартовая неделя",lateJoinerText:"План начинает с наиболее важных безопасных шагов, а не пропускает этапы из-за календаря.",
      needsCorrection:"Нужно исправить",readyRetest:"Готово к повторной проверке",stable:"Стабильно",quadraticIneq:"Квадратные неравенства",endpointIssue:"Неверная граница интервала",review:"Разобрать",conditionalProb:"Условная вероятность",availableNow:"Повторная проверка доступна",chainStable:"Chain Rule",retestPassed:"Повторная проверка пройдена",whatWrong:"Что было неверно",whyMatters:"Почему это важно",correctMethod:"Правильный метод",similarPractice:"Похожая практика",evidenceConfirmed:"Подтверждение получено",morePractice:"Нужно ещё потренироваться",
      timedHub:"Практика на время и Papers",timedSections:"Секции на время",mixedTimedSets:"Смешанные наборы на время",fullPaper:"Полный Paper",purpose:"Цель",duration:"Время",latest:"Последний сопоставимый результат",firstTimed:"Отработать время на выбранной части",transfer:"Проверить перенос навыков в смешанных задачах",fullEvidence:"Получить полное Paper-подтверждение",start:"Начать",notEnough:"Пока недостаточно данных",paperResult:"Результат Paper",rawMark:"Балл",actualTime:"Фактическое время",inTimeMarks:"Баллы в лимите времени",unattempted:"Не выполнено баллов",lossCauses:"Главные причины потерь",reviewLosses:"Разобрать 3 важные потери",appReadiness:"Оценка готовности приложения",onTrack:"По плану",strongObjective:"Сильные объективные подтверждения",risk:"Есть риск",mentorReview:"Проверка наставника",moreEvidenceNeeded:"Нужно больше данных",
      aiAssist:"AI Assist",whyNext:"Почему это следующий шаг",aiNextText:"Базовые навыки differentiation стабильны, а применение Chain Rule ещё нужно укрепить.",explainDifferent:"Объяснить иначе",explainMistake:"Объяснить мою ошибку",mentorCare:"Mentor Care",nextReview:"Следующая проверка: четверг",latestReview:"Последняя проверка",writtenSolution:"Paper 1 • письменное решение Chain Rule",reviewed:"Проверено",mentorText:"Показывайте шаг подстановки яснее перед упрощением.",viewFeedback:"Посмотреть комментарий",
      overview:"Обзор",weekly:"План недели",close:"Закрыть",back:"Назад",mcq:"MCQ",numeric:"Числовой ввод",shortInput:"Короткий математический ввод",diagram:"Вопрос с диаграммой",placementMode:"Стартовая проверка",learningMode:"Обучение",retestMode:"Повторная проверка",timedMode:"Оценивание на время",answer:"Ответ",enterAnswer:"Введите ответ",submit:"Отправить",assessmentProtected:"Во время защищённой проверки подробный разбор ответа не показывается.",
      safePreview:"Статический synthetic preview • без Supabase • без production-данных"
    },
    uz: {
      home:"Bosh sahifa",study:"O‘qish",ratings:"Reyting",profile:"Profil",mathematics:"Matematika",cambridge:"Cambridge AS Mathematics",
      examPrep:"Imtihonga tayyorgarlik",learningSyllabus:"Syllabusni o‘rganish",learningSyllabusSub:"Hozirgi vazifa — takrorlash bosqichidan oldin syllabus qamrovini mustahkamlash.",
      upNext:"Keyingi qadam",paper1:"Paper 1",paper5:"Paper 5",pure:"Pure Mathematics 1",stats:"Probability & Statistics 1",coverage:"Syllabus qamrovi",evidence:"Tasdiq",building:"Shakllanmoqda",starting:"Boshlanish",next:"Keyingi",
      chainRule:"Chain Rule amaliyoti",reprData:"Representation of Data",startPractice:"Amaliyotni boshlash",quickAccess:"Tezkor kirish",syllabusProgress:"Syllabus progressi",corrections:"Tuzatishlar va qayta tekshiruvlar",timedPractice:"Vaqtli amaliyot",papers:"Papers",
      placement:"Boshlang‘ich tekshiruv",findStart:"Boshlash nuqtangizni aniqlaymiz",placementIntro:"Rejangiz to‘g‘ri darajadan boshlanishi uchun nimalarni bilishingizni tekshiramiz.",skills45:"45 syllabus ko‘nikmasi",skills36:"36 syllabus ko‘nikmasi",notStarted:"Boshlanmagan",inProgress:"Jarayonda",completed:"Tugallangan",startPlacement:"Tekshiruvni boshlash",continuePlacement:"Davom ettirish",viewResult:"Natijani ko‘rish",separatePlacement:"Paper 1 va Paper 5 ni alohida topshirish mumkin.",foundationCheck:"Boshlash nuqtasi tasdiqlanishidan oldin ayrim asosiy ko‘nikmalar tekshirilishi mumkin.",
      question:"Savol",of:"dan",submitAnswer:"Javobni yuborish",answerRecorded:"Javob saqlandi",nextQuestion:"Keyingi savol",leavePlacement:"Tekshiruvdan chiqilsinmi?",leavePlacementText:"Tasdiqlangan javoblar saqlanadi. Keyin davom ettirishingiz mumkin.",continuePlacementBtn:"Davom ettirish",leave:"Chiqish",connectionLost:"Aloqa uzildi",waitingConnection:"Aloqa tiklangach javob tasdiqlanadi.",
      placementResult:"Boshlang‘ich tekshiruv natijasi",startingPoint:"Boshlash nuqtasi",strongEvidence:"Kuchli tasdiqlar",needsAttention:"E’tibor kerak",recommendedFocus:"Birinchi tavsiya etilgan yo‘nalish",quadratics:"Kvadrat ifodalar",basicFunctions:"Funksiya asoslari",coordinateGeometry:"Koordinata geometriyasi",functions:"Funksiyalar",buildPlan:"Rejani tuzish",placementNotDone:"Tekshiruv tugallanmagan",completeP5:"Paper 5 boshlash nuqtasini aniqlash uchun uning tekshiruvini tugating.",startP5:"Paper 5 ni boshlash",foundationReview:"Asosiy tayyorgarlik",foundationTwo:"2 asosiy yo‘nalish e’tibor talab qiladi.",foundationNoCredit:"Ular Paper 1 yoki Paper 5 syllabus qamroviga kirmaydi.",moreEvidence:"Ko‘proq tasdiq kerak",moreEvidenceText:"Bu yo‘nalishni xavfsiz o‘tkazib yuborishdan oldin yana biroz ma’lumot kerak.",continueCheck:"Tekshiruvni davom ettirish",
      syllabus:"Syllabus progressi",foundationSkills:"Asosiy ko‘nikmalar",foundationSkillsMeta:"Umumiy baza • P1/P5 qamrovidan tashqari",confirmed:"Tasdiqlangan",needsRetest:"Qayta tekshiruv kerak",timedEvidence:"Vaqtli tasdiq bor",learning:"O‘rganilmoqda",skills:"ko‘nikma",
      circular:"Doiraviy o‘lchov",trigonometry:"Trigonometriya",series:"Ketma-ketliklar va qatorlar",differentiation:"Differensiallash",integration:"Integrallash",data:"Ma’lumotlarni tasvirlash",counting:"O‘rin almashtirish va kombinatsiyalar",probability:"Ehtimollik",drv:"Diskret tasodifiy miqdorlar",normal:"Normal taqsimot",
      differentiationArea:"Differensiallash",powers:"Darajalar va oddiy funksiyalarni differensiallash",chainSkill:"Chain Rule ni qo‘llash",stationary:"Statsionar nuqtalarni topish",retest:"Qayta tekshiruv",continue:"Davom etish",skillDetail:"Ko‘nikma",currentEvidence:"Hozirgi tasdiq",learn:"O‘rganish",practice:"Amaliyot",mixedPractice:"Aralash amaliyot",resource:"Manba",evidenceJourney:"Tasdiqlar tarixi",initialCheck:"Dastlabki tekshiruv",learningPractice:"O‘quv amaliyoti",correction:"Tuzatish",delayedRetest:"Kechiktirilgan qayta tekshiruv",mixedTimed:"Aralash / vaqtli tasdiq",latestIssue:"Oxirgi muammo",substitutionIssue:"Ichki funksiyani noto‘g‘ri o‘rniga qo‘yish",reviewCorrection:"Tuzatishni ko‘rish",foundationRequirement:"Kerakli baza",algebraConfirmed:"Algebraik o‘zgartirish — tasdiqlangan",
      weeklyPlan:"Haftalik reja",thisWeek:"Shu hafta",actionsDone:"6 harakatdan 4 tasi bajarildi",primaryPriorities:"Asosiy ustuvorliklar",dueToday:"Bugun",conditionalProbability:"Shartli ehtimollik",functionsMixed:"Funksiyalar bo‘yicha aralash to‘plam",whyTask:"Nega bu vazifa",retestDue:"Qayta tekshiruv tayyor",recoveryWeek:"Tiklanish haftasi",recoveryText:"Tanaffusdan keyin bu hafta yengillashtirilgan. Tasdiq talablari o‘zgarmaydi.",lateJoiner:"Yo‘naltirilgan boshlang‘ich hafta",lateJoinerText:"Reja kalendar sabab bosqichlarni tashlamaydi, eng muhim xavfsiz ishlarni ustuvor qiladi.",
      needsCorrection:"Tuzatish kerak",readyRetest:"Qayta tekshiruvga tayyor",stable:"Barqaror",quadraticIneq:"Kvadrat tengsizliklar",endpointIssue:"Interval chegarasi noto‘g‘ri",review:"Ko‘rish",conditionalProb:"Shartli ehtimollik",availableNow:"Qayta tekshiruv hozir mavjud",chainStable:"Chain Rule",retestPassed:"Qayta tekshiruvdan o‘tdi",whatWrong:"Nima noto‘g‘ri bo‘ldi",whyMatters:"Nega bu muhim",correctMethod:"To‘g‘ri usul",similarPractice:"O‘xshash amaliyot",evidenceConfirmed:"Tasdiq olindi",morePractice:"Yana amaliyot kerak",
      timedHub:"Vaqtli amaliyot va Papers",timedSections:"Vaqtli bo‘limlar",mixedTimedSets:"Aralash vaqtli to‘plamlar",fullPaper:"To‘liq Paper",purpose:"Maqsad",duration:"Vaqt",latest:"Oxirgi taqqoslanadigan natija",firstTimed:"Tanlangan bo‘limda vaqtni mashq qilish",transfer:"Aralash ko‘nikmalarda transferni tekshirish",fullEvidence:"To‘liq Paper tasdig‘ini olish",start:"Boshlash",notEnough:"Hali yetarli ma’lumot yo‘q",paperResult:"Paper natijasi",rawMark:"Ball",actualTime:"Haqiqiy vaqt",inTimeMarks:"Vaqt ichidagi ballar",unattempted:"Bajarilmagan ballar",lossCauses:"Asosiy yo‘qotish sabablari",reviewLosses:"3 muhim yo‘qotishni ko‘rish",appReadiness:"Ilova tayyorgarlik bahosi",onTrack:"Reja bo‘yicha",strongObjective:"Kuchli obyektiv tasdiq",risk:"Xavf bor",mentorReview:"Mentor tekshiruvi",moreEvidenceNeeded:"Ko‘proq tasdiq kerak",
      aiAssist:"AI Assist",whyNext:"Nega bu keyingi qadam",aiNextText:"Differentiation asoslari barqaror, Chain Rule transferini esa yana mustahkamlash kerak.",explainDifferent:"Boshqacha tushuntirish",explainMistake:"Xatomni tushuntirish",mentorCare:"Mentor Care",nextReview:"Keyingi tekshiruv: payshanba",latestReview:"Oxirgi tekshiruv",writtenSolution:"Paper 1 • Chain Rule yozma yechimi",reviewed:"Tekshirildi",mentorText:"Soddalashtirishdan oldin o‘rniga qo‘yish qadamini aniqroq ko‘rsating.",viewFeedback:"Izohni ko‘rish",
      overview:"Umumiy",weekly:"Haftalik reja",close:"Yopish",back:"Orqaga",mcq:"MCQ",numeric:"Sonli kiritish",shortInput:"Qisqa matematik kiritish",diagram:"Diagrammali savol",placementMode:"Boshlang‘ich tekshiruv",learningMode:"O‘qish",retestMode:"Qayta tekshiruv",timedMode:"Vaqtli baholash",answer:"Javob",enterAnswer:"Javobni kiriting",submit:"Yuborish",assessmentProtected:"Himoyalangan tekshiruv paytida batafsil javob tahlili ko‘rsatilmaydi.",
      safePreview:"Statik synthetic preview • Supabase yo‘q • production ma’lumotlari yo‘q"
    }
  };

  const P1_AREAS = [
    ["quadratics",6,6,"confirmed"],["functions",8,5,"needsRetest"],["coordinateGeometry",6,3,"learning"],["circular",3,2,"learning"],["trigonometry",5,3,"learning"],["series",5,2,"learning"],["differentiation",7,3,"needsRetest"],["integration",5,1,"learning"]
  ];
  const P5_AREAS = [
    ["data",10,5,"learning"],["counting",5,1,"learning"],["probability",6,0,"notStarted"],["drv",9,0,"notStarted"],["normal",6,0,"notStarted"]
  ];

  const ICONS = {
    home:"<path d='M3 10.5 12 3l9 7.5'/><path d='M5 9.5V21h14V9.5'/><path d='M9 21v-7h6v7'/>",
    study:"<path d='m3 6 9-3 9 3-9 3-9-3Z'/><path d='M6 7.5V13c0 2 2.7 4 6 4s6-2 6-4V7.5'/><path d='M21 6v7'/>",
    ratings:"<path d='M4 20V10h4v10'/><path d='M10 20V4h4v16'/><path d='M16 20v-7h4v7'/>",
    profile:"<circle cx='12' cy='8' r='4'/><path d='M4 21c.8-4 3.5-6 8-6s7.2 2 8 6'/>",
    back:"<path d='m15 18-6-6 6-6'/>",chevron:"<path d='m9 18 6-6-6-6'/>",
    clipboard:"<path d='M9 4h6'/><path d='M9 2h6v4H9z'/><path d='M6 4H5a2 2 0 0 0-2 2v15h18V6a2 2 0 0 0-2-2h-1'/>",
    check:"<path d='m5 12 4 4 10-10'/>",repeat:"<path d='m17 2 4 4-4 4'/><path d='M3 11V9a3 3 0 0 1 3-3h15'/><path d='m7 22-4-4 4-4'/><path d='M21 13v2a3 3 0 0 1-3 3H3'/>",
    book:"<path d='M4 5a3 3 0 0 1 3-2h5v17H7a3 3 0 0 0-3 2V5Z'/><path d='M20 5a3 3 0 0 0-3-2h-5v17h5a3 3 0 0 1 3 2V5Z'/>",
    timer:"<circle cx='12' cy='13' r='8'/><path d='M12 9v4l3 2'/><path d='M9 2h6'/>",
    file:"<path d='M6 2h8l4 4v16H6z'/><path d='M14 2v5h5'/><path d='M9 13h6'/><path d='M9 17h6'/>",
    sparkle:"<path d='m12 3 1.5 4.5L18 9l-4.5 1.5L12 15l-1.5-4.5L6 9l4.5-1.5L12 3Z'/>",
    mentor:"<circle cx='9' cy='8' r='3'/><path d='M3 20c.6-3.3 2.6-5 6-5 1.3 0 2.4.2 3.3.7'/><path d='m16 14 2 2 4-4'/>",
    warning:"<path d='M12 3 2 21h20L12 3Z'/><path d='M12 9v5'/><path d='M12 18h.01'/>",
    info:"<circle cx='12' cy='12' r='9'/><path d='M12 11v6'/><path d='M12 7h.01'/>",
    edit:"<path d='M4 20h4l11-11-4-4L4 16v4Z'/><path d='m13 7 4 4'/>",
    target:"<circle cx='12' cy='12' r='9'/><circle cx='12' cy='12' r='5'/><circle cx='12' cy='12' r='1'/>",
    list:"<path d='M8 6h12'/><path d='M8 12h12'/><path d='M8 18h12'/><path d='M4 6h.01'/><path d='M4 12h.01'/><path d='M4 18h.01'/>",
    chart:"<path d='M4 19h16'/><path d='M6 16V9'/><path d='M12 16V5'/><path d='M18 16v-4'/>",
    close:"<path d='m6 6 12 12'/><path d='m18 6-12 12'/>",
    image:"<rect x='3' y='4' width='18' height='16' rx='2'/><circle cx='9' cy='10' r='2'/><path d='m21 16-5-5L5 20'/>",
    clock:"<circle cx='12' cy='12' r='9'/><path d='M12 7v5l3 2'/>",
    syllabus:"<path d='M4 4h16v16H4z'/><path d='M8 8h8'/><path d='M8 12h8'/><path d='M8 16h5'/>",
    corrections:"<path d='M4 19h16'/><path d='m6 15 4-4 3 3 5-6'/>",
    papers:"<path d='M7 3h7l4 4v14H7z'/><path d='M14 3v5h5'/><path d='M10 13h5'/><path d='M10 17h5'/>",
    practice:"<path d='M8 4h8'/><path d='M9 2h6v4H9z'/><path d='M6 4H5a2 2 0 0 0-2 2v15h18V6a2 2 0 0 0-2-2h-1'/><path d='m7 12 2 2 4-4'/>",
    calendar:"<path d='M4 5h16v16H4z'/><path d='M8 2v6'/><path d='M16 2v6'/><path d='M4 10h16'/>",
    arrow:"<path d='M5 12h14'/><path d='m13 6 6 6-6 6'/>",
    wifi:"<path d='M5 12.5a10 10 0 0 1 14 0'/><path d='M8 16a6 6 0 0 1 8 0'/><path d='M12 20h.01'/>",
    math:"<path d='M5 5h14'/><path d='M5 12h14'/><path d='M8 3v4'/><path d='M16 10v4'/><path d='M13 17h6'/><path d='M5 19h4'/>",
    bulb:"<path d='M9 18h6'/><path d='M10 22h4'/><path d='M8 14c-1.3-1-2-2.7-2-4.5A6 6 0 0 1 18 9.5c0 1.8-.7 3.5-2 4.5-.8.7-1 1.4-1 2H9c0-.6-.2-1.3-1-2Z'/>",
  };

  function t(key){ return copy[state.lang]?.[key] || copy.en[key] || key; }
  function esc(v){ return String(v ?? "").replace(/[&<>"']/g,ch=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"})[ch]); }
  function icon(name){ return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICONS[name]||ICONS.info}</svg>`; }

  function topbar(title=t("mathematics"), subtitle=t("cambridge"), back="overview", assessment=false){
    return `<header class="v3-topbar" style="top:42px">
      <button class="v3-topbar__back" type="button" data-back="${esc(back)}" aria-label="${esc(t("back"))}">${icon(assessment?"close":"back")}</button>
      <div><div class="v3-topbar__title">${esc(title)}</div>${subtitle?`<div class="v3-topbar__subtitle">${esc(subtitle)}</div>`:""}</div>
      <div class="v3-topbar__spacer"></div>
    </header>`;
  }
  function nav(){
    return `<nav class="v3-bottom-nav" aria-label="Primary navigation">
      ${[["home","home"],["study","study"],["ratings","ratings"],["profile","profile"]].map(([k,i])=>`<button class="v3-nav-btn${k==="study"?" is-active":""}" type="button">${icon(i)}<span>${esc(t(k))}</span></button>`).join("")}
    </nav>`;
  }
  function pill(label,kind="blue"){ return `<span class="v3-pill v3-pill--${kind}">${esc(label)}</span>`; }
  function progress(pct){ return `<div class="v3-progress"><span style="width:${Math.max(0,Math.min(100,pct))}%"></span></div>`; }
  function serviceBlock(){
    if(state.mode==="ai") return `<div class="v3-service"><div class="v3-service__head">${icon("sparkle")}<span>${esc(t("aiAssist"))}</span></div><div class="v3-service__title">${esc(t("whyNext"))}</div><div class="v3-service__text">${esc(t("aiNextText"))}</div><div class="v3-inline"><button class="v3-text-btn">${esc(t("explainDifferent"))}</button><button class="v3-text-btn">${esc(t("explainMistake"))}</button></div></div>`;
    if(state.mode==="mentor") return `<div class="v3-service v3-service--mentor"><div class="v3-service__head">${icon("mentor")}<span>${esc(t("mentorCare"))}</span></div><div class="v3-service__text">${esc(t("nextReview"))}</div><div class="v3-divider"></div><div class="v3-service__title">${esc(t("latestReview"))}</div><div class="v3-service__text"><strong>${esc(t("writtenSolution"))}</strong> · ${esc(t("reviewed"))}<br>${esc(t("mentorText"))}</div><button class="v3-text-btn">${esc(t("viewFeedback"))}</button></div>`;
    return "";
  }
  function paperCard(component,title,pct,evidence,nextAction){
    return `<article class="v3-paper-card"><div class="v3-paper-card__top"><div><div class="v3-paper-label">${esc(component)}</div><div class="v3-paper-title">${esc(title)}</div></div>${pill(evidence,"blue")}</div><div class="v3-space"></div><div class="v3-progress-row"><span>${esc(t("coverage"))}</span><strong>${pct}%</strong></div>${progress(pct)}<div class="v3-paper-next">${esc(t("next"))}: <strong>${esc(nextAction)}</strong></div></article>`;
  }
  function listRow(iconName,title,meta,screen){
    return `<button class="v3-list-row" type="button"${screen?` data-screen="${screen}"`:""}><span class="v3-list-row__icon">${icon(iconName)}</span><span class="v3-list-row__copy"><span class="v3-list-row__title">${esc(title)}</span>${meta?`<span class="v3-list-row__meta">${esc(meta)}</span>`:""}</span><span class="v3-list-row__right">${icon("chevron")}</span></button>`;
  }
  function standardShell(body,{back="overview",title=null,subtitle=null}={}){
    return `<div class="epv3-shell">${topbar(title||t("mathematics"),subtitle===null?t("cambridge"):subtitle,back)}<main class="epv3-main">${body}<div class="epv3-note" style="margin-top:20px">${esc(t("safePreview"))}</div></main>${nav()}</div>`;
  }

  function overview(){
    const body=`<div class="v3-page-head"><div class="v3-kicker">${esc(t("examPrep"))}</div><h1 class="v3-page-title">${esc(t("learningSyllabus"))}</h1><div class="v3-page-subtitle">${esc(t("learningSyllabusSub"))}</div></div>
      <section class="v3-action-card"><div class="v3-section-head"><div class="v3-section-title">${esc(t("upNext"))}</div>${pill(t("paper1"),"blue")}</div><div class="v3-task-row"><div class="v3-task-icon">${icon("practice")}</div><div class="v3-task-copy"><div class="v3-task-title">${esc(t("chainRule"))}</div><div class="v3-task-meta">20 min</div></div></div>${state.mode==="ai"?serviceBlock():""}<button class="v3-btn v3-btn--primary v3-btn--full" data-screen="question-learning">${esc(t("startPractice"))}</button></section>
      ${state.mode==="mentor"?serviceBlock():""}
      <section class="v3-section"><div class="v3-paper-grid">${paperCard(t("paper1"),t("pure"),65,t("building"),t("chainRule"))}${paperCard(t("paper5"),t("stats"),15,t("starting"),t("reprData"))}</div></section>
      <section class="v3-section"><div class="v3-section-head"><div class="v3-section-title">${esc(t("quickAccess"))}</div></div><div class="v3-list">${listRow("clipboard",t("placement"),t("findStart"),"placement")}${listRow("syllabus",t("syllabusProgress"),"P1 45 • P5 36","syllabus")}${listRow("calendar",t("weeklyPlan"),t("actionsDone"),"weekly")}${listRow("corrections",t("corrections"),t("needsRetest"),"corrections")}${listRow("timer",t("timedPractice"),"P1 / P5","timed")}${listRow("papers",t("papers"),t("notEnough"),"timed")}</div></section>`;
    return standardShell(body,{back:"overview"});
  }

  function placementHub(){
    const card=(comp,title,count,status,action,screen)=>`<article class="v3-card"><div class="v3-card-head"><div><div class="v3-paper-label">${esc(comp)}</div><div class="v3-card-title">${esc(title)}</div><div class="v3-card-subtitle">${esc(count)}</div></div>${pill(status,status===t("completed")?"green":"blue")}</div><button class="v3-btn ${status===t("completed")?"":"v3-btn--primary"} v3-btn--full" data-screen="${screen}">${esc(action)}</button></article>`;
    const body=`<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("findStart"))}</h1><div class="v3-page-subtitle">${esc(t("placementIntro"))}</div></div>
      ${card(t("paper1"),t("pure"),t("skills45"),t("completed"),t("viewResult"),"placement-result")}
      ${card(t("paper5"),t("stats"),t("skills36"),t("notStarted"),t("startPlacement"),"placement-question")}
      <div class="epv3-note" style="margin-top:12px">${esc(t("separatePlacement"))}</div><div class="epv3-note" style="margin-top:8px">${esc(t("foundationCheck"))}</div>`;
    return standardShell(body,{back:"overview"});
  }

  function placementResult(){
    const body=`<div class="v3-page-head"><div class="v3-kicker">${esc(t("paper1"))}</div><h1 class="v3-page-title">${esc(t("placementResult"))}</h1></div>
      <section class="v3-card"><div class="v3-eyebrow">${esc(t("startingPoint"))}</div><div class="v3-card-title" style="margin-top:3px">${esc(t("learningSyllabus"))}</div><div class="v3-divider"></div><div class="epv3-split"><div class="epv3-stat"><div class="epv3-stat__label">${esc(t("strongEvidence"))}</div><div class="epv3-stat__value">${esc(t("quadratics"))}</div><div class="v3-card-subtitle">${esc(t("basicFunctions"))}</div></div><div class="epv3-stat"><div class="epv3-stat__label">${esc(t("needsAttention"))}</div><div class="epv3-stat__value">${esc(t("coordinateGeometry"))}</div></div></div><div class="v3-divider"></div><div class="v3-eyebrow">${esc(t("recommendedFocus"))}</div><div class="v3-card-title" style="margin-top:3px">${esc(t("functions"))}</div><button class="v3-btn v3-btn--primary v3-btn--full" data-screen="weekly">${esc(t("buildPlan"))}</button></section>
      <section class="v3-section"><article class="v3-card"><div class="v3-paper-label">${esc(t("paper5"))}</div><div class="v3-card-title">${esc(t("placementNotDone"))}</div><div class="v3-card-subtitle">${esc(t("completeP5"))}</div><button class="v3-btn v3-btn--full" data-screen="placement-question">${esc(t("startP5"))}</button></article></section>
      <section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("foundationReview"))}</div><div class="v3-card-subtitle">${esc(t("foundationTwo"))}</div><div class="epv3-note" style="margin-top:10px">${esc(t("foundationNoCredit"))}</div></article></section>`;
    return standardShell(body,{back:"placement"});
  }

  function componentSwitch(){ return `<div class="epv3-component-switch"><button class="${state.component==="P1"?"is-active":""}" data-component="P1">${esc(t("paper1"))}</button><button class="${state.component==="P5"?"is-active":""}" data-component="P5">${esc(t("paper5"))}</button></div>`; }
  function statusPill(status){ if(status==="confirmed") return pill(t("confirmed"),"green"); if(status==="needsRetest") return pill(t("needsRetest"),"amber"); if(status==="timedEvidence") return pill(t("timedEvidence"),"blue"); if(status==="notStarted") return `<span class="v3-pill">${esc(t("notStarted"))}</span>`; return pill(t("learning"),"blue"); }
  function syllabus(){
    const areas=state.component==="P1"?P1_AREAS:P5_AREAS;
    const total=state.component==="P1"?45:36;
    const rows=areas.map(([name,count,done,status])=>`<button class="epv3-area" type="button" data-screen="area"><div class="epv3-area__top"><div class="epv3-area__title">${esc(t(name))}</div><div class="epv3-area__count">${done} / ${count}</div></div><div class="epv3-area__bottom">${progress(Math.round(done/count*100))}${statusPill(status)}</div></button>`).join("");
    const body=`<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("syllabus"))}</h1><div class="v3-page-subtitle">${esc(state.component==="P1"?t("skills45"):t("skills36"))} • ${total} ${esc(t("skills"))}</div></div>${componentSwitch()}<div class="epv3-area-list">${rows}</div><section class="v3-section"><div class="v3-list">${listRow("book",t("foundationSkills"),t("foundationSkillsMeta"),"foundation")}</div></section>`;
    return standardShell(body,{back:"overview"});
  }

  function area(){
    const body=`<div class="epv3-breadcrumb"><span>${esc(t("paper1"))}</span><span>›</span><strong>${esc(t("differentiationArea"))}</strong></div><div class="v3-page-head"><h1 class="v3-page-title">${esc(t("differentiationArea"))}</h1><div class="v3-page-subtitle">3 / 7 ${esc(t("confirmed"))}</div></div><div class="epv3-skill-list">
      <div class="epv3-skill"><div class="v3-list-row__icon" style="background:var(--v3-green-bg);color:var(--v3-green)">${icon("check")}</div><div class="epv3-skill__copy"><div class="epv3-skill__title">${esc(t("powers"))}</div><div class="epv3-skill__meta">${esc(t("confirmed"))}</div></div>${pill(t("confirmed"),"green")}</div>
      <div class="epv3-skill"><div class="v3-list-row__icon" style="background:var(--v3-amber-bg);color:var(--v3-amber)">${icon("repeat")}</div><div class="epv3-skill__copy"><div class="epv3-skill__title">${esc(t("chainSkill"))}</div><div class="epv3-skill__meta">${esc(t("needsRetest"))}</div></div><button class="v3-btn v3-btn--compact" data-screen="skill">${esc(t("retest"))}</button></div>
      <div class="epv3-skill"><div class="v3-list-row__icon">${icon("practice")}</div><div class="epv3-skill__copy"><div class="epv3-skill__title">${esc(t("stationary"))}</div><div class="epv3-skill__meta">${esc(t("learning"))}</div></div><button class="v3-btn v3-btn--compact" data-screen="skill">${esc(t("continue"))}</button></div>
    </div>`;
    return standardShell(body,{back:"syllabus"});
  }

  function timelineRow(title,meta,kind){return `<div class="epv3-timeline__row"><div class="epv3-timeline__dot ${kind}">${kind==="is-done"?icon("check"):kind==="is-current"?icon("repeat"):""}</div><div><div class="epv3-timeline__title">${esc(title)}</div><div class="epv3-timeline__meta">${esc(meta)}</div></div></div>`;}
  function skill(){
    const body=`<div class="epv3-breadcrumb"><span>${esc(t("paper1"))}</span><span>›</span><span>${esc(t("differentiationArea"))}</span></div><div class="v3-page-head"><h1 class="v3-page-title">${esc(t("chainSkill"))}</h1><div class="v3-page-subtitle">${esc(t("currentEvidence"))}: ${esc(t("needsRetest"))}</div></div><section class="v3-action-card"><div class="v3-section-head"><div class="v3-section-title">${esc(t("upNext"))}</div>${pill(t("needsRetest"),"amber")}</div><div class="v3-card-title">${esc(t("delayedRetest"))}</div><button class="v3-btn v3-btn--primary v3-btn--full" data-screen="question-retest">${esc(t("retest"))}</button></section>
      <section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("resource"))}</div><div class="v3-card-subtitle">Complete Pure Mathematics 1</div><button class="v3-text-btn">${esc(t("learn"))}</button></article></section>
      <section class="v3-section"><div class="v3-section-head"><div class="v3-section-title">${esc(t("evidenceJourney"))}</div></div><div class="v3-card"><div class="epv3-timeline">${timelineRow(t("initialCheck"),t("completed"),"is-done")}${timelineRow(t("learningPractice"),t("completed"),"is-done")}${timelineRow(t("correction"),t("completed"),"is-done")}${timelineRow(t("delayedRetest"),t("needsRetest"),"is-current")}${timelineRow(t("mixedTimed"),t("notStarted"),"")}</div></div></section>
      <section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("latestIssue"))}</div><div class="v3-card-subtitle">${esc(t("substitutionIssue"))}</div><button class="v3-text-btn" data-screen="correction-detail">${esc(t("reviewCorrection"))}</button></article></section>
      <section class="v3-section"><div class="epv3-note">${esc(t("foundationRequirement"))}: <strong>${esc(t("algebraConfirmed"))}</strong></div></section>${state.mode!=="core"?serviceBlock():""}`;
    return standardShell(body,{back:"area"});
  }

  function priority(num,comp,type,title,mins,reason,screen){return `<div class="epv3-priority"><div class="epv3-priority__num">${num}</div><div class="epv3-priority__copy"><div class="epv3-priority__title">${esc(comp)} • ${esc(type)}<br>${esc(title)}</div><div class="epv3-priority__meta">${esc(mins)}${reason?` • ${esc(reason)}`:""}</div></div><button class="v3-btn v3-btn--compact epv3-priority__action" data-screen="${screen}">${esc(t(num===1?"start":"continue"))}</button></div>`;}
  function weekly(){
    const body=`<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("thisWeek"))}</h1><div class="v3-page-subtitle">${esc(t("actionsDone"))}</div></div><div class="v3-card"><div class="v3-progress-row"><span>${esc(t("weeklyPlan"))}</span><strong>4 / 6</strong></div>${progress(67)}</div><section class="v3-section"><div class="v3-section-head"><div class="v3-section-title">${esc(t("primaryPriorities"))}</div></div>${priority(1,t("paper1"),t("retest"),t("chainSkill"),"15 min",t("dueToday"),"question-retest")}${priority(2,t("paper5"),t("learn"),t("conditionalProbability"),"25 min","","skill")}${priority(3,t("paper1"),t("mixedPractice"),t("functionsMixed"),"30 min","","question-learning")}</section>${state.mode==="ai"?serviceBlock():""}${state.mode==="mentor"?`<div class="v3-service v3-service--mentor" style="margin-top:14px"><div class="v3-service__head">${icon("mentor")}<span>${esc(t("mentorCare"))}</span></div><div class="v3-service__text">${esc(t("mentorText"))}</div></div>`:""}<section class="v3-section"><div class="epv3-note"><strong>${esc(t("recoveryWeek"))}</strong><br>${esc(t("recoveryText"))}</div><div class="epv3-note" style="margin-top:8px"><strong>${esc(t("lateJoiner"))}</strong><br>${esc(t("lateJoinerText"))}</div></section>`;
    return standardShell(body,{back:"overview"});
  }

  function correctionItem(comp,title,meta,status,kind,screen){return `<div class="epv3-skill"><div class="v3-list-row__icon" style="${kind==='amber'?'background:var(--v3-amber-bg);color:var(--v3-amber)':kind==='green'?'background:var(--v3-green-bg);color:var(--v3-green)':''}">${icon(kind==='green'?"check":kind==='amber'?"repeat":"edit")}</div><div class="epv3-skill__copy"><div class="epv3-skill__title">${esc(comp)} • ${esc(title)}</div><div class="epv3-skill__meta">${esc(meta)}</div></div>${screen?`<button class="v3-btn v3-btn--compact" data-screen="${screen}">${esc(status)}</button>`:pill(status,kind)}</div>`;}
  function corrections(){
    const body=`<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("corrections"))}</h1></div><div class="v3-tabs"><button class="v3-tab is-active">All</button><button class="v3-tab">P1</button><button class="v3-tab">P5</button></div><div class="epv3-correction-group"><div class="epv3-correction-group__title">${esc(t("needsCorrection"))}</div>${correctionItem("P1",t("quadraticIneq"),t("endpointIssue"),t("review"),"amber","correction-detail")}</div><div class="epv3-correction-group"><div class="epv3-correction-group__title">${esc(t("readyRetest"))}</div>${correctionItem("P5",t("conditionalProb"),t("availableNow"),t("retest"),"amber","question-retest")}</div><div class="epv3-correction-group"><div class="epv3-correction-group__title">${esc(t("stable"))}</div>${correctionItem("P1",t("chainStable"),t("retestPassed"),t("confirmed"),"green",null)}</div>`;
    return standardShell(body,{back:"overview"});
  }

  function correctionDetail(){
    const steps=[["whatWrong","endpointIssue"],["whyMatters","quadraticIneq"],["correctMethod","functions"],["similarPractice","practice"],["delayedRetest","readyRetest"],["evidenceConfirmed","notStarted"]];
    const body=`<div class="v3-page-head"><div class="v3-kicker">P1</div><h1 class="v3-page-title">${esc(t("quadraticIneq"))}</h1><div class="v3-page-subtitle">${esc(t("correction"))}</div></div><div class="v3-card"><div class="epv3-timeline">${steps.map((s,i)=>timelineRow(t(s[0]),t(s[1]),i<3?"is-done":i===3?"is-current":"")).join("")}</div></div>${state.mode==="ai"?serviceBlock():""}<button class="v3-btn v3-btn--primary v3-btn--full" data-screen="question-learning">${esc(t("similarPractice"))}</button>`;
    return standardShell(body,{back:"corrections"});
  }

  function timed(){
    const body=`<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("timedHub"))}</h1></div>${componentSwitch()}<div class="v3-list">${listRow("timer",t("timedSections"),`${t("purpose")}: ${t("firstTimed")} • 25 min`,"question-timed")}${listRow("practice",t("mixedTimedSets"),`${t("purpose")}: ${t("transfer")} • 35 min`,"question-timed")}${listRow("file",t("fullPaper"),`${t("duration")}: ${state.component==="P1"?"1 h 50 min":"1 h 15 min"}`,"paper-result")}</div><section class="v3-section"><div class="epv3-note">${esc(t("latest"))}: ${esc(t("notEnough"))}</div></section>`;
    return standardShell(body,{back:"overview"});
  }

  function paperResult(){
    const body=`<div class="v3-page-head"><div class="v3-kicker">${esc(t("paper1"))}</div><h1 class="v3-page-title">${esc(t("paperResult"))}</h1></div><div class="epv3-result-grid"><div class="epv3-result-metric"><div class="epv3-result-metric__label">${esc(t("rawMark"))}</div><div class="epv3-result-metric__value">54 / 75</div></div><div class="epv3-result-metric"><div class="epv3-result-metric__label">${esc(t("actualTime"))}</div><div class="epv3-result-metric__value">1 h 52 min</div></div><div class="epv3-result-metric"><div class="epv3-result-metric__label">${esc(t("inTimeMarks"))}</div><div class="epv3-result-metric__value">50</div></div><div class="epv3-result-metric"><div class="epv3-result-metric__label">${esc(t("unattempted"))}</div><div class="epv3-result-metric__value">6</div></div></div><section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("lossCauses"))}</div><ul class="epv3-loss-list"><li>Chain Rule transfer</li><li>Coordinate geometry accuracy</li><li>Timing in final section</li></ul><button class="v3-btn v3-btn--primary v3-btn--full" data-screen="corrections">${esc(t("reviewLosses"))}</button></article></section><section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("appReadiness"))}</div><div class="v3-card-subtitle">${esc(t("onTrack"))}</div><div class="epv3-note" style="margin-top:10px">P1 and P5 remain separate; this result changes only Paper 1 evidence.</div></article></section>${state.mode==="mentor"?`<section class="v3-section"><article class="v3-card"><div class="v3-card-title">${esc(t("mentorReview"))}</div><div class="v3-card-subtitle">${esc(t("moreEvidenceNeeded"))}</div></article></section>`:""}`;
    return standardShell(body,{back:"timed"});
  }

  function questionScreen(mode){
    const placement=mode==="placement"; const timed=mode==="timed"; const retest=mode==="retest";
    const modeLabel=placement?t("placementMode"):timed?t("timedMode"):retest?t("retestMode"):t("learningMode");
    const progressPct=placement?33:timed?42:60;
    const selected=state.selectedOption;
    return `<div class="epv3-question-shell"><div class="epv3-question-head"><button class="v3-topbar__back" type="button" data-back="${placement?"placement":timed?"timed":retest?"skill":"overview"}" aria-label="${esc(t("close"))}">${icon("close")}</button><div class="epv3-question-head__copy"><div class="epv3-question-head__title">${esc(t("paper1"))} • ${esc(modeLabel)}</div><div class="epv3-question-head__meta">${esc(t("question"))} ${placement?"4":"3"} ${esc(t("of"))} ${placement?"12":"10"}</div></div>${timed?pill("18:42","blue"):""}</div><div class="epv3-question-progress"><span style="width:${progressPct}%"></span></div><main class="epv3-question-body"><div class="epv3-question-kicker">${esc(t("mcq"))}</div><div class="epv3-question-text">For f(x) = x² − 6x + 11, find the coordinates of the vertex.</div><div class="epv3-options">${["(3, 2)","(−3, 2)","(3, 11)","(6, 2)"].map((x,i)=>`<button class="epv3-option${selected===i?" is-selected":""}" type="button" data-option="${i}"><span class="epv3-option__letter">${String.fromCharCode(65+i)}</span><span class="epv3-option__text">${esc(x)}</span></button>`).join("")}</div>${(placement||timed||retest)?`<div class="epv3-note" style="margin-top:18px">${esc(t("assessmentProtected"))}</div>`:""}${state.lang!=="en"?`<div class="epv3-note" style="margin-top:8px">Question content language can follow the learner’s selected course-content language independently of interface language.</div>`:""}</main><footer class="epv3-question-footer"><button class="v3-btn v3-btn--primary v3-btn--full" style="margin-top:0" data-submit-question="${mode}" ${selected===null?"disabled":""}>${esc(t("submitAnswer"))}</button></footer></div>`;
  }

  function foundation(){
    const body=`<div class="v3-page-head"><h1 class="v3-page-title">${esc(t("foundationSkills"))}</h1><div class="v3-page-subtitle">${esc(t("foundationSkillsMeta"))}</div></div><div class="v3-list">${listRow("check","Algebraic manipulation",t("confirmed"),null)}${listRow("check","Equations",t("confirmed"),null)}${listRow("repeat","Graphs",t("needsRetest"),null)}${listRow("book","Calculator basics",t("learning"),null)}</div><div class="epv3-note" style="margin-top:12px">${esc(t("foundationNoCredit"))}</div>`;
    return standardShell(body,{back:"syllabus"});
  }

  function render(){
    state.selectedOption=null;
    let html;
    switch(state.screen){
      case "overview":html=overview();break;case "placement":html=placementHub();break;case "placement-result":html=placementResult();break;case "syllabus":html=syllabus();break;case "area":html=area();break;case "skill":html=skill();break;case "weekly":html=weekly();break;case "corrections":html=corrections();break;case "correction-detail":html=correctionDetail();break;case "timed":html=timed();break;case "paper-result":html=paperResult();break;case "foundation":html=foundation();break;case "placement-question":html=questionScreen("placement");break;case "question-learning":html=questionScreen("learning");break;case "question-retest":html=questionScreen("retest");break;case "question-timed":html=questionScreen("timed");break;default:html=overview();
    }
    root.innerHTML=html;
    bind();
    window.scrollTo({top:0,behavior:"instant"});
  }

  function bind(){
    root.querySelectorAll("[data-screen]").forEach(el=>el.addEventListener("click",()=>{state.screen=el.dataset.screen;render();}));
    root.querySelectorAll("[data-back]").forEach(el=>el.addEventListener("click",()=>{state.screen=el.dataset.back||"overview";render();}));
    root.querySelectorAll("[data-component]").forEach(el=>el.addEventListener("click",()=>{state.component=el.dataset.component;render();}));
    root.querySelectorAll("[data-option]").forEach(el=>el.addEventListener("click",()=>{state.selectedOption=Number(el.dataset.option);root.querySelectorAll("[data-option]").forEach(x=>x.classList.toggle("is-selected",Number(x.dataset.option)===state.selectedOption));const submit=root.querySelector("[data-submit-question]");if(submit)submit.disabled=false;}));
    root.querySelectorAll("[data-submit-question]").forEach(el=>el.addEventListener("click",()=>{
      const mode=el.dataset.submitQuestion;
      if(mode==="placement"){state.screen="placement-result";}
      else if(mode==="timed"){state.screen="paper-result";}
      else if(mode==="retest"){state.screen="skill";}
      else {state.screen="corrections";}
      render();
    }));
  }

  function selfTest(){
    const failures=[]; const ok=(v,m)=>{if(!v)failures.push(m);};
    ok(P1_AREAS.reduce((a,x)=>a+x[1],0)===45,"P1 denominator must be 45");
    ok(P5_AREAS.reduce((a,x)=>a+x[1],0)===36,"P5 denominator must be 36");
    ok(P5_AREAS.some(x=>x[0]==="drv"&&x[1]===9),"P5 DRV/BIN/GEO area must contain 9 canonical skills");
    ok(!document.documentElement.innerHTML.includes("correct_answer"),"No answer-key field may appear in preview");
    ok(!document.documentElement.innerHTML.toLowerCase().includes("supabase"),"Preview must have no Supabase dependency");
    ok(["core","ai","mentor"].includes(state.mode),"Service mode must be isolated");
    if(failures.length){console.error("Exam Prep v3 self-test failed",failures);return false;}
    console.info("Exam Prep v3 self-test passed",{p1:45,p5:36,serviceModes:3,network:false});return true;
  }

  modeSelect.addEventListener("change",()=>{state.mode=modeSelect.value;render();});
  langSelect.addEventListener("change",()=>{state.lang=langSelect.value;render();});
  selfTest();
  render();
})();
