\set ON_ERROR_STOP on

DO $$
BEGIN
  IF current_setting('iclub.canary_readiness_isolated', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'GLOBAL AI CANARY READINESS REFUSED: iclub.canary_readiness_isolated=true is required.';
  END IF;
END
$$;

BEGIN;

ALTER TABLE public.tour_attempts
  ADD COLUMN IF NOT EXISTS user_id uuid,
  ADD COLUMN IF NOT EXISTS status text;

CREATE OR REPLACE FUNCTION private.exam_prep_has_active_protected_assessment_v1(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
AS $exam$
  SELECT false;
$exam$;

CREATE TEMP TABLE readiness_people(
  person_key text primary key,
  user_id uuid not null
) ON COMMIT DROP;

DO $people$
DECLARE
  k text;
  uid uuid;
BEGIN
  FOREACH k IN ARRAY ARRAY['free','plus','pro','normal','paid'] LOOP
    uid:=gen_random_uuid();

    INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
    VALUES(
      uid,'authenticated','authenticated',
      'global-ai-readiness-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',
      now(),now(),false,false
    );

    INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
    VALUES(uid,'GlobalAI','Readiness '||k,'en',now(),false);

    INSERT INTO readiness_people VALUES(k,uid);
  END LOOP;
END
$people$;

DO $canaries$
DECLARE
  v jsonb;
  uid uuid;
BEGIN
  SELECT user_id INTO uid FROM readiness_people WHERE person_key='free';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'free','readiness-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM readiness_people WHERE person_key='plus';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'plus','readiness-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM readiness_people WHERE person_key='pro';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'pro','readiness-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro canary setup failed: %',v;
  END IF;

  IF (SELECT count(*) FROM private.iclub_product_canary_users WHERE enabled)<>3 THEN
    RAISE EXCEPTION 'Canary readiness requires exactly three enabled canaries';
  END IF;
END
$canaries$;

-- Normal learner remains default Free without a stored subscription row.
DO $default_free$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='normal');
BEGIN
  v:=public.get_iclub_subscription_capabilities_service_v1(uid);

  IF coalesce((v->>'resolved')::boolean,false) IS NOT TRUE
     OR v->>'plan_code'<>'free'
     OR v->>'plan_source'<>'default_free' THEN
    RAISE EXCEPTION 'Default Free readiness mismatch: %',v;
  END IF;

  IF EXISTS(
    SELECT 1 FROM private.iclub_subscription_entitlements WHERE user_id=uid
  ) THEN
    RAISE EXCEPTION 'Default Free created an entitlement row';
  END IF;
END
$default_free$;

-- AI OFF must remain a fully valid state.
DO $ai_off$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='free');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_ai_ui_bootstrap_v1();
  IF coalesce((v->>'visible')::boolean,true)
     OR v->>'reason'<>'ui_disabled' THEN
    RAISE EXCEPTION 'AI OFF did not remain fail-closed/non-disruptive: %',v;
  END IF;
END
$ai_off$;

UPDATE private.iclub_global_ai_runtime_config
SET ui_enabled=true,
    gateway_enabled=true,
    generation_enabled=true,
    kill_switch=false,
    plans_ui_enabled=true,
    checkout_enabled=false,
    global_ai_rollout_mode='canary',
    plans_rollout_mode='canary',
    updated_at=now()
WHERE id=1;

UPDATE private.iclub_commercial_access_config
SET subject_limits_mode='shadow',
    subject_selection_ui_enabled=true,
    canary_subject_access_enforced=true,
    updated_at=now()
WHERE id=1;

