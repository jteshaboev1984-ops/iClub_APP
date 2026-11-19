#!/usr/bin/env node
'use strict';
// Block10 Q226–Q250: independent circle sector, radian and elementary trig proof gate.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const dir=path.resolve(__dirname,'../content/math/practice_v2/p4_circular_trigonometry');
const files=['P1-CIR-02','P1-CIR-03','P1-TRI-01'];
const Q=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(dir,f+'.json'),'utf8')).questions)
.filter(q=>+q.key.slice(-3)>=226&&+q.key.slice(-3)<=250).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const scalar=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const input=(q,value)=>{assert.equal(q.qtype,'input');assert.ok(near(scalar(q.answer_contract.canonical_answer),value),'answer mismatch');
assert.equal(q.answer_contract.number_only,true);
for(const v of q.answer_contract.accepted_examples||[])assert.ok(near(scalar(v),value),'invalid accepted example');
for(const v of q.answer_contract.rejected_examples||[])assert.ok(!near(scalar(v),value),'invalid rejected example');
};
const mcq=(q,p)=>{assert.equal(q.qtype,'mcq');let yes=q.options.filter(o=>p(o.text.en));assert.equal(yes.length,1,'wrong/duplicate MCQ');assert.equal(yes[0].key,q.correct_answer,'key mismatch');};
const tokens=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(x=>x.replace(',','.')).sort().join('|');
const frac=s=>{const m=/^(-?\d+)(?:\/(\d+))?$/.exec(norm(s));return m?Number(m[1])/Number(m[2]||1):NaN;};
const area=(r,theta)=>.5*r*r*theta,arc=(r,theta)=>r*theta;
const calibrated=new Map([[232,'easy'],[233,'medium'],[240,'medium'],[242,'medium']]);
const tests={
226:q=>input(q,arc(10,1.5)/10),
227:q=>input(q,14/2),
228:q=>mcq(q,t=>norm(t)==='4πcm'&&near(arc(12,60*Math.PI/180),4*Math.PI)),
229:q=>input(q,5*Math.PI/10*180/Math.PI),
230:q=>input(q,(26-2*8)/8),
231:q=>mcq(q,t=>/Arc B is 8\/5 times the length of Arc A/i.test(t)),
232:q=>mcq(q,t=>near(frac(t),15/6)),
233:q=>input(q,4*3/6),
234:q=>input(q,area(4,1.5)),
235:q=>input(q,18/(.5*6**2)),
236:q=>mcq(q,t=>near(Number(norm(t).replace('cm','')),Math.sqrt(24*2/(3/4)))),
237:q=>mcq(q,t=>norm(t)==='12πcm²'&&near(area(6,120*Math.PI/180),12*Math.PI)),
238:q=>mcq(q,t=>norm(t)==='6π-9√3cm²'&&area(6,Math.PI/3)-.5*36*Math.sin(Math.PI/3)>0),
239(q){
 assert.equal(q.difficulty,'hard');
 assert.ok(q.question.en.includes('annular sector')&&q.question.ru.includes('Кольцевой сектор')&&q.question.uz.includes('Halqasimon sektor'));
 const angle=2,sectorArea=5,radialWidth=1;
 const radiusSum=2*sectorArea/(angle*radialWidth);
 const R=(radiusSum+radialWidth)/2,r=(radiusSum-radialWidth)/2;
 assert.ok(R>r&&r>0);
 assert.ok(near(.5*(R*R-r*r)*angle,sectorArea),'annular-sector area constraint');
 const perimeter=angle*(R+r)+2*(R-r);
 input(q,perimeter);
},
240:q=>mcq(q,t=>near(Number(norm(t).replace('cm²','')),area(6,2)-area(3,2))),
241:q=>mcq(q,t=>norm(t)==='4π-8cm²'&&area(4,Math.PI/2)-8>0),
242:q=>mcq(q,t=>near(scalar(t),area(10,1)/arc(10,1))),
243:q=>input(q,36/(area(8,1)-area(4,1))),
244:q=>input(q,360/120),
245:q=>mcq(q,t=>norm(t)==='-5≤y≤-1'),
246:q=>input(q,90/2),
247:q=>mcq(q,t=>norm(t)==='(130°,3)'&&near(90+40,130)),
248:q=>mcq(q,t=>norm(t)==='y=cos4x'&&near(360/4,90)),
249:q=>input(q,(-1+5)/2),
250:q=>input(q,180/60)
};
assert.equal(Q.size,25);
for(let id=226;id<=250;id++){
try{const q=Q.get(id);assert.ok(q);
assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
assert.equal(q.practice_no,4);
assert.ok(q.source_ref.includes(id<=243?'Ch4':'Ch5'));
if(calibrated.has(id))assert.equal(q.difficulty,calibrated.get(id));
for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(tokens(q.question[l]),tokens(q.question.en),'numeric locale mismatch');}
if(q.qtype==='mcq'){assert.deepEqual(q.options.map(o=>o.key),['A','B','C','D']);
for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);
for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);
}
tests[id](q);
}catch(e){console.error('FAIL block10 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block10 Q226–Q250 independent sector/trig arithmetic, 4 difficulty corrections, single-key MCQs and three-language consistency');
