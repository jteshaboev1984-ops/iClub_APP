(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p207recovery1";
  let observer = null;
  let queued = false;
  let busy = false;
  let hydrationToken = 0;

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
      title: "O‘qish jadvali o‘zgardimi?",
      body: "Agar darslarni o‘tkazib yuborgan bo‘lsangiz, davrni kiriting. Reja avvalgi natijalarni o‘chirmasdan va talablarni pasaytirmasdan moslashadi.",
      adjust: "Rejani moslashtirish",
      active: "Reja tanaffusdan keyin moslashtirilgan",
      days: "kun",
      formTitle: "Tanaffus davri",
      from: "Qaysi kundan",
      resumed: "Qachon o‘qishga qaytdingiz",
      reason: "Sabab",
      absence: "Darslarni o‘tkazib yuborish",
      holiday: "Ta’til yoki safar",
      other: "Boshqa",
      save: "Saqlash va rejani yangilash",
      back: "Orqaga",
      invalid: "Sanalarni tekshiring: qaytish sanasi boshlanish sanasidan keyin va bugundan kech bo‘lmasligi kerak.",
      error: "Rejani yangilab bo‘lmadi. Qayta urinib ko‘ring.",
      done: "Reja moslashtirildi",
      reserve: "Qisqa tanaffus uchun zaxira vaqtdan foydalanamiz. Muhim qayta tekshiruvlar saqlanadi.",
      twoThree: "Keyingi 14 kunlik reja: 50% majburiy o‘tilmagan mavzular, 25% shu mavzular bo‘yicha masalalar, 15% oldingi mavzular, 10% vaqtli mashq. Qayta tekshiruvlar saqlanadi.",
      review: "Bu tanaffus davomiyligi uchun avtomatik nisbat belgilanmagan. Reja ehtiyotkorlik bilan qayta ko‘rib chiqiladi; bosqich va talablar avtomatik o‘zgarmaydi.",
      long: "P1 va P5 alohida qayta rejalashtiriladi: qolgan majburiy mavzular, asosiy bilimlar va tanlangan imtihon sessiyasining real bajarilishi tekshiriladi. Haddan tashqari yuklama bilan quvib yetish rejalashtirilmaydi.",
      preserved: "Oldingi natijalaringiz saqlanadi.",
      returnOverview: "Umumiy ko‘rinishga qaytish"
    };
    if (language() === "en") return {
      title: "Has your study schedule changed?",
      body: "If you missed study time, add the dates. Your plan will adapt without deleting previous progress or lowering the evidence requirements.",
      adjust: "Adjust my plan",
      active: "Plan adjusted after a study break",
      days: "days",
      formTitle: "Study break period",
      from: "From",
      resumed: "Returned to study",
      reason: "Reason",
      absence: "Missed study time",
      holiday: "Holiday or travel",
      other: "Other",
      save: "Save and update plan",
      back: "Back",
      invalid: "Check the dates: the return date must be after the start date and cannot be in the future.",
      error: "The plan could not be updated. Try again.",
      done: "Plan adjusted",
      reserve: "For a short break, the plan uses reserve time and keeps important delayed checks in place.",
      twoThree: "For the next 14 days: 50% required uncovered topics, 25% questions on those topics, 15% older topics, and 10% timed practice. Delayed checks stay in the plan.",
      review: "No automatic study ratio is defined for this break length. The plan will be reviewed conservatively; your phase and evidence requirements will not change automatically.",
      long: "P1 and P5 are replanned separately: remaining required topics, foundations and the realism of the selected exam series are checked. Catch-up through unsafe overload is not used.",
      preserved: "Your previous results are kept.",
      returnOverview: "Return to overview"
    };
    return {
      title: "Изменился учебный график?",
      body: "Если вы пропустили занятия, укажите период. План адаптируется без удаления прежнего прогресса и без снижения требований к подтверждению знаний.",
      adjust: "Скорректировать план",
      active: "План адаптирован после перерыва",
      days: "дн.",
      formTitle: "Период перерыва",
      from: "С какого дня",
      resumed: "Когда вернулись к занятиям",
      reason: "Причина",
      absence: "Пропуск занятий",
      holiday: "Каникулы или поездка",
      other: "Другое",
      save: "Сохранить и обновить план",
      back: "Назад",
      invalid: "Проверьте даты: дата возвращения должна быть позже даты начала и не может быть в будущем.",
      error: "Не удалось обновить план. Попробуйте ещё раз.",
      done: "План адаптирован",
      reserve: "Для короткого перерыва используем резерв времени. Важные повторные проверки сохраняются.",
      twoThree: "На следующие 14 дней: 50% — обязательные непройденные темы, 25% — задачи по ним, 15% — более ранние темы, 10% — практика на время. Повторные проверки сохраняются.",
      review: "Для такой длительности перерыва автоматическое соотношение работы не задано. План будет пересмотрен осторожно; этап и требования не изменяются автоматически.",
      long: "P1 и P5 перепланируются отдельно: проверяются оставшиеся обязательные темы, базовые знания и реалистичность выбранной экзаменационной сессии. Догонять программу за счёт небезопасной перегрузки не будем.",
      preserved: "Все прежние результаты сохраняются.",
      returnOverview: "Вернуться к обзору"
    };
  }

  function esc(value) {
    return String(value == null ? "" : value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }

  function isDashboard(root) {
    return Boolean(root?.querySelector('[data-ep-live-plan="P1"], [data-ep-live-start="P1"]')) &&
      Boolean(root?.querySelector('[data-ep-live-plan="P5"], [data-ep-live-start="P5"]'));
  }

  function modeMessage(mode) {
    const c = copy();
    if (mode === "reserve_1w") return c.reserve;
    if (mode === "recovery_2_3w") return c.twoThree;
    if (mode === "rebaseline_over_1mo") return c.long;
    return c.review;
  }

  function todayIso() {
    const d = new Date();
    const local = new Date(d.getTime() - d.getTimezoneOffset() * 60000);
    return local.toISOString().slice(0, 10);
  }

  async function hydrateDashboard() {
    queued = false;
    const root = rootEl();
    if (!root || root.hidden || busy || !canUse() || !isDashboard(root)) return;
    if (root.querySelector("[data-ep-recovery-card]")) return;
    if (typeof internal.api?.recovery !== "function") return;

    const token = ++hydrationToken;
    let p1 = null;
    let p5 = null;
    try {
      const results = await Promise.all([internal.api.recovery("P1"), internal.api.recovery("P5")]);
      if (token !== hydrationToken || !isDashboard(rootEl())) return;
      p1 = results[0]?.ok ? results[0].data : null;
      p5 = results[1]?.ok ? results[1].data : null;
    } catch (_) {
      return;
    }

    const c = copy();
    const activeRows = [p1, p5].filter(row => row?.active === true);
    const active = activeRows.length > 0;
    const days = active ? Math.max(...activeRows.map(row => Number(row?.missed_days || 0))) : 0;
    const status = active
      ? `<div class="ep-live-notice"><strong>${esc(c.active)}${days ? ` · ${days} ${esc(c.days)}` : ""}</strong><div class="ep-live-meta">${esc(modeMessage(activeRows[0]?.recovery_mode))}</div></div>`
      : "";

    const card = document.createElement("div");
    card.className = "ep-live-card";
    card.dataset.epRecoveryCard = "true";
    card.innerHTML = `<strong>${esc(c.title)}</strong><div class="ep-live-meta">${esc(c.body)}</div>${status}<div class="ep-live-actions"><button class="ep-live-btn secondary" type="button" data-ep-recovery-open>${esc(c.adjust)}</button></div>`;
    const shell = root.querySelector(".ep-host-shell.ep-live") || root.firstElementChild || root;
    shell.appendChild(card);
    card.querySelector("[data-ep-recovery-open]")?.addEventListener("click", renderForm);
  }

  function renderForm() {
    const root = rootEl();
    if (!root || busy) return;
    const c = copy();
    const today = todayIso();
    root.innerHTML = `<section class="ep-host-shell ep-live" data-ep-recovery-form-view>
      <div class="ep-live-card">
        <div class="ep-live-head"><strong>${esc(c.formTitle)}</strong><button class="ep-live-btn secondary" type="button" data-ep-recovery-back>${esc(c.back)}</button></div>
        <div class="ep-live-meta">${esc(c.body)}</div>
        <form class="ep-live-form" data-ep-recovery-form>
          <label class="ep-live-field"><span>${esc(c.from)}</span><input type="date" name="started_on" max="${esc(today)}" required></label>
          <label class="ep-live-field"><span>${esc(c.resumed)}</span><input type="date" name="resumed_on" max="${esc(today)}" value="${esc(today)}" required></label>
          <label class="ep-live-field"><span>${esc(c.reason)}</span><select name="kind" required><option value="absence">${esc(c.absence)}</option><option value="planned_holiday">${esc(c.holiday)}</option><option value="other">${esc(c.other)}</option></select></label>
          <div class="ep-live-actions"><button class="ep-live-btn" type="submit">${esc(c.save)}</button></div>
        </form>
        <div data-ep-recovery-error></div>
      </div>
    </section>`;
    root.querySelector("[data-ep-recovery-back]")?.addEventListener("click", reopenOverview);
    root.querySelector("[data-ep-recovery-form]")?.addEventListener("submit", submit);
  }

  async function submit(event) {
    event.preventDefault();
    if (busy) return;
    const form = event.currentTarget;
    const startedOn = String(form.elements.started_on.value || "").trim();
    const resumedOn = String(form.elements.resumed_on.value || "").trim();
    const kind = String(form.elements.kind.value || "absence");
    const error = rootEl()?.querySelector("[data-ep-recovery-error]");
    const startMs = Date.parse(`${startedOn}T00:00:00`);
    const resumeMs = Date.parse(`${resumedOn}T00:00:00`);
    const todayMs = Date.parse(`${todayIso()}T23:59:59`);
    if (!startedOn || !resumedOn || !Number.isFinite(startMs) || !Number.isFinite(resumeMs) || resumeMs <= startMs || resumeMs > todayMs) {
      if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().invalid)}</div>`;
      return;
    }

    busy = true;
    try {
      const result = await internal.api.recordInterruption({ startedOn, resumedOn, kind });
      if (!result?.ok || !result.data) {
        if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().error)}</div>`;
        return;
      }

      // Regenerate each component independently when Stage 0 already permits a weekly plan.
      // Failure for one component never upgrades or blocks the other component.
      await Promise.allSettled([
        internal.api.generateWeeklyPlan("P1"),
        internal.api.generateWeeklyPlan("P5")
      ]);
      renderSuccess(result.data);
    } catch (_) {
      if (error) error.innerHTML = `<div class="ep-live-error">${esc(copy().error)}</div>`;
    } finally {
      busy = false;
    }
  }

  function renderSuccess(data) {
    const root = rootEl();
    if (!root) return;
    const c = copy();
    root.innerHTML = `<section class="ep-host-shell ep-live" data-ep-recovery-success>
      <div class="ep-live-card">
        <strong>${esc(c.done)}</strong>
        <div class="ep-live-notice">${esc(modeMessage(String(data?.recovery_mode || "")))}</div>
        <div class="ep-live-meta">${esc(c.preserved)}</div>
        <div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-recovery-return>${esc(c.returnOverview)}</button></div>
      </div>
    </section>`;
    root.querySelector("[data-ep-recovery-return]")?.addEventListener("click", reopenOverview);
  }

  async function reopenOverview() {
    hydrationToken += 1;
    try {
      if (typeof window.iClubExamPrep?.open === "function") {
        await window.iClubExamPrep.open({ language: language() });
      } else if (typeof window.iClubExamPrep?.refreshCapabilities === "function") {
        await window.iClubExamPrep.refreshCapabilities();
      }
    } catch (_) {
      // Core host owns its normal error/fallback behavior.
    }
  }

  function queueHydrate() {
    if (queued) return;
    queued = true;
    queueMicrotask(hydrateDashboard);
  }

  function attach() {
    const root = rootEl();
    if (!root) { setTimeout(attach, 50); return; }
    if (observer) observer.disconnect();
    observer = new MutationObserver(queueHydrate);
    observer.observe(root, { childList: true, subtree: true, attributes: true, attributeFilter: ["hidden", "aria-hidden"] });
    queueHydrate();
    internal.recoveryFlowVersion = VERSION;
  }

  attach();
})();
