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
  loading_desc: "Получаем список туров…",
  saving: "Сохранение…",

       community_title: "Комьюнити",
community_sub: "Официальный канал и чат обсуждений.",
community_channel_title: "Канал",
community_chat_title: "Чат обсуждений",
community_join: "Присоединиться",

about_title: "О проекте",
about_sub: "Кратко, по делу, без “воды” (её у нас достаточно в задачах по физике).",
about_card_title: "iClub",
about_card_body: "Здесь будет официальный текст из документа проекта: цели, правила участия, форматы туров, условия сертификатов и рейтингов.",

archive_title: "Архив",
archive_sub: "Прошедшие туры (только после завершения активного тура).",
archive_empty: "Архив пуст. Значит, туры ещё свежие — как ваша тревога перед дедлайном.",
       
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
      btn_detach: "Открепить",

      subject_hub_title: "Предмет",
      subject_hub_meta: "Учебный / Соревновательный",
      resources_title: "Ресурсы",

      mentor_kicker: "ВАШ МЕНТОР",
      mentor_assigning: "Ментор назначается",
      mentor_profile_soon: "Скоро появится профиль",

      hub_video_lessons_title: "Видео-уроки",
      hub_video_lessons_sub: "Смотреть или пропустить (“я знаю тему”)",
      hub_my_recs_sub: "Повторный доступ к чтению",

      hub_system_section: "Системные",
      hub_archive_sub: "Прошедшие туры",

      hub_all_subjects_title: "Все предметы",
      hub_all_subjects_sub: "Каталог предметов",

      lessons_list_subtitle: "Список видео-уроков", 

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
       // Additional Subjects
      subj_english_a1: "Английский (A1)",
      subj_english_a2: "Английский (A2)",
      subj_english_b1: "Английский (B1)",
      subj_sat: "SAT",
      subj_ielts: "IELTS",

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
      profile_my_recs_row_title: "Мои рекомендации",
      profile_my_recs_row_sub: "Архив рекомендаций",

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
      notifications_title: "Уведомления",
      notifications_sub: "Системные сообщения и важные события.",
      notifications_empty: "Пока тихо. Это подозрительно приятно.",

      certificates_title: "Сертификаты",
      certificates_sub: "По турам и итоговые — в зависимости от правил доступа.",
      certificates_empty: "Пока нет сертификатов. Это не проблема — это мотивация.",
      profile_certificates_row_title: "Мои сертификаты",
      profile_certificates_row_sub: "Туры и финальные результаты",
      profile_join_btn: "+ ПОДКЛЮЧИТЬ",
      profile_empty_slot: "Пустой слот соревновательного режима",
      profile_settings_more: "Ещё",
      profile_settings_community: "Сообщество",
      profile_settings_about: "О проекте",
      profile_settings_about_sub: "Правила и организаторы",

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
      tours_archive_locked_toast: "🔒 Архив закрыт. Сначала завершите активный тур.",

      tours_active_now: "Активный тур сейчас",
      tour_unavailable_title: "Тур недоступен",
      tour_unavailable_already_attempted: "Вы уже завершили этот тур. Повторное прохождение недоступно.",

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
      tour_rules_subtitle: "Перед стартом необходимо согласие",
tour_rules_important: "Важное",
tour_rules_li1: "Одна попытка, без пауз",
tour_rules_li2: "Назад-вперёд запрещено",
tour_rules_li3: "Античит: 2 нарушения → завершение",
tour_rules_li4: "Автосохранение при таймауте",
tour_rules_accept: "Я ознакомился и согласен с правилами",
tour_start_btn: "Начать тур",

tour_progress_label: "Прогресс тура",
tour_overall_tour: "ТУР — ОБЩЕЕ ВРЕМЯ",
tour_question_time: "ВРЕМЯ НА ВОПРОС",
tour_monitoring_active: "СЕССИЯ ПОД МОНИТОРИНГОМ",
tour_next_question: "Следующий вопрос →",

tour_result_title: "Результат тура",
tour_review_title: "Разбор тура",
tour_review_sub: "Ответы, объяснения, ошибки",
tour_certificate_title: "Сертификат",
tour_certificate_sub: "Если доступен по правилам",

tour_review_screen_title: "Разбор тура",
tour_review_screen_sub: "Ответы, объяснения и работа над ошибками",
tour_review_empty: "Разбор появится после подключения данных тура.",

back_to_result: "Назад к результату",
to_subject: "К предмету",
open_ratings: "Рейтинг",

