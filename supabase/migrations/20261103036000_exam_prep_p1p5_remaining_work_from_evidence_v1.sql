-- Internal SQL computation, read-only. No numeric-hour recommendations.
create or replace function private.exam_prep_remaining_work_internal_v1(p_uid uuid,p_version bigint,p_component text)
returns jsonb language sql stable security invoker set search_path to '' as $q$
    with latest_states as (
      select distinct on (s.skill_code)
        s.skill_code,
        s.objective_evidence_count,
        s.objective_level,
        s.coverage_confirmed,
        s.unresolved_correction_count,
        s.has_delayed_successful_retest,
        s.has_transfer_evidence,
        s.has_written_evidence
      from private.exam_prep_skill_states s
      where s.user_id=p_uid and
            s.program_version_id=p_version and
            s.component_code=p_component
      order by s.skill_code,s.derived_at desc,s.engine_version desc
    ),
    joined as (
      select c.component_code,c.skill_code,c.official_syllabus_section,
        coalesce(s.objective_evidence_count,0) as objective_count,
        coalesce(s.objective_level,0) as objective_level,
        coalesce(s.coverage_confirmed,false) as coverage_confirmed,
        greatest(coalesce(s.unresolved_correction_count,0),0) as open_corrections,
        coalesce(s.has_delayed_successful_retest,false) as delayed_retest_proven,
        coalesce(s.has_transfer_evidence,false) as transfer_proven,
        coalesce(s.has_written_evidence,false) as written_activity_recorded,
        coalesce(k.requires_retest_for_l3,false) as retest_required,
        coalesce(k.requires_transfer_for_l3,false) as transfer_required,
        coalesce(k.requires_mixed_for_l3,false) as mixed_required,
        coalesce(k.requires_written_for_l2,false) as written_activity_required,
        (k.skill_code is not null) as contract_present
      from private.exam_prep_syllabus_nodes c
      left join latest_states s on s.skill_code=c.skill_code
      left join private.exam_prep_skill_contracts k
        on k.program_version_id=c.program_version_id
          and k.component_code=c.component_code
          and k.skill_code=c.skill_code
      where c.program_version_id=p_version
        and c.component_code=p_component
    ),
    categories as (
      select j.*,
        case
          when j.objective_count=0 then 'unobserved'
          when j.coverage_confirmed and j.objective_level>=2
            and j.open_corrections=0 then 'objective_coverage_confirmed'
          else 'observed_unconfirmed'
        end as evidence_category
      from joined j
    ),
    work as (
      select z.*,
        case
          when not z.contract_present then array['academic_contract_missing']::text[]
          when z.evidence_category='unobserved'
            then array['targeted_check']::text[]
          when z.open_corrections>0
            then array['correction']::text[]
          when z.evidence_category='observed_unconfirmed'
            then array['targeted_practice']::text[]
          else array_remove(array[
            case when z.retest_required and not z.delayed_retest_proven
              then 'delayed_retest'::text end,
            case when (z.transfer_required or z.mixed_required)
                    and not z.transfer_proven
              then 'mixed_transfer'::text end,
            case when z.written_activity_required and not z.written_activity_recorded
              then 'written_work_unscored'::text end
          ]::text[],null::text)
        end as pending_actions
      from categories z
    )

select jsonb_build_object(
 'component_code',p_component,
 'skills_total',count(*),
 'skills_unobserved',count(*) filter(where evidence_category='unobserved'),
 'skills_observed_not_yet_confirmed',count(*) filter(where evidence_category='observed_unconfirmed'),
 'skills_objective_coverage_confirmed_not_final_mastery',count(*) filter(where evidence_category='objective_coverage_confirmed'),
 'skills_with_open_corrections',count(*) filter(where open_corrections>0),
 'historical_current_open_correction_entries',coalesce(sum(open_corrections),0),
 'unique_pending_action_slots',coalesce(sum(cardinality(pending_actions)),0),
 'items',coalesce(jsonb_agg(jsonb_build_object(
  'component_code',component_code,'skill_code',skill_code,
  'evidence_status',evidence_category,'pending_actions',to_jsonb(pending_actions),
  'recorded_unresolved_correction_count',open_corrections,
  'remaining_minutes_min',null,'remaining_minutes_max',null,
  'academic_hours_approved',false,'wrong_answer_multiplication_allowed',false,
  'unresolved_corrections_counted_as_separate_full_skill_courses',false,
  'written_activity_is_verified_method_mark',false
 ) order by skill_code),'[]'::jsonb),
 'remaining_study_minutes_min',null,'remaining_study_minutes_max',null,
 'individually_recommended_weekly_hours',null
) from work;
$q$;
revoke all on function private.exam_prep_remaining_work_internal_v1(uuid,bigint,text) from public,anon,authenticated;

create or replace function public.get_exam_prep_remaining_work_by_skill_safe_v1()
returns jsonb language plpgsql stable security definer set search_path to '' as $p$
declare u uuid; v bigint; a jsonb; b jsonb;
begin
 u:=private.exam_prep_require_core_access_v1();
 select program_version_id into v from private.exam_prep_exam_profiles where user_id=u;
 if v is null then raise exception 'exam_prep_profile_required'; end if;
 a:=private.exam_prep_remaining_work_internal_v1(u,v,'P1');
 b:=private.exam_prep_remaining_work_internal_v1(u,v,'P5');
 if (a->>'skills_total')::int<>45 or (b->>'skills_total')::int<>36
 then raise exception 'exam_prep_canonical_81_skill_contract_incomplete'; end if;
 return jsonb_build_object(
 'contract_version','exam_prep_result_led_remaining_work_v1',
 'P1',a,'P5',b,'numeric_recommendation_available',false,
 'recommended_weekly_hours',null,'recommendation_accept_enabled',false,
 'unknown_is_not_weak',true,'repeated_errors_deduplicated_by_component_skill_phase',true,
 'shared_mathematics_budget_double_counted',false,
 'student_may_study_beyond_plan',true,'grades_predicted',false);
end;
$p$;
revoke all on function public.get_exam_prep_remaining_work_by_skill_safe_v1() from public,anon;
grant execute on function public.get_exam_prep_remaining_work_by_skill_safe_v1() to authenticated,service_role;
