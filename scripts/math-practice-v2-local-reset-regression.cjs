#!/usr/bin/env node
"use strict";

const fs = require("fs");
const path = require("path");
const vm = require("vm");

const ROOT = path.resolve(__dirname, "..");
const SOURCE = fs.readFileSync(
  path.join(ROOT, "security", "practice-v2-local-reset.js"),
  "utf8"
);
const MARKER = "iclub_math_practice_v2_local_reset_20261007_v1";

function assert(ok, message) {
  if (!ok) throw new Error(message);
}

function makeStorage(initial = {}) {
  const data = new Map(Object.entries(initial).map(([k, v]) => [k, String(v)]));
  return {
    get length() { return data.size; },
    key(index) { return Array.from(data.keys())[index] ?? null; },
    getItem(key) { return data.has(String(key)) ? data.get(String(key)) : null; },
    setItem(key, value) { data.set(String(key), String(value)); },
    removeItem(key) { data.delete(String(key)); },
    dump() { return Object.fromEntries(data.entries()); }
  };
}

function run(storage) {
  vm.runInNewContext(SOURCE, {
    localStorage: storage,
    console: { warn() {}, error() {}, log() {} }
  }, { filename: "practice-v2-local-reset.js" });
}

const tourContext = {
  tourId: 77,
  subjectKey: "mathematics",
  answers: [{ questionId: 9001, isCorrect: true }]
};
const tourLocalRecs = {
  bySubject: {
    mathematics: [{ source_type: "tour", topic: "Quadratics", tourNo: 2 }]
  }
};

const state = {
  tab: "courses",
  quizLock: "practice",
  quiz: {
    mode: "practice",
    subjectKey: "mathematics",
    safeSessionId: 123,
    questions: [{ id: 11 }]
  },
  practiceLastAttempt: {
    subjectKey: "mathematics",
    attemptKey: "old"
  },
  tourContext,
  courses: {
    subjectKey: "mathematics",
    stack: ["subject-hub", "practice-quiz"],
    lastTourAttemptId: 812,
    lastTourCertificateId: 913,
    activeTourNo: 3,
    activeTourId: 77,
    selectedPracticeTourNoBySubject: {
      mathematics: 3,
      economics: 2
    },
    practiceContext: "drill",
    myRecCurrent: { source_type: "practice", topic: "Old Practice" },
    myRecDrillLast: { subjectKey: "mathematics", drillType: "rec_topic" },
    myRecMistakeQids: [11, 12],
    myRecReturnTarget: "my-rec-detail"
  }
};

const storage = makeStorage({
  "practice_history_v2:mathematics:tour_1": JSON.stringify({ last: [{ id: "old" }] }),
  "practice_history_v3:mathematics:tour_2": JSON.stringify({ last: [{ id: "preview" }] }),
  "practice_history_v2:economics:tour_1": JSON.stringify({ last: [{ id: "keep" }] }),
  "iclub_practice_draft_v1": JSON.stringify({
    status: "paused",
    subjectKey: "mathematics",
    quiz: { subjectKey: "mathematics", safeSessionId: 123 }
  }),
  "iclub_my_recs_v1": JSON.stringify({
    bySubject: {
      mathematics: [{ topic: "Old Practice" }],
      economics: [{ topic: "Keep Economics" }]
    }
  }),
  "iclub_my_tour_recs_v1": JSON.stringify(tourLocalRecs),
  "iclub_state_v1": JSON.stringify(state)
});

run(storage);

let after = storage.dump();
assert(after[MARKER] === "1", "one-time reset marker missing");
assert(!after["practice_history_v2:mathematics:tour_1"], "legacy Mathematics history v2 survived");
assert(!after["practice_history_v3:mathematics:tour_2"], "pre-release Mathematics history v3 survived");
assert(!!after["practice_history_v2:economics:tour_1"], "other-subject Practice history was changed");
assert(!after["iclub_practice_draft_v1"], "legacy Mathematics paused draft survived");

