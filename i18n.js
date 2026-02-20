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

      // Ratings
      ratings_subject: "Предмет",
      ratings_tour: "Тур",
      ratings_all_tours: "Все туры",
      ratings_viewer_hint:
        "Рейтинг доступен для просмотра. «Мой ранг» показывается только участникам соревновательного режима.",
      ratings_search_placeholder: "Поиск…",
      ratings_search_hint_inline: "Поиск по имени, школе, классу, региону или району",
      ratings_info_title: "О рейтинге",
      ratings_info_text1: "Рейтинг доступен для просмотра всем пользователям.",
      ratings_info_text2: "«Мой ранг» показывается только участникам соревновательного режима.",
      ratings_info_text3:
        "Сортировка: больше баллов — выше; при равенстве — меньшее время — выше.",
      ratings_results: "Результаты",
      ratings_reset: "Сброс",
      ratings_empty: "Ничего не найдено.",
      ratings_title: "Рейтинг",
      ratings_scope_district: "Район",
      ratings_scope_region: "Регион",
      ratings_scope_republic: "Республика",
      ratings_col_rank: "МЕСТО",
      ratings_col_student: "УЧАСТНИК",
      ratings_col_score: "БАЛЛЫ",
      ratings_col_time: "ВРЕМЯ",
      ratings_no_participants: "Нет участников.",

      courses_title: "Курсы",

      subject_hub_title: "Предмет",
      subject_hub_meta: "Учебный / Соревновательный",

      profile_metric_competitive: "Соревновательный",
      profile_metric_study: "Учебный",

      done: "Готово",
      error_try_again: "Ошибка — попробуйте ещё раз",

      // Languages
      lang_ru: "Русский",
      lang_uz: "O‘zbek",
      lang_en: "English",

      // Registration
      reg_language_label: "Язык",
      reg_language_hint:
        "Этот язык будет использоваться для практики, туров и сертификатов.",
      reg_language_reset_note: "Важно: смена языка после регистрации сбросит прогресс.",

      tab_home: "Главная",
      tab_courses: "Предметы",
      tab_ratings: "Рейтинг",
      tab_profile: "Профиль",

      reg_title: "Регистрация",
      reg_consent: "Я согласен(на) на обработку данных",
      reg_header_title: "Регистрация",
      reg_progress_label: "Заполнение профиля",
      reg_progress_step: "Шаг 1 из 2",

      reg_create_title: "Создайте аккаунт",
      reg_create_subtitle:
        "Введите данные, чтобы участвовать в обучении по Cambridge curriculum в Узбекистане.",

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

      reg_competitive_subject_label: "🎯 Предмет соревновательного режима",
      reg_competitive_subject_hint: "Используется для рейтинга и сертификатов",

      reg_nonstudent_title: "Обучение без школьного режима",
      reg_nonstudent_text:
        "Если вы не ученик школы, вы можете изучать и практиковаться по всем предметам без туров. Подключать и удалять предметы можно позже в профиле.",

      reg_subject_primary_tag: "Основной",
      reg_subject_secondary_tag: "Дополнительный",
      reg_subject_summary_none: "Выберите до 2 предметов",

      reg_terms_text:
        "Я соглашаюсь с условиями и даю согласие на обработку данных об обучении.",
      reg_complete_btn: "Завершить регистрацию",
      reg_subjects_limit: "Можно выбрать максимум 2 предмета.",

      reg_subject_label_competitive: "Основной предмет (для рейтинга)",
      reg_subject_hint_competitive: "Выберите основной предмет для рейтинга",
      reg_subject_label_study: "Основной предмет (для обучения)",
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

      // Subjects
      subj_informatics: "Информатика",
      subj_economics: "Экономика",
      subj_biology: "Биология",
      subj_chemistry: "Химия",
      subj_mathematics: "Математика",

      // Limits / Validation
      competitive_subjects_limit_2: "Лимит предметов соревновательного режима — 2",
      fill_required_fields: "Заполните обязательные поля",

      // Availability messages
      not_available: "Недоступно",
      disabled_not_school: "Туры и рейтинги доступны только школьникам.",
      disabled_not_competitive: "Функция доступна только для предмета соревновательного режима.",
      tours_denied_title: "Туры недоступны",
      disabled_not_main: "Туры доступны только для основных предметов.",
      disabled_tour_dates: "Тур недоступен по датам.",
      ratings_info:
        "Рейтинг: только предметы соревновательного режима с активными турами. При равных баллах решает время.",

      // Home
      home_competitive_mode: "Соревновательный режим",
      home_competitive_mode_subtitle: "Отслеживайте прогресс по Cambridge curriculum",
      home_active_tour: "Активный тур",
      home_pinned_subjects: "Закреплённые предметы",
      home_show_all_subjects: "Показать все предметы",
      home_course_completion: "Прогресс курса",
      home_rank_label: "Ранг",
      home_lessons_label: "Уроки",
      home_competitive_empty: "Пока нет предметов в соревновательном режиме.",
      home_pinned_empty: "Закрепите предметы в разделе «Предметы».",
      home_need_registration: "Сначала пройдите регистрацию.",

      // UI badges / labels (Courses + Home)
      badge_active: "АКТИВНО",
      badge_pinned: "Закреплён",
      badge_competitive: "Соревновательный",
      module_label: "МОДУЛЬ {n}",
      open_subject_btn: "Открыть предмет",

      // Courses UI
      courses_filter_competitive: "Соревновательный",
      courses_filter_study: "Учебный",
      courses_section_main: "Основные (Cambridge)",
      courses_section_additional: "Дополнительные",

      // Modes / Subject Hub meta
      mode_competitive: "Соревновательный",
      mode_study: "Учебный",
      hub_pinned: "Закреплён",
      hub_not_pinned: "Не закреплён",
      hub_not_added: "Не добавлен",

      // Profile
      profile_title: "Учебный профиль",
      profile_status_badge: "ПРОДВИНУТЫЙ УРОВЕНЬ",
      profile_performance_overview: "Обзор результатов",
      profile_stability_score: "Стабильность (7 дней)",
      profile_current_level: "Текущий уровень",
      profile_competitive_slots: "Слоты соревновательного режима",
      profile_active_slots_label: "Активные",
      profile_earned_credentials: "Достижения",

      cred_none_yet: "Пока нет",
      cred_progress_consistent: "{x} / 7 активных дней",
      cred_progress_focused: "{x} / 5 фокус-сессий подряд",
      cred_progress_practice_attempts: "{x} практик — близко к мастерству",
      cred_progress_error_cycles: "{x} / 3 цикла «ошибка → разбор → повтор»",
      cred_progress_research: "Ресурсы: {x} открытий • {y} дней возврата",

      // Earned Credentials (labels)
      cred_kicker_progress: "ПРОГРЕСС",
      cred_label_focused: "Фокус-серия",
      cred_label_practice: "Мастерство практики",

      // Earned Credentials (names)
      cred_consistent_learner: "Стабильный участник",
      cred_focused_study_streak: "Фокус-серия",
      cred_active_video_learner: "Активный видео-участник",
      cred_practice_mastery_subject: "Мастерство практики",
      cred_error_driven_learner: "Рост через ошибки",
      cred_research_oriented_learner: "Участник-исследователь",
      cred_fair_play_participant: "Честная игра",

      // Earned Credentials (statuses)
      cred_status_active: "Активно",
      cred_status_inactive: "Неактивно",
      cred_status_expired: "Серия завершена",
      cred_status_revoked: "Отозвано",

      // Earned Credentials (meta)
      cred_meta_achieved: "Получено",
      cred_meta_status: "Статус",
      cred_meta_risk: "Риск потери",

      profile_recommendations_archive: "Архив моих рекомендаций",
      profile_view_btn: "ОТКРЫТЬ",
      profile_slots_empty: "Нет активных слотов соревновательного режима.",
      profile_slot_hint: "Старт через 2 дня",
      profile_level_advanced: "Продвинутый",
      profile_level_intermediate: "Средний",
      profile_level_beginner: "Начальный",
      profile_stability_no_data: "—",
      profile_stability_no_activity: "Нет активности",
      profile_certificates_title: "Сертификаты",
      profile_certificates_row_title: "Мои сертификаты",
      profile_certificates_row_sub: "Туры и финальные результаты",
      profile_join_btn: "+ ПОДКЛЮЧИТЬ",
      profile_empty_slot: "Пустой слот соревновательного режима",
      profile_settings_more: "Ещё",
      profile_settings_community: "Сообщество",
      profile_settings_about: "О проекте",

      // Courses toggles / detach
      course_competitive_detach_title: "Отключить соревновательный режим?",
      course_competitive_detach_message:
        "Предмет будет исключён из соревновательного режима.\n\n• Туры, рейтинг и сертификаты станут недоступны.\n• Учебный режим останется доступен.\n\nВажно: при повторном включении прогресс по турам/рейтингу может начаться заново.",
      course_competitive_detach_ok: "Отключить",
      course_competitive_detach_toast:
        "Соревновательный режим отключён. Предмет доступен в учебном режиме.",

      course_toggle_on: "Включено",
      course_toggle_off: "Выключено",
      course_toggle_aria: "Показывать на главном",

      // Toasts time expired
      toast_time_expired_answer_saved: "Время истекло. Ответ сохранён…",
      toast_time_expired_no_answer: "Время истекло. Вопрос сохранён без ответа…",

      // Settings (Profile) — pinned subjects
      settings_competitive_note:
        "Можно выбрать максимум 2 предмета в соревновательном режиме. Сейчас выбрано: {count}/2.",
      settings_hide: "Скрыть",
      settings_show_all: "Показать все",
      settings_pinned: "Закреплён",
      settings_not_pinned: "Не закреплён",
      settings_no_pinned: "Закреплённых предметов пока нет",
      toast_removed_pinned: "Убрано из закреплённых",
      toast_added_pinned: "Добавлено в закреплённые",
      toast_lang_updated: "Язык интерфейса обновлён",

      // Practice
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

      // Tours
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

      // School labels
      school_prefix: "Школа",
      class_suffix: "класс",

      // Ratings UI
      ratings_my_rank: "МОЙ РАНГ",
      ratings_search_title: "Поиск",
      ratings_search_label: "Имя / школа / класс",
      ratings_search_hint: "Введите часть имени, школы или класса.",
      btn_reset: "Сброс",
      btn_apply: "Применить",
      ratings_out_of: "из",
      ratings_of_total: "из {total}",
      points_short: "бал.",

      ratings_top: "Топ 10",
      ratings_around: "Рядом со мной",
      ratings_bottom: "Нижние 3",

      // Tour rules
      tour_rules_title: "Правила тура",
      tour_rules_accept_required: "Подтвердите согласие с правилами, чтобы начать тур.",

      // Profile language blocks
      profile_ui_language_title: "Язык интерфейса",
      profile_ui_language_desc:
        "Меняется только интерфейс приложения и не влияет на туры и практику.",
      profile_content_language_title: "Язык туров и практики",
      profile_content_language_desc:
        "Смена этого языка удалит весь прогресс (туры, практика, ответы). Используйте только при необходимости.",

      // Confirm / Toast
      confirm_content_lang_change:
        "Смена языка туров и практики удалит весь прогресс. Продолжить?",
      toast_content_lang_changed: "Язык туров и практики изменён. Прогресс сброшен.",

      // Practice input
      input_number: "Введите число",
      input_text: "Введите ответ",
      select_option_required: "Выберите вариант ответа",
      invalid_answer_format: "Проверьте формат ответа",

      // Topics
      topic_general: "Общие вопросы",

      // Global
      yes: "Да",
      no: "Нет",
      cancel: "Отмена",
      ok: "ОК",

      // Profile settings cards
      profile_settings_competitive_title: "Соревновательный режим",
      profile_settings_study_title: "Учебный режим",
      profile_settings_study_desc:
        "Закреплённые — для быстрого доступа в учебном режиме. Соревновательный режим настраивается выше.",
      profile_settings_more_title: "Ещё",
      profile_settings_news_title: "Новости",
      profile_settings_news_sub: "Анонсы и обновления",
      profile_settings_notifications_title: "Уведомления",
      profile_settings_notifications_sub: "Системные события",
      profile_settings_community_title: "Сообщество",
      profile_settings_community_sub: "@iClubuzofficial",

      // Pinned hints
      profile_pinned_hint_has:
        "Закреплённые предметы уже ускоряют доступ. Дальше — стабильность.",
      profile_pinned_hint_empty:
        "Закрепите 1–3 предмета — и доступ к нужному станет заметно быстрее."
    },

    uz: {
      app_name: "iClub",
      loading: "Yuklanmoqda…",
      saving: "Saqlanmoqda…",

      // Ratings
      ratings_subject: "Fan",
      ratings_tour: "Tur",
      ratings_all_tours: "Barcha turlar",
      ratings_viewer_hint:
        "Reytingni ko‘rish mumkin. «Mening o‘rnim» faqat musobaqa rejimi ishtirokchilariga ko‘rsatiladi.",
      ratings_search_placeholder: "Qidirish…",
      ratings_search_hint_inline: "Ism, maktab, sinf, viloyat yoki tuman bo‘yicha qidirish",
      ratings_info_title: "Reyting haqida",
      ratings_info_text1: "Reytingni hamma foydalanuvchi ko‘rishi mumkin.",
      ratings_info_text2:
        "«Mening o‘rnim» faqat musobaqa rejimi ishtirokchilariga ko‘rsatiladi.",
      ratings_info_text3:
        "Tartib: ball ko‘proq bo‘lsa — yuqoriroq; teng bo‘lsa — vaqt kam bo‘lsa — yuqoriroq.",
      ratings_results: "Natijalar",
      ratings_reset: "Tozalash",
      ratings_empty: "Hech narsa topilmadi.",
      ratings_title: "Reyting",
      ratings_scope_district: "Tuman",
      ratings_scope_region: "Viloyat",
      ratings_scope_republic: "Respublika",
      ratings_col_rank: "O‘RIN",
      ratings_col_student: "ISHTIROKCHI",
      ratings_col_score: "BALL",
      ratings_col_time: "VAQT",
      ratings_no_participants: "Ishtirokchilar yo‘q.",

      courses_title: "Kurslar",

      subject_hub_title: "Fan",
      subject_hub_meta: "O‘quv / Musobaqa",

      profile_metric_competitive: "Musobaqa",
      profile_metric_study: "O‘quv",

      done: "Tayyor",
      error_try_again: "Xatolik — qayta urinib ko‘ring",

      // Languages
      lang_ru: "Русский",
      lang_uz: "O‘zbek",
      lang_en: "English",

      // Registration
      reg_language_label: "Til",
      reg_language_hint:
        "Ushbu til amaliyot, turlar va sertifikatlarga qo‘llanadi.",
      reg_language_reset_note:
        "Muhim: ro‘yxatdan o‘tgandan so‘ng tilni o‘zgartirish progressni o‘chiradi.",

      tab_home: "Bosh sahifa",
      tab_courses: "Fanlar",
      tab_ratings: "Reyting",
      tab_profile: "Profil",

      reg_title: "Ro‘yxatdan o‘tish",
      reg_consent: "Ma’lumotlarimni qayta ishlashga roziman",
      reg_header_title: "Ro‘yxatdan o‘tish",
      reg_progress_label: "Profilni to‘ldirish",
      reg_progress_step: "1/2-qadam",

      reg_create_title: "Akkaunt yarating",
      reg_create_subtitle:
        "Cambridge curriculum bo‘yicha O‘zbekistonda o‘qish uchun ma’lumotlarni kiriting.",

      reg_full_name_label: "F.I.Sh.",
      reg_full_name_placeholder: "masalan, Alisher Navoiy",

      reg_region_label: "Viloyat",
      reg_region_placeholder: "Viloyatni tanlang",

      reg_district_label: "Tuman",
      reg_district_placeholder: "Tumanni tanlang",

      reg_school_toggle_label: "Siz maktab o‘quvchisizmi?",
      reg_school_toggle_hint: "Maktab va sinfni ko‘rsatish uchun yoqing",
      reg_school_no_label: "Maktab №",
      reg_school_no_placeholder: "masalan 154",
      reg_grade_label: "Sinf",

      reg_competitive_subject_label: "🎯 Musobaqa uchun fan",
      reg_competitive_subject_hint: "Reyting va sertifikatlar uchun ishlatiladi",

      reg_nonstudent_title: "Maktab rejimisiz o‘qish",
      reg_nonstudent_text:
        "Agar siz maktab o‘quvchisi bo‘lmasangiz, barcha fanlarni turlarsiz o‘rganish va amaliyot qilish mumkin. Fanlarni keyin profil orqali qo‘shish yoki olib tashlash mumkin.",

      reg_subject_primary_tag: "Asosiy",
      reg_subject_secondary_tag: "Qo‘shimcha",
      reg_subject_summary_none: "2 tagacha fan tanlang",

      reg_terms_text:
        "Men shartlarga roziman va o‘qish ma’lumotlarimni qayta ishlashga rozilik beraman.",
      reg_complete_btn: "Ro‘yxatdan o‘tishni yakunlash",
      reg_subjects_limit: "Ko‘pi bilan 2 ta fan tanlash mumkin.",

      reg_subject_label_competitive: "Asosiy fan (reyting uchun)",
      reg_subject_hint_competitive: "Reyting uchun asosiy fanni tanlang",
      reg_subject_label_study: "Asosiy fan (o‘qish uchun)",
      reg_subject_hint_study: "O‘qish uchun asosiy fanni tanlang",

      reg_main_subject_required_label: "Asosiy fan (majburiy)",
      reg_main_subject_optional_label: "Asosiy fan №2 (ixtiyoriy)",
      reg_add_subject_optional_label: "Qo‘shimcha fan (ixtiyoriy)",
      reg_choose_placeholder: "Tanlang…",
      reg_choose_none: "Tanlamaslik",
      reg_select_region: "Viloyatni tanlang…",
      reg_select_region_first: "Avval viloyatni tanlang…",
      reg_select_district: "Tumanni tanlang…",
      reg_loading_districts: "Tumanlar yuklanmoqda…",
      reg_no_districts: "Tumanlar yo‘q",

      // Subjects
      subj_informatics: "Informatika",
      subj_economics: "Iqtisodiyot",
      subj_biology: "Biologiya",
      subj_chemistry: "Kimyo",
      subj_mathematics: "Matematika",

      // Limits / Validation
      competitive_subjects_limit_2: "Musobaqa rejimi fanlari limiti — 2 ta",
      fill_required_fields: "Majburiy maydonlarni to‘ldiring",

      // Availability messages
      not_available: "Mavjud emas",
      disabled_not_school: "Turlar va reyting faqat maktab o‘quvchilari uchun.",
      disabled_not_competitive:
        "Bu funksiya faqat musobaqa rejimidagi fan uchun mavjud.",
      tours_denied_title: "Turlar mavjud emas",
      disabled_not_main: "Turlar faqat asosiy fanlar uchun mavjud.",
      disabled_tour_dates: "Tur sanalar bo‘yicha mavjud emas.",
      ratings_info:
        "Reyting: faqat musobaqa rejimidagi fanlar va faol turlar. Ball teng bo‘lsa, vaqt hal qiladi.",

      // Home
      home_competitive_mode: "Musobaqa rejimi",
      home_competitive_mode_subtitle: "Cambridge curriculum bo‘yicha progressni kuzating",
      home_active_tour: "Faol tur",
      home_pinned_subjects: "Biriktirilgan fanlar",
      home_show_all_subjects: "Barcha fanlarni ko‘rsatish",
      home_course_completion: "Kurs progressi",
      home_rank_label: "O‘rin",
      home_lessons_label: "Darslar",
      home_competitive_empty: "Hozircha musobaqa rejimida fan yo‘q.",
      home_pinned_empty: "«Fanlar» bo‘limida fanlarni biriktiring.",
      home_need_registration: "Avval ro‘yxatdan o‘ting.",

      // UI badges / labels (Courses + Home)
      badge_active: "FAOL",
      badge_pinned: "Biriktirilgan",
      badge_competitive: "Musobaqa",
      module_label: "MODUL {n}",
      open_subject_btn: "Fanni ochish",

      // Courses UI
      courses_filter_competitive: "Musobaqa",
      courses_filter_study: "O‘quv",
      courses_section_main: "Asosiy (Cambridge)",
      courses_section_additional: "Qo‘shimcha",

      // Modes / Subject Hub meta
      mode_competitive: "Musobaqa",
      mode_study: "O‘quv",
      hub_pinned: "Biriktirilgan",
      hub_not_pinned: "Biriktirilmagan",
      hub_not_added: "Qo‘shilmagan",
      // Profile
      profile_title: "O‘quv profili",
      profile_status_badge: "Yuqori daraja",
      profile_performance_overview: "Natijalar ko‘rsatkichi",
      profile_stability_score: "Barqarorlik (7 kun)",
      profile_current_level: "Joriy daraja",
      profile_competitive_slots: "Musobaqa rejimi slotlari",
      profile_active_slots_label: "Faol",
      profile_earned_credentials: "Yutuqlar",

      cred_none_yet: "Hozircha yo‘q",
      cred_progress_consistent: "{x} / 7 faol kun",
      cred_progress_focused: "{x} / 5 ketma-ket fokus-sessiya",
      cred_progress_practice_attempts: "{x} ta amaliyot — mahoratga yaqin",
      cred_progress_error_cycles: "{x} / 3 «xato → tahlil → takror» sikli",
      cred_progress_research: "Resurslar: {x} marta ochildi • {y} kun qaytildi",

      // Earned Credentials (labels)
      cred_kicker_progress: "PROGRESS",
      cred_label_focused: "Fokus-seriya",
      cred_label_practice: "Amaliyot mahorati",

      // Earned Credentials (names)
      cred_consistent_learner: "Barqaror ishtirokchi",
      cred_focused_study_streak: "Fokus-seriya",
      cred_active_video_learner: "Faol video-ishtirokchi",
      cred_practice_mastery_subject: "Amaliyot mahorati",
      cred_error_driven_learner: "Xatolar orqali o‘sish",
      cred_research_oriented_learner: "Tadqiqotchi ishtirokchi",
      cred_fair_play_participant: "Halollik ishtirokchisi",

      // Earned Credentials (statuses)
      cred_status_active: "Faol",
      cred_status_inactive: "Nofaol",
      cred_status_expired: "Seriya yakunlandi",
      cred_status_revoked: "Bekor qilindi",

      // Earned Credentials (meta)
      cred_meta_achieved: "Olingan",
      cred_meta_status: "Holat",
      cred_meta_risk: "Yo‘qotish xavfi",

      profile_recommendations_archive: "Tavsiyalarim arxivi",
      profile_view_btn: "OCHISH",
      profile_slots_empty: "Faol musobaqa rejimi slotlari yo‘q.",
      profile_slot_hint: "2 kundan so‘ng boshlanadi",
      profile_level_advanced: "Yuqori",
      profile_level_intermediate: "O‘rta",
      profile_level_beginner: "Boshlang‘ich",
      profile_stability_no_data: "—",
      profile_stability_no_activity: "Faollik yo‘q",
      profile_certificates_title: "Sertifikatlar",
      profile_certificates_row_title: "Sertifikatlarim",
      profile_certificates_row_sub: "Turlar va yakuniy natijalar",
      profile_join_btn: "+ ULASH",
      profile_empty_slot: "Bo‘sh musobaqa sloti",
      profile_settings_more: "Qo‘shimcha",
      profile_settings_community: "Hamjamiyat",
      profile_settings_about: "Loyiha haqida",

      // Courses toggles / detach
      course_competitive_detach_title: "Musobaqa rejimini o‘chirish?",
      course_competitive_detach_message:
        "Fan musobaqa rejimidan olib tashlanadi.\n\n• Turlar, reyting va sertifikatlar mavjud bo‘lmaydi.\n• O‘quv rejimi saqlanadi.\n\nEslatma: keyin musobaqa rejimini qayta yoqsangiz, tur/reyting progressi qaytadan boshlanishi mumkin.",
      course_competitive_detach_ok: "O‘chirish",
      course_competitive_detach_toast:
        "Musobaqa rejimi o‘chirildi. Fan o‘quv rejimida qoladi.",

      course_toggle_on: "Yoqilgan",
      course_toggle_off: "O‘chirilgan",
      course_toggle_aria: "Bosh sahifada ko‘rsatish",

      // Toasts time expired
      toast_time_expired_answer_saved: "Vaqt tugadi. Javob saqlandi…",
      toast_time_expired_no_answer: "Vaqt tugadi. Savol javobsiz saqlandi…",

      // Settings (Profile) — pinned subjects
      settings_competitive_note:
        "Musobaqa rejimida ko‘pi bilan 2 ta fan tanlanadi. Hozir tanlangan: {count}/2.",
      settings_hide: "Yashirish",
      settings_show_all: "Barchasini ko‘rsatish",
      settings_pinned: "Biriktirilgan",
      settings_not_pinned: "Biriktirilmagan",
      settings_no_pinned: "Hozircha biriktirilgan fanlar yo‘q",
      toast_removed_pinned: "Biriktirilganlardan olib tashlandi",
      toast_added_pinned: "Biriktirilganlarga qo‘shildi",
      toast_lang_updated: "Interfeys tili yangilandi",

      // Practice
      practice: "Amaliyot",
      practice_subtitle: "10 savol • osondan qiyinga",
      practice_chip_no_anticheat: "Anti-cheatsiz",
      practice_chip_pause: "To‘xtatish mumkin",
      practice_chip_best_saved: "Eng yaxshi natija saqlanadi",

      practice_subject_label: "Fan",
      practice_best_result: "Eng yaxshi natija",
      practice_best_time: "Eng yaxshi vaqt",
      practice_progress: "Progress",
      practice_last_attempts: "So‘nggi urinishlar",
      practice_all: "Barchasi",
      practice_no_attempts: "Hali urinish yo‘q",

      practice_col_date: "Sana",
      practice_col_score: "Hisob",
      practice_col_time: "Vaqt",

      practice_start: "Amaliyotni boshlash",
      practice_time_min_suffix: "daq",
      practice_time_sec_suffix: "son",

      practice_paused: "Amaliyot to‘xtatildi",
      practice_resume: "Davom ettirish",
      practice_restart: "Qayta boshlash",
      practice_resume_prompt:
        "Tugallanmagan urinish bor. Davom ettirasizmi yoki qayta boshlaysizmi?",

      practice_result_title: "Amaliyot natijasi",
      practice_review_title: "Xatolar tahlili",
      practice_recs_title: "Tavsiyalar",
      practice_my_recs_title: "Tavsiyalarim",
      practice_errors: "Xatolar",
      practice_topics: "Mavzular",
      practice_saved_to_my_recs: "Tavsiyalar «Tavsiyalarim» bo‘limiga saqlandi",
      practice_nothing_to_save: "Xato yo‘q — saqlash shart emas.",

      progress_trend: "Progress trendlari",
      open_tour_btn: "Turni ochish",

      // Tours
      tours_tour_label: "Tur",
      tours_best_result: "Eng yaxshi natija",
      tours_best_time: "Eng yaxshi natija vaqti",
      tours_best_time_of_best_result: "Eng yaxshi natija vaqti",

      tours_completed_title: "Yakunlangan turlar",
      tours_completed_empty: "Bu fandan hali tur topshirmagansiz.",
      tours_completed_sub: "Jami: {n}",
      tours_completed_time_label: "vaqt",

      tours_status_title: "Turlar hozircha mavjud emas",
      tours_status_desc:
        "Tur sanalari va ro‘yxati e’lon qilingach shu yerda ko‘rinadi.",

      tours_status_not_school_title: "Turlar faqat o‘quvchilar uchun",
      tours_status_not_school_desc:
        "Ishtirok etish uchun profilni o‘quvchi sifatida to‘ldiring.",
      tours_only_main_subjects: "Turlar faqat asosiy fanlar uchun mavjud.",
      tours_active_and_completed: "Faol va yakunlangan",

      tours_status_not_comp_title: "Turlar musobaqa rejimida mavjud",
      tours_status_not_comp_desc:
        "Turlarni ochish uchun fanni musobaqa rejimida qo‘shing.",

      tours_empty_title: "Turlar keyinroq paydo bo‘ladi",
      tours_empty_desc:
        "Bu bo‘lim baza ulanganidan va tur sanalari e’lon qilingandan so‘ng ishlaydi.",

      tours_title: "Turlar",
      tours_subtitle: "Faol va yakunlangan",
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

      // School labels
      school_prefix: "Maktab",
      class_suffix: "-sinf",

      // Ratings UI
      ratings_my_rank: "MENING O‘RNIM",
      ratings_search_title: "Qidiruv",
      ratings_search_label: "Ism / maktab / sinf",
      ratings_search_hint: "Ism, maktab yoki sinf bo‘yicha qidiring.",
      btn_reset: "Tozalash",
      btn_apply: "Qo‘llash",
      ratings_out_of: "dan",
      ratings_of_total: "{total} dan",
      points_short: "ball",

      ratings_top: "Top 10",
      ratings_around: "Menga yaqin",
      ratings_bottom: "Oxirgi 3",

      // Tour rules
      tour_rules_title: "Tur qoidalari",
      tour_rules_accept_required:
        "Tur boshlash uchun qoidalarga rozilikni tasdiqlang.",

      // Profile language blocks
      profile_ui_language_title: "Interfeys tili",
      profile_ui_language_desc:
        "Bu faqat ilova interfeysini o‘zgartiradi va turlar hamda amaliyotga ta’sir qilmaydi.",
      profile_content_language_title: "Turlar va amaliyot tili",
      profile_content_language_desc:
        "Bu tilni o‘zgartirish barcha progressni (turlar, amaliyot, javoblar) o‘chiradi. Faqat zarurat bo‘lsa foydalaning.",

      // Confirm / Toast
      confirm_content_lang_change:
        "Turlar va amaliyot tilini o‘zgartirish barcha progressni o‘chiradi. Davom etilsinmi?",
      toast_content_lang_changed:
        "Turlar va amaliyot tili o‘zgartirildi. Progress o‘chirildi.",

      // Practice input
      input_number: "Raqam kiriting",
      input_text: "Javobni kiriting",
      select_option_required: "Variantni tanlang",
      invalid_answer_format: "Javob formatini tekshiring",

      // Topics
      topic_general: "Umumiy savollar",

      // Global
      yes: "Ha",
      no: "Yo‘q",
      cancel: "Bekor qilish",
      ok: "Xo‘p",

      // Profile settings cards
      profile_settings_competitive_title: "Musobaqa rejimi",
      profile_settings_study_title: "O‘quv rejimi",
      profile_settings_study_desc:
        "Biriktirilgan fanlar o‘quv rejimida tezkor kirish uchun. Musobaqa rejimi yuqorida sozlanadi.",
      profile_settings_more_title: "Qo‘shimcha",
      profile_settings_news_title: "Yangiliklar",
      profile_settings_news_sub: "E’lonlar va yangilanishlar",
      profile_settings_notifications_title: "Bildirishnomalar",
      profile_settings_notifications_sub: "Tizim xabarlari",
      profile_settings_community_title: "Hamjamiyat",
      profile_settings_community_sub: "@iClubuzofficial",

      // Pinned hints
      profile_pinned_hint_has:
        "Biriktirilgan fanlar tezkor kirishni ta’minlaydi. Barqarorlik — natijaning asosi.",
      profile_pinned_hint_empty:
        "1–3 ta fanni biriktiring — kerakli bo‘limlarga tezroq kirish imkoniyati yaratiladi."
    },

    en: {
      app_name: "iClub",
      loading: "Loading…",
      saving: "Saving…",

      // Ratings
      ratings_subject: "Subject",
      ratings_tour: "Tour",
      ratings_all_tours: "All tours",
      ratings_viewer_hint:
        "Leaderboards are available for viewing. “My rank” is shown only for Competitive participants.",
      ratings_search_placeholder: "Search…",
      ratings_search_hint_inline: "Search by name, school, class, region or district",
      ratings_info_title: "Leaderboard info",
      ratings_info_text1: "Leaderboards are available for viewing by everyone.",
      ratings_info_text2: "“My rank” is shown only for Competitive participants.",
      ratings_info_text3: "Ranking: higher score wins; if tied, lower time wins.",
      ratings_results: "Results",
      ratings_reset: "Reset",
      ratings_empty: "Nothing found.",
      ratings_title: "Leaderboard",
      ratings_scope_district: "District",
      ratings_scope_region: "Region",
      ratings_scope_republic: "Republic",
      ratings_col_rank: "RANK",
      ratings_col_student: "STUDENT",
      ratings_col_score: "SCORE",
      ratings_col_time: "TIME",
      ratings_no_participants: "No participants.",

      courses_title: "Courses",

      subject_hub_title: "Subject",
      subject_hub_meta: "Study / Competitive",

      profile_metric_competitive: "Competitive",
      profile_metric_study: "Study",

      done: "Done",
      error_try_again: "Error — please try again",

      // Languages
      lang_ru: "Русский",
      lang_uz: "O‘zbek",
      lang_en: "English",

      // Registration
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
      reg_nonstudent_text:
        "If you are not a school student, you can study and practice all subjects without tours. You can add or remove subjects later in your profile.",

      reg_subject_primary_tag: "Primary",
      reg_subject_secondary_tag: "Secondary",
      reg_subject_summary_none: "Select up to 2 subjects",

      reg_terms_text: "I agree to the Terms of Service and consent to processing of my education data.",
      reg_complete_btn: "Complete Registration",
      reg_subjects_limit: "You can choose up to 2 subjects.",

      reg_subject_label_competitive: "Competitive subject",
      reg_subject_hint_competitive: "Choose your primary focus for the leaderboard",
      reg_subject_label_study: "Study subject",
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

      // Subjects
      subj_informatics: "Informatics",
      subj_economics: "Economics",
      subj_biology: "Biology",
      subj_chemistry: "Chemistry",
      subj_mathematics: "Mathematics",

      // Limits / Validation
      competitive_subjects_limit_2: "Competitive subjects limit is 2",
      fill_required_fields: "Please fill required fields",

      // Availability messages
      not_available: "Not available",
      disabled_not_school: "Tours and ratings are available only for school students.",
      disabled_not_competitive: "This feature is available only for competitive subjects.",
      tours_denied_title: "Tours unavailable",
      disabled_not_main: "Tours are available only for main subjects.",
      disabled_tour_dates: "Tour is not available by dates.",
      ratings_info: "Ratings include competitive subjects with active tours. Ties are resolved by time.",

      // Home
      home_competitive_mode: "Competitive Mode",
      home_competitive_mode_subtitle: "Track your Cambridge curriculum progress",
      home_active_tour: "Active Tour",
      home_pinned_subjects: "Pinned Subjects",
      home_show_all_subjects: "Show All Subjects",
      home_course_completion: "Course Completion",
      home_rank_label: "Rank",
      home_lessons_label: "Lessons",
      home_competitive_empty: "No competitive subjects yet.",
      home_pinned_empty: "Pin subjects in Courses to see them here.",
      home_need_registration: "Please complete registration first.",

      // UI badges / labels (Courses + Home)
      badge_active: "ACTIVE",
      badge_pinned: "Pinned",
      badge_competitive: "Competitive",
      module_label: "MODULE {n}",
      open_subject_btn: "Open subject",

      // Courses UI
      courses_filter_competitive: "Competitive",
      courses_filter_study: "Study",
      courses_section_main: "Main (Cambridge)",
      courses_section_additional: "Additional",

      // Modes / Subject Hub meta
      mode_competitive: "Competitive",
      mode_study: "Study",
      hub_pinned: "Pinned",
      hub_not_pinned: "Not pinned",
      hub_not_added: "Not added",

      // Profile
      profile_title: "Academic Profile",
      profile_status_badge: "ADVANCED STATUS",
      profile_performance_overview: "Performance Overview",
      profile_stability_score: "Stability (7d)",
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

      cred_kicker_progress: "PROGRESS",
      cred_label_focused: "Focused streak",
      cred_label_practice: "Practice mastery",

      cred_consistent_learner: "Consistent Learner",
      cred_focused_study_streak: "Focused Study Streak",
      cred_active_video_learner: "Active Video Learner",
      cred_practice_mastery_subject: "Practice Mastery",
      cred_error_driven_learner: "Error-Driven Learner",
      cred_research_oriented_learner: "Research-Oriented Learner",
      cred_fair_play_participant: "Fair Play Participant",

      cred_status_active: "Active",
      cred_status_inactive: "Inactive",
      cred_status_expired: "Expired",
      cred_status_revoked: "Revoked",

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
      course_competitive_detach_message:
        "This subject will be removed from Competitive.\n\n• Tours, leaderboards and certificates will be unavailable.\n• Study mode will remain available.\n\nNote: if you enable Competitive again, tour/leaderboard progress may restart.",
      course_competitive_detach_ok: "Disable",
      course_competitive_detach_toast: "Competitive disabled. Subject stays available in Study.",

      course_toggle_on: "Enabled",
      course_toggle_off: "Disabled",
      course_toggle_aria: "Show on Home",

      toast_time_expired_answer_saved: "Time is up. Answer saved…",
      toast_time_expired_no_answer: "Time is up. Question saved without an answer…",

      settings_competitive_note:
        "You can select up to 2 subjects in Competitive. Selected: {count}/2.",
      settings_hide: "Hide",
      settings_show_all: "Show all",
      settings_pinned: "Pinned",
      settings_not_pinned: "Not pinned",
      settings_no_pinned: "No pinned subjects yet",
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

      tours_status_not_school_title: "Tours are for students only",
      tours_status_not_school_desc: "Complete your profile as a student to participate.",
      tours_only_main_subjects: "Tours are available only for main subjects.",
      tours_active_and_completed: "Active and completed",

      tours_status_not_comp_title: "Tours require competitive mode",
      tours_status_not_comp_desc: "Add this subject in competitive mode to unlock tours.",

      tours_empty_title: "Tours will appear later",
      tours_empty_desc:
        "This section becomes available after the database is connected and tour dates are published.",

      tours_title: "Tours",
      tours_subtitle: "Active and completed",
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

      school_prefix: "School",
      class_suffix: "grade",

      ratings_my_rank: "MY RANK",
      ratings_search_title: "Search",
      ratings_search_label: "Name / school / class",
      ratings_search_hint: "Type any part of a name, school or class.",
      btn_reset: "Reset",
      btn_apply: "Apply",
      ratings_out_of: "out of",
      ratings_of_total: "of {total}",
      points_short: "pts",

      ratings_top: "Top 10",
      ratings_around: "Around me",
      ratings_bottom: "Bottom 3",

      tour_rules_title: "Tour rules",
      tour_rules_accept_required: "Please accept the rules to start the tour.",

      profile_ui_language_title: "Interface Language",
      profile_ui_language_desc:
        "Changes only the application interface and does not affect tours or practice.",
      profile_content_language_title: "Tours & Practice Language",
      profile_content_language_desc:
        "Changing this language will delete all progress (tours, practice, answers). Use only if necessary.",

      confirm_content_lang_change:
        "Changing the tours and practice language will delete all progress. Continue?",
      toast_content_lang_changed:
        "Tours and practice language updated. Progress has been reset.",

      input_number: "Enter a number",
      input_text: "Enter your answer",
      select_option_required: "Please select an option",
      invalid_answer_format: "Please check the answer format",

      topic_general: "General",

      yes: "Yes",
      no: "No",
      cancel: "Cancel",
      ok: "OK",

      profile_settings_competitive_title: "Competitive Mode",
      profile_settings_study_title: "Study Mode",
      profile_settings_study_desc:
        "Pinned subjects are for quick access in Study. Competitive is configured above.",
      profile_settings_more_title: "More",
      profile_settings_news_title: "News",
      profile_settings_news_sub: "Announcements & updates",
      profile_settings_notifications_title: "Notifications",
      profile_settings_notifications_sub: "System events",
      profile_settings_community_title: "Community",
      profile_settings_community_sub: "@iClubuzofficial",

      profile_pinned_hint_has: "Pinned subjects already speed things up. Next: consistency.",
      profile_pinned_hint_empty: "Pin 1–3 subjects to make access noticeably faster."
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
  }

  function getLang() {
    return currentLang;
  }

  window.i18n = {
    t,
    setLang,
    getLang,
    normalizeLang
  };
})();
