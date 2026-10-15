// Economics Gen2 T4 Practice editorial QA; local static data only, no network or DB.
const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'../content/economics-gen2-rebalance');
const files=['t4-hard-01.json','t4-hard-02.json','t4-medium.json'];
const rows=files.flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f),'utf8')));
const originals=[1,2,3,6,10,13,18,19,20,22,23,24,26,29,36,39,40,41,44,49,50,54];
const totals={easy:20,medium:originals.length,hard:0};
assert.equal(rows.length,28);
assert.equal(new Set(rows.map(q=>q.n)).size,28);
for(const q of rows){
  assert.equal(q.ref,'EC9708:G2:EC9708-G2-T4-P-'+String(q.n).padStart(3,'0'));
  assert(!originals.includes(q.n),'unchanged medium overwritten');
  assert(['medium','hard'].includes(q.d)&&'ABCD'.includes(q.k));
  assert(q.sec>=120&&q.sec<=240);
  assert.equal(q.why.length,3);
  for(const l of ['en','ru','uz']){
    assert(typeof q[l]==='string'&&q[l].length>=60);
    const opts=q['options_'+l];
    assert(Array.isArray(opts)&&opts.length===4);
    assert.equal(new Set(opts).size,4);
    assert(opts.every(x=>x&&x.trim()));
  }
  assert(q.why.every(x=>x.length>=25));
  totals[q.d]++;
}
assert.deepEqual(totals,{easy:20,medium:30,hard:20});
console.log('Economics T4 28 trilingual items QA OK: 20 easy/30 medium/20 hard');
