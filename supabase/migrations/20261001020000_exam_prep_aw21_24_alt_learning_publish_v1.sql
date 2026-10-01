-- Publish independently reviewed AW21-24 supplemental learning packs.
--
-- Adds one second governed learning pack per AW21-24 closure skill:
-- P1 10 skills, P5 8 skills; each pack = 3 machine + 1 written task.
--
-- SAFETY:
-- * additive/versioned only;
-- * every target skill already has a separate governed baseline;
-- * public.questions source rows stay inactive/draft;
-- * target drafts must have zero learner/Practice/Tour history;
-- * Core stays controlled-beta; AI Assist and Mentor Care remain off.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare
  v_program bigint;
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
  v_check0 int; v_check1 int; v_check2 int; v_check3 int;
  v_skill record;
begin
  if to_regclass('private.exam_prep_content_release_profiles_v1') is null
     or to_regprocedure('private.exam_prep_supplemental_learning_floor_v1(bigint)') is null
  then raise exception 'aw21_24_alt_publish: supplemental-learning governance missing'; end if;

  if (select count(*) from private.exam_prep_content_versions
      where id in (4821,4822)
        and content_version in ('p1_aw21_24_alt_learning_draft_v1','p5_aw21_24_alt_learning_draft_v1')
        and status='draft')<>2
  then raise exception 'aw21_24_alt_publish: exact target drafts missing'; end if;

  if exists(select 1 from private.exam_prep_content_release_profiles_v1 where content_version_id in (4821,4822))
  then raise exception 'aw21_24_alt_publish: target profile already exists'; end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4821,4822) and assessment_type='learning' and status='draft')<>18
     or exists(select 1 from private.exam_prep_assessments
       where content_version_id in (4821,4822) and (assessment_type<>'learning' or status<>'draft'))
  then raise exception 'aw21_24_alt_publish: assessment draft shape drift'; end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4821,4822)
        and reserve_role='learning' and lifecycle_state='draft' and exposure_state='withheld'
        and copyright_status='pending' and qa_scope_status='pending' and qa_math_status='pending'
        and qa_language_status='pending' and qa_technical_status='pending'
        and diagnostic_rule_status='not_applicable')<>54
  then raise exception 'aw21_24_alt_publish: question governance draft shape drift'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4821,4822)
    and (
      q.subject_id<>5 or q.is_active or q.quality_status<>'draft'
      or q.qtype not in ('mcq','input')
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
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_en::jsonb) z(v))<>4
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_ru::jsonb) z(v))<>4
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_uz::jsonb) z(v))<>4
      ))
      or (q.qtype='input' and (
        nullif(btrim(q.correct_answer),'') is null
        or q.options_text_en::jsonb<>'[]'::jsonb
        or q.options_text_ru::jsonb<>'[]'::jsonb
        or q.options_text_uz::jsonb<>'[]'::jsonb
      ))
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
  if v_bad<>0 then raise exception 'aw21_24_alt_publish: question payload/snapshot failures=%',v_bad; end if;

  if (select count(*) from private.exam_prep_written_tasks
      where content_version_id in (4821,4822)
        and lifecycle_state='draft' and copyright_status='pending'
        and qa_math_status='pending' and qa_language_status='pending' and qa_technical_status='pending')<>18
  then raise exception 'aw21_24_alt_publish: written-task draft shape drift'; end if;

  if (select count(*) from private.exam_prep_written_understanding_checks c
      join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
      where wt.content_version_id in (4821,4822)
        and c.lifecycle_state='draft'
        and c.qa_math_status='pending' and c.qa_language_status='pending' and c.qa_technical_status='pending')<>18
  then raise exception 'aw21_24_alt_publish: written-understanding draft shape drift'; end if;

  select count(*) into v_bad
  from (
    select a.id,
      count(*) filter(where ai.question_id is not null) machine_n,
      count(*) filter(where ai.written_task_id is not null) written_n,
      count(distinct ai.primary_skill_code) skill_n,
      count(*) filter(where ai.is_holdout) holdout_n,
      count(*) filter(where ai.question_id is not null and ai.reserve_role<>'learning') bad_machine_role,
      count(*) filter(where ai.written_task_id is not null and ai.reserve_role<>'written') bad_written_role
    from private.exam_prep_assessments a
    left join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    where a.content_version_id in (4821,4822)
    group by a.id
  ) x
  where x.machine_n<>3 or x.written_n<>1 or x.skill_n<>1
     or x.holdout_n<>0 or x.bad_machine_role<>0 or x.bad_written_role<>0;
  if v_bad<>0 then raise exception 'aw21_24_alt_publish: assessment item-shape failures=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4821,4822)
  ) or exists(
    select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4821,4822)
  ) or exists(
    select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4821,4822)
  ) then raise exception 'aw21_24_alt_publish: target draft has learner/legacy history'; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4821;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(5,5,5,5,10) then
    raise exception 'aw21_24_alt_publish: P1 answer-position drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4822;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw21_24_alt_publish: P5 answer-position drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select count(*) filter(where correct_index=0),count(*) filter(where correct_index=1),
         count(*) filter(where correct_index=2),count(*) filter(where correct_index=3)
  into v_check0,v_check1,v_check2,v_check3
  from private.exam_prep_written_understanding_checks
  where id between 8964 and 8981;
  if (v_check0,v_check1,v_check2,v_check3)<>(5,5,4,4) then
    raise exception 'aw21_24_alt_publish: written-check answer-position drift 0=% 1=% 2=% 3=%',v_check0,v_check1,v_check2,v_check3;
  end if;

  with expected(content_key,answer) as (values
    ('P1COO05-A01','A'),
    ('P1COO05-A02','B'),
    ('P1COO05-A03','10'),
    ('P1COO06-A01','C'),
    ('P1COO06-A02','D'),
    ('P1COO06-A03','5'),
    ('P1DIF05-A01','A'),
    ('P1DIF05-A02','B'),
    ('P1DIF05-A03','5'),
    ('P1DIF06-A01','C'),
    ('P1DIF06-A02','D'),
    ('P1DIF06-A03','-3'),
    ('P1DIF07-A01','A'),
    ('P1DIF07-A02','B'),
    ('P1DIF07-A03','2'),
    ('P1INT01-A01','C'),
    ('P1INT01-A02','D'),
    ('P1INT01-A03','2'),
    ('P1INT02-A01','A'),
    ('P1INT02-A02','B'),
    ('P1INT02-A03','2'),
    ('P1INT03-A01','C'),
    ('P1INT03-A02','D'),
    ('P1INT03-A03','7'),
    ('P1INT04-A01','A'),
    ('P1INT04-A02','B'),
    ('P1INT04-A03','4/3'),
    ('P1INT05-A01','C'),
    ('P1INT05-A02','D'),
    ('P1INT05-A03','12'),
    ('P5DAT08-A01','A'),
    ('P5DAT08-A02','B'),
    ('P5DAT08-A03','5'),
    ('P5DAT09-A01','C'),
    ('P5DAT09-A02','D'),
    ('P5DAT09-A03','12'),
    ('P5DAT10-A01','A'),
    ('P5DAT10-A02','B'),
    ('P5DAT10-A03','21.25'),
    ('P5NOR02-A01','C'),
    ('P5NOR02-A02','D'),
    ('P5NOR02-A03','2'),
    ('P5NOR03-A01','A'),
    ('P5NOR03-A02','B'),
    ('P5NOR03-A03','0.6827'),
    ('P5NOR04-A01','C'),
    ('P5NOR04-A02','D'),
    ('P5NOR04-A03','1.645'),
    ('P5NOR05-A01','A'),
    ('P5NOR05-A02','B'),
    ('P5NOR05-A03','52'),
    ('P5NOR06-A01','C'),
    ('P5NOR06-A02','D'),
    ('P5NOR06-A03','12.5')
  )
  select count(*) into v_bad
  from expected e
  left join private.exam_prep_question_content_meta m
    on m.content_version_id in (4821,4822) and m.content_key=e.content_key
  left join public.questions q on q.id=m.question_id
  where q.id is null or q.correct_answer<>e.answer;
  if v_bad<>0 then raise exception 'aw21_24_alt_publish: independent-QA answer map mismatch rows=%',v_bad; end if;

  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4821 and m.content_key='P1INT01-A01'
      and q.correct_answer='C'
      and q.options_text_en::jsonb->>2='2x³−2x²+5x+C'
      and q.options_text_ru::jsonb->>2='2x³−2x²+5x+C'
      and q.options_text_uz::jsonb->>2='2x³−2x²+5x+C'
  ) then raise exception 'aw21_24_alt_publish: semantic correction pin missing'; end if;

  if exists(
    select 1 from private.exam_prep_assessments
    where content_version_id in (4821,4822)
      and (
        lower(coalesce(title_en,'')) like '%supplemental%'
        or lower(coalesce(title_en,'')) like '%draft%'
        or lower(coalesce(title_ru,'')) like '%дополнительн%'
        or lower(coalesce(title_ru,'')) like '%чернов%'
        or lower(coalesce(title_uz,'')) like '%qo‘shimcha%'
      )
  ) then raise exception 'aw21_24_alt_publish: internal release wording remains in learner titles'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  where m.content_version_id in (4821,4822)
    and (
      (m.primary_skill_code in ('P1-COO-05','P1-COO-06')
        and (m.official_scope_ref not like '%P1 1.3 Coordinate geometry%' or m.coursebook_mapping_ref not like '%Ch3%48-67%'))
      or (m.primary_skill_code in ('P1-DIF-05','P1-DIF-06','P1-DIF-07')
        and (m.official_scope_ref not like '%P1 1.7 Differentiation%' or m.coursebook_mapping_ref not like '%Ch9%156-167%'))
      or (m.primary_skill_code like 'P1-INT-%'
        and (m.official_scope_ref not like '%P1 1.8 Integration%' or m.coursebook_mapping_ref not like '%Ch10%173-200%'))
      or (m.primary_skill_code='P5-DAT-08'
        and (m.official_scope_ref not like '%P5 5.1 Representation of data%' or m.coursebook_mapping_ref not like '%Ch2-3%14-59%'))
      or (m.primary_skill_code in ('P5-DAT-09','P5-DAT-10')
        and (m.official_scope_ref not like '%P5 5.1 Representation of data%' or m.coursebook_mapping_ref not like '%Ch2%14-29%'))
      or (m.primary_skill_code in ('P5-NOR-02','P5-NOR-03','P5-NOR-04','P5-NOR-05')
        and (m.official_scope_ref not like '%P5 5.5 The normal distribution%' or m.coursebook_mapping_ref not like '%Ch9%147-171%'))
      or (m.primary_skill_code='P5-NOR-06'
        and (m.official_scope_ref not like '%P5 5.5 The normal distribution%' or m.coursebook_mapping_ref not like '%Ch10%173-179%'))
    );
  if v_bad<>0 then raise exception 'aw21_24_alt_publish: source-map mismatch rows=%',v_bad; end if;

  if (select count(*)
      from private.exam_prep_content_runway_releases r
      join private.exam_prep_content_runway_release_skills rs on rs.release_id=r.id
      where r.release_key='aw21_24_syllabus_closure'
        and r.active_week_from=21 and r.active_week_through=24
        and r.schedule_status='active'
        and rs.required_for_release)<>18
  then raise exception 'aw21_24_alt_publish: governed runway target set mismatch'; end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code
     and oldm.content_version_id<>m.content_version_id
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4821,4822)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw21_24_alt_publish: exact published stem reuse'; end if;

  if (select count(*) from private.exam_prep_written_understanding_checks where lifecycle_state='published')<>115
     or (select count(distinct written_task_id) from private.exam_prep_written_understanding_checks where lifecycle_state='published')<>112
  then raise exception 'aw21_24_alt_publish: pre-existing written-understanding surface drift'; end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'aw21_24_alt_publish: canonical active program missing'; end if;

  for v_skill in
    select * from (values
      ('P1','P1-COO-05'),
      ('P1','P1-COO-06'),
      ('P1','P1-DIF-05'),
      ('P1','P1-DIF-06'),
      ('P1','P1-DIF-07'),
      ('P1','P1-INT-01'),
      ('P1','P1-INT-02'),
      ('P1','P1-INT-03'),
      ('P1','P1-INT-04'),
      ('P1','P1-INT-05'),
      ('P5','P5-DAT-08'),
      ('P5','P5-DAT-09'),
      ('P5','P5-DAT-10'),
      ('P5','P5-NOR-02'),
      ('P5','P5-NOR-03'),
      ('P5','P5-NOR-04'),
      ('P5','P5-NOR-05'),
      ('P5','P5-NOR-06')
    ) s(component_code,skill_code)
  loop
    if not private.exam_prep_skill_content_ready_v1(v_program,v_skill.component_code,v_skill.skill_code) then
      raise exception 'aw21_24_alt_publish: baseline full-floor skill not ready % %',
        v_skill.component_code,v_skill.skill_code;
    end if;
  end loop;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1 and rollout_state='controlled_beta'
      and core_enabled and ai_enabled=false and mentor_enabled=false and kill_switch=false
  ) then raise exception 'aw21_24_alt_publish: controlled-beta Core-only boundary changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_release_profiles_v1(
  content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
)
values
 (4821,'supplemental_learning','aw21_24_alt_release_v1',true,
  'Independent scope/math/language/technical/copyright review complete; second governed learning pack only; separate full-floor baseline required.'),
 (4822,'supplemental_learning','aw21_24_alt_release_v1',true,
  'Independent scope/math/language/technical/copyright review complete; second governed learning pack only; separate full-floor baseline required.');

