import fs from 'node:fs';
import { assert, range, replaceNamed } from './p0-02-aux-patcher.mjs';

let app = fs.readFileSync('app.js', 'utf8');
let html = fs.readFileSync('index.html', 'utf8');

function replaceBetween(source, startMarker, endMarker, replacement, label) {
  const start = source.indexOf(startMarker);
  assert(start >= 0, `${label}: start marker missing`);
  const end = source.indexOf(endMarker, start + startMarker.length);
  assert(end >= 0, `${label}: end marker missing`);
  return source.slice(0, start) + replacement + source.slice(end);
}

function replaceOnce(source, needle, replacement, label) {
  const first = source.indexOf(needle);
  assert(first >= 0, `${label}: anchor missing`);
  assert(source.indexOf(needle, first + needle.length) < 0, `${label}: anchor not unique`);
  return source.slice(0, first) + replacement + source.slice(first + needle.length);
}

app = replaceNamed(app, 'isValidInputAnswer', `function isValidInputAnswer(q, value) {
  void q;
  const v = String(value ?? "").trim();
  if (!v) return false;
  if (v.length > 500) return false;
  return !/[\\u0000-\\u0008\\u000B\\u000C\\u000E-\\u001F]/.test(v);
}`);

app = replaceNamed(app, 'loadTourQuestionsDB', `function getTourSafeApi() {
  return window.iclubSafeAssessment?.tour || null;
}

function mapTourSafeQuestionRows(rows) {
  const list = Array.isArray(rows) ? rows.slice() : [];
  return list
    .sort((a, b) => Number(a?.order_no || 0) - Number(b?.order_no || 0))
    .map(row => {
      const qtype = String(row?.qtype || "mcq").toLowerCase();
      const type = qtype === "input" ? "input" : "mcq";
      const options = type === "mcq"
        ? (parseOptionsText(pickContentText(row || {}, "options_text") || "") || [])
        : [];
      const diff = normalizeDifficulty(row?.difficulty || "easy");
      return {
        id: Number(row?.id || 0),
        subject_id: Number(row?.subject_id || 0) || null,
        topic: row?.topic || "General",
        subtopic: row?.subtopic || null,
        difficulty: diff,
        qtype,
        type,
        question: pickContentText(row || {}, "question_text") || "",
        options,
        imageUrl: row?.image_url || null,
        image_url: row?.image_url || null,
        book_ref: row?.book_ref || null,
        bookReference: row?.book_ref || null,
        timeLimitSec:
          (row?.time_limit_sec != null && Number(row.time_limit_sec) >= 10)
            ? Number(row.time_limit_sec)
            : TOUR_CONFIG.defaultQuestionTimeSec
      };
    })
    .filter(q => Number.isFinite(q.id) && q.id > 0);
}

async function loadTourQuestionsDB(tourId) {
  try {
    const api = getTourSafeApi();
    if (!api?.preflight) return [];
    return mapTourSafeQuestionRows(await api.preflight(Number(tourId)));
  } catch (error) {
    try { trackEvent("tour_safe_preflight_error", { tour_id: String(tourId || ""), message: String(error?.message || error || "unknown") }); } catch {}
    return [];
  }
}`);

app = replaceNamed(app, 'fetchQuestionRuntimeSecrets', `async function fetchQuestionRuntimeSecrets(questionId) {
  void questionId;
  return null;
}`);

app = replaceNamed(app, 'restoreActiveTourQuestionSecrets', `async function restoreActiveTourQuestionSecrets(ctx, questionIndex) {
  void ctx;
  void questionIndex;
  return null;
}`);

