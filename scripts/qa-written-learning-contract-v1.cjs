#!/usr/bin/env node
// Offline contract QA. Does not load the iClub app or connect to the database.
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const c = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'exam-prep', 'contracts', 'written-learning-contract-v1.json'), 'utf8'));
let passed = 0;
const test = (name, fn) => { fn(); console.log('PASS ' + (++passed) + ' ' + name); };
const has = (xs, v) => assert.ok(xs.includes(v), 'missing ' + v);
test('design-only; not activated', () => assert.equal(c.status, 'DESIGN_ONLY_NOT_LEARNER_RUNTIME'));
test('contract is multisubject', () => assert.equal(c.scope, 'all_exam_prep_subjects'));
test('core task and criteria', () => {has(c.authority.core,'task_delivery');has(c.authority.core,'criteria_display');});
test('core forbidden essay scoring', () => has(c.authority.forbidden.core,'automated_essay_score'));
test('AI is explanation-only', () => assert.deepEqual(c.authority.ai_assist.slice().sort(),['approved_theory_explanation','criteria_meaning_explanation','established_error_explanation'].sort()));
test('AI forbidden as essay grader', () => {has(c.authority.forbidden.ai_assist,'essay_marking');has(c.authority.forbidden.ai_assist,'essay_scoring');});
test('AI forbidden independent plan change', () => has(c.authority.forbidden.ai_assist,'independent_plan_mutation'));
test('mentor checks human written work only', () => has(c.authority.mentor_care,'human_written_review_with_active_assignment'));
test('mentor queue requires both entitlement and assignment', () => assert.deepEqual(c.mentor_queue_requires,['mentor_care_entitled','mentor_assignment_active']));
test('student actions only view and next', () => assert.deepEqual(c.written_core.required_student_actions,['view_task','next']));
test('criteria optional', () => has(c.written_core.optional_student_actions,'view_criteria'));
test('no required input/submissions', () => assert.equal(c.written_core.required_submissions.length,0));
test('no required essay/photo', () => {has(c.written_core.does_not_require,'essay_text');has(c.written_core.does_not_require,'photo');});
test('no required checklist/self mark', () => {has(c.written_core.does_not_require,'self_mark');has(c.written_core.does_not_require,'checklist');});
test('no required AI/mentor review', () => {has(c.written_core.does_not_require,'ai_feedback');has(c.written_core.does_not_require,'mentor_review');});
test('criteria are not model essay or feedback', () => {has(c.written_core.criteria_are_not,'model_essay');has(c.written_core.criteria_are_not,'personal_feedback');});
test('next advances plan only', () => assert.equal(c.written_core.next_event_semantics,'advanced_in_plan_only'));
test('next never creates academic mark/mastery', () => {has(c.written_core.next_must_not_produce,'academic_score');has(c.written_core.next_must_not_produce,'objective_mastery');});
test('next never creates AI/mentor job', () => {has(c.written_core.next_must_not_produce,'mentor_queue_item');has(c.written_core.next_must_not_produce,'ai_evaluation');});
test('next idempotent', () => assert.equal(c.written_core.next_idempotency_required,true));
test('offline no false saved state', () => assert.equal(c.written_core.offline_must_not_claim_server_confirmation,true));
test('ordinary criteria on request', () => assert.equal(c.written_core.normal_practice_criteria,'on_explicit_request'));
test('timed paper criteria after finalized attempt', () => assert.equal(c.written_core.paper_simulation_specific_criteria,'after_attempt_finalized'));
test('never infer server access from plan label', () => assert.equal(c.client_plan_name_does_not_grant_access,true));
for(const locale of ['ru','uz','en']){
 test(locale+' required UI labels',()=>{for(const name of ['criteria','requirements','next','mentor_hint'])assert.ok(typeof c.ui_copy[locale][name]==='string'&&c.ui_copy[locale][name].length>1);});
}
test('Economics stays closed', () => {assert.equal(c.economics_9708.status,'DRAFT_LAUNCH_OFF');assert.equal(c.economics_9708.written_draft_publication_allowed,false);});
test('P2 and P4 are 120min / 60mark',()=>{for(const p of ['P2','P4']){const v=c.economics_9708.papers[p];assert.equal(v.minutes,120);assert.equal(v.max_marks,60);assert.equal(v.section_a_marks+v.section_b_marks+v.section_c_marks,60);}});
test('P2 structured and P4 unstructured',()=>{assert.equal(c.economics_9708.papers.P2.essay_structure,'structured');assert.equal(c.economics_9708.papers.P4.essay_structure,'unstructured');});
test('8+12 subpart split is not official',()=>assert.equal(c.economics_9708.structured_subpart_8_12_is_official,false));
test('legacy protection complete',()=>{for(const s of ['mathematics_legacy_adapter','practice','tours','existing_sessions','existing_responses','user_progress','local_storage'])has(c.legacy_preservation,s);});
test('academic and browser release gates present',()=>{for(const g of ['approved_specific_criteria','security_qa','browser_regression','no_student_data_loss','explicit_program_enable_after_all_gates'])has(c.publication_gates,g);});
console.log('PASS: '+passed+'/'+passed+' checks. No backend or learner data changed.');
