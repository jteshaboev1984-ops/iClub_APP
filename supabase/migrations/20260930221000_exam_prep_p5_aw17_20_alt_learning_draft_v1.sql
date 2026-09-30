-- AW17-20 supplemental learning pack draft for P5.
-- DRAFT ONLY: no learner exposure, QA self-approval or publication.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw17_20_alt_p5_draft canonical program missing'; end if;
  if exists(select 1 from private.exam_prep_content_versions where id=4818 and content_version<>'p5_aw17_20_alt_learning_draft_v1')
     or exists(select 1 from private.exam_prep_written_tasks where id between 15659 and 15663 and content_version_id<>4818)
     or exists(select 1 from private.exam_prep_assessments where id between 35478 and 35482 and content_version_id<>4818)
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59408 and 59422 and content_version_id<>4818)
  then raise exception 'aw17_20_alt_p5_draft reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4818,pv.id,'p5_aw17_20_alt_learning_draft_v1','P5',
 'P5 AW17-20 supplemental learning pack draft v1','draft',
 'Original iClub-authored supplemental learning content. Official Cambridge 9709 scope and Complete Probability & Statistics 1 mappings define learning objectives only; no protected source question, solution, diagram or mark-scheme wording is copied. Independent academic, language, technical and copyright QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,topic,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P5BIN02-A01','P5-BIN-02','P5 Binomial','medium','mcq','Each component is defective independently with probability 0.15. Five components are tested. If X is the number of defective components, find P(X=1) to 4 decimal places.','["0.0750","0.6085","0.3915","0.4437"]','C','P(X=1)=5C1(0.15)(0.85)^4=0.3915046875, which rounds to 0.3915.','Каждый компонент независимо оказывается дефектным с вероятностью 0,15. Проверяют 5 компонентов. Если X — число дефектных компонентов, найдите P(X=1) с точностью до 4 знаков после запятой.','["0,0750","0,6085","0,3915","0,4437"]','P(X=1)=5C1(0,15)(0,85)^4=0,3915046875, что округляется до 0,3915.','Har bir komponent mustaqil ravishda 0.15 ehtimol bilan nuqsonli bo‘ladi. 5 ta komponent tekshiriladi. X — nuqsonli komponentlar soni. P(X=1) ni 4 ta o‘nli xonagacha toping.','["0.0750","0.6085","0.3915","0.4437"]','P(X=1)=5C1(0.15)(0.85)^4=0.3915046875, 4 ta o‘nli xonagacha 0.3915.',75),
('P5BIN02-A02','P5-BIN-02','P5 Binomial','hard','mcq','If X~B(10,0.1), find P(X≥2) to 4 decimal places.','["0.7361","0.3487","0.3874","0.2639"]','D','P(X≥2)=1−P(X=0)−P(X=1)=1−0.9^10−10(0.1)(0.9)^9=0.2639010709≈0.2639.','Если X~B(10,0,1), найдите P(X≥2) с точностью до 4 знаков после запятой.','["0,7361","0,3487","0,3874","0,2639"]','P(X≥2)=1−P(X=0)−P(X=1)=1−0,9^10−10(0,1)(0,9)^9=0,2639010709≈0,2639.','Agar X~B(10,0.1) bo‘lsa, P(X≥2) ni 4 ta o‘nli xonagacha toping.','["0.7361","0.3487","0.3874","0.2639"]','P(X≥2)=1−P(X=0)−P(X=1)=1−0.9^10−10(0.1)(0.9)^9=0.2639010709≈0.2639.',80),
('P5BIN02-A03','P5-BIN-02','P5 Binomial','medium','input','If X~B(6,0.5), then P(X=0 or X=6)=1/k. Enter k.','[]','32','P(X=0 or X=6)=2(0.5)^6=2/64=1/32, so k=32.','Если X~B(6,0,5), то P(X=0 или X=6)=1/k. Введите k.','[]','P(X=0 или X=6)=2(0,5)^6=2/64=1/32, поэтому k=32.','Agar X~B(6,0.5) bo‘lsa, P(X=0 yoki X=6)=1/k. k ni kiriting.','[]','P(X=0 yoki X=6)=2(0.5)^6=2/64=1/32, demak k=32.',65),

