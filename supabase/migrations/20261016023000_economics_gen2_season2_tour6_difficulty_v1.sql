-- Economics Gen2 Season 2 Tour 6. Versioned hard content, 6 easy/10 medium/4 hard.
-- Does not touch legacy Season 1 and aborts if there is learner history on the target season.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='75s';
DO $tour6$
DECLARE
 d jsonb:='[{"ref":"EC9708:G2:EC9708-G2-T6-T-009","d":"hard","sec":135,"k":"B","en":"In Year 1, a country has 1,250 working-age residents, 900 employed and 100 unemployed people actively seeking work. In Year 2, the working-age population grows to 1,300, while 920 are employed and 80 unemployed people actively seek work. What happens to the unemployment rate and labour-force participation rate?","ru":"В первом году в стране 1 250 жителей трудоспособного возраста, из них 900 работают и 100 безработных активно ищут работу. Во втором году трудоспособное население выросло до 1 300, занятых стало 920, безработных, ищущих работу, — 80. Как меняются уровень безработицы и доля участия в рабочей силе?","uz":"1-yilda mamlakatda mehnat yoshidagi 1250 kishi bor, 900 nafari ishlaydi va 100 ishsiz faol ish qidiradi. 2-yilda mehnat yoshidagi aholi 1300 ga oshadi, ishlovchilar 920, faol ish qidirayotgan ishsizlar 80 kishi. Ishsizlik va mehnat kuchida qatnashish darajalari qanday o‘zgaradi?","options_en":["Unemployment 10%→8%; participation 80%→80%","Unemployment 10%→8%; participation 80%→about 76.9%","Unemployment 8%→10%; participation 80%→about 76.9%","Unemployment 10%→6.15%; participation 80%→100%"],"options_ru":["Безработица 10%→8%; участие 80%→80%","Безработица 10%→8%; участие 80%→примерно 76,9%","Безработица 8%→10%; участие 80%→примерно 76,9%","Безработица 10%→6,15%; участие 80%→100%"],"options_uz":["Ishsizlik 10%→8%; qatnashish 80%→80%","Ishsizlik 10%→8%; qatnashish 80%→taxminan 76,9%","Ishsizlik 8%→10%; qatnashish 80%→taxminan 76,9%","Ishsizlik 10%→6,15%; qatnashish 80%→100%"],"why":["The labour force is 900+100=1,000 in Year 1 and 920+80=1,000 in Year 2. Unemployment falls from 100/1,000=10% to 80/1,000=8%; participation declines from 1,000/1,250=80% to 1,000/1,300≈76.9%.","Рабочая сила в оба года 1 000 человек. Безработица уменьшается со 100/1 000=10% до 80/1 000=8%. Участие падает с 1 000/1 250=80% до 1 000/1 300≈76,9%.","Mehnat kuchi ikkala yilda 1000 kishi. Ishsizlik 100/1000=10% dan 80/1000=8% ga tushadi; qatnashish 1000/1250=80% dan 1000/1300≈76,9% ga kamayadi."]},{"ref":"EC9708:G2:EC9708-G2-T6-T-011","d":"hard","sec":135,"k":"D","en":"In a closed economy with fixed prices, no taxes and spare capacity, private saving is S=−40+0.25Y, where Y is national income in millions of dollars. Planned private investment is $60m and government purchases are $40m, with no other injections or leakages. In the simplified circular-flow equilibrium S=I+G. Government purchases then rise by $20m. What are the equilibrium incomes before and after the increase?","ru":"В закрытой экономике с фиксированными ценами, без налогов и при свободных мощностях частные сбережения S=−40+0,25Y, где Y — национальный доход в млн долларов. Планируемые частные инвестиции $60 млн, госзакупки $40 млн; других инъекций и изъятий нет. В упрощённом равновесии кругооборота S=I+G. Затем госзакупки растут на $20 млн. Каковы равновесные доходы до и после?","uz":"Yopiq iqtisodiyotda narxlar o‘zgarmas, soliq yo‘q, bo‘sh quvvat mavjud. Xususiy jamg‘arma S=−40+0,25Y, bunda Y milllion dollardagi milliy daromad. Rejalangan xususiy investitsiya $60 mln, davlat xaridi $40 mln, boshqa kirim yoki chiqim yo‘q. Soddalashtirilgan muvozanatda S=I+G. Keyin davlat xaridi $20 mln oshadi. Oldingi va keyingi muvozanat daromadlari qancha?","options_en":["$400m before; $480m after","$560m before; $580m after","$400m before; $560m after","$560m before; $640m after"],"options_ru":["До $400 млн; после $480 млн","До $560 млн; после $580 млн","До $400 млн; после $560 млн","До $560 млн; после $640 млн"],"options_uz":["Oldin $400 mln; keyin $480 mln","Oldin $560 mln; keyin $580 mln","Oldin $400 mln; keyin $560 mln","Oldin $560 mln; keyin $640 mln"],"why":["Initially −40+0.25Y=60+40=100, giving Y=560. After spending rises, injections are 60+60=120, so −40+0.25Y=120 and Y=640. The $20m injection raises equilibrium income by $80m with multiplier 4.","Изначально −40+0,25Y=60+40=100, поэтому Y=560. Затем инъекции 60+60=120, отсюда Y=640. Дополнительные $20 млн повышают доход на $80 млн, мультипликатор 4.","Dastlab −40+0,25Y=60+40=100, bundan Y=560. Keyin kirim 60+60=120, Y=640. $20 mln qo‘shimcha davlat xaridi daromadni $80 mln oshiradi, multiplikator 4."]},{"ref":"EC9708:G2:EC9708-G2-T6-T-014","d":"hard","sec":135,"k":"C","en":"A central bank purchases $120m of government securities from commercial banks, crediting new bank reserves. It then sells $50m of securities back to commercial banks, which pay with reserves. In a simplified banking model the reserve requirement is 20%, all loans are redeposited and no bank holds excess reserves. What are the maximum total additional deposits and bank loans supported by the net reserve injection?","ru":"Центральный банк покупает у коммерческих банков государственные бумаги на $120 млн, создавая новые банковские резервы. Затем продаёт банкам бумаги на $50 млн, которые оплачиваются резервами. В упрощённой банковской модели норма обязательных резервов 20%, все выданные кредиты возвращаются депозитами, избыточных резервов нет. Каковы максимальные дополнительные депозиты и кредиты, поддерживаемые чистым приростом резервов?","uz":"Markaziy bank tijorat banklaridan $120 mln davlat obligatsiyasini sotib olib, yangi bank zaxiralari yaratadi. Keyin banklarga $50 mln qimmatli qog‘oz sotadi, ular zaxiradan to‘laydi. Soddalashtirilgan modelda majburiy zaxira 20%, barcha kreditlar qayta depozitga aylanadi va ortiqcha zaxira yo‘q. Sof zaxira qo‘shilishiga mos maksimal qo‘shimcha depozit va kredit qancha?","options_en":["Deposits $600m; loans $480m","Deposits $350m; loans $350m","Deposits $350m; loans $280m","Deposits $70m; loans $56m"],"options_ru":["Депозиты $600 млн; кредиты $480 млн","Депозиты $350 млн; кредиты $350 млн","Депозиты $350 млн; кредиты $280 млн","Депозиты $70 млн; кредиты $56 млн"],"options_uz":["Depozit $600 mln; kredit $480 mln","Depozit $350 mln; kredit $350 mln","Depozit $350 mln; kredit $280 mln","Depozit $70 mln; kredit $56 mln"],"why":["Net reserves rise by $120m−$50m=$70m. With 20% reserves, maximum new deposits are $70m/0.20=$350m. Required reserves absorb $70m, leaving up to $280m additional lending in this deliberately idealised model.","Чистый прирост резервов $120−$50=$70 млн. При норме 20% максимально возможные новые депозиты $70/0,20=$350 млн. Из них $70 млн остаются резервами, до $280 млн могут быть кредитами.","Sof zaxira $120−$50=$70 mln. 20% norma bilan maksimal yangi depozit $70/0,20=$350 mln. $70 mln majburiy zaxira, qolgan maksimal $280 mln kredit bo‘lishi mumkin."]},{"ref":"EC9708:G2:EC9708-G2-T6-T-019","d":"hard","sec":135,"k":"A","en":"A bank holds $45m of highly liquid assets against projected 30-day stressed net cash outflows of $60m. Its regulator requires a liquidity coverage ratio of at least 100%. The bank proposes replacing $20m of loans yielding 6% per year with liquid assets yielding 0%, with all other figures unchanged. What is the new coverage ratio and direct annual interest-income sacrifice?","ru":"У банка $45 млн высоколиквидных активов при прогнозируемом чистом оттоке денежных средств за стрессовые 30 дней $60 млн. Регулятор требует коэффициент покрытия ликвидности не ниже 100%. Банк предлагает заменить $20 млн кредитов с годовой доходностью 6% ликвидными активами с доходностью 0%; прочее неизменно. Какими станут покрытие и прямое годовое сокращение процентного дохода?","uz":"Bankda 30 kunlik stressdagi prognoz sof pul chiqimi $60 mln ga qarshi $45 mln yuqori likvid aktiv bor. Regulyator likvidlik qoplash koeffitsienti kamida 100% bo‘lishini talab qiladi. Bank 6% yillik daromadli $20 mln kreditni 0% daromadli likvid aktivga almashtiradi, qolganlari o‘zgarmaydi. Yangi qoplash koeffitsienti va to‘g‘ridan-to‘g‘ri yillik foiz daromadi yo‘qotishi qancha?","options_en":["108.3%; $1.2m annual interest forgone","75.0%; $1.2m annual interest gained","108.3%; $0.12m annual interest forgone","125.0%; $2.0m annual interest forgone"],"options_ru":["108,3%; отказ от годового дохода $1,2 млн","75,0%; прирост годового дохода $1,2 млн","108,3%; потери годового дохода $0,12 млн","125,0%; потери годового дохода $2,0 млн"],"options_uz":["108,3%; yillik foiz daromadi $1,2 mln yo‘qotiladi","75,0%; yillik foiz daromadi $1,2 mln oshadi","108,3%; yillik foiz daromadi $0,12 mln yo‘qotiladi","125,0%; yillik foiz daromadi $2,0 mln yo‘qotiladi"],"why":["Liquid assets rise from $45m to $65m. Coverage becomes 65/60≈108.3%, above the requirement. Forgone loan interest is $20m×6%=$1.2m annually, demonstrating the liquidity-versus-profitability trade-off.","Ликвидные активы растут с $45 до $65 млн. Покрытие 65/60≈108,3%, выше минимума. Потерянные проценты $20 млн×6%=$1,2 млн в год — компромисс ликвидности и доходности.","Likvid aktiv $45 mln dan $65 mln ga oshadi. Qoplash 65/60≈108,3%, talabdan yuqori. Yo‘qotilgan foiz $20 mln×6%=$1,2 mln yiliga, ya’ni likvidlik va foydalilik muvozanati."]}]'::jsonb;
 x jsonb; oldq record; new_id bigint; i int; idx int; keytxt text; reftext text; cnt int;
 enwhy text; ruwhy text; uzwhy text; ez int; med int; hard int;
