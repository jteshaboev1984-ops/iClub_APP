-- Exam Prep governed mixed-transfer eligibility fix.
-- Canonical mixed transfer is same-component and may be within one official syllabus area.
-- Keep atomic L2, correction, runway and transfer-gap gates unchanged.
create or replace function private.exam_prep_mixed_assessment_eligible_v1(
  p_user_id uuid,
  p_component_code text,
  p_active_week_no smallint,
  p_assessment_id bigint
) returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists(
    select 1
    from private.exam_prep_assessments a
    where a.id=p_assessment_id
      and a.component_code=p_component_code
      and a.assessment_type='mixed'
      and a.status='published'
      and (
        select count(distinct ai.primary_skill_code)
        from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id
      )>=2
      and not exists(
        select 1
        from private.exam_prep_assessment_items ai
        left join private.exam_prep_skill_states s
          on s.user_id=p_user_id
          and s.component_code=p_component_code
          and s.skill_code=ai.primary_skill_code
          and s.engine_version='objective_state_v1'
        where ai.assessment_id=a.id
          and (
            s.skill_code is null
            or s.objective_level<2
            or coalesce(s.unresolved_correction_count,0)>0
          )
      )
      and exists(
        select 1
        from private.exam_prep_assessment_items ai
        join private.exam_prep_skill_states s
          on s.user_id=p_user_id
          and s.component_code=p_component_code
          and s.skill_code=ai.primary_skill_code
          and s.engine_version='objective_state_v1'
        where ai.assessment_id=a.id
          and s.hold_reason in ('mixed_transfer_missing','transfer_evidence_missing')
      )
      and not exists(
        select 1
        from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id
          and not exists(
            select 1
            from private.exam_prep_content_runway_releases r
            join private.exam_prep_content_runway_release_skills rs
              on rs.release_id=r.id
             and rs.required_for_release
             and rs.skill_code=ai.primary_skill_code
            where r.program_version_id=(
                select program_version_id
                from private.exam_prep_exam_profiles
                where user_id=p_user_id
              )
              and r.component_code=p_component_code
              and r.schedule_status='active'
              and r.active_week_from<=p_active_week_no
          )
      )
  );
$function$;
