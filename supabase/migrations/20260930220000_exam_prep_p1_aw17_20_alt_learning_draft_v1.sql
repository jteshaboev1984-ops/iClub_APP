-- AW17-20 supplemental learning pack draft for P1.
-- DRAFT ONLY: no learner exposure, QA self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw17_20_alt_p1_draft canonical program missing'; end if;
  if exists(select 1 from private.exam_prep_content_versions where id=4817 and content_version<>'p1_aw17_20_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15653 and 15658 and content_version_id<>4817)
     or exists(select 1 from private.exam_prep_assessments where id between 35472 and 35477 and content_version_id<>4817)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59390 and 59407 and content_version_id<>4817)
  then raise exception 'aw17_20_alt_p1_draft reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4817,pv.id,'p1_aw17_20_alt_learning_draft_v1','P1',
 'P1 AW17-20 supplemental learning pack draft v1','draft',
 'Original iClub-authored supplemental learning content. Official Cambridge 9709 scope and Complete Pure Mathematics 1 mappings define learning objectives only; no protected source question, solution, diagram or mark-scheme wording is copied. Independent academic, language, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P1SER03-A01','P1-SER-03','P1 Series','medium','mcq','In an arithmetic progression, the 4th term is 14 and the 10th term is 32. Find the common difference.','["2","4","3","6"]','C','u10−u4=6d, so 32−14=18=6d and d=3.','В арифметической прогрессии 4-й член равен 14, а 10-й член равен 32. Найдите разность.','["2","4","3","6"]','u10−u4=6d, поэтому 32−14=18=6d и d=3.','Arifmetik progressiyada 4-had 14, 10-had 32 ga teng. Umumiy ayirmani toping.','["2","4","3","6"]','u10−u4=6d, demak 32−14=18=6d va d=3.',65),
