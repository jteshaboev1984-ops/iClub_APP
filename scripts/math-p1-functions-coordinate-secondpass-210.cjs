#!/usr/bin/env node
"use strict";
// Mathematical regression: source-backed answers plus independent numerical methods.
// Separate read-only SQL fixtures compare all keyed values with the LIVE database.
const A=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const files=["math-p1-fun-01-04-60-secondpass.sql","math-p1-fun-05-08-60-secondpass.sql","math-p1-coo-01-03-45-secondpass.sql","math-p1-coo-04-06-45-secondpass.sql"];
const n=[60,60,45,45],keys=new Map();
for(let i=0;i<files.length;i++){
 const s=fs.readFileSync(path.join(__dirname,"fixtures",files[i]),"utf8");
 const rows=[...s.matchAll(/\('(P1(?:FUN|COO)\d\d-[A-Z]\d\d)','((?:[^']|'')*)'\)/g)];
 A.equal(rows.length,n[i],files[i]);
 A.match(s,/FULL JOIN actual/);
 A.doesNotMatch(s,/\b(?:UPDATE|INSERT|DELETE|DROP|TRUNCATE|ALTER)\s+(?:private|public)\./i);
 for(const [,k,v]of rows){A.ok(!keys.has(k),"Duplicate "+k);keys.set(k,v.replaceAll("''","'"))}
}
A.equal(keys.size,210);
for(const [prefix,count] of [["P1FUN",8],["P1COO",6]])for(let j=1;j<=count;j++)
 A.equal([...keys.keys()].filter(k=>k.startsWith(prefix+String(j).padStart(2,"0")+"-")).length,15);
const close=(a,b,t=1e-9)=>A.ok(Math.abs(a-b)<t,String(a)+" is not "+String(b));
const check=(k,v)=>A.equal(keys.get(k),v,k);
const point=(x,y)=>[x,y],mid=(a,b)=>[(a[0]+b[0])/2,(a[1]+b[1])/2];
const dist=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);
const slope=(a,b)=>(b[1]-a[1])/(b[0]-a[0]);
const intercept=(m,p)=>p[1]-m*p[0];
for(const [k,m,p,c]of [
 ["P1COO01-A01",-3,[2,-5],1],["P1COO01-D01",3,[2,-1],-7],
 ["P1COO01-D02",5,[-1,2],7],["P1COO01-R04",-2,[4,1],9]
])close(intercept(m,p),c);
for(const [k,a,b,m,c]of [
 ["P1COO01-A02",[-2,1],[4,13],2,5],
 ["P1COO01-D03",[3,-2],[7,10],3,-11],
 ["P1COO01-L02",[1,2],[5,10],2,0],
 ["P1COO01-M02",[-4,7],[2,-5],-2,-1],
 ["P1COO01-R03",[4,0],[2,6],-3,12]
]){close(slope(a,b),m);close(intercept(m,a),c);close(intercept(m,b),c)}
check("P1COO01-A03","7");check("P1COO01-R03","12");
for(const [k,a,b,x,y]of [
 ["P1COO02-A01",[-5,2],[3,10],-1,6],
 ["P1COO02-D01",[-2,3],[4,7],1,5],
 ["P1COO02-D02",[-6,4],[2,-8],-2,-2],
 ["P1COO02-R01",[2,-4],[8,6],5,1]
])A.deepEqual(mid(a,b),[x,y],k);
for(const [k,a,b,d]of [
 ["P1COO02-A02",[-1,2],[5,10],10],
 ["P1COO02-D03",[2,-1],[8,7],10],
 ["P1COO02-L01",[1,2],[4,6],5],
 ["P1COO02-R02",[-2,-1],[4,7],10]
]){close(dist(a,b),d);check(k,String(d))}
check("P1COO02-M02",String(dist([0,0],mid([0,0],[6,8]))));
close((8-(-4))/(3-(-1)),3);
close((7-1)/(-1-2),-2);
A.deepEqual([(7-1)/(2-(-1)),(7-1)/(2-(-1))*2+1],[2,5]);
check("P1COO02-L02","(2,5)");
check("P1COO02-A03","3");check("P1COO02-R03","2");
A.deepEqual([2*(-1)-(-7),2*1-5],[5,-3]);check("P1COO02-R04","(5,−3)");
for(const [m,perp]of [[-2/3,3/2],[3/2,-2/3],[-4/5,5/4],[.5,-2],[-1/3,3]])
 close(m*perp,-1);
