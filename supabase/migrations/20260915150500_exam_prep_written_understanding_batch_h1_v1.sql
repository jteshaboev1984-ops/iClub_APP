begin;

-- Written Understanding Batch H1
-- Four short checks for high-value probability/statistics interpretations already
-- required by the existing written tasks. One check per task; the original written
-- response remains required. No task, rubric, response, mastery or legacy data is changed.

-- P5-DRV-02: expectation is a long-run average, not a guaranteed single outcome.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'h1-v1','mcq',
  'If E(X)=2.5 for a game, what does this mean?',
  'Если для игры E(X)=2,5, что это означает?',
  'O‘yinda E(X)=2.5 bo‘lsa, bu nimani anglatadi?',
  '["Over many plays, the average net outcome is expected to approach 2.5; one play need not equal 2.5","Every single play gives exactly 2.5","The most likely single outcome must be 2.5","The game cannot produce a negative outcome"]'::jsonb,
  '["При большом числе игр средний чистый результат ожидается близким к 2,5; отдельная игра не обязана давать 2,5","Каждая отдельная игра даёт ровно 2,5","Самый вероятный отдельный результат обязательно равен 2,5","Игра не может дать отрицательный результат"]'::jsonb,
  '["Ko‘p marta o‘ynalganda o‘rtacha sof natija 2.5 ga yaqinlashishi kutiladi; bitta o‘yin natijasi 2.5 bo‘lishi shart emas","Har bir o‘yin aynan 2.5 beradi","Eng ehtimolli bitta natija albatta 2.5 bo‘ladi","O‘yin manfiy natija bera olmaydi"]'::jsonb,
  0,
  'Expectation describes the long-run average across repeated plays, not a guaranteed value on one play.',
  'Математическое ожидание описывает средний результат при большом числе повторений, а не гарантированный результат одной игры.',
  'Matematik kutilma ko‘p takrorlashdagi uzoq muddatli o‘rtacha natijani bildiradi, bitta o‘yindagi kafolatlangan natijani emas.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5DRV02-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-DRV-02' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-NOR-01: second parameter in N(mu, sigma^2) is variance.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'h1-v1','mcq',
  'For X ~ N(60,36), what is the standard deviation?',
  'Для X ~ N(60,36) чему равно стандартное отклонение?',
  'X ~ N(60,36) uchun standart og‘ish nimaga teng?',
  '["6","36","60","18"]'::jsonb,
  '["6","36","60","18"]'::jsonb,
  '["6","36","60","18"]'::jsonb,
  0,
  'In the notation N(μ,σ²), the second parameter is the variance. Here σ²=36, so σ=6.',
  'В записи N(μ,σ²) второй параметр — дисперсия. Здесь σ²=36, поэтому σ=6.',
  'N(μ,σ²) yozuvida ikkinchi parametr dispersiya bo‘ladi. Bu yerda σ²=36, demak σ=6.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5NOR01-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-NOR-01' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-PRO-05: reversing a conditional changes the denominator/sample space.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'h1-v1','mcq',
  'Why can P(B|A) and P(A|B) be different?',
  'Почему P(B|A) и P(A|B) могут быть разными?',
  'Nega P(B|A) va P(A|B) turlicha bo‘lishi mumkin?',
  '["They condition on different events, so the denominator and restricted sample space are different","Conditional probability is never calculated with an intersection","They can differ only when A and B are independent","Reversing the condition changes the intersection A∩B"]'::jsonb,
  '["Условия разные, поэтому различаются знаменатель и ограниченное пространство исходов","В условной вероятности никогда не используют пересечение","Они могут различаться только при независимости A и B","При перестановке условия меняется пересечение A∩B"]'::jsonb,
  '["Shartlar turlicha, shuning uchun maxraj va cheklangan natijalar fazosi ham turlicha","Shartli ehtimolda kesishma hech qachon ishlatilmaydi","Ular faqat A va B mustaqil bo‘lganda farq qiladi","Shartni almashtirish A∩B kesishmasini o‘zgartiradi"]'::jsonb,
  0,
  'Both probabilities use P(A∩B) in the numerator, but P(B|A) divides by P(A) while P(A|B) divides by P(B).',
  'В числителе обеих вероятностей стоит P(A∩B), но P(B|A) делится на P(A), а P(A|B) — на P(B).',
  'Ikkala ehtimolda ham surat P(A∩B), lekin P(B|A) P(A) ga, P(A|B) esa P(B) ga bo‘linadi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5PRO05-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-PRO-05' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- P5-PRO-06: tree rule: multiply along, add mutually exclusive branches.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select wt.id,1,'h1-v1','mcq',
  'In a probability tree, when do you multiply and when do you add?',
  'В дереве вероятностей когда нужно умножать, а когда складывать?',
  'Ehtimollik daraxtida qachon ko‘paytiriladi va qachon qo‘shiladi?',
  '["Multiply probabilities along one complete branch; add probabilities of mutually exclusive branches that make the required event","Add along each branch and multiply different branches","Always multiply every probability in the tree","Always add every probability in the tree"]'::jsonb,
  '["Умножайте вероятности вдоль одной полной ветви; складывайте вероятности взаимоисключающих ветвей, образующих нужное событие","Складывайте вдоль каждой ветви и умножайте разные ветви","Всегда перемножайте все вероятности дерева","Всегда складывайте все вероятности дерева"]'::jsonb,
  '["Bitta to‘liq shox bo‘ylab ehtimollarni ko‘paytiring; kerakli hodisani tashkil qiluvchi o‘zaro istisno shoxlar ehtimollarini qo‘shing","Har bir shox bo‘ylab qo‘shing va turli shoxlarni ko‘paytiring","Daraxtdagi barcha ehtimollarni har doim ko‘paytiring","Daraxtdagi barcha ehtimollarni har doim qo‘shing"]'::jsonb,
  0,
  'A path represents successive events, so its probabilities multiply. Different mutually exclusive complete paths to the same event are then added.',
  'Одна ветвь описывает последовательные события, поэтому вероятности вдоль неё перемножаются. Затем вероятности разных взаимоисключающих полных ветвей нужного события складываются.',
  'Bitta yo‘l ketma-ket hodisalarni ifodalaydi, shuning uchun undagi ehtimollar ko‘paytiriladi. Bir xil hodisaga olib keluvchi o‘zaro istisno to‘liq yo‘llar ehtimollari esa qo‘shiladi.',
  'published','pass','pass','pass',now()