('P1SER03-A02','P1-SER-03','P1 Series','medium','mcq','An arithmetic progression has first term 5 and common difference 4. Find the sum of the first 12 terms.','["270","294","300","324"]','D','S12=12/2[2(5)+11(4)]=6(54)=324.','В арифметической прогрессии первый член равен 5, а разность равна 4. Найдите сумму первых 12 членов.','["270","294","300","324"]','S12=12/2[2(5)+11(4)]=6(54)=324.','Arifmetik progressiyaning birinchi hadi 5, umumiy ayirmasi 4. Dastlabki 12 had yig‘indisini toping.','["270","294","300","324"]','S12=12/2[2(5)+11(4)]=6(54)=324.',70),
('P1SER03-A03','P1-SER-03','P1 Series','medium','input','An arithmetic progression has first term −2 and common difference 5. Enter the 17th term.','[]','78','u17=a+16d=−2+16(5)=78.','В арифметической прогрессии первый член равен −2, а разность равна 5. Введите 17-й член.','[]','u17=a+16d=−2+16(5)=78.','Arifmetik progressiyaning birinchi hadi −2, umumiy ayirmasi 5. 17-hadni kiriting.','[]','u17=a+16d=−2+16(5)=78.',55),
('P1SER04-A01','P1-SER-04','P1 Series','medium','mcq','A geometric progression has first term 3 and common ratio −2. Find the fifth term.','["48","−48","24","−24"]','A','u5=ar^4=3(−2)^4=48.','В геометрической прогрессии первый член равен 3, а знаменатель равен −2. Найдите пятый член.','["48","−48","24","−24"]','u5=ar^4=3(−2)^4=48.','Geometrik progressiyaning birinchi hadi 3, umumiy maxraji −2. Beshinchi hadni toping.','["48","−48","24","−24"]','u5=ar^4=3(−2)^4=48.',55),
('P1SER04-A02','P1-SER-04','P1 Series','hard','mcq','A geometric progression has second term 6 and fifth term 162, with positive common ratio. Find the common ratio.','["2","3","6","9"]','B','u5/u2=r^3=162/6=27, so r=3.','В геометрической прогрессии второй член равен 6, пятый — 162, а знаменатель положительный. Найдите знаменатель.','["2","3","6","9"]','u5/u2=r^3=162/6=27, поэтому r=3.','Geometrik progressiyada ikkinchi had 6, beshinchi had 162 va umumiy maxraj musbat. Umumiy maxrajni toping.','["2","3","6","9"]','u5/u2=r^3=162/6=27, demak r=3.',75),
('P1SER04-A03','P1-SER-04','P1 Series','medium','input','A geometric progression has first term 81 and common ratio 1/3. The sixth term is a fraction in simplest form. Enter its denominator.','[]','3','u6=81(1/3)^5=81/243=1/3, so the denominator is 3.','В геометрической прогрессии первый член равен 81, а знаменатель равен 1/3. Шестой член записан несократимой дробью. Введите её знаменатель.','[]','u6=81(1/3)^5=81/243=1/3, поэтому знаменатель равен 3.','Geometrik progressiyaning birinchi hadi 81, umumiy maxraji 1/3. Oltinchi had qisqartirilgan kasr ko‘rinishida. Maxrajini kiriting.','[]','u6=81(1/3)^5=81/243=1/3, demak maxraj 3.',60),
('P1SER05-A01','P1-SER-05','P1 Series','medium','mcq','A geometric series has first term 14 and common ratio −0.75. Find its sum to infinity.','["56","24","8","3.5"]','C','Since |r|<1, S∞=a/(1−r)=14/[1−(−0.75)]=14/1.75=8.','Геометрическая прогрессия имеет первый член 14 и знаменатель −0,75. Найдите сумму до бесконечности.','["56","24","8","3,5"]','Так как |r|<1, S∞=a/(1−r)=14/[1−(−0,75)]=14/1,75=8.','Geometrik qatorning birinchi hadi 14, umumiy maxraji −0.75. Cheksiz yig‘indisini toping.','["56","24","8","3.5"]','|r|<1 bo‘lgani uchun S∞=a/(1−r)=14/[1−(−0.75)]=14/1.75=8.',65),
('P1SER05-A02','P1-SER-05','P1 Series','medium','mcq','A convergent geometric series has first term 12 and sum to infinity 20. Find its common ratio.','["−0.4","0.25","0.6","0.4"]','D','20=12/(1−r), so 1−r=0.6 and r=0.4.','Сходящийся геометрический ряд имеет первый член 12 и сумму до бесконечности 20. Найдите знаменатель.','["−0,4","0,25","0,6","0,4"]','20=12/(1−r), поэтому 1−r=0,6 и r=0,4.','Yaqinlashuvchi geometrik qatorning birinchi hadi 12, cheksiz yig‘indisi 20. Umumiy maxrajni toping.','["−0.4","0.25","0.6","0.4"]','20=12/(1−r), demak 1−r=0.6 va r=0.4.',65),
('P1SER05-A03','P1-SER-05','P1 Series','hard','input','The geometric series 9+3+1+... converges. Enter the sum of all terms after the first two terms.','[]','1.5','The third term is 1 and r=1/3. The tail from the third term has sum 1/(1−1/3)=3/2=1.5.','Геометрический ряд 9+3+1+... сходится. Введите сумму всех членов после первых двух.','[]','Третий член равен 1, r=1/3. Сумма хвоста начиная с третьего члена равна 1/(1−1/3)=3/2=1,5.','9+3+1+... geometrik qatori yaqinlashadi. Dastlabki ikki haddan keyingi barcha hadlar yig‘indisini kiriting.','[]','Uchinchi had 1 va r=1/3. Uchinchi haddan boshlangan qator yig‘indisi 1/(1−1/3)=3/2=1.5.',70),
('P1DIF02-A01','P1-DIF-02','P1 Differentiation','medium','mcq','Differentiate y=6x^(1/2)−2x^(−1).','["3x^(−1/2)+2x^(−2)","3x^(1/2)−2x^(−2)","6x^(−1/2)+2x^(−2)","3x^(−1/2)−2x^(−2)"]','A','dy/dx=6(1/2)x^(−1/2)−2(−1)x^(−2)=3x^(−1/2)+2x^(−2).','Найдите производную y=6x^(1/2)−2x^(−1).','["3x^(−1/2)+2x^(−2)","3x^(1/2)−2x^(−2)","6x^(−1/2)+2x^(−2)","3x^(−1/2)−2x^(−2)"]','dy/dx=6(1/2)x^(−1/2)−2(−1)x^(−2)=3x^(−1/2)+2x^(−2).','y=6x^(1/2)−2x^(−1) funksiyani differensiallang.','["3x^(−1/2)+2x^(−2)","3x^(1/2)−2x^(−2)","6x^(−1/2)+2x^(−2)","3x^(−1/2)−2x^(−2)"]','dy/dx=6(1/2)x^(−1/2)−2(−1)x^(−2)=3x^(−1/2)+2x^(−2).',65),
('P1DIF02-A02','P1-DIF-02','P1 Differentiation','medium','mcq','For f(x)=x^(3/2)+4x^(1/2), find f′(4).','["3","4","5","6"]','B','f′(x)=(3/2)x^(1/2)+2x^(−1/2). At x=4 this is 3+1=4.','Для f(x)=x^(3/2)+4x^(1/2) найдите f′(4).','["3","4","5","6"]','f′(x)=(3/2)x^(1/2)+2x^(−1/2). При x=4 получаем 3+1=4.','f(x)=x^(3/2)+4x^(1/2) uchun f′(4) ni toping.','["3","4","5","6"]','f′(x)=(3/2)x^(1/2)+2x^(−1/2). x=4 da 3+1=4.',65),
('P1DIF02-A03','P1-DIF-02','P1 Differentiation','medium','input','For y=5x^(2/3), dy/dx at x=8 is a fraction in simplest form. Enter its numerator.','[]','5','dy/dx=(10/3)x^(−1/3). At x=8, x^(−1/3)=1/2, so dy/dx=5/3 and the numerator is 5.','Для y=5x^(2/3) значение dy/dx при x=8 является несократимой дробью. Введите её числитель.','[]','dy/dx=(10/3)x^(−1/3). При x=8 имеем x^(−1/3)=1/2, поэтому dy/dx=5/3 и числитель равен 5.','y=5x^(2/3) uchun x=8 dagi dy/dx qisqartirilgan kasr ko‘rinishida. Uning suratini kiriting.','[]','dy/dx=(10/3)x^(−1/3). x=8 da x^(−1/3)=1/2, demak dy/dx=5/3 va surat 5.',70),
('P1DIF03-A01','P1-DIF-03','P1 Differentiation','medium','mcq','Differentiate y=(4x−3)^5.','["5(4x−3)^4","80(4x−3)^4","20(4x−3)^4","20(4x−3)^5"]','C','By the chain rule, dy/dx=5(4x−3)^4×4=20(4x−3)^4.','Найдите производную y=(4x−3)^5.','["5(4x−3)^4","80(4x−3)^4","20(4x−3)^4","20(4x−3)^5"]','По правилу цепочки dy/dx=5(4x−3)^4×4=20(4x−3)^4.','y=(4x−3)^5 funksiyani differensiallang.','["5(4x−3)^4","80(4x−3)^4","20(4x−3)^4","20(4x−3)^5"]','Zanjir qoidasiga ko‘ra dy/dx=5(4x−3)^4×4=20(4x−3)^4.',60),
('P1DIF03-A02','P1-DIF-03','P1 Differentiation','medium','mcq','For f(x)=(3−2x)^(−2), find f′(0).','["−4/27","−4/9","4/9","4/27"]','D','f′(x)=−2(3−2x)^(−3)(−2)=4(3−2x)^(−3). Thus f′(0)=4/27.','Для f(x)=(3−2x)^(−2) найдите f′(0).','["−4/27","−4/9","4/9","4/27"]','f′(x)=−2(3−2x)^(−3)(−2)=4(3−2x)^(−3). Поэтому f′(0)=4/27.','f(x)=(3−2x)^(−2) uchun f′(0) ni toping.','["−4/27","−4/9","4/9","4/27"]','f′(x)=−2(3−2x)^(−3)(−2)=4(3−2x)^(−3). Demak f′(0)=4/27.',65),
('P1DIF03-A03','P1-DIF-03','P1 Differentiation','medium','input','For y=(5x+1)^3, enter dy/dx at x=0.','[]','15','dy/dx=3(5x+1)^2×5=15(5x+1)^2, so at x=0 the value is 15.','Для y=(5x+1)^3 введите dy/dx при x=0.','[]','dy/dx=3(5x+1)^2×5=15(5x+1)^2, поэтому при x=0 значение равно 15.','y=(5x+1)^3 uchun x=0 dagi dy/dx ni kiriting.','[]','dy/dx=3(5x+1)^2×5=15(5x+1)^2, demak x=0 da qiymat 15.',55),
('P1DIF04-A01','P1-DIF-04','P1 Differentiation','medium','mcq','For y=x^3−2x, find the equation of the tangent at x=1.','["y=x−2","y=3x−4","y=x+2","y=−x"]','A','At x=1, y=−1 and dy/dx=3x²−2=1. Thus y+1=x−1, so y=x−2.','Для y=x^3−2x найдите уравнение касательной при x=1.','["y=x−2","y=3x−4","y=x+2","y=−x"]','При x=1 имеем y=−1 и dy/dx=3x²−2=1. Поэтому y+1=x−1, то есть y=x−2.','y=x^3−2x uchun x=1 dagi urinma tenglamasini toping.','["y=x−2","y=3x−4","y=x+2","y=−x"]','x=1 da y=−1 va dy/dx=3x²−2=1. Demak y+1=x−1, ya’ni y=x−2.',70),
('P1DIF04-A02','P1-DIF-04','P1 Differentiation','hard','mcq','For y=√x, find the equation of the normal at x=4.','["y=4x−14","y=−4x+18","y=−x/4+3","y=4x+18"]','B','At x=4 the point is (4,2). The tangent gradient is 1/(2√4)=1/4, so the normal gradient is −4. Hence y−2=−4(x−4), giving y=−4x+18.','Для y=√x найдите уравнение нормали при x=4.','["y=4x−14","y=−4x+18","y=−x/4+3","y=4x+18"]','При x=4 точка равна (4,2). Градиент касательной равен 1/(2√4)=1/4, поэтому градиент нормали равен −4. Тогда y−2=−4(x−4), то есть y=−4x+18.','y=√x uchun x=4 dagi normal tenglamasini toping.','["y=4x−14","y=−4x+18","y=−x/4+3","y=4x+18"]','x=4 da nuqta (4,2). Urinma gradienti 1/(2√4)=1/4, normal gradienti −4. Demak y−2=−4(x−4), ya’ni y=−4x+18.',75),
('P1DIF04-A03','P1-DIF-04','P1 Differentiation','medium','input','For y=2x²+1, find the tangent at x=−1. Enter the y-intercept of the tangent.','[]','-1','At x=−1, the point is (−1,3) and the tangent gradient is 4x=−4. Thus y−3=−4(x+1), so y=−4x−1 and the y-intercept is −1.','Для y=2x²+1 найдите касательную при x=−1. Введите y-пересечение касательной.','[]','При x=−1 точка равна (−1,3), а градиент касательной 4x=−4. Поэтому y−3=−4(x+1), то есть y=−4x−1, и y-пересечение равно −1.','y=2x²+1 uchun x=−1 dagi urinmani toping. Urinmaning y-o‘q bilan kesishish qiymatini kiriting.','[]','x=−1 da nuqta (−1,3), urinma gradienti 4x=−4. Demak y−3=−4(x+1), ya’ni y=−4x−1 va y-kesishish −1.',70)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,s.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P1:p1_aw17_20_alt_learning_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_aw17_20_alt_learning_draft_v1:'||s.content_key);

