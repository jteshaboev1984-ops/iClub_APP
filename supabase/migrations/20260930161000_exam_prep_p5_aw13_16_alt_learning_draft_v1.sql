-- AW13-16 supplemental learning pack draft for P5.
-- DRAFT ONLY: no learner exposure, QA self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active') then
    raise exception 'aw13_16_alt_p5_draft canonical program missing';
  end if;
  if exists(select 1 from private.exam_prep_content_versions where id=4814 and content_version<>'p5_aw13_16_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15646 and 15652 and content_version_id<>4814)
     or exists(select 1 from private.exam_prep_assessments where id between 35429 and 35435 and content_version_id<>4814)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59294 and 59314 and content_version_id<>4814)
  then raise exception 'aw13_16_alt_p5_draft reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4814,pv.id,'p5_aw13_16_alt_learning_draft_v1','P5',
 'P5 AW13-16 supplemental learning pack draft v1','draft',
 'Original iClub-authored supplemental learning content. Official Cambridge 9709 scope and Complete Probability & Statistics 1 mappings define learning objectives only; no protected source question, solution, diagram or mark-scheme wording is copied. Independent academic, language, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P5PRO05-A01','P5-PRO-05','P5 Probability','medium','mcq','In a group of 50 students, 30 study Economics and 18 study both Economics and Chess. A student is known to study Economics. What is the probability that the student also studies Chess?','["3/5","9/25","18/50","5/6"]','A','Conditional on studying Economics, the relevant group has 30 students. Of these, 18 also study Chess, so the probability is 18/30=3/5.','В группе 50 учеников 30 изучают экономику, а 18 изучают и экономику, и шахматы. Известно, что случайно выбранный ученик изучает экономику. Какова вероятность, что он также занимается шахматами?','["3/5","9/25","18/50","5/6"]','При условии, что ученик изучает экономику, рассматриваем только 30 таких учеников. Из них 18 также занимаются шахматами, поэтому вероятность равна 18/30=3/5.','50 o‘quvchidan 30 tasi iqtisodiyot, 18 tasi esa ham iqtisodiyot, ham shaxmat bilan shug‘ullanadi. Tasodifiy tanlangan o‘quvchi iqtisodiyot o‘qishi ma’lum. Uning shaxmat bilan ham shug‘ullanish ehtimoli qancha?','["3/5","9/25","18/50","5/6"]','Iqtisodiyot o‘qishi sharti ostida 30 o‘quvchi ichidan qaraymiz. Ulardan 18 tasi shaxmat ham o‘ynaydi, demak ehtimol 18/30=3/5.',80),
