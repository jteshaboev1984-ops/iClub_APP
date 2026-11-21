#!/usr/bin/env node
'use strict';
// #574: stage an explicitly selected 10-item published batch OR the isolated
// Q400/Q481, Q089/Q202/Q226 legacy draft checks or one consolidated ten-item cohort. Reuses #599
// proven private future-only version and rollback contract.
// NEVER commit the generated SQL or execute on hosted Supabase without the
// owner-approved cutover. Does not grant academic QA or publish any question.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..');
const args=process.argv.slice(2);
const batchArg=args.indexOf('--batch');
const mode=batchArg>=0?args[batchArg+1]:'hotfix10';
const releases={
 hotfix10:{name:'math_p1_practice_v2_fix_20261120',suffix:'-V20261120'},
 q400q481:{name:'math_p1_practice_v2_q400_q481_20261120',suffix:'-V20261120Q400Q481'},
 q089q202q226:{name:'math_p1_practice_v2_q089_q202_q226_20261120',suffix:'-V20261120Q089Q202Q226'},
 pending10:{name:'math_p1_practice_v2_pending10_20261120',suffix:'-V20261120PENDING10'},
 decimal8:{name:'math_p1_practice_v2_decimal8_20261121',suffix:'-V20261121DEC8'}
};
assert.ok(Object.hasOwn(releases,mode),'unsupported governed release batch');
const release=releases[mode].name,suffix=releases[mode].suffix;
const baselineSpecs=[
 {id:7624,code:'P1-FUN-08',file:'p2_functions/P1-FUN-08.json',old_hash:'b0ccf462b7bafa14abfcf88940a4a5a878b96ec0b7a4a161b558ea812fdb0d67'},
 {id:7662,code:'P1-COO-03',file:'p3_coordinate_geometry/P1-COO-03.json',old_hash:'4361c8f4aaa539da3d0edee194298c83b114a9cdcc8030571db0d46c4dd266a7'},
 {id:7724,code:'P1-CIR-03',file:'p4_circular_trigonometry/P1-CIR-03.json',old_hash:'9a753b585a39471adc75010f0622dbe3f7c1e00a262b864cb2ed4eec6b75d16e'},
 {id:7791,code:'P1-SER-01',file:'p5_binomial_series/P1-SER-01.json',old_hash:'0356f12e2932059bae0ab896c3010a8a117786984ee4b0dcfbbafbef600e7423'},
 {id:7797,code:'P1-SER-02',file:'p5_binomial_series/P1-SER-02.json',old_hash:'59930cdbdf3aa2703722ab60c4921a9e5719d7176168458bf3ff9c9269656cec'},
 {id:7881,code:'P1-DIF-04',file:'p6_differentiation/P1-DIF-04.json',old_hash:'71c936e246749a02c721865fa3517e6c7fa8862e1f983ee79ac32cc2b5d3fa7d'},
 {id:7893,code:'P1-DIF-06',file:'p6_differentiation/P1-DIF-06.json',old_hash:'38e8868cb7481b28ae08daed93078d5f4c58cb882604df349faa37c5269954e0'},
 {id:7926,code:'P1-INT-01',file:'p7_integration/P1-INT-01.json',old_hash:'bcfd7fe929fcf0e46219e3a1fe5083bad3e44718faabe6c932a0d45052d2c0b3'},
 {id:7937,code:'P1-INT-02',file:'p7_integration/P1-INT-02.json',old_hash:'43349ae00988b83dc61d827318d6d2b50c7940d1f9a698686ce2887bf3031985'},
 {id:7970,code:'P1-INT-05',file:'p7_integration/P1-INT-05.json',old_hash:'c45c280840f3c960e05290bf45dee920b17dc67ead5b5c759f942e8770256636'}
];
// Pinned hosted read-only original hash snapshots, checked on 2026-11-20.
const nextTwo=[
 {id:7884,code:'P1-DIF-05',file:'p6_differentiation/P1-DIF-05.json',
  old_hash:'32b8172779a666e62e031a6b6488b2ecf0e6e4c382e9000ecb417b54da49eaff'},
 {id:7965,code:'P1-INT-04',file:'p7_integration/P1-INT-04.json',
  old_hash:'600d6bd3df9bc1409c72ece9fd249095b44101858c378d040b84b36ce9b5201e'}
];
const nextThree=[
 {id:7573,code:'P1-FUN-03',file:'p2_functions/P1-FUN-03.json',
  old_hash:'2be7d4b6e952e591890789d0870e6dca5519353c4b8b0a9c718f09454c437ec1'},
 {id:7686,code:'P1-COO-05',file:'p3_coordinate_geometry/P1-COO-05.json',
  old_hash:'6efedc3b71f46e88e9084c021cd0e5b11ba4bdb8009a38b0100eb0a05a425289'},
 {id:7710,code:'P1-CIR-02',file:'p4_circular_trigonometry/P1-CIR-02.json',
  old_hash:'19928acd031087d741fe251b9fc4bb6f7b0f11e4840d89a61133a8ad3fe7feb6'}
];
// These five original live hashes were checked SELECT-only on 2026-11-20.
const decimalFive=[
 {id:7506,code:'P1-QUA-02',file:'p1_quadratics/P1-QUA-02.json',
  old_hash:'f3d5b3a0c71cf4cd6cb5c04f3acac038f44985b1e10f4f4d5898b9e49971b79a'},
 {id:7754,code:'P1-TRI-03',file:'p4_circular_trigonometry/P1-TRI-03.json',
  old_hash:'62624dc52cfc7d8cc4858da517213efb44a849644c3f9258d52efdf072f235a5'},
 {id:7761,code:'P1-TRI-04',file:'p4_circular_trigonometry/P1-TRI-04.json',
  old_hash:'435daca251d04e28cae53db5a20047f76edc2586a92eb30860e97971a89b499e'},
 {id:7809,code:'P1-SER-03',file:'p5_binomial_series/P1-SER-03.json',
  old_hash:'5fcb36c761ecc3b03ea10dfe3c62650bc4ee5543c59d54b9f9d41dea970633b2'},
 {id:7835,code:'P1-SER-05',file:'p5_binomial_series/P1-SER-05.json',
  old_hash:'55f106f7678a4695de53082a7ea86a3f2395b5e17bf13142ff304752a99eff1f'}
];
const pending10=[...decimalFive,...nextThree,...nextTwo].sort((a,b)=>a.id-b.id);
assert.deepEqual(pending10.map(x=>x.id),
 [7506,7573,7686,7710,7754,7761,7809,7835,7884,7965]);
