-- P2-03 Past Paper Companion isolated acceptance matrix.
-- All learner mutations roll back. The migration's two approved metadata rows
-- are baseline content and remain in the ephemeral database after this test.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p203.isolated_db',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P2-03 REFUSED: p203.isolated_db=true is required';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE p203_user(user_id uuid primary key) ON COMMIT DROP;
INSERT INTO p203_user VALUES(gen_random_uuid());
GRANT SELECT ON p203_user TO authenticated,service_role;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated','p203-'||replace(user_id::text,'-','')||'@invalid.example',now(),now(),false,false FROM p203_user;
INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P203','Learner','en',now(),false FROM p203_user;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;
INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
)
SELECT user_id,'active',true,false,false,'p203-companion',now() FROM p203_user;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p203_user),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);

CREATE TEMP TABLE p203_payloads(component_code text primary key,payload jsonb) ON COMMIT DROP;
INSERT INTO p203_payloads VALUES
('P1',public.get_exam_prep_past_paper_companion_safe_v1('P1','en')),
('P5',public.get_exam_prep_past_paper_companion_safe_v1('P5','ru'));

DO $$
DECLARE p1 jsonb; p5 jsonb; v_bad int; v_p1_full int; v_p5_full int; v_p1_similar int; v_p5_similar int;
BEGIN
  SELECT payload INTO p1 FROM p203_payloads WHERE component_code='P1';
  SELECT payload INTO p5 FROM p203_payloads WHERE component_code='P5';

  IF p1->>'component_code'<>'P1' OR (p1->>'paper_number')::int<>1 THEN
    RAISE EXCEPTION 'P2-03 P1 identity mismatch %',p1;
  END IF;
  IF p5->>'component_code'<>'P5' OR (p5->>'paper_number')::int<>5 THEN
    RAISE EXCEPTION 'P2-03 P5 identity mismatch %',p5;
  END IF;
  IF jsonb_array_length(p1->'external_resources')<>1 OR jsonb_array_length(p5->'external_resources')<>1 THEN
    RAISE EXCEPTION 'P2-03 official portal metadata count mismatch P1=% P5=%',jsonb_array_length(p1->'external_resources'),jsonb_array_length(p5->'external_resources');
  END IF;

  v_p1_full:=jsonb_array_length(p1->'original_full_simulations');
  v_p5_full:=jsonb_array_length(p5->'original_full_simulations');
  v_p1_similar:=jsonb_array_length(p1->'similar_practice');
  v_p5_similar:=jsonb_array_length(p5->'similar_practice');
  IF v_p1_full<1 OR v_p5_full<1 OR v_p1_full<>v_p5_full THEN
    RAISE EXCEPTION 'P2-03 original full simulation availability/symmetry mismatch P1=% P5=%',v_p1_full,v_p5_full;
  END IF;
  IF v_p1_similar<1 OR v_p5_similar<1 OR v_p1_similar<>v_p5_similar THEN
    RAISE EXCEPTION 'P2-03 similar practice availability/symmetry mismatch P1=% P5=%',v_p1_similar,v_p5_similar;
  END IF;

  IF coalesce((p1#>>'{copyright_boundary,stores_official_question_content}')::boolean,true)
     OR coalesce((p1#>>'{copyright_boundary,stores_official_mark_schemes}')::boolean,true)
     OR coalesce((p1#>>'{copyright_boundary,stores_official_answer_keys}')::boolean,true)
     OR coalesce((p1#>>'{copyright_boundary,external_metadata_only}')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P2-03 copyright boundary failed %',p1->'copyright_boundary';
  END IF;

  IF p1::text ~* '(correct_answer|answer_key|mark_scheme|question_text|rubric_json|examiner_report)' OR
     p5::text ~* '(correct_answer|answer_key|mark_scheme|question_text|rubric_json|examiner_report)' THEN
    RAISE EXCEPTION 'P2-03 protected content key leaked in safe payload';
  END IF;

  SELECT count(*) INTO v_bad
  FROM jsonb_array_elements(p1->'external_resources') x
  WHERE x->>'official_url' NOT LIKE 'https://www.cambridgeinternational.org/%'
     OR x->>'rights_status'<>'metadata_only_external';
  IF v_bad<>0 THEN RAISE EXCEPTION 'P2-03 P1 unsafe external resource rows=%',v_bad; END IF;

  SELECT count(*) INTO v_bad
  FROM jsonb_array_elements(p5->'external_resources') x
  WHERE x->>'official_url' NOT LIKE 'https://www.cambridgeinternational.org/%'
     OR x->>'rights_status'<>'metadata_only_external';
  IF v_bad<>0 THEN RAISE EXCEPTION 'P2-03 P5 unsafe external resource rows=%',v_bad; END IF;

  SELECT count(*) INTO v_bad
  FROM jsonb_array_elements(p1->'original_full_simulations') a
  JOIN jsonb_array_elements(p5->'original_full_simulations') b
    ON (a->>'assessment_id')::bigint=(b->>'assessment_id')::bigint;
  IF v_bad<>0 THEN RAISE EXCEPTION 'P2-03 P1/P5 simulation leakage rows=%',v_bad; END IF;
END
$$;

DO $$
BEGIN
  BEGIN
    PERFORM public.get_exam_prep_past_paper_companion_safe_v1('P3','en');
    RAISE EXCEPTION 'P2-03 invalid component was accepted';
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM NOT LIKE '%exam_prep_invalid_component%' THEN RAISE; END IF;
  END;
END
$$;

SET LOCAL ROLE authenticated;
DO $$
BEGIN
  BEGIN
    PERFORM 1 FROM private.exam_prep_paper_metadata LIMIT 1;
    RAISE EXCEPTION 'P2-03 authenticated direct private-table read unexpectedly succeeded';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
END
$$;
RESET ROLE;

ROLLBACK;

DO $$
DECLARE v_n int; v_cfg record;
BEGIN
  SELECT count(*) INTO v_n FROM auth.users WHERE email LIKE 'p203-%@invalid.example';
  IF v_n<>0 THEN RAISE EXCEPTION 'P2-03 rollback synthetic users=%',v_n; END IF;
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P2-03 rollback feature boundary=%',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_n FROM private.exam_prep_paper_metadata WHERE publication_status='approved';
  IF v_n<>2 THEN RAISE EXCEPTION 'P2-03 migration metadata unexpectedly changed after rollback rows=%',v_n; END IF;
END
$$;

SELECT 'P2-03 Past Paper Companion matrix: PASS (metadata-only Cambridge links, original iClub full simulations/practice available, P1/P5 isolated)' AS result;
