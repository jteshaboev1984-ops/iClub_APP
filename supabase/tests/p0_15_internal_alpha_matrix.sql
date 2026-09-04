-- P0-15 Internal Alpha / Security / Integrity / Rollback Drill
-- SAFE-BY-DESIGN: this file refuses to run unless the caller explicitly marks
-- the current database connection as isolated with:
--   PGOPTIONS='-c p015.isolated_db=true'
-- It must never be run against the production database.
--
-- The entire behavioral drill runs inside one transaction and ends with ROLLBACK.
-- No synthetic users, entitlements, assignments, queues, recommendations or
-- feature-config changes are allowed to survive the test.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p015.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P0-15 REFUSED: p015.isolated_db=true is required. Use only a disposable/local/dev database.';
  END IF;
END
$$;

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Structural / security preflight
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_tables
  WHERE schemaname='private' AND tablename LIKE 'exam_prep%' AND NOT rowsecurity;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'P0-15 preflight: % Exam Prep private tables do not have RLS', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM information_schema.role_table_grants
  WHERE table_schema='private'
    AND table_name LIKE 'exam_prep%'
    AND grantee='authenticated'
    AND privilege_type IN ('INSERT','UPDATE','DELETE','TRUNCATE');
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'P0-15 preflight: authenticated has % direct write grants on private Exam Prep tables', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname LIKE '%exam_prep%'
    AND has_function_privilege('anon', p.oid, 'EXECUTE');
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'P0-15 preflight: anon can execute % public Exam Prep functions', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname='public'
    AND p.proname LIKE '%exam_prep%'
    AND p.prosecdef
    AND NOT ('search_path=""' = ANY(coalesce(p.proconfig, ARRAY[]::text[])));
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'P0-15 preflight: % SECURITY DEFINER Exam Prep functions lack fixed empty search_path', v_count;
  END IF;
END
$$;

-- Keep a legacy-history baseline. Synthetic auth/profile rows are intentionally
-- excluded because the drill needs FK-safe disposable users.
CREATE TEMP TABLE p015_legacy_baseline AS
SELECT 'questions'::text object_name, count(*)::bigint row_count FROM public.questions
UNION ALL SELECT 'practice_attempts', count(*) FROM public.practice_attempts
UNION ALL SELECT 'practice_answers', count(*) FROM public.practice_answers
UNION ALL SELECT 'tour_attempts', count(*) FROM public.tour_attempts
UNION ALL SELECT 'tour_answers', count(*) FROM public.tour_answers
UNION ALL SELECT 'ratings_cache', count(*) FROM public.ratings_cache
UNION ALL SELECT 'certificates', count(*) FROM public.certificates;

-- ---------------------------------------------------------------------------
-- 1. Synthetic identities: 600 learners + 10 mentors, transaction-local
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE p015_people (
  ord integer PRIMARY KEY,
  user_id uuid NOT NULL UNIQUE,
  kind text NOT NULL CHECK (kind IN ('learner','mentor'))
) ON COMMIT DROP;

INSERT INTO p015_people(ord,user_id,kind)
SELECT g, gen_random_uuid(), CASE WHEN g <= 600 THEN 'learner' ELSE 'mentor' END
FROM generate_series(1,610) g;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT p.user_id,
       'authenticated',
       'authenticated',
       format('p015-%s-%s@invalid.example',p.ord,replace(p.user_id::text,'-','')),
       now(),now(),false,false
FROM p015_people p;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT p.user_id,
       CASE WHEN p.kind='learner' THEN 'P015 Learner' ELSE 'P015 Mentor' END,
       p.ord::text,
       'en',now(),false
FROM p015_people p;

-- ---------------------------------------------------------------------------
-- 2. Enable INTERNAL_ALPHA inside the disposable transaction only
-- ---------------------------------------------------------------------------
UPDATE private.exam_prep_feature_config
SET rollout_state='internal_alpha',
    core_enabled=true,
    ai_enabled=true,
    mentor_enabled=true,
    kill_switch=false,
    updated_at=now()
