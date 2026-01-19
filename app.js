/* app.js — iClub v1 skeleton (plain JS)
   - 4 bottom tabs: home/courses/ratings/profile
   - Courses has internal stack navigation
   - Practice can pause/resume
   - Tour is strict (no pause)
*/

(function () {
  // ---------- Utilities ----------
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

  function nowIso() { return new Date().toISOString(); }

  // ---------- Simple Store ----------
  const store = {
    state: {
      user: null,
      subjects: [
        { id: "cs", title: "Информатика", type: "main" },
        { id: "eco", title: "Экономика", type: "main" },
        { id: "bio", title: "Биология", type: "main" },
        { id: "chem", title: "Химия", type: "main" },
        { id: "math", title: "Математика", type: "main" },

        { id: "eng", title: "English (A1–B1)", type: "additional" },
        { id: "sat", title: "SAT (English, Math)", type: "additional" },
        { id: "ielts", title: "IELTS", type: "additional" },
      ],
      userSubjects: [], // {subjectId, mode:'study'|'competitive', pinned:boolean}
      activeTab: "home",
      coursesStack: [], // stack of view names for Courses tab
      activeSubjectId: null,
      lessons: {}, // by subjectId => list
      // practice session: resumable
      practice: {
        attemptId: null,
        subjectId: null,
        inProgress: false,
        currentIndex: 0,
        answers: [], // {questionId, answer, isCorrect, timeSpent}
        startedAt: null,
        elapsedSeconds: 0,
        questions: []
      },
      // tour session: strict
      tour: {
        inProgress: false,
        subjectId: null,

