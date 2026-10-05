begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>150 then raise exception 'DAT05 expected 150 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DAT-05' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DAT05 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-DAT-05:tutor:en:v2','P5','P5-DAT-05','en','tutor_v2_learner_first','Cumulative frequency',
$t$Cumulative frequency tells you how many observations are at or below a boundary. On a cumulative-frequency graph, this lets you read quartiles, percentiles and proportions.

Suppose the total frequency is 80.

The lower quartile corresponds to the 20th observation because 80/4=20.

The median corresponds to the 40th observation.

The upper quartile corresponds to the 60th observation.

The 90th percentile corresponds to cumulative frequency 0.90×80=72.

For each target, start on the cumulative-frequency axis, move across to the curve, then down to the data-value axis. The graph converts a position in the ordered data into an estimated value.$t$,
$t$For total frequency 80:

Q1 → cumulative frequency 20.

Median → 40.

Q3 → 60.

90th percentile → 72.

On the graph, start at the required cumulative frequency, move to the curve, then read the corresponding data value.$t$,
$t$Imagine all 80 observations arranged from smallest to largest.

Q1 is one quarter of the way through the list, the median is halfway, and Q3 is three quarters of the way through. A cumulative-frequency graph does the same ordering visually.

You choose a rank such as the 40th or 72nd observation, then use the curve to estimate the value at that position.$t$,
$t$Use the total frequency first to convert a quartile or percentile into a cumulative frequency. Read from cumulative frequency to the curve, then to the data axis. Keep in mind that values read from a drawn curve are usually estimates.$t$,
'p5:P5-DAT-05:theory:en:v1'
),
(
'p5:P5-DAT-05:tutor:ru:v2','P5','P5-DAT-05','ru','tutor_v2_learner_first','Накопленная частота',
$t$Накопленная частота показывает, сколько наблюдений находится не выше заданной границы. По графику накопленной частоты можно находить квартили, процентили и доли.

Пусть общая частота равна 80.

Нижний квартиль соответствует 20-му наблюдению, потому что 80/4=20.

Медиана соответствует 40-му наблюдению.

Верхний квартиль — 60-му.

90-й процентиль соответствует накопленной частоте 0.90×80=72.

Для каждого значения начните на оси накопленной частоты, проведите линию к кривой, затем опуститесь к оси значений. График переводит положение в упорядоченных данных в оценку самого значения.$t$,
$t$При общей частоте 80:

Q1 → накопленная частота 20.

Медиана → 40.

Q3 → 60.

90-й процентиль → 72.

На графике начните с нужной накопленной частоты, идите к кривой, затем считайте соответствующее значение данных.$t$,
$t$Представьте, что все 80 наблюдений расположены от меньшего к большему.

Q1 находится на четверти списка, медиана — посередине, Q3 — на трёх четвертях. График накопленной частоты показывает ту же идею визуально.

Вы выбираете номер наблюдения, например 40-й или 72-й, и по кривой оцениваете соответствующее значение.$t$,
$t$Сначала используйте общую частоту, чтобы перевести квартиль или процентиль в накопленную частоту. Затем идите от неё к кривой и к оси значений. Значения, считанные с нарисованной кривой, обычно являются оценками.$t$,
'p5:P5-DAT-05:theory:ru:v1'
),
(
'p5:P5-DAT-05:tutor:uz:v2','P5','P5-DAT-05','uz','tutor_v2_learner_first','Yig‘ma chastota',
$t$Yig‘ma chastota berilgan chegaragacha nechta kuzatuv borligini ko‘rsatadi. Yig‘ma chastota grafigidan kvartillar, percentillar va ulushlarni topish mumkin.

Umumiy chastota 80 bo‘lsin.

Quyi kvartil 20-kuzatuvga mos keladi, chunki 80/4=20.

Mediana 40-kuzatuvga.

Yuqori kvartil 60-kuzatuvga.

90-percentil esa 0.90×80=72 yig‘ma chastotaga mos keladi.

Har bir holatda yig‘ma chastota o‘qidan boshlang, egri chiziqqacha boring va keyin ma’lumot qiymati o‘qiga tushing. Grafik tartiblangan ma’lumotdagi o‘rinni taxminiy qiymatga aylantiradi.$t$,
$t$Umumiy chastota 80 bo‘lsa:

Q1 → yig‘ma chastota 20.

Mediana → 40.

Q3 → 60.

90-percentil → 72.

Grafikda kerakli yig‘ma chastotadan egri chiziqqa boring, keyin mos ma’lumot qiymatini o‘qing.$t$,
$t$Barcha 80 kuzatuv kichikdan kattaga tartiblanganini tasavvur qiling.

Q1 ro‘yxatning choragida, mediana yarmida, Q3 esa to‘rtdan uch qismida joylashadi. Yig‘ma chastota grafigi shu fikrni vizual ko‘rsatadi.

Masalan, 40- yoki 72-kuzatuvning o‘rnini tanlab, egri chiziqdan unga mos qiymatni baholaysiz.$t$,
$t$Avval umumiy chastotadan foydalanib kvartil yoki percentilni yig‘ma chastotaga aylantiring. So‘ng egri chiziqqa va ma’lumot o‘qiga o‘ting. Chizilgan grafikdan o‘qilgan qiymatlar odatda taxminiy bo‘ladi.$t$,
'p5:P5-DAT-05:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