tour_question_of: "Вопрос {q} из {total}",
tour_result_meta: "Результат: {score}/{total} • Нарушения: {v}",
tour_violation_toast: "Внимание: мониторинг сессии ({v}/{max})",
tour_archive_toast: "Архивный тур: вне рейтинга",
tour_violations_finish_toast: "Тур завершён: нарушения сессии",

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
      notifications_title: "Уведомления",
      notifications_sub: "Системные сообщения и важные события.",
      notifications_empty: "Пока тихо. Это подозрительно приятно.",
      btn_back: "Назад",
      btn_go_home: "На главную",
      profile_settings_community_title: "Сообщество",
      profile_settings_community_sub: "@iClubuzofficial",

       books_title: "Книги",
books_subtitle: "Ресурсы по предмету",
books_empty_static: "Список книг подключим через базу.",

books_loading: "Загрузка…",
books_pick_subject_first: "Сначала выберите предмет.",
books_no_db: "Нет подключения к базе.",
books_subject_not_found: "Предмет не найден в базе.",
books_empty: "По этому предмету книги пока не добавлены.",
books_open_pdf: "Открыть PDF",

my_recs_screen_title: "Мои рекомендации",
my_recs_screen_subtitle: "Сохранённые рекомендации по чтению",
my_recs_empty_static: "Пока пусто.",
my_recs_empty: "Пока пусто.",
saved_at_label: "Сохранено",

      // Pinned hints
      profile_pinned_hint_has:
        "Закреплённые предметы уже ускоряют доступ. Дальше — стабильность.",
      profile_pinned_hint_empty:
        "Закрепите 1–3 предмета — и доступ к нужному станет заметно быстрее."
    },

    uz: {
        app_name: "iClub",
        loading: "Yuklanmoqda…",
        loading_desc: "Turlar ro‘yxati yuklanmoqda…",
        saving: "Saqlanmoqda…",

       community_title: "Hamjamiyat",
community_sub: "Rasmiy kanal va muhokama chati.",
community_channel_title: "Kanal",
community_chat_title: "Muhokama chati",
community_join: "Qo‘shilish",

about_title: "Loyiha haqida",
about_sub: "Qisqa va aniq. “Suv”siz (u esa bizda fizika masalalarida yetarli).",
about_card_title: "iClub",
about_card_body: "Bu yerda loyiha hujjatidagi rasmiy matn bo‘ladi: maqsadlar, qatnashish qoidalari, tur formatlari, sertifikat va reyting shartlari.",

archive_title: "Arxiv",
archive_sub: "O‘tgan turlar (faol tur yakunlangandan keyin).",
archive_empty: "Arxiv bo‘sh. Demak, turlar hali “yangi” — deadline oldidagi hayajoningiz kabi.",
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
      btn_detach: "Biriktirishni yechish",

      subject_hub_title: "Fan",
      subject_hub_meta: "O‘quv / Musobaqa",
      resources_title: "Resurslar",

      mentor_kicker: "MENTORINGIZ",
      mentor_assigning: "Mentor tayinlanmoqda",
      mentor_profile_soon: "Tez orada profil paydo bo‘ladi",

      hub_video_lessons_title: "Video darslar",
      hub_video_lessons_sub: "Ko‘rish yoki o‘tkazib yuborish (“mavzuni bilaman”)",
      hub_my_recs_sub: "Qayta ko‘rish uchun ochish",

      hub_system_section: "Tizim",
      hub_archive_sub: "O‘tgan turlar",

      hub_all_subjects_title: "Barcha fanlar",
      hub_all_subjects_sub: "Fanlar katalogi",

      lessons_list_subtitle: "Video darslar ro‘yxati", 

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
      // Additional Subjects
      subj_english_a1: "Ingliz tili (A1)",
      subj_english_a2: "Ingliz tili (A2)",
      subj_english_b1: "Ingliz tili (B1)",
      subj_sat: "SAT",
      subj_ielts: "IELTS", 

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
      profile_my_recs_row_title: "Tavsiyalarim",
      profile_my_recs_row_sub: "Tavsiyalar arxivi",

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
      notifications_title: "Bildirishnomalar",
      notifications_sub: "Tizim xabarlari va muhim voqealar.",
      notifications_empty: "Hozircha jim. Bu shubhali darajada yoqimli.",

      certificates_title: "Sertifikatlar",
      certificates_sub: "Turlar va yakuniy natijalar — kirish qoidalariga ko‘ra.",
      certificates_empty: "Hozircha sertifikatlar yo‘q. Muammo emas — motivatsiya.",
      profile_certificates_row_title: "Sertifikatlarim",
      profile_certificates_row_sub: "Turlar va yakuniy natijalar",
      profile_join_btn: "+ ULASH",
      profile_empty_slot: "Bo‘sh musobaqa sloti",
      profile_settings_more: "Qo‘shimcha",
      profile_settings_community: "Hamjamiyat",
      profile_settings_about: "Loyiha haqida",
      profile_settings_about_sub: "Qoidalar va tashkilotchilar",
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
      tours_archive_locked_toast: "🔒 Arxiv yopiq. Avval faol turni yakunlang.",

tours_active_now: "Hozir faol tur",
tour_unavailable_title: "Tur mavjud emas",
tour_unavailable_already_attempted: "Siz bu turni allaqachon yakunlagansiz. Qayta topshirish mumkin emas.",

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
      tour_rules_accept_required: "Tur boshlash uchun qoidalarga rozilikni tasdiqlang.",
       tour_rules_subtitle: "Boshlashdan oldin rozilik kerak",
tour_rules_important: "Muhim",
tour_rules_li1: "Bitta urinish, pauzasiz",
tour_rules_li2: "Orqaga-oldinga taqiqlangan",
tour_rules_li3: "Anti-cheat: 2 buzilish → yakun",
tour_rules_li4: "Vaqt tugasa avtomatik saqlanadi",
tour_rules_accept: "Qoidalar bilan tanishdim va roziman",
tour_start_btn: "Turni boshlash",

tour_progress_label: "Tur jarayoni",
tour_overall_tour: "TUR — UMUMIY VAQT",
tour_question_time: "SAVOL VAQTI",
tour_monitoring_active: "SESSIYA NAZORATDA",
tour_next_question: "Keyingi savol →",

tour_result_title: "Tur natijasi",
tour_review_title: "Tur tahlili",
tour_review_sub: "Javoblar, izohlar, xatolar",
tour_certificate_title: "Sertifikat",
tour_certificate_sub: "Qoidalarga ko‘ra mavjud bo‘lsa",

tour_review_screen_title: "Tur tahlili",
tour_review_screen_sub: "Javoblar, izohlar va xatolar ustida ishlash",
tour_review_empty: "Tur ma’lumotlari ulangach tahlil ko‘rinadi.",

back_to_result: "Natijaga qaytish",
to_subject: "Fanga",
open_ratings: "Reyting",

tour_question_of: "{q}/{total} savol",
tour_result_meta: "Natija: {score}/{total} • Buzilish: {v}",
tour_violation_toast: "Ogohlantirish: sessiya nazorati ({v}/{max})",
tour_archive_toast: "Arxiv tur: reytingga kirmaydi",
tour_violations_finish_toast: "Tur yakunlandi: sessiya buzilishlari",

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
      notifications_title: "Bildirishnomalar",
      notifications_sub: "Tizim xabarlari va muhim voqealar.",
      notifications_empty: "Hozircha jim. Bu shubhali darajada yoqimli.",
      btn_back: "Ortga",
      btn_go_home: "Bosh sahifaga",
      profile_settings_community_title: "Hamjamiyat",
      profile_settings_community_sub: "@iClubuzofficial",

       books_title: "Kitoblar",
books_subtitle: "Fan bo‘yicha resurslar",
books_empty_static: "Kitoblar ro‘yxati bazadan ulanadi.",

books_loading: "Yuklanmoqda…",
books_pick_subject_first: "Avval fanni tanlang.",
books_no_db: "Baza bilan ulanish yo‘q.",
books_subject_not_found: "Fan bazada topilmadi.",
books_empty: "Bu fan bo‘yicha kitoblar hali qo‘shilmagan.",
books_open_pdf: "PDFni ochish",

my_recs_screen_title: "Mening tavsiyalarim",
my_recs_screen_subtitle: "O‘qish bo‘yicha saqlangan tavsiyalar",
my_recs_empty_static: "Hozircha bo‘sh.",
my_recs_empty: "Hozircha bo‘sh.",
saved_at_label: "Saqlangan",

      // Pinned hints
      profile_pinned_hint_has:
        "Biriktirilgan fanlar tezkor kirishni ta’minlaydi. Barqarorlik — natijaning asosi.",
      profile_pinned_hint_empty:
        "1–3 ta fanni biriktiring — kerakli bo‘limlarga tezroq kirish imkoniyati yaratiladi."
    },

    en: {
  app_name: "iClub",
  loading: "Loading…",
  loading_desc: "Fetching tour list…",
  saving: "Saving…",

       community_title: "Community",
community_sub: "Official channel and discussion chat.",
community_channel_title: "Channel",
community_chat_title: "Discussion chat",
community_join: "Join",

about_title: "About",
about_sub: "Short and clear. No “water” (we have enough of it in physics tasks).",
about_card_title: "iClub",
about_card_body: "Official project text will appear here: goals, participation rules, tour formats, certificate and rating rules.",

archive_title: "Archive",
archive_sub: "Past tours (only after the active tour is finished).",
archive_empty: "Archive is empty. Tours are still fresh — like pre-deadline anxiety.",

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
      btn_detach: "Unpin",

      subject_hub_title: "Subject",
      subject_hub_meta: "Study / Competitive",
      resources_title: "Resources",

      mentor_kicker: "YOUR MENTOR",
      mentor_assigning: "Mentor will be assigned",
      mentor_profile_soon: "Profile coming soon",

      hub_video_lessons_title: "Video lessons",
      hub_video_lessons_sub: "Watch or skip (“I know this topic”)",
      hub_my_recs_sub: "Re-open for review",

      hub_system_section: "System",
      hub_archive_sub: "Past tours",

      hub_all_subjects_title: "All subjects",
      hub_all_subjects_sub: "Subjects catalog",

      lessons_list_subtitle: "Video lessons list",

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
       // Additional Subjects
      subj_english_a1: "English (A1)",
      subj_english_a2: "English (A2)",
      subj_english_b1: "English (B1)",
      subj_sat: "SAT",
      subj_ielts: "IELTS",

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
      profile_my_recs_row_title: "My recommendations",
      profile_my_recs_row_sub: "Recommendations archive",

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
      notifications_title: "Notifications",
      notifications_sub: "System messages and important events.",
      notifications_empty: "All quiet. Suspiciously pleasant.",

      certificates_title: "Certificates",
      certificates_sub: "Tour and final certificates — depending on access rules.",
      certificates_empty: "No certificates yet. Not a problem — motivation.",
      profile_certificates_row_title: "My certificates",
      profile_certificates_row_sub: "Tours & final results",
      profile_join_btn: "+ JOIN",
      profile_empty_slot: "Empty Competitive Slot",
      profile_settings_more: "More",
      profile_settings_community: "Community",
      profile_settings_about: "About project",
      profile_settings_about_sub: "Rules and organizers",

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
      tours_archive_locked_toast: "🔒 Archive is locked. Finish the active tour first.",

      tours_active_now: "Active tour now",
      tour_unavailable_title: "Tour unavailable",
      tour_unavailable_already_attempted: "You have already completed this tour. Retakes are not available.",

      // Tours
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
       tour_rules_subtitle: "Consent required before starting",
tour_rules_important: "Important",
tour_rules_li1: "One attempt, no pauses",
tour_rules_li2: "Back/forward is not allowed",
tour_rules_li3: "Anti-cheat: 2 violations → finish",
tour_rules_li4: "Auto-save on timeout",
tour_rules_accept: "I have read and accept the rules",
tour_start_btn: "Start tour",

tour_progress_label: "Tour Progress",
tour_overall_tour: "OVERALL TOUR",
tour_question_time: "QUESTION TIME",
tour_monitoring_active: "SESSION MONITORING ACTIVE",
tour_next_question: "Next Question →",

tour_result_title: "Tour result",
tour_review_title: "Tour review",
tour_review_sub: "Answers, explanations, mistakes",
tour_certificate_title: "Certificate",
tour_certificate_sub: "If available by rules",

tour_review_screen_title: "Tour review",
tour_review_screen_sub: "Answers, explanations and work on mistakes",
tour_review_empty: "Review will appear after tour data is connected.",

back_to_result: "Back to result",
to_subject: "To subject",
open_ratings: "Ratings",

tour_question_of: "Question {q} of {total}",
tour_result_meta: "Score: {score}/{total} • Violations: {v}",
tour_violation_toast: "Warning: session monitoring ({v}/{max})",
tour_archive_toast: "Archived tour: not in ratings",
tour_violations_finish_toast: "Tour finished: session violations",

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
      notifications_title: "Notifications",
      notifications_sub: "System messages and important events.",
      notifications_empty: "All quiet. Suspiciously pleasant.",
      btn_back: "Back",
      btn_go_home: "Home",
      profile_settings_community_title: "Community",
      profile_settings_community_sub: "@iClubuzofficial",

       books_title: "Books",
books_subtitle: "Subject resources",
books_empty_static: "Books list will be connected via the database.",

books_loading: "Loading…",
books_pick_subject_first: "Please choose a subject first.",
books_no_db: "No database connection.",
books_subject_not_found: "Subject not found in the database.",
books_empty: "No books have been added for this subject yet.",
books_open_pdf: "Open PDF",

my_recs_screen_title: "My recommendations",
my_recs_screen_subtitle: "Saved reading recommendations",
my_recs_empty_static: "Nothing here yet.",
my_recs_empty: "Nothing here yet.",
saved_at_label: "Saved",

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
