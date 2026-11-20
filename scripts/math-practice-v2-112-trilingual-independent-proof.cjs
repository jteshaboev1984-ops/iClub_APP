#!/usr/bin/env node
'use strict';
// #574: independent, repeatable source-side academic checks of changed Math
// Practice questions, with explicit nine multi-step numerical proof oracles.
// This is machine/assistant QA, not a separate human expert approval.
// No question text, option text, solutions, keys or learner data printed.
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const root=path.resolve(__dirname,'../content/math/practice_v2');
const contract=fs.readFileSync(path.resolve(__dirname,'math-practice-v2-editorial-future-only-contract.cjs'),'utf8');
function idsOf(name) {
  const match=contract.match(new RegExp('const '+name+' = new Set\\(\\[([^\\]]+)\\]\\)'));
  assert.ok(match,'missing authoritative changed-ID manifest');
  return new Set(match[1].split(',').map(v=>+v.trim()));
}
const changed=idsOf('EXPECTED_IDS');
const newIds=idsOf('FUTURE_VERSION_REQUIRED');
const nine=idsOf('HARD_TRANSFER_REAUTHORED');
assert.equal(changed.size,112);assert.equal(newIds.size,81);assert.equal(nine.size,9);
const files=fs.readdirSync(root,{withFileTypes:true})
  .filter(x=>x.isDirectory()).flatMap(folder=>
    fs.readdirSync(path.join(root,folder.name))
      .filter(x=>/^P1-[A-Z]{3}-\d{2}\.json$/.test(x))
      .map(file=>path.join(root,folder.name,file)));
