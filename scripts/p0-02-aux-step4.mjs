import fs from 'node:fs';
import { assert, range, matchingBrace } from './p0-02-aux-patcher.mjs';

let app = fs.readFileSync('app.js', 'utf8');
let html = fs.readFileSync('index.html', 'utf8');

const r = range(app, 'renderPracticeReview');
let fn = r.text;
const marker = '// DB-first flow (best-effort)';
const markerIndex = fn.indexOf(marker);
assert(markerIndex >= 0, 'review DB marker missing');
const iifeStart = fn.indexOf('(async () => {', markerIndex);
assert(iifeStart >= 0, 'review IIFE start missing');
const open = fn.indexOf('{', iifeStart);
const close = matchingBrace(fn, open);
const tail = fn.slice(close + 1);
const call = tail.indexOf(')();');
assert(call >= 0 && call < 20, 'review IIFE call end missing');
const iifeEnd = close + 1 + call + 4;

const safeOnly = `(async () => {
    const localDetails = Array.isArray(attempt?.details) ? attempt.details : [];
    if (!dbAttemptId) {
      renderFromDetails(localDetails);
      return;
    }

    showAsyncOverlay(tr3(
      "Загружаем разбор практики…",
      "Amaliyot tahlili yuklanmoqda…",
      "Loading practice review…"
    ));

    try {
      const safeApi = getPracticeSafeApi();
      if (!safeApi?.review) {
        renderFromDetails([]);
        return;
      }
      const safeRows = await safeApi.review(dbAttemptId);
      renderFromDetails(practiceSafeReviewRowsToDetails(safeRows));
    } catch (safeReviewError) {
      try {
        trackEvent("practice_safe_review_error", {
          attempt_id: dbAttemptId,
          message: String(safeReviewError?.message || safeReviewError || "unknown")
        });
      } catch {}
      renderFromDetails([]);
    } finally {
      hideAsyncOverlay();
    }
  })();`;

fn = fn.slice(0, iifeStart) + safeOnly + fn.slice(iifeEnd);
app = app.slice(0, r.start) + fn + app.slice(r.end);

const reviewAfter = range(app, 'renderPracticeReview').text;
assert(!reviewAfter.includes('.from("practice_answers")'), 'review still reads practice_answers directly');
assert(!reviewAfter.includes('.from("questions")'), 'review still reads questions directly');
assert(reviewAfter.includes('practiceSafeReviewRowsToDetails'), 'safe review mapping missing');

const oldApi = 'security/legacy-assessment-safe-api.js?v=p002v4';
const oldApp = 'app.js?v=support4-p002v4';
assert(html.includes(oldApi), 'old safe API cache key missing');
assert(html.includes(oldApp), 'old app cache key missing');
html = html.replace(oldApi, 'security/legacy-assessment-safe-api.js?v=p002v4aux1');
html = html.replace(oldApp, 'app.js?v=support4-p002v4aux1');

fs.writeFileSync('app.js', app);
fs.writeFileSync('index.html', html);
