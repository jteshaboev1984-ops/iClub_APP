#!/usr/bin/env node
'use strict';

const fs=require('fs');
const path=require('path');
const ROOT=path.resolve(__dirname,'..');
const CONTENT_DIR=path.join(ROOT,'content','math','practice_v2','p7_integration');
const CATALOG_PATH=path.join(CONTENT_DIR,'diagnostic_catalog.json');

const EXPECTED={
 total:66,
 qtype:{mcq:28,input:38},
 skills:{
  'P1-INT-01':14,
  'P1-INT-02':12,
  'P1-INT-03':14,
  'P1-INT-04':14,
  'P1-INT-05':12
 },
 difficultyBand:{easy:[14,20],medium:[22,30],hard:[22,30]},
 correctLetterBand:[6,8],
 maxSameCorrectRun:2
};

const LANGS=['en','ru','uz'],MCQ_KEYS=['A','B','C','D'];
const errors=[],warnings=[];
const fail=m=>errors.push(m);
const normText=v=>String(v??'').normalize('NFKC').replace(/[−–—]/g,'-').replace(/\s+/g,' ').trim().toLowerCase();
const normAnswer=v=>normText(v).replace(/,/g,'.');
function mustText(obj,field,key){for(const l of LANGS)if(!obj||typeof obj[l]!=='string'||!obj[l].trim())fail(`${key}: missing ${field}.${l}`);}
function isObject(v){return v&&typeof v==='object'&&!Array.isArray(v);}

if(!fs.existsSync(CONTENT_DIR)){console.error('Missing content directory');process.exit(2);}
if(!fs.existsSync(CATALOG_PATH)){console.error('Missing diagnostic catalog');process.exit(2);}

const catalog=JSON.parse(fs.readFileSync(CATALOG_PATH,'utf8'));
const catalogCodes=new Set(),catalogSkill=new Map();
for(const d of catalog.diagnostics||[]){
 if(!d.code)fail('diagnostic without code');
 if(catalogCodes.has(d.code))fail(`duplicate diagnostic ${d.code}`);
 catalogCodes.add(d.code);catalogSkill.set(d.code,d.skill);
 if(!/^P1-INT-0[1-5]$/.test(d.skill||''))fail(`${d.code}: invalid skill ${d.skill}`);
 if(!['specific','broad','unmapped'].includes(d.inference_strength))fail(`${d.code}: invalid inference_strength`);
 mustText(d.feedback,'feedback',d.code);mustText(d.next_action,'next_action',d.code);
}

const questionFiles=fs.readdirSync(CONTENT_DIR).filter(n=>/^P1-INT-\d\d\.json$/.test(n)).sort();
const questions=[];
for(const name of questionFiles){
 const parsed=JSON.parse(fs.readFileSync(path.join(CONTENT_DIR,name),'utf8'));
 if(!Array.isArray(parsed.questions)){fail(`${name}: questions must be array`);continue;}
 for(const q of parsed.questions)questions.push({...q,__file:name});
}

const keys=new Set(),stems=new Map(),skillCounts={},qtypeCounts={},difficultyCounts={};
const correctLetters={A:0,B:0,C:0,D:0},perSkillLetters={};let correctSequence='';

