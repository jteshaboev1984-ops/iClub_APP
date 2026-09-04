-- P1-02 atomic governed pack for P1-COO-04 and P1-CIR-02.
-- If any floor, QA or safety invariant fails the whole transaction rolls back.

begin;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_aw09_12_geometry_v1' and component_code='P1' and status='draft'
), src(skill,k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P1-COO-04','P1COO04-D01','diagnostic','medium',
'For the circle x² + y² − 6x + 4y − 12 = 0, state its centre and radius.',
'Для окружности x² + y² − 6x + 4y − 12 = 0 укажите центр и радиус.',
'x² + y² − 6x + 4y − 12 = 0 aylana uchun markaz va radiusni toping.',
'["centre (3, −2), radius 5","centre (−3, 2), radius 5","centre (3, −2), radius 25","centre (6, −4), radius 5"]',
'["центр (3, −2), радиус 5","центр (−3, 2), радиус 5","центр (3, −2), радиус 25","центр (6, −4), радиус 5"]',
'["markaz (3, −2), radius 5","markaz (−3, 2), radius 5","markaz (3, −2), radius 25","markaz (6, −4), radius 5"]','A',
'Complete the squares: (x−3)²−9 + (y+2)²−4 −12 = 0, so (x−3)² + (y+2)² = 25. Hence the centre is (3,−2) and the radius is 5.',
'Выделяем квадраты: (x−3)²−9 + (y+2)²−4 −12 = 0, поэтому (x−3)² + (y+2)² = 25. Центр (3,−2), радиус 5.',
'Kvadratlarni to‘ldiramiz: (x−3)²−9 + (y+2)²−4 −12 = 0, demak (x−3)² + (y+2)² = 25. Markaz (3,−2), radius 5.',80),
('P1-COO-04','P1COO04-L01','learning','easy',
'Which equation represents a circle with centre (2, −1) and radius 3?',
'Какое уравнение задаёт окружность с центром (2, −1) и радиусом 3?',
'Markazi (2, −1), radiusi 3 bo‘lgan aylana qaysi tenglama bilan beriladi?',
'["(x+2)²+(y−1)²=9","(x−2)²+(y+1)²=9","(x−2)²+(y+1)²=3","(x+2)²+(y−1)²=3"]',
'["(x+2)²+(y−1)²=9","(x−2)²+(y+1)²=9","(x−2)²+(y+1)²=3","(x+2)²+(y−1)²=3"]',
'["(x+2)²+(y−1)²=9","(x−2)²+(y+1)²=9","(x−2)²+(y+1)²=3","(x+2)²+(y−1)²=3"]','B',
'A circle with centre (a,b) and radius r has equation (x−a)²+(y−b)²=r². Substituting a=2, b=−1, r=3 gives (x−2)²+(y+1)²=9.',
'Окружность с центром (a,b) и радиусом r имеет вид (x−a)²+(y−b)²=r². При a=2, b=−1, r=3 получаем (x−2)²+(y+1)²=9.',
'Markazi (a,b), radiusi r bo‘lgan aylana (x−a)²+(y−b)²=r² ko‘rinishda. a=2, b=−1, r=3 dan (x−2)²+(y+1)²=9.',55),
('P1-COO-04','P1COO04-L02','learning','medium',
'Find the centre and radius of x² + y² + 8x − 2y − 8 = 0.',
'Найдите центр и радиус окружности x² + y² + 8x − 2y − 8 = 0.',
'x² + y² + 8x − 2y − 8 = 0 aylananing markazi va radiusini toping.',
'["centre (−4,1), radius 5","centre (4,−1), radius 5","centre (−4,1), radius 25","centre (−8,2), radius 5"]',
'["центр (−4,1), радиус 5","центр (4,−1), радиус 5","центр (−4,1), радиус 25","центр (−8,2), радиус 5"]',
'["markaz (−4,1), radius 5","markaz (4,−1), radius 5","markaz (−4,1), radius 25","markaz (−8,2), radius 5"]','A',
'(x+4)²−16 + (y−1)²−1 −8 = 0 gives (x+4)²+(y−1)²=25. Thus centre (−4,1), radius 5.',
'(x+4)²−16 + (y−1)²−1 −8 = 0, значит (x+4)²+(y−1)²=25. Центр (−4,1), радиус 5.',
'(x+4)²−16 + (y−1)²−1 −8 = 0 dan (x+4)²+(y−1)²=25. Markaz (−4,1), radius 5.',70),
('P1-COO-04','P1COO04-L03','learning','medium',
'Does the point (4,3) lie on the circle (x−1)²+(y+1)²=25?',
'Лежит ли точка (4,3) на окружности (x−1)²+(y+1)²=25?',
'(4,3) nuqta (x−1)²+(y+1)²=25 aylanada yotadimi?',
'["No, because 3+4≠25","No, because 4²+3²≠25","Yes, because 3²+4²=25","Yes, because 4+3=7"]',
'["Нет, потому что 3+4≠25","Нет, потому что 4²+3²≠25","Да, потому что 3²+4²=25","Да, потому что 4+3=7"]',
'["Yo‘q, chunki 3+4≠25","Yo‘q, chunki 4²+3²≠25","Ha, chunki 3²+4²=25","Ha, chunki 4+3=7"]','C',
'For (4,3), x−1=3 and y+1=4. Then 3²+4²=9+16=25, so the point lies on the circle.',
'Для (4,3): x−1=3, y+1=4. Тогда 3²+4²=9+16=25, следовательно точка лежит на окружности.',
'(4,3) uchun x−1=3, y+1=4. 3²+4²=9+16=25, demak nuqta aylanada yotadi.',55),
('P1-COO-04','P1COO04-R01','retest','medium',
'Find the centre and radius of x²+y²−2x−6y−6=0.',
'Найдите центр и радиус x²+y²−2x−6y−6=0.',
'x²+y²−2x−6y−6=0 aylananing markazi va radiusini toping.',
'["centre (−1,−3), radius 4","centre (1,3), radius 16","centre (2,6), radius 4","centre (1,3), radius 4"]',
'["центр (−1,−3), радиус 4","центр (1,3), радиус 16","центр (2,6), радиус 4","центр (1,3), радиус 4"]',
'["markaz (−1,−3), radius 4","markaz (1,3), radius 16","markaz (2,6), radius 4","markaz (1,3), radius 4"]','D',
'(x−1)²−1+(y−3)²−9−6=0, so (x−1)²+(y−3)²=16. Centre (1,3), radius 4.',
'(x−1)²−1+(y−3)²−9−6=0, поэтому (x−1)²+(y−3)²=16. Центр (1,3), радиус 4.',
'(x−1)²−1+(y−3)²−9−6=0, demak (x−1)²+(y−3)²=16. Markaz (1,3), radius 4.',65),
('P1-COO-04','P1COO04-R02','retest','easy',
'Write the equation of the circle with centre (−2,5) and radius 6.',
'Запишите уравнение окружности с центром (−2,5) и радиусом 6.',
'Markazi (−2,5), radiusi 6 bo‘lgan aylana tenglamasini yozing.',
'["(x+2)²+(y−5)²=36","(x−2)²+(y+5)²=36","(x+2)²+(y−5)²=6","(x−2)²+(y+5)²=6"]',
'["(x+2)²+(y−5)²=36","(x−2)²+(y+5)²=36","(x+2)²+(y−5)²=6","(x−2)²+(y+5)²=6"]',
'["(x+2)²+(y−5)²=36","(x−2)²+(y+5)²=36","(x+2)²+(y−5)²=6","(x−2)²+(y+5)²=6"]','A',
'Use (x−a)²+(y−b)²=r² with a=−2, b=5 and r=6.',
'Используйте (x−a)²+(y−b)²=r² при a=−2, b=5, r=6.',
'(x−a)²+(y−b)²=r² formulada a=−2, b=5, r=6 ni qo‘ying.',50),
('P1-COO-04','P1COO04-M01','mixed','medium',
'A circle has centre (1,−2) and passes through (4,2). Which equation is correct?',
'Окружность имеет центр (1,−2) и проходит через (4,2). Какое уравнение верно?',
'Aylananing markazi (1,−2) va u (4,2) nuqtadan o‘tadi. Qaysi tenglama to‘g‘ri?',
'["(x−1)²+(y+2)²=5","(x−1)²+(y+2)²=25","(x+1)²+(y−2)²=25","(x−4)²+(y−2)²=25"]',
'["(x−1)²+(y+2)²=5","(x−1)²+(y+2)²=25","(x+1)²+(y−2)²=25","(x−4)²+(y−2)²=25"]',
'["(x−1)²+(y+2)²=5","(x−1)²+(y+2)²=25","(x+1)²+(y−2)²=25","(x−4)²+(y−2)²=25"]','B',
'The radius is the distance from (1,−2) to (4,2): √(3²+4²)=5, so r²=25 and the equation is (x−1)²+(y+2)²=25.',
'Радиус — расстояние от (1,−2) до (4,2): √(3²+4²)=5, значит r²=25 и уравнение (x−1)²+(y+2)²=25.',
'Radius (1,−2) dan (4,2) gacha masofa: √(3²+4²)=5, demak r²=25 va tenglama (x−1)²+(y+2)²=25.',70),

