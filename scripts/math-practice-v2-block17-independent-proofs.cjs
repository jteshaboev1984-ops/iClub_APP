#!/usr/bin/env node
'use strict';
// Block17 Q401–Q425 derivative sign, chain related rates and stationary point proofs.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const base=path.resolve(__dirname,'../content/math/practice_v2/p6_differentiation');
const Q=new Map(['P1-DIF-05','P1-DIF-06','P1-DIF-07'].flatMap(f=>JSON.parse(fs.readFileSync(path.join(base,f+'.json'),'utf8')).questions)
.filter(q=>+q.key.slice(-3)>=401&&+q.key.slice(-3)<=425).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const number=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(x,y)=>Number.isFinite(x)&&Number.isFinite(y)&&Math.abs(x-y)<1e-8;
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(number(q.answer_contract.canonical_answer),v),'numeric incorrect');assert.equal(q.answer_contract.number_only,true);
for(const a of q.answer_contract.accepted_examples||[])assert.ok(near(number(a),v));for(const a of q.answer_contract.rejected_examples||[])assert.ok(!near(number(a),v));};
const mcq=(q,p)=>{assert.equal(q.qtype,'mcq');const hits=q.options.filter(o=>p(o.text.en));assert.equal(hits.length,1,'duplicate/absent correct option');assert.equal(hits[0].key,q.correct_answer);};
const numbers=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(v=>v.replace(',','.')).sort().join('|');
const calibrated=new Map([[406,'medium'],[408,'easy'],[409,'medium'],[410,'medium'],[417,'medium']]);
const tests={
401:q=>mcq(q,t=>norm(t)==='-3<x<1'),
402:q=>mcq(q,t=>norm(t)==='x<-5orx>2'),
403:q=>mcq(q,t=>norm(t)==='1<x<4'),
404:q=>input(q,Math.floor(36/12)+1),
405:q=>mcq(q,t=>norm(t)==='2<x<4'),
406:q=>mcq(q,t=>norm(t)==='0<x<3'),
407(q){const points=[-5,-3,0,2,4,6],f=x=>(x+4)*(x-1)*(x-5)**2;assert.ok(f(points[1])<0&&f(points[2])<0&&f(points[0])>0&&f(points[3])>0);input(q,1);},
408:q=>mcq(q,t=>/f is decreasing throughout I/i.test(t)),
409:q=>mcq(q,t=>norm(t)==='5cm²s⁻¹'&&near((2*4+2)*.5,5)),
410:q=>input(q,2*4*(-.2)),
411:q=>input(q,2*5*3),
412:q=>input(q,3*4**2*2),
413:q=>input(q,12/(2*3)),
414:q=>input(q,4*2*.5),
415:q=>input(q,6/2),
416:q=>input(q,-6*3/8),
417:q=>mcq(q,t=>norm(t)==='0.3cms⁻¹'&&near(15/(2*5**2),.3)),
418:q=>input(q,3**2-6*3+5),
419:q=>mcq(q,t=>sLower(t)==='local maximum'&&6*0-6<0),
420(q){const ys=[-2,0,2];const minima=ys.filter(x=>12*x*x-16>0);input(q,minima.length);},
421:q=>input(q,4*Math.sqrt(64)),
422:q=>input(q,(3*4+12)/4),
423:q=>mcq(q,t=>/Local maximum/i.test(t)&&(6*(-3)+6)<0),
424:q=>input(q,12/4),
425:q=>mcq(q,t=>/Stationary point of inflexion/i.test(t)&&near(3*0**2,0))
};
function sLower(s){return String(s).trim().toLowerCase();}
assert.equal(Q.size,25);
for(let id=401;id<=425;id++){
try{
 const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
 assert.equal(q.practice_no,6);assert.ok(q.source_ref.includes('Ch9'));
 if(calibrated.has(id))assert.equal(q.difficulty,calibrated.get(id));
 for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(numbers(q.question[l]),numbers(q.question.en),'trilingual number mismatch');}
 if(q.qtype==='mcq'){assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D']);for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
 tests[id](q);
}catch(e){console.error('FAIL block17 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block17 Q401–Q425 derivative sign, related rates, stationary points, unit-bearing MCQs and five calibrated items');
