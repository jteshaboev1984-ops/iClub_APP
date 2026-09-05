-- P1-02 P5 AW9-12 counting/probability completion: CNT-05, PRO-02, PRO-04.
-- Original iClub-authored content only. Atomic governed publication; legacy questions stay draft + inactive.

begin;

insert into private.exam_prep_content_versions(
  program_version_id,content_version,component_code,release_label,status,source_policy
)
select pv.id,'p5_aw09_12_count_prob_v1','P5','P5 AW9-12 Combinations + probability completion','draft','Original iClub content only; Cambridge 9709 official syllabus defines scope; Complete Probability & Statistics 1 is mapping/teaching reference only; no Cambridge/coursebook question, diagram, answer or mark-scheme wording copied.'
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0'
on conflict(program_version_id,content_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_aw09_12_count_prob_v1' and component_code='P5' and status='draft'
), src(skill,k,role,diff,qen,qru,quz,o_en,o_ru,o_uz,ans,een,eru,euz,secs) as (values
('P5-CNT-05','P5CNT05-D01','diagnostic','medium','A committee of 4 students is chosen from 10 students. How many different committees are possible?','Из 10 учеников выбирают комитет из 4 человек. Сколько различных комитетов возможно?','10 o‘quvchidan 4 kishilik qo‘mita tanlanadi. Nechta turli qo‘mita mumkin?','["210", "5040", "40", "24"]','["210", "5040", "40", "24"]','["210", "5040", "40", "24"]','A','Order does not matter for a committee, so use C(10,4)=210.','Порядок в комитете не важен, поэтому C(10,4)=210.','Qo‘mitada tartib muhim emas, shuning uchun C(10,4)=210.',65),
('P5-CNT-05','P5CNT05-L01','learning','easy','How many ways can 3 students be selected from 8 students?','Сколькими способами можно выбрать 3 учеников из 8?','8 o‘quvchidan 3 tasini nechta usulda tanlash mumkin?','["56", "336", "24", "11"]','["56", "336", "24", "11"]','["56", "336", "24", "11"]','A','This is an unordered selection: C(8,3)=56.','Это выбор без порядка: C(8,3)=56.','Bu tartibsiz tanlash: C(8,3)=56.',50),
('P5-CNT-05','P5CNT05-L02','learning','medium','A team is formed by choosing 2 boys from 5 and 2 girls from 6. How many teams are possible?','Команду формируют, выбирая 2 мальчиков из 5 и 2 девочек из 6. Сколько команд возможно?','Jamoa 5 o‘g‘il boladan 2 tasi va 6 qizdan 2 tasini tanlash orqali tuziladi. Nechta jamoa mumkin?','["150", "60", "300", "30"]','["150", "60", "300", "30"]','["150", "60", "300", "30"]','A','Choose the groups independently: C(5,2)×C(6,2)=10×15=150.','Выбираем группы независимо: C(5,2)×C(6,2)=10×15=150.','Guruhlarni alohida tanlaymiz: C(5,2)×C(6,2)=10×15=150.',70),
('P5-CNT-05','P5CNT05-L03','learning','medium','A 4-person committee is chosen from 9 people, and Ali must be included. How many committees are possible?','Комитет из 4 человек выбирают из 9, причём Али обязательно входит в комитет. Сколько вариантов?','9 kishidan 4 kishilik qo‘mita tanlanadi va Ali albatta bo‘lishi kerak. Nechta qo‘mita mumkin?','["56", "70", "126", "168"]','["56", "70", "126", "168"]','["56", "70", "126", "168"]','A','Ali is fixed, so choose the remaining 3 members from the other 8: C(8,3)=56.','Али уже выбран, остаётся выбрать 3 из остальных 8: C(8,3)=56.','Ali oldindan tanlangan, qolgan 8 kishidan 3 tasini tanlaymiz: C(8,3)=56.',65),
('P5-CNT-05','P5CNT05-R01','retest','easy','How many ways can 5 objects be chosen from 7 distinct objects?','Сколькими способами можно выбрать 5 объектов из 7 различных?','7 ta turli obyektdan 5 tasini nechta usulda tanlash mumkin?','["21", "35", "2520", "12"]','["21", "35", "2520", "12"]','["21", "35", "2520", "12"]','A','C(7,5)=C(7,2)=21.','C(7,5)=C(7,2)=21.','C(7,5)=C(7,2)=21.',45),
('P5-CNT-05','P5CNT05-R02','retest','medium','From 8 students, one captain and two unordered assistants are chosen. How many selections are possible?','Из 8 учеников выбирают одного капитана и двух помощников без различия ролей между помощниками. Сколько вариантов?','8 o‘quvchidan 1 kapitan va o‘zaro rollari farqlanmaydigan 2 yordamchi tanlanadi. Nechta variant?','["168", "336", "56", "24"]','["168", "336", "56", "24"]','["168", "336", "56", "24"]','A','Choose the captain in 8 ways, then choose 2 assistants from the remaining 7: 8×C(7,2)=168.','Капитана выбираем 8 способами, затем 2 помощников из оставшихся 7: 8×C(7,2)=168.','Kapitanni 8 usulda, so‘ng qolgan 7 kishidan 2 yordamchini tanlaymiz: 8×C(7,2)=168.',75),
('P5-CNT-05','P5CNT05-M01','mixed','medium','Three of 7 distinct books are selected and then arranged on three labelled shelves, one book per shelf. How many outcomes are possible?','Из 7 разных книг выбирают 3, затем размещают их на трёх подписанных полках по одной книге. Сколько исходов возможно?','7 ta turli kitobdan 3 tasi tanlanadi, keyin uchta nomlangan tokchaga bittadan joylanadi. Nechta natija mumkin?','["210", "35", "105", "343"]','["210", "35", "105", "343"]','["210", "35", "105", "343"]','A','Select 3 books and then arrange them: C(7,3)×3! = 35×6 = 210, equivalently 7P3.','Сначала выбираем 3 книги, затем расставляем: C(7,3)×3! = 35×6 = 210, то же самое что 7P3.','Avval 3 kitobni tanlaymiz, keyin joylaymiz: C(7,3)×3! = 35×6 = 210, ya’ni 7P3.',80),
('P5-PRO-02','P5PRO02-D01','diagnostic','medium','A bag contains 5 red and 3 blue counters. Two counters are chosen at random without replacement. What is the probability that both are red, using combinations?','В мешке 5 красных и 3 синих фишки. Случайно без возвращения выбирают 2 фишки. Найдите вероятность того, что обе красные, используя сочетания.','Xaltada 5 qizil va 3 ko‘k chip bor. 2 ta chip qaytarmasdan tasodifiy tanlanadi. Ikkalasi ham qizil bo‘lish ehtimolini kombinatsiyalar orqali toping.','["5/14", "10/64", "25/64", "3/8"]','["5/14", "10/64", "25/64", "3/8"]','["5/14", "10/64", "25/64", "3/8"]','A','There are C(8,2)=28 unordered pairs, and C(5,2)=10 red-red pairs. Probability = 10/28 = 5/14.','Всего C(8,2)=28 неупорядоченных пар, из них C(5,2)=10 красно-красных. Вероятность = 10/28 = 5/14.','Jami C(8,2)=28 tartibsiz juft, qizil-qizil juftlar C(5,2)=10. Ehtimol = 10/28 = 5/14.',80),
('P5-PRO-02','P5PRO02-L01','learning','medium','From 6 men and 4 women, 3 people are chosen at random. What is the probability that exactly 2 women are chosen?','Из 6 мужчин и 4 женщин случайно выбирают 3 человек. Какова вероятность выбрать ровно 2 женщин?','6 erkak va 4 ayoldan tasodifiy 3 kishi tanlanadi. Aynan 2 ayol tanlanish ehtimoli nechaga teng?','["3/10", "1/5", "1/2", "2/5"]','["3/10", "1/5", "1/2", "2/5"]','["3/10", "1/5", "1/2", "2/5"]','A','Favourable selections: C(4,2)C(6,1)=36. Total selections: C(10,3)=120. Probability = 36/120 = 3/10.','Благоприятных выборов C(4,2)C(6,1)=36, всего C(10,3)=120. Вероятность 36/120=3/10.','Qulay tanlovlar C(4,2)C(6,1)=36, jami C(10,3)=120. Ehtimol 36/120=3/10.',90),
('P5-PRO-02','P5PRO02-L02','learning','medium','Ten cards contain 4 marked cards and 6 unmarked cards. Three cards are chosen at random. What is the probability of choosing exactly 2 marked cards?','Из 10 карточек 4 отмечены, 6 не отмечены. Случайно выбирают 3 карточки. Какова вероятность выбрать ровно 2 отмеченные?','10 kartadan 4 tasi belgilangan, 6 tasi belgilanmagan. 3 karta tasodifiy tanlanadi. Aynan 2 belgilangan karta chiqish ehtimoli?','["3/10", "2/5", "1/6", "3/5"]','["3/10", "2/5", "1/6", "3/5"]','["3/10", "2/5", "1/6", "3/5"]','A','C(4,2)C(6,1)/C(10,3)=6×6/120=36/120=3/10.','C(4,2)C(6,1)/C(10,3)=6×6/120=36/120=3/10.','C(4,2)C(6,1)/C(10,3)=6×6/120=36/120=3/10.',85),
('P5-PRO-02','P5PRO02-L03','learning','medium','A committee of 4 is chosen at random from 10 people. What is the probability that two particular people, A and B, are both selected?','Комитет из 4 человек случайно выбирают из 10. Какова вероятность, что два конкретных человека A и B оба войдут в комитет?','10 kishidan tasodifiy 4 kishilik qo‘mita tanlanadi. Muayyan A va B kishilarning ikkalasi ham tanlanish ehtimoli?','["2/15", "1/5", "4/10", "1/15"]','["2/15", "1/5", "4/10", "1/15"]','["2/15", "1/5", "4/10", "1/15"]','A','With A and B fixed, choose 2 more from the remaining 8: C(8,2)=28. Divide by C(10,4)=210: 28/210=2/15.','A и B уже выбраны; выбираем ещё 2 из 8: C(8,2)=28. Делим на C(10,4)=210: 28/210=2/15.','A va B oldindan tanlangan; qolgan 8 kishidan yana 2 tasini tanlaymiz: C(8,2)=28. C(10,4)=210 ga bo‘lamiz: 2/15.',90),
('P5-PRO-02','P5PRO02-R01','retest','medium','A box contains 7 green and 5 yellow balls. Two balls are chosen without replacement. What is the probability both are yellow?','В коробке 7 зелёных и 5 жёлтых шаров. Без возвращения выбирают 2 шара. Какова вероятность, что оба жёлтые?','Qutida 7 yashil va 5 sariq shar bor. Qaytarmasdan 2 shar tanlanadi. Ikkalasi ham sariq bo‘lish ehtimoli?','["5/33", "5/12", "10/144", "25/144"]','["5/33", "5/12", "10/144", "25/144"]','["5/33", "5/12", "10/144", "25/144"]','A','C(5,2)/C(12,2)=10/66=5/33.','C(5,2)/C(12,2)=10/66=5/33.','C(5,2)/C(12,2)=10/66=5/33.',70),
('P5-PRO-02','P5PRO02-R02','retest','medium','Three people are chosen at random from 9 people. What is the probability that a particular person is selected?','Из 9 человек случайно выбирают 3. Какова вероятность, что конкретный человек будет выбран?','9 kishidan tasodifiy 3 kishi tanlanadi. Muayyan bir kishining tanlanish ehtimoli?','["1/3", "1/9", "2/3", "3/8"]','["1/3", "1/9", "2/3", "3/8"]','["1/3", "1/9", "2/3", "3/8"]','A','Favourable committees contain that person plus 2 of the other 8: C(8,2)=28. Total C(9,3)=84, so probability 28/84=1/3.','Благоприятные комитеты содержат этого человека и ещё 2 из 8: C(8,2)=28. Всего C(9,3)=84, значит 1/3.','Qulay qo‘mitalarda shu kishi va qolgan 8 kishidan 2 tasi bor: C(8,2)=28. Jami C(9,3)=84, demak 1/3.',75),
('P5-PRO-02','P5PRO02-M01','mixed','hard','From 5 boys and 4 girls, 3 students are chosen at random. What is the probability that at least one girl is chosen?','Из 5 мальчиков и 4 девочек случайно выбирают 3 учеников. Какова вероятность, что будет выбрана хотя бы одна девочка?','5 o‘g‘il va 4 qizdan tasodifiy 3 o‘quvchi tanlanadi. Kamida bitta qiz tanlanish ehtimoli?','["37/42", "5/42", "4/9", "31/42"]','["37/42", "5/42", "4/9", "31/42"]','["37/42", "5/42", "4/9", "31/42"]','A','Use the complement. P(no girls)=C(5,3)/C(9,3)=10/84=5/42. Therefore P(at least one girl)=1−5/42=37/42.','Используем дополнение. P(без девочек)=C(5,3)/C(9,3)=10/84=5/42. Поэтому P(хотя бы одна девочка)=37/42.','Complement ishlatamiz. P(qiz yo‘q)=C(5,3)/C(9,3)=10/84=5/42. Demak P(kamida bitta qiz)=37/42.',95),
('P5-PRO-04','P5PRO04-D01','diagnostic','medium','Events A and B are independent with P(A)=0.4 and P(B)=0.5. Find P(A ∩ B).','События A и B независимы, P(A)=0,4 и P(B)=0,5. Найдите P(A ∩ B).','A va B hodisalar mustaqil, P(A)=0.4 va P(B)=0.5. P(A ∩ B) ni toping.','["0.20", "0.90", "0.45", "0.10"]','["0.20", "0.90", "0.45", "0.10"]','["0.20", "0.90", "0.45", "0.10"]','A','For independent events, P(A∩B)=P(A)P(B)=0.4×0.5=0.20.','Для независимых событий P(A∩B)=P(A)P(B)=0,4×0,5=0,20.','Mustaqil hodisalar uchun P(A∩B)=P(A)P(B)=0.4×0.5=0.20.',55),
('P5-PRO-04','P5PRO04-L01','learning','easy','Independent events C and D have probabilities 0.3 and 0.6. What is P(C ∩ D)?','Независимые события C и D имеют вероятности 0,3 и 0,6. Чему равно P(C ∩ D)?','Mustaqil C va D hodisalarning ehtimollari 0.3 va 0.6. P(C ∩ D) nechaga teng?','["0.18", "0.90", "0.45", "0.30"]','["0.18", "0.90", "0.45", "0.30"]','["0.18", "0.90", "0.45", "0.30"]','A','Multiply independent probabilities: 0.3×0.6=0.18.','Перемножаем вероятности независимых событий: 0,3×0,6=0,18.','Mustaqil ehtimollarni ko‘paytiramiz: 0.3×0.6=0.18.',45),
('P5-PRO-04','P5PRO04-L02','learning','medium','P(A)=0.3, P(B)=0.4 and P(A ∩ B)=0.12. Are A and B independent?','P(A)=0,3, P(B)=0,4 и P(A ∩ B)=0,12. Независимы ли A и B?','P(A)=0.3, P(B)=0.4 va P(A ∩ B)=0.12. A va B mustaqilmi?','["Yes, because 0.3×0.4=0.12", "No, because 0.3+0.4≠0.12", "Yes, because P(A)+P(B)=0.7", "No, because both probabilities are below 0.5"]','["Да, потому что 0,3×0,4=0,12", "Нет, потому что 0,3+0,4≠0,12", "Да, потому что P(A)+P(B)=0,7", "Нет, потому что обе вероятности меньше 0,5"]','["Ha, chunki 0.3×0.4=0.12", "Yo‘q, chunki 0.3+0.4≠0.12", "Ha, chunki P(A)+P(B)=0.7", "Yo‘q, chunki ikkala ehtimol ham 0.5 dan kichik"]','A','Independence requires P(A∩B)=P(A)P(B). Here 0.3×0.4=0.12, so the condition holds.','Для независимости нужно P(A∩B)=P(A)P(B). Здесь 0,3×0,4=0,12, условие выполнено.','Mustaqillik uchun P(A∩B)=P(A)P(B). Bu yerda 0.3×0.4=0.12, shart bajarilgan.',70),
('P5-PRO-04','P5PRO04-L03','learning','medium','P(A)=0.7 and P(B | A)=0.2. Find P(A ∩ B).','P(A)=0,7 и P(B | A)=0,2. Найдите P(A ∩ B).','P(A)=0.7 va P(B | A)=0.2. P(A ∩ B) ni toping.','["0.14", "0.90", "0.35", "0.50"]','["0.14", "0.90", "0.35", "0.50"]','["0.14", "0.90", "0.35", "0.50"]','A','Use the multiplication rule P(A∩B)=P(A)P(B|A)=0.7×0.2=0.14.','По правилу умножения P(A∩B)=P(A)P(B|A)=0,7×0,2=0,14.','Ko‘paytirish qoidasi: P(A∩B)=P(A)P(B|A)=0.7×0.2=0.14.',65),
('P5-PRO-04','P5PRO04-R01','retest','easy','A fair coin is tossed and a fair die is rolled. What is the probability of a head and an even number?','Подбрасывают честную монету и бросают честный кубик. Какова вероятность получить орла и чётное число?','Adolatli tanga tashlanadi va kubik tashlanadi. Gerb va juft son chiqish ehtimoli?','["1/4", "1/2", "1/6", "3/4"]','["1/4", "1/2", "1/6", "3/4"]','["1/4", "1/2", "1/6", "3/4"]','A','The outcomes are independent: P(head)=1/2 and P(even)=3/6=1/2, so product = 1/4.','События независимы: P(орёл)=1/2, P(чётное)=1/2, произведение = 1/4.','Hodisalar mustaqil: P(gerb)=1/2, P(juft)=1/2, ko‘paytma =1/4.',55),
('P5-PRO-04','P5PRO04-R02','retest','medium','P(A ∩ B)=0.18 and P(A)=0.6. Find P(B | A).','P(A ∩ B)=0,18 и P(A)=0,6. Найдите P(B | A).','P(A ∩ B)=0.18 va P(A)=0.6. P(B | A) ni toping.','["0.30", "0.12", "0.78", "0.108"]','["0.30", "0.12", "0.78", "0.108"]','["0.30", "0.12", "0.78", "0.108"]','A','P(B|A)=P(A∩B)/P(A)=0.18/0.6=0.30.','P(B|A)=P(A∩B)/P(A)=0,18/0,6=0,30.','P(B|A)=P(A∩B)/P(A)=0.18/0.6=0.30.',60),
('P5-PRO-04','P5PRO04-M01','mixed','medium','Three independent events have probabilities 0.8, 0.5 and 0.25. What is the probability that all three occur?','Три независимых события имеют вероятности 0,8, 0,5 и 0,25. Какова вероятность, что произойдут все три?','Uchta mustaqil hodisaning ehtimollari 0.8, 0.5 va 0.25. Uchalasining ham sodir bo‘lish ehtimoli?','["0.10", "1.55", "0.40", "0.025"]','["0.10", "1.55", "0.40", "0.025"]','["0.10", "1.55", "0.40", "0.025"]','A','For independent events multiply all three probabilities: 0.8×0.5×0.25=0.10.','Для независимых событий перемножаем все три вероятности: 0,8×0,5×0,25=0,10.','Mustaqil hodisalar uchun uchala ehtimolni ko‘paytiramiz: 0.8×0.5×0.25=0.10.',60)
)
insert into public.questions(
  subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
  question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
  explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,case when s.skill='P5-CNT-05' then 'P5 Permutations and Combinations' else 'P5 Probability' end,s.skill,s.diff,'mcq',s.qen,s.o_en,s.ans,s.een,null,false,
       s.qru,s.quz,s.qen,s.o_ru,s.o_uz,s.o_en,s.eru,s.euz,s.een,
       'ExamPrep:P5:p5_aw09_12_count_prob_v1:'||s.k,s.secs,null,'draft'
from cv cross join src s
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw09_12_count_prob_v1:'||s.k);

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_aw09_12_count_prob_v1' and component_code='P5' and status='draft'
), keys(skill,k,role) as (values
('P5-CNT-05','P5CNT05-D01','diagnostic'),
('P5-CNT-05','P5CNT05-L01','learning'),
('P5-CNT-05','P5CNT05-L02','learning'),
('P5-CNT-05','P5CNT05-L03','learning'),
('P5-CNT-05','P5CNT05-R01','retest'),
('P5-CNT-05','P5CNT05-R02','retest'),
('P5-CNT-05','P5CNT05-M01','mixed'),
('P5-PRO-02','P5PRO02-D01','diagnostic'),
('P5-PRO-02','P5PRO02-L01','learning'),
('P5-PRO-02','P5PRO02-L02','learning'),
('P5-PRO-02','P5PRO02-L03','learning'),
('P5-PRO-02','P5PRO02-R01','retest'),
('P5-PRO-02','P5PRO02-R02','retest'),
('P5-PRO-02','P5PRO02-M01','mixed'),
('P5-PRO-04','P5PRO04-D01','diagnostic'),
('P5-PRO-04','P5PRO04-L01','learning'),
('P5-PRO-04','P5PRO04-L02','learning'),
('P5-PRO-04','P5PRO04-L03','learning'),
('P5-PRO-04','P5PRO04-R01','retest'),
('P5-PRO-04','P5PRO04-R02','retest'),
('P5-PRO-04','P5PRO04-M01','mixed')
)
insert into private.exam_prep_question_content_meta(
  content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
  exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
  copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
select cv.id,k.k,q.id,k.skill,'{}'::text[],k.role,'withheld','draft',
       'Original iClub-authored stem, numbers, distractors, answer and explanation; no Cambridge/coursebook question, diagram or mark-scheme wording copied.',
       'Authored for p5_aw09_12_count_prob_v1 from the canonical skill intent using independent examples.',
       'Cambridge 9709 2026-2027 v4; P5 5.2 Permutations and combinations + 5.3 Probability','Complete Probability & Statistics 1; Permutations/combinations and Probability (mapping only)',
       'pending','pending','pending','pending','pending',
       case when k.role='diagnostic' then 'pending' else 'not_applicable' end,
       md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
         coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),
         coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),
         coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
         coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
         coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
         coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from cv cross join keys k