WHERE id=1;

-- Expected capability matrix for learner profiles 1..15.
CREATE TEMP TABLE p015_expected (
  ord integer PRIMARY KEY,
  e_core boolean NOT NULL,
  e_ai boolean NOT NULL,
  e_mentor boolean NOT NULL,
  e_assignment boolean NOT NULL
) ON COMMIT DROP;

INSERT INTO p015_expected VALUES
  (1,false,false,false,false), -- no entitlement
  (2,false,false,false,false), -- disabled entitlement
  (3,true, false,false,false), -- Core only
  (4,true, true, false,false), -- Core + AI
  (5,true, false,true, false), -- Mentor entitled, no service/assignment
  (6,true, false,true, false), -- assigned service, no assignment
  (7,true, false,true, true ), -- valid Mentor Care path
  (8,true, false,true, false), -- assignment to non-staff mentor
  (9,true, false,true, false), -- paused assignment
  (10,true,false,true, false), -- paused service
  (11,true,true, true, true ), -- full Core + AI + Mentor
  (12,false,false,false,false), -- revoked
  (13,false,false,false,false), -- future entitlement
  (14,false,false,false,false), -- expired entitlement
  (15,false,false,false,false); -- flags without Core access

INSERT INTO private.exam_prep_feature_entitlements
  (user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from,valid_until)
SELECT p.user_id,
       x.entitlement_status,
       x.core_access,
       x.ai_assist,
       x.mentor_care_entitled,
       'p015-matrix',
       x.valid_from,
       x.valid_until
FROM p015_people p
JOIN (VALUES
  (2,'disabled',true, true, true,  now(),                    NULL::timestamptz),
  (3,'active',  true, false,false, now(),                    NULL::timestamptz),
  (4,'active',  true, true, false, now(),                    NULL::timestamptz),
  (5,'active',  true, false,true,  now(),                    NULL::timestamptz),
  (6,'active',  true, false,true,  now(),                    NULL::timestamptz),
  (7,'active',  true, false,true,  now(),                    NULL::timestamptz),
  (8,'active',  true, false,true,  now(),                    NULL::timestamptz),
  (9,'active',  true, false,true,  now(),                    NULL::timestamptz),
  (10,'active', true, false,true,  now(),                    NULL::timestamptz),
  (11,'active', true, true, true,  now(),                    NULL::timestamptz),
  (12,'revoked',true, true, true,  now(),                    NULL::timestamptz),
  (13,'active', true, false,false, now()+interval '1 day',   NULL::timestamptz),
  (14,'active', true, false,false, now()-interval '2 days',  now()-interval '1 day'),
  (15,'active', false,true, true,  now(),                    NULL::timestamptz)
) AS x(ord,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from,valid_until)
  ON x.ord=p.ord;

INSERT INTO private.exam_prep_mentor_service_status(learner_user_id,service_status,status_reason)
SELECT p.user_id,x.service_status,'p015-matrix'
FROM p015_people p
JOIN (VALUES
  (6,'assigned_active'),
  (7,'assigned_active'),
  (8,'assigned_active'),
  (9,'assigned_active'),
  (10,'assigned_paused'),
  (11,'assigned_active')
) AS x(ord,service_status) ON x.ord=p.ord;

-- Mentors 601 and 603 are valid staff; 602 intentionally is not.
INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status)
SELECT user_id,'mentor','active' FROM p015_people WHERE ord IN (601,603);

INSERT INTO private.exam_prep_mentor_assignments(learner_user_id,mentor_user_id,component_code,assignment_status)
SELECT l.user_id,m.user_id,x.component_code,x.assignment_status
FROM (VALUES
  (7,601,'P1','active'),
  (8,602,'P5','active'),
  (9,601,'P1','paused'),
  (10,603,'P1','active'),
  (11,601,'P1','active')
) AS x(learner_ord,mentor_ord,component_code,assignment_status)
JOIN p015_people l ON l.ord=x.learner_ord
JOIN p015_people m ON m.ord=x.mentor_ord;

