#!/usr/bin/env node
'use strict';
// #574: stage ONLY corrected author versions 7791,7881 in private ephemeral
// SQL. This follows already tested #599 future-only staging contract.
// NEVER commit the generated SQL or execute on hosted Supabase without the
// owner-approved cutover. Does not grant academic QA or publish any question.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const release='math_p1_practice_v2_fix_20261120',suffix='-V20261120';
const args=process.argv.slice(2);
const modeAt=args.indexOf('--group');
const mode=modeAt>=0?args[modeAt+1]:'editorial';
const approvedGroups={
 editorial:[
  {id:7791,code:'P1-SER-01',file:'p5_binomial_series/P1-SER-01.json',
   old_hash:'0356f12e2932059bae0ab896c3010a8a117786984ee4b0dcfbbafbef600e7423'},
  {id:7881,code:'P1-DIF-04',file:'p6_differentiation/P1-DIF-04.json',
   old_hash:'71c936e246749a02c721865fa3517e6c7fa8862e1f983ee79ac32cc2b5d3fa7d'}
 ],
 answer_pattern:[
  {id:7624,code:'P1-FUN-08',file:'p2_functions/P1-FUN-08.json',
   old_hash:'b0ccf462b7bafa14abfcf88940a4a5a878b96ec0b7a4a161b558ea812fdb0d67'},
  {id:7797,code:'P1-SER-02',file:'p5_binomial_series/P1-SER-02.json',
   old_hash:'59930cdbdf3aa2703722ab60c4921a9e5719d7176168458bf3ff9c9269656cec'},
  {id:7937,code:'P1-INT-02',file:'p7_integration/P1-INT-02.json',
   old_hash:'43349ae00988b83dc61d827318d6d2b50c7940d1f9a698686ce2887bf3031985'}
 ]
};
// Exactly the 31 earlier mathematics-editorial equal-key corrections.
// Owner requires that even text-only edits with prior answers never overwrite
// the published question; all 31 stage as NEW inactive question IDs.
function editorial31SourceSpecs(){
 const contract=fs.readFileSync(path.join(root,
   'scripts/math-practice-v2-editorial-future-only-contract.cjs'),'utf8');
 function readSet(name){
  const match=contract.match(new RegExp('const '+name+' = new Set\\(\\[([^\\]]+)\\]\\)'));
  assert.ok(match,'missing canonical 112/81 source manifest');
  return new Set(match[1].split(',').map(x=>Number(x.trim())));
 }
 const all=readSet('EXPECTED_IDS'),substantive=readSet('FUTURE_VERSION_REQUIRED');
 assert.equal(all.size,112);assert.equal(substantive.size,81);
 const ids=[...all].filter(id=>!substantive.has(id)).sort((a,b)=>a-b);
 assert.equal(ids.length,31);
 const pin=fs.readFileSync(path.join(root,
   'supabase/preflight/math_practice_v2_31_editorial_contenthash_pin_readonly.sql'),'utf8');
 const pins=[...pin.matchAll(/\((\d+)::bigint,'([a-f0-9]{64})'::text\)/g)]
   .map(x=>[Number(x[1]),x[2]]);
 assert.equal(pins.length,31,'exact live 31 hash pin required');
 const expected=new Map(pins);
 assert.deepEqual([...expected.keys()],ids,'source diff must match live pin IDs');
 const byId=new Map();
 const bank=path.join(root,'content/math/practice_v2');
 for(const dir of fs.readdirSync(bank,{withFileTypes:true})
     .filter(x=>x.isDirectory()).map(x=>x.name)){
  for(const file of fs.readdirSync(path.join(bank,dir))
      .filter(x=>/^P1-[A-Z]{3}-\d{2}\.json$/.test(x))){
   for(const q of JSON.parse(fs.readFileSync(path.join(bank,dir,file),'utf8')).questions){
    const match=q.key.match(/^MATH-P1-PRACTICE2-Q(\d{3})$/);
    assert.ok(match);
    const id=7484+Number(match[1]);
    if(ids.includes(id)){
     assert.ok(!byId.has(id),'duplicate editorial source ID');
     byId.set(id,{id,code:q.primary_skill,file:dir+'/'+file,
       old_hash:expected.get(id)});
    }
   }
  }
 }
 assert.equal(byId.size,31,'all pinned editorial source items must exist');
 return ids.map(id=>byId.get(id));
}
if(mode==='editorial31')approvedGroups.editorial31=editorial31SourceSpecs();
assert.ok(Object.prototype.hasOwnProperty.call(approvedGroups,mode),
 'unknown pinned patch group');
