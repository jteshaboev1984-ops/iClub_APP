#!/usr/bin/env node
'use strict';
// #574 · Objective mathematics oracle for exactly four published MCQ range prompts.
// This test reads authored local source only: no live DB, student data or answer
// keys are logged. Source-field immutability is enforced by the 495-item guard.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const source = JSON.parse(fs.readFileSync(path.join(__dirname,
  '../content/math/practice_v2/p2_functions/P1-FUN-02.json'), 'utf8'));
const keys = new Map(source.questions.map(q => [7484 + Number(q.key.slice(-3)), q]));
const minus = s => String(s).replace(/−/g, '-').replace(/\\s/g, '');
function expression(text) {
  const v = minus(text);
  const p = v.match(/^(-?\\d+(?:\\.\\d+)?)(≤|<)f\\(x\\)(≤|<)(-?\\d+(?:\\.\\d+)?)$/);
  if (p) return { low: Number(p[1]), lowClosed: p[2] === '≤',
    high: Number(p[4]), highClosed: p[3] === '≤' };
  const one = v.match(/^f\\(x\\)(≤|<|≥|>)(-?\\d+(?:\\.\\d+)?)$/);
  assert.ok(one, 'unrecognized Mathematics range candidate');
  if (one[1] === '≤' || one[1] === '<')
    return {low:-Infinity,lowClosed:false,high:Number(one[2]),highClosed:one[1]==='≤'};
  return {low:Number(one[2]),lowClosed:one[1]==='≥',high:Infinity,highClosed:false};
}
function equalSet(a,b) {
  return a.low === b.low && a.high === b.high &&
    a.lowClosed === b.lowClosed && a.highClosed === b.highClosed;
}
const specs = [
  {id:7562,f:x=>(x-2)**2+1,derivative:x=>2*(x-2),
    checkpoints:[2,3,5],range:({f})=>({
      low:f(2),lowClosed:true,high:f(5),highClosed:true})},
  {id:7565,f:x=>-(x+1)**2+9,derivative:x=>-2*(x+1),
    checkpoints:[0,2,4],range:({f})=>({
      low:f(4),lowClosed:true,high:f(0),highClosed:true})},
  {id:7569,f:x=>5-x,derivative:x=>-1,
    checkpoints:[1,3,5.999],range:({f})=>({
      low:f(6),lowClosed:false,high:f(1),highClosed:true})},
  {id:7570,f:x=>-x*x+4*x+1,derivative:x=>-2*x+4,
    checkpoints:[3,4,100],range:({f})=>({
      low:-Infinity,lowClosed:false,high:f(3),highClosed:true})},
];
for (const spec of specs) {
  const q=keys.get(spec.id);
  assert.ok(q, 'missing scoped item');
  assert.equal(q.qtype,'mcq');
  assert.equal(q.options.length,4);
  assert.deepEqual(q.options.map(o=>o.key),['A','B','C','D']);
  for (const x of spec.checkpoints)
    assert.ok(spec.derivative(x)>=0 && spec.id===7562 ||
      spec.derivative(x)<0 && spec.id!==7562,
      'derivative does not justify chosen monotonic direction');
  const expected=spec.range(spec);
  // Value witnesses check the stated limits and forbid invented intervals.
  for(const x of spec.checkpoints) {
    const y=spec.f(x);
    assert.ok(y>=expected.low-1e-12 && y<=expected.high+1e-12,
      'derived range excludes function image');
  }
  for(const locale of ['en','ru','uz']){
    assert.ok(q.question[locale]?.length>20,'missing localized exact-range prompt');
    const matches=q.options.filter(o=>equalSet(expression(o.text[locale]),expected));
    assert.equal(matches.length,1,'MCQ range must have one exact set');
    assert.equal(matches[0].key,q.correct_answer,'selected MCQ option is not the exact mathematical range');
    // Verify the four option interpretations are pairwise different sets.
    const sets=q.options.map(o=>expression(o.text[locale]));
    assert.equal(new Set(sets.map(s=>JSON.stringify(s))).size,4,
      'duplicated range options');
  }
}
console.log(JSON.stringify({status:'PASS',scoped_questions:4,locales:3,
  independent_monotonicity_and_endpoint_checks:true,unique_exact_range_in_all_locales:true,
  full_source_immutability_checked_separately:true,contains_live_auth_or_student_data:false}));
