#!/usr/bin/env node
'use strict';
// P1/P5 D10-10: stage only separately approved, protected P1 five candidates.
// No protected question/answer text is stored in Git, CI or stdout.
// Check: local only. Dry-run: deterministic synthetic CI PG17 only.
// Stage: explicit owner-GO and a separate private PostgreSQL connection.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');
const mode=process.argv[2];
const filename=process.argv[3];
const PRIVATE_SHA='d788adc9b145cd308937a70f0ffdfa670545f5ee28a3d740b22fb5b33c7a158d';
const TARGETS=[
 ['P1DIF05-M01',6711,'P1-DIF-05','mixed','P1DIF05-M01-V02'],
 ['P1INT03-R04',7435,'P1-INT-03','retest','P1INT03-R04-V02'],
 ['P1QUA03-D01',6289,'P1-QUA-03','diagnostic','P1QUA03-D01-V02'],
 ['P1INT03-D03',7414,'P1-INT-03','diagnostic','P1INT03-D03-V02'],
 ['P1INT04-R04',7405,'P1-INT-04','retest','P1INT04-R04-V02']
];
const TAG='d10-10v02';
function validate(){
 assert(['check','dry-run-isolated','stage'].includes(mode) && filename,
   'Usage: node p1p5-d10-10-private-five-versioned-stage.cjs check|dry-run-isolated|stage /absolute/path/to/private.json');
 const abs=path.resolve(filename),repo=path.resolve(__dirname,'..','..');
 assert(!abs.startsWith(repo+path.sep),'REFUSED: protected bank payload must not be inside public GitHub repository');
 const raw=fs.readFileSync(abs);
 const sha=crypto.createHash('sha256').update(raw).digest('hex');
 if(mode!=='dry-run-isolated') assert.equal(sha,PRIVATE_SHA,'PRIVATE SOURCE SHA drift: do not stage altered bank');
 const o=JSON.parse(raw.toString('utf8'));
 assert(o.candidate_version==='d10_09_v2_private_unpublished'
   && o.component_code==='P1' && o.program==='math_as_p1_p5'
   && o.publication_authorized===false && o.protected_question_count===5,
   'No safe private five-candidate provenance');
 assert(Array.isArray(o.questions)&&o.questions.length===5);
 const byKey=new Map(o.questions.map(q=>[q.supersedes_content_key,q]));
 assert.equal(byKey.size,5,'Repeated original source question');
 for(const [old,id,skill,role,next] of TARGETS){
  const q=byKey.get(old);
  assert(q && q.existing_question_id===id && q.candidate_content_key===next
   && q.primary_skill_code===skill && q.reserve_role===role,`Source metadata mismatch for ${old}`);
  assert(['easy','medium','hard'].includes(q.difficulty) && Number.isInteger(q.time_limit_sec)
   && q.time_limit_sec>=20&&q.time_limit_sec<=300);
  assert(/^[A-D]$/.test(q.correct_answer),'MCQ key invalid');
  for(const locale of ['en','ru','uz']){
   assert(typeof q['question_text_'+locale]==='string' && q['question_text_'+locale].trim().length>=20);
   assert(typeof q['explanation_'+locale]==='string' && q['explanation_'+locale].trim().length>=20);
   const opts=q['options_text_'+locale];
   assert(Array.isArray(opts)&&opts.length===4 && opts.every(x=>typeof x==='string'&&x.trim()),
     'Must have four nonempty '+locale+' options');
   assert(new Set(opts.map(x=>x.trim())).size===4,'Duplicate '+locale+' choices');
  }
  assert(q.official_scope_ref?.includes('Cambridge 9709')
   && q.coursebook_mapping_ref?.includes('Complete Pure Mathematics 1'));
 }
 console.log(`D10-10 PRIVATE SOURCE CHECK PASS: 5 target versions, 6 affected published assessments, EN/RU/UZ and MCQ structure; ${mode==='dry-run-isolated'?'CI synthetic only':'original checksum matched'}`);
 return o;
}
const data=validate();
if(mode==='check')process.exit(0);
if(mode==='stage'){
 assert(process.env.ICLUB_P1P5_PRIVATE_FIVE_STAGE_GO==='OWNER_APPROVED_PRIVATE_FIVE_V02',
   'Separate owner authorization required before any protected database stage');
} else {
 assert(process.env.CI==='true' && process.env.P1P5_E2E_ISOLATED==='true'
   && process.env.PGHOST==='127.0.0.1' && process.env.PGPORT==='5432'
   && process.env.PGDATABASE==='postgres' && process.env.PGUSER==='postgres',
   'D10-10 DRY RUN refused outside isolated PG17 CI');
}
assert(process.env.PGHOST && process.env.PGUSER && process.env.PGDATABASE,
 'Explicit PostgreSQL owner connection required');
