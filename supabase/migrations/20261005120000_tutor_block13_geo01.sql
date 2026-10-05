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
  if v<>219 then raise exception 'GEO01 expected 219 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-GEO-01')<>0
  then raise exception 'GEO01 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-GEO-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'GEO01 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-GEO-01:tutor:en:v2','P5','P5-GEO-01','en','tutor_v2_learner_first',
'Recognising a geometric model',
$t$A geometric model describes the waiting time until the first success.

The repeated trials must have:
- two outcomes: success or failure;
- a constant success probability p;
- independence between trials.

The random variable X counts the trial number on which the first success occurs, so possible values are 1,2,3,...

Example: each independent attempt succeeds with probability 0.2. Let X be the number of attempts needed until the first success.

The success probability stays 0.2, attempts are independent, and we stop at the first success. So this is a geometric model with p=0.2.

The key difference from a binomial model is the stopping rule: binomial fixes the number of trials and counts successes; geometric keeps going until the first success.$t$,
$t$A geometric model counts the trial on which the first success occurs.

Conditions:
two outcomes,
constant p,
independent trials,
stop at the first success.

If each attempt succeeds with probability 0.2 and X is the number of attempts until the first success, the model is geometric with p=0.2.$t$,
$t$Think of a geometric process as a waiting question: “How long until the first success?”

The sequence might be failure, failure, success, so X=3. The experiment does not have a fixed number of trials in advance; it ends when the first success appears.$t$,
$t$Check what X is counting. If X counts successes in a fixed n, think binomial. If X counts trials until the first success, think geometric. Also confirm constant p and independence.$t$,
'p5:P5-GEO-01:theory:en:v1'
),
(
'p5:P5-GEO-01:tutor:ru:v2','P5','P5-GEO-01','ru','tutor_v2_learner_first',
'Как распознать геометрическую модель',
$t$Геометрическая модель описывает ожидание до первого успеха.

Повторяющиеся испытания должны иметь:
- два исхода: успех или неуспех;
- постоянную вероятность успеха p;
- независимость испытаний.

Случайная величина X считает номер испытания, на котором впервые произошёл успех, поэтому возможные значения: 1,2,3,...

Пример: каждое независимое испытание заканчивается успехом с вероятностью 0.2. Пусть X — число испытаний до первого успеха.

Вероятность успеха постоянно равна 0.2, испытания независимы, и процесс заканчивается при первом успехе. Значит, это геометрическая модель с p=0.2.

Главное отличие от биномиальной модели: биномиальная фиксирует число испытаний и считает успехи, геометрическая продолжает испытания до первого успеха.$t$,
$t$Геометрическая модель считает номер испытания, на котором впервые произошёл успех.

Условия:
два исхода,
постоянное p,
независимые испытания,
остановка при первом успехе.

Если каждое испытание успешно с вероятностью 0.2, а X — число испытаний до первого успеха, используется геометрическая модель с p=0.2.$t$,
$t$Представьте геометрическую модель как вопрос об ожидании: «Сколько испытаний пройдёт до первого успеха?»

Последовательность может быть: неуспех, неуспех, успех. Тогда X=3. Заранее фиксированного числа испытаний нет — процесс заканчивается, когда впервые появляется успех.$t$,
$t$Сначала определите, что считает X. Если X считает число успехов в фиксированном n, это биномиальная модель. Если X считает испытания до первого успеха, это геометрическая модель. Также проверьте постоянство p и независимость.$t$,
'p5:P5-GEO-01:theory:ru:v1'
),
(
'p5:P5-GEO-01:tutor:uz:v2','P5','P5-GEO-01','uz','tutor_v2_learner_first',
'Geometrik modelni aniqlash',
$t$Geometrik model birinchi muvaffaqiyatgacha qancha sinov kutishni tasvirlaydi.

Takroriy sinovlarda:
- ikki natija: muvaffaqiyat yoki muvaffaqiyatsizlik;
- muvaffaqiyat ehtimoli p doimiy;
- sinovlar mustaqil

bo‘lishi kerak.

X tasodifiy miqdor birinchi muvaffaqiyat qaysi sinovda sodir bo‘lganini sanaydi, shuning uchun mumkin qiymatlar 1,2,3,...

Masalan, har bir mustaqil urinish 0.2 ehtimollik bilan muvaffaqiyatli. X — birinchi muvaffaqiyatgacha bo‘lgan urinishlar soni.

p=0.2 doimiy, urinishlar mustaqil va jarayon birinchi muvaffaqiyatda tugaydi. Demak, bu p=0.2 bo‘lgan geometrik model.

Binomial modeldan asosiy farq: binomialda sinovlar soni oldindan belgilangan, geometrik model esa birinchi muvaffaqiyatgacha davom etadi.$t$,
$t$Geometrik model birinchi muvaffaqiyat qaysi sinovda bo‘lishini sanaydi.

Shartlar:
ikki natija,
doimiy p,
mustaqil sinovlar,
birinchi muvaffaqiyatda to‘xtash.

Har bir urinish 0.2 ehtimollik bilan muvaffaqiyatli bo‘lsa va X birinchi muvaffaqiyatgacha bo‘lgan urinishlarni sanasa, p=0.2 geometrik model ishlatiladi.$t$,
$t$Geometrik jarayonni “birinchi muvaffaqiyatgacha qancha kutaman?” degan savol deb o‘ylang.

Ketma-ketlik muvaffaqiyatsizlik, muvaffaqiyatsizlik, muvaffaqiyat bo‘lishi mumkin. Unda X=3. Sinovlar soni oldindan belgilanmaydi; birinchi muvaffaqiyat chiqqanda jarayon tugaydi.$t$,
$t$Avval X nimani sanayotganini tekshiring. X belgilangan n ichidagi muvaffaqiyatlar sonini sanasa — binomial; birinchi muvaffaqiyatgacha sinovlarni sanasa — geometrik. p doimiy va sinovlar mustaqil ekanini ham tekshiring.$t$,
'p5:P5-GEO-01:theory:uz:v1'
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
