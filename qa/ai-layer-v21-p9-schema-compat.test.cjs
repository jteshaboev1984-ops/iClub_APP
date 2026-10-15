"use strict";
const {test}=require("node:test"),a=require("node:assert/strict"),{readFileSync}=require("node:fs");
const ref=require("./ai-layer-v21-p9-production-schema-shape-readonly.json");
const overlay=readFileSync("qa/sql_drafts/iclub_ai_v21_89_column_overlay_LOCAL_ONLY.psql","utf8");
const cases=readFileSync("qa/sql_drafts/iclub_ai_v21_two_owner_proof_LOCAL_ONLY.psql","utf8");
test("§117 snapshot matches 89 hardcoded metadata tuples and 49 additive columns",()=>{
 const m=[...overlay.matchAll(/\('([^']+)','([^']+)','([^']+)','([^']+)',(true|false)\)/g)];
 a.equal(m.length,89);
 a.deepEqual(m.map(x=>({table:x[1]+"."+x[2],column:x[3],type:x[4],nullable:x[5]==="true"})),
  ref.columns.map(x=>({table:x.table,column:x.column,type:x.type,nullable:x.nullable})));
 a.equal([...overlay.matchAll(/ALTER TABLE [\w.]+ ADD COLUMN /g)].length,49);
 a.equal(ref.fixtureMissingOrMismatchedColumns,49);
});
test("§117 two-principal synthetic security and failed academic write covered",()=>{
 for(const phrase of ["SET ROLE authenticated","CREATE POLICY qa_subject_owner",
 "CREATE POLICY qa_tour_owner","TWO_OWNER_RLS_GREEN","TWO_OWNER_SCOPE_GREEN",
 "qa_protected_exam","unique_violation"])a.ok(cases.includes(phrase),phrase);
 a.doesNotMatch(cases,/SUPABASE_SERVICE_ROLE_KEY|api\.openai\.com|INSERT INTO auth\.users/);
});
