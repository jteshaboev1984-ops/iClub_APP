-- Economics written beta: consent-first, owner-scoped and restricted to existing active Math beta cohort.
-- ONLY new isolated private beta tables + exact v3 release flags, never historical task/user progress.
-- Joining a learner requires a direct authenticated user click; SQL migration NEVER assigns users.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='60s';

CREATE TABLE private.iclub_econ_written_beta_control_v1 (
 singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
 enabled boolean NOT NULL DEFAULT false,
 max_members smallint NOT NULL DEFAULT 3 CHECK(max_members BETWEEN 1 AND 3),
 consent_copy_version text NOT NULL DEFAULT 'economics_written_12_tasks_v1_20261028',
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO private.iclub_econ_written_beta_control_v1(singleton,enabled,max_members)
 VALUES(true,false,3);

CREATE TABLE private.iclub_econ_written_beta_optins_v1 (
 user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE RESTRICT,
 status text NOT NULL CHECK(status IN ('joined','withdrawn')),
 consent_copy_version text NOT NULL,
 granted_at timestamptz NOT NULL DEFAULT now(),
 withdrawn_at timestamptz,
 plan_id uuid NOT NULL UNIQUE REFERENCES private.iclub_exam_core_written_plans_v1(id) ON DELETE RESTRICT,
 CHECK ((status='joined' AND withdrawn_at IS NULL) OR
        (status='withdrawn' AND withdrawn_at IS NOT NULL))
);
ALTER TABLE private.iclub_econ_written_beta_control_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_econ_written_beta_optins_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_econ_written_beta_control_v1 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON private.iclub_econ_written_beta_optins_v1 FROM PUBLIC,anon,authenticated;

-- Only active members of the *existing* Mathematics canary cohort who have
-- prior general beta consent, have Economics in their subjects, and already
-- finished the Economics entry check can voluntarily join this separate beta.
CREATE OR REPLACE FUNCTION private.iclub_econ_written_beta_eligible_v1(p_user uuid)
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $f$
 SELECT p_user IS NOT NULL
 AND EXISTS (
  SELECT 1 FROM private.exam_prep_beta_cohorts c
  JOIN private.exam_prep_beta_members m ON m.cohort_id=c.id
  JOIN private.exam_prep_beta_consents co
    ON co.cohort_id=c.id AND co.user_id=m.user_id
  WHERE c.program_key='math_as_p1_p5'
    AND c.cohort_key='math_as_p1_p5_beta_2026_09_01'
    AND c.cohort_status='canary'
    AND m.user_id=p_user AND m.member_status='active'
    AND co.consent_status='granted'
    AND co.consent_scope='exam_prep_controlled_beta_v1'
    AND co.revoked_at IS NULL
 )
 AND EXISTS(
  SELECT 1 FROM public.user_subjects us
  JOIN public.subjects s ON s.id=us.subject_id
  WHERE us.user_id=p_user AND s.subject_key='economics' AND s.is_active
 )
 AND EXISTS(
  SELECT 1 FROM private.iclub_exam_native_mcq_attempts_v1 a
  WHERE a.user_id=p_user AND a.program_key='economics_9708'
    AND a.version_key='economics_2026_2028_v1'
    AND a.paper_code='P1' AND a.session_kind='diagnostic'
    AND a.status='finalized'
 );
$f$;
REVOKE ALL ON FUNCTION private.iclub_econ_written_beta_eligible_v1(uuid)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_econ_written_beta_eligible_v1(uuid)
 TO service_role;

CREATE OR REPLACE FUNCTION public.iclub_econ_written_beta_status_v1()
 RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid(); v_row record; v_joined boolean;
BEGIN
 IF v_user IS NULL THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 SELECT enabled,max_members INTO v_row
 FROM private.iclub_econ_written_beta_control_v1 WHERE singleton;
 SELECT EXISTS(SELECT 1 FROM private.iclub_econ_written_beta_optins_v1 o
   WHERE o.user_id=v_user AND o.status='joined'
     AND EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plans_v1 p
       WHERE p.id=o.plan_id AND p.learner_user_id=v_user AND p.status='active'))
 INTO v_joined;
 RETURN jsonb_build_object('ok',true,'joined',v_joined,
   'eligible',COALESCE(v_row.enabled,false) AND NOT EXISTS(
     SELECT 1 FROM private.iclub_econ_written_beta_optins_v1 o WHERE o.user_id=v_user)
     AND private.iclub_econ_written_beta_eligible_v1(v_user)
     AND (SELECT count(*) FROM private.iclub_econ_written_beta_optins_v1) <
         COALESCE(v_row.max_members,0));
END;
$f$;
REVOKE ALL ON FUNCTION public.iclub_econ_written_beta_status_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_econ_written_beta_status_v1()
 TO authenticated;

