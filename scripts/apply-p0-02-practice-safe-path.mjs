import fs from 'node:fs';

const APP = 'app.js';
const INDEX = 'index.html';
let app = fs.readFileSync(APP, 'utf8');
let html = fs.readFileSync(INDEX, 'utf8');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function count(haystack, needle) {
  return haystack.split(needle).length - 1;
}

function replaceOnce(source, needle, replacement, label) {
  const n = count(source, needle);
  assert(n === 1, `${label}: expected exactly 1 anchor, found ${n}`);
  return source.replace(needle, replacement);
}

function replaceFunctionUntil(source, functionStartNeedle, nextFunctionRegex, replacement, label) {
  const start = source.indexOf(functionStartNeedle);
  assert(start >= 0, `${label}: function start not found`);
  assert(source.indexOf(functionStartNeedle, start + 1) < 0, `${label}: duplicate function start`);
  const tail = source.slice(start + functionStartNeedle.length);
  const match = tail.match(nextFunctionRegex);
  assert(match && typeof match.index === 'number', `${label}: next function anchor not found`);
  const end = start + functionStartNeedle.length + match.index;
  return source.slice(0, start) + replacement.trimEnd() + '\n\n' + source.slice(end).replace(/^\s*\n/, '');
}

const SAFE_HELPERS_MARKER = '// P0-02 SAFE PRACTICE FRONTEND HELPERS';
assert(!app.includes(SAFE_HELPERS_MARKER), 'safe Practice helpers already applied');

