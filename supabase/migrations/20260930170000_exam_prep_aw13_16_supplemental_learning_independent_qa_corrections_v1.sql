-- AW13-16 supplemental learning independent QA corrections v1.
-- Draft/history-free content only. No publication or learner exposure.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_content_versions
      where id in (4813,4814) and status='draft')<>2 then
    raise exception 'aw13_16 independent QA: target draft versions missing';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id=4813)<>24
     or (select count(*) from private.exam_prep_question_content_meta where content_version_id=4814)<>21
     or (select count(*) from private.exam_prep_written_tasks where content_version_id in (4813,4814))<>15
     or (select count(*) from private.exam_prep_written_understanding_checks c
         join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
         where wt.content_version_id in (4813,4814))<>15 then
    raise exception 'aw13_16 independent QA: candidate surface mismatch';
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4813,4814)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4813,4814)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4813,4814)
  ) then
    raise exception 'aw13_16 independent QA: draft has learner/legacy history';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4813,4814)
    and (m.lifecycle_state<>'draft' or m.exposure_state<>'withheld' or q.is_active or q.quality_status<>'draft');
  if v_bad<>0 then
    raise exception 'aw13_16 independent QA: draft exposure drift rows=%',v_bad;
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4813,4814)
        and content_key in ('P1CIR03-A02','P1TRI03-A02','P1TRI05-A01','P1SER01-A02','P1SER02-A03','P1DIF01-A01','P1DIF01-A03','P5PRO06-A01','P5BIN01-A02','P5GEO01-A02'))<>10 then
    raise exception 'aw13_16 independent QA: correction targets missing';
  end if;
end
$preflight$;

