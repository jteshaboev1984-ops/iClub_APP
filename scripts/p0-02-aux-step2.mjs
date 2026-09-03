import fs from 'node:fs';
import { assert, range, replaceNamed } from './p0-02-aux-patcher.mjs';

const APP = 'app.js';
let app = fs.readFileSync(APP, 'utf8');

app = replaceNamed(app, 'startPracticePast', `async function startPracticePast() {
  const subjectKey = state.courses.subjectKey;
  const drillApi = getPracticeSafeApi()?.drill;
  if (!drillApi || !window.iclubSafeAssessment) {
    showToast(t("not_available") || "Practice is temporarily unavailable.");
    return;
  }

  const clientSessionId = window.iclubSafeAssessment.makeClientSessionId("practice_past");
  let safeStart = null, rows = [];
  showAsyncOverlay(tr3("Загружаем практику по прошедшим турам…", "O‘tgan turlar amaliyoti yuklanmoqda…", "Loading practice for past tours…"));
  try {
    safeStart = await dbWriteWithRetry(() => drillApi.startPast({ subjectKey, clientSessionId }), { tries: 3, baseDelayMs: 350 });
    rows = await dbWriteWithRetry(() => drillApi.questions(Number(safeStart?.session_id)), { tries: 3, baseDelayMs: 350 });
  } catch (error) {
    const code = practiceSafeErrorText(error);
    showToast(code.includes("practice_past_no_open_questions")
      ? (t("practice_past_done") || "Все вопросы прошлых туров уже закрыты правильно.")
      : (t("practice_past_empty") || "Для прошлых туров пока нет доступных вопросов."));
    return;
  } finally { hideAsyncOverlay(); }

  if (!safeStart?.session_id || !Array.isArray(rows) || !rows.length) {
    showToast(t("practice_past_empty") || "Для прошлых туров пока нет доступных вопросов.");
    return;
  }

  const quiz = buildPracticeSafeQuizFromRows({
    mode: "practice", drillType: "past_tours", subjectKey,
    practiceTourNo: 0, practicePoolId: null,
    safeDrillSessionId: Number(safeStart.session_id), safeDrillClientSessionId: clientSessionId,
    startedAt: Date.now(), paused: false, pauseStartedAt: null, pausedTotalMs: 0,
    index: 0, questions: [], answers: [], correct: [], timeSpent: [], qTimeLeft: 0,
    qEndsAtMono: null, qEndsAtMs: null, qTimerId: null
  }, rows);
  if (!quiz) return;
  state.quizLock = "practice"; state.quiz = quiz; saveState();
  replaceCourses("practice-quiz"); renderPracticeQuiz(); startPracticeQuestionTimer();
}`);

app = replaceNamed(app, 'updatePracticeSubmitEnabled', `function updatePracticeSubmitEnabled() {
  const quiz = state.quiz;
  const btn = $("#practice-submit-btn");
  if (!btn || !quiz || quiz.mode !== "practice") return;
  if (quiz._submitInFlight || quiz._finishing || quiz._safeFinalizeInFlight) { btn.disabled = true; return; }
  const q = quiz.questions[quiz.index];
  const ua = quiz.answers[quiz.index];
  let ok = false;
  if (q.type === "mcq") ok = ua !== null && ua !== undefined;
  else if (quiz.safeSessionId || quiz.safeDrillSessionId) ok = practiceSafeInputLooksValid(q, String(ua ?? "").trim());
  btn.disabled = !ok;
}`);

