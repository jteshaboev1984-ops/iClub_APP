begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>183 then raise exception 'PRO01 expected 183 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-01')<>0
  then raise exception 'PRO01 Tutor Cards already exist'; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-PRO-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'PRO01 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-PRO-01:tutor:en:v2','P5','P5-PRO-01','en','tutor_v2_learner_first','Sample spaces',
$t$A sample space is the complete list of possible outcomes of a random experiment, with no outcome missing and no outcome counted twice.

For two coin tosses, order matters because the first and second toss are different stages. The sample space is

HH, HT, TH, TT.

There are four outcomes. For example, the event “exactly one head” contains HT and TH.

Writing the sample space clearly helps you see what an event actually contains and prevents double counting. If the outcomes are equally likely, probabilities can then be found by comparing the number of favourable outcomes with the total number of outcomes.$t$,
$t$For two coin tosses, the complete sample space is

HH, HT, TH, TT.

Do not leave out TH just because HT is already listed: the order of the tosses is different.

The event “exactly one head” is {HT, TH}.

A correct sample space contains every possible outcome exactly once.$t$,
$t$Think of a sample space as a checklist of everything that can happen.

For two tosses, build the list stage by stage:

first toss H or T,
then for each of those, second toss H or T.

This creates HH, HT, TH and TT. Once the checklist is complete, an event is simply a selected subset of those outcomes.$t$,
$t$Check completeness and duplication. Keep ordered outcomes separate when stages are distinguishable. Do not use favourable/total counting unless the outcomes you are counting are equally likely. An event can contain several outcomes; it is not the same thing as one outcome.$t$,
'p5:P5-PRO-01:theory:en:v1'
),
(
'p5:P5-PRO-01:tutor:ru:v2','P5','P5-PRO-01','ru','tutor_v2_learner_first','Пространство исходов',
$t$Пространство исходов — это полный список возможных результатов случайного эксперимента: без пропусков и без повторного счёта одного и того же исхода.

Для двух бросков монеты порядок важен, потому что первый и второй бросок — разные этапы. Пространство исходов:

HH, HT, TH, TT.

Всего четыре исхода. Например, событие «ровно один орёл» содержит HT и TH.

Чётко записанное пространство исходов помогает понять, из каких исходов состоит событие, и не считать что-либо дважды. Если исходы равновероятны, вероятность затем можно находить как отношение числа благоприятных исходов к общему числу исходов.$t$,
$t$Для двух бросков монеты полное пространство исходов:

HH, HT, TH, TT.

Не убирайте TH только потому, что уже есть HT: порядок бросков различается.

Событие «ровно один орёл» — {HT, TH}.

Правильное пространство содержит каждый возможный исход ровно один раз.$t$,
$t$Представьте пространство исходов как контрольный список всего, что может произойти.

Для двух бросков стройте список по этапам:

первый бросок H или T,
затем для каждого варианта второй бросок H или T.

Получаются HH, HT, TH и TT. После этого событие — просто выбранная часть полного списка.$t$,
$t$Проверяйте полноту и отсутствие повторов. Если этапы различимы, сохраняйте порядок исходов. Не используйте отношение «благоприятные / все», если подсчитанные исходы не равновероятны. Событие может включать несколько исходов.$t$,
'p5:P5-PRO-01:theory:ru:v1'
),
(
'p5:P5-PRO-01:tutor:uz:v2','P5','P5-PRO-01','uz','tutor_v2_learner_first','Natijalar fazosi',
$t$Natijalar fazosi — tasodifiy tajribada sodir bo‘lishi mumkin bo‘lgan barcha natijalarning to‘liq ro‘yxati. Hech bir natija tushib qolmasligi va bir natija ikki marta sanalmasligi kerak.

Tangani ikki marta tashlashda tartib muhim, chunki birinchi va ikkinchi tashlash alohida bosqichlar. Natijalar fazosi:

HH, HT, TH, TT.

Jami to‘rtta natija bor. Masalan, “aynan bitta H” hodisasi HT va TH natijalaridan iborat.

Natijalar fazosini aniq yozish hodisa ichida qaysi natijalar borligini ko‘rsatadi va ikki marta sanashdan saqlaydi. Natijalar teng ehtimolli bo‘lsa, keyin ehtimollikni qulay natijalar sonini jami natijalar soniga bo‘lib topish mumkin.$t$,
$t$Tangani ikki marta tashlash uchun to‘liq natijalar fazosi:

HH, HT, TH, TT.

HT yozilgani uchun TH ni olib tashlamang: tashlashlar tartibi boshqa.

“Aynan bitta H” hodisasi {HT, TH}.

To‘g‘ri natijalar fazosida har bir mumkin natija aynan bir marta bo‘ladi.$t$,
$t$Natijalar fazosini sodir bo‘lishi mumkin bo‘lgan barcha holatlarning tekshiruv ro‘yxati deb o‘ylang.

Ikki tashlash uchun bosqichma-bosqich tuzing:

birinchi tashlash H yoki T,
har biri uchun ikkinchi tashlash H yoki T.

Shunda HH, HT, TH va TT hosil bo‘ladi. Hodisa esa shu to‘liq ro‘yxatning tanlangan qismidir.$t$,
$t$Ro‘yxat to‘liq va takrorsiz ekanini tekshiring. Bosqichlar farqli bo‘lsa, tartiblangan natijalarni alohida saqlang. Faqat sanalayotgan natijalar teng ehtimolli bo‘lsa “qulay / jami” usulidan foydalaning. Hodisa bir nechta natijani o‘z ichiga olishi mumkin.$t$,
'p5:P5-PRO-01:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