const recs = JSON.parse(after["iclub_my_recs_v1"]);
assert(!Object.prototype.hasOwnProperty.call(recs.bySubject, "mathematics"), "legacy Mathematics local Practice recommendations survived");
assert(recs.bySubject.economics?.[0]?.topic === "Keep Economics", "other-subject local Practice recommendations changed");
assert(after["iclub_my_tour_recs_v1"] === JSON.stringify(tourLocalRecs), "Tour recommendation local storage changed");

const nextState = JSON.parse(after["iclub_state_v1"]);
assert(!nextState.quiz, "legacy Mathematics Practice quiz survived");
assert(nextState.quizLock === null, "legacy Mathematics Practice quiz lock survived");
assert(!nextState.practiceLastAttempt, "legacy Mathematics Practice result survived");
assert(JSON.stringify(nextState.tourContext) === JSON.stringify(tourContext), "Tour runtime context changed");
assert(nextState.courses.lastTourAttemptId === 812, "Tour attempt pointer changed");
assert(nextState.courses.lastTourCertificateId === 913, "Tour certificate pointer changed");
assert(nextState.courses.activeTourNo === 3 && nextState.courses.activeTourId === 77, "active Tour routing changed");
assert(!Object.prototype.hasOwnProperty.call(nextState.courses.selectedPracticeTourNoBySubject, "mathematics"), "old Mathematics Practice selection survived");
assert(nextState.courses.selectedPracticeTourNoBySubject.economics === 2, "other-subject Practice selection changed");
assert(JSON.stringify(nextState.courses.stack) === JSON.stringify(["subject-hub"]), "stale Mathematics Practice screen was not exited");
assert(nextState.courses.myRecCurrent === null, "stale Mathematics Practice recommendation detail survived");

// Idempotency: new v2 progress created after the marker must never be erased.
storage.setItem("practice_history_v3:mathematics:tour_1", JSON.stringify({ last: [{ id: "new-v2" }] }));
run(storage);
after = storage.dump();
assert(!!after["practice_history_v3:mathematics:tour_1"], "one-time reset erased new Mathematics v2 history");

// Tour recommendation detail is protected even when Mathematics is the active subject.
const tourDetailState = {
  quizLock: null,
  tourContext,
  courses: {
    subjectKey: "mathematics",
    stack: ["my-recs", "my-rec-detail"],
    lastTourAttemptId: 812,
    lastTourCertificateId: 913,
    myRecCurrent: { topic: "Functions", tourNo: 2 },
    selectedPracticeTourNoBySubject: { mathematics: 2 }
  }
};
const tourDetailStorage = makeStorage({
  "iclub_state_v1": JSON.stringify(tourDetailState),
  "iclub_my_tour_recs_v1": JSON.stringify(tourLocalRecs)
});
run(tourDetailStorage);
const protectedState = JSON.parse(tourDetailStorage.getItem("iclub_state_v1"));
assert(protectedState.courses.myRecCurrent?.tourNo === 2, "legacy Tour recommendation detail was cleared");
assert(JSON.stringify(protectedState.courses.stack) === JSON.stringify(["my-recs", "my-rec-detail"]), "Tour recommendation navigation changed");
assert(JSON.stringify(protectedState.tourContext) === JSON.stringify(tourContext), "Tour context changed in Tour recommendation case");
assert(tourDetailStorage.getItem("iclub_my_tour_recs_v1") === JSON.stringify(tourLocalRecs), "Tour recommendation store changed in Tour detail case");

// Non-Mathematics draft is not part of this reset.
const otherDraft = { status: "paused", subjectKey: "economics", quiz: { subjectKey: "economics" } };
const otherStorage = makeStorage({
  "iclub_practice_draft_v1": JSON.stringify(otherDraft)
});
run(otherStorage);
assert(otherStorage.getItem("iclub_practice_draft_v1") === JSON.stringify(otherDraft), "other-subject Practice draft changed");

console.log(JSON.stringify({
  ok: true,
  mathematicsLegacyHistoryCleared: true,
  mathematicsPausedDraftCleared: true,
  mathematicsPracticeRecommendationFallbackCleared: true,
  stalePracticeRuntimeCleared: true,
  otherSubjectPracticePreserved: true,
  tourRuntimePreserved: true,
  tourRecommendationsPreserved: true,
  legacyTourRecommendationDetailPreserved: true,
  oneTimeIdempotency: true
}, null, 2));