app = replaceNamed(app, 'handlePracticeSubmit', `async function handlePracticeDrillSubmitSafe(isAutoTimeout = false) {
  const quiz = state.quiz;
  if (!quiz || quiz.mode !== "practice" || !quiz.drillType || !quiz.safeDrillSessionId) return;
  if (quiz._submitInFlight || quiz._finishing) return;
  const api = getPracticeSafeApi()?.drill;
  if (!api?.submit) { showToast(t("not_available") || "Practice is temporarily unavailable."); return; }
  quiz._submitInFlight = true;
  try {
    const q = quiz.questions[quiz.index];
    const ua = quiz.answers[quiz.index];
    if (!q) throw new Error("practice_question_missing");
    if (!isAutoTimeout) {
      if (q.type === "mcq" && (ua === null || ua === undefined)) { showToast(t("select_option_required")); return; }
      if (q.type !== "mcq" && !practiceSafeInputLooksValid(q, String(ua ?? "").trim())) {
        const errEl = $("#practice-input-error");
        if (errEl) { errEl.textContent = t("invalid_answer_format"); errEl.style.display = "block"; }
        return;
      }
    }
    const allowed = Number(q.timeLimitSec) || Number(PRACTICE_CONFIG.timeByDifficulty[q.difficulty]) || 60;
    const left = Math.max(0, Number(quiz.qTimeLeft) || 0);
    const timeSpent = isAutoTimeout ? allowed : Math.max(0, Math.min(allowed, allowed - left));
    const result = await dbWriteWithRetry(() => api.submit({
      sessionId: Number(quiz.safeDrillSessionId), questionId: Number(q.id),
      userAnswer: q.type === "input" ? String(ua ?? "").trim() : "",
      pickedIndex: q.type === "mcq" && ua !== null && ua !== undefined ? Number(ua) : null,
      timeSpent
    }), { tries: 3, baseDelayMs: 350 });
    applyPracticeSafeFeedback(q, result || {});
    quiz.correct[quiz.index] = !!result?.is_correct;
    if (!Array.isArray(quiz.timeSpent)) quiz.timeSpent = new Array(quiz.questions.length).fill(0);
    quiz.timeSpent[quiz.index] = timeSpent;
    stopPracticeQuestionTimer();
    if (quiz.index + 1 >= quiz.questions.length) { quiz._submitInFlight = false; finishPractice(); return; }
    quiz.index += 1;
    const nextQ = quiz.questions[quiz.index];
    quiz.qTimeLeft = Number(nextQ?.timeLimitSec) || PRACTICE_CONFIG.timeByDifficulty[nextQ?.difficulty] || 60;
    quiz.qEndsAtMs = null; quiz.qEndsAtMono = null; saveState();
    renderPracticeQuiz(); startPracticeQuestionTimer();
  } catch (error) {
    try { trackEvent("practice_drill_safe_submit_error", { message: String(error?.message || error || "unknown"), subject_key: quiz?.subjectKey || null, drill_type: quiz?.drillType || null }); } catch {}
    showToast(t("save_failed_try_again") || "Не удалось сохранить ответ. Попробуйте ещё раз.");
  } finally {
    if (state.quiz === quiz && !quiz._finishing) { quiz._submitInFlight = false; updatePracticeSubmitEnabled(); }
  }
}

async function handlePracticeSubmit(isAutoTimeout = false) {
  const quiz = state.quiz;
  if (!quiz || quiz.mode !== "practice") return;
  if (quiz.safeSessionId && !quiz.drillType) return handlePracticeSubmitSafe(isAutoTimeout);
  if (quiz.safeDrillSessionId && quiz.drillType) return handlePracticeDrillSubmitSafe(isAutoTimeout);
  showToast(t("not_available") || "Practice is temporarily unavailable.");
}`);

assert(range(app, 'startPracticePast').text.includes('safeDrillSessionId'), 'past drill safe session missing');
assert(range(app, 'handlePracticeSubmit').text.includes('handlePracticeDrillSubmitSafe'), 'drill submit routing missing');
assert(!range(app, 'handlePracticeSubmit').text.includes('isMcqPickedIndexCorrect'), 'client MCQ correctness remains');
assert(!range(app, 'handlePracticeSubmit').text.includes('isInputAnswerCorrect'), 'client input correctness remains');
fs.writeFileSync(APP, app);
