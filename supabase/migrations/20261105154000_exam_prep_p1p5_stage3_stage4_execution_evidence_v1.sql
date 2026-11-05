-- Issue #450 P4-03. Additive guarded upgrade of Stage3/4 PRACTICE EXECUTION
-- qualification only; no Cambridge written marks or assessed-readiness claims.
-- This is an unmerged DRAFT migration. Never apply to live without release GO.
-- Preserve all existing source predicates, syllabus rules, timing, integrity,
-- correction requirements and evidence; change exactly THREE call sites.
BEGIN;

DO $p4_03$
DECLARE
  v_spec record;
  v_oid oid;
  v_source text;
  v_modified text;
  v_old CONSTANT text := 'private.exam_prep_timed_score_comparable_v1(t.session_id)';
  v_new CONSTANT text := 'private.exam_prep_timed_execution_comparable_v1(t.session_id)';
  v_replacements int;
BEGIN
  IF to_regprocedure('private.exam_prep_timed_execution_comparable_v1(uuid)') IS NULL
  THEN
    RAISE EXCEPTION 'P4-03 requires P4-02 execution comparator';
  END IF;
  IF NOT has_function_privilege('service_role',
       'private.exam_prep_timed_execution_comparable_v1(uuid)', 'EXECUTE')
     OR has_function_privilege('anon',
       'private.exam_prep_timed_execution_comparable_v1(uuid)', 'EXECUTE')
     OR has_function_privilege('authenticated',
       'private.exam_prep_timed_execution_comparable_v1(uuid)', 'EXECUTE')
  THEN
    RAISE EXCEPTION 'P4-03 requires private service-only execution contract';
  END IF;

  FOR v_spec IN
    SELECT * FROM (VALUES
      ('private.exam_prep_stage3_exit_status_v1(uuid,bigint,text)',
        's.session_type=''paper''',
        't.attempt_kind=''full_paper''',
        't.strict_timing'),
      ('private.exam_prep_stage4_raw_evidence_v1(uuid,bigint,text)',
        's.session_type=''paper''',
        't.attempt_kind=''full_paper''',
        'a.status=''published'''),
      ('private.exam_prep_stage4_timed_section_gate_v1(uuid,bigint,text,text)',
        't.attempt_kind=''timed_section''',
        't.strict_timing',
        'sc.required')
    ) AS spec(signature,required_1,required_2,required_3)
  LOOP
    v_oid := to_regprocedure(v_spec.signature);
    IF v_oid IS NULL THEN
      RAISE EXCEPTION 'P4-03 missing original evaluator %',v_spec.signature;
    END IF;
    v_source := pg_get_functiondef(v_oid);
    v_replacements := (length(v_source)-length(replace(v_source,v_old,''))) / length(v_old);
    IF v_replacements<>1
       OR position(v_spec.required_1 IN v_source)=0
       OR position(v_spec.required_2 IN v_source)=0
       OR position(v_spec.required_3 IN v_source)=0
       OR position('SECURITY DEFINER' IN upper(v_source))=0
       OR position('search_path TO ''''' IN v_source)=0
    THEN
      RAISE EXCEPTION
        'P4-03 source guard mismatch in %, scored comparator occurrences %',
        v_spec.signature,v_replacements;
    END IF;

    v_modified:=replace(v_source,v_old,v_new);
    -- Re-compile in place, preserving original signature, existing thresholds,
    -- exact family grouping, privileges and unrelated source clauses.
    EXECUTE v_modified;
    IF position(v_old IN pg_get_functiondef(v_oid))<>0
       OR position(v_new IN pg_get_functiondef(v_oid))=0
    THEN
      RAISE EXCEPTION 'P4-03 execution comparator source proof failed %',v_spec.signature;
    END IF;
  END LOOP;
END;
$p4_03$;

-- Maintain explicit service-only grants even when deployed atop inherited schemas.
REVOKE ALL ON FUNCTION private.exam_prep_stage3_exit_status_v1(uuid,bigint,text)
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.exam_prep_stage4_raw_evidence_v1(uuid,bigint,text)
  FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.exam_prep_stage4_timed_section_gate_v1(uuid,bigint,text,text)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_stage3_exit_status_v1(uuid,bigint,text)
  TO service_role;
GRANT EXECUTE ON FUNCTION private.exam_prep_stage4_raw_evidence_v1(uuid,bigint,text)
  TO service_role;
GRANT EXECUTE ON FUNCTION private.exam_prep_stage4_timed_section_gate_v1(uuid,bigint,text,text)
  TO service_role;

-- Intentionally unchanged: private.exam_prep_timed_score_comparable_v1,
-- all original scored marks/thresholds, Stage5 and Stage6 readiness.
COMMIT;
