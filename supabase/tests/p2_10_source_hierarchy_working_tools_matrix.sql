-- P2-10 / C21 source hierarchy + working tools matrix.
-- Synthetic Core learner only; all learner/config changes are rolled back.
\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE p210_user(user_id uuid primary key) ON COMMIT DROP;
INSERT INTO p210_user VALUES(gen_random_uuid());
GRANT SELECT ON p210_user TO authenticated,service_role;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated','p210-'||replace(user_id::text,'-','')||'@invalid.example',now(),now(),false,false
FROM p210_user;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P210','Source Hierarchy','en',now(),false FROM p210_user;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;

INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from
)
SELECT user_id,'active',true,false,false,now() FROM p210_user;

CREATE TEMP TABLE p210_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_evidence_events WHERE user_id=(SELECT user_id FROM p210_user)) evidence_events,
  (SELECT count(*) FROM private.exam_prep_skill_states WHERE user_id=(SELECT user_id FROM p210_user)) skill_states,
  (SELECT count(*) FROM private.exam_prep_stage_states WHERE user_id=(SELECT user_id FROM p210_user)) stage_states,
  (SELECT count(*) FROM private.exam_prep_correction_cases WHERE user_id=(SELECT user_id FROM p210_user)) correction_cases,
  (SELECT count(*) FROM private.exam_prep_timed_attempt_results WHERE user_id=(SELECT user_id FROM p210_user)) timed_results,
  (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=(SELECT user_id FROM p210_user)) weekly_plans,
  (SELECT count(*) FROM public.practice_attempts WHERE user_id=(SELECT user_id FROM p210_user)) practice_attempts,
  (SELECT count(*) FROM public.tour_attempts WHERE user_id=(SELECT user_id FROM p210_user)) tour_attempts,
  (SELECT count(*) FROM public.certificates) certificates;

DO $$
DECLARE
  v_active_sources int;
  v_active_levels int;
  v_materials int;
BEGIN
  SELECT count(*),count(distinct source_level)
    INTO v_active_sources,v_active_levels
  FROM private.exam_prep_source_registry
  WHERE status='active';

  IF v_active_sources<>6 OR v_active_levels<>6 THEN
    RAISE EXCEPTION 'P2-10 expected six active source categories across levels 1..6, got sources=% levels=%',v_active_sources,v_active_levels;
  END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_source_registry
    WHERE source_level=1 AND status='active' AND can_define_scope AND can_define_coverage_denominator
  ) THEN RAISE EXCEPTION 'P2-10 level 1 scope/denominator authority missing'; END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_source_registry
    WHERE status='active' AND source_level<>1 AND (can_define_scope OR can_define_coverage_denominator)
  ) THEN RAISE EXCEPTION 'P2-10 lower source gained scope authority'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_source_registry
    WHERE source_level=3 AND status='active' AND can_support_assessment_evidence
  ) OR NOT EXISTS(
    SELECT 1 FROM private.exam_prep_source_registry
    WHERE source_level=4 AND status='active' AND can_support_assessment_evidence
  ) THEN RAISE EXCEPTION 'P2-10 L3/L4 assessment-evidence support missing'; END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_source_registry
    WHERE status='active' AND can_support_assessment_evidence AND source_level NOT IN (3,4)
  ) THEN RAISE EXCEPTION 'P2-10 invalid evidence authority outside L3/L4'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_source_registry
    WHERE source_level=6 AND status='active' AND downstream_only
  ) THEN RAISE EXCEPTION 'P2-10 downstream-only source level 6 missing'; END IF;

  IF EXISTS(SELECT 1 FROM private.exam_prep_syllabus_nodes WHERE source_level<>1)
     OR EXISTS(SELECT 1 FROM private.exam_prep_component_paper_profiles WHERE source_level<>1)
     OR EXISTS(SELECT 1 FROM private.exam_prep_exam_calendar WHERE source_level<>1)
     OR EXISTS(SELECT 1 FROM private.exam_prep_content_versions WHERE source_level<>3)
     OR EXISTS(SELECT 1 FROM private.exam_prep_paper_metadata WHERE source_level<>4)
     OR EXISTS(SELECT 1 FROM private.exam_prep_threshold_references WHERE source_level<>4)
     OR EXISTS(SELECT 1 FROM private.exam_prep_ai_source_cards WHERE source_level<>6) THEN
    RAISE EXCEPTION 'P2-10 structural source-level mapping mismatch';
  END IF;

  SELECT count(*) INTO v_materials
  FROM private.exam_prep_material_library
  WHERE status='active';
  IF v_materials<>5 THEN RAISE EXCEPTION 'P2-10 expected five governed material records, got %',v_materials; END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_material_library
    WHERE access_mode IN ('licensed_reference','school_request') AND official_url IS NOT NULL
  ) THEN RAISE EXCEPTION 'P2-10 protected/licensed material exposes a URL'; END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_material_library
    WHERE access_mode='official_external' AND coalesce(official_url,'') !~ '^https://'
  ) THEN RAISE EXCEPTION 'P2-10 official material link is not safe https'; END IF;
