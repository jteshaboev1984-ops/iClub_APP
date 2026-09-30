-- AW17-20 P1 annual-reserve top-up draft v1.
-- DRAFT ONLY: no learner-visible content and no existing evidence mutation.
-- Exact delta per skill: +2 diagnostics, +2 delayed retests, +1 mixed/transfer.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if not exists(select 1 from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active')
  then raise exception 'aw17_20_annual_reserve_p1_draft canonical program missing'; end if;

  if exists(select 1 from private.exam_prep_content_versions where id=4819 and content_version<>'p1_aw17_20_annual_reserve_topup_draft_v1')
     or exists(select 1 from private.exam_prep_question_content_meta where id between 59423 and 59452 and content_version_id<>4819)
  then raise exception 'aw17_20_annual_reserve_p1_draft reserved id collision'; end if;

  if (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-SER-03','P1-SER-04','P1-SER-05','P1-DIF-02','P1-DIF-03','P1-DIF-04')
        and m.reserve_role='diagnostic')<>6
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-SER-03','P1-SER-04','P1-SER-05','P1-DIF-02','P1-DIF-03','P1-DIF-04')
        and m.reserve_role='retest')<>12
     or (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.status='published' and m.lifecycle_state in ('published','reserve')
        and m.primary_skill_code in ('P1-SER-03','P1-SER-04','P1-SER-05','P1-DIF-02','P1-DIF-03','P1-DIF-04')
        and m.reserve_role in ('learning','mixed'))<>42
  then raise exception 'aw17_20_annual_reserve_p1_draft baseline depth changed'; end if;
end
$preflight$;

insert into private.exam_prep_content_versions(
 id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
)
overriding system value
select 4819,pv.id,'p1_aw17_20_annual_reserve_topup_draft_v1','P1',
 'P1 AW17-20 annual reserve top-up draft v1','draft',
 'Original iClub-authored annual reserve expansion. Official Cambridge 9709 scope controls the learning objectives; Complete Pure Mathematics 1 is mapping/explanation support only. No protected Cambridge/coursebook question, solution, mark-scheme wording or diagram is copied. Independent academic, trilingual, technical, originality and reserve-isolation QA is required before publication.',
 3
from private.exam_prep_program_versions pv
where pv.program_key='math_as_p1_p5' and pv.version_key='p1_p5_canonical_v1_0' and pv.status='active'
on conflict(program_version_id,content_version) do nothing;

