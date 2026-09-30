-- AW9-12 annual reserve independent QA corrections v1.
-- Draft/history-free reserve only. No publication or learner exposure.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_content_versions where id in (4811,4812) and status='draft')<>2 then
    raise exception 'aw09_12 annual reserve QA: target draft versions missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4811,4812))<>70
     or (select count(*) from private.exam_prep_assessments where content_version_id in (4811,4812) and status='draft')<>34
  then
    raise exception 'aw09_12 annual reserve QA: candidate surface mismatch';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4811,4812) and content_key in ('P1CIR02-D02','P1CIR02-D03','P1COO04-D02','P1COO04-D03','P1FUN03-D02','P1FUN04-D02','P1FUN04-D03','P1FUN05-D02','P1FUN05-D03','P1FUN05-R03','P1FUN05-R04','P1FUN05-M02','P1QUA05-D02','P1QUA05-D03','P1QUA05-R03','P1QUA06-D02','P1QUA06-D03','P1QUA06-R04','P1QUA04-R04','P5DAT03-D02','P5DAT03-D03','P5DAT03-R03','P5DAT03-R04','P5DAT05-D02','P5DAT05-D03','P5DAT05-R03','P5DAT07-D02','P5DAT07-D03','P5DAT07-R03','P5CNT05-D03','P5CNT05-R03','P5PRO02-D02','P5PRO02-D03','P5PRO02-R04','P5PRO04-D02','P5PRO04-D03','P5PRO04-R03','P5PRO04-R04'))<>38 then
    raise exception 'aw09_12 annual reserve QA: correction targets missing';
  end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id in (4811,4812))
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id in (4811,4812))
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id in (4811,4812))
  then raise exception 'aw09_12 annual reserve QA: target draft has learner/legacy history'; end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id in (4811,4812)
      and (m.lifecycle_state<>'draft' or m.exposure_state<>'withheld' or q.is_active or q.quality_status<>'draft')
  ) then raise exception 'aw09_12 annual reserve QA: draft exposure boundary changed'; end if;
end
$preflight$;