from private.exam_prep_written_tasks wt
where wt.task_key='P5PRO06-W01' and wt.component_code='P5' and wt.primary_skill_code='P5-PRO-06' and wt.lifecycle_state='published'
on conflict(written_task_id,check_order,check_version) do nothing;

-- Acceptance: exactly one published check per task and no private evaluation metadata
-- appears in the learner-safe payload.
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
    where wt.task_key in ('P5DRV02-W01','P5NOR01-W01','P5PRO05-W01','P5PRO06-W01')
      and wt.lifecycle_state='published'
    group by wt.task_key
  ) q;

  if coalesce((v_counts->>'P5DRV02-W01')::int,0)<>1
     or coalesce((v_counts->>'P5NOR01-W01')::int,0)<>1
     or coalesce((v_counts->>'P5PRO05-W01')::int,0)<>1
     or coalesce((v_counts->>'P5PRO06-W01')::int,0)<>1 then
    raise exception 'written batch H1 count mismatch: %',v_counts;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key in ('P5DRV02-W01','P5NOR01-W01','P5PRO05-W01','P5PRO06-W01')
    and c.lifecycle_state='published'
    and (c.qa_math_status<>'pass' or c.qa_language_status<>'pass' or c.qa_technical_status<>'pass');
  if v_bad<>0 then raise exception 'written batch H1 contains non-QA-passed rows'; end if;

  select count(*) into v_leak
  from private.exam_prep_written_tasks wt
  where wt.task_key in ('P5DRV02-W01','P5NOR01-W01','P5PRO05-W01','P5PRO06-W01')
    and private.exam_prep_written_understanding_payload_v1(wt.id,'en')::text ~ 'correct_index|rationale|is_correct';
  if v_leak<>0 then raise exception 'written batch H1 safe payload leaked private evaluation metadata'; end if;
end $$;

commit;
