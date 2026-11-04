-- P3/D09 exact seven-day and independent paper boundary proof.
-- SELECT-only assertions on disposable PG17 after all migrations.
\\set ON_ERROR_STOP on
DO $d09$
DECLARE
 t0 timestamptz:='2026-10-01 09:00:00+05'::timestamptz;
 p1 integer;
 p5 integer;
 v_report_source text;
BEGIN
 IF current_database()<>'postgres'
    OR current_setting('server_version_num')::int<170000
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM auth.users)<>2
    OR (SELECT count(*) FROM public.users)<>2
    OR to_regprocedure('private.exam_prep_full_periods_from_t0_v1(timestamptz,timestamptz)') IS NULL
    OR to_regprocedure('public.get_exam_prep_diagnostic_periods_safe_v1()') IS NULL
 THEN RAISE EXCEPTION 'D09 refused non-isolated/projection-missing test stack'; END IF;

 IF private.exam_prep_full_periods_from_t0_v1(t0,t0-interval '1 second') IS NOT NULL
    OR private.exam_prep_full_periods_from_t0_v1(t0,t0)<>0
    OR private.exam_prep_full_periods_from_t0_v1(t0,t0+interval '6 days 23 hours 59 minutes 59 seconds')<>0
    OR private.exam_prep_full_periods_from_t0_v1(t0,t0+interval '7 days')<>1
    OR private.exam_prep_full_periods_from_t0_v1(t0,t0+interval '14 days')<>2
    OR private.exam_prep_full_periods_from_t0_v1(t0,t0+interval '252 days')<>36
    OR private.exam_prep_full_periods_from_t0_v1(t0,t0+interval '259 days')<>37
    OR private.exam_prep_full_periods_from_t0_v1(null,t0) IS NOT NULL
 THEN RAISE EXCEPTION 'D09 genuine exact seven-day boundary or independent >36w calculation failed'; END IF;

 -- Same server day, distinct P1/P5 diagnostic completion timestamps.
 p1:=private.exam_prep_full_periods_from_t0_v1(t0,t0+interval '8 days');
 p5:=private.exam_prep_full_periods_from_t0_v1(t0+interval '3 days',t0+interval '8 days');
 IF p1<>1 OR p5<>0
 THEN RAISE EXCEPTION 'D09 paper-specific diagnostic calendars were conflated'; END IF;

 IF has_function_privilege('anon',
      'public.get_exam_prep_diagnostic_periods_safe_v1()'::regprocedure,'EXECUTE')
    OR NOT has_function_privilege('authenticated',
      'public.get_exam_prep_diagnostic_periods_safe_v1()'::regprocedure,'EXECUTE')
    OR NOT EXISTS(
      SELECT 1 FROM pg_proc p
      WHERE p.oid='public.get_exam_prep_diagnostic_periods_safe_v1()'::regprocedure
        AND p.prosecdef AND p.provolatile='s')
 THEN RAISE EXCEPTION 'D09 public RPC authentication/stability/security drift'; END IF;

 v_report_source:=pg_get_functiondef('public.claim_exam_prep_periodic_study_report_safe_v1()'::regprocedure);
 IF position('v_now-v_diagnostic_anchor' in v_report_source)=0
    OR position('v_end:=v_diagnostic_anchor+' in v_report_source)=0
    OR position('v_end:=v_profile.created_at+' in v_report_source)>0
 THEN RAISE EXCEPTION 'D09 report still uses profile signup time, not diagnostic T0'; END IF;
 RAISE NOTICE 'D09 PASS: exact 7-day boundaries, independent P1/P5, 37+ weeks, strict ACL, diagnostic-rooted report function';
END;
$d09$;