app = replaceNamed(app, 'upsertTourAnswer', `async function upsertTourAnswer(attemptId, questionId, patch) {
  try {
    const api = getTourSafeApi();
    if (!api?.submit) return { ok: false, reason: "safe_api_unavailable" };
    const p = patch && typeof patch === "object" ? patch : {};
    const result = await dbWriteWithRetry(() => api.submit({
      attemptId: Number(attemptId),
      questionId: Number(questionId),
      userAnswer: p.user_answer == null ? "" : String(p.user_answer),
      pickedIndex: p.picked_index ?? p.pickedIndex ?? null,
      timeSpent: Math.max(0, Number(p.time_spent || 0)),
      answered: p.answered !== false,
      finishReason: p.finish_reason ?? p.finishReason ?? null
    }), { tries: 3, baseDelayMs: 350 });
    return { ok: !!result?.ok, ...result };
  } catch (error) {
    try { trackEvent("tour_safe_submit_error", { attempt_id: String(attemptId || ""), question_id: String(questionId || ""), message: String(error?.message || error || "unknown") }); } catch {}
    return { ok: false, reason: "safe_submit_failed", error };
  }
}`);

app = replaceNamed(app, 'updateTourAttempt', `async function updateTourAttempt(attemptId, patch) {
  try {
    const api = getTourSafeApi();
    if (!api?.finalize) return { ok: false, reason: "safe_api_unavailable" };
    const p = patch && typeof patch === "object" ? patch : {};
    const result = await dbWriteWithRetry(() => api.finalize({
      attemptId: Number(attemptId),
      totalTime: Math.max(0, Number(p.total_time || p.totalTime || 0)),
      status: String(p.status || "submitted")
    }), { tries: 3, baseDelayMs: 450 });
    return { ok: !!result?.ok, ...result };
  } catch (error) {
    try { trackEvent("tour_safe_finalize_error", { attempt_id: String(attemptId || ""), message: String(error?.message || error || "unknown") }); } catch {}
    return { ok: false, reason: "safe_finalize_failed", error };
  }
}`);

app = replaceNamed(app, 'submitTourAnswer', `async function submitTourAnswer({ pickedIndex, auto = false } = {}) {
  const ctx = state.tourContext;
  if (!ctx) return;

  const q = ctx.questions?.[ctx.index];
  if (!q || !ctx.questionReady) return;

  const spentSec = Math.max(0, Math.floor((monoNow() - (ctx.qStartedAtMono ?? ctx.qStartedAt)) / 1000));
  const qType = String(q?.qtype || q?.type || "mcq").toLowerCase();
  const isMcq = qType === "mcq" || qType === "multiple_choice";
  const pickedNum = pickedIndex === null || pickedIndex === undefined ? null : Number(pickedIndex);
  const inputEl = document.getElementById("tour-input");
  const inputVal = inputEl ? String(inputEl.value || "").trim() : "";

  if (!isMcq && !auto && !isValidInputAnswer(q, inputVal)) {
    const errEl = document.getElementById("tour-input-error");
    if (errEl) {
      errEl.textContent = t("invalid_answer_format");
      errEl.style.display = "block";
    } else {
      showToast(t("invalid_answer_format"));
    }
    return;
  }

  if (ctx.isArchive) {
    const correctIdx = isMcq ? getMcqCorrectIndexFromQuestion(q) : null;
    const expected = getInputExpectedAnswer(q);
    const isCorrect = isMcq
      ? isMcqPickedIndexCorrect({ ...q, correctIndex: correctIdx }, pickedNum)
      : isInputAnswerCorrect(inputVal, expected);
    ctx.answers = ctx.answers || [];
    ctx.answers.push({ qid: q.id, pickedIndex: pickedNum, input: isMcq ? "" : inputVal, isCorrect, spentSec, index: ctx.index });
    if (isCorrect) ctx.correct += 1;
  } else {
    const pickedForDb = pickedNum === null ? "" : (idxToLetter(pickedNum) || String(pickedNum));
    const answerForDb = isMcq ? pickedForDb : inputVal;
    const answerPatch = {
      user_answer: answerForDb,
      picked_index: isMcq ? pickedNum : null,
      answered: true,
      time_spent: spentSec,
      finish_reason: auto ? "question_timeout" : null
    };

    const result = await upsertTourAnswer(ctx.attemptId, q.id, answerPatch);
    if (!result?.ok) {
      ctx.pendingDbAnswers = Array.isArray(ctx.pendingDbAnswers) ? ctx.pendingDbAnswers : [];
      ctx.pendingDbAnswers.push({ attemptId: ctx.attemptId, questionId: q.id, patch: answerPatch });
    }

    ctx.answers = ctx.answers || [];
    ctx.answers.push({ qid: q.id, pickedIndex: pickedNum, input: isMcq ? "" : inputVal, isCorrect: null, spentSec, index: ctx.index });
  }

  stripAnsweredTourQuestionInRuntime(ctx, ctx.index);
  ctx._pickedIndex = null;
  ctx.index += 1;
  saveState();

  if (ctx.index >= TOUR_CONFIG.total) {
    finishTour({ reason: auto ? "auto_done" : "done" }).catch(() => null);
    return;
  }

  renderTourQuestion();
}`);

