// Academic and localization QA for Gen2 Economics Season2 Tour3. No DB writes.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/economics-gen2-tour-difficulty');
const rows=['t3-hard.json','t3-medium.json'].flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f),'utf8')));
const easy=[3,6,7,11,13,17],mediumOld=[1,2,4,5,12,14,20];
assert.equal(rows.length,7);
assert.equal(rows.filter(x=>x.d==='hard').length,4);
assert.equal(rows.filter(x=>x.d==='medium').length,3);
assert.deepEqual([...easy,...mediumOld,...rows.map(x=>x.n)].sort((a,b)=>a-b),Array.from({length:20},(_,i)=>i+1));
const counts={easy:easy.length,medium:mediumOld.length,hard:0};
for(const x of rows){
 assert.equal(x.ref,'EC9708:G2:EC9708-G2-T3-T-'+String(x.n).padStart(3,'0'));
 assert(['medium','hard'].includes(x.d)&&/^[ABCD]$/.test(x.k));
 assert(Number.isInteger(x.sec)&&x.sec>=90&&x.sec<=135);
 assert(x.why.length===3&&x.why.every(w=>w.length>=35));
 for(const l of ['en','ru','uz']){
  assert(typeof x[l]==='string'&&x[l].trim().length>60);
  const o=x['options_'+l];assert(o.length===4&&o.every(s=>s.trim().length));
  assert.equal(new Set(o.map(s=>s.trim())).size,4);
  if(l!=='en'&&/[A-Za-z]{4}/.test(x.options_en.join(' ')))assert.notDeepEqual(o,x.options_en);
 }
 counts[x.d]++;
}
assert.deepEqual(counts,{easy:6,medium:10,hard:4});
console.log('Economics Tour3: 20 unique positions, 6/10/4, 7 authored versions EN/RU/UZ PASS');