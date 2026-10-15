// Tour 2 Economics Gen2 academic QA; read-only static checks.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/economics-gen2-tour-difficulty');
const rows=['t2-hard.json','t2-medium.json'].flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f),'utf8')));
const originalEasy=[2,3,4,6,9,17],originalMedium=[1,5,8,10,12],hard=[7,11,19,20],mediumNew=[13,14,15,16,18];
assert.deepEqual(rows.map(x=>x.n).sort((a,b)=>a-b),[...hard,...mediumNew].sort((a,b)=>a-b));
assert.equal(new Set([...originalEasy,...originalMedium,...rows.map(x=>x.n)]).size,20);
assert.deepEqual([...originalEasy,...originalMedium,...rows.map(x=>x.n)].sort((a,b)=>a-b),Array.from({length:20},(_,i)=>i+1));
const count={easy:originalEasy.length,medium:originalMedium.length,hard:0};
for(const x of rows){
 assert.equal(x.ref,'EC9708:G2:EC9708-G2-T2-T-'+String(x.n).padStart(3,'0'));
 assert(['medium','hard'].includes(x.d));
 assert(/^[ABCD]$/.test(x.k));
 assert(Number.isInteger(x.sec)&&x.sec>=90&&x.sec<=135);
 assert(Array.isArray(x.why)&&x.why.length===3&&x.why.every(y=>y.length>=35));
 for(const l of ['en','ru','uz']){
  assert(typeof x[l]==='string'&&x[l].trim().length>=60);
  const opts=x['options_'+l];assert(Array.isArray(opts)&&opts.length===4);
  assert(opts.every(v=>typeof v==='string'&&v.trim().length>0));
  assert.equal(new Set(opts.map(v=>v.trim())).size,4);
  if(l!=='en'&&/[A-Za-z]{5}/.test(x.options_en.join(' ')))assert.notDeepEqual(opts,x.options_en);
 }
 count[x.d]++;
}
assert.deepEqual(count,{easy:6,medium:10,hard:4});
console.log('Economics Gen2 Tour2: 6/10/4 original difficulty, 9 trilingual versions, 20 unique question IDs');
