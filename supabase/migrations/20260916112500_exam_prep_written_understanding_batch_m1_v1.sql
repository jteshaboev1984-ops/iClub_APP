begin;

-- Written Understanding Batch M1
-- Three learning-only Group C tasks where a short companion can test a general
-- prerequisite principle without supplying the task-specific result or replacing
-- the learner's written/sign-chart/proof method. Existing prompts, rubrics and
-- learner history remain unchanged; written evidence stays self-reviewed.

-- P1-DIF-05: derivative sign controls monotonicity; the learner still builds the
-- actual sign chart and determines the task-specific intervals.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'m1-v1','mcq',
  'If f′(x)>0 throughout an interval, what does this tell you about f on that interval?',
  'Если f′(x)>0 на всём промежутке, что это означает для функции f на этом промежутке?',
  'Agar butun oraliqda f′(x)>0 bo‘lsa, bu f funksiya haqida nimani bildiradi?',
  '["f is increasing","f is decreasing","f is constant","f must have a maximum inside the interval"]'::jsonb,
  '["f возрастает","f убывает","f постоянна","внутри промежутка обязательно есть максимум"]'::jsonb,
  '["f o‘sadi","f kamayadi","f o‘zgarmas","oraliq ichida albatta maksimum bor"]'::jsonb,
  0,
  'A positive derivative means the function is increasing on that interval. A negative derivative would indicate decreasing behaviour.',
  'Положительная производная означает, что функция возрастает на этом промежутке. Отрицательная производная означала бы убывание.',
  'Musbat hosila funksiya shu oraliqda o‘sishini bildiradi. Manfiy hosila esa kamayishni bildiradi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1DIF05-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-DIF-05' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-DIF-07: second-derivative test supplies only the generic maximum criterion;
-- the learner still models, differentiates, proves and calculates the actual case.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'m1-v1','mcq',
  'At a stationary point x=a, which second-derivative condition shows that the point is a local maximum?',
  'В стационарной точке x=a какое условие для второй производной показывает, что это локальный максимум?',
  'x=a statsionar nuqtada qaysi ikkinchi hosila sharti bu nuqta lokal maksimum ekanini ko‘rsatadi?',
  '["f′′(a)<0","f′′(a)>0","f′′(a)=1","f′(a)>0"]'::jsonb,
  '["f′′(a)<0","f′′(a)>0","f′′(a)=1","f′(a)>0"]'::jsonb,
  '["f′′(a)<0","f′′(a)>0","f′′(a)=1","f′(a)>0"]'::jsonb,
  0,
  'If f′(a)=0 and f′′(a)<0, the graph is locally concave down at the stationary point, so the point is a local maximum.',
  'Если f′(a)=0 и f′′(a)<0, график в стационарной точке локально вогнут вниз, поэтому точка является локальным максимумом.',
  'Agar f′(a)=0 va f′′(a)<0 bo‘lsa, grafik statsionar nuqta atrofida pastga egilgan bo‘ladi, shuning uchun bu nuqta lokal maksimumdir.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1DIF07-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-DIF-07' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P1-TRI-04: validate proof method only. The check does not supply the identity
-- substitution, simplification or denominator restrictions required by the task.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'m1-v1','mcq',
  'Which approach is valid when proving a trigonometric identity?',
  'Какой подход является корректным при доказательстве тригонометрического тождества?',
  'Trigonometrik ayniyatni isbotlashda qaysi usul to‘g‘ri?',
  '["Start from one side and use known identities and valid algebra until it becomes the other side","Assume the two sides are equal and simplify both at the same time","Check one numerical angle and treat that as a proof","Cancel any matching factor even when it may be zero"]'::jsonb,
  '["Начать с одной части и с помощью известных тождеств и корректных алгебраических преобразований получить другую часть","Сразу считать обе части равными и одновременно упрощать их","Проверить один числовой угол и считать это доказательством","Сокращать любой одинаковый множитель, даже если он может быть равен нулю"]'::jsonb,
  '["Bir tomondan boshlab, ma’lum ayniyatlar va to‘g‘ri algebraik o‘zgartirishlar orqali ikkinchi tomonga kelish","Ikki tomonni avvaldan teng deb olib, ikkalasini bir vaqtda soddalashtirish","Bitta sonli burchakni tekshirib, buni isbot deb qabul qilish","Bir xil ko‘paytuvchini nol bo‘lishi mumkin bo‘lsa ham qisqartirish"]'::jsonb,
  0,
  'A proof should transform one side by established identities and valid algebra until it matches the other side, while respecting where each expression is defined.',
  'В доказательстве нужно преобразовывать одну часть с помощью известных тождеств и корректной алгебры, пока она не совпадёт с другой, учитывая область допустимых значений выражений.',
  'Isbotda bir tomonni ma’lum ayniyatlar va to‘g‘ri algebra orqali ikkinchi tomonga teng shaklga keltirish kerak, bunda ifodalar qayerda aniqlanganini ham hisobga olish zarur.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P1TRI04-W01' and wt.component_code='P1' and wt.primary_skill_code='P1-TRI-04' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- Acceptance: one QA-passed learning-only check per M1 task and no private
-- evaluation metadata in learner-safe payloads.
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
    where wt.task_key in ('P1DIF05-W01','P1DIF07-W01','P1TRI04-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P1DIF05-W01')::int,0)<>1
     or coalesce((v_counts->>'P1DIF07-W01')::int,0)<>1
     or coalesce((v_counts->>'P1TRI04-W01')::int,0)<>1 then
    raise exception 'written batch M1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P1DIF05-W01','P1DIF07-W01','P1TRI04-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch M1 contains non-QA-passed rows'; end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  join private.exam_prep_assessment_items ai on ai.written_task_id=wt.id
  join private.exam_prep_assessments a on a.id=ai.assessment_id and a.status='published'
  where wt.task_key in ('P1DIF05-W01','P1DIF07-W01','P1TRI04-W01')
    and c.lifecycle_state='published'
    and (a.assessment_type<>'learning' or ai.is_holdout is true);
  if v_bad<>0 then raise exception 'written batch M1 attached outside learning-only scope'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P1DIF05-W01','P1DIF07-W01','P1TRI04-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|all_correct|is_correct';
  if v_leak<>0 then raise exception 'written batch M1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
