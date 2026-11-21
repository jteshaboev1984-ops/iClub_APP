#!/usr/bin/env node
'use strict';
// #574: 30 previously published Practice corrections + scoped Q070 set-equivalence fix.
// Check all 495 authored questions vs real original main; fail on any other
// key/text/locale/difficulty change. No protected solution printed in CI.
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const {execFileSync}=require('node:child_process');
const root=path.resolve(__dirname,'..');
const bank=path.join(root,'content/math/practice_v2');
const baseline='296bf21df09a808152b4ae4e153ddcec8aec85cd';
const expected=new Map([
 [7553,['question','explanation']],[7554,['options']],[7795,['question','explanation']],
 [7714,['question']],[7727,['question']],[7796,['question']],
 [7818,['question']],[7829,['question']],[7838,['question']],
 [7894,['question']],[7900,['question']],
 [7506,['question']],[7754,['question']],[7761,['question']],
 [7809,['question']],[7835,['question']],
 [7573,['options']],[7686,['question']],[7710,['question']],
 [7624,['options','correct_answer']],[7662,['options','correct_answer']],
 [7724,['question']],[7791,['explanation']],
 [7797,['options','correct_answer']],[7881,['options','correct_answer']],
 [7884,['question']],[7965,['explanation']],
 [7893,['options']],[7926,['options','correct_answer']],
 [7937,['options','correct_answer']],[7970,['question','options','correct_answer']]
]);
const rekey=new Set([7624,7662,7797,7881,7926,7937,7970]);
const extraDecimal=new Map([
 [7714,()=>(26-2*8)/8],
 [7727,()=>36/(0.5*(8**2-4**2))],
 [7796,()=>6/(-4)],
 [7818,()=>8*((-4/8)**5)],
 [7829,()=>5000*(0.9**4)],
 [7838,()=>6*(0.5**4)/(1-0.5)],
 [7894,()=>2*4*(-0.2)],
 [7900,()=>-(6*3)/8],
 [7506,()=>{const roots=[-2,5],p=-(roots[0]+roots[1]),q=roots[0]*roots[1];return (p*p-4*q)/4;}],
 [7754,()=>Math.sin(Math.PI/6)],
 [7761,()=>(3/5)/(4/5)],
 [7809,()=>(6+3)/2],
 [7835,()=>1-5/(20/3)]
]);
const decimalEnding={en:'Give your answer as a decimal number.',
 ru:'Ответ запишите десятичным числом.',
 uz:'Javobni o‘nli son ko‘rinishida kiriting.'};
const stable=x=>Array.isArray(x)?x.map(stable):x&&typeof x==='object'
 ?Object.fromEntries(Object.keys(x).sort().map(k=>[k,stable(x[k])])):x;
const eq=(a,b)=>JSON.stringify(stable(a))===JSON.stringify(stable(b));
const prev=file=>JSON.parse(execFileSync('git',['show',baseline+':'+file],{
 cwd:root,encoding:'utf8',maxBuffer:7*1024*1024}));