insert into private.exam_prep_written_tasks(
 id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
 prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
 lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15653,4817,'P1SER03-AW18','P1','P1-SER-03','{}','v1','An arithmetic progression has 5th term 18 and 14th term 54. (a) Find the common difference and first term. (b) Find the 30th term. (c) Find the sum of the first 30 terms. Show how the nth-term and sum formulae are used.','В арифметической прогрессии 5-й член равен 18, а 14-й член равен 54. (a) Найдите разность и первый член. (b) Найдите 30-й член. (c) Найдите сумму первых 30 членов. Покажите использование формул n-го члена и суммы.','Arifmetik progressiyada 5-had 18, 14-had 54 ga teng. (a) Umumiy ayirma va birinchi hadni toping. (b) 30-hadni toping. (c) Dastlabki 30 had yig‘indisini toping. n-had va yig‘indi formulalaridan qanday foydalanganingizni ko‘rsating.','{"criteria":[{"id":"d","rule":"Uses u14−u5=9d to obtain d=4.","marks":1},{"id":"a","rule":"Finds a=2.","marks":1},{"id":"u30","rule":"Finds u30=118.","marks":1},{"id":"sum_method","rule":"Uses a valid arithmetic-series sum formula with n=30.","marks":1},{"id":"sum","rule":"Finds S30=1800.","marks":1},{"id":"working","rule":"Shows coherent algebra connecting the given terms to the requested values.","marks":1}],"max_marks":6}'::jsonb,'Use uₙ=a+(n−1)d twice before solving for a and d. Then choose either Sₙ=n/2[2a+(n−1)d] or n(a+uₙ)/2.','Сначала дважды используйте uₙ=a+(n−1)d, чтобы найти a и d. Затем используйте Sₙ=n/2[2a+(n−1)d] или n(a+uₙ)/2.','Avval a va d ni topish uchun uₙ=a+(n−1)d formulasini ikki marta ishlating. So‘ng Sₙ=n/2[2a+(n−1)d] yoki n(a+uₙ)/2 dan foydalaning.','draft','pending','pending','pending','pending'),