const helperBlock = String.raw`
  // P0-02 SAFE PRACTICE FRONTEND HELPERS
  function getPracticeSafeApi() {
    return window.iclubSafeAssessment?.practice || null;
  }

  function practiceSafeErrorText(error) {
    return [error?.message, error?.details, error?.hint, error?.code]
      .filter(Boolean)
      .map(String)
      .join(' | ')
      .toLowerCase();
  }

  function practiceSafeCorrectIndex(correctAnswer, options) {
    const raw = String(correctAnswer ?? '').trim();
    const opts = Array.isArray(options) ? options : [];
    if (!raw) return null;
    if (/^[A-Z]$/i.test(raw)) {
      const idx = raw.toUpperCase().charCodeAt(0) - 65;
      return idx >= 0 && idx < opts.length ? idx : null;
    }
    if (/^\d+$/.test(raw)) {
      const idx = Number(raw);
      return idx >= 0 && idx < opts.length ? idx : null;
    }
    const idx = opts.findIndex(x => String(x).trim().toLowerCase() === raw.toLowerCase());
    return idx >= 0 ? idx : null;
  }

  function practiceSafeInputHint(inputKind) {
    if (inputKind === 'numeric') {
      return tr3('Введите число', 'Son kiriting', 'Enter a number');
    }
    if (inputKind === 'token') {
      return tr3('Введите краткий ответ', 'Qisqa javobni kiriting', 'Enter a short answer');
    }
    return tr3('Введите ответ', 'Javobni kiriting', 'Enter answer');
  }

  function practiceSafeInputLooksValid(q, value) {
    const raw = String(value ?? '').trim();
    if (!raw) return false;
    if (q?.inputKind === 'numeric') {
      return /^[+-]?(?:\d+(?:[.,]\d+)?|[.,]\d+)(?:[eE][+-]?\d+)?$/.test(raw);
    }
    if (q?.inputKind === 'token') {
      return /^[A-Za-z][A-Za-z0-9]*$/.test(raw);
    }
    return raw.length <= 500;
  }

  function applyPracticeSafeFeedback(q, row) {
    if (!q || !row) return q;
    const correctAnswer = row.correct_answer == null ? '' : String(row.correct_answer).trim();
    q.correctAnswer = correctAnswer;
    q.explanation = pickContentText(row, 'explanation') || '';
    if (q.type === 'mcq') {
      q.correctIndex = practiceSafeCorrectIndex(correctAnswer, q.options || []);
    }
    return q;
  }

  function mapPracticeSafeRow(row, context = {}) {
    const type = String(row?.qtype || 'mcq').toLowerCase() === 'input' ? 'input' : 'mcq';
    const optionsRaw = pickContentText(row || {}, 'options_text') || '';
    const options = type === 'mcq' ? (parseOptionsText(optionsRaw) || []) : [];
    const inputKind = type === 'input' ? String(row?.input_kind || 'text').toLowerCase() : null;
    const q = {
      id: Number(row?.id || 0),
      topic: row?.topic || (t('topic_general') || 'General'),
      subtopic: row?.subtopic || null,
      difficulty: normalizeDifficulty(row?.difficulty || 'medium'),
      type,
      question: pickContentText(row || {}, 'question_text') || '',
      options,
      imageUrl: row?.image_url || null,
      image_url: row?.image_url || null,
      timeLimitSec: Number(row?.time_limit_sec || 0) || null,
      practiceTourNo: Number(context?.practiceTourNo || 1),
      practicePoolId: Number(context?.practicePoolId || 0) || null,
      book_ref: String(row?.book_ref || '').trim() || null,
      book_reference: String(row?.book_ref || '').trim() || null,
      inputKind,
      inputHint: type === 'input' ? practiceSafeInputHint(inputKind) : ''
    };
    if (row?.was_answered) applyPracticeSafeFeedback(q, row);
    return q;
  }

  function buildPracticeSafeQuizFromRows(baseQuiz, rows) {
    const sorted = (Array.isArray(rows) ? rows.slice() : [])
      .sort((a, b) => Number(a?.order_no || 0) - Number(b?.order_no || 0));
    if (!sorted.length) return null;

    const context = {
      practiceTourNo: Number(baseQuiz?.practiceTourNo || 1),
      practicePoolId: Number(baseQuiz?.practicePoolId || 0) || null
    };
    const questions = sorted.map(row => mapPracticeSafeRow(row, context));
    const answers = sorted.map(row => {
      if (!row?.was_answered) return null;
      const type = String(row?.qtype || 'mcq').toLowerCase() === 'input' ? 'input' : 'mcq';
      return type === 'mcq' ? (row?.saved_picked_index ?? null) : String(row?.saved_user_answer ?? '');
    });
    const correct = sorted.map(row => row?.was_answered ? !!row?.saved_is_correct : false);
    const timeSpent = sorted.map(row => row?.was_answered ? Math.max(0, Number(row?.saved_time_spent || 0)) : 0);
    let index = sorted.findIndex(row => !row?.was_answered);
    if (index < 0) index = Math.max(0, sorted.length - 1);

    const previousIndex = Number(baseQuiz?.index || 0);
    const nextQ = questions[index];
    const allowed = Number(nextQ?.timeLimitSec) || Number(PRACTICE_CONFIG.timeByDifficulty[nextQ?.difficulty]) || 60;
    const keepCurrentTimer = previousIndex === index && Number(baseQuiz?.qTimeLeft || 0) > 0;

    return {
      ...baseQuiz,
      questions,
      answers,
      correct,
      timeSpent,
      index,
      qTimeLeft: keepCurrentTimer ? Number(baseQuiz.qTimeLeft) : allowed,
      qEndsAtMono: null,
      qEndsAtMs: null,
      qTimerId: null
    };
  }

  function practiceSafeReviewRowsToDetails(rows) {
    return (Array.isArray(rows) ? rows : []).map((row, idx) => {
      const type = String(row?.qtype || 'mcq').toLowerCase() === 'input' ? 'input' : 'mcq';
      const options = type === 'mcq' ? (parseOptionsText(pickContentText(row || {}, 'options_text') || '') || []) : [];
      return {
        id: Number(row?.question_id || idx + 1),
        topic: row?.topic || (t('topic_general') || 'General'),
        subtopic: row?.subtopic || null,
        difficulty: row?.difficulty || 'medium',
        type,
        question: pickContentText(row || {}, 'question_text') || '',
        options,
        userAnswer: String(row?.user_answer ?? ''),
        correctAnswer: String(row?.correct_answer ?? ''),
        explanation: pickContentText(row || {}, 'explanation') || '',
        isCorrect: !!row?.is_correct,
        timeSpent: Math.max(0, Number(row?.time_spent || 0)),
        book_ref: String(row?.book_ref || '').trim() || null,
        book_reference: String(row?.book_ref || '').trim() || null
      };
    });
  }

  async function handlePracticeSubmitSafe(isAutoTimeout = false) {
    const quiz = state.quiz;
    if (!quiz || quiz.mode !== 'practice' || !quiz.safeSessionId || quiz.drillType) return;
    if (quiz._submitInFlight || quiz._finishing || quiz._safeFinalizeInFlight) return;

    const api = getPracticeSafeApi();
    if (!api) {
      showToast(t('not_available') || 'Practice is temporarily unavailable.');
      return;
    }

    quiz._submitInFlight = true;
    const submitBtn = $('#practice-submit-btn');
    if (submitBtn) submitBtn.disabled = true;

    try {
      const q = quiz.questions[quiz.index];
      if (!q) return;
      const userAns = quiz.answers[quiz.index];

      if (!isAutoTimeout) {
        if (q.type === 'mcq') {
          if (userAns === null || userAns === undefined) {
            showToast(t('select_option_required'));
            return;
          }
        } else if (!practiceSafeInputLooksValid(q, userAns)) {
          const errEl = $('#practice-input-error');
          if (errEl) {
            errEl.textContent = t('invalid_answer_format');
            errEl.style.display = 'block';
          } else {
            showToast(t('invalid_answer_format'));
          }
          return;
        }
      }

      const allowed = Number(q.timeLimitSec) || Number(PRACTICE_CONFIG.timeByDifficulty[q.difficulty]) || 60;
      const left = Number(quiz.qTimeLeft) || 0;
      const spent = Math.max(0, Math.min(allowed, allowed - left));
      if (!Array.isArray(quiz.timeSpent)) quiz.timeSpent = new Array(quiz.questions.length).fill(0);
      quiz.timeSpent[quiz.index] = spent;

      stopPracticeQuestionTimer();

      const result = await dbWriteWithRetry(() => api.submit({
        sessionId: Number(quiz.safeSessionId),
        questionId: Number(q.id),
        userAnswer: q.type === 'input' ? String(userAns ?? '').trim() : '',
        pickedIndex: q.type === 'mcq' ? (userAns ?? null) : null,
        timeSpent: spent
      }), { tries: 3, baseDelayMs: 350 });

      quiz.correct[quiz.index] = !!result?.is_correct;
      applyPracticeSafeFeedback(q, result || {});

      if (isAutoTimeout) {
        showToast(userAns ? t('toast_time_expired_answer_saved') : t('toast_time_expired_no_answer'));
      }

      const nextIndex = quiz.index + 1;
      if (nextIndex >= quiz.questions.length) {
        quiz._submitInFlight = false;
        finishPractice();
        return;
      }

      quiz.index = nextIndex;
      const nextQ = quiz.questions[quiz.index];
      quiz.qTimeLeft = Number(nextQ?.timeLimitSec) || Number(PRACTICE_CONFIG.timeByDifficulty[nextQ?.difficulty]) || 60;
      quiz.qEndsAtMono = null;
      quiz.qEndsAtMs = null;
      saveState();
      renderPracticeQuiz();
      startPracticeQuestionTimer();
    } catch (error) {
      try {
        trackEvent('practice_safe_submit_error', {
          message: String(error?.message || error || 'unknown'),
          subject_key: quiz?.subjectKey || null,
          safe_session_id: quiz?.safeSessionId || null,
          index: Number(quiz?.index || 0)
        });
      } catch {}
      quiz._submitInFlight = false;
      showToast(tr3(
        'Не удалось подтвердить ответ. Практика поставлена на паузу — прогресс не потерян.',
        'Javobni tasdiqlab bo‘lmadi. Amaliyot pauzaga qo‘yildi — progress saqlandi.',
        'The answer could not be confirmed. Practice was paused and your progress is safe.'
      ));
      handlePracticePause();
      return;
    } finally {
      if (state.quiz === quiz && !quiz._finishing) {
        quiz._submitInFlight = false;
        updatePracticeSubmitEnabled();
      }
    }
  }

  async function finishPracticeSafe(quiz) {
    if (!quiz || !quiz.safeSessionId || quiz.drillType || quiz._safeFinalizeInFlight || quiz._safeFinalizeComplete) return;
    const api = getPracticeSafeApi();
    if (!api) {
      showToast(t('not_available') || 'Practice is temporarily unavailable.');
      return;
    }

    quiz._safeFinalizeInFlight = true;
    stopPracticeQuestionTimer();
    showAsyncOverlay(tr3('Сохраняем результат…', 'Natija saqlanmoqda…', 'Saving result…'));

    try {
      const finishedAt = Date.now();
      const startedAt = quiz.startedAt || finishedAt;
      const durationMs = Math.max(0, finishedAt - startedAt - (quiz.pausedTotalMs || 0));
      const durationSec = Math.round(durationMs / 1000);

      const finalResult = await dbWriteWithRetry(() => api.finalize({
        sessionId: Number(quiz.safeSessionId),
        totalTime: durationSec
      }), { tries: 3, baseDelayMs: 450 });

      let reviewRows = [];
      try {
        reviewRows = await dbWriteWithRetry(() => api.review(Number(finalResult?.attempt_id)), { tries: 3, baseDelayMs: 350 });
      } catch {}

      if (Array.isArray(reviewRows) && reviewRows.length) {
        const byId = new Map(reviewRows.map(row => [Number(row?.question_id), row]));
        quiz.questions = quiz.questions.map(q => {
          const row = byId.get(Number(q?.id));
          if (row) applyPracticeSafeFeedback(q, row);
          return q;
        });
        quiz.correct = quiz.questions.map(q => !!byId.get(Number(q?.id))?.is_correct);
        quiz.timeSpent = quiz.questions.map(q => Math.max(0, Number(byId.get(Number(q?.id))?.time_spent || 0)));
      }

      quiz.safePersistedResult = {
        ok: true,
        reason: 'safe_v4',
        attemptId: Number(finalResult?.attempt_id || 0) || null,
        score: Number(finalResult?.score || 0),
        percent: Number(finalResult?.percent || 0),
        questionCount: Number(finalResult?.question_count || quiz.questions.length || 0)
      };
      quiz._safeFinalizeComplete = true;
      quiz._safeFinalizeInFlight = false;
      state.quiz = quiz;
      saveState();
      hideAsyncOverlay();
      finishPractice();
    } catch (error) {
      quiz._safeFinalizeInFlight = false;
      hideAsyncOverlay();
      try {
        trackEvent('practice_safe_finalize_error', {
          message: String(error?.message || error || 'unknown'),
          subject_key: quiz?.subjectKey || null,
          safe_session_id: quiz?.safeSessionId || null
        });
      } catch {}
      showToast(tr3(
        'Не удалось сохранить результат. Практика поставлена на паузу — ответы уже защищены на сервере.',
        'Natijani saqlab bo‘lmadi. Amaliyot pauzaga qo‘yildi — javoblar serverda saqlangan.',
        'The result could not be finalized. Practice was paused; your confirmed answers are safe on the server.'
      ));
      handlePracticePause();
    }
  }
`;

