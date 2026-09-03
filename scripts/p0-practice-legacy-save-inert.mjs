import fs from 'node:fs';
import { range } from './p0-02-aux-patcher.mjs';

const appPath = 'app.js';
const htmlPath = 'index.html';
let app = fs.readFileSync(appPath, 'utf8');
let html = fs.readFileSync(htmlPath, 'utf8');

function assert(ok, msg) {
  if (!ok) throw new Error(msg);
}
function count(source, needle) {
  return source.split(needle).length - 1;
}
function replaceOne(source, from, to, label) {
  const n = count(source, from);
  assert(n === 1, `${label}: expected 1, found ${n}`);
  return source.replace(from, to);
}

const pendingLegacy = `                    if (op?.type === "practice_save") {
            // op.payload: { attempt, quiz }
            const res = await savePracticeAttemptToSupabase(op.payload?.attempt, op.payload?.quiz);

            if (res?.ok) {
              try {
                refreshLiveProgressSurfaces();
              } catch {}
            } else {
              keep.push(op);
            }

            continue;
          }`;
const pendingSafe = `          if (op?.type === "practice_save") {
            // Legacy client-scored Practice payloads are no longer trusted.
            // Drop stale queued writes instead of replaying them into canonical progress.
            continue;
          }`;
app = replaceOne(app, pendingLegacy, pendingSafe, 'legacy pending Practice save retirement');

const finishLegacy = `      if (quiz?.safePersistedResult?.ok) {
        res = {
          ok: true,
          reason: 'safe_v4',
          attemptId: Number(quiz.safePersistedResult.attemptId || 0) || null,
          subjectId: null,
          score: Number(quiz.safePersistedResult.score || 0),
          percent: Number(quiz.safePersistedResult.percent || 0)
        };
      } else {
        res = await savePracticeAttemptToSupabase(attempt, quiz);
      }

      if (res?.ok) {
        clearPracticeDraft();
        try {
          refreshLiveProgressSurfaces();
        } catch {}
      } else {
        enqueuePendingOp({
          type: "practice_save",
          payload: buildPracticeSavePayload(attempt, quiz)
        });
      }`;
const finishSafe = `      if (quiz?.safePersistedResult?.ok) {
        res = {
          ok: true,
          reason: 'safe_v4',
          attemptId: Number(quiz.safePersistedResult.attemptId || 0) || null,
          subjectId: null,
          score: Number(quiz.safePersistedResult.score || 0),
          percent: Number(quiz.safePersistedResult.percent || 0)
        };
      } else {
        // Defensive fail-closed path. Main Practice reaches finishPractice only after
        // safe-v4 finalization; never fall back to client-authoritative persistence.
        res = { ok: false, reason: 'safe_v4_persistence_missing' };
      }

      if (res?.ok) {
        clearPracticeDraft();
        try {
          refreshLiveProgressSurfaces();
        } catch {}
      } else {
        try { showToast(t("save_failed_try_again") || "Не удалось сохранить результат. Попробуйте ещё раз."); } catch {}
      }`;
app = replaceOne(app, finishLegacy, finishSafe, 'finishPractice fail-closed persistence');

const callsBefore = (app.match(/\bsavePracticeAttemptToSupabase\s*\(/g) || []).length;
assert(callsBefore === 1, `savePracticeAttemptToSupabase must be declaration-only before inerting; found ${callsBefore}`);
const r = range(app, 'savePracticeAttemptToSupabase');
const stub = `async function savePracticeAttemptToSupabase(attempt, quiz) {
  void attempt;
  void quiz;
  // P0 hardening: canonical Practice persistence is server-authoritative via safe-v4 RPCs.
  return { ok: false, reason: "legacy_practice_write_disabled" };
}`;
app = app.slice(0, r.start) + stub + app.slice(r.end);

const callsAfter = (app.match(/\bsavePracticeAttemptToSupabase\s*\(/g) || []).length;
assert(callsAfter === 1, `legacy Practice saver stub count mismatch: ${callsAfter}`);
const stubText = range(app, 'savePracticeAttemptToSupabase').text;
for (const banned of ['.from("practice_attempts")', '.from("practice_answers")', '.insert(', '.delete(', '.update(']) {
  assert(!stubText.includes(banned), `legacy Practice saver still contains ${banned}`);
}
assert(count(app, 'type: "practice_save"') === 0, 'new legacy practice_save enqueue remains');
assert(count(app, 'op?.type === "practice_save"') === 1, 'pending legacy Practice discard path mismatch');

html = replaceOne(
  html,
  'app.js?v=support4-p0practicereset1',
  'app.js?v=support4-p0legacysaveoff1',
  'app cache key bump'
);

fs.writeFileSync(appPath, app);
fs.writeFileSync(htmlPath, html);
