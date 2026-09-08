(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p205profile1";
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
      body: "Imtihon sessiyasi va maqsad bahoni kiriting. Bu ma’lumotlar keyinchalik tayyorgarlik holatini to‘g‘ri baholash uchun kerak. Oldingi natijalaringiz saqlanadi.",
      series: "Imtihon sessiyasi",
      target: "Maqsad baho",
      total: "Haftalik umumiy o‘qish vaqti (soat)",
      math: "Matematika uchun vaqt (soat)",
      save: "Saqlash va davom etish",
      invalid: "Barcha maydonlarni tekshiring. Matematika vaqti 0 dan katta bo‘lishi va umumiy vaqtdan oshmasligi kerak.",
      error: "Ma’lumotni saqlab bo‘lmadi. Qayta urinib ko‘ring."
    };
    if (language() === "en") return {
      title: "Complete your exam plan",
      body: "Add your exam series and target grade. They are needed later to assess readiness correctly. Your existing progress will be kept.",
      series: "Exam series",
      target: "Target grade",
      total: "Total weekly study time (hours)",
      math: "Mathematics time (hours)",
      save: "Save and continue",
      invalid: "Check all fields. Mathematics time must be above 0 and cannot exceed total study time.",
      error: "The information could not be saved. Try again."
    };
    return {
      title: "Дополните план экзамена",
      body: "Укажите экзаменационную сессию и целевую оценку. Эти данные понадобятся позже, чтобы корректно оценивать готовность. Уже накопленный прогресс сохранится.",
      series: "Экзаменационная сессия",
      target: "Целевая оценка",
      total: "Общее учебное время в неделю (часы)",
      math: "Время на математику (часы)",
      save: "Сохранить и продолжить",
      invalid: "Проверьте все поля. Время на математику должно быть больше 0 и не превышать общее учебное время.",
      error: "Не удалось сохранить данные. Попробуйте ещё раз."
    };
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

  function requireNativeFields() {
    const form = rootEl()?.querySelector("[data-ep-live-profile-form]");
    if (!form) return false;
    ["exam_series", "target_grade"].forEach(name => {
      const input = form.elements?.[name];
      if (!input) return;
      input.required = true;
      input.setAttribute("aria-required", "true");
    });
    return true;
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function renderRepair(profile) {
    const root = rootEl();
    if (!root || root.querySelector("[data-ep-profile-completion]")) return;
    const c = copy();
    const total = Number(profile?.total_student_hours_available) > 0 ? Number(profile.total_student_hours_available) : "";
    const math = Number(profile?.mathematics_hours_budget) > 0 ? Number(profile.mathematics_hours_budget) : "";
    root.innerHTML = `<section class="ep-host-shell ep-live" data-ep-profile-completion>
      <div class="ep-live-card">
        <strong>${esc(c.title)}</strong>
        <div class="ep-live-meta">${esc(c.body)}</div>
        <form class="ep-live-form" data-ep-profile-completion-form>
          <label class="ep-live-field"><span>${esc(c.series)}</span><input name="exam_series" maxlength="80" value="${esc(profile?.exam_series || "")}" placeholder="May/June 2027" required aria-required="true"></label>
          <label class="ep-live-field"><span>${esc(c.target)}</span><input name="target_grade" maxlength="40" value="${esc(profile?.target_grade || "")}" placeholder="A" required aria-required="true"></label>
          <label class="ep-live-field"><span>${esc(c.total)}</span><input name="total_hours" type="number" min="0.5" max="168" step="0.5" value="${esc(total)}" required></label>
          <label class="ep-live-field"><span>${esc(c.math)}</span><input name="math_hours" type="number" min="0.5" max="168" step="0.5" value="${esc(math)}" required></label>
          <div class="ep-live-actions"><button class="ep-live-btn" type="submit">${esc(c.save)}</button></div>
        </form>
        <div data-ep-profile-completion-error></div>
      </div>
    </section>`;
    root.querySelector("[data-ep-profile-completion-form]")?.addEventListener("submit", event => save(event, profile));
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

  attach();
})();
