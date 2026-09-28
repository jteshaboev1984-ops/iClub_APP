-- Supplemental-learning publication guard v1.
-- Extends the existing content-version publication gate without weakening the
-- original full-floor or written-only branches.
--
-- A supplemental learning version may publish only when:
--   * it is explicitly registered in the private release-profile table;
--   * every skill already has a fully governed published baseline elsewhere;
--   * this version contains only QA-passed/released learning questions;
--   * each skill has exactly 3 machine learning items + 1 governed written task;
--   * exactly one published learning assessment per skill contains those 4 items;
--   * optional written-understanding companions, when required by the profile,
--     are published, QA-passed and exactly one per written task.
--
-- This migration does NOT register or publish any content version.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare
  v_def text;
begin
  v_def:=pg_get_functiondef('private.exam_prep_content_version_publish_guard_v1()'::regprocedure);
  if position('exam_prep_content_skill_floor_in_version_v1' in v_def)=0
     or position('exam_prep_written_only_publish_task_floor_not_met' in v_def)=0
     or position('exam_prep_written_only_publish_requires_timed_or_paper_assessment' in v_def)=0
     or position('exam_prep_supplemental_learning_floor_v1' in v_def)>0
  then
    raise exception 'supplemental-learning guard: existing full-floor/written-only guard drift; refuse replacement';
  end if;
  if to_regclass('private.exam_prep_content_release_profiles_v1') is not null then
    raise exception 'supplemental-learning guard: release profile table already exists';
  end if;
end
$preflight$;

create table private.exam_prep_content_release_profiles_v1 (
  content_version_id bigint primary key
    references private.exam_prep_content_versions(id) on delete restrict,
  release_mode text not null
    check (release_mode in ('supplemental_learning')),
  profile_version text not null
    check (length(btrim(profile_version)) between 2 and 80),
  require_written_understanding boolean not null default false,
  governance_basis text not null
    check (length(btrim(governance_basis))>=20),
  created_at timestamptz not null default now()
);

revoke all on private.exam_prep_content_release_profiles_v1 from public,anon,authenticated;
alter table private.exam_prep_content_release_profiles_v1 enable row level security;
alter table private.exam_prep_content_release_profiles_v1 force row level security;

