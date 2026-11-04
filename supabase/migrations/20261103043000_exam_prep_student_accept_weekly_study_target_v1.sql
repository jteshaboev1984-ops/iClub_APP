-- P2-17: visible comparison of student-chosen Math hours to iClub's
-- approximate P1/P5 paper target. Only explicit learner action accepts a
-- recommendation. No approval from school, no automatic increase/limits,
-- and NO writes to academic answers/progress/tour/certificate tables.
-- The existing exam profile v2 owns all revision/placement bookkeeping.

create or replace function public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2()
returns jsonb language plpgsql stable security definer set search_path to ''
as $fn$
declare
 v_uid uuid;
 v_version bigint;
 v_original jsonb;
 v_p1 jsonb;
 v_p5 jsonb;
 v_p1hrs numeric;
 v_p5hrs numeric;
 v_w1 numeric;
 v_w5 numeric;
 v_total numeric;
 v_weekly numeric;
 v_first_rate numeric;
 v_later_rate numeric;
 v_known text;
 v_budget numeric;
 v_total_budget numeric;
 v_profile_revision integer;
begin
 v_uid:=private.exam_prep_require_core_access_v1();
 select p.program_version_id,p.mathematics_hours_budget,
        p.total_student_hours_available,p.profile_revision
 into v_version,v_budget,v_total_budget,v_profile_revision
 from private.exam_prep_exam_profiles p
 where p.user_id=v_uid;
 if v_version is null then raise exception 'exam_prep_profile_required'; end if;

 v_original:=public.get_exam_prep_simple_learning_timeline_safe_v1();
 v_p1:=private.exam_prep_simple_guided_effort_internal_v1(v_uid,v_version,'P1');
 v_p5:=private.exam_prep_simple_guided_effort_internal_v1(v_uid,v_version,'P5');

 if (v_p1->>'skill_count')::int<>45 or (v_p5->>'skill_count')::int<>36
   or (v_p1->>'source_coverage_count')::int<>45
   or (v_p5->>'source_coverage_count')::int<>36
   or (v_p1->>'historical_guided_content_hours')::numeric<>90
   or (v_p5->>'historical_guided_content_hours')::numeric<>50
 then raise exception 'exam_prep_guided_content_source_incomplete'; end if;

 v_p1hrs:=(v_p1->>'estimated_remaining_hours')::numeric;
 v_p5hrs:=(v_p5->>'estimated_remaining_hours')::numeric;
 if v_p1hrs is null or v_p5hrs is null then
    raise exception 'exam_prep_current_skill_evidence_incomplete';
 end if;
 v_total:=v_p1hrs+v_p5hrs;
 v_w1:=case when v_original->'P1'->>'exam_date_status'='valid_exam_date'
   then (v_original->'P1'->>'weeks_to_exam')::numeric else null::numeric end;
 v_w5:=case when v_original->'P5'->>'exam_date_status'='valid_exam_date'
   then (v_original->'P5'->>'weeks_to_exam')::numeric else null::numeric end;
 v_w1:=case when v_w1>0 then v_w1 else null::numeric end;
 v_w5:=case when v_w5>0 then v_w5 else null::numeric end;

 -- If both confirmed deadlines exist, solve minimal constant joint Math
 -- weekly pace satisfying earlier deadline and combined later deadline.
 -- This is a SHARED resource, not P1 weeks + P5 weeks.
 if v_w1 is not null and v_w5 is not null then
    if v_w1<=v_w5 then
      v_first_rate:=v_p1hrs/v_w1;
      v_later_rate:=v_total/v_w5;
    else
      v_first_rate:=v_p5hrs/v_w5;
      v_later_rate:=v_total/v_w1;
    end if;
    v_weekly:=round(greatest(v_first_rate,v_later_rate),1);
    v_known:='both_paper_dates_confirmed';
 else
    v_weekly:=null;
    v_known:='missing_at_least_one_paper_exam_date';
 end if;

 return (v_original || jsonb_build_object(
  'contract_version','exam_prep_one_line_progress_timeline_v2_estimated',
  'P1',v_original->'P1'||jsonb_build_object(
    'estimated_remaining_study_hours',v_p1hrs,
    'estimated_remaining_study_hours_low',v_p1->'estimated_remaining_hours_lower_sensitivity',
    'estimated_remaining_study_hours_high',v_p1->'estimated_remaining_hours_upper_sensitivity',
    'estimated_component_weekly_hours',case when v_w1 is not null
       then round(v_p1hrs/v_w1,1) else null::numeric end,
    'estimate_is_iclub_heuristic',true),
  'P5',v_original->'P5'||jsonb_build_object(
    'estimated_remaining_study_hours',v_p5hrs,
    'estimated_remaining_study_hours_low',v_p5->'estimated_remaining_hours_lower_sensitivity',
    'estimated_remaining_study_hours_high',v_p5->'estimated_remaining_hours_upper_sensitivity',
    'estimated_component_weekly_hours',case when v_w5 is not null
       then round(v_p5hrs/v_w5,1) else null::numeric end,
    'estimate_is_iclub_heuristic',true),
  'estimated_remaining_math_hours',v_total,
  'baseline_math_guided_content_hours',140,
  'estimated_joint_math_hours_per_week',v_weekly,
  'joint_paper_dates_status',v_known,
  'existing_chosen_math_hours_per_week',v_budget,
  'student_total_hours_per_week',v_total_budget,
  'student_budget_profile_revision',v_profile_revision,
  'estimated_weekly_hours_difference_from_chosen',
     case when v_weekly is not null and v_budget is not null
       then round(v_weekly-v_budget,1) else null::numeric end,
  'estimate_method','iclub_cambridge_2020_topic_guided_hours_times_skill_status_factors',
  'source_guided_hours_are_not_private_study_hours',true,
  'factors_are_iclub_planning_assumptions_not_official_cambridge',true,
  'estimate_is_not_a_grade_or_completion_guarantee',true,
  'recommended_schedule_applied_automatically',false,
  'study_access_capped',false,
  'learning_evidence_mutated',false
 ));
