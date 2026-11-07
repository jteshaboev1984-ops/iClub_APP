#!/usr/bin/env node
'use strict';
// Only dummy challenges, no protected source. Tests real PostgreSQL v3 insert path.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const crypto=require('node:crypto');
const {spawnSync,execFileSync}=require('node:child_process');
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
 process.env.PGHOST==='127.0.0.1'&&process.env.PGPORT==='5432'&&
 process.env.PGDATABASE==='postgres'&&process.env.PGUSER==='postgres',
 'REFUSED: v3 private import proof must use isolated PG17 CI');
const BANK='math-extra-hard-2026-11-full-v3';
const env={...process.env,PGOPTIONS:'-c iclub.e2e_isolated=true'};
const sql=q=>execFileSync('psql',['-X','-t','-A','-v','ON_ERROR_STOP=1','-c',q],
 {env,encoding:'utf8',maxBuffer:200000}).trim();
assert.equal(sql("SELECT CASE WHEN current_database()='postgres' AND current_setting('iclub.e2e_isolated',true)='true' AND current_setting('server_version_num')::int>=170000 AND (SELECT count(*) FROM auth.users)=2 AND (SELECT count(*) FROM public.users)=2 AND NOT EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_tasks_v1) AND NOT EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_attempts_v1) AND EXISTS(SELECT 1 FROM private.exam_prep_extra_hard_release_v1 WHERE bank_version='math-extra-hard-2026-11-original-v2' AND enabled=false AND academic_approved=false) THEN 'SAFE' ELSE 'UNSAFE' END"),'SAFE',
 'REFUSED: synthetic v3 staging test encountered non-disposable learner/extra-hard records');
const snapshot=sql("SELECT (SELECT count(*) FROM private.exam_prep_sessions)||'|'||(SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1)||'|'||(SELECT count(*) FROM private.exam_prep_extra_hard_attempts_v1)||'|'||(SELECT bank_version||':'||enabled::text||':'||academic_approved::text FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5')");
const groups=[['P1','QUA','1.1'],['P1','FUN','1.2'],['P1','COO','1.3'],['P1','CIR','1.4'],
 ['P1','TRI','1.5'],['P1','SER','1.6'],['P1','DIF','1.7'],['P1','INT','1.8'],
 ['P5','DAT','5.1'],['P5','CNT','5.2'],['P5','PRO','5.3'],['P5','GEO','5.4'],
 ['P5','BIN','5.4'],['P5','NOR','5.5']];
const FIELDS=['task_key','bank_version','component_code','primary_skill_code','official_section',
 'book_map','title_i18n','prompt_i18n','solution_i18n','exact_answer'];
function stable(v){if(Array.isArray(v))return '['+v.map(stable).join(',')+']';
 if(v&&typeof v==='object')return '{'+Object.keys(v).sort().map(k=>JSON.stringify(k)+':'+stable(v[k])).join(',')+'}';
 return JSON.stringify(v);}
const sha=x=>crypto.createHash('sha256').update(x,'utf8').digest('hex');
let i=0;
const tasks=[];
for(const [component,short,section] of groups){
 for(let n=1;n<=3;n++){
  i++;
  const id=`EH-CI-${component}-${short}-${String(i).padStart(2,'0')}`;
  const status='approved';
  const t={task_key:id,bank_version:BANK,component_code:component,
   primary_skill_code:`${component}-${short}-01`,official_section:section+' CI original syllabus',
   book_map:'CI disposable local only',
   title_i18n:{en:`CI synthetic ${i}`,ru:`CI тестовая ${i}`,uz:`CI sinov masalasi ${i}`},
   prompt_i18n:{en:`CI TEST: 1 + 1 challenge ${i}`,ru:`CI TEST: 1 + 1 sinov ${i}`,uz:`CI TEST: 1 + 1 masala ${i}`},
   solution_i18n:{en:`CI TEST: 1 + 1 = 2, problem ${i}`,ru:`CI TEST: 1 + 1 = 2 misol ${i}`,uz:`CI TEST: 1 + 1 = 2 masala ${i}`},
   exact_answer:'CI TEST answer 2',source_kind:'iclub_original',qa_math:'approved',
   qa_languages:status==='approved'?'approved':'pending',
   qa_technical:status==='approved'?'approved':'pending',lifecycle_status:status};
  const c={}; for(const key of FIELDS)c[key]=t[key];
  t.content_sha256=sha(stable(c));tasks.push(t);
 }
}
assert(tasks.length===42);
const bundle={format_version:'iclub.extra_hard.private_bank_v3',program_key:'math_as_p1_p5',
 program_version_key:'p1_p5_canonical_v1_0',bank_version:BANK,
 release_enabled:false,academic_approved:false,tasks};
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'iclub-eh-v3-test-'));
const json=path.join(temp,'synthetic_only.json');
fs.writeFileSync(json,JSON.stringify(bundle),{mode:0o600});
const importer=path.resolve('scripts/ops/p1p5-extra-hard-private-full42-stage-v3.cjs');
try{
 const denied=spawnSync(process.execPath,[importer,'stage',json],{
  env:{...env,ICLUB_EXTRAHARD_FULL42_STAGE_GO:''},encoding:'utf8'});
 assert.notEqual(denied.status,0,'Real protected staging cannot accept disposable source without exact SHA/GO');
 const tamper=structuredClone(bundle);
 tamper.tasks[12].prompt_i18n.en='CI TEST: modified without hash';
 fs.writeFileSync(json,JSON.stringify(tamper));
 const broken=spawnSync(process.execPath,[importer,'dry-run-isolated',json],{
  env,encoding:'utf8'});
 assert.notEqual(broken.status,0,'Tampered protected task unexpectedly accepted');
 fs.writeFileSync(json,JSON.stringify(bundle));
 const valid=spawnSync(process.execPath,[importer,'dry-run-isolated',json],{
  env,encoding:'utf8',maxBuffer:200000});
 if(valid.status!==0)throw new Error('Isolated 42-row COPY+ROLLBACK did not complete: '+(valid.stderr||'').slice(0,450));
 assert.match(valid.stdout,/EXTRA HARD V3 DRY-RUN: 42 dummy inserts verified and ROLLED BACK/);
 const after=sql("SELECT (SELECT count(*) FROM private.exam_prep_sessions)||'|'||(SELECT count(*) FROM private.exam_prep_extra_hard_tasks_v1)||'|'||(SELECT count(*) FROM private.exam_prep_extra_hard_attempts_v1)||'|'||(SELECT bank_version||':'||enabled::text||':'||academic_approved::text FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5')");
 assert.equal(after,snapshot,'Isolated 42-row stage failed to restore preflight snapshot');
 console.log('EXTRA HARD V3 42-ROW PRIVATE COPY ROLLBACK PASS: 42, P1 24/P5 18, 42 internally approved/0 draft, tamper and no-GO denied, release OFF, no learner writes');
}finally{fs.rmSync(temp,{recursive:true,force:true});}