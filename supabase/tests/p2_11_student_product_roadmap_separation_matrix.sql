-- P2-11 / C22 Student vs Product roadmap separation matrix.
-- Synthetic Core learner only. Product calendar metadata must never create learner stage/mastery/evidence.
\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE p211_user(user_id uuid primary key) ON COMMIT DROP;
INSERT INTO p211_user VALUES(gen_random_uuid());
GRANT SELECT ON p211_user TO authenticated,service_role;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated','p211-'||replace(user_id::text,'-','')||'@invalid.example',now(),now(),false,false
FROM p211_user;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P211','Roadmap Separation','en',now(),false FROM p211_user;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;

INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from
)
SELECT user_id,'active',true,false,false,now() FROM p211_user;

INSERT INTO private.exam_prep_exam_profiles(
  user_id,program_version_id,exam_series,target_grade,total_student_hours_available,
  mathematics_hours_budget,active_week_no,created_by,updated_by
)
SELECT u.user_id,pv.id,'May/June 2027','A',12,6,1,u.user_id,u.user_id
FROM p211_user u
CROSS JOIN LATERAL (
  SELECT id FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active'
) pv;

CREATE TEMP TABLE p211_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_evidence_events WHERE user_id=(SELECT user_id FROM p211_user)) evidence_events,
  (SELECT count(*) FROM private.exam_prep_skill_states WHERE user_id=(SELECT user_id FROM p211_user)) skill_states,
  (SELECT count(*) FROM private.exam_prep_stage_states WHERE user_id=(SELECT user_id FROM p211_user)) stage_states,
  (SELECT count(*) FROM private.exam_prep_correction_cases WHERE user_id=(SELECT user_id FROM p211_user)) correction_cases,
  (SELECT count(*) FROM private.exam_prep_timed_attempt_results WHERE user_id=(SELECT user_id FROM p211_user)) timed_results,
  (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=(SELECT user_id FROM p211_user)) weekly_plans,
  (SELECT count(*) FROM public.practice_attempts WHERE user_id=(SELECT user_id FROM p211_user)) practice_attempts,
  (SELECT count(*) FROM public.tour_attempts WHERE user_id=(SELECT user_id FROM p211_user)) tour_attempts,
  (SELECT count(*) FROM public.certificates) certificates;

