#!/usr/bin/env node
'use strict';
// Mathematics Practice Block04 Q076–Q100: domain/range/composition/inverse
// Independent evaluators, single-valid MCQ, answer contract and trilingual invariants.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const dir=path.resolve(__dirname,'../content/math/practice_v2/p2_functions');
const files=['P1-FUN-01','P1-FUN-02','P1-FUN-03','P1-FUN-04'];
const qs=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(dir,f+'.json'),'utf8')).questions)
 .filter(q=>+q.key.slice(-3)>=76&&+q.key.slice(-3)<=100).map(q=>[+q.key.slice(-3),q]));
const plain=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const decimal=s=>plain(s).replace(',','.');
const num=s=>/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/.test(decimal(s))?Number(decimal(s)):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-8;
const qopt=(q,pred)=>{assert.equal(q.qtype,'mcq');const a=q.options.filter(t=>pred(t.text.en));assert.equal(a.length,1,'non-unique or absent MCQ answer');assert.equal(a[0].key,q.correct_answer);};
const input=(q,a)=>{assert.equal(q.qtype,'input');assert.ok(near(num(q.answer_contract.canonical_answer),a),'wrong numeric answer');assert.equal(q.answer_contract.number_only,true);
 for(const v of q.answer_contract.accepted_examples||[])assert.ok(near(num(v),a),'bad accepted input example');
 for(const v of q.answer_contract.rejected_examples||[])assert.ok(!near(num(v),a),'incorrect rejection');
};
function mathTokens(s){return(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(t=>t.replace(',','.')).sort().join('|');}
// Untrusted source expressions only; implement arithmetic grammar, NOT eval / Function.
function evalExpr(input,x){
 const raw=plain(input).replace(/²/g,'^2').replace(/³/g,'^3').replace(/⁴/g,'^4');
 let tokens=raw.match(/\d+(?:\.\d+)?|x|[()+*/^−-]/g)||[];
 if(tokens.join('')!==raw)throw Error('unsupported algebraic expression');
 const withMul=[];for(let i=0;i<tokens.length;i++){
  const t=tokens[i],prev=withMul.at(-1);
  if(prev!==undefined&&(/^(?:x|\d+(?:\.\d+)?|\))$/.test(prev))&&(/^(?:x|\d+(?:\.\d+)?|\()$/.test(t)))withMul.push('*');
  withMul.push(t);
 }
 tokens=withMul;let p=0;
 function atom(){
  const t=tokens[p++];
  if(t==='('){const v=sum();if(tokens[p++]!==')')throw Error('missing )');return v;}
  if(t==='x')return x;
  if(/^\d+(?:\.\d+)?$/.test(t))return Number(t);
  throw Error('bad atomic term');
 }
 function power(){let val=atom();if(tokens[p]==='^'){p++;const exponent=unary();val=val**exponent;}return val;}
 function unary(){if(tokens[p]==='-'){p++;return -unary();}if(tokens[p]==='+'){p++;return unary();}return power();}
 function product(){let v=unary();while(tokens[p]==='*'||tokens[p]==='/'){const op=tokens[p++];const b=unary();v=op==='*'?v*b:v/b;}return v;}
 function sum(){let v=product();while(tokens[p]==='+'||tokens[p]==='-'){const op=tokens[p++];const b=product();v=op==='+'?v+b:v-b;}return v;}
 const result=sum();if(p!==tokens.length)throw Error('trailing expression');return result;
}
function sameExpr(q,expected){
 const xs=[-3,-1,0,2,4.5];
 qopt(q,t=>xs.every(x=>near(evalExpr(t,x),expected(x))));
 // Unique mathematical value signatures for distractor audit.
 const signatures=q.options.map(o=>xs.map(x=>evalExpr(o.text.en,x)).join('|'));
 assert.equal(new Set(signatures).size,4,'algebraically duplicate distractor');
}
function rangeExact(q,lo,hi,loIncluded=true,hiIncluded=true){
 const fmt=plain;
 qopt(q,t=>{
  const s=fmt(t),m=/^(-?\d+(?:\.\d+)?)([<≤])f\(x\)([<≤])(-?\d+(?:\.\d+)?)$/.exec(s);
  if(!m)return false;
  return near(+m[1],lo)&&near(+m[4],hi)&&
   m[2]===(loIncluded?'≤':'<')&&m[3]===(hiIncluded?'≤':'<');
 });
}
function oneBound(q,op,edge){
 qopt(q,t=>{const m=/^f\(x\)([<>≤≥])(-?\d+(?:\.\d+)?)$/.exec(plain(t));return !!m&&m[1]===op&&near(Number(m[2]),edge);});
}
const cases={
 76:q=>input(q,((2*4-2+3)-(2*1+1+3))),
 77:q=>rangeExact(q,0,16),
 78:q=>rangeExact(q,1,10),
 79:q=>rangeExact(q,-5,7,true,false),
 80:q=>input(q,(3-3)**2+2),
 81:q=>rangeExact(q,-16,8),
 82:q=>oneBound(q,'≥',-3),
 83(q){const f=x=>2*x*x-8*x+1;input(q,Math.max(f(-1),f(3)));},
 84:q=>rangeExact(q,-4,5),
 85:q=>rangeExact(q,-1,4,false,true),
 86:q=>oneBound(q,'≤',4),
 87:q=>sameExpr(q,x=>x*x-2),
 88:q=>input(q,2*(2*2-1)+5),
 89:q=>sameExpr(q,x=>1-(3*x-2)),
 90:q=>input(q,2*((-2)**2+2)-1),
 91(q){assert.ok([0,1,4].some(x=>(x+2)**2!==x*x+2));qopt(q,t=>t.includes('f(g(x))=(x+2)²')&&t.includes('g(f(x))=x²+2'));},
 92:q=>input(q,(25-4)/3),
 93(q){
  const samples=[-100,0,1.99,2,2.01,3,10];
  qopt(q,t=>{
   const s=plain(t);
   if(s==='Allrealx')return false;
   const m=/^x([≤≥<>])(-?\d+)$/.exec(s);if(!m)return false;
   const b=Number(m[2]),c=m[1];
   const ok=x=>c==='≤'?x<=b:c==='<'?x<b:c==='≥'?x>=b:x>b;
   return samples.every(x=>ok(x)===(4-2*x>=0));
  });
 },
 94(q){const f=x=>x*x-1,g=x=>x+3;input(q,f(g(-4))+g(f(2)));},
 95:q=>qopt(q,t=>near(num(t),2)),
 96(q){const vals=[(1+5)/2,(1-5)/2];input(q,vals.find(x=>x>0));},
 97(q){const xvalues=[-3,-2,-1,0,1,2,3,4];qopt(q,t=>{const s=plain(t).replace(/^f\(x\)=/,'');const v=xvalues.map(x=>evalExpr(s,x));return new Set(v).size===xvalues.length;});},
 98:q=>input(q,3*5+7),
 99(q){const ys=[-9,-1,0,3,9];qopt(q,t=>ys.every(y=>near(evalExpr(t,y),(y-1)/2)));},
 100(q){const ys=[-9,-1,0,3,9];qopt(q,t=>ys.every(y=>near(evalExpr(t,y),(2*y+5)/3)));}
};
assert.equal(qs.size,25,'Q076–Q100 exactly');
const narrowed=new Set([78,81,85,86]);
for(let id=76;id<=100;id++){
 try{const q=qs.get(id);assert.ok(q,'missing question');
  assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
  assert.equal(q.practice_no,2);assert.ok(q.source_ref.includes('Ch2'));
  for(const l of ['en','ru','uz']){
   assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim(),'language missing');
   assert.equal(mathTokens(q.question[l]),mathTokens(q.question.en),'trilingual number parity');
  }
  if(narrowed.has(id)){
   assert.ok(q.question.en.includes('exact range'),'precise range missing in EN');
   assert.ok(q.question.ru.includes('точно задаёт область значений'),'precise range missing in RU');
   assert.ok(q.question.uz.includes('qiymatlar to‘plamini aynan ifodalaydi'),'precise range missing in UZ');
  }
  if(q.qtype==='mcq'){
   assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D']);
   for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>plain(o.text[l]))).size,4,'duplicate displayed option');
   for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);
     else assert.ok(o.diagnostic_code);
  }
  cases[id](q);
 }catch(e){console.error('FAIL block04 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block04 Q076–Q100 domain/range, composition/inverse algebra, MCQ uniqueness, 4 exact-range clarifications and three-language contracts');