{
  const r = range(app, 'openTourQuiz');
  let fn = r.text;
  fn = replaceBetween(
    fn,
    '  // 3) one attempt rule',
    '  // 4) load questions by mapping table tour_questions',
    '',
    'openTourQuiz remove legacy one-attempt read'
  );
  fn = replaceBetween(
    fn,
    '  // 5) create attempt row',
    '    // analytics: started',
    `  // 5) create/resume server-authoritative attempt after image preflight succeeded\n  const tourApi = getTourSafeApi();\n  if (!tourApi?.start || !tourApi?.questions || !window.iclubSafeAssessment?.makeClientSessionId) {\n    showToast(t("not_available") || "Tour is temporarily unavailable.");\n    return;\n  }\n\n  const tourClientSessionId = window.iclubSafeAssessment.makeClientSessionId("tour");\n  let startResult = null;\n  let runtimeRows = [];\n  try {\n    startResult = await dbWriteWithRetry(() => tourApi.start({\n      tourId: Number(tour.id),\n      clientSessionId: tourClientSessionId\n    }), { tries: 3, baseDelayMs: 400 });\n    runtimeRows = await dbWriteWithRetry(() => tourApi.questions(Number(startResult?.attempt_id)), { tries: 3, baseDelayMs: 350 });\n  } catch (error) {\n    const text = String(error?.message || error || "").toLowerCase();\n    if (text.includes("already_attempted")) {\n      await uiAlert({\n        title: t("tour_unavailable_title") || "Тур недоступен",\n        message: t("tour_unavailable_already_attempted") || "У вас уже была попытка в этом туре."\n      });\n    } else {\n      showToast(t("toast_tour_create_failed") || t("save_failed_try_again") || "Tour could not be started.");\n    }\n    try { trackEvent("tour_safe_start_error", { tour_id: String(tour.id || ""), message: String(error?.message || error || "unknown") }); } catch {}\n    return;\n  }\n\n  const attemptId = Number(startResult?.attempt_id || 0) || null;\n  const runtimeQuestions = mapTourSafeQuestionRows(runtimeRows);\n  if (!attemptId || runtimeQuestions.length !== TOUR_CONFIG.total) {\n    showToast(t("tour_unavailable_no_questions") || "Для тура не назначены вопросы.");\n    return;\n  }\n\n`,
    'openTourQuiz safe start'
  );
  fn = replaceOnce(fn, '    attemptId,\n    questions,', '    attemptId,\n    questions: runtimeQuestions,', 'openTourQuiz runtime questions');
  app = app.slice(0, r.start) + fn + app.slice(r.end);
}

