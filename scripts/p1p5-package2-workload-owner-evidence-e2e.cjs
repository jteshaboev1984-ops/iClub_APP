#!/usr/bin/env node
'use strict';
// Reuses ONLY the two disposable PG17 learners and actual Stage0/learning
// evidence already produced by the existing signed HTTP Chromium E2E.
// This test does not create an invented student, fake grade, or study minutes.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const HOST='http://127.0.0.1:3000';
const USER_A='11111111-1111-4111-8111-111111111191';
const USER_B='22222222-2222-4222-8222-222222222292';
const secret=process.env.P1P5_E2E_JWT_SECRET;
assert(process.env.P1P5_E2E_ISOLATED==='true','REFUSED: not isolated PG17');
assert(secret&&secret.length>=32,'REFUSED: missing disposable JWT key');
function enc(x){return Buffer.from(JSON.stringify(x)).toString('base64url')}
function token(uid){
 const n=Math.floor(Date.now()/1000);
 const msg=enc({alg:'HS256',typ:'JWT'})+'.'+enc({role:'authenticated',aud:'authenticated',sub:uid,iat:n,exp:n+900});
 return msg+'.'+crypto.createHmac('sha256',secret).update(msg).digest('base64url');
}
async function request(uid){
 const r=await fetch(HOST+'/rpc/get_exam_prep_workload_review_projection_safe_v1',{
   method:'POST',
   headers:{'Content-Type':'application/json',Accept:'application/json',
            ...(uid?{Authorization:'Bearer '+token(uid)}:{})},
   body:'{}'
 });
 let data;try{data=await r.json()}catch{data=null}
 return {ok:r.ok,status:r.status,data};
}
(async()=>{
 const result=await request(USER_A);
 assert(result.ok,'Owner could not see real read-only projection: '+result.status+' '+JSON.stringify(result.data));
 const d=result.data;
 assert.equal(d.contract_version,'exam_prep_workload_review_projection_v1');
 assert.equal(d.recommendation_accept_enabled,false,'Academic minute recommendation was not approved');
 assert.equal(d.recommended_daily_minutes,null,'No guessed study-hour requirement');
 assert.equal(d.learning_time_cap,false,'Study budget must never lock learning');
 assert.equal(d.grade_prediction_available,false,'No Cambridge grade forecast');
 for (const [paper,count,examMinutes] of [['P1',45,110],['P5',36,75]]) {
   const p=d[paper];
   assert(p,'Missing '+paper+' real projection');
   assert.equal(p.curriculum_skills,count,'Wrong canonical syllabus count '+paper);
   assert.equal(p.source_mapped_norms,count,'Missing source-bound norms '+paper);
   assert.equal(p.academically_approved_norms,0,'Faked academic approval '+paper);
   assert.equal(p.cambridge_full_paper_exam_minutes,examMinutes,'Wrong official 2026/27 paper duration');
   assert.equal(p.cambridge_paper_time_is_study_quota,false);
   assert.equal(p.numeric_recommendation_available,false);
   assert.equal(p.recommended_daily_minutes,null);
   assert.equal(p.recommended_weekly_hours_min,null);
   assert.equal(p.recommended_weekly_hours_max,null);
   assert.equal(p.learning_time_cap,false);
   assert.equal(p.diagnostic_complete,true,'Existing genuine E2E had finished Stage0 for '+paper);
   assert(p.diagnostic_completed_at,'No actual diagnostic completion anchor '+paper);
   const states=['skills_unknown_objective_level',
       'skills_with_observed_but_unconfirmed_objective_level',
       'skills_with_confirmed_objective_coverage'];
   let classified=0;
   for(const k of states){assert(Number.isInteger(p[k])&&p[k]>=0,'Bad real evidence counter '+k);classified+=p[k]}
   assert.equal(classified,count,'Objective evidence states must cover exactly '+count+' skills without treating unknown as weak');
   assert(p.skills_unknown_objective_level>=0);
   assert.equal(p.status,'exam_date_not_confirmed','No invented official exam date for '+paper);
 }
 const anonymous=await request(null);
 assert(!anonymous.ok,'Anonymous request exposed private Math skill evidence');
 const other=await request(USER_B);
 assert(!other.ok || (other.data.P1?.diagnostic_completed_at===null &&
                      other.data.P5?.diagnostic_completed_at===null),
    'Different user could read another learner diagnostic evidence');
 console.log('PASS P2 real learner objective/unknown evidence (45+36), official 110/75min papers, zero invented hours or grade forecasts, no study quota, owner-only JWT');
})().catch(err=>{console.error(err);process.exitCode=1});
