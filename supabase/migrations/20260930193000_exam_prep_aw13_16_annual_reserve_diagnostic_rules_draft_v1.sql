-- AW13-16 annual-reserve diagnostic misconception rules draft v1.
-- DRAFT ONLY. Exactly three wrong-option rules per diagnostic item.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4815,4816) and lifecycle_state='draft' and reserve_role='diagnostic')<>30
  then raise exception 'aw13_16_annual_reserve_rules: diagnostic draft surface missing'; end if;
end
$preflight$;

with skill_feedback(skill_code,mistake_type,feedback_en,feedback_ru,feedback_uz,next_en,next_ru,next_uz) as (values
('P1-CIR-03','method','Your choice does not match the sector/segment area relationship.','Выбранный вариант не соответствует связи между площадями сектора, треугольника и сегмента.','Tanlangan javob sektor, uchburchak va segment yuzlari orasidagi bog‘lanishga mos emas.','Write the sector area as 1/2 r²θ. For a segment, subtract the triangle area; for an annular sector, subtract the inner sector area.','Запишите площадь сектора как 1/2 r²θ. Для сегмента вычтите площадь треугольника; для кольцевого сектора вычтите площадь внутреннего сектора.','Sektor yuzini 1/2 r²θ ko‘rinishida yozing. Segment uchun uchburchak yuzini, halqasimon sektor uchun ichki sektor yuzini ayiring.'),
('P1-TRI-02','sign','Your choice uses the wrong exact value or quadrant sign.','Выбран неверный точный тригонометрический коэффициент или знак четверти.','Tanlangan javobda aniq trigonometrik qiymat yoki chorak ishorasi noto‘g‘ri.','Find the reference angle first, recall its exact value, then apply the sign of the trigonometric function in the original quadrant.','Сначала найдите опорный угол, вспомните его точное значение и затем примените знак функции в исходной четверти.','Avval tayanch burchakni toping, uning aniq qiymatini eslang, so‘ng asl chorakdagi trigonometrik funksiya ishorasini qo‘llang.'),
('P1-TRI-03','principal_range','Your choice is outside the correct principal-value range or uses the wrong inverse function.','Выбранное значение находится вне правильного диапазона главных значений или использована неверная обратная функция.','Tanlangan qiymat to‘g‘ri bosh qiymatlar oralig‘idan tashqarida yoki noto‘g‘ri teskari funksiya ishlatilgan.','Identify the inverse function and its principal range before evaluating: sin⁻¹ uses −90° to 90°, cos⁻¹ uses 0° to 180°, and tan⁻¹ uses −90° to 90° with endpoints excluded for tangent.','Перед вычислением определите обратную функцию и её главный диапазон: для sin⁻¹ от −90° до 90°, для cos⁻¹ от 0° до 180°, для tan⁻¹ от −90° до 90° без концов.','Hisoblashdan oldin teskari funksiya va uning bosh oralig‘ini aniqlang: sin⁻¹ uchun −90° dan 90° gacha, cos⁻¹ uchun 0° dan 180° gacha, tan⁻¹ uchun −90° dan 90° gacha, chegaralarsiz.'),
('P1-TRI-04','identity','Your choice does not follow from the basic trigonometric identities.','Выбранный вариант не следует из основных тригонометрических тождеств.','Tanlangan javob asosiy trigonometrik ayniyatlardan kelib chiqmaydi.','Start from sin²x+cos²x=1 and tan x=sin x/cos x, then simplify algebraically while keeping any denominator restrictions.','Начните с sin²x+cos²x=1 и tan x=sin x/cos x, затем упростите алгебраически, сохраняя ограничения на знаменатель.','sin²x+cos²x=1 va tan x=sin x/cos x dan boshlang, so‘ng maxraj cheklovlarini saqlagan holda algebraik soddalashtiring.'),
('P1-TRI-05','solution_set','Your choice misses a valid solution or includes an angle with the wrong trigonometric sign.','В выбранном варианте пропущено допустимое решение или включён угол с неверным знаком тригонометрической функции.','Tanlangan javobda mos yechim yo‘qolgan yoki trigonometrik ishorasi noto‘g‘ri burchak kiritilgan.','Find the reference angle, use all quadrants where the required sign is correct, then use periodicity and keep only angles in the stated interval.','Найдите опорный угол, используйте все четверти с нужным знаком, затем учтите периодичность и оставьте только углы из заданного промежутка.','Tayanch burchakni toping, kerakli ishora to‘g‘ri bo‘lgan barcha choraklardan foydalaning, keyin davriylikni hisobga olib faqat berilgan oraliqdagi burchaklarni qoldiring.'),
('P1-SER-01','coefficient','Your choice uses the wrong binomial coefficient, power or sign.','Выбранный вариант использует неверный биномиальный коэффициент, степень или знак.','Tanlangan javobda binomial koeffitsiyent, daraja yoki ishora noto‘g‘ri.','Write the general term nCr·a^(n−r)·(bx)^r and match the required power of x before simplifying the coefficient.','Запишите общий член nCr·a^(n−r)·(bx)^r и сначала сопоставьте нужную степень x, затем упрощайте коэффициент.','Umumiy hadni nCr·a^(n−r)·(bx)^r ko‘rinishida yozing, avval kerakli x darajasini aniqlang, keyin koeffitsiyentni soddalashtiring.'),
('P1-SER-02','structure','Your choice does not match a constant difference or a constant ratio across consecutive terms.','Выбранный вариант не соответствует постоянной разности или постоянному отношению соседних членов.','Tanlangan javob ketma-ket hadlar orasidagi doimiy ayirma yoki doimiy nisbatga mos emas.','Check consecutive differences for an arithmetic progression and consecutive non-zero ratios for a geometric progression; the pattern must stay constant.','Проверьте последовательные разности для арифметической прогрессии и отношения соседних ненулевых членов для геометрической; закономерность должна быть постоянной.','Arifmetik progressiya uchun ketma-ket ayirmalarni, geometrik progressiya uchun ketma-ket nol bo‘lmagan nisbatlarni tekshiring; qonuniyat doimiy bo‘lishi kerak.'),
('P1-DIF-01','limit_interpretation','Your choice confuses a finite average gradient with the limiting instantaneous gradient or misreads the sign of the rate.','Выбранный вариант смешивает средний градиент на конечном промежутке с предельным мгновенным градиентом или неверно трактует знак скорости изменения.','Tanlangan javob chekli oraliqdagi o‘rtacha gradientni limitdagi oniy gradient bilan aralashtiradi yoki o‘zgarish tezligi ishorasini noto‘g‘ri talqin qiladi.','Form the difference quotient and let the interval width tend to zero. For a rate, interpret the derivative sign separately from its magnitude.','Составьте разностное отношение и устремите ширину промежутка к нулю. Для скорости изменения отдельно интерпретируйте знак производной и её величину.','Ayirmali nisbatni tuzing va oraliq kengligini nolga intiltiring. O‘zgarish tezligi uchun hosila ishorasini uning kattaligidan alohida talqin qiling.'),
('P5-PRO-05','conditional','Your choice uses the wrong restricted sample space for the conditional probability.','В выбранном варианте использовано неверное ограниченное пространство исходов для условной вероятности.','Tanlangan javobda shartli ehtimol uchun noto‘g‘ri cheklangan natijalar fazosi ishlatilgan.','In P(A|B), restrict attention to B first, then use P(A∩B)/P(B). Check carefully which event appears after the vertical bar.','В P(A|B) сначала ограничьте пространство событием B, затем используйте P(A∩B)/P(B). Внимательно смотрите, какое событие стоит после вертикальной черты.','P(A|B) da avval natijalar fazosini B hodisasi bilan cheklang, keyin P(A∩B)/P(B) dan foydalaning. Vertikal chiziqdan keyingi hodisani diqqat bilan tekshiring.'),
('P5-PRO-06','tree','Your choice does not combine sequential branch probabilities correctly.','Выбранный вариант неверно объединяет вероятности последовательных ветвей.','Tanlangan javob ketma-ket shoxlar ehtimollarini noto‘g‘ri birlashtiradi.','Multiply probabilities along one complete route, update branch probabilities after a without-replacement draw, and add mutually exclusive routes for the same final event.','Перемножайте вероятности вдоль полного пути, обновляйте вероятности после выбора без возвращения и складывайте взаимоисключающие пути одного итогового события.','Bitta to‘liq yo‘l bo‘ylab ehtimollarni ko‘paytiring, qaytarmasdan tanlashdan keyin shox ehtimollarini yangilang va bir xil yakuniy hodisaga olib keluvchi o‘zaro istisno yo‘llarni qo‘shing.'),
('P5-DRV-01','distribution','Your choice does not satisfy the validity conditions for a discrete probability distribution.','Выбранный вариант не удовлетворяет условиям корректности дискретного распределения вероятностей.','Tanlangan javob diskret ehtimollar taqsimotining to‘g‘rilik shartlariga mos emas.','Check that every probability is between 0 and 1 and that the probabilities of all possible values sum exactly to 1.','Проверьте, что каждая вероятность лежит от 0 до 1 и сумма вероятностей всех возможных значений точно равна 1.','Har bir ehtimol 0 va 1 orasida ekanini va barcha mumkin qiymatlar ehtimollari yig‘indisi aynan 1 ekanini tekshiring.'),
('P5-DRV-02','expectation','Your choice does not use the probability-weighted average correctly.','В выбранном варианте неверно вычислено математическое ожидание как взвешенное среднее.','Tanlangan javobda kutiladigan qiymat ehtimollar bilan og‘irliklangan o‘rtacha sifatida noto‘g‘ri hisoblangan.','Multiply each possible value by its probability and add all products, including the sign of any loss or negative value.','Умножьте каждое возможное значение на его вероятность и сложите все произведения, сохраняя знак потерь или отрицательных значений.','Har bir mumkin qiymatni uning ehtimoliga ko‘paytirib, barcha ko‘paytmalarni qo‘shing; zarar yoki manfiy qiymat ishorasini saqlang.'),
('P5-DRV-03','variance','Your choice confuses E(X²), [E(X)]², variance or standard deviation.','Выбранный вариант смешивает E(X²), [E(X)]², дисперсию или стандартное отклонение.','Tanlangan javob E(X²), [E(X)]², dispersiya yoki standart og‘ishni aralashtiradi.','Use Var(X)=E(X²)−[E(X)]². Take the square root only after finding the variance when standard deviation is required.','Используйте Var(X)=E(X²)−[E(X)]². Извлекайте квадратный корень только после нахождения дисперсии, если требуется стандартное отклонение.','Var(X)=E(X²)−[E(X)]² dan foydalaning. Standart og‘ish kerak bo‘lsa, avval dispersiyani topib, keyin kvadrat ildiz oling.'),
('P5-BIN-01','model','Your choice does not satisfy all conditions of an exact binomial model.','Выбранный вариант не удовлетворяет всем условиям точной биномиальной модели.','Tanlangan javob aniq binomial modelning barcha shartlariga mos emas.','Check four conditions explicitly: fixed n, two outcomes on each trial, constant success probability p, and independent trials.','Явно проверьте четыре условия: фиксированное n, два исхода в каждом испытании, постоянная вероятность успеха p и независимость испытаний.','To‘rtta shartni alohida tekshiring: belgilangan n, har sinovda ikki natija, o‘zgarmas muvaffaqiyat ehtimoli p va mustaqil sinovlar.'),
('P5-GEO-01','model','Your choice does not match a waiting-time-to-first-success model with constant probability.','Выбранный вариант не соответствует модели ожидания первого успеха с постоянной вероятностью.','Tanlangan javob o‘zgarmas ehtimolli birinchi muvaffaqiyatgacha kutish modeliga mos emas.','Check that trials are independent, p stays constant, and X records the trial number on which the first success occurs.','Проверьте, что испытания независимы, p постоянно, а X показывает номер испытания, на котором происходит первый успех.','Sinovlar mustaqil, p o‘zgarmas va X birinchi muvaffaqiyat sodir bo‘ladigan sinov raqamini ko‘rsatishini tekshiring.')
), letters(answer_match) as (values ('A'),('B'),('C'),('D'))
insert into private.exam_prep_diagnostic_rules(
  content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,
  feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status
)
select m.id,'aw_reserve_v1','mcq_option',l.answer_match,
       replace(lower(m.content_key),'-','_')||'_wrong_'||lower(l.answer_match),
       sf.mistake_type,m.primary_skill_code,
       sf.feedback_en,sf.feedback_ru,sf.feedback_uz,sf.next_en,sf.next_ru,sf.next_uz,'draft'
