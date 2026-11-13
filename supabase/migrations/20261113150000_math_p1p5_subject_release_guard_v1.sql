-- #450 / #526: use existing Mathematics selection for expanded/mass Core
-- DEFAULT CONTROLLED BETA IS NOT CHANGED by this migration.
-- NO new tables, grants, roles, feature flags, user rewrites or progress updates.
-- The two existing authority functions keep their signatures, SECURITY DEFINER,
-- owners, grants, and search_path. Exact source-anchor counts are fail-closed.
-- Preparation ONLY: deployment/activation needs a separate owner release GO.

DO $math_release_guard$
DECLARE
  v_private regprocedure := to_regprocedure('private.exam_prep_require_core_access_v1()');
  v_public regprocedure := to_regprocedure('public.get_exam_prep_capabilities_v1()');
  v_source text;
  v_next text;
  v_anchor text;
  v_hits integer;
  v_predicate text;
BEGIN
  IF v_private IS NULL OR v_public IS NULL OR to_regclass('public.user_subjects') IS NULL THEN
    RAISE EXCEPTION 'math_subject_release_guard_missing_existing_dependency';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.subjects WHERE id=5 AND subject_key='mathematics'
  ) THEN
    RAISE EXCEPTION 'math_subject_release_guard_subject_5_mismatch';
  END IF;

  v_source := pg_get_functiondef(v_private);
  IF position('iclub_math_subject_release_guard_v1' in v_source)>0 THEN
    RAISE EXCEPTION 'math_subject_release_guard_private_already_present';
  END IF;
  v_anchor := 'AND c.rollout_state<>''off''';
  v_hits := (length(v_source)-length(replace(v_source,v_anchor,'')))/length(v_anchor);
  IF v_hits<>1 THEN
    RAISE EXCEPTION 'math_subject_release_guard_private_anchor_drift: %',v_hits;
  END IF;
  v_predicate := $private_predicate$
      -- iclub_math_subject_release_guard_v1: existing subject selection, NOT a new entitlement
      AND (
        c.rollout_state NOT IN ('expanded_beta','mass')
        OR EXISTS (
          SELECT 1 FROM public.user_subjects us
          WHERE us.user_id=v_uid AND us.subject_id=5
        )
      )
$private_predicate$;
  v_next := replace(v_source,v_anchor,v_anchor||chr(10)||v_predicate);
  EXECUTE v_next;

  v_source := pg_get_functiondef(v_public);
  IF position('iclub_math_subject_release_guard_v1' in v_source)>0 THEN
    RAISE EXCEPTION 'math_subject_release_guard_public_already_present';
  END IF;
  v_anchor := 'AND e.rollout_state<>''off''';
  v_hits := (length(v_source)-length(replace(v_source,v_anchor,'')))/length(v_anchor);
  IF v_hits<>5 THEN
    RAISE EXCEPTION 'math_subject_release_guard_public_anchor_drift: %',v_hits;
  END IF;
  v_predicate := $public_predicate$
      -- iclub_math_subject_release_guard_v1: existing selection for public rollout
      AND (
        e.rollout_state NOT IN ('expanded_beta','mass')
        OR EXISTS (
          SELECT 1 FROM public.user_subjects us
          WHERE us.user_id=e.user_id AND us.subject_id=5
        )
      )
$public_predicate$;
  v_next := replace(v_source,v_anchor,v_anchor||chr(10)||v_predicate);
  EXECUTE v_next;

  IF (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
      WHERE n.nspname='private' AND p.proname='exam_prep_require_core_access_v1'
        AND pg_get_functiondef(p.oid) LIKE '%iclub_math_subject_release_guard_v1%') <> 1
     OR (SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
      WHERE n.nspname='public' AND p.proname='get_exam_prep_capabilities_v1'
        AND pg_get_functiondef(p.oid) LIKE '%iclub_math_subject_release_guard_v1%') <> 1 THEN
    RAISE EXCEPTION 'math_subject_release_guard_postcondition_failed';
  END IF;
END
$math_release_guard$;
