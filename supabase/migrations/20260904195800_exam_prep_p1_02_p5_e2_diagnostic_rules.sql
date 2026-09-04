-- P1-02 E2 intentional diagnostic interpretations for P5 Counting + Probability.
-- Three approved WRONG-option rules per diagnostic item; private only.

begin;
with rules(ckey,match,dcode,mtype,skill,fen,fru,fuz,nen,nru,nuz) as (values
('P5CNT01-D01','A','unordered_roles','model_selection','P5-CNT-01',
 'Choosing 28 treats president and secretary as an unordered pair, using C(8,2). The two offices are different, so swapping the same two students creates a different outcome.',
 'Ответ 28 рассматривает президента и секретаря как неупорядоченную пару C(8,2). Должности различны, поэтому перестановка тех же двух учеников даёт другой исход.',
 '28 javobi prezident va kotibni tartibsiz juftlik deb C(8,2) orqali sanaydi. Lavozimlar turlicha, shuning uchun ayni ikki o‘quvchini almashtirish boshqa natija beradi.',
 'Ask whether the selected positions are labelled. For labelled roles use 8 choices then 7, not a combination.',
 'Сначала определите, подписаны ли роли. Для разных должностей используйте 8 вариантов, затем 7, а не сочетание.',
 'Avval rollar nomlanganmi, tekshiring. Turli lavozimlarda kombinatsiya emas, 8 ta so‘ng 7 ta tanlov ishlatiladi.'),
('P5CNT01-D01','C','same_person_twice','restriction','P5-CNT-01',
 'Using 8×8=64 allows the same student to be both president and secretary. Once the president is chosen, only 7 students remain for secretary.',
 'Расчёт 8×8=64 разрешает одному ученику занять обе должности. После выбора президента для секретаря остаётся только 7 человек.',
 '8×8=64 hisobida bir o‘quvchiga ikkala lavozim ham berilishi mumkin bo‘lib qoladi. Prezident tanlangach, kotib uchun 7 kishi qoladi.',
 'Reduce the second factor after choosing the first distinct office-holder.',
 'После выбора первого должностного лица уменьшите второй множитель на 1.',
 'Birinchi lavozim egasi tanlangach, ikkinchi ko‘paytuvchini 1 ga kamaytiring.'),
('P5CNT01-D01','D','single_role_only','model_selection','P5-CNT-01',
 'The value 8 counts only the choice for one office. A complete outcome must specify both president and secretary.',
 'Значение 8 учитывает выбор только одной должности. Полный исход должен задавать и президента, и секретаря.',
 '8 qiymati faqat bitta lavozim tanlovini sanaydi. To‘liq natijada prezident ham, kotib ham aniqlanishi kerak.',
 'List the successive choices required to define one complete outcome, then multiply their numbers.',
 'Перечислите последовательные выборы, необходимые для полного исхода, и перемножьте их количества.',
 'Bitta to‘liq natija uchun kerak bo‘lgan ketma-ket tanlovlarni yozib, ularning sonini ko‘paytiring.'),

('P5CNT02-D01','A','power_instead_of_factorial','method','P5-CNT-02',
 'The value 49=7² does not count arrangements of all seven distinct books. Each successive position has one fewer available book.',
 'Значение 49=7² не считает перестановки всех семи различных книг. Для каждой следующей позиции доступно на одну книгу меньше.',
 '49=7² yettita turli kitobning barcha joylashuvlarini sanamaydi. Har keyingi o‘rinda mavjud kitoblar soni bittaga kamayadi.',
 'For a full arrangement of n distinct objects, multiply n(n−1)…1 = n!.',
 'Для полной перестановки n различных объектов используйте n(n−1)…1=n!.',
 'n ta turli obyektning to‘liq joylashuvi uchun n(n−1)…1=n! ni ishlating.'),
('P5CNT02-D01','B','one_object_omitted','method','P5-CNT-02',
 '720 is 6!, so one of the seven books has effectively been omitted. All seven books must occupy the seven ordered positions.',
 '720=6!, то есть одна из семи книг фактически пропущена. Все семь книг должны занять семь упорядоченных мест.',
 '720=6!, ya’ni yettita kitobdan biri hisobdan tushib qolgan. Barcha 7 kitob 7 ta tartibli o‘rinni egallashi kerak.',
 'Check that the factorial starts at the total number of distinct objects being arranged.',
 'Проверьте, что факториал начинается с общего числа переставляемых объектов.',
 'Faktorial joylashtirilayotgan turli obyektlarning umumiy sonidan boshlanishini tekshiring.'),
('P5CNT02-D01','D','repetition_allowed','restriction','P5-CNT-02',
 '7⁷ treats each of seven positions as if any of the seven books could be reused. A book cannot occupy more than one position.',
 '7⁷ предполагает, что в каждой из семи позиций можно снова использовать любую книгу. Одна книга не может занимать несколько мест.',
 '7⁷ har bir 7 ta o‘ringa istalgan kitobni qayta ishlatishga ruxsat beradi. Bir kitob bir nechta o‘rinni egallay olmaydi.',
 'When objects are used without replacement, decrease the number of choices after every placement.',
 'При размещении без повторений уменьшайте число вариантов после каждого выбора.',
 'Takrorlanmasdan joylashtirishda har tanlovdan keyin variantlar sonini kamaytiring.'),

('P5CNT03-D01','A','wrong_repeat_multiplicity','method','P5-CNT-03',
 '20 corresponds to dividing 5! by 3!, as if one letter appeared three times. In LEVEL, L appears twice and E appears twice.',
 '20 получается при делении 5! на 3!, как будто одна буква встречается трижды. В LEVEL буква L встречается дважды и E тоже дважды.',
 '20 qiymati 5! ni 3! ga bo‘lgandek, go‘yo bir harf uch marta uchraydi. LEVEL da L ikki marta va E ham ikki marta keladi.',
 'Count the multiplicity of every repeated symbol separately before dividing the factorial.',
 'Отдельно посчитайте кратность каждой повторяющейся буквы перед делением факториала.',
 'Faktorialni bo‘lishdan oldin har bir takrorlangan belgining sonini alohida sanang.'),
('P5CNT03-D01','C','one_repeat_pair_ignored','method','P5-CNT-03',
 '60=5!/2! corrects for only one repeated pair. Both the two Ls and the two Es create indistinguishable swaps.',
 '60=5!/2! учитывает только одну повторяющуюся пару. Нужно учесть и две L, и две E.',
 '60=5!/2! faqat bitta takrorlangan juftlikni hisobga oladi. Ikki L ham, ikki E ham farqlanmaydigan almashishlar beradi.',
 'Divide by a factorial for each group of identical objects: here 2!×2!.',
 'Делите на факториал для каждой группы одинаковых объектов: здесь на 2!×2!.',
 'Har bir bir xil obyektlar guruhi uchun faktorialga bo‘ling: bu yerda 2!×2!.'),
('P5CNT03-D01','D','identical_objects_treated_distinct','concept','P5-CNT-03',
 '120=5! treats all five letters as distinct. Swapping the two Ls or the two Es does not create a new arrangement.',
 '120=5! считает все пять букв различными. Перестановка двух L или двух E не создаёт новой последовательности.',
 '120=5! barcha besh harfni turli deb hisoblaydi. Ikki L yoki ikki E ni almashtirish yangi joylashuv bermaydi.',
 'Start with 5!, then remove overcounting caused by each repeated letter group.',
 'Начните с 5!, затем устраните многократный подсчёт для каждой группы повторяющихся букв.',
 '5! dan boshlang, keyin har bir takrorlangan harf guruhi sababli ortiqcha sanashni olib tashlang.'),

('P5CNT04-D01','A','block_internal_order_omitted','method','P5-CNT-04',
 '24=4! correctly treats A and B as one block but forgets that the block can be AB or BA.',
 '24=4! правильно рассматривает A и B как один блок, но забывает, что внутри блока возможны AB и BA.',
 '24=4! A va B ni bitta blok deb to‘g‘ri oladi, lekin blok ichida AB yoki BA bo‘lishi mumkinligini unutadi.',
 'After arranging the four units, multiply by the number of allowed internal orders of the block.',
 'После перестановки четырёх объектов умножьте на число допустимых порядков внутри блока.',
 'To‘rtta birlikni joylashtirgach, blok ichidagi mumkin bo‘lgan tartiblar soniga ko‘paytiring.'),
('P5CNT04-D01','C','restriction_halved_without_model','reasoning','P5-CNT-04',
 '60=5!/2 assumes the together condition simply halves all arrangements. The valid cases must be counted structurally by forming an AB block.',
 '60=5!/2 предполагает, что условие соседства просто делит все перестановки пополам. Допустимые случаи нужно считать через блок AB.',
 '60=5!/2 yonma-yon bo‘lish sharti barcha joylashuvlarni shunchaki yarmiga tushiradi deb oladi. To‘g‘ri sanash uchun AB blokini tuzish kerak.',
 'Translate the restriction into a counting structure rather than applying an unsupported fraction to 5!.',
 'Преобразуйте ограничение в структуру подсчёта, а не применяйте необоснованную долю к 5!.',
 'Cheklovni sanash strukturasiga aylantiring; 5! ga asossiz ulush qo‘llamang.'),
('P5CNT04-D01','D','restriction_ignored','reasoning','P5-CNT-04',
 '120=5! counts every arrangement and ignores the requirement that A and B stand together.',
 '120=5! считает все перестановки и игнорирует требование, что A и B должны стоять рядом.',
 '120=5! barcha joylashuvlarni sanaydi va A bilan B yonma-yon turishi shartini e’tiborsiz qoldiradi.',
 'Before calculating, encode the stated restriction: together → one block; apart → often total minus together.',
 'До вычислений закодируйте ограничение: вместе → один блок; не рядом → часто все минус вместе.',
 'Hisoblashdan oldin cheklovni ifodalang: birga → bitta blok; yonma-yon emas → ko‘pincha jami minus birga.'),

('P5PRO01-D01','B','ordered_outcome_collapsed','sample_space','P5-PRO-01',
 'The set omits TH by treating HT and TH as the same. Because the two coin positions are recorded, HT and TH are distinct ordered outcomes.',
 'Множество пропускает TH, считая HT и TH одним исходом. Поскольку позиции двух монет учитываются, HT и TH различны.',
 'To‘plam TH ni tashlab ketadi, HT va TH ni bir xil deb oladi. Ikki tanga o‘rni qayd etilgani uchun HT va TH turli tartiblangan natijalardir.',
 'List outcomes as ordered pairs for coin 1 and coin 2, then check that all 2×2 combinations appear once.',
 'Запишите исходы как упорядоченные пары для монеты 1 и монеты 2 и проверьте все 2×2 комбинации.',
 'Natijalarni 1-tanga va 2-tanga uchun tartiblangan juftlik qilib yozib, barcha 2×2 kombinatsiya bir martadan borligini tekshiring.'),
('P5PRO01-D01','C','single_trial_space','sample_space','P5-PRO-01',
 '{H,T} is the sample space for one coin toss, not for two recorded tosses.',
 '{H,T} — пространство исходов одного броска монеты, а не двух учитываемых бросков.',
 '{H,T} bitta tanga tashlashning natijalar fazosi, ikkita qayd etilgan tashlashniki emas.',
 'A complete outcome must specify a result for each of the two trials.',
 'Полный исход должен задавать результат каждого из двух испытаний.',
 'To‘liq natijada ikkala tajribaning ham natijasi ko‘rsatilishi kerak.'),
('P5PRO01-D01','D','mixed_outcomes_omitted','sample_space','P5-PRO-01',
 '{HH,TT} keeps only equal-face outcomes and omits the possible mixed outcomes HT and TH.',
 '{HH,TT} оставляет только одинаковые результаты и пропускает возможные смешанные исходы HT и TH.',
 '{HH,TT} faqat bir xil tomonli natijalarni qoldiradi va mumkin bo‘lgan HT hamda TH aralash natijalarni tashlab ketadi.',
 'Generate the Cartesian product {H,T}×{H,T}; do not keep only symmetric cases.',
 'Постройте декартово произведение {H,T}×{H,T}, не ограничиваясь симметричными случаями.',
 '{H,T}×{H,T} Dekart ko‘paytmasini tuzing; faqat simmetrik holatlarni qoldirmang.'),

('P5PRO03-D01','A','multiplied_mutually_exclusive','rule_selection','P5-PRO-03',
 '0.12=0.4×0.3 applies a multiplication rule. For mutually exclusive events the intersection is zero, so their union is found by addition.',
 '0.12=0.4×0.3 использует правило умножения. Для несовместных событий пересечение равно нулю, поэтому объединение находится сложением.',
 '0.12=0.4×0.3 ko‘paytirish qoidasini qo‘llaydi. O‘zaro istisno hodisalarning kesishmasi 0, shuning uchun birlashma qo‘shish bilan topiladi.',
 'Identify whether the question asks for AND or OR. Here A∪B means OR, and mutual exclusivity makes the overlap term zero.',
 'Определите, требуется AND или OR. Здесь A∪B означает OR, а несовместность обнуляет пересечение.',
 'Savol AND yoki OR ni so‘rayaptimi, aniqlang. Bu yerda A∪B — OR, o‘zaro istisnolik esa kesishmani 0 qiladi.'),
('P5PRO03-D01','B','one_event_only','incomplete_model','P5-PRO-03',
 '0.3 is only P(B). The union A∪B includes outcomes in A as well as outcomes in B.',
 '0.3 — это только P(B). Объединение A∪B включает исходы и из A, и из B.',
 '0.3 faqat P(B). A∪B birlashmasi A dagi ham, B dagi ham natijalarni o‘z ichiga oladi.',
 'For a union, account for both events and then correct for any overlap if necessary.',
 'Для объединения учтите оба события и при необходимости вычтите пересечение.',
 'Birlashma uchun ikkala hodisani ham hisobga oling, kerak bo‘lsa kesishmani ayiring.'),
('P5PRO03-D01','D','exclusive_confused_with_exhaustive','concept','P5-PRO-03',
 'Mutually exclusive means A and B cannot occur together; it does not mean they cover the whole sample space. Their probabilities need not sum to 1.',
 'Несовместность означает, что A и B не происходят вместе; это не означает, что они исчерпывают всё пространство исходов. Их вероятности не обязаны давать 1.',
 'O‘zaro istisno bo‘lish A va B birga sodir bo‘lmasligini anglatadi; ular barcha natijalar fazosini qoplaydi degani emas. Ehtimollar yig‘indisi 1 bo‘lishi shart emas.',
 'Separate the ideas: mutually exclusive → intersection 0; exhaustive → union 1.',
 'Разделяйте понятия: несовместные → пересечение 0; исчерпывающие → объединение 1.',
 'Tushunchalarni ajrating: o‘zaro istisno → kesishma 0; to‘liq qamrovchi → birlashma 1.')
), meta as (
  select m.id,m.content_key
  from private.exam_prep_question_content_meta m
  join private.exam_prep_content_versions cv on cv.id=m.content_version_id
  where cv.content_version='p5_e2_counting_probability_v1' and m.reserve_role='diagnostic'
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
    join public.questions q on q.id=m.question_id
    left join private.exam_prep_diagnostic_rules r on r.content_meta_id=m.id and r.status='approved' and r.answer_kind='mcq_option'
    where cv.content_version='p5_e2_counting_probability_v1' and m.reserve_role='diagnostic'
    group by m.id,q.correct_answer
    having count(r.id)<>3 or count(r.id) filter(where r.answer_match=q.correct_answer)<>0
  ) x;
  if v_bad<>0 then raise exception 'P1-02 P5 E2 diagnostic rule contract failed for % items',v_bad; end if;
  if (select count(*) from private.exam_prep_diagnostic_rules r join private.exam_prep_question_content_meta m on m.id=r.content_meta_id join private.exam_prep_content_versions cv on cv.id=m.content_version_id where cv.content_version='p5_e2_counting_probability_v1' and r.status='approved')<>18 then
    raise exception 'P1-02 P5 E2 expected 18 approved diagnostic rules';
  end if;
end $$;
commit;
