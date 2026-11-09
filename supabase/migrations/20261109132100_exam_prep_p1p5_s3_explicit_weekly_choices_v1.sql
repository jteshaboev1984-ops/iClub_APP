-- Mathematics P1/P5 S3: three VOLUNTARY, owner-initiated weekly planning choices.
-- Separate immutable decision log; no AI, mentor, grades, work-hour norm or study cap.
-- DRAFT on stacked branch; DO NOT deploy to live before S2 approval and release GO.
BEGIN;
CREATE TABLE private.exam_prep_weekly_choices_s3_v1 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  program_version_id bigint NOT NULL REFERENCES private.exam_prep_program_versions(id),
  week_started_at timestamptz NOT NULL,
  choice_code text NOT NULL CHECK (choice_code IN ('keep','redistribute','change')),
  chosen_math_minutes integer NOT NULL CHECK (chosen_math_minutes BETWEEN 0 AND 10080),
  p1_minutes integer,
  p5_minutes integer,
  study_minutes_per_day integer,
  study_days_per_week integer,
  profile_revision integer NOT NULL,
  schedule_revision integer NOT NULL,
  request_payload jsonb NOT NULL,
  idempotency_key text NOT NULL CHECK(char_length(idempotency_key) BETWEEN 12 AND 150),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id,idempotency_key),
  CHECK ((p1_minutes IS NULL AND p5_minutes IS NULL) OR
         (p1_minutes IS NOT NULL AND p5_minutes IS NOT NULL
          AND p1_minutes>=0 AND p5_minutes>=0
          AND p1_minutes+p5_minutes=chosen_math_minutes))
);
CREATE INDEX exam_prep_weekly_choices_s3_owner_idx ON
 private.exam_prep_weekly_choices_s3_v1(user_id,program_version_id,week_started_at,created_at DESC);
ALTER TABLE private.exam_prep_weekly_choices_s3_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_weekly_choices_s3_v1 FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION public.get_my_exam_prep_weekly_choice_s3_safe_v1()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $s3read$
DECLARE
 v_uid uuid; v_p private.exam_prep_exam_profiles%rowtype; v_begin timestamptz;
 v_choice private.exam_prep_weekly_choices_s3_v1%rowtype; v_minutes int;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 SELECT * INTO v_p FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 IF v_p.user_id IS NULL OR v_p.program_version_id IS NULL THEN
  RAISE EXCEPTION 'exam_prep_profile_required';
 END IF;
 v_begin:=v_p.created_at+make_interval(secs=greatest(0,floor(extract(epoch FROM (now()-v_p.created_at))/604800)::int)*604800);
 SELECT * INTO v_choice FROM private.exam_prep_weekly_choices_s3_v1 c
 WHERE c.user_id=v_uid AND c.program_version_id=v_p.program_version_id
  AND c.week_started_at=v_begin
 ORDER BY c.created_at DESC,c.id DESC LIMIT 1;
 v_minutes:=COALESCE(v_p.study_minutes_per_day*v_p.study_days_per_week,
    round(v_p.mathematics_hours_budget*60)::int);
 RETURN jsonb_build_object(
  'contract_version','voluntary_weekly_choice_s3_v1',
  'active_week_started_at',v_begin,
  'choice_code',v_choice.choice_code,
  'choice_recorded',v_choice.id IS NOT NULL,
  'chosen_math_minutes',v_minutes,
  'p1_minutes',CASE WHEN v_choice.chosen_math_minutes=v_minutes
    THEN v_choice.p1_minutes ELSE NULL END,
  'p5_minutes',CASE WHEN v_choice.chosen_math_minutes=v_minutes
    THEN v_choice.p5_minutes ELSE NULL END,
  'profile_revision',v_p.profile_revision,
  'schedule_revision',v_p.study_schedule_revision,
  'study_minutes_per_day',v_p.study_minutes_per_day,
  'study_days_per_week',v_p.study_days_per_week,
  'total_available_minutes',round(v_p.total_student_hours_available*60)::int,
  'no_study_cap',true,'verified_study_minutes',null,
  'auto_adjusted',false
 );
END;
$s3read$;
REVOKE ALL ON FUNCTION public.get_my_exam_prep_weekly_choice_s3_safe_v1() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_weekly_choice_s3_safe_v1() TO authenticated,service_role;

