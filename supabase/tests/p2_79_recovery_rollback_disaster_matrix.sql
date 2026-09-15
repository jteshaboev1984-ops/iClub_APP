-- P2-79 Recovery / Rollback / Disaster Rehearsal.
-- ISOLATED CI ONLY. Every mutation is contained in this transaction and the file
-- refuses to run unless the disposable-database marker is explicitly supplied.
-- No real learner, legacy Practice/Tour history, or production feature state is used.
\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p279.isolated_db',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-79 REFUSED: p279.isolated_db=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE p279_legacy_before AS
SELECT 'practice_attempts'::text AS object_name,count(*)::bigint AS row_count FROM public.practice_attempts
UNION ALL SELECT 'practice_answers',count(*) FROM public.practice_answers
UNION ALL SELECT 'tour_attempts',count(*) FROM public.tour_attempts
UNION ALL SELECT 'tour_answers',count(*) FROM public.tour_answers
UNION ALL SELECT 'certificates',count(*) FROM public.certificates
UNION ALL SELECT 'ratings_cache',count(*) FROM public.ratings_cache;

-- Production-shaped starting boundary inside disposable CI only.
UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;
UPDATE private.exam_prep_ai_policy SET generation_enabled=false,updated_at=now() WHERE id=1;
UPDATE private.exam_prep_optional_capability_status
SET runtime_status='shadow',gate_version=null,updated_at=now()
WHERE capability_code='ai_assist';

SELECT private.register_exam_prep_synthetic_validation_run_v1(
  'SV-P279-RECOVERY',
  'p279-recovery-disaster-v1',
  :'p279_git_sha',
  'p2-79',
  27901,
  'core',
  'P2-79 rollback-only recovery, rollback and disaster rehearsal'
);
SELECT private.transition_exam_prep_synthetic_validation_run_v1(
  'SV-P279-RECOVERY','registered','running',null,null,
  jsonb_build_object('p2_79','recovery-disaster-start')
);

CREATE TEMP TABLE p279_people(person_key text PRIMARY KEY,user_id uuid NOT NULL UNIQUE) ON COMMIT DROP;
DO $$
DECLARE v_uid uuid;
BEGIN
  v_uid:=private.create_exam_prep_synthetic_identity_v1(
    'SV-P279-RECOVERY','learner','SVF-P279-RECOVERY','p2-79-recovery-learner-proof',
    'Dedicated P2-79 synthetic learner; never a real beta learner.','en'
  );
  INSERT INTO p279_people VALUES('recovery',v_uid);
END
$$;

SELECT private.initialize_exam_prep_synthetic_clock_v1(
  'SV-P279-RECOVERY','P2-79 isolated academic clock'
);

INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
)
SELECT user_id,'active',true,false,false,null,clock_timestamp()-interval '1 minute'
FROM p279_people WHERE person_key='recovery';

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p279_people WHERE person_key='recovery'),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SELECT public.save_exam_prep_exam_profile_v2('CI_P279_RECOVERY','A',12,6);

