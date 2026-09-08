-- P2-13 / C24 broad diagnostic vs multi-session full placement matrix.
-- Read-contract only. No placement, evidence, mastery, stage, correction or legacy mutation is allowed.
\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE p213_user(user_id uuid primary key) ON COMMIT DROP;
INSERT INTO p213_user VALUES(gen_random_uuid());
GRANT SELECT ON p213_user TO authenticated,service_role;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated','p213-'||replace(user_id::text,'-','')||'@invalid.example',now(),now(),false,false
FROM p213_user;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P213','Placement Contract','en',now(),false FROM p213_user;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE program_key='math_as_p1_p5';

INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from
)
SELECT user_id,'active',true,false,false,now() FROM p213_user;

CREATE TEMP TABLE p213_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_component_placements) placements,
  (SELECT count(*) FROM private.exam_prep_component_access_gates) access_gates,
  (SELECT count(*) FROM private.exam_prep_prerequisite_states) prerequisite_states,
  (SELECT count(*) FROM private.exam_prep_evidence_events) evidence_events,
  (SELECT count(*) FROM private.exam_prep_skill_states) skill_states,
  (SELECT count(*) FROM private.exam_prep_stage_states) stage_states,
  (SELECT count(*) FROM private.exam_prep_correction_cases) correction_cases,
  (SELECT count(*) FROM private.exam_prep_timed_attempt_results) timed_results,
  (SELECT count(*) FROM private.exam_prep_weekly_plans) weekly_plans,
  (SELECT count(*) FROM public.practice_attempts) practice_attempts,
  (SELECT count(*) FROM public.practice_answers) practice_answers,
  (SELECT count(*) FROM public.tour_attempts) tour_attempts,
  (SELECT count(*) FROM public.tour_answers) tour_answers,
  (SELECT count(*) FROM public.certificates) certificates;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p213_user),true);
SET LOCAL ROLE authenticated;

DO $$
DECLARE
  v_p1 jsonb;
  v_p5 jsonb;
BEGIN
  v_p1:=public.get_exam_prep_stage0_workflow_safe_v1('P1');
  v_p5:=public.get_exam_prep_stage0_workflow_safe_v1('P5');

  IF v_p1->>'contract_version'<>'p2_13_c24_v1'
     OR v_p5->>'contract_version'<>'p2_13_c24_v1'
     OR v_p1->>'workflow_type'<>'component_specific_full_placement'
     OR v_p5->>'workflow_type'<>'component_specific_full_placement'
     OR v_p1->>'placement_model'<>'multi_session'
     OR v_p5->>'placement_model'<>'multi_session' THEN
    RAISE EXCEPTION 'P2-13 C24 workflow contract mismatch P1=% P5=%',v_p1,v_p5;
  END IF;

  IF (v_p1->>'single_session_completion_required')::boolean IS DISTINCT FROM false
     OR (v_p5->>'single_session_completion_required')::boolean IS DISTINCT FROM false
     OR (v_p1->>'time_based_stage_completion')::boolean IS DISTINCT FROM false
     OR (v_p5->>'time_based_stage_completion')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-13 C24 time gained placement authority';
  END IF;

  IF (v_p1->'broad_screening'->>'required_items')::int<>24
     OR (v_p1->'broad_screening'->>'required_areas')::int<>8
     OR (v_p5->'broad_screening'->>'required_items')::int<>15
     OR (v_p5->'broad_screening'->>'required_areas')::int<>5 THEN
    RAISE EXCEPTION 'P2-13 C24 broad screen denominator drift P1=% P5=%',v_p1->'broad_screening',v_p5->'broad_screening';
  END IF;

  IF v_p1->'broad_screening'->>'delivery_model'<>'governed_short_packages'
     OR v_p5->'broad_screening'->>'delivery_model'<>'governed_short_packages'
     OR v_p1->'broad_screening'->>'fixed_duration_minutes' IS NOT NULL
     OR v_p5->'broad_screening'->>'fixed_duration_minutes' IS NOT NULL THEN
    RAISE EXCEPTION 'P2-13 C24 broad screening was converted to a fixed timed sitting';
  END IF;

  IF (v_p1->'targeted_confirmation'->>'min_items')::int<>3
     OR (v_p1->'targeted_confirmation'->>'max_items')::int<>5
     OR (v_p5->'targeted_confirmation'->>'min_items')::int<>3
     OR (v_p5->'targeted_confirmation'->>'max_items')::int<>5
     OR (v_p1->'targeted_confirmation'->>'duplicated_broad_testing_allowed')::boolean IS DISTINCT FROM false
     OR (v_p5->'targeted_confirmation'->>'duplicated_broad_testing_allowed')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-13 C24 targeted confirmation contract drift';
  END IF;

  IF (v_p1->'human_confirmation'->>'mentor_required_for_core')::boolean IS DISTINCT FROM false
     OR (v_p5->'human_confirmation'->>'mentor_required_for_core')::boolean IS DISTINCT FROM false
     OR (v_p1->'human_confirmation'->>'core_conservative_route_allowed')::boolean IS DISTINCT FROM true
     OR (v_p5->'human_confirmation'->>'core_conservative_route_allowed')::boolean IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'P2-13 C24 Core was made dependent on Mentor Care';
  END IF;

  IF (v_p1->'safeguards'->>'p1_p5_separate')::boolean IS DISTINCT FROM true
     OR (v_p5->'safeguards'->>'p1_p5_separate')::boolean IS DISTINCT FROM true
     OR (v_p1->'safeguards'->>'calendar_cannot_complete_placement')::boolean IS DISTINCT FROM true
     OR (v_p1->'safeguards'->>'duration_cannot_complete_placement')::boolean IS DISTINCT FROM true
     OR (v_p1->'safeguards'->>'advanced_route_auto_awarded')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-13 C24 placement safeguards drift';
  END IF;
