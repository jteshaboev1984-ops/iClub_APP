-- AW21-24 P5 annual-reserve top-up draft v1.
-- DRAFT ONLY: no learner-visible content and no existing evidence mutation.
-- Exact delta per skill: +2 diagnostics, +2 delayed retests, +1 mixed/transfer.
-- Correct-option positions are balanced and explicitly reject cyclic sequential patterns.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
 if not exists(select 1 from private.exam_prep_program_versions where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
 then raise exception 'aw21_24_annual_reserve_p5_draft canonical program missing'; end if;
 if exists(select 1 from private.exam_prep_content_versions where id=4824 and content_version<>'p5_aw21_24_annual_reserve_topup_draft_v1')
    or exists(select 1 from private.exam_prep_question_content_meta where id between 59582 and 59621 and content_version_id<>4824)
 then raise exception 'aw21_24_annual_reserve_p5_draft reserved id collision'; end if;
 if (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
     where cv.status='published' and m.lifecycle_state in ('published','reserve')
       and m.primary_skill_code=any(array['P5-DAT-08','P5-DAT-09','P5-DAT-10','P5-NOR-02','P5-NOR-03','P5-NOR-04','P5-NOR-05','P5-NOR-06'])
       and m.reserve_role='diagnostic')<>8
    or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
     where cv.status='published' and m.lifecycle_state in ('published','reserve')
       and m.primary_skill_code=any(array['P5-DAT-08','P5-DAT-09','P5-DAT-10','P5-NOR-02','P5-NOR-03','P5-NOR-04','P5-NOR-05','P5-NOR-06'])
       and m.reserve_role='retest')<>16
    or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
     where cv.status='published' and m.lifecycle_state in ('published','reserve')
       and m.primary_skill_code=any(array['P5-DAT-08','P5-DAT-09','P5-DAT-10','P5-NOR-02','P5-NOR-03','P5-NOR-04','P5-NOR-05','P5-NOR-06'])
       and m.reserve_role='mixed')<>8
 then raise exception 'aw21_24_annual_reserve_p5_draft baseline reserve depth changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level)
overriding system value
select 4824,pv.id,'p5_aw21_24_annual_reserve_topup_draft_v1','P5','P5 AW21-24 annual reserve top-up draft v1','draft',
 'Original iClub-authored annual reserve expansion. Official Cambridge 9709 scope controls learning objectives; Complete Probability & Statistics 1 is mapping/explanation support only. No protected Cambridge/coursebook question, solution, mark-scheme wording or diagram is copied. Independent academic, trilingual, technical, originality and reserve-isolation QA is required before publication.',3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,reserve_role,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P5DAT08-D02','P5-DAT-08','diagnostic','medium','mcq','Dataset A has median 40 and IQR 8. Dataset B has median 44 and IQR 5. Which comparison is supported?','["A has a higher typical value and less spread","B has a lower median but greater spread","B has a higher typical value and less spread in the middle 50%","The two datasets have the same location and spread"]','C','B has the larger median (44>40) and the smaller IQR (5<8).','У набора A медиана 40 и IQR 8. У набора B медиана 44 и IQR 5. Какое сравнение подтверждается?','["У A выше типичное значение и меньше разброс","У B ниже медиана, но больше разброс","У B выше типичное значение и меньше разброс средних 50%","У наборов одинаковые положение и разброс"]','У B медиана выше (44>40), а IQR меньше (5<8).','A to‘plam medianasi 40 va IQR 8. B to‘plam medianasi 44 va IQR 5. Qaysi taqqoslash asosli?','["A ning odatiy qiymati yuqoriroq va tarqalishi kichikroq","B medianasi pastroq, ammo tarqalishi kattaroq","B ning odatiy qiymati yuqoriroq va o‘rta 50% tarqalishi kichikroq","Ikki to‘plamning markazi va tarqalishi bir xil"]','B medianasi kattaroq (44>40), IQR esa kichikroq (5<8).',55),