app = replaceNamed(app, 'renderTourReview', `async function renderTourReview() {
  const wrap = $("#tour-review-list");
  if (!wrap) return;

  wrap.innerHTML = \`<div class="empty muted">\${escapeHTML(t("loading") || "Загрузка…")}</div>\`;
  const attemptId = Number(state?.courses?.lastTourAttemptId || 0);
  const localPayload = state?.courses?.lastTourReviewPayload || null;
  const payloadItems = Array.isArray(localPayload?.items) ? localPayload.items : [];

  const renderFromDetails = (details) => {
    const mistakesOnly = (Array.isArray(details) ? details : []).filter(d => d?.isCorrect === false);
    if (!mistakesOnly.length) {
      wrap.innerHTML = \`
        <div class="empty muted">\${escapeHTML(t("tour_review_no_mistakes") || "По этому туру ошибок не найдено.")}</div>
        <div class="list-item" style="margin-top:12px">
          <div class="muted small">\${escapeHTML(t("tour_review_practice_hint") || "Отработать темы дополнительно можно в практике.")}</div>
          <div style="margin-top:10px"><button class="btn" type="button" data-action="tour-review-open-practice">\${escapeHTML(t("tour_review_open_practice") || "Открыть практику")}</button></div>
        </div>\`;
      return;
    }

    wrap.innerHTML = mistakesOnly.map((d, idx) => {
      const qForFmt = { qtype: d.type, options_text: Array.isArray(d.options) ? JSON.stringify(d.options) : null };
      const userDisp = formatAnswerForDisplay(qForFmt, d.userAnswer);
      const corrDisp = formatAnswerForDisplay(qForFmt, d.correctAnswer);
      return \`
        <div class="list-item">
          <div style="display:flex;align-items:flex-start;gap:10px">
            <div style="font-size:24px;line-height:1">✕</div>
            <div style="min-width:0;flex:1">
              <div style="font-weight:900">\${escapeHTML(\`\${idx + 1}. \${d.topic || (t("topic_general") || "General")}\`)}</div>
              \${d.subtopic ? \`<div class="muted small" style="margin-top:4px">\${escapeHTML(String(d.subtopic))}</div>\` : ""}
              \${d.difficulty ? \`<div class="muted small" style="margin-top:4px">\${escapeHTML(String(d.difficulty))}</div>\` : ""}
              <div style="margin-top:10px">\${escapeHTML(d.question || "")}</div>
              \${buildReviewQuestionImageHtml(d)}
              <div class="muted small" style="margin-top:10px">\${escapeHTML(t("rec_your_answer") || "Ваш ответ")}: <b>\${escapeHTML(userDisp || "—")}</b></div>
              <div class="muted small" style="margin-top:4px">\${escapeHTML(t("rec_correct_answer") || "Правильный")}: <b>\${escapeHTML(corrDisp || "—")}</b></div>
              \${d.explanation ? \`<div class="muted small" style="margin-top:10px"><b>\${escapeHTML(t("explanation_label") || "Explanation")}:</b> \${escapeHTML(d.explanation)}</div>\` : ""}
            </div>
          </div>
        </div>\`;
    }).join("") + \`<div class="list-item" style="margin-top:12px"><div class="muted small">\${escapeHTML(t("tour_review_practice_hint") || "Отработать темы дополнительно можно в практике.")}</div><div style="margin-top:10px"><button class="btn" type="button" data-action="tour-review-open-practice">\${escapeHTML(t("tour_review_open_practice") || "Открыть практику")}</button></div></div>\`;
    bindQuestionImageButtons(wrap);
  };

  if (!attemptId) {
    renderFromDetails(payloadItems);
    return;
  }

  showAsyncOverlay(tr3("Загружаем разбор тура…", "Tur tahlili yuklanmoqda…", "Loading tour review…"));
  try {
    const api = getTourSafeApi();
    if (!api?.review) throw new Error("safe_tour_review_unavailable");
    const rows = await api.review(attemptId);
    const details = (Array.isArray(rows) ? rows : []).map((x, idx) => {
      const type = String(x?.qtype || "mcq").toLowerCase() === "input" ? "input" : "mcq";
      return {
        id: Number(x?.question_id || idx + 1),
        topic: x?.topic || (t("topic_general") || "General"),
        subtopic: x?.subtopic || null,
        difficulty: x?.difficulty || "easy",
        type,
        question: pickContentText(x || {}, "question_text") || "",
        imageUrl: x?.image_url || null,
        options: type === "mcq" ? (parseOptionsText(pickContentText(x || {}, "options_text") || "") || []) : [],
        userAnswer: String(x?.user_answer ?? ""),
        correctAnswer: String(x?.correct_answer ?? ""),
        explanation: pickContentText(x || {}, "explanation") || "",
        isCorrect: !!x?.is_correct,
        timeSpent: Number(x?.time_spent || 0)
      };
    });
    renderFromDetails(details);
  } catch (error) {
    const text = String(error?.message || error || "").toLowerCase();
    if (text.includes("tour_review_not_open")) {
      wrap.innerHTML = \`<div class="empty muted">\${escapeHTML(tr3("Полный разбор откроется после глобального завершения тура.", "To‘liq tahlil tur global yopilgandan keyin ochiladi.", "Full review will open after the tour is globally closed."))}</div>\`;
    } else {
      wrap.innerHTML = \`<div class="empty muted">\${escapeHTML(t("not_available") || "Разбор временно недоступен.")}</div>\`;
    }
    try { trackEvent("tour_safe_review_error", { attempt_id: String(attemptId), message: String(error?.message || error || "unknown") }); } catch {}
  } finally {
    hideAsyncOverlay();
  }
}`);