('P5PRO05-A02','P5-PRO-05','P5 Probability','medium','mcq','Given P(A)=0.50, P(B)=0.40 and P(A∩B)=0.15, find P(A|B).','["0.30","0.375","0.60","0.75"]','B','P(A|B)=P(A∩B)/P(B)=0.15/0.40=0.375.','Даны P(A)=0,50, P(B)=0,40 и P(A∩B)=0,15. Найдите P(A|B).','["0,30","0,375","0,60","0,75"]','P(A|B)=P(A∩B)/P(B)=0,15/0,40=0,375.','P(A)=0.50, P(B)=0.40 va P(A∩B)=0.15. P(A|B) ni toping.','["0.30","0.375","0.60","0.75"]','P(A|B)=P(A∩B)/P(B)=0.15/0.40=0.375.',65),
('P5PRO05-A03','P5-PRO-05','P5 Probability','medium','input','P(A∩B)=0.24 and P(B)=0.80. Enter P(A|B).','[]','0.3','P(A|B)=0.24/0.80=0.30.','P(A∩B)=0,24 и P(B)=0,80. Введите P(A|B).','[]','P(A|B)=0,24/0,80=0,30.','P(A∩B)=0.24 va P(B)=0.80. P(A|B) ni kiriting.','[]','P(A|B)=0.24/0.80=0.30.',60),
('P5PRO06-A01','P5-PRO-06','P5 Probability','medium','mcq','A bag contains 5 red and 3 blue counters. Two counters are drawn without replacement. Find P(red first, then blue).','["5/21","3/14","15/56","5/8"]','C','P(red then blue)=5/8×3/7=15/56.','В мешке 5 красных и 3 синих фишки. Две фишки вытаскивают без возвращения. Найдите P(сначала красная, затем синяя).','["5/21","3/14","15/56","5/8"]','P(красная, затем синяя)=5/8×3/7=15/56.','Qopda 5 qizil va 3 ko‘k jeton bor. Ikki jeton qaytarmasdan olinadi. P(avval qizil, keyin ko‘k) ni toping.','["5/21","3/14","15/56","5/8"]','P(qizil, keyin ko‘k)=5/8×3/7=15/56.',70),
('P5PRO06-A02','P5-PRO-06','P5 Probability','hard','mcq','A process chooses route A with probability 0.4 and route B with probability 0.6. The probability of success is 0.7 after A and 0.2 after B. What is the overall probability of success?','["0.18","0.28","0.36","0.40"]','D','The success branches give 0.4×0.7+0.6×0.2=0.28+0.12=0.40.','Процесс выбирает маршрут A с вероятностью 0,4 и маршрут B с вероятностью 0,6. Вероятность успеха после A равна 0,7, после B — 0,2. Какова общая вероятность успеха?','["0,18","0,28","0,36","0,40"]','Суммируем ветви успеха: 0,4×0,7+0,6×0,2=0,28+0,12=0,40.','Jarayon A yo‘lini 0.4 ehtimol bilan, B yo‘lini 0.6 ehtimol bilan tanlaydi. A dan keyin muvaffaqiyat ehtimoli 0.7, B dan keyin 0.2. Umumiy muvaffaqiyat ehtimoli qancha?','["0.18","0.28","0.36","0.40"]','Muvaffaqiyat shoxlarini qo‘shamiz: 0.4×0.7+0.6×0.2=0.28+0.12=0.40.',80),
('P5PRO06-A03','P5-PRO-06','P5 Probability','medium','input','A bag contains 4 white and 2 black counters. Two are drawn without replacement. The probability of drawing one counter of each colour is written as a fraction in simplest form. Enter its numerator.','[]','8','P(one of each)=4/6×2/5+2/6×4/5=16/30=8/15, so the numerator is 8.','В мешке 4 белых и 2 чёрных фишки. Две фишки вытаскивают без возвращения. Вероятность получить по одной фишке каждого цвета записана несократимой дробью. Введите её числитель.','[]','P(по одной каждого цвета)=4/6×2/5+2/6×4/5=16/30=8/15, поэтому числитель равен 8.','Qopda 4 oq va 2 qora jeton bor. Ikki jeton qaytarmasdan olinadi. Har rangdan bittadan chiqish ehtimoli qisqartirilgan kasr ko‘rinishida yoziladi. Uning suratini kiriting.','[]','P(har rangdan bittadan)=4/6×2/5+2/6×4/5=16/30=8/15, demak surat 8.',80),
('P5DRV01-A01','P5-DRV-01','P5 Discrete random variables','medium','mcq','A discrete random variable X takes values 0,1,2,3 with probabilities k,2k,k,2k respectively. Find k.','["1/6","1/4","1/5","1/3"]','A','Probabilities sum to 1: k+2k+k+2k=6k=1, so k=1/6.','Дискретная случайная величина X принимает значения 0,1,2,3 с вероятностями k,2k,k,2k соответственно. Найдите k.','["1/6","1/4","1/5","1/3"]','Сумма вероятностей равна 1: k+2k+k+2k=6k=1, поэтому k=1/6.','Diskret tasodifiy X 0,1,2,3 qiymatlarni mos ravishda k,2k,k,2k ehtimollar bilan oladi. k ni toping.','["1/6","1/4","1/5","1/3"]','Ehtimollar yig‘indisi 1: k+2k+k+2k=6k=1, demak k=1/6.',65),
('P5DRV01-A02','P5-DRV-01','P5 Discrete random variables','medium','mcq','Which set of probabilities cannot form a valid discrete probability distribution?','["0.15, 0.25, 0.60","0.20, 0.40, 0.50","0.10, 0.30, 0.25, 0.35","0.05, 0.15, 0.30, 0.50"]','B','A valid distribution requires all probabilities to be between 0 and 1 and sum to 1. The second set sums to 1.10.','Какой набор вероятностей не может задавать корректное дискретное распределение?','["0,15; 0,25; 0,60","0,20; 0,40; 0,50","0,10; 0,30; 0,25; 0,35","0,05; 0,15; 0,30; 0,50"]','Для корректного распределения все вероятности должны лежать между 0 и 1 и давать в сумме 1. Второй набор даёт 1,10.','Qaysi ehtimollar to‘plami to‘g‘ri diskret taqsimot bo‘la olmaydi?','["0.15, 0.25, 0.60","0.20, 0.40, 0.50","0.10, 0.30, 0.25, 0.35","0.05, 0.15, 0.30, 0.50"]','To‘g‘ri taqsimotda barcha ehtimollar 0 va 1 orasida bo‘lib, yig‘indisi 1 bo‘lishi kerak. Ikkinchi to‘plam 1.10 ga teng.',65),
('P5DRV01-A03','P5-DRV-01','P5 Discrete random variables','medium','input','X takes values 1,2,4 with probabilities 0.20, k, 0.30. Enter k.','[]','0.5','The probabilities must sum to 1, so k=1−0.20−0.30=0.50.','X принимает значения 1,2,4 с вероятностями 0,20, k, 0,30. Введите k.','[]','Сумма вероятностей должна быть равна 1, поэтому k=1−0,20−0,30=0,50.','X 1,2,4 qiymatlarni 0.20, k, 0.30 ehtimollar bilan oladi. k ni kiriting.','[]','Ehtimollar yig‘indisi 1 bo‘lishi kerak, demak k=1−0.20−0.30=0.50.',55),
('P5DRV02-A01','P5-DRV-02','P5 Discrete random variables','medium','mcq','X takes values 0,2,5 with probabilities 0.4,0.3,0.3. Find E(X).','["1.5","1.8","2.1","2.5"]','C','E(X)=0(0.4)+2(0.3)+5(0.3)=0.6+1.5=2.1.','X принимает значения 0,2,5 с вероятностями 0,4; 0,3; 0,3. Найдите E(X).','["1,5","1,8","2,1","2,5"]','E(X)=0(0,4)+2(0,3)+5(0,3)=0,6+1,5=2,1.','X 0,2,5 qiymatlarni 0.4,0.3,0.3 ehtimollar bilan oladi. E(X) ni toping.','["1.5","1.8","2.1","2.5"]','E(X)=0(0.4)+2(0.3)+5(0.3)=0.6+1.5=2.1.',65),
('P5DRV02-A02','P5-DRV-02','P5 Discrete random variables','medium','mcq','A game gives a gain of 8 units with probability 0.25 and a loss of 2 units with probability 0.75. What is the expected gain per game?','["−1.5","−0.5","0","0.5"]','D','E=8(0.25)+(−2)(0.75)=2−1.5=0.5.','Игра приносит выигрыш 8 единиц с вероятностью 0,25 и потерю 2 единиц с вероятностью 0,75. Каков ожидаемый выигрыш за игру?','["−1,5","−0,5","0","0,5"]','E=8(0,25)+(−2)(0,75)=2−1,5=0,5.','O‘yin 0.25 ehtimol bilan 8 birlik yutuq, 0.75 ehtimol bilan 2 birlik zarar beradi. Har bir o‘yin uchun kutiladigan yutuq qancha?','["−1.5","−0.5","0","0.5"]','E=8(0.25)+(−2)(0.75)=2−1.5=0.5.',70),
('P5DRV02-A03','P5-DRV-02','P5 Discrete random variables','medium','input','X takes values −1 and 3 with probabilities 0.4 and 0.6. Enter E(X).','[]','1.4','E(X)=−1(0.4)+3(0.6)=−0.4+1.8=1.4.','X принимает значения −1 и 3 с вероятностями 0,4 и 0,6. Введите E(X).','[]','E(X)=−1(0,4)+3(0,6)=−0,4+1,8=1,4.','X −1 va 3 qiymatlarni 0.4 va 0.6 ehtimollar bilan oladi. E(X) ni kiriting.','[]','E(X)=−1(0.4)+3(0.6)=−0.4+1.8=1.4.',60),
('P5DRV03-A01','P5-DRV-03','P5 Discrete random variables','medium','mcq','For a discrete random variable, E(X)=4 and E(X²)=19. Find Var(X).','["3","4","11","15"]','A','Var(X)=E(X²)−[E(X)]²=19−16=3.','Для дискретной случайной величины E(X)=4 и E(X²)=19. Найдите Var(X).','["3","4","11","15"]','Var(X)=E(X²)−[E(X)]²=19−16=3.','Diskret tasodifiy kattalik uchun E(X)=4 va E(X²)=19. Var(X) ni toping.','["3","4","11","15"]','Var(X)=E(X²)−[E(X)]²=19−16=3.',60),
('P5DRV03-A02','P5-DRV-03','P5 Discrete random variables','medium','mcq','X takes values 0 and 4 with equal probability. What is the standard deviation of X?','["1","2","4","8"]','B','E(X)=2 and E(X²)=8, so Var(X)=8−4=4 and the standard deviation is 2.','X принимает значения 0 и 4 с равными вероятностями. Каково стандартное отклонение X?','["1","2","4","8"]','E(X)=2, E(X²)=8, поэтому Var(X)=8−4=4 и стандартное отклонение равно 2.','X 0 va 4 qiymatlarni teng ehtimol bilan oladi. X ning standart og‘ishi qancha?','["1","2","4","8"]','E(X)=2 va E(X²)=8, shuning uchun Var(X)=8−4=4 va standart og‘ish 2.',70),
('P5DRV03-A03','P5-DRV-03','P5 Discrete random variables','medium','input','For X, E(X)=2.5 and E(X²)=8.5. Enter the standard deviation.','[]','1.5','Var(X)=8.5−2.5²=8.5−6.25=2.25, so the standard deviation is √2.25=1.5.','Для X даны E(X)=2,5 и E(X²)=8,5. Введите стандартное отклонение.','[]','Var(X)=8,5−2,5²=8,5−6,25=2,25, поэтому стандартное отклонение равно √2,25=1,5.','X uchun E(X)=2.5 va E(X²)=8.5. Standart og‘ishni kiriting.','[]','Var(X)=8.5−2.5²=8.5−6.25=2.25, demak standart og‘ish √2.25=1.5.',70),
('P5BIN01-A01','P5-BIN-01','P5 Binomial distribution','medium','mcq','Twelve independent patients receive the same treatment. Each patient responds with probability 0.7. X is the number who respond. Which model is appropriate?','["X~B(0.7,12)","X~Geo(0.7)","X~B(12,0.7)","No standard model applies"]','C','There are 12 fixed independent trials, two outcomes per patient and constant success probability 0.7, so X~B(12,0.7).','Двенадцать независимых пациентов получают одинаковое лечение. Каждый отвечает на лечение с вероятностью 0,7. X — число пациентов с ответом. Какая модель подходит?','["X~B(0,7;12)","X~Geo(0,7)","X~B(12;0,7)","Стандартная модель не подходит"]','Есть 12 фиксированных независимых испытаний, два исхода и постоянная вероятность успеха 0,7, поэтому X~B(12,0,7).','12 mustaqil bemor bir xil davolanish oladi. Har biri 0.7 ehtimol bilan javob beradi. X — javob berganlar soni. Qaysi model mos?','["X~B(0.7,12)","X~Geo(0.7)","X~B(12,0.7)","Standart model mos emas"]','12 ta belgilangan mustaqil sinov, ikkita natija va o‘zgarmas 0.7 muvaffaqiyat ehtimoli bor, demak X~B(12,0.7).',75),
('P5BIN01-A02','P5-BIN-01','P5 Binomial distribution','medium','mcq','Six cards are drawn without replacement from a standard deck and X is the number of hearts. Which binomial condition is not exact?','["There is a fixed number of draws","There are two categories: heart/not heart","X counts successes","The draws are independent with constant success probability"]','D','Without replacement, the composition of the deck changes after each draw, so the success probability changes and the trials are not independent.','Из стандартной колоды без возвращения вытаскивают 6 карт, X — число червей. Какое условие биномиальной модели не выполняется точно?','["Число вытаскиваний фиксировано","Есть две категории: черва/не черва","X считает успехи","Испытания независимы и вероятность успеха постоянна"]','Без возвращения состав колоды меняется после каждого вытаскивания, поэтому вероятность успеха меняется и испытания не независимы.','Standart kolodadan qaytarmasdan 6 karta olinadi, X — yuraklar soni. Binomial modelning qaysi sharti aniq bajarilmaydi?','["Olishlar soni belgilangan","Ikki toifa bor: yurak/yurak emas","X muvaffaqiyatlarni sanaydi","Sinovlar mustaqil va muvaffaqiyat ehtimoli o‘zgarmas"]','Qaytarmasdan olinganda koloda tarkibi har safar o‘zgaradi, shu sababli muvaffaqiyat ehtimoli o‘zgaradi va sinovlar mustaqil emas.',75),
('P5BIN01-A03','P5-BIN-01','P5 Binomial distribution','medium','input','Twenty independent components are tested. Each component fails with the same probability 0.04, and X is the number that fail. Enter the binomial parameter n.','[]','20','The number of trials is fixed at 20, so n=20.','Проверяют 20 независимых компонентов. Каждый выходит из строя с одинаковой вероятностью 0,04, X — число отказавших компонентов. Введите биномиальный параметр n.','[]','Число испытаний фиксировано и равно 20, поэтому n=20.','20 ta mustaqil komponent tekshiriladi. Har biri bir xil 0.04 ehtimol bilan ishdan chiqadi, X — ishdan chiqqanlar soni. Binomial n parametrini kiriting.','[]','Sinovlar soni 20 ta qilib belgilangan, demak n=20.',55),
('P5GEO01-A01','P5-GEO-01','P5 Geometric distribution','medium','mcq','Independent calls each lead to a sale with probability 0.25. Calls continue until the first sale, and X is the call number of that sale. Which model fits X?','["Geometric with p=0.25","Binomial with n=4","Normal with mean 0.25","No model because X is not fixed"]','A','X is the waiting time to the first success in independent trials with constant success probability 0.25, so it is geometric.','Каждый независимый звонок приводит к продаже с вероятностью 0,25. Звонки продолжаются до первой продажи, X — номер звонка, на котором произошла первая продажа. Какая модель подходит?','["Геометрическая с p=0,25","Биномиальная с n=4","Нормальная со средним 0,25","Модель не подходит, потому что X не фиксирован"]','X — число испытаний до первого успеха при независимых испытаниях с постоянной вероятностью успеха 0,25, поэтому подходит геометрическая модель.','Har bir mustaqil qo‘ng‘iroq 0.25 ehtimol bilan savdoga olib keladi. Birinchi savdogacha qo‘ng‘iroqlar davom etadi, X — o‘sha savdo sodir bo‘lgan qo‘ng‘iroq raqami. Qaysi model mos?','["p=0.25 bo‘lgan geometrik","n=4 bo‘lgan binomial","o‘rtachasi 0.25 bo‘lgan normal","X belgilangan emasligi uchun model yo‘q"]','X o‘zgarmas 0.25 muvaffaqiyat ehtimoliga ega mustaqil sinovlarda birinchi muvaffaqiyatgacha kutish vaqti, demak geometrik model.',75),
('P5GEO01-A02','P5-GEO-01','P5 Geometric distribution','medium','mcq','Which situation is not modelled exactly by an ordinary geometric distribution?','["Independent coin tosses until the first head","Cards drawn without replacement until the first ace","Independent shots with constant scoring probability until the first score","Independent items inspected with constant defect probability until the first defective item"]','B','Drawing without replacement changes the composition of the deck, so the probability of an ace is not constant and trials are not independent.','Какая ситуация не моделируется точно обычным геометрическим распределением?','["Независимые броски монеты до первого орла","Карты вытаскивают без возвращения до первого туза","Независимые броски с постоянной вероятностью попадания до первого попадания","Независимые изделия проверяют при постоянной вероятности дефекта до первого дефектного"]','При вытаскивании без возвращения состав колоды меняется, поэтому вероятность туза не постоянна и испытания не независимы.','Qaysi vaziyat oddiy geometrik taqsimot bilan aniq modellashtirilmaydi?','["Birinchi gerbgacha mustaqil tanga tashlash","Birinchi tuzgacha kartalarni qaytarmasdan olish","Birinchi muvaffaqiyatgacha o‘zgarmas ehtimolli mustaqil zarbalar","Birinchi nuqsonli buyumgacha o‘zgarmas ehtimolli mustaqil tekshiruvlar"]','Qaytarmasdan karta olinganda koloda tarkibi o‘zgaradi, shuning uchun tuz ehtimoli o‘zgarmas emas va sinovlar mustaqil emas.',75),
('P5GEO01-A03','P5-GEO-01','P5 Geometric distribution','medium','input','Independent trials have success probability 0.12 and continue until the first success. Enter the geometric parameter p.','[]','0.12','In a geometric model, p is the constant success probability on each trial, so p=0.12.','Независимые испытания имеют вероятность успеха 0,12 и продолжаются до первого успеха. Введите параметр геометрического распределения p.','[]','В геометрической модели p — постоянная вероятность успеха в каждом испытании, поэтому p=0,12.','Mustaqil sinovlarda muvaffaqiyat ehtimoli 0.12 va ular birinchi muvaffaqiyatgacha davom etadi. Geometrik p parametrini kiriting.','[]','Geometrik modelda p har bir sinovdagi o‘zgarmas muvaffaqiyat ehtimoli, demak p=0.12.',55)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,s.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P5:p5_aw13_16_alt_learning_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw13_16_alt_learning_draft_v1:'||s.content_key);

