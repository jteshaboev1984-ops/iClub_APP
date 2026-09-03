-- P0-07: governed QA verdict for conservative P1 launch mapping.
-- No public.questions row is modified. Two defective legacy candidates are rejected;
-- two clean replacements are added. Mapping activates only after hard invariants pass.
-- Global Exam Prep capability remains OFF/kill-switched by P0-04.

begin;

with mv as (
  select id from private.exam_prep_question_mapping_versions
  where mapping_version='p1_existing_bank_v1' and component_code='P1' and status='draft'
), candidates(question_id,skill_code,basis) as (
  values
    (6054,'P1-COO-03','Replacement for q2721: clean tri-language perpendicular-gradient item; server evaluator verified.'),
    (2958,'P1-CIR-01','Replacement for q6089: clean tri-language radian-conversion MCQ; server evaluator verified.')
), qsrc as (
  select q.*,c.skill_code,c.basis
  from candidates c join public.questions q on q.id=c.question_id and q.subject_id=5
)
insert into private.exam_prep_question_skill_map(
  mapping_version_id,question_id,skill_code,mapping_role,approval_status,mapping_basis,
  question_snapshot_md5,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status
)
select mv.id,q.id,q.skill_code,'primary','candidate',q.basis,
       md5(concat_ws(chr(31),
         q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
         coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
         coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
         coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),
         coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),
         coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),
         coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),
         coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')
       )),
       'pending','pending','pending','pending'
from mv cross join qsrc q
on conflict(mapping_version_id,question_id,skill_code,mapping_role) do nothing;

-- Explicitly reject the two legacy candidates that failed QA. Do not mutate their question rows.
update private.exam_prep_question_skill_map m
set approval_status='rejected',
    qa_scope_status='pass',qa_math_status='pass',qa_language_status='fail',qa_technical_status='pass',
    rejection_reason='RU explanation contains an English sentence; language-equivalence gate failed. Legacy question preserved unchanged.',
    updated_at=now()
from private.exam_prep_question_mapping_versions mv
where mv.id=m.mapping_version_id and mv.mapping_version='p1_existing_bank_v1' and m.question_id=2721;

update private.exam_prep_question_skill_map m
set approval_status='rejected',
    qa_scope_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='fail',
    rejection_reason='Current safe evaluator rejects the mathematically correct fraction input 5/6; technical evaluator gate failed. Legacy question preserved unchanged.',
    updated_at=now()
from private.exam_prep_question_mapping_versions mv
where mv.id=m.mapping_version_id and mv.mapping_version='p1_existing_bank_v1' and m.question_id=6089;

-- Approve only the reviewed clean set (27 original + 2 replacements).
with approved_ids(question_id) as (
 values
 (6014),(6013),(1516),(6035),(6036),(6040),(2691),(6052),(6099),(6100),
 (6093),(6090),(2833),(2984),(3274),(2759),(6077),(6078),(6110),(6120),
 (6115),(6116),(6129),(6135),(6132),(6140),(6139),(6054),(2958)
)
update private.exam_prep_question_skill_map m
set approval_status='approved',
    qa_scope_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
    approved_at=now(),rejection_reason=null,updated_at=now()
from private.exam_prep_question_mapping_versions mv, approved_ids a
where mv.id=m.mapping_version_id and mv.mapping_version='p1_existing_bank_v1'
  and m.question_id=a.question_id;

-- Hard acceptance gate before mapping activation.
do $$
declare
  v_mv bigint;
  v_program bigint;
  v_approved int;
  v_skills int;
  v_areas int;
  v_bad int;
  v_rejected int;
begin
  select id,program_version_id into v_mv,v_program
  from private.exam_prep_question_mapping_versions
  where mapping_version='p1_existing_bank_v1' and component_code='P1' and status='draft';
  if v_mv is null then raise exception 'P0-07 mapping version draft not found'; end if;

  select count(*),count(distinct skill_code) into v_approved,v_skills
  from private.exam_prep_question_skill_map
  where mapping_version_id=v_mv and mapping_role='primary' and approval_status='approved';
  if v_approved<>29 or v_skills<>29 then
    raise exception 'P0-07 approval invariant failed approved=% skills=% expected 29/29',v_approved,v_skills;
  end if;

  select count(distinct s.official_syllabus_section) into v_areas
  from private.exam_prep_question_skill_map m
  join private.exam_prep_syllabus_nodes s on s.program_version_id=v_program and s.skill_code=m.skill_code
  where m.mapping_version_id=v_mv and m.approval_status='approved';
  if v_areas<>8 then raise exception 'P0-07 area coverage invariant failed: % expected 8',v_areas; end if;

  select count(*) into v_rejected
  from private.exam_prep_question_skill_map
  where mapping_version_id=v_mv and approval_status='rejected';
  if v_rejected<>2 then raise exception 'P0-07 rejection invariant failed: % expected 2',v_rejected; end if;

  -- Approved rows must still point at unchanged snapshots and learner-eligible legacy state.
  select count(*) into v_bad
  from private.exam_prep_question_skill_map m
  join public.questions q on q.id=m.question_id
  where m.mapping_version_id=v_mv and m.approval_status='approved'
    and (
      q.subject_id<>5 or not q.is_active or q.quality_status<>'published'
      or nullif(q.question_text_en,'') is null or nullif(q.question_text_ru,'') is null or nullif(q.question_text_uz,'') is null
      or m.question_snapshot_md5 <> md5(concat_ws(chr(31),
         q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
         coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
         coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
         coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),
         coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),
         coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),
         coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),
         coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
    );
  if v_bad<>0 then raise exception 'P0-07 approved question drift/eligibility violations=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_question_skill_map m
  join private.exam_prep_syllabus_nodes s on s.program_version_id=v_program and s.skill_code=m.skill_code
  where m.mapping_version_id=v_mv and m.approval_status='approved'
    and (s.component_code<>'P1' or m.qa_scope_status<>'pass' or m.qa_math_status<>'pass'
      or m.qa_language_status<>'pass' or m.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'P0-07 component/QA firewall violations=%',v_bad; end if;

  -- Explicit scope exclusions must never appear in the approved launch map.
  select count(*) into v_bad
  from private.exam_prep_question_skill_map m join public.questions q on q.id=m.question_id
  where m.mapping_version_id=v_mv and m.approval_status='approved'
    and (lower(coalesce(q.topic,''))='further trigonometry'
      or lower(coalesce(q.subtopic,'')) like '%modulus%'
      or lower(coalesce(q.subtopic,'')) like '%approximation%');
  if v_bad<>0 then raise exception 'P0-07 out-of-scope approved rows=%',v_bad; end if;

  -- P0-04 kill switch must remain hard-OFF while content mapping activates administratively.
  select count(*) into v_bad from private.exam_prep_feature_config
  where id=1 and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch);
  if v_bad<>0 then raise exception 'P0-07 capability gate is not OFF'; end if;

  update private.exam_prep_question_mapping_versions
  set status='active',activated_at=now()
  where id=v_mv;
end;
$$;

commit;
