begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>189 then raise exception 'PRO03 expected 189 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-PRO-03' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'PRO03 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-PRO-03:tutor:en:v2','P5','P5-PRO-03','en','tutor_v2_learner_first','Addition rule and complements',
$t$For events that may overlap, the probability of “A or B” is

P(A∪B)=P(A)+P(B)-P(A∩B).

The intersection is subtracted because outcomes that belong to both events were counted once in P(A) and again in P(B).

For example, if

P(A)=0.6,
P(B)=0.5,
P(A∩B)=0.2,

then

P(A∪B)=0.6+0.5-0.2=0.9.

A complement is everything outside an event, so

P(A')=1-P(A)=1-0.6=0.4.

If A and B are mutually exclusive, their intersection is zero and the addition rule reduces to simple addition.$t$,
$t$For “A or B” use

P(A∪B)=P(A)+P(B)-P(A∩B).

With 0.6, 0.5 and overlap 0.2:

P(A∪B)=0.9.

For the complement:

P(A')=1-P(A)=0.4.

If A and B cannot happen together, the overlap is 0.$t$,
$t$Imagine two overlapping regions. Adding P(A) and P(B) paints the overlap twice. Subtracting P(A∩B) once fixes that double count.

A complement is the rest of the whole probability space. Since the total probability is 1, whatever is not in A must have probability 1-P(A).

Both rules are really bookkeeping rules for avoiding missing or double-counting outcomes.$t$,
$t$Do not add probabilities blindly. Ask whether the events overlap. If they do, subtract the intersection once. “Mutually exclusive” means P(A∩B)=0; it does not mean independent. For complements, subtract from 1 only when the event and its complement cover the whole sample space.$t$,
'p5:P5-PRO-03:theory:en:v1'
),
(
'p5:P5-PRO-03:tutor:ru:v2','P5','P5-PRO-03','ru','tutor_v2_learner_first','Сложение вероятностей и дополнение',
$t$Если события могут пересекаться, вероятность «A или B» равна

P(A∪B)=P(A)+P(B)-P(A∩B).

Пересечение вычитается, потому что исходы, принадлежащие обоим событиям, уже были посчитаны один раз в P(A) и ещё раз в P(B).

Например, если

P(A)=0.6,
P(B)=0.5,
P(A∩B)=0.2,

то

P(A∪B)=0.6+0.5-0.2=0.9.

Дополнение — это всё, что не входит в событие, поэтому

P(A')=1-P(A)=1-0.6=0.4.

Если A и B несовместны, их пересечение равно нулю и правило превращается в обычное сложение.$t$,
$t$Для «A или B» используйте

P(A∪B)=P(A)+P(B)-P(A∩B).

При 0.6, 0.5 и пересечении 0.2:

P(A∪B)=0.9.

Для дополнения:

P(A')=1-P(A)=0.4.

Если события не могут произойти вместе, пересечение равно 0.$t$,
$t$Представьте две пересекающиеся области. Если просто сложить P(A) и P(B), общая часть будет посчитана дважды. Вычитание P(A∩B) один раз исправляет этот повтор.

Дополнение — вся оставшаяся часть пространства исходов. Поскольку общая вероятность равна 1, вне A остаётся 1-P(A).

Оба правила помогают не пропустить и не посчитать исходы дважды.$t$,
$t$Не складывайте вероятности автоматически. Сначала проверьте, пересекаются ли события. Если да, вычтите пересечение один раз. «Несовместные» означает P(A∩B)=0, а не «независимые». Для дополнения вычитайте из 1 только когда событие и его дополнение покрывают всё пространство исходов.$t$,
'p5:P5-PRO-03:theory:ru:v1'
),
(
'p5:P5-PRO-03:tutor:uz:v2','P5','P5-PRO-03','uz','tutor_v2_learner_first','Ehtimollarni qo‘shish va to‘ldiruvchi hodisa',
$t$Hodisalar kesishishi mumkin bo‘lsa, “A yoki B” ehtimoli

P(A∪B)=P(A)+P(B)-P(A∩B)

formula bilan topiladi.

Kesishma ayiriladi, chunki ikkala hodisaga ham tegishli natijalar P(A) da ham, P(B) da ham bir martadan sanalgan.

Masalan,

P(A)=0.6,
P(B)=0.5,
P(A∩B)=0.2

bo‘lsa,

P(A∪B)=0.6+0.5-0.2=0.9.

To‘ldiruvchi hodisa A ga kirmaydigan barcha natijalar, shuning uchun

P(A')=1-P(A)=1-0.6=0.4.

A va B bir vaqtda sodir bo‘la olmasa, kesishma nol bo‘ladi va oddiy qo‘shish yetarli.$t$,
$t$“A yoki B” uchun

P(A∪B)=P(A)+P(B)-P(A∩B).

0.6, 0.5 va kesishma 0.2 bo‘lsa:

P(A∪B)=0.9.

To‘ldiruvchi hodisa uchun:

P(A')=1-P(A)=0.4.

A va B birga sodir bo‘la olmasa, kesishma 0.$t$,
$t$Ikkita ustma-ust tushadigan sohani tasavvur qiling. P(A) va P(B) ni qo‘shsangiz, umumiy qism ikki marta sanaladi. P(A∩B) ni bir marta ayirish shu takrorni tuzatadi.

To‘ldiruvchi hodisa esa butun fazoning A dan tashqaridagi qismidir. Jami ehtimollik 1 bo‘lgani uchun, A dan tashqarida 1-P(A) qoladi.$t$,
$t$Ehtimollarni avtomatik qo‘shmang. Hodisalar kesishadimi, avval tekshiring. Kesishsa, kesishmani bir marta ayiring. “O‘zaro istisno” P(A∩B)=0 degani, “mustaqil” degani emas. To‘ldiruvchi hodisa uchun faqat hodisa va uning tashqarisi butun fazoni qoplaganda 1 dan ayiring.$t$,
'p5:P5-PRO-03:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
