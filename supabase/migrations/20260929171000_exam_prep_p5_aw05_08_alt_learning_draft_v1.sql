-- AW5-8 supplemental learning pack draft for P5.
-- DRAFT ONLY: no learner exposure, QA self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active') then
    raise exception 'aw05_08_alt_p5_draft canonical program missing';
  end if;
  if exists(select 1 from private.exam_prep_content_versions where id=4806 and content_version<>'p5_aw05_08_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15618 and 15623 and content_version_id<>4806)
     or exists(select 1 from private.exam_prep_assessments where id between 35333 and 35338 and content_version_id<>4806)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59070 and 59087 and content_version_id<>4806)
  then raise exception 'aw05_08_alt_p5_draft reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4806,pv.id,'p5_aw05_08_alt_learning_draft_v1','P5',
 'P5 AW5-8 supplemental learning pack draft v1','draft',
 'Original iClub-authored supplemental learning content. Official Cambridge 9709 scope and Complete Probability & Statistics 1 mappings define learning objectives only; no protected source question, solution, diagram or mark-scheme wording is copied. Independent academic, language, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict (program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P5CNT01-A01','P5-CNT-01','P5 Permutations and combinations','medium','mcq','Ten students are available. A president and a treasurer are chosen. How many ordered outcomes are possible?','["90","45","100","20"]','A','The two offices are different, so order matters: 10 choices for president and then 9 for treasurer, giving 10×9=90.','Есть 10 учеников. Выбирают президента и казначея. Сколько возможно упорядоченных исходов?','["90","45","100","20"]','Должности различаются, поэтому порядок важен: 10 вариантов для президента и затем 9 для казначея, всего 10×9=90.','10 nafar o‘quvchi bor. Prezident va xazinachi tanlanadi. Nechta tartibli natija mumkin?','["90","45","100","20"]','Vazifalar turlicha, shuning uchun tartib muhim: prezident uchun 10, xazinachi uchun 9 tanlov, jami 10×9=90.',50),
