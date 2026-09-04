-- P0-16 Controlled Beta isolated acceptance matrix.
-- Requires: PGOPTIONS='-c p016.isolated_db=true'
-- Test-only; all synthetic cohort/user mutations end in ROLLBACK.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p016.isolated_db',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P0-16 REFUSED: p016.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

-- Baseline must be fail-closed and P0-16 deployment must not pre-enroll anyone.
DO $$
DECLARE v_cfg record; v_count int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 baseline not fail-closed';
  END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_cohorts;
  IF v_count<>0 THEN RAISE EXCEPTION 'P0-16 beta cohort table not empty at baseline'; END IF;
END
$$;

CREATE TEMP TABLE p016_people(
  ord integer PRIMARY KEY,
  user_id uuid NOT NULL UNIQUE,
  kind text NOT NULL CHECK(kind IN ('learner','mentor'))
) ON COMMIT DROP;

INSERT INTO p016_people(ord,user_id,kind)
SELECT g,gen_random_uuid(),'learner' FROM generate_series(1,18) g
UNION ALL
SELECT 100+g,gen_random_uuid(),'mentor' FROM generate_series(1,4) g;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       format('p016-%s-%s@invalid.example',ord,replace(user_id::text,'-','')),
       now(),now(),false,false
FROM p016_people;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,
       CASE WHEN kind='learner' THEN 'P016 Learner' ELSE 'P016 Mentor' END,
       ord::text,'en',now(),false
FROM p016_people;

-- Four governed mentors and four Mentor Care assignments (learners 15..18).
INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT user_id,'mentor','active' FROM p016_people WHERE ord BETWEEN 101 AND 104;

INSERT INTO private.exam_prep_mentor_service_status(learner_user_id,service_status,status_reason)
SELECT user_id,'assigned_active','P0-16 isolated beta readiness'
FROM p016_people WHERE ord BETWEEN 15 AND 18;

INSERT INTO private.exam_prep_mentor_assignments(
  learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
)
SELECT l.user_id,m.user_id,
       CASE WHEN l.ord%2=0 THEN 'P5' ELSE 'P1' END,
       'active',now()
FROM p016_people l
JOIN p016_people m ON m.ord=86+l.ord
WHERE l.ord BETWEEN 15 AND 18;

-- The harness intentionally switches into service_role for the mutation RPCs.
-- Grant that role read access to the transaction-local synthetic roster only;
-- the table disappears on ROLLBACK/connection teardown.
GRANT SELECT ON TABLE p016_people TO service_role;

-- Exercise the mutation surface through service_role-only RPCs.
SET LOCAL ROLE service_role;

SELECT public.stage_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_test_01',18::smallint,'P0-16 isolated 18-learner controlled-beta matrix'
);

SELECT public.set_exam_prep_beta_member_v1(
  'math_as_p1_p5_beta_test_01',p.user_id,
  CASE WHEN p.ord<=7 THEN 'core' WHEN p.ord<=14 THEN 'ai_assist' ELSE 'mentor_care' END,
  CASE WHEN p.ord IN (1,2,8,9,15) THEN 1::smallint ELSE 2::smallint END
)
FROM p016_people p WHERE p.ord BETWEEN 1 AND 18 ORDER BY p.ord;

SELECT public.approve_exam_prep_controlled_beta_v1('math_as_p1_p5_beta_test_01');

RESET ROLE;

-- Approval is allowlist/sign-off only: nobody may have access yet.
DO $$
DECLARE v_cfg record; v_count int; v_mix record;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 approval unexpectedly enabled features';
  END IF;

  SELECT count(*) INTO v_count
  FROM private.exam_prep_feature_entitlements e
  JOIN p016_people p ON p.user_id=e.user_id
  WHERE p.ord<=18 AND e.entitlement_status='active';
  IF v_count<>0 THEN RAISE EXCEPTION 'P0-16 approval activated % learner entitlements',v_count; END IF;

  SELECT
    count(*) filter(where m.service_mode='core') core_n,
    count(*) filter(where m.service_mode='ai_assist') ai_n,
    count(*) filter(where m.service_mode='mentor_care') mentor_n,
    count(*) total_n
  INTO v_mix
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_test_01' AND m.member_status='approved';
  IF v_mix.total_n<>18 OR v_mix.core_n<>7 OR v_mix.ai_n<>7 OR v_mix.mentor_n<>4 THEN
    RAISE EXCEPTION 'P0-16 service mix mismatch: %',row_to_json(v_mix);
  END IF;
END
$$;

-- Canary: 5 learners = 2 Core + 2 AI Assist + 1 Mentor Care.
SET LOCAL ROLE service_role;
SELECT public.activate_exam_prep_controlled_beta_wave_v1('math_as_p1_p5_beta_test_01',1::smallint);
RESET ROLE;

