-- P1-02 intentional diagnostic interpretations for P1-QUA-04/05/06.
-- Three approved wrong-option rules per diagnostic item; private only.

begin;

with rules(cvkey,ckey,match,dcode,mtype,skill,fen,fru,fuz,nen,nru,nuz) as (values
('p1_aw09_12_quadratics_v1','P1QUA04-D01','B','quadratic_sign_region_reversed','concept','P1-QUA-04',
'The quadratic opens upward, so it is negative between the roots and positive outside them. Option B selects the negative region instead of the required positive region.',
'Парабола направлена вверх, поэтому выражение отрицательно между корнями и положительно вне их. Вариант B выбирает область отрицательных значений вместо требуемой положительной.',
'Parabola yuqoriga ochiladi, shuning uchun ifoda ildizlar orasida manfiy, tashqarida musbat. B varianti kerakli musbat soha o‘rniga manfiy sohani tanlaydi.',
'Factor the quadratic, mark the roots 2 and 3, then test one point in each interval.',
'Разложите квадратный трёхчлен, отметьте корни 2 и 3 и проверьте по одной точке на каждом промежутке.',
'Kvadrat ifodani ko‘paytuvchilarga ajrating, 2 va 3 ildizlarini belgilang va har bir oraliqdan bittadan nuqtani tekshiring.'),
('p1_aw09_12_quadratics_v1','P1QUA04-D01','C','strict_endpoint_inclusion','method','P1-QUA-04',
'At x = 2 or x = 3 the expression equals 0, not a positive number. A strict > inequality must exclude both roots.',
'При x = 2 или x = 3 выражение равно 0, а не положительному числу. Строгое неравенство > должно исключать оба корня.',
'x = 2 yoki x = 3 da ifoda 0 ga teng, musbat emas. Qat’iy > tengsizlik ikkala ildizni ham chiqarib tashlaydi.',
'After finding the sign regions, decide endpoint inclusion from the inequality symbol itself.',
'После определения знаков отдельно решите вопрос о включении границ по знаку неравенства.',
'Ishora oraliqlarini topgach, chegara nuqtalari kirishini tengsizlik belgisiga qarab alohida tekshiring.'),
('p1_aw09_12_quadratics_v1','P1QUA04-D01','D','union_intersection_confusion','method','P1-QUA-04',
'The positive solution consists of two separate intervals. They are joined by OR; requiring x < 2 AND x > 3 would give no real number.',
'Положительное решение состоит из двух отдельных промежутков. Они объединяются словом ИЛИ; условие x < 2 И x > 3 не выполняет ни одно действительное число.',
'Musbat yechim ikkita alohida oraliqdan iborat. Ular YOKI bilan birlashtiriladi; x < 2 VA x > 3 shartini hech qanday haqiqiy son bajarmaydi.',
'Write disjoint solution intervals as a union, not as simultaneous inequalities.',
'Записывайте раздельные промежутки как объединение, а не как одновременные условия.',
'Ajralgan yechim oraliqlarini birlashma sifatida yozing, bir vaqtdagi shartlar sifatida emas.'),

('p1_aw09_12_quadratics_v1','P1QUA05-D01','B','discriminant_constant_sign','method','P1-QUA-05',
'After equating the line and curve the equation is x² − 4x + 2 = 0. Its discriminant is 16 − 8 = 8, not 24; using the wrong sign on the constant produces √6.',
'После приравнивания прямой и кривой получается x² − 4x + 2 = 0. Дискриминант равен 16 − 8 = 8, а не 24; неверный знак свободного члена приводит к √6.',
'To‘g‘ri chiziq va egri chiziqni tenglashtirganda x² − 4x + 2 = 0 chiqadi. Diskriminant 16 − 8 = 8, 24 emas; doimiy had ishorasidagi xato √6 ga olib keladi.',
'First simplify to ax² + bx + c = 0, then substitute a, b and c with their signs into b² − 4ac.',
'Сначала приведите уравнение к ax² + bx + c = 0, затем подставляйте a, b и c вместе с их знаками в b² − 4ac.',
'Avval tenglamani ax² + bx + c = 0 ko‘rinishiga keltiring, so‘ng a, b va c ni ishoralari bilan b² − 4ac ga qo‘ying.'),
('p1_aw09_12_quadratics_v1','P1QUA05-D01','C','quadratic_formula_b_sign','method','P1-QUA-05',
'For x² − 4x + 2 = 0, b = −4, so −b = +4. Using −4 in the numerator reflects both roots to the wrong side of the axis.',
'Для x² − 4x + 2 = 0 коэффициент b = −4, поэтому −b = +4. Использование −4 в числителе переносит оба корня на неверную сторону оси.',
'x² − 4x + 2 = 0 uchun b = −4, demak −b = +4. Suratga −4 qo‘yish ikkala ildizni o‘qning noto‘g‘ri tomoniga ko‘chiradi.',
'Write a = 1, b = −4, c = 2 explicitly before using the quadratic formula.',
'Перед применением формулы явно запишите a = 1, b = −4, c = 2.',
'Kvadrat formula ishlatishdan oldin a = 1, b = −4, c = 2 ni aniq yozib oling.'),
('p1_aw09_12_quadratics_v1','P1QUA05-D01','D','integer_factor_guess','concept','P1-QUA-05',
'The intersection equation x² − 4x + 2 = 0 does not factor as (x − 1)(x − 3): that product has constant 3, not 2.',
'Уравнение пересечения x² − 4x + 2 = 0 нельзя разложить как (x − 1)(x − 3): это произведение имеет свободный член 3, а не 2.',
'Kesishish tenglamasi x² − 4x + 2 = 0 ni (x − 1)(x − 3) deb ajratib bo‘lmaydi: bu ko‘paytmaning doimiy hadi 3, 2 emas.',
'Check a proposed factorisation by expanding it; if no integer factors fit, use the quadratic formula.',
'Проверяйте предполагаемое разложение раскрытием скобок; если целые множители не подходят, используйте формулу корней.',
'Taklif qilingan ko‘paytuvchilarni qayta ochib tekshiring; butun ko‘paytuvchilar mos kelmasa, kvadrat formuladan foydalaning.'),

('p1_aw09_12_quadratics_v1','P1QUA06-D01','B','substitution_backsolve_square','method','P1-QUA-06',
'The substitution gives u = x² with u = 1 or 4. You must solve x² = u; the values ±4 are not obtained from x² = 4.',
'Подстановка даёт u = x² и u = 1 или 4. Затем нужно решить x² = u; значения ±4 не следуют из x² = 4.',
'Almashtirish u = x² va u = 1 yoki 4 ni beradi. Keyin x² = u ni yechish kerak; x² = 4 dan ±4 emas, ±2 chiqadi.',
'After solving the quadratic in u, return to the definition u = x² and solve each resulting equation separately.',
'После решения квадратного уравнения относительно u вернитесь к определению u = x² и решите каждое полученное уравнение отдельно.',
'u bo‘yicha kvadrat tenglamani yechgach, u = x² ta’rifiga qayting va har bir hosil bo‘lgan tenglamani alohida yeching.'),
('p1_aw09_12_quadratics_v1','P1QUA06-D01','C','substitution_not_reversed','method','P1-QUA-06',
'The numbers 1 and 4 are values of u = x², not final values of x. The substitution must be reversed before reporting solutions.',
'Числа 1 и 4 — это значения u = x², а не окончательные значения x. Перед записью ответа нужно выполнить обратную подстановку.',
'1 va 4 sonlari x ning yakuniy qiymatlari emas, u = x² ning qiymatlari. Javob yozishdan oldin almashtirishni orqaga qaytarish kerak.',
'Label the temporary variable clearly and do not stop until every answer is expressed in x.',
'Явно обозначайте временную переменную и не заканчивайте решение, пока все ответы не записаны через x.',
'Vaqtinchalik o‘zgaruvchini aniq belgilang va barcha javoblar x orqali yozilmaguncha yechimni tugatmang.'),
('p1_aw09_12_quadratics_v1','P1QUA06-D01','D','one_substitution_branch_lost','method','P1-QUA-06',
'The quadratic in u has two valid roots, u = 1 and u = 4. Keeping only u = 4 loses the solutions x = ±1.',
'Квадратное уравнение относительно u имеет два допустимых корня: u = 1 и u = 4. Если оставить только u = 4, теряются решения x = ±1.',
'u bo‘yicha kvadrat tenglamaning ikkita yaroqli ildizi bor: u = 1 va u = 4. Faqat u = 4 ni qoldirish x = ±1 yechimlarini yo‘qotadi.',
'Carry both roots of the transformed quadratic into the back-substitution step, then collect all distinct real x-values.',
'Перенесите оба корня преобразованного квадратного уравнения на этап обратной подстановки и затем соберите все различные действительные значения x.',
'O‘zgartirilgan kvadrat tenglamaning ikkala ildizini ham teskari almashtirish bosqichiga olib o‘ting, so‘ng barcha turli haqiqiy x qiymatlarini yig‘ing.')
), meta as (
  select m.id,m.content_key,cv.content_version
  from private.exam_prep_question_content_meta m
  join private.exam_prep_content_versions cv on cv.id=m.content_version_id
  where cv.content_version='p1_aw09_12_quadratics_v1' and m.reserve_role='diagnostic'
)
insert into private.exam_prep_diagnostic_rules(
  content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,
  feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status,approved_at
)
select meta.id,'drv1','mcq_option',r.match,r.dcode,r.mtype,r.skill,r.fen,r.fru,r.fuz,r.nen,r.nru,r.nuz,'approved',now()
from rules r join meta on meta.content_version=r.cvkey and meta.content_key=r.ckey
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

do $$ declare v_bad int; begin
  select count(*) into v_bad from (
    select m.id
    from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    join public.questions q on q.id=m.question_id
    left join private.exam_prep_diagnostic_rules r
      on r.content_meta_id=m.id and r.status='approved' and r.answer_kind='mcq_option'
    where cv.content_version='p1_aw09_12_quadratics_v1' and m.reserve_role='diagnostic'
    group by m.id,q.correct_answer
    having count(r.id)<>3 or count(r.id) filter(where r.answer_match=q.correct_answer)<>0
  ) x;
  if v_bad<>0 then raise exception 'P1-02 AW9-12 quadratics diagnostic-rule contract failed for % items',v_bad; end if;
end $$;

commit;