with fixes(content_key,q_en,opts_en,answer,exp_en,q_ru,opts_ru,exp_ru,q_uz,opts_uz,exp_uz) as (values
('P1CIR03-A02','An annular sector has outer radius 8 cm, inner radius 4 cm and area 36 cm². Find its angle in radians.','["1.2","1.5","2","3"]','B','The annular-sector area is 1/2(8²−4²)θ=24θ. Hence 24θ=36 and θ=1.5 radians.','Кольцевой сектор имеет внешний радиус 8 см, внутренний радиус 4 см и площадь 36 см². Найдите его угол в радианах.','["1,2","1,5","2","3"]','Площадь кольцевого сектора равна 1/2(8²−4²)θ=24θ. Поэтому 24θ=36 и θ=1,5 радиана.','Halqasimon sektorning tashqi radiusi 8 cm, ichki radiusi 4 cm va yuzi 36 cm². Uning burchagini radianlarda toping.','["1.2","1.5","2","3"]','Halqasimon sektor yuzi 1/2(8²−4²)θ=24θ. Demak 24θ=36 va θ=1.5 radian.'),
('P1TRI03-A02','A calculator gives cos⁻¹(−0.2)≈101.5° in degree mode. Why is 101.5° the principal value rather than 258.5°?','["Because cosine is positive at 101.5°","Because cos⁻¹ returns values in the principal range 0°≤θ≤180°","Because inverse cosine can return only acute angles","Because 258.5° is outside 0°≤θ≤360°"]','B','The inverse cosine function is defined using the principal range 0°≤θ≤180°. Although another angle may have the same cosine, cos⁻¹ returns the value in this range.','Калькулятор в градусном режиме даёт cos⁻¹(−0,2)≈101,5°. Почему 101,5° является главным значением, а не 258,5°?','["Потому что cos101,5° положителен","Потому что cos⁻¹ возвращает значения из главного диапазона 0°≤θ≤180°","Потому что arccos может возвращать только острые углы","Потому что 258,5° не входит в 0°≤θ≤360°"]','Обратный косинус определяется на главном диапазоне 0°≤θ≤180°. Хотя другой угол может иметь тот же косинус, cos⁻¹ возвращает значение именно из этого диапазона.','Kalkulyator gradus rejimida cos⁻¹(−0.2)≈101.5° ni beradi. Nega 101.5° bosh qiymat, 258.5° esa emas?','["Chunki cos101.5° musbat","Chunki cos⁻¹ bosh 0°≤θ≤180° oraliqdagi qiymatni qaytaradi","Chunki teskari kosinus faqat o‘tkir burchaklarni qaytaradi","Chunki 258.5° 0°≤θ≤360° oraliqda emas"]','Teskari kosinus funksiyasi 0°≤θ≤180° bosh oraliqda aniqlanadi. Boshqa burchak ham shu kosinusga ega bo‘lishi mumkin, lekin cos⁻¹ aynan shu oraliqdagi qiymatni qaytaradi.'),
('P1TRI05-A01','A vertical coordinate is modelled by y=3+6sinθ. Find all θ for which y=0 on 0°≤θ<360°.','["210°, 330°","30°, 150°","150°, 210°","30°, 330°"]','A','Setting y=0 gives 3+6sinθ=0, so sinθ=−1/2. The reference angle is 30°, and sine is negative in quadrants III and IV, giving 210° and 330°.','Вертикальная координата задаётся моделью y=3+6sinθ. Найдите все θ, для которых y=0 при 0°≤θ<360°.','["210°, 330°","30°, 150°","150°, 210°","30°, 330°"]','Из y=0 получаем 3+6sinθ=0, то есть sinθ=−1/2. Опорный угол 30°, синус отрицателен в III и IV четвертях, поэтому θ=210° и 330°.','Vertikal koordinata y=3+6sinθ bilan modellashtirilgan. 0°≤θ<360° da y=0 bo‘ladigan barcha θ larni toping.','["210°, 330°","30°, 150°","150°, 210°","30°, 330°"]','y=0 dan 3+6sinθ=0, ya’ni sinθ=−1/2. Tayanch burchak 30°, sinus III va IV choraklarda manfiy, demak θ=210° va 330°.'),
('P1SER01-A02','Find the coefficient of x² in (1−2x)³(1+x).','["−18","−6","12","6"]','D','(1−2x)³=1−6x+12x²−8x³. In the product with (1+x), the x² coefficient is 12+(−6)=6.','Найдите коэффициент при x² в произведении (1−2x)³(1+x).','["−18","−6","12","6"]','(1−2x)³=1−6x+12x²−8x³. В произведении с (1+x) коэффициент при x² равен 12+(−6)=6.','(1−2x)³(1+x) ko‘paytmada x² oldidagi koeffitsiyentni toping.','["−18","−6","12","6"]','(1−2x)³=1−6x+12x²−8x³. (1+x) bilan ko‘paytmada x² koeffitsiyenti 12+(−6)=6.'),
('P1SER02-A03','The first three terms of an arithmetic progression are 4, k and 18. Enter k.','[]','11','For an arithmetic progression the consecutive differences are equal: k−4=18−k. Thus 2k=22 and k=11.','Первые три члена арифметической прогрессии равны 4, k и 18. Введите k.','[]','В арифметической прогрессии соседние разности равны: k−4=18−k. Поэтому 2k=22 и k=11.','Arifmetik progressiyaning dastlabki uch hadi 4, k va 18. k ni kiriting.','[]','Arifmetik progressiyada ketma-ket ayirmalar teng: k−4=18−k. Demak 2k=22 va k=11.'),
('P1DIF01-A01','For a curve, the secant gradient from x=1 to x=1+h is 5.1 when h=0.1, 5.01 when h=0.01 and 4.99 when h=−0.01. What tangent gradient at x=1 is suggested by these values?','["4.9","4.99","5","5.1"]','C','As h approaches 0 from both sides, the secant gradients approach 5. The derivative, or tangent gradient, is therefore 5.','Для кривой градиент секущей от x=1 до x=1+h равен 5,1 при h=0,1; 5,01 при h=0,01 и 4,99 при h=−0,01. Какой градиент касательной при x=1 показывают эти значения?','["4,9","4,99","5","5,1"]','Когда h стремится к 0 с обеих сторон, градиенты секущих стремятся к 5. Поэтому производная, то есть градиент касательной, равна 5.','Egri chiziq uchun x=1 dan x=1+h gacha kesuvchi gradienti h=0.1 da 5.1, h=0.01 da 5.01 va h=−0.01 da 4.99. Bu qiymatlar x=1 dagi urinma gradienti uchun qaysi qiymatni ko‘rsatadi?','["4.9","4.99","5","5.1"]','h ikki tomondan 0 ga yaqinlashganda kesuvchi gradientlari 5 ga yaqinlashadi. Demak hosila, ya’ni urinma gradienti 5.'),
('P1DIF01-A03','For f(x)=x³, the average gradient from x=2 to x=2+h simplifies to 12+6h+h². Enter the tangent gradient at x=2.','[]','12','The tangent gradient is the limit of the average gradient as h→0. Therefore 12+6h+h²→12.','Для f(x)=x³ средний градиент от x=2 до x=2+h упрощается до 12+6h+h². Введите градиент касательной при x=2.','[]','Градиент касательной — это предел среднего градиента при h→0. Поэтому 12+6h+h²→12.','f(x)=x³ uchun x=2 dan x=2+h gacha o‘rtacha gradient 12+6h+h² ga soddalashadi. x=2 dagi urinma gradientini kiriting.','[]','Urinma gradienti h→0 dagi o‘rtacha gradient limitidir. Shuning uchun 12+6h+h²→12.'),
('P5PRO06-A01','Five applicants are qualified and three are not. Two applicants are selected at random without replacement. Find the probability that the first selected applicant is qualified and the second is not qualified.','["5/21","3/14","15/56","5/8"]','C','The first selection is qualified with probability 5/8. Then 7 applicants remain, including 3 not qualified, so the required probability is 5/8×3/7=15/56.','Пять кандидатов соответствуют требованиям, а трое — нет. Случайно без возвращения выбирают двух кандидатов. Найдите вероятность того, что первый выбранный кандидат соответствует требованиям, а второй — нет.','["5/21","3/14","15/56","5/8"]','Вероятность выбрать подходящего кандидата первым равна 5/8. Затем остаются 7 кандидатов, из них 3 неподходящих, поэтому искомая вероятность равна 5/8×3/7=15/56.','Beshta nomzod talablarga mos, uchtasi mos emas. Ikki nomzod qaytarmasdan tasodifiy tanlanadi. Birinchi tanlangan nomzod mos, ikkinchisi mos emas bo‘lish ehtimolini toping.','["5/21","3/14","15/56","5/8"]','Birinchi bo‘lib mos nomzod tanlanish ehtimoli 5/8. Keyin 7 nomzod qoladi, ulardan 3 tasi mos emas. Demak ehtimol 5/8×3/7=15/56.'),
('P5BIN01-A02','Six items are inspected. After each defective item is found, the machine is adjusted so the probability of a defect changes for later items. X is the number of defective items. Which binomial condition is not satisfied?','["The number of trials is fixed","There are two outcomes for each item","X counts the number of defects","The success probability is constant from trial to trial"]','D','The number of inspections is fixed and each item is defect/not defect, but the adjustment changes the defect probability. Therefore the constant-p condition for an exact binomial model fails.','Проверяют шесть изделий. После обнаружения каждого дефектного изделия станок регулируют, поэтому вероятность дефекта для следующих изделий меняется. X — число дефектных изделий. Какое условие биномиальной модели не выполняется?','["Число испытаний фиксировано","Для каждого изделия есть два исхода","X считает число дефектов","Вероятность успеха постоянна от испытания к испытанию"]','Число проверок фиксировано и каждое изделие либо дефектно, либо нет, но регулировка меняет вероятность дефекта. Поэтому условие постоянного p для точной биномиальной модели нарушается.','Oltita buyum tekshiriladi. Har bir nuqsonli buyum topilgach, uskuna sozlanadi va keyingi buyumlar uchun nuqson ehtimoli o‘zgaradi. X — nuqsonli buyumlar soni. Binomial modelning qaysi sharti bajarilmaydi?','["Sinovlar soni belgilangan","Har bir buyum uchun ikki natija bor","X nuqsonlar sonini sanaydi","Muvaffaqiyat ehtimoli sinovdan sinovga o‘zgarmas"]','Tekshiruvlar soni belgilangan va har bir buyum nuqsonli yoki nuqsonsiz, lekin sozlash nuqson ehtimolini o‘zgartiradi. Shuning uchun aniq binomial model uchun o‘zgarmas p sharti bajarilmaydi.'),
('P5GEO01-A02','Which situation is not modelled exactly by an ordinary geometric distribution?','["Independent coin tosses continue until the first head","After each missed shot, a player adjusts technique so the probability of scoring changes before the next shot","Independent shots with constant scoring probability continue until the first score","Independent items with constant defect probability are inspected until the first defective item"]','B','An ordinary geometric model requires the same success probability on every independent trial. If the scoring probability changes after a miss, the constant-p condition fails.','Какая ситуация не моделируется точно обычным геометрическим распределением?','["Независимые броски монеты продолжаются до первого орла","После каждого промаха игрок меняет технику, поэтому вероятность попадания перед следующим броском изменяется","Независимые броски с постоянной вероятностью попадания продолжаются до первого попадания","Независимые изделия с постоянной вероятностью дефекта проверяют до первого дефектного изделия"]','Обычная геометрическая модель требует одинаковой вероятности успеха в каждом независимом испытании. Если вероятность попадания меняется после промаха, условие постоянного p нарушается.','Qaysi vaziyat oddiy geometrik taqsimot bilan aniq modellashtirilmaydi?','["Mustaqil tanga tashlash birinchi gerbgacha davom etadi","Har bir muvaffaqiyatsiz zarbadan keyin o‘yinchi texnikasini o‘zgartiradi, shuning uchun keyingi zarba oldidan muvaffaqiyat ehtimoli o‘zgaradi","O‘zgarmas muvaffaqiyat ehtimolli mustaqil zarbalar birinchi muvaffaqiyatgacha davom etadi","O‘zgarmas nuqson ehtimolli mustaqil buyumlar birinchi nuqsonli buyumgacha tekshiriladi"]','Oddiy geometrik model har bir mustaqil sinovda bir xil muvaffaqiyat ehtimolini talab qiladi. Muvaffaqiyatsiz zarbadan keyin ehtimol o‘zgarsa, o‘zgarmas p sharti bajarilmaydi.')
)
update public.questions q
set question_text=f.q_en,
    question_text_en=f.q_en,
    question_text_ru=f.q_ru,
    question_text_uz=f.q_uz,
    options_text=f.opts_en,
    options_text_en=f.opts_en,
    options_text_ru=f.opts_ru,
    options_text_uz=f.opts_uz,
    correct_answer=f.answer,
    explanation=f.exp_en,
    explanation_en=f.exp_en,
    explanation_ru=f.exp_ru,
    explanation_uz=f.exp_uz