join public.questions q on q.book_ref='ExamPrep:P5:p5_aw09_12_count_prob_v1:'||k.k
on conflict(content_version_id,content_key) do nothing;

with rules(ckey,match,dcode,mtype,weak_skill,fen,fru,fuz,nen,nru,nuz) as (values
('P5CNT05-D01','B','used_permutation_for_committee','concept','P5-CNT-05','A committee is an unordered selection. 10P4 counts the same four people many times in different orders.','Комитет — неупорядоченный выбор. 10P4 многократно считает тех же четырёх людей в разных порядках.','Qo‘mita tartibsiz tanlov. 10P4 bir xil to‘rt kishini turli tartiblarda qayta-qayta sanaydi.','Ask whether changing the order of the same four selected people creates a new committee.','Спросите, создаёт ли перестановка тех же четырёх людей новый комитет.','Bir xil to‘rt kishining tartibini o‘zgartirish yangi qo‘mita yaratadimi, tekshiring.'),
('P5CNT05-D01','C','multiplied_n_by_r','method','P5-CNT-05','Multiplying 10 by 4 does not count distinct 4-person subsets.','Умножение 10 на 4 не считает различные подмножества из 4 человек.','10 ni 4 ga ko‘paytirish 4 kishilik turli to‘plamlarni sanamaydi.','Use the combinations formula C(n,r)=n!/[r!(n−r)!].','Используйте формулу сочетаний C(n,r)=n!/[r!(n−r)!].','C(n,r)=n!/[r!(n−r)!] formulasidan foydalaning.'),
('P5CNT05-D01','D','used_r_factorial_only','method','P5-CNT-05','4! only counts orders of four already chosen people; it does not choose them from 10.','4! считает только порядки четырёх уже выбранных людей и не выбирает их из 10.','4! faqat oldindan tanlangan to‘rt kishining tartiblarini sanaydi, 10 kishidan tanlamaydi.','Separate the selection step from any arrangement step. Here there is selection only.','Отделите выбор от расстановки. Здесь есть только выбор.','Tanlash va joylashtirish bosqichlarini ajrating. Bu yerda faqat tanlash bor.'),
('P5PRO02-D01','B','used_ordered_sequential_denominator','method','P5-PRO-02','10/64 mixes an unordered favourable count with an ordered/replacement-style denominator. Use the same counting model in numerator and denominator.','10/64 смешивает неупорядоченный благоприятный счёт с неподходящим знаменателем. В числителе и знаменателе нужна одна модель.','10/64 surat va maxrajda turli sanash modelini aralashtiradi. Ikkalasida bir xil model ishlating.','Use C(5,2) favourable pairs over C(8,2) total pairs.','Используйте C(5,2) благоприятных пар из C(8,2) всех пар.','C(5,2) qulay juftlarni C(8,2) jami juftlarga bo‘ling.'),
('P5PRO02-D01','C','treated_draws_as_with_replacement','concept','P5-PRO-02','25/64 would come from 5/8×5/8, but the second draw is without replacement.','25/64 получилось бы из 5/8×5/8, но второй выбор идёт без возвращения.','25/64 = 5/8×5/8 qaytarish bilan bo‘lgan holatga mos; bu yerda qaytarilmaydi.','Either update the second probability to 4/7 or use combinations consistently.','Либо используйте вторую вероятность 4/7, либо последовательно примените сочетания.','Ikkinchi ehtimolni 4/7 ga yangilang yoki kombinatsiyalarni izchil qo‘llang.'),
('P5PRO02-D01','D','used_initial_red_fraction_only','concept','P5-PRO-02','3/8 is not the probability of two red counters; it ignores the two-draw event.','3/8 не является вероятностью двух красных фишек и не описывает оба выбора.','3/8 ikki qizil chip ehtimoli emas; ikki tanlovli hodisani hisobga olmaydi.','Count two-counter outcomes, not single-counter colours.','Считайте исходы для двух фишек, а не долю одного цвета.','Bitta rang ulushini emas, ikki chipli natijalarni sanang.'),
('P5PRO04-D01','B','added_independent_probabilities','concept','P5-PRO-04','For both independent events occurring, probabilities multiply; adding 0.4 and 0.5 corresponds to neither intersection nor a valid union formula here.','Для совместного наступления независимых событий вероятности перемножаются; сумма 0,4 и 0,5 здесь неверна.','Ikkala mustaqil hodisa birga sodir bo‘lsa, ehtimollar ko‘paytiriladi; 0.4+0.5 bu yerda noto‘g‘ri.','Use P(A∩B)=P(A)P(B) when independence is given.','При независимости используйте P(A∩B)=P(A)P(B).','Mustaqillik berilganda P(A∩B)=P(A)P(B) ni ishlating.'),
('P5PRO04-D01','C','averaged_probabilities','method','P5-PRO-04','0.45 is the average of 0.4 and 0.5, but averaging has no role in the multiplication rule.','0,45 — среднее 0,4 и 0,5; усреднение не используется в правиле умножения.','0.45 — 0.4 va 0.5 ning o‘rtachasi; ko‘paytirish qoidasida o‘rtacha olinmaydi.','Write the independence equation before substituting numbers.','Сначала запишите формулу независимости, затем подставьте числа.','Avval mustaqillik formulasini yozing, keyin sonlarni qo‘ying.'),
('P5PRO04-D01','D','halved_product','method','P5-PRO-04','0.10 is half the correct product. 0.4×0.5 equals 0.20.','0,10 — половина правильного произведения. 0,4×0,5=0,20.','0.10 to‘g‘ri ko‘paytmaning yarmi. 0.4×0.5=0.20.','Multiply the decimals directly or use fractions 4/10×5/10.','Перемножьте десятичные дроби напрямую или используйте 4/10×5/10.','O‘nli sonlarni bevosita ko‘paytiring yoki 4/10×5/10 dan foydalaning.')
), meta as (
  select m.id,m.content_key
  from private.exam_prep_question_content_meta m
  join private.exam_prep_content_versions cv on cv.id=m.content_version_id
  where cv.content_version='p5_aw09_12_count_prob_v1' and m.reserve_role='diagnostic'
)
insert into private.exam_prep_diagnostic_rules(
  content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,
  feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status,approved_at
)
select meta.id,'drv1','mcq_option',r.match,r.dcode,r.mtype,r.weak_skill,
       r.fen,r.fru,r.fuz,r.nen,r.nru,r.nuz,'approved',now()
