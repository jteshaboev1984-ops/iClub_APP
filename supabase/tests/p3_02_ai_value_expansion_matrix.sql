-- P3-02 AI value expansion matrix.
-- Rollback-only: validates repeated-error/theory contexts, source coverage and zero mutation by read paths.
\set ON_ERROR_STOP on

DO $guard$
BEGIN
  IF current_setting('p302.value_expansion_isolated',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P3-02 AI value matrix requires p302.value_expansion_isolated=true';
  END IF;
END
$guard$;

BEGIN;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;

CREATE TEMP TABLE p302v_people(
  ord integer primary key,
  user_id uuid not null unique
) ON COMMIT DROP;

INSERT INTO p302v_people(ord,user_id)
VALUES (1,gen_random_uuid()),(2,gen_random_uuid());

GRANT SELECT ON p302v_people TO authenticated,service_role;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       format('exam-prep-p302v-%s-%s@invalid.example',ord,replace(user_id::text,'-','')),
       now(),now(),false,false
FROM p302v_people;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P302','AI Value '||ord::text,'en',now(),false
FROM p302v_people;

INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from
)
SELECT user_id,'active',true,true,false,now()
FROM p302v_people;

INSERT INTO private.exam_prep_correction_cases(
  user_id,component_code,skill_code,status,engine_version,reason,opened_at,updated_at
)
SELECT user_id,'P1','P1-QUA-02','remediating','objective_state_v1',
       '{"source":"finalized_incorrect_evidence"}'::jsonb,now()-interval '2 days',now()-interval '1 hour'
FROM p302v_people WHERE ord=1
UNION ALL
SELECT user_id,'P5','P5-NOR-02','reopened','objective_state_v1',
       '{"source":"finalized_incorrect_evidence"}'::jsonb,now()-interval '3 days',now()-interval '30 minutes'
FROM p302v_people WHERE ord=1;

INSERT INTO private.exam_prep_skill_states(
  user_id,program_version_id,component_code,skill_code,engine_version,
  objective_level,coverage_confirmed,evidence_total,objective_evidence_count,
  correct_objective_count,unresolved_correction_count
)
SELECT p.user_id,pv.id,'P1','P1-QUA-02','objective_state_v1',
       0,false,1,1,0,1
FROM p302v_people p
JOIN private.exam_prep_program_versions pv
  ON pv.program_key='math_as_p1_p5'
 AND pv.version_key='p1_p5_canonical_v1_0'
 AND pv.status='active'
WHERE p.ord=1
UNION ALL
SELECT p.user_id,pv.id,'P5','P5-NOR-02','objective_state_v1',
       1,false,2,2,1,1
FROM p302v_people p
JOIN private.exam_prep_program_versions pv
  ON pv.program_key='math_as_p1_p5'
 AND pv.version_key='p1_p5_canonical_v1_0'
 AND pv.status='active'
WHERE p.ord=1;

CREATE TEMP TABLE p302v_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_evidence_events) AS evidence_count,
  (SELECT count(*) FROM private.exam_prep_skill_states) AS skill_state_count,
  (SELECT count(*) FROM private.exam_prep_stage_states) AS stage_state_count,
  (SELECT count(*) FROM private.exam_prep_component_placements) AS placement_count,
  (SELECT count(*) FROM private.exam_prep_correction_cases) AS correction_count,
  (SELECT count(*) FROM private.exam_prep_retest_events) AS retest_count,
  (SELECT count(*) FROM private.exam_prep_readiness_signoffs) AS readiness_count;

DO $priv$
BEGIN
  IF has_function_privilege('anon','public.get_exam_prep_ai_repeated_error_context_safe_v1(text,text)','EXECUTE')
     OR has_function_privilege('anon','public.get_exam_prep_ai_skill_theory_context_safe_v1(text,text,text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.get_exam_prep_ai_repeated_error_context_safe_v1(text,text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.get_exam_prep_ai_skill_theory_context_safe_v1(text,text,text)','EXECUTE')
     OR has_function_privilege('authenticated','private.exam_prep_ai_repeated_error_context_payload_v1(uuid,text,text)','EXECUTE')
     OR has_function_privilege('authenticated','private.exam_prep_ai_skill_theory_context_payload_v1(uuid,text,text,text)','EXECUTE')
  THEN
    RAISE EXCEPTION 'P3-02 AI value privilege boundary failed';
  END IF;
