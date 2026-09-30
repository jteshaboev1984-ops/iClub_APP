-- AW17-20 annual-reserve diagnostic misconception rules draft v1.
-- DRAFT ONLY. Exactly three wrong-option rules per diagnostic item.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4819,4820) and lifecycle_state='draft' and reserve_role='diagnostic')<>22
  then raise exception 'aw17_20_annual_reserve_rules: diagnostic draft surface missing'; end if;
end
$preflight$;

with skill_feedback(skill_code,mistake_type,feedback_en,feedback_ru,feedback_uz,next_en,next_ru,next_uz) as (values
('P1-SER-03','arithmetic_progression','Your choice does not match the arithmetic-progression nth-term or finite-sum relationship.','Выбранный вариант не соответствует формуле n-го члена или конечной суммы арифметической прогрессии.','Tanlangan javob arifmetik progressiyaning n-hadi yoki chekli yig‘indisi munosabatiga mos emas.','Use un=a+(n−1)d and Sn=n/2[2a+(n−1)d]. For inverse problems, subtract two term equations first if that removes a.','Используйте un=a+(n−1)d и Sn=n/2[2a+(n−1)d]. В обратных задачах сначала вычтите два уравнения для членов, если это устраняет a.','un=a+(n−1)d va Sn=n/2[2a+(n−1)d] formulalaridan foydalaning. Teskari masalalarda a qisqarsa, avval ikki had tenglamasini ayiring.'),
('P1-SER-04','geometric_progression','Your choice does not match the geometric-progression power or finite-sum structure.','Выбранный вариант не соответствует степенной структуре или формуле конечной суммы геометрической прогрессии.','Tanlangan javob geometrik progressiyaning darajali tuzilmasi yoki chekli yig‘indi formulasiga mos emas.','Use un=ar^(n−1). Ratios of two known terms can remove a; use Sn=a(1−r^n)/(1−r) or its equivalent form for r≠1.','Используйте un=ar^(n−1). Отношение двух известных членов может устранить a; для r≠1 используйте Sn=a(1−r^n)/(1−r) или эквивалентную форму.','un=ar^(n−1) dan foydalaning. Ikki ma’lum had nisbati a ni qisqartirishi mumkin; r≠1 uchun Sn=a(1−r^n)/(1−r) yoki teng kuchli formuladan foydalaning.'),
('P1-SER-05','convergence','Your choice ignores the convergence condition or uses the finite-sum formula instead of the sum to infinity.','Выбранный вариант игнорирует условие сходимости или использует формулу конечной суммы вместо суммы до бесконечности.','Tanlangan javob yaqinlashish shartini e’tibordan chetda qoldiradi yoki cheksiz yig‘indi o‘rniga chekli yig‘indi formulasidan foydalanadi.','Check |r|<1 first. Only then use S∞=a/(1−r). For a remaining tail, identify its first term before applying the same formula.','Сначала проверьте |r|<1. Только затем используйте S∞=a/(1−r). Для оставшегося хвоста сначала найдите его первый член.','Avval |r|<1 ni tekshiring. Shundan keyingina S∞=a/(1−r) dan foydalaning. Qolgan dum uchun formulani qo‘llashdan oldin uning birinchi hadini toping.'),
('P1-DIF-02','power_rule','Your choice applies the power rule incorrectly to a rational or negative exponent.','Выбранный вариант неверно применяет правило степени к рациональному или отрицательному показателю.','Tanlangan javob ratsional yoki manfiy darajaga daraja qoidasini noto‘g‘ri qo‘llaydi.','For each term kx^n, multiply by n and reduce the exponent by 1: d(kx^n)/dx=knx^(n−1). Keep signs and fractional exponents exact.','Для каждого члена kx^n умножьте на n и уменьшите показатель на 1: d(kx^n)/dx=knx^(n−1). Сохраняйте знаки и дробные показатели точно.','Har bir kx^n had uchun n ga ko‘paytirib, darajani 1 ga kamaytiring: d(kx^n)/dx=knx^(n−1). Ishoralar va kasr darajalarni aniq saqlang.'),
('P1-DIF-03','chain_rule','Your choice misses or misuses the derivative of the inner linear expression.','Выбранный вариант пропускает или неверно использует производную внутреннего линейного выражения.','Tanlangan javob ichki chiziqli ifodaning hosilasini tushirib qoldiradi yoki noto‘g‘ri qo‘llaydi.','For y=(ax+b)^n, differentiate the outer power and multiply by a: dy/dx=an(ax+b)^(n−1).','Для y=(ax+b)^n продифференцируйте внешнюю степень и умножьте на a: dy/dx=an(ax+b)^(n−1).','y=(ax+b)^n uchun tashqi darajani differensiallab, a ga ko‘paytiring: dy/dx=an(ax+b)^(n−1).'),
('P1-DIF-04','tangent_normal','Your choice uses the wrong point, tangent gradient or perpendicular-gradient relationship.','Выбранный вариант использует неверную точку, градиент касательной или связь перпендикулярных градиентов.','Tanlangan javob noto‘g‘ri nuqta, urinma gradienti yoki perpendikulyar gradientlar munosabatidan foydalanadi.','Find the point from the original curve and the tangent gradient from dy/dx. For a non-zero tangent gradient m, the normal gradient is −1/m, then use point-gradient form.','Найдите точку по исходной кривой и градиент касательной по dy/dx. При ненулевом градиенте m градиент нормали равен −1/m, затем используйте форму через точку и градиент.','Nuqtani asl egri chiziqdan, urinma gradientini dy/dx dan toping. Nol bo‘lmagan m uchun normal gradienti −1/m, so‘ng nuqta-gradient ko‘rinishidan foydalaning.'),
('P5-BIN-02','binomial_probability','Your choice uses the wrong binomial term, range or complement.','Выбранный вариант использует неверный биномиальный член, диапазон или дополнение.','Tanlangan javob noto‘g‘ri binomial had, oraliq yoki to‘ldiruvchi hodisadan foydalanadi.','For X~B(n,p), use P(X=r)=nCr p^r(1−p)^(n−r). For cumulative events, list the included values or use the shorter complement explicitly.','Для X~B(n,p) используйте P(X=r)=nCr p^r(1−p)^(n−r). Для накопленных событий перечислите включённые значения или явно используйте более короткое дополнение.','X~B(n,p) uchun P(X=r)=nCr p^r(1−p)^(n−r) dan foydalaning. Yig‘ma hodisalarda kiritilgan qiymatlarni yozing yoki qisqaroq to‘ldiruvchi hodisani aniq qo‘llang.'),
('P5-BIN-03','binomial_parameters','Your choice confuses the binomial mean, variance or inverse parameter relationships.','Выбранный вариант смешивает математическое ожидание, дисперсию или обратные соотношения параметров биномиального распределения.','Tanlangan javob binomial o‘rtacha, dispersiya yoki teskari parametr munosabatlarini aralashtiradi.','Use E(X)=np and Var(X)=np(1−p). Their ratio gives 1−p, which is often the quickest route in inverse problems.','Используйте E(X)=np и Var(X)=np(1−p). Их отношение даёт 1−p, что часто является самым быстрым путём в обратных задачах.','E(X)=np va Var(X)=np(1−p) dan foydalaning. Ularning nisbati 1−p ni beradi va teskari masalalarda ko‘pincha eng tez yo‘l bo‘ladi.'),
('P5-GEO-02','geometric_probability','Your choice uses the wrong number of failures or confuses an exact probability with a tail/cumulative probability.','Выбранный вариант использует неверное число неудач или смешивает точную вероятность с хвостовой/накопленной.','Tanlangan javob muvaffaqiyatsizliklar sonini noto‘g‘ri oladi yoki aniq ehtimolni dum/yig‘ma ehtimol bilan aralashtiradi.','For trial-number X, P(X=r)=(1−p)^(r−1)p and P(X>k)=(1−p)^k. Build cumulative probabilities with complements when shorter.','Для номера испытания X: P(X=r)=(1−p)^(r−1)p и P(X>k)=(1−p)^k. Для накопленных вероятностей используйте дополнение, если оно короче.','Sinov raqami X uchun P(X=r)=(1−p)^(r−1)p va P(X>k)=(1−p)^k. Yig‘ma ehtimollar uchun qisqaroq bo‘lsa, to‘ldiruvchi hodisadan foydalaning.'),
('P5-GEO-03','geometric_expectation','Your choice does not use the geometric expectation relationship correctly or mixes trials with elapsed time.','Выбранный вариант неверно использует математическое ожидание геометрического распределения или смешивает число испытаний со временем.','Tanlangan javob geometrik kutilma munosabatini noto‘g‘ri qo‘llaydi yoki sinovlar sonini vaqt bilan aralashtiradi.','For the trial-number convention, E(X)=1/p. Convert between trials and time only after finding the expected number of trials.','Для соглашения с номером испытания E(X)=1/p. Переходите между числом испытаний и временем только после нахождения ожидаемого числа испытаний.','Sinov raqami konvensiyasida E(X)=1/p. Sinovlar va vaqt orasida faqat kutiladigan sinovlar sonini topgandan keyin o‘ting.'),
('P5-NOR-01','normal_model','Your choice misreads N(μ,σ²) or chooses a variable whose shape/type is not plausibly normal.','Выбранный вариант неверно читает N(μ,σ²) или выбирает величину, тип/форма которой плохо соответствует нормальной модели.','Tanlangan javob N(μ,σ²) yozuvini noto‘g‘ri talqin qiladi yoki turi/shakli normal modelga mos kelmaydigan o‘zgaruvchini tanlaydi.','In N(μ,σ²), the second parameter is variance and σ is its positive square root. A normal model is continuous and approximately symmetric around μ; discrete waiting-time data are not normal.','В N(μ,σ²) второй параметр — дисперсия, а σ — её положительный квадратный корень. Нормальная модель непрерывна и примерно симметрична около μ; дискретное время ожидания нормальным не является.','N(μ,σ²) da ikkinchi parametr dispersiya, σ esa uning musbat kvadrat ildizi. Normal model uzluksiz va μ atrofida taxminan simmetrik; diskret kutish vaqti normal emas.')
), letters(answer_match) as (values ('A'),('B'),('C'),('D'))
insert into private.exam_prep_diagnostic_rules(
  content_meta_id,rule_version,answer_kind,answer_match,distractor_code,mistake_type,weak_skill_code,
  feedback_en,feedback_ru,feedback_uz,next_action_en,next_action_ru,next_action_uz,status
)
select m.id,'aw_reserve_v1','mcq_option',l.answer_match,
       replace(lower(m.content_key),'-','_')||'_wrong_'||lower(l.answer_match),
       sf.mistake_type,m.primary_skill_code,
       sf.feedback_en,sf.feedback_ru,sf.feedback_uz,sf.next_en,sf.next_ru,sf.next_uz,'draft'
