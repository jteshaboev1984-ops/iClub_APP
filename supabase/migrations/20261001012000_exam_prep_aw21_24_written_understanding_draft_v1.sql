-- AW21-24 written-understanding checks draft v1.
-- One trilingual understanding check per new written learning task.
begin;
set local lock_timeout='3s';
set local statement_timeout='60s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_written_tasks
      where id between 15664 and 15681 and content_version_id in (4821,4822) and lifecycle_state='draft')<>18
  then raise exception 'aw21_24_written_checks expected 18 draft written tasks'; end if;

  if exists(select 1 from private.exam_prep_written_understanding_checks
            where id between 8964 and 8981 and written_task_id not between 15664 and 15681)
  then raise exception 'aw21_24_written_checks reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_written_understanding_checks(
 id,written_task_id,check_order,check_version,check_kind,
 prompt_en,prompt_ru,prompt_uz,options_en,options_ru,options_uz,correct_index,
 rationale_en,rationale_ru,rationale_uz,lifecycle_state,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(8964,15664,1,'aw22-v1','mcq',
'Why does substituting the line equation into the circle equation find the intersection points?','Почему подстановка уравнения прямой в уравнение окружности позволяет найти точки пересечения?','Nega chiziq tenglamasini aylana tenglamasiga qo‘yish kesishish nuqtalarini topishga yordam beradi?',
'["The resulting equation contains coordinates that must satisfy both original equations","It turns every line into a tangent","It makes the circle radius equal to zero","It guarantees the two x-coordinates are equal"]'::jsonb,'["Полученное уравнение содержит координаты, которые должны удовлетворять обоим исходным уравнениям","Это превращает любую прямую в касательную","Это делает радиус окружности равным нулю","Это гарантирует равенство двух x-координат"]'::jsonb,'["Hosil bo‘lgan tenglamadagi koordinatalar ikkala asl tenglamani ham qanoatlantirishi kerak","Bu har qanday chiziqni urinmaga aylantiradi","Bu aylana radiusini nolga teng qiladi","Bu ikkala x-koordinata teng bo‘lishini kafolatlaydi"]'::jsonb,
0,
'An intersection point lies on both objects, so its coordinates must satisfy both equations simultaneously.','Точка пересечения лежит на обоих объектах, поэтому её координаты одновременно удовлетворяют обоим уравнениям.','Kesishish nuqtasi ikkala obyektga ham tegishli, shuning uchun uning koordinatalari ikkala tenglamani bir vaqtda qanoatlantiradi.',
'draft','pending','pending','pending'),
(8965,15665,1,'aw22-v1','mcq',
'Why does a zero discriminant represent tangency after a line is substituted into a circle equation?','Почему нулевой дискриминант означает касание после подстановки прямой в уравнение окружности?','Nega chiziq aylana tenglamasiga qo‘yilgandan keyin nol diskriminant urinmani bildiradi?',
'["Because a tangent has no real contact point","Because tangency gives one repeated intersection root","Because the circle becomes a straight line","Because every tangent has gradient zero"]'::jsonb,'["Потому что у касательной нет действительной точки касания","Потому что при касании получается один повторный корень пересечения","Потому что окружность превращается в прямую","Потому что у любой касательной градиент равен нулю"]'::jsonb,'["Chunki urinmada haqiqiy tegish nuqtasi yo‘q","Chunki urinmada bitta takroriy kesishish ildizi hosil bo‘ladi","Chunki aylana to‘g‘ri chiziqqa aylanadi","Chunki har bir urinmaning gradienti nol"]'::jsonb,
1,
'A tangent meets the circle at exactly one point, so the intersection quadratic has a repeated root and discriminant zero.','Касательная имеет с окружностью ровно одну точку, поэтому квадратное уравнение пересечения имеет повторный корень и дискриминант 0.','Urinma aylana bilan aynan bitta nuqtada tutashadi, shuning uchun kesishish kvadrat tenglamasi takroriy ildizga va nol diskriminantga ega.',
'draft','pending','pending','pending'),
(8966,15666,1,'aw22-v1','mcq',
'Why does the sign of f′(x) determine where f is increasing or decreasing?','Почему знак f′(x) определяет интервалы возрастания и убывания f?','Nega f′(x) ning ishorasi f qayerda o‘sishi yoki kamayishini aniqlaydi?',
'["Because f′(x) is always equal to f(x)","Because f′(x) gives the y-intercept","Because a positive derivative means locally rising and a negative derivative means locally falling","Because the derivative is positive only at stationary points"]'::jsonb,'["Потому что f′(x) всегда равно f(x)","Потому что f′(x) даёт пересечение с осью y","Потому что положительная производная означает локальный рост, а отрицательная — локальное убывание","Потому что производная положительна только в стационарных точках"]'::jsonb,'["Chunki f′(x) har doim f(x) ga teng","Chunki f′(x) y-o‘q bilan kesishishni beradi","Chunki musbat hosila lokal o‘sishni, manfiy hosila esa lokal kamayishni bildiradi","Chunki hosila faqat statsionar nuqtalarda musbat"]'::jsonb,
2,
'The derivative is the local rate of change, so its sign tells the local direction of change of the function.','Производная — локальная скорость изменения, поэтому её знак показывает направление изменения функции.','Hosila lokal o‘zgarish tezligi bo‘lib, uning ishorasi funksiyaning o‘zgarish yo‘nalishini ko‘rsatadi.',
'draft','pending','pending','pending'),
(8967,15667,1,'aw22-v1','mcq',
'Why is dV/dt=(dV/dr)(dr/dt) in a connected-rates problem where V depends on r and r depends on t?','Почему в задаче на связанные скорости dV/dt=(dV/dr)(dr/dt), если V зависит от r, а r — от t?','V r ga, r esa t ga bog‘liq bo‘lgan connected-rates masalasida nega dV/dt=(dV/dr)(dr/dt)?',
'["Because volume and radius always change at the same numerical rate","Because time can be cancelled from every formula without differentiation","Because dV/dr must always equal 1","Because the chain rule links the change of V with r to the change of r with t"]'::jsonb,'["Потому что объём и радиус всегда меняются с одинаковой численной скоростью","Потому что время можно сократить в любой формуле без дифференцирования","Потому что dV/dr всегда равно 1","Потому что правило цепочки связывает изменение V по r с изменением r по t"]'::jsonb,'["Chunki hajm va radius har doim bir xil sonli tezlikda o‘zgaradi","Chunki vaqtni har qanday formuladan differensiallamasdan qisqartirish mumkin","Chunki dV/dr har doim 1 ga teng","Chunki zanjir qoidasi V ning r bo‘yicha o‘zgarishini r ning t bo‘yicha o‘zgarishi bilan bog‘laydi"]'::jsonb,
3,
'This is the chain rule for the composition V(r(t)); it preserves both the rate direction and the units.','Это правило цепочки для композиции V(r(t)); оно сохраняет направление скорости и единицы измерения.','Bu V(r(t)) kompozitsiyasi uchun zanjir qoidasi bo‘lib, tezlik yo‘nalishi va birliklarni saqlaydi.',
'draft','pending','pending','pending'),
(8968,15668,1,'aw22-v1','mcq',
'Which evidence is sufficient to confirm that a stationary point is a local maximum?','Какое доказательство достаточно, чтобы подтвердить, что стационарная точка является локальным максимумом?','Statsionar nuqta lokal maksimum ekanini tasdiqlash uchun qaysi dalil yetarli?',
'["At the stationary point f′=0 and f″<0, or f′ changes from positive to negative","The function value is positive","The x-coordinate is positive","The graph crosses the y-axis there"]'::jsonb,'["В стационарной точке f′=0 и f″<0, либо f′ меняет знак с плюса на минус","Значение функции положительно","x-координата положительна","График пересекает там ось y"]'::jsonb,'["Statsionar nuqtada f′=0 va f″<0, yoki f′ musbatdan manfiyga o‘zgaradi","Funksiya qiymati musbat","x-koordinata musbat","Grafik shu yerda y-o‘qni kesadi"]'::jsonb,
0,
'A maximum requires stationary evidence plus a change from increasing to decreasing; a negative second derivative is a standard sufficient test.','Максимум требует стационарности и перехода от возрастания к убыванию; отрицательная вторая производная — стандартный достаточный тест.','Maksimum statsionar holat va o‘sishdan kamayishga o‘tishni talab qiladi; manfiy ikkinchi hosila standart yetarli testdir.',
'draft','pending','pending','pending'),
(8969,15669,1,'aw22-v1','mcq',
'Why must an antiderivative of (ax+b)^n include division by the inner coefficient a?','Почему при интегрировании (ax+b)^n нужно делить на внутренний коэффициент a?','Nega (ax+b)^n ni integrallashda ichki a koeffitsientga bo‘lish kerak?',
'["Because integration always divides by every coefficient twice","Because differentiating the proposed antiderivative would otherwise introduce an extra factor a","Because the exponent must remain unchanged","Because a is the constant of integration"]'::jsonb,'["Потому что интегрирование всегда дважды делит на каждый коэффициент","Потому что при дифференцировании предполагаемой первообразной иначе появится лишний множитель a","Потому что показатель степени должен остаться неизменным","Потому что a — константа интегрирования"]'::jsonb,'["Chunki integrallash har bir koeffitsientga ikki marta bo‘ladi","Chunki taklif qilingan boshlang‘ich funksiyani differensiallaganda aks holda ortiqcha a ko‘paytuvchisi paydo bo‘ladi","Chunki daraja o‘zgarmasligi kerak","Chunki a integrallash doimiysi"]'::jsonb,
1,
'Reverse chain rule must compensate for d(ax+b)/dx=a, so division by a removes the extra factor on differentiation.','Обратное правило цепочки должно компенсировать d(ax+b)/dx=a, поэтому деление на a убирает лишний множитель при дифференцировании.','Teskari zanjir qoidasi d(ax+b)/dx=a ni kompensatsiya qiladi, shuning uchun a ga bo‘lish differensiallashdagi ortiqcha ko‘paytuvchini yo‘qotadi.',
'draft','pending','pending','pending'),
(8970,15670,1,'aw22-v1','mcq',
'Why is a known point on the curve needed after integrating dy/dx?','Зачем после интегрирования dy/dx нужна известная точка кривой?','dy/dx ni integrallagandan keyin nega egri chiziqdagi ma’lum nuqta kerak?',
'["To determine the derivative again","To change a definite integral into an indefinite one","To determine the unknown constant of integration C","To force the curve through the origin"]'::jsonb,'["Чтобы снова найти производную","Чтобы превратить определённый интеграл в неопределённый","Чтобы определить неизвестную константу интегрирования C","Чтобы заставить кривую проходить через начало координат"]'::jsonb,'["Hosilani yana topish uchun","Aniq integralni noaniq integralga aylantirish uchun","Noma’lum integrallash doimiysi C ni aniqlash uchun","Egri chiziqni koordinata boshidan o‘tkazish uchun"]'::jsonb,
2,
'Integrating a derivative gives a family of curves differing by C; one known point selects the required member of that family.','Интегрирование производной даёт семейство кривых, различающихся C; одна известная точка выбирает нужную кривую.','Hosilani integrallash C bilan farqlanadigan egri chiziqlar oilasini beradi; bitta ma’lum nuqta kerakli egri chiziqni tanlaydi.',
'draft','pending','pending','pending'),
(8971,15671,1,'aw22-v1','mcq',
'What is the correct evaluation rule for a definite integral ∫ from a to b of f(x) dx after finding an antiderivative F?','Как правильно вычислить определённый интеграл ∫ от a до b f(x) dx после нахождения первообразной F?','f(x) ning a dan b gacha aniq integralini F boshlang‘ich funksiya topilgach qanday to‘g‘ri hisoblash kerak?',
'["F(a)+F(b)","F(a)−F(b)","F(a)F(b)","F(b)−F(a)"]'::jsonb,'["F(a)+F(b)","F(a)−F(b)","F(a)F(b)","F(b)−F(a)"]'::jsonb,'["F(a)+F(b)","F(a)−F(b)","F(a)F(b)","F(b)−F(a)"]'::jsonb,
3,
'The Fundamental Theorem of Calculus gives the definite integral as the antiderivative at the upper limit minus its value at the lower limit.','По основной теореме анализа определённый интеграл равен значению первообразной на верхнем пределе минус её значение на нижнем.','Analizning asosiy teoremasiga ko‘ra aniq integral boshlang‘ich funksiyaning yuqori chegaradagi qiymatidan pastki chegaradagi qiymatini ayirishga teng.',
'draft','pending','pending','pending'),
(8972,15672,1,'aw22-v1','mcq',
'Why must a total-area integral be split where the curve crosses the x-axis?','Почему при нахождении полной площади интеграл нужно разбивать в точках пересечения графика с осью x?','Umumiy yuzani topishda nega grafik x-o‘qini kesgan nuqtalarda integralni bo‘lish kerak?',
'["Because signed integrals below the axis are negative, while geometric area must be counted positively","Because integration is impossible across a root","Because every root makes the antiderivative discontinuous","Because the x-axis changes the units of area"]'::jsonb,'["Потому что определённый интеграл ниже оси имеет отрицательный знак, а геометрическая площадь должна считаться положительно","Потому что через корень интегрировать невозможно","Потому что каждый корень делает первообразную разрывной","Потому что ось x меняет единицы площади"]'::jsonb,'["Chunki x-o‘qidan pastdagi aniq integral manfiy, geometrik yuza esa musbat hisoblanishi kerak","Chunki ildiz orqali integrallash mumkin emas","Chunki har bir ildiz boshlang‘ich funksiyani uzluksiz emas qiladi","Chunki x-o‘qi yuza birliklarini o‘zgartiradi"]'::jsonb,
0,
'A definite integral is signed. Splitting at sign changes lets each geometric piece be converted to positive area before adding.','Определённый интеграл имеет знак. Разбиение в точках смены знака позволяет каждую геометрическую часть посчитать положительно.','Aniq integral ishorali. Ishora o‘zgargan joylarda bo‘lish har bir geometrik qismni musbat yuza sifatida qo‘shishga imkon beradi.',
'draft','pending','pending','pending'),
(8973,15673,1,'aw22-v1','mcq',
'Why does volume of revolution about the x-axis use π∫y² dx?','Почему объём вращения вокруг оси x вычисляется как π∫y² dx?','Nega x-o‘qi atrofidagi aylanish hajmi π∫y² dx bilan hisoblanadi?',
'["Because the circumference of each slice is πy²","Because each perpendicular slice is a disk with area πy²","Because y² is always the derivative of x","Because every rotated region is a sphere"]'::jsonb,'["Потому что длина окружности каждого сечения равна πy²","Потому что каждое перпендикулярное сечение — диск площади πy²","Потому что y² всегда является производной x","Потому что любая вращаемая область становится сферой"]'::jsonb,'["Chunki har bir kesim aylanasining uzunligi πy²","Chunki har bir perpendikulyar kesim yuzi πy² bo‘lgan disk","Chunki y² har doim x ning hosilasi","Chunki har bir aylantirilgan soha sferaga aylanadi"]'::jsonb,
1,
'At position x, rotating the vertical radius y about the x-axis creates a disk of cross-sectional area πy².','В точке x вращение вертикального радиуса y вокруг оси x создаёт диск площадью сечения πy².','x nuqtada vertikal y radiusni x-o‘qi atrofida aylantirish kesim yuzi πy² bo‘lgan disk hosil qiladi.',
'draft','pending','pending','pending'),
(8974,15674,1,'aw22-v1','mcq',
'What do median and IQR describe when comparing two datasets?','Что описывают медиана и IQR при сравнении двух наборов данных?','Ikki ma’lumot to‘plamini taqqoslashda mediana va IQR nimani tavsiflaydi?',
'["Both describe only spread","Median describes spread and IQR describes sample size","Median describes location and IQR describes spread","Both describe only location"]'::jsonb,'["Оба показателя описывают только разброс","Медиана описывает разброс, а IQR — размер выборки","Медиана описывает положение, а IQR — разброс","Оба показателя описывают только положение"]'::jsonb,'["Ikkalasi ham faqat tarqalishni tavsiflaydi","Mediana tarqalishni, IQR esa tanlama hajmini tavsiflaydi","Mediana markazni, IQR esa tarqalishni tavsiflaydi","Ikkalasi ham faqat markazni tavsiflaydi"]'::jsonb,
2,
'Median is a location statistic, while IQR measures the spread of the middle 50% of the data.','Медиана — показатель положения, а IQR измеряет разброс центральных 50% данных.','Mediana markaz ko‘rsatkichi, IQR esa ma’lumotlarning o‘rta 50% qismi tarqalishini o‘lchaydi.',
'draft','pending','pending','pending'),
(8975,15675,1,'aw22-v1','mcq',
'Using the course variance convention, why is standard deviation found after calculating Σx²/n − mean²?','Почему при используемой формуле дисперсии стандартное отклонение находят после вычисления Σx²/n − mean²?','Kursdagi dispersiya formulasida nega standart og‘ish Σx²/n − mean² hisoblangandan keyin topiladi?',
'["Because standard deviation equals the variance squared","Because the mean is always the standard deviation","Because Σx²/n is already the standard deviation","Because standard deviation is the positive square root of the variance"]'::jsonb,'["Потому что стандартное отклонение равно квадрату дисперсии","Потому что среднее всегда равно стандартному отклонению","Потому что Σx²/n уже является стандартным отклонением","Потому что стандартное отклонение — положительный квадратный корень из дисперсии"]'::jsonb,'["Chunki standart og‘ish dispersiyaning kvadratiga teng","Chunki o‘rtacha har doim standart og‘ishga teng","Chunki Σx²/n allaqachon standart og‘ish","Chunki standart og‘ish dispersiyaning musbat kvadrat ildizidir"]'::jsonb,
3,
'The expression gives the variance. Standard deviation is defined as its non-negative square root.','Это выражение даёт дисперсию. Стандартное отклонение определяется как её неотрицательный квадратный корень.','Bu ifoda dispersiyani beradi. Standart og‘ish uning manfiy bo‘lmagan kvadrat ildizi sifatida aniqlanadi.',
'draft','pending','pending','pending'),
(8976,15676,1,'aw22-v1','mcq',
'If y=(x−a)/b, why can the mean of x be recovered as a+b(mean of y)?','Если y=(x−a)/b, почему среднее x можно восстановить как a+b·(среднее y)?','Agar y=(x−a)/b bo‘lsa, nega x ning o‘rtachasini a+b·(y ning o‘rtachasi) sifatida tiklash mumkin?',
'["Because x=a+by is a linear transformation, and means transform linearly","Because coding changes only the number of observations","Because the mean of y must be zero","Because b must equal the sample size"]'::jsonb,'["Потому что x=a+by — линейное преобразование, и среднее преобразуется линейно","Потому что кодирование меняет только число наблюдений","Потому что среднее y обязательно равно нулю","Потому что b должно равняться размеру выборки"]'::jsonb,'["Chunki x=a+by chiziqli o‘zgarish va o‘rtachalar ham chiziqli o‘zgaradi","Chunki kodlash faqat kuzatuvlar sonini o‘zgartiradi","Chunki y ning o‘rtachasi albatta nol","Chunki b tanlama hajmiga teng bo‘lishi kerak"]'::jsonb,
0,
'Taking the average of x=a+by gives mean(x)=a+b·mean(y), since a and b are constants.','x=a+by tenglamasining o‘rtachasini olsak, a va b o‘zgarmas bo‘lgani uchun mean(x)=a+b·mean(y).','x=a+by tenglamasining o‘rtachasini olganda a va b o‘zgarmas bo‘lgani uchun mean(x)=a+b·mean(y) bo‘ladi.',
'draft','pending','pending','pending'),
(8977,15677,1,'aw22-v1','mcq',
'For X~N(μ,σ²), which standardisation formula is correct?','Для X~N(μ,σ²) какая формула стандартизации верна?','X~N(μ,σ²) uchun qaysi standartlash formulasi to‘g‘ri?',
'["z=(x−μ)/σ²","z=(x−μ)/σ","z=(x+μ)/σ","z=σ(x−μ)"]'::jsonb,'["z=(x−μ)/σ²","z=(x−μ)/σ","z=(x+μ)/σ","z=σ(x−μ)"]'::jsonb,'["z=(x−μ)/σ²","z=(x−μ)/σ","z=(x+μ)/σ","z=σ(x−μ)"]'::jsonb,
1,
'Standardisation measures displacement from the mean in units of standard deviation, not variance.','Стандартизация измеряет отклонение от среднего в единицах стандартного отклонения, а не дисперсии.','Standartlash o‘rtachadan og‘ishni dispersiya emas, standart og‘ish birliklarida o‘lchaydi.',
'draft','pending','pending','pending'),
(8978,15678,1,'aw22-v1','mcq',
'How is an upper-tail normal probability P(Z>z) found from the cumulative value Φ(z)=P(Z<z)?','Как найти верхнюю хвостовую вероятность P(Z>z) по накопленному значению Φ(z)=P(Z<z)?','Yuqori dum ehtimoli P(Z>z) ni cumulative Φ(z)=P(Z<z) dan qanday topiladi?',
'["Use Φ(z) directly","Multiply Φ(z) by z","Use 1−Φ(z)","Use Φ(−z)+1"]'::jsonb,'["Использовать Φ(z) напрямую","Умножить Φ(z) на z","Использовать 1−Φ(z)","Использовать Φ(−z)+1"]'::jsonb,'["Φ(z) ni bevosita ishlatish","Φ(z) ni z ga ko‘paytirish","1−Φ(z) ni ishlatish","Φ(−z)+1 ni ishlatish"]'::jsonb,
2,
'The total area is 1, so the area to the right of z is the complement of the cumulative area to the left.','Общая площадь равна 1, поэтому площадь справа от z — дополнение к накопленной площади слева.','Umumiy yuza 1 ga teng, shuning uchun z ning o‘ngidagi yuza chapdagi cumulative yuzaning to‘ldiruvchisidir.',
'draft','pending','pending','pending'),
(8979,15679,1,'aw22-v1','mcq',
'What does an inverse-normal calculation do?','Что делает вычисление inverse normal?','Inverse normal hisobi nima qiladi?',
'["It squares a normal probability","It converts every normal variable into a binomial one","It finds the variance from the sample size only","It finds the z- or x-value associated with a specified cumulative probability"]'::jsonb,'["Оно возводит нормальную вероятность в квадрат","Оно превращает любую нормальную величину в биномиальную","Оно находит дисперсию только по размеру выборки","Оно находит z- или x-значение, соответствующее заданной накопленной вероятности"]'::jsonb,'["U normal ehtimolni kvadratga oshiradi","U har bir normal o‘zgaruvchini binomialga aylantiradi","U dispersiyani faqat tanlama hajmidan topadi","U berilgan cumulative probability ga mos z yoki x qiymatini topadi"]'::jsonb,
3,
'Inverse normal reverses the cumulative-probability map: probability in, corresponding quantile out.','Inverse normal обращает накопленное распределение: на входе вероятность, на выходе соответствующий квантиль.','Inverse normal cumulative probability mosligini teskarilaydi: ehtimol kiradi, unga mos kvantil chiqadi.',
'draft','pending','pending','pending'),
(8980,15680,1,'aw22-v1','mcq',
'Why are two independent probability conditions useful when both μ and σ are unknown?','Почему две независимые вероятностные условия полезны, когда неизвестны и μ, и σ?','μ va σ ikkalasi noma’lum bo‘lganda nega ikkita mustaqil ehtimol sharti kerak?',
'["Each condition gives an equation involving μ and σ, so two equations can determine the two unknowns","One condition always gives both parameters immediately","The two conditions make σ equal to 1","The normal distribution has no parameters until two probabilities are given"]'::jsonb,'["Каждое условие даёт уравнение с μ и σ, поэтому два уравнения могут определить две неизвестные","Одно условие всегда сразу даёт оба параметра","Два условия делают σ равным 1","У нормального распределения нет параметров, пока не заданы две вероятности"]'::jsonb,'["Har bir shart μ va σ ishtirokidagi tenglama beradi, shuning uchun ikkita tenglama ikki noma’lumni aniqlashi mumkin","Bitta shart har doim ikkala parametrni darhol beradi","Ikki shart σ ni 1 ga teng qiladi","Ikki ehtimol berilmaguncha normal taqsimotning parametrlari yo‘q"]'::jsonb,
0,
'After converting each cumulative probability to a z-value, each condition becomes an equation in the two unknown parameters.','После преобразования каждой накопленной вероятности в z каждое условие становится уравнением относительно двух неизвестных параметров.','Har bir cumulative probability z qiymatiga aylantirilgach, har bir shart ikki noma’lum parametr uchun tenglamaga aylanadi.',
'draft','pending','pending','pending'),
(8981,15681,1,'aw22-v1','mcq',
'For a continuity correction, which normal boundary corresponds to the binomial event X≥35?','При continuity correction какая нормальная граница соответствует биномиальному событию X≥35?','Continuity correction da binomial X≥35 hodisasiga qaysi normal chegara mos?',
'["35.5","34.5","35.0","34.0"]'::jsonb,'["35,5","34,5","35,0","34,0"]'::jsonb,'["35.5","34.5","35.0","34.0"]'::jsonb,
1,
'The discrete event begins at the bar centred on 35, whose lower edge is 34.5, so the continuous approximation uses Y>34.5.','Дискретное событие начинается со столбца с центром 35, его нижняя граница равна 34,5, поэтому непрерывная аппроксимация использует Y>34,5.','Diskret hodisa markazi 35 bo‘lgan ustundan boshlanadi, uning pastki chegarasi 34.5, shuning uchun uzluksiz yaqinlashuv Y>34.5 ni ishlatadi.',
'draft','pending','pending','pending')
on conflict(id) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_written_understanding_checks
      where id between 8964 and 8981 and written_task_id between 15664 and 15681
        and lifecycle_state='draft' and qa_math_status='pending' and qa_language_status='pending' and qa_technical_status='pending')<>18
  then raise exception 'aw21_24_written_checks cardinality/state mismatch'; end if;

  select count(*) into v_bad from private.exam_prep_written_understanding_checks c
  where c.id between 8964 and 8981 and (
    jsonb_array_length(c.options_en)<>4 or jsonb_array_length(c.options_ru)<>4 or jsonb_array_length(c.options_uz)<>4
    or c.correct_index not between 0 and 3
    or nullif(btrim(c.prompt_en),'') is null or nullif(btrim(c.prompt_ru),'') is null or nullif(btrim(c.prompt_uz),'') is null
    or nullif(btrim(c.rationale_en),'') is null or nullif(btrim(c.rationale_ru),'') is null or nullif(btrim(c.rationale_uz),'') is null
  );
  if v_bad<>0 then raise exception 'aw21_24_written_checks structural/trilingual invalid=%',v_bad; end if;

  if (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=0)<>5
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=1)<>5
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=2)<>4
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=3)<>4
  then raise exception 'aw21_24_written_checks answer-position balance drift'; end if;
end
$postcheck$;

commit;