(15654,4817,'P1SER04-AW18','P1','P1-SER-04','{}','v1','A geometric progression has second term 12 and fifth term 96, with positive common ratio. (a) Find the common ratio and first term. (b) Find the eighth term. (c) Find the sum of the first eight terms. Show the powers of r used.','В геометрической прогрессии второй член равен 12, пятый — 96, а знаменатель положительный. (a) Найдите знаменатель и первый член. (b) Найдите восьмой член. (c) Найдите сумму первых восьми членов. Покажите использованные степени r.','Geometrik progressiyada ikkinchi had 12, beshinchi had 96 va umumiy maxraj musbat. (a) Umumiy maxraj va birinchi hadni toping. (b) Sakkizinchi hadni toping. (c) Dastlabki sakkiz had yig‘indisini toping. Ishlatilgan r darajalarini ko‘rsating.','{"criteria":[{"id":"ratio","rule":"Uses u5/u2=r³=8 to obtain r=2.","marks":1},{"id":"first","rule":"Finds a=6.","marks":1},{"id":"u8","rule":"Finds u8=768.","marks":1},{"id":"sum_method","rule":"Uses the finite geometric-series formula correctly.","marks":1},{"id":"sum","rule":"Finds S8=1530.","marks":1},{"id":"working","rule":"Shows the relation between term numbers and powers of r.","marks":1}],"max_marks":6}'::jsonb,'Divide two known terms so the first term cancels. Remember that uₙ=ar^(n−1), then use the finite geometric sum.','Разделите два известных члена, чтобы первый член сократился. Помните uₙ=ar^(n−1), затем используйте формулу конечной геометрической суммы.','Birinchi had qisqarishi uchun ma’lum ikki hadni bo‘ling. uₙ=ar^(n−1) ekanini eslang, so‘ng chekli geometrik yig‘indi formulasidan foydalaning.','draft','pending','pending','pending','pending'),
(15655,4817,'P1SER05-AW18','P1','P1-SER-05','{}','v1','For each series, decide whether a finite sum to infinity exists and justify the decision: (i) 12−6+3−..., (ii) 5+6+7.2+... . For the convergent series, find the sum to infinity and the sum of all terms after the first four terms.','Для каждого ряда определите, существует ли конечная сумма до бесконечности, и обоснуйте: (i) 12−6+3−..., (ii) 5+6+7,2+... . Для сходящегося ряда найдите сумму до бесконечности и сумму всех членов после первых четырёх.','Har bir qator uchun chekli cheksiz yig‘indi mavjud yoki yo‘qligini aniqlang va asoslang: (i) 12−6+3−..., (ii) 5+6+7.2+... . Yaqinlashuvchi qator uchun cheksiz yig‘indi va dastlabki to‘rtta haddan keyingi barcha hadlar yig‘indisini toping.','{"criteria":[{"id":"ratios","rule":"Identifies r=−1/2 for (i) and r=1.2 for (ii).","marks":1},{"id":"convergence","rule":"Uses |r|<1 to accept (i) and reject (ii).","marks":1},{"id":"infinite","rule":"Finds S∞ for (i) as 8.","marks":1},{"id":"four_terms","rule":"Finds the fourth term or first-four-term sum correctly.","marks":1},{"id":"tail","rule":"Finds the tail after four terms as 1/2.","marks":1},{"id":"reasoning","rule":"Explains why the second series has no finite sum to infinity.","marks":1}],"max_marks":6}'::jsonb,'Convergence depends on |r|, not on whether r is positive. For the tail, treat the fifth term as the first term of a new geometric series.','Сходимость зависит от |r|, а не от знака r. Для хвоста считайте пятый член первым членом нового геометрического ряда.','Yaqinlashish r ning ishorasiga emas, |r| ga bog‘liq. Qolgan qator uchun beshinchi hadni yangi geometrik qatorning birinchi hadi deb oling.','draft','pending','pending','pending','pending'),
(15656,4817,'P1DIF02-AW18','P1','P1-DIF-02','{}','v1','Let f(x)=4x^(3/2)−3x^(1/2)+2x^(−1). (a) Find f′(x). (b) Find f′(4). (c) State which power rule is being used for each rational or negative exponent and simplify your final numerical value.','Пусть f(x)=4x^(3/2)−3x^(1/2)+2x^(−1). (a) Найдите f′(x). (b) Найдите f′(4). (c) Укажите, как применяется правило степени к каждой рациональной или отрицательной степени, и упростите итоговое числовое значение.','f(x)=4x^(3/2)−3x^(1/2)+2x^(−1) bo‘lsin. (a) f′(x) ni toping. (b) f′(4) ni toping. (c) Har bir ratsional yoki manfiy darajaga daraja qoidasi qanday qo‘llanishini ko‘rsating va yakuniy son qiymatini soddalashtiring.','{"criteria":[{"id":"first","rule":"Differentiates 4x^(3/2) to 6x^(1/2).","marks":1},{"id":"second","rule":"Differentiates −3x^(1/2) to −(3/2)x^(−1/2).","marks":1},{"id":"third","rule":"Differentiates 2x^(−1) to −2x^(−2).","marks":1},{"id":"expression","rule":"Combines the derivative correctly.","marks":1},{"id":"evaluate","rule":"Finds f′(4)=89/8.","marks":1},{"id":"rule","rule":"States the power rule d(x^n)/dx=nx^(n−1) for rational/negative exponents in scope.","marks":1}],"max_marks":6}'::jsonb,'Apply the same power rule term by term. When evaluating, rewrite square-root powers and negative powers as simple fractions.','Применяйте одно и то же правило степени к каждому члену. При подстановке перепишите корневые и отрицательные степени как простые дроби.','Har bir hadga bir xil daraja qoidasini qo‘llang. Qiymat qo‘yishda ildizli va manfiy darajalarni oddiy kasrlarga aylantiring.','draft','pending','pending','pending','pending'),
(15657,4817,'P1DIF03-AW18','P1','P1-DIF-03','{}','v1','Differentiate (a) y=(3x−1)^5 and (b) y=(4−2x)^(−3). Then find the value of each derivative at x=1. In each part identify the outer derivative and the derivative of the inner linear expression.','Дифференцируйте (a) y=(3x−1)^5 и (b) y=(4−2x)^(−3). Затем найдите значение каждой производной при x=1. В каждой части укажите производную внешней функции и производную внутреннего линейного выражения.','(a) y=(3x−1)^5 va (b) y=(4−2x)^(−3) ni differensiallang. So‘ng har bir hosilaning x=1 dagi qiymatini toping. Har qismda tashqi funksiya hosilasi va ichki chiziqli ifoda hosilasini ko‘rsating.','{"criteria":[{"id":"a_derivative","rule":"Finds dy/dx=15(3x−1)^4 for part (a).","marks":1},{"id":"a_value","rule":"Finds derivative value 240 at x=1.","marks":1},{"id":"b_derivative","rule":"Finds dy/dx=6(4−2x)^(−4) for part (b).","marks":1},{"id":"b_value","rule":"Finds derivative value 3/8 at x=1.","marks":1},{"id":"inner","rule":"Shows inner derivatives 3 and −2.","marks":1},{"id":"method","rule":"Clearly applies outer derivative × inner derivative in both parts.","marks":1}],"max_marks":6}'::jsonb,'Treat ax+b as the inner function. Differentiate the outer power first, then multiply by the constant derivative of the inner expression.','Рассматривайте ax+b как внутреннюю функцию. Сначала найдите производную внешней степени, затем умножьте на постоянную производную внутреннего выражения.','ax+b ni ichki funksiya deb oling. Avval tashqi darajani differensiallang, keyin ichki ifodaning doimiy hosilasiga ko‘paytiring.','draft','pending','pending','pending','pending'),
(15658,4817,'P1DIF04-AW18','P1','P1-DIF-04','{}','v1','For the curve y=x³−3x+2 at x=2: (a) find the point on the curve, (b) find the gradient and equation of the tangent, (c) find the gradient and equation of the normal, and (d) verify that the tangent and normal gradients have product −1.','Для кривой y=x³−3x+2 при x=2: (a) найдите точку на кривой, (b) найдите градиент и уравнение касательной, (c) найдите градиент и уравнение нормали, (d) проверьте, что произведение градиентов касательной и нормали равно −1.','y=x³−3x+2 egri chiziq uchun x=2 da: (a) egri chiziqdagi nuqtani toping, (b) urinma gradienti va tenglamasini toping, (c) normal gradienti va tenglamasini toping, (d) urinma va normal gradientlari ko‘paytmasi −1 ekanini tekshiring.','{"criteria":[{"id":"point","rule":"Finds the point (2,4).","marks":1},{"id":"tangent_gradient","rule":"Finds dy/dx=3x²−3 and tangent gradient 9.","marks":1},{"id":"tangent","rule":"Finds tangent y−4=9(x−2), equivalent to y=9x−14.","marks":1},{"id":"normal_gradient","rule":"Finds normal gradient −1/9.","marks":1},{"id":"normal","rule":"Finds normal y−4=−(1/9)(x−2), or an equivalent equation.","marks":1},{"id":"verify","rule":"Shows 9×(−1/9)=−1.","marks":1}],"max_marks":6}'::jsonb,'Differentiate before substituting x=2. A non-horizontal tangent with gradient m has normal gradient −1/m.','Сначала найдите производную, затем подставьте x=2. Если градиент касательной m ненулевой, градиент нормали равен −1/m.','Avval differensiallang, keyin x=2 ni qo‘ying. Nol bo‘lmagan m gradientli urinmaning normal gradienti −1/m ga teng.','draft','pending','pending','pending','pending')
on conflict(id) do nothing;

