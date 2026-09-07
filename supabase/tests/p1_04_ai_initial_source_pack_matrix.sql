-- P1-04 initial AI context source pack acceptance matrix.
-- Requires the P1-04 AI foundation plus 20260907103000_exam_prep_ai_initial_context_source_pack_v1.sql.
-- Read-only assertions only.

\set ON_ERROR_STOP on

DO $$
DECLARE
  v_total int;
  v_bad int;
  v_generation boolean;
  v_runtime text;
BEGIN
  SELECT count(*) INTO v_total
  FROM private.exam_prep_ai_source_cards
  WHERE source_version='iclub_ai_context_v1_2026_09_07';
  IF v_total<>12 THEN
    RAISE EXCEPTION 'P1-04 source pack expected 12 cards, got %',v_total;
  END IF;

  SELECT count(*) INTO v_bad
  FROM private.exam_prep_ai_source_cards
  WHERE source_version='iclub_ai_context_v1_2026_09_07'
    AND (
      approval_status<>'approved'
      OR rights_status<>'original_iclub'
      OR NOT is_runtime_allowed
      OR component_code NOT IN ('P1','P5')
      OR locale NOT IN ('ru','uz','en')
      OR card_type NOT IN ('progress_context','weekly_plan_context')
      OR skill_code IS NOT NULL
      OR char_length(content_hash)<>64
    );
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'P1-04 source pack contains invalid governance rows=%',v_bad;
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_ai_source_cards WHERE source_version='iclub_ai_context_v1_2026_09_07' AND component_code='P1')<>6 THEN
    RAISE EXCEPTION 'P1-04 P1 source-card count drifted';
  END IF;
  IF (SELECT count(*) FROM private.exam_prep_ai_source_cards WHERE source_version='iclub_ai_context_v1_2026_09_07' AND component_code='P5')<>6 THEN
    RAISE EXCEPTION 'P1-04 P5 source-card count drifted';
  END IF;

  IF EXISTS (
    SELECT 1 FROM (VALUES ('ru'),('uz'),('en')) l(locale)
    WHERE (SELECT count(*) FROM private.exam_prep_ai_source_cards c WHERE c.source_version='iclub_ai_context_v1_2026_09_07' AND c.locale=l.locale)<>4
  ) THEN
    RAISE EXCEPTION 'P1-04 trilingual source-card symmetry failed';
  END IF;

  SELECT generation_enabled INTO v_generation FROM private.exam_prep_ai_policy WHERE id=1;
  SELECT runtime_status INTO v_runtime FROM private.exam_prep_optional_capability_status WHERE capability_code='ai_assist';
  IF v_generation OR v_runtime<>'shadow' THEN
    RAISE EXCEPTION 'P1-04 source pack must not enable generation/runtime ready generation=% runtime=%',v_generation,v_runtime;
  END IF;

  IF (SELECT count(*) FROM private.exam_prep_evidence_events)<>0
     OR (SELECT count(*) FROM private.exam_prep_stage_states)<>0
     OR (SELECT count(*) FROM private.exam_prep_sessions)<>0 THEN
    RAISE EXCEPTION 'P1-04 source pack changed academic/session state';
  END IF;
END
$$;

DO $$
BEGIN
  IF has_function_privilege('anon','public.get_exam_prep_ai_source_cards_service_v1(text,text,text,text,integer)','EXECUTE') THEN
    RAISE EXCEPTION 'P1-04 anon can execute service source reader';
  END IF;
  IF has_function_privilege('authenticated','public.get_exam_prep_ai_source_cards_service_v1(text,text,text,text,integer)','EXECUTE') THEN
    RAISE EXCEPTION 'P1-04 authenticated can execute service source reader';
  END IF;
  IF has_table_privilege('authenticated','private.exam_prep_ai_source_cards','SELECT') THEN
    RAISE EXCEPTION 'P1-04 authenticated can directly read AI source cards';
  END IF;
END
$$;

SET LOCAL ROLE service_role;
DO $$
DECLARE
  v jsonb;
BEGIN
  v:=public.get_exam_prep_ai_source_cards_service_v1('P1','en','progress_context',null,8);
  IF jsonb_array_length(v)<>1 OR v#>>'{0,component_code}'<>'P1' OR v#>>'{0,locale}'<>'en' OR v#>>'{0,card_type}'<>'progress_context' THEN
    RAISE EXCEPTION 'P1-04 P1 EN progress source retrieval failed: %',v;
  END IF;

  v:=public.get_exam_prep_ai_source_cards_service_v1('P5','ru','weekly_plan_context',null,8);
  IF jsonb_array_length(v)<>1 OR v#>>'{0,component_code}'<>'P5' OR v#>>'{0,locale}'<>'ru' OR v#>>'{0,card_type}'<>'weekly_plan_context' THEN
    RAISE EXCEPTION 'P1-04 P5 RU plan source retrieval failed: %',v;
  END IF;

  v:=public.get_exam_prep_ai_source_cards_service_v1('P1','uz','weekly_plan_context',null,8);
  IF jsonb_array_length(v)<>1 OR v#>>'{0,component_code}'<>'P1' OR v#>>'{0,locale}'<>'uz' THEN
    RAISE EXCEPTION 'P1-04 P1 UZ plan source retrieval failed: %',v;
  END IF;
END
$$;
RESET ROLE;

\echo 'P1-04 initial AI context source pack matrix: GREEN'
