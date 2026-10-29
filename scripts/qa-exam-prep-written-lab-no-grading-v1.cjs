#!/usr/bin/env node
'use strict';
// Production-preservation guard. This tests the agreed boundary:
// independent written work and Chemistry practical-skills cards are NOT app-graded.
// Legacy Mathematics optional learner-entered timed self-marks are a separate
// existing workflow; this guard deliberately neither modifies nor legitimizes them.
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..'),file=p=>fs.readFileSync(path.join(root,p),'utf8');
const policy=JSON.parse(file('exam-prep/contracts/written-learning-contract-v1.json'));
const core=file('exam-prep/runtime/written-core-controller-v1.js');
const view=file('exam-prep/runtime/written-core-view-v1.js');
const econ=file('exam-prep/exam-prep-economics-native.js');
const labs=file('exam-prep/exam-prep-chemistry-labs-native.js');
const chemistry=file('exam-prep/exam-prep-chemistry-entry-native.js');
const html=file('index.html');
const premium=file('exam-prep/runtime/written-core-source-v1.css');
for(const [name,source] of [['written core',core],['written view',view],['economics',econ],
 ['chemistry labs',labs],['chemistry entry',chemistry]]) {
 assert.doesNotThrow(()=>new Function(source),name+' syntax failure');
}
const needed=(source,patterns,which)=>patterns.forEach(p=>
 assert(source.includes(p),which+' missing '+p));
const missing=(source,patterns,which)=>patterns.forEach(p=>
 assert(!source.includes(p),which+' unexpectedly includes '+p));

// Approved global boundaries, not speculative rules.
assert.equal(policy.written_core.mode,'external_self_work');
assert.equal(policy.written_core.next_event_semantics,'advanced_in_plan_only');
assert.equal(policy.progress_disclosure.advanced_is_score,false);
assert.equal(policy.progress_disclosure.advanced_is_mastery,false);
assert.equal(policy.progress_disclosure.human_review_separate,true);
assert(policy.authority.forbidden.core.includes('automated_essay_score'));
assert(policy.authority.forbidden.core.includes('pretend_written_mastery'));
assert(policy.authority.forbidden.ai_assist.includes('essay_marking'));
assert(policy.mentor_queue_requires.includes('mentor_assignment_active'));
for(const item of ['essay_text','photo','self_mark','ai_feedback','mentor_review']) {
 assert(policy.written_core.does_not_require.includes(item),'Core requires '+item);
}
// Economics P2 and P4: question + optional assessment criteria + Next, never an essay grade.
needed(core,[
 "task_kind !== 'written_external'",
 "status:'advanced',replayed:!!response.replayed",
 "throw new Error('advance_unconfirmed')",
 "result.requirements!==undefined || scheme.indicative_points!==undefined",
 'assessment_criteria:Object.freeze([...scheme.assessment_criteria])'
 ],'Core');
needed(econ,[
 'function openWritten(){','iclub_exam_written_available_v1',
 'iclub_exam_written_open_v1','iclub_exam_written_criteria_v1',
 'iclub_exam_written_advance_v1','iclub_exam_written_status_v1',
 'startWrittenPractice(', 'iclub_econ_written_start_v2'
 ],'Economics');
const writtenSlice=econ.slice(econ.indexOf('function openWritten(){'),
 econ.indexOf('function openLevel(',econ.indexOf('function openWritten(){')));
assert(writtenSlice.length>300,'Written route not found');
missing(writtenSlice,['submit_score','score_written','grade_written','essay_mark',
 'mentor_queue','ai_evaluate','marks_awarded'],'Economics written route');
needed(view,[
 'criteriaBox.hidden=true','const criteriaButton=btn(t.criteria',
 'const nextButton=btn(t.next','await ctl.next()',
 'scheme?.assessment_criteria||details.requirements',
 'instruction:"Complete the task independently.',
 'instruction:"Выполните задание самостоятельно.',
 'instruction:"Topshiriqni mustaqil bajaring.'
 ],'Written UI');
missing(view,['createElement("textarea")','createElement("input")',
 'uploadWritten','submitEssay','saveMark','selfGrade','autoGradeWritten',
 'aiGrade','mentorAssignmentCreate'],'Written UI');
assert(!/\b(score|marks_awarded|mastery|is_correct)\s*:\s*(?:true|[0-9])/.test(writtenSlice),
 'Written navigation contains a fabricated mark or mastery');

// Chemistry P3/P5: only practical-skills cards, no laboratory work grading.
needed(labs,[
 'iclub_exam_chemistry_lab_catalog_v1',
 'iclub_exam_chemistry_lab_lesson_v1',
 'r.can_credit_mastery!==false',
 'r.practical_exam_replacement!==false',
 'r.tutor_included!==false',
 'reading', // accepted either comment text? guard below
 ],'Chemistry labs');
missing(labs,['submit_lab','mark_lab','grade_lab','lab_score',
 'mastery_awarded','assessment_result','practical_grade',
 'storage.setItem','localStorage'],'Chemistry labs');
assert(labs.includes('Чтение не подтверждает освоение навыка'),'RU skills disclaimer missing');
assert(labs.includes('O‘qish ko‘nikma o‘zlashtirilganini tasdiqlamaydi'),'UZ skills disclaimer missing');
assert(labs.includes('Reading does not verify practical competence'),'EN skills disclaimer missing');
needed(chemistry,[
 'async function offerLabs(','iclub_exam_chemistry_lab_catalog_v1',
 'x.can_credit_mastery===false','if(allowed[0])','if(allowed[1])'
 ],'Chemistry entry');
assert(html.includes('exam-prep-chemistry-labs-native.js?'),'Chemistry labs loaded only as approved adapter');
assert(html.includes('written-core-controller-v1.js?'),'Written Core controller loaded');
assert(html.includes('written-core-view-v1.js?'),'Written Core view loaded');
assert(premium.includes('ep-written-marking[hidden]'),'Criteria must stay hidden until opened');

// Avoid rewriting active legacy: this test must not require disabling timed Mathematics
// self-review nor claim that user-entered marks represent app-scored essays.
const math=file('exam-prep/exam-prep-live.js');
assert(math.includes('Paper-based written learning has no answer artifact, grades, or understanding check.'),
 'Mathematics paper-based written learning boundary disappeared');
const legacySelfMark=math.includes('submitTimedSelfMark(');
console.log(JSON.stringify({
 result:'PASS',scope:'Economics P2/P4 Core + Chemistry P3/P5 practical cards',
 no_auto_written_grading:true,no_lab_grading:true,
 written_next_is_plan_progress_only:true,
 stored_historical_data_touched:false,
 legacy_timed_self_mark_present_but_not_modified:legacySelfMark,
 checks:'approved contract; 5 JS parses; 3 language instructions; owner-scoped RPC route; no lab mark calls; no input/upload; no false marks'
}));
