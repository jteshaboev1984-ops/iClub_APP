-- P0-16 learner-consent gate acceptance matrix.
-- Requires the full current schema and PGOPTIONS='-c p016.current_schema=true'.
-- Test-only: all synthetic mutations are transaction-local and end in ROLLBACK.
--
-- Proves:
-- 1) cohort approval is rejected while any candidate lacks explicit consent;
-- 2) direct server-side member approval cannot bypass the consent guard;
-- 3) explicit consent records unlock governance approval but grant zero access;
-- 4) a consented Core-only wave may activate normally;
-- 5) revoking consent from a live learner immediately fail-closes the whole beta;
-- 6) all synthetic users/cohorts/consents roll back with zero residue.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p016.current_schema',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P0-16 CONSENT MATRIX REFUSED: p016.current_schema=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE p016g_people(
  ord integer PRIMARY KEY,
  user_id uuid NOT NULL UNIQUE,
  service_mode text NOT NULL,
  activation_wave smallint NOT NULL
) ON COMMIT DROP;

INSERT INTO p016g_people(ord,user_id,service_mode,activation_wave) VALUES
  (1,gen_random_uuid(),'core',1),
  (2,gen_random_uuid(),'ai_assist',2),
  (3,gen_random_uuid(),'mentor_care',3);

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       format('p016g-%s-%s@invalid.example',ord,replace(user_id::text,'-','')),
       now(),now(),false,false
FROM p016g_people;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P016 Consent',ord::text,'en',now(),false
FROM p016g_people;

GRANT SELECT ON TABLE p016g_people TO service_role;

SET LOCAL ROLE service_role;
SELECT public.stage_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_consent_01',3::smallint,
  'P0-16 isolated learner-consent gate regression.'
);

SELECT public.set_exam_prep_beta_member_v1(
  'math_as_p1_p5_beta_consent_01',p.user_id,p.service_mode,p.activation_wave
)
FROM p016g_people p ORDER BY p.ord;

-- Governance approval must fail until every candidate has an explicit grant.
DO $$
DECLARE v_expected boolean:=false;
BEGIN
  BEGIN
    PERFORM public.approve_exam_prep_controlled_beta_v1('math_as_p1_p5_beta_consent_01');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'exam_prep_beta_consent_required:%'
       OR SQLERRM LIKE 'exam_prep_beta_consent_required_for_candidates=%' THEN
      v_expected:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_expected THEN
    RAISE EXCEPTION 'P0-16 consent matrix expected approval without consent to fail';
  END IF;
END
$$;

-- Defense in depth: direct service-role status mutation cannot bypass consent.
DO $$
DECLARE v_uid uuid; v_cohort bigint; v_expected boolean:=false;
BEGIN
  SELECT user_id INTO v_uid FROM p016g_people WHERE ord=1;
  SELECT id INTO v_cohort FROM private.exam_prep_beta_cohorts
  WHERE cohort_key='math_as_p1_p5_beta_consent_01';
  BEGIN
    UPDATE private.exam_prep_beta_members
    SET member_status='approved'
    WHERE cohort_id=v_cohort AND user_id=v_uid;
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM LIKE 'exam_prep_beta_consent_required:%' THEN
      v_expected:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_expected THEN
    RAISE EXCEPTION 'P0-16 consent matrix direct member approval bypassed consent';
  END IF;
END
$$;

-- Record explicit consent for each allowlisted learner. Evidence refs are opaque
-- test identifiers; the gate does not require PII to be copied into the record.
SELECT public.record_exam_prep_beta_consent_v1(
  'math_as_p1_p5_beta_consent_01',p.user_id,
  format('p016g-consent-evidence-%s',p.ord),now()
)
FROM p016g_people p ORDER BY p.ord;

