\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('iclub.subject_selection_isolated', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'SUBJECT SELECTION REFUSED: iclub.subject_selection_isolated=true is required.';
  END IF;
END
$$;

BEGIN;

CREATE TEMP TABLE subject_selection_people(
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
    VALUES(uid,'authenticated','authenticated','subject-selection-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',now(),now(),false,false);

    INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
    VALUES(uid,'Subject','Selection '||k,'ru',now(),false);

    INSERT INTO subject_selection_people VALUES(k,uid);
  END LOOP;
END
$people$;

-- A legacy row proves the beta selector never rewrites public.user_subjects.
INSERT INTO public.user_subjects(user_id,subject_id,mode,is_pinned)
SELECT user_id,1,'competitive',false
FROM subject_selection_people
WHERE person_key='free';

DO $canaries$
DECLARE
  v jsonb;
  uid uuid;
BEGIN
  SELECT user_id INTO uid FROM subject_selection_people WHERE person_key='free';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'free','subject-selection-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM subject_selection_people WHERE person_key='plus';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'plus','subject-selection-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM subject_selection_people WHERE person_key='pro';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'pro','subject-selection-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro canary setup failed: %',v;
  END IF;
END
$canaries$;

UPDATE private.iclub_global_ai_runtime_config
SET plans_ui_enabled=true,
    plans_rollout_mode='canary',
    checkout_enabled=false,
    updated_at=now()
WHERE id=1;

UPDATE private.iclub_commercial_access_config
SET subject_limits_mode='shadow',
    subject_selection_ui_enabled=true,
    updated_at=now()
WHERE id=1;

-- Ordinary Free learner remains outside the beta selector.
DO $normal_gate$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM subject_selection_people WHERE person_key='normal');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_subject_selection_bootstrap_v1();
  IF coalesce((v->>'visible')::boolean,true)
     OR v->>'reason'<>'rollout_unavailable' THEN
    RAISE EXCEPTION 'Normal learner escaped subject-selection canary gate: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('mathematics',true,false);
  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'rollout_unavailable' THEN
    RAISE EXCEPTION 'Normal learner mutated beta subject slots: %',v;
  END IF;
END
$normal_gate$;

-- Free: exactly one study slot and one Competitive slot.
DO $free_matrix$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM subject_selection_people WHERE person_key='free');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_subject_selection_bootstrap_v1();

  IF coalesce((v->>'visible')::boolean,false) IS NOT TRUE
     OR v->>'plan_code'<>'free'
     OR (v->>'study_subject_limit')::integer<>1
     OR (v->>'competitive_subject_limit')::integer<>1
     OR coalesce((v->>'all_available_subjects')::boolean,true) IS NOT FALSE
     OR coalesce((v->>'access_unchanged')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free subject bootstrap mismatch: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('not-a-real-subject',true,false);
  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'subject_unavailable' THEN
    RAISE EXCEPTION 'Unknown subject was accepted by beta selector: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('english_a1',true,false);
  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'subject_unavailable' THEN
    RAISE EXCEPTION 'Inactive subject was accepted by beta selector: %',v;
  END IF;

  UPDATE public.subjects SET is_active=true WHERE subject_key='english_a1';
  v:=public.set_iclub_my_subject_slot_v1('english_a1',true,true);
  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'competitive_requires_main_subject' THEN
    RAISE EXCEPTION 'Non-main subject entered Competitive: %',v;
  END IF;
  UPDATE public.subjects SET is_active=false WHERE subject_key='english_a1';

  v:=public.set_iclub_my_subject_slot_v1('mathematics',true,false);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free first study selection failed: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('biology',true,false);
  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'study_subject_limit_reached' THEN
    RAISE EXCEPTION 'Free second study selection escaped limit: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('mathematics',true,true);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free Competitive selection failed: %',v;
  END IF;

  v:=public.get_iclub_subject_selection_bootstrap_v1();
  IF (v->>'study_selected_count')::integer<>1
     OR (v->>'competitive_selected_count')::integer<>1 THEN
    RAISE EXCEPTION 'Free selection counters mismatch: %',v;
  END IF;
END
$free_matrix$;

-- Plus: three study slots and two Competitive slots.
DO $plus_matrix$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM subject_selection_people WHERE person_key='plus');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_subject_selection_bootstrap_v1();
  IF v->>'plan_code'<>'plus'
     OR (v->>'study_subject_limit')::integer<>3
     OR (v->>'competitive_subject_limit')::integer<>2 THEN
    RAISE EXCEPTION 'Plus subject bootstrap mismatch: %',v;
  END IF;

  PERFORM public.set_iclub_my_subject_slot_v1('mathematics',true,false);
  PERFORM public.set_iclub_my_subject_slot_v1('biology',true,false);
  PERFORM public.set_iclub_my_subject_slot_v1('chemistry',true,false);

  v:=public.set_iclub_my_subject_slot_v1('economics',true,false);
  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'study_subject_limit_reached' THEN
    RAISE EXCEPTION 'Plus fourth study selection escaped limit: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('mathematics',true,true);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus first Competitive selection failed: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('biology',true,true);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus second Competitive selection failed: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('chemistry',true,true);
  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'competitive_subject_limit_reached' THEN
    RAISE EXCEPTION 'Plus third Competitive selection escaped limit: %',v;
  END IF;

  v:=public.get_iclub_subject_selection_bootstrap_v1();
  IF (v->>'study_selected_count')::integer<>3
     OR (v->>'competitive_selected_count')::integer<>2 THEN
    RAISE EXCEPTION 'Plus selection counters mismatch: %',v;
  END IF;
