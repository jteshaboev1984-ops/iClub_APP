#!/usr/bin/env node
'use strict';
// #574 Mathematics Practice v2 — approved answer-letter placement contract.
// Source-only: validates all 495 authorship items / 277 MCQs and the exact
// seven future-only semantic permutations. Never prints keys or item text.
// Historic rows and issued answers remain immutable.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {execFileSync}=require('node:child_process');
const root=path.resolve(__dirname,'..');
const bank=path.join(root,'content/math/practice_v2');
const baseline='381e57ee6ea53b437298d5b5faf4190cf6dc2cb1';
const edited=new Set([7624,7662,7797,7881,7926,7937,7970]);
const extra=new Set([7624,7797,7937]);
const letters=['A','B','C','D'];
const stable=v=>Array.isArray(v)?v.map(stable):v&&typeof v==='object'
  ?Object.fromEntries(Object.keys(v).sort().map(k=>[k,stable(v[k])])):v;
const eq=(a,b)=>JSON.stringify(stable(a))===JSON.stringify(stable(b));
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const parent=p=>execFileSync('git',['show',baseline+':'+p],{
  cwd:root,encoding:'utf8',maxBuffer:8*1024*1024
});
const folderList=fs.readdirSync(bank,{withFileTypes:true})
  .filter(x=>x.isDirectory()).map(x=>x.name).sort();
const files=folderList.flatMap(dir=>fs.readdirSync(path.join(bank,dir))
  .filter(file=>/^P1-[A-Z]{3}-\d{2}\.json$/.test(file)).sort()
  .map(file=>'content/math/practice_v2/'+dir+'/'+file));
assert.equal(files.length,45,'approved 45-skill P1 boundary');
const baselineRows=parent('docs/qa/math-practice-v2-all495-itemwise-review-ledger-20261119.csv')
  .trim().split('\n').slice(1).map(x=>x.split(','));
const rows=read('docs/qa/math-practice-v2-all495-itemwise-review-ledger-20261119.csv')
  .trim().split('\n').slice(1).map(x=>x.split(','));
assert.equal(rows.length,495);
const byId=new Map();
let found=new Set(),unmodified=0;
for(const file of files){
  const old=JSON.parse(parent(file));
  const now=JSON.parse(read(file));
  assert.equal(old.skill,now.skill,'skill family may not drift');
  assert.equal(old.questions.length,now.questions.length,'question count may not drift');
  assert.deepEqual(Object.keys(old).sort(),Object.keys(now).sort());
  assert.ok(eq({...old,questions:[]},{...now,questions:[]}),
    'academic file-level provenance drift');
  for(let i=0;i<now.questions.length;i++){
    const q=now.questions[i],before=old.questions[i];
    assert.equal(q.key,before.key,'published question identity/order drift');
    const match=/^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(q.key);
    assert.ok(match,'unrecognized author key');
    const id=7484+Number(match[1]);
    assert.ok(!byId.has(id),'duplicate author ID');
    byId.set(id,q);
    if(!edited.has(id)){
      assert.ok(eq(q,before),'unapproved question changed outside seven-item fix');
      unmodified++;
      continue;
    }
    found.add(id);
    assert.equal(q.qtype,'mcq','only MCQ answers are repositioned');
    assert.notEqual(q.correct_answer,before.correct_answer,
      'planned answer placement not applied');
    for(const current of [q,before])
      assert.deepEqual(current.options.map(o=>o.key),letters,'option index/key drift');
    assert.equal(q.options.filter(o=>o.diagnostic_code===null).length,1);
    assert.equal(before.options.filter(o=>o.diagnostic_code===null).length,1);
    assert.equal(q.options.find(o=>o.key===q.correct_answer)?.diagnostic_code,null);
    assert.equal(before.options.find(o=>o.key===before.correct_answer)?.diagnostic_code,null);
    assert.ok(eq({...q,options:[],correct_answer:null},
                 {...before,options:[],correct_answer:null}),
      'stem, difficulty, solution, time, source or evaluator drift');
    const semantic=o=>JSON.stringify(stable({text:o.text,diagnostic_code:o.diagnostic_code}));
    assert.deepEqual(q.options.map(semantic).sort(),before.options.map(semantic).sort(),
      'option content / diagnostic meaning changed rather than key placement');
    assert.ok(eq(
      q.options.find(o=>o.key===q.correct_answer)?.text,
      before.options.find(o=>o.key===before.correct_answer)?.text),
      'mathematically correct option meaning changed');
    assert.ok(['en','ru','uz'].every(l=>q.options.every(o=>o.text?.[l]?.trim())),
      'localized option missing');
    const current=rows.find(r=>+r[0]===id);
    const original=baselineRows.find(r=>+r[0]===id);
    assert.equal(current?.[11],'FUTURE_VERSION_REQUIRED',
      'a versioned answer edit must not overwrite historical question '+id);
    assert.equal(current?.[12],original?.[12],'prior answer history flag altered');
  }
}
assert.deepEqual([...found].sort((a,b)=>a-b),[...edited].sort((a,b)=>a-b));
assert.equal(unmodified,495-edited.size);
assert.equal(byId.size,495);
const contract=read('scripts/math-practice-v2-editorial-future-only-contract.cjs');
const match=contract.match(/const FUTURE_VERSION_REQUIRED = new Set\(\[([^\]]+)\]\)/);
assert.ok(match);
const future=new Set(match[1].split(',').map(v=>Number(v.trim())));
assert.equal(future.size,81);
for(const id of edited)assert.ok(future.has(id)||extra.has(id)||id===7881,
  'answer rekey without future-only packaging');
