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
    "profile_meaning","video_help","recs_help","archive_help",
    "nav_home","nav_courses","nav_ratings","nav_profile","nav_about","nav_support"
  ]);
  const LOCALES=new Set(["ru","uz","en"]);
  const NAV_INPUTS={
    ru:{"где главная":"nav_home","как открыть главную":"nav_home",
      "где учёба":"nav_courses","как открыть учёбу":"nav_courses",
      "где рейтинг":"nav_ratings","как открыть рейтинг":"nav_ratings",
      "где профиль":"nav_profile","как открыть профиль":"nav_profile",
      "где о проекте":"nav_about","как открыть о проекте":"nav_about",
      "где поддержка":"nav_support","как открыть поддержку":"nav_support"},
    uz:{"bosh sahifa qayerda":"nav_home","bosh sahifani qanday ochaman":"nav_home",
      "o‘qish qayerda":"nav_courses","o‘qishni qanday ochaman":"nav_courses",
      "reyting qayerda":"nav_ratings","reytingni qanday ochaman":"nav_ratings",
      "profil qayerda":"nav_profile","profilni qanday ochaman":"nav_profile",
      "loyiha haqida qayerda":"nav_about","yordam qayerda":"nav_support"},
    en:{"where is home":"nav_home","how do i open home":"nav_home",
      "where is study":"nav_courses","how do i open study":"nav_courses",
      "where is ratings":"nav_ratings","how do i open ratings":"nav_ratings",
      "where is profile":"nav_profile","how do i open profile":"nav_profile",
      "where is about":"nav_about","how do i open about":"nav_about",
      "where is support":"nav_support","how do i open support":"nav_support"}
  };
  function verifiedNavigationKey(text,lang){
    if(typeof text!=="string"||text.length>120)return "";
    const key=text.normalize("NFKC").toLowerCase()
      .replace(/[’ʻ']/g,"‘").replace(/[?!.。؟]+$/g,"")
      .replace(/\s+/g," ").trim();
    return NAV_INPUTS[lang]?.[key]||"";
  }
  let sequence=0, authEpoch=0, lastUser="", permission=null;
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
      detail:"Добровольное участие в закрытой бете",
      title:"Тестирование iClub AI",
      info:"В закрытой бете iClub AI помогает освоить Practice, разбор ошибок, Tours и учебные материалы. Он пока не решает задания и не изменяет оценки или прогресс. Участие добровольное.",
      confirm:"Согласен участвовать",later:"Позже",
      close:"Закрыть",open:"Открыть iClub AI",done:"Готово",
      successTitle:"Доступ к iClub AI открыт",
      saved:"Согласие принято. Откройте iClub AI с помощью фирменного значка.",
      pending:"Согласие принято. Доступ откроется после запуска беты.",
      error:"Не удалось сохранить согласие. Попробуйте позже."
    },
    uz:{
      offer:"iClub AI sinovida qatnashish",
      detail:"Yopiq sinovda ixtiyoriy ishtirok",
      title:"iClub AI sinovi",
      info:"Yopiq sinovda iClub AI Practice, xatolar tahlili, Tours va o‘quv materiallaridan foydalanishni tushuntiradi. Hozircha u masalalarni yechmaydi, baho yoki o‘quv natijalarini o‘zgartirmaydi. Ishtirok ixtiyoriy.",
      confirm:"Ishtirok etishga roziman",later:"Keyinroq",
      close:"Yopish",open:"iClub AI’ni ochish",done:"Tayyor",
      successTitle:"iClub AI’dan foydalanish mumkin",
      saved:"Rozilik qabul qilindi. iClub AI belgisini bosib yordamchini oching.",
      pending:"Rozilik qabul qilindi. Kirish beta boshlanganda ochiladi.",
      error:"Rozilik saqlanmadi. Keyinroq qayta urinib ko‘ring."
    },
    en:{
      offer:"Join iClub AI testing",detail:"Optional closed beta",title:"iClub AI beta",
      info:"In this closed beta, iClub AI helps you use Practice, mistake review, Tours and study resources. It does not yet solve questions or change grades or progress. Participation is optional.",
      confirm:"I agree to participate",later:"Later",
      close:"Close",open:"Open iClub AI",done:"Done",
      successTitle:"Your iClub AI access is ready",
      saved:"Consent recorded. Tap the iClub AI icon to open the assistant.",
      pending:"Consent recorded. Access will open when beta starts.",
      error:"Consent could not be saved. Please try again."
    }
  };
  const words=()=>WORDS[String(window.i18n?.getLang?.()||"ru")]||WORDS.ru;
  const inviteId="iclub-ai-v21-optin-invite";
  const dialogId="iclub-ai-v21-optin-dialog";
  function removeInvite(){document.getElementById(inviteId)?.remove();}
  function renderInvite(){
    const profile=document.getElementById("view-profile");
    const main=document.getElementById("profile-main");
    const support=main?.querySelector?.('[data-action="open-support"]');
    const section=support?.closest?.(".profile-section");
    const mark=document.getElementById("iclub-global-ai-mark");
    const show=permission?.candidate&&!permission.consented&&
      profile?.classList.contains("is-active")&&
      main&&!main.hidden&&section&&
      !(mark&&!mark.hidden&&mark.getClientRects().length>0);
    if(!show){removeInvite();return;}
    let invite=document.getElementById(inviteId);
    if(!invite){
      invite=document.createElement("div");
      invite.id=inviteId;
      invite.className="profile-section";
      const group=document.createElement("div");
      group.className="profile-row-list";
      const button=document.createElement("button");
      button.className="profile-row";
      button.type="button";
      button.setAttribute("data-ai-beta-consent","true");
      const left=document.createElement("div");left.className="profile-row-left";
      const icon=document.createElement("div");icon.className="profile-row-ico";
      const image=document.createElement("img");
      image.src="iclub-ai-tutor-a.webp";
      image.alt="";image.setAttribute("aria-hidden","true");
      image.width=18;image.height=18;icon.appendChild(image);
      left.appendChild(icon);
      const middle=document.createElement("div");
      middle.className="profile-row-mid";
      const title=document.createElement("div");
      title.className="profile-row-title";
      title.setAttribute("data-ai-beta-invite-title","");
      const detail=document.createElement("div");
      detail.className="muted small";
      detail.setAttribute("data-ai-beta-invite-detail","");
      middle.append(title,detail);
      const arrow=document.createElement("div");
      arrow.className="profile-row-right";arrow.textContent="›";
      button.append(left,middle,arrow);
      button.addEventListener("click",showConsentDialog);
      group.appendChild(button);
      invite.appendChild(group);
      section.after(invite);
    }
    invite.querySelector("[data-ai-beta-invite-title]").textContent=words().offer;
    invite.querySelector("[data-ai-beta-invite-detail]").textContent=words().detail;
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
      if(result.ok){
        removeInvite();
        title.textContent=result.ready?words().successTitle:words().title;
        info.textContent=result.ready?words().saved:words().pending;
        // Consent has already been recorded. Never leave a "Later" action
        // here: it misleadingly suggests that consent could still be deferred.
        const action=document.createElement("button");
        action.type="button";
        action.textContent=result.ready?words().open:words().done;
        Object.assign(action.style,{
          padding:"11px 16px",borderRadius:"10px",border:"0",
          background:"#163e68",color:"#fff",cursor:"pointer",
          font:"600 14px system-ui"
        });
        action.addEventListener("click",()=>{
          close();
          if(result.ready)window.iClubGlobalAiShell?.open?.();
        },{once:true});
        row.replaceChildren(action);
        action.focus();
      }else{
        info.textContent=words().error;
        agree.disabled=false;
        later.textContent=words().close;
        later.disabled=false;
      }
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
    const epoch=authEpoch,user=lastUser;
    const result=await invoke({intent:"consent",consent_version:"global_ai_beta_v21"});
    if(epoch!==authEpoch||user!==await identity())return closed("account_changed");
    await status();
    if(result?.ok===true&&result.recorded===true){
      await window.iClubGlobalAiShell?.refresh?.();
      return {ok:true,recorded:true,ready:permission?.eligible===true};
    }
    return closed("consent_unavailable");
  }
  async function askPrepared({promptKey,locale,userText}={}){
    const localeCode=String(locale||"");
    if(!LOCALES.has(localeCode)||typeof promptKey!=="string")return closed();
    const key=promptKey===""?verifiedNavigationKey(userText,localeCode):promptKey;
    if(!ALLOWED.has(key))return closed();
    const current=await status();
    if(!current.eligible||protectedNow())return closed("beta_not_enabled");
    const user=lastUser,epoch=authEpoch;
    const id=window.crypto?.randomUUID?.();
    if(typeof id!=="string")return closed("request_unavailable");
    const answer=await invoke({intent:"ask",request_id:id,
      prompt_key:key,locale:localeCode});
    if(epoch!==authEpoch||user!==await identity()||protectedNow())
      return closed("context_changed");
    if(answer?.ok!==true||answer.academic_state_changed!==false||
       answer.provider_called!==false||typeof answer.message!=="string")
      return closed(String(answer?.reason||"in_development"));
    return{ok:true,message:answer.message,mode:"prepared",
      academic_state_changed:false,provider_called:false};
  }

  // Unified learner-scoped source bridge. Selectors are not grants:
  // the server verifies real owner, finalization, publication and entitlement.
  const academicTypes=new Set(["practice_error","lesson_topic","tour_archive"]);
  const positiveInt=x=>Number.isSafeInteger(x)&&x>0;
  async function availableAcademic({surface,recordId,locale}={}){
    if(!academicTypes.has(surface)||!positiveInt(recordId)||
       !LOCALES.has(locale))return [];
    const current=await status();
    if(!current.eligible||protectedNow())return [];
    const user=lastUser,epoch=authEpoch;
    const response=await invoke({intent:"academic_available",
      surface,record_id:recordId,locale});
    if(user!==await identity()||epoch!==authEpoch||protectedNow()||
       response?.ok!==true||!Array.isArray(response.available))return [];
    return response.available.filter(positiveInt).slice(0,12);
  }
  async function askAcademic({surface,recordId,questionId=null,locale}={}){
    if(!academicTypes.has(surface)||!positiveInt(recordId)||
       !LOCALES.has(locale)||
       (surface==="practice_error"
        ?!positiveInt(questionId):questionId!==null))return closed();
    const current=await status();
    if(!current.eligible||protectedNow())return closed("beta_not_enabled");
    const user=lastUser,epoch=authEpoch;
    const requestId=window.crypto?.randomUUID?.();
    if(!requestId)return closed("request_unavailable");
    const result=await invoke({intent:"academic",request_id:requestId,
      surface,record_id:recordId,question_id:questionId,locale});
    if(user!==await identity()||epoch!==authEpoch||protectedNow())
      return closed("context_changed");
    if(result?.ok!==true||result.provider_called!==false||
       result.academic_state_changed!==false||typeof result.message!=="string")
      return closed(String(result?.reason||"in_development"));
    return{ok:true,message:result.message,mode:"prepared",
      provider_called:false,academic_state_changed:false};
  }
  const academicLabels={
    ru:{practice_error:"Объяснить ошибку",lesson_topic:"Объяснить тему",
      tour_archive:"Объяснить результаты тура"},
    uz:{practice_error:"Xatoni tushuntirish",lesson_topic:"Mavzuni tushuntirish",
      tour_archive:"Tur natijasini tushuntirish"},
    en:{practice_error:"Explain the mistake",lesson_topic:"Explain the topic",
      tour_archive:"Explain the Tour result"}
  };
  const localeNow=()=>String(window.i18n?.getLang?.()||"ru");
  const active=(code)=>document.getElementById("courses-"+code)
    ?.classList.contains("is-active")===true;
  const scopeFor={
    practice_error:{screen:"practice-review",container:"practice-review-list",
      root:"courses-practice-review",record:"practiceAiAttemptId"},
    lesson_topic:{screen:"video",container:"courses-video",
      root:"courses-video",record:"iclubAiLessonId"},
    tour_archive:{screen:"tour-review",container:"tour-review-list",
      root:"courses-tour-review",record:"iclubAiTourAttemptId"}
  };
  const lastScan=new Map();
  function academicButton(container,surface,recordId,questionId=null){
    const identifier=surface+":"+recordId+":"+(questionId||0);
    if(container.querySelector?.('[data-iclub-ai-academic-button="'+identifier+'"]'))
      return;
    const button=document.createElement("button");
    button.type="button";button.className="btn";
    button.dataset.iclubAiAcademicButton=identifier;
    button.textContent=(academicLabels[localeNow()]||academicLabels.ru)[surface];
    button.addEventListener("click",event=>{
      event.stopPropagation();
      if(!active(scopeFor[surface].screen)||protectedNow())return;
      const sourceRoot=document.getElementById(scopeFor[surface].root);
      if(Number(sourceRoot?.dataset?.[scopeFor[surface].record]||0)!==recordId)
        return;
      void window.iClubGlobalAiShell?.explainAcademic?.({
        surface,recordId,questionId,locale:localeNow(),
        displayText:(academicLabels[localeNow()]||academicLabels.ru)[surface]
      });
    });
    container.appendChild(button);
  }
  async function scanAcademic(surface){
    const conf=scopeFor[surface];
    if(!conf||!active(conf.screen)||protectedNow())return;
    const el=document.getElementById(conf.root);
    const container=document.getElementById(conf.container);
    const id=Number(el?.dataset?.[conf.record]||0);
    if(!positiveInt(id)||!container)return;
    const key=surface+":"+id+":"+localeNow();
    if(lastScan.get(surface)===key)return;
    lastScan.set(surface,key);
    const available=await availableAcademic({surface,recordId:id,locale:localeNow()});
    if(!active(conf.screen)||!el?.isConnected||Number(el.dataset?.[conf.record]||0)!==id)
      return;
    if(surface==="practice_error"){
      const rows=container.querySelectorAll?.("[data-practice-ai-question-id]")||[];
      for(const row of rows){
        const questionId=Number(row.dataset.practiceAiQuestionId||0);
        // The server returns ONLY wrong, finalized, source-published IDs.
        if(positiveInt(questionId)&&available.includes(questionId))
          academicButton(row,surface,id,questionId);
      }
    }else if(available.includes(id)){
      academicButton(container,surface,id);
    }
  }
  function setupAcademicAutoAttach(){
    const roots=["courses-practice-review","courses-video","courses-tour-review"];
    for(const id of roots){
      const root=document.getElementById(id);
      if(!root||typeof MutationObserver!=="function")continue;
      new MutationObserver(()=>{
        const surface=Object.keys(scopeFor).find(s=>scopeFor[s].root===id);
        if(!surface||!active(scopeFor[surface].screen)){
          lastScan.delete(surface);return;
        }
        // One in-flight fetch per source context, irrespective of DOM mutations.
        void scanAcademic(surface);
      }).observe(root,{attributes:true,attributeFilter:["class","data-practice-ai-attempt-id",
        "data-iclub-ai-lesson-id","data-iclub-ai-tour-attempt-id"],
        childList:true,subtree:true});
    }
    document.addEventListener("iclub:practice-ai-context-changed",()=>{
      lastScan.delete("practice_error");void scanAcademic("practice_error");
    });
  }

  function resetOnIdentityChange(){
    sequence++;authEpoch++;permission=null;lastUser="";
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
  if(document.readyState==="loading")
    document.addEventListener("DOMContentLoaded",setupAcademicAutoAttach,{once:true});
  else setupAcademicAutoAttach();
  window.iClubAiV21BetaClient=Object.freeze({
    status,consentFromExplicitUserAction,askPrepared,
    availableAcademic,askAcademic,resetOnIdentityChange
  });
})();
