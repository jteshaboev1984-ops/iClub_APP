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
  if v<>192 then raise exception 'PRO04 expected 192 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-04')<>0
  then raise exception 'PRO04 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-PRO-04' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'PRO04 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-PRO-04:tutor:en:v2','P5','P5-PRO-04','en','tutor_v2_learner_first',
'Multiplication rule and independence',
$t$For two events A and B, the general multiplication rule is

P(A ∩ B)=P(A)P(B|A).

The second probability is conditional because what happened first may change what can happen next.

If A and B are independent, knowing A happened does not change the probability of B. Then

P(B|A)=P(B),

so

P(A ∩ B)=P(A)P(B).

For example, toss a fair coin and roll a fair die. The coin result does not affect the die.

P(head and 6)=1/2 × 1/6 = 1/12.

Independence is a condition, not a signal to multiply whenever you see “and”. If one event changes the probability of the other, use the conditional probability instead.$t$,
$t$The general rule is

P(A ∩ B)=P(A)P(B|A).

If A and B are independent, then P(B|A)=P(B), so

P(A ∩ B)=P(A)P(B).

For a fair coin and fair die:

P(head and 6)=1/2 × 1/6 = 1/12.

Multiply ordinary probabilities only when independence is justified.$t$,
$t$Think of “and” as following one path through two events.

First A happens. Then B happens under whatever conditions A has created. That is why the second factor is P(B|A).

With independent events, the first step changes nothing for the second step, so P(B|A) stays equal to P(B).$t$,
$t$Do not treat “and” as an automatic instruction to multiply marginal probabilities. Ask whether the events are independent. If they are not, the second factor must reflect the updated condition: P(B|A).$t$,
'p5:P5-PRO-04:theory:en:v1'
),
(
'p5:P5-PRO-04:tutor:ru:v2','P5','P5-PRO-04','ru','tutor_v2_learner_first',
'Умножение вероятностей и независимость',
$t$Для двух событий A и B общее правило умножения:

P(A ∩ B)=P(A)P(B|A).

Вторая вероятность условная, потому что первое событие может изменить условия для второго.

Если A и B независимы, знание о наступлении A не меняет вероятность B. Тогда

P(B|A)=P(B),

и поэтому

P(A ∩ B)=P(A)P(B).

Например, бросаем честную монету и честный кубик. Результат монеты не влияет на кубик.

P(орёл и 6)=1/2 × 1/6 = 1/12.

Независимость — это условие, а не разрешение автоматически умножать вероятности при слове «и». Если первое событие меняет вероятность второго, нужно использовать условную вероятность.$t$,
$t$Общее правило:

P(A ∩ B)=P(A)P(B|A).

Если события независимы, P(B|A)=P(B), поэтому

P(A ∩ B)=P(A)P(B).

Для честной монеты и честного кубика:

P(орёл и 6)=1/2 × 1/6 = 1/12.

Обычные вероятности можно перемножать только при обоснованной независимости.$t$,
$t$Представьте «A и B» как один путь из двух шагов.

Сначала происходит A. Затем происходит B уже в условиях, созданных первым событием. Поэтому второй множитель — P(B|A).

При независимости первый шаг ничего не меняет для второго, значит P(B|A)=P(B).$t$,
$t$Не воспринимайте слово «и» как автоматическую команду умножить две обычные вероятности. Сначала проверьте независимость. Если события зависимы, второй множитель должен учитывать изменившиеся условия: P(B|A).$t$,
'p5:P5-PRO-04:theory:ru:v1'
),
(
'p5:P5-PRO-04:tutor:uz:v2','P5','P5-PRO-04','uz','tutor_v2_learner_first',
'Ehtimollarni ko‘paytirish va mustaqillik',
$t$Ikki A va B hodisa uchun umumiy ko‘paytirish qoidasi:

P(A ∩ B)=P(A)P(B|A).

Ikkinchi ehtimollik shartli, chunki birinchi hodisa keyingi hodisa uchun sharoitni o‘zgartirishi mumkin.

A va B mustaqil bo‘lsa, A sodir bo‘lgani B ehtimolini o‘zgartirmaydi. Unda

P(B|A)=P(B),

shuning uchun

P(A ∩ B)=P(A)P(B).

Masalan, adolatli tanga tashlanadi va adolatli kubik otiladi. Tanga natijasi kubikka ta’sir qilmaydi.

P(gerb va 6)=1/2 × 1/6 = 1/12.

Mustaqillik — tekshiriladigan shart. “Va” so‘zini ko‘rib oddiy ehtimollarni avtomatik ko‘paytirmang; birinchi hodisa ikkinchisining ehtimolini o‘zgartirsa, shartli ehtimoldan foydalaning.$t$,
$t$Umumiy qoida:

P(A ∩ B)=P(A)P(B|A).

A va B mustaqil bo‘lsa, P(B|A)=P(B), demak

P(A ∩ B)=P(A)P(B).

Adolatli tanga va adolatli kubik uchun:

P(gerb va 6)=1/2 × 1/6 = 1/12.

Oddiy ehtimollarni faqat mustaqillik asoslanganida ko‘paytiring.$t$,
$t$“A va B” ni ikki bosqichli bitta yo‘l deb tasavvur qiling.

Avval A sodir bo‘ladi. Keyin B birinchi hodisa yaratgan sharoitda sodir bo‘ladi. Shu sabab ikkinchi ko‘paytuvchi P(B|A).

Hodisalar mustaqil bo‘lsa, birinchi bosqich ikkinchisiga ta’sir qilmaydi va P(B|A)=P(B) bo‘lib qoladi.$t$,
$t$“Va” so‘zini ko‘rib ikki oddiy ehtimolni avtomatik ko‘paytirmang. Avval mustaqillikni tekshiring. Hodisalar bog‘liq bo‘lsa, ikkinchi ko‘paytuvchi yangilangan shartni hisobga olishi kerak: P(B|A).$t$,
'p5:P5-PRO-04:theory:uz:v1'
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