-- Seed two immutable pieces of deterministic academic history so every recovery
-- action has something real to preserve. No client answer key is used.
CREATE OR REPLACE FUNCTION pg_temp.p279_seed_learning_evidence_v1(
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
  JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
  WHERE a.component_code=p_component
    AND a.assessment_type='learning'
    AND a.status='published'
    AND cv.status='published'
    AND ai.question_id IS NOT NULL
    AND coalesce(ai.is_holdout,false)=false
  ORDER BY a.id,ai.item_order
  LIMIT 1;

  IF v_assessment_id IS NULL THEN
    RAISE EXCEPTION 'P2-79 governed learning fixture missing component=%',p_component;
  END IF;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(
    p_user_id,v_assessment_id,p_component,'learning','issued',clock_timestamp()+interval '1 hour',
    'P2-79 immutable academic-history preservation fixture',true
  ) RETURNING id INTO v_auth_id;

  INSERT INTO private.exam_prep_sessions(
    id,authorization_id,user_id,program_version_id,content_version_id,assessment_id,
    assessment_version,component_code,session_type,status,client_idempotency_key,total_items
  ) VALUES(
    v_session_id,v_auth_id,p_user_id,p_program_version_id,v_content_version_id,v_assessment_id,
    v_assessment_version,p_component,'learning','active','p279-'||p_tag||'-session',1
  );

  INSERT INTO private.exam_prep_session_items(
    session_id,item_order,item_kind,question_id,primary_skill_code,reserve_role,
    is_holdout,content_meta_id,question_snapshot_md5,item_version
  ) VALUES(
    v_session_id,1,'question',v_question_id,v_skill_code,v_reserve_role,
    false,v_content_meta_id,v_question_snapshot_md5,v_assessment_version||'|p279|'||p_tag
  );

  INSERT INTO private.exam_prep_responses(
    session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
    is_correct,evaluator_version,elapsed_ms
  ) VALUES(
    v_session_id,1,p_user_id,'p279-'||p_tag||'-response','machine',
    'synthetic-app-verified',true,'p279_fixture_v1',1000
  ) RETURNING id INTO v_response_id;

  INSERT INTO private.exam_prep_evidence_events(
    user_id,component_code,skill_code,session_id,response_id,evidence_type,
    verification_status,is_correct,evidence_payload,source_version
  ) VALUES(
    p_user_id,p_component,v_skill_code,v_session_id,v_response_id,'learning',
    'app_verified',true,
    jsonb_build_object('p2_79','history-preservation','tag',p_tag,'component',p_component),
    v_assessment_version||'|p279'
  );

  UPDATE private.exam_prep_sessions
  SET status='finalized',finalized_at=clock_timestamp(),last_activity_at=clock_timestamp(),
      finalize_idempotency_key='p279-'||p_tag||'-final'
  WHERE id=v_session_id;
END
$$;

DO $$
DECLARE v_uid uuid; v_program bigint;
BEGIN
  SELECT user_id INTO v_uid FROM p279_people WHERE person_key='recovery';
  SELECT id INTO v_program FROM private.exam_prep_program_versions
  WHERE program_key='math_as_p1_p5' AND version_key='p1_p5_canonical_v1_0' AND status='active';
  IF v_program IS NULL THEN RAISE EXCEPTION 'P2-79 canonical program missing'; END IF;

  PERFORM pg_temp.p279_seed_learning_evidence_v1(v_uid,v_program,'P1','p1');
  PERFORM pg_temp.p279_seed_learning_evidence_v1(v_uid,v_program,'P5','p5');
  PERFORM private.rebuild_exam_prep_placement_v1(v_uid,'P1');
  PERFORM private.rebuild_exam_prep_placement_v1(v_uid,'P5');
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P1');
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,'P5');
END
$$;

CREATE TEMP TABLE p279_academic_before AS
WITH u AS (SELECT user_id FROM p279_people WHERE person_key='recovery')
SELECT jsonb_build_object(
  'evidence_count',(SELECT count(*) FROM private.exam_prep_evidence_events e WHERE e.user_id=(SELECT user_id FROM u)),
  'evidence_hash',(SELECT md5(coalesce(string_agg(to_jsonb(e)::text,'|' ORDER BY e.id::text),'[]')) FROM private.exam_prep_evidence_events e WHERE e.user_id=(SELECT user_id FROM u)),
  'skill_count',(SELECT count(*) FROM private.exam_prep_skill_states s WHERE s.user_id=(SELECT user_id FROM u)),
  'skill_hash',(SELECT md5(coalesce(string_agg(to_jsonb(s)::text,'|' ORDER BY s.component_code,s.skill_code,s.engine_version),'[]')) FROM private.exam_prep_skill_states s WHERE s.user_id=(SELECT user_id FROM u)),
  'placement_count',(SELECT count(*) FROM private.exam_prep_component_placements p WHERE p.user_id=(SELECT user_id FROM u)),
  'placement_hash',(SELECT md5(coalesce(string_agg(to_jsonb(p)::text,'|' ORDER BY p.component_code),'[]')) FROM private.exam_prep_component_placements p WHERE p.user_id=(SELECT user_id FROM u)),
  'stage_count',(SELECT count(*) FROM private.exam_prep_stage_states s WHERE s.user_id=(SELECT user_id FROM u)),
  'stage_hash',(SELECT md5(coalesce(string_agg(to_jsonb(s)::text,'|' ORDER BY s.component_code,s.engine_version),'[]')) FROM private.exam_prep_stage_states s WHERE s.user_id=(SELECT user_id FROM u))
) AS snapshot;

