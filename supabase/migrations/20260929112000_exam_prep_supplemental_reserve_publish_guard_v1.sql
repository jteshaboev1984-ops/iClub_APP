-- Supplemental-reserve publication guard v1.
--
-- Adds an explicit publication path for reserve-only annual top-up versions.
-- This does NOT register or publish any content version.
--
-- A supplemental reserve version may publish only when:
--   * it is explicitly registered with release_mode='supplemental_reserve';
--   * every included skill already has a separate fully governed published baseline;
--   * the candidate contains exactly +2 diagnostic, +2 retest and +1 mixed item per skill;
--   * every candidate item is QA/copyright passed, lifecycle=reserve, exposure=withheld;
--   * every diagnostic has exactly three approved misconception rules;
--   * diagnostic/retest/mixed assessments are published, holdout-only and shape-safe;
--   * no written tasks are duplicated in the reserve-only version;
--   * prospective cross-version annual depth reaches >=3 diagnostic,
--     >=8 learning/transfer, >=4 retest and >=2 published written tasks per skill;
--   * at least 20% of retest/mixed/unseen-capable content remains withheld;
--   * public source questions stay inactive/draft with exact frozen snapshots.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare
  v_def text;
  v_constraint text;
begin
  if to_regclass('private.exam_prep_content_release_profiles_v1') is null
     or to_regprocedure('private.exam_prep_supplemental_learning_floor_v1(bigint)') is null
  then
    raise exception 'supplemental-reserve guard: supplemental-learning architecture missing';
  end if;

  if to_regprocedure('private.exam_prep_supplemental_reserve_floor_v1(bigint)') is not null then
    raise exception 'supplemental-reserve guard: reserve floor already exists';
  end if;

  select pg_get_constraintdef(c.oid) into v_constraint
  from pg_constraint c
  where c.conrelid='private.exam_prep_content_release_profiles_v1'::regclass
    and c.conname='exam_prep_content_release_profiles_v1_release_mode_check';

  if v_constraint is null
     or position('supplemental_learning' in v_constraint)=0
     or position('supplemental_reserve' in v_constraint)>0
  then
    raise exception 'supplemental-reserve guard: release-mode constraint drift=%',coalesce(v_constraint,'missing');
  end if;

  v_def:=pg_get_functiondef('private.exam_prep_content_version_publish_guard_v1()'::regprocedure);
  if position('exam_prep_supplemental_learning_floor_v1' in v_def)=0
     or position('exam_prep_content_skill_floor_in_version_v1' in v_def)=0
     or position('exam_prep_written_only_publish_task_floor_not_met' in v_def)=0
     or position('exam_prep_supplemental_reserve_floor_v1' in v_def)>0
  then
    raise exception 'supplemental-reserve guard: current publication guard drift';
  end if;

  if exists(
    select 1 from private.exam_prep_content_release_profiles_v1
    where release_mode<>'supplemental_learning'
  ) then
    raise exception 'supplemental-reserve guard: unexpected existing release mode';
  end if;
end
$preflight$;

alter table private.exam_prep_content_release_profiles_v1
  drop constraint exam_prep_content_release_profiles_v1_release_mode_check;

alter table private.exam_prep_content_release_profiles_v1
  add constraint exam_prep_content_release_profiles_v1_release_mode_check
  check (release_mode in ('supplemental_learning','supplemental_reserve'));

