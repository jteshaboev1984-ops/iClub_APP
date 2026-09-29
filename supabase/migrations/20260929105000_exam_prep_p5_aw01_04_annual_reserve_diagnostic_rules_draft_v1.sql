-- Draft diagnostic misconception rules for P5 AW1-4 annual-reserve variants.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4804
        and reserve_role='diagnostic'
        and lifecycle_state='draft'
        and diagnostic_rule_status='pending')<>8 then
    raise exception 'aw01_04_annual_reserve_p5_rules: expected 8 draft diagnostics';
  end if;
end
$preflight$;

with rules(content_key,answer_match,distractor_code,mistake_type,weak_skill_code,
           feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz) as (values
('P5DAT01-D02','B','cumulative_frequency_for_shape','model_selection','P5-DAT-01','A cumulative-frequency graph is useful for medians, quartiles and proportions, but it does not show modal regions or distribution shape as directly as a histogram.','График накопленных частот удобен для медианы, квартилей и долей, но хуже показывает форму распределения и модальные области, чем гистограмма.','Yig‘ma chastota grafigi mediana, kvartillar va ulushlar uchun qulay, ammo taqsimot shakli va modal oraliqlarni gistogrammadek bevosita ko‘rsatmaydi.','Match the display to the goal: here the goal is shape and modal regions of grouped continuous data.','Сопоставьте график с целью: здесь нужно увидеть форму и модальные области сгруппированных непрерывных данных.','Tasvirni maqsadga moslang: bu yerda guruhlangan uzluksiz ma’lumotlarning shakli va modal oraliqlari kerak.'),
('P5DAT01-D02','C','categorical_display_for_continuous_data','model_selection','P5-DAT-01','A pie chart is for categorical part-to-whole proportions, not the shape of grouped continuous measurements.','Круговая диаграмма предназначена для долей категорий, а не для формы распределения сгруппированных непрерывных измерений.','Doiraviy diagramma kategoriyalar ulushi uchun, guruhlangan uzluksiz o‘lchovlar taqsimoti shakli uchun emas.','Identify whether the variable is categorical or continuous before choosing the display.','Перед выбором графика определите, является переменная категориальной или непрерывной.','Tasvirni tanlashdan oldin o‘zgaruvchi kategoriyali yoki uzluksiz ekanini aniqlang.'),
('P5DAT01-D02','D','scatter_for_single_distribution','model_selection','P5-DAT-01','A scatter plot needs paired numerical variables. Here there is one continuous variable grouped into intervals.','Диаграмме рассеяния нужны пары числовых переменных. Здесь одна непрерывная переменная, сгруппированная по интервалам.','Tarqalish diagrammasi juft sonli o‘zgaruvchilar uchun. Bu yerda bitta uzluksiz o‘zgaruvchi oraliqlarga guruhlangan.','Use scatter plots for association between two paired numerical variables.','Используйте диаграмму рассеяния для связи между двумя парными числовыми переменными.','Tarqalish diagrammasini ikkita juft sonli o‘zgaruvchi orasidagi bog‘lanish uchun ishlating.'),
('P5DAT01-D03','A','boxplot_for_bivariate_association','model_selection','P5-DAT-01','A box-and-whisker plot summarises one numerical distribution; it does not show paired height–arm-span relationships.','Диаграмма размаха суммирует одно числовое распределение и не показывает парную связь роста и размаха рук.','Quti va mo‘ylov diagrammasi bitta sonli taqsimotni umumlashtiradi; bo‘y va qo‘l kengligi juft bog‘lanishini ko‘rsatmaydi.','For association, keep each student’s pair of numerical values together.','Для исследования связи сохраняйте пару числовых значений каждого ученика.','Bog‘lanishni tekshirishda har bir o‘quvchining ikki sonli qiymatini juft holda saqlang.'),
('P5DAT01-D03','B','stemleaf_for_bivariate_association','model_selection','P5-DAT-01','A stem-and-leaf diagram shows one distribution and does not preserve the pairing between two variables.','Стебле-листовая диаграмма показывает одно распределение и не сохраняет пары двух переменных.','Poya-barg diagrammasi bitta taqsimotni ko‘rsatadi va ikki o‘zgaruvchi orasidagi juftlikni saqlamaydi.','Choose a display that plots each paired observation as one point.','Выберите график, где каждая пара наблюдений представлена одной точкой.','Har bir juft kuzatuv bitta nuqta sifatida ko‘rsatiladigan tasvirni tanlang.'),
('P5DAT01-D03','D','pie_for_bivariate_association','model_selection','P5-DAT-01','A pie chart shows categorical proportions, not association between two numerical measurements.','Круговая диаграмма показывает доли категорий, а не связь между двумя числовыми измерениями.','Doiraviy diagramma kategoriyalar ulushini ko‘rsatadi, ikki sonli o‘lchov orasidagi bog‘lanishni emas.','Use a scatter plot when both variables are numerical and paired.','Если обе переменные числовые и парные, используйте диаграмму рассеяния.','Har ikkala o‘zgaruvchi sonli va juft bo‘lsa, tarqalish diagrammasidan foydalaning.'),
('P5DAT02-D02','A','decimal_place_lost','representation','P5-DAT-02','The key 7 | 3 = 7.3 shows that the leaf is tenths, so 6 | 5 is 6.5, not 65.','Ключ 7 | 3 = 7,3 показывает, что лист задаёт десятые, поэтому 6 | 5 означает 6,5, а не 65.','7 | 3 = 7.3 kaliti barg o‘ndan birlarni bildirishini ko‘rsatadi, demak 6 | 5 = 6.5, 65 emas.','Read the key before combining a stem and leaf.','Всегда прочитайте ключ перед объединением стебля и листа.','Poya va bargni birlashtirishdan oldin kalitni o‘qing.'),
('P5DAT02-D02','C','decimal_scale_too_small','representation','P5-DAT-02','6 | 5 is 6.5 under this key; placing the leaf in the hundredths position gives the wrong scale.','При этом ключе 6 | 5 означает 6,5; помещение листа в сотые даёт неверный масштаб.','Bu kalitda 6 | 5 = 6.5; bargni yuzdan birlar o‘rniga qo‘yish noto‘g‘ri masshtab beradi.','Use the example key to identify exactly which place value the leaf represents.','По примеру в ключе определите точный разряд, который представляет лист.','Kalitdagi misoldan barg aynan qaysi xona qiymatini bildirishini aniqlang.'),
('P5DAT02-D02','D','stem_leaf_decimal_concatenation_error','representation','P5-DAT-02','The stem is the units part and the leaf is the tenths part, so 6 | 5 cannot mean 6.05.','Стебель задаёт единицы, а лист — десятые, поэтому 6 | 5 не может означать 6,05.','Poya birlik qismini, barg esa o‘ndan bir qismini beradi, shuning uchun 6 | 5 = 6.05 bo‘la olmaydi.','Translate the key 7 | 3 = 7.3 to the new stem and leaf without changing place value.','Перенесите правило ключа 7 | 3 = 7,3 на новый стебель и лист, не меняя разряд.','7 | 3 = 7.3 kalit qoidasini yangi poya va bargga xona qiymatini o‘zgartirmasdan qo‘llang.'),
('P5DAT02-D03','A','duplicate_misplaced_between_stems','representation','P5-DAT-02','Both 4.3 observations belong as two leaves 3 on stem 4; one of them cannot be moved to stem 5.','Оба значения 4,3 должны быть двумя листьями 3 при стебле 4; одно из них нельзя переносить к стеблю 5.','Har ikkala 4.3 qiymat ham 4 poyada ikkita 3 barg sifatida yoziladi; bittasini 5 poyaga ko‘chirib bo‘lmaydi.','Place every observation using the key, preserving duplicates exactly.','Размещайте каждое наблюдение по ключу и точно сохраняйте повторения.','Har bir kuzatuvni kalit bo‘yicha joylashtiring va takrorlarni aynan saqlang.'),
('P5DAT02-D03','B','invented_leaf_value','representation','P5-DAT-02','The leaf 5 on stem 4 would represent 4.5, which is not in the data.','Лист 5 при стебле 4 означал бы 4,5, которого нет в данных.','4 poyadagi 5 barg 4.5 ni bildiradi, bunday qiymat ma’lumotlarda yo‘q.','Reconstruct the values from each proposed row and compare them with the original list.','Восстановите значения из каждого варианта и сравните с исходным списком.','Har bir variantdagi qiymatlarni tiklab, asl ro‘yxat bilan solishtiring.'),
('P5DAT02-D03','C','five_point_zero_on_wrong_stem','representation','P5-DAT-02','5.0 must be written as stem 5 with leaf 0, not as leaf 0 on stem 4.','5,0 нужно записать как стебель 5 с листом 0, а не как лист 0 при стебле 4.','5.0 qiymat 5 poya va 0 barg sifatida yoziladi, 4 poyadagi 0 barg sifatida emas.','Use the stem for the units part and the leaf for the tenths part.','Используйте стебель для целой части, а лист — для десятых.','Poyani butun qism, bargni esa o‘ndan bir qism uchun ishlating.'),
('P5DAT04-D02','A','frequency_minus_width','method','P5-DAT-04','Frequency density is a ratio, not frequency minus class width. Here it is 30÷5.','Плотность частоты — это отношение, а не частота минус ширина интервала. Здесь нужно 30÷5.','Chastota zichligi ayirma emas, nisbatdir. Bu yerda 30÷5 hisoblanadi.','Write frequency density = frequency ÷ class width before substituting values.','Сначала запишите: плотность частоты = частота ÷ ширина интервала.','Avval chastota zichligi = chastota ÷ sinf kengligi formulasini yozing.'),
('P5DAT04-D02','B','frequency_times_width','method','P5-DAT-04','Multiplying 30 by 5 gives an area-like product, but histogram height is frequency divided by class width.','Умножение 30 на 5 даёт неверное значение; высота столбца равна частоте, делённой на ширину интервала.','30 ni 5 ga ko‘paytirish noto‘g‘ri; gistogramma balandligi chastotaning sinf kengligiga bo‘linganiga teng.','Use division to find height; multiplication is used to recover frequency from density and width.','Для высоты используйте деление; умножение применяется, когда по плотности и ширине восстанавливают частоту.','Balandlikni topishda bo‘lishdan foydalaning; ko‘paytirish zichlik va kenglikdan chastotani tiklashda ishlatiladi.'),
('P5DAT04-D02','D','density_reciprocal','method','P5-DAT-04','1/6 is the reciprocal of the required density. The correct ratio is frequency ÷ width.','1/6 — это обратная величина к нужной плотности. Нужное отношение: частота ÷ ширина.','1/6 kerakli zichlikning teskarisi. To‘g‘ri nisbat chastota ÷ kenglik.','Check the formula order and the units before calculating.','Проверьте порядок величин в формуле и единицы.','Hisoblashdan oldin formuladagi tartib va birliklarni tekshiring.'),
('P5DAT04-D03','A','added_width_and_density','method','P5-DAT-04','Frequency is found by multiplying class width by frequency density, not adding them.','Частота находится умножением ширины интервала на плотность частоты, а не их сложением.','Chastota sinf kengligi bilan chastota zichligini qo‘shish orqali emas, ko‘paytirish orqali topiladi.','Use frequency = class width × frequency density.','Используйте: частота = ширина интервала × плотность частоты.','Chastota = sinf kengligi × chastota zichligi formulasidan foydalaning.'),
('P5DAT04-D03','B','class_b_frequency_arithmetic','method','P5-DAT-04','For class B the frequency is 6×2=12, not 8.','Для интервала B частота равна 6×2=12, а не 8.','B sinf uchun chastota 6×2=12, 8 emas.','Calculate each bar area separately before comparing frequencies.','Сначала вычислите площадь каждого столбца, затем сравните частоты.','Chastotalarni solishtirishdan oldin har bir ustun yuzasini alohida hisoblang.'),
('P5DAT04-D03','C','height_confused_with_frequency','concept','P5-DAT-04','Class A is taller, but it is narrower. Frequency is represented by bar area, and both areas are 12.','Столбец A выше, но уже. Частоту представляет площадь столбца, и обе площади равны 12.','A ustun balandroq, lekin torroq. Chastotani ustun yuzi ifodalaydi va ikkala yuza ham 12.','Compare width × height, not height alone, when class widths differ.','При разных ширинах интервалов сравнивайте ширина × высота, а не только высоту.','Sinf kengliklari turlicha bo‘lsa, faqat balandlikni emas, kenglik × balandlikni solishtiring.'),
('P5DAT06-D02','A','divided_by_number_of_values_not_observations','method','P5-DAT-06','There are three distinct values but six observations. The mean divides the weighted total 11 by 6, not by 3.','Различных значений три, но наблюдений шесть. Среднее — это взвешенная сумма 11, делённая на 6, а не на 3.','Uchta turli qiymat bor, lekin oltita kuzatuv. O‘rtacha og‘irlikli yig‘indi 11 ni 3 ga emas, 6 ga bo‘lish orqali topiladi.','Add the frequencies to get the total number of observations before dividing.','Сложите частоты, чтобы получить общее число наблюдений перед делением.','Bo‘lishdan oldin kuzatuvlar umumiy sonini topish uchun chastotalarni qo‘shing.'),
('P5DAT06-D02','C','median_used_instead_of_mean','concept','P5-DAT-06','2 is the median here, but the question asks for the mean from a frequency table.','2 здесь является медианой, но требуется среднее по таблице частот.','Bu yerda 2 mediana, lekin savolda chastota jadvalidan o‘rtacha so‘ralgan.','Distinguish the requested measure, then use Σxf/Σf for the mean.','Определите требуемую меру и для среднего используйте Σxf/Σf.','Avval qaysi ko‘rsatkich so‘ralganini aniqlang, o‘rtacha uchun Σxf/Σf dan foydalaning.'),
('P5DAT06-D02','D','mean_fraction_inverted','method','P5-DAT-06','6/11 reverses the mean formula. The weighted total is 11 and the number of observations is 6.','6/11 переворачивает формулу среднего. Взвешенная сумма равна 11, число наблюдений — 6.','6/11 o‘rtacha formulasini teskarisiga aylantiradi. Og‘irlikli yig‘indi 11, kuzatuvlar soni 6.','Use weighted total divided by total frequency, not the reciprocal.','Делите взвешенную сумму на общую частоту, а не наоборот.','Og‘irlikli yig‘indini jami chastotaga bo‘ling, teskarisini emas.'),
('P5DAT06-D03','A','lower_middle_only','method','P5-DAT-06','With four observations, the median is the mean of the two middle values, not the lower middle value alone.','При четырёх наблюдениях медиана — среднее двух центральных значений, а не только нижнее из них.','To‘rtta kuzatuvda mediana ikki o‘rta qiymatning o‘rtachasi, faqat pastki o‘rta qiymat emas.','For an even number of ordered values, average the two central observations.','При чётном числе упорядоченных значений найдите среднее двух центральных.','Tartiblangan qiymatlar soni juft bo‘lsa, markazdagi ikkita kuzatuvning o‘rtachasini oling.'),
('P5DAT06-D03','B','upper_middle_only','method','P5-DAT-06','6 is the upper middle value, but the median of four observations averages 5 and 6.','6 — верхнее из двух центральных значений, но медиана четырёх наблюдений равна среднему 5 и 6.','6 yuqori o‘rta qiymat, lekin to‘rtta kuzatuv medianasi 5 va 6 ning o‘rtachasi.','Locate both central positions before calculating the median.','Найдите обе центральные позиции перед вычислением медианы.','Medianani hisoblashdan oldin ikkala markaziy o‘rinni toping.'),
('P5DAT06-D03','D','mean_confused_with_median','concept','P5-DAT-06','8.75 is the arithmetic mean, not the median. The median depends on the two central ordered values.','8,75 — это арифметическое среднее, а не медиана. Медиана определяется двумя центральными упорядоченными значениями.','8.75 arifmetik o‘rtacha, mediana emas. Mediana tartiblangan ma’lumotlarning ikki markaziy qiymatiga bog‘liq.','Choose the requested measure before performing a calculation.','Сначала определите, какая мера требуется, и только затем вычисляйте.','Hisoblashdan oldin qaysi ko‘rsatkich so‘ralganini aniqlang.')
)
insert into private.exam_prep_diagnostic_rules(
  content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,
  feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status
)
select
  m.id,'aw_reserve_v1','mcq_option',r.answer_match,r.distractor_code,r.mistake_type,r.weak_skill_code,
  r.feedback_en,r.feedback_ru,r.feedback_uz,r.next_action_en,r.next_action_ru,r.next_action_uz,'draft'
