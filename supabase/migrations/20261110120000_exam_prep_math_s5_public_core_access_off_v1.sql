-- iClub Issue #450, v2.2 S5: OPTIONAL FUTURE PUBLIC Mathematics Core channel.
-- SOURCE-ONLY DRAFT, always OFF. Existing controlled-beta and user data unchanged.
-- This migration adds a new independent flag and versioned auth readers;
-- it DOES NOT replace legacy private.exam_prep_require_core_access_v1(),
-- change other subject access, update legacy feature_config or enable public Math.
-- Owner/architect separate mass GO and an S6 integrated acceptance required.
BEGIN;

CREATE TABLE IF NOT EXISTS private.exam_prep_public_math_s5_config_v1 (
  singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
  public_math_core_enabled boolean NOT NULL DEFAULT false,
  public_math_kill_switch boolean NOT NULL DEFAULT true,
  owner_go_reference text,
  owner_go_recorded_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK(NOT public_math_core_enabled OR (
    NOT public_math_kill_switch
    AND owner_go_recorded_at IS NOT NULL
    AND owner_go_reference IS NOT NULL
    AND length(btrim(owner_go_reference)) >= 16
  ))
);
INSERT INTO private.exam_prep_public_math_s5_config_v1(
 singleton,public_math_core_enabled,public_math_kill_switch
) VALUES(true,false,true)
ON CONFLICT(singleton) DO NOTHING;
ALTER TABLE private.exam_prep_public_math_s5_config_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_public_math_s5_config_v1
  FROM PUBLIC,anon,authenticated;

-- P1/P5 = Mathematics subject id 5 ONLY.
-- This is a future public-eligibility predicate, NOT a beta availability test.
CREATE OR REPLACE FUNCTION private.exam_prep_s5_public_math_eligible_v1(
  p_user_id uuid
) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $s5eligible$
  SELECT coalesce((
    SELECT cfg.public_math_core_enabled
      AND NOT cfg.public_math_kill_switch
      AND cfg.owner_go_recorded_at IS NOT NULL
      AND cfg.owner_go_reference IS NOT NULL
      AND f.core_enabled AND NOT f.kill_switch
      AND f.rollout_state <> 'off'
      AND EXISTS(
        SELECT 1 FROM public.users u
        WHERE u.id=p_user_id
      )
      AND EXISTS(
        SELECT 1 FROM public.user_subjects us
        WHERE us.user_id=p_user_id
          AND us.subject_id=5
          AND us.mode IN ('study','competitive')
      )
    FROM private.exam_prep_public_math_s5_config_v1 cfg
    JOIN private.exam_prep_feature_config f
      ON f.program_key='math_as_p1_p5'
    WHERE cfg.singleton
  ),false);
$s5eligible$;
REVOKE ALL ON FUNCTION private.exam_prep_s5_public_math_eligible_v1(uuid)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_s5_public_math_eligible_v1(uuid)
 TO service_role;

-- Strict PUBLIC Mathematics path; it never falls back to QA open-all or
-- beta entitlements. No other subject can use this public entitlement.
CREATE OR REPLACE FUNCTION private.exam_prep_s5_require_public_math_v1()
RETURNS uuid
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $s5require$
DECLARE v_uid uuid;
BEGIN
 v_uid:=auth.uid();
 IF v_uid IS NULL THEN
  RAISE EXCEPTION 'exam_prep_auth_required' USING ERRCODE='28000';
 END IF;
 IF coalesce(auth.jwt()->>'is_anonymous','false')='true' THEN
  RAISE EXCEPTION 'exam_prep_s5_registered_user_required'
    USING ERRCODE='42501';
 END IF;
 IF NOT private.exam_prep_s5_public_math_eligible_v1(v_uid) THEN
  RAISE EXCEPTION 'exam_prep_s5_public_math_unavailable'
    USING ERRCODE='42501';
 END IF;
 RETURN v_uid;
END;
$s5require$;
REVOKE ALL ON FUNCTION private.exam_prep_s5_require_public_math_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_s5_require_public_math_v1()
 TO service_role;

