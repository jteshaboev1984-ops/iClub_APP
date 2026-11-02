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
  UPDATE private.exam_prep_written_learning_config_v1 SET enabled=true
  WHERE component_code IN ('P1','P5');
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
