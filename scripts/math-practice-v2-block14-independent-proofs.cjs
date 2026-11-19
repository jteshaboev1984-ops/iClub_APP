#!/usr/bin/env node
'use strict';
// Block14 Q326–Q350 arithmetic and geometric sums, inverse formulas and constraints.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2/p5_binomial_series');
const names=['P1-SER-03','P1-SER-04','P1-SER-05'];
const Q=new Map(names.flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f+'.json'),'utf8')).questions)
.filter(q=>+q.key.slice(-3)>=326&&+q.key.slice(-3)<=350).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const number=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-8;
const frac=s=>{let m=/^(-?\d+)(?:\/(\d+))?$/.exec(norm(s));return m?Number(m[1])/Number(m[2]||1):NaN;};
const mcq=(q,p)=>{assert.equal(q.qtype,'mcq');let a=q.options.filter(o=>p(o.text.en));assert.equal(a.length,1,'not uniquely correct');assert.equal(a[0].key,q.correct_answer,'key drift');};
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(number(q.answer_contract.canonical_answer),v),'numeric answer drift');assert.equal(q.answer_contract.number_only,true);
for(const e of q.answer_contract.accepted_examples||[])assert.ok(near(number(e),v));for(const e of q.answer_contract.rejected_examples||[])assert.ok(!near(number(e),v));};
const tokens=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(z=>z.replace(',','.')).sort().join('|');
const AP=(a,d,n)=>n/2*(2*a+(n-1)*d),GP=(a,r,n)=>r===1?a*n:a*(1-r**n)/(1-r);
const newMedium=new Set([328,329,330,344,345]);
const tests={
326:q=>input(q,8), // n(n+5)=104 gives positive n=8.
327:q=>mcq(q,t=>near(number(t),(25+49)/2)),
328:q=>input(q,AP(18,4,15)),
329:q=>input(q,(215/(10/2)-2*8)/(10-1)),
330:q=>mcq(q,t=>near(number(t),5*(3*5+1)-4*(3*4+1))),
331(q){const d=(116/4-2*14)/(7-6),a=14-3*d;input(q,a);},
332:q=>input(q,384/2**7),
333:q=>input(q,GP(5,2,6)),
334:q=>input(q,8*(-1/2)**5),
335(q){const a=12/2;assert.ok(near(GP(a,2,3),42));input(q,2);},
336:q=>mcq(q,t=>near(number(t),54/3**3)),
337:q=>input(q,GP(64,.5,5)),
338:q=>input(q,Math.log(486/2)/Math.log(3)+1),
339:q=>input(q,6*6/18+2),
340:q=>mcq(q,t=>near(number(t),12*12/48)),
341:q=>mcq(q,t=>near(frac(t),9-3+1-1/3)),
342:q=>input(q,21/(1+2+4)),
343(q){const r=Math.cbrt(160/20),a=20/r**2;input(q,a+r);},
344:q=>input(q,100*3**5),
345:q=>input(q,5000*.9**4),
346:q=>input(q,Math.log(242+1)/Math.log(3)),
347:q=>mcq(q,t=>norm(t)==='3or-3'&&near((54/6),9)),
348:q=>mcq(q,t=>{const m=/^r=(-?\d+(?:\.\d+)?)$/.exec(norm(t));return !!m&&Math.abs(+m[1])<1;}),
349:q=>input(q,18/(1-1/3)),
350:q=>input(q,12/(1+1/2))
};
assert.equal(Q.size,25);
for(let id=326;id<=350;id++){
try{const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
assert.equal(q.practice_no,5);assert.ok(q.source_ref.includes('Ch7'));
if(newMedium.has(id))assert.equal(q.difficulty,'medium');
for(let l of ['en','ru','uz']){
  assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());
  if(id===344&&l==='uz'){
    // English 'triples' and Russian 'утраивается' are expressed with a 3 in Uzbek.
    assert.ok(/triples each hour/i.test(q.question.en)&&/утраивается/.test(q.question.ru)&&/3 marta/.test(q.question.uz));
    const uz=tokens(q.question.uz).split('|'),en=tokens(q.question.en).split('|');
    const pos=uz.indexOf('3');assert.ok(pos>=0);uz.splice(pos,1);
    assert.deepEqual(uz,en,'Uzbek multiplier paraphrase no longer equivalent');
  } else assert.equal(tokens(q.question[l]),tokens(q.question.en),'locale number mismatch');
}
if(q.qtype==='mcq'){assert.deepEqual(q.options.map(o=>o.key),['A','B','C','D']);for(let l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);for(let o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
tests[id](q);
}catch(e){console.error('FAIL block14 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block14 Q326–Q350 exact series, inverse roots, negative/common-ratio constraints and five recalibrated items');
