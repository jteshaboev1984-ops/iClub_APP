-- Issue #450 P0-16B: two actual dashboard reads rebuild placement/gates.
-- Keep their old-token read payloads, but never write through stale JWT epoch.
-- No activation, history edits, feature changes or production deployment.
BEGIN;
DO $guard$
DECLARE
  v_sig text; v_oid regprocedure; v_src text; v_new text;
  v_anchor CONSTANT text :=
     'perform private.rebuild_exam_prep_placement_v1(v_uid,p_component_code);';
  v_hits int;
BEGIN
  IF to_regprocedure('private.exam_prep_writer_epoch_current_v1()') IS NULL
  THEN RAISE EXCEPTION 'P0-16B missing signed epoch predicate'; END IF;
  FOREACH v_sig IN ARRAY ARRAY[
    'public.get_exam_prep_placement_safe_v1(text)',
    'public.get_exam_prep_diagnostic_progress_safe_v1(text)'
  ] LOOP
    v_oid:=to_regprocedure(v_sig);
    IF v_oid IS NULL THEN RAISE EXCEPTION 'P0-16B missing real read-projection RPC: %',v_sig; END IF;
    v_src:=pg_get_functiondef(v_oid);
    v_hits:=(length(v_src)-length(replace(v_src,v_anchor,'')))/length(v_anchor);
    IF v_hits<>1
       OR position('private.exam_prep_require_core_access_v1()' in v_src)=0
       OR position('SECURITY DEFINER' in upper(v_src))=0
       OR position('search_path TO ''''' in v_src)=0
       OR position('exam_prep_writer_epoch_current_v1' in v_src)>0
       OR has_function_privilege('anon',v_oid,'EXECUTE')
    THEN RAISE EXCEPTION 'P0-16B read writer/source drift: %, anchors=%',v_sig,v_hits; END IF;
    v_new:=replace(v_src,v_anchor,
      'if private.exam_prep_writer_epoch_current_v1() then'||chr(10)||
      '    '||v_anchor||chr(10)||'  end if;');
    EXECUTE v_new;
    IF position('if private.exam_prep_writer_epoch_current_v1() then'
       in pg_get_functiondef(v_oid))=0
       OR NOT has_function_privilege('authenticated',v_oid,'EXECUTE')
       OR has_function_privilege('anon',v_oid,'EXECUTE')
    THEN RAISE EXCEPTION 'P0-16B did not fence read-projection writer: %',v_sig; END IF;
  END LOOP;
END
$guard$;
COMMIT;
