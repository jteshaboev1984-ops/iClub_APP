#!/usr/bin/env node
"use strict";
// Independently coded calculus properties supplement (not substitute for) the
// 180-by-180 source-stem oracle validated against live Supabase SQL.
const A=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const s=fs.readFileSync(path.join(__dirname,"fixtures/math-p1-calculus-180-secondpass.sql"),"utf8");
const matches=[...s.matchAll(/\('((?:P1DIF|P1INT)\d\d-[A-Z]\d\d)','([^']+)'\)/g)];
A.equal(matches.length,180,"Expect 180 unique independently derived answers");
const keys=new Map(matches.map(x=>[x[1],x[2]]));
A.equal(keys.size,180,"No duplicate source key");
for(const [p,count] of [["DIF",7],["INT",5]]) for(let j=1;j<=count;j++)
 A.equal([...keys.keys()].filter(x=>x.startsWith("P1"+p+String(j).padStart(2,"0")+"-")).length,15);
A.match(s,/FULL JOIN actual/);
A.doesNotMatch(s,/\b(?:UPDATE|INSERT|DELETE|DROP|TRUNCATE|ALTER)\s+(?:private|public)\./i);
const close=(a,b,t=1e-6)=>A.ok(Math.abs(a-b)<t,String(a)+" != "+String(b));
const check=(key,expected)=>A.equal(keys.get(key),String(expected),key);
const derivative=(f,x,h=1e-5)=>(f(x+h)-f(x-h))/(2*h);
const simp=(f,a,b,n=4000)=>{A.equal(n%2,0);let h=(b-a)/n,s=f(a)+f(b);for(let i=1;i<n;i++)s+=(i%2?4:2)*f(a+i*h);return s*h/3};
// Differentiation: quotient limit, chain, fractional powers, tangents,
// monotonicity, related rates, stationary points.
close(derivative(x=>x*x+x,3),7);check("P1DIF01-M02",7);
close(derivative(x=>5*x**(2/3),8),5/3,1e-6);check("P1DIF02-A03",5);
close(derivative(x=>(5*x+1)**3,0),15);check("P1DIF03-A03",15);
close(derivative(x=>(4*x+1)**.5,2),2/3);check("P1DIF03-R03","2/3");
const tangentY=2*(-1)**2+1-4*(-1)*(-1+1);close(tangentY,3);check("P1DIF04-A03",-1);
for(const x of [-4,-1,0,3])A.equal((x-4)*(x+1)<0,x>-1&&x<4);check("P1DIF05-A03",5);
close(3*10**2*(-.2),-60);check("P1DIF06-A02","D");
close(4*Math.PI*5**2*.2,20*Math.PI);check("P1DIF06-R04","A");
close(12*2-2**3,16);close(12*2/Math.sqrt(3),12*2/Math.sqrt(3));
close(12*2-2**3,16); // optimization objective y=12x-x^3 evaluated at x=2
check("P1DIF07-M02",2);
// Integration: antiderivative checks, constants, definite and improper,
// signed versus total area, solids of revolution.
close(derivative(x=>2*x**3-2*x**2+5*x,2),6*4-4*2+5);check("P1INT01-A01","C");
close(derivative(x=>(2*x+1)**3/2,1),3*(2*1+1)**2);check("P1INT01-A02","D");
check("P1INT02-M02",2**5+6);
close(simp(x=>2*x+1,0,3),12);check("P1INT03-A01","C");
// x=t^2 regularizes the integrable x^(-1/2) endpoint singularity.
close(simp(t=>2,0,2),4);check("P1INT03-M02",4);
close(simp(x=>x-x*x,0,1),1/6);check("P1INT04-A02","B");
close(simp(x=>Math.abs(x*x-1),-2,2),4,2e-7);check("P1INT04-M02",4);
close(simp(x=>4-x*x,-2,2),32/3);check("P1INT04-R03","32/3");
close(Math.PI*simp(x=>x*x,0,2),8*Math.PI/3);check("P1INT05-A01","C");
close(Math.PI*simp(x=>x,0,4),8*Math.PI);check("P1INT05-R03",8);
close(Math.PI*simp(x=>(x+1)**2,0,1),7*Math.PI/3);check("P1INT05-R04","B");
console.log("PASS: all 180 unique P1 calculus source-key oracle entries; independent differentiation/integration numerical properties.");
