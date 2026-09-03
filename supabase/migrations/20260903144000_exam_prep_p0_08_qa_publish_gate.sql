-- P0-08 final QA/publication gate for the governed P5 Representation beta slice.
-- Publication is private Exam Prep governance state only.
-- All 21 new public.questions rows remain DRAFT + INACTIVE to isolate legacy Practice/Tours.

begin;

do $$
declare
  v_cv bigint;
  v_bad int;
  v_n int;
begin
  select id into v_cv
  from private.exam_prep_content_versions
  where content_version='p5_repr_beta_v1' and component_code='P5' and status='draft';
  if v_cv is null then raise exception 'P0-08: draft content version missing'; end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv) <> 21 then
    raise exception 'P0-08: expected 21 governed question rows';
  end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and primary_skill_code='P5-DAT-01') <> 7
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and primary_skill_code='P5-DAT-04') <> 7
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and primary_skill_code='P5-DAT-06') <> 7 then
    raise exception 'P0-08: expected 7 rows per opened P5 skill';
  end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and reserve_role='diagnostic') <> 3
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and reserve_role='learning') <> 9
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and reserve_role='retest') <> 6
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and reserve_role='mixed') <> 3 then
    raise exception 'P0-08: reserve floor mismatch';
  end if;

  -- No semantic/state drift and no legacy exposure.
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id=v_cv and (
    q.subject_id<>5 or q.is_active or q.quality_status is distinct from 'draft'
    or nullif(trim(q.question_text_en),'') is null or nullif(trim(q.question_text_ru),'') is null or nullif(trim(q.question_text_uz),'') is null
    or nullif(trim(q.explanation_en),'') is null or nullif(trim(q.explanation_ru),'') is null or nullif(trim(q.explanation_uz),'') is null
    or md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),
      coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,''))) <> m.question_snapshot_md5
  );
  if v_bad<>0 then raise exception 'P0-08: % question rows failed isolation/snapshot/i18n gate',v_bad; end if;

  -- Exactly 9 intentional private diagnostic rules, 3 per diagnostic and never on the correct option.
  select count(*) into v_n
  from private.exam_prep_diagnostic_rules r
  join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
  join public.questions q on q.id=m.question_id
  where m.content_version_id=v_cv and m.reserve_role='diagnostic' and r.status='approved'
    and r.answer_kind='mcq_option' and r.answer_match<>q.correct_answer
    and nullif(trim(r.feedback_en),'') is not null and nullif(trim(r.feedback_ru),'') is not null and nullif(trim(r.feedback_uz),'') is not null
    and nullif(trim(r.next_action_en),'') is not null and nullif(trim(r.next_action_ru),'') is not null and nullif(trim(r.next_action_uz),'') is not null;
  if v_n<>9 then raise exception 'P0-08: expected 9 approved diagnostic rules, got %',v_n; end if;
  if exists (
    select 1 from private.exam_prep_question_content_meta m
    left join private.exam_prep_diagnostic_rules r on r.content_meta_id=m.id and r.status='approved'
    where m.content_version_id=v_cv and m.reserve_role='diagnostic'
    group by m.id having count(r.id)<>3
  ) then raise exception 'P0-08: each diagnostic must have exactly 3 approved rules'; end if;

  -- One fully QA-approved written task per opened skill.
  select count(*) into v_n from private.exam_prep_written_tasks
  where content_version_id=v_cv and component_code='P5'
    and primary_skill_code in ('P5-DAT-01','P5-DAT-04','P5-DAT-06')
    and lifecycle_state='approved' and copyright_status='pass' and qa_math_status='pass' and qa_language_status='pass' and qa_technical_status='pass'
    and jsonb_typeof(rubric_json)='object' and coalesce((rubric_json->>'max_marks')::int,0)>0;
  if v_n<>3 then raise exception 'P0-08: expected 3 approved written tasks, got %',v_n; end if;
  if (select count(distinct primary_skill_code) from private.exam_prep_written_tasks where content_version_id=v_cv and lifecycle_state='approved')<>3 then
    raise exception 'P0-08: written tasks do not cover all 3 opened skills';
  end if;

  -- 8 versioned assessment sets and 24 exact memberships.
  if (select count(*) from private.exam_prep_assessments where content_version_id=v_cv and component_code='P5' and status='approved')<>8 then
    raise exception 'P0-08: expected 8 approved assessments';
  end if;
  if (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=v_cv)<>24 then
    raise exception 'P0-08: expected 24 assessment memberships';
  end if;
  if exists (
    select 1 from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id
    where a.content_version_id=v_cv and a.assessment_type in ('diagnostic','mixed') and not ai.is_holdout
  ) then raise exception 'P0-08: diagnostic/mixed must remain holdout'; end if;
  if (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=v_cv and a.assessment_type='retest' and ai.is_holdout)<>3 then
    raise exception 'P0-08: expected one held retest per opened skill';
  end if;

  -- Feature service remains globally fail-closed.
  if not exists (
    select 1 from private.exam_prep_feature_config c
    where c.program_key='math_as_p1_p5' and c.rollout_state='off'
      and not c.core_enabled and not c.ai_enabled and not c.mentor_enabled and c.kill_switch
  ) then raise exception 'P0-08: OFF/kill-switch invariant failed'; end if;
