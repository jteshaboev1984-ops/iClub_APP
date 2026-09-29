-- Draft diagnostic misconception rules for P1 AW1-4 annual-reserve variants.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id=4803
        and reserve_role='diagnostic'
        and lifecycle_state='draft'
        and diagnostic_rule_status='pending')<>10 then
    raise exception 'aw01_04_annual_reserve_p1_rules: expected 10 draft diagnostics';
  end if;
end
$preflight$;

with rules(content_key,answer_match,distractor_code,mistake_type,weak_skill_code,
           feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz) as (values
('P1QUA01-D02','B','constant_not_compensated_after_factoring','method','P1-QUA-01','After factoring out 3, the square adds 9 inside the bracket, so the outside constant must also be adjusted.','После вынесения 3 полный квадрат добавляет 9 внутри скобок, поэтому свободный член снаружи нужно скорректировать.','3 ni tashqariga chiqargandan keyin to‘liq kvadrat qavs ichida 9 qo‘shadi, shuning uchun tashqi doimiy had ham tuzatilishi kerak.','Expand the completed-square form and compare all three coefficients.','Раскройте форму полного квадрата и сравните все три коэффициента.','To‘liq kvadrat ko‘rinishini ochib, uchala koeffitsiyentni solishtiring.'),
('P1QUA01-D02','C','completed_square_sign_error','algebra','P1-QUA-01','(x+3)² produces +6x inside the bracket, but the required middle term after factoring is −6x.','(x+3)² даёт +6x внутри скобок, тогда как после вынесения коэффициента нужен член −6x.','(x+3)² qavs ichida +6x beradi, lekin koeffitsiyent chiqarilgandan keyin −6x kerak.','Check the sign of the middle term by expanding (x±a)².','Проверьте знак среднего члена, раскрыв (x±a)².','(x±a)² ni ochib, o‘rta had ishorasini tekshiring.'),
('P1QUA01-D02','D','completed_square_shift_not_halved','method','P1-QUA-01','The shift comes from half of −6 inside the bracket, so it is 3, not 6.','Сдвиг берётся из половины коэффициента −6 внутри скобок, поэтому это 3, а не 6.','Siljish qavs ichidagi −6 koeffitsiyentning yarmidan olinadi, ya’ni 3, 6 emas.','First factor the leading coefficient, then halve the new x-coefficient.','Сначала вынесите старший коэффициент, затем разделите новый коэффициент при x пополам.','Avval bosh koeffitsiyentni tashqariga chiqaring, keyin yangi x koeffitsiyentini yarmiga bo‘ling.'),
('P1QUA01-D03','A','vertex_x_sign_error','algebra','P1-QUA-01','From −2(x+2)²+9, the square is zero at x=−2, not x=2.','В форме −2(x+2)²+9 квадрат равен нулю при x=−2, а не при x=2.','−2(x+2)²+9 ko‘rinishda kvadrat x=−2 da nol bo‘ladi, x=2 da emas.','Read the vertex x-coordinate with the opposite sign from (x−h)².','В форме (x−h)² координата вершины по x равна h; учитывайте знак.','(x−h)² ko‘rinishda cho‘qqining x koordinatasi h bo‘ladi; ishoraga e’tibor bering.'),
('P1QUA01-D03','B','vertex_value_and_shape_error','concept','P1-QUA-01','The completed-square form is −2(x+2)²+9, so the vertex y-value is 9 and the graph opens downward.','Форма полного квадрата равна −2(x+2)²+9, поэтому y-координата вершины 9, а ветви направлены вниз.','To‘liq kvadrat ko‘rinishi −2(x+2)²+9, demak cho‘qqining y qiymati 9 va parabola pastga ochiladi.','Use the sign of the squared-term coefficient to decide maximum versus minimum.','По знаку коэффициента при квадрате определите, является вершина максимумом или минимумом.','Kvadrat had koeffitsiyenti ishorasidan maksimum yoki minimum ekanini aniqlang.'),
('P1QUA01-D03','D','vertex_from_raw_coefficient','method','P1-QUA-01','The raw x-coefficient −8 is not the vertex coordinate. Completing the square gives x=−2.','Коэффициент −8 при x сам по себе не является координатой вершины. Выделение полного квадрата даёт x=−2.','x ning −8 koeffitsiyenti cho‘qqi koordinatasi emas. To‘liq kvadrat ajratish x=−2 ni beradi.','Complete the square before reading the vertex.','Сначала выделите полный квадрат, затем считайте координаты вершины.','Avval to‘liq kvadrat ajrating, keyin cho‘qqi koordinatalarini o‘qing.'),
('P1QUA02-D02','A','negative_discriminant_as_two_roots','concept','P1-QUA-02','The discriminant is −4. A negative discriminant gives no real roots, not two real roots.','Дискриминант равен −4. Отрицательный дискриминант означает отсутствие действительных корней, а не два корня.','Diskriminant −4. Manfiy diskriminant ikkita emas, umuman haqiqiy ildiz yo‘qligini bildiradi.','Relate Δ>0, Δ=0 and Δ<0 to the three real-root cases.','Свяжите случаи Δ>0, Δ=0 и Δ<0 с количеством действительных корней.','Δ>0, Δ=0 va Δ<0 holatlarini haqiqiy ildizlar soni bilan bog‘lang.'),
('P1QUA02-D02','C','negative_discriminant_as_repeated_root','concept','P1-QUA-02','A repeated real root requires Δ=0, but here Δ=−4.','Повторяющийся действительный корень требует Δ=0, но здесь Δ=−4.','Takroriy haqiqiy ildiz uchun Δ=0 bo‘lishi kerak, bu yerda esa Δ=−4.','Calculate the discriminant first, then classify its sign.','Сначала вычислите дискриминант, затем определите знак.','Avval diskriminantni hisoblang, keyin uning ishorasini tasniflang.'),
('P1QUA02-D02','D','discriminant_not_evaluated','method','P1-QUA-02','The coefficients are known, so the root type can be determined directly from b²−4ac.','Все коэффициенты известны, поэтому тип корней можно определить прямо по b²−4ac.','Barcha koeffitsiyentlar ma’lum, shuning uchun ildiz turini b²−4ac orqali bevosita aniqlash mumkin.','Write a=1, b=6, c=10 and evaluate Δ.','Запишите a=1, b=6, c=10 и вычислите Δ.','a=1, b=6, c=10 ni yozib, Δ ni hisoblang.'),
('P1QUA02-D03','A','zeroed_linear_coefficient_only','method','P1-QUA-02','Setting p+1=0 does not make the discriminant zero; it ignores the constant term p.','Условие p+1=0 само по себе не делает дискриминант нулём; оно игнорирует свободный член p.','Faqat p+1=0 deb olish diskriminantni nol qilmaydi; bu p doimiy hadini e’tiborsiz qoldiradi.','Form the full discriminant (p+1)²−4p before solving.','Составьте полный дискриминант (p+1)²−4p и только потом решайте.','Avval to‘liq diskriminant (p+1)²−4p ni tuzing, keyin yeching.'),
('P1QUA02-D03','B','zero_constant_assumed_repeated','concept','P1-QUA-02','With p=0 the equation is x(x+1)=0, which has two distinct roots 0 and −1.','При p=0 уравнение x(x+1)=0 имеет два различных корня 0 и −1.','p=0 da tenglama x(x+1)=0 bo‘lib, 0 va −1 kabi ikkita turli ildizga ega.','Test a proposed parameter value by checking the discriminant or roots.','Проверяйте предложенное значение параметра через дискриминант или сами корни.','Taklif qilingan parametrni diskriminant yoki ildizlar orqali tekshiring.'),
('P1QUA02-D03','C','parameter_square_expansion_error','algebra','P1-QUA-02','(p+1)²−4p simplifies to (p−1)², which is not zero at p=2.','(p+1)²−4p упрощается до (p−1)², которое не равно нулю при p=2.','(p+1)²−4p ifoda (p−1)² ga soddalashadi va p=2 da nol emas.','Expand carefully, collect the p-terms, then factor the resulting square.','Аккуратно раскройте скобки, соберите члены с p и разложите полученный квадрат.','Qavslarni ehtiyotkor oching, p hadlarini yig‘ing va hosil bo‘lgan kvadratni ajrating.'),
('P1QUA03-D02','A','quadratic_formula_b_sign_error','algebra','P1-QUA-03','The quadratic formula starts with −b. Here b=2, so the centre of the two roots is −1, not +1.','Формула корней начинается с −b. Здесь b=2, поэтому центр двух корней равен −1, а не +1.','Kvadrat tenglama formulasi −b bilan boshlanadi. Bu yerda b=2, shuning uchun ildizlar markazi +1 emas, −1.','Write a, b and c before substituting into the quadratic formula.','Перед подстановкой в формулу выпишите a, b и c.','Formulaga qo‘yishdan oldin a, b va c ni yozib oling.'),
('P1QUA03-D02','B','radical_simplification_error','algebra','P1-QUA-03','√32=4√2, so dividing by 2 gives 2√2, not √2.','√32=4√2, поэтому после деления на 2 получается 2√2, а не √2.','√32=4√2, 2 ga bo‘lganda 2√2 chiqadi, √2 emas.','Simplify the square root before dividing the numerator by 2a.','Сначала упростите корень, затем разделите числитель на 2a.','Avval ildizni soddalashtiring, keyin suratni 2a ga bo‘ling.'),
('P1QUA03-D02','D','formula_sign_and_scale_error','method','P1-QUA-03','This form has both the wrong centre and an unsimplified scale; it does not satisfy sum of roots −2.','У этого ответа неверны и центр корней, и масштаб радикала; сумма корней не равна −2.','Bu javobda ildizlar markazi ham, ildizli had masshtabi ham noto‘g‘ri; ildizlar yig‘indisi −2 emas.','Check the final roots using sum = −b/a and product = c/a.','Проверьте корни по сумме −b/a и произведению c/a.','Yakuniy ildizlarni yig‘indi −b/a va ko‘paytma c/a orqali tekshiring.'),
('P1QUA03-D03','A','completing_square_root_sign_error','algebra','P1-QUA-03','Completing the square gives (x+5)²=8, so the centre is x=−5, not x=5.','После выделения полного квадрата получаем (x+5)²=8, поэтому центр корней x=−5, а не 5.','To‘liq kvadrat ajratilganda (x+5)²=8, demak ildizlar markazi x=−5, 5 emas.','After taking square roots, solve x+5=±√8.','После извлечения корня решите x+5=±√8.','Ildiz olgandan keyin x+5=±√8 ni yeching.'),
('P1QUA03-D03','B','sqrt8_simplification_error','algebra','P1-QUA-03','√8=2√2, not √2.','√8=2√2, а не √2.','√8=2√2, √2 emas.','Factor 8 as 4·2 before simplifying the radical.','Представьте 8 как 4·2 перед упрощением корня.','Ildizni soddalashtirishdan oldin 8 ni 4·2 ko‘rinishda yozing.'),
('P1QUA03-D03','C','completed_square_centre_sign_error','algebra','P1-QUA-03','The equation (x+5)²=8 gives x=−5±√8, so the sign of 5 must be negative.','Из (x+5)²=8 следует x=−5±√8, поэтому знак перед 5 должен быть отрицательным.','(x+5)²=8 dan x=−5±√8 kelib chiqadi, demak 5 oldidagi ishora manfiy bo‘lishi kerak.','Isolate x after taking the square root instead of reading the bracket sign directly.','После извлечения корня выразите x отдельно, а не переносите знак из скобки напрямую.','Ildiz olgandan keyin x ni alohida ajrating; qavs ishorasini to‘g‘ridan-to‘g‘ri ko‘chirmang.'),
('P1FUN01-D02','B','composition_order_confusion','concept','P1-FUN-01','(f∘g)(x) means f(g(x)), not g(f(x)). Squaring 2x+1 reverses the order.','(f∘g)(x) означает f(g(x)), а не g(f(x)). Возведение 2x+1 в квадрат меняет порядок.','(f∘g)(x) f(g(x)) degani, g(f(x)) emas. 2x+1 ni kvadratga oshirish tartibni almashtiradi.','Write the inside function first: g(x)=x², then substitute it into f.','Сначала запишите внутреннюю функцию g(x)=x², затем подставьте её в f.','Avval ichki funksiya g(x)=x² ni yozing, keyin uni f ga qo‘ying.'),
('P1FUN01-D02','C','composition_as_product_or_expansion','concept','P1-FUN-01','Composition is substitution, not multiplying or expanding the two formulas together.','Композиция — это подстановка, а не умножение или совместное раскрытие двух формул.','Kompozitsiya — bu o‘rniga qo‘yish, ikki formulani ko‘paytirish yoki birga ochish emas.','Replace the input of f by the whole expression g(x).','Замените аргумент функции f целым выражением g(x).','f funksiyasining argumenti o‘rniga butun g(x) ifodasini qo‘ying.'),
('P1FUN01-D02','D','composition_values_added','method','P1-FUN-01','Adding the constants from the two rules does not compute f(g(x)).','Сложение частей двух правил не вычисляет f(g(x)).','Ikki qoidadagi qismlarni qo‘shish f(g(x)) ni hisoblamaydi.','Evaluate the inner function, then apply the outer function to that result.','Вычислите внутреннюю функцию, затем примените внешнюю функцию к полученному результату.','Avval ichki funksiyani hisoblang, keyin natijaga tashqi funksiyani qo‘llang.'),
('P1FUN01-D03','A','function_definition_confused_with_one_one','concept','P1-FUN-01','Every input having one output defines a function, but it does not make the function one-one.','То, что каждому входу соответствует один выход, определяет функцию, но не делает её взаимно однозначной.','Har bir kirishga bitta chiqish mos kelishi funksiyani belgilaydi, lekin uni bir-biriga bir qiymatli qilmaydi.','For one-one, also check that different inputs cannot produce the same output.','Для взаимной однозначности дополнительно проверьте, что разные входы не дают одинаковый выход.','Bir-biriga bir qiymatlilik uchun turli kirishlar bir xil chiqish bermasligini ham tekshiring.'),
('P1FUN01-D03','B','inverse_ignores_one_one_domain','concept','P1-FUN-01','√x reverses only the non-negative branch. On all real inputs, x² is not one-one, so there is no inverse function on the full domain.','√x обращает только неотрицательную ветвь. На всех действительных x функция x² не взаимно однозначна, поэтому на всей области обратной функции нет.','√x faqat manfiy bo‘lmagan tarmoqni qaytaradi. Barcha haqiqiy x larda x² bir-biriga bir qiymatli emas, shuning uchun to‘liq sohada teskari funksiya yo‘q.','Check one-one before writing an inverse; restrict the domain if needed.','Перед нахождением обратной функции проверьте взаимную однозначность; при необходимости ограничьте область.','Teskari funksiyani yozishdan oldin bir-biriga bir qiymatlilikni tekshiring; kerak bo‘lsa sohani cheklang.'),
('P1FUN01-D03','D','range_of_square_all_reals','concept','P1-FUN-01','x² is never negative, so its range on the real domain is [0,∞), not all real numbers.','x² не бывает отрицательным, поэтому область значений на действительной области равна [0,∞), а не всем действительным числам.','x² manfiy bo‘lmaydi, shuning uchun haqiqiy sohada qiymatlar sohasi [0,∞), barcha haqiqiy sonlar emas.','Separate domain from range and inspect possible output values.','Разделяйте область определения и область значений; определите возможные выходы.','Aniqlanish sohasi va qiymatlar sohasini ajrating; mumkin bo‘lgan chiqish qiymatlarini tekshiring.'),
('P1FUN02-D02','A','restricted_range_wrong_endpoint_value','method','P1-FUN-02','At x=7, f(7)=11, so 9 cannot be the maximum on the stated domain.','При x=7 получаем f(7)=11, поэтому 9 не может быть максимумом на заданной области.','x=7 da f(7)=11, shuning uchun 9 berilgan sohada maksimum bo‘la olmaydi.','Evaluate the vertex and both relevant endpoints of the restricted domain.','Проверьте вершину и нужные концы ограниченной области.','Cheklangan sohadagi cho‘qqi va tegishli chekka nuqtalarni hisoblang.'),
('P1FUN02-D02','B','vertical_shift_ignored','method','P1-FUN-02','The function is (x−4)²+2, so its minimum at x=4 is 2, not 0.','Функция равна (x−4)²+2, поэтому минимум при x=4 равен 2, а не 0.','Funksiya (x−4)²+2, shuning uchun x=4 dagi minimum 2, 0 emas.','Include the vertical shift after finding the minimum of the squared term.','Учитывайте вертикальный сдвиг после нахождения минимума квадратного члена.','Kvadrat had minimumini topgandan keyin vertikal siljishni ham hisobga oling.'),
('P1FUN02-D02','D','domain_copied_as_range','concept','P1-FUN-02','The interval 4≤x≤7 is the domain. The range must be found from the output values f(x).','Интервал 4≤x≤7 — это область определения. Область значений нужно получить из значений f(x).','4≤x≤7 — aniqlanish sohasi. Qiymatlar sohasi f(x) chiqish qiymatlaridan topiladi.','Map the allowed x-values through the function and identify output extrema.','Пропустите допустимые x через функцию и найдите минимальный и максимальный выход.','Ruxsat etilgan x qiymatlarini funksiya orqali o‘tkazib, chiqish minimumi va maksimumini toping.'),
('P1FUN02-D03','B','range_endpoint_inclusivity_reversed','representation','P1-FUN-02','The endpoint x=4 is included, so f=−5 is included. The endpoint x=−1 is excluded, so f=5 is excluded.','Точка x=4 включена, поэтому f=−5 включено. Точка x=−1 исключена, поэтому f=5 исключено.','x=4 kiritilgan, shuning uchun f=−5 ham kiradi. x=−1 kiritilmagan, shuning uchun f=5 kirmaydi.','Carry open and closed endpoint information through the decreasing function.','Перенесите информацию об открытых и закрытых концах через убывающую функцию.','Ochiq va yopiq chekka nuqtalar ma’lumotini kamayuvchi funksiya orqali to‘g‘ri o‘tkazing.'),
('P1FUN02-D03','C','open_endpoint_treated_closed','representation','P1-FUN-02','Because x=−1 is not allowed, the limiting output 5 is not part of the range.','Поскольку x=−1 не входит в область, предельное значение 5 не входит в область значений.','x=−1 ruxsat etilmagani uchun 5 chegaraviy chiqish qiymati qiymatlar sohasiga kirmaydi.','Check whether each domain endpoint is included before closing the corresponding range endpoint.','Перед включением границы области значений проверьте, включена ли соответствующая граница области определения.','Qiymatlar sohasi chegarasini yopishdan oldin mos aniqlanish sohasi chegarasi kirishini tekshiring.'),
('P1FUN02-D03','D','domain_used_as_range','concept','P1-FUN-02','−1<x≤4 describes input values, not output values.','−1<x≤4 описывает входные значения, а не значения функции.','−1<x≤4 kirish qiymatlarini bildiradi, chiqish qiymatlarini emas.','Evaluate f at the domain boundaries and use monotonicity to form the range.','Вычислите f на границах области и используйте монотонность для нахождения диапазона.','Soha chegaralarida f ni hisoblang va qiymatlar sohasini topish uchun monotonlikdan foydalaning.')
)
insert into private.exam_prep_diagnostic_rules(
  content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,
  feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status
)
select
  m.id,'aw_reserve_v1','mcq_option',r.answer_match,r.distractor_code,r.mistake_type,r.weak_skill_code,
  r.feedback_en,r.feedback_ru,r.feedback_uz,r.next_action_en,r.next_action_ru,r.next_action_uz,'draft'
