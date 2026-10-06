\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('iclub.subscription_access_isolated', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'SUBSCRIPTION ACCESS TEST REFUSED: iclub.subscription_access_isolated=true is required.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE commercial_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $$
DECLARE
  k text;
  uid uuid;
BEGIN
  FOREACH k IN ARRAY ARRAY['legacy','free','pro','new_user'] LOOP
    uid:=gen_random_uuid();

    INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(
      uid,'authenticated','authenticated',
      'commercial-access-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',
      now(),now(),false,false
    );

    INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
    VALUES(uid,'Commercial',k,'en',now(),false);

    INSERT INTO commercial_people VALUES(k,uid);
  END LOOP;

  INSERT INTO public.user_subjects(user_id,subject_id,mode,is_pinned)
  SELECT user_id,1,'competitive',false
  FROM commercial_people WHERE person_key='legacy';

  INSERT INTO public.user_subjects(user_id,subject_id,mode,is_pinned)
  SELECT user_id,3,'study',true
  FROM commercial_people WHERE person_key='legacy';
END
$$;

-- Dormant defaults must preserve the existing app.
DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='legacy');
  eid uuid:=gen_random_uuid();
BEGIN
  v:=public.get_iclub_subject_access_guard_service_v1(uid,'mathematics','open');

  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'mode'<>'legacy_passthrough'
     OR v->>'reason'<>'subject_limits_off' THEN
    RAISE EXCEPTION 'Dormant subject guard did not preserve legacy access: %',v;
  END IF;

  v:=public.apply_iclub_subscription_event_service_v1(
    eid,uid,'activate','free',now(),now(),now()+interval '30 days','ci'
  );

  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'lifecycle_disabled' THEN
    RAISE EXCEPTION 'Dormant lifecycle accepted an event: %',v;
  END IF;

  IF EXISTS(select 1 from private.iclub_subscription_events where event_id=eid) THEN
    RAISE EXCEPTION 'Dormant lifecycle wrote an event row';
  END IF;
END
$$;

UPDATE private.iclub_commercial_access_config
SET lifecycle_enabled=true,
    updated_at=now()
WHERE id=1;

-- Activate Free and Pro; event IDs must be idempotent.
DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='free');
  eid uuid:=gen_random_uuid();
  c integer;
BEGIN
  v:=public.apply_iclub_subscription_event_service_v1(
    eid,uid,'activate','free',now(),now(),now()+interval '30 days','ci'
  );

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR v->>'current_plan_code'<>'free' THEN
    RAISE EXCEPTION 'Free activation failed: %',v;
  END IF;

  v:=public.apply_iclub_subscription_event_service_v1(
    eid,uid,'activate','free',now(),now(),now()+interval '30 days','ci'
  );

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'duplicate')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Subscription event idempotency failed: %',v;
  END IF;

  SELECT count(*) INTO c
  FROM private.iclub_subscription_events
  WHERE event_id=eid;

  IF c<>1 THEN
    RAISE EXCEPTION 'Duplicate lifecycle event rows=%',c;
  END IF;
END
$$;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='pro');
BEGIN
  v:=public.apply_iclub_subscription_event_service_v1(
    gen_random_uuid(),uid,'activate','pro',now(),now(),now()+interval '30 days','ci'
  );

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR v->>'current_plan_code'<>'pro' THEN
    RAISE EXCEPTION 'Pro activation failed: %',v;
  END IF;
END
$$;

-- Scheduled downgrade must not change the current plan early.
DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='pro');
  bad_eid uuid:=gen_random_uuid();
  ent private.iclub_subscription_entitlements%rowtype;
