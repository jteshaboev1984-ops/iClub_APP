\set ON_ERROR_STOP on

-- P2-56 read-only/current-schema governance matrix.
-- Runs only against the isolated CI database. It does not mutate production or
-- legacy Practice/Tours data. The assertions mirror the approved content
-- governance boundary for the active Cambridge AS Mathematics P1+P5 program.

DO $$
DECLARE
  v_program bigint;
  v_p1 integer;
  v_p5 integer;
  v_bad integer;
  v_total integer;
  v_component_owned integer;
  v_executable integer;
  v_pool integer;
  v_unexposed integer;
  v_pct numeric;
  v_component text;
  v_max_week integer;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5'
    AND version_key='p1_p5_canonical_v1_0'
    AND status='active';

  IF v_program IS NULL THEN
    RAISE EXCEPTION 'P2-56 active canonical Mathematics program version missing';
  END IF;

  -- Canonical denominator is fixed at 45 P1 + 36 P5.
  SELECT
    count(*) FILTER (WHERE component_code='P1'),
    count(*) FILTER (WHERE component_code='P5')
  INTO v_p1,v_p5
  FROM private.exam_prep_syllabus_nodes
  WHERE program_version_id=v_program;

  IF v_p1<>45 OR v_p5<>36 THEN
    RAISE EXCEPTION 'P2-56 canonical denominator drift: P1 %, P5 %',v_p1,v_p5;
  END IF;

  -- Every canonical skill must have the controlled-beta reserve floor:
  -- >=1 governed diagnostic, >=3 governed learning items, >=2 governed retests.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_syllabus_nodes n
  WHERE n.program_version_id=v_program
    AND (
      (SELECT count(DISTINCT m.question_id)
       FROM private.exam_prep_question_content_meta m
       JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
       WHERE cv.program_version_id=v_program
         AND cv.component_code=n.component_code
         AND cv.status='published'
         AND m.primary_skill_code=n.skill_code
         AND m.reserve_role='diagnostic'
         AND m.lifecycle_state='reserve'
         AND m.exposure_state='withheld'
         AND m.qa_scope_status='pass'
         AND m.qa_math_status='pass'
         AND m.qa_language_status='pass'
         AND m.qa_technical_status='pass'
         AND m.copyright_status='pass'
         AND m.diagnostic_rule_status='approved'
         AND nullif(btrim(m.originality_attestation),'') IS NOT NULL) < 1
      OR
      (SELECT count(DISTINCT m.question_id)
       FROM private.exam_prep_question_content_meta m
       JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
       WHERE cv.program_version_id=v_program
         AND cv.component_code=n.component_code
         AND cv.status='published'
         AND m.primary_skill_code=n.skill_code
         AND m.reserve_role='learning'
         AND m.lifecycle_state='published'
         AND m.exposure_state='released'
         AND m.qa_scope_status='pass'
         AND m.qa_math_status='pass'
         AND m.qa_language_status='pass'
         AND m.qa_technical_status='pass'
         AND m.copyright_status='pass'
         AND nullif(btrim(m.originality_attestation),'') IS NOT NULL) < 3
      OR
      (SELECT count(DISTINCT m.question_id)
       FROM private.exam_prep_question_content_meta m
       JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
       WHERE cv.program_version_id=v_program
         AND cv.component_code=n.component_code
         AND cv.status='published'
         AND m.primary_skill_code=n.skill_code
         AND m.reserve_role='retest'
         AND m.lifecycle_state='reserve'
         AND m.exposure_state='withheld'
         AND m.qa_scope_status='pass'
         AND m.qa_math_status='pass'
         AND m.qa_language_status='pass'
         AND m.qa_technical_status='pass'
         AND m.copyright_status='pass'
         AND nullif(btrim(m.originality_attestation),'') IS NOT NULL) < 2
    );

  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-56 controlled-beta question reserve floor failed for % canonical skills',v_bad;
  END IF;

  -- The canonical map marks written evidence as required. Every skill must have
  -- at least one published, trilingual, QA-passed original written task/rubric.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_syllabus_nodes n
  WHERE n.program_version_id=v_program
    AND n.written_suitability='Обязательная'
    AND NOT EXISTS (
      SELECT 1
      FROM private.exam_prep_written_tasks wt
      JOIN private.exam_prep_content_versions cv ON cv.id=wt.content_version_id
      WHERE cv.program_version_id=v_program
        AND cv.component_code=n.component_code
        AND cv.status='published'
        AND wt.component_code=n.component_code
        AND wt.primary_skill_code=n.skill_code
        AND wt.lifecycle_state='published'
        AND wt.copyright_status='pass'
        AND wt.qa_math_status='pass'
        AND wt.qa_language_status='pass'
        AND wt.qa_technical_status='pass'
        AND nullif(btrim(wt.prompt_en),'') IS NOT NULL
        AND nullif(btrim(wt.prompt_ru),'') IS NOT NULL
        AND nullif(btrim(wt.prompt_uz),'') IS NOT NULL
        AND nullif(btrim(wt.self_review_en),'') IS NOT NULL
        AND nullif(btrim(wt.self_review_ru),'') IS NOT NULL
        AND nullif(btrim(wt.self_review_uz),'') IS NOT NULL
        AND wt.rubric_json IS NOT NULL
        AND jsonb_typeof(wt.rubric_json)='object'
        AND coalesce(jsonb_array_length(wt.rubric_json->'criteria'),0)>=1
    );

  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-56 governed written-task floor failed for % canonical skills',v_bad;
  END IF;

  -- Learning content may not overlap protected diagnostic/retest/mixed/timed/
  -- unseen question IDs inside the active program.
  SELECT count(*) INTO v_bad
  FROM (
    SELECT m.question_id
    FROM private.exam_prep_question_content_meta m
    JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
    WHERE cv.program_version_id=v_program
      AND m.question_id IS NOT NULL
    GROUP BY m.question_id
    HAVING bool_or(m.reserve_role='learning')
       AND bool_or(m.reserve_role IN ('diagnostic','retest','mixed','timed','unseen'))
  ) overlap_rows;

  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-56 learning/protected reserve overlap detected for % questions',v_bad;
  END IF;

  -- Protected question roles remain reserve+withheld; ordinary learning is
  -- published+released. Exposure through a governed session does not silently
  -- reclassify the content object as ordinary learning.
  SELECT count(*) INTO v_bad
  FROM private.exam_prep_question_content_meta m
  JOIN private.exam_prep_content_versions cv ON cv.id=m.content_version_id
  WHERE cv.program_version_id=v_program
    AND (
      (m.reserve_role IN ('diagnostic','retest','mixed','timed','unseen')
       AND (m.lifecycle_state<>'reserve' OR m.exposure_state<>'withheld'))
      OR
      (m.reserve_role='learning'
       AND (m.lifecycle_state<>'published' OR m.exposure_state<>'released'))
    );

  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-56 reserve lifecycle/exposure contract failed for % rows',v_bad;
  END IF;

  -- All canonical component-owned mixed nodes must have one executable
  -- assessment binding. Cross-component/non-owned registry nodes must not be
  -- executable as a P1/P5 assessment.
  SELECT count(*) INTO v_total
  FROM private.exam_prep_mixed_nodes
  WHERE program_version_id=v_program;
  IF v_total<>23 THEN
    RAISE EXCEPTION 'P2-56 canonical mixed registry drift: expected 23, found %',v_total;
  END IF;

  SELECT count(*) INTO v_component_owned
  FROM private.exam_prep_mixed_nodes
  WHERE program_version_id=v_program
    AND owner_component_code IN ('P1','P5');

  SELECT count(*) INTO v_executable
  FROM private.exam_prep_mixed_nodes mn
  WHERE mn.program_version_id=v_program
    AND mn.owner_component_code IN ('P1','P5')
    AND EXISTS (
      SELECT 1
      FROM private.exam_prep_assessment_mixed_nodes amn
      JOIN private.exam_prep_assessments a ON a.id=amn.assessment_id
      WHERE amn.program_version_id=mn.program_version_id
        AND amn.mixed_code=mn.mixed_code
        AND amn.component_code=mn.owner_component_code
        AND a.component_code=mn.owner_component_code
        AND a.assessment_type='mixed'
        AND a.status='published'
    );

  IF v_executable<>v_component_owned THEN
    RAISE EXCEPTION 'P2-56 component-owned mixed runtime incomplete: owned %, executable %',v_component_owned,v_executable;
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_mixed_nodes mn
  JOIN private.exam_prep_assessment_mixed_nodes amn
    ON amn.program_version_id=mn.program_version_id
   AND amn.mixed_code=mn.mixed_code
  WHERE mn.program_version_id=v_program
    AND mn.owner_component_code IS NULL;

  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P2-56 non-component mixed node became executable: % bindings',v_bad;
  END IF;

  -- At least 20% of QA-passed transfer/retest-capable reserve must remain
  -- globally unexposed. This is an exposure metric, separate from the content
  -- object's withheld lifecycle state.
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
      SELECT DISTINCT si.question_id
      FROM private.exam_prep_session_items si
      WHERE si.question_id IS NOT NULL
    )
    SELECT count(*),count(*) FILTER (WHERE seen.question_id IS NULL)
    INTO v_pool,v_unexposed
    FROM pool
    LEFT JOIN seen USING(question_id);

    IF v_pool<1 THEN
      RAISE EXCEPTION 'P2-56 % transfer/retest reserve pool is empty',v_component;
    END IF;

    v_pct:=100.0*v_unexposed/v_pool;
    IF v_pct<20.0 THEN
      RAISE EXCEPTION 'P2-56 % unexposed reserve below 20%% floor: %/% = %%%',v_component,v_unexposed,v_pool,round(v_pct,1);
    END IF;
  END LOOP;

  -- Active runway must start at week 1, cover at least the two-week hard floor,
  -- and contain no gap through its current published horizon for either component.
  FOREACH v_component IN ARRAY ARRAY['P1','P5'] LOOP
    SELECT max(active_week_through) INTO v_max_week
    FROM private.exam_prep_content_runway_releases
    WHERE program_version_id=v_program
      AND component_code=v_component
      AND schedule_status='active';

    IF v_max_week IS NULL OR v_max_week<2 THEN
      RAISE EXCEPTION 'P2-56 % active content runway does not satisfy the two-week hard floor',v_component;
    END IF;

    SELECT count(*) INTO v_bad
    FROM generate_series(1,v_max_week) w(week_no)
    WHERE NOT EXISTS (
      SELECT 1
      FROM private.exam_prep_content_runway_releases r
      WHERE r.program_version_id=v_program
        AND r.component_code=v_component
        AND r.schedule_status='active'
        AND w.week_no BETWEEN r.active_week_from AND r.active_week_through
    );

    IF v_bad<>0 THEN
      RAISE EXCEPTION 'P2-56 % active runway contains % uncovered week(s) through week %',v_component,v_bad,v_max_week;
    END IF;
  END LOOP;

  RAISE NOTICE 'P2-56 content reserve/runway matrix: GREEN (P1 45, P5 36, reserve floors + written + mixed + holdout + runway)';
END
$$;
