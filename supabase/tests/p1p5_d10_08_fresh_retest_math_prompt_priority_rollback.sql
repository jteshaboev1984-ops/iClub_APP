-- D10-08: protected retest prompt novelty, no hard gate; PG17 DISPOSABLE.
-- Actual content comes from existing P1/P5 corpus, not invented test answers.
-- Every temporary assessment/status mutation runs in one ROLLBACK.
\set ON_ERROR_STOP on
DO $pre$
BEGIN
 IF current_database()<>'postgres'
    OR current_setting('server_version_num')::int<170000
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM auth.users)<>2
    OR (SELECT count(*) FROM public.users)<>2
 THEN RAISE EXCEPTION 'D10-08 refused: isolated two-user PG17 only'; END IF;
END $pre$;
CREATE TEMP TABLE d1008_baseline ON COMMIT PRESERVE ROWS AS
 SELECT
  (SELECT count(*) FROM private.exam_prep_assessments) assessment_count,
  (SELECT count(*) FROM private.exam_prep_assessment_items) item_count,
  (SELECT count(*) FROM private.exam_prep_question_content_meta) meta_count,
  (SELECT count(*) FROM public.questions) question_count,
  (SELECT count(*) FROM private.exam_prep_sessions) session_count,
  (SELECT count(*) FROM private.exam_prep_session_items) session_item_count;
BEGIN;
DO $proof$
DECLARE
 v_a text; v_b text;
 v_q bigint;v_cv bigint;
 v_ass bigint;
 v_after bigint;
 v_before bigint;
 v_no_alternative bigint;
 v_normalized text;
 r record;
