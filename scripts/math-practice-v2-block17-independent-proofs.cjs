#!/usr/bin/env node
'use strict';
// Q401–Q425 independent Mathematics P1 Practice: monotonicity, linked rates,
// stationary-point classification and optimisation; no protected content logged.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2/p6_differentiation');
const files=['P1-DIF-05','P1-DIF-06','P1-DIF-07'];
const Q=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f+'.json'),'utf8')).questions)
.filter(q=>+q.key.slice(-3)>=401&&+q.key.slice(-3)<=425).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const numeric=s=>/^[+-]?(?:\d+(?:[.,]\d+)?|\.\d+)$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-8;
const input=(q,ans)=>{assert.equal(q.qtype,'input');assert.ok(near(numeric(q.answer_contract.canonical_answer),ans),'wrong scalar');assert.equal(q.answer_contract.number_only,true);
 for(const e of q.answer_contract.accepted_examples||[])assert.ok(near(numeric(e),ans),'wrong accepted example');
 for(const e of q.answer_contract.rejected_examples||[])assert.ok(!near(numeric(e),ans),'wrong rejected example');
};
const mcq=(q,p)=>{assert.equal(q.qtype,'mcq');const hits=q.options.filter(o=>p(o.text.en));assert.equal(hits.length,1,'non-unique correct choice');assert.equal(hits[0].key,q.correct_answer,'incorrect keyed answer');};
const numbers=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(t=>t.replace(',','.')).sort().join('|');
const gt=(a,b)=>a>b,lt=(a,b)=>a<b;
const applyInterval=(s,x)=>{
 const e=norm(s);
 if(e==='Allrealx')return true;
 const p=e.split('or');if(p.length>1)return p.some(t=>applyInterval(t,x));
 let m=/^(-?\d+(?:\.\d+)?)([<≤])x([<≤])(-?\d+(?:\.\d+)?)$/.exec(e);
 if(m)return (m[2]==='<'?x>+m[1]:x>=+m[1])&&(m[3]==='<'?x<+m[4]:x<=+m[4]);
 m=/^x([<>≤≥])(-?\d+(?:\.\d+)?)$/.exec(e);
 if(m){let v=+m[2];return m[1]==='<'?x<v:m[1]==='>'?x>v:m[1]==='≤'?x<=v:x>=v;}
 throw Error('unsupported derivative interval format');
};
const interval=(q,p,samples)=>mcq(q,t=>samples.every(x=>applyInterval(t,x)===p(x)));
const pcode={};
const cases={
 401:q=>interval(q,x=>3*(x+3)*(x-1)<0,[-6,-3,-2,0,.99,1,3]),
 402:q=>interval(q,x=>(x-2)*(x+5)>0,[-9,-5,-4,0,1.9,2,2.1,9]),
 403:q=>interval(q,x=>-(x-1)*(x-4)>0,[-4,.9,1,1.1,2,3.9,4,4.1,9]),
 404:q=>input(q,Math.floor(6*6/(4*3))+1),
 405:q=>interval(q,x=>(x-2)*(x-4)<0,[-6,1.9,2,2.1,3.9,4,4.1]),
 406:q=>interval(q,x=>x>0&&x*(x-3)<0,[-3,0,.1,1.5,2.99,3,3.01,8]),
 407(q){const f=x=>(x+4)*(x-1)*(x-5)**2;
   const spans=[[-9,-5],[-3,0],[2,4],[6,8]];
   input(q,spans.filter(([a,b])=>f(a)<0&&f(b)<0).length);
  },
 408:q=>mcq(q,t=>/f is decreasing throughout I/i.test(t)),
 409(q){const s=4,v=.5,calc=(2*s+2)*v;
   mcq(q,t=>/cm² s⁻¹$/.test(t)&&near(numeric(t.replace(/ cm² s⁻¹$/,'')),calc));
   const keyed=q.options.find(o=>o.key===q.correct_answer);
   assert.ok(keyed&&/cm² s⁻¹$/.test(keyed.text.en),'area-rate units must be squared');
  },
 410:q=>input(q,2*4*(-.2)),
 411:q=>input(q,2*5*3),
 412:q=>input(q,3*4**2*2),
 413:q=>input(q,12/(2*3)),
 414:q=>input(q,4*2*.5),
 415:q=>input(q,6/2),
 416:q=>input(q,-6*3/8),
 417:q=>mcq(q,t=>/cm s⁻¹$/.test(t)&&near(numeric(t.replace(/ cm s⁻¹$/,'')),15/(2*5**2))),
 418:q=>input(q,3**2-6*3+5),
 419(q){const d=x=>3*x*(x-2);assert.ok(d(-.1)>0&&d(.1)<0);
   mcq(q,t=>/Local maximum/i.test(t));
  },
 420(q){const stationary=[-2,0,2];input(q,stationary.filter(x=>12*x*x-16>0).length);},
 421:q=>input(q,4*Math.sqrt(64)),
 422:q=>input(q,(3*(-2)**2+12)/4),
 423(q){const x=-3,dd=6*x+6;assert.ok(dd<0);mcq(q,t=>/Local maximum/i.test(t));},
 424:q=>input(q,12/4),
 425(q){const d=x=>3*x*x;assert.ok(near(d(0),0)&&d(-.2)>0&&d(.2)>0);
   mcq(q,t=>/Stationary point of inflexion/i.test(t));
  }
};
assert.equal(Q.size,25,'Q401–Q425 scope');
for(let id=401;id<=425;id++){
 try{
  const q=Q.get(id);assert.ok(q,'question missing');assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));assert.equal(q.practice_no,6);
  assert.ok(q.source_ref.includes('Ch9'),'chapter source mismatch');
  for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(numbers(q.question[l]),numbers(q.question.en),'trilingual numeral mismatch');}
  if(q.qtype==='mcq'){
   assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D'],'missing/duplicate option keys');
   for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4,'duplicate option');
   for(const o of q.options){if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
  }
  cases[id](q);
 }catch(e){console.error('FAIL block17 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block17 Q401–Q425 independent monotonicity/rates/stationary maths, keyed MCQs incl. unordered options, EN/RU/UZ and numeric contracts');
