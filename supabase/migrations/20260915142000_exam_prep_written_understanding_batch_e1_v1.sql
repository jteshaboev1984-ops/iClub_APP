begin;

-- Written Understanding Batch E1
-- Four short checks for high-value reasoning points already required by the
-- existing written tasks. One short check per task; the original written work
-- remains required. No task, rubric, response, mastery or legacy data is changed.

-- P1-COO-03: perpendicular gradients.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'e1-v1','mcq',
  'For two non-vertical lines, which condition proves they are perpendicular?',
  'Для двух невертикальных прямых какое условие доказывает, что они перпендикулярны?',
  'Ikki vertikal bo‘lmagan chiziq uchun qaysi shart ularning perpendikulyar ekanini ko‘rsatadi?',
  '["Their gradients multiply to −1","Their gradients add to 1","Their gradients are equal","Their gradients multiply to 1"]'::jsonb,
  '["Произведение их градиентов равно −1","Сумма их градиентов равна 1","Их градиенты равны","Произведение их градиентов равно 1"]'::jsonb,
  '["Ularning gradientlari ko‘paytmasi −1 ga teng","Ularning gradientlari yig‘indisi 1 ga teng","Ularning gradientlari teng","Ularning gradientlari ko‘paytmasi 1 ga teng"]'::jsonb,
  0,
  'For non-vertical perpendicular lines, the gradients are negative reciprocals, so their product is −1.',
  'Для невертикальных перпендикулярных прямых градиенты являются противоположными обратными величинами, поэтому их произведение равно −1.',
  'Vertikal bo‘lmagan perpendikulyar chiziqlarda gradientlar qarama-qarshi teskari sonlar bo‘ladi, shuning uchun ularning ko‘paytmasi −1 ga teng.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1COO03-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-COO-03' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-FUN-08: reciprocal horizontal scale inside f(kx).
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'e1-v1','mcq',
  'If a point on y=f(x) has x-coordinate a, what is its new x-coordinate on y=f(3x)?',
  'Если точка графика y=f(x) имеет x-координату a, какой будет её новая x-координата на y=f(3x)?',
  'y=f(x) grafigidagi nuqtaning x-koordinatasi a bo‘lsa, y=f(3x) da uning yangi x-koordinatasi qanday bo‘ladi?',
  '["a/3","3a","a+3","a−3"]'::jsonb,
  '["a/3","3a","a+3","a−3"]'::jsonb,
  '["a/3","3a","a+3","a−3"]'::jsonb,
  0,
  'To reach the same old input a, the new input must satisfy 3x=a, so x=a/3.',
  'Чтобы получить прежний аргумент a, новый x должен удовлетворять 3x=a, поэтому x=a/3.',
  'Eski a argumentini olish uchun yangi x 3x=a shartini qanoatlantirishi kerak, demak x=a/3.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1FUN08-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-FUN-08' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-TRI-03: principal inverse value versus full equation solutions.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'e1-v1','mcq',
  'Why is a principal inverse-trigonometric value not automatically the full solution set of an equation?',
  'Почему главное значение обратной тригонометрической функции не является автоматически полным набором решений уравнения?',
  'Nega teskari trigonometrik funksiyaning asosiy qiymati tenglamaning barcha yechimlari bo‘lib qolmaydi?',
  '["Because the inverse function returns one value in its principal range, while the original trigonometric function is periodic and may have other solutions","Because inverse trigonometric functions have no ranges","Because every trigonometric equation has only one solution","Because principal values can only be positive"]'::jsonb,
  '["Потому что обратная функция возвращает одно значение из своего главного диапазона, а исходная тригонометрическая функция периодична и может иметь другие решения","Потому что у обратных тригонометрических функций нет диапазонов значений","Потому что любое тригонометрическое уравнение имеет только одно решение","Потому что главные значения могут быть только положительными"]'::jsonb,
  '["Chunki teskari funksiya o‘zining asosiy oralig‘idan bitta qiymat qaytaradi, asl trigonometrik funksiya esa davriy bo‘lib, boshqa yechimlarga ham ega bo‘lishi mumkin","Chunki teskari trigonometrik funksiyalarning qiymatlar oralig‘i yo‘q","Chunki har bir trigonometrik tenglamada faqat bitta yechim bo‘ladi","Chunki asosiy qiymatlar faqat musbat bo‘lishi mumkin"]'::jsonb,
  0,
  'An inverse trigonometric function returns one principal value; solving the original periodic equation can require additional symmetric or periodic solutions in the requested interval.',
  'Обратная тригонометрическая функция возвращает одно главное значение; для исходного периодического уравнения могут потребоваться дополнительные симметричные или периодические решения в заданном интервале.',
  'Teskari trigonometrik funksiya bitta asosiy qiymat qaytaradi; asl davriy tenglama uchun berilgan oraliqda qo‘shimcha simmetrik yoki davriy yechimlar ham kerak bo‘lishi mumkin.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1TRI03-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-TRI-03' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-BIN-01: four conditions for a binomial model.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'e1-v1','mcq',
  'Which list gives the key conditions for a binomial model?',
  'Какой список содержит основные условия биномиальной модели?',
  'Qaysi ro‘yxat binomial modelning asosiy shartlarini beradi?',
  '["Fixed number of trials, two outcome categories, constant success probability, independent trials","Any number of trials, three outcomes, changing probability, independent trials","Fixed number of trials, two outcomes, changing probability, dependent trials","Fixed number of trials, any number of outcomes, constant mean, independent trials"]'::jsonb,
  '["Фиксированное число испытаний, две категории исхода, постоянная вероятность успеха, независимые испытания","Любое число испытаний, три исхода, меняющаяся вероятность, независимые испытания","Фиксированное число испытаний, два исхода, меняющаяся вероятность, зависимые испытания","Фиксированное число испытаний, любое число исходов, постоянное среднее, независимые испытания"]'::jsonb,
  '["Sinovlar soni qat’iy, ikki natija toifasi, muvaffaqiyat ehtimoli doimiy, sinovlar mustaqil","Sinovlar soni ixtiyoriy, uchta natija, ehtimol o‘zgaradi, sinovlar mustaqil","Sinovlar soni qat’iy, ikki natija, ehtimol o‘zgaradi, sinovlar bog‘liq","Sinovlar soni qat’iy, natijalar soni ixtiyoriy, o‘rtacha doimiy, sinovlar mustaqil"]'::jsonb,
  0,
  'A binomial model needs fixed n, two outcome categories per trial, constant p and independent trials.',
  'Для биномиальной модели нужны фиксированное n, две категории исхода в каждом испытании, постоянная p и независимость испытаний.',
  'Binomial model uchun qat’iy n, har bir sinovda ikki natija toifasi, doimiy p va mustaqil sinovlar kerak.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5BIN01-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-BIN-01' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- Acceptance: one published check per selected task and no private evaluation
-- metadata in the learner-safe payload.
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
    where wt.task_key in ('P1COO03-W01','P1FUN08-W01','P1TRI03-W01','P5BIN01-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P1COO03-W01')::int,0)<>1
     or coalesce((v_counts->>'P1FUN08-W01')::int,0)<>1
     or coalesce((v_counts->>'P1TRI03-W01')::int,0)<>1
     or coalesce((v_counts->>'P5BIN01-W01')::int,0)<>1 then
    raise exception 'written batch E1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P1COO03-W01','P1FUN08-W01','P1TRI03-W01','P5BIN01-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch E1 contains non-QA-passed rows'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P1COO03-W01','P1FUN08-W01','P1TRI03-W01','P5BIN01-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|is_correct';
  if v_leak<>0 then raise exception 'written batch E1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
