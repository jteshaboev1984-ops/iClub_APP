-- Read-only contract for the published AW1-4 supplemental learning packs.
begin;

do $$
declare
  v_bad int;
  v_dist jsonb;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4801,4802)
        and status='published')<>2 then
    raise exception 'aw01_04_alt_release: content versions not published';
  end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4801,4802)
        and release_mode='supplemental_learning'
        and require_written_understanding)<>2 then
    raise exception 'aw01_04_alt_release: release profiles missing';
  end if;

  if coalesce((private.exam_prep_supplemental_learning_floor_v1(4801)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4802)->>'ready')::boolean,false) is not true
  then
    raise exception 'aw01_04_alt_release: supplemental floor RED';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4801,4802)
        and lifecycle_state='published'
        and exposure_state='released'
        and reserve_role='learning'
        and copyright_status='pass'
        and qa_scope_status='pass'
        and qa_math_status='pass'
        and qa_language_status='pass'
        and qa_technical_status='pass')<>27 then
    raise exception 'aw01_04_alt_release: question metadata state mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4801,4802)
    and (
      q.is_active
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
  if v_bad<>0 then
    raise exception 'aw01_04_alt_release: source isolation/snapshot mismatch=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_written_tasks
      where content_version_id in (4801,4802)
        and lifecycle_state='published'
        and copyright_status='pass'
        and qa_math_status='pass'
        and qa_language_status='pass'
        and qa_technical_status='pass')<>9 then
    raise exception 'aw01_04_alt_release: written task state mismatch';
  end if;

  if (select count(*) from private.exam_prep_written_understanding_checks c
      join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
      where wt.content_version_id in (4801,4802)
        and c.lifecycle_state='published'
        and c.qa_math_status='pass'
        and c.qa_language_status='pass'
        and c.qa_technical_status='pass')<>9 then
    raise exception 'aw01_04_alt_release: understanding-check state mismatch';
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4801,4802)
        and assessment_type='learning'
        and status='published')<>9 then
    raise exception 'aw01_04_alt_release: assessment state mismatch';
  end if;

  select count(*) into v_bad
  from (
    select a.id,
           a.component_code,
           count(*) filter(where ai.question_id is not null) qn,
           count(*) filter(where ai.written_task_id is not null) wn,
           count(distinct ai.primary_skill_code) skill_n,
           count(*) filter(where ai.is_holdout) holdout_n,
           count(*) filter(where ai.question_id is not null and ai.reserve_role<>'learning') bad_q_role,
           count(*) filter(where ai.written_task_id is not null and ai.reserve_role<>'written') bad_w_role
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id in (4801,4802)
    group by a.id,a.component_code
  ) x
  where x.qn<>3 or x.wn<>1 or x.skill_n<>1 or x.holdout_n<>0
     or x.bad_q_role<>0 or x.bad_w_role<>0;
  if v_bad<>0 then
    raise exception 'aw01_04_alt_release: learning assessment shape mismatch=%',v_bad;
  end if;

  -- No alternate item may leak across P1/P5 component boundaries.
  select count(*) into v_bad
  from private.exam_prep_assessments a
  join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
  where a.content_version_id in (4801,4802)
    and ai.primary_skill_code not like a.component_code||'-%';
  if v_bad<>0 then
    raise exception 'aw01_04_alt_release: P1/P5 leakage=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_written_understanding_checks
      where lifecycle_state='published')<>61
     or (select count(distinct written_task_id)
         from private.exam_prep_written_understanding_checks
         where lifecycle_state='published')<>58 then
    raise exception 'aw01_04_alt_release: governed written-understanding cardinality drift';
  end if;

  select jsonb_object_agg(correct_index,n order by correct_index) into v_dist
  from (
    select correct_index,count(*)::int n
    from private.exam_prep_written_understanding_checks
    where lifecycle_state='published'
    group by correct_index
  ) d;
  if v_dist<>jsonb_build_object('0',15,'1',15,'2',15,'3',16) then
    raise exception 'aw01_04_alt_release: written-understanding option distribution drift=%',v_dist;
  end if;

  if exists(
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
    raise exception 'aw01_04_alt_release: legacy Practice/Tour history contamination';
  end if;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1
      and rollout_state='controlled_beta'
      and core_enabled
      and ai_enabled=false
      and mentor_enabled=false
      and kill_switch=false
  ) then
    raise exception 'aw01_04_alt_release: Core-only controlled-beta boundary changed';
  end if;
end $$;

-- Rollback rehearsal in the disposable transaction: retiring only the supplemental
-- versions/assessments must remove them from ordinary selection without deleting
-- any content/evidence rows.
do $$
declare
  v_before_q int;
  v_before_w int;
begin
  select count(*) into v_before_q
  from private.exam_prep_question_content_meta
  where content_version_id in (4801,4802);
  select count(*) into v_before_w
  from private.exam_prep_written_tasks
  where content_version_id in (4801,4802);

  update private.exam_prep_assessments
  set status='retired'
  where content_version_id in (4801,4802)
    and status='published';

  update private.exam_prep_content_versions
  set status='retired'
  where id in (4801,4802)
    and status='published';

  if exists(
    select 1
    from private.exam_prep_assessments a
    join private.exam_prep_content_versions cv on cv.id=a.content_version_id
    where a.content_version_id in (4801,4802)
      and a.assessment_type='learning'
      and a.status='published'
      and cv.status='published'
  ) then
    raise exception 'aw01_04_alt_release: rollback rehearsal left selectable supplemental pack';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4801,4802))<>v_before_q
     or (select count(*) from private.exam_prep_written_tasks
         where content_version_id in (4801,4802))<>v_before_w
  then
    raise exception 'aw01_04_alt_release: rollback rehearsal deleted governed content';
  end if;
end $$;

rollback;

select 'AW01_04_ALT_LEARNING_RELEASE_GREEN' as result;
