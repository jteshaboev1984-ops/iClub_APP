(() => {
  "use strict";

  const root = (window.iClubExamPrepPreview = window.iClubExamPrepPreview || {});
  const { normalizeProfile, assertPreviewIsolation } = root.contracts;

  assertPreviewIsolation();

  const text = (ru, uz, en) => Object.freeze({ ru, uz, en });

  const AREAS = Object.freeze([
    { component: "P1", section: "1.1", family: "QUA", count: 6, title: text("Квадратные выражения и уравнения", "Kvadrat ifodalar va tenglamalar", "Quadratics") },
    { component: "P1", section: "1.2", family: "FUN", count: 8, title: text("Функции", "Funksiyalar", "Functions") },
    { component: "P1", section: "1.3", family: "COO", count: 6, title: text("Координатная геометрия", "Koordinata geometriyasi", "Coordinate geometry") },
    { component: "P1", section: "1.4", family: "CIR", count: 3, title: text("Радианная мера", "Radian o‘lchovi", "Circular measure") },
    { component: "P1", section: "1.5", family: "TRI", count: 5, title: text("Тригонометрия", "Trigonometriya", "Trigonometry") },
    { component: "P1", section: "1.6", family: "SER", count: 5, title: text("Последовательности и ряды", "Ketma-ketliklar va qatorlar", "Series") },
    { component: "P1", section: "1.7", family: "DIF", count: 7, title: text("Дифференцирование", "Differensiallash", "Differentiation") },
    { component: "P1", section: "1.8", family: "INT", count: 5, title: text("Интегрирование", "Integrallash", "Integration") },
    { component: "P5", section: "5.1", family: "DAT", count: 10, title: text("Представление данных", "Ma’lumotlarni ifodalash", "Representation of data") },
    { component: "P5", section: "5.2", family: "CNT", count: 5, title: text("Перестановки и сочетания", "O‘rin almashtirish va kombinatsiyalar", "Permutations and combinations") },
    { component: "P5", section: "5.3", family: "PRO", count: 6, title: text("Вероятность", "Ehtimollik", "Probability") },
    { component: "P5", section: "5.4", family: "DRV", count: 3, title: text("Дискретные случайные величины", "Diskret tasodifiy miqdorlar", "Discrete random variables") },
    { component: "P5", section: "5.4", family: "BIN", count: 3, title: text("Биномиальное распределение", "Binomial taqsimot", "Binomial distribution") },
    { component: "P5", section: "5.4", family: "GEO", count: 3, title: text("Геометрическое распределение", "Geometrik taqsimot", "Geometric distribution") },
    { component: "P5", section: "5.5", family: "NOR", count: 6, title: text("Нормальное распределение", "Normal taqsimot", "Normal distribution") }
  ]);

  const SKILLS = Object.freeze(AREAS.flatMap(area =>
    Array.from({ length: area.count }, (_, index) => Object.freeze({
      code: `${area.component}-${area.family}-${String(index + 1).padStart(2, "0")}`,
      component: area.component,
      section: area.section,
      family: area.family,
      areaTitle: area.title
    }))
  ));

  const PREREQUISITES = Object.freeze([
    "PR-ALG-01", "PR-ALG-02", "PR-ALG-03", "PR-EQN-01", "PR-GRF-01",
    "PR-TRI-01", "PR-SET-01", "PR-CNT-01", "PR-STA-01", "PR-CAL-01", "PR-COM-01"
  ]);

  const MIXED = Object.freeze([
    ...Array.from({ length: 12 }, (_, i) => `MX-P1-${String(i + 1).padStart(2, "0")}`),
    ...Array.from({ length: 9 }, (_, i) => `MX-P5-${String(i + 1).padStart(2, "0")}`),
    "MX-X-01", "MX-X-02"
  ]);

  const task = (id, component, ru, uz, en, minutes, priority, due, aiRu, aiUz, aiEn) => ({
    id, component, title: text(ru, uz, en), minutes, priority, due,
    aiReason: text(aiRu || ru, aiUz || uz, aiEn || en)
  });

  const correction = (id, component, skill, causeRu, causeUz, causeEn, actionRu, actionUz, actionEn, due) => ({
    id, component, skill,
    cause: text(causeRu, causeUz, causeEn),
    action: text(actionRu, actionUz, actionEn),
    status: "open", due
  });

  function profile({
    id, labels, description, recommendedMode = "core", flags = [],
    p1, p5, weeklyBudget = "4 h 30 min", totalStudyHours = "11 h",
    studied = "—", paperHistory = "—", weeklyTasks = [], corrections = [], paper = {}, mentorReview = {}
  }) {
    return normalizeProfile({ id, labels, description, recommendedMode, flags, p1, p5, weeklyBudget, totalStudyHours, studied, paperHistory, weeklyTasks, corrections, paper, mentorReview });
  }

  const defaultTasks = Object.freeze([
    task("w1", "P1", "Квадратные уравнения: перенос", "Kvadrat tenglamalar: transfer", "Quadratics: transfer", 35, 1, "28 Aug", "Закрепить метод до перехода к смешанным задачам.", "Aralash topshiriqlarga o‘tishdan oldin usulni mustahkamlash.", "Secure the method before mixed work."),
    task("w2", "P5", "Гистограммы и плотность частоты", "Gistogramma va chastota zichligi", "Histograms and frequency density", 40, 2, "29 Aug", "Есть свежая ошибка на интерпретацию шкалы.", "Shkalani talqin qilishda yangi xato bor.", "A recent scale-interpretation error needs correction."),
    task("w3", "P1", "Отложенная проверка функции", "Funksiya bo‘yicha kechiktirilgan tekshiruv", "Delayed function retest", 20, 3, "31 Aug", "Проверить, сохранился ли навык после паузы.", "Tanaffusdan keyin ko‘nikma saqlanganini tekshirish.", "Check whether the skill remains stable after a delay.")
  ]);

  const defaultCorrections = Object.freeze([
    correction("c1", "P1", "P1-FUN-04", "Неверно ограничена область определения обратной функции.", "Teskari funksiyaning aniqlanish sohasi noto‘g‘ri cheklangan.", "The inverse-function domain was restricted incorrectly.", "Повторить условие взаимно-однозначности и решить 2 новых примера.", "Bir qiymatlilik shartini takrorlab, 2 yangi misol yeching.", "Review the one-to-one condition and solve 2 fresh examples.", "30 Aug"),
    correction("c2", "P5", "P5-DAT-04", "Высота столбца прочитана как частота, а не плотность частоты.", "Ustun balandligi chastota zichligi o‘rniga chastota deb o‘qilgan.", "Bar height was read as frequency instead of frequency density.", "Восстановить площадь столбца и пройти новый пример через 3 дня.", "Ustun yuzasini tiklab, 3 kundan keyin yangi misol bajaring.", "Reconstruct bar area and complete a fresh example in 3 days.", "31 Aug")
  ]);

  const basePaper = Object.freeze({
    component: "P1", type: "timed", title: "P1 timed section", officialTime: "35 min", actualTime: "38 min",
    rawMark: "21/28", inTime: "18/28", unattempted: "4 marks", recurringErrors: "algebra · final check",
    correction: "P1-FUN-04 retest + one mixed set"
  });

  const mentorReview = Object.freeze({
    status: "pending", component: "P1", skill: "P1-QUA-02", task: "Written parameter condition",
    methodMarks: "2/3", decision: "needs_retest", reason: "Method is sound; final inequality boundary is incomplete.",
    linkedEvidence: "EV-SYN-019", beforeAfter: "L3 candidate → L3 + written review recorded"
  });

  const PROFILES = Object.freeze([
    profile({
      id: "beginner",
      labels: text("Начинающий", "Boshlovchi", "Beginner"),
      description: text("Слабая стартовая база по обоим papers.", "Har ikki paper bo‘yicha boshlang‘ich baza zaif.", "Weak starting base in both papers."),
      p1: { stage: 0, coverage: 3, evidenceLabel: "2 checks", nextAction: "Foundation algebra", readiness: "insufficient", placement: "foundation", confidence: 82 },
      p5: { stage: 0, coverage: 2, evidenceLabel: "1 check", nextAction: "Data basics", readiness: "insufficient", placement: "foundation", confidence: 78 },
      weeklyBudget: "3 h 30 min", totalStudyHours: "9 h", studied: "Basic school mathematics", paperHistory: "None", weeklyTasks: defaultTasks.slice(0, 2), corrections: defaultCorrections.slice(0, 1), paper: basePaper
    }),
    profile({
      id: "prerequisite-gaps",
      labels: text("Пробелы в базе", "Asosiy bilimlarda bo‘shliq", "Prerequisite gaps"),
      description: text("Темы знакомы, но алгебра и чтение графиков блокируют прогресс.", "Mavzular tanish, ammo algebra va grafiklarni o‘qish progressni to‘smoqda.", "Topics are familiar, but algebra and graph reading block progress."),
      flags: ["prerequisite"],
      p1: { stage: 1, coverage: 10, evidenceLabel: "PR-ALG-03 open", nextAction: "Algebra remediation", readiness: "risk", placement: "foundation", confidence: 88 },
      p5: { stage: 1, coverage: 8, evidenceLabel: "PR-GRF-01 open", nextAction: "Graph reading", readiness: "risk", placement: "foundation", confidence: 86 },
      weeklyBudget: "4 h", totalStudyHours: "10 h", studied: "Several syllabus topics", paperHistory: "Topic tests only", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: basePaper
    }),
    profile({
      id: "strong-p1",
      labels: text("Сильный P1", "P1 kuchli", "Strong P1 only"),
      description: text("P1 близок к работе на время, P5 требует фундамента.", "P1 vaqtli ishga yaqin, P5 uchun poydevor kerak.", "P1 is near timed work; P5 still needs foundations."),
      recommendedMode: "mentor",
      flags: ["component-asymmetry"],
      p1: { stage: 4, coverage: 94, evidenceLabel: "3 comparable timed sets", nextAction: "Full P1 baseline", readiness: "ontrack", placement: "consolidation", confidence: 94, delayedRetest: "passed" },
      p5: { stage: 1, coverage: 15, evidenceLabel: "P5 baseline incomplete", nextAction: "Representation of data", readiness: "risk", placement: "foundation", confidence: 80 },
      weeklyBudget: "5 h", totalStudyHours: "12 h", studied: "Most P1; little P5", paperHistory: "P1: 2 papers · P5: none", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: { ...basePaper, rawMark: "25/28", inTime: "24/28", actualTime: "34 min" }, mentorReview
    }),
    profile({
      id: "strong-p5",
      labels: text("Сильный P5", "P5 kuchli", "Strong P5 only"),
      description: text("Статистика сильная, Pure Mathematics требует системного прохода.", "Statistika kuchli, Pure Mathematics tizimli o‘rganishni talab qiladi.", "Statistics is strong; Pure Mathematics needs systematic coverage."),
      recommendedMode: "mentor",
      flags: ["component-asymmetry"],
      p1: { stage: 1, coverage: 14, evidenceLabel: "P1 gaps", nextAction: "Functions", readiness: "risk", placement: "foundation", confidence: 79 },
      p5: { stage: 4, coverage: 96, evidenceLabel: "3 timed sets", nextAction: "Full P5 baseline", readiness: "ontrack", placement: "consolidation", confidence: 95, delayedRetest: "passed" },
      weeklyBudget: "5 h", totalStudyHours: "12 h", studied: "Most P5; limited P1", paperHistory: "P5: 2 papers · P1: none", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: { ...basePaper, component: "P5", title: "P5 timed section", officialTime: "30 min", rawMark: "22/25", inTime: "22/25", unattempted: "0 marks" }, mentorReview: { ...mentorReview, component: "P5", skill: "P5-PRO-05" }
    }),
    profile({
      id: "half-syllabus",
      labels: text("Половина программы", "Dasturning yarmi", "Half syllabus"),
      description: text("Пройдено около половины P1 и P5; нужно наращивать mixed evidence.", "P1 va P5 ning taxminan yarmi o‘tilgan; aralash tasdiqlarni oshirish kerak.", "About half of P1 and P5 is covered; mixed evidence needs to grow."),
      p1: { stage: 2, coverage: 52, evidenceLabel: "23/45 covered", nextAction: "Cumulative mixed set", readiness: "ontrack", placement: "building", confidence: 91 },
      p5: { stage: 2, coverage: 48, evidenceLabel: "17/36 covered", nextAction: "Probability mixed set", readiness: "ontrack", placement: "building", confidence: 90 },
      weeklyBudget: "5 h", totalStudyHours: "12 h", studied: "~50% both components", paperHistory: "Modified papers", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: basePaper
    }),
    profile({
      id: "slow-accurate",
      labels: text("Медленно, но точно", "Sekin, lekin aniq", "Slow but accurate"),
      description: text("Высокая точность при нехватке времени.", "Aniqlik yuqori, lekin vaqt yetishmaydi.", "High accuracy but insufficient speed."),
      recommendedMode: "ai",
      flags: ["timing"],
      p1: { stage: 2, coverage: 42, evidenceLabel: "88% accuracy", nextAction: "Short timed blocks", readiness: "risk", placement: "building", confidence: 92 },
      p5: { stage: 2, coverage: 39, evidenceLabel: "90% accuracy", nextAction: "Timed data set", readiness: "risk", placement: "building", confidence: 93 },
      weeklyBudget: "4 h 30 min", totalStudyHours: "11 h", studied: "Core topics", paperHistory: "Timed sections", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: { ...basePaper, actualTime: "44 min", rawMark: "25/28", inTime: "19/28", unattempted: "5 marks" }
    }),
    profile({
      id: "fast-inaccurate",
      labels: text("Быстро, но неточно", "Tez, lekin noaniq", "Fast but inaccurate"),
      description: text("Время хорошее, но технические ошибки повторяются.", "Vaqt yaxshi, ammo texnik xatolar takrorlanadi.", "Timing is good, but technical errors recur."),
      recommendedMode: "ai",
      flags: ["accuracy"],
      p1: { stage: 2, coverage: 55, evidenceLabel: "67% accuracy", nextAction: "Accuracy correction cycle", readiness: "risk", placement: "building", confidence: 90 },
      p5: { stage: 2, coverage: 50, evidenceLabel: "69% accuracy", nextAction: "Final-check routine", readiness: "risk", placement: "building", confidence: 89 },
      weeklyBudget: "4 h 30 min", totalStudyHours: "11 h", studied: "About half of both papers", paperHistory: "Timed sections", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: { ...basePaper, actualTime: "27 min", rawMark: "17/28", inTime: "17/28", unattempted: "0 marks", recurringErrors: "signs · rounding · reading" }
    }),
    profile({
      id: "mcq-strong-input-weak",
      labels: text("Сильный выбор ответа, слабый ввод", "Test kuchli, kiritish zaif", "Strong MCQ / weak input"),
      description: text("Узнаёт правильный метод, но ошибается в самостоятельном вводе ответа.", "To‘g‘ri usulni taniydi, ammo mustaqil javob kiritishda xato qiladi.", "Recognises the method but struggles with independent input."),
      recommendedMode: "ai",
      flags: ["format-gap"],
      p1: { stage: 2, coverage: 60, evidenceLabel: "MCQ 86% · input 58%", nextAction: "Input-first practice", readiness: "risk", placement: "building", confidence: 92 },
      p5: { stage: 2, coverage: 55, evidenceLabel: "MCQ 84% · input 61%", nextAction: "Exact/rounding input", readiness: "risk", placement: "building", confidence: 91 },
      weeklyBudget: "5 h", totalStudyHours: "12 h", studied: "Broad topic coverage", paperHistory: "Topic tests", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: basePaper
    }),
    profile({
      id: "topic-strong-mixed-weak",
      labels: text("Сильные темы, слабые mixed", "Mavzular kuchli, mixed zaif", "Strong topic / weak mixed"),
      description: text("Отдельные темы решает уверенно, но теряется при комбинации навыков.", "Alohida mavzular yaxshi, ammo ko‘nikmalar aralashganda qiynaladi.", "Strong on isolated topics, weaker when skills are combined."),
      recommendedMode: "ai",
      flags: ["mixed-transfer"],
      p1: { stage: 3, coverage: 78, evidenceLabel: "Topic 84% · mixed 61%", nextAction: "MX-P1 transfer", readiness: "risk", placement: "closure", confidence: 94 },
      p5: { stage: 3, coverage: 75, evidenceLabel: "Topic 82% · mixed 60%", nextAction: "MX-P5 transfer", readiness: "risk", placement: "closure", confidence: 93 },
      weeklyBudget: "5 h 30 min", totalStudyHours: "13 h", studied: "Most syllabus", paperHistory: "Modified papers", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: basePaper
    }),
    profile({
      id: "exam-mode-candidate",
      labels: text("Кандидат в Exam Mode", "Exam Mode nomzodi", "Exam Mode candidate"),
      description: text("100% покрытия; требуется проверка стабильности и времени отдельно P1/P5.", "100% qamrov; P1/P5 bo‘yicha barqarorlik va vaqtni alohida tekshirish kerak.", "100% coverage; stability and timing must be checked separately for P1/P5."),
      recommendedMode: "mentor",
      flags: ["exam-mode"],
      p1: { stage: 5, coverage: 100, evidenceLabel: "3 comparable papers", nextAction: "Last-three stability", readiness: "strong", placement: "exam-mode", confidence: 97, delayedRetest: "stable", writtenStatus: "verified" },
      p5: { stage: 5, coverage: 100, evidenceLabel: "3 comparable papers", nextAction: "Timing calibration", readiness: "ontrack", placement: "exam-mode", confidence: 96, delayedRetest: "stable", writtenStatus: "verified" },
      weeklyBudget: "6 h", totalStudyHours: "16 h", studied: "Full P1 + P5", paperHistory: "P1: 3 · P5: 3 comparable", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: { ...basePaper, rawMark: "64/75", inTime: "62/75", actualTime: "109 min", officialTime: "110 min", unattempted: "0 marks" }, mentorReview: { ...mentorReview, status: "verified", methodMarks: "3/3", decision: "verified", beforeAfter: "P1 App: strong → Mentor Verified: pending component sign-off" }
    }),
    profile({
      id: "late-joiner",
      labels: text("Поздний старт", "Kech qo‘shilgan", "Late joiner"),
      description: text("Присоединился позже календаря; active week начинается с фактического старта.", "Kalendar bo‘yicha kech qo‘shildi; active week haqiqiy boshlanishdan sanaladi.", "Joined later in the calendar; active week starts from the real join date."),
      flags: ["late-joiner"],
      p1: { stage: 0, coverage: 12, evidenceLabel: "Screening open", nextAction: "Separate P1 placement", readiness: "insufficient", placement: "pending", confidence: 72 },
      p5: { stage: 0, coverage: 8, evidenceLabel: "Screening open", nextAction: "Separate P5 placement", readiness: "insufficient", placement: "pending", confidence: 70 },
      weeklyBudget: "4 h", totalStudyHours: "10 h", studied: "Mixed prior study", paperHistory: "Unknown", weeklyTasks: defaultTasks.slice(0, 2), corrections: [], paper: basePaper
    }),
    profile({
      id: "illness-interruption",
      labels: text("Перерыв из-за болезни", "Kasallik sababli tanaffus", "Illness / interruption"),
      description: text("Был перерыв 2–3 недели; нужен безопасный recovery без перегрузки.", "2–3 haftalik tanaffus bo‘lgan; ortiqcha yuklamasiz xavfsiz recovery kerak.", "A 2–3 week interruption requires safe recovery without overload."),
      flags: ["recovery"],
      p1: { stage: 2, coverage: 44, evidenceLabel: "2 retests overdue", nextAction: "14-day recovery", readiness: "risk", placement: "building", confidence: 88 },
      p5: { stage: 2, coverage: 40, evidenceLabel: "1 retest overdue", nextAction: "14-day recovery", readiness: "risk", placement: "building", confidence: 87 },
      weeklyBudget: "3 h 30 min", totalStudyHours: "9 h", studied: "Mid-syllabus before interruption", paperHistory: "One modified paper", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: basePaper
    }),
    profile({
      id: "ai-unavailable",
      labels: text("AI недоступен", "AI mavjud emas", "AI unavailable"),
      description: text("AI отключён; обязательный учебный маршрут остаётся полностью рабочим.", "AI o‘chiq; majburiy o‘quv yo‘li to‘liq ishlaydi.", "AI is off; the required study route remains fully functional."),
      recommendedMode: "ai",
      flags: ["ai-unavailable"],
      p1: { stage: 2, coverage: 38, evidenceLabel: "Core evidence current", nextAction: "Rule-based weekly task", readiness: "ontrack", placement: "building", confidence: 90 },
      p5: { stage: 2, coverage: 35, evidenceLabel: "Core evidence current", nextAction: "Rule-based weekly task", readiness: "ontrack", placement: "building", confidence: 89 },
      weeklyBudget: "4 h 30 min", totalStudyHours: "11 h", studied: "Opening syllabus", paperHistory: "Timed sections", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: basePaper
    }),
    profile({
      id: "offline-retry",
      labels: text("Офлайн и повторная отправка", "Oflayn va qayta yuborish", "Offline / retry"),
      description: text("Ответ сохранён локально и ждёт подтверждения сервера; уровень не повышается заранее.", "Javob qurilmada saqlangan va server tasdig‘ini kutmoqda; daraja oldindan oshmaydi.", "A response is stored locally awaiting server verification; state never increases early."),
      flags: ["offline"],
      p1: { stage: 1, coverage: 20, evidenceLabel: "1 local draft pending", nextAction: "Sync then verify", readiness: "insufficient", placement: "foundation", confidence: 84 },
      p5: { stage: 1, coverage: 18, evidenceLabel: "Server evidence unchanged", nextAction: "Continue available work", readiness: "insufficient", placement: "foundation", confidence: 85 },
      weeklyBudget: "4 h", totalStudyHours: "10 h", studied: "Foundation topics", paperHistory: "None", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: basePaper
    }),
    profile({
      id: "mentor-override",
      labels: text("Случай для решения наставника", "Mentor qarori kerak bo‘lgan holat", "Mentor override case"),
      description: text("Данные приложения неоднозначны; назначенный наставник может изменить маршрут только с причиной и связанным evidence.", "Ilova ma’lumotlari noaniq; biriktirilgan mentor faqat sabab va evidence bilan yo‘lni o‘zgartira oladi.", "App evidence is ambiguous; an assigned mentor may change the route only with reason and linked evidence."),
      recommendedMode: "mentor",
      flags: ["mentor-override"],
      p1: { stage: 1, coverage: 28, evidenceLabel: "Ambiguous advanced skip", nextAction: "Human confirmation", readiness: "ontrack", placement: "accelerated-candidate", confidence: 68, writtenStatus: "pending" },
      p5: { stage: 1, coverage: 22, evidenceLabel: "Deterministic route stable", nextAction: "Foundation + retest", readiness: "ontrack", placement: "foundation", confidence: 91 },
      weeklyBudget: "5 h", totalStudyHours: "12 h", studied: "Strong algebra, uneven evidence", paperHistory: "One P1 paper", weeklyTasks: defaultTasks, corrections: defaultCorrections, paper: basePaper, mentorReview
    })
  ]);

  root.staticData = Object.freeze({
    areas: AREAS,
    skills: SKILLS,
    prerequisites: PREREQUISITES,
    mixedNodes: MIXED,
    profiles: PROFILES,
    defaultTasks,
    defaultCorrections,
    canonicalSummary: Object.freeze({
      P1: 45,
      P5: 36,
      total: 81,
      officialAreasP1: 8,
      officialAreasP5: 5,
      mixedNodes: 23,
      prerequisiteNodes: PREREQUISITES.length,
      note: "81 is the versioned iClub canonical decomposition, not an official Cambridge skill count."
    })
  });
})();
