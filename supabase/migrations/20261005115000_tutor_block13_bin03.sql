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
  if v<>216 then raise exception 'BIN03 expected 216 prior drafts, found %',v; end if;

  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-BIN-03')<>0
  then raise exception 'BIN03 Tutor Cards already exist'; end if;

  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-BIN-03' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'BIN03 requires 3 approved runtime theory sources'; end if;
end
$pre$;

with seed(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,source_card_key
) as (values
(
'p5:P5-BIN-03:tutor:en:v2','P5','P5-BIN-03','en','tutor_v2_learner_first',
'Binomial mean and variance',
$t$For a binomial random variable with parameters n and p,

E(X)=np

and

Var(X)=np(1-p).

These formulas can be used forward to calculate the mean and variance, or backwards to recover an unknown parameter.

Suppose X is binomial with n=20 and

E(X)=6.

Then

20p=6,

so

p=0.3.

Now the variance is

Var(X)=20(0.3)(0.7)=4.2.

This is an inverse-parameter problem: information about the distribution’s mean gives p first, and then the variance follows. After finding p, always check that 0≤p≤1 before using it as a probability.$t$,
$t$For a binomial model,

E(X)=np,
Var(X)=np(1-p).

If n=20 and E(X)=6:

20p=6,

so p=0.3.

Then

Var(X)=20(0.3)(0.7)=4.2.

Check that the recovered p is between 0 and 1.$t$,
$t$Think of np as “number of trials × average successes per trial”. If the expected number of successes is known, dividing by n recovers the success probability p.

Here an expected 6 successes in 20 trials gives p=6/20=0.3. Once p is known, np(1-p) describes how much the number of successes varies around its mean.$t$,
$t$Keep the mean and variance formulas separate. Solve for p from the simplest given equation first, then substitute into the other formula. Check 0≤p≤1 and remember that variance is not the standard deviation.$t$,
'p5:P5-BIN-03:theory:en:v1'
),
(
'p5:P5-BIN-03:tutor:ru:v2','P5','P5-BIN-03','ru','tutor_v2_learner_first',
'Среднее и дисперсия биномиального распределения',
$t$Для биномиальной случайной величины с параметрами n и p:

E(X)=np

и

Var(X)=np(1-p).

Эти формулы можно применять прямо для нахождения среднего и дисперсии или в обратную сторону для восстановления неизвестного параметра.

Пусть X имеет биномиальную модель с n=20 и

E(X)=6.

Тогда

20p=6,

поэтому

p=0.3.

Теперь

Var(X)=20(0.3)(0.7)=4.2.

Это задача на восстановление параметра: сначала из среднего находится p, затем вычисляется дисперсия. После нахождения p обязательно проверьте, что 0≤p≤1, прежде чем использовать его как вероятность.$t$,
$t$Для биномиальной модели:

E(X)=np,
Var(X)=np(1-p).

Если n=20 и E(X)=6:

20p=6,

значит p=0.3.

Тогда

Var(X)=20(0.3)(0.7)=4.2.

Проверьте, что найденное p находится между 0 и 1.$t$,
$t$Формулу np можно понимать как «число испытаний × среднее число успехов на одно испытание». Если ожидаемое число успехов известно, деление на n восстанавливает p.

Здесь 6 ожидаемых успехов из 20 дают p=6/20=0.3. После этого np(1-p) показывает разброс числа успехов вокруг среднего.$t$,
$t$Не смешивайте формулы среднего и дисперсии. Сначала найдите p из самого простого данного уравнения, затем подставьте его в другую формулу. Проверьте 0≤p≤1 и помните: дисперсия и стандартное отклонение — разные величины.$t$,
'p5:P5-BIN-03:theory:ru:v1'
),
(
'p5:P5-BIN-03:tutor:uz:v2','P5','P5-BIN-03','uz','tutor_v2_learner_first',
'Binomial o‘rtacha va dispersiya',
$t$n va p parametrli binomial tasodifiy miqdor uchun

E(X)=np

va

Var(X)=np(1-p).

Bu formulalarni o‘rtacha va dispersiyani hisoblash uchun ham, noma’lum parametrni teskari yo‘l bilan topish uchun ham ishlatish mumkin.

X uchun n=20 va

E(X)=6

bo‘lsin.

Unda

20p=6,

demak

p=0.3.

Endi

Var(X)=20(0.3)(0.7)=4.2.

Bu parametrni tiklash masalasi: avval o‘rtachadan p topiladi, keyin dispersiya hisoblanadi. p ni topgach, uni ehtimollik sifatida ishlatishdan oldin 0≤p≤1 ekanini tekshiring.$t$,
$t$Binomial model uchun:

E(X)=np,
Var(X)=np(1-p).

n=20 va E(X)=6 bo‘lsa:

20p=6,

demak p=0.3.

So‘ng

Var(X)=20(0.3)(0.7)=4.2.

Topilgan p 0 va 1 orasida ekanini tekshiring.$t$,
$t$np ni “sinovlar soni × bitta sinovdagi o‘rtacha muvaffaqiyat” deb o‘ylang. Kutilayotgan muvaffaqiyatlar soni ma’lum bo‘lsa, uni n ga bo‘lib p ni topish mumkin.

Bu yerda 20 sinovda 6 ta kutilayotgan muvaffaqiyat p=6/20=0.3 ni beradi. Keyin np(1-p) muvaffaqiyatlar sonining o‘rtacha atrofidagi tarqalishini beradi.$t$,
$t$O‘rtacha va dispersiya formulalarini aralashtirmang. Avval eng sodda berilgan tenglamadan p ni toping, keyin ikkinchi formulaga qo‘ying. 0≤p≤1 ni tekshiring va dispersiya standart og‘ish emasligini unutmang.$t$,
'p5:P5-BIN-03:theory:uz:v1'
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