BEGIN
  v:=public.apply_iclub_subscription_event_service_v1(
    gen_random_uuid(),uid,'schedule_downgrade','plus',
    now()+interval '30 days',null,null,'ci'
  );

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Schedule downgrade failed: %',v;
  END IF;

  SELECT * INTO ent
  FROM private.iclub_subscription_entitlements
  WHERE user_id=uid;

  IF ent.plan_code<>'pro'
     OR ent.scheduled_plan_code<>'plus'
     OR ent.scheduled_change_at IS NULL THEN
    RAISE EXCEPTION 'Scheduled downgrade changed plan too early: %',row_to_json(ent);
  END IF;

  v:=public.apply_iclub_subscription_event_service_v1(
    bad_eid,uid,'downgrade','plus',
    now()+interval '10 days',null,null,'ci'
  );

  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'future_event_requires_schedule' THEN
    RAISE EXCEPTION 'Future direct downgrade was accepted: %',v;
  END IF;

  IF EXISTS(select 1 from private.iclub_subscription_events where event_id=bad_eid) THEN
    RAISE EXCEPTION 'Rejected future downgrade left a pending event row';
  END IF;

  v:=public.apply_iclub_subscription_event_service_v1(
    gen_random_uuid(),uid,'downgrade','plus',now(),null,null,'ci'
  );

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR v->>'current_plan_code'<>'plus' THEN
    RAISE EXCEPTION 'Effective downgrade failed: %',v;
  END IF;

  SELECT * INTO ent
  FROM private.iclub_subscription_entitlements
  WHERE user_id=uid;

  IF ent.scheduled_plan_code IS NOT NULL
     OR ent.scheduled_change_at IS NOT NULL THEN
    RAISE EXCEPTION 'Applied downgrade did not clear schedule: %',row_to_json(ent);
  END IF;
END
$$;

-- Invalid lifecycle preconditions must never leave pending ledger rows.
DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='new_user');
  eid uuid:=gen_random_uuid();
BEGIN
  v:=public.apply_iclub_subscription_event_service_v1(
    eid,uid,'pause',null,now(),null,null,'ci'
  );

  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'subscription_missing' THEN
    RAISE EXCEPTION 'Missing subscription pause mismatch: %',v;
  END IF;

  IF EXISTS(select 1 from private.iclub_subscription_events where event_id=eid) THEN
    RAISE EXCEPTION 'Rejected lifecycle event left ledger residue';
  END IF;
END
$$;

-- Pause/resume and scheduled cancel/cancel preserve explicit lifecycle semantics.
DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='free');
  ent private.iclub_subscription_entitlements%rowtype;
BEGIN
  v:=public.apply_iclub_subscription_event_service_v1(
    gen_random_uuid(),uid,'pause',null,now(),null,null,'ci'
  );
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pause failed: %',v;
  END IF;

  SELECT * INTO ent FROM private.iclub_subscription_entitlements WHERE user_id=uid;
  IF ent.entitlement_status<>'paused' THEN
    RAISE EXCEPTION 'Pause status mismatch: %',row_to_json(ent);
  END IF;

  v:=public.apply_iclub_subscription_event_service_v1(
    gen_random_uuid(),uid,'resume',null,now(),null,null,'ci'
  );
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Resume failed: %',v;
  END IF;

  v:=public.apply_iclub_subscription_event_service_v1(
    gen_random_uuid(),uid,'schedule_cancel',null,now(),null,null,'ci'
  );
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Schedule cancel failed: %',v;
  END IF;

  SELECT * INTO ent FROM private.iclub_subscription_entitlements WHERE user_id=uid;
  IF ent.cancel_at_period_end IS NOT TRUE
     OR ent.entitlement_status<>'active' THEN
    RAISE EXCEPTION 'Scheduled cancel incorrectly removed current access: %',row_to_json(ent);
  END IF;

  v:=public.apply_iclub_subscription_event_service_v1(
    gen_random_uuid(),uid,'cancel',null,now(),null,null,'ci'
  );
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Cancel failed: %',v;
  END IF;

  SELECT * INTO ent FROM private.iclub_subscription_entitlements WHERE user_id=uid;
  IF ent.entitlement_status<>'cancelled' THEN
    RAISE EXCEPTION 'Cancel status mismatch: %',row_to_json(ent);
  END IF;
END
$$;

-- Restore Free for subject-slot tests.
DO $$
DECLARE
  uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='free');
  v jsonb;
BEGIN
  v:=public.apply_iclub_subscription_event_service_v1(
    gen_random_uuid(),uid,'activate','free',now(),now(),now()+interval '30 days','ci'
  );

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free reactivation failed: %',v;
  END IF;
END
$$;

-- Grandfather capture occurs only in shadow mode and must not modify legacy rows.
UPDATE private.iclub_commercial_access_config
SET subject_limits_mode='shadow',
    updated_at=now()