with src(content_key,skill_code,reserve_role,difficulty,qtype,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz,time_limit) as (values
('P1SER03-D02','P1-SER-03','diagnostic','medium','mcq','An arithmetic progression has u4=17 and u9=37. Find the common difference.','["4","5","20","2"]','A','u9−u4=5d=20, so d=4.','В арифметической прогрессии u4=17 и u9=37. Найдите разность.','["4","5","20","2"]','u9−u4=5d=20, поэтому d=4.','Arifmetik progressiyada u4=17 va u9=37. Umumiy ayirmani toping.','["4","5","20","2"]','u9−u4=5d=20, demak d=4.',70),
('P1SER03-D03','P1-SER-03','diagnostic','medium','mcq','An arithmetic progression has first term 7 and common difference 3. Find S12.','["270","276","282","288"]','C','S12=12/2[2(7)+11(3)]=6(47)=282.','В арифметической прогрессии первый член равен 7, а разность равна 3. Найдите S12.','["270","276","282","288"]','S12=12/2[2(7)+11(3)]=6(47)=282.','Arifmetik progressiyaning birinchi hadi 7, umumiy ayirmasi 3. S12 ni toping.','["270","276","282","288"]','S12=12/2[2(7)+11(3)]=6(47)=282.',70),
('P1SER03-R03','P1-SER-03','retest','medium','input','In an arithmetic progression, u5=18 and u12=46. Enter the first term.','[]','2','u12−u5=7d=28, so d=4. Then u5=a+4d=18 gives a=2.','В арифметической прогрессии u5=18 и u12=46. Введите первый член.','[]','u12−u5=7d=28, поэтому d=4. Затем u5=a+4d=18 даёт a=2.','Arifmetik progressiyada u5=18 va u12=46. Birinchi hadni kiriting.','[]','u12−u5=7d=28, demak d=4. So‘ng u5=a+4d=18 dan a=2.',75),
('P1SER03-R04','P1-SER-03','retest','hard','mcq','An arithmetic progression has first term 5 and S20=670. Find the common difference.','["2","3","4","5"]','B','670=20/2[2(5)+19d]=10(10+19d). Hence 10+19d=67, so d=3.','В арифметической прогрессии первый член равен 5 и S20=670. Найдите разность.','["2","3","4","5"]','670=20/2[2(5)+19d]=10(10+19d). Поэтому 10+19d=67, значит d=3.','Arifmetik progressiyaning birinchi hadi 5 va S20=670. Umumiy ayirmani toping.','["2","3","4","5"]','670=20/2[2(5)+19d]=10(10+19d). Demak 10+19d=67, shuning uchun d=3.',85),
('P1SER03-M02','P1-SER-03','mixed','hard','input','The arithmetic progression 8, 13, 18, ... continues. Enter the least value of n for which un>100.','[]','20','un=8+5(n−1)=5n+3. The inequality 5n+3>100 gives n>19.4, so the least integer n is 20.','Арифметическая прогрессия 8, 13, 18, ... продолжается. Введите наименьшее n, при котором un>100.','[]','un=8+5(n−1)=5n+3. Неравенство 5n+3>100 даёт n>19,4, поэтому наименьшее целое n равно 20.','8, 13, 18, ... arifmetik progressiya davom etadi. un>100 bo‘ladigan eng kichik n ni kiriting.','[]','un=8+5(n−1)=5n+3. 5n+3>100 dan n>19.4, demak eng kichik butun n=20.',85),
('P1SER04-D02','P1-SER-04','diagnostic','medium','mcq','A geometric progression has u2=12 and u5=324, with positive common ratio. Find the common ratio.','["2","3","6","9"]','B','u5/u2=r^3=324/12=27. Since r>0, r=3.','В геометрической прогрессии u2=12 и u5=324, а знаменатель положительный. Найдите знаменатель.','["2","3","6","9"]','u5/u2=r^3=324/12=27. Так как r>0, r=3.','Geometrik progressiyada u2=12 va u5=324, umumiy maxraj musbat. Umumiy maxrajni toping.','["2","3","6","9"]','u5/u2=r^3=324/12=27. r>0 bo‘lgani uchun r=3.',70),
('P1SER04-D03','P1-SER-04','diagnostic','medium','mcq','A geometric progression has first term 5 and common ratio 2. Find S6.','["155","160","305","315"]','D','S6=5(2^6−1)/(2−1)=5(63)=315.','В геометрической прогрессии первый член равен 5, а знаменатель равен 2. Найдите S6.','["155","160","305","315"]','S6=5(2^6−1)/(2−1)=5(63)=315.','Geometrik progressiyaning birinchi hadi 5, umumiy maxraji 2. S6 ni toping.','["155","160","305","315"]','S6=5(2^6−1)/(2−1)=5(63)=315.',70),
('P1SER04-R03','P1-SER-04','retest','medium','input','A geometric progression has u3=20 and u6=160, with positive common ratio. Enter the first term.','[]','5','u6/u3=r^3=8, so r=2. Then u3=ar^2=4a=20, hence a=5.','В геометрической прогрессии u3=20 и u6=160, а знаменатель положительный. Введите первый член.','[]','u6/u3=r^3=8, поэтому r=2. Затем u3=ar^2=4a=20, значит a=5.','Geometrik progressiyada u3=20 va u6=160, umumiy maxraj musbat. Birinchi hadni kiriting.','[]','u6/u3=r^3=8, demak r=2. So‘ng u3=ar^2=4a=20, shuning uchun a=5.',75),
('P1SER04-R04','P1-SER-04','retest','hard','mcq','A geometric progression has first term 3 and common ratio 1/2. Find S5.','["45/16","63/16","93/16","31/8"]','C','S5=3(1−(1/2)^5)/(1−1/2)=6(31/32)=93/16.','В геометрической прогрессии первый член равен 3, а знаменатель равен 1/2. Найдите S5.','["45/16","63/16","93/16","31/8"]','S5=3(1−(1/2)^5)/(1−1/2)=6(31/32)=93/16.','Geometrik progressiyaning birinchi hadi 3, umumiy maxraji 1/2. S5 ni toping.','["45/16","63/16","93/16","31/8"]','S5=3(1−(1/2)^5)/(1−1/2)=6(31/32)=93/16.',80),
('P1SER04-M02','P1-SER-04','mixed','hard','input','A geometric progression has first term 2 and fourth term 54, with positive common ratio. Enter S4.','[]','80','54=2r^3 gives r^3=27, so r=3. Hence S4=2+6+18+54=80.','В геометрической прогрессии первый член равен 2, четвёртый — 54, а знаменатель положительный. Введите S4.','[]','54=2r^3, поэтому r^3=27 и r=3. Следовательно, S4=2+6+18+54=80.','Geometrik progressiyaning birinchi hadi 2, to‘rtinchi hadi 54 va umumiy maxraji musbat. S4 ni kiriting.','[]','54=2r^3, demak r^3=27 va r=3. Shuning uchun S4=2+6+18+54=80.',85),
('P1SER05-D02','P1-SER-05','diagnostic','medium','mcq','Find the sum to infinity of the geometric series 12+6+3+....','["24","21","18","15"]','A','The common ratio is 1/2, so S∞=12/(1−1/2)=24.','Найдите сумму до бесконечности геометрического ряда 12+6+3+....','["24","21","18","15"]','Знаменатель равен 1/2, поэтому S∞=12/(1−1/2)=24.','12+6+3+... geometrik qatorining cheksiz yig‘indisini toping.','["24","21","18","15"]','Umumiy maxraj 1/2, demak S∞=12/(1−1/2)=24.',60),
('P1SER05-D03','P1-SER-05','diagnostic','medium','mcq','Which geometric series has a finite sum to infinity?','["5+7.5+11.25+...","8−9.6+11.52−...","14−7+3.5−...","4+4+4+..."]','C','A finite sum to infinity requires |r|<1. The ratios are 1.5, −1.2, −0.5 and 1, so only the third series converges.','Какой геометрический ряд имеет конечную сумму до бесконечности?','["5+7,5+11,25+...","8−9,6+11,52−...","14−7+3,5−...","4+4+4+..."]','Для конечной суммы до бесконечности необходимо |r|<1. Знаменатели равны 1,5, −1,2, −0,5 и 1, поэтому сходится только третий ряд.','Qaysi geometrik qatorning chekli cheksiz yig‘indisi mavjud?','["5+7.5+11.25+...","8−9.6+11.52−...","14−7+3.5−...","4+4+4+..."]','Chekli cheksiz yig‘indi uchun |r|<1 bo‘lishi kerak. Maxrajlar 1.5, −1.2, −0.5 va 1, shuning uchun faqat uchinchi qator yaqinlashadi.',70),
('P1SER05-R03','P1-SER-05','retest','medium','input','A convergent geometric series has first term 20 and common ratio −1/4. Enter its sum to infinity.','[]','16','S∞=20/(1−(−1/4))=20/(5/4)=16.','Сходящийся геометрический ряд имеет первый член 20 и знаменатель −1/4. Введите его сумму до бесконечности.','[]','S∞=20/(1−(−1/4))=20/(5/4)=16.','Yaqinlashuvchi geometrik qatorning birinchi hadi 20 va umumiy maxraji −1/4. Cheksiz yig‘indisini kiriting.','[]','S∞=20/(1−(−1/4))=20/(5/4)=16.',65),
('P1SER05-R04','P1-SER-05','retest','medium','mcq','A convergent geometric series has first term 12 and sum to infinity 30. Find the common ratio.','["0.4","0.5","0.6","0.8"]','C','30=12/(1−r), so 1−r=12/30=0.4 and r=0.6.','Сходящийся геометрический ряд имеет первый член 12 и сумму до бесконечности 30. Найдите знаменатель.','["0,4","0,5","0,6","0,8"]','30=12/(1−r), поэтому 1−r=12/30=0,4 и r=0,6.','Yaqinlashuvchi geometrik qatorning birinchi hadi 12 va cheksiz yig‘indisi 30. Umumiy maxrajni toping.','["0.4","0.5","0.6","0.8"]','30=12/(1−r), demak 1−r=12/30=0.4 va r=0.6.',70),
('P1SER05-M02','P1-SER-05','mixed','hard','input','A geometric series has first term 16 and common ratio 1/2. Enter the sum of all terms after the first three terms.','[]','4','The fourth term is 16(1/2)^3=2. The remaining tail is geometric with first term 2 and ratio 1/2, so its sum is 2/(1−1/2)=4.','Геометрический ряд имеет первый член 16 и знаменатель 1/2. Введите сумму всех членов после первых трёх.','[]','Четвёртый член равен 16(1/2)^3=2. Оставшийся хвост — геометрический ряд с первым членом 2 и знаменателем 1/2, поэтому его сумма равна 2/(1−1/2)=4.','Geometrik qatorning birinchi hadi 16 va umumiy maxraji 1/2. Dastlabki uch haddan keyingi barcha hadlar yig‘indisini kiriting.','[]','To‘rtinchi had 16(1/2)^3=2. Qolgan qism birinchi hadi 2 va maxraji 1/2 bo‘lgan geometrik qator, shuning uchun yig‘indi 2/(1−1/2)=4.',80),
('P1DIF02-D02','P1-DIF-02','diagnostic','medium','mcq','Differentiate y=5x^(4/3)−3x^(1/2). What is the coefficient of x^(1/3) in dy/dx?','["5/3","20/3","4/3","10"]','B','dy/dx=(20/3)x^(1/3)−(3/2)x^(−1/2), so the required coefficient is 20/3.','Дифференцируйте y=5x^(4/3)−3x^(1/2). Каков коэффициент при x^(1/3) в dy/dx?','["5/3","20/3","4/3","10"]','dy/dx=(20/3)x^(1/3)−(3/2)x^(−1/2), поэтому нужный коэффициент равен 20/3.','y=5x^(4/3)−3x^(1/2) ni differensiallang. dy/dx dagi x^(1/3) oldidagi koeffitsiyent qancha?','["5/3","20/3","4/3","10"]','dy/dx=(20/3)x^(1/3)−(3/2)x^(−1/2), demak kerakli koeffitsiyent 20/3.',70),
('P1DIF02-D03','P1-DIF-02','diagnostic','medium','mcq','Differentiate y=6x^(−2)+4x^(3/2).','["12x^(−3)+6x^(1/2)","−12x^(−1)+6x^(1/2)","−12x^(−3)+4x^(1/2)","−12x^(−3)+6x^(1/2)"]','D','Using d(x^n)/dx=nx^(n−1), dy/dx=−12x^(−3)+6x^(1/2).','Дифференцируйте y=6x^(−2)+4x^(3/2).','["12x^(−3)+6x^(1/2)","−12x^(−1)+6x^(1/2)","−12x^(−3)+4x^(1/2)","−12x^(−3)+6x^(1/2)"]','По правилу d(x^n)/dx=nx^(n−1), dy/dx=−12x^(−3)+6x^(1/2).','y=6x^(−2)+4x^(3/2) ni differensiallang.','["12x^(−3)+6x^(1/2)","−12x^(−1)+6x^(1/2)","−12x^(−3)+4x^(1/2)","−12x^(−3)+6x^(1/2)"]','d(x^n)/dx=nx^(n−1) qoidasiga ko‘ra dy/dx=−12x^(−3)+6x^(1/2).',70),
('P1DIF02-R03','P1-DIF-02','retest','medium','input','For y=kx^(5/2), the gradient at x=4 is 60. Enter k.','[]','3','dy/dx=(5k/2)x^(3/2). At x=4, x^(3/2)=8, so the gradient is 20k. Hence 20k=60 and k=3.','Для y=kx^(5/2) градиент при x=4 равен 60. Введите k.','[]','dy/dx=(5k/2)x^(3/2). При x=4 имеем x^(3/2)=8, поэтому градиент равен 20k. Следовательно, 20k=60 и k=3.','y=kx^(5/2) uchun x=4 dagi gradient 60. k ni kiriting.','[]','dy/dx=(5k/2)x^(3/2). x=4 da x^(3/2)=8, demak gradient 20k. Shuning uchun 20k=60 va k=3.',75),
('P1DIF02-R04','P1-DIF-02','retest','medium','mcq','Differentiate y=8x^(1/2)−2x^(−1).','["4x^(−1/2)+2x^(−2)","4x^(1/2)+2x^(−2)","8x^(−1/2)−2x^(−2)","4x^(−1/2)−2x^(−2)"]','A','dy/dx=8(1/2)x^(−1/2)−2(−1)x^(−2)=4x^(−1/2)+2x^(−2).','Дифференцируйте y=8x^(1/2)−2x^(−1).','["4x^(−1/2)+2x^(−2)","4x^(1/2)+2x^(−2)","8x^(−1/2)−2x^(−2)","4x^(−1/2)−2x^(−2)"]','dy/dx=8(1/2)x^(−1/2)−2(−1)x^(−2)=4x^(−1/2)+2x^(−2).','y=8x^(1/2)−2x^(−1) ni differensiallang.','["4x^(−1/2)+2x^(−2)","4x^(1/2)+2x^(−2)","8x^(−1/2)−2x^(−2)","4x^(−1/2)−2x^(−2)"]','dy/dx=8(1/2)x^(−1/2)−2(−1)x^(−2)=4x^(−1/2)+2x^(−2).',70),
('P1DIF02-M02','P1-DIF-02','mixed','hard','input','For f(x)=3x^(2/3), enter f''(8).','[]','1','f''(x)=2x^(−1/3). Since 8^(1/3)=2, f''(8)=2/2=1.','Для f(x)=3x^(2/3) введите f''(8).','[]','f''(x)=2x^(−1/3). Так как 8^(1/3)=2, f''(8)=2/2=1.','f(x)=3x^(2/3) uchun f''(8) ni kiriting.','[]','f''(x)=2x^(−1/3). 8^(1/3)=2 bo‘lgani uchun f''(8)=2/2=1.',70),
('P1DIF03-D02','P1-DIF-03','diagnostic','medium','mcq','Differentiate y=(3x−2)^5.','["15(3x−2)^4","5(3x−2)^4","15(3x−2)^5","3(3x−2)^4"]','A','The outer derivative is 5(3x−2)^4 and the inner derivative is 3, so dy/dx=15(3x−2)^4.','Дифференцируйте y=(3x−2)^5.','["15(3x−2)^4","5(3x−2)^4","15(3x−2)^5","3(3x−2)^4"]','Производная внешней функции равна 5(3x−2)^4, внутренней — 3, поэтому dy/dx=15(3x−2)^4.','y=(3x−2)^5 ni differensiallang.','["15(3x−2)^4","5(3x−2)^4","15(3x−2)^5","3(3x−2)^4"]','Tashqi funksiya hosilasi 5(3x−2)^4, ichki funksiya hosilasi 3, demak dy/dx=15(3x−2)^4.',65),
('P1DIF03-D03','P1-DIF-03','diagnostic','hard','mcq','For y=(2x+k)^3, the gradient at x=1 is 96. Given k>0, find k.','["1","4","2","6"]','C','dy/dx=6(2x+k)^2. At x=1, 6(2+k)^2=96, so (2+k)^2=16. With k>0, 2+k=4 and k=2.','Для y=(2x+k)^3 градиент при x=1 равен 96. Дано k>0. Найдите k.','["1","4","2","6"]','dy/dx=6(2x+k)^2. При x=1: 6(2+k)^2=96, поэтому (2+k)^2=16. Так как k>0, 2+k=4 и k=2.','y=(2x+k)^3 uchun x=1 dagi gradient 96. k>0 berilgan. k ni toping.','["1","4","2","6"]','dy/dx=6(2x+k)^2. x=1 da 6(2+k)^2=96, demak (2+k)^2=16. k>0 bo‘lgani uchun 2+k=4 va k=2.',80),
('P1DIF03-R03','P1-DIF-03','retest','medium','input','For y=(4x+1)^(1/2), enter dy/dx at x=2 as an exact fraction.','[]','2/3','dy/dx=2(4x+1)^(−1/2). At x=2 this is 2/√9=2/3.','Для y=(4x+1)^(1/2) введите dy/dx при x=2 в виде точной дроби.','[]','dy/dx=2(4x+1)^(−1/2). При x=2 это 2/√9=2/3.','y=(4x+1)^(1/2) uchun x=2 dagi dy/dx ni aniq kasr ko‘rinishida kiriting.','[]','dy/dx=2(4x+1)^(−1/2). x=2 da bu 2/√9=2/3.',70),
('P1DIF03-R04','P1-DIF-03','retest','medium','mcq','Differentiate y=(5−2x)^(−1).','["−2(5−2x)^(−2)","(5−2x)^(−2)","2(5−2x)^(−1)","2(5−2x)^(−2)"]','D','The outer derivative gives −(5−2x)^(−2), and multiplying by the inner derivative −2 gives 2(5−2x)^(−2).','Дифференцируйте y=(5−2x)^(−1).','["−2(5−2x)^(−2)","(5−2x)^(−2)","2(5−2x)^(−1)","2(5−2x)^(−2)"]','Производная внешней функции равна −(5−2x)^(−2), умножение на производную внутренней функции −2 даёт 2(5−2x)^(−2).','y=(5−2x)^(−1) ni differensiallang.','["−2(5−2x)^(−2)","(5−2x)^(−2)","2(5−2x)^(−1)","2(5−2x)^(−2)"]','Tashqi funksiya hosilasi −(5−2x)^(−2), ichki funksiya hosilasi −2 ga ko‘paytirib 2(5−2x)^(−2) hosil qilamiz.',70),
('P1DIF03-M02','P1-DIF-03','mixed','hard','input','For y=(ax−1)^2, the gradient at x=1 is 24. Given a>1, enter a.','[]','4','dy/dx=2a(ax−1). At x=1, 2a(a−1)=24, so a^2−a−12=0. Thus a=4 or −3; a>1 gives a=4.','Для y=(ax−1)^2 градиент при x=1 равен 24. Дано a>1. Введите a.','[]','dy/dx=2a(ax−1). При x=1: 2a(a−1)=24, поэтому a^2−a−12=0. Отсюда a=4 или −3; условие a>1 даёт a=4.','y=(ax−1)^2 uchun x=1 dagi gradient 24. a>1 berilgan. a ni kiriting.','[]','dy/dx=2a(ax−1). x=1 da 2a(a−1)=24, demak a^2−a−12=0. Bundan a=4 yoki −3; a>1 sharti a=4 ni beradi.',80),
('P1DIF04-D02','P1-DIF-04','diagnostic','medium','mcq','For y=x^2+4x, find the equation of the tangent at x=1.','["y=5x","y=6x−1","y=6x+1","y=5x+1"]','B','At x=1, y=5 and dy/dx=2x+4=6. Hence y−5=6(x−1), so y=6x−1.','Для y=x^2+4x найдите уравнение касательной при x=1.','["y=5x","y=6x−1","y=6x+1","y=5x+1"]','При x=1 имеем y=5 и dy/dx=2x+4=6. Поэтому y−5=6(x−1), то есть y=6x−1.','y=x^2+4x uchun x=1 dagi urinma tenglamasini toping.','["y=5x","y=6x−1","y=6x+1","y=5x+1"]','x=1 da y=5 va dy/dx=2x+4=6. Demak y−5=6(x−1), ya’ni y=6x−1.',70),
('P1DIF04-D03','P1-DIF-04','diagnostic','medium','mcq','For y=x^3, which is the equation of the normal at x=1?','["y−1=3(x−1)","y−1=(1/3)(x−1)","y+1=−(1/3)(x+1)","y−1=−(1/3)(x−1)"]','D','At x=1 the tangent gradient is 3, so the normal gradient is −1/3. The point is (1,1), giving y−1=−(1/3)(x−1).','Для y=x^3 какое уравнение задаёт нормаль при x=1?','["y−1=3(x−1)","y−1=(1/3)(x−1)","y+1=−(1/3)(x+1)","y−1=−(1/3)(x−1)"]','При x=1 градиент касательной равен 3, поэтому градиент нормали равен −1/3. Точка (1,1), следовательно y−1=−(1/3)(x−1).','y=x^3 uchun x=1 dagi normal tenglamasi qaysi?','["y−1=3(x−1)","y−1=(1/3)(x−1)","y+1=−(1/3)(x+1)","y−1=−(1/3)(x−1)"]','x=1 da urinma gradienti 3, demak normal gradienti −1/3. Nuqta (1,1), shuning uchun y−1=−(1/3)(x−1).',70),
('P1DIF04-R03','P1-DIF-04','retest','medium','input','For y=2x^2−x, the tangent at x=2 has equation y=7x+c. Enter c.','[]','-8','At x=2, y=6 and dy/dx=4x−1=7. Thus 6=14+c, so c=−8.','Для y=2x^2−x касательная при x=2 имеет уравнение y=7x+c. Введите c.','[]','При x=2 имеем y=6 и dy/dx=4x−1=7. Поэтому 6=14+c, значит c=−8.','y=2x^2−x uchun x=2 dagi urinma y=7x+c. c ni kiriting.','[]','x=2 da y=6 va dy/dx=4x−1=7. Demak 6=14+c, shuning uchun c=−8.',70),
('P1DIF04-R04','P1-DIF-04','retest','medium','mcq','For y=x^2, find the equation of the normal at x=−1.','["y=−2x−1","y=(1/2)x+3/2","y=2x+3","y=−(1/2)x+1/2"]','B','At x=−1 the point is (−1,1). The tangent gradient is −2, so the normal gradient is 1/2. Hence y−1=(1/2)(x+1), giving y=(1/2)x+3/2.','Для y=x^2 найдите уравнение нормали при x=−1.','["y=−2x−1","y=(1/2)x+3/2","y=2x+3","y=−(1/2)x+1/2"]','При x=−1 точка равна (−1,1). Градиент касательной −2, поэтому градиент нормали 1/2. Следовательно, y−1=(1/2)(x+1), то есть y=(1/2)x+3/2.','y=x^2 uchun x=−1 dagi normal tenglamasini toping.','["y=−2x−1","y=(1/2)x+3/2","y=2x+3","y=−(1/2)x+1/2"]','x=−1 da nuqta (−1,1). Urinma gradienti −2, demak normal gradienti 1/2. Shuning uchun y−1=(1/2)(x+1), ya’ni y=(1/2)x+3/2.',75),
('P1DIF04-M02','P1-DIF-04','mixed','hard','input','For y=x^3−6x, the tangent at x=√2 is horizontal and has equation y=c√2. Enter c.','[]','-4','At x=√2, y=(√2)^3−6√2=2√2−6√2=−4√2, so c=−4. Also dy/dx=3x^2−6=0 there, confirming the tangent is horizontal.','Для y=x^3−6x касательная при x=√2 горизонтальна и имеет уравнение y=c√2. Введите c.','[]','При x=√2: y=(√2)^3−6√2=2√2−6√2=−4√2, поэтому c=−4. Кроме того, dy/dx=3x^2−6=0, что подтверждает горизонтальность касательной.','y=x^3−6x uchun x=√2 dagi urinma gorizontal va y=c√2 tenglamaga ega. c ni kiriting.','[]','x=√2 da y=(√2)^3−6√2=2√2−6√2=−4√2, demak c=−4. Shuningdek, dy/dx=3x^2−6=0 bo‘lib, urinma gorizontal ekanini tasdiqlaydi.',80)
)
insert into public.questions(
 subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
 question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
 explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
)
select 5,
 case when s.skill_code like 'P1-SER-%' then 'P1 Series' else 'P1 Differentiation' end,
 s.skill_code,s.difficulty,s.qtype,s.q_en,s.opts_en,s.answer,s.exp_en,null,false,
 s.q_ru,s.q_uz,s.q_en,s.opts_ru,s.opts_uz,s.opts_en,s.exp_ru,s.exp_uz,s.exp_en,
 'ExamPrep:P1:p1_aw17_20_annual_reserve_topup_draft_v1:'||s.content_key,s.time_limit,null,'draft'
