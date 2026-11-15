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
   assert(new Set(headers.map(x=>x.barColor)).size===1,'topbar color jumps '+JSON.stringify(headers.map(x=>x.barColor)));
   const triplets=headers.map(x=>rgbFrom(x.gradient));
   assert(triplets.every(x=>x.length===3),'header gradients must have 3 stops '+JSON.stringify(triplets));
   for(let stop=0;stop<3;stop++)for(let c=0;c<3;c++){
    const vals=triplets.map(t=>t[stop][c]);
    assert(Math.max(...vals)-Math.min(...vals)<=9,'sharp palette shift '+JSON.stringify({viewport,stop,c,vals}));
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
    return {id,children:e.children.length,dots:dots.children.length,scrollable:e.scrollWidth>e.clientWidth};
   }));
   assert(rails[0].scrollable&&rails[1].scrollable,'native swipe should be available '+JSON.stringify(rails));
   assert.equal(rails[0].dots,2,'2 competitive dots');
   assert.equal(rails[1].dots,5,'5 pinned subjects/dots');
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
   await tabs.nth(1).click();
   assert.equal(await page.locator('#academy-hub-pane-preparation').isHidden(),true);
   assert.equal(await page.locator('#academy-hub-pane-materials').isVisible(),true);
   await tabs.nth(1).press('ArrowRight');
   assert.equal(await page.locator('#academy-hub-pane-achievements').isVisible(),true);
   assert.equal(await page.locator('#exam-prep-host-root').count(),1,'Exam Prep host still present');
   assert.equal(errors.length,0,'browser errors '+errors.join('; '));
   console.log('PASS UX531 '+viewport.width+'px: '+Math.round(heights[0])+'px matched headers; smooth sapphire; 2/5 rails; 3 subject tabs');
   await page.close();
  }
 }finally{await browser.close();await new Promise(r=>srv.close(r));}
})().catch(e=>{console.error('FAIL UX531 browser regression',e.stack||e);process.exitCode=1;});
