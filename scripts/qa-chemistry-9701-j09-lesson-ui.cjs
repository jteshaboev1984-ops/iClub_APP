"use strict";
// J09 repeatable synthetic ENTRY and Theory-only skill-link UI regression. No private questions or learner records.
// Run: node scripts/qa-chemistry-9701-j09-lesson-ui.cjs
const assert=require("node:assert/strict");
class Element {
 constructor(tag){this.tag=tag;this.children=[];this.textContent="";this.className="";
 this.handlers={};this.attrs={};this.open=false;this.disabled=false;
 this.classList={add:v=>this.className+=" "+v};}
 append(...els){this.children.push(...els);}
 replaceChildren(...els){this.children=els;}
 addEventListener(k,cb){this.handlers[k]=cb;}
 setAttribute(k,v){this.attrs[k]=v;}
 find(q){const ok=q.startsWith(".")?this.className.split(/\s+/).includes(q.slice(1)):this.tag===q;
 return (ok?[this]:[]).concat(...this.children.flatMap(ch=>ch.find(q)));}
 querySelector(q){return this.find(q)[0]||null;}
 get firstElementChild(){return this.children[0]||null;}
}
const flush=async()=>{for(let i=0;i<14;i++)await Promise.resolve();};
module.exports=async source=>{
 const root=new Element("div"),saved={},calls=[];let finished=false,lessonApproved=true;
 const w={iClubExamPrepHostInternal:{},crypto:{randomUUID:()=>"fake_client_key_j08"},
 confirm:()=>true,sb:{rpc:async(name,args={})=>{
 calls.push(name);
 if(name==="iclub_exam_chemistry_entry_history_v1")
 return {data:{ok:true,sessions:[]}};
 if(name==="iclub_exam_chemistry_entry_start_v1")
 return {data:{ok:true,session_id:"fake-only-session"}};
 if(name==="iclub_exam_chemistry_entry_get_v1")
 return {data:{ok:true,status:finished?"finalized":"active",score:finished?1:null,
 deadline_at:"2099-01-01T00:00:00Z",
 items:Array.from({length:22},(_,i)=>({order:i+1,unit:i+1,
 question:"Synthetic Q"+(i+1)+" "+args.p_language,
 options:["Synthetic A","Synthetic B","Synthetic C","Synthetic D"],
 answered:saved[i+1]!==undefined,selected_index:saved[i+1]??null,
 correct_index:finished?1:null,explanation:finished?"Synthetic explanation":null}))}};
 if(name==="iclub_exam_chemistry_entry_answer_v1"){
 saved[args.p_item_order]=args.p_choice;return {data:{ok:true,saved:true}};}
 if(name==="iclub_exam_chemistry_entry_finish_v1"){
 finished=true;return {data:{ok:true,score:1,answered:1}};}
 if(name==="iclub_exam_chemistry_entry_review_v1")
 return {data:{ok:true,can_credit_mastery:false,calibrated_diagnostic:false,
 topics:Array.from({length:22},(_,i)=>({unit:i+1,title:"Synthetic topic "+(i+1)+" "+args.p_language,
 answered:i===0,correct:i===0,review_needed:i!==0,
 skill_key:"CHEM9701-"+String(i+1).padStart(2,"0")+"-02",
 lesson_available:true}))}};
 if(name==="iclub_exam_chemistry_entry_lesson_v1")
 return lessonApproved
  ? {data:{ok:true,skill_key:args.p_skill_key,title:"Synthetic lesson",
    explanation:"Synthetic theory is only available after the subject library has been released.",
    ai_tutor_content_included:false,can_credit_mastery:false}}
  : {data:{ok:false,code:"lesson_not_released"}};
 throw Error("Unexpected RPC "+name);
 }}};
 new Function("window","document","setInterval","clearInterval",source)(
 w,{createElement:t=>new Element(t)},()=>1,()=>{});
 const ui=w.iClubExamPrepHostInternal.chemistryEntryNative;
 const shell={enabled:true,program_key:"chemistry_9701",
 assessment_code:"ENTRY",item_count:22,duration_seconds:1800};
 assert.equal(ui.mount({root,shell:{...shell,enabled:false},language:"en"}),false);
 let returned=false;
 assert.equal(ui.mount({root,shell,language:"ru",onBack:()=>{returned=true;}}),true);
 await flush();
 const button=txt=>root.find("button").find(b=>b.textContent===txt);
 assert.ok(button("Начать или продолжить"));
 assert.equal(root.find(".ep-native-stem").length,0);
 await button("Начать или продолжить").handlers.click();await flush();
 assert.equal(root.find(".ep-chem-question-jump").length,22);
 assert.equal(root.find(".ep-native-stem")[0].textContent,"Synthetic Q1 ru");
 assert.equal(root.find(".ep-native-explanation").length,0);
 await root.find(".ep-native-option")[1].handlers.click();await flush();
 assert.equal(root.find(".ep-native-stem")[0].textContent,"Synthetic Q2 ru");
 ui.setLanguage("uz");await flush();
 assert.equal(root.find(".ep-native-stem")[0].textContent,"Synthetic Q2 uz");
 assert.equal(saved[1],1);
 await button("Tekshiruvni yakunlash").handlers.click();await flush();
 assert.equal(root.find(".ep-native-result")[0].textContent,"Natija: 1 / 22");
 assert.ok(root.find(".ep-native-explanation").some(x=>x.textContent==="Synthetic explanation"));
 assert.equal(calls.includes("iclub_exam_chemistry_entry_review_v1"),false);
 await button("Keyin nimani o‘rganish kerak").handlers.click();await flush();
 assert.equal(root.find(".ep-chem-review-focus")[0].find(".ep-chem-review-row").length,21);
 assert.equal(root.find(".ep-chem-review-all")[0].find(".ep-chem-review-row").length,22);
 assert.ok(root.find(".ep-host-note").some(x=>x.textContent.includes("bitta savol")));
 assert.ok(button("Mavzuni o‘rganish"));
 await button("Mavzuni o‘rganish").handlers.click();await flush();
 assert.equal(root.find(".ep-chem-entry-theory")[0].textContent.includes("Synthetic theory"),true);
 assert.equal(root.find(".ep-native-result")[0].textContent,"Synthetic lesson");
 assert.equal(calls.includes("iclub_exam_chemistry_entry_lesson_v1"),true);
 await button("Mavzular ro‘yxatiga").handlers.click();await flush();
 lessonApproved=false;
 await button("Mavzuni o‘rganish").handlers.click();await flush();
 assert.ok(root.find(".ep-host-note").some(x=>x.textContent.includes("Dars hali ochilmagan")));
 assert.equal(root.find(".ep-chem-entry-theory").length,0);
 await button("Mavzular ro‘yxatiga").handlers.click();await flush();
 await button("Fanning o‘quv materiallariga").handlers.click();await flush();
 assert.equal(returned,true);
 ui.unmount();
 return {passed:16,checks:["entry gate OFF","existing shared-host entry",
 "22-question map","no early explanations","save and next","RU→UZ",
 "server-saved answer","result","post-finish explanation",
 "skill-specific review list","back to Chemistry subject",
 "lesson offered only with availability","correct skill RPC",
 "rendered released theory","denied hidden theory","back to topics"]};
};
if(require.main===module){
 const fs=require("node:fs"),path=require("node:path");
 const source=fs.readFileSync(path.join(__dirname,"..","exam-prep","exam-prep-chemistry-entry-native.js"),"utf8");
 module.exports(source).then(result=>console.log(JSON.stringify(result,null,2)))
 .catch(e=>{console.error(e);process.exitCode=1;});
}
