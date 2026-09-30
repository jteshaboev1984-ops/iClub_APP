-- AW17-20 written-understanding checks draft v1.
-- One trilingual understanding check per new written learning task.
begin;
set local lock_timeout='3s';
set local statement_timeout='60s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_written_tasks
      where id between 15653 and 15663 and content_version_id in (4817,4818) and lifecycle_state='draft')<>11
  then raise exception 'aw17_20_written_checks expected 11 draft written tasks'; end if;

  if exists(select 1 from private.exam_prep_written_understanding_checks
            where id between 8953 and 8963 and written_task_id not between 15653 and 15663)
  then raise exception 'aw17_20_written_checks reserved id collision'; end if;
end
$preflight$;

insert into private.exam_prep_written_understanding_checks(
 id,written_task_id,check_order,check_version,check_kind,
 prompt_en,prompt_ru,prompt_uz,options_en,options_ru,options_uz,correct_index,
 rationale_en,rationale_ru,rationale_uz,lifecycle_state,qa_math_status,qa_language_status,qa_technical_status
)
overriding system value
values
(8953,15653,1,'aw18-v1','mcq',
'Why can subtracting two known arithmetic-progression terms be used to find the common difference?',
'Почему вычитание двух известных членов арифметической прогрессии позволяет найти разность?',
'Nega arifmetik progressiyaning ikki ma’lum hadini ayirish orqali umumiy ayirmani topish mumkin?',
'["The first term cancels and the remaining difference equals the gap in term numbers multiplied by d","Every arithmetic progression starts at zero","The two known terms must be consecutive","The sum formula always gives d directly"]'::jsonb,
'["Первый член сокращается, а оставшаяся разность равна разности номеров членов, умноженной на d","Любая арифметическая прогрессия начинается с нуля","Два известных члена обязательно должны быть соседними","Формула суммы всегда напрямую даёт d"]'::jsonb,
'["Birinchi had qisqaradi va qolgan ayirma had raqamlari farqining d ga ko‘paytmasiga teng bo‘ladi","Har bir arifmetik progressiya noldan boshlanadi","Ikki ma’lum had albatta ketma-ket bo‘lishi kerak","Yig‘indi formulasi d ni doim bevosita beradi"]'::jsonb,
0,
'Because u_n=a+(n−1)d, subtracting two terms removes a and leaves the difference in indices multiplied by d.',
'Так как u_n=a+(n−1)d, при вычитании двух членов a сокращается и остаётся разность индексов, умноженная на d.',
'u_n=a+(n−1)d bo‘lgani uchun ikki hadni ayirganda a qisqaradi va indekslar farqining d ga ko‘paytmasi qoladi.',
'draft','pending','pending','pending'),

(8954,15654,1,'aw18-v1','mcq',
'Why is dividing u5 by u2 useful when finding the ratio of a geometric progression?',
'Почему деление u5 на u2 удобно для нахождения знаменателя геометрической прогрессии?',
'Geometrik progressiya maxrajini topishda nega u5 ni u2 ga bo‘lish qulay?',
'["It changes a geometric progression into an arithmetic progression","The first term cancels and the quotient becomes r³","It always makes the quotient equal to r","It removes all powers of r"]'::jsonb,
'["Это превращает геометрическую прогрессию в арифметическую","Первый член сокращается, и отношение становится r³","Отношение всегда сразу равно r","Все степени r исчезают"]'::jsonb,
'["Bu geometrik progressiyani arifmetik progressiyaga aylantiradi","Birinchi had qisqaradi va nisbat r³ ga teng bo‘ladi","Nisbat har doim darhol r ga teng bo‘ladi","r ning barcha darajalari yo‘qoladi"]'::jsonb,
1,
'Since u5=ar⁴ and u2=ar, their quotient is r³. The unknown first term cancels.',
'Поскольку u5=ar⁴ и u2=ar, их отношение равно r³. Неизвестный первый член сокращается.',
'u5=ar⁴ va u2=ar bo‘lgani uchun ularning nisbati r³ ga teng. Noma’lum birinchi had qisqaradi.',
'draft','pending','pending','pending'),