('P1-CIR-02','P1CIR02-D01','diagnostic','medium',
'A circle has radius 6 cm and subtends an angle of 1.2 radians at the centre. Find the arc length.',
'Радиус окружности 6 см, центральный угол 1.2 радиана. Найдите длину дуги.',
'Aylana radiusi 6 cm, markaziy burchagi 1.2 radian. Yoy uzunligini toping.',
'["7.2 cm","5.0 cm","0.2 cm","43.2 cm"]','["7.2 см","5.0 см","0.2 см","43.2 см"]','["7.2 cm","5.0 cm","0.2 cm","43.2 cm"]','A',
'For an angle in radians, arc length s=rθ=6×1.2=7.2 cm.',
'Для угла в радианах s=rθ=6×1.2=7.2 см.',
'Radianlarda s=rθ=6×1.2=7.2 cm.',55),
('P1-CIR-02','P1CIR02-L01','learning','easy',
'Find the arc length when r=5 cm and θ=0.8 radians.',
'Найдите длину дуги при r=5 см и θ=0.8 рад.',
'r=5 cm va θ=0.8 rad bo‘lganda yoy uzunligini toping.',
'["6.25 cm","4 cm","5.8 cm","0.16 cm"]','["6.25 см","4 см","5.8 см","0.16 см"]','["6.25 cm","4 cm","5.8 cm","0.16 cm"]','B',
's=rθ=5×0.8=4 cm.','s=rθ=5×0.8=4 см.','s=rθ=5×0.8=4 cm.',45),
('P1-CIR-02','P1CIR02-L02','learning','medium',
'An arc has length 12 cm in a circle of radius 8 cm. Find θ in radians.',
'Длина дуги 12 см в окружности радиуса 8 см. Найдите θ в радианах.',
'Radiusi 8 cm bo‘lgan aylanada yoy uzunligi 12 cm. θ ni radianlarda toping.',
'["0.67","0.96","1.5","4"]','["0.67","0.96","1.5","4"]','["0.67","0.96","1.5","4"]','C',
'From s=rθ, θ=s/r=12/8=1.5 radians.',
'Из s=rθ получаем θ=s/r=12/8=1.5 рад.',
's=rθ dan θ=s/r=12/8=1.5 rad.',50),
('P1-CIR-02','P1CIR02-L03','learning','medium',
'An arc has length 9 cm and subtends 0.6 radians. Find the radius.',
'Длина дуги 9 см, угол 0.6 рад. Найдите радиус.',
'Yoy uzunligi 9 cm, burchak 0.6 rad. Radiusni toping.',
'["5.4 cm","9.6 cm","0.067 cm","15 cm"]','["5.4 см","9.6 см","0.067 см","15 см"]','["5.4 cm","9.6 cm","0.067 cm","15 cm"]','D',
'r=s/θ=9/0.6=15 cm.','r=s/θ=9/0.6=15 см.','r=s/θ=9/0.6=15 cm.',50),
('P1-CIR-02','P1CIR02-R01','retest','medium',
'Find the arc length for r=4 m and θ=2.25 radians.',
'Найдите длину дуги при r=4 м и θ=2.25 рад.',
'r=4 m va θ=2.25 rad uchun yoy uzunligini toping.',
'["6.25 m","9 m","16 m","0.5625 m"]','["6.25 м","9 м","16 м","0.5625 м"]','["6.25 m","9 m","16 m","0.5625 m"]','B',
's=rθ=4×2.25=9 m.','s=rθ=4×2.25=9 м.','s=rθ=4×2.25=9 m.',50),
('P1-CIR-02','P1CIR02-R02','retest','medium',
'An arc of length 7.5 cm lies on a circle of radius 3 cm. Find θ.',
'Дуга длиной 7.5 см лежит на окружности радиуса 3 см. Найдите θ.',
'7.5 cm yoy radiusi 3 cm bo‘lgan aylanada. θ ni toping.',
'["22.5 rad","0.4 rad","2.5 rad","4.5 rad"]','["22.5 рад","0.4 рад","2.5 рад","4.5 рад"]','["22.5 rad","0.4 rad","2.5 rad","4.5 rad"]','C',
'θ=s/r=7.5/3=2.5 radians.','θ=s/r=7.5/3=2.5 рад.','θ=s/r=7.5/3=2.5 rad.',50),
('P1-CIR-02','P1CIR02-M01','mixed','medium',
'An arc of length 8 cm belongs to a circle of radius 12 cm. What angle does it subtend at the centre?',
'Дуга длиной 8 см принадлежит окружности радиуса 12 см. Какой угол она стягивает в центре?',
'Uzunligi 8 cm bo‘lgan yoy radiusi 12 cm aylanada markazda qanday burchak hosil qiladi?',
'["2/3 rad","3/2 rad","96 rad","4 rad"]','["2/3 рад","3/2 рад","96 рад","4 рад"]','["2/3 rad","3/2 rad","96 rad","4 rad"]','A',
'θ=s/r=8/12=2/3 radians.','θ=s/r=8/12=2/3 рад.','θ=s/r=8/12=2/3 rad.',55)
)
insert into public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
select 5,case when s.skill='P1-COO-04' then 'P1 Coordinate Geometry' else 'P1 Circular Measure' end,s.skill,s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,'ExamPrep:P1:p1_aw09_12_geometry_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_aw09_12_geometry_v1:'||s.k);

