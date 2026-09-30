-- AW21-24 supplemental learning pack draft for P1.
-- DRAFT ONLY: no learner exposure, QA self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw21_24_alt_p1_draft canonical program missing'; end if;
  if exists(select 1 from private.exam_prep_content_versions where id=4821 and content_version<>'p1_aw21_24_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15664 and 15673 and content_version_id<>4821)
     or exists(select 1 from private.exam_prep_assessments where id between 35511 and 35520 and content_version_id<>4821)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59478 and 59507 and content_version_id<>4821)
  then raise exception 'aw21_24_alt_p1_draft reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4821,pv.id,'p1_aw21_24_alt_learning_draft_v1','P1',
 'P1 AW21-24 supplemental learning pack draft v1','draft',
 'Original iClub-authored supplemental learning content. Official Cambridge 9709 scope and Complete Pure Mathematics 1 mappings define learning objectives only; no protected source question, solution, diagram or mark-scheme wording is copied. Independent academic, language, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P1COO05-A01','P1-COO-05','P1 Coordinate Geometry','medium','mcq','The line y=x+1 meets the circle x²+y²=13 at two points. What is the sum of the x-coordinates of the intersection points?','["−1","1","5","−5"]','A','Substitution gives x²+(x+1)²=13, so x²+x−6=0. The roots are 2 and −3, whose sum is −1.','Прямая y=x+1 пересекает окружность x²+y²=13 в двух точках. Чему равна сумма x-координат точек пересечения?','["−1","1","5","−5"]','После подстановки x²+(x+1)²=13 получаем x²+x−6=0. Корни 2 и −3, их сумма −1.','y=x+1 to‘g‘ri chiziq x²+y²=13 aylanani ikki nuqtada kesadi. Kesishish nuqtalarining x-koordinatalari yig‘indisi nechaga teng?','["−1","1","5","−5"]','Qo‘yishdan x²+(x+1)²=13, ya’ni x²+x−6=0 hosil bo‘ladi. Ildizlar 2 va −3, yig‘indisi −1.',75),