DO $$
DECLARE
  v_program bigint;
  v_student int;
  v_product int;
  v_skill text;
  v_status jsonb;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';

  SELECT count(*) INTO v_student
  FROM private.exam_prep_student_roadmap_windows
  WHERE program_version_id=v_program AND roadmap_version='beta_2026_09_15_v1' AND status='active';
  IF v_student<>7 THEN RAISE EXCEPTION 'P2-11 expected 7 student stage windows, got %',v_student; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_student_roadmap_windows
    WHERE program_version_id=v_program AND stage_no=0 AND status='active'
      AND active_week_from=1 AND active_week_through=2
      AND target_exit_date=date '2026-09-21' AND latest_safe_exit_date=date '2026-09-28'
  ) THEN RAISE EXCEPTION 'P2-11 Stage 0 planning window mismatch'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_student_roadmap_windows
    WHERE program_version_id=v_program AND stage_no=1 AND status='active'
      AND target_exit_date=date '2026-10-12' AND latest_safe_exit_date=date '2026-10-19'
  ) THEN RAISE EXCEPTION 'P2-11 Stage 1 planning window mismatch'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_student_roadmap_windows
    WHERE program_version_id=v_program AND stage_no=2 AND status='active'
      AND target_exit_date=date '2027-02-01' AND latest_safe_exit_date=date '2027-02-08'
  ) THEN RAISE EXCEPTION 'P2-11 Stage 2 planning window mismatch'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_student_roadmap_windows
    WHERE program_version_id=v_program AND stage_no=3 AND status='active'
      AND target_exit_date=date '2027-02-22' AND latest_safe_exit_date=date '2027-03-01'
  ) THEN RAISE EXCEPTION 'P2-11 Stage 3 planning window mismatch'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_student_roadmap_windows
    WHERE program_version_id=v_program AND stage_no=4 AND status='active'
      AND target_exit_date=date '2027-03-29' AND latest_safe_exit_date=date '2027-04-05'
  ) THEN RAISE EXCEPTION 'P2-11 Stage 4 planning window mismatch'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_student_roadmap_windows
    WHERE program_version_id=v_program AND stage_no=5 AND status='active'
      AND target_exit_date=date '2027-04-26' AND latest_safe_exit_date=date '2027-04-30'
  ) THEN RAISE EXCEPTION 'P2-11 Stage 5 planning window mismatch'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_student_roadmap_windows
    WHERE program_version_id=v_program AND stage_no=6 AND status='active'
      AND target_exit_date=date '2027-05-24' AND latest_safe_exit_date IS NULL
      AND latest_safe_basis='official_component_date'
  ) THEN RAISE EXCEPTION 'P2-11 Stage 6 planning window mismatch'; END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_student_roadmap_windows
    WHERE program_version_id=v_program AND status='active'
      AND (progression_basis<>'evidence_only' OR planning_only IS DISTINCT FROM true OR calendar_auto_promotion IS DISTINCT FROM false)
  ) THEN RAISE EXCEPTION 'P2-11 calendar gained student progression authority'; END IF;

  SELECT count(*) INTO v_product
  FROM private.exam_prep_product_roadmap_milestones
  WHERE program_version_id=v_program AND roadmap_version='product_calendar_2026_2027_v1' AND milestone_status<>'retired';
  IF v_product<>2 THEN RAISE EXCEPTION 'P2-11 expected 2 product calendar milestones, got %',v_product; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_product_roadmap_milestones
    WHERE program_version_id=v_program AND milestone_key='controlled_beta_availability'
      AND target_date=date '2026-09-15' AND product_label='Controlled beta availability'
  ) THEN RAISE EXCEPTION 'P2-11 beta availability product milestone mismatch'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_product_roadmap_milestones
    WHERE program_version_id=v_program AND milestone_key='product_content_complete'
      AND target_date=date '2027-02-15' AND product_label='Product Content-Complete'
  ) THEN RAISE EXCEPTION 'P2-11 Product Content-Complete milestone mismatch'; END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_product_roadmap_milestones
    WHERE program_version_id=v_program AND milestone_status<>'retired'
      AND (can_force_learner_stage OR can_raise_learner_mastery OR can_label_learner_exam_ready)
  ) THEN RAISE EXCEPTION 'P2-11 forbidden product authority detected'; END IF;

  SELECT rs.skill_code INTO v_skill
  FROM private.exam_prep_content_runway_releases r
  JOIN private.exam_prep_content_runway_release_skills rs ON rs.release_id=r.id AND rs.required_for_release
  WHERE r.program_version_id=v_program AND r.component_code='P1' AND r.schedule_status='active'
    AND r.active_week_from=21 AND r.active_week_through=24
  ORDER BY rs.skill_code LIMIT 1;
  IF v_skill IS NULL THEN RAISE EXCEPTION 'P2-11 AW21-24 P1 runway fixture missing'; END IF;

  v_status:=private.exam_prep_product_dependency_for_week_v1(v_program,'P1',23::smallint);
  IF (v_status->>'hard_floor_2w_green')::boolean IS DISTINCT FROM true
     OR (v_status->>'can_force_learner_stage')::boolean IS DISTINCT FROM false
     OR (v_status->>'can_raise_learner_mastery')::boolean IS DISTINCT FROM false
     OR (v_status->>'can_create_learner_evidence')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-11 week-23 dependency contract mismatch: %',v_status;
  END IF;

  IF private.exam_prep_skill_runway_ready_for_week_v1(v_program,'P1',v_skill,23::smallint) IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'P2-11 two-week hard floor should allow governed AW23 learning skill=%',v_skill;
  END IF;

  v_status:=private.exam_prep_product_dependency_for_week_v1(v_program,'P1',24::smallint);
  IF (v_status->>'hard_floor_2w_green')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-11 week-24 should fail two-week runway floor: %',v_status;
  END IF;
  IF private.exam_prep_skill_runway_ready_for_week_v1(v_program,'P1',v_skill,24::smallint) IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-11 insufficient product runway must block NEW learning without promoting learner';
  END IF;

  v_status:=private.exam_prep_product_roadmap_status_v1();
  IF v_status->>'contract_version'<>'p2_11_c22_v1'
     OR v_status->>'clock_type'<>'calendar_delivery_deadlines_and_runway'
     OR (v_status->>'product_status_does_not_equal_learner_readiness')::boolean IS DISTINCT FROM true
     OR (v_status->>'learner_state_mutated')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-11 product roadmap service contract failed: %',v_status;
  END IF;
  IF (v_status->'content_support'->'P1'->>'canonical_skills')::int<>45
     OR (v_status->'content_support'->'P5'->>'canonical_skills')::int<>36 THEN
    RAISE EXCEPTION 'P2-11 product support denominators drifted: %',v_status->'content_support';
  END IF;
END
$$;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p211_user),true);
SET LOCAL ROLE authenticated;

DO $$
DECLARE
  v_p1 jsonb;
  v_p5 jsonb;