from fixes f
join private.exam_prep_question_content_meta m
  on m.content_version_id in (4813,4814)
 and m.content_key=f.content_key
where q.id=m.question_id
  and q.is_active=false
  and q.quality_status='draft';

update private.exam_prep_question_content_meta m
set question_snapshot_md5=md5(concat_ws(chr(31),
      q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
      coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
      coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
      coalesce(q.quality_flag,''),coalesce(q.quality_status,''))),
    updated_at=now()
from public.questions q
where q.id=m.question_id
  and m.content_version_id in (4813,4814)
  and m.content_key in ('P1CIR03-A02','P1TRI03-A02','P1TRI05-A01','P1SER01-A02','P1SER02-A03','P1DIF01-A01','P1DIF01-A03','P5PRO06-A01','P5BIN01-A02','P5GEO01-A02');

do $postcheck$
declare
  v_bad int;
  v_a int; v_b int; v_c int; v_d int; v_inputs int;
begin
  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4813,4814)
    and q.qtype='mcq'
    and (
      q.correct_answer not in ('A','B','C','D')
      or jsonb_array_length(q.options_text_en::jsonb)<>4
      or jsonb_array_length(q.options_text_ru::jsonb)<>4
      or jsonb_array_length(q.options_text_uz::jsonb)<>4
      or (select count(distinct v) from jsonb_array_elements_text(q.options_text_en::jsonb) z(v))<>4
      or (select count(distinct v) from jsonb_array_elements_text(q.options_text_ru::jsonb) z(v))<>4
      or (select count(distinct v) from jsonb_array_elements_text(q.options_text_uz::jsonb) z(v))<>4
    );
  if v_bad<>0 then raise exception 'aw13_16 independent QA: invalid MCQ rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4813,4814)
    and (
      nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
    );
  if v_bad<>0 then raise exception 'aw13_16 independent QA: trilingual surface incomplete rows=%',v_bad; end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4813;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,4,4,8) then
    raise exception 'aw13_16 independent QA: P1 answer balance mismatch A=% B=% C=% D=% input=%',
      v_a,v_b,v_c,v_d,v_inputs;
  end if;

  select
    count(*) filter(where q.correct_answer='A'),
    count(*) filter(where q.correct_answer='B'),
    count(*) filter(where q.correct_answer='C'),
    count(*) filter(where q.correct_answer='D'),
    count(*) filter(where q.qtype='input')
  into v_a,v_b,v_c,v_d,v_inputs
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=4814;
  if (v_a,v_b,v_c,v_d,v_inputs)<>(4,4,3,3,7) then
    raise exception 'aw13_16 independent QA: P5 answer balance mismatch A=% B=% C=% D=% input=%',
      v_a,v_b,v_c,v_d,v_inputs;
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    join private.exam_prep_question_content_meta oldm
      on oldm.primary_skill_code=m.primary_skill_code
     and oldm.content_version_id<>m.content_version_id
    join private.exam_prep_content_versions oldcv
      on oldcv.id=oldm.content_version_id and oldcv.status='published'
    join public.questions oldq on oldq.id=oldm.question_id
    where m.content_version_id in (4813,4814)
      and lower(regexp_replace(q.question_text_en,'\s+',' ','g'))=
          lower(regexp_replace(oldq.question_text_en,'\s+',' ','g'))
  ) then
    raise exception 'aw13_16 independent QA: exact published stem duplicate';
  end if;

  -- Pin the corrected transfer/originality surface.
  if not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4813 and m.content_key='P1DIF01-A01'
      and q.question_text_en like '%secant gradient%' and q.correct_answer='C'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4813 and m.content_key='P1SER01-A02'
      and q.question_text_en like '%(1−2x)³(1+x)%' and q.correct_answer='D'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4814 and m.content_key='P5BIN01-A02'
      and q.question_text_en like '%machine is adjusted%' and q.correct_answer='D'
  ) or not exists(
    select 1 from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
    where m.content_version_id=4814 and m.content_key='P5GEO01-A02'
      and q.question_text_en like '%probability of scoring changes%' and q.correct_answer='B'
  ) then
    raise exception 'aw13_16 independent QA: corrected transfer surface missing';
  end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions q on q.id=m.question_id
  where m.content_version_id in (4813,4814)
    and md5(concat_ws(chr(31),
      q.id::text,q.subject_id::text,coalesce(q.topic,''),coalesce(q.subtopic,''),
      coalesce(q.difficulty,''),coalesce(q.qtype,''),coalesce(q.question_text,''),
      coalesce(q.options_text,''),coalesce(q.correct_answer,''),coalesce(q.explanation,''),
      coalesce(q.image_url,''),coalesce(q.is_active::text,''),
      coalesce(q.question_text_ru,''),coalesce(q.question_text_uz,''),coalesce(q.question_text_en,''),
      coalesce(q.options_text_ru,''),coalesce(q.options_text_uz,''),coalesce(q.options_text_en,''),
      coalesce(q.explanation_ru,''),coalesce(q.explanation_uz,''),coalesce(q.explanation_en,''),
      coalesce(q.book_ref,''),coalesce(q.time_limit_sec::text,''),
      coalesce(q.quality_flag,''),coalesce(q.quality_status,'')))<>m.question_snapshot_md5;
  if v_bad<>0 then raise exception 'aw13_16 independent QA: frozen snapshot mismatch rows=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4813,4814)
  ) or exists(
    select 1 from public.practice_answers pa
    join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4813,4814)
  ) or exists(
    select 1 from public.tour_answers ta
    join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4813,4814)
  ) then
    raise exception 'aw13_16 independent QA: history appeared during correction';
  end if;
end
$postcheck$;

commit;
