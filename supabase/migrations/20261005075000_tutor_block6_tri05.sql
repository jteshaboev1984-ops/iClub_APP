begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>84 then raise exception 'TRI05 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P1' and skill_code='P1-TRI-05' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'TRI05 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p1:P1-TRI-05:tutor:en:v2','P1','P1-TRI-05','en','tutor_v2_learner_first','Trigonometric equations',
$t$A trigonometric equation can have more than one solution because trig graphs repeat. A calculator usually gives only one principal angle, so the interval must be used to find every required solution.

For example,

sin x = 1/2,   0 ≤ x ≤ 2π.

The principal/reference angle is π/6. Sine is positive in quadrants I and II, so within the interval

x = π/6, 5π/6.

Both solutions should be listed.

A reliable method is:
1. find the principal/reference angle;
2. decide which quadrants or graph positions give the required sign;
3. use periodicity if the interval is wider;
4. keep only values inside the stated interval.

The final answer is the complete solution set for that interval, not just the first calculator output.$t$,
$t$For sin x=1/2 on 0≤x≤2π:

reference angle = π/6.

Sine is positive in quadrants I and II, so

x=π/6, 5π/6.

Do not stop after the first calculator answer. Always use the stated interval to check for every solution.$t$,
$t$You can also solve a trig equation by thinking about graph intersections.

For sin x=1/2, draw or imagine y=sin x and the horizontal line y=1/2. Over 0≤x≤2π, the line meets the sine graph twice.

Those x-coordinates are π/6 and 5π/6.

This graph view makes it clear why one principal calculator value may not be enough.$t$,
$t$Write the interval before solving. Check calculator angle mode. After finding a reference angle, use sign, symmetry and period to generate all possible solutions, then discard anything outside the interval. Check endpoints when they are included.$t$,
'p1:P1-TRI-05:theory:en:v1'
),
(
'p1:P1-TRI-05:tutor:ru:v2','P1','P1-TRI-05','ru','tutor_v2_learner_first','Тригонометрические уравнения',
$t$Тригонометрическое уравнение может иметь несколько решений, потому что тригонометрические графики повторяются. Калькулятор обычно даёт только одно главное значение, поэтому заданный промежуток нужно использовать, чтобы найти все решения.

Например,

sin x = 1/2,   0 ≤ x ≤ 2π.

Опорный угол равен π/6. Sine положителен в I и II четвертях, поэтому на этом промежутке

x = π/6, 5π/6.

Нужно записать оба решения.

Надёжный порядок:
1. найти главное/опорное значение;
2. определить четверти или участки графика с нужным знаком;
3. использовать периодичность, если промежуток шире;
4. оставить только значения внутри заданного промежутка.

Финальный ответ — полный набор решений на указанном промежутке, а не только первый результат калькулятора.$t$,
$t$Для sin x=1/2 на 0≤x≤2π:

опорный угол = π/6.

Sine положителен в I и II четвертях, поэтому

x=π/6, 5π/6.

Не останавливайтесь на первом ответе калькулятора. Всегда проверяйте весь заданный промежуток.$t$,
$t$Можно решать тригонометрическое уравнение как задачу о пересечении графиков.

Для sin x=1/2 представьте y=sin x и горизонтальную прямую y=1/2. На промежутке 0≤x≤2π они пересекаются дважды.

Координаты x этих точек: π/6 и 5π/6.

Так видно, почему одного главного значения калькулятора недостаточно.$t$,
$t$Сначала выпишите промежуток и проверьте режим углов на калькуляторе. После нахождения опорного угла используйте знак, симметрию и период, чтобы получить все возможные решения, затем исключите значения вне промежутка. Если границы включены, проверьте и их.$t$,
'p1:P1-TRI-05:theory:ru:v1'
),
(
'p1:P1-TRI-05:tutor:uz:v2','P1','P1-TRI-05','uz','tutor_v2_learner_first','Trigonometrik tenglamalar',
$t$Trigonometrik tenglama bir nechta yechimga ega bo‘lishi mumkin, chunki trigonometrik grafiklar takrorlanadi. Kalkulyator odatda faqat bitta asosiy qiymatni beradi, shuning uchun berilgan oraliqdagi barcha yechimlarni alohida topish kerak.

Masalan,

sin x = 1/2,   0 ≤ x ≤ 2π.

Tayanch burchak π/6. Sine I va II choraklarda musbat, shuning uchun shu oraliqda

x = π/6, 5π/6.

Ikkala yechim ham yozilishi kerak.

Ishonchli tartib:
1. asosiy/tayanch burchakni toping;
2. kerakli ishora qaysi chorak yoki grafik qismlarida bo‘lishini aniqlang;
3. oraliq keng bo‘lsa davriylikdan foydalaning;
4. faqat berilgan oraliqdagi qiymatlarni qoldiring.

Yakuniy javob bitta kalkulyator natijasi emas, balki oraliqdagi to‘liq yechimlar to‘plamidir.$t$,
$t$sin x=1/2 va 0≤x≤2π uchun:

tayanch burchak = π/6.

Sine I va II choraklarda musbat, shuning uchun

x=π/6, 5π/6.

Kalkulyatordagi birinchi javobda to‘xtamang. Berilgan oraliqdagi barcha yechimlarni tekshiring.$t$,
$t$Trigonometrik tenglamani grafiklar kesishishi sifatida ham ko‘rish mumkin.

sin x=1/2 uchun y=sin x va y=1/2 gorizontal chiziqni tasavvur qiling. 0≤x≤2π oraliqda ular ikki marta kesishadi.

Bu nuqtalarning x-koordinatalari π/6 va 5π/6.

Grafik qarash bitta asosiy kalkulyator qiymati nega yetarli emasligini ko‘rsatadi.$t$,
$t$Avval oraliqni yozib oling va kalkulyator burchak rejimini tekshiring. Tayanch burchak topilgach, ishora, simmetriya va davrdan foydalanib barcha mumkin yechimlarni hosil qiling, keyin oraliqdan tashqaridagilarni olib tashlang. Chegara nuqtalari kiritilgan bo‘lsa, ularni ham tekshiring.$t$,
'p1:P1-TRI-05:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
