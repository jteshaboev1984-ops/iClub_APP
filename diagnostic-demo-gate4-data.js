(()=>{'use strict';
const L=(en,ru,uz)=>({en,ru,uz});
const skills={
 utility_meaning:{label:L('Meaning of utility','Значение полезности','Naflilik mazmuni'),pair:'consumer_models'},
 diminishing_marginal_utility:{label:L('Diminishing marginal utility','Убывающая предельная полезность','Kamayib boruvchi chegaraviy naflilik'),pair:'consumer_models'},
 indifference_curve_definition:{label:L('Indifference curve','Кривая безразличия','Befarqlik egri chizig‘i'),pair:'consumer_models'},
 budget_line_income_shift:{label:L('Budget line after income change','Бюджетная линия после изменения дохода','Daromad o‘zgargandan keyingi budjet chizig‘i'),pair:'consumer_models'},
 allocative_efficiency_condition:{label:L('Allocative efficiency: P = MC','Аллокативная эффективность: P = MC','Allokativ samaradorlik: P = MC'),pair:'efficiency_conditions'},
 productive_efficiency_condition:{label:L('Productive efficiency: minimum AC','Производственная эффективность: минимум AC','Ishlab chiqarish samaradorligi: minimum AC'),pair:'efficiency_conditions'},
 profit_maximisation_condition:{label:L('Profit maximisation: MR = MC','Максимизация прибыли: MR = MC','Foydani maksimallashtirish: MR = MC'),pair:'efficiency_conditions'},
 internal_external_growth:{label:L('Internal and external growth','Внутренний и внешний рост','Ichki va tashqi o‘sish'),pair:'growth_methods'},
 external_private_cost:{label:L('External and private cost','Внешние и частные издержки','Tashqi va xususiy xarajat'),pair:'market_failure'},
 public_good_characteristics:{label:L('Public-good characteristics','Характеристики общественного блага','Jamoat ne’mati xususiyatlari'),pair:'market_failure'},
 free_rider_mechanism:{label:L('Free-rider mechanism','Механизм безбилетника','Bepul foydalanuvchi mexanizmi'),pair:'market_failure'},
 price_taker_meaning:{label:L('Price taker','Ценополучатель','Narxni qabul qiluvchi'),pair:'market_structure'},
 barriers_to_entry:{label:L('Barriers to entry','Барьеры входа','Kirish to‘siqlari'),pair:'market_structure'},
 contestability_meaning:{label:L('Contestability','Конкурентоспособность рынка','Bozorning contestability darajasi'),pair:'market_structure'},
 economies_of_scale:{label:L('Economies of scale','Экономия от масштаба','Masshtab samarasi'),pair:'firm_costs'},
 market_structure_features:{label:L('Market-structure features','Признаки рыночной структуры','Bozor tuzilmasi belgilari'),pair:'market_structure'},
 normal_profit:{label:L('Normal profit','Нормальная прибыль','Normal foyda'),pair:'firm_costs'},
 price_discrimination:{label:L('Price discrimination','Ценовая дискриминация','Narx diskriminatsiyasi'),pair:'firm_behaviour'},
 x_inefficiency:{label:L('X-inefficiency','X-неэффективность','X-samarasizlik'),pair:'firm_behaviour'},
 labour_demand:{label:L('Demand for labour','Спрос на труд','Mehnatga talab'),pair:'labour_market'},
 wage_determination:{label:L('Wage determination','Определение заработной платы','Ish haqini belgilash'),pair:'labour_market'},
 monopoly_revenue:{label:L('Monopoly revenue','Выручка монополии','Monopoliya tushumi'),pair:'firm_behaviour'},
 oligopoly_interdependence:{label:L('Oligopoly interdependence','Взаимозависимость в олигополии','Oligopoliyada o‘zaro bog‘liqlik'),pair:'market_structure'},
 sunk_costs:{label:L('Sunk costs','Невозвратные издержки','Qaytmas xarajatlar'),pair:'market_structure'}
};
const currentMap={d1:'utility_meaning',d2:'diminishing_marginal_utility',d3:'indifference_curve_definition',d4:'budget_line_income_shift',d5:'allocative_efficiency_condition',d6:'productive_efficiency_condition',d7:'internal_external_growth'};
const distractors={
 d1:{A:'production_cost',B:'correct_utility',C:'firm_profit',D:'market_price'},
 d2:{A:'total_vs_marginal_confusion',B:'correct_dmu',C:'price_causation',D:'zero_utility_claim'},
 d3:{A:'correct_indifference_curve',B:'isoquant_production_confusion',C:'budget_set_confusion',D:'firm_profit_confusion'},
 d4:{A:'correct_parallel_outward_shift',B:'price_change_rotation',C:'curve_type_confusion',D:'income_effect_ignored'},
 d5:{A:'correct_allocative_efficiency',B:'break_even_confusion',C:'productive_efficiency_confusion',D:'revenue_maximisation_confusion'},
 d6:{A:'correct_productive_efficiency',B:'allocative_efficiency_confusion',C:'break_even_confusion',D:'profit_maximisation_confusion'},
 d7:{A:'correct_internal_growth_internal_finance',B:'finance_source_growth_method_confusion',C:'merger_confusion',D:'ownership_change_confusion'}
};
const tour4Answers=[
 ['t4q01','utility_meaning','C',false,'firm_profit'],
 ['t4q02','diminishing_marginal_utility','B',true,null],
 ['t4q03','indifference_curve_definition','B',false,'isoquant_production_confusion'],
 ['t4q04','budget_line_income_shift','A',true,null],
 ['t4q05','allocative_efficiency_condition','B',false,'break_even_confusion'],
 ['t4q06','productive_efficiency_condition','B',false,'allocative_efficiency_confusion'],
 ['t4q07','profit_maximisation_condition','A',false,'productive_efficiency_confusion'],
 ['t4q08','barriers_to_entry','C',true,null],
 ['t4q09','internal_external_growth','B',false,'finance_source_growth_method_confusion'],
 ['t4q10','external_private_cost','B',false,'external_private_cost_confusion'],
 ['t4q11','public_good_characteristics','C',false,'free_rider_characteristic_confusion'],
 ['t4q12','free_rider_mechanism','A',true,null],
 ['t4q13','price_taker_meaning','B',false,'price_maker_confusion'],
 ['t4q14','contestability_meaning','C',false,'concentration_contestability_confusion'],
 ['t4q15','economies_of_scale','D',false,'average_marginal_cost_confusion'],
 ['t4q16','market_structure_features','A',true,null],
 ['t4q17','allocative_efficiency_condition','B',false,'break_even_confusion'],
 ['t4q18','productive_efficiency_condition','B',false,'allocative_efficiency_confusion'],
 ['t4q19','internal_external_growth','C',false,'merger_internal_growth_confusion'],
 ['t4q20','normal_profit','A',true,null]
].map((r,i)=>({evidenceId:`tour4:${r[0]}`,attemptId:'tour4',questionId:r[0],order:i+1,skillId:r[1],selected:r[2],correct:r[3],diagnosisId:r[4],difficulty:i<6?'easy':i<15?'medium':'hard',qtype:'mcq',timeSpent:42+(i%5)*7,timeLimit:i<6?55:i<15?65:75,newQuestion:false,assisted:false}));
const practice4Skills=['price_discrimination','x_inefficiency','labour_demand','wage_determination','monopoly_revenue','oligopoly_interdependence','sunk_costs','market_structure_features','normal_profit','barriers_to_entry'];
const practice4Answers=practice4Skills.map((skillId,i)=>({evidenceId:`practice4:p4q${String(i+1).padStart(2,'0')}`,attemptId:'practice4',questionId:`p4q${String(i+1).padStart(2,'0')}`,order:i+1,skillId,selected:'A',correct:true,diagnosisId:null,difficulty:i<3?'easy':i<8?'medium':'hard',qtype:'mcq',timeSpent:35+(i%4)*6,timeLimit:60,newQuestion:true,assisted:false}));
const attempts=[
 {id:'practice1',kind:'practice',no:1,score:10,total:10,date:'2026-05-12',seconds:482,role:'prior_program',coverage:['scarcity','ppc','demand_supply']},
 {id:'practice2',kind:'practice',no:2,score:10,total:10,date:'2026-05-19',seconds:506,role:'prior_program',coverage:['government_intervention','macro_indicators']},
 {id:'practice3',kind:'practice',no:3,score:10,total:10,date:'2026-05-26',seconds:471,role:'prior_program',coverage:['macro_policy','international_trade']},
 {id:'tour4',kind:'tour',no:4,score:6,total:20,date:'2026-06-02',seconds:1148,role:'historical_core',coverage:[...new Set(tour4Answers.map(x=>x.skillId))],answers:tour4Answers},
 {id:'practice4',kind:'practice',no:4,score:10,total:10,date:'2026-06-06',seconds:524,role:'post_tour_random',coverage:practice4Skills,answers:practice4Answers}
];
const reinforcement=[
 ['reinforce_01','utility_meaning',L('Utility or profit?','Полезность или прибыль?','Naflilikmi yoki foydami?'),'easy'],
 ['reinforce_02','indifference_curve_definition',L('Indifference curve or isoquant?','Кривая безразличия или изокванта?','Befarqlik egri chizig‘imi yoki izokvanta?'),'medium'],
 ['reinforce_03','allocative_efficiency_condition',L('Choose the condition for allocative efficiency','Выберите условие аллокативной эффективности','Allokativ samaradorlik shartini tanlang'),'medium'],
 ['reinforce_04','productive_efficiency_condition',L('Choose the condition for productive efficiency','Выберите условие производственной эффективности','Ishlab chiqarish samaradorligi shartini tanlang'),'medium'],
 ['reinforce_05','profit_maximisation_condition',L('Separate MR = MC from minimum AC','Отделите MR = MC от минимума AC','MR = MC ni minimum AC dan ajrating'),'hard'],
 ['reinforce_06','internal_external_growth',L('Classify growth method and finance source','Разделите способ роста и источник финансирования','O‘sish usuli va moliya manbasini ajrating'),'hard'],
 ['reinforce_07','external_private_cost',L('Private cost or external cost?','Частные или внешние издержки?','Xususiy yoki tashqi xarajat?'),'medium'],
 ['reinforce_08','public_good_characteristics',L('Public-good features and free riding','Общественное благо и безбилетник','Jamoat ne’mati va bepul foydalanuvchi'),'medium'],
 ['reinforce_09','price_taker_meaning',L('Price taker and market power','Ценополучатель и рыночная власть','Narxni qabul qiluvchi va bozor kuchi'),'easy'],
 ['reinforce_10','contestability_meaning',L('Contestability and entry conditions','Конкурентоспособность и условия входа','Contestability va kirish shartlari'),'hard']
].map((r,i)=>({id:r[0],skillId:r[1],title:r[2],difficulty:r[3],order:i+1,source:`iClub Economics · verified set · ${r[0]}`,verified:true,activeTour:false}));
window.ICLUB_DEMO_GATE4_DATA={version:'1.2-gate-4',skills,currentMap,distractors,attempts,reinforcement,statuses:['insufficient','needs_verification','current_session','new_question','delayed','transfer'],pairs:{consumer_models:['utility_meaning','diminishing_marginal_utility','indifference_curve_definition','budget_line_income_shift'],efficiency_conditions:['allocative_efficiency_condition','productive_efficiency_condition','profit_maximisation_condition'],growth_methods:['internal_external_growth']}};
})();