-- P0-08 final QA/publication gate for the governed P5 Representation beta slice.
-- IMPORTANT: publication here is private Exam Prep governance state only.
-- The 21 new public.questions rows remain DRAFT + INACTIVE so they cannot leak into legacy Practice/Tours.
-- P0-09 will deliver/evaluate them only through membership-bound safe server APIs.

begin;

do $$
declare
  v_cv bigint;
  v_rows int;
  v_bad int;
  v_rules int;
  v_written int;
  v_assessments int;
  v_items int;
begin
  select id into v_cv
  from private.exam_prep_content_versions
  where content_version='p5_repr_beta_v1'
    and component_code='P5'
    and status='draft';
  if v_cv is null then
    raise exception 'P0-08 gate: expected draft content version p5_repr_beta_v1';
  end if;

  select count(*) into v_rows
  from private.exam_prep_question_content_meta
  where content_version_id=v_cv;
  if v_rows <> 21 then
    raise exception 'P0-08 gate: expected 21 governed question rows, got %',v_rows;
  end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and primary_skill_code='P5-DAT-01') <> 7
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and primary_skill_code='P5-DAT-04') <> 7
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and primary_skill_code='P5-DAT-06') <> 7 then
    raise exception 'P0-08 gate: expected 7 governed rows for each opened P5 skill';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and reserve_role='diagnostic') <> 3
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and reserve_role='learning') <> 9
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and reserve_role='retest') <> 6
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and reserve_role='mixed') <> 3 then
    raise exception 'P0-08 gate: reserve-role floor is not 3 diagnostic / 9 learning / 6 retest / 3 mixed';
  end if;

  -- New P5 rows must still be isolated from legacy delivery and must not have changed since seed.
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id=v_cv
    and (
      q.subject_id<>5
      or q.is_active is true
      or q.quality_status is distinct from 'draft'
      or nullif(trim(q.question_text_en),'') is null
      or nullif(trim(q.question_text_ru),'') is null
      or nullif(trim(q.question_text_uz),'') is null
      or nullif(trim(q.explanation_en),'') is null
      or nullif(trim(q.explanation_ru),'') is null
      or nullif(trim(q.explanation_uz),'') is null
      or md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
         coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),
         coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),
         coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
         coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
         coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
         coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,''))) <> m.question_snapshot_md5
    );
  if v_bad <> 0 then
    raise exception 'P0-08 gate: % new P5 rows failed isolation/snapshot/i18n preconditions',v_bad;
  end if;

  -- Exact diagnostic contract: three intentional wrong-option rules per diagnostic, never matching the correct key.
  select count(*) into v_rules
  from private.exam_prep_diagnostic_rules r
  join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
  join public.questions q on q.id=m.question_id
  where m.content_version_id=v_cv
    and m.reserve_role='diagnostic'
    and r.status='approved'
    and r.answer_kind='mcq_option'
    and r.answer_match<>q.correct_answer
    and nullif(trim(r.feedback_en),'') is not null
    and nullif(trim(r.feedback_ru),'') is not null
    and nullif(trim(r.feedback_uz),'') is not null
    and nullif(trim(r.next_action_en),'') is not null
    and nullif(trim(r.next_action_ru),'') is not null
    and nullif(trim(r.next_action_uz),'') is not null;
  if v_rules <> 9 then
    raise exception 'P0-08 gate: expected 9 approved intentional diagnostic rules, got %',v_rules;
  end if;
  if exists (
    select 1
    from private.exam_prep_question_content_meta m
    left join private.exam_prep_diagnostic_rules r on r.content_meta_id=m.id and r.status='approved'
    where m.content_version_id=v_cv and m.reserve_role='diagnostic'
    group by m.id
    having count(r.id)<>3
  ) then
    raise exception 'P0-08 gate: every diagnostic item must have exactly three approved distractor rules';
  end if;

  -- One governed written task per opened skill, already independently QA-approved.
  select count(*) into v_written
  from private.exam_prep_written_tasks
  where content_version_id=v_cv
    and component_code='P5'
    and primary_skill_code in ('P5-DAT-01','P5-DAT-04','P5-DAT-06')
    and lifecycle_state='approved'
    and copyright_status='pass'
    and qa_math_status='pass'
    and qa_language_status='pass'
    and qa_technical_status='pass'
    and jsonb_typeof(rubric_json)='object'
    and coalesce((rubric_json->>'max_marks')::int,0)>0;
  if v_written <> 3 then
    raise exception 'P0-08 gate: expected 3 approved written tasks, got %',v_written;
  end if;
  if (select count(distinct primary_skill_code) from private.exam_prep_written_tasks where content_version_id=v_cv and lifecycle_state='approved') <> 3 then
    raise exception 'P0-08 gate: written tasks do not cover all three opened P5 skills';
  end if;

  -- Versioned assessment topology: 8 approved sets / 24 exact memberships.
  select count(*) into v_assessments
  from private.exam_prep_assessments
  where content_version_id=v_cv and component_code='P5' and status='approved';
  if v_assessments <> 8 then
    raise exception 'P0-08 gate: expected 8 approved assessment definitions, got %',v_assessments;
  end if;

  select count(*) into v_items
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  where a.content_version_id=v_cv;
  if v_items <> 24 then
    raise exception 'P0-08 gate: expected 24 assessment memberships, got %',v_items;
  end if;

  -- Diagnostic and mixed sets are strict holdouts; each skill has one additional held retest.
  if exists (
    select 1 from private.exam_prep_assessment_items ai
    join private.exam_prep_assessments a on a.id=ai.assessment_id
    where a.content_version_id=v_cv
      and a.assessment_type in ('diagnostic','mixed')
      and ai.is_holdout is not true
  ) then
    raise exception 'P0-08 gate: diagnostic/mixed memberships must be holdouts';
  end if;
  if (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=v_cv and a.assessment_type='retest' and ai.is_holdout) <> 3 then
    raise exception 'P0-08 gate: expected one isolated retest holdout per opened skill';
  end if;

  -- Global learner rollout must still be fail-closed while P0-09 APIs do not exist.
  if not exists (
    select 1 from private.exam_prep_feature_config c
    where c.program_key='math_as_p1_p5'
      and c.rollout_state='off'
      and c.core_enabled is false
      and c.ai_enabled is false
      and c.mentor_enabled is false
      and c.kill_switch is true
  ) then
    raise exception 'P0-08 gate: Exam Prep global OFF/kill-switch invariant is not satisfied';
  end if;
