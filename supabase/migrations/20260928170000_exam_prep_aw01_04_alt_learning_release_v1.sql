-- Publish the independently QA-reviewed AW1-4 alternate learning packs.
-- Scope: exactly 9 already-opened canonical skills, learning role only.
-- Safety: no legacy Practice/Tour mutation, no mastery/readiness write, no feature/
-- entitlement change, no public.questions activation, no destructive SQL.
begin;
set local lock_timeout='3s';
set local statement_timeout='120s';

do $preflight$
declare
  v_program bigint;
  v_bad int;
  v_dist jsonb;
begin
  if to_regclass('private.exam_prep_content_release_profiles_v1') is null
     or to_regprocedure('private.exam_prep_supplemental_learning_floor_v1(bigint)') is null
  then
    raise exception 'aw01_04_alt_release: supplemental-learning publication guard missing';
  end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';
  if v_program is null then
    raise exception 'aw01_04_alt_release: active canonical program missing';
  end if;

  if (select count(*)
      from private.exam_prep_content_versions
      where id in (4801,4802)
        and program_version_id=v_program
        and content_version in (
          'p1_aw01_04_alt_learning_draft_v1',
          'p5_aw01_04_alt_learning_draft_v1'
        )
        and status='draft')<>2
  then
    raise exception 'aw01_04_alt_release: exact target content versions are not both draft';
  end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4801,4802))<>0
  then
    raise exception 'aw01_04_alt_release: target release profile already exists';
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4801,4802)
        and assessment_type='learning'
        and status='draft')<>9
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4801,4802))<>9
  then
    raise exception 'aw01_04_alt_release: assessment draft shape changed';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4801,4802)
    and (
      m.lifecycle_state<>'draft'
      or m.exposure_state<>'withheld'
      or m.reserve_role<>'learning'
      or m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or m.diagnostic_rule_status<>'not_applicable'
      or q.is_active
      or q.quality_status<>'draft'
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
  if v_bad<>0
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4801,4802))<>27
  then
    raise exception 'aw01_04_alt_release: target question draft/snapshot gate failed=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_tasks wt
  where wt.content_version_id in (4801,4802)
    and (
      wt.lifecycle_state<>'draft'
      or wt.copyright_status<>'pending'
      or wt.qa_math_status<>'pending'
      or wt.qa_language_status<>'pending'
      or wt.qa_technical_status<>'pending'
      or jsonb_typeof(wt.rubric_json)<>'object'
      or coalesce((wt.rubric_json->>'max_marks')::int,0)<=0
    );
  if v_bad<>0
     or (select count(*) from private.exam_prep_written_tasks
         where content_version_id in (4801,4802))<>9
  then
    raise exception 'aw01_04_alt_release: target written-task draft gate failed=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.content_version_id in (4801,4802)
    and (
      c.lifecycle_state<>'draft'
      or c.qa_math_status<>'pending'
      or c.qa_language_status<>'pending'
      or c.qa_technical_status<>'pending'
      or c.check_kind<>'mcq'
      or jsonb_typeof(c.options_en)<>'array'
      or jsonb_typeof(c.options_ru)<>'array'
      or jsonb_typeof(c.options_uz)<>'array'
      or jsonb_array_length(c.options_en)<>4
      or jsonb_array_length(c.options_en)<>jsonb_array_length(c.options_ru)
      or jsonb_array_length(c.options_en)<>jsonb_array_length(c.options_uz)
      or c.correct_index<0
      or c.correct_index>=jsonb_array_length(c.options_en)
    );
  if v_bad<>0
     or (select count(*) from private.exam_prep_written_understanding_checks c
         join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
         where wt.content_version_id in (4801,4802))<>9
  then
    raise exception 'aw01_04_alt_release: target understanding-check draft gate failed=%',v_bad;
  end if;

  -- Every target skill already has a separate fully governed baseline version.
  select count(*) into v_bad
  from (values
    ('P1','P1-QUA-01'),('P1','P1-QUA-02'),('P1','P1-QUA-03'),
    ('P1','P1-FUN-01'),('P1','P1-FUN-02'),
    ('P5','P5-DAT-01'),('P5','P5-DAT-02'),('P5','P5-DAT-04'),('P5','P5-DAT-06')
  ) s(component_code,skill_code)
  where not private.exam_prep_skill_content_ready_v1(v_program,s.component_code,s.skill_code);
  if v_bad<>0 then
    raise exception 'aw01_04_alt_release: % target skills lack existing full-floor baseline',v_bad;
  end if;

  -- There must still be no target learner exposure/history before publication.
  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4801,4802)
  ) or exists(
    select 1
    from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4801,4802)
  ) or exists(
    select 1
    from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4801,4802)
  ) then
    raise exception 'aw01_04_alt_release: target draft unexpectedly has learner/legacy history';
  end if;

  -- Pin the current written-companion surface before intentionally expanding it.
  if (select count(*) from private.exam_prep_written_understanding_checks
      where lifecycle_state='published')<>52
     or (select count(distinct written_task_id)
         from private.exam_prep_written_understanding_checks
         where lifecycle_state='published')<>49
  then
    raise exception 'aw01_04_alt_release: written-understanding baseline cardinality drift';
  end if;

  select jsonb_object_agg(correct_index,n order by correct_index) into v_dist
  from (
    select correct_index,count(*)::int n
    from private.exam_prep_written_understanding_checks
    where lifecycle_state='published'
    group by correct_index
  ) d;
  if v_dist<>jsonb_build_object('0',13,'1',13,'2',13,'3',13) then
    raise exception 'aw01_04_alt_release: written-understanding baseline balance drift=%',v_dist;
  end if;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1
      and rollout_state='controlled_beta'
      and core_enabled
      and not ai_enabled
      and not mentor_enabled
      and not kill_switch
  ) then
    raise exception 'aw01_04_alt_release: production capability boundary drift';
  end if;