WHERE id=1;

DO $$
DECLARE
  before_count integer;
  after_count integer;
  before_digest text;
  after_digest text;
  v jsonb;
  legacy_uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='legacy');
BEGIN
  SELECT count(*),
         md5(coalesce(string_agg(
           user_id::text||':'||subject_id::text||':'||mode||':'||is_pinned::text,
           '|' order by user_id,subject_id
         ),''))
  INTO before_count,before_digest
  FROM public.user_subjects;

  v:=public.capture_iclub_legacy_access_baseline_service_v1('commercial_cutover_ci_v1');

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'duplicate')::boolean,true) IS NOT FALSE
     OR (v->>'legacy_subject_rows_captured')::integer<>2 THEN
    RAISE EXCEPTION 'Grandfather capture failed: %',v;
  END IF;

  SELECT count(*),
         md5(coalesce(string_agg(
           user_id::text||':'||subject_id::text||':'||mode||':'||is_pinned::text,
           '|' order by user_id,subject_id
         ),''))
  INTO after_count,after_digest
  FROM public.user_subjects;

  IF before_count<>after_count OR before_digest IS DISTINCT FROM after_digest THEN
    RAISE EXCEPTION 'Grandfather capture mutated legacy user_subjects';
  END IF;

  IF NOT EXISTS(
    select 1
    from private.iclub_commercial_migration_state
    where user_id=legacy_uid
      and migration_state='legacy_preserved'
      and snapshot_version='commercial_cutover_ci_v1'
  ) THEN
    RAISE EXCEPTION 'Legacy learner migration state missing';
  END IF;

  IF (
    select count(*)
    from private.iclub_legacy_subject_snapshot
    where user_id=legacy_uid
      and snapshot_version='commercial_cutover_ci_v1'
  )<>2 THEN
    RAISE EXCEPTION 'Legacy subject snapshot row count mismatch';
  END IF;

  v:=public.capture_iclub_legacy_access_baseline_service_v1('commercial_cutover_ci_v1');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'duplicate')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Grandfather capture idempotency failed: %',v;
  END IF;
END
$$;

-- Grandfathered learner may open any active subject until explicit choice.
DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='legacy');
BEGIN
  v:=public.get_iclub_subject_access_guard_service_v1(uid,'biology','open');

  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'mode'<>'grandfathered'
     OR v->>'reason'<>'legacy_access_preserved' THEN
    RAISE EXCEPTION 'Grandfather access was not preserved: %',v;
  END IF;
END
$$;

-- Free learner explicitly chooses one subject, then leaves grandfather mode.
DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='free');
BEGIN
  v:=public.set_iclub_subject_slot_service_v1(
    gen_random_uuid(),uid,'mathematics',true,false,'ci_selection'
  );

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free first study slot failed: %',v;
  END IF;

  v:=public.finalize_iclub_subject_selection_service_v1(uid,'ci_confirmation');

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR v->>'migration_state'<>'migrated'
     OR (v->>'study_selected')::integer<>1 THEN
    RAISE EXCEPTION 'Free selection finalization failed: %',v;
  END IF;
END
$$;

-- The lifecycle test above intentionally downgraded this synthetic learner.
-- Upgrade it back to Pro before testing the independent all-subject access rule.
DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='pro');
BEGIN
  v:=public.apply_iclub_subscription_event_service_v1(
    gen_random_uuid(),uid,'upgrade','pro',now(),null,null,'ci'
  );

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR v->>'current_plan_code'<>'pro' THEN
    RAISE EXCEPTION 'Pro re-upgrade before subject-access test failed: %',v;
  END IF;

  v:=public.finalize_iclub_subject_selection_service_v1(uid,'ci_confirmation');

  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR v->>'migration_state'<>'migrated' THEN
    RAISE EXCEPTION 'Pro all-subject migration failed: %',v;
  END IF;
END
$$;
-- Enforced mode is allowed only after the grandfather snapshot exists.
UPDATE private.iclub_commercial_access_config
SET subject_limits_mode='enforced',
    updated_at=now()
WHERE id=1;

DO $$
DECLARE
  v jsonb;
  free_uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='free');
  legacy_uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='legacy');
  pro_uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='pro');
