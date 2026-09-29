-- Independent academic + trilingual QA contract for AW1-4 annual reserve top-up.
-- The 45 candidate items were independently re-solved/rechecked against their
-- canonical skill intent before this answer key was frozen.

\set ON_ERROR_STOP on

DO $$
DECLARE v_bad int; v_mcq int; v_input int; v_a int; v_b int; v_c int; v_d int;
BEGIN
  IF (SELECT count(*) FROM private.exam_prep_content_versions
      WHERE id IN (4803,4804) AND status='draft')<>2 THEN
    RAISE EXCEPTION 'annual reserve independent QA: draft versions missing';
  END IF;

  WITH expected(content_key,qtype,correct_answer) AS (VALUES
('P1QUA01-D02','mcq','A'),
('P1QUA01-D03','mcq','C'),
('P1QUA01-R03','input','3'),
('P1QUA01-R04','mcq','D'),
('P1QUA01-M02','mcq','B'),
('P1QUA02-D02','mcq','B'),
('P1QUA02-D03','mcq','D'),
('P1QUA02-R03','mcq','A'),
('P1QUA02-R04','mcq','C'),
('P1QUA02-M02','mcq','B'),
('P1QUA03-D02','mcq','C'),
('P1QUA03-D03','mcq','D'),
('P1QUA03-R03','mcq','B'),
('P1QUA03-R04','mcq','A'),
('P1QUA03-M02','mcq','D'),
('P1FUN01-D02','mcq','A'),
('P1FUN01-D03','mcq','C'),
('P1FUN01-R03','mcq','D'),
('P1FUN01-R04','input','18'),
('P1FUN01-M02','mcq','B'),
('P1FUN02-D02','mcq','C'),
('P1FUN02-D03','mcq','A'),
('P1FUN02-R03','mcq','D'),
('P1FUN02-R04','input','3'),
('P1FUN02-M02','mcq','B'),
('P5DAT01-D02','mcq','A'),
('P5DAT01-D03','mcq','C'),
('P5DAT01-R03','mcq','D'),
('P5DAT01-R04','mcq','B'),
('P5DAT01-M02','mcq','B'),
('P5DAT02-D02','mcq','B'),
('P5DAT02-D03','mcq','D'),
('P5DAT02-R03','input','30'),
('P5DAT02-R04','mcq','C'),
('P5DAT02-M02','mcq','A'),
('P5DAT04-D02','mcq','C'),
('P5DAT04-D03','mcq','D'),
('P5DAT04-R03','input','6'),
('P5DAT04-R04','mcq','A'),
('P5DAT04-M02','input','27'),
('P5DAT06-D02','mcq','B'),
('P5DAT06-D03','mcq','C'),
('P5DAT06-R03','input','4'),
('P5DAT06-R04','mcq','D'),
('P5DAT06-M02','mcq','A')
  ), actual AS (
    SELECT m.content_key,lower(q.qtype) AS qtype,q.correct_answer
    FROM private.exam_prep_question_content_meta m
    JOIN public.questions q ON q.id=m.question_id
    WHERE m.content_version_id IN (4803,4804)
  )
  SELECT count(*) INTO v_bad
  FROM expected e
  FULL JOIN actual a USING(content_key)
  WHERE a.content_key IS NULL OR e.content_key IS NULL
     OR a.qtype<>e.qtype OR a.correct_answer<>e.correct_answer;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve independent QA: independently solved answer map mismatch rows=%',v_bad;
  END IF;

  SELECT count(*) FILTER(WHERE lower(q.qtype)='mcq'),
         count(*) FILTER(WHERE lower(q.qtype)='input'),
         count(*) FILTER(WHERE lower(q.qtype)='mcq' AND q.correct_answer='A'),
         count(*) FILTER(WHERE lower(q.qtype)='mcq' AND q.correct_answer='B'),
         count(*) FILTER(WHERE lower(q.qtype)='mcq' AND q.correct_answer='C'),
         count(*) FILTER(WHERE lower(q.qtype)='mcq' AND q.correct_answer='D')
  INTO v_mcq,v_input,v_a,v_b,v_c,v_d
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4803,4804);

  IF (v_mcq,v_input,v_a,v_b,v_c,v_d)<>(38,7,9,10,9,10) THEN
    RAISE EXCEPTION 'annual reserve independent QA: item/balance distribution mismatch';
  END IF;

  -- Diagnostic distractor rules cover every wrong option exactly once.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4803,4804)
    AND m.reserve_role='diagnostic'
    AND (
      SELECT count(DISTINCT r.answer_match)
      FROM private.exam_prep_diagnostic_rules r
      WHERE r.content_meta_id=m.id
        AND r.rule_version='aw_reserve_v1'
        AND r.answer_kind='mcq_option'
        AND r.status='draft'
        AND r.answer_match<>q.correct_answer
    )<>3;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve independent QA: diagnostic distractor coverage mismatch rows=%',v_bad;
  END IF;

  -- Scope correction: DAT01 reserve variant 3 stays inside P5 5.1.
  IF NOT EXISTS(
    SELECT 1
    FROM private.exam_prep_question_content_meta m
    JOIN public.questions q ON q.id=m.question_id
    WHERE m.content_version_id=4804
      AND m.content_key='P5DAT01-D03'
      AND q.correct_answer='C'
      AND q.options_text_en::jsonb->>2='Cumulative-frequency graph'
      AND lower(q.question_text_en) LIKE '%median%'
      AND lower(q.question_text_en) LIKE '%quartile%'
      AND lower(q.question_text_en) NOT LIKE '%arm span%'
  ) THEN
    RAISE EXCEPTION 'annual reserve independent QA: DAT01-D03 scope correction missing';
  END IF;

  -- No source/mark-scheme language is claimed; source refs stay mapping-only.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  WHERE m.content_version_id IN (4803,4804)
    AND (
      m.originality_attestation NOT ILIKE 'Original iClub-authored%'
      OR m.coursebook_mapping_ref NOT ILIKE '%mapping only%'
      OR m.provenance_note NOT ILIKE '%annual-reserve top-up%'
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve independent QA: provenance/source mapping mismatch rows=%',v_bad;
  END IF;

  -- Trilingual parity: all text is populated, option cardinalities match, and
  -- the four P1 option sets found in language review are no longer English-only.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4803,4804)
    AND (
      nullif(btrim(q.question_text_en),'') IS NULL
      OR nullif(btrim(q.question_text_ru),'') IS NULL
      OR nullif(btrim(q.question_text_uz),'') IS NULL
      OR nullif(btrim(q.explanation_en),'') IS NULL
      OR nullif(btrim(q.explanation_ru),'') IS NULL
      OR nullif(btrim(q.explanation_uz),'') IS NULL
      OR (
        lower(q.qtype)='mcq' AND (
          jsonb_array_length(q.options_text_en::jsonb)<>4
          OR jsonb_array_length(q.options_text_ru::jsonb)<>4
          OR jsonb_array_length(q.options_text_uz::jsonb)<>4
        )
      )
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve independent QA: trilingual parity mismatch rows=%',v_bad;
  END IF;

  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_question_content_meta m
    JOIN public.questions q ON q.id=m.question_id
    WHERE m.content_version_id=4803
      AND m.content_key IN ('P1QUA02-R03','P1QUA02-R04','P1QUA03-R03','P1QUA03-M02')
      AND (q.options_text_ru=q.options_text_en OR q.options_text_uz=q.options_text_en)
  ) THEN
    RAISE EXCEPTION 'annual reserve independent QA: P1 option localization correction missing';
  END IF;

  -- Draft-only safety remains exact after QA corrections.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4803,4804)
    AND (
      m.lifecycle_state<>'draft'
      OR m.exposure_state<>'withheld'
      OR m.copyright_status<>'pending'
      OR m.qa_scope_status<>'pending'
      OR m.qa_math_status<>'pending'
      OR m.qa_language_status<>'pending'
      OR m.qa_technical_status<>'pending'
      OR q.is_active
      OR q.quality_status<>'draft'
      OR md5(concat_ws(chr(31),
        q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
        coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
        coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
        coalesce(q.image_url,''),coalesce(q.is_active::text,''),
        coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
        coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
        coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
        coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
        coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve independent QA: draft safety/snapshot mismatch rows=%',v_bad;
  END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_sessions s
    JOIN private.exam_prep_assessments a ON a.id=s.assessment_id
    WHERE a.content_version_id IN (4803,4804)
  ) OR EXISTS(
    SELECT 1 FROM public.practice_answers pa
    JOIN private.exam_prep_question_content_meta m ON m.question_id=pa.question_id
    WHERE m.content_version_id IN (4803,4804)
  ) OR EXISTS(
    SELECT 1 FROM public.tour_answers ta
    JOIN private.exam_prep_question_content_meta m ON m.question_id=ta.question_id
    WHERE m.content_version_id IN (4803,4804)
  ) THEN
    RAISE EXCEPTION 'annual reserve independent QA: draft acquired learner/legacy history';
  END IF;

  RAISE NOTICE 'AW1-4 annual reserve independent academic/trilingual QA: GREEN; content remains draft/pending';
END
$$;
