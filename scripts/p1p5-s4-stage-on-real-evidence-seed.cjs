#!/usr/bin/env node
"use strict";
/*
 * Source-pinned disposable Stage-ON evidence generation.
 * It imports only vetted P2-69 pg_temp SQL test helpers and then executes
 * the real Stage-ON synthetic finalised-evidence fixture in one transaction.
 * The SQL is NOT a migration, not live Supabase, not learner content.
 */
const fs=require("node:fs");
const assert=require("node:assert/strict");
const {execFileSync}=require("node:child_process");
assert(process.env.CI==="true"&&process.env.P1P5_E2E_ISOLATED==="true"&&
  process.env.PGHOST==="127.0.0.1"&&process.env.PGUSER==="postgres"&&
  process.env.PGDATABASE==="postgres"&&
  process.env.P1P5_E2E_JWT_SECRET?.length>32,
  "REFUSED: signed disposable GitHub PostgreSQL17 required");
const source=fs.readFileSync("supabase/tests/p2_69_full_stage0_6_core_simulation.sql","utf8");
const start=source.indexOf("create or replace function pg_temp.p269_complete_session_correct_v1(");
const end=source.indexOf("\nDO $main$",start);
assert(start>0&&end>start&&end-start>9000&&end-start<45000,
  "Canonical P2-69 helper extraction boundary changed");
const helpers=source.slice(start,end);
for(const name of ["p269_complete_session_correct_v1","p269_start_direct_assessment_v1",
  "p269_ensure_learning_first_n_v1","p269_complete_selected_mixed_v1",
  "p269_complete_retests_all_skills_v1","p269_advance_days_v1"])
 assert(helpers.includes("create or replace function pg_temp."+name+"("),
   "Missing vetted P2-69 evidence helper: "+name);
const file="scripts/p1p5-s4-stage-on-finalized-evidence-fixture.sql";
const fixture=fs.readFileSync(file,"utf8");
const marker="-- P2-69 proven pg_temp helper definitions are inserted by the wrapper here.";
assert(fixture.split(marker).length===2,"Fixture helper insertion point changed");
const sql=fixture.replace(marker,()=>helpers);
assert(sql.includes("BEGIN;")&&sql.includes("COMMIT;")&&
  sql.includes("as "+String.fromCharCode(36,36))&&sql.includes("end;\n"+String.fromCharCode(36,36)+";")&&
  sql.includes("private.rebuild_exam_prep_state_v1(v_uid,null)")&&
  !/UPDATE private\.exam_prep_skill_states|INSERT INTO private\.exam_prep_skill_states|UPDATE private\.exam_prep_stage_states|INSERT INTO private\.exam_prep_stage_states/i.test(sql),
  "No direct academic projection injection accepted");
try{
  const out=execFileSync("psql",["-X","-v","ON_ERROR_STOP=1"],{
    input:sql,encoding:"utf8",
    env:{...process.env,PGOPTIONS:"-c iclub.e2e_isolated=true"},
    timeout:20*60*1000,maxBuffer:8*1024*1024
  });
  assert(out.includes("COMMIT"),"Disposable evidence transaction not committed");
  console.log("PASS: committed genuine finalized objective evidence in disposable PG17; stage derived from server; no Paper marks");
}catch(e){
  console.error("STAGE-ON AUTHENTIC EVIDENCE FIXTURE FAIL:",
    String(e.stderr||e.message).slice(-3500));
  process.exitCode=1;
}
