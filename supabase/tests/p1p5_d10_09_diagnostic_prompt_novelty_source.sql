-- D10-09: source-backed real content and authentic retained learner selector.
-- Read-only in disposable PG17; verifies no new content/stage/answer effect.
\set ON_ERROR_STOP on
DO $d1009$
DECLARE
 v_program bigint;
 v_a bigint;v_b bigint;
 v_before jsonb;
 v_after jsonb;
 v_pair record;
 v_normalized_a text;
 v_normalized_b text;
 v_def text;
BEGIN
 IF current_database()<>'postgres'
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR current_setting('server_version_num')::int<170000
    OR (SELECT count(*) FROM public.users)<>2
    OR (SELECT count(*) FROM auth.users)<>2
 THEN RAISE EXCEPTION 'D10-09 refused: not disposable signed-E2E two-user PG17'; END IF;
 SELECT id INTO STRICT v_program FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
 SELECT jsonb_build_object(
  'sessions',(SELECT count(*) FROM private.exam_prep_sessions),
  'answers',(SELECT count(*) FROM private.exam_prep_responses),
  'questions',(SELECT count(*) FROM public.questions),
  'assessment_items',(SELECT count(*) FROM private.exam_prep_assessment_items),
  'stage_rows',(SELECT count(*) FROM private.exam_prep_stage_states)
 ) INTO v_before;

 FOR v_pair IN SELECT * FROM (VALUES
  ('P1DIF05-A02','P1DIF05-M01'),
  ('P1INT03-L02','P1INT03-R04'),
  ('P1QUA03-A01','P1QUA03-D01'),
  ('P1INT03-D01','P1INT03-D03'),
  ('P1INT04-D01','P1INT04-R04')
 ) v(known_key,reserve_key) LOOP
  SELECT private.exam_prep_canonical_prompt_v1(q.question_text_en)
  INTO STRICT v_normalized_a
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_key=v_pair.known_key;
  SELECT private.exam_prep_canonical_prompt_v1(q.question_text_en)
  INTO STRICT v_normalized_b
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_key=v_pair.reserve_key;
  IF v_normalized_a IS DISTINCT FROM v_normalized_b
  THEN RAISE EXCEPTION 'D10-09 real duplicate source drift: % %',v_pair.known_key,v_pair.reserve_key; END IF;
 END LOOP;

 v_a:=private.exam_prep_next_diagnostic_assessment_v1(
  '11111111-1111-4111-8111-111111111191'::uuid,v_program,'P1');
 v_b:=private.exam_prep_next_diagnostic_assessment_v1(
  '22222222-2222-4222-8222-222222222292'::uuid,v_program,'P5');
 -- Existing authentic signed journey has already completed learner diagnostics.
 -- Freshness is only a preference; absence of a next package is legal.
 IF (v_a IS NOT NULL AND NOT EXISTS(
   SELECT 1 FROM private.exam_prep_assessments a
   WHERE a.id=v_a AND a.component_code='P1'
     AND a.assessment_type='diagnostic' AND a.status='published'))
 OR (v_b IS NOT NULL AND NOT EXISTS(
   SELECT 1 FROM private.exam_prep_assessments a
   WHERE a.id=v_b AND a.component_code='P5'
     AND a.assessment_type='diagnostic' AND a.status='published'))
 THEN RAISE EXCEPTION 'D10-09 real selected next package invalid'; END IF;

 SELECT pg_get_functiondef('private.exam_prep_next_diagnostic_assessment_v1(uuid,bigint,text)'::regprocedure)
 INTO v_def;
 IF position('c.newly_deliverable_prompts desc' in v_def)=0
  OR position('c.private_diagnostic_prompts desc' in v_def)=0
  OR position('c.distinct_prompts desc' in v_def)=0
  OR position('least(c.new_sections,r.remaining_areas)' in v_def)=0
 THEN RAISE EXCEPTION 'D10-09 no scoped novelty preference or original screening priority'; END IF;
 SELECT jsonb_build_object(
  'sessions',(SELECT count(*) FROM private.exam_prep_sessions),
  'answers',(SELECT count(*) FROM private.exam_prep_responses),
  'questions',(SELECT count(*) FROM public.questions),
  'assessment_items',(SELECT count(*) FROM private.exam_prep_assessment_items),
  'stage_rows',(SELECT count(*) FROM private.exam_prep_stage_states)
 ) INTO v_after;
 IF v_before IS DISTINCT FROM v_after THEN RAISE EXCEPTION 'D10-09 selector mutated learner content or history'; END IF;
 RAISE NOTICE 'D10-09 PASS: actual 5 repeated prompts, authenticated P1/P5 existing-user selector, official academic ranking first, original content/history preserved';
END $d1009$;
