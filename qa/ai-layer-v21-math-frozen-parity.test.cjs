// node --test qa/ai-layer-v21-math-frozen-parity.test.cjs
// Safety contract: preserve all existing Mathematics Exam Prep functionality.
'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const {createHash}=require('node:crypto');
const meta=require('./ai-layer-v21-math-frozen-baseline.json');
const read=(p)=>fs.readFileSync(p,'utf8');
const gitBlobSha=(file)=>{
 const data=fs.readFileSync(file);
 const sha=createHash('sha1');
 sha.update('blob '+data.length+'\0');sha.update(data);
 return sha.digest('hex');
};
const ui=read('exam-prep/exam-prep-ai-ui.js');
const live=read('exam-prep/exam-prep-live.js');
const edge=read('supabase/functions/exam-prep-ai/index.ts');
const isolation=read('scripts/exam-prep-subject-isolation-regression.cjs');
const global=read('global-ai-ui.js');
const draft=read('qa/sql_drafts/iclub_ai_v21_meter_v2_UNAPPLIED.sql');

test('Frozen original Exam Prep file hashes equal verified production baseline',()=>{
 for(const [file,expected] of Object.entries(meta.frozenFiles)){
   assert.equal(gitBlobSha(file),expected,'Legacy Exam Prep file changed: '+file);
 }
});
test('Existing two-component Math-only host remains isolated from other subjects',()=>{
 assert.match(live,/requestedSubject\s*===\s*"mathematics"/);
 assert.match(live,/hubSubject\s*===\s*"mathematics"/);
 assert.match(live,/context\?\.subjectKey[\s\S]*?!==\s*"mathematics"\)\s*reset\(\)/);
 for(const component of ['P1','P5'])assert.ok(live.includes(component));
});
test('Previously fixed cross-subject regression covers Economics and Informatics',()=>{
 for(const subject of meta.requiredContract.otherSubjectScreens){
  assert.ok(isolation.includes('"'+subject+'"'),'Isolation missing '+subject);
 }
 assert.ok(isolation.includes('must not query Mathematics examProfile'));
 assert.ok(isolation.includes('must not query P1/P5'));
});
test('Existing Tutor remains on the existing Edge endpoint, never silently redirected',()=>{
 assert.equal((ui.match(/client\.functions\.invoke\("exam-prep-ai"/g)||[]).length,2);
 assert.ok(!ui.includes('client.functions.invoke("global-ai"'));
 assert.ok(!edge.includes('reserve_iclub_ai_usage_service_v2('));
});
test('Original AI thread retains approved followup boundaries and typed modes',()=>{
 assert.ok(ui.includes('const MAX_THREAD_STEPS = 5'));
 assert.ok(ui.includes('const MAX_GENERATED_FOLLOWUPS = 2'));
 assert.ok(ui.includes('const MAX_FOLLOWUP_CHARS = 250'));
 assert.ok(ui.includes('new WeakMap()'));
 for(const mode of ['simplify','rephrase','focus'])assert.ok(ui.includes('"'+mode+'"'));
 assert.ok(ui.includes('parent_request_id: state.parentRequestId'));
});
test('Legacy Tutor card fields, locale and course code RPC stay untouched',()=>{
 assert.ok(edge.includes('"get_exam_prep_ai_tutor_card_service_v1"'));
 for(const key of meta.requiredContract.preparedTutorSourceFields)assert.ok(edge.includes('"'+key+'"'));
 for(const v of ['"P1"','"P5"'])assert.ok(ui.includes(v)||edge.includes(v));
 assert.ok(ui.includes('currentLanguage()'));
});
test('New global AI cannot call or overwrite legacy Exam Prep transport',()=>{
 assert.ok(global.includes('client.functions.invoke("global-ai"'));
 assert.ok(!global.includes('client.functions.invoke("exam-prep-ai"'));
 assert.ok(!global.includes('window.iClubExamPrep ='));
 assert.ok(!global.includes('iClubExamPrepHostInternal ='));
});
test('Unapplied SQL cannot edit existing Maths Tutor or legacy subscriber quota',()=>{
 assert.ok(!draft.includes('exam_prep_ai_tutor_cards'));
 assert.ok(!draft.includes('private.exam_prep_feature_entitlements'));
 assert.ok(!draft.includes('private.exam_prep_feature_config'));
 assert.ok(!draft.includes('update private.iclub_ai_usage_policies'));
 assert.ok(draft.includes('plus_qa_v2'));
 assert.ok(draft.includes('pro_qa_v2'));
});
test('Existing AI safety and assessment controls remain in original server route',()=>{
 assert.ok(edge.includes('active_assessment'));
 assert.ok(edge.includes('get_exam_prep_ai_tutor_card_service_v1'));
 assert.ok(edge.includes('get_exam_prep_ai_thread_parent_service_v1'));
 assert.ok(edge.includes('get_exam_prep_ai_error_context_safe_v1'));
});
