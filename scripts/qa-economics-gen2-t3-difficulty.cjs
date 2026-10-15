// Economics Gen2 Practice 3: editorial checks, no database or production writes.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../content/economics-gen2-rebalance');
const rows = ['t3-hard-01.json','t3-hard-02.json','t3-medium.json'].flatMap(f => JSON.parse(fs.readFileSync(path.join(root, f), 'utf8')));
const originalMedium = [7,9,11,12,14,16,18,19,21,24,25,26,33,34,36,37,40,46,49,56,61,70];
const expected = { easy:20, medium:30, hard:20 };
const count = { easy:20, medium:originalMedium.length, hard:0 };
assert.equal(rows.length, 28, 'expected 28 versioned questions');
assert.equal(new Set(rows.map(q=>q.n)).size, rows.length, 'duplicate original question number');
assert.equal(rows.filter(q=>q.d==='hard').length, 20);
assert.equal(rows.filter(q=>q.d==='medium').length, 8);
for(const q of rows){
  assert.equal(q.ref, 'EC9708:G2:EC9708-G2-T3-P-'+String(q.n).padStart(3,'0'));
  assert(!originalMedium.includes(q.n),'overlapping old medium #'+q.n);
  assert(['medium','hard'].includes(q.d),'invalid level');
  assert(/^[ABCD]$/.test(q.k),'invalid key');
  assert(q.sec>=120 && q.sec<=240,'individual timing outside editorial window');
  for(const lang of ['en','ru','uz']){
    assert(typeof q[lang]==='string' && q[lang].trim().length>=60, 'missing stem '+q.ref+lang);
    const options=q['options_'+lang];
    assert(Array.isArray(options) && options.length===4, 'options '+q.ref+lang);
    assert(options.every(v=>typeof v==='string' && v.trim()),'empty option '+q.ref+lang);
    assert.equal(new Set(options).size, 4, 'duplicate options '+q.ref+lang);
  }
  assert(Array.isArray(q.why) && q.why.length===3 && q.why.every(t=>t.length>=30),'missing explanation');
  if(/[A-Za-z]{5}/.test(q.options_en.join(' '))) {
    assert.notDeepEqual(q.options_en,q.options_ru,'RU untranslated '+q.ref);
    assert.notDeepEqual(q.options_en,q.options_uz,'UZ untranslated '+q.ref);
  }
  count[q.d]++;
}
assert.deepEqual(count,expected,'T3 expected 20/30/20');
console.log('Economics T3 editorial QA PASS: 28 original versioned questions EN/RU/UZ; 20/30/20');
