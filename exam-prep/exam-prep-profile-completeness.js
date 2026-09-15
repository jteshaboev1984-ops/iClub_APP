(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p205profile3";
  let observer = null;
  let queued = false;
  let loading = false;

  function rootEl() {
    return document.querySelector("#exam-prep-host-root");
  }

  function language() {
    try {
      const value = String(window.i18n?.getLang?.() || document.documentElement.lang || "ru").toLowerCase();
      return ["ru", "uz", "en"].includes(value) ? value : "ru";
    } catch (_) {
      return "ru";
    }
  }

  function copy() {
    if (language() === "uz") return {
      title: "Imtihon rejasini to‘ldiring",
      body: "Javoblaringiz va progressingiz saqlangan. Faqat yetishmayotgan imtihon ma’lumotlarini to‘ldiring. Mavjud natijalar o‘zgarmaydi.",
      series: "Imtihon sessiyasi",
      target: "Maqsad baho",
      total: "Haftalik umumiy o‘qish vaqti (soat)",
      math: "Matematika uchun vaqt (soat)",
      save: "Saqlash va davom etish",
      choose: "Tanlang",
      invalid: "Barcha maydonlarni tekshiring. Matematika vaqti 0 dan katta bo‘lishi va umumiy vaqtdan oshmasligi kerak.",
      error: "Ma’lumotni saqlab bo‘lmadi. Qayta urinib ko‘ring."
    };
    if (language() === "en") return {
      title: "Complete your exam plan",
      body: "Your answers and progress are saved. Complete only the missing exam details. Your existing results will not change.",
      series: "Exam series",
      target: "Target grade",
      total: "Total weekly study time (hours)",
      math: "Mathematics time (hours)",
      save: "Save and continue",
      choose: "Select",
      invalid: "Check all fields. Mathematics time must be above 0 and cannot exceed total study time.",
      error: "The information could not be saved. Try again."
    };
    return {
      title: "Дополните план экзамена",
      body: "Ваши ответы и прогресс сохранены. Дополните только недостающие данные об экзамене. Уже полученные результаты не изменятся.",
      series: "Экзаменационная сессия",
      target: "Целевая оценка",
      total: "Общее учебное время в неделю (часы)",
      math: "Время на математику (часы)",
      save: "Сохранить и продолжить",
      choose: "Выберите",
      invalid: "Проверьте все поля. Время на математику должно быть больше 0 и не превышать общее учебное время.",
      error: "Не удалось сохранить данные. Попробуйте ещё раз."
    };
  }

  function seriesChoices() {
    return [
      { value: "November 2026", label: "Oct/Nov 2026" },
      { value: "June 2027", label: "May/June 2027" },
      { value: "November 2027", label: "Oct/Nov 2027" },
      { value: "June 2028", label: "May/June 2028" },
      { value: "November 2028", label: "Oct/Nov 2028" }
    ];
  }

  function targetChoices() {
    return ["A", "B", "C", "D", "E"].map(value => ({ value, label: value }));
  }

  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }

  function complete(profile) {
    return Boolean(
      profile &&
      String(profile.exam_series || "").trim() &&
      String(profile.target_grade || "").trim() &&
      Number(profile.total_student_hours_available) > 0 &&
      Number(profile.mathematics_hours_budget) > 0 &&
      Number(profile.mathematics_hours_budget) <= Number(profile.total_student_hours_available)
    );
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function selectMarkup(name, choices, currentValue) {
    const current = String(currentValue || "").trim();
    const known = choices.some(item => item.value === current);
    const rows = [];
    if (!current) rows.push(`<option value="" selected disabled>${esc(copy().choose)}</option>`);
    if (current && !known) rows.push(`<option value="${esc(current)}" selected>${esc(current)}</option>`);
    rows.push(...choices.map(item => `<option value="${esc(item.value)}"${item.value === current ? " selected" : ""}>${esc(item.label)}</option>`));
    return `<select name="${esc(name)}" required aria-required="true">${rows.join("")}</select>`;
  }

  function replaceWithSelect(form, name, choices) {
    const control = form.elements?.[name];
    if (!control) return;
    if (control.tagName === "SELECT") {
      control.required = true;
      control.setAttribute("aria-required", "true");
      return;
    }
    const holder = document.createElement("div");
    holder.innerHTML = selectMarkup(name, choices, control.value);
    const select = holder.firstElementChild;
    if (!select) return;
    control.replaceWith(select);
  }

  function requireNativeFields() {
    const form = rootEl()?.querySelector("[data-ep-live-profile-form]");
    if (!form) return false;
    replaceWithSelect(form, "exam_series", seriesChoices());
    replaceWithSelect(form, "target_grade", targetChoices());
    return true;
  }

  function renderRepair(profile) {
    const root = rootEl();
    if (!root || root.querySelector("[data-ep-profile-completion]")) return;
    const c = copy();
    const total = Number(profile?.total_student_hours_available) > 0 ? Number(profile.total_student_hours_available) : "";
    const math = Number(profile?.mathematics_hours_budget) > 0 ? Number(profile.mathematics_hours_budget) : "";
    const shell = root.querySelector(".ep-host-shell.ep-live");
    const dashboard = root.querySelector(".ep-live-dashboard-intro");
    const grid = root.querySelector(".ep-live-grid");
    if (!shell || !dashboard || !grid) return;

    const panel = document.createElement("section");
    panel.className = "ep-live-card ep-profile-completion-card";
    panel.dataset.epProfileCompletion = "true";
    panel.innerHTML = `
      <strong>${esc(c.title)}</strong>
      <div class="ep-live-meta">${esc(c.body)}</div>
      <form class="ep-live-form" data-ep-profile-completion-form>
        <label class="ep-live-field"><span>${esc(c.series)}</span>${selectMarkup("exam_series", seriesChoices(), profile?.exam_series)}</label>
        <label class="ep-live-field"><span>${esc(c.target)}</span>${selectMarkup("target_grade", targetChoices(), String(profile?.target_grade || "").toUpperCase())}</label>
        <label class="ep-live-field"><span>${esc(c.total)}</span><input name="total_hours" type="number" min="0.5" max="168" step="0.5" value="${esc(total)}" required aria-required="true"></label>
        <label class="ep-live-field"><span>${esc(c.math)}</span><input name="math_hours" type="number" min="0.5" max="168" step="0.5" value="${esc(math)}" required aria-required="true"></label>
        <div class="ep-live-actions"><button class="ep-live-btn" type="submit">${esc(c.save)}</button></div>
      </form>
      <div data-ep-profile-completion-error role="alert" aria-live="assertive"></div>`;
    shell.insertBefore(panel, grid);
    panel.querySelector("[data-ep-profile-completion-form]")?.addEventListener("submit", event => save(event, profile));
  }

  async function save(event, previousProfile) {
    event.preventDefault();
    if (loading) return;
    const form = event.currentTarget;
    const examSeries = String(form.elements.exam_series.value || "").trim();
    const targetGrade = String(form.elements.target_grade.value || "").trim().toUpperCase();
    const totalHours = Number(form.elements.total_hours.value);
    const mathHours = Number(form.elements.math_hours.value);
    const error = rootEl()?.querySelector("[data-ep-profile-completion-error]");
    if (!examSeries || !targetGrade || !(totalHours > 0) || !(mathHours > 0) || mathHours > totalHours || totalHours > 168) {
      if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().invalid)}</div>`;
      return;
    }

    loading = true;
    try {
      const result = await internal.api.saveExamProfile({ examSeries, targetGrade, totalHours, mathHours });
      if (!result?.ok) {
        if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().error)}</div>`;
        return;
      }
      const refreshed = await internal.api.examProfile();
      if (!refreshed?.ok || !complete(refreshed.data)) {
        if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().error)}</div>`;
        return;
      }
      if (typeof window.iClubExamPrep?.refreshCapabilities === "function") {
        await window.iClubExamPrep.refreshCapabilities();
      } else if (typeof window.iClubExamPrep?.open === "function") {
        await window.iClubExamPrep.open({ language: language() });
      }
    } finally {
      loading = false;
    }
  }

  async function hydrate() {
    queued = false;
    const root = rootEl();
    if (!root || root.hidden || !canUse()) return;
    if (requireNativeFields()) return;
    if (root.querySelector("[data-ep-profile-completion]")) return;
    if (loading || typeof internal.api?.examProfile !== "function") return;

    loading = true;
    try {
      const result = await internal.api.examProfile();
      if (!result?.ok || !result.data) return;
      if (!complete(result.data)) renderRepair(result.data);
    } catch (_) {
      // Fail closed without changing learner state. The existing Exam Prep flow remains available.
    } finally {
      loading = false;
    }
  }

  function queueHydrate() {
    if (queued) return;
    queued = true;
    queueMicrotask(hydrate);
  }

  function attach() {
    const root = rootEl();
    if (!root) { setTimeout(attach, 50); return; }
    if (observer) observer.disconnect();
    observer = new MutationObserver(queueHydrate);
    observer.observe(root, { childList: true, subtree: true, attributes: true, attributeFilter: ["hidden", "aria-hidden"] });
    queueHydrate();
    internal.profileCompletenessVersion = VERSION;
  }

  function loadThresholdReferenceLayer() {
    try {
      const src = document?.currentScript?.src || "";
      if (!src || !/exam-prep-profile-completeness\.js(?:\?|$)/.test(src)) return;
      if (document.querySelector('script[data-exam-prep-threshold-reference]')) return;
      const script = document.createElement("script");
      script.dataset.examPrepThresholdReference = "true";
      script.src = src.replace(/exam-prep-profile-completeness\.js(?:\?.*)?$/, "exam-prep-threshold-reference.js?v=p205threshold1");
      document.head.appendChild(script);
    } catch (_) {
      // Read-only learner note is optional; the core flow must remain available without it.
    }
  }

  loadThresholdReferenceLayer();
  attach();
})();
