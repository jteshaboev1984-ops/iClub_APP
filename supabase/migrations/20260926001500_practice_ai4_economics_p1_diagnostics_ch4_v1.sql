-- AI-4 Economics Practice 1 deterministic diagnostic batch: Chapter 4.
-- Adds option-level deterministic explanations for five already-published MCQs.
-- Scoring remains server-authoritative from questions.correct_answer; these rows only
-- classify the learner's selected option after checking. Existing diagnostic mappings remain untouched.

do $guard$
declare
  v_bad integer;
begin
  with expected(question_id,topic,subtopic,correct_answer,options_en) as (
    values
    (1102,'Systems','Price mechanism and resource allocation','A','["Higher prices signal scarcity and encourage producers to supply more while reducing quantity demanded","Government sets quotas for all goods","Prices do not affect choices","Only tradition determines allocation"]'::jsonb),
    (1109,'Systems','Rationing methods','A','["Price rations by willingness/ability to pay; queues ration by time cost","Queues always create surpluses; prices always create shortages","Both methods are identical in effects","Queues eliminate opportunity cost"]'::jsonb),
    (1122,'Systems','Rationing by queue','D','["Income level","Education level","Advertising","Time cost (willingness to wait)"]'::jsonb),
    (1128,'Systems','Price signals and shortage','A','["Raise price, reducing quantity demanded and encouraging supply","Lower price, increasing demand","Fix price permanently","Eliminate opportunity cost"]'::jsonb),
    (1131,'Systems','Incentives in planned and market economies','B','["Lower quality to maximize profit","Meet quotas but with low efficiency/quality","Always innovate faster","Have perfectly accurate price signals"]'::jsonb)
  )
  select count(*) into v_bad
  from expected e
  left join public.questions q on q.id=e.question_id
  where q.id is null
     or q.subject_id<>7
     or q.is_active is not true
     or q.quality_status<>'published'
     or lower(coalesce(q.qtype,''))<>'mcq'
     or q.topic<>e.topic
     or q.subtopic<>e.subtopic
     or upper(trim(coalesce(q.correct_answer,'')))<>e.correct_answer
     or coalesce(q.options_text_en,'[]')::jsonb<>e.options_en;

  if v_bad<>0 then
    raise exception 'AI-4 diagnostic batch refused: one or more Chapter 4 questions changed';
  end if;

  if exists (
    select 1
    from public.question_answer_diagnostics d
    where d.question_id in (1102,1109,1122,1128,1131)
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
(1102,'mcq_option','A','Higher prices signal scarcity and encourage producers to supply more while reducing quantity demanded',true,null,null,
 'Верно: рост цены сигнализирует об относительной редкости, стимулирует предложение и сокращает объём спроса.',
 'To‘g‘ri: narx oshishi nisbiy tanqislikni bildiradi, taklifni rag‘batlantiradi va talab miqdorini kamaytiradi.',
 'Correct: a higher price signals relative scarcity, encourages supply and reduces quantity demanded.',
 'Свяжите цену с функциями сигнала, стимула и нормирования.',
 'Narxni signal, rag‘bat va taqsimlash funksiyalari bilan bog‘lang.',
 'Link price to its signalling, incentive and rationing functions.',
 'Systems','Price mechanism and resource allocation','{}'::jsonb,'published'),
(1102,'mcq_option','B','Government sets quotas for all goods',false,'planned_market_allocation_confusion','Market price mechanism vs administrative allocation',
 'Квоты — административный способ распределения, а не основной механизм рыночной экономики.',
 'Kvotalar ma’muriy taqsimlash usuli bo‘lib, bozor iqtisodiyotining asosiy mexanizmi emas.',
 'Quotas are an administrative allocation method, not the main mechanism of a market economy.',
 'Различайте ценовой механизм и административное распределение.',
 'Narx mexanizmi bilan ma’muriy taqsimlashni farqlang.',
 'Distinguish the price mechanism from administrative allocation.',
 'Systems','Price mechanism and resource allocation','{}'::jsonb,'published'),
(1102,'mcq_option','C','Prices do not affect choices',false,'price_signal_denial','Price signals and incentives',
 'Цены влияют на решения потребителей и производителей через сигналы и стимулы.',
 'Narxlar signal va rag‘batlar orqali iste’molchi hamda ishlab chiqaruvchi qarorlariga ta’sir qiladi.',
 'Prices affect consumer and producer choices through signals and incentives.',
 'Повторите, как изменение цены влияет на спрос и предложение.',
 'Narx o‘zgarishi talab va taklifga qanday ta’sir qilishini takrorlang.',
 'Review how a price change affects demand and supply decisions.',
 'Systems','Price mechanism and resource allocation','{}'::jsonb,'published'),
(1102,'mcq_option','D','Only tradition determines allocation',false,'traditional_market_system_confusion','Economic systems and allocation',
 'Традиция может играть роль в традиционной экономике, но в рыночной экономике ресурсы в основном направляются через цены.',
 'An’ana an’anaviy iqtisodiyotda rol o‘ynashi mumkin, ammo bozor iqtisodiyotida resurslar asosan narxlar orqali yo‘naltiriladi.',
 'Tradition may matter in a traditional economy, but market economies mainly allocate resources through prices.',
 'Сравните способы распределения ресурсов в разных экономических системах.',
 'Turli iqtisodiy tizimlarda resurslar qanday taqsimlanishini solishtiring.',
 'Compare resource-allocation mechanisms across economic systems.',
 'Systems','Price mechanism and resource allocation','{}'::jsonb,'published'),

(1109,'mcq_option','A','Price rations by willingness/ability to pay; queues ration by time cost',true,null,null,
 'Верно: цена распределяет товар по готовности и способности платить, а очередь — через затраты времени.',
 'To‘g‘ri: narx to‘lash istagi va imkoniga ko‘ra, navbat esa vaqt xarajati orqali taqsimlaydi.',
 'Correct: price rations by willingness and ability to pay, while queues ration through time cost.',
 'Сравните денежную и временную стоимость разных способов нормирования.',
 'Turli taqsimlash usullaridagi pul va vaqt xarajatlarini solishtiring.',
 'Compare the money and time costs of different rationing methods.',
 'Systems','Rationing methods','{}'::jsonb,'published'),
(1109,'mcq_option','B','Queues always create surpluses; prices always create shortages',false,'shortage_surplus_rationing_confusion','Rationing methods vs market imbalance',
 'Способ распределения сам по себе не означает, что всегда возникает избыток или дефицит.',
 'Taqsimlash usulining o‘zi har doim ortiqcha yoki taqchillik bo‘lishini anglatmaydi.',
 'A rationing method does not by itself imply that there will always be a surplus or shortage.',
 'Отделяйте способ нормирования от причин рыночного дефицита и избытка.',
 'Taqsimlash usulini bozor taqchilligi va ortiqchaligi sabablaridan ajrating.',
 'Separate the rationing method from the causes of shortages and surpluses.',
 'Systems','Rationing methods','{}'::jsonb,'published'),
(1109,'mcq_option','C','Both methods are identical in effects',false,'rationing_method_equivalence','Price vs non-price rationing',
 'Ценовое и очередное распределение создают разные издержки и критерии доступа.',
 'Narx orqali va navbat orqali taqsimlash turli xarajatlar va kirish mezonlarini yaratadi.',
 'Price rationing and queue rationing create different costs and access criteria.',
 'Сравните, кто получает товар и какую цену — денежную или временную — он платит.',
 'Kim tovar olishi va qanday — pul yoki vaqt — xarajat qilishi jihatidan solishtiring.',
 'Compare who obtains the good and whether the cost is paid in money or time.',
 'Systems','Rationing methods','{}'::jsonb,'published'),
(1109,'mcq_option','D','Queues eliminate opportunity cost',false,'opportunity_cost_denial','Opportunity cost of waiting',
 'Ожидание в очереди имеет альтернативную стоимость: потраченное время нельзя использовать иначе.',
 'Navbatda kutishning muqobil xarajati bor: sarflangan vaqtni boshqa maqsadda ishlatib bo‘lmaydi.',
 'Waiting in a queue has an opportunity cost because the time used cannot be spent on the next best alternative.',
 'Свяжите время ожидания с альтернативной стоимостью.',
 'Kutish vaqtini muqobil xarajat bilan bog‘lang.',
 'Link waiting time to opportunity cost.',
 'Systems','Rationing methods','{}'::jsonb,'published'),

(1122,'mcq_option','A','Income level',false,'queue_income_confusion','Rationing by queue',
 'Очередь распределяет доступ прежде всего через готовность тратить время, а не по уровню дохода.',
 'Navbat kirishni asosan vaqt sarflashga tayyorlik orqali taqsimlaydi, daromad darajasi orqali emas.',
 'Queue rationing mainly allocates access through willingness to spend time, not by income level.',
 'Определите основной неденежный ресурс, который расходуется в очереди.',
 'Navbatda sarflanadigan asosiy nopul resursni aniqlang.',
 'Identify the main non-monetary resource spent in a queue.',
 'Systems','Rationing by queue','{}'::jsonb,'published'),
(1122,'mcq_option','B','Education level',false,'irrelevant_rationing_criterion','Rationing by queue',
 'Уровень образования не является основным критерием очереди. Ключевой фактор — время ожидания.',
 'Ta’lim darajasi navbatning asosiy mezoni emas. Asosiy omil — kutish vaqti.',
 'Education level is not the main criterion in queue rationing. The key factor is waiting time.',
 'Сосредоточьтесь на стоимости ожидания.',
 'Kutish xarajatiga e’tibor qarating.',
 'Focus on the cost of waiting.',
 'Systems','Rationing by queue','{}'::jsonb,'published'),
(1122,'mcq_option','C','Advertising',false,'irrelevant_rationing_criterion','Rationing by queue',
 'Реклама может влиять на спрос, но не является принципом распределения товара через очередь.',
 'Reklama talabga ta’sir qilishi mumkin, ammo tovarni navbat orqali taqsimlash tamoyili emas.',
 'Advertising may affect demand, but it is not the basis of allocation through a queue.',
 'Различайте факторы спроса и механизм распределения дефицитного товара.',
 'Talab omillari bilan tanqis tovarni taqsimlash mexanizmini farqlang.',
 'Distinguish determinants of demand from the rationing mechanism.',
 'Systems','Rationing by queue','{}'::jsonb,'published'),
(1122,'mcq_option','D','Time cost (willingness to wait)',true,null,null,
 'Верно: при очереди доступ распределяется через затраты времени и готовность ждать.',
 'To‘g‘ri: navbatda kirish vaqt xarajati va kutishga tayyorlik orqali taqsimlanadi.',
 'Correct: queue rationing allocates access through time cost and willingness to wait.',
 'Свяжите время ожидания с неденежной ценой доступа.',
 'Kutish vaqtini kirishning nopul narxi bilan bog‘lang.',
 'Link waiting time to the non-monetary price of access.',
 'Systems','Rationing by queue','{}'::jsonb,'published'),

(1128,'mcq_option','A','Raise price, reducing quantity demanded and encouraging supply',true,null,null,
 'Верно: дефицит создаёт повышательное давление на цену, что сокращает объём спроса и стимулирует предложение.',
 'To‘g‘ri: taqchillik narxni oshirishga bosim qiladi, bu talab miqdorini kamaytiradi va taklifni rag‘batlantiradi.',
 'Correct: scarcity creates upward pressure on price, reducing quantity demanded and encouraging supply.',
 'Проследите движение к равновесию через реакцию спроса и предложения.',
 'Talab va taklif reaksiyasi orqali muvozanatga qaytish jarayonini kuzating.',
 'Trace the movement toward equilibrium through demand and supply responses.',
 'Systems','Price signals and shortage','{}'::jsonb,'published'),
(1128,'mcq_option','B','Lower price, increasing demand',false,'shortage_price_direction_error','Price response to shortage',
 'При дефиците снижение цены обычно усилило бы избыточный спрос. Рыночное давление направлено на повышение цены.',
 'Taqchillikda narxni pasaytirish odatda ortiqcha talabni kuchaytiradi. Bozor bosimi narxni oshirish tomonga yo‘naladi.',
 'During a shortage, a lower price would usually worsen excess demand. Market pressure is upward on price.',
 'Повторите направление изменения цены при избыточном спросе.',
 'Ortiqcha talabda narx qaysi tomonga o‘zgarishini takrorlang.',
 'Review the direction of price movement under excess demand.',
 'Systems','Price signals and shortage','{}'::jsonb,'published'),
(1128,'mcq_option','C','Fix price permanently',false,'price_rigidity_confusion','Price mechanism adjustment',
 'Ценовой механизм предполагает изменение цены в ответ на условия рынка, а не постоянную фиксацию.',
 'Narx mexanizmi bozor sharoitiga javoban narxning o‘zgarishini nazarda tutadi, doimiy belgilanishini emas.',
 'The price mechanism relies on price adjustment to market conditions, not permanent price fixing.',
 'Сравните рыночное изменение цены с административным контролем цен.',
 'Bozor narx o‘zgarishini ma’muriy narx nazorati bilan solishtiring.',
 'Compare market price adjustment with administrative price controls.',
 'Systems','Price signals and shortage','{}'::jsonb,'published'),
(1128,'mcq_option','D','Eliminate opportunity cost',false,'opportunity_cost_denial','Scarcity and opportunity cost',
 'Изменение цены не устраняет ограниченность ресурсов и альтернативную стоимость выбора.',
 'Narx o‘zgarishi resurslar cheklanganligi va tanlovning muqobil xarajatini yo‘q qilmaydi.',
 'A price change does not eliminate scarcity or the opportunity cost of choice.',
 'Свяжите ограниченность ресурсов с неизбежностью альтернативной стоимости.',
 'Resurslar cheklanganligini muqobil xarajatning muqarrarligi bilan bog‘lang.',
 'Link scarcity to the inevitability of opportunity cost.',
 'Systems','Price signals and shortage','{}'::jsonb,'published'),

(1131,'mcq_option','A','Lower quality to maximize profit',false,'market_profit_motive_confusion','Incentives in planned economies',
 'Максимизация прибыли — прежде всего рыночный стимул. В плановой системе проблема часто связана с выполнением количественных заданий без достаточного стимула к качеству и эффективности.',
 'Foydani maksimal qilish avvalo bozor rag‘batidir. Rejali tizimda muammo ko‘pincha sifat va samaradorlikka yetarli rag‘batsiz miqdoriy reja bajarish bilan bog‘liq.',
 'Profit maximisation is primarily a market incentive. In a planned system, the common problem is meeting quantitative targets without strong incentives for quality or efficiency.',
 'Различайте стимулы прибыли и стимулы выполнения плана.',
 'Foyda rag‘batlari bilan rejani bajarish rag‘batlarini farqlang.',
 'Distinguish profit incentives from quota-compliance incentives.',
 'Systems','Incentives in planned and market economies','{}'::jsonb,'published'),
(1131,'mcq_option','B','Meet quotas but with low efficiency/quality',true,null,null,
 'Верно: выполнение плана может стать целью само по себе, ослабляя стимулы к эффективности, качеству и инновациям.',
 'To‘g‘ri: rejani bajarish o‘z-o‘zicha maqsadga aylanishi samaradorlik, sifat va innovatsiyaga rag‘batni susaytirishi mumkin.',
 'Correct: meeting quotas can become the target itself, weakening incentives for efficiency, quality and innovation.',
 'Свяжите структуру стимулов с поведением фирмы.',
 'Rag‘batlar tuzilishini firma xatti-harakati bilan bog‘lang.',
 'Link the incentive structure to firm behaviour.',
 'Systems','Incentives in planned and market economies','{}'::jsonb,'published'),
(1131,'mcq_option','C','Always innovate faster',false,'planned_innovation_overstatement','Innovation incentives',
 'В плановой экономике слабая конкуренция и ограниченные рыночные стимулы могут снижать давление к инновациям; «всегда быстрее» неверно.',
 'Rejali iqtisodiyotda zaif raqobat va cheklangan bozor rag‘batlari innovatsiya bosimini kamaytirishi mumkin; “har doim tezroq” noto‘g‘ri.',
 'Weak competition and limited market incentives can reduce pressure to innovate in a planned economy; “always faster” is not supported.',
 'Оценивайте, какие стимулы поощряют инновации в разных системах.',
 'Turli tizimlarda qaysi rag‘batlar innovatsiyani qo‘llashini baholang.',
 'Evaluate which incentives encourage innovation under different systems.',
 'Systems','Incentives in planned and market economies','{}'::jsonb,'published'),
(1131,'mcq_option','D','Have perfectly accurate price signals',false,'planned_price_signal_confusion','Price signals in economic systems',
 'В плановой экономике цены могут не отражать рыночный дефицит так же точно, как конкурентные рыночные цены.',
 'Rejali iqtisodiyotda narxlar bozor tanqisligini raqobatli bozor narxlari kabi aniq aks ettirmasligi mumkin.',
 'In a planned economy, administered prices may not reflect market scarcity as accurately as competitive market prices.',
 'Сравните информационную роль цен в рыночной и плановой системах.',
 'Bozor va rejali tizimlarda narxlarning axborot rolini solishtiring.',
 'Compare the information role of prices in market and planned systems.',
 'Systems','Incentives in planned and market economies','{}'::jsonb,'published');