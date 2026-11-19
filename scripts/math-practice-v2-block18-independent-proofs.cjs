#!/usr/bin/env node
'use strict';
// Block18 Q426–Q450: stationary values and integration, independent
// differentiations + boundary checks; source-only, no key/option text logged.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2');
const files=['p6_differentiation/P1-DIF-07','p7_integration/P1-INT-01','p7_integration/P1-INT-02'];
const Q=new Map(files.flatMap(p=>JSON.parse(fs.readFileSync(path.join(root,p+'.json'),'utf8')).questions)
 .filter(q=>+q.key.slice(-3)>=426&&+q.key.slice(-3)<=450).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const num=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(num(q.answer_contract.canonical_answer),v),'incorrect numeric result');assert.equal(q.answer_contract.number_only,true);
for(const x of q.answer_contract.accepted_examples||[])assert.ok(near(num(x),v),'invalid accepted example');
for(const x of q.answer_contract.rejected_examples||[])assert.ok(!near(num(x),v),'invalid rejected example');};
const mcq=(q,p)=>{assert.equal(q.qtype,'mcq');let matches=q.options.filter(x=>p(x.text.en));assert.equal(matches.length,1,'nonunique mathematical choice');assert.equal(matches[0].key,q.correct_answer,'incorrect keyed option');};
const nums=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(x=>x.replace(',','.')).sort().join('|');
const calibrated=new Map([[426,'medium'],[439,'easy'],[440,'medium'],[441,'medium'],[442,'medium'],[443,'medium'],[444,'medium'],[445,'medium'],[446,'medium']]);
const tests={
 426(q){const f=x=>x**3-3*x*x;input(q,f(0)-f(2));},
 427(q){let df=x=>(x-2)**2*(x+1);assert.ok(df(-1.1)<0&&df(-.9)>0);input(q,-1);},
 428(q){const f=x=>x*x*(12-x);assert.ok(f(8)>f(0)&&f(8)>f(12));input(q,f(8));},
 429(q){const a=-6,b=9;assert.ok(near(3*1**2+2*a*1+b,0)&&near(3*3**2+2*a*3+b,0));input(q,a+b);},
 430:q=>mcq(q,t=>norm(t)==='2x⁴+C'&&8/4===2),
 431:q=>mcq(q,t=>norm(t)==='2x³-2x²+5x+C'&&near(3*2,6)),
 432:q=>input(q,12/6),
 433:q=>mcq(q,t=>norm(t)==='(3x+2)³/9+C'&&near(3*3/9,1)),
 434:q=>mcq(q,t=>norm(t)==='-(5-2x)⁴/8+C'&&near(-4*(-2)/8,1)),
 435:q=>mcq(q,t=>norm(t)==='(8/3)x^(3/2)+C'&&near(8/3*3/2,4)),
 436:q=>mcq(q,t=>norm(t)==='12√x+C'&&near(12/2,6)),
 437:q=>input(q,6/(3*2)),
 438:q=>mcq(q,t=>norm(t)==='3x³-4x+7'&&near(3*3,9)),
 439:q=>input(q,-12/3),
 440:q=>input(q,5*3),
 441:q=>input(q,18/2),
 442:q=>mcq(q,t=>norm(t)==='(2x+3)⁴/2-2x³+C'&&near(4*2/2,4)),
 443:q=>input(q,3*4),
 444(q){const C=15-(3*2**2+2);input(q,3*(-1)**2-1+C);},
 445:q=>mcq(q,t=>norm(t)==='y=2x²-2x+5'&&near(2*0*2-2, -2)),
 446(q){const C=4-1**3;input(q,2**3+C);},
 447:q=>input(q,0-(-1)**2-4*(-1)),
 448(q){const C=2-(2*0+1)**3;mcq(q,t=>norm(t)==='y=(2x+1)³+1'&&C===1);},
 449(q){const C=3-(1**2-1);mcq(q,t=>norm(t)==='(0,3)'&&C===3);},
 450:q=>input(q,12-2*(2**2)-2*2)
};
assert.equal(Q.size,25);
for(let id=426;id<=450;id++){
try{
 const q=Q.get(id);assert.ok(q,'missing question');
 assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
 assert.equal(q.practice_no,id<=429?6:7);
 assert.ok(q.source_ref.includes(id<=429?'Ch9':'Ch10'),'source chapter drift');
 if(calibrated.has(id))assert.equal(q.difficulty,calibrated.get(id),'difficulty calibration missing');
 for(const l of ['en','ru','uz']){
  assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim(),'missing language');
  assert.equal(nums(q.question[l]),nums(q.question.en),'numeric language drift');
 }
 if(q.qtype==='mcq'){
  assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D'],'unstable MCQ keys');
  for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4,'duplicate option');
  for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);
 }
 tests[id](q);
}catch(e){console.error('FAIL block18 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block18 Q426–Q450 integration and extrema independent numeric/keyed math with 9 forward-only difficulty adjustments');
