-- Draft understanding checks for AW1-4 alternate written learning tasks.
-- DRAFT ONLY: non-credit companion checks; no publication or QA self-approval.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(
    select 1 from private.exam_prep_written_tasks
    where id between 15601 and 15609
      and content_version_id in (4801,4802)
      and lifecycle_state='draft'
  ) then
    raise exception 'aw01_04_written_checks_draft parent tasks missing';
  end if;

  if exists(
    select 1 from private.exam_prep_written_understanding_checks
    where id between 8901 and 8909
      and written_task_id not between 15601 and 15609
  ) then
    raise exception 'aw01_04_written_checks_draft reserved id collision';
  end if;
end
$preflight$;

insert into private.exam_prep_written_understanding_checks(
  id,written_task_id,check_order,check_version,check_kind,
  prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,
  correct_index,
  rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(
  8901,15601,1,'aw02-v1','mcq',
  'Why is −7 the minimum value of y=3(x−3)²−7?',
  'Почему −7 является минимальным значением y=3(x−3)²−7?',
  'Nega y=3(x−3)²−7 funksiyaning eng kichik qiymati −7?',
  '["Because (x−3)² is always at least 0 and its coefficient 3 is positive","Because x−3 is always positive","Because the graph crosses the y-axis at −7","Because every quadratic has minimum value equal to its constant term"]',
  '["Потому что (x−3)² всегда не меньше 0, а его коэффициент 3 положителен","Потому что x−3 всегда положительно","Потому что график пересекает ось y в −7","Потому что минимум любого квадратного трёхчлена равен его свободному члену"]',
  '["Chunki (x−3)² har doim 0 dan kichik emas va uning 3 koeffitsiyenti musbat","Chunki x−3 har doim musbat","Chunki grafik y o‘qini −7 da kesadi","Chunki har qanday kvadrat funksiyaning minimumi doimiy hadiga teng"]',
  0,
  'Since (x−3)²≥0, the term 3(x−3)² is nonnegative. Its smallest value is 0 at x=3, giving y=−7.',
  'Так как (x−3)²≥0, выражение 3(x−3)² неотрицательно. Его наименьшее значение 0 достигается при x=3, поэтому y=−7.',
  '(x−3)²≥0 bo‘lgani uchun 3(x−3)² manfiy emas. Uning eng kichik qiymati x=3 da 0, shuning uchun y=−7.',
  'draft','pending','pending','pending'
),
(
  8902,15602,1,'aw02-v1','mcq',
  'Why are the boundary values p=1±2√6 excluded from the interval for no real roots?',
  'Почему граничные значения p=1±2√6 не входят в интервал, при котором действительных корней нет?',
  'Nega p=1±2√6 chegara qiymatlari haqiqiy ildizlar yo‘q bo‘ladigan oraliqqa kirmaydi?',
  '["At the boundaries the discriminant is positive, so there are two roots","At the boundaries the discriminant is zero, so there is a repeated real root","At the boundaries the coefficient of x² becomes zero","At the boundaries the equation has infinitely many roots"]',
  '["На границах дискриминант положителен, поэтому есть два корня","На границах дискриминант равен нулю, поэтому есть повторный действительный корень","На границах коэффициент при x² становится нулём","На границах уравнение имеет бесконечно много корней"]',
  '["Chegaralarda diskriminant musbat bo‘lib, ikkita ildiz hosil bo‘ladi","Chegaralarda diskriminant nol bo‘lib, bitta takroriy haqiqiy ildiz hosil bo‘ladi","Chegaralarda x² koeffitsiyenti nol bo‘ladi","Chegaralarda tenglama cheksiz ko‘p ildizga ega bo‘ladi"]',
  1,
  'No real roots requires Δ<0. At p=1±2√6, Δ=0, so the quadratic has a repeated real root instead.',
  'Отсутствие действительных корней требует Δ<0. При p=1±2√6 получаем Δ=0, поэтому возникает повторный действительный корень.',
  'Haqiqiy ildizlar bo‘lmasligi uchun Δ<0 kerak. p=1±2√6 da Δ=0, shuning uchun takroriy haqiqiy ildiz hosil bo‘ladi.',
  'draft','pending','pending','pending'
),
(
  8903,15603,1,'aw02-v1','mcq',
  'From (x−3)²=13, why must both x=3+√13 and x=3−√13 be kept?',
  'Из (x−3)²=13 почему нужно сохранить оба решения x=3+√13 и x=3−√13?',
  '(x−3)²=13 dan nega x=3+√13 va x=3−√13 yechimlarining ikkalasini ham olish kerak?',
  '["Because taking a square root gives x−3=±√13","Because 13 has two positive square roots","Because every quadratic has exactly two distinct real roots","Because x−3 must be positive"]',
  '["Потому что при извлечении квадратного корня получаем x−3=±√13","Потому что у числа 13 два положительных квадратных корня","Потому что любое квадратное уравнение имеет ровно два различных действительных корня","Потому что x−3 обязательно положительно"]',
  '["Chunki kvadrat ildiz olganda x−3=±√13 bo‘ladi","Chunki 13 sonining ikkita musbat kvadrat ildizi bor","Chunki har qanday kvadrat tenglama aynan ikkita turli haqiqiy ildizga ega","Chunki x−3 albatta musbat"]',
  0,
  'If a square equals 13, the quantity can be either √13 or −√13. Therefore x−3=±√13.',
  'Если квадрат выражения равен 13, само выражение может быть √13 или −√13. Поэтому x−3=±√13.',
  'Ifodaning kvadrati 13 ga teng bo‘lsa, ifoda √13 yoki −√13 bo‘lishi mumkin. Shuning uchun x−3=±√13.',
  'draft','pending','pending','pending'
),
(
  8904,15604,1,'aw02-v1','mcq',
  'Why is the domain of (g∘f)(x) restricted to x≥2 when f(x)=x−2 and g is defined only for inputs ≥0?',
  'Почему область определения (g∘f)(x) ограничена условием x≥2, если f(x)=x−2, а g определена только для аргументов ≥0?',
  'Nega f(x)=x−2 va g faqat ≥0 kirishlarda aniqlangan bo‘lsa, (g∘f)(x) ning aniqlanish sohasi x≥2 bilan cheklanadi?',
  '["Because f(x) must be at most 0 before entering g","Because f(x)=x−2 must satisfy x−2≥0 before it can be used as an input to g","Because g(x)=x² is defined only when x≤2","Because every composition has the same domain as the outer function"]',
  '["Потому что перед подстановкой в g значение f(x) должно быть не больше 0","Потому что f(x)=x−2 должно удовлетворять x−2≥0, чтобы его можно было подставить в g","Потому что g(x)=x² определена только при x≤2","Потому что область любой композиции совпадает с областью внешней функции"]',
  '["Chunki g ga kiritishdan oldin f(x) 0 dan katta bo‘lmasligi kerak","Chunki g ga kirish sifatida ishlatish uchun f(x)=x−2 qiymati x−2≥0 shartini bajarishi kerak","Chunki g(x)=x² faqat x≤2 da aniqlangan","Chunki har qanday kompozitsiyaning aniqlanish sohasi tashqi funksiyaniki bilan bir xil"]',
  1,
  'In g(f(x)), the output of f becomes the input of g. Since g accepts only nonnegative inputs, x−2≥0, hence x≥2.',
  'В g(f(x)) результат f становится аргументом g. Так как g принимает только неотрицательные аргументы, x−2≥0, то есть x≥2.',
  'g(f(x)) da f ning chiqishi g uchun kirish bo‘ladi. g faqat manfiy bo‘lmagan kirishlarni qabul qiladi, shuning uchun x−2≥0, ya’ni x≥2.',
  'draft','pending','pending','pending'
),
(
  8905,15605,1,'aw02-v1','mcq',
  'For a quadratic on a closed restricted domain, where can its maximum or minimum occur?',
  'Для квадратичной функции на замкнутой ограниченной области где могут достигаться максимум или минимум?',
  'Kvadrat funksiya yopiq cheklangan sohada bo‘lsa, maksimum yoki minimum qayerda yuz berishi mumkin?',
  '["Only at the left endpoint","Only at the turning point","At an endpoint or at a turning point that lies inside the domain","Only where f(x)=0"]',
  '["Только на левом конце","Только в точке поворота","На конце области или в точке поворота, если она лежит внутри области","Только там, где f(x)=0"]',
  '["Faqat chap chegarada","Faqat burilish nuqtasida","Chegara nuqtasida yoki aniqlanish sohasi ichidagi burilish nuqtasida","Faqat f(x)=0 bo‘lgan joyda"]',
  2,
  'On a closed interval, the candidates for extreme values are the endpoints and any turning point inside the interval.',
  'На замкнутом интервале кандидатами на экстремальные значения являются концы и любая точка поворота внутри интервала.',
  'Yopiq intervalda ekstremal qiymatlar uchun nomzodlar chegaralar va interval ichidagi burilish nuqtalaridir.',
  'draft','pending','pending','pending'
),
(
  8906,15606,1,'aw02-v1','mcq',
  'Why is a scatter plot not the right display for comparing the two clinics’ waiting-time distributions?',
  'Почему диаграмма рассеяния не подходит для сравнения распределений времени ожидания двух клиник?',
  'Nega nuqtali tarqalish diagrammasi ikki klinikaning kutish vaqti taqsimotlarini taqqoslash uchun mos emas?',
  '["A scatter plot is only for categorical data","A scatter plot studies paired values of two variables, not two separate one-variable distributions","A scatter plot cannot contain numerical values","A scatter plot always shows only the median"]',
  '["Диаграмма рассеяния используется только для категориальных данных","Диаграмма рассеяния изучает парные значения двух переменных, а не два отдельных одномерных распределения","Диаграмма рассеяния не может содержать числовые значения","Диаграмма рассеяния всегда показывает только медиану"]',
  '["Nuqtali tarqalish diagrammasi faqat kategoriyali ma’lumotlar uchun","Nuqtali tarqalish diagrammasi ikki o‘zgaruvchining juft qiymatlarini o‘rganadi, ikkita alohida bir o‘zgaruvchili taqsimotni emas","Nuqtali tarqalish diagrammasida sonli qiymatlar bo‘la olmaydi","Nuqtali tarqalish diagrammasi har doim faqat medianani ko‘rsatadi"]',
  1,
  'Scatter plots are for association between paired measurements of two variables. Here the task is to compare two separate distributions of one variable.',
  'Диаграммы рассеяния используют для связи между парными измерениями двух переменных. Здесь нужно сравнить два отдельных распределения одной переменной.',
  'Nuqtali tarqalish diagrammasi ikki o‘zgaruvchining juft o‘lchovlari orasidagi bog‘lanish uchun ishlatiladi. Bu yerda esa bitta o‘zgaruvchining ikkita alohida taqsimoti taqqoslanadi.',
  'draft','pending','pending','pending'
),
(
  8907,15607,1,'aw02-v1','mcq',
  'Why must the value 3.1 appear twice in the stem-and-leaf diagram?',
  'Почему значение 3,1 должно быть записано в диаграмме «стебель-лист» два раза?',
  'Nega 3.1 qiymati poya-barg diagrammasida ikki marta yozilishi kerak?',
  '["Because every stem must contain at least two leaves","Because a stem-and-leaf diagram preserves every observation, including repeated values","Because 3.1 is the median","Because decimal observations are always duplicated"]',
  '["Потому что у каждого стебля должно быть не менее двух листьев","Потому что диаграмма «стебель-лист» сохраняет каждое наблюдение, включая повторяющиеся значения","Потому что 3,1 является медианой","Потому что десятичные наблюдения всегда записывают дважды"]',
  '["Chunki har bir poyada kamida ikkita barg bo‘lishi kerak","Chunki poya-barg diagrammasi har bir kuzatuvni, shu jumladan takrorlangan qiymatlarni ham saqlaydi","Chunki 3.1 mediana","Chunki o‘nli kuzatuvlar har doim ikki marta yoziladi"]',
  1,
  'A stem-and-leaf display retains the original observations. If a value occurs twice, its leaf must also occur twice.',
  'Диаграмма «стебель-лист» сохраняет исходные наблюдения. Если значение встречается дважды, соответствующий лист тоже должен появиться дважды.',
  'Poya-barg diagrammasi dastlabki kuzatuvlarni saqlaydi. Qiymat ikki marta uchrasa, uning bargi ham ikki marta ko‘rsatiladi.',
  'draft','pending','pending','pending'
),
(
  8908,15608,1,'aw02-v1','mcq',
  'Why is frequency density used as histogram height when class widths are unequal?',
  'Почему при неравных ширинах интервалов высотой столбца гистограммы служит плотность частоты?',
  'Nega interval kengliklari teng bo‘lmaganda gistogramma ustunining balandligi sifatida chastota zichligi ishlatiladi?',
  '["So every bar has the same width","So bar area represents frequency: width × density = frequency","So the tallest bar always has the largest class width","So the horizontal axis can be ignored"]',
  '["Чтобы все столбцы имели одинаковую ширину","Чтобы площадь столбца представляла частоту: ширина × плотность = частота","Чтобы самый высокий столбец всегда имел самый широкий интервал","Чтобы горизонтальную ось можно было не учитывать"]',
  '["Barcha ustunlar bir xil kenglikda bo‘lishi uchun","Ustun yuzasi chastotani ifodalashi uchun: kenglik × zichlik = chastota","Eng baland ustun doim eng keng intervalga ega bo‘lishi uchun","Gorizontal o‘qni hisobga olmaslik uchun"]',
  1,
  'Histogram area, not raw height, represents frequency. Density adjusts the height so width × density equals frequency.',
  'В гистограмме частоту представляет площадь, а не сама высота. Плотность корректирует высоту так, чтобы ширина × плотность = частота.',
  'Gistogrammada chastotani oddiy balandlik emas, yuza ifodalaydi. Zichlik balandlikni shunday moslaydiki, kenglik × zichlik = chastota.',
  'draft','pending','pending','pending'
),
(
  8909,15609,1,'aw02-v1','mcq',
  'Why can the mean be greater than both the median and mode in this frequency distribution?',
  'Почему среднее может быть больше и медианы, и моды в этой таблице частот?',
  'Nega bu chastota taqsimotida o‘rtacha qiymat mediana va modadan kattaroq bo‘lishi mumkin?',
  '["Because the values 3 and 4 contribute to the total and pull the arithmetic mean upward while the middle and most frequent position remain at 2","Because the mean is always the largest measure","Because the median ignores all values above 2","Because the mode is calculated by averaging the two largest values"]',
  '["Потому что значения 3 и 4 входят в сумму и повышают среднее, тогда как срединное положение и наиболее частое значение остаются равны 2","Потому что среднее всегда является самой большой мерой","Потому что медиана игнорирует все значения больше 2","Потому что моду вычисляют как среднее двух наибольших значений"]',
  '["Chunki 3 va 4 qiymatlari yig‘indiga qo‘shilib arifmetik o‘rtachani yuqoriga tortadi, markaziy o‘rin va eng ko‘p uchraydigan qiymat esa 2 bo‘lib qoladi","Chunki o‘rtacha har doim eng katta ko‘rsatkich","Chunki mediana 2 dan katta barcha qiymatlarni e’tiborsiz qoldiradi","Chunki moda eng katta ikki qiymatning o‘rtachasi sifatida hisoblanadi"]',
  0,
  'The mean uses every value with its frequency. The observations at 3 and 4 raise the total, while positions 6 and 7 and the highest frequency are still at value 2.',
  'Среднее учитывает каждое значение с его частотой. Наблюдения 3 и 4 увеличивают сумму, тогда как 6-е и 7-е места и максимальная частота по-прежнему соответствуют значению 2.',
  'O‘rtacha har bir qiymatni uning chastotasi bilan hisobga oladi. 3 va 4 qiymatlari yig‘indini oshiradi, 6- va 7-o‘rinlar hamda eng katta chastota esa 2 qiymatida qoladi.',
  'draft','pending','pending','pending'
)
on conflict (id) do nothing;

do $postcheck$
declare
  v_bad int;
begin
  if (select count(*) from private.exam_prep_written_understanding_checks
      where id between 8901 and 8909
        and written_task_id between 15601 and 15609
        and lifecycle_state='draft'
        and qa_math_status='pending'
        and qa_language_status='pending'
        and qa_technical_status='pending')<>9
  then
    raise exception 'aw01_04_written_checks_draft cardinality/state mismatch';
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  where c.id between 8901 and 8909
    and (
      jsonb_array_length(c.options_en)<>4
      or jsonb_array_length(c.options_ru)<>4
      or jsonb_array_length(c.options_uz)<>4
      or c.correct_index not between 0 and 3
      or nullif(btrim(c.prompt_en),'') is null
      or nullif(btrim(c.prompt_ru),'') is null
      or nullif(btrim(c.prompt_uz),'') is null
      or nullif(btrim(c.rationale_en),'') is null
      or nullif(btrim(c.rationale_ru),'') is null
      or nullif(btrim(c.rationale_uz),'') is null
    );
  if v_bad<>0 then
    raise exception 'aw01_04_written_checks_draft structural/trilingual invalid=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_written_understanding_checks c
    where c.id between 8901 and 8909
      and c.lifecycle_state in ('approved','published')
  ) then
    raise exception 'aw01_04_written_checks_draft accidentally approved/published';
  end if;
end
$postcheck$;

commit;
