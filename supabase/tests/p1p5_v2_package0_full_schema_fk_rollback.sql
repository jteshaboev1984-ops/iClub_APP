-- Package 0 genuine production-shaped session/authorization FK-cycle proof.
-- DISPOSABLE MIGRATIONS+POSTGRESQL 17 ONLY. NEVER execute in production.
-- Needs existing P1P5_E2E_ISOLATED fake user seed and published assessments.
-- All inserted/modified records and their audit events are ROLLED BACK.
\set ON_ERROR_STOP on
BEGIN;
DO $$
BEGIN
 IF current_database()<>'postgres' OR
    current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true' OR
    (SELECT count(*) FROM public.users)<>2 OR
    (SELECT count(*) FROM auth.users)<>2 OR
    EXISTS(SELECT 1 FROM public.practice_attempts) OR
    EXISTS(SELECT 1 FROM public.tour_attempts) OR
    EXISTS(SELECT 1 FROM public.certificates)
 THEN RAISE EXCEPTION 'REFUSED: only empty isolated P1P5 PG17 two-learner seed allowed'; END IF;
END $$;

INSERT INTO private.exam_prep_session_authorizations
 (id,user_id,assessment_id,component_code,purpose,status,reason)
SELECT 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid,
       '11111111-1111-4111-8111-111111111191'::uuid,a.id,'P1','diagnostic','issued','P0 isolated real FK proof'
FROM private.exam_prep_assessments a
WHERE a.component_code='P1' AND a.assessment_type='diagnostic' AND a.status='published'
ORDER BY a.id LIMIT 1;

INSERT INTO private.exam_prep_session_authorizations
 (id,user_id,assessment_id,component_code,purpose,status,reason)
SELECT 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb101'::uuid,
       '22222222-2222-4222-8222-222222222292'::uuid,a.id,'P5','diagnostic','issued','P0 isolated other-user control'
FROM private.exam_prep_assessments a
WHERE a.component_code='P5' AND a.assessment_type='diagnostic' AND a.status='published'
ORDER BY a.id LIMIT 1;

INSERT INTO private.exam_prep_sessions
 (id,authorization_id,user_id,program_version_id,content_version_id,
  assessment_id,assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
SELECT 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa201'::uuid,
       'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid,
       '11111111-1111-4111-8111-111111111191'::uuid,
       cv.program_version_id,a.content_version_id,
       a.id,a.assessment_version,'P1','diagnostic','active','p0-full-schema-proof-a',1
FROM private.exam_prep_assessments a
JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
JOIN private.exam_prep_session_authorizations au ON au.assessment_id=a.id
WHERE au.id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid;

INSERT INTO private.exam_prep_sessions
 (id,authorization_id,user_id,program_version_id,content_version_id,
  assessment_id,assessment_version,component_code,session_type,status,client_idempotency_key,total_items)
SELECT 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb201'::uuid,
       'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb101'::uuid,
       '22222222-2222-4222-8222-222222222292'::uuid,
       cv.program_version_id,a.content_version_id,
       a.id,a.assessment_version,'P5','diagnostic','active','p0-full-schema-proof-b',1
FROM private.exam_prep_assessments a
JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
JOIN private.exam_prep_session_authorizations au ON au.assessment_id=a.id
WHERE au.id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb101'::uuid;

UPDATE private.exam_prep_session_authorizations
SET consumed_session_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa201'::uuid,
    status='consumed',consumed_at=now()
WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid;

UPDATE private.exam_prep_session_authorizations
SET consumed_session_id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb201'::uuid,
    status='consumed',consumed_at=now()
WHERE id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb101'::uuid;

DO $$
BEGIN
 IF (SELECT count(*) FROM private.exam_prep_sessions
     WHERE id IN('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa201'::uuid,'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb201'::uuid))<>2
 OR (SELECT count(*) FROM private.exam_prep_session_authorizations
     WHERE id IN('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid,'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb101'::uuid))<>2
 THEN RAISE EXCEPTION 'FAIL: full schema test setup did not create exact two links'; END IF;
END $$;

SAVEPOINT p0_before_cleanup;

DO $$
BEGIN
 BEGIN
  DELETE FROM private.exam_prep_sessions
  WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa201'::uuid;
  RAISE EXCEPTION 'FAIL: actual full schema FK did not reject direct delete';
 EXCEPTION WHEN foreign_key_violation THEN
  RAISE NOTICE 'PASS: full schema session/authorization RESTRICT cycle refuses early delete';
 END;
END $$;

-- Fully isolated targeted cleanup for fake user A; fake user B remains.
UPDATE private.exam_prep_session_authorizations SET consumed_session_id=NULL
WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid;
DELETE FROM private.exam_prep_sessions
WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa201'::uuid;
DELETE FROM private.exam_prep_session_authorizations
WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid;

DO $$
BEGIN
 IF EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa201'::uuid)
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid)
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_sessions WHERE id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb201'::uuid)
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations WHERE id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb101'::uuid)
 OR (SELECT count(*) FROM public.users)<>2
 OR EXISTS(SELECT 1 FROM public.practice_attempts)
 OR EXISTS(SELECT 1 FROM public.tour_attempts)
 OR EXISTS(SELECT 1 FROM public.certificates)
 THEN RAISE EXCEPTION 'FAIL: full-schema targeted delete touched other learner or protected legacy'; END IF;
 RAISE NOTICE 'PASS: real full schema P1 targeted FK pair removable; P5 and other data unchanged';
END $$;

-- Repeated cleanup must be an exact no-op.
UPDATE private.exam_prep_session_authorizations SET consumed_session_id=NULL
WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid;
DELETE FROM private.exam_prep_sessions WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa201'::uuid;
DELETE FROM private.exam_prep_session_authorizations WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid;

ROLLBACK TO SAVEPOINT p0_before_cleanup;
DO $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM private.exam_prep_sessions
   WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa201'::uuid)
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations
   WHERE id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid AND consumed_session_id='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa201'::uuid)
 THEN RAISE EXCEPTION 'FAIL: real-schema SAVEPOINT did not restore both links'; END IF;
 RAISE NOTICE 'PASS: full-schema SAVEPOINT restored authorization and session';
END $$;
ROLLBACK;
-- Final proof in original transaction scope: no test rows survived.
DO $$
BEGIN
 IF EXISTS(SELECT 1 FROM private.exam_prep_sessions
   WHERE id IN('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa201'::uuid,'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb201'::uuid))
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations
   WHERE id IN('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa101'::uuid,'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbb101'::uuid))
 OR (SELECT count(*) FROM public.users)<>2 THEN
    RAISE EXCEPTION 'FAIL: full-schema rehearsal leaked fake data'; END IF;
 RAISE NOTICE 'PASS: all actual-migration FK rehearsals fully rolled back';
END $$;
