-- P0-16 authenticated learner self-consent acceptance matrix.
-- Requires the full current schema and PGOPTIONS='-c p016.current_schema=true'.
-- Test-only: all synthetic mutations are transaction-local and end in ROLLBACK.
--
-- Proves:
-- 1) learner-facing consent RPCs are authenticated-only;
-- 2) an authenticated learner can see only their own invitation state;
-- 3) a non-candidate cannot self-consent;
-- 4) acknowledgement is explicit and versioned;
-- 5) self-consent changes consent only: no approval, activation or entitlement;
-- 6) three learners can independently self-consent, then service governance approves;
-- 7) a consented Core canary may activate;
-- 8) live self-revocation immediately fail-closes the whole beta;
-- 9) all synthetic state rolls back cleanly.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('p016.current_schema',true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'P0-16 SELF-CONSENT MATRIX REFUSED: p016.current_schema=true is required. Use only an ephemeral test database.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE p016s_people(
  ord integer PRIMARY KEY,
  user_id uuid NOT NULL UNIQUE,
  service_mode text,
  activation_wave smallint
) ON COMMIT DROP;

INSERT INTO p016s_people(ord,user_id,service_mode,activation_wave) VALUES
  (1,gen_random_uuid(),'core',1),
  (2,gen_random_uuid(),'ai_assist',2),
  (3,gen_random_uuid(),'mentor_care',3),
  (4,gen_random_uuid(),null,null);

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       format('p016s-%s-%s@invalid.example',ord,replace(user_id::text,'-','')),
       now(),now(),false,false
FROM p016s_people;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P016 Self Consent',ord::text,'en',now(),false
FROM p016s_people;

GRANT SELECT ON TABLE p016s_people TO service_role,authenticated;

