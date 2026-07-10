(() => {
  'use strict';

  const PREFIX = 'iclub_demo_v12.';
  const STATE_KEY = PREFIX + 'state';
  const TECH_KEY = PREFIX + 'technical';
  const VALID_PLANS = new Set(['free', 'plus', 'pro']);
  const VALID_LANGS = new Set(['ru', 'uz', 'en']);

  const COPY = {
    ru: {
      showMode: 'РЕЖИМ ПОКАЗА',
      subject: 'Экономика', mode: 'Соревновательный', mentor: 'ВАШ МЕНТОР',
      mentorName: 'Erkinov Azizbek', mentorSub: 'AS Level Economics',
      content: 'Контент', practice: 'Практика', tours: 'Туры', resources: 'Ресурсы',
      video: 'Видео-уроки', videoSub: 'Видео-уроки доступны в Telegram',
      recs: 'Мои рекомендации', recsSub: 'Повторный доступ к чтению',
      system: 'Системные', certificates: 'Сертификаты', certificatesSub: 'Туры и финальные результаты',
      archive: 'Архив туров', archiveSub: 'Самопроверка • вне рейтинга',
      all: 'Все предметы', allSub: 'Каталог предметов',
      scenario: 'Сценарий', language: 'Язык интерфейса', normal: 'Обычное обучение',
      technical: 'Техническая панель', reset: 'Сбросить demo', close: 'Закрыть',
      copied: 'Этот экран скопирован из main app и работает на локальных demo-данных.',
      next: 'Следующий экран будет подключён после принятия точной копии Subject Hub.',
      mentorInfo: 'Профиль ментора в demo не обращается к базе.',
      resetConfirm: 'Сбросить только локальные данные demo?',
      resetDone: 'Локальные данные demo сброшены.',
      dataSource: 'Источник данных', storage: 'Хранилище', productionCalls: 'Production-запросы', currentPlan: 'Тариф', guard: 'Сетевая защита'
    },
    uz: {
      showMode: 'NAMOYISH REJIMI',
      subject: 'Iqtisodiyot', mode: 'Musobaqa rejimi', mentor: 'SIZNING MENTORINGIZ',
      mentorName: 'Erkinov Azizbek', mentorSub: 'AS Level Economics',
      content: 'Kontent', practice: 'Mashq', tours: 'Turlar', resources: 'Resurslar',
      video: 'Video darslar', videoSub: 'Video darslar Telegramda mavjud',
      recs: 'Mening tavsiyalarim', recsSub: 'O‘qish materialiga qaytish',
      system: 'Tizimli', certificates: 'Sertifikatlar', certificatesSub: 'Turlar va yakuniy natijalar',
      archive: 'Turlar arxivi', archiveSub: 'O‘zini tekshirish • reytingdan tashqari',
      all: 'Barcha fanlar', allSub: 'Fanlar katalogi',
      scenario: 'Ssenariy', language: 'Interfeys tili', normal: 'Oddiy o‘qish',
      technical: 'Texnik panel', reset: 'Demo holatini tiklash', close: 'Yopish',
      copied: 'Bu ekran main app dan ko‘chirildi va lokal demo ma’lumotlari bilan ishlaydi.',
      next: 'Keyingi ekran Subject Hub aniq nusxasi qabul qilingandan keyin ulanadi.',
      mentorInfo: 'Demo mentor profili bazaga murojaat qilmaydi.',
      resetConfirm: 'Faqat lokal demo ma’lumotlari tiklansinmi?',
      resetDone: 'Lokal demo ma’lumotlari tiklandi.',
      dataSource: 'Ma’lumot manbasi', storage: 'Saqlash', productionCalls: 'Production so‘rovlari', currentPlan: 'Tarif', guard: 'Tarmoq himoyasi'
    },
    en: {
      showMode: 'DEMO MODE',
      subject: 'Economics', mode: 'Competitive', mentor: 'YOUR MENTOR',
      mentorName: 'Erkinov Azizbek', mentorSub: 'AS Level Economics',
      content: 'Content', practice: 'Practice', tours: 'Tours', resources: 'Resources',
      video: 'Video lessons', videoSub: 'Video lessons are available in Telegram',
      recs: 'My recommendations', recsSub: 'Return to saved reading',
      system: 'System', certificates: 'Certificates', certificatesSub: 'Tours and final results',
      archive: 'Tour archive', archiveSub: 'Self-check • outside ranking',
      all: 'All subjects', allSub: 'Subject catalogue',
      scenario: 'Scenario', language: 'Interface language', normal: 'Normal learning',
      technical: 'Technical panel', reset: 'Reset demo', close: 'Close',
      copied: 'This screen is copied from the main app and runs on local demo data.',
      next: 'The next screen will be connected after the exact Subject Hub copy is accepted.',
      mentorInfo: 'The demo mentor profile does not query the database.',
      resetConfirm: 'Reset only local demo data?',
      resetDone: 'Local demo data reset.',
      dataSource: 'Data source', storage: 'Storage', productionCalls: 'Production calls', currentPlan: 'Plan', guard: 'Network guard'
    }
  };

  const $ = (id) => document.getElementById(id);
  const read = (key, fallback = {}) => {
    try { return JSON.parse(localStorage.getItem(key) || '') || fallback; } catch { return fallback; }
  };
  const write = (key, value) => {
    try { localStorage.setItem(key, JSON.stringify(value)); } catch {}
  };

  const initial = read(STATE_KEY, {});
  let plan = VALID_PLANS.has(initial.plan) ? initial.plan : 'free';
  let lang = VALID_LANGS.has(initial.lang) ? initial.lang : 'ru';

  function t() { return COPY[lang] || COPY.ru; }
  function set(id, value) { const node = $(id); if (node) node.textContent = value; }

  function persist() {
    write(STATE_KEY, { ...read(STATE_KEY, {}), plan, lang, screen: 'subject-hub' });
    try {
      sessionStorage.setItem(TECH_KEY, JSON.stringify({
        gate: 'main-copy-foundation',
        data_source: 'static local object',
        production_calls: 0,
        storage: 'iclub_demo_v12.* only',
        plan,
        lang,
        network_guard: 'connect-src none'
      }));
    } catch {}
  }

  function render() {
    const x = t();
    document.documentElement.lang = lang;
    set('demo-planbar-label', x.showMode);
    set('subject-hub-title', x.subject);
    set('subject-hub-meta', x.mode);
    set('mentor-kicker', x.mentor);
    set('subject-hub-mentor-title', x.mentorName);
    set('subject-hub-mentor-sub', x.mentorSub);

    const tabs = document.querySelectorAll('[data-hub-tab]');
    const tabLabels = { content: x.content, practice: x.practice, tours: x.tours, resources: x.resources };
    tabs.forEach((button) => { button.textContent = tabLabels[button.dataset.hubTab] || button.textContent; });

    set('hub-video-title', x.video); set('hub-video-sub', x.videoSub);
    set('hub-recs-title', x.recs); set('hub-recs-sub', x.recsSub);
    set('hub-system-title', x.system);
    set('hub-cert-title', x.certificates); set('hub-cert-sub', x.certificatesSub);
    set('hub-archive-title', x.archive); set('hub-archive-sub', x.archiveSub);
    set('hub-all-title', x.all); set('hub-all-sub', x.allSub);

    set('demo-menu-title', x.scenario);
    set('demo-language-label', x.language);
    set('demo-normal-learning', x.normal);
    set('demo-technical', x.technical);
    set('demo-reset', x.reset);
    set('demo-close', x.close);

    document.querySelectorAll('[data-plan]').forEach((button) => {
      button.classList.toggle('is-active', button.dataset.plan === plan);
      button.setAttribute('aria-pressed', String(button.dataset.plan === plan));
    });
    document.querySelectorAll('[data-lang]').forEach((button) => {
      button.classList.toggle('is-active', button.dataset.lang === lang);
      button.setAttribute('aria-pressed', String(button.dataset.lang === lang));
    });

    persist();
  }

  let toastTimer = null;
  function toast(message) {
    const node = $('toast');
    if (!node) return;
    node.textContent = message;
    node.classList.add('is-show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => node.classList.remove('is-show'), 2400);
  }

  function openMenu() {
    const root = $('modal-root');
    if (!root) return;
    root.setAttribute('aria-hidden', 'false');
    document.body.classList.add('modal-open');
  }

  function closeMenu() {
    const root = $('modal-root');
    if (!root) return;
    root.setAttribute('aria-hidden', 'true');
    document.body.classList.remove('modal-open');
    $('demo-technical-card')?.remove();
  }

  function showTechnical() {
    const modal = document.querySelector('.demo-menu-modal');
    if (!modal) return;
    $('demo-technical-card')?.remove();
    const x = t();
    const card = document.createElement('div');
    card.id = 'demo-technical-card';
    card.className = 'demo-technical-card';
    card.innerHTML = `
      <div class="demo-technical-row"><span>${x.dataSource}</span><b>static local object</b></div>
      <div class="demo-technical-row"><span>${x.storage}</span><b>iclub_demo_v12.*</b></div>
      <div class="demo-technical-row"><span>${x.productionCalls}</span><b>0</b></div>
      <div class="demo-technical-row"><span>${x.currentPlan}</span><b>${plan}</b></div>
      <div class="demo-technical-row"><span>${x.guard}</span><b>connect-src none</b></div>`;
    modal.querySelector('.modal-actions')?.before(card);
  }

  function resetDemo() {
    const x = t();
    if (!window.confirm(x.resetConfirm)) return;
    [localStorage, sessionStorage].forEach((store) => {
      const keys = [];
      for (let i = 0; i < store.length; i += 1) {
        const key = store.key(i);
        if (key && key.startsWith(PREFIX)) keys.push(key);
      }
      keys.forEach((key) => store.removeItem(key));
    });
    plan = 'free';
    lang = 'ru';
    closeMenu();
    render();
    toast(COPY.ru.resetDone);
  }

  document.addEventListener('click', (event) => {
    const planButton = event.target.closest('[data-plan]');
    if (planButton) {
      plan = planButton.dataset.plan;
      render();
      return;
    }

    const langButton = event.target.closest('[data-lang]');
    if (langButton) {
      lang = langButton.dataset.lang;
      render();
      return;
    }

    if (event.target.closest('#topbar-action')) { openMenu(); return; }
    if (event.target.matches('[data-close-demo-menu]') || event.target.closest('#demo-close')) { closeMenu(); return; }

    const menuAction = event.target.closest('[data-demo-menu-action]')?.dataset.demoMenuAction;
    if (menuAction === 'technical') { showTechnical(); return; }
    if (menuAction === 'reset') { resetDemo(); return; }
    if (menuAction === 'learning') { closeMenu(); toast(t().copied); return; }

    if (event.target.closest('#topbar-back')) {
      if (history.length > 1) history.back();
      else toast(t().copied);
      return;
    }

    if (event.target.closest('#subject-hub-mentor-btn')) { toast(t().mentorInfo); return; }
    if (event.target.closest('[data-hub-tab]:not([data-hub-tab="content"])')) { toast(t().next); return; }
    if (event.target.closest('[data-local-action]')) { toast(t().next); }
  });

  render();
  window.ICLUB_DEMO_MAIN_LOCAL = { getState: () => ({ plan, lang, productionCalls: 0 }) };
})();
