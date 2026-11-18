-- D3-HOURS #450: DORMANT CANDIDATE; test ONLY in disposable PostgreSQL 17.
-- Never apply to live Supabase/main without a separate owner-approved release.
-- No student/profile/history/attempt DML; no academic time recommendations.
-- Do not replay installed S2/S3/S4/subject-guard migrations.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='30s';
DO $guard$
BEGIN
  IF to_regprocedure('public.save_exam_prep_exam_profile_v2(text,text,numeric,numeric)') IS NULL OR
     md5(pg_get_functiondef(to_regprocedure('public.save_exam_prep_exam_profile_v2(text,text,numeric,numeric)')))<>'54756ea0729fc7e4d036c9b756ba7d7c' THEN
    RAISE EXCEPTION 'd3_hours_function_source_drift_save_exam_prep_exam_profile_v2';
  END IF;
  -- Placement is checked structurally and patched in-place below.
  IF to_regprocedure('public.save_exam_prep_study_schedule_safe_v1(integer,integer)') IS NULL OR
     md5(pg_get_functiondef(to_regprocedure('public.save_exam_prep_study_schedule_safe_v1(integer,integer)')))<>'4fc23917d72a32751977081efd390233' THEN
    RAISE EXCEPTION 'd3_hours_function_source_drift_save_exam_prep_study_schedule_safe_v1';
  END IF;
  IF to_regprocedure('public.get_exam_prep_shared_study_capacity_safe_v1()') IS NULL OR
     md5(pg_get_functiondef(to_regprocedure('public.get_exam_prep_shared_study_capacity_safe_v1()')))<>'697783cda59ff0109e9c1242313942a6' THEN
    RAISE EXCEPTION 'd3_hours_function_source_drift_get_exam_prep_shared_study_capacity_safe_v1';
  END IF;
  IF to_regprocedure('public.save_my_exam_prep_weekly_choice_s3_safe_v1(text,integer,integer,integer,integer,integer,text)') IS NULL OR
     md5(pg_get_functiondef(to_regprocedure('public.save_my_exam_prep_weekly_choice_s3_safe_v1(text,integer,integer,integer,integer,integer,text)')))<>'879d1062e303650bf90d28997c50b00d' THEN
    RAISE EXCEPTION 'd3_hours_function_source_drift_save_my_exam_prep_weekly_choice_s3_safe_v1';
  END IF;
END $guard$;
-- The profile table already permits NULL. Only the immutable revision ledger
-- had historical NOT NULL constraints and needs additive relaxation.
ALTER TABLE private.exam_prep_exam_map_revisions
  ALTER COLUMN total_student_hours_available DROP NOT NULL,
  ALTER COLUMN mathematics_hours_budget DROP NOT NULL;

