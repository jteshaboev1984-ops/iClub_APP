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
  if v<>195 then raise exception 'PRO05 expected 195 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-05')<>0
  then raise exception 'PRO05 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-PRO-05' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'PRO05 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-PRO-05:tutor:en:v2','P5','P5-PRO-05','en','tutor_v2_learner_first',
'Conditional probability',
$t$Conditional probability asks for the probability of A after we already know that B has happened. The condition changes the relevant sample space.

The rule is

P(A|B)=P(A ∩ B)/P(B),

provided P(B)>0.

Suppose there are 20 students. 12 study Mathematics, 8 study Physics, and 5 study both subjects.

If we are told that the chosen student studies Mathematics, we no longer consider all 20 students. The new relevant group contains 12 Mathematics students, and 5 of those also study Physics.

Therefore

P(Physics | Mathematics)=5/12.

The denominator comes from the condition after the vertical bar. A useful way to think about conditional probability is: first restrict the population to B, then ask what fraction of that restricted group also satisfies A.$t$,
$t$Conditional probability means the sample space has been restricted.

Use

P(A|B)=P(A ∩ B)/P(B).

If 12 students study Mathematics and 5 of those also study Physics, then

P(Physics | Mathematics)=5/12.

The condition after the vertical bar tells you the new denominator.$t$,
$t$Think of conditioning as zooming in.

At first there are 20 students. Once the question says “given that the student studies Mathematics”, everyone outside the 12 Mathematics students disappears from the sample space.

Inside that smaller group, 5 also study Physics. So the required probability is 5 out of 12.$t$,
$t$Read the condition after the vertical bar first. It tells you which group becomes the new sample space. Do not divide by the original total after conditioning. Check that the condition has non-zero probability.$t$,
'p5:P5-PRO-05:theory:en:v1'
),
(
'p5:P5-PRO-05:tutor:ru:v2','P5','P5-PRO-05','ru','tutor_v2_learner_first',
'Условная вероятность',
$t$Условная вероятность — это вероятность события A при уже известном условии, что событие B произошло. Условие меняет пространство, в котором мы считаем вероятность.

Формула:

P(A|B)=P(A ∩ B)/P(B),

если P(B)>0.

Пусть есть 20 учеников. 12 изучают математику, 8 — физику, а 5 изучают оба предмета.

Если известно, что выбранный ученик изучает математику, все 20 уже не являются подходящим знаменателем. Новая группа состоит из 12 учеников, изучающих математику, и 5 из них также изучают физику.

Поэтому

P(физика | математика)=5/12.

Знаменатель задаётся условием после вертикальной черты. Сначала ограничьте пространство событием B, затем найдите долю A внутри этой новой группы.$t$,
$t$Условная вероятность означает, что пространство исходов уже ограничено.

Используйте

P(A|B)=P(A ∩ B)/P(B).

Если 12 учеников изучают математику и 5 из них также изучают физику, то

P(физика | математика)=5/12.

Условие после вертикальной черты задаёт новый знаменатель.$t$,
$t$Представьте условие как увеличение нужной части данных.

Сначала есть 20 учеников. После слов «при условии, что ученик изучает математику» все, кто не входит в 12 учеников с математикой, больше не участвуют.

Внутри этой уменьшенной группы 5 изучают ещё и физику. Поэтому вероятность равна 5 из 12.$t$,
$t$Сначала прочитайте условие после вертикальной черты: оно определяет новое пространство исходов. После условия не делите на исходное общее количество. Также убедитесь, что вероятность условия не равна нулю.$t$,
'p5:P5-PRO-05:theory:ru:v1'
),
(
'p5:P5-PRO-05:tutor:uz:v2','P5','P5-PRO-05','uz','tutor_v2_learner_first',
'Shartli ehtimollik',
$t$Shartli ehtimollik B hodisa sodir bo‘lgani ma’lum bo‘lgandan keyin A hodisaning ehtimolini so‘raydi. Shart hisoblanadigan natijalar fazosini toraytiradi.

Formula:

P(A|B)=P(A ∩ B)/P(B),

agar P(B)>0 bo‘lsa.

20 ta o‘quvchi bo‘lsin. 12 tasi Matematikani, 8 tasi Fizikani o‘rganadi, 5 tasi esa ikkala fanni ham o‘rganadi.

Tanlangan o‘quvchi Matematikani o‘rganishi ma’lum bo‘lsa, endi barcha 20 o‘quvchi maxraj bo‘lmaydi. Yangi guruhda 12 ta Matematikani o‘rganuvchi bor va ulardan 5 tasi Fizikani ham o‘rganadi.

Shuning uchun

P(Fizika | Matematika)=5/12.

Vertikal chiziqdan keyingi shart yangi maxrajni belgilaydi. Avval B guruhigacha toraytiring, keyin shu guruh ichida A ulushini toping.$t$,
$t$Shartli ehtimollik natijalar fazosi torayganini bildiradi.

Formula:

P(A|B)=P(A ∩ B)/P(B).

Agar 12 ta o‘quvchi Matematikani o‘rgansa va ulardan 5 tasi Fizikani ham o‘rgansa,

P(Fizika | Matematika)=5/12.

Vertikal chiziqdan keyingi shart yangi maxrajni ko‘rsatadi.$t$,
$t$Shartni tasvirni yaqinlashtirish deb o‘ylang.

Avval 20 ta o‘quvchi bor. “O‘quvchi Matematikani o‘rganadi” degan shart kelgach, Matematika guruhiga kirmaydiganlar natijalar fazosidan chiqadi.

Qolgan 12 kishining 5 tasi Fizikani ham o‘rganadi. Demak, kerakli ehtimollik 5/12.$t$,
$t$Avval vertikal chiziqdan keyingi shartni o‘qing: u yangi natijalar fazosini beradi. Shart qo‘yilgandan keyin boshlang‘ich umumiy sonni maxrajda qoldirmang. Shart ehtimoli nol emasligini ham tekshiring.$t$,
'p5:P5-PRO-05:theory:uz:v1'
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
