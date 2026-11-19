#!/usr/bin/env node
'use strict';
// Block19 Q451–Q475 definite/signed integrals, boundary parameters and area.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2/p7_integration');
const files=['P1-INT-02','P1-INT-03','P1-INT-04'];
const Q=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f+'.json'),'utf8')).questions)
.filter(q=>+q.key.slice(-3)>=451&&+q.key.slice(-3)<=475).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const num=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const frac=s=>{const m=/^(-?\d+)(?:\/(\d+))?$/.exec(norm(s));return m?Number(m[1])/Number(m[2]||1):NaN;};
const choose=(q,p)=>{assert.equal(q.qtype,'mcq');const valid=q.options.filter(o=>p(o.text.en));assert.equal(valid.length,1,'duplicate or no right option');assert.equal(valid[0].key,q.correct_answer);};
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(num(q.answer_contract.canonical_answer),v),'wrong numeric answer');assert.equal(q.answer_contract.number_only,true);
for(const x of q.answer_contract.accepted_examples||[])assert.ok(near(num(x),v));for(const x of q.answer_contract.rejected_examples||[])assert.ok(!near(num(x),v));};
const nums=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(v=>v.replace(',','.')).sort().join('|');
const F=(f,a,b)=>f(b)-f(a);
const medium=new Map([[454,'medium'],[455,'medium'],[464,'medium'],[465,'easy'],[466,'medium'],[468,'medium'],[469,'medium'],[471,'medium'],[472,'medium']]);
const tests={
451:q=>input(q,(20-(3*2**2+4))/2),
452(q){const C=5-2*4**1.5;input(q,2*9**1.5+C);},
453:q=>choose(q,t=>norm(t)==='y=(4/3)(3x-1)³-2/3'),
454:q=>input(q,F(x=>x*x+3*x,1,4)),
455:q=>input(q,2*3**2-6*3+7),
456:q=>input(q,F(x=>x*x,0,3)),
457:q=>input(q,F(x=>2*x**3-2*x,1,2)),
458:q=>choose(q,t=>near(num(t),F(x=>x**4,1,3))),
459:q=>choose(q,t=>near(num(t),F(x=>x*x/2-2*x,0,2))),
460:q=>input(q,F(x=>(2*x+1)**3/2,0,1)),
461:q=>choose(q,t=>near(num(t),2*(Math.sqrt(9)-Math.sqrt(1)))),
462:q=>input(q,2*Math.sqrt(9)),
463:q=>choose(q,t=>near(num(t),2*Math.sqrt(3+1))),
464:q=>input(q,12/2),
465:q=>input(q,F(x=>x*x,3,1)),
466:q=>choose(q,t=>near(num(t),F(x=>.75*x**4+x*x/2,-2,2))),
467:q=>input(q,20/(2*Math.sqrt(4))),
468:q=>choose(q,t=>near(frac(t),F(x=>x**3/3-x,0,2))),
469:q=>input(q,(18-F(x=>x*x,1,3))/(3-1)),
470:q=>input(q,F(x=>x**3,0,2)),
471:q=>choose(q,t=>near(num(t),F(x=>3*x-x*x/2,0,2))),
472:q=>choose(q,t=>near(frac(t),F(x=>x*x-x**3/3,0,2))),
473:q=>input(q,3*F(x=>2*x*x-3*x-x**3/3,1,3)),
474:q=>choose(q,t=>near(frac(t),F(x=>x-x*x/2,0,1)+F(x=>x*x/2-x,1,3))),
475:q=>input(q,3*F(x=>4*x-x**3/3,-2,2))
};
assert.equal(Q.size,25);
for(let id=451;id<=475;id++){
try{const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
 assert.equal(q.practice_no,7);assert.ok(q.source_ref.includes('Ch10'));
 if(medium.has(id))assert.equal(q.difficulty,medium.get(id));
 for(const l of ['en','ru','uz']){
  assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());
  if(l==='ru'&&[473,475].includes(id)){assert.ok(/утроенн/i.test(q.question.ru),'missing translated threefold factor');}
  else assert.equal(nums(q.question[l]),nums(q.question.en),'numeric source mismatch');
 }
 if(q.qtype==='mcq'){assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D']);for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
 tests[id](q);
}catch(e){console.error('FAIL block19 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block19 Q451–Q475 signed/improper integration, area and context parameters, approved RU threefold paraphrases');
