#!/usr/bin/env node
'use strict';
// Block07 Mathematics Practice Q151–Q175: independently check line, midpoint,
// distance, intersection and gradient; corrections of six difficulty labels.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const base=path.resolve(__dirname,'../content/math/practice_v2/p3_coordinate_geometry');
const files=['P1-COO-01','P1-COO-02','P1-COO-03'];
const qs=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(base,f+'.json'),'utf8')).questions)
.filter(q=>+q.key.slice(-3)>=151&&+q.key.slice(-3)<=175).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const num=s=>/^[+-]?(?:\d+(?:[.,]\d*)?|\.\d+)$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const eq=(a,b)=>a&&b&&a.length===b.length&&a.every((v,i)=>near(v,b[i]));
const point=s=>{const m=/^\((-?\d+),(-?\d+)\)$/.exec(norm(s));return m?[+m[1],+m[2]]:null;};
const choice=(q,p)=>{assert.equal(q.qtype,'mcq');let a=q.options.filter(o=>p(o.text.en));assert.equal(a.length,1,'more than one right choice');assert.equal(a[0].key,q.correct_answer,'wrong correct option');};
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(num(q.answer_contract.canonical_answer),v),'incorrect canonical numeric answer');assert.equal(q.answer_contract.number_only,true);
for(const s of q.answer_contract.accepted_examples||[])assert.ok(near(num(s),v),'bad accepted input');
for(const s of q.answer_contract.rejected_examples||[])assert.ok(!near(num(s),v),'incorrect rejected input');
};
const tokens=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-')
.match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(s=>s.replace(',','.')).sort().join('|');
function lineCoefficients(txt){
 const s=norm(txt);
 const parts=s.split('=');
 if(parts.length!==2)return null;
 const parse=side=>{
   const coeff=[0,0,0];
   const normalized=side.replace(/-/g,'+-');
   for(let t of normalized.split('+').filter(Boolean)){
     let m=/^(-?\d*)x$/.exec(t);if(m){coeff[0]+=Number(m[1]===''?1:m[1]==='-'?-1:m[1]);continue;}
     m=/^(-?\d*)y$/.exec(t);if(m){coeff[1]+=Number(m[1]===''?1:m[1]==='-'?-1:m[1]);continue;}
     if(/^[-]?\d+$/.test(t)){coeff[2]+=+t;continue;}
     return null;
   }return coeff;
 };
 const a=parse(parts[0]),b=parse(parts[1]);return a&&b?a.map((v,i)=>v-b[i]):null;
}
const belongs=(str,x,y)=>{const c=lineCoefficients(str);return !!c&&near(c[0]*x+c[1]*y+c[2],0);};
const sameLine=(s,abc)=>{const coeff=lineCoefficients(s);if(!coeff)return false;
 return Math.abs(coeff[0])+Math.abs(coeff[1])>0 && [0,1,2].every(i=>near(coeff[i]*abc[0],abc[i]*coeff[0]))&&Math.abs(coeff[0])>0 && Math.abs(abc[0])>0;};
const slope=(s)=>{const c=lineCoefficients(s);return c&&c[1]!==0?-c[0]/c[1]:NaN;};
const intercept=(s)=>{const c=lineCoefficients(s);return c&&c[1]!==0?-c[2]/c[1]:NaN;};
const grad=(a,b)=>(b[1]-a[1])/(b[0]-a[0]);
const tests={
 151:q=>choice(q,s=>near(slope(s),grad([1,5],[4,11]))&&belongs(s,1,5)),
 152:q=>input(q,grad([-2,-5],[3,10])),
 153:q=>choice(q,s=>belongs(s,2,3)&&belongs(s,6,1)),
 154:q=>input(q,5-4*(-2)),
 155:q=>input(q,5-(10-2)/2),
 156:q=>choice(q,s=>belongs(s,0,-4)&&belongs(s,2,0)),
 157:q=>input(q,3+grad([-1,3],[2,9])*(8+1)),
 158(q){assert.equal(q.difficulty,'easy');input(q,(7-2*4)/(-1));},
 159:q=>choice(q,s=>belongs(s,2,5)&&belongs(s,6,0)),
 160(q){assert.equal(q.difficulty,'medium');input(q,-2+Math.sqrt(10**2-(9-1)**2));},
 161(q){assert.equal(q.difficulty,'medium');choice(q,s=>eq(point(s),[2*(-1)-(-5),2*3-7]));},
 162:q=>input(q,grad([1,-4],[7,8])),
 163:q=>choice(q,s=>belongs(s,4,3)&&!belongs(s,0,11)),
 164:q=>input(q,18/3),
 165:q=>choice(q,s=>/gradient.*-2.*y-intercept.*4/i.test(norm(s))),
 166:q=>input(q,(2+3)**2+(14-2)**2),
 167:q=>choice(q,s=>eq(point(s),[2*2-(-4),2*(-1)-5])),
 168(q){assert.equal(q.difficulty,'medium');input(q,(15+5)/(2+3));},
 169(q){assert.equal(q.difficulty,'easy');choice(q,s=>near(slope(s),-1/2)&&near(intercept(s),3));},
 170(q){assert.equal(q.difficulty,'easy');input(q,2*4-10);},
 171:q=>choice(q,s=>near(slope(s),-3)&&!near(intercept(s),4)),
 172:q=>input(q,3-(-1/2)*4),
 173:q=>choice(q,s=>near(slope(s),3/2)),
 174:q=>input(q,1+3),
 175:q=>choice(q,s=>near(num(s),1-2))
};
assert.equal(qs.size,25);
for(let id=151;id<=175;id++){
 try{
  const q=qs.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
  assert.equal(q.practice_no,3);assert.ok(q.source_ref.includes('Ch3'));
  for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(tokens(q.question[l]),tokens(q.question.en),'numeric language drift');}
  if(q.qtype==='mcq'){assert.deepEqual(q.options.map(x=>x.key).sort(),['A','B','C','D']);
   for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(x=>norm(x.text[l]))).size,4,'duplicate option');
   for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
  tests[id](q);
 }catch(e){console.error('FAIL block07 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block07 Q151–Q175 line/point/distance math and six independently calibrated difficulty labels, no keys disclosed');
