begin;

-- Written Understanding Batch A1
-- Keep the learner screen light: only one or two short deterministic checks per
-- task, followed by the learner's existing written explanation. These checks are
-- non-crediting support evidence under the established written-understanding v1
-- contract. Existing task prompts, rubrics, responses and mastery are untouched.

-- P1-QUA-02: no real roots => discriminant < 0.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'a1-v1','mcq',
  'For a quadratic equation to have no real roots, what must be true of its discriminant?',
  'Какое условие на дискриминант означает, что квадратное уравнение не имеет действительных корней?',
  'Kvadrat tenglama haqiqiy ildizga ega bo‘lmasligi uchun diskriminant qanday bo‘lishi kerak?',
  '["Δ < 0","Δ = 0","Δ > 0","Δ ≤ 0"]'::jsonb,
  '["Δ < 0","Δ = 0","Δ > 0","Δ ≤ 0"]'::jsonb,
  '["Δ < 0","Δ = 0","Δ > 0","Δ ≤ 0"]'::jsonb,
  0,
  'A negative discriminant means there are no real roots.',
  'Отрицательный дискриминант означает, что действительных корней нет.',
  'Manfiy diskriminant haqiqiy ildizlar yo‘qligini bildiradi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1QUA02-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-QUA-02' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-QUA-02: boundary case.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,2,'a1-v1','mcq',
  'At the boundary value c = 9, what happens to x² + 6x + c = 0?',
  'Что происходит с уравнением x² + 6x + c = 0 при граничном значении c = 9?',
  'c = 9 chegara qiymatida x² + 6x + c = 0 tenglamada nima sodir bo‘ladi?',
  '["It has two distinct real roots","It has one repeated real root","It has no real roots","Every real x is a root"]'::jsonb,
  '["Есть два различных действительных корня","Есть один повторяющийся действительный корень","Действительных корней нет","Любое действительное x является корнем"]'::jsonb,
  '["Ikki xil haqiqiy ildiz bor","Bitta takroriy haqiqiy ildiz bor","Haqiqiy ildiz yo‘q","Har qanday haqiqiy x ildiz bo‘ladi"]'::jsonb,
  1,
  'At c = 9 the discriminant is 0, so the quadratic has one repeated real root.',
  'При c = 9 дискриминант равен 0, поэтому квадратное уравнение имеет один повторяющийся действительный корень.',
  'c = 9 da diskriminant 0 ga teng, shuning uchun kvadrat tenglama bitta takroriy haqiqiy ildizga ega.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1QUA02-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-QUA-02' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-QUA-04: inclusive endpoints for <=.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'a1-v1','mcq',
  'Why are x = 1 and x = 4 included in the solution?',
  'Почему x = 1 и x = 4 входят в решение?',
  'Nega x = 1 va x = 4 yechimga kiradi?',
  '["Because ≤ allows equality and the product is 0 at both endpoints","Because every quadratic inequality includes its roots","Because the product is positive at both endpoints","Because 1 and 4 are the midpoint values"]'::jsonb,
  '["Потому что знак ≤ допускает равенство, а в обеих граничных точках произведение равно 0","Потому что любое квадратное неравенство включает свои корни","Потому что в обеих граничных точках произведение положительно","Потому что 1 и 4 являются средними значениями"]'::jsonb,
  '["≤ belgisi tenglikka ruxsat beradi va ikkala chegara nuqtasida ko‘paytma 0 ga teng","Har qanday kvadrat tengsizlik o‘z ildizlarini yechimga kiritadi","Ikkala chegara nuqtasida ko‘paytma musbat","1 va 4 o‘rta qiymatlar bo‘lgani uchun"]'::jsonb,
  0,
  'The symbol ≤ includes equality, and each endpoint makes one factor zero, so the product is 0.',
  'Знак ≤ включает равенство, и в каждой граничной точке один из множителей равен нулю, поэтому произведение равно 0.',
  '≤ belgisi tenglikni ham o‘z ichiga oladi; har bir chegara nuqtasida ko‘paytuvchilardan biri 0 bo‘ladi, shuning uchun ko‘paytma 0 ga teng.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1QUA04-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-QUA-04' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-FUN-01: why x^2 is one-one after restricting x >= 0.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'a1-v1','mcq',
  'Why is g(x) = x² one-one when its domain is restricted to x ≥ 0?',
  'Почему g(x) = x² является взаимно однозначной при ограничении области x ≥ 0?',
  'Nega g(x) = x² funksiya x ≥ 0 sohada bir-biriga bir qiymatli bo‘ladi?',
  '["Different nonnegative inputs have different squares","Every squared value is positive","The graph crosses the y-axis once","The domain contains infinitely many values"]'::jsonb,
  '["Разные неотрицательные аргументы дают разные квадраты","Любой квадрат положителен","График пересекает ось y один раз","В области определения бесконечно много значений"]'::jsonb,
  '["Turli manfiy bo‘lmagan kirish qiymatlari turli kvadratlarni beradi","Har qanday kvadrat musbat bo‘ladi","Grafik y o‘qini bir marta kesadi","Aniqlanish sohasida cheksiz ko‘p qiymat bor"]'::jsonb,
  0,
  'On x ≥ 0, different inputs give different squares, so each output comes from at most one input.',
  'При x ≥ 0 разные аргументы дают разные квадраты, поэтому каждому значению функции соответствует не более одного аргумента.',
  'x ≥ 0 da turli kirish qiymatlari turli kvadratlarni beradi, shuning uchun har bir chiqish qiymatiga ko‘pi bilan bitta kirish mos keladi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1FUN01-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-FUN-01' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-FUN-03: composition order and domain restrictions matter.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'a1-v1','mcq',
  'Which fact is enough to show that f∘g and g∘f are not the same function here?',
  'Какой факт достаточно показывает, что f∘g и g∘f здесь не являются одной и той же функцией?',
  'Bu yerda f∘g va g∘f bir xil funksiya emasligini qaysi fakt yetarli ko‘rsatadi?',
  '["They have different simplified formulas and different forbidden inputs","They both use the same two functions","Both expressions contain x","Both functions are defined using algebra"]'::jsonb,
  '["У них разные упрощённые формулы и разные запрещённые значения аргумента","В обеих используются те же две функции","Оба выражения содержат x","Обе функции заданы алгебраически"]'::jsonb,
  '["Ularning soddalashtirilgan formulalari va taqiqlangan kirish qiymatlari turlicha","Ikkalasida ham bir xil ikki funksiya ishlatiladi","Ikkala ifodada ham x bor","Ikkala funksiya ham algebraik ko‘rinishda berilgan"]'::jsonb,
  0,
  'Composition order changes the resulting formula and, in this task, the domain restriction as well.',
  'Порядок композиции меняет итоговую формулу, а в этой задаче также и ограничение области определения.',
  'Kompozitsiya tartibi yakuniy formulani, bu masalada esa aniqlanish sohasi cheklovini ham o‘zgartiradi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1FUN03-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-FUN-03' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- Acceptance: this batch is intentionally small and screen-light.
do $$
declare
  v_counts jsonb;
  v_bad int;
  v_leak int;
begin
  select jsonb_object_agg(task_key,cnt order by task_key) into v_counts
  from (
    select wt.task_key,count(c.id)::int as cnt
    from private.exam_prep_written_tasks wt
    left join private.exam_prep_written_understanding_checks c
      on c.written_task_id=wt.id and c.lifecycle_state='published'
    where wt.task_key in ('P1QUA02-W01','P1QUA04-W01','P1FUN01-W01','P1FUN03-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P1QUA02-W01')::int,0)<>2
     or coalesce((v_counts->>'P1QUA04-W01')::int,0)<>1
     or coalesce((v_counts->>'P1FUN01-W01')::int,0)<>1
     or coalesce((v_counts->>'P1FUN03-W01')::int,0)<>1 then
    raise exception 'written batch A1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P1QUA02-W01','P1QUA04-W01','P1FUN01-W01','P1FUN03-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch A1 contains non-QA-passed rows'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P1QUA02-W01','P1QUA04-W01','P1FUN01-W01','P1FUN03-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|is_correct';
  if v_leak<>0 then raise exception 'written batch A1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