from src s
where not exists(
 select 1 from public.questions q
 where q.book_ref='ExamPrep:P1:p1_aw17_20_annual_reserve_topup_draft_v1:'||s.content_key
);

with src(content_key,skill_code,meta_id,official_ref,book_ref) as (values
('P1SER03-D02','P1-SER-03',59423,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER03-D03','P1-SER-03',59424,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER03-R03','P1-SER-03',59425,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER03-R04','P1-SER-03',59426,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER03-M02','P1-SER-03',59427,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER04-D02','P1-SER-04',59428,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER04-D03','P1-SER-04',59429,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER04-R03','P1-SER-04',59430,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER04-R04','P1-SER-04',59431,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER04-M02','P1-SER-04',59432,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER05-D02','P1-SER-05',59433,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER05-D03','P1-SER-05',59434,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER05-R03','P1-SER-05',59435,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER05-R04','P1-SER-05',59436,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1SER05-M02','P1-SER-05',59437,'Cambridge 9709 2026-2027 v4; P1 1.6 Series','Complete Pure Mathematics 1, Ch7 Series pp.120-133 (mapping only)'),
('P1DIF02-D02','P1-DIF-02',59438,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF02-D03','P1-DIF-02',59439,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF02-R03','P1-DIF-02',59440,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF02-R04','P1-DIF-02',59441,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF02-M02','P1-DIF-02',59442,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF03-D02','P1-DIF-03',59443,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF03-D03','P1-DIF-03',59444,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF03-R03','P1-DIF-03',59445,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF03-R04','P1-DIF-03',59446,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF03-M02','P1-DIF-03',59447,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8 Differentiation pp.138-153 (mapping only)'),
('P1DIF04-D02','P1-DIF-04',59448,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8-9 Differentiation pp.138-167 (mapping only)'),
('P1DIF04-D03','P1-DIF-04',59449,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8-9 Differentiation pp.138-167 (mapping only)'),
('P1DIF04-R03','P1-DIF-04',59450,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8-9 Differentiation pp.138-167 (mapping only)'),
('P1DIF04-R04','P1-DIF-04',59451,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8-9 Differentiation pp.138-167 (mapping only)'),
('P1DIF04-M02','P1-DIF-04',59452,'Cambridge 9709 2026-2027 v4; P1 1.7 Differentiation','Complete Pure Mathematics 1, Ch8-9 Differentiation pp.138-167 (mapping only)')
)
insert into private.exam_prep_question_content_meta(
 id,content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,
 exposure_state,lifecycle_state,originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
 copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5
)
overriding system value
select s.meta_id,4819,s.content_key,q.id,s.skill_code,'{}'::text[],
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
  on q.book_ref='ExamPrep:P1:p1_aw17_20_annual_reserve_topup_draft_v1:'||s.content_key
on conflict(id) do nothing;

do $postcheck$
declare v_bad int; v_a int; v_b int; v_c int; v_d int;
begin
  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=4819 and lifecycle_state='draft' and exposure_state='withheld')<>30
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4819 and reserve_role='diagnostic')<>12
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4819 and reserve_role='retest')<>12
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4819 and reserve_role='mixed')<>6
  then raise exception 'aw17_20_annual_reserve_p1_draft cardinality/state failed'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4819 and (
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
  if v_bad<>0 then raise exception 'aw17_20_annual_reserve_p1_draft payload/QA rows=%',v_bad; end if;

  select count(*) filter(where q.correct_answer='A'),count(*) filter(where q.correct_answer='B'),
         count(*) filter(where q.correct_answer='C'),count(*) filter(where q.correct_answer='D')
  into v_a,v_b,v_c,v_d
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4819 and m.reserve_role='diagnostic';
  if (v_a,v_b,v_c,v_d)<>(3,3,3,3) then
    raise exception 'aw17_20_annual_reserve_p1_draft diagnostic answer balance A=% B=% C=% D=%',v_a,v_b,v_c,v_d;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm on oldm.primary_skill_code=m.primary_skill_code and oldm.content_version_id<>4819
    join private.exam_prep_content_versions oldcv on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id=4819
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then raise exception 'aw17_20_annual_reserve_p1_draft exact published stem duplicate'; end if;

  if exists(select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id where a.content_version_id=4819)
     or exists(select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id where m.content_version_id=4819)
     or exists(select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id where m.content_version_id=4819)
  then raise exception 'aw17_20_annual_reserve_p1_draft unexpected history'; end if;
end
$postcheck$;

commit;
