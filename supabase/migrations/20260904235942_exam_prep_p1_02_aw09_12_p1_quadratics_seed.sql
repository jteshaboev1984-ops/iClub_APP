-- P1-02 original iClub AW9-12 content: P1-QUA-04/05/06.
-- Per skill: 1 diagnostic + 3 learning + 2 delayed-retest + 1 mixed.
-- All public.questions rows remain DRAFT + INACTIVE; governed exposure is Exam Prep-only.

begin;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_aw09_12_quadratics_v1' and component_code='P1' and status='draft'
), src(skill,k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
-- P1-QUA-04: quadratic inequalities
('P1-QUA-04','P1QUA04-D01','diagnostic','medium',
'Solve x² − 5x + 6 > 0.',
'Решите неравенство x² − 5x + 6 > 0.',
'x² − 5x + 6 > 0 tengsizlikni yeching.',
'["x < 2 or x > 3","2 < x < 3","x ≤ 2 or x ≥ 3","x < 2 and x > 3"]',
'["x < 2 или x > 3","2 < x < 3","x ≤ 2 или x ≥ 3","x < 2 и x > 3"]',
'["x < 2 yoki x > 3","2 < x < 3","x ≤ 2 yoki x ≥ 3","x < 2 va x > 3"]','A',
'x² − 5x + 6 = (x − 2)(x − 3). The upward-opening quadratic is positive outside its roots, and the strict inequality excludes x = 2 and x = 3.',
'x² − 5x + 6 = (x − 2)(x − 3). Парабола направлена вверх, поэтому выражение положительно вне корней; строгое неравенство исключает x = 2 и x = 3.',
'x² − 5x + 6 = (x − 2)(x − 3). Parabola yuqoriga ochiladi, shuning uchun ifoda ildizlardan tashqarida musbat; qat’iy tengsizlik x = 2 va x = 3 ni kiritmaydi.',80),
('P1-QUA-04','P1QUA04-L01','learning','easy',
'Solve x² − 9 ≤ 0.','Решите x² − 9 ≤ 0.','x² − 9 ≤ 0 tengsizlikni yeching.',
'["−3 ≤ x ≤ 3","x ≤ −3 or x ≥ 3","−3 < x < 3","x ≥ −3"]',
'["−3 ≤ x ≤ 3","x ≤ −3 или x ≥ 3","−3 < x < 3","x ≥ −3"]',
'["−3 ≤ x ≤ 3","x ≤ −3 yoki x ≥ 3","−3 < x < 3","x ≥ −3"]','A',
'(x − 3)(x + 3) ≤ 0 between the roots. Equality is allowed, so both endpoints are included.',
'(x − 3)(x + 3) ≤ 0 между корнями. Равенство разрешено, поэтому обе границы включаются.',
'(x − 3)(x + 3) ≤ 0 ildizlar orasida bajariladi. Tenglik mumkin, shuning uchun ikkala chegara ham kiradi.',55),
('P1-QUA-04','P1QUA04-L02','learning','easy',
'Solve (x − 1)(x + 4) < 0.','Решите (x − 1)(x + 4) < 0.','(x − 1)(x + 4) < 0 tengsizlikni yeching.',
'["−4 < x < 1","x < −4 or x > 1","−4 ≤ x ≤ 1","x > −4"]',
'["−4 < x < 1","x < −4 или x > 1","−4 ≤ x ≤ 1","x > −4"]',
'["−4 < x < 1","x < −4 yoki x > 1","−4 ≤ x ≤ 1","x > −4"]','A',
'The factors have opposite signs only between the roots −4 and 1. The strict inequality excludes both roots.',
'Множители имеют разные знаки только между корнями −4 и 1. Строгое неравенство исключает оба корня.',
'Ko‘paytuvchilar faqat −4 va 1 ildizlari orasida qarama-qarshi ishorali bo‘ladi. Qat’iy tengsizlik ikkala ildizni ham kiritmaydi.',55),
('P1-QUA-04','P1QUA04-L03','learning','medium',
'Solve x² + 2x − 8 ≥ 0.','Решите x² + 2x − 8 ≥ 0.','x² + 2x − 8 ≥ 0 tengsizlikni yeching.',
'["x ≤ −4 or x ≥ 2","−4 ≤ x ≤ 2","x < −4 or x > 2","x ≥ −4"]',
'["x ≤ −4 или x ≥ 2","−4 ≤ x ≤ 2","x < −4 или x > 2","x ≥ −4"]',
'["x ≤ −4 yoki x ≥ 2","−4 ≤ x ≤ 2","x < −4 yoki x > 2","x ≥ −4"]','A',
'x² + 2x − 8 = (x + 4)(x − 2). It is non-negative outside the roots, including both roots because ≥ includes equality.',
'x² + 2x − 8 = (x + 4)(x − 2). Выражение неотрицательно вне корней; оба корня включаются, так как ≥ допускает равенство.',
'x² + 2x − 8 = (x + 4)(x − 2). Ifoda ildizlardan tashqarida manfiy emas; ≥ tenglikni ham qamrab olgani uchun ikkala ildiz kiradi.',65),
('P1-QUA-04','P1QUA04-R01','retest','medium',
'Solve x² − 7x + 10 < 0.','Решите x² − 7x + 10 < 0.','x² − 7x + 10 < 0 tengsizlikni yeching.',
'["2 < x < 5","x < 2 or x > 5","2 ≤ x ≤ 5","x ≤ 2 or x ≥ 5"]',
'["2 < x < 5","x < 2 или x > 5","2 ≤ x ≤ 5","x ≤ 2 или x ≥ 5"]',
'["2 < x < 5","x < 2 yoki x > 5","2 ≤ x ≤ 5","x ≤ 2 yoki x ≥ 5"]','A',
'(x − 2)(x − 5) is negative between the two distinct roots, with endpoints excluded.',
'(x − 2)(x − 5) отрицательно между двумя различными корнями; границы не включаются.',
'(x − 2)(x − 5) ikki turli ildiz orasida manfiy; chegaralar kiritilmaydi.',60),
('P1-QUA-04','P1QUA04-R02','retest','medium',
'Solve 2x² + x − 3 ≤ 0.','Решите 2x² + x − 3 ≤ 0.','2x² + x − 3 ≤ 0 tengsizlikni yeching.',
'["−3/2 ≤ x ≤ 1","x ≤ −3/2 or x ≥ 1","−3/2 < x < 1","−1 ≤ x ≤ 3/2"]',
'["−3/2 ≤ x ≤ 1","x ≤ −3/2 или x ≥ 1","−3/2 < x < 1","−1 ≤ x ≤ 3/2"]',
'["−3/2 ≤ x ≤ 1","x ≤ −3/2 yoki x ≥ 1","−3/2 < x < 1","−1 ≤ x ≤ 3/2"]','A',
'2x² + x − 3 = (2x + 3)(x − 1). The upward-opening quadratic is ≤ 0 between −3/2 and 1, including the roots.',
'2x² + x − 3 = (2x + 3)(x − 1). Парабола направлена вверх, поэтому ≤ 0 на отрезке от −3/2 до 1, включая корни.',
'2x² + x − 3 = (2x + 3)(x − 1). Parabola yuqoriga ochiladi, shuning uchun ≤ 0 −3/2 dan 1 gacha, ildizlar bilan birga.',70),
('P1-QUA-04','P1QUA04-M01','mixed','medium',
'Solve (x − 2)² ≥ 9.','Решите (x − 2)² ≥ 9.','(x − 2)² ≥ 9 tengsizlikni yeching.',
'["x ≤ −1 or x ≥ 5","−1 ≤ x ≤ 5","x < −1 or x > 5","x ≤ 1 or x ≥ 3"]',
'["x ≤ −1 или x ≥ 5","−1 ≤ x ≤ 5","x < −1 или x > 5","x ≤ 1 или x ≥ 3"]',
'["x ≤ −1 yoki x ≥ 5","−1 ≤ x ≤ 5","x < −1 yoki x > 5","x ≤ 1 yoki x ≥ 3"]','A',
'|x − 2| ≥ 3, so x − 2 ≤ −3 or x − 2 ≥ 3. Hence x ≤ −1 or x ≥ 5.',
'|x − 2| ≥ 3, поэтому x − 2 ≤ −3 или x − 2 ≥ 3. Отсюда x ≤ −1 или x ≥ 5.',
'|x − 2| ≥ 3, demak x − 2 ≤ −3 yoki x − 2 ≥ 3. Shundan x ≤ −1 yoki x ≥ 5.',70),

-- P1-QUA-05: simultaneous linear/quadratic systems
('P1-QUA-05','P1QUA05-D01','diagnostic','medium',
'The line y = x + 1 intersects the curve y = x² − 3x + 3. What are the x-coordinates of the intersection points?',
'Прямая y = x + 1 пересекает кривую y = x² − 3x + 3. Каковы x-координаты точек пересечения?',
'y = x + 1 to‘g‘ri chiziq y = x² − 3x + 3 egri chiziqni kesadi. Kesishish nuqtalarining x-koordinatalari qanday?',
'["2 − √2 and 2 + √2","2 − √6 and 2 + √6","−2 − √2 and −2 + √2","1 and 3"]',
'["2 − √2 и 2 + √2","2 − √6 и 2 + √6","−2 − √2 и −2 + √2","1 и 3"]',
'["2 − √2 va 2 + √2","2 − √6 va 2 + √6","−2 − √2 va −2 + √2","1 va 3"]','A',
'At an intersection the y-values are equal: x + 1 = x² − 3x + 3, giving x² − 4x + 2 = 0. The quadratic formula gives x = 2 ± √2.',
'В точке пересечения значения y равны: x + 1 = x² − 3x + 3, откуда x² − 4x + 2 = 0. По формуле корней x = 2 ± √2.',
'Kesishishda y qiymatlari teng: x + 1 = x² − 3x + 3, bundan x² − 4x + 2 = 0. Kvadrat tenglama formulasi x = 2 ± √2 ni beradi.',85),
('P1-QUA-05','P1QUA05-L01','learning','easy',
'Find the x-values where y = 2x + 3 and y = x² + 3 intersect.',
'Найдите значения x, при которых y = 2x + 3 и y = x² + 3 пересекаются.',
'y = 2x + 3 va y = x² + 3 kesishadigan x qiymatlarini toping.',
'["0 and 2","−2 and 0","1 and 2","0 and 3"]',
'["0 и 2","−2 и 0","1 и 2","0 и 3"]',
'["0 va 2","−2 va 0","1 va 2","0 va 3"]','A',
'Equating the two expressions gives x² + 3 = 2x + 3, so x² − 2x = x(x − 2) = 0.',
'Приравнивая выражения, получаем x² + 3 = 2x + 3, то есть x² − 2x = x(x − 2) = 0.',
'Ikki ifodani tenglashtirsak x² + 3 = 2x + 3, ya’ni x² − 2x = x(x − 2) = 0.',55),
('P1-QUA-05','P1QUA05-L02','learning','medium',
'Find the x-values where y = 5 − x and y = x² − 1 intersect.',
'Найдите значения x для пересечения y = 5 − x и y = x² − 1.',
'y = 5 − x va y = x² − 1 kesishadigan x qiymatlarini toping.',
'["−3 and 2","−2 and 3","−3 and −2","2 and 3"]',
'["−3 и 2","−2 и 3","−3 и −2","2 и 3"]',
'["−3 va 2","−2 va 3","−3 va −2","2 va 3"]','A',
'x² − 1 = 5 − x gives x² + x − 6 = (x + 3)(x − 2) = 0.',
'x² − 1 = 5 − x даёт x² + x − 6 = (x + 3)(x − 2) = 0.',
'x² − 1 = 5 − x dan x² + x − 6 = (x + 3)(x − 2) = 0 kelib chiqadi.',60),
('P1-QUA-05','P1QUA05-L03','learning','medium',
'Find the x-values where y = x² and y = 4x − 3 intersect.',
'Найдите значения x для пересечения y = x² и y = 4x − 3.',
'y = x² va y = 4x − 3 kesishadigan x qiymatlarini toping.',
'["1 and 3","−1 and −3","1 and 4","0 and 3"]',
'["1 и 3","−1 и −3","1 и 4","0 и 3"]',
'["1 va 3","−1 va −3","1 va 4","0 va 3"]','A',
'x² = 4x − 3 gives x² − 4x + 3 = (x − 1)(x − 3) = 0.',
'x² = 4x − 3 даёт x² − 4x + 3 = (x − 1)(x − 3) = 0.',
'x² = 4x − 3 dan x² − 4x + 3 = (x − 1)(x − 3) = 0 hosil bo‘ladi.',60),
('P1-QUA-05','P1QUA05-R01','retest','medium',
'Find the x-values where y = 3x − 2 and y = x² intersect.',
'Найдите значения x для пересечения y = 3x − 2 и y = x².',
'y = 3x − 2 va y = x² kesishadigan x qiymatlarini toping.',
'["1 and 2","−1 and −2","0 and 3","1 and 3"]',
'["1 и 2","−1 и −2","0 и 3","1 и 3"]',
'["1 va 2","−1 va −2","0 va 3","1 va 3"]','A',
'x² = 3x − 2 gives x² − 3x + 2 = (x − 1)(x − 2) = 0.',
'x² = 3x − 2 даёт x² − 3x + 2 = (x − 1)(x − 2) = 0.',
'x² = 3x − 2 dan x² − 3x + 2 = (x − 1)(x − 2) = 0.',60),
('P1-QUA-05','P1QUA05-R02','retest','medium',
'Find the x-values where y = 2x + 1 and y = x² + 1 intersect.',
'Найдите значения x для пересечения y = 2x + 1 и y = x² + 1.',
'y = 2x + 1 va y = x² + 1 kesishadigan x qiymatlarini toping.',
'["0 and 2","−2 and 0","1 and 2","0 and 1"]',
'["0 и 2","−2 и 0","1 и 2","0 и 1"]',
'["0 va 2","−2 va 0","1 va 2","0 va 1"]','A',
'x² + 1 = 2x + 1 gives x² − 2x = x(x − 2) = 0.',
'x² + 1 = 2x + 1 даёт x² − 2x = x(x − 2) = 0.',
'x² + 1 = 2x + 1 dan x² − 2x = x(x − 2) = 0.',55),
('P1-QUA-05','P1QUA05-M01','mixed','hard',
'The line y = x + k and the parabola y = x² have two distinct real intersection points. Which condition on k is required?',
'Прямая y = x + k и парабола y = x² имеют две различные действительные точки пересечения. Какое условие на k необходимо?',
'y = x + k to‘g‘ri chiziq va y = x² parabola ikkita turli haqiqiy kesishish nuqtasiga ega. k uchun qanday shart kerak?',
'["k > −1/4","k ≥ −1/4","k < −1/4","k > 1/4"]',
'["k > −1/4","k ≥ −1/4","k < −1/4","k > 1/4"]',
'["k > −1/4","k ≥ −1/4","k < −1/4","k > 1/4"]','A',
'Intersections satisfy x² − x − k = 0. Two distinct real roots require discriminant 1 + 4k > 0, hence k > −1/4.',
'Точки пересечения удовлетворяют x² − x − k = 0. Для двух различных действительных корней нужен дискриминант 1 + 4k > 0, поэтому k > −1/4.',
'Kesishishlar x² − x − k = 0 ni qanoatlantiradi. Ikkita turli haqiqiy ildiz uchun diskriminant 1 + 4k > 0 bo‘lishi kerak, demak k > −1/4.',85),

-- P1-QUA-06: equations quadratic in a transformed expression
('P1-QUA-06','P1QUA06-D01','diagnostic','medium',
'Solve x⁴ − 5x² + 4 = 0 over the real numbers.',
'Решите x⁴ − 5x² + 4 = 0 в действительных числах.',
'x⁴ − 5x² + 4 = 0 tenglamani haqiqiy sonlarda yeching.',
'["x = −2, −1, 1, 2","x = −4, −1, 1, 4","x = 1, 4","x = −2, 2"]',
'["x = −2, −1, 1, 2","x = −4, −1, 1, 4","x = 1, 4","x = −2, 2"]',
'["x = −2, −1, 1, 2","x = −4, −1, 1, 4","x = 1, 4","x = −2, 2"]','A',
'Let u = x². Then u² − 5u + 4 = (u − 1)(u − 4) = 0, so x² = 1 or 4. Taking both square roots gives x = ±1, ±2.',
'Положим u = x². Тогда u² − 5u + 4 = (u − 1)(u − 4) = 0, значит x² = 1 или 4. Учитывая оба квадратных корня, получаем x = ±1, ±2.',
'u = x² deb olamiz. U holda u² − 5u + 4 = (u − 1)(u − 4) = 0, demak x² = 1 yoki 4. Ikkala kvadrat ildizni olib x = ±1, ±2.',80),
('P1-QUA-06','P1QUA06-L01','learning','medium',
'Solve (x² + 1)² − 5(x² + 1) + 4 = 0 over the real numbers.',
'Решите (x² + 1)² − 5(x² + 1) + 4 = 0 в действительных числах.',
'(x² + 1)² − 5(x² + 1) + 4 = 0 tenglamani haqiqiy sonlarda yeching.',
'["x = 0, ±√3","x = ±1, ±2","x = ±√3 only","x = 0, ±2"]',
'["x = 0, ±√3","x = ±1, ±2","только x = ±√3","x = 0, ±2"]',
'["x = 0, ±√3","x = ±1, ±2","faqat x = ±√3","x = 0, ±2"]','A',
'Let u = x² + 1. Then (u − 1)(u − 4) = 0. From u = 1, x = 0; from u = 4, x² = 3, giving x = ±√3.',
'Положим u = x² + 1. Тогда (u − 1)(u − 4) = 0. При u = 1 получаем x = 0; при u = 4 имеем x² = 3, то есть x = ±√3.',
'u = x² + 1 deb olamiz. (u − 1)(u − 4) = 0. u = 1 dan x = 0; u = 4 dan x² = 3, ya’ni x = ±√3.',75),
('P1-QUA-06','P1QUA06-L02','learning','medium',
'Solve x⁶ − 5x³ + 4 = 0 over the real numbers.',
'Решите x⁶ − 5x³ + 4 = 0 в действительных числах.',
'x⁶ − 5x³ + 4 = 0 tenglamani haqiqiy sonlarda yeching.',
'["x = 1 or x = ∛4","x = ±1 or x = ±2","x = 1 or x = 4","x = −1 or x = −∛4"]',
'["x = 1 или x = ∛4","x = ±1 или x = ±2","x = 1 или x = 4","x = −1 или x = −∛4"]',
'["x = 1 yoki x = ∛4","x = ±1 yoki x = ±2","x = 1 yoki x = 4","x = −1 yoki x = −∛4"]','A',
'Let u = x³. Then u² − 5u + 4 = 0, so u = 1 or 4. A real cube has one real cube root for each value: x = 1 or ∛4.',
'Положим u = x³. Тогда u² − 5u + 4 = 0, поэтому u = 1 или 4. Для каждого значения существует один действительный кубический корень: x = 1 или ∛4.',
'u = x³ deb olamiz. U holda u² − 5u + 4 = 0, shuning uchun u = 1 yoki 4. Har bir qiymat uchun bitta haqiqiy kub ildiz bor: x = 1 yoki ∛4.',75),
('P1-QUA-06','P1QUA06-L03','learning','hard',
'Solve (x − 2)⁴ − 10(x − 2)² + 9 = 0 over the real numbers.',
'Решите (x − 2)⁴ − 10(x − 2)² + 9 = 0 в действительных числах.',
'(x − 2)⁴ − 10(x − 2)² + 9 = 0 tenglamani haqiqiy sonlarda yeching.',
'["x = −1, 1, 3, 5","x = −3, −1, 1, 3","x = 1, 3 only","x = −1, 5 only"]',
'["x = −1, 1, 3, 5","x = −3, −1, 1, 3","только x = 1, 3","только x = −1, 5"]',
'["x = −1, 1, 3, 5","x = −3, −1, 1, 3","faqat x = 1, 3","faqat x = −1, 5"]','A',
'Let u = (x − 2)². Then u² − 10u + 9 = (u − 1)(u − 9) = 0. Thus x − 2 = ±1 or ±3, giving x = 1, 3, −1, 5.',
'Положим u = (x − 2)². Тогда u² − 10u + 9 = (u − 1)(u − 9) = 0. Поэтому x − 2 = ±1 или ±3, то есть x = 1, 3, −1, 5.',
'u = (x − 2)² deb olamiz. U holda u² − 10u + 9 = (u − 1)(u − 9) = 0. Demak x − 2 = ±1 yoki ±3, bundan x = 1, 3, −1, 5.',85),
('P1-QUA-06','P1QUA06-R01','retest','medium',
'Solve x⁴ − 13x² + 36 = 0 over the real numbers.',
'Решите x⁴ − 13x² + 36 = 0 в действительных числах.',
'x⁴ − 13x² + 36 = 0 tenglamani haqiqiy sonlarda yeching.',
'["x = −3, −2, 2, 3","x = −6, −4, 4, 6","x = 2, 3","x = −3, 3"]',
'["x = −3, −2, 2, 3","x = −6, −4, 4, 6","x = 2, 3","x = −3, 3"]',
'["x = −3, −2, 2, 3","x = −6, −4, 4, 6","x = 2, 3","x = −3, 3"]','A',
'With u = x², u² − 13u + 36 = (u − 4)(u − 9) = 0. Hence x² = 4 or 9, giving x = ±2, ±3.',
'При u = x² получаем u² − 13u + 36 = (u − 4)(u − 9) = 0. Значит x² = 4 или 9, откуда x = ±2, ±3.',
'u = x² bo‘lsa, u² − 13u + 36 = (u − 4)(u − 9) = 0. Demak x² = 4 yoki 9, bundan x = ±2, ±3.',70),
('P1-QUA-06','P1QUA06-R02','retest','hard',
'Solve (2x − 1)⁴ − 10(2x − 1)² + 9 = 0 over the real numbers.',
'Решите (2x − 1)⁴ − 10(2x − 1)² + 9 = 0 в действительных числах.',
'(2x − 1)⁴ − 10(2x − 1)² + 9 = 0 tenglamani haqiqiy sonlarda yeching.',
'["x = −1, 0, 1, 2","x = −2, −1, 1, 2","x = 0, 1 only","x = −1, 2 only"]',
'["x = −1, 0, 1, 2","x = −2, −1, 1, 2","только x = 0, 1","только x = −1, 2"]',
'["x = −1, 0, 1, 2","x = −2, −1, 1, 2","faqat x = 0, 1","faqat x = −1, 2"]','A',
'Let u = (2x − 1)². Then u = 1 or 9, so 2x − 1 = ±1 or ±3. These give x = 0, 1, −1, 2.',
'Положим u = (2x − 1)². Тогда u = 1 или 9, поэтому 2x − 1 = ±1 или ±3. Получаем x = 0, 1, −1, 2.',
'u = (2x − 1)² deb olamiz. U holda u = 1 yoki 9, demak 2x − 1 = ±1 yoki ±3. Bundan x = 0, 1, −1, 2.',80),
('P1-QUA-06','P1QUA06-M01','mixed','hard',
'Solve x⁸ − 7x⁴ + 12 = 0 over the real numbers.',
'Решите x⁸ − 7x⁴ + 12 = 0 в действительных числах.',
'x⁸ − 7x⁴ + 12 = 0 tenglamani haqiqiy sonlarda yeching.',
'["x = ±⁴√3, ±√2","x = 3 or 4","x = ±√3, ±2","x = ⁴√3 or √2 only"]',
'["x = ±⁴√3, ±√2","x = 3 или 4","x = ±√3, ±2","только x = ⁴√3 или √2"]',
'["x = ±⁴√3, ±√2","x = 3 yoki 4","x = ±√3, ±2","faqat x = ⁴√3 yoki √2"]','A',
'Let u = x⁴. Then u² − 7u + 12 = (u − 3)(u − 4) = 0. Thus x⁴ = 3 or 4, giving the four real roots ±⁴√3 and ±√2.',
'Положим u = x⁴. Тогда u² − 7u + 12 = (u − 3)(u − 4) = 0. Значит x⁴ = 3 или 4, что даёт четыре действительных корня ±⁴√3 и ±√2.',
'u = x⁴ deb olamiz. U holda u² − 7u + 12 = (u − 3)(u − 4) = 0. Demak x⁴ = 3 yoki 4, bundan to‘rtta haqiqiy ildiz ±⁴√3 va ±√2.',90)
)
insert into public.questions(
  subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
  question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
  explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,'P1 Quadratics',s.skill,s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,
       s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,
       'ExamPrep:P1:p1_aw09_12_quadratics_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s
where not exists(
  select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_aw09_12_quadratics_v1:'||s.k
);

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p1_aw09_12_quadratics_v1' and component_code='P1' and status='draft'
), keys(k,skill,role) as (values
('P1QUA04-D01','P1-QUA-04','diagnostic'),('P1QUA04-L01','P1-QUA-04','learning'),('P1QUA04-L02','P1-QUA-04','learning'),('P1QUA04-L03','P1-QUA-04','learning'),('P1QUA04-R01','P1-QUA-04','retest'),('P1QUA04-R02','P1-QUA-04','retest'),('P1QUA04-M01','P1-QUA-04','mixed'),
('P1QUA05-D01','P1-QUA-05','diagnostic'),('P1QUA05-L01','P1-QUA-05','learning'),('P1QUA05-L02','P1-QUA-05','learning'),('P1QUA05-L03','P1-QUA-05','learning'),('P1QUA05-R01','P1-QUA-05','retest'),('P1QUA05-R02','P1-QUA-05','retest'),('P1QUA05-M01','P1-QUA-05','mixed'),
('P1QUA06-D01','P1-QUA-06','diagnostic'),('P1QUA06-L01','P1-QUA-06','learning'),('P1QUA06-L02','P1-QUA-06','learning'),('P1QUA06-L03','P1-QUA-06','learning'),('P1QUA06-R01','P1-QUA-06','retest'),('P1QUA06-R02','P1-QUA-06','retest'),('P1QUA06-M01','P1-QUA-06','mixed')
)
insert into private.exam_prep_question_content_meta(
  content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
  exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
  copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
select cv.id,k.k,q.id,k.skill,'{}'::text[],k.role,'withheld','draft',
       'Original iClub-authored stem, numbers, distractors, answer and explanation; no Cambridge/coursebook question, diagram or mark-scheme wording copied.',
       'Authored for p1_aw09_12_quadratics_v1 from the canonical skill intent using independent examples.',
       'Cambridge 9709 2026-2027 v4; P1 1.1 Quadratics',
       'Complete Pure Mathematics 1, Ch1 Quadratics pp.2-20 (mapping only)',
       'pending','pending','pending','pending','pending',case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
       md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
         coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),
         coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),
         coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
         coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
         coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
         coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k
join public.questions q on q.book_ref='ExamPrep:P1:p1_aw09_12_quadratics_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

-- Exact authored-count guard and fail-closed deployment invariant.
do $$
declare v_id bigint; v_cfg private.exam_prep_feature_config%rowtype; begin
  select id into v_id from private.exam_prep_content_versions where content_version='p1_aw09_12_quadratics_v1';
  if v_id is null then raise exception 'P1-02 AW9-12 quadratics seed: content version missing'; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id)<>21 then
    raise exception 'P1-02 AW9-12 quadratics seed: expected 21 governed questions';
  end if;
  if (select count(*) from public.questions where book_ref like 'ExamPrep:P1:p1_aw09_12_quadratics_v1:%')<>21 then
    raise exception 'P1-02 AW9-12 quadratics seed: expected 21 public question rows';
  end if;
  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-02 AW9-12 quadratics seed escaped fail-closed';
  end if;
end $$;

commit;