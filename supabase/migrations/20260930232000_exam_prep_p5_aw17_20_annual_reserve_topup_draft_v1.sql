-- AW17-20 P5 annual-reserve top-up draft v1.
-- DRAFT ONLY: no learner-visible content and no existing evidence mutation.
-- Exact delta per skill: +2 diagnostics, +2 delayed retests, +1 mixed/transfer.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw17_20_annual_reserve_p5_draft canonical program missing'; end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4820 and content_version<>'p5_aw17_20_annual_reserve_topup_draft_v1')
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59453 and 59477 and content_version_id<>4820)
  then raise exception 'aw17_20_annual_reserve_p5_draft reserved id collision'; end if;

  if (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P5-BIN-02','P5-BIN-03','P5-GEO-02','P5-GEO-03','P5-NOR-01')
        and m.reserve_role='diagnostic')<>5
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P5-BIN-02','P5-BIN-03','P5-GEO-02','P5-GEO-03','P5-NOR-01')
        and m.reserve_role='retest')<>10
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P5-BIN-02','P5-BIN-03','P5-GEO-02','P5-GEO-03','P5-NOR-01')
        and m.reserve_role in ('learning','mixed'))<>35
  then raise exception 'aw17_20_annual_reserve_p5_draft baseline depth changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4820,pv.id,'p5_aw17_20_annual_reserve_topup_draft_v1','P5',
 'P5 AW17-20 annual reserve top-up draft v1','draft',
 'Original iClub-authored annual reserve expansion. Official Cambridge 9709 scope controls the learning objectives; Complete Probability & Statistics 1 is mapping/explanation support only. No protected Cambridge/coursebook question, solution, mark-scheme wording or diagram is copied. Independent academic, trilingual, technical, originality and reserve-isolation QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,reserve_role,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P5BIN02-D02','P5-BIN-02','diagnostic','medium','mcq','If X~B(8,0.25), find P(X=0) to 4 decimal places.','["0.1001","0.2500","0.8999","0.7500"]','A','P(X=0)=(0.75)^8=0.100112915..., so to 4 decimal places the probability is 0.1001.','Если X~B(8,0,25), найдите P(X=0) с точностью до 4 знаков после запятой.','["0,1001","0,2500","0,8999","0,7500"]','P(X=0)=(0,75)^8=0,100112915..., поэтому с точностью до 4 знаков вероятность равна 0,1001.','Agar X~B(8,0.25) bo‘lsa, P(X=0) ni 4 ta o‘nli xonagacha toping.','["0.1001","0.2500","0.8999","0.7500"]','P(X=0)=(0.75)^8=0.100112915..., demak 4 ta o‘nli xonagacha ehtimol 0.1001.',65),
