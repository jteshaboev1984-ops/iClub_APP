"use strict";
// Synthetic-only Chemistry P1 UI regression. Run:
// node scripts/qa-chemistry-9701-j05-ui-navigation-offline.cjs
const assert=require("node:assert/strict");
class Node {
 constructor(tag){this.tag=tag;this.children=[];this.textContent="";this.className="";
 this.attrs={};this.handlers={};this.open=false;this.disabled=false;
 this.classList={add:x=>this.className+=" "+x};}
 append(...a){this.children.push(...a);}replaceChildren(...a){this.children=a;}
 setAttribute(k,v){this.attrs[k]=v;}addEventListener(k,v){this.handlers[k]=v;}
 find(q){const ok=q.startsWith(".")?this.className.split(/\s+/).includes(q.slice(1)):this.tag===q;
 return (ok?[this]:[]).concat(...this.children.flatMap(x=>x.find(q)));}
 querySelector(q){return this.find(q)[0]||null;}
 get firstElementChild(){return this.children[0]||null;}
}
const tick=async()=>{for(let i=0;i<12;i++)await Promise.resolve();};
function setup(source){
 const server={answers:{},finalized:false,score:0,calls:[],expired:false,lostAck:false,delayWrite:false,confirm:""};
 server.read=lang=>({ok:true,status:server.finalized?"finalized":"active",
 score:server.finalized?server.score:null,deadline_at:"2099-01-01T00:00:00Z",
 items:Array.from({length:40},(_,i)=>({order:i+1,question:"Q"+(i+1)+" "+lang,
 options:["A","B","C","D"],answered:server.answers[i+1]!==undefined,
 selected_index:server.answers[i+1]??null,
 correct_index:server.finalized?1:null,
 explanation:server.finalized?"Synthetic reasoning":null}))});
 const root=new Node("div");
 const window={iClubExamPrepHostInternal:{},crypto:{randomUUID:()=>"synthetic-only"},
 confirm:t=>{server.confirm=t;return true;},
 sb:{rpc:async(n,a={})=>{
 server.calls.push([n,a.p_language||""]);
 if(n.endsWith("_history_v1"))return {data:{ok:true,sessions:[]}};
 if(n.endsWith("_start_v1"))return {data:{ok:true,session_id:"test-session"}};
 if(n.endsWith("_get_v1"))return {data:server.read(a.p_language)};
 if(n.endsWith("_answer_v1")){
  if(server.expired)return {data:{ok:false,code:"attempt_closed_or_expired"}};
  if(server.delayWrite){
   server.delayWrite=false;
   return new Promise(resolve=>{server.release=()=>{
    server.answers[a.p_item_order]=a.p_choice;resolve({data:{ok:true,saved:true}});
   };});
  }
  server.answers[a.p_item_order]=a.p_choice;
  if(server.lostAck){server.lostAck=false;return {error:"response dropped"};}
  return {data:{ok:true,saved:true}};
 }
 if(n.endsWith("_finish_v1")){server.finalized=true;
 server.score=Object.values(server.answers).filter(x=>x===1).length;
 return {data:{ok:true,score:server.score}};}
 throw Error("Unexpected RPC: "+n);
 }}};
 new Function("window","document","setInterval","clearInterval",source)(
 window,{createElement:t=>new Node(t)},()=>1,()=>{});
 const api=window.iClubExamPrepHostInternal.chemistryNative;
 const mount=()=>api.mount({root,language:"en",onBack:()=>{},
 shell:{enabled:true,program_key:"chemistry_9701",
 papers:[{code:"P1",assessment_kind:"mcq",mcq_count:40}]}});
 const button=t=>root.find("button").find(x=>x.textContent===t);
 return {api,root,server,mount,button};
}
module.exports=async source=>{
 const passed=[];
 const a=setup(source);assert.equal(a.mount(),true);await tick();
 await a.button("Start or resume").handlers.click();await tick();
 assert.equal(a.root.find(".ep-chem-question-jump").length,40);
 let nav=a.root.find(".ep-chem-question-map")[0];
 nav.open=true;nav.handlers.toggle();
 await a.root.find(".ep-chem-question-jump")[39].handlers.click();await tick();
 assert.equal(a.root.find(".ep-native-stem")[0].textContent,"Q40 en");
 await a.root.find(".ep-native-option")[1].handlers.click();await tick();
 assert.equal(a.root.find(".ep-native-stem")[0].textContent,"Q1 en");
 assert.equal(a.root.find(".ep-chem-question-map")[0].open,true);
 await a.button("Finish paper").handlers.click();await tick();
 assert.ok(a.server.confirm.includes("Unanswered questions: 39"));
 assert.equal(a.root.find(".ep-native-result")[0].textContent,"Result: 1 / 40");
 a.api.unmount();passed.push("40-question navigation and final result");
 const b=setup(source);b.mount();await tick();
 await b.button("Start or resume").handlers.click();await tick();
 b.server.delayWrite=true;
 const saving=b.root.find(".ep-native-option")[1].handlers.click();await tick();
 b.api.setLanguage("uz");await tick();
 assert.equal(b.server.calls.some(([n,l])=>n.endsWith("_get_v1")&&l==="uz"),false);
 b.server.release();await saving;await tick();
 assert.equal(b.server.answers[1],1);
 assert.equal(b.root.find(".ep-native-stem")[0].textContent,"Q2 uz");
 b.api.unmount();passed.push("language request waits for answer write");
 const c=setup(source);c.mount();await tick();
 await c.button("Start or resume").handlers.click();await tick();
 c.server.lostAck=true;
 await c.root.find(".ep-native-option")[1].handlers.click();await tick();
 assert.equal(c.server.answers[1],1);
 await c.button("Try again").handlers.click();await tick();
 assert.equal(c.root.find(".ep-native-option")[1].attrs["aria-pressed"],"true");
 c.api.unmount();passed.push("lost network acknowledgment restores confirmed choice");
 const d=setup(source);d.mount();await tick();
 await d.button("Start or resume").handlers.click();await tick();
 d.server.expired=true;
 await d.root.find(".ep-native-option")[1].handlers.click();await tick();
 assert.equal(d.server.finalized,true);
 assert.deepEqual(d.server.answers,{});
 assert.equal(d.root.find(".ep-native-result")[0].textContent,"Result: 0 / 40");
 d.api.unmount();passed.push("expired answer rejected and paper finalized");
 return {passed:passed.length,scenarios:passed};
};
if(require.main===module){
 const fs=require("node:fs"),path=require("node:path");
 module.exports(fs.readFileSync(path.join(__dirname,"..","exam-prep",
 "exam-prep-chemistry-native.js"),"utf8"))
 .then(result=>console.log(JSON.stringify(result,null,2)))
 .catch(e=>{console.error(e);process.exitCode=1;});
}
