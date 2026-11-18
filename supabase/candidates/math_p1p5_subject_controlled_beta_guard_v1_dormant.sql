-- DORMANT SECURITY CANDIDATE ONLY (#526 / #450).
-- Not a Supabase migration; never apply to production without new owner GO,
-- live impact check and a proper versioned migration created by Supabase CLI.
-- Current beta QA may allow a registered non-Mathematics learner to call Core
-- directly. This reuses only the existing public.user_subjects (subject_id=5)
-- and preserves every existing entitlement, QA flag, learner row and stage.
-- Direct Core and public capabilities must agree across controlled_beta,
-- expanded_beta and mass. internal_alpha remains unchanged.
-- Existing already installed 20261115100103 release guard is prerequisite.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='30s';

DO $math_beta_existing_subject_guard$
DECLARE
  v_private regprocedure := to_regprocedure('private.exam_prep_require_core_access_v1()');
  v_public regprocedure := to_regprocedure('public.get_exam_prep_capabilities_v1()');
  v_priv text;
  v_pub text;
  v_old_priv constant text := 'c.rollout_state NOT IN (''expanded_beta'',''mass'')';
  v_new_priv constant text := 'c.rollout_state NOT IN (''controlled_beta'',''expanded_beta'',''mass'')';
  v_old_pub constant text := 'e.rollout_state NOT IN (''expanded_beta'',''mass'')';
  v_new_pub constant text := 'e.rollout_state NOT IN (''controlled_beta'',''expanded_beta'',''mass'')';
  v_hits integer;
BEGIN
  IF v_private IS NULL OR v_public IS NULL
     OR to_regclass('public.user_subjects') IS NULL
     OR NOT EXISTS(SELECT 1 FROM public.subjects WHERE id=5 AND subject_key='mathematics')
  THEN
    RAISE EXCEPTION 'math_beta_subject_guard_missing_authoritative_dependency';
  END IF;
  v_priv := pg_get_functiondef(v_private);
  v_pub := pg_get_functiondef(v_public);

  IF position('iclub_math_subject_release_guard_v1' in v_priv)=0
     OR position('iclub_math_subject_release_guard_v1' in v_pub)=0
  THEN
    RAISE EXCEPTION 'math_beta_subject_guard_prior_release_guard_missing';
  END IF;

  v_hits:=(length(v_priv)-length(replace(v_priv,v_old_priv,'')))/length(v_old_priv);
  IF v_hits<>1 THEN RAISE EXCEPTION 'math_beta_private_anchor_drift_%',v_hits; END IF;
  v_hits:=(length(v_pub)-length(replace(v_pub,v_old_pub,'')))/length(v_old_pub);
  IF v_hits<>5 THEN RAISE EXCEPTION 'math_beta_capabilities_anchor_drift_%',v_hits; END IF;

  -- ALTER nothing else: replace these two exact expressions only.
  -- The existing caller auth, entitlement, Math subject check, Core kill
  -- switch, AI/Mentor flags, owner and security_definer remain intact.
  EXECUTE replace(v_priv,v_old_priv,v_new_priv);
  EXECUTE replace(v_pub,v_old_pub,v_new_pub);

  IF position(v_new_priv in pg_get_functiondef(v_private))=0
     OR position(v_new_pub in pg_get_functiondef(v_public))=0
  THEN
    RAISE EXCEPTION 'math_beta_subject_guard_postcondition_failed';
  END IF;
END
$math_beta_existing_subject_guard$;

COMMIT;
