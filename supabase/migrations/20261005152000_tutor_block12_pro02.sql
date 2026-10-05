begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>186 then raise exception 'PRO02 expected 186 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-PRO-02' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'PRO02 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-PRO-02:tutor:en:v2','P5','P5-PRO-02','en','tutor_v2_learner_first','Probability by counting',
$t$When all outcomes in the counting model are equally likely, probability can be found by counting:

P(event) = favourable outcomes / total outcomes.

Suppose 2 balls are chosen from 5 balls: 2 red and 3 blue. We only care which two balls are chosen, not their order.

The total number of pairs is

5C2 = 10.

To get two red balls, both red balls must be selected:

2C2 = 1.

Therefore

P(two red) = 1/10.

The important step comes before the arithmetic: define the outcomes so they are equally likely and count each outcome once. Combinations are useful here because the selection is unordered.$t$,
$t$If equally likely outcomes can be counted,

probability = favourable / total.

From 5 balls, 2 red and 3 blue, choose 2 without order.

Total pairs = 5C2 = 10.

Two-red pairs = 2C2 = 1.

So P(two red)=1/10.$t$,
$t$Think of counting probability as building two matching lists.

The denominator counts every equally likely outcome of the experiment.

The numerator counts only the outcomes that satisfy the event.

Both counts must use the same definition of an outcome. Here an unordered pair is one outcome, so combinations are used for both numerator and denominator.$t$,
$t$Confirm equiprobability before using favourable/total. Use the same ordering convention in numerator and denominator. If the experiment selects a group rather than an ordered sequence, combinations usually avoid counting the same group several times.$t$,
'p5:P5-PRO-02:theory:en:v1'
),
(
'p5:P5-PRO-02:tutor:ru:v2','P5','P5-PRO-02','ru','tutor_v2_learner_first','Вероятность через подсчёт',
$t$Если все исходы выбранной модели равновероятны, вероятность можно найти через подсчёт:

P(события) = число благоприятных исходов / общее число исходов.

Пусть из 5 шаров — 2 красных и 3 синих — выбирают 2 шара. Нас интересует только пара выбранных шаров, а не порядок.

Общее число пар:

5C2 = 10.

Чтобы получить два красных, нужно выбрать оба красных шара:

2C2 = 1.

Поэтому

P(два красных) = 1/10.

Главный шаг выполняется до вычислений: исходы должны быть определены так, чтобы они были равновероятны и каждый считался один раз. Здесь удобно использовать сочетания, потому что выбор неупорядоченный.$t$,
$t$Если равновероятные исходы можно посчитать,

вероятность = благоприятные / все.

Из 5 шаров, где 2 красных и 3 синих, выбираем 2 без учёта порядка.

Всего пар = 5C2 = 10.

Пар из двух красных = 2C2 = 1.

Значит, P(два красных)=1/10.$t$,
$t$Представьте подсчёт вероятности как два согласованных списка.

Знаменатель считает все равновероятные исходы эксперимента.

Числитель считает только те исходы, которые удовлетворяют событию.

В обоих подсчётах исход должен определяться одинаково. Здесь исход — неупорядоченная пара, поэтому и числитель, и знаменатель считаются сочетаниями.$t$,
$t$Перед отношением «благоприятные / все» убедитесь, что исходы равновероятны. В числителе и знаменателе используйте один и тот же принцип порядка. Если выбирается группа, а не последовательность, сочетания обычно предотвращают повторный счёт одной группы.$t$,
'p5:P5-PRO-02:theory:ru:v1'
),
(
'p5:P5-PRO-02:tutor:uz:v2','P5','P5-PRO-02','uz','tutor_v2_learner_first','Sanash usullari bilan ehtimollik',
$t$Agar tanlangan modeldagi barcha natijalar teng ehtimolli bo‘lsa, ehtimollikni sanash orqali topish mumkin:

P(hodisa) = qulay natijalar soni / jami natijalar soni.

5 ta shardan 2 tasi qizil, 3 tasi ko‘k. Ulardan 2 tasi tanlanadi. Bizga qaysi ikki shar tanlangani muhim, ularning tartibi emas.

Jami juftliklar soni:

5C2 = 10.

Ikki qizil chiqishi uchun ikkala qizil shar tanlanadi:

2C2 = 1.

Demak,

P(ikki qizil) = 1/10.

Asosiy qadam hisoblashdan oldin: natijalarni teng ehtimolli va takrorsiz qilib aniqlang. Bu yerda tanlov tartibsiz bo‘lgani uchun kombinatsiya qulay.$t$,
$t$Teng ehtimolli natijalarni sanash mumkin bo‘lsa,

ehtimollik = qulay / jami.

5 ta shardan 2 tasi qizil, 3 tasi ko‘k. 2 ta shar tartibsiz tanlanadi.

Jami juftlik = 5C2 = 10.

Ikki qizil juftlik = 2C2 = 1.

Shuning uchun P(ikki qizil)=1/10.$t$,
$t$Sanash orqali ehtimollikni ikki mos ro‘yxat deb o‘ylang.

Maxraj tajribadagi barcha teng ehtimolli natijalarni sanaydi.

Surat faqat hodisaga mos natijalarni sanaydi.

Ikkala sanashda ham “natija” bir xil ma’noga ega bo‘lishi kerak. Bu yerda natija tartibsiz juftlik, shuning uchun ikkala tomonda kombinatsiya ishlatiladi.$t$,
$t$“Qulay / jami” formulasidan oldin natijalar teng ehtimolli ekanini tekshiring. Surat va maxrajda tartibga bir xil munosabatda bo‘ling. Guruh tanlanayotgan bo‘lsa, kombinatsiya bir xil guruhni bir necha marta sanashdan saqlaydi.$t$,
'p5:P5-PRO-02:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
