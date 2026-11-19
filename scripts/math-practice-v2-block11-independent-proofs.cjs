#!/usr/bin/env node
'use strict';
// Block11 Q251–Q275: independent trigonometry values, branches and identities.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const dir=path.resolve(__dirname,'../content/math/practice_v2/p4_circular_trigonometry');
const files=['P1-TRI-01','P1-TRI-02','P1-TRI-03','P1-TRI-04'];
const Q=new Map(files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(dir,f+'.json'),'utf8')).questions).filter(q=>+q.key.slice(-3)>=251&&+q.key.slice(-3)<=275).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const numeric=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const near=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-8;
const trig=(fn,deg)=>Math[fn](deg*Math.PI/180);
const choice=(q,p)=>{assert.equal(q.qtype,'mcq');let good=q.options.filter(o=>p(o.text.en));assert.equal(good.length,1,'non-unique or absent right option');assert.equal(good[0].key,q.correct_answer);};
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(near(numeric(q.answer_contract.canonical_answer),v),'numeric mismatch');assert.equal(q.answer_contract.number_only,true);
for(const a of q.answer_contract.accepted_examples||[])assert.ok(near(numeric(a),v),'invalid accepted');for(const a of q.answer_contract.rejected_examples||[])assert.ok(!near(numeric(a),v),'incorrect rejected');};
const tokens=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(x=>x.replace(',','.')).sort().join('|');
function numberExpr(s){const t=norm(s).replace('°','');if(/^-?\d+(?:\.\d+)?$/.test(t))return +t;
 let m=/^(-?)√(\d+)(?:\/(\d+))?$/.exec(t);if(m)return (m[1]? -1:1)*Math.sqrt(+m[2])/(+(m[3]||1));
 m=/^(-?\d+)\/(\d+)$/.exec(t);if(m)return +m[1]/+m[2];
 return NaN;
}
const md=new Set([252,253,261,262,263]);
const cases={
 251:q=>choice(q,t=>/Period 120°, range −1≤y≤3/.test(t)&&360/3===120),
 252:q=>choice(q,t=>norm(t)==='x=120°'&&near(90+30,120)),
 253:q=>input(q,(10-(-2))/2),
 254(q){const v=[trig('sin',210)-trig('cos',60),trig('sin',210)+trig('cos',60),trig('sin',210)+1,2*trig('sin',210)-1];
  assert.equal(v.filter(z=>near(z,0)).length,1);const answer=q.options.findIndex(o=>o.key===q.correct_answer);assert.ok(near(v[answer],0));},
 255:q=>choice(q,t=>norm(t)==='cos330°=sin60°'&&near(trig('cos',330),trig('sin',60))),
 256:q=>input(q,Math.round(trig('tan',135))),
 257:q=>choice(q,t=>near(numberExpr(t),trig('sin',210))),
 258:q=>choice(q,t=>near(numberExpr(t),trig('cos',225))),
 259:q=>choice(q,t=>near(numberExpr(t),2*trig('sin',30)+trig('cos',60))),
 260:q=>choice(q,t=>norm(t)==='a'&&near(trig('cos',320),trig('cos',40))),
 261:q=>input(q,-2),
 262:q=>choice(q,t=>norm(t)==='sin30°-cos60°'&&near(trig('sin',30)-trig('cos',60),0)),
 263:q=>choice(q,t=>norm(t)==='b'&&near(Math.sin(6*Math.PI/7),Math.sin(Math.PI/7))),
 264:q=>input(q,Math.asin(-.5)*180/Math.PI),
 265:q=>choice(q,t=>near(Number(norm(t).replace('°','')),Math.acos(-Math.SQRT2/2)*180/Math.PI)),
 266:q=>choice(q,t=>near(Number(norm(t).replace('°','')),Math.atan(-Math.sqrt(3))*180/Math.PI)),
 267:q=>choice(q,t=>norm(t)==='0°≤θ≤180°'),
 268:q=>input(q,Math.round(Math.asin(.6)*180/Math.PI*10)/10),
 269:q=>choice(q,t=>/calculator is in radian mode/i.test(t)),
 270:q=>input(q,trig('sin',30)),
 271:q=>choice(q,t=>near(Number(norm(t).replace('°','')),Math.asin(trig('sin',150))*180/Math.PI)),
 272:q=>choice(q,t=>norm(t)==='sinx'&&[-1,0.3,1.4].every(x=>near((1-Math.cos(x)**2)/Math.sin(x),Math.sin(x)))),
 273:q=>choice(q,t=>norm(t)==='sinx'&&[-1,0.3,1.4].every(x=>near(Math.tan(x)*Math.cos(x),Math.sin(x)))),
 274:q=>choice(q,t=>norm(t)==='1/cos²x'&&[-1,0.3,1.4].every(x=>near((Math.sin(x)**2+Math.cos(x)**2)/Math.cos(x)**2,1/Math.cos(x)**2))),
 275:q=>choice(q,t=>norm(t)==='1'&&[-1,0.3,1.4].every(x=>near(((1-Math.cos(x))*(1+Math.cos(x)))/Math.sin(x)**2,1)))
};
cases[254]=(q)=>{
 const values=[trig('sin',210)-trig('cos',60),trig('sin',210)+trig('cos',60),trig('sin',210)+1,2*trig('sin',210)-1];
 assert.equal(values.filter(x=>near(x,0)).length,1);
 const sorted=q.options.slice().sort((a,b)=>a.key.localeCompare(b.key));const zero=sorted.filter((o,i)=>near(values[i],0));assert.equal(zero.length,1);assert.equal(zero[0].key,q.correct_answer);
};
assert.equal(Q.size,25);
for(let id=251;id<=275;id++){
try{
 const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
 assert.equal(q.practice_no,4);assert.ok(q.source_ref.includes('Ch5'));
 if(md.has(id))assert.equal(q.difficulty,'medium');
 for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(tokens(q.question[l]),tokens(q.question.en),'numeric locale drift');}
 if(q.qtype==='mcq'){assert.deepEqual(q.options.map(o=>o.key).sort(),['A','B','C','D']);for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
 cases[id](q);
}catch(e){console.error('FAIL block11 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block11 Q251–Q275 numerical trig, principal branch, identity nonzero tests, 5 difficulty fixes');
