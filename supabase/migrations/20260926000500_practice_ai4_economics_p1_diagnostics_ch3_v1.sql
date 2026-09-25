-- AI-4 Economics Practice 1 deterministic diagnostic batch: Chapter 3.
-- Adds option-level deterministic explanations for three already-published MCQs.
-- Scoring remains server-authoritative from questions.correct_answer; these rows only
-- classify the learner's selected option after checking. Existing diagnostic mappings remain untouched.

do $guard$
declare
  v_bad integer;
begin
  with expected(question_id,topic,subtopic,correct_answer,options_en) as (
    values
    (1066,'Basics','Reward to land','A','["Rent","Wages","Interest","Profit"]'::jsonb),
    (1067,'Basics','Reward to capital','A','["Interest","Rent","Wages","Subsidy"]'::jsonb),
    (1073,'Supply','Productivity and supply','A','["increase supply","decrease demand","cause shortage","make goods inferior"]'::jsonb)
  )
  select count(*) into v_bad
  from expected e
  left join public.questions q on q.id=e.question_id
  where q.id is null
     or q.subject_id<>7
     or q.is_active is not true
     or q.quality_status<>'published'
     or lower(coalesce(q.qtype,''))<>'mcq'
     or q.topic<>e.topic
     or q.subtopic<>e.subtopic
     or upper(trim(coalesce(q.correct_answer,'')))<>e.correct_answer
     or coalesce(q.options_text_en,'[]')::jsonb<>e.options_en;

  if v_bad<>0 then
    raise exception 'AI-4 diagnostic batch refused: one or more Chapter 3 questions changed';
  end if;

  if exists (
    select 1
    from public.question_answer_diagnostics d
    where d.question_id in (1066,1067,1073)
      and d.quality_status='published'
  ) then
    raise exception 'AI-4 diagnostic batch refused: published mappings already exist for a target question';
  end if;
end
$guard$;

insert into public.question_answer_diagnostics(
  question_id,answer_kind,answer_key,answer_value,is_correct,mistake_type,weak_skill,
  feedback_ru,feedback_uz,feedback_en,
  next_action_ru,next_action_uz,next_action_en,
  recommended_topic,recommended_subtopic,rule_json,quality_status
)
values
(1066,'mcq_option','A','Rent',true,null,null,
 'Верно: доходом земли как фактора производства является рента.',
 'To‘g‘ri: ishlab chiqarish omili sifatidagi yerning daromadi renta hisoblanadi.',
 'Correct: the reward to land as a factor of production is rent.',
 'Повторите соответствие факторов производства и их доходов.',
 'Ishlab chiqarish omillari va ularning daromadlari mosligini takrorlang.',
 'Review the matching of factors of production to their rewards.',
 'Basics','Reward to land','{}'::jsonb,'published'),
(1066,'mcq_option','B','Wages',false,'factor_reward_confusion','Factor rewards: land vs labour',
 'Заработная плата является доходом труда, а не земли. Доход земли — рента.',
 'Ish haqi mehnatning daromadi, yerning emas. Yerning daromadi renta.',
 'Wages are the reward to labour, not land. The reward to land is rent.',
 'Сопоставьте: земля → рента; труд → заработная плата.',
 'Moslang: yer → renta; mehnat → ish haqi.',
 'Match: land → rent; labour → wages.',
 'Basics','Reward to land','{}'::jsonb,'published'),
(1066,'mcq_option','C','Interest',false,'factor_reward_confusion','Factor rewards: land vs capital',
 'Процент является доходом капитала, а не земли. Для земли используется рента.',
 'Foiz kapitalning daromadi, yerning emas. Yer uchun renta qo‘llanadi.',
 'Interest is the reward to capital, not land. Land earns rent.',
 'Сопоставьте: земля → рента; капитал → процент.',
 'Moslang: yer → renta; kapital → foiz.',
 'Match: land → rent; capital → interest.',
 'Basics','Reward to land','{}'::jsonb,'published'),
(1066,'mcq_option','D','Profit',false,'factor_reward_confusion','Factor rewards: land vs enterprise',
 'Прибыль связывают с предпринимательством, а не с землёй. Доход земли — рента.',
 'Foyda tadbirkorlik bilan bog‘liq, yer bilan emas. Yerning daromadi renta.',
 'Profit is associated with enterprise, not land. The reward to land is rent.',
 'Повторите четыре фактора производства и их доходы.',
 'To‘rtta ishlab chiqarish omili va ularning daromadlarini takrorlang.',
 'Review the four factors of production and their rewards.',
 'Basics','Reward to land','{}'::jsonb,'published'),

(1067,'mcq_option','A','Interest',true,null,null,
 'Верно: доходом капитала как фактора производства является процент.',
 'To‘g‘ri: ishlab chiqarish omili sifatidagi kapitalning daromadi foiz hisoblanadi.',
 'Correct: the reward to capital as a factor of production is interest.',
 'Свяжите капитал с созданными человеком производственными ресурсами и процентом.',
 'Kapitalni inson yaratgan ishlab chiqarish resurslari va foiz bilan bog‘lang.',
 'Link capital to man-made productive resources and interest.',
 'Basics','Reward to capital','{}'::jsonb,'published'),