(8955,15655,1,'aw18-v1','mcq',
'Which condition is the decisive test for whether a geometric series has a finite sum to infinity?',
'Какое условие является решающим для существования конечной суммы геометрического ряда до бесконечности?',
'Geometrik qatorning chekli cheksiz yig‘indisi mavjudligini qaysi shart hal qiladi?',
'["r must be positive","The first term must be greater than 1","|r| must be less than 1","r must be an integer"]'::jsonb,
'["r должен быть положительным","Первый член должен быть больше 1","|r| должно быть меньше 1","r должен быть целым числом"]'::jsonb,
'["r musbat bo‘lishi kerak","Birinchi had 1 dan katta bo‘lishi kerak","|r| 1 dan kichik bo‘lishi kerak","r butun son bo‘lishi kerak"]'::jsonb,
2,
'A geometric series converges to a finite sum exactly when the magnitude of the common ratio is less than 1.',
'Геометрический ряд имеет конечную сумму до бесконечности именно при |r|<1.',
'Geometrik qatorning chekli cheksiz yig‘indisi aynan |r|<1 bo‘lganda mavjud bo‘ladi.',
'draft','pending','pending','pending'),

(8956,15656,1,'aw18-v1','mcq',
'What happens to the exponent when differentiating x^n by the power rule?',
'Что происходит с показателем степени при дифференцировании x^n по правилу степени?',
'x^n ni daraja qoidasi bilan differensiallaganda daraja bilan nima sodir bo‘ladi?',
'["It stays unchanged","It is squared","It is increased by 1","The old exponent becomes a multiplier and the new exponent is n−1"]'::jsonb,
'["Он не меняется","Он возводится в квадрат","Он увеличивается на 1","Старый показатель становится множителем, а новый показатель равен n−1"]'::jsonb,
'["U o‘zgarmaydi","U kvadratga oshiriladi","U 1 ga oshiriladi","Eski daraja ko‘paytiruvchi bo‘ladi, yangi daraja esa n−1"]'::jsonb,
3,
'The power rule is d(x^n)/dx=nx^(n−1), including the rational and negative exponents used here.',
'Правило степени имеет вид d(x^n)/dx=nx^(n−1), в том числе для используемых здесь рациональных и отрицательных показателей.',
'Daraja qoidasi d(x^n)/dx=nx^(n−1) ko‘rinishida bo‘lib, bu yerda ishlatiladigan ratsional va manfiy darajalar uchun ham amal qiladi.',
'draft','pending','pending','pending'),

(8957,15657,1,'aw18-v1','mcq',
'Why does differentiating (ax+b)^n require an extra factor a?',
'Почему при дифференцировании (ax+b)^n появляется дополнительный множитель a?',
'Nega (ax+b)^n ni differensiallaganda qo‘shimcha a ko‘paytuvchisi paydo bo‘ladi?',
'["The chain rule multiplies the outer derivative by the derivative of the inner expression ax+b","Because a is always the exponent","Because b differentiates to a","Because every composite function has derivative 1"]'::jsonb,
'["По правилу цепочки производная внешней функции умножается на производную внутреннего выражения ax+b","Потому что a всегда является показателем степени","Потому что производная b равна a","Потому что производная любой сложной функции равна 1"]'::jsonb,
'["Zanjir qoidasida tashqi funksiya hosilasi ichki ax+b ifodaning hosilasiga ko‘paytiriladi","Chunki a har doim daraja ko‘rsatkichi","Chunki b ning hosilasi a ga teng","Chunki har bir murakkab funksiyaning hosilasi 1"]'::jsonb,
0,
'The inner derivative is d(ax+b)/dx=a, so the chain rule contributes that factor.',
'Производная внутреннего выражения d(ax+b)/dx=a, поэтому правило цепочки даёт этот множитель.',
'Ichki ifodaning hosilasi d(ax+b)/dx=a, shuning uchun zanjir qoidasi shu ko‘paytuvchini beradi.',
'draft','pending','pending','pending'),

(8958,15658,1,'aw18-v1','mcq',
'If a tangent has non-zero gradient m, why is the normal gradient −1/m?',
'Если касательная имеет ненулевой градиент m, почему градиент нормали равен −1/m?',
'Agar urinmaning nol bo‘lmagan gradienti m bo‘lsa, nega normal gradienti −1/m ga teng?',
'["Because tangent and normal gradients must be equal","Because perpendicular non-vertical lines have gradients whose product is −1","Because the normal always has gradient −1","Because the normal passes through the origin"]'::jsonb,
'["Потому что градиенты касательной и нормали должны быть равны","Потому что у перпендикулярных невертикальных прямых произведение градиентов равно −1","Потому что градиент нормали всегда равен −1","Потому что нормаль проходит через начало координат"]'::jsonb,
'["Chunki urinma va normal gradientlari teng bo‘lishi kerak","Chunki o‘zaro perpendikulyar, vertikal bo‘lmagan chiziqlar gradientlari ko‘paytmasi −1 ga teng","Chunki normal gradienti har doim −1","Chunki normal koordinata boshidan o‘tadi"]'::jsonb,
1,
'For perpendicular non-vertical lines, m1m2=−1. Therefore the normal gradient is the negative reciprocal of the tangent gradient.',
'Для перпендикулярных невертикальных прямых m1m2=−1. Поэтому градиент нормали — отрицательная обратная величина градиента касательной.',
'Perpendikulyar, vertikal bo‘lmagan chiziqlar uchun m1m2=−1. Demak normal gradienti urinma gradientining manfiy teskari qiymati.',
'draft','pending','pending','pending'),