('P5BIN03-A01','P5-BIN-03','P5 Binomial','hard','mcq','If X~B(40,p), Var(X)=8.4 and p<0.5, find p.','["0.2","0.3","0.4","0.7"]','B','40p(1−p)=8.4 gives p(1−p)=0.21, so p=0.3 or 0.7. The condition p<0.5 gives p=0.3.','Если X~B(40,p), Var(X)=8,4 и p<0,5, найдите p.','["0,2","0,3","0,4","0,7"]','40p(1−p)=8,4 даёт p(1−p)=0,21, поэтому p=0,3 или 0,7. Условие p<0,5 даёт p=0,3.','Agar X~B(40,p), Var(X)=8.4 va p<0.5 bo‘lsa, p ni toping.','["0.2","0.3","0.4","0.7"]','40p(1−p)=8.4 dan p(1−p)=0.21, demak p=0.3 yoki 0.7. p<0.5 sharti p=0.3 ni beradi.',80),
('P5BIN03-A02','P5-BIN-03','P5 Binomial','hard','mcq','A binomial random variable has mean 18 and variance 12.6. Find n.','["30","42","60","126"]','C','For a binomial variable, Var(X)/E(X)=1−p=12.6/18=0.7, so p=0.3. Then np=18 gives n=60.','Биномиальная случайная величина имеет математическое ожидание 18 и дисперсию 12,6. Найдите n.','["30","42","60","126"]','Для биномиальной величины Var(X)/E(X)=1−p=12,6/18=0,7, поэтому p=0,3. Затем np=18 даёт n=60.','Binomial tasodifiy kattalikning kutiladigan qiymati 18 va dispersiyasi 12.6. n ni toping.','["30","42","60","126"]','Binomial kattalik uchun Var(X)/E(X)=1−p=12.6/18=0.7, demak p=0.3. Keyin np=18 dan n=60.',80),
('P5BIN03-A03','P5-BIN-03','P5 Binomial','medium','input','If X~B(n,0.25) and E(X)=7.5, enter Var(X).','[]','5.625','np=7.5. Hence Var(X)=np(1−p)=7.5(0.75)=5.625.','Если X~B(n,0,25) и E(X)=7,5, введите Var(X).','[]','np=7,5. Поэтому Var(X)=np(1−p)=7,5(0,75)=5,625.','Agar X~B(n,0.25) va E(X)=7.5 bo‘lsa, Var(X) ni kiriting.','[]','np=7.5. Demak Var(X)=np(1−p)=7.5(0.75)=5.625.',65),

('P5GEO02-A01','P5-GEO-02','P5 Geometric','medium','mcq','For geometric X with success probability p=1/4, find P(X>4).','["81/256","175/256","27/256","3/4"]','A','X>4 means the first four trials are failures, so P(X>4)=(3/4)^4=81/256.','Для геометрической X с вероятностью успеха p=1/4 найдите P(X>4).','["81/256","175/256","27/256","3/4"]','X>4 означает, что первые четыре испытания неудачны, поэтому P(X>4)=(3/4)^4=81/256.','Muvaffaqiyat ehtimoli p=1/4 bo‘lgan geometrik X uchun P(X>4) ni toping.','["81/256","175/256","27/256","3/4"]','X>4 dastlabki to‘rtta sinov muvaffaqiyatsiz bo‘lishini anglatadi, demak P(X>4)=(3/4)^4=81/256.',65),
('P5GEO02-A02','P5-GEO-02','P5 Geometric','medium','mcq','For geometric X with p=0.5, find P(2≤X≤4).','["1/2","3/8","1/4","7/16"]','D','P(2≤X≤4)=P(X=2)+P(X=3)+P(X=4)=1/4+1/8+1/16=7/16.','Для геометрической X с p=0,5 найдите P(2≤X≤4).','["1/2","3/8","1/4","7/16"]','P(2≤X≤4)=P(X=2)+P(X=3)+P(X=4)=1/4+1/8+1/16=7/16.','p=0.5 bo‘lgan geometrik X uchun P(2≤X≤4) ni toping.','["1/2","3/8","1/4","7/16"]','P(2≤X≤4)=P(X=2)+P(X=3)+P(X=4)=1/4+1/8+1/16=7/16.',70),
('P5GEO02-A03','P5-GEO-02','P5 Geometric','medium','input','For geometric X with p=1/3, P(X=4)=8/k. Enter k.','[]','81','P(X=4)=(2/3)^3(1/3)=8/81, so k=81.','Для геометрической X с p=1/3 имеем P(X=4)=8/k. Введите k.','[]','P(X=4)=(2/3)^3(1/3)=8/81, поэтому k=81.','p=1/3 bo‘lgan geometrik X uchun P(X=4)=8/k. k ni kiriting.','[]','P(X=4)=(2/3)^3(1/3)=8/81, demak k=81.',65),

