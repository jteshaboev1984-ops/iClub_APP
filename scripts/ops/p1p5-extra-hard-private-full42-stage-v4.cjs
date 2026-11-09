#!/usr/bin/env node
'use strict';
// Owner-only protected source staging. No real prompts, solutions or keys in this file.
// V4 pending-only source staging. No published content, release switch, or learner writes.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const os=require('node:os');
const crypto=require('node:crypto');
const {spawnSync}=require('node:child_process');
const MODE=process.argv[2],INPUT=process.argv[3];
const BANK='math-extra-hard-2026-11-full-v4';
const PREVIOUS='math-extra-hard-2026-11-original-v2';
const SOURCE_SHA='2bfcfc8b5f961a4905788cc8cb3e33c6c72f663230c2681149bec5a3d0e56666';
const FIELDS=['task_key','bank_version','component_code','primary_skill_code','official_section',
 'book_map','title_i18n','prompt_i18n','solution_i18n','exact_answer'];
const hash=(x)=>crypto.createHash('sha256').update(x).digest('hex');
function stable(v){
 if(Array.isArray(v))return '['+v.map(stable).join(',')+']';
 if(v&&typeof v==='object')return '{'+Object.keys(v).sort().map(k=>JSON.stringify(k)+':'+stable(v[k])).join(',')+'}';
 return JSON.stringify(v);
}
function strand(t){
 if(t.component_code==='P1')return String(t.official_section).slice(0,3);
 if(t.primary_skill_code.startsWith('P5-GEO-'))return '5.4G';
 if(t.primary_skill_code.startsWith('P5-BIN-'))return '5.4B';
 return String(t.official_section).slice(0,3);
}
const EXPECTED=['1.1','1.2','1.3','1.4','1.5','1.6','1.7','1.8',
 '5.1','5.2','5.3','5.4G','5.4B','5.5'];
