// Economics Gen2 T1 Practice editorial release gate. No database/network usage.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname,'../content/economics-gen2-rebalance');
const files = ['t1-hard-01.json','t1-hard-02.json','t1-medium-01.json','t1-medium-02.json'];
const rows = files.flatMap(f => JSON.parse(fs.readFileSync(path.join(root,f),'utf8')));
const status = { easy: 20, medium: 11, hard: 0 }; // 31 unchanged original T1 items
const originalMedium = [4,6,9,15,19,21,48,49,54,60,70];
assert.equal(originalMedium.length,11);
assert.equal(rows.length,39);
assert.equal(new Set(rows.map(q=>q.n)).size,39);
for (const q of rows) {
  assert.match(q.ref,/^EC9708:G2:EC9708-G2-T1-P-[0-9]{3}$/);
  assert.equal(Number(q.ref.slice(-3)),q.n);
  assert.ok(['medium','hard'].includes(q.d));
  assert.ok(['A','B','C','D'].includes(q.k));
  assert.ok(q.sec>=120 && q.sec<=210);
  assert.equal(q.why.length,3);
  for (const l of ['en','ru','uz']) {
    assert.ok(typeof q[l]==='string' && q[l].trim().length>=60,`${q.ref} ${l} stem`);
    assert.ok(Array.isArray(q['options_'+l]) && q['options_'+l].length===4);
    assert.equal(new Set(q['options_'+l]).size,4);
    assert.ok(q['options_'+l].every(v=>typeof v==='string' && v.trim().length>0));
  }
  assert.ok(q.why.every(v=>typeof v==='string' && v.trim().length>35));
  status[q.d]++;
}
assert.deepEqual(status,{easy:20,medium:30,hard:20});
console.log('Economics Gen2 T1 QA: 39 trilingual new versions; 20 easy / 30 medium / 20 hard; PASS');
