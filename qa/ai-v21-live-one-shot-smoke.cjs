"use strict";
// ONE isolated synthetic real-provider QA smoke. Only GitHub hosted QA job.
// Never reads learner records, service_role credentials or production scores.
const assert=require("node:assert/strict");
const {randomUUID}=require("node:crypto");
const BASE="https://mmmduffgpvwjdpruzikw.supabase.co";
const PUB="sb_publishable_OUJFpELgfrrmIIw2lF8_Sw_xEFH1M46";
const ORIGIN="https://i-club-b5clj5fau-jasurbeks-projects-c5451f97.vercel.app";
const MARKER="iclub-ai-qa-smoke-20261019-v1";
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
if(process.env.GITHUB_REF!=="refs/heads/qa/iclub-ai-layer-v21-20261012"||
   process.env.CI!=="true")throw Error("QA_ONLY_CI");
async function call(url,body,jwt){
 const ctrl=new AbortController();
 const timer=setTimeout(()=>ctrl.abort(),20000);
 try{
  const res=await fetch(BASE+url,{method:"POST",
    headers:{"apikey":PUB,"content-type":"application/json","origin":ORIGIN,
      ...(jwt?{"authorization":"Bearer "+jwt}:{})},
    body:JSON.stringify(body),signal:ctrl.signal,redirect:"error"});
  return {status:res.status,body:await res.json()};
 }finally{clearTimeout(timer)}
}
(async()=>{
 const signup=await call("/auth/v1/signup",
  {data:{iclub_global_ai_preview_pilot:"v1",no_academic_data:true,iclub_qa_smoke:MARKER}});
 assert.equal(signup.status,200,"Auth signup refused");
 assert.equal(signup.body?.user?.is_anonymous,true,"Not anonymous");
 assert.ok(signup.body?.access_token?.startsWith("eyJ"),"Missing Auth JWT");
 console.log("ISOLATED_QA_AUTH_CREATED_AWAITING_ALLOWLIST_MARKER_"+MARKER);
 const access=signup.body.access_token;
 let status;
 for(let attempt=0;attempt<48;attempt++){
   await sleep(5000);
   status=await call("/functions/v1/iclub-ai-qa-global",{intent:"status"},access);
   if(status.status===200)break;
   if(status.status!==403)throw Error("Unexpected Auth status "+status.status+
     " reason="+String(status.body?.reason||"unknown"));
 }
 assert.equal(status.status,200,"Operator was not admitted safely");
 assert.equal(status.body?.eligible,true,"Not eligible");
 assert.equal(status.body?.fundedPilot,true,"Money OFF");
 assert.equal(status.body?.providerConfigured,true,"Provider secret absent");
 console.log("SIGNED_IN_QA_STATUS_READY");
 const ask=await call("/functions/v1/iclub-ai-qa-global",{
  intent:"ask",request_id:randomUUID(),locale:"ru",screen_code:"home",
  scope_code:"global",prompt_key:"home_next",user_text:"что делать дальше"
 },access);
 assert.equal(ask.status,200,"Provider failed: HTTP "+ask.status+
   " reason="+String(ask.body?.reason||"unknown"));
 assert.equal(ask.body?.ok,true,"No model response");
 assert.equal(ask.body?.provider_called,true,"No provider call");
 assert.equal(ask.body?.academic_state_changed,false,"Academic write forbidden");
 assert.ok(typeof ask.body?.message==="string"&&ask.body.message.length>12,"Empty reply");
 assert.ok(Number.isSafeInteger(ask.body?.accounted_micro_usd)&&
   ask.body.accounted_micro_usd>=0&&ask.body.accounted_micro_usd<=10000,"Missing accounting");
 console.log("REAL_MODEL_REPLY_CONFIRMED");
 console.log("REAL_MODEL_CHARGED_MICROUSD="+ask.body.accounted_micro_usd);
 console.log("REPLY_LENGTH="+ask.body.message.length);
})().catch(err=>{console.error("QA_SMOKE_FAILED:",String(err.message));process.exitCode=1});
