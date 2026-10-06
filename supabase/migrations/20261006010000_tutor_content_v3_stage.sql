-- Tutor content v3 repair staging.
-- Preserves the approved/runtime v2 corpus untouched while a full v3 + atomic source v2
-- replacement is built and validated as DRAFT/runtime-OFF.
-- No learner state, evidence, entitlement, cohort, Practice/Tour, certificate or localStorage data is touched.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$
declare
  v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='approved'
    and is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 stage expected 243 active v2 cards, found %',v; end if;

  select count(distinct skill_code) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='approved'
    and is_runtime_allowed;
  if v<>81 then raise exception 'Tutor v3 stage expected 81 active v2 skills, found %',v; end if;

  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v2_learner_first'
      and (
        s.source_card_key is null
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.approval_status<>'approved'
        or not s.is_runtime_allowed
      )
  ) then
    raise exception 'Tutor v3 stage refuses source-binding drift in active v2';
  end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
  ) then
    raise exception 'Tutor v3 stage rows already exist';
  end if;

  if exists(
    select 1 from private.exam_prep_ai_source_cards
    where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
       or source_card_key ~ '^p[15]:P[15]-[A-Z]{3}-[0-9]{2}:theory:(en|ru|uz):v2$'
  ) then
    raise exception 'Atomic source v2 rows already exist';
  end if;
end
$pre$;

-- 1) Stage one new atomic source-card row for every active v2 Tutor row.
insert into private.exam_prep_ai_source_cards(
  source_card_key,component_code,skill_code,card_type,locale,source_version,
  title,body_text,approval_status,rights_status,is_runtime_allowed,content_hash,
  approved_at,approved_by,created_at,updated_at
)
select
  regexp_replace(t.source_card_key,':v1$',':v2'),
  t.component_code,
  t.skill_code,
  'theory',
  t.locale,
  'p3_02_full_theory_pack_v2_atomic_2026_10_06',
  t.title,
  case t.locale
    when 'ru' then 'Фокус темы: '||t.title||E'.\n\nОсновное объяснение:\n'||t.main_explanation||E'\n\nКритическая проверка:\n'||t.focus_explanation
    when 'uz' then 'Mavzu fokusi: '||t.title||E'.\n\nAsosiy tushuntirish:\n'||t.main_explanation||E'\n\nMuhim tekshiruv:\n'||t.focus_explanation
    else 'Topic focus: '||t.title||E'.\n\nCore explanation:\n'||t.main_explanation||E'\n\nCritical check:\n'||t.focus_explanation
  end,
  'draft',
  'original_iclub',
  false,
  encode(digest(convert_to(
    case t.locale
      when 'ru' then 'Фокус темы: '||t.title||E'.\n\nОсновное объяснение:\n'||t.main_explanation||E'\n\nКритическая проверка:\n'||t.focus_explanation
      when 'uz' then 'Mavzu fokusi: '||t.title||E'.\n\nAsosiy tushuntirish:\n'||t.main_explanation||E'\n\nMuhim tekshiruv:\n'||t.focus_explanation
      else 'Topic focus: '||t.title||E'.\n\nCore explanation:\n'||t.main_explanation||E'\n\nCritical check:\n'||t.focus_explanation
    end,
    'UTF8'
  ),'sha256'),'hex'),
  null,null,now(),now()
from private.exam_prep_ai_tutor_cards t
where t.content_version='tutor_v2_learner_first'
  and t.approval_status='approved'
  and t.is_runtime_allowed;

-- 2) Clone learner-facing content into a complete v3 DRAFT corpus, bound to source v2.
insert into private.exam_prep_ai_tutor_cards(
  tutor_card_key,component_code,skill_code,locale,content_version,title,
  main_explanation,simple_explanation,alternative_explanation,focus_explanation,
  source_card_key,approval_status,is_runtime_allowed,content_hash,
  approved_at,approved_by,created_at,updated_at
)
select
  regexp_replace(t.tutor_card_key,':v2$',':v3'),
  t.component_code,t.skill_code,t.locale,'tutor_v3_learner_first',t.title,
  t.main_explanation,t.simple_explanation,t.alternative_explanation,t.focus_explanation,
  regexp_replace(t.source_card_key,':v1$',':v2'),
  'draft',false,
  md5(concat_ws('||',
    'tutor_v3_learner_first',t.title,t.main_explanation,t.simple_explanation,
    t.alternative_explanation,t.focus_explanation,
    regexp_replace(t.source_card_key,':v1$',':v2')
  )),
  null,null,now(),now()