// Verified SELECT-only against live original hosted version/hash and 1 active Practice pool, 0 Tour/version links.
const decimalEight=[
 {id:7714,code:'P1-CIR-02',file:'p4_circular_trigonometry/P1-CIR-02.json',
  old_hash:'cc6db4cfee0b8f03a3d2eac20e1072d25f690231ea96df6b063d6c7273f15759'},
 {id:7727,code:'P1-CIR-03',file:'p4_circular_trigonometry/P1-CIR-03.json',
  old_hash:'12cb40ca98e1b9254c008870e3c5dfd4a61c3059bc6d8eebe960c5317ad3fcab'},
 {id:7796,code:'P1-SER-02',file:'p5_binomial_series/P1-SER-02.json',
  old_hash:'4b6570d98de8656c449f56dff7b0a1452f176af554758f377f1c4b43086b25c6'},
 {id:7818,code:'P1-SER-04',file:'p5_binomial_series/P1-SER-04.json',
  old_hash:'c963bf29e6652acab2bbbd227fdcaa17b927ca415b6113c1f87b335e75184f4a'},
 {id:7829,code:'P1-SER-04',file:'p5_binomial_series/P1-SER-04.json',
  old_hash:'58641c016d8a8543bfa0f06a8bae0a51f21058801010bf7c42907e8209c762da'},
 {id:7838,code:'P1-SER-05',file:'p5_binomial_series/P1-SER-05.json',
  old_hash:'cb9e5d82eb02aa4083fd6bb6a31d3639ab079163ddfc401f9e9288c3dc91baec'},
 {id:7894,code:'P1-DIF-06',file:'p6_differentiation/P1-DIF-06.json',
  old_hash:'b5e9eed746e17b803fd4e2ddd1e86b35fc35da4a8d9d2201ffcf8681f6a322e3'},
 {id:7900,code:'P1-DIF-06',file:'p6_differentiation/P1-DIF-06.json',
  old_hash:'bb1a52aceeffe34c6478ac59e0561c249d4ac78ae852c839fe6ce5fdb8cfbeec'}
];
assert.deepEqual(decimalEight.map(x=>x.id),
 [7714,7727,7796,7818,7829,7838,7894,7900]);
const specs=mode==='hotfix10'?baselineSpecs:
  mode==='q400q481'?nextTwo:
  mode==='q089q202q226'?nextThree:
  mode==='pending10'?pending10:decimalEight;
const expectedCount=specs.length;
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
assert.deepEqual(payload.map(p=>p.old_id),specs.map(s=>s.id));
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
