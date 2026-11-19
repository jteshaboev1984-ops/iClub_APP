#!/usr/bin/env node
'use strict';
// Block19 Q451–Q475: exact integration, bounded-area signs and proper/improper
// limits. Source-only; deliberately no answer keys or protected content in CI logs.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2/p7_integration');
const files=['P1-INT-02','P1-INT-03','P1-INT-04'];
const Q=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f+'.json'),'utf8')).questions)
.filter(q=>+q.key.slice(-3)>=451&&+q.key.slice(-3)<=475).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const num=s=>/^[+-]?(?:\d+(?:[.,]\d+)?|\.\d+)$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const frac=s=>{const m=/^(-?\d+)(?:\/(\d+))?$/.exec(norm(s));return m?+m[1]/+(m[2]||1):num(s)};
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const scalar=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(num(q.answer_contract.canonical_answer),v),'incorrect numeric key');assert.equal(q.answer_contract.number_only,true);
 for(const e of q.answer_contract.accepted_examples||[])assert.ok(near(num(e),v),'invalid accepted example');
 for(const e of q.answer_contract.rejected_examples||[])assert.ok(!near(num(e),v),'invalid rejection');
};
const mcq=(q,p)=>{assert.equal(q.qtype,'mcq');const a=q.options.filter(o=>p(o.text.en));assert.equal(a.length,1,'non-unique answer');assert.equal(a[0].key,q.correct_answer,'incorrect keyed answer');};
const tok=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(x=>x.replace(',','.')).sort().join('|');
const F=(f,a,b)=>f(b)-f(a),positive=x=>Math.max(0,x);
const changed=new Map([[457,'medium'],[464,'easy'],[465,'easy'],[466,'medium'],[467,'medium'],[469,'medium'],[471,'medium'],[472,'medium']]);
const qcases={
451:q=>scalar(q,(20-(3*2**2+4))/2),
452(q){const C=5-2*4**1.5;scalar(q,2*9**1.5+C);},
453:q=>mcq(q,t=>norm(t)==='y=(4/3)(3x-1)³-2/3'&&near(4/3*2**3-2/3,10)),
454:q=>scalar(q,F(x=>x*x+3*x,1,4)),
455:q=>scalar(q,2*3**2-6*3+7),
456:q=>scalar(q,F(x=>x*x,0,3)),
457:q=>scalar(q,F(x=>2*x**3-2*x,1,2)),
458:q=>mcq(q,t=>near(frac(t),F(x=>x**4,1,3))),
459:q=>mcq(q,t=>near(frac(t),F(x=>x*x/2-2*x,0,2))),
460:q=>scalar(q,F(x=>(2*x+1)**3/2,0,1)),
461:q=>mcq(q,t=>near(frac(t),F(x=>2*Math.sqrt(x),1,9))),
462(q){const integral=6-2*Math.sqrt(1e-12);assert.ok(near(integral,6,1e-5)||integral>5.999);scalar(q,6);},
463(q){const limit=2*Math.sqrt(3+1);scalarGuard(q);mcq(q,t=>near(frac(t),limit));},
464:q=>scalar(q,12/(2**2/2)),
465:q=>scalar(q,F(x=>x*x,3,1)),
466(q){const f=x=>3*x**3+x;assert.ok(near(f(1),-f(-1)));mcq(q,t=>near(frac(t),0));},
467:q=>scalar(q,20/(2*Math.sqrt(4))),
468:q=>mcq(q,t=>near(frac(t),F(x=>x**3/3-x,0,2))),
469:q=>scalar(q,(18-F(x=>x*x,1,3))/(3-1)),
470:q=>scalar(q,F(x=>x**3,0,2)),
471:q=>mcq(q,t=>near(frac(t),F(x=>3*x-x*x/2,0,2))),
472:q=>mcq(q,t=>near(frac(t),F(x=>x*x-x**3/3,0,2))),
473:q=>scalar(q,3*F(x=>2*x*x-3*x-x**3/3,1,3)),
474:q=>mcq(q,t=>near(frac(t),F(x=>x-x*x/2,0,1)+F(x=>x*x/2-x,1,3))),
475:q=>scalar(q,3*2*F(x=>4*x-x**3/3,0,2))
};
function scalarGuard(q){assert.equal(q.qtype,'mcq');}
assert.equal(Q.size,25);
for(let id=451;id<=475;id++){
try{
const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
assert.equal(q.practice_no,7);assert.ok(q.source_ref.includes('Ch10'));
if(changed.has(id))assert.equal(q.difficulty,changed.get(id));
for(const l of ['en','ru','uz']){
 assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());
 if([473,475].includes(id)&&l==='ru'){
   assert.ok(/3 times/i.test(q.question.en)&&/утроенн/.test(q.question.ru));
   const en=tok(q.question.en).split('|'),ru=tok(q.question.ru).split('|'),k=en.indexOf('3');assert.ok(k>=0);en.splice(k,1);
   assert.deepEqual(ru,en,'Russian multiplier must preserve exact numerical meaning');
 } else assert.equal(tok(q.question[l]),tok(q.question.en),'numerical locale drift');
}
if(q.qtype==='mcq'){
 assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D']);
 for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);
 for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);
}
qcases[id](q);
}catch(e){console.error('FAIL block19 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block19 Q451–Q475 independent definite/indefinite integrals, units, improper endpoints, signed and geometric areas; eight guarded calibrations');
