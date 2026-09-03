import fs from 'node:fs';

const appPath = 'app.js';
const apiPath = 'security/legacy-assessment-safe-api.js';
const htmlPath = 'index.html';

let app = fs.readFileSync(appPath, 'utf8');
let api = fs.readFileSync(apiPath, 'utf8');
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

const oldWipe = `          // --- Practice wipe ---
          const { data: pAtt } = await window.sb
            .from("practice_attempts")
            .select("id")
            .eq("user_id", uid)
            .limit(10000);

          const pIds = (Array.isArray(pAtt) ? pAtt : []).map(x => x.id).filter(Boolean);
          if (pIds.length) {
            // delete answers by attempt_id (safe if column exists)
            for (let i = 0; i < pIds.length; i += 500) {
              const chunk = pIds.slice(i, i + 500);
              await window.sb.from("practice_answers").delete().in("attempt_id", chunk);
            }
          }
          await window.sb.from("practice_attempts").delete().eq("user_id", uid);

          // --- Tour wipe ---`;

const newWipe = `          // --- Practice wipe (server-authoritative) ---
          const practiceApi = getPracticeSafeApi();
          if (!practiceApi?.resetProgress) {
            throw new Error("practice_reset_safe_api_unavailable");
          }
          const resetResult = await practiceApi.resetProgress();
          if (!resetResult?.ok) {
            throw new Error("practice_reset_failed");
          }

          // --- Tour wipe ---`;

app = replaceOne(app, oldWipe, newWipe, 'content-language Practice reset cutover');

const reviewNeedle = `    async review(attemptId) {
      return rpc("get_practice_review_full_safe_v4", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id")
      });
    },

    async recentMistakes`;
const reviewReplacement = `    async review(attemptId) {
      return rpc("get_practice_review_full_safe_v4", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id")
      });
    },

    async resetProgress() {
      return rpc("reset_practice_progress_safe_v4", {});
    },

    async recentMistakes`;
api = replaceOne(api, reviewNeedle, reviewReplacement, 'safe Practice reset API insertion');
api = replaceOne(api, 'const API_VERSION = "p0-02-v4-aux2-tour";', 'const API_VERSION = "p0-02-v4-aux2-tour-reset";', 'safe API version bump');

html = replaceOne(
  html,
  'security/legacy-assessment-safe-api.js?v=p002v4tour1',
  'security/legacy-assessment-safe-api.js?v=p002v4reset1',
  'safe API cache key bump'
);
html = replaceOne(
  html,
  'app.js?v=support4-p0tourwrites1',
  'app.js?v=support4-p0practicereset1',
  'app cache key bump'
);

assert(!app.includes(oldWipe), 'legacy direct Practice wipe remains');
assert(count(app, 'practiceApi.resetProgress()') === 1, 'safe Practice reset call count mismatch');
assert(count(api, 'reset_practice_progress_safe_v4') === 1, 'safe reset RPC exposure count mismatch');
assert(count(api, 'async resetProgress()') === 1, 'safe reset method count mismatch');

fs.writeFileSync(appPath, app);
fs.writeFileSync(apiPath, api);
fs.writeFileSync(htmlPath, html);
