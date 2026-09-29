-- Publish independently QA-reviewed AW1-4 annual reserve top-up v1.
--
-- SAFETY:
--   * additive reserve content only;
--   * all new diagnostic/retest/mixed questions remain withheld;
--   * public.questions remains inactive/draft;
--   * no written tasks are added or duplicated;
--   * existing learner/legacy history is never rewritten;
--   * content versions publish only through supplemental_reserve guard;
--   * Core remains independent of AI Assist and Mentor Care.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare
  v_program bigint;
  v_bad int;
  v_floor jsonb;
begin
  if to_regprocedure('private.exam_prep_supplemental_reserve_floor_v1(bigint)') is null
     or to_regclass('private.exam_prep_content_release_profiles_v1') is null
  then
    raise exception 'aw01_04_reserve_publish: supplemental-reserve architecture missing';
  end if;

  if (select count(*) from private.exam_prep_content_versions
      where id in (4803,4804)
        and content_version in (
          'p1_aw01_04_annual_reserve_topup_draft_v1',
          'p5_aw01_04_annual_reserve_topup_draft_v1'
        )
        and status='draft')<>2
  then
    raise exception 'aw01_04_reserve_publish: exact target draft versions missing';
  end if;

  if exists(
    select 1 from private.exam_prep_content_release_profiles_v1
    where content_version_id in (4803,4804)
  ) then
    raise exception 'aw01_04_reserve_publish: release profile already registered';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4803,4804))<>45
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4803,4804) and reserve_role='diagnostic')<>18
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4803,4804) and reserve_role='retest')<>18
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4803,4804) and reserve_role='mixed')<>9
  then
    raise exception 'aw01_04_reserve_publish: question-role cardinality drift';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4803,4804)
    and (
      m.lifecycle_state<>'draft'
      or m.exposure_state<>'withheld'
      or m.copyright_status<>'pending'
      or m.qa_scope_status<>'pending'
      or m.qa_math_status<>'pending'
      or m.qa_language_status<>'pending'
      or m.qa_technical_status<>'pending'
      or (m.reserve_role='diagnostic' and m.diagnostic_rule_status<>'pending')
      or (m.reserve_role<>'diagnostic' and m.diagnostic_rule_status<>'not_applicable')
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
  if v_bad<>0 then
    raise exception 'aw01_04_reserve_publish: draft metadata/source isolation drift rows=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    where m.content_version_id in (4803,4804)
      and (
        q.options_text_ru ~* '\m(or|only|cm)\M'
        or q.options_text_uz ~* '\m(or|only|cm)\M'
      )
  ) then
    raise exception 'aw01_04_reserve_publish: independent language QA correction missing';
  end if;

  -- Lock the independently strengthened retest semantics before approval.
  if (select count(*) from (
    values
      ('P1QUA01-R03','For q(x)=5x²−20x+23, the equation q(x)=c has exactly one real solution. Enter c.','3'),
      ('P1QUA01-R04','Which statement about y=−x²+10x−18 is correct?','D'),
      ('P1QUA02-R03','For which values of q is 2x²+qx+5 positive for every real x?','A'),
      ('P1QUA02-R04','The line y=4mx−4 is tangent to the parabola y=x². For which values of m does this happen?','C'),
      ('P1FUN01-R03','Let f(x)=x² with domain x≤0. Which formula gives f⁻¹(x)?','D'),
      ('P1FUN01-R04','Let f(x)=1/(x−3) and g(x)=2x+1. Enter the value of x that must be excluded from the domain of (f∘g)(x).','1'),
      ('P1FUN02-R03','For f(x)=(x−2)²+1 with −1<x≤4, what is the range?','D'),
      ('P1FUN02-R04','For f(x)=2x+3 with −5≤x<4, enter the minimum value of f.','-7'),
      ('P5DAT02-R03','A stem-and-leaf diagram has key 2 | 4 = 24 and rows 2 | 4 7 9 and 3 | 1 1 8. One additional observation 30 is inserted. Enter the new median.','30'),
      ('P5DAT04-R03','Two histogram classes have widths 4 and 6 and frequencies 12 and 18 respectively. Enter the ratio (first bar height)/(second bar height).','1'),
      ('P5DAT04-R04','In a histogram, class A has width 4 and frequency density 6; class B has width 8 and frequency density 3. Which statement is correct?','A'),
      ('P5DAT06-R03','The values 2, 6 and 10 occur with frequencies 1, k and 2 respectively. The mean is 7. Enter k.','1'),
      ('P5DAT06-R04','The data are 3, 3, 5, 7, 12. If 12 is replaced by 22, which statement is correct?','D')
  ) e(content_key,question_text_en,correct_answer)
  left join private.exam_prep_question_content_meta m
    on m.content_version_id in (4803,4804) and m.content_key=e.content_key
  left join public.questions q on q.id=m.question_id
  where m.id is null
     or q.question_text_en is distinct from e.question_text_en
     or q.correct_answer is distinct from e.correct_answer)<>0
  then
    raise exception 'aw01_04_reserve_publish: independent retest QA semantics drift';
  end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4803,4804)
        and m.reserve_role='diagnostic'
        and r.rule_version='aw_reserve_v1'
        and r.status='draft')<>54
  then
    raise exception 'aw01_04_reserve_publish: diagnostic rule draft cardinality drift';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4803,4804)
    and m.reserve_role='diagnostic'
    and (
      select count(*)
      from private.exam_prep_diagnostic_rules r
      where r.content_meta_id=m.id
        and r.rule_version='aw_reserve_v1'
        and r.status='draft'
        and r.answer_kind='mcq_option'
        and r.answer_match<>q.correct_answer
        and nullif(btrim(r.feedback_en),'') is not null
        and nullif(btrim(r.feedback_ru),'') is not null
        and nullif(btrim(r.feedback_uz),'') is not null
        and nullif(btrim(r.next_action_en),'') is not null
        and nullif(btrim(r.next_action_ru),'') is not null
        and nullif(btrim(r.next_action_uz),'') is not null
    )<>3;
  if v_bad<>0 then
    raise exception 'aw01_04_reserve_publish: diagnostic misconception rule drift rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4803,4804) and status='draft')<>24
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4803,4804) and assessment_type='diagnostic')<>4
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4803,4804) and assessment_type='retest')<>18
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4803,4804) and assessment_type='mixed')<>2
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4803,4804))<>45
  then
    raise exception 'aw01_04_reserve_publish: assessment draft cardinality drift';
  end if;

  select count(*) into v_bad
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  join private.exam_prep_question_content_meta m on m.question_id=ai.question_id
  where a.content_version_id in (4803,4804)
    and (
      ai.written_task_id is not null
      or not ai.is_holdout
      or ai.reserve_role<>a.assessment_type
      or ai.primary_skill_code<>m.primary_skill_code
      or ai.reserve_role<>m.reserve_role
      or m.content_version_id<>a.content_version_id
      or ai.primary_skill_code not like a.component_code||'-%'
    );
  if v_bad<>0 then
    raise exception 'aw01_04_reserve_publish: assessment reserve isolation drift rows=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_written_tasks
    where content_version_id in (4803,4804)
  ) then
    raise exception 'aw01_04_reserve_publish: reserve-only version unexpectedly has written tasks';
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4803,4804)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4803,4804)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4803,4804)
  ) then
    raise exception 'aw01_04_reserve_publish: target draft has learner/legacy history';
  end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';
  if v_program is null then
    raise exception 'aw01_04_reserve_publish: canonical active program missing';
  end if;

  select count(*) into v_bad
  from (values
    ('P1','P1-QUA-01'),('P1','P1-QUA-02'),('P1','P1-QUA-03'),('P1','P1-FUN-01'),('P1','P1-FUN-02'),
    ('P5','P5-DAT-01'),('P5','P5-DAT-02'),('P5','P5-DAT-04'),('P5','P5-DAT-06')
  ) s(component_code,skill_code)
  where not private.exam_prep_skill_content_ready_v1(v_program,s.component_code,s.skill_code);
  if v_bad<>0 then
    raise exception 'aw01_04_reserve_publish: separate baseline not ready rows=%',v_bad;
  end if;

  -- Verify prospective annual depth before any status mutation.
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
    where (cv.status='published' and m.lifecycle_state in ('published','reserve'))
       or (cv.id in (4803,4804) and cv.status='draft' and m.lifecycle_state='draft')
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
  where coalesce(q.d,0)<3
     or coalesce(q.l,0)+coalesce(q.x,0)<8
     or coalesce(q.r,0)<4
     or coalesce(w.n,0)<2;
  if v_bad<>0 then
    raise exception 'aw01_04_reserve_publish: prospective annual target not met rows=%',v_bad;
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
    raise exception 'aw01_04_reserve_publish: expected Core-only controlled-beta boundary changed';
  end if;

  if exists(
    select 1
    from private.exam_prep_beta_ops_incidents i
    join private.exam_prep_beta_cohorts c on c.id=i.cohort_id
    where c.cohort_key='math_as_p1_p5_beta_2026_09_01'
      and i.severity in ('sev0','sev1')
      and i.status in ('open','mitigating')
  ) then
    raise exception 'aw01_04_reserve_publish: open Sev0/Sev1 beta incident';
  end if;
