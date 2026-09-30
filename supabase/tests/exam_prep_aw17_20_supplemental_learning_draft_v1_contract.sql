-- AW17-20 supplemental learning source/release contract v1.
-- The reviewed draft payload is now governed/published through the supplemental-learning release path;
-- public source questions remain inactive/draft.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4817,4818) and status='published')<>2 then
    raise exception 'aw17_20 supplemental source: expected two published content versions';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4817 and lifecycle_state='published' and reserve_role='learning' and exposure_state='released')<>18
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id=4818 and lifecycle_state='published' and reserve_role='learning' and exposure_state='released')<>15
  then raise exception 'aw17_20 supplemental source: machine-content cardinality/state mismatch'; end if;

  if (select count(*) from private.exam_prep_written_tasks
      where content_version_id=4817 and lifecycle_state='published')<>6
     or (select count(*) from private.exam_prep_written_tasks
         where content_version_id=4818 and lifecycle_state='published')<>5
     or (select count(*) from private.exam_prep_written_understanding_checks
         where id between 8953 and 8963 and lifecycle_state='published')<>11
  then raise exception 'aw17_20 supplemental source: written/check cardinality mismatch'; end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id=4817 and assessment_type='learning' and status='published')<>6
     or (select count(*) from private.exam_prep_assessments
         where content_version_id=4818 and assessment_type='learning' and status='published')<>5
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4817,4818))<>44
  then raise exception 'aw17_20 supplemental source: assessment shape mismatch'; end if;

  select count(*) into v_bad
  from (
    select a.id
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id in (4817,4818)
    group by a.id
    having count(*) filter(where ai.question_id is not null and ai.reserve_role='learning' and not ai.is_holdout)<>3
        or count(*) filter(where ai.written_task_id is not null and ai.reserve_role='written' and not ai.is_holdout)<>1
        or count(*)<>4
  ) x;
  if v_bad<>0 then raise exception 'aw17_20 supplemental source: per-assessment 3+1 shape mismatch rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4817,4818)
    and (
      m.copyright_status<>'pass' or m.qa_scope_status<>'pass' or m.qa_math_status<>'pass'
      or m.qa_language_status<>'pass' or m.qa_technical_status<>'pass'
      or m.diagnostic_rule_status<>'not_applicable'
      or m.lifecycle_state<>'published' or m.exposure_state<>'released'
      or q.is_active or q.quality_status<>'draft'
      or nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
      or (q.qtype='mcq' and (
        q.correct_answer not in ('A','B','C','D')
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
    );
  if v_bad<>0 then raise exception 'aw17_20 supplemental source: trilingual/type/options QA rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4817,4818)
    and md5(concat_ws(chr(31),
      q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
      coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
      coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
      coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5;
  if v_bad<>0 then raise exception 'aw17_20 supplemental source: frozen snapshot mismatch rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_assessments
    where content_version_id in (4817,4818)
      and (
        lower(coalesce(title_en,'')) like '%supplemental%'
        or lower(coalesce(title_en,'')) like '%draft%'
        or lower(coalesce(title_ru,'')) like '%дополнительн%'
        or lower(coalesce(title_ru,'')) like '%чернов%'
        or lower(coalesce(title_uz,'')) like '%qo‘shimcha%'
      )
  ) then raise exception 'aw17_20 supplemental source: internal release wording remains in learner titles'; end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4817,4818)
        and release_mode='supplemental_learning'
        and profile_version='aw17_20_alt_release_v1'
        and require_written_understanding)<>2
  then raise exception 'aw17_20 supplemental source: release profile mismatch'; end if;

  if coalesce((private.exam_prep_supplemental_learning_floor_v1(4817)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4818)->>'ready')::boolean,false) is not true
  then raise exception 'aw17_20 supplemental source: governed supplemental floor is RED'; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4817;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(3,3,3,3,6) then
    raise exception 'aw17_20 supplemental source: P1 answer balance mismatch';
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4818;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(2,2,3,3,5) then
    raise exception 'aw17_20 supplemental source: P5 answer balance mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_tasks wt
  left join private.exam_prep_written_understanding_checks c on c.written_task_id=wt.id
  where wt.content_version_id in (4817,4818)
    and (
      wt.lifecycle_state<>'published'
      or wt.copyright_status<>'pass' or wt.qa_math_status<>'pass'
      or wt.qa_language_status<>'pass' or wt.qa_technical_status<>'pass'
      or coalesce((wt.rubric_json->>'max_marks')::int,0)<>6
      or c.id is null or c.lifecycle_state<>'published'
      or c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass'
      or jsonb_array_length(c.options_en)<>4 or jsonb_array_length(c.options_ru)<>4 or jsonb_array_length(c.options_uz)<>4
      or c.correct_index not between 0 and 3
    );
  if v_bad<>0 then raise exception 'aw17_20 supplemental source: written/check QA rows=%',v_bad; end if;

  if (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=0)<>2
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=1)<>2
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=2)<>4
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=3)<>3
  then raise exception 'aw17_20 supplemental source: written-check balance mismatch'; end if;

  if exists(
    select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4817,4818)
  ) or exists(
    select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4817,4818)
  ) or exists(
    select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4817,4818)
  ) then raise exception 'aw17_20 supplemental source: history contamination'; end if;
END
$$;

\echo 'AW17-20 supplemental learning source/release v1 contract: GREEN'
