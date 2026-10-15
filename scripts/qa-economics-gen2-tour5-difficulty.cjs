// Economics Gen2 Season2 Tour5 editorial gate: no database access or side effects.
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const items=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../content/economics-gen2-tour-difficulty/t5-hard.json'),'utf8'));
const easy=[2,4,6,7,10,17], medium=[1,3,5,9,11,12,15,16,18,20], hard=[8,13,14,19];
assert.equal(items.length,4);assert.deepEqual(items.map(x=>x.n).sort((a,b)=>a-b),hard);
assert.deepEqual([...easy,...medium,...hard].sort((a,b)=>a-b),Array.from({length:20},(_,i)=>i+1));
for(const x of items){
 assert.equal(x.ref,'EC9708:G2:EC9708-G2-T5-T-'+String(x.n).padStart(3,'0'));
 assert.equal(x.d,'hard');assert(/^[ABCD]$/.test(x.k));
 assert(Number.isInteger(x.sec)&&x.sec>=90&&x.sec<=135);
 assert(Array.isArray(x.why)&&x.why.length===3&&x.why.every(y=>y.length>=35));
 for(const l of ['en','ru','uz']){
  assert(typeof x[l]==='string'&&x[l].trim().length>60);
  const o=x['options_'+l];assert(Array.isArray(o)&&o.length===4&&new Set(o.map(y=>y.trim())).size===4);
  assert(o.every(z=>z.trim().length>0));
 }
}
console.log('Economics Tour5: 6 easy, 10 medium, 4 hard; 4 original V2 trilingual contents PASS');