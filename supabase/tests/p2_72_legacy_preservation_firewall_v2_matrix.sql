\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p272.isolated_db', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-72 REFUSED: isolated test database required';
  END IF;
END
$$;

BEGIN;

-- P2-72 proves that real Exam Prep writes do not mutate the legacy learner
-- surfaces that pre-date Exam Prep. The isolated CI bootstrap intentionally
-- carries these six core history-bearing legacy tables; production-only legacy
-- surfaces are covered by the source/trigger firewall below and the live
-- read-only smoke performed before closure.
CREATE TEMP TABLE p272_legacy_fingerprint(
  phase text not null,
  object_name text not null,
  row_count bigint not null,
  row_hash text not null,
  primary key(phase,object_name)
) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.p272_capture_legacy_v1(p_phase text)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_table text;
  v_count bigint;
  v_hash text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY[
    'practice_attempts','practice_answers','tour_attempts','tour_answers','ratings_cache','certificates'
  ] LOOP
    EXECUTE format(
      'select count(*)::bigint, md5(coalesce(string_agg(to_jsonb(t)::text, E''\\n'' order by to_jsonb(t)::text),''<empty>'')) from public.%I t',
      v_table
    ) INTO v_count,v_hash;
    INSERT INTO p272_legacy_fingerprint(phase,object_name,row_count,row_hash)
    VALUES(p_phase,v_table,v_count,v_hash);
  END LOOP;
END
$$;

-- Non-empty sentinels make the fingerprint test sensitive to UPDATE/DELETE as
-- well as accidental INSERTs. Everything is rollback-only.
INSERT INTO public.practice_attempts DEFAULT VALUES;
INSERT INTO public.practice_attempts DEFAULT VALUES;
INSERT INTO public.practice_answers DEFAULT VALUES;
INSERT INTO public.practice_answers DEFAULT VALUES;
INSERT INTO public.tour_attempts DEFAULT VALUES;
INSERT INTO public.tour_attempts DEFAULT VALUES;
INSERT INTO public.tour_answers DEFAULT VALUES;
INSERT INTO public.tour_answers DEFAULT VALUES;
INSERT INTO public.ratings_cache DEFAULT VALUES;
INSERT INTO public.ratings_cache DEFAULT VALUES;
INSERT INTO public.certificates DEFAULT VALUES;
INSERT INTO public.certificates DEFAULT VALUES;

SELECT pg_temp.p272_capture_legacy_v1('before');

DO $$
DECLARE v_bad text;
BEGIN
  SELECT object_name INTO v_bad
  FROM p272_legacy_fingerprint
  WHERE phase='before' AND row_count<>2
  ORDER BY object_name LIMIT 1;
  IF v_bad IS NOT NULL THEN
    RAISE EXCEPTION 'P2-72 legacy sentinel fixture incomplete for %',v_bad;
  END IF;
END
$$;

-- Structural server-side firewall: no Exam Prep function may directly mutate
-- any protected legacy Practice/Tour/rating/certificate/history surface, even
-- those that exist only in the full production schema rather than this minimal
-- isolated contract.
DO $$
DECLARE
  v_fn record;
  v_table text;
  v_pattern text;
BEGIN
  FOR v_fn IN
    SELECT n.nspname AS schema_name,p.proname,pg_get_functiondef(p.oid) AS def
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE p.proname ILIKE '%exam_prep%'
  LOOP
    FOREACH v_table IN ARRAY ARRAY[
      'practice_attempts','practice_answers','practice_sessions_v4','practice_session_answers_v4',
      'practice_drill_sessions_v4','practice_drill_answers_v4','practice_review_events_v1',
      'tour_attempts','tour_answers','tour_session_runtime_v4','tour_session_answers_v4',
      'ratings_cache','certificates','user_subjects','user_subjects_history','app_events'
    ] LOOP
      v_pattern:=format(
        '(insert[[:space:]]+into|update|delete[[:space:]]+from|truncate([[:space:]]+table)?)[[:space:]]+public\\.%s([^a-zA-Z0-9_]|$)',
        v_table
      );
      IF v_fn.def ~* v_pattern THEN
        RAISE EXCEPTION 'P2-72 forbidden legacy mutation path in %.% -> public.%',v_fn.schema_name,v_fn.proname,v_table;
      END IF;
    END LOOP;
  END LOOP;

  IF EXISTS(
    SELECT 1
    FROM pg_trigger t
    JOIN pg_class c ON c.oid=t.tgrelid
    JOIN pg_namespace nc ON nc.oid=c.relnamespace
    JOIN pg_proc p ON p.oid=t.tgfoid
    WHERE NOT t.tgisinternal
      AND nc.nspname='public'
      AND c.relname IN (
        'practice_attempts','practice_answers','tour_attempts','tour_answers','ratings_cache','certificates'
      )
      AND p.proname ILIKE '%exam_prep%'
  ) THEN
    RAISE EXCEPTION 'P2-72 Exam Prep trigger attached to protected legacy table';
  END IF;
END
$$;