with cv as (select id from private.exam_prep_content_versions where content_version='p1_aw09_12_geometry_v1' and status='draft'), keys(k,skill,role) as (values
('P1COO04-D01','P1-COO-04','diagnostic'),('P1COO04-L01','P1-COO-04','learning'),('P1COO04-L02','P1-COO-04','learning'),('P1COO04-L03','P1-COO-04','learning'),('P1COO04-R01','P1-COO-04','retest'),('P1COO04-R02','P1-COO-04','retest'),('P1COO04-M01','P1-COO-04','mixed'),
('P1CIR02-D01','P1-CIR-02','diagnostic'),('P1CIR02-L01','P1-CIR-02','learning'),('P1CIR02-L02','P1-CIR-02','learning'),('P1CIR02-L03','P1-CIR-02','learning'),('P1CIR02-R01','P1-CIR-02','retest'),('P1CIR02-R02','P1-CIR-02','retest'),('P1CIR02-M01','P1-CIR-02','mixed'))
insert into private.exam_prep_question_content_meta(content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
select cv.id,k.k,q.id,k.skill,'{}'::text[],k.role,'withheld','draft','Original iClub-authored stem, numbers, distractors, answer and explanation; no Cambridge/coursebook question, diagram or mark-scheme wording copied.','Authored for p1_aw09_12_geometry_v1 from canonical P1 geometry/circular-measure intent using independent examples.','Cambridge 9709 2026-2027 v4; P1 Coordinate Geometry / Circular Measure','Complete Pure Mathematics 1, coordinate geometry and circular measure chapters (mapping only)','pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k join public.questions q on q.book_ref='ExamPrep:P1:p1_aw09_12_geometry_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

-- Diagnostic distractor interpretations.
with rules(ckey,match,dcode,mtype,skill,fen,fru,fuz,nen,nru,nuz) as (values
('P1COO04-D01','B','circle_centre_signs','concept','P1-COO-04','In standard form (x−a)²+(y−b)²=r², the centre is (a,b). The completed squares are (x−3)² and (y+2)², so the centre is (3,−2), not (−3,2).','В форме (x−a)²+(y−b)²=r² центр равен (a,b). Здесь получаются (x−3)² и (y+2)², поэтому центр (3,−2), а не (−3,2).','(x−a)²+(y−b)²=r² da markaz (a,b). Bu yerda (x−3)² va (y+2)² hosil bo‘ladi, demak markaz (3,−2), (−3,2) emas.','Complete each square and read the centre from the signs inside the brackets.','Выделите полный квадрат по каждой переменной и считайте центр по знакам внутри скобок.','Har bir o‘zgaruvchi bo‘yicha kvadratni to‘ldiring va qavs ichidagi ishoralardan markazni o‘qing.'),
('P1COO04-D01','C','radius_squared_as_radius','method','P1-COO-04','The right side 25 is r², not r. Therefore the radius is √25=5.','Правая часть 25 равна r², а не r. Поэтому радиус √25=5.','O‘ng tomondagi 25 r² ga teng, r ga emas. Shuning uchun radius √25=5.','After reaching standard form, take the positive square root of the right-hand side to obtain the radius.','После получения стандартной формы возьмите положительный квадратный корень из правой части.','Standart ko‘rinishga kelgach, radius uchun o‘ng tomondan musbat kvadrat ildiz oling.'),
('P1COO04-D01','D','linear_coefficients_used_directly','method','P1-COO-04','The centre coordinates are not the raw linear coefficients −6 and 4. Completing the square halves those coefficients before reversing the bracket sign.','Координаты центра — не сами коэффициенты −6 и 4. При выделении квадрата линейные коэффициенты сначала делятся пополам, затем учитывается знак в скобке.','Markaz koordinatalari −6 va 4 chiziqli koeffitsiyentlarning o‘zi emas. Kvadratni to‘ldirishda ular avval ikkiga bo‘linadi, keyin qavs ichidagi ishora hisobga olinadi.','For x²+px, use (x+p/2)²−(p/2)², and similarly for y.','Для x²+px используйте (x+p/2)²−(p/2)² и аналогично для y.','x²+px uchun (x+p/2)²−(p/2)² formulasidan, y uchun ham xuddi shunday foydalaning.'),
('P1CIR02-D01','B','arc_formula_addition','concept','P1-CIR-02','Arc length in radians is a product s=rθ, not r−θ or r+θ. Adding or subtracting the two quantities is dimensionally wrong.','Длина дуги в радианах вычисляется произведением s=rθ, а не сложением или вычитанием r и θ.','Radianlarda yoy uzunligi s=rθ ko‘paytma bilan topiladi, r va θ ni qo‘shish yoki ayirish bilan emas.','Write s=rθ before substituting values and keep θ in radians.','Перед подстановкой запишите s=rθ и убедитесь, что θ задан в радианах.','Qiymatlarni qo‘yishdan oldin s=rθ ni yozing va θ radianlarda ekanini tekshiring.'),
('P1CIR02-D01','C','arc_formula_divided','method','P1-CIR-02','Dividing θ by r reverses the relationship. With s=rθ, increasing radius at the same angle increases arc length.','Деление θ на r обращает зависимость. По формуле s=rθ при том же угле больший радиус даёт большую дугу.','θ ni r ga bo‘lish bog‘lanishni teskarisiga aylantiradi. s=rθ bo‘yicha bir xil burchakda radius oshsa, yoy uzunligi ham oshadi.','Use the rearranged forms θ=s/r and r=s/θ only when θ or r is the unknown.','θ=s/r va r=s/θ ko‘rinishlarini faqat θ yoki r noma’lum bo‘lganda ishlating.','θ=s/r va r=s/θ formulalarini faqat θ yoki r noma’lum bo‘lsa ishlating.'),
('P1CIR02-D01','D','radius_squared_used','concept','P1-CIR-02','The formula for arc length is s=rθ. The factor r² belongs to sector area, not arc length.','Формула длины дуги s=rθ. Множитель r² относится к площади сектора, а не к длине дуги.','Yoy uzunligi formulasi s=rθ. r² esa sektor yuzasiga tegishli, yoy uzunligiga emas.','Separate the two circular-measure formulas: arc length s=rθ; sector area A=½r²θ.','Разделяйте формулы: длина дуги s=rθ; площадь сектора A=½r²θ.','Ikki formulani ajrating: yoy uzunligi s=rθ; sektor yuzi A=½r²θ.')
), meta as (
 select m.id,m.content_key from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id where cv.content_version='p1_aw09_12_geometry_v1' and m.reserve_role='diagnostic'
)
insert into private.exam_prep_diagnostic_rules(content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status,approved_at)
select meta.id,'drv1','mcq_option',r.match,r.dcode,r.mtype,r.skill,r.fen,r.fru,r.fuz,r.nen,r.nru,r.nuz,'approved',now() from rules r join meta on meta.content_key=r.ckey
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

-- Written evidence.
with cv as (select id from private.exam_prep_content_versions where content_version='p1_aw09_12_geometry_v1' and status='draft'), defs(task_key,skill,en,ru,uz,rubric,sen,sru,suz) as (values
('P1COO04-W01','P1-COO-04','The circle x²+y²−4x+6y−12=0 is given in expanded form. Convert it to centre-radius form, state the centre and radius, and verify whether P(5,1) lies on the circle.','Дана окружность x²+y²−4x+6y−12=0. Приведите её к форме центр-радиус, укажите центр и радиус и проверьте, лежит ли P(5,1) на окружности.','x²+y²−4x+6y−12=0 aylana kengaytirilgan ko‘rinishda berilgan. Uni markaz-radius ko‘rinishiga keltiring, markaz va radiusni yozing hamda P(5,1) nuqta aylanada yotishini tekshiring.','{"max_marks":10,"criteria":[{"id":"complete","marks":4,"rule":"Obtains (x−2)²+(y+3)²=25 by correct completing-square compensation."},{"id":"centre_radius","marks":2,"rule":"States centre (2,−3) and radius 5."},{"id":"point","marks":3,"rule":"Substitutes P(5,1): 3²+4²=25 and concludes it lies on the circle."},{"id":"notation","marks":1,"rule":"Uses centre-radius notation and radius rather than radius-squared consistently."}]}','Track every constant introduced when completing each square. After obtaining standard form, test P using its displacement from the centre, not by visual guess.','Отслеживайте все добавленные константы при выделении квадратов. После стандартной формы проверьте P по смещению от центра.','Kvadratlarni to‘ldirishda qo‘shilgan har bir doimiy hadni hisobga oling. Standart ko‘rinishdan keyin P ni markazdan siljish orqali tekshiring.'),
('P1CIR02-W01','P1-CIR-02','An arc has length 15 cm and subtends 1.25 radians. (a) Find the radius. (b) On the same circle, another arc has length 9 cm. Find its central angle in radians. Explain each rearrangement of s=rθ.','Длина дуги 15 см, центральный угол 1.25 рад. (a) Найдите радиус. (b) На той же окружности другая дуга имеет длину 9 см. Найдите её центральный угол в радианах. Объясните каждое преобразование s=rθ.','Yoy uzunligi 15 cm va markaziy burchak 1.25 rad. (a) Radiusni toping. (b) Shu aylanadagi boshqa yoy uzunligi 9 cm. Uning markaziy burchagini radianlarda toping. s=rθ formulani har safar qanday o‘zgartirganingizni tushuntiring.','{"max_marks":8,"criteria":[{"id":"radius","marks":3,"rule":"Uses r=s/θ=15/1.25=12 cm."},{"id":"angle","marks":3,"rule":"Uses θ=s/r=9/12=0.75 rad."},{"id":"reasoning","marks":2,"rule":"States correct rearrangements, units and radians consistently."}]}','Use the same radius in both parts. Check dimensions: r and s are lengths, while θ is dimensionless in radians.','Используйте один и тот же радиус в обеих частях. Проверьте размерности: r и s — длины, θ — угол в радианах.','Ikkala qismda ham bir xil radiusdan foydalaning. O‘lchovlarni tekshiring: r va s uzunlik, θ esa radian burchak.')
)
insert into private.exam_prep_written_tasks(content_version_id,task_key,component_code,primary_skill_code,task_version,prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at)
select cv.id,d.task_key,'P1',d.skill,'wtv1',d.en,d.ru,d.uz,d.rubric::jsonb,d.sen,d.sru,d.suz,'approved','pass','pass','pass','pass',now() from defs d cross join cv
on conflict(content_version_id,task_key,task_version) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p1_aw09_12_geometry_v1' and status='draft'), defs(k,t,en,ru,uz) as (values
('p1_aw09_12_geometry_diagnostic','diagnostic','P1 AW9-12 geometry/measure diagnostic','Диагностика геометрии/мер P1 AW9-12','P1 AW9-12 geometriya/o‘lchov diagnostikasi'),
('p1_coo04_learning','learning','Circle equations learning','Уравнение окружности: обучение','Aylana tenglamasi: o‘rganish'),
('p1_cir02_learning','learning','Arc length learning','Длина дуги: обучение','Yoy uzunligi: o‘rganish'),
('p1_coo04_retest','retest','Circle equations delayed retest','Отложенный ретест: окружность','Kechiktirilgan qayta test: aylana'),
('p1_cir02_retest','retest','Arc length delayed retest','Отложенный ретест: длина дуги','Kechiktirilgan qayta test: yoy uzunligi'),
('p1_aw09_12_geometry_mixed','mixed','P1 AW9-12 geometry/measure mixed transfer','Смешанный перенос геометрии P1 AW9-12','P1 AW9-12 geometriya aralash transferi'))
insert into private.exam_prep_assessments(content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz)
select cv.id,d.k,'av1','P1',d.t,'approved',d.en,d.ru,d.uz from defs d cross join cv on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (select id from private.exam_prep_content_versions where content_version='p1_aw09_12_geometry_v1'), a as (select x.id,x.assessment_key from private.exam_prep_assessments x join cv on cv.id=x.content_version_id), m as (select x.content_key,x.question_id from private.exam_prep_question_content_meta x join cv on cv.id=x.content_version_id), w as (select x.id,x.task_key from private.exam_prep_written_tasks x join cv on cv.id=x.content_version_id), items(akey,ord,ckey,wkey,skill,role,holdout) as (values
('p1_aw09_12_geometry_diagnostic',1,'P1COO04-D01',null,'P1-COO-04','diagnostic',true),('p1_aw09_12_geometry_diagnostic',2,'P1CIR02-D01',null,'P1-CIR-02','diagnostic',true),
('p1_coo04_learning',1,'P1COO04-L01',null,'P1-COO-04','learning',false),('p1_coo04_learning',2,'P1COO04-L02',null,'P1-COO-04','learning',false),('p1_coo04_learning',3,'P1COO04-L03',null,'P1-COO-04','learning',false),('p1_coo04_learning',4,null,'P1COO04-W01','P1-COO-04','written',false),
('p1_cir02_learning',1,'P1CIR02-L01',null,'P1-CIR-02','learning',false),('p1_cir02_learning',2,'P1CIR02-L02',null,'P1-CIR-02','learning',false),('p1_cir02_learning',3,'P1CIR02-L03',null,'P1-CIR-02','learning',false),('p1_cir02_learning',4,null,'P1CIR02-W01','P1-CIR-02','written',false),
('p1_coo04_retest',1,'P1COO04-R01',null,'P1-COO-04','retest',true),('p1_cir02_retest',1,'P1CIR02-R01',null,'P1-CIR-02','retest',true),
('p1_aw09_12_geometry_mixed',1,'P1COO04-M01',null,'P1-COO-04','mixed',true),('p1_aw09_12_geometry_mixed',2,'P1CIR02-M01',null,'P1-CIR-02','mixed',true))
insert into private.exam_prep_assessment_items(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout)
select a.id,i.ord,m.question_id,w.id,i.skill,i.role,i.holdout from items i join a on a.assessment_key=i.akey left join m on m.content_key=i.ckey left join w on w.task_key=i.wkey
on conflict(assessment_id,item_order) do nothing;

