begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>87 then raise exception 'SER01 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-SER-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'SER01 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-SER-01:tutor:en:v2','P1','P1-SER-01','en','tutor_v2_learner_first','Binomial expansion',
$t$For a positive integer power n, the expansion of (a+b)^n uses binomial coefficients.

For example,

(2+x)^4
= 2^4 + 4(2^3)x + 6(2^2)x² + 4(2)x³ + x^4
= 16 + 32x + 24x² + 8x³ + x^4.

So the coefficient of x² is 24.

The coefficients 1,4,6,4,1 are the binomial coefficients for power 4. As the expansion continues, the power of the first term decreases while the power of x increases. If a question asks for only one term or coefficient, identify the required power first so you do not expand more than necessary.$t$,
$t$For positive integer n, use binomial coefficients.

Example:

(2+x)^4
= 16 + 32x + 24x² + 8x³ + x^4.

So the coefficient of x² is 24.

The powers of 2 go down while the powers of x go up.$t$,
$t$Think of each term as choosing how many x factors come from the four brackets in

(2+x)(2+x)(2+x)(2+x).

To get x², choose x from exactly two brackets. There are 6 ways to do that, and the other two brackets contribute 2². So the x² term is

6×2²x² = 24x².

This is what the binomial coefficient is counting.$t$,
$t$This Paper 1 skill is for positive integer powers. Keep the powers organised: first-term power down, x power up. Check the requested power before calculating. Do not use rational or negative-power binomial series here.$t$,
'p1:P1-SER-01:theory:en:v1'
),
(
'p1:P1-SER-01:tutor:ru:v2','P1','P1-SER-01','ru','tutor_v2_learner_first','Биномиальное разложение',
$t$Для положительной целой степени n разложение (a+b)^n строится с биномиальными коэффициентами.

Например,

(2+x)^4
= 2^4 + 4(2^3)x + 6(2^2)x² + 4(2)x³ + x^4
= 16 + 32x + 24x² + 8x³ + x^4.

Поэтому коэффициент при x² равен 24.

Коэффициенты 1,4,6,4,1 — биномиальные коэффициенты для степени 4. По мере разложения степень первого слагаемого уменьшается, а степень x увеличивается. Если нужен только один член или коэффициент, сначала определите требуемую степень, чтобы не раскрывать всё выражение без необходимости.$t$,
$t$Для положительной целой степени используйте биномиальные коэффициенты.

Например,

(2+x)^4
= 16 + 32x + 24x² + 8x³ + x^4.

Коэффициент при x² равен 24.

Степени 2 уменьшаются, а степени x увеличиваются.$t$,
$t$Можно представить четыре множителя:

(2+x)(2+x)(2+x)(2+x).

Чтобы получить x², нужно выбрать x ровно из двух скобок. Это можно сделать 6 способами, а две оставшиеся скобки дают 2². Поэтому член с x² равен

6×2²x² = 24x².

Именно это и считает биномиальный коэффициент.$t$,
$t$В Paper 1 здесь рассматриваются только положительные целые степени. Следите за порядком степеней: степень первого слагаемого уменьшается, степень x растёт. Сначала найдите нужную степень. Не переходите к биномиальным рядам с рациональными или отрицательными степенями.$t$,
'p1:P1-SER-01:theory:ru:v1'
),
(
'p1:P1-SER-01:tutor:uz:v2','P1','P1-SER-01','uz','tutor_v2_learner_first','Binom yoyilmasi',
$t$Musbat butun n uchun (a+b)^n yoyilmasi binomial koeffitsiyentlar yordamida yoziladi.

Masalan,

(2+x)^4
= 2^4 + 4(2^3)x + 6(2^2)x² + 4(2)x³ + x^4
= 16 + 32x + 24x² + 8x³ + x^4.

Demak, x² oldidagi koeffitsiyent 24.

1,4,6,4,1 sonlari 4-daraja uchun binomial koeffitsiyentlardir. Yoyilma bo‘ylab birinchi hadning darajasi kamayadi, x ning darajasi esa oshadi. Savol faqat bitta had yoki koeffitsiyentni so‘rasa, avval kerakli x darajasini aniqlang.$t$,
$t$Musbat butun daraja uchun binomial koeffitsiyentlardan foydalaning.

Masalan,

(2+x)^4
= 16 + 32x + 24x² + 8x³ + x^4.

x² oldidagi koeffitsiyent 24.

2 ning darajalari kamayadi, x ning darajalari oshadi.$t$,
$t$(2+x)(2+x)(2+x)(2+x) ko‘paytmasini tasavvur qiling.

x² hosil bo‘lishi uchun to‘rtta qavsdan aynan ikkitasidan x tanlanadi. Buni 6 xil usulda qilish mumkin, qolgan ikki qavs esa 2² ni beradi. Shuning uchun x² li had

6×2²x² = 24x².

Binomial koeffitsiyent aynan shu tanlashlar sonini hisoblaydi.$t$,
$t$Paper 1 da bu ko‘nikma faqat musbat butun darajalar uchun. Darajalarni tartibli kuzating: birinchi had darajasi kamayadi, x darajasi oshadi. Avval so‘ralgan darajani toping. Ratsional yoki manfiy darajali binomial qatorlarga o‘tmang.$t$,
'p1:P1-SER-01:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
