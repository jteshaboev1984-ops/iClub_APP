#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const CONTENT_DIR = path.join(ROOT, 'content', 'math', 'practice_v2', 'p5_binomial_series');
const CATALOG_PATH = path.join(CONTENT_DIR, 'diagnostic_catalog.json');

const EXPECTED = {
  total: 66,
  qtype: { mcq: 27, input: 39 },
  skills: {
    'P1-SER-01': 14,
    'P1-SER-02': 10,
    'P1-SER-03': 14,
    'P1-SER-04': 16,
    'P1-SER-05': 12,
  },
  difficultyBand: {
    easy: [12, 20],
    medium: [26, 36],
    hard: [15, 24],
  },
  correctLetterBand: [5, 9],
  maxSameCorrectRun: 2,
};

const LANGS = ['en','ru','uz'];
const MCQ_KEYS = ['A','B','C','D'];
const errors = [];
const warnings = [];

function fail(m){ errors.push(m); }
function warn(m){ warnings.push(m); }
function normText(v){
  return String(v ?? '').normalize('NFKC').replace(/[−–—]/g,'-').replace(/\s+/g,' ').trim().toLowerCase();
}
function normAnswer(v){ return normText(v).replace(/,/g,'.'); }
function mustText(obj,field,key){
  for(const lang of LANGS){
    if(!obj || typeof obj[lang] !== 'string' || !obj[lang].trim()) fail(`${key}: missing ${field}.${lang}`);
  }
}
function isObject(v){ return v && typeof v === 'object' && !Array.isArray(v); }

if(!fs.existsSync(CONTENT_DIR)){ console.error(`Missing content directory: ${CONTENT_DIR}`); process.exit(2); }
if(!fs.existsSync(CATALOG_PATH)){ console.error(`Missing diagnostic catalog: ${CATALOG_PATH}`); process.exit(2); }

const catalog=JSON.parse(fs.readFileSync(CATALOG_PATH,'utf8'));
const catalogCodes=new Set();
const catalogSkill=new Map();
for(const d of catalog.diagnostics || []){
  if(!d.code) fail('diagnostic_catalog: diagnostic without code');
  if(catalogCodes.has(d.code)) fail(`diagnostic_catalog: duplicate code ${d.code}`);
  catalogCodes.add(d.code); catalogSkill.set(d.code,d.skill);
  if(!/^P1-SER-0[1-5]$/.test(d.skill || '')) fail(`diagnostic_catalog: ${d.code} invalid skill ${d.skill}`);
  if(!['specific','broad','unmapped'].includes(d.inference_strength)) fail(`diagnostic_catalog: ${d.code} invalid inference_strength`);
  mustText(d.feedback,'feedback',`diagnostic_catalog:${d.code}`);
  mustText(d.next_action,'next_action',`diagnostic_catalog:${d.code}`);
}

const questionFiles=fs.readdirSync(CONTENT_DIR).filter(n=>/^P1-SER-\d\d\.json$/.test(n)).sort();
const questions=[];
for(const name of questionFiles){
  const parsed=JSON.parse(fs.readFileSync(path.join(CONTENT_DIR,name),'utf8'));
  if(!Array.isArray(parsed.questions)){ fail(`${name}: questions must be array`); continue; }
  for(const q of parsed.questions) questions.push({...q,__file:name});
}

const keys=new Set(), stems=new Map(), skillCounts={}, qtypeCounts={}, difficultyCounts={};
const correctLetters={A:0,B:0,C:0,D:0}, perSkillLetters={};
let correctSequence='';

