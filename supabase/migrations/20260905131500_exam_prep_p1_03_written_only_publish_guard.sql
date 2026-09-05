-- P1-03 hardening: allow a content version to publish without question meta only when
-- it is a fully governed written-only timed/paper version. Existing P1-02 question
-- skill-floor semantics remain unchanged for every version that has question content.
begin;

create or replace function private.exam_prep_content_version_publish_guard_v1()
returns trigger
language plpgsql
security definer
set search_path to ''
as $$
declare
  v_skill text;
  v_floor jsonb;
  v_n int;
  v_written int;
  v_assessments int;
begin
  if new.status<>'published' or old.status is not distinct from new.status then
    return new;
  end if;

  select count(distinct m.primary_skill_code) into v_n
  from private.exam_prep_question_content_meta m
  where m.content_version_id=new.id and m.lifecycle_state in ('published','reserve');

  -- Original P1-02 path: preserve the governed per-skill question floor exactly.
  if v_n>=1 then
    for v_skill in
      select distinct m.primary_skill_code
      from private.exam_prep_question_content_meta m
      where m.content_version_id=new.id and m.lifecycle_state in ('published','reserve')
    loop
      v_floor:=private.exam_prep_content_skill_floor_in_version_v1(new.id,v_skill);
      if coalesce((v_floor->>'ready')::boolean,false) is not true then
        raise exception 'exam_prep_content_publish_floor_not_met skill=% detail=%',v_skill,v_floor::text;
      end if;
    end loop;
    return new;
  end if;

  -- P1-03 written-only path. This is intentionally narrow: no ordinary learning
  -- content version may bypass question governance merely by adding a written task.
  select count(*) into v_written
  from private.exam_prep_written_tasks wt
  where wt.content_version_id=new.id;
  if v_written<1 then
    raise exception 'exam_prep_content_publish_empty_version';
  end if;

  if exists(
    select 1 from private.exam_prep_written_tasks wt
    where wt.content_version_id=new.id and (
      wt.component_code<>new.component_code
      or wt.lifecycle_state<>'published'
      or wt.copyright_status<>'pass'
      or wt.qa_math_status<>'pass'
      or wt.qa_language_status<>'pass'
      or wt.qa_technical_status<>'pass'
      or coalesce((wt.rubric_json->>'max_marks')::int,0)<=0
    )
  ) then
    raise exception 'exam_prep_written_only_publish_task_floor_not_met';
  end if;

  select count(*) into v_assessments
  from private.exam_prep_assessments a
  where a.content_version_id=new.id
    and a.component_code=new.component_code
    and a.assessment_type in ('timed','paper')
    and a.status in ('approved','published');
  if v_assessments<1 then
    raise exception 'exam_prep_written_only_publish_requires_timed_or_paper_assessment';
  end if;

  -- Every written task must be attached to at least one assessment item in this
  -- same version; unattached content cannot make a version publishable.
  if exists(
    select 1
    from private.exam_prep_written_tasks wt
    where wt.content_version_id=new.id
      and not exists(
        select 1
        from private.exam_prep_assessments a
        join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
        where a.content_version_id=new.id
          and a.assessment_type in ('timed','paper')
          and a.status in ('approved','published')
          and ai.written_task_id=wt.id
          and ai.question_id is null
          and ai.reserve_role='written'
          and ai.primary_skill_code=wt.primary_skill_code
      )
  ) then
    raise exception 'exam_prep_written_only_publish_unattached_task';
  end if;

  -- Conversely, the version's timed/paper assessments may not smuggle an objective
  -- question around question-meta governance in the written-only branch.
  if exists(
    select 1
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    left join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
    where a.content_version_id=new.id
      and a.assessment_type in ('timed','paper')
      and a.status in ('approved','published')
      and (
        ai.question_id is not null
        or ai.written_task_id is null
        or ai.reserve_role<>'written'
        or wt.id is null
        or wt.content_version_id<>new.id
        or wt.component_code<>new.component_code
      )
  ) then
    raise exception 'exam_prep_written_only_publish_assessment_role_mismatch';
  end if;

  return new;
end;
$$;

-- This governance hardening itself must not move release/runtime state.
do $$
declare
  v_cfg private.exam_prep_feature_config%rowtype;
  v_active int;
begin
  select * into v_cfg from private.exam_prep_feature_config where program_key='math_as_p1_p5';
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-03 written-only publish guard requires fail-closed feature state';
  end if;
  select count(*) into v_active from private.exam_prep_feature_entitlements where entitlement_status='active';
  if v_active<>0 then raise exception 'P1-03 written-only publish guard found active entitlements=%',v_active; end if;
end $$;

commit;