with src(content_key,skill_code,meta_id,official_ref,book_ref) as (values
('P1SER03-A01','P1-SER-03',59390,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER03-A02','P1-SER-03',59391,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER03-A03','P1-SER-03',59392,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER04-A01','P1-SER-04',59393,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER04-A02','P1-SER-04',59394,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER04-A03','P1-SER-04',59395,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER05-A01','P1-SER-05',59396,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER05-A02','P1-SER-05',59397,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER05-A03','P1-SER-05',59398,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1DIF02-A01','P1-DIF-02',59399,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF02-A02','P1-DIF-02',59400,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF02-A03','P1-DIF-02',59401,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF03-A01','P1-DIF-03',59402,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF03-A02','P1-DIF-03',59403,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF03-A03','P1-DIF-03',59404,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF04-A01','P1-DIF-04',59405,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8-9 Differentiation pp.138-167 (mapping only)'),
('P1DIF04-A02','P1-DIF-04',59406,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8-9 Differentiation pp.138-167 (mapping only)'),
('P1DIF04-A03','P1-DIF-04',59407,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8-9 Differentiation pp.138-167 (mapping only)')
)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,4817,s.content_key,q.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'Supplemental AW17-20 learning draft authored from the canonical skill intent with independent values and contexts, separate from the existing teaching pack.',
 s.official_ref,s.book_ref,
 'pending','pending','pending','pending','pending','not_applicable',
 md5(concat_ws(chr(31),
   q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),
   coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
   coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),
   coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
   coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),
   coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')
 ))