for(const q of questions){
  const key=q.key || '<missing-key>';
  if(!q.key) fail(`${q.__file}: question without key`);
  if(keys.has(q.key)) fail(`${key}: duplicate question key`);
  keys.add(q.key);

  const m=/^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(q.key || '');
  if(!m || Number(m[1])<294 || Number(m[1])>359) fail(`${key}: invalid Practice 5 key/range`);
  if(!/^P1-SER-0[1-5]$/.test(q.primary_skill || '')) fail(`${key}: invalid primary_skill ${q.primary_skill}`);
  if(q.ai_source_skill!==q.primary_skill) fail(`${key}: ai_source_skill must equal primary_skill`);
  if(!['easy','medium','hard'].includes(q.difficulty)) fail(`${key}: invalid difficulty ${q.difficulty}`);
  if(!['mcq','input'].includes(q.qtype)) fail(`${key}: unsupported qtype ${q.qtype}`);

  const sourceOk=q.primary_skill==='P1-SER-01'
    ? /Ch6 Binomial expansion/i.test(q.source_ref || '')
    : /Ch7 Series/i.test(q.source_ref || '');
  if(!sourceOk) fail(`${key}: missing/incorrect source_ref`);

  mustText(q.question,'question',key);
  mustText(q.explanation,'explanation',key);

  const stem=normText(q.question?.en);
  if(stems.has(stem)) fail(`${key}: duplicate English stem with ${stems.get(stem)}`);
  else stems.set(stem,key);

  skillCounts[q.primary_skill]=(skillCounts[q.primary_skill]||0)+1;
  qtypeCounts[q.qtype]=(qtypeCounts[q.qtype]||0)+1;
  difficultyCounts[q.difficulty]=(difficultyCounts[q.difficulty]||0)+1;

  if(q.qtype==='mcq'){
    if(q.answer_contract != null) fail(`${key}: MCQ must not carry answer_contract`);
    if(!Array.isArray(q.options) || q.options.length!==4){ fail(`${key}: MCQ must have four options`); continue; }
    const optionKeys=q.options.map(o=>o.key);
    if(new Set(optionKeys).size!==4 || !MCQ_KEYS.every(x=>optionKeys.includes(x))) fail(`${key}: option keys must be A/B/C/D`);
    if(!MCQ_KEYS.includes(q.correct_answer)) fail(`${key}: invalid correct_answer`);

    const seen={en:new Set(),ru:new Set(),uz:new Set()};
    for(const o of q.options){
      mustText(o.text,`option_${o.key}`,key);
      for(const lang of LANGS){
        const n=normText(o.text?.[lang]);
        if(seen[lang].has(n)) fail(`${key}: duplicate ${lang} option text`);
        seen[lang].add(n);
      }
      const correct=o.key===q.correct_answer;
      if(correct && o.diagnostic_code) fail(`${key}: correct option carries diagnostic`);
      if(!correct && !o.diagnostic_code) fail(`${key}: wrong option missing diagnostic`);
      if(o.diagnostic_code && !catalogCodes.has(o.diagnostic_code)) fail(`${key}: unknown diagnostic ${o.diagnostic_code}`);
      if(o.diagnostic_code && catalogSkill.get(o.diagnostic_code)!==q.primary_skill) fail(`${key}: diagnostic skill mismatch ${o.diagnostic_code}`);
    }

    correctLetters[q.correct_answer]+=1;
    correctSequence+=q.correct_answer;
    perSkillLetters[q.primary_skill] ||= {A:0,B:0,C:0,D:0,n:0};
    perSkillLetters[q.primary_skill][q.correct_answer]+=1;
    perSkillLetters[q.primary_skill].n+=1;
  }

  if(q.qtype==='input'){
    if(q.correct_answer != null) fail(`${key}: input must use answer_contract`);
    if(!isObject(q.answer_contract)){ fail(`${key}: input missing answer_contract`); continue; }
    const ac=q.answer_contract;
    if(!['integer_exact','numeric_exact'].includes(ac.kind)) fail(`${key}: unsupported input contract ${ac.kind}`);
    if(typeof ac.canonical_answer!=='string' || !ac.canonical_answer.trim()) fail(`${key}: missing canonical_answer`);
    if(ac.number_only!==true) fail(`${key}: input must be number_only=true`);
    if(!Array.isArray(ac.accepted_examples) || ac.accepted_examples.length<2) fail(`${key}: accepted_examples too small`);
    if(!Array.isArray(ac.rejected_examples) || ac.rejected_examples.length<2) fail(`${key}: rejected_examples too small`);

    const accepted=new Set((ac.accepted_examples||[]).map(normAnswer));
    const rejected=new Set((ac.rejected_examples||[]).map(normAnswer));
    if(!accepted.has(normAnswer(ac.canonical_answer))) fail(`${key}: canonical not represented in accepted_examples`);
    for(const v of accepted) if(rejected.has(v)) fail(`${key}: accepted/rejected overlap ${v}`);

    for(const rule of q.diagnostic_rules || []){
      if(!rule.answer_match || !rule.diagnostic_code){ fail(`${key}: malformed diagnostic rule`); continue; }
      if(!catalogCodes.has(rule.diagnostic_code)) fail(`${key}: unknown input diagnostic ${rule.diagnostic_code}`);
      if(catalogSkill.get(rule.diagnostic_code)!==q.primary_skill) fail(`${key}: input diagnostic skill mismatch ${rule.diagnostic_code}`);
      if(normAnswer(rule.answer_match)===normAnswer(ac.canonical_answer)) fail(`${key}: diagnostic rule matches correct answer`);
    }
  }
}

