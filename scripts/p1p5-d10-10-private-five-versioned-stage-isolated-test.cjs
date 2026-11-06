#!/usr/bin/env node
'use strict';
// SOURCE SAFE PG17 TEST: generic 2+2 test prompts ONLY; never actual private bank.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const {spawnSync,execFileSync}=require('node:child_process');
assert(process.env.CI==='true' && process.env.P1P5_E2E_ISOLATED==='true'
 && process.env.PGHOST==='127.0.0.1' && process.env.PGPORT==='5432'
 && process.env.PGDATABASE==='postgres' && process.env.PGUSER==='postgres',
 'D10-10 refuses non-CI isolated database');
const env={...process.env,PGOPTIONS:'-c iclub.e2e_isolated=true'};
const sql=s=>execFileSync('psql',['-X','-A','-t','-v','ON_ERROR_STOP=1','-c',s],
  {env,encoding:'utf8',maxBuffer:200000}).trim();
const canonicalSpecs=[
 ['P1DIF05-M01','P1-DIF-05','mixed','P1DIF05-M01-V02'],
 ['P1INT03-R04','P1-INT-03','retest','P1INT03-R04-V02'],
 ['P1QUA03-D01','P1-QUA-03','diagnostic','P1QUA03-D01-V02'],
 ['P1INT03-D03','P1-INT-03','diagnostic','P1INT03-D03-V02'],
 ['P1INT04-R04','P1-INT-04','retest','P1INT04-R04-V02']
];
// Disposable schema seeds the same content keys but Postgres identities
// are not required to match the LIVE original question IDs. Use the actual
// CI source key→question link, not guessed numeric values. LIVE protected
// stage still requires the exact original checksum plus five known live IDs.
const oldSpecs=canonicalSpecs.map(([key,skill,role,next])=>{
 const v=sql(`SELECT m.question_id::text||'|'||q.difficulty||'|'||q.time_limit_sec::text
 FROM private.exam_prep_question_content_meta m
 JOIN public.questions q ON q.id=m.question_id
 WHERE m.content_key='${key}' AND m.primary_skill_code='${skill}'
   AND m.reserve_role='${role}' AND q.qtype='mcq' AND q.is_active=false`);
 const parts=v.split('|');
 assert.equal(parts.length,3,'CI canonical original key/skill/role unavailable');
 const [id,difficulty,sec]=parts;
 return [key,Number(id),skill,role,next,difficulty,Number(sec)];
});
const nPublished=sql(`SELECT count(DISTINCT a.id)::text
 FROM private.exam_prep_assessments a
 JOIN private.exam_prep_assessment_items i ON i.assessment_id=a.id
 JOIN private.exam_prep_question_content_meta m ON m.question_id=i.question_id
 WHERE a.status='published' AND a.component_code='P1'
   AND m.content_key IN ('P1DIF05-M01','P1INT03-R04','P1QUA03-D01','P1INT03-D03','P1INT04-R04')`);
assert.equal(nPublished,'6',`Disposable source must include six published P1 assessment routes, found ${nPublished}`);
const clean=sql(`SELECT CASE WHEN current_database()='postgres'
 AND current_setting('iclub.e2e_isolated',true)='true'
 AND (SELECT count(*) FROM auth.users)=2
 AND (SELECT count(*) FROM public.users)=2
 AND (SELECT count(*) FROM private.exam_prep_question_content_meta
      WHERE content_key IN ('P1DIF05-M01-V02','P1INT03-R04-V02','P1QUA03-D01-V02','P1INT03-D03-V02','P1INT04-R04-V02'))=0
 THEN 'CLEAN' ELSE 'DENIED' END`);
assert.equal(clean,'CLEAN','D10-10 source database is not known disposable baseline');
const before=sql(`SELECT (SELECT count(*) FROM public.questions)::text||'|'
 ||(SELECT count(*) FROM private.exam_prep_assessments)::text||'|'
 ||(SELECT count(*) FROM private.exam_prep_assessment_items)::text||'|'
 ||(SELECT count(*) FROM private.exam_prep_question_content_meta)::text||'|'
 ||(SELECT count(*) FROM private.exam_prep_sessions)::text||'|'
 ||(SELECT count(*) FROM private.exam_prep_session_items)::text`);
const payload={
 candidate_version:'d10_09_v2_private_unpublished',component_code:'P1',program:'math_as_p1_p5',
 publication_authorized:false,protected_question_count:5,
 questions:oldSpecs.map(([original,id,skill,role,next,difficulty,seconds],idx)=>({
  existing_question_id:id,supersedes_content_key:original,candidate_content_key:next,
  primary_skill_code:skill,reserve_role:role,difficulty,time_limit_sec:seconds,
  question_text_en:`CI synthetic mathematical question ${idx+1}: calculate 2+2.`,
  question_text_ru:`CI синтетическая проверка ${idx+1}: вычислите 2+2.`,
  question_text_uz:`CI sun'iy tekshiruv ${idx+1}: 2+2 ni hisoblang.`,
  explanation_en:'CI test explanation only; 2+2=4, not a published question.',
  explanation_ru:'Только проверочный пример CI; 2+2=4.',
  explanation_uz:'Faqat CI sinov yechimi; 2+2=4.',
  options_text_en:['4','5','6','7'],
  options_text_ru:['4','5','6','7'],
  options_text_uz:['4','5','6','7'],
  correct_answer:'A',
  official_scope_ref:'Cambridge 9709 CI synthetic only',
  coursebook_mapping_ref:'Complete Pure Mathematics 1 CI synthetic only'
 }))
};
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'iclub-d10-10-synthetic-'));
const file=path.join(temp,'CI_only_five.json');
const importer=path.join(__dirname,'ops','p1p5-d10-10-private-five-versioned-stage.cjs');
try{
 fs.writeFileSync(file,JSON.stringify(payload));
 const denied=spawnSync(process.execPath,[importer,'stage',file],{encoding:'utf8',env});
 assert.notEqual(denied.status,0,'Synthetic source could be permanently staged');
 const proof=spawnSync(process.execPath,[importer,'dry-run-isolated',file],
   {encoding:'utf8',env,maxBuffer:3*1024*1024});
 if(proof.status!==0){
  console.error('D10-10 synthetic dry run failed; no protected candidate payload printed.');
  process.exitCode=1;
  throw new Error('SQL stage regression; inspect local isolated PG error logs for generic fixture');
 }
 assert.match(proof.stdout,/D10-10 PRIVATE DISPOSABLE_DRY_RUN PASS/);
 const after=sql(`SELECT (SELECT count(*) FROM public.questions)::text||'|'
 ||(SELECT count(*) FROM private.exam_prep_assessments)::text||'|'
 ||(SELECT count(*) FROM private.exam_prep_assessment_items)::text||'|'
 ||(SELECT count(*) FROM private.exam_prep_question_content_meta)::text||'|'
 ||(SELECT count(*) FROM private.exam_prep_sessions)::text||'|'
 ||(SELECT count(*) FROM private.exam_prep_session_items)::text`);
 assert.equal(after,before,'D10-10 dry-run changed historical source/learner row counts');
 assert.equal(sql(`SELECT count(*) FROM private.exam_prep_assessments
 WHERE assessment_version LIKE '%-d10-10v02'`),'0',
 'D10-10 dry-run left a draft replacement assessment');
 console.log('D10-10 SOURCE VERSIONED FIVE PASS: 5 new draft candidates + 6 source assessment versions + 24 items DRY-RUN ROLLBACK; no historical progress changes');
} finally { fs.rmSync(temp,{recursive:true,force:true}); }