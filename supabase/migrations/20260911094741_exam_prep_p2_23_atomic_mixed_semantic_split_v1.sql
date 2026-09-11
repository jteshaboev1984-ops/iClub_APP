begin;

-- P2-23 corrects an over-tight interpretation introduced by P2-20.
-- The canonical source has two distinct concepts:
-- (a) atomic skill L3 concept/model evidence may require a successful mixed task;
-- (b) canonical mixed-node/integration mastery is a separate evidence layer outside the 81-skill denominator.
-- A same-component assessment explicitly governed/published as type=mixed is therefore valid atomic mixed-task evidence.
-- Cross-area canonical mixed coverage remains separately auditable and is not auto-awarded as L4/L5.

create or replace function private.exam_prep_atomic_mixed_assessment_qualifies_v1(
  p_assessment_id bigint,
  p_component_code text
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
    where a.id=p_assessment_id
      and p_component_code in ('P1','P5')
      and a.component_code=p_component_code
      and a.assessment_type='mixed'
      and a.status='published'
      and exists(
        select 1
        from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id
          and ai.reserve_role='mixed'
      )
      and not exists(
        select 1
        from private.exam_prep_assessment_items ai
        left join private.exam_prep_question_content_meta m on m.question_id=ai.question_id
        where ai.assessment_id=a.id
          and ai.question_id is not null
          and (
            m.id is null
            or m.reserve_role<>'mixed'
            or m.qa_scope_status<>'pass'
            or m.qa_math_status<>'pass'
            or m.qa_language_status<>'pass'
            or m.qa_technical_status<>'pass'
          )
      )
  );
