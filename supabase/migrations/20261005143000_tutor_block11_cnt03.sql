begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>174 then raise exception 'CNT03 expected 174 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-CNT-03' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'CNT03 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-CNT-03:tutor:en:v2','P5','P5-CNT-03','en','tutor_v2_learner_first','Arrangements with repeated objects',
$t$If some objects are identical, ordinary factorial counting overcounts because swapping identical objects does not create a new arrangement.

For the word

LEVEL

there are 5 letters, so 5! would count arrangements as if every letter were different. But L appears twice and E appears twice.

Swapping the two Ls changes nothing, so divide by 2!. The same is true for the two Es.

Therefore the number of distinct arrangements is

5! / (2!2!) = 30.

The general idea is: start with the arrangement count as if all objects were distinct, then divide by the factorial of each repeated group to remove duplicate counting.$t$,
$t$For LEVEL there are 5 letters, but L repeats twice and E repeats twice.

So

distinct arrangements = 5!/(2!2!) = 30.

The divisions remove arrangements that look identical because repeated letters were only swapped with each other.$t$,
$t$Imagine temporarily labelling the two Ls as L₁ and L₂. Ordinary 5! treats arrangements with L₁ and L₂ swapped as different, even though the visible word does not change.

There are 2! such label-swaps for the Ls and 2! for the Es.

Dividing by those repeat factorials removes the artificial duplicates.$t$,
$t$Count the total number of objects first. Then identify every group of identical objects and divide by each repeat factorial. Do not divide for objects that are genuinely different, even if they have a similar role or appearance in the context.$t$,
'p5:P5-CNT-03:theory:en:v1'
),
(
'p5:P5-CNT-03:tutor:ru:v2','P5','P5-CNT-03','ru','tutor_v2_learner_first','Перестановки с повторениями',
$t$Если некоторые объекты одинаковы, обычный факториал даёт лишний счёт: перестановка одинаковых объектов между собой не создаёт нового размещения.

Рассмотрим слово

LEVEL.

Всего 5 букв, поэтому 5! считал бы все буквы различными. Но L встречается дважды и E встречается дважды.

Перестановка двух L ничего не меняет, поэтому нужно разделить на 2!. То же самое для двух E.

Число различных перестановок:

5! / (2!2!) = 30.

Общий принцип: сначала посчитать так, будто все объекты различны, затем разделить на факториалы размеров всех повторяющихся групп.$t$,
$t$В слове LEVEL 5 букв, но L повторяется два раза и E повторяется два раза.

Поэтому

число различных перестановок = 5!/(2!2!) = 30.

Деление убирает варианты, которые выглядят одинаково из-за перестановки одинаковых букв.$t$,
$t$Временно пометьте две буквы L как L₁ и L₂. Обычный 5! считает перестановку L₁ и L₂ новым случаем, хотя видимое слово не меняется.

Таких перестановок меток для L — 2!, и столько же для E.

Деление на эти факториалы удаляет искусственные дубликаты.$t$,
$t$Сначала посчитайте общее число объектов. Затем найдите каждую группу одинаковых объектов и разделите на факториал количества повторов. Не делите для объектов, которые действительно различны, даже если в задаче они выполняют похожую роль.$t$,
'p5:P5-CNT-03:theory:ru:v1'
),
(
'p5:P5-CNT-03:tutor:uz:v2','P5','P5-CNT-03','uz','tutor_v2_learner_first','Takrorlanuvchi obyektlar joylashuvi',
$t$Ba’zi obyektlar bir xil bo‘lsa, oddiy faktorial ortiqcha sanaydi, chunki bir xil obyektlarni o‘zaro almashtirish yangi joylashuv yaratmaydi.

LEVEL so‘zini olaylik.

Jami 5 ta harf bor, shuning uchun 5! barcha harflarni turli deb hisoblaydi. Lekin L ikki marta va E ikki marta takrorlangan.

Ikki L ni almashtirish natijani o‘zgartirmaydi, shuning uchun 2! ga bo‘lamiz. Ikki E uchun ham xuddi shunday.

Turli joylashuvlar soni:

5! / (2!2!) = 30.

Umumiy g‘oya: avval barcha obyektlar turli deb sanang, keyin har bir takrorlanuvchi guruh faktorialiga bo‘lib ortiqcha hisobni olib tashlang.$t$,
$t$LEVEL so‘zida 5 ta harf bor, lekin L ikki marta va E ikki marta takrorlanadi.

Shuning uchun

turli joylashuvlar = 5!/(2!2!) = 30.

Bo‘lish bir xil harflar o‘rin almashgani uchun tashqi ko‘rinishi o‘zgarmagan takroriy holatlarni olib tashlaydi.$t$,
$t$Ikki L ni vaqtincha L₁ va L₂ deb belgilang. Oddiy 5! L₁ va L₂ o‘rin almashtirgan holatni yangi natija deb hisoblaydi, lekin ko‘rinadigan so‘z o‘zgarmaydi.

L lar uchun 2! ta, E lar uchun ham 2! ta shunday sun’iy farq bor.

Shu faktoriallarga bo‘lish ortiqcha dublikatlarni olib tashlaydi.$t$,
$t$Avval obyektlarning umumiy sonini aniqlang. Keyin har bir bir xil obyektlar guruhini topib, takrorlar soni faktorialiga bo‘ling. Haqiqatan turli obyektlarni, hatto vazifasi o‘xshash bo‘lsa ham, bir xil deb hisoblamang.$t$,
'p5:P5-CNT-03:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
