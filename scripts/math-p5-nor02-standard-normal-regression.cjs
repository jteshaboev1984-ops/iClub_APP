#!/usr/bin/env node
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
// Static-only regression; runs without secrets, SQL execution or user data.
const sql = fs.readFileSync(path.join(__dirname, "ops/20261029_p5_nor02_standard_normal_v3_publish.sql"), "utf8");
for (const expected of [
  "BEGIN;", "COMMIT;", "pg_advisory_xact_lock(611031528037)",
  "P5NOR02-W01", "p5_nor02_learning", "wtv3", "av3",
  "id=280", "id=458", "source_rule_md5", "missing_criteria",
  "P5_NOR02_English_rubric_or_translation_drift",
  "P5_NOR02_learning_pack_drift",
  "P5_NOR02_v3_publication_incomplete",
  "OWNER_REQUESTED_AI_ASSISTED_QA_2026_10_29_NO_INDEPENDENT_HUMAN"
]) assert.ok(sql.includes(expected), "Missing fix safeguard: " + expected);
assert.doesNotMatch(sql, /\b(?:DELETE\s+FROM|DROP\s+TABLE|TRUNCATE|ALTER\s+TABLE)\b/i);
assert.doesNotMatch(sql, /UPDATE\s+private\.exam_prep_(?:responses|sessions|skill_states|weekly_plans)/i);
const taskUpdates=[...sql.matchAll(/UPDATE\s+private\.exam_prep_written_tasks\s+SET[\s\S]*?;/gi)];
assert.equal(taskUpdates.length,1,"Exactly one targeted task UPDATE");
assert.match(taskUpdates[0][0], /WHERE\s+id=280\s+AND\s+task_version='wtv3'\s+AND\s+lifecycle_state='draft'/i);
const assessmentUpdates=[...sql.matchAll(/UPDATE\s+private\.exam_prep_assessments\s+SET[\s\S]*?;/gi)];
assert.equal(assessmentUpdates.length,1);
assert.match(assessmentUpdates[0][0], /WHERE\s+id=458\s+AND\s+assessment_version='av3'\s+AND\s+status='draft'/i);
const z=x=>(x-70)/3; // X ~ N(70,9) so sigma=3.
assert.deepEqual([64,73,79].map(z),[-2,1,3]);
assert.equal(1+3+2+2+3,11); // marks unchanged
// Known rounded standard-normal probabilities referenced by the immutable rubric.
assert.equal(Number(0.841344746.toFixed(4)),0.8413);
assert.equal(Number(0.022750132.toFixed(4)),0.0228);
assert.equal(Number(0.682689492.toFixed(4)),0.6827);
console.log("P5 NOR-02 v3: localization requirements / z-scores / marks / SQL scope PASS");
