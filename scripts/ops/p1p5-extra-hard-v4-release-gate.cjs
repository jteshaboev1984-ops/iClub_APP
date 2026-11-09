#!/usr/bin/env node
"use strict";
/*
 * V4 ONLY: guarded publication from the already-private 42-task candidate.
 * Real publish REQUIRES separate owner GO, exact V4 source and 42 independently
 * reviewed SHA-anchored approvals. Does not publish a draft automatically.
 * CI uses 42 synthetically generated 1+1 tasks and TRANSACTION ROLLBACK.
 * Neither the original questions nor answer keys belong in Git/CI/logs.
 */
const assert=require("node:assert/strict");
const fs=require("node:fs"),path=require("node:path"),os=require("node:os");
const crypto=require("node:crypto");
const {spawnSync,execFileSync}=require("node:child_process");
const MODE=process.argv[2];
const BANK="math-extra-hard-2026-11-full-v4";
const PRIOR="math-extra-hard-2026-11-original-v2";
const SOURCE_SHA="8f9d8aec32da6de43e9415f8ab2965b8d425809bc2e849e6e3d1f4a1ee612a88";
const KEYS=["task_key","bank_version","component_code","primary_skill_code",
 "official_section","book_map","title_i18n","prompt_i18n","solution_i18n","exact_answer"];
