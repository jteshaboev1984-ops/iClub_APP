-- P3-02 full governed theory source pack for all 81 internal P1/P5 skills.
-- Source alignment: canonical Academic Syllabus Source Map plus the mapped Complete coursebooks.
-- All runtime text is original iClub summary text; no copied Cambridge question/mark-scheme wording.
-- Additive/content-only. AI capability flags and academic state are unchanged.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

with skill_titles(skill_code,area_key,title_ru,title_uz,title_en) as (
  values
    ('P1-QUA-01','P1-1.1','Выделение полного квадрата','To‘liq kvadratga keltirish','Completing the square'),
    ('P1-QUA-02','P1-1.1','Дискриминант и корни','Diskriminant va ildizlar','Discriminant and roots'),
    ('P1-QUA-03','P1-1.1','Решение квадратных уравнений','Kvadrat tenglamalarni yechish','Solving quadratic equations'),
    ('P1-QUA-04','P1-1.1','Квадратные неравенства','Kvadrat tengsizliklar','Quadratic inequalities'),
    ('P1-QUA-05','P1-1.1','Линейно-квадратные системы','Chiziqli-kvadrat sistemalar','Linear–quadratic systems'),
    ('P1-QUA-06','P1-1.1','Сведение к квадратному уравнению','Kvadrat tenglamaga keltirish','Reducing to a quadratic'),
    ('P1-FUN-01','P1-1.2','Функция: область и значения','Funksiya: soha va qiymatlar','Functions: domain and range'),
    ('P1-FUN-02','P1-1.2','Область значений функции','Funksiyaning qiymatlar to‘plami','Range of a function'),
    ('P1-FUN-03','P1-1.2','Композиция функций','Funksiyalar kompozitsiyasi','Composite functions'),
    ('P1-FUN-04','P1-1.2','Обратная функция','Teskari funksiya','Inverse functions'),
    ('P1-FUN-05','P1-1.2','График обратной функции','Teskari funksiya grafigi','Graphs of inverse functions'),
    ('P1-FUN-06','P1-1.2','Сдвиги графиков','Grafiklarni siljitish','Graph translations'),
    ('P1-FUN-07','P1-1.2','Отражения графиков','Grafiklarni akslantirish','Graph reflections'),
    ('P1-FUN-08','P1-1.2','Растяжения и сжатия графиков','Grafiklarni cho‘zish va siqish','Graph stretches and compressions'),
    ('P1-COO-01','P1-1.3','Уравнение прямой','To‘g‘ri chiziq tenglamasi','Equation of a straight line'),
    ('P1-COO-02','P1-1.3','Расстояние, середина и пересечение','Masofa, o‘rta nuqta va kesishish','Distance, midpoint and intersection'),
    ('P1-COO-03','P1-1.3','Параллельные и перпендикулярные прямые','Parallel va perpendikulyar chiziqlar','Parallel and perpendicular lines'),
    ('P1-COO-04','P1-1.3','Уравнение окружности','Aylana tenglamasi','Equation of a circle'),
    ('P1-COO-05','P1-1.3','Прямая и окружность','To‘g‘ri chiziq va aylana','Lines and circles'),
    ('P1-COO-06','P1-1.3','Пересечение и касание','Kesishish va urinma','Intersections and tangency'),
    ('P1-CIR-01','P1-1.4','Градусы и радианы','Gradus va radianlar','Degrees and radians'),
    ('P1-CIR-02','P1-1.4','Длина дуги','Yoy uzunligi','Arc length'),
    ('P1-CIR-03','P1-1.4','Площадь сектора и сегмента','Sektor va segment yuzi','Sector and segment area'),
    ('P1-TRI-01','P1-1.5','Графики sin, cos и tan','sin, cos va tan grafiklari','Graphs of sin, cos and tan'),
    ('P1-TRI-02','P1-1.5','Точные тригонометрические значения','Aniq trigonometrik qiymatlar','Exact trigonometric values'),
    ('P1-TRI-03','P1-1.5','Обратные тригонометрические функции','Teskari trigonometrik funksiyalar','Inverse trigonometric functions'),
    ('P1-TRI-04','P1-1.5','Тригонометрические тождества','Trigonometrik ayniyatlar','Trigonometric identities'),
    ('P1-TRI-05','P1-1.5','Тригонометрические уравнения','Trigonometrik tenglamalar','Trigonometric equations'),
    ('P1-SER-01','P1-1.6','Биномиальное разложение','Binom yoyilmasi','Binomial expansion'),
    ('P1-SER-02','P1-1.6','Арифметическая и геометрическая прогрессии','Arifmetik va geometrik progressiyalar','Arithmetic and geometric progressions'),
    ('P1-SER-03','P1-1.6','Арифметическая прогрессия','Arifmetik progressiya','Arithmetic progressions'),
    ('P1-SER-04','P1-1.6','Геометрическая прогрессия','Geometrik progressiya','Geometric progressions'),
    ('P1-SER-05','P1-1.6','Бесконечный геометрический ряд','Cheksiz geometrik qator','Infinite geometric series'),
    ('P1-DIF-01','P1-1.7','Смысл производной','Hosilaning ma’nosi','Meaning of the derivative'),
    ('P1-DIF-02','P1-1.7','Производные степенных функций','Darajali funksiyalar hosilasi','Differentiating powers'),
    ('P1-DIF-03','P1-1.7','Цепное правило','Zanjir qoidasi','Chain rule'),
    ('P1-DIF-04','P1-1.7','Касательная и нормаль','Urinma va normal','Tangent and normal'),
    ('P1-DIF-05','P1-1.7','Возрастание и убывание','O‘sish va kamayish','Increasing and decreasing functions'),
    ('P1-DIF-06','P1-1.7','Скорости изменения','O‘zgarish tezligi','Rates of change'),
    ('P1-DIF-07','P1-1.7','Стационарные точки и оптимизация','Statsionar nuqtalar va optimallashtirish','Stationary points and optimisation'),
    ('P1-INT-01','P1-1.8','Первообразные','Boshlang‘ich funksiyalar','Antiderivatives'),
    ('P1-INT-02','P1-1.8','Постоянная интегрирования','Integrallash doimiysi','Constant of integration'),
    ('P1-INT-03','P1-1.8','Определённый интеграл','Aniq integral','Definite integrals'),
    ('P1-INT-04','P1-1.8','Площадь между кривыми','Egri chiziqlar orasidagi yuza','Area between curves'),
    ('P1-INT-05','P1-1.8','Объём тела вращения','Aylanish jismi hajmi','Volume of revolution'),
    ('P5-DAT-01','P5-5.1','Выбор способа представления данных','Ma’lumotlarni tasvirlash usulini tanlash','Choosing a data display'),
    ('P5-DAT-02','P5-5.1','Диаграмма «стебель и листья»','Poya-barg diagrammasi','Stem-and-leaf diagrams'),
    ('P5-DAT-03','P5-5.1','Диаграмма размаха','Quti diagrammasi','Box-and-whisker plots'),
    ('P5-DAT-04','P5-5.1','Гистограмма и плотность частоты','Gistogramma va chastota zichligi','Histograms and frequency density'),
    ('P5-DAT-05','P5-5.1','Накопленная частота','Yig‘ma chastota','Cumulative frequency'),
    ('P5-DAT-06','P5-5.1','Среднее, медиана и мода','O‘rtacha, mediana va moda','Mean, median and mode'),
    ('P5-DAT-07','P5-5.1','Разброс и стандартное отклонение','Tarqalish va standart og‘ish','Spread and standard deviation'),
    ('P5-DAT-08','P5-5.1','Сравнение наборов данных','Ma’lumotlar to‘plamlarini taqqoslash','Comparing data sets'),
    ('P5-DAT-09','P5-5.1','Среднее и стандартное отклонение','O‘rtacha va standart og‘ishni hisoblash','Mean and standard deviation'),
    ('P5-DAT-10','P5-5.1','Кодированные и объединённые данные','Kodlangan va birlashtirilgan ma’lumotlar','Coded and combined data'),
    ('P5-CNT-01','P5-5.2','Размещения и выборки','Joylashtirish va tanlash','Arrangements and selections'),
    ('P5-CNT-02','P5-5.2','Перестановки различных объектов','Turli obyektlar permutatsiyasi','Permutations of distinct objects'),
    ('P5-CNT-03','P5-5.2','Перестановки с повторениями','Takrorlanuvchi obyektlar joylashuvi','Arrangements with repeated objects'),
    ('P5-CNT-04','P5-5.2','Размещения с ограничениями','Cheklovli joylashtirish','Restricted arrangements'),
    ('P5-CNT-05','P5-5.2','Сочетания','Kombinatsiyalar','Combinations'),
    ('P5-PRO-01','P5-5.3','Пространство исходов','Natijalar fazosi','Sample spaces'),
    ('P5-PRO-02','P5-5.3','Вероятность через подсчёт','Sanash usullari bilan ehtimollik','Probability by counting'),
    ('P5-PRO-03','P5-5.3','Сложение вероятностей и дополнение','Ehtimollarni qo‘shish va to‘ldiruvchi hodisa','Addition rule and complements'),
    ('P5-PRO-04','P5-5.3','Умножение вероятностей и независимость','Ehtimollarni ko‘paytirish va mustaqillik','Multiplication rule and independence'),
    ('P5-PRO-05','P5-5.3','Условная вероятность','Shartli ehtimollik','Conditional probability'),
    ('P5-PRO-06','P5-5.3','Деревья вероятностей','Ehtimollik daraxtlari','Probability trees'),
    ('P5-DRV-01','P5-5.4','Дискретное распределение вероятностей','Diskret ehtimollik taqsimoti','Discrete probability distributions'),
    ('P5-DRV-02','P5-5.4','Математическое ожидание','Matematik kutilma','Expectation'),
    ('P5-DRV-03','P5-5.4','Дисперсия и стандартное отклонение','Dispersiya va standart og‘ish','Variance and standard deviation'),
    ('P5-BIN-01','P5-5.4','Биномиальная модель','Binomial model','Binomial model'),
    ('P5-BIN-02','P5-5.4','Биномиальные вероятности','Binomial ehtimolliklar','Binomial probabilities'),
    ('P5-BIN-03','P5-5.4','Среднее и дисперсия биномиального распределения','Binomial o‘rtacha va dispersiya','Binomial mean and variance'),
    ('P5-GEO-01','P5-5.4','Геометрическая модель','Geometrik model','Geometric model'),
    ('P5-GEO-02','P5-5.4','Геометрические вероятности','Geometrik ehtimolliklar','Geometric probabilities'),
    ('P5-GEO-03','P5-5.4','Ожидание геометрического распределения','Geometrik taqsimotning kutilmasi','Geometric expectation'),
    ('P5-NOR-01','P5-5.5','Нормальная модель','Normal model','Normal model'),
    ('P5-NOR-02','P5-5.5','Стандартизация и z-значение','Standartlashtirish va z-qiymat','Standardisation and z-values'),
    ('P5-NOR-03','P5-5.5','Нормальные вероятности','Normal ehtimolliklar','Normal probabilities'),
    ('P5-NOR-04','P5-5.5','Квантили нормального распределения','Normal taqsimot kvantillari','Normal quantiles'),
    ('P5-NOR-05','P5-5.5','Нахождение μ и σ','μ va σ ni topish','Finding μ and σ'),
    ('P5-NOR-06','P5-5.5','Нормальное приближение биномиального распределения','Binomial taqsimotga normal yaqinlashuv','Normal approximation to the binomial')
),
area_sources(area_key,locale,book_ref,body_text) as (
  values
    ('P1-1.1','ru','Complete Pure Mathematics 1, Ch1 Quadratics, pp. 2-20','Основные идеи квадратных выражений Paper 1: выделяйте полный квадрат, чтобы видеть вершину и форму параболы; используйте дискриминант D = b^2 - 4ac для определения числа действительных корней и условий на параметр; решайте квадратные уравнения разложением, формулой или выделением полного квадрата; решайте квадратные неравенства по корням и знаку; линейно-квадратные системы решайте подстановкой; распознавайте уравнения, которые становятся квадратными после подходящей замены.'),
    ('P1-1.1','uz','Complete Pure Mathematics 1, Ch1 Quadratics, pp. 2-20','Paper 1 kvadrat mavzusining asosiy g‘oyalari: kvadrat ifodani to‘liq kvadratga keltirib parabola uchini va shaklini aniqlang; haqiqiy ildizlar soni va parametr shartlari uchun D = b^2 - 4ac diskriminantidan foydalaning; kvadrat tenglamalarni ko‘paytuvchilarga ajratish, formula yoki to‘liq kvadratga keltirish orqali yeching; kvadrat tengsizliklarni ildizlar va ishora orqali tahlil qiling; chiziqli-kvadrat sistemalarda almashtirishdan foydalaning; mos almashtirishdan keyin kvadrat tenglamaga aylanadigan tenglamalarni taning.'),
    ('P1-1.1','en','Complete Pure Mathematics 1, Ch1 Quadratics, pp. 2-20','Core Paper 1 quadratic ideas: rewrite a quadratic by completing the square to expose its vertex and shape; use the discriminant D = b^2 - 4ac to classify real roots and parameter conditions; solve quadratic equations by factorisation, the quadratic formula or completing the square; solve quadratic inequalities from roots and sign; solve a linear-quadratic system by substitution; and recognise equations that become quadratic after a suitable substitution.'),
    ('P1-1.2','ru','Complete Pure Mathematics 1, Ch2 Functions and transformations, pp. 24-42','Основные идеи функций Paper 1: различайте область определения и область значений; перед нахождением обратной функции проверяйте взаимную однозначность; композиция допустима только там, где результат первой функции входит в область определения второй; обратная функция меняет отображение местами, а её график отражён относительно y = x; сдвиги, отражения, растяжения и сжатия меняют положение или масштаб графика в зависимости от преобразования аргумента x или значения f(x).'),
    ('P1-1.2','uz','Complete Pure Mathematics 1, Ch2 Functions and transformations, pp. 24-42','Paper 1 funksiyalarining asosiy g‘oyalari: aniqlanish sohasi va qiymatlar to‘plamini farqlang; teskari funksiyani topishdan oldin funksiya bir qiymatli teskari moslikka ega ekanini tekshiring; kompozitsiya faqat birinchi funksiyaning chiqishi ikkinchisining aniqlanish sohasiga tushganda mumkin; teskari funksiya moslikni teskariga o‘giradi va grafigi y = x ga nisbatan akslanadi; siljitish, akslantirish, cho‘zish va siqish x yoki f(x) ga qo‘llangan o‘zgarishga qarab grafikning joylashuvi yoki masshtabini o‘zgartiradi.'),
    ('P1-1.2','en','Complete Pure Mathematics 1, Ch2 Functions and transformations, pp. 24-42','Core Paper 1 function ideas: distinguish domain and range; check when a function is one-to-one before forming an inverse; compose functions only where the output of the first lies in the domain of the second; an inverse reverses the mapping and its graph is reflected in y = x; translations, reflections and stretches/compressions change graph position or scale according to the transformation applied to x or to f(x).'),
    ('P1-1.3','ru','Complete Pure Mathematics 1, Ch3 Coordinate geometry, pp. 48-67','Основные идеи координатной геометрии Paper 1: прямая определяется угловым коэффициентом и точкой; параллельные прямые имеют одинаковый коэффициент, а для непараллельных осям перпендикулярных прямых произведение коэффициентов равно -1; используйте формулы расстояния и середины и решайте систему для точки пересечения; окружность с центром (a,b) и радиусом r имеет вид (x-a)^2 + (y-b)^2 = r^2; пересечения прямой и окружности находятся совместным решением, а касание означает одно пересечение и часто соответствует нулевому дискриминанту.'),
    ('P1-1.3','uz','Complete Pure Mathematics 1, Ch3 Coordinate geometry, pp. 48-67','Paper 1 koordinata geometriyasining asosiy g‘oyalari: to‘g‘ri chiziq gradient va nuqta bilan aniqlanadi; parallel chiziqlarning gradientlari teng, koordinata o‘qlariga parallel bo‘lmagan perpendikulyar chiziqlarda gradientlar ko‘paytmasi -1 ga teng; masofa va o‘rta nuqta formulalaridan hamda kesishish uchun birgalikdagi tenglamalardan foydalaning; markazi (a,b), radiusi r bo‘lgan aylana (x-a)^2 + (y-b)^2 = r^2 ko‘rinishida; chiziq-aylana kesishishlari birgalikdagi algebra orqali topiladi, urinma esa aynan bitta kesishish bo‘lib, ko‘pincha diskriminantning nol bo‘lishi bilan aniqlanadi.'),
    ('P1-1.3','en','Complete Pure Mathematics 1, Ch3 Coordinate geometry, pp. 48-67','Core Paper 1 coordinate-geometry ideas: a straight line is controlled by gradient and a point, with parallel lines sharing a gradient and perpendicular non-vertical gradients having product -1; use distance, midpoint and simultaneous equations for intersections; a circle with centre (a,b) and radius r has (x-a)^2 + (y-b)^2 = r^2; line-circle intersections come from simultaneous algebra, and tangency corresponds to exactly one intersection, often detected by discriminant zero.'),
    ('P1-1.4','ru','Complete Pure Mathematics 1, Ch4 Circular measure, pp. 74-81','Основные идеи радианной меры Paper 1: 180 градусов = pi радиан, поэтому перед применением формул приводите угол к нужной мере. Если theta задан в радианах, длина дуги s = r theta, а площадь сектора A = 1/2 r^2 theta. В составных задачах на сектор или сегмент разбивайте фигуру на известные части; площадь сегмента обычно находится как площадь сектора минус площадь соответствующего треугольника.'),
    ('P1-1.4','uz','Complete Pure Mathematics 1, Ch4 Circular measure, pp. 74-81','Paper 1 aylana o‘lchovining asosiy g‘oyalari: 180 gradus = pi radian, shuning uchun formuladan oldin burchak o‘lchovini mos birlikka keltiring. theta radianlarda bo‘lsa, yoy uzunligi s = r theta, sektor yuzi A = 1/2 r^2 theta. Murakkab sektor yoki segment masalalarida shaklni ma’lum qismlarga ajrating; segment yuzi odatda sektor yuzidan tegishli uchburchak yuzini ayirish orqali topiladi.'),
    ('P1-1.4','en','Complete Pure Mathematics 1, Ch4 Circular measure, pp. 74-81','Core Paper 1 circular-measure ideas: 180 degrees = pi radians, so convert consistently before using radian formulas. For angle theta in radians, arc length is s = r theta and sector area is A = 1/2 r^2 theta. In composite sector or segment problems, split the diagram into known pieces; a segment is commonly found as sector area minus the appropriate triangle area.'),
    ('P1-1.5','ru','Complete Pure Mathematics 1, Ch5 Trigonometry, pp. 86-104','Основные идеи тригонометрии Paper 1: знайте форму, период и ключевые значения графиков sin, cos и tan и отслеживайте простые преобразования; используйте точные значения и симметрии по четвертям; обратные тригонометрические функции дают главное значение, поэтому для всех решений на заданном интервале используйте график или закономерности единичной окружности; базовые тождества sin^2 x + cos^2 x = 1 и tan x = sin x / cos x используются для преобразований и доказательств.'),
    ('P1-1.5','uz','Complete Pure Mathematics 1, Ch5 Trigonometry, pp. 86-104','Paper 1 trigonometriyasining asosiy g‘oyalari: sin, cos va tan grafiklarining shakli, davri va asosiy qiymatlarini biling hamda oddiy grafik o‘zgarishlarini kuzating; aniq qiymatlar va choraklardagi simmetriyadan foydalaning; teskari trigonometrik funksiyalar bosh qiymatni beradi, shuning uchun berilgan oraliqdagi barcha yechimlarni topish uchun grafik yoki birlik aylana qonuniyatidan foydalaning; sin^2 x + cos^2 x = 1 va tan x = sin x / cos x asosiy ayniyatlari soddalashtirish va isbotlarda ishlatiladi.'),
    ('P1-1.5','en','Complete Pure Mathematics 1, Ch5 Trigonometry, pp. 86-104','Core Paper 1 trigonometry ideas: know the shapes, periods and key values of sin, cos and tan and track simple graph transformations; use exact values and quadrant symmetry; inverse trig functions return principal values, so use the graph or unit-circle pattern to find every solution in the required interval; the basic identities sin^2 x + cos^2 x = 1 and tan x = sin x / cos x support simplification and proof.'),
    ('P1-1.6','ru','Complete Pure Mathematics 1, Ch6 Binomial expansion and Ch7 Series, pp. 109-133','Основные идеи рядов Paper 1: при положительном целом n раскрывайте (a + bx)^n с биномиальными коэффициентами и находите нужный член по степени x. В арифметической прогрессии разность d постоянна: u_n = a + (n-1)d и S_n = n/2[2a+(n-1)d]. В геометрической прогрессии отношение r постоянно: u_n = ar^(n-1) и S_n = a(1-r^n)/(1-r) при r != 1. Бесконечный геометрический ряд сходится только при |r| < 1, и тогда S_infinity = a/(1-r).'),
    ('P1-1.6','uz','Complete Pure Mathematics 1, Ch6 Binomial expansion and Ch7 Series, pp. 109-133','Paper 1 qatorlarining asosiy g‘oyalari: musbat butun n uchun (a + bx)^n ni binomial koeffitsiyentlar bilan yoying va kerakli hadni x darajasi orqali aniqlang. Arifmetik progressiyada ayirma d o‘zgarmas: u_n = a + (n-1)d va S_n = n/2[2a+(n-1)d]. Geometrik progressiyada nisbat r o‘zgarmas: u_n = ar^(n-1) va r != 1 bo‘lsa S_n = a(1-r^n)/(1-r). Cheksiz geometrik qator faqat |r| < 1 bo‘lganda yaqinlashadi va bu holda S_infinity = a/(1-r).'),
    ('P1-1.6','en','Complete Pure Mathematics 1, Ch6 Binomial expansion and Ch7 Series, pp. 109-133','Core Paper 1 series ideas: for positive integer n, expand (a + bx)^n with binomial coefficients and identify a required term by its power of x. An arithmetic progression has constant difference d, with u_n = a + (n-1)d and S_n = n/2[2a+(n-1)d]. A geometric progression has constant ratio r, with u_n = ar^(n-1) and S_n = a(1-r^n)/(1-r) for r != 1. An infinite geometric series converges only when |r| < 1, then S_infinity = a/(1-r).'),
    ('P1-1.7','ru','Complete Pure Mathematics 1, Ch8-9 Differentiation, pp. 138-167','Основные идеи дифференцирования Paper 1: производная показывает угловой коэффициент касательной и мгновенную скорость изменения. Используйте d/dx(x^n)=n x^(n-1) для допустимых степеней и цепное правило для (ax+b)^n. Касательная имеет угловой коэффициент, равный производной; нормаль при существовании имеет противоположный обратный коэффициент. Знак производной определяет интервалы возрастания и убывания. В стационарной точке dy/dx=0; определяйте её тип по смене знака или подходящему анализу производной и используйте в построении графика и оптимизации. В связанных скоростях связывайте производные через общую переменную и следите за знаками и единицами.'),
    ('P1-1.7','uz','Complete Pure Mathematics 1, Ch8-9 Differentiation, pp. 138-167','Paper 1 differensiallashining asosiy g‘oyalari: hosila urinma gradientini va oniy o‘zgarish tezligini ifodalaydi. Ruxsat etilgan darajalar uchun d/dx(x^n)=n x^(n-1), (ax+b)^n uchun zanjir qoidasidan foydalaning. Urinma gradienti hosilaga teng; normalning gradienti mavjud bo‘lsa, manfiy teskari qiymat bo‘ladi. Hosila ishorasi funksiyaning o‘sish va kamayish oraliqlarini ko‘rsatadi. Statsionar nuqtada dy/dx=0; uning turini ishora almashishi yoki mos hosila tahlili bilan aniqlang va grafik hamda optimallashtirishda ishlating. Bog‘langan tezlik masalalarida hosilalarni umumiy o‘zgaruvchi orqali bog‘lang va ishora hamda birliklarni tekshiring.'),
    ('P1-1.7','en','Complete Pure Mathematics 1, Ch8-9 Differentiation, pp. 138-167','Core Paper 1 differentiation ideas: the derivative represents gradient and instantaneous rate of change. Use d/dx(x^n)=n x^(n-1) for allowed powers and the chain rule for (ax+b)^n. A tangent uses the derivative gradient; a normal has reciprocal negative gradient when defined. The sign of the derivative gives increasing/decreasing intervals. Stationary points satisfy dy/dx=0; classify them from sign change or suitable derivative reasoning, and use them in sketching and optimisation. Connected-rate problems link derivatives through a shared variable and require consistent signs and units.'),
    ('P1-1.8','ru','Complete Pure Mathematics 1, Ch10 Integration, pp. 173-200','Основные идеи интегрирования Paper 1: интегрирование является обратной операцией к дифференцированию. При n != -1 интеграл x^n равен x^(n+1)/(n+1), а при интегрировании (ax+b)^n учитывайте внутренний линейный множитель. В неопределённом интеграле нужна постоянная C; при наличии точки или граничного условия её можно найти. Определённый интеграл даёт знаковое накопление между пределами. Для геометрической площади разбивайте область в точках пересечения или смены знака, чтобы физическая площадь была положительной. Для объёма вращения определите радиус относительно оси и используйте pi умножить на интеграл квадрата радиуса с правильными пределами.'),
    ('P1-1.8','uz','Complete Pure Mathematics 1, Ch10 Integration, pp. 173-200','Paper 1 integrallashining asosiy g‘oyalari: integrallash differensiallashning teskari amalidir. n != -1 bo‘lsa, x^n ning integrali x^(n+1)/(n+1); (ax+b)^n ni integrallashda ichki chiziqli koeffitsiyentni hisobga oling. Aniqlanmagan integralda C doimiysi kerak; berilgan nuqta yoki chegara sharti bo‘lsa, C ni toping. Aniq integral chegaralar orasidagi ishorali yig‘ilishni beradi. Geometrik yuzani topishda kesishish yoki ishora almashish nuqtalarida sohani bo‘ling, shunda fizik yuza musbat olinadi. Aylanish hajmida o‘qqa nisbatan radiusni aniqlang va to‘g‘ri chegaralarda pi ko‘paytirilgan radius kvadrati integralidan foydalaning.'),
    ('P1-1.8','en','Complete Pure Mathematics 1, Ch10 Integration, pp. 173-200','Core Paper 1 integration ideas: integration reverses differentiation. For n != -1, integrate x^n as x^(n+1)/(n+1), and account for the inner linear factor when integrating (ax+b)^n. Indefinite integrals require a constant C, found from a given point or boundary condition when available. A definite integral gives signed accumulation between limits. For geometric area, split at intersections or sign changes so physical area is positive. For a volume of revolution, identify the radius from the axis and use the appropriate pi times integral of radius squared with correct limits.'),
    ('P5-5.1','ru','Complete Probability & Statistics 1, Ch2-3, pp. 14-59','Основные идеи представления данных Paper 5: выбирайте способ представления по типу данных и цели. Диаграмма «стебель и листья» сохраняет отдельные значения; box plot показывает медиану, квартили и разброс; в гистограмме плотность частоты = частота / ширина интервала, поэтому площадь столбца соответствует частоте; график накопленной частоты используется для квартилей, процентилей и долей. Сравнивайте наборы одновременно по положению и разбросу. Для исходных, сгруппированных, кодированных или объединённых данных последовательно используйте выбранную формулу среднего и стандартного отклонения и аккуратно преобразуйте суммы.'),
    ('P5-5.1','uz','Complete Probability & Statistics 1, Ch2-3, pp. 14-59','Paper 5 ma’lumotlar mavzusining asosiy g‘oyalari: tasvirlash usulini ma’lumot turi va maqsadga mos tanlang. Poya-barg diagrammasi alohida qiymatlarni saqlaydi; quti diagrammasi mediana, kvartillar va tarqalishni ko‘rsatadi; gistogrammada chastota zichligi = chastota / interval kengligi, shuning uchun ustun yuzi chastotaga mos keladi; yig‘ma chastota grafigi kvartil, percentil va ulushlarni topishga yordam beradi. To‘plamlarni ham markaziy qiymat, ham tarqalish bo‘yicha taqqoslang. Xom, guruhlangan, kodlangan yoki birlashtirilgan ma’lumotlarda tanlangan o‘rtacha va standart og‘ish formulasini izchil qo‘llang va yig‘indilarni ehtiyotkor o‘zgartiring.'),
    ('P5-5.1','en','Complete Probability & Statistics 1, Ch2-3, pp. 14-59','Core Paper 5 data ideas: choose a display that matches the data type and purpose. Stem-and-leaf diagrams preserve individual values; box plots show median, quartiles and spread; histograms use frequency density = frequency / class width, so bar area represents frequency; cumulative-frequency graphs support quartiles, percentiles and proportions. Compare data using both location and spread. For raw, grouped, coded or combined data, keep the chosen mean and standard-deviation convention consistent with the given information and transform totals carefully.'),
    ('P5-5.2','ru','Complete Probability & Statistics 1, Ch6 Permutations and combinations, pp. 98-111','Основные идеи комбинаторики Paper 5: сначала решите, важен ли порядок. Для последовательных выборов используйте правило произведения, а для размещения n различных объектов — n!. При одинаковых повторяющихся объектах делите на факториалы числа повторений. Ограничения учитывайте фиксацией мест, объединением объектов «вместе» в один блок, вычитанием запрещённых случаев или разбиением на случаи. Используйте сочетания nCr, когда порядок не важен; если после выбора идёт размещение, учитывайте оба этапа.'),
    ('P5-5.2','uz','Complete Probability & Statistics 1, Ch6 Permutations and combinations, pp. 98-111','Paper 5 sanash mavzusining asosiy g‘oyalari: avval tartib muhim yoki muhim emasligini aniqlang. Ketma-ket tanlovlar uchun ko‘paytirish qoidasidan, n ta turli obyektni joylashtirish uchun n! dan foydalaning. Bir xil takrorlanuvchi obyektlarda takrorlar sonining faktoriallariga bo‘ling. Cheklovlarda joylarni mahkamlash, birga turishi kerak bo‘lgan obyektlarni bitta blok deb olish, taqiqlangan holatlarni ayirish yoki holatlarga ajratish usullaridan foydalaning. Tartib muhim bo‘lmasa nCr kombinatsiyasidan foydalaning; tanlovdan keyin joylashtirish bo‘lsa, ikkala bosqichni ham hisoblang.'),
    ('P5-5.2','en','Complete Probability & Statistics 1, Ch6 Permutations and combinations, pp. 98-111','Core Paper 5 counting ideas: decide first whether order matters. Use the product rule for successive choices and n! for arranging n distinct objects. For repeated identical objects divide by the factorials of repeat counts. Restrictions are handled by fixing positions, treating required-together objects as a block, subtracting forbidden cases, or splitting into cases. Use combinations nCr when order does not matter; if a selection is followed by an arrangement, count both stages.'),
    ('P5-5.3','ru','Complete Probability & Statistics 1, Ch4 Probability, pp. 63-82','Основные идеи вероятности Paper 5: задавайте пространство исходов без пропусков и повторов. Для равновероятных исходов используйте методы подсчёта. Правило сложения: P(A union B)=P(A)+P(B)-P(A intersection B); для дополнения P(A'')=1-P(A). Условная вероятность P(A|B)=P(A intersection B)/P(B). Для независимых событий P(A intersection B)=P(A)P(B). Дерево вероятностей удобно для последовательных событий; при выборе без возвращения вероятности после каждого шага изменяются.'),
    ('P5-5.3','uz','Complete Probability & Statistics 1, Ch4 Probability, pp. 63-82','Paper 5 ehtimollik mavzusining asosiy g‘oyalari: natijalar fazosini tushirib qoldirmasdan va takrorlamasdan tuzing. Natijalar teng ehtimolli bo‘lsa, sanash usullaridan foydalaning. Qo‘shish qoidasi: P(A union B)=P(A)+P(B)-P(A intersection B); to‘ldiruvchi hodisa uchun P(A'')=1-P(A). Shartli ehtimollik P(A|B)=P(A intersection B)/P(B). Mustaqil hodisalarda P(A intersection B)=P(A)P(B). Ehtimollik daraxti ketma-ket hodisalarni tartiblaydi; qaytarmasdan tanlashda har bir bosqichdan keyin ehtimollarni yangilang.'),
    ('P5-5.3','en','Complete Probability & Statistics 1, Ch4 Probability, pp. 63-82','Core Paper 5 probability ideas: define the sample space without omissions or duplicates. Use counting methods when outcomes are equally likely. The addition rule is P(A union B)=P(A)+P(B)-P(A intersection B); complements use P(A'')=1-P(A). Conditional probability is P(A|B)=P(A intersection B)/P(B). For independent events, P(A intersection B)=P(A)P(B). Probability trees organise sequential events; without replacement, update the probabilities after each draw.'),
    ('P5-5.4','ru','Complete Probability & Statistics 1, Ch5, Ch7 and Ch8, pp. 84-96, 115-145','Основные идеи дискретных случайных величин Paper 5: распределение вероятностей задаёт неотрицательные вероятности, сумма которых равна 1. Для дискретной X: E(X)=sum xP(X=x), а Var(X)=E(X^2)-[E(X)]^2. Биномиальная модель требует фиксированного n, двух исходов, постоянной вероятности успеха p и независимых испытаний; тогда P(X=r)=nCr p^r(1-p)^(n-r), среднее=np, дисперсия=np(1-p). Геометрическая модель считает число испытаний до первого успеха при постоянном p и независимости; P(X=r)=(1-p)^(r-1)p и E(X)=1/p. Аккуратно используйте накопленные вероятности и дополнение.'),
    ('P5-5.4','uz','Complete Probability & Statistics 1, Ch5, Ch7 and Ch8, pp. 84-96, 115-145','Paper 5 diskret tasodifiy miqdorlarining asosiy g‘oyalari: ehtimollik taqsimotidagi ehtimollar manfiy bo‘lmaydi va yig‘indisi 1 ga teng. Diskret X uchun E(X)=sum xP(X=x), Var(X)=E(X^2)-[E(X)]^2. Binomial modelda n o‘zgarmas, ikki natija, muvaffaqiyat ehtimoli p o‘zgarmas va sinovlar mustaqil bo‘lishi kerak; P(X=r)=nCr p^r(1-p)^(n-r), o‘rtacha=np, dispersiya=np(1-p). Geometrik model doimiy p va mustaqillikda birinchi muvaffaqiyatgacha bo‘lgan sinovlar sonini sanaydi; P(X=r)=(1-p)^(r-1)p va E(X)=1/p. Yig‘ma ehtimollar va to‘ldiruvchidan ehtiyotkor foydalaning.'),
    ('P5-5.4','en','Complete Probability & Statistics 1, Ch5, Ch7 and Ch8, pp. 84-96, 115-145','Core Paper 5 discrete-random-variable ideas: a probability distribution assigns non-negative probabilities that sum to 1. For discrete X, E(X)=sum xP(X=x), and Var(X)=E(X^2)-[E(X)]^2. A binomial model needs fixed n, two outcomes, constant success probability p and independent trials; then P(X=r)=nCr p^r(1-p)^(n-r), mean=np and variance=np(1-p). A geometric model counts trials until the first success with constant p and independence; P(X=r)=(1-p)^(r-1)p and E(X)=1/p. Use cumulative probabilities and complements carefully.'),
    ('P5-5.5','ru','Complete Probability & Statistics 1, Ch9-10, pp. 147-179','Основные идеи нормального распределения Paper 5: моделируйте X нормальным распределением со средним mu и дисперсией sigma^2 и интерпретируйте положение на симметричной колоколообразной кривой. Стандартизация: Z=(X-mu)/sigma; затем правильно выбирайте нужный интервал или хвост. Обратное нормальное распределение используется для квантилей и при нахождении неизвестных mu или sigma. Для нормального приближения биномиального распределения сначала проверяйте условия применимости, используйте среднее np и дисперсию np(1-p) и правильно применяйте поправку на непрерывность при переходе от дискретных границ к непрерывной модели.'),
    ('P5-5.5','uz','Complete Probability & Statistics 1, Ch9-10, pp. 147-179','Paper 5 normal taqsimotining asosiy g‘oyalari: X ni o‘rtacha mu va dispersiya sigma^2 bo‘lgan normal taqsimot bilan modellashtiring va simmetrik qo‘ng‘iroqsimon egri chiziqdagi o‘rnini talqin qiling. Standartlashtirish: Z=(X-mu)/sigma; so‘ng kerakli interval yoki dumni to‘g‘ri tanlang. Teskari normal usul kvantillar hamda noma’lum mu yoki sigma ni topishda ishlatiladi. Binomial taqsimotga normal yaqinlashuvda avval yaqinlashuv shartlarini tekshiring, o‘rtacha np va dispersiya np(1-p) dan foydalaning va diskret chegaralarni uzluksiz modelga o‘tkazishda uzluksizlik tuzatishini to‘g‘ri qo‘llang.'),
    ('P5-5.5','en','Complete Probability & Statistics 1, Ch9-10, pp. 147-179','Core Paper 5 normal-distribution ideas: model X with a normal distribution using mean mu and variance sigma^2, and interpret position relative to the symmetric bell curve. Standardise with Z=(X-mu)/sigma, then match the required interval or tail. Use inverse-normal reasoning for quantiles and for unknown mu or sigma. For a normal approximation to a binomial distribution, first check that the approximation conditions are satisfied, use mean np and variance np(1-p), and apply the correct continuity correction when translating discrete bounds to the continuous model.')
),
expanded as (
  select
    lower(split_part(s.skill_code,'-',1))||':'||s.skill_code||':theory:'||a.locale||':v1' as source_card_key,
    split_part(s.skill_code,'-',1) as component_code,
    s.skill_code,
    'theory'::text as card_type,
    a.locale,
    'p3_02_full_theory_pack_v1_2026_10_03'::text as source_version,
    case a.locale when 'ru' then s.title_ru when 'uz' then s.title_uz else s.title_en end as title,
    case a.locale
      when 'ru' then 'Фокус темы: '||s.title_ru||'. '||a.body_text
      when 'uz' then 'Mavzu fokusi: '||s.title_uz||'. '||a.body_text
      else 'Topic focus: '||s.title_en||'. '||a.body_text
    end as body_text
  from skill_titles s
  join area_sources a on a.area_key=s.area_key
)
insert into private.exam_prep_ai_source_cards(
  source_card_key,component_code,skill_code,card_type,locale,source_version,title,body_text,
  approval_status,rights_status,is_runtime_allowed,content_hash,approved_at,updated_at
)
select
  e.source_card_key,e.component_code,e.skill_code,e.card_type,e.locale,e.source_version,e.title,e.body_text,
  'approved','original_iclub',true,
  md5(e.source_card_key||'|'||e.source_version||'|'||e.title||'|'||e.body_text),
  now(),now()