('P1COO05-A02','P1-COO-05','P1 Coordinate Geometry','medium','mcq','The vertical line x=3 cuts the circle x²+y²=25 at two points. What is the distance between the two intersection points?','["4","8","10","16"]','B','With x=3, y²=25−9=16, so y=±4. The two points differ by 8 units vertically.','Вертикальная прямая x=3 пересекает окружность x²+y²=25 в двух точках. Каково расстояние между ними?','["4","8","10","16"]','При x=3 получаем y²=25−9=16, поэтому y=±4. Точки отличаются по вертикали на 8 единиц.','x=3 vertikal chiziq x²+y²=25 aylanani ikki nuqtada kesadi. Bu nuqtalar orasidagi masofa qancha?','["4","8","10","16"]','x=3 da y²=25−9=16, shuning uchun y=±4. Nuqtalar vertikal bo‘yicha 8 birlik farq qiladi.',60),
('P1COO05-A03','P1-COO-05','P1 Coordinate Geometry','medium','input','The line y=−2 meets the circle (x−1)²+(y+2)²=25 at two points. Enter the distance between the two intersection points.','[]','10','Setting y=−2 gives (x−1)²=25, so x=6 or −4. Their horizontal separation is 10.','Прямая y=−2 пересекает окружность (x−1)²+(y+2)²=25 в двух точках. Введите расстояние между ними.','[]','При y=−2 имеем (x−1)²=25, поэтому x=6 или −4. Горизонтальное расстояние равно 10.','y=−2 chiziq (x−1)²+(y+2)²=25 aylanani ikki nuqtada kesadi. Nuqtalar orasidagi masofani kiriting.','[]','y=−2 da (x−1)²=25, demak x=6 yoki −4. Gorizontal masofa 10.',55),
('P1COO06-A01','P1-COO-06','P1 Coordinate Geometry','hard','mcq','The line y=x+c is tangent to the circle x²+y²=10. If c>0, find c.','["√5","5","2√5","10"]','C','Substitution gives 2x²+2cx+c²−10=0. Tangency requires discriminant 0: 4c²−8(c²−10)=0, hence c²=20 and c=2√5.','Прямая y=x+c касается окружности x²+y²=10. Если c>0, найдите c.','["√5","5","2√5","10"]','После подстановки получаем 2x²+2cx+c²−10=0. Для касания дискриминант равен 0: 4c²−8(c²−10)=0, откуда c²=20 и c=2√5.','y=x+c chiziq x²+y²=10 aylanaga urinma. c>0 bo‘lsa, c ni toping.','["√5","5","2√5","10"]','Qo‘yishdan 2x²+2cx+c²−10=0. Urinma uchun diskriminant 0: 4c²−8(c²−10)=0, demak c²=20 va c=2√5.',90),
('P1COO06-A02','P1-COO-06','P1 Coordinate Geometry','hard','mcq','The line y=2x+k is tangent to the circle x²+y²=16. What is k²?','["16","20","64","80"]','D','The distance from the origin to 2x−y+k=0 is |k|/√5. Tangency requires |k|/√5=4, so k²=80.','Прямая y=2x+k касается окружности x²+y²=16. Чему равно k²?','["16","20","64","80"]','Расстояние от начала координат до 2x−y+k=0 равно |k|/√5. Для касания |k|/√5=4, поэтому k²=80.','y=2x+k chiziq x²+y²=16 aylanaga urinma. k² nechaga teng?','["16","20","64","80"]','Koordinata boshidan 2x−y+k=0 gacha masofa |k|/√5. Urinma uchun |k|/√5=4, shuning uchun k²=80.',85),
('P1COO06-A03','P1-COO-06','P1 Coordinate Geometry','medium','input','The horizontal line y=k is tangent to the circle x²+y²=25. Enter the positive value of k.','[]','5','A horizontal tangent to a circle of radius 5 centred at the origin has distance 5 from the centre, so k=5 for the upper tangent.','Горизонтальная прямая y=k касается окружности x²+y²=25. Введите положительное значение k.','[]','Горизонтальная касательная к окружности радиуса 5 с центром в начале координат находится на расстоянии 5 от центра, поэтому для верхней касательной k=5.','y=k gorizontal chiziq x²+y²=25 aylanaga urinma. k ning musbat qiymatini kiriting.','[]','Markazi koordinata boshida va radiusi 5 bo‘lgan aylananing gorizontal urinmasi markazdan 5 masofada, yuqori urinma uchun k=5.',50),
('P1DIF05-A01','P1-DIF-05','P1 Differentiation Applications','medium','mcq','For a differentiable function, f′(x)=3(x−1)(x+2). On which interval is f decreasing?','["−2<x<1","x<−2","x>1","x<1"]','A','The derivative is negative only between its roots −2 and 1, so f decreases for −2<x<1.','Для дифференцируемой функции f′(x)=3(x−1)(x+2). На каком интервале f убывает?','["−2<x<1","x<−2","x>1","x<1"]','Производная отрицательна только между корнями −2 и 1, поэтому f убывает при −2<x<1.','Differensiallanuvchi funksiya uchun f′(x)=3(x−1)(x+2). f qaysi oraliqda kamayadi?','["−2<x<1","x<−2","x>1","x<1"]','Hosila faqat −2 va 1 ildizlari orasida manfiy, shuning uchun f −2<x<1 da kamayadi.',65),
('P1DIF05-A02','P1-DIF-05','P1 Differentiation Applications','medium','mcq','For f(x)=x³−12x, where is f increasing?','["−2<x<2","x<−2 or x>2","x>−2","x<2"]','B','f′(x)=3x²−12=3(x−2)(x+2), which is positive for x<−2 and x>2.','Для f(x)=x³−12x где функция возрастает?','["−2<x<2","x<−2 или x>2","x>−2","x<2"]','f′(x)=3x²−12=3(x−2)(x+2), и она положительна при x<−2 и x>2.','f(x)=x³−12x funksiyasi qayerda o‘sadi?','["−2<x<2","x<−2 yoki x>2","x>−2","x<2"]','f′(x)=3x²−12=3(x−2)(x+2), u x<−2 va x>2 da musbat.',65),
('P1DIF05-A03','P1-DIF-05','P1 Differentiation Applications','medium','input','A function has derivative f′(x)=(x−4)(x+1). Enter the length of the interval on which f is decreasing.','[]','5','The derivative is negative between −1 and 4. The interval length is 4−(−1)=5.','У функции f′(x)=(x−4)(x+1). Введите длину интервала, на котором f убывает.','[]','Производная отрицательна между −1 и 4. Длина интервала равна 4−(−1)=5.','Funksiya hosilasi f′(x)=(x−4)(x+1). f kamayadigan oraliq uzunligini kiriting.','[]','Hosila −1 va 4 orasida manfiy. Oraliq uzunligi 4−(−1)=5.',55),
('P1DIF06-A01','P1-DIF-06','P1 Differentiation Applications','medium','mcq','The radius of a circle is increasing at 0.4 cm/s. At the instant r=5 cm, what is dA/dt?','["2π cm²/s","10π cm²/s","4π cm²/s","20π cm²/s"]','C','A=πr², so dA/dt=2πr·dr/dt=2π(5)(0.4)=4π cm²/s.','Радиус окружности увеличивается со скоростью 0,4 см/с. В момент, когда r=5 см, чему равно dA/dt?','["2π см²/с","10π см²/с","4π см²/с","20π см²/с"]','A=πr², поэтому dA/dt=2πr·dr/dt=2π(5)(0,4)=4π см²/с.','Aylana radiusi 0.4 cm/s tezlik bilan oshmoqda. r=5 cm bo‘lgan paytda dA/dt nechaga teng?','["2π cm²/s","10π cm²/s","4π cm²/s","20π cm²/s"]','A=πr², demak dA/dt=2πr·dr/dt=2π(5)(0.4)=4π cm²/s.',70),
('P1DIF06-A02','P1-DIF-06','P1 Differentiation Applications','medium','mcq','The side length x of a cube is decreasing at 0.2 cm/s. When x=10 cm, at what rate is the volume decreasing?','["6 cm³/s","20 cm³/s","40 cm³/s","60 cm³/s"]','D','V=x³, so dV/dt=3x² dx/dt=3(100)(−0.2)=−60. Thus the volume decreases at 60 cm³/s.','Длина ребра x куба уменьшается со скоростью 0,2 см/с. Когда x=10 см, с какой скоростью уменьшается объём?','["6 см³/с","20 см³/с","40 см³/с","60 см³/с"]','V=x³, поэтому dV/dt=3x² dx/dt=3(100)(−0,2)=−60. Значит, объём уменьшается со скоростью 60 см³/с.','Kub qirrasi x 0.2 cm/s tezlik bilan kamaymoqda. x=10 cm bo‘lganda hajm qanday tezlik bilan kamayadi?','["6 cm³/s","20 cm³/s","40 cm³/s","60 cm³/s"]','V=x³, shuning uchun dV/dt=3x² dx/dt=3(100)(−0.2)=−60. Demak hajm 60 cm³/s tezlik bilan kamayadi.',70),
('P1DIF06-A03','P1-DIF-06','P1 Differentiation Applications','medium','input','A particle has displacement s=t³−6t²+9t metres. Enter its velocity at t=2 s.','[]','-3','v=ds/dt=3t²−12t+9. At t=2, v=12−24+9=−3 m/s.','Перемещение частицы s=t³−6t²+9t метров. Введите её скорость при t=2 с.','[]','v=ds/dt=3t²−12t+9. При t=2: v=12−24+9=−3 м/с.','Zarracha siljishi s=t³−6t²+9t metr. t=2 s dagi tezligini kiriting.','[]','v=ds/dt=3t²−12t+9. t=2 da v=12−24+9=−3 m/s.',55),
('P1DIF07-A01','P1-DIF-07','P1 Differentiation Applications','medium','mcq','For f(x)=x³−3x²+2, which statement about its stationary points is correct?','["x=0 is a local maximum and x=2 is a local minimum","x=0 is a local minimum and x=2 is a local maximum","Both are local maxima","Both are local minima"]','A','f′(x)=3x(x−2), so x=0,2. Since f″(x)=6x−6, f″(0)<0 gives a maximum and f″(2)>0 gives a minimum.','Для f(x)=x³−3x²+2 какое утверждение о стационарных точках верно?','["x=0 — локальный максимум, x=2 — локальный минимум","x=0 — локальный минимум, x=2 — локальный максимум","Обе — локальные максимумы","Обе — локальные минимумы"]','f′(x)=3x(x−2), поэтому x=0,2. Так как f″(x)=6x−6, f″(0)<0 даёт максимум, а f″(2)>0 — минимум.','f(x)=x³−3x²+2 uchun statsionar nuqtalar haqidagi qaysi fikr to‘g‘ri?','["x=0 lokal maksimum, x=2 lokal minimum","x=0 lokal minimum, x=2 lokal maksimum","Ikkalasi ham lokal maksimum","Ikkalasi ham lokal minimum"]','f′(x)=3x(x−2), demak x=0,2. f″(x)=6x−6 bo‘lgani uchun f″(0)<0 maksimum, f″(2)>0 minimum beradi.',75),
('P1DIF07-A02','P1-DIF-07','P1 Differentiation Applications','medium','mcq','A rectangle has perimeter 40 cm. What is its maximum possible area?','["80 cm²","100 cm²","120 cm²","160 cm²"]','B','If the sides are x and 20−x, A=x(20−x)=20x−x². Its maximum occurs at x=10, giving A=100 cm².','Прямоугольник имеет периметр 40 см. Какова его максимальная возможная площадь?','["80 см²","100 см²","120 см²","160 см²"]','Если стороны x и 20−x, то A=x(20−x)=20x−x². Максимум при x=10, поэтому A=100 см².','To‘g‘ri to‘rtburchak perimetri 40 cm. Uning mumkin bo‘lgan eng katta yuzi qancha?','["80 cm²","100 cm²","120 cm²","160 cm²"]','Tomonlar x va 20−x bo‘lsa, A=x(20−x)=20x−x². Maksimum x=10 da, A=100 cm².',65),
('P1DIF07-A03','P1-DIF-07','P1 Differentiation Applications','medium','input','Enter the minimum value of y=x²−6x+11.','[]','2','Completing the square gives y=(x−3)²+2, so the minimum value is 2.','Введите минимальное значение y=x²−6x+11.','[]','y=(x−3)²+2, поэтому минимальное значение равно 2.','y=x²−6x+11 funksiyaning minimum qiymatini kiriting.','[]','y=(x−3)²+2, shuning uchun minimum qiymat 2.',45),
('P1INT01-A01','P1-INT-01','P1 Integration','medium','mcq','Which is an antiderivative of 6x²−4x+5?','["6x³−4x²+5x+C","3x²−4+C","2x³−2x²+5+C","2x³−2x²+5x+C"]','C','Integrating term by term gives 2x³−2x²+5x+C.','Какая функция является первообразной для 6x²−4x+5?','["6x³−4x²+5x+C","3x²−4+C","2x³−2x²+5+C","2x³−2x²+5x+C"]','Интегрируя по членам, получаем 2x³−2x²+5x+C.','6x²−4x+5 uchun qaysi funksiya boshlang‘ich funksiya?','["6x³−4x²+5x+C","3x²−4+C","2x³−2x²+5+C","2x³−2x²+5x+C"]','Hadma-had integrallab, 2x³−2x²+5x+C hosil qilamiz.',60),
('P1INT01-A02','P1-INT-01','P1 Integration','medium','mcq','Evaluate ∫3(2x+1)² dx.','["3(2x+1)³+C","(2x+1)³+C","(2x+1)³/6+C","(2x+1)³/2+C"]','D','Because d(2x+1)/dx=2, ∫3(2x+1)²dx=3(2x+1)³/(3·2)=(2x+1)³/2+C.','Вычислите ∫3(2x+1)² dx.','["3(2x+1)³+C","(2x+1)³+C","(2x+1)³/6+C","(2x+1)³/2+C"]','Так как d(2x+1)/dx=2, ∫3(2x+1)²dx=3(2x+1)³/(3·2)=(2x+1)³/2+C.','∫3(2x+1)² dx ni hisoblang.','["3(2x+1)³+C","(2x+1)³+C","(2x+1)³/6+C","(2x+1)³/2+C"]','d(2x+1)/dx=2 bo‘lgani uchun ∫3(2x+1)²dx=3(2x+1)³/(3·2)=(2x+1)³/2+C.',65),
('P1INT01-A03','P1-INT-01','P1 Integration','easy','input','If F′(x)=8x³ and F(x) contains the term kx⁴, enter k.','[]','2','∫8x³dx=2x⁴+C, so k=2.','Если F′(x)=8x³ и F(x) содержит член kx⁴, введите k.','[]','∫8x³dx=2x⁴+C, поэтому k=2.','Agar F′(x)=8x³ va F(x) da kx⁴ hadi bo‘lsa, k ni kiriting.','[]','∫8x³dx=2x⁴+C, demak k=2.',40),
('P1INT02-A01','P1-INT-02','P1 Integration','medium','mcq','Given dy/dx=6x−4 and the curve passes through (2,5), what is the constant C in y=3x²−4x+C?','["1","−1","5","9"]','A','At x=2, y=12−8+C=4+C. Since y=5, C=1.','Дано dy/dx=6x−4, и кривая проходит через (2,5). Чему равна C в y=3x²−4x+C?','["1","−1","5","9"]','При x=2: y=12−8+C=4+C. Так как y=5, C=1.','dy/dx=6x−4 va egri chiziq (2,5) nuqtadan o‘tadi. y=3x²−4x+C dagi C nechaga teng?','["1","−1","5","9"]','x=2 da y=12−8+C=4+C. y=5 bo‘lgani uchun C=1.',55),
('P1INT02-A02','P1-INT-02','P1 Integration','medium','mcq','A curve has dy/dx=3x²+2 and passes through (1,7). Find y when x=2.','["12","16","18","20"]','B','Integrating gives y=x³+2x+C. The point (1,7) gives C=4, so y(2)=8+4+4=16.','Кривая имеет dy/dx=3x²+2 и проходит через (1,7). Найдите y при x=2.','["12","16","18","20"]','Интегрирование даёт y=x³+2x+C. Из точки (1,7) получаем C=4, поэтому y(2)=8+4+4=16.','Egri chiziq uchun dy/dx=3x²+2 va u (1,7) nuqtadan o‘tadi. x=2 da y ni toping.','["12","16","18","20"]','Integrallashdan y=x³+2x+C. (1,7) nuqtadan C=4, demak y(2)=8+4+4=16.',65),
('P1INT02-A03','P1-INT-02','P1 Integration','medium','input','A curve has dy/dx=4x³ and passes through (1,3). Enter its y-value at x=0.','[]','2','Integrating gives y=x⁴+C. Since 3=1+C, C=2, so y(0)=2.','Кривая имеет dy/dx=4x³ и проходит через (1,3). Введите её y-значение при x=0.','[]','Интегрирование даёт y=x⁴+C. Так как 3=1+C, C=2, поэтому y(0)=2.','Egri chiziq uchun dy/dx=4x³ va u (1,3) nuqtadan o‘tadi. x=0 dagi y qiymatini kiriting.','[]','Integrallashdan y=x⁴+C. 3=1+C bo‘lgani uchun C=2, demak y(0)=2.',55),
('P1INT03-A01','P1-INT-03','P1 Integration','medium','mcq','Evaluate ∫ from 0 to 3 of (2x+1) dx.','["9","10","12","14"]','C','An antiderivative is x²+x. Evaluating from 0 to 3 gives 9+3=12.','Вычислите ∫ от 0 до 3 (2x+1) dx.','["9","10","12","14"]','Первообразная x²+x. Подстановка пределов от 0 до 3 даёт 9+3=12.','0 dan 3 gacha ∫(2x+1) dx ni hisoblang.','["9","10","12","14"]','Boshlang‘ich funksiya x²+x. 0 va 3 chegaralarda hisoblasak 9+3=12.',50),
('P1INT03-A02','P1-INT-03','P1 Integration','medium','mcq','Evaluate ∫ from 0 to 4 of x^(−1/2) dx.','["2","8","1/2","4"]','D','An antiderivative is 2√x. The endpoint x=0 is finite here, and 2√4−2√0=4.','Вычислите ∫ от 0 до 4 x^(−1/2) dx.','["2","8","1/2","4"]','Первообразная 2√x. В точке x=0 значение предела конечно, и 2√4−2√0=4.','0 dan 4 gacha ∫x^(−1/2) dx ni hisoblang.','["2","8","1/2","4"]','Boshlang‘ich funksiya 2√x. x=0 dagi chegara bu yerda chekli, 2√4−2√0=4.',60),
('P1INT03-A03','P1-INT-03','P1 Integration','easy','input','Evaluate ∫ from 1 to 2 of 3x² dx.','[]','7','An antiderivative is x³, so the value is 2³−1³=7.','Вычислите ∫ от 1 до 2 3x² dx.','[]','Первообразная x³, поэтому значение равно 2³−1³=7.','1 dan 2 gacha ∫3x² dx ni hisoblang.','[]','Boshlang‘ich funksiya x³, qiymat 2³−1³=7.',40),
('P1INT04-A01','P1-INT-04','P1 Integration Applications','medium','mcq','Find the area under y=4−x² above the x-axis from x=0 to x=2.','["16/3","8/3","4","20/3"]','A','The area is ∫₀²(4−x²)dx=[4x−x³/3]₀²=8−8/3=16/3.','Найдите площадь под y=4−x² над осью x от x=0 до x=2.','["16/3","8/3","4","20/3"]','Площадь равна ∫₀²(4−x²)dx=[4x−x³/3]₀²=8−8/3=16/3.','y=4−x² grafigi ostidagi va x-o‘qi ustidagi x=0 dan x=2 gacha yuzani toping.','["16/3","8/3","4","20/3"]','Yuza ∫₀²(4−x²)dx=[4x−x³/3]₀²=8−8/3=16/3.',65),
('P1INT04-A02','P1-INT-04','P1 Integration Applications','medium','mcq','Find the area enclosed by y=x and y=x² between x=0 and x=1.','["1/3","1/6","1/2","2/3"]','B','On 0≤x≤1, x≥x². The area is ∫₀¹(x−x²)dx=1/2−1/3=1/6.','Найдите площадь между y=x и y=x² при 0≤x≤1.','["1/3","1/6","1/2","2/3"]','На 0≤x≤1 имеем x≥x². Площадь равна ∫₀¹(x−x²)dx=1/2−1/3=1/6.','0≤x≤1 da y=x va y=x² orasidagi yuzani toping.','["1/3","1/6","1/2","2/3"]','0≤x≤1 da x≥x². Yuza ∫₀¹(x−x²)dx=1/2−1/3=1/6.',60),
('P1INT04-A03','P1-INT-04','P1 Integration Applications','hard','input','Find the total area between y=x²−1 and the x-axis for −1≤x≤1. Enter the exact value.','[]','4/3','The curve is below the x-axis on [−1,1], so total area is ∫₋₁¹(1−x²)dx=4/3.','Найдите полную площадь между y=x²−1 и осью x при −1≤x≤1. Введите точное значение.','[]','Кривая ниже оси x на [−1,1], поэтому площадь равна ∫₋₁¹(1−x²)dx=4/3.','−1≤x≤1 da y=x²−1 va x-o‘qi orasidagi umumiy yuzani toping. Aniq qiymatni kiriting.','[]','Grafik [−1,1] da x-o‘qidan pastda, shuning uchun umumiy yuza ∫₋₁¹(1−x²)dx=4/3.',75),
('P1INT05-A01','P1-INT-05','P1 Integration Applications','medium','mcq','The region under y=x from x=0 to x=2 is rotated about the x-axis. What volume is formed?','["4π/3","4π","8π/3","8π"]','C','V=π∫₀²y²dx=π∫₀²x²dx=π[x³/3]₀²=8π/3.','Область под y=x от x=0 до x=2 вращается вокруг оси x. Какой объём образуется?','["4π/3","4π","8π/3","8π"]','V=π∫₀²y²dx=π∫₀²x²dx=π[x³/3]₀²=8π/3.','y=x ostidagi x=0 dan x=2 gacha soha x-o‘qi atrofida aylantiriladi. Hosil bo‘lgan hajm qancha?','["4π/3","4π","8π/3","8π"]','V=π∫₀²y²dx=π∫₀²x²dx=π[x³/3]₀²=8π/3.',65),
('P1INT05-A02','P1-INT-05','P1 Integration Applications','medium','mcq','The region under y=√x from x=0 to x=4 is rotated about the x-axis. Find the volume.','["4π","16π/3","4π²","8π"]','D','V=π∫₀⁴(√x)²dx=π∫₀⁴x dx=π[x²/2]₀⁴=8π.','Область под y=√x от x=0 до x=4 вращается вокруг оси x. Найдите объём.','["4π","16π/3","4π²","8π"]','V=π∫₀⁴(√x)²dx=π∫₀⁴x dx=π[x²/2]₀⁴=8π.','y=√x ostidagi x=0 dan x=4 gacha soha x-o‘qi atrofida aylantiriladi. Hajmni toping.','["4π","16π/3","4π²","8π"]','V=π∫₀⁴(√x)²dx=π∫₀⁴x dx=π[x²/2]₀⁴=8π.',65),
('P1INT05-A03','P1-INT-05','P1 Integration Applications','easy','input','The region under y=2 from x=0 to x=3 is rotated about the x-axis. The volume is kπ. Enter k.','[]','12','V=π∫₀³2²dx=4π(3)=12π, so k=12.','Область под y=2 от x=0 до x=3 вращается вокруг оси x. Объём равен kπ. Введите k.','[]','V=π∫₀³2²dx=4π(3)=12π, поэтому k=12.','y=2 ostidagi x=0 dan x=3 gacha soha x-o‘qi atrofida aylantiriladi. Hajm kπ ga teng. k ni kiriting.','[]','V=π∫₀³2²dx=4π(3)=12π, demak k=12.',45)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,s.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P1:p1_aw21_24_alt_learning_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P1:p1_aw21_24_alt_learning_draft_v1:'||s.content_key);