from rules r join meta on meta.content_key=r.ckey
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_aw09_12_count_prob_v1' and component_code='P5' and status='draft'
), defs(task_key,skill,en,ru,uz,rubric,sen,sru,suz) as (values
('P5CNT05-W01','P5-CNT-05','A school club has 10 members. (a) Choose a 4-person committee. (b) Choose a chair and then 3 ordinary committee members from the remaining people. (c) Explain why part (a) uses a combination while part (b) mixes an ordered role with an unordered selection. Calculate both answers.','В школьном клубе 10 участников. (a) Выберите комитет из 4 человек. (b) Выберите председателя, затем 3 обычных членов комитета из оставшихся. (c) Объясните, почему в (a) используется сочетание, а в (b) сочетаются упорядоченная роль и неупорядоченный выбор. Найдите оба ответа.','Maktab klubida 10 a’zo bor. (a) 4 kishilik qo‘mita tanlang. (b) Avval raisni, keyin qolganlardan 3 oddiy a’zoni tanlang. (c) Nima uchun (a) kombinatsiya, (b) esa tartibli rol va tartibsiz tanlovni birlashtirishini tushuntiring. Ikkala javobni hisoblang.','{"max_marks":10,"criteria":[{"id":"part_a_model","marks":2,"rule":"Uses C(10,4) for the unordered committee."},{"id":"part_a_value","marks":2,"rule":"Obtains 210."},{"id":"part_b_model","marks":2,"rule":"Uses 10×C(9,3) or an equivalent correct mixed model."},{"id":"part_b_value","marks":2,"rule":"Obtains 840."},{"id":"reasoning","marks":2,"rule":"Explains why the chair role creates order but the three ordinary members do not."}]}','Ask whether swapping people changes the outcome. The chair is labelled; the three ordinary seats are not.','Проверяйте, меняет ли перестановка людей исход. Роль председателя подписана; три обычных места — нет.','Odamlarni almashtirish natijani o‘zgartiradimi, tekshiring. Rais roli nomlangan, uchta oddiy o‘rin esa yo‘q.'),
('P5PRO02-W01','P5-PRO-02','A class has 7 boys and 5 girls. Four students are chosen at random. (a) Find the probability of choosing exactly 2 girls. (b) Find the probability of choosing at least 1 girl using a complement. (c) Explain why combinations are valid for both numerator and denominator.','В классе 7 мальчиков и 5 девочек. Случайно выбирают 4 учеников. (a) Найдите вероятность выбрать ровно 2 девочек. (b) Найдите вероятность выбрать хотя бы 1 девочку через дополнение. (c) Объясните, почему сочетания подходят и для числителя, и для знаменателя.','Sinfda 7 o‘g‘il va 5 qiz bor. Tasodifiy 4 o‘quvchi tanlanadi. (a) Aynan 2 qiz ehtimolini toping. (b) Complement orqali kamida 1 qiz ehtimolini toping. (c) Nima uchun surat va maxrajda kombinatsiyalar ishlatilishini tushuntiring.','{"max_marks":10,"criteria":[{"id":"exact_model","marks":2,"rule":"Uses C(5,2)C(7,2)/C(12,4)."},{"id":"exact_value","marks":2,"rule":"Obtains 210/495 = 14/33."},{"id":"complement_model","marks":2,"rule":"Uses 1−C(7,4)/C(12,4)."},{"id":"complement_value","marks":2,"rule":"Obtains 1−35/495 = 92/99."},{"id":"reasoning","marks":2,"rule":"Explains that selection order is irrelevant and all 4-person subsets are equally likely."}]}','Keep numerator and denominator in the same unordered sample-space model. For ''at least one'', count the easier complement of no girls.','Используйте одну и ту же неупорядоченную модель в числителе и знаменателе. Для «хотя бы одна» удобнее дополнение «ни одной».','Surat va maxrajda bir xil tartibsiz modelni ishlating. ''Kamida bitta'' uchun ''qiz yo‘q'' complementini hisoblash osonroq.'),
('P5PRO04-W01','P5-PRO-04','Events A and B satisfy P(A)=0.6, P(B)=0.35 and P(A∩B)=0.21. (a) Test whether A and B are independent. (b) Find P(B|A). (c) A third event C is independent of both A and B with P(C)=0.5. Assuming mutual independence of A, B and C, find P(A∩B∩C). Explain each multiplication step.','Для событий A и B: P(A)=0,6, P(B)=0,35 и P(A∩B)=0,21. (a) Проверьте независимость A и B. (b) Найдите P(B|A). (c) Событие C независимо от A и B, P(C)=0,5. При взаимной независимости A, B и C найдите P(A∩B∩C). Объясните каждый шаг умножения.','A va B uchun P(A)=0.6, P(B)=0.35 va P(A∩B)=0.21. (a) A va B mustaqilligini tekshiring. (b) P(B|A) ni toping. (c) C hodisa A va B dan mustaqil, P(C)=0.5. A, B, C o‘zaro mustaqil deb, P(A∩B∩C) ni toping. Har bir ko‘paytirish qadamini tushuntiring.','{"max_marks":10,"criteria":[{"id":"independence","marks":3,"rule":"Checks 0.6×0.35=0.21 and concludes A,B independent."},{"id":"conditional","marks":2,"rule":"Finds P(B|A)=0.21/0.6=0.35."},{"id":"three_way","marks":2,"rule":"Finds 0.6×0.35×0.5=0.105."},{"id":"reasoning","marks":3,"rule":"Distinguishes independence product from conditional multiplication and states the mutual-independence assumption used for three events."}]}','First test independence numerically. Then use the conditional definition. Only multiply all three marginal probabilities after stating the mutual-independence assumption.','Сначала численно проверьте независимость. Затем используйте определение условной вероятности. Все три вероятности перемножайте только после явного условия взаимной независимости.','Avval mustaqillikni son bilan tekshiring. Keyin shartli ehtimol ta’rifini ishlating. Uchta ehtimolni faqat o‘zaro mustaqillik sharti aytilgandan keyin ko‘paytiring.')
)
insert into private.exam_prep_written_tasks(
  content_version_id,task_key,component_code,primary_skill_code,task_version,
  prompt_en,prompt_ru,prompt_uz,rubric_json,self_review_en,self_review_ru,self_review_uz,
  lifecycle_state,copyright_status,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select cv.id,d.task_key,'P5',d.skill,'wtv1',d.en,d.ru,d.uz,d.rubric::jsonb,d.sen,d.sru,d.suz,
       'approved','pass','pass','pass','pass',now()
from defs d cross join cv
on conflict(content_version_id,task_key,task_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions
  where content_version='p5_aw09_12_count_prob_v1' and component_code='P5' and status='draft'
), defs(k,t,en,ru,uz) as (values
('p5_aw09_12_count_prob_diagnostic','diagnostic','P5 AW9-12 counting/probability diagnostic','Диагностика P5 AW9–12: комбинаторика и вероятность','P5 AW9–12 sanash/ehtimollik diagnostikasi'),
('p5_cnt05_learning','learning','Combinations learning','Сочетания: обучение','Kombinatsiyalar: o‘rganish'),
('p5_pro02_learning','learning','Probability by counting learning','Вероятность через подсчёт: обучение','Sanash orqali ehtimollik: o‘rganish'),
('p5_pro04_learning','learning','Multiplication and independence learning','Умножение и независимость: обучение','Ko‘paytirish va mustaqillik: o‘rganish'),
('p5_cnt05_retest','retest','Combinations delayed retest','Отложенный ретест: сочетания','Kechiktirilgan retest: kombinatsiyalar'),
('p5_pro02_retest','retest','Probability by counting delayed retest','Отложенный ретест: вероятность через подсчёт','Kechiktirilgan retest: sanash orqali ehtimollik'),
('p5_pro04_retest','retest','Independence delayed retest','Отложенный ретест: независимость','Kechiktirilgan retest: mustaqillik'),
('p5_aw09_12_count_prob_mixed','mixed','P5 AW9-12 counting/probability mixed transfer','Смешанный перенос P5 AW9–12: комбинаторика/вероятность','P5 AW9–12 sanash/ehtimollik mixed transfer')
)
insert into private.exam_prep_assessments(
  content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz
)
select cv.id,d.k,'av1','P5',d.t,'approved',d.en,d.ru,d.uz
from defs d cross join cv
on conflict(content_version_id,assessment_key,assessment_version) do nothing;

with cv as (
  select id from private.exam_prep_content_versions where content_version='p5_aw09_12_count_prob_v1'
), a as (
  select x.id,x.assessment_key from private.exam_prep_assessments x join cv on cv.id=x.content_version_id
), m as (
  select x.content_key,x.question_id from private.exam_prep_question_content_meta x join cv on cv.id=x.content_version_id
), w as (
  select x.id,x.task_key from private.exam_prep_written_tasks x join cv on cv.id=x.content_version_id
), items(akey,ord,ckey,wkey,skill,role,holdout) as (values
('p5_aw09_12_count_prob_diagnostic',1,'P5CNT05-D01',null,'P5-CNT-05','diagnostic',true),
('p5_aw09_12_count_prob_diagnostic',2,'P5PRO02-D01',null,'P5-PRO-02','diagnostic',true),
('p5_aw09_12_count_prob_diagnostic',3,'P5PRO04-D01',null,'P5-PRO-04','diagnostic',true),
('p5_cnt05_learning',1,'P5CNT05-L01',null,'P5-CNT-05','learning',false),
('p5_cnt05_learning',2,'P5CNT05-L02',null,'P5-CNT-05','learning',false),
('p5_cnt05_learning',3,'P5CNT05-L03',null,'P5-CNT-05','learning',false),
('p5_cnt05_learning',4,null,'P5CNT05-W01','P5-CNT-05','written',false),
('p5_pro02_learning',1,'P5PRO02-L01',null,'P5-PRO-02','learning',false),
('p5_pro02_learning',2,'P5PRO02-L02',null,'P5-PRO-02','learning',false),
('p5_pro02_learning',3,'P5PRO02-L03',null,'P5-PRO-02','learning',false),
('p5_pro02_learning',4,null,'P5PRO02-W01','P5-PRO-02','written',false),
('p5_pro04_learning',1,'P5PRO04-L01',null,'P5-PRO-04','learning',false),
('p5_pro04_learning',2,'P5PRO04-L02',null,'P5-PRO-04','learning',false),
('p5_pro04_learning',3,'P5PRO04-L03',null,'P5-PRO-04','learning',false),
('p5_pro04_learning',4,null,'P5PRO04-W01','P5-PRO-04','written',false),
('p5_cnt05_retest',1,'P5CNT05-R01',null,'P5-CNT-05','retest',true),
('p5_pro02_retest',1,'P5PRO02-R01',null,'P5-PRO-02','retest',true),
('p5_pro04_retest',1,'P5PRO04-R01',null,'P5-PRO-04','retest',true),
('p5_aw09_12_count_prob_mixed',1,'P5CNT05-M01',null,'P5-CNT-05','mixed',true),
('p5_aw09_12_count_prob_mixed',2,'P5PRO02-M01',null,'P5-PRO-02','mixed',true),
('p5_aw09_12_count_prob_mixed',3,'P5PRO04-M01',null,'P5-PRO-04','mixed',true)
)
insert into private.exam_prep_assessment_items(
  assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout
)
select a.id,i.ord,m.question_id,w.id,i.skill,i.role,i.holdout
from items i
join a on a.assessment_key=i.akey
left join m on m.content_key=i.ckey
left join w on w.task_key=i.wkey
on conflict(assessment_id,item_order) do nothing;

do $$
declare v_id bigint; v_skill text; v_bad int;
begin
  select id into v_id from private.exam_prep_content_versions
  where content_version='p5_aw09_12_count_prob_v1' and component_code='P5' and status='draft';
  if v_id is null then raise exception 'P1-02 P5 AW9-12 count/prob: draft content version missing'; end if;
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id)<>21 then
    raise exception 'P1-02 P5 AW9-12 count/prob: expected 21 question objects';
  end if;
  foreach v_skill in array array['P5-CNT-05','P5-PRO-02','P5-PRO-04'] loop
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='diagnostic')<>1 then raise exception 'P5 AW9 count/prob % diagnostic floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='learning')<>3 then raise exception 'P5 AW9 count/prob % learning floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='retest')<>2 then raise exception 'P5 AW9 count/prob % retest floor',v_skill; end if;
    if (select count(*) from private.exam_prep_question_content_meta where content_version_id=v_id and primary_skill_code=v_skill and reserve_role='mixed')<>1 then raise exception 'P5 AW9 count/prob % mixed floor',v_skill; end if;
    if (select count(*) from private.exam_prep_written_tasks where content_version_id=v_id and primary_skill_code=v_skill and lifecycle_state='approved')<>1 then raise exception 'P5 AW9 count/prob % written floor',v_skill; end if;
  end loop;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=v_id and (
    q.subject_id<>5 or q.is_active or q.quality_status is distinct from 'draft'
    or nullif(trim(q.question_text_en),'') is null or nullif(trim(q.question_text_ru),'') is null or nullif(trim(q.question_text_uz),'') is null
    or nullif(trim(q.options_text_en),'') is null or nullif(trim(q.options_text_ru),'') is null or nullif(trim(q.options_text_uz),'') is null
    or jsonb_typeof(q.options_text_en::jsonb)<>'array' or jsonb_array_length(q.options_text_en::jsonb)<>4
    or jsonb_typeof(q.options_text_ru::jsonb)<>'array' or jsonb_array_length(q.options_text_ru::jsonb)<>4
    or jsonb_typeof(q.options_text_uz::jsonb)<>'array' or jsonb_array_length(q.options_text_uz::jsonb)<>4
    or q.correct_answer not in ('A','B','C','D')
    or nullif(trim(q.explanation_en),'') is null or nullif(trim(q.explanation_ru),'') is null or nullif(trim(q.explanation_uz),'') is null
    or md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),coalesce(q.options_text,''),
      coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5
  );
  if v_bad<>0 then raise exception 'P1-02 P5 AW9 count/prob payload/isolation/snapshot failures=%',v_bad; end if;

  select count(*) into v_bad from (
    select m.id
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    left join private.exam_prep_diagnostic_rules r on r.content_meta_id=m.id and r.status='approved' and r.answer_kind='mcq_option'
    where m.content_version_id=v_id and m.reserve_role='diagnostic'
    group by m.id,q.correct_answer
    having count(r.id)<>3 or count(r.id) filter(where r.answer_match=q.correct_answer)<>0
  ) x;
  if v_bad<>0 then raise exception 'P1-02 P5 AW9 count/prob diagnostic-rule failures=%',v_bad; end if;

  if (select count(*) from private.exam_prep_question_content_meta m where m.content_version_id=v_id and m.reserve_role='retest'
      and not exists(select 1 from private.exam_prep_assessment_items i where i.question_id=m.question_id))<>3 then
    raise exception 'P1-02 P5 AW9 count/prob expected 3 isolated R02 holdouts';
  end if;