from expanded e
on conflict(source_card_key) do update
set component_code=excluded.component_code,
    skill_code=excluded.skill_code,
    card_type=excluded.card_type,
    locale=excluded.locale,
    source_version=excluded.source_version,
    title=excluded.title,
    body_text=excluded.body_text,
    approval_status=excluded.approval_status,
    rights_status=excluded.rights_status,
    is_runtime_allowed=excluded.is_runtime_allowed,
    content_hash=excluded.content_hash,
    approved_at=coalesce(private.exam_prep_ai_source_cards.approved_at,excluded.approved_at),
    updated_at=now();

do $check$
declare
  v_program bigint;
  v_theory integer;
  v_p1 integer;
  v_p5 integer;
  v_missing integer;
  v_bad integer;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';

  if v_program is null then raise exception 'P3-02 full theory pack canonical program missing'; end if;

  select count(*),
         count(*) filter(where component_code='P1'),
         count(*) filter(where component_code='P5')
  into v_theory,v_p1,v_p5
  from private.exam_prep_ai_source_cards
  where card_type='theory'
    and approval_status='approved'
    and rights_status='original_iclub'
    and is_runtime_allowed;

  if v_theory<>243 or v_p1<>135 or v_p5<>108 then
    raise exception 'P3-02 full theory coverage count drift total=% P1=% P5=%',v_theory,v_p1,v_p5;
  end if;

  select count(*) into v_missing
  from private.exam_prep_syllabus_nodes n
  cross join (values('ru'),('uz'),('en')) l(locale)
  where n.program_version_id=v_program
    and n.component_code in ('P1','P5')
    and not exists(
      select 1 from private.exam_prep_ai_source_cards c
      where c.component_code=n.component_code
        and c.skill_code=n.skill_code
        and c.card_type='theory'
        and c.locale=l.locale
        and c.approval_status='approved'
        and c.rights_status='original_iclub'
        and c.is_runtime_allowed
    );
  if v_missing<>0 then
    raise exception 'P3-02 full theory pack missing canonical skill/locale rows=%',v_missing;
  end if;

  select count(*) into v_bad
  from private.exam_prep_ai_source_cards c
  where c.card_type='theory'
    and c.approval_status='approved'
    and c.is_runtime_allowed
    and (
      c.skill_code is null
      or c.source_version<>'p3_02_full_theory_pack_v1_2026_10_03'
      or c.rights_status<>'original_iclub'
      or c.body_text ilike '%answer key%'
      or c.body_text ilike '%mark scheme%'
    );
  if v_bad<>0 then
    raise exception 'P3-02 full theory pack governance drift rows=%',v_bad;
  end if;
end
$check$;

commit;
