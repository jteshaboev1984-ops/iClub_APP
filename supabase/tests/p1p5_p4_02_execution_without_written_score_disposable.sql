-- P4-02 REAL source-bound isolated E2E SQL. Never execute in production.
-- Run AFTER genuine signed JWT->PostgREST P1/P5 written full-paper finalization
-- and BEFORE governed synthetic owner cleanup in disposable PostgreSQL 17.
-- READS ONLY inside disposable test DB; protected question keys not selected.
\set ON_ERROR_STOP on
DO $proof$
DECLARE
  v_owner uuid;
  v_count int;
  v_good int;
  v_distinct_components int;
  v_false_old int;
  v_mixed_bad int;
BEGIN
  RAISE NOTICE 'P4-02 isolated source guard: db %, test_flag %, public_accounts %, auth_accounts %',
    current_database(),current_setting('iclub.e2e_isolated',true),
    (SELECT count(*) FROM public.users),(SELECT count(*) FROM auth.users);
  IF current_database()<>'postgres'
     OR current_setting('iclub.e2e_isolated',true)<>'true'
     OR (SELECT count(*) FROM public.users)<>2
     OR (SELECT count(*) FROM auth.users)<>2
  THEN
     RAISE EXCEPTION 'P4-02 REFUSED: disposable two-learner PostgreSQL only';
  END IF;

  SELECT user_id INTO v_owner
  FROM private.exam_prep_synthetic_identities
  WHERE run_id='SV-P1P5-MIXED-TIMED-HTTP-01'
    AND identity_status='active';
  IF v_owner IS NULL THEN RAISE EXCEPTION 'P4-02 authentic signed HTTP owner missing'; END IF;

  IF has_function_privilege('anon',
        'private.exam_prep_timed_execution_comparable_v1(uuid)','EXECUTE')
     OR has_function_privilege('authenticated',
        'private.exam_prep_timed_execution_comparable_v1(uuid)','EXECUTE')
     OR NOT has_function_privilege('service_role',
        'private.exam_prep_timed_execution_comparable_v1(uuid)','EXECUTE')
  THEN RAISE EXCEPTION 'P4-02 service-only execution comparator ACL failed'; END IF;

  SELECT count(*),
    count(*) FILTER (WHERE
      private.exam_prep_timed_execution_comparable_v1(t.session_id)),
    count(DISTINCT t.component_code),
    count(*) FILTER (WHERE NOT
      private.exam_prep_timed_score_comparable_v1(t.session_id))
  INTO v_count,v_good,v_distinct_components,v_false_old
  FROM private.exam_prep_timed_attempt_results t
  JOIN private.exam_prep_sessions s ON s.id=t.session_id
  WHERE t.user_id=v_owner
    AND s.user_id=v_owner
    AND s.session_type='paper'
    AND s.status='finalized'
    AND t.attempt_kind='full_paper'
    AND t.component_code IN ('P1','P5')
    AND (t.pending_review_in_time_marks+
         t.pending_review_after_time_marks)>0
    AND t.objective_marks_in_time=0;

  IF v_count<>2 OR v_good<>2 OR v_false_old<>2 OR v_distinct_components<>2
  THEN RAISE EXCEPTION
    'P4-02 strict execution and scored comparability expected 2 P1/P5 papers; got count %, execution %, unscored %, components %',
     v_count,v_good,v_false_old,v_distinct_components;
  END IF;

  SELECT count(*) INTO v_mixed_bad
  FROM private.exam_prep_sessions s
  WHERE s.user_id=v_owner
    AND s.session_type='mixed'
    AND private.exam_prep_timed_execution_comparable_v1(s.id);
  IF v_mixed_bad<>0 THEN
    RAISE EXCEPTION 'P4-02 non-timed mixed session falsely execution-comparable';
  END IF;

  IF private.exam_prep_timed_execution_comparable_v1(NULL) THEN
    RAISE EXCEPTION 'P4-02 null session falsely comparable';
  END IF;

  RAISE NOTICE 'P4-02 PASS: signed P1/P5 full written papers execution-comparable, scored NOT comparable, ACL private, mixed/NULL excluded';
  RAISE NOTICE 'P4-02 NOTE: Stage3/4/5 still use old scored comparator; this proves helper only, NOT repaired progression';
END
$proof$;