end $$;

update private.exam_prep_question_content_meta m
set copyright_status='pass',qa_scope_status='pass',qa_math_status='pass',qa_language_status='pass',qa_technical_status='pass',
    diagnostic_rule_status=case when reserve_role='diagnostic' then 'approved' else 'not_applicable' end,
    lifecycle_state='approved',approved_at=now(),updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version='p5_aw09_12_count_prob_v1' and cv.status='draft';

update private.exam_prep_content_versions
set status='approved',approved_at=now()
where content_version='p5_aw09_12_count_prob_v1' and status='draft';

update private.exam_prep_question_content_meta m
set lifecycle_state=case when reserve_role='learning' then 'published' else 'reserve' end,
    exposure_state=case when reserve_role='learning' then 'released' else 'withheld' end,
    published_at=case when reserve_role='learning' then now() else null end,
    updated_at=now()
from private.exam_prep_content_versions cv
where cv.id=m.content_version_id and cv.content_version='p5_aw09_12_count_prob_v1' and cv.status='approved';

update private.exam_prep_written_tasks w
set lifecycle_state='published'
from private.exam_prep_content_versions cv
where cv.id=w.content_version_id and cv.content_version='p5_aw09_12_count_prob_v1' and cv.status='approved' and w.lifecycle_state='approved';

