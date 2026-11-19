#!/usr/bin/env node
'use strict';
// Block15 Q351–Q375: convergence rules, derivatives and exact input validation.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2');
const files=['p5_binomial_series/P1-SER-05','p6_differentiation/P1-DIF-01','p6_differentiation/P1-DIF-02'];
const Q=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f+'.json'),'utf8')).questions).filter(q=>+q.key.slice(-3)>=351&&+q.key.slice(-3)<=375).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const num=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-8;
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(num(q.answer_contract.canonical_answer),v),'incorrect numeric answer');assert.equal(q.answer_contract.number_only,true);
for(const z of q.answer_contract.accepted_examples||[])assert.ok(near(num(z),v));for(const z of q.answer_contract.rejected_examples||[])assert.ok(!near(num(z),v));};
const choice=(q,p)=>{assert.equal(q.qtype,'mcq');let a=q.options.filter(o=>p(o.text.en));assert.equal(a.length,1,'not uniquely correct');assert.equal(a[0].key,q.correct_answer);};
const tokens=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(z=>z.replace(',','.')).sort().join('|');
const lowerDifficulty=new Map([[356,'medium'],[357,'easy'],[358,'medium'],[366,'medium'],[367,'medium']]);
const tests={
351:q=>input(q,1-5/(20/3)),
352:q=>input(q,30*(1-.4)),
353:q=>choice(q,t=>norm(t)==='-1<k<3'&&[-.9,0,2.99].every(k=>Math.abs((k-1)/2)<1)),
354(q){const v=6/(1-.5)-6*(1-.5**4)/(1-.5);input(q,v);},
355:q=>input(q,(6/(1/3))/(1-1/3)),
356:q=>choice(q,t=>norm(t)==='|k|<2'),
357:q=>choice(q,t=>/common ratio is −1, so \|r\| is not less than 1/i.test(t)),
358:q=>input(q,12*(1-12/16)),
359:q=>choice(q,t=>norm(t)==='1<k²<3'),
360:q=>choice(q,t=>/tangent gradient is −3/i.test(t)),
361:q=>choice(q,t=>norm(t)==='[f(a+h)-f(a)]/h'),
362:q=>input(q,2*3+2),
363:q=>choice(q,t=>norm(t)==='10+h'),
364:q=>choice(q,t=>/decreasing at an instantaneous rate of 4/i.test(t)),
365:q=>choice(q,t=>/approaches the tangent gradient f′\(a\)/i.test(t)),
366:q=>input(q,9-2*2),
367:q=>choice(q,t=>near(num(t),7-2)),
368:q=>choice(q,t=>norm(t)==='28x³'&&7*4===28),
369:q=>choice(q,t=>norm(t)==='9x²-5'),
370:q=>input(q,6*2**2-8*2),
371:q=>choice(q,t=>norm(t)==='3/√x'),
372:q=>choice(q,t=>norm(t)==='-10/x³'),
373:q=>input(q,6*Math.sqrt(9)),
374:q=>input(q,12*1**2-12*1),
375:q=>input(q,(14-2)/3)
};
assert.equal(Q.size,25);
for(let id=351;id<=375;id++){
 try{const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
 assert.equal(q.practice_no,id<=359?5:6);
 assert.ok(q.source_ref.includes(id<=359?'Ch7':'Ch8'));
 if(lowerDifficulty.has(id))assert.equal(q.difficulty,lowerDifficulty.get(id));
 for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(tokens(q.question[l]),tokens(q.question.en),'trilingual numeric parity');}
 if(q.qtype==='mcq'){assert.deepEqual(q.options.map(o=>o.key),['A','B','C','D']);for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
 tests[id](q);
 }catch(e){console.error('FAIL block15 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block15 Q351–Q375 constrained convergence, derivative computations, MCQ uniqueness and five independent difficulty recalibrations');
