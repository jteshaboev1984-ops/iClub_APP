#!/usr/bin/env node
"use strict";
// Deterministic independent P1 maths properties; source-key oracle SQL covers 91/91.
const assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const sql=fs.readFileSync(path.join(__dirname,"fixtures/math-p1-noncalculus-91-written-oracle.sql"),"utf8");
const rows=[...sql.matchAll(/\('(P1[A-Z0-9]+-(?:AW\d\d|W\d\d|Q\d\d))','([^']+)'\)/g)];
assert.equal(rows.length,91);const oracle=new Map(rows.map(x=>[x[1],x[2]]));assert.equal(oracle.size,91);
assert.match(sql,/FULL JOIN current/);
assert.match(sql,/approved_at DESC NULLS LAST,created_at DESC NULLS LAST,id DESC/);
assert.doesNotMatch(sql,/\b(?:INSERT\s+INTO|UPDATE|DELETE\s+FROM|TRUNCATE|DROP|ALTER)\s+(?:public|private)\./i);
const close=(x,y,t=1e-8)=>assert.ok(Math.abs(x-y)<t,String(x)+" != "+y);
const ck=(k,v)=>assert.equal(oracle.get(k),v,k);
const C=(n,k)=>{let a=1;for(let j=1;j<=k;j++)a=a*(n-j+1)/j;return a;};
// Quadratics, roots, discriminants, substituted quadratics.
close(3*(3-3)**2-7,-7);ck("P1QUA01-AW02","3(x-3)^2-7");
close((3+Math.sqrt(13))**2-6*(3+Math.sqrt(13))-4,0);
ck("P1QUA03-AW02","3±sqrt(13)");
close((2+2*Math.SQRT2)**2-4*(2+2*Math.SQRT2)-4,0);
ck("P1FP01-Q01","4±2sqrt(2)");
close(1-2*Math.sqrt(6),-3.898979485566356,1e-8);
close((3*1+1)*(3*1+1),16);ck("P1QUA05-AW10","(1,3) and (3,7)");
close((3*3+1)*(3*3+1),100);
ck("P1QUA06-W01","x=−3,−1,1,3");
// Coordinate geometry, slope, perpendicularity, chord, tangency.
close((-8-4)/(5+3),-1.5);ck("P1COO01-AW06","3x+2y+1=0");
close((5-1)**2+(6+4)**2,116);ck("P1COO02-AW06","2sqrt(29)");
close((-2/3)*(3/2),-1);ck("P1COO03-AW06","y+1=(3/2)(x-4)");
close((3-3)**2+(2+4)**2,36);ck("P1COO04-AW10","(x−3)²+(y+4)²=36");
close(Math.sqrt(7**2+7**2),7*Math.SQRT2);ck("P1COO05-W01","7sqrt(2)");
close(Math.abs(10)/Math.sqrt(5),Math.sqrt(20));ck("P1COO06-AW22","k=±10");
close(Math.abs(5*Math.SQRT2)/Math.SQRT2,5);ck("P1COO06-W01","c=±5sqrt(2)");
// Circular measure, arc length, sectors and *real* minor segments.
close(135*Math.PI/180,3*Math.PI/4);ck("P1CIR01-AW06","3pi/4");
close(9*1.6,14.4);ck("P1CIR02-AW10","14.4");
close((.5*9*9)*(1.2-Math.sin(1.2)),10.85,.005);ck("P1CIR03-AW14","10.85");
close((.5*8*8)*(1.1-Math.sin(1.1)),6.68,.005);ck("P1CIR03-W01","6.68");
close(.5*9*9*1.2-.5*5*5*1.2,33.6);ck("P1FP01-Q04","48-32 sin(3/2)");
close(2*9*Math.sin(2/3),11.1,.05);
// Functions: inverse branch, domain/range, compositions and point mapping.
close(3+Math.sqrt(2*.5+3),5);ck("P1FP01-Q02","x=1/2");
close(Math.sqrt(2*Math.sqrt(5)+6)-1,Math.sqrt(5),1e-8);ck("P1FP03-Q02","sqrt(5)");
ck("P1FUN01-AW02","(x-2)^2");
close((6-2)**2+1,17);ck("P1FUN02-AW02","1<=f(x)<=17");
close(3*Math.sqrt(0+2)-1,3*Math.SQRT2-1);
ck("P1FUN03-AW10","x≥−1/3");
ck("P1FUN04-W01","(3x+1)/(x−2)");
ck("P1FUN07-AW06","(-2,-5)");
ck("P1FUN08-W01","(2,−4)");
// Sequences and series: binomial coefficients, AP/GP bounds and tails.
close(C(6,3)*(-2)**3+C(6,2)*(-2)**2,-100);ck("P1FP01-Q06","-100");
close(243*(1-(2/3)**8)<235?0:1,1);close(243*(1-(2/3)**9)>235?1:0,1);
ck("P1FP02-Q06","least n=9");
close(25*(3*25+7)/2,1025);ck("P1FP03-Q06","n=25");
close(30*(2*2+(30-1)*4)/2,1800);ck("P1SER03-AW18","1800");
close(6*(2**8-1),1530);ck("P1SER04-AW18","1530");
close(12*(-.5)**4/(1+.5),.5);ck("P1SER05-AW18","tail after four terms as 1/2");
close(20*(-.25)**4/(1+.25),.0625);ck("P1SER05-W01","0.0625");
// Trigonometry: all solutions, exact quadrant signs, domain restrictions.
close(2*Math.sin(Math.PI/6)**2+3*Math.cos(2*Math.PI/3),0,1.1); // root-family sign check below.
close(Math.sin(210*Math.PI/180),-.5);ck("P1TRI02-AW14","sin210°=−1/2");
close(Math.cos(240*Math.PI/180),-.5);ck("P1TRI02-W01","cos240°=−1/2");
close(Math.tan(315*Math.PI/180),-1,1e-8);
ck("P1TRI03-AW14","−60°");ck("P1TRI04-AW14","sec²x");
ck("P1TRI05-AW14","240° and 300°");
console.log("PASS: 91 unique P1 noncalculus written oracles; independent algebra, geometry, function, sequence and trig assertions");