end
$preflight$;

insert into private.exam_prep_content_release_profiles_v1(
  content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
) values
  (4803,'supplemental_reserve','aw01_04_annual_reserve_release_v1',false,
   'Independent scope/math/language/technical/copyright review complete; annual reserve top-up only; separate full-floor baseline required; all items remain withheld.'),
  (4804,'supplemental_reserve','aw01_04_annual_reserve_release_v1',false,
   'Independent scope/math/language/technical/copyright review complete; annual reserve top-up only; separate full-floor baseline required; all items remain withheld.');

-- Approve misconception rules before diagnostic metadata can enter reserve.
update private.exam_prep_diagnostic_rules r
set status='approved',
    approved_at=now()
from private.exam_prep_question_content_meta m
where m.id=r.content_meta_id
  and m.content_version_id in (4803,4804)
  and m.reserve_role='diagnostic'
  and r.rule_version='aw_reserve_v1'
  and r.status='draft';

-- Record independent QA. Still no learner-selectable assessment/version yet.
update private.exam_prep_question_content_meta
set copyright_status='pass',
    qa_scope_status='pass',
    qa_math_status='pass',
    qa_language_status='pass',
    qa_technical_status='pass',
    diagnostic_rule_status=case when reserve_role='diagnostic' then 'approved' else 'not_applicable' end,
    lifecycle_state='approved',
    approved_at=now(),
    updated_at=now()
