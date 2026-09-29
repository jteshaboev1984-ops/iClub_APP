-- AW1-4 governed annual reserve release v1 contract.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_bad int;
  v1 jsonb;
  v2 jsonb;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4803,4804) and status='published')<>2 then
    raise exception 'annual reserve release: target versions not published';
  end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4803,4804)
        and release_mode='supplemental_reserve'
        and profile_version='aw01_04_annual_reserve_release_v1'
        and require_written_understanding=false)<>2 then
    raise exception 'annual reserve release: release profiles mismatch';
  end if;

  v1:=private.exam_prep_supplemental_reserve_floor_v1(4803);
  v2:=private.exam_prep_supplemental_reserve_floor_v1(4804);
  if coalesce((v1->>'ready')::boolean,false) is not true
     or coalesce((v2->>'ready')::boolean,false) is not true then
    raise exception 'annual reserve release: final floors not ready P1=% P5=%',v1,v2;
  end if;

  if (v1#>>'{counts,skills}')::int<>5
     or (v1#>>'{counts,questions}')::int<>25
     or (v1#>>'{counts,assessments}')::int<>13
     or (v2#>>'{counts,skills}')::int<>4
     or (v2#>>'{counts,questions}')::int<>20
     or (v2#>>'{counts,assessments}')::int<>11 then
    raise exception 'annual reserve release: final floor cardinality mismatch P1=% P5=%',v1,v2;
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4803,4804)
        and lifecycle_state='reserve'
        and exposure_state='withheld'
        and copyright_status='pass'
        and qa_scope_status='pass'
        and qa_math_status='pass'
        and qa_language_status='pass'
        and qa_technical_status='pass')<>45 then
    raise exception 'annual reserve release: governed reserve rows mismatch';
  end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4803,4804)
        and m.reserve_role='diagnostic'
        and r.rule_version='aw_reserve_v1'
        and r.status='approved')<>54 then
    raise exception 'annual reserve release: diagnostic rules mismatch';
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4803,4804)
        and status='published')<>24
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4803,4804)
           and assessment_type='diagnostic' and status='published')<>4
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4803,4804)
           and assessment_type='retest' and status='published')<>18
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4803,4804)
           and assessment_type='mixed' and status='published')<>2 then
    raise exception 'annual reserve release: assessment publication mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  join private.exam_prep_question_content_meta m
    on m.question_id=ai.question_id
   and m.content_version_id=a.content_version_id
  where a.content_version_id in (4803,4804)
    and (
      ai.question_id is null
      or ai.written_task_id is not null
      or not ai.is_holdout
      or ai.primary_skill_code<>m.primary_skill_code
      or ai.reserve_role<>m.reserve_role
      or ai.reserve_role<>a.assessment_type
      or ai.primary_skill_code not like a.component_code||'-%'
    );
  if v_bad<>0 then
    raise exception 'annual reserve release: holdout/component/role mismatch rows=%',v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4803,4804)
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
    raise exception 'annual reserve release: source isolation/snapshot mismatch rows=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_written_tasks
    where content_version_id in (4803,4804)
  ) then
    raise exception 'annual reserve release: reserve-only version contains written tasks';
  end if;

  -- Four delayed retest reserves per target skill now exist, all isolated one-item
  -- published assessments with withheld governed content.
  with expected(skill_code) as (values
    ('P1-QUA-01'),('P1-QUA-02'),('P1-QUA-03'),('P1-FUN-01'),('P1-FUN-02'),
    ('P5-DAT-01'),('P5-DAT-02'),('P5-DAT-04'),('P5-DAT-06')
  ), got as (
    select ai.primary_skill_code skill_code,count(*) n
    from private.exam_prep_assessments a
    join private.exam_prep_content_versions cv on cv.id=a.content_version_id
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    join private.exam_prep_question_content_meta m
      on m.question_id=ai.question_id
     and m.content_version_id=a.content_version_id
    where cv.status='published'
      and a.status='published'
      and a.assessment_type='retest'
      and ai.reserve_role='retest'
      and ai.is_holdout
      and m.lifecycle_state='reserve'
      and m.exposure_state='withheld'
      and ai.primary_skill_code in (select skill_code from expected)
      and (select count(*) from private.exam_prep_assessment_items z where z.assessment_id=a.id)=1
    group by ai.primary_skill_code
  )
  select count(*) into v_bad
  from expected e
  left join got g using(skill_code)
  where coalesce(g.n,0)<>4;
  if v_bad<>0 then
    raise exception 'annual reserve release: four-retest reserve not achieved rows=%',v_bad;
  end if;

  -- Cross-version annual depth is exact for machine evidence and at least two
  -- governed written tasks already exist outside this reserve-only version.
  with expected(component_code,skill_code) as (values
    ('P1','P1-QUA-01'),('P1','P1-QUA-02'),('P1','P1-QUA-03'),('P1','P1-FUN-01'),('P1','P1-FUN-02'),
    ('P5','P5-DAT-01'),('P5','P5-DAT-02'),('P5','P5-DAT-04'),('P5','P5-DAT-06')
  ), q as (
    select cv.component_code,m.primary_skill_code skill_code,
      count(*) filter(where m.reserve_role='diagnostic') d,
      count(*) filter(where m.reserve_role='learning') l,
      count(*) filter(where m.reserve_role='retest') r,
      count(*) filter(where m.reserve_role='mixed') x
    from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    join expected e on e.component_code=cv.component_code and e.skill_code=m.primary_skill_code
    where cv.status='published'
      and m.lifecycle_state in ('published','reserve')
    group by cv.component_code,m.primary_skill_code
  ), w as (
    select component_code,primary_skill_code skill_code,count(*) n
    from private.exam_prep_written_tasks
    where lifecycle_state='published'
      and primary_skill_code in (
        'P1-QUA-01','P1-QUA-02','P1-QUA-03','P1-FUN-01','P1-FUN-02',
        'P5-DAT-01','P5-DAT-02','P5-DAT-04','P5-DAT-06'
      )
    group by component_code,primary_skill_code
  )
  select count(*) into v_bad
  from expected e
  left join q using(component_code,skill_code)
  left join w using(component_code,skill_code)
  where coalesce(q.d,0)<>3
     or coalesce(q.l,0)+coalesce(q.x,0)<>8
     or coalesce(q.r,0)<>4
     or coalesce(w.n,0)<2;
  if v_bad<>0 then
    raise exception 'annual reserve release: annual machine/written depth mismatch rows=%',v_bad;
  end if;

  if has_table_privilege('anon','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_function_privilege('anon','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
     or not has_function_privilege('service_role','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE') then
    raise exception 'annual reserve release: private ACL mismatch';
  end if;
END
$$;

-- Rollback rehearsal: retire future selection only; preserve all content rows.
BEGIN;

UPDATE private.exam_prep_assessments
SET status='retired'
WHERE content_version_id IN (4803,4804)
  AND status='published';

UPDATE private.exam_prep_question_content_meta
SET exposure_state='retired',
    updated_at=now()
WHERE content_version_id IN (4803,4804)
  AND lifecycle_state='reserve'
  AND exposure_state='withheld';

UPDATE private.exam_prep_content_versions
SET status='retired',
    retired_at=now()
WHERE id IN (4803,4804)
  AND status='published';

DO $$
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4803,4804) and status='retired')<>2
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4803,4804) and status='retired')<>24
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4803,4804)
           and lifecycle_state='reserve'
           and exposure_state='retired')<>45 then
    raise exception 'annual reserve release: retirement rehearsal failed';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4803,4804))<>45
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4803,4804))<>24
     or (select count(*) from private.exam_prep_diagnostic_rules r
         join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
         where m.content_version_id in (4803,4804))<>54 then
    raise exception 'annual reserve release: retirement rehearsal deleted governed rows';
  end if;
END
$$;

ROLLBACK;

DO $$
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4803,4804) and status='published')<>2
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4803,4804) and status='published')<>24
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4803,4804)
           and lifecycle_state='reserve'
           and exposure_state='withheld')<>45 then
    raise exception 'annual reserve release: rollback rehearsal did not restore published reserve';
  end if;
END
$$;

\echo 'AW1-4 governed annual reserve release v1 contract: GREEN'
