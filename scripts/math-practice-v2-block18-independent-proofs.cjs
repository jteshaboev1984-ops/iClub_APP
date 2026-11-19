#!/usr/bin/env node
'use strict';
// Block18 Q426–Q450 stationary/optimisation and definite-source antiderivative checks.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2');
const files=['p6_differentiation/P1-DIF-07','p7_integration/P1-INT-01','p7_integration/P1-INT-02'];
const Q=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f+'.json'),'utf8')).questions).filter(q=>+q.key.slice(-3)>=426&&+q.key.slice(-3)<=450).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const num=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(num(q.answer_contract.canonical_answer),v),'bad scalar');assert.equal(q.answer_contract.number_only,true);
for(const x of q.answer_contract.accepted_examples||[])assert.ok(near(num(x),v));for(const x of q.answer_contract.rejected_examples||[])assert.ok(!near(num(x),v));};
const choice=(q,p)=>{assert.equal(q.qtype,'mcq');const hit=q.options.filter(o=>p(o.text.en));assert.equal(hit.length,1,'non-unique MCQ');assert.equal(hit[0].key,q.correct_answer);};
const nums=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(x=>x.replace(',','.')).sort().join('|');
const calibrated=new Set([439,440,441,443,444,445,446]);
const point=s=>{const m=/^\((-?\d+),(-?\d+)\)$/.exec(norm(s));return m?[+m[1],+m[2]]:null;};
const tests={
426(q){const y=x=>x**3-3*x*x;input(q,y(0)-y(2));},
427:q=>input(q,-1),
428:q=>input(q,8**2*(12-8)),
429:q=>input(q,(-12/2)+9),
430:q=>choice(q,t=>norm(t)==='2x⁴+C'&&near(2*4,8)),
431:q=>choice(q,t=>norm(t)==='2x³-2x²+5x+C'),
432:q=>input(q,12/6),
433:q=>choice(q,t=>norm(t)==='(3x+2)³/9+C'),
434:q=>choice(q,t=>norm(t)==='-(5-2x)⁴/8+C'),
435:q=>choice(q,t=>norm(t)==='(8/3)x^(3/2)+C'),
436:q=>choice(q,t=>norm(t)==='12√x+C'),
437:q=>input(q,6/(3*2)),
438:q=>choice(q,t=>norm(t)==='3x³-4x+7'),
439:q=>input(q,-12/3),
440:q=>input(q,5*3),
441:q=>input(q,18/2),
442:q=>choice(q,t=>norm(t)==='(2x+3)⁴/2-2x³+C'),
443:q=>input(q,3*4),
444(q){const C=15-(3*2**2+2);input(q,3*(-1)**2-1+C);},
445:q=>choice(q,t=>norm(t)==='y=2x²-2x+5'),
446:q=>input(q,2**3+(4-1**3)),
447:q=>input(q,0-((-1)**2+4*(-1))),
448:q=>choice(q,t=>norm(t)==='y=(2x+1)³+1'),
449:q=>choice(q,t=>{const p=point(t);return p&&near(p[1],p[0]**2-p[0]+3);}),
450:q=>input(q,12-(2*2**2+2*2))
};
assert.equal(Q.size,25);
for(let id=426;id<=450;id++){
 try{const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
 assert.equal(q.practice_no,id<=429?6:7);assert.ok(q.source_ref.includes(id<=429?'Ch8':'Ch10'));
 if(calibrated.has(id))assert.equal(q.difficulty,'medium');
 for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(nums(q.question[l]),nums(q.question.en),'numeric language drift');}
 if(q.qtype==='mcq'){assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D']);for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
 tests[id](q);
 }catch(e){console.error('FAIL block18 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block18 Q426–Q450 independent stationary/integration/curve-reconstruction calculations and seven calibrated items');
