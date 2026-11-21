#!/usr/bin/env node
'use strict';
// #574 · Nine genuine Hard-transfer authored questions.
// Independent calculation oracle; no live database, no learner rows, no answer
// keys or protected question text printed. Archive-equivalence / immutability
// are independently checked by the 495-question source guard.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const ROOT=path.resolve(__dirname,'..');
const items=[
 [7511,'p1_quadratics/P1-QUA-03.json','P1-QUA-03'],
 [7585,'p2_functions/P1-FUN-04.json','P1-FUN-04'],
 [7692,'p3_coordinate_geometry/P1-COO-06.json','P1-COO-06'],
 [7723,'p4_circular_trigonometry/P1-CIR-03.json','P1-CIR-03'],
 [7769,'p4_circular_trigonometry/P1-TRI-05.json','P1-TRI-05'],
 [7823,'p5_binomial_series/P1-SER-04.json','P1-SER-04'],
 [7835,'p5_binomial_series/P1-SER-05.json','P1-SER-05'],
 [7908,'p6_differentiation/P1-DIF-07.json','P1-DIF-07'],
 [7974,'p7_integration/P1-INT-05.json','P1-INT-05']
];
const near=(a,b)=>Math.abs(a-b)<1e-9;
const derived=new Map();

// Q027: graph vertex -> coefficient b; y-intercept -> c; roots -> positive root.
{
 const vertexX=1/2,c=-12,b=-2*vertexX;
 const d=b*b-4*c,roots=[(-b+Math.sqrt(d))/2,(-b-Math.sqrt(d))/2];
 assert.ok(roots.every(x=>near(x*x+b*x+c,0)));
 derived.set(7511,Math.max(...roots));
}
// Q101: two inverse-function data points -> affine slope -> inverse difference.
{
 const x1=2,y1=-1,x2=6,y2=0;
 const slope=(y2-y1)/(x2-x1),intercept=y1-slope*x1;
 assert.ok(slope>0 && near(slope*x1+intercept,y1) && near(slope*x2+intercept,y2));
 derived.set(7585,(5-3)/slope);
}
// Q208: diameter -> circle centre/radius -> two tangents -> sum of intercepts.
{
 const A=[0,-3],B=[2,1],centre=[(A[0]+B[0])/2,(A[1]+B[1])/2];
 const radius=Math.hypot(B[0]-A[0],B[1]-A[1])/2,normal=Math.hypot(2,-1);
 const offset=2*centre[0]-centre[1];
 const intercepts=[radius*normal-offset,-radius*normal-offset];
 assert.ok(intercepts.every(p=>near(Math.abs(offset+p)/normal,radius)));
 derived.set(7692,intercepts.reduce((a,b)=>a+b,0));
}
// Q239: annular sector area and width -> sum of radii -> full perimeter.
{
 const theta=2,area=5,width=1;
 const sum=2*area/(theta*width),R=(sum+width)/2,r=(sum-width)/2;
 assert.ok(R>r&&r>0&&near((R*R-r*r)*theta/2,area));
 derived.set(7723,theta*sum+2*width);
}
// Q285: union of roots of two translated trig factors within [0,360).
{
 const rad=x=>x*Math.PI/180;
 const roots=[];
 for(let x=0;x<360;x++){
  if(near(2*Math.sin(rad(x-30))-1,0)||near(2*Math.cos(rad(x))+1,0))roots.push(x);
 }
 assert.equal(new Set(roots).size,roots.length);
 assert.ok(roots.every(x=>x>=0&&x<360));
 derived.set(7769,roots.length);
}
// Q339: nonadjacent GP terms permit +/- ratios; positive first term selects one.
{
 const u2=6,u4=54;
 const roots=[Math.sqrt(u4/u2),-Math.sqrt(u4/u2)];
 const valid=roots.filter(r=>u2/r>0);
 assert.equal(valid.length,1);
 const first=u2/valid[0];
 assert.ok(near(first*(valid[0]**3),u4));
 derived.set(7823,first+2);
}
// Q351: second term + infinite sum -> quadratic with a restricted ratio.
{
 const u2=15/4,total=20,disc=1-4*u2/total;
 assert.ok(disc>0);
 const possible=[(1-Math.sqrt(disc))/2,(1+Math.sqrt(disc))/2];
 const valid=possible.filter(r=>r>0&&r<1/2);
 assert.equal(valid.length,1);
 const r=valid[0],a=total*(1-r);
 assert.ok(near(a*r,u2)&&near(a/(1-r),total));
 derived.set(7835,r);
}
// Q424: wall and one partition -> 3 depths + 1 width, strict maximum.
{
 const fence=18,depth=fence/(2*3),width=fence-3*depth;
 const area=x=>x*(fence-3*x);
 assert.ok(depth>0&&width>0&&near(area(depth),depth*width));
 assert.ok(area(depth)>area(depth-0.1)&&area(depth)>area(depth+0.1));
 derived.set(7908,depth);
}
// Q490: solve coupled integral area/solid-volume constraints.
{
 const twiceArea=9,volumeDivPiTimes3=27;
 const upper=twiceArea**2/volumeDivPiTimes3,k=twiceArea/(upper**2);
 assert.ok(upper>0&&k>0);
 assert.ok(near(k*upper**2/2,9/2));
 assert.ok(near(k*k*upper**3/3,9));
 derived.set(7974,upper);
}

const digits=v=>[...String(v).replace(/[−–—]/g,'-')
 .matchAll(/-?\d+(?:[.,]\d+)?(?:\/\d+)?/g)]
 .map(x=>x[0].replace(',','.')).sort();
const seen=new Set();
for(const [id,file,skill] of items){
 const bank=JSON.parse(fs.readFileSync(
  path.join(ROOT,'content/math/practice_v2',file),'utf8'));
 const key='MATH-P1-PRACTICE2-Q'+String(id-7484).padStart(3,'0');
 const q=bank.questions.find(x=>x.key===key);
 assert.ok(q,'missing governed Hard author question');
 assert.ok(!seen.has(id),'repeated Hard author ID');
 seen.add(id);
 assert.equal(q.primary_skill,skill);
 assert.equal(q.qtype,'input');
 assert.equal(q.difficulty,'hard');
 assert.ok(['integer_exact','numeric_exact'].includes(q.answer_contract.kind),
   'unsupported deterministic numeric input contract');
 assert.equal(q.answer_contract.number_only,true);
 assert.ok(near(Number(q.answer_contract.canonical_answer),derived.get(id)),
   'independently derived answer disagrees with original deterministic contract');
 assert.equal(Object.keys(q.question).length,3);
 assert.equal(Object.keys(q.explanation).length,3);
 const originalTokens=digits(q.question.en);
 for(const lang of ['en','ru','uz']){
  assert.ok(q.question[lang].length>30&&q.explanation[lang].length>40,
    'missing complete localized reasoning');
  assert.deepEqual(digits(q.question[lang]),originalTokens,
    'numerical premise differs between languages');
 }
}
assert.equal(seen.size,9);
assert.equal(new Set(items.map(x=>x[2])).size,9);
console.log(JSON.stringify({status:'PASS',nine_hard_transfer_math_proofs:true,
  scoped_items:9,distinct_skills:9,locales_checked:3,
  numeric_answer_contract_preserved:true,question_numeric_premise_parity:true,
  tour_or_student_records_accessed:false,protected_answers_printed:false}));
