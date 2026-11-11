/* B02 visual-only, offline Chromium. Original Home source markup, representative
   app.js card DOM. All values are demo placeholders, never production data. */
"use strict";
const fs=require("node:fs"),path=require("node:path"),http=require("node:http"),assert=require("node:assert/strict");
const {chromium}=require("playwright");
const root=path.resolve(__dirname,"..");
const html=fs.readFileSync(path.join(root,"index.html"),"utf8");
const app=fs.readFileSync(path.join(root,"app.js"),"utf8");
const i18n=fs.readFileSync(path.join(root,"i18n.js"),"utf8");
const view=html.match(/<section id="view-home"[\s\S]*?<\/section>/)?.[0];
const top=html.match(/<header id="topbar"[\s\S]*?<\/header>/)?.[0];
const nav=html.match(/<nav id="tabbar"[\s\S]*?<\/nav>/)?.[0];
assert.ok(view&&top&&nav,"Existing Home/shell source must be used");
for(const k of ["home-competitive-list","home-study-list","home-extra-card","home-extra-body"])
 assert.ok(view.includes('id="'+k+'"'),"Source id missing: "+k);
for(const k of ["homeCompetitiveCardEl","homePinnedTileEl","home-competitive-hero-img","js-home-comp-module","js-home-pin-count"])
 assert.ok(app.includes(k),"Original dynamic card selector missing: "+k);
for(const k of ["home_competitive_mode","home_pinned_subjects","home_extra_title"])
 assert.ok(i18n.includes(k+":"),"Original i18n missing: "+k);
