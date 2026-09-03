import fs from 'node:fs';
import { assert, range, replaceNamed } from './p0-02-aux-patcher.mjs';

const APP = 'app.js';
let app = fs.readFileSync(APP, 'utf8');

app = replaceNamed(app, 'fetchRecentMistakesByRec', `async function fetchRecentMistakesByRec(subjectKey, rec) {
  try {
    const api = getPracticeSafeApi();
    if (!api?.recentMistakes) return [];
    const rows = await api.recentMistakes({ subjectKey, topic: rec?.topic || null, subtopic: rec?.subtopic || null, limit: 10 });
    return (Array.isArray(rows) ? rows : []).map(row => ({
      attempt_id: Number(row?.attempt_id || 0) || null,
      question_id: Number(row?.question_id || 0) || null,
      user_answer: String(row?.user_answer ?? ""), is_correct: !!row?.is_correct,
      time_spent: Number(row?.time_spent || 0), created_at: row?.created_at || null,
      q: {
        id: Number(row?.question_id || 0), topic: row?.topic || null, subtopic: row?.subtopic || null,
        difficulty: row?.difficulty || "medium", qtype: row?.qtype || "mcq",
        question_text: row?.question_text || null, question_text_ru: row?.question_text_ru || null,
        question_text_uz: row?.question_text_uz || null, question_text_en: row?.question_text_en || null,
        options_text: row?.options_text || null, options_text_ru: row?.options_text_ru || null,
        options_text_uz: row?.options_text_uz || null, options_text_en: row?.options_text_en || null,
        correct_answer: row?.correct_answer || null,
        explanation: row?.explanation || null, explanation_ru: row?.explanation_ru || null,
        explanation_uz: row?.explanation_uz || null, explanation_en: row?.explanation_en || null,
        image_url: row?.image_url || null, book_ref: row?.book_ref || null
      }
    })).filter(x => Number(x?.q?.id || 0) > 0);
  } catch (e) {
    logClientError("myrec_mistakes_safe_exception", e);
    return [];
  }
}`);

app = replaceNamed(app, 'buildPracticeSetByRec', `async function buildPracticeSetByRec(subjectKey, rec) {
  void subjectKey; void rec;
  return [];
}`);

app = replaceNamed(app, 'startPracticeByRec', `async function startPracticeByRec() {
  const rec = state?.courses?.myRecCurrent;
  const subjectKey = state?.courses?.subjectKey;
  if (!rec || !subjectKey) return;
  const api = getPracticeSafeApi()?.drill;
  if (!api || !window.iclubSafeAssessment) { showToast(t("not_available") || "Practice is temporarily unavailable."); return; }
  const clientSessionId = window.iclubSafeAssessment.makeClientSessionId("practice_topic");
  let started = null, rows = [];
  showAsyncOverlay(tr3("Загружаем практику по теме…", "Mavzu bo‘yicha amaliyot yuklanmoqda…", "Loading topic practice…"));
  try {
    started = await dbWriteWithRetry(() => api.startTopic({ subjectKey, topic: rec.topic, subtopic: rec.subtopic || null, clientSessionId }), { tries: 3, baseDelayMs: 350 });
    rows = await dbWriteWithRetry(() => api.questions(Number(started?.session_id)), { tries: 3, baseDelayMs: 350 });
  } catch { showToast(t("rec_practice_empty") || t("practice_no_questions") || "Нет вопросов для практики по этой теме."); return; }
  finally { hideAsyncOverlay(); }
  if (!started?.session_id || !Array.isArray(rows) || !rows.length) return;
  const quiz = buildPracticeSafeQuizFromRows({
    mode: "practice", subjectKey, practiceTourNo: 0, practicePoolId: null,
    safeDrillSessionId: Number(started.session_id), safeDrillClientSessionId: clientSessionId,
    startedAt: Date.now(), paused: false, pauseStartedAt: null, pausedTotalMs: 0,
    index: 0, questions: [], answers: [], correct: [], timeSpent: [], qTimeLeft: 0,
    qEndsAtMono: null, qEndsAtMs: null, qTimerId: null,
    recTopic: rec.topic || null, recSubtopic: rec.subtopic || null, drillType: "rec_topic"
  }, rows);
  if (!quiz) return;
  if (!state.courses) state.courses = {};
  state.courses.myRecReturnTarget = "my-rec-detail";
  state.quizLock = "practice"; state.quiz = quiz; saveState();
  pushCourses("practice-quiz"); renderPracticeQuiz(); startPracticeQuestionTimer();
}`);

app = replaceNamed(app, 'startPracticeRetryMistakes', `async function startPracticeRetryMistakes() {
  const rec = state?.courses?.myRecCurrent;
  const subjectKey = state?.courses?.subjectKey;
  const qids = Array.isArray(state?.courses?.myRecMistakeQids) ? state.courses.myRecMistakeQids.slice(0, 10) : [];
  if (!rec || !subjectKey) return;
  if (!qids.length) { showToast(t("rec_retry_empty") || "Нет ошибок для повтора."); return; }
  const api = getPracticeSafeApi()?.drill;
  if (!api || !window.iclubSafeAssessment) { showToast(t("not_available") || "Practice is temporarily unavailable."); return; }
  const clientSessionId = window.iclubSafeAssessment.makeClientSessionId("practice_mistakes");
  let started = null, rows = [];
  showAsyncOverlay(tr3("Загружаем ошибки для повтора…", "Xatolarni takrorlash yuklanmoqda…", "Loading mistakes to retry…"));
  try {
    started = await dbWriteWithRetry(() => api.startMistakes({ subjectKey, questionIds: qids, clientSessionId }), { tries: 3, baseDelayMs: 350 });
    rows = await dbWriteWithRetry(() => api.questions(Number(started?.session_id)), { tries: 3, baseDelayMs: 350 });
  } catch { showToast(t("rec_retry_empty") || "Нет доступных ошибок для повтора."); return; }
  finally { hideAsyncOverlay(); }
  if (!started?.session_id || !Array.isArray(rows) || !rows.length) return;
  const quiz = buildPracticeSafeQuizFromRows({
    mode: "practice", subjectKey, practiceTourNo: 0, practicePoolId: null,
    safeDrillSessionId: Number(started.session_id), safeDrillClientSessionId: clientSessionId,
    startedAt: Date.now(), paused: false, pauseStartedAt: null, pausedTotalMs: 0,
    index: 0, questions: [], answers: [], correct: [], timeSpent: [], qTimeLeft: 0,
    qEndsAtMono: null, qEndsAtMs: null, qTimerId: null,
    recTopic: rec.topic || null, recSubtopic: rec.subtopic || null, drillType: "rec_mistakes"
  }, rows);
  if (!quiz) return;
  if (!state.courses) state.courses = {};
  state.courses.myRecReturnTarget = "my-rec-detail";
  state.quizLock = "practice"; state.quiz = quiz; saveState();
  pushCourses("practice-quiz"); renderPracticeQuiz(); startPracticeQuestionTimer();
}`);

assert(!range(app, 'fetchRecentMistakesByRec').text.includes('.from("practice_answers")'), 'recommendations still read practice_answers directly');
assert(!range(app, 'buildPracticeSetByRec').text.includes('correct_answer'), 'topic builder still carries answer key');
assert(range(app, 'startPracticeByRec').text.includes('safeDrillSessionId'), 'topic drill safe session missing');
assert(range(app, 'startPracticeRetryMistakes').text.includes('startMistakes'), 'mistake drill safe start missing');
fs.writeFileSync(APP, app);
