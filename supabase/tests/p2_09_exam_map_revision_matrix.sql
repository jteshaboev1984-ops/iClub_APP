-- P2-09 exam-map revision matrix.
-- Synthetic learner only; all changes are rolled back and must leave zero residue.
\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE p209_user(user_id uuid primary key) ON COMMIT DROP;
INSERT INTO p209_user VALUES(gen_random_uuid());
GRANT SELECT ON p209_user TO authenticated,service_role;

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at,is_sso_user,is_anonymous)
SELECT user_id,'authenticated','authenticated','p209-'||replace(user_id::text,'-','')||'@invalid.example',now(),now(),false,false
FROM p209_user;

INSERT INTO public.users(id,first_name,last_name,language_code,created_at,must_change_password)
SELECT user_id,'P209','Exam Map Revision','en',now(),false FROM p209_user;

UPDATE private.exam_prep_feature_config
SET rollout_state='controlled_beta',core_enabled=true,ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
WHERE id=1;

INSERT INTO private.exam_prep_feature_entitlements(
  user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,valid_from
)
SELECT user_id,'active',true,false,false,now() FROM p209_user;

CREATE TEMP TABLE p209_before AS
SELECT
  (SELECT count(*) FROM private.exam_prep_evidence_events WHERE user_id=(SELECT user_id FROM p209_user)) evidence_events,
  (SELECT count(*) FROM private.exam_prep_skill_states WHERE user_id=(SELECT user_id FROM p209_user)) skill_states,
  (SELECT count(*) FROM private.exam_prep_stage_states WHERE user_id=(SELECT user_id FROM p209_user)) stage_states,
  (SELECT count(*) FROM private.exam_prep_correction_cases WHERE user_id=(SELECT user_id FROM p209_user)) correction_cases,
  (SELECT count(*) FROM public.practice_attempts WHERE user_id=(SELECT user_id FROM p209_user)) practice_attempts,
  (SELECT count(*) FROM public.tour_attempts WHERE user_id=(SELECT user_id FROM p209_user)) tour_attempts,
  (SELECT count(*) FROM public.certificates) certificates;

SELECT set_config('request.jwt.claim.sub',(SELECT user_id::text FROM p209_user),true);
SET LOCAL ROLE authenticated;

CREATE TEMP TABLE p209_results(
  step_no int primary key,
  payload jsonb not null
) ON COMMIT DROP;
GRANT SELECT,INSERT ON p209_results TO authenticated,service_role;

INSERT INTO p209_results VALUES
(1,public.save_exam_prep_exam_profile_v2('May/June 2027','A',12,6));
INSERT INTO p209_results VALUES
(2,public.save_exam_prep_exam_profile_v2('May/June 2027','A',12,6));
INSERT INTO p209_results VALUES
(3,public.save_exam_prep_exam_profile_v2('May/June 2027','A',10,5));
INSERT INTO p209_results VALUES
(4,public.save_exam_prep_exam_profile_v2('May/June 2027','A*',10,5));
INSERT INTO p209_results VALUES
(5,public.save_exam_prep_exam_profile_v2('Oct/Nov 2027','A*',10,5));

DO $$
DECLARE
  r1 jsonb; r2 jsonb; r3 jsonb; r4 jsonb; r5 jsonb;
  v_status jsonb;
BEGIN
  SELECT payload INTO r1 FROM p209_results WHERE step_no=1;
  SELECT payload INTO r2 FROM p209_results WHERE step_no=2;
  SELECT payload INTO r3 FROM p209_results WHERE step_no=3;
  SELECT payload INTO r4 FROM p209_results WHERE step_no=4;
  SELECT payload INTO r5 FROM p209_results WHERE step_no=5;

  IF (r1->>'profile_revision')::int<>1 OR (r1->>'paper_comparability_epoch')::int<>1
     OR (r1->>'progress_retained')::boolean IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'P2-09 initial profile contract failed: %',r1;
  END IF;

  IF (r2->>'profile_revision')::int<>1 OR (r2->>'paper_comparability_epoch')::int<>1
     OR (r2->>'plan_rebuild_required')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-09 idempotent save changed revision/epoch: %',r2;
  END IF;

  IF (r3->>'profile_revision')::int<>2 OR (r3->>'paper_comparability_epoch')::int<>1
     OR (r3->>'hours_changed')::boolean IS DISTINCT FROM true
     OR (r3->>'series_changed')::boolean IS DISTINCT FROM false
     OR (r3->>'plan_rebuild_required')::boolean IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'P2-09 hours change contract failed: %',r3;
  END IF;

  IF (r4->>'profile_revision')::int<>3 OR (r4->>'paper_comparability_epoch')::int<>1
     OR (r4->>'target_changed')::boolean IS DISTINCT FROM true
     OR (r4->>'series_changed')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-09 target change contract failed: %',r4;
  END IF;

  IF (r5->>'profile_revision')::int<>4 OR (r5->>'paper_comparability_epoch')::int<>2
     OR (r5->>'series_changed')::boolean IS DISTINCT FROM true
     OR (r5->>'timetable_reconfirmation_required')::boolean IS DISTINCT FROM true
     OR (r5->>'prior_papers_count_toward_current_trend')::boolean IS DISTINCT FROM false
     OR (r5->>'progress_retained')::boolean IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'P2-09 series change contract failed: %',r5;
  END IF;

  v_status:=public.get_exam_prep_exam_map_status_safe_v1();
  IF (v_status->>'profile_revision')::int<>4
     OR (v_status->>'paper_comparability_epoch')::int<>2
     OR v_status->>'exam_series'<>'Oct/Nov 2027'
     OR v_status->>'target_grade'<>'A*'
     OR (v_status->>'progress_retained')::boolean IS DISTINCT FROM true
     OR (v_status->>'calendar_can_reduce_progress')::boolean IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'P2-09 safe status contract failed: %',v_status;
  END IF;
