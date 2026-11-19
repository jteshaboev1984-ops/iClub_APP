#!/usr/bin/env node
'use strict';
// Block16 Q376–Q400 differentiation, chain/power rule, tangent and normal proofs.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2/p6_differentiation');
const files=['P1-DIF-02','P1-DIF-03','P1-DIF-04','P1-DIF-05'];
const Q=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f+'.json'),'utf8')).questions).filter(q=>+q.key.slice(-3)>=376&&+q.key.slice(-3)<=400).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const num=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const mcq=(q,p)=>{assert.equal(q.qtype,'mcq');let a=q.options.filter(o=>p(o.text.en));assert.equal(a.length,1,'MCQ duplicate/missing correct');assert.equal(a[0].key,q.correct_answer,'key mismatch');};
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(num(q.answer_contract.canonical_answer),v),'numeric answer mismatch');assert.equal(q.answer_contract.number_only,true);for(const x of q.answer_contract.accepted_examples||[])assert.ok(near(num(x),v));for(const x of q.answer_contract.rejected_examples||[])assert.ok(!near(num(x),v));};
const numbers=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(v=>v.replace(',','.')).sort().join('|');
const calibrated=new Set([376,377,378,379,389]);
const tests={
376:q=>mcq(q,t=>norm(t)==='5x^(3/2)+3x^(-2)'),
377:q=>input(q,(5-3)/2),
378:q=>input(q,2*Math.sqrt(4)*3),
379:q=>mcq(q,t=>norm(t)==='60x³-12x'),
380:q=>mcq(q,t=>norm(t)==='12(4x-1)²'),
381:q=>mcq(q,t=>norm(t)==='-8(5-2x)³'),
382:q=>input(q,6*(2*1+3)**2),
383:q=>mcq(q,t=>norm(t)==='3/[2√(3x+4)]'),
384:q=>mcq(q,t=>norm(t)==='-4(2x+1)^(-3)'),
385:q=>input(q,(-1+Math.sqrt(1+48))/2),
386:q=>input(q,3*4*2*(2*1-1)**3),
387:q=>mcq(q,t=>norm(t)==='18(3x+1)²-4(x-4)³'),
388:q=>input(q,Math.sqrt(144/9)-3),
389:q=>input(q,3/(1-3*0)**2),
390:q=>mcq(q,t=>norm(t)==='y=2x-1'),
391:q=>mcq(q,t=>near(Number(norm(t).split('/')[0])/Number(norm(t).split('/')[1]),-1/3)),
392:q=>input(q,(2*1**2+1)-4*1),
393:q=>mcq(q,t=>norm(t)==='y=-x/2'),
394:q=>input(q,5-2*1),
395:q=>mcq(q,t=>norm(t)==='y=-2x-1'),
396:q=>input(q,3*(2+1/3)),
397:q=>mcq(q,t=>norm(t)==='y=-16'&&near(3*2**2-12,0)),
398:q=>input(q,Math.sqrt((9+3)/3)),
399:q=>mcq(q,t=>norm(t)==='y=-x+2;y=x'),
400:q=>mcq(q,t=>norm(t)==='x>2')
};
assert.equal(Q.size,25);
for(let id=376;id<=400;id++){
try{const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
 assert.equal(q.practice_no,6);assert.ok(q.source_ref.includes(id<400?'Ch8':'Ch9'),'chapter attribution mismatch');
 if(calibrated.has(id))assert.equal(q.difficulty,'medium');
 for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(numbers(q.question[l]),numbers(q.question.en),'trilingual numeric mismatch');}
 if(q.qtype==='mcq'){
 assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D']);
 for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);
 for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);
 }
 tests[id](q);
}catch(e){console.error('FAIL block16 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block16 Q376–Q400 derivative, chain and tangent/normal checks, keyed MCQs and 5 calibration corrections');