-- ---------------------------------------------------------------------------
-- 3. 15-profile capability matrix
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  r record;
  c record;
BEGIN
  FOR r IN
    SELECT e.*,p.user_id FROM p015_expected e JOIN p015_people p USING(ord) ORDER BY e.ord
  LOOP
    PERFORM set_config('request.jwt.claim.sub',r.user_id::text,true);
    PERFORM set_config('request.jwt.claim.role','authenticated',true);
    SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();

    IF c.rollout_state <> 'internal_alpha'
       OR c.kill_switch
       OR c.core_access IS DISTINCT FROM r.e_core
       OR c.ai_assist IS DISTINCT FROM r.e_ai
       OR c.mentor_care_entitled IS DISTINCT FROM r.e_mentor
       OR c.mentor_assignment_active IS DISTINCT FROM r.e_assignment
       OR c.mentor_authority IS DISTINCT FROM r.e_assignment THEN
      RAISE EXCEPTION 'P0-15 profile % failed: got %, expected core=% ai=% mentor=% assignment=%',
        r.ord,row_to_json(c),r.e_core,r.e_ai,r.e_mentor,r.e_assignment;
    END IF;
  END LOOP;
END
$$;

-- ---------------------------------------------------------------------------
-- 4. Kill-switch, downgrade, AI outage, mentor absence
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_uid uuid;
  c record;
  v_evidence_before bigint;
  v_evidence_after bigint;
  v_state_before bigint;
  v_state_after bigint;
BEGIN
  -- Fully entitled profile 11 must fail closed under kill switch.
  SELECT user_id INTO v_uid FROM p015_people WHERE ord=11;
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  UPDATE private.exam_prep_feature_config SET kill_switch=true WHERE id=1;
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF c.core_access OR c.ai_assist OR c.mentor_care_entitled OR c.mentor_assignment_active OR c.mentor_authority OR NOT c.kill_switch THEN
    RAISE EXCEPTION 'P0-15 kill-switch override failed: %',row_to_json(c);
  END IF;

  -- Re-enable alpha, then downgrade profile 11. Existing evidence/state must not be deleted.
  UPDATE private.exam_prep_feature_config SET kill_switch=false WHERE id=1;
  SELECT count(*) INTO v_evidence_before FROM private.exam_prep_evidence_events WHERE user_id=v_uid;
  SELECT count(*) INTO v_state_before FROM private.exam_prep_skill_states WHERE user_id=v_uid;
  UPDATE private.exam_prep_feature_entitlements SET entitlement_status='paused' WHERE user_id=v_uid;
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF c.core_access OR c.ai_assist OR c.mentor_care_entitled OR c.mentor_assignment_active OR c.mentor_authority OR c.kill_switch THEN
    RAISE EXCEPTION 'P0-15 downgrade failed: %',row_to_json(c);
  END IF;
  SELECT count(*) INTO v_evidence_after FROM private.exam_prep_evidence_events WHERE user_id=v_uid;
  SELECT count(*) INTO v_state_after FROM private.exam_prep_skill_states WHERE user_id=v_uid;
  IF v_evidence_after<>v_evidence_before OR v_state_after<>v_state_before THEN
    RAISE EXCEPTION 'P0-15 downgrade mutated evidence/state';
  END IF;

  -- AI outage: Core remains available and the AI toggle must not mutate evidence/state.
  SELECT user_id INTO v_uid FROM p015_people WHERE ord=4;
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  SELECT count(*) INTO v_evidence_before FROM private.exam_prep_evidence_events WHERE user_id=v_uid;
  SELECT count(*) INTO v_state_before FROM private.exam_prep_skill_states WHERE user_id=v_uid;
  UPDATE private.exam_prep_feature_config SET ai_enabled=false WHERE id=1;
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF NOT c.core_access OR c.ai_assist THEN
    RAISE EXCEPTION 'P0-15 AI outage coupled to Core: %',row_to_json(c);
  END IF;
  SELECT count(*) INTO v_evidence_after FROM private.exam_prep_evidence_events WHERE user_id=v_uid;
  SELECT count(*) INTO v_state_after FROM private.exam_prep_skill_states WHERE user_id=v_uid;
  IF v_evidence_after<>v_evidence_before OR v_state_after<>v_state_before THEN
    RAISE EXCEPTION 'P0-15 AI outage mutated evidence/state';
  END IF;

  -- Mentor absence: Core remains available while mentor authority disappears.
  SELECT user_id INTO v_uid FROM p015_people WHERE ord=7;
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  UPDATE private.exam_prep_mentor_assignments
     SET assignment_status='paused',updated_at=now()
   WHERE learner_user_id=v_uid AND component_code='P1' AND assignment_status='active';
  SELECT * INTO c FROM public.get_exam_prep_capabilities_v1();
  IF NOT c.core_access OR NOT c.mentor_care_entitled OR c.mentor_assignment_active OR c.mentor_authority THEN
    RAISE EXCEPTION 'P0-15 mentor absence coupled to Core or leaked authority: %',row_to_json(c);
  END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- 5. 600 learners / 10 mentors queue-isolation drill