('P5GEO03-A01','P5-GEO-03','P5 Geometric','medium','mcq','A geometric random variable has expected trial number 6.25. Find p.','["0.625","0.25","0.16","0.84"]','C','For the trial-number convention, E(X)=1/p. Hence p=1/6.25=0.16.','Для геометрической случайной величины ожидаемый номер испытания равен 6,25. Найдите p.','["0,625","0,25","0,16","0,84"]','Для соглашения с номером испытания E(X)=1/p. Поэтому p=1/6,25=0,16.','Geometrik tasodifiy kattalik uchun kutiladigan sinov raqami 6.25. p ni toping.','["0.625","0.25","0.16","0.84"]','Sinov raqami konvensiyasida E(X)=1/p. Demak p=1/6.25=0.16.',60),
('P5GEO03-A02','P5-GEO-03','P5 Geometric','medium','mcq','For geometric X with p=0.4, what is E(X)?','["1.5","2.5","4","0.4"]','B','E(X)=1/p=1/0.4=2.5 trials.','Для геометрической X с p=0,4 чему равно E(X)?','["1,5","2,5","4","0,4"]','E(X)=1/p=1/0,4=2,5 испытания.','p=0.4 bo‘lgan geometrik X uchun E(X) qancha?','["1.5","2.5","4","0.4"]','E(X)=1/p=1/0.4=2.5 ta sinov.',55),
('P5GEO03-A03','P5-GEO-03','P5 Geometric','medium','input','Independent trials have success probability 0.25 and each trial takes 3 minutes. Enter the expected number of minutes up to and including the first success.','[]','12','E(X)=1/0.25=4 trials. At 3 minutes per trial, the expected time is 4×3=12 minutes.','Независимые испытания имеют вероятность успеха 0,25, каждое испытание занимает 3 минуты. Введите ожидаемое число минут до первого успеха включительно.','[]','E(X)=1/0,25=4 испытания. При 3 минутах на испытание ожидаемое время равно 4×3=12 минут.','Mustaqil sinovlarda muvaffaqiyat ehtimoli 0.25 va har bir sinov 3 daqiqa davom etadi. Birinchi muvaffaqiyatgacha, muvaffaqiyatli sinovni ham hisobga olgan holda, kutiladigan daqiqalar sonini kiriting.','[]','E(X)=1/0.25=4 ta sinov. Har bir sinov 3 daqiqa bo‘lsa, kutiladigan vaqt 4×3=12 daqiqa.',65),

