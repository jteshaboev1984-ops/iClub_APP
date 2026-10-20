// iClub AI v2.1 connected beta transport — original iClub APP, existing account.
// Add to app only after a protected release review; no new signups, no storage.
// Do not embed service_role or provider credentials in the browser.
(() => {
  "use strict";
  const EDGE="iclub-ai-v21-prepared";
  const ALLOWED=new Set([
    "support_help","catalog_help","ratings_help","home_next",
    "practice_rules","tour_rules","books_help","about_help",
    "notifications_help","community_help","certificates_help",
    "profile_meaning","video_help","recs_help","archive_help"
  ]);
  const LOCALES=new Set(["ru","uz","en"]);
  let sequence=0, lastUser="", permission=null;
  const closed=(reason="in_development")=>({ok:false,reason,
    academic_state_changed:false});
  const identity=async()=>{
    try{
      const {data,error}=await window.sb?.auth?.getUser?.();
      if(error)return "";
      return String(data?.user?.id||"");
    }catch{return "";}
  };
  const protectedNow=()=>{
    const visible=id=>document.getElementById(id)?.classList.contains("is-active")===true;
    const exam=document.getElementById("exam-prep-host-root");
    return visible("courses-practice-quiz")||visible("courses-tour-quiz")||
      (!!exam&&!exam.hidden&&exam.getAttribute("aria-hidden")!=="true"&&
       !!exam.querySelector("[data-ep-ai-active-assessment]"));
  };
  const invoke=async body=>{
    const client=window.sb;
    if(typeof client?.functions?.invoke!=="function")return null;
    try{
      const {data,error}=await client.functions.invoke(EDGE,{body});
      return !error&&data&&typeof data==="object"&&!Array.isArray(data)?data:null;
    }catch{return null;}
  };
  // Single explicit opt-in invitation for staged candidates on Profile only.
  // The working Global AI mark is never duplicated during an active beta.
  const WORDS={
    ru:{
      offer:"Участвовать в тестировании iClub AI",
      title:"Тестирование iClub AI",
      info:"На первом этапе помощник использует только проверенную справку iClub. Он не меняет оценки и прогресс. Участие добровольное; доступ откроется после отдельного запуска беты.",
      confirm:"Согласен участвовать",later:"Не сейчас",
      saved:"Согласие принято. Доступ откроется после запуска беты.",
      error:"Не удалось сохранить согласие. Попробуйте позже."
    },
    uz:{
      offer:"iClub AI sinovida qatnashish",
      title:"iClub AI sinovi",
      info:"Birinchi bosqichda yordamchi faqat iClub’ning tekshirilgan ma’lumotlaridan foydalanadi. U baholar yoki o‘quv natijalarini o‘zgartirmaydi. Ishtirok ixtiyoriy; kirish beta boshlangandan so‘ng ochiladi.",
      confirm:"Ishtirok etishga roziman",later:"Hozir emas",
      saved:"Rozilik qabul qilindi. Kirish beta boshlanganda ochiladi.",
      error:"Rozilik saqlanmadi. Keyinroq qayta urinib ko‘ring."
    },
    en:{
      offer:"Join iClub AI testing",title:"iClub AI beta",
      info:"At first, the assistant uses only verified iClub help. It does not change grades or learning progress. Participation is optional, and access opens only after the beta is launched.",
      confirm:"I agree to participate",later:"Not now",
      saved:"Consent recorded. Access will open when beta starts.",
      error:"Consent could not be saved. Please try again."
    }
  };
  const words=()=>WORDS[String(window.i18n?.getLang?.()||"ru")]||WORDS.ru;
  const inviteId="iclub-ai-v21-optin-invite";
  const dialogId="iclub-ai-v21-optin-dialog";
  function removeInvite(){document.getElementById(inviteId)?.remove();}
  function renderInvite(){
    const profile=document.getElementById("view-profile");
    const mark=document.getElementById("iclub-global-ai-mark");
    if(!permission?.candidate||permission.consented||
       !profile?.classList.contains("is-active")||
       (mark&&!mark.hidden&&mark.getClientRects().length>0)){
      removeInvite();return;
    }
    let invite=document.getElementById(inviteId);
    if(invite){invite.textContent=words().offer;return;}
    invite=document.createElement("button");
    invite.id=inviteId;invite.type="button";
    invite.textContent=words().offer;
    Object.assign(invite.style,{
      position:"fixed",right:"16px",
      bottom:"calc(86px + env(safe-area-inset-bottom))",
      zIndex:"1050",padding:"12px 16px",
      maxWidth:"calc(100vw - 32px)",border:"0",borderRadius:"14px",
      color:"#fff",background:"#163e68",
      font:"600 14px/1.4 system-ui, sans-serif",
      boxShadow:"0 8px 22px rgba(0,0,0,.2)",cursor:"pointer"
    });
    invite.addEventListener("click",showConsentDialog);
    document.body.appendChild(invite);
  }
  function showConsentDialog(){
    if(document.getElementById(dialogId)||!permission?.candidate||
       permission.consented||protectedNow())return;
    const overlay=document.createElement("div");
    overlay.id=dialogId;
    Object.assign(overlay.style,{
      position:"fixed",inset:"0",display:"flex",alignItems:"center",
      justifyContent:"center",padding:"18px",
      background:"rgba(12,25,42,.64)",zIndex:"11000"
    });
    const card=document.createElement("section");
    card.setAttribute("role","dialog");card.setAttribute("aria-modal","true");
    card.setAttribute("aria-label",words().title);
    Object.assign(card.style,{
      width:"min(100%,440px)",boxSizing:"border-box",background:"#fff",
      color:"#192b41",borderRadius:"18px",padding:"24px",
      boxShadow:"0 16px 45px rgba(0,0,0,.25)"
    });
    const title=document.createElement("h2");
    title.textContent=words().title;
    Object.assign(title.style,{font:"700 20px/1.3 system-ui",margin:"0 0 12px"});
    const info=document.createElement("p");
    info.textContent=words().info;
    Object.assign(info.style,{font:"400 14px/1.65 system-ui",margin:"0 0 20px"});
    const row=document.createElement("div");
    Object.assign(row.style,{display:"flex",gap:"10px",flexWrap:"wrap",justifyContent:"flex-end"});
    const later=document.createElement("button"),agree=document.createElement("button");
    for(const b of [later,agree]){
      b.type="button";
      Object.assign(b.style,{padding:"11px 14px",borderRadius:"10px",
        font:"600 14px system-ui",cursor:"pointer"});
    }
    later.textContent=words().later;
    agree.textContent=words().confirm;
    Object.assign(later.style,{border:"1px solid #cad1d8",background:"#fff",color:"#23344c"});
    Object.assign(agree.style,{border:"0",background:"#163e68",color:"#fff"});
    const close=()=>overlay.remove();
    later.addEventListener("click",close);
    agree.addEventListener("click",async()=>{
      agree.disabled=true;later.disabled=true;
      const result=await consentFromExplicitUserAction(true);
      info.textContent=result.ok?words().saved:words().error;
      agree.remove();later.textContent=words().later;later.disabled=false;
      if(result.ok)removeInvite();
    });
    row.append(later,agree);card.append(title,info,row);overlay.append(card);
    document.body.appendChild(overlay);later.focus();
  }
  function listenForInvite(){
    const profile=document.getElementById("view-profile");
    if(profile&&typeof MutationObserver==="function"){
      new MutationObserver(renderInvite).observe(profile,{
        attributes:true,attributeFilter:["class"]
      });
    }
    document.addEventListener("iclub:language-change",renderInvite);
  }

  async function status(){
    const ticket=++sequence;
    const id=await identity();
    if(!id||protectedNow()){
      lastUser=id;permission=null;
      return{ok:false,eligible:false,candidate:false,consented:false};
    }
    const result=await invoke({intent:"status"});
    if(ticket!==sequence||!id||await identity()!==id||protectedNow())return{
      ok:false,eligible:false,candidate:false,consented:false};
    lastUser=id;
    permission=result?.ok===true?{
      eligible:result.eligible===true,
      candidate:result.candidate===true,
      consented:result.consented===true
    }:null;
    renderInvite();
    return{ok:!!permission,...(permission||{
      eligible:false,candidate:false,consented:false})};
  }
  async function consentFromExplicitUserAction(agreed){
    // A click-based UX must display an explanation and obtain explicit consent.
    if(agreed!==true)return closed("consent_required");
    const current=await status();
    if(!current.candidate||current.consented||protectedNow())
      return closed("not_eligible_or_already_recorded");
    const epoch=sequence,user=lastUser;
    const result=await invoke({intent:"consent",consent_version:"global_ai_beta_v21"});
    if(epoch!==sequence||user!==await identity())return closed("account_changed");
    await status();
    return result?.ok===true&&result.recorded===true?
      {ok:true,recorded:true}:closed("consent_unavailable");
  }
  async function askPrepared({promptKey,locale}={}){
    const localeCode=String(locale||"");
    if(!LOCALES.has(localeCode)||typeof promptKey!=="string"||
       !ALLOWED.has(promptKey))return closed();
    const current=await status();
    if(!current.eligible||protectedNow())return closed("beta_not_enabled");
    const user=lastUser,epoch=sequence;
    const id=window.crypto?.randomUUID?.();
    if(typeof id!=="string")return closed("request_unavailable");
    const answer=await invoke({intent:"ask",request_id:id,
      prompt_key:promptKey,locale:localeCode});
    if(epoch!==sequence||user!==await identity()||protectedNow())
      return closed("context_changed");
    if(answer?.ok!==true||answer.academic_state_changed!==false||
       answer.provider_called!==false||typeof answer.message!=="string")
      return closed(String(answer?.reason||"in_development"));
    return{ok:true,message:answer.message,mode:"prepared",
      academic_state_changed:false,provider_called:false};
  }
  function resetOnIdentityChange(){
    sequence++;permission=null;lastUser="";
    removeInvite();
    document.getElementById(dialogId)?.remove();
  }
  try{
    window.sb?.auth?.onAuthStateChange?.((event)=>{
      if(["SIGNED_OUT","USER_DELETED","SIGNED_IN"].includes(event))
        resetOnIdentityChange();
    });
  }catch{}
  if(document.readyState==="loading")
    document.addEventListener("DOMContentLoaded",listenForInvite,{once:true});
  else listenForInvite();
  window.iClubAiV21BetaClient=Object.freeze({
    status,consentFromExplicitUserAction,askPrepared,resetOnIdentityChange
  });
})();
