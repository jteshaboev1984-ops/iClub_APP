-- Issue #450 P4-05: a real timed/paper result is written AFTER session
-- status finalization. The prior stage rebuild on status transition can
-- therefore run before the timed results exist, leaving Stage4/5 stale.
-- Surgical addition only AFTER durable result insert, not a stage override.
-- DRAFT/unmerged. No historical backfill and no release GO.
BEGIN;

DO $p4_05$
DECLARE
  v_oid oid:='public.finalize_exam_prep_timed_safe_v1(uuid,text,text)'::regprocedure;
  v_source text;
  v_now text;
  v_anchor CONSTANT text :=
    'return public.get_exam_prep_timed_result_safe_v1(v_s.id) || jsonb_build_object(''replayed'',false);';
  v_hook CONSTANT text :=
    'if v_kind in (''full_paper'',''timed_section'') and v_timing_comp and v_answered>0 then'
    || chr(10) ||
    '    perform private.rebuild_exam_prep_state_v1(v_uid,v_s.component_code);'
    || chr(10) ||
    '  end if;'
    || chr(10) ||
    '  ';
  v_hits int;
BEGIN
  v_source:=pg_get_functiondef(v_oid);
  IF v_source IS NULL
    OR position('private.exam_prep_require_core_access_v1()' in v_source)=0
    OR position('insert into private.exam_prep_timed_attempt_results' in lower(v_source))=0
    OR position('SECURITY DEFINER' in upper(v_source))=0
    OR position('search_path TO ''''' in v_source)=0
    OR position('rebuild_exam_prep_state_v1(v_uid,v_s.component_code)' in v_source)>0
    OR to_regprocedure('private.rebuild_exam_prep_state_v1(uuid,text)') IS NULL
  THEN RAISE EXCEPTION 'P4-05 timed finalizer source or rebuild dependency drift'; END IF;
  v_hits:=(length(v_source)-length(replace(v_source,v_anchor,'')))/length(v_anchor);
  IF v_hits<>1
  THEN RAISE EXCEPTION 'P4-05 cannot add post-ledger refresh safely: return anchor count %',v_hits;
  END IF;

  -- Exact original finalizer preserved, including frozen ownership, idempotent
  -- replays, timer integrity, mark decomposition, published content and ACL.
  -- Only the FIRST genuine finalized Paper/section with answered items rebuilds
  -- after its immutable result exists. Blank/admin stopped attempts never earn a stage.
  EXECUTE replace(v_source,v_anchor,v_hook||v_anchor);
  v_now:=pg_get_functiondef(v_oid);
  IF position('perform private.rebuild_exam_prep_state_v1(v_uid,v_s.component_code);' in v_now)=0
    OR position(v_anchor in v_now)=0
  THEN RAISE EXCEPTION 'P4-05 finalizer post-ledger repair not installed'; END IF;
END
$p4_05$;

REVOKE ALL ON FUNCTION public.finalize_exam_prep_timed_safe_v1(uuid,text,text)
  FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.finalize_exam_prep_timed_safe_v1(uuid,text,text)
  TO authenticated,service_role;
COMMIT;