from rules r
join private.exam_prep_question_content_meta m
  on m.content_version_id=4804
 and m.content_key=r.content_key
 and m.primary_skill_code=r.weak_skill_code
 and m.reserve_role='diagnostic'
join public.questions q on q.id=m.question_id
where r.answer_match<>q.correct_answer
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select count(*)
      from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id=4804 and r.rule_version='aw_reserve_v1')<>24 then
    raise exception 'aw01_04_annual_reserve_p5_rules: expected 24 draft rules';
  end if;

  select count(*) into v_bad
  from private.exam_prep_diagnostic_rules r
  join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
  join public.questions q on q.id=m.question_id
  where m.content_version_id=4804
    and r.rule_version='aw_reserve_v1'
    and (
      r.status<>'draft'
      or r.answer_kind<>'mcq_option'
      or r.answer_match=q.correct_answer
      or r.weak_skill_code<>m.primary_skill_code
      or nullif(btrim(r.feedback_en),'') is null
      or nullif(btrim(r.feedback_ru),'') is null
      or nullif(btrim(r.feedback_uz),'') is null
      or nullif(btrim(r.next_action_en),'') is null
      or nullif(btrim(r.next_action_ru),'') is null
      or nullif(btrim(r.next_action_uz),'') is null
    );
  if v_bad<>0 then
    raise exception 'aw01_04_annual_reserve_p5_rules: invalid rule rows=%',v_bad;
  end if;
end
$postcheck$;

commit;
