#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");
const root = path.resolve(__dirname, "..");
const read = p => fs.readFileSync(path.join(root, p), "utf8");
const sql = read("supabase/migrations/20261008110000_math_practice_v2_post_publish_local_reset_gate_v1.sql");
const app = read("app.js");
const index = read("index.html");
const reset = read("security/practice-v2-local-reset.js");

function assert(ok, why) {
  if (!ok) throw new Error(why);
}
for(const required of [
 "create or replace function public.is_math_practice_v2_published_safe_v1()",
 "auth.uid() is null",
 "return false",
 "private.practice_v2_release_switch_audit",
 "a.status = 'published'",
 "m.lifecycle_state = 'published'",
 "m.is_runtime_allowed is true",
 "q.is_active is true",
 "ppq.is_active is true",
 "count(*) = 495",
 "revoke all on function public.is_math_practice_v2_published_safe_v1() from public, anon",
 "grant execute on function public.is_math_practice_v2_published_safe_v1() to authenticated"
]) {
 assert(sql.includes(required), "Published-bank auth contract missing: "+required);
}
for(const forbidden of [/\bdelete\s+from\b/i,/\btruncate\b/i,/\bupdate\s+(?:public\.|private\.)/i,/\binsert\s+into\b/i]) {
 assert(!forbidden.test(sql), "Read-only publish gate contains unexpected data mutation");
}
assert(reset.includes('result?.data !== true'), "Cleanup must require exact server true, not a loosely truthy response");
assert(reset.includes('Promise.race('), "Cleanup must have a bounded server check");
assert(reset.includes('if (result?.error'), "Cleanup must fail closed on server errors");
assert(!reset.includes('storage.removeItem("practice_history_v3:mathematics:tour_'), "Must not clear new Mathematics v3 history");
assert(!reset.includes("PRACTICE_HISTORY_PREFIXES"), "Must not bulk-clear both old and new history namespaces");
assert(app.includes('await window.iclubMathPracticeV2ResetAfterPublish?.(window.sb)'), "Boot must invoke authenticated publication gate");
assert(!app.includes('if (cleared === true) state = loadState()'), "Narrow old-history cleanup must not reload or clear an active quiz");
assert(index.includes("security/practice-v2-local-reset.js?v=stage03oldhistory2"), "Cache pin must refresh protective local reset");
assert(index.includes("app.js?v=") && index.includes("reviewback1-postpublish1"), "Cache pin must refresh calling app");
console.log("Mathematics Practice v2 local-reset publish gate: GREEN, no automatic reset and no protected history writes.");
