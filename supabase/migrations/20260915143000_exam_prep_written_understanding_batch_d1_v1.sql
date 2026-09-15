begin;

-- Written Understanding Batch D1
-- Four short checks for core reasoning already required by the existing tasks.
-- One check per task. Existing prompts, rubrics, responses, mastery and legacy data
-- remain unchanged. The learner still completes the original written work.

-- P1-INT-04: total geometric area requires splitting where the sign changes.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'d1-v1','mcq',
  'If a curve crosses the x-axis, how should total geometric area be found?',
  'Если график пересекает ось x, как найти полную геометрическую площадь?',
  'Grafik x-o‘qini kesib o‘tsa, umumiy geometrik yuza qanday topiladi?',
  '["Split at the x-intercepts and add the positive areas","Use one signed integral across the whole interval","Ignore the parts below the x-axis","Subtract every area from the first one"]'::jsonb,
  '["Разбить область в точках пересечения с осью x и сложить положительные площади","Взять один интеграл со знаком на всём промежутке","Не учитывать части ниже оси x","Вычесть все площади из первой"]'::jsonb,
  '["x-o‘q bilan kesishish nuqtalarida bo‘lib, musbat yuzalarni qo‘shish","Butun oraliqda bitta ishorali integral olish","x-o‘qdan pastdagi qismlarni hisobga olmaslik","Barcha yuzalarni birinchi yuzadan ayirish"]'::jsonb,
  0,
  'Total geometric area counts every region positively, so the interval must be split where the curve changes sign.',
  'Полная геометрическая площадь учитывает каждую область положительно, поэтому промежуток нужно разбить там, где функция меняет знак.',
  'Umumiy geometrik yuzada har bir qism musbat olinadi, shuning uchun funksiya ishora almashtiradigan nuqtalarda oraliq bo‘linadi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1INT04-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-INT-04' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-CNT-01: order matters when distinct roles are assigned.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'d1-v1','mcq',
  'When should permutations be used instead of combinations?',
  'Когда следует использовать размещения, а не сочетания?',
  'Qachon kombinatsiya o‘rniga joylashtirish ishlatiladi?',
  '["When different roles or positions make order matter","Whenever the group has more than two people","Only when repetition is allowed","Whenever the total number is even"]'::jsonb,
  '["Когда разные роли или позиции делают порядок важным","Когда в группе больше двух человек","Только когда разрешены повторения","Когда общее число чётное"]'::jsonb,
  '["Turli rollar yoki o‘rinlar sabab tartib muhim bo‘lganda","Guruhda ikki kishidan ko‘p bo‘lsa","Faqat takrorlashga ruxsat berilganda","Umumiy son juft bo‘lganda"]'::jsonb,
  0,
  'Permutations are used when assigning the same selected people to different roles creates different outcomes.',
  'Размещения используются, когда распределение одних и тех же выбранных людей по разным ролям даёт разные исходы.',
  'Bir xil tanlangan odamlarni turli rollarga joylashtirish turli natijalar bersa, joylashtirish ishlatiladi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5CNT01-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-CNT-01' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-CNT-04: use the unrestricted total minus the together cases.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'d1-v1','mcq',
  'How can the number of arrangements where A and B are not together be found most directly?',
  'Как проще всего найти число перестановок, где A и B не стоят рядом?',
  'A va B yonma-yon bo‘lmagan joylashuvlar sonini eng to‘g‘ri qanday topish mumkin?',
  '["All arrangements minus the arrangements where A and B are together","The together arrangements minus all arrangements","Only count arrangements starting with A","Divide the together arrangements by 2"]'::jsonb,
  '["Из общего числа перестановок вычесть случаи, где A и B стоят рядом","Из случаев, где A и B рядом, вычесть общее число перестановок","Считать только перестановки, начинающиеся с A","Разделить число случаев, где A и B рядом, на 2"]'::jsonb,
  '["Barcha joylashuvlardan A va B yonma-yon bo‘lgan joylashuvlarni ayirish","A va B yonma-yon bo‘lgan joylashuvlardan barcha joylashuvlarni ayirish","Faqat A bilan boshlanadigan joylashuvlarni sanash","A va B yonma-yon bo‘lgan joylashuvlar sonini 2 ga bo‘lish"]'::jsonb,
  0,
  'Together and not-together are disjoint cases that cover all unrestricted arrangements, so the complement is total minus together.',
  'Случаи «рядом» и «не рядом» не пересекаются и вместе дают все перестановки, поэтому используется дополнение: всего минус «рядом».',
  '“Yonma-yon” va “yonma-yon emas” holatlari kesishmaydi va barcha joylashuvlarni qamrab oladi, shuning uchun to‘ldiruvchi usul: jami minus “yonma-yon”.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5CNT04-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-CNT-04' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-PRO-02: combinations match an unordered sample space.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'d1-v1','mcq',
  'Why are combinations appropriate when four students are simply selected from a class?',
  'Почему при простом выборе четырёх учеников из класса подходят сочетания?',
  'Nega sinfdan shunchaki 4 o‘quvchi tanlanganda kombinatsiyalar mos keladi?',
  '["Because the order in which the same four students are selected does not change the group","Because every student must be selected more than once","Because order always matters in probability","Because combinations can only be used with two categories"]'::jsonb,
  '["Потому что порядок выбора одних и тех же четырёх учеников не меняет состав группы","Потому что каждого ученика нужно выбрать больше одного раза","Потому что в вероятности порядок всегда важен","Потому что сочетания можно использовать только для двух категорий"]'::jsonb,
  '["Chunki ayni 4 o‘quvchini qaysi tartibda tanlash guruhni o‘zgartirmaydi","Chunki har bir o‘quvchi bir necha marta tanlanishi kerak","Chunki ehtimollikda tartib har doim muhim","Chunki kombinatsiyalar faqat ikki toifa bilan ishlatiladi"]'::jsonb,
  0,
  'A four-student selection is an unordered subset: changing the selection order does not create a new outcome.',
  'Выбор четырёх учеников — это неупорядоченное подмножество: изменение порядка выбора не создаёт новый исход.',
  '4 o‘quvchini tanlash tartibsiz to‘plamdir: tanlash tartibini o‘zgartirish yangi natija yaratmaydi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5PRO02-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-PRO-02' and wt.lifecycle_state='published'
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
    where wt.task_key in ('P1INT04-W01','P5CNT01-W01','P5CNT04-W01','P5PRO02-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P1INT04-W01')::int,0)<>1
     or coalesce((v_counts->>'P5CNT01-W01')::int,0)<>1
     or coalesce((v_counts->>'P5CNT04-W01')::int,0)<>1
     or coalesce((v_counts->>'P5PRO02-W01')::int,0)<>1 then
    raise exception 'written batch D1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P1INT04-W01','P5CNT01-W01','P5CNT04-W01','P5PRO02-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch D1 contains non-QA-passed rows'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P1INT04-W01','P5CNT01-W01','P5CNT04-W01','P5PRO02-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|is_correct';
  if v_leak<>0 then raise exception 'written batch D1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
