-- P1-02 intentional diagnostic interpretations for P1-FUN-03/04/05.
-- Three approved wrong-option rules per diagnostic item; private only.

begin;
with rules(cvkey,ckey,match,dcode,mtype,skill,fen,fru,fuz,nen,nru,nuz) as (values
('p1_aw09_12_functions_v1','P1FUN03-D01','B','outer_domain_not_preimaged','concept','P1-FUN-03',
'The restriction for f is that its input cannot equal 2. In the composite, that input is g(x)=x+3, so the condition is x+3≠2, not x≠2.',
'Ограничение функции f относится к её аргументу: он не может равняться 2. В композиции этим аргументом является g(x)=x+3, поэтому нужно x+3≠2, а не x≠2.',
'f uchun cheklov uning kirishiga tegishli: kirish 2 ga teng bo‘la olmaydi. Kompozitsiyada bu kirish g(x)=x+3, demak x+3≠2, x≠2 emas.',
'Write the forbidden-input condition for the outer function as g(x) ≠ 2 and solve it for x.',
'Запишите условие запрещённого аргумента внешней функции как g(x) ≠ 2 и решите его относительно x.',
'Tashqi funksiyaning taqiqlangan kirish shartini g(x) ≠ 2 deb yozing va x bo‘yicha yeching.'),
('p1_aw09_12_functions_v1','P1FUN03-D01','C','inner_zero_confused_with_outer_pole','concept','P1-FUN-03',
'The inner function is allowed to equal zero. The problem occurs when g(x) equals 2, because f(t)=1/(t−2) is undefined at t=2.',
'Внутренняя функция может принимать значение 0. Проблема возникает при g(x)=2, потому что f(t)=1/(t−2) не определена при t=2.',
'Ichki funksiya 0 ga teng bo‘lishi mumkin. Muammo g(x)=2 bo‘lganda yuz beradi, chunki f(t)=1/(t−2) t=2 da aniqlanmagan.',
'Identify the forbidden value in the denominator of the outer function before solving for x.',
'Сначала определите запрещённое значение в знаменателе внешней функции, затем находите x.',
'Avval tashqi funksiyaning maxrajidagi taqiqlangan qiymatni aniqlang, keyin x ni toping.'),
('p1_aw09_12_functions_v1','P1FUN03-D01','D','composite_domain_unchecked','method','P1-FUN-03',
'The composite is 1/(x+1), so it is not defined at x=−1. Composition does not automatically preserve an all-real domain.',
'Композиция равна 1/(x+1), поэтому она не определена при x=−1. Композиция не обязана иметь область всех действительных чисел.',
'Kompozitsiya 1/(x+1), shuning uchun x=−1 da aniqlanmagan. Kompozitsiya avtomatik ravishda barcha haqiqiy sonlarda aniqlanmaydi.',
'Simplify the composite first, then check every denominator, square root or other domain restriction.',
'Сначала упростите композицию, затем проверьте все знаменатели, корни и другие ограничения области определения.',
'Avval kompozitsiyani soddalashtiring, so‘ng barcha maxrajlar, ildizlar va boshqa soha cheklovlarini tekshiring.'),

('p1_aw09_12_functions_v1','P1FUN04-D01','B','inverse_constant_operation_not_reversed','method','P1-FUN-04',
'To undo f(x)=2x−3, first add 3 and then divide by 2. Subtracting 3 again repeats the original shift instead of reversing it.',
'Чтобы обратить f(x)=2x−3, сначала нужно прибавить 3, затем разделить на 2. Повторное вычитание 3 не обращает исходный сдвиг.',
'f(x)=2x−3 ni teskari qilish uchun avval 3 qo‘shib, keyin 2 ga bo‘lish kerak. Yana 3 ayirish asl siljishni teskari qilmaydi.',
'Think of the original operations in order and undo them in reverse order with inverse operations.',
'Запишите действия исходной функции и отменяйте их в обратном порядке обратными операциями.',
'Asl funksiyadagi amallar tartibini yozing va ularni teskari tartibda qarama-qarshi amallar bilan bekor qiling.'),
('p1_aw09_12_functions_v1','P1FUN04-D01','C','inverse_not_solved_for_output','concept','P1-FUN-04',
'Changing −3 to +3 is not enough. An inverse must also undo the multiplication by 2, so the result must include division by 2.',
'Недостаточно заменить −3 на +3. Обратная функция должна также отменить умножение на 2, поэтому нужно деление на 2.',
'−3 ni +3 ga almashtirish yetarli emas. Teskari funksiya 2 ga ko‘paytirishni ham bekor qilishi kerak, shuning uchun 2 ga bo‘lish zarur.',
'Swap x and y, then solve the entire equation for y rather than changing signs by inspection.',
'Поменяйте x и y местами и полностью решите уравнение относительно y, а не меняйте знаки на глаз.',
'x va y ni almashtiring, so‘ng ishoralarni taxminan almashtirish o‘rniga tenglamani to‘liq y bo‘yicha yeching.'),
('p1_aw09_12_functions_v1','P1FUN04-D01','D','inverse_scale_multiplied','method','P1-FUN-04',
'The original function multiplies by 2, so the inverse must divide by 2. Multiplying by 2 again moves values farther from the original input.',
'Исходная функция умножает на 2, поэтому обратная должна делить на 2. Повторное умножение на 2 не возвращает исходный аргумент.',
'Asl funksiya 2 ga ko‘paytiradi, shuning uchun teskari funksiya 2 ga bo‘lishi kerak. Yana 2 ga ko‘paytirish asl kirishga qaytarmaydi.',
'Verify a candidate inverse by checking f(f⁻¹(x))=x.',
'Проверьте кандидат на обратную функцию равенством f(f⁻¹(x))=x.',
'Teskari funksiya nomzodini f(f⁻¹(x))=x orqali tekshiring.'),

('p1_aw09_12_functions_v1','P1FUN05-D01','B','inverse_confused_y_axis_reflection','concept','P1-FUN-05',
'The point (−2,5) is a reflection of (2,5) in the y-axis. A function and its inverse are reflected in y=x, which swaps the coordinates instead.',
'Точка (−2,5) — отражение (2,5) относительно оси y. Функция и обратная к ней отражаются относительно y=x, то есть координаты меняются местами.',
'(−2,5) nuqta (2,5) ning y o‘qiga nisbatan aksidir. Funksiya va uning teskarisi y=x ga nisbatan akslanadi, ya’ni koordinatalar o‘rin almashadi.',
'Use the inverse point rule (a,b) → (b,a), not an axis-reflection sign rule.',
'Используйте правило обратной функции (a,b) → (b,a), а не смену знака при отражении относительно оси.',
'Teskari funksiya uchun (a,b) → (b,a) qoidasidan foydalaning, o‘q bo‘yicha ishora almashtirishdan emas.'),
('p1_aw09_12_functions_v1','P1FUN05-D01','C','inverse_confused_x_axis_reflection','concept','P1-FUN-05',
'The point (2,−5) is reflection in the x-axis. Inversion does not negate the output; it interchanges input and output.',
'Точка (2,−5) получается отражением относительно оси x. Обращение функции не меняет знак значения, а меняет местами аргумент и значение.',
'(2,−5) x o‘qiga nisbatan aksdir. Teskari funksiya chiqish ishorasini o‘zgartirmaydi, balki kirish va chiqishni almashtiradi.',
'Translate f(2)=5 directly into the inverse statement f⁻¹(5)=2.',
'Перепишите f(2)=5 напрямую как f⁻¹(5)=2.',
'f(2)=5 ni to‘g‘ridan-to‘g‘ri f⁻¹(5)=2 ko‘rinishida yozing.'),
('p1_aw09_12_functions_v1','P1FUN05-D01','D','inverse_confused_origin_reflection','method','P1-FUN-05',
'Changing both signs gives reflection through the origin, not reflection in y=x. The inverse point must be (5,2).',
'Смена обоих знаков даёт отражение относительно начала координат, а не относительно y=x. Точка обратной функции должна быть (5,2).',
'Ikkala ishorani o‘zgartirish koordinata boshiga nisbatan aks beradi, y=x ga nisbatan emas. Teskari funksiya nuqtasi (5,2) bo‘lishi kerak.',
'Sketch the line y=x mentally: reflection across it swaps horizontal and vertical coordinates without changing their signs.',
'Представьте прямую y=x: отражение относительно неё меняет горизонтальную и вертикальную координаты местами, не меняя их знаки.',
'y=x chizig‘ini tasavvur qiling: unga nisbatan akslantirish gorizontal va vertikal koordinatalarni ishoralarini o‘zgartirmasdan almashtiradi.')
), meta as (
  select m.id,m.content_key,cv.content_version
  from private.exam_prep_question_content_meta m
  join private.exam_prep_content_versions cv on cv.id=m.content_version_id
  where cv.content_version='p1_aw09_12_functions_v1' and m.reserve_role='diagnostic'
)
insert into private.exam_prep_diagnostic_rules(content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status,approved_at)
select meta.id,'drv1','mcq_option',r.match,r.dcode,r.mtype,r.skill,r.fen,r.fru,r.fuz,r.nen,r.nru,r.nuz,'approved',now()
from rules r join meta on meta.content_version=r.cvkey and meta.content_key=r.ckey
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;
do $$ declare v_bad int; begin
 select count(*) into v_bad from (
   select m.id from private.exam_prep_question_content_meta m
   join private.exam_prep_content_versions cv on cv.id=m.content_version_id
   join public.questions q on q.id=m.question_id
   left join private.exam_prep_diagnostic_rules r on r.content_meta_id=m.id and r.status='approved' and r.answer_kind='mcq_option'
   where cv.content_version='p1_aw09_12_functions_v1' and m.reserve_role='diagnostic'
   group by m.id,q.correct_answer having count(r.id)<>3 or count(r.id) filter(where r.answer_match=q.correct_answer)<>0
 ) x;
 if v_bad<>0 then raise exception 'P1-02 AW9-12 functions diagnostic-rule contract failed for % items',v_bad; end if;
end $$;
commit;