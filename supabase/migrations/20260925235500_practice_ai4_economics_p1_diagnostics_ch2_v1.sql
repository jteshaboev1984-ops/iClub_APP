-- AI-4 Economics Practice 1 deterministic diagnostic batch: Chapter 2.
-- Adds option-level deterministic explanations for six already-published MCQs.
-- Scoring remains server-authoritative from questions.correct_answer; these rows only
-- classify the learner's selected option after checking. Existing diagnostic mappings remain untouched.

do $guard$
declare
  v_bad integer;
begin
  with expected(question_id,topic,subtopic,correct_answer,options_en) as (
    values
    (1083,'Basics','Microeconomics and macroeconomics','A','["individual markets and decision-makers","the whole economy’s GDP only","only inflation","only government budgets"]'::jsonb),
    (1112,'Intro','Correlation and causation','A','["This is correlation; it does not prove gyms cause lower obesity","Gyms definitely cause lower obesity","Obesity causes more gyms","There is no relationship at all"]'::jsonb),
    (1118,'Intro','Meaning of ceteris paribus','A','["Other relevant factors are held constant","Prices always fall","Demand never changes","Supply becomes zero"]'::jsonb),
    (1126,'Intro','Limits of economic models','C','["Always predicts perfectly","Must include every detail of reality","May omit important real-world factors","Cannot be tested"]'::jsonb),
    (1129,'Intro','Positive statements','B','["The government should raise taxes","A rise in price reduces quantity demanded, ceteris paribus","It is unfair that some people are poor","The best policy is free education"]'::jsonb),
    (1130,'Intro','Correlation and causation','A','["There is correlation, but a third factor (hot weather) may cause both","Ice cream causes drowning","Drowning causes ice cream sales","There is no relationship at all"]'::jsonb)
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
    raise exception 'AI-4 diagnostic batch refused: one or more Chapter 2 questions changed';
  end if;

  if exists (
    select 1
    from public.question_answer_diagnostics d
    where d.question_id in (1083,1112,1118,1126,1129,1130)
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
(1083,'mcq_option','A','individual markets and decision-makers',true,null,null,
 'Верно: микроэкономика изучает решения отдельных потребителей, фирм и конкретные рынки.',
 'To‘g‘ri: mikroiqtisodiyot alohida iste’molchilar, firmalar va aniq bozorlar qarorlarini o‘rganadi.',
 'Correct: microeconomics studies individual consumers, firms and specific markets.',
 'Сравните объект анализа микро- и макроэкономики.',
 'Mikro va makroiqtisodiyotning tahlil obyektlarini solishtiring.',
 'Compare the unit of analysis in microeconomics and macroeconomics.',
 'Basics','Microeconomics and macroeconomics','{}'::jsonb,'published'),
(1083,'mcq_option','B','the whole economy’s GDP only',false,'micro_macro_scope_confusion','Microeconomics vs macroeconomics',
 'ВВП всей экономики относится к макроэкономике. Микроэкономика рассматривает отдельных участников и рынки.',
 'Butun iqtisodiyot YAIMi makroiqtisodiyotga kiradi. Mikroiqtisodiyot alohida ishtirokchilar va bozorlarni o‘rganadi.',
 'Economy-wide GDP is a macroeconomic measure. Microeconomics focuses on individual decision-makers and markets.',
 'Повторите различие между микро- и макроэкономическими показателями.',
 'Mikro va makroiqtisodiy ko‘rsatkichlar farqini takrorlang.',
 'Review the difference between microeconomic and macroeconomic measures.',
 'Basics','Microeconomics and macroeconomics','{}'::jsonb,'published'),
(1083,'mcq_option','C','only inflation',false,'single_macro_indicator_confusion','Scope of microeconomics',
 'Инфляция — макроэкономический показатель. Она не определяет основную область микроэкономики.',
 'Inflyatsiya makroiqtisodiy ko‘rsatkichdir. U mikroiqtisodiyotning asosiy doirasini belgilamaydi.',
 'Inflation is a macroeconomic indicator. It does not define the main scope of microeconomics.',
 'Определите, изучает ли показатель отдельный рынок или экономику в целом.',
 'Ko‘rsatkich alohida bozorni yoki butun iqtisodiyotni o‘rganishini aniqlang.',
 'Classify whether a measure concerns an individual market or the economy as a whole.',
 'Basics','Microeconomics and macroeconomics','{}'::jsonb,'published'),
(1083,'mcq_option','D','only government budgets',false,'government_scope_confusion','Scope of microeconomics',
 'Государственный бюджет обычно рассматривается как часть макроэкономической и фискальной политики, а не как определение микроэкономики.',
 'Davlat byudjeti odatda makroiqtisodiy va fiskal siyosat doirasida ko‘riladi, mikroiqtisodiyot ta’rifi sifatida emas.',
 'Government budgets are generally analysed within macroeconomics and fiscal policy, not as the definition of microeconomics.',
 'Вернитесь к объектам микроэкономики: потребители, фирмы и рынки.',
 'Mikroiqtisodiyot obyektlariga qayting: iste’molchilar, firmalar va bozorlar.',
 'Return to the core microeconomic units: consumers, firms and markets.',
 'Basics','Microeconomics and macroeconomics','{}'::jsonb,'published'),

(1112,'mcq_option','A','This is correlation; it does not prove gyms cause lower obesity',true,null,null,
 'Верно: наблюдаемая связь является корреляцией и сама по себе не доказывает причинность.',
 'To‘g‘ri: kuzatilgan bog‘lanish korrelyatsiya bo‘lib, o‘z-o‘zidan sababiylikni isbotlamaydi.',
 'Correct: the observed relationship is correlation and does not by itself prove causation.',
 'Проверьте возможные третьи факторы и обратную причинность.',
 'Uchinchi omillar va teskari sababiylik ehtimolini tekshiring.',
 'Check for possible third factors and reverse causation.',
 'Intro','Correlation and causation','{}'::jsonb,'published'),
(1112,'mcq_option','B','Gyms definitely cause lower obesity',false,'causation_from_correlation','Correlation vs causation',
 'Вы сделали причинный вывод только из корреляции. Наблюдаемая связь не исключает другие объяснения.',
 'Siz faqat korrelyatsiyadan sababiy xulosa chiqardingiz. Kuzatilgan bog‘lanish boshqa izohlarni istisno qilmaydi.',
 'You inferred causation from correlation alone. The observed association does not rule out other explanations.',
 'Отделяйте статистическую связь от доказательства причинного эффекта.',
 'Statistik bog‘lanishni sababiy ta’sir isbotidan ajrating.',
 'Separate statistical association from evidence of a causal effect.',
 'Intro','Correlation and causation','{}'::jsonb,'published'),
(1112,'mcq_option','C','Obesity causes more gyms',false,'reverse_causation_assertion','Correlation vs causation',
 'Обратная причинность возможна как гипотеза, но из данной корреляции нельзя утверждать её как факт.',
 'Teskari sababiylik gipoteza bo‘lishi mumkin, ammo bu korrelyatsiyadan uni fakt deb bo‘lmaydi.',
 'Reverse causation is a possible hypothesis, but the correlation does not establish it as fact.',
 'Рассматривайте обратную причинность как альтернативное объяснение, а не доказанный вывод.',
 'Teskari sababiylikni isbotlangan xulosa emas, muqobil izoh sifatida ko‘ring.',
 'Treat reverse causation as an alternative explanation, not a proven conclusion.',
 'Intro','Correlation and causation','{}'::jsonb,'published'),
(1112,'mcq_option','D','There is no relationship at all',false,'correlation_denial','Recognising correlation',
 'В условии уже указана статистическая связь. Ошибка — отрицать корреляцию только потому, что причинность не доказана.',
 'Shartda statistik bog‘lanish berilgan. Sababiylik isbotlanmagani uchun korrelyatsiyani inkor etish xato.',
 'The prompt already states a statistical association. Lack of proven causation does not mean there is no correlation.',
 'Различайте «есть корреляция» и «доказана причинность».',
 '“Korrelyatsiya bor” va “sababiylik isbotlangan” tushunchalarini farqlang.',
 'Distinguish “there is correlation” from “causation is proven.”',
 'Intro','Correlation and causation','{}'::jsonb,'published'),

(1118,'mcq_option','A','Other relevant factors are held constant',true,null,null,
 'Верно: ceteris paribus означает, что другие существенные факторы считаются неизменными.',
 'To‘g‘ri: ceteris paribus boshqa muhim omillar o‘zgarmaydi deb qabul qilishni anglatadi.',
 'Correct: ceteris paribus means other relevant factors are held constant.',
 'Используйте это условие, чтобы изолировать влияние одной переменной.',
 'Bir o‘zgaruvchining ta’sirini ajratish uchun shu shartdan foydalaning.',
 'Use this assumption to isolate the effect of one variable.',
 'Intro','Meaning of ceteris paribus','{}'::jsonb,'published'),
(1118,'mcq_option','B','Prices always fall',false,'ceteris_paribus_definition_error','Meaning of ceteris paribus',
 'Ceteris paribus не означает направление изменения цены. Это допущение о неизменности других факторов.',
 'Ceteris paribus narxning qaysi tomonga o‘zgarishini anglatmaydi. Bu boshqa omillar o‘zgarmasligi haqidagi faraz.',
 'Ceteris paribus does not specify the direction of price changes. It means other relevant factors are held constant.',
 'Повторите буквальный смысл допущения ceteris paribus.',
 'Ceteris paribus farazining ma’nosini takrorlang.',
 'Review the meaning of the ceteris paribus assumption.',
 'Intro','Meaning of ceteris paribus','{}'::jsonb,'published'),
(1118,'mcq_option','C','Demand never changes',false,'ceteris_paribus_definition_error','Meaning of ceteris paribus',
 'Ceteris paribus не означает, что спрос никогда не меняется. Меняется изучаемая переменная, а другие факторы фиксируются.',
 'Ceteris paribus talab hech qachon o‘zgarmaydi degani emas. O‘rganilayotgan o‘zgaruvchi o‘zgarishi mumkin, boshqa omillar esa o‘zgarmas deb olinadi.',
 'Ceteris paribus does not mean demand never changes. The variable being studied may change while other relevant factors are held constant.',
 'Определите, какие факторы фиксируются, а какой эффект изучается.',
 'Qaysi omillar o‘zgarmasligi va qaysi ta’sir o‘rganilishini aniqlang.',
 'Identify which factors are held constant and which effect is being studied.',
 'Intro','Meaning of ceteris paribus','{}'::jsonb,'published'),
(1118,'mcq_option','D','Supply becomes zero',false,'ceteris_paribus_definition_error','Meaning of ceteris paribus',
 'Нулевое предложение не связано с определением ceteris paribus. Это метод анализа при неизменных прочих условиях.',
 'Taklifning nol bo‘lishi ceteris paribus ta’rifiga aloqador emas. Bu boshqa shartlar o‘zgarmas bo‘lgandagi tahlil usuli.',
 'Zero supply is unrelated to the definition of ceteris paribus. It is an analytical assumption that other relevant conditions remain unchanged.',
 'Повторите, зачем экономисты фиксируют прочие условия.',
 'Iqtisodchilar nima uchun boshqa shartlarni o‘zgarmas deb olishlarini takrorlang.',
 'Review why economists hold other conditions constant.',
 'Intro','Meaning of ceteris paribus','{}'::jsonb,'published'),

(1126,'mcq_option','A','Always predicts perfectly',false,'perfect_prediction_assumption','Limits of economic models',
 'Экономические модели не обязаны предсказывать идеально: они упрощают реальность и зависят от предпосылок и данных.',
 'Iqtisodiy modellar mukammal bashorat qilishi shart emas: ular haqiqatni soddalashtiradi va farazlar hamda ma’lumotlarga bog‘liq.',
 'Economic models do not have to predict perfectly: they simplify reality and depend on assumptions and data.',
 'Оцените модель по полезности и ограничениям, а не по требованию идеального прогноза.',
 'Modelni mukammal bashorat talabi bilan emas, foydaliligi va cheklovlari bilan baholang.',
 'Evaluate a model by its usefulness and limitations, not by requiring perfect prediction.',
 'Intro','Limits of economic models','{}'::jsonb,'published'),
(1126,'mcq_option','B','Must include every detail of reality',false,'model_overcomplexity_assumption','Purpose of economic models',
 'Модель специально упрощает реальность. Включение каждой детали лишило бы её аналитической полезности.',
 'Model ataylab haqiqatni soddalashtiradi. Har bir tafsilotni kiritish uning tahliliy foydasini kamaytiradi.',
 'A model deliberately simplifies reality. Including every detail would undermine its analytical usefulness.',
 'Свяжите упрощение модели с её назначением — выделить ключевые взаимосвязи.',
 'Model soddalashtirilishini uning maqsadi — asosiy bog‘lanishlarni ajratish bilan bog‘lang.',
 'Link model simplification to its purpose of isolating key relationships.',
 'Intro','Limits of economic models','{}'::jsonb,'published'),
(1126,'mcq_option','C','May omit important real-world factors',true,null,null,
 'Верно: упрощение означает, что модель может не учитывать некоторые важные реальные факторы.',
 'To‘g‘ri: soddalashtirish sababli model ayrim muhim real omillarni hisobga olmasligi mumkin.',
 'Correct: because models simplify reality, they may omit important real-world factors.',
 'При применении модели проверяйте её предпосылки и пропущенные факторы.',
 'Modelni qo‘llaganda uning farazlari va hisobga olinmagan omillarini tekshiring.',
 'When applying a model, check its assumptions and omitted factors.',
 'Intro','Limits of economic models','{}'::jsonb,'published'),
(1126,'mcq_option','D','Cannot be tested',false,'model_testability_confusion','Economic model evaluation',
 'Многие экономические модели можно сопоставлять с данными и проверять их выводы. Неполнота модели не означает, что её нельзя тестировать.',
 'Ko‘plab iqtisodiy modellarni ma’lumotlar bilan solishtirish va xulosalarini tekshirish mumkin. Modelning to‘liq emasligi uni sinab bo‘lmaydi degani emas.',
 'Many economic models can be compared with data and their implications tested. Simplification does not mean a model cannot be tested.',
 'Различайте ограниченность модели и возможность эмпирической проверки.',
 'Modelning cheklanganligi bilan empirik tekshirish imkonini farqlang.',
 'Distinguish model limitations from empirical testability.',
 'Intro','Limits of economic models','{}'::jsonb,'published'),

(1129,'mcq_option','A','The government should raise taxes',false,'normative_positive_confusion','Positive vs normative statements',
 'Слово «должно» выражает оценочное суждение о желательной политике, поэтому это нормативное утверждение.',
 '“Kerak” mazmuni ma’qul siyosat haqidagi baholashni bildiradi, shuning uchun bu normativ fikr.',
 'The word “should” expresses a value judgement about desirable policy, so this is a normative statement.',
 'Ищите утверждение, которое можно проверить фактами.',
 'Dalillar bilan tekshirish mumkin bo‘lgan fikrni izlang.',
 'Look for a statement that can be tested against evidence.',
 'Intro','Positive statements','{}'::jsonb,'published'),
(1129,'mcq_option','B','A rise in price reduces quantity demanded, ceteris paribus',true,null,null,
 'Верно: это проверяемое утверждение о связи между ценой и объёмом спроса при прочих равных.',
 'To‘g‘ri: bu boshqa shartlar o‘zgarmaganda narx va talab miqdori o‘rtasidagi bog‘lanish haqida tekshiriladigan fikr.',
 'Correct: this is a testable claim about the relationship between price and quantity demanded, other things equal.',
 'Сравните проверяемые факты с оценочными словами «следует», «справедливо», «лучше».',
 'Tekshiriladigan fikrlarni “kerak”, “adolatli”, “eng yaxshi” kabi baholash so‘zlari bilan solishtiring.',
 'Contrast testable claims with value-laden words such as “should,” “fair,” and “best.”',
 'Intro','Positive statements','{}'::jsonb,'published'),
(1129,'mcq_option','C','It is unfair that some people are poor',false,'normative_positive_confusion','Positive vs normative statements',
 '«Несправедливо» выражает ценностную оценку, а не утверждение, которое можно однозначно проверить как истинное или ложное.',
 '“Adolatsiz” so‘zi qadriyatga asoslangan bahoni bildiradi, uni oddiy fakt sifatida tekshirib bo‘lmaydi.',
 '“Unfair” expresses a value judgement rather than a claim that can be tested as simply true or false.',
 'Отмечайте оценочные слова как признак нормативного утверждения.',
 'Baholovchi so‘zlarni normativ fikr belgisi sifatida aniqlang.',
 'Use evaluative language as a clue that a statement is normative.',
 'Intro','Positive statements','{}'::jsonb,'published'),
(1129,'mcq_option','D','The best policy is free education',false,'normative_positive_confusion','Positive vs normative statements',
 '«Лучшая политика» — оценочное суждение, зависящее от целей и ценностей, поэтому утверждение нормативное.',
 '“Eng yaxshi siyosat” maqsad va qadriyatlarga bog‘liq baholash bo‘lgani uchun normativ fikrdir.',
 '“The best policy” is an evaluative judgement that depends on goals and values, so it is normative.',
 'Переформулируйте нормативную фразу в проверяемую гипотезу и сравните различие.',
 'Normativ jumlani tekshiriladigan gipotezaga aylantirib, farqni solishtiring.',
 'Rewrite a normative claim as a testable hypothesis and compare the difference.',
 'Intro','Positive statements','{}'::jsonb,'published'),

(1130,'mcq_option','A','There is correlation, but a third factor (hot weather) may cause both',true,null,null,
 'Верно: рост обеих величин может быть связан с третьим фактором — жаркой погодой — поэтому корреляция не доказывает причинность.',
 'To‘g‘ri: ikkala ko‘rsatkichning oshishi uchinchi omil — issiq ob-havo — bilan bog‘liq bo‘lishi mumkin, shuning uchun korrelyatsiya sababiylikni isbotlamaydi.',
 'Correct: both variables may rise because of a third factor—hot weather—so the correlation does not prove causation.',
 'При корреляции ищите возможные общие причины.',
 'Korrelyatsiyada mumkin bo‘lgan umumiy sabablarni izlang.',
 'When you see correlation, look for plausible common causes.',
 'Intro','Correlation and causation','{}'::jsonb,'published'),
(1130,'mcq_option','B','Ice cream causes drowning',false,'causation_from_correlation','Correlation vs causation',
 'Совместный рост продаж мороженого и утоплений не доказывает, что одно вызывает другое.',
 'Muzqaymoq savdosi va cho‘kish holatlarining birga oshishi biri ikkinchisiga sabab ekanini isbotlamaydi.',
 'Ice cream sales and drowning incidents rising together does not prove that one causes the other.',
 'Проверьте наличие третьего фактора, влияющего на обе переменные.',
 'Ikkala o‘zgaruvchiga ta’sir qiladigan uchinchi omilni tekshiring.',
 'Check for a third factor that could affect both variables.',
 'Intro','Correlation and causation','{}'::jsonb,'published'),
(1130,'mcq_option','C','Drowning causes ice cream sales',false,'reverse_causation_assertion','Correlation vs causation',
 'Обратный причинный вывод также не подтверждается данными. Корреляция сама по себе не устанавливает направление причинности.',
 'Teskari sababiy xulosa ham ma’lumot bilan tasdiqlanmagan. Korrelyatsiya sababiy yo‘nalishni o‘z-o‘zidan belgilamaydi.',
 'The reverse causal claim is also unsupported. Correlation alone does not establish the direction of causation.',
 'Не выбирайте направление причинности без дополнительных доказательств.',
 'Qo‘shimcha dalilsiz sababiylik yo‘nalishini tanlamang.',
 'Do not assign a causal direction without additional evidence.',
 'Intro','Correlation and causation','{}'::jsonb,'published'),
(1130,'mcq_option','D','There is no relationship at all',false,'correlation_denial','Recognising correlation',
 'Обе величины растут летом, значит корреляция наблюдается. Ошибка — отрицать связь только потому, что причинность не доказана.',
 'Ikkala ko‘rsatkich yozda oshadi, demak korrelyatsiya kuzatiladi. Sababiylik isbotlanmagani uchun bog‘lanishni inkor etish xato.',
 'Both variables rise in summer, so there is an observed correlation. The absence of proven causation does not erase that relationship.',
 'Различайте наличие статистической связи и объяснение её причины.',
 'Statistik bog‘lanish mavjudligi bilan uning sababini izohlashni farqlang.',
 'Distinguish the existence of a statistical relationship from an explanation of its cause.',
 'Intro','Correlation and causation','{}'::jsonb,'published');