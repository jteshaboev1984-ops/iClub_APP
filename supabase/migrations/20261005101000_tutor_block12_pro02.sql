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
  if v<>186 then raise exception 'PRO02 expected 186 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-02')<>0
  then raise exception 'PRO02 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-PRO-02' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'PRO02 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-PRO-02:tutor:en:v2','P5','P5-PRO-02','en','tutor_v2_learner_first',
'Probability by counting',
$t$When many outcomes are equally likely, you do not need to list them one by one. You can count the total number of possible outcomes and the number that satisfy the event.

Suppose 2 objects are chosen from 6, where 3 are red and 3 are blue. Order does not matter, so use combinations.

Total selections:

C(6,2)=15.

Selections with both objects red:

C(3,2)=3.

Therefore

P(both red)=3/15=1/5.

The numerator and denominator must describe outcomes from the same model. If the denominator counts unordered selections, the numerator must also count unordered selections. The key decision is whether order matters; once that is clear, counting can replace a long sample-space list.$t$,
$t$Use counting when all outcomes are equally likely.

Choose 2 from 6 objects, with 3 red and 3 blue.

Total selections:

C(6,2)=15.

Both red:

C(3,2)=3.

So

P(both red)=3/15=1/5.

Because order does not matter, combinations are the correct counting tool.$t$,
$t$Think of probability as a ratio of counts.

The denominator asks: how many equally likely outcomes are possible?
The numerator asks: how many of those outcomes satisfy the event?

For choosing 2 objects, a pair such as red 1 + red 2 is the same selection whichever one is named first, so combinations avoid double-counting order that does not matter.$t$,
$t$First decide whether order matters. Use the same counting model in numerator and denominator. Only divide favourable count by total count when those counted outcomes are equally likely. Simplify the final probability, not the counting structure halfway through.$t$,
'p5:P5-PRO-02:theory:en:v1'
),
(
'p5:P5-PRO-02:tutor:ru:v2','P5','P5-PRO-02','ru','tutor_v2_learner_first',
'Вероятность через подсчёт',
$t$Если возможных равновероятных исходов много, их не обязательно перечислять по одному. Можно посчитать общее число исходов и число тех, которые удовлетворяют событию.

Пусть из 6 объектов выбирают 2, причём 3 объекта красные и 3 синие. Порядок выбора не важен, поэтому используем сочетания.

Всего выборов:

C(6,2)=15.

Выборов, где оба объекта красные:

C(3,2)=3.

Следовательно,

P(оба красные)=3/15=1/5.

Числитель и знаменатель должны описывать исходы одной и той же модели. Если в знаменателе считаются неупорядоченные пары, в числителе нужно считать такие же пары. Сначала решите, важен ли порядок, и только затем выбирайте способ подсчёта.$t$,
$t$Подсчёт удобен, когда все исходы равновероятны.

Выбираем 2 объекта из 6, где 3 красных и 3 синих.

Всего выборов:

C(6,2)=15.

Оба красные:

C(3,2)=3.

Поэтому

P(оба красные)=3/15=1/5.

Порядок не важен, значит нужны сочетания.$t$,
$t$Представьте вероятность как отношение двух количеств.

Знаменатель: сколько всего равновероятных исходов возможно?
Числитель: сколько из них подходят событию?

При выборе двух объектов одна и та же пара не становится новой только потому, что предметы названы в другом порядке. Поэтому сочетания не считают лишний порядок.$t$,
$t$Сначала решите, важен ли порядок. В числителе и знаменателе используйте одну и ту же модель подсчёта. Делить число подходящих исходов на общее число можно только для равновероятных исходов.$t$,
'p5:P5-PRO-02:theory:ru:v1'
),
(
'p5:P5-PRO-02:tutor:uz:v2','P5','P5-PRO-02','uz','tutor_v2_learner_first',
'Sanash usullari bilan ehtimollik',
$t$Teng ehtimolli natijalar juda ko‘p bo‘lsa, ularni bittalab yozish shart emas. Mumkin bo‘lgan natijalar sonini va hodisaga mos natijalar sonini sanash mumkin.

6 ta obyekt ichidan 2 tasi tanlansin; 3 tasi qizil, 3 tasi ko‘k. Tartib muhim emas, shuning uchun kombinatsiyadan foydalanamiz.

Barcha tanlashlar soni:

C(6,2)=15.

Ikkalasi ham qizil bo‘lgan tanlashlar:

C(3,2)=3.

Demak,

P(ikkalasi ham qizil)=3/15=1/5.

Surat va maxraj bir xil modeldagi natijalarni sanashi kerak. Agar maxraj tartibsiz juftliklarni sanasa, surat ham shunday juftliklarni sanashi kerak. Avval tartib muhimmi yoki yo‘qmi aniqlang, keyin sanash usulini tanlang.$t$,
$t$Natijalar teng ehtimolli bo‘lsa, sanash usulidan foydalanish mumkin.

6 ta obyekt ichidan 2 ta tanlanadi; 3 tasi qizil, 3 tasi ko‘k.

Barcha tanlashlar:

C(6,2)=15.

Ikkalasi ham qizil:

C(3,2)=3.

Shuning uchun

P(ikkalasi ham qizil)=3/15=1/5.

Tartib muhim emas, demak kombinatsiya ishlatiladi.$t$,
$t$Ehtimollikni ikki sonning nisbati deb o‘ylang.

Maxraj: nechta teng ehtimolli natija bor?
Surat: ulardan nechtasi hodisaga mos?

Ikki obyekt tanlanganda bir xil juftlik elementlarni boshqa tartibda aytish bilan yangi natijaga aylanmaydi. Kombinatsiya ana shu ortiqcha tartibni sanamaydi.$t$,
$t$Avval tartib muhim yoki yo‘qligini aniqlang. Surat va maxrajda bir xil sanash modelidan foydalaning. “Mos natijalar / barcha natijalar” faqat sanalayotgan natijalar teng ehtimolli bo‘lsa to‘g‘ri ishlaydi.$t$,
'p5:P5-PRO-02:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,
  source_card_key,approval_status,is_runtime_allowed,content_hash
)
select tutor_card_key,component_code,skill_code,locale,content_version,title,
       main_explanation,simple_explanation,alternative_explanation,focus_explanation,
       source_card_key,'draft',false,
       md5(concat_ws('||',content_version,title,main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key))
from seed;

commit;