from private.exam_prep_ai_tutor_cards t
where t.content_version='tutor_v2_learner_first'
  and t.approval_status='approved'
  and t.is_runtime_allowed;

-- F-002: restore the missing triangle-area method in RU P1-CIR-03 main.
update private.exam_prep_ai_tutor_cards
set main_explanation=replace(
      main_explanation,
      'Его площадь равна 16√3.',
      'Его площадь: 1/2 r² sinθ = 16√3.'
    ),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P1-CIR-03' and locale='ru';

-- F-003: replace the textbook-matching P1-QUA-06 worked example with an iClub-original example.
update private.exam_prep_ai_tutor_cards
set main_explanation=$en$
Some equations are not written as quadratics in x, but they become quadratic after a useful substitution. Look for the same expression appearing as a first power and a square.

For example,

x⁴ - 13x² + 36 = 0.

Because x⁴ = (x²)², let

u = x².

The equation becomes

u² - 13u + 36 = 0
(u - 4)(u - 9) = 0,

so u = 4 or u = 9.

Now return to the original variable:

x² = 4 gives x = ±2,
x² = 9 gives x = ±3.

Therefore x = -3, -2, 2 or 3. The substitution only simplifies the structure; the final answer must always be converted back to the original variable.$en$,
    simple_explanation=$en$
If an equation contains something and its square, replace that repeated expression with a new variable.

For

x⁴ - 13x² + 36 = 0,

let u = x². Then

u² - 13u + 36 = 0,

so u = 4 or 9. Finally return to x:

x² = 4 gives x = ±2,
x² = 9 gives x = ±3.

So x = -3, -2, 2 or 3.$en$,
    alternative_explanation=$en$
Think of substitution as temporarily hiding a repeated expression behind a simpler name.

In x⁴ - 13x² + 36 = 0, the repeated building block is x². Calling it u reveals an ordinary quadratic:

u² - 13u + 36 = 0
(u - 4)(u - 9) = 0.

Once that easier equation is solved, remove the temporary label u and translate every solution back into x. Here u=4 or 9 gives x=±2 or ±3. The algebra is simpler, but the original variable still controls the final answer.$en$,
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P1-QUA-06' and locale='en';

update private.exam_prep_ai_tutor_cards
set main_explanation=$ru$
Некоторые уравнения не выглядят квадратными относительно x, но становятся квадратными после подходящей замены. Ищите одно и то же выражение в первой и второй степени.

Например,

x⁴ - 13x² + 36 = 0.

Так как x⁴ = (x²)², положим

u = x².

Тогда получаем

u² - 13u + 36 = 0
(u - 4)(u - 9) = 0,

поэтому u = 4 или u = 9.

Теперь возвращаемся к исходной переменной:

x² = 4 даёт x = ±2,
x² = 9 даёт x = ±3.

Итак, x = -3, -2, 2 или 3. Замена только упрощает структуру уравнения; окончательный ответ всегда нужно вернуть к исходной переменной.$ru$,
    simple_explanation=$ru$
Если в уравнении встречаются некоторое выражение и его квадрат, временно замените это выражение новой переменной.

Для

x⁴ - 13x² + 36 = 0

положим u = x². Тогда получаем

u² - 13u + 36 = 0,

откуда u = 4 или 9. Возвращаемся к x:

x² = 4 даёт x = ±2,
x² = 9 даёт x = ±3.

Ответ: x = -3, -2, 2, 3.$ru$,
    alternative_explanation=$ru$
Представьте замену как временное короткое имя для повторяющегося выражения.

В x⁴ - 13x² + 36 = 0 таким блоком является x². Если назвать его u, появляется обычное квадратное уравнение:

u² - 13u + 36 = 0
(u - 4)(u - 9) = 0.

