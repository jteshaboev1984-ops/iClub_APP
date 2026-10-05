begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>162 then raise exception 'DAT09 expected 162 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DAT-09' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DAT09 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-DAT-09:tutor:en:v2','P5','P5-DAT-09','en','tutor_v2_learner_first','Mean and standard deviation from summaries',
$t$Summary totals can be used to calculate mean and standard deviation without listing every value again.

Suppose

n=5,   Σx=30,   Σx²=220.

Then the mean is

x̄ = Σx/n = 30/5 = 6.

Using the course convention

variance = Σx²/n - x̄²,

we get

variance = 220/5 - 6² = 44 - 36 = 8,

so the standard deviation is

√8.

For grouped data, the same structure is used with frequencies and class midpoints, giving an estimate when exact observations are not known.

The key is to match each total to the correct formula and keep the same standard-deviation convention throughout the calculation.$t$,
$t$If n=5, Σx=30 and Σx²=220:

mean = 30/5 = 6.

variance = 220/5 - 6² = 8.

standard deviation = √8.

Use the supplied totals carefully. For grouped data, midpoint calculations usually give estimates.$t$,
$t$Think of Σx and Σx² as compressed information about the whole data set.

Σx tells you the total needed for the mean.

Σx² tells you how large the squared values are, which combines with the mean to measure spread.

So you can recover key summary measures without reconstructing every observation.$t$,
$t$Keep n, Σx and Σx² separate. Square the mean only after calculating it; do not confuse (Σx)² with Σx². For grouped data, use frequency-weighted midpoints and state an estimate when grouping prevents exact values.$t$,
'p5:P5-DAT-09:theory:en:v1'
),
(
'p5:P5-DAT-09:tutor:ru:v2','P5','P5-DAT-09','ru','tutor_v2_learner_first','Среднее и стандартное отклонение по итоговым суммам',
$t$Итоговые суммы позволяют найти среднее и стандартное отклонение, не выписывая все значения заново.

Пусть

n=5,   Σx=30,   Σx²=220.

Тогда среднее:

x̄ = Σx/n = 30/5 = 6.

Используя принятую в курсе форму

дисперсия = Σx²/n - x̄²,

получаем

дисперсия = 220/5 - 6² = 44 - 36 = 8,

поэтому стандартное отклонение равно

√8.

Для сгруппированных данных используется та же структура с частотами и серединами интервалов; если точные наблюдения неизвестны, результат является оценкой.

Главное — правильно сопоставить каждую сумму с формулой и последовательно использовать одну convention стандартного отклонения.$t$,
$t$Если n=5, Σx=30 и Σx²=220:

среднее = 30/5 = 6.

дисперсия = 220/5 - 6² = 8.

стандартное отклонение = √8.

Внимательно используйте данные суммы. Для сгруппированных данных расчёты по серединам интервалов обычно дают оценку.$t$,
$t$Считайте Σx и Σx² сжатой информацией о всём наборе.

Σx даёт сумму, нужную для среднего.

Σx² содержит информацию о квадратах значений и вместе со средним помогает измерить разброс.

Так можно восстановить основные характеристики, не возвращаясь к каждому наблюдению отдельно.$t$,
$t$Не путайте n, Σx и Σx². Квадрат среднего вычисляйте после нахождения среднего; (Σx)² и Σx² — разные величины. Для сгруппированных данных используйте частоты и середины интервалов и отмечайте оценочный характер результата, если точные значения неизвестны.$t$,
'p5:P5-DAT-09:theory:ru:v1'
),
(
'p5:P5-DAT-09:tutor:uz:v2','P5','P5-DAT-09','uz','tutor_v2_learner_first','Yig‘indi ma’lumotlardan o‘rtacha va standart og‘ish',
$t$Yakuniy yig‘indilar barcha qiymatlarni qayta yozmasdan o‘rtacha va standart og‘ishni topishga yordam beradi.

Faraz qilaylik,

n=5,   Σx=30,   Σx²=220.

O‘rtacha:

x̄ = Σx/n = 30/5 = 6.

Kursda ishlatiladigan

dispersiya = Σx²/n - x̄²

ko‘rinishdan:

dispersiya = 220/5 - 6² = 44 - 36 = 8,

demak standart og‘ish

√8.

Guruhlangan ma’lumotlarda ham shu tuzilma chastotalar va interval o‘rtalari bilan ishlatiladi; aniq kuzatuvlar noma’lum bo‘lsa natija taxminiy bo‘ladi.

Asosiy narsa — har bir yig‘indini to‘g‘ri formulaga qo‘yish va standart og‘ish conventionini izchil saqlash.$t$,
$t$n=5, Σx=30 va Σx²=220 bo‘lsa:

o‘rtacha = 30/5 = 6.

dispersiya = 220/5 - 6² = 8.

standart og‘ish = √8.

Yig‘indilarni ehtiyotkor ishlating. Guruhlangan ma’lumotlarda interval o‘rtalari bilan hisoblangan natija odatda taxminiy bo‘ladi.$t$,
$t$Σx va Σx² ni butun to‘plam haqidagi siqilgan ma’lumot deb o‘ylang.

Σx o‘rtacha uchun kerakli umumiy yig‘indini beradi.

Σx² esa qiymatlar kvadratlari haqida ma’lumot beradi va o‘rtacha bilan birga tarqalishni hisoblashga yordam beradi.

Shu sabab har bir kuzatuvni qayta tiklamasdan asosiy statistikalarni topish mumkin.$t$,
$t$n, Σx va Σx² ni aralashtirmang. Avval o‘rtachani topib, keyin uning kvadratini oling; (Σx)² va Σx² bir xil emas. Guruhlangan ma’lumotlarda chastota bilan og‘irlangan interval o‘rtalaridan foydalaning va kerak bo‘lsa natijani taxmin sifatida ko‘rsating.$t$,
'p5:P5-DAT-09:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
