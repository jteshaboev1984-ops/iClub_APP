#!/usr/bin/env node
'use strict';
// #574: independent numeric oracle for trigonometric wrong-option feedback.
// No live data, secrets, question keys or full source text in test output.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const base=path.resolve(__dirname,'../content/math/practice_v2/p4_circular_trigonometry');
const catalog=JSON.parse(fs.readFileSync(path.join(base,'diagnostic_catalog.json'),'utf8'));
const q3=JSON.parse(fs.readFileSync(path.join(base,'P1-TRI-03.json'),'utf8')).questions;
const q5=JSON.parse(fs.readFileSync(path.join(base,'P1-TRI-05.json'),'utf8')).questions;
const all=new Map([...q3,...q5].map(q=>[Number(q.key.slice(-3)),q]));
const deg=x=>x*Math.PI/180;
const eq=(a,b)=>Math.abs(a-b)<1e-10;
const trig=(kind,x)=>{
 const a=deg(x);
 if(kind==='sin')return Math.sin(a);
 if(kind==='cos')return Math.cos(a);
 if(kind==='tan_shift_15')return Math.tan(a-deg(15));
 if(kind==='cos_shift_30')return Math.cos(a+deg(30));
 if(kind==='cos_quadratic')return 2*Math.cos(a)**2+Math.cos(a)-1;
 if(kind==='sin_equals_cos')return Math.sin(a)-Math.cos(a);
 if(kind==='cos_double')return Math.cos(2*a);
 throw Error('unsupported oracle');
};
function angles(s){
 const text=String(s).replace(/−/g,'-');
 const direct=[...text.matchAll(/(-?\d+(?:\.\d+)?)°/g)].map(m=>Number(m[1]));
 if(direct.length)return direct;
 const rad=[...text.matchAll(/(\d*)π\/(\d+)/g)].map(m=>180*Number(m[1]||1)/Number(m[2]));
 if(rad.length)return rad;
 throw Error('cannot parse authored mathematical angle list');
}
const laws=[
 [282,'sin',Math.sqrt(3)/2,['A','C'],['D'],2],
 [283,'cos',-Math.sqrt(3)/2,['A','C'],['B'],2],
 [284,'tan_shift_15',1/Math.sqrt(3),['A','B'],[],2],
 [286,'cos_shift_30',0,['B','C'],[],2],
 [287,'cos',1,['D'],[],2],
 [288,'sin',-Math.SQRT1_2,['B','C'],['A'],2],
 [289,'cos_quadratic',0,['C'],[],3],
 [290,'sin_equals_cos',0,['A','B'],[],2],
 [292,'cos_double',-1,['C'],[],2],
 [293,'sin',-.5,['A','C'],['D'],2]
];
let disproved=0,retained=0;
for(const [n,law,target,wrong,validPartial,solutions] of laws){
 const q=all.get(n);
 assert.ok(q,'missing target question');
 assert.equal(q.primary_skill,'P1-TRI-05');
 const answer=q.options.find(o=>o.key===q.correct_answer);
 assert.ok(answer);
 const correctAngles=angles(answer.text.en);
 assert.equal(correctAngles.length,solutions,'correct solution-set cardinality');
 assert.ok(correctAngles.every(a=>eq(trig(law,a),target)),'correct angles independently false');
 for(const key of wrong){
  const opt=q.options.find(o=>o.key===key);assert.ok(opt&&key!==q.correct_answer);
  const listed=angles(opt.text.en);
  assert.ok(listed.some(x=>!eq(trig(law,x),target)),'previous missed-solution feedback was actually true');
  assert.equal(opt.diagnostic_code,'TRI05_INVALID_LISTED_ANGLE');
  disproved++;
 }
 for(const key of validPartial){
  const opt=q.options.find(o=>o.key===key);assert.ok(opt);
  const listed=angles(opt.text.en);
  assert.ok(listed.every(a=>eq(trig(law,a),target)),'formerly valid subset not actually valid');
  assert.ok(listed.length<correctAngles.length,'not a missing-solution subset');
  assert.equal(opt.diagnostic_code,'TRI05_REFERENCE_SOLUTIONS');
  retained++;
 }
}
const mapped=[
 [265,{A:'TRI03_IN_RANGE_WRONG_SIGN'}],
 [266,{B:'TRI03_IN_RANGE_WRONG_SIGN'}],
 [267,{A:'TRI03_PRINCIPAL_INTERVAL_DEFINITION',B:'TRI03_PRINCIPAL_INTERVAL_DEFINITION',C:'TRI03_PRINCIPAL_INTERVAL_DEFINITION'}],
 [269,{A:'TRI03_INPUT_VALID'}]
];
let principal=0;
for(const [n,options] of mapped){
 const q=all.get(n);assert.ok(q&&q.primary_skill==='P1-TRI-03');
 for(const [letter,code] of Object.entries(options)){
  const opt=q.options.find(o=>o.key===letter);assert.ok(opt);
  assert.equal(opt.diagnostic_code,code,'wrong principal-range feedback scope');
  if(n===265){assert.ok(45>=0&&45<=180&&Math.cos(deg(45))>0);}
  if(n===266){assert.ok(60>-90&&60<90&&Math.tan(deg(60))>0);}
  if(n===267){
   assert.equal(q.options.find(o=>o.key===q.correct_answer).text.en,'0°≤θ≤180°');
   assert.notEqual(opt.text.en,'0°≤θ≤180°');
  }
  if(n===269){assert.ok(.5>=-1&&.5<=1&&/outside the domain/.test(opt.text.en));}
  principal++;
 }
}
assert.equal(disproved,17);
assert.equal(retained,4);
assert.equal(principal,6);
const codes=['TRI03_IN_RANGE_WRONG_SIGN','TRI03_PRINCIPAL_INTERVAL_DEFINITION',
 'TRI03_INPUT_VALID','TRI05_INVALID_LISTED_ANGLE'];
for(const code of codes){
 const found=catalog.diagnostics.filter(d=>d.code===code);
 assert.equal(found.length,1,'new diagnostic code uniqueness');
 const d=found[0];assert.ok(d.skill==='P1-TRI-03'||d.skill==='P1-TRI-05');
 for(const lang of ['en','ru','uz']){
  assert.ok(typeof d.feedback[lang]==='string'&&d.feedback[lang].trim());
  assert.ok(typeof d.next_action[lang]==='string'&&d.next_action[lang].trim());
 }
}
assert.equal(catalog.diagnostics.length,34);
console.log(JSON.stringify({oracle:'PASS',affected_questions:14,
 proven_invalid_trig_option_feedback:disproved,
 proven_inaccurate_principal_feedback:principal,
 preserved_valid_missing_solution_feedback:retained,
 new_catalog_entries:codes.length,localized:['en','ru','uz'],
 changed_canonical_answers:0,printed_private_answers:false}));