insert into private.exam_prep_written_tasks(
 id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
 prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
 lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15646,4814,'P5PRO05-AW14','P5','P5-PRO-05','{}','v1','In a school club, 48 students take part in at least one of Economics or Chess. Of these, 36 take Economics, 30 take Chess and 18 take both. (a) Find P(Chess|Economics). (b) Find P(Economics|Chess). (c) Given that a student takes exactly one of the two activities, find the probability that it is Economics. Show the restricted sample space in each conditional calculation.','В школьном клубе 48 учеников участвуют хотя бы в одном из направлений: экономика или шахматы. 36 занимаются экономикой, 30 — шахматами, 18 — обоими. (a) Найдите P(Шахматы|Экономика). (b) Найдите P(Экономика|Шахматы). (c) Если известно, что ученик занимается ровно одним из двух направлений, найдите вероятность, что это экономика. Покажите ограниченное пространство исходов в каждом условном вычислении.','Maktab klubida 48 o‘quvchi Iqtisodiyot yoki Shaxmatdan kamida bittasida qatnashadi. 36 tasi iqtisodiyot, 30 tasi shaxmat, 18 tasi ikkalasida ham. (a) P(Shaxmat|Iqtisodiyot) ni toping. (b) P(Iqtisodiyot|Shaxmat) ni toping. (c) O‘quvchi aynan bitta faoliyatda qatnashishi ma’lum bo‘lsa, uning iqtisodiyot bo‘lish ehtimolini toping. Har bir shartli hisobda cheklangan natijalar fazosini ko‘rsating.','{"criteria":[{"id":"ce","rule":"Finds P(Chess|Economics)=18/36=1/2.","marks":1},{"id":"ec","rule":"Finds P(Economics|Chess)=18/30=3/5.","marks":1},{"id":"exact","rule":"Finds Economics-only 18 and Chess-only 12.","marks":1},{"id":"cond","rule":"Finds 18/(18+12)=3/5 for part (c).","marks":1},{"id":"spaces","rule":"Identifies the correct conditional sample space in each part.","marks":1},{"id":"method","rule":"Uses conditional probability notation and reasoning consistently.","marks":1}],"max_marks":6}'::jsonb,'For each condition, replace the original sample space by the group named after the vertical bar before forming the fraction.','Для каждого условия сначала замените исходное пространство группой, указанной после вертикальной черты, и только затем составляйте дробь.','Har bir shartda kasr tuzishdan oldin dastlabki natijalar fazosini vertikal chiziqdan keyin ko‘rsatilgan guruh bilan almashtiring.','draft','pending','pending','pending','pending'),
