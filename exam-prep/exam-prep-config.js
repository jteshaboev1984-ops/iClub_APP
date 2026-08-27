(() => {
  "use strict";

  const NS = "iClubExamPrepPreview";
  const root = (window[NS] = window[NS] || {});

  root.config = Object.freeze({
    previewOnly: true,
    liveApiEnabled: false,
    featureDefault: "off",
    subjectId: 5,
    subjectKey: "mathematics",
    syllabusCode: "9709",
    syllabusVersion: "2026-2027",
    canonicalMapVersion: "iclub_math_p1p5:v1.0",
    componentCounts: Object.freeze({ P1: 45, P5: 36 }),
    stageCount: 7,
    allowedComponents: Object.freeze(["P1", "P5"]),
    allowedLanguages: Object.freeze(["ru", "uz", "en"]),
    allowedServiceModes: Object.freeze(["core", "ai", "mentor"]),
    previewStoragePrefix: "iclub_exam_prep_preview_",
    legacyStorageKeysForbidden: Object.freeze([
      "iclub_state_v1",
      "iclub_profile_v1",
      "iclub_practice_draft_v1",
      "iclub_pending_ops_v1"
    ]),
    routes: Object.freeze([
      "overview",
      "exam-profile",
      "placement-hub",
      "placement-run",
      "placement-result",
      "syllabus-tracker",
      "skill-detail",
      "weekly-plan",
      "correction-queue",
      "timed-paper-hub",
      "paper-result",
      "mentor-review"
    ])
  });
})();
