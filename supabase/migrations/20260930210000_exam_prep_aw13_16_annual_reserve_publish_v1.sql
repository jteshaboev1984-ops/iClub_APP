-- Publish the independently reviewed AW13-16 annual reserve top-up.
--
-- Adds reserve depth only:
--   +2 diagnostic, +2 isolated delayed retest, +1 mixed/transfer item per target skill.
-- No teaching pack or written task is introduced here.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare
  v_program bigint;
  v_skill record;
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if to_regprocedure('private.exam_prep_supplemental_reserve_floor_v1(bigint)') is null
     or to_regclass('private.exam_prep_content_release_profiles_v1') is null
  then raise exception 'aw13_16_reserve_publish: supplemental-reserve architecture missing'; end if;

  if (select count(*) from private.exam_prep_content_versions
      where id in (4815,4816) and status='draft')<>2
  then raise exception 'aw13_16_reserve_publish: expected two exact draft versions'; end if;

  if exists(select 1 from private.exam_prep_content_release_profiles_v1 where content_version_id in (4815,4816))
  then raise exception 'aw13_16_reserve_publish: target release profile already exists'; end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4815,4816))<>75
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4815,4816) and reserve_role='diagnostic')<>30
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4815,4816) and reserve_role='retest')<>30
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4815,4816) and reserve_role='mixed')<>15
  then raise exception 'aw13_16_reserve_publish: candidate question-role cardinality drift'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
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
  if v_bad<>0 then raise exception 'aw13_16_reserve_publish: draft QA/exposure/source snapshot drift rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id in (4815,4816)
      and (q.options_text_ru ~* '\m(or|only|cm)\M' or q.options_text_uz ~* '\m(or|only|cm)\M')
  ) then raise exception 'aw13_16_reserve_publish: untranslated learner-facing option token'; end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4815,4816)
        and m.reserve_role='diagnostic'
        and r.rule_version='aw_reserve_v1'
        and r.status='draft')<>90
  then raise exception 'aw13_16_reserve_publish: expected 90 reviewed draft diagnostic rules'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
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
    );
  if v_bad<>0 then raise exception 'aw13_16_reserve_publish: diagnostic misconception rule drift rows=%',v_bad; end if;

  if (select count(*) from private.exam_prep_assessments where content_version_id in (4815,4816) and status='draft')<>36
     or (select count(*) from private.exam_prep_assessments where content_version_id in (4815,4816) and assessment_type='diagnostic')<>4
     or (select count(*) from private.exam_prep_assessments where content_version_id in (4815,4816) and assessment_type='retest')<>30
     or (select count(*) from private.exam_prep_assessments where content_version_id in (4815,4816) and assessment_type='mixed')<>2
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id in (4815,4816))<>75
  then raise exception 'aw13_16_reserve_publish: candidate assessment cardinality drift'; end if;

  select count(*) into v_bad
  from private.exam_prep_assessment_items ai
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  join private.exam_prep_question_content_meta m on m.question_id=ai.question_id and m.content_version_id=a.content_version_id
  where a.content_version_id in (4815,4816)
    and (
      ai.question_id is null
      or ai.written_task_id is not null
      or not ai.is_holdout
      or ai.primary_skill_code<>m.primary_skill_code
      or ai.reserve_role<>m.reserve_role
      or ai.reserve_role<>a.assessment_type
      or ai.primary_skill_code not like a.component_code||'-%'
    );
  if v_bad<>0 then raise exception 'aw13_16_reserve_publish: candidate assessment role/isolation drift rows=%',v_bad; end if;

  if exists(select 1 from private.exam_prep_written_tasks where content_version_id in (4815,4816))
  then raise exception 'aw13_16_reserve_publish: reserve-only version unexpectedly contains written tasks'; end if;

  if exists(
    select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4815,4816)
  ) then raise exception 'aw13_16_reserve_publish: target draft already has learner/legacy history'; end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where lower(q.qtype)='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816);
  if (v_a,v_b,v_c,v_d,v_inputs)<>(13,12,10,10,30) then
    raise exception 'aw13_16_reserve_publish: answer-position QA drift A=% B=% C=% D=% input=%',
      v_a,v_b,v_c,v_d,v_inputs;
  end if;

  with expected(content_key,answer) as (values
    ('P1SER02-D03','D'),('P1TRI03-D02','A'),('P1TRI03-R03','113.6'),
    ('P1TRI05-D02','A'),('P1TRI05-D03','B'),
    ('P1SER01-D02','A'),('P1SER01-D03','C'),('P1SER01-R04','B'),
    ('P1CIR03-D02','A'),('P1DIF01-D02','A'),('P1TRI04-D02','A'),
    ('P5PRO06-D02','D'),('P5PRO06-D03','A'),
    ('P5DRV02-D02','B'),('P5DRV02-R04','D'),
    ('P5DRV03-D02','A'),('P5DRV03-D03','B'),('P5GEO01-R03','0')
  )
  select count(*) into v_bad
  from expected e
  left join private.exam_prep_question_content_meta m
    on m.content_key=e.content_key and m.content_version_id in (4815,4816)
  left join public.questions q on q.id=m.question_id
  where q.id is null or q.correct_answer<>e.answer;
  if v_bad<>0 then raise exception 'aw13_16_reserve_publish: independent-QA answer map mismatch rows=%',v_bad; end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'aw13_16_reserve_publish: canonical active program missing'; end if;

  for v_skill in
    select * from (values
      ('P1','P1-CIR-03'),('P1','P1-TRI-02'),('P1','P1-TRI-03'),('P1','P1-TRI-04'),('P1','P1-TRI-05'),('P1','P1-SER-01'),('P1','P1-SER-02'),('P1','P1-DIF-01'),
      ('P5','P5-PRO-05'),('P5','P5-PRO-06'),('P5','P5-DRV-01'),('P5','P5-DRV-02'),('P5','P5-DRV-03'),('P5','P5-BIN-01'),('P5','P5-GEO-01')
    ) s(component_code,skill_code)
  loop
    if not private.exam_prep_skill_content_ready_v1(v_program,v_skill.component_code,v_skill.skill_code) then
      raise exception 'aw13_16_reserve_publish: full-floor baseline not ready % %',v_skill.component_code,v_skill.skill_code;
    end if;
  end loop;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1 and rollout_state='controlled_beta' and core_enabled
      and ai_enabled=false and mentor_enabled=false and kill_switch=false
  ) then raise exception 'aw13_16_reserve_publish: expected controlled-beta Core-only boundary changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_release_profiles_v1(
  content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
)
values
  (4815,'supplemental_reserve','aw13_16_annual_reserve_release_v1',false,
   'Independent scope/math/language/technical/copyright review complete; reserve-only AW13-16 annual depth; separate fully governed baseline required.'),
  (4816,'supplemental_reserve','aw13_16_annual_reserve_release_v1',false,
   'Independent scope/math/language/technical/copyright review complete; reserve-only AW13-16 annual depth; separate fully governed baseline required.');

