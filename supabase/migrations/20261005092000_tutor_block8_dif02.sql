begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>105 then raise exception 'DIF02 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-DIF-02' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DIF02 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-DIF-02:tutor:en:v2','P1','P1-DIF-02','en','tutor_v2_learner_first','Differentiating powers',
$t$For an allowed rational power n, use the power rule

d/dx(x^n)=n x^(n-1).

Differentiate a linear combination term by term; constant factors stay in front.

For example,

y=4x³+3√x
=4x³+3x^(1/2).

Then

dy/dx
=12x²+(3/2)x^(-1/2)
=12x²+3/(2√x).

The pattern is always “bring the power down, then reduce the exponent by 1”. Rewrite roots or reciprocals as powers first when that makes the rule easier to apply.$t$,
$t$Power rule:

d/dx(x^n)=n x^(n-1).

For

y=4x³+3√x,

rewrite √x as x^(1/2), then differentiate each term:

dy/dx=12x²+3/(2√x).$t$,
$t$Think of the exponent as doing two jobs when you differentiate:

1. it moves down in front as a multiplier;
2. it then decreases by 1.

So x³ becomes 3x². For √x=x^(1/2), the multiplier becomes 1/2 and the new power is -1/2.

Apply that same two-step pattern to each term separately.$t$,
$t$Rewrite roots and reciprocals as powers when useful. Multiply by the old exponent before subtracting 1 from it. Differentiate constants to zero and keep constant coefficients attached to their terms.$t$,
'p1:P1-DIF-02:theory:en:v1'
),
(
'p1:P1-DIF-02:tutor:ru:v2','P1','P1-DIF-02','ru','tutor_v2_learner_first','Производные степенных функций',
$t$Для допустимой рациональной степени n используйте правило:

d/dx(x^n)=n x^(n-1).

Линейную комбинацию дифференцируйте по членам; постоянный множитель остаётся перед производной.

Например,

y=4x³+3√x
=4x³+3x^(1/2).

Тогда

dy/dx
=12x²+(3/2)x^(-1/2)
=12x²+3/(2√x).

Шаблон один и тот же: степень переносится вперёд как множитель, затем показатель уменьшается на 1. Корни и обратные степени удобно сначала переписать в степенном виде.$t$,
$t$Правило степени:

d/dx(x^n)=n x^(n-1).

Для

y=4x³+3√x

перепишите √x как x^(1/2) и дифференцируйте каждый член:

dy/dx=12x²+3/(2√x).$t$,
$t$У показателя степени при дифференцировании две роли:

1. он становится множителем перед выражением;
2. затем уменьшается на 1.

Поэтому x³ превращается в 3x². Для √x=x^(1/2) коэффициент становится 1/2, а новая степень равна -1/2.

Тот же двухшаговый принцип применяется к каждому члену.$t$,
$t$Корни и дробные степени при необходимости переписывайте как степени x. Сначала умножьте на старый показатель, затем уменьшите показатель на 1. Производная константы равна нулю; постоянные коэффициенты сохраняются.$t$,
'p1:P1-DIF-02:theory:ru:v1'
),
(
'p1:P1-DIF-02:tutor:uz:v2','P1','P1-DIF-02','uz','tutor_v2_learner_first','Darajali funksiyalar hosilasi',
$t$Ruxsat etilgan ratsional n daraja uchun daraja qoidasidan foydalaning:

d/dx(x^n)=n x^(n-1).

Chiziqli yig‘indidagi har bir hadni alohida differensiallang; doimiy koeffitsiyent oldinda qoladi.

Masalan,

y=4x³+3√x
=4x³+3x^(1/2).

Shunda

dy/dx
=12x²+(3/2)x^(-1/2)
=12x²+3/(2√x).

Andoza bir xil: daraja oldinga koeffitsiyent bo‘lib tushadi, keyin daraja ko‘rsatkichi 1 ga kamayadi. Ildiz yoki teskari darajani qoida qulay bo‘lsa avval x darajasi ko‘rinishiga o‘tkazing.$t$,
$t$Daraja qoidasi:

d/dx(x^n)=n x^(n-1).

y=4x³+3√x uchun √x ni x^(1/2) deb yozing va har bir hadni alohida differensiallang:

dy/dx=12x²+3/(2√x).$t$,
$t$Differensiallashda daraja ko‘rsatkichi ikki ish qiladi:

1. oldinga koeffitsiyent bo‘lib tushadi;
2. keyin 1 ga kamayadi.

Shuning uchun x³ → 3x². √x=x^(1/2) uchun koeffitsiyent 1/2, yangi daraja esa -1/2 bo‘ladi.

Har bir hadga shu ikki qadamni qo‘llang.$t$,
$t$Ildiz va teskari darajalarni kerak bo‘lsa x darajasi ko‘rinishiga yozing. Avval eski darajaga ko‘paytiring, keyin darajani 1 ga kamaytiring. Doimiy sonning hosilasi nol, doimiy koeffitsiyent esa had bilan qoladi.$t$,
'p1:P1-DIF-02:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