{
  const r = range(app, 'finishTour');
  let fn = r.text;
  fn = replaceBetween(
    fn,
    '  // duration/score summary (used for local + DB)',
    '  // Save attempt locally (for stats/trend). Does not affect future DB integration.',
    `  // duration/score summary. Active Tour score is server-authoritative.\n  const durationSec = Math.max(0, Math.round((Date.now() - (ctx?.startedAt || Date.now())) / 1000));\n  const total = TOUR_CONFIG.total;\n  let score = ctx?.isArchive\n    ? (Array.isArray(ctx?.answers) ? ctx.answers.filter(a => !!a?.isCorrect).length : Number(ctx?.correct || 0))\n    : 0;\n  let percent = total ? Math.round((score / total) * 100) : 0;\n\n`,
    'finishTour server score init'
  );
  fn = replaceBetween(
    fn,
    '  // Save attempt locally (for stats/trend). Does not affect future DB integration.',
    '       // DB finalize (only active tours)',
    `  // Archive mode remains local. Active Tour is persisted only after authoritative finalize.\n  if (ctx?.subjectKey && ctx?.isArchive) {\n    saveTourAttemptLocal(ctx.subjectKey, ctx.tourNo || 1, { ts: Date.now(), score, total, percent, durationSec });\n  }\n\n       // DB finalize (only active tours)`,
    'finishTour local save gate'
  );
  fn = replaceOnce(
    fn,
    '  } catch {}\n\n  // result meta',
    `  } catch {}\n\n  if (finalizeSavedToDb && ctx?.subjectKey && !ctx?.isArchive) {\n    saveTourAttemptLocal(ctx.subjectKey, ctx.tourNo || 1, { ts: Date.now(), score, total, percent, durationSec });\n  }\n\n  // result meta`,
    'finishTour authoritative local mirror'
  );

  const reviewStart = fn.indexOf('    try {\n      const reviewItems =');
  assert(reviewStart >= 0, 'finishTour review payload start missing');
  const certMarker = '    if (!state.certificates) {';
  const reviewEnd = fn.indexOf(certMarker, reviewStart);
  assert(reviewEnd > reviewStart, 'finishTour review payload end missing');
  const safeReviewPayload = `    try {\n      if (ctx?.isArchive) {\n        const reviewItems = Array.isArray(ctx?.answers)\n          ? ctx.answers.map((ans, idx) => {\n              const q = ctx?.questions?.[Number(ans.index)] || null;\n              const qType = String(q?.type || q?.qtype || "mcq").toLowerCase();\n              const isMcq = qType === "mcq" || qType === "multiple_choice";\n              const userAnswer = isMcq\n                ? ((ans?.pickedIndex === null || ans?.pickedIndex === undefined) ? "" : (idxToLetter(Number(ans.pickedIndex)) || String(ans.pickedIndex)))\n                : String(ans?.input || "").trim();\n              const correctAnswer = q?.correct_answer != null\n                ? String(q.correct_answer).trim()\n                : (q?.correctAnswer != null ? String(q.correctAnswer).trim() : ((q?.correctIndex !== null && q?.correctIndex !== undefined) ? (idxToLetter(Number(q.correctIndex)) || String(q.correctIndex)) : ""));\n              return {\n                id: Number(q?.id || idx + 1), topic: q?.topic || (t("topic_general") || "General"), subtopic: q?.subtopic || null,\n                difficulty: q?.difficulty || "easy", type: isMcq ? "mcq" : "input", question: q?.question || "",\n                imageUrl: q?.imageUrl || q?.image_url || null, options: Array.isArray(q?.options) ? q.options.slice() : [],\n                userAnswer, correctAnswer, explanation: pickContentText(q || {}, "explanation") || "",\n                isCorrect: !!ans?.isCorrect, timeSpent: Number(ans?.spentSec || 0)\n              };\n            })\n          : [];\n        state.courses.lastTourReviewPayload = { attemptId: null, subjectKey: ctx?.subjectKey || null, tourNo: ctx?.tourNo || 1, items: reviewItems };\n        addMyTourRecsFromTourAttempt(ctx);\n      } else {\n        state.courses.lastTourReviewPayload = { attemptId: ctx?.attemptId || null, subjectKey: ctx?.subjectKey || null, tourNo: ctx?.tourNo || 1, items: [] };\n      }\n      state.courses.lastTourEndDate = String(ctx?.tourEndDate || "").trim() || null;\n    } catch {\n      state.courses.lastTourReviewPayload = null;\n    }\n\n`;
  fn = fn.slice(0, reviewStart) + safeReviewPayload + fn.slice(reviewEnd);
  app = app.slice(0, r.start) + fn + app.slice(r.end);
}

