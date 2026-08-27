(() => {
  "use strict";

  const root = (window.iClubExamPrepPreview = window.iClubExamPrepPreview || {});
  const { config, staticData } = root;
  const { invariant, validateComponent, validateServiceMode } = root.contracts;

  const byId = new Map(staticData.profiles.map(profile => [profile.id, profile]));

  function t(value, lang) {
    if (value && typeof value === "object" && !Array.isArray(value)) {
      return value[lang] || value.ru || value.en || value.uz || "—";
    }
    return String(value ?? "—");
  }

  function getProfile(profileId) {
    return byId.get(profileId) || staticData.profiles[0];
  }

  function getComponentState(profile, component) {
    validateComponent(component);
    return component === "P1" ? profile.p1 : profile.p5;
  }

  function areaRows(profile, component, lang) {
    const state = getComponentState(profile, component);
    const areas = staticData.areas.filter(area => area.component === component);
    const denominator = config.componentCounts[component];
    let remaining = Math.round((state.coverage / 100) * denominator);

    return areas.map(area => {
      const confirmed = Math.max(0, Math.min(area.count, remaining));
      remaining -= confirmed;
      const status = confirmed === area.count ? "confirmed" : confirmed > 0 ? "learning" : "locked";
      return Object.freeze({
        section: area.section,
        family: area.family,
        title: t(area.title, lang),
        confirmed,
        total: area.count,
        percent: Math.round((confirmed / area.count) * 100),
        status
      });
    });
  }

  function representativeSkill(profile, component, lang) {
    const rows = areaRows(profile, component, lang);
    const focus = rows.find(row => row.status === "learning") || rows.find(row => row.status === "locked") || rows[rows.length - 1];
    const skill = staticData.skills.find(item => item.component === component && item.family === focus.family) || staticData.skills.find(item => item.component === component);
    const state = getComponentState(profile, component);
    return Object.freeze({
      code: skill.code,
      title: focus.title,
      component,
      evidence: state.evidenceLabel,
      prerequisites: staticData.prerequisites.slice(0, component === "P1" ? 3 : 4),
      writtenStatus: state.writtenStatus,
      delayedRetest: state.delayedRetest || "—",
      resource: component === "P1" ? "Complete Pure Mathematics 1" : "Complete Probability & Statistics 1"
    });
  }

  function serviceState(profile, mode) {
    validateServiceMode(mode);
    const aiRequested = mode === "ai";
    const mentorAssigned = mode === "mentor";
    const aiUnavailable = profile.flags.includes("ai-unavailable");

    return Object.freeze({
      mode,
      coreAccess: true,
      aiAssist: aiRequested && !aiUnavailable,
      aiUnavailable: aiRequested && aiUnavailable,
      mentorEntitled: mentorAssigned,
      mentorAssignmentActive: mentorAssigned,
      mentorQueueAllowed: mentorAssigned,
      academicStateMutationAllowed: false
    });
  }

  function mentorReadiness(profile, component, mode) {
    if (mode !== "mentor") return "notIncluded";
    const state = getComponentState(profile, component);
    if (profile.id === "exam-mode-candidate" && state.stage >= 5 && state.writtenStatus === "verified") {
      return component === "P1" ? "ready" : "pending";
    }
    return "pending";
  }

  function weeklyTasks(profile, mode, lang) {
    const service = serviceState(profile, mode);
    return profile.weeklyTasks.map(task => Object.freeze({
      id: task.id,
      component: task.component,
      title: t(task.title, lang),
      minutes: task.minutes,
      priority: task.priority,
      due: task.due,
      status: task.status,
      aiReason: service.aiAssist ? t(task.aiReason, lang) : null,
      mentorAdjusted: service.mentorAssignmentActive && task.priority === 1
    }));
  }

  function corrections(profile, lang) {
    return profile.corrections.map(item => Object.freeze({
      id: item.id,
      component: item.component,
      skill: item.skill,
      cause: t(item.cause, lang),
      action: t(item.action, lang),
      status: item.status,
      due: item.due
    }));
  }

  function placementSteps(profile, component) {
    const state = getComponentState(profile, component);
    return Object.freeze([
      { key: "broad", status: state.confidence >= 75 ? "completed" : "open" },
      { key: "targeted", status: state.confidence >= 85 ? "completed" : "open" },
      { key: "retest", status: state.delayedRetest === "passed" || state.delayedRetest === "stable" ? "completed" : "open" }
    ]);
  }

  function sampleQuestion(component, lang) {
    validateComponent(component);
    const questions = {
      P1: {
        ru: { stem: "Для функции f(x) = x² − 6x + 11 выберите координаты вершины.", options: ["(3, 2)", "(−3, 2)", "(3, 11)", "(6, 2)"] },
        uz: { stem: "f(x) = x² − 6x + 11 funksiya uchun uch nuqta koordinatalarini tanlang.", options: ["(3, 2)", "(−3, 2)", "(3, 11)", "(6, 2)"] },
        en: { stem: "For f(x) = x² − 6x + 11, choose the coordinates of the vertex.", options: ["(3, 2)", "(−3, 2)", "(3, 11)", "(6, 2)"] }
      },
      P5: {
        ru: { stem: "В группе частоты 12, 18 и 10. Какова общая частота?", options: ["30", "36", "40", "42"] },
        uz: { stem: "Guruhdagi chastotalar 12, 18 va 10. Umumiy chastota nechaga teng?", options: ["30", "36", "40", "42"] },
        en: { stem: "A group has frequencies 12, 18 and 10. What is the total frequency?", options: ["30", "36", "40", "42"] }
      }
    };
    return Object.freeze({ component, ...(questions[component][lang] || questions[component].ru) });
  }

  function paperModel(profile) {
    const paper = profile.paper || {};
    return Object.freeze({
      component: paper.component || "P1",
      type: paper.type || "timed",
      title: paper.title || "Timed section",
      officialTime: paper.officialTime || "—",
      actualTime: paper.actualTime || "—",
      rawMark: paper.rawMark || "—",
      inTime: paper.inTime || "—",
      unattempted: paper.unattempted || "—",
      recurringErrors: paper.recurringErrors || "—",
      correction: paper.correction || "—"
    });
  }

  function mentorModel(profile, mode) {
    const service = serviceState(profile, mode);
    if (!service.mentorAssignmentActive) {
      return Object.freeze({ assigned: false, queueCount: 0, review: null });
    }
    const review = profile.mentorReview && Object.keys(profile.mentorReview).length ? profile.mentorReview : null;
    return Object.freeze({ assigned: true, queueCount: review && review.status === "pending" ? 1 : 0, review });
  }

  function buildViewModel({ profileId, mode, lang, component = "P1" }) {
    invariant(config.allowedLanguages.includes(lang), `Unsupported language: ${lang}`);
    const profile = getProfile(profileId);
    const service = serviceState(profile, mode);
    validateComponent(component);

    // The top-level preview view model remains mutable only so the UI can attach
    // ephemeral render-only fields. Every academic source object inside it is frozen.
    return {
      lang,
      profile,
      service,
      component,
      p1: profile.p1,
      p5: profile.p5,
      p1Areas: areaRows(profile, "P1", lang),
      p5Areas: areaRows(profile, "P5", lang),
      focusSkill: representativeSkill(profile, component, lang),
      weeklyTasks: weeklyTasks(profile, mode, lang),
      corrections: corrections(profile, lang),
      placementP1: placementSteps(profile, "P1"),
      placementP5: placementSteps(profile, "P5"),
      sampleQuestion: sampleQuestion(component, lang),
      paper: paperModel(profile),
      mentor: mentorModel(profile, mode),
      mentorReadinessP1: mentorReadiness(profile, "P1", mode),
      mentorReadinessP5: mentorReadiness(profile, "P5", mode),
      summary: staticData.canonicalSummary
    };
  }

  function assertAcademicParity(profileId) {
    const profile = getProfile(profileId);
    const snapshot = JSON.stringify({ p1: profile.p1, p5: profile.p5 });
    for (const mode of config.allowedServiceModes) {
      const vm = buildViewModel({ profileId, mode, lang: "en", component: "P1" });
      invariant(JSON.stringify({ p1: vm.p1, p5: vm.p5 }) === snapshot, `Academic state drift in ${mode}`);
    }
    return true;
  }

  root.engine = Object.freeze({
    t,
    getProfile,
    getComponentState,
    areaRows,
    representativeSkill,
    serviceState,
    weeklyTasks,
    corrections,
    buildViewModel,
    assertAcademicParity
  });
})();