(8959,15659,1,'aw18-v1','mcq',
'Why is a complement efficient for finding P(X≤8) when X~B(10,p)?',
'Почему дополнение удобно для нахождения P(X≤8), если X~B(10,p)?',
'X~B(10,p) bo‘lganda P(X≤8) ni topishda nega to‘ldiruvchi hodisa qulay?',
'["Because P(X≤8)=P(X=8)","Because binomial probabilities cannot be added","Because the complement has only X=9 and X=10, so fewer terms are needed","Because complements change p to 1−p"]'::jsonb,
'["Потому что P(X≤8)=P(X=8)","Потому что биномиальные вероятности нельзя складывать","Потому что дополнение содержит только X=9 и X=10, поэтому нужно меньше членов","Потому что дополнение заменяет p на 1−p"]'::jsonb,
'["Chunki P(X≤8)=P(X=8)","Chunki binomial ehtimollarni qo‘shib bo‘lmaydi","Chunki to‘ldiruvchi hodisada faqat X=9 va X=10 bor, shuning uchun kamroq had kerak","Chunki to‘ldiruvchi hodisa p ni 1−p ga almashtiradi"]'::jsonb,
2,
'P(X≤8)=1−P(X≥9), and the excluded tail contains only the two terms X=9 and X=10.',
'P(X≤8)=1−P(X≥9), а исключаемый хвост содержит только два члена: X=9 и X=10.',
'P(X≤8)=1−P(X≥9), chiqarib tashlanadigan dumda esa faqat X=9 va X=10 hadlari bor.',
'draft','pending','pending','pending'),

(8960,15660,1,'aw18-v1','mcq',
'For X~B(n,p), why does Var(X)/E(X) equal 1−p?',
'Для X~B(n,p) почему Var(X)/E(X) равно 1−p?',
'X~B(n,p) uchun nega Var(X)/E(X) 1−p ga teng?',
'["Because Var(X)=n+p","Because E(X)=1−p","Because n must equal 1","Because Var(X)=np(1−p) and E(X)=np, so np cancels"]'::jsonb,
'["Потому что Var(X)=n+p","Потому что E(X)=1−p","Потому что n обязательно равно 1","Потому что Var(X)=np(1−p), а E(X)=np, поэтому np сокращается"]'::jsonb,
'["Chunki Var(X)=n+p","Chunki E(X)=1−p","Chunki n albatta 1 ga teng","Chunki Var(X)=np(1−p) va E(X)=np, shuning uchun np qisqaradi"]'::jsonb,
3,
'Dividing np(1−p) by np leaves 1−p, provided the binomial model has a non-zero mean.',
'np(1−p) делится на np, и остаётся 1−p, если среднее биномиальной величины ненулевое.',
'np(1−p) ni np ga bo‘lganda 1−p qoladi, agar binomial kattalikning o‘rtachasi nol bo‘lmasa.',
'draft','pending','pending','pending'),

(8961,15661,1,'aw18-v1','mcq',
'For a geometric trial-number variable, why is P(X>k)=(1−p)^k?',
'Для геометрической величины, считающей номер испытания, почему P(X>k)=(1−p)^k?',
'Sinov raqamini sanaydigan geometrik kattalik uchun nega P(X>k)=(1−p)^k?',
'["X>k means the first k trials must all be failures","X>k means exactly k successes occur","The kth trial must be a success","The probability is always p^k"]'::jsonb,
'["X>k означает, что первые k испытаний должны быть неудачными","X>k означает ровно k успехов","k-е испытание обязательно должно быть успешным","Вероятность всегда равна p^k"]'::jsonb,
'["X>k dastlabki k ta sinovning barchasi muvaffaqiyatsiz bo‘lishini anglatadi","X>k aynan k ta muvaffaqiyat bo‘lishini anglatadi","k-sinov albatta muvaffaqiyatli bo‘lishi kerak","Ehtimol har doim p^k ga teng"]'::jsonb,
0,
'To wait beyond trial k, no success can occur in the first k independent trials. Each failure has probability 1−p.',
'Чтобы ждать дольше k-го испытания, в первых k независимых испытаниях не должно быть успеха. Вероятность каждой неудачи равна 1−p.',
'k-sinovdan keyin ham kutish uchun dastlabki k ta mustaqil sinovning birortasida muvaffaqiyat bo‘lmasligi kerak. Har bir muvaffaqiyatsizlik ehtimoli 1−p.',
'draft','pending','pending','pending'),