DO $$
DECLARE v jsonb;
BEGIN
  SELECT public.get_exam_prep_beta_consent_status_v1('math_as_p1_p5_beta_consent_01') INTO v;
  IF (v->>'members')::int<>3
     OR (v->>'granted')::int<>3
     OR (v->>'revoked')::int<>0
     OR (v->>'missing')::int<>0
     OR coalesce((v->>'consent_complete')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P0-16 consent matrix completeness mismatch: %',v;
  END IF;
END
$$;

SELECT public.approve_exam_prep_controlled_beta_v1('math_as_p1_p5_beta_consent_01');
RESET ROLE;

-- Consent + approval is still governance only: no access before a live wave.
DO $$
DECLARE v_cfg record; v_approved int; v_ent int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 consent approval changed feature state: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_approved
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_consent_01' AND m.member_status='approved';
  IF v_approved<>3 THEN
    RAISE EXCEPTION 'P0-16 consent approval expected 3 approved members, got %',v_approved;
  END IF;
  SELECT count(*) INTO v_ent
  FROM private.exam_prep_feature_entitlements e
  JOIN p016g_people p ON p.user_id=e.user_id
  WHERE e.entitlement_status='active';
  IF v_ent<>0 THEN
    RAISE EXCEPTION 'P0-16 consent approval leaked % active entitlements',v_ent;
  END IF;
END
$$;

-- Wave 1 contains only the consented Core learner and must activate normally.
SET LOCAL ROLE service_role;
SELECT public.activate_exam_prep_controlled_beta_wave_v1(
  'math_as_p1_p5_beta_consent_01',1::smallint
);
RESET ROLE;

DO $$
DECLARE v_cfg record; v_active int; v_core_ent int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta' OR v_cfg.kill_switch OR NOT v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled THEN
    RAISE EXCEPTION 'P0-16 consent Core canary config mismatch: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_active
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_consent_01' AND m.member_status='active';
  IF v_active<>1 THEN
    RAISE EXCEPTION 'P0-16 consent Core canary expected 1 active member, got %',v_active;
  END IF;
  SELECT count(*) INTO v_core_ent
  FROM private.exam_prep_feature_entitlements e
  JOIN p016g_people p ON p.user_id=e.user_id
  WHERE p.ord=1 AND e.entitlement_status='active' AND e.core_access AND NOT e.ai_assist AND NOT e.mentor_care_entitled;
  IF v_core_ent<>1 THEN
    RAISE EXCEPTION 'P0-16 consent Core canary entitlement mismatch count=%',v_core_ent;
  END IF;
END
$$;

-- A live learner can revoke consent. The revocation must immediately use the
-- existing global emergency-pause path and remove all active access.
SET LOCAL ROLE service_role;
SELECT public.revoke_exam_prep_beta_consent_v1(
  'math_as_p1_p5_beta_consent_01',
  (SELECT user_id FROM p016g_people WHERE ord=1),
  'p016g-live-revocation-evidence'
);
RESET ROLE;

DO $$
DECLARE v_cfg record; v_status text; v_active int; v_ent int; v_consent text;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 live consent revocation did not fail-close config: %',row_to_json(v_cfg);
  END IF;
  SELECT cohort_status INTO v_status
  FROM private.exam_prep_beta_cohorts
  WHERE cohort_key='math_as_p1_p5_beta_consent_01';
  IF v_status<>'paused' THEN
    RAISE EXCEPTION 'P0-16 live consent revocation expected paused cohort, got %',v_status;
  END IF;
  SELECT count(*) INTO v_active
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='math_as_p1_p5_beta_consent_01' AND m.member_status='active';
  IF v_active<>0 THEN
    RAISE EXCEPTION 'P0-16 live consent revocation left % active members',v_active;
  END IF;
  SELECT count(*) INTO v_ent
  FROM private.exam_prep_feature_entitlements e
  JOIN p016g_people p ON p.user_id=e.user_id
  WHERE e.entitlement_status='active';
  IF v_ent<>0 THEN
    RAISE EXCEPTION 'P0-16 live consent revocation left % active entitlements',v_ent;
  END IF;
  SELECT c.consent_status INTO v_consent
  FROM private.exam_prep_beta_consents c
  JOIN p016g_people p ON p.user_id=c.user_id
  WHERE p.ord=1;
  IF v_consent<>'revoked' THEN
    RAISE EXCEPTION 'P0-16 live consent revocation status mismatch=%',v_consent;
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_cfg record; v_users int; v_cohorts int; v_consents int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 consent matrix post-rollback config not fail-closed: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_users FROM auth.users WHERE email like 'p016g-%@invalid.example';
  SELECT count(*) INTO v_cohorts FROM private.exam_prep_beta_cohorts WHERE cohort_key='math_as_p1_p5_beta_consent_01';
  SELECT count(*) INTO v_consents
  FROM private.exam_prep_beta_consents c
  JOIN private.exam_prep_beta_cohorts b ON b.id=c.cohort_id
  WHERE b.cohort_key='math_as_p1_p5_beta_consent_01';
  IF v_users<>0 OR v_cohorts<>0 OR v_consents<>0 THEN
    RAISE EXCEPTION 'P0-16 consent matrix synthetic residue users=% cohorts=% consents=%',v_users,v_cohorts,v_consents;
  END IF;
END
$$;

\echo 'P0-16 learner consent matrix: GREEN (approval/activation gated; live revoke fail-closes)'
