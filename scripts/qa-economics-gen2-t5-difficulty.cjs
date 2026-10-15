// Read-only editorial preflight for Economics Gen2 Tour 5 Practice (A Level chapters 38–40).
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/economics-gen2-rebalance');
const batches=['t5-hard-01.json','t5-hard-02.json','t5-medium.json'];
const items=batches.flatMap(f=>JSON.parse(fs.readFileSync(path.join(root,f),'utf8')));
const mediumOld=[1,4,5,6,11,13,14,16,18,20,22,23,25,26,28,30,31,38,44,49,57,64];
const easyOld=[2,3,7,8,9,10,12,15,17,19,21,24,35,36,39,42,47,48,59,60];
const expected={easy:20,medium:30,hard:20};
assert.equal(items.length,28);
assert.equal(items.filter(x=>x.d==='hard').length,20);
assert.equal(items.filter(x=>x.d==='medium').length,8);
const numbers=items.map(x=>x.n);
assert.equal(new Set(numbers).size,28,'duplicate authorship targets');
const covered=[...numbers,...easyOld,...mediumOld];
assert.equal(covered.length,70);
assert.equal(new Set(covered).size,70,'target overlaps unchanged questions');
assert.deepEqual([...covered].sort((a,b)=>a-b),Array.from({length:70},(_,i)=>i+1));
const totals={easy:easyOld.length,medium:mediumOld.length,hard:0};
for(const x of items){
  assert.equal(x.ref,'EC9708:G2:EC9708-G2-T5-P-'+String(x.n).padStart(3,'0'));
  assert(['medium','hard'].includes(x.d));
  assert(/^[ABCD]$/.test(x.k));
  assert(Number.isInteger(x.sec)&&x.sec>=120&&x.sec<=240);
  assert(Array.isArray(x.why)&&x.why.length===3&&x.why.every(v=>v.trim().length>=35));
  for(const l of ['en','ru','uz']){
    assert(typeof x[l]==='string'&&x[l].trim().length>=60,'stem '+x.n+l);
    const opts=x['options_'+l];
    assert(Array.isArray(opts)&&opts.length===4,'four options '+x.n+l);
    assert(opts.every(v=>typeof v==='string'&&v.trim().length>0),'empty option '+x.n+l);
    assert.equal(new Set(opts.map(v=>v.trim())).size,4,'duplicate answers '+x.n+l);
  }
  if(/[a-zA-Z]{4,}/.test(x.options_en.join(' '))){
    assert.notDeepEqual(x.options_ru,x.options_en,'RU untranslated '+x.n);
    assert.notDeepEqual(x.options_uz,x.options_en,'UZ untranslated '+x.n);
  }
  totals[x.d]++;
}
assert.deepEqual(totals,expected);
console.log('T5 difficulty QA PASS: 20 easy, 30 medium, 20 hard; 28 versioned EN/RU/UZ questions');
