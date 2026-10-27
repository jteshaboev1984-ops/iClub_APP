/* iClub Exam Prep — governed written practice, no automatic marks.
 * Reuses the existing Mathematics ep-live UI and approved Core v1.3 controller.
 * Mount only after server-approved written_available_v1 === true.
 */
(function(){
 "use strict";
 const copy={
   ru:{title:"Письменная практика",criteria:"Критерии",next:"Далее",
     back:"Назад",loading:"Загружаем задание…",offline:"Не удалось подтвердить действие. Повторите попытку.",
     complete:"Письменные задания по текущему плану пройдены.",
     instruction:"Выполните задание самостоятельно. Загрузка работы и самооценка не требуются.",
     criteriaTitle:"Требования к ответу",openError:"Задание сейчас недоступно."},
   uz:{title:"Yozma mashqlar",criteria:"Baholash mezonlari",next:"Keyingi",
     back:"Orqaga",loading:"Topshiriq yuklanmoqda…",offline:"Amal tasdiqlanmadi. Qaytadan urinib ko‘ring.",
     complete:"Joriy rejadagi yozma topshiriqlar yakunlandi.",
     instruction:"Topshiriqni mustaqil bajaring. Ishni yuklash yoki o‘zingizga baho qo‘yish shart emas.",
     criteriaTitle:"Javobga qo‘yiladigan talablar",openError:"Topshiriq hozir mavjud emas."},
   en:{title:"Written practice",criteria:"Criteria",next:"Next",
     back:"Back",loading:"Loading task…",offline:"Action not confirmed. Please retry.",
     complete:"Written tasks in this study plan have been completed.",
     instruction:"Complete the task independently. No essay upload or self-grading is required.",
     criteriaTitle:"Answer requirements",openError:"Task is currently unavailable."}
 };
 const el=(tag,cls,str)=>{const x=document.createElement(tag);if(cls)x.className=cls;if(str!=null)x.textContent=String(str);return x;};
 function mount({root,planId,language="ru",onBack,api,createActionKey}={}){
   if(!root||!planId||!api||!window.iClubWrittenCoreControllerV1||
      !["available","next","open","criteria","advance","status"].every(k=>typeof api[k]==="function"))
      return null;
   const t=copy[language]||copy.ru;
   let closed=false,working=false,sequence=0,ctl=null;
   const actionKey=typeof createActionKey==="function"?createActionKey:
      ()=>window.crypto?.randomUUID?.()||"";
   function btn(label,handler,secondary=false){
      const x=el("button",secondary?"ep-live-btn secondary":"ep-live-btn",label);
      x.type="button";x.addEventListener("click",handler);return x;
   }
   function page(){
      const base=el("section","ep-host-shell ep-live");
      const top=el("div","ep-live-head");
      const title=el("h2","ep-host-title",t.title);
      top.append(title,btn("← "+t.back,()=>{dispose();onBack?.();},true));
      base.append(top);root.replaceChildren(base);return base;
   }
   function message(str){
      const body=page();body.append(el("p","ep-live-card",str));return body;
   }
   async function loadNext(){
      if(closed||working)return;
      working=true;const token=++sequence;
      message(t.loading);
      try{
         const result=await api.next({p_plan_id:planId});
         if(closed||token!==sequence)return;
         if(!result||result.ok===false)throw Error("written_not_available");
         if(result.status==="completed"){
            message(t.complete);return;
         }
         if(result.status!=="ready"||!result.plan_item_id)
            throw Error("written_item_not_ready");
         let openedTask=null;
         ctl=window.iClubWrittenCoreControllerV1.create({
            api:{
              open:async({plan_item_id})=>{
                openedTask=await api.open({p_item_id:plan_item_id,p_language:language});
                return openedTask;
              },
              criteria:({plan_item_id,task_key,task_version,task_token})=>
                api.criteria({p_item_id:plan_item_id,p_task_key:task_key,
                  p_task_version:task_version,p_task_token:task_token,p_language:language}),
              advance:({plan_item_id,task_key,task_version,task_token,idempotency_key})=>
                api.advance({p_item_id:plan_item_id,p_task_key:task_key,
                  p_task_version:task_version,p_task_token:task_token,p_idempotency_key:idempotency_key}),
              status:({plan_item_id,task_key,task_version,task_token})=>
                api.status({p_item_id:plan_item_id,p_task_key:task_key,
                  p_task_version:task_version,p_task_token:task_token})
            },createActionKey:actionKey
         });
         await ctl.open(result.plan_item_id);
         if(closed||token!==sequence)return;
         const answer=openedTask;
         if(closed||token!==sequence)return;
         // Task wording is returned by the approved, learner-owned Core service only.
         if(!answer||answer.task_kind!=="written_external"||typeof answer.question!=="string")
            throw Error("written_question_not_approved");
         renderTask(answer,token);
      }catch(_){
         if(!closed&&token===sequence){
            const box=message(t.openError);
            box.append(btn(t.next,()=>{working=false;loadNext();}));
         }
      }finally{if(token===sequence)working=false;}
   }
   function renderTask(item,token){
      const body=page();
      const card=el("section","ep-live-card");
      card.append(el("div","ep-live-meta",item.paper_code||""),
        el("p","ep-live-qtext",item.question),
        el("p","ep-live-meta",t.instruction));
      const criteriaBox=el("div","ep-live-card");criteriaBox.hidden=true;
      const err=el("p","ep-live-meta");err.setAttribute("role","alert");
      const actions=el("div","ep-live-actions");
      const criteriaButton=btn(t.criteria,async()=>{
        if(closed||working||token!==sequence)return;
        working=true;criteriaButton.disabled=true;
        try{
          const details=await ctl.criteria();
          if(closed||token!==sequence)return;
          criteriaBox.replaceChildren(el("h3","",details.title||t.criteriaTitle));
          const list=el("ul","ep-live-list");
          for(const requirement of details.requirements)list.append(el("li","",requirement));
          criteriaBox.append(list);criteriaBox.hidden=false;err.textContent="";
        }catch(_){if(!closed&&token===sequence)err.textContent=t.offline;}
        finally{working=false;criteriaButton.disabled=false;}
      },true);
      const nextButton=btn(t.next,async()=>{
        if(closed||working||token!==sequence)return;
        working=true;nextButton.disabled=true;criteriaButton.disabled=true;
        try{
          await ctl.next();
          if(closed||token!==sequence)return;
          working=false;await loadNext();
        }catch(_){
          if(!closed&&token===sequence){err.textContent=t.offline;working=false;
            nextButton.disabled=false;criteriaButton.disabled=false;}
        }
      });
      actions.append(criteriaButton,nextButton);
      card.append(criteriaBox,err,actions);body.append(card);
   }
   function dispose(){closed=true;sequence++;ctl=null;root=null;}
   loadNext();
   return Object.freeze({dispose});
 }
 window.iClubWrittenCoreViewV1=Object.freeze({mount});
})();