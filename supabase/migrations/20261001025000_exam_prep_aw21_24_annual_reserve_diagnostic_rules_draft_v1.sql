-- AW21-24 annual-reserve diagnostic misconception rules draft v1.
-- DRAFT ONLY. Exactly three wrong-option rules per diagnostic item.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
 if (select count(*) from private.exam_prep_question_content_meta
     where content_version_id in (4823,4824) and lifecycle_state='draft' and reserve_role='diagnostic')<>36
 then raise exception 'aw21_24_annual_reserve_rules: diagnostic draft surface missing'; end if;
 if exists(select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
   where m.content_version_id in (4823,4824) and m.reserve_role='diagnostic'
     and (q.qtype<>'mcq' or q.correct_answer not in ('A','B','C','D')))
 then raise exception 'aw21_24_annual_reserve_rules: diagnostic item is not a four-option MCQ'; end if;
end
$preflight$;

with skill_feedback(skill_code,mistake_type,feedback_en,feedback_ru,feedback_uz,next_en,next_ru,next_uz) as (values
('P1-COO-05','line_circle','Your choice does not preserve the line–circle geometry or the algebraic substitution correctly.','Выбранный вариант неверно сохраняет геометрию прямой и окружности или алгебраическую подстановку.','Tanlangan javob chiziq–aylana geometriyasini yoki algebraik qo‘yishni noto‘g‘ri saqlaydi.','Write the circle in centre-radius form when useful, then substitute the line equation and solve the resulting quadratic carefully.','При необходимости приведите окружность к форме с центром и радиусом, затем подставьте уравнение прямой и аккуратно решите полученное квадратное уравнение.','Kerak bo‘lsa aylanani markaz-radius ko‘rinishiga keltiring, so‘ng chiziq tenglamasini qo‘yib hosil bo‘lgan kvadrat tenglamani ehtiyotkor yeching.'),
('P1-COO-06','tangency','Your choice does not use the one-point tangency condition correctly.','Выбранный вариант неверно использует условие касания в одной точке.','Tanlangan javob bitta nuqtadagi urinma shartini noto‘g‘ri qo‘llaydi.','After substitution, tangency means the quadratic has one repeated real root, so set its discriminant to zero; a centre-to-line distance check is an equivalent route when convenient.','После подстановки касание означает один кратный действительный корень, поэтому приравняйте дискриминант к нулю; при необходимости эквивалентно можно использовать расстояние от центра до прямой.','Qo‘yishdan keyin urinma kvadrat tenglamaning bitta takroriy haqiqiy ildizga ega bo‘lishini bildiradi, shuning uchun diskriminantni nolga tenglang; qulay bo‘lsa markazdan chiziqqacha masofadan ham foydalanish mumkin.'),
('P1-DIF-05','derivative_sign','Your choice confuses the sign of the derivative with the value of the function.','Выбранный вариант смешивает знак производной со значением самой функции.','Tanlangan javob hosila ishorasini funksiya qiymati bilan aralashtiradi.','Find where f′(x)=0, split the number line at those points, and test the sign of f′ on each interval: positive means increasing, negative means decreasing.','Найдите точки f′(x)=0, разделите числовую прямую этими точками и проверьте знак f′ на каждом интервале: положительный — возрастание, отрицательный — убывание.','f′(x)=0 nuqtalarni toping, son o‘qini shu nuqtalarda bo‘ling va har oraliqda f′ ishorasini tekshiring: musbat — o‘sish, manfiy — kamayish.'),
('P1-DIF-06','connected_rates','Your choice drops the chain-rule link, a sign, or the required units in a connected-rates calculation.','Выбранный вариант теряет связь по правилу цепочки, знак или требуемые единицы в задаче на связанные скорости.','Tanlangan javob bog‘langan tezliklar masalasida zanjir qoidasi bog‘lanishini, ishorani yoki kerakli birliklarni yo‘qotadi.','Differentiate the geometric relation with respect to time and substitute the instantaneous values only after the rate equation is formed. Keep the sign and units.','Продифференцируйте геометрическую связь по времени и подставляйте текущие значения только после получения уравнения скоростей. Сохраняйте знак и единицы.','Geometrik bog‘lanishni vaqt bo‘yicha differensiallang va joriy qiymatlarni faqat tezliklar tenglamasi hosil bo‘lgandan keyin qo‘ying. Ishora va birliklarni saqlang.'),
('P1-DIF-07','stationary_points','Your choice does not distinguish a stationary point from its nature or optimisation meaning.','Выбранный вариант не различает стационарную точку, её характер и смысл в задаче оптимизации.','Tanlangan javob statsionar nuqta, uning turi va optimallashtirishdagi ma’nosini farqlamaydi.','Solve f′(x)=0 first. Then use a derivative sign change or f″ to classify each point, and check any domain restriction before selecting an optimum.','Сначала решите f′(x)=0. Затем используйте смену знака производной или f″ для классификации точки и проверьте ограничения области перед выбором оптимума.','Avval f′(x)=0 ni yeching. Keyin hosila ishorasi o‘zgarishi yoki f″ orqali nuqtani tasniflang va optimal qiymatni tanlashdan oldin soha cheklovlarini tekshiring.'),
('P1-INT-01','antiderivative','Your choice applies the power rule or the inner linear factor incorrectly when integrating.','Выбранный вариант неверно применяет правило степени или учитывает внутренний линейный множитель при интегрировании.','Tanlangan javob integrallashda daraja qoidasini yoki ichki chiziqli ko‘paytuvchini noto‘g‘ri qo‘llaydi.','For x^n, increase the power by 1 and divide by the new power. For (ax+b)^n, also divide by the inner derivative a. Differentiate your result to check it.','Для x^n увеличьте степень на 1 и разделите на новую степень. Для (ax+b)^n дополнительно разделите на внутреннюю производную a. Проверьте ответ дифференцированием.','x^n uchun darajani 1 ga oshirib yangi darajaga bo‘ling. (ax+b)^n uchun ichki hosila a ga ham bo‘ling. Javobni differensiallab tekshiring.'),
('P1-INT-02','integration_constant','Your choice does not use the point or boundary condition to determine the constant of integration correctly.','Выбранный вариант неверно использует заданную точку или граничное условие для нахождения константы интегрирования.','Tanlangan javob integrallash doimiysini topishda berilgan nuqta yoki chegara shartidan noto‘g‘ri foydalanadi.','Integrate first and keep +C. Substitute the given point or boundary value into the full antiderivative, solve for C, then evaluate any requested value.','Сначала проинтегрируйте и сохраните +C. Подставьте заданную точку или граничное значение в полную первообразную, найдите C и только затем вычисляйте требуемое значение.','Avval integrallab +C ni saqlang. Berilgan nuqta yoki chegara qiymatini to‘liq boshlang‘ich funksiyaga qo‘yib C ni toping, keyin so‘ralgan qiymatni hisoblang.'),
('P1-INT-03','definite_integral','Your choice does not evaluate the antiderivative at the limits in the correct order or mishandles an endpoint limit.','Выбранный вариант неверно подставляет пределы в первообразную или неправильно обрабатывает предел в особой конечной точке.','Tanlangan javob boshlang‘ich funksiyada chegaralarni noto‘g‘ri tartibda qo‘llaydi yoki chekka nuqtadagi limitni noto‘g‘ri ishlatadi.','Find an antiderivative F and calculate F(upper)−F(lower). If an endpoint is improper, replace it by a one-sided limit before evaluating.','Найдите первообразную F и вычислите F(верхняя граница)−F(нижняя граница). Если конечная точка особая, сначала замените её односторонним пределом.','Boshlang‘ich funksiya F ni topib F(yuqori chegara)−F(pastki chegara) ni hisoblang. Chekka nuqta xosmas bo‘lsa, avval uni bir tomonlama limit bilan almashtiring.'),
('P1-INT-04','area_integration','Your choice treats a signed integral as total geometric area or uses the wrong upper-minus-lower curve.','Выбранный вариант принимает знаковый интеграл за полную геометрическую площадь или неверно выбирает верхнюю и нижнюю кривые.','Tanlangan javob ishorali integralni umumiy geometrik yuza deb oladi yoki yuqori va pastki egri chiziqlarni noto‘g‘ri tanlaydi.','Find all relevant intersections or sign changes. Split the interval where necessary and integrate a positive vertical gap on each piece.','Найдите все нужные точки пересечения или смены знака. При необходимости разбейте интервал и на каждом участке интегрируйте положительный вертикальный зазор.','Kerakli kesishish yoki ishora o‘zgarish nuqtalarini toping. Zarur bo‘lsa oraliqni bo‘ling va har bo‘lakda musbat vertikal farqni integrallang.'),
('P1-INT-05','volume_revolution','Your choice uses an area formula instead of the disk-volume model or squares the wrong quantity.','Выбранный вариант использует формулу площади вместо модели объёма дисков или возводит в квадрат неверную величину.','Tanlangan javob disk hajmi modeli o‘rniga yuza formulasini ishlatadi yoki noto‘g‘ri kattalikni kvadratga oshiradi.','For rotation about the x-axis, use V=π∫y² dx with correct limits. Identify the radius of each cross-sectional disk before squaring it.','При вращении вокруг оси x используйте V=π∫y² dx с правильными пределами. Перед возведением в квадрат определите радиус каждого дискового сечения.','x-o‘qi atrofida aylantirishda V=π∫y² dx ni to‘g‘ri chegaralar bilan ishlating. Kvadratga oshirishdan oldin har disk kesimining radiusini aniqlang.'),
('P5-DAT-08','compare_data','Your choice mixes up a measure of location with a measure of spread or makes a conclusion not supported by the summaries.','Выбранный вариант смешивает показатель положения с показателем разброса или делает вывод, который не подтверждается сводными данными.','Tanlangan javob markaz ko‘rsatkichini tarqalish ko‘rsatkichi bilan aralashtiradi yoki berilgan xulosalardan ortiq da’vo qiladi.','Compare medians or means for location and IQR/range/standard deviation for spread separately, then state only the contextual conclusion supported by those measures.','Сравнивайте медианы или средние для положения и IQR/размах/стандартное отклонение для разброса отдельно, затем делайте только подтверждённый ими контекстный вывод.','Markaz uchun mediana yoki o‘rtachani, tarqalish uchun IQR/diapazon/standart og‘ishni alohida taqqoslang, so‘ng faqat shu ko‘rsatkichlar tasdiqlaydigan kontekstli xulosani ayting.'),
('P5-DAT-09','summary_measures','Your choice confuses the mean, variance and standard deviation or substitutes the wrong summary total.','Выбранный вариант смешивает среднее, дисперсию и стандартное отклонение или подставляет неверную сводную сумму.','Tanlangan javob o‘rtacha, dispersiya va standart og‘ishni aralashtiradi yoki noto‘g‘ri yig‘indi qiymatini qo‘yadi.','Compute x̄=Σx/n first. Then use variance=Σx²/n−x̄²; take the positive square root only if standard deviation is requested.','Сначала вычислите x̄=Σx/n. Затем используйте дисперсию Σx²/n−x̄²; положительный квадратный корень берите только если требуется стандартное отклонение.','Avval x̄=Σx/n ni hisoblang. Keyin dispersiya=Σx²/n−x̄² dan foydalaning; faqat standart og‘ish so‘ralsa musbat kvadrat ildiz oling.'),
('P5-DAT-10','coded_combined','Your choice combines group means without weighting or applies a coding transformation in the wrong direction.','Выбранный вариант объединяет средние без учёта размеров групп или применяет кодирование в неверном направлении.','Tanlangan javob guruh o‘rtachalarini hajmlar bilan og‘irlamaydi yoki kodlash o‘zgarishini noto‘g‘ri yo‘nalishda qo‘llaydi.','Recover totals as group size × mean before combining groups. For linear coding, apply the same linear transformation to the mean and reverse it carefully when required.','Перед объединением групп восстановите суммы как размер группы × среднее. Для линейного кодирования применяйте то же линейное преобразование к среднему и аккуратно обращайте его при необходимости.','Guruhlarni birlashtirishdan oldin yig‘indini guruh hajmi × o‘rtacha sifatida toping. Chiziqli kodlashda o‘rtachaga ham shu o‘zgarishni qo‘llang va kerak bo‘lsa uni ehtiyotkorlik bilan teskarilang.'),
('P5-NOR-02','normal_standardise','Your choice confuses variance with standard deviation or standardises with the wrong sign/tail.','Выбранный вариант смешивает дисперсию со стандартным отклонением или стандартизует с неверным знаком/хвостом.','Tanlangan javob dispersiyani standart og‘ish bilan aralashtiradi yoki noto‘g‘ri ishora/dum bilan standartlaydi.','In N(μ,σ²), take σ as the positive square root of the second parameter, then use z=(x−μ)/σ. Sketch or identify the required tail before reading a probability.','В N(μ,σ²) возьмите σ как положительный квадратный корень из второго параметра, затем используйте z=(x−μ)/σ. Перед чтением вероятности определите нужный хвост.','N(μ,σ²) da σ ni ikkinchi parametrning musbat kvadrat ildizi sifatida oling, keyin z=(x−μ)/σ dan foydalaning. Ehtimolni o‘qishdan oldin kerakli dumni aniqlang.'),
('P5-NOR-03','normal_probability','Your choice uses the wrong complement, symmetry relation or interval subtraction for a normal probability.','Выбранный вариант неверно использует дополнение, симметрию или вычитание вероятностей для нормального распределения.','Tanlangan javob normal ehtimolda to‘ldiruvchi hodisa, simmetriya yoki oraliq ayirmasini noto‘g‘ri qo‘llaydi.','Mark the target region first. Use 1−Φ(z) for an upper tail, Φ(b)−Φ(a) for an interval, and Φ(−z)=1−Φ(z) for symmetry.','Сначала отметьте нужную область. Для верхнего хвоста используйте 1−Φ(z), для интервала Φ(b)−Φ(a), а для симметрии Φ(−z)=1−Φ(z).','Avval kerakli sohani belgilang. Yuqori dum uchun 1−Φ(z), oraliq uchun Φ(b)−Φ(a), simmetriya uchun Φ(−z)=1−Φ(z) dan foydalaning.'),
('P5-NOR-04','normal_quantile','Your choice uses the wrong percentile z-value or forgets to convert back from z to x.','Выбранный вариант использует неверное z-значение процентиля или забывает перейти обратно от z к x.','Tanlangan javob percentilning noto‘g‘ri z-qiymatini ishlatadi yoki z dan x ga qaytishni unutadi.','Translate the percentile to its z-value, using a negative z for a lower percentile when appropriate, then use x=μ+zσ.','Переведите процентиль в z-значение, используя отрицательное z для нижнего процентиля при необходимости, затем примените x=μ+zσ.','Percentilni z-qiymatga aylantiring, kerak bo‘lsa pastki percentil uchun manfiy z ishlating, keyin x=μ+zσ ni qo‘llang.'),
('P5-NOR-05','normal_parameters','Your choice does not convert probability conditions into the correct equations for μ and σ.','Выбранный вариант неверно преобразует вероятностные условия в уравнения для μ и σ.','Tanlangan javob ehtimol shartlarini μ va σ uchun to‘g‘ri tenglamalarga aylantirmaydi.','Convert each stated probability to a z-value and write x=μ+zσ. Use two independent conditions simultaneously when both μ and σ are unknown.','Каждое вероятностное условие переведите в z-значение и запишите x=μ+zσ. Если неизвестны и μ, и σ, решайте два независимых условия совместно.','Har bir ehtimol shartini z-qiymatga aylantirib x=μ+zσ ni yozing. μ va σ ikkalasi noma’lum bo‘lsa, ikki mustaqil shartni birga yeching.'),
('P5-NOR-06','normal_approximation','Your choice uses the wrong binomial mean/variance or applies continuity correction in the wrong direction.','Выбранный вариант использует неверные среднее/дисперсию биномиального распределения или неправильно применяет поправку на непрерывность.','Tanlangan javob binomial taqsimotning o‘rtacha/dispersiyasini yoki uzluksizlik tuzatishi yo‘nalishini noto‘g‘ri qo‘llaydi.','Check that a normal approximation is appropriate, use μ=np and variance=np(1−p), then move each integer boundary by 0.5 in the direction that represents the same discrete event before standardising.','Проверьте применимость нормального приближения, используйте μ=np и дисперсию np(1−p), затем перед стандартизацией сдвиньте каждую целую границу на 0,5 так, чтобы сохранить то же дискретное событие.','Normal yaqinlashuv mosligini tekshiring, μ=np va dispersiya=np(1−p) ni ishlating, so‘ng standartlashdan oldin har butun chegarani shu diskret hodisani saqlaydigan yo‘nalishda 0.5 ga siljiting.')
), letters(answer_match) as (values ('A'),('B'),('C'),('D'))
insert into private.exam_prep_diagnostic_rules(
 content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,
 feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status
)
select m.id,'aw_reserve_v1','mcq_option',l.answer_match,
       replace(lower(m.content_key),'-','_')||'_wrong_'||lower(l.answer_match),
       sf.mistake_type,m.primary_skill_code,
       sf.feedback_en,sf.feedback_ru,sf.feedback_uz,sf.next_en,sf.next_ru,sf.next_uz,'draft'