DO $$
DECLARE v_n int;
BEGIN
  SELECT (snapshot->>'evidence_count')::int INTO v_n FROM p279_academic_before;
  IF v_n<>2 THEN RAISE EXCEPTION 'P2-79 expected two seeded evidence rows, got %',v_n; END IF;
END
$$;

-- Recovery policy itself must change planning/recovery metadata only. A 14-day
-- interruption is source-defined as the 2-3 week recovery band for both P1/P5.
SELECT public.record_my_exam_prep_interruption_v2(current_date-14,current_date,'absence');
DO $$
DECLARE v_uid uuid; v_count int;
BEGIN
  SELECT user_id INTO v_uid FROM p279_people WHERE person_key='recovery';
  SELECT count(*) INTO v_count
  FROM private.exam_prep_recovery_cases
  WHERE user_id=v_uid AND status='active' AND recovery_mode='recovery_2_3w'
    AND evidence_standards_preserved AND NOT absence_stage_downgrade_allowed;
  IF v_count<>2 THEN
    RAISE EXCEPTION 'P2-79 expected two independent P1/P5 recovery cases, got %',v_count;
  END IF;
END
$$;

-- Select one normal published learning assessment for session recovery tests.
CREATE TEMP TABLE p279_assessment AS
SELECT a.id AS assessment_id,a.content_version_id,a.component_code,a.assessment_type,a.status AS assessment_status,cv.status AS content_status
FROM private.exam_prep_assessments a
JOIN private.exam_prep_content_versions cv ON cv.id=a.content_version_id
WHERE a.status='published' AND cv.status='published' AND a.assessment_type='learning'
  AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai WHERE ai.assessment_id=a.id)
ORDER BY a.id
LIMIT 1;
DO $$ BEGIN
  IF NOT EXISTS(SELECT 1 FROM p279_assessment) THEN RAISE EXCEPTION 'P2-79 published learning assessment missing'; END IF;
END $$;

-- Kill switch in the middle of an already-started flow: access fails closed,
-- immutable history stays put, and the same idempotency key resumes exactly the
-- same session after the switch is restored.
DO $$
DECLARE
  v_uid uuid;
  v_ass bigint;
  v_component text;
  v_auth uuid;
  v_first jsonb;
  v_replay jsonb;
  v_session uuid;
  v_blocked boolean:=false;
  v_core boolean;
  v_count int;
