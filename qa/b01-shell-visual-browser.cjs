/* B01 offline Chromium: same source header/nav, before and after CSS.
   Never loads app.js, Supabase, Telegram, or external content. */
"use strict";
const fs=require("node:fs"),path=require("node:path"),http=require("node:http");
const assert=require("node:assert/strict");
const {chromium}=require("playwright");
const root=path.resolve(__dirname,"..");
const original=fs.readFileSync(path.join(root,"index.html"),"utf8");
const header=original.match(/<header id="topbar"[\s\S]*?<\/header>/)?.[0];
const nav=original.match(/<nav id="tabbar"[\s\S]*?<\/nav>/)?.[0];
assert.ok(header&&nav,"Existing source shell required");
assert.deepEqual(Array.from(nav.matchAll(/data-tab="([^"]+)"/g),m=>m[1]),["home","courses","ratings","profile"]);
const labels={
 ru:["Главная","Учёба","Рейтинг","Профиль"],
 uz:["Bosh sahifa","O‘qish","Reyting","Profil"],
 en:["Home","Study","Ratings","Profile"]
};
assert.ok(fs.readFileSync(path.join(root,"i18n.js"),"utf8").includes('tab_study: "O‘qish"'));
const allow=new Set(["/","/logo.png","/style.css","/visual/iclub-visual-v3.css","/visual/iclub-premium-v3.css","/visual/iclub-shell-b01.css"]);
const server=http.createServer((req,res)=>{
 const pathname=new URL(req.url,"http://127.0.0.1").pathname;
 if(!allow.has(pathname)){res.writeHead(404).end();return;}
 if(pathname==="/"){res.writeHead(200,{"content-type":"text/html"}).end("B01");return;}
 try{const data=fs.readFileSync(path.join(root,pathname.slice(1)));
 res.writeHead(200,{"content-type":pathname.endsWith(".css")?"text/css":"image/png"}).end(data);
 }catch{res.writeHead(404).end();}
});
function fixture(base,after,view){
 const styles=["style.css","visual/iclub-visual-v3.css","visual/iclub-premium-v3.css"];
 if(after)styles.push("visual/iclub-shell-b01.css");
 const links=styles.map(p=>'<link rel="stylesheet" href="'+p+'">').join("\n");
 const sections=["home","courses","ratings","profile","notifications","registration","splash","certificate-verify"];
 const active=view==="home-zero"?"home":view==="study-nested"?"courses":view==="profile-nested"?"profile":view;
 const main=sections.map(v=>'<section id="view-'+v+'" class="view '+(v===active?"is-active":"")+'"><div class="test-neutral"><div class="k">B01 · NAVIGATION ONLY</div><h2>Содержимое экрана</h2><p>Одинаковая область содержимого. Сравниваем только навигацию iClub.</p><div class="line"></div><div class="line short"></div><div class="line"></div></div></section>').join("\n");
 return '<!doctype html><html lang="ru"><head><meta charset="utf-8"><base href="'+base+'"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'+links+
 '<style>.test-neutral{max-width:560px;margin:24px auto;background:white;padding:25px 20px;border-radius:20px;border:1px solid #E8EDF5}.test-neutral .k{color:#2F6FD6;font-size:10px;font-weight:800;letter-spacing:.1em}.test-neutral h2{font-size:21px;margin:10px 0}.test-neutral p{font-size:13px;color:#697589;line-height:1.5}.line{height:13px;border-radius:9px;background:#F1F4FA;margin:15px 0}.line.short{width:70%}</style>'+
 '</head><body class="iclub-visual-v3"><div id="app" class="app">'+header+'<main id="main" class="main">'+main+'</main>'+nav+'</div></body></html>';
}
const cases=[
 {view:"home",width:390,lang:"ru"},
 {view:"study-nested",width:390,lang:"ru"},
 {view:"profile",width:390,lang:"ru"},
 {view:"home",width:320,lang:"uz"},
 {view:"ratings",width:375,lang:"uz"},
 {view:"home-zero",width:390,lang:"en"},
 {view:"courses",width:1440,lang:"en"},
 {view:"registration",width:390,lang:"ru"},
 {view:"splash",width:390,lang:"ru"},
 {view:"notifications",width:390,lang:"ru"}
];
function setup(s){
 const bar=document.getElementById("topbar"),back=document.getElementById("topbar-back"),tabs=document.getElementById("tabbar");
 const bell=document.getElementById("topbar-notifications"),badge=document.getElementById("topbar-notifications-badge"),gear=document.getElementById("topbar-action");
 const hiddenTop=s.view==="splash";
 const hiddenTabs=s.view==="splash"||s.view==="registration";
 const backOn=["study-nested","profile-nested","notifications","registration"].includes(s.view);
 const bellOn=["home","home-zero"].includes(s.view);
 const gearOn=s.view==="profile";
 bar.style.display=hiddenTop?"none":"grid";
 bar.classList.toggle("is-no-left",!backOn);
 back.style.visibility=backOn?"visible":"hidden";
 bell.style.display=bellOn?"inline-flex":"none";bell.style.visibility=bellOn?"visible":"hidden";
 badge.hidden=s.view!=="home";badge.textContent="3";
 gear.style.display=gearOn?"inline-flex":"none";gear.style.visibility=gearOn?"visible":"hidden";
 gear.dataset.action=gearOn?"profile-settings":"topbar-action";
 tabs.style.display=hiddenTabs?"none":"grid";
 document.getElementById("topbar-title").textContent="iClub";
 document.getElementById("topbar-subtitle").textContent="Smarter together";
 const selected= s.view.startsWith("home")?"home":s.view.startsWith("study")?"courses":s.view.startsWith("profile")?"profile":s.view==="ratings"?"ratings":"home";
 [...tabs.querySelectorAll(".tab")].forEach((b,i)=>{
   b.classList.toggle("is-active",b.dataset.tab===selected);
   b.querySelector(".tab-txt").textContent=s.labels[i];
 });
}
async function run(browser,base,s,after){
 const context=await browser.newContext({viewport:{width:s.width,height:844},deviceScaleFactor:1});
 const page=await context.newPage(),errors=[],offsite=[];
 page.on("pageerror",e=>errors.push(String(e)));
 await page.route("**/*",route=>{const u=new URL(route.request().url());if(u.hostname==="127.0.0.1")return route.continue();offsite.push(u.href);return route.abort();});
 try{
 await page.goto(base,{waitUntil:"domcontentloaded"});
 await page.setContent(fixture(base,after,s.view),{waitUntil:"load"});
 await page.evaluate(setup,{view:s.view,labels:labels[s.lang]});
 const result=await page.evaluate(()=>{
   const tabs=document.getElementById("tabbar"),bar=document.getElementById("topbar");
   const rb=x=>{let r=x.getBoundingClientRect();return{l:r.left,r:r.right,t:r.top,b:r.bottom,w:r.width,h:r.height}};
   return{overflow:document.documentElement.scrollWidth-innerWidth,tabDisplay:getComputedStyle(tabs).display,barDisplay:getComputedStyle(bar).display,
   radius:getComputedStyle(tabs).borderRadius,
   navBox:rb(tabs),brandBox:rb(document.querySelector(".topbar-brand")),barBox:rb(bar),
   tabs:[...tabs.querySelectorAll(".tab")].map(x=>{const text=x.querySelector(".tab-txt");return{str:text.textContent,button:rb(x),word:rb(text),client:text.clientWidth,scroll:text.scrollWidth}}),
   badgeHidden:document.getElementById("topbar-notifications-badge").hidden,
   gear:getComputedStyle(document.getElementById("topbar-action")).display,
   back:getComputedStyle(document.getElementById("topbar-back")).visibility,
   subtitle:document.getElementById("topbar-subtitle").textContent};
 });
 assert.ok(result.overflow<=1,"horizontal overflow "+s.view+"/"+s.lang+"/"+s.width+" "+result.overflow);
 if(after && s.view==="home" && s.lang==="ru" && s.width===390){
   const computed=await page.locator("#tabbar .tab").evaluateAll(els=>els.map(el=>{
     const s=getComputedStyle(el);return {border:s.border,outline:s.outline,background:s.backgroundColor,color:s.color,active:el.classList.contains("is-active"),font:s.fontSize};
   }));
   const debug=await page.evaluate(()=>{
     const el=document.querySelector("#tabbar .tab");
     const sheet=[...document.styleSheets].find(s=>s.href?.includes("iclub-shell-b01.css"));
     return { el:el.outerHTML.slice(0,250), styleSheets:[...document.styleSheets].map(s=>s.href),
      rules:sheet?[...sheet.cssRules].filter(r=>r.selectorText?.includes("#tabbar")&&r.selectorText?.includes(".tab")).slice(0,7).map(r=>({selector:r.selectorText,matches:el.matches(r.selectorText),css:r.style?.cssText?.slice(0,210)})):[],
      computed:{appearance:getComputedStyle(el).appearance, border:getComputedStyle(el).border,
       background:getComputedStyle(el).background,color:getComputedStyle(el).color},
      parents:el.parentElement?.outerHTML.slice(0,150)
     };
   });
   console.log("B01_STYLE_DIAGNOSTIC "+JSON.stringify(computed)+" MATCH "+JSON.stringify(debug));
 }
 assert.deepEqual(result.tabs.map(x=>x.str),labels[s.lang]);
 assert.equal(result.tabs.length,4);
 if(s.view==="splash"||s.view==="registration")assert.equal(result.tabDisplay,"none");
 if(s.view==="splash")assert.equal(result.barDisplay,"none");
 if(!["splash","registration"].includes(s.view)){
   for(const tab of result.tabs){
     assert.ok(tab.scroll<=tab.client+1,"clipped text "+tab.str+" "+s.width+" "+after);
     assert.ok(tab.button.w>=44&&tab.button.h>=44,"small touch area");
     assert.ok(tab.word.l>=tab.button.l-1&&tab.word.r<=tab.button.r+1,"label outside tab");
   }
   assert.equal(result.subtitle,"Smarter together");
   assert.ok(result.navBox.l>=-1&&result.navBox.r<=s.width+1,"nav outside screen");
 }
 if(s.view==="home")assert.equal(result.badgeHidden,false);
 if(s.view==="home-zero")assert.equal(result.badgeHidden,true);
 if(s.view==="profile")assert.notEqual(result.gear,"none");
 if(["study-nested","notifications","registration"].includes(s.view))assert.equal(result.back,"visible");
 assert.deepEqual(offsite,[]);
 assert.deepEqual(errors,[]);
 const capture=s.width===390&&s.lang==="ru"&&["home","study-nested","profile"].includes(s.view)||after&&s.width===320&&s.lang==="uz";
 if(capture)await page.screenshot({path:path.join(root,"b01-"+(after?"after":"before")+"-"+s.view+"-"+s.lang+"-"+s.width+".png"),fullPage:false});
 console.log("PASS",after?"AFTER":"BEFORE",s.view,s.lang,s.width,"radius",result.radius,"overflow",result.overflow);
 }finally{await context.close();}
}
(async()=>{
 await new Promise(r=>server.listen(0,"127.0.0.1",r));
 const base="http://127.0.0.1:"+server.address().port+"/";
 const browser=await chromium.launch({headless:true});
 try{for(const s of cases){await run(browser,base,s,false);await run(browser,base,s,true);}}
 finally{await browser.close();await new Promise(r=>server.close(r));}
})().catch(e=>{console.error(e);server.close();process.exitCode=1;});