with fixes(content_key,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz) as (values
('P1CIR02-D02','A sector has radius 9 cm. Its arc is 6 cm longer than its radius. What is the central angle in radians?','["2/3","3/5","5/3","15"]','C','The arc length is 9+6=15 cm. Hence θ=s/r=15/9=5/3 radians.','Радиус сектора равен 9 см. Длина его дуги на 6 см больше радиуса. Каков центральный угол в радианах?','["2/3","3/5","5/3","15"]','Длина дуги равна 9+6=15 см. Поэтому θ=s/r=15/9=5/3 радиана.','Sektor radiusi 9 sm. Uning yoy uzunligi radiusdan 6 sm katta. Markaziy burchak necha radian?','["2/3","3/5","5/3","15"]','Yoy uzunligi 9+6=15 sm. Demak θ=s/r=15/9=5/3 radian.'),
('P1CIR02-D03','An arc has fixed length. Its radius is increased from 6 cm to 8 cm. The new central angle is what fraction of the original angle?','["4/3","2/3","1/2","3/4"]','D','For fixed arc length, θ=s/r. Therefore θ_new/θ_old=(s/8)/(s/6)=6/8=3/4.','Длина дуги остаётся неизменной. Радиус увеличили с 6 см до 8 см. Какую долю первоначального угла составляет новый центральный угол?','["4/3","2/3","1/2","3/4"]','При неизменной длине дуги θ=s/r. Поэтому θнов/θисх=(s/8)/(s/6)=6/8=3/4.','Yoy uzunligi o‘zgarmaydi. Radius 6 sm dan 8 sm ga oshiriladi. Yangi markaziy burchak dastlabki burchakning qanday ulushi bo‘ladi?','["4/3","2/3","1/2","3/4"]','Yoy uzunligi o‘zgarmasa θ=s/r. Shuning uchun θ_yangi/θ_eski=(s/8)/(s/6)=6/8=3/4.'),
('P1COO04-D02','The circle x²+y²+ax−6y+9=0 has centre (4,3). Find a.','["−8","8","−4","4"]','A','For x²+y²+ax+by+c=0, the centre is (−a/2,−b/2). Here −a/2=4, so a=−8.','Окружность x²+y²+ax−6y+9=0 имеет центр (4,3). Найдите a.','["−8","8","−4","4"]','Для x²+y²+ax+by+c=0 центр равен (−a/2,−b/2). Здесь −a/2=4, поэтому a=−8.','x²+y²+ax−6y+9=0 aylananing markazi (4,3). a ni toping.','["−8","8","−4","4"]','x²+y²+ax+by+c=0 uchun markaz (−a/2,−b/2). Bu yerda −a/2=4, demak a=−8.'),
('P1COO04-D03','Which point lies strictly inside the circle (x−2)²+(y+1)²=25?','["(7,−1)","(2,3)","(2,4)","(−3,−1)"]','B','The circle has centre (2,−1) and radius 5. Point (2,3) is 4 units from the centre, while the other three points are exactly 5 units away.','Какая точка лежит строго внутри окружности (x−2)²+(y+1)²=25?','["(7,−1)","(2,3)","(2,4)","(−3,−1)"]','Центр окружности (2,−1), радиус 5. Точка (2,3) находится на расстоянии 4 от центра, а остальные три — на расстоянии 5.','Qaysi nuqta (x−2)²+(y+1)²=25 aylananing qat’iy ichida yotadi?','["(7,−1)","(2,3)","(2,4)","(−3,−1)"]','Aylana markazi (2,−1), radiusi 5. (2,3) nuqta markazdan 4 birlik uzoqda, qolgan uch nuqta esa aynan 5 birlik uzoqda.'),
('P1FUN03-D02','Let f(x)=1/(x−2) and g(x)=x+4. Which pair of restrictions is correct for the domains of (f∘g)(x) and (g∘f)(x), respectively?','["x≠2; x≠−2","x≠−2; x≠−2","x≠−2; x≠2","no restrictions; x≠2"]','C','f(g(x))=1/(x+2), so x≠−2. For g(f(x)), f must first be defined, so x≠2.','Пусть f(x)=1/(x−2), g(x)=x+4. Какая пара ограничений верна для областей определения (f∘g)(x) и (g∘f)(x) соответственно?','["x≠2; x≠−2","x≠−2; x≠−2","x≠−2; x≠2","нет ограничений; x≠2"]','f(g(x))=1/(x+2), поэтому x≠−2. Для g(f(x)) сначала должна быть определена f, поэтому x≠2.','f(x)=1/(x−2), g(x)=x+4 bo‘lsin. (f∘g)(x) va (g∘f)(x) aniqlanish sohalari uchun mos ravishda qaysi cheklovlar to‘g‘ri?','["x≠2; x≠−2","x≠−2; x≠−2","x≠−2; x≠2","cheklov yo‘q; x≠2"]','f(g(x))=1/(x+2), demak x≠−2. g(f(x)) uchun avval f aniqlangan bo‘lishi kerak, shuning uchun x≠2.'),
('P1FUN04-D02','Let f(x)=x²−6x+5. Which domain restriction makes f one-one and gives the inverse branch f⁻¹(x)=3+√(x+4)?','["x≥3","x≤3","x≥−4","all real x"]','A','f(x)=(x−3)²−4. The branch x≥3 is one-one and has x−3≥0, giving f⁻¹(y)=3+√(y+4).','Пусть f(x)=x²−6x+5. Какое ограничение области определения делает f взаимно однозначной и даёт ветвь f⁻¹(x)=3+√(x+4)?','["x≥3","x≤3","x≥−4","все действительные x"]','f(x)=(x−3)²−4. На ветви x≥3 функция взаимно однозначна и x−3≥0, поэтому f⁻¹(y)=3+√(y+4).','f(x)=x²−6x+5 bo‘lsin. Qaysi soha cheklovi f ni bir qiymatli qilib, f⁻¹(x)=3+√(x+4) tarmog‘ini beradi?','["x≥3","x≤3","x≥−4","barcha haqiqiy x"]','f(x)=(x−3)²−4. x≥3 tarmog‘ida funksiya bir qiymatli va x−3≥0, shuning uchun f⁻¹(y)=3+√(y+4).'),
('P1FUN04-D03','The function f(x)=|x−2| is defined for all real x. Why does it not have an inverse function on this full domain?','["Its range contains only non-negative values","Different inputs can give the same output","Its graph has no y-intercept","Its domain is unbounded"]','B','For example, f(1)=f(3)=1. Reversing the mapping would assign one inverse input to two outputs, so the inverse relation would not be a function.','Функция f(x)=|x−2| определена для всех действительных x. Почему на всей этой области у неё нет обратной функции?','["Её область значений содержит только неотрицательные числа","Разные входные значения могут давать один и тот же результат","Её график не пересекает ось y","Её область определения не ограничена"]','Например, f(1)=f(3)=1. При обращении одному входу соответствовали бы два выхода, поэтому обратное отношение не было бы функцией.','f(x)=|x−2| barcha haqiqiy x lar uchun aniqlangan. Nega to‘liq sohada uning teskari funksiyasi yo‘q?','["Qiymatlar sohasi faqat manfiy bo‘lmagan sonlardan iborat","Turli kirishlar bir xil chiqish berishi mumkin","Grafik y o‘qini kesmaydi","Aniqlanish sohasi cheklanmagan"]','Masalan, f(1)=f(3)=1. Akslantirishni teskarilaganda bitta kirishga ikkita chiqish mos keladi, shuning uchun teskari bog‘lanish funksiya bo‘lmaydi.'),
('P1FUN05-D02','A point P=(−2,6) lies on y=f(x), and Q is the corresponding point on y=f⁻¹(x). Which line is the perpendicular bisector of PQ?','["y=−x","x=2","y=x","y=2"]','C','Q=(6,−2). A graph and its inverse are reflections in y=x, so y=x is the perpendicular bisector of the segment joining corresponding points.','Точка P=(−2,6) лежит на y=f(x), а Q — соответствующая точка на y=f⁻¹(x). Какая прямая является серединным перпендикуляром к PQ?','["y=−x","x=2","y=x","y=2"]','Q=(6,−2). График функции и её обратной отражаются относительно y=x, поэтому y=x является серединным перпендикуляром к отрезку между соответствующими точками.','P=(−2,6) nuqta y=f(x) da, Q esa y=f⁻¹(x) dagi mos nuqta. PQ kesmaning o‘rta perpendikulyari qaysi chiziq?','["y=−x","x=2","y=x","y=2"]','Q=(6,−2). Funksiya va uning teskarisi y=x ga nisbatan akslangan, shuning uchun y=x mos nuqtalarni tutashtiruvchi kesmaning o‘rta perpendikulyaridir.'),
('P1FUN05-D03','A point P=(1,5) on y=f(x) corresponds to Q on y=f⁻¹(x). What is the gradient of PQ?','["1","4","−4","−1"]','D','Q=(5,1). The gradient of PQ is (1−5)/(5−1)=−4/4=−1.','Точке P=(1,5) на y=f(x) соответствует точка Q на y=f⁻¹(x). Каков градиент PQ?','["1","4","−4","−1"]','Q=(5,1). Градиент PQ равен (1−5)/(5−1)=−4/4=−1.','y=f(x) dagi P=(1,5) nuqtaga y=f⁻¹(x) da Q nuqta mos keladi. PQ gradienti qancha?','["1","4","−4","−1"]','Q=(5,1). PQ gradienti (1−5)/(5−1)=−4/4=−1.'),
('P1FUN05-R03','A point P=(−2,5) on y=f(x) corresponds to Q on y=f⁻¹(x). The distance PQ is a√2. Enter a.','[]','7','Q=(5,−2). Hence PQ=√(7²+(−7)²)=√98=7√2, so a=7.','Точке P=(−2,5) на y=f(x) соответствует точка Q на y=f⁻¹(x). Расстояние PQ равно a√2. Введите a.','[]','Q=(5,−2). Тогда PQ=√(7²+(−7)²)=√98=7√2, поэтому a=7.','y=f(x) dagi P=(−2,5) nuqtaga y=f⁻¹(x) da Q nuqta mos keladi. PQ masofa a√2 ga teng. a ni kiriting.','[]','Q=(5,−2). Demak PQ=√(7²+(−7)²)=√98=7√2, shuning uchun a=7.'),
('P1FUN05-R04','For f(x)=2x+b, the graphs y=f(x) and y=f⁻¹(x) meet at (−3,−3). Find b.','["−9","3","−3","9"]','B','A common point (−3,−3) is a fixed point of f, so f(−3)=−3. Thus −6+b=−3 and b=3.','Для f(x)=2x+b графики y=f(x) и y=f⁻¹(x) пересекаются в точке (−3,−3). Найдите b.','["−9","3","−3","9"]','Общая точка (−3,−3) является неподвижной точкой f, поэтому f(−3)=−3. Получаем −6+b=−3 и b=3.','f(x)=2x+b uchun y=f(x) va y=f⁻¹(x) grafiklari (−3,−3) nuqtada kesishadi. b ni toping.','["−9","3","−3","9"]','Umumiy (−3,−3) nuqta f ning qo‘zg‘almas nuqtasi, demak f(−3)=−3. Shundan −6+b=−3 va b=3.'),
('P1FUN05-M02','A point P=(1,5) on y=f(x) is reflected to Q on y=f⁻¹(x). If PQ=a√2, enter a.','[]','4','Q=(5,1). Therefore PQ=√(4²+(−4)²)=4√2, so a=4.','Точка P=(1,5) на y=f(x) отражается в точку Q на y=f⁻¹(x). Если PQ=a√2, введите a.','[]','Q=(5,1). Поэтому PQ=√(4²+(−4)²)=4√2, значит a=4.','y=f(x) dagi P=(1,5) nuqta y=f⁻¹(x) dagi Q ga akslanadi. Agar PQ=a√2 bo‘lsa, a ni kiriting.','[]','Q=(5,1). Shuning uchun PQ=√(4²+(−4)²)=4√2, demak a=4.'),
('P1QUA05-D02','The system x+y=6 and y=x²−6 has two solutions. Which pair of points is correct?','["(2,4) and (−3,9)","(3,3) and (−3,9)","(3,3) and (−4,10)","(4,2) and (−3,9)"]','C','Substitute y=6−x into y=x²−6: 6−x=x²−6, so x²+x−12=0=(x−3)(x+4). The points are (3,3) and (−4,10).','Система x+y=6 и y=x²−6 имеет два решения. Какая пара точек верна?','["(2,4) и (−3,9)","(3,3) и (−3,9)","(3,3) и (−4,10)","(4,2) и (−3,9)"]','Подставляем y=6−x в y=x²−6: 6−x=x²−6, поэтому x²+x−12=0=(x−3)(x+4). Точки: (3,3) и (−4,10).','x+y=6 va y=x²−6 sistema ikkita yechimga ega. Qaysi nuqtalar jufti to‘g‘ri?','["(2,4) va (−3,9)","(3,3) va (−3,9)","(3,3) va (−4,10)","(4,2) va (−3,9)"]','y=6−x ni y=x²−6 ga qo‘yamiz: 6−x=x²−6, demak x²+x−12=0=(x−3)(x+4). Nuqtalar (3,3) va (−4,10).'),
('P1QUA05-D03','To solve the simultaneous equations y=7−2x and y=x²+1, which quadratic equation in x should be solved?','["x²−2x−6=0","x²+2x+6=0","x²−2x+6=0","x²+2x−6=0"]','D','Set the two y-expressions equal: x²+1=7−2x. Rearranging gives x²+2x−6=0.','Для решения системы y=7−2x и y=x²+1 какое квадратное уравнение по x нужно решить?','["x²−2x−6=0","x²+2x+6=0","x²−2x+6=0","x²+2x−6=0"]','Приравниваем выражения для y: x²+1=7−2x. После переноса получаем x²+2x−6=0.','y=7−2x va y=x²+1 sistemani yechish uchun x bo‘yicha qaysi kvadrat tenglama yechilishi kerak?','["x²−2x−6=0","x²+2x+6=0","x²−2x+6=0","x²+2x−6=0"]','y ifodalarni tenglashtiramiz: x²+1=7−2x. Tartibga keltirib x²+2x−6=0 ni olamiz.'),
('P1QUA05-R03','The line y=mx+1 intersects the parabola y=x²+1 at x=0 and x=5. Enter m.','[]','5','At intersections, mx+1=x²+1, so x(x−m)=0. The two roots are 0 and m. Since the second root is 5, m=5.','Прямая y=mx+1 пересекает параболу y=x²+1 при x=0 и x=5. Введите m.','[]','В точках пересечения mx+1=x²+1, поэтому x(x−m)=0. Корни равны 0 и m. Второй корень равен 5, значит m=5.','y=mx+1 chiziq y=x²+1 parabola bilan x=0 va x=5 da kesishadi. m ni kiriting.','[]','Kesishishda mx+1=x²+1, demak x(x−m)=0. Ildizlar 0 va m. Ikkinchi ildiz 5 bo‘lgani uchun m=5.'),
('P1QUA06-D02','Which substitution turns x⁸−10x⁴+9=0 into a quadratic equation in one new variable?','["u=x⁴","u=x²","u=x³","u=x⁸"]','A','With u=x⁴, the equation becomes u²−10u+9=0, which is quadratic in u.','Какая замена превращает x⁸−10x⁴+9=0 в квадратное уравнение относительно новой переменной?','["u=x⁴","u=x²","u=x³","u=x⁸"]','При u=x⁴ уравнение становится u²−10u+9=0, то есть квадратным по u.','Qaysi almashtirish x⁸−10x⁴+9=0 tenglamani yangi o‘zgaruvchi bo‘yicha kvadrat tenglamaga aylantiradi?','["u=x⁴","u=x²","u=x³","u=x⁸"]','u=x⁴ deb olsak, tenglama u²−10u+9=0 ko‘rinishga keladi va u bo‘yicha kvadrat bo‘ladi.'),
('P1QUA06-D03','For (x²−x)²−7(x²−x)+10=0, let u=x²−x. Which pair of equations in x must then be solved?','["x²−x=−2 or x²−x=−5","x²−x=2 or x²−x=5","x²−x=1 or x²−x=10","x²−x=−1 or x²−x=10"]','B','The transformed equation is u²−7u+10=0=(u−2)(u−5), so u=2 or 5. Substitute back to get x²−x=2 or x²−x=5.','Для (x²−x)²−7(x²−x)+10=0 положим u=x²−x. Какую пару уравнений по x затем нужно решить?','["x²−x=−2 или x²−x=−5","x²−x=2 или x²−x=5","x²−x=1 или x²−x=10","x²−x=−1 или x²−x=10"]','Преобразованное уравнение: u²−7u+10=0=(u−2)(u−5), поэтому u=2 или 5. После обратной подстановки получаем x²−x=2 или x²−x=5.','(x²−x)²−7(x²−x)+10=0 uchun u=x²−x deb olaylik. Keyin x bo‘yicha qaysi juft tenglamani yechish kerak?','["x²−x=−2 yoki x²−x=−5","x²−x=2 yoki x²−x=5","x²−x=1 yoki x²−x=10","x²−x=−1 yoki x²−x=10"]','O‘zgartirilgan tenglama u²−7u+10=0=(u−2)(u−5), demak u=2 yoki 5. Qayta qo‘ysak x²−x=2 yoki x²−x=5.'),
('P1QUA06-R04','For which value of k does x⁴−kx²+9=0 become (x²−3)²=0?','["3","6","9","12"]','B','(x²−3)²=x⁴−6x²+9, so k=6.','При каком k уравнение x⁴−kx²+9=0 превращается в (x²−3)²=0?','["3","6","9","12"]','(x²−3)²=x⁴−6x²+9, поэтому k=6.','Qaysi k qiymatda x⁴−kx²+9=0 tenglama (x²−3)²=0 ko‘rinishga keladi?','["3","6","9","12"]','(x²−3)²=x⁴−6x²+9, demak k=6.'),
('P1QUA04-R04','Among the integers −1≤x≤7, how many satisfy x²−6x+8>0?','["5","6","7","4"]','B','x²−6x+8=(x−2)(x−4)>0 gives x<2 or x>4. In the stated range the integers are −1,0,1,5,6,7: six values.','Сколько целых x в диапазоне −1≤x≤7 удовлетворяют x²−6x+8>0?','["5","6","7","4"]','x²−6x+8=(x−2)(x−4)>0 даёт x<2 или x>4. В указанном диапазоне это −1,0,1,5,6,7 — шесть значений.','−1≤x≤7 oralig‘idagi nechta butun x qiymat x²−6x+8>0 tengsizlikni qanoatlantiradi?','["5","6","7","4"]','x²−6x+8=(x−2)(x−4)>0 dan x<2 yoki x>4. Berilgan oraliqda −1,0,1,5,6,7 — oltita qiymat.'),
('P5DAT03-D02','Which ordered list could be a five-number summary (minimum, Q1, median, Q3, maximum) for a data set?','["4, 8, 10, 15, 20","4, 12, 10, 15, 20","4, 8, 16, 15, 20","4, 8, 10, 21, 20"]','A','A five-number summary must be non-decreasing from minimum through maximum. Only 4,8,10,15,20 has the required order.','Какой упорядоченный список может быть пятичисловой сводкой (минимум, Q1, медиана, Q3, максимум) набора данных?','["4, 8, 10, 15, 20","4, 12, 10, 15, 20","4, 8, 16, 15, 20","4, 8, 10, 21, 20"]','Пятичисловая сводка должна быть неубывающей от минимума до максимума. Только 4,8,10,15,20 имеет правильный порядок.','Qaysi tartibli ro‘yxat ma’lumotlar to‘plamining besh sonli xulosasi (minimum, Q1, mediana, Q3, maksimum) bo‘lishi mumkin?','["4, 8, 10, 15, 20","4, 12, 10, 15, 20","4, 8, 16, 15, 20","4, 8, 10, 21, 20"]','Besh sonli xulosa minimumdan maksimumgacha kamaymasligi kerak. Faqat 4,8,10,15,20 to‘g‘ri tartibda.'),
('P5DAT03-D03','Box plot A has minimum 10 and maximum 50. Box plot B has minimum 20 and maximum 44. Which comparison is supported directly?','["The two ranges are equal","A has the larger range","B has the larger range","The medians must be equal"]','B','Range(A)=50−10=40 and range(B)=44−20=24, so A has the larger overall range.','У диаграммы размаха A минимум 10 и максимум 50. У B минимум 20 и максимум 44. Какое сравнение подтверждается напрямую?','["Размахи одинаковы","У A размах больше","У B размах больше","Медианы обязательно равны"]','Размах A=50−10=40, размах B=44−20=24, поэтому у A общий размах больше.','A box plotda minimum 10 va maksimum 50. B da minimum 20 va maksimum 44. Qaysi taqqoslash bevosita tasdiqlanadi?','["Oraliqlar teng","A da oraliq kengligi katta","B da oraliq kengligi katta","Medianalar albatta teng"]','A oraliq kengligi 50−10=40, B niki 44−20=24. Demak A da umumiy oraliq kengligi katta.'),
('P5DAT03-R03','A box plot has Q1=18 and lower outlier fence −3 under the 1.5×IQR rule. Enter Q3.','[]','32','−3=18−1.5×IQR, so 1.5×IQR=21 and IQR=14. Hence Q3=18+14=32.','Для диаграммы размаха Q1=18, а нижняя граница выбросов по правилу 1,5×IQR равна −3. Введите Q3.','[]','−3=18−1,5×IQR, поэтому 1,5×IQR=21 и IQR=14. Следовательно, Q3=18+14=32.','Box plot uchun Q1=18, 1.5×IQR qoidasidagi quyi chet qiymat chegarasi −3. Q3 ni kiriting.','[]','−3=18−1.5×IQR, demak 1.5×IQR=21 va IQR=14. Shuning uchun Q3=18+14=32.'),
('P5DAT03-R04','A box plot has Q1=14 and Q3=26. What is the upper outlier fence using the 1.5×IQR rule?','["32","38","44","56"]','C','IQR=26−14=12. The upper fence is 26+1.5×12=26+18=44.','Для диаграммы размаха Q1=14 и Q3=26. Какова верхняя граница выбросов по правилу 1,5×IQR?','["32","38","44","56"]','IQR=26−14=12. Верхняя граница равна 26+1,5×12=26+18=44.','Box plot uchun Q1=14 va Q3=26. 1.5×IQR qoidasidagi yuqori chet qiymat chegarasi qancha?','["32","38","44","56"]','IQR=26−14=12. Yuqori chegara 26+1.5×12=26+18=44.'),
('P5DAT05-D02','A cumulative-frequency graph represents 200 observations. At x=30 the cumulative frequency is 50. If x=30 is exactly a quartile, which quartile is it?','["median","Q3","Q1","none of the quartiles"]','C','50/200=0.25, so x=30 is at the 25th percentile, which is Q1.','График накопленной частоты представляет 200 наблюдений. При x=30 накопленная частота равна 50. Если x=30 точно соответствует квартилю, какому?','["медиане","Q3","Q1","ни одному квартилю"]','50/200=0,25, поэтому x=30 находится на 25-м процентиле, то есть Q1.','Kumulyativ chastota grafigida 200 ta kuzatuv bor. x=30 da kumulyativ chastota 50. Agar x=30 aynan kvartil bo‘lsa, qaysi kvartil?','["mediana","Q3","Q1","hech qaysi kvartil emas"]','50/200=0.25, demak x=30 25-percentilda, ya’ni Q1.'),
('P5DAT05-D03','A cumulative-frequency graph represents 140 observations and has cumulative frequency 47 at x=18. How many observations are greater than 18?','["47","140","187","93"]','D','Cumulative frequency 47 counts observations at most 18. Therefore the number greater than 18 is 140−47=93.','График накопленной частоты представляет 140 наблюдений, а при x=18 накопленная частота равна 47. Сколько наблюдений больше 18?','["47","140","187","93"]','Накопленная частота 47 считает наблюдения не больше 18. Значит, больше 18: 140−47=93.','Kumulyativ chastota grafigida 140 ta kuzatuv bor va x=18 da kumulyativ chastota 47. 18 dan katta nechta kuzatuv bor?','["47","140","187","93"]','47 kumulyativ chastota 18 dan katta bo‘lmagan kuzatuvlarni sanaydi. Demak 18 dan kattalari 140−47=93.'),
('P5DAT05-R03','A cumulative-frequency graph represents 180 observations. At x=52 the cumulative frequency is 117. Enter the percentile number corresponding to x=52.','[]','65','117/180×100=65, so x=52 corresponds to the 65th percentile.','График накопленной частоты представляет 180 наблюдений. При x=52 накопленная частота равна 117. Введите номер процентиля, соответствующий x=52.','[]','117/180×100=65, поэтому x=52 соответствует 65-му процентилю.','Kumulyativ chastota grafigida 180 ta kuzatuv bor. x=52 da kumulyativ chastota 117. x=52 ga mos percentil raqamini kiriting.','[]','117/180×100=65, demak x=52 65-percentilga mos keladi.'),
('P5DAT07-D02','Which transformation leaves the standard deviation unchanged for every data set?','["y=x+7","y=2x","y=x/2","y=3x−1"]','A','Adding the same constant to every value shifts the data but leaves deviations from the mean unchanged. The other transformations change the scale.','Какое преобразование оставляет стандартное отклонение любого набора данных неизменным?','["y=x+7","y=2x","y=x/2","y=3x−1"]','Прибавление одной константы ко всем значениям сдвигает данные, но не меняет отклонения от среднего. Остальные преобразования меняют масштаб.','Qaysi almashtirish har qanday ma’lumotlar to‘plamining standart og‘ishini o‘zgartirmaydi?','["y=x+7","y=2x","y=x/2","y=3x−1"]','Barcha qiymatlarga bir xil doimiy son qo‘shish ma’lumotlarni siljitadi, lekin o‘rtachadan og‘ishlarni o‘zgartirmaydi. Qolgan almashtirishlar masshtabni o‘zgartiradi.'),
('P5DAT07-D03','Every value in a data set is multiplied by −3. What happens to the range, IQR and standard deviation?','["All three are unchanged","All three are multiplied by 3","All three are multiplied by −3","Only the standard deviation changes"]','B','Measures of spread scale by the absolute value of the multiplier. Since |−3|=3, range, IQR and standard deviation are all tripled.','Каждое значение набора данных умножают на −3. Что произойдёт с размахом, IQR и стандартным отклонением?','["Все три не изменятся","Все три умножатся на 3","Все три умножатся на −3","Изменится только стандартное отклонение"]','Меры разброса масштабируются по модулю множителя. Так как |−3|=3, размах, IQR и стандартное отклонение утраиваются.','Ma’lumotlar to‘plamidagi har bir qiymat −3 ga ko‘paytiriladi. Oraliq kengligi, IQR va standart og‘ish bilan nima sodir bo‘ladi?','["Uchovi ham o‘zgarmaydi","Uchovi ham 3 ga ko‘payadi","Uchovi ham −3 ga ko‘payadi","Faqat standart og‘ish o‘zgaradi"]','Tarqoqlik o‘lchovlari ko‘paytiruvchining moduliga ko‘ra masshtablanadi. |−3|=3 bo‘lgani uchun oraliq, IQR va standart og‘ish uch baravar bo‘ladi.'),
('P5DAT07-R03','A data set has IQR 8 and standard deviation 3. Every value is transformed to y=−2x+5. Enter the sum of the new IQR and new standard deviation.','[]','22','Both spread measures are multiplied by |−2|=2. The new IQR is 16 and the new standard deviation is 6, so the required sum is 22.','У набора данных IQR равен 8, стандартное отклонение — 3. Каждое значение преобразуют по формуле y=−2x+5. Введите сумму новых IQR и стандартного отклонения.','[]','Обе меры разброса умножаются на |−2|=2. Новый IQR равен 16, новое стандартное отклонение 6, сумма 22.','Ma’lumotlar to‘plamida IQR 8 va standart og‘ish 3. Har bir qiymat y=−2x+5 ga o‘zgartiriladi. Yangi IQR va yangi standart og‘ish yig‘indisini kiriting.','[]','Har ikkala tarqoqlik o‘lchovi |−2|=2 ga ko‘payadi. Yangi IQR 16, yangi standart og‘ish 6, yig‘indi 22.'),
('P5CNT05-D03','Nine people include A and B. How many 4-person committees include A but exclude B?','["56","70","84","35"]','D','A is fixed in the committee and B is excluded. Choose the remaining 3 members from the other 7 people: 7C3=35.','Среди 9 человек есть A и B. Сколько комитетов из 4 человек включают A, но не включают B?','["56","70","84","35"]','A уже включён, B исключён. Остальных 3 членов выбираем из 7 человек: 7C3=35.','9 kishi orasida A va B bor. A ni o‘z ichiga olib, B ni olmaydigan 4 kishilik qo‘mitalar nechta?','["56","70","84","35"]','A qo‘mitaga kiritilgan, B chiqarilgan. Qolgan 3 a’zoni 7 kishidan tanlaymiz: 7C3=35.'),
('P5CNT05-R03','Ten people include A and B. A 5-person committee must contain both A and B. The chair must then be chosen from the other three committee members. Enter the number of possible outcomes.','[]','168','Choose the other 3 committee members from the remaining 8: 8C3=56. Then choose the chair from those 3 members: 56×3=168.','Среди 10 человек есть A и B. Комитет из 5 человек должен содержать обоих A и B. Затем председателя выбирают только из остальных трёх членов комитета. Введите число возможных исходов.','[]','Остальных 3 членов комитета выбираем из 8: 8C3=56. Председателя выбираем из этих трёх: 56×3=168.','10 kishi orasida A va B bor. 5 kishilik qo‘mita A va B ning ikkalasini ham o‘z ichiga olishi kerak. So‘ng rais qolgan uch a’zodan tanlanadi. Mumkin natijalar sonini kiriting.','[]','Qolgan 3 a’zoni 8 kishidan tanlaymiz: 8C3=56. Rais shu 3 a’zodan tanlanadi: 56×3=168.'),
('P5PRO02-D02','A bag contains 7 red and 5 blue counters. Three counters are chosen without replacement. What is the probability that all three chosen counters have the same colour?','["9/44","7/44","5/22","15/44"]','A','Favourable selections are 7C3+5C3=35+10=45. Total selections are 12C3=220. Thus the probability is 45/220=9/44.','В мешке 7 красных и 5 синих фишек. Без возвращения выбирают 3 фишки. Какова вероятность того, что все три выбранные фишки одного цвета?','["9/44","7/44","5/22","15/44"]','Благоприятных выборов: 7C3+5C3=35+10=45. Всего 12C3=220. Вероятность 45/220=9/44.','Qopda 7 qizil va 5 ko‘k jeton bor. Qaytarmasdan 3 ta jeton tanlanadi. Uchala tanlangan jeton bir xil rangda bo‘lish ehtimoli qancha?','["9/44","7/44","5/22","15/44"]','Qulay tanlovlar 7C3+5C3=35+10=45. Jami 12C3=220. Ehtimol 45/220=9/44.'),
('P5PRO02-D03','From 6 men and 4 women, 3 people are chosen at random. What is the probability that exactly one woman is chosen?','["1/3","1/2","2/3","3/5"]','B','Favourable selections are 4C1×6C2=4×15=60. Total selections are 10C3=120. Probability=60/120=1/2.','Из 6 мужчин и 4 женщин случайно выбирают 3 человек. Какова вероятность выбрать ровно одну женщину?','["1/3","1/2","2/3","3/5"]','Благоприятных выборов: 4C1×6C2=4×15=60. Всего 10C3=120. Вероятность 60/120=1/2.','6 erkak va 4 ayoldan tasodifiy 3 kishi tanlanadi. Aynan bitta ayol tanlash ehtimoli qancha?','["1/3","1/2","2/3","3/5"]','Qulay tanlovlar 4C1×6C2=4×15=60. Jami 10C3=120. Ehtimol 60/120=1/2.'),
('P5PRO02-R04','From 6 girls and 4 boys, 3 students are chosen at random. What is the probability that exactly 2 boys are chosen?','["1/6","1/5","3/10","1/2"]','C','Favourable selections are 4C2×6C1=6×6=36. Total selections are 10C3=120. Probability=36/120=3/10.','Из 6 девочек и 4 мальчиков случайно выбирают 3 учеников. Какова вероятность выбрать ровно 2 мальчиков?','["1/6","1/5","3/10","1/2"]','Благоприятных выборов: 4C2×6C1=6×6=36. Всего 10C3=120. Вероятность 36/120=3/10.','6 qiz va 4 o‘g‘ildan tasodifiy 3 o‘quvchi tanlanadi. Aynan 2 o‘g‘il tanlash ehtimoli qancha?','["1/6","1/5","3/10","1/2"]','Qulay tanlovlar 4C2×6C1=6×6=36. Jami 10C3=120. Ehtimol 36/120=3/10.'),
('P5PRO04-D02','P(B)=0.4 and P(A|B)=0.7. Find P(A∩B).','["0.12","0.35","0.28","0.70"]','C','P(A∩B)=P(B)P(A|B)=0.4×0.7=0.28.','P(B)=0,4 и P(A|B)=0,7. Найдите P(A∩B).','["0,12","0,35","0,28","0,70"]','P(A∩B)=P(B)P(A|B)=0,4×0,7=0,28.','P(B)=0.4 va P(A|B)=0.7. P(A∩B) ni toping.','["0.12","0.35","0.28","0.70"]','P(A∩B)=P(B)P(A|B)=0.4×0.7=0.28.'),
('P5PRO04-D03','P(A)=0.5, P(B)=0.4 and P(B|A)=0.4. Which statement is correct?','["A and B are mutually exclusive","P(A∩B)=0","A and B are not independent","A and B are independent"]','D','P(B|A)=P(B)=0.4, so knowing that A occurred does not change the probability of B. Thus A and B are independent.','P(A)=0,5, P(B)=0,4 и P(B|A)=0,4. Какое утверждение верно?','["A и B взаимоисключающие","P(A∩B)=0","A и B не независимы","A и B независимы"]','P(B|A)=P(B)=0,4, поэтому наступление A не меняет вероятность B. Значит, A и B независимы.','P(A)=0.5, P(B)=0.4 va P(B|A)=0.4. Qaysi fikr to‘g‘ri?','["A va B o‘zaro istisno","P(A∩B)=0","A va B mustaqil emas","A va B mustaqil"]','P(B|A)=P(B)=0.4, demak A sodir bo‘lishi B ehtimolini o‘zgartirmaydi. Shuning uchun A va B mustaqil.'),
('P5PRO04-R03','Events A and B are independent. P(A)=0.3 and P(A∪B)=0.58. Enter P(B).','[]','0.4','For independent events, P(A∪B)=P(A)+P(B)−P(A)P(B). Let P(B)=p: 0.58=0.3+p−0.3p=0.3+0.7p, so p=0.4.','События A и B независимы. P(A)=0,3 и P(A∪B)=0,58. Введите P(B).','[]','Для независимых событий P(A∪B)=P(A)+P(B)−P(A)P(B). Пусть P(B)=p: 0,58=0,3+p−0,3p=0,3+0,7p, поэтому p=0,4.','A va B hodisalar mustaqil. P(A)=0.3 va P(A∪B)=0.58. P(B) ni kiriting.','[]','Mustaqil hodisalar uchun P(A∪B)=P(A)+P(B)−P(A)P(B). P(B)=p desak: 0.58=0.3+p−0.3p=0.3+0.7p, demak p=0.4.'),
('P5PRO04-R04','P(A)=0.4, P(B)=0.25 and P(A∪B)=0.55. Which statement is correct?','["A and B are mutually exclusive","A and B are independent","P(A∩B)=0.15","There is not enough information to test independence"]','B','P(A∩B)=0.4+0.25−0.55=0.10. Also P(A)P(B)=0.4×0.25=0.10, so A and B are independent.','P(A)=0,4, P(B)=0,25 и P(A∪B)=0,55. Какое утверждение верно?','["A и B взаимоисключающие","A и B независимы","P(A∩B)=0,15","Недостаточно данных для проверки независимости"]','P(A∩B)=0,4+0,25−0,55=0,10. Также P(A)P(B)=0,4×0,25=0,10, поэтому A и B независимы.','P(A)=0.4, P(B)=0.25 va P(A∪B)=0.55. Qaysi fikr to‘g‘ri?','["A va B o‘zaro istisno","A va B mustaqil","P(A∩B)=0.15","Mustaqillikni tekshirish uchun ma’lumot yetarli emas"]','P(A∩B)=0.4+0.25−0.55=0.10. Shuningdek P(A)P(B)=0.4×0.25=0.10, demak A va B mustaqil.')
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
  on m.content_version_id in (4811,4812) and m.content_key=f.content_key
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
  and m.content_version_id in (4811,4812)
  and m.content_key in ('P1CIR02-D02','P1CIR02-D03','P1COO04-D02','P1COO04-D03','P1FUN03-D02','P1FUN04-D02','P1FUN04-D03','P1FUN05-D02','P1FUN05-D03','P1FUN05-R03','P1FUN05-R04','P1FUN05-M02','P1QUA05-D02','P1QUA05-D03','P1QUA05-R03','P1QUA06-D02','P1QUA06-D03','P1QUA06-R04','P1QUA04-R04','P5DAT03-D02','P5DAT03-D03','P5DAT03-R03','P5DAT03-R04','P5DAT05-D02','P5DAT05-D03','P5DAT05-R03','P5DAT07-D02','P5DAT07-D03','P5DAT07-R03','P5CNT05-D03','P5CNT05-R03','P5PRO02-D02','P5PRO02-D03','P5PRO02-R04','P5PRO04-D02','P5PRO04-D03','P5PRO04-R03','P5PRO04-R04');

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int;
begin
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id in (4811,4812)
    and (
      nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
      or (q.qtype='mcq' and (
        q.correct_answer not in ('A','B','C','D')
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_en::jsonb) z(v))<>4
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_ru::jsonb) z(v))<>4
        or (select count(distinct v) from jsonb_array_elements_text(q.options_text_uz::jsonb) z(v))<>4
      ))
      or (q.qtype='input' and (
        q.options_text_en::jsonb<>'[]'::jsonb
        or q.options_text_ru::jsonb<>'[]'::jsonb
        or q.options_text_uz::jsonb<>'[]'::jsonb
      ))
    );
  if v_bad<>0 then raise exception 'aw09_12 annual reserve QA: payload/trilingual rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id in (4811,4812)
    and md5(concat_ws(chr(31),
      q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
      coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
      coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
      coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5;
  if v_bad<>0 then raise exception 'aw09_12 annual reserve QA: frozen snapshot mismatch rows=%',v_bad; end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id not in (4811,4812)
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4811,4812)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw09_12 annual reserve QA: exact published stem duplicate'; end if;

  select count(*) filter(where q.correct_answer='A'),
         count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),
         count(*) filter(where q.correct_answer='D')
  into v_a,v_b,v_c,v_d
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4811 and m.reserve_role='diagnostic';
  if (v_a,v_b,v_c,v_d)<>(4,4,4,4) then
    raise exception 'aw09_12 annual reserve QA: P1 diagnostic balance drift A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  end if;

  select count(*) filter(where q.correct_answer='A'),
         count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),
         count(*) filter(where q.correct_answer='D')
  into v_a,v_b,v_c,v_d
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4812 and m.reserve_role='diagnostic';
  if (v_a,v_b,v_c,v_d)<>(3,3,3,3) then
    raise exception 'aw09_12 annual reserve QA: P5 diagnostic balance drift A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id in (4811,4812))
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id in (4811,4812))
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id in (4811,4812))
  then raise exception 'aw09_12 annual reserve QA: history appeared during correction'; end if;

  if (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id
      where a.content_version_id in (4811,4812) and ai.is_holdout)<>70
  then raise exception 'aw09_12 annual reserve QA: holdout isolation drift'; end if;
end
$postcheck$;

commit;
