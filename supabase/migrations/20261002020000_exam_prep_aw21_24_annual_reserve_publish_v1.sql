-- Publish independently reviewed AW21-24 annual reserve top-up.
--
-- Reserve depth only:
--   +2 diagnostic, +2 isolated delayed retest, +1 mixed/transfer item
--   for each of the 18 AW21-24 closure skills.
-- No teaching pack or written task is introduced here.
--
-- Safety:
-- * exact hidden/history-free drafts only;
-- * public.questions source rows remain inactive/draft;
-- * all reserve questions remain withheld after publication;
-- * separate governed learning/written baseline must already be ready;
-- * Core stays controlled-beta; AI Assist and Mentor Care remain off.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare
  v_program bigint;
  v_skill record;
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
  v_seq text;
begin
  if to_regprocedure('private.exam_prep_supplemental_reserve_floor_v1(bigint)') is null
     or to_regclass('private.exam_prep_content_release_profiles_v1') is null
  then
    raise exception 'aw21_24_reserve_publish: supplemental-reserve architecture missing';
  end if;

  if (select count(*) from private.exam_prep_content_versions
      where id in (4823,4824)
        and content_version in ('p1_aw21_24_annual_reserve_topup_draft_v1','p5_aw21_24_annual_reserve_topup_draft_v1')
        and status='draft')<>2
  then raise exception 'aw21_24_reserve_publish: exact target drafts missing'; end if;

  if exists(
    select 1 from private.exam_prep_content_release_profiles_v1
    where content_version_id in (4823,4824)
  ) then raise exception 'aw21_24_reserve_publish: target release profile already exists'; end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4823,4824))<>90
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4823,4824) and reserve_role='diagnostic')<>36
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4823,4824) and reserve_role='retest')<>36
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4823,4824) and reserve_role='mixed')<>18
  then raise exception 'aw21_24_reserve_publish: candidate question-role cardinality drift'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4823,4824)
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
      or q.subject_id<>5
      or q.is_active
      or q.quality_status<>'draft'
      or nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
      or nullif(btrim(m.originality_attestation),'') is null
      or nullif(btrim(m.provenance_note),'') is null
      or nullif(btrim(m.official_scope_ref),'') is null
      or nullif(btrim(m.coursebook_mapping_ref),'') is null
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
  if v_bad<>0 then
    raise exception 'aw21_24_reserve_publish: draft QA/source/snapshot drift rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4823,4824)
        and m.reserve_role='diagnostic'
        and r.rule_version='aw_reserve_v1'
        and r.status='draft')<>108
  then raise exception 'aw21_24_reserve_publish: diagnostic-rule cardinality drift'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4823,4824)
    and m.reserve_role='diagnostic'
    and (
      q.qtype<>'mcq'
      or (select count(*) from private.exam_prep_diagnostic_rules r
          where r.content_meta_id=m.id
            and r.rule_version='aw_reserve_v1'
            and r.status='draft'
            and r.answer_kind='mcq_option'
            and r.answer_match<>q.correct_answer
            and r.weak_skill_code=m.primary_skill_code
            and nullif(btrim(r.feedback_en),'') is not null
            and nullif(btrim(r.feedback_ru),'') is not null
            and nullif(btrim(r.feedback_uz),'') is not null
            and nullif(btrim(r.next_action_en),'') is not null
            and nullif(btrim(r.next_action_ru),'') is not null
            and nullif(btrim(r.next_action_uz),'') is not null)<>3
      or exists(
          select 1 from private.exam_prep_diagnostic_rules r
          where r.content_meta_id=m.id
            and r.rule_version='aw_reserve_v1'
            and r.answer_match=q.correct_answer)
    );
  if v_bad<>0 then
    raise exception 'aw21_24_reserve_publish: diagnostic misconception-rule drift rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4823,4824) and status='draft')<>42
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4823,4824) and assessment_type='diagnostic')<>4
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4823,4824) and assessment_type='retest')<>36
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4823,4824) and assessment_type='mixed')<>2
     or (select count(*) from private.exam_prep_assessment_items ai
         join private.exam_prep_assessments a on a.id=ai.assessment_id
         where a.content_version_id in (4823,4824))<>90
  then raise exception 'aw21_24_reserve_publish: candidate assessment cardinality drift'; end if;

  select count(*) into v_bad
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  join private.exam_prep_question_content_meta m
    on m.question_id=ai.question_id and m.content_version_id=a.content_version_id
  where a.content_version_id in (4823,4824)
    and (
      ai.question_id is null
      or ai.written_task_id is not null
      or ai.is_holdout is not true
      or ai.primary_skill_code<>m.primary_skill_code
      or ai.reserve_role<>m.reserve_role
      or ai.reserve_role<>a.assessment_type
      or ai.primary_skill_code not like a.component_code||'-%'
    );
  if v_bad<>0 then
    raise exception 'aw21_24_reserve_publish: assessment role/holdout drift rows=%',v_bad;
  end if;

  if exists(select 1 from private.exam_prep_written_tasks where content_version_id in (4823,4824))
  then raise exception 'aw21_24_reserve_publish: reserve-only candidate contains written tasks'; end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4823,4824)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4823,4824)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4823,4824)
  ) then raise exception 'aw21_24_reserve_publish: target draft already has learner/legacy history'; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4823;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(8,8,7,7,20) then
    raise exception 'aw21_24_reserve_publish: P1 answer-position drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4824;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(6,6,6,6,16) then
    raise exception 'aw21_24_reserve_publish: P5 answer-position drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  for v_seq in
    select string_agg(q.correct_answer,'' order by ai.item_order)
    from private.exam_prep_assessments a
    join private.exam_prep_assessment_items ai on ai.assessment_id=a.id
    join public.questions q on q.id=ai.question_id
    where a.id in (35529,35530,35552,35553)
    group by a.id
  loop
    if v_seq like any(array['%ABCD%','%BCDA%','%CDAB%','%DABC%','%DCBA%','%CBAD%','%BADC%','%ADCB%'])
       or v_seq ~ '(AA|BB|CC|DD)' then
      raise exception 'aw21_24_reserve_publish: sequential correct-option pattern detected: %',v_seq;
    end if;
  end loop;

  with expected(content_key,answer) as (values
    ('P1COO05-D02','B'),
    ('P1COO05-D03','A'),
    ('P1COO05-R03','4'),
    ('P1COO05-R04','C'),
    ('P1COO05-M02','2'),
    ('P1COO06-D02','A'),
    ('P1COO06-D03','D'),
    ('P1COO06-R03','2'),
    ('P1COO06-R04','A'),
    ('P1COO06-M02','4'),
    ('P1DIF05-D02','C'),
    ('P1DIF05-D03','B'),
    ('P1DIF05-R03','6'),
    ('P1DIF05-R04','C'),
    ('P1DIF05-M02','2'),
    ('P1DIF06-D02','A'),
    ('P1DIF06-D03','C'),
    ('P1DIF06-R03','3'),
    ('P1DIF06-R04','A'),
    ('P1DIF06-M02','15'),
    ('P1DIF07-D02','B'),
    ('P1DIF07-D03','D'),
    ('P1DIF07-R03','1'),
    ('P1DIF07-R04','B'),
    ('P1DIF07-M02','2'),
    ('P1INT01-D02','D'),
    ('P1INT01-D03','B'),
    ('P1INT01-R03','3'),
    ('P1INT01-R04','D'),
    ('P1INT01-M02','2'),
    ('P1INT02-D02','C'),
    ('P1INT02-D03','D'),
    ('P1INT02-R03','-3'),
    ('P1INT02-R04','B'),
    ('P1INT02-M02','38'),
    ('P1INT03-D02','D'),
    ('P1INT03-D03','C'),
    ('P1INT03-R03','12'),
    ('P1INT03-R04','A'),
    ('P1INT03-M02','4'),
    ('P1INT04-D02','B'),
    ('P1INT04-D03','A'),
    ('P1INT04-R03','32/3'),
    ('P1INT04-R04','D'),
    ('P1INT04-M02','4'),
    ('P1INT05-D02','A'),
    ('P1INT05-D03','C'),
    ('P1INT05-R03','8'),
    ('P1INT05-R04','B'),
    ('P1INT05-M02','18'),
    ('P5DAT08-D02','B'),
    ('P5DAT08-D03','C'),
    ('P5DAT08-R03','8'),
    ('P5DAT08-R04','B'),
    ('P5DAT08-M02','4'),
    ('P5DAT09-D02','D'),
    ('P5DAT09-D03','B'),
    ('P5DAT09-R03','13'),
    ('P5DAT09-R04','D'),
    ('P5DAT09-M02','6'),
    ('P5DAT10-D02','C'),
    ('P5DAT10-D03','D'),
    ('P5DAT10-R03','84'),
    ('P5DAT10-R04','B'),
    ('P5DAT10-M02','15'),
    ('P5NOR02-D02','D'),
    ('P5NOR02-D03','B'),
    ('P5NOR02-R03','2'),
    ('P5NOR02-R04','A'),
    ('P5NOR02-M02','-2'),
    ('P5NOR03-D02','B'),
    ('P5NOR03-D03','A'),
    ('P5NOR03-R03','0.1357'),
    ('P5NOR03-R04','C'),
    ('P5NOR03-M02','0.95'),
    ('P5NOR04-D02','A'),
    ('P5NOR04-D03','C'),
    ('P5NOR04-R03','33.59'),
    ('P5NOR04-R04','A'),
    ('P5NOR04-M02','86.02'),
    ('P5NOR05-D02','C'),
    ('P5NOR05-D03','A'),
    ('P5NOR05-R03','43'),
    ('P5NOR05-R04','D'),
    ('P5NOR05-M02','60'),
    ('P5NOR06-D02','A'),
    ('P5NOR06-D03','D'),
    ('P5NOR06-R03','24.5'),
    ('P5NOR06-R04','C'),
    ('P5NOR06-M02','31.5')
  )
  select count(*) into v_bad
  from expected e
  left join private.exam_prep_question_content_meta m
    on m.content_version_id in (4823,4824) and m.content_key=e.content_key
  left join public.questions q on q.id=m.question_id
  where q.id is null or q.correct_answer<>e.answer;
  if v_bad<>0 then
    raise exception 'aw21_24_reserve_publish: independent-QA 90-answer map mismatch rows=%',v_bad;
  end if;

  -- Independent-QA semantic pins that materially changed this candidate.
  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5DAT08-D02'
      and q.correct_answer='B'
      and q.question_text_en like 'Route A delivery times%'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5DAT09-D02'
      and q.correct_answer='D' and q.question_text_en like '%standard deviation%'
      and q.options_text_en::jsonb->>3='3'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5NOR04-M02'
      and q.correct_answer='86.02'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4824 and m.content_key='P5NOR06-D03'
      and q.correct_answer='D'
      and q.options_text_en::jsonb->>3='Both np and n(1−p) should be sufficiently large'
  ) then
    raise exception 'aw21_24_reserve_publish: independent-QA semantic correction pin missing';
  end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code
     and oldm.content_version_id<>m.content_version_id
    join private.exam_prep_content_versions oldcv
      on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4823,4824)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw21_24_reserve_publish: exact published stem reuse'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  where m.content_version_id in (4823,4824)
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
  if v_bad<>0 then raise exception 'aw21_24_reserve_publish: source-map mismatch rows=%',v_bad; end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';
  if v_program is null then raise exception 'aw21_24_reserve_publish: canonical active program missing'; end if;

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
      raise exception 'aw21_24_reserve_publish: full-floor baseline not ready % %',
        v_skill.component_code,v_skill.skill_code;
    end if;
  end loop;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1 and rollout_state='controlled_beta' and core_enabled
      and ai_enabled=false and mentor_enabled=false and kill_switch=false
  ) then
    raise exception 'aw21_24_reserve_publish: expected controlled-beta Core-only boundary changed';
  end if;