from private.exam_prep_question_content_meta m
join public.questions qn on qn.id=m.question_id
join skill_feedback sf on sf.skill_code=m.primary_skill_code
cross join letters l
where m.content_version_id in (4819,4820)
  and m.reserve_role='diagnostic'
  and qn.qtype='mcq'
  and l.answer_match<>qn.correct_answer
on conflict(content_meta_id,rule_version,answer_kind,answer_match) do nothing;

do $postcheck$
declare v_bad int;
begin
  if (select count(*) from private.exam_prep_diagnostic_rules r
      join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
      where m.content_version_id in (4819,4820) and r.rule_version='aw_reserve_v1')<>66
  then raise exception 'aw17_20_annual_reserve_rules: expected 66 draft rules'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join public.questions qn on qn.id=m.question_id
  where m.content_version_id in (4819,4820)
    and m.reserve_role='diagnostic'
    and (
      qn.qtype<>'mcq'
      or (select count(*) from private.exam_prep_diagnostic_rules r
          where r.content_meta_id=m.id and r.rule_version='aw_reserve_v1'
            and r.status='draft' and r.answer_kind='mcq_option'
            and r.answer_match<>qn.correct_answer
            and r.weak_skill_code=m.primary_skill_code
            and nullif(btrim(r.feedback_en),'') is not null
            and nullif(btrim(r.feedback_ru),'') is not null
            and nullif(btrim(r.feedback_uz),'') is not null
            and nullif(btrim(r.next_action_en),'') is not null
            and nullif(btrim(r.next_action_ru),'') is not null
            and nullif(btrim(r.next_action_uz),'') is not null)<>3
    );
  if v_bad<>0 then raise exception 'aw17_20_annual_reserve_rules: invalid diagnostic rule rows=%',v_bad; end if;
end
$postcheck$;

commit;
