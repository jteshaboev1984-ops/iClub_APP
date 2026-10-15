-- Economics Gen2 Season 2 Tour 1. Versioned hard content, 6 easy/10 medium/4 hard.
-- Does not touch legacy Season 1 and aborts if there is learner history on the target season.
BEGIN;
SET LOCAL lock_timeout='5s';
SET LOCAL statement_timeout='75s';
DO $tour1$
DECLARE
 d jsonb:='[{"ref":"EC9708:G2:EC9708-G2-T1-T-011","d":"hard","sec":135,"k":"C","en":"Three suppliers would accept minimum prices of $10, $14 and $18 for one crate each. Initially the market price is $20. Later it falls to $16, and each supplier sells one crate only if the price covers its minimum. What happens to their total producer surplus?","ru":"Три продавца готовы поставить по одному ящику при минимальных ценах соответственно $10, $14 и $18. Первоначально рыночная цена $20, затем падает до $16. Каждый продаёт ящик, только если цена не ниже его минимума. Как изменится их общий излишек производителя?","uz":"Uch sotuvchining har biri bittadan quti sotishga tayyor: eng kam narxlari $10, $14 va $18. Dastlab bozor narxi $20, keyin $16 ga tushadi. Har biri narx o‘zining minimumidan past bo‘lmasa sotadi. Ularning jami ishlab chiqaruvchi ortiqchaligi qanday o‘zgaradi?","options_en":["From $18 to $12, down $6","From $30 to $16, down $14","From $18 to $8, down $10","From $18 to $18, unchanged"],"options_ru":["С $18 до $12, снижение на $6","С $30 до $16, снижение на $14","С $18 до $8, снижение на $10","С $18 до $18, без изменений"],"options_uz":["$18 dan $12 ga, $6 kamayadi","$30 dan $16 ga, $14 kamayadi","$18 dan $8 ga, $10 kamayadi","$18 dan $18 ga, o‘zgarmaydi"],"why":["At $20 all three supply: surplus=(20−10)+(20−14)+(20−18)=$18. At $16 only the first two supply: (16−10)+(16−14)=$8, a $10 fall.","При цене $20 продают все трое: излишек 10+6+2=$18. При $16 продают лишь первые два: 6+2=$8. Снижение на $10.","$20 narxda uchalasi sotadi: ortiqchalik 10+6+2=$18. $16 da faqat dastlabki ikkitasi sotadi: 6+2=$8. $10 kamayadi."]},{"ref":"EC9708:G2:EC9708-G2-T1-T-012","d":"hard","sec":135,"k":"A","en":"On a country''s production possibility frontier, output combinations (textiles, grain) are A=(0,100), B=(10,90), C=(20,65) and D=(30,25). What is the opportunity cost in grain of increasing textiles from 10 to 20 units, and what does the next 10-unit textile increase illustrate?","ru":"На КПВ страны возможные комбинации (ткань, зерно): A=(0,100), B=(10,90), C=(20,65), D=(30,25). Какова альтернативная стоимость увеличения выпуска ткани с 10 до 20 единиц в зерне и какую закономерность показывает следующее увеличение ткани ещё на 10 единиц?","uz":"Mamlakat ishlab chiqarish imkoniyatlari egri chizig‘ida (mato, don) kombinatsiyalar A=(0,100), B=(10,90), C=(20,65), D=(30,25). Mato ishlab chiqarishni 10 dan 20 birlikka oshirishning don hisobidagi muqobil qiymati qancha va keyingi yana 10 birlik oshish nimani ko‘rsatadi?","options_en":["25 grain units; the next increase costs 40, showing rising opportunity cost","10 grain units; the next increase costs 25, showing constant opportunity cost","40 grain units; the next increase costs 25, showing falling opportunity cost","65 grain units; the next increase costs 25, showing falling opportunity cost"],"options_ru":["25 единиц зерна; следующий шаг стоит 40 — растущая альтернативная стоимость","10 единиц зерна; следующий шаг стоит 25 — постоянная стоимость","40 единиц зерна; следующий шаг стоит 25 — падающая стоимость","65 единиц зерна; следующий шаг стоит 25 — падающая стоимость"],"options_uz":["25 birlik don; keyingi qadam 40 dona — o‘suvchi muqobil qiymat","10 birlik don; keyingi qadam 25 dona — doimiy muqobil qiymat","40 birlik don; keyingi qadam 25 dona — kamayuvchi muqobil qiymat","65 birlik don; keyingi qadam 25 dona — kamayuvchi muqobil qiymat"],"why":["Moving B→C gains 10 textiles and sacrifices 90−65=25 grain. Moving C→D sacrifices 65−25=40 grain for the next 10 textiles, showing increasing opportunity cost.","При переходе B→C зерно падает с 90 до 65: потеря 25. При C→D теряется уже 40 зерна ради следующих 10 единиц ткани. Альтернативная стоимость растёт.","B→C da don 90 dan 65 ga tushib 25 birlik yo‘qotiladi. C→D da keyingi 10 mato uchun 40 don yo‘qotiladi. Muqobil qiymat oshadi."]},{"ref":"EC9708:G2:EC9708-G2-T1-T-018","d":"hard","sec":135,"k":"D","en":"A sports centre raises its class fee from $20 to $24. Weekly bookings fall from 100 to 90. Using the midpoint method for price elasticity of demand, which pair gives the change in weekly revenue and approximate absolute PED?","ru":"Спортивный центр повышает плату за занятие с $20 до $24. Число недельных записей падает со 100 до 90. Используя формулу средней точки для ценовой эластичности спроса, выберите изменение недельной выручки и приблизительное значение |PED|.","uz":"Sport markazi dars narxini $20 dan $24 ga oshiradi. Haftalik buyurtmalar 100 tadan 90 taga tushadi. Talab narx elastikligini o‘rta nuqta usulida hisoblab, haftalik tushum o‘zgarishi va taxminiy |PED| ni tanlang.","options_en":["Revenue −$160; |PED|≈1.73","Revenue +$160; |PED|≈1.73","Revenue −$160; |PED|≈0.58","Revenue +$160; |PED|≈0.58"],"options_ru":["Выручка −$160; |PED|≈1,73","Выручка +$160; |PED|≈1,73","Выручка −$160; |PED|≈0,58","Выручка +$160; |PED|≈0,58"],"options_uz":["Tushum −$160; |PED|≈1,73","Tushum +$160; |PED|≈1,73","Tushum −$160; |PED|≈0,58","Tushum +$160; |PED|≈0,58"],"why":["Revenue changes from 20×100=$2,000 to 24×90=$2,160, up $160. Midpoint elasticity |(−10/95)/(4/22)|≈0.58, so demand is inelastic over this change.","Выручка растёт с $2 000 до $2 160 (+$160). Эластичность по средней точке |(−10/95)/(4/22)|≈0,58 — спрос неэластичен на данном интервале.","Tushum $2000 dan $2160 ga, $160 oshadi. O‘rta nuqta elastikligi |(−10/95)/(4/22)|≈0,58, ya’ni talab noelastik."]},{"ref":"EC9708:G2:EC9708-G2-T1-T-019","d":"hard","sec":130,"k":"B","en":"A drought leaves a city with 310 units of water. It allocates two essential units to each of 120 households administratively. For discretionary pool use, a fee of $9 results in demand for 60 units. If no other uses exist, how much water remains unused, and which allocation mechanism is used?","ru":"Из-за засухи городу доступны 310 единиц воды. В административном порядке он выделяет каждому из 120 домохозяйств по две единицы для основных нужд. При цене $9 спрос на воду для бассейнов составляет 60 единиц. Других потребителей нет. Сколько воды остаётся и какие механизмы распределения используются?","uz":"Qurg‘oqchilik sabab shahar ixtiyorida 310 birlik suv bor. Ma’muriy tartibda 120 xonadonning har biriga asosiy ehtiyoj uchun ikki birlikdan ajratiladi. Hovuz uchun narx $9 bo‘lganda talab 60 birlik. Boshqa foydalanish yo‘q. Qancha suv qoladi va qanday taqsimlash usullari qo‘llanadi?","options_en":["No water remains; all water is allocated only by market prices","10 units remain; essentials are rationed administratively and discretionary use is price-based","70 units remain; market prices allocate every unit","60 units remain; administrative rationing applies only to swimming pools"],"options_ru":["Воды не осталось; вся вода распределяется исключительно по рыночным ценам","Остаётся 10 единиц; базовые нужды нормируются, дополнительный спрос регулируется ценой","Остаётся 70 единиц; все единицы распределяются рыночными ценами","Остаётся 60 единиц; административное нормирование действует только для бассейнов"],"options_uz":["Suv qolmaydi; hammasi faqat bozor narxi bilan taqsimlanadi","10 birlik qoladi; asosiy ehtiyoj ma’muriy ajratiladi, qo‘shimcha foydalanish narx bilan boshqariladi","70 birlik qoladi; hamma suv bozor narxi bilan taqsimlanadi","60 birlik qoladi; ma’muriy cheklov faqat hovuzlarga tegishli"],"why":["Essential allocation is 120×2=240 units, discretionary use is 60, total 300 of 310. Ten remain. The policy combines quantity rationing for essentials with price allocation for discretionary demand.","Базовым нуждам выделяют 120×2=240 единиц, бассейнам — 60. Всего используется 300 из 310, остаётся 10. Система сочетает нормирование и ценовой механизм.","Asosiy ehtiyojga 120×2=240 birlik, hovuzga 60 birlik ketadi. Jami 300/310, 10 birlik qoladi. Ma’muriy me’yor va narx usuli birga ishlaydi."]}]'::jsonb;
 x jsonb; oldq record; new_id bigint; i int; idx int; keytxt text; reftext text; cnt int;
 enwhy text; ruwhy text; uzwhy text; ez int; med int; hard int;
