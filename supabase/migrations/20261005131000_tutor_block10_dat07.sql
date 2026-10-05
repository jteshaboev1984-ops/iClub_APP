begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>156 then raise exception 'DAT07 expected 156 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DAT-07' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DAT07 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-DAT-07:tutor:en:v2','P5','P5-DAT-07','en','tutor_v2_learner_first','Spread and standard deviation',
$t$Measures of spread describe how widely data values are distributed.

The range uses only the two extremes:

range = maximum - minimum.

The interquartile range focuses on the middle half:

IQR = Q3 - Q1.

For example, if Q1=4 and Q3=10, then

IQR = 10 - 4 = 6.

Standard deviation uses all the data and measures how far values typically lie from the mean. A larger standard deviation means greater overall variability; a smaller one means values are more tightly clustered around the mean.

Different spread measures answer different questions. Range is quick but sensitive to extremes, IQR focuses on the central half, and standard deviation reflects the whole distribution.$t$,
$t$Spread tells you how variable the data are.

range = maximum - minimum.

IQR = Q3 - Q1.

If Q1=4 and Q3=10, then IQR=6.

Standard deviation uses all values. A larger standard deviation means the data are more spread out around the mean.$t$,
$t$Think of spread as asking how much room the data occupy.

Range looks from the smallest value all the way to the largest.

IQR ignores the outer quarters and measures the width of the middle 50%.

Standard deviation looks at every observation and asks how far the data typically sit from the mean.

So two data sets can have similar centres but very different levels of consistency.$t$,
$t$Do not use the same interpretation for every spread measure. Range depends only on extremes; IQR uses quartiles; standard deviation uses all observations. When comparing sets, state which measure is larger and what that says about variability.$t$,
'p5:P5-DAT-07:theory:en:v1'
),
(
'p5:P5-DAT-07:tutor:ru:v2','P5','P5-DAT-07','ru','tutor_v2_learner_first','Разброс и стандартное отклонение',
$t$Меры разброса показывают, насколько широко распределены значения данных.

Размах использует только два крайних значения:

размах = максимум - минимум.

Межквартильный размах описывает среднюю половину данных:

IQR = Q3 - Q1.

Например, если Q1=4 и Q3=10, то

IQR = 10 - 4 = 6.

Стандартное отклонение использует все значения и показывает, насколько далеко данные обычно находятся от среднего. Большее стандартное отклонение означает большую общую изменчивость, меньшее — более плотное расположение около среднего.

Разные меры разброса отвечают на разные вопросы: размах чувствителен к крайним значениям, IQR смотрит на центральную половину, а стандартное отклонение учитывает всё распределение.$t$,
$t$Разброс показывает, насколько различаются данные.

размах = максимум - минимум.

IQR = Q3 - Q1.

Если Q1=4 и Q3=10, то IQR=6.

Стандартное отклонение использует все значения. Чем оно больше, тем сильнее данные разбросаны вокруг среднего.$t$,
$t$Представьте разброс как вопрос: сколько пространства занимают данные?

Размах измеряет расстояние от самого маленького значения до самого большого.

IQR измеряет ширину средних 50% данных.

Стандартное отклонение использует каждое наблюдение и показывает типичное удаление от среднего.

Поэтому два набора могут иметь похожий центр, но разную стабильность.$t$,
$t$Не интерпретируйте все меры разброса одинаково. Размах зависит только от крайних значений, IQR — от квартилей, стандартное отклонение — от всех наблюдений. При сравнении обязательно укажите, какая мера больше и что это говорит об изменчивости.$t$,
'p5:P5-DAT-07:theory:ru:v1'
),
(
'p5:P5-DAT-07:tutor:uz:v2','P5','P5-DAT-07','uz','tutor_v2_learner_first','Tarqalish va standart og‘ish',
$t$Tarqalish o‘lchovlari ma’lumot qiymatlari qanchalik keng yoyilganini ko‘rsatadi.

Range faqat ikki chekka qiymatdan foydalanadi:

range = maksimum - minimum.

Kvartillar oralig‘i ma’lumotlarning o‘rta yarmini o‘lchaydi:

IQR = Q3 - Q1.

Masalan, Q1=4 va Q3=10 bo‘lsa,

IQR = 10 - 4 = 6.

Standart og‘ish barcha qiymatlardan foydalanadi va ma’lumotlar o‘rtachadan odatda qanchalik uzoqda ekanini ko‘rsatadi. Standart og‘ish kattaroq bo‘lsa, umumiy o‘zgaruvchanlik kattaroq; kichikroq bo‘lsa, qiymatlar o‘rtacha atrofida zichroq joylashgan.

Har bir tarqalish o‘lchovi boshqa savolga javob beradi.$t$,
$t$Tarqalish ma’lumotlar qanchalik o‘zgarishini ko‘rsatadi.

range = maksimum - minimum.

IQR = Q3 - Q1.

Q1=4 va Q3=10 bo‘lsa, IQR=6.

Standart og‘ish barcha qiymatlarni ishlatadi. U kattaroq bo‘lsa, ma’lumotlar o‘rtacha atrofida ko‘proq tarqalgan.$t$,
$t$Tarqalishni “ma’lumotlar qancha joy egallaydi?” degan savol deb o‘ylang.

Range eng kichikdan eng kattagacha bo‘lgan masofani oladi.

IQR o‘rta 50% ma’lumot kengligini o‘lchaydi.

Standart og‘ish har bir kuzatuvni hisobga olib, o‘rtachadan odatiy uzoqlikni ifodalaydi.

Shu sabab markazi o‘xshash ikki to‘plamning barqarorligi turlicha bo‘lishi mumkin.$t$,
$t$Har bir tarqalish o‘lchovini bir xil talqin qilmang. Range faqat chekka qiymatlarga, IQR kvartillarga, standart og‘ish esa barcha kuzatuvlarga bog‘liq. Taqqoslashda qaysi o‘lchov kattaroq ekanini va bu o‘zgaruvchanlik haqida nimani anglatishini ayting.$t$,
'p5:P5-DAT-07:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
