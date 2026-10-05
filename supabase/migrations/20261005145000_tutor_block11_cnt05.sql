begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>180 then raise exception 'CNT05 expected 180 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-CNT-05' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'CNT05 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-CNT-05:tutor:en:v2','P5','P5-CNT-05','en','tutor_v2_learner_first','Combinations and mixed counting',
$t$A combination counts selections where order does not matter.

For example, choosing 3 people from 8 gives

8C3 = 56.

Every group of the same three people is counted once, regardless of the order in which their names are written.

Some questions then add an ordered stage. Suppose the chosen group of three must also have one chair. First choose the group, then choose which of the three becomes chair:

8C3 × 3 = 56×3 = 168.

This is a mixed selection-arrangement problem. The key is to separate the stages: use nCr for the unordered selection, then multiply by the number of distinct role or ordering choices that happen afterwards.$t$,
$t$If order does not matter, use a combination.

Choose 3 from 8:

8C3 = 56.

If the three selected people then need one chair:

8C3 × 3 = 168.

First count the unordered selection, then count the extra ordered role.$t$,
$t$Think of nCr as removing repeated orderings of the same group.

ABC, ACB, BAC and the other orders all describe one three-person selection, so a combination counts that group once.

If the problem later gives the selected people different roles, order matters again at that second stage. Then multiply the selection count by the number of role assignments.$t$,
$t$Separate “who is chosen?” from “what happens to the chosen people?”. Use nCr only for the unordered choice. If roles or positions are assigned afterwards, count that stage too. Do not multiply by extra orderings when the final outcome is still just a group.$t$,
'p5:P5-CNT-05:theory:en:v1'
),
(
'p5:P5-CNT-05:tutor:ru:v2','P5','P5-CNT-05','ru','tutor_v2_learner_first','Сочетания и смешанные задачи',
$t$Сочетание считает выборки, в которых порядок не важен.

Например, выбрать 3 человек из 8 можно

8C3 = 56

способами.

Одна и та же группа из трёх человек считается один раз независимо от порядка записи имён.

Иногда после выбора появляется упорядоченный этап. Пусть среди выбранных трёх нужно назначить одного председателя. Сначала выбираем группу, затем выбираем председателя из трёх:

8C3 × 3 = 56×3 = 168.

Это смешанная задача «выбор + размещение». Главное — разделить этапы: nCr используется для неупорядоченной выборки, затем умножаем на число различающихся ролей или порядков, которые назначаются после неё.$t$,
$t$Если порядок не важен, используйте сочетание.

Выбрать 3 из 8:

8C3 = 56.

Если затем среди этих троих нужно выбрать председателя:

8C3 × 3 = 168.

Сначала считайте неупорядоченную группу, затем дополнительную роль.$t$,
$t$Считайте nCr способом убрать повторные порядки одной и той же группы.

ABC, ACB, BAC и остальные перестановки описывают одну группу из трёх, поэтому сочетание считает её один раз.

Если потом выбранным людям назначаются разные роли, на втором этапе порядок снова становится важным. Тогда число выборок умножается на число распределений ролей.$t$,
$t$Разделяйте вопросы «кого выбрали?» и «что происходит с выбранными?». nCr используйте только для неупорядоченного выбора. Если затем назначаются роли или места, посчитайте и этот этап. Не добавляйте лишние перестановки, если итоговый результат остаётся просто группой.$t$,
'p5:P5-CNT-05:theory:ru:v1'
),
(
'p5:P5-CNT-05:tutor:uz:v2','P5','P5-CNT-05','uz','tutor_v2_learner_first','Kombinatsiyalar va aralash sanash',
$t$Kombinatsiya tartib muhim bo‘lmagan tanlovlarni hisoblaydi.

Masalan, 8 odamdan 3 tasini tanlash:

8C3 = 56.

Bir xil uch kishilik guruh ismlar qaysi tartibda yozilishidan qat’i nazar bir marta hisoblanadi.

Ba’zi masalalarda tanlovdan keyin tartibli bosqich keladi. Masalan, tanlangan uch kishidan bittasi rais bo‘lishi kerak. Avval guruhni tanlaymiz, keyin uch kishidan raisni tanlaymiz:

8C3 × 3 = 56×3 = 168.

Bu aralash tanlash-joylashtirish masalasi. Asosiy usul — bosqichlarni ajratish: tartibsiz tanlov uchun nCr, undan keyingi rol yoki tartib uchun alohida ko‘paytirish.$t$,
$t$Tartib muhim bo‘lmasa kombinatsiyadan foydalaning.

8 dan 3 tanlash:

8C3 = 56.

Agar tanlangan uch kishidan biri rais bo‘lsa:

8C3 × 3 = 168.

Avval tartibsiz guruhni, keyin qo‘shimcha rolni hisoblang.$t$,
$t$nCr ni bir xil guruhning turli yozilish tartiblarini olib tashlaydigan usul deb o‘ylang.

ABC, ACB, BAC va boshqa tartiblar bitta uch kishilik guruhni bildiradi, shuning uchun kombinatsiya uni bir marta sanaydi.

Agar keyin tanlangan odamlarga turli rollar berilsa, ikkinchi bosqichda tartib yana muhim bo‘ladi. Shunda tanlov sonini rol taqsimotlari soniga ko‘paytiring.$t$,
$t$“Kim tanlandi?” va “tanlanganlardan keyin nima qilinadi?” bosqichlarini ajrating. Tartibsiz tanlov uchun nCr ishlating. Keyin rol yoki o‘rin berilsa, shu bosqichni ham hisoblang. Yakuniy natija faqat guruh bo‘lsa, ortiqcha tartiblarni qo‘shmang.$t$,
'p5:P5-CNT-05:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
