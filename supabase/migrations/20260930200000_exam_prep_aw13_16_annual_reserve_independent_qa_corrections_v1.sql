-- AW13-16 annual reserve independent QA corrections v1.
-- History-free draft reserve only. No publication or learner exposure.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_content_versions where id in (4815,4816) and status='draft')<>2
  then raise exception 'aw13_16 annual reserve QA: target draft versions missing'; end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4815,4816) and content_key in ('P1SER02-D03','P1TRI03-D02','P1TRI03-R03','P1TRI05-D02','P1TRI05-D03','P5DRV03-D03','P5PRO06-D02','P5DRV02-D02','P5DRV03-D02','P5DRV02-R04','P5GEO01-R03','P5PRO06-D03','P1SER01-D02','P1SER01-D03','P1CIR03-D02','P1SER01-R04','P1DIF01-D02','P1TRI04-D02'))<>18
  then raise exception 'aw13_16 annual reserve QA: correction targets missing'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id in (4815,4816))
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id in (4815,4816))
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id in (4815,4816))
  then raise exception 'aw13_16 annual reserve QA: target draft has learner/legacy history'; end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id in (4815,4816)
      and (m.lifecycle_state<>'draft' or m.exposure_state<>'withheld' or q.is_active or q.quality_status<>'draft')
  ) then raise exception 'aw13_16 annual reserve QA: draft exposure boundary changed'; end if;
end
$preflight$;

