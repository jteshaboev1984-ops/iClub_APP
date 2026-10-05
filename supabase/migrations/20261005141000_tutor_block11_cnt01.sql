begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>168 then raise exception 'CNT01 expected 168 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-CNT-01')<>0
  then raise exception 'CNT01 Tutor Cards already exist'; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-CNT-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'CNT01 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-CNT-01:tutor:en:v2','P5','P5-CNT-01','en','tutor_v2_learner_first','Arrangements and selections',
$t$Before counting, decide whether order matters.

Suppose you have four people A, B, C and D and need to choose three.

If the three places are ordered, such as first, second and third, then changing the order creates a different outcome. The count is

4 × 3 × 2 = 24.

If the task is only to choose a committee of three, ABC and CBA are the same committee. Order does not matter, so use a combination:

4C3 = 4.

This order decision is the key step. Product-rule or permutation methods count ordered outcomes; combinations count selections where rearranging the chosen objects does not create a new result.$t$,
$t$Ask one question first:

Does changing the order make a new outcome?

For three ordered positions chosen from A, B, C, D:

4×3×2 = 24.

For an unordered committee of three:

4C3 = 4.

Order matters → arrangement.
Order does not matter → combination.$t$,
$t$Think about whether labels are attached to the chosen places.

If you choose a president, secretary and treasurer, the roles make the positions different, so A-B-C is not the same as C-B-A.

If you choose only a three-person team, the same three people form one result no matter how you list them.

The formula comes after this interpretation.$t$,
$t$Do not choose nPr or nCr from the wording alone. Test whether swapping two selected objects changes the outcome. If it does, order matters. If it does not, use an unordered selection. For multi-stage choices, multiply the number of choices at successive stages.$t$,
'p5:P5-CNT-01:theory:en:v1'
),
(
'p5:P5-CNT-01:tutor:ru:v2','P5','P5-CNT-01','ru','tutor_v2_learner_first','Размещения и выборки',
$t$Перед подсчётом сначала решите, важен ли порядок.

Пусть есть четыре человека A, B, C и D, и нужно выбрать троих.

Если три места различаются, например первое, второе и третье, то изменение порядка даёт новый результат. Получаем

4 × 3 × 2 = 24.

Если нужно только выбрать комитет из трёх человек, то ABC и CBA — один и тот же комитет. Порядок не важен, поэтому используем сочетание:

4C3 = 4.

Именно решение о порядке — главный шаг. Правило произведения и перестановки считают упорядоченные результаты; сочетания — выборки, где перестановка выбранных объектов не создаёт новый исход.$t$,
$t$Сначала задайте один вопрос:

Создаёт ли другой порядок новый результат?

Для трёх различающихся мест из A, B, C, D:

4×3×2 = 24.

Для неупорядоченного комитета из трёх:

4C3 = 4.

Порядок важен → размещение.
Порядок не важен → сочетание.$t$,
$t$Подумайте, есть ли у выбранных мест разные роли.

Если выбирают президента, секретаря и казначея, роли различаются, поэтому A-B-C и C-B-A — разные результаты.

Если выбирают просто команду из трёх человек, те же трое образуют один результат независимо от порядка записи.

Сначала смысл, потом формула.$t$,
$t$Не выбирайте nPr или nCr только по знакомому слову в условии. Проверьте: если поменять два выбранных объекта местами, изменится ли результат? Если да — порядок важен. Если нет — это неупорядоченная выборка. Для последовательных этапов используйте правило произведения.$t$,
'p5:P5-CNT-01:theory:ru:v1'
),
(
'p5:P5-CNT-01:tutor:uz:v2','P5','P5-CNT-01','uz','tutor_v2_learner_first','Joylashtirish va tanlash',
$t$Sanashdan oldin avval tartib muhim yoki yo‘qligini aniqlang.

A, B, C va D degan to‘rt odamdan uchtasini tanlaymiz.

Agar uchta joy farqli bo‘lsa, masalan birinchi, ikkinchi va uchinchi, tartib o‘zgarsa yangi natija hosil bo‘ladi:

4 × 3 × 2 = 24.

Agar faqat uch kishilik qo‘mita tanlansa, ABC va CBA bir xil qo‘mita. Tartib muhim emas, shuning uchun kombinatsiya ishlatiladi:

4C3 = 4.

Asosiy qadam — tartib haqidagi qaror. Ko‘paytirish qoidasi va permutatsiyalar tartibli natijalarni, kombinatsiyalar esa tartibsiz tanlovlarni hisoblaydi.$t$,
$t$Avval bitta savol bering:

Tartibni almashtirish yangi natija beradimi?

A, B, C, D dan uchta farqli o‘rin uchun:

4×3×2 = 24.

Uch kishilik tartibsiz qo‘mita uchun:

4C3 = 4.

Tartib muhim → joylashtirish.
Tartib muhim emas → kombinatsiya.$t$,
$t$Tanlangan o‘rinlarda alohida rollar bormi, deb o‘ylang.

Prezident, kotib va xazinachi tanlansa, rollar farqli, shuning uchun A-B-C va C-B-A boshqa natijalar.

Faqat uch kishilik jamoa tanlansa, o‘sha uch odam qaysi tartibda yozilishidan qat’i nazar bitta natija.

Avval ma’noni tushuning, keyin formulani tanlang.$t$,
$t$nPr yoki nCr ni faqat kalit so‘zga qarab tanlamang. Ikki tanlangan obyektni joyini almashtirsangiz natija o‘zgaradimi, tekshiring. O‘zgarsa tartib muhim. O‘zgarmasa tartibsiz tanlov. Ketma-ket bosqichlarda tanlov sonlarini ko‘paytiring.$t$,
'p5:P5-CNT-01:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