BEGIN
  SELECT user_id INTO v_uid FROM p279_people WHERE person_key='recovery';
  SELECT assessment_id,component_code INTO v_ass,v_component FROM p279_assessment;
  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_uid,v_ass,v_component,'learning','issued',clock_timestamp()+interval '1 hour',
           'P2-79 kill-switch mid-flow rehearsal',true)
  RETURNING id INTO v_auth;

  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_first:=public.start_exam_prep_session_safe_v1(v_auth,'p279-kill-resume-0001');
  v_session:=(v_first->>'session_id')::uuid;
  IF coalesce((v_first->>'resumed')::boolean,true) THEN RAISE EXCEPTION 'P2-79 initial session unexpectedly resumed'; END IF;

  UPDATE private.exam_prep_feature_config SET kill_switch=true,updated_at=now() WHERE id=1;
  SELECT core_access INTO v_core FROM public.get_exam_prep_capabilities_v1();
  IF coalesce(v_core,false) THEN RAISE EXCEPTION 'P2-79 kill switch left Core capability active'; END IF;

  BEGIN
    PERFORM public.start_exam_prep_session_safe_v1(v_auth,'p279-kill-resume-0001');
  EXCEPTION WHEN OTHERS THEN
    v_blocked:=true;
  END;
  IF NOT v_blocked THEN RAISE EXCEPTION 'P2-79 kill switch did not block mid-flow server access'; END IF;

  UPDATE private.exam_prep_feature_config SET kill_switch=false,updated_at=now() WHERE id=1;
  v_replay:=public.start_exam_prep_session_safe_v1(v_auth,'p279-kill-resume-0001');
  IF (v_replay->>'session_id')::uuid<>v_session OR coalesce((v_replay->>'resumed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-79 kill-switch replay did not resume exact session first=% replay=%',v_first,v_replay;
  END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_sessions
  WHERE user_id=v_uid AND client_idempotency_key='p279-kill-resume-0001';
  IF v_count<>1 THEN RAISE EXCEPTION 'P2-79 kill-switch replay duplicated session count=%',v_count; END IF;
END
$$;

-- Failed migration simulation. A deliberately bad subtransaction creates a
-- probe table and then violates its PK. PostgreSQL must roll back the whole
-- subtransaction, leaving no half-applied schema object.
DO $$
DECLARE v_failed boolean:=false;
BEGIN
  BEGIN
    EXECUTE 'create table private.p279_failed_migration_probe(id integer primary key, note text not null)';
    EXECUTE 'insert into private.p279_failed_migration_probe values (1,''first'')';
    EXECUTE 'insert into private.p279_failed_migration_probe values (1,''duplicate'')';
  EXCEPTION WHEN unique_violation THEN
    v_failed:=true;
  END;
  IF NOT v_failed THEN RAISE EXCEPTION 'P2-79 failed-migration probe unexpectedly succeeded'; END IF;
  IF to_regclass('private.p279_failed_migration_probe') IS NOT NULL THEN
    RAISE EXCEPTION 'P2-79 failed migration left partial schema object';
  END IF;
  IF to_regprocedure('public.get_exam_prep_capabilities_v1()') IS NULL THEN
    RAISE EXCEPTION 'P2-79 current schema became unusable after failed migration';
  END IF;
END
$$;

-- Stale/bad content version: a previously issued authorization must fail closed
-- while its governed content version is retired, then become usable again after
-- the exact status is restored. No session is created during the bad interval.
DO $$
DECLARE
  v_uid uuid;
  v_ass bigint;
  v_cv bigint;
  v_component text;
  v_auth uuid;
  v_blocked boolean:=false;
  v_err text;
  v_start jsonb;
  v_count int;
BEGIN
  SELECT user_id INTO v_uid FROM p279_people WHERE person_key='recovery';
  SELECT assessment_id,content_version_id,component_code INTO v_ass,v_cv,v_component FROM p279_assessment;
  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_uid,v_ass,v_component,'learning','issued',clock_timestamp()+interval '1 hour',
           'P2-79 stale content-version rehearsal',true)
  RETURNING id INTO v_auth;

  UPDATE private.exam_prep_content_versions SET status='retired',retired_at=clock_timestamp() WHERE id=v_cv;
  BEGIN
    PERFORM public.start_exam_prep_session_safe_v1(v_auth,'p279-content-recover-0001');
  EXCEPTION WHEN OTHERS THEN
    v_blocked:=true; v_err:=SQLERRM;
  END;
  IF NOT v_blocked OR position('exam_prep_content_version_not_published' in coalesce(v_err,''))=0 THEN
    RAISE EXCEPTION 'P2-79 stale content did not fail closed as expected error=%',v_err;
  END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_sessions
  WHERE user_id=v_uid AND client_idempotency_key='p279-content-recover-0001';
  IF v_count<>0 THEN RAISE EXCEPTION 'P2-79 stale content created a session'; END IF;

  UPDATE private.exam_prep_content_versions SET status='published',retired_at=null WHERE id=v_cv;
  v_start:=public.start_exam_prep_session_safe_v1(v_auth,'p279-content-recover-0001');
  IF coalesce((v_start->>'resumed')::boolean,true) THEN RAISE EXCEPTION 'P2-79 restored content unexpectedly resumed old session'; END IF;
END
$$;

-- Expired/stale client authorization: old authorization is rejected; a fresh
-- authorization succeeds, and a duplicate retry resumes rather than duplicates.
DO $$
DECLARE
  v_uid uuid;
  v_ass bigint;
  v_component text;
  v_old_auth uuid;
  v_new_auth uuid;
  v_blocked boolean:=false;
  v_err text;
  v_first jsonb;
  v_retry jsonb;
  v_count int;
BEGIN
  SELECT user_id INTO v_uid FROM p279_people WHERE person_key='recovery';
  SELECT assessment_id,component_code INTO v_ass,v_component FROM p279_assessment;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,issued_at,valid_until,reason,academic_credit
  ) VALUES(v_uid,v_ass,v_component,'learning','issued',clock_timestamp()-interval '2 hours',
           clock_timestamp()-interval '1 hour','P2-79 expired-client rehearsal',true)
  RETURNING id INTO v_old_auth;

  BEGIN
    PERFORM public.start_exam_prep_session_safe_v1(v_old_auth,'p279-expired-client-0001');
  EXCEPTION WHEN OTHERS THEN
    v_blocked:=true; v_err:=SQLERRM;
  END;
  IF NOT v_blocked OR position('exam_prep_authorization_expired' in coalesce(v_err,''))=0 THEN
    RAISE EXCEPTION 'P2-79 expired client authorization did not fail closed error=%',v_err;
  END IF;

  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(v_uid,v_ass,v_component,'learning','issued',clock_timestamp()+interval '1 hour',
           'P2-79 fresh authorization after stale client',true)
  RETURNING id INTO v_new_auth;

  v_first:=public.start_exam_prep_session_safe_v1(v_new_auth,'p279-fresh-client-0001');
  v_retry:=public.start_exam_prep_session_safe_v1(v_new_auth,'p279-fresh-client-0001');
  IF (v_first->>'session_id') IS DISTINCT FROM (v_retry->>'session_id')
     OR coalesce((v_retry->>'resumed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-79 stale-client recovery retry mismatch first=% retry=%',v_first,v_retry;
  END IF;
  SELECT count(*) INTO v_count FROM private.exam_prep_sessions
  WHERE user_id=v_uid AND client_idempotency_key='p279-fresh-client-0001';
  IF v_count<>1 THEN RAISE EXCEPTION 'P2-79 fresh-client retry duplicated session count=%',v_count; END IF;
END
$$;

-- AI outage/recovery remains an optional capability transition. Generation is
-- explicitly disabled; deterministic academic truth must remain unchanged.
DO $$
DECLARE v_uid uuid; v_core boolean; v_ai boolean;
BEGIN
  SELECT user_id INTO v_uid FROM p279_people WHERE person_key='recovery';
  UPDATE private.exam_prep_feature_entitlements SET ai_assist=true WHERE user_id=v_uid;
  UPDATE private.exam_prep_feature_config SET ai_enabled=true,updated_at=now() WHERE id=1;
  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  SELECT core_access,ai_assist INTO v_core,v_ai FROM public.get_exam_prep_capabilities_v1();
  IF v_core IS NOT TRUE OR v_ai IS NOT TRUE THEN RAISE EXCEPTION 'P2-79 AI pre-outage capability mismatch core=% ai=%',v_core,v_ai; END IF;

  UPDATE private.exam_prep_feature_config SET ai_enabled=false,updated_at=now() WHERE id=1;
  SELECT core_access,ai_assist INTO v_core,v_ai FROM public.get_exam_prep_capabilities_v1();
  IF v_core IS NOT TRUE OR v_ai IS NOT FALSE THEN RAISE EXCEPTION 'P2-79 AI outage coupled to Core core=% ai=%',v_core,v_ai; END IF;

  UPDATE private.exam_prep_feature_entitlements SET ai_assist=false WHERE user_id=v_uid;
END
$$;

-- All learner-facing recovery/service failures above may add operational metadata,
-- but they must not rewrite the previously established deterministic truth.
DO $$
DECLARE v_uid uuid; v_after jsonb; v_before jsonb;
BEGIN
  SELECT user_id INTO v_uid FROM p279_people WHERE person_key='recovery';
  SELECT snapshot INTO v_before FROM p279_academic_before;
  SELECT jsonb_build_object(
    'evidence_count',(SELECT count(*) FROM private.exam_prep_evidence_events e WHERE e.user_id=v_uid),
    'evidence_hash',(SELECT md5(coalesce(string_agg(to_jsonb(e)::text,'|' ORDER BY e.id::text),'[]')) FROM private.exam_prep_evidence_events e WHERE e.user_id=v_uid),
    'skill_count',(SELECT count(*) FROM private.exam_prep_skill_states s WHERE s.user_id=v_uid),
    'skill_hash',(SELECT md5(coalesce(string_agg(to_jsonb(s)::text,'|' ORDER BY s.component_code,s.skill_code,s.engine_version),'[]')) FROM private.exam_prep_skill_states s WHERE s.user_id=v_uid),
    'placement_count',(SELECT count(*) FROM private.exam_prep_component_placements p WHERE p.user_id=v_uid),
    'placement_hash',(SELECT md5(coalesce(string_agg(to_jsonb(p)::text,'|' ORDER BY p.component_code),'[]')) FROM private.exam_prep_component_placements p WHERE p.user_id=v_uid),
    'stage_count',(SELECT count(*) FROM private.exam_prep_stage_states s WHERE s.user_id=v_uid),
    'stage_hash',(SELECT md5(coalesce(string_agg(to_jsonb(s)::text,'|' ORDER BY s.component_code,s.engine_version),'[]')) FROM private.exam_prep_stage_states s WHERE s.user_id=v_uid)
  ) INTO v_after;
  IF v_after<>v_before THEN
    RAISE EXCEPTION 'P2-79 academic state changed during recovery/disaster tests before=% after=%',v_before,v_after;
  END IF;
END
$$;

-- Simulate an interrupted run followed by an interrupted cleanup. The governed
-- cleanup engine must recover from cleanup_status=failed and be idempotent.
SELECT private.transition_exam_prep_synthetic_validation_run_v1(
  'SV-P279-RECOVERY','running','failed',
  jsonb_build_object('p2_79','simulated-interrupted-run'),
  'p279_simulated_interruption',
  jsonb_build_object('p2_79','run-interrupted-after-recovery-tests')
);
SELECT private.transition_exam_prep_synthetic_cleanup_v1(
  'SV-P279-RECOVERY','not_started','pending',jsonb_build_object('p2_79','cleanup-queued')
);
SELECT private.transition_exam_prep_synthetic_cleanup_v1(
  'SV-P279-RECOVERY','pending','running',jsonb_build_object('p2_79','cleanup-started')
);
SELECT private.transition_exam_prep_synthetic_cleanup_v1(
  'SV-P279-RECOVERY','running','failed',jsonb_build_object('p2_79','simulated-cleanup-interruption')
);

DO $$
DECLARE v_cleanup jsonb; v_retry jsonb; v_n int;
BEGIN
  v_cleanup:=private.cleanup_exam_prep_synthetic_run_v1(
    'SV-P279-RECOVERY',1,'p2-79-recovered-cleanup-proof','I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1'
  );
  IF v_cleanup->>'cleanup_status'<>'clean' OR coalesce((v_cleanup->>'idempotent')::boolean,true) THEN
    RAISE EXCEPTION 'P2-79 interrupted cleanup did not recover cleanly: %',v_cleanup;
  END IF;
  v_retry:=private.cleanup_exam_prep_synthetic_run_v1(
    'SV-P279-RECOVERY',1,'p2-79-recovered-cleanup-proof','I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1'
  );
  IF v_retry->>'cleanup_status'<>'clean' OR coalesce((v_retry->>'idempotent')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-79 cleanup retry was not idempotent: %',v_retry;
  END IF;
  SELECT count(*) INTO v_n FROM private.exam_prep_audit_events
  WHERE event_type='synthetic_validation_run_cleaned'
    AND object_type='private.exam_prep_synthetic_validation_runs'
    AND object_id='SV-P279-RECOVERY';
  IF v_n<>1 THEN RAISE EXCEPTION 'P2-79 cleanup summary audit count expected 1 got %',v_n; END IF;
END
$$;

-- Recovery/replay after the failed run: create a brand-new governed run, prove it
-- can complete and clean without manual repair, then clean it twice safely.
SELECT private.register_exam_prep_synthetic_validation_run_v1(
  'SV-P279-REPLAY',
  'p279-recovery-replay-v1',
  :'p279_git_sha',
  'p2-79',
  27902,
  'core',
  'P2-79 clean replay after simulated interrupted run and cleanup'
);
SELECT private.transition_exam_prep_synthetic_validation_run_v1(
  'SV-P279-REPLAY','registered','running',null,null,jsonb_build_object('p2_79','replay-start')
);
DO $$
DECLARE v_uid uuid;
BEGIN
  v_uid:=private.create_exam_prep_synthetic_identity_v1(
    'SV-P279-REPLAY','learner','SVF-P279-REPLAY','p2-79-replay-learner-proof',
    'P2-79 replay identity after recovery; synthetic only.','uz'
  );
END
$$;
SELECT private.complete_exam_prep_synthetic_run_v1(
  'SV-P279-REPLAY',1,jsonb_build_object('p2_79','replay-complete')
);
SELECT private.cleanup_exam_prep_synthetic_run_v1(
  'SV-P279-REPLAY',1,'p2-79-replay-cleanup-proof','I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1'
);
DO $$
DECLARE v_retry jsonb;
BEGIN
  v_retry:=private.cleanup_exam_prep_synthetic_run_v1(
    'SV-P279-REPLAY',1,'p2-79-replay-cleanup-proof','I_CONFIRM_SYNTHETIC_RUN_CLEANUP_V1'
  );
  IF coalesce((v_retry->>'idempotent')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-79 replay cleanup retry not idempotent: %',v_retry;
  END IF;
END
$$;

-- Restore the production-shaped optional-layers-off boundary before final
-- assertions. All changes still roll back below.
UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;
UPDATE private.exam_prep_ai_policy SET generation_enabled=false,updated_at=now() WHERE id=1;
UPDATE private.exam_prep_optional_capability_status
SET runtime_status='shadow',gate_version=null,updated_at=now()
WHERE capability_code='ai_assist';

DO $$
DECLARE v_changed int; v_residue int;
BEGIN
  SELECT count(*) INTO v_changed
  FROM p279_legacy_before b
  JOIN LATERAL (
    SELECT CASE b.object_name
      WHEN 'practice_attempts' THEN (SELECT count(*) FROM public.practice_attempts)
      WHEN 'practice_answers' THEN (SELECT count(*) FROM public.practice_answers)
      WHEN 'tour_attempts' THEN (SELECT count(*) FROM public.tour_attempts)
      WHEN 'tour_answers' THEN (SELECT count(*) FROM public.tour_answers)
      WHEN 'certificates' THEN (SELECT count(*) FROM public.certificates)
      WHEN 'ratings_cache' THEN (SELECT count(*) FROM public.ratings_cache)
    END::bigint AS now_count
  ) n ON true
  WHERE n.now_count<>b.row_count;
  IF v_changed<>0 THEN RAISE EXCEPTION 'P2-79 legacy row counts changed before rollback objects=%',v_changed; END IF;

  SELECT count(*) INTO v_residue FROM private.exam_prep_synthetic_identities
  WHERE run_id IN ('SV-P279-RECOVERY','SV-P279-REPLAY');
  IF v_residue<>0 THEN RAISE EXCEPTION 'P2-79 governed cleanup left synthetic identities=%',v_residue; END IF;
END
$$;

ROLLBACK;

-- Outer rollback proof: even the run ledger/temporary disaster manipulations are
-- gone; production-shaped feature state remains as supplied by the workflow.
DO $$
DECLARE v_n int; v_cfg private.exam_prep_feature_config%rowtype;
BEGIN
  SELECT count(*) INTO v_n FROM private.exam_prep_synthetic_validation_runs
  WHERE run_id IN ('SV-P279-RECOVERY','SV-P279-REPLAY');
  IF v_n<>0 THEN RAISE EXCEPTION 'P2-79 outer rollback left run registry rows=%',v_n; END IF;
  SELECT count(*) INTO v_n FROM auth.users WHERE email LIKE 'exam-prep-sv-%@invalid.example';
  IF v_n<>0 THEN RAISE EXCEPTION 'P2-79 outer rollback left synthetic auth users=%',v_n; END IF;

  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta' OR NOT v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P2-79 outer rollback feature boundary mismatch=%',row_to_json(v_cfg);
  END IF;
END
$$;

SELECT 'P2-79 recovery/rollback/disaster matrix: GREEN (all mutations rolled back)' AS result;