END
$$;

RESET ROLE;

DO $$
DECLARE
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_count int;
  b record;
  a record;
BEGIN
  SELECT user_id INTO v_uid FROM p209_user;
  SELECT * INTO v_profile FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  IF v_profile.profile_revision<>4 OR v_profile.paper_comparability_epoch<>2
     OR v_profile.exam_series<>'Oct/Nov 2027' OR v_profile.target_grade<>'A*' THEN
    RAISE EXCEPTION 'P2-09 stored current profile mismatch';
  END IF;

  SELECT count(*) INTO v_count FROM private.exam_prep_exam_map_revisions WHERE user_id=v_uid;
  IF v_count<>4 THEN RAISE EXCEPTION 'P2-09 expected 4 revision rows, got %',v_count; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_exam_map_revisions
    WHERE user_id=v_uid AND profile_revision=2 AND change_kind='hours_change'
      AND paper_comparability_epoch=1 AND hours_changed AND NOT series_changed
  ) THEN RAISE EXCEPTION 'P2-09 hours revision audit row missing'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_exam_map_revisions
    WHERE user_id=v_uid AND profile_revision=3 AND change_kind='target_change'
      AND paper_comparability_epoch=1 AND target_changed AND NOT series_changed
  ) THEN RAISE EXCEPTION 'P2-09 target revision audit row missing'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM private.exam_prep_exam_map_revisions
    WHERE user_id=v_uid AND profile_revision=4 AND change_kind='series_change'
      AND paper_comparability_epoch=2 AND series_changed AND progress_retained AND prior_papers_remain_history
  ) THEN RAISE EXCEPTION 'P2-09 series revision audit row missing'; END IF;

  SELECT * INTO b FROM p209_before;
  SELECT
    (SELECT count(*) FROM private.exam_prep_evidence_events WHERE user_id=v_uid) evidence_events,
    (SELECT count(*) FROM private.exam_prep_skill_states WHERE user_id=v_uid) skill_states,
    (SELECT count(*) FROM private.exam_prep_stage_states WHERE user_id=v_uid) stage_states,
    (SELECT count(*) FROM private.exam_prep_correction_cases WHERE user_id=v_uid) correction_cases,
    (SELECT count(*) FROM public.practice_attempts WHERE user_id=v_uid) practice_attempts,
    (SELECT count(*) FROM public.tour_attempts WHERE user_id=v_uid) tour_attempts,
    (SELECT count(*) FROM public.certificates) certificates
  INTO a;

  IF row_to_json(a)::text<>row_to_json(b)::text THEN
    RAISE EXCEPTION 'P2-09 profile changes mutated academic/legacy history before=% after=%',row_to_json(b),row_to_json(a);
  END IF;

  IF has_table_privilege('authenticated','private.exam_prep_exam_map_revisions','SELECT') THEN
    RAISE EXCEPTION 'P2-09 authenticated can read private revision history directly';
  END IF;
  IF has_function_privilege('anon','public.save_exam_prep_exam_profile_v2(text,text,numeric,numeric)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-09 anon can save exam profile';
  END IF;
  IF NOT has_function_privilege('authenticated','public.save_exam_prep_exam_profile_v2(text,text,numeric,numeric)','EXECUTE') THEN
    RAISE EXCEPTION 'P2-09 authenticated cannot save exam profile v2';
  END IF;
END
$$;

ROLLBACK;

DO $$
BEGIN
  IF EXISTS(select 1 from auth.users where email like 'p209-%@invalid.example') THEN
    RAISE EXCEPTION 'P2-09 synthetic auth residue found';
  END IF;
  IF EXISTS(select 1 from public.users where first_name='P209' and last_name='Exam Map Revision') THEN
    RAISE EXCEPTION 'P2-09 synthetic public user residue found';
  END IF;
END
$$;

\echo 'P2-09 exam map revision matrix: GREEN'
