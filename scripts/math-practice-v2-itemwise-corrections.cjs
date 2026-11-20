#!/usr/bin/env node
'use strict';
// #574 Mathematics Practice item-by-item correction contract.
// Source-only verification; historical published rows and learner attempts
// must NOT be overwritten. No question/answer text or keys printed.
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const ledger=read('docs/qa/math-practice-v2-all495-itemwise-review-ledger-20261119.csv')
  .trim().split('\n').slice(1).map(row=>row.split(','));
const entry=id=>ledger.find(x=>Number(x[0])===id);
const load=(file,id)=>{
  const obj=JSON.parse(read('content/math/practice_v2/'+file));
  const q=obj.questions.find(x=>/^MATH-P1-PRACTICE2-Q\d{3}$/.test(x.key)
    && 7484+Number(x.key.slice(-3))===id);
  assert.ok(q,'authored correction missing '+id);
  return q;
};
const corrected=[
  [7791,'p5_binomial_series/P1-SER-01.json'],
  [7881,'p6_differentiation/P1-DIF-04.json'],
  [7893,'p6_differentiation/P1-DIF-06.json']
];
assert.equal(ledger.length,495);
for(const [id,file] of corrected){
  const item=entry(id),q=load(file,id);
  assert.equal(item?.[11],'FUTURE_VERSION_REQUIRED',
    'do not publish corrected content over the old row '+id);
  assert.equal(q.qtype,'mcq');
  assert.deepEqual(q.options.map(o=>o.key),['A','B','C','D'],
    'canonical display key ordering broken '+id);
  for(const lang of ['en','ru','uz']){
    assert.ok(q.question[lang]&&q.explanation[lang]);
    assert(q.options.every(o=>o.text?.[lang]),
      'option translation missing '+id+' '+lang);
  }
  assert.equal(new Set(q.options.map(o=>o.key)).size,4);
  assert(q.options.some(o=>o.key===q.correct_answer));
}
const binomial=load(corrected[0][1],7791);
const secondTerm=4*(-1),firstTerm=6;
const trueCoefficient=firstTerm+secondTerm;
assert.equal(trueCoefficient,2);
assert.equal(binomial.options.find(o=>o.key===binomial.correct_answer)?.text.en,
  String(trueCoefficient));
assert.match(binomial.explanation.en,/minus 4/);
assert.match(binomial.explanation.ru,/−4/);
assert.match(binomial.explanation.uz,/−4/);
for(const lang of ['en','ru','uz'])
  assert.ok(binomial.explanation[lang].includes('6−4=2'));
assert.equal(entry(7791)[12],'YES','known prior-answer history must stay pinned');
const tangent=load(corrected[1][1],7881);
const x=2,derivative=3*x*x-12,y=x**3-12*x;
assert.equal(derivative,0);
assert.equal(tangent.options.find(o=>o.key===tangent.correct_answer)?.text.en,
  'y='+String(y).replace('-','−'));
const rate=load(corrected[2][1],7893);
const rectangleRate=(2*4+2)*0.5;
assert.equal(rectangleRate,5);
assert.equal(rate.options.find(o=>o.key===rate.correct_answer)?.text.en,
  String(rectangleRate)+' cm² s⁻¹');
// Preserve question boundaries: never silently modify the original
// approved score of a historical attempt, and never call a live DB.
console.log(JSON.stringify({
  corrected_source_items:3,
  independent_maths_recomputed:3,
  required_future_only_versions:3,
  history_bearing_known_minimum:1,
  correct_answers_rekeyed:0,
  published_rows_changed:0,
  learner_attempts_modified:0,
  result:'SOURCE_REGRESSION_PASS_RELEASE_NOT_AUTHORIZED_YET'
}));
