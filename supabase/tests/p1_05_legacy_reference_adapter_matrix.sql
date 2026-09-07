-- P1-05 legacy reference adapter isolated acceptance matrix.
-- Synthetic legacy rows only; everything in this fixture rolls back.

\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE p105_user(user_id uuid primary key) ON COMMIT DROP;
INSERT INTO p105_user VALUES(gen_random_uuid());
GRANT SELECT ON p105_user TO authenticated,service_role;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated','p105-legacy-'||replace(user_id::text,'-','')||'@invalid.example',now(),now(),false,false
FROM p105_user;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P105','Legacy Reference','en',now(),false FROM p105_user;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;

INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from)
SELECT user_id,'active',true,false,false,now() FROM p105_user;

DO $$
DECLARE
  v_uid uuid;
  v_q1 bigint;
  v_q2 bigint;
  v_pa bigint;
  v_tour bigint;
  v_ta bigint;
BEGIN
  SELECT user_id INTO v_uid FROM p105_user;

  SELECT m.question_id INTO v_q1
  FROM private.exam_prep_question_skill_map m
  JOIN private.exam_prep_question_mapping_versions mv ON mv.id=m.mapping_version_id
  WHERE mv.mapping_version='p1_existing_bank_v1' AND mv.status='active'
    AND m.mapping_role='primary' AND m.approval_status='approved'
  ORDER BY m.question_id LIMIT 1;

  SELECT m.question_id INTO v_q2
  FROM private.exam_prep_question_skill_map m
  JOIN private.exam_prep_question_mapping_versions mv ON mv.id=m.mapping_version_id
  WHERE mv.mapping_version='p1_existing_bank_v1' AND mv.status='active'
    AND m.mapping_role='primary' AND m.approval_status='approved'
    AND m.question_id<>v_q1
  ORDER BY m.question_id LIMIT 1;

  IF v_q1 IS NULL OR v_q2 IS NULL THEN RAISE EXCEPTION 'P1-05 approved P1 fixture mappings missing'; END IF;

  INSERT INTO public.practice_attempts(user_id,subject_id,is_lab)
  VALUES(v_uid,5,false) RETURNING id INTO v_pa;
  INSERT INTO public.practice_answers(attempt_id,question_id,user_answer,is_correct,time_spent,created_at)
  VALUES(v_pa,v_q1,'synthetic',true,31,now()-interval '5 days');

  INSERT INTO public.tours(subject_id) VALUES(5) RETURNING id INTO v_tour;
  INSERT INTO public.tour_attempts(user_id,tour_id) VALUES(v_uid,v_tour) RETURNING id INTO v_ta;
  INSERT INTO public.tour_answers(attempt_id,question_id,user_answer,answered,is_correct,time_spent,finish_reason,created_at)
  VALUES(v_ta,v_q2,'synthetic',true,false,42,'submitted',now()-interval '4 days');
END
$$;

CREATE TEMP TABLE p105_before AS
SELECT
  (SELECT count(*) FROM public.practice_attempts) practice_attempts,
  (SELECT count(*) FROM public.practice_answers) practice_answers,
  (SELECT count(*) FROM public.tour_attempts) tour_attempts,
  (SELECT count(*) FROM public.tour_answers) tour_answers,
  (SELECT count(*) FROM public.certificates) certificates,
  (SELECT count(*) FROM public.ratings_cache) ratings_cache,
  (SELECT count(*) FROM private.exam_prep_evidence_events) evidence_events,
  (SELECT count(*) FROM private.exam_prep_stage_states) stage_states;

SET LOCAL ROLE service_role;
DO $$
DECLARE v jsonb;
BEGIN
  v:=public.sync_exam_prep_legacy_references_v1('p1_existing_bank_v1');
  IF (v->>'inserted_total')::int<>2 OR (v->>'practice_inserted')::int<>1 OR (v->>'tour_inserted')::int<>1 THEN
    RAISE EXCEPTION 'P1-05 first sync expected 2 references: %',v;
  END IF;

  v:=public.sync_exam_prep_legacy_references_v1('p1_existing_bank_v1');
  IF (v->>'inserted_total')::int<>0 THEN
    RAISE EXCEPTION 'P1-05 idempotent sync inserted duplicates: %',v;
  END IF;

  v:=public.set_exam_prep_legacy_reference_adapter_v1('p1_existing_bank_v1','active');
  IF v->>'adapter_status'<>'active' THEN RAISE EXCEPTION 'P1-05 adapter did not activate: %',v; END IF;