('P5DAT08-D03','P5-DAT-08','diagnostic','medium','mcq','Dataset A has median 62 and range 30. Dataset B has median 58 and range 18. Which statement is correct?','["B has the higher median and smaller range","A has the higher median, while B has the smaller range","A has both the higher median and smaller range","The ranges are equal"]','B','62>58, so A has the higher median. Since 18<30, B has the smaller range.','У набора A медиана 62 и размах 30. У набора B медиана 58 и размах 18. Какое утверждение верно?','["У B выше медиана и меньше размах","У A выше медиана, а у B меньше размах","У A и медиана выше, и размах меньше","Размахи равны"]','62>58, поэтому у A выше медиана. Так как 18<30, у B меньше размах.','A to‘plam medianasi 62 va diapazoni 30. B to‘plam medianasi 58 va diapazoni 18. Qaysi fikr to‘g‘ri?','["B medianasi yuqoriroq va diapazoni kichikroq","A medianasi yuqoriroq, B diapazoni esa kichikroq","A medianasi ham yuqoriroq, diapazoni ham kichikroq","Diapazonlar teng"]','62>58, demak A medianasi yuqoriroq. 18<30 bo‘lgani uchun B diapazoni kichikroq.',55),
('P5DAT08-R03','P5-DAT-08','retest','medium','input','Dataset A has range 27 and Dataset B has range 19. Enter how much larger A''s range is.','[]','8','27−19=8.','У набора A размах 27, у набора B размах 19. Введите, на сколько размах A больше.','[]','27−19=8.','A to‘plam diapazoni 27, B to‘plamniki 19. A diapazoni qanchaga katta ekanini kiriting.','[]','27−19=8.',35),
('P5DAT08-R04','P5-DAT-08','retest','medium','mcq','Two datasets have the same median. Dataset X has IQR 9 and Dataset Y has IQR 15. Which conclusion is justified?','["Y has the higher median","Y is more consistent","X is more consistent in its middle 50%","X and Y have equal spread"]','C','A smaller IQR means the middle 50% is less spread out. Since 9<15, X is more consistent.','У двух наборов одинаковая медиана. У X IQR 9, у Y IQR 15. Какой вывод обоснован?','["У Y выше медиана","Y более стабилен","X более стабилен в средних 50%","У X и Y одинаковый разброс"]','Меньший IQR означает меньший разброс средних 50%. Так как 9<15, X более стабилен.','Ikki to‘plam medianasi bir xil. X da IQR 9, Y da IQR 15. Qaysi xulosa asosli?','["Y medianasi yuqoriroq","Y barqarorroq","X o‘rta 50% da barqarorroq","X va Y tarqalishi teng"]','Kichik IQR o‘rta 50% kamroq tarqalganini bildiradi. 9<15, shuning uchun X barqarorroq.',50),
('P5DAT08-M02','P5-DAT-08','mixed','hard','input','Two samples have medians 72 and 68. Enter the absolute difference between their medians.','[]','4','|72−68|=4.','У двух выборок медианы 72 и 68. Введите абсолютную разность медиан.','[]','|72−68|=4.','Ikki tanlanma medianalari 72 va 68. Medianalar orasidagi mutlaq farqni kiriting.','[]','|72−68|=4.',35),
('P5DAT09-D02','P5-DAT-09','diagnostic','medium','mcq','For 5 observations, Σx=35 and Σx²=285. Find the variance using Σx²/n−x̄².','["7","8","14","57"]','B','The mean is 35/5=7. Variance=285/5−7²=57−49=8.','Для 5 наблюдений Σx=35 и Σx²=285. Найдите дисперсию по формуле Σx²/n−x̄².','["7","8","14","57"]','Среднее 35/5=7. Дисперсия=285/5−7²=57−49=8.','5 ta kuzatuv uchun Σx=35 va Σx²=285. Σx²/n−x̄² formulasi bilan dispersiyani toping.','["7","8","14","57"]','O‘rtacha 35/5=7. Dispersiya=285/5−7²=57−49=8.',60),
('P5DAT09-D03','P5-DAT-09','diagnostic','medium','mcq','The values are 3, 5, 7, 9, 11. What is their mean?','["5","6","8","7"]','D','The total is 35 and there are 5 values, so the mean is 35/5=7.','Значения: 3, 5, 7, 9, 11. Чему равно среднее?','["5","6","8","7"]','Сумма равна 35, значений 5, поэтому среднее 35/5=7.','Qiymatlar 3, 5, 7, 9, 11. O‘rtacha nechaga teng?','["5","6","8","7"]','Yig‘indi 35 va 5 ta qiymat bor, demak o‘rtacha 35/5=7.',40),
('P5DAT09-R03','P5-DAT-09','retest','medium','input','For 8 observations, Σx=104. Enter the mean.','[]','13','The mean is 104/8=13.','Для 8 наблюдений Σx=104. Введите среднее.','[]','Среднее 104/8=13.','8 ta kuzatuv uchun Σx=104. O‘rtachani kiriting.','[]','O‘rtacha 104/8=13.',35),
('P5DAT09-R04','P5-DAT-09','retest','hard','mcq','For 4 observations, Σx=20 and Σx²=120. Find the variance using Σx²/n−x̄².','["25","30","5","10"]','C','The mean is 5. Variance=120/4−5²=30−25=5.','Для 4 наблюдений Σx=20 и Σx²=120. Найдите дисперсию по формуле Σx²/n−x̄².','["25","30","5","10"]','Среднее равно 5. Дисперсия=120/4−5²=30−25=5.','4 ta kuzatuv uchun Σx=20 va Σx²=120. Σx²/n−x̄² formulasi bilan dispersiyani toping.','["25","30","5","10"]','O‘rtacha 5. Dispersiya=120/4−5²=30−25=5.',55),
('P5DAT09-M02','P5-DAT-09','mixed','hard','input','For the values 2, 2, 4, 8, enter the variance using Σx²/n−x̄².','[]','6','The mean is 4 and Σx²=88. Variance=88/4−4²=22−16=6.','Для значений 2, 2, 4, 8 введите дисперсию по формуле Σx²/n−x̄².','[]','Среднее 4, а Σx²=88. Дисперсия=88/4−4²=22−16=6.','2, 2, 4, 8 qiymatlari uchun Σx²/n−x̄² formulasi bilan dispersiyani kiriting.','[]','O‘rtacha 4, Σx²=88. Dispersiya=88/4−4²=22−16=6.',55),
('P5DAT10-D02','P5-DAT-10','diagnostic','medium','mcq','Group A has 10 values with mean 12. Group B has 15 values with mean 18. What is the combined mean?','["15","16","14.4","15.6"]','D','Combined total=10(12)+15(18)=390 across 25 values, so mean=390/25=15.6.','В группе A 10 значений со средним 12. В группе B 15 значений со средним 18. Чему равно объединённое среднее?','["15","16","14,4","15,6"]','Общая сумма=10(12)+15(18)=390 для 25 значений, поэтому среднее=390/25=15,6.','A guruhda 10 ta qiymat, o‘rtacha 12. B guruhda 15 ta qiymat, o‘rtacha 18. Birlashtirilgan o‘rtacha nechaga teng?','["15","16","14.4","15.6"]','Umumiy yig‘indi=10(12)+15(18)=390, jami 25 qiymat. O‘rtacha=390/25=15.6.',55),
('P5DAT10-D03','P5-DAT-10','diagnostic','medium','mcq','For coded values y=(x−4)/3, the mean of x is 19. What is the mean of y?','["5","3","7","15"]','A','The same linear transformation applies to the mean: ȳ=(19−4)/3=5.','Для кодированных значений y=(x−4)/3 среднее x равно 19. Чему равно среднее y?','["5","3","7","15"]','К среднему применяется то же линейное преобразование: ȳ=(19−4)/3=5.','Kodlangan y=(x−4)/3 qiymatlar uchun x o‘rtachasi 19. y o‘rtachasi nechaga teng?','["5","3","7","15"]','O‘rtachaga ham shu chiziqli o‘zgarish qo‘llanadi: ȳ=(19−4)/3=5.',50),
('P5DAT10-R03','P5-DAT-10','retest','medium','input','A set of 12 values has mean 7. Enter the total of the 12 values.','[]','84','Total=12×7=84.','Набор из 12 значений имеет среднее 7. Введите сумму всех 12 значений.','[]','Сумма=12×7=84.','12 ta qiymatdan iborat to‘plamning o‘rtachasi 7. Barcha qiymatlar yig‘indisini kiriting.','[]','Yig‘indi=12×7=84.',35),
('P5DAT10-R04','P5-DAT-10','retest','hard','mcq','Group A has 8 values with mean 5. Group B has 12 values with mean 9. Find the combined mean.','["7","8","6.4","7.4"]','D','Combined total=8(5)+12(9)=148. Divide by 20: 148/20=7.4.','В группе A 8 значений со средним 5. В группе B 12 значений со средним 9. Найдите объединённое среднее.','["7","8","6,4","7,4"]','Общая сумма=8(5)+12(9)=148. Делим на 20: 148/20=7,4.','A guruhda 8 ta qiymat, o‘rtacha 5. B guruhda 12 ta qiymat, o‘rtacha 9. Birlashtirilgan o‘rtachani toping.','["7","8","6.4","7.4"]','Umumiy yig‘indi=8(5)+12(9)=148. 20 ga bo‘lamiz: 148/20=7.4.',55),
('P5DAT10-M02','P5-DAT-10','mixed','hard','input','Values are coded by x=2y+6. If the mean of y is 4.5, enter the mean of x.','[]','15','x̄=2ȳ+6=2(4.5)+6=15.','Значения связаны кодированием x=2y+6. Если среднее y равно 4,5, введите среднее x.','[]','x̄=2ȳ+6=2(4,5)+6=15.','Qiymatlar x=2y+6 bo‘yicha kodlangan. Agar y o‘rtachasi 4.5 bo‘lsa, x o‘rtachasini kiriting.','[]','x̄=2ȳ+6=2(4.5)+6=15.',45),
('P5NOR02-D02','P5-NOR-02','diagnostic','medium','mcq','X~N(60,16). What is the z-score corresponding to X=68?','["0.5","4","2","8"]','C','Variance 16 gives σ=4. Therefore z=(68−60)/4=2.','X~N(60,16). Каково z-значение для X=68?','["0,5","4","2","8"]','Дисперсия 16 даёт σ=4. Поэтому z=(68−60)/4=2.','X~N(60,16). X=68 uchun z-qiymat nechaga teng?','["0.5","4","2","8"]','Dispersiya 16 bo‘lsa σ=4. Shuning uchun z=(68−60)/4=2.',45),
('P5NOR02-D03','P5-NOR-02','diagnostic','medium','mcq','X~N(30,25). What is the z-score corresponding to X=20?','["-10","-0.4","2","-2"]','D','σ=5, so z=(20−30)/5=−2.','X~N(30,25). Каково z-значение для X=20?','["-10","-0,4","2","-2"]','σ=5, поэтому z=(20−30)/5=−2.','X~N(30,25). X=20 uchun z-qiymat nechaga teng?','["-10","-0.4","2","-2"]','σ=5, demak z=(20−30)/5=−2.',45),
('P5NOR02-R03','P5-NOR-02','retest','medium','input','X~N(100,36). Enter the z-score for X=112.','[]','2','σ=6, so z=(112−100)/6=2.','X~N(100,36). Введите z-значение для X=112.','[]','σ=6, поэтому z=(112−100)/6=2.','X~N(100,36). X=112 uchun z-qiymatni kiriting.','[]','σ=6, shuning uchun z=(112−100)/6=2.',35),
('P5NOR02-R04','P5-NOR-02','retest','medium','mcq','X~N(50,9). What is the z-score for X=44?','["-6","-2","-3","2"]','B','σ=3, so z=(44−50)/3=−2.','X~N(50,9). Каково z-значение для X=44?','["-6","-2","-3","2"]','σ=3, поэтому z=(44−50)/3=−2.','X~N(50,9). X=44 uchun z-qiymat nechaga teng?','["-6","-2","-3","2"]','σ=3, demak z=(44−50)/3=−2.',45),
('P5NOR02-M02','P5-NOR-02','mixed','hard','input','X~N(80,49). Enter the z-score for X=66.','[]','-2','σ=7, so z=(66−80)/7=−2.','X~N(80,49). Введите z-значение для X=66.','[]','σ=7, поэтому z=(66−80)/7=−2.','X~N(80,49). X=66 uchun z-qiymatni kiriting.','[]','σ=7, shuning uchun z=(66−80)/7=−2.',45),
('P5NOR03-D02','P5-NOR-03','diagnostic','medium','mcq','For Z~N(0,1), P(Z<1.50)=0.9332. What is P(Z>1.50)?','["0.0668","0.9332","0.4332","0.1336"]','A','Use the complement: 1−0.9332=0.0668.','Для Z~N(0,1), P(Z<1,50)=0,9332. Чему равно P(Z>1,50)?','["0,0668","0,9332","0,4332","0,1336"]','Используем дополнение: 1−0,9332=0,0668.','Z~N(0,1) uchun P(Z<1.50)=0.9332. P(Z>1.50) nechaga teng?','["0.0668","0.9332","0.4332","0.1336"]','To‘ldiruvchi ehtimol: 1−0.9332=0.0668.',40),
('P5NOR03-D03','P5-NOR-03','diagnostic','medium','mcq','For Z~N(0,1), P(Z<0.80)=0.7881. Find P(−0.80<Z<0.80).','["0.2119","0.7881","0.5762","0.4238"]','C','By symmetry P(Z<−0.80)=1−0.7881=0.2119. Thus 0.7881−0.2119=0.5762.','Для Z~N(0,1), P(Z<0,80)=0,7881. Найдите P(−0,80<Z<0,80).','["0,2119","0,7881","0,5762","0,4238"]','По симметрии P(Z<−0,80)=1−0,7881=0,2119. Поэтому 0,7881−0,2119=0,5762.','Z~N(0,1) uchun P(Z<0.80)=0.7881. P(−0.80<Z<0.80) ni toping.','["0.2119","0.7881","0.5762","0.4238"]','Simmetriya bo‘yicha P(Z<−0.80)=1−0.7881=0.2119. Demak 0.7881−0.2119=0.5762.',50),
('P5NOR03-R03','P5-NOR-03','retest','medium','input','For Z~N(0,1), P(Z<1.10)=0.8643. Enter P(Z<−1.10) to 4 d.p.','[]','0.1357','By symmetry P(Z<−1.10)=1−0.8643=0.1357.','Для Z~N(0,1), P(Z<1,10)=0,8643. Введите P(Z<−1,10) до 4 знаков.','[]','По симметрии P(Z<−1,10)=1−0,8643=0,1357.','Z~N(0,1) uchun P(Z<1.10)=0.8643. P(Z<−1.10) ni 4 xonagacha kiriting.','[]','Simmetriya bo‘yicha P(Z<−1.10)=1−0.8643=0.1357.',35),
('P5NOR03-R04','P5-NOR-03','retest','medium','mcq','For Z~N(0,1), P(Z<0.25)=0.5987. What is P(Z>−0.25)?','["0.5987","0.4013","0.1974","0.9013"]','A','By symmetry, P(Z>−0.25)=P(Z<0.25)=0.5987.','Для Z~N(0,1), P(Z<0,25)=0,5987. Чему равно P(Z>−0,25)?','["0,5987","0,4013","0,1974","0,9013"]','По симметрии P(Z>−0,25)=P(Z<0,25)=0,5987.','Z~N(0,1) uchun P(Z<0.25)=0.5987. P(Z>−0.25) nechaga teng?','["0.5987","0.4013","0.1974","0.9013"]','Simmetriya bo‘yicha P(Z>−0.25)=P(Z<0.25)=0.5987.',45),
('P5NOR03-M02','P5-NOR-03','mixed','hard','input','For Z~N(0,1), P(Z<1.96)=0.9750. Enter P(−1.96<Z<1.96).','[]','0.95','Each tail has probability 0.0250, so the central probability is 1−0.0500=0.9500.','Для Z~N(0,1), P(Z<1,96)=0,9750. Введите P(−1,96<Z<1,96).','[]','Вероятность каждого хвоста 0,0250, поэтому центральная вероятность 1−0,0500=0,9500.','Z~N(0,1) uchun P(Z<1.96)=0.9750. P(−1.96<Z<1.96) ni kiriting.','[]','Har bir dum ehtimoli 0.0250, demak markaziy ehtimol 1−0.0500=0.9500.',45),
('P5NOR04-D02','P5-NOR-04','diagnostic','medium','mcq','For Z~N(0,1), which z-value is approximately the 97.5th percentile?','["1.645","1.282","2.326","1.96"]','D','The standard-normal 97.5th percentile is approximately z=1.96.','Для Z~N(0,1) какое z-значение примерно соответствует 97,5-му процентилю?','["1,645","1,282","2,326","1,96"]','97,5-й процентиль стандартного нормального распределения примерно равен z=1,96.','Z~N(0,1) uchun 97.5-percentilga taxminan qaysi z-qiymat mos?','["1.645","1.282","2.326","1.96"]','Standart normal taqsimotning 97.5-percentili taxminan z=1.96.',35),
('P5NOR04-D03','P5-NOR-04','diagnostic','medium','mcq','X~N(50,100). Using z=1.282 for the 90th percentile, find the 90th percentile of X.','["51.28","57.82","62.82","75.64"]','C','σ=10, so x=50+1.282(10)=62.82.','X~N(50,100). Используя z=1,282 для 90-го процентиля, найдите 90-й процентиль X.','["51,28","57,82","62,82","75,64"]','σ=10, поэтому x=50+1,282(10)=62,82.','X~N(50,100). 90-percentil uchun z=1.282 dan foydalanib, X ning 90-percentilini toping.','["51.28","57.82","62.82","75.64"]','σ=10, shuning uchun x=50+1.282(10)=62.82.',50),
('P5NOR04-R03','P5-NOR-04','retest','medium','input','X~N(40,25). Using z=1.282, enter the lower 10th percentile to 2 d.p.','[]','33.59','σ=5 and the lower 10th percentile uses z=−1.282: x=40−1.282(5)=33.59.','X~N(40,25). Используя z=1,282, введите нижний 10-й процентиль до 2 знаков.','[]','σ=5, а для нижнего 10-го процентиля z=−1,282: x=40−1,282(5)=33,59.','X~N(40,25). z=1.282 dan foydalanib, pastki 10-percentilni 2 xonagacha kiriting.','[]','σ=5 va pastki 10-percentil uchun z=−1.282: x=40−1.282(5)=33.59.',50),
('P5NOR04-R04','P5-NOR-04','retest','hard','mcq','X~N(70,16). Using z=0.674 for the 75th percentile, find the 75th percentile to 2 d.p.','["70.67","74.00","76.74","72.70"]','D','σ=4, so x=70+0.674(4)=72.696≈72.70.','X~N(70,16). Используя z=0,674 для 75-го процентиля, найдите 75-й процентиль до 2 знаков.','["70,67","74,00","76,74","72,70"]','σ=4, поэтому x=70+0,674(4)=72,696≈72,70.','X~N(70,16). 75-percentil uchun z=0.674 dan foydalanib, 75-percentilni 2 xonagacha toping.','["70.67","74.00","76.74","72.70"]','σ=4, shuning uchun x=70+0.674(4)=72.696≈72.70.',50),
('P5NOR04-M02','P5-NOR-04','mixed','medium','input','X~N(84,9). Enter the median of X.','[]','84','A normal distribution is symmetric, so its median equals its mean: 84.','X~N(84,9). Введите медиану X.','[]','Нормальное распределение симметрично, поэтому медиана равна среднему: 84.','X~N(84,9). X medianasini kiriting.','[]','Normal taqsimot simmetrik, shuning uchun mediana o‘rtachaga teng: 84.',30),
('P5NOR05-D02','P5-NOR-05','diagnostic','hard','mcq','X~N(μ,16) and P(X<72)=0.8413. Using z=1 for this probability, find μ.','["64","68","70","71"]','B','σ=4 and (72−μ)/4=1, so μ=68.','X~N(μ,16) и P(X<72)=0,8413. Используя z=1 для этой вероятности, найдите μ.','["64","68","70","71"]','σ=4 и (72−μ)/4=1, поэтому μ=68.','X~N(μ,16) va P(X<72)=0.8413. Bu ehtimol uchun z=1 dan foydalanib, μ ni toping.','["64","68","70","71"]','σ=4 va (72−μ)/4=1, demak μ=68.',55),
('P5NOR05-D03','P5-NOR-05','diagnostic','hard','mcq','X~N(50,σ²) and P(X<58)=0.9772. Using z=2, find σ.','["4","2","8","16"]','A','(58−50)/σ=2, so σ=4.','X~N(50,σ²) и P(X<58)=0,9772. Используя z=2, найдите σ.','["4","2","8","16"]','(58−50)/σ=2, поэтому σ=4.','X~N(50,σ²) va P(X<58)=0.9772. z=2 dan foydalanib, σ ni toping.','["4","2","8","16"]','(58−50)/σ=2, demak σ=4.',50),
('P5NOR05-R03','P5-NOR-05','retest','medium','input','X~N(μ,9) and P(X<40)=0.1587. Using z=−1, enter μ.','[]','43','σ=3 and (40−μ)/3=−1, so μ=43.','X~N(μ,9) и P(X<40)=0,1587. Используя z=−1, введите μ.','[]','σ=3 и (40−μ)/3=−1, поэтому μ=43.','X~N(μ,9) va P(X<40)=0.1587. z=−1 dan foydalanib, μ ni kiriting.','[]','σ=3 va (40−μ)/3=−1, demak μ=43.',45),
('P5NOR05-R04','P5-NOR-05','retest','hard','mcq','X~N(μ,σ²), P(X<30)=0.1587 and P(X<42)=0.8413. Using z=−1 and z=1, find μ.','["30","36","42","6"]','B','30=μ−σ and 42=μ+σ. Adding gives 72=2μ, so μ=36.','X~N(μ,σ²), P(X<30)=0,1587 и P(X<42)=0,8413. Используя z=−1 и z=1, найдите μ.','["30","36","42","6"]','30=μ−σ и 42=μ+σ. Складывая, получаем 72=2μ, поэтому μ=36.','X~N(μ,σ²), P(X<30)=0.1587 va P(X<42)=0.8413. z=−1 va z=1 dan foydalanib, μ ni toping.','["30","36","42","6"]','30=μ−σ va 42=μ+σ. Qo‘shsak 72=2μ, demak μ=36.',60),
('P5NOR05-M02','P5-NOR-05','mixed','hard','input','A normal distribution has lower quartile 54 and upper quartile 66. Enter its mean μ.','[]','60','A normal distribution is symmetric, so the mean lies midway between symmetric quartiles: (54+66)/2=60.','У нормального распределения нижний квартиль 54, верхний квартиль 66. Введите среднее μ.','[]','Нормальное распределение симметрично, поэтому среднее находится посередине между симметричными квартилями: (54+66)/2=60.','Normal taqsimotning pastki kvartili 54, yuqori kvartili 66. O‘rtacha μ ni kiriting.','[]','Normal taqsimot simmetrik, shuning uchun o‘rtacha simmetrik kvartillar o‘rtasida: (54+66)/2=60.',45),
('P5NOR06-D02','P5-NOR-06','diagnostic','hard','mcq','X~Bin(100,0.5). Which normal-approximation setup is correct for P(X≤55)?','["Y~N(50,25) and use P(Y<55.5)","Y~N(50,5) and use P(Y<55.5)","Y~N(50,25) and use P(Y<55)","Y~N(100,25) and use P(Y<55.5)"]','A','The normal mean is np=50 and variance np(1−p)=25. Continuity correction changes X≤55 to Y<55.5.','X~Bin(100,0,5). Какая запись нормального приближения верна для P(X≤55)?','["Y~N(50,25) и использовать P(Y<55,5)","Y~N(50,5) и использовать P(Y<55,5)","Y~N(50,25) и использовать P(Y<55)","Y~N(100,25) и использовать P(Y<55,5)"]','Среднее нормального приближения np=50, дисперсия np(1−p)=25. Поправка на непрерывность заменяет X≤55 на Y<55,5.','X~Bin(100,0.5). P(X≤55) uchun qaysi normal yaqinlashuv to‘g‘ri?','["Y~N(50,25) va P(Y<55.5) dan foydalanish","Y~N(50,5) va P(Y<55.5) dan foydalanish","Y~N(50,25) va P(Y<55) dan foydalanish","Y~N(100,25) va P(Y<55.5) dan foydalanish"]','Normal yaqinlashuv o‘rtachasi np=50, dispersiyasi np(1−p)=25. Uzluksizlik tuzatishi X≤55 ni Y<55.5 ga o‘zgartiradi.',70),
('P5NOR06-D03','P5-NOR-06','diagnostic','medium','mcq','For X~Bin(200,0.2), what variance is used in the normal approximation?','["40","32","16","160"]','B','Variance=np(1−p)=200(0.2)(0.8)=32.','Для X~Bin(200,0,2) какая дисперсия используется в нормальном приближении?','["40","32","16","160"]','Дисперсия=np(1−p)=200(0,2)(0,8)=32.','X~Bin(200,0.2) uchun normal yaqinlashuvda qaysi dispersiya ishlatiladi?','["40","32","16","160"]','Dispersiya=np(1−p)=200(0.2)(0.8)=32.',45),
('P5NOR06-R03','P5-NOR-06','retest','medium','input','For X~Bin(80,0.25), a normal approximation is used for P(X≥25). Enter the continuity-corrected lower boundary.','[]','24.5','The inclusive event X≥25 becomes Y>24.5.','Для X~Bin(80,0,25) нормальное приближение используется для P(X≥25). Введите нижнюю границу с поправкой на непрерывность.','[]','Включённое событие X≥25 превращается в Y>24,5.','X~Bin(80,0.25) uchun P(X≥25) normal yaqinlashuv bilan topiladi. Uzluksizlik tuzatishidan keyingi pastki chegarani kiriting.','[]','X≥25 hodisasi Y>24.5 ga o‘zgaradi.',40),
('P5NOR06-R04','P5-NOR-06','retest','hard','mcq','For X~Bin(120,0.4), which continuity-corrected interval represents P(45≤X≤55)?','["44.5<Y<55.5","45<Y<55","45.5<Y<54.5","44<Y<56"]','A','Both integer endpoints are included, so move the lower boundary down by 0.5 and the upper boundary up by 0.5.','Для X~Bin(120,0,4) какой интервал с поправкой на непрерывность соответствует P(45≤X≤55)?','["44.5<Y<55.5","45<Y<55","45.5<Y<54.5","44<Y<56"]','Обе целые границы включены, поэтому нижнюю границу уменьшаем на 0,5, а верхнюю увеличиваем на 0,5.','X~Bin(120,0.4) uchun P(45≤X≤55) ga qaysi uzluksizlik tuzatishli oraliq mos?','["44.5<Y<55.5","45<Y<55","45.5<Y<54.5","44<Y<56"]','Ikkala butun chegara ham kiritilgan, shuning uchun pastki chegarani 0.5 ga kamaytirib, yuqori chegarani 0.5 ga oshiramiz.',55),
('P5NOR06-M02','P5-NOR-06','mixed','hard','input','For X~Bin(150,0.3), enter the variance np(1−p) used in the normal approximation.','[]','31.5','np(1−p)=150(0.3)(0.7)=31.5.','Для X~Bin(150,0,3) введите дисперсию np(1−p), используемую в нормальном приближении.','[]','np(1−p)=150(0,3)(0,7)=31,5.','X~Bin(150,0.3) uchun normal yaqinlashuvda ishlatiladigan np(1−p) dispersiyani kiriting.','[]','np(1−p)=150(0.3)(0.7)=31.5.',40)
)
insert into public.questions(subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status)
select 5,sm.topic,s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P5:p5_aw21_24_annual_reserve_topup_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
join (values
('P5-DAT-08','P5 Data Representation'),
('P5-DAT-09','P5 Data Summaries'),
('P5-DAT-10','P5 Coded and Combined Data'),
('P5-NOR-02','P5 Normal Distribution'),
('P5-NOR-03','P5 Normal Distribution'),
('P5-NOR-04','P5 Normal Distribution'),
('P5-NOR-05','P5 Normal Distribution'),
('P5-NOR-06','P5 Normal Approximation')
) sm(skill_code,topic) on sm.skill_code=s.skill_code
where not exists(select 1 from public.questions q where q.book_ref='ExamPrep:P5:p5_aw21_24_annual_reserve_topup_draft_v1:'||s.content_key);

