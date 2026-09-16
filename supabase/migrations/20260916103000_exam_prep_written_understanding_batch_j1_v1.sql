begin;

-- Written Understanding Batch J1
-- Four remaining learning-only reasoning tasks from the audited Group A set.
-- One short conceptual check per task; existing prompts, rubrics and learner history
-- remain unchanged. Companion results stay app-checked, non-crediting support evidence.

-- P1-FUN-02: a closed-interval range needs endpoint values and any turning point inside.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'j1-v1','mcq',
  'To determine the full range of a quadratic on a closed interval, which values should be compared?',
  'Чтобы найти область значений квадратичной функции на замкнутом отрезке, какие значения нужно сравнить?',
  'Kvadrat funksiyaning yopiq oraliqdagi barcha qiymatlarini topish uchun qaysi qiymatlarni taqqoslash kerak?',
  '["Only the two endpoint values","The turning-point value, if its x-value lies in the interval, and both endpoint values","Only the x-coordinate of the turning point","The gradients at the two endpoints"]'::jsonb,
  '["Только значения на двух концах отрезка","Значение в вершине, если её x-координата лежит в отрезке, и значения на обоих концах","Только x-координату вершины","Градиенты на двух концах отрезка"]'::jsonb,
  '["Faqat oraliqning ikki chetidagi qiymatlarni","Agar uchining x-koordinatasi oraliqda bo‘lsa, uchdagi qiymatni va ikkala chetdagi qiymatlarni","Faqat uchining x-koordinatasini","Oraliqning ikki chetidagi gradientlarni"]'::jsonb,
  1,
  'On a closed interval, extreme function values can occur at the endpoints or at an interior turning point. Those candidate values must be compared.',
  'На замкнутом отрезке крайние значения функции могут достигаться на концах или во внутренней вершине. Поэтому нужно сравнить все эти значения-кандидаты.',
  'Yopiq oraliqda funksiyaning eng katta yoki eng kichik qiymati chetlarda yoki oraliq ichidagi burilish nuqtasida bo‘lishi mumkin. Shu sababli barcha nomzod qiymatlar taqqoslanadi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1FUN02-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-FUN-02' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-CNT-05: the chair is a distinct role; the other committee places are unordered.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'j1-v1','mcq',
  'Why is the chair counted as a distinct role while the other three committee members are treated as an unordered selection?',
  'Почему председатель считается отдельной ролью, а трое остальных членов комитета выбираются без учёта порядка?',
  'Nega rais alohida rol sifatida hisoblanadi, qolgan uch a’zo esa tartibsiz tanlanadi?',
  '["Because the chair is chosen earlier in time","Because the chair has a distinct position, while the other three have equal roles and their internal order does not matter","Because combinations can only be used after permutations","Because the committee size changes after the chair is chosen"]'::jsonb,
  '["Потому что председателя выбирают раньше по времени","Потому что у председателя отдельная роль, а у трёх остальных роли одинаковы и их внутренний порядок не важен","Потому что сочетания можно использовать только после перестановок","Потому что после выбора председателя меняется размер комитета"]'::jsonb,
  '["Chunki rais vaqt bo‘yicha oldinroq tanlanadi","Chunki raisning roli alohida, qolgan uch a’zoning roli esa bir xil va ularning ichki tartibi ahamiyatli emas","Chunki kombinatsiyalarni faqat permutatsiyalardan keyin ishlatish mumkin","Chunki rais tanlangandan keyin qo‘mita hajmi o‘zgaradi"]'::jsonb,
  1,
  'The chair position distinguishes one selected person. The remaining three positions are equivalent, so rearranging those three people does not create a new committee.',
  'Роль председателя выделяет одного выбранного человека. Три остальные позиции равноправны, поэтому перестановка этих трёх людей не создаёт новый комитет.',
  'Rais lavozimi tanlangan odamlardan birini alohida ajratadi. Qolgan uch o‘rin teng, shuning uchun bu uch kishining o‘zaro tartibini almashtirish yangi qo‘mita yaratmaydi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5CNT05-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-CNT-05' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-NOR-06: the standard normal-approximation check is large expected successes/failures.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'j1-v1','mcq',
  'For a binomial distribution, which quantities should be sufficiently large before using a normal approximation?',
  'Для биномиального распределения какие величины должны быть достаточно большими, чтобы использовать нормальное приближение?',
  'Binomial taqsimot uchun normal yaqinlashuvdan foydalanishdan oldin qaysi kattaliklar yetarlicha katta bo‘lishi kerak?',
  '["n only","p and 1−p only","np and n(1−p)","The mean and standard deviation must both be integers"]'::jsonb,
  '["Только n","Только p и 1−p","np и n(1−p)","Среднее и стандартное отклонение обязательно должны быть целыми числами"]'::jsonb,
  '["Faqat n","Faqat p va 1−p","np va n(1−p)","O‘rtacha qiymat va standart og‘ish ikkalasi ham butun son bo‘lishi kerak"]'::jsonb,
  2,
  'A normal approximation to a binomial distribution is justified when the expected numbers of successes and failures, np and n(1−p), are both sufficiently large.',
  'Нормальное приближение биномиального распределения обосновано, когда ожидаемые числа успехов и неуспехов, np и n(1−p), оба достаточно велики.',
  'Binomial taqsimotni normal taqsimot bilan yaqinlashtirish uchun kutilayotgan muvaffaqiyatlar soni np va muvaffaqiyatsizliklar soni n(1−p) ikkalasi ham yetarlicha katta bo‘lishi kerak.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5NOR06-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-NOR-06' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-PRO-01: fairness plus independence makes each ordered product outcome 1/8.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'j1-v1','mcq',
  'Why are the eight coin-and-spinner outcomes equiprobable?',
  'Почему восемь исходов «монета и спиннер» равновероятны?',
  'Nega tanga va spinnerning sakkizta natijasi teng ehtimolli?',
  '["Because there are eight outcomes, so they must automatically have equal probability","Because the fair coin and fair spinner are independent, so each ordered pair has probability 1/2 × 1/4 = 1/8","Because each spinner number appears twice in the written sample space","Because tails is as likely as any one spinner number"]'::jsonb,
  '["Потому что исходов восемь, значит их вероятности автоматически равны","Потому что честная монета и честный спиннер независимы, поэтому каждая упорядоченная пара имеет вероятность 1/2 × 1/4 = 1/8","Потому что каждое число спиннера дважды встречается в записанном пространстве исходов","Потому что решка имеет ту же вероятность, что и любое отдельное число спиннера"]'::jsonb,
  '["Chunki sakkizta natija bor, shuning uchun ularning ehtimollari avtomatik ravishda teng","Chunki adolatli tanga va adolatli spinner mustaqil, shuning uchun har bir tartibli juftlik ehtimoli 1/2 × 1/4 = 1/8","Chunki spinnerdagi har bir son yozilgan natijalar fazosida ikki marta uchraydi","Chunki gerb tushmasligi spinnerdagi istalgan bitta son bilan bir xil ehtimolga ega"]'::jsonb,
  1,
  'Fairness gives probabilities 1/2 for each coin result and 1/4 for each spinner result. Independence lets us multiply them, so every ordered pair has probability 1/8.',
  'Честность даёт вероятность 1/2 для каждого исхода монеты и 1/4 для каждого исхода спиннера. Из-за независимости вероятности перемножаются, поэтому каждая упорядоченная пара имеет вероятность 1/8.',
  'Adolatlilik tanga natijalarining har biriga 1/2 va spinner natijalarining har biriga 1/4 ehtimol beradi. Mustaqillik sababli ular ko‘paytiriladi va har bir tartibli juftlik ehtimoli 1/8 bo‘ladi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5PRO01-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-PRO-01' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- Acceptance: one published QA-passed check per J1 task, learning-only placement,
