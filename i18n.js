(function () {
  const DICT = {
    loading: { ru: "Загрузка…", uz: "Yuklanmoqda…", en: "Loading…" },
    registration: { ru: "Регистрация", uz: "Ro‘yxatdan o‘tish", en: "Registration" },
    full_name: { ru: "ФИО", uz: "F.I.Sh.", en: "Full name" },
    region: { ru: "Регион", uz: "Viloyat", en: "Region" },
    district: { ru: "Район", uz: "Tuman", en: "District" },
    language: { ru: "Язык", uz: "Til", en: "Language" },
    are_you_school: { ru: "Вы ученик школы?", uz: "Maktab o‘quvchisimisiz?", en: "Are you a school student?" },
    school: { ru: "Школа", uz: "Maktab", en: "School" },
    class: { ru: "Класс", uz: "Sinf", en: "Class" },
    choose_main_subject: {
      ru: "Выберите 1 основной предмет (он станет соревновательным #1, если вы школьник).",
      uz: "1 ta asosiy fan tanlang (maktab o‘quvchisi bo‘lsangiz, u musobaqaviy #1 bo‘ladi).",
      en: "Choose 1 main subject (it becomes competitive #1 if you are a student)."
    },
    choose_optional_subject: {
      ru: "Опционально: выберите 1 дополнительный предмет (он будет учебным).",
      uz: "Ixtiyoriy: 1 ta qo‘shimcha fan tanlang (u o‘quv rejimida bo‘ladi).",
      en: "Optional: choose 1 additional subject (study only)."
    },
    consent_text: { ru: "Я согласен(а) на обработку данных", uz: "Ma’lumotlarni qayta ishlashga roziman", en: "I consent to data processing" },
    continue: { ru: "Продолжить", uz: "Davom etish", en: "Continue" },

    home_title: { ru: "Главная", uz: "Bosh sahifa", en: "Home" },
    competitive_subjects: { ru: "Соревновательные предметы", uz: "Musobaqaviy fanlar", en: "Competitive subjects" },
    study_subjects: { ru: "Учебные предметы", uz: "O‘quv fanlari", en: "Study subjects" },
    quick_actions: { ru: "Быстрые действия", uz: "Tezkor amallar", en: "Quick actions" },
    open_courses: { ru: "Открыть Courses", uz: "Courses ochish", en: "Open Courses" },
    open_profile: { ru: "Открыть Profile", uz: "Profile ochish", en: "Open Profile" },

    courses: { ru: "Courses", uz: "Courses", en: "Courses" },
    all_subjects: { ru: "Все предметы", uz: "Barcha fanlar", en: "All subjects" },
    pin_or_open_once: { ru: "Закрепить или открыть один раз", uz: "Biriktirish yoki bir martalik ochish", en: "Pin or open once" },
    resources: { ru: "Ресурсы", uz: "Resurslar", en: "Resources" },
    lessons: { ru: "Видео-уроки", uz: "Video darslar", en: "Lessons" },
    lessons_hint: { ru: "Открой урок → смотри или пропусти → затем практика", uz: "Dars → ko‘rish/yoki o‘tkazish → amaliyot", en: "Open → watch/skip → practice" },
    video_placeholder: { ru: "Здесь будет плеер (в v1 можно открыть ссылку).", uz: "Bu yerda pleer bo‘ladi (v1 da havola).", en: "Player goes here (v1 can open link)." },
    start_video: { ru: "Начать", uz: "Boshlash", en: "Start" },
    skip_video: { ru: "Пропустить (знаю тему)", uz: "O‘tkazib yuborish (bilaman)", en: "Skip (I know it)" },
    finish_video: { ru: "Завершить", uz: "Yakunlash", en: "Finish" },

    practice: { ru: "Практика", uz: "Amaliyot", en: "Practice" },
    practice_rules: { ru: "10 вопросов (3 лёгких, 5 средних, 2 сложных). Античит не применяется.", uz: "10 savol (3 oson, 5 o‘rta, 2 qiyin). Anticheat yo‘q.", en: "10 questions (3 easy, 5 medium, 2 hard). No anti-cheat." },
    start_practice: { ru: "Начать практику", uz: "Amaliyotni boshlash", en: "Start practice" },
    pause: { ru: "Пауза", uz: "Pauza", en: "Pause" },

    next: { ru: "Далее", uz: "Keyingi", en: "Next" },
    result: { ru: "Результат", uz: "Natija", en: "Result" },
    review_errors: { ru: "Разбор ошибок", uz: "Xatolar tahlili", en: "Review errors" },
    go_recommendations: { ru: "Рекомендации", uz: "Tavsiyalar", en: "Recommendations" },
    back_to_subject: { ru: "Назад к предмету", uz: "Fanga qaytish", en: "Back to subject" },
    recommendations: { ru: "Рекомендации", uz: "Tavsiyalar", en: "Recommendations" },
    read_recommended: { ru: "Рекомендуем прочитать по темам ошибок", uz: "Xatolar bo‘yicha o‘qishni tavsiya qilamiz", en: "Recommended reading based on errors" },

    tours: { ru: "Туры", uz: "Turlar", en: "Tours" },
    tour_rules: { ru: "Правила тура", uz: "Tur qoidalari", en: "Tour rules" },
    tour_rule_one_attempt: { ru: "Проходится один раз, без паузы", uz: "Bir marta, pauzasiz", en: "One attempt, no pause" },
    tour_rule_no_back: { ru: "Нельзя возвращаться к предыдущим вопросам", uz: "Oldingi savollarga qaytib bo‘lmaydi", en: "No going back" },
    tour_rule_autosave: { ru: "Ответы сохраняются автоматически при истечении времени", uz: "Vaqt tugasa javob avtomatik saqlanadi", en: "Auto-save on time expiry" },
    tour_rule_anticheat: { ru: "Античит: 2 нарушения → завершение тура", uz: "Anticheat: 2 marta → yakun", en: "Anti-cheat: 2 strikes → end" },
    i_accept_rules: { ru: "Я согласен(на) с правилами", uz: "Qoidalarga roziman", en: "I accept the rules" },
    start_tour: { ru: "Начать тур", uz: "Turni boshlash", en: "Start tour" },
    tour: { ru: "Тур", uz: "Tur", en: "Tour" },
    certificate: { ru: "Сертификат", uz: "Sertifikat", en: "Certificate" },

    ratings: { ru: "Ratings", uz: "Ratings", en: "Ratings" },
    ratings_hint: { ru: "Рейтинги доступны только для соревновательных предметов и активных туров.", uz: "Reyting faqat musobaqaviy fanlar va faol turlar uchun.", en: "Ratings are for competitive subjects and active tours only." },

    profile: { ru: "Profile", uz: "Profile", en: "Profile" },
    settings: { ru: "Настройки", uz: "Sozlamalar", en: "Settings" },
    notifications: { ru: "Уведомления", uz: "Bildirishnomalar", en: "Notifications" },
    competitive_manage: { ru: "Управление соревновательными (≤2)", uz: "Musobaqaviy boshqaruv (≤2)", en: "Manage competitive (≤2)" },
    pinned_manage: { ru: "Закреплённые учебные", uz: "Biriktirilgan o‘quv", en: "Pinned study" },
    save: { ru: "Сохранить", uz: "Saqlash", en: "Save" },

    books: { ru: "Книги", uz: "Kitoblar", en: "Books" },
    books_hint: { ru: "Чтение и скачивание", uz: "O‘qish va yuklab olish", en: "Read & download" },
    open: { ru: "Открыть", uz: "Ochish", en: "Open" },
    my_recommendations: { ru: "Мои рекомендации", uz: "Mening tavsiyalarim", en: "My recommendations" },
    certificates: { ru: "Сертификаты", uz: "Sertifikatlar", en: "Certificates" },
  };

  function getLang() {
    const saved = localStorage.getItem("lang");
    if (saved) return saved;
    return "ru";
  }

  function t(key) {
    const lang = getLang();
    const entry = DICT[key];
    if (!entry) return key;
    return entry[lang] || entry.ru || key;
  }

  function applyI18n(root = document) {
    const lang = getLang();
    root.querySelectorAll("[data-i18n]").forEach(el => {
      const key = el.getAttribute("data-i18n");
      el.textContent = t(key);
    });

    // tab labels (keep in English in UI? we’ll keep as is for now)
    document.documentElement.lang = lang;
  }

  window.i18n = { t, applyI18n, getLang };
})();

