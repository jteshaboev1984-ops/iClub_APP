#!/usr/bin/env node
'use strict';
// Independent P1 Practice block03 (Q051–Q075) proofs; protected content is read,
// verified, and never printed. Do not confuse English lexical concept checks with proof of translations.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const dir=path.resolve(__dirname,'../content/math/practice_v2');
const files=['p1_quadratics/P1-QUA-05','p1_quadratics/P1-QUA-06','p2_functions/P1-FUN-01'];
const qset=new Map(files.flatMap(file=>JSON.parse(fs.readFileSync(path.join(dir,file+'.json'),'utf8')).questions)
 .filter(q=>+q.key.slice(-3)>=51&&+q.key.slice(-3)<=75).map(q=>[+q.key.slice(-3),q]));
const s=x=>String(x||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const numeric=x=>/^[+-]?(?:\d+(?:[.,]\d*)?|\.\d+)$/.test(s(x))?Number(s(x).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-8;
const setEq=(a,b)=>a.length===b.length&&a.slice().sort((x,y)=>x-y).every((v,i)=>near(v,b.slice().sort((x,y)=>x-y)[i]));
const integer=r=>Number.isInteger(r)&&r>=0;
function input(q,expected){
 assert.equal(q.qtype,'input');assert.ok(near(numeric(q.answer_contract.canonical_answer),expected));
 assert.equal(q.answer_contract.number_only,true);
 for(const ex of q.answer_contract.accepted_examples||[])assert.ok(near(numeric(ex),expected),'bad accepted example');
 for(const ex of q.answer_contract.rejected_examples||[])assert.ok(!near(numeric(ex),expected),'bad rejected example');
}
function correctMCQ(q,matcher){
 assert.equal(q.qtype,'mcq');const good=q.options.filter(o=>matcher(o.text.en));
 assert.equal(good.length,1,'non-unique MCQ');
 assert.equal(good[0].key,q.correct_answer,'source key/independent proof conflict');
}
function quadratic(a,b,c){const D=b*b-4*a*c;return D<0?[]:D===0?[-b/(2*a)]:[(-b-Math.sqrt(D))/(2*a),(-b+Math.sqrt(D))/(2*a)];}
function fraction(st){
 const t=s(st);const m=/^(-?\d+)(?:\/(\d+))?$/.exec(t);return m?Number(m[1])/Number(m[2]||1):NaN;
}
function parsePair(st){
 const m=/^\(x,y\)=\((-?\d+(?:\/\d+)?),(-?\d+(?:\/\d+)?)\)$/.exec(s(st));
 return m?[fraction(m[1]),fraction(m[2])]:null;
}
function parseRoots(st,varName='x'){
 const t=s(st),m=t.split('and');
 if(m.length!==2)return [];
 const out=m.map(x=>x.replace(new RegExp('^'+varName+'='),'')).map(fraction);
 return out.every(Number.isFinite)?out:[];
}
function parseParamPair(st,p='a'){
 const t=s(st),m=t.split('or');if(m.length!==2)return [];
 const out=m.map(x=>x.replace(new RegExp('^'+p+'='),'')).map(fraction);
 return out.every(Number.isFinite)?out:[];
}
function literalNumbers(st){
 return (String(st||'').normalize('NFC').replace(/[−–—]/g,'-')
 .match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(v=>v.replace(',','.')).sort().join('|');
}
const tests={
 51:q=>input(q,quadratic(1,3,-10).find(x=>x>0)),
 52(q){
  const ys=quadratic(2,1,-6),y=ys.find(v=>v>0);assert.ok(near(y,1.5));
  correctMCQ(q,t=>{const pair=parsePair(t);return !!pair&&near(pair[1],y)&&near(pair[0],y+1);});
 },
 53:q=>input(q,quadratic(1,2,-48).find(x=>x>0)),
 54(q){const amp=Math.sqrt(4*(7-3));correctMCQ(q,t=>setEq(parseParamPair(t),[-amp,amp]));},
 55:q=>input(q,Math.max(...quadratic(1,-5,6))),
 56(q){
  const ys=quadratic(5,4,-9),y=ys.find(v=>v>0);
  correctMCQ(q,t=>{const pair=parsePair(t);return !!pair&&near(pair[1],y)&&near(pair[0],1+2*y);});
 },
 57:q=>input(q,Math.max(...quadratic(1,-13,40))),
 58(q){const a=2-4,b=2+4;correctMCQ(q,t=>setEq(parseParamPair(t),[a,b]));},
 59(q){
  for(const x of [-2,0,1,3]){const y=x*x;assert.ok(near(x**4-5*x*x+4,y*y-5*y+4));}
  correctMCQ(q,t=>s(t)==='y=x²');
 },
 60(q){
  const ys=quadratic(1,-5,4),roots=ys.flatMap(y=>[1-Math.sqrt(y),1+Math.sqrt(y)]);
  input(q,Math.max(...roots));
 },
 61(q){
  const ys=quadratic(1,-7,-8),roots=ys.map(y=>Math.cbrt(y));
  correctMCQ(q,t=>setEq(parseRoots(t),roots));
 },
 62(q){
  const ys=quadratic(2,-5,-3),valid=ys.filter(v=>v>=0).flatMap(v=>[-Math.sqrt(v),Math.sqrt(v)]);
  assert.equal(valid.length,2);
  // The only full real-solution option is ±√3 (not the extra imaginary roots).
  correctMCQ(q,t=>s(t)==='x=±√3'&&setEq(valid,[-Math.sqrt(3),Math.sqrt(3)]));
 },
 63(q){
  correctMCQ(q,t=>{
   const x=s(t).split('=')[0];return x.includes('x⁶')&&x.includes('x³')&&!x.includes('x⁹')&&!x.includes('x⁴')&&!x.includes('x²');
  });
 },
 64(q){
  const ys=quadratic(1,-17,16);
  input(q,ys.filter(v=>v>0).length*2);
 },
 65(q){assert.equal(quadratic(1,4,3).filter(v=>v>=0).length,0);correctMCQ(q,t=>near(numeric(t),0));},
 66(q){assert.ok(near((3*(Math.sqrt(5/3)**2)-5)**2,0));correctMCQ(q,t=>near(numeric(t),2));},
 67(q){let y=quadratic(1,-9,20);correctMCQ(q,t=>near(numeric(t),y.filter(v=>v>0).length));},
 68(q){const a=-2*4;assert.ok(near(4*4+a*4+16,0));correctMCQ(q,t=>near(numeric(t),a));},
 69:q=>correctMCQ(q,t=>/Each allowed x is paired with exactly one y/i.test(t)),
 70:q=>correctMCQ(q,t=>s(t)==='Domain{1,2,3};range{4,7}'),
 71(q){correctMCQ(q,t=>{
  const outputs=String(t).match(/→\s*(-?\d+)/g)||[];
  if(outputs.length!==3)return false;
  return new Set(outputs.map(x=>Number(x.split('→')[1]))).size===3;
 });},
 72:q=>correctMCQ(q,t=>/reverses the input-output mapping when an inverse function exists/i.test(t)),
 73:q=>correctMCQ(q,t=>/Apply g first, then apply f/i.test(t)),
 74:q=>correctMCQ(q,t=>/Two different allowed inputs give the same output/i.test(t)),
 75(q){
  const mapping=new Map([[-2,5],[0,1],[3,5]]);assert.equal(mapping.size,3);
  assert.ok(new Set([...mapping.values()]).size<mapping.size);
  correctMCQ(q,t=>/is a function but is not one-to-one/i.test(t));
 }
};
assert.equal(qset.size,25);
for(let id=51;id<=75;id++){
 try{
  const q=qset.get(id);assert.ok(q,'missing item');
  assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
  assert.ok(q.source_ref.includes('Complete Pure Mathematics 1'));
  assert.ok(q.practice_no===(id<=68?1:2));
  for(const l of ['en','ru','uz']){
   assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());
   assert.equal(literalNumbers(q.question[l]),literalNumbers(q.question.en),'stem numeric parity');
  }
  if(q.qtype==='mcq'){
   assert.deepEqual(q.options.map(x=>x.key).sort(),['A','B','C','D']);
   for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(x=>s(x.text[l]))).size,4);
   for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);
    else assert.ok(o.diagnostic_code);
  }
  tests[id](q);
 }catch(e){console.error('FAIL block03 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block03 Q051–Q075 mathematics, single-key MCQ, locale literals and input bounds; no protected keys logged');