('P5NOR01-A01','P5-NOR-01','P5 Normal','medium','mcq','If X~N(72,25), which statement is correct?','["The mean is 72 and the standard deviation is 5","The mean is 72 and the standard deviation is 25","The mean is 5 and the standard deviation is 72","The variance is 5 and the mean is 25"]','A','In N(μ,σ²), the second parameter is the variance. Here μ=72 and σ=√25=5.','Если X~N(72,25), какое утверждение верно?','["Среднее равно 72, стандартное отклонение равно 5","Среднее равно 72, стандартное отклонение равно 25","Среднее равно 5, стандартное отклонение равно 72","Дисперсия равна 5, среднее равно 25"]','В N(μ,σ²) второй параметр — дисперсия. Здесь μ=72 и σ=√25=5.','Agar X~N(72,25) bo‘lsa, qaysi fikr to‘g‘ri?','["O‘rtacha 72, standart og‘ish 5","O‘rtacha 72, standart og‘ish 25","O‘rtacha 5, standart og‘ish 72","Dispersiya 5, o‘rtacha 25"]','N(μ,σ²) da ikkinchi parametr dispersiya. Bu yerda μ=72 va σ=√25=5.',60),
('P5NOR01-A02','P5-NOR-01','P5 Normal','medium','mcq','Which variable is least suitable for a normal model?','["Fill mass from a stable packing process, measured continuously","Adult height in a large homogeneous group","Small measurement error around a calibrated zero","Number of coin tosses until the first head"]','D','The number of tosses until the first head is a discrete waiting-time variable, naturally geometric rather than normal.','Какая величина меньше всего подходит для нормальной модели?','["Масса наполнения при стабильном процессе упаковки, измеряемая непрерывно","Рост взрослых в большой однородной группе","Небольшая ошибка измерения около откалиброванного нуля","Число бросков монеты до первого орла"]','Число бросков до первого орла — дискретная величина времени ожидания, естественно описываемая геометрическим, а не нормальным распределением.','Qaysi o‘zgaruvchi normal modelga eng kam mos keladi?','["Barqaror qadoqlash jarayonidagi uzluksiz o‘lchanadigan to‘ldirish massasi","Katta bir xil guruhdagi kattalar bo‘yi","Kalibrlangan nol atrofidagi kichik o‘lchash xatosi","Birinchi gerbgacha tanga tashlashlar soni"]','Birinchi gerbgacha tashlashlar soni diskret kutish vaqti bo‘lib, normal emas, tabiiy ravishda geometrik taqsimotga mos keladi.',65),
('P5NOR01-A03','P5-NOR-01','P5 Normal','medium','input','If Y~N(100,144), enter the standard deviation of Y.','[]','12','The second parameter is σ²=144, so σ=12.','Если Y~N(100,144), введите стандартное отклонение Y.','[]','Второй параметр σ²=144, поэтому σ=12.','Agar Y~N(100,144) bo‘lsa, Y ning standart og‘ishini kiriting.','[]','Ikkinchi parametr σ²=144, demak σ=12.',50)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,s.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P5:p5_aw17_20_alt_learning_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw17_20_alt_learning_draft_v1:'||s.content_key);