-- Staging-friendly future unification: preserve exactly the legacy beta
-- authorization when the new independent public switch is OFF.
-- DO NOT replace old authorizer or wire this into all existing RPCs
-- until S6 source integration and separate architect GO.
CREATE OR REPLACE FUNCTION private.exam_prep_s5_require_beta_or_public_math_v1()
RETURNS uuid
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $s5compatible$
DECLARE v_uid uuid;
BEGIN
 v_uid:=auth.uid();
 IF v_uid IS NULL THEN
  RAISE EXCEPTION 'exam_prep_auth_required' USING ERRCODE='28000';
 END IF;
 IF coalesce(auth.jwt()->>'is_anonymous','false')<>'true'
    AND private.exam_prep_s5_public_math_eligible_v1(v_uid) THEN
  RETURN v_uid;
 END IF;
 -- Use the real deployed beta policy; no copied QA/entitlement rule drift.
 RETURN private.exam_prep_require_core_access_v1();
END;
$s5compatible$;
REVOKE ALL ON FUNCTION private.exam_prep_s5_require_beta_or_public_math_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_s5_require_beta_or_public_math_v1()
 TO service_role;

-- Authenticated read-only user status. No cross-user selectors, no entitlement
-- writes, no costs, no AI/Mentor enablement. Public switch is OFF by default.
CREATE OR REPLACE FUNCTION public.get_exam_prep_s5_public_math_status_safe_v1()
RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $s5status$
DECLARE v_uid uuid;v_registered boolean;v_enrolled boolean;v_public boolean;
 v_flag boolean;v_legacy_beta boolean;
BEGIN
 v_uid:=auth.uid();
 IF v_uid IS NULL THEN RAISE EXCEPTION 'exam_prep_auth_required'
  USING ERRCODE='28000'; END IF;
 v_registered:=EXISTS(SELECT 1 FROM public.users u WHERE u.id=v_uid)
   AND coalesce(auth.jwt()->>'is_anonymous','false')<>'true';
 v_enrolled:=v_registered AND EXISTS(
   SELECT 1 FROM public.user_subjects us
   WHERE us.user_id=v_uid AND us.subject_id=5
     AND us.mode IN('study','competitive')
 );
 SELECT public_math_core_enabled AND NOT public_math_kill_switch
 INTO v_flag FROM private.exam_prep_public_math_s5_config_v1 WHERE singleton;
 v_public:=v_registered AND
   private.exam_prep_s5_public_math_eligible_v1(v_uid);
 -- Report old beta condition only as a separate read-only fact. It may
 -- remain available independently of the new S5 flag.
 SELECT EXISTS(
  SELECT 1 FROM private.exam_prep_feature_config f
  WHERE f.program_key='math_as_p1_p5' AND f.core_enabled
    AND f.rollout_state<>'off' AND NOT f.kill_switch
    AND (f.qa_open_all_core OR EXISTS(
      SELECT 1 FROM private.exam_prep_feature_entitlements e
      WHERE e.user_id=v_uid AND e.entitlement_status='active'
        AND e.core_access
        AND (e.valid_from IS NULL OR e.valid_from<=now())
        AND (e.valid_until IS NULL OR e.valid_until>now())))
 ) INTO v_legacy_beta;
 RETURN jsonb_build_object(
  'version','public_math_s5_v1','registered',v_registered,
  'mathematics_enrolled',v_enrolled,
  'public_math_core_enabled',coalesce(v_flag,false),
  'public_mathematics_access',v_public,
  'controlled_beta_access',v_registered AND v_legacy_beta,
  'full_paper_method_marks_verified',false,
  'new_ai_marking_enabled',false,'mentor_marking_required',false,
  'student_self_scoring',false,
  'other_subjects_unmodified',true);
END;
$s5status$;
REVOKE ALL ON FUNCTION public.get_exam_prep_s5_public_math_status_safe_v1()
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_s5_public_math_status_safe_v1()
 TO authenticated,service_role;

COMMIT;