const specs=approvedGroups[mode],expectedCount=specs.length;
assert.ok([2,3,31].includes(expectedCount),'unapproved release group cardinality');
const stable=x=>Array.isArray(x)?x.map(stable):x&&typeof x==='object'
  ?Object.fromEntries(Object.keys(x).sort().map(k=>[k,stable(x[k])])):x;
const hash=x=>crypto.createHash('sha256').update(JSON.stringify(stable(x))).digest('hex');
const diagnostics=new Map();
for(const f of specs){
  const folder=path.join(root,'content/math/practice_v2',path.dirname(f.file));
  const cat=JSON.parse(fs.readFileSync(path.join(folder,'diagnostic_catalog.json'),'utf8'));
  for(const d of cat.diagnostics||[])diagnostics.set(d.code,d);
}
const payload=specs.map(spec=>{
  const file=path.join(root,'content/math/practice_v2',spec.file);
  const contents=JSON.parse(fs.readFileSync(file,'utf8'));
  const q=contents.questions.find(item=>
    item.key==='MATH-P1-PRACTICE2-Q'+String(spec.id-7484).padStart(3,'0'));
  assert.ok(q,'missing corrected source ID '+spec.id);
  assert.equal(q.primary_skill,spec.code);
  assert.ok(['mcq','input'].includes(q.qtype));
  assert.ok(q.practice_no>=1&&q.practice_no<=7);
  assert.ok(/^[a-f0-9]{64}$/.test(spec.old_hash));
  const opts=q.qtype==='mcq'?[...q.options].sort((a,b)=>a.key.localeCompare(b.key)):[];
  if(q.qtype==='mcq'){
    assert.deepEqual(opts.map(x=>x.key),['A','B','C','D']);
    assert.ok(opts.some(x=>x.key===q.correct_answer));
  }else{
    assert.ok(q.answer_contract?.number_only===true);
    assert.ok(q.answer_contract?.canonical_answer);
  }
  for(const l of ['en','ru','uz']){
    assert.ok(q.question?.[l]&&q.explanation?.[l]);
    for(const opt of opts)assert.ok(opt.text?.[l]);
  }
  const d=[];
  for(const option of opts.filter(o=>o.key!==q.correct_answer&&o.diagnostic_code)){
    assert.ok(diagnostics.has(option.diagnostic_code));
    d.push({code:option.diagnostic_code,answer_kind:'mcq_option',
      answer_key:option.key,answer_value:null});
  }
  if(q.qtype==='input')for(const rule of q.diagnostic_rules||[]){
    assert.ok(diagnostics.has(rule.diagnostic_code));
    d.push({code:rule.diagnostic_code,answer_kind:'input_exact',
      answer_key:null,answer_value:String(rule.answer_match)});
  }
  const record={
    old_id:spec.id,old_hash:spec.old_hash,old_key:q.key,
    new_key:q.key+suffix,release_version:release,
    practice_no:q.practice_no,skill:q.primary_skill,role:q.role,
    source_ref:q.source_ref,difficulty:q.difficulty,qtype:q.qtype,
    text:q.question,explanation:q.explanation,
    options:q.qtype==='mcq'?Object.fromEntries(['en','ru','uz'].map(l=>[l,JSON.stringify(opts.map(o=>o.text[l]))])):null,
    correct_answer:q.qtype==='mcq'?q.correct_answer:q.answer_contract.canonical_answer,
    time_limit_sec:q.difficulty==='hard'?90:q.difficulty==='medium'?60:45,
    answer_contract:q.qtype==='input'?q.answer_contract:{},diagnostics:d
  };
  record.new_hash=hash(record);
  assert.notEqual(record.new_hash,record.old_hash);
  return record;
});
assert.equal(payload.length,expectedCount);
const quote=s=>"'"+String(s).replace(/'/g,"''")+"'";
const sql=[
  '-- GENERATED, SENSITIVE QUESTIONS/KEYS: NEVER COMMIT OR LOG.',
  '-- STAGING ONLY in an owner-authorized release; NO live execution.',
  '-- Requires #599 private activate/rollback separately; ALL QA pending.',
  'begin;',
  'do $two_item_staging$',
  'declare',
  ' v_items jsonb := '+quote(JSON.stringify(payload))+'::jsonb;',
  ' v_item jsonb;',
  ' v_old public.questions%rowtype;',
  ' v_meta private.practice_v2_question_meta%rowtype;',
  ' v_pool public.practice_pool_questions%rowtype;',
  ' v_cat private.practice_v2_diagnostic_catalog%rowtype;',
  ' v_diag jsonb;',
  ' v_new_id bigint;',
  ' v_count int:=0;',
  'begin',
  " perform pg_advisory_xact_lock(hashtext('math_practice_v2_release')::bigint);",
  " perform pg_advisory_xact_lock(hashtext('math_practice_v2_future_only_patch')::bigint);",
  " if jsonb_array_length(v_items)<>"+expectedCount+" then raise exception 'two_item_patch_scope_drift'; end if;",
  " for v_item in select value from jsonb_array_elements(v_items) loop",
  "  select * into v_old from public.questions where id=(v_item->>'old_id')::bigint for update;",
  "  select * into v_meta from private.practice_v2_question_meta where question_id=v_old.id for update;",
  "  if v_old.id is null or v_old.subject_id<>5 or v_old.is_active is not true",
  "    or v_old.quality_status<>'published' or v_old.qtype<>v_item->>'qtype'",
  "    or v_meta.question_id is null or v_meta.lifecycle_state<>'published'",
  "    or v_meta.is_runtime_allowed is not true",
  "    or v_meta.release_version<>'math_p1_practice_v2_2026_10_07'",
  "    or v_meta.content_hash<>v_item->>'old_hash'",
  "    or v_meta.content_key<>v_item->>'old_key'",
  "    or v_meta.practice_no<>(v_item->>'practice_no')::smallint",
  "    or v_meta.primary_skill_code<>v_item->>'skill'",
  "    or v_meta.question_role<>v_item->>'role'",
  "    or v_meta.source_ref<>v_item->>'source_ref' then",
  "    raise exception 'old_published_question_hash_or_metadata_changed'; end if;",
  "  select ppq.* into v_pool from public.practice_pool_questions ppq",
  "   join public.practice_pools p on p.id=ppq.pool_id",
  "   where ppq.question_id=v_old.id and ppq.is_active=true",
  "    and p.is_active=true and p.subject_id=5",
  "    and p.tour_no=(v_item->>'practice_no')::smallint for update of ppq;",
  "  if not found or (select count(*) from public.practice_pool_questions",
  "     where question_id=v_old.id and is_active)<>1",
  "     then raise exception 'old_single_active_pool_required'; end if;",
  "  if exists(select 1 from public.tour_questions where question_id=v_old.id)",
  "   or exists(select 1 from private.practice_v2_question_meta",
  "      where content_key=v_item->>'new_key')",
  "   or exists(select 1 from public.question_version_links",
  "      where old_question_id=v_old.id and link_type='replacement')",
  "     then raise exception 'tour_or_duplicate_patch_version'; end if;",
  "  insert into public.questions(",
  "   subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,",
  "   correct_answer,explanation,image_url,is_active,question_text_ru,question_text_uz,",
  "   question_text_en,options_text_ru,options_text_uz,options_text_en,",
  "   explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_status)",
  "   values(5,v_old.topic,v_old.subtopic,v_item->>'difficulty',v_item->>'qtype',",
  "   v_item #>> '{text,en}',v_item #>> '{options,en}',v_item->>'correct_answer',",
  "   v_item #>> '{explanation,en}',null,false,",
  "   v_item #>> '{text,ru}',v_item #>> '{text,uz}',v_item #>> '{text,en}',",
  "   v_item #>> '{options,ru}',v_item #>> '{options,uz}',v_item #>> '{options,en}',",
  "   v_item #>> '{explanation,ru}',v_item #>> '{explanation,uz}',",
  "   v_item #>> '{explanation,en}',v_old.book_ref,",
  "   (v_item->>'time_limit_sec')::integer,'draft') returning id into v_new_id;",
  "  insert into private.practice_v2_question_meta(",
  "   question_id,content_key,release_version,practice_no,primary_skill_code,",
  "   secondary_skill_codes,question_role,source_ref,answer_contract,content_hash,",
  "   qa_math_status,qa_language_status,qa_technical_status,qa_tour_separation_status,",
  "   lifecycle_state,is_runtime_allowed)",
  "   values(v_new_id,v_item->>'new_key',v_item->>'release_version',",
  "   (v_item->>'practice_no')::smallint,v_item->>'skill',v_meta.secondary_skill_codes,",
  "   v_item->>'role',v_item->>'source_ref',v_item->'answer_contract',v_item->>'new_hash',",
  "   'pending','pending','pending','pending','approved',false);",
  "  insert into public.practice_pool_questions(pool_id,question_id,order_no,is_active)",
  "   values(v_pool.pool_id,v_new_id,v_pool.order_no,false);",
  "  for v_diag in select value from jsonb_array_elements(v_item->'diagnostics') loop",
  "   select * into v_cat from private.practice_v2_diagnostic_catalog",
  "     where diagnostic_code=v_diag->>'code' and approval_status='approved'",
  "      and is_runtime_allowed=true;",
  "   if not found then raise exception 'diagnostic_catalog_not_approved'; end if;",
  "   insert into public.question_answer_diagnostics(",
  "      question_id,answer_kind,answer_key,answer_value,is_correct,mistake_type,weak_skill,",
  "      feedback_ru,feedback_uz,feedback_en,next_action_ru,next_action_uz,next_action_en,",
  "      rule_json,quality_status) values(v_new_id,v_diag->>'answer_kind',v_diag->>'answer_key',",
  "      v_diag->>'answer_value',false,v_cat.mistake_type,v_cat.skill_code,",
  "      v_cat.feedback_ru,v_cat.feedback_uz,v_cat.feedback_en,",
  "      v_cat.next_action_ru,v_cat.next_action_uz,v_cat.next_action_en,",
  "      jsonb_build_object('diagnostic_code',v_diag->>'code','inference_strength',",
  "       v_cat.inference_strength,'release_version',v_item->>'release_version'),'draft');",
  "  end loop;",
  "  v_count:=v_count+1;",
  " end loop;",
  " if v_count<>"+expectedCount+" then raise exception 'two_item_staging_partial'; end if;",
  'end $two_item_staging$;',
  'commit;'
].join('\n')+'\n';
const out=args.indexOf('--out');
if(out>=0){
  assert.ok(args[out+1],'--out needs a private output file');
  const file=path.resolve(process.cwd(),args[out+1]);
  fs.writeFileSync(file,sql,{encoding:'utf8',flag:'wx',mode:0o600});
}
console.log(JSON.stringify({
  extra_future_only_items:payload.length,
  group:mode,
  historic_published_hashes_pinned:expectedCount,
  staged_keys_or_questions_logged:false,
  staging_sql_written:out>=0,
  qa:'PENDING',
  live_questions_changed:0,
  old_history_changed:0,
  publication:false
}));
