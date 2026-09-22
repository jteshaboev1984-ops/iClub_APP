-- Disposable PostgreSQL 17 ONLY. Refuse production. All fixtures roll back.
\set ON_ERROR_STOP on
DO $guard$ BEGIN
 IF current_setting('mcq_on.isolated_db',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'MCQ feature-ON test refused: disposable DB marker required'; END IF;
 IF (SELECT enabled FROM private.exam_prep_mcq_order_rollout_v1 WHERE singleton) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'MCQ feature-ON fixture requires rollout OFF'; END IF;
END $guard$;
BEGIN;
CREATE TEMP TABLE mcq_baseline AS
SELECT (SELECT count(*) FROM public.practice_attempts) practice_attempts,
       (SELECT count(*) FROM public.practice_answers) practice_answers,
       (SELECT count(*) FROM public.tour_attempts) tour_attempts,
       (SELECT count(*) FROM public.tour_answers) tour_answers,
       (SELECT count(*) FROM public.certificates) certificates,
       (SELECT count(*) FROM private.exam_prep_evidence_events) evidence;
SELECT private.register_exam_prep_synthetic_validation_run_v1(
 'SV-MCQ-ON-ROLLBACK','mcq-feature-on-isolated-v1',:'mcq_git_sha',
 'mcq-pg17',14101,'core','Dedicated isolated MCQ feature-ON regression; rollback only');
SELECT private.transition_exam_prep_synthetic_validation_run_v1(
 'SV-MCQ-ON-ROLLBACK','registered','running',null,null,
 jsonb_build_object('test','mcq-feature-on-rollback'));
DO $cases$
DECLARE
 c record; uid uuid; ass bigint; auth_id uuid; started jsonb; replayed jsonb;
 sid uuid; si private.exam_prep_session_items%rowtype; q public.questions%rowtype;
 locale text; payload jsonb; item_payload jsonb; displayed jsonb; expected jsonb;
 source_index int; display_index int; correct_index int; should_correct boolean;
 response jsonb; repeated jsonb; stored private.exam_prep_responses%rowtype;
 evidence_count int; map smallint[]; mapped_count int;
BEGIN
 FOR c IN SELECT * FROM (VALUES
    (1,'old-p1','P1','learning'),(2,'old-p5','P5','learning'),
    (3,'new-p1-learning','P1','learning'),(4,'new-p5-learning','P5','learning'),
    (5,'new-p1-diagnostic','P1','diagnostic'),(6,'new-p5-diagnostic','P5','diagnostic'),
    (7,'new-p1-timed','P1','timed'),(8,'new-p5-timed','P5','timed')
 ) x(n,scenario,component,kind) ORDER BY n LOOP
   IF c.n=3 THEN
     UPDATE private.exam_prep_mcq_order_rollout_v1
       SET enabled=true,enabled_at=now() WHERE singleton;
     IF (SELECT enabled FROM private.exam_prep_mcq_order_rollout_v1 WHERE singleton) IS DISTINCT FROM true
     THEN RAISE EXCEPTION 'Isolated feature enable failed'; END IF;
   END IF;
   uid:=private.create_exam_prep_synthetic_identity_v1(
     'SV-MCQ-ON-ROLLBACK','learner','SVF-MCQ-'||upper(replace(c.scenario,'-','')),
     'mcq-feature-on-'||c.scenario,'Ephemeral scenario; rollback only','en');
   -- Synthetic evidence requires a RUNNING registered run AND its own active clock.
   -- Initialize only after the first synthetic identity exists; reuse the same
   -- clock for all subsequent synthetic identities in this one isolated run.
   IF c.n=1 THEN
     PERFORM private.initialize_exam_prep_synthetic_clock_v1(
       'SV-MCQ-ON-ROLLBACK','Feature-on evidence-scoring regression clock');
   END IF;
   INSERT INTO private.exam_prep_feature_entitlements
     (user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from)
   VALUES(uid,'active',true,false,false,now()-interval '1 minute');
   PERFORM set_config('request.jwt.claim.sub',uid::text,true);
   PERFORM set_config('request.jwt.claim.role','authenticated',true);
   PERFORM public.save_exam_prep_exam_profile_v2('CI_P279_RECOVERY','A',12,6);
   SELECT a.id INTO ass FROM private.exam_prep_assessments a
   JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
   WHERE a.status='published' AND cv.status='published'
     AND a.component_code=c.component AND a.assessment_type=c.kind
     AND (c.kind='timed' OR EXISTS (
       SELECT 1 FROM private.exam_prep_assessment_items ai
       JOIN public.questions qp ON qp.id=ai.question_id
       WHERE ai.assessment_id=a.id AND qp.qtype='mcq'
         AND qp.correct_answer IN ('A','B','C','D')
         AND qp.options_text_en IS NOT NULL AND qp.options_text_ru IS NOT NULL
         AND qp.options_text_uz IS NOT NULL))
   ORDER BY a.id LIMIT 1;
   IF ass IS NULL THEN RAISE EXCEPTION 'Published fixture missing % %',c.component,c.kind; END IF;
   INSERT INTO private.exam_prep_session_authorizations
     (user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit)
   VALUES(uid,ass,c.component,c.kind,'issued',now()+interval '1 hour',
          'MCQ feature-on isolated test',true) RETURNING id INTO auth_id;
   started:=public.start_exam_prep_session_safe_v1(auth_id,'mcq-on-session-'||c.scenario);
   replayed:=public.start_exam_prep_session_safe_v1(auth_id,'mcq-on-session-'||c.scenario);
   sid:=(started->>'session_id')::uuid;
   IF sid IS NULL OR sid IS DISTINCT FROM (replayed->>'session_id')::uuid
      OR (replayed->>'resumed')::boolean IS DISTINCT FROM true
   THEN RAISE EXCEPTION 'Session start/retry mismatch %',c.scenario; END IF;
   SELECT count(*) INTO mapped_count FROM private.exam_prep_session_items
   WHERE session_id=sid AND display_to_source IS NOT NULL;
   IF (c.n<=2 OR c.kind='timed') AND mapped_count<>0
   THEN RAISE EXCEPTION 'Legacy/timed unexpectedly mapped %',c.scenario; END IF;
   IF c.kind='timed' THEN
     IF (SELECT count(*) FROM private.exam_prep_session_items WHERE session_id=sid)=0
     THEN RAISE EXCEPTION 'Timed session empty %',c.scenario; END IF;
     CONTINUE;
   END IF;
   SELECT si0.* INTO si FROM private.exam_prep_session_items si0
   JOIN public.questions qp ON qp.id=si0.question_id AND qp.qtype='mcq'
   WHERE si0.session_id=sid ORDER BY si0.item_order LIMIT 1;
   IF si.session_id IS NULL THEN RAISE EXCEPTION 'MCQ item missing %',c.scenario; END IF;
   SELECT * INTO q FROM public.questions WHERE id=si.question_id;
   map:=si.display_to_source;
   IF (c.n<=2 AND map IS NOT NULL) OR (c.n>2 AND map IS NULL)
   THEN RAISE EXCEPTION 'Wrong mapping state %',c.scenario; END IF;
   IF map IS NOT NULL AND (array_length(map,1)<>4 OR NOT map @> ARRAY[0,1,2,3]::smallint[])
   THEN RAISE EXCEPTION 'Invalid mapping %',c.scenario; END IF;
   FOR locale IN SELECT unnest(ARRAY['en','ru','uz']) LOOP
     payload:=public.get_exam_prep_session_safe_v1(sid,locale);
     SELECT element->'options' INTO displayed FROM jsonb_array_elements(payload->'items') element
       WHERE (element->>'item_order')::int=si.item_order;
     expected:=CASE locale WHEN 'ru' THEN q.options_text_ru::jsonb
                           WHEN 'uz' THEN q.options_text_uz::jsonb ELSE q.options_text_en::jsonb END;
     IF map IS NOT NULL THEN expected:=jsonb_build_array(
       expected->map[1],expected->map[2],expected->map[3],expected->map[4]); END IF;
     IF displayed IS DISTINCT FROM expected
     THEN RAISE EXCEPTION 'Frozen options drift case=% locale=%',c.scenario,locale; END IF;
   END LOOP;
   correct_index:=ascii(q.correct_answer)-ascii('A');
   display_index:=CASE WHEN map IS NULL THEN correct_index
                       ELSE array_position(map,correct_index::smallint)-1 END;
   -- Diagnostic intentionally submits a wrong displayed option: the scorer
   -- must retain the original canonical distractor for diagnostic matching.
   should_correct:=c.kind<>'diagnostic';
   IF NOT should_correct THEN display_index:=(display_index+1)%4; END IF;
   source_index:=CASE WHEN map IS NULL THEN display_index ELSE map[display_index+1] END;
   response:=public.submit_exam_prep_response_safe_v1(sid,si.item_order,
     jsonb_build_object('picked_index',display_index),'mcq-on-response-'||c.scenario,1000,'en');
   SELECT * INTO stored FROM private.exam_prep_responses WHERE session_id=sid AND item_order=si.item_order;
   IF stored.id IS NULL OR stored.is_correct IS DISTINCT FROM should_correct
      OR stored.picked_index IS DISTINCT FROM source_index
      OR stored.selected_answer IS DISTINCT FROM chr(65+source_index)
   THEN RAISE EXCEPTION 'Canonical scorer/diagnosis drift %',c.scenario; END IF;
   IF response->>'selected_answer' IS DISTINCT FROM chr(65+display_index)
   THEN RAISE EXCEPTION 'Returned display letter drift %',c.scenario; END IF;
   SELECT count(*) INTO evidence_count FROM private.exam_prep_evidence_events e
     WHERE e.response_id=stored.id AND e.component_code=c.component
       AND e.is_correct IS NOT DISTINCT FROM should_correct;
   IF evidence_count<>1 THEN RAISE EXCEPTION 'Academic evidence drift %',c.scenario; END IF;
   repeated:=public.submit_exam_prep_response_safe_v1(sid,si.item_order,
     jsonb_build_object('picked_index',display_index),'mcq-on-response-'||c.scenario,1000,'ru');
   IF (repeated->>'replayed')::boolean IS DISTINCT FROM true
      OR repeated->>'selected_answer' IS DISTINCT FROM chr(65+display_index)
      OR (SELECT count(*) FROM private.exam_prep_responses WHERE session_id=sid AND item_order=si.item_order)<>1
   THEN RAISE EXCEPTION 'Idempotent response retry drift %',c.scenario; END IF;
   payload:=public.get_exam_prep_session_safe_v1(sid,'uz');
   SELECT element INTO item_payload FROM jsonb_array_elements(payload->'items') element
     WHERE (element->>'item_order')::int=si.item_order;
   IF item_payload->>'selected_answer' IS DISTINCT FROM chr(65+display_index)
      OR (item_payload->>'answered')::boolean IS DISTINCT FROM true
   THEN RAISE EXCEPTION 'Locale switch/resume answer drift %',c.scenario; END IF;
 END LOOP;
 IF EXISTS(SELECT 1 FROM information_schema.role_table_grants
           WHERE table_schema='private'
             AND table_name IN ('exam_prep_mcq_order_rollout_v1','exam_prep_mcq_order_function_backups_v1')
             AND grantee IN ('PUBLIC','anon','authenticated'))
 OR EXISTS(SELECT 1 FROM pg_tables WHERE schemaname='private'
             AND tablename IN ('exam_prep_mcq_order_rollout_v1','exam_prep_mcq_order_function_backups_v1')
             AND rowsecurity IS NOT TRUE)
 THEN RAISE EXCEPTION 'MCQ private privilege or RLS leak'; END IF;
END $cases$;
DO $preservation$
DECLARE b record;
BEGIN
 SELECT * INTO b FROM mcq_baseline;
 IF (SELECT count(*) FROM public.practice_attempts)<>b.practice_attempts
 OR (SELECT count(*) FROM public.practice_answers)<>b.practice_answers
 OR (SELECT count(*) FROM public.tour_attempts)<>b.tour_attempts
 OR (SELECT count(*) FROM public.tour_answers)<>b.tour_answers
 OR (SELECT count(*) FROM public.certificates)<>b.certificates
 THEN RAISE EXCEPTION 'Legacy Practice/Tours/certificates mutated'; END IF;
 IF (SELECT count(*) FROM private.exam_prep_evidence_events)<>b.evidence+6
 THEN RAISE EXCEPTION 'Synthetic MCQ evidence count drift'; END IF;
END $preservation$;
ROLLBACK;
DO $postcheck$
BEGIN
 IF (SELECT enabled FROM private.exam_prep_mcq_order_rollout_v1 WHERE singleton) IS DISTINCT FROM false
 OR EXISTS(SELECT 1 FROM private.exam_prep_synthetic_identities WHERE run_id='SV-MCQ-ON-ROLLBACK')
 OR EXISTS(SELECT 1 FROM private.exam_prep_session_items WHERE display_to_source IS NOT NULL)
 THEN RAISE EXCEPTION 'Isolated feature-on test left residue'; END IF;
END $postcheck$;
SELECT 'PASS: PG17 feature ON, original P1/P5, EN/RU/UZ, canonical scorer, wrong diagnosis, retry, timed and complete rollback' AS result;