where content_version_id in (4803,4804)
  and lifecycle_state='draft'
  and exposure_state='withheld';

update private.exam_prep_assessments
set status='approved',
    approved_at=now()
where content_version_id in (4803,4804)
  and status='draft';

update private.exam_prep_content_versions
set status='approved',
    approved_at=now()
where id in (4803,4804)
  and status='draft';

-- Reserve items remain withheld. Assessments become selectable only when the
-- content-version transaction commits as published.
update private.exam_prep_question_content_meta
set lifecycle_state='reserve',
    exposure_state='withheld',
    updated_at=now()
where content_version_id in (4803,4804)
  and lifecycle_state='approved';

update private.exam_prep_assessments
set status='published'
where content_version_id in (4803,4804)
  and status='approved';

do $floor_before_version_publish$
declare
  v1 jsonb;
  v2 jsonb;
begin
  v1:=private.exam_prep_supplemental_reserve_floor_v1(4803);
  v2:=private.exam_prep_supplemental_reserve_floor_v1(4804);

  if coalesce((v1->>'ready')::boolean,false) is not true
     or coalesce((v2->>'ready')::boolean,false) is not true
  then
    raise exception 'aw01_04_reserve_publish: supplemental reserve floor not ready P1=% P5=%',v1,v2;
  end if;
end
$floor_before_version_publish$;

-- Publication trigger independently re-runs the supplemental-reserve floor.
update private.exam_prep_content_versions
set status='published',
    published_at=now()
where id in (4803,4804)
  and status='approved';

do $postcheck$
declare
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4803,4804) and status='published')<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1
         where content_version_id in (4803,4804)
           and release_mode='supplemental_reserve'
           and profile_version='aw01_04_annual_reserve_release_v1'
           and not require_written_understanding)<>2
  then
    raise exception 'aw01_04_reserve_publish: version/profile publication mismatch';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4803,4804)
        and lifecycle_state='reserve'
        and exposure_state='withheld'
        and copyright_status='pass'
        and qa_scope_status='pass'
        and qa_math_status='pass'
        and qa_language_status='pass'
        and qa_technical_status='pass')<>45
  then
    raise exception 'aw01_04_reserve_publish: reserve metadata publication mismatch';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4803,4804)
        and reserve_role='diagnostic'
        and diagnostic_rule_status='approved')<>18
     or (select count(*) from private.exam_prep_diagnostic_rules r
         join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
         where m.content_version_id in (4803,4804)
           and m.reserve_role='diagnostic'
           and r.rule_version='aw_reserve_v1'
           and r.status='approved')<>54
  then
    raise exception 'aw01_04_reserve_publish: diagnostic governance publication mismatch';
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4803,4804) and status='published')<>24
  then
    raise exception 'aw01_04_reserve_publish: assessment publication mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4803,4804)
    and (q.is_active or q.quality_status<>'draft');
  if v_bad<>0 then
    raise exception 'aw01_04_reserve_publish: public source question isolation changed rows=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_written_tasks
    where content_version_id in (4803,4804)
  ) then
    raise exception 'aw01_04_reserve_publish: reserve-only version gained written tasks';
  end if;

  if coalesce((private.exam_prep_supplemental_reserve_floor_v1(4803)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4804)->>'ready')::boolean,false) is not true
  then
    raise exception 'aw01_04_reserve_publish: final supplemental reserve floor not ready';
  end if;

  -- Final annual target across published versions.
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
    where cv.status='published' and m.lifecycle_state in ('published','reserve')
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
  where coalesce(q.d,0)<3
     or coalesce(q.l,0)+coalesce(q.x,0)<8
     or coalesce(q.r,0)<4
     or coalesce(w.n,0)<2;
  if v_bad<>0 then
    raise exception 'aw01_04_reserve_publish: annual target failed after publication rows=%',v_bad;
  end if;

  -- Stored MCQ answer positions remain balanced as reviewed.
  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where lower(q.qtype)='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4803,4804);

  if (v_a,v_b,v_c,v_d,v_inputs)<>(9,10,9,10,7) then
    raise exception 'aw01_04_reserve_publish: answer balance drift A=% B=% C=% D=% input=%',
      v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4803,4804)
  ) then
    raise exception 'aw01_04_reserve_publish: learner session appeared during release transaction';
  end if;

  if exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4803,4804)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4803,4804)
  ) then
    raise exception 'aw01_04_reserve_publish: legacy history referenced target during release';
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
    raise exception 'aw01_04_reserve_publish: feature/service boundary changed during release';
  end if;
end
$postcheck$;

commit;
