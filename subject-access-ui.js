(() => {
  "use strict";

  const ENTRY_ID = "profile-subject-access-entry";
  const SCREEN_ID = "profile-subject-access";

  const COPY = {
    ru: {
      entryTitle: "Предметы тарифа",
      entryFree: "1 учебный · 1 Competitive",
      entryPlus: "До 3 учебных · до 2 Competitive",
      entryPro: "Все предметы · до 2 Competitive",
      title: "Предметы тарифа",
      subtitle: "Настрой предметы, которые входят в твой тариф.",
      betaTitle: "Тестовый режим",
      betaText: "Этот выбор пока не меняет твой текущий доступ и прогресс. Мы проверяем будущую настройку тарифов.",
      plan: "Тариф",
      studyTitle: "Учебные предметы",
      studyFree: "Выбери 1 предмет.",
      studyPlus: "Выбери до 3 предметов.",
      studyPro: "В Pro доступны все активные предметы.",
      competitiveTitle: "Competitive",
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
      entryTitle: "Tarif fanlari",
      entryFree: "1 o‘quv · 1 Competitive",
      entryPlus: "3 tagacha o‘quv · 2 tagacha Competitive",
      entryPro: "Barcha fanlar · 2 tagacha Competitive",
      title: "Tarif fanlari",
      subtitle: "Tarifingizga kiradigan fanlarni sozlang.",
      betaTitle: "Sinov rejimi",
      betaText: "Bu tanlov hozircha joriy kirish yoki progressni o‘zgartirmaydi. Biz kelajakdagi tarif sozlamasini tekshiryapmiz.",
      plan: "Tarif",
      studyTitle: "O‘quv fanlari",
      studyFree: "1 ta fan tanlang.",
      studyPlus: "3 tagacha fan tanlang.",
      studyPro: "Pro’da barcha faol fanlar mavjud.",
      competitiveTitle: "Competitive",
      competitiveText: "Tours, reyting va sertifikatlar uchun fanlarni tanlang.",
      selected: "Tanlandi",
      included: "Kiritilgan",
      firstStudy: "Avval fanni o‘quv fanlariga qo‘shing.",
      studyLimit: "Tarifingizdagi o‘quv fanlari limiti tugadi.",
      competitiveLimit: "Tarifingizdagi Competitive limiti tugadi.",
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
      entryFree: "1 study · 1 Competitive",
      entryPlus: "Up to 3 study · up to 2 Competitive",
      entryPro: "All subjects · up to 2 Competitive",
      title: "Plan subjects",
      subtitle: "Choose the subjects included in your plan.",
      betaTitle: "Test mode",
      betaText: "This selection does not change your current access or progress yet. We are testing the future plan setup.",
      plan: "Plan",
      studyTitle: "Study subjects",
      studyFree: "Choose 1 subject.",
      studyPlus: "Choose up to 3 subjects.",
      studyPro: "Pro includes every active subject.",
      competitiveTitle: "Competitive",
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
    busy: new Set()
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
      const next = input.checked;
      input.disabled = true;
      try {
        await args.onChange(next);
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
      const busy = state.busy.has(key);

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
        disabled: busy || limitReached,
        helper: limitReached ? c.studyLimit : "",
        onChange: async (next) => {
          await writeSelection(key, next, next ? current.competitive : false);
        }
      }));
    }

    host.appendChild(list);
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
      const busy = state.busy.has(key);
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
          await writeSelection(key, true, next);
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
    if (betaText) betaText.textContent = c.betaText;

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
      renderCompetitive(competitive);
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