-- ---------------------------------------------------------------------------
-- Close any profile-specific active assignments first.
UPDATE private.exam_prep_mentor_assignments
SET assignment_status='ended',updated_at=now()
WHERE learner_user_id IN (SELECT user_id FROM p015_people WHERE ord<=600)
  AND assignment_status='active';

-- Normalize all 600 learners to Core + Mentor entitlement; AI deliberately off.
INSERT INTO private.exam_prep_feature_entitlements
  (user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from,valid_until,updated_at)
SELECT user_id,'active',true,false,true,'p015-scale',now(),NULL,now()
FROM p015_people WHERE ord<=600
ON CONFLICT(user_id) DO UPDATE SET
  entitlement_status='active',core_access=true,ai_assist=false,mentor_care_entitled=true,
  cohort_key='p015-scale',valid_from=now(),valid_until=NULL,updated_at=now();

INSERT INTO private.exam_prep_mentor_service_status
  (learner_user_id,service_status,status_reason,status_changed_at,updated_at)
SELECT user_id,
       CASE WHEN ord<=10 THEN 'assigned_active' ELSE 'entitled_waitlist' END,
       'p015-scale',now(),now()
FROM p015_people WHERE ord<=600
ON CONFLICT(learner_user_id) DO UPDATE SET
  service_status=excluded.service_status,status_reason=excluded.status_reason,
  status_changed_at=now(),updated_at=now();

-- All ten mentors are operationally active for the scale test.
INSERT INTO private.exam_prep_staff_roles(user_id,role_code,role_status,updated_at)
SELECT user_id,'mentor','active',now() FROM p015_people WHERE ord BETWEEN 601 AND 610
ON CONFLICT(user_id,role_code) DO UPDATE SET role_status='active',updated_at=now();

-- Exactly ten learners receive an operational assignment, one per mentor.
INSERT INTO private.exam_prep_mentor_assignments
  (learner_user_id,mentor_user_id,component_code,assignment_status,valid_from)
SELECT l.user_id,m.user_id,CASE WHEN l.ord%2=0 THEN 'P5' ELSE 'P1' END,'active',now()
FROM p015_people l
JOIN p015_people m ON m.ord=600+l.ord
WHERE l.ord BETWEEN 1 AND 10;

-- Every learner gets recommendation metadata. Queue work must materialize only
-- for the ten truly assigned learners.
INSERT INTO private.exam_prep_human_review_recommendations
  (learner_user_id,component_code,recommendation_type,source_object_type,source_object_id,recommendation_reason)
