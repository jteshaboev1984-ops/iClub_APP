#!/usr/bin/env node
'use strict';
// Source-only staging SQL generator for EXACTLY 81 Mathematics P1 question
// versions. SQL contains protected content/keys: never commit or print it.
// Never invokes PostgreSQL, Supabase or a paid provider.
// Academic QA is explicitly pending; stage != publish != owner authorization.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),bank=path.join(root,'content/math/practice_v2');
const patchRelease='math_p1_practice_v2_fix_20261120',suffix='-V20261120';
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const guard=read('scripts/math-practice-v2-editorial-future-only-contract.cjs');
const pin=read('supabase/preflight/math_practice_v2_81_future_only_hash_pin_readonly.sql');
const m=guard.match(/const FUTURE_VERSION_REQUIRED = new Set\(\[([\s\S]*?)\]\)/);
assert.ok(m,'Missing immutable version set');
const IDs=m[1].split(',').map(x=>+x.trim()).sort((a,b)=>a-b);
assert.equal(IDs.length,81);assert.equal(new Set(IDs).size,81);
const pinRows=[...pin.matchAll(/\((\d+)::bigint,'([a-f0-9]{64})'::text\)/g)].map(x=>[+x[1],x[2]]);
assert.equal(pinRows.length,81);
const expected=new Map(pinRows);assert.deepEqual([...expected.keys()],IDs);
const stable=x=>Array.isArray(x)?x.map(stable):x&&typeof x==='object'?
 Object.fromEntries(Object.keys(x).sort().map(k=>[k,stable(x[k])])):x;