BEGIN
  v_p1:=public.get_exam_prep_student_roadmap_safe_v1('P1');
  v_p5:=public.get_exam_prep_student_roadmap_safe_v1('P5');

  IF v_p1->>'roadmap_type'<>'student'
     OR v_p1->>'clock_type'<>'active_week_plus_target_latest_safe'
     OR (v_p1->>'active_week_no')::int<>1
     OR (v_p1->>'operational_stage')::int<>0
     OR v_p1->>'progression_basis'<>'evidence_only'
     OR (v_p1->>'calendar_auto_promotion')::boolean IS DISTINCT FROM false
     OR (v_p1->>'product_deadline_can_force_stage')::boolean IS DISTINCT FROM false
     OR (v_p1->>'product_content_complete_is_syllabus_closure')::boolean IS DISTINCT FROM false
     OR (v_p1->>'product_content_complete_is_learner_exam_ready')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-11 P1 student roadmap contract failed: %',v_p1;
  END IF;

  IF v_p1->>'target_exit_date'<>'2026-09-21' OR v_p1->>'latest_safe_exit_date'<>'2026-09-28' THEN
    RAISE EXCEPTION 'P2-11 Stage 0 target/latest-safe projection mismatch: %',v_p1;
  END IF;

  IF (v_p1->'product_dependency'->>'hard_floor_2w_green')::boolean IS DISTINCT FROM true
     OR (v_p5->'product_dependency'->>'hard_floor_2w_green')::boolean IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'P2-11 opening learner route lacks required two-week product runway';
  END IF;

  IF (v_p1->>'p1_p5_mastery_separate')::boolean IS DISTINCT FROM true
     OR (v_p5->>'p1_p5_mastery_separate')::boolean IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'P2-11 P1/P5 separation flag missing';
  END IF;
END
$$;

RESET ROLE;

-- Product calendar changes are product-only metadata. Even a status change cannot create learner state/evidence.
UPDATE private.exam_prep_product_roadmap_milestones
SET milestone_status='met',updated_at=now()
WHERE milestone_key='controlled_beta_availability' AND milestone_status='scheduled';

DO $$
DECLARE
  v_uid uuid;
  b record;
  a record;
BEGIN
  SELECT user_id INTO v_uid FROM p211_user;
  SELECT * INTO b FROM p211_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_evidence_events WHERE user_id=v_uid) evidence_events,
    (SELECT count(*) FROM private.exam_prep_skill_states WHERE user_id=v_uid) skill_states,
    (SELECT count(*) FROM private.exam_prep_stage_states WHERE user_id=v_uid) stage_states,
    (SELECT count(*) FROM private.exam_prep_correction_cases WHERE user_id=v_uid) correction_cases,
    (SELECT count(*) FROM private.exam_prep_timed_attempt_results WHERE user_id=v_uid) timed_results,
    (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=v_uid) weekly_plans,
    (SELECT count(*) FROM public.practice_attempts WHERE user_id=v_uid) practice_attempts,
    (SELECT count(*) FROM public.tour_attempts WHERE user_id=v_uid) tour_attempts,
    (SELECT count(*) FROM public.certificates) certificates
  INTO a;

  IF row_to_json(a)::text<>row_to_json(b)::text THEN
    RAISE EXCEPTION 'P2-11 product milestone mutated learner/legacy state before=% after=%',row_to_json(b),row_to_json(a);
  END IF;

  IF has_table_privilege('authenticated','private.exam_prep_student_roadmap_windows','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_product_roadmap_milestones','SELECT') THEN
    RAISE EXCEPTION 'P2-11 authenticated can directly read private roadmap tables';
  END IF;

  IF has_function_privilege('anon','public.get_exam_prep_student_roadmap_safe_v1(text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-11 anon can execute student roadmap API';
  END IF;
  IF NOT has_function_privilege('authenticated','public.get_exam_prep_student_roadmap_safe_v1(text)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-11 authenticated Core cannot execute student roadmap API';
  END IF;
  IF has_function_privilege('authenticated','private.exam_prep_product_roadmap_status_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'P2-11 authenticated can execute private product roadmap status';
  END IF;
END
$$;

ROLLBACK;

DO $$
BEGIN
  IF EXISTS(select 1 from auth.users where email like 'p211-%@invalid.example') THEN
    RAISE EXCEPTION 'P2-11 synthetic auth residue found';
  END IF;
  IF EXISTS(select 1 from public.users where first_name='P211' and last_name='Roadmap Separation') THEN
    RAISE EXCEPTION 'P2-11 synthetic public user residue found';
  END IF;
END
$$;

\echo 'P2-11 Student/Product roadmap separation matrix: GREEN'
