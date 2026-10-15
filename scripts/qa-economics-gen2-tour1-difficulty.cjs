// Economics Gen2 Season 2 Tour 1 editorial QA: read-only, zero network or DB use.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const items=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../content/economics-gen2-tour-difficulty/t1-hard.json'),'utf8'));
const easy=[2,4,5,7,9,14],medium=[1,3,6,8,10,13,15,16,17,20],hard=[11,12,18,19];
assert.equal(items.length,4);
assert.deepEqual(items.map(x=>x.n).sort((a,b)=>a-b),hard);
assert.equal(new Set([...easy,...medium,...hard]).size,20);
assert.deepEqual([...easy,...medium,...hard].sort((a,b)=>a-b),Array.from({length:20},(_,i)=>i+1));
for(const x of items){
 assert.equal(x.ref,'EC9708:G2:EC9708-G2-T1-T-'+String(x.n).padStart(3,'0'));
 assert.equal(x.d,'hard');assert(/^[ABCD]$/.test(x.k));
 assert(Number.isInteger(x.sec)&&x.sec>=90&&x.sec<=135,'Tour time budget must remain within original UX scale');
 assert(Array.isArray(x.why)&&x.why.length===3);
 for(const lang of ['en','ru','uz']){
   assert(typeof x[lang]==='string'&&x[lang].trim().length>60);
   const opts=x['options_'+lang];
   assert(Array.isArray(opts)&&opts.length===4&&new Set(opts.map(v=>v.trim())).size===4);
 }
 assert(x.why.every(v=>v.length>=35));
}
console.log('Economics G2 Tour1: 6 easy / 10 medium / 4 genuinely hard; EN/RU/UZ PASS');
