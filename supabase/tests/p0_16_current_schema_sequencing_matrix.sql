-- P0-16 current-schema sequencing acceptance matrix.
-- Requires the full P0 -> P1-03 schema and PGOPTIONS='-c p016.current_schema=true'.
-- Test-only: every synthetic mutation is transaction-local and ends in ROLLBACK.
--
-- Purpose:
-- 1) prove a governed mixed cohort may be staged/approved while global access stays OFF;
-- 2) prove a Core-only first wave can run as deterministic controlled beta;
-- 3) prove an AI Assist wave is fail-closed until a later governed AI gate promotes runtime_status=ready;
-- 4) prove failed AI activation leaks no entitlement/config/member state;
-- 5) prove emergency pause returns the live Core canary to fail-closed state;
-- 6) prove no synthetic residue survives the matrix.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p016.current_schema',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P0-16 CURRENT-SCHEMA REFUSED: p016.current_schema=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE v_cfg record; v_count int; v_ai text;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 current-schema baseline not fail-closed: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_cohorts;
  IF v_count<>0 THEN RAISE EXCEPTION 'P0-16 current-schema beta cohort table not empty at baseline'; END IF;
  SELECT runtime_status INTO v_ai
  FROM private.exam_prep_optional_capability_status WHERE capability_code='ai_assist';
  IF coalesce(v_ai,'not_deployed')<>'not_deployed' THEN
    RAISE EXCEPTION 'P0-16 current-schema AI runtime baseline unexpectedly promoted: %',v_ai;
  END IF;
END
$$;

CREATE TEMP TABLE p016c_people(
  ord integer PRIMARY KEY,
  user_id uuid NOT NULL UNIQUE,
  kind text NOT NULL CHECK(kind IN ('learner','mentor'))
) ON COMMIT DROP;

INSERT INTO p016c_people(ord,user_id,kind)
SELECT g,gen_random_uuid(),'learner' FROM generate_series(1,12) g
UNION ALL
SELECT 101,gen_random_uuid(),'mentor';

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       format('p016c-%s-%s@invalid.example',ord,replace(user_id::text,'-','')),
       now(),now(),false,false
FROM p016c_people;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,
       CASE WHEN kind='learner' THEN 'P016C Learner' ELSE 'P016C Mentor' END,
       ord::text,'en',now(),false
FROM p016c_people;

-- Mentor readiness exists for the two future Mentor Care members, but those
-- members are intentionally not part of the Core canary wave.
INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT user_id,'mentor','active' FROM p016c_people WHERE ord=101;

INSERT INTO private.exam_prep_mentor_service_status(learner_user_id,service_status,status_reason)
SELECT user_id,'assigned_active','P0-16 current-schema isolated readiness'
FROM p016c_people WHERE ord IN (11,12);

INSERT INTO private.exam_prep_mentor_assignments(
  learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
)
SELECT l.user_id,m.user_id,
       CASE WHEN l.ord=11 THEN 'P1' ELSE 'P5' END,
       'active',now()
FROM p016c_people l
CROSS JOIN p016c_people m
WHERE l.ord IN (11,12) AND m.ord=101;

GRANT SELECT ON TABLE p016c_people TO service_role;

SET LOCAL ROLE service_role;
SELECT public.stage_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_current_01',12::smallint,
  'P0-16 current-schema sequencing: Core canary first, AI must remain fail-closed.'
);

-- 8 Core, 2 AI Assist, 2 Mentor Care. Wave 1 contains Core only; wave 2 contains
-- AI only; wave 3 contains the remaining Core + Mentor Care members.
SELECT public.set_exam_prep_beta_member_v1(
  'math_as_p1_p5_beta_current_01',p.user_id,
  CASE WHEN p.ord<=8 THEN 'core' WHEN p.ord<=10 THEN 'ai_assist' ELSE 'mentor_care' END,
  CASE WHEN p.ord<=4 THEN 1::smallint WHEN p.ord<=8 THEN 3::smallint WHEN p.ord<=10 THEN 2::smallint ELSE 3::smallint END
)
FROM p016c_people p WHERE p.ord BETWEEN 1 AND 12 ORDER BY p.ord;

SELECT public.approve_exam_prep_controlled_beta_v1('math_as_p1_p5_beta_current_01');
RESET ROLE;

