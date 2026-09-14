\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p270.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-70 REFUSED: isolated test database required';
  END IF;
END
$$;

DO $$
DECLARE
  v_program bigint;
  v_p1 integer;
  v_p5 integer;
  v_bad integer;
  v_component text;
  v_max_week integer;
  v_pool integer;
  v_unexposed integer;
  v_pct numeric;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5'
    AND version_key='p1_p5_canonical_v1_0'
    AND status='active';
  IF v_program IS NULL THEN
    RAISE EXCEPTION 'P2-70 canonical Mathematics program missing';
  END IF;

  SELECT count(*) FILTER (WHERE component_code='P1'),
         count(*) FILTER (WHERE component_code='P5')
  INTO v_p1,v_p5
  FROM private.exam_prep_syllabus_nodes
  WHERE program_version_id=v_program;
  IF v_p1<>45 OR v_p5<>36 THEN
    RAISE EXCEPTION 'P2-70 canonical denominator drift P1=% P5=%',v_p1,v_p5;
  END IF;

  -- Every canonical skill must be executable through the complete Core content
  -- lifecycle: diagnostic, correction-ready learning, fresh retest reserve,
  -- written evidence and mixed transfer. Skill contracts must also exist.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_syllabus_nodes n
  WHERE n.program_version_id=v_program
    AND (
      NOT EXISTS (
        SELECT 1
        FROM private.exam_prep_assessments a
        JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
        JOIN private.exam_prep_question_content_meta m
          ON m.question_id=ai.question_id
         AND m.primary_skill_code=ai.primary_skill_code
        JOIN private.exam_prep_content_versions mv ON mv.id=m.content_version_id
        WHERE a.component_code=n.component_code
          AND a.assessment_type='diagnostic'
          AND a.status='published'
          AND ai.primary_skill_code=n.skill_code
          AND ai.reserve_role='diagnostic'
          AND ai.is_holdout
          AND mv.program_version_id=v_program
          AND mv.component_code=n.component_code
          AND mv.status='published'
          AND m.reserve_role='diagnostic'
          AND m.lifecycle_state='reserve'
          AND m.exposure_state='withheld'
          AND m.qa_scope_status='pass'
          AND m.qa_math_status='pass'
          AND m.qa_language_status='pass'
          AND m.qa_technical_status='pass'
          AND m.copyright_status='pass'
          AND m.diagnostic_rule_status='approved'
      )
      OR NOT EXISTS (
        SELECT 1
        FROM private.exam_prep_assessments a
        WHERE a.component_code=n.component_code
          AND a.assessment_type='learning'
          AND a.status='published'
          AND EXISTS (
            SELECT 1 FROM private.exam_prep_assessment_items ai
            WHERE ai.assessment_id=a.id AND ai.primary_skill_code=n.skill_code
          )
          AND NOT EXISTS (
            SELECT 1 FROM private.exam_prep_assessment_items ai
            WHERE ai.assessment_id=a.id AND ai.primary_skill_code<>n.skill_code
          )
          AND (SELECT count(*) FROM private.exam_prep_assessment_items ai
               WHERE ai.assessment_id=a.id AND ai.question_id IS NOT NULL)>=3
          AND (SELECT count(*) FROM private.exam_prep_assessment_items ai
               WHERE ai.assessment_id=a.id AND ai.written_task_id IS NOT NULL)>=1
      )
      OR (SELECT count(DISTINCT ai.question_id)
          FROM private.exam_prep_assessments a
          JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
          JOIN private.exam_prep_question_content_meta m
            ON m.question_id=ai.question_id
           AND m.primary_skill_code=ai.primary_skill_code
          JOIN private.exam_prep_content_versions mv ON mv.id=m.content_version_id
          WHERE a.component_code=n.component_code
            AND a.assessment_type='retest'
            AND a.status='published'
            AND ai.primary_skill_code=n.skill_code
            AND ai.reserve_role='retest'
            AND ai.is_holdout
            AND mv.program_version_id=v_program
            AND mv.component_code=n.component_code
            AND mv.status='published'
            AND m.reserve_role='retest'
            AND m.lifecycle_state='reserve'
            AND m.exposure_state='withheld'
            AND m.qa_scope_status='pass'
            AND m.qa_math_status='pass'
            AND m.qa_language_status='pass'
            AND m.qa_technical_status='pass'
            AND m.copyright_status='pass') < 2
      OR NOT EXISTS (
        SELECT 1
        FROM private.exam_prep_assessments a
        JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
        WHERE a.component_code=n.component_code
          AND a.assessment_type='mixed'
          AND a.status='published'
          AND ai.primary_skill_code=n.skill_code
          AND private.exam_prep_mixed_mastery_assessment_qualifies_v1(a.id,n.component_code)
      )
      OR NOT EXISTS (
        SELECT 1
        FROM private.exam_prep_written_tasks wt
        JOIN private.exam_prep_assessment_items ai ON ai.written_task_id=wt.id
        JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id
        JOIN private.exam_prep_content_versions wv ON wv.id=wt.content_version_id
        WHERE wt.component_code=n.component_code
          AND wt.primary_skill_code=n.skill_code
          AND wt.lifecycle_state='published'
          AND wt.qa_math_status='pass'
          AND wt.qa_language_status='pass'
          AND wt.qa_technical_status='pass'
          AND wt.copyright_status='pass'
          AND a.component_code=n.component_code
          AND a.status='published'
          AND wv.program_version_id=v_program
      )
      OR NOT EXISTS (
        SELECT 1 FROM private.exam_prep_skill_contracts c
        WHERE c.program_version_id=v_program
          AND c.component_code=n.component_code
          AND c.skill_code=n.skill_code
      )
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-70 canonical skill lifecycle dead ends=%',v_bad;
  END IF;

  -- Every published runtime item must point to exactly one valid object and to
  -- a canonical skill in the same component.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_assessment_items ai
  JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  WHERE cv.program_version_id=v_program
    AND a.status='published'
    AND (
      (ai.question_id IS NULL)=(ai.written_task_id IS NULL)
      OR NOT EXISTS (
        SELECT 1 FROM private.exam_prep_syllabus_nodes n
        WHERE n.program_version_id=v_program
          AND n.component_code=a.component_code
          AND n.skill_code=ai.primary_skill_code
      )
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-70 invalid/orphan published assessment items=%',v_bad;
  END IF;

  -- Question-backed runtime items must have governed metadata in the same
  -- program/component and their item role must agree with content governance.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_assessment_items ai
  JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  WHERE cv.program_version_id=v_program
    AND a.status='published'
    AND ai.question_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1
      FROM private.exam_prep_question_content_meta m
      JOIN private.exam_prep_content_versions mv ON mv.id=m.content_version_id
      WHERE mv.program_version_id=v_program
        AND mv.component_code=a.component_code
        AND m.question_id=ai.question_id
        AND m.primary_skill_code=ai.primary_skill_code
        AND m.reserve_role=ai.reserve_role
        AND m.qa_scope_status='pass'
        AND m.qa_math_status='pass'
        AND m.qa_language_status='pass'
        AND m.qa_technical_status='pass'
        AND m.copyright_status='pass'
        AND nullif(btrim(m.originality_attestation),'') IS NOT NULL
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-70 runtime question items without governed metadata=%',v_bad;
  END IF;

  -- Learner-facing bound question content must be complete in EN/RU/UZ.
  SELECT count(*) INTO v_bad
  FROM (
    SELECT DISTINCT q.id,q.qtype,q.question_text_en,q.question_text_ru,q.question_text_uz,
           q.options_text_en,q.options_text_ru,q.options_text_uz,
           q.explanation_en,q.explanation_ru,q.explanation_uz
    FROM private.exam_prep_assessment_items ai
    JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id AND a.status='published'
    JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
    JOIN public.questions q ON q.id=ai.question_id
    WHERE cv.program_version_id=v_program
  ) q
  WHERE nullif(btrim(q.question_text_en),'') IS NULL
     OR nullif(btrim(q.question_text_ru),'') IS NULL
     OR nullif(btrim(q.question_text_uz),'') IS NULL
     OR nullif(btrim(q.explanation_en),'') IS NULL
     OR nullif(btrim(q.explanation_ru),'') IS NULL
     OR nullif(btrim(q.explanation_uz),'') IS NULL
     OR (q.qtype='mcq' AND (
          nullif(btrim(q.options_text_en),'') IS NULL
       OR nullif(btrim(q.options_text_ru),'') IS NULL
       OR nullif(btrim(q.options_text_uz),'') IS NULL));
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-70 bound question locale gaps=%',v_bad;
  END IF;

  -- Written tasks used at runtime must stay governed, skill-aligned and
  -- trilingual, including self-review and rubric.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_assessment_items ai
  JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  LEFT JOIN private.exam_prep_written_tasks wt ON wt.id=ai.written_task_id
  WHERE cv.program_version_id=v_program
    AND a.status='published'
    AND ai.written_task_id IS NOT NULL
    AND (
      wt.id IS NULL
      OR wt.component_code<>a.component_code
      OR wt.primary_skill_code<>ai.primary_skill_code
      OR wt.lifecycle_state<>'published'
      OR wt.qa_math_status<>'pass'
      OR wt.qa_language_status<>'pass'
      OR wt.qa_technical_status<>'pass'
      OR wt.copyright_status<>'pass'
      OR nullif(btrim(wt.prompt_en),'') IS NULL
      OR nullif(btrim(wt.prompt_ru),'') IS NULL
      OR nullif(btrim(wt.prompt_uz),'') IS NULL
      OR nullif(btrim(wt.self_review_en),'') IS NULL
      OR nullif(btrim(wt.self_review_ru),'') IS NULL
      OR nullif(btrim(wt.self_review_uz),'') IS NULL
      OR wt.rubric_json IS NULL
      OR jsonb_typeof(wt.rubric_json)<>'object'
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-70 governed written runtime gaps=%',v_bad;
  END IF;

  -- Published assessment labels are learner-facing and therefore trilingual.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  WHERE cv.program_version_id=v_program
    AND a.status='published'
    AND (nullif(btrim(a.title_en),'') IS NULL
      OR nullif(btrim(a.title_ru),'') IS NULL
      OR nullif(btrim(a.title_uz),'') IS NULL);
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-70 published assessment title locale gaps=%',v_bad;
  END IF;

  -- Protected assessments must always snapshot from holdout source items;
  -- ordinary learning items must remain non-holdout.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_assessment_items ai
  JOIN private.exam_prep_assessments a ON a.id=ai.assessment_id
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  WHERE cv.program_version_id=v_program
    AND a.status='published'
    AND (
      (a.assessment_type IN ('diagnostic','retest','mixed','timed','paper') AND NOT ai.is_holdout)
      OR (a.assessment_type='learning' AND ai.is_holdout)
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-70 protected reserve/holdout mismatch rows=%',v_bad;
  END IF;

  -- Timed/full-paper runtime is complete per component: two timed blocks plus
  -- mini-mock and three full papers, each with a published timing contract and
  -- at least one canonical item.
  FOREACH v_component IN ARRAY ARRAY['P1','P5'] LOOP
    SELECT count(*) INTO v_bad
    FROM private.exam_prep_assessments a
    JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
    WHERE cv.program_version_id=v_program
      AND a.component_code=v_component
      AND a.status='published'
      AND a.assessment_type='timed';
    IF v_bad<2 THEN
      RAISE EXCEPTION 'P2-70 % timed runtime count below floor=%',v_component,v_bad;
    END IF;

    SELECT count(*) INTO v_bad
    FROM private.exam_prep_assessments a
    JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
    WHERE cv.program_version_id=v_program
      AND a.component_code=v_component
      AND a.status='published'
      AND a.assessment_type='paper';
    IF v_bad<4 THEN
      RAISE EXCEPTION 'P2-70 % paper runtime count below mini-mock+3 full-paper floor=%',v_component,v_bad;
    END IF;

    SELECT count(*) INTO v_bad
    FROM private.exam_prep_assessments a
    JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
    WHERE cv.program_version_id=v_program
      AND a.component_code=v_component
      AND a.status='published'
      AND a.assessment_type IN ('timed','paper')
      AND (
        NOT EXISTS (SELECT 1 FROM private.exam_prep_timed_assessment_contracts tc WHERE tc.assessment_id=a.id AND tc.status='published')
        OR NOT EXISTS (SELECT 1 FROM private.exam_prep_assessment_items ai WHERE ai.assessment_id=a.id)
      );
    IF v_bad<>0 THEN
      RAISE EXCEPTION 'P2-70 % timed/paper contract or item gaps=%',v_component,v_bad;
    END IF;
  END LOOP;

  -- The three full-paper readiness anchors used by the Stage engine must remain
  -- published and timed-contract governed for both components.
  SELECT count(*) INTO v_bad
  FROM (VALUES
    ('p1_stage3_full_paper_01'),('p1_stage4_full_paper_02'),('p1_stage4_full_paper_03'),
    ('p5_stage3_full_paper_01'),('p5_stage4_full_paper_02'),('p5_stage4_full_paper_03')
  ) req(assessment_key)
  WHERE NOT EXISTS (
    SELECT 1
    FROM private.exam_prep_assessments a
    JOIN private.exam_prep_timed_assessment_contracts tc ON tc.assessment_id=a.id AND tc.status='published'
    JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
    WHERE cv.program_version_id=v_program
      AND a.assessment_key=req.assessment_key
      AND a.assessment_type='paper'
      AND a.status='published'
  );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-70 required full-paper readiness anchors missing=%',v_bad;
  END IF;

  -- Protected reserve remains genuinely unexposed: at least 20% of the
  -- retest/mixed/unseen pool per component has never entered a session.
  FOREACH v_component IN ARRAY ARRAY['P1','P5'] LOOP
    WITH pool AS (
      SELECT DISTINCT m.question_id
      FROM private.exam_prep_question_content_meta m
      JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
      WHERE cv.program_version_id=v_program
        AND cv.component_code=v_component
        AND cv.status='published'
        AND m.reserve_role IN ('retest','mixed','unseen')
        AND m.lifecycle_state='reserve'
        AND m.exposure_state='withheld'
        AND m.qa_scope_status='pass'
        AND m.qa_math_status='pass'
        AND m.qa_language_status='pass'
        AND m.qa_technical_status='pass'
        AND m.copyright_status='pass'
    ), seen AS (
      SELECT DISTINCT question_id FROM private.exam_prep_session_items WHERE question_id IS NOT NULL
    )
    SELECT count(*),count(*) FILTER (WHERE seen.question_id IS NULL)
    INTO v_pool,v_unexposed
    FROM pool LEFT JOIN seen USING(question_id);

    IF v_pool<1 THEN
      RAISE EXCEPTION 'P2-70 % protected reserve pool empty',v_component;
    END IF;
    v_pct:=100.0*v_unexposed/v_pool;
    IF v_pct<20.0 THEN
      RAISE EXCEPTION 'P2-70 % unexposed protected reserve below 20%%: %/%',v_component,v_unexposed,v_pool;
    END IF;
  END LOOP;

  -- Runway hard floor: starts at week 1, covers at least two weeks and has no
  -- gap through the currently published horizon.
  FOREACH v_component IN ARRAY ARRAY['P1','P5'] LOOP
    SELECT max(active_week_through) INTO v_max_week
    FROM private.exam_prep_content_runway_releases
    WHERE program_version_id=v_program
      AND component_code=v_component
      AND schedule_status='active';
    IF v_max_week IS NULL OR v_max_week<2 THEN
      RAISE EXCEPTION 'P2-70 % runway below two-week hard floor',v_component;
    END IF;

    SELECT count(*) INTO v_bad
    FROM generate_series(1,v_max_week) w(week_no)
    WHERE NOT EXISTS (
      SELECT 1 FROM private.exam_prep_content_runway_releases r
      WHERE r.program_version_id=v_program
        AND r.component_code=v_component
        AND r.schedule_status='active'
        AND w.week_no BETWEEN r.active_week_from AND r.active_week_through
    );
    IF v_bad<>0 THEN
      RAISE EXCEPTION 'P2-70 % runway uncovered weeks=% through week=%',v_component,v_bad,v_max_week;
    END IF;
  END LOOP;

  RAISE NOTICE 'P2-70 content lifecycle/runway matrix: GREEN (81 canonical skills, runtime links, locales, protected holdout, timed/papers, reserve and runway)';
END
$$;
