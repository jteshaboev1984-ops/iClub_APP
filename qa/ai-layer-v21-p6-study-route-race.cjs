"use strict";
// Two INDEPENDENT worker threads and independent psql child processes
// compete for ONE consumed synthetic Home choice. Never live Supabase.
const {Worker,isMainThread,workerData,parentPort}=require("node:worker_threads");
const assert=require("node:assert/strict");
const {createHash}=require("node:crypto");
const {makeGateway,scratchSql,HANDLE}=
 require("./ai-layer-v21-p6-home-pg-http-gateway.cjs");
const {openSyntheticStudy}=require("./ai-layer-v21-p6-study-route.cjs");
if(!isMainThread){
 parentPort.postMessage({ready:true});
 parentPort.once("message",async()=>{
  let outcome;
  try{
   outcome=openSyntheticStudy({sql:scratchSql,
    signingKey:Buffer.alloc(32,0x4f),...workerData});
  }catch{outcome={ok:false};}
  parentPort.postMessage({done:true,ok:outcome.ok===true,
   routeToken:outcome.ok===true?outcome.routeToken:null});
 });
}else{
 async function run(){
  const g=makeGateway();
  await new Promise(resolve=>g.server.listen(0,"127.0.0.1",resolve));
  const origin="http://127.0.0.1:"+g.server.address().port;
  const post=async(path,body)=>{
   const res=await fetch(origin+path,{method:"POST",
    headers:{"origin":origin,"content-type":"application/json",
     "authorization":"Bearer "+g.ownerToken},body:JSON.stringify(body)});
   return {status:res.status,body:await res.json()};
  };
  const employees=[];
  try{
   const before=scratchSql("SELECT count(*) FROM "+
    "public.practice_session_answers_v4 WHERE session_id=901 AND is_correct=false");
   const next=await post("/qa/home/next",{contextHandle:HANDLE,locale:"ru"});
   assert.equal(next.status,200,JSON.stringify(next));
   assert.equal(next.body.actionCode,"review_finalized_practice");
   const handoffToken=next.body.handoffToken;
   const data={userId:g.ownerId,contextHandle:HANDLE,locale:"ru",
    handoffToken,actionCode:"review_finalized_practice",subjectKey:"economics"};
   const confirmed=await post("/qa/home/confirm",{
    contextHandle:HANDLE,locale:"ru",handoffToken,
    actionCode:data.actionCode,subjectKey:data.subjectKey});
   assert.equal(confirmed.status,200,JSON.stringify(confirmed));
   for(let i=0;i<2;i++){
    const worker=new Worker(__filename,{workerData:data});
    employees.push(worker);
   }
   const resultPromises=employees.map(worker=>new Promise((resolve,reject)=>{
    const onMessage=v=>{if(v.done){worker.off("message",onMessage);resolve(v);}};
    worker.on("message",onMessage);
    worker.on("error",reject);
   }));
   await Promise.all(employees.map(w=>new Promise((resolve,reject)=>{
    const handler=v=>{if(v.ready){w.off("message",handler);resolve();}};
    w.on("message",handler);w.once("error",reject);
   })));
   // Barrier: neither worker begins the SQL authorization/insert until both
   // have reached the same starting line.
   employees.forEach(w=>w.postMessage("go"));
   const outcomes=await Promise.all(resultPromises);
   assert.deepEqual(outcomes.map(x=>x.ok).sort(),[false,true],
    "Only one independently authorised PostgreSQL issuer may enter");
   const winner=outcomes.find(x=>x.ok);
   const sha=createHash("sha256").update(handoffToken).digest("hex");
   assert.equal(scratchSql("SELECT count(*) FROM "+
    "private.iclub_ai_v21_study_routes_scratch WHERE home_handoff_sha256='"+
    sha+"'"),"1");
   assert.equal((await post("/qa/study/read",{
    locale:"ru",routeToken:winner.routeToken})).status,200);
   assert.equal((await post("/qa/study/close",{
    locale:"ru",routeToken:winner.routeToken})).status,200);
   assert.equal(scratchSql("SELECT count(*) FROM "+
    "public.practice_session_answers_v4 WHERE session_id=901 AND is_correct=false"),before,
    "Parallel navigation never changes user academic evidence");
   console.log("HOME_STUDY_TWO_WORKERS_GREEN: 1 study screen opened, "+
    "1 independent denial, both psql processes, student evidence unchanged");
  }finally{
   await Promise.all(employees.map(w=>w.terminate()));
   await new Promise(resolve=>g.server.close(resolve));
  }
 }
 run().catch(e=>{
  console.error("HOME_STUDY_TWO_WORKERS_FAIL: "+String(e.stack||e));
  process.exitCode=1;
 });
}
