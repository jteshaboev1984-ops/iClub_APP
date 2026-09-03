import fs from 'node:fs';

function assert(ok, message) {
  if (!ok) throw new Error(message);
}
function replaceOnce(src, needle, replacement, label) {
  const first = src.indexOf(needle);
  assert(first >= 0, `${label}: anchor missing`);
  assert(src.indexOf(needle, first + needle.length) < 0, `${label}: anchor not unique`);
  return src.slice(0, first) + replacement + src.slice(first + needle.length);
}

let api = fs.readFileSync('security/legacy-assessment-safe-api.js','utf8');
let app = fs.readFileSync('app.js','utf8');
let html = fs.readFileSync('index.html','utf8');

api = replaceOnce(
  api,
  'const API_VERSION = "p0-02-v4-aux2-tour-reset";',
  'const API_VERSION = "p0-02-v4-aux2-tour-reset-cred1";',
  'safe api version'
);

const reviewAnchor = `    async review(attemptId) {\n      return rpc("get_practice_review_full_safe_v4", {\n        p_attempt_id: requirePositiveInt(attemptId, "attempt_id")\n      });\n    },\n\n    async resetProgress() {`;
const reviewReplacement = `    async review(attemptId) {\n      return rpc("get_practice_review_full_safe_v4", {\n        p_attempt_id: requirePositiveInt(attemptId, "attempt_id")\n      });\n    },\n\n    async reviewOpened(attemptId) {\n      return rpc("record_practice_review_opened_safe_v1", {\n        p_attempt_id: requirePositiveInt(attemptId, "attempt_id")\n      });\n    },\n\n    async resetProgress() {`;
api = replaceOnce(api, reviewAnchor, reviewReplacement, 'practice reviewOpened API');

const appAnchor = `      const safeRows = await safeApi.review(dbAttemptId);\n      renderFromDetails(practiceSafeReviewRowsToDetails(safeRows));`;
const appReplacement = `      try {\n        if (safeApi?.reviewOpened) await safeApi.reviewOpened(dbAttemptId);\n      } catch (reviewMarkerError) {\n        try {\n          trackEvent("practice_review_marker_error", {\n            attempt_id: dbAttemptId,\n            message: String(reviewMarkerError?.message || reviewMarkerError || "unknown")\n          });\n        } catch {}\n      }\n      const safeRows = await safeApi.review(dbAttemptId);\n      renderFromDetails(practiceSafeReviewRowsToDetails(safeRows));`;
app = replaceOnce(app, appAnchor, appReplacement, 'Practice review marker call');

html = replaceOnce(
  html,
  'security/legacy-assessment-safe-api.js?v=p002v4reset1',
  'security/legacy-assessment-safe-api.js?v=p002v4cred1',
  'safe api cache key'
);
html = replaceOnce(
  html,
  'app.js?v=support4-p0legacysaveoff1',
  'app.js?v=support4-p0credreview1',
  'app cache key'
);

assert(api.includes('record_practice_review_opened_safe_v1'), 'review marker RPC missing');
assert(app.includes('safeApi.reviewOpened(dbAttemptId)'), 'review marker call missing');
assert(app.includes('const safeRows = await safeApi.review(dbAttemptId);'), 'main safe review path lost');
assert(!app.includes('.from("practice_review_events_v1")'), 'frontend must not access review evidence table directly');

fs.writeFileSync('security/legacy-assessment-safe-api.js', api);
fs.writeFileSync('app.js', app);
fs.writeFileSync('index.html', html);