const labels={
 ru:["Соревновательный режим","Отслеживайте прогресс по Cambridge curriculum","Закреплённые предметы","Дополнительно","Математика","Экономика","ТУР АКТИВЕН","Практика 1 тура","Участвуйте в текущем туре.","Открыть предмет","Практика"],
 uz:["Musobaqa rejimi","Cambridge curriculum bo‘yicha progressni kuzating","Biriktirilgan fanlar","Qo‘shimcha","Matematika","Iqtisodiyot","TUR FAOL","1-tur amaliyoti","Joriy turda ishtirok eting.","Fanni ochish","Amaliyot"],
 en:["Competitive Mode","Track your Cambridge curriculum progress","Pinned Subjects","More","Mathematics","Economics","TOUR ACTIVE","Practice for Tour 1","Take part in the current tour.","Open subject","Practice"]
};
const navLabels={
 ru:["Главная","Учёба","Рейтинг","Профиль"],
 uz:["Bosh sahifa","O‘qish","Reyting","Profil"],
 en:["Home","Study","Ratings","Profile"]
};
const emptyStrings={
 ru:["Пока нет предметов в соревновательном режиме.","Здесь появятся ваши учебные предметы. Откройте раздел «Предметы» и закрепите нужные для быстрого доступа."],
 uz:["Hozircha musobaqa rejimida fanlar yo‘q.","Bu yerda sizning o‘quv fanlaringiz ko‘rinadi. Kerakli fanlarga tezkor kirish uchun «Fanlar» bo‘limida biriktiring."],
 en:["No subjects in competitive mode yet.","Your study subjects will appear here. Open Courses and pin the ones you want for quick access."]
};
for(const l of Object.keys(navLabels)){
 for(const value of navLabels[l].concat(emptyStrings[l]))assert.ok(i18n.includes(value),"Source translation missing: "+value);
}
const allow=p=>p==="/"||p==="/logo.png"||p==="/style.css"||p==="/visual/iclub-visual-v3.css"||p==="/visual/iclub-premium-v3.css"||p==="/visual/iclub-home-b02.css"||/^\/asset\/[A-Za-z0-9._-]+$/.test(p);
const server=http.createServer((req,res)=>{
 const u=new URL(req.url,"http://127.0.0.1"),p=u.pathname;
 if(!allow(p)){res.writeHead(404).end();return;}
 if(p==="/"){res.writeHead(200,{"content-type":"text/html"}).end("offline");return;}
 try{const bytes=fs.readFileSync(path.join(root,p.slice(1)));
 res.writeHead(200,{"content-type":p.endsWith(".css")?"text/css":"image/png"}).end(bytes);}
 catch{res.writeHead(404).end();}
});
function content(base,after){
 const css=["style.css","visual/iclub-visual-v3.css","visual/iclub-premium-v3.css"];
 if(after)css.push("visual/iclub-home-b02.css");
 return '<!doctype html><html lang="ru"><head><meta charset="utf-8"><base href="'+base+'"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">'+
 css.map(p=>'<link rel="stylesheet" href="'+p+'">').join("")+
 '</head><body class="iclub-visual-v3"><div id="app" class="app">'+top+
 '<main id="main" class="main">'+view.replace('class="view"','class="view is-active"')+'</main>'+nav+'</div></body></html>';
}
function card(key,title,t){
 return '<div class="home-competitive-card" data-subject="'+key+'">'+
 '<div class="home-competitive-badge">'+t[6]+'</div>'+
 '<div class="home-competitive-hero"><div class="home-competitive-hero-img" aria-hidden="true"></div></div>'+
 '<div class="home-competitive-body"><div class="home-competitive-title">'+title+'</div>'+
 '<div class="home-competitive-note js-home-comp-note">'+t[8]+'</div>'+
 '<div class="home-competitive-meta"><span class="home-competitive-module js-home-comp-module">'+t[7]+'</span>'+
 '<span class="home-competitive-rank js-home-comp-rank iclub-stat-empty">—</span></div>'+
 '<div class="home-competitive-percent js-home-comp-percent"></div>'+
 '<div class="home-progress"><div class="home-progress-fill js-home-comp-fill" style="width:0%"></div></div></div>'+
 '<button class="btn primary home-competitive-btn" type="button">'+t[9]+'</button></div>';
}
function pinned(name,t){
 return '<button class="home-pinned-tile" type="button">'+
 '<div class="home-pinned-ico" aria-hidden="true"><svg class="v3-home-pinned-icon" viewBox="0 0 24 24"><path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H11v16H6.5A2.5 2.5 0 0 0 4 21z"/><path d="M20 5.5A2.5 2.5 0 0 0 17.5 3H13v16h4.5A2.5 2.5 0 0 1 20 21z"/></svg></div>'+
 '<div class="home-pinned-title">'+name+'</div>'+
 '<div class="home-pinned-meta"><span class="js-home-pin-count">—</span> '+t[10]+'</div></button>';
}
function wordWrapChecks(el){
 const node=[...el.childNodes].find(x=>x.nodeType===Node.TEXT_NODE&&x.textContent.trim());
 if(!node)return true;
 const txt=node.textContent;
 for(const m of txt.matchAll(/[\p{L}\p{N}‘ʼ'-]{4,}/gu)){
  const a=document.createRange();a.setStart(node,m.index);a.setEnd(node,m.index+1);
  const startY=a.getBoundingClientRect().top;
  a.setStart(node,m.index+m[0].length-1);a.setEnd(node,m.index+m[0].length);
  if(Math.abs(startY-a.getBoundingClientRect().top)>2)return false;
 }
 return true;
}
const cases=[
 {lang:"ru",width:390,c:2,p:2,expanded:false},
 {lang:"ru",width:320,c:1,p:2,expanded:false},
 {lang:"uz",width:320,c:2,p:2,expanded:true},
 {lang:"en",width:375,c:0,p:0,expanded:false},
 {lang:"ru",width:390,c:2,p:4,expanded:true},
 {lang:"en",width:1440,c:2,p:4,expanded:false}
];
async function run(browser,base,s,after){
 const context=await browser.newContext({viewport:{width:s.width,height:844},deviceScaleFactor:1});
 const page=await context.newPage(),errors=[],offsite=[];
 page.on("pageerror",e=>errors.push(String(e)));
 await page.route("**/*",route=>{const u=new URL(route.request().url());if(u.hostname==="127.0.0.1")return route.continue();offsite.push(u.href);return route.abort();});
 try{
 await page.goto(base,{waitUntil:"domcontentloaded"});
 await page.setContent(content(base,after),{waitUntil:"load"});
 const t=labels[s.lang];
 await page.evaluate(({s,t,competitive,pinnedCards,tabs,emptyText})=>{
  const q=x=>document.querySelector(x);
  q('[data-i18n="home_competitive_mode"]').textContent=t[0];
  q('[data-i18n="home_competitive_mode_subtitle"]').textContent=t[1];
  q('[data-i18n="home_pinned_subjects"]').textContent=t[2];
  q('[data-i18n="home_extra_title"]').textContent=t[3];
  q("#home-competitive-list").innerHTML=s.c?competitive.slice(0,s.c).join(""):'<div class="empty muted">'+emptyText[0]+'</div>';
  q("#home-study-list").innerHTML=s.p?pinnedCards.slice(0,s.p).join(""):'<div class="empty muted">'+emptyText[1]+'</div>';
  q("#home-extra-card").classList.toggle("is-open",s.expanded);
  q("#topbar").style.display="grid";q("#topbar").classList.add("is-no-left");
  q("#topbar-back").style.visibility="hidden";
  q("#topbar-notifications").style.display="inline-flex";q("#topbar-notifications").style.visibility="visible";
  q("#topbar-action").style.display="none";
  q("#topbar-subtitle").textContent="Smarter together";
  q("#tabbar").style.display="grid";
  document.documentElement.lang=s.lang;
  [...document.querySelectorAll("#tabbar .tab-txt")].forEach((el,i)=>el.textContent=tabs[i]);
 },{s,t,competitive:[card("mathematics",t[4],t),card("economics",t[5],t)],
 pinnedCards:[pinned(t[4],t),pinned(t[5],t),pinned("Biology",t),pinned("Computer Science",t)],
 tabs:navLabels[s.lang],emptyText:emptyStrings[s.lang]});
 await page.waitForTimeout(260);
 const result=await page.evaluate(()=>{
  function wordWrapChecks(el){
    const node=[...el.childNodes].find(x=>x.nodeType===Node.TEXT_NODE&&x.textContent.trim());
    if(!node)return true;
    const txt=node.textContent;
    for(const m of txt.matchAll(/[\p{L}\p{N}‘ʼ'-]{4,}/gu)){
      const a=document.createRange();a.setStart(node,m.index);a.setEnd(node,m.index+1);
      const startY=a.getBoundingClientRect().top;
      a.setStart(node,m.index+m[0].length-1);a.setEnd(node,m.index+m[0].length);
      if(Math.abs(startY-a.getBoundingClientRect().top)>2)return false;
    }
    return true;
  }
  const q=x=>document.querySelector(x);
  return {
   overflow:document.documentElement.scrollWidth-innerWidth,
   comp:document.querySelectorAll("#home-competitive-list .home-competitive-card").length,
   pinned:document.querySelectorAll("#home-study-list .home-pinned-tile").length,
   accordion:document.querySelectorAll('[data-action="home-extra-toggle"]').length,
   about:document.querySelectorAll('[data-action="open-about"]').length,
   news:document.querySelectorAll('#home-extra-card [data-action="open-news"]').length,
   community:document.querySelectorAll('#home-extra-card [data-action="open-community"]').length,
   open:q("#home-extra-card").classList.contains("is-open"),
   empty:document.querySelectorAll("#home-competitive-list > .empty,#home-study-list > .empty").length,
   columns:getComputedStyle(q("#home-study-list")).gridTemplateColumns.split(" ").length,
   words:[...document.querySelectorAll("#view-home .home-block-title,#view-home .home-pinned-title,#view-home .home-competitive-title")].map(x=>({t:x.textContent,ok:wordWrapChecks(x)})),
   legacy:getComputedStyle(q(".home-legacy")).display,
   tabs:[...document.querySelectorAll("#tabbar .tab-txt")].map(el=>({text:el.textContent,client:el.clientWidth,scroll:el.scrollWidth}))
  };
 });
 assert.ok(result.overflow<=1,"horizontal overflow "+s.lang+"/"+s.width+" "+result.overflow);
 assert.equal(result.comp,s.c);assert.equal(result.pinned,s.p);
 assert.equal(result.accordion,1);assert.equal(result.about,1);
 assert.equal(result.news,1);assert.equal(result.community,1);
 assert.equal(result.open,s.expanded);
 assert.equal(result.empty,(s.c===0?1:0)+(s.p===0?1:0));
 for(const x of result.words)assert.ok(x.ok,"split whole word at "+s.width+" "+x.t);
 if(after&&s.width<360)assert.equal(result.columns,1,"no two-column labels at 320px");
 assert.equal(result.legacy,"none");
 assert.deepEqual(result.tabs.map(x=>x.text),navLabels[s.lang]);
 for(const x of result.tabs)assert.ok(x.scroll<=x.client+1,"clipped nav label: "+x.text);
 assert.deepEqual(offsite,[]);assert.deepEqual(errors,[]);
 const capture=(s.lang==="ru"&&s.width===390&&s.p===2)||
  (after&&s.width===320)||(after&&s.c===0)||(after&&s.expanded);
 if(capture)await page.screenshot({path:path.join(root,"b02-"+(after?"after":"before")+"-"+s.lang+"-"+s.width+"-c"+s.c+"-p"+s.p+(s.expanded?"-open":"-closed")+".png"),fullPage:true});
 console.log("PASS",after?"AFTER":"BEFORE",s.lang,s.width,"competitive="+s.c,"pinned="+s.p,"expanded="+s.expanded,"overflow="+result.overflow);
 }finally{await context.close();}
}
(async()=>{
 await new Promise(ok=>server.listen(0,"127.0.0.1",ok));
 const base="http://127.0.0.1:"+server.address().port+"/";
 const browser=await chromium.launch({headless:true});
 try{for(const s of cases){await run(browser,base,s,false);await run(browser,base,s,true);}}
 finally{await browser.close();await new Promise(ok=>server.close(ok));}
})().catch(e=>{console.error(e);server.close();process.exitCode=1;});
