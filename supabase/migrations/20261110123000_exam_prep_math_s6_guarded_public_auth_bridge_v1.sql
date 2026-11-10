-- Mathematics P1/P5 Issue #450 v2.2 S6 source-only, NOT production release.
-- Guarded integration of S5 OFF-only access into existing Core entry authorizer.
-- Current controlled-beta access remains identical while independent
-- public_math_core_enabled=false (S5 default). No AI/Mentor upgrades.
-- No user rows, skill states, attempts or historical data changed.
-- Can be applied only after S5 20261110120000 source migration; never
-- reimport S2 migration already contained in S3 PR #520.
BEGIN;

DO $s6bridge$
DECLARE
 v_sig regprocedure;
 v_old_def text;
 v_new_def text;
 v_anchor text;
 v_replacement text;
 v_matches int;
BEGIN
 IF to_regprocedure('private.exam_prep_s5_public_math_eligible_v1(uuid)') IS NULL THEN
   RAISE EXCEPTION 'S6 missing S5 public Math eligibility predicate';
 END IF;
 IF NOT EXISTS (
   SELECT 1 FROM private.exam_prep_public_math_s5_config_v1
    WHERE singleton AND NOT public_math_core_enabled AND public_math_kill_switch
 ) THEN
   RAISE EXCEPTION 'S6 requires S5 public access OFF and independent kill-switch ON';
 END IF;
 v_sig:=to_regprocedure('private.exam_prep_require_core_access_v1()');
 IF v_sig IS NULL THEN
   RAISE EXCEPTION 'S6 missing deployed legacy beta authorizer';
 END IF;
 v_old_def:=pg_get_functiondef(v_sig);
 -- Guard exact existing ownership + beta entitlement path. No global
 -- replace or guessed substring within a different security policy.
 IF strpos(v_old_def,'private.exam_prep_feature_config c')=0 OR
    strpos(v_old_def,'c.program_key=''math_as_p1_p5''')=0 OR
    strpos(v_old_def,'AND NOT c.kill_switch')=0 OR
    strpos(v_old_def,'private.exam_prep_feature_entitlements e')=0 OR
    strpos(v_old_def,'e.core_access')=0 OR
    strpos(v_old_def,'auth.uid()')=0 OR
    strpos(v_old_def,'public.users u')=0
 THEN
   RAISE EXCEPTION 'S6 legacy authorization source changed; manual source review required';
 END IF;

 v_anchor:=E'        c.qa_open_all_core\n        OR EXISTS(';
 v_replacement:=E'        c.qa_open_all_core\n        OR private.exam_prep_s5_public_math_eligible_v1(v_uid)\n        OR EXISTS(';
 v_matches:=(length(v_old_def)-length(replace(v_old_def,v_anchor,'')))
            / nullif(length(v_anchor),0);
 IF v_matches<>1 OR position(v_anchor IN v_old_def)=0 THEN
   RAISE EXCEPTION 'S6 legacy core beta anchor mismatch: matches=%', v_matches;
 END IF;
 v_new_def:=replace(v_old_def,v_anchor,v_replacement);
 IF v_new_def=v_old_def THEN RAISE EXCEPTION 'S6 no authorization diff created'; END IF;
 EXECUTE v_new_def;
 -- Source-only defence: a broadened owner-bound path must still be
 -- callable ONLY through the original security definer and its old grants.
 IF to_regprocedure('private.exam_prep_require_core_access_v1()') IS NULL THEN
   RAISE EXCEPTION 'S6 failed to preserve legacy auth signature';
 END IF;
END;
$s6bridge$;

COMMIT;
