-- AW5-8 P5 annual-reserve top-up draft v1.
-- DRAFT ONLY: no learner-visible content and no existing evidence mutation.
-- Exact delta per skill: +2 diagnostics, +2 delayed retests, +1 mixed/transfer.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw05_08_annual_reserve_p5_draft canonical program missing'; end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4808 and content_version<>'p5_aw05_08_annual_reserve_topup_draft_v1')
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59128 and 59157 and content_version_id<>4808)
  then raise exception 'aw05_08_annual_reserve_p5_draft reserved id collision'; end if;

  if (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P5-CNT-01','P5-CNT-02','P5-CNT-03','P5-CNT-04','P5-PRO-01','P5-PRO-03')
        and m.reserve_role='diagnostic')<>6
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P5-CNT-01','P5-CNT-02','P5-CNT-03','P5-CNT-04','P5-PRO-01','P5-PRO-03')
        and m.reserve_role='retest')<>12
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P5-CNT-01','P5-CNT-02','P5-CNT-03','P5-CNT-04','P5-PRO-01','P5-PRO-03')
        and m.reserve_role in ('learning','mixed'))<>42
  then raise exception 'aw05_08_annual_reserve_p5_draft baseline depth changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4808,pv.id,'p5_aw05_08_annual_reserve_topup_draft_v1','P5',
 'P5 AW5-8 annual reserve top-up draft v1','draft',
 'Original iClub-authored annual reserve expansion. Official Cambridge 9709 scope controls the learning objectives; Complete Probability & Statistics 1 is mapping/explanation support only. No protected Cambridge/coursebook question, solution, mark-scheme wording or diagram is copied. Independent academic, trilingual, technical, originality and reserve-isolation QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,reserve_role,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P5CNT01-D02','P5-CNT-01','diagnostic','medium','mcq','Eleven students are available. A captain and a deputy captain are chosen. How many outcomes are possible?','["110","55","121","22"]','A','The roles are different, so order matters: 11×10=110.','Есть 11 учеников. Выбирают капитана и заместителя капитана. Сколько исходов возможно?','["110","55","121","22"]','Роли различаются, поэтому порядок важен: 11×10=110.','11 nafar o‘quvchi bor. Sardor va sardor o‘rinbosari tanlanadi. Nechta natija mumkin?','["110","55","121","22"]','Vazifalar turlicha, shuning uchun tartib muhim: 11×10=110.',70),
