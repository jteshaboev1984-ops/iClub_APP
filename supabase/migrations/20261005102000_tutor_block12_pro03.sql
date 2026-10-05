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
  if v<>189 then raise exception 'PRO03 expected 189 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-PRO-03')<>0
  then raise exception 'PRO03 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-PRO-03' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'PRO03 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-PRO-03:tutor:en:v2','P5','P5-PRO-03','en','tutor_v2_learner_first',
'Addition rule and complements',
$t$When an event can happen through A or B, the addition rule prevents overlap from being counted twice:

P(A ∪ B)=P(A)+P(B)-P(A ∩ B).

Suppose one fair die is rolled.

A = even = {2,4,6}
and
B = greater than 4 = {5,6}.

The overlap is

A ∩ B = {6}.

Therefore

P(A ∪ B)=3/6+2/6-1/6=4/6=2/3.

If A and B are mutually exclusive, their overlap is empty, so P(A ∩ B)=0 and the probabilities add directly.

A complement means “not A”:

P(A')=1-P(A).

The key idea is to identify whether events overlap before adding. Subtract the shared part once so each outcome is counted exactly once.$t$,
$t$Use

P(A ∪ B)=P(A)+P(B)-P(A ∩ B).

For a fair die, let A={2,4,6} and B={5,6}. Their overlap is {6}.

So

P(A ∪ B)=3/6+2/6-1/6=2/3.

If events are mutually exclusive, the overlap is 0. For a complement, use P(A')=1-P(A).$t$,
$t$Imagine colouring the outcomes in A and then colouring the outcomes in B. Any outcome in both sets gets coloured twice.

The addition rule first adds both sets, then subtracts the overlap once. If the sets do not overlap, there is nothing to subtract. A complement is simply everything in the sample space outside the event.$t$,
$t$Before adding probabilities, ask whether the events overlap. Do not use P(A)+P(B) automatically. For mutually exclusive events, intersection is 0. For “not”, “none”, or “at least one” questions, a complement may be the shortest route.$t$,
'p5:P5-PRO-03:theory:en:v1'
),
(
'p5:P5-PRO-03:tutor:ru:v2','P5','P5-PRO-03','ru','tutor_v2_learner_first',
'Сложение вероятностей и дополнение',
$t$Если событие может произойти через A или B, правило сложения не позволяет дважды посчитать пересечение:

P(A ∪ B)=P(A)+P(B)-P(A ∩ B).

Пусть бросают честный кубик.

A = чётное = {2,4,6},
B = больше 4 = {5,6}.

Пересечение:

A ∩ B = {6}.

Поэтому

P(A ∪ B)=3/6+2/6-1/6=4/6=2/3.

Если A и B несовместны, пересечение пусто, значит P(A ∩ B)=0 и вероятности можно просто сложить.

Дополнение означает «не A»:

P(A')=1-P(A).

Главная идея — сначала определить, есть ли пересечение. Общую часть нужно вычесть один раз, чтобы каждый исход был посчитан ровно один раз.$t$,
$t$Используйте

P(A ∪ B)=P(A)+P(B)-P(A ∩ B).

Для честного кубика пусть A={2,4,6}, B={5,6}. Их пересечение — {6}.

Тогда

P(A ∪ B)=3/6+2/6-1/6=2/3.

Для несовместных событий пересечение равно 0. Для дополнения используйте P(A')=1-P(A).$t$,
$t$Представьте, что исходы A закрашены одним цветом, а исходы B — другим. Исходы в пересечении окажутся закрашены дважды.

Правило сложения сначала складывает оба набора, затем один раз вычитает пересечение. Если пересечения нет, вычитать нечего. Дополнение — это все исходы пространства, которые не принадлежат событию.$t$,
$t$Перед сложением вероятностей проверьте, пересекаются ли события. Не используйте P(A)+P(B) автоматически. Для несовместных событий пересечение равно 0. В задачах «не», «ни одного» или «хотя бы один» часто удобнее использовать дополнение.$t$,
'p5:P5-PRO-03:theory:ru:v1'
),
(
'p5:P5-PRO-03:tutor:uz:v2','P5','P5-PRO-03','uz','tutor_v2_learner_first',
'Ehtimollarni qo‘shish va to‘ldiruvchi hodisa',
$t$Hodisa A yoki B orqali yuz berishi mumkin bo‘lsa, qo‘shish qoidasi kesishmani ikki marta sanashdan saqlaydi:

P(A ∪ B)=P(A)+P(B)-P(A ∩ B).

Adolatli kubik tashlansin.

A = juft = {2,4,6},
B = 4 dan katta = {5,6}.

Kesishma:

A ∩ B = {6}.

Shuning uchun

P(A ∪ B)=3/6+2/6-1/6=4/6=2/3.

A va B o‘zaro istisno bo‘lsa, kesishma bo‘sh, ya’ni P(A ∩ B)=0 va ehtimollar to‘g‘ridan-to‘g‘ri qo‘shiladi.

To‘ldiruvchi hodisa “A emas” degani:

P(A')=1-P(A).

Asosiy g‘oya — qo‘shishdan oldin hodisalar kesishadimi yoki yo‘qmi aniqlash.$t$,
$t$Quyidagidan foydalaning:

P(A ∪ B)=P(A)+P(B)-P(A ∩ B).

Adolatli kubikda A={2,4,6}, B={5,6}. Ularning kesishmasi {6}.

Demak,

P(A ∪ B)=3/6+2/6-1/6=2/3.

O‘zaro istisno hodisalarda kesishma 0. To‘ldiruvchi hodisa uchun P(A')=1-P(A).$t$,
$t$A dagi natijalarni bir rang, B dagilarni boshqa rang bilan belgilayotganingizni tasavvur qiling. Kesishmadagi natijalar ikki marta belgilanadi.

Qo‘shish qoidasi avval ikki to‘plamni qo‘shadi, keyin kesishmani bir marta ayiradi. Kesishma bo‘lmasa, ayirish shart emas. To‘ldiruvchi hodisa esa natijalar fazosidagi A ga kirmaydigan barcha natijalardir.$t$,
$t$Ehtimollarni qo‘shishdan oldin hodisalar kesishadimi, tekshiring. P(A)+P(B) ni avtomatik ishlatmang. O‘zaro istisno hodisalarda kesishma 0. “Emas”, “hech biri” yoki “kamida bittasi” savollarida to‘ldiruvchi hodisa ko‘pincha qisqaroq yo‘l bo‘ladi.$t$,
'p5:P5-PRO-03:theory:uz:v1'
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