update private.exam_prep_question_content_meta
set copyright_status='pass',qa_scope_status='pass',qa_math_status='pass',
    qa_language_status='pass',qa_technical_status='pass',
    lifecycle_state='approved',approved_at=now(),updated_at=now()
where content_version_id in (4821,4822)
  and lifecycle_state='draft' and exposure_state='withheld' and reserve_role='learning';

update private.exam_prep_written_tasks
set copyright_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
    lifecycle_state='approved',approved_at=now()
where content_version_id in (4821,4822) and lifecycle_state='draft';

update private.exam_prep_written_understanding_checks c
set qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
    lifecycle_state='approved',approved_at=now()
from private.exam_prep_written_tasks wt
where wt.id=c.written_task_id and wt.content_version_id in (4821,4822) and c.lifecycle_state='draft';

update private.exam_prep_assessments
set status='approved',approved_at=now()
where content_version_id in (4821,4822) and assessment_type='learning' and status='draft';

update private.exam_prep_content_versions
set status='approved',approved_at=now()
where id in (4821,4822) and status='draft';

update private.exam_prep_question_content_meta
set lifecycle_state='published',exposure_state='released',published_at=now(),updated_at=now()
where content_version_id in (4821,4822) and lifecycle_state='approved' and reserve_role='learning';

