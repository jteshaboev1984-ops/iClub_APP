-- AI-4 Economics Practice 1 deterministic diagnostic batch: Chapter 5.
-- Adds option-level diagnostics for q1090 and deterministic input diagnosis for q1116.
-- Scoring remains server-authoritative from questions.correct_answer; diagnostics only
-- explain the already-checked answer. Existing diagnostic mappings remain untouched.

do $guard$
declare
  v_bad integer;
begin
  with expected(question_id,topic,subtopic,qtype,correct_answer,options_en) as (
    values
    (1090,'PPC','Outward shift of the PPC','mcq','A','["economic growth/technology","a price ceiling","a fall in demand","higher inflation"]'::jsonb),
    (1116,'PPC','Opportunity cost on a PPC','input','2',null::jsonb)
  )
  select count(*) into v_bad
  from expected e
  left join public.questions q on q.id=e.question_id
  where q.id is null
     or q.subject_id<>7
     or q.is_active is not true
     or q.quality_status<>'published'
     or lower(coalesce(q.qtype,''))<>e.qtype
     or q.topic<>e.topic
     or q.subtopic<>e.subtopic
     or upper(trim(coalesce(q.correct_answer,'')))<>upper(e.correct_answer)
     or (e.qtype='mcq' and coalesce(q.options_text_en,'[]')::jsonb is distinct from e.options_en)
     or (e.qtype='input' and q.options_text_en is not null);

  if v_bad<>0 then
    raise exception 'AI-4 diagnostic batch refused: one or more Chapter 5 questions changed';
  end if;

  if exists (
    select 1
    from public.question_answer_diagnostics d
    where d.question_id in (1090,1116)
      and d.quality_status='published'
  ) then
    raise exception 'AI-4 diagnostic batch refused: published mappings already exist for a target question';
  end if;
end
$guard$;

insert into public.question_answer_diagnostics(
  question_id,answer_kind,answer_key,answer_value,is_correct,mistake_type,weak_skill,
  feedback_ru,feedback_uz,feedback_en,
  next_action_ru,next_action_uz,next_action_en,
  recommended_topic,recommended_subtopic,rule_json,quality_status
)
values
(1090,'mcq_option','A','economic growth/technology',true,null,null,
 'Верно: экономический рост или технологический прогресс увеличивает производственный потенциал и может сдвинуть PPC наружу.',
 'To‘g‘ri: iqtisodiy o‘sish yoki texnologik taraqqiyot ishlab chiqarish salohiyatini oshiradi va PPCni tashqariga siljitishi mumkin.',
 'Correct: economic growth or technological progress increases productive capacity and can shift the PPC outward.',
 'Свяжите сдвиг PPC с изменением количества, качества ресурсов или технологии.',
 'PPC siljishini resurslar miqdori, sifati yoki texnologiya o‘zgarishi bilan bog‘lang.',
 'Link a PPC shift to changes in the quantity or quality of resources or technology.',
 'PPC','Outward shift of the PPC','{}'::jsonb,'published'),
(1090,'mcq_option','B','a price ceiling',false,'ppc_market_intervention_confusion','PPC shifts vs market price controls',
 'Потолок цены влияет на конкретный рынок, но сам по себе не увеличивает производственный потенциал экономики.',
 'Narxning yuqori chegarasi aniq bozorga ta’sir qiladi, ammo o‘z-o‘zidan iqtisodiyotning ishlab chiqarish salohiyatini oshirmaydi.',
 'A price ceiling affects a particular market but does not by itself increase the economy’s productive capacity.',
 'Различайте изменение рыночной цены и изменение производственных возможностей.',
 'Bozor narxi o‘zgarishi bilan ishlab chiqarish imkoniyatlari o‘zgarishini farqlang.',
 'Distinguish a market-price intervention from a change in productive capacity.',
 'PPC','Outward shift of the PPC','{}'::jsonb,'published'),