BEGIN
 IF jsonb_array_length(d)<>4 THEN RAISE EXCEPTION 'T6_four_hard_required'; END IF;
 IF EXISTS(SELECT 1 FROM public.tour_attempts at JOIN public.tours t ON t.id=at.tour_id WHERE t.subject_id=7 AND t.season_id=2 AND t.tour_no=6)
 THEN RAISE EXCEPTION 'T6_season2_attempts_exist'; END IF;
 SELECT count(*) INTO cnt FROM public.tours t JOIN public.tour_questions l ON l.tour_id=t.id AND l.is_active
 WHERE t.subject_id=7 AND t.season_id=2 AND t.tour_no=6;
 IF cnt<>20 THEN RAISE EXCEPTION 'T6_pool_not20_before: %',cnt; END IF;
 FOR x IN SELECT value FROM jsonb_array_elements(d) LOOP
   reftext:=x->>'ref';keytxt:=x->>'k';idx:=ascii(keytxt)-65;
   IF keytxt NOT IN ('A','B','C','D') OR x->>'d'<>'hard'
      OR jsonb_array_length(x->'options_en')<>4 OR jsonb_array_length(x->'options_ru')<>4
      OR jsonb_array_length(x->'options_uz')<>4
   THEN RAISE EXCEPTION 'T6_invalid_authoring: %',reftext; END IF;
   SELECT q.id,q.subject_id,q.topic,q.subtopic,q.quality_flag,l.tour_id,l.order_no
   INTO STRICT oldq FROM public.questions q JOIN public.tour_questions l ON l.question_id=q.id AND l.is_active
   JOIN public.tours t ON t.id=l.tour_id
   WHERE q.subject_id=7 AND t.subject_id=7 AND t.season_id=2 AND t.tour_no=6 AND q.book_ref=reftext;
   IF EXISTS(SELECT 1 FROM public.tour_answers a WHERE a.question_id=oldq.id)
      OR EXISTS(SELECT 1 FROM public.tour_session_answers_v4 a WHERE a.question_id=oldq.id)
      OR EXISTS(SELECT 1 FROM public.questions q WHERE q.subject_id=7 AND q.book_ref=reftext||'-V2')
   THEN RAISE EXCEPTION 'T6_history_or_duplicate: %',reftext; END IF;
   enwhy:=x->'why'->>0;ruwhy:=x->'why'->>1;uzwhy:=x->'why'->>2;
   INSERT INTO public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
   question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
   VALUES(oldq.subject_id,oldq.topic,oldq.subtopic,'hard','mcq',x->>'en',(x->'options_en')::text,keytxt,
   'Correct: '||(x->'options_en'->>idx)||E'\n'||enwhy,NULL,true,
   x->>'ru',x->>'uz',x->>'en',(x->'options_ru')::text,(x->'options_uz')::text,(x->'options_en')::text,
   'Правильный ответ: '||(x->'options_ru'->>idx)||E'\n'||ruwhy,
   'To‘g‘ri javob: '||(x->'options_uz'->>idx)||E'\n'||uzwhy,
   'Correct answer: '||(x->'options_en'->>idx)||E'\n'||enwhy,
   reftext||'-V2',(x->>'sec')::int,oldq.quality_flag,'published')
   RETURNING id INTO new_id;
   UPDATE public.tour_questions SET is_active=false WHERE tour_id=oldq.tour_id AND question_id=oldq.id AND is_active;
   GET DIAGNOSTICS cnt=ROW_COUNT;
   IF cnt<>1 THEN RAISE EXCEPTION 'T6_old_link_count: %',reftext; END IF;
   INSERT INTO public.tour_questions(tour_id,question_id,order_no,is_active) VALUES(oldq.tour_id,new_id,oldq.order_no,true);
   INSERT INTO public.question_version_links(old_question_id,new_question_id,link_type,reason)
   VALUES(oldq.id,new_id,'replacement','Economics Gen2 season2 Tour6: actual high-order difficulty replacement; old question preserved');
   FOR i IN 0..3 LOOP
     INSERT INTO public.question_answer_diagnostics(question_id,answer_kind,answer_key,answer_value,is_correct,
        mistake_type,weak_skill,feedback_ru,feedback_uz,feedback_en,next_action_ru,next_action_uz,next_action_en,rule_json,quality_status)
     VALUES(new_id,'mcq_option',chr(65+i),NULL,i=idx,
        CASE WHEN i=idx THEN NULL ELSE 'multi_step_economic_reasoning' END,oldq.subtopic,
        'Выбрано: '||(x->'options_ru'->>i)||E'\n'||ruwhy||E'\nОтвет: '||(x->'options_ru'->>idx),
        'Tanlov: '||(x->'options_uz'->>i)||E'\n'||uzwhy||E'\nJavob: '||(x->'options_uz'->>idx),
        'Selected: '||(x->'options_en'->>i)||E'\n'||enwhy||E'\nCorrect: '||(x->'options_en'->>idx),
        CASE WHEN i=idx THEN NULL ELSE 'Перепроверьте каждый шаг.' END,
        CASE WHEN i=idx THEN NULL ELSE 'Har bir bosqichni tekshiring.' END,
        CASE WHEN i=idx THEN NULL ELSE 'Check each step.' END,
        jsonb_build_object('diagnostic_code','EC9708_G2_T6T'||substring(reftext from 'T-([0-9]{3})')||'_V2_'||chr(65+i)),
        'published');
   END LOOP;
 END LOOP;
 UPDATE public.questions q SET difficulty=
  CASE WHEN right(q.book_ref,3) IN ('001','004','006','008','012','020') THEN 'easy' ELSE 'medium' END
 WHERE q.subject_id=7 AND q.book_ref ~ '^EC9708:G2:EC9708-G2-T6-T-[0-9]{3}$'
   AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(d) z WHERE z->>'ref'=q.book_ref);
 GET DIAGNOSTICS cnt=ROW_COUNT;
 IF cnt<>16 THEN RAISE EXCEPTION 'T6_unchanged_expected16: %',cnt; END IF;
 SELECT count(*),count(*) FILTER(WHERE q.difficulty='easy'),
 count(*) FILTER(WHERE q.difficulty='medium'),count(*) FILTER(WHERE q.difficulty='hard')
 INTO cnt,ez,med,hard
 FROM public.tours t JOIN public.tour_questions l ON l.tour_id=t.id AND l.is_active
 JOIN public.questions q ON q.id=l.question_id WHERE t.subject_id=7 AND t.season_id=2 AND t.tour_no=6;
 IF cnt<>20 OR ez<>6 OR med<>10 OR hard<>4 THEN
 RAISE EXCEPTION 'T6_mix_invalid: %,%,%,%',cnt,ez,med,hard; END IF;
END $tour6$;
COMMIT;