После его решения временное обозначение нужно убрать и перевести каждый найденный u обратно в x. Здесь u=4 или 9 даёт x=±2 или ±3. Замена упрощает алгебру, но окончательный ответ остаётся в исходной переменной.$ru$,
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P1-QUA-06' and locale='ru';

update private.exam_prep_ai_tutor_cards
set main_explanation=$uz$
Ba’zi tenglamalar x ga nisbatan kvadrat ko‘rinishda yozilmagan bo‘ladi, lekin mos almashtirishdan keyin kvadrat tenglamaga aylanadi. Bir xil ifoda birinchi va ikkinchi darajada takrorlanayotganini qidiring.

Masalan,

x⁴ - 13x² + 36 = 0.

x⁴ = (x²)² bo‘lgani uchun

u = x²

deb olamiz. Shunda

u² - 13u + 36 = 0
(u - 4)(u - 9) = 0,

ya’ni u = 4 yoki u = 9.

Endi boshlang‘ich o‘zgaruvchiga qaytamiz:

x² = 4 dan x = ±2,
x² = 9 dan x = ±3.

Demak, x = -3, -2, 2 yoki 3. Almashtirish faqat tenglama tuzilishini soddalashtiradi; yakuniy javob albatta boshlang‘ich o‘zgaruvchiga qaytarilishi kerak.$uz$,
    simple_explanation=$uz$
Agar tenglamada biror ifoda va uning kvadrati takrorlansa, shu ifodani vaqtincha yangi o‘zgaruvchi bilan almashtiring.

x⁴ - 13x² + 36 = 0

uchun u = x² deb olamiz. Shunda

u² - 13u + 36 = 0,

demak u = 4 yoki 9. Endi x ga qaytamiz:

x² = 4 dan x = ±2,
x² = 9 dan x = ±3.

Javob: x = -3, -2, 2, 3.$uz$,
    alternative_explanation=$uz$
Almashtirishni takroriy ifodaga vaqtinchalik qisqa nom berish deb o‘ylang.

x⁴ - 13x² + 36 = 0 da takroriy blok x². Uni u deb atasak, oddiy kvadrat tenglama paydo bo‘ladi:

u² - 13u + 36 = 0
(u - 4)(u - 9) = 0.

Uni yechgach, vaqtinchalik u belgisini olib tashlab, har bir yechimni x ga qaytaramiz. Bu yerda u=4 yoki 9 dan x=±2 yoki ±3 chiqadi. Algebra soddalashadi, lekin yakuniy javob boshlang‘ich o‘zgaruvchida bo‘ladi.$uz$,
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P1-QUA-06' and locale='uz';

-- F-004: replace textbook-matching P5-BIN-02 numbers with an original worked example.
update private.exam_prep_ai_tutor_cards
set main_explanation=$en$
For a binomial random variable,

P(X=r)=nCr p^r(1-p)^(n-r).

The first job is to translate the wording into the correct values of X.

Suppose X is binomial with n=6 and p=0.3.

For exactly 2 successes:

P(X=2)
=6C2(0.3)²(0.7)⁴
=0.324135.

For at most 1 success:

P(X≤1)
=P(X=0)+P(X=1)
=0.420175.

A cumulative probability combines several integer outcomes, not just one. For “at least” or “more than” questions, a complement can often be shorter than adding many terms. The important step is to identify the required integer values before pressing the calculator.$en$,
    simple_explanation=$en$
If X is binomial,

P(X=r)=nCr p^r(1-p)^(n-r).

For n=6, p=0.3:

P(X=2)=0.324135.

For at most 1 success:

P(X≤1)=P(X=0)+P(X=1)=0.420175.

Translate the wording into the correct X-values before calculating.$en$,
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-BIN-02' and locale='en';

update private.exam_prep_ai_tutor_cards
set main_explanation=$ru$
Для биномиальной случайной величины

P(X=r)=nCr p^r(1-p)^(n-r).

Первый шаг — правильно перевести условие задачи в нужные значения X.

Пусть X имеет биномиальную модель с n=6 и p=0.3.

Для ровно 2 успехов:

P(X=2)
=6C2(0.3)²(0.7)⁴
=0.324135.

Для не более 1 успеха:

P(X≤1)
=P(X=0)+P(X=1)
=0.420175.

