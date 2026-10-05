begin;
do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>138 then raise exception 'DAT01 baseline %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DAT-01' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DAT01 sources missing'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-DAT-01:tutor:en:v2','P5','P5-DAT-01','en','tutor_v2_learner_first','Choosing a data display',
$t$Choose a data display by asking what kind of data you have and what the reader needs to see.

A stem-and-leaf diagram is useful when individual numerical values should remain visible. A box plot gives a compact view of median, quartiles and spread, so it is useful for comparing distributions. A histogram is appropriate for continuous grouped data and handles unequal class widths through frequency density. A cumulative-frequency graph is useful when you need quartiles, percentiles or proportions below a value.

A good choice is not just “a graph that can be drawn”. It should make the required feature easy to see without hiding information that matters to the question.$t$,
$t$Match the display to the purpose.

Need exact values? Stem-and-leaf.

Need a compact comparison of centre and spread? Box plot.

Continuous grouped data, especially unequal class widths? Histogram.

Need quartiles, percentiles or proportions? Cumulative-frequency graph.$t$,
$t$Think of each display as answering a different question.

Stem-and-leaf says “what were the actual observations?”
Box plot says “where is the middle and how spread out is the data?”
Histogram says “how is continuous grouped data distributed across intervals?”
Cumulative frequency says “how many observations are at or below each value?”

Choose the display whose question matches your task.$t$,
$t$Do not choose only from habit. State why the display suits the data and purpose. Check whether exact values, grouped intervals, centre/spread or accumulated proportions are the important information. Also notice what the chosen display does not show.$t$,
'p5:P5-DAT-01:theory:en:v1'
),
(
'p5:P5-DAT-01:tutor:ru:v2','P5','P5-DAT-01','ru','tutor_v2_learner_first','Выбор способа представления данных',
$t$Способ представления выбирают по типу данных и по тому, что читатель должен увидеть.

Диаграмма «стебель и листья» удобна, когда важно сохранить отдельные числовые значения. Диаграмма размаха компактно показывает медиану, квартили и разброс, поэтому подходит для сравнения распределений. Гистограмма используется для непрерывных сгруппированных данных и учитывает разные ширины интервалов через плотность частоты. График накопленной частоты удобен для квартилей, процентилей и долей ниже заданного значения.

Хороший выбор — не просто «график, который можно построить». Он должен ясно показывать нужную особенность и не скрывать информацию, важную для задачи.$t$,
$t$Подбирайте представление под цель.

Нужны исходные значения? «Стебель и листья».

Нужно компактно сравнить центр и разброс? Диаграмма размаха.

Непрерывные сгруппированные данные, особенно с разными интервалами? Гистограмма.

Нужны квартили, процентили или доли? График накопленной частоты.$t$,
$t$Считайте, что каждый вид представления отвечает на свой вопрос.

«Стебель и листья»: какие именно наблюдения были получены?
Диаграмма размаха: где находится середина и насколько данные разбросаны?
Гистограмма: как распределены непрерывные сгруппированные данные по интервалам?
Накопленная частота: сколько наблюдений не превышает каждое значение?

Выбирайте тот способ, чей вопрос совпадает с вашей задачей.$t$,
$t$Не выбирайте диаграмму только по привычке. Объясните, почему она подходит типу данных и цели. Определите, что важнее: точные значения, интервалы, положение/разброс или накопленные доли. Учитывайте и то, какую информацию выбранный способ не показывает.$t$,
'p5:P5-DAT-01:theory:ru:v1'
),
(
'p5:P5-DAT-01:tutor:uz:v2','P5','P5-DAT-01','uz','tutor_v2_learner_first','Ma’lumotlarni tasvirlash usulini tanlash',
$t$Ma’lumotni tasvirlash usuli ma’lumot turi va nimani ko‘rsatish kerakligiga qarab tanlanadi.

Poya-barg diagrammasi alohida sonli qiymatlarni saqlab qolish kerak bo‘lganda qulay. Quti diagrammasi mediana, kvartillar va tarqalishni ixcham ko‘rsatadi, shuning uchun taqsimotlarni solishtirishga mos. Gistogramma uzluksiz guruhlangan ma’lumotlar uchun ishlatiladi va turli interval kengliklarini chastota zichligi orqali hisobga oladi. Yig‘ma chastota grafigi kvartillar, percentillar va berilgan qiymatdan past ulushlarni topishga qulay.

Yaxshi tanlov shunchaki “chizish mumkin bo‘lgan grafik” emas. U kerakli xususiyatni aniq ko‘rsatishi va vazifa uchun muhim ma’lumotni yashirmasligi kerak.$t$,
$t$Tasvirni maqsadga mos tanlang.

Aniq qiymatlar kerakmi? Poya-barg diagrammasi.

Markaz va tarqalishni ixcham solishtirish kerakmi? Quti diagrammasi.

Uzluksiz guruhlangan ma’lumotlar, ayniqsa interval kengliklari turlicha bo‘lsa? Gistogramma.

Kvartil, percentil yoki ulush kerakmi? Yig‘ma chastota grafigi.$t$,
$t$Har bir tasvir turi boshqa savolga javob beradi deb o‘ylang.

Poya-barg: aynan qaysi kuzatuvlar bor edi?
Quti diagrammasi: markaz qayerda va ma’lumotlar qanchalik tarqalgan?
Gistogramma: uzluksiz guruhlangan ma’lumotlar intervallarda qanday taqsimlangan?
Yig‘ma chastota: har bir qiymatgacha nechta kuzatuv yig‘ilgan?

Vazifangizga mos savolni beradigan tasvirni tanlang.$t$,
$t$Tasvirni faqat odat bo‘yicha tanlamang. Nega u ma’lumot turi va maqsadga mosligini ayting. Aniq qiymatlar, intervallar, markaz/tarqalish yoki yig‘ilgan ulushlardan qaysi biri muhimligini aniqlang. Tanlangan tasvir nimani ko‘rsatmasligini ham hisobga oling.$t$,
'p5:P5-DAT-01:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
