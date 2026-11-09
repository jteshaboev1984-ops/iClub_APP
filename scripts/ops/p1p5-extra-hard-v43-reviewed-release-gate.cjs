#!/usr/bin/env node
"use strict";
// V4.3 ALREADY STAGED: publish only after specific review and owner PUBLIC GO.
// Synthetic CI uses fully disposable data and always rolls back.
// Protected question prompts, worked solutions and answer keys never enter Git.
const assert=require("node:assert/strict");
const fs=require("node:fs");
const crypto=require("node:crypto");
const path=require("node:path");
const os=require("node:os");
const {spawnSync,execFileSync}=require("node:child_process");
const MODE=process.argv[2];
const BANK="math-extra-hard-2026-11-full-v4";
const PRIOR="math-extra-hard-2026-11-original-v2";
const SOURCE_SHA="42c16a0d81cad35576b927e0f8c412650b045c25c1cfbcb71d86e20dfda2e090";
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
  assert(t.qa_math==="pending"&&t.qa_languages==="pending"&&t.qa_technical==="pending");
  assert(t.lifecycle_status==="draft");
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
// Current owner-private V4.3 review is on HOLD. This format is deliberately
// distinct from the existing pending report; never fabricate 42 approvals.
function confirmReview(file,expected){
 assert(file,"42-item reviewed V4.3 manifest missing");
 const abs=path.resolve(file),repo=path.resolve(__dirname,"..","..")+path.sep;
 assert(!abs.startsWith(repo),"Review document must be owner-private");
 const bytes=fs.readFileSync(abs),pin=String(process.env.ICLUB_EXTRAHARD_V43_REVIEW_SHA256||"");
 assert(/^[a-f0-9]{64}$/.test(pin)&&hash(bytes)===pin,"Review source SHA mismatch");
 const r=JSON.parse(bytes.toString("utf8"));
 assert(r.bank_version===BANK&&r.source_sha256===SOURCE_SHA&&r.decision==="approve");
 assert(typeof r.reviewed_by==="string"&&r.reviewed_by.length>=3);
 assert(typeof r.reviewed_at==="string"&&Number.isFinite(Date.parse(r.reviewed_at)));
 assert(Array.isArray(r.items)&&r.items.length===42);
 const ids=new Map(expected.map(x=>[x.id,x.sha])),seen=new Set();
 for(const row of r.items){
  assert(row&&ids.has(row.task_key)&&!seen.has(row.task_key));
  seen.add(row.task_key);
  assert(row.content_sha256===ids.get(row.task_key));
  assert(row.qa_math==="approved"&&row.qa_languages==="approved"&&row.qa_technical==="approved");
  assert(row.difficulty==="extra_hard"&&typeof row.difficulty_rationale==="string"&&row.difficulty_rationale.trim().length>=12);
 }
 assert(seen.size===42);
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
function publish(expected,synthetic,injectTamper=false,injectPartial=false){
 const safe=x=>{assert(/^[A-Za-z0-9_.-]+$/.test(x));return x;};
 const values=expected.map(x=>"('"+safe(x.id)+"','"+safe(x.sha)+"','"+safe(x.component)+"')").join(",");
 assert(expected.length===42);
 const env={...process.env,...(synthetic?{PGOPTIONS:"-c iclub.e2e_isolated=true"}:{})};
 const snapSql="SELECT (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1)||'|'||(SELECT count(*) FROM private.exam_prep_extra_hard_attempts_v1)||'|'||(SELECT count(*) FROM private.exam_prep_sessions)||'|'||(SELECT bank_version||':'||enabled||':'||academic_approved FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5')";
 const before=synthetic?sqlRead(snapSql,env):null;
 if(synthetic)assert(before.includes(PRIOR+":false:false")&&before.startsWith("0|0|"),
  "Synthetic release expected zero existing private tasks or attempts");
 // Authoritative source content reaches only this process, a mode-0600 CSV,
 // and the local psql COPY. No protected answers enter Git or CI logs.
 assert(expected.every(e=>e.fields && sourceFields.every(k=>
  Object.prototype.hasOwnProperty.call(e.fields,k))),"Authoritative task fields missing");
 const temp=fs.mkdtempSync(path.join(os.tmpdir(),"iclub-eh-release-proof-"));
 const proof=path.join(temp,"approved-source.csv");
 const lines=expected.map(e=>'"'+JSON.stringify(e.fields).replace(/"/g,'""')+'"');
 fs.writeFileSync(proof,lines.join("\n")+"\n",{mode:0o600,encoding:"utf8"});
 const copyPath=proof.replace(/'/g,"''");
 try{
 const sql=[
  "BEGIN;","SET LOCAL lock_timeout='3s';","SET LOCAL statement_timeout='30s';",
  "DO $pre$ BEGIN",
  "IF NOT EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_release_v1",
  " WHERE program_key='math_as_p1_p5' AND bank_version='"+PRIOR+"' AND enabled=false AND academic_approved=false)",
  "OR (SELECT count(*) FROM private.exam_prep_program_versions WHERE program_key='math_as_p1_p5'",
  " AND version_key='p1_p5_canonical_v1_0' AND status='active')<>1",
  "THEN RAISE EXCEPTION 'Extra Hard release: wrong prior disabled bank/program'; END IF;",
  "IF position('''official_section''' in pg_get_functiondef('public.get_my_exam_prep_extra_hard_catalog_safe_v1(text,text)'::regprocedure))=0",
  "OR position('''attempt_status''' in pg_get_functiondef('public.get_my_exam_prep_extra_hard_catalog_safe_v1(text,text)'::regprocedure))=0",
  "OR position('''total_count''' in pg_get_functiondef('public.get_my_exam_prep_extra_hard_catalog_safe_v1(text,text)'::regprocedure))=0",
  "OR has_function_privilege('anon','public.get_my_exam_prep_extra_hard_catalog_safe_v1(text,text)','EXECUTE')",
  "THEN RAISE EXCEPTION 'V4.3 catalog topic/progress migration missing or unsafe'; END IF;",
  synthetic?"IF current_database()<>'postgres' OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true' OR (SELECT count(*) FROM auth.users)<>2 OR (SELECT count(*) FROM public.users)<>2 THEN RAISE EXCEPTION 'Not a disposable CI source'; END IF;":"",
  "END $pre$;",
  "CREATE TEMP TABLE _eh_release_proof(id text PRIMARY KEY,sha text NOT NULL,component text NOT NULL) ON COMMIT DROP;",
  "INSERT INTO pg_temp._eh_release_proof VALUES "+values+";",
  "CREATE TEMP TABLE _eh_release_expected(raw text NOT NULL) ON COMMIT DROP;",
  "\\copy pg_temp._eh_release_expected(raw) FROM '"+copyPath+"' WITH (FORMAT csv)"
 ];
 if(synthetic)sql.push(
  "INSERT INTO private.exam_prep_extra_hard_tasks_v1(task_key,program_version_id,bank_version,component_code,primary_skill_code,official_section,book_map,title_i18n,prompt_i18n,solution_i18n,exact_answer,source_kind,qa_math,qa_languages,qa_technical,lifecycle_status,content_sha256)",
  "SELECT e.id,p.id,'"+BANK+"',e.component,CASE WHEN e.component='P1' THEN 'P1-QUA-01' ELSE 'P5-GEO-01' END,'CI TEST','CI TEST',",
  "jsonb_build_object('en','CI TEST','ru','CI TEST','uz','CI TEST'),",
  "jsonb_build_object('en','CI TEST 1+1','ru','CI TEST 1+1','uz','CI TEST 1+1'),",
  "jsonb_build_object('en','CI TEST 1+1=2','ru','CI TEST 1+1=2','uz','CI TEST 1+1=2'),",
  "'CI TEST 2','iclub_original','pending','pending','pending','draft',e.sha",
  "FROM pg_temp._eh_release_proof e CROSS JOIN private.exam_prep_program_versions p",
  "WHERE p.program_key='math_as_p1_p5' AND p.version_key='p1_p5_canonical_v1_0' AND p.status='active';"
 );
 // Hold row-level locks until the same transaction publishes or rolls back.
 sql.push("DO $lock$ DECLARE k text; BEGIN",
  "PERFORM 1 FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5' FOR UPDATE;",
  "FOR k IN SELECT task_key FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' FOR UPDATE LOOP NULL; END LOOP;",
  "END $lock$;");
 if(synthetic&&injectPartial)
  sql.push("UPDATE private.exam_prep_extra_hard_tasks_v1 SET qa_math='approved' WHERE task_key='"+safe(expected[0].id)+"';");
 if(synthetic&&injectTamper){
  // Mutate a real DB prompt while keeping its stored hash unchanged.
  sql.push("UPDATE private.exam_prep_extra_hard_tasks_v1 SET prompt_i18n=jsonb_set(prompt_i18n,'{en}',to_jsonb('CI TEST: changed in database'::text)) "+
   "WHERE task_key='"+safe(expected[0].id)+"';");
 }
 sql.push(
  "DO $verify$ BEGIN",
  "IF (SELECT count(*) FROM pg_temp._eh_release_proof)<>42",
  "OR (SELECT count(*) FROM pg_temp._eh_release_expected)<>42",
  "OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"')<>42",
  "OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' AND component_code='P1')<>24",
  "OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' AND component_code='P5')<>18",
  "OR EXISTS(SELECT 1 FROM pg_temp._eh_release_proof e LEFT JOIN private.exam_prep_extra_hard_tasks_v1 t ON t.task_key=e.id",
  " WHERE t.task_key IS NULL OR t.content_sha256 IS DISTINCT FROM e.sha OR t.bank_version IS DISTINCT FROM '"+BANK+"'",
  " OR t.component_code IS DISTINCT FROM e.component OR t.lifecycle_status IS DISTINCT FROM 'draft'",
  " OR t.qa_math IS DISTINCT FROM 'pending' OR t.qa_languages IS DISTINCT FROM 'pending' OR t.qa_technical IS DISTINCT FROM 'pending'",
  " OR t.published_at IS NOT NULL)",
  // The cached SHA field alone is not proof the ACTUAL DB content matches.
  "OR EXISTS(SELECT 1 FROM pg_temp._eh_release_expected src",
  " LEFT JOIN private.exam_prep_extra_hard_tasks_v1 t ON t.task_key=(src.raw::jsonb)->>'task_key'",
  " WHERE t.task_key IS NULL OR t.bank_version IS DISTINCT FROM (src.raw::jsonb)->>'bank_version'",
  " OR t.component_code IS DISTINCT FROM (src.raw::jsonb)->>'component_code'",
  " OR t.primary_skill_code IS DISTINCT FROM (src.raw::jsonb)->>'primary_skill_code'",
  " OR t.official_section IS DISTINCT FROM (src.raw::jsonb)->>'official_section'",
  " OR t.book_map IS DISTINCT FROM (src.raw::jsonb)->>'book_map'",
  " OR t.title_i18n IS DISTINCT FROM (src.raw::jsonb)->'title_i18n'",
  " OR t.prompt_i18n IS DISTINCT FROM (src.raw::jsonb)->'prompt_i18n'",
  " OR t.solution_i18n IS DISTINCT FROM (src.raw::jsonb)->'solution_i18n'",
  " OR t.exact_answer IS DISTINCT FROM (src.raw::jsonb)->>'exact_answer'",
  " OR t.source_kind IS DISTINCT FROM 'iclub_original'",
  " OR NOT EXISTS(SELECT 1 FROM private.exam_prep_program_versions p WHERE p.id=t.program_version_id",
  "  AND p.program_key='math_as_p1_p5' AND p.version_key='p1_p5_canonical_v1_0' AND p.status='active'))",
  "OR EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_attempts_v1 a JOIN private.exam_prep_extra_hard_tasks_v1 t ON t.task_key=a.task_key WHERE t.bank_version='"+BANK+"')",
  "THEN RAISE EXCEPTION 'Extra Hard release: staged source content mismatch or prior history drift'; END IF;",
  "END $verify$;",
  "UPDATE private.exam_prep_extra_hard_tasks_v1 SET qa_math='approved',qa_languages='approved',qa_technical='approved',lifecycle_status='published',published_at=now() WHERE bank_version='"+BANK+"' AND lifecycle_status='draft' AND qa_math='pending' AND qa_languages='pending' AND qa_technical='pending';",
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
 if(synthetic&&injectPartial){
  assert(run.status!==0&&!String(run.stdout).includes("CI_RELEASE_ROLLBACK_PASS"),
   "Premature partial QA unexpectedly published");
  assert(String(run.stderr).includes("Extra Hard release: staged source content mismatch"),
   "Partial approval guard did not fire");
  assert.equal(sqlRead(snapSql,env),before,"Partial QA rollback changed records");
  console.log("EXTRA HARD V4.3 PARTIAL QA DENIED: no release, no student writes");
  return;
 }
 if(synthetic&&injectTamper){
  assert(run.status!==0&&!String(run.stdout).includes("CI_RELEASE_ROLLBACK_PASS"),
   "Mutated staged content incorrectly published in disposable test");
  assert(String(run.stderr).includes("Extra Hard release: staged source content mismatch"),
   "Expected source-fidelity guard did not reject mutated DB content");
  assert.equal(sqlRead(snapSql,env),before,
   "Failed synthetic tamper test did not roll back");
  console.log("EXTRA HARD FULL42 DB CONTENT TAMPER DENIED: stale hash rejected, all rows ROLLED BACK");
  return;
 }
 const witness=synthetic?"CI_RELEASE_ROLLBACK_PASS":"PRIVATE_V43_RELEASE_COMMITTED";
 if(run.status!==0||!String(run.stdout).includes(witness))
  throw new Error("Extra Hard release conditions failed; SQL transaction not approved (protected source not printed)");
 if(synthetic){
  const after=sqlRead(snapSql,env);
  assert.equal(after,before,"Synthetic release altered learner/private bank state");
  console.log("EXTRA HARD FULL42 PUBLIC RELEASE GATE ROLLBACK PASS: 42 CI-only tasks, switch and publish reverted, no progress writes");
 }else console.log("Extra Hard Full42 release completed only after explicit owner GO and verified private source.");
 }finally{
  fs.rmSync(temp,{recursive:true,force:true});
 }
}
try{
 assert(["publish","check-private","dry-run-isolated","dry-run-tampered-isolated","dry-run-partial-qa-isolated"].includes(MODE),
  "Expected check-private V4.3.json, dry-run-isolated or publish V4.3.json reviewed.json");
 if(MODE==="dry-run-isolated"||MODE==="dry-run-tampered-isolated"||MODE==="dry-run-partial-qa-isolated")
  publish(syntheticExpected(),true,MODE==="dry-run-tampered-isolated",MODE==="dry-run-partial-qa-isolated");
 else if(MODE==="check-private"){
  privateExpected(process.argv[3]);
  console.log("EXTRA HARD V4.3 PRIVATE SOURCE PASS: 42 pending tasks, 24 P1/18 P5");
 }else{
  assert(process.env.ICLUB_EXTRAHARD_V43_PUBLISH_GO==="OWNER_APPROVED_PUBLIC_MATH_V43_42",
   "Distinct owner PUBLIC GO missing");
  const ref="mmmduffgpvwjdpruzikw";
  assert(process.env.ICLUB_EXTRAHARD_V43_PROJECT_REF===ref&&
   process.env.PGHOST==="db."+ref+".supabase.co"&&
   process.env.PGDATABASE==="postgres"&&process.env.PGUSER==="postgres"&&process.env.PGPORT==="5432"&&
   process.env.ICLUB_EXTRAHARD_V43_TARGET===ref+"/postgres"&&
   process.env.ICLUB_EXTRAHARD_V43_RELEASE_CONFIRM==="PUBLISH_REVIEWED_42_MATH_V43",
   "Owner-confirmed existing iClub release target mismatch");
  const expected=privateExpected(process.argv[3]);
  confirmReview(process.argv[4],expected);
  publish(expected,false);
 }
}catch(e){console.error("V4.3 release gate refused:",e.message);process.exitCode=1;}
