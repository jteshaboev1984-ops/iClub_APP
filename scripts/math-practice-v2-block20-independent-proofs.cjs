#!/usr/bin/env node
'use strict';
// Final Block20 Q476–Q495: area sign splits, intersections and revolved volumes.
// No answer keys or protected source text emitted to logs.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const dir=path.resolve(__dirname,'../content/math/practice_v2/p7_integration');
const files=['P1-INT-04','P1-INT-05'];
const Q=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(dir,f+'.json'),'utf8')).questions)
.filter(q=>+q.key.slice(-3)>=476&&+q.key.slice(-3)<=495).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const num=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-8;
const fraction=s=>{let m=/^(-?\d+)(?:\/(\d+))?$/.exec(norm(s));return m?Number(m[1])/Number(m[2]||1):NaN;};
const mcq=(q,p)=>{assert.equal(q.qtype,'mcq');let ok=q.options.filter(o=>p(o.text.en));assert.equal(ok.length,1,'more than one or no valid answer');assert.equal(ok[0].key,q.correct_answer);};
const input=(q,a)=>{assert.equal(q.qtype,'input');assert.ok(near(num(q.answer_contract.canonical_answer),a),'wrong numeric answer');assert.equal(q.answer_contract.number_only,true);for(const s of q.answer_contract.accepted_examples||[])assert.ok(near(num(s),a));for(const s of q.answer_contract.rejected_examples||[])assert.ok(!near(num(s),a));};
const nums=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(x=>x.replace(',','.')).sort().join('|');
const integral=(f,a,b)=>f(b)-f(a);
const calibrated=new Map([[486,'medium'],[492,'medium'],[493,'easy']]);
const tests={
476:q=>input(q,.5*3*6),
477:q=>input(q,Math.cbrt((9/2)*6)),
478(q){const area=2*(integral(x=>4*x-x**3/3,0,2)+integral(x=>x**3/3-4*x,2,3));mcq(q,t=>near(fraction(t),area));},
479:q=>input(q,3*integral(x=>2*x*x-x**3/3,0,4)),
480:q=>input(q,3*(-integral(x=>x**3/3-x*x,0,2)+integral(x=>x**3/3-x*x,2,3))),
481(q){const r=Math.sqrt(36-24);assert.ok(near((3-r/2)**2-6*(3-r/2)+6,0));
 mcq(q,t=>norm(t)==='x=3-√3andx=3+√3');for(const l of ['en','ru','uz'])assert.ok(q.explanation[l].includes('√(36−24)'),'ungrouped discriminant');},
482(q){
 const example=x=>x-2,anti=x=>x*x/2-2*x;
 assert.ok(near(integral(anti,0,4),0)&&near(-integral(anti,0,2)+integral(anti,2,4),4));
 mcq(q,t=>/geometric area between the graph and x-axis is positive because positive and negative signed parts cancel/i.test(t));
},
483:q=>input(q,Math.cbrt(36*3/4)),
484:q=>mcq(q,t=>norm(t)==='4π/3'&&near(integral(x=>4*x**3/3,0,1),4/3)),
485:q=>input(q,integral(x=>x*x,0,3)),
486:q=>mcq(q,t=>near(num(t),Math.sqrt((288/5)/(32/5)))),
487:q=>input(q,integral(x=>9*x-3*x*x+x**3/3,0,3)),
488:q=>input(q,2*integral(x=>x*x/2+x,0,3)),
489:q=>input(q,Math.sqrt(12*3)),
490:q=>input(q,Math.cbrt(9*3)),
491(q){const a=integral(x=>x**3/3,0,1),b=integral(x=>x*x/2,0,1);assert.ok(b>a);mcq(q,t=>/Under y=√x/.test(t));},
492:q=>input(q,3*integral(x=>4*x**3/3+2*x*x+x,0,1)),
493:q=>mcq(q,t=>norm(t)==='12π'&&near(4*3,12)),
494(q){const a=integral(x=>4*x**3/3-x**4+x**5/5,0,2);input(q,15*a);},
495:q=>input(q,Math.sqrt(72/integral(x=>x*x/2,0,4)))
};
assert.equal(Q.size,20,'final block exactly 20 questions');
for(let id=476;id<=495;id++){
 try{const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
 assert.equal(q.practice_no,7);assert.ok(q.source_ref.includes('Ch10'));
 if(calibrated.has(id))assert.equal(q.difficulty,calibrated.get(id));
 for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());
 if(l==='ru'&&[479,480].includes(id))assert.ok(/утроенн/i.test(q.question.ru),'translated threefold not stated');
 else assert.equal(nums(q.question[l]),nums(q.question.en),'numeric language drift');}
 if(q.qtype==='mcq'){assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D']);for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
 tests[id](q);
 }catch(e){console.error('FAIL block20 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS final block20 Q476–Q495 area sign, corrected radicand, rotation volumes, contextual source/range and RU/UZ phrasing');
