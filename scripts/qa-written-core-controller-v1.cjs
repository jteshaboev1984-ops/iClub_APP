#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const {create}=require('../exam-prep/runtime/written-core-controller-v1.js');
const task={task_kind:'written_external',task_token:'server',task_key:'B1',task_version:'v1',plan_item_id:'p1',program_key:'economics_9708',program_version:'v1',runtime_enabled:true,can_advance:true};
let calls=0,checks=0;
const api={open:async()=>task,criteria:async()=>({available:true,task_key:'B1',task_version:'v1',requirements:['State relevant analysis']}),advance:async()=>{calls++;return {status:'advanced',plan_item_id:'p1',task_key:'B1',task_version:'v1'}},status:async()=>({status:'active',plan_item_id:'p1',task_key:'B1',task_version:'v1',program_version:'v1'})};
async function check(label,fn){await fn();checks++;console.log('PASS',label)}
(async()=>{
 const c=create({api,createActionKey:()=>String(Date.now())});
 await check('must open',()=>assert.rejects(c.next(),/not_open/));
 await check('loads server item',async()=>assert.equal((await c.open('p1')).status,'active'));
 await check('criteria optional',async()=>assert.equal(c.snapshot().criteria_loaded,false));
 await check('criteria explicit',async()=>assert.equal((await c.criteria()).requirements.length,1));
 await check('advance no essay',async()=>assert.equal((await c.next()).status,'advanced'));
 await check('duplicate advance safe',async()=>{await c.next();assert.equal(calls,1)});
 await check('no master score',async()=>assert.equal(c.snapshot().score,undefined));
 const d=create({api:{...api,advance:async()=>{throw Error('network')},status:async()=>{throw Error('network')}},createActionKey:()=>String(Date.now())});
 await d.open('p1');
 await check('offline fail closed',async()=>{await assert.rejects(d.next(),/unconfirmed/);assert.equal(d.snapshot().status,'active')});
 console.log('RESULT',checks,'tests pass');
})().catch(e=>{console.error(e);process.exitCode=1});
