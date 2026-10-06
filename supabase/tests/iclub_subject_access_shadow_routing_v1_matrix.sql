\set ON_ERROR_STOP on

DO $guard$
BEGIN
  IF current_setting('iclub.subject_shadow_routing_isolated', true) IS DISTINCT FROM 'true' THEN
    RAISE EXCEPTION 'SUBJECT SHADOW ROUTING REFUSED: isolated flag required';
  END IF;
END
$guard$;

BEGIN;

CREATE TEMP TABLE shadow_people(
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

    INSERT INTO auth.users(
      id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous
    ) VALUES (
      uid,'authenticated','authenticated',
      'subject-shadow-'||k||'-'||replace(uid::text,'-','')||'@invalid.example',
      now(),now(),false,false
    );

    INSERT INTO public.users(
      id,first_name,last_name,language_code,created_at,must_change_password
    ) VALUES (
      uid,'Shadow','Routing '||k,'en',now(),false
    );

    INSERT INTO shadow_people VALUES(k,uid);
  END LOOP;
END
$people$;

-- Default state is completely dormant.
DO $dormant$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM shadow_people WHERE person_key='free');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'mathematics','catalog_subject_hub'
  );

  IF coalesce((v->>'observed')::boolean,true)
     OR v->>'reason'<>'shadow_routing_disabled'
     OR coalesce((v->>'access_unchanged')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Dormant shadow route mismatch: %',v;
  END IF;

  IF EXISTS(select 1 from private.iclub_subject_access_shadow_events) THEN
    RAISE EXCEPTION 'Dormant route wrote audit rows';
  END IF;
END
$dormant$;

-- Enable only the isolated canary shadow path.
UPDATE private.iclub_commercial_access_config
SET subject_limits_mode='shadow',
    subject_selection_ui_enabled=true,
    subject_access_shadow_routing_enabled=true,
    updated_at=now()
WHERE id=1;

UPDATE private.iclub_global_ai_runtime_config
SET plans_rollout_mode='canary',
    updated_at=now()
WHERE id=1;

DO $canaries$
DECLARE
  v jsonb;
  uid uuid;
BEGIN
  SELECT user_id INTO uid FROM shadow_people WHERE person_key='free';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'free','shadow-routing-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Free canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM shadow_people WHERE person_key='plus';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'plus','shadow-routing-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Plus canary setup failed: %',v;
  END IF;

  SELECT user_id INTO uid FROM shadow_people WHERE person_key='pro';
  v:=public.set_iclub_product_canary_service_v1(uid,true,'pro','shadow-routing-ci');
  IF coalesce((v->>'ok')::boolean,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'Pro canary setup failed: %',v;
  END IF;
END
$canaries$;

-- Prepare shadow selections without touching legacy public.user_subjects.
INSERT INTO private.iclub_subject_slot_selections(
  user_id,subject_key,study_selected,competitive_selected,source,selected_at,updated_at
)
SELECT user_id,'mathematics',true,true,'shadow-routing-ci',now(),now()
FROM shadow_people WHERE person_key='free';

INSERT INTO private.iclub_subject_slot_selections(
  user_id,subject_key,study_selected,competitive_selected,source,selected_at,updated_at
)
SELECT user_id,'mathematics',true,true,'shadow-routing-ci',now(),now()
FROM shadow_people WHERE person_key='plus';

INSERT INTO private.iclub_subject_slot_selections(
  user_id,subject_key,study_selected,competitive_selected,source,selected_at,updated_at
)
SELECT user_id,'biology',true,false,'shadow-routing-ci',now(),now()
FROM shadow_people WHERE person_key='plus';

INSERT INTO private.iclub_subject_slot_selections(
  user_id,subject_key,study_selected,competitive_selected,source,selected_at,updated_at
)
SELECT user_id,'chemistry',true,false,'shadow-routing-ci',now(),now()
FROM shadow_people WHERE person_key='plus';

INSERT INTO private.iclub_subject_slot_selections(
  user_id,subject_key,study_selected,competitive_selected,source,selected_at,updated_at
)
SELECT user_id,'mathematics',true,true,'shadow-routing-ci',now(),now()
FROM shadow_people WHERE person_key='pro';

-- Normal Free user is not in the canary and cannot write shadow telemetry.
DO $noncanary$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM shadow_people WHERE person_key='normal');
  before_count integer;
BEGIN
  SELECT count(*) INTO before_count FROM private.iclub_subject_access_shadow_events;

  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'mathematics','catalog_subject_hub'
  );

  IF coalesce((v->>'observed')::boolean,true)
     OR v->>'reason'<>'rollout_unavailable' THEN
    RAISE EXCEPTION 'Non-canary escaped shadow rollout gate: %',v;
  END IF;

  IF (select count(*) from private.iclub_subject_access_shadow_events)<>before_count THEN
    RAISE EXCEPTION 'Non-canary wrote a shadow route event';
  END IF;
