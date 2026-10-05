begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>144 then raise exception 'DAT03 expected 144 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DAT-03' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DAT03 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-DAT-03:tutor:en:v2','P5','P5-DAT-03','en','tutor_v2_learner_first','Box-and-whisker plots',
$t$A box-and-whisker plot summarises a data set using five key values: minimum, lower quartile, median, upper quartile and maximum.

Suppose the five-number summary is

4, 7, 10, 15, 20.

The box runs from Q1=7 to Q3=15, with a median line at 10. The whiskers extend to 4 and 20. The interquartile range is

IQR = 15 - 7 = 8.

The plot is especially useful for comparing data sets because the median shows location while the box width shows the spread of the middle half of the data. If a question provides an outlier rule or marks outliers separately, include that information in the interpretation.$t$,
$t$A box plot uses five values:

minimum, Q1, median, Q3, maximum.

For

4, 7, 10, 15, 20,

the box goes from 7 to 15, the median is 10, and the whiskers reach 4 and 20.

The IQR is 15-7=8.

Use the median for location and the IQR for spread.$t$,
$t$Think of a box plot as a compressed map of the ordered data.

The line inside the box marks the middle value. The two sides of the box mark the middle 50% of the observations, from Q1 to Q3. The whiskers show how far the data extend beyond that central half.

This is why box plots are strong for comparison: position and spread are visible at the same time.$t$,
$t$Put the five summary values on the same numerical scale and in the correct order. Do not confuse the box width with the full range: box width represents IQR. When comparing two box plots, discuss both location and spread, not just one feature.$t$,
'p5:P5-DAT-03:theory:en:v1'
),
(
'p5:P5-DAT-03:tutor:ru:v2','P5','P5-DAT-03','ru','tutor_v2_learner_first','Диаграмма размаха',
$t$Box plot кратко описывает набор данных пятью ключевыми значениями: минимумом, нижним квартилем, медианой, верхним квартилем и максимумом.

Пусть эти значения равны

4, 7, 10, 15, 20.

Коробка идёт от Q1=7 до Q3=15, линия медианы находится при 10, а «усы» доходят до 4 и 20. Межквартильный размах:

IQR = 15 - 7 = 8.

Такой график особенно удобен для сравнения наборов: медиана показывает положение, а ширина коробки — разброс средней половины данных. Если в условии дано правило выбросов или выбросы отмечены отдельно, учитывайте это при интерпретации.$t$,
$t$Box plot использует пять значений:

минимум, Q1, медиана, Q3, максимум.

Для

4, 7, 10, 15, 20

коробка идёт от 7 до 15, медиана равна 10, «усы» доходят до 4 и 20.

IQR = 15-7=8.

Медиана показывает положение, IQR — разброс.$t$,
$t$Представьте box plot как сжатую карту упорядоченных данных.

Линия внутри коробки показывает середину. Границы коробки показывают средние 50% наблюдений — от Q1 до Q3. «Усы» показывают, насколько данные продолжаются за этой центральной частью.

Поэтому такой график позволяет одновременно видеть и положение, и разброс.$t$,
$t$Размещайте пять чисел на одной числовой шкале и в правильном порядке. Не путайте ширину коробки с полным размахом: коробка показывает IQR. При сравнении двух box plots обязательно обсуждайте и положение, и разброс.$t$,
'p5:P5-DAT-03:theory:ru:v1'
),
(
'p5:P5-DAT-03:tutor:uz:v2','P5','P5-DAT-03','uz','tutor_v2_learner_first','Quti diagrammasi',
$t$Quti diagrammasi ma’lumotlar to‘plamini beshta asosiy qiymat bilan qisqacha ko‘rsatadi: minimum, quyi kvartil, mediana, yuqori kvartil va maksimum.

Faraz qilaylik, besh sonli xulosa:

4, 7, 10, 15, 20.

Quti Q1=7 dan Q3=15 gacha, mediana chizig‘i 10 da, “mo‘ylovlar” esa 4 va 20 gacha boradi. Kvartillar oralig‘i:

IQR = 15 - 7 = 8.

Bu grafik to‘plamlarni solishtirishda juda qulay: mediana markaziy joylashuvni, quti kengligi esa ma’lumotlarning o‘rta yarmidagi tarqalishni ko‘rsatadi. Savolda outlier qoidasi berilgan yoki outlierlar alohida ko‘rsatilgan bo‘lsa, ularni ham izohga qo‘shing.$t$,
$t$Quti diagrammasi beshta qiymatdan foydalanadi:

minimum, Q1, mediana, Q3, maksimum.

4, 7, 10, 15, 20 uchun quti 7 dan 15 gacha, mediana 10, mo‘ylovlar 4 va 20 gacha.

IQR = 15-7=8.

Mediana joylashuvni, IQR esa tarqalishni ko‘rsatadi.$t$,
$t$Quti diagrammasini tartiblangan ma’lumotlarning siqilgan xaritasi deb o‘ylang.

Quti ichidagi chiziq o‘rtani ko‘rsatadi. Qutining ikki cheti Q1 dan Q3 gacha bo‘lgan o‘rta 50% ma’lumotni ko‘rsatadi. Mo‘ylovlar markaziy qismdan tashqaridagi tarqalishni ko‘rsatadi.

Shuning uchun bir vaqtning o‘zida ham markaz, ham tarqalishni ko‘rish mumkin.$t$,
$t$Beshta qiymatni bir xil sonlar shkalasida va to‘g‘ri tartibda joylashtiring. Quti kengligini umumiy range bilan aralashtirmang: quti IQR ni ko‘rsatadi. Ikki quti diagrammasini solishtirganda ham joylashuv, ham tarqalishni izohlang.$t$,
'p5:P5-DAT-03:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