-- Normal learners must still be excluded from the beta surface even though they resolve to Free.
DO $rollout_scope$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='normal');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.get_iclub_plan_ui_bootstrap_v1();
  IF coalesce((v->>'visible')::boolean,true)
     OR v->>'reason'<>'rollout_unavailable' THEN
    RAISE EXCEPTION 'Non-canary Plans rollout leak: %',v;
  END IF;

  v:=public.get_iclub_ai_ui_bootstrap_v1();
  IF coalesce((v->>'visible')::boolean,true)
     OR v->>'reason'<>'rollout_unavailable' THEN
    RAISE EXCEPTION 'Non-canary AI rollout leak: %',v;
  END IF;

  v:=public.get_iclub_my_subject_access_v1('mathematics','study');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'enforced')::boolean,true)
     OR v->>'reason'<>'not_canary' THEN
    RAISE EXCEPTION 'Non-canary subject access changed: %',v;
  END IF;
END
$rollout_scope$;

-- Free canary: prepared route only; generated route must remain upgrade-gated.
DO $free_guard$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='free');
BEGIN
  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'general','global','app_help','prepared','en',0
  );

  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'ai_usage_policy_code'<>'free_v1' THEN
    RAISE EXCEPTION 'Free prepared guard mismatch: %',v;
  END IF;

  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'mathematics','exam_prep','freeform_question','generated','en',20
  );

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'generation_upgrade_required' THEN
    RAISE EXCEPTION 'Free generated guard mismatch: %',v;
  END IF;

  v:=public.reserve_iclub_ai_usage_service_v1(gen_random_uuid(),uid,'free_v1','generated');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'generation_not_entitled' THEN
    RAISE EXCEPTION 'Free usage ledger accepted generated route: %',v;
  END IF;
END
$free_guard$;

-- Free gets exactly three successful prepared replies in one five-hour period.
DO $free_usage$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='free');
  rid uuid;
  i integer;
  v_reset timestamptz;
BEGIN
  FOR i IN 1..3 LOOP
    rid:=gen_random_uuid();
    v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'free_v1','prepared');
    IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
      RAISE EXCEPTION 'Free prepared reservation % failed: %',i,v;
    END IF;

    v:=public.finalize_iclub_ai_usage_service_v1(rid,'completed');
    IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
      RAISE EXCEPTION 'Free prepared completion % failed: %',i,v;
    END IF;
  END LOOP;

  SELECT reset_at INTO v_reset
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid AND status='active';

  IF v_reset IS NULL
     OR v_reset < now()+interval '4 hours 59 minutes'
     OR v_reset > now()+interval '5 hours 1 minute' THEN
    RAISE EXCEPTION 'Free reset window is not five hours: %',v_reset;
  END IF;

  v:=public.reserve_iclub_ai_usage_service_v1(gen_random_uuid(),uid,'free_v1','prepared');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'usage_exhausted' THEN
    RAISE EXCEPTION 'Free fourth prepared reply escaped exhaustion: %',v;
  END IF;

  UPDATE private.iclub_ai_usage_periods
  SET started_at=now()-interval '5 hours 1 minute',
      reset_at=now()-interval '1 minute',
      reserved_units=0
  WHERE user_id=uid AND status='active';

  rid:=gen_random_uuid();
  v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'free_v1','prepared');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free did not reopen after five-hour reset: %',v;
  END IF;

  PERFORM public.finalize_iclub_ai_usage_service_v1(rid,'released','readiness_cleanup');
END
$free_usage$;

-- Plus: duplicate request IDs cannot double-charge, and a too-expensive route exhausts the whole period.
DO $plus_usage$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='plus');
  rid uuid:=gen_random_uuid();
  rid2 uuid:=gen_random_uuid();
  committed integer;
