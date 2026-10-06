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
     )
     OR has_function_privilege(
       'authenticated',
       'public.set_iclub_product_canary_service_v1(uuid,boolean,text,text)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'Authenticated browser role received commercial service authority';
  END IF;

  IF has_table_privilege('authenticated','private.iclub_subject_slot_selections','SELECT')
     OR has_table_privilege('authenticated','private.iclub_product_canary_users','SELECT')
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
    + (select count(*) from private.iclub_product_canary_users)
  INTO c;

  IF c<>0 THEN
    RAISE EXCEPTION 'Lifecycle matrix rollback left private commercial rows=%',c;
  END IF;
END
$$;

\echo 'iClub subscription lifecycle + subject access v1 matrix: GREEN'