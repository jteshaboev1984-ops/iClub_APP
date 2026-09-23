const fs = require("fs");
const assert = require("assert");

const live = fs.readFileSync("exam-prep/exam-prep-live.js","utf8");
const migration = fs.readFileSync("supabase/migrations/20260923104500_exam_prep_written_rubric_locale_guard_v1.sql","utf8");

assert.match(live,/rubricUnavailable:/,"localized rubric fallback copy missing");
assert.match(live,/Batafsil baholash mezonlari o‘zbek tilida hali tasdiqlanmagan/,"UZ fallback missing");
assert.match(live,/Подробные критерии оценивания на русском языке пока не утверждены/,"RU fallback missing");
assert.match(live,/localization_status === "unavailable"/,"UI does not honor server localization state");

assert.match(migration,/exam_prep_localized_written_rubric_v1/,"server rubric projector missing");
assert.match(migration,/'criteria','\[\]'::jsonb/,"RU\/UZ fail-closed criteria projection missing");
assert.match(migration,/'localization_status','unavailable'/,"unavailable status missing");
assert.match(migration,/'rubric',private\.exam_prep_localized_written_rubric_v1\(wt\.rubric_json,v_lang\)/,"timed review does not use localized projector");
assert.match(migration,/v_s\.status<>'finalized'/,"post-attempt guard missing");
assert.doesNotMatch(migration,/GRANT EXECUTE ON FUNCTION private\.exam_prep_localized_written_rubric_v1\(jsonb,text\)\s+TO authenticated/i,"private helper exposed to browser");

console.log("written rubric locale guard: PASS");
