begin;

-- Written Understanding Batch I1
-- Final curated set from the current reasoning-task audit. These checks cover
-- distinct conceptual traps not already covered by earlier companion checks.
-- One short check per task; original written work remains required and unchanged.

-- P1-SER-01: construct the required binomial term with sign and powers intact.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'i1-v1','mcq',
  'Which expression gives the x³ term in the expansion of (2−x)⁵?',
  'Какое выражение даёт член с x³ в разложении (2−x)⁵?',
  '(2−x)⁵ yoyilmasida x³ hadini qaysi ifoda beradi?',
  '["C(5,3)·2²·(−x)³","C(5,3)·2³·(−x)²","C(5,2)·2²·x³","C(5,3)·2²·x³"]'::jsonb,
  '["C(5,3)·2²·(−x)³","C(5,3)·2³·(−x)²","C(5,2)·2²·x³","C(5,3)·2²·x³"]'::jsonb,
  '["C(5,3)·2²·(−x)³","C(5,3)·2³·(−x)²","C(5,2)·2²·x³","C(5,3)·2²·x³"]'::jsonb,
  0,
  'For the x³ term, choose three factors of −x and two factors of 2, giving C(5,3)·2²·(−x)³.',
  'Для члена с x³ выбираются три множителя −x и два множителя 2, поэтому получается C(5,3)·2²·(−x)³.',
  'x³ hadi uchun uchta −x va ikkita 2 omili tanlanadi, shuning uchun C(5,3)·2²·(−x)³ hosil bo‘ladi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1SER01-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-SER-01' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-CNT-03: identical copies create overcounting in the unrestricted factorial.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'i1-v1','mcq',
  'Why do we divide 10! by 3!·3!·2! for the distinct arrangements of STATISTICS?',
  'Почему для числа различных перестановок слова STATISTICS нужно делить 10! на 3!·3!·2!?',
  'Nega STATISTICS so‘zining turli joylashuvlari uchun 10! ni 3!·3!·2! ga bo‘lamiz?',
  '["Because swapping identical copies of S, T or I does not create a new arrangement","Because the first 8 letters are fixed","Because only 3 letters may change position","Because every repeated letter must be removed from the word"]'::jsonb,
  '["Потому что перестановка одинаковых экземпляров S, T или I не создаёт нового расположения","Потому что первые 8 букв зафиксированы","Потому что только 3 буквы могут менять места","Потому что каждую повторяющуюся букву нужно удалить из слова"]'::jsonb,
  '["Chunki bir xil S, T yoki I nusxalarini o‘zaro almashtirish yangi joylashuv yaratmaydi","Chunki dastlabki 8 ta harf o‘zgarmaydi","Chunki faqat 3 ta harf joyini o‘zgartirishi mumkin","Chunki har bir takrorlangan harfni so‘zdan olib tashlash kerak"]'::jsonb,
  0,
  'The unrestricted 10! count treats identical copies as if they were different. Dividing by each repeated-letter factorial removes those duplicate counts.',
  'Подсчёт 10! ошибочно считает одинаковые экземпляры букв различными. Деление на факториал кратности каждой повторяющейся буквы убирает эти повторные подсчёты.',
  '10! hisobi bir xil harf nusxalarini turlicha deb sanaydi. Har bir takrorlangan harf sonining faktorialiga bo‘lish shu ortiqcha sanashlarni olib tashlaydi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5CNT03-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-CNT-03' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-DAT-07: translations preserve spread, scaling changes it.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'i1-v1','mcq',
  'For y=3x−7, why does −7 not change the range, IQR or standard deviation, while the factor 3 does?',
  'Для y=3x−7 почему −7 не меняет размах, IQR и стандартное отклонение, а множитель 3 меняет?',
  'y=3x−7 da nega −7 range, IQR va standart og‘ishni o‘zgartirmaydi, 3 ko‘paytuvchi esa o‘zgartiradi?',
  '["Subtracting the same number from every value leaves differences unchanged, while multiplying every value by 3 multiplies differences by 3","Subtracting 7 changes only the largest value, while multiplying by 3 changes only the smallest","Both −7 and ×3 leave every measure of spread unchanged","Subtracting 7 triples all deviations, while multiplying by 3 only shifts the centre"]'::jsonb,
  '["Вычитание одного и того же числа из всех значений не меняет разности между ними, а умножение всех значений на 3 умножает разности на 3","Вычитание 7 меняет только наибольшее значение, а умножение на 3 — только наименьшее","И −7, и ×3 не меняют ни одну меру разброса","Вычитание 7 утраивает все отклонения, а умножение на 3 только сдвигает центр"]'::jsonb,
  '["Barcha qiymatlardan bir xil sonni ayirish ularning farqlarini o‘zgartirmaydi, barcha qiymatlarni 3 ga ko‘paytirish esa farqlarni 3 baravar qiladi","7 ni ayirish faqat eng katta qiymatni, 3 ga ko‘paytirish esa faqat eng kichik qiymatni o‘zgartiradi","−7 ham, ×3 ham tarqalish o‘lchovlarini o‘zgartirmaydi","7 ni ayirish barcha og‘ishlarni 3 baravar qiladi, 3 ga ko‘paytirish esa faqat markazni siljitadi"]'::jsonb,
  0,
  'A common translation cancels when differences or deviations are formed. A scale factor remains in those differences, so spread measures scale by its magnitude.',
  'Одинаковый сдвиг сокращается при вычислении разностей и отклонений. Множитель масштаба остаётся в этих разностях, поэтому меры разброса масштабируются на его модуль.',
  'Bir xil siljish farqlar yoki og‘ishlar hisoblanganda qisqaradi. Masshtab ko‘paytuvchisi esa farqlarda qoladi, shuning uchun tarqalish o‘lchovlari uning moduliga ko‘payadi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5DAT07-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-DAT-07' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-GEO-01: without replacement breaks constant p and independence.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'i1-v1','mcq',
  'Why is drawing cards without replacement until the first heart not an ordinary geometric model?',
  'Почему выбор карт без возвращения до первой червы не является обычной геометрической моделью?',
  'Nega kartalarni qaytarmasdan birinchi yurakkacha olish oddiy geometrik model emas?',
  '["Because after each draw the composition changes, so the success probability changes and the trials are not independent","Because a geometric model can only be used with coins","Because hearts are not a success/failure outcome","Because geometric models require exactly two trials"]'::jsonb,
  '["Потому что после каждого выбора состав колоды меняется, поэтому вероятность успеха меняется и испытания не являются независимыми","Потому что геометрическую модель можно использовать только для монет","Потому что черва не может быть исходом типа успех/неуспех","Потому что геометрическая модель требует ровно двух испытаний"]'::jsonb,
  '["Chunki har bir olishdan keyin koloda tarkibi o‘zgaradi, natijada muvaffaqiyat ehtimoli o‘zgaradi va sinovlar mustaqil bo‘lmaydi","Chunki geometrik model faqat tanga uchun ishlatiladi","Chunki yurak muvaffaqiyat/muvaffaqiyatsizlik natijasi bo‘la olmaydi","Chunki geometrik model aynan ikki sinovni talab qiladi"]'::jsonb,
  0,
  'An ordinary geometric model requires independent repeated trials with constant success probability. Without replacement, the deck changes after each draw, so both conditions fail.',
  'Обычная геометрическая модель требует независимых повторных испытаний с постоянной вероятностью успеха. Без возвращения состав колоды меняется после каждого выбора, поэтому оба условия нарушаются.',
  'Oddiy geometrik model mustaqil takroriy sinovlar va doimiy muvaffaqiyat ehtimolini talab qiladi. Qaytarmasdan olishda koloda har safar o‘zgaradi, shuning uchun ikkala shart ham bajarilmaydi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5GEO01-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-GEO-01' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- Acceptance: exactly one published check per selected task and no private
-- evaluation metadata in the learner-safe payload.
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
    where wt.task_key in ('P1SER01-W01','P5CNT03-W01','P5DAT07-W01','P5GEO01-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P1SER01-W01')::int,0)<>1
     or coalesce((v_counts->>'P5CNT03-W01')::int,0)<>1
     or coalesce((v_counts->>'P5DAT07-W01')::int,0)<>1
     or coalesce((v_counts->>'P5GEO01-W01')::int,0)<>1 then
    raise exception 'written batch I1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P1SER01-W01','P5CNT03-W01','P5DAT07-W01','P5GEO01-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch I1 contains non-QA-passed rows'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P1SER01-W01','P5CNT03-W01','P5DAT07-W01','P5GEO01-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|is_correct';
  if v_leak<>0 then raise exception 'written batch I1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
