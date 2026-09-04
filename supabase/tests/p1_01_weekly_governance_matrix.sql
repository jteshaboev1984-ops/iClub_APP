-- P1-01 weekly governance isolated acceptance matrix.
-- Requires: PGOPTIONS='-c p101.isolated_db=true'
-- Test-only; all synthetic mutations end in ROLLBACK.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p101.isolated_db',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P1-01 REFUSED: p101.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE v_cfg record; v_count int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P1-01 baseline not fail-closed';
  END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_cohorts;
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-01 baseline beta cohort rows=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_weekly_reviews;
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-01 baseline weekly review rows=%',v_count; END IF;
END
$$;

CREATE TEMP TABLE p101_people(
  ord integer PRIMARY KEY,
  user_id uuid NOT NULL UNIQUE,
  kind text NOT NULL CHECK(kind IN ('learner','mentor','reviewer'))
) ON COMMIT DROP;

INSERT INTO p101_people(ord,user_id,kind)
SELECT g,gen_random_uuid(),'learner' FROM generate_series(1,12) g
UNION ALL
SELECT 100+g,gen_random_uuid(),'mentor' FROM generate_series(1,4) g
UNION ALL
SELECT 200,gen_random_uuid(),'reviewer';

GRANT SELECT ON p101_people TO service_role;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       format('p101-%s-%s@invalid.example',ord,replace(user_id::text,'-','')),
       now(),now(),false,false
FROM p101_people;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,
       CASE kind WHEN 'learner' THEN 'P101 Learner' WHEN 'mentor' THEN 'P101 Mentor' ELSE 'P101 Reviewer' END,
       ord::text,'en',now(),false
FROM p101_people;

INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT user_id,'mentor','active' FROM p101_people WHERE ord BETWEEN 101 AND 104;
INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT user_id,'academic_moderator','active' FROM p101_people WHERE ord=200;

INSERT INTO private.exam_prep_mentor_service_status(learner_user_id,service_status,status_reason)
SELECT user_id,'assigned_active','P1-01 isolated weekly governance readiness'
FROM p101_people WHERE ord BETWEEN 9 AND 12;

INSERT INTO private.exam_prep_mentor_assignments(
  learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
)
SELECT l.user_id,m.user_id,CASE WHEN l.ord%2=0 THEN 'P5' ELSE 'P1' END,'active',now()
FROM p101_people l
JOIN p101_people m ON m.ord=92+l.ord
WHERE l.ord BETWEEN 9 AND 12;

SET LOCAL ROLE service_role;
SELECT public.stage_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_p101',12::smallint,'P1-01 isolated governance matrix'
);
SELECT public.set_exam_prep_beta_member_v1(
  'math_as_p1_p5_beta_p101',p.user_id,
  CASE WHEN p.ord<=4 THEN 'core' WHEN p.ord<=8 THEN 'ai_assist' ELSE 'mentor_care' END,
  CASE WHEN p.ord IN (1,2,5,6,9) THEN 1::smallint ELSE 2::smallint END
)
FROM p101_people p WHERE p.ord BETWEEN 1 AND 12 ORDER BY p.ord;
SELECT public.approve_exam_prep_controlled_beta_v1('math_as_p1_p5_beta_p101');

DO $$
BEGIN
  BEGIN
    PERFORM public.activate_exam_prep_controlled_beta_wave_v1('math_as_p1_p5_beta_p101',1::smallint);
    RAISE EXCEPTION 'P1-01 expected AI runtime readiness block did not occur';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%exam_prep_beta_ai_runtime_not_ready%' THEN RAISE; END IF;
  END;
END
$$;
RESET ROLE;

DO $$
DECLARE v_cfg record; v_active int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  SELECT count(*) INTO v_active FROM private.exam_prep_beta_members WHERE member_status='active';
  IF v_cfg.rollout_state<>'off' OR NOT v_cfg.kill_switch OR v_active<>0 THEN
    RAISE EXCEPTION 'P1-01 blocked AI activation changed state';
  END IF;
END
$$;

UPDATE private.exam_prep_optional_capability_status
SET runtime_status='ready',gate_version='p1-04-isolated-test',
    evidence=jsonb_build_object('test_only',true,'reason','exercise P1-01 governance after an explicit AI runtime gate'),
    updated_at=now()
WHERE capability_code='ai_assist';

SET LOCAL ROLE service_role;
SELECT public.activate_exam_prep_controlled_beta_wave_v1('math_as_p1_p5_beta_p101',1::smallint);
SELECT public.activate_exam_prep_controlled_beta_wave_v1('math_as_p1_p5_beta_p101',2::smallint);
RESET ROLE;

