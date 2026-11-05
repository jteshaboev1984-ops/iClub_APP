-- Issue #450 P4-05 legitimate Stage3 -> Stage4 learning prerequisites.
-- Disposable PG17 ONLY. The included pg_temp helpers from P2-69
-- submit actual published objective answers via existing public RPCs;
-- NO direct stage, skills, marks, grades, entitlement or profile assignment.
\set ON_ERROR_STOP on
DO $proof$
DECLARE
 v_run text:='SV-P1P5-MIXED-TIMED-HTTP-01';
 v_uid uuid;v_program bigint;v_comp text;
 v_mixed_p1 int;v_mixed_p5 int;
 v_retests_p1 int;v_retests_p5 int;
 v_l3 int;v_stage int;v_status jsonb;
BEGIN
 IF current_database()<>'postgres'
    OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
    OR (SELECT count(*) FROM public.users)<>3
    OR (SELECT count(*) FROM auth.users)<>3
 THEN RAISE EXCEPTION 'P4-05 REFUSED: isolated three-actor PG17 only'; END IF;
 SELECT user_id INTO STRICT v_uid
 FROM private.exam_prep_synthetic_identities
 WHERE run_id=v_run AND identity_kind='learner' AND identity_status='active';
 SELECT program_version_id INTO STRICT v_program
 FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 IF EXISTS(SELECT 1 FROM private.exam_prep_feature_entitlements
   WHERE user_id=v_uid AND mentor_care_entitled=true)
 THEN RAISE EXCEPTION 'P4-05 mistakenly requires Mentor'; END IF;
 -- Earn the remaining skill coverage and objective transfer using the
 -- same real published-content test helpers as the existing P2-69 lifecycle.
 PERFORM pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P1',45);
 PERFORM pg_temp.p269_ensure_learning_first_n_v1(v_uid,v_program,'P5',36);
 v_mixed_p1:=pg_temp.p269_complete_selected_mixed_v1(v_uid,v_program,'P1');
 v_mixed_p5:=pg_temp.p269_complete_selected_mixed_v1(v_uid,v_program,'P5');
 IF v_mixed_p1<1 OR v_mixed_p5<1
 THEN RAISE EXCEPTION 'P4-05 real objective mixed transfer missing'; END IF;
 PERFORM private.rebuild_exam_prep_state_v1(v_uid,null);
 -- Time alone cannot advance the learner; the delayed retests must truly pass.
 PERFORM pg_temp.p269_advance_days_v1(v_run,7,'P4-05 objective delayed retest eligibility');
 v_retests_p1:=pg_temp.p269_complete_retests_all_skills_v1(v_uid,v_program,'P1');
 v_retests_p5:=pg_temp.p269_complete_retests_all_skills_v1(v_uid,v_program,'P5');
 IF v_retests_p1<>45 OR v_retests_p5<>36
 THEN RAISE EXCEPTION 'P4-05 actual governed retests mismatch P1 %, P5 %',v_retests_p1,v_retests_p5;
 END IF;
 PERFORM private.rebuild_exam_prep_state_v1(v_uid,null);
 FOREACH v_comp IN ARRAY ARRAY['P1','P5'] LOOP
   SELECT operational_stage,l3_count INTO STRICT v_stage,v_l3
   FROM private.exam_prep_stage_states
   WHERE user_id=v_uid AND program_version_id=v_program
     AND component_code=v_comp AND engine_version='objective_state_v1';
   v_status:=private.exam_prep_stage3_exit_status_v1(v_uid,v_program,v_comp);
   IF v_stage<>4
      OR v_l3<>(CASE WHEN v_comp='P1' THEN 45 ELSE 36 END)
      OR NOT coalesce((v_status->>'ready')::boolean,false)
      OR (v_status->>'comparable_full_baseline_count')::int<>1
   THEN RAISE EXCEPTION 'P4-05 failed legitimate Stage3 exit % stage % L3 % status %',
      v_comp,v_stage,v_l3,v_status;
   END IF;
 END LOOP;
 IF EXISTS(SELECT 1 FROM public.practice_attempts)
   OR EXISTS(SELECT 1 FROM public.tour_attempts)
   OR EXISTS(SELECT 1 FROM public.certificates)
 THEN RAISE EXCEPTION 'P4-05 objective learning spilled into legacy'; END IF;
 RAISE NOTICE 'P4-05 PASS: completed real objective L3, mixed transfer and delayed retests before Stage4 for P1/P5; no Mentor or grade';
END $proof$;