with fixes(content_key,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz) as (values
('P1SER02-D03','A sequence has nth term uₙ=7(−2)^(n−1). Which description is correct?','["arithmetic with difference −2","geometric with ratio 2","neither arithmetic nor geometric","geometric with ratio −2"]','D','Each term is obtained from the previous term by multiplying by −2, so the sequence is geometric with common ratio −2.','Последовательность имеет общий член uₙ=7(−2)^(n−1). Какое описание верно?','["арифметическая с разностью −2","геометрическая со знаменателем 2","ни арифметическая, ни геометрическая","геометрическая со знаменателем −2"]','Каждый следующий член получается умножением предыдущего на −2, поэтому это геометрическая прогрессия со знаменателем −2.','Ketma-ketlikning n-hadi uₙ=7(−2)^(n−1). Qaysi tavsif to‘g‘ri?','["ayirmasi −2 bo‘lgan arifmetik progressiya","maxraji 2 bo‘lgan geometrik progressiya","na arifmetik, na geometrik progressiya","maxraji −2 bo‘lgan geometrik progressiya"]','Har bir keyingi had oldingisini −2 ga ko‘paytirib olinadi, demak bu maxraji −2 bo‘lgan geometrik progressiya.'),
('P1TRI03-D02','Which angle cannot be returned as the principal value of sin⁻¹ when the calculator is in degree mode?','["135°","30°","−45°","90°"]','A','The principal-value range of sin⁻¹ is −90°≤θ≤90°. Therefore 135° cannot be a principal inverse-sine output.','Какой угол не может быть главным значением sin⁻¹, если калькулятор работает в градусном режиме?','["135°","30°","−45°","90°"]','Диапазон главных значений sin⁻¹: −90°≤θ≤90°. Поэтому 135° не может быть главным значением обратного синуса.','Kalkulyator gradus rejimida bo‘lganda qaysi burchak sin⁻¹ ning bosh qiymati bo‘la olmaydi?','["135°","30°","−45°","90°"]','sin⁻¹ ning bosh qiymatlar oralig‘i −90°≤θ≤90°. Shuning uchun 135° teskari sinusning bosh qiymati bo‘la olmaydi.'),
('P1TRI03-R03','In degree mode, a calculator evaluates cos⁻¹(−0.4). Enter the principal value to 1 decimal place.','[]','113.6','cos⁻¹(−0.4)≈113.578°, so the principal value is 113.6° to 1 decimal place.','В градусном режиме калькулятор вычисляет cos⁻¹(−0,4). Введите главное значение с точностью до 1 десятичного знака.','[]','cos⁻¹(−0,4)≈113,578°, поэтому главное значение равно 113,6° с точностью до 1 десятичного знака.','Gradus rejimida kalkulyator cos⁻¹(−0.4) ni hisoblaydi. Bosh qiymatni 1 ta o‘nli xonagacha kiriting.','[]','cos⁻¹(−0.4)≈113.578°, demak bosh qiymat 1 ta o‘nli xonagacha 113.6°.'),
('P1TRI05-D02','Solve 2cos θ+√2=0 for −180°≤θ<180°.','["−135°, 135°","−45°, 45°","45°, 135°","−135°, −45°"]','A','The equation gives cosθ=−√2/2. In the stated interval the solutions are −135° and 135°.','Решите 2cos θ+√2=0 при −180°≤θ<180°.','["−135°, 135°","−45°, 45°","45°, 135°","−135°, −45°"]','Уравнение даёт cosθ=−√2/2. На указанном промежутке решения равны −135° и 135°.','−180°≤θ<180° da 2cos θ+√2=0 tenglamani yeching.','["−135°, 135°","−45°, 45°","45°, 135°","−135°, −45°"]','Tenglama cosθ=−√2/2 ni beradi. Berilgan oraliqda yechimlar −135° va 135°.'),
('P1TRI05-D03','Solve 3tan θ=√3 for −90°<θ≤270°.','["−30°, 150°","30°, 210°","60°, 240°","30°, 150°"]','B','tanθ=√3/3 gives reference angle 30°. With period 180°, the solutions in the interval are 30° and 210°.','Решите 3tan θ=√3 при −90°<θ≤270°.','["−30°, 150°","30°, 210°","60°, 240°","30°, 150°"]','tanθ=√3/3 даёт опорный угол 30°. С периодом 180° решения на промежутке: 30° и 210°.','−90°<θ≤270° da 3tan θ=√3 tenglamani yeching.','["−30°, 150°","30°, 210°","60°, 240°","30°, 150°"]','tanθ=√3/3 dan tayanch burchak 30°. Davr 180° bo‘lgani uchun oraliqdagi yechimlar 30° va 210°.'),
('P5DRV03-D03','X takes values 0, 2 and 5 with probabilities 0.2, 0.5 and 0.3. What is the standard deviation of X?','["3.25","√13/2","13/4","2.5"]','B','E(X)=2.5 and E(X²)=9.5. Hence Var(X)=9.5−2.5²=13/4, so the standard deviation is √13/2.','X принимает значения 0, 2 и 5 с вероятностями 0,2; 0,5 и 0,3. Каково стандартное отклонение X?','["3,25","√13/2","13/4","2,5"]','E(X)=2,5 и E(X²)=9,5. Поэтому Var(X)=9,5−2,5²=13/4, а стандартное отклонение равно √13/2.','X 0, 2 va 5 qiymatlarni 0.2, 0.5 va 0.3 ehtimollar bilan oladi. X ning standart og‘ishi qancha?','["3.25","√13/2","13/4","2.5"]','E(X)=2.5 va E(X²)=9.5. Demak Var(X)=9.5−2.5²=13/4, standart og‘ish esa √13/2.'),
('P5PRO06-D02','A bag contains 5 red and 4 blue counters. Two are drawn without replacement. Find the probability of getting exactly one red counter.','["5/18","10/81","4/9","5/9"]','D','P(exactly one red)=5/9×4/8+4/9×5/8=40/72=5/9.','В мешке 5 красных и 4 синие фишки. Две фишки вытаскивают без возвращения. Найдите вероятность получить ровно одну красную фишку.','["5/18","10/81","4/9","5/9"]','P(ровно одна красная)=5/9×4/8+4/9×5/8=40/72=5/9.','Qopda 5 qizil va 4 ko‘k jeton bor. Ikki jeton qaytarmasdan olinadi. Aynan bitta qizil jeton chiqish ehtimolini toping.','["5/18","10/81","4/9","5/9"]','P(aynan bitta qizil)=5/9×4/8+4/9×5/8=40/72=5/9.'),
('P5DRV02-D02','A game gives a net gain of −2 units with probability 0.25, 1 unit with probability 0.50 and 6 units with probability 0.25. Find the expected gain.','["1.0","1.5","2.0","2.5"]','B','E(X)=−2(0.25)+1(0.50)+6(0.25)=−0.5+0.5+1.5=1.5.','Игра даёт чистый выигрыш −2 единицы с вероятностью 0,25, 1 единицу с вероятностью 0,50 и 6 единиц с вероятностью 0,25. Найдите ожидаемый выигрыш.','["1,0","1,5","2,0","2,5"]','E(X)=−2(0,25)+1(0,50)+6(0,25)=−0,5+0,5+1,5=1,5.','O‘yin 0.25 ehtimol bilan −2 birlik, 0.50 ehtimol bilan 1 birlik va 0.25 ehtimol bilan 6 birlik sof yutuq beradi. Kutiladigan yutuqni toping.','["1.0","1.5","2.0","2.5"]','E(X)=−2(0.25)+1(0.50)+6(0.25)=−0.5+0.5+1.5=1.5.'),
('P5DRV03-D02','X takes values 0, 1 and 4 with probabilities 0.50, 0.25 and 0.25. Find Var(X).','["43/16","17/4","25/16","11/4"]','A','E(X)=5/4 and E(X²)=17/4. Hence Var(X)=17/4−(5/4)²=68/16−25/16=43/16.','X принимает значения 0, 1 и 4 с вероятностями 0,50; 0,25 и 0,25. Найдите Var(X).','["43/16","17/4","25/16","11/4"]','E(X)=5/4 и E(X²)=17/4. Поэтому Var(X)=17/4−(5/4)²=68/16−25/16=43/16.','X 0, 1 va 4 qiymatlarni 0.50, 0.25 va 0.25 ehtimollar bilan oladi. Var(X) ni toping.','["43/16","17/4","25/16","11/4"]','E(X)=5/4 va E(X²)=17/4. Demak Var(X)=17/4−(5/4)²=68/16−25/16=43/16.'),
('P5DRV02-R04','A game pays 0 units with probability 0.30, 4 units with probability 0.50 and k units with probability 0.20. If the expected payout is 3.4 units, find k.','["4","5","6","7"]','D','3.4=0(0.30)+4(0.50)+0.20k=2+0.20k, so k=7.','Игра выплачивает 0 единиц с вероятностью 0,30, 4 единицы с вероятностью 0,50 и k единиц с вероятностью 0,20. Если ожидаемая выплата равна 3,4 единицы, найдите k.','["4","5","6","7"]','3,4=0(0,30)+4(0,50)+0,20k=2+0,20k, поэтому k=7.','O‘yin 0.30 ehtimol bilan 0 birlik, 0.50 ehtimol bilan 4 birlik va 0.20 ehtimol bilan k birlik to‘laydi. Kutiladigan to‘lov 3.4 birlik bo‘lsa, k ni toping.','["4","5","6","7"]','3.4=0(0.30)+4(0.50)+0.20k=2+0.20k, demak k=7.'),
('P5GEO01-R03','Independent trials continue until the first success. The success probability is 0.30 on the first trial but 0.40 after a failure. Enter 1 if an ordinary geometric model is exact, or 0 if it is not.','[]','0','An ordinary geometric model requires a constant success probability on every trial. Here p changes, so the model is not exact.','Независимые испытания продолжаются до первого успеха. Вероятность успеха равна 0,30 в первом испытании, но после неудачи становится 0,40. Введите 1, если обычная геометрическая модель точна, или 0, если нет.','[]','Обычная геометрическая модель требует постоянной вероятности успеха в каждом испытании. Здесь p меняется, поэтому модель неточна.','Mustaqil sinovlar birinchi muvaffaqiyatgacha davom etadi. Birinchi sinovda muvaffaqiyat ehtimoli 0.30, lekin muvaffaqiyatsizlikdan keyin 0.40 bo‘ladi. Oddiy geometrik model aniq bo‘lsa 1, aks holda 0 kiriting.','[]','Oddiy geometrik model har bir sinovda muvaffaqiyat ehtimoli o‘zgarmas bo‘lishini talab qiladi. Bu yerda p o‘zgaradi, shuning uchun model aniq emas.'),
('P5PRO06-D03','A factory uses machine A for 60% of items and machine B for 40%. The defect probability is 0.02 after A and 0.05 after B. Find the overall probability that a randomly chosen item is defective.','["0.032","0.030","0.070","0.028"]','A','P(defective)=0.60(0.02)+0.40(0.05)=0.012+0.020=0.032.','Фабрика производит 60% изделий на станке A и 40% на станке B. Вероятность дефекта после A равна 0,02, после B — 0,05. Найдите общую вероятность того, что случайно выбранное изделие дефектно.','["0,032","0,030","0,070","0,028"]','P(дефект)=0,60(0,02)+0,40(0,05)=0,012+0,020=0,032.','Zavod buyumlarning 60% ini A stanokda, 40% ini B stanokda ishlab chiqaradi. A dan keyin nuqson ehtimoli 0.02, B dan keyin 0.05. Tasodifiy tanlangan buyum nuqsonli bo‘lishining umumiy ehtimolini toping.','["0.032","0.030","0.070","0.028"]','P(nuqson)=0.60(0.02)+0.40(0.05)=0.012+0.020=0.032.'),
('P1SER01-D02','Find the coefficient of x² in (1+2x)³(1−x).','["6","12","18","24"]','A','(1+2x)³=1+6x+12x²+8x³. Multiplying by (1−x), the x² coefficient is 12−6=6.','Найдите коэффициент при x² в произведении (1+2x)³(1−x).','["6","12","18","24"]','(1+2x)³=1+6x+12x²+8x³. После умножения на (1−x) коэффициент при x² равен 12−6=6.','(1+2x)³(1−x) ko‘paytmada x² oldidagi koeffitsiyentni toping.','["6","12","18","24"]','(1+2x)³=1+6x+12x²+8x³. (1−x) ga ko‘paytirilganda x² koeffitsiyenti 12−6=6.'),
('P1SER01-D03','The coefficient of x² in (1+kx)⁴ is 54, where k>0. Find k.','["√3","2","3","9"]','C','The x² coefficient is 4C2 k²=6k². Hence 6k²=54, so k²=9 and k=3 because k>0.','Коэффициент при x² в разложении (1+kx)⁴ равен 54, где k>0. Найдите k.','["√3","2","3","9"]','Коэффициент при x² равен 4C2 k²=6k². Поэтому 6k²=54, k²=9 и k=3, так как k>0.','(1+kx)⁴ yoyilmasida x² oldidagi koeffitsiyent 54, bunda k>0. k ni toping.','["√3","2","3","9"]','x² koeffitsiyenti 4C2 k²=6k². Demak 6k²=54, k²=9 va k>0 bo‘lgani uchun k=3.'),
('P1CIR03-D02','Two non-overlapping sectors of the same circle have radius 10 cm and angles 1.1 and 0.4 radians. What is the difference between their areas?','["35 cm²","55 cm²","20 cm²","70 cm²"]','A','The difference is 1/2×10²×(1.1−0.4)=50×0.7=35 cm².','Два неперекрывающихся сектора одной окружности имеют радиус 10 см и углы 1,1 и 0,4 радиана. Какова разность их площадей?','["35 см²","55 см²","20 см²","70 см²"]','Разность площадей равна 1/2×10²×(1,1−0,4)=50×0,7=35 см².','Bitta aylananing ustma-ust tushmaydigan ikki sektori radiusi 10 sm, burchaklari 1.1 va 0.4 radian. Ularning yuzalari farqi qancha?','["35 sm²","55 sm²","20 sm²","70 sm²"]','Yuzalar farqi 1/2×10²×(1.1−0.4)=50×0.7=35 sm².'),
('P1SER01-R04','Find the coefficient of x² in (2+x)³(1−x).','["6","−6","−12","12"]','B','(2+x)³=8+12x+6x²+x³. Multiplying by (1−x), the x² coefficient is 6−12=−6.','Найдите коэффициент при x² в произведении (2+x)³(1−x).','["6","−6","−12","12"]','(2+x)³=8+12x+6x²+x³. После умножения на (1−x) коэффициент при x² равен 6−12=−6.','(2+x)³(1−x) ko‘paytmada x² oldidagi koeffitsiyentni toping.','["6","−6","−12","12"]','(2+x)³=8+12x+6x²+x³. (1−x) ga ko‘paytirilganda x² koeffitsiyenti 6−12=−6.'),
('P1DIF01-D02','Which limit is the derivative of f(x)=x²+1 at x=2?','["lim(h→0) [((2+h)²+1)−5]/h","lim(h→0) [((2+h)²+1)−2]/h","lim(h→0) [(2+h)²−4]/2","lim(h→0) [(2+h)²−5]/h"]','A','By definition f′(2)=lim(h→0)[f(2+h)−f(2)]/h. Here f(2)=5 and f(2+h)=(2+h)²+1.','Какой предел является производной f(x)=x²+1 при x=2?','["lim(h→0) [((2+h)²+1)−5]/h","lim(h→0) [((2+h)²+1)−2]/h","lim(h→0) [(2+h)²−4]/2","lim(h→0) [(2+h)²−5]/h"]','По определению f′(2)=lim(h→0)[f(2+h)−f(2)]/h. Здесь f(2)=5, а f(2+h)=(2+h)²+1.','f(x)=x²+1 funksiyaning x=2 dagi hosilasi qaysi limit bilan ifodalanadi?','["lim(h→0) [((2+h)²+1)−5]/h","lim(h→0) [((2+h)²+1)−2]/h","lim(h→0) [(2+h)²−4]/2","lim(h→0) [(2+h)²−5]/h"]','Ta’rif bo‘yicha f′(2)=lim(h→0)[f(2+h)−f(2)]/h. Bu yerda f(2)=5 va f(2+h)=(2+h)²+1.'),
('P1TRI04-D02','For sin x cos x≠0, simplify tan x(1−cos²x)/sin x.','["sin²x/cos x","sin x","cos x","tan x"]','A','Use tan x=sin x/cos x and 1−cos²x=sin²x. Then (sin x/cos x)(sin²x)/sin x=sin²x/cos x.','При sin x cos x≠0 упростите tan x(1−cos²x)/sin x.','["sin²x/cos x","sin x","cos x","tan x"]','Используйте tan x=sin x/cos x и 1−cos²x=sin²x. Тогда (sin x/cos x)(sin²x)/sin x=sin²x/cos x.','sin x cos x≠0 bo‘lganda tan x(1−cos²x)/sin x ni soddalashtiring.','["sin²x/cos x","sin x","cos x","tan x"]','tan x=sin x/cos x va 1−cos²x=sin²x dan foydalaning. Shunda (sin x/cos x)(sin²x)/sin x=sin²x/cos x.')
)
update public.questions q
set question_text=f.q_en,
    question_text_en=f.q_en,
    question_text_ru=f.q_ru,
    question_text_uz=f.q_uz,
    options_text=f.opts_en,
    options_text_en=f.opts_en,
    options_text_ru=f.opts_ru,
    options_text_uz=f.opts_uz,
    correct_answer=f.answer,
    explanation=f.exp_en,
    explanation_en=f.exp_en,
    explanation_ru=f.exp_ru,
    explanation_uz=f.exp_uz