from src s
join public.questions q on q.book_ref='ExamPrep:P1:p1_aw17_20_alt_learning_draft_v1:'||s.content_key
on conflict(id) do nothing;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35472,4817,'P1-SER-03-learning-alt-04','v1','P1','learning','draft','Arithmetic progression terms and sums','Члены и суммы арифметической прогрессии','Arifmetik progressiya hadlari va yig‘indilari'),
(35473,4817,'P1-SER-04-learning-alt-04','v1','P1','learning','draft','Geometric progression terms and sums','Члены и суммы геометрической прогрессии','Geometrik progressiya hadlari va yig‘indilari'),
(35474,4817,'P1-SER-05-learning-alt-04','v1','P1','learning','draft','Convergent geometric series','Сходящиеся геометрические ряды','Yaqinlashuvchi geometrik qatorlar'),
(35475,4817,'P1-DIF-02-learning-alt-04','v1','P1','learning','draft','Differentiating powers','Дифференцирование степенных функций','Darajali funksiyalarni differensiallash'),
(35476,4817,'P1-DIF-03-learning-alt-04','v1','P1','learning','draft','Chain rule','Правило цепочки','Zanjir qoidasi'),
(35477,4817,'P1-DIF-04-learning-alt-04','v1','P1','learning','draft','Tangents and normals','Касательные и нормали','Urinmalar va normallar')
on conflict(id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35472,1,'P1SER03-A01',null::bigint,'P1-SER-03'),
(35472,2,'P1SER03-A02',null::bigint,'P1-SER-03'),
(35472,3,'P1SER03-A03',null::bigint,'P1-SER-03'),
(35472,4,null,15653,'P1-SER-03'),
(35473,1,'P1SER04-A01',null::bigint,'P1-SER-04'),
(35473,2,'P1SER04-A02',null::bigint,'P1-SER-04'),
(35473,3,'P1SER04-A03',null::bigint,'P1-SER-04'),
(35473,4,null,15654,'P1-SER-04'),
(35474,1,'P1SER05-A01',null::bigint,'P1-SER-05'),
(35474,2,'P1SER05-A02',null::bigint,'P1-SER-05'),
(35474,3,'P1SER05-A03',null::bigint,'P1-SER-05'),
(35474,4,null,15655,'P1-SER-05'),
(35475,1,'P1DIF02-A01',null::bigint,'P1-DIF-02'),
(35475,2,'P1DIF02-A02',null::bigint,'P1-DIF-02'),
(35475,3,'P1DIF02-A03',null::bigint,'P1-DIF-02'),
(35475,4,null,15656,'P1-DIF-02'),
(35476,1,'P1DIF03-A01',null::bigint,'P1-DIF-03'),
(35476,2,'P1DIF03-A02',null::bigint,'P1-DIF-03'),
(35476,3,'P1DIF03-A03',null::bigint,'P1-DIF-03'),
(35476,4,null,15657,'P1-DIF-03'),
(35477,1,'P1DIF04-A01',null::bigint,'P1-DIF-04'),
(35477,2,'P1DIF04-A02',null::bigint,'P1-DIF-04'),
(35477,3,'P1DIF04-A03',null::bigint,'P1-DIF-04'),
(35477,4,null,15658,'P1-DIF-04')
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select i.assessment_id,i.item_order,q.id,i.written_id,i.skill_code,
 case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions q on i.content_key is not null
 and q.book_ref='ExamPrep:P1:p1_aw17_20_alt_learning_draft_v1:'||i.content_key
on conflict(assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4817)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4817 and lifecycle_state='draft' and reserve_role='learning')<>18
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4817 and lifecycle_state='draft')<>6
     or (select count(*) from private.exam_prep_assessments where content_version_id=4817 and status='draft' and assessment_type='learning')<>6
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4817)<>24
  then raise exception 'aw17_20_alt_p1_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4817 and (
    m.exposure_state<>'withheld' or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or q.is_active or q.quality_status<>'draft'
  );
  if v_bad<>0 then raise exception 'aw17_20_alt_p1_draft exposure/QA boundary rows=%',v_bad; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id where m.content_version_id=4817;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(3,3,3,3,6) then
    raise exception 'aw17_20_alt_p1_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4817
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4817
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw17_20_alt_p1_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4817)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4817)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4817)
  then raise exception 'aw17_20_alt_p1_draft unexpected history'; end if;
end
$postcheck$;

commit;
