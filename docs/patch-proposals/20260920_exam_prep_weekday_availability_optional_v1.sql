-- REVIEW-ONLY SQL proposal. NOT a migration. No production execution approved.
-- Depends on the reviewed atomic legacy dispatcher / private server enrollment.
-- Optional hours describe a TYPICAL Monday-Sunday week. P1+P5 SHARE ONE Math budget.
-- These fields are not remaining hours, official exam deadlines or a risk prediction.
BEGIN;
CREATE TABLE private.exam_prep_weekday_availability_v1 (
  user_id uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  weekday_hours jsonb,
  confirmed boolean NOT NULL DEFAULT false,
  profile_revision integer NOT NULL CHECK(profile_revision>=1),
  availability_revision integer NOT NULL DEFAULT 1 CHECK(availability_revision>=1),
  mathematics_budget_snapshot numeric NOT NULL CHECK(mathematics_budget_snapshot>0 AND mathematics_budget_snapshot<=168),
  updated_by uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT weekday_availability_confirmation_check CHECK(confirmed=(weekday_hours IS NOT NULL))
);
ALTER TABLE private.exam_prep_weekday_availability_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_weekday_availability_v1 FROM PUBLIC,anon,authenticated,service_role;
CREATE TRIGGER exam_prep_weekday_availability_audit_v1
AFTER INSERT OR UPDATE OR DELETE ON private.exam_prep_weekday_availability_v1
FOR EACH ROW EXECUTE FUNCTION private.exam_prep_audit_row_change_v1();

-- Separate new read RPC; older profile read signatures remain byte-identical.
CREATE FUNCTION public.get_my_exam_prep_weekday_availability_safe_v1()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $body$
DECLARE v_uid uuid; v_profile private.exam_prep_exam_profiles%rowtype;
        v_day private.exam_prep_weekday_availability_v1%rowtype; v_fresh boolean;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
    RAISE EXCEPTION 'exam_prep_weekly_flow_not_enabled' USING errcode='42501';
  END IF;
  SELECT * INTO v_profile FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  IF v_profile.user_id IS NULL THEN RAISE EXCEPTION 'exam_prep_profile_required'; END IF;
  SELECT * INTO v_day FROM private.exam_prep_weekday_availability_v1 WHERE user_id=v_uid;
  v_fresh:=v_day.user_id IS NOT NULL AND v_day.confirmed IS TRUE
    AND v_day.profile_revision=v_profile.profile_revision
    AND v_day.mathematics_budget_snapshot=v_profile.mathematics_hours_budget;
  RETURN jsonb_build_object('contract_version','weekly_day_availability_v1',
    'enabled',true,'scope','shared_mathematics_week','weekday_hours',v_day.weekday_hours,
    'confirmed',coalesce(v_fresh,false),
    'needs_reconfirmation',v_day.confirmed IS TRUE AND NOT v_fresh,
    'profile_revision',v_profile.profile_revision,
    'availability_revision',coalesce(v_day.availability_revision,0),
    'exam_series',v_profile.exam_series,'target_grade',v_profile.target_grade,
    'total_student_hours_available',v_profile.total_student_hours_available,
    'mathematics_hours_budget',v_profile.mathematics_hours_budget,
    'planning_only',true,'does_not_change_current_plan',true);
END;
$body$;
REVOKE ALL ON FUNCTION public.get_my_exam_prep_weekday_availability_safe_v1() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_weekday_availability_safe_v1() TO authenticated,service_role;