BEGIN
 IF jsonb_array_length(d)<>4 THEN RAISE EXCEPTION 'T1_four_hard_required'; END IF;
 IF EXISTS(SELECT 1 FROM public.tour_attempts at JOIN public.tours t ON t.id=at.tour_id WHERE t.subject_id=7 AND t.season_id=2 AND t.tour_no=1)
 THEN RAISE EXCEPTION 'T1_season2_attempts_exist'; END IF;
 SELECT count(*) INTO cnt FROM public.tours t JOIN public.tour_questions l ON l.tour_id=t.id AND l.is_active
 WHERE t.subject_id=7 AND t.season_id=2 AND t.tour_no=1;
 IF cnt<>20 THEN RAISE EXCEPTION 'T1_pool_not20_before: %',cnt; END IF;
 FOR x IN SELECT value FROM jsonb_array_elements(d) LOOP
   reftext:=x->>'ref';keytxt:=x->>'k';idx:=ascii(keytxt)-65;
   IF keytxt NOT IN ('A','B','C','D') OR x->>'d'<>'hard'
      OR jsonb_array_length(x->'options_en')<>4 OR jsonb_array_length(x->'options_ru')<>4
      OR jsonb_array_length(x->'options_uz')<>4
   THEN RAISE EXCEPTION 'T1_invalid_authoring: %',reftext; END IF;
   SELECT q.id,q.subject_id,q.topic,q.subtopic,q.quality_flag,l.tour_id,l.order_no
   INTO STRICT oldq FROM public.questions q JOIN public.tour_questions l ON l.question_id=q.id AND l.is_active
   JOIN public.tours t ON t.id=l.tour_id
   WHERE q.subject_id=7 AND t.subject_id=7 AND t.season_id=2 AND t.tour_no=1 AND q.book_ref=reftext;
   IF EXISTS(SELECT 1 FROM public.tour_answers a WHERE a.question_id=oldq.id)
      OR EXISTS(SELECT 1 FROM public.tour_session_answers_v4 a WHERE a.question_id=oldq.id)
      OR EXISTS(SELECT 1 FROM public.questions q WHERE q.subject_id=7 AND q.book_ref=reftext||'-V2')
   THEN RAISE EXCEPTION 'T1_history_or_duplicate: %',reftext; END IF;
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
   IF cnt<>1 THEN RAISE EXCEPTION 'T1_old_link_count: %',reftext; END IF;
   INSERT INTO public.tour_questions(tour_id,question_id,order_no,is_active) VALUES(oldq.tour_id,new_id,oldq.order_no,true);
   INSERT INTO public.question_version_links(old_question_id,new_question_id,link_type,reason)
   VALUES(oldq.id,new_id,'replacement','Economics Gen2 season2 Tour1: actual high-order difficulty replacement; old question preserved');
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
        jsonb_build_object('diagnostic_code','EC9708_G2_T1T'||substring(reftext from 'T-([0-9]{3})')||'_V2_'||chr(65+i)),
        'published');
   END LOOP;
 END LOOP;
 UPDATE public.questions q SET difficulty=
  CASE WHEN right(q.book_ref,3) IN ('002','004','005','007','009','014') THEN 'easy' ELSE 'medium' END
 WHERE q.subject_id=7 AND q.book_ref ~ '^EC9708:G2:EC9708-G2-T1-T-[0-9]{3}$'
   AND NOT EXISTS(SELECT 1 FROM jsonb_array_elements(d) z WHERE z->>'ref'=q.book_ref);
 GET DIAGNOSTICS cnt=ROW_COUNT;
 IF cnt<>16 THEN RAISE EXCEPTION 'T1_unchanged_expected16: %',cnt; END IF;
 SELECT count(*),count(*) FILTER(WHERE q.difficulty='easy'),
 count(*) FILTER(WHERE q.difficulty='medium'),count(*) FILTER(WHERE q.difficulty='hard')
 INTO cnt,ez,med,hard
 FROM public.tours t JOIN public.tour_questions l ON l.tour_id=t.id AND l.is_active
 JOIN public.questions q ON q.id=l.question_id WHERE t.subject_id=7 AND t.season_id=2 AND t.tour_no=1;
 IF cnt<>20 OR ez<>6 OR med<>10 OR hard<>4 THEN
 RAISE EXCEPTION 'T1_mix_invalid: %,%,%,%',cnt,ez,med,hard; END IF;
END $tour1$;
COMMIT;
