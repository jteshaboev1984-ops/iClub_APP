#!/usr/bin/env node
'use strict';
// Private source files are supplied by the owner at runtime; NEVER commit or log
// question text, options, explanations or answer keys in this public repository.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const assert=require('node:assert/strict');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
function stable(x){
  if(Array.isArray(x))return '['+x.map(stable).join(',')+']';
  if(x&&typeof x==='object')return '{'+Object.keys(x).sort().map(k=>JSON.stringify(k)+':'+stable(x[k])).join(',')+'}';
  return JSON.stringify(x);
}
const canonical=x=>sha(Buffer.from(stable(x),'utf8'));
const read=p=>JSON.parse(fs.readFileSync(p,'utf8'));
function validate(p1Path,p3Path,privateSourcesDir){
  const paths=[p1Path,p3Path],banks=paths.map(read);
  const specs=[
    {paper:'P1',n:30,units:{1:6,2:6,3:6,4:6,5:3,6:3}},
    {paper:'P3',n:12,units:{7:3,8:3,9:2,10:2,11:2}}
  ];
  const ids=new Set(),stems=new Set(),papers=[];
  let historicHashAudited=0;
  for(let i=0;i<2;i++){
    const bank=banks[i],s=specs[i],units={};
    assert.equal(bank.paper_code,s.paper);
    assert.equal(bank.program_key,'economics_9708');
    assert.equal(bank.version_key,'economics_2026_2028_v1');
    assert.equal(bank.release_enabled,false,'released bank cannot be used as a draft');
    assert.equal(bank.ready_for_server_authorization,false,'unapproved server release');
    assert.equal(bank.ready_for_public_exam,false,'unapproved public release');
    assert(Array.isArray(bank.items)&&bank.items.length===s.n,'wrong item count');
    if(bank.target_item_count!==undefined)assert.equal(bank.target_item_count,12);
    if(bank.session_kind_target!==undefined)assert.equal(bank.session_kind_target,'diagnostic');
    for(const item of bank.items){
      assert(typeof item.item_key==='string'&&/^[A-Za-z0-9_-]+$/.test(item.item_key),'invalid item key');
      assert(!ids.has(item.item_key),'duplicate item key between papers');
      ids.add(item.item_key);
      assert(/^\d+\.\d+\.\d+$/.test(item.syllabus_point),'bad syllabus point');
      const unit=item.syllabus_point.split('.')[0];
      assert(Object.hasOwn(s.units,unit),'wrong AS/A syllabus unit');
      units[unit]=(units[unit]||0)+1;
      assert(item.skill_key?.startsWith('ECON-9708-'+item.syllabus_point+'-'),'wrong skill mapping');
      assert(/^[ABCD]$/.test(item.correct_answer),'bad answer label');
      for(const loc of ['en','ru','uz']){
        const x=item[loc];
        assert(x&&typeof x.question==='string'&&x.question.trim().length>=12,'missing question');
        assert(typeof x.explanation==='string'&&x.explanation.trim().length>=15,'missing explanation');
        assert(Array.isArray(x.options)&&x.options.length===4,'missing options');
        assert(x.options.every(y=>typeof y==='string'&&y.trim()),'empty option');
        assert(new Set(x.options.map(y=>y.trim())).size===4,'duplicate options');
      }
      const stem=item.en.question.trim().toLowerCase();
      assert(!stems.has(stem),'duplicate English stem across candidate banks');
      stems.add(stem);
      const canon=canonical(Object.fromEntries(Object.entries(item).filter(([k])=>k!=='review_hash_sha256')));
      if(item.review_hash_sha256!==canon){
        assert(i===0&&bank.audit_canonical_item_sha256?.[item.item_key]===canon,
          'historic hash must have separately verified canonical digest');
        historicHashAudited++;
      }
    }
    assert.deepEqual(units,Object.fromEntries(Object.entries(s.units).map(([k,v])=>[k,v])),'wrong syllabus quotas');
    const contentHash=canonical(bank.items);
    if(i===0)assert.equal(bank.content_sha256,contentHash,'P1 items digest drift');
    else assert(/^[a-f0-9]{64}$/.test(bank.content_sha256),'P3 historical digest invalid');
    papers.push({paper:s.paper,items:s.n,locales:s.n*3,options:s.n*12,
      units,canonical_items_sha256:contentHash,source_bytes_sha256:sha(fs.readFileSync(paths[i]))});
  }
  if(privateSourcesDir){
    const p1=banks[0],p3=banks[1];
    const refs=[...p1.original_source_files.map(x=>({file:x.name,hash:x.sha256,dir:privateSourcesDir})),
      {file:p1.new_gapfill_file.name,hash:p1.new_gapfill_file.sha256,dir:path.dirname(p1Path)},
      ...p3.original_source_files.map(x=>({file:x.filename,hash:x.sha256,dir:privateSourcesDir}))];
    for(const ref of refs){
      assert(ref.file===path.basename(ref.file),'invalid relative source name');
      assert.equal(sha(fs.readFileSync(path.join(ref.dir,ref.file))),ref.hash,'original source file changed');
    }
    for(const result of papers)result.original_source_bytes_checked=true;
  }
  return {
    status:'PASS_PRIVATE_STRUCTURE_NOT_ACADEMIC_RELEASE',
    total_items:42,total_locales:126,total_options:504,
    historic_item_digests_independently_rechecked:historicHashAudited,
    independently_new_retest_bank_ready:false,
    production_release_authorized:false,papers
  };
}
if(require.main===module){
  try{
    const args=process.argv.slice(2);
    if(args.length<2||args.length>3)throw Error('Usage: node qa-economics-private-originals-v1.cjs /private/P1.json /private/P3.json [/private/original-sources]');
    console.log(JSON.stringify(validate(...args),null,2));
  }catch(error){
    // Only status/error category, never the protected question payload.
    console.error('PRIVATE ECONOMICS SOURCE QA FAILED: '+String(error.message).slice(0,160));
    process.exitCode=1;
  }
}
module.exports={validate,canonical,stable};
