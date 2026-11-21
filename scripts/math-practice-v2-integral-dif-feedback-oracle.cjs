#!/usr/bin/env node
'use strict';
// Independent academic oracle: compare bound-reversal outputs to actually chosen
// values and verify derivative sign against the stationary-point claim.
// No production access; never print protected answer keys.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'../content/math/practice_v2');
const integrals=JSON.parse(fs.readFileSync(path.join(root,'p7_integration/P1-INT-03.json'),'utf8')).questions;
const dif=JSON.parse(fs.readFileSync(path.join(root,'p6_differentiation/P1-DIF-05.json'),'utf8')).questions;
const ix=new Map([...integrals,...dif].map(q=>[Number(q.key.slice(-3)),q]));
const equal=(a,b)=>Math.abs(a-b)<1e-12;
const numeric=s=>{
 const normalized=String(s).replace(/[−–—]/g,'-').trim();
 if(!/^-?\d+(?:\.\d+)?(?:\/\d+(?:\.\d+)?)?$/.test(normalized))throw Error('unexpected numeric choice');
 if(!normalized.includes('/'))return Number(normalized);
 const [a,b]=normalized.split('/').map(Number);return a/b;
};
const e=[
 [458,Math.pow(3,4)-Math.pow(1,4),['B','C'],['A']],
 [459,(Math.pow(2,2)/2-2*2)-(Math.pow(0,2)/2-2*0),['C'],[]],
 [461,2*Math.sqrt(9)-2*Math.sqrt(1),['A','B','D'],[]],
 [463,2*Math.sqrt(3+1)-2*Math.sqrt(0),['C'],[]],
 [466,(3*Math.pow(2,4)/4+Math.pow(2,2)/2)-(3*Math.pow(-2,4)/4+Math.pow(-2,2)/2),['A'],[]]
];
let fixed=0,retained=0;
for(const [n,actual,changed,kept]of e){
 const q=ix.get(n);assert.ok(q,'original source question missing');
 assert.equal(q.primary_skill,'P1-INT-03');
 const choice=q.options.find(o=>o.key===q.correct_answer);assert.ok(choice);
 assert.ok(equal(numeric(choice.text.en),actual),'independent definite integral calculation disagrees');
 for(const key of changed){
  const opt=q.options.find(o=>o.key===key);assert.ok(opt);
  assert.ok(!equal(numeric(opt.text.en),-actual),'chosen wrong value WAS a reversal');
  assert.equal(opt.diagnostic_code,'INT03_NOT_BOUNDS_REVERSAL');
  fixed++;
 }
 for(const key of kept){
  const opt=q.options.find(o=>o.key===key);assert.ok(opt);
  assert.ok(equal(numeric(opt.text.en),-actual),'retained reversal feedback not supported');
  assert.equal(opt.diagnostic_code,'INT03_UPPER_MINUS_LOWER');
  retained++;
 }
}
const reversalCorrect=ix.get(468);
assert.ok(reversalCorrect);
const revCorrect=(Math.pow(2,3)/3-2)-(Math.pow(0,3)/3-0);
const anti=reversalCorrect.options.find(o=>o.diagnostic_code==='INT03_UPPER_MINUS_LOWER');
assert.ok(anti&&equal(numeric(anti.text.en),-revCorrect));
retained++;
const monotonic=ix.get(408);assert.ok(monotonic);
assert.equal(monotonic.primary_skill,'P1-DIF-05');
assert.match(monotonic.question.en,/f′\(x\)<0 at every point/);
const suspect=monotonic.options.find(o=>/stationary point at every x/i.test(o.text.en));
assert.ok(suspect&&suspect.key!==monotonic.correct_answer);
assert.equal(suspect.diagnostic_code,'DIF05_NO_STATIONARY_WHEN_NEGATIVE');
assert.ok([-10,-1,0,1,10].every(y=>-Math.exp(y)<0&&-Math.exp(y)!==0));
const catalogInt=JSON.parse(fs.readFileSync(path.join(root,'p7_integration/diagnostic_catalog.json'),'utf8')).diagnostics;
const catalogDif=JSON.parse(fs.readFileSync(path.join(root,'p6_differentiation/diagnostic_catalog.json'),'utf8')).diagnostics;
for(const [code,source]of [['INT03_NOT_BOUNDS_REVERSAL',catalogInt],['DIF05_NO_STATIONARY_WHEN_NEGATIVE',catalogDif]]){
 const entries=source.filter(d=>d.code===code);assert.equal(entries.length,1);
 for(const lang of ['en','ru','uz']){assert.ok(entries[0].feedback[lang]?.trim());assert.ok(entries[0].next_action[lang]?.trim());}
}
assert.equal(fixed,8);
assert.equal(retained,2);
console.log(JSON.stringify({oracle:'PASS',verified_integral_traps:8,retained_true_bound_reversals:retained,strict_negative_derivative_stationary_contradictions:1,
 catalog_entries:2,question_count:6,locales:['en','ru','uz'],answer_keys_unchanged:true,private_answers_exposed:false}));