END
$noncanary$;

-- Free: selected study/Competitive work; unselected study is a future block.
DO $free$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM shadow_people WHERE person_key='free');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'mathematics','catalog_subject_hub'
  );

  IF coalesce((v->>'observed')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'would_allow')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'subject_selected'
     OR v->>'plan_code'<>'free'
     OR coalesce((v->>'access_unchanged')::boolean,false) IS NOT TRUE
     OR v ? 'allowed' THEN
    RAISE EXCEPTION 'Free selected study route mismatch: %',v;
  END IF;

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'biology','subject_practice'
  );

  IF coalesce((v->>'observed')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'would_allow')::boolean,true)
     OR v->>'reason'<>'subject_not_selected' THEN
    RAISE EXCEPTION 'Free unselected study route mismatch: %',v;
  END IF;

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'mathematics','tour_start'
  );

  IF coalesce((v->>'would_allow')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'competitive_selected' THEN
    RAISE EXCEPTION 'Free selected Competitive route mismatch: %',v;
  END IF;

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'biology','subject_tours'
  );

  IF coalesce((v->>'would_allow')::boolean,true)
     OR v->>'reason'<>'competitive_not_selected' THEN
    RAISE EXCEPTION 'Free unselected Competitive route mismatch: %',v;
  END IF;
END
$free$;

-- History stays readable, including an inactive but known subject.
DO $history$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM shadow_people WHERE person_key='free');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'biology','global_recommendations'
  );

  IF coalesce((v->>'would_allow')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'history_preserved'
     OR v->>'access_class'<>'history' THEN
    RAISE EXCEPTION 'Unselected history route was not preserved: %',v;
  END IF;

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'english_a1','profile_recommendations'
  );

  IF coalesce((v->>'observed')::boolean,false) IS NOT TRUE
     OR coalesce((v->>'would_allow')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'history_preserved' THEN
    RAISE EXCEPTION 'Inactive-subject history was not preserved: %',v;
  END IF;

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'english_a1','global_books'
  );

  IF coalesce((v->>'observed')::boolean,true)
     OR v->>'reason'<>'subject_unavailable' THEN
    RAISE EXCEPTION 'Inactive subject opened a new-study route: %',v;
  END IF;
END
$history$;

-- Plus: three study selections do not imply Competitive for all three.
DO $plus$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM shadow_people WHERE person_key='plus');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'chemistry','subject_books'
  );

  IF coalesce((v->>'would_allow')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'subject_selected'
     OR v->>'plan_code'<>'plus' THEN
    RAISE EXCEPTION 'Plus selected study route mismatch: %',v;
  END IF;

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'economics','subject_exam_prep'
  );

  IF coalesce((v->>'would_allow')::boolean,true)
     OR v->>'reason'<>'subject_not_selected' THEN
    RAISE EXCEPTION 'Plus unselected study route mismatch: %',v;
  END IF;

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'chemistry','subject_tours'
  );

  IF coalesce((v->>'would_allow')::boolean,true)
     OR v->>'reason'<>'competitive_not_selected' THEN
    RAISE EXCEPTION 'Plus study-only subject incorrectly gained Competitive: %',v;
  END IF;