insert into private.exam_prep_written_tasks(
 id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
 prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
 lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15664,4821,'P1COO05-AW22','P1','P1-COO-05','{}'::text[],'v1','The circle x²+y²=25 meets the line y=x+1. Find both intersection points, then find the distance and midpoint between them. Show the substitution that produces the quadratic equation.','Окружность x²+y²=25 пересекает прямую y=x+1. Найдите обе точки пересечения, затем расстояние и середину отрезка между ними. Покажите подстановку, приводящую к квадратному уравнению.','x²+y²=25 aylana y=x+1 chiziq bilan kesishadi. Ikkala kesishish nuqtasini, ular orasidagi masofa va kesmaning o‘rta nuqtasini toping. Kvadrat tenglamaga olib keladigan qo‘yishni ko‘rsating.','{"max_marks":6,"criteria":[{"id":"sub","marks":1,"rule":"Substitutes y=x+1 into the circle."},{"id":"roots","marks":1,"rule":"Solves x²+(x+1)²=25 correctly."},{"id":"points","marks":1,"rule":"Finds both coordinate pairs."},{"id":"distance","marks":1,"rule":"Finds the distance between the points."},{"id":"midpoint","marks":1,"rule":"Finds the midpoint."},{"id":"working","marks":1,"rule":"Shows coherent algebra and exact values."}]}'::jsonb,'Substitute the line into the circle first. Keep each x-root paired with y=x+1 before using the distance and midpoint formulae.','Сначала подставьте уравнение прямой в окружность. Для каждого корня x найдите соответствующий y=x+1, затем используйте формулы расстояния и середины.','Avval chiziq tenglamasini aylana tenglamasiga qo‘ying. Har bir x ildizini y=x+1 bilan bog‘lab, keyin masofa va o‘rta nuqta formulalaridan foydalaning.','draft','pending','pending','pending','pending'),
