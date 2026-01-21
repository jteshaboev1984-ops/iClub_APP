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
      reg_header_title: "Registration",
      reg_progress_label: "Setup Profile",
      reg_progress_step: "Step 1 of 2",
      reg_create_title: "Create your account",
      reg_create_subtitle: "Enter your details to join the Cambridge curriculum study in Uzbekistan.",
      reg_full_name_label: "Full Name",
      reg_full_name_placeholder: "e.g. Alisher Navoiy",
      reg_region_label: "Region",
      reg_region_placeholder: "Select your region",
      reg_district_label: "District",
      reg_district_placeholder: "Select your district",
      reg_school_toggle_label: "Are you a school student?",
      reg_school_toggle_hint: "Enable to provide school details",
      reg_school_no_label: "School No.",
      reg_school_no_placeholder: "e.g. 154",
      reg_grade_label: "Grade",
      reg_competitive_subject_label: "Competitive Subject",
      reg_competitive_subject_hint: "Choose your primary focus for the leaderboard",
      reg_terms_text: "I agree to the Terms of Service and consent to processing of my education data.",
      reg_complete_btn: "Complete Registration",
      reg_subjects_limit: "Можно выбрать максимум 2 предмета.",

      not_available: "Недоступно",
      disabled_not_school: "Туры и рейтинги доступны только школьникам.",
      disabled_not_competitive: "Функция доступна только для соревновательного предмета.",
      disabled_tour_dates: "Тур недоступен по датам.",
      ratings_info: "Рейтинг: только Competitive предметы с активными турами. При равных баллах решает время.",
      home_competitive_mode: "Competitive Mode",
      home_competitive_mode_subtitle: "Track your Cambridge curriculum progress",
      home_active_tour: "Active Tour",
      home_pinned_subjects: "Pinned Subjects",
      home_show_all_subjects: "Show All Subjects",
      home_course_completion: "Course Completion",
      home_rank_label: "Rank",
      home_lessons_label: "Lessons",
      home_competitive_empty: "Пока нет соревновательных предметов.",
      home_pinned_empty: "Закрепите предметы в Courses.",
      home_need_registration: "Сначала регистрация.",
      profile_title: "Academic Profile",
      profile_status_badge: "ADVANCED STATUS",
      profile_performance_overview: "Performance Overview",
      profile_stability_score: "Stability Score",
      profile_current_level: "Current Level",
      profile_competitive_slots: "Competitive Slots",
      profile_active_slots_label: "Active",
      profile_earned_credentials: "Earned Credentials",
      profile_recommendations_archive: "My Recommendations Archive",
      profile_view_btn: "VIEW",
      profile_slots_empty: "Нет активных Competitive слотов.",
      profile_slot_hint: "Starts in 2 days",
      profile_level_advanced: "Advanced",
      profile_level_intermediate: "Intermediate",
      profile_level_beginner: "Beginner",

      toast_time_expired_answer_saved: "Время истекло. Ответ сохранён…",
      toast_time_expired_no_answer: "Время истекло. Вопрос сохранён без ответа…",

      practice: "Практика",
      practice_paused: "Практика приостановлена",
      practice_resume: "Продолжить",
      practice_restart: "Начать заново",
      practice_resume_prompt: "Есть незавершённая попытка. Продолжить или начать заново?",

      practice_result_title: "Результат практики",
      practice_review_title: "Разбор ошибок",
      practice_recs_title: "Рекомендации",
      practice_my_recs_title: "Мои рекомендации",
      practice_errors: "Ошибок",
      practice_topics: "Темы",
      practice_saved_to_my_recs: "Рекомендации сохранены в «Мои рекомендации»",
      practice_nothing_to_save: "Нет ошибок — сохранять нечего. Красиво.",

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
      reg_header_title: "Registration",
      reg_progress_label: "Setup Profile",
      reg_progress_step: "Step 1 of 2",
      reg_create_title: "Create your account",
      reg_create_subtitle: "Enter your details to join the Cambridge curriculum study in Uzbekistan.",
      reg_full_name_label: "Full Name",
      reg_full_name_placeholder: "e.g. Alisher Navoiy",
      reg_region_label: "Region",
      reg_region_placeholder: "Select your region",
      reg_district_label: "District",
      reg_district_placeholder: "Select your district",
      reg_school_toggle_label: "Are you a school student?",
      reg_school_toggle_hint: "Enable to provide school details",
      reg_school_no_label: "School No.",
      reg_school_no_placeholder: "e.g. 154",
      reg_grade_label: "Grade",
      reg_competitive_subject_label: "Competitive Subject",
      reg_competitive_subject_hint: "Choose your primary focus for the leaderboard",
      reg_terms_text: "I agree to the Terms of Service and consent to processing of my education data.",
      reg_complete_btn: "Complete Registration",
      reg_subjects_limit: "Ko‘pi bilan 2 ta fan tanlash mumkin.",

      not_available: "Mavjud emas",
      disabled_not_school: "Turlar va reytinglar faqat maktab o‘quvchilari uchun.",
      disabled_not_competitive: "Bu funksiya faqat musobaqa rejimidagi fan uchun.",
      disabled_tour_dates: "Tur sanalar bo‘yicha mavjud emas.",
      ratings_info: "Reyting: faqat Competitive fanlar va faol turlar. Ball teng bo‘lsa, vaqt hal qiladi.",
      home_competitive_mode: "Competitive Mode",
      home_competitive_mode_subtitle: "Track your Cambridge curriculum progress",
      home_active_tour: "Active Tour",
      home_pinned_subjects: "Pinned Subjects",
      home_show_all_subjects: "Show All Subjects",
      home_course_completion: "Course Completion",
      home_rank_label: "Rank",
      home_lessons_label: "Lessons",
      home_competitive_empty: "Hozircha musobaqa fanlari yo‘q.",
      home_pinned_empty: "Courses’da fanlarni biriktiring.",
      home_need_registration: "Avval ro‘yxatdan o‘ting.",
      profile_title: "Academic Profile",
      profile_status_badge: "ADVANCED STATUS",
      profile_performance_overview: "Performance Overview",
      profile_stability_score: "Stability Score",
      profile_current_level: "Current Level",
      profile_competitive_slots: "Competitive Slots",
      profile_active_slots_label: "Active",
      profile_earned_credentials: "Earned Credentials",
      profile_recommendations_archive: "My Recommendations Archive",
      profile_view_btn: "VIEW",
      profile_slots_empty: "Faol Competitive slotlar yo‘q.",
      profile_slot_hint: "Starts in 2 days",
      profile_level_advanced: "Advanced",
      profile_level_intermediate: "Intermediate",
      profile_level_beginner: "Beginner",

      toast_time_expired_answer_saved: "Vaqt tugadi. Javob saqlandi…",
      toast_time_expired_no_answer: "Vaqt tugadi. Savol javobsiz saqlandi…",

      practice: "Amaliyot",
      practice_paused: "Amaliyot to‘xtatildi",
      practice_resume: "Davom ettirish",
      practice_restart: "Qayta boshlash",
      practice_resume_prompt: "Tugallanmagan urinish bor. Davom ettirasizmi yoki qayta boshlaysizmi?",

      practice_result_title: "Amaliyot natijasi",
      practice_review_title: "Xatolar tahlili",
      practice_recs_title: "Tavsiyalar",
      practice_my_recs_title: "Mening tavsiyalarim",
      practice_errors: "Xatolar",
      practice_topics: "Mavzular",
      practice_saved_to_my_recs: "Tavsiyalar «Mening tavsiyalarim»ga saqlandi",
      practice_nothing_to_save: "Xato yo‘q — saqlash shart emas. Zo‘r.",

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
      reg_header_title: "Registration",
      reg_progress_label: "Setup Profile",
      reg_progress_step: "Step 1 of 2",
      reg_create_title: "Create your account",
      reg_create_subtitle: "Enter your details to join the Cambridge curriculum study in Uzbekistan.",
      reg_full_name_label: "Full Name",
      reg_full_name_placeholder: "e.g. Alisher Navoiy",
      reg_region_label: "Region",
      reg_region_placeholder: "Select your region",
      reg_district_label: "District",
      reg_district_placeholder: "Select your district",
      reg_school_toggle_label: "Are you a school student?",
      reg_school_toggle_hint: "Enable to provide school details",
      reg_school_no_label: "School No.",
      reg_school_no_placeholder: "e.g. 154",
      reg_grade_label: "Grade",
      reg_competitive_subject_label: "Competitive Subject",
      reg_competitive_subject_hint: "Choose your primary focus for the leaderboard",
      reg_terms_text: "I agree to the Terms of Service and consent to processing of my education data.",
      reg_complete_btn: "Complete Registration",
      reg_subjects_limit: "You can choose up to 2 subjects.",

      not_available: "Not available",
      disabled_not_school: "Tours and ratings are available only for school students.",
      disabled_not_competitive: "This feature is available only for competitive subjects.",
      disabled_tour_dates: "Tour is not available by dates.",
      ratings_info: "Ratings include competitive subjects with active tours. Ties are resolved by time.",
      home_competitive_mode: "Competitive Mode",
      home_competitive_mode_subtitle: "Track your Cambridge curriculum progress",
      home_active_tour: "Active Tour",
      home_pinned_subjects: "Pinned Subjects",
      home_show_all_subjects: "Show All Subjects",
      home_course_completion: "Course Completion",
      home_rank_label: "Rank",
      home_lessons_label: "Lessons",
      home_competitive_empty: "No competitive subjects yet.",
      home_pinned_empty: "Pin subjects in Courses.",
      home_need_registration: "Please complete registration first.",
      profile_title: "Academic Profile",
      profile_status_badge: "ADVANCED STATUS",
      profile_performance_overview: "Performance Overview",
      profile_stability_score: "Stability Score",
      profile_current_level: "Current Level",
      profile_competitive_slots: "Competitive Slots",
      profile_active_slots_label: "Active",
      profile_earned_credentials: "Earned Credentials",
      profile_recommendations_archive: "My Recommendations Archive",
      profile_view_btn: "VIEW",
      profile_slots_empty: "No active Competitive slots.",
      profile_slot_hint: "Starts in 2 days",
      profile_level_advanced: "Advanced",
      profile_level_intermediate: "Intermediate",
      profile_level_beginner: "Beginner",

      toast_time_expired_answer_saved: "Time is up. Answer saved…",
      toast_time_expired_no_answer: "Time is up. Question saved without an answer…",

      practice: "Practice",
      practice_paused: "Practice paused",
      practice_resume: "Resume",
      practice_restart: "Start over",
      practice_resume_prompt: "You have an unfinished attempt. Resume or start over?",

      practice_result_title: "Practice result",
      practice_review_title: "Review mistakes",
      practice_recs_title: "Recommendations",
      practice_my_recs_title: "My recommendations",
      practice_errors: "Errors",
      practice_topics: "Topics",
      practice_saved_to_my_recs: "Saved to “My recommendations”",
      practice_nothing_to_save: "No mistakes — nothing to save. Nice.",

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