('P5CNT01-A02','P5-CNT-01','P5 Permutations and combinations','medium','mcq','A 3-person committee is selected from 8 students. No roles are assigned. How many committees are possible?','["336","56","24","512"]','B','Order does not matter, so use a combination: 8C3=56.','Из 8 учеников выбирают комитет из 3 человек без распределения ролей. Сколько комитетов возможно?','["336","56","24","512"]','Порядок не важен, поэтому используем сочетания: 8C3=56.','8 nafar o‘quvchidan 3 kishilik qo‘mita tanlanadi, vazifalar berilmaydi. Nechta qo‘mita mumkin?','["336","56","24","512"]','Tartib muhim emas, shuning uchun kombinatsiya ishlatiladi: 8C3=56.',50),
('P5CNT01-A03','P5-CNT-01','P5 Permutations and combinations','hard','input','From 9 students, a 4-person team is selected and then one of the four is appointed captain. Enter the number of possible outcomes.','[]','504','There are 9C4=126 possible teams. Each team has 4 choices for captain, so 126×4=504.','Из 9 учеников выбирают команду из 4 человек, затем одного из четырёх назначают капитаном. Введите число возможных исходов.','[]','Команд 9C4=126. В каждой команде 4 варианта выбора капитана, поэтому 126×4=504.','9 nafar o‘quvchidan 4 kishilik jamoa tanlanadi, so‘ng ulardan biri sardor qilinadi. Mumkin bo‘lgan natijalar sonini kiriting.','[]','9C4=126 ta jamoa bor. Har bir jamoada sardor uchun 4 tanlov, demak 126×4=504.',65),
('P5CNT02-A01','P5-CNT-02','P5 Permutations and combinations','medium','mcq','A 4-digit code is formed from the digits 1 to 7 without repetition. How many codes are possible?','["2401","210","840","28"]','C','The positions are ordered and digits cannot repeat, so the count is 7P4=7×6×5×4=840.','Четырёхзначный код составляют из цифр от 1 до 7 без повторений. Сколько кодов возможно?','["2401","210","840","28"]','Позиции упорядочены, повторений нет, поэтому число кодов равно 7P4=7×6×5×4=840.','1 dan 7 gacha raqamlardan takrorlanmasdan 4 xonali kod tuziladi. Nechta kod mumkin?','["2401","210","840","28"]','Joylar tartibli va raqamlar takrorlanmaydi, shuning uchun 7P4=7×6×5×4=840.',55),
('P5CNT02-A02','P5-CNT-02','P5 Permutations and combinations','medium','mcq','Five of 8 distinct paintings are chosen and arranged from left to right. How many displays are possible?','["56","120","40320","6720"]','D','Choosing and arranging five distinct objects from eight gives 8P5=8×7×6×5×4=6720.','Из 8 разных картин выбирают 5 и располагают слева направо. Сколько экспозиций возможно?','["56","120","40320","6720"]','Выбор и упорядочивание 5 разных объектов из 8 даёт 8P5=8×7×6×5×4=6720.','8 ta turli rasmdan 5 tasi tanlanib, chapdan o‘ngga tartiblanadi. Nechta ko‘rinish mumkin?','["56","120","40320","6720"]','8 ta turli obyekt ichidan 5 tasini tanlab tartiblash 8P5=8×7×6×5×4=6720 beradi.',55),
('P5CNT02-A03','P5-CNT-02','P5 Permutations and combinations','medium','input','Three ordered positions are filled from 10 distinct candidates without repetition. Enter the number of outcomes.','[]','720','The count is 10P3=10×9×8=720.','Три упорядоченные позиции заполняют из 10 разных кандидатов без повторений. Введите число исходов.','[]','Число исходов равно 10P3=10×9×8=720.','10 ta turli nomzoddan 3 ta tartibli o‘rin takrorlanmasdan to‘ldiriladi. Natijalar sonini kiriting.','[]','Natijalar soni 10P3=10×9×8=720.',45),
('P5CNT03-A01','P5-CNT-03','P5 Permutations and combinations','medium','mcq','How many distinct arrangements of the letters in SUCCESS are possible?','["840","420","210","5040"]','B','SUCCESS has 7 letters with S repeated 3 times and C repeated 2 times. The number is 7!/(3!2!)=420.','Сколько различных перестановок можно составить из букв слова SUCCESS?','["840","420","210","5040"]','В слове SUCCESS 7 букв, S повторяется 3 раза, C — 2 раза. Число перестановок 7!/(3!2!)=420.','SUCCESS so‘zidagi harflardan nechta turli tartib tuzish mumkin?','["840","420","210","5040"]','SUCCESS so‘zida 7 ta harf bor, S 3 marta, C 2 marta takrorlanadi. Soni 7!/(3!2!)=420.',60),
('P5CNT03-A02','P5-CNT-03','P5 Permutations and combinations','medium','mcq','How many distinct strings can be formed using exactly the symbols 1,1,1,2,2,3?','["60","120","20","720"]','A','There are 6 positions, with three identical 1s and two identical 2s. The count is 6!/(3!2!)=60.','Сколько различных строк можно составить, используя ровно символы 1,1,1,2,2,3?','["60","120","20","720"]','Есть 6 позиций, три одинаковые единицы и две одинаковые двойки. Число строк 6!/(3!2!)=60.','Aynan 1,1,1,2,2,3 belgilaridan nechta turli satr tuzish mumkin?','["60","120","20","720"]','6 ta joy bor, uchta 1 va ikkita 2 bir xil. Soni 6!/(3!2!)=60.',55),
('P5CNT03-A03','P5-CNT-03','P5 Permutations and combinations','medium','input','Enter the number of distinct arrangements of the letters in COCOA.','[]','30','COCOA has 5 letters with C repeated twice and O repeated twice, so the count is 5!/(2!2!)=30.','Введите число различных перестановок букв слова COCOA.','[]','В COCOA 5 букв, C повторяется дважды и O повторяется дважды, поэтому 5!/(2!2!)=30.','COCOA so‘zidagi harflarning turli tartiblari sonini kiriting.','[]','COCOA da 5 ta harf bor, C ikki marta va O ikki marta takrorlanadi. Shuning uchun 5!/(2!2!)=30.',50),
('P5CNT04-A01','P5-CNT-04','P5 Permutations and combinations','medium','mcq','Six distinct people stand in a row. A and B must stand together. How many arrangements are possible?','["120","720","480","240"]','D','Treat A and B as one block. There are 5 units to arrange, giving 5!, and A,B can swap inside the block: 2×5!=240.','Шесть разных людей стоят в ряд. A и B должны стоять рядом. Сколько расстановок возможно?','["120","720","480","240"]','Считаем A и B одним блоком. Получаем 5 объектов, которые можно расположить 5! способами, а внутри блока A и B можно поменять местами: 2×5!=240.','Olti xil odam qatorga turadi. A va B yonma-yon turishi shart. Nechta tartib mumkin?','["120","720","480","240"]','A va B ni bitta blok deb olamiz. 5 ta birlikni 5! usulda joylashtiramiz, blok ichida A va B 2 usulda almashadi: 2×5!=240.',60),
('P5CNT04-A02','P5-CNT-04','P5 Permutations and combinations','hard','mcq','Seven distinct people stand in a row. A and B must not stand together. How many arrangements are possible?','["1440","5040","3600","720"]','C','All arrangements give 7!=5040. Arrangements with A and B together are 2×6!=1440. Therefore 5040−1440=3600.','Семь разных людей стоят в ряд. A и B не должны стоять рядом. Сколько расстановок возможно?','["1440","5040","3600","720"]','Всего 7!=5040 расстановок. Рядом A и B стоят в 2×6!=1440 случаях. Поэтому 5040−1440=3600.','Yetti xil odam qatorga turadi. A va B yonma-yon turmasligi kerak. Nechta tartib mumkin?','["1440","5040","3600","720"]','Jami 7!=5040 tartib. A va B yonma-yon bo‘lganlari 2×6!=1440. Demak 5040−1440=3600.',65),
('P5CNT04-A03','P5-CNT-04','P5 Permutations and combinations','hard','input','Eight distinct people stand in a row. C is fixed in the first position and A and B must stand together. Enter the number of arrangements.','[]','1440','With C fixed, six other individuals plus the AB block make 6 units. They can be arranged in 6! ways, and A,B can swap, giving 2×6!=1440.','Восемь разных людей стоят в ряд. C закреплён на первом месте, а A и B должны стоять рядом. Введите число расстановок.','[]','После фиксации C остаются шесть других людей и блок AB — всего 6 объектов. Они располагаются 6! способами, а A и B внутри блока можно поменять местами: 2×6!=1440.','Sakkiz xil odam qatorga turadi. C birinchi o‘rinda turadi, A va B esa yonma-yon bo‘lishi kerak. Tartiblar sonini kiriting.','[]','C birinchi joyda mahkamlanganidan keyin qolgan olti odam va AB bloki jami 6 birlik bo‘ladi. Ular 6! usulda, A va B blok ichida 2 usulda joylashadi: 2×6!=1440.',65),
('P5PRO01-A01','P5-PRO-01','P5 Probability','medium','mcq','A fair coin is tossed and an independent fair spinner with 4 equally likely sectors is spun. How many equiprobable ordered outcomes are in the sample space?','["8","6","4","16"]','A','There are 2 coin outcomes and 4 spinner outcomes, so the product rule gives 2×4=8 equiprobable ordered outcomes.','Подбрасывают честную монету и независимо вращают честный секторный диск с 4 равновероятными секторами. Сколько равновероятных упорядоченных исходов в пространстве исходов?','["8","6","4","16"]','У монеты 2 исхода, у диска 4 исхода, поэтому по правилу произведения получаем 2×4=8 равновероятных упорядоченных исходов.','Adolatli tanga tashlanadi va mustaqil ravishda 4 teng ehtimolli sektorga ega adolatli aylantirgich aylantiriladi. Namunalar fazosida nechta teng ehtimolli tartibli natija bor?','["8","6","4","16"]','Tangada 2, aylantirgichda 4 natija bor. Ko‘paytirish qoidasiga ko‘ra 2×4=8 teng ehtimolli tartibli natija.',55),
('P5PRO01-A02','P5-PRO-01','P5 Probability','medium','mcq','Two distinguishable fair six-sided dice are rolled and then a fair coin is tossed. How many equiprobable ordered outcomes are possible?','["36","72","24","144"]','B','The dice give 6×6=36 ordered outcomes and the coin doubles this, giving 36×2=72.','Бросают два различимых честных шестигранных кубика, затем честную монету. Сколько равновероятных упорядоченных исходов возможно?','["36","72","24","144"]','Кубики дают 6×6=36 упорядоченных исходов, монета удваивает это число: 36×2=72.','Ikki farqlanadigan adolatli olti qirrali kubik tashlanadi, so‘ng adolatli tanga tashlanadi. Nechta teng ehtimolli tartibli natija mumkin?','["36","72","24","144"]','Kubiklar 6×6=36 tartibli natija beradi, tanga esa bu sonni ikki baravar qiladi: 36×2=72.',55),
('P5PRO01-A03','P5-PRO-01','P5 Probability','medium','input','One fair spinner has 3 equally likely sectors and another independent fair spinner has 5 equally likely sectors. Enter the number of equiprobable ordered outcomes.','[]','15','Each outcome is an ordered pair. By the product rule the sample space has 3×5=15 outcomes.','Один честный диск имеет 3 равновероятных сектора, другой независимый честный диск — 5. Введите число равновероятных упорядоченных исходов.','[]','Каждый исход — упорядоченная пара. По правилу произведения пространство исходов содержит 3×5=15 исходов.','Bitta adolatli aylantirgichda 3 teng ehtimolli sektor, ikkinchi mustaqil aylantirgichda 5 sektor bor. Teng ehtimolli tartibli natijalar sonini kiriting.','[]','Har bir natija tartibli juftlik. Ko‘paytirish qoidasiga ko‘ra namunalar fazosida 3×5=15 natija bor.',50),
('P5PRO03-A01','P5-PRO-03','P5 Probability','medium','mcq','If P(A)=0.62, what is P(Aᶜ)?','["0.62","1.62","0.38","0.48"]','C','A and its complement cover the whole sample space, so P(Aᶜ)=1−0.62=0.38.','Если P(A)=0,62, чему равно P(Aᶜ)?','["0,62","1,62","0,38","0,48"]','A и его дополнение образуют всё пространство исходов, поэтому P(Aᶜ)=1−0,62=0,38.','Agar P(A)=0.62 bo‘lsa, P(Aᶜ) qancha?','["0.62","1.62","0.38","0.48"]','A hodisa va uning to‘ldiruvchisi butun namunalar fazosini tashkil qiladi, shuning uchun P(Aᶜ)=1−0.62=0.38.',45),
('P5PRO03-A02','P5-PRO-03','P5 Probability','medium','mcq','P(A)=0.45, P(B)=0.50 and P(A∩B)=0.18. Find P(A∪B).','["0.95","0.27","0.68","0.77"]','D','Use P(A∪B)=P(A)+P(B)−P(A∩B)=0.45+0.50−0.18=0.77.','P(A)=0,45, P(B)=0,50 и P(A∩B)=0,18. Найдите P(A∪B).','["0,95","0,27","0,68","0,77"]','Используем P(A∪B)=P(A)+P(B)−P(A∩B)=0,45+0,50−0,18=0,77.','P(A)=0.45, P(B)=0.50 va P(A∩B)=0.18. P(A∪B) ni toping.','["0.95","0.27","0.68","0.77"]','P(A∪B)=P(A)+P(B)−P(A∩B)=0.45+0.50−0.18=0.77.',50),
('P5PRO03-A03','P5-PRO-03','P5 Probability','hard','input','P(A)=0.41, P(B)=0.46 and P(A∪B)=0.72. Enter P(A∩B).','[]','0.15','Rearrange the addition rule: P(A∩B)=0.41+0.46−0.72=0.15.','P(A)=0,41, P(B)=0,46 и P(A∪B)=0,72. Введите P(A∩B).','[]','Переставляем члены формулы сложения: P(A∩B)=0,41+0,46−0,72=0,15.','P(A)=0.41, P(B)=0.46 va P(A∪B)=0.72. P(A∩B) ni kiriting.','[]','Qo‘shish formulasini qayta tuzamiz: P(A∩B)=0.41+0.46−0.72=0.15.',55)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,s.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P5:p5_aw05_08_alt_learning_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw05_08_alt_learning_draft_v1:'||s.content_key);

