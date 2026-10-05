begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>129 then raise exception 'INT03 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-INT-03' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'INT03 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-INT-03:tutor:en:v2','P1','P1-INT-03','en','tutor_v2_learner_first','Definite integrals',
$t$A definite integral gives signed accumulation between two limits. Find an antiderivative, then calculate “upper value minus lower value”.

For the simple endpoint-improper example

∫ from 0 to 4 of x^(-1/2) dx,

the integrand is undefined at x=0, so the lower endpoint must be treated as a limit.

An antiderivative is 2√x. Therefore

lim as a→0+ of [2√x] from a to 4
= lim as a→0+ (4 - 2√a)
= 4.

The integral exists because the limiting value is finite. The important extra step is not to substitute directly at an endpoint where the original integrand is undefined.$t$,
$t$For a definite integral, evaluate an antiderivative at the upper limit and subtract its value at the lower limit.

For

∫ from 0 to 4 of x^(-1/2) dx,

use a limit because x^(-1/2) is undefined at 0:

lim as a→0+ (4-2√a)=4.

So the definite integral is 4.$t$,
$t$Think of a definite integral as accumulated signed change.

For an ordinary endpoint, you evaluate the antiderivative directly. If the original function is not defined at an endpoint, approach that endpoint from inside the interval instead.

If the accumulated value settles to a finite limit, the improper integral converges.$t$,
$t$Use upper minus lower. If the original integrand is undefined at an endpoint, replace that endpoint by a variable and take a one-sided limit. Do not confuse a definite integral with geometric area when the function is below the axis; definite integrals keep signs.$t$,
'p1:P1-INT-03:theory:en:v1'
),
(
'p1:P1-INT-03:tutor:ru:v2','P1','P1-INT-03','ru','tutor_v2_learner_first','Определённый интеграл',
$t$Определённый интеграл даёт знаковое накопление между двумя пределами. Найдите первообразную, затем вычислите «верхнее значение минус нижнее».

Рассмотрим простой случай с особой нижней границей:

∫ от 0 до 4 от x^(-1/2) dx.

Функция не определена при x=0, поэтому нижнюю границу нужно понимать через предел.

Первообразная равна 2√x. Тогда

lim при a→0+ [2√x] от a до 4
= lim при a→0+ (4 - 2√a)
= 4.

Интеграл существует, потому что предел конечен. Важный дополнительный шаг — не подставлять напрямую границу, в которой исходная функция не определена.$t$,
$t$В определённом интеграле подставьте верхнюю границу в первообразную и вычтите значение на нижней.

Для

∫ от 0 до 4 от x^(-1/2) dx

нужен предел, потому что функция не определена при 0:

lim при a→0+ (4-2√a)=4.

Значит, интеграл равен 4.$t$,
$t$Определённый интеграл можно понимать как накопленное изменение с учётом знака.

При обычной границе первообразная вычисляется напрямую. Если исходная функция не определена на границе, нужно подходить к ней изнутри промежутка.

Если накопленное значение стремится к конечному пределу, несобственный интеграл сходится.$t$,
$t$Используйте правило «верхний предел минус нижний». Если исходная функция не определена на границе, замените эту границу переменной и возьмите односторонний предел. Не путайте определённый интеграл с геометрической площадью: участок ниже оси даёт отрицательный вклад.$t$,
'p1:P1-INT-03:theory:ru:v1'
),
(
'p1:P1-INT-03:tutor:uz:v2','P1','P1-INT-03','uz','tutor_v2_learner_first','Aniq integral',
$t$Aniq integral ikki chegara orasidagi ishorali yig‘ilishni beradi. Boshlang‘ich funksiyani toping, keyin “yuqori qiymat minus quyi qiymat” ni hisoblang.

Oddiy maxsus chegara misoli:

∫ 0 dan 4 gacha x^(-1/2) dx.

Funksiya x=0 da aniqlanmagan, shuning uchun quyi chegarani limit orqali olish kerak.

Boshlang‘ich funksiya 2√x. Shunda

a→0+ da [2√x] ni a dan 4 gacha
= a→0+ da (4 - 2√a)
= 4.

Limit chekli bo‘lgani uchun integral mavjud. Muhim qadam — boshlang‘ich funksiya emas, aynan integrand aniqlanmagan chegaraga to‘g‘ridan-to‘g‘ri qo‘ymaslik.$t$,
$t$Aniq integralda boshlang‘ich funksiyaning yuqori chegara qiymatidan quyi chegara qiymatini ayiring.

∫ 0 dan 4 gacha x^(-1/2) dx uchun 0 da funksiya aniqlanmagan, shuning uchun limit ishlatiladi:

a→0+ da (4-2√a)=4.

Demak, integral 4.$t$,
$t$Aniq integralni ishorali yig‘ilgan o‘zgarish deb tasavvur qiling.

Oddiy chegarada boshlang‘ich funksiya bevosita hisoblanadi. Agar boshlang‘ich funksiya emas, integrand chegarada aniqlanmagan bo‘lsa, shu chegaraga interval ichidan yaqinlashing.

Yig‘ilgan qiymat chekli songa yaqinlashsa, integral yaqinlashadi.$t$,
$t$“Yuqori minus quyi” qoidasini ishlating. Integrand chegarada aniqlanmagan bo‘lsa, chegarani o‘zgaruvchi bilan almashtirib bir tomonlama limit oling. Aniq integralni geometrik yuza bilan aralashtirmang: o‘q ostidagi qism manfiy hissa beradi.$t$,
'p1:P1-INT-03:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