from private.exam_prep_question_content_meta m
join public.questions qn on qn.id=m.question_id
join skill_feedback sf on sf.skill_code=m.primary_skill_code
cross join letters l
where m.content_version_id in (4815,4816)
  and m.reserve_role='diagnostic'
  and qn.qtype='mcq'
  and l.answer_match<>qn.correct_answer
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4815,4816) and r.rule_version='aw_reserve_v1')<>90
  then raise exception 'aw13_16_annual_reserve_rules: expected 90 draft rules'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions qn on qn.id=m.question_id
  where m.content_version_id in (4815,4816)
    and m.reserve_role='diagnostic'
    and (
      qn.qtype<>'mcq'
      or (select count(*) from private.exam_prep_diagnostic_rules r
          where r.content_meta_id=m.id and r.rule_version='aw_reserve_v1'
            and r.status='draft' and r.answer_kind='mcq_option'
            and r.answer_match<>qn.correct_answer
            and r.weak_skill_code=m.primary_skill_code
            and nullif(btrim(r.feedback_en),'') is not null
            and nullif(btrim(r.feedback_ru),'') is not null
            and nullif(btrim(r.feedback_uz),'') is not null
            and nullif(btrim(r.next_action_en),'') is not null
            and nullif(btrim(r.next_action_ru),'') is not null
            and nullif(btrim(r.next_action_uz),'') is not null)<>3
    );
  if v_bad<>0 then raise exception 'aw13_16_annual_reserve_rules: invalid diagnostic rule rows=%',v_bad; end if;
end
$postcheck$;

commit;