END
$priv$;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p302v_people WHERE ord=1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;

DO $learner$
DECLARE
  v jsonb;
  v_locale text;
BEGIN
  v:=public.get_exam_prep_ai_repeated_error_context_safe_v1('P1','en');
  IF coalesce((v->>'mapped')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'repeated_gap_count')::int,0)<>1
     OR v#>>'{items,0,skill_code}'<>'P1-QUA-02'
     OR lower(v::text) LIKE '%correct_answer%'
     OR lower(v::text) LIKE '%answer_key%'
  THEN
    RAISE EXCEPTION 'P3-02 repeated-error P1 context failed: %',v;
  END IF;

  v:=public.get_exam_prep_ai_repeated_error_context_safe_v1('P5','ru');
  IF coalesce((v->>'mapped')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'repeated_gap_count')::int,0)<>1
     OR v#>>'{items,0,skill_code}'<>'P5-NOR-02'
  THEN
    RAISE EXCEPTION 'P3-02 repeated-error P5 context failed: %',v;
  END IF;

  FOREACH v_locale IN ARRAY ARRAY['en','ru','uz']::text[] LOOP
    v:=public.get_exam_prep_ai_skill_theory_context_safe_v1('P1','P1-QUA-02',v_locale);
    IF coalesce((v->>'mapped')::boolean,false) IS NOT TRUE
       OR v->>'skill_code'<>'P1-QUA-02'
       OR v->>'locale'<>v_locale
       OR v->>'description' IS NULL
       OR v#>>'{learner_context,status}'<>'needs_correction'
       OR coalesce((v#>>'{learner_context,attempt_count}')::int,-1)<>1
       OR coalesce((v#>>'{learner_context,correct_count}')::int,-1)<>0
       OR coalesce((v#>>'{learner_context,unresolved_correction_count}')::int,-1)<>1
    THEN
      RAISE EXCEPTION 'P3-02 theory P1 personalised context failed locale=% payload=%',v_locale,v;
    END IF;

    v:=public.get_exam_prep_ai_skill_theory_context_safe_v1('P5','P5-NOR-02',v_locale);
    IF coalesce((v->>'mapped')::boolean,false) IS NOT TRUE
       OR v->>'skill_code'<>'P5-NOR-02'
       OR v->>'locale'<>v_locale
       OR v->>'description' IS NULL
       OR v#>>'{learner_context,status}'<>'needs_correction'
       OR coalesce((v#>>'{learner_context,attempt_count}')::int,-1)<>2
       OR coalesce((v#>>'{learner_context,correct_count}')::int,-1)<>1
    THEN
      RAISE EXCEPTION 'P3-02 theory P5 personalised context failed locale=% payload=%',v_locale,v;
    END IF;
  END LOOP;

  v:=public.get_exam_prep_ai_skill_theory_context_safe_v1('P1','P1-QUA-01','en');
  IF coalesce((v->>'mapped')::boolean,false) IS NOT TRUE
     OR v->>'skill_code'<>'P1-QUA-01'
     OR v#>>'{learner_context,status}'<>'not_started'
     OR coalesce((v#>>'{learner_context,attempt_count}')::int,-1)<>0
     OR coalesce((v#>>'{learner_context,unresolved_correction_count}')::int,-1)<>0
  THEN
    RAISE EXCEPTION 'P3-02 newly covered theory skill did not map with safe learner context: %',v;
  END IF;
END
$learner$;

RESET ROLE;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p302v_people WHERE ord=2),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;

DO $none$
DECLARE v jsonb;
BEGIN
  v:=public.get_exam_prep_ai_repeated_error_context_safe_v1('P1','uz');
  IF coalesce((v->>'mapped')::boolean,true)
     OR v->>'reason'<>'no_repeated_gap'
  THEN
    RAISE EXCEPTION 'P3-02 no repeated-gap path did not fail closed: %',v;
  END IF;
END
$none$;

RESET ROLE;
SET LOCAL ROLE service_role;

DO $sources$
DECLARE
  v jsonb;
  v_locale text;
  v_key text;
BEGIN
  FOREACH v_locale IN ARRAY ARRAY['en','ru','uz']::text[] LOOP
    v:=public.get_exam_prep_ai_source_cards_service_v1('P1',v_locale,'theory','P1-QUA-02',8);
    IF jsonb_array_length(v)<>1 OR v#>>'{0,source_card_key}'<>'p1:P1-QUA-02:theory:'||v_locale||':v1' THEN
      RAISE EXCEPTION 'P3-02 P1 theory source isolation failed locale=% cards=%',v_locale,v;
    END IF;

    v:=public.get_exam_prep_ai_source_cards_service_v1('P5',v_locale,'theory','P5-NOR-02',8);
    IF jsonb_array_length(v)<>1 OR v#>>'{0,source_card_key}'<>'p5:P5-NOR-02:theory:'||v_locale||':v1' THEN
      RAISE EXCEPTION 'P3-02 P5 theory source isolation failed locale=% cards=%',v_locale,v;
    END IF;

    v:=public.get_exam_prep_ai_source_cards_service_v1('P1',v_locale,'error_explanation',null,8);
    v_key:='p1:repeated_error_summary:'||v_locale||':v1';
    IF NOT EXISTS(
      SELECT 1 FROM jsonb_array_elements(v) e WHERE e->>'source_card_key'=v_key
    ) THEN
      RAISE EXCEPTION 'P3-02 P1 repeated-error source missing locale=% cards=%',v_locale,v;
    END IF;

    v:=public.get_exam_prep_ai_source_cards_service_v1('P5',v_locale,'error_explanation',null,8);
    v_key:='p5:repeated_error_summary:'||v_locale||':v1';
    IF NOT EXISTS(
      SELECT 1 FROM jsonb_array_elements(v) e WHERE e->>'source_card_key'=v_key
    ) THEN
      RAISE EXCEPTION 'P3-02 P5 repeated-error source missing locale=% cards=%',v_locale,v;
    END IF;
  END LOOP;

  v:=public.get_exam_prep_ai_source_cards_service_v1('P1','en','theory','P1-QUA-01',8);
  IF jsonb_array_length(v)<>1
     OR v#>>'{0,source_card_key}'<>'p1:P1-QUA-01:theory:en:v1'
     OR v#>>'{0,source_version}'<>'p3_02_full_theory_pack_v1_2026_10_03'
  THEN
    RAISE EXCEPTION 'P3-02 newly covered theory source retrieval failed: %',v;
  END IF;
END
$sources$;

RESET ROLE;

DO $no_mutation$
DECLARE b record; a record;
BEGIN
  SELECT * INTO b FROM p302v_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_evidence_events) AS evidence_count,
    (SELECT count(*) FROM private.exam_prep_skill_states) AS skill_state_count,
    (SELECT count(*) FROM private.exam_prep_stage_states) AS stage_state_count,
    (SELECT count(*) FROM private.exam_prep_component_placements) AS placement_count,
    (SELECT count(*) FROM private.exam_prep_correction_cases) AS correction_count,
    (SELECT count(*) FROM private.exam_prep_retest_events) AS retest_count,
    (SELECT count(*) FROM private.exam_prep_readiness_signoffs) AS readiness_count
  INTO a;

  IF row_to_json(a)::text<>row_to_json(b)::text THEN
    RAISE EXCEPTION 'P3-02 AI read paths mutated academic state before=% after=%',row_to_json(b),row_to_json(a);
  END IF;
END
$no_mutation$;

ROLLBACK;

DO $cleanup$
DECLARE v_count integer;
BEGIN
  SELECT count(*) INTO v_count FROM auth.users WHERE email LIKE 'exam-prep-p302v-%@invalid.example';
  IF v_count<>0 THEN RAISE EXCEPTION 'P3-02 AI value rollback left auth users=%',v_count; END IF;
END
$cleanup$;

\echo 'P3-02 AI value expansion matrix: GREEN'
