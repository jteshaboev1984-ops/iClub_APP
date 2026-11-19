#!/usr/bin/env node
'use strict';
// Mathematics Practice Block13 Q301–Q325 binomial and arithmetic/geometry sequence proofs.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const base=path.resolve(__dirname,'../content/math/practice_v2/p5_binomial_series');
const Q=new Map(['P1-SER-01','P1-SER-02','P1-SER-03','P1-SER-04'].flatMap(f=>JSON.parse(fs.readFileSync(path.join(base,f+'.json'),'utf8')).questions)
 .filter(q=>+q.key.slice(-3)>=301&&+q.key.slice(-3)<=325).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const num=s=>/^[+-]?(?:\d+(?:[.,]\d*)?|\.\d+)$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const close=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const choose=(q,p)=>{assert.equal(q.qtype,'mcq');let a=q.options.filter(o=>p(o.text.en));assert.equal(a.length,1,'multiple or absent correct answers');assert.equal(a[0].key,q.correct_answer);};
const input=(q,n)=>{assert.equal(q.qtype,'input');assert.ok(close(num(q.answer_contract.canonical_answer),n),'incorrect integer/decimal');
assert.equal(q.answer_contract.number_only,true);for(let v of q.answer_contract.accepted_examples||[])assert.ok(close(num(v),n));for(let v of q.answer_contract.rejected_examples||[])assert.ok(!close(num(v),n));};
const C=(n,r)=>{let v=1;for(let i=1;i<=r;i++)v=v*(n-i+1)/i;return Math.round(v);};
const tokens=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(v=>v.replace(',','.')).sort().join('|');
const sequences=(s)=>{const matches=norm(s).match(/-?\d+(?:\/\d+)?/g)||[];return matches.map(x=>x.includes('/')?Number(x.split('/')[0])/Number(x.split('/')[1]):+x).slice(0,4);};
const isAP=a=>a.length>=3&&a.slice(2).every((v,i)=>close(v-a[i+1],a[1]-a[0]));
const isGP=a=>a.length>=3&&a[0]!==0&&a.slice(2).every((v,i)=>close(v/a[i+1],a[1]/a[0]));
const tests={
301:q=>choose(q,s=>norm(s)==='C(7,r)2^(7-r)(-3x)^r'&&C(7,2)*2**5*(-3)**2===6048),
302:q=>input(q,3**5),
303:q=>input(q,C(8,6)),
304:q=>input(q,35/C(7,1)),
305:q=>choose(q,s=>close(num(s),C(4,3)*3*2**3)),
306(q){let n=7;assert.equal(C(n,2)-C(n,1),14);input(q,n);},
307:q=>choose(q,s=>close(num(s),C(4,2)-C(4,1))),
308:q=>choose(q,s=>/Arithmetic progression/.test(s)&&!/Both/.test(s)&&isAP([4,9,14,19])),
309:q=>choose(q,s=>s==='Geometric progression'&&isGP([81,27,9,3])),
310:q=>choose(q,s=>s==='Neither'&&!isAP([2,4,8,14])&&!isGP([2,4,8,14])),
311:q=>choose(q,s=>s==='Consecutive differences are equal.'),
312:q=>input(q,6/(-4)),
313:q=>choose(q,s=>s==='Arithmetic'),
314:q=>choose(q,s=>{const v=sequences(s);return v.length===4&&isGP(v);}),
315(q){assert.equal(q.difficulty,'medium');input(q,3*(-8/12));},
316:q=>choose(q,s=>/Both arithmetic and geometric/.test(s)&&isAP([5,5,5,5])&&isGP([5,5,5,5])),
317:q=>choose(q,s=>{const v=sequences(s);return v.length===4&&!isAP(v)&&!isGP(v);}),
318:q=>input(q,7+(15-1)*4),
319:q=>input(q,25/2*(2*2+24*3)),
320:q=>input(q,(138-5)/7+1),
321:q=>choose(q,s=>close(num(s),40-(12-1)*3)),
322:q=>input(q,(46-18)/(12-5)),
323(q){const d=(31-11)/(8-3),a=11-2*d;input(q,a+d);},
324:q=>choose(q,s=>close(num(s),20*(4+61)/2)),
325:q=>input(q,9/2)
};
assert.equal(Q.size,25);
for(let id=301;id<=325;id++){
 try{const q=Q.get(id);assert.ok(q);
 assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));assert.equal(q.practice_no,5);
 assert.ok(q.source_ref.includes(id<=307?'Ch6':'Ch7'));
 for(let l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(tokens(q.question[l]),tokens(q.question.en),'numeric stem mismatch');}
 if(q.qtype==='mcq'){assert.deepEqual(q.options.map(o=>o.key),['A','B','C','D']);for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
 tests[id](q);
 }catch(e){console.error('FAIL block13 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block13 Q301–Q325 independent coefficient/sequence/finite AP proofs, exact options and trilingual literals');
