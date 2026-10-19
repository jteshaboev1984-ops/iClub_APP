// Voluntary isolated QA Auth only. The existing academic iClub screens stay
// synthetic; no real student accounts, grades or results are read or modified.
(() => {
 "use strict";
 if(window.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites!==true) return;
 const URL="https://mmmduffgpvwjdpruzikw.supabase.co";
 const PUB="sb_publishable_OUJFpELgfrrmIIw2lF8_Sw_xEFH1M46";
 const EDGE=URL+"/functions/v1/iclub-ai-qa-global";
 let token=null,userId=null,refresh=null,eligible=false,canSpend=false,connecting=false,errorText="";
 const SESSION_KEY="iclub_qa_preview_trial_session_v1";
 const languages={
  ru:{live:"Настоящий AI · закрытый тест",
    approved:"Тестовый доступ подтверждён, но генерация пока выключена.",
    pending:"Тестовый профиль создан. Доступ к настоящему AI ожидает подтверждения.",
    intro:"Для настоящего AI будет создан отдельный временный тестовый профиль. Ваши оценки и прогресс не используются.",
    connect:"Создать тестовый доступ",check:"Проверить доступ",
    error:"Не удалось создать тестовый профиль. Попробуйте позже."},
  uz:{live:"Haqiqiy AI · yopiq sinov",
    approved:"Sinovga ruxsat berilgan, ammo AI javoblari hozircha o‘chiq.",
    pending:"Sinov profili yaratildi. Haqiqiy AI uchun ruxsat kutilmoqda.",
    intro:"Haqiqiy AI uchun alohida vaqtinchalik profil yaratiladi. Baholaringiz va natijalaringiz ishlatilmaydi.",
    connect:"Sinovga ulanish",check:"Ruxsatni tekshirish",
    error:"Sinov profilini yaratib bo‘lmadi. Keyinroq urinib ko‘ring."},
  en:{live:"Real AI · closed test",
    approved:"Test access confirmed, but AI generation is not enabled yet.",
    pending:"Test profile created. Approval for real AI is pending.",
    intro:"A separate temporary test profile will be created. Your grades and progress are not used.",
    connect:"Create test access",check:"Check access",
    error:"Could not create a test profile. Please try later."}
 };
 const copy=()=>languages[window.i18n?.getLang?.()]||languages.ru;
 const validId=id=>typeof id==="string"&&
  /^[0-9a-f]{8}-[0-9a-f-]{27,}$/i.test(id);
 function save(data){
  try{sessionStorage.setItem(SESSION_KEY,JSON.stringify({
   token:data.access_token,refresh:data.refresh_token,
   id:data.user.id,expires:data.expires_at
  }));}catch{}
 }
 function restore(){
  try{
   const x=JSON.parse(sessionStorage.getItem(SESSION_KEY)||"null");
   if(x&&validId(x.id)&&typeof x.refresh==="string"&&x.refresh.length<4000){
    userId=x.id;refresh=x.refresh;
    if(Number(x.expires)>Math.floor(Date.now()/1000)+60 &&
       typeof x.token==="string"&&x.token.length<4000)token=x.token;
   }
  }catch{}
 }
 restore();
 const state=()=>({authenticated:!!token,eligible,ready:canSpend,userId});
 const head=()=>document.querySelector("#iclub-global-ai-panel .iclub-global-ai-head");
 const ui=()=>document.querySelector("#iclub-ai-qa-live-connect");
 function update(){
  const bar=ui();if(!bar)return;
  const status=bar.querySelector("[data-qa-pilot-state]");
  const btn=bar.querySelector("button");
  const t=copy();
  status.textContent=errorText||(
   canSpend?t.live:eligible?t.approved:(token||refresh)?t.pending:t.intro
  );
  btn.hidden=canSpend;
  btn.textContent=(token||refresh)?t.check:t.connect;
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
  connecting=true;errorText="";update();
  try{
   if(!token&&refresh){
    // Refresh the isolated PREVIEW identity, never use app's Auth session.
    const response=await requestJson("/auth/v1/token?grant_type=refresh_token",
      {refresh_token:refresh},null);
    if(response.status!==200||!validId(response.body?.user?.id)||
       response.body.user.id!==userId||!response.body.access_token)
      throw Error(copy().error);
    token=response.body.access_token;refresh=response.body.refresh_token;
    save(response.body);
   }
   if(!token){
    // Explicit click only: a new, separate anonymous QA identity.
    // No production public.users/profile/Exam Prep learner data is written.
    const response=await requestJson("/auth/v1/signup",
      {data:{iclub_global_ai_preview_pilot:"v1",no_academic_data:true}},null);
    const data=response.body;
    if(response.status!==200||!validId(data?.user?.id)||
       typeof data.access_token!=="string"||
       typeof data.refresh_token!=="string"||
       data.user.is_anonymous!==true)
     throw Error(copy().error);
    token=data.access_token;refresh=data.refresh_token;userId=data.user.id;
    save(data);
   }
   const response=await requestJson("/functions/v1/iclub-ai-qa-global",{intent:"status"});
   eligible=response.status===200&&response.body?.eligible===true;
   canSpend=eligible&&response.body?.fundedPilot===true&&
      response.body?.providerConfigured===true;
  }catch(error){
   canSpend=false;eligible=false;
   errorText=String(error?.message||copy().error);
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
  // Only a real voluntary button click can create the isolated test identity.
  const h=head();if(!h||ui())return;
  const bar=document.createElement("div");bar.id="iclub-ai-qa-live-connect";
  bar.setAttribute("role","status");
  bar.style.cssText="display:flex;flex-direction:column;align-items:stretch;gap:8px;padding:10px 14px;border-bottom:1px solid #e4ecf8;background:#f8faff;font:500 12px/1.5 system-ui;color:#456388";
  const span=document.createElement("span");span.setAttribute("data-qa-pilot-state","");
  const button=document.createElement("button");button.type="button";
  button.style.cssText="align-self:flex-end;max-width:100%;border:1px solid #d4e2f4;background:white;border-radius:10px;padding:8px 12px;font:600 12px system-ui;color:#285fad;white-space:normal;cursor:pointer";
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