insert into private.exam_prep_written_tasks(
 id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
 prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
 lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15618,4806,'P5CNT01-AW06','P5','P5-CNT-01','{}','v1','Nine students are available. (a) A chair and a secretary are chosen. (b) A 2-person committee is chosen with no roles. Calculate both numbers of outcomes and explain exactly why the answers differ.','Есть 9 учеников. (a) Выбирают председателя и секретаря. (b) Выбирают комитет из 2 человек без ролей. Найдите оба числа исходов и точно объясните, почему ответы различаются.','9 nafar o‘quvchi bor. (a) Rais va kotib tanlanadi. (b) Vazifalarsiz 2 kishilik qo‘mita tanlanadi. Har ikkala natijalar sonini hisoblang va nega javoblar farq qilishini aniq tushuntiring.','{"criteria":[{"id":"ordered","rule":"Calculates 9P2=72 for chair and secretary.","marks":2},{"id":"unordered","rule":"Calculates 9C2=36 for the committee.","marks":2},{"id":"reason","rule":"Explains that swapping the same two people creates a new office assignment in (a) but not a new committee in (b).","marks":2}],"max_marks":6}'::jsonb,'State first whether order changes the outcome, then choose the counting rule. Do not use the same rule for both parts.','Сначала определите, меняет ли порядок исход, затем выберите правило подсчёта. Не используйте одно и то же правило для обеих частей.','Avval tartib natijani o‘zgartiradimi, aniqlang; keyin sanash qoidasini tanlang. Ikki qism uchun bir xil qoidadan foydalanmang.','draft','pending','pending','pending','pending'),
