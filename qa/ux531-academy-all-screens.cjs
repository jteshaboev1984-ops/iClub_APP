/* UX531 Academy OS B04-B08, real index.html and CSS, offline Chromium. */
'use strict';
const fs=require('node:fs'),path=require('node:path'),http=require('node:http'),assert=require('node:assert/strict');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..');
const source=fs.readFileSync(path.join(root,'index.html'),'utf8');
const css=fs.readFileSync(path.join(root,'visual/iclub-academy-ux531-b04b08.css'),'utf8');
const i18n=fs.readFileSync(path.join(root,'i18n.js'),'utf8');
const globalViews=['splash','registration','home','courses','ratings','profile','notifications',
 'community','about','support','support-topic','certificates','certificate-verify','archive'];
const stackScreens=['all-subjects','subject-hub','lessons','video','practice-start','practice-quiz',
 'practice-result','practice-review','practice-recs','tours','tour-rules','tour-quiz','tour-result',
 'tour-review','books','my-recs','my-rec-topic-history','my-rec-topic-review','my-rec-detail'];
const protectedIds=['practice-pause-btn','practice-submit-btn','practice-question',
 'tour-rules-accept','tour-warn-btn','tour-overall-time','tour-question-time','tour-next-btn',
 'ratings-subject','ratings-tour','ratings-search','ratings-mybar',
 'profile-settings-content-language','profile-competitive-slots-list',
 'support-submit','certificates-list','certificate-verify-result','exam-prep-host-root'];
const actions=['practice-pause','practice-submit','practice-review','practice-recommendations',
 'tour-start','tour-next','tour-review','tour-certificate','open-ratings',
 'my-rec-train','my-rec-retry','my-rec-delete','support-submit'];
