-- P1-02 QA + publication gate for the AW1-4 opening runway extension.
-- Publishes only private Exam Prep memberships. Every public.questions row stays DRAFT + INACTIVE.

begin;

-- Pre-publication structural, QA, reserve and isolation checks.
do $$
declare
  v_p1 bigint; v_p5 bigint; v_bad int; v_skill text;
begin
  select id into v_p1 from private.exam_prep_content_versions where content_version='p1_foundations_runway_v1' and component_code='P1' and status='draft';
  select id into v_p5 from private.exam_prep_content_versions where content_version='p5_dat02_runway_v1' and component_code='P5' and status='draft';
  if v_p1 is null or v_p5 is null then raise exception 'P1-02 QA: expected draft content versions missing'; end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_p1)<>35 then raise exception 'P1-02 QA: expected 35 P1 question objects'; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_p5)<>7 then raise exception 'P1-02 QA: expected 7 P5-DAT-02 question objects'; end if;

  foreach v_skill in array array['P1-QUA-01','P1-QUA-02','P1-QUA-03','P1-FUN-01','P1-FUN-02'] loop
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_p1 and primary_skill_code=v_skill and reserve_role='diagnostic')<>1 then raise exception 'P1-02 QA: % diagnostic floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_p1 and primary_skill_code=v_skill and reserve_role='learning')<>3 then raise exception 'P1-02 QA: % learning floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_p1 and primary_skill_code=v_skill and reserve_role='retest')<>2 then raise exception 'P1-02 QA: % retest floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_p1 and primary_skill_code=v_skill and reserve_role='mixed')<>1 then raise exception 'P1-02 QA: % mixed floor',v_skill; end if;
    if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_p1 and primary_skill_code=v_skill and lifecycle_state='approved')<>1 then raise exception 'P1-02 QA: % written floor',v_skill; end if;
  end loop;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_p5 and primary_skill_code='P5-DAT-02' and reserve_role='diagnostic')<>1 then raise exception 'P1-02 QA: DAT02 diagnostic floor'; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_p5 and primary_skill_code='P5-DAT-02' and reserve_role='learning')<>3 then raise exception 'P1-02 QA: DAT02 learning floor'; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_p5 and primary_skill_code='P5-DAT-02' and reserve_role='retest')<>2 then raise exception 'P1-02 QA: DAT02 retest floor'; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_p5 and primary_skill_code='P5-DAT-02' and reserve_role='mixed')<>1 then raise exception 'P1-02 QA: DAT02 mixed floor'; end if;
  if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_p5 and primary_skill_code='P5-DAT-02' and lifecycle_state='approved')<>1 then raise exception 'P1-02 QA: DAT02 written floor'; end if;

  -- Every new question remains fully isolated from legacy delivery and has complete trilingual payload + stable snapshot.
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id in (v_p1,v_p5) and (
    q.subject_id<>5 or q.is_active or q.quality_status is distinct from 'draft'
    or nullif(trim(q.question_text_en),'') is null or nullif(trim(q.question_text_ru),'') is null or nullif(trim(q.question_text_uz),'') is null
    or nullif(trim(q.options_text_en),'') is null or nullif(trim(q.options_text_ru),'') is null or nullif(trim(q.options_text_uz),'') is null
    or jsonb_typeof(q.options_text_en::jsonb)<>'array' or jsonb_array_length(q.options_text_en::jsonb)<>4
    or jsonb_typeof(q.options_text_ru::jsonb)<>'array' or jsonb_array_length(q.options_text_ru::jsonb)<>4
    or jsonb_typeof(q.options_text_uz::jsonb)<>'array' or jsonb_array_length(q.options_text_uz::jsonb)<>4
    or q.correct_answer not in ('A','B','C','D')
    or nullif(trim(q.explanation_en),'') is null or nullif(trim(q.explanation_ru),'') is null or nullif(trim(q.explanation_uz),'') is null
    or md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5
  );
  if v_bad<>0 then raise exception 'P1-02 QA: % question payload/isolation/snapshot failures',v_bad; end if;

  -- Exactly three intentional WRONG-option diagnostic rules per diagnostic item.
  select count(*) into v_bad from (
    select m.id
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    left join private.exam_prep_diagnostic_rules r on r.content_meta_id=m.id and r.status='approved' and r.answer_kind='mcq_option'
    where m.content_version_id in (v_p1,v_p5) and m.reserve_role='diagnostic'
    group by m.id,q.correct_answer
    having count(r.id)<>3 or count(r.id) filter(where r.answer_match=q.correct_answer)<>0
  ) x;
  if v_bad<>0 then raise exception 'P1-02 QA: diagnostic rule contract failed for % items',v_bad; end if;

  -- Assessment layout: learning is exactly 3 machine + 1 written; retest/mixed/diagnostic remain holdout.
  select count(*) into v_bad from private.exam_prep_assessments a
  where a.content_version_id in (v_p1,v_p5) and a.assessment_type='learning' and (
    (select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.question_id is not null and i.reserve_role='learning')<>3
    or (select count(*) from private.exam_prep_assessment_items i where i.assessment_id=a.id and i.written_task_id is not null and i.reserve_role='written')<>1
  );
  if v_bad<>0 then raise exception 'P1-02 QA: % learning assessments violate 3+written contract',v_bad; end if;
  select count(*) into v_bad from private.exam_prep_assessment_items i join private.exam_prep_assessments a on a.id=i.assessment_id
  where a.content_version_id in (v_p1,v_p5) and a.assessment_type in ('diagnostic','retest','mixed') and not i.is_holdout;
  if v_bad<>0 then raise exception 'P1-02 QA: % reserve assessment items are not holdout',v_bad; end if;

  -- Second retest item remains unassigned to any assessment for each new skill.
  select count(*) into v_bad from private.exam_prep_question_content_meta m
  where m.content_version_id in (v_p1,v_p5) and m.reserve_role='retest'
    and not exists(select 1 from private.exam_prep_assessment_items i where i.question_id=m.question_id);
  if v_bad<>6 then raise exception 'P1-02 QA: expected 6 isolated second-retest holdouts, got %',v_bad; end if;