with src(content_key,skill_code,meta_id,official_ref,book_ref) as (values
('P5DAT08-D02','P5-DAT-08',59582,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2-3 pp. 14-59 (mapping only)'),
('P5DAT08-D03','P5-DAT-08',59583,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2-3 pp. 14-59 (mapping only)'),
('P5DAT08-R03','P5-DAT-08',59584,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2-3 pp. 14-59 (mapping only)'),
('P5DAT08-R04','P5-DAT-08',59585,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2-3 pp. 14-59 (mapping only)'),
('P5DAT08-M02','P5-DAT-08',59586,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2-3 pp. 14-59 (mapping only)'),
('P5DAT09-D02','P5-DAT-09',59587,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
('P5DAT09-D03','P5-DAT-09',59588,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
('P5DAT09-R03','P5-DAT-09',59589,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
('P5DAT09-R04','P5-DAT-09',59590,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
('P5DAT09-M02','P5-DAT-09',59591,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
('P5DAT10-D02','P5-DAT-10',59592,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
('P5DAT10-D03','P5-DAT-10',59593,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
('P5DAT10-R03','P5-DAT-10',59594,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
('P5DAT10-R04','P5-DAT-10',59595,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
('P5DAT10-M02','P5-DAT-10',59596,'Cambridge 9709 2026-2027 v4; P5 5.1 Representation of data','Complete Probability & Statistics 1; Ch2 pp. 14-29 (mapping only)'),
('P5NOR02-D02','P5-NOR-02',59597,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR02-D03','P5-NOR-02',59598,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR02-R03','P5-NOR-02',59599,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR02-R04','P5-NOR-02',59600,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR02-M02','P5-NOR-02',59601,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR03-D02','P5-NOR-03',59602,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR03-D03','P5-NOR-03',59603,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR03-R03','P5-NOR-03',59604,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR03-R04','P5-NOR-03',59605,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR03-M02','P5-NOR-03',59606,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR04-D02','P5-NOR-04',59607,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR04-D03','P5-NOR-04',59608,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR04-R03','P5-NOR-04',59609,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR04-R04','P5-NOR-04',59610,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR04-M02','P5-NOR-04',59611,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR05-D02','P5-NOR-05',59612,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR05-D03','P5-NOR-05',59613,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR05-R03','P5-NOR-05',59614,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR05-R04','P5-NOR-05',59615,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR05-M02','P5-NOR-05',59616,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch9 pp. 147-171 (mapping only)'),
('P5NOR06-D02','P5-NOR-06',59617,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch10 pp. 173-179 (mapping only)'),
('P5NOR06-D03','P5-NOR-06',59618,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch10 pp. 173-179 (mapping only)'),
('P5NOR06-R03','P5-NOR-06',59619,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch10 pp. 173-179 (mapping only)'),
('P5NOR06-R04','P5-NOR-06',59620,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch10 pp. 173-179 (mapping only)'),
('P5NOR06-M02','P5-NOR-06',59621,'Cambridge 9709 2026-2027 v4; P5 5.5 The normal distribution','Complete Probability & Statistics 1; Ch10 pp. 173-179 (mapping only)')
)
insert into private.exam_prep_question_content_meta(id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5)
overriding system value
select s.meta_id,4824,s.content_key,q.id,s.skill_code,'{}'::text[],case when s.content_key like '%-D%' then 'diagnostic' when s.content_key like '%-R%' then 'retest' else 'mixed' end,
 'withheld','draft','Original iClub-authored stem, values, distractors, answer and explanation; no Cambridge/coursebook question, solution, diagram or mark-scheme wording copied.',
 'AW21-24 annual reserve authored from canonical skill intent with independent values and contexts; withheld reserve only.',
 s.official_ref,s.book_ref,'pending','pending','pending','pending','pending',case when s.content_key like '%-D%' then 'pending' else 'not_applicable' end,
 md5(concat_ws(chr(31),q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),coalesce(q.difficulty,''),coalesce(q.qtype,''),
 coalesce(q.question_text,''),coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),coalesce(q.image_url,''),coalesce(q.is_active::text,''),
 coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
 coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))
from src s join public.questions q on q.book_ref='ExamPrep:P5:p5_aw21_24_annual_reserve_topup_draft_v1:'||s.content_key
on conflict(id) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int; v_inputs int; v_seq text;
begin
 if (select count(*) from private.exam_prep_question_content_meta where content_version_id=4824 and lifecycle_state='draft' and exposure_state='withheld')<>40
    or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4824 and reserve_role='diagnostic')<>16
    or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4824 and reserve_role='retest')<>16
    or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4824 and reserve_role='mixed')<>8
 then raise exception 'aw21_24_annual_reserve_p5_draft cardinality/state failed'; end if;

 select count(*) into v_bad from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
 where m.content_version_id=4824 and (
   q.is_active or q.quality_status<>'draft'
   or m.copyright_status<>'pending' or m.qa_scope_status<>'pending' or m.qa_math_status<>'pending' or m.qa_language_status<>'pending' or m.qa_technical_status<>'pending'
   or nullif(btrim(q.question_text_en),'') is null or nullif(btrim(q.question_text_ru),'') is null or nullif(btrim(q.question_text_uz),'') is null
   or nullif(btrim(q.explanation_en),'') is null or nullif(btrim(q.explanation_ru),'') is null or nullif(btrim(q.explanation_uz),'') is null
   or (m.reserve_role='diagnostic' and (q.qtype<>'mcq' or m.diagnostic_rule_status<>'pending'))
   or (m.reserve_role<>'diagnostic' and m.diagnostic_rule_status<>'not_applicable')
   or (q.qtype='mcq' and (q.correct_answer not in ('A','B','C','D') or jsonb_array_length(q.options_text_en::jsonb)<>4 or jsonb_array_length(q.options_text_ru::jsonb)<>4 or jsonb_array_length(q.options_text_uz::jsonb)<>4
       or (select count(distinct v) from jsonb_array_elements_text(q.options_text_en::jsonb) z(v))<>4 or (select count(distinct v) from jsonb_array_elements_text(q.options_text_ru::jsonb) z(v))<>4 or (select count(distinct v) from jsonb_array_elements_text(q.options_text_uz::jsonb) z(v))<>4))
   or (q.qtype='input' and (nullif(btrim(q.correct_answer),'') is null or q.options_text_en::jsonb<>'[]'::jsonb or q.options_text_ru::jsonb<>'[]'::jsonb or q.options_text_uz::jsonb<>'[]'::jsonb))
 );
 if v_bad<>0 then raise exception 'aw21_24_annual_reserve_p5_draft payload/QA rows=%',v_bad; end if;

 select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D'),count(*) filter(where q.qtype='input')
 into v_a,v_b,v_c,v_d,v_inputs from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id where m.content_version_id=4824;
 if (v_a,v_b,v_c,v_d,v_inputs)<>(6,6,6,6,16) then raise exception 'aw21_24_annual_reserve_p5_draft answer balance A=% B=% C=% D=% input=%',v_a,v_b,v_c,v_d,v_inputs; end if;

 select string_agg(q.correct_answer,'' order by m.id) into v_seq from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id where m.content_version_id=4824 and q.qtype='mcq';
 if v_seq like any(array['%ABCD%','%BCDA%','%CDAB%','%DABC%','%DCBA%','%CBAD%','%BADC%','%ADCB%'])
    or v_seq ~ '(AA|BB|CC|DD)'
 then raise exception 'aw21_24_annual_reserve_p5_draft sequential answer pattern detected: %',v_seq; end if;

 if exists(select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
   join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4824
   join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
   join public.questions oldq on oldq.id=oldm.question_id
   where m.content_version_id=4824 and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g')))
 then raise exception 'aw21_24_annual_reserve_p5_draft exact published stem duplicate'; end if;

 if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4824)
    or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4824)
    or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4824)
 then raise exception 'aw21_24_annual_reserve_p5_draft unexpected history'; end if;
end
$postcheck$;

commit;
