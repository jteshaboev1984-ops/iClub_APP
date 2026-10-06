(() => {
  "use strict";

  const ENTRY_ID = "profile-plan-entry";
  const SCREEN_ID = "profile-plan";
  const COPY = {
    ru: {
      rowTitle: "Тариф",
      rowSubFree: "Free · Базовый доступ",
      rowSubPlus: "Plus · Расширенный доступ",
      rowSubPro: "Pro · Максимум возможностей",
      screenTitle: "Тариф iClub",
      screenSub: "Выбери уровень доступа, который подходит твоей учёбе.",
      perMonth: "сум / месяц",
      current: "Текущий тариф",
      choose: "Выбрать",
      coming: "Подключение скоро",
      best: "Лучший выбор",
      freeName: "Free",
      plusName: "Plus",
      proName: "Pro",
      freeLead: "Для знакомства с iClub и одного основного предмета.",
      plusLead: "Для регулярной учёбы по нескольким предметам.",
      proLead: "Для тех, кто использует iClub как основную учебную платформу.",
      compareTitle: "Сравнение возможностей",
      limitsTitle: "Как работают лимиты iClub AI",
      limitsBody: "Все тарифы используют единый 5-часовой период. Free включает до 3 готовых ответов iClub AI за период. Plus и Pro дают больше использования и поддерживают свободные вопросы; Pro рассчитан на более активную работу. Сложные запросы могут расходовать доступ быстрее. Постоянный счётчик не показывается: если лимит закончится, iClub покажет точное время восстановления. Ошибки сервиса и запросы, заблокированные во время экзамена, лимит не расходуют.",
      termsTitle: "Условия использования AI",
      termsBody: "iClub AI помогает объяснять учебный материал, результаты и уже определённые ошибки. Он не меняет академический прогресс, рейтинг, сертификаты, готовность или результаты проверок. Во время защищённой проверки AI недоступен. Академические ответы доступны только там, где iClub подготовил и разрешил проверенные источники.",
      privacyTitle: "Диалоги и данные",
      privacyBody: "В текущей версии история Global iClub AI хранится только в текущем сеансе интерфейса и не используется как доказательство знаний или прогресса. Постоянное хранение истории не будет включено до отдельного утверждения правил хранения и конфиденциальности.",
      unavailable: "Информация о тарифах сейчас недоступна.",
      checkoutUnavailable: "Подключение платных тарифов пока не запущено.",
      features: {
        subjects: "Учебные предметы",
        competitive: "Competitive-предметы",
        practice: "Practice",
        tours: "Tours, рейтинги и сертификаты",
        errors: "Разбор ошибок",
        recommendations: "Рекомендации и история",
        resources: "Книги, видео и материалы",
        examPrep: "Exam Prep",
        ai: "iClub AI",
        aiFreeText: "Свободные вопросы AI",
        support: "Поддержка и новые функции"
      },
      values: {
        freeSubjects: "1",
        plusSubjects: "До 3",
        proSubjects: "Все доступные",
        freeCompetitive: "1",
        paidCompetitive: "2",
        included: "Включено",
        activeSubjects: "В активных предметах",
        basic: "Базовый",
        aiAnalysis: "AI-разбор",
        aiAnalysisPro: "AI-разбор + расширенная история",
        standard: "Стандартные",
        personalized: "Персонализированные",
        personalizedPro: "Персонализированные + глубокий анализ",
        allSubjects: "Для всех доступных предметов",
        examIntro: "Ознакомление",
        examFull: "Полный",
        examPro: "Полный + новые модули после запуска",
        aiFree: "3 готовых ответа / 5 ч",
        aiPlus: "Повышенный лимит / 5 ч",
        aiPro: "Самый высокий лимит / 5 ч",
        no: "Нет",
        yes: "Да",
        normalSupport: "Стандартная",
        proSupport: "Приоритетная + ранний доступ после QA"
      }
    },
    uz: {
      rowTitle: "Tarif",
      rowSubFree: "Free · Asosiy kirish",
      rowSubPlus: "Plus · Kengaytirilgan kirish",
      rowSubPro: "Pro · Eng ko‘p imkoniyat",
      screenTitle: "iClub tarifi",
      screenSub: "O‘qishingizga mos kirish darajasini tanlang.",
      perMonth: "so‘m / oy",
      current: "Joriy tarif",
      choose: "Tanlash",
      coming: "Ulanish tez orada",
      best: "Eng yaxshi tanlov",
      freeName: "Free",
      plusName: "Plus",
      proName: "Pro",
      freeLead: "iClub bilan tanishish va bitta asosiy fan uchun.",
      plusLead: "Bir nechta fan bo‘yicha muntazam o‘qish uchun.",
      proLead: "iClub’dan asosiy o‘quv platformasi sifatida foydalanadiganlar uchun.",
      compareTitle: "Imkoniyatlarni taqqoslash",
      limitsTitle: "iClub AI limitlari qanday ishlaydi",
      limitsBody: "Barcha tariflar bir xil 5 soatlik davrdan foydalanadi. Free har davrda 3 tagacha tayyor iClub AI javobini beradi. Plus va Pro ko‘proq foydalanish hamda erkin savollarni qo‘llab-quvvatlaydi; Pro faolroq foydalanish uchun mo‘ljallangan. Murakkab so‘rovlar kirishni tezroq sarflashi mumkin. Doimiy hisoblagich ko‘rsatilmaydi: limit tugasa, iClub tiklanish vaqtini aniq ko‘rsatadi. Xizmat xatolari va imtihon paytida bloklangan so‘rovlar limitni sarflamaydi.",
      termsTitle: "AI’dan foydalanish shartlari",
      termsBody: "iClub AI o‘quv materialini, natijalarni va oldindan aniqlangan xatolarni tushuntirishga yordam beradi. U akademik progress, reyting, sertifikat, tayyorlik yoki tekshiruv natijalarini o‘zgartirmaydi. Himoyalangan tekshiruv vaqtida AI mavjud emas. Akademik javoblar faqat iClub tasdiqlagan manbalar mavjud bo‘lgan joylarda ishlaydi.",
      privacyTitle: "Dialoglar va ma’lumotlar",
      privacyBody: "Global iClub AI dialog tarixi hozirgi versiyada faqat joriy interfeys seansida saqlanadi va bilim yoki progress dalili sifatida ishlatilmaydi. Doimiy tarix saqlash alohida maxfiylik va saqlash qoidalari tasdiqlanmaguncha yoqilmaydi.",
      unavailable: "Tariflar haqidagi ma’lumot hozir mavjud emas.",
      checkoutUnavailable: "Pullik tariflarni ulash hali ishga tushirilmagan.",
      features: {
        subjects: "O‘quv fanlari",
        competitive: "Competitive fanlar",
        practice: "Practice",
        tours: "Tours, reytinglar va sertifikatlar",
        errors: "Xatolar tahlili",
        recommendations: "Tavsiyalar va tarix",
        resources: "Kitoblar, videolar va materiallar",
        examPrep: "Exam Prep",
        ai: "iClub AI",
        aiFreeText: "AI’ga erkin savollar",
        support: "Yordam va yangi funksiyalar"
      },
      values: {
        freeSubjects: "1",
        plusSubjects: "3 tagacha",
        proSubjects: "Barcha mavjud",
        freeCompetitive: "1",
        paidCompetitive: "2",
        included: "Kiritilgan",
        activeSubjects: "Faol fanlarda",
        basic: "Asosiy",
        aiAnalysis: "AI tahlili",
        aiAnalysisPro: "AI tahlili + kengaytirilgan tarix",
        standard: "Standart",
        personalized: "Shaxsiylashtirilgan",
        personalizedPro: "Shaxsiylashtirilgan + chuqur tahlil",
        allSubjects: "Barcha mavjud fanlarda",
        examIntro: "Tanishish",
        examFull: "To‘liq",
        examPro: "To‘liq + ishga tushirilgan yangi modullar",
        aiFree: "3 tayyor javob / 5 soat",
        aiPlus: "Yuqori limit / 5 soat",
        aiPro: "Eng yuqori limit / 5 soat",
        no: "Yo‘q",
        yes: "Ha",
        normalSupport: "Standart",
        proSupport: "Ustuvor + QA’dan keyin erta kirish"
      }
    },
    en: {
      rowTitle: "Plan",
      rowSubFree: "Free · Core access",
      rowSubPlus: "Plus · Extended access",
      rowSubPro: "Pro · Maximum access",
      screenTitle: "iClub plan",
      screenSub: "Choose the level of access that fits your study routine.",
      perMonth: "UZS / month",
      current: "Current plan",
      choose: "Choose",
      coming: "Coming soon",
      best: "Best value",
      freeName: "Free",
      plusName: "Plus",
      proName: "Pro",
      freeLead: "For getting started with iClub and one main subject.",
      plusLead: "For regular study across several subjects.",
      proLead: "For learners who use iClub as their main study platform.",
      compareTitle: "Compare features",
      limitsTitle: "How iClub AI limits work",
      limitsBody: "All plans use the same 5-hour period. Free includes up to 3 prepared iClub AI answers per period. Plus and Pro provide more usage and support free-form questions; Pro is designed for heavier use. Complex requests may use access faster. There is no permanent counter: if a limit is reached, iClub shows the exact reset time. Service errors and requests blocked during exams do not use the limit.",
      termsTitle: "AI usage terms",
      termsBody: "iClub AI helps explain learning material, results, and already-established errors. It does not change academic progress, rankings, certificates, readiness, or assessment results. AI is unavailable during protected assessments. Academic answers are available only where iClub has approved verified sources.",
      privacyTitle: "Conversations and data",
      privacyBody: "In the current version, Global iClub AI conversation history exists only for the current interface session and is never used as evidence of knowledge or progress. Persistent chat history will not be enabled until separate retention and privacy rules are approved.",
      unavailable: "Plan information is unavailable right now.",
      checkoutUnavailable: "Paid plan checkout has not launched yet.",
      features: {
        subjects: "Study subjects",
        competitive: "Competitive subjects",
        practice: "Practice",
        tours: "Tours, rankings and certificates",
        errors: "Error review",
        recommendations: "Recommendations and history",
        resources: "Books, videos and materials",
        examPrep: "Exam Prep",
        ai: "iClub AI",
        aiFreeText: "Free-form AI questions",
        support: "Support and new features"
      },
      values: {
        freeSubjects: "1",
        plusSubjects: "Up to 3",
        proSubjects: "All available",
        freeCompetitive: "1",
        paidCompetitive: "2",
        included: "Included",
        activeSubjects: "For active subjects",
        basic: "Basic",
        aiAnalysis: "AI review",
        aiAnalysisPro: "AI review + extended history",
        standard: "Standard",
        personalized: "Personalized",
        personalizedPro: "Personalized + deeper analysis",
        allSubjects: "For all available subjects",
        examIntro: "Preview",
        examFull: "Full",
        examPro: "Full + new modules after release",
        aiFree: "3 prepared answers / 5h",
        aiPlus: "Higher limit / 5h",
        aiPro: "Highest limit / 5h",
        no: "No",
        yes: "Yes",
        normalSupport: "Standard",
        proSupport: "Priority + early access after QA"
      }
    }
  };

  const state = {
    bootstrap: null,
    loading: false
  };

  function locale() {
    const lang = String(window.i18n?.getLang?.() || "ru").toLowerCase();
    return lang === "uz" || lang === "en" ? lang : "ru";
  }

  function copy() {
    return COPY[locale()] || COPY.ru;
  }

  function formatPrice(value) {
    const amount = Math.max(0, Number(value) || 0);
    if (amount === 0) return "0";
    try {
      return new Intl.NumberFormat(locale() === "uz" ? "uz-UZ" : locale() === "en" ? "en-US" : "ru-RU").format(amount);
    } catch {
      return String(amount);
    }
  }

  function entry() {
    return document.getElementById(ENTRY_ID);
  }

  function screen() {
    return document.getElementById(SCREEN_ID);
  }

  function showToast(text, duration = 2800) {
    const toast = document.getElementById("toast");
    if (!toast || !text) return;
    toast.textContent = text;
    toast.classList.add("is-show");
    setTimeout(() => toast.classList.remove("is-show"), duration);
  }

  function rowSubtitle(planCode) {
    const c = copy();
    if (planCode === "pro") return c.rowSubPro;
    if (planCode === "plus") return c.rowSubPlus;
    return c.rowSubFree;
  }

  function syncEntry() {
    const host = entry();
    if (!host) return;
    const visible = state.bootstrap?.visible === true;
    host.hidden = !visible;
    if (!visible) return;

    const title = host.querySelector("[data-plan-row-title]");
    const sub = host.querySelector("[data-plan-row-sub]");
    if (title) title.textContent = copy().rowTitle;
    if (sub) sub.textContent = rowSubtitle(String(state.bootstrap?.current_plan_code || "free"));
  }

  function planMeta(code) {
    const c = copy();
    if (code === "pro") return { name:c.proName, lead:c.proLead };
    if (code === "plus") return { name:c.plusName, lead:c.plusLead };
    return { name:c.freeName, lead:c.freeLead };
  }

  function renderPlanCards() {
    const host = screen()?.querySelector("[data-plan-cards]");
    if (!host) return;
    host.replaceChildren();

    const plans = Array.isArray(state.bootstrap?.plans) ? state.bootstrap.plans : [];
    const current = String(state.bootstrap?.current_plan_code || "free");
    const checkoutEnabled = state.bootstrap?.checkout_enabled === true;
    const c = copy();

    for (const plan of plans) {
      const code = String(plan?.plan_code || "");
      if (!["free","plus","pro"].includes(code)) continue;

      const meta = planMeta(code);
      const card = document.createElement("article");
      card.className = `iclub-plan-card is-${code}${code === current ? " is-current" : ""}`;

      const head = document.createElement("div");
      head.className = "iclub-plan-card-head";

      const nameWrap = document.createElement("div");
      const name = document.createElement("div");
      name.className = "iclub-plan-name";
      name.textContent = meta.name;
      nameWrap.appendChild(name);

      if (code === "pro") {
        const badge = document.createElement("div");
        badge.className = "iclub-plan-best";
        badge.textContent = c.best;
        nameWrap.appendChild(badge);
      }

      const price = document.createElement("div");
      price.className = "iclub-plan-price";
      if (code === "free") {
        price.textContent = "0";
      } else {
        price.innerHTML = `<strong>${formatPrice(plan.monthly_price_uzs)}</strong><span>${c.perMonth}</span>`;
      }

      head.append(nameWrap, price);

      const lead = document.createElement("p");
      lead.className = "iclub-plan-lead";
      lead.textContent = meta.lead;

      const button = document.createElement("button");
      button.type = "button";
      button.className = `btn ${code === "pro" ? "primary" : ""} iclub-plan-cta`;

      if (code === current) {
        button.textContent = c.current;
        button.disabled = true;
      } else if (code === "free") {
        button.textContent = c.choose;
        button.disabled = !checkoutEnabled;
      } else if (checkoutEnabled) {
        button.textContent = `${c.choose} ${meta.name}`;
      } else {
        button.textContent = c.coming;
        button.disabled = true;
      }

      button.addEventListener("click", () => {
        if (button.disabled) return;
        if (!checkoutEnabled) {
          showToast(c.checkoutUnavailable);
          return;
        }
        window.dispatchEvent(new CustomEvent("iclub:plan-checkout-request", {
          detail: { planCode: code }
        }));
      });

      card.append(head, lead, button);
      host.appendChild(card);
    }
  }

  function comparisonRows() {
    const c = copy();
    const f = c.features;
    const v = c.values;
    return [
      [f.subjects, v.freeSubjects, v.plusSubjects, v.proSubjects],
      [f.competitive, v.freeCompetitive, v.paidCompetitive, v.paidCompetitive],
      [f.practice, v.activeSubjects, v.activeSubjects, v.allSubjects],
      [f.tours, v.included, v.included, v.included],
      [f.errors, v.basic, v.aiAnalysis, v.aiAnalysisPro],
      [f.recommendations, v.standard, v.personalized, v.personalizedPro],
      [f.resources, v.activeSubjects, v.activeSubjects, v.allSubjects],
      [f.examPrep, v.examIntro, v.examFull, v.examPro],
      [f.ai, v.aiFree, v.aiPlus, v.aiPro],
      [f.aiFreeText, v.no, v.yes, v.yes],
      [f.support, v.normalSupport, v.normalSupport, v.proSupport]
    ];
  }

  function renderComparison() {
    const host = screen()?.querySelector("[data-plan-compare]");
    if (!host) return;
    const c = copy();
    host.replaceChildren();

    const title = document.createElement("h2");
    title.className = "iclub-plan-section-title";
    title.textContent = c.compareTitle;
    host.appendChild(title);

    const table = document.createElement("div");
    table.className = "iclub-plan-compare";

    const header = document.createElement("div");
    header.className = "iclub-plan-compare-row is-head";
    ["", c.freeName, c.plusName, c.proName].forEach((text) => {
      const cell = document.createElement("div");
      cell.textContent = text;
      header.appendChild(cell);
    });
    table.appendChild(header);

    for (const row of comparisonRows()) {
      const line = document.createElement("div");
      line.className = "iclub-plan-compare-row";
      row.forEach((text, index) => {
        const cell = document.createElement("div");
        cell.className = index === 0 ? "iclub-plan-feature" : "iclub-plan-value";
        cell.textContent = text;
        line.appendChild(cell);
      });
      table.appendChild(line);
    }

    host.appendChild(table);
  }

  function renderInfo() {
    const host = screen()?.querySelector("[data-plan-info]");
    if (!host) return;
    const c = copy();
    host.replaceChildren();

    const items = [
      [c.limitsTitle, c.limitsBody],
      [c.termsTitle, c.termsBody],
      [c.privacyTitle, c.privacyBody]
    ];

    for (const [title, body] of items) {
      const details = document.createElement("details");
      details.className = "iclub-plan-details";
      const summary = document.createElement("summary");
      summary.textContent = title;
      const text = document.createElement("p");
      text.textContent = body;
      details.append(summary, text);
      host.appendChild(details);
    }
  }

  function render() {
    const host = screen();
    if (!host) return;

    const c = copy();
    const title = host.querySelector("[data-plan-title]");
    const sub = host.querySelector("[data-plan-subtitle]");
    const unavailable = host.querySelector("[data-plan-unavailable]");
    const body = host.querySelector("[data-plan-body]");

    if (title) title.textContent = c.screenTitle;
    if (sub) sub.textContent = c.screenSub;

    const visible = state.bootstrap?.visible === true;
    if (unavailable) {
      unavailable.hidden = visible;
      unavailable.textContent = c.unavailable;
    }
    if (body) body.hidden = !visible;

    if (!visible) return;
    renderPlanCards();
    renderComparison();
    renderInfo();
  }

  async function refresh() {
    if (state.loading) return state.bootstrap;
    const client = window.sb;
    if (!client?.rpc) {
      state.bootstrap = null;
      syncEntry();
      return null;
    }

    state.loading = true;
    try {
      const { data, error } = await client.rpc("get_iclub_plan_ui_bootstrap_v1");
      state.bootstrap = (!error && data && typeof data === "object") ? data : null;
      syncEntry();
      render();
      return state.bootstrap;
    } catch {
      state.bootstrap = null;
      syncEntry();
      render();
      return null;
    } finally {
      state.loading = false;
    }
  }

  function attach() {
    document.addEventListener("iclub:plans-render", () => render());
    window.addEventListener("focus", () => { void refresh(); });

    try {
      window.sb?.auth?.onAuthStateChange?.(() => {
        queueMicrotask(() => { void refresh(); });
      });
    } catch {}

    setTimeout(() => { void refresh(); }, 0);
  }

  window.iClubPlansUI = Object.freeze({
    version: "iclub_plans_v1",
    refresh,
    render,
    bootstrap: () => state.bootstrap ? structuredClone(state.bootstrap) : null
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", attach, { once:true });
  } else {
    attach();
  }
})();
