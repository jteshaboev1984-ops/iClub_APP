begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

do $pre$ declare v integer; begin
  select count(*) into v from private.exam_prep_ai_tutor_cards
  where content_version='tutor_v2_learner_first' and approval_status='draft' and not is_runtime_allowed;
  if v<>159 then raise exception 'DAT08 expected 159 prior drafts, found %',v; end if;
  if (select count(*) from private.exam_prep_ai_source_cards
      where component_code='P5' and skill_code='P5-DAT-08' and card_type='theory'
        and locale in ('en','ru','uz') and approval_status='approved' and is_runtime_allowed)<>3
  then raise exception 'DAT08 requires 3 approved runtime theory sources'; end if;
end $pre$;

with seed(k,c,s,l,v,title,m,simp,alt,focus,src) as (values
(
'p5:P5-DAT-08:tutor:en:v2','P5','P5-DAT-08','en','tutor_v2_learner_first','Comparing data sets',
$t$A useful comparison of two data sets should discuss both location and spread.

Suppose:

Set A has median 52 and IQR 8.

Set B has median 48 and IQR 14.

The higher median suggests that Set A has the higher typical value. The smaller IQR suggests that the middle half of Set A is less spread out, so its values are more consistent.

A complete contextual conclusion could be: “Set A typically has higher values and shows less variation in the middle half of the data than Set B.”

Do not compare only one statistic unless the question asks for only one. A strong comparison links the numerical evidence to the real context.$t$,
$t$Compare both centre and spread.

Set A: median 52, IQR 8.

Set B: median 48, IQR 14.

A has the higher typical value because its median is larger.

A is also less variable in the middle half because its IQR is smaller.

State both points in context.$t$,
$t$Think of comparison as answering two separate questions.

“Where is the distribution centred?” Use a location measure such as median or mean.

“How consistent or variable is it?” Use a spread measure such as IQR or standard deviation.

Only after answering both should you write the contextual conclusion. This prevents vague statements such as “A is better” without statistical evidence.$t$,
$t$Quote the relevant statistics, then interpret them. Higher centre does not automatically mean smaller spread, and smaller spread does not automatically mean higher centre. Avoid unsupported words like “better”; say exactly what is higher/lower or more/less variable in the context.$t$,
'p5:P5-DAT-08:theory:en:v1'
),
(
'p5:P5-DAT-08:tutor:ru:v2','P5','P5-DAT-08','ru','tutor_v2_learner_first','Сравнение наборов данных',
$t$Полезное сравнение двух наборов должно учитывать и положение, и разброс.

Пусть:

у набора A медиана 52 и IQR 8;

у набора B медиана 48 и IQR 14.

Более высокая медиана показывает, что у A типичное значение выше. Меньший IQR показывает, что средняя половина данных A менее разбросана, то есть значения более стабильны.

Полный вывод в контексте может звучать так: «У набора A типичные значения выше и разброс средней половины данных меньше, чем у набора B».

Не сравнивайте только один показатель, если вопрос не требует именно этого. Сильный вывод связывает числа с реальным смыслом данных.$t$,
$t$Сравнивайте и центр, и разброс.

A: медиана 52, IQR 8.

B: медиана 48, IQR 14.

У A типичное значение выше, потому что медиана больше.

У A также меньший разброс средней половины, потому что IQR меньше.

Оба вывода запишите в контексте.$t$,
$t$Считайте сравнение ответом на два отдельных вопроса.

«Где находится центр распределения?» — используйте медиану или среднее.

«Насколько данные стабильны или разбросаны?» — используйте IQR или стандартное отклонение.

Только после этого формулируйте контекстный вывод. Так вы избегаете фраз вроде «A лучше» без статистического основания.$t$,
$t$Сначала назовите нужные статистики, затем объясните их смысл. Более высокий центр не означает автоматически меньший разброс, и наоборот. Не используйте слово «лучше» без основания — укажите, что именно выше, ниже, стабильнее или более изменчиво.$t$,
'p5:P5-DAT-08:theory:ru:v1'
),
(
'p5:P5-DAT-08:tutor:uz:v2','P5','P5-DAT-08','uz','tutor_v2_learner_first','Ma’lumotlar to‘plamlarini taqqoslash',
$t$Ikki ma’lumotlar to‘plamini yaxshi taqqoslash uchun ham markaziy joylashuv, ham tarqalish haqida gapirish kerak.

Faraz qilaylik:

A to‘plamining medianasi 52, IQR 8.

B to‘plamining medianasi 48, IQR 14.

Kattaroq mediana A ning odatiy qiymati yuqoriroq ekanini ko‘rsatadi. Kichikroq IQR esa A ning o‘rta yarmi kamroq tarqalganini, ya’ni qiymatlar barqarorroq ekanini ko‘rsatadi.

To‘liq xulosa: “A to‘plamida odatiy qiymatlar yuqoriroq va ma’lumotlarning o‘rta yarmidagi tarqalish B ga qaraganda kichikroq.”

Savol faqat bitta ko‘rsatkichni so‘ramasa, faqat bitta statistikani solishtirib to‘xtamang.$t$,
$t$Ham markazni, ham tarqalishni solishtiring.

A: mediana 52, IQR 8.

B: mediana 48, IQR 14.

A ning odatiy qiymati yuqoriroq, chunki medianasi kattaroq.

A ning o‘rta yarmi ham kamroq tarqalgan, chunki IQR kichikroq.

Ikkala fikrni ham kontekstda yozing.$t$,
$t$Taqqoslashni ikki alohida savol deb o‘ylang.

“Ta’qsimot qayerda markazlangan?” — mediana yoki o‘rtachadan foydalaning.

“Qanchalik barqaror yoki tarqalgan?” — IQR yoki standart og‘ishdan foydalaning.

Shundan keyingina kontekstli xulosa yozing. Bu “A yaxshiroq” kabi dalilsiz gaplardan saqlaydi.$t$,
$t$Avval tegishli statistikalarni keltiring, keyin ma’nosini tushuntiring. Yuqoriroq markaz avtomatik ravishda kichikroq tarqalishni anglatmaydi va aksincha. “Yaxshiroq” demang; aynan nima yuqori, past, barqaror yoki o‘zgaruvchan ekanini ayting.$t$,
'p5:P5-DAT-08:theory:uz:v1'
))
insert into private.exam_prep_ai_tutor_cards(
 tutor_card_key,component_code,skill_code,locale,content_version,title,
 main_explanation,simple_explanation,alternative_explanation,focus_explanation,
 source_card_key,approval_status,is_runtime_allowed,content_hash)
select k,c,s,l,v,title,m,simp,alt,focus,src,'draft',false,
md5(concat_ws('||',v,title,m,simp,alt,focus,src)) from seed;
commit;
