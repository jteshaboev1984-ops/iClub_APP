#!/usr/bin/env node
'use strict';
// #574 — independent source-bound mathematical spot oracles for the remaining
// 31 editorial-equal-key Mathematics Practice candidates.
// No DB, publication or QA signoff. Never print stems/options/keys/PII.
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const ROOT=path.resolve(__dirname,'..');
const BANK=path.join(ROOT,'content/math/practice_v2');
const contract=fs.readFileSync(path.join(ROOT,'scripts/math-practice-v2-editorial-future-only-contract.cjs'),'utf8');
function parseSet(name){
  const m=contract.match(new RegExp('const '+name+' = new Set\\(\\[([^\\]]+)\\]\\)'));
  assert.ok(m,'missing source contract: '+name);
  return new Set(m[1].split(',').map(x=>Number(x.trim())));
}
const changed=parseSet('EXPECTED_IDS'),future=parseSet('FUTURE_VERSION_REQUIRED');
const editorials=[...changed].filter(id=>!future.has(id)).sort((a,b)=>a-b);
const EXPECTED=[7506,7553,7555,7556,7558,7559,7562,7565,7569,7570,
  7581,7586,7587,7590,7591,7593,7594,7597,7598,7599,7710,7714,
  7727,7754,7761,7796,7809,7818,7838,7900,7965];
