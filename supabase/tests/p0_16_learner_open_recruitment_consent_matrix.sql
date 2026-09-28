-- P0-16 capped open Core recruitment acceptance matrix.
-- Full current schema required. All rows are transaction-local and roll back.

\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE p016open_people(
  ord integer primary key,
  user_id uuid not null unique
) ON COMMIT DROP;

INSERT INTO p016open_people(ord,user_id)
SELECT g,gen_random_uuid() FROM generate_series(1,13) g;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',
       format('p016open-%s-%s@invalid.example',ord,replace(user_id::text,'-','')),
       now(),now(),false,false
FROM p016open_people;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P016 Open',ord::text,'en',now(),false
FROM p016open_people;

GRANT SELECT ON p016open_people TO authenticated,service_role;

-- Learner claim is authenticated-only; private recruitment tables stay private.
DO $$
BEGIN
  IF has_function_privilege('anon','public.claim_my_exam_prep_beta_core_seat_v1(text,text)','EXECUTE')
     OR has_function_privilege('service_role','public.claim_my_exam_prep_beta_core_seat_v1(text,text)','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.claim_my_exam_prep_beta_core_seat_v1(text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'P0-16 open recruitment claim ACL mismatch';
  END IF;
  IF has_table_privilege('authenticated','private.exam_prep_beta_open_recruitment_v1','SELECT')
     OR has_table_privilege('authenticated','private.exam_prep_beta_open_recruitment_members_v1','SELECT') THEN
    RAISE EXCEPTION 'P0-16 open recruitment private table leakage';
  END IF;
END
$$;

-- Build a normal 3-person Core canary first.
SET LOCAL ROLE service_role;
SELECT public.stage_exam_prep_controlled_beta_v1(
  'p016-open-core-12',12::smallint,
  'P0-16 isolated open recruitment regression.'
);
SELECT public.set_exam_prep_beta_member_v1(
  'p016-open-core-12',p.user_id,'core',1::smallint
)
FROM p016open_people p WHERE p.ord between 1 and 3
ORDER BY p.ord;
SELECT public.record_exam_prep_beta_consent_v1(
  'p016-open-core-12',p.user_id,
  format('p016-open-initial-consent-%s',p.ord),now()
)
FROM p016open_people p WHERE p.ord between 1 and 3
ORDER BY p.ord;
SELECT public.approve_exam_prep_controlled_beta_v1('p016-open-core-12');
SELECT public.activate_exam_prep_controlled_beta_wave_v1('p016-open-core-12',1::smallint);
RESET ROLE;

DO $$
DECLARE v_c bigint;
BEGIN
  SELECT id INTO v_c FROM private.exam_prep_beta_cohorts WHERE cohort_key='p016-open-core-12';
  INSERT INTO private.exam_prep_beta_open_recruitment_v1(
    cohort_id,enabled,max_active_members,service_mode,consent_copy_version,opened_at
  ) VALUES(
    v_c,true,12,'core','controlled_beta_v1_2026_09_04',now()
  );
END
$$;

-- Outsider 4 sees the public testing offer, but viewing it cannot grant access.
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p016open_people WHERE ord=4),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE v jsonb;
BEGIN
  v:=public.get_my_exam_prep_beta_invitation_v1();
  IF coalesce((v->>'invited')::boolean,false) IS NOT TRUE
     OR jsonb_array_length(v->'invitations')<>1
     OR coalesce((v#>>'{invitations,0,open_recruitment}')::boolean,false) IS NOT TRUE
     OR v#>>'{invitations,0,member_status}'<>'open'
     OR (v#>>'{invitations,0,remaining_slots}')::int<>9
     OR v#>>'{invitations,0,service_mode}'<>'core' THEN
    RAISE EXCEPTION 'P0-16 open recruitment offer mismatch: %',v;
  END IF;
END
$$;

DO $$
DECLARE v_expected boolean:=false;
BEGIN
  BEGIN
    PERFORM public.claim_my_exam_prep_beta_core_seat_v1('p016-open-core-12','YES');
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_beta_open_recruitment_acknowledgement_required' THEN
      v_expected:=true;
    ELSE
      RAISE;
    END IF;
  END;
  IF NOT v_expected THEN
    RAISE EXCEPTION 'P0-16 open recruitment accepted weak acknowledgement';
  END IF;
END
$$;

SELECT public.claim_my_exam_prep_beta_core_seat_v1(
  'p016-open-core-12','I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1'
);
RESET ROLE;

DO $$
DECLARE v_uid uuid; v_active int; v_ent int; v_consent int; v_wave int; v_cfg record;
BEGIN
  SELECT user_id INTO v_uid FROM p016open_people WHERE ord=4;
  SELECT count(*) INTO v_active
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='p016-open-core-12' AND m.user_id=v_uid
    AND m.member_status='active' AND m.service_mode='core';
  IF v_active<>1 THEN RAISE EXCEPTION 'P0-16 open recruit not active'; END IF;

  SELECT activation_wave INTO v_wave
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='p016-open-core-12' AND m.user_id=v_uid;
  IF v_wave<>2 THEN RAISE EXCEPTION 'P0-16 open recruit expected wave 2, got %',v_wave; END IF;

  SELECT count(*) INTO v_ent FROM private.exam_prep_feature_entitlements
  WHERE user_id=v_uid AND entitlement_status='active' AND core_access
    AND NOT ai_assist AND NOT mentor_care_entitled AND cohort_key='p016-open-core-12';
  IF v_ent<>1 THEN RAISE EXCEPTION 'P0-16 open recruit entitlement mismatch'; END IF;

  SELECT count(*) INTO v_consent
  FROM private.exam_prep_beta_consents c
  JOIN private.exam_prep_beta_cohorts b ON b.id=c.cohort_id
  WHERE b.cohort_key='p016-open-core-12' AND c.user_id=v_uid
    AND c.consent_status='granted'
    AND c.grant_evidence_ref='authenticated_open_recruitment_v1:controlled_beta_v1_2026_09_28';
  IF v_consent<>1 THEN RAISE EXCEPTION 'P0-16 open recruit consent evidence mismatch'; END IF;

  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta' OR v_cfg.kill_switch OR NOT v_cfg.core_enabled
     OR v_cfg.ai_enabled OR v_cfg.mentor_enabled THEN
    RAISE EXCEPTION 'P0-16 open recruit changed capability boundary: %',row_to_json(v_cfg);
  END IF;
END
$$;

-- Fill remaining seats through the same authenticated RPC. Row locking must keep the cap exact.
SET LOCAL ROLE authenticated;
DO $$
DECLARE r record; v jsonb;
BEGIN
  FOR r IN SELECT ord,user_id FROM p016open_people WHERE ord between 5 and 12 ORDER BY ord LOOP
    PERFORM set_config('request.jwt.claim.sub',r.user_id::text,true);
    PERFORM set_config('request.jwt.claim.role','authenticated',true);
    v:=public.claim_my_exam_prep_beta_core_seat_v1(
      'p016-open-core-12','I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1'
    );
    IF v->>'status'<>'activated' THEN
      RAISE EXCEPTION 'P0-16 open recruitment activation failed ord=% result=%',r.ord,v;
    END IF;
  END LOOP;
END
$$;
RESET ROLE;

DO $$
DECLARE v_active int; v_enabled boolean; v_status text; v_wave int;
BEGIN
  SELECT count(*) INTO v_active
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='p016-open-core-12' AND m.member_status='active';
  IF v_active<>12 THEN RAISE EXCEPTION 'P0-16 cap expected 12 active, got %',v_active; END IF;

  SELECT r.enabled,c.cohort_status,c.current_wave
  INTO v_enabled,v_status,v_wave
  FROM private.exam_prep_beta_open_recruitment_v1 r
  JOIN private.exam_prep_beta_cohorts c ON c.id=r.cohort_id
  WHERE c.cohort_key='p016-open-core-12';
  IF v_enabled OR v_status<>'active' OR v_wave<>10 THEN
    RAISE EXCEPTION 'P0-16 cap closure mismatch enabled=% status=% wave=%',v_enabled,v_status,v_wave;
  END IF;
END
$$;

-- User 13 sees no offer when full.
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p016open_people WHERE ord=13),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
DO $$
DECLARE v jsonb; v_expected boolean:=false;
BEGIN
  v:=public.get_my_exam_prep_beta_invitation_v1();
  IF coalesce((v->>'invited')::boolean,false) OR jsonb_array_length(v->'invitations')<>0 THEN
    RAISE EXCEPTION 'P0-16 full cohort still advertised an open seat: %',v;
  END IF;
  BEGIN
    PERFORM public.claim_my_exam_prep_beta_core_seat_v1(
      'p016-open-core-12','I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1'
    );
  EXCEPTION WHEN OTHERS THEN
    IF SQLERRM='exam_prep_beta_open_recruitment_closed' THEN v_expected:=true; ELSE RAISE; END IF;
  END;
  IF NOT v_expected THEN RAISE EXCEPTION 'P0-16 full cohort accepted a 13th learner'; END IF;
END
$$;
RESET ROLE;

-- A self-recruited learner may leave without pausing everybody else.
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p016open_people WHERE ord=4),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
SELECT public.revoke_my_exam_prep_beta_consent_v1(
  'p016-open-core-12','I_REVOKE_EXAM_PREP_CONTROLLED_BETA_V1'
);
RESET ROLE;

DO $$
DECLARE v_uid uuid; v_active int; v_other_active int; v_enabled boolean; v_status text; v_cfg record;
BEGIN
  SELECT user_id INTO v_uid FROM p016open_people WHERE ord=4;
  SELECT count(*) INTO v_active
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='p016-open-core-12' AND m.member_status='active';
  IF v_active<>11 THEN RAISE EXCEPTION 'P0-16 withdrawal expected 11 active, got %',v_active; END IF;

  SELECT count(*) INTO v_other_active
  FROM private.exam_prep_feature_entitlements e
  JOIN p016open_people p ON p.user_id=e.user_id
  WHERE p.ord<>4 AND e.entitlement_status='active' AND e.core_access;
  IF v_other_active<>11 THEN RAISE EXCEPTION 'P0-16 withdrawal affected other learners=%',v_other_active; END IF;

  IF EXISTS(
    SELECT 1 FROM private.exam_prep_feature_entitlements
    WHERE user_id=v_uid AND entitlement_status='active'
  ) THEN RAISE EXCEPTION 'P0-16 withdrawn learner retained access'; END IF;

  SELECT * INTO v_cfg FROM private.exam_prep_feature_config WHERE id=1;
  IF v_cfg.rollout_state<>'controlled_beta' OR v_cfg.kill_switch OR NOT v_cfg.core_enabled
     OR v_cfg.ai_enabled OR v_cfg.mentor_enabled THEN
    RAISE EXCEPTION 'P0-16 withdrawal globally paused beta: %',row_to_json(v_cfg);
  END IF;

  SELECT r.enabled,c.cohort_status INTO v_enabled,v_status
  FROM private.exam_prep_beta_open_recruitment_v1 r
  JOIN private.exam_prep_beta_cohorts c ON c.id=r.cohort_id
  WHERE c.cohort_key='p016-open-core-12';
  IF NOT v_enabled OR v_status<>'canary' THEN
    RAISE EXCEPTION 'P0-16 withdrawal did not reopen one seat enabled=% status=%',v_enabled,v_status;
  END IF;
END
$$;

-- User 13 can now take the reopened seat; capacity returns to exactly 12.
SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p016open_people WHERE ord=13),true);
SELECT set_config('request.jwt.claim.role','authenticated',true);
SET LOCAL ROLE authenticated;
SELECT public.claim_my_exam_prep_beta_core_seat_v1(
  'p016-open-core-12','I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1'
);
RESET ROLE;

