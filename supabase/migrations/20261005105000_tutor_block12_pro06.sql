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
  if v<>198 then raise exception 'PRO06 expected 198 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-06')<>0
  then raise exception 'PRO06 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-PRO-06' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'PRO06 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-PRO-06:tutor:en:v2','P5','P5-PRO-06','en','tutor_v2_learner_first',
'Probability trees',
$t$A probability tree organises a sequence of events. Each branch shows the probability of the next outcome under the conditions created by the earlier branches.

Suppose a bag contains 3 red and 2 blue counters. Two counters are drawn without replacement.

For red then blue:

P(R then B)=3/5 × 2/4 = 3/10.

For blue then red:

P(B then R)=2/5 × 3/4 = 3/10.

These two complete paths are mutually exclusive, so

P(one of each)=3/10+3/10=3/5.

The second-stage denominator is 4, not 5, because one counter has already been removed. On a tree, multiply probabilities along one path and add probabilities of different complete paths that make up the required event.$t$,
$t$For sequential events, a tree keeps the changing probabilities organised.

Bag: 3 red, 2 blue. Draw 2 without replacement.

P(RB)=3/5×2/4=3/10.
P(BR)=2/5×3/4=3/10.

So

P(one of each)=3/10+3/10=3/5.

Without replacement, update the second branch because only 4 counters remain.$t$,
$t$Think of each complete route through the tree as one possible story.

One story is red then blue; another is blue then red. To find the probability of one story, multiply along its branches. To combine different stories that all satisfy the event, add their final path probabilities.

Without replacement, the story changes what is available next, so later branch probabilities must be updated.$t$,
$t$At every split, branch probabilities should sum to 1. Multiply along a path; add across separate complete paths. Without replacement, update both numerator and denominator after each draw. Do not reuse the first-stage probabilities automatically.$t$,
'p5:P5-PRO-06:theory:en:v1'
),
(
'p5:P5-PRO-06:tutor:ru:v2','P5','P5-PRO-06','ru','tutor_v2_learner_first',
'Деревья вероятностей',
$t$Дерево вероятностей организует последовательность событий. Каждая ветвь показывает вероятность следующего исхода с учётом того, что произошло раньше.

Пусть в мешке 3 красных и 2 синих фишки. Две фишки выбирают без возвращения.

Красная, затем синяя:

P(R затем B)=3/5 × 2/4 = 3/10.

Синяя, затем красная:

P(B затем R)=2/5 × 3/4 = 3/10.

Эти два полных пути несовместны, поэтому

P(по одной каждого цвета)=3/10+3/10=3/5.

На втором шаге знаменатель равен 4, а не 5, потому что одна фишка уже удалена. В дереве вероятности вдоль одного пути перемножают, а вероятности разных полных путей нужного события складывают.$t$,
$t$Дерево удобно для последовательных событий с меняющимися вероятностями.

В мешке 3 красных и 2 синих фишки. Выбираем 2 без возвращения.

P(RB)=3/5×2/4=3/10.
P(BR)=2/5×3/4=3/10.

Поэтому

P(по одной каждого цвета)=3/10+3/10=3/5.

Без возвращения на втором шаге остаются только 4 фишки.$t$,
$t$Представьте каждый полный путь дерева как отдельный сценарий.

Один сценарий: красная, затем синяя. Другой: синяя, затем красная. Вероятность одного сценария находится умножением вдоль ветвей. Если несколько разных сценариев подходят событию, их итоговые вероятности складывают.

При выборе без возвращения предыдущий шаг меняет то, что осталось для следующего.$t$,
$t$В каждой точке разветвления вероятности ветвей должны давать 1. Вдоль пути вероятности перемножаются, разные подходящие полные пути складываются. При выборе без возвращения после каждого шага обновляйте и числитель, и знаменатель.$t$,
'p5:P5-PRO-06:theory:ru:v1'
),
(
'p5:P5-PRO-06:tutor:uz:v2','P5','P5-PRO-06','uz','tutor_v2_learner_first',
'Ehtimollik daraxtlari',
$t$Ehtimollik daraxti ketma-ket hodisalarni tartib bilan ko‘rsatadi. Har bir shox oldingi natijalar yaratgan sharoitda keyingi natijaning ehtimolini beradi.

Xaltada 3 ta qizil va 2 ta ko‘k chip bo‘lsin. Ikki chip qaytarmasdan olinadi.

Avval qizil, keyin ko‘k:

P(R keyin B)=3/5 × 2/4 = 3/10.

Avval ko‘k, keyin qizil:

P(B keyin R)=2/5 × 3/4 = 3/10.

Bu ikki to‘liq yo‘l bir vaqtda sodir bo‘la olmaydi, shuning uchun

P(har rangdan bittadan)=3/10+3/10=3/5.

Ikkinchi bosqichda maxraj 5 emas, 4, chunki bitta chip allaqachon olingan. Daraxtda bitta yo‘l bo‘ylab ehtimollar ko‘paytiriladi, kerakli hodisaga olib boradigan turli to‘liq yo‘llar esa qo‘shiladi.$t$,
$t$Ehtimollik daraxti ketma-ket hodisalarda o‘zgaradigan ehtimollarni tartiblaydi.

Xaltada 3 qizil, 2 ko‘k chip bor. 2 tasi qaytarmasdan olinadi.

P(RB)=3/5×2/4=3/10.
P(BR)=2/5×3/4=3/10.

Demak,

P(har rangdan bittadan)=3/10+3/10=3/5.

Qaytarmasdan tanlashda ikkinchi bosqichda faqat 4 ta chip qoladi.$t$,
$t$Daraxtdagi har bir to‘liq yo‘lni alohida voqea ketma-ketligi deb o‘ylang.

Bir yo‘l qizil-keyin-ko‘k, boshqasi ko‘k-keyin-qizil. Bitta yo‘l ehtimoli shoxlar bo‘ylab ko‘paytirish bilan topiladi. Bir hodisaga olib boradigan turli to‘liq yo‘llarning ehtimollari esa qo‘shiladi.

Qaytarmasdan tanlashda oldingi natija keyingi bosqichdagi tarkibni o‘zgartiradi.$t$,
$t$Har bir ajralish nuqtasida shoxlar ehtimollari yig‘indisi 1 bo‘lsin. Yo‘l bo‘ylab ko‘paytiring, alohida mos to‘liq yo‘llarni qo‘shing. Qaytarmasdan tanlashda har bir bosqichdan keyin surat va maxrajni yangilang.$t$,
'p5:P5-PRO-06:theory:uz:v1'
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