-- Preserve existing signature, owner, SECURITY DEFINER, search_path and EXECUTE grants: save_exam_prep_exam_profile_v2.
CREATE OR REPLACE FUNCTION public.save_exam_prep_exam_profile_v2(p_exam_series text, p_target_grade text, p_total_student_hours_available numeric, p_mathematics_hours_budget numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid;
  v_program bigint;
  v_old private.exam_prep_exam_profiles%rowtype;
  v_total_hours numeric;
  v_math_hours numeric;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_series text:=nullif(trim(p_exam_series),'');
  v_target text:=nullif(upper(trim(p_target_grade)),'');
  v_changed boolean:=false;
  v_series_changed boolean:=false;
  v_target_changed boolean:=false;
  v_hours_changed boolean:=false;
  v_revision int:=1;
  v_epoch int:=1;
  v_kind text:='initial';
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_exam_series is not null and char_length(trim(p_exam_series))>80 then raise exception 'exam_prep_bad_exam_series'; end if;
  if p_target_grade is not null and char_length(trim(p_target_grade))>40 then raise exception 'exam_prep_bad_target_grade'; end if;
  -- D3: null means no time preference, not zero hours of study.
  -- Read and preserve existing voluntary budgets before validating changes.

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'exam_prep_profile_program_missing'; end if;

  select * into v_old from private.exam_prep_exam_profiles where user_id=v_uid for update;
  -- An omitted time field never erases an existing learner's saved choices.
  v_total_hours:=coalesce(p_total_student_hours_available,v_old.total_student_hours_available);
  v_math_hours:=coalesce(p_mathematics_hours_budget,v_old.mathematics_hours_budget);
  if v_total_hours is not null and (v_total_hours<=0 or v_total_hours>168) then
    raise exception 'exam_prep_bad_total_hours'; end if;
  if v_math_hours is not null and (v_math_hours<=0 or v_math_hours>168 or
     (v_total_hours is not null and v_math_hours>v_total_hours)) then
    raise exception 'exam_prep_bad_math_budget'; end if;

  if v_old.user_id is null then
    insert into private.exam_prep_exam_profiles(
      user_id,program_version_id,exam_series,target_grade,total_student_hours_available,mathematics_hours_budget,
      active_week_no,profile_revision,paper_comparability_epoch,created_by,updated_by
    ) values(
      v_uid,v_program,v_series,v_target,v_total_hours,v_math_hours,
      1,1,1,v_uid,v_uid
    ) returning * into v_profile;

    insert into private.exam_prep_exam_map_revisions(
      user_id,program_version_id,profile_revision,paper_comparability_epoch,exam_series,target_grade,
      total_student_hours_available,mathematics_hours_budget,change_kind,series_changed,target_changed,hours_changed
    ) values(
      v_uid,v_program,1,1,v_series,v_target,v_total_hours,v_math_hours,
      'initial',false,false,false
    );
  else
    v_series_changed:=nullif(trim(v_old.exam_series),'') is not null
      and lower(trim(v_old.exam_series)) is distinct from lower(coalesce(v_series,''));
    v_target_changed:=upper(coalesce(trim(v_old.target_grade),'')) is distinct from upper(coalesce(v_target,''));
    v_hours_changed:=v_old.total_student_hours_available is distinct from v_total_hours
      or v_old.mathematics_hours_budget is distinct from v_math_hours;
    v_changed:=lower(coalesce(trim(v_old.exam_series),'')) is distinct from lower(coalesce(v_series,''))
      or v_target_changed or v_hours_changed;

    v_revision:=v_old.profile_revision + case when v_changed then 1 else 0 end;
    v_epoch:=v_old.paper_comparability_epoch + case when v_series_changed then 1 else 0 end;
    v_kind:=case
      when v_series_changed and (v_target_changed or v_hours_changed) then 'combined_change'
      when v_series_changed then 'series_change'
      when v_target_changed and v_hours_changed then 'combined_change'
      when v_target_changed then 'target_change'
      when v_hours_changed then 'hours_change'
      else 'initial'
    end;

    update private.exam_prep_exam_profiles
    set program_version_id=v_program,
        exam_series=v_series,
        target_grade=v_target,
        total_student_hours_available=v_total_hours,
        mathematics_hours_budget=v_math_hours,
        profile_revision=v_revision,
        paper_comparability_epoch=v_epoch,
        last_exam_series_change_at=case when v_series_changed then now() else last_exam_series_change_at end,
        active_week_no=greatest(active_week_no,1),
        updated_at=now(),updated_by=v_uid
    where user_id=v_uid
    returning * into v_profile;

    if v_changed then
      insert into private.exam_prep_exam_map_revisions(
        user_id,program_version_id,profile_revision,paper_comparability_epoch,exam_series,target_grade,
        total_student_hours_available,mathematics_hours_budget,change_kind,series_changed,target_changed,hours_changed
      ) values(
        v_uid,v_program,v_revision,v_epoch,v_series,v_target,v_total_hours,v_math_hours,
        v_kind,v_series_changed,v_target_changed,v_hours_changed
      );
    end if;
  end if;

  perform private.rebuild_exam_prep_placement_v1(v_uid,null);

  return jsonb_build_object(
    'program_version_id',v_profile.program_version_id,
    'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,
    'total_student_hours_available',v_profile.total_student_hours_available,
    'mathematics_hours_budget',v_profile.mathematics_hours_budget,
    'active_week_no',v_profile.active_week_no,
    'profile_revision',v_profile.profile_revision,
    'paper_comparability_epoch',v_profile.paper_comparability_epoch,
    'series_changed',v_series_changed,
    'target_changed',v_target_changed,
    'hours_changed',v_hours_changed,
    'progress_retained',true,
    'prior_papers_remain_history',true,
    'prior_papers_count_toward_current_trend',case when v_series_changed then false else true end,
    'plan_rebuild_required',(v_series_changed or v_target_changed or v_hours_changed),
    'timetable_reconfirmation_required',v_series_changed,
    'note','Exam-plan changes never delete academic evidence. A genuine exam-series change starts a new full-paper comparability epoch; older papers remain visible history but do not count in the current readiness trend.'
  );
end;
$function$


-- Fail-closed selective patch of the *installed* placement function.
-- GitHub's disposable migration replay and current live SQL can have unrelated
-- non-academic formatting/body differences. Do NOT overwrite those other rules
-- with a copied production function; modify ONLY two unique, reviewed anchors.
DO $d3_placement$
DECLARE
  v_oid oid:=to_regprocedure('private.rebuild_exam_prep_placement_v1(uuid,text)');
  v_def text;
  v_old text:=$d3_old$        and p.mathematics_hours_budget is not null and p.mathematics_hours_budget>0
        and p.total_student_hours_available is not null and p.total_student_hours_available>0
        and p.mathematics_hours_budget<=p.total_student_hours_available
        and p.active_week_no>=1$d3_old$;
  v_new text:=$d3_new$        and nullif(btrim(p.exam_series),'') is not null
        and nullif(btrim(p.target_grade),'') is not null
        and p.active_week_no>=1$d3_new$;
BEGIN
  IF v_oid IS NULL THEN RAISE EXCEPTION 'd3_placement_missing'; END IF;
  IF NOT (SELECT p.prosecdef AND
        coalesce(array_to_string(p.proconfig,','),'') LIKE '%search_path=%'
      FROM pg_proc p WHERE p.oid=v_oid) THEN
    RAISE EXCEPTION 'd3_placement_security_contract_changed';
  END IF;
  v_def:=pg_get_functiondef(v_oid);
  IF length(v_def)-length(replace(v_def,v_old,''))<>length(v_old) OR
     length(v_def)-length(replace(v_def,'exam_profile_or_realistic_mathematics_budget_required',''))<>length('exam_profile_or_realistic_mathematics_budget_required')
  THEN RAISE EXCEPTION 'd3_placement_anchor_source_drift'; END IF;
  v_def:=replace(replace(v_def,v_old,v_new),
     'exam_profile_or_realistic_mathematics_budget_required','exam_profile_required_without_time_budget');
  EXECUTE v_def;
END $d3_placement$;

-- Preserve existing signature, owner, SECURITY DEFINER, search_path and EXECUTE grants: save_exam_prep_study_schedule_safe_v1.
CREATE OR REPLACE FUNCTION public.save_exam_prep_study_schedule_safe_v1(p_minutes_per_day integer, p_days_per_week integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid;
  v_old private.exam_prep_exam_profiles%rowtype;
  v_new private.exam_prep_exam_profiles%rowtype;
  v_budget numeric;
  v_change boolean;
  v_profile_result jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_minutes_per_day is null or p_minutes_per_day<15 or
     p_minutes_per_day>240 or mod(p_minutes_per_day,5)<>0 then
    raise exception 'exam_prep_study_minutes_invalid';
  end if;
  if p_days_per_week is null or p_days_per_week<1 or p_days_per_week>7 then
    raise exception 'exam_prep_study_days_invalid';
  end if;
  v_budget:=round((p_minutes_per_day::numeric * p_days_per_week::numeric)/60,4);

  select * into v_old from private.exam_prep_exam_profiles
  where user_id=v_uid for update;
  if v_old.user_id is null or v_old.program_version_id is null then
    raise exception 'exam_prep_profile_required';
  end if;
  if v_old.total_student_hours_available is not null and v_budget>v_old.total_student_hours_available then
    raise exception 'exam_prep_study_exceeds_total_weekly_budget';
  end if;
  v_change:=v_old.study_minutes_per_day is distinct from p_minutes_per_day
        or v_old.study_days_per_week is distinct from p_days_per_week;
  if v_old.mathematics_hours_budget is distinct from v_budget then
    -- Existing governed profile change creates a revision and preserves all
    -- old learning/session evidence. Does not change the overall hours.
    v_profile_result:=public.save_exam_prep_exam_profile_v2(
      v_old.exam_series,
      v_old.target_grade,
      v_old.total_student_hours_available,
      v_budget
    );
  end if;
  if v_change then
    update private.exam_prep_exam_profiles
    set study_minutes_per_day=p_minutes_per_day,
        study_days_per_week=p_days_per_week,
        study_schedule_revision=study_schedule_revision+1,
        study_schedule_updated_at=now(),
        updated_at=now(),
        updated_by=v_uid
    where user_id=v_uid;
  end if;
  select * into v_new from private.exam_prep_exam_profiles where user_id=v_uid;

  return jsonb_build_object(
    'study_minutes_per_day',v_new.study_minutes_per_day,
    'study_days_per_week',v_new.study_days_per_week,
    'mathematics_hours_per_week',v_new.mathematics_hours_budget,
    'total_student_hours_per_week',v_new.total_student_hours_available,
    'study_schedule_revision',v_new.study_schedule_revision,
    'study_schedule_updated_at',v_new.study_schedule_updated_at,
    'changed',v_change or v_old.mathematics_hours_budget is distinct from v_budget,
    'plan_rebuild_required',coalesce((v_profile_result->>'plan_rebuild_required')::boolean,false),
    'progress_retained',true,
    'forecast_available',false
  );
end;
$function$


-- Preserve existing signature, owner, SECURITY DEFINER, search_path and EXECUTE grants: get_exam_prep_shared_study_capacity_safe_v1.
CREATE OR REPLACE FUNCTION public.get_exam_prep_shared_study_capacity_safe_v1()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_now timestamptz;
  v_budget numeric;
  v_earliest timestamptz;
  v_latest timestamptz;
  v_first_hours numeric;
  v_last_hours numeric;
  v_p1_date timestamptz;
  v_p5_date timestamptz;
  v_p1_state text;
  v_p5_state text;
  v_p1_diagnostic boolean;
  v_p5_diagnostic boolean;
  v_p1_diag_end timestamptz;
  v_p5_diag_end timestamptz;
  v_code text;
  v_start timestamptz;
  v_has_complete boolean;
  v_diagnostic_end timestamptz;
  v_status text;
  v_components jsonb:='{}'::jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_profile
  from private.exam_prep_exam_profiles
  where user_id=v_uid;
  if v_profile.user_id is null or v_profile.program_version_id is null then
    raise exception 'exam_prep_profile_required';
  end if;
  v_now:=private.exam_prep_effective_academic_now_v1(v_uid);
  v_budget:=v_profile.mathematics_hours_budget;
  if v_budget<0 or
     (v_profile.total_student_hours_available is not null and
       v_budget>v_profile.total_student_hours_available) then
    raise exception 'exam_prep_invalid_shared_math_budget';
  end if;

  foreach v_code in array array['P1','P5'] loop
    v_start:=null;v_has_complete:=false;v_diagnostic_end:=null;
    select a.scheduled_start_at into v_start
    from private.exam_prep_exam_appointments a
    where a.user_id=v_uid
      and a.program_version_id=v_profile.program_version_id
      and a.component_code=v_code
      and (a.exam_series_snapshot is null or
           lower(trim(a.exam_series_snapshot))=lower(trim(coalesce(v_profile.exam_series,''))));
    select coalesce(p.stage0_complete,false) into v_has_complete
    from private.exam_prep_component_placements p
    where p.user_id=v_uid and p.program_version_id=v_profile.program_version_id
      and p.component_code=v_code
    order by p.derived_at desc limit 1;
    v_has_complete:=coalesce(v_has_complete,false);
    if v_has_complete then
      select max(s.finalized_at) into v_diagnostic_end
      from private.exam_prep_sessions s
      where s.user_id=v_uid
        and s.program_version_id=v_profile.program_version_id
        and s.component_code=v_code
        and s.session_type='diagnostic'
        and s.status='finalized' and s.finalized_at is not null;
    end if;
    v_status:=case
      when not v_has_complete or v_diagnostic_end is null
        then 'diagnostic_incomplete'
      when v_start is null then 'exam_date_unconfirmed'
      when not private.exam_prep_exam_date_matches_series_v1(v_profile.exam_series,v_start)
        then 'exam_date_series_mismatch'
      when v_start<=v_now then 'exam_date_passed'
      when v_start<=v_diagnostic_end then 'exam_before_diagnostic'
      else 'calendar_capacity_available'
    end;
    v_components:=v_components||jsonb_build_object(
      v_code,jsonb_build_object(
        'component_code',v_code,
        'diagnostic_completed_at',v_diagnostic_end,
        'exam_date_confirmed',v_start is not null,
        'exam_start_at',v_start,
        'status',v_status,
        'paper_minutes',case when v_code='P1' then 110 else 75 end,
        'paper_minutes_are_daily_study_quota',false
      )
    );
    if v_status='calendar_capacity_available' then
      if v_earliest is null or v_start<v_earliest then v_earliest:=v_start; end if;
      if v_latest is null or v_start>v_latest then v_latest:=v_start; end if;
    end if;
  end loop;

  -- A wall-clock capacity at the student's ELECTED Math budget, not an
  -- effort requirement. Fractional weeks avoid turning five 30-minute days
  -- into seven daily hours. Shared and NON-ADDITIVE across both papers.
  if v_earliest is not null then
    v_first_hours:=round(v_budget * greatest(
      extract(epoch from (v_earliest-v_now)),0)::numeric / 604800,2);
    v_last_hours:=round(v_budget * greatest(
      extract(epoch from (v_latest-v_now)),0)::numeric / 604800,2);
  end if;

  return jsonb_build_object(
    'contract_version','exam_prep_shared_study_capacity_v1',
    'as_of',v_now,
    'P1',v_components->'P1',
    'P5',v_components->'P5',
    'chosen_math_hours_per_week',v_budget,
    'chosen_total_study_hours_per_week',v_profile.total_student_hours_available,
    'earliest_ready_paper_start_at',v_earliest,
    'latest_ready_paper_start_at',v_latest,
    'planned_shared_math_hours_to_earliest_exam',v_first_hours,
    'planned_shared_math_hours_to_latest_exam',v_last_hours,
    'shared_across_both_papers',true,
    'horizon_hours_additive_across_p1_p5',false,
    'capacity_is_recommendation',false,
    'capacity_is_access_limit',false,
    'may_study_above_plan',true,
    'recommended_study_hours_per_week',null,
    'recommended_daily_minutes',null,
    'recommendation_accept_enabled',false,
    'outside_iclub_study_minutes','unknown',
    'progress_notifications_only','after_completed_week_or_month',
    'explanation','Elected weekly hours scaled by exact remaining time, shared by P1 and P5. Does not estimate the hours necessary to learn unverified skills; no study access is ever capped.'
  );
end;
$function$


-- Preserve existing signature, owner, SECURITY DEFINER, search_path and EXECUTE grants: save_my_exam_prep_weekly_choice_s3_safe_v1.
CREATE OR REPLACE FUNCTION public.save_my_exam_prep_weekly_choice_s3_safe_v1(p_choice_code text, p_p1_minutes integer, p_p5_minutes integer, p_minutes_per_day integer, p_days_per_week integer, p_expected_schedule_revision integer, p_idempotency_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
 IF v_p.user_id IS NULL OR v_p.program_version_id IS NULL THEN
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
 v_week:=v_p.created_at+make_interval(secs => floor(extract(epoch FROM (now()-v_p.created_at))/604800)::int*604800);
 v_budget:=COALESCE(v_p.study_minutes_per_day*v_p.study_days_per_week,
    round(v_p.mathematics_hours_budget*60)::int);
 IF (v_budget IS NULL OR v_budget<0) AND p_choice_code<>'change'
 THEN RAISE EXCEPTION 'exam_prep_s3_missing_time_choice'; END IF;
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
   IF v_p.total_student_hours_available IS NOT NULL AND
      v_budget>round(v_p.total_student_hours_available*60)::int THEN
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
$function$


COMMIT;