BEGIN
  v:=public.get_iclub_subject_access_guard_service_v1(free_uid,'mathematics','open');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'subject_selected' THEN
    RAISE EXCEPTION 'Selected Free subject denied: %',v;
  END IF;

  v:=public.get_iclub_subject_access_guard_service_v1(free_uid,'chemistry','open');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'subject_not_selected' THEN
    RAISE EXCEPTION 'Unselected Free subject was not blocked: %',v;
  END IF;

  v:=public.set_iclub_subject_slot_service_v1(
    gen_random_uuid(),free_uid,'chemistry',true,false,'ci_selection'
  );
  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'study_subject_limit_reached' THEN
    RAISE EXCEPTION 'Free second study subject was not blocked: %',v;
  END IF;

  v:=public.set_iclub_subject_slot_service_v1(
    gen_random_uuid(),free_uid,'mathematics',true,true,'ci_selection'
  );
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free first competitive subject failed: %',v;
  END IF;

  v:=public.set_iclub_subject_slot_service_v1(
    gen_random_uuid(),free_uid,'biology',true,true,'ci_selection'
  );
  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason' NOT IN ('competitive_subject_limit_reached','study_subject_limit_reached') THEN
    RAISE EXCEPTION 'Free extra competitive subject was not blocked: %',v;
  END IF;

  v:=public.get_iclub_subject_access_guard_service_v1(legacy_uid,'economics','open');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'legacy_access_preserved' THEN
    RAISE EXCEPTION 'Enforced mode broke grandfathered learner: %',v;
  END IF;

  v:=public.get_iclub_subject_access_guard_service_v1(pro_uid,'economics','open');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'plan_all_subjects' THEN
    RAISE EXCEPTION 'Pro all-subject access failed: %',v;
  END IF;
END
$$;

-- Structural subject rules stay strict even in shadow mode.
UPDATE private.iclub_commercial_access_config
SET subject_limits_mode='shadow',
    updated_at=now()
WHERE id=1;

DO $$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM commercial_people WHERE person_key='free');
BEGIN
  v:=public.set_iclub_subject_slot_service_v1(
    gen_random_uuid(),uid,'english_a1',true,true,'ci_selection'
  );

  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'subject_unavailable' THEN
    RAISE EXCEPTION 'Inactive/additional structural guard failed in shadow: %',v;
  END IF;
END
$$;

-- Browser roles cannot mutate lifecycle/access authority.
DO $$
BEGIN
  IF has_function_privilege(
       'authenticated',
       'public.apply_iclub_subscription_event_service_v1(uuid,uuid,text,text,timestamptz,timestamptz,timestamptz,text)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'authenticated',
       'public.capture_iclub_legacy_access_baseline_service_v1(text)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'authenticated',
       'public.get_iclub_subject_access_guard_service_v1(uuid,text,text)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'authenticated',
       'public.set_iclub_subject_slot_service_v1(uuid,uuid,text,boolean,boolean,text)',
       'EXECUTE'
     )
     OR has_function_privilege(
       'authenticated',
       'public.finalize_iclub_subject_selection_service_v1(uuid,text)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'Authenticated browser role received commercial service authority';
  END IF;

  IF has_table_privilege('authenticated','private.iclub_subject_slot_selections','SELECT')
     OR has_table_privilege('anon','private.iclub_subscription_events','SELECT') THEN
    RAISE EXCEPTION 'Commercial private storage became browser-readable';
  END IF;
END
$$;

ROLLBACK;

DO $$
DECLARE
  c integer;
BEGIN
  SELECT count(*) INTO c
  FROM auth.users
  WHERE email like 'commercial-access-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Lifecycle matrix rollback left synthetic users=%',c;
  END IF;

  SELECT
    (select count(*) from private.iclub_subscription_events)
    + (select count(*) from private.iclub_commercial_migration_state)
    + (select count(*) from private.iclub_legacy_subject_snapshot)
    + (select count(*) from private.iclub_subject_slot_selections)
    + (select count(*) from private.iclub_subject_slot_events)
  INTO c;

  IF c<>0 THEN
    RAISE EXCEPTION 'Lifecycle matrix rollback left private commercial rows=%',c;
  END IF;
END
$$;

\echo 'iClub subscription lifecycle + subject access v1 matrix: GREEN'