CREATE OR REPLACE FUNCTION public.save_my_exam_prep_weekly_choice_s3_safe_v1(
 p_choice_code text,
 p_p1_minutes integer,
 p_p5_minutes integer,
 p_minutes_per_day integer,
 p_days_per_week integer,
 p_expected_schedule_revision integer,
 p_idempotency_key text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $s3save$
DECLARE
 v_uid uuid; v_p private.exam_prep_exam_profiles%rowtype; v_after private.exam_prep_exam_profiles%rowtype;
 v_old private.exam_prep_weekly_choices_s3_v1%rowtype;
 v_recent private.exam_prep_weekly_choices_s3_v1%rowtype;
 v_week timestamptz; v_budget integer; v_p1 integer; v_p5 integer;
 v_payload jsonb;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_choice_code NOT IN ('keep','redistribute','change')
  OR p_idempotency_key IS NULL OR length(p_idempotency_key) NOT BETWEEN 12 AND 150
 THEN RAISE EXCEPTION 'exam_prep_s3_invalid_choice_or_key' USING ERRCODE='22023'; END IF;
 v_payload:=jsonb_build_object(
  'choice',p_choice_code,'p1',p_p1_minutes,'p5',p_p5_minutes,
  'per_day',p_minutes_per_day,'days',p_days_per_week,
  'expected_rev',p_expected_schedule_revision
 );
 -- Process ACK-loss retries BEFORE a stale revision check. A reused key with
 -- different payload always fails; it cannot spend study time or mutate a plan.
 SELECT * INTO v_old FROM private.exam_prep_weekly_choices_s3_v1
 WHERE user_id=v_uid AND idempotency_key=p_idempotency_key;
 IF v_old.id IS NOT NULL THEN
  IF v_old.request_payload IS DISTINCT FROM v_payload THEN
   RAISE EXCEPTION 'exam_prep_s3_idempotency_conflict' USING ERRCODE='22023';
  END IF;
  RETURN jsonb_build_object('saved',true,'replayed',true,
    'choice_code',v_old.choice_code,'chosen_math_minutes',v_old.chosen_math_minutes,
    'p1_minutes',v_old.p1_minutes,'p5_minutes',v_old.p5_minutes,
    'profile_revision',v_old.profile_revision,'schedule_revision',v_old.schedule_revision,
    'no_study_cap',true,'academic_marks_changed',false);
 END IF;
 SELECT * INTO v_p FROM private.exam_prep_exam_profiles WHERE user_id=v_uid FOR UPDATE;
 IF v_p.user_id IS NULL OR v_p.program_version_id IS NULL
   OR v_p.total_student_hours_available IS NULL THEN
  RAISE EXCEPTION 'exam_prep_profile_required'; END IF;
 -- A parallel retry may have arrived before the first writer committed.
 -- After locking the owner profile, re-check the key and return its immutable
 -- result instead of raising an unrelated stale-revision error.
 SELECT * INTO v_old FROM private.exam_prep_weekly_choices_s3_v1
  WHERE user_id=v_uid AND idempotency_key=p_idempotency_key;
 IF v_old.id IS NOT NULL THEN
  IF v_old.request_payload IS DISTINCT FROM v_payload THEN
   RAISE EXCEPTION 'exam_prep_s3_idempotency_conflict' USING ERRCODE='22023';
  END IF;
  RETURN jsonb_build_object('saved',true,'replayed',true,
    'choice_code',v_old.choice_code,'chosen_math_minutes',v_old.chosen_math_minutes,
    'p1_minutes',v_old.p1_minutes,'p5_minutes',v_old.p5_minutes,
    'profile_revision',v_old.profile_revision,'schedule_revision',v_old.schedule_revision,
    'no_study_cap',true,'academic_marks_changed',false);
 END IF;
 IF p_expected_schedule_revision IS DISTINCT FROM v_p.study_schedule_revision THEN
  RAISE EXCEPTION 'exam_prep_s3_stale_schedule' USING ERRCODE='PT409'; END IF;
 IF now()<v_p.created_at THEN RAISE EXCEPTION 'exam_prep_s3_invalid_profile_clock'; END IF;
 v_week:=v_p.created_at+make_interval(secs=floor(extract(epoch FROM (now()-v_p.created_at))/604800)::int*604800);
 v_budget:=COALESCE(v_p.study_minutes_per_day*v_p.study_days_per_week,
    round(v_p.mathematics_hours_budget*60)::int);
 IF v_budget IS NULL OR v_budget<0 THEN RAISE EXCEPTION 'exam_prep_s3_missing_time_choice'; END IF;
 IF p_choice_code='keep' THEN
   IF p_p1_minutes IS NOT NULL OR p_p5_minutes IS NOT NULL OR
    p_minutes_per_day IS NOT NULL OR p_days_per_week IS NOT NULL
   THEN RAISE EXCEPTION 'exam_prep_s3_keep_has_unrequested_changes' USING ERRCODE='22023'; END IF;
   SELECT * INTO v_recent FROM private.exam_prep_weekly_choices_s3_v1
    WHERE user_id=v_uid AND program_version_id=v_p.program_version_id
    AND week_started_at=v_week ORDER BY created_at DESC,id DESC LIMIT 1;
   v_p1:=CASE WHEN v_recent.chosen_math_minutes=v_budget THEN v_recent.p1_minutes END;
   v_p5:=CASE WHEN v_recent.chosen_math_minutes=v_budget THEN v_recent.p5_minutes END;
 ELSIF p_choice_code='redistribute' THEN
   IF p_minutes_per_day IS NOT NULL OR p_days_per_week IS NOT NULL THEN
    RAISE EXCEPTION 'exam_prep_s3_redistribute_cannot_change_hours'; END IF;
   v_p1:=p_p1_minutes; v_p5:=p_p5_minutes;
   IF v_p1 IS NULL OR v_p5 IS NULL OR v_p1<0 OR v_p5<0 OR v_p1+v_p5<>v_budget THEN
    RAISE EXCEPTION 'exam_prep_s3_component_sum_mismatch' USING ERRCODE='22023'; END IF;
 ELSE
   IF p_minutes_per_day IS NULL OR p_days_per_week IS NULL
      OR p_minutes_per_day<15 OR p_minutes_per_day>240
      OR mod(p_minutes_per_day,5)<>0 OR p_days_per_week<1 OR p_days_per_week>7
   THEN RAISE EXCEPTION 'exam_prep_s3_schedule_invalid' USING ERRCODE='22023'; END IF;
   v_budget:=p_minutes_per_day*p_days_per_week;
   v_p1:=p_p1_minutes; v_p5:=p_p5_minutes;
   IF v_p1 IS NULL OR v_p5 IS NULL OR v_p1<0 OR v_p5<0 OR v_p1+v_p5<>v_budget THEN
     RAISE EXCEPTION 'exam_prep_s3_component_sum_mismatch' USING ERRCODE='22023'; END IF;
   IF v_budget>round(v_p.total_student_hours_available*60)::int THEN
     RAISE EXCEPTION 'exam_prep_s3_exceeds_user_total_available'; END IF;
   -- Existing S2 revision-governed writer; atomic in same transaction.
   PERFORM public.save_exam_prep_study_schedule_safe_v1(p_minutes_per_day,p_days_per_week);
 END IF;
 SELECT * INTO v_after FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 INSERT INTO private.exam_prep_weekly_choices_s3_v1(
  user_id,program_version_id,week_started_at,choice_code,chosen_math_minutes,
  p1_minutes,p5_minutes,study_minutes_per_day,study_days_per_week,
  profile_revision,schedule_revision,request_payload,idempotency_key)
 VALUES(v_uid,v_after.program_version_id,v_week,p_choice_code,v_budget,
  v_p1,v_p5,v_after.study_minutes_per_day,v_after.study_days_per_week,
  v_after.profile_revision,v_after.study_schedule_revision,v_payload,p_idempotency_key);
 RETURN jsonb_build_object('saved',true,'replayed',false,
   'choice_code',p_choice_code,'chosen_math_minutes',v_budget,
   'p1_minutes',v_p1,'p5_minutes',v_p5,
   'profile_revision',v_after.profile_revision,
   'schedule_revision',v_after.study_schedule_revision,
   'no_study_cap',true,'academic_marks_changed',false,
   'historical_learning_preserved',true);
END;
$s3save$;
REVOKE ALL ON FUNCTION public.save_my_exam_prep_weekly_choice_s3_safe_v1(
 text,integer,integer,integer,integer,integer,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.save_my_exam_prep_weekly_choice_s3_safe_v1(
 text,integer,integer,integer,integer,integer,text) TO authenticated,service_role;
COMMENT ON FUNCTION public.save_my_exam_prep_weekly_choice_s3_safe_v1(
 text,integer,integer,integer,integer,integer,text) IS
'Three explicit user-owned weekly decisions with exact idempotency, P1/P5 time allocation, no auto hours or grade. Not a study cap.';
COMMIT;
