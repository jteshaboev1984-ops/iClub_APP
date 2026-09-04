(() => {
  "use strict";

  const root = (window.iClubExamPrepPreview = window.iClubExamPrepPreview || {});
  const config = root.config;

  function invariant(condition, message) {
    if (!condition) throw new Error(`[Exam Prep preview] ${message}`);
  }

  function clampNumber(value, min, max, fallback = min) {
    const n = Number(value);
    if (!Number.isFinite(n)) return fallback;
    return Math.min(max, Math.max(min, n));
  }

  function validateComponent(component) {
    invariant(config.allowedComponents.includes(component), `Unsupported component: ${component}`);
    return component;
  }

  function validateStage(stage) {
    return Math.round(clampNumber(stage, 0, config.stageCount - 1, 0));
  }

  function validateCoverage(coverage) {
    return Math.round(clampNumber(coverage, 0, 100, 0));
  }

  function validateServiceMode(mode) {
    invariant(config.allowedServiceModes.includes(mode), `Unsupported service mode: ${mode}`);
    return mode;
  }

  function normalizeComponentState(input) {
    const state = input || {};
    return Object.freeze({
      component: validateComponent(state.component),
      stage: validateStage(state.stage),
      coverage: validateCoverage(state.coverage),
      evidenceLabel: String(state.evidenceLabel || "—"),
      nextAction: String(state.nextAction || "—"),
      readiness: String(state.readiness || "insufficient"),
      placement: String(state.placement || "pending"),
      confidence: Math.round(clampNumber(state.confidence, 0, 100, 0)),
      delayedRetest: String(state.delayedRetest || "—"),
      writtenStatus: String(state.writtenStatus || "unverified")
    });
  }

  function normalizeProfile(input) {
    invariant(input && input.id, "Profile id is required");
    invariant(input.p1 && input.p5, "Profile must contain separate P1 and P5 state");
    return Object.freeze({
      id: String(input.id),
      labels: Object.freeze({ ...(input.labels || {}) }),
      description: Object.freeze({ ...(input.description || {}) }),
      recommendedMode: validateServiceMode(input.recommendedMode || "core"),
      flags: Object.freeze([...(input.flags || [])]),
      p1: normalizeComponentState({ ...input.p1, component: "P1" }),
      p5: normalizeComponentState({ ...input.p5, component: "P5" }),
      weeklyBudget: String(input.weeklyBudget || "4 h"),
      totalStudyHours: String(input.totalStudyHours || "10 h"),
      studied: String(input.studied || "—"),
      paperHistory: String(input.paperHistory || "—"),
      weeklyTasks: Object.freeze((input.weeklyTasks || []).map((task, index) => Object.freeze({
        id: String(task.id || `task-${index + 1}`),
        component: validateComponent(task.component),
        title: Object.freeze({ ...(task.title || {}) }),
        minutes: Math.round(clampNumber(task.minutes, 5, 240, 30)),
        status: String(task.status || "open"),
        priority: Math.round(clampNumber(task.priority, 1, 3, 3)),
        due: String(task.due || "—"),
        aiReason: Object.freeze({ ...(task.aiReason || {}) })
      }))),
      corrections: Object.freeze((input.corrections || []).map((item, index) => Object.freeze({
        id: String(item.id || `correction-${index + 1}`),
        component: validateComponent(item.component),
        skill: String(item.skill || "—"),
        cause: Object.freeze({ ...(item.cause || {}) }),
        action: Object.freeze({ ...(item.action || {}) }),
        status: String(item.status || "open"),
        due: String(item.due || "—")
      }))),
      paper: Object.freeze({ ...(input.paper || {}) }),
      mentorReview: Object.freeze({ ...(input.mentorReview || {}) })
    });
  }

  function assertPreviewIsolation() {
    invariant(config.previewOnly === true, "Preview-only flag must be true");
    invariant(config.liveApiEnabled === false, "Live API must be disabled in P0-01");
    invariant(config.featureDefault === "off", "Feature default must be OFF");
    return true;
  }

  root.contracts = Object.freeze({
    invariant,
    validateComponent,
    validateStage,
    validateCoverage,
    validateServiceMode,
    normalizeComponentState,
    normalizeProfile,
    assertPreviewIsolation
  });
})();
