#!/usr/bin/env node
"use strict";
const assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
for(const skill of ["cir01","cir02","qua01","qua02","qua03","qua04","qua05","qua06"]){
 const q=fs.readFileSync(path.join(__dirname,"fixtures","math-p1-second-pass-"+skill+"-15.sql"),"utf8");
 const keys=[...q.matchAll(/\('P1(?:CIR|QUA)\d\d-[A-Z]\d\d'/g)].map(x=>x[0]);
 assert.equal(keys.length,15,"Expected 15 current items in "+skill);
 assert.equal(new Set(keys).size,15,"Duplicate key in "+skill);
 assert.match(q,/FULL JOIN actual/);
 assert.doesNotMatch(q,/\b(?:UPDATE|INSERT|DELETE|TRUNCATE|DROP|ALTER)\s+(?:public|private)\./i);
}
const close=(a,b,tol=1e-9)=>assert.ok(Math.abs(a-b)<=tol,String(a)+" is not "+String(b));
const pi=Math.PI, deg=r=>r*180/pi,rad=d=>d*pi/180;
for(const [d,n,z] of [[210,7,6],[150,5,6],[330,11,6],[60,1,3],[225,5,4],[315,7,4],[72,2,5]]){
 close(rad(d),n*pi/z);close(deg(n*pi/z),d);
}
for(const [rn,rd,d] of [[11,18,110],[13,12,195],[7,12,105],[1,8,22.5]])close(deg(rn*pi/rd),d);
close(deg(pi/4)+35,80);close(deg(5*pi/18)+40,90);
close(rad(40)+pi/6,7*pi/18);close(7*pi/12+rad(15),2*pi/3);
for(const [r,theta,s] of [[6,1.2,7.2],[5,.8,4],[4,2.25,9],[8,1.5,12],[6,1.5,9]])close(r*theta,s);
close((18-2*5)/5,1.6);close((9+6)/9,5/3);close(9/.6,15);
close(8/12,2/3);close(8*1.5/5,2.4);close(10*pi/rad(150),12);
close(deg(5*pi/6),150);close(6/8,3/4);
const parabola=(a,b,c)=>({x:-b/(2*a),y:c-b*b/(4*a)});
for(const [a,b,c,x,y] of [
 [2,12,11,-3,-7],[-3,12,-1,2,11],[4,8,9,-1,5],
 [1,-6,11,3,2],[3,-18,31,3,4],[-2,-8,1,-2,9],
 [1,8,19,-4,3],[2,-12,7,3,-11],[1,-10,31,5,6],
 [-2,16,3,4,35],[1,4,-5,-2,-9],[-1,6,-4,3,5],
 [5,-20,23,2,3],[-1,10,-18,5,7]
]){
 const v=parabola(a,b,c);close(v.x,x);close(v.y,y);
 for(let delta of [-2,-1,0,1,2])close(a*(x+delta)**2+b*(x+delta)+c,a*delta*delta+y);
}
const discr=(a,b,c)=>b*b-4*a*c;
assert.equal(discr(3,4,5),-44);assert.equal(discr(1,6,10),-4);
assert.equal(discr(1,-6,10),-4);assert.equal(discr(1,4,4),0);
for(const k of [-3,7])assert.ok(discr(1,k-2,4)>0);
for(const k of [-2,6])assert.equal(discr(1,k-2,4),0);
for(const m of [-3,3])assert.equal(discr(4,-4*m,9),0);
close(discr(1,-2*(-.5+1),(-.5)**2),0);
close(discr(2,-3,1),1);close(discr(1,-4,4),0);
close(discr(3,-6,3),0);
for(const q of [-2*Math.sqrt(10),2*Math.sqrt(10)])close(discr(2,q,5),0);
const roots=(a,b,c)=>{const d=discr(a,b,c);return d>=0?[(-b-Math.sqrt(d))/(2*a),(-b+Math.sqrt(d))/(2*a)]:[]};
for(const [a,b,c,expected] of [
 [2,-7,3,[.5,3]],[1,-4,-1,[2-Math.sqrt(5),2+Math.sqrt(5)]],
 [1,2,-7,[-1-2*Math.sqrt(2),-1+2*Math.sqrt(2)]],
 [1,10,17,[-5-2*Math.sqrt(2),-5+2*Math.sqrt(2)]],
 [3,2,-8,[-2,4/3]],[1,6,1,[-3-2*Math.sqrt(2),-3+2*Math.sqrt(2)]],
 [1,-5,-24,[-3,8]],[1,3,-54,[-9,6]],[4,-12,5,[.5,2.5]],
 [1,-5,-14,[-2,7]],[3,-5,-2,[-1/3,2]],
 [2,3,-4,[(-3-Math.sqrt(41))/4,(-3+Math.sqrt(41))/4]]
]){
 const found=roots(a,b,c);assert.equal(found.length,expected.length);
 for(let i=0;i<found.length;i++){close(found[i],expected[i]);close(a*found[i]**2+b*found[i]+c,0);}
}
const positive=(a,b,c,x)=>a*x*x+b*x+c>0;
assert.ok(positive(1,-5,6,1)&&!positive(1,-5,6,2.5)&&positive(1,-5,6,4));
assert.ok(!positive(3,-14,8,3)&&positive(3,-14,8,0));
assert.ok(positive(1,0,-9,4)&&!positive(1,0,-9,0));
assert.ok(positive(1,2,-8,-5)&&!positive(1,2,-8,0)&&positive(1,2,-8,3));
assert.ok(positive(-2,7,-3,2)&&!positive(-2,7,-3,0));
for(const k of [0,2])assert.equal(discr(1,-2,1-k),4*k);
close(roots(1,-6,6)[0]+roots(1,-6,6)[1],6);
close(roots(1,-4,2)[0]*roots(1,-4,2)[1],2);
close(roots(1,1,-12)[0]+roots(1,1,-12)[1],-1);
close(roots(1,-4,3)[0]*roots(1,-4,3)[1],3);
assert.equal(discr(1,-4,4),0);
close(roots(1,-4,3)[1]-roots(1,-4,3)[0],2);
const biquad=(a,b,c)=>roots(a,b,c).filter(u=>u>=0).flatMap(u=>u===0?[0]:[-Math.sqrt(u),Math.sqrt(u)]).sort((x,y)=>x-y);
assert.deepEqual(biquad(1,-5,4),[-2,-1,1,2]);
assert.deepEqual(biquad(1,-13,36),[-3,-2,2,3]);
const calc=biquad(1,-7,12).map(x=>Math.round(x*10000)/10000);
const target=[-Math.sqrt(2),-(3**.25),3**.25,Math.sqrt(2)].map(x=>Math.round(x*10000)/10000).sort((a,b)=>a-b);
assert.deepEqual(calc,target);
close(2+2+5+5,14);
console.log("P1 CIR/QUA second-pass: 120 distinct keyed questions, independent geometry/algebra oracles, no writes PASS");
