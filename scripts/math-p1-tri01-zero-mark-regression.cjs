#!/usr/bin/env node
"use strict";
const fs = require("node:fs");
const path = require("node:path");
const assert = require("node:assert/strict");

// Static regression only. Never opens Supabase or writes student records.
const sql = fs.readFileSync(
  path.join(__dirname, "ops/20261029_p1_tri01_zeros_version3_publish.sql"), "utf8"
);
function expect(s){assert.ok(sql.includes(s), `Missing release invariant: ${s}`);}
for(const s of [
  "BEGIN;", "COMMIT;", "pg_advisory_xact_lock(611031528036)",
  "P1TRI01-W01", "p1_tri01_learning", "wtv3", "av3",
  "id=279", "id=457", "task_version='wtv3'",
  "both exact zeros x=π/6 and x=5π/6",
  "v_total<>10", "written_task_id=279", "source_rule_md5",
  "P1_TRI01_cloned_learning_pack_drift",
  "P1_TRI01_post_publish_incomplete",
  "OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_29_NO_INDEPENDENT_HUMAN"
])expect(s);
assert.doesNotMatch(sql, /\b(?:DELETE\s+FROM|TRUNCATE|DROP\s+TABLE|ALTER\s+TABLE)\b/i);
assert.doesNotMatch(sql, /UPDATE\s+private\.exam_prep_(?:responses|sessions|skill_states|weekly_plans)/i);
const taskWrites = [...sql.matchAll(/UPDATE\s+private\.exam_prep_written_tasks\s+SET[\s\S]*?;/gi)].map(m => m[0]);
assert.equal(taskWrites.length, 1, "Exactly one targeted task-status UPDATE expected");
assert.match(taskWrites[0], /WHERE\s+id=279\s+AND\s+lifecycle_state='draft'/i);
assert.doesNotMatch(taskWrites[0], /\b(?:17|184)\b/);
assert.equal(Math.abs(2*Math.sin(Math.PI/6)-1)<1e-12, true);
assert.equal(Math.abs(2*Math.sin(5*Math.PI/6)-1)<1e-12, true);
assert.equal(4+3+2+1,10);
console.log("P1TRI01: guarded published-version correction / math / no student writes: PASS");
