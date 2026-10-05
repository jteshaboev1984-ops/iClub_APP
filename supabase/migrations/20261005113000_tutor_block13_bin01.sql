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
  if v<>210 then raise exception 'BIN01 expected 210 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-BIN-01')<>0
  then raise exception 'BIN01 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-BIN-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'BIN01 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-BIN-01:tutor:en:v2','P5','P5-BIN-01','en','tutor_v2_learner_first',
'Recognising a binomial model',
$t$A binomial model counts the number of successes in a fixed number of repeated trials.

Four conditions must hold:
- the number of trials n is fixed;
- each trial has two outcomes: success or failure;
- the success probability p stays constant;
- the trials are independent.

Example: 10 independent seeds are tested and each seed germinates with probability 0.7. Let X be the number that germinate.

The number of trials is fixed at 10, each seed either germinates or does not, p=0.7 is constant, and the trials are independent. So X can be modelled as binomial with n=10 and p=0.7.

The important skill is not spotting the word “success”; it is checking all four conditions before using binomial formulas.$t$,
$t$Use a binomial model only when all four conditions hold:

fixed n,
two outcomes,
constant p,
independent trials.

For 10 independent seeds, each with germination probability 0.7, the number that germinate is binomial with

n=10, p=0.7.$t$,
$t$Think of a binomial model as repeating the same yes/no experiment n times and counting how many “yes” results occur.

If the experiment changes from trial to trial — for example p changes, or one trial affects another — then the repetitions are no longer identical and the binomial model may not fit.$t$,
$t$Check all four conditions before calculating. A fixed number of trials alone is not enough. Write down what “success” means, identify n and p, and confirm that p is constant and the trials are independent.$t$,
'p5:P5-BIN-01:theory:en:v1'
),
(
'p5:P5-BIN-01:tutor:ru:v2','P5','P5-BIN-01','ru','tutor_v2_learner_first',
'Как распознать биномиальную модель',
$t$Биномиальная модель считает число успехов в фиксированном количестве повторяющихся испытаний.

Должны выполняться четыре условия:
- число испытаний n фиксировано;
- у каждого испытания два исхода: успех или неуспех;
- вероятность успеха p постоянна;
- испытания независимы.

Пример: проверяют 10 независимых семян, и каждое прорастает с вероятностью 0.7. Пусть X — число проросших семян.

Число испытаний фиксировано и равно 10, каждое семя либо прорастает, либо нет, p=0.7 постоянно, испытания независимы. Поэтому X можно моделировать биномиальным распределением с n=10 и p=0.7.

Главное — не просто увидеть слово «успех», а проверить все четыре условия до применения биномиальных формул.$t$,
$t$Биномиальная модель подходит только при четырёх условиях:

фиксированное n,
два исхода,
постоянное p,
независимые испытания.

Для 10 независимых семян с вероятностью прорастания 0.7 число проросших семян имеет биномиальную модель с

n=10, p=0.7.$t$,
$t$Представьте биномиальную модель как одно и то же испытание «да/нет», которое повторяют n раз, а затем считают количество «да».

Если от испытания к испытанию условия меняются — например, меняется p или один результат влияет на следующий, — повторения уже не одинаковы и биномиальная модель может не подходить.$t$,
$t$Перед расчётом проверьте все четыре условия. Одного фиксированного числа испытаний недостаточно. Чётко определите, что считается успехом, найдите n и p и убедитесь, что p постоянно, а испытания независимы.$t$,
'p5:P5-BIN-01:theory:ru:v1'
),
(
'p5:P5-BIN-01:tutor:uz:v2','P5','P5-BIN-01','uz','tutor_v2_learner_first',
'Binomial modelni aniqlash',
$t$Binomial model belgilangan sondagi takroriy sinovlarda nechta muvaffaqiyat bo‘lishini sanaydi.

To‘rtta shart bajarilishi kerak:
- sinovlar soni n oldindan belgilangan;
- har bir sinovda ikki natija bor: muvaffaqiyat yoki muvaffaqiyatsizlik;
- muvaffaqiyat ehtimoli p o‘zgarmaydi;
- sinovlar mustaqil.

Masalan, 10 ta urug‘ mustaqil tekshiriladi va har bir urug‘ 0.7 ehtimollik bilan unadi. X — ungan urug‘lar soni bo‘lsin.

Sinovlar soni 10, har bir urug‘ unadi yoki unamaydi, p=0.7 doimiy va sinovlar mustaqil. Demak, X ni n=10 va p=0.7 bo‘lgan binomial model bilan ifodalash mumkin.

Muhim qadam — formulani ishlatishdan oldin to‘rtta shartning barchasini tekshirish.$t$,
$t$Binomial model faqat to‘rtta shart bajarilganda mos keladi:

n belgilangan,
ikki natija,
p doimiy,
sinovlar mustaqil.

10 ta mustaqil urug‘ning har biri 0.7 ehtimollik bilan unsa, unganlar soni uchun

n=10, p=0.7

binomial model ishlatiladi.$t$,
$t$Binomial modelni bir xil “ha/yo‘q” tajribasi n marta takrorlanib, nechta “ha” chiqqani sanaladi deb tasavvur qiling.

Agar sinovdan sinovga sharoit o‘zgarsa — masalan p o‘zgarsa yoki bir natija keyingisiga ta’sir qilsa — sinovlar bir xil bo‘lmaydi va binomial model mos kelmasligi mumkin.$t$,
$t$Hisoblashdan oldin to‘rtta shartni tekshiring. Faqat sinovlar soni belgilangan bo‘lishi yetarli emas. “Muvaffaqiyat” nimani anglatishini, n va p ni yozing, p doimiy va sinovlar mustaqil ekanini tasdiqlang.$t$,
'p5:P5-BIN-01:theory:uz:v1'
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
