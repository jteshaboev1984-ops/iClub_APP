"use strict";
// §108 physically independent worker-thread -> psql process claims.
// Entirely synthetic, separate disposable scratch database. No real accounts.
const a=require("node:assert/strict");
const {Worker,isMainThread,parentPort,workerData}=require("node:worker_threads");
const {claimSyntheticHandoff}=require("./ai-layer-v21-p6-home-action-handoff.cjs");
const {makeGateway,scratchSql,HANDLE,OWNER}=require("./ai-layer-v21-p6-home-pg-http-gateway.cjs");
if(!isMainThread){
 try{
  const response=claimSyntheticHandoff({
   sql:scratchSql,signingKey:Buffer.alloc(32,0x4f),
   userId:OWNER,contextHandle:HANDLE,locale:"ru",
   handoffToken:workerData.token,
   actionCode:"review_finalized_practice",subjectKey:"economics"});
  parentPort.postMessage({ok:response.ok===true});
 }catch(error){parentPort.postMessage({ok:false,error:String(error)});}
}else{
 const run=async()=>{
  const gw=makeGateway();
  await new Promise(done=>gw.server.listen(0,"127.0.0.1",done));
  const origin="http://127.0.0.1:"+gw.server.address().port;
  try{
   const source=await fetch(origin+"/qa/home/next",{
    method:"POST",headers:{"origin":origin,"content-type":"application/json",
     "authorization":"Bearer "+gw.ownerToken},
    body:JSON.stringify({contextHandle:HANDLE,locale:"ru"})});
   const result=await source.json();
   a.equal(source.status,200,JSON.stringify(result));
   a.match(result.handoffToken,/^[A-Za-z0-9_-]{32}$/);
   a.equal(result.actionCode,"review_finalized_practice");
   const runWorker=()=>new Promise((resolve,reject)=>{
    const worker=new Worker(__filename,{workerData:{token:result.handoffToken}});
    let settled=false;
    worker.once("message",msg=>{settled=true;resolve(msg);});
    worker.once("error",reject);
    worker.once("exit",code=>{
     if(!settled)reject(Error("worker exited before claim response: "+code));
    });
   });
   // Separate worker threads concurrently use independent psql processes
   // against a single durable PostgreSQL row. Exactly ONE UPDATE may win.
   const outcomes=await Promise.all([runWorker(),runWorker()]);
   a.equal(outcomes.filter(x=>x.ok).length,1,
    "Only one concurrent psql process can claim the same opaque token");
   a.equal(outcomes.filter(x=>!x.ok).length,1,
    "Other independent psql process must fail closed");
   a.equal(scratchSql("SELECT count(*) FROM "+
    "private.iclub_ai_v21_home_action_handoffs_scratch "+
    "WHERE consumed_at IS NOT NULL"),"1");
   a.equal(scratchSql("SELECT count(*) FROM "+
    "public.practice_sessions_v4 WHERE status='finalized'"),"2",
    "Concurrent action claims cannot alter Practice progress");
   a.equal(scratchSql("SELECT count(*) FROM "+
    "private.iclub_ai_v21_home_action_handoffs_scratch "+
    "WHERE selected_subject='economics' AND "+
    "selected_action='review_finalized_practice'"),"1");
   console.log("HOME_ACTION_TWO_WORKERS_GREEN: 1 accepted, 1 replay blocked, no student progress changes");
  }finally{
   await new Promise(resolve=>gw.server.close(resolve));
  }
 };
 run().catch(e=>{console.error("HOME_ACTION_RACE_FAIL "+String(e.stack||e));process.exitCode=1;});
}
