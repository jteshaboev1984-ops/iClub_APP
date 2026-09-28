-- Correct source mappings for the withheld AW1-4 alternate learning drafts.
-- SAFE DRAFT-ONLY METADATA FIX:
--   * no learner-visible content is published;
--   * no question stem/answer/explanation is changed;
--   * no historical learner evidence is rewritten;
--   * migration aborts if any target draft has acquired learner history or exposure.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare
  v_bad int;
begin
  if (select count(*)
      from private.exam_prep_content_versions
      where id in (4801,4802)
        and content_version in (
          'p1_aw01_04_alt_learning_draft_v1',
          'p5_aw01_04_alt_learning_draft_v1'
        )
        and status='draft')<>2
  then
    raise exception 'aw01_04_source_map_fix: target content versions are not exact withheld drafts';
  end if;

  if exists(
    select 1
    from private.exam_prep_assessments
    where content_version_id in (4801,4802)
      and status<>'draft'
  ) then
    raise exception 'aw01_04_source_map_fix: non-draft assessment detected';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4801,4802)
    and (
      m.lifecycle_state<>'draft'
      or m.exposure_state<>'withheld'
      or m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or q.is_active
      or q.quality_status<>'draft'
    );
  if v_bad<>0 then
    raise exception 'aw01_04_source_map_fix: target question rows no longer safely withheld/pending=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4801,4802)
  ) then
    raise exception 'aw01_04_source_map_fix: learner session exists on target draft';
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
    raise exception 'aw01_04_source_map_fix: legacy answer history exists on target draft';
  end if;
end
$preflight$;

-- Non-semantic provenance/source-mapping corrections on unexposed draft metadata only.
update private.exam_prep_question_content_meta
set coursebook_mapping_ref='Complete Pure Mathematics 1, Ch2 Functions and transformations, pp.24-42 (mapping only)'
where content_version_id=4801
  and primary_skill_code in ('P1-FUN-01','P1-FUN-02')
  and lifecycle_state='draft'
  and exposure_state='withheld';

update private.exam_prep_question_content_meta
set coursebook_mapping_ref='Complete Probability & Statistics 1, Ch2-3, pp.14-59 (mapping only)'
where content_version_id=4802
  and primary_skill_code='P5-DAT-01'
  and lifecycle_state='draft'
  and exposure_state='withheld';

update private.exam_prep_question_content_meta
set coursebook_mapping_ref='Complete Probability & Statistics 1, Ch3 Representation of data, pp.34-59 (mapping only)'
where content_version_id=4802
  and primary_skill_code in ('P5-DAT-02','P5-DAT-04')
  and lifecycle_state='draft'
  and exposure_state='withheld';

update private.exam_prep_question_content_meta
set coursebook_mapping_ref='Complete Probability & Statistics 1, Ch2 Measures of location and spread, pp.14-29 (mapping only)'
where content_version_id=4802
  and primary_skill_code='P5-DAT-06'
  and lifecycle_state='draft'
  and exposure_state='withheld';

do $postcheck$
declare
  v_bad int;
begin
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  where m.content_version_id in (4801,4802)
    and (
      (m.content_version_id=4801 and m.primary_skill_code in ('P1-FUN-01','P1-FUN-02')
       and m.coursebook_mapping_ref<>'Complete Pure Mathematics 1, Ch2 Functions and transformations, pp.24-42 (mapping only)')
      or
      (m.content_version_id=4802 and m.primary_skill_code='P5-DAT-01'
       and m.coursebook_mapping_ref<>'Complete Probability & Statistics 1, Ch2-3, pp.14-59 (mapping only)')
      or
      (m.content_version_id=4802 and m.primary_skill_code in ('P5-DAT-02','P5-DAT-04')
       and m.coursebook_mapping_ref<>'Complete Probability & Statistics 1, Ch3 Representation of data, pp.34-59 (mapping only)')
      or
      (m.content_version_id=4802 and m.primary_skill_code='P5-DAT-06'
       and m.coursebook_mapping_ref<>'Complete Probability & Statistics 1, Ch2 Measures of location and spread, pp.14-29 (mapping only)')
    );
  if v_bad<>0 then
    raise exception 'aw01_04_source_map_fix: canonical source mapping postcheck failed=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4801 and primary_skill_code in ('P1-FUN-01','P1-FUN-02'))<>6
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id=4802 and primary_skill_code='P5-DAT-01')<>3
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id=4802 and primary_skill_code in ('P5-DAT-02','P5-DAT-04'))<>6
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id=4802 and primary_skill_code='P5-DAT-06')<>3
  then
    raise exception 'aw01_04_source_map_fix: target cardinality changed unexpectedly';
  end if;

  if exists(
    select 1
    from private.exam_prep_assessments
    where content_version_id in (4801,4802)
      and status='published'
  ) or exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    where m.content_version_id in (4801,4802)
      and (m.lifecycle_state<>'draft' or m.exposure_state<>'withheld' or q.is_active)
  ) then
    raise exception 'aw01_04_source_map_fix: draft exposure/lifecycle changed';
  end if;
end
$postcheck$;

commit;