const preDiagnosticRelease='4082f2da036628efbb4c3c89244eb388b93de53c';
const terms21=new Set([7555,7556,7558,7559,7581,7586,7587,7590,7591,7593,7594,7597,7598,7599]);
const diag21=new Map(Object.entries({"7554":{"B":"FUN01_RANGE_EXTRA","D":"FUN01_DOMAIN_EXTRA"},"7586":{"A":"FUN04_MONOTONIC_DIRECTION"},"7797":{"B":"SER02_EQUAL_DIFFS_AP","C":"SER02_INCREASE_NOT_GUARANTEED"},"7798":{"B":"SER02_AP_NOT_GP"},"7800":{"A":"SER02_CONSTANT_BOTH","B":"SER02_CONSTANT_BOTH"},"7801":{"A":"SER02_AP_NOT_NEITHER","C":"SER02_GP_NOT_NEITHER"},"7958":{"C":"INT04_MISSED_BELOW_AXIS"},"7966":{"B":"INT04_ZERO_SIGNED_NOT_AREA"}}).map(([id,v])=>[Number(id),v]));
const newCatalog21={"p2_functions":["FUN01_RANGE_EXTRA","FUN01_DOMAIN_EXTRA","FUN04_MONOTONIC_DIRECTION"],"p5_binomial_series":["SER02_EQUAL_DIFFS_AP","SER02_INCREASE_NOT_GUARANTEED","SER02_AP_NOT_GP","SER02_CONSTANT_BOTH","SER02_AP_NOT_NEITHER","SER02_GP_NOT_NEITHER"],"p7_integration":["INT04_MISSED_BELOW_AXIS","INT04_ZERO_SIGNED_NOT_AREA"]};
const diagTrig23=new Map(Object.entries({
 "7749":{"A":"TRI03_IN_RANGE_WRONG_SIGN"},
 "7750":{"B":"TRI03_IN_RANGE_WRONG_SIGN"},
 "7751":{"A":"TRI03_PRINCIPAL_INTERVAL_DEFINITION","B":"TRI03_PRINCIPAL_INTERVAL_DEFINITION","C":"TRI03_PRINCIPAL_INTERVAL_DEFINITION"},
 "7753":{"A":"TRI03_INPUT_VALID"},
 "7766":{"A":"TRI05_INVALID_LISTED_ANGLE","C":"TRI05_INVALID_LISTED_ANGLE"},
 "7767":{"A":"TRI05_INVALID_LISTED_ANGLE","C":"TRI05_INVALID_LISTED_ANGLE"},
 "7768":{"A":"TRI05_INVALID_LISTED_ANGLE","B":"TRI05_INVALID_LISTED_ANGLE"},
 "7770":{"B":"TRI05_INVALID_LISTED_ANGLE","C":"TRI05_INVALID_LISTED_ANGLE"},
 "7771":{"D":"TRI05_INVALID_LISTED_ANGLE"},
 "7772":{"B":"TRI05_INVALID_LISTED_ANGLE","C":"TRI05_INVALID_LISTED_ANGLE"},
 "7773":{"C":"TRI05_INVALID_LISTED_ANGLE"},
 "7774":{"A":"TRI05_INVALID_LISTED_ANGLE","B":"TRI05_INVALID_LISTED_ANGLE"},
 "7776":{"C":"TRI05_INVALID_LISTED_ANGLE"},
 "7777":{"A":"TRI05_INVALID_LISTED_ANGLE","C":"TRI05_INVALID_LISTED_ANGLE"}
}).map(([id,changes])=>[Number(id),changes]));
const extraCatalogTrig23=["TRI03_IN_RANGE_WRONG_SIGN","TRI03_PRINCIPAL_INTERVAL_DEFINITION","TRI03_INPUT_VALID","TRI05_INVALID_LISTED_ANGLE"];
const diagIntegral9=new Map(Object.entries({
 "7942":{"B":"INT03_NOT_BOUNDS_REVERSAL","C":"INT03_NOT_BOUNDS_REVERSAL"},
 "7943":{"C":"INT03_NOT_BOUNDS_REVERSAL"},
 "7945":{"A":"INT03_NOT_BOUNDS_REVERSAL","B":"INT03_NOT_BOUNDS_REVERSAL","D":"INT03_NOT_BOUNDS_REVERSAL"},
 "7947":{"C":"INT03_NOT_BOUNDS_REVERSAL"},
 "7950":{"A":"INT03_NOT_BOUNDS_REVERSAL"},
 "7892":{"D":"DIF05_NO_STATIONARY_WHEN_NEGATIVE"}
}).map(([id,changes])=>[Number(id),changes]));
const extraCatalogIntegral9={"p7_integration":["INT03_NOT_BOUNDS_REVERSAL"],"p6_differentiation":["DIF05_NO_STATIONARY_WHEN_NEGATIVE"]};
const diagNext8=new Map(Object.entries({
 "7892":{"C":"DIF05_VALUE_NOT_SLOPE_SIGN"},
 "7903":{"D":"DIF07_POINT_IS_STATIONARY"},
 "7907":{"D":"DIF07_POINT_IS_STATIONARY"},
 "7909":{"C":"DIF07_POINT_IS_STATIONARY"},
 "7955":{"C":"INT04_NOT_ORDER_REVERSAL","D":"INT04_NOT_ORDER_REVERSAL"},
 "7956":{"A":"INT04_NOT_ORDER_REVERSAL","B":"INT04_NOT_ORDER_REVERSAL"}
}).map(([id,changes])=>[Number(id),changes]));
const extraCatalogNext8={"p6_differentiation":["DIF05_VALUE_NOT_SLOPE_SIGN","DIF07_POINT_IS_STATIONARY"],"p7_integration":["INT04_NOT_ORDER_REVERSAL"]};
const previousRelease=file=>JSON.parse(execFileSync('git',['show',preDiagnosticRelease+':'+file],{
 cwd:root,encoding:'utf8',maxBuffer:7*1024*1024}));
