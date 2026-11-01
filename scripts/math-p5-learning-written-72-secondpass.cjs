#!/usr/bin/env node
"use strict";
const fs=require("node:fs"),path=require("node:path"),assert=require("node:assert/strict");
const sql=fs.readFileSync(path.join(__dirname,"fixtures/math-p5-learning-written-72-secondpass.sql"),"utf8");
const matches=[...sql.matchAll(/\('(P5[A-Z]{3}\d\d-(?:AW|W)\d\d)','([^']+)'\)/g)];
assert.equal(matches.length,72,"Expected exactly 72 unique latest P5 learning written checkpoints");
const keys=new Map(matches.map(z=>[z[1],z[2]]));assert.equal(keys.size,72);
for (const [skill,expected] of [["DAT",20],["NOR",12],["PRO",12],["CNT",10],["BIN",6],["DRV",6],["GEO",6]]) {
 assert.equal([...keys.keys()].filter(k=>k.startsWith("P5"+skill)).length,expected,skill);
}
assert.match(sql,/FULL JOIN current/);
assert.match(sql,/approved_at DESC NULLS LAST,created_at DESC NULLS LAST,id DESC/);
assert.doesNotMatch(sql,/\b(?:UPDATE|INSERT\s+INTO|DELETE\s+FROM|TRUNCATE|ALTER|DROP)\s+(?:private|public)\./i);
const ck=(k,v)=>assert.equal(keys.get(k),v,k),close=(a,b,t=1e-8)=>assert.ok(Math.abs(a-b)<t,String(a)+" != "+String(b));
const C=(n,k)=>{let q=1;for(let j=1;j<=k;j++)q=q*(n-j+1)/j;return q};
const F=n=>{let f=1;for(let j=2;j<=n;j++)f*=j;return f};
// P5 binomial: model constraints, probabilities and variance.
ck("P5BIN01-AW14","B(15,0.04)");ck("P5BIN01-W01","n=12,p=1/6");
close(10*.75**9*.25+.75**10, .24402523040771484,1e-6);
ck("P5BIN02-AW18","P(X=10)=0.75^10");
close(C(8,2)*.25**2*.75**6,0.31146240234375,1e-9);
ck("P5BIN02-W01","C(8,2)(0.25)^2(0.75)^6");
close(10.5/15,.7);ck("P5BIN03-AW18","p=0.3");ck("P5BIN03-W01","n=30");
// P5 combinatorics: ordered offices/blocks, repeated arrangements, choice & chair.
close(9*8,72);ck("P5CNT01-AW06","9P2=72");
close(9*8*7,504);ck("P5CNT01-W01","504");
close(7*6*5*4,840);ck("P5CNT02-AW06","840");
close(F(7),5040);ck("P5CNT02-W01","5040");
close(F(7)/(F(2)*F(2)),1260);ck("P5CNT03-AW06","1260");
close(F(10)/(F(3)*F(3)*F(2)),50400);ck("P5CNT03-W01","50400");
close(2*F(5)*2,480);ck("P5CNT04-AW06","2×5!×2=480");
close(F(6)-2*F(5),480);ck("P5CNT04-W01","720−240=480");
close(C(5,2)*C(7,2)*4,840);ck("P5CNT05-AW10","840 outcomes");
close(10*C(9,3),840);ck("P5CNT05-W01","840");
// P5 statistics: quartiles, density, samples, coding, moments.
ck("P5DAT01-AW02","side-by-side box-and-whisker plots");
ck("P5DAT01-W01","side-by-side box plots");
close(4.2-2.3,1.9);ck("P5DAT02-AW02","range 4.2-2.3=1.9");
close((20+22)/2,21);ck("P5DAT02-W01","Median=(20+22)/2=21");
close(30+1.5*(30-18),48);ck("P5DAT03-AW10","upper fence 48");
close(31+1.5*(31-17),52);ck("P5DAT03-W01","upper fence=31+1.5×14=52");
close(18/6,3);ck("P5DAT04-AW02","densities 2,3,2");
close(20/5,4);ck("P5DAT04-W01","densities 2,3,4");
close(126/160*100,78.75);ck("P5DAT05-AW10","78.75%");
close(124/160*100,77.5);ck("P5DAT05-W01","77.5%");
close((2+10+12+4)/12,7/3);ck("P5DAT06-AW02","28/12=7/3");
close((4+5+5+6+30)/5,10);ck("P5DAT06-W01","Mean = 10");
close(2.6*3,7.8);ck("P5DAT07-AW10","7.8");
close(3*12-7,29);ck("P5DAT07-W01","3×12−7 = 29");
ck("P5DAT08-AW22","A as more consistent");ck("P5DAT08-W01","median 72>68");
close(264/6-6**2,8);ck("P5DAT09-AW22","264/6−36=8");
close(62/8-2.5**2,1.5);ck("P5DAT09-W01","62/8-2.5^2=1.5");
close((20*(40+5*(36/20))+10*55)/30,51);ck("P5DAT10-AW22","1530/30=51");
close(53800/20-51.5**2,37.75);ck("P5DAT10-W01","53800/20-51.5^2=37.75");
// P5 discrete: normalization, expectation, variance.
close((1-.3-.1)/3,.2);ck("P5DRV01-AW14","k=0.20");
close(.3+.4,.7);ck("P5DRV01-W01","P(X≥2)=0.7");
close(-3*.5+2*.35+8*.15+1,1.4);ck("P5DRV02-AW14","1.40");
close(-3*.2+2*.5+7*.3,2.5);ck("P5DRV02-W01","2.5");
close(Math.sqrt(6-2**2),Math.SQRT2);
ck("P5DRV03-AW14","√2");ck("P5DRV03-W01","sqrt(2)");
// P5 geometric: definitions, first-success probabilities, waiting-time expectation.
ck("P5GEO01-AW14","p=0.3");ck("P5GEO01-W01","p=1/6");
close(.65**3*.35,.09611875);ck("P5GEO02-AW18","0.65^3(0.35)");
close(.7-.7**4,.4599);ck("P5GEO02-W01","0.4599");
close(1/4,.25);ck("P5GEO03-AW18","p=0.25");
close(.8**3*.2,.1024);ck("P5GEO03-W01","0.1024");
// Normal: CDF, inverse CDF, normal approximation plus continuity correction.
const Phi=x=>{
 const y=Math.abs(x)/Math.sqrt(2),t=1/(1+0.3275911*y);
 const erf=1-(((((1.061405429*t-1.453152027)*t)+1.421413741)*t-0.284496736)*t+0.254829592)*t*Math.exp(-y*y);
 return (1+(x<0?-erf:erf))/2;
};
close(500-4,496);close(500+4,504);ck("P5NOR01-AW18","496 and 504");
ck("P5NOR01-W01","standard deviations 4 and 6");
close(Phi(1)-Phi(-2),.8185,.00015);ck("P5NOR02-AW22","0.8185");
close(Phi(1)-Phi(-1),.6827,.0001);ck("P5NOR02-W01","0.6827");
close(Phi(2)-Phi(-1),.8186,.0001);ck("P5NOR03-AW22","0.8186");
close(Phi(1.5)-Phi(-1),.7745,.0001);ck("P5NOR03-W01","0.7745");
close(Math.round((60+5*1.2816)*10)/10,66.4);ck("P5NOR04-AW22","66.4");
close(Math.round((70+3*1.2816)*10)/10,73.8);ck("P5NOR04-W01","[66.2,73.8]");
close((44+68)/2,56);ck("P5NOR05-AW22","μ=56");
close(Math.round((76.4-5*1.2816)*10)/10,70);ck("P5NOR05-W01","mu approximately 70.0");
close(Phi((55.5-48)/Math.sqrt(28.8)),.9189,.0003);ck("P5NOR06-AW22","0.9189");
close(Phi((54.5-48)/Math.sqrt(28.8))-Phi((41.5-48)/Math.sqrt(28.8)),.7742,.0002);
ck("P5NOR06-W01","0.7742");
// P5 probability: unions, conditional sample spaces, independence and no replacement.
close(4/6,2/3);ck("P5PRO01-AW06","4/6=2/3");ck("P5PRO01-W01","E={T2,T4}");
close(C(8,2)*C(4,1)/C(12,3),28/55);ck("P5PRO02-AW10","28/55");
close(C(5,2)*C(7,2)/C(12,4),14/33);ck("P5PRO02-W01","14/33");
close(.58+.47-.21,.84);ck("P5PRO03-AW06","0.84");
close(.55+.4-.2,.75);ck("P5PRO03-W01","0.75");
close(.55*.4/.32,.6875);ck("P5PRO04-AW10","0.6875");
close(.6*.35*.5,.105);ck("P5PRO04-W01","0.105");
close((36-18)/((36-18)+(30-18)),.6);ck("P5PRO05-AW14","18/(18+12)=3/5");
close(.18/.5,.36);ck("P5PRO05-W01","0.36");
close((C(5,2)+C(3,2)+C(2,2))/C(10,2),14/45);ck("P5PRO06-AW14","14/45");
close((5/8)*(3/7)+(3/8)*(5/7),15/28);ck("P5PRO06-W01","15/28");
console.log("PASS: 72 P5 current written keys and all seven-skill mathematical regression families");
