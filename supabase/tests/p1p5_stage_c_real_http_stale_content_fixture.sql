-- Local-only fixture for real signed HTTP recovery of a learner's issued task
-- while one published P1 content version is temporarily retired.
\set ON_ERROR_STOP on
DO $guard$
DECLARE v_uid uuid:='22222222-2222-4222-8222-222222222292';
BEGIN
 IF current_database()<>'postgres'
 OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
 OR (SELECT count(*) FROM public.users)<>2
 OR (SELECT count(*) FROM auth.users)<>2
 OR EXISTS(SELECT 1 FROM public.users WHERE id NOT IN (
 '11111111-1111-4111-8111-111111111191'::uuid,
 '22222222-2222-4222-8222-222222222292'::uuid))
 OR EXISTS(SELECT 1 FROM private.exam_prep_beta_weekly_reviews)
 OR EXISTS(SELECT 1 FROM public.practice_attempts)
 OR EXISTS(SELECT 1 FROM public.tour_attempts)
 OR EXISTS(SELECT 1 FROM public.certificates)
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_config
  WHERE id=1 AND rollout_state='controlled_beta' AND core_enabled=true
  AND kill_switch=false AND ai_enabled=false AND mentor_enabled=false
  AND qa_open_all_core=false AND qa_open_all_weekly=false)
 OR NOT EXISTS(SELECT 1 FROM private.exam_prep_feature_entitlements
  WHERE user_id=v_uid AND entitlement_status='active' AND core_access)
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_authorizations
  WHERE reason LIKE 'S466-REAL-HTTP-%')
 THEN RAISE EXCEPTION 'Stage C real HTTP stale content fixture refused outside pristine isolated CI'; END IF;

 INSERT INTO private.exam_prep_session_authorizations(
 user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit)
 SELECT v_uid,a.id,a.component_code,'learning','issued',
 clock_timestamp()+interval '1 hour',
 CASE a.component_code
  WHEN 'P1' THEN 'S466-REAL-HTTP-RETIRED-P1'
  ELSE 'S466-REAL-HTTP-UNAFFECTED-P5' END,true
 FROM (
   SELECT DISTINCT ON (a.component_code) a.id,a.component_code
   FROM private.exam_prep_assessments a
   JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
   WHERE a.component_code IN ('P1','P5')
     AND a.assessment_type='learning'
     AND a.status='published' AND cv.status='published'
     AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai
       WHERE ai.assessment_id=a.id AND ai.question_id IS NOT NULL)
   ORDER BY a.component_code,a.id
 ) a;

 INSERT INTO private.exam_prep_session_authorizations(
  user_id,assessment_id,component_code,purpose,status,issued_at,valid_until,reason,academic_credit)
 SELECT v_uid,assessment_id,'P1','learning','issued',
  clock_timestamp()-interval '2 hours',clock_timestamp()-interval '1 hour',
  'S466-REAL-HTTP-EXPIRED-P1',true
 FROM private.exam_prep_session_authorizations
 WHERE user_id=v_uid AND reason='S466-REAL-HTTP-RETIRED-P1';

 IF (SELECT count(*) FROM private.exam_prep_session_authorizations
  WHERE user_id=v_uid AND reason LIKE 'S466-REAL-HTTP-%')<>3
 THEN RAISE EXCEPTION 'Stage C real HTTP P1/P5 published academic source missing'; END IF;
END $guard$;
\echo 'STAGE C REAL HTTP P1 P5 ISSUED CONTENT FIXTURE READY'