('P5CNT01-D03','P5-CNT-01','diagnostic','medium','mcq','A 4-person panel is selected from 10 students, with no roles assigned. How many panels are possible?','["5040","210","720","40"]','B','Order does not matter, so use 10C4=210.','Из 10 учеников выбирают группу из 4 человек без распределения ролей. Сколько групп возможно?','["5040","210","720","40"]','Порядок не важен, поэтому используем 10C4=210.','10 nafar o‘quvchidan vazifalarsiz 4 kishilik guruh tanlanadi. Nechta guruh mumkin?','["5040","210","720","40"]','Tartib muhim emas, shuning uchun 10C4=210.',70),
('P5CNT01-R03','P5-CNT-01','retest','medium','input','A 3-person group is selected from 12 people, with no roles. Enter the number of groups.','[]','220','The number is 12C3=220.','Из 12 человек выбирают группу из 3 человек без ролей. Введите число групп.','[]','Число групп равно 12C3=220.','12 kishidan vazifalarsiz 3 kishilik guruh tanlanadi. Guruhlar sonini kiriting.','[]','Guruhlar soni 12C3=220.',70),
('P5CNT01-R04','P5-CNT-01','retest','medium','mcq','First and second prizes are awarded to two different people from 7 finalists. How many outcomes are possible?','["21","49","14","42"]','D','The prizes are ordered, so 7P2=7×6=42.','Первое и второе места присуждают двум разным людям из 7 финалистов. Сколько исходов возможно?','["21","49","14","42"]','Места упорядочены, поэтому 7P2=7×6=42.','7 finalchidan ikki turli kishiga birinchi va ikkinchi o‘rin beriladi. Nechta natija mumkin?','["21","49","14","42"]','O‘rinlar tartibli, shuning uchun 7P2=7×6=42.',70),
('P5CNT01-M02','P5-CNT-01','mixed','hard','mcq','From 9 students, a 5-person team is selected and then one of the five is appointed captain. How many outcomes are possible?','["126","630","15120","2520"]','B','There are 9C5=126 teams and 5 captain choices for each team, giving 126×5=630.','Из 9 учеников выбирают команду из 5 человек, затем одного из пяти назначают капитаном. Сколько исходов возможно?','["126","630","15120","2520"]','Есть 9C5=126 команд и 5 вариантов капитана для каждой, поэтому 126×5=630.','9 nafar o‘quvchidan 5 kishilik jamoa tanlanadi, so‘ng ulardan biri sardor qilinadi. Nechta natija mumkin?','["126","630","15120","2520"]','9C5=126 ta jamoa va har bir jamoada 5 ta sardor tanlovi bor, demak 126×5=630.',90),
('P5CNT02-D02','P5-CNT-02','diagnostic','medium','mcq','Six of 9 distinct objects are chosen and arranged in a row. How many arrangements are possible?','["84","720","60480","362880"]','C','The positions are ordered and there is no repetition, so 9P6=9×8×7×6×5×4=60480.','Из 9 различных объектов выбирают 6 и располагают в ряд. Сколько расстановок возможно?','["84","720","60480","362880"]','Позиции упорядочены и повторений нет, поэтому 9P6=9×8×7×6×5×4=60480.','9 ta turli obyektdan 6 tasi tanlanib qatorga joylashtiriladi. Nechta tartib mumkin?','["84","720","60480","362880"]','Joylar tartibli va takrorlanish yo‘q, shuning uchun 9P6=9×8×7×6×5×4=60480.',70),
('P5CNT02-D03','P5-CNT-02','diagnostic','medium','mcq','A 4-digit code is formed from the digits 1 to 9 without repetition. How many codes are possible?','["1512","6561","126","3024"]','D','The count is 9P4=9×8×7×6=3024.','Четырёхзначный код составляют из цифр 1–9 без повторений. Сколько кодов возможно?','["1512","6561","126","3024"]','Число кодов равно 9P4=9×8×7×6=3024.','1 dan 9 gacha raqamlardan takrorlanmasdan 4 xonali kod tuziladi. Nechta kod mumkin?','["1512","6561","126","3024"]','Kodlar soni 9P4=9×8×7×6=3024.',70),
('P5CNT02-R03','P5-CNT-02','retest','medium','input','Four ordered positions are filled from 8 distinct candidates without repetition. Enter the number of outcomes.','[]','1680','8P4=8×7×6×5=1680.','Четыре упорядоченные позиции заполняют из 8 разных кандидатов без повторений. Введите число исходов.','[]','8P4=8×7×6×5=1680.','8 ta turli nomzoddan 4 ta tartibli o‘rin takrorlanmasdan to‘ldiriladi. Natijalar sonini kiriting.','[]','8P4=8×7×6×5=1680.',70),
('P5CNT02-R04','P5-CNT-02','retest','medium','mcq','Seven distinct flags are arranged in a row. How many orders are possible?','["5040","720","343","49"]','A','All seven distinct objects are arranged, so the number is 7!=5040.','Семь разных флагов располагают в ряд. Сколько порядков возможно?','["5040","720","343","49"]','Располагаются все семь разных объектов, поэтому число равно 7!=5040.','Yetti xil bayroq qatorga joylashtiriladi. Nechta tartib mumkin?','["5040","720","343","49"]','Yetti turli obyektning barchasi joylashtiriladi, shuning uchun 7!=5040.',70),
('P5CNT02-M02','P5-CNT-02','mixed','hard','mcq','Three distinct flags are selected from 8 and placed on three ordered masts. How many displays are possible?','["56","336","512","24"]','B','The three mast positions are ordered, so 8P3=8×7×6=336.','Три разных флага выбирают из 8 и размещают на трёх упорядоченных флагштоках. Сколько вариантов возможно?','["56","336","512","24"]','Три места упорядочены, поэтому 8P3=8×7×6=336.','8 ta turli bayroqdan 3 tasi tanlanib, uchta tartibli ustunga joylashtiriladi. Nechta ko‘rinish mumkin?','["56","336","512","24"]','Uchta joy tartibli, shuning uchun 8P3=8×7×6=336.',90),
('P5CNT03-D02','P5-CNT-03','diagnostic','medium','mcq','How many distinct arrangements of the letters in TATTOO are possible?','["60","180","120","720"]','A','TATTOO has 6 letters with T repeated three times and O repeated twice, so 6!/(3!2!)=60.','Сколько различных перестановок можно составить из букв слова TATTOO?','["60","180","120","720"]','В TATTOO 6 букв, T повторяется трижды и O дважды, поэтому 6!/(3!2!)=60.','TATTOO so‘zidagi harflardan nechta turli tartib tuzish mumkin?','["60","180","120","720"]','TATTOO da 6 ta harf bor, T uch marta va O ikki marta takrorlanadi, shuning uchun 6!/(3!2!)=60.',70),
('P5CNT03-D03','P5-CNT-03','diagnostic','medium','mcq','How many distinct strings can be formed using exactly A,A,B,B,B,C,C?','["420","210","840","35"]','B','There are 7 symbols with multiplicities 2,3,2, so the count is 7!/(2!3!2!)=210.','Сколько различных строк можно составить, используя ровно A,A,B,B,B,C,C?','["420","210","840","35"]','Есть 7 символов с кратностями 2,3,2, поэтому 7!/(2!3!2!)=210.','Aynan A,A,B,B,B,C,C belgilaridan nechta turli satr tuzish mumkin?','["420","210","840","35"]','7 ta belgi bor, takrorlanishlar 2,3,2; shuning uchun 7!/(2!3!2!)=210.',70),
('P5CNT03-R03','P5-CNT-03','retest','medium','input','Enter the number of distinct arrangements of the letters in BANANAS.','[]','420','BANANAS has 7 letters with A repeated three times and N twice, so 7!/(3!2!)=420.','Введите число различных перестановок букв слова BANANAS.','[]','В BANANAS 7 букв, A повторяется трижды и N дважды, поэтому 7!/(3!2!)=420.','BANANAS so‘zidagi harflarning turli tartiblari sonini kiriting.','[]','BANANAS da 7 ta harf bor, A uch marta va N ikki marta takrorlanadi, shuning uchun 7!/(3!2!)=420.',70),
('P5CNT03-R04','P5-CNT-03','retest','medium','mcq','How many distinct arrangements of the letters in APPLE are possible?','["120","24","60","30"]','C','APPLE has 5 letters with P repeated twice, so 5!/2!=60.','Сколько различных перестановок букв слова APPLE возможно?','["120","24","60","30"]','В APPLE 5 букв, P повторяется дважды, поэтому 5!/2!=60.','APPLE so‘zidagi harflarning nechta turli tartibi mumkin?','["120","24","60","30"]','APPLE da 5 ta harf bor, P ikki marta takrorlanadi, shuning uchun 5!/2!=60.',70),
('P5CNT03-M02','P5-CNT-03','mixed','hard','mcq','How many distinct strings can be formed using exactly A,A,A,B,B,C,C,D?','["3360","1680","840","560"]','B','The count is 8!/(3!2!2!)=1680.','Сколько различных строк можно составить, используя ровно A,A,A,B,B,C,C,D?','["3360","1680","840","560"]','Число строк равно 8!/(3!2!2!)=1680.','Aynan A,A,A,B,B,C,C,D belgilaridan nechta turli satr tuzish mumkin?','["3360","1680","840","560"]','Satrlar soni 8!/(3!2!2!)=1680.',90),
('P5CNT04-D02','P5-CNT-04','diagnostic','medium','mcq','Eight distinct people stand in a row. A and B must stand together. How many arrangements are possible?','["20160","40320","10080","5040"]','C','Treat A and B as one block: 7 units can be arranged in 7! ways, and A,B can swap, giving 2×7!=10080.','Восемь разных людей стоят в ряд. A и B должны стоять рядом. Сколько расстановок возможно?','["20160","40320","10080","5040"]','Считаем A и B одним блоком: 7 объектов дают 7! порядков, внутри блока A и B меняются местами, итого 2×7!=10080.','Sakkiz xil odam qatorga turadi. A va B yonma-yon turishi shart. Nechta tartib mumkin?','["20160","40320","10080","5040"]','A va B ni bitta blok deb olamiz: 7 birlik 7! usulda joylashadi, blok ichida A va B almashadi, jami 2×7!=10080.',70),
('P5CNT04-D03','P5-CNT-04','diagnostic','medium','mcq','Eight distinct people stand in a row. A and B must not stand together. How many arrangements are possible?','["10080","40320","20160","30240"]','D','All arrangements give 8!=40320. With A and B together there are 2×7!=10080, so 40320−10080=30240.','Восемь разных людей стоят в ряд. A и B не должны стоять рядом. Сколько расстановок возможно?','["10080","40320","20160","30240"]','Всего 8!=40320. С A и B рядом: 2×7!=10080, поэтому 40320−10080=30240.','Sakkiz xil odam qatorga turadi. A va B yonma-yon turmasligi kerak. Nechta tartib mumkin?','["10080","40320","20160","30240"]','Jami 8!=40320. A va B yonma-yon bo‘lsa 2×7!=10080, demak 40320−10080=30240.',70),
('P5CNT04-R03','P5-CNT-04','retest','medium','input','Seven distinct people stand in a row with C fixed in the first position. Enter the number of arrangements.','[]','720','With C fixed, the remaining 6 people can be arranged in 6!=720 ways.','Семь разных людей стоят в ряд, C закреплён на первом месте. Введите число расстановок.','[]','C закреплён, оставшиеся 6 человек можно расположить 6!=720 способами.','Yetti xil odam qatorga turadi, C birinchi o‘rinda mahkamlangan. Tartiblar sonini kiriting.','[]','C mahkamlangan, qolgan 6 odam 6!=720 usulda joylashadi.',70),
('P5CNT04-R04','P5-CNT-04','retest','medium','mcq','Seven distinct people stand in a row. C is fixed at the last position and A and B must stand together. How many arrangements are possible?','["480","240","720","120"]','B','With C fixed, the AB block plus four other people make 5 units: 5!×2=240.','Семь разных людей стоят в ряд. C закреплён на последнем месте, A и B должны стоять рядом. Сколько расстановок возможно?','["480","240","720","120"]','После фиксации C блок AB и четыре других человека дают 5 объектов: 5!×2=240.','Yetti xil odam qatorga turadi. C oxirgi o‘rinda, A va B esa yonma-yon turishi kerak. Nechta tartib mumkin?','["480","240","720","120"]','C mahkamlangach, AB bloki va yana to‘rt odam jami 5 birlik: 5!×2=240.',70),
('P5CNT04-M02','P5-CNT-04','mixed','hard','mcq','Eight distinct people stand in a row. C must be at one of the two ends and A and B must stand together. How many arrangements are possible?','["1440","2880","5760","10080"]','B','Choose the end for C in 2 ways. Then the AB block and five others form 6 units: 6! arrangements, with 2 internal AB orders. Total 2×6!×2=2880.','Восемь разных людей стоят в ряд. C должен стоять на одном из двух концов, A и B — рядом. Сколько расстановок возможно?','["1440","2880","5760","10080"]','Конец для C выбирается 2 способами. Затем блок AB и ещё пять человек дают 6 объектов: 6! порядков и 2 внутренних порядка AB. Итого 2×6!×2=2880.','Sakkiz xil odam qatorga turadi. C ikki chetdan birida, A va B esa yonma-yon turishi kerak. Nechta tartib mumkin?','["1440","2880","5760","10080"]','C uchun chet 2 usulda tanlanadi. Keyin AB bloki va yana besh odam 6 birlik bo‘ladi: 6! tartib va AB ichida 2 tartib. Jami 2×6!×2=2880.',95),
('P5PRO01-D02','P5-PRO-01','diagnostic','medium','mcq','Two fair coins are tossed and an independent fair spinner with 4 equally likely sectors is spun. How many equiprobable ordered outcomes are possible?','["16","12","8","32"]','A','The coins give 2×2=4 ordered outcomes; the spinner multiplies this by 4, giving 16.','Подбрасывают две честные монеты и независимо вращают честный диск с 4 равновероятными секторами. Сколько равновероятных упорядоченных исходов возможно?','["16","12","8","32"]','Монеты дают 2×2=4 упорядоченных исхода; диск умножает число на 4, получаем 16.','Ikki adolatli tanga tashlanadi va mustaqil ravishda 4 teng ehtimolli sektorga ega aylantirgich aylantiriladi. Nechta teng ehtimolli tartibli natija mumkin?','["16","12","8","32"]','Tangalar 2×2=4 tartibli natija beradi; aylantirgich bu sonni 4 ga ko‘paytiradi, jami 16.',70),
('P5PRO01-D03','P5-PRO-01','diagnostic','medium','mcq','A fair 4-sided die and a fair 6-sided die are distinguishable and rolled once each. How many equiprobable ordered outcomes are possible?','["10","24","48","20"]','B','The sample space is the Cartesian product: 4×6=24 ordered outcomes.','Различимые честные 4-гранный и 6-гранный кубики бросают по одному разу. Сколько равновероятных упорядоченных исходов возможно?','["10","24","48","20"]','Пространство исходов — декартово произведение: 4×6=24 упорядоченных исхода.','Farqlanadigan adolatli 4 qirrali va 6 qirrali kubik bir martadan tashlanadi. Nechta teng ehtimolli tartibli natija mumkin?','["10","24","48","20"]','Namunalar fazosi Dekart ko‘paytmasi: 4×6=24 tartibli natija.',70),
('P5PRO01-R03','P5-PRO-01','retest','medium','input','Three independent fair spinners have 2, 3 and 4 equally likely sectors. Enter the number of equiprobable ordered outcomes.','[]','24','The product rule gives 2×3×4=24.','Три независимых честных диска имеют 2, 3 и 4 равновероятных сектора. Введите число равновероятных упорядоченных исходов.','[]','По правилу произведения 2×3×4=24.','Uchta mustaqil adolatli aylantirgichda 2, 3 va 4 ta teng ehtimolli sektor bor. Tartibli natijalar sonini kiriting.','[]','Ko‘paytirish qoidasiga ko‘ra 2×3×4=24.',70),
('P5PRO01-R04','P5-PRO-01','retest','medium','mcq','A fair coin, a fair six-sided die and a fair spinner with 3 sectors are used independently. How many equiprobable ordered outcomes are possible?','["18","12","36","72"]','C','The product rule gives 2×6×3=36.','Независимо используют честную монету, честный шестигранный кубик и честный диск с 3 секторами. Сколько равновероятных упорядоченных исходов возможно?','["18","12","36","72"]','По правилу произведения 2×6×3=36.','Adolatli tanga, adolatli olti qirrali kubik va 3 sektorga ega adolatli aylantirgich mustaqil ishlatiladi. Nechta teng ehtimolli tartibli natija mumkin?','["18","12","36","72"]','Ko‘paytirish qoidasiga ko‘ra 2×6×3=36.',70),
('P5PRO01-M02','P5-PRO-01','mixed','hard','mcq','A fair spinner with 4 sectors, a fair spinner with 5 sectors and a fair coin are used independently. How many equiprobable ordered outcomes are possible?','["20","40","80","10"]','B','The complete sample space has 4×5×2=40 ordered outcomes.','Независимо используют честные диски с 4 и 5 секторами и честную монету. Сколько равновероятных упорядоченных исходов возможно?','["20","40","80","10"]','Полное пространство исходов содержит 4×5×2=40 упорядоченных исходов.','4 va 5 sektorga ega adolatli aylantirgichlar hamda adolatli tanga mustaqil ishlatiladi. Nechta teng ehtimolli tartibli natija mumkin?','["20","40","80","10"]','To‘liq namunalar fazosida 4×5×2=40 tartibli natija bor.',90),
('P5PRO03-D02','P5-PRO-03','diagnostic','medium','mcq','If P(A)=0.37, what is P(Aᶜ)?','["0.37","1.37","0.63","0.73"]','C','P(Aᶜ)=1−0.37=0.63.','Если P(A)=0,37, чему равно P(Aᶜ)?','["0,37","1,37","0,63","0,73"]','P(Aᶜ)=1−0,37=0,63.','Agar P(A)=0.37 bo‘lsa, P(Aᶜ) qancha?','["0.37","1.37","0.63","0.73"]','P(Aᶜ)=1−0.37=0.63.',70),
('P5PRO03-D03','P5-PRO-03','diagnostic','medium','mcq','P(A)=0.52, P(B)=0.43 and P(A∩B)=0.19. Find P(A∪B).','["0.95","0.57","0.71","0.76"]','D','P(A∪B)=0.52+0.43−0.19=0.76.','P(A)=0,52, P(B)=0,43 и P(A∩B)=0,19. Найдите P(A∪B).','["0,95","0,57","0,71","0,76"]','P(A∪B)=0,52+0,43−0,19=0,76.','P(A)=0.52, P(B)=0.43 va P(A∩B)=0.19. P(A∪B) ni toping.','["0.95","0.57","0.71","0.76"]','P(A∪B)=0.52+0.43−0.19=0.76.',70),
('P5PRO03-R03','P5-PRO-03','retest','medium','input','P(A)=0.44, P(B)=0.39 and P(A∪B)=0.68. Enter P(A∩B).','[]','0.15','P(A∩B)=0.44+0.39−0.68=0.15.','P(A)=0,44, P(B)=0,39 и P(A∪B)=0,68. Введите P(A∩B).','[]','P(A∩B)=0,44+0,39−0,68=0,15.','P(A)=0.44, P(B)=0.39 va P(A∪B)=0.68. P(A∩B) ni kiriting.','[]','P(A∩B)=0.44+0.39−0.68=0.15.',70),
('P5PRO03-R04','P5-PRO-03','retest','medium','mcq','If P(A∪B)=0.81, what is the probability that neither A nor B occurs?','["0.81","0.09","0.19","1.81"]','C','Neither A nor B is the complement of A∪B, so the probability is 1−0.81=0.19.','Если P(A∪B)=0,81, какова вероятность того, что не произойдёт ни A, ни B?','["0,81","0,09","0,19","1,81"]','Событие «ни A, ни B» — дополнение A∪B, поэтому вероятность 1−0,81=0,19.','Agar P(A∪B)=0.81 bo‘lsa, A ham, B ham sodir bo‘lmaslik ehtimoli qancha?','["0.81","0.09","0.19","1.81"]','A ham, B ham emas hodisasi A∪B ning to‘ldiruvchisi, shuning uchun ehtimol 1−0.81=0.19.',70),
('P5PRO03-M02','P5-PRO-03','mixed','hard','mcq','Events A and B are mutually exclusive with P(A)=0.27 and P(B)=0.31. What is the probability that neither event occurs?','["0.58","0.42","0.04","0.69"]','B','Mutual exclusivity gives P(A∪B)=0.27+0.31=0.58. The complement is 1−0.58=0.42.','События A и B несовместны, P(A)=0,27 и P(B)=0,31. Какова вероятность того, что не произойдёт ни одно событие?','["0,58","0,42","0,04","0,69"]','Для несовместных событий P(A∪B)=0,27+0,31=0,58. Дополнение равно 1−0,58=0,42.','A va B hodisalar o‘zaro istisno, P(A)=0.27 va P(B)=0.31. Hech biri sodir bo‘lmaslik ehtimoli qancha?','["0.58","0.42","0.04","0.69"]','O‘zaro istisno hodisalar uchun P(A∪B)=0.27+0.31=0.58. To‘ldiruvchi ehtimol 1−0.58=0.42.',90)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,'P5 Annual reserve',s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P5:p5_aw05_08_annual_reserve_topup_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw05_08_annual_reserve_topup_draft_v1:'||s.content_key);

