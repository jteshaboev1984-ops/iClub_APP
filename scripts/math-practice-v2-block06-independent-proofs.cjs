#!/usr/bin/env node
'use strict';
// Block06 Mathematics Practice Q126–Q150: coordinate transformations, straight-line setup.
// Independent expectations; no protected questions, keys, or option text printed.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2');
const files=['p2_functions/P1-FUN-06','p2_functions/P1-FUN-07','p2_functions/P1-FUN-08','p3_coordinate_geometry/P1-COO-01'];
const qs=new Map(files.flatMap(p=>JSON.parse(fs.readFileSync(path.join(root,p+'.json'),'utf8')).questions)
 .filter(q=>+q.key.slice(-3)>=126&&+q.key.slice(-3)<=150).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const num=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const eq=(a,b)=>a&&b&&a.length===b.length&&a.every((v,i)=>near(v,b[i]));
const point=s=>{const m=/^\((-?\d+(?:\/\d+)?),(-?\d+(?:\/\d+)?)\)$/.exec(norm(s));if(!m)return null;return[m[1],m[2]].map(v=>v.includes('/')?Number(v.split('/')[0])/Number(v.split('/')[1]):Number(v));};
const choice=(q,p)=>{assert.equal(q.qtype,'mcq');let correct=q.options.filter(o=>p(o.text.en));assert.equal(correct.length,1,'not exactly one correct');assert.equal(correct[0].key,q.correct_answer,'wrong key');};
const input=(q,value)=>{assert.equal(q.qtype,'input');assert.ok(near(num(q.answer_contract?.canonical_answer),value),'incorrect input answer');
 assert.equal(q.answer_contract.number_only,true);for(const e of q.answer_contract.accepted_examples||[])assert.ok(near(num(e),value),'invalid accepted');
 for(const e of q.answer_contract.rejected_examples||[])assert.ok(!near(num(e),value),'invalid rejected');
};
const tokens=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(v=>v.replace(',','.')).sort().join('|');
function trans(s){const m=/^h=(-?\d+),k=(-?\d+)$/.exec(norm(s));return m?[Number(m[1]),Number(m[2])]:null;}
function line(s){const m=/^y=(-?\d*)x([+-]\d+)?$/.exec(norm(s));if(!m)return null;return [Number(m[1]===''?1:m[1]==='-'?-1:m[1]),Number(m[2]||0)];}
const cases={
 126:q=>choice(q,t=>eq(trans(t),[-5,4])),
 127:q=>choice(q,t=>norm(t)==='y=-f(x)'),
 128:q=>choice(q,t=>norm(t)==='y=f(-x)'),
 129:q=>input(q,-(-7)),
 130:q=>choice(q,t=>eq(point(t),[5,2])),
 131:q=>choice(q,t=>norm(t)==='y=(x+2)²+1'),
 132:q=>input(q,-(-8)),
 133:q=>choice(q,t=>norm(t)==='y=-f(-x)'),
 134(q){assert.equal(q.role,'representation_variation');assert.equal(q.difficulty,'easy');
   choice(q,t=>norm(t)==='y=-f(x)');},
 135:q=>choice(q,t=>near(num(t),6)),
 136:q=>choice(q,t=>eq(point(t),[2,-5])),
 137:q=>choice(q,t=>norm(t)==='y=3f(x)'),
 138:q=>choice(q,t=>norm(t)==='y=f(2x)'),
 139:q=>input(q,5*(-3)),
 140:q=>choice(q,t=>eq(point(t),[6/3,4])),
 141:q=>choice(q,t=>eq(point(t),[2+1,2*3+4])),
 142:q=>input(q,-8*4),
 143:q=>choice(q,t=>/reflect in the x-axis and stretch vertically by factor 2/i.test(t)),
 144:q=>choice(q,t=>eq(point(t),[-6/(-2),4])),
 145:q=>choice(q,t=>eq(point(t),[4/2,3*(-2)+1])),
 146(q){
  const m=t=>/^a=(-?\d+(?:\/\d+)?),b=(-?\d+(?:\/\d+)?)$/.exec(norm(t));
  const fraction=x=>x.includes('/')?Number(x.split('/')[0])/Number(x.split('/')[1]):Number(x);
  choice(q,t=>{let a=m(t);return !!a&&near(fraction(a[1]),-4/8)&&near(fraction(a[2]),6/2);});
 },
 147:q=>input(q,8-3),
 148:q=>choice(q,t=>eq(point(t),[3,-3*3+5])),
 149(q){let m=3,c=-1-3*2;choice(q,t=>eq(line(t),[m,c]));},
 150:q=>input(q,4-(-2)*(-3))
};
assert.equal(qs.size,25,'must cover exactly 25 unique questions');
for(let id=126;id<=150;id++){
 try{
  const q=qs.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
  assert.equal(q.practice_no,id<=148?2:3);
  assert.ok(q.source_ref.includes(id<=148?'Ch2':'Ch3'));
  for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(tokens(q.question[l]),tokens(q.question.en),'language numeric drift');}
  if(q.qtype==='mcq'){
   assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D']);
   for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);
   for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);
  }
  cases[id](q);
 }catch(e){console.error('FAIL block06 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block06 Q126–Q150 independent graph/line mapping and Q134 difficulty/role; no protected content output');
