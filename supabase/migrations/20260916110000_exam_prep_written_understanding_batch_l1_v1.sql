begin;

-- Written Understanding Batch L1
-- Complete the remaining learning-only tasks from audited Group B.
-- One short conceptual check per task; existing written prompts, rubrics and
-- learner history remain unchanged and written evidence stays self-reviewed.

-- P1-CIR-02: understand the inverse relationship between radius and angle at fixed arc length.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'l1-v1','mcq',
  'If the arc length s stays fixed and θ doubles, what happens to r in s=rθ?',
  'Если длина дуги s остаётся постоянной, а θ удваивается, что происходит с r в формуле s=rθ?',
  'Yoy uzunligi s o‘zgarmasa va θ ikki baravar oshsa, s=rθ formulasida r nima bo‘ladi?',
  '["r doubles","r halves","r stays the same","r becomes zero"]'::jsonb,
  '["r удваивается","r уменьшается вдвое","r не меняется","r становится равным нулю"]'::jsonb,
  '["r ikki baravar oshadi","r ikki baravar kamayadi","r o‘zgarmaydi","r nolga teng bo‘ladi"]'::jsonb,
  1,
  'With s fixed, r=s/θ. Therefore doubling θ divides the radius by 2.',
  'При постоянном s имеем r=s/θ. Поэтому удвоение θ уменьшает радиус в 2 раза.',
  's o‘zgarmasa, r=s/θ. Shuning uchun θ ikki baravar oshsa, radius 2 baravar kamayadi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1CIR02-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-CIR-02' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-DAT-06: an extreme value can distort the mean far more than the median.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'l1-v1','mcq',
  'What can one value that is much larger than the rest do when comparing the mean and median?',
  'Как одно значение, намного большее остальных, может повлиять на среднее и медиану?',
  'Qolganlaridan ancha katta bitta qiymat o‘rtacha qiymat va medianaga qanday ta’sir qilishi mumkin?',
  '["It can pull the mean upward much more than it changes the median","It must make the mean and median equal","It changes the median but cannot affect the mean","It makes both measures become the largest value"]'::jsonb,
  '["Оно может заметно увеличить среднее, тогда как медиана изменится намного меньше","Оно обязательно сделает среднее и медиану равными","Оно меняет медиану, но не может повлиять на среднее","Оно делает обе меры равными наибольшему значению"]'::jsonb,
  '["U o‘rtacha qiymatni ancha yuqoriga tortishi mumkin, mediana esa ancha kam o‘zgaradi","U o‘rtacha qiymat va medianani albatta teng qiladi","U medianani o‘zgartiradi, lekin o‘rtacha qiymatga ta’sir qilmaydi","U ikkala ko‘rsatkichni ham eng katta qiymatga teng qiladi"]'::jsonb,
  0,
  'The mean uses every value directly, so a very large observation can pull it upward. The median depends mainly on the ordered middle position and is less sensitive to one extreme value.',
  'Среднее напрямую учитывает каждое значение, поэтому очень большое наблюдение может заметно потянуть его вверх. Медиана зависит прежде всего от среднего положения в упорядоченном ряду и менее чувствительна к одному крайнему значению.',
  'O‘rtacha qiymat har bir qiymatni bevosita hisobga oladi, shuning uchun juda katta kuzatuv uni yuqoriga tortishi mumkin. Mediana esa asosan tartiblangan qatorning o‘rta o‘rniga bog‘liq va bitta chet qiymatga kamroq sezgir.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5DAT06-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-DAT-06' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- Acceptance: exactly one QA-passed learning-only check per L1 task and no
-- private evaluation metadata in learner-safe payloads.
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
    where wt.task_key in ('P1CIR02-W01','P5DAT06-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P1CIR02-W01')::int,0)<>1
     or coalesce((v_counts->>'P5DAT06-W01')::int,0)<>1 then
    raise exception 'written batch L1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P1CIR02-W01','P5DAT06-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch L1 contains non-QA-passed rows'; end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  join private.exam_prep_assessment_items ai on ai.written_task_id=wt.id
  join private.exam_prep_assessments a on a.id=ai.assessment_id and a.status='published'
  where wt.task_key in ('P1CIR02-W01','P5DAT06-W01')
    and c.lifecycle_state='published'
    and (a.assessment_type<>'learning' or ai.is_holdout is true);
  if v_bad<>0 then raise exception 'written batch L1 attached outside learning-only scope'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P1CIR02-W01','P5DAT06-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|all_correct|is_correct';
  if v_leak<>0 then raise exception 'written batch L1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