create or replace function private.exam_prep_supplemental_learning_floor_v1(
  p_content_version_id bigint
)
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $fn$
declare
  v_cv private.exam_prep_content_versions%rowtype;
  v_profile private.exam_prep_content_release_profiles_v1%rowtype;
  v_skill_count int:=0;
  v_question_count int:=0;
  v_written_count int:=0;
  v_assessment_count int:=0;
  v_check_count int:=0;
  v_bad_questions int:=0;
  v_bad_skill_shape int:=0;
  v_bad_written int:=0;
  v_bad_assessments int:=0;
  v_bad_baseline int:=0;
  v_bad_checks int:=0;
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
     or v_profile.release_mode<>'supplemental_learning'
  then
    return jsonb_build_object('ready',false,'reason','supplemental_profile_missing');
  end if;

  select count(*),count(distinct m.primary_skill_code)
    into v_question_count,v_skill_count
  from private.exam_prep_question_content_meta m
  where m.content_version_id=v_cv.id;

  if v_question_count<1 or v_skill_count<1 then
    return jsonb_build_object(
      'ready',false,'reason','empty_supplemental_learning_version',
      'question_count',v_question_count,'skill_count',v_skill_count
    );
  end if;

  select count(*) into v_bad_questions
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id=v_cv.id
    and (
      m.reserve_role<>'learning'
      or m.lifecycle_state<>'published'
      or m.exposure_state<>'released'
      or m.copyright_status<>'pass'
      or m.qa_scope_status<>'pass'
      or m.qa_math_status<>'pass'
      or m.qa_language_status<>'pass'
      or m.qa_technical_status<>'pass'
      or m.diagnostic_rule_status<>'not_applicable'
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
      or (q.qtype='mcq' and (
          q.correct_answer not in ('A','B','C','D')
          or jsonb_typeof(q.options_text_en::jsonb)<>'array'
          or jsonb_typeof(q.options_text_ru::jsonb)<>'array'
          or jsonb_typeof(q.options_text_uz::jsonb)<>'array'
          or jsonb_array_length(q.options_text_en::jsonb)<>4
          or jsonb_array_length(q.options_text_ru::jsonb)<>4
          or jsonb_array_length(q.options_text_uz::jsonb)<>4
      ))
      or (q.qtype='input' and nullif(btrim(q.correct_answer),'') is null)
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

  select count(*) into v_bad_skill_shape
  from (
    select m.primary_skill_code,
           count(*) as machine_n
    from private.exam_prep_question_content_meta m
    where m.content_version_id=v_cv.id
    group by m.primary_skill_code
    having count(*)<>3
  ) x;

  select count(*) into v_written_count
  from private.exam_prep_written_tasks wt
  where wt.content_version_id=v_cv.id;

  select count(*) into v_bad_written
  from (
    select s.skill_code
    from (
      select distinct m.primary_skill_code as skill_code
      from private.exam_prep_question_content_meta m
      where m.content_version_id=v_cv.id
    ) s
    left join private.exam_prep_written_tasks wt
      on wt.content_version_id=v_cv.id
     and wt.component_code=v_cv.component_code
     and wt.primary_skill_code=s.skill_code
     and wt.lifecycle_state='published'
     and wt.copyright_status='pass'
     and wt.qa_math_status='pass'
     and wt.qa_language_status='pass'
     and wt.qa_technical_status='pass'
     and jsonb_typeof(wt.rubric_json)='object'
     and coalesce(nullif(wt.rubric_json->>'max_marks','')::int,0)>0
    group by s.skill_code
    having count(wt.id)<>1
  ) x;

  if exists(
    select 1
    from private.exam_prep_written_tasks wt
    where wt.content_version_id=v_cv.id
      and (
        wt.component_code<>v_cv.component_code
        or wt.lifecycle_state<>'published'
        or wt.copyright_status<>'pass'
        or wt.qa_math_status<>'pass'
        or wt.qa_language_status<>'pass'
        or wt.qa_technical_status<>'pass'
        or jsonb_typeof(wt.rubric_json)<>'object'
        or coalesce(nullif(wt.rubric_json->>'max_marks','')::int,0)<=0
      )
  ) then
    v_bad_written:=v_bad_written+1;
  end if;

  select count(*) into v_assessment_count
  from private.exam_prep_assessments a
  where a.content_version_id=v_cv.id;

  select count(*) into v_bad_assessments
  from (
    select a.id,
           a.component_code,
           a.assessment_type,
           a.status,
           count(*) filter(where ai.question_id is not null) as machine_n,
           count(*) filter(where ai.written_task_id is not null) as written_n,
           count(distinct ai.primary_skill_code) as skill_n,
           count(*) filter(where ai.is_holdout) as holdout_n,
           count(*) filter(where ai.question_id is not null and ai.reserve_role<>'learning') as bad_machine_role,
           count(*) filter(where ai.written_task_id is not null and ai.reserve_role<>'written') as bad_written_role,
           count(*) filter(where ai.question_id is not null and not exists(
             select 1 from private.exam_prep_question_content_meta m
             where m.question_id=ai.question_id
               and m.content_version_id=v_cv.id
               and m.primary_skill_code=ai.primary_skill_code
               and m.reserve_role='learning'
               and m.lifecycle_state='published'
               and m.exposure_state='released'
           )) as bad_question_link,
           count(*) filter(where ai.written_task_id is not null and not exists(
             select 1 from private.exam_prep_written_tasks wt
             where wt.id=ai.written_task_id
               and wt.content_version_id=v_cv.id
               and wt.primary_skill_code=ai.primary_skill_code
               and wt.lifecycle_state='published'
           )) as bad_written_link
    from private.exam_prep_assessments a
    left join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id=v_cv.id
    group by a.id,a.component_code,a.assessment_type,a.status
  ) x
  where x.component_code<>v_cv.component_code
     or x.assessment_type<>'learning'
     or x.status<>'published'
     or x.machine_n<>3
     or x.written_n<>1
     or x.skill_n<>1
     or x.holdout_n<>0
     or x.bad_machine_role<>0
     or x.bad_written_role<>0
     or x.bad_question_link<>0
     or x.bad_written_link<>0;

  if v_assessment_count<>v_skill_count then
    v_bad_assessments:=v_bad_assessments+1;
  end if;

  select count(*) into v_bad_baseline
  from (
    select distinct m.primary_skill_code as skill_code
    from private.exam_prep_question_content_meta m
    where m.content_version_id=v_cv.id
  ) s
  where not private.exam_prep_skill_content_ready_v1(
    v_cv.program_version_id,v_cv.component_code,s.skill_code
  );

  if v_profile.require_written_understanding then
    select count(*) into v_check_count
    from private.exam_prep_written_understanding_checks c
    join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
    where wt.content_version_id=v_cv.id
      and c.lifecycle_state='published';

    select count(*) into v_bad_checks
    from (
      select wt.id
      from private.exam_prep_written_tasks wt
      left join private.exam_prep_written_understanding_checks c
        on c.written_task_id=wt.id
       and c.lifecycle_state='published'
       and c.qa_math_status='pass'
       and c.qa_language_status='pass'
       and c.qa_technical_status='pass'
       and c.check_kind='mcq'
       and jsonb_typeof(c.options_en)='array'
       and jsonb_typeof(c.options_ru)='array'
       and jsonb_typeof(c.options_uz)='array'
       and jsonb_array_length(c.options_en)=jsonb_array_length(c.options_ru)
       and jsonb_array_length(c.options_en)=jsonb_array_length(c.options_uz)
       and c.correct_index>=0
       and c.correct_index<jsonb_array_length(c.options_en)
      where wt.content_version_id=v_cv.id
      group by wt.id
      having count(c.id)<>1
    ) x;
  else
    v_check_count:=0;
    v_bad_checks:=0;
  end if;

  v_ready :=
       v_skill_count>=1
   and v_question_count=3*v_skill_count
   and v_written_count=v_skill_count
   and v_assessment_count=v_skill_count
   and v_bad_questions=0
   and v_bad_skill_shape=0
   and v_bad_written=0
   and v_bad_assessments=0
   and v_bad_baseline=0
   and v_bad_checks=0;

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
      'written_tasks',v_written_count,
      'assessments',v_assessment_count,
      'written_understanding_checks',v_check_count
    ),
    'failures',jsonb_build_object(
      'question_rows',v_bad_questions,
      'skill_shape',v_bad_skill_shape,
      'written',v_bad_written,
      'assessments',v_bad_assessments,
      'baseline',v_bad_baseline,
      'understanding_checks',v_bad_checks
    )
  );