const payload=Buffer.from(JSON.stringify(data),'utf8').toString('base64');
const verdict=(mode==='stage'?'COMMIT':'ROLLBACK');
const checkMode=(mode==='stage'?'PRIVATE_STAGE':'DISPOSABLE_DRY_RUN');
const script=String.raw`BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='100s';
SELECT pg_advisory_xact_lock(611061030010);
CREATE TEMP TABLE _p1p5_d1010_payload(doc jsonb NOT NULL) ON COMMIT DROP;
INSERT INTO _p1p5_d1010_payload SELECT convert_from(decode('${payload}','base64'),'UTF8')::jsonb;
CREATE TEMP TABLE _p1p5_d1010_candidates ON COMMIT DROP AS
 SELECT (q->>'existing_question_id')::bigint AS old_id,
        (q->>'candidate_content_key')::text AS new_key,
        q AS item
 FROM _p1p5_d1010_payload p
 CROSS JOIN LATERAL jsonb_array_elements(p.doc->'questions') q;
CREATE UNIQUE INDEX _p1p5_d1010_candidate_id_idx ON _p1p5_d1010_candidates(old_id);
CREATE UNIQUE INDEX _p1p5_d1010_candidate_key_idx ON _p1p5_d1010_candidates(new_key);
CREATE TEMP TABLE _p1p5_d1010_old_assess ON COMMIT DROP AS
 SELECT DISTINCT a.id AS old_id,a.assessment_key,a.assessment_version,a.content_version_id,
    a.assessment_type
 FROM private.exam_prep_assessments a
 JOIN private.exam_prep_assessment_items i ON i.assessment_id=a.id
 JOIN _p1p5_d1010_candidates c ON c.old_id=i.question_id
 WHERE a.status='published' AND a.component_code='P1';
DO $pre$
DECLARE n int; v integer;
BEGIN
 IF to_regclass('private.exam_prep_question_content_meta') IS NULL
   OR (SELECT count(*) FROM _p1p5_d1010_candidates)<>5
   OR (SELECT count(*) FROM _p1p5_d1010_old_assess)<>6
 THEN RAISE EXCEPTION 'D10-10 source drift: candidates=%, published_assessments=%', (SELECT count(*) FROM _p1p5_d1010_candidates), (SELECT count(*) FROM _p1p5_d1010_old_assess); END IF;
 SELECT count(*) INTO n FROM _p1p5_d1010_candidates c
 JOIN private.exam_prep_question_content_meta m
  ON m.question_id=c.old_id AND m.content_key=c.item->>'supersedes_content_key'
 JOIN public.questions old_q ON old_q.id=c.old_id
 JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
 WHERE m.primary_skill_code=c.item->>'primary_skill_code'
  AND m.reserve_role=c.item->>'reserve_role'
  AND m.lifecycle_state IN ('reserve','published')
  AND m.qa_math_status='pass' AND m.qa_language_status='pass'
  AND m.qa_scope_status='pass' AND m.qa_technical_status='pass'
  AND cv.program_version_id=(SELECT id FROM private.exam_prep_program_versions
    WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active')
  AND cv.component_code='P1' AND old_q.subject_id=5
  AND old_q.qtype='mcq' AND old_q.is_active=false
  AND old_q.difficulty=c.item->>'difficulty'
  AND old_q.time_limit_sec=(c.item->>'time_limit_sec')::integer;
 IF n<>5 THEN RAISE EXCEPTION 'D10-10 source metadata, source math QA or identity drift'; END IF;
 IF EXISTS(SELECT 1 FROM _p1p5_d1010_candidates c
  JOIN private.exam_prep_question_content_meta m ON m.question_id=c.old_id
  WHERE EXISTS(SELECT 1 FROM private.exam_prep_question_content_meta n
    WHERE n.content_version_id=m.content_version_id AND n.content_key=c.new_key))
 OR EXISTS(SELECT 1 FROM _p1p5_d1010_candidates c
  JOIN public.questions q ON q.id=c.old_id
  WHERE EXISTS(SELECT 1 FROM public.questions n
    WHERE n.book_ref=q.book_ref||':d10-10v02-private-stage'))
 OR EXISTS(SELECT 1 FROM _p1p5_d1010_old_assess a
  WHERE EXISTS(SELECT 1 FROM private.exam_prep_assessments n
    WHERE n.content_version_id=a.content_version_id
      AND n.assessment_key=a.assessment_key
      AND n.assessment_version=a.assessment_version||'-d10-10v02'))
 THEN RAISE EXCEPTION 'D10-10 v02 versions already exist; avoid duplicate import'; END IF;
 SELECT coalesce(sum(k),0) INTO v FROM (
  SELECT count(*)::int k FROM private.exam_prep_assessment_items i
  JOIN _p1p5_d1010_old_assess s ON s.old_id=i.assessment_id
  GROUP BY i.assessment_id) x;
 IF v<>24 THEN RAISE EXCEPTION 'D10-10 six source assessment item counts drift'; END IF;
 IF EXISTS(SELECT 1 FROM _p1p5_d1010_old_assess a
  JOIN private.exam_prep_sessions s ON s.assessment_id=a.old_id
  WHERE s.status='active') THEN
  -- Do NOT block staging or destroy active owners: original is never changed.
  NULL;
 END IF;
 IF ${mode==='dry-run-isolated'?'true':'false'} AND (
   current_database()<>'postgres' OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
   OR (SELECT count(*) FROM auth.users)<>2
   OR (SELECT count(*) FROM public.users)<>2
 ) THEN RAISE EXCEPTION 'D10-10 dry run must use disposable isolated PG17 two-user data'; END IF;
END $pre$;
INSERT INTO public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,
 image_url,is_active,question_text_ru,question_text_uz,question_text_en,
 options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
SELECT old_q.subject_id,old_q.topic,old_q.subtopic,c.item->>'difficulty','mcq',
 c.item->>'question_text_en',(c.item->'options_text_en')::text,c.item->>'correct_answer',c.item->>'explanation_en',
 NULL,false,c.item->>'question_text_ru',c.item->>'question_text_uz',c.item->>'question_text_en',
 (c.item->'options_text_ru')::text,(c.item->'options_text_uz')::text,(c.item->'options_text_en')::text,
 c.item->>'explanation_ru',c.item->>'explanation_uz',c.item->>'explanation_en',
 old_q.book_ref||':d10-10v02-private-stage',
 (c.item->>'time_limit_sec')::int,old_q.quality_flag,'draft'
FROM _p1p5_d1010_candidates c JOIN public.questions old_q ON old_q.id=c.old_id;
CREATE TEMP TABLE _p1p5_d1010_new_questions ON COMMIT DROP AS
SELECT c.old_id,c.new_key,n.id AS new_id,c.item
FROM _p1p5_d1010_candidates c
JOIN public.questions old_q ON old_q.id=c.old_id
JOIN public.questions n ON n.book_ref=old_q.book_ref||':d10-10v02-private-stage';
DO $qc$ BEGIN
 IF (SELECT count(*) FROM _p1p5_d1010_new_questions)<>5
  OR EXISTS(SELECT 1 FROM _p1p5_d1010_new_questions c
   JOIN public.questions q ON q.id=c.new_id WHERE q.is_active<>false OR q.quality_status<>'draft')
 THEN RAISE EXCEPTION 'D10-10 incomplete private new question rows'; END IF;
END $qc$;
INSERT INTO private.exam_prep_question_content_meta(
 content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,
 reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,
 official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,
 qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
SELECT m.content_version_id,c.new_key,c.new_id,m.primary_skill_code,m.secondary_skill_codes,
 m.reserve_role,'withheld','draft',
 'iclub_original_owner_requested_ai_assisted_versioned_replacement',
 'D10-10 private DRAFT replacement of '||m.content_key||', previous question and all learner history unchanged; requires separate academic content/release approval',
 c.item->>'official_scope_ref',c.item->>'coursebook_mapping_ref',
 'pending','pending','pending','pending','pending',
 CASE WHEN m.reserve_role='diagnostic' THEN 'pending' ELSE 'not_applicable' END,
 md5(concat_ws(chr(31),
  q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
  coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
  coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
  coalesce(q.image_url,''),coalesce(q.is_active::text,''),
  coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
  coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
  coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
  coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
  coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
FROM _p1p5_d1010_new_questions c
JOIN private.exam_prep_question_content_meta m ON m.question_id=c.old_id
JOIN public.questions q ON q.id=c.new_id;
INSERT INTO private.exam_prep_assessments(
 content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,
 title_en,title_ru,title_uz,approved_at)
SELECT a.content_version_id,a.assessment_key,a.assessment_version||'-d10-10v02',
 a.component_code,a.assessment_type,'draft',a.title_en,a.title_ru,a.title_uz,NULL
FROM private.exam_prep_assessments a
JOIN _p1p5_d1010_old_assess old ON old.old_id=a.id;
CREATE TEMP TABLE _p1p5_d1010_new_assess ON COMMIT DROP AS
SELECT old.old_id AS original_assessment_id,a.id AS new_assessment_id
FROM _p1p5_d1010_old_assess old
JOIN private.exam_prep_assessments a ON a.content_version_id=old.content_version_id
 AND a.assessment_key=old.assessment_key
 AND a.assessment_version=old.assessment_version||'-d10-10v02';
INSERT INTO private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout)
SELECT new_ass.new_assessment_id,i.item_order,
 coalesce(c.new_id,i.question_id),i.written_task_id,i.primary_skill_code,i.reserve_role,i.is_holdout
FROM _p1p5_d1010_new_assess new_ass
JOIN private.exam_prep_assessment_items i ON i.assessment_id=new_ass.original_assessment_id
LEFT JOIN _p1p5_d1010_new_questions c ON c.old_id=i.question_id;
DO $verify$
DECLARE n_ass integer; n_items integer; n_swapped integer;
BEGIN
 SELECT count(*) INTO n_ass FROM _p1p5_d1010_new_assess;
 SELECT count(*) INTO n_items FROM private.exam_prep_assessment_items i
  JOIN _p1p5_d1010_new_assess a ON a.new_assessment_id=i.assessment_id;
 SELECT count(*) INTO n_swapped FROM private.exam_prep_assessment_items i
  JOIN _p1p5_d1010_new_assess a ON a.new_assessment_id=i.assessment_id
  JOIN _p1p5_d1010_new_questions c ON c.new_id=i.question_id;
 IF n_ass<>6 OR n_items<>24 OR n_swapped<>6
  OR (SELECT count(*) FROM _p1p5_d1010_new_questions)<>5
  OR (SELECT count(*) FROM private.exam_prep_question_content_meta m
    JOIN _p1p5_d1010_new_questions c ON c.new_id=m.question_id
    WHERE m.lifecycle_state='draft' AND m.exposure_state='withheld'
      AND m.qa_math_status='pending' AND m.qa_language_status='pending'
      AND m.qa_scope_status='pending' AND m.qa_technical_status='pending')<>5
  OR EXISTS(SELECT 1 FROM _p1p5_d1010_new_assess a
    JOIN private.exam_prep_assessments n ON n.id=a.new_assessment_id WHERE n.status<>'draft')
  OR EXISTS(SELECT 1 FROM _p1p5_d1010_old_assess a
    JOIN private.exam_prep_assessments orig ON orig.id=a.old_id WHERE orig.status<>'published')
  OR EXISTS(SELECT 1 FROM _p1p5_d1010_candidates c
    JOIN public.questions q ON q.id=c.old_id WHERE q.is_active OR q.quality_status='published')
 THEN RAISE EXCEPTION 'D10-10 verification failed; transaction rolled back'; END IF;
 RAISE NOTICE 'D10-10 SOURCE VERSIONING PASS: 5 draft question versions, 6 draft assessments, 24 cloned items, 6 swaps, all 6 originals still published';
END $verify$;
${verdict};
SELECT '${checkMode}_DONE' AS outcome;
`;
const run=spawnSync('psql',['-X','-q','-t','-A','-v','ON_ERROR_STOP=1'],{
 input:script,encoding:'utf8',maxBuffer:4*1024*1024,env:process.env
});
if(run.error)throw run.error;
if(run.status!==0 || !String(run.stdout).includes(checkMode+'_DONE')){
 console.error('D10-10 private source import failed. Diagnostic output intentionally omitted to protect question/solution text.');
 process.exit(1);
}
console.log(`D10-10 PRIVATE ${checkMode} PASS: 5 draft questions, 6 draft assessments, prior published history intact; ${mode==='stage'?'review + public release still OFF':'all inserted rows ROLLED BACK'}`);