BEGIN
  v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'plus_v1','generated');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus first generated reservation failed: %',v;
  END IF;

  v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'plus_v1','generated');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'duplicate')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus duplicate reservation not idempotent: %',v;
  END IF;

  v:=public.finalize_iclub_ai_usage_service_v1(rid,'completed');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus generated completion failed: %',v;
  END IF;

  v:=public.finalize_iclub_ai_usage_service_v1(rid,'completed');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'duplicate')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus duplicate completion not idempotent: %',v;
  END IF;

  SELECT committed_units INTO committed
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid AND status='active';

  IF committed<>5 THEN
    RAISE EXCEPTION 'Plus duplicate request double-charged units=%',committed;
  END IF;

  v:=public.reserve_iclub_ai_usage_service_v1(rid2,uid,'plus_v1','generated');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'usage_exhausted' THEN
    RAISE EXCEPTION 'Plus second generated route should exhaust remaining period: %',v;
  END IF;

  v:=public.reserve_iclub_ai_usage_service_v1(gen_random_uuid(),uid,'plus_v1','prepared');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'usage_exhausted' THEN
    RAISE EXCEPTION 'Limited mode leaked after Plus exhaustion: %',v;
  END IF;
END
$plus_usage$;

-- Failed first delivery must not start a five-hour clock.
DO $failure_no_charge$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='pro');
  rid uuid:=gen_random_uuid();
  period_status text;
  started timestamptz;
  reset_at timestamptz;
BEGIN
  v:=public.reserve_iclub_ai_usage_service_v1(rid,uid,'pro_v1','prepared');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro provisional reservation failed: %',v;
  END IF;

  v:=public.finalize_iclub_ai_usage_service_v1(rid,'released','provider_error');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Released failure cleanup failed: %',v;
  END IF;

  SELECT status,started_at,reset_at
  INTO period_status,started,reset_at
  FROM private.iclub_ai_usage_periods
  WHERE user_id=uid
  ORDER BY created_at DESC
  LIMIT 1;

  IF period_status<>'closed' OR started IS NOT NULL OR reset_at IS NOT NULL THEN
    RAISE EXCEPTION 'Failed first response started usage clock status=% started=% reset=%',
      period_status,started,reset_at;
  END IF;
END
$failure_no_charge$;

-- Protected assessment must block at the guard before any usage reservation exists.
DO $exam_first$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='pro');
  before_n integer;
  after_n integer;
BEGIN
  INSERT INTO public.tour_attempts(user_id,status)
  VALUES(uid,'in_progress');

  SELECT count(*) INTO before_n
  FROM private.iclub_ai_usage_reservations
  WHERE user_id=uid;

  v:=public.get_iclub_global_ai_guard_service_v1(
    uid,'mathematics','exam_prep','topic_explanation','prepared','en',0
  );

  SELECT count(*) INTO after_n
  FROM private.iclub_ai_usage_reservations
  WHERE user_id=uid;

  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'active_assessment'
     OR before_n<>after_n THEN
    RAISE EXCEPTION 'Protected assessment did not block before usage: guard=% before=% after=%',
      v,before_n,after_n;
  END IF;

  DELETE FROM public.tour_attempts WHERE user_id=uid AND status='in_progress';
END
$exam_first$;

-- Subject-plan boundaries: Free selection, Plus limits and Pro all-study behavior.
DO $subjects$
DECLARE
  v jsonb;
  free_uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='free');
  plus_uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='plus');
  pro_uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='pro');
BEGIN
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  PERFORM set_config('request.jwt.claim.sub',free_uid::text,true);
  v:=public.set_iclub_my_subject_slot_v1('mathematics',true,true);
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free plan subject selection failed: %',v;
  END IF;

  v:=public.get_iclub_my_subject_access_v1('biology','study');
  IF coalesce((v->>'allowed')::boolean,true)
     OR v->>'reason'<>'subject_not_in_plan' THEN
    RAISE EXCEPTION 'Free subject boundary failed: %',v;
  END IF;

  PERFORM set_config('request.jwt.claim.sub',plus_uid::text,true);
  PERFORM public.set_iclub_my_subject_slot_v1('mathematics',true,true);
  PERFORM public.set_iclub_my_subject_slot_v1('biology',true,true);
  PERFORM public.set_iclub_my_subject_slot_v1('chemistry',true,false);

  v:=public.set_iclub_my_subject_slot_v1('economics',true,false);
  IF coalesce((v->>'ok')::boolean,true)
     OR v->>'reason'<>'study_subject_limit_reached' THEN
    RAISE EXCEPTION 'Plus fourth subject escaped limit: %',v;
  END IF;

  PERFORM set_config('request.jwt.claim.sub',pro_uid::text,true);
  v:=public.get_iclub_my_subject_access_v1('economics','study');
  IF coalesce((v->>'allowed')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'plan_all_subjects' THEN
    RAISE EXCEPTION 'Pro all-subject study access failed: %',v;
  END IF;
END
$subjects$;

-- Downgrade changes capability, never erases subject-slot state or legacy evidence.
DO $downgrade$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM readiness_people WHERE person_key='paid');
  activate_id uuid:=gen_random_uuid();
  downgrade_id uuid:=gen_random_uuid();
  slot_before integer;
  slot_after integer;