END
$$;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p210_user),true);
SET LOCAL ROLE authenticated;

DO $$
DECLARE
  v_materials jsonb;
  v_tools jsonb;
BEGIN
  v_materials:=public.get_exam_prep_materials_library_safe_v1('en');
  IF jsonb_array_length(v_materials->'materials')<>5
     OR (v_materials->>'rights_respected')::boolean IS DISTINCT FROM true
     OR (v_materials->>'protected_content_embedded')::boolean IS DISTINCT FROM false
     OR (v_materials->>'official_links_open_externally')::boolean IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'P2-10 safe Materials Library contract failed: %',v_materials;
  END IF;

  IF v_materials::text LIKE '%source_level%' OR v_materials::text LIKE '%rights_status%' THEN
    RAISE EXCEPTION 'P2-10 learner Materials Library leaked internal source/rights fields: %',v_materials;
  END IF;

  IF EXISTS(
    SELECT 1 FROM jsonb_array_elements(v_materials->'materials') x
    WHERE x->>'access_mode'='licensed_reference' AND x->>'external_url' IS NOT NULL
  ) THEN RAISE EXCEPTION 'P2-10 licensed reference leaked external URL'; END IF;

  IF EXISTS(
    SELECT 1 FROM jsonb_array_elements(v_materials->'materials') x
    WHERE x->>'access_mode'='official_external' AND coalesce(x->>'external_url','') !~ '^https://'
  ) THEN RAISE EXCEPTION 'P2-10 official external material missing safe URL'; END IF;

  v_tools:=public.get_exam_prep_working_tools_safe_v1();
  IF v_tools->>'contract_version'<>'p2_10_c21_v1'
     OR (v_tools->>'read_only')::boolean IS DISTINCT FROM true
     OR (v_tools->>'p1_p5_separate')::boolean IS DISTINCT FROM true
     OR (v_tools->>'legacy_state_mutated')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-10 working tools top-level contract failed: %',v_tools;
  END IF;

  IF v_tools->'exam_map'->>'status'<>'required' THEN
    RAISE EXCEPTION 'P2-10 synthetic learner without profile should require Exam Map: %',v_tools->'exam_map';
  END IF;

  IF (v_tools->'syllabus_tracker'->'P1'->>'denominator_count')::int<>45
     OR (v_tools->'syllabus_tracker'->'P5'->>'denominator_count')::int<>36 THEN
    RAISE EXCEPTION 'P2-10 P1/P5 canonical denominators drifted: %',v_tools->'syllabus_tracker';
  END IF;

  IF (v_tools->'score_tracker'->'P1'->>'timed_or_paper_attempts')::int<>0
     OR (v_tools->'score_tracker'->'P5'->>'timed_or_paper_attempts')::int<>0
     OR (v_tools->'score_tracker'->'P1'->>'full_papers')::int<>0
     OR (v_tools->'score_tracker'->'P5'->>'full_papers')::int<>0 THEN
    RAISE EXCEPTION 'P2-10 working tools invented score evidence: %',v_tools->'score_tracker';
  END IF;

  IF (v_tools->'error_journal'->'P1'->>'active_count')::int<>0
     OR (v_tools->'error_journal'->'P5'->>'active_count')::int<>0 THEN
    RAISE EXCEPTION 'P2-10 working tools invented corrections: %',v_tools->'error_journal';
  END IF;

  IF (v_tools->'materials_library'->>'active_materials')::int<>5
     OR (v_tools->'materials_library'->>'protected_content_embedded')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-10 working tools Materials Library summary failed: %',v_tools->'materials_library';
  END IF;

  IF (v_tools->'weekly_plan'->'P1'->>'has_active_plan')::boolean IS DISTINCT FROM false
     OR (v_tools->'weekly_plan'->'P5'->>'has_active_plan')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-10 working tools invented weekly plan state: %',v_tools->'weekly_plan';
  END IF;