(8962,15662,1,'aw18-v1','mcq',
'What does E(X)=4 mean for a geometric trial-number variable?',
'Что означает E(X)=4 для геометрической величины, считающей номер испытания?',
'Sinov raqamini sanaydigan geometrik kattalik uchun E(X)=4 nimani anglatadi?',
'["The first success always occurs on trial 4","Across many repeated experiments, the average trial number of the first success tends toward 4","Exactly four failures occur before every success","The probability of success is 4"]'::jsonb,
'["Первый успех всегда происходит в 4-м испытании","При большом числе повторений средний номер испытания первого успеха стремится к 4","Перед каждым успехом происходит ровно четыре неудачи","Вероятность успеха равна 4"]'::jsonb,
'["Birinchi muvaffaqiyat har doim 4-sinovda sodir bo‘ladi","Ko‘p takroriy tajribalarda birinchi muvaffaqiyatning o‘rtacha sinov raqami 4 ga yaqinlashadi","Har bir muvaffaqiyatdan oldin aynan to‘rtta muvaffaqiyatsizlik bo‘ladi","Muvaffaqiyat ehtimoli 4 ga teng"]'::jsonb,
1,
'Expectation is a long-run average, not a guarantee for any one run of the experiment.',
'Математическое ожидание — это долгосрочное среднее, а не гарантия для одного конкретного эксперимента.',
'Kutilma uzoq muddatli o‘rtacha bo‘lib, bitta tajriba uchun kafolat emas.',
'draft','pending','pending','pending'),

(8963,15663,1,'aw18-v1','mcq',
'In the notation X~N(μ,σ²), what does the second parameter represent?',
'В записи X~N(μ,σ²) что означает второй параметр?',
'X~N(μ,σ²) yozuvida ikkinchi parametr nimani bildiradi?',
'["The standard deviation σ","The median only","The variance σ²","The total area under half of the curve"]'::jsonb,
'["Стандартное отклонение σ","Только медиану","Дисперсию σ²","Площадь под половиной кривой"]'::jsonb,
'["Standart og‘ish σ","Faqat medianani","Dispersiya σ²","Egri chiziqning yarmi ostidagi umumiy yuza"]'::jsonb,
2,
'The standard normal notation used here stores the variance as the second parameter; the standard deviation is its positive square root.',
'В используемой записи нормального распределения вторым параметром является дисперсия; стандартное отклонение — её положительный квадратный корень.',
'Bu normal taqsimot yozuvida ikkinchi parametr dispersiya; standart og‘ish esa uning musbat kvadrat ildizi.',
'draft','pending','pending','pending')
on conflict(id) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_written_understanding_checks
      where id between 8953 and 8963 and written_task_id between 15653 and 15663
        and lifecycle_state='draft' and qa_math_status='pending' and qa_language_status='pending' and qa_technical_status='pending')<>11
  then raise exception 'aw17_20_written_checks cardinality/state mismatch'; end if;

  select count(*) into v_bad from private.exam_prep_written_understanding_checks c
  where c.id between 8953 and 8963 and (
    jsonb_array_length(c.options_en)<>4 or jsonb_array_length(c.options_ru)<>4 or jsonb_array_length(c.options_uz)<>4
    or c.correct_index not between 0 and 3
    or nullif(btrim(c.prompt_en),'') is null or nullif(btrim(c.prompt_ru),'') is null or nullif(btrim(c.prompt_uz),'') is null
    or nullif(btrim(c.rationale_en),'') is null or nullif(btrim(c.rationale_ru),'') is null or nullif(btrim(c.rationale_uz),'') is null
  );
  if v_bad<>0 then raise exception 'aw17_20_written_checks structural/trilingual invalid=%',v_bad; end if;

  if (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=0)<>3
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=1)<>3
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=2)<>3
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8953 and 8963 and correct_index=3)<>2
  then raise exception 'aw17_20_written_checks answer-position balance drift'; end if;
end
$postcheck$;

commit;
