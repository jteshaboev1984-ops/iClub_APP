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
  if v<>213 then raise exception 'BIN02 expected 213 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-BIN-02')<>0
  then raise exception 'BIN02 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-BIN-02' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'BIN02 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-BIN-02:tutor:en:v2','P5','P5-BIN-02','en','tutor_v2_learner_first',
'Binomial probabilities',
$t$For a binomial random variable,

P(X=r)=nCr p^r(1-p)^(n-r).

The first job is to translate the wording into the correct values of X.

Suppose X is binomial with n=5 and p=0.4.

For exactly 2 successes:

P(X=2)
=5C2(0.4)²(0.6)³
=0.3456.

For at most 1 success:

P(X≤1)
=P(X=0)+P(X=1)
=0.33696.

A cumulative probability combines several integer outcomes, not just one. For “at least” or “more than” questions, a complement can often be shorter than adding many terms. The important step is to identify the required integer values before pressing the calculator.$t$,
$t$If X is binomial,

P(X=r)=nCr p^r(1-p)^(n-r).

For n=5, p=0.4:

P(X=2)=0.3456.

For at most 1 success:

P(X≤1)=P(X=0)+P(X=1)=0.33696.

Translate the wording into the correct X-values before calculating.$t$,
$t$Think of the binomial distribution as separate probability bars at X=0,1,2,...,n.

“Exactly 2” means one bar.
“At most 1” means add the bars for 0 and 1.
“At least 1” can be easier as 1-P(X=0).

The wording tells you which bars belong in the required probability.$t$,
$t$Convert words carefully: exactly r means X=r; at most r means X≤r; fewer than r means X≤r-1; at least r means X≥r. Check whether a complement is shorter, and keep enough calculator accuracy until the final answer.$t$,
'p5:P5-BIN-02:theory:en:v1'
),
(
'p5:P5-BIN-02:tutor:ru:v2','P5','P5-BIN-02','ru','tutor_v2_learner_first',
'Биномиальные вероятности',
$t$Для биномиальной случайной величины

P(X=r)=nCr p^r(1-p)^(n-r).

Первый шаг — правильно перевести условие задачи в нужные значения X.

Пусть X имеет биномиальную модель с n=5 и p=0.4.

Для ровно 2 успехов:

P(X=2)
=5C2(0.4)²(0.6)³
=0.3456.

Для не более 1 успеха:

P(X≤1)
=P(X=0)+P(X=1)
=0.33696.

Накопленная вероятность объединяет несколько целых значений X, а не только одно. Для условий «не менее» или «больше» часто удобнее использовать дополнение, чем складывать много отдельных вероятностей. Сначала определите нужные значения X, затем считайте.$t$,
$t$Если X имеет биномиальную модель,

P(X=r)=nCr p^r(1-p)^(n-r).

При n=5, p=0.4:

P(X=2)=0.3456.

Для не более 1 успеха:

P(X≤1)=P(X=0)+P(X=1)=0.33696.

Сначала переведите слова задачи в правильные значения X.$t$,
$t$Представьте биномиальное распределение как отдельные столбики вероятности для X=0,1,2,...,n.

«Ровно 2» — один столбик.
«Не более 1» — сумма столбиков 0 и 1.
«Хотя бы 1» часто удобнее найти как 1-P(X=0).

Формулировка задачи показывает, какие столбики нужно объединить.$t$,
$t$Точно переводите слова: ровно r — X=r; не более r — X≤r; меньше r — X≤r-1; не менее r — X≥r. Проверьте, не проще ли использовать дополнение, и сохраняйте достаточную точность до финального ответа.$t$,
'p5:P5-BIN-02:theory:ru:v1'
),
(
'p5:P5-BIN-02:tutor:uz:v2','P5','P5-BIN-02','uz','tutor_v2_learner_first',
'Binomial ehtimolliklar',
$t$Binomial tasodifiy miqdor uchun

P(X=r)=nCr p^r(1-p)^(n-r).

Birinchi qadam — savol matnini X ning to‘g‘ri qiymatlariga aylantirish.

X uchun n=5 va p=0.4 bo‘lgan binomial model berilsin.

Aynan 2 muvaffaqiyat uchun:

P(X=2)
=5C2(0.4)²(0.6)³
=0.3456.

Ko‘pi bilan 1 muvaffaqiyat uchun:

P(X≤1)
=P(X=0)+P(X=1)
=0.33696.

Yig‘ma ehtimollik bitta emas, bir nechta butun X qiymatlarini birlashtiradi. “Kamida” yoki “ko‘proq” shartlarida ko‘p hadni qo‘shish o‘rniga to‘ldiruvchi hodisa qisqaroq bo‘lishi mumkin. Avval kerakli X qiymatlarini aniqlang, keyin hisoblang.$t$,
$t$X binomial bo‘lsa,

P(X=r)=nCr p^r(1-p)^(n-r).

n=5, p=0.4 uchun:

P(X=2)=0.3456.

Ko‘pi bilan 1 muvaffaqiyat:

P(X≤1)=P(X=0)+P(X=1)=0.33696.

Hisoblashdan oldin savol so‘zlarini to‘g‘ri X qiymatlariga aylantiring.$t$,
$t$Binomial taqsimotni X=0,1,2,...,n dagi alohida ehtimollik ustunlari deb tasavvur qiling.

“Aynan 2” — bitta ustun.
“Ko‘pi bilan 1” — 0 va 1 ustunlarini qo‘shish.
“Kamida 1” ni esa ko‘pincha 1-P(X=0) orqali topish osonroq.

Savol matni qaysi ustunlar kerakligini ko‘rsatadi.$t$,
$t$So‘zlarni aniq tarjima qiling: aynan r — X=r; ko‘pi bilan r — X≤r; r dan kam — X≤r-1; kamida r — X≥r. To‘ldiruvchi hodisa qisqaroqmi, tekshiring va yakuniy javobgacha yetarli aniqlikni saqlang.$t$,
'p5:P5-BIN-02:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select tutor_card_key,component_code,skill_code,locale,content_version,title,
       main_explanation,simple_explanation,alternative_explanation,focus_explanation,
       source_card_key,'draft',false,
       md5(concat_ws('||',content_version,title,main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key))
from seed;

commit;
