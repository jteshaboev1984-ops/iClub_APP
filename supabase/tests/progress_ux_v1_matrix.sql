-- Exam Prep Progress UX runtime matrix: disposable PostgreSQL only, full rollback.
\set ON_ERROR_STOP on
DO $$ BEGIN
 IF current_setting('progress_ux.isolated_db',true) IS DISTINCT FROM 'true' THEN
  RAISE EXCEPTION 'PROGRESS UX REFUSED: isolated database setting required';
 END IF;
END $$;
BEGIN;

CREATE TEMP TABLE px_people(ord int PRIMARY KEY,user_id uuid NOT NULL UNIQUE) ON COMMIT DROP;
INSERT INTO px_people VALUES (1,gen_random_uuid()),(2,gen_random_uuid());
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated',format('px-%s@invalid.example',ord),now(),now(),false,false FROM px_people;
INSERT INTO public.users(id,first_name,created_at,must_change_password)
SELECT user_id,'ProgressUXSynthetic',now(),false FROM px_people;
INSERT INTO private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access)
SELECT user_id,'active',true FROM px_people;
UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,kill_switch=false
WHERE program_key='math_as_p1_p5';
DO $$ DECLARE v_program bigint; BEGIN
 SELECT id INTO v_program FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND status='active' ORDER BY id DESC LIMIT 1;
 IF v_program IS NULL THEN RAISE EXCEPTION 'No active canonical program in isolated schema'; END IF;
 INSERT INTO private.exam_prep_exam_profiles(user_id,program_version_id,exam_series,target_grade,
  total_student_hours_available,mathematics_hours_budget,active_week_no)
 SELECT user_id,v_program,'May/June 2027','A',12,6,1 FROM px_people;
END $$;