-- A join is a user-initiated opt-in, never an admin-generated assumption of consent.
-- The single control row serializes concurrent joins; max three members in wave 1.
CREATE OR REPLACE FUNCTION public.iclub_econ_written_beta_join_v1(p_confirm boolean)
 RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid(); v_ctl record; v_plan uuid;
 v_keys text[]:=ARRAY[
  'P2.A.a','P2.A.b','P2.A.c','P2.A.d','P2.A.e','P2.A.f',
  'P2.B1.a','P2.C1.a','P4.A.a','P4.A.c','P4.B1','P4.C1'
 ];
 v_task_version text:='economics_9708_written_editorial_candidate_v3_20261027';
 v_program text:='economics_9708'; v_version text:='economics_2026_2028_v1';
BEGIN
 IF v_user IS NULL THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 IF p_confirm IS DISTINCT FROM true THEN
  RETURN jsonb_build_object('ok',false,'code','consent_required');
 END IF;
 SELECT enabled,max_members,consent_copy_version INTO v_ctl
 FROM private.iclub_econ_written_beta_control_v1 WHERE singleton FOR UPDATE;
 IF NOT FOUND OR NOT v_ctl.enabled THEN
  RETURN jsonb_build_object('ok',false,'code','beta_closed');
 END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_econ_written_beta_optins_v1
   WHERE user_id=v_user AND status='joined') THEN
  RETURN jsonb_build_object('ok',true,'joined',true,'replayed',true);
 END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_econ_written_beta_optins_v1 WHERE user_id=v_user) THEN
  RETURN jsonb_build_object('ok',false,'code','beta_withdrawn');
 END IF;
 IF NOT private.iclub_econ_written_beta_eligible_v1(v_user) THEN
  RETURN jsonb_build_object('ok',false,'code','not_eligible');
 END IF;
 IF (SELECT count(*) FROM private.iclub_econ_written_beta_optins_v1)>=v_ctl.max_members THEN
  RETURN jsonb_build_object('ok',false,'code','beta_full');
 END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_core_written_access_v1
   WHERE learner_user_id=v_user AND program_key=v_program AND version_key=v_version)
  OR EXISTS(SELECT 1 FROM private.iclub_exam_core_written_plans_v1
   WHERE learner_user_id=v_user AND program_key=v_program AND version_key=v_version)
 THEN RETURN jsonb_build_object('ok',false,'code','existing_written_plan');
 END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1 t
  WHERE t.program_key=v_program AND t.version_key=v_version
  AND t.task_version=v_task_version AND t.task_key=ANY(v_keys)
  AND t.status='approved' AND t.release_enabled
  AND t.academic_review='approved' AND t.language_review='approved'
  AND t.source_review='approved' AND t.questions ?& ARRAY['en','ru','uz']
  AND t.answer_requirements ?& ARRAY['en','ru','uz']
  AND private.iclub_exam_written_source_ready_v1(
    t.program_key,t.version_key,t.task_key,t.task_version)
 )<>12 THEN
  RETURN jsonb_build_object('ok',false,'code','beta_content_unavailable');
 END IF;
 INSERT INTO private.iclub_exam_core_written_access_v1
  (learner_user_id,program_key,version_key,core_access,status,valid_from,valid_until)
 VALUES(v_user,v_program,v_version,true,'active',now(),now()+INTERVAL '28 days');
 INSERT INTO private.iclub_exam_core_written_plans_v1
  (learner_user_id,program_key,version_key,status)
 VALUES(v_user,v_program,v_version,'active') RETURNING id INTO v_plan;
 INSERT INTO private.iclub_exam_core_written_plan_items_v1
  (plan_id,learner_user_id,program_key,version_key,task_key,task_version,priority_order,mode)
 SELECT v_plan,v_user,v_program,v_version,k,v_task_version,i::integer,'practice'
 FROM unnest(v_keys) WITH ORDINALITY AS v(k,i);
 INSERT INTO private.iclub_econ_written_beta_optins_v1
  (user_id,status,consent_copy_version,plan_id)
 VALUES(v_user,'joined',v_ctl.consent_copy_version,v_plan);
 RETURN jsonb_build_object('ok',true,'joined',true,'replayed',false);
END;
$f$;
REVOKE ALL ON FUNCTION public.iclub_econ_written_beta_join_v1(boolean)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_econ_written_beta_join_v1(boolean)
 TO authenticated;

-- Revocation preserves work history; does not erase any attempted step.
CREATE OR REPLACE FUNCTION public.iclub_econ_written_beta_leave_v1()
 RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid(); v_plan uuid;