from fixes f
join private.exam_prep_question_content_meta m
  on m.content_version_id in (4815,4816) and m.content_key=f.content_key
where q.id=m.question_id
  and q.is_active=false and q.quality_status='draft';

update private.exam_prep_question_content_meta m
set question_snapshot_md5=md5(concat_ws(chr(31),
      q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
      coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
      coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
      coalesce(q.quality_flag,''),coalesce(q.quality_status,''))),
    updated_at=now()
from public.questions q
where q.id=m.question_id
  and m.content_version_id in (4815,4816)
  and m.content_key in ('P1SER02-D03','P1TRI03-D02','P1TRI03-R03','P1TRI05-D02','P1TRI05-D03','P5DRV03-D03','P5PRO06-D02','P5DRV02-D02','P5DRV03-D02','P5DRV02-R04','P5GEO01-R03','P5PRO06-D03','P1SER01-D02','P1SER01-D03','P1CIR03-D02','P1SER01-R04','P1DIF01-D02','P1TRI04-D02');

do $postcheck$
declare v_bad int;
begin
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
    and (
      nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
      or (q.qtype='mcq' and (
        q.correct_answer not in ('A','B','C','D')
        or jsonb_array_length(q.options_text_en::jsonb)<>4
        or jsonb_array_length(q.options_text_ru::jsonb)<>4
        or jsonb_array_length(q.options_text_uz::jsonb)<>4
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_en::jsonb) z(v))<>4
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_ru::jsonb) z(v))<>4
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_uz::jsonb) z(v))<>4
      ))
      or (q.qtype='input' and (
        nullif(btrim(q.correct_answer),'') is null
        or q.options_text_en::jsonb<>'[]'::jsonb
        or q.options_text_ru::jsonb<>'[]'::jsonb
        or q.options_text_uz::jsonb<>'[]'::jsonb
      ))
      or md5(concat_ws(chr(31),
        q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
        coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
        coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
        coalesce(q.image_url,''),coalesce(q.is_active::text,''),
        coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
        coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
        coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
        coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
        coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5
    );
  if v_bad<>0 then raise exception 'aw13_16 annual reserve QA: payload/snapshot rows=%',v_bad; end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id not in (4815,4816)
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4815,4816)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw13_16 annual reserve QA: exact published stem reuse remains'; end if;

  -- Diagnostic correct positions are intentionally unchanged so pre-authored misconception rules remain valid.
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4815,4816)
    and m.reserve_role='diagnostic'
    and (
      q.qtype<>'mcq'
      or (select count(*) from private.exam_prep_diagnostic_rules r
          where r.content_meta_id=m.id and r.rule_version='aw_reserve_v1' and r.status='draft'
            and r.answer_kind='mcq_option' and r.answer_match<>q.correct_answer
            and r.weak_skill_code=m.primary_skill_code)<>3
    );
  if v_bad<>0 then raise exception 'aw13_16 annual reserve QA: diagnostic rule/answer drift rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id in (4815,4816)
      and (q.options_text_ru ~* '\m(or|only|cm)\M' or q.options_text_uz ~* '\m(or|only|cm)\M')
  ) then raise exception 'aw13_16 annual reserve QA: untranslated learner option token'; end if;
end
$postcheck$;

commit;