(15619,4806,'P5CNT02-AW06','P5','P5-CNT-02','{}','v1','Seven distinct books are available, but only four positions are on a display shelf. Find the number of possible displays in two ways: using permutation notation and using a product. Explain why no division by 4! is made.','Есть 7 разных книг, но на полке только 4 места. Найдите число возможных расстановок двумя способами: через обозначение перестановок и через произведение. Объясните, почему делить на 4! не нужно.','7 ta turli kitob bor, lekin ko‘rgazma tokchasida faqat 4 ta joy bor. Mumkin bo‘lgan tartiblar sonini ikki usulda toping: permutatsiya belgisi va ko‘paytma orqali. Nega 4! ga bo‘linmasligini tushuntiring.','{"criteria":[{"id":"notation","rule":"Writes 7P4.","marks":1},{"id":"product","rule":"Writes 7×6×5×4.","marks":1},{"id":"value","rule":"Obtains 840.","marks":2},{"id":"reason","rule":"Explains that the four shelf positions are ordered, so different orders are different displays.","marks":2}],"max_marks":6}'::jsonb,'Check whether changing left-to-right order creates a different display. If it does, the positions are ordered.','Проверьте, создаёт ли изменение порядка слева направо новую экспозицию. Если да, позиции упорядочены.','Chapdan o‘ngga tartibni o‘zgartirish boshqa ko‘rinish beradimi, tekshiring. Bersа, joylar tartibli.','draft','pending','pending','pending','pending'),
(15620,4806,'P5CNT03-AW06','P5','P5-CNT-03','{}','v1','Find the number of distinct arrangements of the letters in BALLOON. Show how repeated letters change the factorial count and explain each divisor.','Найдите число различных перестановок букв слова BALLOON. Покажите, как повторяющиеся буквы изменяют факториальный подсчёт, и объясните каждый делитель.','BALLOON so‘zidagi harflarning turli tartiblari sonini toping. Takrorlangan harflar faktorial sanashni qanday o‘zgartirishini ko‘rsating va har bir bo‘luvchini tushuntiring.','{"criteria":[{"id":"raw","rule":"Starts from 7! arrangements.","marks":1},{"id":"repeat","rule":"Identifies L repeated twice and O repeated twice.","marks":1},{"id":"formula","rule":"Uses 7!/(2!2!).","marks":2},{"id":"value","rule":"Obtains 1260.","marks":1},{"id":"reason","rule":"Explains division removes overcount from swapping identical letters.","marks":1}],"max_marks":6}'::jsonb,'List the multiplicity of every repeated letter before writing the denominator.','Сначала выпишите число повторений каждой повторяющейся буквы, затем составьте знаменатель.','Maxrajni yozishdan oldin har bir takrorlangan harf nechta ekanini yozib chiqing.','draft','pending','pending','pending','pending'),
(15621,4806,'P5CNT04-AW06','P5','P5-CNT-04','{}','v1','Seven distinct people stand in a row. A and B must stand together, and C must stand at one of the two ends. Find the number of arrangements and explain how both restrictions are enforced without double counting.','Семь разных людей стоят в ряд. A и B должны стоять рядом, а C должен находиться на одном из двух концов. Найдите число расстановок и объясните, как учесть оба ограничения без двойного счёта.','Yetti xil odam qatorga turadi. A va B yonma-yon turishi, C esa ikki chetdan birida turishi kerak. Tartiblar sonini toping va ikkala cheklovni takror sanamasdan qanday hisobga olishni tushuntiring.','{"criteria":[{"id":"C","rule":"Uses 2 choices for the end occupied by C.","marks":1},{"id":"block","rule":"Treats A and B as one block in the remaining six positions.","marks":1},{"id":"arrange","rule":"Counts 5! arrangements of the AB block with four other people after C is fixed.","marks":2},{"id":"inside","rule":"Uses 2 internal orders for A and B.","marks":1},{"id":"value","rule":"Obtains 2×5!×2=480.","marks":1}],"max_marks":6}'::jsonb,'Fix the end for C first. Then count the remaining six-position row using an AB block, and finally allow A and B to swap.','Сначала зафиксируйте конец для C. Затем считайте оставшийся ряд из шести мест, используя блок AB, и в конце учтите перестановку A и B внутри блока.','Avval C uchun chetni tanlang. Keyin qolgan olti joyda AB blokidan foydalanib sanang va oxirida A bilan B ning blok ichida almashishini hisobga oling.','draft','pending','pending','pending','pending'),
(15622,4806,'P5PRO01-AW06','P5','P5-PRO-01','{}','v1','A fair coin is tossed and an independent fair spinner labelled 1, 2 and 3 is spun. List the complete ordered sample space. Then find the probability of the event: the coin shows H or the spinner shows 2.','Подбрасывают честную монету и независимо вращают честный диск с метками 1, 2 и 3. Выпишите полное упорядоченное пространство исходов. Затем найдите вероятность события: выпала H или на диске выпало 2.','Adolatli tanga tashlanadi va mustaqil ravishda 1, 2, 3 deb belgilangan adolatli aylantirgich aylantiriladi. To‘liq tartibli namunalar fazosini yozing. So‘ng hodisa ehtimolini toping: tangada H chiqadi yoki aylantirgichda 2 chiqadi.','{"criteria":[{"id":"space","rule":"Lists exactly six ordered outcomes (H,1),(H,2),(H,3),(T,1),(T,2),(T,3).","marks":2},{"id":"event","rule":"Identifies four favourable outcomes: (H,1),(H,2),(H,3),(T,2).","marks":2},{"id":"prob","rule":"Obtains probability 4/6=2/3.","marks":1},{"id":"overlap","rule":"Explains (H,2) is counted once in the union.","marks":1}],"max_marks":6}'::jsonb,'Write every ordered pair before counting the event, and check that the overlap outcome is not counted twice.','Сначала выпишите все упорядоченные пары, затем считайте событие и убедитесь, что пересечение не посчитано дважды.','Hodisani sanashdan oldin barcha tartibli juftliklarni yozing va kesishma natija ikki marta sanalmaganini tekshiring.','draft','pending','pending','pending','pending'),
(15623,4806,'P5PRO03-AW06','P5','P5-PRO-03','{}','v1','For events A and B, P(A)=0.58, P(B)=0.47 and P(A∩B)=0.21. Find P(A∪B) and the probability that neither A nor B occurs. Explain why the intersection is subtracted once.','Для событий A и B даны P(A)=0,58, P(B)=0,47 и P(A∩B)=0,21. Найдите P(A∪B) и вероятность того, что не произойдёт ни A, ни B. Объясните, почему пересечение вычитается один раз.','A va B hodisalar uchun P(A)=0.58, P(B)=0.47 va P(A∩B)=0.21. P(A∪B) ni va A ham, B ham sodir bo‘lmaslik ehtimolini toping. Nega kesishma bir marta ayirilishini tushuntiring.','{"criteria":[{"id":"union","rule":"Uses 0.58+0.47-0.21 and obtains 0.84.","marks":2},{"id":"neither","rule":"Uses complement to obtain 1-0.84=0.16.","marks":2},{"id":"reason","rule":"Explains the intersection is included in both P(A) and P(B), so adding them counts it twice.","marks":2}],"max_marks":6}'::jsonb,'Use the addition rule first, then take the complement of the union for neither event.','Сначала примените правило сложения, затем возьмите дополнение объединения для события «ни A, ни B».','Avval qo‘shish qoidasidan foydalaning, keyin A ham, B ham emas hodisasi uchun birlashmaning to‘ldiruvchisini oling.','draft','pending','pending','pending','pending')
on conflict (id) do nothing;

