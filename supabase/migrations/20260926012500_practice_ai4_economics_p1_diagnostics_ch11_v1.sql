-- AI-4 Economics Practice 1 deterministic diagnostic batch: Chapter 11.
-- Adds option-level diagnostics for five currently-unmapped Chapter 11 MCQs.
-- q1081 and q1115 already have published deterministic diagnostics and remain untouched.
-- Server scoring remains authoritative; diagnostics only explain the checked result.

do $guard$
declare v_bad integer;
begin
  with expected(question_id,topic,subtopic,correct_answer,options_en) as (
    values
    (1028,'Market','Consumer surplus','B','["Total revenue minus total cost","Difference between what consumers are willing to pay and what they actually pay","A tax paid by consumers","Profit earned by firms"]'::jsonb),
    (1029,'Market','Producer surplus','A','["Difference between price received and minimum price producers are willing to accept","A government subsidy","A tax on firms","Total cost of production"]'::jsonb),
    (1079,'Elasticity','Total revenue and elasticity','A','["increase total revenue","decrease total revenue","leave revenue unchanged always","make supply perfectly elastic"]'::jsonb),
    (1121,'Market','Tax and consumer surplus','C','["Increase","Stay the same","Decrease","Become infinite"]'::jsonb),
    (1133,'Market','Producer surplus','B','["Below the supply curve and above the market price","Above the supply curve and below the market price","Above the demand curve and below the market price","Above the market price and above the supply curve"]'::jsonb)
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
    raise exception 'AI-4 diagnostic batch refused: one or more Chapter 11 questions changed';
  end if;

  if exists (
    select 1 from public.question_answer_diagnostics
    where question_id in (1028,1029,1079,1121,1133)
      and quality_status='published'
  ) then
    raise exception 'AI-4 diagnostic batch refused: published mappings already exist for a target question';
  end if;
end
$guard$;

insert into public.question_answer_diagnostics(
  question_id,answer_kind,answer_key,answer_value,is_correct,mistake_type,weak_skill,
  feedback_ru,feedback_uz,feedback_en,next_action_ru,next_action_uz,next_action_en,
  recommended_topic,recommended_subtopic,rule_json,quality_status
) values
(1028,'mcq_option','A','Total revenue minus total cost',false,'consumer_surplus_profit_confusion','Consumer surplus vs firm profit',
 'Вы выбрали формулу прибыли фирмы. Потребительский излишек относится к выгоде покупателей, а не к доходу минус издержки.',
 'Siz firma foydasi formulasini tanladingiz. Iste’molchi ortiqchaligi xaridor foydasiga tegishli, daromad minus xarajatga emas.',
 'You chose the firm-profit formula. Consumer surplus is a buyer benefit, not total revenue minus total cost.',
 'Различайте consumer surplus и profit.',
 'Consumer surplus va profitni farqlang.',
 'Distinguish consumer surplus from profit.',
 'Market','Consumer surplus','{}'::jsonb,'published'),
(1028,'mcq_option','B','Difference between what consumers are willing to pay and what they actually pay',true,null,null,
 'Верно: потребительский излишек — разница между максимальной готовностью платить и фактической ценой.',
 'To‘g‘ri: iste’molchi ortiqchaligi maksimal to‘lashga tayyor narx bilan amaldagi narx o‘rtasidagi farq.',
 'Correct: consumer surplus is the difference between willingness to pay and the price actually paid.',
 'Свяжите demand curve с willingness to pay.',
 'Talab egri chizig‘ini willingness to pay bilan bog‘lang.',
 'Link the demand curve to willingness to pay.',
 'Market','Consumer surplus','{}'::jsonb,'published'),
(1028,'mcq_option','C','A tax paid by consumers',false,'consumer_surplus_tax_confusion','Consumer surplus definition',
 'Налог может уменьшить потребительский излишек, но сам налог не является его определением.',
 'Soliq iste’molchi ortiqchaligini kamaytirishi mumkin, ammo soliqning o‘zi uning ta’rifi emas.',
 'A tax can reduce consumer surplus, but the tax itself is not the definition of consumer surplus.',
 'Отделяйте изменение surplus от самого surplus.',
 'Surplus o‘zgarishi bilan surplusning o‘zini farqlang.',
 'Separate a change in surplus from the definition of surplus itself.',
 'Market','Consumer surplus','{}'::jsonb,'published'),
(1028,'mcq_option','D','Profit earned by firms',false,'consumer_producer_side_confusion','Consumer surplus vs firm profit',
 'Прибыль фирмы относится к производителям. Потребительский излишек измеряет выгоду покупателей.',
 'Firma foydasi ishlab chiqaruvchilarga tegishli. Iste’molchi ortiqchaligi xaridor foydasini o‘lchaydi.',
 'Firm profit belongs to the producer side. Consumer surplus measures buyer benefit.',
 'Сначала определите, относится показатель к покупателю или продавцу.',
 'Avval ko‘rsatkich xaridor yoki sotuvchiga tegishli ekanini aniqlang.',
 'First identify whether the measure belongs to buyers or sellers.',
 'Market','Consumer surplus','{}'::jsonb,'published'),

(1029,'mcq_option','A','Difference between price received and minimum price producers are willing to accept',true,null,null,
 'Верно: излишек производителя — разница между полученной ценой и минимальной ценой, при которой производитель готов продавать.',
 'To‘g‘ri: ishlab chiqaruvchi ortiqchaligi olingan narx bilan ishlab chiqaruvchi sotishga tayyor bo‘lgan eng past narx o‘rtasidagi farq.',
 'Correct: producer surplus is the difference between the price received and the minimum price producers are willing to accept.',
 'Свяжите supply curve с minimum acceptable price.',
 'Taklif egri chizig‘ini minimum acceptable price bilan bog‘lang.',
 'Link the supply curve to the minimum acceptable price.',
 'Market','Producer surplus','{}'::jsonb,'published'),
(1029,'mcq_option','B','A government subsidy',false,'producer_surplus_subsidy_confusion','Producer surplus definition',
 'Субсидия может увеличить излишек производителя, но не является его определением.',
 'Subsidiya ishlab chiqaruvchi ortiqchaligini oshirishi mumkin, ammo uning ta’rifi emas.',
 'A subsidy can increase producer surplus, but it is not the definition of producer surplus.',
 'Отделяйте политику, влияющую на surplus, от определения surplus.',
 'Surplusga ta’sir qiladigan siyosatni surplus ta’rifidan ajrating.',
 'Separate a policy that affects surplus from the definition of surplus.',
 'Market','Producer surplus','{}'::jsonb,'published'),
(1029,'mcq_option','C','A tax on firms',false,'producer_surplus_tax_confusion','Producer surplus definition',
 'Налог на фирмы может уменьшить излишек производителя, но сам налог не является producer surplus.',
 'Firmalarga soliq ishlab chiqaruvchi ortiqchaligini kamaytirishi mumkin, ammo soliqning o‘zi producer surplus emas.',
 'A tax on firms may reduce producer surplus, but the tax itself is not producer surplus.',
 'Вернитесь к разнице между фактической и минимально приемлемой ценой.',
 'Amaldagi narx bilan eng past qabul qilinadigan narx o‘rtasidagi farqqa qayting.',
 'Return to the difference between actual price and minimum acceptable price.',
 'Market','Producer surplus','{}'::jsonb,'published'),
(1029,'mcq_option','D','Total cost of production',false,'producer_surplus_cost_confusion','Producer surplus vs total cost',
 'Общие издержки — отдельное понятие. Producer surplus связан с ценой продажи относительно минимальной готовности продавца принять цену.',
 'Jami xarajat alohida tushuncha. Producer surplus sotuv narxining sotuvchi qabul qilishga tayyor eng past narxga nisbati bilan bog‘liq.',
 'Total cost is a separate concept. Producer surplus is about the selling price relative to the seller’s minimum acceptable price.',
 'Различайте cost и surplus.',
 'Cost va surplusni farqlang.',
 'Distinguish cost from surplus.',
 'Market','Producer surplus','{}'::jsonb,'published'),

(1079,'mcq_option','A','increase total revenue',true,null,null,
 'Верно: при неэластичном спросе процентное падение количества меньше процентного роста цены, поэтому общая выручка обычно растёт.',
 'To‘g‘ri: noelastik talabda miqdorning foiz kamayishi narxning foiz oshishidan kichik bo‘ladi, shuning uchun jami tushum odatda oshadi.',
 'Correct: with inelastic demand, the percentage fall in quantity is smaller than the percentage rise in price, so total revenue usually increases.',
 'Свяжите inelastic demand с одинаковым направлением цены и total revenue.',
 'Inelastic demandda narx va total revenue bir yo‘nalishda harakatlanishini bog‘lang.',
 'Link inelastic demand to price and total revenue moving in the same direction.',
 'Elasticity','Total revenue and elasticity','{}'::jsonb,'published'),
(1079,'mcq_option','B','decrease total revenue',false,'ped_revenue_direction_error','Inelastic demand and total revenue',
 'При |PED| < 1 рост цены обычно повышает, а не снижает общую выручку.',
 '|PED| < 1 bo‘lganda narx oshishi odatda jami tushumni kamaytirmaydi, oshiradi.',
 'When |PED| < 1, a price increase usually raises rather than lowers total revenue.',
 'Повторите правило total revenue для inelastic demand.',
 'Inelastic demand uchun total revenue qoidasini takrorlang.',
 'Review the total-revenue rule for inelastic demand.',
 'Elasticity','Total revenue and elasticity','{}'::jsonb,'published'),
(1079,'mcq_option','C','leave revenue unchanged always',false,'unit_elastic_confusion','Inelastic vs unit-elastic demand',
 'Неизменная выручка связана с единичной эластичностью, а не с |PED| < 1.',
 'Tushumning o‘zgarmasligi unit elastic talabga xos, |PED| < 1 ga emas.',
 'Unchanged total revenue is associated with unit elasticity, not |PED| < 1.',
 'Сравните elastic, inelastic и unit-elastic demand.',
 'Elastic, inelastic va unit-elastic demandni solishtiring.',
 'Compare elastic, inelastic and unit-elastic demand.',
 'Elasticity','Total revenue and elasticity','{}'::jsonb,'published'),
(1079,'mcq_option','D','make supply perfectly elastic',false,'ped_pes_confusion','Demand elasticity vs supply elasticity',
 'Изменение цены при неэластичном спросе не делает предложение совершенно эластичным.',
 'Noelastik talabdagi narx o‘zgarishi taklifni mutlaqo elastik qilib qo‘ymaydi.',
 'A price change under inelastic demand does not make supply perfectly elastic.',
 'Различайте PED и PES.',
 'PED va PESni farqlang.',
 'Distinguish PED from PES.',
 'Elasticity','Total revenue and elasticity','{}'::jsonb,'published'),

(1121,'mcq_option','A','Increase',false,'tax_consumer_surplus_direction_error','Tax effect on consumer surplus',
 'Налог на единицу обычно повышает цену для покупателей и сокращает объём сделок, поэтому consumer surplus не увеличивается.',
 'Bir birlik solig‘i odatda xaridor narxini oshiradi va savdo hajmini kamaytiradi, shuning uchun consumer surplus oshmaydi.',
 'A per-unit tax usually raises the buyer price and reduces traded quantity, so consumer surplus does not increase.',
 'Проследите влияние налога на цену покупателей и объём рынка.',
 'Soliqning xaridor narxi va bozor miqdoriga ta’sirini kuzating.',
 'Trace the tax effect on buyer price and market quantity.',
 'Market','Tax and consumer surplus','{}'::jsonb,'published'),
(1121,'mcq_option','B','Stay the same',false,'tax_effect_ignored','Tax effect on consumer surplus',
 'Налог изменяет цену и количество сделок, поэтому потребительский излишек обычно меняется.',
 'Soliq narx va savdo miqdorini o‘zgartiradi, shuning uchun iste’molchi ortiqchaligi odatda o‘zgaradi.',
 'A tax changes price and traded quantity, so consumer surplus usually changes.',
 'Не игнорируйте welfare-эффект налога.',
 'Soliqning welfare ta’sirini e’tiborsiz qoldirmang.',
 'Do not ignore the welfare effect of a tax.',
 'Market','Tax and consumer surplus','{}'::jsonb,'published'),
(1121,'mcq_option','C','Decrease',true,null,null,
 'Верно: налог на единицу обычно повышает цену для потребителей и снижает количество, уменьшая consumer surplus.',
 'To‘g‘ri: bir birlik solig‘i odatda iste’molchi narxini oshiradi va miqdorni kamaytirib, consumer surplusni pasaytiradi.',
 'Correct: a per-unit tax usually raises the consumer price and lowers quantity, reducing consumer surplus.',
 'Свяжите налог с потерей части области consumer surplus.',
 'Soliqni consumer surplus maydonining bir qismi yo‘qolishi bilan bog‘lang.',
 'Link the tax to the loss of part of the consumer-surplus area.',
 'Market','Tax and consumer surplus','{}'::jsonb,'published'),
(1121,'mcq_option','D','Become infinite',false,'surplus_extreme_error','Consumer surplus under tax',
 'Налог не делает потребительский излишек бесконечным; обычно он его уменьшает.',
 'Soliq iste’molchi ortiqchaligini cheksiz qilmaydi; odatda uni kamaytiradi.',
 'A tax does not make consumer surplus infinite; it usually reduces it.',
 'Избегайте крайних выводов без экономической логики.',
 'Iqtisodiy mantiqsiz keskin xulosalardan qoching.',
 'Avoid extreme conclusions without economic logic.',
 'Market','Tax and consumer surplus','{}'::jsonb,'published'),

(1133,'mcq_option','A','Below the supply curve and above the market price',false,'producer_surplus_area_direction','Producer surplus diagram',
 'Producer surplus находится не ниже supply curve. Он расположен выше supply curve и ниже market price.',
 'Producer surplus supply curve ostida emas. U supply curve ustida va market price ostida joylashadi.',
 'Producer surplus is not below the supply curve. It lies above the supply curve and below the market price.',
 'Повторите положение producer surplus на диаграмме.',
 'Diagrammada producer surplus joylashuvini takrorlang.',
 'Review the location of producer surplus on a diagram.',
 'Market','Producer surplus','{}'::jsonb,'published'),
(1133,'mcq_option','B','Above the supply curve and below the market price',true,null,null,
 'Верно: producer surplus — область выше кривой предложения и ниже рыночной цены до проданного количества.',
 'To‘g‘ri: producer surplus sotilgan miqdorgacha supply curve ustida va bozor narxi ostidagi maydon.',
 'Correct: producer surplus is the area above the supply curve and below the market price up to the quantity sold.',
 'Свяжите supply curve с минимально приемлемой ценой продавца.',
 'Supply curveni sotuvchining minimum acceptable price bilan bog‘lang.',
 'Link the supply curve to the seller’s minimum acceptable price.',
 'Market','Producer surplus','{}'::jsonb,'published'),
(1133,'mcq_option','C','Above the demand curve and below the market price',false,'consumer_producer_curve_confusion','Producer surplus vs demand curve',
 'Producer surplus связан с supply curve, а не с demand curve.',
 'Producer surplus demand curve bilan emas, supply curve bilan bog‘liq.',
 'Producer surplus is linked to the supply curve, not the demand curve.',
 'Различайте demand-side consumer surplus и supply-side producer surplus.',
 'Demand-side consumer surplus va supply-side producer surplusni farqlang.',
 'Distinguish demand-side consumer surplus from supply-side producer surplus.',
 'Market','Producer surplus','{}'::jsonb,'published'),
(1133,'mcq_option','D','Above the market price and above the supply curve',false,'producer_surplus_price_boundary_error','Producer surplus diagram',
 'Область producer surplus находится ниже рыночной цены, потому что цена — верхняя граница полученной производителем суммы на единицу.',
 'Producer surplus bozor narxidan pastda joylashadi, chunki narx ishlab chiqaruvchi oladigan birlik daromadining yuqori chegarasidir.',
 'Producer surplus lies below the market price because the price is the upper boundary of what the producer receives per unit.',
 'Проверьте верхнюю и нижнюю границы области producer surplus.',
 'Producer surplus maydonining yuqori va pastki chegaralarini tekshiring.',
 'Check the upper and lower boundaries of the producer-surplus area.',
 'Market','Producer surplus','{}'::jsonb,'published');