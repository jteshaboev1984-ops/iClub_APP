// Economics Gen2 T7 Practice: static editorial QA, no network or database mutations.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/economics-gen2-rebalance');
const rows=['t7-hard-01.json','t7-hard-02.json','t7-medium.json'].flatMap(n=>JSON.parse(fs.readFileSync(path.join(root,n),'utf8')));
const easyOld=[1,2,4,5,7,13,18,22,25,28,30,37,38,42,49,52,53,59,60,70];
const mediumOld=[3,11,15,16,26,29,34,44,46,48,50,51,54,55,56,57,58,64,66,67,68,69];
const historyBearing=[22,29,38,44,46,48,49,53,58,67];
const ids=rows.map(x=>x.n);
assert.equal(rows.length,28);
assert.equal(rows.filter(x=>x.d==='hard').length,20);
assert.equal(rows.filter(x=>x.d==='medium').length,8);
assert.equal(new Set(ids).size,28,'duplicate replacement target');
assert(ids.every(n=>!historyBearing.includes(n)),'do not replace history-bearing originals');
assert.deepEqual([...ids,...easyOld,...mediumOld].sort((a,b)=>a-b),Array.from({length:70},(_,i)=>i+1));
const mix={easy:easyOld.length,medium:mediumOld.length,hard:0};
for(const x of rows){
  assert.equal(x.ref,'EC9708:G2:EC9708-G2-T7-P-'+String(x.n).padStart(3,'0'));
  assert(['medium','hard'].includes(x.d));
  assert(/^[ABCD]$/.test(x.k));
  assert(Number.isInteger(x.sec)&&x.sec>=120&&x.sec<=240);
  assert(Array.isArray(x.why)&&x.why.length===3&&x.why.every(t=>t.trim().length>=30));
  for(const l of ['en','ru','uz']){
    assert(typeof x[l]==='string'&&x[l].trim().length>=60);
    const opts=x['options_'+l];assert(Array.isArray(opts)&&opts.length===4);
    assert.equal(new Set(opts.map(v=>v.trim())).size,4);
    assert(opts.every(v=>typeof v==='string'&&v.trim().length>0));
    if(l!=='en'&&/[A-Za-z]{5}/.test(x.options_en.join(' ')))assert.notDeepEqual(opts,x.options_en);
  }
  mix[x.d]++;
}
assert.deepEqual(mix,{easy:20,medium:30,hard:20});
console.log('T7 editorial QA PASS: 28 original trilingual versions, 20/30/20, historical P048 preserved');