-- Both the profile and independent weekday revision are compare-and-swap values.
-- Parent profile FOR UPDATE serializes two concurrent devices including an absent
-- optional row. A rejected edit rolls back ALL changes; the learner must refresh.
CREATE FUNCTION public.save_my_exam_prep_profile_with_weekday_availability_safe_v1(
  p_exam_series text,p_target_grade text,
  p_total_student_hours_available numeric,p_mathematics_hours_budget numeric,
  p_weekday_hours jsonb,p_expected_profile_revision integer,
  p_expected_availability_revision integer
)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $body$
DECLARE v_uid uuid; v_key text; v_hours numeric; v_sum numeric:=0;
        v_count integer; v_revision integer; v_day_revision integer;
        v_saved jsonb;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  IF NOT private.exam_prep_weekly_flow_enrolled_v1(v_uid) THEN
    RAISE EXCEPTION 'exam_prep_weekly_flow_not_enabled' USING errcode='42501';
  END IF;
  IF p_weekday_hours IS NOT NULL THEN
    IF jsonb_typeof(p_weekday_hours)<>'object' THEN
      RAISE EXCEPTION 'exam_prep_weekday_hours_must_be_object'; END IF;
    SELECT count(*) INTO v_count FROM jsonb_object_keys(p_weekday_hours);
    IF v_count<>7 THEN RAISE EXCEPTION 'exam_prep_weekday_hours_require_seven_days'; END IF;
    FOREACH v_key IN ARRAY ARRAY['mon','tue','wed','thu','fri','sat','sun'] LOOP
      IF NOT p_weekday_hours ? v_key OR jsonb_typeof(p_weekday_hours->v_key)<>'number' THEN
        RAISE EXCEPTION 'exam_prep_weekday_hours_invalid_key_or_type'; END IF;
      v_hours:=(p_weekday_hours->>v_key)::numeric;
      IF v_hours<0 OR v_hours>24 OR v_hours*2<>trunc(v_hours*2) THEN
        RAISE EXCEPTION 'exam_prep_weekday_hours_out_of_range'; END IF;
      v_sum:=v_sum+v_hours;
    END LOOP;
    IF p_mathematics_hours_budget IS NULL OR v_sum>p_mathematics_hours_budget THEN
      RAISE EXCEPTION 'exam_prep_weekday_hours_exceed_shared_mathematics_budget'; END IF;
  END IF;
  SELECT profile_revision INTO v_revision FROM private.exam_prep_exam_profiles
    WHERE user_id=v_uid FOR UPDATE;
  IF v_revision IS NULL OR p_expected_profile_revision IS NULL OR
     v_revision<>p_expected_profile_revision THEN
    RAISE EXCEPTION 'exam_prep_profile_changed_refresh_required' USING errcode='40001';
  END IF;
  SELECT availability_revision INTO v_day_revision
  FROM private.exam_prep_weekday_availability_v1 WHERE user_id=v_uid FOR UPDATE;
  v_day_revision:=coalesce(v_day_revision,0);
  IF p_expected_availability_revision IS NULL OR p_expected_availability_revision<>v_day_revision THEN
    RAISE EXCEPTION 'exam_prep_weekday_hours_changed_refresh_required' USING errcode='40001';
  END IF;
  v_saved:=public.save_exam_prep_exam_profile_v2(
    p_exam_series,p_target_grade,p_total_student_hours_available,p_mathematics_hours_budget);
  SELECT profile_revision INTO v_revision FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  IF v_revision IS NULL THEN RAISE EXCEPTION 'exam_prep_profile_required'; END IF;
  -- One row per user; day-only edits advance a separate revision even if the
  -- exam profile's revision is unchanged. NULL clears but never deletes history.
  INSERT INTO private.exam_prep_weekday_availability_v1(
    user_id,weekday_hours,confirmed,profile_revision,availability_revision,
    mathematics_budget_snapshot,updated_by)
  VALUES(v_uid,p_weekday_hours,p_weekday_hours IS NOT NULL,v_revision,
    v_day_revision+1,p_mathematics_hours_budget,v_uid)
  ON CONFLICT(user_id) DO UPDATE SET
    weekday_hours=excluded.weekday_hours,confirmed=excluded.confirmed,
    profile_revision=excluded.profile_revision,
    availability_revision=excluded.availability_revision,
    mathematics_budget_snapshot=excluded.mathematics_budget_snapshot,
    updated_by=excluded.updated_by,updated_at=now();
  RETURN v_saved||jsonb_build_object('day_availability_saved',true,
    'day_availability_confirmed',p_weekday_hours IS NOT NULL,
    'availability_revision',v_day_revision+1,'does_not_replace_current_week',true);
END;
$body$;
REVOKE ALL ON FUNCTION public.save_my_exam_prep_profile_with_weekday_availability_safe_v1(
  text,text,numeric,numeric,jsonb,integer,integer) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.save_my_exam_prep_profile_with_weekday_availability_safe_v1(
  text,text,numeric,numeric,jsonb,integer,integer) TO authenticated,service_role;
COMMIT;