update private.exam_prep_diagnostic_rules r
set status='approved', approved_at=now()
from private.exam_prep_question_content_meta m
where m.id=r.content_meta_id
  and m.content_version_id in (4815,4816)
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
where content_version_id in (4815,4816)
  and lifecycle_state='draft'
  and exposure_state='withheld';

update private.exam_prep_assessments
set status='approved', approved_at=coalesce(approved_at,now())
where content_version_id in (4815,4816) and status='draft';

update private.exam_prep_content_versions
set status='approved', approved_at=coalesce(approved_at,now())
where id in (4815,4816) and status='draft';

update private.exam_prep_assessments
set status='published'
where content_version_id in (4815,4816)
  and status='approved'
  and assessment_type in ('diagnostic','retest','mixed');

do $floor_before_version_publish$
declare v1 jsonb; v2 jsonb;
begin
  v1:=private.exam_prep_supplemental_reserve_floor_v1(4815);
  v2:=private.exam_prep_supplemental_reserve_floor_v1(4816);
  if coalesce((v1->>'ready')::boolean,false) is not true
     or coalesce((v2->>'ready')::boolean,false) is not true
  then raise exception 'aw13_16_reserve_publish: supplemental reserve floor not ready P1=% P5=%',v1::text,v2::text; end if;
