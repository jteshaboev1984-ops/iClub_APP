/* UX #531 — offline integrated browser QA against actual index.html and current CSS.
   Fixture strips application scripts; no Supabase, network writes, or real users. */
'use strict';
const fs=require('node:fs'),path=require('node:path'),http=require('node:http'),assert=require('node:assert/strict');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..'),source=fs.readFileSync(path.join(root,'index.html'),'utf8');
assert(source.includes('academy-view-zone'));
const fixture=source.replace(/<script\b[\s\S]*?<\/script>/gi,m=>m.includes('visual/iclub-academy-ux531-interactions.js')?m:'')
  .replace(/class="i18n-pending"/,'');
const mime={'.html':'text/html','.css':'text/css','.js':'text/javascript','.png':'image/png','.svg':'image/svg+xml','.woff2':'font/woff2'};
const srv=http.createServer((req,res)=>{
 const raw=decodeURIComponent((req.url||'/').split('?')[0]);
 if(raw==='/fixture'){res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});res.end(fixture);return;}
 const file=path.resolve(root,'.'+raw);
 if(!file.startsWith(root+path.sep)||!fs.existsSync(file)||!fs.statSync(file).isFile()){
  res.writeHead(404);res.end('missing');return;
 }
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream'});
 res.end(fs.readFileSync(file));
});
function setScreen({view,screen}){
 document.querySelectorAll('.view').forEach(el=>el.classList.toggle('is-active',el.id==='view-'+view));
 document.querySelectorAll('#courses-stack > .stack-screen').forEach(el=>{
  const active=view==='courses'&&el.id==='courses-'+screen;
  el.classList.toggle('is-active',active);el.hidden=!active;
 });
 const bar=document.getElementById('topbar');
 bar.style.display='grid';
 bar.classList.toggle('is-no-left',view==='home'||view==='ratings'||view==='profile'||screen==='all-subjects');
 document.getElementById('tabbar').style.display='grid';
}
const rgbFrom=s=>[...s.matchAll(/rgba?\((\d+),\s*(\d+),\s*(\d+)/g)].map(m=>[+m[1],+m[2],+m[3]]);
(async()=>{
 await new Promise(r=>srv.listen(0,'127.0.0.1',r));
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 try{
  for(const viewport of [{width:320,height:720},{width:375,height:812},{width:390,height:844},{width:430,height:932},{width:1440,height:900}]){
   const page=await browser.newPage({viewport});
   const errors=[];page.on('pageerror',e=>errors.push(e.message));
   await page.route(/^https?:\/\/(?!127\.0\.0\.1)/,r=>r.abort());
   await page.goto('http://127.0.0.1:'+srv.address().port+'/fixture',{waitUntil:'domcontentloaded'});
   const headers=[];
   for(const scenario of [{view:'home',screen:''},{view:'courses',screen:'all-subjects'},{view:'courses',screen:'subject-hub'}]){
    await page.evaluate(setScreen,scenario);
    const m=await page.evaluate(({view,screen})=>{
      const top=document.getElementById('topbar');
      const zone=view==='home'?document.querySelector('#view-home .academy-view-zone'):
        screen==='all-subjects'?document.querySelector('#courses-all-subjects .academy-view-zone'):
        document.querySelector('#courses-subject-hub .subject-hub-head');
      return{height:top.getBoundingClientRect().height+zone.getBoundingClientRect().height,
       barColor:getComputedStyle(top).backgroundColor,gradient:getComputedStyle(zone).backgroundImage,
       width:document.documentElement.scrollWidth,viewport:innerWidth};
    },scenario);
    assert(m.height>=216&&m.height<=255,'top zone height '+JSON.stringify({scenario,viewport,m}));
    assert(m.width<=m.viewport+2,'horizontal overflow '+JSON.stringify({scenario,viewport,m}));
    headers.push(m);
   }
   const heights=headers.map(x=>x.height);
   assert(Math.max(...heights)-Math.min(...heights)<2,'unequal headers '+JSON.stringify({viewport,heights}));
   const bars=headers.map(x=>x.barColor);
   assert(new Set(bars).size===3,'topbar needs distinct related blue tones '+JSON.stringify(bars));
   const barTriplets=bars.map(x=>rgbFrom(x)[0]);
   assert(barTriplets.every(x=>Array.isArray(x)),'topbar RGB missing '+JSON.stringify(bars));
   const maxBarDifference=Math.max(...[0,1,2].map(c=>Math.max(...barTriplets.map(x=>x[c]))-Math.min(...barTriplets.map(x=>x[c]))));
   assert(maxBarDifference>=12&&maxBarDifference<=44,'topbar tonal shift must be visible but gentle '+JSON.stringify({bars,maxBarDifference}));
   const triplets=headers.map(x=>rgbFrom(x.gradient));
   assert(triplets.every(x=>x.length===3),'header gradients must have 3 stops '+JSON.stringify(triplets));
   assert(new Set(headers.map(x=>x.gradient)).size===3,'header gradients must be distinct');
   for(let stop=0;stop<3;stop++)for(let c=0;c<3;c++){
    const vals=triplets.map(t=>t[stop][c]);
    assert(Math.max(...vals)-Math.min(...vals)<=43,'sharp palette shift '+JSON.stringify({viewport,stop,c,vals}));
   }
   await page.evaluate(setScreen,{view:'home',screen:''});
   await page.evaluate(()=>{
    const competitive=document.getElementById('home-competitive-list');
    const pinned=document.getElementById('home-study-list');
    competitive.replaceChildren();pinned.replaceChildren();
    for(let i=0;i<2;i++){
     const card=document.createElement('div');card.className='home-competitive-card';
     card.innerHTML='<span class="home-competitive-title">Subject '+i+'</span><button class="home-competitive-btn">Open</button>';
     competitive.append(card);
    }
    for(let i=0;i<5;i++){
     const card=document.createElement('button');card.className='home-pinned-tile';
     card.innerHTML='<span class="home-pinned-title">Subject '+i+'</span>';pinned.append(card);
    }
   });
   await page.waitForTimeout(120);
   const rails=await page.evaluate(()=>['home-competitive-list','home-study-list'].map(id=>{
    const e=document.getElementById(id),dots=e.nextElementSibling;
    return {id,children:e.children.length,dots:dots?.children.length||0,scrollable:e.scrollWidth>e.clientWidth,layout:getComputedStyle(e).display};
   }));
   assert(!rails[0].scrollable&&rails[1].scrollable,'Competitive must stay static while pinned Study swipes '+JSON.stringify(rails));
   assert.equal(rails[0].layout,'grid','Competitive cards must use the static grid');
   assert.equal(rails[0].dots,0,'Competitive must not have swipe dots');
   assert.equal(rails[1].dots,5,'5 pinned subjects/dots');
   const competitivePositions=await page.evaluate(()=>[...document.querySelectorAll('#home-competitive-list .home-competitive-card')].map(el=>({top:el.getBoundingClientRect().top,left:el.getBoundingClientRect().left})));
   assert(competitivePositions.length===2&&
     (viewport.width<700
       ? competitivePositions[0].top<competitivePositions[1].top
       : Math.abs(competitivePositions[0].top-competitivePositions[1].top)<2&&
           competitivePositions[0].left<competitivePositions[1].left),
     'All Competitive cards must be visible, stacked on phones and side-by-side on desktop: '+
       JSON.stringify({viewport,competitivePositions}));
   await page.evaluate(()=>{const e=document.getElementById('home-study-list');e.scrollLeft=e.scrollWidth;});
   await page.waitForTimeout(190);
   const current=await page.evaluate(()=>[...document.querySelector('#home-study-list+.academy-rail-pagination').children].findIndex(el=>el.getAttribute('aria-current')==='true'));
   assert(current>=2,'pinned pagination did not advance '+current);
   await page.evaluate(()=>{const e=document.getElementById('home-study-list');while(e.children.length>1)e.lastElementChild.remove();});
   await page.waitForTimeout(80);
   const single=await page.evaluate(()=>{
    const e=document.getElementById('home-study-list');
    return {hidden:e.nextElementSibling.hidden,childWidth:e.firstElementChild.getBoundingClientRect().width,railWidth:e.getBoundingClientRect().width};
   });
   assert(single.hidden&&Math.abs(single.childWidth-single.railWidth)<=3,'one subject should not carousel '+JSON.stringify(single));
   await page.evaluate(setScreen,{view:'courses',screen:'subject-hub'});
   const tabs=page.locator('#courses-subject-hub .academy-hub-tab');
   assert.equal(await tabs.count(),3,'three hub tabs');
   const headerOrder=await page.evaluate(()=>{
    const y=selector=>{
      const e=document.querySelector(selector),r=e.getBoundingClientRect();
      return{top:r.top,bottom:r.bottom,order:getComputedStyle(e).order};
    };
    return{header:y('#courses-subject-hub > .subject-hub-head'),
      tabs:y('#courses-subject-hub > .academy-hub-tabs'),
      preparation:y('#courses-subject-hub > #academy-hub-pane-preparation')};
   });
   assert(headerOrder.header.bottom<=headerOrder.tabs.top+2&&
     headerOrder.tabs.bottom<=headerOrder.preparation.top+2,
     'Subject Hub must show sapphire header BEFORE tabs and cards '+JSON.stringify(headerOrder));
   await tabs.nth(1).click();
   assert.equal(await page.locator('#academy-hub-pane-preparation').isHidden(),true);
   assert.equal(await page.locator('#academy-hub-pane-materials').isVisible(),true);
   await tabs.nth(1).press('ArrowRight');
   assert.equal(await page.locator('#academy-hub-pane-achievements').isVisible(),true);
   assert.equal(await page.locator('#exam-prep-host-root').count(),1,'Exam Prep host still present');

   if(viewport.width===390){
    // Execute the exact Home Continue helper extracted from the live app.js,
    // with a fake owner-bound vault and no application/network writes.
    const appText=fs.readFileSync(path.join(root,'app.js'),'utf8');
    const begin=appText.indexOf('  let academyHomeContinueRequest = 0;');
    const end=appText.indexOf('function renderHome() {',begin);
    assert(begin>=0&&end>begin&&end-begin<12000,'exact source helper missing');
    const helper=appText.slice(begin,end);
    assert(!/localStorage\.|deleteUserSubject|reset_subject_progress|\.from\(/.test(helper),
      'home helper must not mutate drafts or progress');
    await page.evaluate(setScreen,{view:'home',screen:''});
    await page.evaluate(()=>{
      const initial={
        status:'paused',subjectKey:'mathematics',
        quiz:{mode:'practice',safeSessionId:101,questions:[{id:11}]}
      };
      window.__academyAuthQA={
        owner:'00000000-0000-4000-8000-000000000001',
        other:'00000000-0000-4000-8000-000000000002',
        uid:null,draft:initial,screen:null,saved:0,practiceOpened:0,alerts:[]
      };
      const model=window.__academyAuthQA;
      window.sb={};
      window.iClubPracticeDraftIdentityV1={
        bind:async()=>model.uid,
        currentUid:()=>model.uid,
        read:()=>model.uid===model.owner?model.draft:null
      };
      window.loadProfile=()=>({subjects:[{key:'mathematics',mode:'study',pinned:true}]});
      window.isSubjectActive=k=>k==='mathematics';
      window.getVisibleSubjectsCatalog=()=>[{key:'mathematics'}];
      window.subjectByKey=()=>({title:'Mathematics'});
      window.subjectTitle=()=> 'Mathematics';
      window.t=k=>({practice:'Practice',academy_continue_status:'Paused session',academy_continue_cta:'Continue'})[k]||'';
      window.tr3=(ru,uz,en)=>en;
      window.iClubCommercialAccessUI={guardStudy:async()=>true};
      window.state={courses:{}};
      window.saveState=()=>{model.saved++};
      window.setTab=view=>{
        document.getElementById('view-home').classList.toggle('is-active',view==='home');
        document.getElementById('view-courses').classList.toggle('is-active',view==='courses');
      };
      window.replaceCourses=screen=>{model.screen=screen};
      window.getCoursesTopScreen=()=>model.screen;
      window.renderSubjectHub=async()=>{};
      window.openPracticeStart=async()=>{model.practiceOpened++};
      window.showToast=msg=>model.alerts.push(msg);
    });
    await page.addScriptTag({content:helper+'\nwindow.__runAcademyContinueQA=academyRenderHomeContinue;'});
    await page.evaluate(()=>window.__runAcademyContinueQA());
    assert(await page.locator('#academy-home-continue').isHidden(),'no auth must not show any local draft');
    await page.evaluate(()=>{window.__academyAuthQA.uid=window.__academyAuthQA.owner;});
    await page.evaluate(()=>window.__runAcademyContinueQA());
    assert(await page.locator('#academy-home-continue').isVisible(),'owner draft must show');
    assert.equal(await page.locator('#academy-home-continue-list > button').count(),1);
    const before=await page.evaluate(()=>JSON.stringify(window.__academyAuthQA.draft));
    // Simulate a stale Home card clicked just after the account has changed.
    await page.evaluate(()=>{window.__academyAuthQA.uid=window.__academyAuthQA.other;});
    await page.locator('#academy-home-continue-list > button').click();
    assert.equal(await page.evaluate(()=>window.__academyAuthQA.practiceOpened),0,'cross-account resume must fail closed');
    await page.evaluate(()=>window.dispatchEvent(new Event('iclub:practice-identity-invalidated')));
    assert(await page.locator('#academy-home-continue').isHidden(),'sign out must hide saved practice');
    await page.evaluate(()=>{window.__academyAuthQA.uid=window.__academyAuthQA.owner;});
    await page.evaluate(()=>window.__runAcademyContinueQA());
    await page.locator('#academy-home-continue-list > button').click();
    await page.waitForFunction(()=>window.__academyAuthQA.practiceOpened===1,{timeout:2000});
    const after=await page.evaluate(()=>JSON.stringify(window.__academyAuthQA.draft));
    assert.equal(before,after,'Home Continue must not mutate draft bytes');
    assert.equal(await page.evaluate(()=>window.__academyAuthQA.practiceOpened),1);
    console.log('PASS UX531 owner-bound Practice Continue: anonymous hidden, owner shown, cross-account blocked, existing route only.');
   }
   assert.equal(errors.length,0,'browser errors '+errors.join('; '));
   console.log('PASS UX531 '+viewport.width+'px: '+Math.round(heights[0])+'px matched headers; smooth sapphire; 2/5 rails; 3 subject tabs');
   await page.close();
  }
 }finally{await browser.close();await new Promise(r=>srv.close(r));}
})().catch(e=>{console.error('FAIL UX531 browser regression',e.stack||e);process.exitCode=1;});