assert.equal(files.length,45);
const items=new Map();
for(const file of files){
  for(const q of JSON.parse(fs.readFileSync(file,'utf8')).questions||[]){
    const m=/^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(q.key);
    assert.ok(m,'author ID drift');
    const id=7484+Number(m[1]);
    assert.ok(!items.has(id),'author ID repeated');
    items.set(id,q);
  }
}
assert.equal(items.size,495);
const expectedNumerical=new Map([
  [7511,()=>{const b=-2*(1/2),c=-12;return (1+Math.sqrt(b*b-4*c))/2;}],
  [7585,()=>{const slope=(0-(-1))/(6-2);return (5-3)/slope;}],
  [7692,()=>{const xc=1,yc=-1,r=Math.sqrt(5),denom=Math.sqrt(2*2+1);return (r*denom-(2*xc-yc))+(-r*denom-(2*xc-yc));}],
  [7723,()=>{const area=5,theta=2,deltaRadius=1;const sumRadius=2*area/(theta*deltaRadius);return theta*sumRadius+2*deltaRadius;}],
  [7769,()=>new Set([60,180,120,240]).size],
  [7823,()=>{const r=Math.sqrt(54/6);return 2+6/r;}],
  [7835,()=>{const a=16,b=-16,c=3;const roots=[(-b+Math.sqrt(b*b-4*a*c))/(2*a),(-b-Math.sqrt(b*b-4*a*c))/(2*a)];return roots.find(x=>x>0&&x<.5);}],
  [7908,()=>18/(2*3)],
  [7974,()=>81/27]
]);
assert.deepEqual([...expectedNumerical.keys()].sort((a,b)=>a-b),[...nine].sort((a,b)=>a-b));
const lexical=new Map([
  [7511,{en:/vertex|x-axis/i,ru:/вершин|абсцисс/i,uz:/uchin|o‘qi/i}],
  [7585,{en:/inverse|one-to-one/i,ru:/обратн|взаимно/i,uz:/teskari/i}],
  [7692,{en:/tangent/i,ru:/каса/i,uz:/urin/i}],
  [7723,{en:/both arcs/i,ru:/обе дуги/i,uz:/Ikkala yoy/i}],
  [7769,{en:/distinct solutions/i,ru:/различных решений/i,uz:/turli yechimi/i}],
  [7823,{en:/positive/i,ru:/положител/i,uz:/musbat/i}],
  [7835,{en:/convergent/i,ru:/сходящ/i,uz:/yaqinlashuvchi/i}],
  [7908,{en:/maximises/i,ru:/максимальн/i,uz:/eng katta/i}],
  [7974,{en:/volume/i,ru:/объём/i,uz:/hajm/i}]
]);
const normalize=s=>String(s||'').normalize('NFKC').replace(/[−–—]/g,'-').replace(/,/g,'.');
// A conservative numeric semantic comparator. A mismatch creates an explicit
// review finding, not an automatic translated answer substitution.
const mathNumbers=s=>(normalize(s).match(/(?<![\p{L}\d])[+-]?\d+(?:\.\d+)?/gu)||[]).sort().join('|');
const findings=[];
let locales=0,mcq=0,input=0,explained=0,checkedNine=0;
for(const id of [...changed].sort((a,b)=>a-b)){
  const q=items.get(id);
  assert.ok(q,'missing changed question '+id);
  assert.ok(newIds.has(id)||!newIds.has(id));
  assert.ok(q.source_ref && q.primary_skill && q.practice_no>0);
  for(const lang of ['en','ru','uz']){
    assert.ok(q.question?.[lang]?.trim() && q.explanation?.[lang]?.trim(),
      'missing localized stem or proof '+id+' '+lang);
    locales++;
  }
  if(q.qtype==='mcq'){
    mcq++;
    assert.equal(q.options?.length,4,'MCQ option count '+id);
    assert.ok(q.options.some(o=>o.key===q.correct_answer),'MCQ answer key unresolved '+id);
    for(const option of q.options)for(const lang of ['en','ru','uz'])
      assert.ok(option.text?.[lang]?.trim(),'untranslated MCQ option '+id+' '+lang);
  }else{
    assert.equal(q.qtype,'input','noncanonical item type '+id);
    input++;
    assert.ok(q.answer_contract?.canonical_answer,'missing governed input answer '+id);
  }
  for(const lang of ['ru','uz']){
    if(mathNumbers(q.question.en)!==mathNumbers(q.question[lang]))
      findings.push({id,lang,field:'question_math_tokens'});
    if(mathNumbers(q.explanation.en)!==mathNumbers(q.explanation[lang]))
      findings.push({id,lang,field:'explanation_math_tokens'});
  }
  explained++;
  if(!nine.has(id))continue;
  checkedNine++;
  const proof=expectedNumerical.get(id)();
  const authored=Number(normalize(q.answer_contract?.canonical_answer));
  assert.ok(Number.isFinite(proof) && Number.isFinite(authored) &&
    Math.abs(proof-authored)<1e-9,'independent higher-reasoning answer failed '+id);
  for(const lang of ['en','ru','uz']){
    assert.match(q.question[lang],lexical.get(id)[lang],
      'missing key semantic condition '+id+' '+lang);
    assert.ok(normalize(q.explanation[lang]).includes(String(authored)),
      'localized worked result differs '+id+' '+lang);
  }
}
assert.equal(mcq+input,112);
assert.equal(locales,336);
assert.equal(checkedNine,9);
assert.equal(explained,112);
// Report precisely which source items need manual semantic reconciliation.
// Treat numeric lexical differences as review prompts rather than silently
// declaring 112 independent professional approvals.
const unique=[...new Set(findings.map(x=>x.id+':'+x.lang+':'+x.field))];
console.log(JSON.stringify({scope:112,trilingual_sections:locales,
  math_reproofs:9,conserved_previous_edits:103,
  mcq,input,locale_math_token_review_findings:unique.length,
  review_identifiers:unique.slice(0,60),
  verified_human_expert_signoff:false,qa_status:unique.length?'NEEDS_TARGETED_REVIEW':'SOURCE_RULES_PASS',
  production_writes:0,protected_content_printed:false}));
if(unique.length){
  process.exitCode=2;
}