with src(content_key,skill_code,meta_id) as (values
('P5CNT01-A01','P5-CNT-01',59070),
('P5CNT01-A02','P5-CNT-01',59071),
('P5CNT01-A03','P5-CNT-01',59072),
('P5CNT02-A01','P5-CNT-02',59073),
('P5CNT02-A02','P5-CNT-02',59074),
('P5CNT02-A03','P5-CNT-02',59075),
('P5CNT03-A01','P5-CNT-03',59076),
('P5CNT03-A02','P5-CNT-03',59077),
('P5CNT03-A03','P5-CNT-03',59078),
('P5CNT04-A01','P5-CNT-04',59079),
('P5CNT04-A02','P5-CNT-04',59080),
('P5CNT04-A03','P5-CNT-04',59081),
('P5PRO01-A01','P5-PRO-01',59082),
('P5PRO01-A02','P5-PRO-01',59083),
('P5PRO01-A03','P5-PRO-01',59084),
('P5PRO03-A01','P5-PRO-03',59085),
('P5PRO03-A02','P5-PRO-03',59086),
('P5PRO03-A03','P5-PRO-03',59087)
), cv as (select id from private.exam_prep_content_versions where id=4806)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,cv.id,s.content_key,qn.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'Supplemental AW5-8 learning draft authored from the canonical skill intent with independent values and contexts, separate from the existing teaching pack.',
 case s.skill_code
 when 'P5-CNT-01' then 'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations'
 when 'P5-CNT-02' then 'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations'
 when 'P5-CNT-03' then 'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations'
 when 'P5-CNT-04' then 'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations'
 when 'P5-PRO-01' then 'Cambridge 9709 2026-2027 v4; P5 5.3 Probability'
 when 'P5-PRO-03' then 'Cambridge 9709 2026-2027 v4; P5 5.3 Probability'
 end,
 case s.skill_code
 when 'P5-CNT-01' then 'Complete Probability & Statistics 1, Ch6 pp.98-111 (mapping only)'
 when 'P5-CNT-02' then 'Complete Probability & Statistics 1, Ch6 pp.98-111 (mapping only)'
 when 'P5-CNT-03' then 'Complete Probability & Statistics 1, Ch6 pp.98-111 (mapping only)'
 when 'P5-CNT-04' then 'Complete Probability & Statistics 1, Ch6 pp.98-111 (mapping only)'
 when 'P5-PRO-01' then 'Complete Probability & Statistics 1, Ch4 pp.63-82 (mapping only)'
 when 'P5-PRO-03' then 'Complete Probability & Statistics 1, Ch4 pp.63-82 (mapping only)'
 end,
 'pending','pending','pending','pending','pending','not_applicable',
 md5(concat_ws(chr(31),
   qn.id::text,qn.subject_id::text,coalesce(qn.topic,''),coalesce(qn.subtopic,''),coalesce(qn.difficulty,''),coalesce(qn.qtype,''),
   coalesce(qn.question_text,''),coalesce(qn.options_text,''),coalesce(qn.correct_answer,''),coalesce(qn.explanation,''),
   coalesce(qn.image_url,''),coalesce(qn.is_active::text,''),coalesce(qn.question_text_ru,''),coalesce(qn.question_text_uz,''),
   coalesce(qn.question_text_en,''),coalesce(qn.options_text_ru,''),coalesce(qn.options_text_uz,''),coalesce(qn.options_text_en,''),
   coalesce(qn.explanation_ru,''),coalesce(qn.explanation_uz,''),coalesce(qn.explanation_en,''),coalesce(qn.book_ref,''),
   coalesce(qn.time_limit_sec::text,''),coalesce(qn.quality_flag,''),coalesce(qn.quality_status,'')
 ))