-- Pre-publication QA.
do $$ declare v_id bigint; v_skill text; v_bad int; begin
 select id into v_id from private.exam_prep_content_versions where content_version='p1_aw09_12_geometry_v1' and status='draft';
 if v_id is null then raise exception 'P1-02 P1 geometry pack draft version missing'; end if;
 if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id)<>14 then raise exception 'P1-02 P1 geometry pack expected 14 questions'; end if;
 foreach v_skill in array array['P1-COO-04','P1-CIR-02'] loop
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='diagnostic')<>1 then raise exception '% diagnostic floor',v_skill; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='learning')<>3 then raise exception '% learning floor',v_skill; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='retest')<>2 then raise exception '% retest floor',v_skill; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='mixed')<>1 then raise exception '% mixed floor',v_skill; end if;
  if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_id and primary_skill_code=v_skill and lifecycle_state='approved')<>1 then raise exception '% written floor',v_skill; end if;
 end loop;
 select count(*) into v_bad from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id where m.content_version_id=v_id and (q.is_active or q.quality_status is distinct from 'draft' or nullif(trim(q.question_text_en),'') is null or nullif(trim(q.question_text_ru),'') is null or nullif(trim(q.question_text_uz),'') is null or jsonb_array_length(q.options_text_en::jsonb)<>4 or jsonb_array_length(q.options_text_ru::jsonb)<>4 or jsonb_array_length(q.options_text_uz::jsonb)<>4 or md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5);
 if v_bad<>0 then raise exception 'P1-02 P1 geometry QA payload failures=%',v_bad; end if;
 select count(*) into v_bad from (select m.id from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id left join private.exam_prep_diagnostic_rules r on r.content_meta_id=m.id and r.status='approved' and r.answer_kind='mcq_option' where m.content_version_id=v_id and m.reserve_role='diagnostic' group by m.id,q.correct_answer having count(r.id)<>3 or count(r.id) filter(where r.answer_match=q.correct_answer)<>0) x;
 if v_bad<>0 then raise exception 'P1-02 P1 geometry diagnostic rule failures=%',v_bad; end if;
 if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_id)<>2 then raise exception 'P1-02 P1 geometry expected 2 written tasks'; end if;
 if (select count(*) from private.exam_prep_assessments where content_version_id=v_id)<>6 then raise exception 'P1-02 P1 geometry expected 6 assessments'; end if;
 if (select count(*) from private.exam_prep_question_content_meta m where m.content_version_id=v_id and m.reserve_role='retest' and not exists(select 1 from private.exam_prep_assessment_items i where i.question_id=m.question_id))<>2 then raise exception 'P1-02 P1 geometry expected 2 isolated R02 holdouts'; end if;