if(questions.length!==EXPECTED.total) fail(`Practice 5 total expected ${EXPECTED.total}, got ${questions.length}`);
for(const [skill,expected] of Object.entries(EXPECTED.skills)) if((skillCounts[skill]||0)!==expected) fail(`${skill}: expected ${expected}, got ${skillCounts[skill]||0}`);
for(const [qt,expected] of Object.entries(EXPECTED.qtype)) if((qtypeCounts[qt]||0)!==expected) fail(`${qt}: expected ${expected}, got ${qtypeCounts[qt]||0}`);
for(const [d,band] of Object.entries(EXPECTED.difficultyBand)){
  const actual=difficultyCounts[d]||0;
  if(actual<band[0] || actual>band[1]) fail(`${d}: count ${actual} outside ${band[0]}-${band[1]}`);
}
for(const l of MCQ_KEYS){
  const actual=correctLetters[l], [lo,hi]=EXPECTED.correctLetterBand;
  if(actual<lo || actual>hi) fail(`correct-option distribution ${l}=${actual}, expected ${lo}-${hi}`);
}

let maxRun=0,run=0,prev='';
for(const l of correctSequence){
  if(l===prev) run+=1; else {prev=l;run=1;}
  maxRun=Math.max(maxRun,run);
}
if(maxRun>EXPECTED.maxSameCorrectRun) fail(`correct-option run ${maxRun} > ${EXPECTED.maxSameCorrectRun}`);

for(const [skill,dist] of Object.entries(perSkillLetters)){
  if(dist.n>=5){
    for(const l of MCQ_KEYS){
      if(dist[l]/dist.n>0.4+1e-9) fail(`${skill}: correct letter ${l} dominates ${dist[l]}/${dist.n}`);
    }
  }
}
for(const pattern of ['ABCDABCD','BCDABCDA','CDABCDAB','DABCDABC']){
  if(correctSequence.includes(pattern)) fail(`correct-option sequence contains obvious cycle ${pattern}`);
}

const summary={
  questions:questions.length,
  skillCounts,qtypeCounts,difficultyCounts,correctLetters,
  maxSameCorrectRun:maxRun,
  diagnosticCodesInCatalog:catalogCodes.size,
  errors:errors.length,warnings:warnings.length
};
console.log(JSON.stringify(summary,null,2));
for(const m of warnings) console.warn(`WARN: ${m}`);
for(const m of errors) console.error(`ERROR: ${m}`);
if(errors.length) process.exit(1);
