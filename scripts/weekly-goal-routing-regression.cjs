'use strict';
const assert = require('node:assert/strict');
const {resolve} = require('../exam-prep/exam-prep-weekly-goal-routing-v1.js');
const p = {contract_version:'progress_ux_v1',component_code:'P1',active_week_no:1,goals:[
  {goal_id:'goal-cir',component_code:'P1',action_priority_order:2,item_type:'correction',skill_code:'P1-CIR-01',status:'in_progress',weekly_commitment_complete:false},
  {goal_id:'goal-coo',component_code:'P1',action_priority_order:1,item_type:'correction',skill_code:'P1-COO-02',status:'not_started',weekly_commitment_complete:false}
]};
const plan = {plan_id:'current-plan',component_code:'P1',active_week_no:1,items:[
  {priority_order:1,item_type:'correction',skill_code:'P1-COO-02',status:'pending'},
  {priority_order:2,item_type:'correction',skill_code:'P1-CIR-01',status:'pending'}
]};
const eligible = (goal,item,status='ready') => ({component_code:'P1',plan_id:'current-plan',goal_id:goal.goal_id,
  priority_order:item.priority_order,skill_code:item.skill_code,item_type:item.item_type,status});
const [cir,coo]=p.goals;
const good=(goal,item)=>resolve({component:'P1',progress:p,goal,plan,eligibility:eligible(goal,item)});
assert.deepEqual(good(cir,plan.items[1]),{ok:true,action:'launch',planId:'current-plan',priorityOrder:2});
assert.deepEqual(good(coo,plan.items[0]),{ok:true,action:'launch',planId:'current-plan',priorityOrder:1});
const bad=(params,reason)=>assert.equal(resolve(Object.assign({component:'P1',progress:p,goal:cir,plan,eligibility:eligible(cir,plan.items[1])},params)).reason,reason);
bad({component:'P5'},'bad_progress');
bad({goal:Object.assign({},cir,{goal_id:'forged'})},'foreign_goal');
bad({plan:Object.assign({},plan,{plan_id:'old-plan'})},'eligibility_not_verified');
bad({plan:Object.assign({},plan,{active_week_no:2})},'stale_plan');
bad({goal:Object.assign({},cir,{action_priority_order:1})},'skill_changed');
bad({plan:Object.assign({},plan,{items:[...plan.items,{...plan.items[1],priority_order:3}]})},'ambiguous_binding');
bad({goal:Object.assign({},cir,{weekly_commitment_complete:true})},'goal_not_open');
bad({eligibility:eligible(cir,plan.items[1],'content_exhausted')},'server_not_ready');
bad({eligibility:Object.assign(eligible(cir,plan.items[1],'blocked'),{reason:'content_exhausted'})},'content_exhausted');
const retest={...plan.items[1],item_type:'retest',due_at:'2026-09-20T00:00:00Z'};
const waiting={...cir,status:'waiting_retest',weekly_commitment_complete:true};
bad({plan:{...plan,items:[plan.items[0],retest]},goal:waiting,eligibility:eligible(waiting,retest),now:Date.parse('2026-09-19')},'retest_not_due');
assert.deepEqual(resolve({component:'P1',progress:p,goal:waiting,plan:{...plan,items:[plan.items[0],retest]},
 eligibility:eligible(waiting,retest),now:Date.parse('2026-09-21')}),
 {ok:true,action:'launch',planId:'current-plan',priorityOrder:2});
assert.deepEqual(resolve({component:'P1',progress:p,goal:cir,plan,eligibility:{...eligible(cir,plan.items[1],'resume'),session_id:'existing-session'}}),
 {ok:true,action:'resume',sessionId:'existing-session'});
console.log('PASS: reordered goals, stale plan, identity, duplicates, exhausted content, due date and resume');
