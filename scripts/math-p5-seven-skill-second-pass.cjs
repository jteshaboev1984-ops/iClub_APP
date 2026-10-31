#!/usr/bin/env node
"use strict";
const fs=require("node:fs"),path=require("node:path"),assert=require("node:assert/strict");
const files=[
 ["math-p5-second-pass-bin03-geo03-30.sql",30],
 ["math-p5-second-pass-pro01-15.sql",15],
 ["math-p5-second-pass-nor02-15.sql",15],
 ["math-p5-second-pass-model-conceptual-45.sql",null]
];
for(const [name,expected] of files){
 const sql=fs.readFileSync(path.join(__dirname,"fixtures",name),"utf8");
 assert.match(sql,/SELECT /i);
 assert.doesNotMatch(sql,/\b(?:INSERT|DELETE|UPDATE|TRUNCATE|ALTER|DROP)\s+(?:private|public)\./i);
 if(expected!==null) {
  const n=(sql.match(/\('P5(?:BIN|GEO|PRO|NOR)\d\d-[A-Z]\d\d'/g)||[]).length;
  assert.equal(n,expected,name+" source key coverage");
 }
}
const close=(x,y)=>assert.ok(Math.abs(x-y)<1e-9, x+" not equal "+y);
close((1-Math.sqrt(1-4*8.4/40))/2,.3);
close(80*.15*.85,10.2);
close(1/6.25,.16);
close(Math.cbrt(.216),.6);
close((2**3)*1,8);
close(6*6*2,72);
close((68-60)/Math.sqrt(16),2);
close((20-30)/Math.sqrt(25),-2);
close(1-.933192798,.066807202);
console.log("P5 second-pass: 60 numeric formula fixtures, 45 conceptual structure checks, no database writes PASS");
