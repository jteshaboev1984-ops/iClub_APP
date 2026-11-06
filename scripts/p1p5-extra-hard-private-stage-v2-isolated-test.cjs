#!/usr/bin/env node
'use strict';
// Disposable PG17-only proof of the PRIVATE importer. Synthetic "1 + 1" only.
// NEVER includes the architect's real protected question bank or answer keys.
// Inserts and deletes only twelve deterministic dummy rows, never learner data.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const {spawnSync,execFileSync}=require('node:child_process');
assert(process.env.CI==='true' && process.env.P1P5_E2E_ISOLATED==='true'
 && process.env.PGHOST==='127.0.0.1' && process.env.PGDATABASE==='postgres'
 && process.env.PGUSER==='postgres','REFUSED: isolated PG17 CI only');
const BANK='math-extra-hard-2026-11-original-v2';
const root=path.resolve(__dirname,'..');
const loader=path.join(root,'scripts','ops','p1p5-extra-hard-private-bank-v2.cjs');
const dbEnv={...process.env,PGOPTIONS:'-c iclub.e2e_isolated=true'};
const sql=(q)=>execFileSync('psql',['-X','-A','-t','-v','ON_ERROR_STOP=1','-c',q],
  {env:dbEnv,encoding:'utf8',maxBuffer:200000}).trim();
const allowed=sql("SELECT CASE WHEN current_database()='postgres' AND current_setting('iclub.e2e_isolated',true)='true' AND (SELECT count(*) FROM public.users)=2 AND (SELECT count(*) FROM auth.users)=2 AND (SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1)=0 AND (SELECT count(*) FROM private.exam_prep_extra_hard_attempts_v1)=0 AND EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_release_v1 WHERE bank_version='"+BANK+"' AND enabled=false AND academic_approved=false) THEN 'SAFE' ELSE 'NO' END");
assert.equal(allowed,'SAFE','No clean isolated Extra Hard test baseline');
function stable(value){
 if(Array.isArray(value))return '['+value.map(stable).join(',')+']';
 if(value&&typeof value==='object')return '{'+Object.keys(value).sort().map(
  k=>JSON.stringify(k)+':'+stable(value[k])).join(',')+'}';
 return JSON.stringify(value);
}
const hash=s=>crypto.createHash('sha256').update(s,'utf8').digest('hex');
const sourceFields=['task_key','bank_version','component_code','primary_skill_code',
 'official_section','book_map','title_i18n','prompt_i18n','solution_i18n','exact_answer'];
const tasks=[];
for(const component of ['P1','P5']){
 for(let i=1;i<=6;i++){
  const n=String(i).padStart(2,'0');
  const t={
   task_key:'EH26-'+component+'-'+(component==='P1'?'QUA':'GEO')+'-99-'+n,
   bank_version:BANK,component_code:component,
   primary_skill_code:component==='P1'?'P1-QUA-01':'P5-GEO-01',
   official_section:component==='P1'?'1.1 Quadratics':'5.4 Discrete random variables',
   book_map:'CI disposable synthetic only, never course content',
   title_i18n:{en:'CI synthetic '+n,ru:'Тестовый пример '+n,uz:'Sinov masalasi '+n},
   prompt_i18n:{en:'CI TEST: What is 1 + 1?',ru:'ТЕСТ: 1 + 1 чему равно?',uz:'SINOV: 1 + 1 nechiga teng?'},
   solution_i18n:{en:'CI TEST ONLY: 1 + 1 = 2.',ru:'ТЕСТ: 1 + 1 = 2.',uz:'SINOV: 1 + 1 = 2.'},
   exact_answer:'CI synthetic answer 2',source_kind:'iclub_original',
   qa_math:'approved',qa_languages:'approved',qa_technical:'approved',lifecycle_status:'approved'
  };
  const canonical={}; for(const f of sourceFields)canonical[f]=t[f];
  t.content_sha256=hash(stable(canonical));
  tasks.push(t);
 }
}
const bundle={format_version:'iclub.extra_hard.private_bank_v2',program_key:'math_as_p1_p5',
 program_version_key:'p1_p5_canonical_v1_0',bank_version:BANK,
 release_enabled:false,academic_approved:false,tasks};
const tmp=fs.mkdtempSync(path.join(os.tmpdir(),'iclub-extra-hard-v2-ci-'));
const file=path.join(tmp,'synthetic-only.json');
fs.writeFileSync(file,JSON.stringify(bundle),'utf8');
function cleanup(){
 // Delete ONLY synthetic codes inside local isolated PG; never authentic tasks.
 const cmd="DO $guard$ BEGIN IF current_database()<>'postgres' OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true' OR (SELECT count(*) FROM public.users)<>2 OR EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_attempts_v1) THEN RAISE EXCEPTION 'CI synthetic cleanup refused'; END IF; END $guard$; DELETE FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' AND (task_key LIKE 'EH26-P1-QUA-99-%' OR task_key LIKE 'EH26-P5-GEO-99-%');";
 sql(cmd);
}
try{
 const check=spawnSync(process.execPath,[loader,'check',file],{encoding:'utf8',maxBuffer:300000});
 assert.equal(check.status,0,'Source hashes did not validate');
 assert.match(check.stdout,/12 unique tasks/);
 const tampered=JSON.parse(fs.readFileSync(file,'utf8'));
 tampered.tasks[0].solution_i18n.en='SYNTHETIC wrong answer';
 fs.writeFileSync(file,JSON.stringify(tampered),'utf8');
 const bad=spawnSync(process.execPath,[loader,'check',file],{encoding:'utf8'});
 assert.notEqual(bad.status,0,'Tampered challenge passed SHA validation');
 fs.writeFileSync(file,JSON.stringify(bundle),'utf8');
 const missingGO=spawnSync(process.execPath,[loader,'stage',file],{
   encoding:'utf8',env:{...dbEnv,ICLUB_EXTRAHARD_PRIVATE_STAGE_GO:''}});
 assert.notEqual(missingGO.status,0,'Private staging succeeded without owner GO');
 const staged=spawnSync(process.execPath,[loader,'stage',file],{
   encoding:'utf8',maxBuffer:300000,
   env:{...dbEnv,ICLUB_EXTRAHARD_PRIVATE_STAGE_GO:'OWNER_APPROVED_PRIVATE_12_V2'}});
 assert.equal(staged.status,0,'Private synthetic importer could not stage complete 12');
 assert.match(staged.stdout,/PRIVATE STAGING COMPLETE/);
 assert.equal(sql("SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1 WHERE bank_version='"+BANK+"' AND lifecycle_status='approved' AND qa_math='approved' AND qa_languages='approved' AND qa_technical='approved'"),'12');
 assert.equal(sql("SELECT (enabled::int)::text||'|'||(academic_approved::int)::text FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5'"),'0|0');
 console.log('EXTRA HARD V2 PRIVATE STAGING PASS: 12/12 synthetic rows, immutable hashes, tamper denied, owner-GO required, release OFF');
} finally {
 cleanup();
 fs.rmSync(tmp,{recursive:true,force:true});
}
assert.equal(sql('SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1'), '0');
assert.equal(sql('SELECT count(*) FROM private.exam_prep_extra_hard_attempts_v1'),'0');
console.log('EXTRA HARD V2 SYNTHETIC CLEANUP PASS: no tasks, attempts or learner reset');