END
$plus_matrix$;

-- Pro: all active subjects are included without study-slot selection; Competitive remains capped at 2.
DO $pro_matrix$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM subject_selection_people WHERE person_key='pro');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_subject_selection_bootstrap_v1();
  IF v->>'plan_code'<>'pro'
     OR v->'study_subject_limit'<>'null'::jsonb
     OR coalesce((v->>'all_available_subjects')::boolean,false) IS NOT TRUE
     OR (v->>'competitive_subject_limit')::integer<>2 THEN
    RAISE EXCEPTION 'Pro subject bootstrap mismatch: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('mathematics',true,true);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro first Competitive selection failed: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('economics',true,true);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro second Competitive selection failed: %',v;
  END IF;

  v:=public.set_iclub_my_subject_slot_v1('biology',true,true);
  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'competitive_subject_limit_reached' THEN
    RAISE EXCEPTION 'Pro third Competitive selection escaped limit: %',v;
  END IF;
END
$pro_matrix$;

-- Beta selection never touches legacy subject configuration or migration state.
DO $preservation$
DECLARE
  c integer;
  uid uuid:=(SELECT user_id FROM subject_selection_people WHERE person_key='free');
BEGIN
  SELECT count(*) INTO c
  FROM public.user_subjects
  WHERE user_id=uid;

  IF c<>1 THEN
    RAISE EXCEPTION 'Shadow selector mutated legacy public.user_subjects rows=%',c;
  END IF;

  IF EXISTS(
    SELECT 1
    FROM private.iclub_commercial_migration_state
    WHERE user_id IN (SELECT user_id FROM subject_selection_people)
      AND migration_state='migrated'
  ) THEN
    RAISE EXCEPTION 'Shadow UI finalized a learner migration';
  END IF;
END
$preservation$;

DO $privileges$
BEGIN
  IF has_function_privilege('anon','public.get_iclub_subject_selection_bootstrap_v1()','EXECUTE')
     OR has_function_privilege('anon','public.set_iclub_my_subject_slot_v1(text,boolean,boolean)','EXECUTE') THEN
    RAISE EXCEPTION 'Anonymous role received beta subject-selection access';
  END IF;

  IF NOT has_function_privilege('authenticated','public.get_iclub_subject_selection_bootstrap_v1()','EXECUTE')
     OR NOT has_function_privilege('authenticated','public.set_iclub_my_subject_slot_v1(text,boolean,boolean)','EXECUTE') THEN
    RAISE EXCEPTION 'Authenticated canary cannot use browser-safe subject-selection contract';
  END IF;
END
$privileges$;

UPDATE private.iclub_commercial_access_config
SET subject_selection_ui_enabled=false,
    subject_limits_mode='off',
    updated_at=now()
WHERE id=1;

UPDATE private.iclub_global_ai_runtime_config
SET plans_ui_enabled=false,
    plans_rollout_mode='off',
    updated_at=now()
WHERE id=1;

ROLLBACK;

DO $cleanup$
DECLARE
  c integer;
BEGIN
  SELECT count(*) INTO c
  FROM auth.users
  WHERE email like 'subject-selection-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Subject-selection matrix rollback left synthetic users=%',c;
  END IF;

  SELECT count(*) INTO c
  FROM private.iclub_subject_slot_selections;

  IF c<>0 THEN
    RAISE EXCEPTION 'Subject-selection matrix rollback left shadow selections=%',c;
  END IF;
END
$cleanup$;

\echo 'iClub subject-selection shadow UI v1 SQL matrix: GREEN'