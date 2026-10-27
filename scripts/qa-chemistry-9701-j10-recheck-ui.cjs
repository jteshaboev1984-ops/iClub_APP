"use strict";
// J10 standalone synthetic integration UI test: no real student or question content.
// Run: node scripts/qa-chemistry-9701-j10-recheck-ui.cjs
const assert=require("node:assert/strict");
class Element {
 constructor(tag){this.tag=tag;this.children=[];this.textContent="";this.className="";
 this.handlers={};this.attrs={};this.disabled=false;this.checked=false;this.open=false;
 this.classList={add:v=>this.className+=" "+v};}
 append(...xs){this.children.push(...xs);}
 replaceChildren(...xs){this.children=xs;}
 setAttribute(k,v){this.attrs[k]=v;}
 addEventListener(k,fn){this.handlers[k]=fn;}
 find(q){const ok=q.startsWith(".")?this.className.split(/\s+/).includes(q.slice(1)):this.tag===q;
 return (ok?[this]:[]).concat(...this.children.flatMap(c=>c.find(q)));}
 get firstElementChild(){return this.children[0]||null;}
}
const flush=async()=>{for(let k=0;k<25;k++)await Promise.resolve();};
module.exports=async(entrySource,recheckSource)=>{
 const root=new Element("div"),saved={},calls=[];
 let recheckFinal=false,allowed=true;
 const w={iClubExamPrepHostInternal:{},
  crypto:{randomUUID:()=>"j10_fake_nonce"},
  setInterval:()=>5,clearInterval:()=>{},confirm:()=>true,
  sb:{rpc:async(name,args={})=>{
   calls.push(name);
   if(name==="iclub_exam_chemistry_entry_history_v1")
    return {data:{ok:true,sessions:[{session_id:"entry_fixture",
     status:"finalized",score:12,started_at:"2026-10-27T11:00:00Z"}]}};
   if(name==="get_my_exam_prep_chemistry_recheck_shell_v1")
    return {data:allowed?{enabled:true,program_key:"chemistry_9701",
      assessment_code:"RECHECK",entry_session_id:"entry_fixture",
      item_count:22,duration_seconds:1800,can_credit_mastery:false,
      learning_ack_kind:"self_report"}:{}};
   if(name==="iclub_exam_chemistry_recheck_history_v1")
    return {data:{ok:true,sessions:[]}};
   if(name==="iclub_exam_chemistry_recheck_start_v1"){
    assert.equal(args.p_study_confirmed,true);
    assert.equal(args.p_entry_id,"entry_fixture");
    return {data:{ok:true,session_id:"recheck_fixture",status:"active"}};
   }
   if(name==="iclub_exam_chemistry_recheck_get_v1")
    return {data:{ok:true,status:recheckFinal?"finalized":"active",
      score:recheckFinal?20:null,deadline_at:"2099-01-01T00:00:00Z",
      items:Array.from({length:22},(_,i)=>({
        order:i+1,unit:i+1,skill_key:"S"+i,
        question:"New Q"+(i+1)+" "+args.p_language,
        options:["New A","New B","New C","New D"],
        answered:saved[i+1]!==undefined,selected_index:saved[i+1]??null,
        correct_index:recheckFinal?0:null,
        explanation:recheckFinal?"Synthetic new question explanation":null}))}};
   if(name==="iclub_exam_chemistry_recheck_answer_v1"){
    saved[args.p_item_order]=args.p_choice;return {data:{ok:true,saved:true}};}
   if(name==="iclub_exam_chemistry_recheck_finish_v1"){
    recheckFinal=true;return {data:{ok:true,score:20,answered:21}};}
   if(name==="iclub_exam_chemistry_recheck_review_v1")
    return {data:{ok:true,can_credit_mastery:false,calibrated_diagnostic:false,
      recheck_means_improvement_not_mastery:true,
      topics:Array.from({length:22},(_,i)=>({unit:i+1,
      title:"Topic "+(i+1)+" "+args.p_language,entry_answered:true,
      entry_correct:i>10,recheck_answered:i!==2,recheck_correct:i!==1&&i!==2,
      study_recommended:i===1||i===2}))}};
   throw Error("Unexpected fake RPC "+name);
  }}};
 const doc={createElement:t=>new Element(t)};
 new Function("window","document","setInterval","clearInterval",entrySource)(
 w,doc,()=>2,()=>{});
 new Function("window","document",recheckSource)(w,doc);
 const shell={enabled:true,program_key:"chemistry_9701",assessment_code:"ENTRY",
 item_count:22,duration_seconds:1800};
 const disabled=w.iClubExamPrepHostInternal.chemistryRecheckNative.mount({
  root,shell:{...shell,assessment_code:"RECHECK",enabled:false},language:"ru"});
 assert.equal(disabled,false);
 let closed=false;
 assert.equal(w.iClubExamPrepHostInternal.chemistryEntryNative.mount({
  root,shell,language:"ru",onBack:()=>{closed=true;}}),true);
 await flush();
 const btn=t=>root.find("button").find(x=>x.textContent===t);
 assert.ok(btn("Повторная проверка · новые задания"));
 await btn("Повторная проверка · новые задания").handlers.click();await flush();
 assert.ok(root.find(".ep-chem-recheck").length>0);
 const ack=root.find("input")[0];assert.ok(ack);
 let start=btn("Перейти к проверке");
 assert.equal(start.disabled,true);
 ack.checked=true;ack.handlers.change();start=btn("Перейти к проверке");
 assert.equal(start.disabled,false);
 await start.handlers.click();await flush();
 assert.equal(root.find(".ep-chem-question-jump").length,22);
 assert.equal(root.find(".ep-native-stem")[0].textContent,"New Q1 ru");
 assert.equal(root.find(".ep-native-explanation").length,0);
 await root.find(".ep-native-option")[0].handlers.click();await flush();
 assert.equal(root.find(".ep-native-stem")[0].textContent,"New Q2 ru");
 w.iClubExamPrepHostInternal.chemistryRecheckNative.setLanguage("uz");await flush();
 assert.equal(root.find(".ep-native-stem")[0].textContent,"New Q2 uz");
 assert.equal(saved[1],0);
 await btn("Yakunlash").handlers.click();await flush();
 assert.equal(root.find(".ep-native-result")[0].textContent,"Qayta tekshiruv natijasi: 20 / 22");
 assert.ok(root.find(".ep-native-explanation").some(x=>x.textContent==="Synthetic new question explanation"));
 await btn("Mavzular bo‘yicha taqqoslash").handlers.click();await flush();
 assert.equal(root.find(".ep-chem-review-focus")[0].find(".ep-chem-review-row").length,2);
 assert.equal(root.find(".ep-chem-review-all")[0].find(".ep-chem-review-row").length,22);
 assert.equal(root.find(".ep-chem-recheck-comparison").length,24);
 assert.ok(root.find(".ep-host-note").some(x=>x.textContent.includes("to‘liq o‘zlashtirish tasdig‘i emas")));
 await btn("Kirish tekshiruviga").handlers.click();await flush();
 assert.ok(btn("Повторная проверка · новые задания"));
 assert.equal(closed,false);
 w.iClubExamPrepHostInternal.chemistryEntryNative.unmount();
 w.iClubExamPrepHostInternal.chemistryRecheckNative.unmount();
 return {passed:16,checks:["closed recheck shell denied",
 "approved recheck offer after Entry","adapter transition without host teardown",
 "explicit readiness checkbox","start requires acknowledgement","22-question map",
 "no answer key or explanation before finish","autosaved answer","RU to UZ",
 "final score 20/22","explanation after finish","topic comparison",
 "focus on two wrong topics","all 22 topic comparisons",
 "no mastery claim","return to Entry without leaving subject"]};
};
if(require.main===module){
 const fs=require("node:fs"),path=require("node:path");
 const base=path.join(__dirname,"..","exam-prep");
 module.exports(fs.readFileSync(path.join(base,"exam-prep-chemistry-entry-native.js"),"utf8"),
 fs.readFileSync(path.join(base,"exam-prep-chemistry-recheck-native.js"),"utf8"))
 .then(x=>console.log(JSON.stringify(x,null,2))).catch(e=>{console.error(e);process.exitCode=1;});
}