(1090,'mcq_option','C','a fall in demand',false,'ppc_demand_confusion','PPC capacity vs demand conditions',
 'Падение спроса может уменьшить фактический выпуск, но не означает увеличение максимальных производственных возможностей.',
 'Talabning pasayishi amaldagi ishlab chiqarishni kamaytirishi mumkin, lekin maksimal ishlab chiqarish imkoniyatlari oshganini anglatmaydi.',
 'A fall in demand may reduce actual output, but it does not mean maximum productive capacity has increased.',
 'Отделяйте движение фактического выпуска от сдвига границы производственных возможностей.',
 'Amaldagi ishlab chiqarish o‘zgarishini ishlab chiqarish imkoniyatlari chegarasining siljishidan ajrating.',
 'Separate changes in actual output from shifts in the production possibility frontier.',
 'PPC','Outward shift of the PPC','{}'::jsonb,'published'),
(1090,'mcq_option','D','higher inflation',false,'ppc_nominal_real_confusion','Productive capacity vs price level',
 'Более высокая инфляция означает рост общего уровня цен и сама по себе не увеличивает реальную производственную мощность.',
 'Yuqori inflyatsiya umumiy narxlar darajasining oshishini bildiradi va o‘z-o‘zidan real ishlab chiqarish salohiyatini oshirmaydi.',
 'Higher inflation is a rise in the general price level and does not by itself increase real productive capacity.',
 'Ищите факторы, которые позволяют производить физически больше товаров и услуг.',
 'Jismonan ko‘proq tovar va xizmat ishlab chiqarish imkonini beradigan omillarni izlang.',
 'Look for factors that allow the economy to produce physically more goods and services.',
 'PPC','Outward shift of the PPC','{}'::jsonb,'published'),

(1116,'input_exact',null,'2',true,null,null,
 'Верно: при переходе теряется 6 единиц X и приобретается 3 единицы Y, поэтому альтернативная стоимость 1 единицы Y равна 6 ÷ 3 = 2 единицы X.',
 'To‘g‘ri: o‘tishda 6 birlik Xdan voz kechilib, 3 birlik Y olinadi, shuning uchun 1 birlik Yning muqobil xarajati 6 ÷ 3 = 2 birlik X.',
 'Correct: the move gives up 6 units of X to gain 3 units of Y, so the opportunity cost of 1 unit of Y is 6 ÷ 3 = 2 units of X.',
 'Для стоимости одной единицы делите потерянный объём на полученный.',
 'Bir birlik xarajatini topish uchun voz kechilgan miqdorni olingan miqdorga bo‘ling.',
 'For a per-unit opportunity cost, divide the amount sacrificed by the amount gained.',
 'PPC','Opportunity cost on a PPC','{"accepted":"2"}'::jsonb,'published'),
(1116,'fallback',null,null,false,'opportunity_cost_ratio_error','Opportunity cost calculation on a PPC',
 'Нужно найти стоимость одной единицы Y: потеряно 6 единиц X ради 3 единиц Y, поэтому 6 ÷ 3 = 2. Ответ должен быть только числом.',
 '1 birlik Yning xarajatini topish kerak: 3 birlik Y uchun 6 birlik Xdan voz kechilgan, demak 6 ÷ 3 = 2. Javob faqat son bo‘lishi kerak.',
 'Find the cost of one unit of Y: 6 units of X are sacrificed to gain 3 units of Y, so 6 ÷ 3 = 2. The response should contain only the number.',
 'Повторите правило: альтернативная стоимость единицы полученного блага = потерянный объём ÷ полученный объём.',
 'Qoidani takrorlang: olingan ne’matning bir birlik muqobil xarajati = voz kechilgan miqdor ÷ olingan miqdor.',
 'Review the rule: opportunity cost per unit gained = amount sacrificed ÷ amount gained.',
 'PPC','Opportunity cost on a PPC','{}'::jsonb,'published');