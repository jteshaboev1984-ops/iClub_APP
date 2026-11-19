#!/usr/bin/env node
'use strict';
// Final Block20 Q476–Q495: integration areas, curve intersections and
// volumes of revolution. No protected question content/keys printed.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const base=path.resolve(__dirname,'../content/math/practice_v2/p7_integration');
const files=['P1-INT-04','P1-INT-05'];
const Q=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(base,f+'.json'),'utf8')).questions)
.filter(q=>+q.key.slice(-3)>=476&&+q.key.slice(-3)<=495).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const number=s=>/^[+-]?(?:\d+(?:[.,]\d+)?|\.\d+)$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const frac=s=>{const t=norm(s);const m=/^(-?\d+)(?:\/(\d+))?$/.exec(t);return m?+m[1]/+(m[2]||1):NaN};
const piCoeff=s=>{let t=norm(s),m=/^(-?\d*)π(?:\/(\d+))?$/.exec(t);if(!m)return NaN;return(m[1]===''?1:m[1]==='-'?-1:+m[1])/+(m[2]||1);};
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(number(q.answer_contract.canonical_answer),v),'wrong input key');assert.equal(q.answer_contract.number_only,true);
 for(const e of q.answer_contract.accepted_examples||[])assert.ok(near(number(e),v),'incorrect accepted example');
 for(const e of q.answer_contract.rejected_examples||[])assert.ok(!near(number(e),v),'incorrect rejected example');};
const mcq=(q,p)=>{assert.equal(q.qtype,'mcq');const hits=q.options.filter(x=>p(x.text.en));assert.equal(hits.length,1,'nonunique MCQ option');assert.equal(hits[0].key,q.correct_answer,'wrong keyed answer');};
const tokens=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(v=>v.replace(',','.')).sort().join('|');
const area=(F,a,b)=>F(b)-F(a);
const volume=(F,a,b)=>area(F,a,b); // V/π, where F is antiderivative of radius².
const corrected=new Map([[486,'medium'],[493,'easy'],[495,'medium']]);
const verify={
 476:q=>input(q,area(x=>6*x-x*x,0,3)),
 477:q=>input(q,Math.cbrt((9/2)*6)),
 478(q){const inside=area(x=>4*x-x**3/3,0,2),outside=area(x=>x**3/3-4*x,2,3);
  mcq(q,t=>near(frac(t),2*(inside+outside)));},
 479:q=>input(q,3*area(x=>2*x*x-x**3/3,0,4)),
 480(q){const below=-area(x=>x**3/3-x*x,0,2),above=area(x=>x**3/3-x*x,2,3);input(q,3*(below+above));},
 481(q){
  const roots=[3-Math.sqrt(3),3+Math.sqrt(3)];
  for(const x of roots)assert.ok(near(x*x-6*x+6,0),'intersection equation not satisfied');
  mcq(q,t=>norm(t)==='x=3-√3andx=3+√3');
  for(const l of ['en','ru','uz'])assert.ok(q.explanation[l].includes('√(36−24)')&&!q.explanation[l].includes('√36−24'),'radicand grouping');
 },
 482(q){const signArea=area(x=>x*x/2-2*x,0,4),geometric=4;assert.ok(near(signArea,0)&&geometric>0);
  mcq(q,t=>/geometric area.*positive.*signed parts cancel/i.test(t));},
 483:q=>input(q,Math.cbrt(36*3/4)),
 484:q=>mcq(q,t=>near(piCoeff(t),volume(x=>4*x**3/3,0,1))),
 485:q=>input(q,volume(x=>x*x,0,3)),
 486(q){const k=Math.sqrt((288/5)/(32/5));mcq(q,t=>near(number(t),k));},
 487:q=>input(q,volume(x=>-(3-x)**3/3,0,3)),
 488:q=>input(q,2*volume(x=>x*x/2+x,0,3)),
 489:q=>input(q,Math.sqrt(12*3)),
 490:q=>input(q,Math.cbrt(9*3)),
 491(q){assert.ok(1/2>1/3);mcq(q,t=>/Under y=√x$/.test(t));},
 492:q=>input(q,3*volume(x=>4*x**3/3+2*x*x+x,0,1)),
 493:q=>mcq(q,t=>near(piCoeff(t),2**2*3)),
 494:q=>input(q,15*volume(x=>4*x**3/3-x**4+x**5/5,0,2)),
 495:q=>input(q,Math.sqrt(72/volume(x=>x*x/2,0,4)))
};
assert.equal(Q.size,20,'final 20 questions required');
for(let id=476;id<=495;id++){
try{
 const q=Q.get(id);assert.ok(q,'missing item');assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
 assert.equal(q.practice_no,7);assert.ok(q.source_ref.includes('Ch10'));
 if(corrected.has(id))assert.equal(q.difficulty,corrected.get(id),'incorrect difficulty');
 for(const l of ['en','ru','uz']){
  assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());
  if([479,480].includes(id)&&l==='ru'){
   assert.ok(/3 times/.test(q.question.en)&&/утроенн/.test(q.question.ru));
   const en=tokens(q.question.en).split('|'),ru=tokens(q.question.ru).split('|'),p=en.indexOf('3');assert.ok(p>=0);en.splice(p,1);
   assert.deepEqual(ru,en,'Russian "tripled area" semantic numeral divergence');
  } else assert.equal(tokens(q.question[l]),tokens(q.question.en),'language numeral parity');
 }
 if(q.qtype==='mcq'){
  assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D']);
  for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);
  for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);
 }
 verify[id](q);
}catch(e){console.error('FAIL block20 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block20 Q476–Q495 integration/volumes, 3 difficulty updates, trilingual parity and corrected discriminant Q481');