assert.deepEqual(editorials,EXPECTED,'31 editorial source IDs changed: review before extending the test');
const historySensitive=new Set([7710,7714,7754]);
const inputProofs=new Map([
  [7506,()=>((5-(-2))**2)/4],          // quadratic double-root discriminant
  [7594,()=>-6],                       // inverse swaps ordered coordinates
  [7710,()=>15/10],                    // arc s=r*theta
  [7714,()=>(26-2*8)/8],               // sector perimeter
  [7727,()=>36/(0.5*(8**2-4**2))],    // annular sector
  [7754,()=>Math.sin(Math.PI/6)],      // inverse-sine datum in degrees
  [7761,()=>(3/5)/(4/5)],             // tan=sin/cos
  [7796,()=>6/(-4)],                  // geometric ratio
  [7809,()=>9/2],                     // consecutive arithmetic terms
  [7818,()=>8*((-4/8)**5)],           // geometric sixth term
  [7838,()=>6/(1-0.5)-(6+3+1.5+0.75)], // geometric tail
  [7900,()=>-(6*3)/8]                 // implicit differentiation
]);
// These textual options are selected from independent definitions / derivations,
// rather than copying the source answer key. A source wording change requires review.
const mcqProofs=new Map([
  [7553,'Each allowed x is paired with exactly one y.'],
  [7556,'f⁻¹ reverses the input-output mapping when an inverse function exists.'],
  [7558,'Two different allowed inputs give the same output.'],
  [7559,'f is a function but is not one-to-one.'],
  [7562,'1≤f(x)≤'+String((5-2)**2+1)],
  [7565,'−16≤f(x)≤'+String(-(0+1)**2+9)],
  [7569,'−1<f(x)≤'+String(5-1)],
  [7570,'f(x)≤'+String(-(3**2)+4*3+1)],
  [7581,'f(x)=4x−7'],
  [7586,'x≤2'],
  [7587,'[−3,8]'],
  [7590,'Its domain is x<5 and range y>2.'],
  [7591,'f⁻¹(−2)=6'],
  [7593,'(7,−3)'],
  [7597,'(0,5)'],
  [7598,'1≤x≤9, −2≤y≤6'],
  [7599,'(2,−1), (4,0), (7,3)'],
  [7965,'x=3−√3 and x=3+√3']
]);
function numeric(s){
  const value=Number(String(s).trim().replace(/[−–—]/g,'-').replace(',','.'));
  assert.ok(Number.isFinite(value),'invalid numeric answer example');
  return value;
}
const close=(a,b)=>Math.abs(a-b)<1e-9;
const questions=new Map();
let skillFiles=0;
for(const folder of fs.readdirSync(BANK,{withFileTypes:true}).filter(x=>x.isDirectory())){
  for(const file of fs.readdirSync(path.join(BANK,folder.name)).filter(x=>/^P1-[A-Z]{3}-\d{2}\.json$/.test(x))){
    skillFiles++;
    const data=JSON.parse(fs.readFileSync(path.join(BANK,folder.name,file),'utf8'));
    for(const q of data.questions||[]){
      const match=/^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(q.key);
      assert.ok(match,'unexpected author key');
      const id=7484+Number(match[1]);
      assert.ok(!questions.has(id),'duplicate ID');
      questions.set(id,q);
    }
  }
}
assert.equal(skillFiles,45);assert.equal(questions.size,495);
let reviewedInput=0,reviewedMCQ=0,historyCount=0;
for(const id of editorials){
  const q=questions.get(id);
  assert.ok(q,'missing editorial item');
  assert.ok(Number.isInteger(q.practice_no)&&q.practice_no>=1&&q.practice_no<=7);
  assert.ok(/^P1-[A-Z]{3}-\d{2}$/.test(q.primary_skill));
  for(const lang of ['en','ru','uz']){
    assert.ok(q.question?.[lang]?.trim() && q.explanation?.[lang]?.trim(),
      'incomplete trilingual editorial item '+id);
  }
  if(historySensitive.has(id)){
    historyCount++;
    assert.ok(inputProofs.has(id),'history-sensitive fix must not be published in place');
    assert.ok(!future.has(id),'editorial category drift: review 81 staging gate');
  }
  if(inputProofs.has(id)){
    reviewedInput++;
    assert.equal(q.qtype,'input','question type drift '+id);
    const canonical=numeric(q.answer_contract?.canonical_answer);
    const computed=inputProofs.get(id)();
    assert.ok(close(canonical,computed),'independent numeric solution mismatch at '+id);
    assert.ok(q.answer_contract?.number_only);
    assert.ok(Array.isArray(q.answer_contract.accepted_examples));
    assert.ok(Array.isArray(q.answer_contract.rejected_examples));
    for(const example of q.answer_contract.accepted_examples){
      assert.ok(close(numeric(example),computed),'accepted example invalid at '+id);
    }
    for(const example of q.answer_contract.rejected_examples){
      assert.ok(!close(numeric(example),computed),'rejected correct response at '+id);
    }
    if(!Number.isInteger(computed)){
      assert.match(q.question.en,/decimal number/i,'EN decimal instruction missing '+id);
      assert.match(q.question.ru,/десятичным числом/i,'RU decimal instruction missing '+id);
      assert.match(q.question.uz,/o‘nli son ko‘rinishida/i,'UZ decimal instruction missing '+id);
    }
    // Guard the central solved value in all three explanations, normalizing
    // mathematical minus and decimal comma without publishing any solution.
    for(const lang of ['en','ru','uz']){
      const explanation=q.explanation[lang].replace(/[−–—]/g,'-').replace(/,/g,'.');
      assert.ok(explanation.includes(String(canonical)),'worked result missing in '+lang+' at '+id);
    }
  } else {
    reviewedMCQ++;
    assert.equal(q.qtype,'mcq','question type drift '+id);
    assert.ok(Array.isArray(q.options)&&q.options.length===4);
    let derived;
    if(id===7555){
      // Exactly one mapping has three different outputs.
      const oneToOne=q.options.filter(o=>{
        const matches=[...o.text.en.matchAll(/[-−]?\d+→[-−]?\d+/g)];
        const outputs=matches.map(x=>Number(x[0].split('→')[1]));
        return matches.length===3 && new Set(outputs).size===3;
      });
      assert.equal(oneToOne.length,1,'non-unique one-to-one mapping');
      derived=oneToOne[0].key;
    } else {
      const want=mcqProofs.get(id);
      assert.ok(want,'missing independently specified MCQ oracle '+id);
      const matches=q.options.filter(o=>o.text.en===want);
      assert.equal(matches.length,1,'missing/nonunique derived MCQ answer '+id);
      derived=matches[0].key;
    }
    assert.equal(q.correct_answer,derived,'MCQ key and independent reasoning differ '+id);
    assert.equal(new Set(q.options.map(o=>o.key)).size,4);
    for(const option of q.options){
      assert.ok(['A','B','C','D'].includes(option.key));
      for(const lang of ['en','ru','uz'])assert.ok(option.text?.[lang]?.trim(),
        'missing translated option '+id);
    }
  }
}
assert.equal(reviewedInput,12);assert.equal(reviewedMCQ,19);
assert.equal(historyCount,3);
assert.equal(editorials.length,31);
// A source-bound AI/machine regression is NOT independent human RU/UZ approval.
console.log(JSON.stringify({
  scope:'Mathematics Practice editorial-equal-key source QA',
  reviewed:31,input_math_oracles:reviewedInput,mcq_derived_keys:reviewedMCQ,
  history_bearing_future_only_required:historyCount,
  full_human_ru_uz_semantic_signoff:'PENDING',
  production_writes:0,publication:false,protected_content_logged:false,
  verdict:'SOURCE_CHECK_PASS_NOT_RELEASE_GO'
}));