(1067,'mcq_option','B','Rent',false,'factor_reward_confusion','Factor rewards: capital vs land',
 'Рента является доходом земли. Капитал приносит процент.',
 'Renta yerning daromadi. Kapitalning daromadi foiz.',
 'Rent is the reward to land. Capital earns interest.',
 'Сопоставьте: капитал → процент; земля → рента.',
 'Moslang: kapital → foiz; yer → renta.',
 'Match: capital → interest; land → rent.',
 'Basics','Reward to capital','{}'::jsonb,'published'),
(1067,'mcq_option','C','Wages',false,'factor_reward_confusion','Factor rewards: capital vs labour',
 'Заработная плата является доходом труда. Доход капитала — процент.',
 'Ish haqi mehnatning daromadi. Kapitalning daromadi foiz.',
 'Wages are the reward to labour. The reward to capital is interest.',
 'Сопоставьте каждый фактор производства с его доходом.',
 'Har bir ishlab chiqarish omilini uning daromadi bilan moslang.',
 'Match each factor of production to its reward.',
 'Basics','Reward to capital','{}'::jsonb,'published'),
(1067,'mcq_option','D','Subsidy',false,'subsidy_factor_reward_confusion','Factor rewards vs government payments',
 'Субсидия — это государственная поддержка, а не доход фактора производства. Капитал приносит процент.',
 'Subsidiya davlat yordami bo‘lib, ishlab chiqarish omilining daromadi emas. Kapitalning daromadi foiz.',
 'A subsidy is government support, not a factor reward. Capital earns interest.',
 'Различайте факторные доходы и государственные выплаты.',
 'Omil daromadlari bilan davlat to‘lovlarini farqlang.',
 'Distinguish factor rewards from government payments.',
 'Basics','Reward to capital','{}'::jsonb,'published'),

(1073,'mcq_option','A','increase supply',true,null,null,
 'Верно: более высокая производительность труда позволяет выпускать больше продукции из имеющихся ресурсов и обычно увеличивает предложение.',
 'To‘g‘ri: yuqori mehnat unumdorligi mavjud resurslardan ko‘proq mahsulot ishlab chiqarishga imkon beradi va odatda taklifni oshiradi.',
 'Correct: higher labour productivity allows more output from available resources and will usually increase supply.',
 'Свяжите производительность с издержками на единицу и положением кривой предложения.',
 'Unumdorlikni birlik xarajatlari va taklif egri chizig‘i holati bilan bog‘lang.',
 'Link productivity to unit costs and the position of the supply curve.',
 'Supply','Productivity and supply','{}'::jsonb,'published'),
(1073,'mcq_option','B','decrease demand',false,'supply_demand_side_confusion','Productivity affects supply, not demand',
 'Производительность труда относится к условиям производства и напрямую влияет на предложение, а не на спрос потребителей.',
 'Mehnat unumdorligi ishlab chiqarish sharoitiga taalluqli va bevosita taklifga ta’sir qiladi, iste’molchilar talabiga emas.',
 'Labour productivity is a production-side factor and directly affects supply, not consumer demand.',
 'Определяйте, относится ли фактор к стороне спроса или предложения.',
 'Omil talab yoki taklif tomoniga tegishli ekanini aniqlang.',
 'Identify whether a factor belongs to the demand side or the supply side.',
 'Supply','Productivity and supply','{}'::jsonb,'published'),
(1073,'mcq_option','C','cause shortage',false,'productivity_shortage_confusion','Productivity and market supply',
 'Рост производительности сам по себе не означает дефицит. Он обычно увеличивает возможный выпуск и сдвигает предложение вправо.',
 'Unumdorlik oshishi o‘z-o‘zidan taqchillikni anglatmaydi. U odatda mumkin bo‘lgan ishlab chiqarishni ko‘paytiradi va taklifni o‘ngga siljitadi.',
 'Higher productivity does not by itself cause a shortage. It usually raises potential output and shifts supply to the right.',
 'Повторите, что означает сдвиг предложения вправо.',
 'Taklifning o‘ngga siljishi nimani anglatishini takrorlang.',
 'Review what a rightward shift of supply means.',
 'Supply','Productivity and supply','{}'::jsonb,'published'),
(1073,'mcq_option','D','make goods inferior',false,'income_classification_supply_confusion','Inferior goods vs supply factors',
 'Низшее благо классифицируется по реакции спроса на изменение дохода. Производительность труда относится к предложению и не делает благо низшим.',
 'Past toifadagi tovar talabning daromad o‘zgarishiga reaksiyasi bilan aniqlanadi. Mehnat unumdorligi taklif omili bo‘lib, tovarni past toifaga aylantirmaydi.',
 'An inferior good is classified by how demand responds to income. Labour productivity is a supply-side factor and does not make a good inferior.',
 'Разделяйте классификацию по YED и факторы предложения.',
 'YED bo‘yicha tasnifni taklif omillaridan ajrating.',
 'Separate YED-based classification from determinants of supply.',
 'Supply','Productivity and supply','{}'::jsonb,'published');