end;
$fn$;
revoke all on function public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2()
 from public,anon;
grant execute on function public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2()
 to authenticated,service_role;


-- One-tap acceptance is intentionally strict and transactional.
-- Recompute the current suggested hours ON SERVER, use profile optimistic
-- revision and expected old budget, and refuse if whole-week capacity
-- would be exceeded. A suggestion is not mandatory and does not gate study.
create or replace function public.accept_my_exam_prep_timeline_weekly_target_safe_v1(
 p_expected_current_math_hours numeric,
 p_expected_profile_revision integer,
 p_new_math_hours numeric
)
returns jsonb
language plpgsql
security definer
set search_path to ''
as $fn$
declare
 v_uid uuid;
 v_old private.exam_prep_exam_profiles%rowtype;
 v_est jsonb;
 v_target numeric;
 v_first boolean;
 v_fifth boolean;
begin
 v_uid:=private.exam_prep_require_core_access_v1();
 select * into v_old
 from private.exam_prep_exam_profiles
 where user_id=v_uid for update;
 if v_old.user_id is null or v_old.program_version_id is null then
   raise exception 'exam_prep_profile_required';
 end if;
 if p_expected_profile_revision is null
   or p_expected_profile_revision<>v_old.profile_revision
   or p_expected_current_math_hours is null
   or p_expected_current_math_hours is distinct from v_old.mathematics_hours_budget then
   -- SQLSTATE 40001 means serialization_failure and triggers repeated
   -- transaction retries in PostgREST 14. Stale user input is a normal
   -- application conflict, not a transient database serialization error.
   -- PT409 maps to HTTP 409 and fails closed without a retry loop.
   raise exception 'exam_prep_weekly_plan_changed_refresh'
     using errcode='PT409';
 end if;

 v_est:=public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2();
 v_first:=v_est->'P1'->>'exam_date_status'='valid_exam_date';
 v_fifth:=v_est->'P5'->>'exam_date_status'='valid_exam_date';
 v_target:=case
   when v_first and v_fifth
     then (v_est->>'estimated_joint_math_hours_per_week')::numeric
   when v_first and not v_fifth
     then (v_est->'P1'->>'estimated_component_weekly_hours')::numeric
   when v_fifth and not v_first
     then (v_est->'P5'->>'estimated_component_weekly_hours')::numeric
   else null::numeric end;

 if v_target is null or v_target<=0
   or v_target>168
   or p_new_math_hours is null
   or p_new_math_hours is distinct from v_target then
   raise exception 'exam_prep_weekly_target_invalid_refresh'
     using errcode='22023';
 end if;
 if v_old.total_student_hours_available is null
   or v_target>v_old.total_student_hours_available then
   raise exception 'exam_prep_weekly_target_exceeds_total_available'
     using errcode='22023';
 end if;
 if v_old.mathematics_hours_budget is null
   or v_target<=v_old.mathematics_hours_budget then
   raise exception 'exam_prep_weekly_time_already_sufficient'
     using errcode='22023';
 end if;

 -- Reuse the EXISTING academically governed profile writer so the hours
 -- change has its normal revision ledger; no duplicated custom mutations.
 perform public.save_exam_prep_exam_profile_v2(
   v_old.exam_series,v_old.target_grade,
   v_old.total_student_hours_available,v_target
 );
 return public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2();
end;
$fn$;

revoke all on function public.accept_my_exam_prep_timeline_weekly_target_safe_v1(numeric,integer,numeric)
 from public,anon;
grant execute on function public.accept_my_exam_prep_timeline_weekly_target_safe_v1(numeric,integer,numeric)
 to authenticated,service_role;
comment on function public.accept_my_exam_prep_timeline_weekly_target_safe_v1(numeric,integer,numeric)
 is 'Only on student explicit tap: recheck current Math target, selected date, original budget/profile revision, total study capacity; delegate to existing v2 profile audit. No auto acceptance, learning quota or academic evidence deletion.';
