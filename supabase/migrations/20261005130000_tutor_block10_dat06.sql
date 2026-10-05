begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>153 then raise exception 'DAT06 expected 153 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DAT-06' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DAT06 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-DAT-06:tutor:en:v2','P5','P5-DAT-06','en','tutor_v2_learner_first','Mean, median and mode',
$t$Mean, median and mode describe the location of a data set in different ways.

For the data

2, 4, 4, 7, 8,

the mean is

(2+4+4+7+8)/5 = 5.

The median is the middle ordered value, 4.

The mode is the most frequent value, also 4.

These measures answer different questions. The mean uses every value, so it responds to unusually large or small observations. The median depends on order and is less affected by extreme values. The mode identifies the most common value.

For grouped data, the mean is usually estimated using class midpoints and frequencies. Choose the measure that best matches the data and the purpose of the comparison.$t$,
$t$For

2, 4, 4, 7, 8:

mean = 5,
median = 4,
mode = 4.

The mean uses every value. The median is the middle value after ordering. The mode is the most common value.

For grouped data, use class midpoints with frequencies to estimate the mean.$t$,
$t$Think of the three measures as three different ideas of “centre”.

The mean is a balance point because every value contributes to it.

The median is the halfway point in the ordered list.

The mode is the most common value.

None is automatically “best”; the useful measure depends on what the data and the question are trying to describe.$t$,
$t$Order the data before finding the median. Do not confuse frequency with value when finding the mode. For grouped data, remember that a midpoint-based mean is an estimate because the exact values inside each class are not known.$t$,
'p5:P5-DAT-06:theory:en:v1'
),
(
'p5:P5-DAT-06:tutor:ru:v2','P5','P5-DAT-06','ru','tutor_v2_learner_first','Среднее, медиана и мода',
$t$Среднее, медиана и мода по-разному описывают положение данных.

Для набора

2, 4, 4, 7, 8

среднее равно

(2+4+4+7+8)/5 = 5.

Медиана — среднее по позиции значение в упорядоченном списке, то есть 4.

Мода — наиболее часто встречающееся значение, тоже 4.

Эти меры отвечают на разные вопросы. Среднее использует каждое значение, поэтому реагирует на очень большие или маленькие наблюдения. Медиана зависит от порядка и слабее меняется из-за крайних значений. Мода показывает самое частое значение.

Для сгруппированных данных среднее обычно оценивают по серединам интервалов и частотам. Выбирайте меру по данным и цели сравнения.$t$,
$t$Для

2, 4, 4, 7, 8:

среднее = 5,
медиана = 4,
мода = 4.

Среднее использует все значения. Медиана — середина упорядоченного списка. Мода — самое частое значение.

Для сгруппированных данных среднее оценивают по серединам интервалов и частотам.$t$,
$t$Представьте три разные идеи «центра».

Среднее — точка баланса, потому что в нём участвует каждое значение.

Медиана — середина упорядоченного списка.

Мода — наиболее часто встречающееся значение.

Ни одна мера не является автоматически лучшей: выбор зависит от данных и того, что нужно описать.$t$,
$t$Перед медианой обязательно упорядочьте данные. При поиске моды не путайте значение с его частотой. Для сгруппированных данных среднее по серединам интервалов является оценкой, потому что точные значения внутри классов неизвестны.$t$,
'p5:P5-DAT-06:theory:ru:v1'
),
(
'p5:P5-DAT-06:tutor:uz:v2','P5','P5-DAT-06','uz','tutor_v2_learner_first','O‘rtacha, mediana va moda',
$t$O‘rtacha, mediana va moda ma’lumotlar markazini turli usulda tavsiflaydi.

Quyidagi ma’lumotlar uchun

2, 4, 4, 7, 8

o‘rtacha

(2+4+4+7+8)/5 = 5.

Mediana tartiblangan ro‘yxatdagi o‘rta qiymat, ya’ni 4.

Moda eng ko‘p uchraydigan qiymat, u ham 4.

Bu ko‘rsatkichlar turli ma’noga ega. O‘rtacha har bir qiymatdan foydalanadi, shuning uchun juda katta yoki kichik kuzatuvlarga sezgir. Mediana tartibga bog‘liq va ekstremal qiymatlardan kamroq ta’sirlanadi. Moda eng ko‘p uchraydigan qiymatni ko‘rsatadi.

Guruhlangan ma’lumotlarda o‘rtacha odatda interval o‘rtalari va chastotalar yordamida taxmin qilinadi.$t$,
$t$2, 4, 4, 7, 8 uchun:

o‘rtacha = 5,
mediana = 4,
moda = 4.

O‘rtacha barcha qiymatlarni ishlatadi. Mediana tartiblangan ro‘yxatning o‘rtasidir. Moda eng ko‘p uchraydigan qiymat.

Guruhlangan ma’lumotlarda o‘rtacha interval o‘rtalari va chastotalardan taxmin qilinadi.$t$,
$t$Uchta ko‘rsatkichni “markaz”ning uch xil ma’nosi deb o‘ylang.

O‘rtacha — barcha qiymatlar qatnashadigan muvozanat nuqtasi.

Mediana — tartiblangan ro‘yxatning yarmi.

Moda — eng ko‘p uchraydigan qiymat.

Hech biri har doim eng yaxshi emas; foydali tanlov ma’lumot va savol maqsadiga bog‘liq.$t$,
$t$Medianani topishdan oldin ma’lumotlarni tartiblang. Modada qiymatni uning chastotasi bilan aralashtirmang. Guruhlangan ma’lumotlarda interval o‘rtalari bilan hisoblangan o‘rtacha taxminiy natija ekanini unutmang.$t$,
'p5:P5-DAT-06:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
