#!/usr/bin/env node
"use strict";
const A=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const load=n=>fs.readFileSync(path.join(__dirname,n),"utf8");
const sql={TRI:load("fixtures/math-p1-second-pass-tri-75.sql"),SER:load("fixtures/math-p1-second-pass-ser-75.sql")};
const maps={};
for(const family of ["TRI","SER"]){
 const tuples=[...sql[family].matchAll(/\('(P1(?:TRI|SER)\d\d-[A-Z]\d\d(?:-QA20261101)?)','([^']*)'\)/g)];
 A.equal(tuples.length,75,"Complete "+family+" academic coverage");
 maps[family]=new Map(tuples.map(m=>[m[1],m[2]]));
 A.equal(maps[family].size,75,"No duplicate "+family+" question keys");
 A.match(sql[family],/FULL JOIN actual/);
 A.doesNotMatch(sql[family],/\b(?:INSERT|UPDATE|DELETE|DROP|ALTER|TRUNCATE)\s+(?:private|public)\./i);
}
const source=load("ops/20261101_math_p1_tri02_sin210_versioned_repair.sql");
const post=load("fixtures/math-p1-tri02-sin210-postrelease-readonly.sql");
for(const x of ["P1TRI02_SIN210_PRECONDITION_OR_LEARNER_USAGE_DRIFT","P1TRI02_NEW_ASSESSMENT_INVALID","P1TRI02_POSTPUBLISH_FAILED","OWNER_REQUESTED_AI_ASSISTED_MATH_REPAIR_2026_11_01_NO_INDEPENDENT_HUMAN"])A.ok(source.includes(x));
A.ok(post.includes("SIN210_CORRECTED_LIVE_PASS"));
for(const s of [source,post]){
 A.doesNotMatch(s,/\b(?:DELETE\s+FROM|TRUNCATE|DROP\s+TABLE|ALTER\s+TABLE)\b/i);
 A.doesNotMatch(s,/UPDATE\s+(?:private\.exam_prep_(?:responses|sessions|session_items|skill_states|weekly_plans)|public\.questions)/i);
}
const near=(a,b,tol=1e-8)=>A.ok(Math.abs(a-b)<=tol,String(a)+" != "+String(b));
const key=(fam,topic,suffix)=>{const k="P1"+fam+topic+"-"+suffix;A.ok(maps[fam].has(k),"Missing independent key "+k);return maps[fam].get(k);};
const num=(s)=>{s=s.replace(/−/g,"-");let r=s.match(/^(-?)√(\d+)\/(\d+)$/);if(r)return(r[1]?-1:1)*Math.sqrt(+r[2])/(+r[3]);if(s.includes("/")){let [a,b]=s.split("/").map(Number);return a/b}return Number(s)};
const matched=(fam,topic,suffix,number)=>near(num(key(fam,topic,suffix)),number);
const F=n=>{let a=1;for(let i=2;i<=n;i++)a*=i;return a};
const C=(n,k)=>F(n)/(F(k)*F(n-k));
const mul=(a,b)=>{let c=Array(a.length+b.length-1).fill(0);a.forEach((v,i)=>b.forEach((w,j)=>c[i+j]+=v*w));return c};
const pow=(a,n)=>{let r=[1];for(let i=0;i<n;i++)r=mul(r,a);return r};
const poly={
 A01:pow([3,1],5)[4],A02:mul(pow([1,-2],3),[1,1])[2],A03:pow([3,2],4)[1],
 D01:pow([1,2],4)[2],D02:mul(pow([1,2],3),[1,-1])[2],D03:Math.sqrt(54/C(4,2)),
 L01:pow([1,1],3)[2],L02:pow([2,1],5)[3],L03:pow([3,-2],4)[0],
 M01:mul(pow([1,1],3),[1,2])[2],M02:mul(pow([1,1],4),[1,-1])[2],
 R01:pow([1,-3],4)[1],R02:pow([2,1],4)[2],R03:pow([5,-2],4)[0],R04:mul(pow([2,1],3),[1,-1])[2]
};
for(const [s,n]of Object.entries(poly))matched("SER","01",s,n);
const arith=(a,d,n)=>n*(2*a+(n-1)*d)/2;
const ap={A01:(32-14)/6,A02:((220/5)-8)/9,A03:11-2*(31-11)/5,
 D01:arith(5,3,10),D02:(37-17)/5,D03:7+11*3,L01:7+11*4,
 L02:arith(2,3,20),L03:(31-3)/7,M02:Math.floor((100-3)/5)+1,
 R01:arith(4,2,15),R02:47-11*4,R03:18-4*(46-18)/7,R04:230-189};
for(const [s,n]of Object.entries(ap))matched("SER","03",s,n);
A.equal(key("SER","03","M01"),"6n−1");
for(let n=1;n<=30;n++)near(3*n*n+2*n-(3*(n-1)**2+2*(n-1)),6*n-1);
const gp=(a,r,n)=>a*(1-r**n)/(1-r);
const geo={A01:10/Math.sqrt(40/10),A02:Math.cbrt(162/6),A03:1/(81*(1/3)**5),
 D01:gp(3,2,6),D02:Math.cbrt(324/12),D03:gp(5,2,6),
 L01:5*.5**7,L02:gp(4,3,5),L03:Math.cbrt(54/2),M01:Math.log(243)/Math.log(3),
 M02:gp(2,3,4),R01:gp(6,2,4),R02:20/4,R03:20/(Math.cbrt(160/20)**2),R04:gp(3,.5,5)};
for(const [s,n]of Object.entries(geo))matched("SER","04",s,n);
const inf={A02:1-18/30,A03:1/(1-1/3),D01:12/(1-.5),D02:18/(1-1/3),
 L02:5/(1-.2),L03:1-8/10,M01:6*.5**4/(1-.5),M02:16*.5**3/(1-.5),
 R01:9/(1-1/3),R03:20*(-.25)/(1+.25),R04:30-12-12*.6};
for(const [s,n]of Object.entries(inf))matched("SER","05",s,n);
near(10/(1+.4),50/7);
A.equal(key("SER","05","L01"),"|r|<1");
for(const r of [-.5,.5,.2,1/3,-.4])A.ok(Math.abs(r)<1);
const rad=d=>d*Math.PI/180,deg=r=>r*180/Math.PI;
const sin=d=>Math.sin(rad(d)),cos=d=>Math.cos(rad(d)),tan=d=>Math.tan(rad(d));
const trig={
 "A01-QA20261101":sin(210),A02:cos(60)-tan(135),A03:2*sin(150)-cos(180),
 D01:sin(150),D02:cos(225),D03:tan(330),
 L01:cos(120),L02:tan(225),L03:sin(330),
 M01:2*sin(30)+cos(180),M02:4*sin(30)*cos(60)-tan(225),
 R01:cos(300),R02:tan(135),R03:2*cos(60)+tan(45),R04:sin(270)*cos(180)};
for(const [s,n]of Object.entries(trig))matched("TRI","02",s,n);
A.ok(!maps.TRI.has("P1TRI02-A01"));
near(sin(210),-.5);A.ok(Math.abs(sin(210)+Math.sqrt(3)/2)>.2);
near(deg(Math.asin(-.5)),-30);near(deg(Math.acos(-.5)),120);
near(deg(Math.atan(-Math.sqrt(3))),-60);
near(Math.round(deg(Math.acos(.25))*10)/10,75.5);
near(Math.round(deg(Math.asin(.3))*10)/10,17.5);
near(Math.round(deg(Math.acos(-.4))*10)/10,113.6);
for(const x of [-2,-1,.23,.76,1.5,2.6]){
 const s=Math.sin(x),c=Math.cos(x);near(s*s+c*c,1);
 near((1-s*s)/c,c);near(Math.tan(x)*c,s);
 near((1-c*c)/(s*c),Math.tan(x));
}
near(1-.6**2,.64);near(1-(12/13)**2,25/169);near(1-.8**2,.36);
const solve=(fn,target,from,to,inclusive)=>{
 const solutions=[];for(let d=from;d<=to;d++){
  if(d===to&&!inclusive)continue;
  if(Number.isFinite(fn(d))&&Math.abs(fn(d)-target)<1e-9)solutions.push(d);
 }return solutions;
};
for(const [fn,t,from,to,last,expected]of [
 [sin,-.5,0,360,false,[210,330]],[cos,0,-180,180,true,[-90,90]],
 [tan,1,0,720,false,[45,225,405,585]],[sin,.5,0,360,true,[30,150]],
 [cos,-Math.SQRT1_2,-180,180,false,[-135,135]],
 [tan,1/Math.sqrt(3),-90,270,true,[30,210]],
 [cos,.5,0,360,false,[60,300]],[tan,1,0,360,false,[45,225]],
 [sin,-Math.sqrt(3)/2,0,360,false,[240,300]],
 [cos,-.5,0,360,false,[120,240]],[tan,-Math.sqrt(3),0,360,false,[120,300]],
 [sin,0,-360,360,true,[-360,-180,0,180,360]]
])A.deepEqual(solve(fn,t,from,to,last),expected);
A.deepEqual(solve(sin,cos(45),0,360,false),[45,135]);
console.log("TRI/SER 150 keyed source checks; independent binomial, progressions, trigonometry and interval roots PASS");