END
$plus$;

-- Pro gets all active study subjects, but Competitive still needs selection.
DO $pro$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM shadow_people WHERE person_key='pro');
BEGIN
  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'economics','subject_practice'
  );

  IF coalesce((v->>'would_allow')::boolean,false) IS NOT TRUE
     OR v->>'reason'<>'plan_all_subjects'
     OR v->>'plan_code'<>'pro' THEN
    RAISE EXCEPTION 'Pro all-subject study route mismatch: %',v;
  END IF;

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'economics','subject_tours'
  );

  IF coalesce((v->>'would_allow')::boolean,true)
     OR v->>'reason'<>'competitive_not_selected' THEN
    RAISE EXCEPTION 'Pro all-subject plan bypassed Competitive selection: %',v;
  END IF;
END
$pro$;

-- Unknown route/subject fail closed for telemetry and do not create rows.
DO $invalid$
DECLARE
  v jsonb;
  uid uuid:=(SELECT user_id FROM shadow_people WHERE person_key='free');
  before_count integer;
BEGIN
  SELECT count(*) INTO before_count FROM private.iclub_subject_access_shadow_events;

  PERFORM set_config('request.jwt.claim.sub',uid::text,true);
  PERFORM set_config('request.jwt.claim.role','authenticated',true);

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'mathematics','invented_route'
  );

  IF coalesce((v->>'observed')::boolean,true)
     OR v->>'reason'<>'route_not_allowed' THEN
    RAISE EXCEPTION 'Unknown route was accepted: %',v;
  END IF;

  v:=public.record_iclub_my_subject_access_shadow_v1(
    'not_a_subject','subject_practice'
  );

  IF coalesce((v->>'observed')::boolean,true)
     OR v->>'reason'<>'subject_unavailable' THEN
    RAISE EXCEPTION 'Unknown subject was accepted: %',v;
  END IF;

  IF (select count(*) from private.iclub_subject_access_shadow_events)<>before_count THEN
    RAISE EXCEPTION 'Invalid observations wrote audit rows';
  END IF;
END
$invalid$;

DO $privileges$
BEGIN
  IF has_function_privilege(
       'anon',
       'public.record_iclub_my_subject_access_shadow_v1(text,text)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'Anonymous role can write subject shadow telemetry';
  END IF;

  IF NOT has_function_privilege(
       'authenticated',
       'public.record_iclub_my_subject_access_shadow_v1(text,text)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'Authenticated canary cannot call subject shadow observer';
  END IF;

  IF has_table_privilege(
       'authenticated',
       'private.iclub_subject_access_shadow_events',
       'SELECT'
     )
     OR has_table_privilege(
       'authenticated',
       'private.iclub_subject_access_shadow_events',
       'INSERT'
     ) THEN
    RAISE EXCEPTION 'Browser role can access private shadow audit table';
  END IF;
END
$privileges$;

-- This phase must never modify legacy subject preferences.
DO $legacy_unchanged$
DECLARE
  c integer;
BEGIN
  SELECT count(*) INTO c FROM public.user_subjects;

  IF c<>0 THEN
    RAISE EXCEPTION 'Shadow routing unexpectedly touched legacy user_subjects rows=%',c;
  END IF;
END
$legacy_unchanged$;

ROLLBACK;

DO $post_rollback$
DECLARE
  c integer;
BEGIN
  SELECT count(*) INTO c
  FROM auth.users
  WHERE email like 'subject-shadow-%@invalid.example';

  IF c<>0 THEN
    RAISE EXCEPTION 'Shadow routing matrix left synthetic users=%',c;
  END IF;

  SELECT count(*) INTO c FROM private.iclub_subject_access_shadow_events;
  IF c<>0 THEN
    RAISE EXCEPTION 'Shadow routing matrix left audit rows=%',c;
  END IF;
END
$post_rollback$;

\echo 'iClub subject access shadow routing v1 SQL matrix: GREEN'