BEGIN
  UPDATE private.iclub_commercial_access_config
  SET lifecycle_enabled=true
  WHERE id=1;

  v:=public.apply_iclub_subscription_event_service_v1(
    activate_id,uid,'activate','pro',now(),now(),now()+interval '30 days','readiness-ci'
  );
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Paid Pro activation failed: %',v;
  END IF;

  INSERT INTO private.iclub_subject_slot_selections(
    user_id,subject_key,study_selected,competitive_selected,source,selected_at,updated_at
  ) VALUES
    (uid,'mathematics',true,true,'readiness-ci',now(),now()),
    (uid,'biology',true,false,'readiness-ci',now(),now());

  SELECT count(*) INTO slot_before
  FROM private.iclub_subject_slot_selections
  WHERE user_id=uid;

  v:=public.apply_iclub_subscription_event_service_v1(
    downgrade_id,uid,'downgrade','free',now(),now(),now()+interval '30 days','readiness-ci'
  );
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro to Free downgrade failed: %',v;
  END IF;

  SELECT count(*) INTO slot_after
  FROM private.iclub_subject_slot_selections
  WHERE user_id=uid;

  IF slot_after<>slot_before THEN
    RAISE EXCEPTION 'Downgrade erased subject-slot history before=% after=%',slot_before,slot_after;
  END IF;

  v:=public.get_iclub_subscription_capabilities_service_v1(uid);
  IF v->>'plan_code'<>'free' OR v->>'plan_source'<>'explicit_entitlement' THEN
    RAISE EXCEPTION 'Downgrade capability mismatch: %',v;
  END IF;
END
$downgrade$;

-- Return all runtime switches to dormant baseline inside the test transaction.
UPDATE private.iclub_global_ai_runtime_config
SET ui_enabled=false,
    gateway_enabled=false,
    generation_enabled=false,
    kill_switch=true,
    plans_ui_enabled=false,
    checkout_enabled=false,
    global_ai_rollout_mode='off',
    plans_rollout_mode='off',
    updated_at=now()
WHERE id=1;

UPDATE private.iclub_commercial_access_config
SET lifecycle_enabled=false,
    subject_limits_mode='off',
    subject_selection_ui_enabled=false,
    canary_subject_access_enforced=false,
    updated_at=now()
WHERE id=1;

ROLLBACK;

DO $clean$
DECLARE
  c integer;
BEGIN
  SELECT count(*) INTO c
  FROM auth.users
  WHERE email like 'global-ai-readiness-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Readiness matrix rollback left synthetic users=%',c;
  END IF;

  IF (SELECT count(*) FROM private.iclub_product_canary_users)<>0
     OR (SELECT count(*) FROM private.iclub_ai_usage_periods)<>0
     OR (SELECT count(*) FROM private.iclub_ai_usage_reservations)<>0
     OR (SELECT count(*) FROM private.iclub_subscription_entitlements)<>0
     OR (SELECT count(*) FROM private.iclub_subject_slot_selections)<>0 THEN
    RAISE EXCEPTION 'Readiness matrix rollback left commercial/AI residue';
  END IF;
END
$clean$;

\echo 'iClub Global AI + tariffs controlled canary readiness matrix: GREEN'