-- and learner-safe payloads without answer keys or rationales.
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
    where wt.task_key in ('P1FUN02-W01','P5CNT05-W01','P5NOR06-W01','P5PRO01-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P1FUN02-W01')::int,0)<>1
     or coalesce((v_counts->>'P5CNT05-W01')::int,0)<>1
     or coalesce((v_counts->>'P5NOR06-W01')::int,0)<>1
     or coalesce((v_counts->>'P5PRO01-W01')::int,0)<>1 then
    raise exception 'written batch J1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P1FUN02-W01','P5CNT05-W01','P5NOR06-W01','P5PRO01-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch J1 contains non-QA-passed rows'; end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  join private.exam_prep_assessment_items ai on ai.written_task_id=wt.id
  join private.exam_prep_assessments a on a.id=ai.assessment_id and a.status='published'
  where wt.task_key in ('P1FUN02-W01','P5CNT05-W01','P5NOR06-W01','P5PRO01-W01')
    and c.lifecycle_state='published'
    and (a.assessment_type<>'learning' or ai.is_holdout is true);
  if v_bad<>0 then raise exception 'written batch J1 attached outside learning-only scope'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P1FUN02-W01','P5CNT05-W01','P5NOR06-W01','P5PRO01-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|all_correct|is_correct';
  if v_leak<>0 then raise exception 'written batch J1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
