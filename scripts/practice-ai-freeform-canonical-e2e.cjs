"use strict";
// Disposable real Edge + canonical accounting SQL + fake provider, NO paid call.
const assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path"),
 http=require("node:http"),{spawn,spawnSync}=require("node:child_process");
if(process.env.PGHOST!=="127.0.0.1"||process.env.PGDATABASE!=="postgres"||
 !String(process.env.PGOPTIONS).includes("iclub.isolated_practice_context=true"))
 throw Error("isolated Postgres required");
const DIR=path.resolve(__dirname,"../supabase/functions/iclub-ai-practice-freeform");
const PROD="https://mmmduffgpvwjdpruzikw.supabase.co",USER="00000000-0000-4000-8000-000000000011";
const JWT="fake-token-"+"a".repeat(64),
 OTHER_JWT="fake-token-"+"f".repeat(64),
 OTHER_USER="00000000-0000-4000-8000-000000000022",
 ANON="fake-anon-"+"b".repeat(64),
 SERVICE="fake-service-"+"c".repeat(64),MODELKEY="fake-model-"+"d".repeat(64);
const ID="eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee",PORT=18769;
const GOTRUE=process.env.ICLUB_AUTH_GOTRUE_URI||"";
let realOwner=null,realOther=null;
const uuidRe=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
async function realLogin(label){
 if(!/^http:\/\/127\.0\.0\.1:\d+$/.test(GOTRUE))
  throw Error("Refused non-loopback isolated Auth endpoint");
 const email="iclub-practice-ci-"+label+"@example.com";
 const password="Temporary-Only-GoTrue-CI-"+label+"-2026!";
 const signup=await fetch(GOTRUE+"/signup",{method:"POST",
  headers:{"content-type":"application/json"},body:JSON.stringify({email,password})});
 if(!signup.ok)throw Error("Isolated GoTrue signup failed "+signup.status+
   " "+(await signup.text()).slice(0,180));
 const signIn=await fetch(GOTRUE+"/token?grant_type=password",{
  method:"POST",headers:{"content-type":"application/json"},
  body:JSON.stringify({email,password})});
 if(!signIn.ok)throw Error("Isolated GoTrue password grant failed "+signIn.status+
  " "+(await signIn.text()).slice(0,180));
 const {access_token:token}=await signIn.json();
 if(typeof token!=="string"||token.length<24)throw Error("No real Auth JWT");
 const verified=await fetch(GOTRUE+"/user",{headers:{authorization:"Bearer "+token}});
 if(!verified.ok)throw Error("Real GoTrue rejected issued token");
 const user=await verified.json();
 if(!uuidRe.test(user.id)||user.role!=="authenticated")throw Error("Invalid GoTrue principal");
 return {id:user.id,token};
}
const spec={
 get_iclub_ai_practice_context_v1_service:["p_user_id:uuid","p_attempt_id:bigint","p_intent:text","p_question_id:bigint","p_locale:text"],
 iclub_ai_practice_freeform_pc3_gate_service:[],
 iclub_ai_practice_receipt_pc4_service:["p_action:text","p_request_id:uuid","p_user_id:uuid","p_attempt_ref:bigint","p_request_fingerprint:text","p_context_fingerprint:text","p_source_fingerprint:text","p_locale:text","p_answer:text","p_actual_microusd:bigint"],
 iclub_ai_practice_recover_pc4_service:["p_user_id:uuid","p_attempt_ref:bigint","p_locale:text","p_request_id:uuid"],
 reserve_iclub_ai_v21_freeform_quota_v1:["p_request_id:uuid","p_user_id:uuid","p_request_fingerprint:text"],
 reserve_iclub_ai_v21_freeform_budget_v1:["p_request_id:uuid","p_user_id:uuid","p_session_fingerprint:text","p_request_fingerprint:text","p_source_fingerprint:text","p_source_version:text","p_locale:text"],
 dispatch_iclub_ai_v21_freeform_budget_v1:["p_request_id:uuid","p_user_id:uuid","p_session_fingerprint:text","p_request_fingerprint:text"],
 settle_iclub_ai_v21_freeform_budget_v1:["p_request_id:uuid","p_user_id:uuid","p_session_fingerprint:text","p_request_fingerprint:text","p_outcome:text","p_actual_microusd:bigint"],
 finish_iclub_ai_v21_freeform_quota_v1:["p_request_id:uuid","p_user_id:uuid","p_request_fingerprint:text","p_outcome:text"]
};
const cast=(v,t)=>{
 if(v==null)return "NULL::"+t;
 if(t==="bigint"&&!Number.isSafeInteger(v))throw Error("invalid integer");
 if(t==="uuid"&&!/^[0-9a-f-]{36}$/i.test(v))throw Error("invalid UUID");
 if(t==="text"&&(typeof v!=="string"||v.length>2600))throw Error("invalid text");
 return "'"+String(v).replace(/'/g,"''")+"'::"+t;
};
function pg(q){
 const sql="BEGIN; SET LOCAL request.jwt.claim.role='service_role'; "+q+" COMMIT;";
 const p=spawnSync("psql",["-X","-q","-A","-t","-v","ON_ERROR_STOP=1","-c",sql],
  {env:process.env,encoding:"utf8",timeout:6500});
 if(p.status!==0)throw Error("Postgres: "+String(p.stderr).slice(0,650));
 const lines=p.stdout.trim().split(/\r?\n/).filter(x=>x&&x!=="BEGIN"&&x!=="COMMIT");
 return lines[0]||"";
}
function rpc(fn,obj){
 if(!Object.hasOwn(spec,fn)||!obj||typeof obj!=="object")throw Error("RPC rejected");
 const defs=spec[fn];
 if(Object.keys(obj).some(k=>!defs.some(s=>s.startsWith(k+":"))))throw Error("unknown RPC argument");
 const args=defs.map(d=>{const [k,t]=d.split(":");return cast(obj[k],t)});
 return JSON.parse(pg("SELECT public."+fn+"("+args.join(",")+")::text;"));
}
function state(){
 const q="SELECT json_build_object("+
 "'money',(SELECT state FROM private.iclub_ai_v21_freeform_budget_ledger WHERE request_id='"+ID+"'),"+
 "'cost',(SELECT actual_microusd FROM private.iclub_ai_v21_freeform_budget_ledger WHERE request_id='"+ID+"'),"+
 "'quota',(SELECT state FROM private.iclub_ai_v21_freeform_quota_holds WHERE request_id='"+ID+"'),"+
 "'usage',(SELECT committed_count FROM private.iclub_ai_v21_beta_usage WHERE user_id='"+USER+"'),"+
 "'receipt',(SELECT status FROM private.iclub_ai_practice_receipts_v1 WHERE request_id='"+ID+"'),"+
 "'accounted',(SELECT quota_confirmed_at IS NOT NULL FROM private.iclub_ai_practice_receipts_v1 WHERE request_id='"+ID+"'))::text;";
 return JSON.parse(pg(q));
}

async function testBrowserGoTrue({edge,answer,receiptId,ownerId,providerCalls}){
  if(!GOTRUE||!realOwner||!realOther)throw Error("Local GoTrue missing");
  const {chromium}=require("playwright"),esbuild=require("esbuild");
  const root=path.resolve(__dirname,"..");
  const html=fs.readFileSync(path.join(root,"scripts/fixtures/practice-ai-unified-tutor-local-only.html"),"utf8")
    .replaceAll('data-practice-ai-attempt-id="501"','data-practice-ai-attempt-id="701"');
  const jsClient=fs.readFileSync(path.join(root,"iclub-ai-v21-beta-client.js"),"utf8");
  const jsTutor=fs.readFileSync(path.join(root,"iclub-ai-v21-ui.js"),"utf8");
  const css=fs.readFileSync(path.join(root,"iclub-ai-v21-ui.css"),"utf8");
  const bundle=await esbuild.build({
    stdin:{contents:'import {createClient} from "@supabase/supabase-js";window.__makeRealAuthClient=createClient;',
      resolveDir:root,sourcefile:"real-auth-browser-entry.js"},
    platform:"browser",format:"iife",target:"chrome110",
    bundle:true,write:false,logLevel:"silent"
  });
  let site=null,browser=null;
  const browserErrors=[],escaped=[],requests=[],authPaths=[];
  try{
    site=http.createServer((req,res)=>{
      res.writeHead(req.url==="/"?200:404,{"content-type":"text/html; charset=utf-8"});
      res.end(req.url==="/"?html:"Not found");
    });
    await new Promise(ok=>site.listen(0,"127.0.0.1",ok));
    const origin="http://127.0.0.1:"+site.address().port;
    browser=await chromium.launch({headless:true});
    const page=await browser.newPage({viewport:{width:1024,height:768}});
    page.on("pageerror",e=>browserErrors.push(e.message));
    await page.route("**/*",async route=>{
      const req=route.request(),url=req.url(),method=req.method();
      if(url.startsWith(origin+"/"))return route.continue();
      if(!url.startsWith(PROD+"/")){
        escaped.push(url);return route.abort("blockedbyclient");
      }
      const u=new URL(url),pathName=u.pathname,bearer=req.headers().authorization||"";
      const h={"access-control-allow-origin":origin,"access-control-allow-methods":"GET,POST,OPTIONS",
        "access-control-allow-headers":"authorization,apikey,content-type,x-client-info",
        "content-type":"application/json; charset=utf-8","vary":"Origin"};
      if(method==="OPTIONS")return route.fulfill({status:204,headers:h,body:""});
      if(pathName.startsWith("/auth/v1/")){
        const upstream=await fetch(GOTRUE+pathName.slice(8)+u.search,{
          method,headers:{"content-type":"application/json",authorization:bearer},
          body:method==="GET"?undefined:req.postData()
        });
        authPaths.push(pathName);
        return route.fulfill({status:upstream.status,headers:h,body:await upstream.text()});
      }
      if(pathName.endsWith("/iclub-ai-v21-prepared")||
         pathName.endsWith("/iclub-ai-practice-prepared")){
        const check=await fetch(GOTRUE+"/user",{headers:{authorization:bearer}});
        const person=check.ok?await check.json():null;
        const valid=person?.id===ownerId;
        const response=pathName.endsWith("/iclub-ai-v21-prepared")
          ?{ok:true,eligible:valid,consented:valid,candidate:false}
          :{ok:true,available:valid,mode:"availability",provider_called:false,academic_state_changed:false};
        // Only UI preflight is stubbed; PC3/PC4 still use real Edge/Auth/DB.
        return route.fulfill({status:200,headers:h,body:JSON.stringify(response)});
      }
      if(pathName.endsWith("/iclub-ai-practice-freeform")){
        const body=JSON.parse(req.postData()||"{}");
        requests.push({operation:body.operation,request_id:body.request_id});
        const upstream=await fetch(edge,{method:"POST",headers:{
          origin,authorization:bearer,"content-type":"application/json"
        },body:req.postData()});
        return route.fulfill({status:upstream.status,headers:h,body:await upstream.text()});
      }
      escaped.push(url);return route.abort("blockedbyclient");
    });
    await page.goto(origin+"/",{waitUntil:"domcontentloaded"});
    await page.addScriptTag({content:bundle.outputFiles[0].text});
    const loggedIn=await page.evaluate(async()=>{
      window.i18n={getLang:()=>"ru"};
      window.sb=window.__makeRealAuthClient("https://mmmduffgpvwjdpruzikw.supabase.co",
        "fake-anon-"+"b".repeat(64),{auth:{persistSession:false,
          autoRefreshToken:false,detectSessionInUrl:false}});
      const {data,error}=await window.sb.auth.signInWithPassword({
        email:"iclub-practice-ci-owner@example.com",
        password:"Temporary-Only-GoTrue-CI-owner-2026!"
      });
      if(error)throw Error("Browser GoTrue sign-in failed: "+error.message);
      const u=await window.sb.auth.getUser();
      if(u.error||u.data.user?.id!==data.user.id)throw Error("Browser Auth /user failed");
      return data.user.id;
    });
    assert.equal(loggedIn,ownerId,"Wrong actual browser Auth principal");
    await page.addStyleTag({content:css});
    await page.addScriptTag({content:jsClient});
    await page.addScriptTag({content:jsTutor});
    await page.locator("#iclub-global-ai-mark").waitFor({timeout:10000});
    await page.evaluate(()=>window.iClubGlobalAiShell.open());
    await page.waitForFunction(expected=>{
      const text=document.querySelector("[data-global-ai-messages]")?.textContent||"";
      return text.includes("Восстановлен ответ")&&text.includes(expected);
    },answer,{timeout:14000});
    await page.waitForFunction(()=>{
      const quick=document.querySelector("[data-global-ai-quick]");
      return !!quick&&!quick.textContent.includes("Восстановить ответ");
    },null,{timeout:10000});
    const content=await page.locator("[data-global-ai-messages]").textContent();
    assert.equal(content.split(answer).length-1,1,"Real browser duplicated saved answer");
    assert.equal(requests.filter(x=>x.operation==="resume").length,1);
    assert.equal(requests.filter(x=>x.operation==="resume_ack"&&x.request_id===receiptId).length,1);
    assert.equal(providerCalls(),1,"Browser recovery generated new model answer");
    // Disposable quota window rollover (never applied to real accounts).
    // Now ask a NEW question through the genuine signed-in browser -> Edge.
    pg("UPDATE private.iclub_ai_v21_beta_usage "+
      "SET started_at=clock_timestamp()-interval '6 hours' "+
      "WHERE user_id='"+ownerId+"'; SELECT 'TEST_WINDOW_RESET'::text;");
    await page.locator("[data-global-ai-input]").fill("Что означает мой результат 70%?");
    await page.locator("[data-global-ai-send]").click();
    await page.waitForFunction(expected=>{
      const text=document.querySelector("[data-global-ai-messages]")?.textContent||"";
      return text.split(expected).length-1===2;
    },answer,{timeout:14000});
    for(let tries=0;tries<45&&!requests.some(x=>x.operation==="ack");tries++)
      await new Promise(ok=>setTimeout(ok,100));
    const freshAsk=requests.find(x=>x.operation==="ask");
    assert(freshAsk,"Genuine browser did not send a new Practice question");
    assert(requests.some(x=>x.operation==="ack"&&x.request_id===freshAsk.request_id),
      "Real browser did not ACK its newly generated answer");
    assert.equal(providerCalls(),2,"Genuine browser request must use one provider dispatch");
    const newReceipt=JSON.parse(pg("SELECT json_build_object("+
      "'money',(SELECT state FROM private.iclub_ai_v21_freeform_budget_ledger "+
        "WHERE request_id='"+freshAsk.request_id+"'),"+
      "'quota',(SELECT state FROM private.iclub_ai_v21_freeform_quota_holds "+
        "WHERE request_id='"+freshAsk.request_id+"'),"+
      "'receipt',(SELECT status FROM private.iclub_ai_practice_receipts_v1 "+
        "WHERE request_id='"+freshAsk.request_id+"'))::text;"));
    assert.deepEqual(newReceipt,{money:"charged",quota:"completed",receipt:"acknowledged"});
    assert.equal(await page.evaluate(()=>localStorage.length),0,"AI answer stored on device");
    await page.evaluate(()=>window.sb.auth.signOut());
    const foreign=await page.evaluate(async()=>{
      const {data,error}=await window.sb.auth.signInWithPassword({
        email:"iclub-practice-ci-other@example.com",
        password:"Temporary-Only-GoTrue-CI-other-2026!"
      });
      if(error)throw Error("Other GoTrue browser login failed");
      return data.user.id;
    });
    assert.equal(foreign,realOther.id);
    await page.waitForFunction(()=>{
      const t=document.querySelector("[data-global-ai-messages]")?.textContent||"";
      return !t.includes("Восстановлен ответ");
    },null,{timeout:9000});
    assert.equal(providerCalls(),2,"Foreign account dispatched the provider");
    assert.deepEqual(escaped,[],"Real Auth browser contacted external site");
    assert.deepEqual(browserErrors,[],"Browser script errors");
    assert(authPaths.includes("/auth/v1/token")&&authPaths.includes("/auth/v1/user"),
      "Browser must use actual GoTrue password and /user endpoints");
    console.log("PASS REAL Supabase JS browser sign-in / GoTrue JWT / Tutor recovery + new typed question -> actual Edge / ACK / foreign account isolation");
    console.log("PASS real Edge + database, local-only network, zero browser answer storage, no model replay");
  }finally{
    if(browser)await browser.close();
    if(site)await new Promise(ok=>site.close(ok));
  }
}

let calls=0,failures=[];
const respond=(res,status,obj)=>{res.writeHead(status,{"content-type":"application/json"});res.end(JSON.stringify(obj));};
async function main(){
 let server,deno,tmp;
 try{
  if(GOTRUE){
   [realOwner,realOther]=await Promise.all([realLogin("owner"),realLogin("other")]);
   assert.notEqual(realOwner.id,realOther.id);
  }
  server=http.createServer(async(req,res)=>{
   try{
    const loc=new URL(req.url,"http://localhost").pathname;
    if(loc==="/auth/v1/user"){
     if(req.headers.apikey!==ANON)return respond(res,401,{error:"auth"});
     if(req.headers.authorization==="Bearer "+JWT)
      return respond(res,200,{id:USER,role:"authenticated"});
     if(req.headers.authorization==="Bearer "+OTHER_JWT)
      return respond(res,200,{id:OTHER_USER,role:"authenticated"});
     if(GOTRUE){
      const upstream=await fetch(GOTRUE+"/user",{
       headers:{authorization:req.headers.authorization||""}});
      return respond(res,upstream.status,await upstream.json());
     }
     return respond(res,401,{error:"auth"});
    }
    if(loc==="/provider"){
     calls++;
     if(req.headers.authorization!=="Bearer "+MODELKEY)throw Error("bad provider auth");
     let raw="";for await(const chunk of req)raw+=chunk;
     const p=JSON.parse(raw);
     assert.equal(p.model,"gpt-5.4-mini");
     assert.equal(p.max_output_tokens,384);
     assert.match(p.instructions,/"correct":7/);
     assert.doesNotMatch(p.instructions,/reviewable_error_ordinals/);
     // Simulate real consent revocation WHILE the provider has already
     // received a request. The generated result must never be shown.
     if(String(p.input||"").includes("после отзыва")){
      pg("UPDATE private.iclub_ai_v21_beta_members SET enabled=false "+
       "WHERE user_id='"+USER+"'; SELECT 'REVOKED'::text;");
     }
     if(String(p.input||"").includes("после выключения")){
      pg("UPDATE private.iclub_ai_practice_freeform_pc3_control "+
       "SET enabled=false WHERE singleton=1; SELECT 'PC3_KILLED'::text;");
     }
     // Provider may have charged despite a failed response.
     if(String(p.input||"").includes("после сбоя"))
      return respond(res,503,{error:"synthetic_provider_outcome_unknown"});
     return respond(res,200,{status:"completed",model:"gpt-5.4-mini",
      usage:{input_tokens:320,output_tokens:58},
      output:[{type:"message",role:"assistant",status:"completed",content:[{
       type:"output_text",text:"Результат 70% означает, что 7 ответов из 10 правильные. Повторите материал, относящийся к ошибкам, затем попробуйте ещё раз."}]}]});
    }
    if(loc.startsWith("/rest/v1/rpc/")){
     if(req.headers.authorization!=="Bearer "+SERVICE||req.headers.apikey!==SERVICE)
      return respond(res,403,{error:"service forbidden"});
     let raw="";for await(const chunk of req)raw+=chunk;
     const fn=loc.substring("/rest/v1/rpc/".length);
     const params=JSON.parse(raw);
     const result=rpc(fn,params);
     // The canonical quota reservation COMMITTED, but its HTTP response
     // never reached the Edge. The Edge must try a compensating release.
     if(fn==="reserve_iclub_ai_v21_freeform_quota_v1" &&
        params.p_request_id==="77777777-7777-4777-8777-777777777777")
       return respond(res,503,{error:"simulated_lost_quota_reservation_ack"});
     return respond(res,200,result);
    }
    throw Error("unknown path "+loc);
   }catch(e){failures.push(String(e));respond(res,500,{error:"synthetic gateway failed"});}
  });
  await new Promise(resolve=>server.listen(0,"127.0.0.1",resolve));
  const host="http://127.0.0.1:"+server.address().port;
  let code=fs.readFileSync(path.join(DIR,"index.ts"),"utf8");
  assert(code.includes('const BASE="'+PROD+'";'));
  assert(code.includes("Deno.serve(async"));
  code=code.replace('const BASE="'+PROD+'";','const BASE="'+host+'";')
    .replace(/const ORIGIN=.*;/,'const ORIGIN=/^http:\\/\\/127\\.0\\.0\\.1:\\d+$/;')
    .replace("https://api.openai.com/v1/responses",host+"/provider")
    .replace("Deno.serve(async",'Deno.serve({hostname:"127.0.0.1",port:'+PORT+'},async');
  tmp=path.join(DIR,"isolated_freeform_"+process.pid+".ts");
  fs.writeFileSync(tmp,code);
  deno=spawn("deno",["run","--quiet","--allow-net=127.0.0.1",
   "--allow-env=SUPABASE_URL,SUPABASE_ANON_KEY,SUPABASE_SERVICE_ROLE_KEY,OPENAI_API_KEY",tmp],
   {env:{...process.env,SUPABASE_URL:host,SUPABASE_ANON_KEY:ANON,
    SUPABASE_SERVICE_ROLE_KEY:SERVICE,OPENAI_API_KEY:MODELKEY},
    stdio:["ignore","pipe","pipe"]});
  let stderr="";deno.stderr.on("data",d=>{stderr+=d;});
  const edge="http://127.0.0.1:"+PORT+"/";
  let started=false;
  for(let n=0;n<100;n++){
   if(deno.exitCode!==null)throw Error("Edge exited "+stderr.slice(-800));
   try{const p=await fetch(edge,{headers:{Origin:host}});if(p.status===405){started=true;break;}}catch{}
   await new Promise(ok=>setTimeout(ok,100));
  }
  if(!started)throw Error("Edge startup "+stderr.slice(-800));
  const Q="Что означает мой результат 70%?";
  async function send(op,question=Q,id=ID,opts={}){
   const r=await fetch(edge,{method:"POST",headers:{
     Origin:opts.origin||host,
     authorization:"Bearer "+(opts.token||JWT),"content-type":"application/json"},
    body:JSON.stringify({intent:"practice_freeform",operation:op,request_id:id,
     purpose:"practice_result",attempt_ref:opts.attempt||501,
     question_ref:null,locale:"ru",question})});
   return{status:r.status,body:await r.json()};
  }
  const noSource=await send("ask","Реши задачу №6 и объясни почему неверно",
    "ffffffff-ffff-4fff-8fff-ffffffffffff");
  assert.equal(noSource.status,403,JSON.stringify(noSource));
  assert.equal(calls,0);
  // Two verified principals against the LOCAL auth imitation. Only the
  // real owner of the finalized synthetic attempt may spend quota.
  const badJwt=await send("ask",Q,
    "abababab-abab-4bab-8bab-abababababab",{token:"invalid-token-"+"z".repeat(64)});
  assert.equal(badJwt.status,401,JSON.stringify(badJwt));
  const badOrigin=await send("ask",Q,
    "bcbcbcbc-bcbc-4cbc-8cbc-bcbcbcbcbcbc",
    {origin:"https://untrusted.example"});
  assert.equal(badOrigin.status,403,JSON.stringify(badOrigin));
  const foreignAsk=await send("ask",Q,
    "cdcdcdcd-cdcd-4dcd-8dcd-cdcdcdcdcdcd",{token:OTHER_JWT});
  assert.equal(foreignAsk.status,403,JSON.stringify(foreignAsk));
  assert.equal(foreignAsk.body.reason,"context_or_source_not_ready");
  const missingAttempt=await send("ask",Q,
    "dededede-dede-4ded-8ded-dededededede",{attempt:999});
  assert.equal(missingAttempt.status,403,JSON.stringify(missingAttempt));
  assert.equal(calls,0,"Unauthorized identity/origin/attempt triggered model");
  const first=await send("ask");
  assert.equal(first.status,200,JSON.stringify({first,failures,stderr:stderr.slice(-600)}));
  assert.equal(first.body.delivery_state,"pending_ack");
  assert.equal(first.body.provider_called,true);
  assert.equal(calls,1);
  const before=state();
  assert.equal(before.money,"charged");
  assert.equal(before.quota,"reserved");
  assert.equal(before.receipt,"ready");
  assert.equal(before.usage,3);
  // Simulate a full browser reload: NO retained question or UUID.
  // Another client discovers the newest charged receipt by owned attempt.
  const newSessionId="cccccccc-cccc-4ccc-8ccc-cccccccccccc";
  const recovered=await send("resume",null,newSessionId);
  assert.equal(recovered.status,200,JSON.stringify(recovered));
  assert.equal(recovered.body.recovered,true);
  assert.equal(recovered.body.request_id,ID);
  assert.equal(recovered.body.message,first.body.message);
  assert.equal(recovered.body.provider_called,false);
  assert.equal(calls,1);
  const foreignReplay=await send("resume",null,newSessionId,{token:OTHER_JWT});
  assert.equal(foreignReplay.status,409,JSON.stringify(foreignReplay));
  assert.equal(foreignReplay.body.reason,"context_or_source_not_ready");
  assert.equal(calls,1,"Another account obtained the original AI response");
  // Existing same-UUID recovery remains idempotent for network retries.
  const saved=await send("ask");
  assert.equal(saved.status,200,JSON.stringify(saved));
  assert.equal(saved.body.message,first.body.message);
  assert.equal(saved.body.provider_called,false);
  assert.equal(calls,1);
  const ack=await send("resume_ack",null,ID);
  assert.equal(ack.status,200,JSON.stringify(ack));
  assert.equal(ack.body.request_id,ID);
  const final=state();
  assert.deepEqual([final.money,final.cost,final.quota,final.receipt,final.accounted],
    ["charged",501,"completed","acknowledged",true]);
  assert.equal(final.usage,3);
  const again=await send("ack");
  assert.equal(again.status,200,JSON.stringify(again));
  const alreadyRecovered=await send("resume",null,newSessionId);
  assert.equal(alreadyRecovered.status,409,JSON.stringify(alreadyRecovered));
  assert.equal(alreadyRecovered.body.reason,"no_pending_answer");
  assert.equal(calls,1);
  const conflict=await send("ask","Какой мой процент и результат?");
  assert.equal(conflict.status,409);
  assert.equal(conflict.body.reason,"request_conflict");
  assert.equal(calls,1);
  // In a disposable DB, advance the learner's quota WINDOW beyond 5 hours.
  // This tests a second legitimately permitted request, not a quota bypass.
  pg("UPDATE private.iclub_ai_v21_beta_usage "+
     "SET started_at=clock_timestamp()-interval '6 hours' "+
     "WHERE user_id='"+USER+"'; SELECT 'NEXT_PERIOD'::text;");
  const unknownId="99999999-9999-4999-8999-999999999999";
  const unknownQuestion="Что означает мой результат 70% после сбоя?";
  const uncertain=await send("ask",unknownQuestion,unknownId);
  assert.equal(uncertain.status,409,JSON.stringify(uncertain));
  assert.equal(uncertain.body.reason,"provider_outcome_unverified");
  assert.equal(calls,2);
  const unknownLedger=JSON.parse(pg("SELECT json_build_object("+
   "'money',(SELECT state FROM private.iclub_ai_v21_freeform_budget_ledger WHERE request_id='"+unknownId+"'),"+
   "'quota',(SELECT state FROM private.iclub_ai_v21_freeform_quota_holds WHERE request_id='"+unknownId+"'),"+
   "'receipt',(SELECT status FROM private.iclub_ai_practice_receipts_v1 WHERE request_id='"+unknownId+"'))::text;"));
  assert.deepEqual(unknownLedger,{money:"unknown",quota:"released",receipt:"unknown"});
  const repeatedUnknown=await send("ask",unknownQuestion,unknownId);
  assert.equal(repeatedUnknown.status,409);
  assert.equal(repeatedUnknown.body.reason,"request_already_in_progress");
  assert.equal(calls,2,"Unknown provider charge must never retrigger generation");
  const recoverUnknown=await send("resume",null,newSessionId);
  assert.equal(recoverUnknown.status,409);
  assert.equal(recoverUnknown.body.reason,"no_pending_answer");
  const lostQuotaId="77777777-7777-4777-8777-777777777777";
  const quotaLost=await send("ask","Что означает мой результат 70% при потере связи?",lostQuotaId);
  assert.equal(quotaLost.status,409,JSON.stringify(quotaLost));
  assert.equal(quotaLost.body.reason,"usage_or_access_unavailable");
  const quotaLedger=JSON.parse(pg("SELECT json_build_object("+
   "'quota',(SELECT state FROM private.iclub_ai_v21_freeform_quota_holds WHERE request_id='"+lostQuotaId+"'),"+
   "'money',(SELECT state FROM private.iclub_ai_v21_freeform_budget_ledger WHERE request_id='"+lostQuotaId+"'),"+
   "'receipt',(SELECT status FROM private.iclub_ai_practice_receipts_v1 WHERE request_id='"+lostQuotaId+"'))::text;"));
  assert.deepEqual(quotaLedger,{quota:"released",money:null,receipt:"void"},
    "Lost quota-ack should not permanently reduce learner entitlement");
  assert.equal(calls,2,"Lost quota ACK must never dispatch model");
  // Revocation between provider request and provider response.
  // Provider cost must be recorded, quota released and receipt closed,
  // but NO academic answer should reach the user.
  pg("UPDATE private.iclub_ai_v21_beta_usage "+
    "SET started_at=clock_timestamp()-interval '6 hours' "+
    "WHERE user_id='"+USER+"'; SELECT 'NEXT_PERIOD'::text;");
  const revokeId="44444444-4444-4444-8444-444444444444";
  const revoked=await send("ask","Что означает мой результат 70% после отзыва?",revokeId);
  assert.equal(revoked.status,409,JSON.stringify(revoked));
  assert.equal(revoked.body.reason,"context_changed_after_provider");
  assert.equal(revoked.body.message,undefined,"Revoked learner received provider answer");
  const revocationLedger=JSON.parse(pg("SELECT json_build_object("+
   "'money',(SELECT state FROM private.iclub_ai_v21_freeform_budget_ledger WHERE request_id='"+revokeId+"'),"+
   "'quota',(SELECT state FROM private.iclub_ai_v21_freeform_quota_holds WHERE request_id='"+revokeId+"'),"+
   "'receipt',(SELECT status FROM private.iclub_ai_practice_receipts_v1 WHERE request_id='"+revokeId+"'))::text;"));
  assert.deepEqual(revocationLedger,{money:"charged",quota:"released",receipt:"unknown"},
   "Owner consent withdrawal left an unaccounted in-flight provider request");
  const providerCallsAfterRevocation=calls;
  const deniedDuringRevocation=await send("ask",Q,"33333333-3333-4333-8333-333333333333");
  assert.equal(deniedDuringRevocation.status,403);
  assert.equal(calls,providerCallsAfterRevocation,"Revoked user dispatched a new provider request");
  pg("UPDATE private.iclub_ai_v21_beta_members SET enabled=true "+
     "WHERE user_id='"+USER+"'; SELECT 'REGRANTED'::text;");
  const repeatRevoked=await send("ask","Что означает мой результат 70% после отзыва?",revokeId);
  assert.equal(repeatRevoked.status,409);
  assert.equal(repeatRevoked.body.reason,"request_already_in_progress");
  assert.equal(calls,providerCallsAfterRevocation,
     "Same revoked UUID triggered a second model dispatch after regrant");
  // Administrator disables PC3 WHILE the fake provider responds.
  // No response may escape after the kill switch, but a real provider
  // charge must still be recorded and learner quota returned.
  pg("UPDATE private.iclub_ai_v21_beta_usage "+
    "SET started_at=clock_timestamp()-interval '6 hours' "+
    "WHERE user_id='"+USER+"'; SELECT 'NEXT_PERIOD'::text;");
  const killedId="22222222-2222-4222-8222-222222222222";
  const killedQuestion="Что означает мой результат 70% после выключения?";
  const killed=await send("ask",killedQuestion,killedId);
  assert.equal(killed.status,409,JSON.stringify(killed));
  assert.equal(killed.body.reason,"context_changed_after_provider");
  assert.equal(killed.body.message,undefined,"AI answer leaked after feature was killed");
  const killedLedger=JSON.parse(pg("SELECT json_build_object("+
   "'money',(SELECT state FROM private.iclub_ai_v21_freeform_budget_ledger WHERE request_id='"+killedId+"'),"+
   "'quota',(SELECT state FROM private.iclub_ai_v21_freeform_quota_holds WHERE request_id='"+killedId+"'),"+
   "'receipt',(SELECT status FROM private.iclub_ai_practice_receipts_v1 WHERE request_id='"+killedId+"'))::text;"));
  assert.deepEqual(killedLedger,{money:"charged",quota:"released",receipt:"unknown"},
    "Kill switch prevented required in-flight financial cleanup");
  const callsAfterKill=calls;
  const blocked=await send("ask",Q,"11111111-1111-4111-8111-111111111111");
  assert.equal(blocked.status,403);
  assert.equal(calls,callsAfterKill,"New call dispatched while kill switch OFF");
  pg("UPDATE private.iclub_ai_practice_freeform_pc3_control "+
    "SET enabled=true WHERE singleton=1; SELECT 'PC3_REENABLED'::text;");
  const cannotRetryKilled=await send("ask",killedQuestion,killedId);
  assert.equal(cannotRetryKilled.status,409);
  assert.equal(cannotRetryKilled.body.reason,"request_already_in_progress");
  assert.equal(calls,callsAfterKill,"Repeated killed request retriggered provider");
  pg("UPDATE private.iclub_ai_practice_freeform_pc3_control SET enabled=false WHERE singleton=1; SELECT 'OFF'::text;");
  const disabled=await send("ask");
  assert.equal(disabled.status,403);
  assert.equal(disabled.body.reason,"not_released");
  assert.equal(calls,4);
  if(realOwner&&realOther){
   // Real local GoTrue users, signed tokens; all source rows disposable.
   const owner=realOwner.id;
   pg("INSERT INTO public.user_subjects(user_id,subject_id) "+
      "VALUES('"+owner+"'::uuid,5); "+
      "INSERT INTO private.iclub_ai_v21_beta_members"+
      "(user_id,enabled,consent_version,consent_at) "+
      "VALUES('"+owner+"'::uuid,true,'global_ai_beta_v21',now()); "+
      "INSERT INTO public.practice_attempts "+
      "VALUES(701,'"+owner+"'::uuid,5,7,70,false,NULL); "+
      "INSERT INTO public.practice_sessions_v4 "+
      "VALUES(701,'"+owner+"'::uuid,5,701,2,'finalized',now(),11,"+
      "ARRAY[1,2,3,4,5,6,7,8,9,10]::bigint[]); "+
      "INSERT INTO public.practice_session_answers_v4 "+
      "SELECT 701,g,now(),g NOT IN(2,6,9) FROM generate_series(1,10) AS g; "+
      "UPDATE private.iclub_ai_practice_freeform_pc3_control SET enabled=true "+
      "WHERE singleton=1; SELECT 'REAL_AUTH_FIXTURE'::text;");
   const beforeRealCalls=calls;
   const foreign=await send("ask",Q,
      "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
      {token:realOther.token,attempt:701});
   assert.equal(foreign.status,403,JSON.stringify(foreign));
   assert.equal(foreign.body.reason,"context_or_source_not_ready");
   const forged=await send("ask",Q,
      "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
      {token:realOwner.token.slice(0,-6)+"xxxxxx",attempt:701});
   assert.equal(forged.status,401,JSON.stringify(forged));
   assert.equal(calls,beforeRealCalls);
   const id="cccccccc-cccc-4ccc-8ccc-cccccccccccc";
   const owned=await send("ask",Q,id,
      {token:realOwner.token,attempt:701});
   assert.equal(owned.status,200,JSON.stringify(owned));
   assert.equal(owned.body.mode,"generated");
   assert.equal(owned.body.request_id,id);
   assert.equal(calls,beforeRealCalls+1);
   const foreignRecovery=await send("resume",null,
      "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
      {token:realOther.token,attempt:701});
   assert.equal(foreignRecovery.status,409,JSON.stringify(foreignRecovery));
   const recovery=await send("resume",null,
      "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeef",
      {token:realOwner.token,attempt:701});
   assert.equal(recovery.status,200,JSON.stringify(recovery));
   assert.equal(recovery.body.request_id,id);
   assert.equal(calls,beforeRealCalls+1);
   await testBrowserGoTrue({edge,answer:owned.body.message,receiptId:id,
     ownerId:realOwner.id,providerCalls:()=>calls-beforeRealCalls});
   // Browser signOut revokes the original signed GoTrue session.
   // Prove that a revoked JWT is rejected; then repeat ACK after a fresh login.
   const revokedOldToken=await send("resume_ack",null,id,
      {token:realOwner.token,attempt:701});
   assert.equal(revokedOldToken.status,401,JSON.stringify(revokedOldToken));
   const freshLogin=await fetch(GOTRUE+"/token?grant_type=password",{
     method:"POST",headers:{"content-type":"application/json"},
     body:JSON.stringify({
       email:"iclub-practice-ci-owner@example.com",
       password:"Temporary-Only-GoTrue-CI-owner-2026!"
     })
   });
   assert.equal(freshLogin.status,200,"Fresh owner GoTrue sign-in after logout");
   const renewedJwt=(await freshLogin.json()).access_token;
   const acknowledged=await send("resume_ack",null,id,
      {token:renewedJwt,attempt:701});
   assert.equal(acknowledged.status,200,JSON.stringify(acknowledged));
   const audit=JSON.parse(pg("SELECT json_build_object("+
      "'money',(SELECT state FROM private.iclub_ai_v21_freeform_budget_ledger "+
       "WHERE request_id='"+id+"'),"+
      "'quota',(SELECT state FROM private.iclub_ai_v21_freeform_quota_holds "+
       "WHERE request_id='"+id+"'),"+
      "'receipt',(SELECT status FROM private.iclub_ai_practice_receipts_v1 "+
       "WHERE request_id='"+id+"'))::text;"));
   assert.deepEqual(audit,{money:"charged",quota:"completed",receipt:"acknowledged"});
   console.log("PASS genuine isolated Supabase GoTrue: 2 password signins and signed JWTs, forged JWT blocked, foreign Practice/replay denied, owned AI answer/ACK");
   pg("UPDATE private.iclub_ai_practice_freeform_pc3_control "+
      "SET enabled=false WHERE singleton=1; SELECT 'OFF'::text;");
  }
  assert.deepEqual(failures,[]);
  console.log("PASS PC3 real Deno Edge + PC1/PC3/PC4 Postgres + five canonical money/quota RPCs + synthetic provider only");
  console.log("PASS isolated verified principal separation, cross-account replay denial, bad JWT/origin/attempt; reload recovery, quota compensation, consent revocation and emergency OFF");
  console.log("FINAL "+JSON.stringify({...final,providerCalls:calls}));
 }finally{
  if(deno){deno.kill("SIGTERM");await new Promise(ok=>{
    if(deno.exitCode!==null)return ok();
    deno.once("exit",ok);setTimeout(ok,1100);
   });}
  if(tmp)try{fs.unlinkSync(tmp);}catch{}
  if(server)await new Promise(ok=>server.close(ok));
 }
}
main().catch(e=>{console.error(e);process.exitCode=1;});