app = replaceOnce(
  app,
  '  async function restorePracticeQuizSecrets(quiz) {',
  `${helperBlock}\n\n  async function restorePracticeQuizSecrets(quiz) {\n    if (quiz?.safeSessionId && !quiz?.drillType) {\n      try {\n        const api = getPracticeSafeApi();\n        if (!api) return null;\n        const rows = await api.questions(Number(quiz.safeSessionId));\n        return buildPracticeSafeQuizFromRows(quiz, rows);\n      } catch {\n        return null;\n      }\n    }`,
  'inject safe Practice helpers/resume branch'
);

const safeStartPractice = String.raw`
async function startPracticeNew() {
  const subjectKey = state.courses.subjectKey;
  const api = getPracticeSafeApi();
  if (!api || !window.iclubSafeAssessment) {
    showToast(t('not_available') || 'Practice is temporarily unavailable.');
    return;
  }

  let stageCtx = null;
  let rows = [];
  let safeStart = null;
  const clientSessionId = window.iclubSafeAssessment.makeClientSessionId('practice');

  showAsyncOverlay(tr3(
    'Загружаем вопросы практики…',
    'Amaliyot savollari yuklanmoqda…',
    'Loading practice questions…'
  ));

  try {
    stageCtx = await getPracticeStageContext(subjectKey);
    const picker = await getPracticeTourCards(subjectKey);
    const selectedTourNo = Number(picker?.selectedTourNo || stageCtx?.practiceTourNo || 1);
    const selectedCard = (Array.isArray(picker?.cards) ? picker.cards : []).find(
      c => Number(c?.tourNo || 0) === selectedTourNo
    );

    if (selectedCard?.isLocked) {
      showToast(t('practice_tour_locked') || tr3(
        'Эта практика откроется вместе с соответствующим туром.',
        'Bu amaliyot tegishli tur bilan birga ochiladi.',
        'This practice opens with the corresponding tour.'
      ));
      return;
    }

    const selectedStats = await computePracticeStageStats(subjectKey, selectedTourNo);
    stageCtx = {
      ...stageCtx,
      poolId: Number(selectedStats?.poolId || 0) || null,
      practiceTourNo: Number(selectedStats?.practiceTourNo || selectedTourNo || 1)
    };

    if (!stageCtx?.poolId) {
      showToast(t('practice_stage_not_ready') || 'Практика для этого этапа пока не опубликована.');
      return;
    }

    safeStart = await dbWriteWithRetry(() => api.start({
      poolId: Number(stageCtx.poolId),
      clientSessionId
    }), { tries: 3, baseDelayMs: 350 });

    rows = await dbWriteWithRetry(() => api.questions(Number(safeStart?.session_id)), { tries: 3, baseDelayMs: 350 });
  } catch (error) {
    const code = practiceSafeErrorText(error);
    if (code.includes('practice_no_open_questions')) {
      showToast(t('practice_stage_all_closed') || 'Все вопросы этого этапа уже закрыты.');
    } else if (code.includes('practice_pool_locked') || code.includes('practice_pool_not_published')) {
      showToast(t('practice_tour_locked') || 'Эта практика пока закрыта.');
    } else {
      showToast(t('save_failed_try_again') || 'Не удалось загрузить практику. Попробуйте ещё раз.');
    }
    try { trackEvent('practice_safe_start_error', { message: String(error?.message || error || 'unknown'), subject_key: subjectKey }); } catch {}
    return;
  } finally {
    hideAsyncOverlay();
  }

  if (!Array.isArray(rows) || !rows.length || !safeStart?.session_id) {
    showToast(t('practice_no_questions') || 'Нет вопросов для практики по этому предмету.');
    return;
  }

  const baseQuiz = {
    mode: 'practice',
    subjectKey,
    practiceTourNo: Number(stageCtx?.practiceTourNo || 1),
    practicePoolId: Number(stageCtx?.poolId || 0) || null,
    safeSessionId: Number(safeStart.session_id),
    safeClientSessionId: clientSessionId,
    startedAt: Date.now(),
    paused: false,
    pauseStartedAt: null,
    pausedTotalMs: 0,
    index: 0,
    questions: [],
    answers: [],
    correct: [],
    timeSpent: [],
    qTimeLeft: 60,
    qEndsAtMono: null,
    qEndsAtMs: null,
    qTimerId: null
  };

  const quiz = buildPracticeSafeQuizFromRows(baseQuiz, rows);
  if (!quiz) {
    showToast(t('practice_no_questions') || 'Нет вопросов для практики по этому предмету.');
    return;
  }

  try {
    trackEvent('practice_attempt_started', {
      subject_id: normSubjectId(subjectKey),
      subject_key: String(subjectKey || ''),
      practice_tour_no: Number(stageCtx?.practiceTourNo || 1),
      practice_pool_id: Number(stageCtx?.poolId || 0) || null,
      questions_total: quiz.questions.length,
      source: 'subject_hub_safe_v4'
    });
  } catch {}

  state.quizLock = 'practice';
  state.quiz = quiz;
  saveState();
  replaceCourses('practice-quiz');
  renderPracticeQuiz();
  startPracticeQuestionTimer();
}
`;