Накопленная вероятность объединяет несколько целых значений X, а не только одно. Для условий «не менее» или «больше» часто удобнее использовать дополнение, чем складывать много отдельных вероятностей. Сначала определите нужные значения X, затем считайте.$ru$,
    simple_explanation=$ru$
Если X имеет биномиальную модель,

P(X=r)=nCr p^r(1-p)^(n-r).

При n=6, p=0.3:

P(X=2)=0.324135.

Для не более 1 успеха:

P(X≤1)=P(X=0)+P(X=1)=0.420175.

Сначала переведите слова задачи в правильные значения X.$ru$,
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-BIN-02' and locale='ru';

update private.exam_prep_ai_tutor_cards
set main_explanation=$uz$
Binomial tasodifiy miqdor uchun

P(X=r)=nCr p^r(1-p)^(n-r).

Birinchi qadam — savol matnini X ning to‘g‘ri qiymatlariga aylantirish.

X uchun n=6 va p=0.3 bo‘lgan binomial model berilsin.

Aynan 2 muvaffaqiyat uchun:

P(X=2)
=6C2(0.3)²(0.7)⁴
=0.324135.

Ko‘pi bilan 1 muvaffaqiyat uchun:

P(X≤1)
=P(X=0)+P(X=1)
=0.420175.

Yig‘ma ehtimollik bitta emas, bir nechta butun X qiymatlarini birlashtiradi. “Kamida” yoki “ko‘proq” shartlarida ko‘p hadni qo‘shish o‘rniga to‘ldiruvchi hodisa qisqaroq bo‘lishi mumkin. Avval kerakli X qiymatlarini aniqlang, keyin hisoblang.$uz$,
    simple_explanation=$uz$
X binomial bo‘lsa,

P(X=r)=nCr p^r(1-p)^(n-r).

n=6, p=0.3 uchun:

P(X=2)=0.324135.

Ko‘pi bilan 1 muvaffaqiyat:

P(X≤1)=P(X=0)+P(X=1)=0.420175.

Hisoblashdan oldin savol so‘zlarini to‘g‘ri X qiymatlariga aylantiring.$uz$,
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-BIN-02' and locale='uz';

-- F-005: remove raw English "Sine" from RU/UZ P1-TRI-05.
update private.exam_prep_ai_tutor_cards
set main_explanation=replace(main_explanation,'Sine положителен','sin x положителен'),
    simple_explanation=replace(simple_explanation,'Sine положителен','sin x положителен'),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P1-TRI-05' and locale='ru';

update private.exam_prep_ai_tutor_cards
set main_explanation=replace(main_explanation,'Sine I va II choraklarda musbat','sin x I va II choraklarda musbat'),
    simple_explanation=replace(simple_explanation,'Sine I va II choraklarda musbat','sin x I va II choraklarda musbat'),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P1-TRI-05' and locale='uz';

-- F-006/F-007: normalize "Box plot" terminology in RU learner cards.
update private.exam_prep_ai_tutor_cards
set main_explanation=replace(main_explanation,'Box plot компактно','Диаграмма размаха компактно'),
    simple_explanation=replace(simple_explanation,'Box plot удобен','Диаграмма размаха удобна'),
    alternative_explanation=replace(alternative_explanation,'box plot','диаграмма размаха'),
    focus_explanation=replace(focus_explanation,'Box plot','Диаграмма размаха'),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-DAT-01' and locale='ru';

update private.exam_prep_ai_tutor_cards
set main_explanation=replace(main_explanation,'Box plot кратко','Диаграмма размаха кратко'),
    simple_explanation=replace(simple_explanation,'Box plot использует','Диаграмма размаха использует'),
    alternative_explanation=replace(alternative_explanation,'Представьте box plot как','Представьте диаграмму размаха как'),
    focus_explanation=replace(focus_explanation,'двух box plots','двух диаграмм размаха'),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-DAT-03' and locale='ru';

-- F-008/F-009: remove unnecessary English code-switching from UZ data cards.
update private.exam_prep_ai_tutor_cards
set main_explanation=replace(
      replace(main_explanation,'outlier qoidasi','chet qiymatlarni aniqlash qoidasi'),
      'outlierlar alohida','chet qiymatlar alohida'
    ),
    focus_explanation=replace(focus_explanation,'umumiy range','umumiy qiymatlar oralig‘i'),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-DAT-03' and locale='uz';