end $$;

-- Human-reviewed QA decisions for these original packs. Learning can release; diagnostic/retest/mixed stay withheld.
update private.exam_prep_question_content_meta m
set copyright_status='pass',qa_scope_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
    diagnostic_rule_status=case when reserve_role='diagnostic' then 'approved' else 'not_applicable' end,
    lifecycle_state='approved',approved_at=now(),updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version in ('p1_foundations_runway_v1','p5_dat02_runway_v1') and cv.status='draft';

update private.exam_prep_content_versions
set status='approved',approved_at=now()
where content_version in ('p1_foundations_runway_v1','p5_dat02_runway_v1') and status='draft';

update private.exam_prep_question_content_meta m
set lifecycle_state=case when reserve_role='learning' then 'published' else 'reserve' end,
    exposure_state=case when reserve_role='learning' then 'released' else 'withheld' end,
    published_at=case when reserve_role='learning' then now() else null end,
    updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version in ('p1_foundations_runway_v1','p5_dat02_runway_v1') and cv.status='approved';

update private.exam_prep_written_tasks w
set lifecycle_state='published'
from private.exam_prep_content_versions cv
where cv.id=w.content_version_id and cv.content_version in ('p1_foundations_runway_v1','p5_dat02_runway_v1') and cv.status='approved' and w.lifecycle_state='approved';

update private.exam_prep_assessments a
set status='published',approved_at=coalesce(approved_at,now())
from private.exam_prep_content_versions cv
where cv.id=a.content_version_id and cv.content_version in ('p1_foundations_runway_v1','p5_dat02_runway_v1') and cv.status='approved' and a.status='approved';

-- This transition is independently checked by the P1-02 publication guard.
update private.exam_prep_content_versions
set status='published',published_at=now()
where content_version in ('p1_foundations_runway_v1','p5_dat02_runway_v1') and status='approved';

-- Final P1-02 acceptance: 5/45 P1 and 4/36 P5 opening skills ready, AW1 four-week runway GREEN, no activation.
do $$
declare v_program bigint; v_skill text; v_r jsonb;
begin
  select id into v_program from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';
  foreach v_skill in array array['P1-QUA-01','P1-QUA-02','P1-QUA-03','P1-FUN-01','P1-FUN-02'] loop
    if not private.exam_prep_skill_content_ready_v1(v_program,'P1',v_skill) then raise exception 'P1-02 final: P1 skill not runway-ready: %',v_skill; end if;
  end loop;
  foreach v_skill in array array['P5-DAT-01','P5-DAT-02','P5-DAT-04','P5-DAT-06'] loop
    if not private.exam_prep_skill_content_ready_v1(v_program,'P5',v_skill) then raise exception 'P1-02 final: P5 skill not runway-ready: %',v_skill; end if;
  end loop;
  v_r:=public.get_exam_prep_content_runway_v1(1::smallint);
  if not coalesce((v_r->>'hard_floor_green')::boolean,false) then raise exception 'P1-02 final: AW1 hard-floor runway not green: %',v_r::text; end if;
  if not coalesce((v_r->>'target_4w_green')::boolean,false) then raise exception 'P1-02 final: AW1 four-week target not green: %',v_r::text; end if;
  if exists(select 1 from private.exam_prep_feature_config where program_key='math_as_p1_p5' and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch)) then raise exception 'P1-02 final: feature state escaped fail-closed'; end if;
  if (select count(*) from private.exam_prep_beta_cohorts)<>0 or (select count(*) from private.exam_prep_beta_members)<>0 then raise exception 'P1-02 final: beta residue'; end if;
end $$;

commit;
