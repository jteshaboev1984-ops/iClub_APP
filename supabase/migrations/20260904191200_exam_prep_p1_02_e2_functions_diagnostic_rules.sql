-- P1-02 intentional diagnostic interpretations for P1-FUN-06/07/08.
-- Three approved wrong-option rules per diagnostic item; private only.

begin;
with rules(cvkey,ckey,match,dcode,mtype,skill,fen,fru,fuz,nen,nru,nuz) as (values
('p1_e2_functions_bridge_v1','P1FUN06-D01','B','horizontal_translation_direction','concept','P1-FUN-06','For f(x−3), the graph moves right, not left. The inside sign works opposite to the visible horizontal direction.','Для f(x−3) график сдвигается вправо, а не влево. Знак внутри аргумента работает противоположно видимому горизонтальному направлению.','f(x−3) da grafik chapga emas, o‘ngga siljiydi. Argument ichidagi ishora gorizontal yo‘nalishga teskari ishlaydi.','Track a known point and solve x−3 = old x before applying the vertical shift.','Проследите известную точку и сначала решите x−3 = старый x, затем примените вертикальный сдвиг.','Ma’lum nuqtani kuzating: avval x−3 = eski x ni yeching, keyin vertikal siljishni qo‘llang.'),
('p1_e2_functions_bridge_v1','P1FUN06-D01','C','vertical_translation_sign','concept','P1-FUN-06','The +4 is outside f, so it increases every y-coordinate by 4 rather than decreasing it.','+4 находится вне f, поэтому увеличивает каждую y-координату на 4, а не уменьшает её.','+4 f dan tashqarida, shuning uchun har bir y-koordinatani 4 ga oshiradi, kamaytirmaydi.','Separate horizontal input changes from vertical output changes.','Разделяйте изменения аргумента по горизонтали и изменения значения функции по вертикали.','Gorizontal argument o‘zgarishini vertikal chiqish o‘zgarishidan ajrating.'),
('p1_e2_functions_bridge_v1','P1FUN06-D01','D','both_translation_signs','method','P1-FUN-06','Both transformations were reversed. f(x−3) shifts right by 3 and +4 shifts up by 4.','Оба преобразования выполнены в обратную сторону. f(x−3) сдвигает на 3 вправо, а +4 — на 4 вверх.','Ikkala o‘zgarish ham teskari qo‘llangan. f(x−3) 3 birlik o‘ngga, +4 esa 4 birlik yuqoriga siljitadi.','Use point mapping: (a,b) → (a+3,b+4).','Используйте отображение точки: (a,b) → (a+3,b+4).','Nuqta akslantirishidan foydalaning: (a,b) → (a+3,b+4).'),

('p1_e2_functions_bridge_v1','P1FUN07-D01','B','reflected_wrong_axis','concept','P1-FUN-07','Changing x to −x reflects in the y-axis. Here the minus is outside f, so the reflection is in the x-axis.','Замена x на −x отражает относительно оси y. Здесь минус стоит вне f, поэтому отражение идёт относительно оси x.','x ni −x ga almashtirish y o‘qiga nisbatan akslantiradi. Bu yerda minus f dan tashqarida, shuning uchun akslantirish x o‘qiga nisbatan bo‘ladi.','Ask whether the minus changes the input or the output.','Определите, меняет ли минус аргумент или значение функции.','Minus kirishni o‘zgartiryaptimi yoki chiqishni — shuni aniqlang.'),
('p1_e2_functions_bridge_v1','P1FUN07-D01','C','reflected_both_axes','method','P1-FUN-07','Only y changes sign for y=−f(x). Changing both coordinates would correspond to reflecting in both axes.','Для y=−f(x) знак меняет только y. Изменение обеих координат означало бы отражение относительно обеих осей.','y=−f(x) da faqat y ishorasi o‘zgaradi. Ikkala koordinatani o‘zgartirish ikkala o‘qqa nisbatan akslantirish bo‘lardi.','Use the mapping (x,y) → (x,−y) for an x-axis reflection.','Для отражения относительно оси x используйте (x,y) → (x,−y).','x o‘qiga nisbatan akslantirish uchun (x,y) → (x,−y) dan foydalaning.'),
('p1_e2_functions_bridge_v1','P1FUN07-D01','D','coordinate_swap_not_reflection','concept','P1-FUN-07','Swapping coordinates is not the rule for reflection in a coordinate axis.','Перестановка координат местами не является правилом отражения относительно координатной оси.','Koordinatalarni joyini almashtirish koordinata o‘qiga nisbatan akslantirish qoidasi emas.','Memorise the two axis maps: x-axis (x,y)→(x,−y), y-axis (x,y)→(−x,y).','Запомните две формулы: ось x — (x,y)→(x,−y), ось y — (x,y)→(−x,y).','Ikki qoidani eslab qoling: x o‘qi (x,y)→(x,−y), y o‘qi (x,y)→(−x,y).'),

('p1_e2_functions_bridge_v1','P1FUN08-D01','B','horizontal_scale_direction','concept','P1-FUN-08','For f(2x), x-coordinates are divided by 2, not multiplied by 2. The graph is horizontally compressed.','Для f(2x) x-координаты делятся на 2, а не умножаются на 2. График сжимается по горизонтали.','f(2x) da x-koordinatalar 2 ga bo‘linadi, 2 ga ko‘paytirilmaydi. Grafik gorizontal siqiladi.','Solve 2x = old x-coordinate before scaling y.','Перед изменением y решите 2x = старая x-координата.','y ni o‘zgartirishdan oldin 2x = eski x-koordinata tenglamasini yeching.'),
('p1_e2_functions_bridge_v1','P1FUN08-D01','C','vertical_scale_inverse','concept','P1-FUN-08','The outside factor 2 doubles y-coordinates; it does not halve them.','Внешний множитель 2 удваивает y-координаты, а не делит их пополам.','Tashqi 2 ko‘paytuvchi y-koordinatalarni ikki baravar qiladi, yarmiga tushirmaydi.','Treat inside and outside scale factors separately: input first, output second.','Разбирайте внутренний и внешний множители отдельно: сначала аргумент, затем значение функции.','Ichki va tashqi masshtablarni alohida ko‘ring: avval kirish, keyin chiqish.'),
('p1_e2_functions_bridge_v1','P1FUN08-D01','D','both_scale_directions','method','P1-FUN-08','Both scale directions were reversed. f(2x) halves x-coordinates and 2f(...) doubles y-coordinates.','Оба масштабирования выполнены в обратную сторону. f(2x) делит x-координаты пополам, а 2f(...) удваивает y-координаты.','Ikkala masshtab ham teskari qo‘llangan. f(2x) x-koordinatalarni yarmiga tushiradi, 2f(...) esa y-koordinatalarni ikki baravar qiladi.','Use point mapping (a,b) → (a/2,2b).','Используйте отображение точки (a,b) → (a/2,2b).','Nuqta akslantirishidan foydalaning: (a,b) → (a/2,2b).')
), meta as (
  select m.id,m.content_key,cv.content_version
  from private.exam_prep_question_content_meta m
  join private.exam_prep_content_versions cv on cv.id=m.content_version_id
  where cv.content_version='p1_e2_functions_bridge_v1' and m.reserve_role='diagnostic'
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
    left join private.exam_prep_diagnostic_rules r on r.content_meta_id=m.id and r.status='approved'
    where cv.content_version='p1_e2_functions_bridge_v1' and m.reserve_role='diagnostic'
    group by m.id having count(r.id)<>3
  ) x;
  if v_bad<>0 then raise exception 'P1-02 E2 functions diagnostic-rule floor failed for % items',v_bad; end if;
end $$;
commit;