BEGIN
 IF v_user IS NULL THEN RETURN jsonb_build_object('ok',false,'code','not_authorized'); END IF;
 SELECT plan_id INTO v_plan
 FROM private.iclub_econ_written_beta_optins_v1
 WHERE user_id=v_user AND status='joined' FOR UPDATE;
 IF v_plan IS NULL THEN RETURN jsonb_build_object('ok',true,'left',true); END IF;
 UPDATE private.iclub_econ_written_beta_optins_v1 SET status='withdrawn',withdrawn_at=now()
 WHERE user_id=v_user;
 UPDATE private.iclub_exam_core_written_access_v1 SET status='revoked',core_access=false,updated_at=now()
 WHERE learner_user_id=v_user AND program_key='economics_9708'
 AND version_key='economics_2026_2028_v1';
 UPDATE private.iclub_exam_core_written_plans_v1 SET status='archived'
 WHERE id=v_plan AND learner_user_id=v_user AND status='active';
 RETURN jsonb_build_object('ok',true,'left',true);
END;
$f$;
REVOKE ALL ON FUNCTION public.iclub_econ_written_beta_leave_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_econ_written_beta_leave_v1()
 TO authenticated;

DO $qa$
DECLARE k text; v_keys text[]:=ARRAY[
 'P2.A.a','P2.A.b','P2.A.c','P2.A.d','P2.A.e','P2.A.f',
 'P2.B1.a','P2.C1.a','P4.A.a','P4.A.c','P4.B1','P4.C1'];
BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
   WHERE program_key='economics_9708'
   AND task_version='economics_9708_written_editorial_candidate_v3_20261027')<>22
 THEN RAISE EXCEPTION 'candidate_count_changed'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
   WHERE program_key='economics_9708' AND release_enabled)<>0
 THEN RAISE EXCEPTION 'unexpected_existing_written_release'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_access_v1)<>0
   OR (SELECT count(*) FROM private.iclub_exam_core_written_plans_v1)<>0
   OR (SELECT count(*) FROM private.iclub_exam_core_written_plan_items_v1)<>0
 THEN RAISE EXCEPTION 'nonempty_written_runtime'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_written_source_cards_v1
  WHERE program_key='economics_9708' AND source_version='economics_sectionA_editorial_v3_20261027'
   AND status='approved' AND academic_review='approved'
   AND language_review='approved' AND source_review='approved'
   AND NOT release_enabled
   AND content_sha256=encode(pg_catalog.sha256(pg_catalog.convert_to(content::text,'UTF8')),'hex')
   AND private.iclub_exam_written_source_locale_valid_v1(content,'en')
   AND private.iclub_exam_written_source_locale_valid_v1(content,'ru')
   AND private.iclub_exam_written_source_locale_valid_v1(content,'uz'))<>2
 THEN RAISE EXCEPTION 'beta_sources_unapproved'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
   WHERE program_key='economics_9708' AND
    task_version='economics_9708_written_editorial_candidate_v3_20261027'
   AND task_key=ANY(v_keys) AND status='approved'
   AND academic_review='approved' AND language_review='approved'
   AND source_review='approved')<>12
 THEN RAISE EXCEPTION 'pilot_tasks_unapproved'; END IF;
END;
$qa$;
UPDATE private.iclub_exam_written_source_cards_v1 SET release_enabled=true
 WHERE program_key='economics_9708' AND source_version='economics_sectionA_editorial_v3_20261027';
UPDATE private.iclub_exam_core_written_tasks_v1 SET release_enabled=true
 WHERE program_key='economics_9708'
   AND task_version='economics_9708_written_editorial_candidate_v3_20261027'
   AND task_key IN ('P2.A.a','P2.A.b','P2.A.c','P2.A.d','P2.A.e','P2.A.f',
      'P2.B1.a','P2.C1.a','P4.A.a','P4.A.c','P4.B1','P4.C1');
-- Beta enrollment remains disabled until the opt-in UI passes isolated QA.
DO $end$
BEGIN
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
 WHERE program_key='economics_9708' AND release_enabled)<>12
 THEN RAISE EXCEPTION 'not_exactly_twelve_releaseable'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_tasks_v1
 WHERE program_key='economics_9708'
 AND task_version<>'economics_9708_written_editorial_candidate_v3_20261027'
 AND release_enabled)<>0 THEN RAISE EXCEPTION 'legacy_release'; END IF;
 IF (SELECT count(*) FROM private.iclub_exam_core_written_access_v1)<>0
 THEN RAISE EXCEPTION 'access_created_during_staging'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_econ_written_beta_control_v1 WHERE enabled)
 THEN RAISE EXCEPTION 'beta_invite_must_start_off'; END IF;
 IF has_function_privilege('anon','public.iclub_econ_written_beta_join_v1(boolean)','EXECUTE')
 OR has_table_privilege('authenticated','private.iclub_econ_written_beta_optins_v1','SELECT')
 THEN RAISE EXCEPTION 'beta_privilege_leak'; END IF;
END;$end$;
COMMIT;
