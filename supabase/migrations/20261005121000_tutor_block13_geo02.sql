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
  if v<>222 then raise exception 'GEO02 expected 222 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-GEO-02')<>0
  then raise exception 'GEO02 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-GEO-02' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'GEO02 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-GEO-02:tutor:en:v2','P5','P5-GEO-02','en','tutor_v2_learner_first',
'Geometric probabilities',
$t$For a geometric random variable X, where p is the success probability on each independent trial,

P(X=r)=(1-p)^(r-1)p.

To get the first success on trial r, the first r-1 trials must fail and trial r must succeed.

Let p=0.25. Then

P(X=3)
=(0.75)²(0.25)
=0.140625.

For no success in the first 3 trials,

P(X>3)=(0.75)³=0.421875.

Therefore

P(X≤3)=1-P(X>3)
=1-(0.75)³
=0.578125.

The wording decides whether you need an exact first-success probability, a “still waiting” probability, or a cumulative probability. Complements are often the cleanest route.$t$,
$t$For a geometric model,

P(X=r)=(1-p)^(r-1)p.

If p=0.25:

P(X=3)=(0.75)²(0.25)=0.140625.

Also,

P(X>3)=(0.75)³=0.421875,

so

P(X≤3)=0.578125.$t$,
$t$Think in terms of a success/failure sequence.

For X=3, the sequence must be

failure, failure, success.

That gives (1-p)²p.

For X>3, the first three trials must all fail, so the probability is (1-p)³. This sequence view often makes geometric formulas easier to remember.$t$,
$t$Count the failures before the first success carefully: for X=r there are r-1 failures. For “more than r”, all first r trials fail. Use complements for “by”, “within” or “at most” when it shortens the calculation.$t$,
'p5:P5-GEO-02:theory:en:v1'
),
(
'p5:P5-GEO-02:tutor:ru:v2','P5','P5-GEO-02','ru','tutor_v2_learner_first',
'Геометрические вероятности',
$t$Для геометрической случайной величины X с вероятностью успеха p в каждом независимом испытании:

P(X=r)=(1-p)^(r-1)p.

Чтобы первый успех произошёл в испытании r, первые r-1 испытаний должны закончиться неуспехом, а испытание r — успехом.

Пусть p=0.25. Тогда

P(X=3)
=(0.75)²(0.25)
=0.140625.

Если в первых 3 испытаниях успеха ещё нет,

P(X>3)=(0.75)³=0.421875.

Поэтому

P(X≤3)=1-P(X>3)
=1-(0.75)³
=0.578125.

Формулировка задачи определяет, нужна ли вероятность первого успеха ровно в одном испытании, дальнейшего ожидания или накопленная вероятность. Часто удобнее использовать дополнение.$t$,
$t$Для геометрической модели:

P(X=r)=(1-p)^(r-1)p.

При p=0.25:

P(X=3)=(0.75)²(0.25)=0.140625.

Также

P(X>3)=(0.75)³=0.421875,

поэтому

P(X≤3)=0.578125.$t$,
$t$Представьте последовательность успехов и неуспехов.

Для X=3 последовательность должна быть:

неуспех, неуспех, успех.

Поэтому вероятность равна (1-p)²p.

Для X>3 первые три испытания должны быть неуспешными, значит вероятность равна (1-p)³. Такой взгляд помогает запомнить формулы.$t$,
$t$Правильно считайте число неуспехов перед первым успехом: для X=r их r-1. Для X>r первые r испытаний должны быть неуспешными. Для условий «к этому моменту», «в течение» или «не более» часто удобно использовать дополнение.$t$,
'p5:P5-GEO-02:theory:ru:v1'
),
(
'p5:P5-GEO-02:tutor:uz:v2','P5','P5-GEO-02','uz','tutor_v2_learner_first',
'Geometrik ehtimolliklar',
$t$Har bir mustaqil sinovdagi muvaffaqiyat ehtimoli p bo‘lgan geometrik X uchun

P(X=r)=(1-p)^(r-1)p.

Birinchi muvaffaqiyat r-sinovda bo‘lishi uchun avvalgi r-1 sinov muvaffaqiyatsiz, r-sinov esa muvaffaqiyatli bo‘lishi kerak.

p=0.25 bo‘lsin. Unda

P(X=3)
=(0.75)²(0.25)
=0.140625.

Birinchi 3 sinovda hali muvaffaqiyat bo‘lmasa,

P(X>3)=(0.75)³=0.421875.

Shuning uchun

P(X≤3)=1-P(X>3)
=1-(0.75)³
=0.578125.

Savol matni aynan bir sinovdagi birinchi muvaffaqiyat, hali kutish yoki yig‘ma ehtimollik kerakligini belgilaydi. To‘ldiruvchi hodisa ko‘pincha eng qisqa yo‘l bo‘ladi.$t$,
$t$Geometrik model uchun

P(X=r)=(1-p)^(r-1)p.

p=0.25 bo‘lsa:

P(X=3)=(0.75)²(0.25)=0.140625.

Shuningdek,

P(X>3)=(0.75)³=0.421875,

demak

P(X≤3)=0.578125.$t$,
$t$Muvaffaqiyat va muvaffaqiyatsizliklar ketma-ketligini tasavvur qiling.

X=3 uchun:

muvaffaqiyatsizlik, muvaffaqiyatsizlik, muvaffaqiyat.

Shuning uchun ehtimollik (1-p)²p.

X>3 bo‘lishi uchun dastlabki uch sinovning barchasi muvaffaqiyatsiz bo‘lishi kerak, ya’ni (1-p)³.$t$,
$t$Birinchi muvaffaqiyatgacha bo‘lgan muvaffaqiyatsizliklarni to‘g‘ri sanang: X=r uchun ularning soni r-1. X>r uchun dastlabki r sinov muvaffaqiyatsiz. “Shu vaqtgacha”, “ichida” yoki “ko‘pi bilan” shartlarida to‘ldiruvchi hodisa ko‘pincha qulay.$t$,
'p5:P5-GEO-02:theory:uz:v1'
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