app = replaceFunctionUntil(
  app,
  'async function startPracticeNew() {',
  /\n\s*async function startPracticePast\(\)\s*\{/,
  safeStartPractice,
  'replace startPracticeNew'
);

app = replaceOnce(
  app,
  '  if (quiz._submitInFlight || quiz._finishing) return;\n\n  quiz._submitInFlight = true;',
  `  if (quiz._submitInFlight || quiz._finishing) return;\n\n  if (quiz.safeSessionId && !quiz.drillType) {\n    return handlePracticeSubmitSafe(isAutoTimeout);\n  }\n\n  quiz._submitInFlight = true;`,
  'route main Practice submit to safe v4'
);

app = replaceOnce(
  app,
  '  if (!quiz || quiz.mode !== "practice") return;\n  if (quiz._finishing) return;\n\n  quiz._finishing = true;',
  `  if (!quiz || quiz.mode !== "practice") return;\n\n  if (quiz.safeSessionId && !quiz.drillType && !quiz._safeFinalizeComplete) {\n    finishPracticeSafe(quiz).catch(() => null);\n    return;\n  }\n\n  if (quiz._finishing) return;\n\n  quiz._finishing = true;`,
  'route main Practice finalize to safe v4'
);

app = replaceOnce(
  app,
  '      res = await savePracticeAttemptToSupabase(attempt, quiz);',
  `      if (quiz?.safePersistedResult?.ok) {\n        res = {\n          ok: true,\n          reason: 'safe_v4',\n          attemptId: Number(quiz.safePersistedResult.attemptId || 0) || null,\n          subjectId: null,\n          score: Number(quiz.safePersistedResult.score || 0),\n          percent: Number(quiz.safePersistedResult.percent || 0)\n        };\n      } else {\n        res = await savePracticeAttemptToSupabase(attempt, quiz);\n      }`,
  'avoid duplicate legacy Practice save after safe finalize'
);

const reviewAnchor = `    try {\n      const uid = await getAuthUid();\n      if (!uid) {`;
assert(count(app, reviewAnchor) >= 1, 'Practice review async anchor not found');
const renderReviewStart = app.indexOf('function renderPracticeReview');
const renderReviewEnd = app.indexOf('function syncPracticeResultBadges', renderReviewStart);
assert(renderReviewStart >= 0 && renderReviewEnd > renderReviewStart, 'Practice review function bounds not found');
const reviewBlock = app.slice(renderReviewStart, renderReviewEnd);
assert(count(reviewBlock, reviewAnchor) === 1, 'Practice review anchor must be unique inside renderPracticeReview');
const safeReviewInjection = `    try {\n      const safeApi = getPracticeSafeApi();\n      if (safeApi && dbAttemptId) {\n        try {\n          const safeRows = await safeApi.review(dbAttemptId);\n          const safeDetails = practiceSafeReviewRowsToDetails(safeRows);\n          if (safeDetails.length) {\n            renderFromDetails(safeDetails);\n            return;\n          }\n        } catch (safeReviewError) {\n          try { trackEvent('practice_safe_review_error', { attempt_id: dbAttemptId, message: String(safeReviewError?.message || safeReviewError || 'unknown') }); } catch {}\n        }\n      }\n\n      const uid = await getAuthUid();\n      if (!uid) {`;
const patchedReviewBlock = reviewBlock.replace(reviewAnchor, safeReviewInjection);
app = app.slice(0, renderReviewStart) + patchedReviewBlock + app.slice(renderReviewEnd);

const safeScriptTag = '<script src="security/legacy-assessment-safe-api.js?v=p002v4"></script>';
assert(!html.includes(safeScriptTag), 'safe assessment helper already included');
html = replaceOnce(
  html,
  '<script src="app.js?v=support4"></script>',
  `${safeScriptTag}\n<script src="app.js?v=support4-p002v4"></script>`,
  'load safe assessment helper before app.js'
);

assert(app.includes(SAFE_HELPERS_MARKER), 'safe helper marker missing after patch');
assert(app.includes("source: 'subject_hub_safe_v4'"), 'safe Practice start not present');
assert(app.includes('return handlePracticeSubmitSafe(isAutoTimeout);'), 'safe Practice submit route missing');
assert(app.includes('finishPracticeSafe(quiz).catch(() => null);'), 'safe Practice finalize route missing');
assert(app.includes("reason: 'safe_v4'"), 'safe persisted result routing missing');
assert(html.indexOf(safeScriptTag) < html.indexOf('app.js?v=support4-p002v4'), 'safe helper must load before app.js');

fs.writeFileSync(APP, app);
fs.writeFileSync(INDEX, html);
console.log('P0-02 safe Practice frontend patch applied successfully.');
