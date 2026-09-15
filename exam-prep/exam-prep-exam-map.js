(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p209map2";
  let observer = null;
  let queued = false;
  let busy = false;
  let hydrating = false;
  let pendingNotice = null;

  function rootEl() { return document.querySelector("#exam-prep-host-root"); }
  function language() {
    try {
      const value = String(window.i18n?.getLang?.() || document.documentElement.lang || "ru").toLowerCase();
      return ["ru", "uz", "en"].includes(value) ? value : "ru";
    } catch (_) { return "ru"; }
  }

  function copy() {
    if (language() === "uz") return {
      title: "Imtihon rejasi",
      body: "Imtihon sessiyasi, maqsad baho va mavjud o‘qish vaqtini yangilashingiz mumkin. Oldingi progress, xatolar ustidagi ish va qayta tekshiruvlar saqlanadi.",
      edit: "Rejani o‘zgartirish",
      series: "Imtihon sessiyasi",
      target: "Maqsad baho",
      total: "Haftalik umumiy o‘qish vaqti (soat)",
      math: "Matematika uchun vaqt (soat)",
      save: "Saqlash va rejani yangilash",
      cancel: "Bekor qilish",
      choose: "Tanlang",
      mathShort: "Matematika",
      totalShort: "Jami",
      hours: "soat/hafta",
      invalid: "Barcha maydonlarni tekshiring. Matematika vaqti 0 dan katta bo‘lishi va umumiy vaqtdan oshmasligi kerak.",
      error: "Ma’lumotni saqlab bo‘lmadi. Qayta urinib ko‘ring.",
      seriesChanged: "Imtihon sessiyasi yangilandi. Oldingi natijalar tarixda saqlanadi. Yangi sessiyaga tayyorgarlik yangi to‘liq ishlar asosida baholanadi; P1 va P5 alohida hisoblanadi.",
      planChanged: "Reja yangilandi. Oldingi progress, tuzatishlar va qayta tekshiruvlar saqlandi.",
      unchanged: "O‘zgarish yo‘q. Joriy reja saqlandi."
    };
    if (language() === "en") return {
      title: "Exam plan",
      body: "You can update your exam series, target grade and available study time. Previous progress, correction work and scheduled checks are kept.",
      edit: "Change exam plan",
      series: "Exam series",
      target: "Target grade",
      total: "Total weekly study time (hours)",
      math: "Mathematics time (hours)",
      save: "Save and update plan",
      cancel: "Cancel",
      choose: "Select",
      mathShort: "Mathematics",
      totalShort: "Total",
      hours: "h/week",
      invalid: "Check all fields. Mathematics time must be above 0 and cannot exceed total study time.",
      error: "The information could not be saved. Try again.",
      seriesChanged: "Your exam series has been updated. Previous results remain in your history. Readiness for the new series will be based on new full papers; P1 and P5 remain separate.",
      planChanged: "Your plan has been updated. Previous progress, corrections and scheduled checks are kept.",
      unchanged: "Nothing changed. Your current plan has been kept."
    };
    return {
      title: "План экзамена",
      body: "Можно изменить экзаменационную сессию, целевую оценку и доступное учебное время. Прежний прогресс, работа над ошибками и повторные проверки сохраняются.",
      edit: "Изменить план",
      series: "Экзаменационная сессия",
      target: "Целевая оценка",
      total: "Общее учебное время в неделю (часы)",
      math: "Время на математику (часы)",
      save: "Сохранить и обновить план",
      cancel: "Отмена",
      choose: "Выберите",
      mathShort: "Математика",
      totalShort: "Всего",
      hours: "ч/нед.",
      invalid: "Проверьте все поля. Время на математику должно быть больше 0 и не превышать общее учебное время.",
      error: "Не удалось сохранить данные. Попробуйте ещё раз.",
      seriesChanged: "Экзаменационная сессия обновлена. Прежние результаты останутся в истории. Готовность к новой сессии будет оцениваться по новым полным работам; P1 и P5 по-прежнему учитываются отдельно.",
      planChanged: "План обновлён. Прежний прогресс, исправления и повторные проверки сохранены.",
      unchanged: "Изменений нет. Текущий план сохранён."
    };
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;").replaceAll("'", "&#039;");
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

  function selectMarkup(name, choices, currentValue) {
    const c = copy();
    const current = String(currentValue || "").trim();
    const known = choices.some(item => item.value === current);
    const rows = [];
    if (!current) rows.push(`<option value="" selected disabled>${esc(c.choose)}</option>`);
    if (current && !known) rows.push(`<option value="${esc(current)}" selected>${esc(current)}</option>`);
    rows.push(...choices.map(item => `<option value="${esc(item.value)}"${item.value === current ? " selected" : ""}>${esc(item.label)}</option>`));
    return `<select name="${esc(name)}" required aria-required="true">${rows.join("")}</select>`;
  }

  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }

  function profileComplete(profile) {
    return Boolean(
      profile && String(profile.exam_series || "").trim() && String(profile.target_grade || "").trim() &&
      Number(profile.total_student_hours_available) > 0 && Number(profile.mathematics_hours_budget) > 0 &&
      Number(profile.mathematics_hours_budget) <= Number(profile.total_student_hours_available)
    );
  }

  function isDashboard(root) {
    return Boolean(root?.querySelector('[data-ep-live-plan="P1"], [data-ep-live-start="P1"]')) &&
      Boolean(root?.querySelector('[data-ep-live-plan="P5"], [data-ep-live-start="P5"]'));
  }

  function currentHeader(root) {
    return root?.querySelector(".ep-host-shell.ep-live > .ep-live-head")?.outerHTML || "";
  }

  function localBackControl(root) {
    if (!root || root.hidden) return null;
    return root.querySelector([
      "[data-ep-exam-plan-cancel]",
      "[data-ep-materials-back]",
      "[data-ep-placement-back]",
      "[data-ep-views-back]",
      "[data-ep-recovery-back]",
      "[data-ep-live-dashboard]",
      "[data-ep-live-exit]",
      "[data-ep-live-end]"
    ].join(","));
  }

  function installContextualBack() {
    const app = window.iClubExamPrep;
    if (!app || typeof app.back !== "function" || app.examPrepContextualBackVersion === VERSION) return;
    const originalBack = app.back.bind(app);
    window.iClubExamPrep = Object.freeze({
      ...app,
      back: () => {
        const root = rootEl();
        const local = app.isOpen?.() ? localBackControl(root) : null;
        if (local) {
          local.click();
          return true;
        }
        return originalBack();
      },
      examPrepContextualBackVersion: VERSION
    });
  }

  async function hydrate() {
    queued = false;
    const root = rootEl();
    if (!root || root.hidden || busy || hydrating || !canUse() || !isDashboard(root)) return;
    if (root.querySelector("[data-ep-exam-plan-edit]")) return;
    if (typeof internal.api?.examProfile !== "function") return;

    hydrating = true;
    try {
      let result;
      try { result = await internal.api.examProfile(); } catch (_) { return; }
      const profile = result?.ok ? result.data : null;
      const liveRoot = rootEl();
      if (liveRoot !== root || !profileComplete(profile) || !isDashboard(root)) return;
      if (root.querySelector("[data-ep-exam-plan-edit]")) return;

      const profileSummary = root.querySelector(".ep-live-dashboard-profile");
      if (!profileSummary) return;
      const c = copy();
      const button = document.createElement("button");
      button.className = "ep-live-btn secondary ep-exam-plan-edit";
      button.type = "button";
      button.dataset.epExamPlanEdit = "true";
      button.textContent = c.edit;
      button.addEventListener("click", () => renderEditor(profile));
      profileSummary.appendChild(button);

      if (pendingNotice) {
        const shell = root.querySelector(".ep-host-shell.ep-live") || root.firstElementChild || root;
        const intro = shell.querySelector(".ep-live-dashboard-intro");
        const notice = document.createElement("div");
        notice.className = "ep-live-notice";
        notice.dataset.epExamPlanNotice = "true";
        notice.setAttribute("role", "status");
        notice.setAttribute("aria-live", "polite");
        notice.textContent = pendingNotice;
        if (intro) shell.insertBefore(notice, intro);
        else shell.prepend(notice);
        pendingNotice = null;
      }
    } finally {
      hydrating = false;
    }
  }

  function renderEditor(profile) {
    const root = rootEl();
    if (!root || busy || !profileComplete(profile)) return;
    const c = copy();
    const header = currentHeader(root);
    root.innerHTML = `<section class="ep-host-shell ep-live" data-ep-exam-plan-editor>${header}<div class="ep-live-card">
      <strong>${esc(c.title)}</strong><div class="ep-live-meta">${esc(c.body)}</div>
      <form class="ep-live-form" data-ep-exam-plan-form>
        <label class="ep-live-field"><span>${esc(c.series)}</span>${selectMarkup("exam_series", seriesChoices(), profile.exam_series)}</label>
        <label class="ep-live-field"><span>${esc(c.target)}</span>${selectMarkup("target_grade", targetChoices(), String(profile.target_grade || "").toUpperCase())}</label>
        <label class="ep-live-field"><span>${esc(c.total)}</span><input name="total_hours" type="number" min="0.5" max="168" step="0.5" value="${esc(profile.total_student_hours_available)}" required aria-required="true"></label>
        <label class="ep-live-field"><span>${esc(c.math)}</span><input name="math_hours" type="number" min="0.5" max="168" step="0.5" value="${esc(profile.mathematics_hours_budget)}" required aria-required="true"></label>
        <div class="ep-live-actions"><button class="ep-live-btn" type="submit">${esc(c.save)}</button><button class="ep-live-btn secondary" type="button" data-ep-exam-plan-cancel>${esc(c.cancel)}</button></div>
      </form><div data-ep-exam-plan-error role="alert" aria-live="assertive"></div>
    </div></section>`;
    root.querySelector("[data-ep-exam-plan-form]")?.addEventListener("submit", save);
    root.querySelector("[data-ep-exam-plan-cancel]")?.addEventListener("click", reopenOverview);
  }

  async function save(event) {
    event.preventDefault();
    if (busy) return;
    const form = event.currentTarget;
    const examSeries = String(form.elements.exam_series.value || "").trim();
    const targetGrade = String(form.elements.target_grade.value || "").trim().toUpperCase();
    const totalHours = Number(form.elements.total_hours.value);
    const mathHours = Number(form.elements.math_hours.value);
    const error = rootEl()?.querySelector("[data-ep-exam-plan-error]");
    if (!examSeries || !targetGrade || !(totalHours > 0) || !(mathHours > 0) || mathHours > totalHours || totalHours > 168) {
      if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().invalid)}</div>`;
      return;
    }

    busy = true;
    try {
      const result = await internal.api.saveExamProfile({ examSeries, targetGrade, totalHours, mathHours });
      if (!result?.ok) {
        if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().error)}</div>`;
        return;
      }
      const data = result.data || {};
      pendingNotice = data.series_changed === true
        ? copy().seriesChanged
        : (data.target_changed === true || data.hours_changed === true ? copy().planChanged : copy().unchanged);
      await reopenOverview();
    } catch (_) {
      if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().error)}</div>`;
    } finally {
      busy = false;
      queueHydrate();
    }
  }

  async function reopenOverview() {
    try {
      if (typeof window.iClubExamPrep?.refreshCapabilities === "function") {
        await window.iClubExamPrep.refreshCapabilities();
      } else if (typeof window.iClubExamPrep?.open === "function") {
        await window.iClubExamPrep.open({ subjectKey: "mathematics", language: language() });
      }
    } catch (_) {
      // The existing host remains authoritative if a refresh fails.
    }
    queueHydrate();
  }

  function queueHydrate() {
    if (queued) return;
    queued = true;
    queueMicrotask(hydrate);
  }

  function attach() {
    const root = rootEl();
    if (!root) { setTimeout(attach, 50); return; }
    installContextualBack();
    if (observer) observer.disconnect();
    observer = new MutationObserver(queueHydrate);
    observer.observe(root, { childList: true, subtree: true, attributes: true, attributeFilter: ["hidden", "aria-hidden"] });
    queueHydrate();
    internal.examMapUiVersion = VERSION;
  }

  attach();
})();
