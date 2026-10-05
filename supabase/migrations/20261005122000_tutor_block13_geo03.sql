begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$
declare v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='draft' and not is_runtime_allowed;
  if v<>225 then raise exception 'GEO03 expected 225 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-GEO-03')<>0
  then raise exception 'GEO03 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-GEO-03' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'GEO03 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-GEO-03:tutor:en:v2','P5','P5-GEO-03','en','tutor_v2_learner_first',
'Geometric expectation',
$t$For a geometric random variable that counts trials until the first success,

E(X)=1/p.

This gives the long-run average waiting time to the first success.

Suppose the expected waiting time is 5 trials. Then

1/p = 5,

so

p = 1/5 = 0.2.

This does not mean the first success will always occur on trial 5. In one sequence it may happen immediately; in another it may take much longer. The formula describes the average trial number of the first success across many repeated sequences.

Because p is a probability, an inverse-parameter answer should always satisfy 0<p≤1.$t$,
$t$For a geometric model,

E(X)=1/p.

If the expected waiting time is 5 trials,

1/p=5,

so

p=0.2.

This is a long-run average, not a promise that the first success happens exactly on trial 5.$t$,
$t$Think of p and waiting time as moving in opposite directions.

A large success probability usually means you do not wait long. A small success probability usually means a longer wait.

The formula E(X)=1/p captures that relationship exactly. If the average wait is 5 trials, the success probability is the reciprocal, 1/5.$t$,
$t$Make sure X counts trials until the first success. To recover p, take the reciprocal of the expected waiting time. Check 0<p≤1, and interpret E(X) as a long-run average rather than a guaranteed trial number.$t$,
'p5:P5-GEO-03:theory:en:v1'
),
(
'p5:P5-GEO-03:tutor:ru:v2','P5','P5-GEO-03','ru','tutor_v2_learner_first',
'Математическое ожидание геометрического распределения',
$t$Для геометрической случайной величины, которая считает число испытаний до первого успеха,

E(X)=1/p.

Это долгосрочное среднее время ожидания первого успеха.

Пусть ожидаемое число испытаний равно 5. Тогда

1/p = 5,

поэтому

p = 1/5 = 0.2.

Это не означает, что первый успех всегда произойдёт в пятом испытании. В одной последовательности он может появиться сразу, в другой — значительно позже. Формула описывает средний номер первого успешного испытания при большом числе повторений.

Так как p — вероятность, найденный параметр должен удовлетворять 0<p≤1.$t$,
$t$Для геометрической модели:

E(X)=1/p.

Если ожидаемое время ожидания равно 5 испытаниям,

1/p=5,

значит

p=0.2.

Это долгосрочное среднее, а не гарантия успеха ровно в пятом испытании.$t$,
$t$Представьте, что p и время ожидания движутся в противоположных направлениях.

Большая вероятность успеха обычно означает короткое ожидание. Маленькая — более долгое.

Формула E(X)=1/p точно описывает эту связь. Если среднее ожидание равно 5 испытаниям, вероятность успеха равна обратному числу 1/5.$t$,
$t$Убедитесь, что X действительно считает испытания до первого успеха. Чтобы восстановить p, возьмите величину, обратную математическому ожиданию. Проверьте 0<p≤1 и трактуйте E(X) как долгосрочное среднее, а не гарантированный номер испытания.$t$,
'p5:P5-GEO-03:theory:ru:v1'
),
(
'p5:P5-GEO-03:tutor:uz:v2','P5','P5-GEO-03','uz','tutor_v2_learner_first',
'Geometrik taqsimotning matematik kutilmasi',
$t$Birinchi muvaffaqiyatgacha bo‘lgan sinovlar sonini sanaydigan geometrik tasodifiy miqdor uchun

E(X)=1/p.

Bu birinchi muvaffaqiyatgacha bo‘lgan uzoq muddatli o‘rtacha kutish vaqtidir.

Kutilayotgan sinovlar soni 5 bo‘lsin. Unda

1/p = 5,

demak

p = 1/5 = 0.2.

Bu birinchi muvaffaqiyat har doim beshinchi sinovda bo‘ladi degani emas. Bir ketma-ketlikda muvaffaqiyat darhol chiqishi, boshqasida esa ancha kech chiqishi mumkin. Formula ko‘p takrorlashlardagi birinchi muvaffaqiyat sinovining o‘rtacha raqamini beradi.

p ehtimollik bo‘lgani uchun 0<p≤1 bo‘lishi kerak.$t$,
$t$Geometrik model uchun

E(X)=1/p.

Kutilayotgan kutish 5 ta sinov bo‘lsa,

1/p=5,

demak

p=0.2.

Bu uzoq muddatli o‘rtacha; birinchi muvaffaqiyat aynan 5-sinovda bo‘lishiga kafolat bermaydi.$t$,
$t$p va kutish vaqtini qarama-qarshi yo‘nalishda o‘zgaradi deb o‘ylang.

Muvaffaqiyat ehtimoli katta bo‘lsa, odatda kamroq kutiladi. p kichik bo‘lsa, kutish uzoqroq bo‘ladi.

E(X)=1/p shu munosabatni aniq beradi. O‘rtacha kutish 5 bo‘lsa, muvaffaqiyat ehtimoli uning teskarisi — 1/5.$t$,
$t$X birinchi muvaffaqiyatgacha bo‘lgan sinovlarni sanayotganini tekshiring. p ni topish uchun kutilmaning teskarisini oling. 0<p≤1 ni tekshiring va E(X) ni kafolatlangan sinov raqami emas, uzoq muddatli o‘rtacha deb talqin qiling.$t$,
'p5:P5-GEO-03:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select tutor_card_key,component_code,skill_code,locale,content_version,title,
       main_explanation,simple_explanation,alternative_explanation,focus_explanation,
       source_card_key,'draft',false,
       md5(concat_ws('||',content_version,title,main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key))
from seed;

commit;
