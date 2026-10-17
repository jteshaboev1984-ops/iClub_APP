// Optional, deliberate, user-visible REAL QA canary inside the EXISTING
// iClub AI panel. Academic app data stays synthetic; only the isolated
// trial-auth session and QA money ledger reach Supabase.
(() => {
 "use strict";
 if(window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites!==true) return;
 const URL="https://mmmduffgpvwjdpruzikw.supabase.co";
 const PUB="sb_publishable_OUJFpELgfrrmIIw2lF8_Sw_xEFH1M46";
 const EDGE=URL+"/functions/v1/iclub-ai-qa-global";
 let token=null,userId=null,eligible=false,canSpend=false,connecting=false;
 const state=()=>({authenticated:!!token,eligible,ready:canSpend,userId});
 const head=()=>document.querySelector("#iclub-global-ai-panel .iclub-global-ai-head");
 const ui=()=>document.querySelector("#iclub-ai-qa-live-connect");
 function update(){
  const bar=ui();if(!bar)return;
  const status=bar.querySelector("[data-qa-pilot-state]");
  const btn=bar.querySelector("button");
  if(canSpend){
   status.textContent="Настоящий AI · закрытый тест · лимит $1";
   btn.hidden=true;
  }else if(eligible){
   status.textContent="Тестовый аккаунт допущен, но денежный пилот ещё выключен.";
   btn.textContent="Проверить доступ";
  }else if(token){
   status.textContent="Тестовый аккаунт готов. Ожидает допуска: "+userId;
   btn.textContent="Проверить доступ";
  }else{
   status.textContent="Демо-ответы. Настоящий AI доступен только оператору пилота.";
   btn.textContent="Подключить тестовый AI";
  }
  btn.disabled=connecting;
 }
 async function requestJson(path,body,access=token){
  const controller=new AbortController();
  const cancel=setTimeout(()=>controller.abort(),15000);
  try{
   const res=await fetch(URL+path,{
    method:"POST",headers:{
      "Content-Type":"application/json","apikey":PUB,
      ...(access?{"Authorization":"Bearer "+access}:{})
    },
    body:JSON.stringify(body),
    signal:controller.signal,credentials:"omit",cache:"no-store",redirect:"error"
   });
   const json=await res.json().catch(()=>({ok:false,reason:"invalid_response"}));
   return {status:res.status,body:json};
  } finally{clearTimeout(cancel);}
 }
 async function connect(){
  if(connecting)return;
  connecting=true;update();
  try{
   if(!token){
    // Explicit click only. Reuse an EXISTING verified iClub Auth session.
    // Never sign up an anonymous user, paste a token, or import student data.
    const client=window.sb;
    const sessionResult=await client?.auth?.getSession?.();
    const session=sessionResult?.data?.session||null;
    const id=String(session?.user?.id||"");
    const jwt=String(session?.access_token||"");
    const isSynthetic=id===String(window.__ICLUB_AI_QA_PREVIEW__?.syntheticIdentity||"") ||
      session?.user?.app_metadata?.provider==="qa-fixture";
    if(isSynthetic||!(/^[0-9a-f]{8}-[0-9a-f-]{27,}$/i.test(id))||
       !/^eyJ[A-Za-z0-9_-]{10,}\./.test(jwt)||jwt.length>4000)
     throw Error("Нужна действующая сессия существующего beta-аккаунта iClub. Тестовый Preview не создаёт аккаунты.");
    token=jwt;userId=id;
   }
   const response=await requestJson("/functions/v1/iclub-ai-qa-global",{intent:"status"});
   eligible=response.status===200&&response.body?.eligible===true;
   canSpend=eligible&&response.body?.fundedPilot===true&&
      response.body?.providerConfigured===true;
  }catch(error){
   canSpend=false;eligible=false;
   const bar=ui();
   if(bar)bar.querySelector("[data-qa-pilot-state]").textContent=
     String(error?.message||"Тестовая авторизация временно недоступна.");
  }finally{connecting=false;update();}
 }
 async function invoke(body){
  if(!canSpend||!token)return {data:{ok:false,reason:"qa_access_not_approved"},error:null};
  const safe={
   intent:"ask",
   request_id:body?.request_id,
   locale:body?.locale,
   screen_code:body?.screen_code,
   scope_code:body?.scope_code,
   prompt_key:body?.prompt_key,
   user_text:body?.user_text||""
  };
  try{
   const result=await requestJson("/functions/v1/iclub-ai-qa-global",safe);
   if(result.status===401||result.status===403){
    canSpend=false;eligible=false;update();
   }
   return {data:result.body,error:null};
  }catch{
   return {data:{ok:false,reason:"qa_gateway_unavailable"},error:null};
  }
 }
 function attach(){
  // Shared synthetic Preview: no registration, live-model controls or Auth writes.
  // A signed-in operator test, if later authorized, must use a distinct vetted shell.
  if(window.__ICLUB_AI_QA_PREVIEW__?.syntheticIdentity)return;
  const h=head();if(!h||ui())return;
  const bar=document.createElement("div");bar.id="iclub-ai-qa-live-connect";
  bar.setAttribute("role","status");
  bar.style.cssText="display:flex;align-items:center;justify-content:space-between;gap:8px;padding:9px 14px;border-bottom:1px solid #e4ecf8;background:#f8faff;font:500 11px/1.4 system-ui;color:#456388";
  const span=document.createElement("span");span.setAttribute("data-qa-pilot-state","");
  const button=document.createElement("button");button.type="button";
  button.style.cssText="border:1px solid #d4e2f4;background:white;border-radius:9px;padding:6px 8px;font:600 11px system-ui;color:#285fad;white-space:nowrap;cursor:pointer";
  button.addEventListener("click",()=>{void connect();});
  bar.append(span,button);h.insertAdjacentElement("afterend",bar);update();
 }
 let scheduled=false;
 const observer=new MutationObserver(()=>{
  if(scheduled)return;scheduled=true;
  queueMicrotask(()=>{scheduled=false;attach();});
 });
 observer.observe(document.body,{childList:true,subtree:true});
 attach();
 window.__ICLUB_AI_QA_LIVE_BRIDGE__=Object.freeze({
  invoke,ready:()=>canSpend,state,connect
 });
})();