END
$$;

RESET ROLE;

DO $$
DECLARE
  v_uid uuid;
  b record;
  a record;
BEGIN
  SELECT user_id INTO v_uid FROM p210_user;
  SELECT * INTO b FROM p210_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_evidence_events WHERE user_id=v_uid) evidence_events,
    (SELECT count(*) FROM private.exam_prep_skill_states WHERE user_id=v_uid) skill_states,
    (SELECT count(*) FROM private.exam_prep_stage_states WHERE user_id=v_uid) stage_states,
    (SELECT count(*) FROM private.exam_prep_correction_cases WHERE user_id=v_uid) correction_cases,
    (SELECT count(*) FROM private.exam_prep_timed_attempt_results WHERE user_id=v_uid) timed_results,
    (SELECT count(*) FROM private.exam_prep_weekly_plans WHERE user_id=v_uid) weekly_plans,
    (SELECT count(*) FROM public.practice_attempts WHERE user_id=v_uid) practice_attempts,
    (SELECT count(*) FROM public.tour_attempts WHERE user_id=v_uid) tour_attempts,
    (SELECT count(*) FROM public.certificates) certificates
  INTO a;

  IF row_to_json(a)::text<>row_to_json(b)::text THEN
    RAISE EXCEPTION 'P2-10 read-only tools mutated learner/legacy state before=% after=%',row_to_json(b),row_to_json(a);
  END IF;

  IF has_table_privilege('authenticated','private.exam_prep_source_registry','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_material_library','SELECT') THEN
    RAISE EXCEPTION 'P2-10 authenticated can directly read private registry/material tables';
  END IF;

  IF has_function_privilege('anon','public.get_exam_prep_materials_library_safe_v1(text)','EXECUTE')
     OR has_function_privilege('anon','public.get_exam_prep_working_tools_safe_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'P2-10 anon can execute Core working-tool functions';
  END IF;

  IF NOT has_function_privilege('authenticated','public.get_exam_prep_materials_library_safe_v1(text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.get_exam_prep_working_tools_safe_v1()','EXECUTE') THEN
    RAISE EXCEPTION 'P2-10 authenticated Core cannot execute safe working-tool functions';
  END IF;
END
$$;

ROLLBACK;

DO $$
BEGIN
  IF EXISTS(select 1 from auth.users where email like 'p210-%@invalid.example') THEN
    RAISE EXCEPTION 'P2-10 synthetic auth residue found';
  END IF;
  IF EXISTS(select 1 from public.users where first_name='P210' and last_name='Source Hierarchy') THEN
    RAISE EXCEPTION 'P2-10 synthetic public user residue found';
  END IF;
END
$$;

\echo 'P2-10 source hierarchy + working tools matrix: GREEN'
