-- Mathematics 9709 P1/P5: owner-scoped workload REVIEW projection.
-- Uses real syllabus, objective evidence, verified component diagnostics and
-- confirmed appointment records. NEVER infers personalized Cambridge hours.
-- Earlier PR adds norm register; this is standalone in Package 2 branch and
-- does NOT depend on draft Package 1 RPCs or access/rollout changes.

create or replace function public.get_exam_prep_workload_review_projection_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
 v_uid uuid;
 v_profile private.exam_prep_exam_profiles%rowtype;
 v_now timestamptz;
 v_component text;
 v_total int;
 v_norm_total int;
 v_approved int;
 v_unobserved int;
 v_observed_unconfirmed int;
 v_confirmed int;
 v_corrections int;
 v_other_evidence int;
 v_screening boolean;
 v_diagnostic_done_at timestamptz;
 v_start timestamptz;
 v_appointment private.exam_prep_exam_appointments%rowtype;
 v_days_remaining int;
 v_state text;
 v_paper_minutes int;
 v_result jsonb:='{}'::jsonb;
begin
 v_uid:=private.exam_prep_require_core_access_v1();

 select * into v_profile
 from private.exam_prep_exam_profiles
 where user_id=v_uid;
 if v_profile.user_id is null or v_profile.program_version_id is null then
   raise exception 'exam_prep_profile_required';
 end if;
 v_now:=private.exam_prep_effective_academic_now_v1(v_uid);

 foreach v_component in array array['P1','P5'] loop
   v_total:=0;v_norm_total:=0;v_approved:=0;
   v_unobserved:=0;v_observed_unconfirmed:=0;v_confirmed:=0;
   v_corrections:=0;v_other_evidence:=0;v_days_remaining:=null;
   v_start:=null;v_diagnostic_done_at:=null;v_screening:=false;
   v_paper_minutes:=case when v_component='P1' then 110 else 75 end;

   -- Distinct-on prevents old engine-version rows from being counted twice.
   -- A missing skill state or zero OBJECTIVE evidence is UNKNOWN, never weak.
   with latest_states as (
     select distinct on (s.skill_code)
       s.skill_code,s.objective_evidence_count,s.objective_level,
       s.coverage_confirmed,s.unresolved_correction_count,
       s.written_count,s.has_mentor_verified_evidence
     from private.exam_prep_skill_states s
     where s.user_id=v_uid
       and s.program_version_id=v_profile.program_version_id
       and s.component_code=v_component
     order by s.skill_code,s.derived_at desc,s.engine_version desc
   )
   select count(*)::int,
          count(n.skill_code)::int,
          count(n.skill_code) filter (
            where n.estimate_status='approved' and
              n.estimated_core_min_minutes is not null and
              n.estimated_core_max_minutes is not null and
              n.estimated_revision_min_minutes is not null and
              n.estimated_revision_max_minutes is not null)::int,
          count(*) filter(where coalesce(t.objective_evidence_count,0)=0)::int,
          count(*) filter(where coalesce(t.objective_evidence_count,0)>0 and
            not (t.coverage_confirmed=true and t.objective_level>=2 and
                 t.unresolved_correction_count=0))::int,
          count(*) filter(where coalesce(t.objective_evidence_count,0)>0 and
            t.coverage_confirmed=true and t.objective_level>=2 and
            t.unresolved_correction_count=0)::int,
          count(*) filter(where coalesce(t.unresolved_correction_count,0)>0)::int,
          count(*) filter(where coalesce(t.objective_evidence_count,0)=0 and
              (coalesce(t.written_count,0)>0 or
               coalesce(t.has_mentor_verified_evidence,false)=true))::int
   into v_total,v_norm_total,v_approved,v_unobserved,v_observed_unconfirmed,
        v_confirmed,v_corrections,v_other_evidence
   from private.exam_prep_syllabus_nodes c
   left join private.exam_prep_skill_workload_norms_v1 n
      on n.program_version_id=c.program_version_id and
         n.skill_code=c.skill_code and n.component_code=c.component_code
   left join latest_states t on t.skill_code=c.skill_code
   where c.program_version_id=v_profile.program_version_id
     and c.component_code=v_component;

   -- Do not assume a finalized screening chunk means full diagnostic.
   select coalesce(p.stage0_complete,false) into v_screening
   from private.exam_prep_component_placements p
   where p.user_id=v_uid and p.program_version_id=v_profile.program_version_id
     and p.component_code=v_component
   order by p.derived_at desc limit 1;
   v_screening:=coalesce(v_screening,false);
   if v_screening then
     select max(s.finalized_at) into v_diagnostic_done_at
     from private.exam_prep_sessions s
     where s.user_id=v_uid and s.program_version_id=v_profile.program_version_id
       and s.component_code=v_component and s.session_type='diagnostic'
       and s.status='finalized' and s.finalized_at is not null;
   end if;

   select * into v_appointment
   from private.exam_prep_exam_appointments a
   where a.user_id=v_uid and a.program_version_id=v_profile.program_version_id
     and a.component_code=v_component and
     (a.exam_series_snapshot is null or
      lower(trim(a.exam_series_snapshot))=lower(trim(coalesce(v_profile.exam_series,''))));
   if v_appointment.user_id is not null then
      v_start:=v_appointment.scheduled_start_at;
      v_days_remaining:=(
        (v_start at time zone 'Asia/Tashkent')::date -
        (v_now at time zone 'Asia/Tashkent')::date
      );
   end if;

   v_state:=case
     when not v_screening or v_diagnostic_done_at is null
       then 'diagnostic_incomplete'
     when v_start is null then 'exam_date_not_confirmed'
     when not private.exam_prep_exam_date_matches_series_v1(v_profile.exam_series,v_start)
       then 'exam_date_series_mismatch'
     when v_start<=v_now then 'exam_date_passed'
     when v_start<=v_diagnostic_done_at then 'exam_before_diagnostic'
     when v_norm_total<>v_total or v_approved<>v_total
       then 'academic_workload_norms_incomplete'
     else 'personal_workload_engine_not_approved'
   end;

   v_result:=v_result||jsonb_build_object(
     v_component,jsonb_build_object(
       'component_code',v_component,
       'status',v_state,
       'curriculum_skills',v_total,
       'source_mapped_norms',v_norm_total,
       'academically_approved_norms',v_approved,
       'skills_unknown_objective_level',v_unobserved,
       'skills_with_observed_but_unconfirmed_objective_level',v_observed_unconfirmed,
       'skills_with_confirmed_objective_coverage',v_confirmed,
       'skills_with_unresolved_corrections',v_corrections,
       'skills_with_other_evidence_only',v_other_evidence,
       'diagnostic_complete',v_screening and v_diagnostic_done_at is not null,
       'diagnostic_completed_at',v_diagnostic_done_at,
       'exam_start_at',v_start,
       'exam_date_confirmation',case when v_start is null then null
           else v_appointment.confirmation_source end,
       'days_to_exam',case when v_start is null or
             not private.exam_prep_exam_date_matches_series_v1(v_profile.exam_series,v_start)
             then null else greatest(v_days_remaining,0) end,
       'cambridge_full_paper_exam_minutes',v_paper_minutes,
       'cambridge_paper_time_is_study_quota',false,
       'current_weekly_math_budget_hours',v_profile.mathematics_hours_budget,
       'recommended_daily_minutes',null,
       'recommended_weekly_hours_min',null,
       'recommended_weekly_hours_max',null,
       'numeric_recommendation_available',false,
       'learning_time_cap',false,
       'confidence','unverified_skill_study_time'
     )
   );
 end loop;
 return jsonb_build_object(
   'contract_version','exam_prep_workload_review_projection_v1',
   'as_of',v_now,
   'P1',v_result->'P1','P5',v_result->'P5',
   'syllabus_ref','Cambridge 9709 syllabus for 2026 and 2027',
   'paper_duration_ref_url',
     'https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf',
   'recommended_daily_minutes',null,
   'recommendation_accept_enabled',false,
   'grade_prediction_available',false,
   'outside_iclub_study_minutes','unknown',
   'notifications_only','after_completed_week_or_month',
   'learning_time_cap',false
 );
end;
$function$;

revoke all on function public.get_exam_prep_workload_review_projection_safe_v1()
 from public,anon;
grant execute on function public.get_exam_prep_workload_review_projection_safe_v1()
 to authenticated,service_role;

comment on function public.get_exam_prep_workload_review_projection_safe_v1() is
'Read-only owner P1/P5 evidence and exact Cambridge paper-duration source. Unknown objective skill evidence is NOT graded as weak; no invented 81-skill study-hour forecast, no grade predictions or study caps.';
