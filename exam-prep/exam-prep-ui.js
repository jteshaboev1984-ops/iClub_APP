(() => {
  "use strict";

  const root = (window.iClubExamPrepPreview = window.iClubExamPrepPreview || {});
  const { config, staticData, engine } = root;

  const esc = value => String(value ?? "").replace(/[&<>'"]/g, ch => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;"
  })[ch]);

  function copy(lang) {
    return root.i18n.get(lang);
  }

  function langText(obj, lang) {
    return engine.t(obj, lang);
  }

  function readinessClass(key) {
    if (key === "strong" || key === "ready") return "is-good";
    if (key === "ontrack") return "is-primary";
    if (key === "risk" || key === "notready") return "is-warn";
    return "is-muted";
  }

  function stageChip(state, c) {
    return `<span class="ep-stage-chip">${esc(c.stageLabel)} ${state.stage}: ${esc(c.stages[state.stage] || "—")}</span>`;
  }

  function progressBar(percent) {
    return `<div class="ep-progress" aria-label="${esc(percent)}%"><span style="width:${Math.max(0, Math.min(100, Number(percent) || 0))}%"></span></div>`;
  }

  function readinessBadge(key, c) {
    const label = c.readinessStates[key] || key;
    return `<span class="ep-badge ${readinessClass(key)}">${esc(label)}</span>`;
  }

  function componentCard(component, state, mentorReadiness, c) {
    return `
      <article class="ep-card ep-component-card" data-component="${esc(component)}">
        <div class="ep-card-head">
          <div>
            <div class="ep-kicker">${esc(component)}</div>
            <h2>${esc(c.components[component])}</h2>
          </div>
          ${stageChip(state, c)}
        </div>
        <div class="ep-metric-row">
          <div class="ep-metric"><strong>${esc(state.coverage)}%</strong><span>${esc(c.coverage)}</span></div>
          <div class="ep-metric"><strong>${esc(state.confidence)}%</strong><span>${esc(c.confidence)}</span></div>
        </div>
        ${progressBar(state.coverage)}
        <dl class="ep-facts">
          <div><dt>${esc(c.lastEvidence)}</dt><dd>${esc(state.evidenceLabel)}</dd></div>
          <div><dt>${esc(c.nextAction)}</dt><dd>${esc(state.nextAction)}</dd></div>
          <div><dt>${esc(c.appEstimate)}</dt><dd>${readinessBadge(state.readiness, c)}</dd></div>
          <div><dt>${esc(c.mentorVerified)}</dt><dd>${mentorReadiness === "notIncluded" ? `<span class="ep-badge is-muted">${esc(c.notIncluded)}</span>` : readinessBadge(mentorReadiness, c)}</dd></div>
        </dl>
      </article>`;
  }

  function servicePanel(vm, c) {
    if (vm.service.aiUnavailable) {
      return `<section class="ep-banner ep-banner-warn"><strong>AI</strong><span>${esc(c.aiUnavailable)}</span></section>`;
    }
    if (vm.service.aiAssist) {
      return `<section class="ep-banner ep-banner-ai"><strong>AI</strong><span>${esc(c.aiWhy)}: ${esc(langText(vm.profile.weeklyTasks[0]?.aiReason || {}, vm.lang || "ru"))}</span></section>`;
    }
    if (vm.service.mentorAssignmentActive) {
      return `<section class="ep-banner ep-banner-mentor"><strong>${esc(c.assignedMentor)}</strong><span>${esc(c.mentorReviewLead)}</span></section>`;
    }
    return `<section class="ep-banner"><strong>${esc(c.services.core)}</strong><span>${esc(c.weeklyLead)}</span></section>`;
  }

  function renderOverview(vm, lang) {
    const c = copy(lang);
    vm.lang = lang;
    const flags = vm.profile.flags || [];
    return `
      <section class="ep-page-head">
        <div><div class="ep-kicker">${esc(langText(vm.profile.labels, lang))}</div><h1>${esc(c.routes.overview)}</h1><p>${esc(langText(vm.profile.description, lang))}</p></div>
      </section>
      ${servicePanel(vm, c)}
      ${flags.includes("offline") ? `<section class="ep-banner ep-banner-warn"><strong>${esc(c.waitingSync)}</strong><span>${esc(c.offlineNoUplift)}</span></section>` : ""}
      <div class="ep-grid-2">
        ${componentCard("P1", vm.p1, vm.mentorReadinessP1, c)}
        ${componentCard("P5", vm.p5, vm.mentorReadinessP5, c)}
      </div>
      <section class="ep-card ep-summary-card">
        <div class="ep-card-head"><div><div class="ep-kicker">9709</div><h2>45 + 36 = 81</h2></div><span class="ep-badge is-muted">v1.0</span></div>
        <p class="ep-note">${lang === "ru" ? "81 — внутренняя каноническая декомпозиция iClub, а не официальное число навыков Cambridge." : lang === "uz" ? "81 — iClub ichki kanonik bo‘linishi, Cambridge rasmiy ko‘nikmalar soni emas." : "81 is iClub’s internal canonical decomposition, not an official Cambridge skill count."}</p>
      </section>`;
  }

  function renderExamProfile(vm, lang) {
    const c = copy(lang);
    return `
      <section class="ep-page-head"><div><h1>${esc(c.routes["exam-profile"])}</h1><p>${esc(c.placementLead)}</p></div></section>
      <section class="ep-card">
        <dl class="ep-facts ep-facts-wide">
          <div><dt>${esc(c.series)}</dt><dd>May–June 2027</dd></div>
          <div><dt>${esc(c.route)}</dt><dd>Cambridge International AS Mathematics 9709 · P1 + P5</dd></div>
          <div><dt>${esc(c.targetGrade)}</dt><dd>A</dd></div>
          <div><dt>${esc(c.totalHours)}</dt><dd>${esc(vm.profile.totalStudyHours)} / week</dd></div>
          <div><dt>${esc(c.weeklyBudget)}</dt><dd>${esc(vm.profile.weeklyBudget)} / week</dd></div>
          <div><dt>${esc(c.studied)}</dt><dd>${esc(vm.profile.studied)}</dd></div>
          <div><dt>${esc(c.paperHistory)}</dt><dd>${esc(vm.profile.paperHistory)}</dd></div>
          <div><dt>${esc(c.targetWindow)}</dt><dd>Active week 1 → active week 36</dd></div>
        </dl>
      </section>`;
  }

  function placementPanel(component, state, steps, c) {
    const statusLabel = status => status === "completed" ? c.completed : c.pending;
    return `
      <article class="ep-card">
        <div class="ep-card-head"><div><div class="ep-kicker">${esc(component)}</div><h2>${esc(c.components[component])}</h2></div>${readinessBadge(state.readiness, c)}</div>
        <p>${esc(c.conservative)} · ${esc(c.confidence)} ${esc(state.confidence)}%</p>
        <div class="ep-step-list">
          <div><span>1</span><strong>${esc(c.broadCheck)}</strong><em>${esc(statusLabel(steps[0].status))}</em></div>
          <div><span>2</span><strong>${esc(c.targetedCheck)}</strong><em>${esc(statusLabel(steps[1].status))}</em></div>
          <div><span>3</span><strong>${esc(c.delayedRetest)}</strong><em>${esc(statusLabel(steps[2].status))}</em></div>
        </div>
        <button class="ep-btn ep-btn-primary" type="button" data-action="set-component" data-component="${esc(component)}">${esc(c.continue)}</button>
      </article>`;
  }

  function renderPlacementHub(vm, lang) {
    const c = copy(lang);
    return `
      <section class="ep-page-head"><div><h1>${esc(c.placementTitle)}</h1><p>${esc(c.placementLead)}</p></div></section>
      <div class="ep-grid-2">
        ${placementPanel("P1", vm.p1, vm.placementP1, c)}
        ${placementPanel("P5", vm.p5, vm.placementP5, c)}
      </div>`;
  }

  function renderPlacementRun(vm, lang) {
    const c = copy(lang);
    const q = vm.sampleQuestion;
    return `
      <section class="ep-page-head"><div><div class="ep-kicker">${esc(q.component)}</div><h1>${esc(c.routes["placement-run"])}</h1><p>${esc(c.synthetic)} · ${esc(c.noAnswerSaved)}</p></div></section>
      <section class="ep-card ep-question-card">
        <div class="ep-question-no">${esc(c.question)} 1 / 1</div>
        <h2>${esc(q.stem)}</h2>
        <div class="ep-options">
          ${q.options.map((option, i) => `<button type="button" class="ep-option" data-action="pick-demo"><span>${String.fromCharCode(65 + i)}</span>${esc(option)}</button>`).join("")}
        </div>
        <p class="ep-note" id="ep-demo-answer-note">${esc(c.chooseAnswer)}</p>
        <button class="ep-btn ep-btn-primary" type="button" data-action="demo-submit">${esc(c.submit)}</button>
      </section>`;
  }

  function renderPlacementResult(vm, lang) {
    const c = copy(lang);
    const state = vm.component === "P1" ? vm.p1 : vm.p5;
    return `
      <section class="ep-page-head"><div><div class="ep-kicker">${esc(vm.component)}</div><h1>${esc(c.routes["placement-result"])}</h1><p>${esc(c.placementLead)}</p></div></section>
      <section class="ep-card ep-result-card">
        <div class="ep-result-ring"><strong>${esc(state.confidence)}%</strong><span>${esc(c.confidence)}</span></div>
        <div class="ep-result-copy">
          ${stageChip(state, c)}
          <h2>${esc(state.placement)}</h2>
          <p>${esc(c.conservative)}. ${esc(c.nextAction)}: ${esc(state.nextAction)}.</p>
          <div class="ep-inline-badges">${readinessBadge(state.readiness, c)}<span class="ep-badge is-muted">${esc(c.delayedRetest)}: ${esc(state.delayedRetest)}</span></div>
        </div>
      </section>`;
  }

  function areaTable(rows, c) {
    return `<div class="ep-area-list">${rows.map(row => `
      <div class="ep-area-row">
        <div class="ep-area-title"><span>${esc(row.section)}</span><strong>${esc(row.title)}</strong><em>${esc(row.confirmed)}/${esc(row.total)}</em></div>
        ${progressBar(row.percent)}
      </div>`).join("")}</div>`;
  }

  function renderSyllabusTracker(vm, lang) {
    const c = copy(lang);
    return `
      <section class="ep-page-head"><div><h1>${esc(c.routes["syllabus-tracker"])}</h1><p>${esc(c.placementLead)}</p></div></section>
      <div class="ep-grid-2">
        <section class="ep-card"><div class="ep-card-head"><h2>P1 · 45 ${esc(c.skills)}</h2><strong>${esc(vm.p1.coverage)}%</strong></div>${areaTable(vm.p1Areas, c)}</section>
        <section class="ep-card"><div class="ep-card-head"><h2>P5 · 36 ${esc(c.skills)}</h2><strong>${esc(vm.p5.coverage)}%</strong></div>${areaTable(vm.p5Areas, c)}</section>
      </div>
      <section class="ep-card ep-inline-stats">
        <div><strong>81</strong><span>${esc(c.skills)}</span></div>
        <div><strong>23</strong><span>Mixed</span></div>
        <div><strong>${esc(staticData.prerequisites.length)}</strong><span>${esc(c.prerequisites)}</span></div>
      </section>`;
  }

  function renderSkillDetail(vm, lang) {
    const c = copy(lang);
    const skill = vm.focusSkill;
    const written = vm.service.mentorAssignmentActive ? c.mentorReviewed : c.selfReviewed;
    return `
      <section class="ep-page-head"><div><div class="ep-kicker">${esc(skill.code)} · ${esc(skill.component)}</div><h1>${esc(skill.title)}</h1><p>${esc(c.routes["skill-detail"])}</p></div></section>
      <section class="ep-card">
        <dl class="ep-facts ep-facts-wide">
          <div><dt>${esc(c.evidence)}</dt><dd>${esc(skill.evidence)}</dd></div>
          <div><dt>${esc(c.prerequisites)}</dt><dd>${skill.prerequisites.map(x => `<span class="ep-code">${esc(x)}</span>`).join(" ")}</dd></div>
          <div><dt>${esc(c.writtenStatus)}</dt><dd>${esc(written)}</dd></div>
          <div><dt>${esc(c.retestDue)}</dt><dd>${esc(skill.delayedRetest)}</dd></div>
          <div><dt>${esc(c.resources)}</dt><dd>${esc(skill.resource)}</dd></div>
        </dl>
      </section>`;
  }

  function renderWeeklyPlan(vm, lang) {
    const c = copy(lang);
    return `
      <section class="ep-page-head"><div><h1>${esc(c.weeklyTitle)}</h1><p>${esc(c.weeklyLead)}</p></div></section>
      ${vm.service.aiUnavailable ? `<section class="ep-banner ep-banner-warn"><strong>AI</strong><span>${esc(c.aiUnavailable)}</span></section>` : ""}
      <div class="ep-task-list">
        ${vm.weeklyTasks.map(task => `
          <article class="ep-card ep-task-card">
            <div class="ep-task-priority">${esc(c.priority)} ${esc(task.priority)}</div>
            <div class="ep-task-main"><div class="ep-kicker">${esc(task.component)} · ${esc(task.minutes)} ${esc(c.minutes)}</div><h2>${esc(task.title)}</h2><p>${esc(c.due)}: ${esc(task.due)}</p>
            ${task.aiReason ? `<div class="ep-ai-box"><strong>AI · ${esc(c.aiWhy)}</strong><span>${esc(task.aiReason)}</span></div>` : ""}
            ${task.mentorAdjusted ? `<div class="ep-mentor-box"><strong>${esc(c.assignedMentor)}</strong><span>${esc(c.mentorNote)}</span></div>` : ""}
            </div>
          </article>`).join("")}
      </div>`;
  }

  function renderCorrections(vm, lang) {
    const c = copy(lang);
    return `
      <section class="ep-page-head"><div><h1>${esc(c.correctionTitle)}</h1><p>${esc(c.correctionCycle)}</p></div></section>
      ${vm.profile.flags.includes("offline") ? `<section class="ep-banner ep-banner-warn"><strong>${esc(c.waitingSync)}</strong><span>${esc(c.offlineNoUplift)}</span></section>` : ""}
      <div class="ep-task-list">
        ${vm.corrections.length ? vm.corrections.map(item => `
          <article class="ep-card ep-correction-card">
            <div class="ep-card-head"><div><div class="ep-kicker">${esc(item.component)} · ${esc(item.skill)}</div><h2>${esc(c.needsReview)}</h2></div><span class="ep-badge is-warn">${esc(c.open)}</span></div>
            <dl class="ep-facts ep-facts-wide"><div><dt>${esc(c.errorCause)}</dt><dd>${esc(item.cause)}</dd></div><div><dt>${esc(c.correctionAction)}</dt><dd>${esc(item.action)}</dd></div><div><dt>${esc(c.retestDue)}</dt><dd>${esc(item.due)}</dd></div></dl>
          </article>`).join("") : `<section class="ep-card"><p>${esc(c.completed)}</p></section>`}
      </div>`;
  }

  function renderTimedHub(vm, lang) {
    const c = copy(lang);
    const p = vm.paper;
    return `
      <section class="ep-page-head"><div><h1>${esc(c.timedTitle)}</h1><p>${esc(c.timedLead)}</p></div></section>
      <div class="ep-grid-3">
        <article class="ep-card ep-choice-card"><span class="ep-icon">◷</span><h2>${esc(c.timedSection)}</h2><p>P1 / P5 · component-specific</p></article>
        <article class="ep-card ep-choice-card"><span class="ep-icon">◫</span><h2>${esc(c.modifiedPaper)}</h2><p>${esc(c.coverage)} → safe scope</p></article>
        <article class="ep-card ep-choice-card"><span class="ep-icon">▤</span><h2>${esc(c.fullPaper)}</h2><p>P1 110 min · P5 75 min</p></article>
      </div>
      <section class="ep-card">
        <div class="ep-card-head"><div><div class="ep-kicker">${esc(p.component)}</div><h2>${esc(p.title)}</h2></div>${readinessBadge((p.unattempted === "0 marks") ? "ontrack" : "risk", c)}</div>
        <dl class="ep-facts"><div><dt>${esc(c.officialTime)}</dt><dd>${esc(p.officialTime)}</dd></div><div><dt>${esc(c.actualTime)}</dt><dd>${esc(p.actualTime)}</dd></div><div><dt>${esc(c.rawMark)}</dt><dd>${esc(p.rawMark)}</dd></div><div><dt>${esc(c.unattempted)}</dt><dd>${esc(p.unattempted)}</dd></div></dl>
      </section>`;
  }

  function renderPaperResult(vm, lang) {
    const c = copy(lang);
    const p = vm.paper;
    return `
      <section class="ep-page-head"><div><div class="ep-kicker">${esc(p.component)}</div><h1>${esc(c.routes["paper-result"])}</h1><p>${esc(c.timedLead)}</p></div></section>
      <section class="ep-card">
        <div class="ep-score-strip"><div><strong>${esc(p.rawMark)}</strong><span>${esc(c.rawMark)}</span></div><div><strong>${esc(p.inTime)}</strong><span>${esc(c.inTime)}</span></div><div><strong>${esc(p.unattempted)}</strong><span>${esc(c.unattempted)}</span></div></div>
        <dl class="ep-facts ep-facts-wide"><div><dt>${esc(c.officialTime)}</dt><dd>${esc(p.officialTime)}</dd></div><div><dt>${esc(c.actualTime)}</dt><dd>${esc(p.actualTime)}</dd></div><div><dt>${esc(c.recurringErrors)}</dt><dd>${esc(p.recurringErrors)}</dd></div><div><dt>${esc(c.paperCorrection)}</dt><dd>${esc(p.correction)}</dd></div></dl>
      </section>`;
  }

  function renderMentorReview(vm, lang) {
    const c = copy(lang);
    if (!vm.mentor.assigned) {
      return `
        <section class="ep-page-head"><div><h1>${esc(c.mentorReviewTitle)}</h1><p>${esc(c.mentorReviewLead)}</p></div></section>
        <section class="ep-card ep-empty"><span class="ep-icon">✓</span><h2>${esc(c.noMentorQueue)}</h2><p>${esc(c.continueCore)}</p><span class="ep-badge is-good">Queue: 0</span></section>`;
    }
    const review = vm.mentor.review;
    if (!review) {
      return `
        <section class="ep-page-head"><div><h1>${esc(c.mentorReviewTitle)}</h1><p>${esc(c.assignedMentor)}</p></div></section>
        <section class="ep-card ep-empty"><span class="ep-icon">✓</span><h2>${esc(c.completed)}</h2><p>Queue: 0</p></section>`;
    }
    return `
      <section class="ep-page-head"><div><div class="ep-kicker">${esc(review.component)} · ${esc(review.skill)}</div><h1>${esc(c.mentorReviewTitle)}</h1><p>${esc(c.assignedMentor)} · ${esc(review.task)}</p></div></section>
      <section class="ep-card">
        <div class="ep-card-head"><h2>${esc(c.waitingReview)}</h2><span class="ep-badge ${review.status === "verified" ? "is-good" : "is-warn"}">${esc(review.status)}</span></div>
        <dl class="ep-facts ep-facts-wide">
          <div><dt>${esc(c.methodMarks)}</dt><dd>${esc(review.methodMarks)}</dd></div>
          <div><dt>${esc(c.decision)}</dt><dd>${esc(review.decision)}</dd></div>
          <div><dt>${esc(c.reason)}</dt><dd>${esc(review.reason)}</dd></div>
          <div><dt>${esc(c.linkedEvidence)}</dt><dd><span class="ep-code">${esc(review.linkedEvidence)}</span></dd></div>
          <div><dt>${esc(c.beforeAfter)}</dt><dd>${esc(review.beforeAfter)}</dd></div>
        </dl>
      </section>`;
  }

  const renderers = Object.freeze({
    overview: renderOverview,
    "exam-profile": renderExamProfile,
    "placement-hub": renderPlacementHub,
    "placement-run": renderPlacementRun,
    "placement-result": renderPlacementResult,
    "syllabus-tracker": renderSyllabusTracker,
    "skill-detail": renderSkillDetail,
    "weekly-plan": renderWeeklyPlan,
    "correction-queue": renderCorrections,
    "timed-paper-hub": renderTimedHub,
    "paper-result": renderPaperResult,
    "mentor-review": renderMentorReview
  });

  function fillControls(state) {
    const c = copy(state.lang);
    const language = document.querySelector("#ep-language");
    const profile = document.querySelector("#ep-profile");
    const service = document.querySelector("#ep-service");

    if (language) {
      language.innerHTML = `<option value="ru">RU</option><option value="uz">UZ</option><option value="en">EN</option>`;
      language.value = state.lang;
      language.setAttribute("aria-label", c.language);
    }
    if (profile) {
      profile.innerHTML = staticData.profiles.map(item => `<option value="${esc(item.id)}">${esc(langText(item.labels, state.lang))}</option>`).join("");
      profile.value = state.profileId;
      profile.setAttribute("aria-label", c.profile);
    }
    if (service) {
      service.innerHTML = config.allowedServiceModes.map(mode => `<option value="${mode}">${esc(c.services[mode])}</option>`).join("");
      service.value = state.mode;
      service.setAttribute("aria-label", c.service);
    }

    const title = document.querySelector("#ep-title");
    const subtitle = document.querySelector("#ep-subtitle");
    const badge = document.querySelector("#ep-preview-badge");
    const notice = document.querySelector("#ep-preview-notice");
    if (title) title.textContent = c.appTitle;
    if (subtitle) subtitle.textContent = c.appSubtitle;
    if (badge) badge.textContent = c.previewBadge;
    if (notice) notice.textContent = c.previewNotice;
  }

  function renderNav(state) {
    const c = copy(state.lang);
    const nav = document.querySelector("#ep-route-nav");
    if (!nav) return;
    nav.innerHTML = config.routes.map(route => `<button type="button" class="ep-nav-chip ${route === state.route ? "is-active" : ""}" data-route="${esc(route)}">${esc(c.routes[route])}</button>`).join("");
  }

  function render(state) {
    const rootEl = document.querySelector("#exam-prep-root");
    if (!rootEl) return;
    fillControls(state);
    renderNav(state);
    const vm = engine.buildViewModel({ profileId: state.profileId, mode: state.mode, lang: state.lang, component: state.component });
    const renderer = renderers[state.route] || renderOverview;
    rootEl.innerHTML = renderer(vm, state.lang);
  }

  root.ui = Object.freeze({ render, fillControls, renderNav });
})();