update private.exam_prep_ai_tutor_cards
set main_explanation=replace(replace(main_explanation,'Range','qiymatlar oralig‘i'),'range','qiymatlar oralig‘i'),
    simple_explanation=replace(replace(simple_explanation,'Range','qiymatlar oralig‘i'),'range','qiymatlar oralig‘i'),
    alternative_explanation=replace(replace(alternative_explanation,'Range','qiymatlar oralig‘i'),'range','qiymatlar oralig‘i'),
    focus_explanation=replace(replace(focus_explanation,'Range','qiymatlar oralig‘i'),'range','qiymatlar oralig‘i'),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-DAT-07' and locale='uz';

-- F-010: remove raw "convention" in RU/UZ P5-DAT-09.
update private.exam_prep_ai_tutor_cards
set main_explanation=replace(
      main_explanation,
      'последовательно использовать одну convention стандартного отклонения',
      'последовательно использовать выбранную формулу стандартного отклонения'
    ),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-DAT-09' and locale='ru';

update private.exam_prep_ai_tutor_cards
set main_explanation=replace(
      main_explanation,
      'standart og‘ish conventionini izchil saqlash',
      'tanlangan standart og‘ish formulasini izchil qo‘llash'
    ),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-DAT-09' and locale='uz';

-- F-011: localize inverse-normal wording in RU/UZ focus.
update private.exam_prep_ai_tutor_cards
set focus_explanation=replace(
      focus_explanation,
      'До применения inverse normal определите',
      'До использования функции обратного нормального распределения определите'
    ),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-NOR-04' and locale='ru';

update private.exam_prep_ai_tutor_cards
set focus_explanation=replace(
      focus_explanation,
      'Inverse normal ishlatishdan oldin',
      'Teskari normal usulni ishlatishdan oldin'
    ),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-NOR-04' and locale='uz';

-- F-012: UZ grammar repair.
update private.exam_prep_ai_tutor_cards
set alternative_explanation=replace(
      alternative_explanation,
      'p va kutish vaqtini qarama-qarshi yo‘nalishda o‘zgaradi deb o‘ylang.',
      'p va kutish vaqti qarama-qarshi yo‘nalishda o‘zgaradi deb o‘ylang.'
    ),
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-GEO-03' and locale='uz';

-- F-001 BLOCKER: state the Cambridge normal-approximation conditions explicitly in all variants/locales.
update private.exam_prep_ai_tutor_cards
set main_explanation=$en$
A binomial distribution can sometimes be approximated by a normal distribution, but first the approximation conditions must be checked.

For

X ~ B(n,p),

let q=1-p. Use the normal approximation only when both

np>5

and

nq>5.

Then use the normal model with

mean = np

and

variance = npq = np(1-p).

Suppose

X ~ B(100,0.4).

Here q=0.6, so np=40 and nq=60; both conditions are satisfied. The approximating normal variable Y has

mean = 40,
variance = 24.

To approximate

P(X≤45),

translate the discrete boundary using continuity correction:

P(X≤45) ≈ P(Y<45.5).

Now standardise:

z=(45.5-40)/√24≈1.123.

Therefore

P(X≤45)≈0.8692.

The continuity correction is applied before standardisation because it translates an integer boundary from a discrete distribution to a continuous one.$en$,
    simple_explanation=$en$
For X~B(n,p), let q=1-p.

Use a normal approximation only when

np>5 and nq>5.

Then use

mean=np,
variance=npq=np(1-p).

For X~B(100,0.4), q=0.6, so np=40 and nq=60. The conditions are satisfied.

For P(X≤45), continuity correction gives

P(Y<45.5).

Then z≈1.123, so

P(X≤45)≈0.8692.$en$,
    alternative_explanation=$en$
First check np>5 and nq>5. Only then replace the binomial bars by a continuous normal curve.

Think of each binomial value as a bar centred on an integer. The event X≤45 includes the whole bar centred at 45, so the matching continuous boundary is halfway to the next integer: 45.5.

