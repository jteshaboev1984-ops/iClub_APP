#!/usr/bin/env node
'use strict';
// Block12 Q276–Q300: trig identities/periodic roots and positive integer binomial.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2');
const paths=['p4_circular_trigonometry/P1-TRI-04','p4_circular_trigonometry/P1-TRI-05','p5_binomial_series/P1-SER-01'];
const Q=new Map(paths.flatMap(p=>JSON.parse(fs.readFileSync(path.join(root,p+'.json'),'utf8')).questions).filter(q=>+q.key.slice(-3)>=276&&+q.key.slice(-3)<=300).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-8;
const decimal=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(decimal(q.answer_contract.canonical_answer),v),'bad input answer');
assert.equal(q.answer_contract.number_only,true);for(const e of q.answer_contract.accepted_examples||[])assert.ok(near(decimal(e),v));for(const e of q.answer_contract.rejected_examples||[])assert.ok(!near(decimal(e),v));};
const mcq=(q,p)=>{assert.equal(q.qtype,'mcq');const a=q.options.filter(o=>p(o.text.en));assert.equal(a.length,1,'wrong/duplicated MCQ');assert.equal(a[0].key,q.correct_answer,'wrong key');};
const tokens=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(v=>v.replace(',','.')).sort().join('|');
const rad=deg=>deg*Math.PI/180,sin=x=>Math.sin(rad(x)),cos=x=>Math.cos(rad(x)),tan=x=>Math.tan(rad(x));
const comb=(n,k)=>{let v=1;for(let i=1;i<=k;i++)v=v*(n-i+1)/i;return Math.round(v);};
const medium=new Set([278,279,280,281,290,292,293]);
const tests={
276:q=>mcq(q,s=>norm(s)==='(1+sinx)/sinx=1'&&Math.abs((1+sin(37))/sin(37)-1)>1e-8),
277:q=>input(q,(3/5)/(4/5)),
278:q=>mcq(q,s=>norm(s)==='sinxcosx'&&[17,51,79].every(a=>near(tan(a)*cos(a)**2,sin(a)*cos(a)))),
279:q=>mcq(q,s=>norm(s)==='1-cosx'&&[17,51,79].every(a=>near(sin(a)**2/(1+cos(a)),1-cos(a)))),
280:q=>mcq(q,s=>norm(s)==='cosx'&&[17,51,79].every(a=>near(sin(a)/tan(a),cos(a)))),
281:q=>mcq(q,s=>norm(s)==='0°and360°'),
282:q=>mcq(q,s=>norm(s)==='x=60°,120°'&&near(sin(60),Math.sqrt(3)/2)&&near(sin(120),Math.sqrt(3)/2)),
283:q=>mcq(q,s=>norm(s)==='x=150°,210°'&&near(cos(150),-Math.sqrt(3)/2)&&near(cos(210),-Math.sqrt(3)/2)),
284:q=>mcq(q,s=>norm(s)==='x=45°,225°'&&near(tan(45-15),1/Math.sqrt(3))&&near(tan(225-15),1/Math.sqrt(3))),
285:q=>input(q,[0,90,180,270].filter(x=>near(sin(2*x),0)).length),
286:q=>mcq(q,s=>norm(s)==='x=60°,240°'&&near(cos(60+30),0)&&near(cos(240+30),0)),
287:q=>mcq(q,s=>norm(s)==='x=0°,360°'&&near(cos(360),1)),
288:q=>mcq(q,s=>norm(s)==='x=-135°,-45°'&&near(sin(-135),-Math.SQRT2/2)),
289:q=>mcq(q,s=>norm(s)==='x=60°,180°,300°'&&[60,180,300].every(x=>near(2*cos(x)**2+cos(x)-1,0))),
290:q=>mcq(q,s=>norm(s)==='x=45°,225°'&&[45,225].every(x=>near(sin(x),cos(x)))),
291:q=>input(q,[0,60,180,300].filter(x=>near(sin(x)*(2*cos(x)-1),0)).length),
292:q=>mcq(q,s=>norm(s)==='x=90°,270°'&&near(cos(180),-1)&&near(cos(540),-1)),
293:q=>mcq(q,s=>norm(s)==='x=7π/6,11π/6'&&near(Math.sin(7*Math.PI/6),-.5)&&near(Math.sin(11*Math.PI/6),-.5)),
294:q=>input(q,(comb(5,2)*2**2)/(comb(5,1)*2)),
295:q=>mcq(q,s=>norm(s)==='54x²'&&comb(4,2)*3**2===54),
296:q=>input(q,comb(5,3)*2**2*(-1)**3),
297:q=>mcq(q,s=>norm(s)==='-540x³'&&comb(6,3)*(-3)**3===-540),
298:q=>input(q,comb(6,4)*2**2*3**4),
299:q=>input(q,8*comb(5,1)/comb(5,2)),
300:q=>mcq(q,s=>near(decimal(s),comb(5,3)+2*comb(5,2)))
};
assert.equal(Q.size,25);
for(let id=276;id<=300;id++){
 try{const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
 assert.equal(q.practice_no,id<=293?4:5);
 assert.ok(q.source_ref.includes(id<=293?'Ch5':'Ch6'));
 if(medium.has(id))assert.equal(q.difficulty,'medium');
 for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(tokens(q.question[l]),tokens(q.question.en),'trilingual literals differ');}
 if(q.qtype==='mcq'){assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D']);for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
 tests[id](q);
 }catch(e){console.error('FAIL block12 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block12 Q276–Q300 trig identities, interval roots and binomial coefficient independent calculations; seven calibrated items');
