#!/usr/bin/env node
"use strict";
// Live iClub Written Core controller + real learner UI in isolated Chromium.
// All RPCs synthetic, NO auth token, NO production DB, NO external network.
// An open written answer is independently done by learner; grade cannot be invented.
const assert=require("node:assert/strict"),path=require("node:path");
const {chromium}=require("playwright");
const rooted=f=>path.resolve(__dirname,"..",f);
const texts={
 ru:{next:"Далее",criteria:"Критерии оценивания",complete:"Письменные задания по текущему плану пройдены.",offline:"Не удалось подтвердить действие.",unavailable:"Задание сейчас недоступно."},
 uz:{next:"Keyingi",criteria:"Baholash mezonlari",complete:"Joriy rejadagi yozma topshiriqlar yakunlandi.",offline:"Amal tasdiqlanmadi.",unavailable:"Topshiriq hozir mavjud emas."},
 en:{next:"Next",criteria:"Assessment criteria",complete:"Written tasks in this study plan have been completed.",offline:"Action not confirmed.",unavailable:"Task is currently unavailable."}
};
const task={
 task_kind:"written_external",task_token:"synthetic-token",task_key:"P2.B1",task_version:"v1",
 plan_item_id:"synthetic-item",program_key:"economics_9708",program_version:"v1",
 paper_code:"P2",question:"Explain how a change in demand could affect price.",
 runtime_enabled:true,can_advance:true
};
const criteria={
 available:true,task_key:"P2.B1",task_version:"v1",
 mark_scheme:{
   max_marks:20,ao12_marks:14,ao3_marks:6,marking_style:"levels",
   official_cambridge:false,
   assessment_criteria:[
     "Use relevant economic concepts accurately.",
     "Explain the effect of the change in demand using reasoning.",
     "Evaluate relevant limitations and justify the conclusion."
   ]
 }
};
async function scenario(browser,lang,width,kind){
 const page=await browser.newPage({viewport:{width,height:844},timezoneId:"Asia/Tashkent"});
 const errors=[];page.on("pageerror",e=>errors.push(String(e)));
 await page.route(/^https?:\/\//,r=>r.abort());
 try {
  await page.setContent('<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="exam-prep-host-root"></div></body></html>');
  await page.addStyleTag({path:rooted("exam-prep/exam-prep-host.css")});
  await page.addScriptTag({path:rooted("exam-prep/runtime/written-core-controller-v1.js")});
  await page.addScriptTag({path:rooted("exam-prep/runtime/written-core-view-v1.js")});
  await page.evaluate(([lang,kind,task,criteria])=>{
   const state=window.__testWritten={
     advanced:false,mode:kind,advances:0,criteriaCalls:0,acks:0,
     clickedTokens:[],lastPage:null
   };
   const api={
    available:async()=>({available:true}),
    next:async()=>state.advanced?{status:"completed"}:{status:"ready",plan_item_id:task.plan_item_id},
    open:async()=>kind==="unauthorized"?{...task,runtime_enabled:false}:structuredClone(task),
    criteria:async()=>{
      state.criteriaCalls++;
      return structuredClone(criteria);
    },
    advance:async args=>{
      state.advances++;state.clickedTokens.push(args.p_idempotency_key);
      if(kind==="offline-first"&&state.advances===1)throw Error("network down before commit");
      if(kind==="lost-ack"&&state.advances===1){state.advanced=true;throw Error("response lost after commit")}
      state.advanced=true;
      return {status:"advanced",task_key:task.task_key,task_version:task.task_version,plan_item_id:task.plan_item_id};
    },
    status:async()=>({status:state.advanced?"advanced":"active",task_key:task.task_key,
      task_version:task.task_version,plan_item_id:task.plan_item_id,program_version:task.program_version})
   };
   state.view=window.iClubWrittenCoreViewV1.mount({
      root:document.querySelector("#exam-prep-host-root"),planId:"synthetic-plan",language:lang,
      api,createActionKey:()=> "synthetic-idempotency-"+(state.advances+1),
      onBack:()=>{state.back=true}
   });
  },[lang,kind,task,criteria]);
  const root=page.locator("#exam-prep-host-root"),t=texts[lang];
  if(kind==="unauthorized"){
   await page.getByText(t.unavailable).waitFor();
   assert.equal(await root.locator(".ep-written-task-text").count(),0);
   assert.equal((await page.evaluate(()=>window.__testWritten.advances)),0);
   return;
  }
  await page.locator(".ep-written-task-text").waitFor();
  assert((await page.locator(".ep-written-task-text").textContent()).includes("change in demand"));
  assert.equal(await page.locator("textarea,input[type=file],input[name=score]").count(),0);
  assert.equal(await page.getByText(t.complete).count(),0);
  assert.equal(await page.locator(".ep-written-mark-points li").count(),0);
  if(kind==="criteria"){
    await page.getByRole("button",{name:t.criteria}).click();
    await page.locator(".ep-written-mark-points li").first().waitFor();
    assert.equal(await page.locator(".ep-written-mark-points li").count(),3);
    assert.equal((await root.textContent()).includes("Use relevant economic concepts accurately."),true);
    assert.equal((await root.textContent()).includes("Use relevant economic concepts accurately."),true);
    assert.equal(await page.evaluate(()=>window.__testWritten.criteriaCalls),1);
  }
  // A correct solution can be written as words, equations, annotated graph, or
  // any mathematically equivalent form on paper: there is no auto-essay input.
  await page.getByRole("button",{name:t.next}).click();
  if(kind==="offline-first"){
    await page.getByText(t.offline,{exact:false}).waitFor();
    assert.equal((await page.evaluate(()=>window.__testWritten.advanced)),false);
    assert.equal(await page.getByText(t.complete).count(),0);
    await page.getByRole("button",{name:t.next}).click();
  }
  await page.getByText(t.complete).waitFor();
  const state=await page.evaluate(()=>({
   advances:window.__testWritten.advances,criteriaCalls:window.__testWritten.criteriaCalls,
   confirmed:window.__testWritten.advanced,ids:window.__testWritten.clickedTokens,
   html:document.querySelector("#exam-prep-host-root").innerHTML
  }));
  assert.equal(state.confirmed,true);
  assert.equal(state.advances,kind==="offline-first"?2:1);
  assert.equal(state.criteriaCalls,kind==="criteria"?1:0);
  assert.equal(state.html.includes("score="),false);
  assert.equal(state.html.includes("mastery"),false);
  assert.equal(state.html.includes("mentor_queue"),false);
  assert.equal(state.ids.every(id=>id.startsWith("synthetic-idempotency-")),true);
  const wide=await page.evaluate(()=>document.documentElement.scrollWidth>window.innerWidth+4);
  assert.equal(wide,false,"horizontal overflow "+lang+" "+width+" "+kind);
  assert.deepEqual(errors,[]);
 }finally{await page.close()}
}
(async()=>{
 const browser=await chromium.launch({headless:true});
 try{
  let n=0;
  for(const lang of ["ru","uz","en"])
   for(const width of [375,1280])
    for(const kind of ["criteria","no-criteria","lost-ack","offline-first","unauthorized"]){
     await scenario(browser,lang,width,kind);n++;
    }
  console.log("PASS",n,"isolated written-core browser E2E scenarios, RU/UZ/EN mobile/desktop, criteria/no-criteria, idempotence, offline and owner gate; no learner data.");
 }finally{await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