That half-unit shift is the continuity correction. After the shift, standardise using mean np and variance np(1-p).$en$,
    focus_explanation=$en$
Let q=1-p and check both np>5 and nq>5 before using the normal approximation. Then use μ=np and σ²=npq=np(1-p), not σ=np(1-p). Apply the continuity correction to the discrete boundary before calculating z; the direction of the half-unit shift depends on the event.$en$,
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-NOR-06' and locale='en';

update private.exam_prep_ai_tutor_cards
set main_explanation=$ru$
Биномиальное распределение иногда можно приближать нормальным, но сначала нужно проверить условия применимости.

Для

X ~ B(n,p)

положите q=1-p. Нормальное приближение используйте только если одновременно

np>5

и

nq>5.

Затем используйте нормальную модель со

средним = np

и

дисперсией = npq = np(1-p).

Пусть

X ~ B(100,0.4).

Здесь q=0.6, поэтому np=40 и nq=60; оба условия выполнены. Тогда приближающая нормальная величина Y имеет

среднее = 40,
дисперсию = 24.

Чтобы приблизить

P(X≤45),

сначала применяем поправку на непрерывность:

P(X≤45) ≈ P(Y<45.5).

Затем стандартизируем:

z=(45.5-40)/√24≈1.123.

Поэтому

P(X≤45)≈0.8692.

Поправка на непрерывность применяется до стандартизации, потому что она переводит дискретную целочисленную границу в непрерывную шкалу.$ru$,
    simple_explanation=$ru$
Для X~B(n,p) положите q=1-p.

Нормальное приближение используйте только если

np>5 и nq>5.

Затем используйте

среднее=np,
дисперсия=npq=np(1-p).

Для X~B(100,0.4) имеем q=0.6, np=40 и nq=60. Оба условия выполнены.

Для P(X≤45) поправка на непрерывность даёт

P(Y<45.5).

Тогда z≈1.123 и

P(X≤45)≈0.8692.$ru$,
    alternative_explanation=$ru$
Сначала проверьте np>5 и nq>5. Только после этого заменяйте биномиальные столбики непрерывной нормальной кривой.

Представьте биномиальные значения как столбики с центрами в целых числах. Событие X≤45 включает весь столбик с центром 45, поэтому соответствующая непрерывная граница проходит посередине до следующего целого числа — в 45.5.

Этот сдвиг на половину единицы и есть поправка на непрерывность. После сдвига стандартизируйте, используя среднее np и дисперсию np(1-p).$ru$,
    focus_explanation=$ru$
Положите q=1-p и перед нормальным приближением проверьте оба условия: np>5 и nq>5. Затем используйте μ=np и σ²=npq=np(1-p), не путайте дисперсию со стандартным отклонением. Поправку на непрерывность применяйте к дискретной границе до вычисления z; направление сдвига зависит от события.$ru$,
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-NOR-06' and locale='ru';

update private.exam_prep_ai_tutor_cards
set main_explanation=$uz$
Binomial taqsimotni ayrim hollarda normal taqsimot bilan yaqinlashtirish mumkin, lekin avval qo‘llash shartlarini tekshirish kerak.

X ~ B(n,p)

uchun q=1-p deb oling. Normal yaqinlashuvni faqat

np>5

va

nq>5

shartlarining ikkalasi ham bajarilganda qo‘llang.

Keyin normal modelda

o‘rtacha = np

va

dispersiya = npq = np(1-p)

dan foydalaning.

Masalan,

X ~ B(100,0.4).

Bu yerda q=0.6, shuning uchun np=40 va nq=60; ikkala shart ham bajarilgan. Yaqinlashtiruvchi normal Y uchun

o‘rtacha = 40,
dispersiya = 24.

P(X≤45) ni yaqinlashtirish uchun avval uzluksizlik tuzatishini qo‘llaymiz:

P(X≤45) ≈ P(Y<45.5).

Keyin standartlashtiramiz:

z=(45.5-40)/√24≈1.123.

Demak,

P(X≤45)≈0.8692.

Uzluksizlik tuzatishi standartlashtirishdan oldin qo‘llanadi, chunki u diskret butun sonli chegarani uzluksiz shkalaga o‘tkazadi.$uz$,
    simple_explanation=$uz$