end
$floor_before_version_publish$;

update private.exam_prep_content_versions
set status='published', published_at=now()
where id in (4815,4816) and status='approved';

do $postcheck$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions where id in (4815,4816) and status='published')<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1
         where content_version_id in (4815,4816)
           and release_mode='supplemental_reserve'
           and profile_version='aw13_16_annual_reserve_release_v1'
           and require_written_understanding=false)<>2
  then raise exception 'aw13_16_reserve_publish: final version/profile state mismatch'; end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4815,4816)
        and lifecycle_state='reserve'
        and exposure_state='withheld'
        and copyright_status='pass'
        and qa_scope_status='pass'
        and qa_math_status='pass'
        and qa_language_status='pass'
        and qa_technical_status='pass')<>75
  then raise exception 'aw13_16_reserve_publish: final reserve question state mismatch'; end if;

  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4815,4816)
        and m.reserve_role='diagnostic'
        and r.rule_version='aw_reserve_v1'
        and r.status='approved')<>90
  then raise exception 'aw13_16_reserve_publish: final diagnostic-rule state mismatch'; end if;

  if (select count(*) from private.exam_prep_assessments
      where content_version_id in (4815,4816) and status='published')<>36
  then raise exception 'aw13_16_reserve_publish: final assessment publication mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
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
  if v_bad<>0 then raise exception 'aw13_16_reserve_publish: public source isolation/snapshot changed rows=%',v_bad; end if;

  if exists(select 1 from private.exam_prep_written_tasks where content_version_id in (4815,4816))
  then raise exception 'aw13_16_reserve_publish: final reserve version contains written tasks'; end if;

  if coalesce((private.exam_prep_supplemental_reserve_floor_v1(4815)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4816)->>'ready')::boolean,false) is not true
  then raise exception 'aw13_16_reserve_publish: final supplemental reserve floor not ready'; end if;

  with expected(component_code,skill_code) as (values
    ('P1','P1-CIR-03'),('P1','P1-TRI-02'),('P1','P1-TRI-03'),('P1','P1-TRI-04'),('P1','P1-TRI-05'),('P1','P1-SER-01'),('P1','P1-SER-02'),('P1','P1-DIF-01'),
    ('P5','P5-PRO-05'),('P5','P5-PRO-06'),('P5','P5-DRV-01'),('P5','P5-DRV-02'),('P5','P5-DRV-03'),('P5','P5-BIN-01'),('P5','P5-GEO-01')
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
        'P1-CIR-03','P1-TRI-02','P1-TRI-03','P1-TRI-04','P1-TRI-05','P1-SER-01','P1-SER-02','P1-DIF-01',
        'P5-PRO-05','P5-PRO-06','P5-DRV-01','P5-DRV-02','P5-DRV-03','P5-BIN-01','P5-GEO-01'
      )
    group by component_code,primary_skill_code
  )
  select count(*) into v_bad
  from expected e left join q using(component_code,skill_code) left join w using(component_code,skill_code)
  where coalesce(q.d,0)<>3
     or coalesce(q.l,0)+coalesce(q.x,0)<>8
     or coalesce(q.r,0)<>4
     or coalesce(w.n,0)<2;
  if v_bad<>0 then raise exception 'aw13_16_reserve_publish: final annual depth mismatch rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4815,4816)
  ) or exists(
    select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4815,4816)
  ) then raise exception 'aw13_16_reserve_publish: learner/legacy history appeared during release transaction'; end if;

  if not exists(
    select 1 from private.exam_prep_feature_config
    where id=1 and rollout_state='controlled_beta' and core_enabled
      and ai_enabled=false and mentor_enabled=false and kill_switch=false
  ) then raise exception 'aw13_16_reserve_publish: feature/service boundary changed during release'; end if;
end
$postcheck$;

commit;