-- Learner-facing functions must not be callable by anon/service_role and must be
-- executable by authenticated only.
DO $$
BEGIN
  IF has_function_privilege('anon','public.get_my_exam_prep_beta_invitation_v1()','EXECUTE')
     OR has_function_privilege('anon','public.grant_my_exam_prep_beta_consent_v1(text,text)','EXECUTE')
     OR has_function_privilege('anon','public.revoke_my_exam_prep_beta_consent_v1(text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P0-16 self-consent anon execution leakage';
  END IF;
  IF has_function_privilege('service_role','public.get_my_exam_prep_beta_invitation_v1()','EXECUTE')
     OR has_function_privilege('service_role','public.grant_my_exam_prep_beta_consent_v1(text,text)','EXECUTE')
     OR has_function_privilege('service_role','public.revoke_my_exam_prep_beta_consent_v1(text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P0-16 self-consent service_role should not use learner-facing RPCs';
  END IF;
  IF NOT has_function_privilege('authenticated','public.get_my_exam_prep_beta_invitation_v1()','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.grant_my_exam_prep_beta_consent_v1(text,text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.revoke_my_exam_prep_beta_consent_v1(text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P0-16 self-consent authenticated grants missing';
  END IF;
END
$$;

SET LOCAL ROLE service_role;
SELECT public.stage_exam_prep_controlled_beta_v1(
  'math_as_p1_p5_beta_self_consent_01',3::smallint,
  'P0-16 isolated authenticated self-consent regression.'
);
SELECT public.set_exam_prep_beta_member_v1(
  'math_as_p1_p5_beta_self_consent_01',p.user_id,p.service_mode,p.activation_wave
)
FROM p016s_people p
WHERE p.ord between 1 and 3
ORDER BY p.ord;
RESET ROLE;

-- Authenticated role without a subject claim is still unauthenticated for this API.
SELECT set_config('request.jwt.claim.sub','',true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_expected boolean:=false;
BEGIN
  BEGIN
    PERFORM public.get_my_exam_prep_beta_invitation_v1();
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_beta_self_consent_auth_required' THEN
      v_expected:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_expected THEN
    RAISE EXCEPTION 'P0-16 self-consent expected missing auth subject to fail';
  END IF;
END
$$;
RESET ROLE;

-- Candidate 1 can see only their own invitation and initially has no consent.
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p016s_people WHERE ord=1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE v jsonb;
BEGIN
  v:=public.get_my_exam_prep_beta_invitation_v1();
  IF coalesce((v->>'invited')::boolean,false) IS NOT TRUE
     OR jsonb_array_length(v->'invitations')<>1
     OR v#>>'{invitations,0,service_mode}'<>'core'
     OR v#>>'{invitations,0,member_status}'<>'candidate'
     OR v#>>'{invitations,0,consent_status}'<>'missing'
     OR v->>'consent_copy_version'<>'controlled_beta_v1_2026_09_04' THEN
    RAISE EXCEPTION 'P0-16 self-consent own invitation mismatch: %',v;
  END IF;
END
$$;
RESET ROLE;

-- Outsider sees no invitation and cannot create consent for the cohort.
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p016s_people WHERE ord=4),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE v jsonb; v_expected boolean:=false;
BEGIN
  v:=public.get_my_exam_prep_beta_invitation_v1();
  IF coalesce((v->>'invited')::boolean,false) OR jsonb_array_length(v->'invitations')<>0 THEN
    RAISE EXCEPTION 'P0-16 self-consent outsider invitation leakage: %',v;
  END IF;
  BEGIN
    PERFORM public.grant_my_exam_prep_beta_consent_v1(
      'math_as_p1_p5_beta_self_consent_01',
      'I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_beta_self_consent_candidate_required' THEN
      v_expected:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_expected THEN
    RAISE EXCEPTION 'P0-16 self-consent outsider was able to grant consent';
  END IF;
END
$$;
RESET ROLE;

-- Candidate 1 must provide the exact acknowledgement token.
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p016s_people WHERE ord=1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE v_expected boolean:=false;
BEGIN
  BEGIN
    PERFORM public.grant_my_exam_prep_beta_consent_v1(
      'math_as_p1_p5_beta_self_consent_01','YES'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_beta_self_consent_acknowledgement_required' THEN
      v_expected:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_expected THEN
    RAISE EXCEPTION 'P0-16 self-consent weak acknowledgement was accepted';
  END IF;
END
$$;

SELECT public.grant_my_exam_prep_beta_consent_v1(
  'math_as_p1_p5_beta_self_consent_01',
  'I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1'
);
RESET ROLE;

-- Self-consent must be consent-only: member remains candidate and feature stays dark.
DO $$
DECLARE v_cfg record; v_consent int; v_candidate int; v_ent int; v_uid uuid;
BEGIN
  SELECT user_id INTO v_uid FROM p016s_people WHERE ord=1;
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 self-consent changed feature state: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_consent
  FROM private.exam_prep_beta_consents c
  JOIN private.exam_prep_beta_cohorts b ON b.id=c.cohort_id
  WHERE b.cohort_key='math_as_p1_p5_beta_self_consent_01'
    AND c.user_id=v_uid
    AND c.consent_status='granted'
    AND c.created_by=v_uid
    AND c.grant_evidence_ref='authenticated_self_consent_v1:controlled_beta_v1_2026_09_04';
  IF v_consent<>1 THEN
    RAISE EXCEPTION 'P0-16 self-consent evidence/actor mismatch count=%',v_consent;
  END IF;
  SELECT count(*) INTO v_candidate
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts b ON b.id=m.cohort_id
  WHERE b.cohort_key='math_as_p1_p5_beta_self_consent_01'
    AND m.user_id=v_uid AND m.member_status='candidate';
  IF v_candidate<>1 THEN
    RAISE EXCEPTION 'P0-16 self-consent unexpectedly changed member status';
  END IF;
  SELECT count(*) INTO v_ent
  FROM private.exam_prep_feature_entitlements e
  WHERE e.user_id=v_uid AND e.entitlement_status='active';
  IF v_ent<>0 THEN
    RAISE EXCEPTION 'P0-16 self-consent leaked active entitlement count=%',v_ent;
  END IF;
END
$$;

-- Candidates 2 and 3 independently self-consent as themselves.
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p016s_people WHERE ord=2),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
SELECT public.grant_my_exam_prep_beta_consent_v1(
  'math_as_p1_p5_beta_self_consent_01',
  'I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1'
);
RESET ROLE;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p016s_people WHERE ord=3),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
SELECT public.grant_my_exam_prep_beta_consent_v1(
  'math_as_p1_p5_beta_self_consent_01',
  'I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1'
);
RESET ROLE;

DO $$
DECLARE v jsonb;
BEGIN
  v:=public.get_exam_prep_beta_consent_status_v1('math_as_p1_p5_beta_self_consent_01');
  IF (v->>'members')::int<>3 OR (v->>'granted')::int<>3
     OR (v->>'missing')::int<>0 OR (v->>'revoked')::int<>0
     OR coalesce((v->>'consent_complete')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'P0-16 self-consent cohort completeness mismatch: %',v;
  END IF;
END
$$;

-- Governance can now approve, still without granting access.
SET LOCAL ROLE service_role;
SELECT public.approve_exam_prep_controlled_beta_v1('math_as_p1_p5_beta_self_consent_01');
RESET ROLE;

DO $$
DECLARE v_cfg record; v_approved int; v_ent int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 self-consent approval changed feature state: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_approved
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts b ON b.id=m.cohort_id
  WHERE b.cohort_key='math_as_p1_p5_beta_self_consent_01' AND m.member_status='approved';
  IF v_approved<>3 THEN
    RAISE EXCEPTION 'P0-16 self-consent expected 3 approved members, got %',v_approved;
  END IF;
  SELECT count(*) INTO v_ent
  FROM private.exam_prep_feature_entitlements e
  JOIN p016s_people p ON p.user_id=e.user_id
  WHERE e.entitlement_status='active';
  IF v_ent<>0 THEN
    RAISE EXCEPTION 'P0-16 self-consent approval leaked active entitlements=%',v_ent;
  END IF;
END
$$;

-- Core-only wave 1 canary activates through the normal governed path.
SET LOCAL ROLE service_role;
SELECT public.activate_exam_prep_controlled_beta_wave_v1(
  'math_as_p1_p5_beta_self_consent_01',1::smallint
);
RESET ROLE;

DO $$
DECLARE v_cfg record; v_active int; v_core_ent int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta' OR v_cfg.kill_switch
     OR NOT v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled THEN
    RAISE EXCEPTION 'P0-16 self-consent Core canary config mismatch: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_active
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts b ON b.id=m.cohort_id
  WHERE b.cohort_key='math_as_p1_p5_beta_self_consent_01' AND m.member_status='active';
  IF v_active<>1 THEN
    RAISE EXCEPTION 'P0-16 self-consent Core canary expected 1 active member, got %',v_active;
  END IF;
  SELECT count(*) INTO v_core_ent
  FROM private.exam_prep_feature_entitlements e
  JOIN p016s_people p ON p.user_id=e.user_id
  WHERE p.ord=1 AND e.entitlement_status='active'
    AND e.core_access AND NOT e.ai_assist AND NOT e.mentor_care_entitled;
  IF v_core_ent<>1 THEN
    RAISE EXCEPTION 'P0-16 self-consent Core entitlement mismatch count=%',v_core_ent;
  END IF;
END
$$;

-- The live Core learner revokes for themselves. This must globally fail-close.
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p016s_people WHERE ord=1),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
SELECT public.revoke_my_exam_prep_beta_consent_v1(
  'math_as_p1_p5_beta_self_consent_01',
  'I_REVOKE_EXAM_PREP_CONTROLLED_BETA_V1'
);
RESET ROLE;

DO $$
DECLARE v_cfg record; v_status text; v_active int; v_ent int; v_consent text;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 self-revocation did not fail-close config: %',row_to_json(v_cfg);
  END IF;
  SELECT cohort_status INTO v_status
  FROM private.exam_prep_beta_cohorts
  WHERE cohort_key='math_as_p1_p5_beta_self_consent_01';
  IF v_status<>'paused' THEN
    RAISE EXCEPTION 'P0-16 self-revocation expected paused cohort, got %',v_status;
  END IF;
  SELECT count(*) INTO v_active
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts b ON b.id=m.cohort_id
  WHERE b.cohort_key='math_as_p1_p5_beta_self_consent_01' AND m.member_status='active';
  IF v_active<>0 THEN
    RAISE EXCEPTION 'P0-16 self-revocation left % active members',v_active;
  END IF;
  SELECT count(*) INTO v_ent
  FROM private.exam_prep_feature_entitlements e
  JOIN p016s_people p ON p.user_id=e.user_id
  WHERE e.entitlement_status='active';
  IF v_ent<>0 THEN
    RAISE EXCEPTION 'P0-16 self-revocation left % active entitlements',v_ent;
  END IF;
  SELECT c.consent_status INTO v_consent
  FROM private.exam_prep_beta_consents c
  JOIN p016s_people p ON p.user_id=c.user_id
  WHERE p.ord=1;
  IF v_consent<>'revoked' THEN
    RAISE EXCEPTION 'P0-16 self-revocation consent status mismatch=%',v_consent;
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_cfg record; v_users int; v_cohorts int; v_consents int;
BEGIN
  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'off' OR v_cfg.core_enabled OR v_cfg.ai_enabled OR v_cfg.mentor_enabled OR NOT v_cfg.kill_switch THEN
    RAISE EXCEPTION 'P0-16 self-consent matrix post-rollback config not fail-closed: %',row_to_json(v_cfg);
  END IF;
  SELECT count(*) INTO v_users FROM auth.users WHERE email like 'p016s-%@invalid.example';
  SELECT count(*) INTO v_cohorts FROM private.exam_prep_beta_cohorts WHERE cohort_key='math_as_p1_p5_beta_self_consent_01';
  SELECT count(*) INTO v_consents
  FROM private.exam_prep_beta_consents c
  JOIN private.exam_prep_beta_cohorts b ON b.id=c.cohort_id
  WHERE b.cohort_key='math_as_p1_p5_beta_self_consent_01';
  IF v_users<>0 OR v_cohorts<>0 OR v_consents<>0 THEN
    RAISE EXCEPTION 'P0-16 self-consent synthetic residue users=% cohorts=% consents=%',v_users,v_cohorts,v_consents;
  END IF;
END
$$;

\echo 'P0-16 authenticated learner self-consent matrix: GREEN (own invite/consent only; live revoke fail-closes)'
