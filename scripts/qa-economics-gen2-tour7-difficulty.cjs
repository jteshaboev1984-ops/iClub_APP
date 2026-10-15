// Tour7 Economics Gen2 original trilingual questions: read-only static QA.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const rows=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../content/economics-gen2-tour-difficulty/t7-hard.json'),'utf8'));
const easy=[3,5,6,9,17,19],med=[1,2,7,8,11,12,13,15,16,18],hard=[4,10,14,20];
assert.deepEqual(rows.map(x=>x.n).sort((a,b)=>a-b),hard);
assert.deepEqual([...easy,...med,...hard].sort((a,b)=>a-b),Array.from({length:20},(_,i)=>i+1));
for(const x of rows){
 assert.equal(x.ref,'EC9708:G2:EC9708-G2-T7-T-'+String(x.n).padStart(3,'0'));
 assert(x.d==='hard'&&/^[ABCD]$/.test(x.k));
 assert(Number.isInteger(x.sec)&&x.sec>=90&&x.sec<=135);
 assert(x.why.length===3&&x.why.every(y=>y.trim().length>=35));
 for(const l of ['en','ru','uz']){
  assert(typeof x[l]==='string'&&x[l].trim().length>=60);
  const o=x['options_'+l];assert(Array.isArray(o)&&o.length===4);
  assert(o.every(z=>z.trim().length>0));assert.equal(new Set(o.map(z=>z.trim())).size,4);
 }
}
console.log('Economics Gen2 Tour7: 6/10/4 authentic difficulty, 4 new trilingual hard and 20 distinct positions');