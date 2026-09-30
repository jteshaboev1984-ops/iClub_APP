-- AW9-12 annual reserve top-up draft v1 contract.
-- Read-only acceptance checks after the draft migration stack.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int;
BEGIN
  IF (SELECT count(*) FROM private.exam_prep_content_versions
      WHERE id IN (4811,4812) AND status='draft')<>2 THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: expected two draft versions';
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_question_content_meta
      WHERE content_version_id IN (4811,4812))<>70
     OR (SELECT count(*) FROM private.exam_prep_question_content_meta
         WHERE content_version_id IN (4811,4812) AND reserve_role='diagnostic')<>28
     OR (SELECT count(*) FROM private.exam_prep_question_content_meta
         WHERE content_version_id IN (4811,4812) AND reserve_role='retest')<>28
     OR (SELECT count(*) FROM private.exam_prep_question_content_meta
         WHERE content_version_id IN (4811,4812) AND reserve_role='mixed')<>14
  THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: question-role cardinality mismatch';
  END IF;

  WITH expected(component_code,skill_code) AS (VALUES
    ('P1','P1-QUA-04'),('P1','P1-QUA-05'),('P1','P1-QUA-06'),('P1','P1-FUN-03'),('P1','P1-FUN-04'),('P1','P1-FUN-05'),('P1','P1-COO-04'),('P1','P1-CIR-02'),
    ('P5','P5-DAT-03'),('P5','P5-DAT-05'),('P5','P5-DAT-07'),('P5','P5-CNT-05'),('P5','P5-PRO-02'),('P5','P5-PRO-04')
  ), got AS (
    SELECT cv.component_code,m.primary_skill_code AS skill_code,
      count(*) FILTER (WHERE m.reserve_role='diagnostic') AS d,
      count(*) FILTER (WHERE m.reserve_role='retest') AS r,
      count(*) FILTER (WHERE m.reserve_role='mixed') AS x
    FROM private.exam_prep_question_content_meta m
    JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
    WHERE m.content_version_id IN (4811,4812)
    GROUP BY cv.component_code,m.primary_skill_code
  )
  SELECT count(*) INTO v_bad
  FROM expected e LEFT JOIN got g USING(component_code,skill_code)
  WHERE coalesce(g.d,0)<>2 OR coalesce(g.r,0)<>2 OR coalesce(g.x,0)<>1;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: per-skill delta mismatch rows=%',v_bad;
  END IF;

  -- Prospective annual numeric floor after this reserve is governed:
  -- 3 diagnostics, 8 learning/transfer, 4 delayed retests, >=2 written tasks.
  WITH expected(component_code,skill_code) AS (VALUES
    ('P1','P1-QUA-04'),('P1','P1-QUA-05'),('P1','P1-QUA-06'),('P1','P1-FUN-03'),('P1','P1-FUN-04'),('P1','P1-FUN-05'),('P1','P1-COO-04'),('P1','P1-CIR-02'),
    ('P5','P5-DAT-03'),('P5','P5-DAT-05'),('P5','P5-DAT-07'),('P5','P5-CNT-05'),('P5','P5-PRO-02'),('P5','P5-PRO-04')
  ), q AS (
    SELECT cv.component_code,m.primary_skill_code AS skill_code,
      count(*) FILTER(WHERE m.reserve_role='diagnostic') AS d,
      count(*) FILTER(WHERE m.reserve_role='learning') AS l,
      count(*) FILTER(WHERE m.reserve_role='retest') AS r,
      count(*) FILTER(WHERE m.reserve_role='mixed') AS x
    FROM private.exam_prep_question_content_meta m
    JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
    JOIN expected e ON e.component_code=cv.component_code AND e.skill_code=m.primary_skill_code
    WHERE (cv.status='published' AND m.lifecycle_state IN ('published','reserve'))
       OR (cv.id IN (4811,4812) AND cv.status='draft' AND m.lifecycle_state='draft')
    GROUP BY cv.component_code,m.primary_skill_code
  ), w AS (
    SELECT component_code,primary_skill_code AS skill_code,count(*) AS n
    FROM private.exam_prep_written_tasks
    WHERE lifecycle_state='published'
      AND primary_skill_code IN (
        'P1-QUA-04','P1-QUA-05','P1-QUA-06','P1-FUN-03','P1-FUN-04','P1-FUN-05','P1-COO-04','P1-CIR-02',
        'P5-DAT-03','P5-DAT-05','P5-DAT-07','P5-CNT-05','P5-PRO-02','P5-PRO-04'
      )
    GROUP BY component_code,primary_skill_code
  )
  SELECT count(*) INTO v_bad
  FROM expected e LEFT JOIN q USING(component_code,skill_code) LEFT JOIN w USING(component_code,skill_code)
  WHERE coalesce(q.d,0)<>3
     OR coalesce(q.l,0)+coalesce(q.x,0)<>8
     OR coalesce(q.r,0)<>4
     OR coalesce(w.n,0)<2;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: prospective annual numeric floor not closed rows=%',v_bad;
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4811,4812)
    AND (
      m.lifecycle_state<>'draft' OR m.exposure_state<>'withheld'
      OR m.copyright_status<>'pending' OR m.qa_scope_status<>'pending'
      OR m.qa_math_status<>'pending' OR m.qa_language_status<>'pending' OR m.qa_technical_status<>'pending'
      OR (m.reserve_role='diagnostic' AND m.diagnostic_rule_status<>'pending')
      OR (m.reserve_role<>'diagnostic' AND m.diagnostic_rule_status<>'not_applicable')
      OR q.is_active OR q.quality_status<>'draft'
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: exposure/QA boundary failure rows=%',v_bad;
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4811,4812)
    AND (
      nullif(btrim(q.question_text_en),'') IS NULL
      OR nullif(btrim(q.question_text_ru),'') IS NULL
      OR nullif(btrim(q.question_text_uz),'') IS NULL
      OR nullif(btrim(q.explanation_en),'') IS NULL
      OR nullif(btrim(q.explanation_ru),'') IS NULL
      OR nullif(btrim(q.explanation_uz),'') IS NULL
      OR (q.qtype='mcq' AND (
        q.correct_answer NOT IN ('A','B','C','D')
        OR jsonb_array_length(q.options_text_en::jsonb)<>4
        OR jsonb_array_length(q.options_text_ru::jsonb)<>4
        OR jsonb_array_length(q.options_text_uz::jsonb)<>4
        OR (SELECT count(distinct v) FROM jsonb_array_elements_text(q.options_text_en::jsonb) z(v))<>4
        OR (SELECT count(distinct v) FROM jsonb_array_elements_text(q.options_text_ru::jsonb) z(v))<>4
        OR (SELECT count(distinct v) FROM jsonb_array_elements_text(q.options_text_uz::jsonb) z(v))<>4
      ))
      OR (q.qtype='input' AND (
        q.options_text_en::jsonb<>'[]'::jsonb
        OR q.options_text_ru::jsonb<>'[]'::jsonb
        OR q.options_text_uz::jsonb<>'[]'::jsonb
        OR nullif(btrim(q.correct_answer),'') IS NULL
      ))
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: trilingual/type/options failure rows=%',v_bad;
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4811,4812)
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
    RAISE EXCEPTION 'aw09_12 annual reserve draft: source snapshot mismatch rows=%',v_bad;
  END IF;

  -- Exact English stem reuse against older governed content is forbidden.
  WITH candidate AS (
    SELECT m.primary_skill_code,q.id,lower(regexp_replace(btrim(q.question_text_en),'\s+','','g')) AS stem
    FROM private.exam_prep_question_content_meta m
    JOIN public.questions q ON q.id=m.question_id
    WHERE m.content_version_id IN (4811,4812)
  )
  SELECT count(*) INTO v_bad
  FROM candidate d
  JOIN private.exam_prep_question_content_meta oldm
    ON oldm.primary_skill_code=d.primary_skill_code
   AND oldm.content_version_id NOT IN (4811,4812)
  JOIN private.exam_prep_content_versions oldcv ON oldcv.id=oldm.content_version_id AND oldcv.status='published'
  JOIN public.questions oldq ON oldq.id=oldm.question_id
  WHERE lower(regexp_replace(btrim(oldq.question_text_en),'\s+','','g'))=d.stem;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: exact same-skill old-stem overlap rows=%',v_bad;
  END IF;

  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_question_content_meta m JOIN public.questions q ON q.id=m.question_id
    WHERE m.content_version_id IN (4811,4812)
    GROUP BY lower(regexp_replace(btrim(q.question_text_en),'\s+','','g'))
    HAVING count(*)>1
  ) THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: duplicate stem inside candidate';
  END IF;

  IF (SELECT count(*)
      FROM private.exam_prep_diagnostic_rules r
      JOIN private.exam_prep_question_content_meta m ON m.id=r.content_meta_id
      WHERE m.content_version_id IN (4811,4812)
        AND r.rule_version='aw_reserve_v1' AND r.status='draft')<>84 THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: expected 84 diagnostic rules';
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4811,4812) AND m.reserve_role='diagnostic'
    AND (
      q.qtype<>'mcq'
      OR (SELECT count(*) FROM private.exam_prep_diagnostic_rules r
          WHERE r.content_meta_id=m.id AND r.rule_version='aw_reserve_v1'
            AND r.status='draft' AND r.answer_kind='mcq_option'
            AND r.answer_match<>q.correct_answer
            AND r.weak_skill_code=m.primary_skill_code
            AND nullif(btrim(r.feedback_en),'') IS NOT NULL
            AND nullif(btrim(r.feedback_ru),'') IS NOT NULL
            AND nullif(btrim(r.feedback_uz),'') IS NOT NULL
            AND nullif(btrim(r.next_action_en),'') IS NOT NULL
            AND nullif(btrim(r.next_action_ru),'') IS NOT NULL
            AND nullif(btrim(r.next_action_uz),'') IS NOT NULL)<>3
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: diagnostic-rule coverage failure rows=%',v_bad;
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_assessments
      WHERE id BETWEEN 35387 AND 35420 AND status='draft')<>34
     OR (SELECT count(*) FROM private.exam_prep_assessments
         WHERE id BETWEEN 35387 AND 35420 AND assessment_type='diagnostic')<>4
     OR (SELECT count(*) FROM private.exam_prep_assessments
         WHERE id BETWEEN 35387 AND 35420 AND assessment_type='retest')<>28
     OR (SELECT count(*) FROM private.exam_prep_assessments
         WHERE id BETWEEN 35387 AND 35420 AND assessment_type='mixed')<>2
     OR (SELECT count(*) FROM private.exam_prep_assessment_items
         WHERE assessment_id BETWEEN 35387 AND 35420)<>70
  THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: assessment cardinality mismatch';
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_assessment_items ai
  JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id
  JOIN private.exam_prep_question_content_meta m ON m.question_id=ai.question_id
  WHERE ai.assessment_id BETWEEN 35387 AND 35420
    AND (
      NOT ai.is_holdout OR ai.written_task_id IS NOT NULL
      OR ai.primary_skill_code<>m.primary_skill_code
      OR ai.reserve_role<>m.reserve_role
      OR ai.reserve_role<>a.assessment_type
      OR m.content_version_id<>a.content_version_id
      OR ai.primary_skill_code NOT LIKE a.component_code||'-%'
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: assessment isolation/role failure rows=%',v_bad;
  END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_assessments a
    JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
    WHERE a.id BETWEEN 35387 AND 35420
    GROUP BY a.id,a.assessment_type
    HAVING (a.assessment_type='retest' AND count(*)<>1)
        OR (a.assessment_type='diagnostic' AND count(*) NOT IN (6,8))
        OR (a.assessment_type='mixed' AND count(*) NOT IN (6,8))
  ) THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: assessment shape failure';
  END IF;

  -- Diagnostic answer positions are balanced independently by component.
  SELECT
    count(*) FILTER(WHERE q.correct_answer='A'),
    count(*) FILTER(WHERE q.correct_answer='B'),
    count(*) FILTER(WHERE q.correct_answer='C'),
    count(*) FILTER(WHERE q.correct_answer='D')
  INTO v_a,v_b,v_c,v_d
  FROM private.exam_prep_question_content_meta m JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id=4811 AND m.reserve_role='diagnostic';
  IF (v_a,v_b,v_c,v_d)<>(4,4,4,4) THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: P1 diagnostic answer balance A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  END IF;

  SELECT
    count(*) FILTER(WHERE q.correct_answer='A'),
    count(*) FILTER(WHERE q.correct_answer='B'),
    count(*) FILTER(WHERE q.correct_answer='C'),
    count(*) FILTER(WHERE q.correct_answer='D')
  INTO v_a,v_b,v_c,v_d
  FROM private.exam_prep_question_content_meta m JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id=4812 AND m.reserve_role='diagnostic';
  IF (v_a,v_b,v_c,v_d)<>(3,3,3,3) THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: P5 diagnostic answer balance A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_sessions s
    JOIN private.exam_prep_assessments a ON a.id=s.assessment_id
    WHERE a.content_version_id IN (4811,4812)
  ) OR EXISTS(
    SELECT 1 FROM public.practice_answers pa
    JOIN private.exam_prep_question_content_meta m ON m.question_id=pa.question_id
    WHERE m.content_version_id IN (4811,4812)
  ) OR EXISTS(
    SELECT 1 FROM public.tour_answers ta
    JOIN private.exam_prep_question_content_meta m ON m.question_id=ta.question_id
    WHERE m.content_version_id IN (4811,4812)
  ) THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: unexpected learner/legacy history';
  END IF;

  IF EXISTS(SELECT 1 FROM private.exam_prep_written_tasks WHERE content_version_id IN (4811,4812)) THEN
    RAISE EXCEPTION 'aw09_12 annual reserve draft: unnecessary written task duplicated';
  END IF;
END
$$;

\echo 'AW9-12 annual reserve draft v1 contract: GREEN'
