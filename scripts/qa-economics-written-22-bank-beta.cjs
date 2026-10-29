#!/usr/bin/env node
'use strict';
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const migration=read('supabase/migrations/20261029130000_iclub_economics_written_complete_22_beta_v1.sql');
const contract=JSON.parse(read('exam-prep/contracts/written-learning-contract-v1.json'));
const view=read('exam-prep/runtime/written-core-view-v1.js');
const controller=read('exam-prep/runtime/written-core-controller-v1.js');
const native=read('exam-prep/exam-prep-economics-native.js');
const held=['P2.B1.b','P2.B2.a','P2.B2.b','P2.C1.b','P2.C2.a','P2.C2.b','P4.A.b','P4.A.d','P4.B2','P4.C2'];
const all=[
 'P2.A.a','P2.A.b','P2.A.c','P2.A.d','P2.A.e','P2.A.f',
 'P2.B1.a','P2.B1.b','P2.B2.a','P2.B2.b',
 'P2.C1.a','P2.C1.b','P2.C2.a','P2.C2.b',
 'P4.A.a','P4.A.b','P4.A.c','P4.A.d',
 'P4.B1','P4.B2','P4.C1','P4.C2'
];
assert.equal(all.length,22);
assert.equal(new Set(all).size,22);
assert.equal(held.length,10);
for(const key of held)assert(all.includes(key),'Held task outside reviewed bank: '+key);
const expected=(arr)=>arr.map(x=>"'"+x+"'").join(',');
assert(migration.includes(expected(all)),'Future Start must assign all 22 canonical tasks in P2 then P4 order');
assert(migration.includes(expected(held)),'Existing learner must receive exactly ten follow-on tasks');
assert(migration.includes('v_last+h.ordinal::integer'),'Keep historic order and add only at the end');
assert(migration.includes('priority_order<=12 AND status'),'Existing task progress never rewritten');
assert(migration.includes('FOR UPDATE'),'Protect against competing plan writes');
assert(migration.includes("WHERE program_key='economics_9708'"),'Only Economics content scoped');
assert(migration.includes("task_version='economics_9708_written_editorial_candidate_v3_20261027'"),'Immutable approved version required');
assert(migration.includes('private.iclub_exam_written_source_ready_v1('),'Sources must be valid');
assert(migration.includes("status='approved'")&&migration.includes("language_review='approved'"),'Academic/language gate required');
assert(migration.includes('m.task_sha256=encode('),'Rubrics bound to task content hash');
assert(migration.includes('v_reserved<>10 OR v_ready<>22'),'All released tasks must be reviewed and validated');
assert(migration.includes('WHERE p.learner_user_id=v_user') || migration.includes('WHERE p.learner_user_id=v_user AND'),'Only owner may receive plans');
assert(migration.includes('private.iclub_econ_written_beta_eligible_v1(v_user)'),'Retain existing beta gate');
assert(migration.includes('WHERE singleton FOR UPDATE'),'Keep seat limit atomic');
assert(migration.includes("now()+INTERVAL '28 days'"),'Never silently extend prior entitlement');
assert(migration.includes('count(*) FROM private.iclub_exam_core_written_access_v1'),'Keep beta capacity');
assert(!/\bDELETE\s+FROM\b|\bTRUNCATE\b|\bDROP\s+TABLE\b|\bUPDATE\s+private\.iclub_exam_core_written_plan_items_v1\b/i.test(migration),
  'No history clearing or reprioritizing existing plans');
assert(!/\bUPDATE\s+private\.iclub_exam_core_written_access_v1\b/i.test(migration),'No existing entitlements updated');
assert(!migration.includes("SET status='advanced'"),'No fabricated written completion');
assert(!migration.includes('INSERT INTO private.iclub_econ_written_beta_optins_v1'),'No extra consent forms');
assert(migration.includes('REVOKE ALL ON FUNCTION public.iclub_econ_written_start_v2() FROM PUBLIC,anon,authenticated'),'No anonymous access');
assert.equal(contract.written_core.next_event_semantics,'advanced_in_plan_only');
assert.equal(contract.progress_disclosure.advanced_is_score,false);
assert.equal(contract.progress_disclosure.advanced_is_mastery,false);
assert(view.includes('scheme?.assessment_criteria||details.requirements'),'Only AO criteria, not solutions');
assert(controller.includes('scheme.indicative_points!==undefined'),'Reject indicative answers leaked to Core');
assert(native.includes('iclub_econ_written_start_v2'),'Native UI uses the updated server function name');
new Function(native);new Function(view);new Function(controller);
console.log('ECONOMICS WRITTEN 22-BANK EXTENSION PASS — 10 held tasks, 22 approved routes, append-only progress, beta & no-grading boundaries');
