(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p251live1";
  let attached = false;

  const state = {
    language: "ru",
    busy: false,
    profile: null,
    progress: { P1: null, P5: null },
    componentState: { P1: null, P5: null },
    session: null,
    returnView: null,
    itemStartedAt: 0,
    notice: null,
    timerId: null
  };

  function lang(value) {
    const v = String(value || "ru").toLowerCase();
    return ["ru", "uz", "en"].includes(v) ? v : "ru";
  }

  function dateLocale() {
    if (state.language === "uz") return "uz-UZ";
    if (state.language === "en") return "en-GB";
    return "ru-RU";
  }

  function formatDateTime(value) {
    if (!value) return "";
    const date = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(date.getTime())) return "";
    return new Intl.DateTimeFormat(dateLocale(), {
      day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit"
    }).format(date);
  }

  function copy() {
    if (state.language === "uz") return {
      title: "Cambridge AS Mathematics · Exam Prep", kicker: "Imtihonga tayyorgarlik", safe: "Modulga kirish shaxsiy ruxsat bilan himoyalangan.",
      profileTitle: "Avval imtihon rejangizni kiriting", profileText: "Bu ma’lumotlar matematika uchun real haftalik yuklamani tuzishga yordam beradi.",
      series: "Imtihon seriyasi", target: "Maqsad baho", total: "Haftalik umumiy o‘qish vaqti (soat)", math: "Matematika uchun vaqt (soat)",
      save: "Saqlash va kirish tekshiruvini boshlash", saving: "Saqlanmoqda…", invalid: "Soatlarni tekshiring: matematika vaqti 0 dan katta va umumiy vaqtdan oshmasligi kerak.",
      items: "savol", areas: "bo‘lim", start: "Keyingi tekshiruv qismini boshlash", resume: "Tekshiruvni davom ettirish", complete: "Kirish tekshiruvi yakunlandi", loading: "Yuklanmoqda…",
      question: "Savol", submit: "Javobni yuborish", correct: "To‘g‘ri", incorrect: "Xatoni ko‘rib chiqing", finish: "Tekshiruv qismi yakunlandi. Natija yangilandi.",
      error: "Amalni bajarib bo‘lmadi. Qayta urinib ko‘ring.", back: "Orqaga", overview: "Umumiy ko‘rinish", plan: "Haftalik reja", openPlan: "Haftalik rejani ochish", priority: "Ustuvorlik", week: "Hafta",
      learning: "Mavzuni o‘rganish", correction: "Xato ustida ishlash", retest: "Qayta tekshirish", mixed: "Aralash mashq", rebaseline: "Rejani yangilash", startTask: "Boshlash", notDue: "Qayta tekshirish vaqti hali kelmagan", noPlan: "Faol reja yo‘q.", written: "Yechimingizni yozing", completedTask: "Topshiriq tugadi. Reja yangilandi.",
      stageTitle: "Joriy bosqich", coverage: "Tasdiqlangan qamrov", timed: "Vaqtli mashqlar", openTimed: "Vaqtli mashqlarni ochish", noTimed: "Hozircha bu bosqich uchun vaqtli mashq yo‘q.", marks: "ball", minutes: "daq.", startTimed: "Boshlash", timeLeft: "Qolgan vaqt", endAttempt: "Urinishni yakunlash", endConfirm: "Urinishni hozir yakunlaysizmi? Yakunlanmagan qism natijada hisobga olinadi.",
      timedDone: "Urinish yakunlandi", selfReviewTitle: "Ishingizni tekshiring", selfReviewText: "Mezonlar bo‘yicha o‘zingizga ball bering. Bu baho faqat urinishingiz yakunlangandan keyin saqlanadi.", yourAnswer: "Sizning yechimingiz", rubric: "Baholash mezonlari", rubricUnavailable: "Batafsil baholash mezonlari o‘zbek tilida hali tasdiqlanmagan. Hozircha quyidagi tekshirish eslatmasidan foydalaning.", selfTip: "Tekshirish uchun eslatma", award: "Ball", saveMark: "Ballni saqlash", result: "Natija", inTime: "Vaqt ichidagi ball", afterTime: "Vaqtdan keyingi ball", unattempted: "Bajarilmagan ball", comparable: "Taqqoslash uchun yaroqli", yes: "Ha", no: "Yo‘q", backTimed: "Vaqtli mashqlarga qaytish",
      readiness: "Imtihon tayyorgarligi", openReadiness: "Tayyorgarlik holatini ko‘rish", readyStrong: "Obyektiv ko‘rsatkichlar tayyor", readyMore: "Yana dalil kerak", readinessPapers: "Hisobga olingan to‘liq ishlar", readinessSkills: "Barqarorlashtirilishi kerak bo‘lgan ko‘nikmalar", readinessCorrections: "Ochiq tuzatishlar", calibration: "Yakuniy moslashuv", openCalibration: "Yakuniy moslashuvni ochish", calibrationUnavailable: "Yakuniy moslashuv tayyorgarlik mezonlari bajarilgandan keyin ochiladi.",
      stage0: "Kirish tekshiruvi", stage1: "Asoslarni mustahkamlash", stage2: "Dastur bo‘yicha o‘rganish", stage3: "Dastur qamrovini yopish", stage4: "Vaqt ostida mustahkamlash", stage5: "Imtihon tayyorgarligi", stage6: "Yakuniy moslashuv",
      thresholdPending: "Tanlangan imtihon seriyasi va maqsad baho uchun tayyorgarlik mezoni hali sozlanmagan.", threePapers: "Tayyorgarlik uchun uchta taqqoslanadigan to‘liq ish kerak.", stage4Incomplete: "Vaqt ostidagi mustahkamlash hali yakunlanmagan.", skillsIncomplete: "Ba’zi ko‘nikmalarda barqaror natija hali yetarli emas.", correctionsOpen: "Ba’zi xatolar bo‘yicha tuzatish sikli hali yopilmagan.", belowThreshold: "Oxirgi uchta to‘liq ishning hammasi maqsad darajasiga yetmagan.", unattemptedHigh: "Bajarilmay qolayotgan ballar hali ko‘p.", afterTimeHigh: "Natijaning bir qismi hali vaqt tugagandan keyingi ishga tayanmoqda.",
      dashboardEyebrow: "Sizning yo‘lingiz", dashboardTitle: "P1 va P5 bo‘yicha tayyorgarlik", dashboardText: "Har bir komponent o‘z bosqichi, dalillari va keyingi qadami bilan alohida yuradi.",
      componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "ko‘nikma", continueCheck: "Kirish tekshiruvini davom ettirish", profileSaved: "Saqlangan reja", targetShort: "Maqsad", totalShort: "Jami", mathShort: "Matematika", hoursShort: "soat/hafta",
      actionCloseIssue: "Qolgan asosiy xatoni yoping", actionShort: "Qisqa maqsadli mashq", actionTiming: "Vaqt va imtihon tartibini tekshirish", actionTaper: "Yuklamani kamaytirish va natijani saqlash"
    };
    if (state.language === "en") return {
      title: "Cambridge AS Mathematics · Exam Prep", kicker: "Exam preparation", safe: "Access to this module is protected by personal permission.",
      profileTitle: "Set your exam plan first", profileText: "This helps build a realistic weekly mathematics workload.",
      series: "Exam series", target: "Target grade", total: "Total weekly study time (hours)", math: "Mathematics time (hours)",
      save: "Save and start entry check", saving: "Saving…", invalid: "Check the hours: mathematics time must be above 0 and cannot exceed total time.",
      items: "questions", areas: "areas", start: "Start the next check section", resume: "Continue the check", complete: "Entry check complete", loading: "Loading…",
      question: "Question", submit: "Submit answer", correct: "Correct", incorrect: "Review this mistake", finish: "Check section complete. Progress updated.",
      error: "The action could not be completed. Try again.", back: "Back", overview: "Overview", plan: "Weekly plan", openPlan: "Open weekly plan", priority: "Priority", week: "Week",
      learning: "Study this topic", correction: "Work on this mistake", retest: "Check again", mixed: "Mixed practice", rebaseline: "Update plan", startTask: "Start", notDue: "This check is not due yet", noPlan: "No active plan yet.", written: "Write your solution", completedTask: "Task complete. Plan updated.",
      stageTitle: "Current phase", coverage: "Confirmed coverage", timed: "Timed practice", openTimed: "Open timed practice", noTimed: "No timed practice is available for this phase yet.", marks: "marks", minutes: "min", startTimed: "Start", timeLeft: "Time left", endAttempt: "End attempt", endConfirm: "End this attempt now? Unfinished work will be counted in the result.",
      timedDone: "Attempt complete", selfReviewTitle: "Review your work", selfReviewText: "Use the criteria to award your marks. Marks are recorded only after the attempt has ended.", yourAnswer: "Your solution", rubric: "Marking criteria", rubricUnavailable: "Detailed marking criteria are temporarily unavailable in this language.", selfTip: "Review note", award: "Marks", saveMark: "Save marks", result: "Result", inTime: "Marks in time", afterTime: "Marks after time", unattempted: "Unattempted marks", comparable: "Comparable result", yes: "Yes", no: "No", backTimed: "Back to timed practice",
      readiness: "Exam readiness", openReadiness: "View readiness", readyStrong: "Objective evidence is ready", readyMore: "More evidence is needed", readinessPapers: "Comparable full papers counted", readinessSkills: "Skills still needing stability", readinessCorrections: "Open corrections", calibration: "Final calibration", openCalibration: "Open final calibration", calibrationUnavailable: "Final calibration opens after the readiness criteria are met.",
      stage0: "Entry check", stage1: "Foundation", stage2: "Syllabus learning", stage3: "Syllabus closure", stage4: "Timed consolidation", stage5: "Exam readiness", stage6: "Final calibration",
      thresholdPending: "The readiness threshold for the selected exam series and target grade is not configured yet.", threePapers: "Three comparable full papers are required for readiness.", stage4Incomplete: "Timed consolidation is not complete yet.", skillsIncomplete: "Some skills still need stable evidence.", correctionsOpen: "Some corrective work is still open.", belowThreshold: "The latest three full papers do not all meet the target level.", unattemptedHigh: "Too many marks are still being left unattempted.", afterTimeHigh: "Part of the result still depends on work completed after time.",
      dashboardEyebrow: "Your route", dashboardTitle: "Preparation for P1 and P5", dashboardText: "Each component moves separately with its own phase, evidence and next action.",
      componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "skills", continueCheck: "Continue entry check", profileSaved: "Saved plan", targetShort: "Target grade", totalShort: "Total", mathShort: "Mathematics", hoursShort: "h/week",
      actionCloseIssue: "Close the main remaining issue", actionShort: "Short targeted practice", actionTiming: "Check timing and exam logistics", actionTaper: "Reduce workload and protect performance"
    };
    return {
      title: "Cambridge AS Mathematics · Exam Prep", kicker: "Подготовка к экзамену", safe: "Доступ к модулю защищён персональным разрешением.",
      profileTitle: "Сначала задайте план экзамена", profileText: "Это поможет системе построить реалистичную недельную нагрузку по математике.",
      series: "Экзаменационная сессия", target: "Целевая оценка", total: "Общее учебное время в неделю (часы)", math: "Время на математику (часы)",
      save: "Сохранить и начать входную проверку", saving: "Сохраняем…", invalid: "Проверьте часы: время на математику должно быть больше 0 и не превышать общее время.",
      items: "вопросов", areas: "разделов", start: "Начать следующую часть проверки", resume: "Продолжить проверку", complete: "Входная проверка завершена", loading: "Загрузка…",
      question: "Вопрос", submit: "Отправить ответ", correct: "Верно", incorrect: "Разберите эту ошибку", finish: "Часть проверки завершена. Прогресс обновлён.",
      error: "Не удалось выполнить действие. Попробуйте ещё раз.", back: "Назад", overview: "Обзор", plan: "Недельный план", openPlan: "Открыть недельный план", priority: "Приоритет", week: "Неделя",
      learning: "Изучить тему", correction: "Разобрать ошибку", retest: "Проверить ещё раз", mixed: "Смешанная практика", rebaseline: "Обновить план", startTask: "Начать", notDue: "Повторная проверка ещё не наступила", noPlan: "Активного плана пока нет.", written: "Запишите своё решение", completedTask: "Задание завершено. План обновлён.",
      stageTitle: "Текущий этап", coverage: "Подтверждённое покрытие", timed: "Практика на время", openTimed: "Открыть практику на время", noTimed: "Для текущего этапа пока нет доступной практики на время.", marks: "баллов", minutes: "мин", startTimed: "Начать", timeLeft: "Осталось", endAttempt: "Завершить попытку", endConfirm: "Завершить попытку сейчас? Незавершённая часть будет учтена в результате.",
      timedDone: "Попытка завершена", selfReviewTitle: "Проверьте свою работу", selfReviewText: "Сверьтесь с критериями и выставьте себе баллы. Оценка сохраняется только после завершения попытки.", yourAnswer: "Ваше решение", rubric: "Критерии оценивания", rubricUnavailable: "Подробные критерии оценивания на русском языке пока не утверждены. Пока используйте подсказку для проверки ниже.", selfTip: "Подсказка для проверки", award: "Баллы", saveMark: "Сохранить баллы", result: "Результат", inTime: "Баллы в пределах времени", afterTime: "Баллы после времени", unattempted: "Невыполненные баллы", comparable: "Результат сопоставим", yes: "Да", no: "Нет", backTimed: "Вернуться к практике на время",
      readiness: "Готовность к экзамену", openReadiness: "Посмотреть готовность", readyStrong: "Объективные показатели готовы", readyMore: "Нужно больше подтверждений", readinessPapers: "Учтено полных сопоставимых работ", readinessSkills: "Навыков требуют стабилизации", readinessCorrections: "Открытых исправлений", calibration: "Финальная калибровка", openCalibration: "Открыть финальную калибровку", calibrationUnavailable: "Финальная калибровка откроется после выполнения критериев готовности.",
      stage0: "Входная проверка", stage1: "Фундамент", stage2: "Изучение программы", stage3: "Закрытие программы", stage4: "Закрепление на время", stage5: "Готовность к экзамену", stage6: "Финальная калибровка",
      thresholdPending: "Критерий готовности для выбранной экзаменационной сессии и целевой оценки ещё не настроен.", threePapers: "Для готовности нужны три сопоставимые полные работы.", stage4Incomplete: "Этап работы на время ещё не завершён.", skillsIncomplete: "По части навыков ещё не хватает стабильных подтверждений.", correctionsOpen: "По части ошибок цикл исправления ещё не закрыт.", belowThreshold: "Не все три последние полные работы достигли целевого уровня.", unattemptedHigh: "Пока остаётся слишком много невыполненных баллов.", afterTimeHigh: "Часть результата всё ещё зависит от работы после окончания времени.",
      dashboardEyebrow: "Ваш маршрут", dashboardTitle: "Подготовка по P1 и P5", dashboardText: "Каждый компонент идёт отдельно: со своим этапом, подтверждениями и следующим действием.",
      componentP1: "Pure Mathematics 1", componentP5: "Probability & Statistics 1", skillsLabel: "навыков", continueCheck: "Продолжить входную проверку", profileSaved: "Сохранённый план", targetShort: "Цель", totalShort: "Всего", mathShort: "Математика", hoursShort: "ч/нед",
      actionCloseIssue: "Закрыть основную оставшуюся ошибку", actionShort: "Короткая целевая практика", actionTiming: "Проверить время и экзаменационный порядок", actionTaper: "Снизить нагрузку и сохранить форму"
    };
  }

  function esc(value) {
    return String(value == null ? "" : value).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&#039;");
  }
  function key(prefix) { return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`; }
  function rootEl() { return document.querySelector("#exam-prep-host-root"); }
  function canMount() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }
  function clearTimer() { if (state.timerId) clearInterval(state.timerId); state.timerId = null; }
  function stageLabel(value) { const c = copy(); return c[`stage${Math.max(0, Math.min(6, Number(value) || 0))}`]; }
  function minutes(sec) { return Math.max(1, Math.ceil((Number(sec) || 0) / 60)); }
  function assessmentTitle(row) { return String(row?.[`title_${state.language}`] || row?.title_en || copy().timed); }
  function artifactText(value) {
    if (value == null) return "";
    if (typeof value === "string") return value;
    if (typeof value === "object" && typeof value.text === "string") return value.text;
    try { return JSON.stringify(value); } catch (_) { return String(value); }
  }

  function shell(body, options = {}) {
    const c = copy();
    const head = options.compact === true
      ? ""
      : `<div class="ep-live-head"><div><div class="ep-host-kicker">${esc(c.kicker)}</div><h2 class="ep-host-title">${esc(c.title)}</h2></div></div>`;
    return `<section class="ep-host-shell ep-live" aria-label="${esc(c.title)}">${head}${body}</section>`;
  }
  function renderLoading() { clearTimer(); const root = rootEl(); if (root) root.innerHTML = shell(`<div class="ep-live-card" role="status" aria-live="polite">${esc(copy().loading)}</div>`); }
  function renderError(message = null) { clearTimer(); const root = rootEl(); if (root) root.innerHTML = shell(`<div class="ep-live-error" role="alert" aria-live="assertive">${esc(message || copy().error)}</div><button class="ep-live-btn secondary" type="button" data-ep-live-home>${esc(copy().overview)}</button>`); root?.querySelector('[data-ep-live-home]')?.addEventListener('click', renderDashboard); }

  function renderProfile() {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy();
    root.innerHTML = shell(`<div class="ep-live-card"><strong>${esc(c.profileTitle)}</strong><div class="ep-live-meta">${esc(c.profileText)}</div><form class="ep-live-form" data-ep-live-profile-form>
      <label class="ep-live-field"><span>${esc(c.series)}</span><input name="exam_series" maxlength="80" placeholder="Oct/Nov 2026" required aria-required="true"></label>
      <label class="ep-live-field"><span>${esc(c.target)}</span><input name="target_grade" maxlength="40" placeholder="A" required aria-required="true"></label>
      <label class="ep-live-field"><span>${esc(c.total)}</span><input name="total_hours" type="number" min="0.5" max="168" step="0.5" required aria-required="true"></label>
      <label class="ep-live-field"><span>${esc(c.math)}</span><input name="math_hours" type="number" min="0.5" max="168" step="0.5" required aria-required="true"></label>
      <div class="ep-live-actions"><button class="ep-live-btn" type="submit" data-ep-live-save-profile>${esc(state.busy ? c.saving : c.save)}</button></div></form><div data-ep-live-profile-error role="alert" aria-live="assertive"></div></div>`);
    root.querySelector("[data-ep-live-profile-form]")?.addEventListener("submit", saveProfile);
  }

  async function saveProfile(event) {
    event.preventDefault(); if (state.busy) return;
    const form = event.currentTarget;
    const values = { examSeries: form.elements.exam_series.value, targetGrade: form.elements.target_grade.value, totalHours: Number(form.elements.total_hours.value), mathHours: Number(form.elements.math_hours.value) };
    if (!String(values.examSeries || "").trim() || !String(values.targetGrade || "").trim() || !(values.totalHours > 0) || !(values.mathHours > 0) || values.mathHours > values.totalHours || values.totalHours > 168) {
      const el = rootEl()?.querySelector("[data-ep-live-profile-error]"); if (el) el.innerHTML = `<div class="ep-live-error">${esc(copy().invalid)}</div>`; return;
    }
    state.busy = true; renderLoading();
    const result = await internal.api.saveExamProfile(values); state.busy = false;
    if (!result?.ok) { renderError(); return; }
    const profile = await internal.api.examProfile(); state.profile = profile?.ok ? profile.data : null; await renderDashboard();
  }

  const COMPONENT_AREA_LABELS = Object.freeze({
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

  function componentHomeCopy() {
    if (state.language === "uz") return {
      back: "Sizning yo‘lingiz", next: "Keyingi qadam", progress: "Progress", topics: "Mavzular",
      attention: "E’tibor talab qiladi", timed: "Vaqtli mashq", materials: "O‘quv materiallari",
      readiness: "Imtihon tayyorgarligi", confirmed: "Tasdiqlangan", inProgress: "Jarayonda",
      notStarted: "Boshlanmagan", needsAttention: "Qayta ko‘rish kerak", openComponent: "Ochish",
      startTask: "Topshiriqni boshlash", continueTask: "Topshiriqni davom ettirish",
      fixTask: "Xatoni tuzatish", retestTask: "Qayta tekshiruvdan o‘tish", mixedTask: "Aralash mashqni boshlash",
      timedTask: "Vaqtli mashqni boshlash", checkNext: "Keyingi topshiriqni tekshirish",
      waiting: "Qayta tekshiruv vaqti hali kelmagan", noAvailable: "Hozircha yangi topshiriq mavjud emas.",
      skills: "ko‘nikma", skill: "Ko‘nikma"
    };
    if (state.language === "en") return {
      back: "Your route", next: "Next step", progress: "Progress", topics: "Topics",
      attention: "Needs attention", timed: "Timed practice", materials: "Study materials",
      readiness: "Exam readiness", confirmed: "Confirmed", inProgress: "In progress",
      notStarted: "Not started", needsAttention: "Needs review", openComponent: "Open",
      startTask: "Start task", continueTask: "Continue task", fixTask: "Fix this mistake",
      retestTask: "Take the delayed check", mixedTask: "Start mixed practice", timedTask: "Start timed practice",
      checkNext: "Check next task", waiting: "The delayed check is not available yet",
      noAvailable: "No new task is available right now.", skills: "skills", skill: "Skill"
    };
    return {
      back: "Ваш маршрут", next: "Следующий шаг", progress: "Прогресс", topics: "Темы",
      attention: "Требуют внимания", timed: "Работа на время", materials: "Учебные материалы",
      readiness: "Готовность к экзамену", confirmed: "Подтверждено", inProgress: "В работе",
      notStarted: "Не начато", needsAttention: "Нужно повторить", openComponent: "Открыть",
      startTask: "Начать задание", continueTask: "Продолжить задание", fixTask: "Исправить ошибку",
      retestTask: "Пройти повторную проверку", mixedTask: "Начать смешанную практику",
      timedTask: "Начать работу на время", checkNext: "Проверить следующий шаг",
      waiting: "Повторная проверка ещё не доступна", noAvailable: "Сейчас нет нового доступного задания.",
      skills: "навыков", skill: "Навык"
    };
  }

  function componentAreaLabel(value) {
    const labels = COMPONENT_AREA_LABELS[String(value || "")];
    return labels?.[state.language] || labels?.ru || String(value || "").replace(/^\d+\.\d+\s+/, "");
  }

  function componentSummary(component, statePayload) {
    const rows = Array.isArray(statePayload?.components) ? statePayload.components : [];
    return rows.find(x => x?.component_code === component) || rows[0] || null;
  }

  function componentCard(component, progress, statePayload) {
    const c = copy(), home = componentHomeCopy(), s = progress?.screening || {}, summary = componentSummary(component, statePayload);
    const reqItems = Number(s.required_items || 0), ansItems = Number(s.answered_items || 0), reqAreas = Number(s.required_areas || 0), ansAreas = Number(s.answered_areas || 0);
    const pct = reqItems > 0 ? Math.min(100, Math.round(100 * ansItems / reqItems)) : 0;
    const complete = progress?.stage0_complete === true, active = progress?.active_session;
    const stage = Number(summary?.operational_stage || 0), coverage = Number(summary?.coverage_pct || 0);
    const componentName = component === "P1" ? c.componentP1 : c.componentP5;
    const skillCount = component === "P1" ? 45 : 36;
    const status = complete
      ? `<div class="ep-live-component-status"><strong>${esc(c.stageTitle)}: ${esc(stageLabel(stage))}</strong><div class="ep-live-progress"><span style="width:${Math.max(0, Math.min(100, coverage))}%"></span></div><div class="ep-live-meta">${esc(c.coverage)}: ${coverage.toFixed(0)}%</div></div>`
      : `<div class="ep-live-component-status"><div>${ansItems} / ${reqItems} ${esc(c.items)}</div><div class="ep-live-progress"><span style="width:${pct}%"></span></div><div class="ep-live-meta">${ansAreas} / ${reqAreas} ${esc(c.areas)}</div></div>`;
    const compat = complete
      ? `<div class="ep-live-compat-actions" hidden aria-hidden="true"><button type="button" data-ep-live-plan="${component}"></button>${stage >= 2 ? `<button type="button" data-ep-live-timed="${component}"></button>` : ""}${stage >= 5 ? `<button type="button" data-ep-live-readiness="${component}"></button>` : ""}</div>`
      : `<div class="ep-live-compat-actions" hidden aria-hidden="true"><button type="button" data-ep-live-start="${component}"></button></div>`;
    const hint = complete ? `${home.openComponent} ${component}` : (active || ansItems > 0 ? c.continueCheck : c.start);
    return `<div class="ep-live-component-slot"><button class="ep-live-card ep-live-component-card ep-live-component-entry" type="button" data-ep-live-component="${component}" data-ep-component-entry="1" data-ep-live-open-component="${component}"><div class="ep-live-component-head"><span class="ep-live-component-code">${component}</span><div class="ep-live-component-copy"><strong>${esc(componentName)}</strong><span>${skillCount} ${esc(home.skills)}</span></div><span class="ep-live-component-arrow" aria-hidden="true">›</span></div>${status}<div class="ep-live-component-open">${esc(hint)} <span aria-hidden="true">→</span></div></button>${compat}</div>`;
  }

  function trackerAreaForSkill(tracker, skillCode) {
    const areas = Array.isArray(tracker?.areas) ? tracker.areas : [];
    return areas.find(area => Array.isArray(area?.skills) && area.skills.some(skill => skill?.skill_code === skillCode)) || null;
  }

  function skillStateLabel(skill) {
    const c = componentHomeCopy();
    if (skill?.correction_case_id) return c.needsAttention;
    const level = Number(skill?.objective_level || 0);
    if (level >= 2) return c.confirmed;
    if (level >= 1) return c.inProgress;
    return c.notStarted;
  }

  function planSelection(plan) {
    const rows = (Array.isArray(plan?.items) ? plan.items : [])
      .filter(item => item && item.status === "pending" && ["learning", "correction", "retest", "mixed_transfer"].includes(item.item_type))
      .sort((a, b) => Number(a.priority_order || 999) - Number(b.priority_order || 999));
    const now = Date.now();
    const ready = rows.find(item => item.item_type !== "retest" || !item.due_at || !Number.isFinite(Date.parse(item.due_at)) || Date.parse(item.due_at) <= now) || null;
    const waiting = rows.find(item => item.item_type === "retest" && item.due_at && Number.isFinite(Date.parse(item.due_at)) && Date.parse(item.due_at) > now) || null;
    return { ready, waiting };
  }

  function weeklyGoalCanAct(component, goal) {
    if (!goal || goal.component_code !== component ||
        !["learning", "correction", "retest", "mixed_transfer"].includes(goal.item_type)) return false;
    if (["completed", "paused", "replaced", "unavailable"].includes(goal.status)) return false;
    const delayedRetest = goal.item_type === "correction" && goal.status === "waiting_retest";
    if (goal.weekly_commitment_complete === true && !delayedRetest) return false;
    return true;
  }

  function weeklyPlanSelection(component, plan, weeklyProgress) {
    if (!plan || !weeklyProgress ||
        weeklyProgress.contract_version !== "progress_ux_v1" ||
        weeklyProgress.component_code !== component ||
        !Array.isArray(plan.items) || !Array.isArray(weeklyProgress.goals) ||
        Number(plan.active_week_no || 0) !== Number(weeklyProgress.active_week_no || 0)) {
      return { ready: null, waiting: null, valid: false };
    }
    const pending = plan.items.filter(item => item && item.status === "pending" &&
      ["learning", "correction", "retest", "mixed_transfer"].includes(item.item_type));
    const bound = [];
    const seenOrders = new Set();
    for (const goal of weeklyProgress.goals) {
      if (!weeklyGoalCanAct(component, goal)) continue;
      const order = Number(goal.action_priority_order);
      if (!Number.isInteger(order) || order < 1 || order > 3) continue;
      if (seenOrders.has(order)) return { ready: null, waiting: null, valid: false };
      seenOrders.add(order);
      const matches = pending.filter(item => Number(item.priority_order) === order);
      if (matches.length !== 1) return { ready: null, waiting: null, valid: false };
      const item = matches[0];
      if (!goal.skill_code || item.skill_code !== goal.skill_code) return { ready: null, waiting: null, valid: false };
      const delayedRetest = goal.item_type === "correction" && item.item_type === "retest" && goal.status === "waiting_retest";
      if (item.item_type !== goal.item_type && !delayedRetest) return { ready: null, waiting: null, valid: false };
      bound.push({ item, goal });
    }
    bound.sort((a, b) => Number(a.item.priority_order) - Number(b.item.priority_order));
    const now = Date.now();
    const readyPair = bound.find(({ item }) =>
      item.item_type !== "retest" || !item.due_at || !Number.isFinite(Date.parse(item.due_at)) || Date.parse(item.due_at) <= now) || null;
    let waiting = bound.find(({ item }) =>
      item.item_type === "retest" && item.due_at && Number.isFinite(Date.parse(item.due_at)) && Date.parse(item.due_at) > now)?.item || null;
    if (!waiting) {
      const waitingGoal = weeklyProgress.goals
        .filter(goal => goal?.component_code === component && goal.status === "waiting_retest" &&
          goal.retest_due_at && Number.isFinite(Date.parse(goal.retest_due_at)) && Date.parse(goal.retest_due_at) > now)
        .sort((a, b) => Number(a.priority_order || 999) - Number(b.priority_order || 999))[0];
      if (waitingGoal) waiting = { item_type: "retest", skill_code: waitingGoal.skill_code, due_at: waitingGoal.retest_due_at };
    }
    return { ready: readyPair?.item || null, waiting, valid: true };
  }

  function primaryAction(component, progress, summary, tracker, plan, recovery, weeklyProgress) {
    const c = copy(), home = componentHomeCopy(), screening = progress?.screening || {};
    if (progress?.stage0_complete !== true) {
      const started = Boolean(progress?.active_session) || Number(screening.answered_items || 0) > 0;
      return { kind: "diagnostic", title: stageLabel(0), detail: started ? c.continueCheck : c.start, label: started ? c.continueCheck : c.start };
    }
    if (["resume", "ready_to_finalize"].includes(recovery?.status) && recovery?.session_id) {
      return { kind: "resume", title: home.continueTask, detail: stageLabel(Number(summary?.operational_stage || 0)), label: home.continueTask, sessionId: recovery.session_id };
    }
    const selection = window.iClubExamPrepWeeklyFlowEnabled === true
      ? weeklyPlanSelection(component, plan, weeklyProgress)
      : planSelection(plan);
    if (selection.ready) {
      const area = trackerAreaForSkill(tracker, selection.ready.skill_code);
      const title = area ? componentAreaLabel(area.official_syllabus_section) : itemTypeLabel(selection.ready.item_type);
      const labels = { learning: home.startTask, correction: home.fixTask, retest: home.retestTask, mixed_transfer: home.mixedTask };
      return { kind: "task", title, detail: itemTypeLabel(selection.ready.item_type), label: labels[selection.ready.item_type] || home.startTask, planId: plan?.plan_id || null, priorityOrder: Number(selection.ready.priority_order || 0) };
    }
    if (selection.waiting) {
      const area = trackerAreaForSkill(tracker, selection.waiting.skill_code);
      return { kind: "waiting", title: area ? componentAreaLabel(area.official_syllabus_section) : home.waiting, detail: selection.waiting.due_at ? `${home.waiting} · ${formatDateTime(selection.waiting.due_at)}` : home.waiting, label: home.waiting };
    }
    const stage = Number(summary?.operational_stage || 0);
    if (stage >= 4) return { kind: "timed", title: home.timed, detail: stageLabel(stage), label: home.timedTask };
    return { kind: "prepare", title: home.checkNext, detail: stageLabel(stage), label: home.startTask };
  }

  function topicsMarkup(tracker) {
    const home = componentHomeCopy();
    const areas = Array.isArray(tracker?.areas) ? tracker.areas : [];
    if (!areas.length) return `<div class="ep-component-empty">—</div>`;
    return areas.map(area => {
      const skills = Array.isArray(area?.skills) ? area.skills : [];
      const total = Number(area?.skill_count || skills.length || 0), covered = Number(area?.coverage_count || 0);
      const skillRows = skills.map(skill => `<button class="ep-component-skill" type="button" data-ep-component-skill="${esc(skill.skill_code)}"><span>${esc(home.skill)} ${Number(skill.sequence_no || 0)}</span><small>${esc(skillStateLabel(skill))}</small></button>`).join("");
      return `<details class="ep-component-area"><summary><span>${esc(componentAreaLabel(area.official_syllabus_section))}</span><strong>${covered} / ${total}</strong></summary><div class="ep-component-skill-list">${skillRows}</div></details>`;
    }).join("");
  }

  function renderComponentHome(component, payload) {
    clearTimer();
    const root = rootEl(); if (!root) return;
    const c = copy(), home = componentHomeCopy(), summary = componentSummary(component, payload.state);
    const stage = Number(summary?.operational_stage || 0);
    const tracker = payload.tracker || {};
    const denominator = Number(tracker?.denominator_count || (component === "P1" ? 45 : 36));
    const covered = Number(tracker?.coverage_count || 0);
    const coverage = Number(tracker?.coverage_pct ?? summary?.coverage_pct ?? 0);
    const corrections = Number(payload.queue?.active_count || 0);
    const diagnosticComplete = payload.progress?.stage0_complete === true;
    const action = primaryAction(component, payload.progress, summary, tracker, payload.plan, payload.recovery, payload.weeklyProgress);
    const componentName = component === "P1" ? c.componentP1 : c.componentP5;
    const attention = diagnosticComplete && corrections > 0 ? `<button class="ep-component-link" type="button" data-ep-component-link="corrections"><span><strong>${esc(home.attention)}</strong><small>${corrections}</small></span><span aria-hidden="true">›</span></button>` : "";
    const timed = stage >= 2 ? `<button class="ep-component-link" type="button" data-ep-component-link="timed"><span><strong>${esc(home.timed)}</strong><small>${esc(stageLabel(stage))}</small></span><span aria-hidden="true">›</span></button>` : "";
    const readiness = stage >= 5 ? `<button class="ep-component-link" type="button" data-ep-component-link="readiness"><span><strong>${esc(home.readiness)}</strong></span><span aria-hidden="true">›</span></button>` : "";
    const materials = internal.materialsView?.openMaterials ? `<button class="ep-component-link" type="button" data-ep-component-link="materials"><span><strong>${esc(home.materials)}</strong></span><span aria-hidden="true">›</span></button>` : "";
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice" role="status" aria-live="polite">${esc(state.notice)}</div>` : ""}<section class="ep-component-home" data-ep-component-home="${component}"><button class="ep-component-back" type="button" data-ep-component-back>← ${esc(home.back)}</button><header class="ep-component-hero"><div class="ep-live-component-head"><span class="ep-live-component-code">${component}</span><div class="ep-live-component-copy"><strong>${esc(componentName)}</strong><span>${denominator} ${esc(home.skills)}</span></div></div><span class="ep-stage-pill">${esc(c.stageTitle)}: ${esc(stageLabel(stage))}</span></header><section class="ep-component-next"><div class="ep-component-section-label">${esc(home.next)}</div><strong class="ep-component-next-title">${esc(action.title)}</strong><div class="ep-live-meta">${esc(action.detail)}</div><button class="ep-live-btn ep-component-primary" type="button" data-ep-component-primary="${esc(action.kind)}" ${action.kind === "waiting" ? "disabled" : ""}>${esc(action.label)}</button></section><section class="ep-component-progress-card"><div class="ep-component-section-head"><strong>${esc(home.progress)}</strong><span>${covered} / ${denominator}</span></div><div class="ep-live-progress"><span style="width:${Math.max(0, Math.min(100, coverage))}%"></span></div><div class="ep-live-meta">${esc(c.coverage)}: ${coverage.toFixed(0)}%</div></section><section class="ep-component-topics"><div class="ep-component-section-head"><strong>${esc(home.topics)}</strong><span>${Array.isArray(tracker?.areas) ? tracker.areas.length : 0}</span></div>${topicsMarkup(tracker)}</section><section class="ep-component-links">${attention}${timed}${readiness}${materials}</section></section>`, { compact: true });
    state.notice = null;
    root.querySelector("[data-ep-component-back]")?.addEventListener("click", renderDashboard);
    root.querySelector("[data-ep-component-primary]")?.addEventListener("click", () => handleComponentPrimary(component, action));
    root.querySelectorAll("[data-ep-component-skill]").forEach(button => button.addEventListener("click", () => internal.learnerViews?.openSkill?.(component, button.dataset.epComponentSkill)));
    root.querySelector('[data-ep-component-link="corrections"]')?.addEventListener("click", () => internal.learnerViews?.openCorrections?.(component));
    root.querySelector('[data-ep-component-link="timed"]')?.addEventListener("click", () => openTimed(component));
    root.querySelector('[data-ep-component-link="readiness"]')?.addEventListener("click", () => openReadiness(component));
    root.querySelector('[data-ep-component-link="materials"]')?.addEventListener("click", () => internal.materialsView?.openMaterials?.(component));
  }

  async function openComponentHome(component) {
    if (state.busy || !["P1", "P5"].includes(component)) return;
    state.busy = true; renderLoading();
    const flow = window.iClubExamPrepWeeklyFlowEnabled === true ? internal.weeklyFlowApi : null;

    // These two reads rebuild placement projections on the server. Running them
    // together can make the same learner state compete with itself and produce
    // transient 409/500 responses. Keep them ordered, then load the purely
    // supplemental component data in parallel.
    const progressResult = await internal.api.diagnosticProgress(component);
    if (!progressResult?.ok) { state.busy = false; renderError(); return; }
    const stateResult = await internal.api.getState(component);
    if (!stateResult?.ok) { state.busy = false; renderError(); return; }
    const [trackerResult, queueResult, planResult, recoveryResult] = await Promise.all([
      typeof internal.api.syllabusTracker === "function" ? internal.api.syllabusTracker(component).catch(() => null) : Promise.resolve(null),
      typeof internal.api.correctionQueue === "function" ? internal.api.correctionQueue(component).catch(() => null) : Promise.resolve(null),
      typeof internal.api.weeklyPlan === "function" ? internal.api.weeklyPlan(component).catch(() => null) : Promise.resolve(null),
      flow?.version === "weekly_flow_adapter_v1" ? flow.recover(component).catch(() => null) : Promise.resolve(null)
    ]);
    const weeklyProgressResult = flow?.version === "weekly_flow_adapter_v1" &&
      typeof internal.progressUxApi?.progress === "function"
      ? await internal.progressUxApi.progress(component).catch(() => null)
      : null;
    state.busy = false;
    state.progress[component] = progressResult.data;
    state.componentState[component] = stateResult.data;
    renderComponentHome(component, {
      progress: progressResult.data, state: stateResult.data,
      tracker: trackerResult?.ok ? trackerResult.data : null,
      queue: queueResult?.ok ? queueResult.data : null,
      plan: planResult?.ok ? planResult.data : null,
      recovery: recoveryResult?.ok ? recoveryResult.data : null,
      weeklyProgress: weeklyProgressResult?.ok ? weeklyProgressResult.data : null
    });
  }

  async function prepareAndLaunch(component) {
    if (state.busy) return;
    state.busy = true; renderLoading();
    let plan = null;
    let weeklyProgress = null;
    if (window.iClubExamPrepWeeklyFlowEnabled === true) {
      const flow = internal.weeklyFlowApi;
      if (!flow || flow.version !== "weekly_flow_adapter_v1" || flow.allowed(component)) {
        state.busy = false; renderError(); return;
      }
      const ensured = await flow.plan(component);
      if (!ensured?.ok) { state.busy = false; renderError(); return; }
      if (ensured.data?.status === "resume_first") {
        const recovery = ensured.data.recovery;
        state.busy = false;
        if (!["resume", "ready_to_finalize"].includes(recovery?.status) || !recovery?.session_id) { renderError(); return; }
        state.returnView = { kind: "component", component };
        await loadSession(recovery.session_id); return;
      }
      const read = await internal.api.weeklyPlan(component);
      if (!read?.ok || !read.data?.plan_id || read.data.plan_id !== ensured.data?.plan_id) {
        state.busy = false; renderError(); return;
      }
      plan = read.data;
      if (typeof internal.progressUxApi?.progress !== "function") {
        state.busy = false; renderError(); return;
      }
      const progress = await internal.progressUxApi.progress(component);
      if (!progress?.ok) { state.busy = false; renderError(); return; }
      weeklyProgress = progress.data;
    } else {
      let read = await internal.api.weeklyPlan(component);
      if (!read?.ok) { state.busy = false; renderError(); return; }
      plan = read.data;
      if (!plan?.plan_id) {
        const generated = await internal.api.generateWeeklyPlan(component, "normal");
        if (!generated?.ok) { state.busy = false; renderError(); return; }
        read = await internal.api.weeklyPlan(component);
        if (!read?.ok) { state.busy = false; renderError(); return; }
        plan = read.data;
      }
    }
    const selection = window.iClubExamPrepWeeklyFlowEnabled === true
      ? weeklyPlanSelection(component, plan, weeklyProgress)
      : planSelection(plan);
    state.busy = false;
    if (selection.ready && plan?.plan_id) {
      await launchPlanItem(component, plan.plan_id, Number(selection.ready.priority_order), "component");
      return;
    }
    state.notice = componentHomeCopy().noAvailable;
    await openComponentHome(component);
  }

  async function handleComponentPrimary(component, action) {
    if (state.busy || !action) return;
    if (action.kind === "diagnostic") { await startDiagnostic(component, "component"); return; }
    if (action.kind === "resume" && action.sessionId) {
      state.returnView = { kind: "component", component };
      await loadSession(action.sessionId); return;
    }
    if (action.kind === "task" && action.planId && action.priorityOrder > 0) {
      await launchPlanItem(component, action.planId, action.priorityOrder, "component"); return;
    }
    if (action.kind === "timed") { await openTimed(component); return; }
    if (action.kind === "prepare") await prepareAndLaunch(component);
  }

  async function renderDashboard() {
    clearTimer();
    const root = rootEl(); if (!root) return; renderLoading();

    // diagnosticProgress/getState are state-bearing reads: both rebuild the
    // learner placement projection. Serializing P1/P5 prevents cross-request
    // contention that can otherwise surface as transient 409/500 responses.
    const p1 = await internal.api.diagnosticProgress("P1");
    if (!p1?.ok) { renderError(); return; }
    const s1 = await internal.api.getState("P1");
    if (!s1?.ok) { renderError(); return; }
    const p5 = await internal.api.diagnosticProgress("P5");
    if (!p5?.ok) { renderError(); return; }
    const s5 = await internal.api.getState("P5");
    if (!s5?.ok) { renderError(); return; }
    state.progress.P1 = p1.data; state.progress.P5 = p5.data; state.componentState.P1 = s1.data; state.componentState.P5 = s5.data;
    const c = copy();
    const totalHours = Number(state.profile?.total_student_hours_available || 0), mathHours = Number(state.profile?.mathematics_hours_budget || 0);
    const profileBits = [
      state.profile?.exam_series || "",
      state.profile?.target_grade ? `${c.targetShort}: ${state.profile.target_grade}` : "",
      totalHours > 0 ? `${c.totalShort}: ${totalHours} ${c.hoursShort}` : "",
      mathHours > 0 ? `${c.mathShort}: ${mathHours} ${c.hoursShort}` : ""
    ].filter(Boolean);
    const profileLine = profileBits.join(" · ");
    const profileBadge = profileLine ? `<div class="ep-live-dashboard-profile"><strong>${esc(c.profileSaved)}</strong><span>${esc(profileLine)}</span></div>` : "";
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice" role="status" aria-live="polite">${esc(state.notice)}</div>` : ""}<section class="ep-live-dashboard-intro"><div><div class="ep-live-dashboard-eyebrow">${esc(c.dashboardEyebrow)}</div><h3 class="ep-live-dashboard-title">${esc(c.dashboardTitle)}</h3><p class="ep-live-dashboard-text">${esc(c.dashboardText)}</p></div>${profileBadge}</section><div class="ep-live-grid">${componentCard("P1", p1.data, s1.data)}${componentCard("P5", p5.data, s5.data)}</div>`, { compact: true });
    state.notice = null;
    root.querySelectorAll("[data-ep-live-open-component]").forEach(card => card.addEventListener("click", () => openComponentHome(card.dataset.epLiveOpenComponent)));
    root.querySelectorAll("[data-ep-live-start]").forEach(b => b.addEventListener("click", () => startDiagnostic(b.dataset.epLiveStart)));
    root.querySelectorAll("[data-ep-live-plan]").forEach(b => b.addEventListener("click", () => openPlan(b.dataset.epLivePlan)));
    root.querySelectorAll("[data-ep-live-timed]").forEach(b => b.addEventListener("click", () => openTimed(b.dataset.epLiveTimed)));
    root.querySelectorAll("[data-ep-live-readiness]").forEach(b => b.addEventListener("click", () => openReadiness(b.dataset.epLiveReadiness)));
  }

  async function startDiagnostic(component, returnKind = "dashboard") {
    if (state.busy) return; state.busy = true; renderLoading();
    const result = await internal.api.startNextDiagnostic(component, key(`ep-check-${component.toLowerCase()}`)); state.busy = false;
    if (!result?.ok || !result.data?.session_id) { renderError(); return; }
    state.returnView = { kind: returnKind, component }; await loadSession(result.data.session_id);
  }

  function itemTypeLabel(type) {
    const c = copy(); return ({ learning: c.learning, correction: c.correction, retest: c.retest, mixed_transfer: c.mixed, rebaseline: c.rebaseline })[type] || c.learning;
  }

  async function openPlan(component) {
    clearTimer(); renderLoading();
    // The new weekly flow is an explicit OFF-by-default cutover. Never fall back to
    // a plan-changing legacy RPC if its audited server contract is unavailable.
    if (window.iClubExamPrepWeeklyFlowEnabled === true) {
      const flow = internal.weeklyFlowApi;
      if (!flow || flow.version !== 'weekly_flow_adapter_v1' || flow.allowed(component)) {
        renderError(); return;
      }
      const ensured = await flow.plan(component);
      if (!ensured?.ok) { renderError(); return; }
      if (ensured.data?.status === 'resume_first') {
        const recovery = ensured.data.recovery;
        if (!['resume','ready_to_finalize'].includes(recovery?.status) || !recovery?.session_id) {
          renderError(); return;
        }
        state.returnView = { kind: 'plan', component };
        await loadSession(recovery.session_id);
        return;
      }
      const read = await internal.api.weeklyPlan(component);
      if (!read?.ok || !read.data?.plan_id || read.data.plan_id !== ensured.data?.plan_id) {
        renderError(); return;
      }
      renderPlan(component, read.data);
      return;
    }
    let planResult = await internal.api.weeklyPlan(component);
    if (!planResult?.ok) { renderError(); return; }
    let plan = planResult.data;
    if (!plan?.plan_id) {
      const generated = await internal.api.generateWeeklyPlan(component, "normal");
      if (!generated?.ok) { renderError(); return; }
      planResult = await internal.api.weeklyPlan(component); plan = planResult?.data;
    }
    if (!planResult?.ok || !plan?.plan_id) { renderError(copy().noPlan); return; }
    renderPlan(component, plan);
  }

  function renderPlan(component, plan) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy(); const items = Array.isArray(plan.items) ? plan.items : [];
    const rows = items.length ? items.map(item => {
      const due = item.due_at ? new Date(item.due_at) : null;
      const future = item.item_type === "retest" && due && due.getTime() > Date.now();
      const actionable = ["learning","correction","retest","mixed_transfer"].includes(item.item_type) && item.status === "pending";
      const button = actionable ? `<button class="ep-live-btn" type="button" data-ep-live-plan-item="${Number(item.priority_order)}" ${future ? "disabled" : ""}>${esc(future ? c.notDue : c.startTask)}</button>` : "";
      return `<div class="ep-live-plan-item"><div><strong>${esc(itemTypeLabel(item.item_type))}</strong>${due ? `<div class="ep-live-due">${esc(formatDateTime(due))}</div>` : ""}</div>${button}</div>`;
    }).join("") : `<div class="ep-live-notice">${esc(c.noPlan)}</div>`;
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice" role="status" aria-live="polite">${esc(state.notice)}</div>` : ""}<div class="ep-live-card"><div class="ep-live-head"><div><strong>${component} · ${esc(c.plan)}</strong><div class="ep-live-meta">${esc(c.week)} ${Number(plan.active_week_no || 1)}</div></div><button class="ep-live-btn secondary" type="button" data-ep-live-dashboard>${esc(c.overview)}</button></div>${rows}</div>`);
    state.notice = null;
    root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard);
    root.querySelectorAll('[data-ep-live-plan-item]').forEach(b => b.addEventListener('click', () => launchPlanItem(component, plan.plan_id, Number(b.dataset.epLivePlanItem))));
  }

  async function launchPlanItem(component, planId, priorityOrder, returnKind = "plan") {
    if (state.busy) return; state.busy = true; renderLoading();
    if (window.iClubExamPrepWeeklyFlowEnabled === true) {
      const flow = internal.weeklyFlowApi;
      const progress = typeof internal.progressUxApi?.progress === 'function'
        ? await internal.progressUxApi.progress(component) : null;
      const matching = Array.isArray(progress?.data?.goals) ? progress.data.goals.filter(goal =>
        goal.component_code === component && goal.action_priority_order === priorityOrder &&
        weeklyGoalCanAct(component, goal)) : [];
      if (!flow || flow.allowed(component) || !progress?.ok || matching.length !== 1) {
        state.busy = false; renderError(); return;
      }
      const selected = matching[0];
      const authorization = await flow.authorize(component, selected.goal_id, planId);
      if (!authorization?.ok) { state.busy = false; renderError(); return; }
      if (authorization.data?.status === 'resume_existing_session_first' || authorization.data?.status === 'resume') {
        const sessionId = authorization.data?.recovery?.session_id || authorization.data?.session_id;
        state.busy = false;
        if (!sessionId) { renderError(); return; }
        state.returnView = { kind: returnKind, component }; await loadSession(sessionId); return;
      }
      if (authorization.data?.status !== 'authorized' || !authorization.data?.authorization_id) {
        state.busy = false;
        const seen = authorization.data?.status === 'content_exhausted';
        renderError(seen ? ({ ru:'Этот набор уже выполнен. Для новой проверки нужны другие задания. Предыдущие ответы сохранены.',
          uz:'Bu savollar avval bajarilgan. Yangi tekshiruv uchun boshqa topshiriqlar kerak. Oldingi javoblar saqlangan.',
          en:'You have already completed these questions. A new check needs different questions. Your earlier answers are saved.' })[state.language] : null);
        return;
      }
      const started = await flow.start(component, authorization.data.authorization_id, key('ep-plan-session'));
      state.busy = false;
      const sessionId = started?.ok ? started.data?.session_id :
        (started?.reason === 'start_outcome_unknown' ? started.recovery?.session_id : null);
      if (!sessionId || (started?.ok && !['started','resume','resume_existing_session_first'].includes(started.data?.status))) {
        renderError(); return;
      }
      state.returnView = { kind: returnKind, component };
      await loadSession(sessionId);
      return;
    }
    const auth = await internal.api.authorizePlanItem(planId, priorityOrder);
    if (!auth?.ok || !auth.data?.authorization_id) { state.busy = false; renderError(); return; }
    const started = await internal.api.startSession(auth.data.authorization_id, key("ep-plan-session")); state.busy = false;
    if (!started?.ok || !started.data?.session_id) { renderError(); return; }
    state.returnView = { kind: returnKind, component }; await loadSession(started.data.session_id);
  }

  async function openTimed(component) {
    clearTimer(); renderLoading();
    const result = await internal.api.timedCatalog(component);
    if (!result?.ok) { renderError(); return; }
    renderTimedCatalog(component, result.data);
  }

  function renderTimedCatalog(component, payload) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy(); const rows = Array.isArray(payload?.assessments) ? payload.assessments : [];
    const body = rows.length ? rows.map(row => `<div class="ep-live-timed-row"><div><strong>${esc(assessmentTitle(row))}</strong><div class="ep-live-meta">${Number(row.marks_available || 0)} ${esc(c.marks)} · ${minutes(row.time_limit_sec)} ${esc(c.minutes)}</div></div><button class="ep-live-btn" type="button" data-ep-live-timed-start="${Number(row.assessment_id)}">${esc(c.startTimed)}</button></div>`).join("") : `<div class="ep-live-notice">${esc(c.noTimed)}</div>`;
    root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><strong>${component} · ${esc(c.timed)}</strong><button class="ep-live-btn secondary" type="button" data-ep-live-dashboard>${esc(c.overview)}</button></div>${body}</div>`);
    root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard);
    root.querySelectorAll('[data-ep-live-timed-start]').forEach(b => b.addEventListener('click', () => startTimed(component, Number(b.dataset.epLiveTimedStart))));
  }

  async function startTimed(component, assessmentId) {
    if (state.busy) return; state.busy = true; renderLoading();
    const auth = await internal.api.authorizeTimed(assessmentId);
    if (!auth?.ok || !auth.data?.authorization_id) { state.busy = false; renderError(); return; }
    const started = await internal.api.startSession(auth.data.authorization_id, key("ep-timed-session")); state.busy = false;
    if (!started?.ok || !started.data?.session_id) { renderError(); return; }
    state.returnView = { kind: "timed", component }; await loadSession(started.data.session_id);
  }

  function deadlineMs(session) {
    const value = session?.timing_contract?.deadline_at; const ms = value ? new Date(value).getTime() : NaN;
    return Number.isFinite(ms) ? ms : null;
  }

  function startTimer(sessionId) {
    clearTimer(); const deadline = deadlineMs(state.session); if (!deadline) return;
    const tick = async () => {
      const left = Math.max(0, Math.ceil((deadline - Date.now()) / 1000));
      const el = rootEl()?.querySelector('[data-ep-live-timer]');
      if (el) el.textContent = `${copy().timeLeft}: ${String(Math.floor(left / 60)).padStart(2, "0")}:${String(left % 60).padStart(2, "0")}`;
      if (left <= 0) {
        clearTimer();
        if (!state.busy && state.session?.session_id === sessionId && ["timed","paper"].includes(state.session?.session_type)) await finishTimed("time_expired");
      }
    };
    tick(); state.timerId = setInterval(tick, 1000);
  }

  async function loadSession(sessionId) {
    clearTimer(); renderLoading(); const result = await internal.api.getSession(sessionId, state.language);
    if (!result?.ok) { renderError(); return; }
    state.session = result.data;
    const items = Array.isArray(state.session?.items) ? state.session.items : [], next = items.find(item => item && item.answered !== true);
    const timed = ["timed","paper"].includes(state.session?.session_type);
    if (timed && state.session?.status === "active" && deadlineMs(state.session) && Date.now() >= deadlineMs(state.session)) { await finishTimed("time_expired"); return; }
    if (!next && state.session?.status === "active") {
      if (timed) { await finishTimed("submitted"); return; }
      const finalized = await internal.api.finalizeSession(sessionId, key("ep-session-finalize"));
      if (!finalized?.ok) { renderError(); return; }
      const finishedType = state.session.session_type, component = state.session.component_code;
      state.session = null;
      if (finishedType === "diagnostic") {
        state.notice = copy().finish;
        if (state.returnView?.kind === "component") await openComponentHome(component);
        else await renderDashboard();
      } else {
        if (window.iClubExamPrepWeeklyFlowEnabled !== true) {
          await internal.api.generateWeeklyPlan(component, "normal");
          state.notice = copy().completedTask;
        } else {
          state.notice = ({ ru:'Занятие сохранено. Недельный план не изменён.',
            uz:'Mashg‘ulot saqlandi. Haftalik reja o‘zgarmadi.',
            en:'Session saved. Your weekly plan has not changed.' })[state.language];
        }
        if (state.returnView?.kind === "component") await openComponentHome(component);
        else await openPlan(component);
      }
      return;
    }
    if (!next) {
      state.session = null;
      if (state.returnView?.kind === "component") await openComponentHome(state.returnView.component);
      else if (state.returnView?.kind === "plan") await openPlan(state.returnView.component);
      else if (state.returnView?.kind === "timed") await openTimed(state.returnView.component);
      else await renderDashboard();
      return;
    }
    state.itemStartedAt = Date.now(); renderQuestion(next, items, timed);
  }

  function renderQuestion(item, items, timed = false) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy(), answered = items.filter(x => x?.answered === true).length, total = items.length;
    let answerControl = "";
    if (item.item_kind === "written") {
      answerControl = `<label class="ep-live-field"><span>${esc(c.written)}</span><textarea class="ep-live-textarea" name="ep_live_written_answer"></textarea></label>`;
    } else if (String(item.qtype || "").toLowerCase() === "mcq" && Array.isArray(item.options)) {
      answerControl = `<div class="ep-live-options">${item.options.map((option, index) => `<label class="ep-live-option"><input type="radio" name="ep_live_answer" value="${index}"><span>${esc(option)}</span></label>`).join("")}</div>`;
    } else answerControl = `<input class="ep-live-input" name="ep_live_text_answer" autocomplete="off" aria-label="${esc(c.submit)}">`;
    const timer = timed ? `<span class="ep-live-timer" data-ep-live-timer></span>` : "";
    const exit = timed ? `<button class="ep-live-btn secondary" type="button" data-ep-live-end>${esc(c.endAttempt)}</button>` : `<button class="ep-live-btn secondary" type="button" data-ep-live-exit>${esc(c.back)}</button>`;
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice" role="status" aria-live="polite">${esc(state.notice)}</div>` : ""}<div class="ep-live-card ep-live-question-card"><div class="ep-live-head"><strong>${esc(c.question)} ${answered + 1} / ${total}</strong>${timer}</div><div class="ep-live-qtext">${esc(item.text || item.written_prompt || "")}</div>${answerControl}<div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-live-submit>${esc(c.submit)}</button>${exit}</div></div>`, { compact: true });
    state.notice = null;
    root.querySelector('[data-ep-live-submit]')?.addEventListener('click', () => submitAnswer(item));
    root.querySelector('[data-ep-live-exit]')?.addEventListener('click', async () => {
      state.session = null;
      if (state.returnView?.kind === "component") await openComponentHome(state.returnView.component);
      else if (state.returnView?.kind === "plan") await openPlan(state.returnView.component);
      else await renderDashboard();
    });
    root.querySelector('[data-ep-live-end]')?.addEventListener('click', async () => { if (window.confirm(c.endConfirm)) await finishTimed("administrative_stop"); });
    if (timed) startTimer(state.session.session_id);
  }

  // The guarded weekly route never discards a learner's answer before the
  // server confirms persistence. Read-only reconciliation precedes any retry.
  function answerRecoveryCopy() {
    return ({
      ru: { saving:'Сохраняем ответ…', saved:'Ответ сохранён.', uncertain:'Не удалось подтвердить сохранение. Ваш ответ остаётся на экране. Пока статус не подтверждён, не закрывайте эту страницу.', retryReady:'Сервер пока не показывает сохранённый ответ. Можно повторно отправить ТОТ ЖЕ ответ; другая попытка не создаётся.', check:'Проверить сохранение', retry:'Повторить отправку' },
      uz: { saving:'Javob saqlanmoqda…', saved:'Javob saqlandi.', uncertain:'Javob saqlangani tasdiqlanmadi. Javobingiz ekranda qoldi. Holat aniqlanmaguncha sahifani yopmang.', retryReady:'Server hali saqlangan javobni ko‘rsatmayapti. AYNAN shu javobni qayta yuborishingiz mumkin; yangi urinish ochilmaydi.', check:'Saqlanganini tekshirish', retry:'Qayta yuborish' },
      en: { saving:'Saving answer…', saved:'Answer saved.', uncertain:'We could not confirm that your answer was saved. It remains on screen. Please keep this page open until its status is confirmed.', retryReady:'The server does not show a saved answer yet. You may resend the SAME answer without starting a new attempt.', check:'Check saved answer', retry:'Resend same answer' }
    })[state.language] || answerRecoveryCopyFallback();
  }

  function answerRecoveryCopyFallback() {
    return { saving:'Saving answer…', saved:'Answer saved.', uncertain:'Answer status is not confirmed. Keep this page open.', retryReady:'You may resend the same answer.', check:'Check saved answer', retry:'Resend same answer' };
  }

  function showAnswerRecovery(pending) {
    if (state.pendingSubmission !== pending) return;
    const root=rootEl(), card=root?.querySelector('.ep-live-card');
    if (!card) return;
    root.querySelector('.ep-host-shell')?.removeAttribute('aria-busy');
    root.querySelectorAll('input,textarea,select').forEach(control => { control.disabled=true; });
    const submit=root.querySelector('[data-ep-live-submit]');
    if (submit) { submit.disabled=true; submit.hidden=true; submit.removeAttribute('aria-busy'); }
    const exit=root.querySelector('[data-ep-live-exit]');
    if (exit) exit.disabled=true;
    root.querySelector('[data-ep-answer-recovery]')?.remove();
    const content=answerRecoveryCopy();
    const panel=document.createElement('aside');
    panel.dataset.epAnswerRecovery='true';
    panel.className='ep-live-error';
    panel.setAttribute('role','alert');
    const message=document.createElement('p');
    message.textContent=pending.retryAllowed ? content.retryReady : content.uncertain;
    const actions=document.createElement('div');
    actions.className='ep-live-actions';
    const check=document.createElement('button');
    check.type='button'; check.className='ep-live-btn secondary';
    check.dataset.epAnswerCheck='true'; check.textContent=content.check;
    check.disabled=state.busy;
    check.addEventListener('click',() => reconcilePendingAnswer(pending));
    actions.append(check);
    if (pending.retryAllowed) {
      const retry=document.createElement('button');
      retry.type='button'; retry.className='ep-live-btn';
      retry.dataset.epAnswerRetry='true'; retry.textContent=content.retry;
      retry.disabled=state.busy;
      retry.addEventListener('click',() => {
        if (state.busy || state.pendingSubmission !== pending || !pending.retryAllowed) return;
        pending.retryAllowed=false;
        void sendPendingAnswer(pending);
      });
      actions.append(retry);
    }
    panel.append(message,actions);
    card.append(panel);
  }

  async function reconcilePendingAnswer(pending) {
    if (state.busy || state.pendingSubmission !== pending) return;
    state.busy=true;
    showAnswerRecovery(pending);
    let read=null;
    try { read=await internal.api.getSession(pending.sessionId,state.language); } catch (_) {}
    if (state.pendingSubmission !== pending) { state.busy=false; return; }
    const same=read?.ok && read.data?.session_id===pending.sessionId &&
      read.data?.component_code===pending.component;
    const found=same && Array.isArray(read.data.items) ?
      read.data.items.filter(row => Number(row?.item_order)===pending.itemOrder) : [];
    if (found.length===1 && found[0].answered===true) {
      state.pendingSubmission=null;
      state.busy=false;
      state.notice=answerRecoveryCopy().saved;
      await loadSession(pending.sessionId);
      return;
    }
    pending.retryAllowed=Boolean(found.length===1 && found[0].answered===false && read.data.status==='active');
    state.busy=false;
    showAnswerRecovery(pending);
  }

  async function sendPendingAnswer(pending) {
    if (state.busy || state.pendingSubmission !== pending) return;
    state.busy=true;
    const root=rootEl(), submit=root?.querySelector('[data-ep-live-submit]');
    if (submit) { submit.disabled=true; submit.textContent=answerRecoveryCopy().saving; submit.setAttribute('aria-busy','true'); }
    root?.querySelectorAll('[data-ep-answer-check],[data-ep-answer-retry]').forEach(button => { button.disabled=true; });
    let result;
    try {
      result=await internal.api.submitResponse(pending.sessionId,pending.itemOrder,
        pending.payload,pending.idempotencyKey,pending.elapsedMs,state.language);
    } catch (_) { result={ok:false,reason:'unknown_response'}; }
    if (state.pendingSubmission !== pending) { state.busy=false; return; }
    if (result?.ok) {
      state.pendingSubmission=null;
      state.busy=false;
      const data=result.data || {}, c=copy(), parts=[];
      if (typeof data.is_correct==='boolean') parts.push(data.is_correct?c.correct:c.incorrect);
      if (data.diagnostic_feedback) parts.push(data.diagnostic_feedback);
      else if (data.explanation) parts.push(data.explanation);
      if (data.next_action) parts.push(data.next_action);
      state.notice=parts.filter(Boolean).join(' — ');
      await loadSession(pending.sessionId);
      return;
    }
    // This client-only rejection made no RPC; keep all controls editable.
    if (result?.reason==='understanding_checks_incomplete') {
      state.pendingSubmission=null;
      state.busy=false;
      const screen=rootEl();
      screen?.querySelector('.ep-host-shell')?.removeAttribute('aria-busy');
      screen?.querySelectorAll('input,textarea,select').forEach(control=>{control.disabled=false;});
      screen?.querySelector('[data-ep-answer-recovery]')?.remove();
      const button=screen?.querySelector('[data-ep-live-submit]');
      if (button) {button.hidden=false;button.disabled=false;button.removeAttribute('aria-busy');button.textContent=copy().submit;}
      const exit=screen?.querySelector('[data-ep-live-exit]'); if (exit) exit.disabled=false;
      return;
    }
    state.busy=false;
    // The write may have committed even if its acknowledgment vanished. No auto resend.
    await reconcilePendingAnswer(pending);
  }

  async function submitAnswer(item) {
    if (state.busy || !state.session || state.pendingSubmission) return;
    let payload;
    if (item.item_kind === 'written') {
      const value=rootEl()?.querySelector('textarea[name="ep_live_written_answer"]')?.value?.trim();
      if (!value) return; payload={artifact:{text:value}};
    } else if (String(item.qtype || '').toLowerCase()==='mcq') {
      const chosen=rootEl()?.querySelector('input[name="ep_live_answer"]:checked');
      if (!chosen) return; payload={picked_index:Number(chosen.value)};
    } else {
      const value=rootEl()?.querySelector('input[name="ep_live_text_answer"]')?.value?.trim();
      if (!value) return; payload={answer:value};
    }
    // Diagnostic and timed/paper sessions retain their own existing contracts.
    if (window.iClubExamPrepWeeklyFlowEnabled===true && ['plan','component'].includes(state.returnView?.kind)
        && !['diagnostic','timed','paper'].includes(state.session.session_type)) {
      const pending={sessionId:state.session.session_id,component:state.session.component_code,
        itemOrder:Number(item.item_order),payload,idempotencyKey:key('ep-answer'),
        elapsedMs:Math.max(0,Date.now()-state.itemStartedAt),retryAllowed:false};
      state.pendingSubmission=pending;
      await sendPendingAnswer(pending);
      return;
    }
    state.busy=true; clearTimer(); renderLoading();
    const result=await internal.api.submitResponse(state.session.session_id,item.item_order,payload,
      key('ep-answer'),Date.now()-state.itemStartedAt,state.language); state.busy=false;
    if (!result?.ok) { renderError(); return; }
    const data=result.data || {}, c=copy(), parts=[];
    if (typeof data.is_correct==='boolean') parts.push(data.is_correct?c.correct:c.incorrect);
    if (data.diagnostic_feedback) parts.push(data.diagnostic_feedback);
    else if (data.explanation) parts.push(data.explanation);
    if (data.next_action) parts.push(data.next_action);
    state.notice=parts.filter(Boolean).join(' — '); await loadSession(state.session.session_id);
  }

  async function finishTimed(reason) {
    if (state.busy || !state.session) return; const sessionId = state.session.session_id, component = state.session.component_code;
    state.busy = true; clearTimer(); renderLoading();
    const finalized = await internal.api.finalizeTimed(sessionId, key("ep-timed-finalize"), reason); state.busy = false;
    if (!finalized?.ok) { renderError(); return; }
    state.session = null; await openTimedReview(sessionId, component);
  }

  async function openTimedReview(sessionId, component) {
    renderLoading();
    const [review, result] = await Promise.all([internal.api.timedReviewPack(sessionId, state.language), internal.api.timedResult(sessionId)]);
    if (!review?.ok || !result?.ok) { renderError(); return; }
    const items = Array.isArray(review.data?.items) ? review.data.items : [];
    const next = items.find(item => item && item.self_marked !== true);
    if (next) renderSelfReview(sessionId, component, next, items.length, result.data);
    else renderTimedResult(component, result.data);
  }

  function renderSelfReview(sessionId, component, item, total, result) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy();
    const criteria = Array.isArray(item?.rubric?.criteria) ? item.rubric.criteria : [];
    const rubricUnavailable = item?.rubric?.localization_status === "unavailable";
    const rubric = criteria.length
      ? `<div class="ep-live-rubric">${criteria.map(x => `<div class="ep-live-rubric-row">${esc(x.rule || "")} <strong>(${Number(x.marks || 0)})</strong></div>`).join("")}</div>`
      : (rubricUnavailable ? `<div class="ep-live-notice">${esc(c.rubricUnavailable)}</div>` : "");
    root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><div><strong>${esc(c.selfReviewTitle)}</strong><div class="ep-live-meta">${esc(c.selfReviewText)}</div></div><span>${Number(item.item_order)} / ${total}</span></div><div><strong>${esc(c.question)}</strong><div class="ep-live-qtext">${esc(item.prompt || "")}</div></div><div><strong>${esc(c.yourAnswer)}</strong><div class="ep-live-answer">${esc(artifactText(item.learner_artifact))}</div></div><div><strong>${esc(c.rubric)}</strong>${rubric}</div>${item.self_review ? `<div class="ep-live-notice"><strong>${esc(c.selfTip)}:</strong> ${esc(item.self_review)}</div>` : ""}<label class="ep-live-field"><span>${esc(c.award)} (0–${Number(item.max_marks || 0)})</span><input name="ep_live_self_mark" type="number" min="0" max="${Number(item.max_marks || 0)}" step="1"></label><div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-live-save-self>${esc(c.saveMark)}</button></div></div>`);
    root.querySelector('[data-ep-live-save-self]')?.addEventListener('click', async () => {
      const input = rootEl()?.querySelector('input[name="ep_live_self_mark"]'); const marks = Number(input?.value);
      if (!Number.isInteger(marks) || marks < 0 || marks > Number(item.max_marks || 0)) return;
      state.busy = true; renderLoading();
      const saved = await internal.api.submitTimedSelfMark(sessionId, item.item_order, marks, key("ep-self-mark"), null); state.busy = false;
      if (!saved?.ok) { renderError(); return; }
      await openTimedReview(sessionId, component);
    });
  }

  function renderTimedResult(component, result) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy();
    root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><strong>${component} · ${esc(c.result)}</strong><button class="ep-live-btn secondary" type="button" data-ep-live-dashboard>${esc(c.overview)}</button></div><div class="ep-live-stats"><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.inTime)}</span><strong>${Number(result?.marks_in_time || 0)} / ${Number(result?.marks_available || 0)}</strong></div><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.afterTime)}</span><strong>${Number(result?.marks_after_time || 0)}</strong></div><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.unattempted)}</span><strong>${Number(result?.unattempted_marks || 0)}</strong></div></div><div class="ep-live-notice">${esc(c.comparable)}: <strong>${esc(result?.score_comparable ? c.yes : c.no)}</strong></div><div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-live-back-timed>${esc(c.backTimed)}</button><button class="ep-live-btn secondary" type="button" data-ep-live-readiness="${component}">${esc(c.openReadiness)}</button></div></div>`);
    root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard);
    root.querySelector('[data-ep-live-back-timed]')?.addEventListener('click', () => openTimed(component));
    root.querySelector('[data-ep-live-readiness]')?.addEventListener('click', () => openReadiness(component));
  }

  function readinessMessage(data) {
    const c = copy(); const reason = String(data?.reason_code || "");
    return ({
      threshold_configuration_pending: c.thresholdPending,
      three_comparable_attempts_incomplete: c.threePapers,
      stage4_exit_incomplete: c.stage4Incomplete,
      objective_skill_stability_incomplete: c.skillsIncomplete,
      corrective_cycles_open: c.correctionsOpen,
      last_three_below_individual_threshold: c.belowThreshold,
      unattempted_marks_not_minimal: c.unattemptedHigh,
      after_time_dependency_not_closed: c.afterTimeHigh
    })[reason] || c.readyMore;
  }

  async function openReadiness(component) {
    clearTimer(); renderLoading();
    const result = await internal.api.readiness(component);
    if (!result?.ok) { renderError(); return; }
    renderReadiness(component, result.data || {});
  }

  function renderReadiness(component, data) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy(); const ready = data?.ready === true;
    const calibration = ready ? `<button class="ep-live-btn" type="button" data-ep-live-calibration="${component}">${esc(c.openCalibration)}</button>` : "";
    root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><strong>${component} · ${esc(c.readiness)}</strong><button class="ep-live-btn secondary" type="button" data-ep-live-dashboard>${esc(c.overview)}</button></div><div class="ep-live-notice"><strong>${esc(ready ? c.readyStrong : c.readyMore)}</strong><div class="ep-live-meta">${esc(ready ? c.readyStrong : readinessMessage(data))}</div></div><div class="ep-live-stats"><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.readinessPapers)}</span><strong>${Number(data?.last_three_count || 0)}</strong></div><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.readinessSkills)}</span><strong>${Number(data?.below_l3_count || 0)}</strong></div><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.readinessCorrections)}</span><strong>${Number(data?.unresolved_correction_case_count || 0)}</strong></div></div><div class="ep-live-actions">${calibration}</div></div>`);
    root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard);
    root.querySelector('[data-ep-live-calibration]')?.addEventListener('click', () => openCalibration(component));
  }

  function calibrationActionLabel(code) {
    const c = copy();
    return ({ close_recurring_issue:c.actionCloseIssue, short_targeted_work:c.actionShort, timing_and_logistics:c.actionTiming, taper:c.actionTaper })[code] || c.actionShort;
  }

  async function openCalibration(component) {
    clearTimer(); renderLoading();
    const result = await internal.api.finalCalibration(component);
    if (!result?.ok) { renderError(); return; }
    renderCalibration(component, result.data || {});
  }

  function renderCalibration(component, data) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy();
    if (data?.available !== true) {
      root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><strong>${component} · ${esc(c.calibration)}</strong><button class="ep-live-btn secondary" type="button" data-ep-live-dashboard>${esc(c.overview)}</button></div><div class="ep-live-notice">${esc(c.calibrationUnavailable)}</div></div>`);
      root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard); return;
    }
    const actions = Array.isArray(data?.actions) ? data.actions : [];
    const rows = actions.map((a, index) => `<div class="ep-live-action-row"><strong>${index + 1}. ${esc(calibrationActionLabel(a.action_code))}</strong></div>`).join("");
    root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><strong>${component} · ${esc(c.calibration)}</strong><button class="ep-live-btn secondary" type="button" data-ep-live-dashboard>${esc(c.overview)}</button></div>${rows || `<div class="ep-live-notice">${esc(c.calibration)}</div>`}</div>`);
    root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard);
  }

  async function mount(context = {}) {
    state.language = lang(context.language || state.language); if (!canMount()) return false;
    const root = rootEl(); if (!root || root.hidden || root.querySelector('[data-ep-beta-action]')) return false;
    renderLoading(); const profile = await internal.api.examProfile(); if (!profile?.ok) { renderError(); return false; }
    state.profile = profile.data; if (!state.profile) renderProfile(); else await renderDashboard(); return true;
  }
  function reset() { clearTimer(); state.busy = false; state.profile = null; state.progress = { P1: null, P5: null }; state.componentState = { P1: null, P5: null }; state.session = null; state.returnView = null; state.notice = null; state.pendingSubmission = null; }

  function attach() {
    if (attached) return; const host = window.iClubExamPrep;
    if (!host || typeof host.open !== "function") { setTimeout(attach, 0); return; }
    attached = true;
    window.iClubExamPrep = Object.freeze({
      syncSubjectHub: async context => { state.language = lang(context?.language || state.language); const result = await host.syncSubjectHub(context); if (!result) reset(); return result; },
      refreshCapabilities: async () => { const result = await host.refreshCapabilities(); if (host.isOpen() && canMount()) await mount({ language: state.language }); return result; },
      open: async context => { state.language = lang(context?.language || state.language); const result = await host.open(context); if (result && canMount()) await mount(context || {}); return result; },
      back: () => {
        if (rootEl()?.querySelector("[data-ep-component-home]")) { void renderDashboard(); return true; }
        reset(); return host.back();
      }, close: () => { reset(); return host.close(); }, isOpen: () => host.isOpen(), liveFlowVersion: VERSION
    });
  }

  attach();
})();