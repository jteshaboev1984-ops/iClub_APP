begin;

-- Written Understanding Batch C1
-- Four short checks for core ideas already required by the existing written tasks.
-- One check per task. Existing prompts, rubrics, responses, mastery and legacy data
-- remain unchanged. The learner still completes the original written work.

-- P1-SER-02: distinguish arithmetic and geometric sequences by the invariant used.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'c1-v1','mcq',
  'Which statement correctly distinguishes arithmetic and geometric sequences?',
  'Какое утверждение правильно различает арифметическую и геометрическую последовательности?',
  'Qaysi javob arifmetik va geometrik ketma-ketliklarni to‘g‘ri farqlaydi?',
  '["Arithmetic sequences have a constant difference; geometric sequences have a constant ratio","Arithmetic sequences have a constant ratio; geometric sequences have a constant difference","Both must have a constant difference","Both must have a constant ratio"]'::jsonb,
  '["У арифметической последовательности постоянна разность, у геометрической — отношение","У арифметической последовательности постоянно отношение, у геометрической — разность","У обеих должна быть постоянная разность","У обеих должно быть постоянное отношение"]'::jsonb,
  '["Arifmetik ketma-ketlikda ayirma doimiy, geometrik ketma-ketlikda nisbat doimiy","Arifmetik ketma-ketlikda nisbat doimiy, geometrik ketma-ketlikda ayirma doimiy","Ikkalasida ham ayirma doimiy bo‘lishi kerak","Ikkalasida ham nisbat doimiy bo‘lishi kerak"]'::jsonb,
  0,
  'Arithmetic sequences are identified by a constant difference, while geometric sequences are identified by a constant ratio.',
  'Арифметическую последовательность определяет постоянная разность, а геометрическую — постоянное отношение.',
  'Arifmetik ketma-ketlik doimiy ayirma bilan, geometrik ketma-ketlik esa doimiy nisbat bilan aniqlanadi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1SER02-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-SER-02' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-SER-05: convergence condition for an infinite geometric series.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'c1-v1','mcq',
  'When does an infinite geometric series converge?',
  'Когда бесконечный геометрический ряд сходится?',
  'Cheksiz geometrik qator qachon yaqinlashadi?',
  '["When |r| < 1","When r > 1","When r = 1","Whenever the first term is positive"]'::jsonb,
  '["Когда |r| < 1","Когда r > 1","Когда r = 1","Всегда, если первый член положительный"]'::jsonb,
  '["|r| < 1 bo‘lganda","r > 1 bo‘lganda","r = 1 bo‘lganda","Birinchi had musbat bo‘lsa har doim"]'::jsonb,
  0,
  'An infinite geometric series converges exactly when the magnitude of its common ratio is less than 1.',
  'Бесконечный геометрический ряд сходится тогда и только тогда, когда модуль его знаменателя меньше 1.',
  'Cheksiz geometrik qator umumiy nisbatining moduli 1 dan kichik bo‘lgandagina yaqinlashadi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1SER05-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-SER-05' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-GEO-02: use a complement for a cumulative geometric event.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'c1-v1','mcq',
  'Which complement identity is correct for P(X≤4)?',
  'Какое равенство с дополнением верно для P(X≤4)?',
  'P(X≤4) uchun qaysi to‘ldiruvchi tenglik to‘g‘ri?',
  '["P(X≤4)=1−P(X>4)","P(X≤4)=1−P(X=4)","P(X≤4)=P(X>4)","P(X≤4)=1−P(X<4)"]'::jsonb,
  '["P(X≤4)=1−P(X>4)","P(X≤4)=1−P(X=4)","P(X≤4)=P(X>4)","P(X≤4)=1−P(X<4)"]'::jsonb,
  '["P(X≤4)=1−P(X>4)","P(X≤4)=1−P(X=4)","P(X≤4)=P(X>4)","P(X≤4)=1−P(X<4)"]'::jsonb,
  0,
  'The complement of X≤4 is X>4, so their probabilities add to 1.',
  'Дополнение события X≤4 — это X>4, поэтому сумма их вероятностей равна 1.',
  'X≤4 hodisasining to‘ldiruvchisi X>4 bo‘ladi, shuning uchun ularning ehtimolliklari yig‘indisi 1 ga teng.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5GEO02-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-GEO-02' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-PRO-04: numerical criterion for independence.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'c1-v1','mcq',
  'Which equality can be used to test whether A and B are independent?',
  'Какое равенство можно использовать, чтобы проверить независимость A и B?',
  'A va B hodisalarning mustaqilligini tekshirish uchun qaysi tenglikdan foydalaniladi?',
  '["P(A∩B)=P(A)P(B)","P(A∩B)=P(A)+P(B)","P(A|B)=P(A)+P(B)","P(A∪B)=P(A)P(B)"]'::jsonb,
  '["P(A∩B)=P(A)P(B)","P(A∩B)=P(A)+P(B)","P(A|B)=P(A)+P(B)","P(A∪B)=P(A)P(B)"]'::jsonb,
  '["P(A∩B)=P(A)P(B)","P(A∩B)=P(A)+P(B)","P(A|B)=P(A)+P(B)","P(A∪B)=P(A)P(B)"]'::jsonb,
  0,
  'For independent events, the probability of their intersection equals the product of their probabilities.',
  'Для независимых событий вероятность пересечения равна произведению их вероятностей.',
  'Mustaqil hodisalar uchun ularning kesishish ehtimoli ehtimolliklar ko‘paytmasiga teng.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5PRO04-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-PRO-04' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- Acceptance: exactly one published check for each selected task and no private
-- evaluation metadata appears in the safe learner payload.
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
    where wt.task_key in ('P1SER02-W01','P1SER05-W01','P5GEO02-W01','P5PRO04-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P1SER02-W01')::int,0)<>1
     or coalesce((v_counts->>'P1SER05-W01')::int,0)<>1
     or coalesce((v_counts->>'P5GEO02-W01')::int,0)<>1
     or coalesce((v_counts->>'P5PRO04-W01')::int,0)<>1 then
    raise exception 'written batch C1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P1SER02-W01','P1SER05-W01','P5GEO02-W01','P5PRO04-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch C1 contains non-QA-passed rows'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P1SER02-W01','P1SER05-W01','P5GEO02-W01','P5PRO04-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|is_correct';
  if v_leak<>0 then raise exception 'written batch C1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