with keys(content_key,skill_code,reserve_role,meta_id,official_ref,book_ref) as (values
('P5CNT01-D02','P5-CNT-01','diagnostic',59128,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT01-D03','P5-CNT-01','diagnostic',59129,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT01-R03','P5-CNT-01','retest',59130,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT01-R04','P5-CNT-01','retest',59131,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT01-M02','P5-CNT-01','mixed',59132,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT02-D02','P5-CNT-02','diagnostic',59133,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT02-D03','P5-CNT-02','diagnostic',59134,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT02-R03','P5-CNT-02','retest',59135,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT02-R04','P5-CNT-02','retest',59136,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT02-M02','P5-CNT-02','mixed',59137,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT03-D02','P5-CNT-03','diagnostic',59138,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT03-D03','P5-CNT-03','diagnostic',59139,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT03-R03','P5-CNT-03','retest',59140,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT03-R04','P5-CNT-03','retest',59141,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT03-M02','P5-CNT-03','mixed',59142,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT04-D02','P5-CNT-04','diagnostic',59143,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT04-D03','P5-CNT-04','diagnostic',59144,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT04-R03','P5-CNT-04','retest',59145,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT04-R04','P5-CNT-04','retest',59146,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5CNT04-M02','P5-CNT-04','mixed',59147,'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations','Complete Probability & Statistics 1, Ch6 Permutations and combinations pp.98-111 (mapping only)'),
('P5PRO01-D02','P5-PRO-01','diagnostic',59148,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO01-D03','P5-PRO-01','diagnostic',59149,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO01-R03','P5-PRO-01','retest',59150,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO01-R04','P5-PRO-01','retest',59151,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO01-M02','P5-PRO-01','mixed',59152,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO03-D02','P5-PRO-03','diagnostic',59153,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO03-D03','P5-PRO-03','diagnostic',59154,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO03-R03','P5-PRO-03','retest',59155,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO03-R04','P5-PRO-03','retest',59156,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO03-M02','P5-PRO-03','mixed',59157,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)')
)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,
 reserve_role,exposure_state,lifecycle_state,originality_attestation,provenance_note,
 official_scope_ref,coursebook_mapping_ref,copyright_status,qa_scope_status,qa_math_status,
 qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select k.meta_id,4808,k.content_key,q.id,k.skill_code,'{}'::text[],k.reserve_role,'withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'AW5-8 annual reserve top-up for future diagnostic, delayed-retest and transfer depth. It does not reinterpret any existing learner evidence.',
 k.official_ref,k.book_ref,'pending','pending','pending','pending','pending',
 case when k.reserve_role='diagnostic' then 'pending' else 'not_applicable' end,
 md5(concat_ws(chr(31),
   q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
   coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
   coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
   coalesce(q.image_url,''),coalesce(q.is_active::text,''),
   coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
   coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
   coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
   coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')
 ))
from keys k join public.questions q
 on q.book_ref='ExamPrep:P5:p5_aw05_08_annual_reserve_topup_draft_v1:'||k.content_key
on conflict(content_version_id,content_key) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int;
begin
 if (select status from private.exam_prep_content_versions where id=4808)<>'draft'
    or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4808)<>30
    or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4808 and reserve_role='diagnostic')<>12
    or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4808 and reserve_role='retest')<>12
    or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4808 and reserve_role='mixed')<>6
 then raise exception 'aw05_08_annual_reserve_p5_draft cardinality/state failure'; end if;

 select count(*) into v_bad from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
 where m.content_version_id=4808 and (
   m.lifecycle_state<>'draft' or m.exposure_state<>'withheld'
   or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
   or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
   or q.is_active or q.quality_status<>'draft'
   or nullif(btrim(q.question_text_en),'') is null or nullif(btrim(q.question_text_ru),'') is null or nullif(btrim(q.question_text_uz),'') is null
   or nullif(btrim(q.explanation_en),'') is null or nullif(btrim(q.explanation_ru),'') is null or nullif(btrim(q.explanation_uz),'') is null
 );
 if v_bad<>0 then raise exception 'aw05_08_annual_reserve_p5_draft governance/exposure rows=%',v_bad; end if;

 select
   count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
   count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D')
 into v_a,v_b,v_c,v_d
 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
 where m.content_version_id=4808 and m.reserve_role='diagnostic';
 if (v_a,v_b,v_c,v_d)<>(3,3,3,3) then
   raise exception 'aw05_08_annual_reserve_p5_draft diagnostic answer balance A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
 end if;

 if exists(
   select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
   join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4808
   join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
   join public.questions oldq on oldq.id=oldm.question_id
   where m.content_version_id=4808
     and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
 ) then raise exception 'aw05_08_annual_reserve_p5_draft exact published stem duplicate'; end if;

 if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4808)
    or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4808)
    or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4808)
 then raise exception 'aw05_08_annual_reserve_p5_draft unexpected history'; end if;
end
$postcheck$;

commit;
