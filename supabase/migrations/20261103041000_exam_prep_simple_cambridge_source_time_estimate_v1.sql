-- iClub P2-14: practical time estimate from Cambridge Scheme of Work,
-- source-mapped current 9709 P1/P5 skill evidence. Architect requested a
-- useful number without waiting for empirical personal timing research.
--
-- Cambridge 2020 topic hours = GUIDED TEACHING, NOT independent study.
-- iClub's explicit 1:1 planning proxy and 0.6/0.8 completion adjustments
-- are a product HEURISTIC, NOT official Cambridge individual requirements.
-- NO updates to live learner evidence, profile, exams, questions or clocks.

create or replace function private.exam_prep_simple_guided_effort_internal_v1(
  p_uid uuid,p_version bigint,p_component text
)
returns jsonb language sql stable security invoker set search_path to ''
as $fn$
with authentic as (
  select private.exam_prep_remaining_work_internal_v1(p_uid,p_version,p_component)
     as evidence
), items as (
  select e.item->>'skill_code' skill_code,
         e.item->>'evidence_status' evidence_status,
         coalesce((e.item->>'recorded_unresolved_correction_count')::int,0) open_corrections
  from authentic a
  cross join lateral jsonb_array_elements(a.evidence->'items') e(item)
), sections as (
 select s.skill_code,s.component_code,s.official_syllabus_section,
        h.suggested_guided_teaching_hours::numeric as topic_guided_hours,
        h.source_url,h.source_scheme_version,
        count(*) over(partition by s.program_version_id,s.component_code,
           s.official_syllabus_section)::numeric as skills_in_section
 from private.exam_prep_syllabus_nodes s
 left join private.exam_prep_historical_topic_teaching_refs_v1 h
   on h.program_version_id=s.program_version_id
   and h.component_code=s.component_code
   and h.official_syllabus_section=s.official_syllabus_section
 where s.program_version_id=p_version and s.component_code=p_component
), weighted as (
 select s.*,i.evidence_status,i.open_corrections,
   case
     when i.evidence_status='objective_coverage_confirmed' then 0.00::numeric
     when i.evidence_status='unobserved' then 1.00::numeric
     when i.evidence_status='observed_unconfirmed' and i.open_corrections>0
       then 0.80::numeric
     when i.evidence_status='observed_unconfirmed' then 0.60::numeric
     else null::numeric
   end as remaining_work_factor,
   (s.topic_guided_hours*60/s.skills_in_section) as baseline_guided_minutes
 from sections s left join items i on i.skill_code=s.skill_code
)
select jsonb_build_object(
 'component_code',p_component,
 'skill_count',count(*)::int,
 'source_coverage_count',count(topic_guided_hours)::int,
 'historical_guided_content_hours',round(sum(topic_guided_hours/skills_in_section),2),
 'estimated_remaining_hours',case
   when count(*)=count(topic_guided_hours) and count(*)=count(remaining_work_factor)
     then round(sum(baseline_guided_minutes*remaining_work_factor)/60,1)
   else null::numeric end,
 'estimated_remaining_hours_lower_sensitivity',case
   when count(*)=count(topic_guided_hours) and count(*)=count(remaining_work_factor)
     then round(sum(baseline_guided_minutes*remaining_work_factor)*0.75/60,1)
   else null::numeric end,
 'estimated_remaining_hours_upper_sensitivity',case
   when count(*)=count(topic_guided_hours) and count(*)=count(remaining_work_factor)
     then round(sum(baseline_guided_minutes*remaining_work_factor)*1.25/60,1)
   else null::numeric end,
 'source_kind','cambridge_2020_scheme_of_work_guided_teaching_topic_hours',
 'assumption_kind','iclub_explicit_guided_to_study_planning_proxy_not_measured',
 'factors',jsonb_build_object(
    'unobserved',1.0,'attempted_unconfirmed_no_open_error',0.6,
    'attempted_unconfirmed_open_error',0.8,'objective_covered',0.0),
 'sensitivity_band_is_statistical_confidence_interval',false,
 'source_hours_are_official_private_study_requirement',false,
 'estimate_is_cambridge_endorsed_personal_hour_requirement',false,
 'items',coalesce(jsonb_agg(jsonb_build_object(
    'skill_code',skill_code,'section',official_syllabus_section,
    'source_topic_teaching_hours',topic_guided_hours,
    'source_skills_in_topic',skills_in_section,
    'base_guided_minutes',round(baseline_guided_minutes,1),
    'remaining_work_factor',remaining_work_factor,
    'estimated_remaining_minutes',round(baseline_guided_minutes*remaining_work_factor,1)
 ) order by skill_code),'[]'::jsonb)
) from weighted;
$fn$;
revoke all on function private.exam_prep_simple_guided_effort_internal_v1(uuid,bigint,text)
 from public,anon,authenticated;

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
begin
 v_uid:=private.exam_prep_require_core_access_v1();
 select p.program_version_id,p.mathematics_hours_budget
 into v_version,v_budget
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

comment on function public.get_exam_prep_simple_learning_timeline_with_hours_safe_v2() is
'iClub approximate 9709 P1/P5 source-weighted remaining hours and joint deadline pace. Historical Cambridge teacher-guided hours are an explicit unvalidated student planning proxy, not official independent-study guidance. Strict owner-only, read-only, no automatic plan edits.';
