-- P1-06 expanded-beta readiness matrix.
-- Development acceleration: exercises the expanded service shape synthetically
-- without waiting for live learner time. All mutations are transaction-local and
-- end in ROLLBACK. This is not authorization to expand the real cohort.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p106.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P1-06 REFUSED: p106.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

DO $$
DECLARE
  v_program bigint;
  v_p1 int;
  v_p5 int;
  v_runway jsonb;
  v_cards int;
  v_generation boolean;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  IF v_program IS NULL THEN RAISE EXCEPTION 'P1-06 active program version missing'; END IF;

  SELECT count(*) FILTER (WHERE component_code='P1'),count(*) FILTER (WHERE component_code='P5')
  INTO v_p1,v_p5
  FROM private.exam_prep_syllabus_nodes WHERE program_version_id=v_program;
  IF v_p1<>45 OR v_p5<>36 THEN
    RAISE EXCEPTION 'P1-06 canonical denominator mismatch P1=% P5=%',v_p1,v_p5;
  END IF;

  v_runway:=public.get_exam_prep_content_runway_v1(1::smallint);
  IF coalesce((v_runway->>'hard_floor_green')::boolean,false) IS NOT TRUE
     OR coalesce((v_runway->>'target_4w_green')::boolean,false) IS NOT TRUE
     OR coalesce((v_runway#>>'{components,P1,ready_through_aw}')::int,0)<24
     OR coalesce((v_runway#>>'{components,P5,ready_through_aw}')::int,0)<24 THEN
    RAISE EXCEPTION 'P1-06 content runway not expansion-ready: %',v_runway;
  END IF;

  SELECT count(*) INTO v_cards FROM private.exam_prep_ai_source_cards
  WHERE approval_status='approved' AND is_runtime_allowed AND rights_status='original_iclub';
  SELECT generation_enabled INTO v_generation FROM private.exam_prep_ai_policy WHERE id=1;
  IF v_cards<>12 OR v_generation IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P1-06 dormant AI contract mismatch approved_cards=% generation=%',v_cards,v_generation;
  END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_legacy_reference_configs c
    WHERE c.source_type<>'legacy_readonly'
  ) THEN
    RAISE EXCEPTION 'P1-06 legacy adapter contains a non-readonly source';
  END IF;
END
$$;

CREATE TEMP TABLE p106_people(
  ord int PRIMARY KEY,
  user_id uuid NOT NULL UNIQUE,
  kind text NOT NULL CHECK(kind IN ('learner','mentor'))
) ON COMMIT DROP;

INSERT INTO p106_people(ord,user_id,kind)
SELECT g,gen_random_uuid(),CASE WHEN g<=18 THEN 'learner' ELSE 'mentor' END
FROM generate_series(1,22) g;

GRANT SELECT ON p106_people TO authenticated,service_role;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       format('p106-%s-%s@invalid.example',ord,replace(user_id::text,'-','')),
       now(),now(),false,false
FROM p106_people;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,CASE WHEN kind='learner' THEN 'P106 Learner' ELSE 'P106 Mentor' END,
       ord::text,'en',now(),false
FROM p106_people;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=true,mentor_enabled=true,kill_switch=false,updated_at=now()
WHERE id=1;

-- 7 Core-only + 7 Core+AI + 4 Mentor Care: the documented example service shape.
INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
)
SELECT user_id,'active',true,
       (ord BETWEEN 8 AND 14),
       (ord BETWEEN 15 AND 18),
       'p106-expanded',now()
FROM p106_people WHERE ord<=18;

INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT user_id,'mentor','active' FROM p106_people WHERE ord BETWEEN 19 AND 22;

INSERT INTO private.exam_prep_mentor_service_status(learner_user_id,service_status,status_reason)
SELECT user_id,'assigned_active','P1-06 isolated expanded-beta service-shape test'
FROM p106_people WHERE ord BETWEEN 15 AND 18;

INSERT INTO private.exam_prep_mentor_assignments(
  learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
)
SELECT l.user_id,m.user_id,CASE WHEN l.ord%2=0 THEN 'P5' ELSE 'P1' END,'active',now()
FROM p106_people l
JOIN p106_people m ON m.ord=l.ord+4
WHERE l.ord BETWEEN 15 AND 18;

DO $$
DECLARE r record; c record;
BEGIN
  FOR r IN SELECT ord,user_id FROM p106_people WHERE ord<=18 ORDER BY ord LOOP
    PERFORM set_config('request.jwt.claim.sub',r.user_id::text,true);
    PERFORM set_config('request.jwt.claim.role','authenticated',true);
    SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
    IF NOT c.core_access OR c.kill_switch OR c.rollout_state<>'controlled_beta' THEN
      RAISE EXCEPTION 'P1-06 learner % lost Core access: %',r.ord,row_to_json(c);
    END IF;
    IF (r.ord BETWEEN 8 AND 14) IS DISTINCT FROM c.ai_assist THEN
      RAISE EXCEPTION 'P1-06 learner % AI capability mismatch: %',r.ord,row_to_json(c);
    END IF;
    IF (r.ord BETWEEN 15 AND 18) IS DISTINCT FROM c.mentor_care_entitled THEN
      RAISE EXCEPTION 'P1-06 learner % Mentor entitlement mismatch: %',r.ord,row_to_json(c);
    END IF;
    IF (r.ord BETWEEN 15 AND 18) IS DISTINCT FROM c.mentor_assignment_active THEN
      RAISE EXCEPTION 'P1-06 learner % Mentor assignment mismatch: %',r.ord,row_to_json(c);
    END IF;
    IF (r.ord BETWEEN 15 AND 18) IS DISTINCT FROM c.mentor_authority THEN
      RAISE EXCEPTION 'P1-06 learner % Mentor authority mismatch: %',r.ord,row_to_json(c);
    END IF;
  END LOOP;
END
$$;

-- Recommendation metadata may exist for every learner; only the 4 assigned
-- Mentor Care learners are allowed to materialize routine human work.
INSERT INTO private.exam_prep_human_review_recommendations(
  learner_user_id,component_code,recommendation_type,source_object_type,source_object_id,recommendation_reason
)
SELECT user_id,CASE WHEN ord%2=0 THEN 'P5' ELSE 'P1' END,'readiness','p106_expanded',ord::text,
       'P1-06 synthetic recommendation used only to prove assignment-scoped Mentor Care queue isolation.'
FROM p106_people WHERE ord<=18;

DO $$
DECLARE v_total int; v_leaked int; v_distinct int;
BEGIN
  SELECT count(*) INTO v_total
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p106_expanded';
  IF v_total<>4 THEN RAISE EXCEPTION 'P1-06 expected exactly 4 mentor queue items, got %',v_total; END IF;

  SELECT count(*) INTO v_leaked
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  JOIN p106_people p ON p.user_id=q.learner_user_id
  WHERE r.source_object_type='p106_expanded' AND p.ord<15;
  IF v_leaked<>0 THEN RAISE EXCEPTION 'P1-06 queue leaked to % Core/AI-only learners',v_leaked; END IF;

  SELECT count(distinct q.mentor_user_id) INTO v_distinct
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p106_expanded';
  IF v_distinct<>4 THEN RAISE EXCEPTION 'P1-06 expected 4 mentor scopes, got %',v_distinct; END IF;
END
$$;

-- AI outage must remove only AI convenience, never Core or Mentor Care.
UPDATE private.exam_prep_feature_config SET ai_enabled=false,updated_at=now() WHERE id=1;
DO $$
DECLARE r record; c record;
BEGIN
  FOR r IN SELECT ord,user_id FROM p106_people WHERE ord<=18 LOOP
    PERFORM set_config('request.jwt.claim.sub',r.user_id::text,true);
    PERFORM set_config('request.jwt.claim.role','authenticated',true);
    SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
    IF NOT c.core_access OR c.ai_assist THEN
      RAISE EXCEPTION 'P1-06 AI outage damaged Core or left AI active learner=% payload=%',r.ord,row_to_json(c);
    END IF;
    IF (r.ord BETWEEN 15 AND 18) IS DISTINCT FROM c.mentor_authority THEN
      RAISE EXCEPTION 'P1-06 AI outage changed Mentor authority learner=% payload=%',r.ord,row_to_json(c);
    END IF;
  END LOOP;
END
$$;

-- Mentor outage must remove only human authority. Core stays available and the
-- seven AI learners recover when AI is re-enabled.
UPDATE private.exam_prep_feature_config SET ai_enabled=true,mentor_enabled=false,updated_at=now() WHERE id=1;
DO $$
DECLARE r record; c record;
BEGIN
  FOR r IN SELECT ord,user_id FROM p106_people WHERE ord<=18 LOOP
    PERFORM set_config('request.jwt.claim.sub',r.user_id::text,true);
    PERFORM set_config('request.jwt.claim.role','authenticated',true);
    SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
    IF NOT c.core_access OR c.mentor_assignment_active OR c.mentor_authority THEN
      RAISE EXCEPTION 'P1-06 mentor outage coupled to Core/authority learner=% payload=%',r.ord,row_to_json(c);
    END IF;
    IF (r.ord BETWEEN 8 AND 14) IS DISTINCT FROM c.ai_assist THEN
      RAISE EXCEPTION 'P1-06 mentor outage changed AI capability learner=% payload=%',r.ord,row_to_json(c);
    END IF;
  END LOOP;
END
$$;

-- Re-enable Mentor Care, then pause one assignment. The learner must retain Core
-- and entitlement while human authority disappears only for that component.
UPDATE private.exam_prep_feature_config SET mentor_enabled=true,updated_at=now() WHERE id=1;
UPDATE private.exam_prep_mentor_assignments
SET assignment_status='paused',updated_at=now()
WHERE learner_user_id=(SELECT user_id FROM p106_people WHERE ord=15)
  AND assignment_status='active';

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p106_people WHERE ord=15),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
DO $$
DECLARE c record;
BEGIN
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF NOT c.core_access OR NOT c.mentor_care_entitled OR c.mentor_assignment_active OR c.mentor_authority THEN
    RAISE EXCEPTION 'P1-06 mentor pause did not preserve Core/entitlement boundary: %',row_to_json(c);
  END IF;
END
$$;

-- No test may mutate academic or legacy learner history.
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM private.exam_prep_evidence_events e JOIN p106_people p ON p.user_id=e.user_id WHERE p.ord<=18;
  IF v_n<>0 THEN RAISE EXCEPTION 'P1-06 synthetic service transition created academic evidence rows=%',v_n; END IF;
  SELECT count(*) INTO v_n FROM private.exam_prep_skill_states s JOIN p106_people p ON p.user_id=s.user_id WHERE p.ord<=18;
  IF v_n<>0 THEN RAISE EXCEPTION 'P1-06 synthetic service transition created mastery/state rows=%',v_n; END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_count int; v_cfg record;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'p106-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-06 rollback failed synthetic users=%',v_count; END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_human_review_recommendations WHERE source_object_type='p106_expanded';
  IF v_count<>0 THEN RAISE EXCEPTION 'P1-06 rollback failed recommendations=%',v_count; END IF;
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P1-06 rollback failed feature boundary=%',row_to_json(v_cfg);
  END IF;
END
$$;

SELECT 'P1-06 expanded beta readiness matrix: PASS (7 Core + 7 AI + 4 Mentor, service outages isolated, no academic mutation)' AS result;