update private.exam_prep_written_tasks
set lifecycle_state='published'
where content_version_id in (4821,4822) and lifecycle_state='approved';

update private.exam_prep_written_understanding_checks c
set lifecycle_state='published'
from private.exam_prep_written_tasks wt
where wt.id=c.written_task_id and wt.content_version_id in (4821,4822) and c.lifecycle_state='approved';

update private.exam_prep_assessments
set status='published'
where content_version_id in (4821,4822) and assessment_type='learning' and status='approved';

do $floor_before_version_publish$
declare v1 jsonb; v2 jsonb;
begin
  v1:=private.exam_prep_supplemental_learning_floor_v1(4821);
  v2:=private.exam_prep_supplemental_learning_floor_v1(4822);
  if coalesce((v1->>'ready')::boolean,false) is not true
     or coalesce((v2->>'ready')::boolean,false) is not true
  then raise exception 'aw21_24_alt_publish: supplemental floor not ready P1=% P5=%',v1::text,v2::text; end if;
end
$floor_before_version_publish$;

update private.exam_prep_content_versions
set status='published',published_at=now()
where id in (4821,4822) and status='approved';

do $postcheck$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions where id in (4821,4822) and status='published')<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1
         where content_version_id in (4821,4822)
           and release_mode='supplemental_learning'
           and profile_version='aw21_24_alt_release_v1'
           and require_written_understanding)<>2
  then raise exception 'aw21_24_alt_publish: version/profile publication mismatch'; end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4821,4822)
        and reserve_role='learning' and lifecycle_state='published' and exposure_state='released'
        and copyright_status='pass' and qa_scope_status='pass' and qa_math_status='pass'
        and qa_language_status='pass' and qa_technical_status='pass')<>54
  then raise exception 'aw21_24_alt_publish: published learning metadata mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id in (4821,4822)
    and (q.is_active or q.quality_status<>'draft');
  if v_bad<>0 then raise exception 'aw21_24_alt_publish: source question isolation changed rows=%',v_bad; end if;

  if (select count(*) from private.exam_prep_written_tasks
      where content_version_id in (4821,4822)
        and lifecycle_state='published' and copyright_status='pass'
        and qa_math_status='pass' and qa_language_status='pass' and qa_technical_status='pass')<>18
     or (select count(*) from private.exam_prep_written_understanding_checks c
         join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
         where wt.content_version_id in (4821,4822)
           and c.lifecycle_state='published' and c.qa_math_status='pass'
           and c.qa_language_status='pass' and c.qa_technical_status='pass')<>18
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4821,4822) and assessment_type='learning' and status='published')<>18
  then raise exception 'aw21_24_alt_publish: written/check/assessment publication mismatch'; end if;

  if (select count(*) from private.exam_prep_written_understanding_checks where lifecycle_state='published')<>133
     or (select count(distinct written_task_id)
         from private.exam_prep_written_understanding_checks where lifecycle_state='published')<>130
  then raise exception 'aw21_24_alt_publish: governed written-understanding surface mismatch'; end if;

  select count(*) into v_bad
  from (
    with skills(skill_code) as (values
      ('P1-COO-05'),
      ('P1-COO-06'),
      ('P1-DIF-05'),
      ('P1-DIF-06'),
      ('P1-DIF-07'),
      ('P1-INT-01'),
      ('P1-INT-02'),
      ('P1-INT-03'),
      ('P1-INT-04'),
      ('P1-INT-05'),
      ('P5-DAT-08'),
      ('P5-DAT-09'),
      ('P5-DAT-10'),
      ('P5-NOR-02'),
      ('P5-NOR-03'),
      ('P5-NOR-04'),
      ('P5-NOR-05'),
      ('P5-NOR-06')
    )
    select s.skill_code
    from skills s
    left join private.exam_prep_question_content_meta m on m.primary_skill_code=s.skill_code
    left join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    left join private.exam_prep_written_tasks wt on wt.primary_skill_code=s.skill_code and wt.lifecycle_state='published'
    group by s.skill_code
    having count(distinct m.id) filter(
      where cv.status='published' and m.lifecycle_state in ('published','reserve') and m.reserve_role in ('learning','mixed')
    )<7
       or count(distinct wt.id)<2
  ) x;
  if v_bad<>0 then raise exception 'aw21_24_alt_publish: final learning/written floor failed rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4821,4822)
  ) or exists(
    select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4821,4822)
  ) or exists(
    select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4821,4822)
  ) then raise exception 'aw21_24_alt_publish: history appeared during release'; end if;

  if coalesce((private.exam_prep_supplemental_learning_floor_v1(4821)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4822)->>'ready')::boolean,false) is not true
  then raise exception 'aw21_24_alt_publish: final supplemental floor not ready'; end if;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1 and rollout_state='controlled_beta'
      and core_enabled and ai_enabled=false and mentor_enabled=false and kill_switch=false
  ) then raise exception 'aw21_24_alt_publish: feature/service boundary changed'; end if;
end
$postcheck$;

commit;