END
$$;
RESET ROLE;

DO $$
DECLARE v_count int;
BEGIN
  SELECT count(*) INTO v_count
  FROM private.exam_prep_legacy_evidence_references r
  WHERE r.user_id=(SELECT user_id FROM p105_user);
  IF v_count<>2 THEN RAISE EXCEPTION 'P1-05 expected 2 legacy references got %',v_count; END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_legacy_evidence_references r
    WHERE r.user_id=(SELECT user_id FROM p105_user)
      AND (r.source_type<>'legacy_readonly' OR r.academic_credit OR r.verification_claim<>'none' OR r.component_code<>'P1')
  ) THEN
    RAISE EXCEPTION 'P1-05 non-crediting/component contract violated';
  END IF;

  IF EXISTS(
    SELECT 1
    FROM private.exam_prep_legacy_evidence_references r
    LEFT JOIN private.exam_prep_question_skill_map m
      ON m.mapping_version_id=r.mapping_version_id AND m.question_id=r.question_id AND m.skill_code=r.skill_code
     AND m.mapping_role='primary' AND m.approval_status='approved'
    WHERE r.user_id=(SELECT user_id FROM p105_user) AND m.id IS NULL
  ) THEN
    RAISE EXCEPTION 'P1-05 reference escaped approved active mapping';
  END IF;
END
$$;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p105_user),true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE v jsonb;
BEGIN
  v:=public.get_exam_prep_legacy_reference_summary_safe_v1('P1');
  IF coalesce((v->>'available')::boolean,false) IS NOT TRUE
     OR (v->>'reference_count')::int<>2
     OR (v->>'academic_credit')::boolean IS DISTINCT FROM false
     OR v->>'mastery_effect'<>'none'
     OR v->>'source_type'<>'legacy_readonly'
     OR v->>'mapping_version'<>'p1_existing_bank_v1' THEN
    RAISE EXCEPTION 'P1-05 learner safe summary contract failed: %',v;
  END IF;

  v:=public.get_exam_prep_legacy_reference_summary_safe_v1('P5');
  IF (v->>'available')::boolean IS DISTINCT FROM false OR (v->>'reference_count')::int<>0 THEN
    RAISE EXCEPTION 'P1-05 P5 must remain unavailable without active P5 legacy mapping: %',v;
  END IF;
END
$$;
RESET ROLE;

DO $$
DECLARE b record; a record;
BEGIN
  SELECT * INTO b FROM p105_before;
  SELECT
    (SELECT count(*) FROM public.practice_attempts) practice_attempts,
    (SELECT count(*) FROM public.practice_answers) practice_answers,
    (SELECT count(*) FROM public.tour_attempts) tour_attempts,
    (SELECT count(*) FROM public.tour_answers) tour_answers,
    (SELECT count(*) FROM public.certificates) certificates,
    (SELECT count(*) FROM public.ratings_cache) ratings_cache,
    (SELECT count(*) FROM private.exam_prep_evidence_events) evidence_events,
    (SELECT count(*) FROM private.exam_prep_stage_states) stage_states
  INTO a;
  IF row_to_json(a)::text<>row_to_json(b)::text THEN
    RAISE EXCEPTION 'P1-05 adapter mutated legacy/academic state before=% after=%',row_to_json(b),row_to_json(a);
  END IF;
END
$$;

DO $$
BEGIN
  IF has_table_privilege('authenticated','private.exam_prep_legacy_evidence_references','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_legacy_reference_configs','SELECT') THEN
    RAISE EXCEPTION 'P1-05 authenticated has direct private legacy adapter table access';
  END IF;
  IF has_function_privilege('anon','public.get_exam_prep_legacy_reference_summary_safe_v1(text)','EXECUTE') THEN
    RAISE EXCEPTION 'P1-05 anon can execute learner legacy summary';
  END IF;
  IF has_function_privilege('authenticated','public.sync_exam_prep_legacy_references_v1(text)','EXECUTE')
     OR has_function_privilege('authenticated','public.set_exam_prep_legacy_reference_adapter_v1(text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P1-05 learner can mutate legacy adapter';
  END IF;
END
$$;

ROLLBACK;

\echo 'P1-05 legacy reference adapter matrix: GREEN'