SELECT user_id,
       CASE WHEN ord%2=0 THEN 'P5' ELSE 'P1' END,
       'readiness',
       'p015_scale',
       ord::text,
       'P0-15 synthetic readiness recommendation for queue-isolation testing.'
FROM p015_people
WHERE ord<=600;

DO $$
DECLARE
  v_total integer;
  v_leaked integer;
  v_mentors integer;
  v_bad_distribution integer;
BEGIN
  SELECT count(*) INTO v_total
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p015_scale';
  IF v_total<>10 THEN
    RAISE EXCEPTION 'P0-15 queue isolation: expected 10 queue items, got %',v_total;
  END IF;

  SELECT count(*) INTO v_leaked
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  JOIN p015_people p ON p.user_id=q.learner_user_id
  WHERE r.source_object_type='p015_scale' AND p.ord>10;
  IF v_leaked<>0 THEN
    RAISE EXCEPTION 'P0-15 queue leakage: % unassigned/waitlisted learners received queue work',v_leaked;
  END IF;

  SELECT count(DISTINCT q.mentor_user_id) INTO v_mentors
  FROM private.exam_prep_mentor_queue_items q
  JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
  WHERE r.source_object_type='p015_scale';
  IF v_mentors<>10 THEN
    RAISE EXCEPTION 'P0-15 queue distribution: expected 10 distinct mentors, got %',v_mentors;
  END IF;

  SELECT count(*) INTO v_bad_distribution
  FROM (
    SELECT q.mentor_user_id,count(*) c
    FROM private.exam_prep_mentor_queue_items q
    JOIN private.exam_prep_human_review_recommendations r ON r.id=q.recommendation_id
    WHERE r.source_object_type='p015_scale'
    GROUP BY q.mentor_user_id
    HAVING count(*)<>1
  ) x;
  IF v_bad_distribution<>0 THEN
    RAISE EXCEPTION 'P0-15 queue distribution: one or more mentors received an unexpected queue count';
  END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- 6. Legacy integrity inside the drill
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_changed integer;
BEGIN
  SELECT count(*) INTO v_changed
  FROM p015_legacy_baseline b
  JOIN LATERAL (
    SELECT CASE b.object_name
      WHEN 'questions' THEN (SELECT count(*) FROM public.questions)
      WHEN 'practice_attempts' THEN (SELECT count(*) FROM public.practice_attempts)
      WHEN 'practice_answers' THEN (SELECT count(*) FROM public.practice_answers)
      WHEN 'tour_attempts' THEN (SELECT count(*) FROM public.tour_attempts)
      WHEN 'tour_answers' THEN (SELECT count(*) FROM public.tour_answers)
      WHEN 'ratings_cache' THEN (SELECT count(*) FROM public.ratings_cache)
      WHEN 'certificates' THEN (SELECT count(*) FROM public.certificates)
    END::bigint AS now_count
  ) n ON true
  WHERE n.now_count<>b.row_count;

  IF v_changed<>0 THEN
    RAISE EXCEPTION 'P0-15 legacy integrity failed: % protected legacy tables changed',v_changed;
  END IF;
END
$$;

-- The test is intentionally non-persistent.
ROLLBACK;

-- ---------------------------------------------------------------------------
-- 7. Rollback proof: no synthetic identities or rollout changes survive
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_count integer;
  v_cfg record;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'p015-%@invalid.example';
  IF v_count<>0 THEN
    RAISE EXCEPTION 'P0-15 rollback failed: % synthetic auth users survived',v_count;
  END IF;

  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off'
     OR v_cfg.core_enabled
     OR v_cfg.ai_enabled
     OR v_cfg.mentor_enabled
     OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-15 rollback failed: feature config did not return to OFF/fail-closed baseline';
  END IF;
END
$$;

SELECT 'P0-15 isolated alpha matrix: PASS (all mutations rolled back)' AS result;
