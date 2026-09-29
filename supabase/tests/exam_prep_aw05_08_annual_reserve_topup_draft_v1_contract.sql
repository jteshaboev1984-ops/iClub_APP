-- AW5-8 annual-reserve top-up draft v1 contract.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int;
BEGIN
  -- Exact draft versions, still fully withheld.
  IF (SELECT count(*) FROM private.exam_prep_content_versions
      WHERE id IN (4807,4808) AND status='draft')<>2 THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: expected two draft content versions';
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_question_content_meta
      WHERE content_version_id=4807)<>40
     OR (SELECT count(*) FROM private.exam_prep_question_content_meta
         WHERE content_version_id=4808)<>30
     OR (SELECT count(*) FROM private.exam_prep_question_content_meta
         WHERE content_version_id IN (4807,4808) AND reserve_role='diagnostic')<>28
     OR (SELECT count(*) FROM private.exam_prep_question_content_meta
         WHERE content_version_id IN (4807,4808) AND reserve_role='retest')<>28
     OR (SELECT count(*) FROM private.exam_prep_question_content_meta
         WHERE content_version_id IN (4807,4808) AND reserve_role='mixed')<>14
  THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: question-role cardinality mismatch';
  END IF;

  -- Draft source rows and governance flags remain unapproved/withheld.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4807,4808)
    AND (
      m.lifecycle_state<>'draft'
      OR m.exposure_state<>'withheld'
      OR m.copyright_status<>'pending'
      OR m.qa_scope_status<>'pending'
      OR m.qa_math_status<>'pending'
      OR m.qa_language_status<>'pending'
      OR m.qa_technical_status<>'pending'
      OR (m.reserve_role='diagnostic' AND m.diagnostic_rule_status<>'pending')
      OR (m.reserve_role<>'diagnostic' AND m.diagnostic_rule_status<>'not_applicable')
      OR q.subject_id<>5
      OR q.is_active
      OR q.quality_status<>'draft'
      OR q.qtype NOT IN ('mcq','input')
      OR nullif(btrim(q.question_text_en),'') IS NULL
      OR nullif(btrim(q.question_text_ru),'') IS NULL
      OR nullif(btrim(q.question_text_uz),'') IS NULL
      OR nullif(btrim(q.explanation_en),'') IS NULL
      OR nullif(btrim(q.explanation_ru),'') IS NULL
      OR nullif(btrim(q.explanation_uz),'') IS NULL
      OR nullif(btrim(m.originality_attestation),'') IS NULL
      OR nullif(btrim(m.provenance_note),'') IS NULL
      OR nullif(btrim(m.official_scope_ref),'') IS NULL
      OR nullif(btrim(m.coursebook_mapping_ref),'') IS NULL
      OR (q.qtype='mcq' AND (
        q.correct_answer NOT IN ('A','B','C','D')
        OR jsonb_typeof(q.options_text_en::jsonb)<>'array'
        OR jsonb_typeof(q.options_text_ru::jsonb)<>'array'
        OR jsonb_typeof(q.options_text_uz::jsonb)<>'array'
        OR jsonb_array_length(q.options_text_en::jsonb)<>4
        OR jsonb_array_length(q.options_text_ru::jsonb)<>4
        OR jsonb_array_length(q.options_text_uz::jsonb)<>4
        OR (SELECT count(DISTINCT z.v) FROM jsonb_array_elements_text(q.options_text_en::jsonb) z(v))<>4
        OR (SELECT count(DISTINCT z.v) FROM jsonb_array_elements_text(q.options_text_ru::jsonb) z(v))<>4
        OR (SELECT count(DISTINCT z.v) FROM jsonb_array_elements_text(q.options_text_uz::jsonb) z(v))<>4
      ))
      OR (q.qtype='input' AND (
        nullif(btrim(q.correct_answer),'') IS NULL
        OR q.options_text_en::jsonb<>'[]'::jsonb
        OR q.options_text_ru::jsonb<>'[]'::jsonb
        OR q.options_text_uz::jsonb<>'[]'::jsonb
      ))
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: governance/trilingual/type rows=%',v_bad;
  END IF;

  -- Frozen source snapshots are exact.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4807,4808)
    AND md5(concat_ws(chr(31),
      q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
      coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
      coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
      coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: frozen snapshot mismatch rows=%',v_bad;
  END IF;

  -- Canonical source-map boundaries.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  WHERE m.content_version_id IN (4807,4808)
    AND (
      (m.primary_skill_code LIKE 'P1-FUN-%' AND
        (m.official_scope_ref NOT LIKE '%P1 1.2 Functions%' OR m.coursebook_mapping_ref NOT LIKE '%Ch2%24-42%'))
      OR (m.primary_skill_code LIKE 'P1-COO-%' AND
        (m.official_scope_ref NOT LIKE '%P1 1.3 Coordinate geometry%' OR m.coursebook_mapping_ref NOT LIKE '%Ch3%48-67%'))
      OR (m.primary_skill_code LIKE 'P1-CIR-%' AND
        (m.official_scope_ref NOT LIKE '%P1 1.4 Circular measure%' OR m.coursebook_mapping_ref NOT LIKE '%Ch4%74-81%'))
      OR (m.primary_skill_code LIKE 'P1-TRI-%' AND
        (m.official_scope_ref NOT LIKE '%P1 1.5 Trigonometry%' OR m.coursebook_mapping_ref NOT LIKE '%Ch5%86-104%'))
      OR (m.primary_skill_code LIKE 'P5-CNT-%' AND
        (m.official_scope_ref NOT LIKE '%P5 5.2 Permutations and combinations%' OR m.coursebook_mapping_ref NOT LIKE '%Ch6%98-111%'))
      OR (m.primary_skill_code LIKE 'P5-PRO-%' AND
        (m.official_scope_ref NOT LIKE '%P5 5.3 Probability%' OR m.coursebook_mapping_ref NOT LIKE '%Ch4%63-82%'))
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: source-map mismatch rows=%',v_bad;
  END IF;

  -- Exact per-skill reserve top-up: 2 diagnostics + 2 retests + 1 mixed.
  SELECT count(*) INTO v_bad
  FROM (
    SELECT content_version_id,primary_skill_code,
      count(*) FILTER (WHERE reserve_role='diagnostic') d,
      count(*) FILTER (WHERE reserve_role='retest') r,
      count(*) FILTER (WHERE reserve_role='mixed') x,
      count(*) n
    FROM private.exam_prep_question_content_meta
    WHERE content_version_id IN (4807,4808)
    GROUP BY content_version_id,primary_skill_code
    HAVING count(*) FILTER (WHERE reserve_role='diagnostic')<>2
        OR count(*) FILTER (WHERE reserve_role='retest')<>2
        OR count(*) FILTER (WHERE reserve_role='mixed')<>1
        OR count(*)<>5
  ) q;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: per-skill reserve shape rows=%',v_bad;
  END IF;

  -- Balanced diagnostic answer positions per component.
  SELECT
    count(*) FILTER (WHERE q.correct_answer='A'),
    count(*) FILTER (WHERE q.correct_answer='B'),
    count(*) FILTER (WHERE q.correct_answer='C'),
    count(*) FILTER (WHERE q.correct_answer='D')
  INTO v_a,v_b,v_c,v_d
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id=4807 AND m.reserve_role='diagnostic';
  IF (v_a,v_b,v_c,v_d)<>(4,4,4,4) THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: P1 diagnostic balance A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  END IF;

  SELECT
    count(*) FILTER (WHERE q.correct_answer='A'),
    count(*) FILTER (WHERE q.correct_answer='B'),
    count(*) FILTER (WHERE q.correct_answer='C'),
    count(*) FILTER (WHERE q.correct_answer='D')
  INTO v_a,v_b,v_c,v_d
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id=4808 AND m.reserve_role='diagnostic';
  IF (v_a,v_b,v_c,v_d)<>(3,3,3,3) THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: P5 diagnostic balance A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  END IF;

  -- No exact same-skill English stem reuse against published content.
  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_question_content_meta m
    JOIN public.questions q ON q.id=m.question_id
    JOIN private.exam_prep_question_content_meta oldm
      ON oldm.primary_skill_code=m.primary_skill_code
     AND oldm.content_version_id<>m.content_version_id
    JOIN private.exam_prep_content_versions oldcv
      ON oldcv.id=oldm.content_version_id AND oldcv.status='published'
    JOIN public.questions oldq ON oldq.id=oldm.question_id
    WHERE m.content_version_id IN (4807,4808)
      AND lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: exact published same-skill stem duplicate';
  END IF;

  -- Exact diagnostic-rule surface: three wrong-option rules per diagnostic.
  IF (SELECT count(*)
      FROM private.exam_prep_diagnostic_rules r
      JOIN private.exam_prep_question_content_meta m ON m.id=r.content_meta_id
      WHERE m.content_version_id IN (4807,4808)
        AND r.rule_version='aw_reserve_v1'
        AND r.status='draft')<>84 THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: expected 84 draft misconception rules';
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4807,4808)
    AND m.reserve_role='diagnostic'
    AND (
      q.qtype<>'mcq'
      OR (
        SELECT count(*)
        FROM private.exam_prep_diagnostic_rules r
        WHERE r.content_meta_id=m.id
          AND r.rule_version='aw_reserve_v1'
          AND r.status='draft'
          AND r.answer_kind='mcq_option'
          AND r.answer_match<>q.correct_answer
          AND r.weak_skill_code=m.primary_skill_code
          AND nullif(btrim(r.feedback_en),'') IS NOT NULL
          AND nullif(btrim(r.feedback_ru),'') IS NOT NULL
          AND nullif(btrim(r.feedback_uz),'') IS NOT NULL
          AND nullif(btrim(r.next_action_en),'') IS NOT NULL
          AND nullif(btrim(r.next_action_ru),'') IS NOT NULL
          AND nullif(btrim(r.next_action_uz),'') IS NOT NULL
      )<>3
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: diagnostic-rule coverage rows=%',v_bad;
  END IF;

  -- Exact assessment shape: 4 component diagnostics, 28 isolated retests,
  -- 2 component mixed sets, all holdout-only.
  IF (SELECT count(*) FROM private.exam_prep_assessments
      WHERE content_version_id IN (4807,4808) AND status='draft')<>34
     OR (SELECT count(*) FROM private.exam_prep_assessments
         WHERE content_version_id IN (4807,4808) AND assessment_type='diagnostic')<>4
     OR (SELECT count(*) FROM private.exam_prep_assessments
         WHERE content_version_id IN (4807,4808) AND assessment_type='retest')<>28
     OR (SELECT count(*) FROM private.exam_prep_assessments
         WHERE content_version_id IN (4807,4808) AND assessment_type='mixed')<>2
     OR (SELECT count(*) FROM private.exam_prep_assessment_items ai
         JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id
         WHERE a.content_version_id IN (4807,4808))<>70
  THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: assessment cardinality mismatch';
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_assessment_items ai
  JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id
  JOIN private.exam_prep_question_content_meta m
    ON m.question_id=ai.question_id
   AND m.content_version_id=a.content_version_id
  WHERE a.content_version_id IN (4807,4808)
    AND (
      ai.question_id IS NULL
      OR ai.written_task_id IS NOT NULL
      OR ai.is_holdout IS NOT TRUE
      OR ai.primary_skill_code<>m.primary_skill_code
      OR ai.reserve_role<>m.reserve_role
      OR ai.reserve_role<>a.assessment_type
      OR ai.primary_skill_code NOT LIKE a.component_code||'-%'
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: holdout/component/role rows=%',v_bad;
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_assessments a
  WHERE a.content_version_id IN (4807,4808)
    AND a.assessment_type='retest'
    AND (SELECT count(*) FROM private.exam_prep_assessment_items ai WHERE ai.assessment_id=a.id)<>1;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: non-isolated retest rows=%',v_bad;
  END IF;

  IF EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE content_version_id IN (4807,4808)) THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: reserve-only version contains written tasks';
  END IF;

  -- No learner or legacy history may reference a draft reserve version.
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_sessions s
    JOIN private.exam_prep_assessments a ON a.id=s.assessment_id
    WHERE a.content_version_id IN (4807,4808)
  ) OR EXISTS(
    SELECT 1 FROM public.practice_answers pa
    JOIN private.exam_prep_question_content_meta m ON m.question_id=pa.question_id
    WHERE m.content_version_id IN (4807,4808)
  ) OR EXISTS(
    SELECT 1 FROM public.tour_answers ta
    JOIN private.exam_prep_question_content_meta m ON m.question_id=ta.question_id
    WHERE m.content_version_id IN (4807,4808)
  ) THEN
    RAISE EXCEPTION 'aw05_08 annual reserve draft: learner/legacy history contamination';
  END IF;
END
$$;

\echo 'AW5-8 annual-reserve top-up draft v1 contract: GREEN'
