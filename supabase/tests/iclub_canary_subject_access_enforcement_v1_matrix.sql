\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('iclub.canary_access_isolated', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'CANARY ACCESS REFUSED: iclub.canary_access_isolated=true is required.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE canary_access_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $people$
DECLARE
  k text;
  uid uuid;
BEGIN
  FOREACH k IN ARRAY ARRAY['free','plus','pro','normal'] LOOP
    uid:=gen_random_uuid();

    INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(uid,'authenticated','authenticated','canary-access-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',now(),now(),false,false);

    INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
    VALUES(uid,'Canary','Access '||k,'ru',now(),false);

    INSERT INTO canary_access_people VALUES(k,uid);
  END LOOP;
END
$people$;

DO $canaries$
DECLARE
  v jsonb;
  uid uuid;
BEGIN
  SELECT user_id INTO uid FROM canary_access_people WHERE person_key='free';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'free','canary-access-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM canary_access_people WHERE person_key='plus';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'plus','canary-access-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM canary_access_people WHERE person_key='pro';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'pro','canary-access-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro canary setup failed: %',v;
  END IF;
END
$canaries$;

UPDATE private.iclub_global_ai_runtime_config
SET plans_rollout_mode='canary',
    updated_at=now()
WHERE id=1;

UPDATE private.iclub_commercial_access_config
SET subject_limits_mode='shadow',
    subject_selection_ui_enabled=true,
    updated_at=now()
WHERE id=1;

-- Default OFF must preserve existing access even for a canary.
DO $default_off$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM canary_access_people WHERE person_key='free');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_my_subject_access_v1('mathematics','study');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'enforced')::boolean,true)
     OR v->>'reason'<>'access_preview_disabled' THEN
    RAISE EXCEPTION 'Default canary access preview changed legacy access: %',v;
  END IF;
END
$default_off$;

UPDATE private.iclub_commercial_access_config
SET canary_subject_access_enforced=true,
    updated_at=now()
WHERE id=1;

-- Non-canary users are never affected by this preview.
DO $normal_passthrough$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM canary_access_people WHERE person_key='normal');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_my_subject_access_v1('mathematics','study');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'enforced')::boolean,true)
     OR v->>'reason'<>'not_canary' THEN
    RAISE EXCEPTION 'Non-canary learner was affected: %',v;
  END IF;
END
$normal_passthrough$;

-- Free: no selection blocks, selected study opens, legacy toggles are plan-managed.
DO $free_access$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM canary_access_people WHERE person_key='free');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_my_subject_access_v1('mathematics','study');
  IF coalesce((v->>'allowed')::boolean,true)
     OR coalesce((v->>'enforced')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'subject_selection_required' THEN
    RAISE EXCEPTION 'Free no-selection gate mismatch: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('mathematics',true,true);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free selection setup failed: %',v;
  END IF;

  v:=public.get_iclub_my_subject_access_v1('mathematics','study');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'subject_selected' THEN
    RAISE EXCEPTION 'Selected Free study subject was blocked: %',v;
  END IF;

  v:=public.get_iclub_my_subject_access_v1('biology','study');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'subject_not_in_plan' THEN
    RAISE EXCEPTION 'Unselected Free subject escaped plan: %',v;
  END IF;

  v:=public.get_iclub_my_subject_access_v1('mathematics','competitive');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'competitive_selected' THEN
    RAISE EXCEPTION 'Selected Free Competitive subject was blocked: %',v;
  END IF;

  v:=public.get_iclub_my_subject_access_v1('biology','competitive');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'competitive_not_in_plan' THEN
    RAISE EXCEPTION 'Unselected Competitive subject escaped plan: %',v;
  END IF;

  v:=public.get_iclub_my_subject_access_v1('mathematics','legacy_toggle');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'manage_in_plan_subjects' THEN
    RAISE EXCEPTION 'Legacy subject toggle remained writable in canary preview: %',v;
  END IF;
END
$free_access$;

-- Plus selections obey the existing 3-study/2-Competitive selector and access gate.
DO $plus_access$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM canary_access_people WHERE person_key='plus');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  PERFORM public.set_iclub_my_subject_slot_v1('mathematics',true,true);
  PERFORM public.set_iclub_my_subject_slot_v1('biology',true,true);
  PERFORM public.set_iclub_my_subject_slot_v1('chemistry',true,false);

  v:=public.get_iclub_my_subject_access_v1('chemistry','study');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus selected study subject was blocked: %',v;
  END IF;

  v:=public.get_iclub_my_subject_access_v1('economics','study');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'subject_not_in_plan' THEN
    RAISE EXCEPTION 'Plus fourth/unselected study subject escaped access: %',v;
  END IF;

  v:=public.get_iclub_my_subject_access_v1('chemistry','competitive');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'competitive_not_in_plan' THEN
    RAISE EXCEPTION 'Plus non-Competitive subject escaped Tours gate: %',v;
  END IF;
END
$plus_access$;

-- Pro gets all active study subjects but Competitive still follows its selected slots.
DO $pro_access$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM canary_access_people WHERE person_key='pro');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_my_subject_access_v1('economics','study');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'plan_all_subjects' THEN
    RAISE EXCEPTION 'Pro all-subject study access failed: %',v;
  END IF;

  v:=public.get_iclub_my_subject_access_v1('economics','competitive');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'competitive_not_in_plan' THEN
    RAISE EXCEPTION 'Pro Competitive gate ignored slot selection: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('economics',true,true);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro Competitive selection failed: %',v;
  END IF;

  v:=public.get_iclub_my_subject_access_v1('economics','competitive');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro selected Competitive subject was blocked: %',v;
  END IF;
END
$pro_access$;

-- Browser can read only its own guard; no private-table access is granted.
DO $permissions$
BEGIN
  IF has_function_privilege('anon','public.get_iclub_my_subject_access_v1(text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous role can execute canary subject access guard';
  END IF;

  IF NOT has_function_privilege('authenticated','public.get_iclub_my_subject_access_v1(text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'Authenticated canary cannot execute self-only access guard';
  END IF;

  IF has_table_privilege('authenticated','private.iclub_subject_slot_selections','SELECT')
     OR has_table_privilege('authenticated','private.iclub_product_canary_users','SELECT') THEN
    RAISE EXCEPTION 'Browser role can read private commercial tables';
  END IF;
END
$permissions$;

ROLLBACK;

DO $clean$
DECLARE
  c integer;
BEGIN
  SELECT count(*) INTO c
  FROM auth.users
  WHERE email like 'canary-access-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Canary access matrix rollback left synthetic users=%',c;
  END IF;
END
$clean$;

\echo 'iClub canary subject access enforcement v1 SQL matrix: GREEN'
