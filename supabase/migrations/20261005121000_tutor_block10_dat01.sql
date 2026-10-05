begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>138 then raise exception 'DAT01 expected 138 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_tutor_cards
      where content_version='tutor_v2_learner_first' and skill_code='P5-DAT-01')<>0
  then raise exception 'DAT01 Tutor Cards already exist'; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DAT-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DAT01 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-DAT-01:tutor:en:v2','P5','P5-DAT-01','en','tutor_v2_learner_first','Choosing a data display',
$t$A good data display is chosen for a reason: it should match both the type of data and what you want to see.

A stem-and-leaf diagram is useful when the data set is fairly small and you want to keep the individual values visible. A box plot gives a compact picture of median, quartiles and spread, so it is useful for comparing distributions. A histogram is designed for continuous grouped data and is especially important when class widths are unequal. A cumulative-frequency graph is useful when the question asks for quartiles, percentiles or proportions below a value.

So before drawing anything, ask two questions: what kind of data do I have, and what feature am I trying to communicate?$t$,
$t$Choose the display from the purpose.

Use a stem-and-leaf diagram to keep individual values visible.

Use a box plot to compare median and spread.

Use a histogram for continuous grouped data, especially unequal class widths.

Use a cumulative-frequency graph for quartiles, percentiles and proportions.

The best graph is the one that makes the required feature easiest to read.$t$,
$t$Think of each display as answering a different question.

“Can I still see the original values?” points to stem-and-leaf.

“How do two distributions compare in centre and spread?” points to box plots.

“How is continuous grouped data distributed?” points to a histogram.

“What value cuts off a chosen percentage of the data?” points to cumulative frequency.

The choice is about information, not decoration.$t$,
$t$Do not choose a graph only because it is familiar. Check data type and purpose first. Histograms require frequency density when class widths differ. Box plots summarise rather than preserve every value. Cumulative-frequency graphs are for accumulated counts, not ordinary class frequencies.$t$,
'p5:P5-DAT-01:theory:en:v1'
),
(
'p5:P5-DAT-01:tutor:ru:v2','P5','P5-DAT-01','ru','tutor_v2_learner_first','Выбор способа представления данных',
$t$Способ представления данных нужно выбирать по смыслу: он должен подходить и типу данных, и тому, что вы хотите увидеть.

Диаграмма «стебель и листья» удобна для небольшого набора, когда важно сохранить отдельные значения. Box plot компактно показывает медиану, квартили и разброс, поэтому подходит для сравнения распределений. Гистограмма предназначена для непрерывных сгруппированных данных и особенно важна при неодинаковой ширине интервалов. График накопленной частоты удобен для квартилей, процентилей и долей ниже заданного значения.

Поэтому перед построением задайте два вопроса: какие у меня данные и какую особенность нужно показать?$t$,
$t$Выбирайте представление по цели.

«Стебель и листья» сохраняет отдельные значения.

Box plot удобен для сравнения медианы и разброса.

Гистограмма нужна для непрерывных сгруппированных данных, особенно при разной ширине интервалов.

Накопленная частота нужна для квартилей, процентилей и долей.

Лучший график — тот, на котором нужная информация читается проще всего.$t$,
$t$Можно считать, что каждый способ отвечает на свой вопрос.

«Нужно видеть исходные значения?» — стебель и листья.

«Нужно сравнить центр и разброс?» — box plot.

«Как распределены непрерывные сгруппированные данные?» — гистограмма.

«Какое значение отделяет заданный процент наблюдений?» — график накопленной частоты.

Выбор делается по информации, а не по внешнему виду.$t$,
$t$Не выбирайте график только потому, что он знаком. Сначала проверьте тип данных и цель. При неравных интервалах в гистограмме нужна плотность частоты. Box plot не сохраняет каждое значение. Накопленная частота показывает накопленные количества, а не обычные частоты интервалов.$t$,
'p5:P5-DAT-01:theory:ru:v1'
),
(
'p5:P5-DAT-01:tutor:uz:v2','P5','P5-DAT-01','uz','tutor_v2_learner_first','Ma’lumotlarni tasvirlash usulini tanlash',
$t$Ma’lumotni tasvirlash usuli maqsadga qarab tanlanadi: u ham ma’lumot turiga, ham nimani ko‘rsatmoqchi ekaningizga mos bo‘lishi kerak.

Poya-barg diagrammasi kichikroq to‘plamda alohida qiymatlarni saqlab ko‘rsatish uchun qulay. Quti diagrammasi mediana, kvartillar va tarqalishni ixcham ko‘rsatadi, shuning uchun taqsimotlarni solishtirishda foydali. Gistogramma uzluksiz guruhlangan ma’lumotlar uchun, ayniqsa interval kengliklari turlicha bo‘lganda kerak. Yig‘ma chastota grafigi kvartillar, percentillar va berilgan qiymatdan pastdagi ulushlarni topishga yordam beradi.

Shuning uchun avval ikki savol bering: ma’lumot qanday turda va qaysi xususiyatni ko‘rsatish kerak?$t$,
$t$Tasvirlash usulini maqsadga qarab tanlang.

Poya-barg diagrammasi alohida qiymatlarni saqlaydi.

Quti diagrammasi mediana va tarqalishni solishtirishga yordam beradi.

Gistogramma uzluksiz guruhlangan ma’lumotlar uchun, ayniqsa interval kengliklari turlicha bo‘lsa, mos keladi.

Yig‘ma chastota grafigi kvartil, percentil va ulushlar uchun ishlatiladi.$t$,
$t$Har bir grafik turini alohida savolga javob deb o‘ylang.

“Asl qiymatlarni ko‘rish kerakmi?” — poya-barg.

“Markaz va tarqalishni solishtirish kerakmi?” — quti diagrammasi.

“Uzluksiz guruhlangan ma’lumot qanday taqsimlangan?” — gistogramma.

“Ma’lum foizni qaysi qiymat ajratadi?” — yig‘ma chastota.

Tanlov bezak uchun emas, kerakli ma’lumot uchun qilinadi.$t$,
$t$Grafikni faqat tanish bo‘lgani uchun tanlamang. Avval ma’lumot turi va maqsadni tekshiring. Gistogrammada interval kengliklari turlicha bo‘lsa chastota zichligi kerak. Quti diagrammasi har bir qiymatni saqlamaydi. Yig‘ma chastota oddiy interval chastotalarini emas, yig‘ilib boradigan sonlarni ko‘rsatadi.$t$,
'p5:P5-DAT-01:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
