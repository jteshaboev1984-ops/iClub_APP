#!/usr/bin/env node
'use strict';
// Source-only, read-only history-safe gate for Math Practice v2's 103 governed candidate corrections.
// No database access, answer-key output, generation bump or automatic publication.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { spawnSync } = require('node:child_process');

const BASE = process.env.MATH_PRACTICE_EDITORIAL_BASE_SHA ||
  'f30adcd4b6b4cbc230fa375418e5aa56f95e49d2';
if (!/^[0-9a-f]{40}$/.test(BASE)) throw new Error('Invalid pinned source baseline SHA');

const ROOT = path.resolve(__dirname, '..');
const BANK = path.join(ROOT, 'content/math/practice_v2');
const EXPECTED_IDS = new Set([7506,7553,7555,7556,7558,7559,7562,7565,7569,7570,7573,7581,7586,7587,7590,7591,7593,7594,7597,7598,7599,7618,7642,7644,7645,7652,7653,7654,7662,7672,7673,7686,7699,7708,7710,7714,7716,7717,7724,7726,7727,7736,7737,7745,7746,7747,7754,7761,7762,7763,7764,7765,7774,7776,7777,7796,7799,7809,7812,7813,7814,7818,7828,7829,7835,7838,7840,7841,7842,7850,7851,7860,7861,7862,7863,7873,7890,7892,7893,7894,7900,7901,7910,7923,7924,7925,7926,7927,7928,7929,7930,7941,7948,7949,7950,7951,7953,7955,7956,7965,7970,7977,7979]);
const FUTURE_VERSION_REQUIRED = new Set([7573,7618,7642,7644,7645,7652,7653,7654,7662,7672,7673,7686,7699,7708,7716,7717,7724,7726,7736,7737,7745,7746,7747,7762,7763,7764,7765,7774,7776,7777,7799,7812,7813,7814,7828,7829,7840,7841,7842,7850,7851,7860,7861,7862,7863,7873,7890,7892,7893,7894,7901,7910,7923,7924,7925,7926,7927,7928,7929,7930,7941,7948,7949,7950,7951,7953,7955,7956,7970,7977,7979]);
const HISTORY_SENSITIVE = new Set([7710,7714,7726,7754,7923,7925,7927,7929,7930,7941,7949,7951,7955,7956,7970,7977]);
const ADDITIONAL_DIFFICULTY_CORRECTIONS = new Map([[7662,"medium"],[7672,"medium"],[7673,"easy"],[7699,"medium"],[7708,"medium"],[7716,"easy"],[7717,"medium"],[7724,"medium"],[7726,"medium"],[7736,"medium"],[7737,"medium"],[7745,"medium"],[7746,"medium"],[7747,"medium"],[7762,"medium"],[7763,"medium"],[7764,"medium"],[7765,"medium"],[7774,"medium"],[7776,"medium"],[7777,"medium"],[7799,"medium"]]);
const FURTHER_DIFFICULTY_CORRECTIONS = new Map([[7812,"medium"],[7813,"medium"],[7814,"medium"],[7828,"medium"],[7829,"medium"],[7840,"medium"],[7841,"easy"],[7842,"medium"],[7850,"medium"],[7851,"medium"],[7860,"medium"],[7861,"medium"],[7862,"medium"],[7863,"medium"],[7873,"medium"],[7890,"medium"],[7892,"easy"],[7893,"medium"],[7894,"medium"],[7901,"medium"]]);
const INTEGRATION_DIFFICULTY_CORRECTIONS = new Map([[7910,"medium"],[7923,"easy"],[7924,"medium"],[7925,"medium"],[7926,"medium"],[7927,"medium"],[7928,"medium"],[7929,"medium"],[7930,"medium"]]);
const LAST_BLOCK_DIFFICULTY_CORRECTIONS = new Map([[7941,"medium"],[7948,"easy"],[7949,"easy"],[7950,"medium"],[7951,"medium"],[7953,"medium"],[7955,"medium"],[7956,"medium"],[7970,"medium"],[7977,"easy"],[7979,"medium"]]);
const OPTION_TEXT_ALLOWED = new Map([
  [7559,new Set(['options.3.text.uz'])],
  [7573,new Set(['options.3.text.en','options.3.text.ru','options.3.text.uz'])]
]);
const errors = [];
const output = [];
const perPool = Array(7).fill(0);
const allKeys = new Set();
let input = 0, mcq = 0, skillFiles = 0, checked = 0;