end
$preflight$;

-- Explicitly register these two versions as supplemental learning. This profile
-- does not itself publish anything; the publish trigger consumes it at the final gate.
insert into private.exam_prep_content_release_profiles_v1(
  content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
)
values
  (4801,'supplemental_learning','supplemental_learning_v1',true,
   'Second AW1-4 P1 learning pack. Existing full-floor skills remain authoritative; this version adds governed learning variety only.'),
  (4802,'supplemental_learning','supplemental_learning_v1',true,
   'Second AW1-4 P5 learning pack. Existing full-floor skills remain authoritative; this version adds governed learning variety only.');

-- Record the actual review stages in the audit trail before approval.
update private.exam_prep_question_content_meta
set copyright_status='pass',
    qa_scope_status='pass',
    qa_math_status='pass',
    lifecycle_state='mathematical_review',
    updated_at=now()
where content_version_id in (4801,4802)
  and lifecycle_state='draft'
  and exposure_state='withheld';

update private.exam_prep_question_content_meta
set qa_language_status='pass',
    lifecycle_state='language_review',
    updated_at=now()
where content_version_id in (4801,4802)
  and lifecycle_state='mathematical_review';

update private.exam_prep_question_content_meta
set qa_technical_status='pass',
    lifecycle_state='technical_validation',
    updated_at=now()
where content_version_id in (4801,4802)
  and lifecycle_state='language_review';

update private.exam_prep_question_content_meta
set lifecycle_state='approved',
    approved_at=now(),
    updated_at=now()
where content_version_id in (4801,4802)
  and lifecycle_state='technical_validation';

update private.exam_prep_written_tasks
set copyright_status='pass',
    qa_math_status='pass',
    lifecycle_state='mathematical_review'
where content_version_id in (4801,4802)
  and lifecycle_state='draft';

update private.exam_prep_written_tasks
set qa_language_status='pass',
    lifecycle_state='language_review'
where content_version_id in (4801,4802)
  and lifecycle_state='mathematical_review';

update private.exam_prep_written_tasks
set qa_technical_status='pass',
    lifecycle_state='technical_validation'
where content_version_id in (4801,4802)
  and lifecycle_state='language_review';

update private.exam_prep_written_tasks
set lifecycle_state='approved',
    approved_at=now()
where content_version_id in (4801,4802)
  and lifecycle_state='technical_validation';

update private.exam_prep_written_understanding_checks c
set qa_math_status='pass',
    qa_language_status='pass',
    qa_technical_status='pass',
    lifecycle_state='approved',
    approved_at=now()
from private.exam_prep_written_tasks wt
where wt.id=c.written_task_id
  and wt.content_version_id in (4801,4802)
  and c.lifecycle_state='draft';

update private.exam_prep_assessments
set status='approved',
    approved_at=now()
where content_version_id in (4801,4802)
  and assessment_type='learning'
  and status='draft';

update private.exam_prep_content_versions
set status='approved',
    approved_at=now(),
    release_label=case
      when id=4801 then 'P1 AW1-4 alternate learning pack v1'
      when id=4802 then 'P5 AW1-4 alternate learning pack v1'
      else release_label
    end
where id in (4801,4802)
  and status='draft';

-- Publication: only governed Exam Prep membership is released. Source rows in
-- public.questions remain inactive/draft and therefore do not enter legacy banks.
update private.exam_prep_question_content_meta
set lifecycle_state='published',
    exposure_state='released',
    published_at=now(),
    updated_at=now()
