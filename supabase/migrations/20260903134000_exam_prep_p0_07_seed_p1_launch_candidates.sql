-- P0-07: seed conservative P1 launch mapping candidates.
-- Existing public.questions rows are read-only; this migration creates additive references only.
-- All rows remain candidate/pending. Mapping version remains DRAFT, so learner eligibility stays zero.

begin;

with mv as (
  select id
  from private.exam_prep_question_mapping_versions
  where mapping_version='p1_existing_bank_v1' and component_code='P1' and status='draft'
), candidates(question_id,skill_code,basis) as (
  values
    (6014,'P1-QUA-01','Exact legacy subtopic match: Completing the square.'),
    (6013,'P1-QUA-02','Exact legacy subtopic match: Discriminant.'),
    (1516,'P1-QUA-03','Exact legacy subtopic match: Quadratic equations.'),
    (6035,'P1-FUN-03','Exact legacy subtopic match: Composite functions.'),
    (6036,'P1-FUN-04','Exact legacy subtopic match: Inverse function.'),
    (6040,'P1-FUN-08','Exact legacy subtopic match: Combined transformations.'),
    (2691,'P1-COO-01','Exact legacy subtopic match: Equation of line.'),
    (2721,'P1-COO-03','Exact legacy subtopic match: Perpendicular line.'),
    (6052,'P1-COO-04','Exact legacy subtopic match: Circle centre and radius.'),
    (6089,'P1-CIR-01','Exact legacy subtopic match: Radian measure.'),
    (6099,'P1-CIR-02','Exact legacy subtopic match: Arc length.'),
    (6100,'P1-CIR-03','Exact legacy subtopic match: Sector area.'),
    (6093,'P1-TRI-01','Legacy P1 Trigonometry graph item; explicit exclusion of Further trigonometry.'),
    (6090,'P1-TRI-02','Exact legacy subtopic match: Exact values in P1 Trigonometry.'),
    (2833,'P1-TRI-04','Legacy P1 Trigonometry identity item; explicit exclusion of Further trigonometry.'),
    (2984,'P1-TRI-05','Legacy P1 Trigonometry equation item; explicit exclusion of Further trigonometry.'),
    (3274,'P1-SER-01','Legacy Binomial expansion coefficient item; excludes post-P1 approximation items.'),
    (2759,'P1-SER-03','Exact legacy subtopic match: sum of AP.'),
    (6077,'P1-SER-04','Exact legacy subtopic match: Sum of a geometric series.'),
    (6078,'P1-SER-05','Exact legacy subtopic match: Infinite sum.'),
    (6110,'P1-DIF-02','Exact legacy subtopic match: Power rule.'),
    (6120,'P1-DIF-03','Exact legacy subtopic match: Chain rule.'),
    (6115,'P1-DIF-04','Exact legacy subtopic match: Equation of a tangent.'),
    (6116,'P1-DIF-07','Exact legacy subtopic match: Stationary points; checked against canonical P1 scope.'),
    (6129,'P1-INT-01','Exact legacy subtopic match: Indefinite integration.'),
    (6135,'P1-INT-02','Exact legacy subtopic match: Finding a curve from its derivative.'),
    (6132,'P1-INT-03','Exact legacy subtopic match: Definite integration.'),
    (6140,'P1-INT-04','Exact legacy subtopic match: Area between two curves.'),
    (6139,'P1-INT-05','Exact legacy subtopic match: Volume of revolution.')
), qsrc as (
  select q.*, c.skill_code, c.basis
  from candidates c
  join public.questions q on q.id=c.question_id and q.subject_id=5
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

-- Fail if source inventory drifted and the full intended candidate set was not inserted/present.
do $$
declare v_count int;
begin
  select count(*) into v_count
  from private.exam_prep_question_skill_map m
  join private.exam_prep_question_mapping_versions mv on mv.id=m.mapping_version_id
  where mv.mapping_version='p1_existing_bank_v1' and m.mapping_role='primary';
  if v_count <> 29 then
    raise exception 'P0-07 candidate seed invariant failed: got %, expected 29',v_count;
  end if;
end;
$$;

commit;