from rules r
join private.exam_prep_question_content_meta m
  on m.content_version_id=4803
 and m.content_key=r.content_key
 and m.primary_skill_code=r.weak_skill_code
 and m.reserve_role='diagnostic'
join public.questions q on q.id=m.question_id
where r.answer_match<>q.correct_answer
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select count(*)
      from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id=4803 and r.rule_version='aw_reserve_v1')<>30 then
    raise exception 'aw01_04_annual_reserve_p1_rules: expected 30 draft rules';
  end if;

  select count(*) into v_bad
  from private.exam_prep_diagnostic_rules r
  join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
  join public.questions q on q.id=m.question_id
  where m.content_version_id=4803
    and r.rule_version='aw_reserve_v1'
    and (
      r.status<>'draft'
      or r.answer_kind<>'mcq_option'
      or r.answer_match=q.correct_answer
      or r.weak_skill_code<>m.primary_skill_code
      or nullif(btrim(r.feedback_en),'') is null
      or nullif(btrim(r.feedback_ru),'') is null
      or nullif(btrim(r.feedback_uz),'') is null
      or nullif(btrim(r.next_action_en),'') is null
      or nullif(btrim(r.next_action_ru),'') is null
      or nullif(btrim(r.next_action_uz),'') is null
    );
  if v_bad<>0 then
    raise exception 'aw01_04_annual_reserve_p1_rules: invalid rule rows=%',v_bad;
  end if;
end
$postcheck$;

commit;