const sha=x=>crypto.createHash("sha256").update(x).digest("hex");
function stable(x){
 if(Array.isArray(x))return "["+x.map(stable).join(",")+"]";
 if(x&&typeof x==="object")return "{"+Object.keys(x).sort().map(k=>JSON.stringify(k)+":"+stable(x[k])).join(",")+"}";
 return JSON.stringify(x);
}
function source(p){
 assert(p,"Private V4 JSON path required");
 const abs=path.resolve(p);
 assert(!abs.startsWith(path.resolve(__dirname,"..","..")+path.sep),
  "No real private source in public repository");
 const bytes=fs.readFileSync(abs);
 assert.equal(sha(bytes),SOURCE_SHA,"V4 source SHA mismatch");
 const b=JSON.parse(bytes.toString("utf8"));
 assert(b.program_key==="math_as_p1_p5"&&b.program_version_key==="p1_p5_canonical_v1_0");
 assert(b.bank_version===BANK&&b.release_enabled===false&&b.academic_approved===false);
 assert(Array.isArray(b.tasks)&&b.tasks.length===42);
 const seen=new Set(),group=new Map(),count={P1:0,P5:0};
 for(const t of b.tasks){
  assert(/^EH26-P[15]-[A-Z]{3}-\\d{2}-\\d{2}$/.test(t.task_key));
  assert(!seen.has(t.task_key));seen.add(t.task_key);
  assert(t.bank_version===BANK&&t.source_kind==="iclub_original");
  assert(["P1","P5"].includes(t.component_code));
  assert(t.primary_skill_code.startsWith(t.component_code+"-"));
  assert(t.lifecycle_status==="draft"&&["qa_math","qa_languages","qa_technical"].every(k=>t[k]==="pending"),
   "V4 source must remain versioned and pending until separately approved");
  for(const f of ["title_i18n","prompt_i18n","solution_i18n"])
   for(const l of ["en","ru","uz"])assert(typeof t[f]?.[l]==="string"&&t[f][l].trim().length>10);
  const canonical={};for(const k of KEYS)canonical[k]=t[k];
  assert.equal(sha(Buffer.from(stable(canonical),"utf8")),t.content_sha256);
  count[t.component_code]++;
  const g=t.component_code==="P1"?t.official_section.slice(0,3):
   t.primary_skill_code.startsWith("P5-GEO")?"5.4G":
   t.primary_skill_code.startsWith("P5-BIN")?"5.4B":t.official_section.slice(0,3);
  group.set(g,(group.get(g)||0)+1);
 }
 assert(count.P1===24&&count.P5===18&&group.size===14&&[...group.values()].every(n=>n===3));
 return b.tasks;
}
function reviewManifest(p,tasks){
 assert(p,"Missing separate V4 individual academic review manifest");
 const abs=path.resolve(p);
 assert(!abs.startsWith(path.resolve(__dirname,"..","..")+path.sep));
 const bytes=fs.readFileSync(abs),pin=String(process.env.ICLUB_EXTRAHARD_V4_REVIEW_SHA256||"");
 assert(/^[0-9a-f]{64}$/.test(pin)&&sha(bytes)===pin,"Unpinned review document");
 const m=JSON.parse(bytes.toString("utf8"));
 assert(m.bank_version===BANK&&m.source_sha256===SOURCE_SHA&&m.decision==="approve");
 assert(typeof m.reviewer==="string"&&m.reviewer.trim().length>=3);
 assert(typeof m.reviewed_at==="string"&&Number.isFinite(Date.parse(m.reviewed_at)));
 assert(m.items?.length===42,"Review every V4 task independently");
 const byId=new Map(tasks.map(t=>[t.task_key,t.content_sha256])),seen=new Set();
 for(const r of m.items){
  assert(byId.has(r.task_key)&&!seen.has(r.task_key)&&byId.get(r.task_key)===r.content_sha256);
  seen.add(r.task_key);
  assert(r.difficulty==="extra_hard"&&r.qa_math==="approved"&&
   r.qa_languages==="approved"&&r.qa_technical==="approved"&&
   typeof r.difficulty_evidence==="string"&&r.difficulty_evidence.trim().length>=12);
 }
 assert(seen.size===42);
}
function dummyTasks(){
 assert(process.env.CI==="true"&&process.env.P1P5_E2E_ISOLATED==="true"&&
  process.env.PGHOST==="127.0.0.1"&&process.env.PGPORT==="5432"&&
  process.env.PGDATABASE==="postgres"&&process.env.PGUSER==="postgres");
 const tasks=[];
 for(const c of ["P1","P5"])for(let i=1;i<=(c==="P1"?24:18);i++){
  const id="CI-EH-V4-"+c+"-"+String(i).padStart(2,"0");
  const t={task_key:id,bank_version:BANK,component_code:c,
   primary_skill_code:c==="P1"?"P1-QUA-01":"P5-GEO-01",
   official_section:"CI TEST",book_map:"CI TEST",
   title_i18n:{en:"CI 1+1",ru:"CI 1+1",uz:"CI 1+1"},
   prompt_i18n:{en:"CI 1+1 synthetic",ru:"CI 1+1 synthetic",uz:"CI 1+1 synthetic"},
   solution_i18n:{en:"CI 1+1 = 2",ru:"CI 1+1 = 2",uz:"CI 1+1 = 2"},
   exact_answer:"CI answer 2"};
  const x={};for(const k of KEYS)x[k]=t[k];
  t.content_sha256=sha(Buffer.from(stable(x),"utf8"));
  tasks.push(t);
 }
 return tasks;
}
function readSnapshot(env){
 const sql="SELECT (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1)||'|'||(SELECT count(*) FROM private.exam_prep_extra_hard_attempts_v1)||'|'||(SELECT count(*) FROM private.exam_prep_sessions)||'|'||(SELECT bank_version||':'||enabled||':'||academic_approved FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5')";
 return execFileSync("psql",["-X","-At","-v","ON_ERROR_STOP=1","-c",sql],{encoding:"utf8",env}).trim();
}
function publish(tasks,synthetic,negative){
 assert(tasks.length===42);
 const env={...process.env,...(synthetic?{PGOPTIONS:"-c iclub.e2e_isolated=true"}:{})};
 const before=synthetic?readSnapshot(env):null;
 if(synthetic)assert(before.includes(PRIOR+":false:false")&&before.startsWith("0|0|"));
 const dir=fs.mkdtempSync(path.join(os.tmpdir(),"iclub-eh-v4-release-"));
 const file=path.join(dir,"protected_expected.csv");
 fs.writeFileSync(file,tasks.map(t=>'"'+JSON.stringify(t).replace(/"/g,'""')+'"').join("\n")+"\n",{mode:0o600});
 const fp=file.replace(/'/g,"''");
 const sql=[
  "BEGIN;","SET LOCAL lock_timeout='3s';","SET LOCAL statement_timeout='40s';",
  "DO $pre$ BEGIN",
  "IF (SELECT count(*) FROM private.exam_prep_program_versions WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active')<>1",
  "OR NOT EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5' AND bank_version='"+PRIOR+"' AND enabled=false AND academic_approved=false)",
  "THEN RAISE EXCEPTION 'V4 wrong original disabled release/program'; END IF;",
  synthetic?"IF current_database()<>'postgres' OR current_setting('server_version_num')::int<170000 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true' OR (SELECT count(*) FROM auth.users)<>2 OR (SELECT count(*) FROM public.users)<>2 THEN RAISE EXCEPTION 'V4 refuses non-disposable CI'; END IF;":"",
  "END $pre$;",
  "CREATE TEMP TABLE _v4_source(raw text NOT NULL) ON COMMIT DROP;",
  "\\copy pg_temp._v4_source(raw) FROM '"+fp+"' WITH (FORMAT csv)"
 ];
 if(synthetic)sql.push(
  "INSERT INTO private.exam_prep_extra_hard_tasks_v1(task_key,program_version_id,bank_version,component_code,primary_skill_code,official_section,book_map,title_i18n,prompt_i18n,solution_i18n,exact_answer,source_kind,qa_math,qa_languages,qa_technical,lifecycle_status,content_sha256)",
  "SELECT x.raw::jsonb->>'task_key',p.id,x.raw::jsonb->>'bank_version',x.raw::jsonb->>'component_code',x.raw::jsonb->>'primary_skill_code',x.raw::jsonb->>'official_section',x.raw::jsonb->>'book_map',x.raw::jsonb->'title_i18n',x.raw::jsonb->'prompt_i18n',x.raw::jsonb->'solution_i18n',x.raw::jsonb->>'exact_answer','iclub_original',",
  "'"+(negative==="pending"?"pending":"approved")+"','"+(negative==="pending"?"pending":"approved")+"','"+(negative==="pending"?"pending":"approved")+"','"+(negative==="pending"?"draft":"approved")+"',x.raw::jsonb->>'content_sha256'",
  "FROM pg_temp._v4_source x CROSS JOIN private.exam_prep_program_versions p WHERE p.program_key='math_as_p1_p5' AND p.version_key='p1_p5_canonical_v1_0' AND p.status='active';"
 );
 sql.push(
  "DO $lock$ BEGIN PERFORM 1 FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5' FOR UPDATE; PERFORM 1 FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' FOR UPDATE; END $lock$;"
 );
 if(synthetic&&negative==="tamper")sql.push(
  "UPDATE private.exam_prep_extra_hard_tasks_v1 SET prompt_i18n=jsonb_set(prompt_i18n,'{en}',to_jsonb('CI test tampered'::text)) WHERE task_key='"+tasks[0].task_key+"';");
 sql.push(
  "DO $gate$ BEGIN",
  "IF (SELECT count(*) FROM pg_temp._v4_source)<>42 OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"')<>42",
  "OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' AND component_code='P1')<>24",
  "OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' AND component_code='P5')<>18",
  "OR EXISTS(SELECT 1 FROM pg_temp._v4_source s LEFT JOIN private.exam_prep_extra_hard_tasks_v1 t ON t.task_key=s.raw::jsonb->>'task_key'",
  " WHERE t.task_key IS NULL OR t.content_sha256 IS DISTINCT FROM s.raw::jsonb->>'content_sha256' OR t.bank_version IS DISTINCT FROM '"+BANK+"'",
  " OR t.component_code IS DISTINCT FROM s.raw::jsonb->>'component_code' OR t.primary_skill_code IS DISTINCT FROM s.raw::jsonb->>'primary_skill_code'",
  " OR t.official_section IS DISTINCT FROM s.raw::jsonb->>'official_section' OR t.book_map IS DISTINCT FROM s.raw::jsonb->>'book_map'",
  " OR t.title_i18n IS DISTINCT FROM s.raw::jsonb->'title_i18n' OR t.prompt_i18n IS DISTINCT FROM s.raw::jsonb->'prompt_i18n'",
  " OR t.solution_i18n IS DISTINCT FROM s.raw::jsonb->'solution_i18n' OR t.exact_answer IS DISTINCT FROM s.raw::jsonb->>'exact_answer'",
  " OR t.qa_math IS DISTINCT FROM 'approved' OR t.qa_languages IS DISTINCT FROM 'approved' OR t.qa_technical IS DISTINCT FROM 'approved'",
  " OR t.lifecycle_status IS DISTINCT FROM 'approved' OR t.published_at IS NOT NULL)",
  "THEN RAISE EXCEPTION 'V4 approved source/DB fidelity mismatch'; END IF;",
  "END $gate$;",
  "UPDATE private.exam_prep_extra_hard_tasks_v1 SET lifecycle_status='published',published_at=now() WHERE bank_version='"+BANK+"' AND lifecycle_status='approved';",
  "UPDATE private.exam_prep_extra_hard_release_v1 SET bank_version='"+BANK+"',enabled=true,academic_approved=true,updated_at=now() WHERE program_key='math_as_p1_p5' AND bank_version='"+PRIOR+"' AND enabled=false AND academic_approved=false;",
  "DO $post$ BEGIN IF (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' AND lifecycle_status='published' AND published_at IS NOT NULL)<>42 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_release_v1 WHERE bank_version='"+BANK+"' AND enabled=true AND academic_approved=true) THEN RAISE EXCEPTION 'V4 atomic publication postcondition failed'; END IF; END $post$;",
  "SELECT 'V4_RELEASE_PROOF_OK';",
  synthetic?"ROLLBACK;":"COMMIT;"
 );
 try {
  const r=spawnSync("psql",["-X","-q","-t","-A","-v","ON_ERROR_STOP=1"],{env,encoding:"utf8",input:sql.join("\n"),maxBuffer:2000000});
  if(r.error)throw r.error;
  if(synthetic&&negative){
   assert(r.status!==0&&!r.stdout.includes("V4_RELEASE_PROOF_OK"),"Unsafe V4 case published");
   assert(String(r.stderr).includes("V4 approved source/DB fidelity mismatch"),"Wrong denial reason");
   assert.equal(readSnapshot(env),before,"Negative V4 test modified source state");
   console.log("V4 RELEASE "+negative.toUpperCase()+" DENIED: exact source fidelity or pending approval, ROLLBACK");
  }else {
   assert(r.status===0&&r.stdout.includes("V4_RELEASE_PROOF_OK"),
    "V4 release refused; no protected source or SQL dumped");
   if(synthetic){
    assert.equal(readSnapshot(env),before,"V4 transaction did not rollback");
    console.log("V4 ATOMIC RELEASE ROLLBACK PASS: 42 synthetic approved, 24 P1/18 P5, no learner changes");
   }else console.log("V4 reviewed source published after explicit owner authorization");
  }
 } finally {fs.rmSync(dir,{recursive:true,force:true});}
}
try{
 assert(["publish","dry-run-isolated","dry-run-tampered-isolated","dry-run-pending-isolated"].includes(MODE));
 if(MODE!=="publish"){
  publish(dummyTasks(),true,MODE==="dry-run-tampered-isolated"?"tamper":MODE==="dry-run-pending-isolated"?"pending":null);
 }else{
  assert(process.env.ICLUB_EXTRAHARD_V4_PUBLISH_GO==="OWNER_APPROVED_PUBLIC_MATH_V4_42",
   "Distinct architect V4 PUBLIC GO missing");
  const ref="mmmduffgpvwjdpruzikw";
  assert(process.env.ICLUB_EXTRAHARD_V4_TARGET_PROJECT_REF===ref&&
   process.env.PGHOST==="db."+ref+".supabase.co"&&process.env.PGPORT==="5432"&&
   process.env.PGDATABASE==="postgres"&&process.env.PGUSER==="postgres"&&
   process.env.ICLUB_EXTRAHARD_V4_RELEASE_TARGET===ref+"/postgres"&&
   process.env.ICLUB_EXTRAHARD_V4_RELEASE_CONFIRM==="PUBLISH_REVIEWED_V4_42_MATH_ONLY",
   "Exact existing target and separate owner authorization required");
  const tasks=source(process.argv[3]);
  reviewManifest(process.argv[4],tasks);
  publish(tasks,false,null);
 }
}catch(e){console.error("Protected V4 release refused:",e.message);process.exitCode=1;}
