// Economics Gen2 Season2 Tour6 editorial gate; static, no DB.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const rows=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../content/economics-gen2-tour-difficulty/t6-hard.json'),'utf8'));
const easy=[1,4,6,8,12,20],med=[2,3,5,7,10,13,15,16,17,18],hard=[9,11,14,19];
assert.deepEqual(rows.map(x=>x.n).sort((a,b)=>a-b),hard);
assert.deepEqual([...easy,...med,...hard].sort((a,b)=>a-b),Array.from({length:20},(_,i)=>i+1));
for(const x of rows){
 assert.equal(x.ref,'EC9708:G2:EC9708-G2-T6-T-'+String(x.n).padStart(3,'0'));
 assert(x.d==='hard'&&/^[ABCD]$/.test(x.k));
 assert(Number.isInteger(x.sec)&&x.sec>=90&&x.sec<=135);
 assert(x.why.length===3&&x.why.every(y=>y.length>=35));
 for(const l of ['en','ru','uz']){
  assert(typeof x[l]==='string'&&x[l].trim().length>=60);
  const o=x['options_'+l];assert(Array.isArray(o)&&o.length===4);
  assert(o.every(z=>z.trim().length>0));assert.equal(new Set(o.map(z=>z.trim())).size,4);
 }
}
console.log('Economics Gen2 Tour6: real 6/10/4; 4 new hard EN/RU/UZ items and 20 unique positions');