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
  if v<>183 then raise exception 'PRO01 expected 183 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-01')<>0
  then raise exception 'PRO01 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-PRO-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'PRO01 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-PRO-01:tutor:en:v2','P5','P5-PRO-01','en','tutor_v2_learner_first',
'Sample spaces',
$t$A sample space is the complete set of possible outcomes. The important word is complete: every valid outcome must appear once, with no omissions and no duplicates.

Suppose a fair coin is tossed twice. A careful sample space is

S = {HH, HT, TH, TT}.

HT and TH are different because the order of the two tosses is different. If the question asks for exactly one head, the favourable outcomes are

{HT, TH}.

All four outcomes are equally likely, so

P(exactly one head) = 2/4 = 1/2.

When you use “favourable outcomes ÷ total outcomes”, first check that the outcomes in your sample space are equally likely. A correct sample space is not just a list: it is the structure that makes the probability calculation trustworthy.$t$,
$t$A sample space lists every possible outcome exactly once.

For two fair coin tosses:

S = {HH, HT, TH, TT}.

Exactly one head happens in HT or TH, so

P(exactly one head)=2/4=1/2.

HT and TH are different because the order is different. Counting works directly here because all four outcomes are equally likely.$t$,
$t$Think of a sample space as a checklist. If one possible outcome is missing, your denominator is wrong. If one outcome is written twice, it gets too much weight.

For two coin tosses, a small tree also gives HH, HT, TH and TT. Reading the endpoints of the tree is another way to build the same complete sample space.$t$,
$t$Before calculating, ask: Have I listed every possible outcome once? Are these outcomes equally likely? Keep ordered outcomes separate when order changes the result: HT and TH are not the same sequence.$t$,
'p5:P5-PRO-01:theory:en:v1'
),
(
'p5:P5-PRO-01:tutor:ru:v2','P5','P5-PRO-01','ru','tutor_v2_learner_first',
'Пространство исходов',
$t$Пространство исходов — это полный набор всех возможных результатов. Главное слово — полный: каждый допустимый исход должен быть записан один раз, без пропусков и повторов.

Пусть честную монету бросают два раза. Тогда

S = {HH, HT, TH, TT}.

HT и TH — разные исходы, потому что порядок двух бросков различается. Если требуется ровно один орёл, подходящие исходы:

{HT, TH}.

Все четыре исхода равновероятны, поэтому

P(ровно один орёл) = 2/4 = 1/2.

Прежде чем использовать правило «подходящие исходы ÷ все исходы», убедитесь, что исходы действительно равновероятны. Правильно составленное пространство исходов — это основа дальнейшего расчёта вероятности.$t$,
$t$Пространство исходов перечисляет все возможные результаты ровно по одному разу.

Для двух бросков честной монеты:

S = {HH, HT, TH, TT}.

Ровно один орёл получается в HT и TH, поэтому

P(ровно один орёл)=2/4=1/2.

HT и TH различаются порядком. Здесь можно просто считать исходы, потому что все четыре равновероятны.$t$,
$t$Представьте пространство исходов как контрольный список. Если один исход пропущен, знаменатель будет неверным. Если один исход повторён, ему случайно приписывается слишком большой вес.

Для двух бросков монеты те же HH, HT, TH и TT можно получить по конечным ветвям небольшого дерева. Это другой способ построить тот же полный набор.$t$,
$t$Перед расчётом проверьте: все ли возможные исходы записаны ровно один раз и равновероятны ли они. Если порядок меняет результат, сохраняйте порядок: HT и TH — разные последовательности.$t$,
'p5:P5-PRO-01:theory:ru:v1'
),
(
'p5:P5-PRO-01:tutor:uz:v2','P5','P5-PRO-01','uz','tutor_v2_learner_first',
'Natijalar fazosi',
$t$Natijalar fazosi — barcha mumkin bo‘lgan natijalarning to‘liq to‘plami. Eng muhim narsa — to‘liqlik: har bir mumkin natija bir marta yozilishi, hech biri tushib qolmasligi yoki takrorlanmasligi kerak.

Adolatli tanga ikki marta tashlansin. Unda

S = {HH, HT, TH, TT}.

HT va TH turli natijalar, chunki ikki tashlashdagi tartib boshqacha. Aynan bitta gerb chiqishi kerak bo‘lsa, mos natijalar

{HT, TH}.

To‘rtta natijaning barchasi teng ehtimolli, shuning uchun

P(aynan bitta gerb) = 2/4 = 1/2.

“Mos natijalar ÷ barcha natijalar” usulini ishlatishdan oldin natijalar teng ehtimolli ekanini tekshiring. To‘g‘ri natijalar fazosi keyingi ehtimollik hisobining asosidir.$t$,
$t$Natijalar fazosi barcha mumkin natijalarni aynan bir martadan ko‘rsatadi.

Adolatli tanga ikki marta tashlansa:

S = {HH, HT, TH, TT}.

Aynan bitta gerb HT yoki TH da chiqadi, demak

P(aynan bitta gerb)=2/4=1/2.

HT va TH tartibi bilan farq qiladi. Bu yerda natijalar teng ehtimolli bo‘lgani uchun oddiy sanash mumkin.$t$,
$t$Natijalar fazosini tekshiruv ro‘yxati deb tasavvur qiling. Bitta natija tushib qolsa, maxraj noto‘g‘ri bo‘ladi. Bitta natija ikki marta yozilsa, unga ortiqcha og‘irlik beriladi.

Ikki tanga tashlashda HH, HT, TH va TT ni kichik daraxtning oxirgi shoxlaridan ham olish mumkin. Bu xuddi shu to‘liq fazoni qurishning boshqa usuli.$t$,
$t$Hisoblashdan oldin tekshiring: barcha mumkin natijalar bir martadan yozilganmi va ular teng ehtimollimi? Agar tartib natijani o‘zgartirsa, tartibni saqlang: HT va TH bir xil emas.$t$,
'p5:P5-PRO-01:theory:uz:v1'
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