$$;
revoke all on function private.exam_prep_atomic_mixed_assessment_qualifies_v1(bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_atomic_mixed_assessment_qualifies_v1(bigint,text) to service_role;

create or replace function private.exam_prep_atomic_mixed_satisfied_v1(
  p_user_id uuid,
  p_component_code text,
  p_skill_code text
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1
    from private.exam_prep_evidence_events e
    join private.exam_prep_sessions s on s.id=e.session_id
    where e.user_id=p_user_id
      and e.component_code=p_component_code
      and e.skill_code=p_skill_code
      and e.evidence_type='mixed'
      and e.verification_status='app_verified'
      and e.is_correct is true
      and s.user_id=p_user_id
      and s.component_code=p_component_code
      and s.status='finalized'
      and private.exam_prep_atomic_mixed_assessment_qualifies_v1(s.assessment_id,p_component_code)
  );
$$;
revoke all on function private.exam_prep_atomic_mixed_satisfied_v1(uuid,text,text) from public,anon,authenticated;
grant execute on function private.exam_prep_atomic_mixed_satisfied_v1(uuid,text,text) to service_role;

create or replace function private.exam_prep_mixed_mastery_assessment_qualifies_v1(
  p_assessment_id bigint,
  p_component_code text
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select private.exam_prep_atomic_mixed_assessment_qualifies_v1(p_assessment_id,p_component_code);
$$;
revoke all on function private.exam_prep_mixed_mastery_assessment_qualifies_v1(bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_mixed_mastery_assessment_qualifies_v1(bigint,text) to service_role;
comment on function private.exam_prep_mixed_mastery_assessment_qualifies_v1(bigint,text) is
'Backward-compatible objective_state_v1 atomic mixed-task qualifier only. Do not use as a canonical L4/L5 mixed-mastery claim.';

create or replace function private.exam_prep_mixed_mastery_satisfied_v1(
  p_user_id uuid,
  p_component_code text,
  p_skill_code text
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select private.exam_prep_atomic_mixed_satisfied_v1(p_user_id,p_component_code,p_skill_code);
$$;
revoke all on function private.exam_prep_mixed_mastery_satisfied_v1(uuid,text,text) from public,anon,authenticated;
grant execute on function private.exam_prep_mixed_mastery_satisfied_v1(uuid,text,text) to service_role;
comment on function private.exam_prep_mixed_mastery_satisfied_v1(uuid,text,text) is
'Backward-compatible objective_state_v1 atomic skill mixed-task evidence check. Canonical mixed-node portfolio mastery is separate.';

create or replace function private.exam_prep_canonical_mixed_assessment_v1(
  p_assessment_id bigint,
  p_component_code text
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
  );
$$;
revoke all on function private.exam_prep_canonical_mixed_assessment_v1(bigint,text) from public,anon,authenticated;
grant execute on function private.exam_prep_canonical_mixed_assessment_v1(bigint,text) to service_role;

create or replace function private.exam_prep_canonical_mixed_objective_area_span_v1(
  p_user_id uuid,
  p_component_code text
)
returns integer
language sql
stable
security definer
set search_path=''
as $$
  select count(distinct sn.official_syllabus_section)::integer
  from private.exam_prep_evidence_events e
  join private.exam_prep_sessions s on s.id=e.session_id
  join private.exam_prep_assessment_mixed_nodes amn on amn.assessment_id=s.assessment_id
  join private.exam_prep_syllabus_nodes sn
    on sn.program_version_id=amn.program_version_id
   and sn.component_code=p_component_code
   and sn.skill_code=e.skill_code
  where e.user_id=p_user_id
    and e.component_code=p_component_code
    and e.evidence_type='mixed'
    and e.verification_status='app_verified'
    and e.is_correct is true
    and s.user_id=p_user_id
    and s.component_code=p_component_code
    and s.status='finalized'
    and amn.component_code=p_component_code;
$$;
revoke all on function private.exam_prep_canonical_mixed_objective_area_span_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.exam_prep_canonical_mixed_objective_area_span_v1(uuid,text) to service_role;
comment on function private.exam_prep_canonical_mixed_objective_area_span_v1(uuid,text) is
'Objective audit metric for canonical mixed evidence area span. It does not award L4/L5 or Mentor Verified mastery.';

create or replace function private.exam_prep_mixed_assessment_eligible_v1(
  p_user_id uuid,
  p_component_code text,
  p_active_week_no smallint,
  p_assessment_id bigint
) returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1
    from private.exam_prep_assessments a
    where a.id=p_assessment_id
      and a.component_code=p_component_code
      and a.assessment_type='mixed'
      and a.status='published'
      and private.exam_prep_atomic_mixed_assessment_qualifies_v1(a.id,p_component_code)
      and private.exam_prep_mixed_assessment_fresh_for_user_v1(p_user_id,a.id)
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
$$;
revoke all on function private.exam_prep_mixed_assessment_eligible_v1(uuid,text,smallint,bigint) from public,anon,authenticated;
grant execute on function private.exam_prep_mixed_assessment_eligible_v1(uuid,text,smallint,bigint) to service_role;

create or replace function private.exam_prep_select_mixed_assessment_v1(
  p_user_id uuid,
  p_component_code text,
  p_active_week_no smallint
) returns bigint
language sql
stable
security definer
set search_path=''
as $$
  select a.id
  from private.exam_prep_assessments a
  where a.component_code=p_component_code
    and a.assessment_type='mixed'
    and a.status='published'
    and private.exam_prep_mixed_assessment_eligible_v1(
      p_user_id,p_component_code,p_active_week_no,a.id
    )
  order by
    (
      select count(*)
      from private.exam_prep_assessment_items ai
      join private.exam_prep_skill_states s
        on s.user_id=p_user_id
       and s.component_code=p_component_code
       and s.skill_code=ai.primary_skill_code
       and s.engine_version='objective_state_v1'
      where ai.assessment_id=a.id and s.hold_reason='mixed_transfer_missing'
    ) desc,
    exists(select 1 from private.exam_prep_assessment_mixed_nodes amn where amn.assessment_id=a.id) desc,
    a.id
  limit 1;
$$;
revoke all on function private.exam_prep_select_mixed_assessment_v1(uuid,text,smallint) from public,anon,authenticated;
grant execute on function private.exam_prep_select_mixed_assessment_v1(uuid,text,smallint) to service_role;

commit;