function equals(a,b) { return JSON.stringify(a) === JSON.stringify(b); }
function normalize(v) {
  if (Array.isArray(v)) return v.map(normalize);
  if (v && typeof v === 'object') {
    return Object.fromEntries(Object.keys(v).sort().map(k => [k,normalize(v[k])]));
  }
  return v;
}
function digest(v) {
  return crypto.createHash('sha256').update(JSON.stringify(normalize(v))).digest('hex');
}
function changedPaths(before,after,prefix='',out=[]) {
  if (equals(before,after)) return out;
  if (before && after && typeof before==='object' && typeof after==='object' &&
      Array.isArray(before) === Array.isArray(after)) {
    const keys = new Set([...Object.keys(before),...Object.keys(after)]);
    for (const key of keys) changedPaths(before[key],after[key],
      prefix ? prefix+'.'+key : key,out);
  } else out.push(prefix);
  return out;
}
function baselineFile(rel) {
  const r = spawnSync('git',['show',BASE+':'+rel],{
    cwd:ROOT,encoding:'utf8',maxBuffer:4*1024*1024
  });
  if (r.status !== 0) throw new Error('Unable to read pinned baseline: '+rel);
  return JSON.parse(r.stdout);
}
function itemNumber(key) {
  const m = /^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(key||'');
  return m ? Number(m[1]) : 0;
}
const folders = fs.readdirSync(BANK,{withFileTypes:true})
  .filter(d=>d.isDirectory()).map(d=>d.name).sort();
