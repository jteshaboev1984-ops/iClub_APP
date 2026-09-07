(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p019timed1";
  let attached = false;

  const state = {
    language: "ru",
    busy: false,
    profile: null,
    progress: { P1: null, P5: null },
    componentState: { P1: null, P5: null },
    session: null,
    returnView: null,
    itemStartedAt: 0,
    notice: null,
    timerId: null
  };

  function lang(value) {
    const v = String(value || "ru").toLowerCase();
    return ["ru", "uz", "en"].includes(v) ? v : "ru";
  }

  function copy() {
    if (state.language === "uz") return {
      title: "Cambridge AS Mathematics · Exam Prep", kicker: "Imtihonga tayyorgarlik", safe: "Modulga kirish shaxsiy ruxsat bilan himoyalangan.",
      profileTitle: "Avval imtihon rejangizni kiriting", profileText: "Bu ma’lumotlar matematika uchun real haftalik yuklamani tuzishga yordam beradi.",
      series: "Imtihon seriyasi", target: "Maqsad baho", total: "Haftalik umumiy o‘qish vaqti (soat)", math: "Matematika uchun vaqt (soat)",
      save: "Saqlash va kirish tekshiruvini boshlash", saving: "Saqlanmoqda…", invalid: "Soatlarni tekshiring: matematika vaqti 0 dan katta va umumiy vaqtdan oshmasligi kerak.",
      items: "savol", areas: "bo‘lim", start: "Keyingi tekshiruv qismini boshlash", resume: "Tekshiruvni davom ettirish", complete: "Kirish tekshiruvi yakunlandi", loading: "Yuklanmoqda…",
      question: "Savol", submit: "Javobni yuborish", correct: "To‘g‘ri", incorrect: "Xatoni ko‘rib chiqing", finish: "Tekshiruv qismi yakunlandi. Natija yangilandi.",
      error: "Amalni bajarib bo‘lmadi. Qayta urinib ko‘ring.", back: "Orqaga", overview: "Umumiy ko‘rinish", plan: "Haftalik reja", openPlan: "Haftalik rejani ochish", priority: "Ustuvorlik", week: "Hafta",
      learning: "Mavzuni o‘rganish", correction: "Xato ustida ishlash", retest: "Qayta tekshirish", mixed: "Aralash mashq", rebaseline: "Rejani yangilash", startTask: "Boshlash", notDue: "Qayta tekshirish vaqti hali kelmagan", noPlan: "Faol reja yo‘q.", written: "Yechimingizni yozing", completedTask: "Topshiriq tugadi. Reja yangilandi.",
      stageTitle: "Joriy bosqich", coverage: "Tasdiqlangan qamrov", timed: "Vaqtli mashqlar", openTimed: "Vaqtli mashqlarni ochish", noTimed: "Hozircha bu bosqich uchun vaqtli mashq yo‘q.", marks: "ball", minutes: "daq.", startTimed: "Boshlash", timeLeft: "Qolgan vaqt", endAttempt: "Urinishni yakunlash", endConfirm: "Urinishni hozir yakunlaysizmi? Yakunlanmagan qism natijada hisobga olinadi.",
      timedDone: "Urinish yakunlandi", selfReviewTitle: "Ishingizni tekshiring", selfReviewText: "Mezonlar bo‘yicha o‘zingizga ball bering. Bu baho faqat urinishingiz yakunlangandan keyin saqlanadi.", yourAnswer: "Sizning yechimingiz", rubric: "Baholash mezonlari", selfTip: "Tekshirish uchun eslatma", award: "Ball", saveMark: "Ballni saqlash", result: "Natija", inTime: "Vaqt ichidagi ball", afterTime: "Vaqtdan keyingi ball", unattempted: "Bajarilmagan ball", comparable: "Taqqoslash uchun yaroqli", yes: "Ha", no: "Yo‘q", backTimed: "Vaqtli mashqlarga qaytish",
      readiness: "Imtihon tayyorgarligi", openReadiness: "Tayyorgarlik holatini ko‘rish", readyStrong: "Obyektiv ko‘rsatkichlar tayyor", readyMore: "Yana dalil kerak", readinessPapers: "Hisobga olingan to‘liq ishlar", readinessSkills: "Barqarorlashtirilishi kerak bo‘lgan ko‘nikmalar", readinessCorrections: "Ochiq tuzatishlar", calibration: "Yakuniy moslashuv", openCalibration: "Yakuniy moslashuvni ochish", calibrationUnavailable: "Yakuniy moslashuv tayyorgarlik mezonlari bajarilgandan keyin ochiladi.",
      stage0: "Kirish tekshiruvi", stage1: "Asoslarni mustahkamlash", stage2: "Dastur bo‘yicha o‘rganish", stage3: "Dastur qamrovini yopish", stage4: "Vaqt ostida mustahkamlash", stage5: "Imtihon tayyorgarligi", stage6: "Yakuniy moslashuv",
      thresholdPending: "Tanlangan imtihon seriyasi va maqsad baho uchun tayyorgarlik mezoni hali sozlanmagan.", threePapers: "Tayyorgarlik uchun uchta taqqoslanadigan to‘liq ish kerak.", stage4Incomplete: "Vaqt ostidagi mustahkamlash hali yakunlanmagan.", skillsIncomplete: "Ba’zi ko‘nikmalarda barqaror natija hali yetarli emas.", correctionsOpen: "Ba’zi xatolar bo‘yicha tuzatish sikli hali yopilmagan.", belowThreshold: "Oxirgi uchta to‘liq ishning hammasi maqsad darajasiga yetmagan.", unattemptedHigh: "Bajarilmay qolayotgan ballar hali ko‘p.", afterTimeHigh: "Natijaning bir qismi hali vaqt tugagandan keyingi ishga tayanmoqda.",
      actionCloseIssue: "Qolgan asosiy xatoni yoping", actionShort: "Qisqa maqsadli mashq", actionTiming: "Vaqt va imtihon tartibini tekshirish", actionTaper: "Yuklamani kamaytirish va natijani saqlash"
    };
    if (state.language === "en") return {
      title: "Cambridge AS Mathematics · Exam Prep", kicker: "Exam preparation", safe: "Access to this module is protected by personal permission.",
      profileTitle: "Set your exam plan first", profileText: "This helps build a realistic weekly mathematics workload.",
      series: "Exam series", target: "Target grade", total: "Total weekly study time (hours)", math: "Mathematics time (hours)",
      save: "Save and start entry check", saving: "Saving…", invalid: "Check the hours: mathematics time must be above 0 and cannot exceed total time.",
      items: "questions", areas: "areas", start: "Start the next check section", resume: "Continue the check", complete: "Entry check complete", loading: "Loading…",
      question: "Question", submit: "Submit answer", correct: "Correct", incorrect: "Review this mistake", finish: "Check section complete. Progress updated.",
      error: "The action could not be completed. Try again.", back: "Back", overview: "Overview", plan: "Weekly plan", openPlan: "Open weekly plan", priority: "Priority", week: "Week",
      learning: "Study this topic", correction: "Work on this mistake", retest: "Check again", mixed: "Mixed practice", rebaseline: "Update plan", startTask: "Start", notDue: "This check is not due yet", noPlan: "No active plan yet.", written: "Write your solution", completedTask: "Task complete. Plan updated.",
      stageTitle: "Current phase", coverage: "Confirmed coverage", timed: "Timed practice", openTimed: "Open timed practice", noTimed: "No timed practice is available for this phase yet.", marks: "marks", minutes: "min", startTimed: "Start", timeLeft: "Time left", endAttempt: "End attempt", endConfirm: "End this attempt now? Unfinished work will be counted in the result.",
      timedDone: "Attempt complete", selfReviewTitle: "Review your work", selfReviewText: "Use the criteria to award your marks. Marks are recorded only after the attempt has ended.", yourAnswer: "Your solution", rubric: "Marking criteria", selfTip: "Review note", award: "Marks", saveMark: "Save marks", result: "Result", inTime: "Marks in time", afterTime: "Marks after time", unattempted: "Unattempted marks", comparable: "Comparable result", yes: "Yes", no: "No", backTimed: "Back to timed practice",
      readiness: "Exam readiness", openReadiness: "View readiness", readyStrong: "Objective evidence is ready", readyMore: "More evidence is needed", readinessPapers: "Comparable full papers counted", readinessSkills: "Skills still needing stability", readinessCorrections: "Open corrections", calibration: "Final calibration", openCalibration: "Open final calibration", calibrationUnavailable: "Final calibration opens after the readiness criteria are met.",
      stage0: "Entry check", stage1: "Foundation", stage2: "Syllabus learning", stage3: "Syllabus closure", stage4: "Timed consolidation", stage5: "Exam readiness", stage6: "Final calibration",
      thresholdPending: "The readiness threshold for the selected exam series and target grade is not configured yet.", threePapers: "Three comparable full papers are required for readiness.", stage4Incomplete: "Timed consolidation is not complete yet.", skillsIncomplete: "Some skills still need stable evidence.", correctionsOpen: "Some corrective work is still open.", belowThreshold: "The latest three full papers do not all meet the target level.", unattemptedHigh: "Too many marks are still being left unattempted.", afterTimeHigh: "Part of the result still depends on work completed after time.",
      actionCloseIssue: "Close the main remaining issue", actionShort: "Short targeted practice", actionTiming: "Check timing and exam logistics", actionTaper: "Reduce workload and protect performance"
    };
    return {
      title: "Cambridge AS Mathematics · Exam Prep", kicker: "Подготовка к экзамену", safe: "Доступ к модулю защищён персональным разрешением.",
      profileTitle: "Сначала задайте план экзамена", profileText: "Это поможет системе построить реалистичную недельную нагрузку по математике.",
      series: "Экзаменационная сессия", target: "Целевая оценка", total: "Общее учебное время в неделю (часы)", math: "Время на математику (часы)",
      save: "Сохранить и начать входную проверку", saving: "Сохраняем…", invalid: "Проверьте часы: время на математику должно быть больше 0 и не превышать общее время.",
      items: "вопросов", areas: "разделов", start: "Начать следующую часть проверки", resume: "Продолжить проверку", complete: "Входная проверка завершена", loading: "Загрузка…",
      question: "Вопрос", submit: "Отправить ответ", correct: "Верно", incorrect: "Разберите эту ошибку", finish: "Часть проверки завершена. Прогресс обновлён.",
      error: "Не удалось выполнить действие. Попробуйте ещё раз.", back: "Назад", overview: "Обзор", plan: "Недельный план", openPlan: "Открыть недельный план", priority: "Приоритет", week: "Неделя",
      learning: "Изучить тему", correction: "Разобрать ошибку", retest: "Проверить ещё раз", mixed: "Смешанная практика", rebaseline: "Обновить план", startTask: "Начать", notDue: "Повторная проверка ещё не наступила", noPlan: "Активного плана пока нет.", written: "Запишите своё решение", completedTask: "Задание завершено. План обновлён.",
      stageTitle: "Текущий этап", coverage: "Подтверждённое покрытие", timed: "Практика на время", openTimed: "Открыть практику на время", noTimed: "Для текущего этапа пока нет доступной практики на время.", marks: "баллов", minutes: "мин", startTimed: "Начать", timeLeft: "Осталось", endAttempt: "Завершить попытку", endConfirm: "Завершить попытку сейчас? Незавершённая часть будет учтена в результате.",
      timedDone: "Попытка завершена", selfReviewTitle: "Проверьте свою работу", selfReviewText: "Сверьтесь с критериями и выставьте себе баллы. Оценка сохраняется только после завершения попытки.", yourAnswer: "Ваше решение", rubric: "Критерии оценивания", selfTip: "Подсказка для проверки", award: "Баллы", saveMark: "Сохранить баллы", result: "Результат", inTime: "Баллы в пределах времени", afterTime: "Баллы после времени", unattempted: "Невыполненные баллы", comparable: "Результат сопоставим", yes: "Да", no: "Нет", backTimed: "Вернуться к практике на время",
      readiness: "Готовность к экзамену", openReadiness: "Посмотреть готовность", readyStrong: "Объективные показатели готовы", readyMore: "Нужно больше подтверждений", readinessPapers: "Учтено полных сопоставимых работ", readinessSkills: "Навыков требуют стабилизации", readinessCorrections: "Открытых исправлений", calibration: "Финальная калибровка", openCalibration: "Открыть финальную калибровку", calibrationUnavailable: "Финальная калибровка откроется после выполнения критериев готовности.",
      stage0: "Входная проверка", stage1: "Фундамент", stage2: "Изучение программы", stage3: "Закрытие программы", stage4: "Закрепление на время", stage5: "Готовность к экзамену", stage6: "Финальная калибровка",
      thresholdPending: "Критерий готовности для выбранной экзаменационной сессии и целевой оценки ещё не настроен.", threePapers: "Для готовности нужны три сопоставимые полные работы.", stage4Incomplete: "Этап работы на время ещё не завершён.", skillsIncomplete: "По части навыков ещё не хватает стабильных подтверждений.", correctionsOpen: "По части ошибок цикл исправления ещё не закрыт.", belowThreshold: "Не все три последние полные работы достигли целевого уровня.", unattemptedHigh: "Пока остаётся слишком много невыполненных баллов.", afterTimeHigh: "Часть результата всё ещё зависит от работы после окончания времени.",
      actionCloseIssue: "Закрыть основную оставшуюся ошибку", actionShort: "Короткая целевая практика", actionTiming: "Проверить время и экзаменационный порядок", actionTaper: "Снизить нагрузку и сохранить форму"
    };
  }

  function esc(value) {
    return String(value == null ? "" : value).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&#039;");
  }
  function key(prefix) { return `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`; }
  function rootEl() { return document.querySelector("#exam-prep-host-root"); }
  function canMount() {
    const caps = internal.lastCapabilities;
    return Boolean(caps && caps.coreAccess === true && caps.killSwitch === false && caps.rolloutState === "controlled_beta");
  }
  function clearTimer() { if (state.timerId) clearInterval(state.timerId); state.timerId = null; }
  function stageLabel(value) { const c = copy(); return c[`stage${Math.max(0, Math.min(6, Number(value) || 0))}`]; }
  function minutes(sec) { return Math.max(1, Math.ceil((Number(sec) || 0) / 60)); }
  function assessmentTitle(row) { return String(row?.[`title_${state.language}`] || row?.title_en || copy().timed); }
  function artifactText(value) {
    if (value == null) return "";
    if (typeof value === "string") return value;
    if (typeof value === "object" && typeof value.text === "string") return value.text;
    try { return JSON.stringify(value); } catch (_) { return String(value); }
  }

  function ensureStyle() {
    if (document.querySelector("#ep-live-flow-style")) return;
    const style = document.createElement("style");
    style.id = "ep-live-flow-style";
    style.textContent = `
      .ep-live{display:grid;gap:14px}.ep-live-head{display:flex;justify-content:space-between;gap:12px;align-items:flex-start}.ep-live-safe{font-size:12px;opacity:.72;max-width:280px;text-align:right}
      .ep-live-card{border:1px solid rgba(127,127,127,.24);border-radius:14px;padding:14px;display:grid;gap:10px;background:rgba(127,127,127,.04)}
      .ep-live-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}.ep-live-form{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}
      .ep-live-field{display:grid;gap:5px;font-size:13px}.ep-live-field input,.ep-live-input,.ep-live-textarea{width:100%;box-sizing:border-box;padding:10px 11px;border:1px solid rgba(127,127,127,.35);border-radius:10px;background:transparent;color:inherit}
      .ep-live-textarea{min-height:140px;resize:vertical}.ep-live-btn{border:0;border-radius:11px;padding:10px 14px;font-weight:700;cursor:pointer;background:#111827;color:#fff}.ep-live-btn:disabled{opacity:.55;cursor:default}.ep-live-btn.secondary{background:transparent;color:inherit;border:1px solid rgba(127,127,127,.35)}
      .ep-live-progress{height:7px;border-radius:999px;background:rgba(127,127,127,.18);overflow:hidden}.ep-live-progress>span{display:block;height:100%;background:currentColor;opacity:.7}
      .ep-live-meta{font-size:12px;opacity:.72}.ep-live-options{display:grid;gap:8px}.ep-live-option{display:flex;gap:9px;align-items:flex-start;padding:10px;border:1px solid rgba(127,127,127,.25);border-radius:10px}
      .ep-live-notice{padding:10px;border-radius:10px;background:rgba(127,127,127,.1);font-size:13px}.ep-live-error{padding:10px;border-radius:10px;background:rgba(180,30,30,.12);font-size:13px}.ep-live-qtext{white-space:pre-wrap;line-height:1.5}.ep-live-actions{display:flex;gap:8px;flex-wrap:wrap}
      .ep-live-plan-item,.ep-live-timed-row{display:grid;grid-template-columns:1fr auto;gap:10px;align-items:center;padding:11px;border:1px solid rgba(127,127,127,.2);border-radius:11px}.ep-live-priority{font-weight:800;font-size:18px}.ep-live-due{font-size:11px;opacity:.7}
      .ep-live-stat{display:grid;gap:3px;padding:10px;border:1px solid rgba(127,127,127,.18);border-radius:10px}.ep-live-stats{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:8px}.ep-live-stat strong{font-size:18px}.ep-live-rubric{display:grid;gap:7px}.ep-live-rubric-row{padding:8px;border-radius:9px;background:rgba(127,127,127,.07);font-size:13px}.ep-live-answer{white-space:pre-wrap;padding:10px;border-radius:9px;background:rgba(127,127,127,.07)}
      .ep-live-timer{font-variant-numeric:tabular-nums;font-weight:800}.ep-live-action-row{display:grid;gap:4px;padding:10px;border:1px solid rgba(127,127,127,.18);border-radius:10px}
      @media(max-width:680px){.ep-live-grid,.ep-live-form,.ep-live-stats{grid-template-columns:1fr}.ep-live-head{display:grid}.ep-live-safe{text-align:left;max-width:none}.ep-live-plan-item,.ep-live-timed-row{grid-template-columns:1fr}.ep-live-plan-item .ep-live-btn,.ep-live-timed-row .ep-live-btn{width:100%}}
    `;
    document.head.appendChild(style);
  }

  function shell(body) {
    const c = copy();
    return `<section class="ep-host-shell ep-live" aria-label="${esc(c.title)}"><div class="ep-live-head"><div><div class="ep-host-kicker">${esc(c.kicker)}</div><h2 class="ep-host-title">${esc(c.title)}</h2></div><div class="ep-live-safe">${esc(c.safe)}</div></div>${body}</section>`;
  }
  function renderLoading() { clearTimer(); const root = rootEl(); if (root) root.innerHTML = shell(`<div class="ep-live-card">${esc(copy().loading)}</div>`); }
  function renderError(message = null) { clearTimer(); const root = rootEl(); if (root) root.innerHTML = shell(`<div class="ep-live-error">${esc(message || copy().error)}</div><button class="ep-live-btn secondary" data-ep-live-home>${esc(copy().overview)}</button>`); root?.querySelector('[data-ep-live-home]')?.addEventListener('click', renderDashboard); }

  function renderProfile() {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy();
    root.innerHTML = shell(`<div class="ep-live-card"><strong>${esc(c.profileTitle)}</strong><div class="ep-live-meta">${esc(c.profileText)}</div><form class="ep-live-form" data-ep-live-profile-form>
      <label class="ep-live-field"><span>${esc(c.series)}</span><input name="exam_series" maxlength="80" placeholder="Oct/Nov 2026"></label>
      <label class="ep-live-field"><span>${esc(c.target)}</span><input name="target_grade" maxlength="40" placeholder="A"></label>
      <label class="ep-live-field"><span>${esc(c.total)}</span><input name="total_hours" type="number" min="0.5" max="168" step="0.5" required></label>
      <label class="ep-live-field"><span>${esc(c.math)}</span><input name="math_hours" type="number" min="0.5" max="168" step="0.5" required></label>
      <div class="ep-live-actions"><button class="ep-live-btn" type="submit" data-ep-live-save-profile>${esc(state.busy ? c.saving : c.save)}</button></div></form><div data-ep-live-profile-error></div></div>`);
    root.querySelector("[data-ep-live-profile-form]")?.addEventListener("submit", saveProfile);
  }

  async function saveProfile(event) {
    event.preventDefault(); if (state.busy) return;
    const form = event.currentTarget;
    const values = { examSeries: form.elements.exam_series.value, targetGrade: form.elements.target_grade.value, totalHours: Number(form.elements.total_hours.value), mathHours: Number(form.elements.math_hours.value) };
    if (!(values.totalHours > 0) || !(values.mathHours > 0) || values.mathHours > values.totalHours || values.totalHours > 168) {
      const el = rootEl()?.querySelector("[data-ep-live-profile-error]"); if (el) el.innerHTML = `<div class="ep-live-error">${esc(copy().invalid)}</div>`; return;
    }
    state.busy = true; renderLoading();
    const result = await internal.api.saveExamProfile(values); state.busy = false;
    if (!result?.ok) { renderError(); return; }
    const profile = await internal.api.examProfile(); state.profile = profile?.ok ? profile.data : null; await renderDashboard();
  }

  function componentSummary(component, statePayload) {
    const rows = Array.isArray(statePayload?.components) ? statePayload.components : [];
    return rows.find(x => x?.component_code === component) || rows[0] || null;
  }

  function componentCard(component, progress, statePayload) {
    const c = copy(), s = progress?.screening || {}, summary = componentSummary(component, statePayload);
    const reqItems = Number(s.required_items || 0), ansItems = Number(s.answered_items || 0), reqAreas = Number(s.required_areas || 0), ansAreas = Number(s.answered_areas || 0);
    const pct = reqItems > 0 ? Math.min(100, Math.round(100 * ansItems / reqItems)) : 0;
    const complete = progress?.stage0_complete === true, active = progress?.active_session;
    const stage = Number(summary?.operational_stage || 0), coverage = Number(summary?.coverage_pct || 0);
    const actions = [];
    if (complete) {
      actions.push(`<button class="ep-live-btn" type="button" data-ep-live-plan="${component}">${esc(c.openPlan)}</button>`);
      if (stage >= 2) actions.push(`<button class="ep-live-btn secondary" type="button" data-ep-live-timed="${component}">${esc(c.openTimed)}</button>`);
      if (stage >= 5) actions.push(`<button class="ep-live-btn secondary" type="button" data-ep-live-readiness="${component}">${esc(c.openReadiness)}</button>`);
    } else {
      actions.push(`<button class="ep-live-btn" type="button" data-ep-live-start="${component}" ${state.busy ? "disabled" : ""}>${esc(active ? c.resume : c.start)}</button>`);
    }
    const status = complete
      ? `<div class="ep-live-notice"><strong>${esc(c.stageTitle)}: ${esc(stageLabel(stage))}</strong><div class="ep-live-meta">${esc(c.coverage)}: ${coverage.toFixed(0)}%</div></div>`
      : `<div><div>${ansItems} / ${reqItems} ${esc(c.items)}</div><div class="ep-live-progress"><span style="width:${pct}%"></span></div><div class="ep-live-meta">${ansAreas} / ${reqAreas} ${esc(c.areas)}</div></div>`;
    return `<div class="ep-live-card"><strong>${component}</strong>${status}<div class="ep-live-actions">${actions.join("")}</div></div>`;
  }

  async function renderDashboard() {
    clearTimer();
    const root = rootEl(); if (!root) return; renderLoading();
    const [p1, p5, s1, s5] = await Promise.all([
      internal.api.diagnosticProgress("P1"), internal.api.diagnosticProgress("P5"),
      internal.api.getState("P1"), internal.api.getState("P5")
    ]);
    if (!p1?.ok || !p5?.ok || !s1?.ok || !s5?.ok) { renderError(); return; }
    state.progress.P1 = p1.data; state.progress.P5 = p5.data; state.componentState.P1 = s1.data; state.componentState.P5 = s5.data;
    const profileLine = [state.profile?.exam_series, state.profile?.target_grade].filter(Boolean).join(" · ");
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice">${esc(state.notice)}</div>` : ""}<div class="ep-live-meta">${esc(profileLine)}</div><div class="ep-live-grid">${componentCard("P1", p1.data, s1.data)}${componentCard("P5", p5.data, s5.data)}</div>`);
    state.notice = null;
    root.querySelectorAll("[data-ep-live-start]").forEach(b => b.addEventListener("click", () => startDiagnostic(b.dataset.epLiveStart)));
    root.querySelectorAll("[data-ep-live-plan]").forEach(b => b.addEventListener("click", () => openPlan(b.dataset.epLivePlan)));
    root.querySelectorAll("[data-ep-live-timed]").forEach(b => b.addEventListener("click", () => openTimed(b.dataset.epLiveTimed)));
    root.querySelectorAll("[data-ep-live-readiness]").forEach(b => b.addEventListener("click", () => openReadiness(b.dataset.epLiveReadiness)));
  }

  async function startDiagnostic(component) {
    if (state.busy) return; state.busy = true; renderLoading();
    const result = await internal.api.startNextDiagnostic(component, key(`ep-check-${component.toLowerCase()}`)); state.busy = false;
    if (!result?.ok || !result.data?.session_id) { renderError(); return; }
    state.returnView = { kind: "dashboard", component }; await loadSession(result.data.session_id);
  }

  function itemTypeLabel(type) {
    const c = copy(); return ({ learning: c.learning, correction: c.correction, retest: c.retest, mixed_transfer: c.mixed, rebaseline: c.rebaseline })[type] || c.learning;
  }

  async function openPlan(component) {
    clearTimer(); renderLoading();
    let planResult = await internal.api.weeklyPlan(component);
    if (!planResult?.ok) { renderError(); return; }
    let plan = planResult.data;
    if (!plan?.plan_id) {
      const generated = await internal.api.generateWeeklyPlan(component, "normal");
      if (!generated?.ok) { renderError(); return; }
      planResult = await internal.api.weeklyPlan(component); plan = planResult?.data;
    }
    if (!planResult?.ok || !plan?.plan_id) { renderError(copy().noPlan); return; }
    renderPlan(component, plan);
  }

  function renderPlan(component, plan) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy(); const items = Array.isArray(plan.items) ? plan.items : [];
    const rows = items.length ? items.map(item => {
      const due = item.due_at ? new Date(item.due_at) : null;
      const future = item.item_type === "retest" && due && due.getTime() > Date.now();
      const actionable = ["learning","correction","retest","mixed_transfer"].includes(item.item_type) && item.status === "pending";
      const button = actionable ? `<button class="ep-live-btn" data-ep-live-plan-item="${Number(item.priority_order)}" ${future ? "disabled" : ""}>${esc(future ? c.notDue : c.startTask)}</button>` : "";
      return `<div class="ep-live-plan-item"><div><strong>${esc(itemTypeLabel(item.item_type))}</strong>${due ? `<div class="ep-live-due">${esc(due.toLocaleString())}</div>` : ""}</div>${button}</div>`;
    }).join("") : `<div class="ep-live-notice">${esc(c.noPlan)}</div>`;
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice">${esc(state.notice)}</div>` : ""}<div class="ep-live-card"><div class="ep-live-head"><div><strong>${component} · ${esc(c.plan)}</strong><div class="ep-live-meta">${esc(c.week)} ${Number(plan.active_week_no || 1)}</div></div><button class="ep-live-btn secondary" data-ep-live-dashboard>${esc(c.overview)}</button></div>${rows}</div>`);
    state.notice = null;
    root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard);
    root.querySelectorAll('[data-ep-live-plan-item]').forEach(b => b.addEventListener('click', () => launchPlanItem(component, plan.plan_id, Number(b.dataset.epLivePlanItem))));
  }

  async function launchPlanItem(component, planId, priorityOrder) {
    if (state.busy) return; state.busy = true; renderLoading();
    const auth = await internal.api.authorizePlanItem(planId, priorityOrder);
    if (!auth?.ok || !auth.data?.authorization_id) { state.busy = false; renderError(); return; }
    const started = await internal.api.startSession(auth.data.authorization_id, key("ep-plan-session")); state.busy = false;
    if (!started?.ok || !started.data?.session_id) { renderError(); return; }
    state.returnView = { kind: "plan", component }; await loadSession(started.data.session_id);
  }

  async function openTimed(component) {
    clearTimer(); renderLoading();
    const result = await internal.api.timedCatalog(component);
    if (!result?.ok) { renderError(); return; }
    renderTimedCatalog(component, result.data);
  }

  function renderTimedCatalog(component, payload) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy(); const rows = Array.isArray(payload?.assessments) ? payload.assessments : [];
    const body = rows.length ? rows.map(row => `<div class="ep-live-timed-row"><div><strong>${esc(assessmentTitle(row))}</strong><div class="ep-live-meta">${Number(row.marks_available || 0)} ${esc(c.marks)} · ${minutes(row.time_limit_sec)} ${esc(c.minutes)}</div></div><button class="ep-live-btn" data-ep-live-timed-start="${Number(row.assessment_id)}">${esc(c.startTimed)}</button></div>`).join("") : `<div class="ep-live-notice">${esc(c.noTimed)}</div>`;
    root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><strong>${component} · ${esc(c.timed)}</strong><button class="ep-live-btn secondary" data-ep-live-dashboard>${esc(c.overview)}</button></div>${body}</div>`);
    root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard);
    root.querySelectorAll('[data-ep-live-timed-start]').forEach(b => b.addEventListener('click', () => startTimed(component, Number(b.dataset.epLiveTimedStart))));
  }

  async function startTimed(component, assessmentId) {
    if (state.busy) return; state.busy = true; renderLoading();
    const auth = await internal.api.authorizeTimed(assessmentId);
    if (!auth?.ok || !auth.data?.authorization_id) { state.busy = false; renderError(); return; }
    const started = await internal.api.startSession(auth.data.authorization_id, key("ep-timed-session")); state.busy = false;
    if (!started?.ok || !started.data?.session_id) { renderError(); return; }
    state.returnView = { kind: "timed", component }; await loadSession(started.data.session_id);
  }

  function deadlineMs(session) {
    const value = session?.timing_contract?.deadline_at; const ms = value ? new Date(value).getTime() : NaN;
    return Number.isFinite(ms) ? ms : null;
  }

  function startTimer(sessionId) {
    clearTimer(); const deadline = deadlineMs(state.session); if (!deadline) return;
    const tick = async () => {
      const left = Math.max(0, Math.ceil((deadline - Date.now()) / 1000));
      const el = rootEl()?.querySelector('[data-ep-live-timer]');
      if (el) el.textContent = `${copy().timeLeft}: ${String(Math.floor(left / 60)).padStart(2, "0")}:${String(left % 60).padStart(2, "0")}`;
      if (left <= 0) {
        clearTimer();
        if (!state.busy && state.session?.session_id === sessionId && ["timed","paper"].includes(state.session?.session_type)) await finishTimed("time_expired");
      }
    };
    tick(); state.timerId = setInterval(tick, 1000);
  }

  async function loadSession(sessionId) {
    clearTimer(); renderLoading(); const result = await internal.api.getSession(sessionId, state.language);
    if (!result?.ok) { renderError(); return; }
    state.session = result.data;
    const items = Array.isArray(state.session?.items) ? state.session.items : [], next = items.find(item => item && item.answered !== true);
    const timed = ["timed","paper"].includes(state.session?.session_type);
    if (timed && state.session?.status === "active" && deadlineMs(state.session) && Date.now() >= deadlineMs(state.session)) { await finishTimed("time_expired"); return; }
    if (!next && state.session?.status === "active") {
      if (timed) { await finishTimed("submitted"); return; }
      const finalized = await internal.api.finalizeSession(sessionId, key("ep-session-finalize"));
      if (!finalized?.ok) { renderError(); return; }
      const finishedType = state.session.session_type, component = state.session.component_code;
      state.session = null;
      if (finishedType === "diagnostic") { state.notice = copy().finish; await renderDashboard(); }
      else { await internal.api.generateWeeklyPlan(component, "normal"); state.notice = copy().completedTask; await openPlan(component); }
      return;
    }
    if (!next) { state.session = null; if (state.returnView?.kind === "plan") await openPlan(state.returnView.component); else if (state.returnView?.kind === "timed") await openTimed(state.returnView.component); else await renderDashboard(); return; }
    state.itemStartedAt = Date.now(); renderQuestion(next, items, timed);
  }

  function renderQuestion(item, items, timed = false) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy(), answered = items.filter(x => x?.answered === true).length, total = items.length;
    let answerControl = "";
    if (item.item_kind === "written") {
      answerControl = `<label class="ep-live-field"><span>${esc(c.written)}</span><textarea class="ep-live-textarea" name="ep_live_written_answer"></textarea></label>`;
    } else if (String(item.qtype || "").toLowerCase() === "mcq" && Array.isArray(item.options)) {
      answerControl = `<div class="ep-live-options">${item.options.map((option, index) => `<label class="ep-live-option"><input type="radio" name="ep_live_answer" value="${index}"><span>${esc(option)}</span></label>`).join("")}</div>`;
    } else answerControl = `<input class="ep-live-input" name="ep_live_text_answer" autocomplete="off">`;
    const timer = timed ? `<span class="ep-live-timer" data-ep-live-timer></span>` : "";
    const exit = timed ? `<button class="ep-live-btn secondary" type="button" data-ep-live-end>${esc(c.endAttempt)}</button>` : `<button class="ep-live-btn secondary" type="button" data-ep-live-exit>${esc(c.back)}</button>`;
    root.innerHTML = shell(`${state.notice ? `<div class="ep-live-notice">${esc(state.notice)}</div>` : ""}<div class="ep-live-card"><div class="ep-live-head"><strong>${esc(c.question)} ${answered + 1} / ${total}</strong>${timer}</div><div class="ep-live-qtext">${esc(item.text || item.written_prompt || "")}</div>${answerControl}<div class="ep-live-actions"><button class="ep-live-btn" type="button" data-ep-live-submit>${esc(c.submit)}</button>${exit}</div></div>`);
    state.notice = null;
    root.querySelector('[data-ep-live-submit]')?.addEventListener('click', () => submitAnswer(item));
    root.querySelector('[data-ep-live-exit]')?.addEventListener('click', async () => { state.session = null; if (state.returnView?.kind === "plan") await openPlan(state.returnView.component); else await renderDashboard(); });
    root.querySelector('[data-ep-live-end]')?.addEventListener('click', async () => { if (window.confirm(c.endConfirm)) await finishTimed("administrative_stop"); });
    if (timed) startTimer(state.session.session_id);
  }

  async function submitAnswer(item) {
    if (state.busy || !state.session) return; let payload;
    if (item.item_kind === "written") {
      const value = rootEl()?.querySelector('textarea[name="ep_live_written_answer"]')?.value?.trim(); if (!value) return; payload = { artifact: { text: value } };
    } else if (String(item.qtype || "").toLowerCase() === "mcq") {
      const chosen = rootEl()?.querySelector('input[name="ep_live_answer"]:checked'); if (!chosen) return; payload = { picked_index: Number(chosen.value) };
    } else {
      const value = rootEl()?.querySelector('input[name="ep_live_text_answer"]')?.value?.trim(); if (!value) return; payload = { answer: value };
    }
    state.busy = true; clearTimer(); renderLoading();
    const result = await internal.api.submitResponse(state.session.session_id, item.item_order, payload, key("ep-answer"), Date.now() - state.itemStartedAt, state.language); state.busy = false;
    if (!result?.ok) { renderError(); return; }
    const data = result.data || {}, c = copy(), parts = [];
    if (typeof data.is_correct === "boolean") parts.push(data.is_correct ? c.correct : c.incorrect);
    if (data.diagnostic_feedback) parts.push(data.diagnostic_feedback); else if (data.explanation) parts.push(data.explanation);
    if (data.next_action) parts.push(data.next_action);
    state.notice = parts.filter(Boolean).join(" — "); await loadSession(state.session.session_id);
  }

  async function finishTimed(reason) {
    if (state.busy || !state.session) return; const sessionId = state.session.session_id, component = state.session.component_code;
    state.busy = true; clearTimer(); renderLoading();
    const finalized = await internal.api.finalizeTimed(sessionId, key("ep-timed-finalize"), reason); state.busy = false;
    if (!finalized?.ok) { renderError(); return; }
    state.session = null; await openTimedReview(sessionId, component);
  }

  async function openTimedReview(sessionId, component) {
    renderLoading();
    const [review, result] = await Promise.all([internal.api.timedReviewPack(sessionId, state.language), internal.api.timedResult(sessionId)]);
    if (!review?.ok || !result?.ok) { renderError(); return; }
    const items = Array.isArray(review.data?.items) ? review.data.items : [];
    const next = items.find(item => item && item.self_marked !== true);
    if (next) renderSelfReview(sessionId, component, next, items.length, result.data);
    else renderTimedResult(component, result.data);
  }

  function renderSelfReview(sessionId, component, item, total, result) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy();
    const criteria = Array.isArray(item?.rubric?.criteria) ? item.rubric.criteria : [];
    const rubric = criteria.length ? `<div class="ep-live-rubric">${criteria.map(x => `<div class="ep-live-rubric-row">${esc(x.rule || "")} <strong>(${Number(x.marks || 0)})</strong></div>`).join("")}</div>` : "";
    root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><div><strong>${esc(c.selfReviewTitle)}</strong><div class="ep-live-meta">${esc(c.selfReviewText)}</div></div><span>${Number(item.item_order)} / ${total}</span></div><div><strong>${esc(c.question)}</strong><div class="ep-live-qtext">${esc(item.prompt || "")}</div></div><div><strong>${esc(c.yourAnswer)}</strong><div class="ep-live-answer">${esc(artifactText(item.learner_artifact))}</div></div><div><strong>${esc(c.rubric)}</strong>${rubric}</div>${item.self_review ? `<div class="ep-live-notice"><strong>${esc(c.selfTip)}:</strong> ${esc(item.self_review)}</div>` : ""}<label class="ep-live-field"><span>${esc(c.award)} (0–${Number(item.max_marks || 0)})</span><input name="ep_live_self_mark" type="number" min="0" max="${Number(item.max_marks || 0)}" step="1"></label><div class="ep-live-actions"><button class="ep-live-btn" data-ep-live-save-self>${esc(c.saveMark)}</button></div></div>`);
    root.querySelector('[data-ep-live-save-self]')?.addEventListener('click', async () => {
      const input = rootEl()?.querySelector('input[name="ep_live_self_mark"]'); const marks = Number(input?.value);
      if (!Number.isInteger(marks) || marks < 0 || marks > Number(item.max_marks || 0)) return;
      state.busy = true; renderLoading();
      const saved = await internal.api.submitTimedSelfMark(sessionId, item.item_order, marks, key("ep-self-mark"), null); state.busy = false;
      if (!saved?.ok) { renderError(); return; }
      await openTimedReview(sessionId, component);
    });
  }

  function renderTimedResult(component, result) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy();
    root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><strong>${component} · ${esc(c.result)}</strong><button class="ep-live-btn secondary" data-ep-live-dashboard>${esc(c.overview)}</button></div><div class="ep-live-stats"><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.inTime)}</span><strong>${Number(result?.marks_in_time || 0)} / ${Number(result?.marks_available || 0)}</strong></div><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.afterTime)}</span><strong>${Number(result?.marks_after_time || 0)}</strong></div><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.unattempted)}</span><strong>${Number(result?.unattempted_marks || 0)}</strong></div></div><div class="ep-live-notice">${esc(c.comparable)}: <strong>${esc(result?.score_comparable ? c.yes : c.no)}</strong></div><div class="ep-live-actions"><button class="ep-live-btn" data-ep-live-back-timed>${esc(c.backTimed)}</button><button class="ep-live-btn secondary" data-ep-live-readiness="${component}">${esc(c.openReadiness)}</button></div></div>`);
    root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard);
    root.querySelector('[data-ep-live-back-timed]')?.addEventListener('click', () => openTimed(component));
    root.querySelector('[data-ep-live-readiness]')?.addEventListener('click', () => openReadiness(component));
  }

  function readinessMessage(data) {
    const c = copy(); const reason = String(data?.reason_code || "");
    return ({
      threshold_configuration_pending: c.thresholdPending,
      three_comparable_attempts_incomplete: c.threePapers,
      stage4_exit_incomplete: c.stage4Incomplete,
      objective_skill_stability_incomplete: c.skillsIncomplete,
      corrective_cycles_open: c.correctionsOpen,
      last_three_below_individual_threshold: c.belowThreshold,
      unattempted_marks_not_minimal: c.unattemptedHigh,
      after_time_dependency_not_closed: c.afterTimeHigh
    })[reason] || c.readyMore;
  }

  async function openReadiness(component) {
    clearTimer(); renderLoading();
    const result = await internal.api.readiness(component);
    if (!result?.ok) { renderError(); return; }
    renderReadiness(component, result.data || {});
  }

  function renderReadiness(component, data) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy(); const ready = data?.ready === true;
    const calibration = ready ? `<button class="ep-live-btn" data-ep-live-calibration="${component}">${esc(c.openCalibration)}</button>` : "";
    root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><strong>${component} · ${esc(c.readiness)}</strong><button class="ep-live-btn secondary" data-ep-live-dashboard>${esc(c.overview)}</button></div><div class="ep-live-notice"><strong>${esc(ready ? c.readyStrong : c.readyMore)}</strong><div class="ep-live-meta">${esc(ready ? c.readyStrong : readinessMessage(data))}</div></div><div class="ep-live-stats"><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.readinessPapers)}</span><strong>${Number(data?.last_three_count || 0)}</strong></div><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.readinessSkills)}</span><strong>${Number(data?.below_l3_count || 0)}</strong></div><div class="ep-live-stat"><span class="ep-live-meta">${esc(c.readinessCorrections)}</span><strong>${Number(data?.unresolved_correction_case_count || 0)}</strong></div></div><div class="ep-live-actions">${calibration}</div></div>`);
    root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard);
    root.querySelector('[data-ep-live-calibration]')?.addEventListener('click', () => openCalibration(component));
  }

  function calibrationActionLabel(code) {
    const c = copy();
    return ({ close_recurring_issue:c.actionCloseIssue, short_targeted_work:c.actionShort, timing_and_logistics:c.actionTiming, taper:c.actionTaper })[code] || c.actionShort;
  }

  async function openCalibration(component) {
    clearTimer(); renderLoading();
    const result = await internal.api.finalCalibration(component);
    if (!result?.ok) { renderError(); return; }
    renderCalibration(component, result.data || {});
  }

  function renderCalibration(component, data) {
    clearTimer();
    const root = rootEl(); if (!root) return; const c = copy();
    if (data?.available !== true) {
      root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><strong>${component} · ${esc(c.calibration)}</strong><button class="ep-live-btn secondary" data-ep-live-dashboard>${esc(c.overview)}</button></div><div class="ep-live-notice">${esc(c.calibrationUnavailable)}</div></div>`);
      root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard); return;
    }
    const actions = Array.isArray(data?.actions) ? data.actions : [];
    const rows = actions.map((a, index) => `<div class="ep-live-action-row"><strong>${index + 1}. ${esc(calibrationActionLabel(a.action_code))}</strong></div>`).join("");
    root.innerHTML = shell(`<div class="ep-live-card"><div class="ep-live-head"><strong>${component} · ${esc(c.calibration)}</strong><button class="ep-live-btn secondary" data-ep-live-dashboard>${esc(c.overview)}</button></div>${rows || `<div class="ep-live-notice">${esc(c.calibration)}</div>`}</div>`);
    root.querySelector('[data-ep-live-dashboard]')?.addEventListener('click', renderDashboard);
  }

  async function mount(context = {}) {
    state.language = lang(context.language || state.language); if (!canMount()) return false;
    const root = rootEl(); if (!root || root.hidden || root.querySelector('[data-ep-beta-action]')) return false;
    ensureStyle(); renderLoading(); const profile = await internal.api.examProfile(); if (!profile?.ok) { renderError(); return false; }
    state.profile = profile.data; if (!state.profile) renderProfile(); else await renderDashboard(); return true;
  }
  function reset() { clearTimer(); state.busy = false; state.profile = null; state.progress = { P1: null, P5: null }; state.componentState = { P1: null, P5: null }; state.session = null; state.returnView = null; state.notice = null; }

  function attach() {
    if (attached) return; const host = window.iClubExamPrep;
    if (!host || typeof host.open !== "function") { setTimeout(attach, 0); return; }
    attached = true;
    window.iClubExamPrep = Object.freeze({
      syncSubjectHub: async context => { state.language = lang(context?.language || state.language); const result = await host.syncSubjectHub(context); if (!result) reset(); return result; },
      refreshCapabilities: async () => { const result = await host.refreshCapabilities(); if (host.isOpen() && canMount()) await mount({ language: state.language }); return result; },
      open: async context => { state.language = lang(context?.language || state.language); const result = await host.open(context); if (result && canMount()) await mount(context || {}); return result; },
      back: () => { reset(); return host.back(); }, close: () => { reset(); return host.close(); }, isOpen: () => host.isOpen(), liveFlowVersion: VERSION
    });
  }

  attach();
})();