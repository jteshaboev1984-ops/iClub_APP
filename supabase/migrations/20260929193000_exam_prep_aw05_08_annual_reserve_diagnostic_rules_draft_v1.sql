-- AW5-8 annual-reserve diagnostic misconception rules draft v1.
-- DRAFT ONLY. Exactly three wrong-option rules per diagnostic item.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4807,4808) and lifecycle_state='draft' and reserve_role='diagnostic')<>28
  then raise exception 'aw05_08_annual_reserve_rules: diagnostic draft surface missing'; end if;
end
$preflight$;

with skill_feedback(skill_code,mistake_type,feedback_en,feedback_ru,feedback_uz,next_en,next_ru,next_uz) as (values
('P1-FUN-06','representation','Your choice does not follow the translation rule. A change inside f moves x in the opposite direction; a change outside f moves y directly.','Выбранный вариант не соблюдает правило сдвига. Изменение внутри f сдвигает x в противоположную сторону, изменение снаружи f напрямую меняет y.','Tanlangan javob ko‘chirish qoidasiga mos emas. f ichidagi o‘zgarish x ni teskari yo‘nalishda, tashqaridagi o‘zgarish esa y ni bevosita siljitadi.','Write the horizontal and vertical shifts separately, then apply both to the point or graph feature.','Отдельно запишите горизонтальный и вертикальный сдвиги, затем примените оба к точке или элементу графика.','Gorizontal va vertikal siljishlarni alohida yozing, keyin ikkalasini nuqta yoki grafik xususiyatiga qo‘llang.'),
('P1-FUN-07','representation','Your choice changes the wrong coordinate for the stated reflection.','В выбранном варианте меняется не та координата, которая должна измениться при указанном отражении.','Tanlangan javobda berilgan akslantirish uchun noto‘g‘ri koordinata o‘zgargan.','For reflection in the y-axis change x only; for reflection in the x-axis change y only.','При отражении относительно оси y меняйте только x; относительно оси x — только y.','y o‘qiga nisbatan akslantirishda faqat x ni, x o‘qiga nisbatan akslantirishda faqat y ni o‘zgartiring.'),
('P1-FUN-08','representation','Your choice applies a scale factor to the wrong coordinate or in the wrong direction.','В выбранном варианте коэффициент масштабирования применён к неверной координате или в неверном направлении.','Tanlangan javobda masshtab koeffitsiyenti noto‘g‘ri koordinataga yoki noto‘g‘ri yo‘nalishda qo‘llangan.','Inside f, solve for the new x-coordinate inversely; outside f, multiply the y-value directly.','Внутри f найдите новую x-координату обратным масштабированием; внешний множитель напрямую меняет y.','f ichida yangi x-koordinatani teskari masshtab bilan toping; tashqi koeffitsiyent y ni bevosita o‘zgartiradi.'),
('P1-COO-01','method','Your choice is inconsistent with the required gradient or does not pass through the stated point(s).','Выбранная прямая имеет неверный градиент или не проходит через заданную точку (точки).','Tanlangan chiziq kerakli gradientga ega emas yoki berilgan nuqta(lar)dan o‘tmaydi.','Find the gradient first, use y−y₁=m(x−x₁), then substitute a given point to verify the equation.','Сначала найдите градиент, используйте y−y₁=m(x−x₁), затем подставьте заданную точку для проверки.','Avval gradientni toping, y−y₁=m(x−x₁) dan foydalaning, so‘ng berilgan nuqtani qo‘yib tekshiring.'),
('P1-COO-02','method','Your choice does not match the coordinate formula required for midpoint, distance or intersection.','Выбранный вариант не соответствует формуле координат для середины, расстояния или пересечения.','Tanlangan javob o‘rta nuqta, masofa yoki kesishish uchun kerakli koordinata formulasiga mos emas.','Identify the required operation: average coordinates for a midpoint, use the distance formula, or equate the two line equations for an intersection.','Определите нужную операцию: усредните координаты для середины, используйте формулу расстояния или приравняйте уравнения прямых для пересечения.','Kerakli amalni aniqlang: o‘rta nuqta uchun koordinatalarni o‘rtachalang, masofa formulasidan foydalaning yoki kesishish uchun ikki chiziq tenglamasini tenglashtiring.'),
('P1-COO-03','method','Your choice uses an incorrect relationship between gradients.','В выбранном варианте неверно использована связь между градиентами.','Tanlangan javob gradientlar orasidagi munosabatni noto‘g‘ri qo‘llaydi.','Parallel lines have equal gradients; perpendicular non-vertical lines have gradients whose product is −1.','У параллельных прямых градиенты равны; у перпендикулярных невертикальных прямых произведение градиентов равно −1.','Parallel chiziqlar gradientlari teng; perpendikulyar vertikal bo‘lmagan chiziqlar gradientlari ko‘paytmasi −1.'),
('P1-CIR-01','method','Your choice uses the degree–radian conversion factor incorrectly.','В выбранном варианте неверно применён коэффициент перевода между градусами и радианами.','Tanlangan javobda gradus–radian o‘tkazish koeffitsiyenti noto‘g‘ri qo‘llangan.','Use 180°=π radians: multiply degrees by π/180, or radians by 180/π.','Используйте 180°=π радиан: градусы умножайте на π/180, радианы — на 180/π.','180°=π radian dan foydalaning: gradusni π/180 ga, radianni 180/π ga ko‘paytiring.'),
('P1-TRI-01','representation','Your choice misreads a transformed trigonometric graph feature such as period, range or asymptote.','В выбранном варианте неверно определено свойство преобразованного тригонометрического графика: период, область значений или асимптота.','Tanlangan javob o‘zgargan trigonometrik grafikning davri, qiymatlar sohasi yoki asimptotasini noto‘g‘ri aniqlaydi.','Separate horizontal and vertical effects, then use the base sin/cos/tan graph property.','Разделите горизонтальные и вертикальные изменения, затем используйте свойство базового графика sin/cos/tan.','Gorizontal va vertikal ta’sirlarni ajrating, so‘ng asosiy sin/cos/tan grafik xususiyatidan foydalaning.'),
('P5-CNT-01','concept','Your choice treats an ordered outcome as unordered, or an unordered selection as ordered.','В выбранном варианте упорядоченный исход рассматривается как неупорядоченный или наоборот.','Tanlangan javob tartibli natijani tartibsiz, yoki tartibsiz tanlovni tartibli deb hisoblaydi.','Decide first whether swapping the selected people or objects creates a new outcome; then choose permutation or combination.','Сначала решите, создаёт ли перестановка выбранных людей или объектов новый исход; затем выбирайте размещение или сочетание.','Avval tanlangan odamlar yoki obyektlar o‘rnini almashtirish yangi natija beradimi, aniqlang; keyin permutatsiya yoki kombinatsiyani tanlang.'),
('P5-CNT-02','method','Your choice does not count ordered positions without repetition correctly.','В выбранном варианте неверно посчитаны упорядоченные позиции без повторений.','Tanlangan javob takrorlanmaydigan tartibli joylarni noto‘g‘ri sanaydi.','Use nPr or the descending product n(n−1)… for the number of ordered positions required.','Используйте nPr или убывающее произведение n(n−1)… для нужного числа упорядоченных мест.','Kerakli tartibli joylar soni uchun nPr yoki n(n−1)… kamayuvchi ko‘paytmasidan foydalaning.'),
('P5-CNT-03','method','Your choice does not remove the overcount caused by identical repeated objects correctly.','В выбранном варианте неверно устранён лишний подсчёт из-за одинаковых повторяющихся объектов.','Tanlangan javob bir xil takrorlanuvchi obyektlar sababli ortiqcha sanashni to‘g‘ri bartaraf etmaydi.','Start with the factorial of all positions and divide by the factorial of each repeated multiplicity.','Начните с факториала всех позиций и разделите на факториал каждой кратности повторения.','Barcha joylar faktorialidan boshlang va har bir takrorlanish sonining faktorialiga bo‘ling.'),
('P5-CNT-04','method','Your choice does not enforce the stated restriction consistently.','В выбранном варианте заданное ограничение учтено непоследовательно.','Tanlangan javob berilgan cheklovni izchil hisobga olmaydi.','Use a block for items that must be together, a complement for items that must be apart, and fix required positions before arranging the rest.','Используйте блок для объектов, которые должны быть рядом, дополнение для запрета соседства и сначала фиксируйте заданные позиции.','Yonma-yon bo‘lishi kerak bo‘lganlar uchun blok, ajralgan bo‘lishi kerak bo‘lganlar uchun to‘ldiruvchi usuldan foydalaning va avval belgilangan joylarni mahkamlang.'),
('P5-PRO-01','representation','Your choice omits outcomes or does not use the product structure of independent stages.','В выбранном варианте пропущены исходы или не использована структура произведения независимых этапов.','Tanlangan javobda natijalar tushib qolgan yoki mustaqil bosqichlarning ko‘paytma tuzilishi ishlatilmagan.','List each stage and multiply its number of equally likely outcomes to form the complete ordered sample space.','Перечислите этапы и перемножьте числа равновероятных исходов, чтобы получить полное упорядоченное пространство исходов.','Har bir bosqichdagi teng ehtimolli natijalar sonini yozing va to‘liq tartibli namunalar fazosi uchun ularni ko‘paytiring.'),
('P5-PRO-03','method','Your choice applies the complement or probability addition rule incorrectly.','В выбранном варианте неверно применено дополнение или правило сложения вероятностей.','Tanlangan javobda to‘ldiruvchi yoki ehtimollarni qo‘shish qoidasi noto‘g‘ri qo‘llangan.','Use P(Aᶜ)=1−P(A) and P(A∪B)=P(A)+P(B)−P(A∩B); simplify only after substituting all terms.','Используйте P(Aᶜ)=1−P(A) и P(A∪B)=P(A)+P(B)−P(A∩B); упрощайте после подстановки всех членов.','P(Aᶜ)=1−P(A) va P(A∪B)=P(A)+P(B)−P(A∩B) formulalaridan foydalaning; barcha hadlarni qo‘ygandan keyin soddalashtiring.')
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
where m.content_version_id in (4807,4808)
  and m.reserve_role='diagnostic'
  and qn.qtype='mcq'
  and l.answer_match<>qn.correct_answer
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4807,4808) and r.rule_version='aw_reserve_v1')<>84
  then raise exception 'aw05_08_annual_reserve_rules: expected 84 draft rules'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions qn on qn.id=m.question_id
  where m.content_version_id in (4807,4808)
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
  if v_bad<>0 then raise exception 'aw05_08_annual_reserve_rules: invalid diagnostic rule rows=%',v_bad; end if;
end
$postcheck$;

commit;
