"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const vm=require("node:vm");
const fs=require("node:fs");
const path=require("node:path");
const root=path.resolve(__dirname,"..");
const clientSource=fs.readFileSync(path.join(__dirname,"iclub-ai-v21-browser-adapter.js"),"utf8");
const panelSource=fs.readFileSync(path.join(root,"ai-v21-real-preview-ui-snapshot.js"),"utf8");
const publishedSql=fs.readFileSync(path.join(__dirname,"iclub_ai_v21_product_help_21_publish_20261020.sql"),"utf8");
class Node {
 constructor(tag="div"){
  this.tag=tag;this.children=[];this.listeners={};this.style={};
  this.attributes={};this.hidden=false;this.disabled=false;
  this.classList={contains:x=>this.className?.split(" ").includes(x)};
 }
 setAttribute(k,v){this.attributes[k]=String(v)}
 getAttribute(k){return this.attributes[k]??null}
 append(...kids){for(const kid of kids){this.children.push(kid);kid.parent=this}}
 appendChild(kid){this.append(kid);return kid}
 remove(){if(this.parent)this.parent.children=this.parent.children.filter(x=>x!==this)}
 after(el){if(this.parent){const i=this.parent.children.indexOf(this);this.parent.children.splice(i+1,0,el);el.parent=this.parent}}
 replaceChildren(...kids){for(const c of this.children)c.parent=null;this.children=[];this.append(...kids)}
 querySelector(selector){
  const m=/^\[([a-z-]+)(?:="([^"]+)")?\]$/.exec(selector);
  if(!m)return null;
  const find=(node)=>{for(const c of node.children){if(c.attributes[m[1]]!==undefined&&
     (m[2]===undefined||c.attributes[m[1]]===m[2]))return c;
    const nested=find(c);if(nested)return nested}return null;};
  return find(this);
 }
 closest(selector){return selector===".profile-section"?this.parentSection:null}
 addEventListener(ev,fn){(this.listeners[ev]??=[]).push(fn)}
 async click(){for(const fn of this.listeners.click??[])await fn()}
 focus(){}
 getClientRects(){return []}
}
function rig(locale="ru"){
 const state={eligible:false,consented:false,opened:0,locale,requests:[]};
 const body=new Node("body");
 const profile=new Node("section");profile.id="view-profile";profile.className="view is-active";
 const main=new Node("section");main.id="profile-main";
 const section=new Node("section");section.className="profile-section";
 const support=new Node("button");support.setAttribute("data-action","open-support");support.parentSection=section;
 section.append(support);main.append(section);profile.append(main);body.append(profile);
 main.querySelector=selector=>selector==='[data-action="open-support"]'?support:null;
 const locate=(node,id)=>{
   if(node.id===id)return node;
   for(const c of node.children){const result=locate(c,id);if(result)return result}
   return null;
 };
 const document={
  readyState:"loading",body,
  getElementById:id=>locate(body,id),
  createElement:tag=>new Node(tag),
  addEventListener(){},
 };
 const win={
  sb:{
   auth:{
    getUser:async()=>({data:{user:{id:"11111111-1111-4111-8111-111111111111"}},error:null}),
    onAuthStateChange(){}
   },
   functions:{invoke:async(_,req)=>{
    state.requests.push(req.body);
    if(req.body.intent==="status")return{data:{
      ok:true,candidate:true,consented:state.consented,eligible:state.eligible
    },error:null};
    if(req.body.intent==="consent"){
      state.consented=true;state.eligible=true;
      return{data:{ok:true,recorded:true},error:null};
    }
    throw Error("Unexpected delivery in consent QA");
   }}
  },
  i18n:{getLang:()=>state.locale},
  iClubGlobalAiShell:{refresh:async()=>{},open:()=>{state.opened++}}
 };
 vm.runInNewContext(clientSource,{window:win,document,MutationObserver:class{observe(){}},
  console,crypto:{randomUUID:()=>""}},{filename:"beta-client.js"});
 return {state,document,api:win.iClubAiV21BetaClient};
}
const tr={
 ru:{before:"Позже",open:"Открыть iClub AI",success:"Доступ к iClub AI открыт"},
 uz:{before:"Keyinroq",open:"iClub AI’ni ochish",success:"iClub AI’dan foydalanish mumkin"},
 en:{before:"Later",open:"Open iClub AI",success:"Your iClub AI access is ready"}
};
for(const lang of ["ru","uz","en"]){
 test("Consent UI in "+lang+" has unambiguous completion and launches approved shell",async()=>{
  const x=rig(lang);
  await x.api.status();
  const invite=x.document.getElementById("iclub-ai-v21-optin-invite");
  assert.ok(invite);
  const inviteButton=invite.children[0].children[0];
  await inviteButton.click();
  const modal=x.document.getElementById("iclub-ai-v21-optin-dialog");
  assert.ok(modal);
  const card=modal.children[0],title=card.children[0],row=card.children[2];
  assert.equal(row.children.length,2);
  assert.equal(row.children[0].textContent,tr[lang].before);
  assert.equal(x.state.consented,false);
  await row.children[1].click();
  assert.equal(x.state.consented,true);
  assert.equal(title.textContent,tr[lang].success);
  assert.equal(row.children.length,1);
  assert.equal(row.children[0].textContent,tr[lang].open);
  assert.equal(x.state.opened,0);
  await row.children[0].click();
  assert.equal(x.state.opened,1);
  assert.equal(x.document.getElementById("iclub-ai-v21-optin-dialog"),null);
  assert.equal(x.document.getElementById("iclub-ai-v21-optin-invite"),null);
  assert.equal(x.state.requests.filter(x=>x.intent==="consent").length,1);
 });
}
test("Connected AI chips are substantive and only published prepared source keys",()=>{
 for(const key of ["catalog_help","practice_rules","practice_after",
   "recs_help","tour_rules","books_help","support_help"]){
  assert.ok(panelSource.includes(key+':"'),key);
  assert.match(publishedSql,new RegExp("'"+key+"'"));
 }
 for(const forbidden of ['nav_home:"Где Главная?"','nav_courses:"Где Учёба?"']){
  assert.equal(panelSource.includes(forbidden),false);
 }
 assert.match(panelSource,/open: \(\) => openPanel\(\)/);
 assert.match(panelSource,/iclub-global-ai-mark-logo/);
 assert.doesNotMatch(clientSource,/OPENAI_API_KEY|localStorage|sessionStorage/);
 assert.doesNotMatch(publishedSql,/DELETE FROM|TRUNCATE|DROP TABLE/);
});
