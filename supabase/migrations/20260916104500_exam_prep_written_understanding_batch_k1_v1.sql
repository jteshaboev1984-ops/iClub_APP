begin;

-- Written Understanding Batch K1
-- Four learning-only interpretation tasks from audited Group B.
-- Each task receives one short concept check. The original written explanation
-- remains required and self-reviewed; no final task answer is supplied by the check.

-- P1-TRI-02: reference angle controls magnitude; original quadrant controls sign.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'k1-v1','mcq',
  'When using a reference angle to find an exact trigonometric value, what determines the sign of the final answer?',
  'При нахождении точного тригонометрического значения через опорный угол что определяет знак окончательного ответа?',
  'Tayanch burchak yordamida aniq trigonometrik qiymat topilganda yakuniy javob ishorasini nima belgilaydi?',
  '["The size of the reference angle only","The quadrant containing the original angle","Whether the angle is written in degrees","The number of terms in the expression"]'::jsonb,
  '["Только величина опорного угла","Четверть, в которой находится исходный угол","То, записан ли угол в градусах","Количество слагаемых в выражении"]'::jsonb,
  '["Faqat tayanch burchakning kattaligi","Boshlang‘ich burchak joylashgan chorak","Burchak gradusda yozilganligi","Ifodadagi hadlar soni"]'::jsonb,
  1,
  'The reference angle gives the exact magnitude. The quadrant of the original angle determines whether the relevant trigonometric value is positive or negative.',
  'Опорный угол задаёт точный модуль значения. Знак соответствующей тригонометрической функции определяется четвертью исходного угла.',
  'Tayanch burchak qiymatning aniq modulini beradi. Tegishli trigonometrik qiymatning musbat yoki manfiy bo‘lishini boshlang‘ich burchak joylashgan chorak belgilaydi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1TRI02-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-TRI-02' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-DAT-01: a mean alone cannot describe the shape/spread of a distribution.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'k1-v1','mcq',
  'Why can comparing only the means of two groups be misleading?',
  'Почему сравнение только средних значений двух групп может вводить в заблуждение?',
  'Nega ikki guruhni faqat o‘rtacha qiymatlari orqali taqqoslash noto‘g‘ri xulosa berishi mumkin?',
  '["Because a mean cannot be calculated from numerical data","Because similar means can hide important differences in spread, skewness or extreme values","Because the mean is always the smallest value in a dataset","Because two groups with different sizes must have different means"]'::jsonb,
  '["Потому что среднее нельзя вычислить по числовым данным","Потому что близкие средние могут скрывать важные различия в разбросе, асимметрии или крайних значениях","Потому что среднее всегда является наименьшим значением набора","Потому что группы разного размера обязательно имеют разные средние"]'::jsonb,
  '["Chunki sonli ma’lumotlar uchun o‘rtacha qiymatni hisoblab bo‘lmaydi","Chunki o‘xshash o‘rtacha qiymatlar tarqalish, qiyshiqlik yoki chet qiymatlardagi muhim farqlarni yashirishi mumkin","Chunki o‘rtacha qiymat har doim to‘plamdagi eng kichik qiymat bo‘ladi","Chunki hajmi turlicha bo‘lgan guruhlarning o‘rtacha qiymati albatta turlicha bo‘ladi"]'::jsonb,
  1,
  'The mean describes one aspect of location, but it does not by itself show spread, skewness or the effect of extreme observations.',
  'Среднее описывает один аспект положения данных, но само по себе не показывает разброс, асимметрию или влияние крайних наблюдений.',
  'O‘rtacha qiymat ma’lumotlarning markaziga oid bitta xususiyatni ko‘rsatadi, lekin tarqalish, qiyshiqlik yoki chet kuzatuvlar ta’sirini o‘zi ko‘rsatmaydi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5DAT01-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-DAT-01' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-DAT-08: IQR describes the spread of the middle half of observations.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'k1-v1','mcq',
  'What does a smaller interquartile range (IQR) indicate when comparing two groups?',
  'Что означает меньший межквартильный размах (IQR) при сравнении двух групп?',
  'Ikki guruh taqqoslanganda kichikroq kvartillar oralig‘i (IQR) nimani bildiradi?',
  '["The middle 50% of values are more tightly clustered","Every value in that group is larger","The group must have the higher median","There are fewer observations in the group"]'::jsonb,
  '["Средние 50% значений расположены более компактно","Каждое значение в этой группе больше","У этой группы обязательно выше медиана","В этой группе меньше наблюдений"]'::jsonb,
  '["Qiymatlarning o‘rta 50 foizi zichroq joylashgan","Bu guruhdagi har bir qiymat kattaroq","Bu guruhning medianasi albatta yuqoriroq","Bu guruhda kuzatuvlar soni kamroq"]'::jsonb,
  0,
  'IQR measures the spread of the middle 50% of the data. A smaller IQR means those central observations are less spread out.',
  'IQR измеряет разброс средних 50% данных. Меньший IQR означает, что центральная половина наблюдений разбросана меньше.',
  'IQR ma’lumotlarning o‘rta 50 foizi tarqalishini o‘lchaydi. Kichikroq IQR markaziy kuzatuvlar kamroq tarqalganini bildiradi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5DAT08-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-DAT-08' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-GEO-03: expectation is a long-run mean, not a guaranteed trial number.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'k1-v1','mcq',
  'For a geometric random variable, what does an expected trial number of 5 mean?',
  'Что означает ожидаемый номер испытания 5 для геометрической случайной величины?',
  'Geometrik tasodifiy miqdor uchun kutilayotgan sinov raqami 5 bo‘lishi nimani anglatadi?',
  '["The first success must occur on trial 5 every time","Over many repeated experiments, the trial number of the first success has a long-run average of 5","The first success cannot occur before trial 5","Exactly half of all experiments finish on trial 5"]'::jsonb,
  '["Первый успех каждый раз обязан происходить в пятом испытании","При большом числе повторений номер испытания первого успеха в среднем стремится к 5","Первый успех не может произойти раньше пятого испытания","Ровно половина всех экспериментов заканчивается на пятом испытании"]'::jsonb,
  '["Birinchi muvaffaqiyat har safar aynan 5-sinovda yuz berishi shart","Ko‘p marta takrorlanganda birinchi muvaffaqiyat sodir bo‘ladigan sinov raqamining uzoq muddatli o‘rtachasi 5 ga teng bo‘ladi","Birinchi muvaffaqiyat 5-sinovdan oldin yuz bera olmaydi","Tajribalarning aynan yarmi 5-sinovda tugaydi"]'::jsonb,
  1,
  'Expected value is a long-run average over many repetitions. Individual experiments may finish earlier or later than trial 5.',
  'Математическое ожидание — это долгосрочное среднее по многим повторениям. Отдельный эксперимент может закончиться раньше или позже пятого испытания.',
  'Kutilayotgan qiymat ko‘p takrorlashdagi uzoq muddatli o‘rtachadir. Alohida tajriba 5-sinovdan oldin ham, keyin ham tugashi mumkin.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5GEO03-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-GEO-03' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- Acceptance: exactly one QA-passed learning-only check per K1 task and no