end $$;

update private.exam_prep_question_content_meta m set copyright_status='pass',qa_scope_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',diagnostic_rule_status=case when reserve_role='diagnostic' then 'approved' else 'not_applicable' end,lifecycle_state='approved',approved_at=now(),updated_at=now() from private.exam_prep_content_versions cv where cv.id=m.content_version_id and cv.content_version='p1_aw09_12_geometry_v1' and cv.status='draft';
update private.exam_prep_content_versions set status='approved',approved_at=now() where content_version='p1_aw09_12_geometry_v1' and status='draft';
update private.exam_prep_question_content_meta m set lifecycle_state=case when reserve_role='learning' then 'published' else 'reserve' end,exposure_state=case when reserve_role='learning' then 'released' else 'withheld' end,published_at=case when reserve_role='learning' then now() else null end,updated_at=now() from private.exam_prep_content_versions cv where cv.id=m.content_version_id and cv.content_version='p1_aw09_12_geometry_v1' and cv.status='approved';
update private.exam_prep_written_tasks w set lifecycle_state='published' from private.exam_prep_content_versions cv where cv.id=w.content_version_id and cv.content_version='p1_aw09_12_geometry_v1' and cv.status='approved';
update private.exam_prep_assessments a set status='published',approved_at=coalesce(a.approved_at,now()) from private.exam_prep_content_versions cv where cv.id=a.content_version_id and cv.content_version='p1_aw09_12_geometry_v1' and cv.status='approved';
update private.exam_prep_content_versions set status='published',published_at=now() where content_version='p1_aw09_12_geometry_v1' and status='approved';

