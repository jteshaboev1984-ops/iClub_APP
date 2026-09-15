begin;

-- Written Understanding Batch B1
-- Three short P5 checks, one per written task. The check only verifies the core
-- mathematical reason already required by the task; the learner still completes
-- the existing calculations and written explanation. No task, rubric, response,
-- mastery or legacy record is rewritten.

-- P5-DRV-01: both validity conditions for a discrete probability distribution.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'b1-v1','mcq',
  'Which statement gives both conditions for a valid discrete probability distribution?',
  'Какое утверждение содержит оба условия корректного дискретного распределения вероятностей?',
  'Qaysi javob diskret ehtimollik taqsimotining ikkala to‘g‘rilik shartini beradi?',
  '["Every probability is between 0 and 1, and all probabilities add to 1","Every probability is positive, and the values of X add to 1","Every probability is below 1, and the mean is 1","All values of X are nonnegative, and the probabilities are different"]'::jsonb,
  '["Каждая вероятность находится от 0 до 1, и сумма всех вероятностей равна 1","Каждая вероятность положительна, и сумма значений X равна 1","Каждая вероятность меньше 1, и среднее равно 1","Все значения X неотрицательны, и вероятности различны"]'::jsonb,
  '["Har bir ehtimollik 0 dan 1 gacha bo‘ladi va barcha ehtimolliklar yig‘indisi 1 ga teng","Har bir ehtimollik musbat bo‘ladi va X qiymatlari yig‘indisi 1 ga teng","Har bir ehtimollik 1 dan kichik bo‘ladi va o‘rtacha qiymat 1 ga teng","Barcha X qiymatlari manfiy emas va ehtimolliklar har xil"]'::jsonb,
  0,
  'A valid discrete probability distribution has probabilities in [0,1] and total probability 1.',
  'В корректном дискретном распределении каждая вероятность лежит в [0,1], а их сумма равна 1.',
  'To‘g‘ri diskret ehtimollik taqsimotida har bir ehtimollik [0,1] oralig‘ida bo‘ladi va ularning yig‘indisi 1 ga teng.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5DRV01-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-DRV-01' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-DRV-03: variance is an expectation of squared deviations.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'b1-v1','mcq',
  'Why can a valid variance not be negative?',
  'Почему корректная дисперсия не может быть отрицательной?',
  'Nega to‘g‘ri dispersiya manfiy bo‘la olmaydi?',
  '["Variance is based on squared deviations, which cannot be negative","Variance is always equal to the mean","Every value of a random variable must be positive","Standard deviation is added before variance is found"]'::jsonb,
  '["Дисперсия основана на квадратах отклонений, которые не могут быть отрицательными","Дисперсия всегда равна среднему","Любое значение случайной величины должно быть положительным","Перед вычислением дисперсии прибавляют стандартное отклонение"]'::jsonb,
  '["Dispersiya og‘ishlarning kvadratlariga asoslanadi, ular manfiy bo‘la olmaydi","Dispersiya har doim o‘rtacha qiymatga teng","Tasodifiy miqdorning har bir qiymati musbat bo‘lishi kerak","Dispersiyani topishdan oldin standart og‘ish qo‘shiladi"]'::jsonb,
  0,
  'Variance is the expected value of squared deviations from the mean, so it cannot be negative.',
  'Дисперсия — это математическое ожидание квадратов отклонений от среднего, поэтому она не может быть отрицательной.',
  'Dispersiya o‘rtacha qiymatdan og‘ishlar kvadratining matematik kutilmasi bo‘lgani uchun manfiy bo‘la olmaydi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5DRV03-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-DRV-03' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-BIN-03: Var(X)/E(X) = np(1-p)/(np) = 1-p.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'b1-v1','mcq',
  'For X ~ Bin(n,p), why does variance ÷ mean reveal 1−p?',
  'Для X ~ Bin(n,p) почему дисперсия ÷ среднее даёт 1−p?',
  'X ~ Bin(n,p) uchun nega dispersiya ÷ o‘rtacha qiymat 1−p ni beradi?',
  '["Because np(1−p) ÷ np = 1−p","Because np ÷ np(1−p) = 1−p","Because the mean and variance are always equal","Because n cancels and p becomes n"]'::jsonb,
  '["Потому что np(1−p) ÷ np = 1−p","Потому что np ÷ np(1−p) = 1−p","Потому что среднее и дисперсия всегда равны","Потому что n сокращается, а p превращается в n"]'::jsonb,
  '["Chunki np(1−p) ÷ np = 1−p","Chunki np ÷ np(1−p) = 1−p","Chunki o‘rtacha qiymat va dispersiya har doim teng","Chunki n qisqaradi va p n ga aylanadi"]'::jsonb,
  0,
  'For a binomial variable, E(X)=np and Var(X)=np(1−p), so their ratio is 1−p.',
  'Для биномиальной величины E(X)=np и Var(X)=np(1−p), поэтому их отношение равно 1−p.',
  'Binomial tasodifiy miqdor uchun E(X)=np va Var(X)=np(1−p), shuning uchun ularning nisbati 1−p ga teng.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5BIN03-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-BIN-03' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- Acceptance: exactly one visible short check per task and no safe-payload key leak.
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
    where wt.task_key in ('P5DRV01-W01','P5DRV03-W01','P5BIN03-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P5DRV01-W01')::int,0)<>1
     or coalesce((v_counts->>'P5DRV03-W01')::int,0)<>1
     or coalesce((v_counts->>'P5BIN03-W01')::int,0)<>1 then
    raise exception 'written batch B1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P5DRV01-W01','P5DRV03-W01','P5BIN03-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch B1 contains non-QA-passed rows'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P5DRV01-W01','P5DRV03-W01','P5BIN03-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|is_correct';
  if v_leak<>0 then raise exception 'written batch B1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