end
$preflight$;

insert into private.exam_prep_content_release_profiles_v1(
  content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
)
values
  (4823,'supplemental_reserve','aw21_24_annual_reserve_release_v1',false,
   'Independent scope/math/language/technical/copyright review complete; reserve-only AW21-24 annual depth; separate fully governed baseline required.'),
  (4824,'supplemental_reserve','aw21_24_annual_reserve_release_v1',false,
   'Independent scope/math/language/technical/copyright review complete; reserve-only AW21-24 annual depth; separate fully governed baseline required.');

update private.exam_prep_diagnostic_rules r
set status='approved',approved_at=now()
from private.exam_prep_question_content_meta m
where m.id=r.content_meta_id
  and m.content_version_id in (4823,4824)
  and m.reserve_role='diagnostic'
  and r.rule_version='aw_reserve_v1'
  and r.status='draft';

update private.exam_prep_question_content_meta
set copyright_status='pass',
    qa_scope_status='pass',
    qa_math_status='pass',
    qa_language_status='pass',
    qa_technical_status='pass',
    diagnostic_rule_status=case when reserve_role='diagnostic' then 'approved' else 'not_applicable' end,
    lifecycle_state='reserve',
    exposure_state='withheld',
    approved_at=coalesce(approved_at,now()),
    updated_at=now()
