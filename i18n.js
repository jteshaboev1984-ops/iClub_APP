/* =========================================================
   iClub WebApp — i18n (v1)
   Plain JS dictionary + helper functions
   ========================================================= */

(function () {
  "use strict";

  const DICT = {
    ru: {
      app_name: "iClub",
      loading: "Загрузка…",
      saving: "Сохранение…",
      done: "Готово",
      error_try_again: "Ошибка — попробуйте ещё раз",

      tab_home: "Home",
      tab_courses: "Courses",
      tab_ratings: "Ratings",
      tab_profile: "Profile",

      reg_title: "Регистрация",
      reg_consent: "Я согласен(на) на обработку данных",

      not_available: "Недоступно",
      disabled_not_school: "Туры и рейтинги доступны только школьникам.",
      disabled_not_competitive: "Функция доступна только для соревновательного предмета.",
      disabled_tour_dates: "Тур недоступен по датам.",

      toast_time_expired_answer_saved: "Время истекло. Ответ сохранён…",
      toast_time_expired_no_answer: "Время истекло. Вопрос сохранён без ответа…",

      practice: "Практика",
      practice_paused: "Практика приостановлена",
      practice_resume: "Продолжить",
      practice_restart: "Начать заново",
      practice_resume_prompt: "Есть незавершённая попытка. Продолжить или начать заново?",

      tour_rules_title: "Правила тура",
      tour_rules_accept_required: "Подтвердите согласие с правилами, чтобы начать тур."
    },

    uz: {
      app_name: "iClub",
      loading: "Yuklanmoqda…",
      saving: "Saqlanmoqda…",
      done: "Tayyor",
      error_try_again: "Xatolik — qayta urinib ko‘ring",

      tab_home: "Home",
      tab_courses: "Courses",
      tab_ratings: "Ratings",
      tab_profile: "Profile",

      reg_title: "Ro‘yxatdan o‘tish",
      reg_consent: "Ma’lumotlarimni qayta ishlashga roziman",

      not_available: "Mavjud emas",
      disabled_not_school: "Turlar va reytinglar faqat maktab o‘quvchilari uchun.",
      disabled_not_competitive: "Bu funksiya faqat musobaqa rejimidagi fan uchun.",
      disabled_tour_dates: "Tur sanalar bo‘yicha mavjud emas.",

      toast_time_expired_answer_saved: "Vaqt tugadi. Javob saqlandi…",
      toast_time_expired_no_answer: "Vaqt tugadi. Savol javobsiz saqlandi…",

      practice: "Amaliyot",
      practice_paused: "Amaliyot to‘xtatildi",
      practice_resume: "Davom ettirish",
      practice_restart: "Qayta boshlash",
      practice_resume_prompt: "Tugallanmagan urinish bor. Davom ettirasizmi yoki qayta boshlaysizmi?",

      tour_rules_title: "Tur qoidalari",
      tour_rules_accept_required: "Tur boshlash uchun qoidalarga rozilikni tasdiqlang."
    },

    en: {
      app_name: "iClub",
      loading: "Loading…",
      saving: "Saving…",
      done: "Done",
      error_try_again: "Error — please try again",

      tab_home: "Home",
      tab_courses: "Courses",
      tab_ratings: "Ratings",
      tab_profile: "Profile",

      reg_title: "Registration",
      reg_consent: "I agree to data processing",

      not_available: "Not available",
      disabled_not_school: "Tours and ratings are available only for school students.",
      disabled_not_competitive: "This feature is available only for competitive subjects.",
      disabled_tour_dates: "Tour is not available by dates.",

      toast_time_expired_answer_saved: "Time is up. Answer saved…",
      toast_time_expired_no_answer: "Time is up. Question saved without an answer…",

      practice: "Practice",
      practice_paused: "Practice paused",
      practice_resume: "Resume",
      practice_restart: "Start over",
      practice_resume_prompt: "You have an unfinished attempt. Resume or start over?",

      tour_rules_title: "Tour rules",
      tour_rules_accept_required: "Please accept the rules to start the tour."
    }
  };

  // --- language state (default: Telegram language_code -> ru fallback)
  let currentLang = "ru";

  function normalizeLang(code) {
    const c = String(code || "").toLowerCase();
    if (c.startsWith("uz")) return "uz";
    if (c.startsWith("en")) return "en";
    if (c.startsWith("ru")) return "ru";
    return "ru";
  }

  // Simple templating: t("key", {name:"..."})
  function template(str, vars) {
    if (!vars) return str;
    return String(str).replace(/\{(\w+)\}/g, (_, k) => {
      const v = vars[k];
      return v === undefined || v === null ? "" : String(v);
    });
  }

  function t(key, vars) {
    const langPack = DICT[currentLang] || DICT.ru;
    const ruPack = DICT.ru;
    const raw = (langPack && langPack[key]) || (ruPack && ruPack[key]) || key;
    return template(raw, vars);
  }

  function setLang(code) {
    currentLang = normalizeLang(code);
    document.documentElement.lang = currentLang;
    // Optional: update static labels if needed later
  }

  function getLang() {
    return currentLang;
  }

  // Expose to global scope for app.js
  window.i18n = {
    t,
    setLang,
    getLang,
    normalizeLang
  };

})();

