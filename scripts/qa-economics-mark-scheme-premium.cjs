#!/usr/bin/env node
'use strict';
const fs=require('node:fs'),assert=require('node:assert/strict'),vm=require('node:vm');
const path=require('node:path'),base=path.resolve(__dirname,'..');
const file=p=>fs.readFileSync(path.join(base,p),'utf8');
const migration=file('supabase/migrations/20261028052330_iclub_econ_written_mark_scheme_v1.sql');
const view=file('exam-prep/runtime/written-core-view-v1.js');
const controller=file('exam-prep/runtime/written-core-controller-v1.js');
const native=file('exam-prep/exam-prep-economics-native.js');
const css=file('exam-prep/runtime/written-core-source-v1.css');
const html=file('index.html');
new Function(view);new Function(native);new Function(controller);
const allocation=[...migration.matchAll(/\('((?:P2|P4)\.[A-C](?:\d)?\.[abcfde]|P4\.[BC][12])',(\d+),(\d+),(\d+)\)/g)];
assert.equal(allocation.length,22,'All 22 v3 task parts must have a scheme');
const row=Object.fromEntries(allocation.map(m=>[m[1],[Number(m[2]),Number(m[3]),Number(m[4])]]));
assert.equal(Object.keys(row).length,22,'No duplicate keys');
for(const [key,[total,a12,a3]] of Object.entries(row))
 assert.equal(total,a12+a3,'Unbalanced AO marks: '+key);
for(const paper of ['P2','P4'])
 assert.equal(Object.entries(row).filter(([key])=>key.startsWith(paper+'.A.'))
  .reduce((n,[,x])=>n+x[0],0),20,'Section A must total 20 marks');
for(const [key,[total,a12,a3]] of Object.entries(row))if(key.includes('.B')||key.includes('.C'))
 assert([8,12,20].includes(total) &&
  (total===8?a12===8&&a3===0:total===12?a12===8&&a3===4:a12===14&&a3===6),
 'Essay AO split wrong: '+key);
assert(migration.includes('task_sha256='),'Source task versions cannot silently change scheme');
assert(migration.includes('i.learner_user_id=auth.uid()'),'Marking scheme must be owner-bound');
assert(migration.includes('private.iclub_exam_written_source_ready_v1('),'Revoked sources still denied');
assert(!/UPDATE\s+private\.iclub_exam_core_written_tasks_v1|DELETE\s+FROM\s+private\.iclub_exam_core_written/i.test(migration),'No legacy user mutations');
assert(migration.includes('REVOKE ALL ON private.iclub_exam_written_mark_scheme_v1'),'Rubric table must be private');
for(const t of ['ru','uz','en']) {
 assert(view.includes(t+':{title:'),'All locale text required: '+t);
 assert(native.includes(t+':{'),'All native home copy required: '+t);
}
assert(view.includes('scheme.ao12_marks')&&view.includes('scheme.ao3_marks'),'Numeric marks and AO split displayed');
assert(view.includes('scheme?.indicative_points||details.requirements'),'Response-specific creditable content required');
assert(view.includes('scheme.max_marks+" "+t.marks'),'Max marks visible');
assert(controller.includes('scheme.marking_style'),'Controller must validate grading style');
assert(view.includes('ep-written-level-row'),'Level bands displayed for essays');
assert(view.includes('scheme.style==="levels"'),'Levels-based essays only');
assert(view.includes('criteriaBox.hidden=true'),'Marking criteria hidden before deliberate click');
assert(view.includes('t.notOfficial'),'Practice scheme must not be falsely labeled official');
assert(!native.includes('Согласен, начать')&&!native.includes('I agree, start')
 &&!native.includes('Roziman, boshlash'),'No unnecessary consent prompt in UI');
assert(native.includes('Начать письменную практику')&&native.includes('Yozma mashqlarni boshlash')
 &&native.includes('Start written practice'),'Single Start action translated');
assert(!native.includes('if(state.betaInvite&&!state.writtenPlan&&window.iClubWrittenCoreViewV1)'),'No duplicate consent banner');
assert(native.includes('rpc("iclub_econ_written_beta_join_v1",{p_confirm:true})'),
 'Server eligibility preserved behind a direct Start action');
assert(css.includes('ep-written-mark-breakdown')&&css.includes('ep-written-actions')&&css.includes('ep-written-marking[hidden]'),'Premium CSS must honor layout and hidden controls');
for(const needle of ['written-core-view-v1.js?v=econ-mark-scheme-premium-20261028',
 'written-core-controller-v1.js?v=econ-mark-scheme-premium-20261028',
 'written-core-source-v1.css?v=econ-mark-scheme-premium-20261028',
 'exam-prep-economics-native.js?v=econ-mark-scheme-premium-20261028'])
 assert(html.includes(needle),'Stale asset would hide change: '+needle);
const root={};vm.runInNewContext(controller,{globalThis:root,module:{exports:{}},console});
const ctl=(()=>{const sandbox={module:{exports:{}},console};vm.runInNewContext(controller,sandbox);return sandbox.module.exports})();

(async()=>{
 const baseTask={task_kind:'written_external',task_token:'token',task_key:'P2.B1.b',
 task_version:'candidate-v3',plan_item_id:'item',program_key:'economics_9708',
 program_version:'economics_2026_2028_v1',runtime_enabled:true,can_advance:true,question:'Sample'};
 let calls=0;
 const a=ctl.create({api:{
 open:async()=>baseTask,
 criteria:async()=>{calls++;return {
 available:true,task_key:'P2.B1.b',task_version:'candidate-v3',title:'Marking scheme',
 requirements:['Relevant content'],
 mark_scheme:{max_marks:12,ao12_marks:8,ao3_marks:4,marking_style:'levels',
 official_cambridge:false,indicative_points:['Relevant analysis','Justified evaluation']}}},
 advance:async()=>({status:'advanced',plan_item_id:'item',task_key:'P2.B1.b',task_version:'candidate-v3'}),
 status:async()=>({status:'advanced',plan_item_id:'item',task_key:'P2.B1.b',task_version:'candidate-v3',program_version:'economics_2026_2028_v1'})
 },createActionKey:()=> 'fixed'});
 await a.open('item');const one=await a.criteria();const two=await a.criteria();
 assert.strictEqual(one,two);assert.equal(calls,1,'Scheme should be fetched on request once');
 assert.equal(one.marking.ao12_marks,8);assert.equal(one.marking.ao3_marks,4);
 const corrupted=ctl.create({api:{
 open:async()=>baseTask,
 criteria:async()=>({available:true,task_key:'P2.B1.b',task_version:'candidate-v3',
 requirements:['Relevant content'],mark_scheme:{max_marks:12,ao12_marks:4,ao3_marks:3,
 official_cambridge:false,marking_style:'levels',indicative_points:['Relevant point']}}),
 advance:async()=>({}),status:async()=>({})
 },createActionKey:()=> 'fixed'});
 await corrupted.open('item');
 await assert.rejects(corrupted.criteria(),/invalid_mark_scheme/);
 console.log('ECONOMICS MARK SCHEME PREMIUM QA PASS — 22 mark splits, 2 live controller cases, privacy, copy, CSS, cache');
})().catch(e=>{console.error(e);process.exitCode=1});
