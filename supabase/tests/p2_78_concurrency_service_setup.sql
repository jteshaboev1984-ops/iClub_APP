-- P2-78 scale-shaped concurrency/service-transition fixture.
-- ISOLATED CI ONLY. This intentionally persists inside the disposable database
-- until p2_78_concurrency_service_cleanup.sql runs; it must never run on production.
\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p278.isolated_db',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-78 REFUSED: p278.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM private.exam_prep_synthetic_validation_runs WHERE run_id='SV-P278-CONCURRENCY') THEN
    RAISE EXCEPTION 'P2-78 fixture run already exists';
  END IF;
END
$$;

SELECT private.register_exam_prep_synthetic_validation_run_v1(
  'SV-P278-CONCURRENCY',
  'p278-600x10-concurrency-v1',
  :'p278_git_sha',
  'p2-78',
  27801,
  'mentor_technical',
  'P2-78 isolated 600 learner / 10 mentor concurrency and service-transition validation'
);

SELECT private.transition_exam_prep_synthetic_validation_run_v1(
  'SV-P278-CONCURRENCY','registered','running',null,null,
  jsonb_build_object('p2_78','fixture-start','learners',600,'mentors',10)
);

-- Dedicated run-owned identities only. No real account is reused or cloned.
DO $$
DECLARE
  i int;
BEGIN
  FOR i IN 1..600 LOOP
    PERFORM private.create_exam_prep_synthetic_identity_v1(
      'SV-P278-CONCURRENCY','learner',
      'SVF-P278-L'||lpad(i::text,4,'0'),
      'p2-78-concurrency-learner-'||i,
      'P2-78 scale-shaped synthetic learner '||i,
      CASE i%3 WHEN 1 THEN 'en' WHEN 2 THEN 'ru' ELSE 'uz' END
    );
  END LOOP;
  FOR i IN 1..10 LOOP
    PERFORM private.create_exam_prep_synthetic_identity_v1(
      'SV-P278-CONCURRENCY','mentor',
      'SVF-P278-M'||lpad(i::text,2,'0'),
      'p2-78-concurrency-mentor-'||i,
      'P2-78 scale-shaped synthetic mentor '||i,
      'en'
    );
  END LOOP;
END
$$;

-- Synthetic evidence is governed by the P2-68 academic-time firewall. The
-- clock can be initialized only after the run owns at least one active identity.
SELECT private.initialize_exam_prep_synthetic_clock_v1(
  'SV-P278-CONCURRENCY','P2-78 isolated concurrency academic clock'
);

-- Enable optional layers only in this disposable database. Provider generation
-- remains disabled; P2-78 makes zero paid AI calls.
UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=true,mentor_enabled=true,kill_switch=false,updated_at=now()
WHERE id=1;
UPDATE private.exam_prep_ai_policy SET generation_enabled=false,updated_at=now() WHERE id=1;
UPDATE private.exam_prep_optional_capability_status
SET runtime_status='shadow',gate_version=null,updated_at=now()
WHERE capability_code='ai_assist';

-- All 600 retain Core. Learners 301..600 are AI-entitled to exercise global AI
-- transitions. Only learners 1..30 are Mentor-entitled; exactly 1..10 are assigned.
WITH learners AS (
  SELECT s.user_id,(substring(s.fixture_profile_key from 'L([0-9]{4})$'))::int AS ord
  FROM private.exam_prep_synthetic_identities s
  WHERE s.run_id='SV-P278-CONCURRENCY' AND s.identity_kind='learner'
)
INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
)
SELECT user_id,'active',true,(ord>=301),(ord<=30),null,now()-interval '1 minute'
FROM learners;

WITH learners AS (
  SELECT s.user_id,(substring(s.fixture_profile_key from 'L([0-9]{4})$'))::int AS ord
  FROM private.exam_prep_synthetic_identities s
  WHERE s.run_id='SV-P278-CONCURRENCY' AND s.identity_kind='learner'
)
INSERT INTO private.exam_prep_mentor_service_status(learner_user_id,service_status,status_reason)
SELECT user_id,CASE WHEN ord<=10 THEN 'assigned_active' ELSE 'entitled_waitlist' END,
       'P2-78 isolated 600/10 service fixture'
FROM learners WHERE ord<=30;

-- Ten governed synthetic mentors; mentor 10 also acts as mentor_ops for pause/handover.
INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT s.user_id,'mentor','active'
FROM private.exam_prep_synthetic_identities s
WHERE s.run_id='SV-P278-CONCURRENCY' AND s.identity_kind='mentor';
INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT s.user_id,'mentor_ops','active'
FROM private.exam_prep_synthetic_identities s
WHERE s.run_id='SV-P278-CONCURRENCY' AND s.fixture_profile_key='SVF-P278-M10';

