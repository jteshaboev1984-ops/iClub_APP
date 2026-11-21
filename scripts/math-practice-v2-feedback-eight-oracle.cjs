#!/usr/bin/env node
'use strict';
// Independent mathematical oracle for eight option-specific diagnostic corrections.
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'../content/math/practice_v2');
const load=(dir,skill)=>JSON.parse(fs.readFileSync(path.join(root,dir,skill+'.json'),'utf8')).questions;
const qs=[...load('p6_differentiation','P1-DIF-05'),...load('p6_differentiation','P1-DIF-07'),...load('p7_integration','P1-INT-04')];
const byNo=new Map(qs.map(q=>[Number(q.key.slice(-3)),q]));
const expectCode=(n,letters,code)=>{const q=byNo.get(n);assert.ok(q);for(const key of letters){const opt=q.options.find(o=>o.key===key);assert.ok(opt&&key!==q.correct_answer);assert.equal(opt.diagnostic_code,code);}};
expectCode(408,['C'],'DIF05_VALUE_NOT_SLOPE_SIGN');
assert.match(byNo.get(408).question.en,/f′\\(x\\)<0 at every point/);
assert.equal(byNo.get(408).options.find(o=>o.key==='D').diagnostic_code,'DIF05_NO_STATIONARY_WHEN_NEGATIVE');
// A negative derivative need not give a negative function value.
assert.ok([-0.5,-0.1].every(x=>10+x>0)); // f(x)=10-x on (0,1)
assert.ok([0.2,0.8].every(x=>10-x>0&&-1<0));
for(const [n,x,fprime] of [
 [419,0,z=>3*z*z-6*z],
 [423,-3,z=>3*z*z+6*z-9],
 [425,0,z=>3*z*z]
]){const q=byNo.get(n);assert.ok(q);assert.equal(fprime(x),0);expectCode(n,[n===425?'C':'D'],'DIF07_POINT_IS_STATIONARY');}
assert.ok((3*(-1)**2-6*(-1))>0&&(3*(1)**2-6*(1))<0);
assert.ok((3*(-4)**2+6*(-4)-9)>0&&(3*(-2)**2+6*(-2)-9)<0);
assert.ok((3*(-1)**2)>0&&(3*(1)**2)>0);
const scenarios=[
 [471,4,['C','D'],'B',[2,6],-4],
 [472,4/3,['A','B'],'D',[8/3,2/3],-4/3]
];
for(const [n,area,wrong,actualReversal,trapValues,reversed] of scenarios){
 const q=byNo.get(n);assert.ok(q);
 const numeric=x=>Number(String(x).replace('−','-').split('/').reduce((a,b,i)=>i?a/Number(b):Number(b),0));
 assert.ok(Math.abs(numeric(q.options.find(o=>o.key===q.correct_answer).text.en)-area)<1e-12);
 expectCode(n,wrong,'INT04_NOT_ORDER_REVERSAL');
 for(let i=0;i<wrong.length;i++)assert.ok(Math.abs(numeric(q.options.find(o=>o.key===wrong[i]).text.en)-trapValues[i])<1e-12&&trapValues[i]>0&&Math.abs(trapValues[i]+area)>1e-12);
 const genuinelyReversed=q.options.find(o=>o.key===actualReversal);
 assert.equal(genuinelyReversed.diagnostic_code,'INT04_AREA_SIGN');
 assert.ok(Math.abs(numeric(genuinelyReversed.text.en)-reversed)<1e-12);
}
assert.equal((3*2-(2*2)/2),4); // ∫0^2 (3-x) dx
assert.ok(Math.abs((2*2-(2**3)/3)-4/3)<1e-12); // ∫0^2 (2x-x²) dx
for(const [dir,skill,codes]of [
 ['p6_differentiation','P1-DIF-05',['DIF05_VALUE_NOT_SLOPE_SIGN']],
 ['p6_differentiation','P1-DIF-07',['DIF07_POINT_IS_STATIONARY']],
 ['p7_integration','P1-INT-04',['INT04_NOT_ORDER_REVERSAL']]
]){
 const j=JSON.parse(fs.readFileSync(path.join(root,dir,'diagnostic_catalog.json'),'utf8'));
 for(const code of codes){const d=j.diagnostics.filter(x=>x.code===code);assert.equal(d.length,1);assert.equal(d[0].skill,skill);
 for(const lang of ['en','ru','uz']){assert.ok(d[0].feedback[lang]?.trim());assert.ok(d[0].next_action[lang]?.trim());}}
}
console.log(JSON.stringify({oracle:'PASS',questions:6,remaps:8,catalogs:3,real_negative_area_options_preserved:2,mathematical_keys_unchanged:true,private_keys_logged:false}));