do $$ declare v_program bigint; v_p1_ready int; v_p5_ready int; v_r9 jsonb; v_cfg private.exam_prep_feature_config%rowtype; begin
 select id into v_program from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';
 if not private.exam_prep_skill_content_ready_v1(v_program,'P1','P1-COO-04') or not private.exam_prep_skill_content_ready_v1(v_program,'P1','P1-CIR-02') then raise exception 'P1-02 P1 geometry final skill readiness failed'; end if;
 select count(*) into v_p1_ready from private.exam_prep_content_runway_release_skills rs join private.exam_prep_content_runway_releases r on r.id=rs.release_id where r.release_key='aw09_12_core_coverage_ii' and r.component_code='P1' and rs.required_for_release and private.exam_prep_skill_content_ready_v1(v_program,'P1',rs.skill_code);
 select count(*) into v_p5_ready from private.exam_prep_content_runway_release_skills rs join private.exam_prep_content_runway_releases r on r.id=rs.release_id where r.release_key='aw09_12_core_coverage_ii' and r.component_code='P5' and rs.required_for_release and private.exam_prep_skill_content_ready_v1(v_program,'P5',rs.skill_code);
 if v_p1_ready<>8 or v_p5_ready<>0 then raise exception 'P1-02 P1 geometry final expected AW9 readiness P1=8 P5=0, got P1=% P5=%',v_p1_ready,v_p5_ready; end if;
 v_r9:=public.get_exam_prep_content_runway_v1(9::smallint); if (v_r9#>>'{components,P1,ready_through_aw}')::int<>12 or (v_r9#>>'{components,P5,ready_through_aw}')::int<>8 then raise exception 'P1-02 P1 geometry final runway mismatch %',v_r9::text; end if;
 select * into v_cfg from private.exam_prep_feature_config where id=1; if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then raise exception 'P1-02 P1 geometry final escaped fail-closed'; end if;
end $$;
commit;