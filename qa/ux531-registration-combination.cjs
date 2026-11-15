/* UX #531 / B00 accepted registration compatibility. Headless OFFLINE:
   Loads current Academy OS index.html, injected accepted B00 CSS and JS from
   the PINNED registration draft. Uses no Supabase or real account scripts. */
'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs'),path=require('node:path'),http=require('node:http');
const {chromium}=require('playwright');
const root=path.resolve(__dirname,'..');
const src=fs.readFileSync(path.join(root,'index.html'),'utf8');
for(const id of ['reg-language','reg-fullname','reg-region','reg-district','reg-is-school-toggle',
 'reg-school','reg-class','reg-subject-chips','reg-main-subject-1','reg-main-subject-2',
 'reg-additional-subject','reg-nonstudent-subjects','reg-consent','reg-submit']){
 assert(src.includes('id="'+id+'"'),'Registration source field changed unexpectedly: '+id);
}
assert(fs.existsSync(path.join(root,'visual/iclub-registration-b00.css')),'Pinned approved B00 CSS not loaded');
assert(fs.existsSync(path.join(root,'registration-b00-ui.js')),'Pinned approved B00 adapter not loaded');
const fixture=src
 .replace(/<script\b[\s\S]*?<\/script>/gi,'')
 .replace('</head>','<link rel="stylesheet" href="/visual/iclub-registration-b00.css?v=accepted-B00"></head>')
 .replace('</body>','<script src="/registration-b00-ui.js"></script></body>');
const srv=http.createServer((req,res)=>{
 const pathname=(req.url||'/').split('?')[0];
 if(pathname==='/'||pathname==='/fixture'){res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});res.end(fixture);return;}
 const resolved=path.resolve(root,'.'+decodeURIComponent(pathname));
 if(!resolved.startsWith(root+path.sep)||!fs.existsSync(resolved)||!fs.statSync(resolved).isFile()){
  res.writeHead(404);res.end('not found');return;
 }
 res.writeHead(200,{'Content-Type':({'.js':'text/javascript','.css':'text/css','.png':'image/png','.svg':'image/svg+xml'})[path.extname(resolved)]||'application/octet-stream'});
 res.end(fs.readFileSync(resolved));
});
(async()=>{
 await new Promise(r=>srv.listen(0,'127.0.0.1',r));
 const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
 try {
  for(const width of [320,375,390,430,768,1440]){
   const page=await browser.newPage({viewport:{width,height:844}});
   const errors=[];page.on('pageerror',e=>errors.push(e.message));
   await page.route(/^https?:\/\/(?!127\.0\.0\.1)/,route=>route.abort());
   await page.goto('http://127.0.0.1:'+srv.address().port+'/fixture',{waitUntil:'load'});
   await page.evaluate(()=>{
    document.querySelectorAll('.view').forEach(v=>v.classList.remove('is-active'));
    document.getElementById('view-registration').classList.add('is-active');
    const topbar=document.getElementById('topbar');topbar.style.display='grid';
    document.getElementById('tabbar').style.display='none';
   });
   const q=await page.evaluate(()=>{
    const view=document.getElementById('view-registration');
    const stage1=document.getElementById('reg-b00-step-one');
    const stage2=document.getElementById('reg-b00-step-two');
    const fields=[...document.querySelectorAll('#reg-form input, #reg-form select')].map(x=>x.id);
    const css=getComputedStyle(document.querySelector('.reg-b00-progress .reg-b00-progress-track span.is-done'));
    const full=getComputedStyle(document.getElementById('reg-fullname'));
    const card=document.querySelector('.reg-b00-fields-card')||document.querySelector('.reg-b00-step-one');
    const accent=css.backgroundColor;
    const active=document.getElementById('view-home').classList.contains('is-active');
    return{
      isEnhanced:view.classList.contains('reg-b00-enhanced'),
      stage1Visible:stage1&&!stage1.hidden&&getComputedStyle(stage1).display!=='none',
      stage2Hidden:!!stage2?.hidden,
      regFieldCount:fields.length,
      accent,
      cardBackground:getComputedStyle(card).backgroundColor,
      inputRadius:full.borderRadius,
      inputBorder:full.borderColor,
      viewWidth:view.getBoundingClientRect().width,
      rootWidth:document.documentElement.scrollWidth,
      viewport:innerWidth,
      mistakenlyActiveHome:active,
      formCount:document.querySelectorAll('#reg-form').length,
      submitCount:document.querySelectorAll('#reg-submit').length,
      consentCount:document.querySelectorAll('#reg-consent').length
    };
   });
   assert(q.isEnhanced&&q.stage1Visible&&q.stage2Hidden,'accepted two-step registration not intact '+JSON.stringify({width,q}));
   assert(q.formCount===1&&q.submitCount===1&&q.consentCount===1,'original form controls changed '+JSON.stringify(q));
   assert(q.regFieldCount>=9,'missing inputs '+JSON.stringify(q));
   assert(q.rootWidth<=q.viewport+2,'registration overflow '+JSON.stringify({width,q}));
   assert(!q.mistakenlyActiveHome,'global Home leaked onto Registration');
   assert(q.accent==='rgb(47, 111, 214)'||q.accent==='rgb(44, 101, 187)',
    'registration brand accent outside blue family '+JSON.stringify(q));
   assert(q.cardBackground==='rgb(255, 255, 255)','Registration approved card surface changed '+JSON.stringify(q));
   assert(errors.length===0,'Browser JS errors '+errors.join(' / '));
   if(width===390){
     const dir=path.join(root,'ux531-registration-compat-screens');
     fs.mkdirSync(dir,{recursive:true});
     await page.screenshot({path:path.join(dir,'B00_390_step1.png'),fullPage:false});
   }
   console.log('PASS registration '+width+'px; accepted B00 form, single submit/consent, blue/white surface, no overflow');
   await page.close();
  }
 }finally{await browser.close();await new Promise(r=>srv.close(r));}
})().catch(e=>{console.error('B00+AOS combined regression FAIL',e.stack||e);process.exitCode=1;});