(15647,4814,'P5PRO06-AW14','P5','P5-PRO-06','{}','v1','A bag contains 5 red, 3 blue and 2 green counters. Two counters are drawn without replacement. (a) Draw or describe the complete two-stage probability tree. (b) Find P(two counters have the same colour). (c) Find P(exactly one red counter). (d) Explain why second-draw branch probabilities differ from first-draw probabilities.','В мешке 5 красных, 3 синих и 2 зелёных фишки. Две фишки вытаскивают без возвращения. (a) Постройте или опишите полное двухэтапное дерево вероятностей. (b) Найдите P(две фишки одного цвета). (c) Найдите P(ровно одна красная фишка). (d) Объясните, почему вероятности ветвей второго вытаскивания отличаются от первого.','Qopda 5 qizil, 3 ko‘k va 2 yashil jeton bor. Ikki jeton qaytarmasdan olinadi. (a) To‘liq ikki bosqichli ehtimollar daraxtini chizing yoki tasvirlang. (b) P(ikki jeton bir xil rangda) ni toping. (c) P(aynan bitta qizil) ni toping. (d) Nega ikkinchi olishdagi shox ehtimollari birinchi olishdagidan farq qilishini tushuntiring.','{"criteria":[{"id":"tree","rule":"Gives correct first- and second-stage branch probabilities for all colours.","marks":2},{"id":"same","rule":"Finds P(same colour)=5/10·4/9+3/10·2/9+2/10·1/9=14/45.","marks":1},{"id":"one_red","rule":"Finds P(exactly one red)=5/10·5/9+5/10·5/9=5/9.","marks":1},{"id":"multiplyadd","rule":"Multiplies along branches and adds mutually exclusive routes correctly.","marks":1},{"id":"explain","rule":"Explains that without replacement changes both the total remaining and the colour count.","marks":1}],"max_marks":6}'::jsonb,'Update both numerator and denominator after the first draw. Multiply probabilities along a route and add routes that represent the same final event.','После первого вытаскивания обновляйте и числитель, и знаменатель. Вероятности вдоль ветви перемножайте, а подходящие альтернативные ветви складывайте.','Birinchi olishdan keyin suratni ham, maxrajni ham yangilang. Bir yo‘l bo‘ylab ehtimollarni ko‘paytiring, bir xil yakuniy hodisaga olib keluvchi yo‘llarni qo‘shing.','draft','pending','pending','pending','pending'),
(15648,4814,'P5DRV01-AW14','P5','P5-DRV-01','{}','v1','A discrete random variable X takes values 0,1,2,3 with probabilities k, 2k, 0.30 and 0.10 respectively. (a) Find k. (b) Write the complete probability distribution. (c) Find P(X≥2). (d) Explain the two conditions that make the table a valid discrete probability distribution.','Дискретная случайная величина X принимает значения 0,1,2,3 с вероятностями k, 2k, 0,30 и 0,10 соответственно. (a) Найдите k. (b) Запишите полное распределение вероятностей. (c) Найдите P(X≥2). (d) Объясните два условия корректности таблицы дискретного распределения.','Diskret tasodifiy X 0,1,2,3 qiymatlarni mos ravishda k, 2k, 0.30 va 0.10 ehtimollar bilan oladi. (a) k ni toping. (b) To‘liq ehtimollar taqsimotini yozing. (c) P(X≥2) ni toping. (d) Jadval to‘g‘ri diskret ehtimollar taqsimoti bo‘lishi uchun ikki shartni tushuntiring.','{"criteria":[{"id":"sum","rule":"Uses k+2k+0.30+0.10=1.","marks":1},{"id":"k","rule":"Finds k=0.20.","marks":1},{"id":"table","rule":"Writes probabilities 0.20,0.40,0.30,0.10 against X=0,1,2,3.","marks":1},{"id":"event","rule":"Finds P(X≥2)=0.40.","marks":1},{"id":"bounds","rule":"States each probability must lie between 0 and 1.","marks":1},{"id":"total","rule":"States all probabilities must sum to 1.","marks":1}],"max_marks":6}'::jsonb,'Use the total-probability condition first. After finding k, rewrite the whole table before answering the event probability.','Сначала используйте условие суммы вероятностей. После нахождения k перепишите всю таблицу и только затем вычисляйте вероятность события.','Avval ehtimollar yig‘indisi shartidan foydalaning. k ni topgach, hodisa ehtimolini hisoblashdan oldin butun jadvalni qayta yozing.','draft','pending','pending','pending','pending'),
(15649,4814,'P5DRV02-AW14','P5','P5-DRV-02','{}','v1','A game has net gain X with values −3, 2 and 8 occurring with probabilities 0.50, 0.35 and 0.15. (a) Find E(X). (b) Interpret the sign of E(X) over many repetitions. (c) The organiser adds a fixed entry bonus of 1 unit to every outcome. Without rebuilding the distribution from scratch, find the new expected gain and explain the rule used.','Чистый выигрыш X в игре принимает значения −3, 2 и 8 с вероятностями 0,50; 0,35 и 0,15. (a) Найдите E(X). (b) Интерпретируйте знак E(X) при большом числе повторений. (c) Организатор добавляет фиксированный бонус 1 единица к каждому исходу. Не перестраивая распределение заново, найдите новое математическое ожидание и объясните использованное правило.','O‘yindagi sof yutuq X −3, 2 va 8 qiymatlarni 0.50, 0.35 va 0.15 ehtimollar bilan oladi. (a) E(X) ni toping. (b) Ko‘p takrorlashda E(X) ishorasini talqin qiling. (c) Tashkilotchi har bir natijaga 1 birlik doimiy bonus qo‘shadi. Taqsimotni boshidan qayta tuzmasdan yangi kutiladigan yutuqni toping va ishlatilgan qoidani tushuntiring.','{"criteria":[{"id":"expect","rule":"Finds E(X)=−3(0.50)+2(0.35)+8(0.15)=0.40.","marks":2},{"id":"interpret","rule":"Explains that a positive expectation means an average gain of about 0.40 units per play over many repetitions.","marks":1},{"id":"transform","rule":"Uses E(X+1)=E(X)+1.","marks":1},{"id":"new","rule":"Finds new expectation 1.40.","marks":1},{"id":"reason","rule":"Explains why adding a constant to every outcome adds the same constant to expectation.","marks":1}],"max_marks":6}'::jsonb,'Multiply each possible value by its probability for the original expectation. For the fixed bonus, use linearity of expectation rather than recomputing every term.','Для исходного ожидания умножьте каждое значение на его вероятность. Для фиксированного бонуса используйте линейность математического ожидания вместо полного пересчёта.','Dastlabki kutilma uchun har bir qiymatni uning ehtimoliga ko‘paytiring. Doimiy bonus uchun barcha hadlarni qayta hisoblash o‘rniga kutilmaning chiziqliligidan foydalaning.','draft','pending','pending','pending','pending'),
(15650,4814,'P5DRV03-AW14','P5','P5-DRV-03','{}','v1','A discrete random variable X takes values 0,2,4 with probabilities 0.25,0.50,0.25. (a) Find E(X). (b) Find E(X²). (c) Hence find Var(X) and the standard deviation. (d) Explain why variance cannot be negative.','Дискретная случайная величина X принимает значения 0,2,4 с вероятностями 0,25; 0,50; 0,25. (a) Найдите E(X). (b) Найдите E(X²). (c) Затем найдите Var(X) и стандартное отклонение. (d) Объясните, почему дисперсия не может быть отрицательной.','Diskret tasodifiy X 0,2,4 qiymatlarni 0.25,0.50,0.25 ehtimollar bilan oladi. (a) E(X) ni toping. (b) E(X²) ni toping. (c) Shundan Var(X) va standart og‘ishni toping. (d) Nega dispersiya manfiy bo‘la olmasligini tushuntiring.','{"criteria":[{"id":"mean","rule":"Finds E(X)=2.","marks":1},{"id":"second","rule":"Finds E(X²)=6.","marks":1},{"id":"variance","rule":"Finds Var(X)=6−2²=2.","marks":2},{"id":"sd","rule":"Finds standard deviation √2.","marks":1},{"id":"reason","rule":"Explains variance is an expectation of squared deviations and therefore is non-negative.","marks":1}],"max_marks":6}'::jsonb,'Calculate E(X) and E(X²) as separate weighted sums before using Var(X)=E(X²)−[E(X)]².','Вычислите E(X) и E(X²) как отдельные взвешенные суммы, затем используйте Var(X)=E(X²)−[E(X)]².','Var(X)=E(X²)−[E(X)]² formulasini ishlatishdan oldin E(X) va E(X²) ni alohida og‘irlikli yig‘indilar sifatida hisoblang.','draft','pending','pending','pending','pending'),
(15651,4814,'P5BIN01-AW14','P5','P5-BIN-01','{}','v1','For each situation, decide whether a binomial model is exact and justify your decision using fixed n, two outcomes, constant p and independence: (a) 15 independent components are tested and each is defective with probability 0.04; X counts defects. (b) 5 cards are drawn without replacement and X counts aces. (c) A fair coin is tossed until the first head and X is the number of tosses.','Для каждой ситуации определите, является ли биномиальная модель точной, и обоснуйте решение через фиксированное n, два исхода, постоянное p и независимость: (a) проверяют 15 независимых компонентов, каждый дефектен с вероятностью 0,04; X считает дефекты. (b) 5 карт вытаскивают без возвращения, X считает тузов. (c) честную монету подбрасывают до первого орла, X — число бросков.','Har bir vaziyat uchun binomial model aniq mos keladimi, aniqlang va fixed n, ikki natija, o‘zgarmas p va mustaqillik orqali asoslang: (a) 15 mustaqil komponent tekshiriladi, har biri 0.04 ehtimol bilan nuqsonli; X nuqsonlarni sanaydi. (b) 5 karta qaytarmasdan olinadi, X tuzlarni sanaydi. (c) tanga birinchi gerbgacha tashlanadi, X tashlashlar soni.','{"criteria":[{"id":"a","rule":"Identifies (a) as binomial B(15,0.04) and states the four conditions.","marks":2},{"id":"b","rule":"Rejects (b) because without replacement changes p and breaks independence.","marks":1},{"id":"c","rule":"Rejects (c) because the number of trials is not fixed; it is a waiting-time structure.","marks":1},{"id":"criteria","rule":"Uses the binomial conditions explicitly rather than only naming models.","marks":1},{"id":"distinguish","rule":"Distinguishes count-in-fixed-trials from waiting-to-first-success.","marks":1}],"max_marks":6}'::jsonb,'Check the four binomial conditions one by one. A situation may have two outcomes but still fail because n is not fixed or p changes.','Проверяйте четыре условия биномиальной модели по отдельности. Наличие двух исходов ещё не достаточно: n может быть не фиксировано или p может меняться.','Binomial modelning to‘rt shartini bittadan tekshiring. Ikki natija bo‘lishi yetarli emas: n belgilangan bo‘lmasligi yoki p o‘zgarishi mumkin.','draft','pending','pending','pending','pending'),
(15652,4814,'P5GEO01-AW14','P5','P5-GEO-01','{}','v1','For each situation, decide whether a geometric model is exact and justify your decision: (a) independent shots with scoring probability 0.3 continue until the first score; (b) cards are drawn without replacement until the first ace; (c) a fair die is rolled exactly 8 times and X counts sixes. For any geometric case, state p and explain what X represents.','Для каждой ситуации определите, является ли геометрическая модель точной, и обоснуйте решение: (a) независимые броски с вероятностью попадания 0,3 продолжаются до первого попадания; (b) карты вытаскивают без возвращения до первого туза; (c) честный кубик бросают ровно 8 раз, X считает шестёрки. Для геометрического случая укажите p и объясните смысл X.','Har bir vaziyat uchun geometrik model aniq mos keladimi, aniqlang va asoslang: (a) 0.3 muvaffaqiyat ehtimolli mustaqil zarbalar birinchi muvaffaqiyatgacha davom etadi; (b) kartalar birinchi tuzgacha qaytarmasdan olinadi; (c) adolatli kubik aynan 8 marta tashlanadi, X oltitalarni sanaydi. Geometrik holat uchun p ni yozing va X nimani ifodalashini tushuntiring.','{"criteria":[{"id":"a","rule":"Identifies (a) as geometric with p=0.3.","marks":2},{"id":"meaning","rule":"Explains that X is the trial number/waiting time to the first success.","marks":1},{"id":"b","rule":"Rejects (b) because without replacement changes success probability and dependence.","marks":1},{"id":"c","rule":"Rejects (c) as a fixed-trial count rather than waiting to first success.","marks":1},{"id":"assumptions","rule":"States independence and constant p as geometric assumptions.","marks":1}],"max_marks":6}'::jsonb,'A geometric model needs repeated independent trials with constant p and stops at the first success. Separate this from a fixed number of trials.','Геометрическая модель требует повторяющихся независимых испытаний с постоянным p и остановки при первом успехе. Не смешивайте это с фиксированным числом испытаний.','Geometrik model o‘zgarmas p li takroriy mustaqil sinovlar va birinchi muvaffaqiyatda to‘xtashni talab qiladi. Buni belgilangan sondagi sinovlardan ajrating.','draft','pending','pending','pending','pending')
on conflict(id) do nothing;

