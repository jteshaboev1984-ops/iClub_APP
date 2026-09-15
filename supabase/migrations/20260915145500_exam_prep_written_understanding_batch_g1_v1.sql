begin;

-- Written Understanding Batch G1
-- Four short checks for conceptual traps already present in the existing written
-- tasks. One check per task; the original written solution remains required.
-- No task, rubric, response, mastery or legacy data is changed.

-- P1-DIF-01: simplify for h != 0 before taking h -> 0.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'g1-v1','mcq',
  'In the limit definition of a derivative, why should you not substitute h=0 before simplifying the difference quotient?',
  'Почему в определении производной через предел нельзя подставлять h=0 до упрощения разностного отношения?',
  'Hosilaning limit ta’rifida nega ayirmali nisbatni soddalashtirishdan oldin h=0 qo‘yib bo‘lmaydi?',
  '["Because the quotient still contains division by h; simplify for h≠0 first, then take the limit as h→0","Because h must always stay positive","Because substituting h=0 changes x into 0","Because limits can only be used after differentiating"]'::jsonb,
  '["Потому что в выражении ещё есть деление на h; сначала нужно упростить при h≠0, затем взять предел при h→0","Потому что h всегда должно оставаться положительным","Потому что подстановка h=0 превращает x в 0","Потому что предел можно использовать только после дифференцирования"]'::jsonb,
  '["Chunki ifodada hali h ga bo‘lish bor; avval h≠0 da soddalashtirib, keyin h→0 limitini olish kerak","Chunki h har doim musbat bo‘lishi kerak","Chunki h=0 qo‘yish x ni 0 ga aylantiradi","Chunki limitni faqat hosila topilgandan keyin ishlatish mumkin"]'::jsonb,
  0,
  'Before cancellation the difference quotient is undefined at h=0. The algebra is simplified for h≠0, and only then is the limit taken as h approaches 0.',
  'До сокращения разностное отношение не определено при h=0. Выражение упрощают при h≠0 и только затем берут предел при h→0.',
  'Qisqartirishdan oldin ayirmali nisbat h=0 da aniqlanmagan. Ifoda h≠0 da soddalashtiriladi va shundan keyin h→0 limiti olinadi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1DIF01-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-DIF-01' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-FUN-06: inside subtraction causes a right shift.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'g1-v1','mcq',
  'Why does y=f(x−2) move the graph of y=f(x) two units to the right?',
  'Почему y=f(x−2) сдвигает график y=f(x) на 2 единицы вправо?',
  'Nega y=f(x−2) grafigi y=f(x) grafigini 2 birlik o‘ngga siljitadi?',
  '["To give f the same old input a, the new x must satisfy x−2=a, so x=a+2","Because subtracting 2 always moves every graph left","Because all y-values increase by 2","Because x−2 changes the range, not the input"]'::jsonb,
  '["Чтобы функция f получила прежний аргумент a, новый x должен удовлетворять x−2=a, поэтому x=a+2","Потому что вычитание 2 всегда сдвигает любой график влево","Потому что все значения y увеличиваются на 2","Потому что x−2 меняет область значений, а не аргумент"]'::jsonb,
  '["f funksiyasi eski a argumentini olishi uchun yangi x x−2=a shartini bajarishi kerak, demak x=a+2","Chunki 2 ni ayirish har qanday grafikni chapga siljitadi","Chunki barcha y qiymatlar 2 ga oshadi","Chunki x−2 argumentni emas, qiymatlar oralig‘ini o‘zgartiradi"]'::jsonb,
  0,
  'The change is inside the input. A point that used to occur at input a now occurs when x−2=a, so its new x-coordinate is a+2.',
  'Изменение находится внутри аргумента функции. Точка, которая раньше соответствовала аргументу a, теперь получается при x−2=a, поэтому её новая x-координата равна a+2.',
  'O‘zgarish funksiya argumenti ichida. Oldin a argumentida bo‘lgan nuqta endi x−2=a bo‘lganda hosil bo‘ladi, shuning uchun yangi x-koordinata a+2 ga teng.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1FUN06-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-FUN-06' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-INT-03: an improper endpoint integral can still converge.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'g1-v1','mcq',
  'Why can ∫ from 0 to 9 of x^(−1/2) dx be finite even though x^(−1/2) is undefined at x=0?',
  'Почему интеграл ∫ от 0 до 9 x^(−1/2) dx может быть конечным, хотя x^(−1/2) не определена при x=0?',
  'Nega x^(−1/2) funksiya x=0 da aniqlanmagan bo‘lsa ham, 0 dan 9 gacha ∫x^(−1/2)dx integral chekli bo‘lishi mumkin?',
  '["It is treated as an improper integral, and the antiderivative 2√x has a finite limit as x→0+","An undefined endpoint is always ignored","The integrand becomes zero at x=0","Every integral over a finite interval is automatically finite"]'::jsonb,
  '["Его рассматривают как несобственный интеграл, а первообразная 2√x имеет конечный предел при x→0+","Неопределённую конечную точку всегда просто игнорируют","Подынтегральная функция становится равной нулю при x=0","Любой интеграл на конечном интервале автоматически конечен"]'::jsonb,
  '["U xosmas integral sifatida qaraladi va 2√x boshlang‘ich funksiyasi x→0+ da chekli limitga ega","Aniqlanmagan chegara nuqtasi har doim shunchaki e’tiborsiz qoldiriladi","Integral ostidagi funksiya x=0 da nol bo‘ladi","Chekli oraliqdagi har bir integral avtomatik ravishda chekli bo‘ladi"]'::jsonb,
  0,
  'Replace the endpoint 0 by a>0, evaluate using 2√x, and take a→0+. The resulting limit is finite, so the improper integral converges.',
  'Конечную точку 0 временно заменяют на a>0, вычисляют через 2√x и затем берут предел при a→0+. Предел конечен, поэтому несобственный интеграл сходится.',
  '0 chegara vaqtincha a>0 bilan almashtiriladi, 2√x orqali hisoblanadi va keyin a→0+ limiti olinadi. Limit chekli bo‘lgani uchun xosmas integral yaqinlashadi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1INT03-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-INT-03' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-DAT-04: histogram area represents frequency for unequal class widths.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'g1-v1','mcq',
  'Why should frequency density, rather than raw frequency, be used as histogram height when class widths are unequal?',
  'Почему при разных ширинах интервалов высотой столбца гистограммы должна быть плотность частоты, а не сама частота?',
  'Nega sinf kengliklari teng bo‘lmaganda gistogramma balandligi sifatida oddiy chastota emas, chastota zichligi ishlatiladi?',
  '["Because bar area must represent frequency, so height = frequency ÷ class width","Because every histogram bar must have the same height","Because frequency is only used for continuous data","Because class width must equal frequency"]'::jsonb,
  '["Потому что частоту должна представлять площадь столбца, поэтому высота = частота ÷ ширина интервала","Потому что все столбцы гистограммы должны иметь одинаковую высоту","Потому что частоту используют только для непрерывных данных","Потому что ширина интервала должна быть равна частоте"]'::jsonb,
  '["Chunki chastotani ustun yuzasi ifodalashi kerak, shuning uchun balandlik = chastota ÷ sinf kengligi","Chunki gistogrammadagi barcha ustunlar bir xil balandlikda bo‘lishi kerak","Chunki chastota faqat uzluksiz ma’lumotlarda ishlatiladi","Chunki sinf kengligi chastotaga teng bo‘lishi kerak"]'::jsonb,
  0,
  'In a histogram the area of each bar represents frequency. With unequal class widths, using frequency density as height keeps area = width × density = frequency.',
  'В гистограмме частоту представляет площадь столбца. При разных ширинах использование плотности частоты сохраняет равенство: площадь = ширина × плотность = частота.',
  'Gistogrammada chastotani ustun yuzasi ifodalaydi. Sinf kengliklari turlicha bo‘lsa, chastota zichligi balandlik sifatida ishlatilganda yuza = kenglik × zichlik = chastota bo‘lib qoladi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5DAT04-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-DAT-04' and wt.lifecycle_state='published'
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
    where wt.task_key in ('P1DIF01-W01','P1FUN06-W01','P1INT03-W01','P5DAT04-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P1DIF01-W01')::int,0)<>1
     or coalesce((v_counts->>'P1FUN06-W01')::int,0)<>1
     or coalesce((v_counts->>'P1INT03-W01')::int,0)<>1
     or coalesce((v_counts->>'P5DAT04-W01')::int,0)<>1 then
    raise exception 'written batch G1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P1DIF01-W01','P1FUN06-W01','P1INT03-W01','P5DAT04-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch G1 contains non-QA-passed rows'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P1DIF01-W01','P1FUN06-W01','P1INT03-W01','P5DAT04-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|is_correct';
  if v_leak<>0 then raise exception 'written batch G1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
