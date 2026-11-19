#!/usr/bin/env node
'use strict';
// Block08 Q176–Q200 independent Euclidean geometry algebra, trilingual source checks.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2/p3_coordinate_geometry');
const names=['P1-COO-03','P1-COO-04','P1-COO-05'];
const Q=new Map(names.flatMap(n=>JSON.parse(fs.readFileSync(path.join(root,n+'.json'),'utf8')).questions)
 .filter(q=>+q.key.slice(-3)>=176&&+q.key.slice(-3)<=200).map(q=>[+q.key.slice(-3),q]));
const norm=x=>String(x||'').normalize('NFC').replace(/[−–—]/g,'-').replace(/\s+/g,'');
const numeric=x=>/^[+-]?\d+(?:[.,]\d+)?$/.test(norm(x))?Number(norm(x).replace(',','.')):NaN;
const near=(x,y)=>Number.isFinite(x)&&Number.isFinite(y)&&Math.abs(x-y)<1e-8;
const point=s=>{const m=/^\((-?\d+),(-?\d+)\)$/.exec(norm(s));return m?[Number(m[1]),Number(m[2])]:null;};
const eq=(a,b)=>a&&b&&a.length===b.length&&a.every((v,i)=>near(v,b[i]));
const choice=(q,p)=>{assert.equal(q.qtype,'mcq');const correct=q.options.filter(o=>p(o.text.en));assert.equal(correct.length,1,'non-unique correct option');assert.equal(correct[0].key,q.correct_answer,'key drift');};
const input=(q,expected)=>{assert.equal(q.qtype,'input');assert.ok(near(numeric(q.answer_contract.canonical_answer),expected),'wrong input answer');assert.equal(q.answer_contract.number_only,true);
for(const e of q.answer_contract.accepted_examples||[])assert.ok(near(numeric(e),expected));
for(const e of q.answer_contract.rejected_examples||[])assert.ok(!near(numeric(e),expected));
};
const numbers=s=>(String(s||'').normalize('NFC').replace(/[−–—]/g,'-').match(/(?<!\p{L})[-+]?\d+(?:[.,]\d+)?/gu)||[]).map(x=>x.replace(',','.')).sort().join('|');
function lineCoefficients(t){
 // Cover y=mx+c with exact rational slope/intercept before integer general form.
 const literal=norm(t);
 const m=/^y=([+-]?)(\\d*)x(?:\\/(\\d+))?([+-]\\d+(?:\\/\\d+)?)?$/.exec(literal);
 if(m){
   const factor=(m[1]==='-'?-1:1)*Number(m[2]||1)/Number(m[3]||1);
   const pieces=(m[4]||'0').split('/');
   const intercept=Number(pieces[0])/Number(pieces[1]||1);
   return [factor,-1,intercept];
 }
 const s=literal.split('=');if(s.length!==2)return null;
 const calc=z=>{let c=[0,0,0];for(const term of z.replace(/-/g,'+-').split('+').filter(Boolean)){
 let m=/^(-?\d*)x$/.exec(term);if(m){c[0]+=Number(m[1]===''?1:m[1]==='-'?-1:m[1]);continue;}
 m=/^(-?\d*)y$/.exec(term);if(m){c[1]+=Number(m[1]===''?1:m[1]==='-'?-1:m[1]);continue;}
 if(/^[-]?\d+$/.test(term)){c[2]+=Number(term);continue;}return null;
 }return c;};const l=calc(s[0]),r=calc(s[1]);return l&&r?l.map((v,i)=>v-r[i]):null;
}
const lineAt=(s,x,y)=>{let a=lineCoefficients(s);return !!a&&near(a[0]*x+a[1]*y+a[2],0)};
const slope=(s)=>{const a=lineCoefficients(s);return a&&a[1]?(-a[0]/a[1]):NaN;};
const parseCenterRadius=s=>{
 let m=/^Centre\((-?\d+),(-?\d+)\),radius(\d+)$/.exec(norm(s));
 return m?{cx:Number(m[1]),cy:Number(m[2]),r:Number(m[3])}:null;
};
const correctCircle=(s,cx,cy,r2)=>{
 // Require exact normalized centre form and radius square.
 const source=norm(s),m=/^\(x([+-]\d+)\)²\+\(y([+-]\d+)\)²=(\d+)$/.exec(source);
 return !!m&&near(-Number(m[1]),cx)&&near(-Number(m[2]),cy)&&near(Number(m[3]),r2);
};
const tests={
176:q=>choice(q,s=>/^x=-?\d+$/.test(norm(s))),
177(q){const m=(0-2)/(5-1);input(q,2*(-1/m));},
178(q){assert.equal(q.difficulty,'medium');choice(q,s=>{const c=lineCoefficients(s);return !!c&&near(c[0]*(-2)+c[1]*5+c[2],0)&&near(-c[0]/c[1],3/2);});},
179:q=>choice(q,s=>near(slope(s),1/4)&&lineAt(s,3,-2)),
180:q=>choice(q,s=>{const c=parseCenterRadius(s);return !!c&&near(c.cx,-4)&&near(c.cy,3)&&near(c.r,Math.sqrt(49));}),
181:q=>input(q,5),
182:q=>choice(q,s=>{const c=parseCenterRadius(s);return !!c&&eq([c.cx,c.cy,c.r],[3,-4,Math.sqrt(36)]);}),
183:q=>input(q,(-2)**2+5**2-13),
184:q=>choice(q,s=>correctCircle(s,-2,5,3**2)),
185:q=>input(q,4**2+(-3)**2-4**2),
186:q=>choice(q,s=>norm(s)==='x²+y²-2x+6y-10=0'),
187:q=>input(q,12/2),
188(q){assert.equal(q.difficulty,'medium');choice(q,s=>near(numeric(s),Math.sqrt(25+4-20)));},
189(q){assert.equal(q.difficulty,'easy');input(q,3);},
190:q=>choice(q,s=>correctCircle(s,(-1+5)/2,(2+6)/2,((5+1)**2+(6-2)**2)/4)),
191:q=>input(q,(-2)**2+5),
192:q=>choice(q,s=>((5-2)**2+(3+1)**2===25)&&/On the circle/i.test(s)),
193:q=>input(q,Math.sqrt(10-1)),
194:q=>choice(q,s=>near(Number(norm(s).split('/')[0])/Number(norm(s).split('/')[1]),-3/4)),
195:q=>input(q,2*2+3*3),
196:q=>choice(q,s=>/midpoint of AB is \(2,5\).*perpendicular/i.test(s)),
197:q=>input(q,(3+1)**2+(4-2)**2-20),
198(q){const ys=[-2+Math.sqrt(10-1),-2-Math.sqrt(10-1)];choice(q,s=>{const a=norm(s).split('and').map(Number);return eq(a.sort((a,b)=>a-b),ys.slice().sort((a,b)=>a-b));});},
199:q=>choice(q,s=>lineAt(s,4,6)&&near(slope(s),-3/4)),
200:q=>input(q,2*Math.sqrt(25-3**2))
};
assert.equal(Q.size,25);
for(let id=176;id<=200;id++){
try{
const q=Q.get(id);assert.ok(q);assert.equal(q.key,'MATH-P1-PRACTICE2-Q'+String(id).padStart(3,'0'));
assert.equal(q.practice_no,3);assert.ok(q.source_ref.includes('Ch3'));
for(const lang of ['en','ru','uz']){assert.ok(q.question[lang]?.trim()&&q.explanation[lang]?.trim());assert.equal(numbers(q.question[lang]),numbers(q.question.en),'trilingual number mismatch');}
if(q.qtype==='mcq'){
 assert.deepEqual(q.options.map(o=>o.key),['A','B','C','D']);
 for(const l of ['en','ru','uz'])assert.equal(new Set(q.options.map(o=>norm(o.text[l]))).size,4);
 for(const o of q.options)if(o.key===q.correct_answer)assert.equal(o.diagnostic_code,null);else assert.ok(o.diagnostic_code);
}
tests[id](q);
}catch(e){console.error('FAIL block08 Q'+String(id).padStart(3,'0')+' '+e.message);process.exitCode=1;}
}
if(process.exitCode)process.exit(1);
console.log('PASS block08 Q176–Q200 exact circle/line geometry, MCQ uniqueness, scalar contract, three-language literals and 3 difficulty fixes');