with src(content_key,skill_code,meta_id,official_ref,book_ref) as (values
('P5PRO05-A01','P5-PRO-05',59294,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO05-A02','P5-PRO-05',59295,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO05-A03','P5-PRO-05',59296,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO06-A01','P5-PRO-06',59297,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO06-A02','P5-PRO-06',59298,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5PRO06-A03','P5-PRO-06',59299,'Cambridge 9709 2026-2027 v4; P5 5.3 Probability','Complete Probability & Statistics 1, Ch4 Probability pp.63-82 (mapping only)'),
('P5DRV01-A01','P5-DRV-01',59300,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch5 Discrete random variables pp.84-96 (mapping only)'),
('P5DRV01-A02','P5-DRV-01',59301,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch5 Discrete random variables pp.84-96 (mapping only)'),
('P5DRV01-A03','P5-DRV-01',59302,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch5 Discrete random variables pp.84-96 (mapping only)'),
('P5DRV02-A01','P5-DRV-02',59303,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch5 Discrete random variables pp.84-96 (mapping only)'),
('P5DRV02-A02','P5-DRV-02',59304,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch5 Discrete random variables pp.84-96 (mapping only)'),
('P5DRV02-A03','P5-DRV-02',59305,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch5 Discrete random variables pp.84-96 (mapping only)'),
('P5DRV03-A01','P5-DRV-03',59306,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch5 Discrete random variables pp.84-96 (mapping only)'),
('P5DRV03-A02','P5-DRV-03',59307,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch5 Discrete random variables pp.84-96 (mapping only)'),
('P5DRV03-A03','P5-DRV-03',59308,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch5 Discrete random variables pp.84-96 (mapping only)'),
('P5BIN01-A01','P5-BIN-01',59309,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN01-A02','P5-BIN-01',59310,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN01-A03','P5-BIN-01',59311,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5GEO01-A01','P5-GEO-01',59312,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO01-A02','P5-GEO-01',59313,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO01-A03','P5-GEO-01',59314,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)')
), cv as (select id from private.exam_prep_content_versions where id=4814)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,cv.id,s.content_key,qn.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'Supplemental AW13-16 learning draft authored from the canonical skill intent with independent values and contexts, separate from the existing teaching pack.',
 s.official_ref,s.book_ref,
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
join public.questions qn on qn.book_ref='ExamPrep:P5:p5_aw13_16_alt_learning_draft_v1:'||s.content_key
on conflict(id) do nothing;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35429,4814,'P5-PRO-05-learning-alt-03','v1','P5','learning','draft','Conditional probability','Условная вероятность','Shartli ehtimollik'),
(35430,4814,'P5-PRO-06-learning-alt-03','v1','P5','learning','draft','Probability trees','Деревья вероятностей','Ehtimollar daraxti'),
(35431,4814,'P5-DRV-01-learning-alt-03','v1','P5','learning','draft','Discrete probability distributions','Дискретные распределения вероятностей','Diskret ehtimollar taqsimoti'),
(35432,4814,'P5-DRV-02-learning-alt-03','v1','P5','learning','draft','Expected value','Математическое ожидание','Kutiladigan qiymat'),
(35433,4814,'P5-DRV-03-learning-alt-03','v1','P5','learning','draft','Variance and standard deviation','Дисперсия и стандартное отклонение','Dispersiya va standart og‘ish'),
(35434,4814,'P5-BIN-01-learning-alt-03','v1','P5','learning','draft','Recognising a binomial model','Распознавание биномиальной модели','Binomial modelni aniqlash'),
(35435,4814,'P5-GEO-01-learning-alt-03','v1','P5','learning','draft','Recognising a geometric model','Распознавание геометрической модели','Geometrik modelni aniqlash')
on conflict(id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35429,1,'P5PRO05-A01',null::bigint,'P5-PRO-05'),
(35429,2,'P5PRO05-A02',null::bigint,'P5-PRO-05'),
(35429,3,'P5PRO05-A03',null::bigint,'P5-PRO-05'),
(35429,4,null,15646,'P5-PRO-05'),
(35430,1,'P5PRO06-A01',null::bigint,'P5-PRO-06'),
(35430,2,'P5PRO06-A02',null::bigint,'P5-PRO-06'),
(35430,3,'P5PRO06-A03',null::bigint,'P5-PRO-06'),
(35430,4,null,15647,'P5-PRO-06'),
(35431,1,'P5DRV01-A01',null::bigint,'P5-DRV-01'),
(35431,2,'P5DRV01-A02',null::bigint,'P5-DRV-01'),
(35431,3,'P5DRV01-A03',null::bigint,'P5-DRV-01'),
(35431,4,null,15648,'P5-DRV-01'),
(35432,1,'P5DRV02-A01',null::bigint,'P5-DRV-02'),
(35432,2,'P5DRV02-A02',null::bigint,'P5-DRV-02'),
(35432,3,'P5DRV02-A03',null::bigint,'P5-DRV-02'),
(35432,4,null,15649,'P5-DRV-02'),
(35433,1,'P5DRV03-A01',null::bigint,'P5-DRV-03'),
(35433,2,'P5DRV03-A02',null::bigint,'P5-DRV-03'),
(35433,3,'P5DRV03-A03',null::bigint,'P5-DRV-03'),
(35433,4,null,15650,'P5-DRV-03'),
(35434,1,'P5BIN01-A01',null::bigint,'P5-BIN-01'),
(35434,2,'P5BIN01-A02',null::bigint,'P5-BIN-01'),
(35434,3,'P5BIN01-A03',null::bigint,'P5-BIN-01'),
(35434,4,null,15651,'P5-BIN-01'),
(35435,1,'P5GEO01-A01',null::bigint,'P5-GEO-01'),
(35435,2,'P5GEO01-A02',null::bigint,'P5-GEO-01'),
(35435,3,'P5GEO01-A03',null::bigint,'P5-GEO-01'),
(35435,4,null,15652,'P5-GEO-01')
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select i.assessment_id,i.item_order,qn.id,i.written_id,i.skill_code,
 case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions qn on i.content_key is not null
 and qn.book_ref='ExamPrep:P5:p5_aw13_16_alt_learning_draft_v1:'||i.content_key
on conflict(assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4814)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4814 and lifecycle_state='draft' and reserve_role='learning')<>21
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4814 and lifecycle_state='draft')<>7
     or (select count(*) from private.exam_prep_assessments where content_version_id=4814 and status='draft' and assessment_type='learning')<>7
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4814)<>28
  then raise exception 'aw13_16_alt_p5_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4814 and (
    m.exposure_state<>'withheld' or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or qn.is_active or qn.quality_status<>'draft'
    or nullif(btrim(qn.question_text_en),'') is null or nullif(btrim(qn.question_text_ru),'') is null or nullif(btrim(qn.question_text_uz),'') is null
    or nullif(btrim(qn.explanation_en),'') is null or nullif(btrim(qn.explanation_ru),'') is null or nullif(btrim(qn.explanation_uz),'') is null
  );
  if v_bad<>0 then raise exception 'aw13_16_alt_p5_draft exposure/QA boundary rows=%',v_bad; end if;

  select
    count(*) filter(where qn.correct_answer='A'),
    count(*) filter(where qn.correct_answer='B'),
    count(*) filter(where qn.correct_answer='C'),
    count(*) filter(where qn.correct_answer='D'),
    count(*) filter(where qn.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions qn on qn.id=m.question_id
  where m.content_version_id=4814;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,3,3,7) then
    raise exception 'aw13_16_alt_p5_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions qn on qn.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4814
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4814
      and lower(regexp_replace(qn.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw13_16_alt_p5_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4814)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4814)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4814)
  then raise exception 'aw13_16_alt_p5_draft unexpected history'; end if;
end
$postcheck$;

commit;
