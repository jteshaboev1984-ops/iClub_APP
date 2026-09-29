-- AW1-4 annual reserve top-up draft contract.
-- Read-only acceptance checks after the full migration stack.

\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
BEGIN
  -- Exactly two invisible draft versions.
  IF (SELECT count(*) FROM private.exam_prep_content_versions
      WHERE id IN (4803,4804)
        AND status='draft')<>2 THEN
    RAISE EXCEPTION 'annual reserve draft: expected two draft content versions';
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_question_content_meta
      WHERE content_version_id IN (4803,4804))<>45
     OR (SELECT count(*) FROM private.exam_prep_question_content_meta
         WHERE content_version_id IN (4803,4804) AND reserve_role='diagnostic')<>18
     OR (SELECT count(*) FROM private.exam_prep_question_content_meta
         WHERE content_version_id IN (4803,4804) AND reserve_role='retest')<>18
     OR (SELECT count(*) FROM private.exam_prep_question_content_meta
         WHERE content_version_id IN (4803,4804) AND reserve_role='mixed')<>9
  THEN
    RAISE EXCEPTION 'annual reserve draft: question-role cardinality mismatch';
  END IF;

  -- Per-skill delta is exactly +2 diagnostic, +2 retest, +1 mixed/transfer.
  WITH expected(component_code,skill_code) AS (VALUES
    ('P1','P1-QUA-01'),('P1','P1-QUA-02'),('P1','P1-QUA-03'),('P1','P1-FUN-01'),('P1','P1-FUN-02'),
    ('P5','P5-DAT-01'),('P5','P5-DAT-02'),('P5','P5-DAT-04'),('P5','P5-DAT-06')
  ), got AS (
    SELECT cv.component_code,m.primary_skill_code AS skill_code,
      count(*) FILTER (WHERE m.reserve_role='diagnostic') AS d,
      count(*) FILTER (WHERE m.reserve_role='retest') AS r,
      count(*) FILTER (WHERE m.reserve_role='mixed') AS x
    FROM private.exam_prep_question_content_meta m
    JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
    WHERE m.content_version_id IN (4803,4804)
    GROUP BY cv.component_code,m.primary_skill_code
  )
  SELECT count(*) INTO v_bad
  FROM expected e
  LEFT JOIN got g USING(component_code,skill_code)
  WHERE coalesce(g.d,0)<>2 OR coalesce(g.r,0)<>2 OR coalesce(g.x,0)<>1;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve draft: per-skill delta mismatch rows=%',v_bad;
  END IF;

  -- Candidate delta closes the numeric annual floor for these nine skills:
  -- 3 diagnostics, 8 learning/transfer (6 learning + 2 mixed), 4 retests;
  -- written reserve already has >=2 published tasks.
  WITH expected(component_code,skill_code) AS (VALUES
    ('P1','P1-QUA-01'),('P1','P1-QUA-02'),('P1','P1-QUA-03'),('P1','P1-FUN-01'),('P1','P1-FUN-02'),
    ('P5','P5-DAT-01'),('P5','P5-DAT-02'),('P5','P5-DAT-04'),('P5','P5-DAT-06')
  ), q AS (
    SELECT cv.component_code,m.primary_skill_code AS skill_code,
      count(*) FILTER(WHERE m.reserve_role='diagnostic') AS d,
      count(*) FILTER(WHERE m.reserve_role='learning') AS l,
      count(*) FILTER(WHERE m.reserve_role='retest') AS r,
      count(*) FILTER(WHERE m.reserve_role='mixed') AS x
    FROM private.exam_prep_question_content_meta m
    JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
    JOIN expected e ON e.component_code=cv.component_code AND e.skill_code=m.primary_skill_code
    WHERE (
      cv.status='published' AND m.lifecycle_state IN ('published','reserve')
    ) OR (
      cv.id IN (4803,4804) AND cv.status='draft' AND m.lifecycle_state='draft'
    )
    GROUP BY cv.component_code,m.primary_skill_code
  ), w AS (
    SELECT component_code,primary_skill_code AS skill_code,count(*) AS n
    FROM private.exam_prep_written_tasks
    WHERE lifecycle_state='published'
      AND primary_skill_code IN (
        'P1-QUA-01','P1-QUA-02','P1-QUA-03','P1-FUN-01','P1-FUN-02',
        'P5-DAT-01','P5-DAT-02','P5-DAT-04','P5-DAT-06'
      )
    GROUP BY component_code,primary_skill_code
  )
  SELECT count(*) INTO v_bad
  FROM expected e
  LEFT JOIN q USING(component_code,skill_code)
  LEFT JOIN w USING(component_code,skill_code)
  WHERE coalesce(q.d,0)<>3
     OR coalesce(q.l,0)+coalesce(q.x,0)<>8
     OR coalesce(q.r,0)<>4
     OR coalesce(w.n,0)<2;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve draft: prospective annual numeric floor not closed rows=%',v_bad;
  END IF;

  -- Draft content remains fully withheld and unapproved.
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
      OR (m.reserve_role='diagnostic' AND m.diagnostic_rule_status<>'pending')
      OR (m.reserve_role<>'diagnostic' AND m.diagnostic_rule_status<>'not_applicable')
      OR q.is_active
      OR q.quality_status<>'draft'
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve draft: exposure/QA boundary failure rows=%',v_bad;
  END IF;

  -- All three learner languages and explanations are present; MCQs have four
  -- options in every locale and a valid stored answer.
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
          jsonb_typeof(q.options_text_en::jsonb)<>'array'
          OR jsonb_array_length(q.options_text_en::jsonb)<>4
          OR jsonb_array_length(q.options_text_ru::jsonb)<>4
          OR jsonb_array_length(q.options_text_uz::jsonb)<>4
          OR q.correct_answer NOT IN ('A','B','C','D')
        )
      )
      OR (
        lower(q.qtype)='input' AND (
          q.options_text_en::jsonb<>'[]'::jsonb
          OR q.options_text_ru::jsonb<>'[]'::jsonb
          OR q.options_text_uz::jsonb<>'[]'::jsonb
          OR nullif(btrim(q.correct_answer),'') IS NULL
        )
      )
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve draft: trilingual/type contract failure rows=%',v_bad;
  END IF;

  -- Independent language QA: learner-facing RU/UZ options must not retain the
  -- English connector/unit tokens found during the second review.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4803,4804)
    AND (
      q.options_text_ru ~* '\\m(or|only|cm)\\M'
      OR q.options_text_uz ~* '\\m(or|only|cm)\\M'
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve draft: untranslated option token rows=%',v_bad;
  END IF;

  -- Independent reserve-role QA: delayed-retest questions that were too close
  -- to teaching practice were rewritten as materially different evidence.
  WITH expected(content_key,question_text_en,correct_answer) AS (VALUES
    ('P1QUA01-R03','For q(x)=5x²−20x+23, the equation q(x)=c has exactly one real solution. Enter c.','3'),
    ('P1QUA01-R04','Which statement about y=−x²+10x−18 is correct?','D'),
    ('P1QUA02-R03','For which values of q is 2x²+qx+5 positive for every real x?','A'),
    ('P1QUA02-R04','The line y=4mx−4 is tangent to the parabola y=x². For which values of m does this happen?','C'),
    ('P1FUN01-R03','Let f(x)=x² with domain x≤0. Which formula gives f⁻¹(x)?','D'),
    ('P1FUN01-R04','Let f(x)=1/(x−3) and g(x)=2x+1. Enter the value of x that must be excluded from the domain of (f∘g)(x).','1'),
    ('P1FUN02-R03','For f(x)=(x−2)²+1 with −1<x≤4, what is the range?','D'),
    ('P1FUN02-R04','For f(x)=2x+3 with −5≤x<4, enter the minimum value of f.','-7'),
    ('P5DAT02-R03','A stem-and-leaf diagram has key 2 | 4 = 24 and rows 2 | 4 7 9 and 3 | 1 1 8. One additional observation 30 is inserted. Enter the new median.','30'),
    ('P5DAT04-R03','Two histogram classes have widths 4 and 6 and frequencies 12 and 18 respectively. Enter the ratio (first bar height)/(second bar height).','1'),
    ('P5DAT04-R04','In a histogram, class A has width 4 and frequency density 6; class B has width 8 and frequency density 3. Which statement is correct?','A'),
    ('P5DAT06-R03','The values 2, 6 and 10 occur with frequencies 1, k and 2 respectively. The mean is 7. Enter k.','1'),
    ('P5DAT06-R04','The data are 3, 3, 5, 7, 12. If 12 is replaced by 22, which statement is correct?','D')
  )
  SELECT count(*) INTO v_bad
  FROM expected e
  LEFT JOIN private.exam_prep_question_content_meta m
    ON m.content_version_id IN (4803,4804)
   AND m.content_key=e.content_key
  LEFT JOIN public.questions q ON q.id=m.question_id
  WHERE m.id IS NULL
     OR q.question_text_en IS DISTINCT FROM e.question_text_en
     OR q.correct_answer IS DISTINCT FROM e.correct_answer;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve draft: independent retest QA contract drift rows=%',v_bad;
  END IF;

  -- Exact source snapshot must still match the immutable private metadata.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4803,4804)
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
    RAISE EXCEPTION 'annual reserve draft: source snapshot mismatch rows=%',v_bad;
  END IF;

  -- No exact English-stem reuse from any older question and no duplicates inside
  -- the top-up itself.
  WITH draft_q AS (
    SELECT q.id,lower(regexp_replace(btrim(q.question_text_en),'\s+','','g')) AS stem
    FROM private.exam_prep_question_content_meta m
    JOIN public.questions q ON q.id=m.question_id
    WHERE m.content_version_id IN (4803,4804)
  )
  SELECT count(*) INTO v_bad
  FROM draft_q d
  JOIN public.questions oldq
    ON oldq.id<>d.id
   AND lower(regexp_replace(btrim(oldq.question_text_en),'\s+','','g'))=d.stem
  LEFT JOIN private.exam_prep_question_content_meta dm ON dm.question_id=oldq.id
    AND dm.content_version_id IN (4803,4804)
  WHERE dm.id IS NULL;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve draft: exact old-stem overlap rows=%',v_bad;
  END IF;

  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_question_content_meta m
    JOIN public.questions q ON q.id=m.question_id
    WHERE m.content_version_id IN (4803,4804)
    GROUP BY lower(regexp_replace(btrim(q.question_text_en),'\s+','','g'))
    HAVING count(*)>1
  ) THEN
    RAISE EXCEPTION 'annual reserve draft: duplicate stem inside candidate';
  END IF;

  -- Diagnostic rules: three distinct wrong-option diagnoses per diagnostic.
  IF (SELECT count(*)
      FROM private.exam_prep_diagnostic_rules r
      JOIN private.exam_prep_question_content_meta m ON m.id=r.content_meta_id
      WHERE m.content_version_id IN (4803,4804)
        AND r.rule_version='aw_reserve_v1')<>54 THEN
    RAISE EXCEPTION 'annual reserve draft: expected 54 diagnostic rules';
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4803,4804)
    AND m.reserve_role='diagnostic'
    AND (
      SELECT count(*)
      FROM private.exam_prep_diagnostic_rules r
      WHERE r.content_meta_id=m.id
        AND r.rule_version='aw_reserve_v1'
        AND r.status='draft'
        AND r.answer_kind='mcq_option'
        AND r.answer_match<>q.correct_answer
        AND nullif(btrim(r.feedback_en),'') IS NOT NULL
        AND nullif(btrim(r.feedback_ru),'') IS NOT NULL
        AND nullif(btrim(r.feedback_uz),'') IS NOT NULL
        AND nullif(btrim(r.next_action_en),'') IS NOT NULL
        AND nullif(btrim(r.next_action_ru),'') IS NOT NULL
        AND nullif(btrim(r.next_action_uz),'') IS NOT NULL
    )<>3;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve draft: diagnostic rule coverage failure rows=%',v_bad;
  END IF;

  -- Draft assessments are exact: 4 diagnostic variants, 18 isolated retests
  -- and 2 mixed transfer sets; every item is held out.
  IF (SELECT count(*) FROM private.exam_prep_assessments
      WHERE id BETWEEN 35301 AND 35324 AND status='draft')<>24
     OR (SELECT count(*) FROM private.exam_prep_assessments
         WHERE id BETWEEN 35301 AND 35324 AND assessment_type='diagnostic')<>4
     OR (SELECT count(*) FROM private.exam_prep_assessments
         WHERE id BETWEEN 35301 AND 35324 AND assessment_type='retest')<>18
     OR (SELECT count(*) FROM private.exam_prep_assessments
         WHERE id BETWEEN 35301 AND 35324 AND assessment_type='mixed')<>2
     OR (SELECT count(*) FROM private.exam_prep_assessment_items
         WHERE assessment_id BETWEEN 35301 AND 35324)<>45
  THEN
    RAISE EXCEPTION 'annual reserve draft: assessment cardinality mismatch';
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_assessment_items ai
  JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id
  JOIN private.exam_prep_question_content_meta m ON m.question_id=ai.question_id
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  WHERE ai.assessment_id BETWEEN 35301 AND 35324
    AND (
      NOT ai.is_holdout
      OR ai.written_task_id IS NOT NULL
      OR ai.primary_skill_code<>m.primary_skill_code
      OR ai.reserve_role<>m.reserve_role
      OR ai.reserve_role<>a.assessment_type
      OR m.content_version_id<>a.content_version_id
      OR cv.component_code<>a.component_code
      OR ai.primary_skill_code NOT LIKE a.component_code||'-%'
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'annual reserve draft: assessment isolation/role failure rows=%',v_bad;
  END IF;

  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_assessments a
    JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
    WHERE a.id BETWEEN 35301 AND 35324
    GROUP BY a.id,a.assessment_type
    HAVING (a.assessment_type='retest' AND count(*)<>1)
        OR (a.assessment_type='diagnostic' AND count(*) NOT IN (4,5))
        OR (a.assessment_type='mixed' AND count(*) NOT IN (4,5))
  ) THEN
    RAISE EXCEPTION 'annual reserve draft: assessment shape failure';
  END IF;

  -- Defense-in-depth answer balance.
  SELECT
    count(*) FILTER(WHERE q.correct_answer='A'),
    count(*) FILTER(WHERE q.correct_answer='B'),
    count(*) FILTER(WHERE q.correct_answer='C'),
    count(*) FILTER(WHERE q.correct_answer='D'),
    count(*) FILTER(WHERE lower(q.qtype)='input')
  INTO v_a,v_b,v_c,v_d,v_inputs
  FROM private.exam_prep_question_content_meta m
  JOIN public.questions q ON q.id=m.question_id
  WHERE m.content_version_id IN (4803,4804);

  IF (v_a,v_b,v_c,v_d,v_inputs)<>(9,10,9,10,7) THEN
    RAISE EXCEPTION 'annual reserve draft: answer balance mismatch A=% B=% C=% D=% input=%',
      v_a,v_b,v_c,v_d,v_inputs;
  END IF;

  -- No learner or legacy history can reference this draft.
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
    RAISE EXCEPTION 'annual reserve draft: unexpected learner/legacy history';
  END IF;

  -- This top-up deliberately creates no written tasks: existing published written
  -- reserve already meets the annual >=2 target for all nine skills.
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_written_tasks
    WHERE content_version_id IN (4803,4804)
  ) THEN
    RAISE EXCEPTION 'annual reserve draft: unnecessary written task duplicated';
  END IF;

  RAISE NOTICE 'AW1-4 annual reserve top-up draft contract: GREEN (45 machine items; prospective 3D/8 learning-transfer/4R; written already >=2)';
END
$$;
