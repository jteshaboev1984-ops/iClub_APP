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
  }
  try{
    window.sb?.auth?.onAuthStateChange?.((event)=>{
      if(["SIGNED_OUT","USER_DELETED","SIGNED_IN"].includes(event))
        resetOnIdentityChange();
    });
  }catch{}
  window.iClubAiV21BetaClient=Object.freeze({
    status,consentFromExplicitUserAction,askPrepared,resetOnIdentityChange
  });
})();
