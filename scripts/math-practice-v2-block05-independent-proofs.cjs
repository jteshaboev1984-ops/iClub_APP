#!/usr/bin/env node
'use strict';
// Mathematics Practice Block05 Q101–Q125: inverse functions and translations.
// Source-only independent checks; no protected answer keys in output.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const dir=path.resolve(__dirname,'../content/math/practice_v2/p2_functions');
const files=['P1-FUN-04','P1-FUN-05','P1-FUN-06'];
const qs=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(dir,f+'.json'),'utf8')).questions)
 .filter(q=>+q.key.slice(-3)>=101&&+q.key.slice(-3)<=125).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const numeric=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
function input(q,v){assert.equal(q.qtype,'input');assert.ok(near(numeric(q.answer_contract.canonical_answer),v),'numeric answer mismatch');
 assert.equal(q.answer_contract.number_only,true);
 for(const e of q.answer_contract.accepted_examples||[])assert.ok(near(numeric(e),v),'incorrect accepted example');
 for(const e of q.answer_contract.rejected_examples||[])assert.ok(!near(numeric(e),v),'incorrect rejected example');
}
function choice(q,accept){assert.equal(q.qtype,'mcq');let right=q.options.filter(x=>accept(x.text.en));assert.equal(right.length,1,'correct option non-unique');assert.equal(right[0].key,q.correct_answer);}
const point=s=>{const m=/^\((-?\d+),(-?\d+)\)$/.exec(norm(s));return m?[+m[1],+m[2]]:null;};
const samePoint=(a,b)=>!!a&&a.length===2&&a.every((v,i)=>near(v,b[i]));
function translate(s){
 const m=/^y=f\(x([+-]\d+)?\)([+-]\d+)?$/.exec(norm(s));
 return m?{dx:-Number(m[1]||0),dy:Number(m[2]||0)}:null;
}
function transformedVertex(s){
 const m=/^y=\(x([+-]\d+)\)²([+-]\d+)?$/.exec(norm(s));
 return m?[-Number(m[1]),Number(m[2]||0)]:null;
}
const literalNumbers=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-')
 .match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(x=>x.replace(',','.')).sort().join('|');
const tests={
 101:q=>input(q,(4*5+5)-(4*3+5)),
 102(q){const f=x=>(x-2)**2+6;assert.ok(f(0)>f(1)&&f(1)>f(2));choice(q,t=>norm(t)==='x≤2');},
 103:q=>choice(q,t=>norm(t)==='[-3,8]'),
 104(q){const r=Math.sqrt(27-2);input(q,-1+r);},
 105(q){const fn=x=>(x+1)**2-4;for(const y of [-4,0,5,20]){const inv=-1-Math.sqrt(y+4);assert.ok(inv<=-1&&near(fn(inv),y));}
  choice(q,t=>norm(t)==='-1-√(x+4)');},
 106(q){choice(q,t=>/domain is x<5 and range y>2\./i.test(t));},
 107(q){choice(q,t=>norm(t)==='f⁻¹(-2)=6');},
 108(q){const fn=x=>(x-3)**2-4;for(const y of [-4,0,5,20]){const inv=3-Math.sqrt(y+4);assert.ok(inv<=3&&near(fn(inv),y));}
  choice(q,t=>norm(t)==='3-√(x+4)');},
 109:q=>choice(q,t=>samePoint(point(t),[7,-3])),
 110:q=>input(q,-6),
 111:q=>choice(q,t=>norm(t)==='y=x'),
 112:q=>choice(q,t=>{const xy=point(t);return !!xy&&near(xy[0],xy[1]);}),
 113:q=>choice(q,t=>samePoint(point(t),[0,5])),
 114(q){const expected='1≤x≤9,-2≤y≤6';choice(q,t=>norm(t)===expected);},
 115(q){const answer=[[2,-1],[4,0],[7,3]];choice(q,t=>{const pts=[...norm(t).matchAll(/\((-?\d+),(-?\d+)\)/g)].map(m=>[+m[1],+m[2]]);return pts.length===3&&pts.every((xy,i)=>samePoint(xy,answer[i]));});},
 116(q){const x=3;assert.ok(near(2*x-3,x)&&near((x+3)/2,x));choice(q,t=>samePoint(point(t),[x,x]));},
 117:q=>choice(q,t=>{const v=translate(t);return !!v&&v.dx===0&&v.dy===6;}),
 118:q=>choice(q,t=>{const v=translate(t);return !!v&&v.dx===-3&&v.dy===0;}),
 119:q=>input(q,-2+4),
 120:q=>choice(q,t=>samePoint(transformedVertex(t),[-3,-2])),
 121:q=>choice(q,t=>samePoint(point(t),[1-5,-4+2])),
 122:q=>input(q,-1+5),
 123:q=>choice(q,t=>/2 units left and 5 units up/i.test(t)),
 124:q=>choice(q,t=>{const v=translate(t);return !!v&&v.dx===7&&v.dy===-4;}),
 125:q=>choice(q,t=>samePoint(transformedVertex(t),[1+2,4]))
};
assert.equal(qs.size,25,'missing/duplicate Q101–Q125');
for(let i=101;i<=125;i++){
 try{
  const q=qs.get(i);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(i).padStart(3,'0'));
  assert.equal(q.practice_no,2);assert.ok(q.source_ref.includes('Ch2'));
  for(const l of ['en','ru','uz']){
   assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim(),'missing language');
   assert.equal(literalNumbers(q.question[l]),literalNumbers(q.question.en),'numerical stem parity');
  }
  if(q.qtype==='mcq'){
   assert.deepEqual(q.options.map(v=>v.key),['A','B','C','D']);
   for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(v=>norm(v.text[l]))).size,4);
   for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);
  }
  tests[i](q);
 }catch(e){console.error('FAIL block05 Q'+String(i).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block05 Q101–Q125 inverse/translation checks, unique MCQs, scalar contracts and RU/UZ/EN number parity; no answer keys logged');
