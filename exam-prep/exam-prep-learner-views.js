(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p260focus3";
  let observer = null;
  let busy = false;
  let activeLanguage = "ru";
  let attentionNotice = "";

  const AREA_LABELS = Object.freeze({
    "1.1 Quadratics": { ru: "Квадратные выражения и уравнения", uz: "Kvadrat ifodalar va tenglamalar", en: "Quadratics" },
    "1.2 Functions": { ru: "Функции", uz: "Funksiyalar", en: "Functions" },
    "1.3 Coordinate geometry": { ru: "Координатная геометрия", uz: "Koordinata geometriyasi", en: "Coordinate geometry" },
    "1.4 Circular measure": { ru: "Радианная мера и окружность", uz: "Radian o‘lchov va aylana", en: "Circular measure" },
    "1.5 Trigonometry": { ru: "Тригонометрия", uz: "Trigonometriya", en: "Trigonometry" },
    "1.6 Series": { ru: "Последовательности и ряды", uz: "Ketma-ketliklar va qatorlar", en: "Series" },
    "1.7 Differentiation": { ru: "Дифференцирование", uz: "Differensiallash", en: "Differentiation" },
    "1.8 Integration": { ru: "Интегрирование", uz: "Integrallash", en: "Integration" },
    "5.1 Representation of data": { ru: "Представление данных", uz: "Ma’lumotlarni tasvirlash", en: "Representation of data" },
    "5.2 Permutations and combinations": { ru: "Перестановки и сочетания", uz: "O‘rin almashtirish va kombinatsiyalar", en: "Permutations and combinations" },
    "5.3 Probability": { ru: "Вероятность", uz: "Ehtimollik", en: "Probability" },
    "5.4 Discrete random variables": { ru: "Дискретные случайные величины", uz: "Diskret tasodifiy miqdorlar", en: "Discrete random variables" },
    "5.5 The normal distribution": { ru: "Нормальное распределение", uz: "Normal taqsimot", en: "The normal distribution" }
  });



  /* Learner-facing Russian copy is intentionally separate from canonical source text.
     The database keeps the versioned academic wording unchanged; this map only controls presentation. */
  const LEARNER_SKILL_RU = Object.freeze({
    "P1-QUA-01": "Приводить квадратный трёхчлен к форме полного квадрата и по этой форме определять вершину и форму графика.",
    "P1-QUA-02": "Использовать дискриминант, чтобы определять число и тип действительных корней, в том числе находить условия на параметр.",
    "P1-QUA-03": "Решать квадратные уравнения, осознанно выбирая разложение на множители, формулу корней или выделение полного квадрата.",
    "P1-QUA-04": "Решать квадратные неравенства с корректным указанием границ интервалов.",
    "P1-QUA-05": "Решать систему из одного линейного и одного квадратного уравнения.",
    "P1-QUA-06": "Распознавать уравнения, которые становятся квадратными после замены выражения, и решать их.",
    "P1-FUN-01": "Использовать понятия функции, области определения, области значений, взаимно однозначной функции, обратной функции и композиции функций.",
    "P1-FUN-02": "Определять область значений функции с учётом заданного ограничения области определения.",
    "P1-FUN-03": "Находить композиции функций и проверять совместимость областей определения и значений.",
    "P1-FUN-04": "Проверять, является ли функция взаимно однозначной, и находить обратную функцию с корректной областью определения.",
    "P1-FUN-05": "Связывать графики функции и обратной функции отражением относительно прямой y = x.",
    "P1-FUN-06": "Выполнять горизонтальные и вертикальные сдвиги графиков.",
    "P1-FUN-07": "Выполнять отражения графиков относительно координатных осей.",
    "P1-FUN-08": "Выполнять растяжения и сжатия графиков, а также простые комбинации преобразований с отслеживанием положения точек.",
    "P1-COO-01": "Получать уравнение прямой по точке и угловому коэффициенту или по двум точкам.",
    "P1-COO-02": "Использовать формы уравнения прямой, а также формулы расстояния, середины отрезка, углового коэффициента и точки пересечения.",
    "P1-COO-03": "Использовать условия параллельности и перпендикулярности прямых через их угловые коэффициенты.",
    "P1-COO-04": "Интерпретировать и строить уравнение окружности, включая развёрнутую форму, центр и радиус.",
    "P1-COO-05": "Решать задачи о пересечении прямой и окружности и задачи на геометрию окружности, сочетая алгебру и геометрию.",
    "P1-COO-06": "Определять точки пересечения, касание и условия на параметры через корни уравнения и дискриминант.",
    "P1-CIR-01": "Переводить градусы в радианы и обратно и использовать радианную меру угла.",
    "P1-CIR-02": "Вычислять длину дуги и находить неизвестные r или θ.",
    "P1-CIR-03": "Вычислять площадь сектора и решать составные задачи на сектор и сегмент окружности.",
    "P1-TRI-01": "Строить и использовать графики sin, cos и tan, включая простые преобразования.",
    "P1-TRI-02": "Использовать точные значения тригонометрических функций и симметрии связанных углов.",
    "P1-TRI-03": "Находить главные значения обратных тригонометрических функций и правильно интерпретировать результат калькулятора.",
    "P1-TRI-04": "Доказывать и применять базовые тригонометрические тождества.",
    "P1-TRI-05": "Решать простые тригонометрические уравнения на заданном интервале без потери решений.",
    "P1-SER-01": "Раскрывать (a + bx)^n при положительном целом n и находить заданные члены или коэффициенты.",
    "P1-SER-02": "Распознавать арифметические и геометрические прогрессии по структуре их членов.",
    "P1-SER-03": "Находить n-й член и сумму конечной арифметической прогрессии, включая обратные задачи.",
    "P1-SER-04": "Находить n-й член и сумму конечной геометрической прогрессии, включая обратные задачи.",
    "P1-SER-05": "Проверять сходимость геометрического ряда и находить сумму до бесконечности.",
    "P1-DIF-01": "Интерпретировать производную как угловой коэффициент касательной и скорость изменения; использовать определение через предел в простом случае.",
    "P1-DIF-02": "Дифференцировать степенные функции с рациональным показателем и их линейные комбинации.",
    "P1-DIF-03": "Применять цепное правило к функциям вида (ax + b)^n.",
    "P1-DIF-04": "Находить уравнения касательной и нормали в заданной точке.",
    "P1-DIF-05": "Определять интервалы возрастания и убывания по знаку производной.",
    "P1-DIF-06": "Решать задачи на скорость изменения и связанные скорости, корректно учитывая единицы и знаки.",
    "P1-DIF-07": "Находить стационарные точки, определять их тип и использовать их для построения графика и оптимизации.",
    "P1-INT-01": "Интегрировать степенные выражения и выражения вида (ax + b)^n, находя первообразные.",
    "P1-INT-02": "Использовать постоянную интегрирования и условие в точке или на границе для восстановления функции.",
    "P1-INT-03": "Вычислять определённые интегралы, включая простой случай с особой точкой на границе.",
    "P1-INT-04": "Находить площадь между кривой и осями или прямыми, а также между двумя кривыми, разбивая область при необходимости.",
    "P1-INT-05": "Находить объём тела вращения вокруг координатной оси с корректными пределами интегрирования.",
    "P5-DAT-01": "Выбирать и критически оценивать подходящий способ представления данных с учётом типа данных и цели.",
    "P5-DAT-02": "Строить и интерпретировать диаграммы «стебель и листья», сохраняя исходные значения.",
    "P5-DAT-03": "Строить и интерпретировать диаграммы размаха, включая сравнение с учётом выбросов, если они заданы.",
    "P5-DAT-04": "Строить и интерпретировать гистограммы с плотностью частоты и неравными интервалами классов.",
    "P5-DAT-05": "Использовать график накопленной частоты для нахождения квартилей, процентилей и долей.",
    "P5-DAT-06": "Вычислять и выбирать среднее арифметическое, медиану и моду для исходных или сгруппированных данных.",
    "P5-DAT-07": "Вычислять и интерпретировать размах, межквартильный размах и стандартное отклонение.",
    "P5-DAT-08": "Сравнивать наборы данных по положению и разбросу и формулировать вывод в контексте задачи.",
    "P5-DAT-09": "Находить среднее и стандартное отклонение по исходным, сгруппированным или сводным данным с корректным использованием формул.",
    "P5-DAT-10": "Работать с кодированными суммами и с объединением или разделением двух наборов данных.",
    "P5-CNT-01": "Различать упорядоченные размещения и неупорядоченные выборки; применять факториал и правило произведения.",
    "P5-CNT-02": "Считать перестановки различных объектов в строке или других упорядоченных позициях.",
    "P5-CNT-03": "Считать размещения с повторяющимися или одинаковыми объектами.",
    "P5-CNT-04": "Считать размещения с ограничениями: вместе, раздельно, на фиксированных позициях или по рядам.",
    "P5-CNT-05": "Считать сочетания и выборки и решать задачи, где выбор сочетается с последующим размещением.",
    "P5-PRO-01": "Строить пространство элементарных исходов и перечислять равновероятные исходы без пропусков и повторов.",
    "P5-PRO-02": "Вычислять вероятность с использованием перестановок и сочетаний.",
    "P5-PRO-03": "Применять правило сложения вероятностей, дополнение события и понятие несовместимых событий.",
    "P5-PRO-04": "Применять правило умножения вероятностей и проверять или использовать независимость событий.",
    "P5-PRO-05": "Вычислять и интерпретировать условную вероятность.",
    "P5-PRO-06": "Строить и использовать деревья вероятностей для последовательных событий, включая выбор без возвращения.",
    "P5-DRV-01": "Строить и проверять дискретное распределение вероятностей и находить неизвестную вероятность.",
    "P5-DRV-02": "Вычислять и интерпретировать математическое ожидание E(X) дискретной случайной величины.",
    "P5-DRV-03": "Вычислять дисперсию и стандартное отклонение дискретной случайной величины.",
    "P5-BIN-01": "Распознавать биномиальную модель и проверять её условия: фиксированное n, два исхода, постоянное p и независимость испытаний.",
    "P5-BIN-02": "Вычислять точечные, интервальные и накопленные биномиальные вероятности.",
    "P5-BIN-03": "Использовать среднее и дисперсию биномиального распределения и решать обратные задачи на параметры.",
    "P5-GEO-01": "Распознавать геометрическую модель как число испытаний до первого успеха и проверять её условия.",
    "P5-GEO-02": "Вычислять точные и накопленные вероятности геометрического распределения, включая использование дополнения.",
    "P5-GEO-03": "Использовать математическое ожидание геометрического распределения и восстанавливать параметр p.",
    "P5-NOR-01": "Распознавать нормальную модель, использовать её обозначения и строить схему с μ и σ.",
    "P5-NOR-02": "Стандартизовать нормально распределённую случайную величину и использовать таблицы или калькулятор с правильным выбором хвоста распределения.",
    "P5-NOR-03": "Вычислять вероятности для интервалов и хвостов нормального распределения.",
    "P5-NOR-04": "Находить квантили и критические значения нормального распределения по заданной вероятности.",
    "P5-NOR-05": "Находить неизвестные μ и/или σ по условиям, заданным через вероятность или квантиль.",
    "P5-NOR-06": "Применять нормальное приближение биномиального распределения, проверяя условия применимости и используя поправку на непрерывность."
  });

  const LEARNER_FOUNDATION_RU = Object.freeze({
    "PR-ALG-01": "Точная арифметика, дроби, отношения и проценты.",
    "PR-ALG-02": "Степени, корни, иррациональные корни и стандартная форма записи числа.",
    "PR-ALG-03": "Раскрытие скобок, разложение на множители, преобразование алгебраических дробей и выражение одной переменной через другие.",
    "PR-CAL-01": "Работа с научным калькулятором, округление и проверка порядка величины.",
    "PR-CNT-01": "Факториал и базовое правило произведения.",
    "PR-COM-01": "Читаемая запись решения, математическая нотация, контекст и единицы.",
    "PR-EQN-01": "Линейные уравнения, неравенства и базовые системы уравнений.",
    "PR-GRF-01": "Координаты, шкалы, чтение и построение стандартных графиков.",
    "PR-SET-01": "Обозначения событий: P(A), объединение, пересечение и дополнение.",
    "PR-STA-01": "Типы данных, таблицы частот и интервалы классов.",
    "PR-TRI-01": "Теорема Пифагора и тригонометрия прямоугольного треугольника."
  });

  function learnerSkillDescription(skillCode) {
    if (activeLanguage !== "ru") return "";
    return LEARNER_SKILL_RU[String(skillCode || "")] || "";
  }

  function learnerPrerequisiteLabel(row, index) {
    const c = copy();
    if (activeLanguage !== "ru") return `${c.prerequisite} ${index + 1}`;
    const code = String(row?.code || "");
    return LEARNER_FOUNDATION_RU[code] || LEARNER_SKILL_RU[code] || `${c.prerequisite} ${index + 1}`;
  }

  internal.learnerCopy = Object.freeze({
    skillRu(skillCode) {
      return LEARNER_SKILL_RU[String(skillCode || "")] || "";
    },
    foundationRu(code) {
      return LEARNER_FOUNDATION_RU[String(code || "")] || "";
    }
  });

  function copy() {
    if (activeLanguage === "uz") return {
      tracker: "Dastur bo‘yicha progress", corrections: "Diqqat talab qiladigan mavzular", overview: "Umumiy ko‘rinish", backTracker: "Progressga qaytish",
      trackerIntro: "Paper 1 va Paper 5 progressi hamda har bir bo‘lim natijasi alohida ko‘rsatiladi.",
      confirmedCount: "Tasdiqlangan", coverage: "Qamrov", skill: "Ko‘nikma", checks: "Tekshiruvlar",
      noEvidence: "Hali tasdiqlanmagan", developing: "Rivojlanmoqda", confirmed: "Tasdiqlangan", secure: "Barqaror", needsWork: "Tuzatish kerak",
      detail: "Ko‘nikma tafsilotlari", history: "Tekshiruv tarixi", prerequisites: "Tayanch bilimlar", resources: "Manbalar", correctionHistory: "Tuzatish tarixi",
      noneYet: "Hozircha ma’lumot yo‘q.", prerequisite: "Tayanch bilim", unknown: "Tekshirilmagan", blocker: "Mustahkamlash kerak", ready: "Yetarli",
      writtenNote: "Yozma yechimlar alohida saqlanadi. Inson tekshiruvi bo‘lmasa ham asosiy o‘quv yo‘li davom etadi.",
      openCorrections: "Diqqat talab qiladigan mavzular", queueIntro: "Bu yerda tasdiqlangan xatolar va kirish tekshiruvidan keyin yana tekshirish kerak bo‘lgan mavzular ko‘rsatiladi. Faqat tasdiqlangan xato tuzatish sikliga o‘tadi.",
      noCorrections: "Hozir tuzatish talab qiladigan xato yo‘q.", reviewError: "Xatoni tahlil qilish", analogues: "O‘xshash masalalarda mashq", waitRetest: "Qayta tekshiruvni kutish", delayedRetest: "Qayta tekshirish",
      due: "Qayta tekshiruv", openPlan: "Haftalik rejani ochish", recentResolved: "Yaqinda yopilgan", loading: "Yuklanmoqda…", error: "Ma’lumotni yuklab bo‘lmadi. Qayta urinib ko‘ring.",
      attempt: "Urinish", correct: "To‘g‘ri", incorrect: "Xato", recorded: "Saqlangan", book: "Kitob", pages: "Sahifalar", completedCorrection: "Tuzatish yopilgan",
      autoChecked: "Avtomatik tekshiruv", writtenCompleted: "Yozma ishlar", focusNow: "Hozir diqqatda", later: "Keyinroq",
      focusFoundation: "Keyingi mavzular uchun asos", focusRepeated: "Takrorlangan qiyinchilik", focusRetest: "Qayta tekshiruv vaqti", focusAttention: "Diqqat talab qiladi", focusSignalFoundation: "Kirish tekshiruvi signali · keyingi mavzular uchun asos", focusSignal: "Kirish tekshiruvi signali · yana tekshirish kerak", confirmSignal: "Yana tekshirish",
      signalStart: "Mavzuni tekshirish", signalFreshNeeded: "Halol qayta tekshiruv uchun yangi topshiriqlar kerak. Oldingi savollar yangi natija sifatida takrorlanmaydi.", signalConfirmed: "Mavzu yangi topshiriqlarda tasdiqlandi.", signalLater: "Bu mavzuni keyinroq tekshiramiz.", signalCorrection: "Mavzu endi xato ustida ishlash bosqichiga o‘tdi.", signalWeekly: "Bu tekshiruv haftalik rejangizda allaqachon bor.",
      focusIntro: "Tizim hozir eng muhim 5 ta mavzuni ko‘rsatadi. Qolganlari yo‘qolmaydi va navbat bilan qo‘shiladi."
    };
    if (activeLanguage === "en") return {
      tracker: "Syllabus progress", corrections: "Needs attention", overview: "Overview", backTracker: "Back to progress",
      trackerIntro: "Paper 1 and Paper 5 progress and each syllabus area are shown separately.",
      confirmedCount: "Confirmed", coverage: "Coverage", skill: "Skill", checks: "Checks",
      noEvidence: "Not yet confirmed", developing: "Developing", confirmed: "Confirmed", secure: "Secure", needsWork: "Needs correction",
      detail: "Skill detail", history: "Check history", prerequisites: "Foundation prerequisites", resources: "Resources", correctionHistory: "Correction history",
      noneYet: "No records yet.", prerequisite: "Prerequisite", unknown: "Not checked", blocker: "Needs work", ready: "Secure",
      writtenNote: "Written solutions are stored separately. Your learning route continues even when no human review is available.",
      openCorrections: "Topics needing attention", queueIntro: "This view combines confirmed mistakes with topics that need another check after the entry screening. Only a confirmed mistake enters the correction cycle.",
      noCorrections: "There are no corrections to work on right now.", reviewError: "Review the mistake", analogues: "Practise similar questions", waitRetest: "Wait for the delayed check", delayedRetest: "Check again",
      due: "Check date", openPlan: "Open weekly plan", recentResolved: "Recently completed", loading: "Loading…", error: "Could not load this view. Try again.",
      attempt: "Attempt", correct: "Correct", incorrect: "Incorrect", recorded: "Recorded", book: "Book", pages: "Pages", completedCorrection: "Correction completed",
      autoChecked: "Auto-checked", writtenCompleted: "Written work", focusNow: "In focus now", later: "Later",
      focusFoundation: "Foundation for later topics", focusRepeated: "Repeated difficulty", focusRetest: "Delayed check due", focusAttention: "Needs attention", focusSignalFoundation: "Entry-check signal · foundation for later topics", focusSignal: "Entry-check signal · needs confirmation", confirmSignal: "Check again",
      signalStart: "Check this topic", signalFreshNeeded: "A fair new check needs different questions. Previously seen questions will not be reused as fresh evidence.", signalConfirmed: "The topic was confirmed on new questions.", signalLater: "This topic will be checked later.", signalCorrection: "This topic now needs correction work.", signalWeekly: "This check is already included in your weekly plan.",
      focusIntro: "The system shows up to five highest-priority topics now. The rest stay recorded and move into focus gradually."
    };
    return {
      tracker: "Прогресс по программе", corrections: "Требуют внимания", overview: "Обзор", backTracker: "Вернуться к прогрессу",
      trackerIntro: "Прогресс Paper 1 и Paper 5 и результат по каждому разделу программы показаны отдельно.",
      confirmedCount: "Подтверждено", coverage: "Покрытие", skill: "Навык", checks: "Проверок",
      noEvidence: "Пока не подтверждено", developing: "Формируется", confirmed: "Подтверждено", secure: "Уверенно", needsWork: "Нужно исправить",
      detail: "Детали навыка", history: "История проверок", prerequisites: "Базовые знания", resources: "Материалы", correctionHistory: "История исправления",
      noneYet: "Пока данных нет.", prerequisite: "Базовое знание", unknown: "Не проверено", blocker: "Нужно укрепить", ready: "Достаточно",
      writtenNote: "Письменные решения сохраняются отдельно. Отсутствие человеческой проверки не блокирует основной учебный маршрут.",
      openCorrections: "Темы, требующие внимания", queueIntro: "Здесь вместе показаны подтверждённые ошибки и темы, которые нужно ещё раз проверить после входной диагностики. Только подтверждённая ошибка запускает цикл исправления.",
      noCorrections: "Сейчас нет ошибок, требующих исправления.", reviewError: "Разобрать ошибку", analogues: "Практика на похожих задачах", waitRetest: "Дождаться повторной проверки", delayedRetest: "Проверить ещё раз",
      due: "Повторная проверка", openPlan: "Открыть недельный план", recentResolved: "Недавно закрыто", loading: "Загрузка…", error: "Не удалось загрузить данные. Попробуйте ещё раз.",
      attempt: "Попытка", correct: "Верно", incorrect: "Ошибка", recorded: "Сохранено", book: "Книга", pages: "Страницы", completedCorrection: "Исправление закрыто",
      autoChecked: "Автопроверка", writtenCompleted: "Письменные работы", focusNow: "Сейчас в фокусе", later: "Позже",
      focusFoundation: "Основа для следующих тем", focusRepeated: "Повторная трудность", focusRetest: "Пора повторно проверить", focusAttention: "Требует внимания", focusSignalFoundation: "Сигнал входной проверки · основа для следующих тем", focusSignal: "Сигнал входной проверки · нужно подтвердить", confirmSignal: "Проверить ещё раз",
      signalStart: "Проверить тему", signalFreshNeeded: "Для честной новой проверки нужны другие задания. Уже увиденные вопросы не будут повторяться как новая проверка.", signalConfirmed: "Тема подтверждена на новых заданиях.", signalLater: "Эту тему система проверит позже.", signalCorrection: "Теперь по этой теме нужна работа над ошибкой.", signalWeekly: "Эта проверка уже включена в недельный план.",
      focusIntro: "Система показывает сейчас не больше 5 самых важных тем. Остальные сохраняются и будут подключаться постепенно."
    };
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;").replaceAll("'", "&#039;");
  }

  function rootEl() { return document.querySelector("#exam-prep-host-root"); }

  function detectLanguage() {
    try {
      const explicit = String(window.i18n?.getLang?.() || document.documentElement.lang || "").toLowerCase();
      if (explicit.startsWith("uz")) return "uz";
      if (explicit.startsWith("en")) return "en";
      if (explicit.startsWith("ru")) return "ru";
    } catch (_) {}
    const value = String(rootEl()?.textContent || "");
    if (/Umumiy ko‘rinish|Haftalik|Imtihon tayyorgarligi|Dastur bo‘yicha/i.test(value)) return "uz";
    if (/\bOverview\b|weekly plan|exam preparation|entry check|syllabus progress/i.test(value)) return "en";
    return "ru";
  }

  function dateLocale() {
    if (activeLanguage === "uz") return "uz-UZ";
    if (activeLanguage === "en") return "en-GB";
    return "ru-RU";
  }

  function formatDate(value, withTime = false) {
    if (!value) return "";
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return "";
    const options = withTime
      ? { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" }
      : { day: "2-digit", month: "2-digit", year: "numeric" };
    return new Intl.DateTimeFormat(dateLocale(), options).format(date);
  }

  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }

  function areaLabel(source) {
    return AREA_LABELS[String(source || "")]?.[activeLanguage] || String(source || "").replace(/^\d+\.\d+\s+/, "");
  }

  function skillStatus(level, correctionId) {
    const c = copy();
    if (correctionId) return c.needsWork;
    const n = Number(level || 0);
    if (n >= 3) return c.secure;
    if (n >= 2) return c.confirmed;
    if (n >= 1) return c.developing;
    return c.noEvidence;
  }

  function shell(component, title, subtitle, body, backHandler = "dashboard") {
    const c = copy();
    const backText = backHandler === "tracker" ? c.backTracker : c.overview;
    return `<section class="ep-host-shell ep-views-shell" data-ep-views-screen><div class="ep-views-top"><div><div class="ep-views-sub">${esc(component)} · Cambridge AS Mathematics</div><div class="ep-views-title">${esc(title)}</div>${subtitle ? `<div class="ep-views-sub">${esc(subtitle)}</div>` : ""}</div><button class="ep-views-btn" type="button" data-ep-views-back="${esc(backHandler)}">${esc(backText)}</button></div>${body}</section>`;
  }

  function bindBack(root, component, backHandler = "dashboard") {
    root.querySelector("[data-ep-views-back]")?.addEventListener("click", async () => {
      if (backHandler === "tracker") await openTracker(component);
      else await dashboard();
    });
  }

  function renderLoading(component, title, backHandler = "dashboard") {
    const root = rootEl(); if (!root) return;
    root.innerHTML = shell(component, title, "", `<div class="ep-views-card" role="status" aria-live="polite">${esc(copy().loading)}</div>`, backHandler);
    bindBack(root, component, backHandler);
  }

  function renderError(component, title, backHandler = "dashboard") {
    const root = rootEl(); if (!root) return;
    root.innerHTML = shell(component, title, "", `<div class="ep-views-error" role="alert" aria-live="assertive">${esc(copy().error)}</div>`, backHandler);
    bindBack(root, component, backHandler);
  }

  async function dashboard() {
    const app = window.iClubExamPrep;
    if (!app || typeof app.open !== "function") return false;
    return Boolean(await app.open({ subjectKey: "mathematics", language: activeLanguage }));
  }

  async function waitFor(selector, attempts = 40) {
    for (let i = 0; i < attempts; i += 1) {
      const node = document.querySelector(selector);
      if (node) return node;
      await new Promise(resolve => setTimeout(resolve, 25));
    }
    return null;
  }

  async function openTracker(component) {
    if (busy || !canUse() || typeof internal.api?.syllabusTracker !== "function") return;
    busy = true; activeLanguage = detectLanguage(); renderLoading(component, copy().tracker);
    const result = await internal.api.syllabusTracker(component); busy = false;
    if (!result?.ok) { renderError(component, copy().tracker); return; }
    renderTracker(component, result.data || {});
  }

  function renderTracker(component, data) {
    const root = rootEl(); if (!root) return; const c = copy();
    const areas = Array.isArray(data?.areas) ? data.areas : [];
    const denominator = Number(data?.denominator_count || 0), confirmed = Number(data?.coverage_count || 0), pct = Number(data?.coverage_pct || 0);
    const cards = areas.map(area => {
      const skills = Array.isArray(area?.skills) ? area.skills : [];
      const total = Number(area?.skill_count || skills.length || 0), done = Number(area?.coverage_count || 0);
      const rows = skills.map(skill => `<button class="ep-views-skill" type="button" data-ep-views-skill="${esc(skill.skill_code)}"><span><strong>${esc(c.skill)} ${Number(skill.sequence_no || 0)}</strong><span class="ep-views-skill-meta"> · ${esc(c.checks)}: ${Number(skill.evidence_total || 0)}</span></span><span class="ep-views-badge">${esc(skillStatus(skill.objective_level, skill.correction_case_id))}</span></button>`).join("");
      return `<div class="ep-views-card ep-views-area"><div class="ep-views-area-head"><strong>${esc(areaLabel(area.official_syllabus_section))}</strong><span class="ep-views-sub">${done} / ${total}</span></div><div class="ep-views-progress"><span style="width:${total > 0 ? Math.min(100, 100 * done / total) : 0}%"></span></div>${rows}</div>`;
    }).join("");
    const body = `<div class="ep-views-summary"><div class="ep-views-stat"><span>${esc(c.confirmedCount)}</span><strong>${confirmed} / ${denominator}</strong></div><div class="ep-views-stat"><span>${esc(c.coverage)}</span><strong>${pct.toFixed(0)}%</strong></div><div class="ep-views-stat"><span>${esc(c.corrections)}</span><strong>${Number(data?.open_correction_count || 0)}</strong></div></div>${cards}`;
    root.innerHTML = shell(component, c.tracker, c.trackerIntro, body);
    bindBack(root, component);
    root.querySelectorAll("[data-ep-views-skill]").forEach(button => button.addEventListener("click", () => openSkill(component, button.dataset.epViewsSkill)));
  }

  async function openSkill(component, skillCode) {
    if (busy || !canUse() || typeof internal.api?.skillDetail !== "function") return;
    activeLanguage = detectLanguage();
    busy = true; renderLoading(component, copy().detail, "tracker");
    const result = await internal.api.skillDetail(component, skillCode); busy = false;
    if (!result?.ok) { renderError(component, copy().detail, "tracker"); return; }
    renderSkill(component, result.data || {});
  }

  function prerequisiteStatus(row) {
    const c = copy();
    if (row?.kind === "foundation") {
      if (row.foundation_status === "secure") return c.ready;
      if (["blocker", "retest_needed"].includes(row.foundation_status)) return c.blocker;
      return c.unknown;
    }
    const level = Number(row?.skill_objective_level || 0);
    return level >= 2 ? c.ready : level >= 1 ? c.developing : c.unknown;
  }

  function evidenceLabel(row) {
    const c = copy();
    const names = activeLanguage === "uz"
      ? { diagnostic: "Kirish tekshiruvi", learning: "O‘rganish", retest: "Qayta tekshirish", mixed: "Aralash mashq", mixed_transfer: "Aralash mashq", timed: "Vaqtli mashq", written: "Yozma ish" }
      : activeLanguage === "en"
        ? { diagnostic: "Entry check", learning: "Learning", retest: "Delayed check", mixed: "Mixed practice", mixed_transfer: "Mixed practice", timed: "Timed practice", written: "Written work" }
        : { diagnostic: "Входная проверка", learning: "Обучение", retest: "Повторная проверка", mixed: "Смешанная практика", mixed_transfer: "Смешанная практика", timed: "Практика на время", written: "Письменная работа" };
    const outcome = typeof row?.is_correct === "boolean" ? (row.is_correct ? c.correct : c.incorrect) : c.recorded;
    return `${names[String(row?.evidence_type || "")] || c.attempt} · ${outcome}`;
  }

  function renderSkill(component, data) {
    const root = rootEl(); if (!root) return; const c = copy();
    const state = data?.state || {}, prereqs = Array.isArray(data?.prerequisites) ? data.prerequisites : [], evidence = Array.isArray(data?.evidence_history) ? data.evidence_history : [], corrections = Array.isArray(data?.correction_history) ? data.correction_history : [];
    const title = `${c.skill} ${Number(data?.sequence_no || 0)}`;
    const learnerDescription = learnerSkillDescription(data?.skill_code);
    const description = learnerDescription ? `<div class="ep-views-note">${esc(learnerDescription)}</div>` : "";
    const prereqRows = prereqs.length ? prereqs.map((row, index) => `<div class="ep-views-row"><span>${esc(learnerPrerequisiteLabel(row, index))}</span><span class="ep-views-badge">${esc(prerequisiteStatus(row))}</span></div>`).join("") : `<div class="ep-views-note">${esc(c.noneYet)}</div>`;
    const evidenceRows = evidence.length ? evidence.map(row => `<div class="ep-views-row"><span>${esc(evidenceLabel(row))}</span><small>${esc(formatDate(row?.created_at))}</small></div>`).join("") : `<div class="ep-views-note">${esc(c.noneYet)}</div>`;
    const correctionRows = corrections.length ? corrections.map(row => `<div class="ep-views-row"><span>${esc(row.status === "resolved" ? c.completedCorrection : c.needsWork)}</span><small>${row?.retest_due_at ? `${esc(c.due)}: ${esc(formatDate(row.retest_due_at))}` : ""}</small></div>`).join("") : `<div class="ep-views-note">${esc(c.noneYet)}</div>`;
    const resources = data?.resources || {};
    const resourceRows = [
      resources.book_chapter ? `<div class="ep-views-row"><span>${esc(c.book)}</span><small>${esc(resources.book_chapter)}</small></div>` : "",
      resources.book_pages ? `<div class="ep-views-row"><span>${esc(c.pages)}</span><small>${esc(resources.book_pages)}</small></div>` : ""
    ].filter(Boolean).join("") || `<div class="ep-views-note">${esc(c.noneYet)}</div>`;
    const objectiveTotal = Number(state.objective_evidence_count || 0), objectiveCorrect = Number(state.correct_objective_count || 0);
    const body = `${description}<div class="ep-views-summary"><div class="ep-views-stat"><span>${esc(c.confirmedCount)}</span><strong>${esc(skillStatus(state.objective_level, Number(state.unresolved_correction_count || 0) > 0 ? "open" : null))}</strong></div><div class="ep-views-stat"><span>${esc(c.autoChecked)}</span><strong>${objectiveCorrect} / ${objectiveTotal}</strong></div><div class="ep-views-stat"><span>${esc(c.writtenCompleted)}</span><strong>${Number(state.written_count || 0)}</strong></div></div><div class="ep-views-card"><strong>${esc(c.prerequisites)}</strong><div class="ep-views-list">${prereqRows}</div></div><div class="ep-views-card"><strong>${esc(c.history)}</strong><div class="ep-views-list">${evidenceRows}</div></div><div class="ep-views-card"><strong>${esc(c.correctionHistory)}</strong><div class="ep-views-list">${correctionRows}</div></div><div class="ep-views-card"><strong>${esc(c.resources)}</strong><div class="ep-views-list">${resourceRows}</div></div><div class="ep-views-note">${esc(c.writtenNote)}</div><div class="ep-views-actions"><button class="ep-views-btn primary" type="button" data-ep-views-corrections="${esc(component)}">${esc(c.openCorrections)}</button></div>`;
    root.innerHTML = shell(component, c.detail, areaLabel(data?.official_syllabus_section), body, "tracker");
    bindBack(root, component, "tracker");
    root.querySelector("[data-ep-views-corrections]")?.addEventListener("click", () => openCorrections(component));
  }

  function correctionStepLabel(value) {
    const c = copy();
    return ({ review_error: c.reviewError, practice_analogues: c.analogues, wait_delayed_retest: c.waitRetest, delayed_retest: c.delayedRetest, retest_content_wait: c.waitRetest, confirm_signal: c.confirmSignal })[String(value || "")] || c.reviewError;
  }

  function focusReasonLabel(value) {
    const c = copy();
    return ({ foundation_dependency:c.focusFoundation, repeated_gap:c.focusRepeated, retest_due:c.focusRetest, needs_attention:c.focusAttention, diagnostic_signal_foundation:c.focusSignalFoundation, diagnostic_signal:c.focusSignal })[String(value || "")] || c.focusAttention;
  }

  async function openCorrections(component) {
    if (busy || !canUse() || typeof internal.api?.correctionQueue !== "function") return;
    busy = true; activeLanguage = detectLanguage(); renderLoading(component, copy().corrections);
    const result = await internal.api.correctionQueue(component); busy = false;
    if (!result?.ok) { renderError(component, copy().corrections); return; }
    renderCorrections(component, result.data || {});
  }

  async function confirmSignal(component, skillCode) {
    if (busy || !canUse() || typeof internal.api?.authorizeSignalConfirmation !== "function") return;
    busy = true;
    const result = await internal.api.authorizeSignalConfirmation(component, skillCode);
    busy = false;
    if (!result?.ok || !result.data) { renderError(component, copy().corrections); return; }
    const status = String(result.data.status || "");
    const c = copy();

    if (["authorized","resume","resume_existing_session_first"].includes(status)) {
      const bridge = internal.liveFlowBridge;
      if (!bridge || typeof bridge.startAuthorizedExternal !== "function") { renderError(component, c.corrections); return; }
      const started = await bridge.startAuthorizedExternal(component, result.data, "corrections");
      if (!started) renderError(component, c.corrections);
      return;
    }
    if (status === "use_weekly_plan") {
      attentionNotice = "";
      await openWeeklyPlan(component);
      return;
    }
    if (status === "already_confirmed") attentionNotice = c.signalConfirmed;
    else if (status === "correction_open") attentionNotice = c.signalCorrection;
    else if (["content_exhausted","content_unavailable"].includes(status)) attentionNotice = c.signalFreshNeeded;
    else attentionNotice = c.signalLater;
    await openCorrections(component);
  }

  function renderCorrections(component, data) {
    const root = rootEl(); if (!root) return; const c = copy();
    const allCases = Array.isArray(data?.cases) ? data.cases : [];
    const cases = Array.isArray(data?.focus_cases) ? data.focus_cases : allCases.slice(0, 5);
    const resolved = Array.isArray(data?.recent_resolved) ? data.recent_resolved : [];
    const rows = cases.length ? cases.map((row,index) => {
      const learnerDescription = learnerSkillDescription(row?.skill_code);
      const signalAction = row?.focus_kind === "screening_signal"
        ? `<div class="ep-views-actions"><button class="ep-views-btn primary" type="button" data-ep-views-confirm-signal="${esc(row.skill_code || "")}">${esc(c.signalStart)}</button></div>`
        : "";
      return `<div class="ep-views-card"><div class="ep-views-area-head"><strong>${index + 1}. ${esc(areaLabel(row.official_syllabus_section))}</strong><span class="ep-views-badge">${esc(correctionStepLabel(row.process_step))}</span></div>${learnerDescription ? `<div class="ep-views-sub">${esc(learnerDescription)}</div>` : ""}<div class="ep-views-note">${esc(focusReasonLabel(row.focus_reason))}</div>${row?.retest_due_at ? `<div class="ep-views-note">${esc(c.due)}: ${esc(formatDate(row.retest_due_at, true))}</div>` : ""}${signalAction}</div>`;
    }).join("") : `<div class="ep-views-note">${esc(c.noCorrections)}</div>`;
    const recent = resolved.length ? `<div class="ep-views-card"><strong>${esc(c.recentResolved)}</strong><div class="ep-views-list">${resolved.map(row => `<div class="ep-views-row"><span>${esc(areaLabel(row.official_syllabus_section))}</span><small>${esc(formatDate(row?.resolved_at))}</small></div>`).join("")}</div></div>` : "";
    const focusCount = Number(data?.focus_count ?? cases.length), deferredCount = Number(data?.deferred_count ?? Math.max(0, Number(data?.active_count || allCases.length) - focusCount));
    const deferred = deferredCount > 0 ? `<div class="ep-views-note ep-views-focus-note">${esc(c.focusIntro)} <strong>+${deferredCount} ${esc(c.later)}</strong></div>` : `<div class="ep-views-note ep-views-focus-note">${esc(c.focusIntro)}</div>`;
    const notice = attentionNotice ? `<div class="ep-views-note" role="status" aria-live="polite">${esc(attentionNotice)}</div>` : "";
    attentionNotice = "";
    const body = `${notice}<div class="ep-views-summary"><div class="ep-views-stat"><span>${esc(c.focusNow)}</span><strong>${focusCount}</strong></div><div class="ep-views-stat"><span>${esc(c.later)}</span><strong>${deferredCount}</strong></div><div class="ep-views-stat"><span>${esc(c.due)}</span><strong>${Number(data?.retest_due_count || 0)}</strong></div></div>${deferred}${rows}${recent}<div class="ep-views-actions"><button class="ep-views-btn primary" type="button" data-ep-views-open-plan="${esc(component)}">${esc(c.openPlan)}</button></div>`;
    root.innerHTML = shell(component, c.corrections, c.queueIntro, body);
    bindBack(root, component);
    root.querySelectorAll("[data-ep-views-confirm-signal]").forEach(button => button.addEventListener("click", () => confirmSignal(component, button.dataset.epViewsConfirmSignal)));
    root.querySelector("[data-ep-views-open-plan]")?.addEventListener("click", () => openWeeklyPlan(component));
  }

  async function openWeeklyPlan(component) {
    if (busy) return; busy = true;
    const ok = await dashboard();
    if (!ok) { busy = false; return; }
    const button = await waitFor(`[data-ep-live-plan="${component}"]`);
    busy = false;
    if (button) button.click();
  }

  function injectDashboardActions() {
    const root = rootEl();
    if (!root || root.hidden || !canUse() || root.querySelector("[data-ep-views-screen]")) return;
    activeLanguage = detectLanguage(); const c = copy();
    root.querySelectorAll(".ep-live-card").forEach(card => {
      if (card.dataset.epViewsInjected === "1") return;
      const component = card.querySelector("[data-ep-live-plan]")?.dataset.epLivePlan || card.querySelector("[data-ep-live-start]")?.dataset.epLiveStart;
      if (!component || !["P1", "P5"].includes(component)) return;
      const actions = card.querySelector(".ep-live-actions");
      if (!actions) return;
      const tracker = document.createElement("button");
      tracker.type = "button"; tracker.className = "ep-views-btn"; tracker.dataset.epViewsTracker = component; tracker.textContent = c.tracker;
      const corrections = document.createElement("button");
      corrections.type = "button"; corrections.className = "ep-views-btn"; corrections.dataset.epViewsCorrections = component; corrections.textContent = c.corrections;
      tracker.addEventListener("click", () => openTracker(component));
      corrections.addEventListener("click", () => openCorrections(component));
      actions.append(tracker, corrections);
      card.dataset.epViewsInjected = "1";
    });
  }

  function attach() {
    const root = rootEl();
    if (!root) { setTimeout(attach, 50); return; }
    if (observer) return;
    observer = new MutationObserver(() => injectDashboardActions());
    observer.observe(root, { childList: true, subtree: true });
    injectDashboardActions();
    internal.learnerViews = Object.freeze({ version: VERSION, openTracker, openSkill, openCorrections });
  }

  attach();
})();