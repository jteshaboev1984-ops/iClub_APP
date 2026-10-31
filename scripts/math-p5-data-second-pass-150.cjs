#!/usr/bin/env node
"use strict";
const assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const dir=path.join(__dirname,"fixtures");
for(let i=1;i<=10;i++){
 const skill=String(i).padStart(2,"0");
 const file="math-p5-second-pass-dat"+skill+"-15.sql";
 const sql=fs.readFileSync(path.join(dir,file),"utf8");
 const keys=[...sql.matchAll(/\('P5(?:DAT\d\d|MIX)-[A-Z]\d\d'/g)].map(x=>x[0]);
 assert.equal(keys.length,15,"15 source keys expected in "+file);
 assert.equal(new Set(keys).size,15,"Duplicate source keys in "+file);
 assert.doesNotMatch(sql,/\b(?:UPDATE|INSERT|DELETE|TRUNCATE|ALTER|DROP)\s+(?:private|public)\./i,"SQL must remain read-only");
 assert.ok(sql.includes("FULL JOIN source"),"Must not hide missing/extra questions");
 assert.ok(sql.includes("count(*) FILTER(WHERE wrong)"),"Must expose mismatch total");
}
const near=(x,y,tol=1e-9)=>assert.ok(Math.abs(x-y)<=tol,"Expected "+x+" to equal "+y);
near((2*2.5+4*10+2*20)/8,10.625);
near((18-(-3))/1.5+18,32);
near((116-44),72);
near((110-35)*100/160,46.875);
near((45/6),7.5);
near((2**2+2**2+4**2+8**2)/4-((2+2+4+8)/4)**2,6);
near((290/5)-(35/5)**2,9);
near((23/6)-(11/6)**2,17/36);
near((3*25+10*6+14),149);
near((15*24+25*30)/40,27.75);
near((20*17.5-180)/8,21.25);
near((8*5+12*9)/20,7.4);
console.log("P5 DAT-01..10: all 150 source keys, independent statistical calculations and read-only fixtures PASS");