(15665,4821,'P1COO06-AW22','P1','P1-COO-06','{}'::text[],'v1','The line y=2x+k is tangent to the circle x²+y²=20. Find both possible values of k and the point of contact for each tangent. Use either the discriminant or centre-to-line distance method and justify the tangency condition.','Прямая y=2x+k касается окружности x²+y²=20. Найдите оба возможных значения k и точку касания для каждой прямой. Используйте дискриминант или расстояние от центра до прямой и обоснуйте условие касания.','y=2x+k chiziq x²+y²=20 aylanaga urinadi. k ning ikkala mumkin bo‘lgan qiymatini va har bir urinma nuqtasini toping. Diskriminant yoki markazdan chiziqqacha masofa usulidan foydalanib, urinma shartini asoslang.','{"max_marks":6,"criteria":[{"id":"condition","marks":1,"rule":"States a valid tangency condition."},{"id":"k","marks":2,"rule":"Obtains k=±10."},{"id":"contact1","marks":1,"rule":"Finds the contact point for k=10."},{"id":"contact2","marks":1,"rule":"Finds the contact point for k=−10."},{"id":"verify","marks":1,"rule":"Verifies each point lies on both the circle and its tangent."}]}'::jsonb,'For a tangent there is one repeated intersection. If using distance, set the perpendicular distance from the origin to the line equal to the circle radius.','У касательной одна повторяющаяся точка пересечения. При методе расстояния приравняйте расстояние от начала координат до прямой радиусу окружности.','Urinmada bitta takroriy kesishish nuqtasi bo‘ladi. Masofa usulida koordinata boshidan chiziqqacha masofani aylana radiusiga tenglang.','draft','pending','pending','pending','pending'),
(15666,4821,'P1DIF05-AW22','P1','P1-DIF-05','{}'::text[],'v1','For f(x)=x³−6x²+9x+2, find all stationary x-values and determine the intervals on which f is increasing and decreasing. Present a sign chart for f′(x).','Для f(x)=x³−6x²+9x+2 найдите все стационарные значения x и интервалы возрастания и убывания. Представьте таблицу знаков f′(x).','f(x)=x³−6x²+9x+2 uchun barcha statsionar x qiymatlarni va o‘sish-kamayish oraliqlarini toping. f′(x) uchun ishora jadvalini ko‘rsating.','{"max_marks":6,"criteria":[{"id":"derivative","marks":1,"rule":"Finds f′(x)=3(x−1)(x−3)."},{"id":"points","marks":1,"rule":"Finds stationary x=1 and x=3."},{"id":"sign1","marks":1,"rule":"Correct sign for x<1."},{"id":"sign2","marks":1,"rule":"Correct sign for 1<x<3."},{"id":"sign3","marks":1,"rule":"Correct sign for x>3."},{"id":"intervals","marks":1,"rule":"States increasing and decreasing intervals correctly."}]}'::jsonb,'Factor f′(x), mark its roots on a number line, and test one value in each interval.','Разложите f′(x) на множители, отметьте корни на числовой прямой и проверьте по одному значению в каждом интервале.','f′(x) ni faktorlarga ajrating, ildizlarni son o‘qida belgilang va har bir oraliqda bittadan qiymat tekshiring.','draft','pending','pending','pending','pending'),
(15667,4821,'P1DIF06-AW22','P1','P1-DIF-06','{}'::text[],'v1','A spherical balloon has radius r increasing at 0.2 cm/s. Find dV/dt when r=5 cm, where V=4πr³/3. Then explain the sign and units of your answer.','Радиус сферического шара r увеличивается со скоростью 0,2 см/с. Найдите dV/dt при r=5 см, где V=4πr³/3. Затем объясните знак и единицы ответа.','Sferik sharning radiusi r 0.2 cm/s tezlik bilan oshmoqda. V=4πr³/3 bo‘lsa, r=5 cm da dV/dt ni toping. So‘ng javobning ishorasi va birliklarini tushuntiring.','{"max_marks":6,"criteria":[{"id":"differentiate","marks":2,"rule":"Uses dV/dt=4πr² dr/dt."},{"id":"substitute","marks":1,"rule":"Substitutes r=5 and dr/dt=0.2."},{"id":"value","marks":1,"rule":"Gets 20π cm³/s."},{"id":"sign","marks":1,"rule":"Explains positive sign because radius/volume increase."},{"id":"units","marks":1,"rule":"Uses cm³/s."}]}'::jsonb,'Differentiate V with respect to r first, then multiply by dr/dt. Keep the rate sign and cubic-volume units.','Сначала найдите dV/dr, затем умножьте на dr/dt. Сохраняйте знак скорости и кубические единицы объёма.','Avval dV/dr ni toping, keyin dr/dt ga ko‘paytiring. Tezlik ishorasi va hajmning kub birliklarini saqlang.','draft','pending','pending','pending','pending'),
(15668,4821,'P1DIF07-AW22','P1','P1-DIF-07','{}'::text[],'v1','A rectangle has perimeter 48 cm. Let one side be x cm. Express its area as a function of x, find the stationary point, prove it gives a maximum, and state the maximum area and dimensions.','Периметр прямоугольника 48 см. Пусть одна сторона равна x см. Выразите площадь через x, найдите стационарную точку, докажите, что это максимум, и укажите максимальную площадь и размеры.','To‘g‘ri to‘rtburchak perimetri 48 cm. Bir tomoni x cm bo‘lsin. Yuzani x orqali ifodalang, statsionar nuqtani toping, u maksimum ekanini isbotlang va maksimal yuza hamda o‘lchamlarni yozing.','{"max_marks":6,"criteria":[{"id":"model","marks":1,"rule":"Gets other side 24−x and A=x(24−x)."},{"id":"derivative","marks":1,"rule":"Gets A′=24−2x."},{"id":"stationary","marks":1,"rule":"Finds x=12."},{"id":"nature","marks":1,"rule":"Uses A″<0 or equivalent to prove maximum."},{"id":"area","marks":1,"rule":"Finds maximum area 144 cm²."},{"id":"dimensions","marks":1,"rule":"States 12 cm by 12 cm."}]}'::jsonb,'Use the perimeter to eliminate the second side before differentiating the area function.','С помощью периметра выразите вторую сторону через x, а затем дифференцируйте функцию площади.','Perimetr yordamida ikkinchi tomonni x orqali ifodalang, so‘ng yuza funksiyasini differensiallang.','draft','pending','pending','pending','pending'),
(15669,4821,'P1INT01-AW22','P1','P1-INT-01','{}'::text[],'v1','Find ∫[4x³−6x+2(3x+1)²] dx. Show the power-rule steps and the adjustment for the inner coefficient in (3x+1)². Differentiate your final answer to verify it.','Найдите ∫[4x³−6x+2(3x+1)²] dx. Покажите степенное правило и учёт внутреннего коэффициента в (3x+1)². Продефференцируйте итоговый ответ для проверки.','∫[4x³−6x+2(3x+1)²] dx ni toping. Daraja qoidasini va (3x+1)² dagi ichki koeffitsientni hisobga olishni ko‘rsating. Yakuniy javobni differensiallab tekshiring.','{"max_marks":6,"criteria":[{"id":"poly1","marks":1,"rule":"Integrates 4x³ to x⁴."},{"id":"poly2","marks":1,"rule":"Integrates −6x to −3x²."},{"id":"chain","marks":2,"rule":"Integrates 2(3x+1)² to 2(3x+1)³/9."},{"id":"constant","marks":1,"rule":"Includes +C."},{"id":"verify","marks":1,"rule":"Differentiates back to the integrand."}]}'::jsonb,'Integrate each term separately. For (ax+b)^n, divide by the inner coefficient a after increasing the power.','Интегрируйте каждый член отдельно. Для (ax+b)^n после повышения степени делите на внутренний коэффициент a.','Har bir hadni alohida integrallang. (ax+b)^n uchun darajani oshirgach, ichki a koeffitsientga bo‘ling.','draft','pending','pending','pending','pending'),
(15670,4821,'P1INT02-AW22','P1','P1-INT-02','{}'::text[],'v1','A curve has dy/dx=6x²−4 and passes through (1,5). Find its equation and then find y when x=2. Show how the point determines the constant of integration.','Кривая имеет dy/dx=6x²−4 и проходит через (1,5). Найдите её уравнение, затем y при x=2. Покажите, как точка определяет константу интегрирования.','Egri chiziq uchun dy/dx=6x²−4 va u (1,5) nuqtadan o‘tadi. Uning tenglamasini va x=2 dagi y ni toping. Nuqta integrallash doimiysini qanday aniqlashini ko‘rsating.','{"max_marks":6,"criteria":[{"id":"integrate","marks":2,"rule":"Gets y=2x³−4x+C."},{"id":"condition","marks":1,"rule":"Substitutes (1,5)."},{"id":"constant","marks":1,"rule":"Finds C=7."},{"id":"equation","marks":1,"rule":"States y=2x³−4x+7."},{"id":"value","marks":1,"rule":"Finds y(2)=15."}]}'::jsonb,'Integrate first and keep +C. Only then substitute the known point to determine C.','Сначала проинтегрируйте и оставьте +C. Только затем подставьте известную точку, чтобы определить C.','Avval integrallab +C ni qoldiring. Keyin ma’lum nuqtani qo‘yib C ni aniqlang.','draft','pending','pending','pending','pending'),
(15671,4821,'P1INT03-AW22','P1','P1-INT-03','{}'::text[],'v1','Evaluate exactly: (i) ∫ from 0 to 4 of x^(−1/2) dx; (ii) ∫ from 1 to 3 of (2x+1) dx. Show the antiderivative and substitution of the limits in each case.','Вычислите точно: (i) ∫ от 0 до 4 x^(−1/2) dx; (ii) ∫ от 1 до 3 (2x+1) dx. Покажите первообразную и подстановку пределов в каждом случае.','Aniq hisoblang: (i) 0 dan 4 gacha ∫x^(−1/2) dx; (ii) 1 dan 3 gacha ∫(2x+1) dx. Har birida boshlang‘ich funksiya va chegaralarni qo‘yishni ko‘rsating.','{"max_marks":6,"criteria":[{"id":"anti1","marks":1,"rule":"Uses antiderivative 2√x."},{"id":"value1","marks":1,"rule":"Gets 4."},{"id":"endpoint","marks":1,"rule":"Handles x=0 correctly."},{"id":"anti2","marks":1,"rule":"Uses antiderivative x²+x."},{"id":"value2","marks":1,"rule":"Gets 10."},{"id":"working","marks":1,"rule":"Shows upper-minus-lower substitution."}]}'::jsonb,'For a definite integral, find one antiderivative and evaluate F(upper)−F(lower). Treat the x=0 endpoint by its finite limiting value here.','Для определённого интеграла найдите первообразную и вычислите F(верхний)−F(нижний). В точке x=0 здесь используйте конечное предельное значение.','Aniq integral uchun boshlang‘ich funksiyani topib, F(yuqori)−F(pastki) ni hisoblang. x=0 da bu yerda chekli limit qiymatidan foydalaning.','draft','pending','pending','pending','pending'),
(15672,4821,'P1INT04-AW22','P1','P1-INT-04','{}'::text[],'v1','Find the total area between y=x²−4 and the x-axis for −3≤x≤3. Identify where the sign changes, split the integral correctly, and give an exact answer.','Найдите полную площадь между y=x²−4 и осью x при −3≤x≤3. Определите точки смены знака, правильно разбейте интеграл и дайте точный ответ.','−3≤x≤3 da y=x²−4 va x-o‘qi orasidagi umumiy yuzani toping. Ishora o‘zgaradigan nuqtalarni aniqlang, integralni to‘g‘ri bo‘ling va aniq javob bering.','{"max_marks":6,"criteria":[{"id":"roots","marks":1,"rule":"Identifies x=−2 and x=2."},{"id":"split","marks":1,"rule":"Splits the total-area calculation at both roots."},{"id":"middle","marks":1,"rule":"Uses 4−x² on the central interval."},{"id":"outer","marks":1,"rule":"Uses x²−4 on outer intervals."},{"id":"symmetry","marks":1,"rule":"Uses symmetry correctly or evaluates all pieces."},{"id":"answer","marks":1,"rule":"Gets total area 46/3."}]}'::jsonb,'Total geometric area is always positive. Split wherever the curve crosses the x-axis before integrating.','Полная геометрическая площадь всегда положительна. Разбейте область в точках пересечения с осью x до интегрирования.','Umumiy geometrik yuza har doim musbat. Integrallashdan oldin grafik x-o‘qini kesgan nuqtalarda sohani bo‘ling.','draft','pending','pending','pending','pending'),
(15673,4821,'P1INT05-AW22','P1','P1-INT-05','{}'::text[],'v1','The region under y=2x from x=0 to x=3 is rotated about the x-axis. Set up and evaluate the volume integral. State why the integrand contains y² and give the exact volume.','Область под y=2x от x=0 до x=3 вращается вокруг оси x. Составьте и вычислите интеграл объёма. Объясните, почему подынтегральная функция содержит y², и дайте точный объём.','y=2x ostidagi x=0 dan x=3 gacha soha x-o‘qi atrofida aylantiriladi. Hajm integralini tuzing va hisoblang. Nega integralda y² qatnashishini tushuntirib, aniq hajmni bering.','{"max_marks":6,"criteria":[{"id":"formula","marks":1,"rule":"Uses V=π∫y²dx."},{"id":"square","marks":1,"rule":"Substitutes y²=4x²."},{"id":"limits","marks":1,"rule":"Uses limits 0 to 3."},{"id":"integrate","marks":1,"rule":"Integrates 4x² correctly."},{"id":"answer","marks":1,"rule":"Gets 36π."},{"id":"reason","marks":1,"rule":"Links y² to circular cross-sectional area πy²."}]}'::jsonb,'For rotation about the x-axis, each cross-section is a disk of radius y, so dV=πy²dx.','При вращении вокруг оси x каждое сечение — диск радиуса y, поэтому dV=πy²dx.','x-o‘qi atrofida aylantirilganda har bir kesim radiusi y bo‘lgan disk, shuning uchun dV=πy²dx.','draft','pending','pending','pending','pending')
on conflict(id) do nothing;