end
$fn$;

revoke all on function private.exam_prep_supplemental_learning_floor_v1(bigint)
from public,anon,authenticated;

create or replace function private.exam_prep_content_version_publish_guard_v1()
returns trigger
language plpgsql
security definer
set search_path to ''
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

  -- Explicit supplemental-learning path. This never establishes first coverage:
  -- every skill must already be globally ready from a separate full-floor version.
  if v_release_mode='supplemental_learning' then
    v_floor:=private.exam_prep_supplemental_learning_floor_v1(new.id);
    if coalesce((v_floor->>'ready')::boolean,false) is not true then
      raise exception 'exam_prep_supplemental_learning_publish_floor_not_met detail=%',v_floor::text;
    end if;
    return new;
  end if;

  -- Original P1-02 path: preserve the governed per-skill full question floor.
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

  -- P1-03 written-only path remains unchanged.
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
begin
  if (select count(*) from private.exam_prep_content_release_profiles_v1)<>0 then
    raise exception 'supplemental-learning guard: migration must not register content';
  end if;

  v_def:=pg_get_functiondef('private.exam_prep_content_version_publish_guard_v1()'::regprocedure);
  if position('exam_prep_supplemental_learning_floor_v1' in v_def)=0
     or position('exam_prep_content_skill_floor_in_version_v1' in v_def)=0
     or position('exam_prep_written_only_publish_task_floor_not_met' in v_def)=0
  then
    raise exception 'supplemental-learning guard: existing publication branches not preserved';
  end if;

  if has_table_privilege('anon','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_function_privilege('anon','private.exam_prep_supplemental_learning_floor_v1(bigint)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_supplemental_learning_floor_v1(bigint)','EXECUTE')
  then
    raise exception 'supplemental-learning guard: browser privilege widened';
  end if;
end
$postcheck$;

commit;