const sha=x=>crypto.createHash('sha256').update(JSON.stringify(stable(x))).digest('hex');
const byId=new Map();
const cats=new Map();
for(const dir of fs.readdirSync(bank,{withFileTypes:true}).filter(d=>d.isDirectory())){
 const folder=path.join(bank,dir.name);
 const catalogPath=path.join(folder,'diagnostic_catalog.json');
 const catalog=JSON.parse(fs.readFileSync(catalogPath,'utf8'));
 for(const d of catalog.diagnostics||[]){if(cats.has(d.code))throw Error('duplicate diagnostic code');cats.set(d.code,d);}
 for(const file of fs.readdirSync(folder).filter(f=>/^P1-[A-Z]{3}-\d{2}\.json$/.test(f))){
  const data=JSON.parse(fs.readFileSync(path.join(folder,file),'utf8'));
  for(const q of data.questions){
   const match=/^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(q.key);assert.ok(match,'unknown key');
   const id=7484+Number(match[1]);
   if(byId.has(id))throw Error('duplicate authored ID');
   byId.set(id,q);
  }
 }
}
assert.equal(byId.size,495);
const payload=[];
for(const id of IDs){
 const q=byId.get(id);
 assert.ok(q);
 assert.ok(['easy','medium','hard'].includes(q.difficulty)&&['input','mcq'].includes(q.qtype));
 assert.ok(q.source_ref&&q.role&&q.primary_skill&&q.practice_no>=1&&q.practice_no<=7);
 for(const l of ['en','ru','uz'])assert.ok(q.question[l]&&q.explanation[l]);
 const options=q.qtype==='mcq'?[...q.options].sort((a,b)=>a.key.localeCompare(b.key)):[];
 if(q.qtype==='mcq'){
  assert.deepEqual(options.map(x=>x.key),['A','B','C','D']);
  assert.ok(options.some(x=>x.key===q.correct_answer));
 }
 const diagnostics=[];
 if(q.qtype==='mcq'){
  for(const opt of options.filter(x=>x.key!==q.correct_answer)){
   assert.ok(cats.has(opt.diagnostic_code));
   diagnostics.push({code:opt.diagnostic_code,answer_kind:'mcq_option',answer_key:opt.key,answer_value:null});
  }
 }else{
  assert.equal(q.answer_contract.number_only,true);
  assert.ok(q.answer_contract.canonical_answer);
  for(const rule of q.diagnostic_rules||[]){
   assert.ok(cats.has(rule.diagnostic_code));
   diagnostics.push({code:rule.diagnostic_code,answer_kind:'input_exact',answer_key:null,answer_value:String(rule.answer_match)});
  }
 }
 const obj={
  old_id:id,old_hash:expected.get(id),old_key:q.key,
  new_key:q.key+suffix,release_version:patchRelease,
  practice_no:q.practice_no,skill:q.primary_skill,role:q.role,source_ref:q.source_ref,
  difficulty:q.difficulty,qtype:q.qtype,
  text:q.question,explanation:q.explanation,
  options:q.qtype==='mcq'?Object.fromEntries(['en','ru','uz'].map(l=>[l,JSON.stringify(options.map(o=>o.text[l]))])):null,
  correct_answer:q.qtype==='mcq'?q.correct_answer:q.answer_contract.canonical_answer,
  time_limit_sec:q.difficulty==='hard'?90:q.difficulty==='medium'?60:45,
  answer_contract:q.qtype==='input'?q.answer_contract:{},diagnostics,
 };
 obj.new_hash=sha(obj);
 assert.notEqual(obj.new_hash,obj.old_hash);
 payload.push(obj);
}
const json=JSON.stringify(payload);
const pgQuote=t=>"'"+t.replace(/'/g,"''")+"'";
const sql=[
'-- GENERATED STAGING-ONLY Mathematics Practice future-only versions.',
'-- DO NOT COMMIT GENERATED SQL: contains private questions/options/keys.',
'-- Do not run on hosted Supabase without separate owner approval.',
'-- No academic QA is granted: all new QA flags remain PENDING.',
'-- No active pool membership, old question or learner records modified.',
'begin;',
'do $math_patch_stage$',
'declare',
' v_items jsonb := '+pgQuote(json)+'::jsonb;',
' v_item jsonb;',
' v_old public.questions%rowtype;',
' v_old_m private.practice_v2_question_meta%rowtype;',
' v_old_link public.practice_pool_questions%rowtype;',
' v_new_id bigint;',
' v_diag jsonb;',
' v_cat private.practice_v2_diagnostic_catalog%rowtype;',
' v_count integer:=0;',
'begin',
" perform pg_advisory_xact_lock(hashtext('math_practice_v2_release')::bigint);",
' if jsonb_array_length(v_items)<>81 then raise exception '+pgQuote('staging_wrong_size')+'; end if;',
' for v_item in select value from jsonb_array_elements(v_items) loop',
"  select * into v_old from public.questions where id=(v_item->>'old_id')::bigint for update;",
"  select * into v_old_m from private.practice_v2_question_meta where question_id=v_old.id for update;",
'  if v_old.id is null or v_old.subject_id<>5 or v_old.is_active is not true',
"    or v_old.quality_status<>'published' or v_old_m.lifecycle_state<>'published'",
"    or v_old_m.is_runtime_allowed is not true or v_old_m.content_key<>v_item->>'old_key'",
"    or v_old_m.content_hash<>v_item->>'old_hash' or v_old_m.practice_no<>(v_item->>'practice_no')::smallint",
"    or v_old_m.primary_skill_code<>v_item->>'skill' or v_old_m.question_role<>v_item->>'role'",
"    or v_old.qtype<>v_item->>'qtype' then",
"     raise exception 'published_old_version_mismatch'; end if;",
'  select ppq.* into v_old_link from public.practice_pool_questions ppq',
'   join public.practice_pools p on p.id=ppq.pool_id',
'   where ppq.question_id=v_old.id and ppq.is_active=true',
'     and p.is_active=true and p.subject_id=5',
"     and p.tour_no=(v_item->>'practice_no')::smallint for update of ppq;",
"  if not found then raise exception 'old_published_pool_missing'; end if;",
'  if exists(select 1 from public.tour_questions where question_id=v_old.id)',
"    or exists(select 1 from private.practice_v2_question_meta where content_key=v_item->>'new_key')",
'    or exists(select 1 from public.question_version_links',
"      where old_question_id=v_old.id and link_type='replacement') then",
"    raise exception 'protected_or_already_versioned'; end if;",
'  insert into public.questions(',
'    subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,',
'    correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,',
'    question_text_en,options_text_ru,options_text_uz,options_text_en,',
'    explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_status',
'  ) values(',
'    5,v_old.topic,v_old.subtopic,v_item->>\'difficulty\',v_item->>\'qtype\',',
'    v_item #>> \'{text,en}\',v_item #>> \'{options,en}\',v_item->>\'correct_answer\',',
'    v_item #>> \'{explanation,en}\',null,false,',
'    v_item #>> \'{text,ru}\',v_item #>> \'{text,uz}\',v_item #>> \'{text,en}\',',
'    v_item #>> \'{options,ru}\',v_item #>> \'{options,uz}\',v_item #>> \'{options,en}\',',
'    v_item #>> \'{explanation,ru}\',v_item #>> \'{explanation,uz}\',v_item #>> \'{explanation,en}\',',
'    v_old.book_ref,(v_item->>\'time_limit_sec\')::integer,\'draft\')',
'  returning id into v_new_id;',
'  insert into private.practice_v2_question_meta(',
'    question_id,content_key,release_version,practice_no,primary_skill_code,',
'    secondary_skill_codes,question_role,source_ref,answer_contract,content_hash,',
'    qa_math_status,qa_language_status,qa_technical_status,qa_tour_separation_status,',
'    lifecycle_state,is_runtime_allowed)',
'  values(v_new_id,v_item->>\'new_key\',v_item->>\'release_version\',',
'    (v_item->>\'practice_no\')::smallint,v_item->>\'skill\',v_old_m.secondary_skill_codes,',
'    v_item->>\'role\',v_item->>\'source_ref\',v_item->\'answer_contract\',',
'    v_item->>\'new_hash\',\'pending\',\'pending\',\'pending\',\'pending\',',
'    \'approved\',false);',
'  insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)',
'  values(v_old_link.pool_id,v_new_id,v_old_link.order_no,false);',
'  for v_diag in select value from jsonb_array_elements(v_item->\'diagnostics\') loop',
'    select * into v_cat from private.practice_v2_diagnostic_catalog',
'      where diagnostic_code=v_diag->>\'code\' and is_runtime_allowed=true',
'        and approval_status=\'approved\';',
'    if not found then raise exception \'diagnostic_catalog_unavailable\'; end if;',
'    insert into public.question_answer_diagnostics(',
'     question_id,answer_kind,answer_key,answer_value,is_correct,mistake_type,weak_skill,',
'     feedback_ru,feedback_uz,feedback_en,next_action_ru,next_action_uz,next_action_en,',
'     rule_json,quality_status)',
'    values(v_new_id,v_diag->>\'answer_kind\',v_diag->>\'answer_key\',',
'      v_diag->>\'answer_value\',false,v_cat.mistake_type,v_cat.skill_code,',
'      v_cat.feedback_ru,v_cat.feedback_uz,v_cat.feedback_en,',
'      v_cat.next_action_ru,v_cat.next_action_uz,v_cat.next_action_en,',
'      jsonb_build_object(\'diagnostic_code\',v_diag->>\'code\',',
'      \'inference_strength\',v_cat.inference_strength,',
'      \'release_version\',v_item->>\'release_version\'),\'draft\');',
'  end loop;',
'  v_count:=v_count+1;',
' end loop;',
' if v_count<>81 then raise exception \'staged_count_wrong\'; end if;',
'end;',
'$math_patch_stage$;',
'commit;'
].join('\n')+'\n';
const args=process.argv.slice(2),outIdx=args.indexOf('--out');
if(outIdx>=0){
 const output=args[outIdx+1];assert.ok(output,'--out needs an output file');
 const file=path.resolve(process.cwd(),output);
 // Never print or expose the generated file in any PR/CI artifact.
 fs.writeFileSync(file,sql,{encoding:'utf8',flag:'wx',mode:0o600});
}
console.log(JSON.stringify({candidate_count:payload.length,old_published_versions_pinned:expected.size,
 candidate_manifest_sha256:sha(payload.map(x=>({id:x.old_id,old_hash:x.old_hash,new_hash:x.new_hash}))),
 staging_sql_output_written:outIdx>=0,qa_status:'PENDING',active_memberships_changed:0,
 published_questions_changed:0,production_writes:0}));
