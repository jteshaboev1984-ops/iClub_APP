"use strict";
// Deterministic synthetic-only Chemistry P1 post-paper plan regression.
// Run: node scripts/qa-chemistry-9701-j06-review-plan-ui.cjs
const assert=require("node:assert/strict");
class Node {
 constructor(tag){this.tag=tag;this.children=[];this.className="";this.textContent="";this.open=false;this.attrs={};this.handlers={};
 this.disabled=false;this.classList={add:x=>this.className+=" "+x};}
 append(...a){this.children.push(...a);}replaceChildren(...a){this.children=a;}
 addEventListener(k,v){this.handlers[k]=v;}setAttribute(k,v){this.attrs[k]=v;}
 find(q){const match=q.startsWith(".")?this.className.split(/\s+/).includes(q.slice(1)):this.tag===q;
 return (match?[this]:[]).concat(...this.children.flatMap(x=>x.find(q)));}
 querySelector(q){return this.find(q)[0]||null;}
}
const tick=async()=>{for(let i=0;i<12;i++)await Promise.resolve();};
module.exports=async source=>{
 const server={calls:[],allowPlan:true};
 const root=new Node("div"),win={iClubExamPrepHostInternal:{},
 crypto:{randomUUID:()=>"fake-uuid"},
 confirm:()=>true,
 sb:{rpc:async(name,args={})=>{
  server.calls.push([name,args.p_language||""]);
  if(name.endsWith("_history_v1"))return {data:{ok:true,sessions:[]}};
  if(name.endsWith("_start_v1"))return {data:{ok:true,session_id:"fake-finalized-id"}};
  if(name.endsWith("_get_v1"))return {data:{ok:true,status:"finalized",score:38,
   items:Array.from({length:40},(_,i)=>({
    order:i+1,question:"Fictional Q"+(i+1),options:["A","B","C","D"],
    answered:true,selected_index:1,correct_index:i<2?0:1,explanation:"Synthetic explanation"
   }))}};
  if(name.endsWith("_review_plan_v1")){
   if(!server.allowPlan)return {data:{ok:false,code:"not_available"}};
   const topics=Array.from({length:22},(_,i)=>({
    unit:i+1,title:"Synthetic "+args.p_language+" "+(i+1),
    questions:i<18?2:1,correct: i===0?1:i<2?0:i<18?2:1,
    incorrect:i===0?1:i===1?2:0,unanswered:0
   }));
   return {data:{ok:true,exam_prep_diagnostic_result:false,can_credit_mastery:false,
    topics,focus_first:topics.slice(0,2).map(x=>({
     unit:x.unit,title:x.title,questions:x.questions,incorrect:x.incorrect,unanswered:0
    }))}};
  }
  return {data:{ok:false}};
 }}};
 new Function("window","document","setInterval","clearInterval",source)(
 win,{createElement:t=>new Node(t)},()=>1,()=>{});
 const api=win.iClubExamPrepHostInternal.chemistryNative;
 assert.equal(api.mount({root,language:"en",onBack:()=>{},
 shell:{enabled:true,program_key:"chemistry_9701",
 papers:[{code:"P1",assessment_kind:"mcq",mcq_count:40}]}}),true);
 await tick();
 const button=text=>root.find("button").find(x=>x.textContent===text);
 await button("Start or resume").handlers.click();await tick();
 assert.ok(button("What to review"));
 assert.equal(server.calls.some(([name])=>name.endsWith("_review_plan_v1")),false,
 "No plan data requested until result button clicked");
 await button("What to review").handlers.click();await tick();
 assert.ok(root.find(".ep-chem-review-focus")[0],"Priority section exists");
 assert.equal(root.find(".ep-chem-review-focus")[0].find(".ep-chem-review-row").length,2);
 assert.equal(root.find(".ep-chem-review-all")[0].find(".ep-chem-review-row").length,22);
 assert.ok(root.find(".ep-host-note").some(n=>n.textContent.includes("cannot establish mastery")));
 assert.equal(root.find(".ep-chem-review-focus")[0].find(".ep-chem-review-row")[0]
 .find("strong")[0].textContent,"1. Synthetic en 1");
 await button("Back to result").handlers.click();await tick();
 assert.equal(root.find(".ep-native-result")[0].textContent,"Result: 38 / 40");
 api.setLanguage("uz");await tick();
 assert.ok(button("Nimalarni takrorlash kerak"));
 await button("Nimalarni takrorlash kerak").handlers.click();await tick();
 assert.equal(root.find(".ep-chem-review-all")[0].find(".ep-chem-review-row")[0]
 .find("strong")[0].textContent,"1. Synthetic uz 1");
 await button("Natijaga qaytish").handlers.click();await tick();
 server.allowPlan=false;
 await button("Nimalarni takrorlash kerak").handlers.click();await tick();
 assert.ok(root.find(".ep-host-note").some(n=>n.textContent.includes("Takrorlash rejasini yuklab bo‘lmadi")));
 assert.ok(button("Natijaga qaytish"));
 api.unmount();
 return {passed:7,checks:["Result-gated action","No automatic pre-click fetching",
 "Top errors", "Full 22 AS unit list", "Conservative evidence note",
 "EN to UZ switch", "Safe failure and back"]};
};
if(require.main===module){
 const fs=require("node:fs"),path=require("node:path");
 const src=fs.readFileSync(path.join(__dirname,"..","exam-prep","exam-prep-chemistry-native.js"),"utf8");
 module.exports(src).then(r=>console.log(JSON.stringify(r,null,2))).catch(e=>{console.error(e);process.exitCode=1;});
}
