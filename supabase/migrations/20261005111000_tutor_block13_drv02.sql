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
  if v<>204 then raise exception 'DRV02 expected 204 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DRV-02')<>0
  then raise exception 'DRV02 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DRV-02' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DRV02 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-DRV-02:tutor:en:v2','P5','P5-DRV-02','en','tutor_v2_learner_first',
'Expectation of a discrete random variable',
$t$The expectation E(X) is the probability-weighted mean of a discrete random variable:

E(X)=ΣxP(X=x).

Use the value of X as the outcome and weight it by how likely that outcome is.

Suppose X takes values 0, 1 and 2 with probabilities 0.2, 0.3 and 0.5.

Then

E(X)=0(0.2)+1(0.3)+2(0.5)
=0+0.3+1.0
=1.3.

The value 1.3 does not mean X must ever equal 1.3 in one trial. X can only be 0, 1 or 2. Expectation describes the long-run average value you would expect across many repetitions of the same random process.$t$,
$t$Use

E(X)=ΣxP(X=x).

For X=0,1,2 with probabilities 0.2,0.3,0.5:

E(X)=0(0.2)+1(0.3)+2(0.5)=1.3.

Expectation is a long-run average. It does not have to be one of the possible values of X.$t$,
$t$Think of each outcome as contributing “value × probability” to the average.

The outcome 2 is quite likely here, with probability 0.5, so it contributes 2×0.5=1 to the expectation. Adding all such weighted contributions gives the centre of balance of the distribution: 1.3.$t$,
$t$Multiply each x-value by its own probability before adding. Check the probabilities sum to 1 first. Interpret E(X) as a long-run mean, not as a guaranteed result from one trial.$t$,
'p5:P5-DRV-02:theory:en:v1'
),
(
'p5:P5-DRV-02:tutor:ru:v2','P5','P5-DRV-02','ru','tutor_v2_learner_first',
'Математическое ожидание дискретной величины',
$t$Математическое ожидание E(X) — это среднее значение дискретной случайной величины с учётом вероятностей:

E(X)=ΣxP(X=x).

Каждое возможное значение X умножается на вероятность этого значения.

Пусть X принимает 0, 1 и 2 с вероятностями 0.2, 0.3 и 0.5.

Тогда

E(X)=0(0.2)+1(0.3)+2(0.5)
=0+0.3+1.0
=1.3.

Число 1.3 не означает, что в одном испытании X обязано принять значение 1.3. Возможные значения по-прежнему только 0, 1 и 2. Математическое ожидание показывает долгосрочное среднее при большом числе повторений одного и того же случайного процесса.$t$,
$t$Используйте

E(X)=ΣxP(X=x).

Для X=0,1,2 с вероятностями 0.2,0.3,0.5:

E(X)=0(0.2)+1(0.3)+2(0.5)=1.3.

Это долгосрочное среднее. Оно не обязано быть одним из возможных значений X.$t$,
$t$Можно представить, что каждый исход вносит в среднее вклад «значение × вероятность».

Значение 2 имеет вероятность 0.5, поэтому его вклад равен 2×0.5=1. Сложение всех таких вкладов даёт центр распределения — здесь 1.3.$t$,
$t$Умножайте каждое значение x на его собственную вероятность, а затем складывайте. Сначала проверьте, что вероятности в сумме дают 1. E(X) — это долгосрочное среднее, а не гарантированный результат одного испытания.$t$,
'p5:P5-DRV-02:theory:ru:v1'
),
(
'p5:P5-DRV-02:tutor:uz:v2','P5','P5-DRV-02','uz','tutor_v2_learner_first',
'Diskret tasodifiy miqdorning matematik kutilmasi',
$t$E(X) matematik kutilma — diskret tasodifiy miqdorning ehtimolliklar bilan og‘irlangan o‘rtacha qiymati:

E(X)=ΣxP(X=x).

Har bir mumkin X qiymati o‘z ehtimolligiga ko‘paytiriladi.

X 0, 1 va 2 qiymatlarni 0.2, 0.3 va 0.5 ehtimolliklar bilan qabul qilsin.

Unda

E(X)=0(0.2)+1(0.3)+2(0.5)
=0+0.3+1.0
=1.3.

1.3 soni bitta tajribada X aynan 1.3 bo‘lishi kerak degani emas. X faqat 0, 1 yoki 2 bo‘lishi mumkin. Matematik kutilma bir xil tasodifiy jarayon juda ko‘p takrorlangandagi uzoq muddatli o‘rtacha qiymatni ifodalaydi.$t$,
$t$Quyidagidan foydalaning:

E(X)=ΣxP(X=x).

X=0,1,2 va ehtimolliklar 0.2,0.3,0.5 bo‘lsa:

E(X)=0(0.2)+1(0.3)+2(0.5)=1.3.

Matematik kutilma uzoq muddatli o‘rtacha; u X ning mumkin qiymatlaridan biri bo‘lishi shart emas.$t$,
$t$Har bir natijani o‘rtachaga “qiymat × ehtimollik” miqdorida hissa qo‘shadi deb o‘ylang.

Bu yerda 2 qiymati 0.5 ehtimollikka ega, shuning uchun uning hissasi 2×0.5=1. Barcha hissalarni qo‘shsak, taqsimotning muvozanat markazi — 1.3 chiqadi.$t$,
$t$Har bir x qiymatini aynan o‘z ehtimolligiga ko‘paytirib, keyin yig‘ing. Avval ehtimolliklar yig‘indisi 1 ekanini tekshiring. E(X) ni bitta tajribaning kafolatlangan natijasi emas, uzoq muddatli o‘rtacha sifatida talqin qiling.$t$,
'p5:P5-DRV-02:theory:uz:v1'
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