end $$;

-- Explicit academic approval first.
update private.exam_prep_question_content_meta m
set copyright_status='pass',qa_scope_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
    diagnostic_rule_status=case when m.reserve_role='diagnostic' then 'approved' else 'not_applicable' end,
    lifecycle_state='approved',approved_at=coalesce(m.approved_at,now()),updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version='p5_repr_beta_v1';

update private.exam_prep_content_versions cv
set status='approved',approved_at=coalesce(cv.approved_at,now())
where cv.content_version='p5_repr_beta_v1' and cv.component_code='P5' and cv.status='draft';

-- Then explicit publication vs reserve transition. Legacy questions are deliberately untouched.
update private.exam_prep_question_content_meta m
set lifecycle_state=case when m.reserve_role='learning' then 'published' else 'reserve' end,
    exposure_state=case when m.reserve_role='learning' then 'released' else 'withheld' end,
    published_at=case when m.reserve_role='learning' then coalesce(m.published_at,now()) else m.published_at end,
    updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version='p5_repr_beta_v1';

update private.exam_prep_written_tasks wt
set lifecycle_state='published'
from private.exam_prep_content_versions cv
where cv.id=wt.content_version_id and cv.content_version='p5_repr_beta_v1' and wt.lifecycle_state='approved';

update private.exam_prep_assessments a
set status='published'
from private.exam_prep_content_versions cv
where cv.id=a.content_version_id and cv.content_version='p5_repr_beta_v1' and a.status='approved';

update private.exam_prep_content_versions cv
set status='published',published_at=coalesce(cv.published_at,now())
where cv.content_version='p5_repr_beta_v1' and cv.component_code='P5' and cv.status='approved';

-- Final state must be published privately but still invisible to legacy delivery.
do $$
declare v_cv bigint; v_bad int;
begin
  select id into v_cv from private.exam_prep_content_versions where content_version='p5_repr_beta_v1' and component_code='P5' and status='published';
  if v_cv is null then raise exception 'P0-08 final: content version not published'; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and reserve_role='learning' and lifecycle_state='published' and exposure_state='released')<>9 then
    raise exception 'P0-08 final: expected 9 published learning items';
  end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_cv and reserve_role in ('diagnostic','retest','mixed') and lifecycle_state='reserve' and exposure_state='withheld')<>12 then
    raise exception 'P0-08 final: expected 12 withheld reserve items';
  end if;
  if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_cv and lifecycle_state='published')<>3 then raise exception 'P0-08 final: written task publication mismatch'; end if;
  if (select count(*) from private.exam_prep_assessments where content_version_id=v_cv and status='published')<>8 then raise exception 'P0-08 final: assessment publication mismatch'; end if;
  select count(*) into v_bad from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id where m.content_version_id=v_cv and (q.is_active or q.quality_status is distinct from 'draft');
  if v_bad<>0 then raise exception 'P0-08 final: % P5 rows escaped legacy isolation',v_bad; end if;
end $$;

commit;
