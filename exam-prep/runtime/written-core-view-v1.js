/* iClub Exam Prep — governed written practice, no automatic marks.
 * Reuses the existing Mathematics ep-live UI and approved Core v1.3 controller.
 * Mount only after server-approved written_available_v1 === true.
 */
(function(){
 "use strict";
 const copy={
   ru:{title:"Письменная практика",criteria:"Схема оценивания",hideCriteria:"Скрыть схему",next:"Далее",source:"Источник",data:"Таблица данных",
     back:"Назад",loading:"Загружаем задание…",offline:"Не удалось подтвердить действие. Повторите попытку.",
     complete:"Письменные задания по текущему плану пройдены.",
     instruction:"Выполните задание самостоятельно. Загрузка работы и самооценка не требуются.",
     criteriaTitle:"Схема оценивания",marks:"баллов",ao12:"AO1 + AO2 · Знания и анализ",ao3:"AO3 · Оценка и аргументация",markContent:"Что учитывается при оценивании",levelsInfo:"Эссе оценивается по уровням: полнота знаний, глубина анализа и обоснованность вывода. Баллы не начисляются автоматически за каждый пункт.",pointInfo:"Баллы за отдельную часть задания учитывают верные понятия, расчёты и объяснения.",notOfficial:"Учебная схема iClub по принципам Cambridge 9708. Это не официальный mark scheme для данного задания.",openError:"Задание сейчас недоступно."},
   uz:{title:"Yozma mashqlar",criteria:"Baholash mezonlari",hideCriteria:"Mezonlarni yashirish",next:"Keyingi",source:"Manba",data:"Ma’lumotlar jadvali",
     back:"Orqaga",loading:"Topshiriq yuklanmoqda…",offline:"Amal tasdiqlanmadi. Qaytadan urinib ko‘ring.",
     complete:"Joriy rejadagi yozma topshiriqlar yakunlandi.",
     instruction:"Topshiriqni mustaqil bajaring. Ishni yuklash yoki o‘zingizga baho qo‘yish shart emas.",
     criteriaTitle:"Baholash mezonlari",marks:"ball",ao12:"AO1 + AO2 · Bilim va tahlil",ao3:"AO3 · Baholash va dalillar",markContent:"Baholashda nimalar hisobga olinadi",levelsInfo:"Esse bilim, tahlil chuqurligi va asoslangan xulosa bo‘yicha darajalarda baholanadi. Har bir band uchun avtomatik ball berilmaydi.",pointInfo:"Savolning ushbu qismida tushunchalar, hisob-kitoblar va izohlar uchun ball hisobga olinadi.",notOfficial:"Cambridge 9708 tamoyillariga mos iClub o‘quv mezonlari. Bu savol uchun rasmiy Cambridge mark scheme emas.",openError:"Topshiriq hozir mavjud emas."},
   en:{title:"Written practice",criteria:"Marking scheme",hideCriteria:"Hide scheme",next:"Next",source:"Source",data:"Data table",
     back:"Back",loading:"Loading task…",offline:"Action not confirmed. Please retry.",
     complete:"Written tasks in this study plan have been completed.",
     instruction:"Complete the task independently. No essay upload or self-grading is required.",
     criteriaTitle:"Marking scheme",marks:"marks",ao12:"AO1 + AO2 · Knowledge and analysis",ao3:"AO3 · Evaluation and judgement",markContent:"Creditworthy content",levelsInfo:"Essay marks follow levels of knowledge, developed analysis and justified evaluation. Listed points are indicative, not one mark each.",pointInfo:"This part awards marks for correct concepts, calculations and explanations.",notOfficial:"iClub practice marking guide aligned to Cambridge 9708 principles; not an official Cambridge mark scheme for this question.",openError:"Task is currently unavailable."}
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
   // Sources are rendered ONLY from the guarded task-open server response.
   // A Section A question without its approved locale-matched source is not shown.
   function sourcePanel(item){
     if(item.program_key!=="economics_9708"||!["P2","P4"].includes(item.paper_code)||String(item.task_key||"").split(".")[1]!=="A")return null;
     const s=item.source;
     if(!s||s.language!==language||typeof s.title!=="string"||!s.title.trim()
       ||!Array.isArray(s.paragraphs)||!s.paragraphs.length
       ||s.paragraphs.some(p=>typeof p!=="string"||!p.trim()))
       throw Error("written_source_unavailable");
     const panel=el("section","ep-live-card ep-written-source");
     panel.setAttribute("aria-label",t.source);
     panel.append(el("div","ep-live-meta",t.source),
       el("h3","ep-written-source-title",s.title));
     for(const p of s.paragraphs)panel.append(el("p","ep-written-source-paragraph",p));
     if(s.table!==undefined&&s.table!==null){
       const x=s.table;
       if(!Array.isArray(x.columns)||x.columns.length<2
         ||!x.columns.every(h=>typeof h==="string"&&h.trim())
         ||!Array.isArray(x.rows)||!x.rows.length
         ||x.rows.some(row=>!Array.isArray(row)||row.length!==x.columns.length
           ||row.some(cell=>!["string","number"].includes(typeof cell))))
         throw Error("written_source_table_invalid");
       const scroll=el("div","ep-written-source-scroll");
       const table=el("table","ep-written-source-table");
       const caption=el("caption","",t.data+(typeof x.unit==="string"&&x.unit.trim()?" · "+x.unit:""));
       const thead=el("thead"),tr=el("tr");
       x.columns.forEach(h=>{const th=el("th","",h);th.scope="col";tr.append(th);});
       thead.append(tr);table.append(caption,thead);
       const tbody=el("tbody");
       for(const row of x.rows){
         const line=el("tr");
         row.forEach((cell,i)=>{
           const node=el(i===0?"th":"td","",String(cell));
           if(i===0)node.scope="row";
           line.append(node);
         });
         tbody.append(line);
       }
       table.append(tbody);scroll.append(table);panel.append(scroll);
     }
     return panel;
   }
   function renderTask(item,token){
      const body=page();
      const card=el("section","ep-live-card ep-written-question");
      const meta=el("div","ep-written-task-meta");
      meta.append(el("span","ep-written-task-paper",item.paper_code||""));
      card.append(meta,el("p","ep-live-qtext ep-written-task-text",item.question),
        el("p","ep-written-instruction",t.instruction));
      body.append(card);
      const source=sourcePanel(item);
      if(source)body.append(source);
      const work=el("section","ep-live-card ep-written-workflow");
      const criteriaBox=el("div","ep-written-marking");criteriaBox.hidden=true;
      const err=el("p","ep-live-meta");err.setAttribute("role","alert");
      const actions=el("div","ep-live-actions ep-written-actions");
      const criteriaButton=btn(t.criteria,async()=>{
        if(closed||working||token!==sequence)return;
        if(!criteriaBox.hidden){
          criteriaBox.hidden=true;
          criteriaButton.textContent=t.criteria;
          return;
        }
        working=true;criteriaButton.disabled=true;
        try{
          const details=await ctl.criteria();
          if(closed||token!==sequence)return;
          const title=el("div","ep-written-marking-head");
          const scheme=details.marking;
          title.append(el("h3","ep-written-marking-title",t.criteriaTitle));
          if(scheme)title.append(el("span","ep-written-mark-total",
            scheme.max_marks+" "+t.marks));
          criteriaBox.replaceChildren(title);
          if(scheme){
            const breakdown=el("div","ep-written-mark-breakdown");
            const ao12=el("div","ep-written-mark-part");
            ao12.append(el("span","",t.ao12),
              el("strong","",scheme.ao12_marks+" / "+scheme.max_marks));
            breakdown.append(ao12);
            if(scheme.ao3_marks>0){
              const ao3=el("div","ep-written-mark-part");
              ao3.append(el("span","",t.ao3),
                el("strong","",scheme.ao3_marks+" / "+scheme.max_marks));
              breakdown.append(ao3);
            }
            criteriaBox.append(breakdown,el("p","ep-written-mark-help",
              scheme.style==="levels"?t.levelsInfo:t.pointInfo),
              el("h4","ep-written-mark-subtitle",t.markContent));
          }else{
            criteriaBox.append(el("h4","ep-written-mark-subtitle",t.markContent));
          }
          const list=el("ul","ep-live-list ep-written-mark-points");
          for(const requirement of (scheme?.indicative_points||details.requirements))
            list.append(el("li","",requirement));
          criteriaBox.append(list);
          if(scheme)criteriaBox.append(el("p","ep-written-mark-disclaimer",t.notOfficial));
          criteriaBox.hidden=false;criteriaButton.textContent=t.hideCriteria;
          err.textContent="";
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
      work.append(actions,err,criteriaBox);body.append(work);
   }
   function dispose(){closed=true;sequence++;ctl=null;root=null;}
   loadNext();
   return Object.freeze({dispose});
 }
 window.iClubWrittenCoreViewV1=Object.freeze({mount});
})();