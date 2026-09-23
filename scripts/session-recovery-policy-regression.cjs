'use strict';
const assert = require('node:assert/strict');
const {decide,reconcileUnknownWrite} = require('../exam-prep/exam-prep-session-recovery-policy-v1.js');
const sessionId='00000000-0000-4000-8000-000000000001';
const planId='00000000-0000-4000-8000-000000000002';
const base={contract_version:'active_plan_session_v1',component_code:'P1',status:'resume',
  active_session_count:1,session_id:sessionId,session_type:'learning',answered_items:3,total_items:4,
  first_unanswered_item_order:4,source_plan_status:'superseded',source_plan_week:1,
  resume_independent_of_current_plan:true};
const run=(lookup,component='P1',goalRoute)=>decide({component,lookup,goalRoute});
assert.deepEqual(run(base),{ok:true,action:'resume',sessionId,firstUnansweredItemOrder:4});
assert.deepEqual(run({...base,source_plan_status:'active',source_plan_week:2}),
  {ok:true,action:'resume',sessionId,firstUnansweredItemOrder:4});
assert.deepEqual(run({...base,status:'ready_to_finalize',answered_items:4,first_unanswered_item_order:null}),
  {ok:true,action:'resume',sessionId,firstUnansweredItemOrder:null});
assert.equal(run({...base,component_code:'P5'}).reason,'unverified_session_lookup');
assert.equal(run(base,'P5').reason,'unverified_session_lookup');
assert.equal(run({...base,session_id:'forged'}).reason,'invalid_resume_evidence');
assert.equal(run({...base,active_session_count:2,status:'multiple_active'}).reason,'multiple_active_sessions');
assert.equal(run({...base,status:'finalized'}).reason,'unexpected_lookup_state');
assert.equal(run({...base,status:'resume',first_unanswered_item_order:5}).reason,'invalid_resume_position');
assert.equal(run({...base,status:'ready_to_finalize',first_unanswered_item_order:null}).reason,'invalid_finalize_position');
assert.equal(run({...base,status:'resume',answered_items:4}).reason,'invalid_resume_position');
const none={contract_version:'active_plan_session_v1',component_code:'P1',status:'none',active_session_count:0};
assert.equal(run(none).reason,'no_verified_new_action');
assert.deepEqual(run(none,'P1',{ok:true,action:'launch',planId,priorityOrder:2}),
  {ok:true,action:'launch',planId,priorityOrder:2});
assert.equal(run({...none,session_id:sessionId},'P1',{ok:true,action:'launch',planId,priorityOrder:2}).reason,
  'unexpected_lookup_state');
assert.equal(run(null).reason,'unverified_session_lookup');
assert.equal(reconcileUnknownWrite({writeStatus:'unknown'}).reason,'server_read_required');
assert.deepEqual(reconcileUnknownWrite({writeStatus:'unknown',serverItem:{answered:true}}),
  {ok:true,action:'saved_do_not_replay'});
assert.equal(reconcileUnknownWrite({writeStatus:'unknown',serverItem:{answered:false}}).reason,
  'uncertain_write_do_not_auto_retry');
assert.equal(reconcileUnknownWrite({writeStatus:'success',serverItem:{answered:true}}).reason,'not_unknown_write');
console.log('PASS: same-session resume across supersession and rollover, P1/P5 isolation, finalization and no replay of uncertain writes');
