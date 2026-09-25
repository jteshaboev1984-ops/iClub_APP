-- AI-4 Economics Practice 1 deterministic diagnostic batch: Chapter 6.
-- Adds option-level deterministic explanations for four already-published MCQs.
-- Server scoring remains authoritative; these rows only explain the checked result.

do $guard$
declare v_bad integer;
begin
  with expected(question_id,topic,subtopic,correct_answer,options_en) as (
    values
    (1100,'Goods','Merit goods and education','A','["It creates positive external benefits and may be under-consumed without intervention","It is non-excludable and non-rival","It always causes negative externalities","It has zero opportunity cost"]'::jsonb),
    (1111,'Goods','Free-rider problem','A','["The free-rider problem","Perfect competition","Negative income elasticity","A shift along demand"]'::jsonb),
    (1123,'Goods','Features of pure public goods','B','["Rival and excludable","Non-rival and non-excludable","Rival and non-excludable","Non-rival and excludable"]'::jsonb),
    (1124,'Goods','Demerit goods','A','["Cigarettes","Street lighting","A private car","A textbook"]'::jsonb)
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
    raise exception 'AI-4 diagnostic batch refused: one or more Chapter 6 questions changed';
  end if;

  if exists (
    select 1 from public.question_answer_diagnostics
    where question_id in (1100,1111,1123,1124)
      and quality_status='published'
  ) then
    raise exception 'AI-4 diagnostic batch refused: published mappings already exist for a target question';
  end if;
end
$guard$;

insert into public.question_answer_diagnostics(
  question_id,answer_kind,answer_key,answer_value,is_correct,mistake_type,weak_skill,
  feedback_ru,feedback_uz,feedback_en,next_action_ru,next_action_uz,next_action_en,
  recommended_topic,recommended_subtopic,rule_json,quality_status
) values
(1100,'mcq_option','A','It creates positive external benefits and may be under-consumed without intervention',true,null,null,
 'Верно: образование создаёт внешние выгоды, а без вмешательства может потребляться в объёме ниже общественно желательного.',
 'To‘g‘ri: ta’lim tashqi ijobiy foyda yaratadi va aralashuvsiz jamiyat uchun maqbul darajadan kam iste’mol qilinishi mumkin.',
 'Correct: education creates positive external benefits and may be under-consumed relative to the socially desirable level.',
 'Свяжите merit goods с положительными внешними эффектами и недопотреблением.',
 'Merit goodsni ijobiy tashqi ta’sirlar va kam iste’mol bilan bog‘lang.',
 'Link merit goods to positive externalities and under-consumption.',
 'Goods','Merit goods and education','{}'::jsonb,'published'),
(1100,'mcq_option','B','It is non-excludable and non-rival',false,'merit_public_good_confusion','Merit goods vs public goods',
 'Неисключаемость и неконкурентность — признаки чистого общественного блага, а не определение merit good.',
 'Foydalanishni cheklab bo‘lmaslik va raqobatsizlik sof jamoat ne’matining belgilaridir, merit good ta’rifi emas.',
 'Non-excludability and non-rivalry define a pure public good, not a merit good.',
 'Различайте merit goods и pure public goods.',
 'Merit goods bilan pure public goodsni farqlang.',
 'Distinguish merit goods from pure public goods.',
 'Goods','Merit goods and education','{}'::jsonb,'published'),
(1100,'mcq_option','C','It always causes negative externalities',false,'externality_direction_confusion','Positive vs negative externalities',
 'Для образования обычно подчёркиваются положительные внешние выгоды, а не обязательные отрицательные внешние эффекты.',
 'Ta’lim uchun odatda salbiy emas, ijobiy tashqi foydalar ta’kidlanadi.',
 'Education is commonly associated with positive external benefits, not necessarily negative externalities.',
 'Повторите направление внешних эффектов merit goods.',
 'Merit goods tashqi ta’sirlarining yo‘nalishini takrorlang.',
 'Review the direction of external effects associated with merit goods.',
 'Goods','Merit goods and education','{}'::jsonb,'published'),
(1100,'mcq_option','D','It has zero opportunity cost',false,'opportunity_cost_denial','Scarcity and merit goods',
 'Образование использует ограниченные ресурсы, поэтому имеет альтернативную стоимость.',
 'Ta’lim cheklangan resurslardan foydalanadi, shuning uchun uning muqobil xarajati mavjud.',
 'Education uses scarce resources, so it has an opportunity cost.',
 'Не путайте общественную полезность блага с отсутствием альтернативной стоимости.',
 'Ne’matning ijtimoiy foydasini muqobil xarajat yo‘qligi bilan adashtirmang.',
 'Do not confuse social benefit with absence of opportunity cost.',
 'Goods','Merit goods and education','{}'::jsonb,'published'),

(1111,'mcq_option','A','The free-rider problem',true,null,null,
 'Верно: люди получают выгоду от доступного всем блага, не участвуя в его финансировании — это проблема безбилетника.',
 'To‘g‘ri: odamlar hammaga ochiq ne’matdan foyda olib, uning xarajatiga hissa qo‘shmasligi free-rider muammosidir.',
 'Correct: people benefit from a widely available good without contributing to its cost, which is the free-rider problem.',
 'Свяжите free-rider problem с неисключаемостью.',
 'Free-rider muammosini foydalanishni cheklab bo‘lmaslik bilan bog‘lang.',
 'Link the free-rider problem to non-excludability.',
 'Goods','Free-rider problem','{}'::jsonb,'published'),
(1111,'mcq_option','B','Perfect competition',false,'public_good_market_structure_confusion','Free-rider problem',
 'Совершенная конкуренция описывает структуру рынка и не объясняет пользование благом без оплаты.',
 'Mukammal raqobat bozor tuzilmasini tasvirlaydi va to‘lovsiz foydalanishni izohlamaydi.',
 'Perfect competition describes a market structure and does not explain benefiting without paying.',
 'Определите, какая характеристика общественного блага позволяет не платить.',
 'Jamoat ne’matining qaysi xususiyati to‘lamasdan foydalanishga imkon berishini aniqlang.',
 'Identify which public-good characteristic allows people to benefit without paying.',
 'Goods','Free-rider problem','{}'::jsonb,'published'),
(1111,'mcq_option','C','Negative income elasticity',false,'elasticity_public_good_confusion','Free-rider problem vs income elasticity',
 'Отрицательная эластичность по доходу относится к низшим благам, а не к проблеме финансирования общественного блага.',
 'Manfiy daromad elastikligi past toifadagi tovarlarga tegishli, jamoat ne’matini moliyalashtirish muammosiga emas.',
 'Negative income elasticity concerns inferior goods, not the financing problem of a public good.',
 'Различайте классификацию по YED и проблему безбилетника.',
 'YED bo‘yicha tasnifni free-rider muammosidan farqlang.',
 'Separate YED classification from the free-rider problem.',
 'Goods','Free-rider problem','{}'::jsonb,'published'),
(1111,'mcq_option','D','A shift along demand',false,'demand_movement_public_good_confusion','Free-rider problem',
 'Движение вдоль кривой спроса связано с изменением цены, а здесь речь о получении выгоды без вклада в содержание.',
 'Talab egri chizig‘i bo‘ylab harakat narx o‘zgarishi bilan bog‘liq; bu holatda esa xarajatga hissa qo‘shmasdan foyda olish tasvirlangan.',
 'A movement along demand is caused by a price change; this case is about benefiting without contributing to maintenance.',
 'Сосредоточьтесь на стимуле не платить за неисключаемое благо.',
 'Foydalanishni cheklab bo‘lmaydigan ne’mat uchun to‘lamaslik rag‘batiga e’tibor qarating.',
 'Focus on the incentive not to pay for a non-excludable good.',
 'Goods','Free-rider problem','{}'::jsonb,'published'),

(1123,'mcq_option','A','Rival and excludable',false,'public_private_good_confusion','Characteristics of pure public goods',
 'Конкурентность и исключаемость характерны для частных благ.',
 'Raqobatlilik va foydalanishni cheklash xususiy ne’matlarga xos.',
 'Rivalry and excludability are characteristics of private goods.',
 'Повторите две характеристики чистого общественного блага.',
 'Sof jamoat ne’matining ikki xususiyatini takrorlang.',
 'Review the two defining features of a pure public good.',
 'Goods','Features of pure public goods','{}'::jsonb,'published'),
(1123,'mcq_option','B','Non-rival and non-excludable',true,null,null,
 'Верно: чистое общественное благо одновременно неконкурентно и неисключаемо.',
 'To‘g‘ri: sof jamoat ne’mati bir vaqtning o‘zida raqobatsiz va foydalanishni cheklab bo‘lmaydigan bo‘ladi.',
 'Correct: a pure public good is both non-rival and non-excludable.',
 'Свяжите эти признаки с free-rider problem.',
 'Bu belgilarni free-rider muammosi bilan bog‘lang.',
 'Link these features to the free-rider problem.',
 'Goods','Features of pure public goods','{}'::jsonb,'published'),
(1123,'mcq_option','C','Rival and non-excludable',false,'common_resource_confusion','Public goods vs common resources',
 'Сочетание конкурентности и неисключаемости больше соответствует общему ресурсу, а не чистому общественному благу.',
 'Raqobatlilik va foydalanishni cheklab bo‘lmaslik kombinatsiyasi sof jamoat ne’matidan ko‘ra umumiy resursga mos keladi.',
 'Rival but non-excludable describes a common resource more closely than a pure public good.',
 'Сравните четыре комбинации rival/non-rival и excludable/non-excludable.',
 'Rival/non-rival va excludable/non-excludable to‘rtta kombinatsiyasini solishtiring.',
 'Compare the four rival/non-rival and excludable/non-excludable combinations.',
 'Goods','Features of pure public goods','{}'::jsonb,'published'),
(1123,'mcq_option','D','Non-rival and excludable',false,'club_good_confusion','Public goods vs club goods',
 'Неконкурентное, но исключаемое благо ближе к клубному благу; чистое общественное благо также неисключаемо.',
 'Raqobatsiz, lekin foydalanishni cheklash mumkin bo‘lgan ne’mat club goodga yaqin; sof jamoat ne’mati esa cheklab bo‘lmaydigan ham bo‘ladi.',
 'A non-rival but excludable good is closer to a club good; a pure public good is also non-excludable.',
 'Проверьте обе характеристики одновременно.',
 'Ikkala xususiyatni bir vaqtda tekshiring.',
 'Check both defining characteristics together.',
 'Goods','Features of pure public goods','{}'::jsonb,'published'),

(1124,'mcq_option','A','Cigarettes',true,null,null,
 'Верно: сигареты — типичный demerit good, поскольку потребление связано с вредом и может превышать общественно желательный уровень.',
 'To‘g‘ri: sigaretalar odatiy demerit good bo‘lib, iste’moli zarar bilan bog‘liq va jamiyat uchun maqbul darajadan yuqori bo‘lishi mumkin.',
 'Correct: cigarettes are a standard demerit good because consumption is harmful and may exceed the socially desirable level.',
 'Свяжите demerit goods с отрицательными последствиями и перепотреблением.',
 'Demerit goodsni salbiy oqibatlar va ortiqcha iste’mol bilan bog‘lang.',
 'Link demerit goods to harmful effects and over-consumption.',
 'Goods','Demerit goods','{}'::jsonb,'published'),
(1124,'mcq_option','B','Street lighting',false,'demerit_public_good_confusion','Demerit goods vs public goods',
 'Уличное освещение — типичный пример общественного блага, а не demerit good.',
 'Ko‘cha yoritgichi demerit good emas, odatiy jamoat ne’mati misolidir.',
 'Street lighting is a standard example of a public good, not a demerit good.',
 'Различайте классификацию по социальным последствиям и по rival/excludable.',
 'Ijtimoiy oqibatlar bo‘yicha tasnifni rival/excludable tasnifidan farqlang.',
 'Distinguish classification by social effects from classification by rivalry/excludability.',
 'Goods','Demerit goods','{}'::jsonb,'published'),
(1124,'mcq_option','C','A private car',false,'demerit_private_good_confusion','Demerit-good definition',
 'Частная собственность или исключаемость сами по себе не делают благо demerit good.',
 'Xususiy mulk yoki foydalanishni cheklashning o‘zi ne’matni demerit good qilmaydi.',
 'Being privately owned or excludable does not by itself make a good a demerit good.',
 'Ищите благо, потребление которого связано с недооценённым вредом и возможным перепотреблением.',
 'Iste’moli yetarlicha hisobga olinmagan zarar va ortiqcha iste’mol bilan bog‘liq ne’matni izlang.',
 'Look for a good whose consumption involves under-recognised harm and possible over-consumption.',
 'Goods','Demerit goods','{}'::jsonb,'published'),
(1124,'mcq_option','D','A textbook',false,'demerit_merit_good_confusion','Merit vs demerit goods',
 'Учебник связан с образованием и обычно ближе к merit good, а не demerit good.',
 'Darslik ta’lim bilan bog‘liq va odatda demerit gooddan ko‘ra merit goodga yaqin.',
 'A textbook is associated with education and is closer to a merit good than a demerit good.',
 'Сравните причины недопотребления merit goods и перепотребления demerit goods.',
 'Merit goods kam iste’moli va demerit goods ortiqcha iste’moli sabablarini solishtiring.',
 'Compare why merit goods may be under-consumed and demerit goods over-consumed.',
 'Goods','Demerit goods','{}'::jsonb,'published');