CREATE OR REPLACE FUNCTION pg_temp.p272_finish_session_v1(
  p_user_id uuid,
  p_assessment_id bigint,
  p_component text,
  p_tag text
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_auth uuid;
  v_session uuid;
  v_item record;
  v_payload jsonb;
BEGIN
  INSERT INTO private.exam_prep_session_authorizations(
    user_id,assessment_id,component_code,purpose,status,valid_until,reason,academic_credit
  ) VALUES(
    p_user_id,p_assessment_id,p_component,'learning','issued',clock_timestamp()+interval '1 hour',
    'P2-72 rollback-only legacy firewall fixture',true
  ) RETURNING id INTO v_auth;

  PERFORM set_config('request.jwt.claim.sub',p_user_id::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  v_session:=(public.start_exam_prep_session_safe_v1(v_auth,'p272-'||p_tag||'-start')->>'session_id')::uuid;

  FOR v_item IN
    SELECT si.item_order,si.item_kind,q.correct_answer
    FROM private.exam_prep_session_items si
    LEFT JOIN public.questions q ON q.id=si.question_id
    WHERE si.session_id=v_session
    ORDER BY si.item_order
  LOOP
    IF v_item.item_kind='question' THEN
      v_payload:=jsonb_build_object('answer',v_item.correct_answer);
    ELSE
      v_payload:=jsonb_build_object('artifact',jsonb_build_object(
        'working','P2-72 isolated preservation working',
        'method','legacy firewall validation'
      ));
    END IF;
    PERFORM public.submit_exam_prep_response_safe_v1(
      v_session,v_item.item_order,v_payload,
      'p272-'||p_tag||'-i'||lpad(v_item.item_order::text,3,'0'),900,'en'
    );
  END LOOP;

  PERFORM public.finalize_exam_prep_session_safe_v1(v_session,'p272-'||p_tag||'-final');
  RETURN v_session;
END
$$;

DO $$
DECLARE
  v_uid uuid:=gen_random_uuid();
  v_p1 bigint;
  v_p5 bigint;
BEGIN
  SELECT a.id INTO v_p1
  FROM private.exam_prep_assessments a
  WHERE a.component_code='P1' AND a.assessment_type='learning' AND a.status='published'
    AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai WHERE ai.assessment_id=a.id)
  ORDER BY a.id LIMIT 1;

  SELECT a.id INTO v_p5
  FROM private.exam_prep_assessments a
  WHERE a.component_code='P5' AND a.assessment_type='learning' AND a.status='published'
    AND EXISTS(SELECT 1 FROM private.exam_prep_assessment_items ai WHERE ai.assessment_id=a.id)
  ORDER BY a.id LIMIT 1;

  IF v_p1 IS NULL OR v_p5 IS NULL THEN
    RAISE EXCEPTION 'P2-72 governed P1/P5 learning fixtures required';
  END IF;

  INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
  VALUES(v_uid,'authenticated','authenticated','p272-'||replace(v_uid::text,'-','')||'@invalid.example',now(),now(),false,false);
  INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
  VALUES(v_uid,'P272','LegacyFirewall','en',now(),false);

  INSERT INTO private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from
  ) VALUES(v_uid,'active',true,false,false,now()-interval '1 minute');

  UPDATE private.exam_prep_feature_config
  SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
  WHERE id=1;

  PERFORM set_config('request.jwt.claim.sub',v_uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);
  PERFORM public.save_exam_prep_exam_profile_v2('CI_P272_LEGACY_FIREWALL','A',12,6);

  PERFORM pg_temp.p272_finish_session_v1(v_uid,v_p1,'P1','p1-learning');
  PERFORM pg_temp.p272_finish_session_v1(v_uid,v_p5,'P5','p5-learning');

  -- Exercise additional stateful Core paths without touching legacy storage.
  PERFORM private.rebuild_exam_prep_state_v1(v_uid,null);
  PERFORM public.generate_exam_prep_weekly_plan_safe_v3('P1');
  PERFORM public.generate_exam_prep_weekly_plan_safe_v3('P5');
END
$$;

SELECT pg_temp.p272_capture_legacy_v1('after');

DO $$
DECLARE v_diff record;
BEGIN
  SELECT b.object_name,b.row_count before_count,a.row_count after_count,b.row_hash before_hash,a.row_hash after_hash
  INTO v_diff
  FROM p272_legacy_fingerprint b
  JOIN p272_legacy_fingerprint a USING(object_name)
  WHERE b.phase='before' AND a.phase='after'
    AND (b.row_count<>a.row_count OR b.row_hash<>a.row_hash)
  ORDER BY b.object_name
  LIMIT 1;

  IF v_diff.object_name IS NOT NULL THEN
    RAISE EXCEPTION 'P2-72 legacy mutation detected table=% count %->% hash %->%',
      v_diff.object_name,v_diff.before_count,v_diff.after_count,v_diff.before_hash,v_diff.after_hash;
  END IF;
END
$$;

ROLLBACK;

SELECT 'P2-72 legacy preservation firewall v2 matrix: GREEN' AS result;
