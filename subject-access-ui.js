(() => {
  "use strict";

  const ENTRY_ID = "profile-subject-access-entry";
  const SCREEN_ID = "profile-subject-access";

  const COPY = {
    ru: {
      entryTitle: "Предметы тарифа",
      entryFree: "1 предмет для учёбы и соревнований",
      entryPlus: "До 3 учебных · до 2 Competitive",
      entryPro: "Все предметы · до 2 Competitive",
      title: "Предметы тарифа",
      subtitle: "Настрой предметы, которые входят в твой тариф.",
      betaTitle: "Тестовый режим",
      betaText: "Этот выбор пока не меняет твой текущий доступ и прогресс. Мы проверяем будущую настройку тарифов.",
      betaTextEnforced: "Тестовый доступ включён: выбранные предметы определяют доступ в этом beta-аккаунте. Прогресс и история не удаляются.",
      plan: "Тариф",
      studyTitle: "Учебные предметы",
      studyFree: "Выбери один предмет. Для школьников он автоматически участвует в соревнованиях и рейтинге.",
      studyPlus: "Выбери до 3 предметов.",
      studyPro: "В Pro доступны все активные предметы.",
      competitiveTitle: "Соревнования и рейтинг",
      freeCompetitiveAuto: "Выбранный предмет автоматически участвует в соревнованиях и рейтинге. Повторно выбирать его не нужно.",
      freeCompetitiveUnavailable: "Участие в соревнованиях определяется данными школьного профиля.",
      competitiveText: "Выбери предметы для туров, рейтингов и сертификатов.",
      selected: "Выбрано",
      included: "Включено",
      firstStudy: "Сначала добавь предмет в учебные.",
      studyLimit: "Лимит учебных предметов для твоего тарифа достигнут.",
      competitiveLimit: "Лимит Competitive для твоего тарифа достигнут.",
      saveFailed: "Не удалось сохранить выбор. Попробуй ещё раз.",
      unavailable: "Настройка предметов сейчас недоступна.",
      subjectNames: {
        mathematics: "Математика",
        biology: "Биология",
        chemistry: "Химия",
        economics: "Экономика",
        informatics: "Информатика",
        english_a1: "English A1",
        english_a2: "English A2",
        english_b1: "English B1",
        sat: "SAT",
        ielts: "IELTS"
      }
    },
    uz: {
      entryTitle: "Tarifdagi fanlar",
      entryFree: "O‘qish va musobaqalar uchun bitta fan",
      entryPlus: "O‘qish uchun 3 tagacha, musobaqa uchun 2 tagacha fan",
      entryPro: "Barcha fanlar · musobaqa uchun 2 tagacha",
      title: "Tarifdagi fanlar",
      subtitle: "Tarifingiz bo‘yicha foydalanadigan fanlarni tanlang.",
      betaTitle: "Sinov rejimi",
      betaText: "Bu tanlov hozircha mavjud imkoniyatlar va o‘qish natijalariga ta’sir qilmaydi. Yangi tariflarni sinab ko‘ryapmiz.",
      betaTextEnforced: "Sinov rejimida faqat tanlangan fanlar ochiladi. Oldingi natijalaringiz saqlanadi.",
      plan: "Tarif",
      studyTitle: "O‘qish uchun fanlar",
      studyFree: "Bitta fan tanlang. Maktab o‘quvchilari uchun shu fan musobaqalarga ham avtomatik qo‘shiladi.",
      studyPlus: "3 tagacha fan tanlang.",
      studyPro: "Pro tarifida barcha mavjud fanlardan foydalanishingiz mumkin.",
      competitiveTitle: "Musobaqa va reyting",
      freeCompetitiveAuto: "Tanlagan faningiz musobaqalar va reyting uchun ham belgilandi. Uni qayta tanlash shart emas.",
      freeCompetitiveUnavailable: "Musobaqalarda qatnashish maktab o‘quvchisi sifatida ro‘yxatdan o‘tganingizga bog‘liq.",
      competitiveText: "Musobaqa, reyting va sertifikatlar uchun fanlarni tanlang.",
      selected: "Tanlandi",
      included: "Kiritilgan",
      firstStudy: "Avval fanni o‘quv fanlariga qo‘shing.",
      studyLimit: "Tarifingizdagi o‘quv fanlari limiti tugadi.",
      competitiveLimit: "Musobaqalar uchun tanlash mumkin bo‘lgan fanlar soniga yetdingiz.",
      saveFailed: "Tanlovni saqlab bo‘lmadi. Qayta urinib ko‘ring.",
      unavailable: "Fanlarni sozlash hozir mavjud emas.",
      subjectNames: {
        mathematics: "Matematika",
        biology: "Biologiya",
        chemistry: "Kimyo",
        economics: "Iqtisodiyot",
        informatics: "Informatika",
        english_a1: "English A1",
        english_a2: "English A2",
        english_b1: "English B1",
        sat: "SAT",
        ielts: "IELTS"
      }
    },
    en: {
      entryTitle: "Plan subjects",
      entryFree: "One subject for study and competitions",
      entryPlus: "Up to 3 study · up to 2 Competitive",
      entryPro: "All subjects · up to 2 Competitive",
      title: "Plan subjects",
      subtitle: "Choose the subjects included in your plan.",
      betaTitle: "Test mode",
      betaText: "This selection does not change your current access or progress yet. We are testing the future plan setup.",
      betaTextEnforced: "Test access is on: selected subjects control access for this beta account. Progress and history are not deleted.",
      plan: "Plan",
      studyTitle: "Study subjects",
      studyFree: "Choose one subject. Eligible school learners enter competitions in that subject automatically.",
      studyPlus: "Choose up to 3 subjects.",
      studyPro: "Pro includes every active subject.",
      competitiveTitle: "Competitions and rankings",
      freeCompetitiveAuto: "Your selected subject is also used for competitions and rankings. No second selection is needed.",
      freeCompetitiveUnavailable: "Competition access follows your school profile eligibility.",
      competitiveText: "Choose subjects for Tours, rankings, and certificates.",
      selected: "Selected",
      included: "Included",
      firstStudy: "Add this as a study subject first.",
      studyLimit: "Your plan's study-subject limit has been reached.",
      competitiveLimit: "Your plan's Competitive limit has been reached.",
      saveFailed: "Could not save the selection. Try again.",
      unavailable: "Subject setup is unavailable right now.",
      subjectNames: {
        mathematics: "Mathematics",
        biology: "Biology",
        chemistry: "Chemistry",
        economics: "Economics",
        informatics: "Informatics",
        english_a1: "English A1",
        english_a2: "English A2",
        english_b1: "English B1",
        sat: "SAT",
        ielts: "IELTS"
      }
    }
  };

  const state = {
    bootstrap: null,
    loading: false,
    busy: new Set(),
    accessPreviewEnforced: false
  };

  function locale() {
    const lang = String(window.i18n?.getLang?.() || "ru").toLowerCase();
    return lang === "uz" || lang === "en" ? lang : "ru";
  }

  function copy() {
    return COPY[locale()] || COPY.ru;
  }

  function screen() {
    return document.getElementById(SCREEN_ID);
  }

  function entry() {
    return document.getElementById(ENTRY_ID);
  }

  function showToast(text, duration = 2600) {
    const toast = document.getElementById("toast");
    if (!toast || !text) return;
    toast.textContent = text;
    toast.classList.add("is-show");
    setTimeout(() => toast.classList.remove("is-show"), duration);
  }

  function planCode() {
    const code = String(state.bootstrap?.plan_code || "free").toLowerCase();
    return ["free","plus","pro"].includes(code) ? code : "free";
  }

  function planLabel() {
    const code = planCode();
    return code === "pro" ? "Pro" : code === "plus" ? "Plus" : "Free";
  }

  function subjectTitle(key) {
    return copy().subjectNames?.[key] || key;
  }

  function selectionMap() {
    const map = new Map();
    for (const row of Array.isArray(state.bootstrap?.selections) ? state.bootstrap.selections : []) {
      const key = String(row?.subject_key || "").trim();
      if (!key) continue;
      map.set(key, {
        study: row?.study_selected === true,
        competitive: row?.competitive_selected === true
      });
    }
    return map;
  }

  function entrySubtitle() {
    const c = copy();
    const code = planCode();
    return code === "pro" ? c.entryPro : code === "plus" ? c.entryPlus : c.entryFree;
  }

  function syncEntry() {
    const host = entry();
    if (!host) return;
    const visible = state.bootstrap?.visible === true;
    host.hidden = !visible;
    if (!visible) return;

    const title = host.querySelector("[data-subject-access-entry-title]");
    const sub = host.querySelector("[data-subject-access-entry-sub]");
    if (title) title.textContent = copy().entryTitle;
    if (sub) sub.textContent = entrySubtitle();
  }

  function countText(current, limit, all) {
    if (all) return copy().included;
    return String(current) + " / " + String(limit);
  }

  function makeSwitch(args) {
    const wrap = document.createElement("label");
    wrap.className = "iclub-subject-access-switch";
    const input = document.createElement("input");
    input.type = "checkbox";
    input.checked = args.checked;
    input.disabled = args.disabled;
    input.setAttribute("aria-label", args.label);
    const slider = document.createElement("span");
    slider.className = "iclub-subject-access-slider";
    input.addEventListener("change", async () => {
      const previous = !input.checked;
      const next = input.checked;
      input.disabled = true;
      try {
        const saved = await args.onChange(next);
        if (saved !== true) input.checked = previous;
      } catch {
        input.checked = previous;
      } finally {
        input.disabled = false;
      }
    });
    wrap.append(input, slider);
    return wrap;
  }

  function makeSubjectRow(args) {
    const row = document.createElement("div");
    row.className = "iclub-subject-access-row" +
      (args.selected ? " is-selected" : "") +
      (args.disabled ? " is-disabled" : "");
    row.dataset.subjectKey = String(args.subject?.subject_key || "");
    row.dataset.selectionMode = String(args.mode || "");

    const main = document.createElement("div");
    main.className = "iclub-subject-access-row-main";

    const title = document.createElement("div");
    title.className = "iclub-subject-access-row-title";
    title.textContent = subjectTitle(args.subject.subject_key);

    const sub = document.createElement("div");
    sub.className = "iclub-subject-access-row-sub";
    sub.textContent = args.helper || (args.selected ? copy().selected : "");

    main.append(title, sub);

    if (args.mode === "included") {
      const badge = document.createElement("span");
      badge.className = "iclub-subject-access-included";
      badge.textContent = copy().included;
      row.append(main, badge);
    } else {
      row.append(main, makeSwitch({
        checked: args.mode === "competitive" ? args.competitive : args.selected,
        disabled: args.disabled,
        label: subjectTitle(args.subject.subject_key),
        onChange: args.onChange
      }));
    }

    return row;
  }

  async function writeSelection(subjectKey, studySelected, competitiveSelected) {
    if (!window.sb?.rpc || state.busy.has(subjectKey)) return false;
    state.busy.add(subjectKey);
    render();

    try {
      const result = await window.sb.rpc("set_iclub_my_subject_slot_v1", {
        p_subject_key: subjectKey,
        p_study_selected: studySelected,
        p_competitive_selected: competitiveSelected
      });
      const data = result?.data;
      const error = result?.error;

      if (error || !data || data.ok !== true) {
        const reason = String(data?.reason || "");
        if (reason === "study_subject_limit_reached") showToast(copy().studyLimit);
        else if (reason === "competitive_subject_limit_reached") showToast(copy().competitiveLimit);
        else showToast(copy().saveFailed);
        return false;
      }

      window.dispatchEvent(new CustomEvent("iclub:subject-selection-changed", {
        detail: { subjectKey }
      }));
      await refresh();
      return true;
    } catch {
      showToast(copy().saveFailed);
      return false;
    } finally {
      state.busy.delete(subjectKey);
      render();
    }
  }

  async function chooseFreeSubject(subjectKey) {
    if (!window.sb?.rpc || state.busy.size > 0) return false;
    state.busy.add(subjectKey);
    render();
    try {
      const { data, error } = await window.sb.rpc("choose_iclub_my_free_subject_v2", {
        p_subject_key: subjectKey
      });
      if (error || data?.ok !== true) {
        showToast(copy().saveFailed);
        return false;
      }
      window.dispatchEvent(new CustomEvent("iclub:subject-selection-changed", {
        detail: { subjectKey }
      }));
      await refresh();
      return true;
    } catch {
      showToast(copy().saveFailed);
      return false;
    } finally {
      state.busy.delete(subjectKey);
      render();
    }
  }

  function renderStudy(host) {
    const c = copy();
    const code = planCode();
    const all = state.bootstrap?.all_available_subjects === true;
    const limit = Number(state.bootstrap?.study_subject_limit || 0);
    const selectedCount = Number(state.bootstrap?.study_selected_count || 0);
    const selections = selectionMap();
    const subjects = Array.isArray(state.bootstrap?.subjects) ? state.bootstrap.subjects : [];

    const head = document.createElement("div");
    head.className = "iclub-subject-access-section-head";

    const text = document.createElement("div");
    const title = document.createElement("div");
    title.className = "iclub-subject-access-section-title";
    title.textContent = c.studyTitle;
    const desc = document.createElement("div");
    desc.className = "iclub-subject-access-section-copy";
    desc.textContent = code === "pro" ? c.studyPro : code === "plus" ? c.studyPlus : c.studyFree;
    text.append(title, desc);

    const count = document.createElement("span");
    count.className = "iclub-subject-access-count";
    count.textContent = countText(selectedCount, limit, all);

    head.append(text, count);
    host.appendChild(head);

    const list = document.createElement("div");
    list.className = "iclub-subject-access-list";

    for (const subject of subjects) {
      const key = String(subject?.subject_key || "");
      const current = selections.get(key) || { study:false, competitive:false };
      const busy = state.busy.size > 0;

      if (all) {
        list.appendChild(makeSubjectRow({
          subject: subject,
          selected: true,
          competitive: current.competitive,
          mode: "included",
          disabled: true,
          helper: ""
        }));
        continue;
      }

      const limitReached = selectedCount >= limit && !current.study;
      list.appendChild(makeSubjectRow({
        subject: subject,
        selected: current.study,
        competitive: current.competitive,
        mode: "study",
        disabled: busy || (code === "free" ? current.study : limitReached),
        helper: code === "free" ? "" : limitReached ? c.studyLimit : "",
        onChange: async (next) => {
          if (code === "free") return next ? await chooseFreeSubject(key) : false;
          return await writeSelection(key, next, next ? current.competitive : false);
        }
      }));
    }

    host.appendChild(list);
  }

  function renderFreeCompetitive(host) {
    const note = document.createElement("p");
    note.className = "iclub-subject-access-section-copy";
    note.textContent = state.bootstrap?.is_school_student === true
      ? copy().freeCompetitiveAuto : copy().freeCompetitiveUnavailable;
    host.appendChild(note);
  }

  function renderCompetitive(host) {
    const c = copy();
    const all = state.bootstrap?.all_available_subjects === true;
    const limit = Number(state.bootstrap?.competitive_subject_limit || 0);
    const selectedCount = Number(state.bootstrap?.competitive_selected_count || 0);
    const selections = selectionMap();
    const subjects = (Array.isArray(state.bootstrap?.subjects) ? state.bootstrap.subjects : [])
      .filter((subject) => String(subject?.type || "") === "main");

    const head = document.createElement("div");
    head.className = "iclub-subject-access-section-head";

    const text = document.createElement("div");
    const title = document.createElement("div");
    title.className = "iclub-subject-access-section-title";
    title.textContent = c.competitiveTitle;
    const desc = document.createElement("div");
    desc.className = "iclub-subject-access-section-copy";
    desc.textContent = c.competitiveText;
    text.append(title, desc);

    const count = document.createElement("span");
    count.className = "iclub-subject-access-count";
    count.textContent = String(selectedCount) + " / " + String(limit);

    head.append(text, count);
    host.appendChild(head);

    const list = document.createElement("div");
    list.className = "iclub-subject-access-list";

    for (const subject of subjects) {
      const key = String(subject?.subject_key || "");
      const current = selections.get(key) || { study:false, competitive:false };
      const busy = state.busy.size > 0;
      const studyAvailable = all || current.study;
      const limitReached = selectedCount >= limit && !current.competitive;
      const disabled = busy || !studyAvailable || limitReached;
      const helper = !studyAvailable ? c.firstStudy : limitReached ? c.competitiveLimit : "";

      list.appendChild(makeSubjectRow({
        subject: subject,
        selected: current.study || all,
        competitive: current.competitive,
        mode: "competitive",
        disabled: disabled,
        helper: helper,
        onChange: async (next) => {
          return await writeSelection(key, true, next);
        }
      }));
    }

    host.appendChild(list);
  }

  function render() {
    syncEntry();
    const host = screen();
    if (!host) return;

    const c = copy();
    const title = host.querySelector("[data-subject-access-title]");
    const subtitle = host.querySelector("[data-subject-access-subtitle]");
    const betaTitle = host.querySelector("[data-subject-access-beta-title]");
    const betaText = host.querySelector("[data-subject-access-beta-text]");
    const plan = host.querySelector("[data-subject-access-plan]");
    const unavailable = host.querySelector("[data-subject-access-unavailable]");
    const body = host.querySelector("[data-subject-access-body]");
    const study = host.querySelector("[data-subject-access-study]");
    const competitive = host.querySelector("[data-subject-access-competitive]");

    if (title) title.textContent = c.title;
    if (subtitle) subtitle.textContent = c.subtitle;
    if (betaTitle) betaTitle.textContent = c.betaTitle;
    if (betaText) betaText.textContent = state.accessPreviewEnforced ? c.betaTextEnforced : c.betaText;

    const visible = state.bootstrap?.visible === true;
    if (unavailable) {
      unavailable.hidden = visible;
      unavailable.textContent = c.unavailable;
    }
    if (body) body.hidden = !visible;
    if (!visible) return;

    if (plan) plan.textContent = c.plan + ": " + planLabel();
    if (study) {
      study.replaceChildren();
      renderStudy(study);
    }
    if (competitive) {
      competitive.replaceChildren();
      if (planCode() === "free") renderFreeCompetitive(competitive);
      else renderCompetitive(competitive);
    }
  }

  async function refresh() {
    if (state.loading) return state.bootstrap;
    if (!window.sb?.rpc) {
      state.bootstrap = null;
      render();
      return null;
    }

    state.loading = true;
    try {
      const result = await window.sb.rpc("get_iclub_subject_selection_bootstrap_v1");
      const data = result?.data;
      const error = result?.error;
      state.bootstrap = (!error && data && typeof data === "object") ? data : null;
      state.accessPreviewEnforced = false;

      if (state.bootstrap?.visible === true) {
        const firstSubject = Array.isArray(state.bootstrap?.subjects)
          ? String(state.bootstrap.subjects[0]?.subject_key || "").trim()
          : "";

        if (firstSubject && window.iClubCommercialAccessUI?.checkStudy) {
          try {
            const access = await window.iClubCommercialAccessUI.checkStudy(firstSubject,{ fresh:true });
            state.accessPreviewEnforced = access?.enforced === true;
          } catch {}
        }
      }

      render();
      return state.bootstrap;
    } catch {
      state.bootstrap = null;
      render();
      return null;
    } finally {
      state.loading = false;
    }
  }

  function attach() {
    window.addEventListener("focus", () => { void refresh(); });
    window.addEventListener("iclub:commercial-access-ready", () => { void refresh(); });
    try {
      window.sb?.auth?.onAuthStateChange?.(() => {
        queueMicrotask(() => { void refresh(); });
      });
    } catch {}
    setTimeout(() => { void refresh(); }, 0);
  }

  window.iClubSubjectAccessUI = Object.freeze({
    version: "subject_selection_shadow_v1",
    refresh: refresh,
    render: render,
    bootstrap: () => state.bootstrap ? structuredClone(state.bootstrap) : null
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", attach, { once:true });
  } else {
    attach();
  }
})();