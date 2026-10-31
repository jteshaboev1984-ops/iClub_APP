#!/usr/bin/env node
"use strict";
const assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
for(let i=1;i<=3;i++){
 const skill=String(i).padStart(2,"0");
 const sql=fs.readFileSync(path.join(__dirname,"fixtures",`math-p5-second-pass-drv${skill}-15.sql`),"utf8");
 const keys=[...sql.matchAll(/\('P5DRV\d\d-[A-Z]\d\d'/g)].map(x=>x[0]);
 assert.equal(keys.length,15,"15 source keys per discrete skill");
 assert.equal(new Set(keys).size,15,"No duplicate source keys");
 assert.doesNotMatch(sql,/\b(?:UPDATE|INSERT|DELETE|TRUNCATE|ALTER|DROP)\s+(?:private|public)\./i,"Read-only academic fixture");
 assert.ok(sql.includes("FULL JOIN source"),"Protect unexpected or missing source questions");
}
const near=(a,b)=>assert.ok(Math.abs(a-b)<1e-10,`Math mismatch: ${a} != ${b}`);
near(1/(1+2+1+2),1/6);
near(1-(.2+.3),.5);
near((1-.1)/4,.225);
near(-2*.4+3*.6,1.0);
near(10*.1+2*.4-1*(1-.1-.4),1.3);
near((0*.25+2*.25+4*.5),2.5);
near((0**2*.25+2**2*.25+4**2*.5)-2.5**2,2.75);
near((0**2*.5+1**2*.25+4**2*.25)-(1*.25+4*.25)**2,43/16);
near(Math.sqrt((0**2*.2+2**2*.5+5**2*.3)-(0*.2+2*.5+5*.3)**2),Math.sqrt(13)/2);
console.log("P5 DRV-01..03: 45 unique source keys and independent expectation/variance math PASS");