X~B(n,p) uchun q=1-p deb oling.

Normal yaqinlashuvni faqat

np>5 va nq>5

bo‘lganda qo‘llang.

Keyin

o‘rtacha=np,
dispersiya=npq=np(1-p).

X~B(100,0.4) uchun q=0.6, np=40 va nq=60. Ikkala shart ham bajarilgan.

P(X≤45) uchun uzluksizlik tuzatishi:

P(Y<45.5).

Shundan z≈1.123 va

P(X≤45)≈0.8692.$uz$,
    alternative_explanation=$uz$
Avval np>5 va nq>5 shartlarini tekshiring. Faqat shundan keyin binomial ustunlarni uzluksiz normal egri chiziq bilan almashtiring.

Binomial qiymatlarni butun sonlar markazidagi ustunlar deb tasavvur qiling. X≤45 hodisasi 45 markazli ustunning hammasini o‘z ichiga oladi, shuning uchun uzluksiz chegara keyingi butun songacha bo‘lgan o‘rtada — 45.5 da olinadi.

Shu yarim birlik siljish uzluksizlik tuzatishidir. Siljishdan keyin o‘rtacha np va dispersiya np(1-p) bilan standartlashtiring.$uz$,
    focus_explanation=$uz$
q=1-p deb oling va normal yaqinlashuvdan oldin np>5 hamda nq>5 shartlarining ikkalasini ham tekshiring. Keyin μ=np va σ²=npq=np(1-p) dan foydalaning; dispersiyani standart og‘ish bilan aralashtirmang. Uzluksizlik tuzatishini z ni hisoblashdan oldin diskret chegaraga qo‘llang; yarim birlik siljish yo‘nalishi hodisaga bog‘liq.$uz$,
    updated_at=now()
where content_version='tutor_v3_learner_first'
  and skill_code='P5-NOR-06' and locale='uz';

-- Recompute every v3 Tutor hash after the audited repairs.
update private.exam_prep_ai_tutor_cards
set content_hash=md5(concat_ws('||',
      content_version,title,main_explanation,simple_explanation,
      alternative_explanation,focus_explanation,source_card_key
    )),
    updated_at=now()
where content_version='tutor_v3_learner_first';

-- F-013/F-014: rebuild all 243 source v2 bodies from the final corrected atomic
-- Tutor explanation + skill-specific critical check. This removes the family-generic
-- template and the inherited RU P5-DAT "box plot" wording.
with built as (
  select
    s.source_card_key,
    case t.locale
      when 'ru' then 'Фокус темы: '||t.title||E'.\n\nОсновное объяснение:\n'||t.main_explanation||E'\n\nКритическая проверка:\n'||t.focus_explanation
      when 'uz' then 'Mavzu fokusi: '||t.title||E'.\n\nAsosiy tushuntirish:\n'||t.main_explanation||E'\n\nMuhim tekshiruv:\n'||t.focus_explanation
      else 'Topic focus: '||t.title||E'.\n\nCore explanation:\n'||t.main_explanation||E'\n\nCritical check:\n'||t.focus_explanation
    end as body
  from private.exam_prep_ai_source_cards s
  join private.exam_prep_ai_tutor_cards t on t.source_card_key=s.source_card_key
  where s.source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
    and t.content_version='tutor_v3_learner_first'
)
update private.exam_prep_ai_source_cards s
set body_text=b.body,
    content_hash=encode(digest(convert_to(b.body,'UTF8'),'sha256'),'hex'),
    updated_at=now()
from built b
where s.source_card_key=b.source_card_key;

do $post$
declare
  v integer;