close(slope([-1,1],[3,3]),.5);
close(intercept(-2,[2,5]),9);check("P1COO03-M01","y=−2x+9");
close(intercept(-2,[2,-3]),1);check("P1COO03-M02","y=−2x+1");
close(intercept(2,[3,-1]),-7);check("P1COO03-R03","-7");
const circle=(d,e,f)=>({x:-d/2,y:-e/2,r:Math.sqrt((d*d+e*e)/4-f)});
for(const [d,e,f,x,y,r]of [
 [6,-8,-11,-3,4,6],[-4,10,13,2,-5,4],
 [-6,4,-12,3,-2,5],[8,-2,-8,-4,1,5],[-2,-6,-6,1,3,4]
]){const v=circle(d,e,f);close(v.x,x);close(v.y,y);close(v.r,r)}
close(dist([-1,2],[5,6])/2,Math.sqrt(13));
check("P1COO04-A02","(x−2)²+(y−4)²=13");
check("P1COO04-A03","4");
check("P1COO04-R03",String(Math.abs(-4)));
close(dist([1,-2],[4,2]),5);check("P1COO04-M01","(x−1)²+(y+2)²=25");
for(const x of [2,-3])close(x*x+(x+1)**2,13);
check("P1COO05-A01","−1");check("P1COO05-R04","2 and −3");
for(const [k,r,d,w]of [
 ["P1COO05-A02",5,3,8],["P1COO05-A03",5,0,10],
 ["P1COO05-L02",3,0,6],["P1COO05-M01",5,4,6]
]){close(2*Math.sqrt(r*r-d*d),w);check(k,String(w))}
check("P1COO05-R03","4");
for(const [m,r2,k2]of [[1,10,20],[2,16,80],[1,8,16],[2,5,25],[1,2,4],[2,20,100]])
 close((1+m*m)*r2,k2);
check("P1COO06-A02","80");check("P1COO06-R04","100");
check("P1COO06-M02","4");check("P1COO06-R03","2");
// Functions: algebraic reversal, endpoint extrema and coordinate maps.
for(const x of [-7,0,4,11]){
 close(3*((x+7)/3)-7,x);
 const y=(2*x+1)/(x-3);close((3*y+1)/(y-2),x);
}
check("P1FUN01-A03","25");close((2*3-1)**2,25);
check("P1FUN01-R04","1");check("P1FUN04-M02","8");
const quadratic=(x,h,k,a)=>a*(x-h)**2+k;
for(const [h,k,a,d,low,high]of [
 [-2,-1,1,[-5,1],-1,8],[1,5,-2,[0,4],-13,5],
 [4,2,1,[4,7],2,11],[2,0,1,[0,5],0,9],
 [0,4,-1,[-1,2],0,4],[4,20,-1,[1,6],11,20],
 [2,1,1,[-1,4],1,10]
]){
 let vals=d.map(x=>quadratic(x,h,k,a));if(h>=d[0]&&h<=d[1])vals.push(k);
 close(Math.min(...vals),low);close(Math.max(...vals),high);
}
check("P1FUN02-R04","-7");
for(const x of [-4,0,.5,1.5,4,6])A.equal((x-1)*(x-4)>=0,x<=1||x>=4);
check("P1FUN03-M02","x≤1 or x≥4");
const translate=(p,dx,dy)=>[p[0]+dx,p[1]+dy];
const reflect=(p,rx,ry)=>[rx?-p[0]:p[0],ry?-p[1]:p[1]];
const scale=(p,h,v)=>[p[0]*h,p[1]*v];
A.deepEqual(translate([-2,5],3,2),[1,7]);check("P1FUN06-A02","(1,7)");
A.deepEqual(translate([-4,2],6,-3),[2,-1]);check("P1FUN06-D02","(2,−1)");
A.deepEqual(translate([-2,0],5,7),[3,7]);check("P1FUN06-M02","(3,7)");
A.deepEqual(reflect([3,-4],true,false),[-3,-4]);check("P1FUN07-A01","(−3,−4)");
A.deepEqual(reflect([-5,6],true,true),[5,-6]);check("P1FUN07-A03","5");
A.deepEqual(reflect([-6,4],true,true),[6,-4]);check("P1FUN07-R03","2");
A.deepEqual(scale([6,-2],3,2),[18,-4]);check("P1FUN08-A01","(18,−4)");
A.deepEqual(scale([8,-3],.5,4),[4,-12]);check("P1FUN08-D02","(4,−12)");
A.deepEqual(scale([9,4],3,-2),[27,-8]);check("P1FUN08-M02","(27,−8)");
A.deepEqual(scale([-10,6],.2,.5),[-2,3]);check("P1FUN08-R03","1");
console.log("PASS: 210 current source keys, independent geometry/functions numerical calculations and source fixture integrity.");
