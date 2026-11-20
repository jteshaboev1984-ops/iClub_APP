#!/usr/bin/env node
'use strict';
// #574: 10 already-published corrections + 2 new isolated academic fixes.
// Check all 495 authored questions vs real original main; fail on any other
// key/text/locale/difficulty change. No protected solution printed in CI.
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path');
const {execFileSync}=require('node:child_process');
const root=path.resolve(__dirname,'..');
const bank=path.join(root,'content/math/practice_v2');
const baseline='296bf21df09a808152b4ae4e153ddcec8aec85cd';
const expected=new Map([
 [7624,['options','correct_answer']],[7662,['options','correct_answer']],
 [7724,['question']],[7791,['explanation']],
 [7797,['options','correct_answer']],[7881,['options','correct_answer']],
 [7884,['question']],[7965,['explanation']],
 [7893,['options']],[7926,['options','correct_answer']],
 [7937,['options','correct_answer']],[7970,['question','options','correct_answer']]
]);
const rekey=new Set([7624,7662,7797,7881,7926,7937,7970]);
const stable=x=>Array.isArray(x)?x.map(stable):x&&typeof x==='object'
 ?Object.fromEntries(Object.keys(x).sort().map(k=>[k,stable(x[k])])):x;
const eq=(a,b)=>JSON.stringify(stable(a))===JSON.stringify(stable(b));
const prev=file=>JSON.parse(execFileSync('git',['show',baseline+':'+file],{
 cwd:root,encoding:'utf8',maxBuffer:7*1024*1024}));
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
  assert.equal(original.skill,now.skill);
  assert.equal(original.questions.length,now.questions.length);
  assert.ok(eq({...original,questions:[]},{...now,questions:[]}));
  for(let i=0;i<now.questions.length;i++){
   const before=original.questions[i],q=now.questions[i];
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
     assert.deepEqual(pool(q.options),pool(before.options),
       'distractor or diagnostic semantics changed');
     if(rekey.has(id))assert.notEqual(before.correct_answer,q.correct_answer);
     if(id===7893)assert.equal(before.correct_answer,q.correct_answer);
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
assert.equal(nFiles,45);assert.equal(items,495);assert.equal(changed,12);
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
 corrected:12,published_prior:10,new_source_proposals:2,unrelated_change_count:0,practice_batches:7,
 anti_pattern_cycles:0,retained_option_semantics:true,
 answer_distribution:'balanced',protected_keys_printed:false}));