function validate(raw,synthetic){
 const actual=JSON.parse(raw.toString('utf8'));
 assert.equal(actual.format_version,'iclub.extra_hard.private_bank_v3');
 assert.equal(actual.program_key,'math_as_p1_p5');
 assert.equal(actual.program_version_key,'p1_p5_canonical_v1_0');
 assert.equal(actual.bank_version,BANK);
 assert.equal(actual.release_enabled,false);
 assert.equal(actual.academic_approved,false);
 assert(Array.isArray(actual.tasks)&&actual.tasks.length===42,'Need exactly 42 protected tasks');
 const seen=new Set(),groups=new Map(),textPrompts=new Set();
 let p1=0,p5=0,approved=0,draft=0;
 for(const t of actual.tasks){
  assert(t&&typeof t==='object');
  if(synthetic)assert(/^EH-CI-P[15]-/.test(t.task_key),'Only synthetic CI IDs are allowed');
  else assert(/^EH26-P[15]-[A-Z]{3}-\d{2}-\d{2}$/.test(t.task_key),'Invalid original task key');
  assert(!seen.has(t.task_key),'Duplicate original task keys');seen.add(t.task_key);
  assert(t.bank_version===BANK&&t.source_kind==='iclub_original');
  assert(t.component_code==='P1'||t.component_code==='P5');
  t.component_code==='P1'?p1++:p5++;
  assert(t.primary_skill_code.startsWith(t.component_code+'-'),'Skill belongs to different component');
  for(const key of ['title_i18n','prompt_i18n','solution_i18n']){
   assert(t[key]&&typeof t[key]==='object');
   assert.deepEqual(Object.keys(t[key]).sort(),['en','ru','uz']);
   for(const lang of ['en','ru','uz'])assert(typeof t[key][lang]==='string'&&
    t[key][lang].trim().length>=12&&t[key][lang].length<=10000,'Incomplete source language');
  }
  const p=t.prompt_i18n.en.normalize('NFKC').replace(/\s+/g,' ').trim().toLowerCase();
  assert(!textPrompts.has(p),'Repeated EN problem condition');textPrompts.add(p);
  if(synthetic){
   assert(t.prompt_i18n.en.startsWith('CI TEST:')&&t.solution_i18n.en.startsWith('CI TEST:'),
    'Never send genuine protected tasks to disposable CI');
  }
  // V4 has verified arithmetic but no independent difficulty/language sign-off.
  // Never elevate candidate status in the import path.
  assert(t.qa_math==='pending'&&t.qa_languages==='pending'&&t.qa_technical==='pending',
   'V4 academic/editorial status must remain pending');
  assert(t.lifecycle_status==='draft','V4 must remain draft');draft++;
  const item={};for(const key of FIELDS)item[key]=t[key];
  assert.equal(hash(Buffer.from(stable(item),'utf8')),t.content_sha256,
   'Protected content checksum mismatch');
  const g=strand(t);assert(EXPECTED.includes(g),'Extra Hard outside P1/P5 syllabus');
  groups.set(g,(groups.get(g)||0)+1);
 }
 assert.equal(p1,24);assert.equal(p5,18);
 assert.equal(approved,0);assert.equal(draft,42);
 assert.equal(groups.size,14);
 for(const g of EXPECTED)assert.equal(groups.get(g),3,'Missing syllabus strand '+g);
 return actual;
}
function source(){
 assert(INPUT,'Usage: (check|stage|dry-run-isolated) /absolute/private/full42.json');
 const absolute=path.resolve(INPUT);
 if(MODE!=='dry-run-isolated'){
  const repo=path.resolve(__dirname,'..','..')+path.sep;
  assert(!absolute.startsWith(repo),'Protected bank must remain outside public Git repository');
 }
 const raw=fs.readFileSync(absolute);
 if(MODE!=='dry-run-isolated')assert.equal(hash(raw),SOURCE_SHA,
  'Owner-private bank SHA mismatch; staged source must be reviewed/pinned');
 const bank=validate(raw,MODE==='dry-run-isolated');
 console.log('V4 FULL42 SOURCE VALID: 24 P1, 18 P5, 14 strands x3; 42 draft/pending; release OFF.');
 return bank;
}
function stage(bank,synthetic){
 if(synthetic){
  assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
   process.env.PGHOST==='127.0.0.1'&&process.env.PGDATABASE==='postgres'&&
   process.env.PGUSER==='postgres'&&process.env.PGPORT==='5432',
   'Disposable CI must use isolated local postgres and synthetic content');
 }else{
  // The production project is *never* a permitted staging target, even when
  // PGDATABASE happens to be "postgres" in both environments.
  assert(process.env.ICLUB_EXTRAHARD_V4_STAGE_GO==='OWNER_APPROVED_PRIVATE_V4_DRAFT_42',
   'Protected V4 stage requires owner-approved operation');
  const ref=String(process.env.ICLUB_EXTRAHARD_V4_STAGING_PROJECT_REF||'');
  assert(/^[a-z0-9]{20}$/.test(ref)&&ref!=='mmmduffgpvwjdpruzikw',
   'Refusing missing, invalid or production Supabase project ref');
  assert(process.env.PGHOST==='db.'+ref+'.supabase.co'&&
   process.env.PGUSER==='postgres'&&process.env.PGDATABASE==='postgres'&&
   process.env.PGPORT==='5432',
   'Private staging project host and database identity must match exactly');
  assert(process.env.ICLUB_EXTRAHARD_V4_STAGING_TARGET===ref+'/postgres',
   'Explicit non-production project/database confirmation required');
 }
 // Local temporary CSV is NEVER committed, exposed to the HTTP client, or logged.
 // PostgreSQL receives COPY FROM STDIN, rather than a logged SQL literal of the answer key.
 const temp=fs.mkdtempSync(path.join(os.tmpdir(),'iclub-eh-v4-'));
 const fixture=path.join(temp,'private_content_0600.ndjson');
 const lines=bank.tasks.map(t=>'\"'+JSON.stringify(t).replace(/\"/g,'\"\"')+'\"');
 fs.writeFileSync(fixture,lines.join('\n')+'\n',{mode:0o600,encoding:'utf8'});
 const actual=synthetic?'ROLLBACK':'COMMIT';
 const modeTag=synthetic?'EXTRA_HARD_V4_DRY_RUN_PASS':'EXTRA_HARD_V4_PRIVATE_DRAFT_STAGED_OFF';
 const sql=String.raw`BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='30s';
DO $pre$
DECLARE v text; BEGIN
 IF to_regclass('private.exam_prep_extra_hard_tasks_v1') IS NULL
  OR to_regclass('private.exam_prep_extra_hard_release_v1') IS NULL
  OR (SELECT count(*) FROM private.exam_prep_program_versions WHERE
     program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active')<>1
 THEN RAISE EXCEPTION 'Extra Hard V4 schema/program drift'; END IF;
 IF NOT EXISTS (SELECT 1 FROM private.exam_prep_extra_hard_release_v1
  WHERE program_key='math_as_p1_p5' AND bank_version='${PREVIOUS}'
   AND enabled=false AND academic_approved=false)
 THEN RAISE EXCEPTION 'Extra Hard V4 requires original disabled V2 bank'; END IF;
 IF EXISTS (SELECT 1 FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='${BANK}')
 OR EXISTS (SELECT 1 FROM private.exam_prep_extra_hard_attempts_v1 a
  JOIN private.exam_prep_extra_hard_tasks_v1 t ON t.task_key=a.task_key
  WHERE t.bank_version='${BANK}')
 THEN RAISE EXCEPTION 'Extra Hard V4 already populated; never overwrite old task/learner history'; END IF;
 IF current_setting('iclub.e2e_isolated',true)='true' AND
  (current_database()<>'postgres' OR current_setting('server_version_num')::int<170000
    OR (SELECT count(*) FROM public.users)<>2 OR (SELECT count(*) FROM auth.users)<>2)
 THEN RAISE EXCEPTION 'Extra Hard V4 disposable source mismatch'; END IF;
END $pre$;
CREATE TEMP TABLE _eh_v4_payload(raw text NOT NULL) ON COMMIT DROP;
\copy pg_temp._eh_v4_payload(raw) FROM '${fixture}' WITH (FORMAT csv)
DO $copied$ BEGIN
 IF (SELECT count(*) FROM pg_temp._eh_v4_payload)<>42
 THEN RAISE EXCEPTION 'Extra Hard V4 source copy count is not 42'; END IF;
END $copied$;
WITH entries AS (SELECT raw::jsonb AS t FROM pg_temp._eh_v4_payload),
 pgm AS (SELECT id FROM private.exam_prep_program_versions WHERE
  program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active')
INSERT INTO private.exam_prep_extra_hard_tasks_v1(
 task_key,program_version_id,bank_version,component_code,primary_skill_code,official_section,
 book_map,title_i18n,prompt_i18n,solution_i18n,exact_answer,source_kind,
 qa_math,qa_languages,qa_technical,lifecycle_status,content_sha256)
SELECT e.t->>'task_key',p.id,e.t->>'bank_version',e.t->>'component_code',
 e.t->>'primary_skill_code',e.t->>'official_section',e.t->>'book_map',
 e.t->'title_i18n',e.t->'prompt_i18n',e.t->'solution_i18n',e.t->>'exact_answer',
 e.t->>'source_kind',e.t->>'qa_math',e.t->>'qa_languages',e.t->>'qa_technical',
 e.t->>'lifecycle_status',e.t->>'content_sha256'
FROM entries e CROSS JOIN pgm p;
DO $post$
DECLARE v_approved int;v_draft int;BEGIN
 SELECT count(*) FILTER(WHERE lifecycle_status='approved'),
 count(*) FILTER(WHERE lifecycle_status='draft')
 INTO v_approved,v_draft FROM private.exam_prep_extra_hard_tasks_v1
 WHERE bank_version='${BANK}';
 IF v_approved<>0 OR v_draft<>42
  OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='${BANK}')<>42
  OR EXISTS (SELECT 1 FROM pg_temp._eh_v4_payload src
    LEFT JOIN private.exam_prep_extra_hard_tasks_v1 dst
     ON dst.task_key=(src.raw::jsonb)->>'task_key'
    WHERE dst.task_key IS NULL OR dst.bank_version<>'${BANK}'
      OR dst.content_sha256 IS DISTINCT FROM (src.raw::jsonb)->>'content_sha256'
      OR dst.lifecycle_status IS DISTINCT FROM (src.raw::jsonb)->>'lifecycle_status'
      OR dst.qa_languages IS DISTINCT FROM (src.raw::jsonb)->>'qa_languages'
      OR dst.qa_math IS DISTINCT FROM (src.raw::jsonb)->>'qa_math'
      OR dst.qa_technical IS DISTINCT FROM (src.raw::jsonb)->>'qa_technical'
      OR dst.component_code IS DISTINCT FROM (src.raw::jsonb)->>'component_code'
      OR dst.primary_skill_code IS DISTINCT FROM (src.raw::jsonb)->>'primary_skill_code'
      OR dst.official_section IS DISTINCT FROM (src.raw::jsonb)->>'official_section'
      OR dst.book_map IS DISTINCT FROM (src.raw::jsonb)->>'book_map'
      OR dst.title_i18n IS DISTINCT FROM (src.raw::jsonb)->'title_i18n'
      OR dst.prompt_i18n IS DISTINCT FROM (src.raw::jsonb)->'prompt_i18n'
      OR dst.solution_i18n IS DISTINCT FROM (src.raw::jsonb)->'solution_i18n'
      OR dst.exact_answer IS DISTINCT FROM (src.raw::jsonb)->>'exact_answer')
  OR EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_release_v1
    WHERE program_key='math_as_p1_p5' AND
     (bank_version<>'${PREVIOUS}' OR enabled OR academic_approved))
  OR EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_tasks_v1
    WHERE bank_version='${BANK}' AND lifecycle_status='published')
 THEN RAISE EXCEPTION 'Extra Hard V4 verification failed; transaction must rollback'; END IF;
END $post$;
SELECT '${modeTag}' AS verified;
${actual};
`;
 // Only the local psql client sees the source file; no stdout/stderr contains protected items.
 try{
  const opts={input:sql,encoding:'utf8',maxBuffer:2*1024*1024,
   env:{...process.env,PGOPTIONS:(synthetic?'-c iclub.e2e_isolated=true':process.env.PGOPTIONS)||''}};
  const run=spawnSync('psql',['-X','-q','-A','-t','-v','ON_ERROR_STOP=1'],opts);
  if(run.error)throw run.error;
  if(run.status!==0 || !String(run.stdout).includes(modeTag)){
   // Do NOT emit psql stderr: it may include protected content on some server errors.
   throw new Error('Protected V4 stage/dry-run failed (no contents printed); inspect restricted local logs only');
  }
  console.log(synthetic?'EXTRA HARD V4 DRY-RUN: 42 pending dummy inserts verified and ROLLED BACK; 0 release/progress writes.':
   'EXTRA HARD V4 PRIVATE DRAFT STAGE: 42 protected pending rows, zero approved/published, release OFF.');
 } finally{
  fs.rmSync(temp,{recursive:true,force:true});
 }
}
try{
 assert(['check','stage','dry-run-isolated'].includes(MODE)&&INPUT,'Specify mode and absolute input path');
 const bank=source();
 if(MODE==='stage'||MODE==='dry-run-isolated')stage(bank,MODE==='dry-run-isolated');
}catch(e){console.error('FULL42 protected operation refused:',e.message);process.exitCode=1;}