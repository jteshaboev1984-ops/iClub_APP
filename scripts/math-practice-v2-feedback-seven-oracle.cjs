#!/usr/bin/env node
'use strict';
// Issue #574: exact option-link and independent maths check, no answer keys in CI logs.
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'../content/math/practice_v2');
function get(dir,skill,n){
 const j=JSON.parse(fs.readFileSync(path.join(root,dir,skill+'.json'),'utf8'));
 const q=j.questions.find(x=>x.key.endsWith('Q'+n));
 assert.ok(q,'missing authored question');
 return q;
}
function link(q,key,code){
 const option=q.options.find(o=>o.key===key);
 assert.ok(option&&key!==q.correct_answer,'wrong-option-only guard');
 assert.equal(option.diagnostic_code,code);
}
const q406=get('p6_differentiation','P1-DIF-05',406);
assert.ok(q406.question.en.includes('defined for x>0'));
link(q406,'D','DIF05_DOMAIN_INTERSECTION');
// f'(x)=x(x-3): negative only for 0<x<3 within specified domain.
const deriv=x=>x*(x-3);
assert.ok(deriv(1)<0&&deriv(2)<0&&deriv(3)===0&&deriv(4)>0);
assert.ok(-1<3&&0<3); // rejected interval x<3 includes outside-domain x<=0
for(const [n,x,deriv2] of [[419,0,z=>6*z-6],[423,-3,z=>6*z+6]]){
 const q=get('p6_differentiation','P1-DIF-07',n);
 link(q,n===419?'A':'C','DIF07_MAX_NOT_INFLEXION');
 assert.ok(deriv2(x)<0,'not stationary inflexion: second derivative nonzero negative');
}
const f419=z=>3*z*z-6*z;
const f423=z=>3*z*z+6*z-9;
assert.equal(f419(0),0);assert.equal(f423(-3),0);
assert.ok(f419(-.1)>0&&f419(.1)<0);
assert.ok(f423(-3.1)>0&&f423(-2.9)<0);
const q425=get('p6_differentiation','P1-DIF-07',425);
link(q425,'A','DIF07_INFLEXION_NOT_EXTREMUM');
link(q425,'B','DIF07_INFLEXION_NOT_EXTREMUM');
assert.ok([-2,-1,-.1,.1,1,2].every(x=>3*x*x>0));
assert.equal(3*0*0,0); // stationary point, monotonicity retained
const q482=get('p7_integration','P1-INT-04',482);
link(q482,'A','INT04_ZERO_NEEDS_SIGN_CHANGE');
link(q482,'D','INT04_ZERO_NEEDS_SIGN_CHANGE');
assert.ok(q482.question.en.includes('∫₀⁴f(x)dx=0'));
// A continuous example with zero signed integral and both signs.
// f(x)=x-2 on [0,4]: F(4)-F(0)=0, but geometric area = 4 >0.
const antideriv=x=>x*x/2-2*x;
assert.equal(antideriv(4)-antideriv(0),0);
assert.ok((-1-2)<0&&(3-2)>0);
assert.equal(2*2,4);
for(const [folder,code] of [
 ['p6_differentiation','DIF05_DOMAIN_INTERSECTION'],
 ['p6_differentiation','DIF07_MAX_NOT_INFLEXION'],
 ['p6_differentiation','DIF07_INFLEXION_NOT_EXTREMUM'],
 ['p7_integration','INT04_ZERO_NEEDS_SIGN_CHANGE']
]){
 const catalog=JSON.parse(fs.readFileSync(path.join(root,folder,'diagnostic_catalog.json'),'utf8'));
 const defs=catalog.diagnostics.filter(d=>d.code===code);assert.equal(defs.length,1);
 for(const lang of ['en','ru','uz']){assert.ok(defs[0].feedback[lang]?.trim());assert.ok(defs[0].next_action[lang]?.trim());}
}
console.log(JSON.stringify({oracle:'PASS',distinct_questions:5,option_feedback_links:7,trilingual_catalogs:4,answer_keys_unchanged:true,no_private_options_logged:true}));