for(const q of questions){
 const key=q.key||'<missing-key>';
 if(keys.has(q.key))fail(`${key}: duplicate key`);keys.add(q.key);
 const m=/^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(q.key||'');
 if(!m||Number(m[1])<430||Number(m[1])>495)fail(`${key}: invalid Practice 7 key/range`);
 if(!/^P1-INT-0[1-5]$/.test(q.primary_skill||''))fail(`${key}: invalid primary_skill`);
 if(q.ai_source_skill!==q.primary_skill)fail(`${key}: ai_source_skill mismatch`);
 if(!['easy','medium','hard'].includes(q.difficulty))fail(`${key}: invalid difficulty`);
 if(!['mcq','input'].includes(q.qtype))fail(`${key}: invalid qtype`);
 if(!/Ch10 Integration/i.test(q.source_ref||''))fail(`${key}: incorrect source_ref`);
 mustText(q.question,'question',key);mustText(q.explanation,'explanation',key);

 const stem=normText(q.question?.en);
 if(stems.has(stem))fail(`${key}: duplicate English stem with ${stems.get(stem)}`);else stems.set(stem,key);

 skillCounts[q.primary_skill]=(skillCounts[q.primary_skill]||0)+1;
 qtypeCounts[q.qtype]=(qtypeCounts[q.qtype]||0)+1;
 difficultyCounts[q.difficulty]=(difficultyCounts[q.difficulty]||0)+1;

 if(q.qtype==='mcq'){
  if(q.answer_contract!=null)fail(`${key}: MCQ carries answer_contract`);
  if(!Array.isArray(q.options)||q.options.length!==4){fail(`${key}: MCQ must have four options`);continue;}
  const optionKeys=q.options.map(o=>o.key);
  if(new Set(optionKeys).size!==4||!MCQ_KEYS.every(k=>optionKeys.includes(k)))fail(`${key}: option keys must be A/B/C/D`);
  if(!MCQ_KEYS.includes(q.correct_answer))fail(`${key}: invalid correct_answer`);
  const seen={en:new Set(),ru:new Set(),uz:new Set()};
  for(const o of q.options){
   mustText(o.text,`option_${o.key}`,key);
   for(const l of LANGS){const n=normText(o.text?.[l]);if(seen[l].has(n))fail(`${key}: duplicate ${l} option`);seen[l].add(n);}
   const correct=o.key===q.correct_answer;
   if(correct&&o.diagnostic_code)fail(`${key}: correct option carries diagnostic`);
   if(!correct&&!o.diagnostic_code)fail(`${key}: wrong option missing diagnostic`);
   if(o.diagnostic_code&&!catalogCodes.has(o.diagnostic_code))fail(`${key}: unknown diagnostic ${o.diagnostic_code}`);
   if(o.diagnostic_code&&catalogSkill.get(o.diagnostic_code)!==q.primary_skill)fail(`${key}: diagnostic skill mismatch ${o.diagnostic_code}`);
  }
  correctLetters[q.correct_answer]++;correctSequence+=q.correct_answer;
  perSkillLetters[q.primary_skill]||={A:0,B:0,C:0,D:0,n:0};
  perSkillLetters[q.primary_skill][q.correct_answer]++;perSkillLetters[q.primary_skill].n++;
 }

 if(q.qtype==='input'){
  if(q.correct_answer!=null)fail(`${key}: input must use answer_contract`);
  if(!isObject(q.answer_contract)){fail(`${key}: missing answer_contract`);continue;}
  const ac=q.answer_contract;
  if(!['integer_exact','numeric_exact'].includes(ac.kind))fail(`${key}: unsupported input kind ${ac.kind}`);
  if(typeof ac.canonical_answer!=='string'||!ac.canonical_answer.trim())fail(`${key}: missing canonical_answer`);
  if(ac.number_only!==true)fail(`${key}: number_only must be true`);
  if(!Array.isArray(ac.accepted_examples)||ac.accepted_examples.length<2)fail(`${key}: accepted_examples too small`);
  if(!Array.isArray(ac.rejected_examples)||ac.rejected_examples.length<2)fail(`${key}: rejected_examples too small`);
  const accepted=new Set((ac.accepted_examples||[]).map(normAnswer)),rejected=new Set((ac.rejected_examples||[]).map(normAnswer));
  if(!accepted.has(normAnswer(ac.canonical_answer)))fail(`${key}: canonical not accepted`);
  for(const v of accepted)if(rejected.has(v))fail(`${key}: accepted/rejected overlap ${v}`);
  for(const rule of q.diagnostic_rules||[]){
   if(!rule.answer_match||!rule.diagnostic_code){fail(`${key}: malformed diagnostic rule`);continue;}
   if(!catalogCodes.has(rule.diagnostic_code))fail(`${key}: unknown input diagnostic ${rule.diagnostic_code}`);
   if(catalogSkill.get(rule.diagnostic_code)!==q.primary_skill)fail(`${key}: input diagnostic skill mismatch`);
   if(normAnswer(rule.answer_match)===normAnswer(ac.canonical_answer))fail(`${key}: diagnostic rule matches correct answer`);
  }
 }
}

if(questions.length!==EXPECTED.total)fail(`total expected ${EXPECTED.total}, got ${questions.length}`);
for(const [s,n] of Object.entries(EXPECTED.skills))if((skillCounts[s]||0)!==n)fail(`${s}: expected ${n}, got ${skillCounts[s]||0}`);
for(const [t,n] of Object.entries(EXPECTED.qtype))if((qtypeCounts[t]||0)!==n)fail(`${t}: expected ${n}, got ${qtypeCounts[t]||0}`);
for(const [d,[lo,hi]] of Object.entries(EXPECTED.difficultyBand)){const n=difficultyCounts[d]||0;if(n<lo||n>hi)fail(`${d}: ${n} outside ${lo}-${hi}`);}
for(const l of MCQ_KEYS){const n=correctLetters[l],[lo,hi]=EXPECTED.correctLetterBand;if(n<lo||n>hi)fail(`${l}=${n} outside ${lo}-${hi}`);}

let maxRun=0,run=0,prev='';
for(const l of correctSequence){if(l===prev)run++;else{prev=l;run=1;}maxRun=Math.max(maxRun,run);}
if(maxRun>EXPECTED.maxSameCorrectRun)fail(`same-letter run ${maxRun} > ${EXPECTED.maxSameCorrectRun}`);
for(const [s,d] of Object.entries(perSkillLetters))if(d.n>=5)for(const l of MCQ_KEYS)if(d[l]/d.n>0.4+1e-9)fail(`${s}: ${l} dominates ${d[l]}/${d.n}`);
for(const p of ['ABCDABCD','BCDABCDA','CDABCDAB','DABCDABC'])if(correctSequence.includes(p))fail(`obvious answer cycle ${p}`);

console.log(JSON.stringify({
 questions:questions.length,skillCounts,qtypeCounts,difficultyCounts,correctLetters,
 maxSameCorrectRun:maxRun,diagnosticCodesInCatalog:catalogCodes.size,
 errors:errors.length,warnings:warnings.length
},null,2));
for(const m of warnings)console.warn(`WARN: ${m}`);
for(const m of errors)console.error(`ERROR: ${m}`);
if(errors.length)process.exit(1);