('P5BIN02-D03','P5-BIN-02','diagnostic','medium','mcq','If X~B(6,0.4), find P(X=2) to 4 decimal places.','["0.1866","0.3119","0.3110","0.4000"]','C','P(X=2)=6C2(0.4)^2(0.6)^4=15(0.16)(0.1296)=0.31104, so 0.3110 to 4 decimal places.','Если X~B(6,0,4), найдите P(X=2) с точностью до 4 знаков после запятой.','["0,1866","0,3119","0,3110","0,4000"]','P(X=2)=6C2(0,4)^2(0,6)^4=15(0,16)(0,1296)=0,31104, то есть 0,3110 с точностью до 4 знаков.','Agar X~B(6,0.4) bo‘lsa, P(X=2) ni 4 ta o‘nli xonagacha toping.','["0.1866","0.3119","0.3110","0.4000"]','P(X=2)=6C2(0.4)^2(0.6)^4=15(0.16)(0.1296)=0.31104, ya’ni 4 ta o‘nli xonagacha 0.3110.',70),
('P5BIN02-R03','P5-BIN-02','retest','medium','input','If X~B(4,0.5), enter P(X≥3) as an exact fraction.','[]','5/16','P(X≥3)=P(X=3)+P(X=4)=[4C3+4C4]/16=(4+1)/16=5/16.','Если X~B(4,0,5), введите P(X≥3) в виде точной дроби.','[]','P(X≥3)=P(X=3)+P(X=4)=[4C3+4C4]/16=(4+1)/16=5/16.','Agar X~B(4,0.5) bo‘lsa, P(X≥3) ni aniq kasr ko‘rinishida kiriting.','[]','P(X≥3)=P(X=3)+P(X=4)=[4C3+4C4]/16=(4+1)/16=5/16.',70),
('P5BIN02-R04','P5-BIN-02','retest','hard','mcq','If X~B(10,0.2), find P(X≤1) to 4 decimal places.','["0.6242","0.3758","0.2684","0.1074"]','B','P(X≤1)=0.8^10+10(0.2)(0.8)^9=0.3758096384, so 0.3758.','Если X~B(10,0,2), найдите P(X≤1) с точностью до 4 знаков после запятой.','["0,6242","0,3758","0,2684","0,1074"]','P(X≤1)=0,8^10+10(0,2)(0,8)^9=0,3758096384, поэтому 0,3758.','Agar X~B(10,0.2) bo‘lsa, P(X≤1) ni 4 ta o‘nli xonagacha toping.','["0.6242","0.3758","0.2684","0.1074"]','P(X≤1)=0.8^10+10(0.2)(0.8)^9=0.3758096384, demak 0.3758.',80),
('P5BIN02-M02','P5-BIN-02','mixed','hard','input','Twelve independent calls each have probability 0.1 of being unsuccessful. Enter the probability that at least one call is unsuccessful, to 4 decimal places.','[]','0.7176','P(at least one)=1−P(none)=1−0.9^12=0.7175704635..., so 0.7176.','Двенадцать независимых звонков имеют вероятность 0,1 оказаться неуспешными каждый. Введите вероятность того, что хотя бы один звонок окажется неуспешным, с точностью до 4 знаков.','[]','P(хотя бы один)=1−P(ни одного)=1−0,9^12=0,7175704635..., поэтому 0,7176.','12 ta mustaqil qo‘ng‘iroqning har biri 0.1 ehtimol bilan muvaffaqiyatsiz bo‘ladi. Kamida bittasi muvaffaqiyatsiz bo‘lish ehtimolini 4 ta o‘nli xonagacha kiriting.','[]','P(kamida bittasi)=1−P(hech biri)=1−0.9^12=0.7175704635..., demak 0.7176.',85),
('P5BIN03-D02','P5-BIN-03','diagnostic','hard','mcq','A binomial random variable has mean 12 and variance 9.6. Find n.','["50","60","48","75"]','B','Var(X)/E(X)=1−p=9.6/12=0.8, so p=0.2. Since np=12, n=12/0.2=60.','Биномиальная случайная величина имеет математическое ожидание 12 и дисперсию 9,6. Найдите n.','["50","60","48","75"]','Var(X)/E(X)=1−p=9,6/12=0,8, поэтому p=0,2. Так как np=12, n=12/0,2=60.','Binomial tasodifiy kattalikning kutiladigan qiymati 12 va dispersiyasi 9.6. n ni toping.','["50","60","48","75"]','Var(X)/E(X)=1−p=9.6/12=0.8, demak p=0.2. np=12 bo‘lgani uchun n=12/0.2=60.',75),
('P5BIN03-D03','P5-BIN-03','diagnostic','medium','mcq','If X~B(80,0.15), find Var(X).','["12","9.6","68","10.2"]','D','Var(X)=np(1−p)=80(0.15)(0.85)=10.2.','Если X~B(80,0,15), найдите Var(X).','["12","9,6","68","10,2"]','Var(X)=np(1−p)=80(0,15)(0,85)=10,2.','Agar X~B(80,0.15) bo‘lsa, Var(X) ni toping.','["12","9.6","68","10.2"]','Var(X)=np(1−p)=80(0.15)(0.85)=10.2.',60),
('P5BIN03-R03','P5-BIN-03','retest','medium','input','If X~B(70,p) and E(X)=21, enter p.','[]','0.3','E(X)=np, so 70p=21 and p=0.3.','Если X~B(70,p) и E(X)=21, введите p.','[]','E(X)=np, поэтому 70p=21 и p=0,3.','Agar X~B(70,p) va E(X)=21 bo‘lsa, p ni kiriting.','[]','E(X)=np, demak 70p=21 va p=0.3.',55),
('P5BIN03-R04','P5-BIN-03','retest','hard','mcq','A binomial random variable has mean 8 and variance 6. Find n.','["24","30","32","40"]','C','1−p=6/8=0.75, so p=0.25. Then np=8 gives n=8/0.25=32.','Биномиальная случайная величина имеет математическое ожидание 8 и дисперсию 6. Найдите n.','["24","30","32","40"]','1−p=6/8=0,75, поэтому p=0,25. Затем np=8 даёт n=8/0,25=32.','Binomial tasodifiy kattalikning kutiladigan qiymati 8 va dispersiyasi 6. n ni toping.','["24","30","32","40"]','1−p=6/8=0.75, demak p=0.25. So‘ng np=8 dan n=8/0.25=32.',75),
('P5BIN03-M02','P5-BIN-03','mixed','hard','input','For X~B(n,0.25), Var(X)=4.5. Enter E(X).','[]','6','Var(X)=np(0.75)=4.5, so np=6. Therefore E(X)=np=6.','Для X~B(n,0,25) имеем Var(X)=4,5. Введите E(X).','[]','Var(X)=np(0,75)=4,5, поэтому np=6. Следовательно, E(X)=np=6.','X~B(n,0.25) uchun Var(X)=4.5. E(X) ni kiriting.','[]','Var(X)=np(0.75)=4.5, demak np=6. Shuning uchun E(X)=np=6.',70),
('P5GEO02-D02','P5-GEO-02','diagnostic','medium','mcq','For geometric X with success probability p=0.2, find P(X=3).','["0.128","0.160","0.512","0.800"]','A','P(X=3)=(0.8)^2(0.2)=0.128.','Для геометрической X с вероятностью успеха p=0,2 найдите P(X=3).','["0,128","0,160","0,512","0,800"]','P(X=3)=(0,8)^2(0,2)=0,128.','p=0.2 muvaffaqiyat ehtimolli geometrik X uchun P(X=3) ni toping.','["0.128","0.160","0.512","0.800"]','P(X=3)=(0.8)^2(0.2)=0.128.',60),
('P5GEO02-D03','P5-GEO-02','diagnostic','medium','mcq','For geometric X with p=0.3, find P(X>4) to 4 decimal places.','["0.1681","0.2401","0.7599","0.1029"]','B','X>4 means four failures before any success, so P(X>4)=(0.7)^4=0.2401.','Для геометрической X с p=0,3 найдите P(X>4) с точностью до 4 знаков после запятой.','["0,1681","0,2401","0,7599","0,1029"]','X>4 означает четыре неудачи до первого успеха, поэтому P(X>4)=(0,7)^4=0,2401.','p=0.3 bo‘lgan geometrik X uchun P(X>4) ni 4 ta o‘nli xonagacha toping.','["0.1681","0.2401","0.7599","0.1029"]','X>4 birinchi muvaffaqiyatgacha to‘rtta muvaffaqiyatsizlikni anglatadi, demak P(X>4)=(0.7)^4=0.2401.',65),
('P5GEO02-R03','P5-GEO-02','retest','medium','input','For geometric X with p=0.5, enter P(X≤3) as an exact fraction.','[]','7/8','P(X≤3)=1−P(X>3)=1−(0.5)^3=1−1/8=7/8.','Для геометрической X с p=0,5 введите P(X≤3) в виде точной дроби.','[]','P(X≤3)=1−P(X>3)=1−(0,5)^3=1−1/8=7/8.','p=0.5 bo‘lgan geometrik X uchun P(X≤3) ni aniq kasr ko‘rinishida kiriting.','[]','P(X≤3)=1−P(X>3)=1−(0.5)^3=1−1/8=7/8.',60),
('P5GEO02-R04','P5-GEO-02','retest','hard','mcq','For geometric X with p=1/4, find P(2≤X≤3).','["9/64","15/64","21/64","27/64"]','C','P(2≤X≤3)=P(X=2)+P(X=3)=(3/4)(1/4)+(3/4)^2(1/4)=3/16+9/64=21/64.','Для геометрической X с p=1/4 найдите P(2≤X≤3).','["9/64","15/64","21/64","27/64"]','P(2≤X≤3)=P(X=2)+P(X=3)=(3/4)(1/4)+(3/4)^2(1/4)=3/16+9/64=21/64.','p=1/4 bo‘lgan geometrik X uchun P(2≤X≤3) ni toping.','["9/64","15/64","21/64","27/64"]','P(2≤X≤3)=P(X=2)+P(X=3)=(3/4)(1/4)+(3/4)^2(1/4)=3/16+9/64=21/64.',70),
('P5GEO02-M02','P5-GEO-02','mixed','hard','input','For geometric X with p=0.4, given that X>1, enter P(X>2 | X>1).','[]','0.6','Given X>1, the first trial failed. For X>2 the second trial must also fail. Independence gives probability 1−p=0.6.','Для геометрической X с p=0,4 известно, что X>1. Введите P(X>2 | X>1).','[]','При условии X>1 первое испытание было неудачным. Для X>2 второе испытание также должно быть неудачным. По независимости вероятность равна 1−p=0,6.','p=0.4 bo‘lgan geometrik X uchun X>1 ma’lum. P(X>2 | X>1) ni kiriting.','[]','X>1 sharti birinchi sinov muvaffaqiyatsiz bo‘lganini bildiradi. X>2 uchun ikkinchi sinov ham muvaffaqiyatsiz bo‘lishi kerak. Mustaqillikdan ehtimol 1−p=0.6.',75),
('P5GEO03-D02','P5-GEO-03','diagnostic','medium','mcq','A geometric random variable has expected trial number 5. Find p.','["0.5","0.25","0.2","0.05"]','C','E(X)=1/p, so p=1/5=0.2.','Геометрическая случайная величина имеет ожидаемый номер испытания 5. Найдите p.','["0,5","0,25","0,2","0,05"]','E(X)=1/p, поэтому p=1/5=0,2.','Geometrik tasodifiy kattalikning kutiladigan sinov raqami 5. p ni toping.','["0.5","0.25","0.2","0.05"]','E(X)=1/p, demak p=1/5=0.2.',55),
('P5GEO03-D03','P5-GEO-03','diagnostic','medium','mcq','For geometric X with p=0.125, find E(X).','["0.125","4","6","8"]','D','E(X)=1/p=1/0.125=8.','Для геометрической X с p=0,125 найдите E(X).','["0,125","4","6","8"]','E(X)=1/p=1/0,125=8.','p=0.125 bo‘lgan geometrik X uchun E(X) ni toping.','["0.125","4","6","8"]','E(X)=1/p=1/0.125=8.',55),
('P5GEO03-R03','P5-GEO-03','retest','medium','input','A geometric random variable has E(X)=4. Enter p.','[]','0.25','Since E(X)=1/p, p=1/4=0.25.','Геометрическая случайная величина имеет E(X)=4. Введите p.','[]','Так как E(X)=1/p, p=1/4=0,25.','Geometrik tasodifiy kattalik uchun E(X)=4. p ni kiriting.','[]','E(X)=1/p bo‘lgani uchun p=1/4=0.25.',50),
('P5GEO03-R04','P5-GEO-03','retest','medium','mcq','Independent trials have success probability 0.2 and each trial takes 2 minutes. What is the expected time to and including the first success?','["10 minutes","5 minutes","8 minutes","12 minutes"]','A','E(X)=1/0.2=5 trials. At 2 minutes per trial, the expected time is 10 minutes.','Независимые испытания имеют вероятность успеха 0,2, каждое испытание занимает 2 минуты. Каково ожидаемое время до первого успеха включительно?','["10 минут","5 минут","8 минут","12 минут"]','E(X)=1/0,2=5 испытаний. При 2 минутах на испытание ожидаемое время равно 10 минут.','Mustaqil sinovlarda muvaffaqiyat ehtimoli 0.2 va har bir sinov 2 daqiqa davom etadi. Birinchi muvaffaqiyatgacha, muvaffaqiyatli sinovni ham hisobga olgan holda, kutiladigan vaqt qancha?','["10 daqiqa","5 daqiqa","8 daqiqa","12 daqiqa"]','E(X)=1/0.2=5 ta sinov. Har bir sinov 2 daqiqa bo‘lsa, kutiladigan vaqt 10 daqiqa.',60),
('P5GEO03-M02','P5-GEO-03','mixed','hard','input','Independent trials continue until the first success. Each trial takes 3 minutes and the expected total time is 15 minutes. Enter the success probability p.','[]','0.2','The expected number of trials is 15/3=5. For a geometric variable E(X)=1/p, so p=1/5=0.2.','Независимые испытания продолжаются до первого успеха. Каждое испытание занимает 3 минуты, а ожидаемое общее время равно 15 минут. Введите вероятность успеха p.','[]','Ожидаемое число испытаний равно 15/3=5. Для геометрической величины E(X)=1/p, поэтому p=1/5=0,2.','Mustaqil sinovlar birinchi muvaffaqiyatgacha davom etadi. Har bir sinov 3 daqiqa, kutiladigan umumiy vaqt 15 daqiqa. Muvaffaqiyat ehtimoli p ni kiriting.','[]','Kutiladigan sinovlar soni 15/3=5. Geometrik kattalik uchun E(X)=1/p, demak p=1/5=0.2.',65),
('P5NOR01-D02','P5-NOR-01','diagnostic','medium','mcq','If X~N(60,9), what is the standard deviation of X?','["3","9","51","69"]','A','In N(μ,σ²), the second parameter is the variance. Thus σ=√9=3.','Если X~N(60,9), каково стандартное отклонение X?','["3","9","51","69"]','В N(μ,σ²) второй параметр — дисперсия. Поэтому σ=√9=3.','Agar X~N(60,9) bo‘lsa, X ning standart og‘ishi qancha?','["3","9","51","69"]','N(μ,σ²) da ikkinchi parametr dispersiya. Demak σ=√9=3.',50),
('P5NOR01-D03','P5-NOR-01','diagnostic','medium','mcq','Four data sets are being assigned probability models. Which variable should not be assigned a normal model?','["Measurement error around zero from a calibrated instrument","Number of attempts until the first success","Fill mass from a stable machine","Adult height in a large homogeneous group"]','B','The number of attempts until the first success is discrete waiting-time data and is naturally geometric, not normal.','Для четырёх наборов данных выбирают вероятностные модели. Какой величине не следует назначать нормальную модель?','["Ошибка измерения около нуля у откалиброванного прибора","Число попыток до первого успеха","Масса наполнения стабильной машины","Рост взрослых в большой однородной группе"]','Число попыток до первого успеха — дискретная величина времени ожидания и естественно описывается геометрическим, а не нормальным распределением.','To‘rtta ma’lumot to‘plamiga ehtimollik modellari tanlanmoqda. Qaysi o‘zgaruvchiga normal modelni qo‘llamaslik kerak?','["Kalibrlangan asbobning nol atrofidagi o‘lchash xatosi","Birinchi muvaffaqiyatgacha urinishlar soni","Barqaror mashinadagi to‘ldirish massasi","Katta bir xil guruhdagi kattalar bo‘yi"]','Birinchi muvaffaqiyatgacha urinishlar soni diskret kutish vaqti bo‘lib, tabiiy ravishda geometrik, normal emas.',60),
('P5NOR01-R03','P5-NOR-01','retest','medium','input','If X~N(250,36), enter the value one standard deviation above the mean.','[]','256','The mean is 250 and the standard deviation is √36=6. One standard deviation above the mean is 250+6=256.','Если X~N(250,36), введите значение на одно стандартное отклонение выше среднего.','[]','Среднее равно 250, стандартное отклонение √36=6. На одно стандартное отклонение выше среднего: 250+6=256.','Agar X~N(250,36) bo‘lsa, o‘rtachadan bitta standart og‘ish yuqoridagi qiymatni kiriting.','[]','O‘rtacha 250, standart og‘ish √36=6. O‘rtachadan bitta standart og‘ish yuqoridagi qiymat 250+6=256.',55),
('P5NOR01-R04','P5-NOR-01','retest','medium','mcq','A normal model has mean 40 and standard deviation 5. Which pair is one standard deviation below and above the mean?','["30 and 50","40 and 45","35 and 45","35 and 50"]','C','The one-standard-deviation points are μ−σ=40−5=35 and μ+σ=40+5=45.','Нормальная модель имеет среднее 40 и стандартное отклонение 5. Какая пара находится на одно стандартное отклонение ниже и выше среднего?','["30 и 50","40 и 45","35 и 45","35 и 50"]','Точки на одно стандартное отклонение: μ−σ=40−5=35 и μ+σ=40+5=45.','Normal modelning o‘rtachasi 40 va standart og‘ishi 5. Qaysi juftlik o‘rtachadan bitta standart og‘ish past va yuqori?','["30 va 50","40 va 45","35 va 45","35 va 50"]','Bitta standart og‘ishdagi nuqtalar μ−σ=40−5=35 va μ+σ=40+5=45.',55),
('P5NOR01-M02','P5-NOR-01','mixed','hard','input','If Y~N(100,225), enter the value one standard deviation below the mean.','[]','85','The standard deviation is √225=15, so one standard deviation below the mean is 100−15=85.','Если Y~N(100,225), введите значение на одно стандартное отклонение ниже среднего.','[]','Стандартное отклонение равно √225=15, поэтому на одно стандартное отклонение ниже среднего: 100−15=85.','Agar Y~N(100,225) bo‘lsa, o‘rtachadan bitta standart og‘ish pastdagi qiymatni kiriting.','[]','Standart og‘ish √225=15, demak o‘rtachadan bitta standart og‘ish pastdagi qiymat 100−15=85.',55)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,
 case when s.skill_code like 'P5-BIN-%' then 'P5 Binomial'
      when s.skill_code like 'P5-GEO-%' then 'P5 Geometric'
      else 'P5 Normal' end,
 s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P5:p5_aw17_20_annual_reserve_topup_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(
 select 1 from public.questions q
 where q.book_ref='ExamPrep:P5:p5_aw17_20_annual_reserve_topup_draft_v1:'||s.content_key
);

