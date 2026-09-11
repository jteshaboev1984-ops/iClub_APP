begin;

-- P2-22: canonical mixed transfer must not recycle a question already delivered
-- to the same learner. Exposure is defined by frozen session membership, not by
-- whether the learner completed the session. This preserves independent transfer evidence.

create or replace function private.exam_prep_mixed_assessment_fresh_for_user_v1(
  p_user_id uuid,p_assessment_id bigint
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select p_user_id is not null
    and exists(select 1 from private.exam_prep_assessment_items ai where ai.assessment_id=p_assessment_id)
    and not exists(
      select 1
      from private.exam_prep_assessment_items ai
      join private.exam_prep_session_items si on si.question_id=ai.question_id
      join private.exam_prep_sessions s on s.id=si.session_id
      where ai.assessment_id=p_assessment_id
        and ai.question_id is not null
        and s.user_id=p_user_id
    );
$$;
revoke all on function private.exam_prep_mixed_assessment_fresh_for_user_v1(uuid,bigint) from public,anon,authenticated;
grant execute on function private.exam_prep_mixed_assessment_fresh_for_user_v1(uuid,bigint) to service_role;

create or replace function private.exam_prep_mixed_assessment_eligible_v1(
  p_user_id uuid,p_component_code text,p_active_week_no smallint,p_assessment_id bigint
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_mixed_nodes amn on amn.assessment_id=a.id
    where a.id=p_assessment_id
      and a.component_code=p_component_code
      and amn.component_code=p_component_code
      and a.assessment_type='mixed'
      and a.status='published'
      and private.exam_prep_mixed_assessment_fresh_for_user_v1(p_user_id,a.id)
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
          and (s.skill_code is null or s.objective_level<2 or coalesce(s.unresolved_correction_count,0)>0)
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
            where r.program_version_id=amn.program_version_id
              and r.component_code=p_component_code
              and r.schedule_status='active'
              and r.active_week_from<=p_active_week_no
          )
      )
  );
$$;
revoke all on function private.exam_prep_mixed_assessment_eligible_v1(uuid,text,smallint,bigint) from public,anon,authenticated;
grant execute on function private.exam_prep_mixed_assessment_eligible_v1(uuid,text,smallint,bigint) to service_role;

commit;