end $$;

-- First explicit academic approval transition. This is separate from publication/exposure.
update private.exam_prep_question_content_meta m
set copyright_status='pass',
    qa_scope_status='pass',
    qa_math_status='pass',
    qa_language_status='pass',
    qa_technical_status='pass',
    diagnostic_rule_status=case when reserve_role='diagnostic' then 'approved' else 'not_applicable' end,
    lifecycle_state='approved',
    approved_at=coalesce(approved_at,now()),
    updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version='p5_repr_beta_v1';

update private.exam_prep_content_versions
set status='approved',approved_at=coalesce(approved_at,now())
where content_version='p5_repr_beta_v1' and component_code='P5' and status='draft';

-- Explicit publication/reserve transition. Exposure remains role-aware and private.
update private.exam_prep_question_content_meta m
set lifecycle_state=case when reserve_role='learning' then 'published' else 'reserve' end,
    exposure_state=case when reserve_role='learning' then 'released' else 'withheld' end,
    published_at=case when reserve_role='learning' then coalesce(published_at,now()) else published_at end,
    updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version='p5_repr_beta_v1';

update private.exam_prep_written_tasks wt
set lifecycle_state='published'
from private.exam_prep_content_versions cv
where cv.id=wt.content_version_id
  and cv.content_version='p5_repr_beta_v1'
  and wt.lifecycle_state='approved';

update private.exam_prep_assessments a
set status='published'
from private.exam_prep_content_versions cv
where cv.id=a.content_version_id
  and cv.content_version='p5_repr_beta_v1'
  and a.status='approved';

update private.exam_prep_content_versions
set status='published',published_at=coalesce(published_at,now())
where content_version='p5_repr_beta_v1' and component_code='P5' and status='approved';

-- Final fail-closed assertions: governance may be published, legacy delivery must still see none of the 21 rows.
do $$
declare v_cv bigint; v_bad int;
begin
  select id into v_cv from private.exam_prep_content_versions where content_version='p5_repr_beta_v1' and component_code='P5' and status='published';
  if v_cv is null then raise exception 'P0-08 final: content version was not published'; end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and lifecycle_state='published' and exposure_state='released' and reserve_role='learning') <> 9 then
    raise exception 'P0-08 final: expected 9 published learning items';
  end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and lifecycle_state='reserve' and exposure_state='withheld' and reserve_role in ('diagnostic','retest','mixed')) <> 12 then
    raise exception 'P0-08 final: expected 12 withheld reserve items';
  end if;
  if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_cv and lifecycle_state='published') <> 3 then
    raise exception 'P0-08 final: expected 3 published governed written tasks';
  end if;
  if (select count(*) from private.exam_prep_assessments where content_version_id=v_cv and status='published') <> 8 then
    raise exception 'P0-08 final: expected 8 published assessment definitions';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=v_cv and (q.is_active is true or q.quality_status is distinct from 'draft');
  if v_bad<>0 then
    raise exception 'P0-08 final: % P5 question rows escaped legacy isolation',v_bad;
  end if;
end $$;

commit;
