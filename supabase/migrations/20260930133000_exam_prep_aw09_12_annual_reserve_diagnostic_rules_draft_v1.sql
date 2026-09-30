-- AW9-12 annual-reserve diagnostic misconception rules draft v1.
-- DRAFT ONLY. Exactly three wrong-option rules per diagnostic item.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4811,4812) and lifecycle_state='draft' and reserve_role='diagnostic')<>28
  then raise exception 'aw09_12_annual_reserve_rules: diagnostic draft surface missing'; end if;
end
$preflight$;

with skill_feedback(skill_code,mistake_type,feedback_en,feedback_ru,feedback_uz,next_en,next_ru,next_uz) as (values
('P1-QUA-04','method','Your choice does not match the sign pattern of the quadratic across its roots.','Выбранный вариант не соответствует знакам квадратичной функции на промежутках между корнями.','Tanlangan javob kvadrat funksiyaning ildizlar oralig‘idagi ishora tartibiga mos emas.','Factor or find the roots, mark them on a number line, then test the sign in each interval and check whether endpoints are included.','Разложите на множители или найдите корни, отметьте их на числовой прямой, проверьте знак на каждом промежутке и включение границ.','Ko‘paytuvchilarga ajrating yoki ildizlarni toping, ularni sonlar o‘qida belgilang, har oraliqda ishorani va chegara nuqtalar kirishini tekshiring.'),
('P1-QUA-05','method','Your choice does not satisfy both relations at the same point.','Выбранный вариант не удовлетворяет обоим соотношениям в одной и той же точке.','Tanlangan javob bir nuqtada ikkala bog‘lanishni ham qanoatlantirmaydi.','Set the two expressions for the shared variable equal, solve the resulting quadratic, then substitute back to verify each intersection.','Приравняйте два выражения общей переменной, решите получившееся квадратное уравнение и подставьте решения обратно.','Umumiy o‘zgaruvchi uchun ikki ifodani tenglashtiring, hosil bo‘lgan kvadrat tenglamani yeching va har bir yechimni qayta tekshiring.'),
('P1-QUA-06','structure','Your choice does not preserve the repeated expression as a single transformed variable.','Выбранный вариант неверно использует повторяющееся выражение как новую переменную.','Tanlangan javob takrorlanuvchi ifodani bitta yangi o‘zgaruvchi sifatida to‘g‘ri saqlamaydi.','Name the repeated expression u, solve the quadratic in u, then substitute each valid u-value back and solve for x.','Обозначьте повторяющееся выражение через u, решите квадратное уравнение по u, затем верните каждое допустимое значение u.','Takrorlanuvchi ifodani u deb belgilang, u bo‘yicha kvadrat tenglamani yeching, so‘ng har bir mos u qiymatini asl ifodaga qaytaring.'),
('P1-FUN-03','domain','Your choice misses a domain restriction created by the inner or outer function.','В выбранном варианте пропущено ограничение области определения внутренней или внешней функции.','Tanlangan javob ichki yoki tashqi funksiya keltirib chiqaradigan aniqlanish sohasi cheklovini hisobga olmaydi.','Apply the inner function first, then require its output to be a valid input for the outer function; combine all restrictions.','Сначала примените внутреннюю функцию, затем потребуйте, чтобы её результат был допустимым входом внешней функции; объедините ограничения.','Avval ichki funksiyani qo‘llang, keyin uning chiqishi tashqi funksiya uchun ruxsat etilgan kirish bo‘lishini talab qiling; barcha cheklovlarni birlashtiring.'),
('P1-FUN-04','inverse','Your choice does not correctly reverse the original one-one mapping or its domain/range restriction.','Выбранный вариант неверно обращает исходное взаимно однозначное отображение или его ограничения.','Tanlangan javob asl bir qiymatli akslantirishni yoki uning soha cheklovlarini to‘g‘ri teskarilamaydi.','Write y=f(x), solve algebraically for x, then swap variable names and carry the original range into the inverse domain.','Запишите y=f(x), выразите x, затем поменяйте обозначения переменных и перенесите область значений исходной функции в область определения обратной.','y=f(x) ni yozing, x ni algebraik ifodalang, so‘ng o‘zgaruvchi nomlarini almashtiring va asl qiymatlar sohasini teskari funksiyaning aniqlanish sohasiga o‘tkazing.'),
('P1-FUN-05','representation','Your choice does not reflect the graph correctly in the line y=x.','Выбранный вариант неверно отражает график относительно прямой y=x.','Tanlangan javob grafikni y=x chiziqqa nisbatan to‘g‘ri akslantirmaydi.','Swap the coordinates of every corresponding point: (x,y) on f becomes (y,x) on f⁻¹.','Меняйте координаты местами: точка (x,y) на f переходит в (y,x) на f⁻¹.','Har bir mos nuqtada koordinatalarni almashtiring: f dagi (x,y) nuqta f⁻¹ da (y,x) ga o‘tadi.'),
('P1-COO-04','method','Your choice uses the wrong centre, radius or square-completion step for the circle.','В выбранном варианте неверно найден центр, радиус или выполнено дополнение до квадрата.','Tanlangan javobda aylana markazi, radiusi yoki kvadratni to‘ldirish bosqichi noto‘g‘ri.','Complete the x- and y-squares separately, then compare with (x−a)²+(y−b)²=r² and verify any given point.','Отдельно дополните квадраты по x и y, затем сравните с (x−a)²+(y−b)²=r² и проверьте заданную точку.','x va y bo‘yicha kvadratlarni alohida to‘ldiring, so‘ng (x−a)²+(y−b)²=r² bilan solishtiring va berilgan nuqtani tekshiring.'),
('P1-CIR-02','units','Your choice does not use arc length, radius and radian measure consistently.','В выбранном варианте длина дуги, радиус и радианная мера используются несогласованно.','Tanlangan javobda yoy uzunligi, radius va radian o‘lchovi izchil ishlatilmagan.','Use s=rθ only with θ in radians; if an angle is in degrees, convert it before substituting.','Используйте s=rθ только при θ в радианах; угол в градусах сначала переведите в радианы.','s=rθ formulasini faqat θ radianlarda bo‘lganda ishlating; gradusdagi burchakni avval radianlarga o‘tkazing.'),
('P5-DAT-03','interpretation','Your choice misreads quartiles, IQR or the 1.5×IQR outlier fences.','В выбранном варианте неверно интерпретированы квартили, IQR или границы выбросов по правилу 1,5×IQR.','Tanlangan javob kvartillar, IQR yoki 1.5×IQR chet qiymat chegaralarini noto‘g‘ri talqin qiladi.','Compute IQR=Q3−Q1 first, then form the lower and upper fences and compare values with those fences.','Сначала вычислите IQR=Q3−Q1, затем найдите нижнюю и верхнюю границы и сравните с ними значения.','Avval IQR=Q3−Q1 ni hisoblang, so‘ng quyi va yuqori chegaralarni topib, qiymatlarni shu chegaralar bilan solishtiring.'),
('P5-DAT-05','interpretation','Your choice uses the wrong cumulative count or percentile position.','В выбранном варианте использована неверная накопленная частота или позиция процентиля.','Tanlangan javobda noto‘g‘ri kumulyativ chastota yoki percentil o‘rni ishlatilgan.','Convert the required percentile or quartile to a cumulative count, or subtract cumulative counts to find how many values lie in an interval.','Переведите процентиль или квартиль в накопленную частоту либо вычтите накопленные частоты для нужного интервала.','Kerakli percentil yoki kvartilni kumulyativ songa aylantiring yoki oraliqdagi qiymatlar sonini topish uchun kumulyativ chastotalarni ayiring.'),
('P5-DAT-07','spread','Your choice applies a shift or scale factor incorrectly to a measure of spread.','В выбранном варианте сдвиг или масштаб неверно применён к мере разброса.','Tanlangan javobda siljish yoki masshtab koeffitsiyenti tarqoqlik o‘lchoviga noto‘g‘ri qo‘llangan.','A common shift leaves range, IQR and standard deviation unchanged; multiplication by a scales them by |a|.','Общий сдвиг не меняет размах, IQR и стандартное отклонение; умножение на a масштабирует их в |a| раз.','Umumiy siljish oraliq, IQR va standart og‘ishni o‘zgartirmaydi; a ga ko‘paytirish ularni |a| marta masshtablaydi.'),
('P5-CNT-05','counting','Your choice does not match the selection restriction or treats an unordered committee as ordered.','В выбранном варианте неверно учтено ограничение выбора или неупорядоченный комитет посчитан как упорядоченный.','Tanlangan javob tanlash chekloviga mos emas yoki tartibsiz qo‘mita tartibli deb sanalgan.','Break the restriction into disjoint cases or use a complement, and use combinations whenever internal order does not create a new selection.','Разбейте ограничение на непересекающиеся случаи или используйте дополнение; применяйте сочетания, если внутренний порядок не создаёт новый выбор.','Cheklovni kesishmaydigan holatlarga ajrating yoki to‘ldiruvchidan foydalaning; ichki tartib yangi tanlov bermasa kombinatsiyalarni ishlating.'),
('P5-PRO-02','probability','Your choice does not use the same equally likely combination sample space in the numerator and denominator.','В выбранном варианте числитель и знаменатель не относятся к одному пространству равновероятных сочетаний.','Tanlangan javobda surat va maxraj bir xil teng ehtimolli kombinatsiyalar fazosiga tegishli emas.','Count favourable unordered selections with combinations, divide by the total combinations, then simplify.','Посчитайте благоприятные неупорядоченные выборы сочетаниями, разделите на общее число сочетаний и сократите.','Qulay tartibsiz tanlovlarni kombinatsiyalar bilan sanang, jami kombinatsiyalarga bo‘ling va kasrni qisqartiring.'),
('P5-PRO-04','independence','Your choice misuses the multiplication rule or the numerical test for independence.','В выбранном варианте неверно применено правило умножения или численная проверка независимости.','Tanlangan javobda ko‘paytirish qoidasi yoki mustaqillikning sonli tekshiruvi noto‘g‘ri qo‘llangan.','Use P(A∩B)=P(A)P(B|A). For independence specifically, check whether P(A∩B)=P(A)P(B).','Используйте P(A∩B)=P(A)P(B|A). Для независимости отдельно проверьте P(A∩B)=P(A)P(B).','P(A∩B)=P(A)P(B|A) dan foydalaning. Mustaqillik uchun alohida P(A∩B)=P(A)P(B) tengligini tekshiring.')
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
where m.content_version_id in (4811,4812)
  and m.reserve_role='diagnostic'
  and qn.qtype='mcq'
  and l.answer_match<>qn.correct_answer
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4811,4812) and r.rule_version='aw_reserve_v1')<>84
  then raise exception 'aw09_12_annual_reserve_rules: expected 84 draft rules'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions qn on qn.id=m.question_id
  where m.content_version_id in (4811,4812)
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
  if v_bad<>0 then raise exception 'aw09_12_annual_reserve_rules: invalid diagnostic rule rows=%',v_bad; end if;
end
$postcheck$;

commit;