with src(meta_id,content_key,skill_code,official_ref,book_ref) as (values
(59478,'P1COO05-A01','P1-COO-05','Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1; Ch3 pp. 48-67 (mapping only)'),
(59479,'P1COO05-A02','P1-COO-05','Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1; Ch3 pp. 48-67 (mapping only)'),
(59480,'P1COO05-A03','P1-COO-05','Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1; Ch3 pp. 48-67 (mapping only)'),
(59481,'P1COO06-A01','P1-COO-06','Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1; Ch3 pp. 48-67 (mapping only)'),
(59482,'P1COO06-A02','P1-COO-06','Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1; Ch3 pp. 48-67 (mapping only)'),
(59483,'P1COO06-A03','P1-COO-06','Cambridge 9709 2026-2027 v4; P1 1.3 Coordinate geometry','Complete Pure Mathematics 1; Ch3 pp. 48-67 (mapping only)'),
(59484,'P1DIF05-A01','P1-DIF-05','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1; Ch9 pp. 156-167 (mapping only)'),
(59485,'P1DIF05-A02','P1-DIF-05','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1; Ch9 pp. 156-167 (mapping only)'),
(59486,'P1DIF05-A03','P1-DIF-05','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1; Ch9 pp. 156-167 (mapping only)'),
(59487,'P1DIF06-A01','P1-DIF-06','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1; Ch9 pp. 156-167 (mapping only)'),
(59488,'P1DIF06-A02','P1-DIF-06','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1; Ch9 pp. 156-167 (mapping only)'),
(59489,'P1DIF06-A03','P1-DIF-06','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1; Ch9 pp. 156-167 (mapping only)'),
(59490,'P1DIF07-A01','P1-DIF-07','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1; Ch9 pp. 156-167 (mapping only)'),
(59491,'P1DIF07-A02','P1-DIF-07','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1; Ch9 pp. 156-167 (mapping only)'),
(59492,'P1DIF07-A03','P1-DIF-07','Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1; Ch9 pp. 156-167 (mapping only)'),
(59493,'P1INT01-A01','P1-INT-01','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59494,'P1INT01-A02','P1-INT-01','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59495,'P1INT01-A03','P1-INT-01','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59496,'P1INT02-A01','P1-INT-02','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59497,'P1INT02-A02','P1-INT-02','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59498,'P1INT02-A03','P1-INT-02','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59499,'P1INT03-A01','P1-INT-03','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59500,'P1INT03-A02','P1-INT-03','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59501,'P1INT03-A03','P1-INT-03','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59502,'P1INT04-A01','P1-INT-04','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59503,'P1INT04-A02','P1-INT-04','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59504,'P1INT04-A03','P1-INT-04','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59505,'P1INT05-A01','P1-INT-05','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59506,'P1INT05-A02','P1-INT-05','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)'),
(59507,'P1INT05-A03','P1-INT-05','Cambridge 9709 2026-2027 v4; P1 1.8 Integration','Complete Pure Mathematics 1; Ch10 pp. 173-200 (mapping only)')
)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,4821,s.content_key,q.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'Supplemental AW21-24 learning draft authored from the canonical skill intent with independent values and contexts, separate from the existing teaching pack.',
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
join public.questions q on q.book_ref='ExamPrep:P1:p1_aw21_24_alt_learning_draft_v1:'||s.content_key
on conflict(id) do nothing;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35511,4821,'P1-COO-05-learning-alt-04','v1','P1','learning','draft','Line and circle intersections','Пересечения прямой и окружности','Chiziq va aylana kesishishlari'),
(35512,4821,'P1-COO-06-learning-alt-04','v1','P1','learning','draft','Tangency and parameter conditions','Касание и условия на параметры','Urinma va parametr shartlari'),
(35513,4821,'P1-DIF-05-learning-alt-04','v1','P1','learning','draft','Increasing and decreasing intervals','Интервалы возрастания и убывания','O‘sish va kamayish oraliqlari'),
(35514,4821,'P1-DIF-06-learning-alt-04','v1','P1','learning','draft','Rates of change','Скорости изменения','O‘zgarish tezliklari'),
(35515,4821,'P1-DIF-07-learning-alt-04','v1','P1','learning','draft','Stationary points and optimisation','Стационарные точки и оптимизация','Statsionar nuqtalar va optimallashtirish'),
(35516,4821,'P1-INT-01-learning-alt-04','v1','P1','learning','draft','Antiderivatives','Первообразные','Boshlang‘ich funksiyalar'),
(35517,4821,'P1-INT-02-learning-alt-04','v1','P1','learning','draft','Constants and curve reconstruction','Константа и восстановление кривой','Doimiy va egri chiziqni tiklash'),
(35518,4821,'P1-INT-03-learning-alt-04','v1','P1','learning','draft','Definite integrals','Определённые интегралы','Aniq integrallar'),
(35519,4821,'P1-INT-04-learning-alt-04','v1','P1','learning','draft','Areas by integration','Площади с помощью интегрирования','Integrallash orqali yuzalar'),
(35520,4821,'P1-INT-05-learning-alt-04','v1','P1','learning','draft','Volumes of revolution','Объёмы вращения','Aylanish hajmlari')
on conflict(id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35511,1,'P1COO05-A01',null::bigint,'P1-COO-05'),
(35511,2,'P1COO05-A02',null::bigint,'P1-COO-05'),
(35511,3,'P1COO05-A03',null::bigint,'P1-COO-05'),
(35511,4,null,15664,'P1-COO-05'),
(35512,1,'P1COO06-A01',null::bigint,'P1-COO-06'),
(35512,2,'P1COO06-A02',null::bigint,'P1-COO-06'),
(35512,3,'P1COO06-A03',null::bigint,'P1-COO-06'),
(35512,4,null,15665,'P1-COO-06'),
(35513,1,'P1DIF05-A01',null::bigint,'P1-DIF-05'),
(35513,2,'P1DIF05-A02',null::bigint,'P1-DIF-05'),
(35513,3,'P1DIF05-A03',null::bigint,'P1-DIF-05'),
(35513,4,null,15666,'P1-DIF-05'),
(35514,1,'P1DIF06-A01',null::bigint,'P1-DIF-06'),
(35514,2,'P1DIF06-A02',null::bigint,'P1-DIF-06'),
(35514,3,'P1DIF06-A03',null::bigint,'P1-DIF-06'),
(35514,4,null,15667,'P1-DIF-06'),
(35515,1,'P1DIF07-A01',null::bigint,'P1-DIF-07'),
(35515,2,'P1DIF07-A02',null::bigint,'P1-DIF-07'),
(35515,3,'P1DIF07-A03',null::bigint,'P1-DIF-07'),
(35515,4,null,15668,'P1-DIF-07'),
(35516,1,'P1INT01-A01',null::bigint,'P1-INT-01'),
(35516,2,'P1INT01-A02',null::bigint,'P1-INT-01'),
(35516,3,'P1INT01-A03',null::bigint,'P1-INT-01'),
(35516,4,null,15669,'P1-INT-01'),
(35517,1,'P1INT02-A01',null::bigint,'P1-INT-02'),
(35517,2,'P1INT02-A02',null::bigint,'P1-INT-02'),
(35517,3,'P1INT02-A03',null::bigint,'P1-INT-02'),
(35517,4,null,15670,'P1-INT-02'),
(35518,1,'P1INT03-A01',null::bigint,'P1-INT-03'),
(35518,2,'P1INT03-A02',null::bigint,'P1-INT-03'),
(35518,3,'P1INT03-A03',null::bigint,'P1-INT-03'),
(35518,4,null,15671,'P1-INT-03'),
(35519,1,'P1INT04-A01',null::bigint,'P1-INT-04'),
(35519,2,'P1INT04-A02',null::bigint,'P1-INT-04'),
(35519,3,'P1INT04-A03',null::bigint,'P1-INT-04'),
(35519,4,null,15672,'P1-INT-04'),
(35520,1,'P1INT05-A01',null::bigint,'P1-INT-05'),
(35520,2,'P1INT05-A02',null::bigint,'P1-INT-05'),
(35520,3,'P1INT05-A03',null::bigint,'P1-INT-05'),
(35520,4,null,15673,'P1-INT-05')
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select i.assessment_id,i.item_order,q.id,i.written_id,i.skill_code,
 case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions q on i.content_key is not null
 and q.book_ref='ExamPrep:P1:p1_aw21_24_alt_learning_draft_v1:'||i.content_key
on conflict(assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4821)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4821 and lifecycle_state='draft' and reserve_role='learning')<>30
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4821 and lifecycle_state='draft')<>10
     or (select count(*) from private.exam_prep_assessments where content_version_id=4821 and status='draft' and assessment_type='learning')<>10
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4821)<>40
  then raise exception 'aw21_24_alt_p1_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4821 and (
    m.exposure_state<>'withheld' or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or q.is_active or q.quality_status<>'draft'
  );
  if v_bad<>0 then raise exception 'aw21_24_alt_p1_draft exposure/QA boundary rows=%',v_bad; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id where m.content_version_id=4821;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(5,5,5,5,10) then
    raise exception 'aw21_24_alt_p1_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4821
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4821
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw21_24_alt_p1_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4821)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4821)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4821)
  then raise exception 'aw21_24_alt_p1_draft unexpected history'; end if;
end
$postcheck$;

commit;