DO $$
DECLARE v_active int; v_cfg record;
BEGIN
  SELECT count(*) INTO v_active FROM private.exam_prep_beta_members WHERE member_status='active';
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_active<>12 OR v_cfg.rollout_state<>'controlled_beta' OR v_cfg.kill_switch
     OR NOT v_cfg.core_enabled OR NOT v_cfg.ai_enabled OR NOT v_cfg.mentor_enabled THEN
    RAISE EXCEPTION 'P1-01 full controlled beta activation mismatch active=% cfg=%',v_active,row_to_json(v_cfg);
  END IF;
END
$$;

SET LOCAL ROLE service_role;
CREATE TEMP TABLE p101_snapshot1 AS
SELECT public.get_exam_prep_beta_weekly_snapshot_v1('math_as_p1_p5_beta_p101',now()+interval '1 second') snapshot;
RESET ROLE;

DO $$
DECLARE v jsonb;
BEGIN
  SELECT snapshot INTO v FROM p101_snapshot1;
  IF v->>'decision'<>'NOT_DERIVED_BY_SYSTEM' THEN RAISE EXCEPTION 'P1-01 snapshot self-derived a decision: %',v; END IF;
  IF v->>'ai_runtime_status'<>'ready' THEN RAISE EXCEPTION 'P1-01 AI runtime status missing from snapshot: %',v; END IF;
  IF coalesce((v#>>'{hard_blockers,entitlement_mismatches}')::int,-1)<>0
     OR coalesce((v#>>'{hard_blockers,component_evidence_mismatches}')::int,-1)<>0
     OR coalesce((v#>>'{hard_blockers,queue_leakage}')::int,-1)<>0 THEN
    RAISE EXCEPTION 'P1-01 clean snapshot contains hard blockers: %',v;
  END IF;
END
$$;

SET LOCAL ROLE service_role;
CREATE TEMP TABLE p101_review1 AS
SELECT public.record_exam_prep_beta_weekly_review_v1(
  'math_as_p1_p5_beta_p101',1::smallint,now()+interval '2 seconds','continue',
  'green','green','green',
  'Week 1 isolated governance evidence is clean across active service modes.',
  'Core integrity, component firewall and continuity checks are green.',
  'AI runtime was explicitly promoted by the isolated readiness gate and fallback boundary is intact.',
  'Mentor assignments, queue isolation and safeguarding checks are green.',
  (SELECT user_id FROM p101_people WHERE ord=200)
) payload;
RESET ROLE;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_weekly_reviews;
  IF v_count<>1 THEN RAISE EXCEPTION 'P1-01 first weekly review not persisted'; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_weekly_service_reviews;
  IF v_count<>3 THEN RAISE EXCEPTION 'P1-01 service decisions not normalized count=%',v_count; END IF;
END
$$;

SET LOCAL ROLE service_role;
CREATE TEMP TABLE p101_incident AS
SELECT public.record_exam_prep_beta_ops_incident_v1(
  'math_as_p1_p5_beta_p101','technical','sev1','Synthetic beta integrity incident',
  'An isolated Sev1 incident is opened to prove that automatic metrics can veto but never manufacture a GREEN decision.',
  'core','P1',(SELECT user_id FROM p101_people WHERE ord=200)
) payload;

DO $$
BEGIN
  BEGIN
    PERFORM public.record_exam_prep_beta_weekly_review_v1(
      'math_as_p1_p5_beta_p101',2::smallint,now()+interval '3 seconds','continue',
      'green','green','green',
      'This deliberately invalid review should be rejected while Sev1 is open.',
      'Attempted false Core green while a hard blocker remains open.',
      'AI remains technically ready in the isolated test.',
      'Mentor integrity remains otherwise clean.',
      (SELECT user_id FROM p101_people WHERE ord=200)
    );
    RAISE EXCEPTION 'P1-01 expected false GREEN rejection did not occur';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%exam_prep_beta_false_green_core_blockers=%' THEN RAISE; END IF;
  END;
END
$$;

SELECT public.resolve_exam_prep_beta_ops_incident_v1(
  (SELECT (payload->>'incident_id')::uuid FROM p101_incident),
  'Synthetic Sev1 has been resolved after the hard-blocker rejection was verified.',
  (SELECT user_id FROM p101_people WHERE ord=200)
);

CREATE TEMP TABLE p101_review2 AS
SELECT public.record_exam_prep_beta_weekly_review_v1(
  'math_as_p1_p5_beta_p101',2::smallint,now()+interval '4 seconds','continue',
  'green','green','green',
  'Week 2 is recorded only after the explicit Sev1 blocker is resolved.',
  'Core hard blockers are now zero and deterministic continuity remains intact.',
  'AI runtime readiness remains explicitly gated and observable.',
  'Mentor Care assignment and queue isolation remain clean.',
  (SELECT user_id FROM p101_people WHERE ord=200)
) payload;
RESET ROLE;

SET LOCAL ROLE service_role;
SELECT public.pause_exam_prep_controlled_beta_service_v1(
  'math_as_p1_p5_beta_p101','ai_assist','Isolated optional-service rollback verification after weekly governance review.'
);
RESET ROLE;

DO $$
DECLARE v_core int; v_ai int; v_mentor int; v_cfg record; v_ai_ent int;
BEGIN
  SELECT count(*) filter(where member_status='active' and service_mode='core'),
         count(*) filter(where member_status='active' and service_mode='ai_assist'),
         count(*) filter(where member_status='active' and service_mode='mentor_care')
  INTO v_core,v_ai,v_mentor FROM private.exam_prep_beta_members;
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  SELECT count(*) INTO v_ai_ent
  FROM private.exam_prep_feature_entitlements e
  JOIN private.exam_prep_beta_members m ON m.user_id=e.user_id
  WHERE m.service_mode='ai_assist' AND e.entitlement_status='active';
  IF v_core<>4 OR v_ai<>0 OR v_mentor<>4 OR v_ai_ent<>0
     OR v_cfg.rollout_state<>'controlled_beta' OR v_cfg.kill_switch OR NOT v_cfg.core_enabled OR v_cfg.ai_enabled OR NOT v_cfg.mentor_enabled THEN
    RAISE EXCEPTION 'P1-01 optional AI pause leaked into Core/Mentor: core=% ai=% mentor=% ai_ent=% cfg=%',v_core,v_ai,v_mentor,v_ai_ent,row_to_json(v_cfg);
  END IF;
END
$$;

SET LOCAL ROLE service_role;
SELECT public.resume_exam_prep_controlled_beta_service_v1(
  'math_as_p1_p5_beta_p101','ai_assist',(SELECT (payload->>'review_id')::uuid FROM p101_review2)
);
RESET ROLE;

DO $$
DECLARE v_active int; v_cfg record;
BEGIN
  SELECT count(*) INTO v_active FROM private.exam_prep_beta_members WHERE member_status='active';
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_active<>12 OR NOT v_cfg.ai_enabled OR NOT v_cfg.core_enabled OR NOT v_cfg.mentor_enabled OR v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P1-01 optional AI resume failed active=% cfg=%',v_active,row_to_json(v_cfg);
  END IF;
END
$$;

CREATE TEMP TABLE p101_preserve_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_evidence_events e JOIN p101_people p ON p.user_id=e.user_id WHERE p.ord<=12) evidence_n,
  (SELECT count(*) FROM private.exam_prep_skill_states s JOIN p101_people p ON p.user_id=s.user_id WHERE p.ord<=12) state_n;

SET LOCAL ROLE service_role;
SELECT public.pause_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_p101','P1-01 isolated final global rollback verification'
);
RESET ROLE;

DO $$
DECLARE v_cfg record; v_active int; v_before record; v_after record;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  SELECT count(*) INTO v_active FROM private.exam_prep_beta_members WHERE member_status='active';
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch OR v_active<>0 THEN
    RAISE EXCEPTION 'P1-01 global rollback not fail-closed';
  END IF;
  SELECT * INTO v_before FROM p101_preserve_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_evidence_events e JOIN p101_people p ON p.user_id=e.user_id WHERE p.ord<=12) evidence_n,
    (SELECT count(*) FROM private.exam_prep_skill_states s JOIN p101_people p ON p.user_id=s.user_id WHERE p.ord<=12) state_n
  INTO v_after;
  IF v_after.evidence_n<>v_before.evidence_n OR v_after.state_n<>v_before.state_n THEN
    RAISE EXCEPTION 'P1-01 rollback mutated evidence/state before=% after=%',row_to_json(v_before),row_to_json(v_after);
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int; v_cfg record; v_ai_status text;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'p101-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-01 rollback failed: synthetic users survived=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_cohorts;
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-01 rollback failed: beta cohort rows survived=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_beta_weekly_reviews;
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-01 rollback failed: weekly review rows survived=%',v_count; END IF;
  SELECT runtime_status INTO v_ai_status FROM private.exam_prep_optional_capability_status WHERE capability_code='ai_assist';
  IF v_ai_status<>'not_deployed' THEN RAISE EXCEPTION 'P1-01 rollback failed: AI readiness test state survived=%',v_ai_status; END IF;
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P1-01 rollback failed: config not fail-closed';
  END IF;
END
$$;

SELECT 'P1-01 weekly governance matrix: PASS (12 learners, manual GREEN, false-GREEN veto, AI readiness gate, optional rollback/resume, global rollback)' AS result;
