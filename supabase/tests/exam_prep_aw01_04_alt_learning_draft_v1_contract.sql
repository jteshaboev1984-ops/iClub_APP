-- Contract for AW1-4 alternate learning draft packs.
-- Draft rows must be complete, trilingual, unique, and impossible to select at runtime.
begin;
do $$
declare
  v_bad int;
begin
  if to_regclass('private.exam_prep_content_versions') is null then
    raise exception 'alt_learning_draft_v1 schema missing';
  end if;

  if (select count(*) from private.exam_prep_content_versions where id in (4801,4802) and status='draft')<>2 then
    raise exception 'alt_learning_draft_v1 content versions must stay draft';
  end if;

  if (select count(*) from private.exam_prep_assessments where content_version_id in (4801,4802) and status='draft')<>9
     or (select count(*) from private.exam_prep_written_tasks where content_version_id in (4801,4802) and lifecycle_state='draft')<>9
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4801,4802) and lifecycle_state='draft' and reserve_role='learning')<>27
  then
    raise exception 'alt_learning_draft_v1 cardinality mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4801,4802)
    and (
      nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
      or q.is_active
      or q.quality_status<>'draft'
      or m.exposure_state<>'withheld'
      or m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or m.diagnostic_rule_status<>'not_applicable'
    );
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 draft safety/trilingual rows invalid=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_tasks wt
  where wt.content_version_id in (4801,4802)
    and (
      nullif(btrim(wt.prompt_en),'') is null
      or nullif(btrim(wt.prompt_ru),'') is null
      or nullif(btrim(wt.prompt_uz),'') is null
      or nullif(btrim(wt.self_review_en),'') is null
      or nullif(btrim(wt.self_review_ru),'') is null
      or nullif(btrim(wt.self_review_uz),'') is null
      or coalesce((wt.rubric_json->>'max_marks')::int,0)<=0
      or jsonb_array_length(coalesce(wt.rubric_json->'criteria','[]'::jsonb))<2
      or wt.copyright_status<>'pending'
      or wt.qa_math_status<>'pending'
      or wt.qa_language_status<>'pending'
      or wt.qa_technical_status<>'pending'
    );
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 written draft rows invalid=%',v_bad;
  end if;

  -- No duplicate English stem inside the alternate draft.
  select count(*) into v_bad
  from (
    select lower(regexp_replace(btrim(q.question_text_en),'\s+',' ','g')) norm,count(*) n
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    where m.content_version_id in (4801,4802)
    group by 1
    having count(*)>1
  ) d;
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 duplicate draft stems=%',v_bad;
  end if;

  -- Alternate draft must not exactly duplicate a published learning stem.
  select count(*) into v_bad
  from private.exam_prep_question_content_meta d
  join public.questions dq on dq.id=d.question_id
  join public.questions pq
    on pq.id<>dq.id
   and lower(regexp_replace(btrim(pq.question_text_en),'\s+',' ','g'))
       =lower(regexp_replace(btrim(dq.question_text_en),'\s+',' ','g'))
  join private.exam_prep_question_content_meta pm on pm.question_id=pq.id
  join private.exam_prep_content_versions pcv on pcv.id=pm.content_version_id and pcv.status='published'
  where d.content_version_id in (4801,4802)
    and pm.reserve_role='learning';
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 exact published stem duplicates=%',v_bad;
  end if;

  -- Every assessment is exactly 3 machine + 1 written and single-skill.
  select count(*) into v_bad
  from (
    select a.id,
      count(*) filter(where ai.question_id is not null) machine_n,
      count(*) filter(where ai.written_task_id is not null) written_n,
      count(distinct ai.primary_skill_code) skills_n,
      count(*) filter(where ai.is_holdout) holdout_n,
      count(*) filter(where ai.question_id is not null and ai.reserve_role<>'learning') wrong_machine_role,
      count(*) filter(where ai.written_task_id is not null and ai.reserve_role<>'written') wrong_written_role
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id in (4801,4802)
    group by a.id
  ) x
  where machine_n<>3 or written_n<>1 or skills_n<>1 or holdout_n<>0 or wrong_machine_role<>0 or wrong_written_role<>0;
  if v_bad<>0 then
    raise exception 'alt_learning_draft_v1 assessment shape invalid=%',v_bad;
  end if;

  -- Runtime selector requires published content version + published assessment, so these drafts must be invisible.
  if exists(
    select 1
    from private.exam_prep_assessments a
    join private.exam_prep_content_versions cv on cv.id=a.content_version_id
    where cv.id in (4801,4802)
      and (a.status='published' or cv.status='published')
  ) then
    raise exception 'alt_learning_draft_v1 accidentally learner-visible';
  end if;
end $$;
rollback;