-- Approval is allowlist/sign-off only. Nothing may be live before wave 1.
DO $$
DECLARE v_cfg record; v_mix record; v_active int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 current-schema approval enabled features: %',row_to_json(v_cfg);
  END IF;
  SELECT
    count(*) filter(where m.service_mode='core') core_n,
    count(*) filter(where m.service_mode='ai_assist') ai_n,
    count(*) filter(where m.service_mode='mentor_care') mentor_n,
    count(*) total_n
  INTO v_mix
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_current_01' AND m.member_status='approved';
  IF v_mix.total_n<>12 OR v_mix.core_n<>8 OR v_mix.ai_n<>2 OR v_mix.mentor_n<>2 THEN
    RAISE EXCEPTION 'P0-16 current-schema approved mix mismatch: %',row_to_json(v_mix);
  END IF;
  SELECT count(*) INTO v_active
  FROM private.exam_prep_feature_entitlements e
  JOIN p016c_people p ON p.user_id=e.user_id
  WHERE p.ord<=12 AND e.entitlement_status='active';
  IF v_active<>0 THEN RAISE EXCEPTION 'P0-16 current-schema approval leaked % active entitlements',v_active; END IF;
END
$$;

-- Wave 1 is deterministic Core only and must succeed on the current schema.
SET LOCAL ROLE service_role;
SELECT public.activate_exam_prep_controlled_beta_wave_v1('math_as_p1_p5_beta_current_01',1::smallint);
RESET ROLE;