let checked21=new Set(),seenUz21=0,seenDiag21=0;
let checkedTrig23=new Set(),seenDiagTrig23=0;
let checkedIntegral9=new Set(),seenDiagIntegral9=0;
let checkedNext8=new Set(),seenDiagNext8=0;
let items=0,mcq=0,input=0,changed=0;
const groups=new Map(),found=new Set();
const languages=['en','ru','uz'],letters=['A','B','C','D'];
const folderList=fs.readdirSync(bank,{withFileTypes:true}).filter(x=>x.isDirectory());
let nFiles=0;
for(const folder of folderList){
 for(const name of fs.readdirSync(path.join(bank,folder.name))
   .filter(x=>/^P1-[A-Z]{3}-\d{2}\.json$/.test(x))){
  nFiles++;
  const relative='content/math/practice_v2/'+folder.name+'/'+name;
  const original=prev(relative);
  const now=JSON.parse(fs.readFileSync(path.join(root,relative),'utf8'));
  const previousNow=previousRelease(relative);
  assert.equal(previousNow.questions.length,now.questions.length);
  assert.equal(original.skill,now.skill);
  assert.equal(original.questions.length,now.questions.length);
  assert.ok(eq({...original,questions:[]},{...now,questions:[]}));
  for(let i=0;i<now.questions.length;i++){
   const before=original.questions[i],q=previousNow.questions[i],actual=now.questions[i];
   const id21=7484+Number(q.key.slice(-3));
   const expectedNow=JSON.parse(JSON.stringify(q));
   if(terms21.has(id21)){
    for(const field of [expectedNow.question,expectedNow.explanation,...(expectedNow.options||[]).map(o=>o.text)]){
     if(!field?.uz)continue;
     seenUz21+=(field.uz.match(/one-to-one/gi)||[]).length;
     field.uz=field.uz.replace(/one-to-one/gi,'injektiv (birga-bir)');
    }
    checked21.add(id21);
   }
   if(diag21.has(id21)){
    for(const [letter,code] of Object.entries(diag21.get(id21))){
     const option=expectedNow.options.find(o=>o.key===letter);
     assert.ok(option&&option.key!==expectedNow.correct_answer);
     option.diagnostic_code=code;seenDiag21++;
    }
    checked21.add(id21);
   }
   if(diagTrig23.has(id21)){
    for(const [letter,code] of Object.entries(diagTrig23.get(id21))){
     const option=expectedNow.options?.find(o=>o.key===letter);
     assert.ok(option&&option.key!==expectedNow.correct_answer,'invalid changed wrong-choice target '+id21);
     assert.equal(option.diagnostic_code,
       id21<=7753?'TRI03_PRINCIPAL_RANGE':'TRI05_REFERENCE_SOLUTIONS',
       'unexpected pre-existing trigonometric diagnostic');
     option.diagnostic_code=code;
     seenDiagTrig23++;
    }
    checkedTrig23.add(id21);
   }
   if(diagIntegral9.has(id21)){
    for(const [letter,code] of Object.entries(diagIntegral9.get(id21))){
     const opt=expectedNow.options?.find(o=>o.key===letter);
     assert.ok(opt&&letter!==expectedNow.correct_answer);
     assert.equal(opt.diagnostic_code,id21===7892?'DIF05_ROOTS_ONLY':'INT03_UPPER_MINUS_LOWER');
     opt.diagnostic_code=code;seenDiagIntegral9++;
    }
    checkedIntegral9.add(id21);
   }
   if(diagNext8.has(id21)){
    for(const [letter,code] of Object.entries(diagNext8.get(id21))){
     const opt=expectedNow.options?.find(o=>o.key===letter);
     assert.ok(opt&&letter!==expectedNow.correct_answer);
     const oldCode=id21===7892?'DIF05_SIGN_INTERVAL':
      [7903,7907,7909].includes(id21)?'DIF07_STATIONARY_CONDITION':'INT04_TOP_BOTTOM';
     assert.equal(opt.diagnostic_code,oldCode,'new eight feedback preimage mismatch');
     opt.diagnostic_code=code;
     seenDiagNext8++;
    }
    checkedNext8.add(id21);
   }
   assert.ok(eq(actual,expectedNow),'consolidated approved released+next8 scope drift '+id21);
   assert.equal(before.key,q.key,'candidate order changed');
   const id=7484+Number(q.key.slice(-3));
   items++;
   const allowed=expected.get(id);
   if(!allowed)assert.ok(eq(before,q),'unrelated authored item mutated '+id);
   else{
    changed++;found.add(id);
    const fields=Object.keys(q).filter(k=>!eq(before[k],q[k])).sort();
    assert.deepEqual(fields,allowed.slice().sort(),
      'micro-release includes unsanctioned field change '+id);
    assert.equal(before.difficulty,q.difficulty,'release not authorized to regrade difficulty');
    assert.equal(before.qtype,q.qtype);
    assert.equal(before.primary_skill,q.primary_skill);
    if(q.qtype==='mcq'){
     assert.equal(q.options.length,4);
     const oldCorrect=before.options.find(o=>o.key===before.correct_answer);
     const newCorrect=q.options.find(o=>o.key===q.correct_answer);
     assert.ok(oldCorrect&&newCorrect,'missing correct keyed option');
     for(const lang of languages)assert.equal(newCorrect.text[lang],oldCorrect.text[lang],
       'correct mathematical option changed '+id+' '+lang);
     const semantics=o=>stable({text:o.text,diagnostic_code:o.diagnostic_code});
     const pool=arr=>arr.map(o=>JSON.stringify(semantics(o))).sort();
     if(id!==7573&&id!==7554)assert.deepEqual(pool(q.options),pool(before.options),
       'distractor or diagnostic semantics changed');
     if(rekey.has(id))assert.notEqual(before.correct_answer,q.correct_answer);
     if(id===7893)assert.equal(before.correct_answer,q.correct_answer);
    }
    if(extraDecimal.has(id)){
     assert.equal(q.qtype,'input','new decimal format must be numeric input');
     assert.equal(q.answer_contract?.kind,'numeric_exact');
     assert.equal(q.answer_contract?.number_only,true);
     assert.ok(eq(q.answer_contract,before.answer_contract),'numeric contract cannot change');
     assert.ok(eq(q.explanation,before.explanation),'numeric solution cannot change');
     assert.ok(eq(q.diagnostic_rules,before.diagnostic_rules),'diagnostic rules cannot change');
     const derived=extraDecimal.get(id)();
     assert.ok(Math.abs(derived-Number(q.answer_contract.canonical_answer))<1e-10,
       'independent original numeric derivation disagrees with evaluator');
     assert.ok(q.answer_contract.accepted_examples.some(v=>
       Math.abs(Number(String(v).trim().replace(',','.'))-derived)<1e-10),
       'derived value absent from accepted input variants');
     for(const lang of languages){
      assert.ok(q.question[lang].startsWith(before.question[lang]+' '),
       'unexpected learner stem rewrite for decimal format');
      assert.equal(q.question[lang].slice(before.question[lang].length+1),
        id===7506&&lang==='en'?'Enter the answer as a decimal number.':decimalEnding[lang],
        'decimal format instruction not exact trilingual reviewed text');
     }
    }


    if(id===7554){
     // A set ignores repeated entries: {4,4,7} and {4,7} are identical.
     // Q070 must have exactly one mathematically valid domain/range option.
     assert.equal(q.qtype,'mcq');
     assert.equal(q.correct_answer,'C');
     assert.equal(q.correct_answer,before.correct_answer);
     assert.ok(eq(q.question,before.question)&&eq(q.explanation,before.explanation));
     const asSets=text=>[...String(text).matchAll(/\{([^}]+)\}/g)]
       .map(m=>[...new Set(m[1].split(',').map(Number))].sort((a,b)=>a-b).join(',')).join(';');
     for(const lang of languages){
      const oldB=before.options.find(o=>o.key==='B'),newB=q.options.find(o=>o.key==='B');
      assert.ok(oldB&&newB);
      assert.ok(oldB.text[lang].includes('{4,4,7}'));
      assert.equal(newB.text[lang],oldB.text[lang].replace('{4,4,7}','{4,5,7}'));
      assert.equal(newB.diagnostic_code,oldB.diagnostic_code);
      for(const key of ['A','C','D'])assert.ok(eq(q.options.find(o=>o.key===key),
        before.options.find(o=>o.key===key)),'Q070 non-B option changed '+lang);
      assert.equal(asSets(oldB.text[lang]),asSets(before.options.find(o=>o.key==='C').text[lang]),
        'Q070 historical distractor mathematical equivalence not reproduced');
      assert.notEqual(asSets(newB.text[lang]),asSets(q.options.find(o=>o.key==='C').text[lang]),
        'Q070 new distractor is still equivalent to correct');
      const signatures=q.options.map(o=>asSets(o.text[lang]));
      assert.equal(new Set(signatures).size,4,'Q070 all choices must be distinct sets '+lang);
     }
    }
    if(id===7553){
     assert.ok(eq(before.options,q.options),'Q069 original answer and distractor semantics must stay unchanged');
     assert.equal(q.correct_answer,before.correct_answer);
     assert.equal(q.correct_answer,'B');
     assert.ok(/Which statement correctly defines/.test(q.question.en));
     assert.ok(/Какое утверждение/.test(q.question.ru));
     assert.ok(/Qaysi tasdiq/.test(q.question.uz));
     assert.equal(q.explanation.en,before.explanation.en);
     assert.equal(q.explanation.ru,before.explanation.ru);
     assert.ok(/injektiv \(birga-bir\)/.test(q.explanation.uz));
     assert.ok(!/one-to-one/.test(q.explanation.uz));
    }
    if(id===7795){
     assert.ok(eq(before.options,q.options),'Q311 original answer and diagnostic meanings must stay unchanged');
     assert.equal(q.correct_answer,before.correct_answer);
     assert.equal(q.correct_answer,'B');
     const constantSeq=[5,5,5,5];
     const diffs=constantSeq.slice(1).map((v,i)=>v-constantSeq[i]);
     assert.equal(new Set(diffs).size,1);
     assert.equal(diffs[0],0);
     assert.ok(/an arithmetic progression\?/.test(q.question.en));
     assert.ok(!/non-constant/i.test(q.question.en));
     assert.ok(!/непостоянную/i.test(q.question.ru));
     assert.ok(!/O‘zgarmas bo‘lmagan/i.test(q.question.uz));
     assert.ok(/zero/.test(q.explanation.en));
     assert.ok(/нулю/.test(q.explanation.ru));
     assert.ok(/nolga/.test(q.explanation.uz));
    }
    if(id===7573){
     // g(f(x)) = 1-(3x-2): one correct expression, four distinct polynomials.
     assert.equal(before.correct_answer,q.correct_answer);
     assert.ok(eq(q.question,before.question)&&eq(q.explanation,before.explanation));
     for(const key of ['A','B','C'])assert.ok(eq(q.options.find(o=>o.key===key),
       before.options.find(o=>o.key===key)),'Q089 unchanged options A-C');
     const oldD=before.options.find(o=>o.key==='D'),newD=q.options.find(o=>o.key==='D');
     assert.equal(oldD.diagnostic_code,newD.diagnostic_code);
     for(const lang of languages){
      assert.equal(newD.text[lang],'3x−3','Q089 unique wrong distractor');
      assert.equal(oldD.text[lang],'−3x−1','Q089 former redundant distractor');
      assert.equal(new Set(q.options.map(o=>o.text[lang])).size,4);
     }
     // Evaluate all options independently at x=0; a repeat in any locale fails.
     const values=q.options.map(o=>{
      const s=o.text.en.replace(/−/g,'-').replace(/\s+/g,'');
      if(s==='3(1-x)-2')return 1;
      if(s==='1-3x-2')return -1;
      if(s==='3-3x')return 3;
      if(s==='3x-3')return -3;
      throw Error('Q089 unrecognized expression');
     });
     assert.equal(new Set(values).size,4);
     const expectedValue=1-(3*0-2);
     assert.equal(values[q.options.findIndex(o=>o.key===q.correct_answer)],expectedValue);
    }
    if(id===7686){
     assert.ok(eq(q.options,before.options));
     assert.ok(eq(q.explanation,before.explanation));
     assert.equal(q.correct_answer,before.correct_answer);
     assert.match(q.question.en,/must the centre/);
     assert.match(q.question.ru,/обязательно лежит/);
     assert.match(q.question.uz,/albatta yotadi/);
     // Midpoint (3,4), AB slope +1 -> perpendicular bisector y=-x+7.
     // Test three different allowable centres, not a single lucky intersection.
     const lineValue=(s,x)=>{
      const m=/^y=([−-]?)x([+−-]\d+)$/.exec(s);
      assert.ok(m,'Q202 non-linear distractor');
      return (m[1]? -1:1)*x+Number(m[2].replace('−','-'));
     };
     const allCentres=[2,3,4].map(x=>[x,7-x]);
     const matching=q.options.filter(o=>allCentres.every(([x,y])=>
       lineValue(o.text.en,x)===y));
     assert.equal(matching.length,1,'Q202 must have exactly one mandatory locus');
     assert.equal(matching[0].key,q.correct_answer);
     for(const lang of languages)assert.deepEqual(q.options.map(o=>o.text[lang]),
       q.options.map(o=>o.text.en),'Q202 math options differ across locales');
    }
    if(id===7710){
     assert.ok(eq(q.explanation,before.explanation));
     assert.ok(eq(q.answer_contract,before.answer_contract));
     assert.equal(q.qtype,'input');
     assert.equal(Number(q.answer_contract.canonical_answer),15/10);
     assert.ok(q.answer_contract.accepted_examples.includes('1.5'));
     assert.ok(q.answer_contract.accepted_examples.includes('1,5'));
     assert.match(q.question.en,/decimal number/);
     assert.match(q.question.ru,/десятичным числом/);
     assert.match(q.question.uz,/o‘nli son/);
    }
    if(id===7791){
     assert.equal(q.explanation.ru,before.explanation.ru);
     assert.equal(q.explanation.uz,before.explanation.uz);
     assert.ok(/minus 4/.test(q.explanation.en));
    }
    if(id===7724){
     assert.match(q.question.en,/same two bounding rays/);
     assert.match(q.question.ru,/одними и теми же двумя лучами/);
     assert.match(q.question.uz,/bir xil ikkita chegaralovchi nurga/);
    }
    if(id===7884){
     assert.equal(q.correct_answer,before.correct_answer,'Q400 math key unchanged');
     assert.ok(eq(q.options,before.options),'Q400 distractors unchanged');
     assert.ok(eq(q.explanation,before.explanation),'Q400 solution unchanged');
     assert.match(q.question.en,/complete set of x-values where dy\/dx>0/);
     assert.match(q.question.ru,/все значения x, при которых dy\/dx>0/);
     assert.match(q.question.uz,/barcha x qiymatlarini/);
     // dy/dx=2x-4: 2 is excluded; one valid proper subset is not the full answer.
     const derivative=x=>2*x-4;
     assert.equal(derivative(2),0);
     assert.ok(derivative(3)>0&&derivative(1)<0);
    }
    if(id===7965){
     assert.equal(q.correct_answer,before.correct_answer,'Q481 math key unchanged');
     assert.ok(eq(q.options,before.options),'Q481 options unchanged');
     assert.ok(eq(q.question,before.question),'Q481 task unchanged');
     for(const lang of languages){
      assert.ok(q.explanation[lang].includes('√(36−24)'),
       'Q481 explicit discriminant grouping required in '+lang);
      assert.ok(!q.explanation[lang].includes('√36−24'));
     }
     // x²-6x+6=0; both candidate roots satisfy the equation.
     const residual=x=>x*x-6*x+6;
     assert.ok(Math.abs(residual(3+Math.sqrt(3)))<1e-12);
     assert.ok(Math.abs(residual(3-Math.sqrt(3)))<1e-12);
    }
    if(id===7970)for(const lang of languages){
     assert.notEqual(before.question[lang],q.question[lang]);
     assert.ok(!/(?:Enter k|Введите k|k ni kiriting)/.test(q.question[lang]));
    }
   }
   assert.ok(q.question?.en&&q.question?.ru&&q.question?.uz);
   assert.ok(q.explanation?.en&&q.explanation?.ru&&q.explanation?.uz);
   const seq=groups.get(q.practice_no)||[];groups.set(q.practice_no,seq);
   if(q.qtype==='mcq'){
    mcq++;
    assert.deepEqual(q.options.map(o=>o.key),letters);
    assert.ok(letters.includes(q.correct_answer));
    assert.ok(!/\b(?:enter|type in|write down|provide your answer|give your answer)\b/i.test(q.question.en));
    assert.ok(!/введите|вписа/i.test(q.question.ru));
    assert.ok(!/\bkiriting\b/i.test(q.question.uz));
    for(const opt of q.options)for(const lang of languages)assert.ok(opt.text?.[lang]);
    seq.push(q.correct_answer);
   }else{assert.equal(q.qtype,'input');input++;}
  }
 }
}
assert.equal(nFiles,45);assert.equal(items,495);assert.equal(changed,31);
assert.equal(checked21.size,21);assert.equal(seenUz21,19);assert.equal(seenDiag21,12);
assert.equal(checkedTrig23.size,14);assert.equal(seenDiagTrig23,23);
assert.equal(checkedIntegral9.size,6);assert.equal(seenDiagIntegral9,9);
assert.equal(checkedNext8.size,6);assert.equal(seenDiagNext8,8);
for(const folder of folderList){
 const rel='content/math/practice_v2/'+folder.name+'/diagnostic_catalog.json';
 const current=JSON.parse(fs.readFileSync(path.join(root,rel),'utf8'));
 const previous=previousRelease(rel);
 const extra=[...(newCatalog21[folder.name]||[]),...(folder.name==='p4_circular_trigonometry'?extraCatalogTrig23:[]),...(extraCatalogIntegral9[folder.name]||[]),...(extraCatalogNext8[folder.name]||[])];
 assert.equal(current.diagnostics.length,previous.diagnostics.length+extra.length);
 assert.ok(eq(current.diagnostics.slice(0,previous.diagnostics.length),previous.diagnostics));
 assert.deepEqual(current.diagnostics.slice(previous.diagnostics.length).map(d=>d.code),extra);
 for(const d of current.diagnostics.slice(previous.diagnostics.length)){
  assert.ok(d.feedback?.en&&d.feedback?.ru&&d.feedback?.uz);
  assert.ok(d.next_action?.en&&d.next_action?.ru&&d.next_action?.uz);
  assert.ok(['P1-FUN-01','P1-FUN-04','P1-SER-02','P1-INT-04','P1-TRI-03','P1-TRI-05','P1-INT-03','P1-DIF-05','P1-DIF-07'].includes(d.skill));
 }
}
assert.equal(found.size,expected.size);assert.equal(mcq,277);assert.equal(input,218);
const all={A:0,B:0,C:0,D:0};
for(let practice=1;practice<=7;practice++){
 const lettersHere=groups.get(practice);
 assert.ok(lettersHere?.length>20);
 const count={A:0,B:0,C:0,D:0};
 for(const letter of lettersHere){count[letter]++;all[letter]++;}
 for(const letter of letters)assert.ok(count[letter]/lettersHere.length>=.2 &&
  count[letter]/lettersHere.length<=.3,'Practice '+practice+' unbalanced');
 for(let i=0;i<lettersHere.length;i++){
  for(let period=1;period<=4;period++){
   if(i+period*2>lettersHere.length)continue;
   if(period===1 && i+4<=lettersHere.length &&
      lettersHere.slice(i,i+4).every(x=>x===lettersHere[i]))
    assert.fail('4 consecutive identical correct letters in Practice '+practice);
   if(period>=2 && lettersHere.slice(i,i+period).join('')===
      lettersHere.slice(i+period,i+period*2).join(''))
    assert.fail('short repeated correct-letter motif in Practice '+practice);
  }
 }
}
assert.deepEqual(all,{A:68,B:70,C:71,D:68},
 'correct-answer placement deviates from reviewed 277-question distribution');
console.log(JSON.stringify({source_guard:'PASS',authored:495,mcq:277,input:218,
 corrected:30,diagnostic21:21,additional_trig_questions:14,additional_true_feedback_remaps:23,new_integral_derivative_questions:6,new_integral_derivative_remaps:9,new_8_feedback_questions:6,new_8_feedback_remaps:8,new_uz_field_occurrences:19,new_option_diagnostic_mappings:52,published_prior:28,new_source_proposals:2,unrelated_change_count:0,practice_batches:7,
 anti_pattern_cycles:0,retained_option_semantics:true,
 answer_distribution:'balanced',protected_keys_printed:false}));
