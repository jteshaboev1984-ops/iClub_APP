begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>171 then raise exception 'CNT02 expected 171 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-CNT-02' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'CNT02 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-CNT-02:tutor:en:v2','P5','P5-CNT-02','en','tutor_v2_learner_first','Permutations of distinct objects',
$t$When all objects are different and every position matters, arrange them using the product rule.

For five distinct books in a row:

5 choices for the first position,
then 4,
then 3,
then 2,
then 1.

So the number of arrangements is

5×4×3×2×1 = 5! = 120.

Factorial notation is simply a compact way to write this decreasing product.

The reason each factor changes is that once an object is used, it cannot be used again. This is what distinguishes arrangements without repetition from situations where choices can repeat.$t$,
$t$Five distinct books can be arranged in

5! = 5×4×3×2×1 = 120

ways.

Each time you place one book, one fewer book remains for the next position.

For n distinct objects arranged in a line, the count is n!.$t$,
$t$Imagine filling positions one by one.

The first position has the most freedom. Every choice you make reduces the options for the next position.

For five different objects the choice pattern is 5, 4, 3, 2, 1. Multiplying these gives 5!.

So factorial comes directly from the product rule, not from a separate counting idea.$t$,
$t$Use n! only when all n distinct objects are being arranged and order matters. If only some positions are filled, stop the decreasing product at the required number of factors. If objects are identical, ordinary n! will overcount.$t$,
'p5:P5-CNT-02:theory:en:v1'
),
(
'p5:P5-CNT-02:tutor:ru:v2','P5','P5-CNT-02','ru','tutor_v2_learner_first','Перестановки различных объектов',
$t$Если все объекты различны и каждое место важно, используйте правило произведения.

Для пяти разных книг в ряд:

5 вариантов для первого места,
затем 4,
затем 3,
затем 2,
затем 1.

Поэтому число размещений:

5×4×3×2×1 = 5! = 120.

Факториал — это просто короткая запись такого убывающего произведения.

Каждый следующий множитель меньше, потому что уже использованный объект нельзя выбрать снова. Это и создаёт перестановку без повторений.$t$,
$t$Пять различных книг можно расположить

5! = 5×4×3×2×1 = 120

способами.

После выбора одной книги остаётся на одну меньше для следующего места.

Для n различных объектов в ряд число перестановок равно n!.$t$,
$t$Представьте, что вы заполняете места по одному.

Для первого места выбор самый большой. После каждого выбора число доступных объектов уменьшается.

Для пяти разных объектов получается последовательность 5, 4, 3, 2, 1. Их произведение и есть 5!.

То есть факториал прямо следует из правила произведения.$t$,
$t$n! используйте, когда все n различных объектов размещаются и порядок важен. Если заполняется только часть мест, остановите убывающее произведение после нужного числа множителей. Если есть одинаковые объекты, обычный n! будет считать лишние варианты.$t$,
'p5:P5-CNT-02:theory:ru:v1'
),
(
'p5:P5-CNT-02:tutor:uz:v2','P5','P5-CNT-02','uz','tutor_v2_learner_first','Turli obyektlar permutatsiyasi',
$t$Barcha obyektlar turli bo‘lsa va har bir joy muhim bo‘lsa, ularni ko‘paytirish qoidasi bilan joylashtiring.

Beshta turli kitobni bir qatorga qo‘yishda:

birinchi joy uchun 5 tanlov,
keyin 4,
keyin 3,
keyin 2,
keyin 1.

Shuning uchun joylashtirishlar soni

5×4×3×2×1 = 5! = 120.

Faktorial shu kamayib boradigan ko‘paytmaning qisqa yozuvidir.

Har safar bir obyekt ishlatilgach, keyingi joy uchun bitta kam variant qoladi. Takrorsiz permutatsiyaning asosiy sababi shu.$t$,
$t$Beshta turli kitobni

5! = 5×4×3×2×1 = 120

usulda joylashtirish mumkin.

Har bir kitob joylashtirilgach, keyingi joy uchun bitta kam kitob qoladi.

n ta turli obyektning qatordagi joylashuvi n! ga teng.$t$,
$t$Joylarni birma-bir to‘ldirayotganingizni tasavvur qiling.

Birinchi joyda tanlov eng ko‘p. Har bir tanlovdan keyin keyingi joy uchun imkoniyatlar kamayadi.

Beshta obyekt uchun 5, 4, 3, 2, 1 hosil bo‘ladi. Ularning ko‘paytmasi 5!.

Demak, faktorial alohida g‘oya emas, ko‘paytirish qoidasining qisqa shakli.$t$,
$t$n! ni barcha n ta turli obyekt joylashtirilganda va tartib muhim bo‘lganda ishlating. Agar faqat ayrim joylar to‘ldirilsa, kamayuvchi ko‘paytmani kerakli bosqichda to‘xtating. Bir xil obyektlar bo‘lsa, oddiy n! ortiqcha hisoblaydi.$t$,
'p5:P5-CNT-02:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
