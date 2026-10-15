// Economics Gen2 Season 2 Tour4 static academic QA; no database writes.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/economics-gen2-tour-difficulty');
const rows=['t4-hard.json','t4-medium.json'].flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f),'utf8')));
const easy=[7,9,10,12,16,17],mediumOld=[2,4,11,13,20];
assert.equal(rows.length,9);
assert.equal(rows.filter(x=>x.d==='hard').length,4);
assert.equal(rows.filter(x=>x.d==='medium').length,5);
assert.deepEqual([...easy,...mediumOld,...rows.map(x=>x.n)].sort((a,b)=>a-b),Array.from({length:20},(_,i)=>i+1));
const count={easy:easy.length,medium:mediumOld.length,hard:0};
for(const x of rows){
 assert.equal(x.ref,'EC9708:G2:EC9708-G2-T4-T-'+String(x.n).padStart(3,'0'));
 assert(['hard','medium'].includes(x.d)&&/^[ABCD]$/.test(x.k));
 assert(Number.isInteger(x.sec)&&x.sec>=90&&x.sec<=135);
 assert(Array.isArray(x.why)&&x.why.length===3&&x.why.every(t=>t.length>=35));
 for(const l of ['en','ru','uz']){
  assert(typeof x[l]==='string'&&x[l].trim().length>=60);
  const o=x['options_'+l];assert(o.length===4&&new Set(o.map(z=>z.trim())).size===4);
  assert(o.every(z=>typeof z==='string'&&z.trim().length>0));
  if(l!=='en'&&/[A-Za-z]{4}/.test(x.options_en.join(' ')))assert.notDeepEqual(o,x.options_en);
 }
 count[x.d]++;
}
assert.deepEqual(count,{easy:6,medium:10,hard:4});
console.log('Tour4: 6 easy, 10 medium, 4 hard; 9 versioned EN/RU/UZ questions PASS');