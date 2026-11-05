-- Issue #450 P4-05 after six genuine signed full Paper finalizations.
-- READ ONLY; disposable PG17 test actors only, no fake marks or stage writes.
\set ON_ERROR_STOP on
DO $proof$
DECLARE
 v_uid uuid;v_program bigint;v_comp text;v_total int;v_distinct int;
 v_exec int;v_scored int;v_saved int;v_writing int;v_op jsonb;
 v_stage4 jsonb;v_ready jsonb;v_stage int;v_mentor boolean;
BEGIN
 IF current_database()<>'postgres'
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM public.users)<>3
    OR (SELECT count(*) FROM auth.users)<>3
 THEN RAISE EXCEPTION 'P4-05 REFUSED: disposable PG17 with 3 synthetic actors required'; END IF;
 SELECT user_id INTO STRICT v_uid
 FROM private.exam_prep_synthetic_identities
 WHERE run_id='SV-P1P5-MIXED-TIMED-HTTP-01'
   AND identity_kind='learner' AND identity_status='active';
 SELECT program_version_id INTO STRICT v_program
 FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 SELECT mentor_care_entitled INTO STRICT v_mentor
 FROM private.exam_prep_feature_entitlements WHERE user_id=v_uid
 AND entitlement_status='active';
 IF v_mentor THEN RAISE EXCEPTION 'P4-05 Mentor wrongly required'; END IF;
 FOREACH v_comp IN ARRAY ARRAY['P1','P5'] LOOP
   SELECT count(*)::int,
     count(DISTINCT s.assessment_id)::int,
     count(*) FILTER(WHERE private.exam_prep_timed_execution_comparable_v1(s.id))::int,
     count(*) FILTER(WHERE private.exam_prep_timed_score_comparable_v1(s.id))::int,
     coalesce(sum((SELECT count(*) FROM private.exam_prep_responses r
       WHERE r.session_id=s.id AND r.user_id=v_uid)),0)::int,
     coalesce(sum((SELECT count(*) FROM private.exam_prep_responses r
       WHERE r.session_id=s.id AND r.user_id=v_uid AND r.response_kind='written'
         AND r.learner_artifact IS NOT NULL AND r.is_correct IS NULL)),0)::int
   INTO v_total,v_distinct,v_exec,v_scored,v_saved,v_writing
   FROM private.exam_prep_sessions s
   JOIN private.exam_prep_timed_attempt_results t ON t.session_id=s.id
   WHERE s.user_id=v_uid AND s.component_code=v_comp
     AND s.session_type='paper' AND s.status='finalized'
     AND t.attempt_kind='full_paper';
   v_stage4:=private.exam_prep_stage4_raw_evidence_v1(v_uid,v_program,v_comp);
   v_op:=private.exam_prep_stage5_operational_completion_v1(v_uid,v_program,v_comp);
   v_ready:=private.exam_prep_stage5_readiness_status_v1(v_uid,v_program,v_comp);
   SELECT operational_stage INTO STRICT v_stage
   FROM private.exam_prep_stage_states WHERE user_id=v_uid
     AND program_version_id=v_program AND component_code=v_comp
     AND engine_version='objective_state_v1';
   IF v_total<>3 OR v_distinct<>3 OR v_exec<>3 OR v_scored<>0
      OR v_saved<>(CASE WHEN v_comp='P1' THEN 30 ELSE 21 END)
      OR v_writing<>v_saved
      OR (v_stage4->>'comparable_full_attempt_count_total')::int<>3
      OR (v_op->>'compatible_execution_papers')::int<3
      OR coalesce((v_op->>'operational_calibration_access')::boolean,false)
      OR coalesce((v_ready->>'ready')::boolean,false)
      OR coalesce((v_op->>'exam_readiness_claim')::boolean,false)
      OR v_stage<>3
   THEN RAISE EXCEPTION
      'P4-05 3 signed written paper evidence/grade firewall failed % attempts % distinct % executed % scored % saved % written % stage4 % op % readiness % current_stage %',
      v_comp,v_total,v_distinct,v_exec,v_scored,v_saved,v_writing,
      v_stage4,v_op,v_ready,v_stage;
   END IF;
   RAISE NOTICE 'P4-05 PASS %: 3 distinct genuine signed full Papers, all written artifacts, zero grade, Stage6 still gated by actual academic evidence',v_comp;
 END LOOP;
 IF EXISTS(SELECT 1 FROM private.exam_prep_timed_written_self_marks w
   WHERE w.user_id=v_uid)
 THEN RAISE EXCEPTION 'P4-05 forbidden learner-written exam marks persisted'; END IF;
 IF EXISTS(SELECT 1 FROM public.practice_attempts)
   OR EXISTS(SELECT 1 FROM public.tour_attempts)
   OR EXISTS(SELECT 1 FROM public.certificates)
 THEN RAISE EXCEPTION 'P4-05 protected Practice/Tours/certificate mutation'; END IF;
 RAISE NOTICE 'P4-05 PASS: signed P1/P5 three-Paper real path, written score unknown, no premature stage, no Mentor, no legacy contamination';
END $proof$;
