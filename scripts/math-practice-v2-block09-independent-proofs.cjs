#!/usr/bin/env node
'use strict';
// Independent block09 Mathematics P1 Practice Q201–Q225 geometry/circular measure.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2');
const files=['p3_coordinate_geometry/P1-COO-05','p3_coordinate_geometry/P1-COO-06','p4_circular_trigonometry/P1-CIR-01','p4_circular_trigonometry/P1-CIR-02'];
const Q=new Map(files.flatMap(p=>JSON.parse(fs.readFileSync(path.join(root,p+'.json'),'utf8')).questions).filter(q=>+q.key.slice(-3)>=201&&+q.key.slice(-3)<=225).map(q=>[+q.key.slice(-3),q]));
const norm=s=>String(s||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const value=s=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(s))?Number(norm(s).replace(',','.')):NaN;
const close=(a,b)=>Number.isFinite(a)&&Number.isFinite(b)&&Math.abs(a-b)<1e-9;
const input=(q,v)=>{assert.equal(q.qtype,'input');assert.ok(close(value(q.answer_contract.canonical_answer),v),'incorrect numeric result');assert.equal(q.answer_contract.number_only,true);for(const e of q.answer_contract.accepted_examples||[])assert.ok(close(value(e),v),'invalid accepted');for(const e of q.answer_contract.rejected_examples||[])assert.ok(!close(value(e),v),'invalid rejected');};
const mcq=(q,p)=>{assert.equal(q.qtype,'mcq');let rows=q.options.filter(o=>p(o.text.en));assert.equal(rows.length,1,'non-unique answer');assert.equal(rows[0].key,q.correct_answer,'answer-key mismatch');};
const tokenNums=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(v=>v.replace(',','.')).sort().join('|');
const fraction=s=>{const m=/^(-?\d+)(?:\/(\d+))?$/.exec(norm(s));return m?Number(m[1])/Number(m[2]||1):NaN;};
function line(s){
 const expr=norm(s).split('=');if(expr.length!==2)return null;
 const side=z=>{const v=[0,0,0];for(const t of z.replace(/-/g,'+-').split('+').filter(Boolean)){
  const m=/^(-?\d*)[xy]$/.exec(t);if(m){v[t.endsWith('x')?0:1]+=Number(m[1]===''?1:m[1]==='-'?-1:m[1]);continue;}
  if(/^[-]?\d+$/.test(t)){v[2]+=Number(t);continue;}return null;
 }return v;};
 const a=side(expr[0]),b=side(expr[1]);return a&&b?a.map((v,i)=>v-b[i]):null;
}
const lineHas=(s,x,y)=>{const c=line(s);return !!c&&close(c[0]*x+c[1]*y+c[2],0);};
const gradient=s=>{const c=line(s);return c&&c[1]!==0?-c[0]/c[1]:NaN;};
const pointString=s=>[...norm(s).matchAll(/\((-?\d+),(-?\d+)\)/g)].map(m=>[+m[1],+m[2]]);
const expectedPointSets=(a,b)=>a.length===b.length&&a.every((p,i)=>p.every((v,j)=>close(v,b[i][j])));
const radians=t=>{
 const s=norm(t).replace('radians','').replace('°','');
 if(s.includes('π')){const m=/^(\d*)π(?:\/(\d+))?$/.exec(s);return m?Number(m[1]||1)*Math.PI/Number(m[2]||1):NaN;}
 return Number(s)*Math.PI/180;
};
const f=x=>Math.abs(x);
const cases={
201:q=>mcq(q,s=>expectedPointSets(pointString(s),[[0,2],[8,2]])),
202:q=>mcq(q,s=>lineHas(s,3,4)&&close(gradient(s),-1)),
203:q=>input(q,1+Math.sqrt(25-(2+2)**2)),
204:q=>mcq(q,s=>lineHas(s,5,2)&&close(gradient(s),-3)),
205(q){const D=(-12)**2-4*3*12;assert.equal(D,0);mcq(q,s=>/line is tangent to the circle/i.test(s));},
206:q=>input(q,-2+3),
207:q=>input(q,-(2)/(2)),
208:q=>input(q,(2)+(-8)),
209:q=>mcq(q,s=>norm(s)==='|k|<4'),
210:q=>mcq(q,s=>norm(s)==='k=0or8'),
211:q=>mcq(q,s=>norm(s)==='p<9'),
212:q=>input(q,8/2),
213:q=>mcq(q,s=>norm(s)==='m=±4/3'),
214:q=>input(q,25*5),
215(q){assert.equal(q.difficulty,'medium');input(q,(2+4)*(2-4));},
216:q=>mcq(q,s=>close(fraction(s),5/12)),
217:q=>input(q,Math.PI/5*180/Math.PI),
218:q=>mcq(q,s=>close(radians(s),225*Math.PI/180)),
219:q=>input(q,7*Math.PI/6*180/Math.PI),
220:q=>mcq(q,s=>close(fraction(s),72/180)),
221:q=>mcq(q,s=>close(radians(s),3*Math.PI/4)),
222:q=>input(q,5*Math.PI/2*180/Math.PI),
223:q=>input(q,150*6/180),
224(q){assert.equal(q.difficulty,'medium');input(q,2*(3*Math.PI/8)*180/Math.PI);},
225:q=>input(q,8*.75)
};
assert.equal(Q.size,25);
for(let id=201;id<=225;id++){
try{
const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
assert.equal(q.practice_no,id<=216?3:4);
assert.ok(q.source_ref.includes(id<=216?'Ch3':'Ch4'));
for(const l of ['en','ru','uz']){assert.ok(q.question[l]?.trim()&&q.explanation[l]?.trim());assert.equal(tokenNums(q.question[l]),tokenNums(q.question.en),'locale numeric drift');}
if(q.qtype==='mcq'){assert.deepEqual(q.options.map(o=>o.key),['A','B','C','D']);for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);}
cases[id](q);
}catch(e){console.error('FAIL block09 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block09 Q201–Q225 tangent/discriminant/circular conversions, unique choices, input contracts and two difficulty corrections');
