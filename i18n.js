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
      ratings_subject: "Предмет",
      ratings_tour: "Тур",
      ratings_all_tours: "Все туры",
      ratings_viewer_hint: "Рейтинг доступен для просмотра. “Мой ранг” показывается только участникам (Competitive).",
      ratings_search_placeholder: "Поиск...",
      ratings_search_hint_inline: "Поиск по имени, школе, классу, региону или району",
      ratings_info_title: "О рейтинге",
      ratings_info_text1: "Рейтинг доступен для просмотра всем пользователям.",
      ratings_info_text2: "“Мой ранг” показывается только участникам Competitive.",
      ratings_info_text3: "Сортировка: больше баллов выше; при равенстве — меньшее время выше.",
      done: "Готово",
      error_try_again: "Ошибка — попробуйте ещё раз",

      lang_ru: "Русский",
      lang_uz: "O‘zbek",
      lang_en: "English",

      reg_language_label: "Язык",
      reg_language_hint: "Далее этот язык используется для практики, туров и сертификатов.",
      reg_language_reset_note: "Важно: смена языка после регистрации сбросит прогресс.",
 
      tab_home: "Home",
      tab_courses: "Courses",
      tab_ratings: "Ratings",
      tab_profile: "Profile",

      reg_title: "Регистрация",
      reg_consent: "Я согласен(на) на обработку данных",
      reg_header_title: "Регистрация",
      reg_progress_label: "Заполнение профиля",
      reg_progress_step: "Шаг 1 из 2",

      reg_create_title: "Создайте аккаунт",
      reg_create_subtitle: "Введите данные, чтобы участвовать в обучении по Cambridge curriculum в Узбекистане.",

      reg_full_name_label: "ФИО",
      reg_full_name_placeholder: "например, Alisher Navoiy",

      reg_region_label: "Регион",
      reg_region_placeholder: "Выберите регион",

      reg_district_label: "Район",
      reg_district_placeholder: "Выберите район",

      reg_school_toggle_label: "Вы ученик школы?",
      reg_school_toggle_hint: "Включите, чтобы указать школу и класс",
      reg_school_no_label: "Школа №",
      reg_school_no_placeholder: "например 154",
      reg_grade_label: "Класс",
      reg_competitive_subject_label: "🎯 Предмет для соревнований",
      reg_competitive_subject_hint: "Он используется для рейтингов и сертификатов",
      reg_nonstudent_title: "Обучение без школьного режима",
      reg_nonstudent_text: "Если вы не ученик школы, вы можете изучать и практиковаться по всем предметам без туров. Подключать и удалять предметы можно позже в профиле.",
 
      reg_subject_primary_tag: "Основной",
      reg_subject_secondary_tag: "Дополнительный",
      reg_subject_summary_none: "Выберите до 2 предметов",

      reg_terms_text: "Я соглашаюсь с условиями и даю согласие на обработку данных об обучении.",
      reg_complete_btn: "Завершить регистрацию",
      reg_subjects_limit: "Можно выбрать максимум 2 предмета.",
      reg_subject_label_competitive: "Competitive Subject",
      reg_subject_hint_competitive: "Выберите основной предмет для рейтинга",
      reg_subject_label_study: "Study Subject",
      reg_subject_hint_study: "Выберите основной предмет для обучения",

      reg_main_subject_required_label: "Основной предмет (обязательно)",
      reg_main_subject_optional_label: "Основной предмет №2 (опционально)",
      reg_add_subject_optional_label: "Дополнительный предмет (опционально)",
      reg_choose_placeholder: "Выберите…",
      reg_choose_none: "Не выбирать",
      reg_select_region: "Выберите регион…",
      reg_select_region_first: "Сначала выберите регион…",
      reg_select_district: "Выберите район…",
      reg_loading_districts: "Загрузка районов…",
      reg_no_districts: "Нет районов",

      subj_informatics: "Информатика",
      subj_economics: "Экономика",
      subj_biology: "Биология",
      subj_chemistry: "Химия",
      subj_mathematics: "Математика",

      competitive_subjects_limit_2: "Лимит competitive-предметов — 2",
      fill_required_fields: "Заполните обязательные поля",

      not_available: "Недоступно",
      disabled_not_school: "Туры и рейтинги доступны только школьникам.",
      disabled_not_competitive: "Функция доступна только для соревновательного предмета.",
      tours_denied_title: "Туры недоступны",
      disabled_not_main: "Туры доступны только для основных предметов.",
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
      profile_stability_score: "Стабильность (7 дней)",
      profile_current_level: "Current Level",
      profile_competitive_slots: "Competitive Slots",
      profile_active_slots_label: "Active",
      profile_earned_credentials: "Earned Credentials",
      cred_none_yet: "Пока нет",
      cred_progress_consistent: "{x} / 7 активных дней",
      cred_progress_focused: "{x} / 5 фокус-сессий подряд",
      cred_progress_practice_attempts: "{x} практик — близко к mastery",
      cred_progress_error_cycles: "{x} / 3 цикла “ошибка → разбор → повтор”",
      cred_progress_research: "Ресурсы: {x} открытия • {y} дней возврата",

      // Earned Credentials (v1.3) — labels
      cred_kicker_progress: "ПРОГРЕСС",
      cred_label_focused: "Фокус-серия",
      cred_label_practice: "Мастерство практики",

      // Earned Credentials (v1.3) — credential names (keys)
      cred_consistent_learner: "Consistent Learner",
      cred_focused_study_streak: "Focused Study Streak",
      cred_active_video_learner: "Active Video Learner",
      cred_practice_mastery_subject: "Practice Mastery",
      cred_error_driven_learner: "Error-Driven Learner",
      cred_research_oriented_learner: "Research-Oriented Learner",
      cred_fair_play_participant: "Fair Play Participant",

      // Earned Credentials (v1.3) — statuses
      cred_status_active: "Активен",
      cred_status_inactive: "Неактивен",
      cred_status_expired: "Серия завершена",
      cred_status_revoked: "Отозван",

      // Earned Credentials (v1.3) — meta
      cred_meta_achieved: "Получено",
      cred_meta_status: "Статус",
      cred_meta_risk: "Риск потери",

      profile_recommendations_archive: "My Recommendations Archive",
      profile_view_btn: "VIEW",
      profile_slots_empty: "Нет активных Competitive слотов.",
      profile_slot_hint: "Starts in 2 days",
      profile_level_advanced: "Advanced",
      profile_level_intermediate: "Intermediate",
      profile_level_beginner: "Beginner",
      profile_stability_no_data: "—",
      profile_stability_no_activity: "No activity",
      profile_certificates_title: "Certificates",
      profile_certificates_row_title: "My certificates",
      profile_certificates_row_sub: "Tours & final results",
      profile_join_btn: "+ JOIN",
      profile_empty_slot: "Empty Competitive Slot",
      profile_settings_more: "More",
      profile_settings_community: "Community",
      profile_settings_about: "About project",

      course_toggle_on: "Включено",
      course_toggle_off: "Выключено",
      course_toggle_aria: "Показывать на главном",

      toast_time_expired_answer_saved: "Время истекло. Ответ сохранён…",
      toast_time_expired_no_answer: "Время истекло. Вопрос сохранён без ответа…",

            // Settings (Profile) — pinned subjects
      settings_competitive_note: "Можно выбрать максимум 2 предмета в Competitive. Сейчас выбрано: {count}/2.",
      settings_hide: "Скрыть",
      settings_show_all: "Показать все",
      settings_pinned: "Закреплён",
      settings_not_pinned: "Не закреплён",
      settings_no_pinned: "Закреплённых предметов пока нет",
      toast_removed_pinned: "Убрано из закреплённых",
      toast_added_pinned: "Добавлено в закреплённые",
      toast_lang_updated: "Язык интерфейса обновлён",

      practice: "Практика",
      practice_subtitle: "10 вопросов • от простого к сложному",
      practice_chip_no_anticheat: "Без античита",
      practice_chip_pause: "Можно прервать",
      practice_chip_best_saved: "Лучший результат сохраняется",

      practice_subject_label: "Предмет",
      practice_best_result: "Лучший результат",
      practice_best_time: "Лучшее время",
      practice_progress: "Прогресс",
      practice_last_attempts: "Последние попытки",
      practice_all: "Все",
      practice_no_attempts: "Пока нет попыток",

      practice_col_date: "Дата",
      practice_col_score: "Счёт",
      practice_col_time: "Время",

      practice_start: "Начать практику",
      practice_time_min_suffix: "м",
      practice_time_sec_suffix: "с",
 
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

      progress_trend: "Тренд прогресса",
      open_tour_btn: "Открыть тур",

      tours_tour_label: "Тур",
      tours_best_result: "Лучший результат",
      tours_best_time: "Время лучшего результата",
      tours_best_time_of_best_result: "Время лучшего результата",

      tours_completed_title: "Пройденные туры",
      tours_completed_empty: "Вы ещё не проходили туры по этому предмету.",
      tours_completed_sub: "Всего: {n}",
      tours_completed_time_label: "время",

      tours_status_title: "Туры пока недоступны",
      tours_status_desc: "Даты и список туров появятся здесь после публикации.",

      tours_status_not_school_title: "Туры доступны только школьникам",
      tours_status_not_school_desc: "Заполните профиль как школьник, чтобы участвовать в турах.",
      tours_only_main_subjects: "Туры доступны только для основных предметов.",
      tours_active_and_completed: "Активные и прошедшие",
    
      tours_status_not_comp_title: "Туры доступны только в соревновательном режиме",
      tours_status_not_comp_desc: "Добавьте предмет в соревновательном режиме, чтобы открыть туры.",
      tours_empty_title: "Туры появятся позже",
      tours_empty_desc: "Этот раздел активируется после подключения базы и публикации дат туров.",
      tours_title: "Туры",
      tours_subtitle: "Активные и прошедшие",
      tours_subject_label: "Предмет",
      tours_fact_questions: "Вопросов",
      tours_fact_attempts: "Попытка",
      tours_fact_attempts_one: "1",
      tours_fact_pause: "Пауза",
      tours_fact_pause_no: "Нет",
      tours_fact_rules: "Контроль",
      tours_fact_rules_on: "Включён",
      tours_tab_active: "Активные",
      tours_tab_past: "Прошедшие",
      tours_archive_btn: "Архив туров",
      to_subject_btn: "К предмету",
      tours_empty_title: "Туры появятся позже",
      tours_empty_desc: "Этот раздел активируется после подключения базы и публикации дат туров.",

      school_prefix: "Школа",
      class_suffix: "класс",

      ratings_my_rank: "МОЙ РАНГ",
      ratings_search_title: "Поиск",
      ratings_search_label: "Имя / школа / класс",
      ratings_search_hint: "Введите часть имени, школы или класса.",
      btn_reset: "Сброс",
      btn_apply: "Применить",
      ratings_out_of: "из",

      ratings_top: "Топ 10",
      ratings_around: "Рядом со мной",
      ratings_bottom: "Нижние 3",
      ratings_out_of: "из",
      ratings_of_total: "из {total}",
      points_short: "бал.", 

      tour_rules_title: "Правила тура",
      tour_rules_accept_required: "Подтвердите согласие с правилами, чтобы начать тур."
    },

    uz: {
      app_name: "iClub",
      loading: "Yuklanmoqda…",
      saving: "Saqlanmoqda…",
      ratings_subject: "Fan",
      ratings_tour: "Tur",
      ratings_all_tours: "Barcha turlar",
      ratings_viewer_hint: "Reytingni ko‘rish mumkin. “Mening o‘rnim” faqat Competitive ishtirokchilar uchun ko‘rsatiladi.",
      ratings_search_placeholder: "Qidirish...",
      ratings_search_hint_inline: "Ism, maktab, sinf, viloyat yoki tuman bo‘yicha qidirish",
      ratings_info_title: "Reyting haqida",
      ratings_info_text1: "Reytingni hamma foydalanuvchi ko‘rishi mumkin.",
      ratings_info_text2: "“Mening o‘rnim” faqat Competitive ishtirokchilar uchun ko‘rsatiladi.",
      ratings_info_text3: "Tartiblash: bal ko‘p bo‘lsa yuqori; teng bo‘lsa — vaqt kam bo‘lsa yuqori.",
 
      done: "Tayyor",
      error_try_again: "Xatolik — qayta urinib ko‘ring",

      lang_ru: "Русский",
      lang_uz: "O‘zbek",
      lang_en: "English",

      reg_language_label: "Til",
      reg_language_hint: "Keyin ushbu til amaliyot, turlar va sertifikatlarda ishlatiladi.",
      reg_language_reset_note: "Muhim: ro‘yxatdan o‘tgandan keyin tilni o‘zgartirish progressni nolga tushiradi.",

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
      reg_competitive_subject_label: "🎯 Reyting fani",
      reg_competitive_subject_hint: "Reyting va sertifikatlar uchun ishlatiladi",
      reg_nonstudent_title: "Maktab rejimisiz o‘qish",
      reg_nonstudent_text: "Agar siz maktab o‘quvchisi bo‘lmasangiz, barcha fanlarni turlarsiz o‘rganish va mashq qilish mumkin. Fanlarni keyin profil orqali qo‘shish yoki olib tashlash mumkin.",
 
      reg_subject_primary_tag: "Asosiy",
      reg_subject_secondary_tag: "Qo‘shimcha",
      reg_subject_summary_none: "2 tagacha fan tanlang",

      reg_terms_text: "I agree to the Terms of Service and consent to processing of my education data.",
      reg_complete_btn: "Complete Registration",
      reg_subjects_limit: "Ko‘pi bilan 2 ta fan tanlash mumkin.",
      reg_subject_label_competitive: "Raqobat fani",
      reg_subject_hint_competitive: "Reyting uchun asosiy fanni tanlang",
      reg_subject_label_study: "O‘quv fani",
      reg_subject_hint_study: "O‘rganish uchun asosiy fanni tanlang",
      reg_select_region: "Viloyatni tanlang…",
      reg_select_region_first: "Avval viloyatni tanlang…",
      reg_select_district: "Tumanni tanlang…",
      reg_loading_districts: "Tumanlar yuklanmoqda…",
      reg_no_districts: "Tumanlar yo‘q",
   
      reg_main_subject_required_label: "Asosiy fan (majburiy)",
      reg_main_subject_optional_label: "Asosiy fan №2 (ixtiyoriy)",
      reg_add_subject_optional_label: "Qo‘shimcha fan (ixtiyoriy)",
      reg_choose_placeholder: "Tanlang…",
      reg_choose_none: "Tanlamaslik",

      subj_informatics: "Informatika",
      subj_economics: "Iqtisodiyot",
      subj_biology: "Biologiya",
      subj_chemistry: "Kimyo",
      subj_mathematics: "Matematika",

      competitive_subjects_limit_2: "Raqobat fanlari limiti — 2 ta",
      fill_required_fields: "Majburiy maydonlarni to‘ldiring",
   
      not_available: "Mavjud emas",
      disabled_not_school: "Turlar va reytinglar faqat maktab o‘quvchilari uchun.",
      disabled_not_competitive: "Bu funksiya faqat musobaqa rejimidagi fan uchun.",
      tours_denied_title: "Turlar mavjud emas",
      disabled_not_main: "Turlar faqat asosiy fanlar uchun mavjud.",
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
      home_pinned_empty: "Home’da ko‘rinishi uchun Courses → Study’da fanlarni biriktiring. Competitive fanlar yuqorida alohida ko‘rsatiladi.",
      home_need_registration: "Avval ro‘yxatdan o‘ting.",
      profile_title: "Academic Profile",
      profile_status_badge: "ADVANCED STATUS",
      profile_performance_overview: "Performance Overview",
      profile_stability_score: "Barqarorlik (7 kun)",
      profile_current_level: "Current Level",
      profile_competitive_slots: "Competitive Slots",
      profile_active_slots_label: "Active",
      profile_earned_credentials: "Earned Credentials",
      cred_none_yet: "Hozircha yo‘q.",
      cred_progress_consistent: "{x} / 7 faol kun",
      cred_progress_focused: "{x} / 5 ketma-ket fokus sessiya",
      cred_progress_practice_attempts: "{x} ta praktika — masteryga yaqin",
      cred_progress_error_cycles: "{x} / 3 “xato → tahlil → qayta” sikl",
      cred_progress_research: "Resurslar: {x} ochish • {y} qaytish kuni",
 
      // Earned Credentials (v1.3) — labels
      cred_kicker_progress: "PROGRESS",
      cred_label_focused: "Fokus seriyasi",
      cred_label_practice: "Amaliyot mahorati",

      // Earned Credentials (v1.3) — credential names (keys)
      cred_consistent_learner: "Consistent Learner",
      cred_focused_study_streak: "Focused Study Streak",
      cred_active_video_learner: "Active Video Learner",
      cred_practice_mastery_subject: "Practice Mastery",
      cred_error_driven_learner: "Error-Driven Learner",
      cred_research_oriented_learner: "Research-Oriented Learner",
      cred_fair_play_participant: "Fair Play Participant",

      // Earned Credentials (v1.3) — statuses
      cred_status_active: "Faol",
      cred_status_inactive: "Nofaol",
      cred_status_expired: "Seriya yakunlandi",
      cred_status_revoked: "Bekor qilindi",

      // Earned Credentials (v1.3) — meta
      cred_meta_achieved: "Olingan",
      cred_meta_status: "Status",
      cred_meta_risk: "Yo‘qotish riski",

      profile_recommendations_archive: "My Recommendations Archive",
      profile_view_btn: "VIEW",
      profile_slots_empty: "Faol Competitive slotlar yo‘q.",
      profile_slot_hint: "Starts in 2 days",
      profile_level_advanced: "Advanced",
      profile_level_intermediate: "Intermediate",
      profile_level_beginner: "Beginner",
      profile_stability_no_data: "—",
      profile_stability_no_activity: "No activity",
      profile_certificates_title: "Certificates",
      profile_certificates_row_title: "My certificates",
      profile_certificates_row_sub: "Tours & final results",
      profile_join_btn: "+ JOIN",
      profile_empty_slot: "Empty Competitive Slot",
      profile_settings_more: "More",
      profile_settings_community: "Community",
      profile_settings_about: "About project",

      course_competitive_detach_title: "Competitive o‘chirilsinmi?",
      course_competitive_detach_message: "Fan Competitive’dan olib tashlanadi.\n\n• Turlar, reytinglar va sertifikatlar mavjud bo‘lmaydi.\n• Study (o‘quv) rejimi qoladi.\n\nMuhim: keyin Competitive’ni qayta yoqsangiz, tur/reyting progressi qaytadan boshlanishi mumkin.",
      course_competitive_detach_ok: "Olib tashlash",
      course_competitive_detach_toast: "Competitive o‘chirildi. Fan Study’ga o‘tkazildi.",

      course_toggle_on: "Yoqilgan",
      course_toggle_off: "O‘chirilgan",
      course_toggle_aria: "Home’da ko‘rsatish",
 
      toast_time_expired_answer_saved: "Vaqt tugadi. Javob saqlandi…",
      toast_time_expired_no_answer: "Vaqt tugadi. Savol javobsiz saqlandi…",

            // Settings (Profile) — pinned subjects
      settings_competitive_note: "Competitive’da maksimal 2 ta fan tanlash mumkin. Hozir tanlangan: {count}/2.",
      settings_hide: "Yashirish",
      settings_show_all: "Barchasini ko‘rsatish",
      settings_pinned: "Biriktirilgan",
      settings_not_pinned: "Biriktirilmagan",
      settings_no_pinned: "Biriktirilgan (Study) fanlar hozircha yo‘q. Home’da tez kirish uchun ularni Courses → Study’da biriktiring.",
      toast_removed_pinned: "Biriktirilganlardan olib tashlandi",
      toast_added_pinned: "Biriktirilganlarga qo‘shildi",
      toast_lang_updated: "Interfeys tili yangilandi",
       
      practice: "Amaliyot",
      practice_subtitle: "10 savol • osondan qiyinga",
      practice_chip_no_anticheat: "Anti-cheatsiz",
      practice_chip_pause: "To‘xtatish mumkin",
      practice_chip_best_saved: "Eng yaxshi natija saqlanadi",

      practice_subject_label: "Fan",
      practice_best_result: "Eng yaxshi natija",
      practice_best_time: "Eng yaxshi vaqt",
      practice_progress: "O‘sish",
      practice_last_attempts: "So‘nggi urinishlar",
      practice_all: "Barchasi",
      practice_no_attempts: "Hali urinish yo‘q",

      practice_col_date: "Sana",
      practice_col_score: "Hisob",
      practice_col_time: "Vaqt",

      practice_start: "Amaliyotni boshlash",
      practice_time_min_suffix: "m",
      practice_time_sec_suffix: "s",
 
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

      progress_trend: "O‘sish trendlari",
      open_tour_btn: "Turni ochish",

      tours_tour_label: "Tur",
      tours_best_result: "Eng yaxshi natija",
      tours_best_time: "Eng yaxshi vaqt",
      tours_best_time_of_best_result: "Eng yaxshi natijaning vaqti",

      tours_completed_title: "Yakunlangan turlar",
      tours_completed_empty: "Bu fandan hali tur topshirmagansiz.",
      tours_completed_sub: "Jami: {n}",
      tours_completed_time_label: "vaqt",

      tours_status_title: "Turlar hozircha mavjud emas",
      tours_status_desc: "Tur sanalari va ro‘yxati e’lon qilingach shu yerda ko‘rinadi.",
      tours_only_main_subjects: "Turlar faqat asosiy fanlar uchun mavjud.",
      tours_active_and_completed: "Faol va yakunlangan",
 
      tours_status_not_school_title: "Turlar faqat o‘quvchilar uchun",
      tours_status_not_school_desc: "Ishtirok etish uchun profilni o‘quvchi sifatida to‘ldiring.",

      tours_status_not_comp_title: "Turlar uchun competitive rejim kerak",
      tours_status_not_comp_desc: "Turlarni ochish uchun fanni competitive rejimda qo‘shing.",

      tours_empty_title: "Turlar keyinroq paydo bo‘ladi",
      tours_empty_desc: "Bu bo‘lim baza ulanganidan va tur sanalari e’lon qilingandan so‘ng ishlaydi.",
      tours_title: "Turlar",
      tours_subtitle: "Faol va o‘tgan",
      tours_subject_label: "Fan",
      tours_fact_questions: "Savollar",
      tours_fact_attempts: "Urinish",
      tours_fact_attempts_one: "1",
      tours_fact_pause: "Pauza",
      tours_fact_pause_no: "Yo‘q",
      tours_fact_rules: "Nazorat",
      tours_fact_rules_on: "Yoqilgan",
      tours_tab_active: "Faol",
      tours_tab_past: "O‘tgan",
      tours_archive_btn: "Turlar arxivi",
      to_subject_btn: "Fanga qaytish",
      tours_empty_title: "Turlar keyinroq paydo bo‘ladi",
      tours_empty_desc: "Bu bo‘lim baza ulanganidan va tur sanalari e’lon qilingandan so‘ng ishlaydi.",

      school_prefix: "Maktab",
      class_suffix: "-sinf",

      ratings_my_rank: "MENING O'RNIM",
      ratings_search_title: "Qidiruv",
      ratings_search_label: "Ism / maktab / sinf",
      ratings_search_hint: "Ism, maktab yoki sinf bo‘yicha qidiring.",
      btn_reset: "Tozalash",
      btn_apply: "Qo‘llash",
      ratings_out_of: "dan",
      ratings_of_total: "{total} dan",
      points_short: "ball",

      ratings_top: "Top 10",
      ratings_around: "Mening atrofimda",
      ratings_bottom: "Oxirgi 3",
      ratings_out_of: "dan",

      tour_rules_title: "Tur qoidalari",
      tour_rules_accept_required: "Tur boshlash uchun qoidalarga rozilikni tasdiqlang."
    },

    en: {
      app_name: "iClub",
      loading: "Loading…",
      saving: "Saving…",
      ratings_subject: "Subject",
      ratings_tour: "Tour",
      ratings_all_tours: "All tours",
      ratings_viewer_hint: "Leaderboards are available for viewing. “My rank” is shown only for Competitive participants.",
      ratings_search_placeholder: "Search...",
      ratings_search_hint_inline: "Search by name, school, class, region or district",
      ratings_info_title: "Leaderboard info",
      ratings_info_text1: "Leaderboards are available for viewing by everyone.",
      ratings_info_text2: "“My rank” is shown only for Competitive participants.",
      ratings_info_text3: "Ranking: higher score wins; if tied, lower time wins.",

      done: "Done",
      error_try_again: "Error — please try again",

      lang_ru: "Русский",
      lang_uz: "O‘zbek",
      lang_en: "English",

      reg_language_label: "Language",
      reg_language_hint: "This language will be used for practice, tours, and certificates.",
      reg_language_reset_note: "Important: changing the language after registration will reset progress.",

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
      reg_competitive_subject_label: "🎯 Competitive subject",
      reg_competitive_subject_hint: "Used for leaderboards and certificates",
      reg_nonstudent_title: "Study mode (non-school)",
      reg_nonstudent_text: "If you are not a school student, you can study and practice all subjects without tours. You can add or remove subjects later in your profile.",
 
      reg_subject_primary_tag: "Primary",
      reg_subject_secondary_tag: "Secondary",
      reg_subject_summary_none: "Select up to 2 subjects",

      reg_terms_text: "I agree to the Terms of Service and consent to processing of my education data.",
      reg_complete_btn: "Complete Registration",
      reg_subjects_limit: "You can choose up to 2 subjects.",
      reg_subject_label_competitive: "Competitive Subject",
      reg_subject_hint_competitive: "Choose your primary focus for the leaderboard",
      reg_subject_label_study: "Study Subject",
      reg_subject_hint_study: "Choose your primary subject for studying",

      reg_main_subject_required_label: "Main subject (required)",
      reg_main_subject_optional_label: "Main subject #2 (optional)",
      reg_add_subject_optional_label: "Additional subject (optional)",
      reg_choose_placeholder: "Choose…",
      reg_choose_none: "Do not choose",
      reg_select_region: "Choose region…",
      reg_select_region_first: "Choose region first…",
      reg_select_district: "Choose district…",
      reg_loading_districts: "Loading districts…",
      reg_no_districts: "No districts",
   
      subj_informatics: "Informatics",
      subj_economics: "Economics",
      subj_biology: "Biology",
      subj_chemistry: "Chemistry",
      subj_mathematics: "Mathematics",

      competitive_subjects_limit_2: "Competitive subjects limit is 2",
      fill_required_fields: "Please fill required fields",
 
      not_available: "Not available",
      disabled_not_school: "Tours and ratings are available only for school students.",
      disabled_not_competitive: "This feature is available only for competitive subjects.",
      tours_denied_title: "Tours unavailable",
      disabled_not_main: "Tours are available only for main subjects.",
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
      home_pinned_empty: "Pin study subjects in Courses → Study to see them here. Competitive subjects are shown above separately.",
      home_need_registration: "Please complete registration first.",
      profile_title: "Academic Profile",
      profile_status_badge: "ADVANCED STATUS",
      profile_performance_overview: "Performance Overview",
      profile_stability_score: "Stability Score (7d)",
      profile_current_level: "Current Level",
      profile_competitive_slots: "Competitive Slots",
      profile_active_slots_label: "Active",
      profile_earned_credentials: "Earned Credentials",
      cred_none_yet: "No credentials yet",
      cred_progress_consistent: "{x} / 7 active days",
      cred_progress_focused: "{x} / 5 focused sessions in a row",
      cred_progress_practice_attempts: "{x} practices — close to mastery",
      cred_progress_error_cycles: "{x} / 3 “error → review → retry” cycles",
      cred_progress_research: "Resources: {x} opens • {y} return days",

      // Earned Credentials (v1.3) — labels
      cred_kicker_progress: "PROGRESS",
      cred_label_focused: "Focused streak",
      cred_label_practice: "Practice mastery",

      // Earned Credentials (v1.3) — credential names (keys)
      cred_consistent_learner: "Consistent Learner",
      cred_focused_study_streak: "Focused Study Streak",
      cred_active_video_learner: "Active Video Learner",
      cred_practice_mastery_subject: "Practice Mastery",
      cred_error_driven_learner: "Error-Driven Learner",
      cred_research_oriented_learner: "Research-Oriented Learner",
      cred_fair_play_participant: "Fair Play Participant",

      // Earned Credentials (v1.3) — statuses
      cred_status_active: "Active",
      cred_status_inactive: "Inactive",
      cred_status_expired: "Expired",
      cred_status_revoked: "Revoked",

      // Earned Credentials (v1.3) — meta
      cred_meta_achieved: "Achieved",
      cred_meta_status: "Status",
      cred_meta_risk: "Risk of loss",

      profile_recommendations_archive: "My Recommendations Archive",
      profile_view_btn: "VIEW",
      profile_slots_empty: "No active Competitive slots.",
      profile_slot_hint: "Starts in 2 days",
      profile_level_advanced: "Advanced",
      profile_level_intermediate: "Intermediate",
      profile_level_beginner: "Beginner",
      profile_stability_no_data: "—",
      profile_stability_no_activity: "No activity",
      profile_certificates_title: "Certificates",
      profile_certificates_row_title: "My certificates",
      profile_certificates_row_sub: "Tours & final results",
      profile_join_btn: "+ JOIN",
      profile_empty_slot: "Empty Competitive Slot",
      profile_settings_more: "More",
      profile_settings_community: "Community",
      profile_settings_about: "About project",

      course_competitive_detach_title: "Disable Competitive?",
      course_competitive_detach_message: "This subject will be removed from Competitive.\n\n• Tours, leaderboards and certificates will be unavailable.\n• Study mode will remain available.\n\nNote: if you enable Competitive again, tour/leaderboard progress may restart.",
      course_competitive_detach_ok: "Detach",
      course_competitive_detach_toast: "Competitive disabled. Subject moved to Study.",

      course_toggle_on: "Enabled",
      course_toggle_off: "Disabled",
      course_toggle_aria: "Show on Home",
 
      toast_time_expired_answer_saved: "Time is up. Answer saved…",
      toast_time_expired_no_answer: "Time is up. Question saved without an answer…",

            // Settings (Profile) — pinned subjects
      settings_competitive_note: "You can select up to 2 subjects in Competitive. Selected: {count}/2.",
      settings_hide: "Hide",
      settings_show_all: "Show all",
      settings_pinned: "Pinned",
      settings_not_pinned: "Not pinned",
      settings_no_pinned: "No pinned study subjects yet. Pin them in Courses → Study for quick access on Home.",
      toast_removed_pinned: "Removed from pinned",
      toast_added_pinned: "Added to pinned",
      toast_lang_updated: "Interface language updated",
 
      practice: "Practice",
      practice_subtitle: "10 questions • easy to hard",
      practice_chip_no_anticheat: "No anti-cheat",
      practice_chip_pause: "Can pause",
      practice_chip_best_saved: "Best result is saved",

      practice_subject_label: "Subject",
      practice_best_result: "Best result",
      practice_best_time: "Best time",
      practice_progress: "Progress",
      practice_last_attempts: "Recent attempts",
      practice_all: "All",
      practice_no_attempts: "No attempts yet",

      practice_col_date: "Date",
      practice_col_score: "Score",
      practice_col_time: "Time",

      practice_start: "Start practice",
      practice_time_min_suffix: "m",
      practice_time_sec_suffix: "s",
 
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

      progress_trend: "Progress trend",
      open_tour_btn: "Open tour",

      tours_tour_label: "Tour",
      tours_best_result: "Best result",
      tours_best_time: "Best time",
      tours_best_time_of_best_result: "Time of best result",

      tours_completed_title: "Completed tours",
      tours_completed_empty: "You haven’t completed any tours for this subject yet.",
      tours_completed_sub: "Total: {n}",
      tours_completed_time_label: "time",

      tours_status_title: "Tours are not available yet",
      tours_status_desc: "Tour dates and the list will appear here after publication.",
      tours_only_main_subjects: "Tours are available only for main subjects.",
      tours_active_and_completed: "Active and completed",
 
      tours_status_not_school_title: "Tours are for students only",
      tours_status_not_school_desc: "Complete your profile as a student to participate.",

      tours_status_not_comp_title: "Tours require competitive mode",
      tours_status_not_comp_desc: "Add this subject in competitive mode to unlock tours.",
        
      tours_empty_title: "Tours will appear later",
      tours_empty_desc: "This section becomes available after the database is connected and tour dates are published.",
      tours_title: "Tours",
      tours_subtitle: "Active and past",
      tours_subject_label: "Subject",
      tours_fact_questions: "Questions",
      tours_fact_attempts: "Attempt",
      tours_fact_attempts_one: "1",
      tours_fact_pause: "Pause",
      tours_fact_pause_no: "No",
      tours_fact_rules: "Monitoring",
      tours_fact_rules_on: "On",
      tours_tab_active: "Active",
      tours_tab_past: "Past",
      tours_archive_btn: "Tour archive",
      to_subject_btn: "Back to subject",
      tours_empty_title: "Tours will appear later",
      tours_empty_desc: "This section becomes available after the database is connected and tour dates are published.",

      school_prefix: "School",
      class_suffix: "grade",

      ratings_my_rank: "MY RANK",
      ratings_search_title: "Search",
      ratings_search_label: "Name / school / class",
      ratings_search_hint: "Type any part of a name, school or class.",
      btn_reset: "Reset",
      btn_apply: "Apply",
      ratings_out_of: "out of",

      ratings_top: "Top 10",
      ratings_around: "Around me",
      ratings_bottom: "Bottom 3",
      ratings_out_of: "out of",
      ratings_of_total: "of {total}",
      points_short: "pts",

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