BEGIN
 IF current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'D10-08 live run refused'; END IF;
 -- These are real original prompts. Distinct options or different content
 -- IDs must not make an unchanged mathematics question count as fresh.
 FOR r IN SELECT * FROM (VALUES
  ('P1DIF05-A02','P1DIF05-M01'),
  ('P1INT03-L02','P1INT03-R04'),
  ('P1QUA03-A01','P1QUA03-D01'),
  ('P1INT03-D01','P1INT03-D03'),
  ('P1INT04-D01','P1INT04-R04')
 ) x(k1,k2)
 LOOP
   SELECT private.exam_prep_canonical_prompt_v1(q.question_text_en)
   INTO STRICT v_a
   FROM private.exam_prep_question_content_meta m
   JOIN public.questions q ON q.id=m.question_id
   WHERE m.content_key=r.k1;
   SELECT private.exam_prep_canonical_prompt_v1(q.question_text_en)
   INTO STRICT v_b
   FROM private.exam_prep_question_content_meta m
   JOIN public.questions q ON q.id=m.question_id
   WHERE m.content_key=r.k2;
   IF v_a IS DISTINCT FROM v_b
   THEN RAISE EXCEPTION 'D10-08 real duplicate pair not normalized: % / %',
     r.k1,r.k2; END IF;
 END LOOP;
 IF private.exam_prep_canonical_prompt_v1('x² + 6x + 10 = 0')
      =private.exam_prep_canonical_prompt_v1('x^2 - 6x + 10 = 0')
 OR private.exam_prep_canonical_prompt_v1('x≤2')
      =private.exam_prep_canonical_prompt_v1('x≥2')
 OR private.exam_prep_canonical_prompt_v1('x³−12x')
      IS DISTINCT FROM private.exam_prep_canonical_prompt_v1('x^3-12x')
 THEN RAISE EXCEPTION 'D10-08 unsafe equation sign or glyph normalization'; END IF;

 SELECT m.question_id,m.content_version_id INTO STRICT v_q,v_cv
 FROM private.exam_prep_question_content_meta m
 WHERE m.content_key='P1INT03-R04'
  AND m.primary_skill_code='P1-INT-03'
  AND m.reserve_role='retest' AND m.lifecycle_state='reserve';
 IF (SELECT count(DISTINCT ai.assessment_id)
     FROM private.exam_prep_assessment_items ai
     JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id
     WHERE ai.primary_skill_code='P1-INT-03' AND ai.reserve_role='retest'
       AND a.assessment_type='retest' AND a.status='published')<4
 THEN RAISE EXCEPTION 'D10-08 fixture must have four unchanged retest variants'; END IF;

 v_before:=private.exam_prep_select_fresh_retest_assessment_v1(
   '00000000-0000-4000-8000-000000000008'::uuid,'P1','P1-INT-03');
 IF v_before IS NULL
 THEN RAISE EXCEPTION 'D10-08 existing retest feature unexpectedly unavailable'; END IF;

 -- Give a duplicated question the LOWEST assessment ID. The old selector
 -- would choose it; the corrected selector must pick a genuinely new prompt.
 INSERT INTO private.exam_prep_assessments (
  id,content_version_id,assessment_key,assessment_version,component_code,
  assessment_type,status,title_en,title_ru,title_uz,approved_at
 ) OVERRIDING SYSTEM VALUE VALUES (
  -100008,v_cv,'d1008_isolated_duplicate_prompt','test-v1','P1',
  'retest','published','Isolated novelty test','Изолированный тест',
  'Ajratilgan sinov',now()
 );
 INSERT INTO private.exam_prep_assessment_items
 (assessment_id,item_order,question_id,written_task_id,primary_skill_code,
  reserve_role,is_holdout)
 VALUES(-100008,1,v_q,null,'P1-INT-03','retest',true);

 v_ass:=private.exam_prep_select_fresh_retest_assessment_v1(
   '00000000-0000-4000-8000-000000000008'::uuid,'P1','P1-INT-03');
 IF v_ass IS NULL OR v_ass=-100008
 THEN RAISE EXCEPTION 'D10-08 selector still favours lowest-ID duplicated prompt'; END IF;
 -- Ensure selected real content is not duplicated from an already
 -- released learning item when at least one genuine alternative exists.
 SELECT private.exam_prep_canonical_prompt_v1(q.question_text_en)
 INTO STRICT v_normalized
 FROM private.exam_prep_assessment_items ai
 JOIN public.questions q ON q.id=ai.question_id
 WHERE ai.assessment_id=v_ass AND ai.item_order=1;
 IF EXISTS(
  SELECT 1 FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.primary_skill_code='P1-INT-03'
   AND m.reserve_role='learning' AND m.lifecycle_state='published'
   AND private.exam_prep_canonical_prompt_v1(q.question_text_en)=v_normalized
 ) THEN RAISE EXCEPTION 'D10-08 selector chose released learning clone over alternatives'; END IF;

 -- Not a new content-access gate: if only duplicate candidates remain,
 -- keep the old fallback so a due retest remains reachable.
 UPDATE private.exam_prep_assessments a SET status='retired'
 WHERE a.assessment_type='retest' AND a.status='published'
  AND a.component_code='P1' AND a.id<>-100008
  AND EXISTS(
    SELECT 1 FROM private.exam_prep_assessment_items ai
    WHERE ai.assessment_id=a.id AND ai.primary_skill_code='P1-INT-03'
     AND ai.reserve_role='retest'
  );
 v_no_alternative:=private.exam_prep_select_fresh_retest_assessment_v1(
   '00000000-0000-4000-8000-000000000008'::uuid,'P1','P1-INT-03');
 IF v_no_alternative IS DISTINCT FROM -100008
 THEN RAISE EXCEPTION 'D10-08 introduced a new no-content retest blocker'; END IF;

 RAISE NOTICE 'D10-08 PASS: all 5 true duplicates, signs preserved, fresh-retake priority and fallback with zero user-access gate';
END $proof$;
ROLLBACK;
DO $post$
DECLARE v record;
BEGIN
 IF current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM auth.users)<>2
 THEN RAISE EXCEPTION 'D10-08 postflight refused non-isolated database'; END IF;
 SELECT * INTO STRICT v FROM pg_temp.d1008_baseline;
 IF EXISTS(SELECT 1 FROM private.exam_prep_assessments WHERE id=-100008)
  OR (SELECT count(*) FROM private.exam_prep_assessments)<>v.assessment_count
  OR (SELECT count(*) FROM private.exam_prep_assessment_items)<>v.item_count
  OR (SELECT count(*) FROM private.exam_prep_question_content_meta)<>v.meta_count
  OR (SELECT count(*) FROM public.questions)<>v.question_count
  OR (SELECT count(*) FROM private.exam_prep_sessions)<>v.session_count
  OR (SELECT count(*) FROM private.exam_prep_session_items)<>v.session_item_count
 THEN RAISE EXCEPTION 'D10-08 rollback did not preserve original assessment or user counts'; END IF;
 RAISE NOTICE 'D10-08 ROLLBACK PASS: no synthetic assessments, learner sessions, answers or source content changed';
END $post$;