DO $$
DECLARE v_active int; v_enabled boolean; v_ai int; v_mentor int;
BEGIN
  SELECT count(*) INTO v_active
  FROM private.exam_prep_beta_members m
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='p016-open-core-12' AND m.member_status='active';
  IF v_active<>12 THEN RAISE EXCEPTION 'P0-16 reopened seat did not restore cap: %',v_active; END IF;

  SELECT enabled INTO v_enabled
  FROM private.exam_prep_beta_open_recruitment_v1 r
  JOIN private.exam_prep_beta_cohorts c ON c.id=r.cohort_id
  WHERE c.cohort_key='p016-open-core-12';
  IF v_enabled THEN RAISE EXCEPTION 'P0-16 recruitment did not reclose at cap'; END IF;

  SELECT count(*) filter(where ai_assist),count(*) filter(where mentor_care_entitled)
  INTO v_ai,v_mentor
  FROM private.exam_prep_feature_entitlements e
  JOIN private.exam_prep_beta_members m ON m.user_id=e.user_id
  JOIN private.exam_prep_beta_cohorts c ON c.id=m.cohort_id
  WHERE c.cohort_key='p016-open-core-12' AND e.entitlement_status='active';
  IF v_ai<>0 OR v_mentor<>0 THEN
    RAISE EXCEPTION 'P0-16 open recruitment leaked optional services ai=% mentor=%',v_ai,v_mentor;
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE v_users int; v_cohorts int; v_markers int;
BEGIN
  SELECT count(*) INTO v_users FROM auth.users WHERE email like 'p016open-%@invalid.example';
  SELECT count(*) INTO v_cohorts FROM private.exam_prep_beta_cohorts WHERE cohort_key='p016-open-core-12';
  SELECT count(*) INTO v_markers FROM private.exam_prep_beta_open_recruitment_members_v1;
  IF v_users<>0 OR v_cohorts<>0 OR v_markers<>0 THEN
    RAISE EXCEPTION 'P0-16 open recruitment rollback residue users=% cohorts=% markers=%',v_users,v_cohorts,v_markers;
  END IF;
END
$$;

\echo 'P0-16 capped open Core recruitment matrix: GREEN'
