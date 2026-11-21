#!/usr/bin/env node
'use strict';
// #574: real production RPCs under ephemeral signed JWT/PostgREST/PG17, never hosted.
const assert=require('node:assert/strict');
const crypto=require('node:crypto');
assert(process.env.CI==='true'&&process.env.PRACTICE_SEASON2_ISOLATED==='true'&&
 process.env.PRACTICE_TOPIC_CUTOVER_ISOLATED==='true'&&
 process.env.PGHOST==='127.0.0.1'&&process.env.PRACTICE_TOPIC_DB==='practice_topic_cutover',
 'REFUSED: disposable PostgreSQL 17 only');
const secret=process.env.PRACTICE_SEASON2_JWT_SECRET;
assert(secret&&secret.length>=48,'ephemeral signing secret missing');
const A='11111111-1111-4111-8111-111111111111';
const B='22222222-2222-4222-8222-222222222222';
const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
function jwt(user,ttl=600){
 const now=Math.floor(Date.now()/1000),data=enc({alg:'HS256',typ:'JWT'})+'.'+
  enc({role:'authenticated',sub:user,aud:'authenticated',iat:now,exp:now+ttl});
 return data+'.'+crypto.createHmac('sha256',secret).update(data).digest('base64url');
}
async function rpc(name,body,token=null){
 const response=await fetch('http://127.0.0.1:3001/rpc/'+name,{
  method:'POST',
  headers:{'content-type':'application/json',...(token?{authorization:'Bearer '+token}:{})},
  body:JSON.stringify(body)
 });
 let data=null;try{data=await response.json()}catch{}
 return {ok:response.ok,status:response.status,data};
}
const startArgs=id=>({p_subject_key:'mathematics',p_topic:'Synthetic Topic',
 p_subtopic:null,p_client_session_id:id});
const resumeArgs=id=>({p_session_id:id});
async function run(){
 const alice=jwt(A),bob=jwt(B);
 for(const token of [null,jwt(A,-3600)]){
  const unauthorized=await rpc('start_practice_topic_drill_choice_safe_v1',
   startArgs('practice_topic_choice_qa_unauthorized_1'),token);
  assert(!unauthorized.ok&&unauthorized.status>=400,'unauthorized start permitted');
 }
 const before=await rpc('get_practice_topic_history_safe_v1',{p_subject_key:'mathematics'},alice);
 assert(before.ok&&before.data?.completed_sessions===3,'historical sessions not preserved');
 const client='practice_topic_choice_qa_integrated_20261121';
 const started=await rpc('start_practice_topic_drill_choice_safe_v1',startArgs(client),alice);
 assert(started.ok,'server rejected new session '+started.status);
 const sid=Number(started.data?.session_id);
 assert(Number.isInteger(sid)&&sid>=200,'no real created server ID');
 assert(started.data?.question_count===5&&started.data?.resumed===false,'incorrect new session details');
 const idempotent=await rpc('start_practice_topic_drill_choice_safe_v1',startArgs(client),alice);
 assert(idempotent.ok&&idempotent.data?.resumed===true&&Number(idempotent.data.session_id)===sid,
  'same client id created duplicate session');
 const resume=await rpc('get_practice_drill_resume_safe_v4',resumeArgs(sid),alice);
 assert(resume.ok&&Array.isArray(resume.data)&&resume.data.length===5,'signed Resume missing questions');
 assert(resume.data.every(q=>!q.was_answered&&q.correct_answer===null&&q.explanation===null),
  'server leaked answers before submission');
 const denied=await rpc('get_practice_drill_resume_safe_v4',resumeArgs(sid),bob);
 assert(denied.ok&&Array.isArray(denied.data)&&denied.data.length===0,'cross-user Resume exposed');
 const first=resume.data[0];
 const answerArgs=(q,val)=>({p_session_id:sid,p_question_id:q.id,
  p_user_answer:val,p_picked_index:null,p_time_spent:9});
 const wrong=await rpc('submit_practice_drill_answer_safe_v5',answerArgs(first,'WRONG'),alice);
 assert(wrong.ok&&wrong.data?.is_correct===false&&wrong.data?.answered===1&&!wrong.data?.complete,
  'first wrong answer was not stored');
 assert(wrong.data?.correct_answer==='RIGHT','answer key not disclosed after submission');
 for(const [locale,value] of [['ru','RU explanation'],['uz','UZ explanation'],['en','EN explanation']]){
  assert(wrong.data?.['explanation_'+locale]===value,'feedback translation mismatch '+locale);
 }
 const restored=await rpc('get_practice_drill_resume_safe_v4',resumeArgs(sid),alice);
 assert(restored.ok&&restored.data.filter(q=>q.was_answered).length===1,'Pause/Resume lost saved answer');
 assert(restored.data.slice(1).every(q=>!q.was_answered&&q.correct_answer===null),
  'Pause/Resume revealed future solutions');
 const blocked=await rpc('submit_practice_drill_answer_safe_v5',answerArgs(first,'RIGHT'),bob);
 assert(!blocked.ok,'other account wrote to the owned session');
 const retry=await rpc('submit_practice_drill_answer_safe_v5',answerArgs(first,'RIGHT'),alice);
 assert(retry.ok&&retry.data?.idempotent===true&&retry.data?.is_correct===false,
  'replay changed already recorded answer');
 for(let i=1;i<resume.data.length;i++){
  const next=await rpc('submit_practice_drill_answer_safe_v5',answerArgs(resume.data[i],'RIGHT'),alice);
  assert(next.ok&&next.data?.is_correct===true&&next.data?.answered===i+1&&
   next.data?.complete===(i===resume.data.length-1),'answer/finalization mismatch at '+i);
 }
 const finished=await rpc('get_practice_drill_resume_safe_v4',resumeArgs(sid),alice);
 assert(finished.ok&&finished.data?.length===5&&finished.data.every(q=>q.was_answered),
  'finalized attempt unavailable in signed review');
 assert(finished.data.filter(q=>q.saved_is_correct).length===4);
 const history=await rpc('get_practice_topic_history_safe_v1',{p_subject_key:'mathematics'},alice);
 assert(history.ok&&history.data?.completed_sessions===4&&
  JSON.stringify(history.data).includes('"session_id":'+sid),'completed attempt not in own History');
 const other=await rpc('get_practice_topic_history_safe_v1',{p_subject_key:'mathematics'},bob);
 assert(other.ok&&other.data?.completed_sessions===1&&
  !JSON.stringify(other.data).includes('"session_id":'+sid),'history owner isolation failed');
 console.log('PRACTICE_TOPIC_REAL_SIGNED_HTTP_PASS: start/idempotency/submit/wrong feedback/restore/finalized history/access boundaries, disposable PG17');
}
run().catch(err=>{console.error('PRACTICE_TOPIC_REAL_SIGNED_HTTP_FAILED:',err?.message);process.exitCode=1});