with src(content_key,skill_code,meta_id,official_ref,book_ref) as (values
('P5BIN02-D02','P5-BIN-02',59453,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN02-D03','P5-BIN-02',59454,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN02-R03','P5-BIN-02',59455,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN02-R04','P5-BIN-02',59456,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN02-M02','P5-BIN-02',59457,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN03-D02','P5-BIN-03',59458,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN03-D03','P5-BIN-03',59459,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN03-R03','P5-BIN-03',59460,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN03-R04','P5-BIN-03',59461,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5BIN03-M02','P5-BIN-03',59462,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch7 The binomial distribution pp.115-131 (mapping only)'),
('P5GEO02-D02','P5-GEO-02',59463,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO02-D03','P5-GEO-02',59464,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO02-R03','P5-GEO-02',59465,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO02-R04','P5-GEO-02',59466,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO02-M02','P5-GEO-02',59467,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO03-D02','P5-GEO-03',59468,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO03-D03','P5-GEO-03',59469,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO03-R03','P5-GEO-03',59470,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO03-R04','P5-GEO-03',59471,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5GEO03-M02','P5-GEO-03',59472,'Cambridge 9709 2026-2027 v4; P5 5.4 Discrete random variables','Complete Probability & Statistics 1, Ch8 The geometric distribution pp.133-145 (mapping only)'),
('P5NOR01-D02','P5-NOR-01',59473,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1, Ch9 The normal distribution pp.147-171 (mapping only)'),
('P5NOR01-D03','P5-NOR-01',59474,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1, Ch9 The normal distribution pp.147-171 (mapping only)'),
('P5NOR01-R03','P5-NOR-01',59475,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1, Ch9 The normal distribution pp.147-171 (mapping only)'),
('P5NOR01-R04','P5-NOR-01',59476,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1, Ch9 The normal distribution pp.147-171 (mapping only)'),
('P5NOR01-M02','P5-NOR-01',59477,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1, Ch9 The normal distribution pp.147-171 (mapping only)')
)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,4820,s.content_key,q.id,s.skill_code,'{}'::text[],
 case when s.content_key like '%-D%' then 'diagnostic'
      when s.content_key like '%-R%' then 'retest'
      else 'mixed' end,
 'withheld','draft',
 'Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'AW17-20 annual reserve authored from canonical skill intent with independent values and contexts; withheld reserve only.',
 s.official_ref,s.book_ref,
 'pending','pending','pending','pending','pending',
 case when s.content_key like '%-D%' then 'pending' else 'not_applicable' end,
 md5(concat_ws(chr(31),
   q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),
   coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
   coalesce(q.image_url,''),coalesce(q.is_active::text,''),coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),
   coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
   coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),
   coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')
 ))
from src s
join public.questions q
  on q.book_ref='ExamPrep:P5:p5_aw17_20_annual_reserve_topup_draft_v1:'||s.content_key
on conflict(id) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int;
begin
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=4820 and lifecycle_state='draft' and exposure_state='withheld')<>25
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4820 and reserve_role='diagnostic')<>10
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4820 and reserve_role='retest')<>10
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4820 and reserve_role='mixed')<>5
  then raise exception 'aw17_20_annual_reserve_p5_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4820 and (
    q.is_active or q.quality_status<>'draft'
    or m.copyright_status<>'pending' or m.qa_scope_status<>'pending' or m.qa_math_status<>'pending'
    or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
    or nullif(btrim(q.question_text_en),'') is null or nullif(btrim(q.question_text_ru),'') is null or nullif(btrim(q.question_text_uz),'') is null
    or nullif(btrim(q.explanation_en),'') is null or nullif(btrim(q.explanation_ru),'') is null or nullif(btrim(q.explanation_uz),'') is null
    or (m.reserve_role='diagnostic' and (q.qtype<>'mcq' or m.diagnostic_rule_status<>'pending'))
    or (m.reserve_role<>'diagnostic' and m.diagnostic_rule_status<>'not_applicable')
    or (q.qtype='mcq' and (
      q.correct_answer not in ('A','B','C','D')
      or jsonb_array_length(q.options_text_en::jsonb)<>4
      or jsonb_array_length(q.options_text_ru::jsonb)<>4
      or jsonb_array_length(q.options_text_uz::jsonb)<>4
      or (select count(distinct v) from jsonb_array_elements_text(q.options_text_en::jsonb) z(v))<>4
    ))
    or (q.qtype='input' and (
      nullif(btrim(q.correct_answer),'') is null
      or q.options_text_en::jsonb<>'[]'::jsonb
      or q.options_text_ru::jsonb<>'[]'::jsonb
      or q.options_text_uz::jsonb<>'[]'::jsonb
    ))
  );
  if v_bad<>0 then raise exception 'aw17_20_annual_reserve_p5_draft payload/QA rows=%',v_bad; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D')
  into v_a,v_b,v_c,v_d
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4820 and m.reserve_role='diagnostic';
  if (v_a,v_b,v_c,v_d)<>(3,3,2,2) then
    raise exception 'aw17_20_annual_reserve_p5_draft diagnostic answer balance A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4820
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4820
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw17_20_annual_reserve_p5_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4820)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4820)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4820)
  then raise exception 'aw17_20_annual_reserve_p5_draft unexpected history'; end if;
end
$postcheck$;

commit;
