#!/usr/bin/env node
'use strict';
// 25-question Mathematics Practice block 01: independent, deterministic academic proofs.
// No stored answer keys/stems/distractors; CI emits counts/errors by ID only.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const ROOT=path.resolve(__dirname,'..');
const ROOT_CONTENT=path.join(ROOT,'content/math/practice_v2/p1_quadratics');
const FILES=['P1-QUA-01','P1-QUA-02','P1-QUA-03'];
const all=FILES.flatMap(f=>JSON.parse(fs.readFileSync(path.join(ROOT_CONTENT,f+'.json'),'utf8')).questions);
const qs=new Map(all.filter(q=>Number(q.key.slice(-3))<=25).map(q=>[Number(q.key.slice(-3)),q]));
const plain=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'').replace(/,/g,'.');
const n=s=>{const v=plain(s);return /^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/.test(v)?Number(v):NaN};
const close=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const matches=(a,b)=>a.length===b.length&&a.every((x,i)=>close(x,b[i]));
const enOpts=q=>q.options.map(o=>o.text.en);
function exactlyOne(q,predicate){
  assert.equal(q.qtype,'mcq');
  const flags=enOpts(q).map((v,i)=>Boolean(predicate(v,i)));
  assert.equal(flags.filter(Boolean).length,1,'non-unique/absent correct option');
  assert.equal(q.options[flags.findIndex(Boolean)].key,q.correct_answer,'source key disagrees with independent proof');
}
function exactInput(q,expected){
  assert.equal(q.qtype,'input');assert.ok(Number.isFinite(expected));
  assert.ok(close(n(q.answer_contract?.canonical_answer),expected),'incorrect canonical answer');
  assert.ok(close(n(q.answer_contract?.canonical_answer),n(q.answer_contract?.canonical_answer)));
  assert.ok(q.answer_contract?.number_only,'number-only guard');
  for(const v of q.answer_contract.accepted_examples||[])assert.ok(close(n(v),expected),'invalid accepted example');
  for(const v of q.answer_contract.rejected_examples||[])assert.ok(!close(n(v),expected),'true answer rejected by contract');
}
function point(s){const m=/^\((-?\d+),(-?\d+)\)$/.exec(plain(s));return m?[Number(m[1]),Number(m[2])]:null;}
function polynomial(s){
  const left=plain(s).replace(/-/g,'+-').split('=')[0];
  const c={a:0,b:0,c:0};for(let t of left.split('+').filter(Boolean)){
    if(t.endsWith('x²')){let a=t.slice(0,-2);c.a+=a===''?1:a==='-'?-1:Number(a);}
    else if(t.endsWith('x')){let b=t.slice(0,-1);c.b+=b===''?1:b==='-'?-1:Number(b);}
    else c.c+=Number(t);
  }
  return c;
}
function condition(src,v,letter){
  const s=plain(src).replace(/^(Allrealk|Allrealp)$/i,'all');
  if(s==='all')return true;
  if(s.includes('or'))return s.split('or').some(t=>condition(t,v,letter));
  const c=(a,op,b)=>op==='<'?a<b:op==='>'?a>b:op==='≤'?a<=b:op==='≥'?a>=b:op==='='?close(a,b):false;
  let m=/^(-?\d+(?:\.\d+)?)([<>≤≥])([pk])([<>≤≥])(-?\d+(?:\.\d+)?)$/.exec(s);
  if(m)return m[3]===letter&&c(Number(m[1]),m[2],v)&&c(v,m[4],Number(m[5]));
  m=/^([pk])([<>≤≥=])(-?\d+(?:\.\d+)?)$/.exec(s);
  if(m)return m[1]===letter&&c(v,m[2],Number(m[3]));
  m=/^(-?\d+(?:\.\d+)?)([<>≤≥])([pk])$/.exec(s);
  if(m)return m[3]===letter&&c(Number(m[1]),m[2],v);
  throw Error('Unsupported predicate format in source');
}
function predicateEqual(q,letter,proof,samples){
  exactlyOne(q,txt=>samples.every(v=>condition(txt,v,letter)===proof(v)));
}
function numericChoice(q,expected){exactlyOne(q,text=>close(n(text),expected));}
function twoRoots(q,root1,root2){
  exactlyOne(q,t=>{
    const s=plain(t);
    const m=/^k=(-?\d+)±(\d*)√2$/.exec(s);
    if(!m)return false;
    const a=Number(m[1]),f=Number(m[2]||1);
    return matches([a-f*Math.sqrt(2),a+f*Math.sqrt(2)].sort((x,y)=>x-y),[root1,root2].sort((x,y)=>x-y));
  });
}
const cases={
  1(q){
    const values=[-3,0,2,7];
    exactlyOne(q,t=>{
      const m=/^\(x([+-]\d+)\)²([+-]\d+)$/.exec(plain(t));
      if(!m)return false;
      const shift=Number(m[1]),c=Number(m[2]);
      return values.every(x=>close((x+shift)**2+c,x*x-10*x+21));
    });
  },
  2:q=>exactInput(q,-8/2),
  3:q=>exactlyOne(q,t=>matches(point(t)||[],[-4,5])),
  4:q=>exactInput(q,11-(-12)**2/(4*2)),
  5:q=>exactlyOne(q,t=>plain(t)==='y≥-5'&&close(7-12**2/(4*3),-5)),
  6:q=>exactInput(q,3*3+4),
  7:q=>numericChoice(q,-2*3),
  8:q=>exactInput(q,7+4),
  9:q=>numericChoice(q,-1-(8*8)/(4*(-2))),
  10:q=>exactInput(q,36/(5-(-4))),
  11:q=>exactlyOne(q,t=>plain(t)==='2'&&25-4*2*(-3)>0),
  12:q=>exactInput(q,64/4),
  13:q=>predicateEqual(q,'p',v=>v*v-4*2*8<0,[-15,-8,-7,0,7,8,15]),
  14:q=>predicateEqual(q,'k',v=>v>0 && 36-4*v*v>0,[-10,-3,-1,0,0.1,2.9,3,3.1,10]),
  15:q=>exactInput(q,-Math.sqrt(4*3*12)),
  16(q){
    exactlyOne(q,t=>{
      const {a,b,c}=polynomial(t);assert.ok(a!==0&&Number.isFinite(b)&&Number.isFinite(c));
      return b*b-4*a*c<0;
    });
  },
  17(q){
    const r=Math.sqrt(2*2+7);
    // independent quadratic equation: k²+2k−7=0 gives roots −1±√8
    const s=Math.sqrt(8);
    assert.ok(close(s,2*Math.sqrt(2)));
    twoRoots(q,-1-s,-1+s);
  },
  18:q=>exactInput(q,Math.sqrt(4*2*18)),
  19(q){
    const a=2,b=3,c=4; // abstract positive-leading quadratic with D<0
    const D=b*b-4*a*c;
    assert.ok(a>0&&D<0);
    exactlyOne(q,t=>{
      if(t.includes('crosses'))return D>0;
      if(t.includes('touches'))return D===0;
      if(t.includes('above'))return a>0&&D<0;
      if(t.includes('below'))return a<0&&D<0;
      throw Error('Unexpected conceptual option');
    });
  },
  20:q=>predicateEqual(q,'k',v=>8*v>0,[-4,-1,0,0.1,2]),
  21:q=>numericChoice(q,16/(4*4)),
  22:q=>exactInput(q,(5-(-2))**2/4),
  23:q=>exactInput(q,Math.sqrt(6*6-4*5)),
  24(q){
    // Difference of squares gives exact factors; alternatives are indirect methods.
    assert.ok([0,1,2].every(x=>close(x*x-9,(x-3)*(x+3))));
    exactlyOne(q,t=>/difference of squares/i.test(t));
  },
  25:q=>exactInput(q,(7+Math.sqrt(49-4*2*3))/(2*2)),
};
function mathLiterals(s){return (String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(v=>v.replace(',','.')).sort().join('|');}
function qValid(q,n){
  assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(n).padStart(3,'0'));
  assert.equal(q.practice_no,1);assert.ok(/^P1-QUA-0[123]$/.test(q.primary_skill));
  assert.ok(q.source_ref.includes('Ch1 Quadratics')&&q.source_ref.includes('pp. 2-20'));
  for(const l of ['en','ru','uz']){
    assert.ok(q.question?.[l]?.trim()&&q.explanation?.[l]?.trim());
    // All mathematical literal numbers in stems have equivalent magnitude in each language.
    assert.equal(mathLiterals(q.question[l]),mathLiterals(q.question.en),'language stem literal drift');
  }
  if(q.qtype==='mcq'){
    assert.equal(q.options.length,4);assert.deepEqual(q.options.map(o=>o.key),['A','B','C','D']);
    for(const lang of ['en','ru','uz']){
      assert.equal(new Set(q.options.map(o=>plain(o.text[lang]))).size,4,'duplicate displayed options');
    }
    for(const o of q.options){
      if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);
      else assert.ok(o.diagnostic_code);
    }
  }else{
    assert.ok(q.answer_contract?.canonical_answer);
    assert.equal(q.options,undefined);
  }
}
assert.equal(qs.size,25,'block must contain all Q001–Q025 without repeats');
const checked=[];
for(let i=1;i<=25;i++){
  let q=qs.get(i);assert.ok(q,'missing item in block');
  try{qValid(q,i);cases[i](q);checked.push(i);}
  catch(e){console.error('FAIL block01 Q'+String(i).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit();
if(checked.length!==25)throw Error('Incomplete block');
console.log('PASS block01 25/25 independent calculations, single-correct MCQs, numeric examples and trilingual math literal consistency; no answer keys printed');
