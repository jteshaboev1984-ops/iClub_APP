#!/usr/bin/env node
"use strict";
// Source-stem-specific independent maths assertions for 31 P5 mixed written tasks.
// No network, databases, passwords, or mutations.
const assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const p=path.join(__dirname,"fixtures/math-p5-mixed-written-31-current-oracle.sql");
const sql=fs.readFileSync(p,"utf8");
const entries=[...sql.matchAll(/\('((?:P5FP|P5TB|P5MM)\d\d-Q\d\d)','([^']+)'\)/g)];
assert.equal(entries.length,31);
const oracle=new Map(entries.map(x=>[x[1],x[2]]));
assert.equal(oracle.size,31);
for (const [prefix,n] of [["P5FP01",7],["P5FP02",7],["P5FP03",7],["P5TB01",3],["P5TB02",3],["P5MM01",4]]) {
 assert.equal([...oracle.keys()].filter(k=>k.startsWith(prefix+"-")).length,n);
}
for(const f of ["math-written-current-version-and-locales-readonly.sql","math-p5-mixed-written-31-current-oracle.sql"]){
 const s=fs.readFileSync(path.join(__dirname,"fixtures",f),"utf8");
 assert.match(s,/approved_at DESC NULLS LAST,created_at DESC NULLS LAST,id DESC/);
 assert.doesNotMatch(s,/\b(?:UPDATE|DELETE\s+FROM|INSERT\s+INTO|DROP|TRUNCATE|ALTER)\s+(?:private|public)\./i);
}
const C=(n,k)=>{let s=1;for(let j=1;j<=k;j++)s=s*(n-j+1)/j;return s};
const F=n=>{let s=1;for(let k=2;k<=n;k++)s*=k;return s};
const close=(a,b,t=0.0003)=>assert.ok(Math.abs(a-b)<=t,String(a)+" != "+String(b));
const check=(k,v)=>assert.equal(oracle.get(k),v,k);
// Numerical normal CDF approximation (Abramowitz-Stegun 7.1.26).
const Phi=x=>{
 const y=Math.abs(x)/Math.sqrt(2),t=1/(1+0.3275911*y);
 const erf=1-(((((1.061405429*t-1.453152027)*t)+1.421413741)*t-0.284496736)*t+0.254829592)*t*Math.exp(-y*y);
 return (1+(x<0?-erf:erf))/2;
};
// FP01 — data, selection/counting, conditional, discrete, binomial, geometric, normal.
close((35400+58500)/50-43.2**2,11.76);check("P5FP01-Q01","11.76");
close(C(5,2)*C(7,2)+C(5,3)*7+C(5,4),285);
close(C(5,2)*C(7,2)*F(3)*F(2),2520);check("P5FP01-Q02","2520");
close(C(5,2)/(C(12,2)-C(7,2)),2/9);check("P5FP01-Q03","2/9");
close((2*0.1+2*3*0.1+3*4*0.1),2);
close(5-2**2,1);check("P5FP01-Q04","Var(X)=5-2^2=1");
close(C(12,4)*.3**4*.7**8,.231,.0005);
close(1-.7**12-12*.3*.7**11,.915,.0005);check("P5FP01-Q05","0.915");
close(.8**4,.4096);check("P5FP01-Q06","0.4096");
close(Phi(2.1)-Phi(-1.1),.8465,.0001);check("P5FP01-Q07","0.8465");
// FP02 — coding, multiset arrangements, hypergeometric, discrete, distributions, geometric, inverse normal.
close((115400+10*3600)/50-(54.4)**2,68.64);check("P5FP02-Q01","68.64");
close(F(7)/(F(2)*F(2))-F(6)/F(2),900);check("P5FP02-Q02","900");
close(1-(C(4,2)+C(3,2)+C(2,2))/C(9,2),13/18);check("P5FP02-Q03","13/18");
close(.24+4*.36+9*.28-1.8**2,.96);check("P5FP02-Q04","0.96");
close(50*.8,40);check("P5FP02-Q05","E(Y)=40");
close(.75**2-.75**6,.3845,.0001);check("P5FP02-Q06","0.3845");
const sig=10/1.2816;close(Phi(5/sig)-Phi(-5/sig),.4783,.0003);check("P5FP02-Q07","0.4783");
// FP03 — grouped statistics, digit codes, conditional, binomial, waiting time, normal and continuity.
const mid=[5,15,30,50],freq=[6,14,20,10];
close(mid.reduce((s,v,i)=>s+v*v*freq[i],0),46300);
close(46300/50-(1340/50)**2,207.76);check("P5FP03-Q01","207.76");
close(7*6*5*4+3*6*6*5*4,3000);check("P5FP03-Q02","3000");
close(C(5,2)/(C(12,2)-C(7,2)),2/9);check("P5FP03-Q03","2/9");
const p3=C(8,3)*.3**3*.7**5,pAtLeast2=1-.7**8-8*.3*.7**7;
close(p3/pAtLeast2,.3412,.0001);check("P5FP03-Q04","0.3412");
close(.8**2-.8**6,.377856,1e-9);check("P5FP03-Q05","0.377856");
close(Math.round((70+8*1.2816)*10)/10,80.3,1e-9);check("P5FP03-Q06","80.3");
close(Phi(10.5/Math.sqrt(48))-Phi(-10.5/Math.sqrt(48)),.870,.001);check("P5FP03-Q07","0.870");
// Timed blocks and mini mock.
close(Math.sqrt(66/10-(24/10)**2),.917,.001);check("P5TB01-Q01","0.917");
close((C(8,6)+C(8,7)+C(8,8))/2**8,37/256,1e-9);check("P5TB01-Q02","37/256");
close(Phi(2)-Phi(-1),.8186,.0001);check("P5TB01-Q03","0.8186");
close((C(9,3)-C(5,3))*F(3),444);check("P5TB02-Q01","444");
close(4/6,2/3,1e-9);check("P5TB02-Q02","2/3");
close(5-2**2,1);check("P5TB02-Q03","Var(X)=5-2^2=1");
close((40+20*10+30*18)/50,15.6);check("P5MM01-Q01","15.6");
close(.6+.5-2*.3,.5);check("P5MM01-Q02","0.5");
close((3/4)**4/4,81/1024,1e-9);check("P5MM01-Q03","81/1024");
close(Phi((38.5-32)/Math.sqrt(19.2))-Phi((27.5-32)/Math.sqrt(19.2)),.7788,.0002);
check("P5MM01-Q04","0.7788");
console.log("PASS: 31 P5 current-task independent mathematical checks + version-aware read-only SQL guards");
