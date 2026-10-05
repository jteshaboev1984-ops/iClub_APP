begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>165 then raise exception 'DAT10 expected 165 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DAT-10' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DAT10 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-DAT-10:tutor:en:v2','P5','P5-DAT-10','en','tutor_v2_learner_first','Coded and combined data',
$t$Coded and combined data problems let you work with summaries instead of rebuilding every raw value.

For combined data, convert each group mean back to a total.

Group A: n=20, mean=50, so total = 20×50 = 1000.

Group B: n=30, mean=60, so total = 30×60 = 1800.

The combined mean is

(1000+1800)/(20+30) = 2800/50 = 56.

Coding works by reversing the transformation. If

y=(x-50)/10,

then

x=10y+50.

So if the coded mean is ȳ=1.2, the original mean is

x̄=10(1.2)+50=62.

The main idea is to transform totals and summary measures systematically rather than trying to reconstruct the whole data set.$t$,
$t$For combined means, first recover totals.

A: 20 values, mean 50 → total 1000.

B: 30 values, mean 60 → total 1800.

Combined mean = 2800/50 = 56.

For coding y=(x-50)/10, reverse it with x=10y+50. If ȳ=1.2, then x̄=62.$t$,
$t$Think of a mean as “total divided by number of values”.

When two groups are combined, their means cannot simply be averaged unless the group sizes are equal. Convert each mean into its total first, add the totals, then divide by the new total number of observations.

Coding is similar: the coded summary lives on a transformed scale, so undo the scale and shift to return to the original units.$t$,
$t$Do not average two group means without checking group sizes. Use total = n×mean before combining. For coded data, write the inverse transformation explicitly and apply scale and shift in the correct order. Keep original and coded units separate.$t$,
'p5:P5-DAT-10:theory:en:v1'
),
(
'p5:P5-DAT-10:tutor:ru:v2','P5','P5-DAT-10','ru','tutor_v2_learner_first','Кодированные и объединённые данные',
$t$Задачи с кодированными и объединёнными данными позволяют работать со сводными величинами, не восстанавливая все исходные значения.

Для объединения сначала восстановите сумму каждой группы.

Группа A: n=20, среднее 50, поэтому сумма = 20×50 = 1000.

Группа B: n=30, среднее 60, поэтому сумма = 30×60 = 1800.

Общее среднее:

(1000+1800)/(20+30) = 2800/50 = 56.

При кодировании нужно обратить преобразование. Если

y=(x-50)/10,

то

x=10y+50.

Если среднее кодированных данных ȳ=1.2, то исходное среднее:

x̄=10(1.2)+50=62.

Главная идея — последовательно преобразовывать суммы и сводные характеристики, а не пытаться заново строить весь набор.$t$,
$t$При объединении сначала восстановите суммы.

A: 20 значений, среднее 50 → сумма 1000.

B: 30 значений, среднее 60 → сумма 1800.

Общее среднее = 2800/50 = 56.

Для y=(x-50)/10 обратное преобразование: x=10y+50. Если ȳ=1.2, то x̄=62.$t$,
$t$Смотрите на среднее как на «сумма / количество».

При объединении групп нельзя просто усреднить два средних, если размеры групп различаются. Сначала превратите каждое среднее в сумму, сложите суммы и разделите на общее число наблюдений.

Кодирование похоже на работу в другой шкале: чтобы вернуться к исходным единицам, отмените масштабирование и сдвиг.$t$,
$t$Не усредняйте средние групп без проверки их размеров. Перед объединением используйте сумма = n×среднее. Для кодированных данных явно запишите обратное преобразование и применяйте масштаб и сдвиг в правильном порядке. Не смешивайте исходные и кодированные единицы.$t$,
'p5:P5-DAT-10:theory:ru:v1'
),
(
'p5:P5-DAT-10:tutor:uz:v2','P5','P5-DAT-10','uz','tutor_v2_learner_first','Kodlangan va birlashtirilgan ma’lumotlar',
$t$Kodlangan va birlashtirilgan ma’lumotlar masalalarida barcha xom qiymatlarni qayta tiklamasdan yig‘indi va xulosa ko‘rsatkichlari bilan ishlash mumkin.

Birlashtirish uchun avval har bir guruhning umumiy yig‘indisini toping.

A guruh: n=20, o‘rtacha 50, demak yig‘indi = 20×50 = 1000.

B guruh: n=30, o‘rtacha 60, demak yig‘indi = 30×60 = 1800.

Birlashtirilgan o‘rtacha:

(1000+1800)/(20+30) = 2800/50 = 56.

Kodlashda o‘zgarishni teskari bajaring. Agar

y=(x-50)/10,

bo‘lsa

x=10y+50.

Kodlangan o‘rtacha ȳ=1.2 bo‘lsa, asl o‘rtacha

x̄=10(1.2)+50=62.

Asosiy g‘oya — butun to‘plamni qayta qurmasdan yig‘indi va xulosa ko‘rsatkichlarini tizimli o‘zgartirish.$t$,
$t$Guruhlarni birlashtirishda avval yig‘indilarni toping.

A: 20 qiymat, o‘rtacha 50 → yig‘indi 1000.

B: 30 qiymat, o‘rtacha 60 → yig‘indi 1800.

Birlashtirilgan o‘rtacha = 2800/50 = 56.

y=(x-50)/10 bo‘lsa, teskari formula x=10y+50. ȳ=1.2 bo‘lsa, x̄=62.$t$,
$t$O‘rtachani “yig‘indi / qiymatlar soni” deb o‘ylang.

Ikki guruh hajmi turlicha bo‘lsa, ularning o‘rtachalarini shunchaki o‘rtachalash mumkin emas. Har bir o‘rtachadan umumiy yig‘indini toping, yig‘indilarni qo‘shing va jami kuzatuvlar soniga bo‘ling.

Kodlash boshqa shkala bilan ishlashdir; asl birlikka qaytish uchun masshtab va siljishni teskari bajaring.$t$,
$t$Guruh o‘rtachalarini ularning hajmini tekshirmasdan o‘rtachalamang. Birlashtirishdan oldin yig‘indi = n×o‘rtacha dan foydalaning. Kodlangan ma’lumotda teskari o‘zgarishni aniq yozing va masshtab hamda siljishni to‘g‘ri tartibda qaytaring. Asl va kodlangan birliklarni aralashtirmang.$t$,
'p5:P5-DAT-10:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
