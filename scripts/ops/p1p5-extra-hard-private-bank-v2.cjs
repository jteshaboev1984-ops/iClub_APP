#!/usr/bin/env node
'use strict';
/* PRIVATE local owner workflow: checks or stages a protected 12-task JSON.
 * No protected prompts/solutions/answer keys in this public source file.
 * Never run against live Supabase without a separate owner staging GO.
 */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');
const mode = process.argv[2];
const privateFile = process.argv[3];
const BANK = 'math-extra-hard-2026-11-original-v2';
const fields = [ 'task_key','bank_version','component_code','primary_skill_code',
  'official_section','book_map','title_i18n','prompt_i18n','solution_i18n','exact_answer' ];
function stable(value) {
  if (Array.isArray(value)) return '['+value.map(stable).join(',')+']';
  if (value && typeof value==='object') return '{'+Object.keys(value).sort().map(
    k=>JSON.stringify(k)+':'+stable(value[k])).join(',')+'}';
  return JSON.stringify(value);
}
function sha(s) {return crypto.createHash('sha256').update(s,'utf8').digest('hex');}
function plain(v) {return typeof v==='string' && v.trim().length>=4 && v.length<=10000;}
function valid() {
  assert(['check','stage'].includes(mode) && privateFile,'Usage: node ... (check|stage) /absolute/private/bank.json');
  const abs=path.resolve(privateFile);
  const repo=path.resolve(__dirname,'..','..')+path.sep;
  assert(!abs.startsWith(repo),'Refusing protected bank inside the public Git repository');
  const raw=fs.readFileSync(abs,'utf8');
  const obj=JSON.parse(raw);
  assert(obj.format_version==='iclub.extra_hard.private_bank_v2');
  assert(obj.program_key==='math_as_p1_p5' && obj.program_version_key==='p1_p5_canonical_v1_0');
  assert(obj.bank_version===BANK && obj.release_enabled===false && obj.academic_approved===false);
  assert(Array.isArray(obj.tasks) && obj.tasks.length===12);
  const seen=new Set();let p1=0,p5=0;
  for(const t of obj.tasks){
    assert(t && typeof t==='object');
    assert(/^EH26-P[15]-[A-Z]{3}-\d{2}-\d{2}$/.test(t.task_key));
    assert(!seen.has(t.task_key),'Duplicate task key');seen.add(t.task_key);
    assert(t.component_code==='P1'||t.component_code==='P5');
    t.component_code==='P1'?p1++:p5++;
    assert(t.primary_skill_code.startsWith(t.component_code+'-'));
    assert(t.bank_version===BANK && t.source_kind==='iclub_original');
    assert(t.qa_math==='approved' && t.qa_languages==='approved' && t.qa_technical==='approved');
    assert(t.lifecycle_status==='approved');
    for(const k of ['title_i18n','prompt_i18n','solution_i18n']) {
      assert(t[k] && typeof t[k]==='object' && Object.keys(t[k]).sort().join(',')==='en,ru,uz');
      for(const lang of ['en','ru','uz']) assert(plain(t[k][lang]),'Missing '+k+' / '+lang);
    }
    for(const k of ['official_section','book_map','exact_answer']) assert(plain(t[k]),'Missing '+k);
    const canonical={};for(const k of fields) canonical[k]=t[k];
    assert(sha(stable(canonical))===t.content_sha256,'Content SHA mismatch: '+t.task_key);
  }
  assert(p1===6 && p5===6,'Need exactly six P1 and six P5 tasks');
  console.log('PRIVATE BANK CHECK PASS: 12 unique tasks (P1=6, P5=6), three locales, 12 verified source hashes. Bank remains OFF.');
  return obj;
}
const obj=valid();
if(mode==='stage'){
  assert(process.env.ICLUB_EXTRAHARD_PRIVATE_STAGE_GO==='OWNER_APPROVED_PRIVATE_12_V2',
    'Separate owner approval required; validation does not authorize database writes');
  assert(process.env.PGHOST && process.env.PGDATABASE && process.env.PGUSER,
    'Explicit PostgreSQL connection environment required');
  // The action is deliberately not a production deployment or a bank release.
  const payload=Buffer.from(JSON.stringify(obj),'utf8').toString('base64');
  const sql=`BEGIN;
DO $pre$ BEGIN
 IF to_regclass('private.exam_prep_extra_hard_tasks_v1') IS NULL
  OR to_regclass('private.exam_prep_extra_hard_release_v1') IS NULL
  OR (SELECT count(*) FROM private.exam_prep_program_versions
      WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active')<>1
 THEN RAISE EXCEPTION 'Extra Hard private bank schema/program not ready'; END IF;
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_release_v1
   WHERE program_key='math_as_p1_p5' AND bank_version='${BANK}'
     AND enabled=false AND academic_approved=false)
 THEN RAISE EXCEPTION 'Extra Hard private staging requires OFF release and matching new bank version'; END IF;
END $pre$;
WITH bundle AS (SELECT convert_from(decode('${payload}','base64'),'UTF8')::jsonb AS doc),
 version AS (SELECT id FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active'),
 entries AS (SELECT jsonb_array_elements(doc->'tasks') AS t FROM bundle)
INSERT INTO private.exam_prep_extra_hard_tasks_v1(
 task_key,program_version_id,bank_version,component_code,primary_skill_code,official_section,
 book_map,title_i18n,prompt_i18n,solution_i18n,exact_answer,source_kind,
 qa_math,qa_languages,qa_technical,lifecycle_status,content_sha256)
SELECT t->>'task_key',v.id,t->>'bank_version',t->>'component_code',
 t->>'primary_skill_code',t->>'official_section',t->>'book_map',
 t->'title_i18n',t->'prompt_i18n',t->'solution_i18n',t->>'exact_answer',
 t->>'source_kind',t->>'qa_math',t->>'qa_languages',t->>'qa_technical',
 t->>'lifecycle_status',t->>'content_sha256'
FROM entries CROSS JOIN version v
ON CONFLICT(task_key) DO NOTHING;
DO $verify$
DECLARE
 doc jsonb;
BEGIN
 doc:=convert_from(decode('${payload}','base64'),'UTF8')::jsonb;
 IF (SELECT count(*) FROM jsonb_array_elements(doc->'tasks'))<>12
 OR (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1
     WHERE bank_version='${BANK}' AND lifecycle_status='approved')<>12
 OR EXISTS(SELECT 1 FROM jsonb_array_elements(doc->'tasks') e
   LEFT JOIN private.exam_prep_extra_hard_tasks_v1 t
    ON t.task_key=e->>'task_key' AND t.bank_version='${BANK}'
   WHERE t.task_key IS NULL OR t.content_sha256 IS DISTINCT FROM e->>'content_sha256'
    OR t.lifecycle_status<>'approved' OR t.qa_math<>'approved'
    OR t.qa_languages<>'approved' OR t.qa_technical<>'approved')
 OR EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_release_v1
    WHERE program_key='math_as_p1_p5' AND (enabled OR academic_approved))
 THEN RAISE EXCEPTION 'Extra Hard private staging verification failed: transaction rolled back'; END IF;
END $verify$;
COMMIT;
SELECT 'PRIVATE_12_STAGED_OFF' AS outcome;`;
  // Output uses tuple-only summary; neither SQL nor protected fields are logged.
  const run=spawnSync('psql',['-X','-q','-t','-A','-v','ON_ERROR_STOP=1'],{
    input:sql,encoding:'utf8',maxBuffer:2*1024*1024});
  if(run.error)throw run.error;
  if(run.status!==0 || !String(run.stdout).includes('PRIVATE_12_STAGED_OFF')){
    throw new Error('Private DB staging failed/was not verified. Use a restricted local log; never publish protected stdout or server-side query text.');
  }
  console.log('PRIVATE STAGING COMPLETE: 12 approved unpublished task versions, release switch remains OFF.');
}