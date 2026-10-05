begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>177 then raise exception 'CNT04 expected 177 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-CNT-04' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'CNT04 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-CNT-04:tutor:en:v2','P5','P5-CNT-04','en','tutor_v2_learner_first','Restricted arrangements',
$t$Restrictions change a counting problem because not every ordinary arrangement is allowed. The useful strategy is to turn the restriction into a simpler counting structure.

Suppose A, B, C, D and E are arranged in a row and A and B must be together.

Treat A and B as one block. Then there are four objects to arrange:

[AB], C, D, E.

These can be arranged in 4! ways. Inside the block, A and B can appear as AB or BA, giving 2 orders.

So

together = 4!×2 = 48.

If the question instead asks for A and B apart, use the complement:

5! - 48 = 72.

The restriction tells you which method is most efficient: block, fixed position, complement, or separate cases.$t$,
$t$For A, B, C, D, E in a row with A and B together:

Treat A and B as one block.

Arrange [AB], C, D, E: 4! ways.

Order A and B inside the block: 2 ways.

Total = 4!×2 = 48.

If A and B must be apart:

5! - 48 = 72.$t$,
$t$Think of a restriction as changing the objects you are counting.

When A and B must stay together, they temporarily behave like one larger object. You arrange that block with the other objects, then count the possible order inside the block.

When “apart” is harder to count directly, count all arrangements and subtract the “together” cases.$t$,
$t$Choose the restriction method before calculating. “Together” often suggests a block. “Not together” can often use total minus together. Fixed positions should be handled before arranging the remaining objects. If cases overlap, do not add them without checking for double counting.$t$,
'p5:P5-CNT-04:theory:en:v1'
),
(
'p5:P5-CNT-04:tutor:ru:v2','P5','P5-CNT-04','ru','tutor_v2_learner_first','Размещения с ограничениями',
$t$Ограничения меняют задачу на подсчёт, потому что разрешены не все обычные перестановки. Полезно превратить ограничение в более простую структуру.

Пусть A, B, C, D и E стоят в ряд, причём A и B должны быть вместе.

Считайте A и B одним блоком. Тогда размещаем четыре объекта:

[AB], C, D, E.

Это можно сделать 4! способами. Внутри блока возможны два порядка: AB и BA.

Поэтому

вместе = 4!×2 = 48.

Если нужно, чтобы A и B не стояли вместе, удобнее использовать дополнение:

5! - 48 = 72.

Само ограничение подсказывает метод: блок, фиксированное место, дополнение или разбиение на случаи.$t$,
$t$Для A, B, C, D, E в ряд, если A и B должны быть вместе:

Считайте A и B одним блоком.

Размещаем [AB], C, D, E: 4! способов.

Внутри блока два порядка.

Итого: 4!×2 = 48.

Если A и B должны быть раздельно:

5! - 48 = 72.$t$,
$t$Представьте, что ограничение меняет сами объекты задачи.

Если A и B должны быть рядом, временно объедините их в один крупный объект. Сначала разместите этот блок с остальными, затем учтите порядок внутри блока.

Если условие «не вместе» считать напрямую неудобно, посчитайте все варианты и вычтите случаи «вместе».$t$,
$t$Сначала выберите стратегию ограничения. «Вместе» часто означает блок. «Не вместе» часто удобно считать как все варианты минус случаи вместе. Фиксированные места учитывайте до размещения остальных объектов. При сложении случаев проверяйте, не пересекаются ли они.$t$,
'p5:P5-CNT-04:theory:ru:v1'
),
(
'p5:P5-CNT-04:tutor:uz:v2','P5','P5-CNT-04','uz','tutor_v2_learner_first','Cheklovli joylashtirish',
$t$Cheklov bo‘lsa, oddiy joylashuvlarning hammasi ruxsat etilmaydi. Eng qulay usul — cheklovni soddaroq sanash tuzilmasiga aylantirish.

A, B, C, D va E bir qatorda joylashsin va A bilan B yonma-yon bo‘lishi kerak.

A va B ni bitta blok deb oling. Endi to‘rtta obyekt joylashtiriladi:

[AB], C, D, E.

Ularni 4! usulda joylashtirish mumkin. Blok ichida esa AB yoki BA — 2 ta tartib bor.

Shuning uchun

birga = 4!×2 = 48.

A va B alohida turishi kerak bo‘lsa, complement qulay:

5! - 48 = 72.

Cheklovning o‘zi qaysi usul qulayligini ko‘rsatadi: blok, mahkamlangan joy, complement yoki alohida holatlar.$t$,
$t$A, B, C, D, E qatorda va A bilan B birga bo‘lsa:

A va B ni bitta blok deb oling.

[AB], C, D, E ni joylashtirish: 4!.

Blok ichida 2 ta tartib.

Jami: 4!×2 = 48.

A va B alohida bo‘lsa:

5! - 48 = 72.$t$,
$t$Cheklovni sanalayotgan obyektlarni o‘zgartiradigan shart deb o‘ylang.

A va B yonma-yon bo‘lsa, ularni vaqtincha bitta katta obyekt sifatida ko‘ring. Avval blokni boshqalar bilan joylashtiring, keyin blok ichidagi tartibni hisoblang.

“Alohida” holatini to‘g‘ridan-to‘g‘ri sanash qiyin bo‘lsa, barcha holatlardan “birga” holatlarini ayiring.$t$,
$t$Hisoblashdan oldin cheklov strategiyasini tanlang. “Birga” ko‘pincha blok usulini bildiradi. “Birga emas” ko‘pincha jami minus birga orqali osonroq. Mahkamlangan joylarni avval hisobga oling. Holatlarni qo‘shishda ularning kesishmasligini tekshiring.$t$,
'p5:P5-CNT-04:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
