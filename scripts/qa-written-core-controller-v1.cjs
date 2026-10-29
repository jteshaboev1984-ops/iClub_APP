#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const {create}=require('../exam-prep/runtime/written-core-controller-v1.js');
const task={task_kind:'written_external',task_token:'server',task_key:'B1',task_version:'v1',plan_item_id:'p1',program_key:'economics_9708',program_version:'v1',runtime_enabled:true,can_advance:true};
let calls=0,checks=0;
const api={open:async()=>task,criteria:async()=>({available:true,task_key:'B1',task_version:'v1',mark_scheme:{max_marks:20,ao12_marks:14,ao3_marks:6,marking_style:'levels',official_cambridge:false,assessment_criteria:['Use accurate economic concepts','Develop a relevant economic analysis','Weigh competing arguments and justify the judgement']}}),advance:async()=>{calls++;return {status:'advanced',plan_item_id:'p1',task_key:'B1',task_version:'v1'}},status:async()=>({status:'active',plan_item_id:'p1',task_key:'B1',task_version:'v1',program_version:'v1'})};
async function check(label,fn){await fn();checks++;console.log('PASS',label)}
(async()=>{
 const c=create({api,createActionKey:()=>String(Date.now())});
 await check('must open',()=>assert.rejects(c.next(),/not_open/));
 await check('loads server item',async()=>assert.equal((await c.open('p1')).status,'active'));
 await check('criteria optional',async()=>assert.equal(c.snapshot().criteria_loaded,false));
 await check('criteria explicit without answer hints',async()=>{const result=await c.criteria();assert.equal(result.requirements.length,0);assert.equal(result.marking.assessment_criteria.length,3);assert.equal(result.marking.official_cambridge,false);assert.equal(result.marking.max_marks,20);assert.equal(Object.hasOwn(result.marking,'indicative_points'),false)});
 await check('advance no essay',async()=>assert.equal((await c.next()).status,'advanced'));
 await check('duplicate advance safe',async()=>{await c.next();assert.equal(calls,1)});
 await check('no master score',async()=>assert.equal(c.snapshot().score,undefined));
 const d=create({api:{...api,advance:async()=>{throw Error('network')},status:async()=>{throw Error('network')}},createActionKey:()=>String(Date.now())});
 await d.open('p1');
 await check('offline fail closed',async()=>{await assert.rejects(d.next(),/unconfirmed/);assert.equal(d.snapshot().status,'active')});
 const legacy=create({api:{...api,open:async()=>({...task,program_key:'chemistry_9701'}),criteria:async()=>({available:true,task_key:'B1',task_version:'v1',requirements:['Keep independent existing criteria contract']})},createActionKey:()=>String(Date.now())});
 await legacy.open('p1');
 await check('non-Economics legacy criteria unchanged',async()=>{const result=await legacy.criteria();assert.equal(result.requirements.length,1);assert.equal(result.marking,null)});
 console.log('RESULT',checks,'tests pass');
})().catch(e=>{console.error(e);process.exitCode=1});
