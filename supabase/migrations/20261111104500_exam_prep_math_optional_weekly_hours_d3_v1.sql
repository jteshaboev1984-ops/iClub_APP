-- Issue #450 D3. A learner may enter P1/P5 without supplying weekly hours.
-- The *absence* of a voluntary choice stays NULL (never zero, fabricated hours,
-- a time cap or a mandatory mentor). No updates/deletes to existing student rows.
-- Guard against function source drift; replace existing RPCs without changing
-- their signatures, grants, search_path or authorization.
BEGIN;
DO $d3$
DECLARE v_def text; v_old text; v_new text;
BEGIN
  v_def:=pg_get_functiondef('public.save_exam_prep_exam_profile_v2(text,text,numeric,numeric)'::regprocedure);
  v_old:=$old$if p_total_student_hours_available is null or p_total_student_hours_available<=0 or p_total_student_hours_available>168 then raise exception 'exam_prep_bad_total_hours'; end if;
  if p_mathematics_hours_budget is null or p_mathematics_hours_budget<=0 or p_mathematics_hours_budget>p_total_student_hours_available then raise exception 'exam_prep_bad_math_budget'; end if;$old$;
  v_new:=$new$-- Hours are entirely voluntary; an omitted budget is UNKNOWN, never 0.
  if p_total_student_hours_available is not null and (p_total_student_hours_available<=0 or p_total_student_hours_available>168) then
    raise exception 'exam_prep_bad_total_hours'; end if;
  if p_mathematics_hours_budget is not null and (p_mathematics_hours_budget<=0 or p_mathematics_hours_budget>168 or
    (p_total_student_hours_available is not null and p_mathematics_hours_budget>p_total_student_hours_available)) then
    raise exception 'exam_prep_bad_math_budget'; end if;$new$;
  IF length(v_def)-length(replace(v_def,v_old,''))<>length(v_old) THEN
    RAISE EXCEPTION 'd3_save_profile_v2_source_guard_mismatch'; END IF;
  EXECUTE replace(v_def,v_old,v_new);

  v_def:=pg_get_functiondef('private.rebuild_exam_prep_placement_v1(uuid,text)'::regprocedure);
  v_old:=$old$        and p.mathematics_hours_budget is not null and p.mathematics_hours_budget>0
        and p.total_student_hours_available is not null and p.total_student_hours_available>0
        and p.mathematics_hours_budget<=p.total_student_hours_available
        and p.active_week_no>=1$old$;
  v_new:=$new$        -- Profile and screening determine Core access; voluntary hours do not.
        and p.active_week_no>=1$new$;
  IF length(v_def)-length(replace(v_def,v_old,''))<>length(v_old) THEN
    RAISE EXCEPTION 'd3_placement_source_guard_mismatch'; END IF;
  v_def:=replace(v_def,v_old,v_new);
  v_old:=$old$exam_profile_or_realistic_mathematics_budget_required$old$;
  IF length(v_def)-length(replace(v_def,v_old,''))<>length(v_old) THEN
    RAISE EXCEPTION 'd3_placement_reason_guard_mismatch'; END IF;
  EXECUTE replace(v_def,v_old,'exam_profile_required');

  v_def:=pg_get_functiondef('public.save_exam_prep_study_schedule_safe_v1(integer,integer)'::regprocedure);
  v_old:=$old$  if v_old.user_id is null or v_old.program_version_id is null or
     v_old.total_student_hours_available is null or
     v_old.total_student_hours_available<=0 then
    raise exception 'exam_prep_profile_required';
  end if;
  if v_budget>v_old.total_student_hours_available then
    raise exception 'exam_prep_study_exceeds_total_weekly_budget';
  end if;$old$;
  v_new:=$new$  if v_old.user_id is null or v_old.program_version_id is null then
    raise exception 'exam_prep_profile_required';
  end if;
  -- If a learner did choose a total, keep its coherence constraint.
  -- An unknown total is not a numeric limit on choosing a Math schedule.
  if v_old.total_student_hours_available is not null and
     v_budget>v_old.total_student_hours_available then
    raise exception 'exam_prep_study_exceeds_total_weekly_budget';
  end if;$new$;
  IF length(v_def)-length(replace(v_def,v_old,''))<>length(v_old) THEN
    RAISE EXCEPTION 'd3_schedule_source_guard_mismatch'; END IF;
  EXECUTE replace(v_def,v_old,v_new);

  v_def:=pg_get_functiondef('public.get_exam_prep_shared_study_capacity_safe_v1()'::regprocedure);
  v_old:=$old$  if v_profile.user_id is null or v_profile.program_version_id is null
     or v_profile.mathematics_hours_budget is null then
    raise exception 'exam_prep_profile_required';
  end if;$old$;
  v_new:=$new$  if v_profile.user_id is null or v_profile.program_version_id is null then
    raise exception 'exam_prep_profile_required';
  end if;$new$;
  IF length(v_def)-length(replace(v_def,v_old,''))<>length(v_old) THEN
    RAISE EXCEPTION 'd3_capacity_source_guard_mismatch'; END IF;
  v_def:=replace(v_def,v_old,v_new);
  v_old:=$old$  if v_earliest is not null then
    v_first_hours:=round(v_budget *$old$;
  v_new:=$new$  if v_earliest is not null and v_budget is not null then
    v_first_hours:=round(v_budget *$new$;
  IF length(v_def)-length(replace(v_def,v_old,''))<>length(v_old) THEN
    RAISE EXCEPTION 'd3_capacity_rounding_guard_mismatch'; END IF;
  EXECUTE replace(v_def,v_old,v_new);
END $d3$;
COMMIT;