CREATE TEMP TABLE px_cases(ord int PRIMARY KEY,case_id uuid) ON COMMIT DROP;
INSERT INTO private.exam_prep_correction_cases(user_id,component_code,skill_code,status)
SELECT user_id,'P1','P1-CIR-01','remediating' FROM px_people WHERE ord=1;
INSERT INTO px_cases
SELECT 1,id FROM private.exam_prep_correction_cases
WHERE user_id=(SELECT user_id FROM px_people WHERE ord=1) AND skill_code='P1-CIR-01';
CREATE TEMP TABLE px_plans(component_code text,version_no int,plan_id uuid,PRIMARY KEY(component_code,version_no)) ON COMMIT DROP;
WITH created AS (
 INSERT INTO private.exam_prep_weekly_plans(user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 SELECT p.user_id,e.program_version_id,'P1',1,1,'superseded','isolated first plan'
 FROM px_people p JOIN private.exam_prep_exam_profiles e ON e.user_id=p.user_id WHERE p.ord=1
 RETURNING id
) INSERT INTO px_plans SELECT 'P1',1,id FROM created;
-- Only release-approved week-one learning skills may be used: QUA-01, QUA-02, DAT-01.
INSERT INTO private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
VALUES
((SELECT plan_id FROM px_plans WHERE component_code='P1' AND version_no=1),1,'correction','P1-CIR-01',(SELECT case_id FROM px_cases WHERE ord=1),'COMPLETE_CORRECTION_ANALOGUES'),
((SELECT plan_id FROM px_plans WHERE component_code='P1' AND version_no=1),2,'learning','P1-QUA-01',null,'BUILD_FIRST_COVERAGE'),
((SELECT plan_id FROM px_plans WHERE component_code='P1' AND version_no=1),3,'learning','P1-QUA-02',null,'BUILD_FIRST_COVERAGE');
WITH created AS (
 INSERT INTO private.exam_prep_weekly_plans(user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 SELECT p.user_id,e.program_version_id,'P1',1,2,'active','isolated regenerated plan'
 FROM px_people p JOIN private.exam_prep_exam_profiles e ON e.user_id=p.user_id WHERE p.ord=1
 RETURNING id
) INSERT INTO px_plans SELECT 'P1',2,id FROM created;
INSERT INTO private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,correction_case_id,action_code)
VALUES
((SELECT plan_id FROM px_plans WHERE component_code='P1' AND version_no=2),1,'correction','P1-CIR-01',(SELECT case_id FROM px_cases WHERE ord=1),'COMPLETE_CORRECTION_ANALOGUES'),
((SELECT plan_id FROM px_plans WHERE component_code='P1' AND version_no=2),2,'mixed_transfer',null,null,'COMPLETE_MIXED_TRANSFER');
WITH created AS (
 INSERT INTO private.exam_prep_weekly_plans(user_id,program_version_id,component_code,active_week_no,plan_version,status,policy_note)
 SELECT p.user_id,e.program_version_id,'P5',1,1,'active','isolated P5 plan'
 FROM px_people p JOIN private.exam_prep_exam_profiles e ON e.user_id=p.user_id WHERE p.ord=1
 RETURNING id
) INSERT INTO px_plans SELECT 'P5',1,id FROM created;
INSERT INTO private.exam_prep_weekly_plan_items(plan_id,priority_order,item_type,skill_code,action_code)
VALUES ((SELECT plan_id FROM px_plans WHERE component_code='P5' AND version_no=1),1,'learning','P5-DAT-01','BUILD_FIRST_COVERAGE');

DO $$ DECLARE v_one uuid;v_two uuid;v_result jsonb;v_before jsonb;v_after jsonb;v_ids text[]; BEGIN
 SELECT user_id INTO v_one FROM px_people WHERE ord=1;
 SELECT user_id INTO v_two FROM px_people WHERE ord=2;
 PERFORM set_config('request.jwt.claim.sub',v_one::text,true);
 PERFORM set_config('request.jwt.claim.role','authenticated',true);
 v_before:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF v_before->>'plan_available'<>'false' OR jsonb_array_length(v_before->'goals')<>0 THEN
  RAISE EXCEPTION 'No snapshot must not fabricate 0/3';END IF;
 v_result:=public.ensure_exam_prep_weekly_goals_safe_v1('P1');
 IF (v_result->>'created')::int<>3 THEN RAISE EXCEPTION 'Expected three original goals: %',v_result;END IF;
 v_after:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF v_after->>'component_code'<>'P1' OR (v_after->>'completed_goals')::int<>0 OR jsonb_array_length(v_after->'goals')<>3 THEN
  RAISE EXCEPTION 'P1 projection incorrect: %',v_after;END IF;
 IF v_after->'goals'->0->>'action_priority_order'<>'1' OR
    (v_after->'goals'->2->>'action_priority_order') IS NOT NULL THEN
  RAISE EXCEPTION 'Current action/replan binding incorrect: %',v_after->'goals';END IF;
 SELECT array_agg(x->>'goal_id' ORDER BY (x->>'priority_order')::int) INTO v_ids FROM jsonb_array_elements(v_after->'goals') x;
 v_result:=public.ensure_exam_prep_weekly_goals_safe_v1('P1');
 IF (v_result->>'created')::int<>0 THEN RAISE EXCEPTION 'Duplicate snapshots';END IF;
 v_after:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF v_ids IS DISTINCT FROM (SELECT array_agg(x->>'goal_id' ORDER BY (x->>'priority_order')::int)
   FROM jsonb_array_elements(v_after->'goals') x) THEN RAISE EXCEPTION 'IDs moved';END IF;
 v_result:=public.ensure_exam_prep_weekly_goals_safe_v1('P5');
 IF (v_result->>'created')::int<>1 THEN RAISE EXCEPTION 'P5 first plan missing';END IF;
 v_result:=public.get_exam_prep_weekly_progress_safe_v1('P5');
 IF jsonb_array_length(v_result->'goals')<>1 OR v_result->'goals'->0->>'component_code'<>'P5' THEN
  RAISE EXCEPTION 'P5 component isolation failed: %',v_result;END IF;
 PERFORM set_config('request.jwt.claim.sub',v_two::text,true);
 v_result:=public.get_exam_prep_weekly_progress_safe_v1('P1');
 IF v_result->>'plan_available'<>'false' OR jsonb_array_length(v_result->'goals')<>0 OR
  (v_result->>'finalized_study_sessions')::int<>0 THEN RAISE EXCEPTION 'Cross-user leak: %',v_result;END IF;
 v_result:=public.ensure_exam_prep_weekly_goals_safe_v1('P1');
 IF v_result->>'plan_available'<>'false' THEN RAISE EXCEPTION 'Cross-user snapshot leak';END IF;
 PERFORM set_config('request.jwt.claim.sub','',true);
 BEGIN
  PERFORM public.get_exam_prep_weekly_progress_safe_v1('P1');
  RAISE EXCEPTION 'Unauthenticated read succeeded';
 EXCEPTION WHEN sqlstate '28000' THEN NULL;END;
 RAISE NOTICE 'Progress UX runtime PASS: idempotent frozen plans, truthful zero, current binding, P1/P5 and cross-user isolation';
END $$;
ROLLBACK;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.users WHERE first_name='ProgressUXSynthetic') THEN RAISE EXCEPTION 'Synthetic user residue';END IF;
 RAISE NOTICE 'Progress UX rollback PASS';
END $$;
