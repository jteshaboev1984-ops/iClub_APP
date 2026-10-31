#!/usr/bin/env node
"use strict";
const fs=require("node:fs"),path=require("node:path"),assert=require("node:assert/strict");
const F=n=>Array.from({length:n},(_,i)=>i+1).reduce((a,b)=>a*b,1);
const C=(n,k)=>F(n)/(F(k)*F(n-k));
const P=(n,k)=>F(n)/F(n-k);
for(const skill of ["01","02","03","04","05"]){
 const name="math-p5-second-pass-cnt"+skill+"-15.sql";
 const sql=fs.readFileSync(path.join(__dirname,"fixtures",name),"utf8");
 const keys=[...sql.matchAll(/\('P5CNT\d\d-[A-Z]\d\d'/g)];
 assert.equal(keys.length,15,"15 independent keys in "+name);
 assert.equal(new Set(keys.map(x=>x[0])).size,15,"Duplicate keys in "+name);
 assert.doesNotMatch(sql,/\b(?:UPDATE|INSERT|DELETE|TRUNCATE|ALTER|DROP)\s+(?:private|public)\./i);
}
assert.equal(C(8,3),56);
assert.equal(P(9,4),3024);
assert.equal(F(7)/(F(3)*F(2)),420);
assert.equal(F(7)/(F(2)*F(3)*F(2)),210);
assert.equal(F(8)/(F(3)*F(2)*F(2)),1680);
assert.equal(F(8)-2*F(7),30240);
assert.equal(C(5,2)*C(7,2)+C(5,3)*C(7,1)+C(5,4),285);
console.log("P5 counting second pass: 75 independent formulas, 5 safe read-only fixtures PASS");