for(const id of extra)assert.ok(!future.has(id));
const pools=new Map();
let mcq=0,input=0;
for(const [id,q] of byId){
  const p=q.practice_no;
  assert.ok(Number.isInteger(p)&&p>=1&&p<=7);
  let pool=pools.get(p)||[];pool.push({id,q});pools.set(p,pool);
  if(q.qtype==='input'){input++;continue;}
  assert.equal(q.qtype,'mcq');mcq++;
  assert.deepEqual(q.options.map(o=>o.key),letters);
  assert.ok(letters.includes(q.correct_answer));
  assert.equal(q.options.filter(o=>o.key===q.correct_answer).length,1);
  for(const lang of ['en','ru','uz']){
    const options=q.options.map(o=>o.text?.[lang]?.normalize('NFKC').trim());
    assert.ok(options.every(Boolean),'missing localized MCQ choice');
    assert.equal(new Set(options).size,4,'duplicate localized MCQ choices');
  }
}
assert.equal(mcq,277);assert.equal(input,218);
assert.deepEqual([...pools].sort((a,b)=>a[0]-b[0]).map(([p,items])=>items.length),
  [68,80,68,77,66,70,66]);
const poolCounts=[],distributionByDifficulty={},skillChecks=[];
for(const [p,questions] of [...pools].sort((a,b)=>a[0]-b[0])){
  const mcqItems=questions.filter(x=>x.q.qtype==='mcq').sort((a,b)=>a.id-b.id);
  const pattern=mcqItems.map(x=>x.q.correct_answer);
  const count=Object.fromEntries(letters.map(letter=>[letter,pattern.filter(x=>x===letter).length]));
  for(const countForLetter of Object.values(count))assert.ok(
    countForLetter>=Math.ceil(.2*pattern.length-1e-9) &&
    countForLetter<=Math.floor(.3*pattern.length+1e-9),
    'practice batch violates approved 20–30% placement: '+p);
  let run=1;
  for(let i=1;i<pattern.length;i++){
    run=pattern[i]===pattern[i-1]?run+1:1;
    assert.ok(run<=3,'predictable 4+ identical answers: practice '+p);
  }
  for(let n=2;n<=4;n++)
    for(let i=0;i+2*n<=pattern.length;i++)
      assert.notEqual(pattern.slice(i,i+n).join(''),pattern.slice(i+n,i+2*n).join(''),
        'repeated fixed A/B/C/D cycle: practice '+p);
  const bySkill=new Map(),byLevel=new Map();
  for(const item of mcqItems){
    const skill=item.q.primary_skill;
    bySkill.set(skill,[...(bySkill.get(skill)||[]),item.q.correct_answer]);
    const difficulty=item.q.difficulty;
    byLevel.set(difficulty,[...(byLevel.get(difficulty)||[]),item.q.correct_answer]);
  }
  for(const [skill,list] of bySkill){
    if(list.length<5)continue;
    for(const letter of letters)
      assert.ok(list.filter(x=>x===letter).length/list.length<=.4+1e-9,
        'single-letter dominance in 5+ MCQ skill family '+skill);
    skillChecks.push(skill);
  }
  // Alert only on strong within-difficulty dominance in a substantial batch;
  // preserve exact approved distribution rule as whole Practice and skill.
  for(const [difficulty,list] of byLevel){
    if(list.length>=12)for(const letter of letters)
      assert.ok(list.filter(x=>x===letter).length/list.length<=.5,
        'difficulty-specific single-key dominance: practice '+p+' '+difficulty);
  }
  poolCounts.push({practice:p,mcq:mcqItems.length,counts:count,
    repeated_cycles:0,overlong_same_letter_runs:0});
}
const overall=Object.fromEntries(letters.map(l=>[l,poolCounts.reduce((s,p)=>s+p.counts[l],0)]));
console.log(JSON.stringify({coverage:495,skill_files:45,mcq,input,
  corrected_future_only_items:edited.size,additional_future_only_versions:extra.size,
  semantically_preserved_all_three_locales:true,
  previous_learner_answer_edits:0,old_published_row_updates:0,
  overall_correct_letter_distribution:overall,
  per_practice:poolCounts,skill_families_checked:skillChecks.length,
  detectable_repeated_short_cycles:0,release_ready:false}));