-- Seed real deterministic academic history for twelve learners before service
-- transitions. This gives P2-78 non-zero evidence/mastery/stage history to prove
-- that service changes preserve academic truth.
CREATE OR REPLACE FUNCTION pg_temp.p278_seed_learning_evidence_v1(
  p_user_id uuid,
  p_program_version_id bigint,
  p_component text,
  p_tag text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_assessment_id bigint;
  v_content_version_id bigint;
  v_assessment_version text;
  v_question_id bigint;
  v_skill_code text;
  v_reserve_role text;
  v_content_meta_id bigint;
  v_question_snapshot_md5 text;
  v_auth_id uuid;
  v_session_id uuid:=gen_random_uuid();
  v_response_id uuid;
BEGIN
  SELECT a.id,a.content_version_id,a.assessment_version,
         ai.question_id,ai.primary_skill_code,ai.reserve_role,
         m.id,m.question_snapshot_md5
  INTO v_assessment_id,v_content_version_id,v_assessment_version,
       v_question_id,v_skill_code,v_reserve_role,
       v_content_meta_id,v_question_snapshot_md5
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
  JOIN private.exam_prep_question_content_meta m
    ON m.content_version_id=a.content_version_id AND m.question_id=ai.question_id
  WHERE a.component_code=p_component
    AND a.assessment_type='learning'
    AND a.status='published'
    AND ai.question_id IS NOT NULL
    AND coalesce(ai.is_holdout,false)=false
  ORDER BY a.id,ai.item_order
  LIMIT 1;

  IF v_assessment_id IS NULL THEN
    RAISE EXCEPTION 'P2-78 governed learning fixture missing component=%',p_component;
  END IF;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(
    p_user_id,v_assessment_id,p_component,'learning','issued',clock_timestamp()+interval '1 hour',
    'P2-78 isolated academic-history preservation fixture',true
  ) RETURNING id INTO v_auth_id;

  INSERT INTO private.exam_prep_sessions(
    id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
    assessment_version,component_code,session_type,status,client_idempotency_key,total_items
  ) VALUES(
    v_session_id,v_auth_id,p_user_id,p_program_version_id,v_content_version_id,v_assessment_id,
    v_assessment_version,p_component,'learning','active','p278-'||p_tag||'-session',1
  );

  INSERT INTO private.exam_prep_session_items(
    session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,
    is_holdout,content_meta_id,question_snapshot_md5,item_version
  ) VALUES(
    v_session_id,1,'question',v_question_id,v_skill_code,v_reserve_role,
    false,v_content_meta_id,v_question_snapshot_md5,v_assessment_version||'|p278|'||p_tag
  );

  INSERT INTO private.exam_prep_responses(
    session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
    is_correct,evaluator_version,elapsed_ms
  ) VALUES(
    v_session_id,1,p_user_id,'p278-'||p_tag||'-response','machine',
    'synthetic-correct',true,'p278_fixture_v1',1000
  ) RETURNING id INTO v_response_id;

  INSERT INTO private.exam_prep_evidence_events(
    user_id,component_code,skill_code,session_id,response_id,evidence_type,
    verification_status,is_correct,evidence_payload,source_version
  ) VALUES(
    p_user_id,p_component,v_skill_code,v_session_id,v_response_id,'learning',
    'app_verified',true,
    jsonb_build_object('p2_78','history-preservation','tag',p_tag,'component',p_component),
    v_assessment_version||'|p278'
  );

  UPDATE private.exam_prep_sessions
  SET status='finalized',finalized_at=clock_timestamp(),last_activity_at=clock_timestamp(),
      finalize_idempotency_key='p278-'||p_tag||'-final'
  WHERE id=v_session_id;
END
$$;

DO $$
DECLARE
  v_program bigint;
  r record;
BEGIN
  SELECT id INTO v_program
  FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  IF v_program IS NULL THEN RAISE EXCEPTION 'P2-78 canonical program missing'; END IF;

  FOR r IN
    SELECT s.user_id,(substring(s.fixture_profile_key from 'L([0-9]{4})$'))::int AS ord
    FROM private.exam_prep_synthetic_identities s
    WHERE s.run_id='SV-P278-CONCURRENCY'
      AND s.fixture_profile_key IN (
        'SVF-P278-L0001','SVF-P278-L0002','SVF-P278-L0003','SVF-P278-L0004',
        'SVF-P278-L0301','SVF-P278-L0302','SVF-P278-L0303','SVF-P278-L0304',
        'SVF-P278-L0591','SVF-P278-L0592','SVF-P278-L0599','SVF-P278-L0600'
      )
    ORDER BY s.fixture_profile_key
  LOOP
    PERFORM set_config('request.jwt.claim.sub',r.user_id::text,true);
    PERFORM set_config('request.jwt.claim.role','authenticated',true);
    PERFORM public.save_exam_prep_exam_profile_v2('CI_P278_CONCURRENCY','A',12,6);
    PERFORM pg_temp.p278_seed_learning_evidence_v1(r.user_id,v_program,'P1','l'||r.ord||'-p1');
    PERFORM pg_temp.p278_seed_learning_evidence_v1(r.user_id,v_program,'P5','l'||r.ord||'-p5');
    PERFORM private.rebuild_exam_prep_placement_v1(r.user_id,'P1');
    PERFORM private.rebuild_exam_prep_placement_v1(r.user_id,'P5');
    PERFORM private.rebuild_exam_prep_state_v1(r.user_id,'P1');
    PERFORM private.rebuild_exam_prep_state_v1(r.user_id,'P5');
  END LOOP;
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claim.role','',true);
END
$$;

-- Exactly ten active assignments, one learner per synthetic mentor, alternating P1/P5.
WITH learners AS (
  SELECT s.user_id,(substring(s.fixture_profile_key from 'L([0-9]{4})$'))::int AS ord
  FROM private.exam_prep_synthetic_identities s
  WHERE s.run_id='SV-P278-CONCURRENCY' AND s.identity_kind='learner'
), mentors AS (
  SELECT s.user_id,(substring(s.fixture_profile_key from 'M([0-9]{2})$'))::int AS ord
  FROM private.exam_prep_synthetic_identities s
  WHERE s.run_id='SV-P278-CONCURRENCY' AND s.identity_kind='mentor'
)
INSERT INTO private.exam_prep_mentor_assignments(
  learner_user_id,mentor_user_id,component_code,assignment_status,valid_from
)
SELECT l.user_id,m.user_id,CASE WHEN l.ord%2=0 THEN 'P5' ELSE 'P1' END,'active',now()-interval '1 minute'
FROM learners l JOIN mentors m USING(ord)
WHERE l.ord<=10;

-- Recommendation metadata for every learner. The queue trigger must materialize
-- routine human work only for the ten active assignments.
WITH learners AS (
  SELECT s.user_id,(substring(s.fixture_profile_key from 'L([0-9]{4})$'))::int AS ord
  FROM private.exam_prep_synthetic_identities s
  WHERE s.run_id='SV-P278-CONCURRENCY' AND s.identity_kind='learner'
)
INSERT INTO private.exam_prep_human_review_recommendations(
  learner_user_id,component_code,recommendation_type,source_object_type,source_object_id,recommendation_reason
)
SELECT user_id,CASE WHEN ord%2=0 THEN 'P5' ELSE 'P1' END,'readiness','p278_scale',ord::text,
       'P2-78 synthetic scale recommendation; queue work is assignment-scoped only.'
FROM learners;

DO $$
DECLARE
  v_learners int;
  v_mentors int;
  v_assignments int;
  v_queue int;
  v_unassigned_queue int;
  v_actor_count int;
  v_role_grants int;
  v_iso jsonb;
  v_history int;
BEGIN
  SELECT count(*) FILTER(WHERE identity_kind='learner'),count(*) FILTER(WHERE identity_kind='mentor')
  INTO v_learners,v_mentors
  FROM private.exam_prep_synthetic_identities WHERE run_id='SV-P278-CONCURRENCY';
  SELECT count(*) INTO v_assignments
  FROM private.exam_prep_mentor_assignments a
  JOIN private.exam_prep_synthetic_identities l ON l.user_id=a.learner_user_id
  WHERE l.run_id='SV-P278-CONCURRENCY' AND a.assignment_status='active';
  SELECT count(*) INTO v_queue
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p278_scale';
  SELECT count(*) INTO v_unassigned_queue
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  JOIN private.exam_prep_synthetic_identities l ON l.user_id=q.learner_user_id
  WHERE r.source_object_type='p278_scale'
    AND (substring(l.fixture_profile_key from 'L([0-9]{4})$'))::int>10;
  SELECT count(*) INTO v_history
  FROM private.exam_prep_evidence_events e
  JOIN private.exam_prep_synthetic_identities s ON s.user_id=e.user_id
  WHERE s.run_id='SV-P278-CONCURRENCY';
  v_iso:=private.exam_prep_synthetic_identity_isolation_report_v1();
  v_actor_count:=coalesce((v_iso->>'synthetic_staff_actor_count')::int,-1);
  v_role_grants:=coalesce((v_iso->>'synthetic_staff_role_grants')::int,-1);

  IF v_learners<>600 OR v_mentors<>10 OR v_assignments<>10 OR v_queue<>10 OR v_unassigned_queue<>0 THEN
    RAISE EXCEPTION 'P2-78 fixture cardinality failed learners=% mentors=% assignments=% queue=% unassigned_queue=%',
      v_learners,v_mentors,v_assignments,v_queue,v_unassigned_queue;
  END IF;
  IF v_actor_count<>10 OR v_role_grants<>11 OR coalesce((v_iso->>'eligible')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-78 synthetic staff isolation failed: %',v_iso;
  END IF;
  IF v_history<>24 THEN
    RAISE EXCEPTION 'P2-78 expected 24 non-zero academic evidence rows, got %',v_history;
  END IF;
END
$$;

COMMIT;

\echo 'P2-78 fixture ready: 600 learners / 10 mentors / 10 active human scopes / 24 academic evidence rows'