insert into private.exam_prep_written_tasks(
 id,content_version_id,task_key,component_code,primary_skill_code,secondary_skill_codes,task_version,
 prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
 lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(15659,4818,'P5BIN02-AW18','P5','P5-BIN-02','{}','v1','A seed has probability 0.75 of germinating, independently of the others. Ten seeds are planted and X is the number that germinate. (a) Find P(X=10). (b) Find P(X≥9). (c) Find P(X≤8) using a complement. Show the binomial terms you use and give final probabilities to 4 decimal places.','Семя прорастает с вероятностью 0,75 независимо от остальных. Высаживают 10 семян, X — число проросших. (a) Найдите P(X=10). (b) Найдите P(X≥9). (c) Найдите P(X≤8), используя дополнение. Покажите использованные биномиальные члены и дайте итоговые вероятности с точностью до 4 знаков.','Urug‘ boshqa urug‘lardan mustaqil ravishda 0.75 ehtimol bilan unadi. 10 ta urug‘ ekiladi, X — ungan urug‘lar soni. (a) P(X=10) ni toping. (b) P(X≥9) ni toping. (c) To‘ldiruvchi hodisadan foydalanib P(X≤8) ni toping. Ishlatilgan binomial hadlarni ko‘rsating va yakuniy ehtimollarni 4 ta o‘nli xonagacha bering.','{"criteria":[{"id":"model","rule":"Uses X~B(10,0.75) consistently.","marks":1},{"id":"all","rule":"Gets P(X=10)=0.75^10.","marks":1},{"id":"at_least_nine","rule":"Uses P(X=9)+P(X=10) correctly.","marks":1},{"id":"complement","rule":"Uses P(X≤8)=1−P(X≥9).","marks":1},{"id":"accuracy","rule":"Evaluates the requested probabilities accurately to 4 decimal places.","marks":1},{"id":"working","rule":"Shows correct binomial coefficients/powers and a coherent complement step.","marks":1}],"max_marks":6}'::jsonb,'For “at least 9”, only X=9 and X=10 are possible. Then P(X≤8) is the complement of that same event.','Для «не менее 9» возможны только X=9 и X=10. Затем P(X≤8) является дополнением этого события.','“Kamida 9” uchun faqat X=9 va X=10 mumkin. So‘ng P(X≤8) shu hodisaning to‘ldiruvchisidir.','draft','pending','pending','pending','pending'),
(15660,4818,'P5BIN03-AW18','P5','P5-BIN-03','{}','v1','A binomial random variable has mean 15 and variance 10.5. (a) Find p. (b) Find n. (c) Find the standard deviation. Explain why dividing the variance by the mean gives 1−p.','Биномиальная случайная величина имеет математическое ожидание 15 и дисперсию 10,5. (a) Найдите p. (b) Найдите n. (c) Найдите стандартное отклонение. Объясните, почему деление дисперсии на среднее даёт 1−p.','Binomial tasodifiy kattalikning kutiladigan qiymati 15 va dispersiyasi 10.5. (a) p ni toping. (b) n ni toping. (c) Standart og‘ishni toping. Nega dispersiyani o‘rtachaga bo‘lish 1−p ni berishini tushuntiring.','{"criteria":[{"id":"ratio","rule":"Uses 10.5/15=0.7=1−p.","marks":1},{"id":"p","rule":"Finds p=0.3.","marks":1},{"id":"n","rule":"Uses np=15 to find n=50.","marks":1},{"id":"sd","rule":"Finds standard deviation √10.5.","marks":1},{"id":"explain","rule":"Explains np(1−p)/(np)=1−p.","marks":1},{"id":"working","rule":"Keeps the binomial parameter conditions and algebra consistent.","marks":1}],"max_marks":6}'::jsonb,'Use E(X)=np and Var(X)=np(1−p). Their ratio removes n and p together, leaving 1−p.','Используйте E(X)=np и Var(X)=np(1−p). Их отношение сокращает np и оставляет 1−p.','E(X)=np va Var(X)=np(1−p) dan foydalaning. Ularning nisbati np ni qisqartirib, 1−p ni qoldiradi.','draft','pending','pending','pending','pending'),
(15661,4818,'P5GEO02-AW18','P5','P5-GEO-02','{}','v1','Independent trials have success probability 0.35, and X is the trial number of the first success. (a) Find P(X=4). (b) Find P(X>5). (c) Find P(X≤3). (d) Find P(2≤X≤4). Show where a complement or tail difference is efficient.','Независимые испытания имеют вероятность успеха 0,35, X — номер испытания, на котором впервые происходит успех. (a) Найдите P(X=4). (b) Найдите P(X>5). (c) Найдите P(X≤3). (d) Найдите P(2≤X≤4). Покажите, где удобно использовать дополнение или разность хвостовых вероятностей.','Mustaqil sinovlarda muvaffaqiyat ehtimoli 0.35, X — birinchi muvaffaqiyat sodir bo‘ladigan sinov raqami. (a) P(X=4) ni toping. (b) P(X>5) ni toping. (c) P(X≤3) ni toping. (d) P(2≤X≤4) ni toping. Qayerda to‘ldiruvchi hodisa yoki dum ehtimollari farqidan foydalanish qulayligini ko‘rsating.','{"criteria":[{"id":"point","rule":"Uses P(X=4)=0.65^3(0.35).","marks":1},{"id":"tail","rule":"Uses P(X>5)=0.65^5.","marks":1},{"id":"cumulative","rule":"Uses P(X≤3)=1−0.65^3.","marks":1},{"id":"interval","rule":"Uses a correct sum or tail difference for P(2≤X≤4).","marks":1},{"id":"method","rule":"Identifies an efficient complement/tail method correctly.","marks":1},{"id":"working","rule":"Uses the trial-number convention consistently.","marks":1}],"max_marks":6}'::jsonb,'For the trial-number convention, P(X>k)=(1−p)^k. This makes both cumulative and interval probabilities easier.','Для соглашения с номером испытания P(X>k)=(1−p)^k. Это упрощает накопленные и интервальные вероятности.','Sinov raqami konvensiyasida P(X>k)=(1−p)^k. Bu yig‘ma va oraliq ehtimollarni osonlashtiradi.','draft','pending','pending','pending','pending'),
(15662,4818,'P5GEO03-AW18','P5','P5-GEO-03','{}','v1','A process is repeated independently until the first success. The expected trial number of the first success is 4. (a) Find p. (b) If each trial takes 2 minutes, find the expected time to the first success. (c) If the success probability were 0.5 instead, find the new expected trial number. (d) Explain what an expected trial number of 4 means.','Процесс независимо повторяют до первого успеха. Ожидаемый номер испытания первого успеха равен 4. (a) Найдите p. (b) Если каждое испытание длится 2 минуты, найдите ожидаемое время до первого успеха. (c) Если вероятность успеха вместо этого равна 0,5, найдите новый ожидаемый номер испытания. (d) Объясните, что означает ожидаемый номер испытания 4.','Jarayon birinchi muvaffaqiyatgacha mustaqil takrorlanadi. Birinchi muvaffaqiyatning kutiladigan sinov raqami 4. (a) p ni toping. (b) Har bir sinov 2 daqiqa davom etsa, birinchi muvaffaqiyatgacha kutiladigan vaqtni toping. (c) Agar muvaffaqiyat ehtimoli 0.5 bo‘lsa, yangi kutiladigan sinov raqamini toping. (d) Kutiladigan sinov raqami 4 nimani anglatishini tushuntiring.','{"criteria":[{"id":"p","rule":"Uses E(X)=1/p to find p=0.25.","marks":1},{"id":"time","rule":"Finds expected time 4×2=8 minutes.","marks":1},{"id":"new_mean","rule":"For p=0.5, finds E(X)=2.","marks":1},{"id":"interpret","rule":"Explains 4 as a long-run average trial number over many repeated experiments, not a guarantee.","marks":2},{"id":"convention","rule":"Uses the trial-number convention consistently, including the successful trial.","marks":1}],"max_marks":6}'::jsonb,'Expectation is a long-run average. It does not mean that the first success must occur on trial 4 in any one experiment.','Математическое ожидание — это долгосрочное среднее. Оно не означает, что в каждом отдельном эксперименте первый успех обязан произойти в 4-м испытании.','Kutilma uzoq muddatli o‘rtacha qiymat. Bu har bir alohida tajribada birinchi muvaffaqiyat albatta 4-sinovda bo‘ladi degani emas.','draft','pending','pending','pending','pending'),
(15663,4818,'P5NOR01-AW18','P5','P5-NOR-01','{}','v1','A stable filling process produces packet masses that are continuous and approximately symmetric about 500 g. A separate variable records the number of inspections until the first defective packet. (a) State which variable is more plausibly modelled by a normal distribution and justify your choice. (b) If the packet mass is modelled as X~N(500,16), state μ, σ² and σ. (c) Describe or sketch the normal curve with the centre and one-standard-deviation points labelled.','Стабильный процесс наполнения даёт массы пакетов, которые являются непрерывными и примерно симметричными около 500 г. Другая величина показывает число проверок до первого дефектного пакета. (a) Укажите, какая величина правдоподобнее моделируется нормальным распределением, и обоснуйте выбор. (b) Если масса пакета моделируется как X~N(500,16), укажите μ, σ² и σ. (c) Опишите или нарисуйте нормальную кривую, отметив центр и точки на одно стандартное отклонение от центра.','Barqaror to‘ldirish jarayonida paket massalari uzluksiz va 500 g atrofida taxminan simmetrik. Boshqa o‘zgaruvchi birinchi nuqsonli paketgacha bo‘lgan tekshiruvlar sonini qayd etadi. (a) Qaysi o‘zgaruvchi normal taqsimot bilan ishonchliroq modellashtirilishini ayting va asoslang. (b) Paket massasi X~N(500,16) bilan modellashtirilsa, μ, σ² va σ ni yozing. (c) Markaz va undan bitta standart og‘ishdagi nuqtalar belgilangan normal egri chiziqni tasvirlang yoki chizing.','{"criteria":[{"id":"choice","rule":"Chooses packet mass as the plausible normal variable.","marks":1},{"id":"reason","rule":"Uses continuous measurement plus approximate symmetry/stable centre as justification and rejects waiting time as discrete geometric structure.","marks":2},{"id":"parameters","rule":"States μ=500, σ²=16 and σ=4.","marks":1},{"id":"curve","rule":"Shows/describes a symmetric bell-shaped curve centred at 500.","marks":1},{"id":"labels","rule":"Labels one-standard-deviation points 496 and 504.","marks":1}],"max_marks":6}'::jsonb,'Normal modelling is about the type and shape of the variable, not just whether many observations are available. In N(μ,σ²), the second parameter is variance.','Нормальная модель зависит от типа и формы величины, а не только от большого числа наблюдений. В N(μ,σ²) второй параметр — дисперсия.','Normal model o‘zgaruvchining turi va shakliga bog‘liq, faqat kuzatuvlar sonining ko‘pligiga emas. N(μ,σ²) da ikkinchi parametr dispersiyadir.','draft','pending','pending','pending','pending')
on conflict(id) do nothing;

with src(content_key,skill_code,meta_id,official_ref,book_ref) as (values
('P5BIN02-A01','P5-BIN-02',59408,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN02-A02','P5-BIN-02',59409,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN02-A03','P5-BIN-02',59410,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN03-A01','P5-BIN-03',59411,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN03-A02','P5-BIN-03',59412,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN03-A03','P5-BIN-03',59413,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5GEO02-A01','P5-GEO-02',59414,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO02-A02','P5-GEO-02',59415,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO02-A03','P5-GEO-02',59416,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO03-A01','P5-GEO-03',59417,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO03-A02','P5-GEO-03',59418,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO03-A03','P5-GEO-03',59419,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5NOR01-A01','P5-NOR-01',59420,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1, Ch9 The normal distribution pp.147-171 (mapping only)'),
('P5NOR01-A02','P5-NOR-01',59421,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1, Ch9 The normal distribution pp.147-171 (mapping only)'),
('P5NOR01-A03','P5-NOR-01',59422,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1, Ch9 The normal distribution pp.147-171 (mapping only)')
)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,4818,s.content_key,q.id,s.skill_code,'{}'::text[],'learning','withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'Supplemental AW17-20 learning draft authored from the canonical skill intent with independent values and contexts, separate from the existing teaching pack.',
 s.official_ref,s.book_ref,
 'pending','pending','pending','pending','pending','not_applicable',
 md5(concat_ws(chr(31),
   q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),
   coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
   coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),
   coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
   coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),
   coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')
 ))
from src s
join public.questions q on q.book_ref='ExamPrep:P5:p5_aw17_20_alt_learning_draft_v1:'||s.content_key
on conflict(id) do nothing;

insert into private.exam_prep_assessments(
 id,content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
overriding system value
values
(35478,4818,'P5-BIN-02-learning-alt-04','v1','P5','learning','draft','Binomial probabilities','Биномиальные вероятности','Binomial ehtimollar'),
(35479,4818,'P5-BIN-03-learning-alt-04','v1','P5','learning','draft','Binomial mean, variance and parameters','Биномиальные среднее, дисперсия и параметры','Binomial o‘rtacha, dispersiya va parametrlar'),
(35480,4818,'P5-GEO-02-learning-alt-04','v1','P5','learning','draft','Geometric probabilities','Геометрические вероятности','Geometrik ehtimollar'),
(35481,4818,'P5-GEO-03-learning-alt-04','v1','P5','learning','draft','Geometric expectation and parameter','Математическое ожидание и параметр геометрического распределения','Geometrik kutilma va parametr'),
(35482,4818,'P5-NOR-01-learning-alt-04','v1','P5','learning','draft','Recognising the normal model','Распознавание нормальной модели','Normal modelni aniqlash')
on conflict(id) do nothing;

with items(assessment_id,item_order,content_key,written_id,skill_code) as (values
(35478,1,'P5BIN02-A01',null::bigint,'P5-BIN-02'),
(35478,2,'P5BIN02-A02',null::bigint,'P5-BIN-02'),
(35478,3,'P5BIN02-A03',null::bigint,'P5-BIN-02'),
(35478,4,null,15659,'P5-BIN-02'),
(35479,1,'P5BIN03-A01',null::bigint,'P5-BIN-03'),
(35479,2,'P5BIN03-A02',null::bigint,'P5-BIN-03'),
(35479,3,'P5BIN03-A03',null::bigint,'P5-BIN-03'),
(35479,4,null,15660,'P5-BIN-03'),
(35480,1,'P5GEO02-A01',null::bigint,'P5-GEO-02'),
(35480,2,'P5GEO02-A02',null::bigint,'P5-GEO-02'),
(35480,3,'P5GEO02-A03',null::bigint,'P5-GEO-02'),
(35480,4,null,15661,'P5-GEO-02'),
(35481,1,'P5GEO03-A01',null::bigint,'P5-GEO-03'),
(35481,2,'P5GEO03-A02',null::bigint,'P5-GEO-03'),
(35481,3,'P5GEO03-A03',null::bigint,'P5-GEO-03'),
(35481,4,null,15662,'P5-GEO-03'),
(35482,1,'P5NOR01-A01',null::bigint,'P5-NOR-01'),
(35482,2,'P5NOR01-A02',null::bigint,'P5-NOR-01'),
(35482,3,'P5NOR01-A03',null::bigint,'P5-NOR-01'),
(35482,4,null,15663,'P5-NOR-01')
)
insert into private.exam_prep_assessment_items(
 assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select i.assessment_id,i.item_order,q.id,i.written_id,i.skill_code,
 case when i.content_key is null then 'written' else 'learning' end,false
from items i
left join public.questions q on i.content_key is not null
 and q.book_ref='ExamPrep:P5:p5_aw17_20_alt_learning_draft_v1:'||i.content_key
on conflict(assessment_id,item_order) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  if (select status from private.exam_prep_content_versions where id=4818)<>'draft'
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4818 and lifecycle_state='draft' and reserve_role='learning')<>15
     or (select count(*) from private.exam_prep_written_tasks where content_version_id=4818 and lifecycle_state='draft')<>5
     or (select count(*) from private.exam_prep_assessments where content_version_id=4818 and status='draft' and assessment_type='learning')<>5
     or (select count(*) from private.exam_prep_assessment_items ai join private.exam_prep_assessments a on a.id=ai.assessment_id where a.content_version_id=4818)<>20
  then raise exception 'aw17_20_alt_p5_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4818 and (
    m.exposure_state<>'withheld' or m.copyright_status<>'pending' or m.qa_scope_status<>'pending'
    or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or q.is_active or q.quality_status<>'draft'
  );
  if v_bad<>0 then raise exception 'aw17_20_alt_p5_draft exposure/QA boundary rows=%',v_bad; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),
         count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id where m.content_version_id=4818;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(2,2,3,3,5) then
    raise exception 'aw17_20_alt_p5_draft answer balance drift A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4818
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4818
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw17_20_alt_p5_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4818)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4818)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4818)
  then raise exception 'aw17_20_alt_p5_draft unexpected history'; end if;
end
$postcheck$;

commit;