END
$$;

RESET ROLE;

DO $$
DECLARE
  b record;
  a record;
BEGIN
  SELECT * INTO b FROM p213_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_component_placements) placements,
    (SELECT count(*) FROM private.exam_prep_component_access_gates) access_gates,
    (SELECT count(*) FROM private.exam_prep_prerequisite_states) prerequisite_states,
    (SELECT count(*) FROM private.exam_prep_evidence_events) evidence_events,
    (SELECT count(*) FROM private.exam_prep_skill_states) skill_states,
    (SELECT count(*) FROM private.exam_prep_stage_states) stage_states,
    (SELECT count(*) FROM private.exam_prep_correction_cases) correction_cases,
    (SELECT count(*) FROM private.exam_prep_timed_attempt_results) timed_results,
    (SELECT count(*) FROM private.exam_prep_weekly_plans) weekly_plans,
    (SELECT count(*) FROM public.practice_attempts) practice_attempts,
    (SELECT count(*) FROM public.practice_answers) practice_answers,
    (SELECT count(*) FROM public.tour_attempts) tour_attempts,
    (SELECT count(*) FROM public.tour_answers) tour_answers,
    (SELECT count(*) FROM public.certificates) certificates
  INTO a;

  IF row_to_json(a)::text<>row_to_json(b)::text THEN
    RAISE EXCEPTION 'P2-13 C24 read contract mutated learner/legacy state before=% after=%',row_to_json(b),row_to_json(a);
  END IF;

  IF has_function_privilege('anon','public.get_exam_prep_stage0_workflow_safe_v1(text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-13 C24 anon can execute workflow API';
  END IF;
  IF NOT has_function_privilege('authenticated','public.get_exam_prep_stage0_workflow_safe_v1(text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-13 C24 authenticated Core cannot execute workflow API';
  END IF;
  IF has_function_privilege('authenticated','private.exam_prep_stage0_workflow_contract_v1(text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-13 C24 authenticated can execute private workflow contract directly';
  END IF;
END
$$;

ROLLBACK;

DO $$
BEGIN
  IF EXISTS(select 1 from auth.users where email like 'p213-%@invalid.example') THEN
    RAISE EXCEPTION 'P2-13 C24 synthetic auth residue found';
  END IF;
  IF EXISTS(select 1 from public.users where first_name='P213' and last_name='Placement Contract') THEN
    RAISE EXCEPTION 'P2-13 C24 synthetic public user residue found';
  END IF;
END
$$;

\echo 'P2-13 broad diagnostic / multi-session placement matrix: GREEN'