for(const id of [...globalViews.map(x=>'view-'+x),...stackScreens.map(x=>'courses-'+x),...protectedIds]){
 assert.equal((source.match(new RegExp('id="'+id+'"','g'))||[]).length,1,'missing or duplicate source ID '+id);
}
for(const action of actions)assert(source.includes('data-action="'+action+'"'),'source action lost: '+action);
assert.equal([...source.matchAll(/<section\b[^>]*\bid="[^"]+"[^>]*>/g)].length,35,'named source screen structure changed');
// Two dynamic subject-access sections are intentionally unnamed UI containers.
assert.equal([...source.matchAll(/<section\b[^>]*>/g)].length,37,'including two subject-access subsections');
assert(source.includes('visual/iclub-academy-ux531-b04b08.css'),'new visual layer not linked');
for(const k of ['academy_profile_subtitle','academy_continue_title']){
 assert.equal((i18n.match(new RegExp('\\b'+k+':','g'))||[]).length,3,'missing RU/UZ/EN key '+k);
}
for(const key of ['B04 — Learning','B05 — Tours','B06 — Profile','B07 — existing Exam Prep','B08 — shared controls'])
 assert(css.includes(key),'missing design family '+key);
assert.doesNotMatch(css,/localStorage|supabase\.|fetch\(|\.rpc\(/,'CSS must be side effect-free');
const fixture=source.replace(/<script\b[\s\S]*?<\/script>/gi,'').replace('class="i18n-pending"','');
const types={'.html':'text/html','.css':'text/css','.js':'text/javascript','.png':'image/png',
 '.svg':'image/svg+xml','.woff2':'font/woff2','.jpg':'image/jpeg'};
const server=http.createServer((req,res)=>{
 const raw=decodeURIComponent((req.url||'/').split('?')[0]);
 if(raw==='/fixture'){res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});res.end(fixture);return;}
 const file=path.resolve(root,'.'+raw);
 if(!file.startsWith(root+path.sep)||!fs.existsSync(file)||!fs.statSync(file).isFile()){
  res.writeHead(404);res.end('not found');return;
 }
 res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream'});
 res.end(fs.readFileSync(file));
});
(async()=>{
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 const report=[];
 try{
  for(const width of [320,375,390,430,768,1440]){
   const page=await browser.newPage({viewport:{width,height:width<500?844:900}});
   const errors=[];page.on('pageerror',e=>errors.push(e.message));
   await page.route(/^https?:\/\/(?!127\.0\.0\.1)/,route=>route.abort());
   await page.goto('http://127.0.0.1:'+server.address().port+'/fixture',{waitUntil:'load'});
   await page.evaluate(()=>{
    window.__ux531Show=(state)=>{
     document.querySelectorAll('.view').forEach(el=>{
      const active=el.id==='view-'+state.view;
      el.classList.toggle('is-active',active);el.hidden=!active;
     });
     document.querySelectorAll('#courses-stack > .stack-screen').forEach(el=>{
      const active=state.view==='courses'&&el.id==='courses-'+state.part;
      el.classList.toggle('is-active',active);el.hidden=!active;
      el.setAttribute('aria-hidden',String(!active));
     });
     document.querySelectorAll('#view-profile .profile-screen').forEach(el=>{
      const active=el.id==='profile-'+(state.profile||'main');el.classList.toggle('is-active',active);el.hidden=!active;
     });
     const bar=document.getElementById('topbar');
     bar.style.display=['splash','registration'].includes(state.view)?'none':'grid';
     document.getElementById('tabbar').style.display=
       ['home','courses','ratings','profile'].includes(state.view)?'grid':'none';
    };
   });
   const states=[
    ...globalViews.filter(v=>!['splash','registration','courses'].includes(v)).map(view=>({view})),
    ...stackScreens.map(part=>({view:'courses',part})),
    ...['plan','subject-access','settings'].map(profile=>({view:'profile',profile}))
   ];
   for(const state of states){
    await page.evaluate(state=>window.__ux531Show(state),state);
    const m=await page.evaluate(state=>{
     const el=document.getElementById(state.view==='courses'?'courses-'+state.part:'view-'+state.view);
     const style=getComputedStyle(el),bounds=el.getBoundingClientRect();
     const child=state.view==='profile'&&state.profile?
       document.getElementById('profile-'+state.profile):null;
     const childVisible=child?getComputedStyle(child).display!=='none':true;
     const sheet=[...document.styleSheets].find(s=>(s.href||'').includes('iclub-academy-ux531-b04b08.css'));
     let rules=0;try{rules=sheet?.cssRules?.length||0}catch{}
     return{id:el.id,display:style.display,childVisible,width:bounds.width,
      documentWidth:document.documentElement.scrollWidth,viewport:innerWidth,rules};
    },state);
    assert(m.display!=='none'&&m.width>0&&m.childVisible,'screen invisible '+JSON.stringify({width,state,m}));
    assert(m.rules>=50,'Academy CSS failed to load/parse '+JSON.stringify({width,m}));
    assert(m.documentWidth<=m.viewport+2,'root horizontal overflow '+JSON.stringify({width,m}));
    if(width===390&&['view-ratings','view-profile','view-notifications','view-support',
      'view-certificates','courses-practice-start','courses-practice-quiz',
      'courses-practice-result','courses-tours','courses-tour-quiz',
      'courses-tour-result','courses-books','courses-subject-hub'].includes(m.id)){
     const folder=path.join(root,'ux531-academy-all-screens');
     fs.mkdirSync(folder,{recursive:true});
     await page.screenshot({path:path.join(folder,m.id+(state.profile?'-'+state.profile:'')+'.png'),fullPage:false});
    }
   }

   // Source CSS + real Home card DOM classes; placeholder content is explicitly
   // synthetic for owner visual review. Not a real learner or competition state.
   if(width===390||width===1440) {
    await page.evaluate(()=>{
     window.__ux531Show({view:'home'});
     document.getElementById('home-competitive-list').innerHTML =
      '<div class="home-competitive-card" data-subject="mathematics">'+
      '<div class="home-competitive-badge">ПРИМЕР · ТУР</div>'+
      '<div class="home-competitive-hero"><div class="home-competitive-hero-img"></div></div>'+
      '<div class="home-competitive-body"><div class="home-competitive-title">Mathematics</div>'+
      '<div class="home-competitive-note">Соревновательный предмет</div>'+
      '<div class="home-competitive-meta"><span class="home-competitive-module">Тур · пример</span></div>'+
      '<div class="home-progress"><div class="home-progress-fill" style="width:34%"></div></div></div>'+
      '<button class="btn primary home-competitive-btn" type="button">Открыть предмет</button></div>';
     document.getElementById('home-competitive-list').insertAdjacentHTML('beforeend',
      '<div class="home-competitive-card" data-subject="chemistry">'+
      '<div class="home-competitive-badge">ПРИМЕР · ТУР</div>'+
      '<div class="home-competitive-body"><div class="home-competitive-title">Chemistry</div>'+
      '<div class="home-competitive-note">Соревновательный предмет</div>'+
      '<div class="home-competitive-meta"><span class="home-competitive-module">Тур · пример</span></div>'+
      '<div class="home-progress"><div class="home-progress-fill" style="width:18%"></div></div></div>'+
      '<button class="btn primary home-competitive-btn" type="button">Открыть предмет</button></div>');
     const pinned=title=>'<button class="home-pinned-tile" type="button">'+
      '<span class="home-pinned-top">ЗАКРЕПЛЁН · ПРИМЕР</span>'+
      '<strong class="home-pinned-title">'+title+'</strong>'+
      '<span class="home-pinned-bottom"><span class="home-pinned-meta">Учебный предмет</span>'+
      '<span class="home-pinned-open">Открыть ›</span></span></button>';
     document.getElementById('home-study-list').innerHTML=pinned('Biology')+pinned('Computer Science');
    });
    const palettes=await page.evaluate(()=>{
      const comp=document.getElementById('home-competitive-list');
      return{
        competitive:[...comp.querySelectorAll('.home-competitive-card')].map(card=>getComputedStyle(card).backgroundImage),
        competitiveScrollable:comp.scrollWidth>comp.clientWidth+1,
        competitiveLayout:getComputedStyle(comp).display,
        pinned:getComputedStyle(document.querySelector('#view-home .home-pinned-tile')).backgroundImage
      };
    });
    assert(palettes.competitive.length===2&&palettes.competitive.every(x=>x===palettes.competitive[0]),
      'Both swipeable Competitive cards must have exactly the same deep-blue palette');
    assert(palettes.competitive[0].includes('rgb(23, 74, 171)')&&
      palettes.pinned.includes('rgb(86, 137, 210)')&&
      palettes.competitiveLayout==='flex'&&(width!==390||palettes.competitiveScrollable),
      'Both families swipe on phones; only pinned uses the lighter blue '+JSON.stringify(palettes));
    const folder=path.join(root,'ux531-academy-all-screens');
    fs.mkdirSync(folder,{recursive:true});
    await page.screenshot({path:path.join(folder,'home-competitive-and-pinned-blue-'+width+'.png'),fullPage:true});
    if(width===390){
      await page.evaluate(()=>{
        const comp=document.getElementById('home-competitive-list');
        comp.scrollLeft=comp.scrollWidth;
      });
      await page.waitForTimeout(180);
      const second=await page.evaluate(()=>{
        const comp=document.getElementById('home-competitive-list');
        return{left:comp.scrollLeft,colors:[...comp.children].map(c=>getComputedStyle(c).backgroundImage)};
      });
      assert(second.left>10&&second.colors.every(c=>c===palettes.competitive[0]),
        'Swipe to second Competitive card must preserve its identical color: '+JSON.stringify(second));
      await page.screenshot({path:path.join(folder,'home-competitive-second-swipe-same-blue-390.png'),fullPage:true});
    }
   }
   await page.evaluate(()=>window.__ux531Show({view:'profile'}));
   const profile=await page.evaluate(()=>{
    const h=document.querySelector('#view-profile .academy-profile-zone');
    return {height:h.getBoundingClientRect().height,
     gradient:getComputedStyle(h).backgroundImage,
     text:h.querySelector('h1')?.textContent?.trim()};
   });
   assert(profile.height>=156&&profile.gradient.includes('linear-gradient'),
     'Profile blue zone mismatch '+JSON.stringify({width,profile}));
   assert.equal(profile.text,'Профиль');
   // Owner's phone review: simulate the long loading label during measurement
   // even though the shipped placeholder is intentionally a compact ellipsis.
   await page.evaluate(()=>{document.getElementById('profile-metric-tours').textContent='Загружаем…';});
   const metricLayout=await page.evaluate(()=>{
     const cards=[...document.querySelectorAll('#profile-main .profile-stat, #profile-main .overview-card')];
     const rows=cards.map(card=>{
       const content=card.querySelector('.profile-stat-value, .overview-value');
       const cb=card.getBoundingClientRect(),tb=content.getBoundingClientRect();
       return {cardWidth:cb.width,textWidth:content.clientWidth,
         scrollWidth:content.scrollWidth,contentRight:tb.right,cardRight:cb.right,
         font:getComputedStyle(content).fontFamily};
     });
     const overview=[...document.querySelectorAll('#profile-main .overview-card')]
       .map(c=>({top:c.getBoundingClientRect().top,bottom:c.getBoundingClientRect().bottom}));
     return {rows,overview};
   });
   assert.equal(metricLayout.rows.length,5,'three metrics + two profile overview cards');
   assert(metricLayout.rows.every(c=>c.scrollWidth<=c.textWidth+2 &&
      c.contentRight<=c.cardRight+2),'profile text must remain inside its card at '+width+
      ': '+JSON.stringify(metricLayout.rows));
   assert(metricLayout.rows.every(c=>/ui-sans-serif|system-ui/i.test(c.font)),
      'Profile must inherit iClub system typography at '+width);
   assert(Math.abs(metricLayout.overview[0].bottom-metricLayout.overview[1].bottom)<=2,
      'Profile overview cards must align at '+width);
   await page.evaluate(()=>{
     document.getElementById('profile-metric-tours').textContent='…';
     window.__ux531Show({view:'ratings'});
   });
   const rating=await page.evaluate(()=>{
    const h=document.querySelector('#view-ratings .lb-header');
    return {height:h.getBoundingClientRect().height,
      actions:[...h.querySelectorAll('button')].map(b=>({
       width:b.getBoundingClientRect().width,height:b.getBoundingClientRect().height
      }))};
   });
   assert(rating.height>=156,'Ratings blue zone mismatch '+JSON.stringify({width,rating}));
   assert(rating.actions.every(x=>x.width>=38&&x.height>=38),
     'Ratings back/search/info inaccessible '+JSON.stringify({width,rating}));
   assert.equal(errors.length,0,'Unexpected browser exceptions '+JSON.stringify({width,errors}));
   report.push({width,statesChecked:states.length,profileZone:profile.height,
     ratingsZone:rating.height,failures:0});
   console.log('PASS UX531 '+width+'px: '+states.length+' source-screen visual states; no overflow.');
   await page.close();
  }
  const output=path.join(root,'ux531-academy-all-screens');
  fs.mkdirSync(output,{recursive:true});
  fs.writeFileSync(path.join(output,'qa-summary.json'),JSON.stringify({
   totalGlobalViews:globalViews.length,totalCoursesScreens:stackScreens.length,
   report,note:'DOM/CSS structural fixture; authenticated Work staging still required'
  },null,2));
 }finally{
  await browser.close();
  await new Promise(resolve=>server.close(resolve));
 }
})().catch(e=>{console.error('UX531 all-screen regression failed:',e.stack||e);process.exitCode=1;});