for (const folder of folders) {
  const dir=path.join(BANK,folder);
  const files=fs.readdirSync(dir).filter(f=>/^P1-[A-Z]{3}-\d{2}\.json$/.test(f)).sort();
  for(const file of files) {
    skillFiles++;
    const rel='content/math/practice_v2/'+folder+'/'+file;
    const old=baselineFile(rel), current=JSON.parse(fs.readFileSync(path.join(dir,file),'utf8'));
    if(!equals({...old,questions:null},{...current,questions:null}))
      errors.push('File-level metadata changed outside question payload: '+file);
    const oldItems=old.questions||[],newItems=current.questions||[];
    if(oldItems.length!==newItems.length)errors.push('Question count changed in '+file);
    const oldByKey=new Map(oldItems.map(q=>[q.key,q]));
    if(oldByKey.size!==oldItems.length)errors.push('Baseline duplicate key in '+file);
    for(const q of newItems){
      checked++;
      const n=itemNumber(q.key),id=7484+n;
      if(!n||n>495||allKeys.has(q.key))errors.push('Invalid/duplicate item index '+n);
      allKeys.add(q.key);
      const before=oldByKey.get(q.key);
      if(!before){errors.push('No baseline for item '+id);continue;}
      const pool=Number(q.practice_no);
      if(!Number.isInteger(pool)||pool<1||pool>7)errors.push('Invalid pool for item '+id);
      else perPool[pool-1]++;
      if(q.qtype==='input')input++;
      else if(q.qtype==='mcq')mcq++;
      else errors.push('Unsupported answer type for item '+id);
      const paths=changedPaths(before,q);
      if(!paths.length)continue;
      const permitted=OPTION_TEXT_ALLOWED.get(id)||new Set();
      for(const p of paths){
        if(/^question\.(en|ru|uz)$/.test(p) || p==='explanation.uz' || (id===7965 && /^explanation\.(en|ru)$/.test(p)) || (id===7618 && ['difficulty','role'].includes(p)) || ([7642,7644,7645,7652,7653,7654].includes(id)&&p==='difficulty') || (ADDITIONAL_DIFFICULTY_CORRECTIONS.has(id)&&p==='difficulty') || (FURTHER_DIFFICULTY_CORRECTIONS.has(id)&&p==='difficulty') || (INTEGRATION_DIFFICULTY_CORRECTIONS.has(id)&&p==='difficulty') || (LAST_BLOCK_DIFFICULTY_CORRECTIONS.has(id)&&p==='difficulty') || permitted.has(p)) continue;
        errors.push('Unreviewed/semantic payload change at item '+id+' field '+p);
      }
      if([7562,7565,7569,7570].includes(id)){
        if(!String(q.question?.en||'').includes('exact range') ||
           !String(q.question?.ru||'').includes('точно задаёт область значений') ||
           !String(q.question?.uz||'').includes('qiymatlar to‘plamini aynan ifodalaydi'))
          errors.push('Exact-range trilingual stem contract failed for item '+id);
      }
      const calibrated = new Map([[7642,'easy'],[7644,'medium'],[7645,'medium'],[7652,'medium'],[7653,'easy'],[7654,'easy']]);
      if(calibrated.has(id) && (q.difficulty!==calibrated.get(id) || paths.length!==1 || paths[0]!=='difficulty'))
        errors.push('Unexpected reasoning-demand calibration payload at '+id);
      if(ADDITIONAL_DIFFICULTY_CORRECTIONS.has(id) && (q.difficulty!==ADDITIONAL_DIFFICULTY_CORRECTIONS.get(id)||paths.length!==1||paths[0]!=='difficulty'))
        errors.push('Only approved Q difficulty change permitted: '+id);
      if(FURTHER_DIFFICULTY_CORRECTIONS.has(id)){
        const permittedPaths = new Set(id===7829||id===7894 ? ['difficulty','question.en','question.ru','question.uz'] : ['difficulty']);
        if(q.difficulty!==FURTHER_DIFFICULTY_CORRECTIONS.get(id) || !paths.includes('difficulty') || paths.some(p=>!permittedPaths.has(p)))
          errors.push('Unapproved new difficulty payload at '+id);
      }
      if(INTEGRATION_DIFFICULTY_CORRECTIONS.has(id) && (q.difficulty!==INTEGRATION_DIFFICULTY_CORRECTIONS.get(id)||paths.length!==1||paths[0]!=='difficulty'))
        errors.push('Unauthorized integration difficulty change '+id);
      if(LAST_BLOCK_DIFFICULTY_CORRECTIONS.has(id) && (q.difficulty!==LAST_BLOCK_DIFFICULTY_CORRECTIONS.get(id)||paths.length!==1||paths[0]!=='difficulty'))
        errors.push('Unapproved final block difficulty edit '+id);
      if(id===7618 && (q.difficulty!=='easy' || q.role!=='representation_variation'))
        errors.push('Q134 difficulty/role academic calibration drift');
      if(id===7965){
        for(const lang of ['en','ru','uz']){
          if(!String(q.explanation?.[lang]||'').includes('√(36−24)') ||
             String(q.explanation[lang]).includes('√36−24'))
            errors.push('Missing grouped discriminant in '+lang+' explanation at '+id);
        }
        // Independently verify the quadratic formula's roots satisfy x²−6x+6=0.
        for(const sign of [-1,1]){
          const root=(6+sign*Math.sqrt(36-24))/2;
          if(Math.abs(root*root-6*root+6)>1e-10)
            errors.push('Quadratic root proof failed at '+id);
        }
      }
      if(!EXPECTED_IDS.has(id))errors.push('Unapproved question edited: '+id);
      if(FUTURE_VERSION_REQUIRED.has(id)&&!paths.some(p=>p.startsWith('options.')||p.startsWith('question.')||p==='difficulty'||(id===7618&&p==='role')))
        errors.push('Versioned question change missing: '+id);
      output.push({id,category:FUTURE_VERSION_REQUIRED.has(id)?'future_version_required':'editorial_equal_key',
        old_sha256:digest(before),new_sha256:digest(q),
        history_sensitive:HISTORY_SENSITIVE.has(id)});
    }
  }
}
const actual=new Set(output.map(o=>o.id));
for(const id of EXPECTED_IDS)if(!actual.has(id))errors.push('Expected correction missing: '+id);
if(checked!==495||allKeys.size!==495||skillFiles!==45)
  errors.push('Coverage must remain 495 questions / 45 skill files');
if(input!==218||mcq!==277)errors.push('Answer-type totals changed');
if(!equals(perPool,[68,80,68,77,66,70,66]))errors.push('Pool membership counts changed');
if(output.length!==103||actual.size!==103)errors.push('Exactly 103 distinct approved edits required');
if(output.filter(x=>x.category==='future_version_required').length!==71)
  errors.push('71 substantive / timing-changing items require future-only versioning');
if(output.filter(x=>x.history_sensitive).length!==16)
  errors.push('Sixteen history-bearing changed items must preserve existing answers');
if(errors.length){
  console.error('Math Practice editorial source contract FAILED: '+errors.length+' finding(s)');
  for(const err of errors)console.error(err);
  process.exit(1);
}
const summary = {
  source_baseline:BASE,questions:checked,skill_files:skillFiles,
  mcq,input,practice_pool_sizes:perPool,
  unchanged:checked-output.length,edited:output.length,
  editorial_equal_key:32,future_version_required:71,
  history_sensitive_candidates:16,
  changed_id_set_sha256:digest(output.map(x=>x.id).sort((a,b)=>a-b)),
  // Only digests, item IDs and classification; never print stems, answers or keys.
  edited_manifest:output.sort((a,b)=>a.id-b.id)
};
console.log(JSON.stringify(summary,null,2));
