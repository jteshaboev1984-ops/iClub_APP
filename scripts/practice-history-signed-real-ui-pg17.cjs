#!/usr/bin/env node
'use strict';
// #574 · Real signed browser -> PostgREST -> disposable PostgreSQL17 ->
// actual Practice Season2 History/Tab UI modules (three languages).
// NOT production/WebApp full login/navigation; only synthetic users/data.
// No question texts, keys, JWTs or student identities are emitted.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {chromium}=require('playwright');
const ROOT=path.resolve(__dirname,'..');
assert(process.env.CI==='true'&&
  process.env.PRACTICE_S2_REAL_UI_ISOLATED==='true'&&
  process.env.PGHOST==='127.0.0.1'&&
  process.env.PGDATABASE==='postgres',
  'Refused: local disposable CI PG17 required');
const secret=process.env.PRACTICE_SEASON2_JWT_SECRET;
assert(secret?.length>=48,'ephemeral signing secret absent');
const enc=x=>Buffer.from(JSON.stringify(x)).toString('base64url');
const makeToken=(user,expiresIn=300)=>{
  const now=Math.floor(Date.now()/1000);
  const unsigned=enc({alg:'HS256',typ:'JWT'})+'.'+
    enc({role:'authenticated',sub:user,aud:'authenticated',iat:now,exp:now+expiresIn});
  return unsigned+'.'+crypto.createHmac('sha256',secret).update(unsigned).digest('base64url');
};
const OWNER='11111111-1111-4111-8111-111111111111';
const OTHER='22222222-2222-4222-8222-222222222222';
const html=fs.readFileSync(path.join(ROOT,'index.html'),'utf8');
const from=html.indexOf('<section id="courses-practice-start"');
const to=html.indexOf('<!-- Practice Quiz -->',from);
assert(from>=0&&to>from,'actual Practice HTML section not found');
const actualPractice=html.slice(from,to);
const api=async(page,subject,token)=>page.evaluate(async ({subject,token})=>{
  const response=await fetch('/rpc/get_practice_season2_progress_safe_v1',{
    method:'POST',headers:{'Content-Type':'application/json',
      ...(token?{Authorization:'Bearer '+token}:{})},
    body:JSON.stringify({p_subject_key:subject})
  });
  const content=await response.json().catch(()=>null);
  return {ok:response.ok,status:response.status,data:content};
},{subject,token});
(async()=>{
  const browser=await chromium.launch({headless:true,args:['--no-sandbox']});
  try{
    for(const lang of ['ru','uz','en'])for(const width of [320,375,430,1440]){
      const context=await browser.newContext({viewport:{width,height:850}});
      const page=await context.newPage();
      try{
        // Establish the genuine PostgREST origin, not a mocked browser fetch.
        const response=await page.goto('http://127.0.0.1:3000/',{waitUntil:'domcontentloaded'});
        assert.ok(response,'real localhost HTTP origin missing');
        await page.setContent('<!doctype html><html lang="'+lang+'><head><meta charset="utf-8"></head>'+
          '<body class="iclub-visual-v3"><main>'+actualPractice+
          '<section id="courses-practice-history" class="stack-screen">'+
          '<div id="practice-history-title"></div><div id="practice-history-subtitle"></div>'+
          '<div id="practice-history-content"></div></section></main></body></html>');
        await page.evaluate(locale=>{ document.documentElement.lang=locale; },lang);
        await page.addStyleTag({content:
          'html,body{margin:0;font:14px system-ui;background:#f5f8fe;color:#142b50}'+
          '*,*::before,*::after{box-sizing:border-box}.stack-screen[hidden]{display:none!important}'+
          '.stack-screen:not(.is-active){display:none}.stack-screen.is-active{display:block} main{width:100%}'});
        await page.addStyleTag({path:path.join(ROOT,'practice-results-tabs.css')});
        await page.addStyleTag({path:path.join(ROOT,'visual/iclub-academy-ux531-b04b08.css')});
        await page.addScriptTag({path:path.join(ROOT,'practice-history-screen.js')});
        await page.addScriptTag({path:path.join(ROOT,'practice-results-tabs.js')});
        await page.evaluate(()=>{
          const start=document.getElementById('courses-practice-start');
          start.classList.add('is-active');
          window.addEventListener('iclub-practice-open-history',()=>{
            start.classList.remove('is-active');
            document.getElementById('courses-practice-history').classList.add('is-active');
            window.iClubPracticeHistoryScreenV1.render();
          });
        });
        const anon=await api(page,'mathematics',null);
        assert(!anon.ok,'anonymous History RPC improperly accepted');
        const expired=await api(page,'mathematics',makeToken(OWNER,-300));
        assert(!expired.ok,'expired History RPC accepted');
        const owned=await api(page,'mathematics',makeToken(OWNER));
        assert(owned.ok&&owned.data?.ok===true,'owner real signed S2 History RPC failed');
        assert.equal(owned.data.period_active,true,'owned published S2 not active');
        assert.equal(owned.data.subject_key,'mathematics','wrong subject returned');
        assert.equal(owned.data.main.attempts_count,2,'wrong owner S2 attempt count');
        assert.equal(owned.data.main.archived_attempts_count,1,'old S1 attempt missing');
        const other=await api(page,'mathematics',makeToken(OTHER));
        assert(other.ok,'other account signed read denied');
        assert.equal(other.data.main.attempts_count,1,'other owner history leaked');
        const chemistry=await api(page,'chemistry',makeToken(OWNER));
        assert(chemistry.ok,'signed other subject read denied');
        assert.equal(chemistry.data.period_active,false,'Chemistry S2 wrongly inherited Math Tour cutoff');
        await page.evaluate(payload=>{
          window.iClubPracticeSeason2HistoryV1.render(payload,'mathematics',
            document.documentElement.lang);
        },owned.data);
        const entry=page.locator('#courses-practice-start .iclub-practice-history-entry');
        assert.equal(await entry.count(),1,'Practice lacks unique standalone History entry');
        assert.equal(await page.locator('#courses-practice-start .iclub-s2-history-block').count(),0,
          'old embedded History duplicated');
        await entry.click();
        const root=page.locator('#courses-practice-history .iclub-ph-root');
        assert.equal(await root.count(),1,'actual History screen not rendered');
        assert.equal(await root.getAttribute('data-history-season'),'2');
        assert.equal(await root.locator('.iclub-ph-current-badge').textContent(),
          {ru:'Текущий сезон',uz:'Joriy mavsum',en:'Current season'}[lang]);
        assert.equal(await root.locator('.iclub-ph-results .iclub-ph-results-label').count(),1);
        await root.locator('.iclub-ph-arrow').last().click();
        assert.equal(await root.getAttribute('data-history-season'),'1',
          'historical Season1 vanished after S2 cutover');
        assert.equal(await root.locator('.iclub-ph-current-badge').isVisible(),false,
          'archive presented as current');
        await root.locator('#iclub-ph-tab-topics').click();
        assert.equal(await root.getAttribute('data-history-type'),'topics');
        const leak=await page.evaluate(()=>document.documentElement.scrollWidth-innerWidth);
        assert(leak<=1,'History horizontal overflow at '+lang+'/'+width);
        // A fresh query for another subject must not carry previous session context.
        await page.evaluate(payload=>{
          window.iClubPracticeHistoryScreenV1.setData(payload,'chemistry',
            document.documentElement.lang);
        },chemistry.data);
        assert.equal(await page.locator('#courses-practice-history .iclub-ph-root').count(),1,
          'independently available S1 Chemistry history not rendered');
        assert.equal(await root.getAttribute('data-history-season'),'1',
          'other subject incorrectly shows S2');
        assert.equal(await root.locator('.iclub-ph-current-badge').textContent(),
          {ru:'Текущая практика',uz:'Joriy amaliyot',en:'Current practice'}[lang]);
      }finally{await context.close();}
    }
    console.log('PRACTICE_SIGNED_REAL_UI_HISTORY_PG17_PASS: actual source DOM/UI, signed learner PostgREST, PG17 owned S2/S1/other subject; RU/UZ/EN x 4 viewports');
  }finally{await browser.close();}
})().catch(error=>{
  // No bearer, response bodies or private data are ever printed.
  console.error('PRACTICE_SIGNED_REAL_UI_HISTORY_FAILED:',String(error.message||error));
  process.exit(1);
});
