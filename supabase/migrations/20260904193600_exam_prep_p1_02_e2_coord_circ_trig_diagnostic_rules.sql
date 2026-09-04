-- P1-02 E2 intentional diagnostic interpretations for Coordinate/Circular/Trig opening skills.
-- Three approved WRONG-option rules per diagnostic item; private only.

begin;
with rules(ckey,match,dcode,mtype,skill,fen,fru,fuz,nen,nru,nuz) as (values
('P1COO01-D01','A','intercept_sign_error','algebra','P1-COO-01',
 'The gradient is correct, but the intercept does not satisfy the given point. Substituting (2,−1) into y=3x+c gives c=−7, not +5.',
 'Градиент выбран верно, но свободный член не проходит через заданную точку. Подстановка (2,−1) в y=3x+c даёт c=−7, а не +5.',
 'Gradient to‘g‘ri, lekin ozod had berilgan nuqtadan o‘tmaydi. (2,−1) ni y=3x+c ga qo‘ysak c=−7, +5 emas.',
 'After finding the intercept, substitute the given point back into the line equation.',
 'После нахождения свободного члена подставьте заданную точку обратно в уравнение.',
 'Ozod hadni topgach, berilgan nuqtani tenglamaga qayta qo‘yib tekshiring.'),
('P1COO01-D01','B','gradient_lost','concept','P1-COO-01',
 'The equation must preserve the stated gradient 3. A line with coefficient 1 on x has the wrong gradient.',
 'Уравнение должно сохранять заданный градиент 3. Коэффициент 1 при x даёт другой градиент.',
 'Tenglama berilgan 3 gradientni saqlashi kerak. x oldidagi 1 koeffitsiyent noto‘g‘ri gradient beradi.',
 'Start from y=mx+c with the stated value of m before using the point.',
 'Начните с y=mx+c с заданным m, затем используйте точку.',
 'Avval y=mx+c da m ning berilgan qiymatini yozing, keyin nuqtadan foydalaning.'),
('P1COO01-D01','D','gradient_sign_error','concept','P1-COO-01',
 'The line has positive gradient 3, not −3. Reversing the sign changes the direction of the line.',
 'Градиент положительный 3, а не −3. Смена знака меняет направление прямой.',
 'Gradient musbat 3, −3 emas. Ishora o‘zgarishi chiziq yo‘nalishini o‘zgartiradi.',
 'Check that the coefficient of x equals the stated gradient before solving for c.',
 'Сначала проверьте, что коэффициент при x равен заданному градиенту.',
 'Avval x koeffitsiyenti berilgan gradientga tengligini tekshiring.'),

('P1COO02-D01','B','midpoint_x_not_averaged','method','P1-COO-02',
 'A midpoint uses the average of both x-coordinates. (−2+4)/2=1, not 2.',
 'Для середины нужно усреднить обе x-координаты: (−2+4)/2=1, а не 2.',
 'O‘rta nuqta uchun ikkala x-koordinata o‘rtachalanadi: (−2+4)/2=1, 2 emas.',
 'Use ((x₁+x₂)/2,(y₁+y₂)/2) and calculate each coordinate independently.',
 'Используйте ((x₁+x₂)/2,(y₁+y₂)/2), считая координаты отдельно.',
 '((x₁+x₂)/2,(y₁+y₂)/2) formuladan foydalanib, har koordinatani alohida hisoblang.'),
('P1COO02-D01','C','forgot_divide_by_two','method','P1-COO-02',
 'Adding coordinates gives a sum, not a midpoint. Both coordinate sums must be divided by 2.',
 'Сумма координат ещё не является серединой. Обе суммы нужно разделить на 2.',
 'Koordinatalarni qo‘shishning o‘zi o‘rta nuqta emas. Har ikki yig‘indini 2 ga bo‘lish kerak.',
 'After adding each coordinate pair, explicitly divide both sums by 2.',
 'После сложения каждой пары координат явно разделите обе суммы на 2.',
 'Har bir koordinata juftini qo‘shgach, ikkala yig‘indini ham 2 ga bo‘ling.'),
('P1COO02-D01','D','difference_used_instead_of_average','concept','P1-COO-02',
 'The midpoint is found by averaging endpoints, not by taking coordinate differences.',
 'Середина находится усреднением концов, а не разностью координат.',
 'O‘rta nuqta uchlarni o‘rtachalash bilan topiladi, koordinatalar ayirmasi bilan emas.',
 'Distinguish midpoint from displacement: midpoint averages; displacement subtracts.',
 'Разделяйте середину и перемещение: середина — среднее, перемещение — разность.',
 'O‘rta nuqta va siljishni ajrating: o‘rta nuqta — o‘rtacha, siljish — ayirma.'),

('P1COO03-D01','B','reciprocal_without_negative','concept','P1-COO-03',
 'Perpendicular gradients are negative reciprocals, not just reciprocals. The sign must change.',
 'Перпендикулярные градиенты — отрицательные обратные, а не просто обратные. Знак должен измениться.',
 'Perpendikulyar gradientlar oddiy teskari emas, manfiy teskari bo‘ladi. Ishora o‘zgarishi kerak.',
 'Use m₁m₂=−1 and solve for the unknown gradient.',
 'Используйте m₁m₂=−1 и найдите неизвестный градиент.',
 'm₁m₂=−1 dan foydalanib noma’lum gradientni toping.'),
('P1COO03-D01','C','negative_not_reciprocal','concept','P1-COO-03',
 'Changing only the sign is insufficient. A perpendicular gradient must also be the reciprocal magnitude.',
 'Недостаточно поменять только знак. Нужно также взять обратную величину.',
 'Faqat ishorani o‘zgartirish yetarli emas. Modul ham teskari qiymatga aylanishi kerak.',
 'Take the reciprocal first, then change the sign; verify the product is −1.',
 'Сначала возьмите обратную величину, затем смените знак; проверьте произведение −1.',
 'Avval teskari qiymatni oling, keyin ishorani almashtiring; ko‘paytma −1 bo‘lishini tekshiring.'),
('P1COO03-D01','D','parallel_confused_with_perpendicular','concept','P1-COO-03',
 'Keeping the same gradient gives a parallel line, not a perpendicular one.',
 'Одинаковый градиент даёт параллельную, а не перпендикулярную прямую.',
 'Bir xil gradient parallel chiziq beradi, perpendikulyar emas.',
 'Use equal gradients for parallel lines and product −1 for perpendicular lines.',
 'Для параллельных используйте равные градиенты, для перпендикулярных — произведение −1.',
 'Parallel uchun teng gradient, perpendikulyar uchun ko‘paytma −1 qoidasini ishlating.'),

('P1CIR01-D01','B','conversion_fraction_inverted','method','P1-CIR-01',
 'Degrees to radians uses π/180. Using 180/π or an incorrect ratio reverses the conversion.',
 'При переводе градусов в радианы используется π/180. Неверное отношение обращает преобразование.',
 'Gradusdan radianga o‘tishda π/180 ishlatiladi. Noto‘g‘ri nisbat o‘girishni buzadi.',
 'Write 180°=π radians first, then multiply the degree value by π/180.',
 'Сначала запишите 180°=π радиан, затем умножьте градусы на π/180.',
 'Avval 180°=π radian deb yozing, keyin gradus qiymatini π/180 ga ko‘paytiring.'),
('P1CIR01-D01','C','simplification_error','algebra','P1-CIR-01',
 '150π/180 simplifies by dividing numerator and denominator by 30, giving 5π/6, not 5π/3.',
 '150π/180 сокращается на 30 до 5π/6, а не 5π/3.',
 '150π/180 ni 30 ga qisqartirsak 5π/6 chiqadi, 5π/3 emas.',
 'Simplify the numerical fraction 150/180 carefully after applying π/180.',
 'После применения π/180 аккуратно сократите дробь 150/180.',
 'π/180 ni qo‘llagach, 150/180 kasrini ehtiyotkorlik bilan qisqartiring.'),
('P1CIR01-D01','D','degree_radian_scale_error','concept','P1-CIR-01',
 '150° is less than π radians (180°), so the answer must be less than π. 6π/5 is greater than π.',
 '150° меньше π радиан (180°), поэтому ответ должен быть меньше π. 6π/5 больше π.',
 '150° π radiandan (180°) kichik, demak javob π dan kichik bo‘lishi kerak. 6π/5 esa π dan katta.',
 'Use 180°=π as a magnitude check after converting.',
 'После перевода используйте 180°=π как проверку порядка величины.',
 'O‘girgandan keyin 180°=π ni kattalik tekshiruvi sifatida ishlating.'),

('P1TRI01-D01','B','sine_peak_location_error','graph_feature','P1-TRI-01',
 'At x=π, sin x=0. The positive maximum occurs one quarter-period earlier at π/2.',
 'При x=π имеем sin x=0. Положительный максимум достигается раньше, при π/2.',
 'x=π da sin x=0. Musbat maksimum undan oldin, π/2 da bo‘ladi.',
 'Anchor the sine graph at 0, π/2, π, 3π/2 and 2π before interpreting features.',
 'Отметьте ключевые точки 0, π/2, π, 3π/2 и 2π перед анализом графика.',
 'Grafikni tahlil qilishdan oldin 0, π/2, π, 3π/2 va 2π nuqtalarni belgilang.'),
('P1TRI01-D01','C','sine_minimum_location_error','graph_feature','P1-TRI-01',
 'At x=π, sin x=0. The minimum −1 occurs at x=3π/2.',
 'При x=π sin x=0. Минимум −1 достигается при x=3π/2.',
 'x=π da sin x=0. Minimum −1 x=3π/2 da bo‘ladi.',
 'Use the standard five key points over one 2π period.',
 'Используйте пять стандартных ключевых точек на одном периоде 2π.',
 'Bir 2π davrda beshta standart tayanch nuqtadan foydalaning.'),
('P1TRI01-D01','D','period_halved','concept','P1-TRI-01',
 'The basic sine graph repeats after 2π, not π. A shift of π changes sin x to −sin x.',
 'Базовый sin x повторяется через 2π, а не π. Сдвиг на π меняет знак функции.',
 'Asosiy sin x grafigi π emas, 2π dan keyin takrorlanadi. π ga siljish ishorani o‘zgartiradi.',
 'Compare values at x and x+π, then at x and x+2π to verify the period.',
 'Сравните значения при x и x+π, затем при x и x+2π.',
 'Davrni tekshirish uchun x va x+π, so‘ng x va x+2π dagi qiymatlarni solishtiring.')
), meta as (
  select m.id,m.content_key
  from private.exam_prep_question_content_meta m
  join private.exam_prep_content_versions cv on cv.id=m.content_version_id
  where cv.content_version='p1_e2_coordinate_circular_trig_v1' and m.reserve_role='diagnostic'
)
insert into private.exam_prep_diagnostic_rules(content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status,approved_at)
select meta.id,'drv1','mcq_option',r.match,r.dcode,r.mtype,r.skill,r.fen,r.fru,r.fuz,r.nen,r.nru,r.nuz,'approved',now()
from rules r join meta on meta.content_key=r.ckey
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

do $$ declare v_bad int; begin
  select count(*) into v_bad from (
    select m.id
    from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    left join private.exam_prep_diagnostic_rules r on r.content_meta_id=m.id and r.status='approved'
    where cv.content_version='p1_e2_coordinate_circular_trig_v1' and m.reserve_role='diagnostic'
    group by m.id having count(r.id)<>3
  ) x;
  if v_bad<>0 then raise exception 'P1-02 E2 coord/circ/trig diagnostic rule floor failed for % items',v_bad; end if;
end $$;
commit;