-- answer-key/rationale leakage through learner-safe payloads.
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
    where wt.task_key in ('P1TRI02-W01','P5DAT01-W01','P5DAT08-W01','P5GEO03-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P1TRI02-W01')::int,0)<>1
     or coalesce((v_counts->>'P5DAT01-W01')::int,0)<>1
     or coalesce((v_counts->>'P5DAT08-W01')::int,0)<>1
     or coalesce((v_counts->>'P5GEO03-W01')::int,0)<>1 then
    raise exception 'written batch K1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P1TRI02-W01','P5DAT01-W01','P5DAT08-W01','P5GEO03-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch K1 contains non-QA-passed rows'; end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  join private.exam_prep_assessment_items ai on ai.written_task_id=wt.id
  join private.exam_prep_assessments a on a.id=ai.assessment_id and a.status='published'
  where wt.task_key in ('P1TRI02-W01','P5DAT01-W01','P5DAT08-W01','P5GEO03-W01')
    and c.lifecycle_state='published'
    and (a.assessment_type<>'learning' or ai.is_holdout is true);
  if v_bad<>0 then raise exception 'written batch K1 attached outside learning-only scope'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P1TRI02-W01','P5DAT01-W01','P5DAT08-W01','P5GEO03-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|all_correct|is_correct';
  if v_leak<>0 then raise exception 'written batch K1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
