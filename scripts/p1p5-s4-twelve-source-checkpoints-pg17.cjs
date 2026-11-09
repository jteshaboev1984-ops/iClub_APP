#!/usr/bin/env node
'use strict';
// Academically re-derived candidate final-answer checks for iClub's six ORIGINAL
// P1/P5 Paper versions. ALL approved key values exist only in the disposable
// CI PostgreSQL process; the Git migration pins metadata but inserts NO answers.
// Signed real PostgREST/PG17 checks, never method marks or Cambridge grades.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
assert(process.env.CI==='true'&&process.env.P1P5_E2E_ISOLATED==='true'&&
  process.env.PGHOST==='127.0.0.1'&&process.env.PGDATABASE==='postgres'&&
  process.env.PGUSER==='postgres', 'REFUSED: disposable PG17 CI only');
const SECRET=process.env.P1P5_E2E_JWT_SECRET;
assert(SECRET&&SECRET.length>=32,'ephemeral signed JWT secret missing');
const USER='11111111-1111-4111-8111-111111111191';
const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const data=enc({alg:'HS256',typ:'JWT'})+'.'+enc({
 aud:'authenticated',role:'authenticated',sub:USER,iat:Math.floor(Date.now()/1000),
 exp:Math.floor(Date.now()/1000)+1800
});
const token=data+'.'+crypto.createHmac('sha256',SECRET).update(data).digest('base64url');
const sql=q=>execFileSync('psql',['-X','-A','-t','-v','ON_ERROR_STOP=1','-c',q],{
 env:process.env,encoding:'utf8',stdio:['ignore','pipe','pipe']
}).trim();
const sqlLiteral=s=>"'"+String(s).replaceAll("'","''")+"'";
const safeId=n=>{assert(Number.isSafeInteger(n)&&n>=1);return String(n)};
const key=(id,suffix)=>'s4-twelve-source-qa-'+id+'-'+suffix+'-token-20261109';
async function rpc(name,args){
 const res=await fetch('http://127.0.0.1:3000/rpc/'+name,{
  method:'POST',headers:{'Content-Type':'application/json',
   'Authorization':'Bearer '+token,'Accept':'application/json'},
  body:JSON.stringify(args)
 });
 let result=null;try{result=await res.json()}catch{}
 return{ok:res.ok,status:res.status,data:result};
}
const ok=(r,msg)=>{assert(r.ok,msg+' HTTP '+r.status+' '+JSON.stringify(r.data).slice(0,320));return r.data};
const deny=(r,msg)=>assert(!r.ok,msg+' should be denied: '+JSON.stringify(r.data).slice(0,200));
const choose=(n,k)=>{
 let v=1;for(let i=1;i<=k;i++)v=v*(n-i+1)/i;
 return Math.round(v);
};
function normalQuantile90(){
 // Cambridge MF19 prints the 90th percentile z around 1.282; the final k
 // is requested to THREE significant figures. This is a derived result only.
 return Number((70+8*1.282).toPrecision(3));
}
const cases=[
 {c:'P1',paper:'p1_stage3_full_paper_01',a:391,i:2,t:220,part:'c',
  calc:()=> (5-3)**2/2-1.5,first:'1/2',wrong:'0.6',criterion:'solution'},
 {c:'P1',paper:'p1_stage3_full_paper_01',a:391,i:4,t:108,part:'c',
  calc:()=>Number((48-0.5*8*8*Math.sin(12/8)).toPrecision(3)),
  first:'16,1',wrong:'16.0',criterion:'segment_numeric'},
 {c:'P1',paper:'p1_stage4_full_paper_02',a:451,i:4,t:125,part:'c',
  calc:()=>0.5*((26-10)/2)*10,first:'40',wrong:'41',criterion:'area'},
 {c:'P1',paper:'p1_stage4_full_paper_02',a:451,i:10,t:131,part:'c',
  calc:()=>Math.pow(10/2,2),first:'25',wrong:'24',criterion:'a_value'},
 {c:'P1',paper:'p1_stage4_full_paper_03',a:452,i:6,t:144,part:'c',
  calc:()=>{let n=1;while(n*(3*n+7)/2<=1000)n++;return n},
  first:'25',wrong:'24',criterion:'least_n'},
 {c:'P1',paper:'p1_stage4_full_paper_03',a:452,i:8,t:146,part:'b',
  calc:()=>{const x=Math.sqrt(24/6);return 24*x-2*x**3},
  first:'32',wrong:'31',criterion:'max_area'},
 {c:'P5',paper:'p5_stage3_full_paper_01',a:453,i:2,t:116,part:'c',
  calc:()=>choose(5,2)*choose(7,2)*(3*2*1)*2,first:'2520',
  wrong:'2519',criterion:'total_arrangements'},
 {c:'P5',paper:'p5_stage3_full_paper_01',a:453,i:6,t:228,part:'e',
  calc:()=>Number(((1-0.2)**4).toFixed(4)),first:'0.4096',
  wrong:'0.4095',criterion:'conditional'},
 {c:'P5',paper:'p5_stage4_full_paper_02',a:455,i:2,t:133,part:'c',
  calc:()=>choose(7,2)*120/2-360,first:'900',
  wrong:'901',criterion:'l_apart'},
 {c:'P5',paper:'p5_stage4_full_paper_02',a:455,i:6,t:179,part:'d',
  calc:()=>0.75**3,alt:[0.4219],first:'27/64',wrong:'0.4218',
  criterion:'conditional'},
 {c:'P5',paper:'p5_stage4_full_paper_03',a:363,i:2,t:150,part:'c',
  calc:()=>7*6*5*4+6*6*5*4,first:'1560',
  wrong:'1559',criterion:'divisible5'},
 {c:'P5',paper:'p5_stage4_full_paper_03',a:363,i:6,t:234,part:'c',
  calc:normalQuantile90,first:'80,3',wrong:'80.2',criterion:'k'}
];
function expectedFromFirst(entry){
 const input=entry.first.replace(',','.');
 if(input.includes('/')){const [a,b]=input.split('/').map(Number);return a/b;}
 return Number(input);
}
async function main(){
 assert.equal(cases.length,12);
 assert.equal(new Set(cases.map(q=>q.a+':'+q.i+':'+q.part)).size,12);
 assert.equal(sql("SELECT count(*) FROM private.exam_prep_hybrid_s4_checkpoint_keys_v1 "+
  "WHERE review_state='candidate' AND expected_numeric IS NULL"),'12',
  'all 12 version-pinned source candidates must start with no live keys');
 assert.equal(sql("SELECT count(*) FROM private.exam_prep_hybrid_s4_checkpoint_keys_v1 "+
  "WHERE review_state='approved' AND expected_numeric IS NOT NULL AND part_label <> 'test'"+
  " AND part_label <> 'alternate' AND part_label <> 'stale'"),'0',
  'no real answer-checker provisioned before disposable QA');
 const original=sql("SELECT (SELECT count(*) FROM private.exam_prep_sessions)::text||'/'||"+
  "(SELECT count(*) FROM private.exam_prep_timed_attempt_results)::text||'/'||"+
  "(SELECT count(*) FROM public.practice_attempts)::text||'/'||"+
  "(SELECT count(*) FROM public.tour_attempts)::text||'/'||"+
  "(SELECT count(*) FROM public.certificates)::text");
 let reviewed=0;
 for(const c of cases){
   const actual=c.calc();
   const expected=expectedFromFirst(c);
   assert(Math.abs(actual-expected)<1e-11,'independent derivation/format mismatch '+c.paper+' Q'+c.i+c.part);
   const metadata=sql("SELECT a.component_code||'/'||a.assessment_key||'/'||"+
     "w.id::text||'/'||w.task_version||'/'||"+
     "coalesce((SELECT cr->>'id' FROM jsonb_array_elements(w.rubric_json->'criteria') cr"+
     " WHERE cr->>'id'="+sqlLiteral(c.criterion)+" LIMIT 1),'missing')"+
     " FROM private.exam_prep_assessment_items i"+
     " JOIN private.exam_prep_assessments a ON a.id=i.assessment_id"+
     " JOIN private.exam_prep_written_tasks w ON w.id=i.written_task_id"+
     " WHERE i.assessment_id="+safeId(c.a)+" AND i.item_order="+safeId(c.i));
   const [component,paper,task,version,criterion]=metadata.split('/');
   assert.equal(component,c.c);assert.equal(paper,c.paper);
   assert.equal(Number(task),c.t);assert(/^wtv\d+$/.test(version));
   assert.equal(criterion,c.criterion,'rubric criterion must exist in actual pinned task');
   const normalized=Number(actual.toPrecision(12));
   const alternates=c.alt||[];
   assert(alternates.every(v=>Number.isFinite(v)));
   const expectedNumeric=String(normalized);
   const pgAlt="'{"+alternates.join(',')+"}'::numeric[]";
   const updated=sql("UPDATE private.exam_prep_hybrid_s4_checkpoint_keys_v1"+
     " SET expected_numeric="+expectedNumeric+
     ", accepted_numeric_alternates="+pgAlt+
     ", absolute_tolerance=0,review_state='approved',approved_at=now(),"+
     "academic_review_ref='s4-disposable-independent-math-recalculation-20261109'"+
     " WHERE assessment_id="+safeId(c.a)+" AND item_order="+safeId(c.i)+
     " AND part_label="+sqlLiteral(c.part)+" AND written_task_id="+safeId(c.t)+
     " AND source_task_version="+sqlLiteral(version)+
     " AND review_state='candidate' AND expected_numeric IS NULL"+
     " RETURNING item_order");
   assert.equal(updated,String(c.i),'candidate must activate only on exact source binding');
   reviewed++;
 }
 assert.equal(reviewed,12);
 assert.equal(sql("SELECT count(*) FROM private.exam_prep_hybrid_s4_checkpoint_keys_v1"+
  " WHERE academic_review_ref='s4-disposable-independent-math-recalculation-20261109'"+
  " AND review_state='approved'"),'12');
 // Disposable CI only. Older signed test intentionally switches the feature OFF.
 sql("UPDATE private.exam_prep_hybrid_s4_config_v1 SET paper_enabled=true,stage_gates_enabled=true"+
  " WHERE singleton");
 const grouped=[...new Set(cases.map(x=>x.a))];
 let matches=0,mismatches=0;
 for(const assessmentId of grouped){
  const items=cases.filter(x=>x.a===assessmentId);
  assert.equal(items.length,2,'two real source-verified parts per Paper');
  for(const [kind,isCorrect] of [['correct',true],['wrong',false]]){
   const id=key(assessmentId,kind);
   const started=ok(await rpc('start_exam_prep_hybrid_s4_paper_safe_v1',{
     p_assessment_id:assessmentId,p_idempotency_key:id+'-start'
   }), 'start '+assessmentId+' '+kind);
   const session=ok(await rpc('get_exam_prep_hybrid_s4_session_safe_v1',{
     p_session_id:started.session_id,p_language:'en'
   }),'source Paper no answer keys');
   assert.equal(session.awarded_paper_marks,null);
   assert(!JSON.stringify(session).includes('expected_numeric')&&
     !JSON.stringify(session).includes('rubric_json'),
     'no privileged correct answer or full rubric during Paper');
   const finished=ok(await rpc('finish_exam_prep_hybrid_s4_paper_safe_v1',{
     p_session_id:started.session_id,p_reason:'finish',
     p_idempotency_key:id+'-finish'
   }),'finish original source Paper');
   assert.equal(finished.paper_marks,null);
   const checkable=ok(await rpc('get_exam_prep_hybrid_s4_session_safe_v1',{
     p_session_id:started.session_id,p_language:'en'
   }),'finished source Paper');
   assert(items.every(c=>checkable.checkpoints.some(k=>
     k.item_order===c.i&&k.part_label===c.part&&k.checked===false)));
   for(const c of items){
    const result=ok(await rpc('check_exam_prep_hybrid_s4_final_safe_v1',{
       p_session_id:started.session_id,p_item_order:c.i,p_part_label:c.part,
       p_answer:isCorrect?c.first:c.wrong,
       p_idempotency_key:id+'-answer-'+c.i
    }),'signed '+kind+' '+c.c+' Q'+c.i+c.part);
    assert.equal(result.matched,isCorrect,
      'incorrect numeric must not match, nor correct numeric miss');
    assert.equal(result.paper_marks_awarded,null);
    assert.equal(result.written_method_verified,false);
    if(isCorrect)matches++;else mismatches++;
   }
   const revealed=ok(await rpc('reveal_exam_prep_hybrid_s4_review_safe_v1',{
      p_session_id:started.session_id,p_language:'ru'
   }),'noncredit licensed-source rubric after attempt');
   assert.equal(revealed.paper_marks_awarded,null);
   assert.equal(revealed.written_method_verified,false);
   deny(await rpc('check_exam_prep_hybrid_s4_final_safe_v1',{
      p_session_id:started.session_id,p_item_order:items[0].i,
      p_part_label:items[0].part,p_answer:'0',
      p_idempotency_key:id+'-after-reveal'
   }),'no second/new result after first reveal');
  }
 }
 assert.equal(matches,12);assert.equal(mismatches,12);
 assert.equal(sql("SELECT (SELECT count(*) FROM private.exam_prep_sessions)::text||'/'||"+
  "(SELECT count(*) FROM private.exam_prep_timed_attempt_results)::text||'/'||"+
  "(SELECT count(*) FROM public.practice_attempts)::text||'/'||"+
  "(SELECT count(*) FROM public.tour_attempts)::text||'/'||"+
  "(SELECT count(*) FROM public.certificates)::text"),original,
  '12 source cases cannot touch legacy Paper/progress/Practice/Tours/certificates');
 sql("UPDATE private.exam_prep_hybrid_s4_config_v1"+
   " SET paper_enabled=false,stage_gates_enabled=false WHERE singleton");
 console.log('S4 12 SOURCE-PINNED CANDIDATES PG17/SIGNED PASS: 6 P1/P5 Paper revisions; '+
  '12 independently re-derived exact/rounded numeric targets; '+
  '12 correct and 12 wrong signed owner checkpoints; source/version guard, '+
  'no browser answer keys, no method marks, no paper grade, untouched legacy. '+
  'Correct numeric keys enabled in DISPOSABLE CI only; production candidates remain inert.');
}
main().catch(e=>{console.error('S4 12 SOURCE CHECKPOINT QA FAIL:',e.stack||e);
 process.exitCode=1});
