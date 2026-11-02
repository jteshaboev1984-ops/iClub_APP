-- CI-ONLY / temporary disposable PostgreSQL. Enable approved on-paper
-- Mathematics Core solely for the existing fake learner A in this local run.
-- Neither production configs nor real consent/cohort users are ever modified.
\set ON_ERROR_STOP on
DO $$
DECLARE v_user constant uuid:='11111111-1111-4111-8111-111111111191'::uuid;
BEGIN
  IF current_database()<>'postgres'
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM auth.users)<>2
    OR (SELECT count(*) FROM public.users)<>2
    OR NOT EXISTS(SELECT 1 FROM public.users WHERE id=v_user)
  THEN RAISE EXCEPTION 'REFUSED: written-on-paper fixture needs exact two fake users in isolated PG17'; END IF;
  -- SECURITY: verify the actual locale gate denies any paper activation
  -- when the disposable schema lacks the reviewed locale ledger.
  BEGIN
    INSERT INTO private.exam_prep_written_learning_config_v1(component_code,enabled)
    VALUES('P1',true);
    RAISE EXCEPTION 'UNSAFE: paper mode enabled without any reviewed locale';
  EXCEPTION WHEN check_violation THEN
    NULL; -- required fail-closed: exam_prep_written_locale_approvals_incomplete
  END;
  IF EXISTS(SELECT 1 FROM private.exam_prep_written_learning_config_v1
            WHERE component_code='P1' AND enabled=true) THEN
    RAISE EXCEPTION 'unsafe paper config survived rejected activation';
  END IF;

  -- The full production locale review ledger is NOT stored in migrations.
  -- Only in disposable CI, synthesize deliberately non-academic placeholder
  -- rubric locales to exercise actual owner/locale gate and UI navigation.
  -- This is NOT an independent mathematical or language QA approval.
  -- The real production published locales were checked read-only separately.
  INSERT INTO private.exam_prep_written_criteria_locale_v1(
    written_task_id,task_version,criterion_id,language,source_rule_md5,
    translated_rule,review_state,academic_review_ref,language_review_ref,reviewed_at
  )
  SELECT wt.id,wt.task_version,c.value->>'id',l.language,
    md5(c.value->>'rule'),
    CASE WHEN l.language='ru' THEN 'Тестовый критерий CI: ' ELSE 'CI sinov mezoni: ' END ||
      left(c.value->>'id',100),
    'approved','DISPOSABLE_SYNTHETIC_CI_NOT_ACADEMIC_QA',
    'DISPOSABLE_SYNTHETIC_CI_NOT_LANGUAGE_QA',now()
  FROM private.exam_prep_written_tasks wt
  CROSS JOIN LATERAL jsonb_array_elements(
    coalesce(wt.rubric_json->'criteria','[]'::jsonb)) c(value)
  CROSS JOIN (VALUES('ru'::text),('uz'::text)) l(language)
  WHERE wt.component_code IN ('P1','P5') AND wt.lifecycle_state='published'
    AND wt.qa_math_status='pass' AND wt.qa_language_status='pass'
    AND wt.qa_technical_status='pass'
  ON CONFLICT (written_task_id,task_version,criterion_id,language)
  DO NOTHING;
  IF EXISTS(
    SELECT 1 FROM private.exam_prep_written_criteria_locale_v1
    WHERE review_state='approved'
      AND academic_review_ref<>'DISPOSABLE_SYNTHETIC_CI_NOT_ACADEMIC_QA'
  ) THEN RAISE EXCEPTION 'Unexpected non-synthetic review rows in fresh fixture'; END IF;

  INSERT INTO private.exam_prep_written_learning_config_v1(component_code,enabled)
  VALUES ('P1',true),('P5',true)
  ON CONFLICT (component_code) DO UPDATE SET enabled=excluded.enabled;
  IF (SELECT count(*) FROM private.exam_prep_written_learning_config_v1
      WHERE component_code IN ('P1','P5') AND enabled=true)<>2 THEN
    RAISE EXCEPTION 'missing two existing Mathematics paper learning configuration rows';
  END IF;
  INSERT INTO private.exam_prep_written_learning_allowlist_v1(user_id,component_code)
  VALUES (v_user,'P1'),(v_user,'P5')
  ON CONFLICT (user_id,component_code) DO NOTHING;
  IF (SELECT count(*) FROM private.exam_prep_written_learning_allowlist_v1 WHERE user_id=v_user)<>2
    OR EXISTS(SELECT 1 FROM private.exam_prep_written_learning_allowlist_v1 WHERE user_id<>v_user) THEN
    RAISE EXCEPTION 'written-on-paper temporary allowlist escaped fake owner';
  END IF;
  IF EXISTS (SELECT 1 FROM private.exam_prep_beta_weekly_reviews)
    OR EXISTS (SELECT 1 FROM public.practice_attempts)
    OR EXISTS (SELECT 1 FROM public.tour_attempts)
    OR EXISTS (SELECT 1 FROM public.certificates) THEN
    RAISE EXCEPTION 'written-on-paper fixture cannot touch legacy/beta evidence';
  END IF;
END $$;
