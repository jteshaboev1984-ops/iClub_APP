#!/usr/bin/env node
"use strict";
// Release gate only. Requires separate explicit GO; CI is SYNTHETIC and ROLLBACK.
// Protected question prompts, worked solutions and answer keys never enter Git.
const assert=require("node:assert/strict");
const fs=require("node:fs");
const crypto=require("node:crypto");
const path=require("node:path");
const os=require("node:os");
const {spawnSync,execFileSync}=require("node:child_process");
const MODE=process.argv[2];
const BANK="math-extra-hard-2026-11-full-v3";
const PRIOR="math-extra-hard-2026-11-original-v2";
const SOURCE_SHA="2283f0a35697349dac6825accd199e85fc72bb61d4ac5f8b4aca9e5adaeea77b";
const sourceFields=["task_key","bank_version","component_code","primary_skill_code",
 "official_section","book_map","title_i18n","prompt_i18n","solution_i18n","exact_answer"];
const hash=x=>crypto.createHash("sha256").update(x).digest("hex");
function stable(v){
 if(Array.isArray(v))return "["+v.map(stable).join(",")+"]";
 if(v&&typeof v==="object")return "{"+Object.keys(v).sort().map(k=>JSON.stringify(k)+":"+stable(v[k])).join(",")+"}";
 return JSON.stringify(v);
}
function privateExpected(filename){
 assert(filename,"A private Full42 JSON source path is required");
 const src=path.resolve(filename),repo=path.resolve(__dirname,"..","..")+path.sep;
 assert(!src.startsWith(repo),"Protected sources cannot be inside public repository");
 const bytes=fs.readFileSync(src);
 assert.equal(hash(bytes),SOURCE_SHA,"Protected source SHA mismatch");
 const b=JSON.parse(bytes.toString("utf8"));
 assert(b.format_version==="iclub.extra_hard.private_bank_v3"&&b.bank_version===BANK);
 assert(b.program_key==="math_as_p1_p5"&&b.program_version_key==="p1_p5_canonical_v1_0");
 assert(b.release_enabled===false&&b.academic_approved===false);
 assert(Array.isArray(b.tasks)&&b.tasks.length===42);
 const seen=new Set(),groups=new Map(),count={P1:0,P5:0};
 const result=[];
 for(const t of b.tasks){
  assert(/^EH26-P[15]-[A-Z]{3}-\d{2}-\d{2}$/.test(t.task_key));
  assert(!seen.has(t.task_key));seen.add(t.task_key);
  assert(t.bank_version===BANK&&t.source_kind==="iclub_original");
  assert(t.component_code==="P1"||t.component_code==="P5");
  assert(t.primary_skill_code.startsWith(t.component_code+"-"));
  assert(t.qa_math==="approved"&&t.qa_languages==="approved"&&t.qa_technical==="approved");
  assert(t.lifecycle_status==="approved");
  const item={};for(const f of sourceFields)item[f]=t[f];
  assert.equal(hash(Buffer.from(stable(item),"utf8")),t.content_sha256);
  const g=t.component_code==="P1"?String(t.official_section).slice(0,3):
    t.primary_skill_code.startsWith("P5-GEO-")?"5.4G":
    t.primary_skill_code.startsWith("P5-BIN-")?"5.4B":String(t.official_section).slice(0,3);
  groups.set(g,(groups.get(g)||0)+1);count[t.component_code]++;
  result.push({id:t.task_key,sha:t.content_sha256,component:t.component_code,fields:item});
 }
 assert(count.P1===24&&count.P5===18&&groups.size===14&&[...groups.values()].every(n=>n===3));
 return result;
}
function syntheticExpected(){
 assert(process.env.CI==="true"&&process.env.P1P5_E2E_ISOLATED==="true"
  &&process.env.PGHOST==="127.0.0.1"&&process.env.PGPORT==="5432"
  &&process.env.PGDATABASE==="postgres"&&process.env.PGUSER==="postgres",
  "CI release rehearsal refuses other databases");
 const arr=[];for(const c of ["P1","P5"]){for(let i=0;i<(c==="P1"?24:18);i++){
  const id="CI-EH-PUB-"+c+"-"+String(i+1).padStart(2,"0");
  const fields={task_key:id,bank_version:BANK,component_code:c,
   primary_skill_code:c==="P1"?"P1-QUA-01":"P5-GEO-01",
   official_section:"CI TEST",book_map:"CI TEST",
   title_i18n:{en:"CI TEST",ru:"CI TEST",uz:"CI TEST"},
   prompt_i18n:{en:"CI TEST 1+1",ru:"CI TEST 1+1",uz:"CI TEST 1+1"},
   solution_i18n:{en:"CI TEST 1+1=2",ru:"CI TEST 1+1=2",uz:"CI TEST 1+1=2"},
   exact_answer:"CI TEST 2"};
  arr.push({id,component:c,sha:hash(Buffer.from("CI TEST ONLY "+id)),fields});
 }}
 return arr;
}
function sqlRead(sql,env){
 return execFileSync("psql",["-X","-At","-v","ON_ERROR_STOP=1","-c",sql],{env,encoding:"utf8"}).trim();
}
function publish(expected,synthetic,injectTamper=false){
 const safe=x=>{assert(/^[A-Za-z0-9_.-]+$/.test(x));return x;};
 const values=expected.map(x=>"('"+safe(x.id)+"','"+safe(x.sha)+"','"+safe(x.component)+"')").join(",");
 assert(expected.length===42);
 const env={...process.env,...(synthetic?{PGOPTIONS:"-c iclub.e2e_isolated=true"}:{})};
 const snapSql="SELECT (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1)||'|'||(SELECT count(*) FROM private.exam_prep_extra_hard_attempts_v1)||'|'||(SELECT count(*) FROM private.exam_prep_sessions)||'|'||(SELECT bank_version||':'||enabled||':'||academic_approved FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5')";
 const before=synthetic?sqlRead(snapSql,env):null;
 if(synthetic)assert(before.includes(PRIOR+":false:false")&&before.startsWith("0|0|"),
  "Synthetic release expected zero existing private tasks or attempts");
 const sql=[
  "BEGIN;","SET LOCAL lock_timeout='3s';","SET LOCAL statement_timeout='30s';",
  "DO $pre$ BEGIN",
  "IF NOT EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_release_v1",
  " WHERE program_key='math_as_p1_p5' AND bank_version='"+PRIOR+"' AND enabled=false AND academic_approved=false)",
  "OR (SELECT count(*) FROM private.exam_prep_program_versions WHERE program_key='math_as_p1_p5'",
  " AND version_key='p1_p5_canonical_v1_0' AND status='active')<>1",
  "THEN RAISE EXCEPTION 'Extra Hard release: wrong prior disabled bank/program'; END IF;",
  synthetic?"IF current_database()<>'postgres' OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true' OR (SELECT count(*) FROM auth.users)<>2 OR (SELECT count(*) FROM public.users)<>2 THEN RAISE EXCEPTION 'Not a disposable CI source'; END IF;":"",
  "END $pre$;",
  "CREATE TEMP TABLE _eh_release_proof(id text PRIMARY KEY,sha text NOT NULL,component text NOT NULL) ON COMMIT DROP;",
  "INSERT INTO pg_temp._eh_release_proof VALUES "+values+";"
 ];
 if(synthetic)sql.push(
  "INSERT INTO private.exam_prep_extra_hard_tasks_v1(task_key,program_version_id,bank_version,component_code,primary_skill_code,official_section,book_map,title_i18n,prompt_i18n,solution_i18n,exact_answer,source_kind,qa_math,qa_languages,qa_technical,lifecycle_status,content_sha256)",
  "SELECT e.id,p.id,'"+BANK+"',e.component,CASE WHEN e.component='P1' THEN 'P1-QUA-01' ELSE 'P5-GEO-01' END,'CI TEST','CI TEST',",
  "jsonb_build_object('en','CI TEST','ru','CI TEST','uz','CI TEST'),",
  "jsonb_build_object('en','CI TEST 1+1','ru','CI TEST 1+1','uz','CI TEST 1+1'),",
  "jsonb_build_object('en','CI TEST 1+1=2','ru','CI TEST 1+1=2','uz','CI TEST 1+1=2'),",
  "'CI TEST 2','iclub_original','approved','approved','approved','approved',e.sha",
  "FROM pg_temp._eh_release_proof e CROSS JOIN private.exam_prep_program_versions p",
  "WHERE p.program_key='math_as_p1_p5' AND p.version_key='p1_p5_canonical_v1_0' AND p.status='active';"
 );
 sql.push(
  "DO $verify$ BEGIN",
  "IF (SELECT count(*) FROM pg_temp._eh_release_proof)<>42",
  "OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"')<>42",
  "OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' AND component_code='P1')<>24",
  "OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' AND component_code='P5')<>18",
  "OR EXISTS(SELECT 1 FROM pg_temp._eh_release_proof e LEFT JOIN private.exam_prep_extra_hard_tasks_v1 t ON t.task_key=e.id",
  " WHERE t.task_key IS NULL OR t.content_sha256 IS DISTINCT FROM e.sha OR t.bank_version IS DISTINCT FROM '"+BANK+"'",
  " OR t.component_code IS DISTINCT FROM e.component OR t.lifecycle_status IS DISTINCT FROM 'approved'",
  " OR t.qa_math IS DISTINCT FROM 'approved' OR t.qa_languages IS DISTINCT FROM 'approved' OR t.qa_technical IS DISTINCT FROM 'approved'",
  " OR t.published_at IS NOT NULL)",
  "OR EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_attempts_v1 a JOIN private.exam_prep_extra_hard_tasks_v1 t ON t.task_key=a.task_key WHERE t.bank_version<>'"+BANK+"')",
  "THEN RAISE EXCEPTION 'Extra Hard release: source, content QA, or prior history drift'; END IF;",
  "END $verify$;",
  "UPDATE private.exam_prep_extra_hard_tasks_v1 SET lifecycle_status='published',published_at=now() WHERE bank_version='"+BANK+"' AND lifecycle_status='approved';",
  "UPDATE private.exam_prep_extra_hard_release_v1 SET bank_version='"+BANK+"',academic_approved=true,enabled=true,updated_at=now() WHERE program_key='math_as_p1_p5' AND bank_version='"+PRIOR+"' AND enabled=false AND academic_approved=false;",
  "DO $post$ BEGIN",
  "IF NOT EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5' AND bank_version='"+BANK+"' AND enabled=true AND academic_approved=true)",
  "OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' AND lifecycle_status='published' AND published_at IS NOT NULL)<>42",
  "THEN RAISE EXCEPTION 'Extra Hard release post-verification failed'; END IF;",
  "END $post$;",
  "SELECT '"+(synthetic?"CI_RELEASE_ROLLBACK_PASS":"PRIVATE_FULL42_RELEASE_COMMITTED")+"' AS verified;",
  synthetic?"ROLLBACK;":"COMMIT;"
 );
 const run=spawnSync("psql",["-X","-q","-t","-A","-v","ON_ERROR_STOP=1"],{env,encoding:"utf8",input:sql.join("\n"),maxBuffer:1500000});
 if(run.error)throw run.error;
 const witness=synthetic?"CI_RELEASE_ROLLBACK_PASS":"PRIVATE_FULL42_RELEASE_COMMITTED";
 if(run.status!==0||!String(run.stdout).includes(witness))
  throw new Error("Extra Hard release conditions failed; SQL transaction not approved (protected source not printed)");
 if(synthetic){
  const after=sqlRead(snapSql,env);
  assert.equal(after,before,"Synthetic release altered learner/private bank state");
  console.log("EXTRA HARD FULL42 PUBLIC RELEASE GATE ROLLBACK PASS: 42 CI-only tasks, switch and publish reverted, no progress writes");
 }else console.log("Extra Hard Full42 release completed only after explicit owner GO and verified private source.");
}
try{
 assert(["publish","dry-run-isolated"].includes(MODE),"Usage: publish /absolute/private/full42.json or dry-run-isolated");
 if(MODE==="dry-run-isolated")publish(syntheticExpected(),true);
 else{
  assert(process.env.ICLUB_EXTRAHARD_V3_PUBLISH_GO==="OWNER_APPROVED_PUBLIC_MATH_EXTRA_HARD_42",
   "Distinct architect PUBLIC GO required; staging GO alone never publishes");
  assert(process.env.PGHOST&&process.env.PGDATABASE&&process.env.PGUSER,
   "Explicit release DB target required");
  assert(process.env.ICLUB_EXTRAHARD_V3_RELEASE_TARGET===process.env.PGDATABASE,
   "Named release target must equal actual database");
  assert(process.env.ICLUB_EXTRAHARD_V3_RELEASE_CONFIRM==="PUBLISH_VERIFIED_42_MATH_ONLY",
   "Second release confirmation required");
  publish(privateExpected(process.argv[3]),false);
 }
}catch(e){console.error("Extra Hard release gate refused:",e.message);process.exitCode=1;}