update private.exam_prep_assessments a
set status='published',approved_at=coalesce(a.approved_at,now())
from private.exam_prep_content_versions cv
where cv.id=a.content_version_id and cv.content_version='p5_aw09_12_count_prob_v1' and cv.status='approved' and a.status='approved';

update private.exam_prep_content_versions
set status='published',published_at=now()
where content_version='p5_aw09_12_count_prob_v1' and status='approved';

-- Final acceptance: AW9-12 is now fully governed for both P1 and P5, while live beta remains OFF.
do $$
declare v_program bigint; v_skill text; v_p1_ready int; v_p5_ready int; v_r jsonb; v_cfg private.exam_prep_feature_config%rowtype;
begin
  select id into v_program from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';

  foreach v_skill in array array['P5-CNT-05','P5-PRO-02','P5-PRO-04'] loop
    if not private.exam_prep_skill_content_ready_v1(v_program,'P5',v_skill) then
      raise exception 'P1-02 P5 AW9 count/prob final skill not ready=%',v_skill;
    end if;
  end loop;

  select count(*) into v_p1_ready
  from private.exam_prep_content_runway_release_skills rs
  join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.release_key='aw09_12_core_coverage_ii' and r.component_code='P1' and rs.required_for_release
    and private.exam_prep_skill_content_ready_v1(v_program,'P1',rs.skill_code);
  select count(*) into v_p5_ready
  from private.exam_prep_content_runway_release_skills rs
  join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.release_key='aw09_12_core_coverage_ii' and r.component_code='P5' and rs.required_for_release
    and private.exam_prep_skill_content_ready_v1(v_program,'P5',rs.skill_code);
  if v_p1_ready<>8 or v_p5_ready<>6 then
    raise exception 'P1-02 AW9-12 final readiness expected P1=8 P5=6, got P1=% P5=%',v_p1_ready,v_p5_ready;
  end if;

  v_r:=public.get_exam_prep_content_runway_v1(9::smallint);
  if coalesce((v_r->>'hard_floor_green')::boolean,false) is distinct from true
     or coalesce((v_r->>'target_4w_green')::boolean,false) is distinct from true then
    raise exception 'P1-02 AW9-12 final runway unexpected=%',v_r::text;
  end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1;
  if v_cfg.rollout_state<>'off' or v_cfg.core_enabled or v_cfg.ai_enabled or v_cfg.mentor_enabled or not v_cfg.kill_switch then
    raise exception 'P1-02 P5 AW9 count/prob feature escaped fail-closed';
  end if;
  if exists(select 1 from private.exam_prep_feature_entitlements where entitlement_status='active') then
    raise exception 'P1-02 P5 AW9 count/prob active entitlement residue';
  end if;
  if exists(select 1 from public.questions where book_ref like 'ExamPrep:P5:p5_aw09_12_count_prob_v1:%' and is_active) then
    raise exception 'P1-02 P5 AW9 count/prob legacy question activation detected';
  end if;
end $$;

commit;
