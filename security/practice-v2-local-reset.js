(() => {
  "use strict";

  const RESET_MARKER = "iclub_math_practice_v2_local_reset_20261007_v1";
  const STATE_KEY = "iclub_state_v1";
  const DRAFT_KEY = "iclub_practice_draft_v1";
  const PRACTICE_RECS_KEY = "iclub_my_recs_v1";
  const SUBJECT_KEY = "mathematics";
  const PRACTICE_HISTORY_PREFIXES = [
    "practice_history_v2:mathematics:tour_",
    "practice_history_v3:mathematics:tour_"
  ];
  const PRACTICE_SCREENS = new Set([
    "practice-start",
    "practice-quiz",
    "practice-result",
    "practice-review",
    "practice-recs"
  ]);

  const storage = globalThis.localStorage;
  if (!storage) return;
  if (storage.getItem(RESET_MARKER) === "1") return;

  const norm = (value) => String(value || "").trim().toLowerCase();
  const parse = (raw) => {
    try {
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  };

  try {
    const historyKeys = [];
    for (let i = 0; i < storage.length; i += 1) {
      const key = storage.key(i);
      const lower = norm(key);
      if (PRACTICE_HISTORY_PREFIXES.some(prefix => lower.startsWith(prefix))) {
        historyKeys.push(key);
      }
    }
    historyKeys.forEach(key => storage.removeItem(key));

    const draft = parse(storage.getItem(DRAFT_KEY));
    const draftSubject = norm(draft?.subjectKey || draft?.quiz?.subjectKey);
    if (draftSubject === SUBJECT_KEY) {
      storage.removeItem(DRAFT_KEY);
    }

    const practiceRecs = parse(storage.getItem(PRACTICE_RECS_KEY));
    if (practiceRecs?.bySubject && typeof practiceRecs.bySubject === "object") {
      let recsChanged = false;
      Object.keys(practiceRecs.bySubject).forEach(key => {
        if (norm(key) === SUBJECT_KEY) {
          delete practiceRecs.bySubject[key];
          recsChanged = true;
        }
      });
      if (recsChanged) {
        storage.setItem(PRACTICE_RECS_KEY, JSON.stringify(practiceRecs));
      }
    }

    const savedState = parse(storage.getItem(STATE_KEY));
    if (savedState && typeof savedState === "object") {
      let stateChanged = false;
      const quizIsMathPractice =
        savedState?.quiz?.mode === "practice" &&
        norm(savedState?.quiz?.subjectKey) === SUBJECT_KEY;

      if (quizIsMathPractice) {
        delete savedState.quiz;
        savedState.quizLock = null;
        stateChanged = true;
      }

      if (norm(savedState?.practiceLastAttempt?.subjectKey) === SUBJECT_KEY) {
        delete savedState.practiceLastAttempt;
        stateChanged = true;
      }

      const courses = savedState?.courses;
      if (courses && typeof courses === "object") {
        const selections = courses.selectedPracticeTourNoBySubject;
        if (selections && typeof selections === "object") {
          Object.keys(selections).forEach(key => {
            if (norm(key) === SUBJECT_KEY) {
              delete selections[key];
              stateChanged = true;
            }
          });
        }

        const activeSubjectIsMath = norm(courses.subjectKey) === SUBJECT_KEY;
        if (activeSubjectIsMath) {
          const currentRecIsTour = norm(courses?.myRecCurrent?.source_type) === "tour";
          const stalePracticeRec = !!courses?.myRecCurrent && !currentRecIsTour;

          for (const key of [
            "practiceContext",
            "myRecDrillLast",
            "myRecMistakeQids",
            "myRecReturnTarget"
          ]) {
            if (Object.prototype.hasOwnProperty.call(courses, key)) {
              delete courses[key];
              stateChanged = true;
            }
          }

          if (stalePracticeRec) {
            courses.myRecCurrent = null;
            stateChanged = true;
          }

          const stack = Array.isArray(courses.stack) ? courses.stack : [];
          const top = stack.length ? stack[stack.length - 1] : "";
          if (
            PRACTICE_SCREENS.has(top) ||
            (top === "my-rec-detail" && stalePracticeRec)
          ) {
            courses.stack = ["subject-hub"];
            stateChanged = true;
          }
        }
      }

      if (stateChanged) {
        storage.setItem(STATE_KEY, JSON.stringify(savedState));
      }
    }

    storage.setItem(RESET_MARKER, "1");
  } catch {
    // Fail closed for the marker: retry cleanup on the next app load.
  }
})();