create or replace function private.exam_prep_supplemental_reserve_floor_v1(
  p_content_version_id bigint
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $fn$
declare
  v_cv private.exam_prep_content_versions%rowtype;
  v_profile private.exam_prep_content_release_profiles_v1%rowtype;
  v_skill_count int:=0;
  v_question_count int:=0;
  v_assessment_count int:=0;
  v_bad_questions int:=0;
  v_bad_skill_shape int:=0;
  v_bad_rules int:=0;
  v_bad_assessments int:=0;
  v_bad_baseline int:=0;
  v_bad_written int:=0;
  v_bad_annual int:=0;
  v_bad_holdout int:=0;
  v_ready boolean:=false;
begin
  select * into v_cv
  from private.exam_prep_content_versions
  where id=p_content_version_id;

  if v_cv.id is null then
    return jsonb_build_object('ready',false,'reason','content_version_not_found');
  end if;

  select * into v_profile
  from private.exam_prep_content_release_profiles_v1
  where content_version_id=v_cv.id;

  if v_profile.content_version_id is null
     or v_profile.release_mode<>'supplemental_reserve'
  then
    return jsonb_build_object('ready',false,'reason','supplemental_reserve_profile_missing');
  end if;

  if v_profile.require_written_understanding then
    return jsonb_build_object('ready',false,'reason','supplemental_reserve_must_not_require_new_written_understanding');
  end if;

  select count(*),count(distinct m.primary_skill_code)
    into v_question_count,v_skill_count
  from private.exam_prep_question_content_meta m
  where m.content_version_id=v_cv.id;

  if v_skill_count<1 or v_question_count<>5*v_skill_count then
    return jsonb_build_object(
      'ready',false,'reason','supplemental_reserve_question_shape_invalid',
      'question_count',v_question_count,'skill_count',v_skill_count
    );
  end if;

  -- Candidate rows are reserve evidence, never learner-released teaching items.
  select count(*) into v_bad_questions
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id=v_cv.id
    and (
      m.reserve_role not in ('diagnostic','retest','mixed')
      or m.lifecycle_state<>'reserve'
      or m.exposure_state<>'withheld'
      or m.copyright_status<>'pass'
      or m.qa_scope_status<>'pass'
      or m.qa_math_status<>'pass'
      or m.qa_language_status<>'pass'
      or m.qa_technical_status<>'pass'
      or (m.reserve_role='diagnostic' and m.diagnostic_rule_status<>'approved')
      or (m.reserve_role<>'diagnostic' and m.diagnostic_rule_status<>'not_applicable')
      or not exists(
        select 1
        from private.exam_prep_syllabus_nodes n
        where n.program_version_id=v_cv.program_version_id
          and n.component_code=v_cv.component_code
          and n.skill_code=m.primary_skill_code
      )
      or q.subject_id<>5
      or q.is_active
      or q.quality_status is distinct from 'draft'
      or q.qtype not in ('mcq','input')
      or nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
      or nullif(btrim(m.originality_attestation),'') is null
      or nullif(btrim(m.provenance_note),'') is null
      or nullif(btrim(m.official_scope_ref),'') is null
      or nullif(btrim(m.coursebook_mapping_ref),'') is null
      or (q.qtype='mcq' and (
        q.correct_answer not in ('A','B','C','D')
        or jsonb_typeof(q.options_text_en::jsonb)<>'array'
        or jsonb_typeof(q.options_text_ru::jsonb)<>'array'
        or jsonb_typeof(q.options_text_uz::jsonb)<>'array'
        or jsonb_array_length(q.options_text_en::jsonb)<>4
        or jsonb_array_length(q.options_text_ru::jsonb)<>4
        or jsonb_array_length(q.options_text_uz::jsonb)<>4
      ))
      or (q.qtype='input' and (
        nullif(btrim(q.correct_answer),'') is null
        or q.options_text_en::jsonb<>'[]'::jsonb
        or q.options_text_ru::jsonb<>'[]'::jsonb
        or q.options_text_uz::jsonb<>'[]'::jsonb
      ))
      or md5(concat_ws(chr(31),
        q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
        coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
        coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
        coalesce(q.image_url,''),coalesce(q.is_active::text,''),
        coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
        coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
        coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
        coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
        coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5
    );

  -- Exact per-skill top-up shape: +2 diagnostic, +2 delayed retest, +1 mixed.
  select count(*) into v_bad_skill_shape
  from (
    select m.primary_skill_code,
      count(*) filter(where m.reserve_role='diagnostic') as d,
      count(*) filter(where m.reserve_role='retest') as r,
      count(*) filter(where m.reserve_role='mixed') as x
    from private.exam_prep_question_content_meta m
    where m.content_version_id=v_cv.id
    group by m.primary_skill_code
    having count(*) filter(where m.reserve_role='diagnostic')<>2
        or count(*) filter(where m.reserve_role='retest')<>2
        or count(*) filter(where m.reserve_role='mixed')<>1
        or count(*)<>5
  ) s;

  -- Diagnostics are MCQ-only here and carry exactly three approved wrong-option
  -- misconception rules each.
  select count(*) into v_bad_rules
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id=v_cv.id
    and m.reserve_role='diagnostic'
    and (
      q.qtype<>'mcq'
      or (
        select count(*)
        from private.exam_prep_diagnostic_rules r
        where r.content_meta_id=m.id
          and r.rule_version='aw_reserve_v1'
          and r.status='approved'
          and r.answer_kind='mcq_option'
          and r.answer_match<>q.correct_answer
          and nullif(btrim(r.feedback_en),'') is not null
          and nullif(btrim(r.feedback_ru),'') is not null
          and nullif(btrim(r.feedback_uz),'') is not null
          and nullif(btrim(r.next_action_en),'') is not null
          and nullif(btrim(r.next_action_ru),'') is not null
          and nullif(btrim(r.next_action_uz),'') is not null
      )<>3
    );

  if exists(
    select 1 from private.exam_prep_written_tasks
    where content_version_id=v_cv.id
  ) then
    v_bad_written:=v_bad_written+1;
  end if;

  select count(*) into v_assessment_count
  from private.exam_prep_assessments a
  where a.content_version_id=v_cv.id;

  -- All candidate assessments are published and contain only matching holdout
  -- machine items from the same reserve-only version.
  select count(*) into v_bad_assessments
  from private.exam_prep_assessments a
  where a.content_version_id=v_cv.id
    and (
      a.component_code<>v_cv.component_code
      or a.assessment_type not in ('diagnostic','retest','mixed')
      or a.status<>'published'
      or exists(
        select 1
        from private.exam_prep_assessment_items ai
        left join private.exam_prep_question_content_meta m
          on m.question_id=ai.question_id
         and m.content_version_id=v_cv.id
        where ai.assessment_id=a.id
          and (
            ai.question_id is null
            or ai.written_task_id is not null
            or not ai.is_holdout
            or ai.reserve_role<>a.assessment_type
            or ai.primary_skill_code not like v_cv.component_code||'-%'
            or m.id is null
            or m.primary_skill_code<>ai.primary_skill_code
            or m.reserve_role<>ai.reserve_role
            or m.lifecycle_state<>'reserve'
            or m.exposure_state<>'withheld'
          )
      )
    );

  if v_assessment_count<>(3+2*v_skill_count) then
    v_bad_assessments:=v_bad_assessments+1;
  end if;

  -- Exactly two diagnostic variants: each one item per candidate skill.
  if (
    select count(*)
    from private.exam_prep_assessments a
    where a.content_version_id=v_cv.id and a.assessment_type='diagnostic' and a.status='published'
  )<>2
  or exists(
    select 1
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id=v_cv.id and a.assessment_type='diagnostic'
    group by a.id
    having count(*)<>v_skill_count
        or count(distinct ai.primary_skill_code)<>v_skill_count
  ) then
    v_bad_assessments:=v_bad_assessments+1;
  end if;

  -- Exactly two isolated retest assessments per skill, one item each.
  if (
    select count(*)
    from private.exam_prep_assessments a
    where a.content_version_id=v_cv.id and a.assessment_type='retest' and a.status='published'
  )<>2*v_skill_count
  or exists(
    select 1
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id=v_cv.id and a.assessment_type='retest'
    group by a.id
    having count(*)<>1 or count(distinct ai.primary_skill_code)<>1
  )
  or exists(
    select 1
    from (
      select ai.primary_skill_code,count(*) n
      from private.exam_prep_assessments a
      join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
      where a.content_version_id=v_cv.id and a.assessment_type='retest'
      group by ai.primary_skill_code
      having count(*)<>2
    ) x
  ) then
    v_bad_assessments:=v_bad_assessments+1;
  end if;

  -- Exactly one same-component mixed set, one candidate item per skill.
  if (
    select count(*)
    from private.exam_prep_assessments a
    where a.content_version_id=v_cv.id and a.assessment_type='mixed' and a.status='published'
  )<>1
  or exists(
    select 1
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id=v_cv.id and a.assessment_type='mixed'
    group by a.id
    having count(*)<>v_skill_count
        or count(distinct ai.primary_skill_code)<>v_skill_count
  ) then
    v_bad_assessments:=v_bad_assessments+1;
  end if;

  -- The top-up may deepen only already governed skills.
  select count(*) into v_bad_baseline
  from (
    select distinct m.primary_skill_code as skill_code
    from private.exam_prep_question_content_meta m
    where m.content_version_id=v_cv.id
  ) s
  where not private.exam_prep_skill_content_ready_v1(
    v_cv.program_version_id,v_cv.component_code,s.skill_code
  );

  -- Cross-version annual target after including this candidate.
  with skills as (
    select distinct m.primary_skill_code skill_code
    from private.exam_prep_question_content_meta m
    where m.content_version_id=v_cv.id
  ), q as (
    select m.primary_skill_code skill_code,
      count(*) filter(where m.reserve_role='diagnostic') d,
      count(*) filter(where m.reserve_role='learning') l,
      count(*) filter(where m.reserve_role='retest') r,
      count(*) filter(where m.reserve_role='mixed') x
    from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    join skills s on s.skill_code=m.primary_skill_code
    where cv.program_version_id=v_cv.program_version_id
      and cv.component_code=v_cv.component_code
      and (
        (cv.status='published' and m.lifecycle_state in ('published','reserve'))
        or (cv.id=v_cv.id and m.lifecycle_state='reserve')
      )
    group by m.primary_skill_code
  ), w as (
    select wt.primary_skill_code skill_code,count(*) n
    from private.exam_prep_written_tasks wt
    join private.exam_prep_content_versions cv on cv.id=wt.content_version_id
    join skills s on s.skill_code=wt.primary_skill_code
    where cv.program_version_id=v_cv.program_version_id
      and cv.component_code=v_cv.component_code
      and cv.status='published'
      and wt.lifecycle_state='published'
      and wt.copyright_status='pass'
      and wt.qa_math_status='pass'
      and wt.qa_language_status='pass'
      and wt.qa_technical_status='pass'
    group by wt.primary_skill_code
  )
  select count(*) into v_bad_annual
  from skills s
  left join q using(skill_code)
  left join w using(skill_code)
  where coalesce(q.d,0)<3
     or coalesce(q.l,0)+coalesce(q.x,0)<8
     or coalesce(q.r,0)<4
     or coalesce(w.n,0)<2;

  -- Annual holdout remains at or above the governed 20% minimum.
  with skills as (
    select distinct m.primary_skill_code skill_code
    from private.exam_prep_question_content_meta m
    where m.content_version_id=v_cv.id
  ), h as (
    select m.primary_skill_code skill_code,
      count(*) filter(where m.reserve_role in ('retest','mixed','unseen')) eligible,
      count(*) filter(where m.reserve_role in ('retest','mixed','unseen')
                        and m.lifecycle_state='reserve'
                        and m.exposure_state='withheld') withheld
    from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    join skills s on s.skill_code=m.primary_skill_code
    where cv.program_version_id=v_cv.program_version_id
      and cv.component_code=v_cv.component_code
      and (
        (cv.status='published' and m.lifecycle_state in ('published','reserve'))
        or (cv.id=v_cv.id and m.lifecycle_state='reserve')
      )
    group by m.primary_skill_code
  )
  select count(*) into v_bad_holdout
  from h
  where eligible<1 or (100.0*withheld/eligible)<20.0;

  v_ready :=
       v_skill_count>=1
   and v_question_count=5*v_skill_count
   and v_bad_questions=0
   and v_bad_skill_shape=0
   and v_bad_rules=0
   and v_bad_assessments=0
   and v_bad_baseline=0
   and v_bad_written=0
   and v_bad_annual=0
   and v_bad_holdout=0;

  return jsonb_build_object(
    'ready',v_ready,
    'release_mode',v_profile.release_mode,
    'profile_version',v_profile.profile_version,
    'content_version_id',v_cv.id,
    'content_version',v_cv.content_version,
    'component_code',v_cv.component_code,
    'counts',jsonb_build_object(
      'skills',v_skill_count,
      'questions',v_question_count,
      'assessments',v_assessment_count
    ),
    'annual_target',jsonb_build_object(
      'diagnostic_min',3,
      'learning_transfer_min',8,
      'retest_min',4,
      'written_min',2,
      'holdout_min_pct',20
    ),
    'failures',jsonb_build_object(
      'question_rows',v_bad_questions,
      'skill_shape',v_bad_skill_shape,
      'diagnostic_rules',v_bad_rules,
      'assessments',v_bad_assessments,
      'baseline',v_bad_baseline,
      'written',v_bad_written,
      'annual_target',v_bad_annual,
      'holdout',v_bad_holdout
    )
  );
end
$fn$;

revoke all on function private.exam_prep_supplemental_reserve_floor_v1(bigint)
from public,anon,authenticated;
grant execute on function private.exam_prep_supplemental_reserve_floor_v1(bigint)
to service_role;

create or replace function private.exam_prep_content_version_publish_guard_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $guard$
declare
  v_skill text;
  v_floor jsonb;
  v_n int;
  v_written int;
  v_assessments int;
  v_release_mode text;
begin
  if new.status<>'published' or old.status is not distinct from new.status then
    return new;
  end if;

  select p.release_mode into v_release_mode
  from private.exam_prep_content_release_profiles_v1 p
  where p.content_version_id=new.id;

  select count(distinct m.primary_skill_code) into v_n
  from private.exam_prep_question_content_meta m
  where m.content_version_id=new.id
    and m.lifecycle_state in ('published','reserve');

  -- Existing supplemental-learning path remains unchanged.
  if v_release_mode='supplemental_learning' then
    v_floor:=private.exam_prep_supplemental_learning_floor_v1(new.id);
    if coalesce((v_floor->>'ready')::boolean,false) is not true then
      raise exception 'exam_prep_supplemental_learning_publish_floor_not_met detail=%',v_floor::text;
    end if;
    return new;
  end if;

  -- New reserve-only annual-depth path. It cannot establish first coverage and
  -- cannot release teaching content.
  if v_release_mode='supplemental_reserve' then
    v_floor:=private.exam_prep_supplemental_reserve_floor_v1(new.id);
    if coalesce((v_floor->>'ready')::boolean,false) is not true then
      raise exception 'exam_prep_supplemental_reserve_publish_floor_not_met detail=%',v_floor::text;
    end if;
    return new;
  end if;

  -- Original full-floor path remains unchanged.
  if v_n>=1 then
    for v_skill in
      select distinct m.primary_skill_code
      from private.exam_prep_question_content_meta m
      where m.content_version_id=new.id
        and m.lifecycle_state in ('published','reserve')
    loop
      v_floor:=private.exam_prep_content_skill_floor_in_version_v1(new.id,v_skill);
      if coalesce((v_floor->>'ready')::boolean,false) is not true then
        raise exception 'exam_prep_content_publish_floor_not_met skill=% detail=%',v_skill,v_floor::text;
      end if;
    end loop;
    return new;
  end if;

  -- Existing written-only path remains unchanged.
  if v_release_mode is not null then
    raise exception 'exam_prep_content_release_profile_without_question_content';
  end if;

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
end
$guard$;

revoke all on function private.exam_prep_content_version_publish_guard_v1()
from public,anon,authenticated;

do $postcheck$
declare
  v_def text;
  v_constraint text;
begin
  select pg_get_constraintdef(c.oid) into v_constraint
  from pg_constraint c
  where c.conrelid='private.exam_prep_content_release_profiles_v1'::regclass
    and c.conname='exam_prep_content_release_profiles_v1_release_mode_check';

  if position('supplemental_learning' in coalesce(v_constraint,''))=0
     or position('supplemental_reserve' in coalesce(v_constraint,''))=0
  then
    raise exception 'supplemental-reserve guard: release-mode constraint not expanded';
  end if;

  if exists(
    select 1 from private.exam_prep_content_release_profiles_v1
    where release_mode='supplemental_reserve'
  ) then
    raise exception 'supplemental-reserve guard: architecture migration must not register reserve content';
  end if;

  if exists(
    select 1
    from private.exam_prep_content_release_profiles_v1 p
    where p.release_mode='supplemental_learning'
      and coalesce((private.exam_prep_supplemental_learning_floor_v1(p.content_version_id)->>'ready')::boolean,false) is not true
  ) then
    raise exception 'supplemental-reserve guard: existing supplemental-learning floor regressed';
  end if;

  v_def:=pg_get_functiondef('private.exam_prep_content_version_publish_guard_v1()'::regprocedure);
  if position('exam_prep_supplemental_learning_floor_v1' in v_def)=0
     or position('exam_prep_supplemental_reserve_floor_v1' in v_def)=0
     or position('exam_prep_content_skill_floor_in_version_v1' in v_def)=0
     or position('exam_prep_written_only_publish_task_floor_not_met' in v_def)=0
  then
    raise exception 'supplemental-reserve guard: publication branches not preserved';
  end if;

  if has_table_privilege('anon','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_function_privilege('anon','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
     or not has_function_privilege('service_role','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
  then
    raise exception 'supplemental-reserve guard: private ACL widened or service ACL missing';
  end if;
end
$postcheck$;

commit;
