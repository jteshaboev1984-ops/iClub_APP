-- Issue #450 P4-05 source-bound final inventory after signed BLANK Paper.
-- The fourth fully unattempted Paper must not enter operational execution counts.
\set ON_ERROR_STOP on
DO $proof$
DECLARE
  v_uid uuid;v_program bigint;v_comp text;v_total int;v_exec int;
  v_blank int;v_saved int;v_stage int;v_est text;v_operational jsonb;v_scored jsonb;
BEGIN
 IF current_database()<>'postgres'
 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM auth.users)<>3 OR (SELECT count(*) FROM public.users)<>3
 THEN RAISE EXCEPTION 'P4-05 blank negative requires exact isolated 3-actor PG17'; END IF;
 SELECT user_id INTO STRICT v_uid FROM private.exam_prep_synthetic_identities
 WHERE run_id='SV-P1P5-MIXED-TIMED-HTTP-01'
 AND identity_kind='learner' AND identity_status='active';
 SELECT program_version_id INTO STRICT v_program
 FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 FOREACH v_comp IN ARRAY ARRAY['P1','P5'] LOOP
   SELECT count(*)::int,
     count(*) FILTER(WHERE private.exam_prep_timed_execution_comparable_v1(t.session_id))::int,
     count(*) FILTER(WHERE t.answered_items=0 AND t.unattempted_items>0)::int,
     coalesce(sum((SELECT count(*) FROM private.exam_prep_responses r
       WHERE r.session_id=t.session_id)),0)::int
   INTO v_total,v_exec,v_blank,v_saved
   FROM private.exam_prep_timed_attempt_results t
   JOIN private.exam_prep_sessions s ON s.id=t.session_id
   WHERE s.user_id=v_uid AND s.status='finalized'
   AND s.component_code=v_comp AND s.session_type='paper'
   AND t.attempt_kind='full_paper';
   SELECT operational_stage,app_readiness_estimate INTO STRICT v_stage,v_est
   FROM private.exam_prep_stage_states WHERE user_id=v_uid
   AND program_version_id=v_program AND component_code=v_comp
   AND engine_version='objective_state_v1';
   v_operational:=private.exam_prep_stage5_operational_completion_v1(v_uid,v_program,v_comp);
   v_scored:=private.exam_prep_stage5_readiness_status_v1(v_uid,v_program,v_comp);
   IF v_total<>4 OR v_exec<>3 OR v_blank<>1
     OR v_saved<>(CASE WHEN v_comp='P1' THEN 30 ELSE 21 END)
     OR v_stage<>6 OR v_est<>'INSUFFICIENT_EVIDENCE'
     OR NOT coalesce((v_operational->>'operational_calibration_access')::boolean,false)
     OR (v_operational->>'compatible_execution_papers')::int<>3
     OR coalesce((v_scored->>'ready')::boolean,false)
   THEN RAISE EXCEPTION
      'P4-05 blank Paper damaged honest execution/score state %: total %, executed %, blank %, saved %, stage %, estimate %, operational %, scored %',
      v_comp,v_total,v_exec,v_blank,v_saved,v_stage,v_est,v_operational,v_scored;
   END IF;
   RAISE NOTICE 'P4-05 PASS %: 3 executed signed Papers plus 1 fully blank signed Paper excluded, Stage6 and score firewall intact',v_comp;
 END LOOP;
 IF EXISTS(SELECT 1 FROM private.exam_prep_timed_written_self_marks w
 WHERE w.user_id=v_uid)
 THEN RAISE EXCEPTION 'P4-05 signed empty paper generated fake self-awarded marks'; END IF;
 RAISE NOTICE 'P4-05 PASS: blank and skipped full Paper does not qualify for operational execution evidence or grade readiness';
END $proof$;
