#!/usr/bin/env node
'use strict';
// Read-only QA of original iClub Economics 9708 written sources.
// Never imports learner runtime, never updates a database, never approves content.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const dir=path.resolve(__dirname,'../exam-prep/academic');
const load=n=>JSON.parse(fs.readFileSync(path.join(dir,n),'utf8'));
const p2=load('economics-9708-P2-written-requirements-EN-DRAFT.json');
const p4=load('economics-9708-P4-written-requirements-EN-DRAFT.json');
const ss=load('economics-9708-P2-P4-sectionA-source-EN-DRAFT.json');
let n=0;
function check(name,fn){fn();n++;process.stdout.write('PASS '+n+' '+name+'\n');}
check('P2 14',()=>assert.equal(p2.items.length,14));
check('P4 8',()=>assert.equal(p4.items.length,8));
check('unique task refs',()=>assert.equal(new Set([...p2.items,...p4.items].map(x=>x.task_ref)).size,22));
for(const p of [p2,p4]){
 check(p.paper+' unpublished',()=>{assert.equal(p.runtime_enabled,false);assert.equal(p.rubric_is_official,false)});
 check(p.paper+' A=20',()=>assert.equal(p.items.filter(x=>x.task_ref.startsWith(p.paper+'.A.')).reduce((a,x)=>a+x.draft_marks,0),20));
 check(p.paper+' choices',()=>{const k=p.paper==='P2'?4:2;assert.equal(p.items.filter(x=>x.task_ref.startsWith(p.paper+'.B')).length,k);assert.equal(p.items.filter(x=>x.task_ref.startsWith(p.paper+'.C')).length,k)});
 check(p.paper+' prompts+requirements',()=>assert.ok(p.items.every(x=>x.prompt_en&&x.requirements_en?.length)));
}
check('2 sources unpublished',()=>{assert.equal(ss.paper_sources.length,2);assert.equal(ss.runtime_enabled,false)});
for(const source of ss.paper_sources){
 const p=source.paper_code==='P2'?p2:p4;
 const a=p.items.filter(x=>x.task_ref.startsWith(p.paper+'.A.')).map(x=>x.task_ref).sort();
 check(source.paper_code+' all A linked',()=>assert.deepEqual(source.linked_task_keys.slice().sort(),a));
}
const isara=ss.paper_sources.find(x=>x.paper_code==='P2');
const get=i=>isara.data.find(x=>x.indicator.startsWith(i)).value;
check('Isara shortage 60',()=>assert.equal(get('Quantity demanded')-get('Quantity supplied'),60));
check('Isara binding price',()=>assert.ok(get('Maximum retail price')<get('Estimated market-clearing price')));
check('Isara positive inflation',()=>assert.ok(get('Consumer inflation, Year A')===8&&get('Consumer inflation, Year B')===6));
const nerava=ss.paper_sources.find(x=>x.paper_code==='P4');
const t=Object.fromEntries(nerava.trade_table.rows.map(x=>[x[0],x.slice(1)]));
const balance=i=>t['Exports of goods'][i]+t['Exports of services'][i]-t['Imports of goods'][i]-t['Imports of services'][i];
check('Nerava Year A -12',()=>assert.equal(balance(0),-12));
check('Nerava Year B -9',()=>assert.equal(balance(1),-9));
check('Nerava improvement +3',()=>assert.equal(balance(1)-balance(0),3));
check('No current account inferred',()=>assert.equal(nerava.internal_deterministic_qa.current_account_from_trade_only,false));
check('Translations still missing',()=>{assert.equal(ss.locales.ru,'missing');assert.equal(ss.locales.uz,'missing')});
check('P2 draft split not official',()=>assert.equal(p2.prototype_subpart_8_12_is_not_official,true));
check('Publication explicitly barred',()=>assert.equal(ss.publication_status,'INTERNAL_DRAFT_NOT_FOR_LEARNERS'));
console.log('RESULT '+n+' PASS; does not constitute academic sign-off or learner QA');