begin
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v3_learner_first'
    and approval_status='draft' and not is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 stage expected 243 draft/off cards, found %',v; end if;

  select count(*) into v
  from private.exam_prep_ai_source_cards
  where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
    and approval_status='draft' and not is_runtime_allowed
    and rights_status='original_iclub';
  if v<>243 then raise exception 'Tutor v3 stage expected 243 draft/off atomic sources, found %',v; end if;

  -- Exactly the 21 audited locale cards may change learner-facing text.
  select count(*) into v
  from private.exam_prep_ai_tutor_cards n
  join private.exam_prep_ai_tutor_cards o
    on o.skill_code=n.skill_code and o.locale=n.locale
   and o.content_version='tutor_v2_learner_first'
  where n.content_version='tutor_v3_learner_first'
    and (n.title,n.main_explanation,n.simple_explanation,n.alternative_explanation,n.focus_explanation)
        is distinct from
        (o.title,o.main_explanation,o.simple_explanation,o.alternative_explanation,o.focus_explanation);
  if v<>21 then raise exception 'Tutor v3 stage expected exactly 21 changed locale cards, found %',v; end if;

  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and content_hash<>md5(concat_ws('||',
        content_version,title,main_explanation,simple_explanation,
        alternative_explanation,focus_explanation,source_card_key
      ))
  ) then raise exception 'Tutor v3 stage found stale Tutor hashes'; end if;

  if exists(
    select 1
    from private.exam_prep_ai_source_cards
    where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06'
      and content_hash<>encode(digest(convert_to(body_text,'UTF8'),'sha256'),'hex')
  ) then raise exception 'Tutor v3 stage found stale source hashes'; end if;

  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards t
    left join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v3_learner_first'
      and (
        s.source_card_key is null
        or s.component_code<>t.component_code
        or s.skill_code<>t.skill_code
        or s.locale<>t.locale
        or s.card_type<>'theory'
        or s.source_version<>'p3_02_full_theory_pack_v2_atomic_2026_10_06'
      )
  ) then raise exception 'Tutor v3 stage source binding mismatch'; end if;

  select count(distinct body_text) into v
  from private.exam_prep_ai_source_cards
  where source_version='p3_02_full_theory_pack_v2_atomic_2026_10_06';
  if v<>243 then raise exception 'Tutor v3 stage expected 243 distinct atomic source bodies, found %',v; end if;

  -- BLOCKER proof: all four Tutor variants and the source card must carry both thresholds.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards t
    join private.exam_prep_ai_source_cards s on s.source_card_key=t.source_card_key
    where t.content_version='tutor_v3_learner_first'
      and t.skill_code='P5-NOR-06'
      and not (
        t.main_explanation like '%np>5%' and t.main_explanation like '%nq>5%'
        and t.simple_explanation like '%np>5%' and t.simple_explanation like '%nq>5%'
        and t.alternative_explanation like '%np>5%' and t.alternative_explanation like '%nq>5%'
        and t.focus_explanation like '%np>5%' and t.focus_explanation like '%nq>5%'
        and s.body_text like '%np>5%' and s.body_text like '%nq>5%'
      )
  ) then raise exception 'Tutor v3 stage P5-NOR-06 thresholds incomplete'; end if;

  -- Copyright/originality regression guards.
  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and skill_code='P1-QUA-06'
      and concat_ws(' ',main_explanation,simple_explanation,alternative_explanation)
          like '%x⁴ - 5x² + 4%'
  ) then raise exception 'Tutor v3 stage retained old P1-QUA-06 worked example'; end if;

  if exists(
    select 1 from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and skill_code='P5-BIN-02'
      and concat_ws(' ',main_explanation,simple_explanation) like '%n=5%'
      and concat_ws(' ',main_explanation,simple_explanation) like '%p=0.4%'
  ) then raise exception 'Tutor v3 stage retained old P5-BIN-02 worked example'; end if;

  -- Targeted language regression guards.
  if exists(
    select 1
    from private.exam_prep_ai_tutor_cards
    where content_version='tutor_v3_learner_first'
      and (
        (locale='ru' and lower(concat_ws(' ',main_explanation,simple_explanation,alternative_explanation,focus_explanation))
          ~ '(sine|box plot|inverse normal|convention)')
        or
        (locale='uz' and lower(concat_ws(' ',main_explanation,simple_explanation,alternative_explanation,focus_explanation))
          ~ '(sine|outlier|range|inverse normal|convention)')
      )
  ) then raise exception 'Tutor v3 stage retained audited mixed-language defect'; end if;

  -- Staging must not change current runtime service coverage.
  select count(*) into v
  from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first'
    and approval_status='approved' and is_runtime_allowed;
  if v<>243 then raise exception 'Tutor v3 stage mutated active v2 corpus'; end if;
end
$post$;

commit;
