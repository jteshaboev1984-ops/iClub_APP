begin;

-- Written Understanding Batch F1
-- Four short checks for conceptual points already required by the existing
-- written tasks. One check per task; the learner still completes the original
-- written solution. No task, rubric, response, mastery or legacy data is changed.

-- P1-COO-06: two equivalent tangency tests.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'f1-v1','mcq',
  'Which pair of facts both indicates that a line is tangent to a circle?',
  'Какая пара условий указывает на то, что прямая является касательной к окружности?',
  'Qaysi ikki shart chiziq aylanaga urinma ekanini ko‘rsatadi?',
  '["Substitution gives a repeated root, and the perpendicular distance from the centre to the line equals the radius","Substitution gives two distinct roots, and the distance from the centre is less than the radius","Substitution gives no real roots, and the distance from the centre equals zero","The quadratic has any real roots, and the distance from the centre is greater than the radius"]'::jsonb,
  '["После подстановки получается кратный корень, а перпендикулярное расстояние от центра до прямой равно радиусу","После подстановки получаются два различных корня, а расстояние от центра меньше радиуса","После подстановки нет действительных корней, а расстояние от центра равно нулю","Квадратное уравнение имеет любые действительные корни, а расстояние от центра больше радиуса"]'::jsonb,
  '["Qo‘yishdan keyin takroriy ildiz hosil bo‘ladi va markazdan chiziqqacha perpendikulyar masofa radiusga teng","Qo‘yishdan keyin ikkita turli ildiz hosil bo‘ladi va markazdan masofa radiusdan kichik","Qo‘yishdan keyin haqiqiy ildiz yo‘q va markazdan masofa nolga teng","Kvadrat tenglama istalgan haqiqiy ildizlarga ega va markazdan masofa radiusdan katta"]'::jsonb,
  0,
  'A tangent meets the circle at exactly one point, giving a repeated root after substitution; geometrically, the centre-to-line distance equals the radius.',
  'Касательная имеет с окружностью ровно одну общую точку, поэтому после подстановки получается кратный корень; геометрически расстояние от центра до прямой равно радиусу.',
  'Urinma aylana bilan aynan bitta umumiy nuqtaga ega, shuning uchun qo‘yishdan keyin takroriy ildiz chiqadi; geometrik jihatdan markazdan chiziqqacha masofa radiusga teng.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1COO06-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-COO-06' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-FUN-05: fixed points of reflection in y=x.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'f1-v1','mcq',
  'A point stays fixed when reflected in y=x. What must be true?',
  'Точка не меняется при отражении относительно y=x. Что обязательно верно?',
  'Nuqta y=x ga nisbatan akslantirilganda o‘zgarmaydi. Qaysi shart albatta bajariladi?',
  '["Its coordinates are equal: x=y","Its x-coordinate is zero","Its y-coordinate is zero","Its coordinates are opposites: x=−y"]'::jsonb,
  '["Её координаты равны: x=y","Её x-координата равна нулю","Её y-координата равна нулю","Её координаты противоположны: x=−y"]'::jsonb,
  '["Uning koordinatalari teng: x=y","Uning x-koordinatasi nol","Uning y-koordinatasi nol","Uning koordinatalari qarama-qarshi: x=−y"]'::jsonb,
  0,
  'Reflection in y=x swaps the coordinates. A point is unchanged only when swapping does nothing, so x=y.',
  'Отражение относительно y=x меняет координаты местами. Точка остаётся на месте только тогда, когда x=y.',
  'y=x ga nisbatan akslantirish koordinatalarni o‘rin almashtiradi. Nuqta faqat x=y bo‘lganda o‘zgarmaydi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1FUN05-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-FUN-05' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-BIN-02: complement for at least one success.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'f1-v1','mcq',
  'Which is the simplest complement form for P(X≥1)?',
  'Как удобнее всего записать P(X≥1) через дополнение?',
  'P(X≥1) ni to‘ldiruvchi hodisa orqali eng sodda qanday yozish mumkin?',
  '["1−P(X=0)","1−P(X=1)","P(X=0)","P(X≤1)"]'::jsonb,
  '["1−P(X=0)","1−P(X=1)","P(X=0)","P(X≤1)"]'::jsonb,
  '["1−P(X=0)","1−P(X=1)","P(X=0)","P(X≤1)"]'::jsonb,
  0,
  'The complement of at least one success is no successes, so P(X≥1)=1−P(X=0).',
  'Дополнение события «хотя бы один успех» — «ни одного успеха», поэтому P(X≥1)=1−P(X=0).',
  '“Kamida bitta muvaffaqiyat” hodisasining to‘ldiruvchisi “muvaffaqiyat yo‘q”, shuning uchun P(X≥1)=1−P(X=0).',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5BIN02-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-BIN-02' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-CNT-02: labelled positions mean order matters and choices decrease.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'f1-v1','mcq',
  'Why is 7×6×5×4 the correct product for placing 4 of 7 distinct books into 4 labelled positions without repetition?',
  'Почему произведение 7×6×5×4 подходит для размещения 4 из 7 разных книг на 4 подписанных местах без повторений?',
  'Nega 7 ta turli kitobdan 4 tasini takrorlamasdan 4 ta nomlangan o‘ringa joylashtirish uchun 7×6×5×4 to‘g‘ri ko‘paytma?',
  '["Each labelled position is a different choice, and after each placement one fewer unused book remains","Order does not matter, so every position always has 7 choices","Books may be reused, so the number of choices stays 7","Only the final position matters"]'::jsonb,
  '["Каждое подписанное место — отдельный выбор, и после каждого размещения остаётся на одну неиспользованную книгу меньше","Порядок не важен, поэтому для каждого места всегда есть 7 вариантов","Книги можно повторно использовать, поэтому число вариантов всегда остаётся 7","Имеет значение только последнее место"]'::jsonb,
  '["Har bir nomlangan o‘rin alohida tanlov, har bir joylashtirishdan keyin ishlatilmagan kitoblar soni bittaga kamayadi","Tartib muhim emas, shuning uchun har bir o‘rinda doim 7 ta tanlov bor","Kitoblarni qayta ishlatish mumkin, shuning uchun tanlovlar soni 7 bo‘lib qoladi","Faqat oxirgi o‘rin muhim"]'::jsonb,
  0,
  'The positions are labelled, so assignments are ordered. Without repetition the available choices decrease from 7 to 6 to 5 to 4.',
  'Места подписаны, поэтому назначения упорядочены. Без повторений число доступных книг уменьшается: 7, затем 6, 5 и 4.',
  'O‘rinlar nomlangan, shuning uchun joylashtirishda tartib muhim. Takrorlanmasdan mavjud kitoblar soni 7 dan 6, 5 va 4 gacha kamayadi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5CNT02-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-CNT-02' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- Acceptance: exactly one published check for each selected task and no private
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
    where wt.task_key in ('P1COO06-W01','P1FUN05-W01','P5BIN02-W01','P5CNT02-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P1COO06-W01')::int,0)<>1
     or coalesce((v_counts->>'P1FUN05-W01')::int,0)<>1
     or coalesce((v_counts->>'P5BIN02-W01')::int,0)<>1
     or coalesce((v_counts->>'P5CNT02-W01')::int,0)<>1 then
    raise exception 'written batch F1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P1COO06-W01','P1FUN05-W01','P5BIN02-W01','P5CNT02-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch F1 contains non-QA-passed rows'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P1COO06-W01','P1FUN05-W01','P5BIN02-W01','P5CNT02-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|is_correct';
  if v_leak<>0 then raise exception 'written batch F1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