DO $$
DECLARE v_cfg record; v_active int; v_waiting int; v_uid uuid; c record; v jsonb;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta' OR v_cfg.kill_switch OR NOT v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled THEN
    RAISE EXCEPTION 'P0-16 current-schema Core canary config mismatch: %',row_to_json(v_cfg);
  END IF;

  SELECT count(*) filter(where m.member_status='active'),count(*) filter(where m.member_status='approved')
  INTO v_active,v_waiting
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts b ON b.id=m.cohort_id
  WHERE b.cohort_key='math_as_p1_p5_beta_current_01';
  IF v_active<>4 OR v_waiting<>8 THEN
    RAISE EXCEPTION 'P0-16 current-schema Core canary counts mismatch active=% waiting=%',v_active,v_waiting;
  END IF;

  -- Core canary gets Core and nothing optional.
  SELECT user_id INTO v_uid FROM p016c_people WHERE ord=1;
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF NOT c.core_access OR c.ai_assist OR c.mentor_care_entitled OR c.mentor_authority THEN
    RAISE EXCEPTION 'P0-16 current-schema Core capability mismatch: %',row_to_json(c);
  END IF;

  -- Future AI member remains completely dark before its blocked wave.
  SELECT user_id INTO v_uid FROM p016c_people WHERE ord=9;
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF c.core_access OR c.ai_assist OR c.mentor_care_entitled OR c.mentor_authority THEN
    RAISE EXCEPTION 'P0-16 current-schema waiting AI learner leaked access: %',row_to_json(c);
  END IF;

  SELECT public.get_exam_prep_controlled_beta_monitor_v1('math_as_p1_p5_beta_current_01') INTO v;
  IF coalesce((v->>'runway_green')::boolean,false) IS NOT TRUE
     OR (v#>>'{member_counts,active}')::int<>4
     OR (v#>>'{active_service_mix,core}')::int<>4
     OR (v#>>'{active_service_mix,ai_assist}')::int<>0
     OR (v#>>'{active_service_mix,mentor_care}')::int<>0
     OR (v#>>'{integrity,entitlement_mismatches}')::int<>0
     OR (v#>>'{integrity,mentor_readiness_violations}')::int<>0
     OR (v#>>'{integrity,queue_leakage}')::int<>0 THEN
    RAISE EXCEPTION 'P0-16 current-schema Core canary monitor not green: %',v;
  END IF;
END
$$;

-- Wave 2 contains AI Assist members. P1-01 deliberately requires a later
-- governed AI runtime promotion; baseline runtime_status=not_deployed must block it.
SET LOCAL ROLE service_role;
DO $$
DECLARE v_expected boolean := false;
BEGIN
  BEGIN
    PERFORM public.activate_exam_prep_controlled_beta_wave_v1('math_as_p1_p5_beta_current_01',2::smallint);
  EXCEPTION WHEN OTHERS THEN
    IF position('exam_prep_beta_ai_runtime_not_ready' in SQLERRM)>0 THEN
      v_expected:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_expected THEN
    RAISE EXCEPTION 'P0-16 current-schema expected AI runtime gate did not fire';
  END IF;
END
$$;
RESET ROLE;

-- The rejected AI wave must be atomic: Core wave stays live, AI stays dark,
-- current_wave remains 1, and no AI entitlement/feature flag leaks.
DO $$
DECLARE v_cfg record; v_wave int; v_active int; v_ai_active int; v_ai_ent int; v_ai_status text;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta' OR v_cfg.kill_switch OR NOT v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled THEN
    RAISE EXCEPTION 'P0-16 current-schema AI rejection mutated config: %',row_to_json(v_cfg);
  END IF;

  SELECT c.current_wave INTO v_wave FROM private.exam_prep_beta_cohorts c WHERE c.cohort_key='math_as_p1_p5_beta_current_01';
  IF v_wave<>1 THEN RAISE EXCEPTION 'P0-16 current-schema failed AI wave advanced current_wave=%',v_wave; END IF;

  SELECT count(*) filter(where m.member_status='active'),
         count(*) filter(where m.member_status='active' and m.service_mode='ai_assist')
  INTO v_active,v_ai_active
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_current_01';
  IF v_active<>4 OR v_ai_active<>0 THEN
    RAISE EXCEPTION 'P0-16 current-schema failed AI wave leaked membership active=% ai=%',v_active,v_ai_active;
  END IF;

  SELECT count(*) INTO v_ai_ent
  FROM private.exam_prep_feature_entitlements e
  JOIN p016c_people p ON p.user_id=e.user_id
  WHERE p.ord IN (9,10) AND e.entitlement_status='active' AND e.ai_assist;
  IF v_ai_ent<>0 THEN RAISE EXCEPTION 'P0-16 current-schema failed AI wave leaked % AI entitlements',v_ai_ent; END IF;

  SELECT runtime_status INTO v_ai_status FROM private.exam_prep_optional_capability_status WHERE capability_code='ai_assist';
  IF coalesce(v_ai_status,'not_deployed')<>'not_deployed' THEN
    RAISE EXCEPTION 'P0-16 current-schema AI gate unexpectedly changed runtime_status=%',v_ai_status;
  END IF;
END
$$;

-- Emergency pause must fail-close the live Core canary without deleting evidence/state.
CREATE TEMP TABLE p016c_preserve_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_evidence_events e JOIN p016c_people p ON p.user_id=e.user_id WHERE p.ord<=12) evidence_n,
  (SELECT count(*) FROM private.exam_prep_skill_states s JOIN p016c_people p ON p.user_id=s.user_id WHERE p.ord<=12) state_n;

SET LOCAL ROLE service_role;
SELECT public.pause_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_current_01','P0-16 current-schema isolated emergency rollback verification'
);
RESET ROLE;

DO $$
DECLARE v_cfg record; v_active int; v_paused int; v_waiting int; v_ent int; v_status text; v_before record; v_after record;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 current-schema pause did not fail-close config: %',row_to_json(v_cfg);
  END IF;

  SELECT c.cohort_status INTO v_status FROM private.exam_prep_beta_cohorts c WHERE c.cohort_key='math_as_p1_p5_beta_current_01';
  IF v_status<>'paused' THEN RAISE EXCEPTION 'P0-16 current-schema cohort not paused: %',v_status; END IF;

  SELECT count(*) filter(where m.member_status='active'),
         count(*) filter(where m.member_status='paused'),
         count(*) filter(where m.member_status='approved')
  INTO v_active,v_paused,v_waiting
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_current_01';
  IF v_active<>0 OR v_paused<>4 OR v_waiting<>8 THEN
    RAISE EXCEPTION 'P0-16 current-schema pause member states active=% paused=% approved=%',v_active,v_paused,v_waiting;
  END IF;

  SELECT count(*) INTO v_ent
  FROM private.exam_prep_feature_entitlements e
  JOIN p016c_people p ON p.user_id=e.user_id
  WHERE p.ord<=12 AND e.entitlement_status='active';
  IF v_ent<>0 THEN RAISE EXCEPTION 'P0-16 current-schema pause left % active entitlements',v_ent; END IF;

  SELECT * INTO v_before FROM p016c_preserve_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_evidence_events e JOIN p016c_people p ON p.user_id=e.user_id WHERE p.ord<=12) evidence_n,
    (SELECT count(*) FROM private.exam_prep_skill_states s JOIN p016c_people p ON p.user_id=s.user_id WHERE p.ord<=12) state_n
  INTO v_after;
  IF v_after.evidence_n<>v_before.evidence_n OR v_after.state_n<>v_before.state_n THEN
    RAISE EXCEPTION 'P0-16 current-schema pause mutated evidence/state before=% after=%',row_to_json(v_before),row_to_json(v_after);
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_cfg record; v_count int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 current-schema post-rollback config not fail-closed: %',row_to_json(v_cfg);
  END IF;

  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'p016c-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P0-16 current-schema synthetic auth residue=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_cohorts WHERE cohort_key='math_as_p1_p5_beta_current_01';
  IF v_count<>0 THEN RAISE EXCEPTION 'P0-16 current-schema cohort residue=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_members m JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id WHERE c.cohort_key='math_as_p1_p5_beta_current_01';
  IF v_count<>0 THEN RAISE EXCEPTION 'P0-16 current-schema member residue=%',v_count; END IF;
END
$$;

SELECT 'P0-16 current-schema sequencing matrix: GREEN' AS result;
