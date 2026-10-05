begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>195 then raise exception 'PRO05 expected 195 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-PRO-05' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'PRO05 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-PRO-05:tutor:en:v2','P5','P5-PRO-05','en','tutor_v2_learner_first','Conditional probability',
$t$Conditional probability asks for the chance of A after we already know that B has occurred. The sample space is therefore restricted to B.

The formula is

P(A|B)=P(A∩B)/P(B).

For example, if

P(A∩B)=0.18

and

P(B)=0.6,

then

P(A|B)=0.18/0.6=0.3.

The denominator is P(B) because once B is known, only outcomes inside B remain possible. The numerator keeps the outcomes that are inside both A and B.

This is why conditional probability is not usually the same as P(A): the information that B occurred may change the relevant sample space.$t$,
$t$Conditional probability means “probability of A given B”.

Use

P(A|B)=P(A∩B)/P(B).

If P(A∩B)=0.18 and P(B)=0.6:

P(A|B)=0.3.

Once B is known, B becomes the new sample space.$t$,
$t$Imagine zooming in until only event B is visible.

Before the condition, the whole probability space is available. After learning that B occurred, everything outside B is impossible.

Inside this smaller space, A happens only in the overlap A∩B. So the conditional probability is

overlap / B.$t$,
$t$Read the order carefully: P(A|B) means A given B, so divide by P(B), not P(A). The numerator must be the intersection. If A and B are independent, conditioning on B will not change P(A), but do not assume that without evidence.$t$,
'p5:P5-PRO-05:theory:en:v1'
),
(
'p5:P5-PRO-05:tutor:ru:v2','P5','P5-PRO-05','ru','tutor_v2_learner_first','Условная вероятность',
$t$Условная вероятность — это вероятность события A после того, как уже известно, что произошло B. Поэтому пространство исходов сужается до события B.

Формула:

P(A|B)=P(A∩B)/P(B).

Например, если

P(A∩B)=0.18

и

P(B)=0.6,

то

P(A|B)=0.18/0.6=0.3.

В знаменателе стоит P(B), потому что после информации о B возможными остаются только исходы внутри B. В числителе остаются исходы, которые одновременно принадлежат A и B.

Поэтому условная вероятность обычно не равна P(A): новая информация может изменить рассматриваемое пространство.$t$,
$t$Условная вероятность означает «вероятность A при условии B».

Используйте

P(A|B)=P(A∩B)/P(B).

Если P(A∩B)=0.18 и P(B)=0.6:

P(A|B)=0.3.

После того как B известно, B становится новым пространством исходов.$t$,
$t$Представьте, что вы увеличили только область B и больше ничего не видите.

До условия доступно всё пространство исходов. После информации, что B произошло, всё вне B становится невозможным.

Внутри нового пространства событие A представлено только пересечением A∩B. Поэтому условная вероятность — это

пересечение / B.$t$,
$t$Внимательно читайте порядок: P(A|B) означает A при условии B, поэтому делить нужно на P(B), а не на P(A). В числителе должно быть пересечение. При независимости условие B не изменит P(A), но это нельзя предполагать без основания.$t$,
'p5:P5-PRO-05:theory:ru:v1'
),
(
'p5:P5-PRO-05:tutor:uz:v2','P5','P5-PRO-05','uz','tutor_v2_learner_first','Shartli ehtimollik',
$t$Shartli ehtimollik B hodisa sodir bo‘lganini bilganimizdan keyin A hodisaning ehtimolini so‘raydi. Shuning uchun natijalar fazosi B hodisaga qisqaradi.

Formula:

P(A|B)=P(A∩B)/P(B).

Masalan,

P(A∩B)=0.18

va

P(B)=0.6

bo‘lsa,

P(A|B)=0.18/0.6=0.3.

Maxrajda P(B) turadi, chunki B sodir bo‘lgani ma’lum bo‘lgach faqat B ichidagi natijalar mumkin. Surat esa A va B ga bir vaqtda tegishli natijalarni oladi.

Shu sabab shartli ehtimollik odatda P(A) bilan bir xil emas: yangi ma’lumot ko‘rilayotgan fazoni o‘zgartirishi mumkin.$t$,
$t$Shartli ehtimollik “B berilganda A ehtimoli” degani.

P(A|B)=P(A∩B)/P(B).

Agar P(A∩B)=0.18 va P(B)=0.6 bo‘lsa:

P(A|B)=0.3.

B sodir bo‘lgani ma’lum bo‘lgach, B yangi natijalar fazosiga aylanadi.$t$,
$t$Faqat B hodisasi ko‘rinadigan qilib tasvirni yaqinlashtirganingizni tasavvur qiling.

Shartdan oldin butun natijalar fazosi mavjud. B sodir bo‘lganini bilganimizdan keyin B tashqarisidagi hamma narsa imkonsiz bo‘ladi.

Shu kichik fazoda A faqat A∩B kesishma orqali ko‘rinadi. Demak, shartli ehtimollik

kesishma / B.$t$,
$t$Tartibni diqqat bilan o‘qing: P(A|B) — B berilganda A, shuning uchun P(B) ga bo‘linadi, P(A) ga emas. Surat kesishma bo‘lishi kerak. A va B mustaqil bo‘lsa, B sharti P(A) ni o‘zgartirmaydi, lekin buni dalilsiz taxmin qilmang.$t$,
'p5:P5-PRO-05:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
