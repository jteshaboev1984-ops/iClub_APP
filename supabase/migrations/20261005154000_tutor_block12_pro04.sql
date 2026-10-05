begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>192 then raise exception 'PRO04 expected 192 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-PRO-04' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'PRO04 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-PRO-04:tutor:en:v2','P5','P5-PRO-04','en','tutor_v2_learner_first','Multiplication rule and independence',
$t$Two events are independent when knowing that one happened does not change the probability of the other. For independent events,

P(A∩B)=P(A)P(B).

For example, suppose

P(A)=0.4,
P(B)=0.5,
P(A∩B)=0.2.

Since

0.4×0.5=0.2,

the intersection equals the product of the separate probabilities, so A and B are independent.

The same rule can be used forward when independence is already known: multiply the probabilities to find the chance that both events occur.

Independence should be justified from the information or checked from probabilities; it should not be assumed merely because two events sound unrelated.$t$,
$t$For independent events,

P(A∩B)=P(A)P(B).

If P(A)=0.4 and P(B)=0.5, their product is 0.2.

If P(A∩B) is also 0.2, the events are independent.

Use multiplication only when independence is given or established.$t$,
$t$Think of independence as “no probability update”.

If event B happens and that information does not change the chance of A, then the two events are independent.

Algebraically this means the probability of both occurring factors into two separate probabilities:

P(A∩B)=P(A)P(B).

The product rule is therefore a test as well as a calculation rule.$t$,
$t$Do not confuse independent with mutually exclusive. Independent events can occur together; mutually exclusive events cannot. Before multiplying P(A) and P(B), make sure independence is known or verify that the intersection equals the product.$t$,
'p5:P5-PRO-04:theory:en:v1'
),
(
'p5:P5-PRO-04:tutor:ru:v2','P5','P5-PRO-04','ru','tutor_v2_learner_first','Умножение вероятностей и независимость',
$t$Два события независимы, если информация о наступлении одного не меняет вероятность другого. Для независимых событий

P(A∩B)=P(A)P(B).

Например, пусть

P(A)=0.4,
P(B)=0.5,
P(A∩B)=0.2.

Поскольку

0.4×0.5=0.2,

вероятность пересечения совпадает с произведением отдельных вероятностей, значит A и B независимы.

Если независимость уже известна, то это же правило используется для вычисления вероятности совместного наступления событий.

Независимость нужно получить из условия или проверить по вероятностям; её нельзя предполагать только потому, что события кажутся несвязанными.$t$,
$t$Для независимых событий

P(A∩B)=P(A)P(B).

Если P(A)=0.4 и P(B)=0.5, произведение равно 0.2.

Если P(A∩B) тоже равно 0.2, события независимы.

Умножайте отдельные вероятности только когда независимость дана или доказана.$t$,
$t$Представьте независимость как «вероятность не обновилась».

Если событие B произошло, но это не изменило вероятность A, события независимы.

Алгебраически это означает:

P(A∩B)=P(A)P(B).

Поэтому правило произведения может быть и способом вычисления, и проверкой независимости.$t$,
$t$Не путайте независимые и несовместные события. Независимые события могут произойти вместе, несовместные — нет. Перед умножением P(A) и P(B) убедитесь, что независимость известна, или проверьте равенство пересечения произведению.$t$,
'p5:P5-PRO-04:theory:ru:v1'
),
(
'p5:P5-PRO-04:tutor:uz:v2','P5','P5-PRO-04','uz','tutor_v2_learner_first','Ehtimollarni ko‘paytirish va mustaqillik',
$t$Ikki hodisa mustaqil bo‘lsa, birining sodir bo‘lgani haqidagi ma’lumot ikkinchisining ehtimolini o‘zgartirmaydi. Mustaqil hodisalar uchun

P(A∩B)=P(A)P(B).

Masalan,

P(A)=0.4,
P(B)=0.5,
P(A∩B)=0.2

bo‘lsin.

Chunki

0.4×0.5=0.2,

kesishma ehtimoli alohida ehtimollar ko‘paytmasiga teng, demak A va B mustaqil.

Mustaqillik oldindan ma’lum bo‘lsa, shu formula ikkala hodisaning birga sodir bo‘lish ehtimolini topish uchun ishlatiladi.

Mustaqillik shartdan kelib chiqishi yoki ehtimollar orqali tekshirilishi kerak; hodisalar mavzu jihatdan alohida ko‘ringani uchun uni taxmin qilmang.$t$,
$t$Mustaqil hodisalar uchun

P(A∩B)=P(A)P(B).

P(A)=0.4 va P(B)=0.5 bo‘lsa, ko‘paytma 0.2.

Agar P(A∩B) ham 0.2 bo‘lsa, hodisalar mustaqil.

Faqat mustaqillik berilgan yoki tasdiqlangan bo‘lsa alohida ehtimollarni ko‘paytiring.$t$,
$t$Mustaqillikni “ehtimol yangilanmaydi” deb o‘ylang.

B hodisa sodir bo‘lganini bilish A ehtimolini o‘zgartirmasa, ular mustaqil.

Algebraik ko‘rinish:

P(A∩B)=P(A)P(B).

Shu sabab ko‘paytirish qoidasi ham hisoblash, ham mustaqillikni tekshirish vositasi.$t$,
$t$Mustaqil hodisalarni o‘zaro istisno hodisalar bilan aralashtirmang. Mustaqil hodisalar birga sodir bo‘lishi mumkin; o‘zaro istisno hodisalar esa yo‘q. P(A) va P(B) ni ko‘paytirishdan oldin mustaqillikni tasdiqlang.$t$,
'p5:P5-PRO-04:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