where content_version_id in (4823,4824)
  and lifecycle_state='draft'
  and exposure_state='withheld';

update private.exam_prep_assessments
set status='approved',approved_at=coalesce(approved_at,now())
where content_version_id in (4823,4824) and status='draft';

update private.exam_prep_content_versions
set status='approved',approved_at=coalesce(approved_at,now())
where id in (4823,4824) and status='draft';

update private.exam_prep_assessments
set status='published'
where content_version_id in (4823,4824)
  and status='approved'
  and assessment_type in ('diagnostic','retest','mixed');

do $floor_before_version_publish$
declare v1 jsonb; v2 jsonb;
begin
  v1:=private.exam_prep_supplemental_reserve_floor_v1(4823);
  v2:=private.exam_prep_supplemental_reserve_floor_v1(4824);
  if coalesce((v1->>'ready')::boolean,false) is not true
     or coalesce((v2->>'ready')::boolean,false) is not true
  then
    raise exception 'aw21_24_reserve_publish: supplemental reserve floor not ready P1=% P5=%',
      v1::text,v2::text;
  end if;
end
$floor_before_version_publish$;

update private.exam_prep_content_versions
set status='published',published_at=now()
where id in (4823,4824) and status='approved';

do $postcheck$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4823,4824) and status='published')<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1
         where content_version_id in (4823,4824)
           and release_mode='supplemental_reserve'
           and profile_version='aw21_24_annual_reserve_release_v1'
           and require_written_understanding=false)<>2
  then raise exception 'aw21_24_reserve_publish: final version/profile state mismatch'; end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4823,4824)
        and lifecycle_state='reserve'
        and exposure_state='withheld'
        and copyright_status='pass'
        and qa_scope_status='pass'
        and qa_math_status='pass'
        and qa_language_status='pass'
        and qa_technical_status='pass')<>90
  then raise exception 'aw21_24_reserve_publish: final reserve question state mismatch'; end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4823,4824)
        and m.reserve_role='diagnostic'
        and r.rule_version='aw_reserve_v1'
        and r.status='approved')<>108
  then raise exception 'aw21_24_reserve_publish: final diagnostic-rule state mismatch'; end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4823,4824) and status='published')<>42
  then raise exception 'aw21_24_reserve_publish: final assessment publication mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4823,4824)
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
    raise exception 'aw21_24_reserve_publish: public source isolation/snapshot changed rows=%',v_bad;
  end if;

  if exists(select 1 from private.exam_prep_written_tasks where content_version_id in (4823,4824))
  then raise exception 'aw21_24_reserve_publish: final reserve versions contain written tasks'; end if;

  if coalesce((private.exam_prep_supplemental_reserve_floor_v1(4823)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4824)->>'ready')::boolean,false) is not true
  then raise exception 'aw21_24_reserve_publish: final supplemental reserve floor not ready'; end if;

  with expected(component_code,skill_code) as (values
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
  ), q as (
    select cv.component_code,m.primary_skill_code skill_code,
      count(*) filter(where m.reserve_role='diagnostic') d,
      count(*) filter(where m.reserve_role='learning') l,
      count(*) filter(where m.reserve_role='retest') r,
      count(*) filter(where m.reserve_role='mixed') x
    from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    join expected e
      on e.component_code=cv.component_code and e.skill_code=m.primary_skill_code
    where cv.status='published' and m.lifecycle_state in ('published','reserve')
    group by cv.component_code,m.primary_skill_code
  ), w as (
    select component_code,primary_skill_code skill_code,count(*) n
    from private.exam_prep_written_tasks
    where lifecycle_state='published'
      and primary_skill_code in ('P1-COO-05','P1-COO-06','P1-DIF-05','P1-DIF-06','P1-DIF-07','P1-INT-01','P1-INT-02','P1-INT-03','P1-INT-04','P1-INT-05','P5-DAT-08','P5-DAT-09','P5-DAT-10','P5-NOR-02','P5-NOR-03','P5-NOR-04','P5-NOR-05','P5-NOR-06')
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
    raise exception 'aw21_24_reserve_publish: final annual depth mismatch rows=%',v_bad;
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4823,4824)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4823,4824)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4823,4824)
  ) then raise exception 'aw21_24_reserve_publish: learner/legacy history appeared during release transaction'; end if;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1 and rollout_state='controlled_beta' and core_enabled
      and ai_enabled=false and mentor_enabled=false and kill_switch=false
  ) then raise exception 'aw21_24_reserve_publish: feature/service boundary changed during release'; end if;
end
$postcheck$;

commit;
