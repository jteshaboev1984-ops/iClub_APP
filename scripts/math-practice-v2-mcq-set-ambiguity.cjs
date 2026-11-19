#!/usr/bin/env node
'use strict';
// Detect MCQs where more than one inequality option can be a true subset
// of the same mathematical set. Such distractors require a "full/exact
// range/domain/solution set" question, not a generic "where?" prompt.
// This is a focused anti-ambiguity regression, not a proof of all MCQs.
// No question text, options or keys are emitted.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const bank=path.resolve(__dirname,'../content/math/practice_v2');
const files=fs.readdirSync(bank,{withFileTypes:true}).filter(x=>x.isDirectory())
 .flatMap(dir=>fs.readdirSync(path.join(bank,dir.name))
  .filter(name=>/^P1-[A-Z]{3}-\d{2}\.json$/.test(name))
  .map(name=>path.join(bank,dir.name,name)));
assert.equal(files.length,45,'The full 45-skill P1 bank must be inspected');
const issues=[],flagged=[],ids=new Set();
const norm=t=>String(t||'').normalize('NFC').replace(/[−–—]/g,'-')
 .replace(/[≤]/g,'<=').replace(/[≥]/g,'>=').replace(/\s+/g,'');
function bound(t){
 const m=/^(x|k|p|f\(x\)|y)(<=|>=|<|>)(-?\d+(?:\.\d+)?)$/.exec(norm(t));
 return m?{v:m[1],direction:m[2][0],n:+m[3]}:null;
}
let count=0,mcqs=0;
for(const file of files){
 const content=JSON.parse(fs.readFileSync(file,'utf8'));
 for(const q of content.questions){
  count++;
  const item=7484+Number(q.key.slice(-3));
  if(ids.has(item))issues.push('Duplicate item ID '+item);
  ids.add(item);
  if(q.qtype!=='mcq')continue;
  mcqs++;
  const opts=q.options.map(o=>bound(o.text.en));
  let nested=false;
  for(let i=0;i<opts.length;i++)for(let j=i+1;j<opts.length;j++){
   const a=opts[i],b=opts[j];
   if(a&&b&&a.v===b.v&&a.direction===b.direction&&a.n!==b.n)nested=true;
  }
  if(!nested)continue;
  flagged.push(item);
  if(!/\b(range|domain|complete set|full set|all x-values)\b/i.test(q.question.en))
   issues.push('Nested inequality MCQ missing exact-set qualifier: '+item);
  // This family should remain under explicit review when a new candidate is authored.
 }
}
if(count!==495||ids.size!==495||mcqs!==277)issues.push('Incomplete active P1 MCQ coverage');
const expected=[7489,7566,7570,7577,7884];
if(flagged.length!==expected.length||flagged.slice().sort((a,b)=>a-b).some((x,i)=>x!==expected[i]))
 issues.push('Nested-inequality candidate IDs changed: independent re-review required');
if(issues.length){for(const e of issues)console.error(e);process.exit(1);}
console.log('PASS 495-question/277-MCQ set-ambiguity sweep; 5 nested-predicate items have exact range/domain/full-set prompts; no keys printed');