const openAfter = range(app, 'openTourQuiz').text;
assert(!openAfter.includes('hasTourAttempt('), 'openTourQuiz still does legacy attempt read');
assert(!openAfter.includes('createTourAttempt('), 'openTourQuiz still creates legacy attempt directly');
assert(openAfter.includes('tourApi.start(') && openAfter.includes('tourApi.questions('), 'openTourQuiz safe start/questions missing');

const loadAfter = range(app, 'loadTourQuestionsDB').text;
assert(!loadAfter.includes('.from("tour_questions")'), 'Tour preflight still reads tour_questions directly');
assert(!loadAfter.includes('correct_answer'), 'Tour preflight contains answer key');

const fetchAfter = range(app, 'fetchQuestionRuntimeSecrets').text;
assert(!fetchAfter.includes('.from("questions")'), 'runtime secret fetch still reads questions');

const upsertAfter = range(app, 'upsertTourAnswer').text;
assert(!upsertAfter.includes('.from("tour_answers")'), 'Tour answer helper still writes tour_answers directly');
assert(upsertAfter.includes('api.submit('), 'Tour answer helper safe submit missing');

const updateAfter = range(app, 'updateTourAttempt').text;
assert(!updateAfter.includes('.from("tour_attempts")'), 'Tour finalize helper still writes tour_attempts directly');
assert(updateAfter.includes('api.finalize('), 'Tour finalize helper safe finalize missing');

const reviewAfter = range(app, 'renderTourReview').text;
assert(!reviewAfter.includes('.from("tour_answers")'), 'Tour review still reads tour_answers directly');
assert(!reviewAfter.includes('question:questions('), 'Tour review still joins questions directly');
assert(reviewAfter.includes('api.review('), 'Tour safe review missing');

const submitAfter = range(app, 'submitTourAnswer').text;
assert(!submitAfter.includes('restoreActiveTourQuestionSecrets('), 'active Tour submit still restores secrets');
assert(submitAfter.includes('isCorrect: null'), 'active Tour submit must not know correctness');

const oldApiKey = 'security/legacy-assessment-safe-api.js?v=p002v4aux1';
const oldAppKey = 'app.js?v=support4-p002v4aux2';
assert(html.includes(oldApiKey), 'old safe API cache key missing');
assert(html.includes(oldAppKey), 'old app cache key missing');
html = html.replace(oldApiKey, 'security/legacy-assessment-safe-api.js?v=p002v4tour1');
html = html.replace(oldAppKey, 'app.js?v=support4-p002v4tour1');

fs.writeFileSync('app.js', app);
fs.writeFileSync('index.html', html);