DO $$
DECLARE
  v_cfg record;
  v_active int;
  v_waiting int;
  v_uid uuid;
  c record;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta' OR v_cfg.kill_switch OR NOT v_cfg.core_enabled OR NOT v_cfg.ai_enabled OR NOT v_cfg.mentor_enabled THEN
    RAISE EXCEPTION 'P0-16 canary config mismatch: %',row_to_json(v_cfg);
  END IF;

  SELECT count(*) filter(where m.member_status='active'),count(*) filter(where m.member_status='approved')
  INTO v_active,v_waiting
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts b ON b.id=m.cohort_id
  WHERE b.cohort_key='math_as_p1_p5_beta_test_01';
  IF v_active<>5 OR v_waiting<>13 THEN
    RAISE EXCEPTION 'P0-16 canary counts mismatch active=% waiting=%',v_active,v_waiting;
  END IF;

  -- Core canary.
  SELECT user_id INTO v_uid FROM p016_people WHERE ord=1;
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF NOT c.core_access OR c.ai_assist OR c.mentor_care_entitled OR c.mentor_authority THEN
    RAISE EXCEPTION 'P0-16 Core canary capability mismatch: %',row_to_json(c);
  END IF;

  -- AI Assist canary.
  SELECT user_id INTO v_uid FROM p016_people WHERE ord=8;
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF NOT c.core_access OR NOT c.ai_assist OR c.mentor_care_entitled OR c.mentor_authority THEN
    RAISE EXCEPTION 'P0-16 AI canary capability mismatch: %',row_to_json(c);
  END IF;

  -- Mentor Care canary.
  SELECT user_id INTO v_uid FROM p016_people WHERE ord=15;
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF NOT c.core_access OR c.ai_assist OR NOT c.mentor_care_entitled OR NOT c.mentor_assignment_active OR NOT c.mentor_authority THEN
    RAISE EXCEPTION 'P0-16 Mentor canary capability mismatch: %',row_to_json(c);
  END IF;

  -- Wave-2 learner must still be completely dark.
  SELECT user_id INTO v_uid FROM p016_people WHERE ord=3;
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF c.core_access OR c.ai_assist OR c.mentor_care_entitled OR c.mentor_authority THEN
    RAISE EXCEPTION 'P0-16 waiting learner leaked access: %',row_to_json(c);
  END IF;
END
$$;

-- Canary monitor must be green before expansion.
SET LOCAL ROLE service_role;
CREATE TEMP TABLE p016_canary_monitor AS
SELECT public.get_exam_prep_controlled_beta_monitor_v1('math_as_p1_p5_beta_test_01') snapshot;
RESET ROLE;

