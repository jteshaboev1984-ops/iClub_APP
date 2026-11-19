#!/usr/bin/env node
'use strict';
// Block02 (Q026–Q050): source-only, independently derived mathematical oracles.
// Never prints answer keys, distractor content, diagnosis keys or question stems.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const base=path.resolve(__dirname,'../content/math/practice_v2/p1_quadratics');
const files=['P1-QUA-03','P1-QUA-04','P1-QUA-05'];
const qs=new Map(files.flatMap(k=>JSON.parse(fs.readFileSync(path.join(base,k+'.json'),'utf8')).questions)
 .filter(q=>+q.key.slice(-3)>=26&&+q.key.slice(-3)<=50).map(q=>[+q.key.slice(-3),q]));
const plain=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'').replace(/,/g,'.');
const number=s=>/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/.test(plain(s))?Number(plain(s)):NaN;
const approx=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
function eqSet(a,b){return a.length===b.length&&a.slice().sort((x,y)=>x-y).every((x,i)=>approx(x,b.slice().sort((x,y)=>x-y)[i]));}
function qOption(q,pred){
 assert.equal(q.qtype,'mcq');
 const good=q.options.filter(x=>Boolean(pred(x.text.en)));
 assert.equal(good.length,1,'more than one correct or no correct MCQ option');
 assert.equal(good[0].key,q.correct_answer,'incorrect source key');
}
function input(q,ans){
 assert.equal(q.qtype,'input');
 assert.ok(approx(number(q.answer_contract?.canonical_answer),ans),'incorrect numeric canonical answer');
 assert.ok(q.answer_contract.number_only,'missing deterministic number-only contract');
 for(const v of q.answer_contract.accepted_examples||[])assert.ok(approx(number(v),ans),'invalid accepted example');
 for(const v of q.answer_contract.rejected_examples||[])assert.ok(!approx(number(v),ans),'rejected example is correct');
}
function quadratic(a,b,c){const D=b*b-4*a*c;return D<0?[]:D===0?[-b/(2*a)]:[(-b-Math.sqrt(D))/(2*a),(-b+Math.sqrt(D))/(2*a)];}
function polynomial(text){
 const normalized=plain(text).split('=')[0].replace(/-/g,'+-');
 const coefs=[0,0,0];for(let term of normalized.split('+').filter(Boolean)){
  let m=/^(-?\d*)x²$/.exec(term);
  if(m){coefs[0]+=Number(m[1]===''?1:m[1]==='-'?-1:m[1]);continue;}
  m=/^(-?\d*)x$/.exec(term);
  if(m){coefs[1]+=Number(m[1]===''?1:m[1]==='-'?-1:m[1]);continue;}
  if(!/^[-]?\d+$/.test(term))throw Error('unparseable polynomial option');
  coefs[2]+=Number(term);
 }
 return coefs;
}
function rootsOption(text){
 const normalized=plain(text);
 // Typical MCQ: x=−2±√5 or x=3/5 and x=−1.
 const radical=/^x=(-?\d+)±(\d*)√(\d+)$/.exec(normalized);
 if(radical){const a=Number(radical[1]),b=Number(radical[2]||1),r=Math.sqrt(Number(radical[3]));return [a-b*r,a+b*r];}
 const other=normalized.split('and').map(s=>s.replace(/^x=/,''));
 if(other.length!==2)return [];
 const parseFraction=s=>{const m=/^(-?\d+)(?:\/(\d+))?$/.exec(s);return m?Number(m[1])/Number(m[2]||1):NaN;};
 return other.map(parseFraction);
}
const asNumber=s=>{const m=/^(-?\d+)(?:\/(\d+))?$/.exec(s);return m?Number(m[1])/Number(m[2]||1):NaN};
function condition(src,x){
 const s=plain(src);
 if(s==='Allrealx')return true;
 if(s.startsWith('Allrealxexceptx='))return !approx(x,asNumber(s.slice('Allrealxexceptx='.length)));
 if(s.endsWith('only'))return condition(s.slice(0,-4),x);
 const or=s.split('or');if(or.length>1)return or.some(p=>condition(p,x));
 const cmp=(a,op,b)=>op==='<'?a<b:op==='>'?a>b:op==='≤'?a<=b:op==='≥'?a>=b:op==='='?approx(a,b):false;
 let m=/^(-?(?:\d+(?:\/\d+)?))([<>≤≥])x([<>≤≥])(-?(?:\d+(?:\/\d+)?))$/.exec(s);
 if(m)return cmp(asNumber(m[1]),m[2],x)&&cmp(x,m[3],asNumber(m[4]));
 m=/^x([<>≤≥=])(-?(?:\d+(?:\/\d+)?))$/.exec(s);
 if(m)return cmp(x,m[1],asNumber(m[2]));
 m=/^(-?(?:\d+(?:\/\d+)?))([<>≤≥])x$/.exec(s);
 if(m)return cmp(asNumber(m[1]),m[2],x);
 throw Error('unparseable interval option');
}
function interval(q,truth,values){qOption(q,t=>values.every(x=>condition(t,x)===truth(x)));}
const tests={
 26(q){const roots=quadratic(1,4,-1);qOption(q,t=>eqSet(rootsOption(t),roots));},
 27(q){
   assert.equal(q.difficulty,'hard');
   assert.ok(q.question.en.includes('vertex at x=1/2')&&q.question.ru.includes('x=1/2')&&q.question.uz.includes('1/2'));
   const vertexX=.5,yIntercept=-12;
   const b=-2*vertexX,c=yIntercept;
   const roots=quadratic(1,b,c);
   assert.equal(roots.length,2);
   for(const x of roots)assert.ok(near(x*x+b*x+c,0));
   assert.ok(roots.some(x=>x<0)&&roots.some(x=>x>0));
   input(q,Math.max(...roots));
  },
 28(q){assert.deepEqual(quadratic(1,6,13),[]);qOption(q,t=>/no real roots/i.test(t));},
 29:q=>input(q,Math.max(...quadratic(3,-5,-2))),
 30(q){const roots=quadratic(4,4,-3);qOption(q,t=>eqSet(rootsOption(t),roots));},
 31:q=>input(q,Math.max(...quadratic(1,-6,8))),
 32(q){const roots=quadratic(5,2,-3);qOption(q,t=>eqSet(rootsOption(t),roots));},
 33:q=>input(q,(16-8)/2),
 34(q){
  // x²+(p−2)x−2p=(x+p)(x−2), verified for several p and x.
  for(const p of [-10,-3,0,2,10])for(const x of [-4,0,2,5])
   assert.ok(approx(x*x+(p-2)*x-2*p,(x+p)*(x-2)));
  qOption(q,t=>approx(number(t),2));
 },
 35:q=>input(q,Math.max(...quadratic(1,0,-25))),
 36(q){
  const p=Math.max(...quadratic(6,-1,-2));
  const a=2,b=3;assert.ok(approx(p,a/b));
  input(q,a+b);
 },
 37(q){const f=x=>x*x-x-6>0;qOption(q,t=>!f(number(t)));},
 38:q=>interval(q,x=>x*x+x-6<=0,[-6,-3,-2,0,1,2,3,6]),
 39(q){input(q,Array.from({length:21},(_,i)=>i-10).filter(x=>x*x-4*x-5<0).length);},
 40:q=>interval(q,x=>-x*x+2*x+3>=0,[-5,-1,-0.5,0,2.99,3,3.1,5]),
 41:q=>interval(q,x=>(x-2)*(x-2)>9,[-5,-1.01,-1,-0.99,1,3,5,5.01,9]),
 42:q=>interval(q,x=>3*x*x-x-2<0,[-3,-2/3-0.01,-2/3,-2/3+0.01,0,0.99,1,1.01,2]),
 43:q=>input(q,Array.from({length:25},(_,i)=>i-12).filter(x=>(x+4)*(x-1)<=0).length),
 44(q){
   const truth=x=>(x+2)**2>0;
   const values=[-3,-2,-1,0,4];
   interval(q,truth,values);
  },
 45:q=>interval(q,x=>(x-3)**2<=0,[0,2.9,3,3.1,6]),
 46:q=>interval(q,x=>x*x-2*x-8>0,[-5,-2.01,-2,-1.99,1,3.99,4,4.01,10]),
 47(q){let roots=quadratic(1,-3,0);let p=roots.filter(x=>x>0);assert.equal(p.length,1);input(q,2*p[0]+3);},
 48(q){
   const target=[1,-3,-2];
   qOption(q,t=>polynomial(t).every((v,i)=>approx(v,target[i])));
 },
 49(q){const roots=quadratic(1,-4,0).filter(x=>x>0);assert.equal(roots.length,1);input(q,roots[0]);},
 50(q){const roots=quadratic(1,-2,4);qOption(q,t=>approx(number(t),roots.length));}
};
function numbers(s){return (String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(v=>v.replace(',','.')).sort().join('|');}
assert.equal(qs.size,25,'all 25 source questions required');
for(let i=26;i<=50;i++){
 try{
  const q=qs.get(i);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(i).padStart(3,'0'));
  assert.equal(q.practice_no,1);assert.ok(q.source_ref.includes('Ch1 Quadratics'));
  for(const l of ['en','ru','uz']){
   assert.ok(q.question[l]?.trim());assert.ok(q.explanation[l]?.trim());
   assert.equal(numbers(q.question[l]),numbers(q.question.en),'numeric source translation mismatch');
  }
  if(q.qtype==='mcq'){
   assert.deepEqual(q.options.map(z=>z.key),['A','B','C','D']);
   for(const l of ['en','ru','uz'])
    assert.equal(new Set(q.options.map(z=>plain(z.text[l]))).size,4);
   for(const z of q.options)if(z.key===q.correct_answer)assert.equal(z.diagnostic_code,null);
    else assert.ok(z.diagnostic_code);
  }
  tests[i](q);
 }catch(err){console.error('FAIL block02 Q'+String(i).padStart(3,'0')+': '+err.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block02 Q026–Q050 independent quadratic/inequality/intersection proofs and EN/RU/UZ literals; zero keys printed');