from cv cross join src s
join public.questions qn on qn.book_ref='ExamPrep:P5:p5_aw05_08_alt_learning_draft_v1:'||s.content_key
on conflict (id) do nothing;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35333,4806,'P5-CNT-01-learning-alt-02','v1','P5','learning','draft','Counting: order or selection - supplemental learning','Подсчёт: порядок или выбор — дополнительное обучение','Sanash: tartib yoki tanlash — qo‘shimcha o‘rganish'),
(35334,4806,'P5-CNT-02-learning-alt-02','v1','P5','learning','draft','Counting: ordered arrangements - supplemental learning','Подсчёт: упорядоченные расстановки — дополнительное обучение','Sanash: tartibli joylashtirish — qo‘shimcha o‘rganish'),
(35335,4806,'P5-CNT-03-learning-alt-02','v1','P5','learning','draft','Counting: repeated objects - supplemental learning','Подсчёт: повторяющиеся объекты — дополнительное обучение','Sanash: takrorlanuvchi obyektlar — qo‘shimcha o‘rganish'),
(35336,4806,'P5-CNT-04-learning-alt-02','v1','P5','learning','draft','Counting: restrictions - supplemental learning','Подсчёт: ограничения — дополнительное обучение','Sanash: cheklovlar — qo‘shimcha o‘rganish'),
(35337,4806,'P5-PRO-01-learning-alt-02','v1','P5','learning','draft','Probability: sample spaces - supplemental learning','Вероятность: пространства исходов — дополнительное обучение','Ehtimollik: namunalar fazosi — qo‘shimcha o‘rganish'),
(35338,4806,'P5-PRO-03-learning-alt-02','v1','P5','learning','draft','Probability: complement and addition rule - supplemental learning','Вероятность: дополнение и правило сложения — дополнительное обучение','Ehtimollik: to‘ldiruvchi va qo‘shish qoidasi — qo‘shimcha o‘rganish')
on conflict (id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35333,1,'P5CNT01-A01',null::bigint,'P5-CNT-01'),
(35333,2,'P5CNT01-A02',null,'P5-CNT-01'),
(35333,3,'P5CNT01-A03',null,'P5-CNT-01'),
(35333,4,null,15618,'P5-CNT-01'),
(35334,1,'P5CNT02-A01',null::bigint,'P5-CNT-02'),
(35334,2,'P5CNT02-A02',null,'P5-CNT-02'),
(35334,3,'P5CNT02-A03',null,'P5-CNT-02'),
(35334,4,null,15619,'P5-CNT-02'),
(35335,1,'P5CNT03-A01',null::bigint,'P5-CNT-03'),
(35335,2,'P5CNT03-A02',null,'P5-CNT-03'),
(35335,3,'P5CNT03-A03',null,'P5-CNT-03'),
(35335,4,null,15620,'P5-CNT-03'),
(35336,1,'P5CNT04-A01',null::bigint,'P5-CNT-04'),
(35336,2,'P5CNT04-A02',null,'P5-CNT-04'),
(35336,3,'P5CNT04-A03',null,'P5-CNT-04'),
(35336,4,null,15621,'P5-CNT-04'),
(35337,1,'P5PRO01-A01',null::bigint,'P5-PRO-01'),
(35337,2,'P5PRO01-A02',null,'P5-PRO-01'),
(35337,3,'P5PRO01-A03',null,'P5-PRO-01'),
(35337,4,null,15622,'P5-PRO-01'),
(35338,1,'P5PRO03-A01',null::bigint,'P5-PRO-03'),
(35338,2,'P5PRO03-A02',null,'P5-PRO-03'),
(35338,3,'P5PRO03-A03',null,'P5-PRO-03'),
(35338,4,null,15623,'P5-PRO-03')
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select i.assessment_id,i.item_order,qn.id,i.written_id,i.skill_code,
 case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions qn on i.content_key is not null
 and qn.book_ref='ExamPrep:P5:p5_aw05_08_alt_learning_draft_v1:'||i.content_key
on conflict (assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4806)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4806 and lifecycle_state='draft' and reserve_role='learning')<>18
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4806 and lifecycle_state='draft')<>6
     or (select count(*) from private.exam_prep_assessments where content_version_id=4806 and status='draft' and assessment_type='learning')<>6
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4806)<>24
  then raise exception 'aw05_08_alt_p5_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4806 and (
    m.exposure_state<>'withheld' or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or qn.is_active or qn.quality_status<>'draft'
  );
  if v_bad<>0 then raise exception 'aw05_08_alt_p5_draft exposure/QA boundary rows=%',v_bad; end if;

  select
    count(*) filter(where qn.correct_answer='A'),
    count(*) filter(where qn.correct_answer='B'),
    count(*) filter(where qn.correct_answer='C'),
    count(*) filter(where qn.correct_answer='D'),
    count(*) filter(where qn.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4806;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(3,3,3,3,6) then
    raise exception 'aw05_08_alt_p5_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions qn on qn.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4806
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4806
      and lower(regexp_replace(qn.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw05_08_alt_p5_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4806)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4806)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4806)
  then raise exception 'aw05_08_alt_p5_draft unexpected history'; end if;
end
$postcheck$;

commit;