DO $$
DECLARE v jsonb;
BEGIN
  SELECT snapshot INTO v FROM p016_canary_monitor;
  IF coalesce((v->>'runway_green')::boolean,false) IS NOT TRUE
     OR (v#>>'{member_counts,active}')::int<>5
     OR (v#>>'{integrity,entitlement_mismatches}')::int<>0
     OR (v#>>'{integrity,mentor_readiness_violations}')::int<>0
     OR (v#>>'{integrity,queue_leakage}')::int<>0 THEN
    RAISE EXCEPTION 'P0-16 canary monitor not green: %',v;
  END IF;
END
$$;

-- Expand to the remaining 13 approved learners.
SET LOCAL ROLE service_role;
SELECT public.activate_exam_prep_controlled_beta_wave_v1('math_as_p1_p5_beta_test_01',2::smallint);
RESET ROLE;

DO $$
DECLARE v_count int; v_status text;
BEGIN
  SELECT c.cohort_status INTO v_status
  FROM private.exam_prep_beta_cohorts c WHERE c.cohort_key='math_as_p1_p5_beta_test_01';
  SELECT count(*) INTO v_count
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_test_01' AND m.member_status='active';
  IF v_status<>'active' OR v_count<>18 THEN
    RAISE EXCEPTION 'P0-16 full cohort activation mismatch status=% active=%',v_status,v_count;
  END IF;
END
$$;

-- Human-review recommendations are global metadata, but queue work must appear
-- only for the Mentor Care learner with a governed assignment.
INSERT INTO private.exam_prep_human_review_recommendations(
  learner_user_id,component_code,recommendation_type,source_object_type,source_object_id,recommendation_reason
)
SELECT user_id,'P1','readiness','p016_beta_test','core-1',
       'P0-16 Core learner metadata must not create Mentor Care queue work.'
FROM p016_people WHERE ord=1;

INSERT INTO private.exam_prep_human_review_recommendations(
  learner_user_id,component_code,recommendation_type,source_object_type,source_object_id,recommendation_reason
)
SELECT user_id,'P1','readiness','p016_beta_test','mentor-15',
       'P0-16 Mentor Care learner should enqueue only to the governed assigned mentor.'
FROM p016_people WHERE ord=15;

DO $$
DECLARE v_total int; v_core int; v_mentor int;
BEGIN
  SELECT count(*) INTO v_total
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p016_beta_test';
  SELECT count(*) INTO v_core
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p016_beta_test' AND r.source_object_id='core-1';
  SELECT count(*) INTO v_mentor
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p016_beta_test' AND r.source_object_id='mentor-15';
  IF v_total<>1 OR v_core<>0 OR v_mentor<>1 THEN
    RAISE EXCEPTION 'P0-16 queue isolation mismatch total=% core=% mentor=%',v_total,v_core,v_mentor;
  END IF;
END
$$;

SET LOCAL ROLE service_role;
CREATE TEMP TABLE p016_full_monitor AS
SELECT public.get_exam_prep_controlled_beta_monitor_v1('math_as_p1_p5_beta_test_01') snapshot;
RESET ROLE;

DO $$
DECLARE v jsonb;
BEGIN
  SELECT snapshot INTO v FROM p016_full_monitor;
  IF coalesce((v->>'runway_green')::boolean,false) IS NOT TRUE
     OR (v#>>'{member_counts,active}')::int<>18
     OR (v#>>'{active_service_mix,core}')::int<>7
     OR (v#>>'{active_service_mix,ai_assist}')::int<>7
     OR (v#>>'{active_service_mix,mentor_care}')::int<>4
     OR (v#>>'{integrity,queue_leakage}')::int<>0
     OR (v#>>'{mentor_queue,open_items}')::int<>1 THEN
    RAISE EXCEPTION 'P0-16 full monitor not green: %',v;
  END IF;
END
$$;

-- Emergency rollback must pause access, not delete evidence/state.
CREATE TEMP TABLE p016_preserve_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_evidence_events e JOIN p016_people p ON p.user_id=e.user_id WHERE p.ord<=18) evidence_n,
  (SELECT count(*) FROM private.exam_prep_skill_states s JOIN p016_people p ON p.user_id=s.user_id WHERE p.ord<=18) state_n;

SET LOCAL ROLE service_role;
SELECT public.pause_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_test_01','P0-16 isolated emergency rollback verification'
);
RESET ROLE;

DO $$
DECLARE v_cfg record; v_active int; v_paused int; v_ent_active int; v_before record; v_after record;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 rollback did not fail-close config: %',row_to_json(v_cfg);
  END IF;

  SELECT count(*) filter(where m.member_status='active'),count(*) filter(where m.member_status='paused')
  INTO v_active,v_paused
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_test_01';
  IF v_active<>0 OR v_paused<>18 THEN
    RAISE EXCEPTION 'P0-16 rollback member states active=% paused=%',v_active,v_paused;
  END IF;

  SELECT count(*) INTO v_ent_active
  FROM private.exam_prep_feature_entitlements e
  JOIN p016_people p ON p.user_id=e.user_id
  WHERE p.ord<=18 AND e.entitlement_status='active';
  IF v_ent_active<>0 THEN RAISE EXCEPTION 'P0-16 rollback left % active entitlements',v_ent_active; END IF;

  SELECT * INTO v_before FROM p016_preserve_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_evidence_events e JOIN p016_people p ON p.user_id=e.user_id WHERE p.ord<=18) evidence_n,
    (SELECT count(*) FROM private.exam_prep_skill_states s JOIN p016_people p ON p.user_id=s.user_id WHERE p.ord<=18) state_n
  INTO v_after;
  IF v_after.evidence_n<>v_before.evidence_n OR v_after.state_n<>v_before.state_n THEN
    RAISE EXCEPTION 'P0-16 rollback mutated evidence/state before=% after=%',row_to_json(v_before),row_to_json(v_after);
  END IF;
END
$$;

ROLLBACK;

-- Rollback proof: the ephemeral test left the persistent schema fail-closed and
-- no synthetic beta/user rows survived.
DO $$
DECLARE v_count int; v_cfg record;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'p016-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P0-16 rollback failed: synthetic auth users survived=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_cohorts;
  IF v_count<>0 THEN RAISE EXCEPTION 'P0-16 rollback failed: beta cohort rows survived=%',v_count; END IF;
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 rollback failed: config not fail-closed';
  END IF;
END
$$;

SELECT 'P0-16 controlled beta matrix: PASS (18 learners, 7/7/4, canary, full wave, monitoring, rollback)' AS result;