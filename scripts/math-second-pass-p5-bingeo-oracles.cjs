#!/usr/bin/env node
"use strict";
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const readOnly=fs.readFileSync(path.join(__dirname,"fixtures/math-second-pass-p5-bin-geo-30-readonly.sql"),"utf8");
const choose=(n,k)=>{let a=1;for(let i=1;i<=k;i++)a=a*(n-i+1)/i;return a};
const bin=(n,p,k)=>choose(n,k)*p**k*(1-p)**(n-k);
const geo=(p,k)=>p*(1-p)**(k-1);
const cases=[
 ["P5BIN02-A01",()=>bin(5,.15,1),"0.3915"],
 ["P5BIN02-A02",()=>1-bin(10,.1,0)-bin(10,.1,1),"0.2639"],
 ["P5BIN02-A03",()=>1/(bin(6,.5,0)+bin(6,.5,6)),"32"],
 ["P5BIN02-D01",()=>bin(5,.2,0),"0.32768"],
 ["P5BIN02-D02",()=>1-bin(8,.25,0),"0.8999"],
 ["P5BIN02-D03",()=>bin(6,.4,2),"0.3110"],
 ["P5BIN02-L01",()=>bin(4,.5,2),"0.375"],
 ["P5BIN02-L02",()=>1-bin(3,.2,0),"0.488"],
 ["P5BIN02-L03",()=>bin(6,.3,0)+bin(6,.3,1),"0.420175"],
 ["P5BIN02-M01",()=>1-bin(4,.5,0)-bin(4,.5,4),"0.875"],
 ["P5BIN02-M02",()=>1-bin(12,.1,0),"0.7176"],
 ["P5BIN02-R01",()=>bin(5,.5,5),"0.03125"],
 ["P5BIN02-R02",()=>bin(4,.25,0),"0.31640625"],
 ["P5BIN02-R03",()=>bin(4,.5,3)+bin(4,.5,4),"5/16"],
 ["P5BIN02-R04",()=>bin(8,.1,0)+bin(8,.1,1),"0.8131"],
 ["P5GEO02-A01",()=>1-(.75)**4,"175/256"],
 ["P5GEO02-A02",()=>geo(.5,2)+geo(.5,3)+geo(.5,4),"7/16"],
 ["P5GEO02-A03",()=>8/geo(1/3,4),"81"],
 ["P5GEO02-D01",()=>geo(.2,3),"0.128"],
 ["P5GEO02-D02",()=>geo(.2,3),"(0.8)^2(0.2)"],
 ["P5GEO02-D03",()=>.7**4,"0.2401"],
 ["P5GEO02-L01",()=>.7**4,"0.2401"],
 ["P5GEO02-L02",()=>1-.75**3,"0.578125"],
 ["P5GEO02-L03",()=>geo(.4,1),"0.40"],
 ["P5GEO02-M01",()=>geo(.2,3)+geo(.2,4)+geo(.2,5),"0.31232"],
 ["P5GEO02-M02",()=>1-.4,"0.6"],
 ["P5GEO02-R01",()=>geo(.5,4),"0.0625"],
 ["P5GEO02-R02",()=>.9**2,"0.81"],
 ["P5GEO02-R03",()=>1-.5**3,"7/8"],
 ["P5GEO02-R04",()=>1-.75**2,"7/16"]
];
const numeric=s=>{
 if(s.includes("/")&&/^[0-9]+\/[0-9]+$/.test(s)){
  const [a,b]=s.split("/").map(Number);return {value:a/b,tol:1e-11};
 }
 const m=s.match(/^\((\d+(?:\.\d+)?)\)\^(\d+)\((\d+(?:\.\d+)?)\)$/);
 if(m)return{value:Number(m[1])**Number(m[2])*Number(m[3]),tol:1e-11};
 const d=s.split(".")[1]?.length||0;
 return{value:Number(s),tol:d===0?1e-11:(.5*10**(-d)+1e-11)};
};
assert.equal(cases.length,30);
for(const [key,formula,selected] of cases){
 const x=numeric(selected),actual=formula();
 assert.ok(Number.isFinite(actual),"Nonfinite "+key);
 assert.ok(Math.abs(actual-x.value)<=x.tol,"Independent math calculation contradicts "+key+": "+actual+" vs "+selected);
 assert.ok(readOnly.includes("('"+key+"','"+selected+"')"),"Live keyed-answer fixture disagrees "+key);
}
assert.doesNotMatch(readOnly,/\b(?:UPDATE|INSERT|DELETE|TRUNCATE|ALTER|DROP)\s+(?:private\.|public\.)/i);
console.log("Independent P5 binomial/geometric 30/30 math oracles and read-only live key assertions PASS");