where content_version_id in (4801,4802)
  and lifecycle_state='approved'
  and reserve_role='learning';

update private.exam_prep_written_tasks
set lifecycle_state='published'
where content_version_id in (4801,4802)
  and lifecycle_state='approved';

update private.exam_prep_written_understanding_checks c
set lifecycle_state='published'
from private.exam_prep_written_tasks wt
where wt.id=c.written_task_id
  and wt.content_version_id in (4801,4802)
  and wt.lifecycle_state='published'
  and c.lifecycle_state='approved';

update private.exam_prep_assessments
set status='published'
where content_version_id in (4801,4802)
  and assessment_type='learning'
  and status='approved';

-- Must be last: the publication trigger now validates the explicit supplemental
-- profile, pre-existing full-floor baseline, exact learning assessment shape,
-- QA, snapshots and required written-understanding companions.
update private.exam_prep_content_versions
set status='published',
    published_at=now()
where id in (4801,4802)
  and status='approved';

do $postcheck$
declare
  v_program bigint;
  v_bad int;
  v_dist jsonb;
  v_p1 jsonb;
  v_p5 jsonb;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';

  v_p1:=private.exam_prep_supplemental_learning_floor_v1(4801);
  v_p5:=private.exam_prep_supplemental_learning_floor_v1(4802);
  if coalesce((v_p1->>'ready')::boolean,false) is not true
     or coalesce((v_p5->>'ready')::boolean,false) is not true
  then
    raise exception 'aw01_04_alt_release: supplemental floor failed P1=% P5=%',v_p1,v_p5;
  end if;

  if (select count(*) from private.exam_prep_content_versions
      where id in (4801,4802) and status='published')<>2
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4801,4802)
           and assessment_type='learning' and status='published')<>9
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4801,4802)
           and lifecycle_state='published'
           and exposure_state='released'
           and reserve_role='learning')<>27
     or (select count(*) from private.exam_prep_written_tasks
         where content_version_id in (4801,4802)
           and lifecycle_state='published')<>9
     or (select count(*) from private.exam_prep_written_understanding_checks c
         join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
         where wt.content_version_id in (4801,4802)
           and c.lifecycle_state='published')<>9
  then
    raise exception 'aw01_04_alt_release: final publication cardinality mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4801,4802)
    and (
      q.is_active
      or q.quality_status<>'draft'
      or m.copyright_status<>'pass'
      or m.qa_scope_status<>'pass'
      or m.qa_math_status<>'pass'
      or m.qa_language_status<>'pass'
      or m.qa_technical_status<>'pass'
      or m.diagnostic_rule_status<>'not_applicable'
    );
  if v_bad<>0 then
    raise exception 'aw01_04_alt_release: source-row isolation/QA postcheck failed=%',v_bad;
  end if;

  -- Existing baseline authority remains true independently of the supplemental pack.
  select count(*) into v_bad
  from (values
    ('P1','P1-QUA-01'),('P1','P1-QUA-02'),('P1','P1-QUA-03'),
    ('P1','P1-FUN-01'),('P1','P1-FUN-02'),
    ('P5','P5-DAT-01'),('P5','P5-DAT-02'),('P5','P5-DAT-04'),('P5','P5-DAT-06')
  ) s(component_code,skill_code)
  where not private.exam_prep_skill_content_ready_v1(v_program,s.component_code,s.skill_code);
  if v_bad<>0 then
    raise exception 'aw01_04_alt_release: existing full-floor readiness regressed=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_written_understanding_checks
      where lifecycle_state='published')<>61
     or (select count(distinct written_task_id)
         from private.exam_prep_written_understanding_checks
         where lifecycle_state='published')<>58
  then
    raise exception 'aw01_04_alt_release: written-understanding final cardinality mismatch';
  end if;

  select jsonb_object_agg(correct_index,n order by correct_index) into v_dist
  from (
    select correct_index,count(*)::int n
    from private.exam_prep_written_understanding_checks
    where lifecycle_state='published'
    group by correct_index
  ) d;
  if v_dist<>jsonb_build_object('0',15,'1',15,'2',15,'3',16) then
    raise exception 'aw01_04_alt_release: written-understanding final balance mismatch=%',v_dist;
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4801,4802)
  ) or exists(
    select 1
    from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4801,4802)
  ) or exists(
    select 1
    from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4801,4802)
  ) then
    raise exception 'aw01_04_alt_release: unexpected target history appeared inside release transaction';
  end if;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1
      and rollout_state='controlled_beta'
      and core_enabled
      and not ai_enabled
      and not mentor_enabled
      and not kill_switch
  ) then
    raise exception 'aw01_04_alt_release: capability state changed during publication';
  end if;
end
$postcheck$;

commit;