from private.exam_prep_question_content_meta m
join public.questions qn on qn.id=m.question_id
join skill_feedback sf on sf.skill_code=m.primary_skill_code
cross join letters l
where m.content_version_id in (4823,4824)
  and m.reserve_role='diagnostic'
  and qn.qtype='mcq'
  and l.answer_match<>qn.correct_answer
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

do $postcheck$
declare v_bad int;
begin
 if (select count(*) from private.exam_prep_diagnostic_rules r
     join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
     where m.content_version_id in (4823,4824) and r.rule_version='aw_reserve_v1')<>108
 then raise exception 'aw21_24_annual_reserve_rules: expected 108 draft rules'; end if;

 select count(*) into v_bad
 from private.exam_prep_question_content_meta m
 join public.questions qn on qn.id=m.question_id
 where m.content_version_id in (4823,4824)
   and m.reserve_role='diagnostic'
   and (
     qn.qtype<>'mcq'
     or (select count(*) from private.exam_prep_diagnostic_rules r
         where r.content_meta_id=m.id and r.rule_version='aw_reserve_v1'
           and r.status='draft' and r.answer_kind='mcq_option'
           and r.answer_match<>qn.correct_answer
           and r.weak_skill_code=m.primary_skill_code
           and nullif(btrim(r.feedback_en),'') is not null
           and nullif(btrim(r.feedback_ru),'') is not null
           and nullif(btrim(r.feedback_uz),'') is not null
           and nullif(btrim(r.next_action_en),'') is not null
           and nullif(btrim(r.next_action_ru),'') is not null
           and nullif(btrim(r.next_action_uz),'') is not null)<>3
   );
 if v_bad<>0 then raise exception 'aw21_24_annual_reserve_rules: invalid diagnostic rule rows=%',v_bad; end if;

 if exists(select 1 from private.exam_prep_diagnostic_rules r
   join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
   where m.content_version_id in (4823,4824)
     and (r.feedback_en=r.feedback_ru or r.feedback_en=r.feedback_uz or r.next_action_en=r.next_action_ru or r.next_action_en=r.next_action_uz))
 then raise exception 'aw21_24_annual_reserve_rules: untranslated rule text detected'; end if;
end
$postcheck$;

commit;
