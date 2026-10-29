#!/usr/bin/env node
'use strict';
// Genuine Chromium DOM and iClub Economics screen; isolated synthetic server.
// NOT an authenticated Supabase / production browser E2E test.
const assert=require('node:assert/strict');
const {chromium}=require('playwright');
const path=require('node:path');
const file=x=>path.resolve(x);
const langs=['ru','uz','en'], widths=[390,1280];
async function scenario(browser,lang,width,mode){
  const page=await browser.newPage({viewport:{width,height:820}}),errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  // Use an intercepted same-origin URL: about:blank has opaque storage and
  // would falsely report that tab-local recovery failed.
  await page.route(/^https?:\/\//,route=>route.abort());
  // Playwright resolves the newest matching route first. Keep localhost
  // later than the fallback network-abort route.
  await page.route('http://localhost:13741/',route=>route.fulfill({
    contentType:'text/html',
    body:'<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><main id="host"></main></body></html>'
  }));
  try {
    await page.goto('http://localhost:13741/');
    await page.addStyleTag({path:file('exam-prep/exam-prep-host.css')});
    await page.addStyleTag({path:file('exam-prep/exam-prep-economics-native.css')});
    await page.evaluate(mode=>{
      const s=window.__econ={mode,sends:0,reads:0,started:false,saved:{},finish:false,
        paper:mode==='paper30'?'P3':'P1'};
      const id='11111111-1111-4111-8111-111111111111';
      window.sb={rpc:async(name,args)=>{
        const ok=data=>({data:{ok:true,...data}});
        if(name==='iclub_exam_native_mcq_history_v1'){
          const baseline=s.mode==='paper30'?[{session_id:'22222222-2222-4222-8222-222222222222',
            paper_code:'P1',session_kind:'diagnostic',status:'finalized',
            answered:12,score:8,total_items:12}]:[];
          if(s.started)baseline.push({session_id:id,paper_code:s.paper,
            session_kind:s.mode==='paper30'?'paper':'diagnostic',
            status:s.finish?'finalized':'active',answered:Object.keys(s.saved).length,
            total_items:s.mode==='paper30'?30:12});
          return ok({sessions:baseline});
        }
        if(name==='iclub_exam_native_economics_profile_v1')return ok({profile:null});
        if(name==='iclub_exam_written_available_v1')return ok({available:false});
        if(name==='iclub_econ_written_beta_status_v1')return ok({eligible:false,joined:false});
        if(name==='iclub_exam_native_mcq_start_diagnostic_v1'||
           name==='iclub_exam_native_mcq_start_v1'){
          if(s.mode==='paper30'&&name==='iclub_exam_native_mcq_start_v1'&&args.p_paper_code!=='P3')
            throw Error('Wrong paper selected');
          s.started=true;return ok({session_id:id});
        }
        if(name==='iclub_exam_native_mcq_get_v1'){
          s.reads++;
          if(s.mode==='revoked'&&s.sends>0)return {data:{ok:false,code:'not_authorized'}};
          if(args.p_session_id!==id)return ok({status:'not_found',items:[]});
          return ok({session_id:id,paper_code:s.paper,
            session_kind:s.mode==='paper30'?'paper':'diagnostic',
            status:s.finish?'finalized':'active',score:s.finish?Object.keys(s.saved).length:null,
            deadline_at:new Date(Date.now()+(s.mode==='expired_pending'&&s.sends>0?-3000:1200000)).toISOString(),
            items:Array.from({length:s.mode==='paper30'?30:12},(_,i)=>({order:i+1,question:'Q'+(i+1),options:['A','B','C','D'],
              selected_index:Number.isInteger(s.saved[i+1])?s.saved[i+1]:null,
              answered:Number.isInteger(s.saved[i+1]),
              correct_index:s.finish?1:null}))});
        }
        if(name==='iclub_exam_native_mcq_answer_v1'){
          s.sends++;
          if(['before_commit','revoked','pending_resume','offline_leave','expired_pending'].includes(s.mode)&&s.sends===1)
            return {error:{message:'disconnected'}};
          if(s.mode==='slow'&&s.sends===1)await new Promise(r=>setTimeout(r,90));
          s.saved[args.p_item_order]=s.mode==='conflict'&&s.sends===1?2:args.p_choice;
          if(['lost_ack','conflict'].includes(s.mode)&&s.sends===1)
            return {error:{message:'lost ACK'}};
          return ok({saved:true,selected_index:args.p_choice});
        }
        if(name==='iclub_exam_native_mcq_finish_v1'){s.finish=true;return ok({status:'finalized'});}
        throw Error('Unexpected Economics RPC '+name);
      }};
    },mode);
    await page.addScriptTag({path:file('exam-prep/exam-prep-economics-native.js')});
    await page.evaluate(lang=>{
      window.__app=window.iClubExamPrepHostInternal.economicsNative;
      const root=document.getElementById('host');
      if(!window.__app.mount({root,shell:{program_key:'economics_9708',enabled:true,
        papers:[{code:'P1',assessment_kind:'mcq'},{code:'P3',assessment_kind:'mcq'}]},language:lang}))throw Error('mount refused');
    },lang);
    if(mode==='paper30'){
      await page.waitForSelector('.ep-live-component-entry');
      await page.locator('.ep-live-component-entry').nth(2).click();
      await page.waitForSelector('.ep-component-primary');
      await page.click('.ep-component-primary');
    }else{
      await page.waitForSelector('.ep-component-next button');
      await page.locator('.ep-component-next button').first().click();
    }
    await page.waitForSelector('input[name="ep-native-choice"]');
    await page.check('input[name="ep-native-choice"][value="1"]');
    assert.equal(await page.evaluate(()=>window.__econ.sends),0,'Changing radio must not submit');
    if(mode==='draft'){
      await page.evaluate(()=>{window.__app.unmount();window.__app.mount({
        root:document.getElementById('host'),shell:{program_key:'economics_9708',enabled:true,
        papers:[{code:'P1',assessment_kind:'mcq'},{code:'P3',assessment_kind:'mcq'}]},language:document.documentElement.lang||'en'});});
      await page.waitForSelector('.ep-component-next button');
      await page.locator('.ep-component-next button').first().click();
      await page.waitForSelector('input[name="ep-native-choice"][value="1"]');
      assert(await page.locator('input[name="ep-native-choice"][value="1"]').isChecked(),'Draft lost on remount');
      assert.equal(await page.evaluate(()=>window.__econ.sends),0,'Draft must never auto-submit');
    }
    if(mode==='unsubmitted_finish'){
      await page.evaluate(()=>window.confirm=()=>{throw Error('Unsent choice must block finish');});
      await page.locator('.ep-live-actions button').filter({hasText:/^(Finish exam|Завершить экзамен|Imtihonni yakunlash)$/}).click();
      assert.equal(await page.evaluate(()=>window.__econ.finish),false,'Unsent draft must not finish exam');
      assert.equal(await page.locator('.ep-native-unsubmitted[role="alert"]').count(),1,
        'The learner must be told to submit their selected answer');
    }
    if(mode==='slow'){
      await page.evaluate(()=>{
        const b=document.querySelector('[data-ep-native-submit]');
        b.click();b.click();
      });
    }else await page.click('[data-ep-native-submit]');
    if(['before_commit','pending_resume','revoked','offline_leave','expired_pending'].includes(mode)){
      await page.waitForSelector('.ep-native-save-recovery button');
      assert.equal(await page.evaluate(()=>window.__econ.sends),1,'Uncertain request auto retried');
      if(mode==='pending_resume'||mode==='expired_pending'){
        await page.evaluate(lang=>{window.__app.unmount();window.__app.mount({
          root:document.getElementById('host'),shell:{program_key:'economics_9708',enabled:true,
          papers:[{code:'P1',assessment_kind:'mcq'},{code:'P3',assessment_kind:'mcq'}]},language:lang});},lang);
        await page.waitForSelector('.ep-component-next button');
        await page.locator('.ep-component-next button').first().click();
        await page.waitForSelector('.ep-native-save-recovery button');
        assert(await page.locator('input[name="ep-native-choice"][value="1"]').isChecked(),'Pending choice lost on remount');
        assert.equal(await page.evaluate(()=>window.__econ.sends),1,'Remount must not auto-resend');
        if(mode==='pending_resume')
          await page.locator('.ep-native-save-recovery button').first().click();
        else assert.equal(await page.evaluate(()=>window.__econ.finish),false,
          'Expired attempt must not finalize an uncertain answer on remount');
      }
      if(mode==='revoked'||mode==='offline_leave'||mode==='expired_pending'){
        await page.locator('.ep-native-save-recovery button').last().click();
        await page.waitForSelector('.ep-component-next button');
        assert.equal(await page.evaluate(()=>window.__econ.sends),1,'Exit must not send an answer');
        assert(await page.evaluate(()=>sessionStorage.getItem(
          'iclub_ep_economics_choice_v1:11111111-1111-4111-8111-111111111111:1')),
          'Exit lost unconfirmed tab choice');
      }else{
        await page.locator('.ep-native-save-recovery button').nth(1).click();
      }
    }
    if(mode==='conflict'){
      await page.waitForSelector('.ep-native-choice-feedback');
      assert(await page.locator('input[name="ep-native-choice"][value="2"]').isChecked(),
        'Server choice must be displayed after a conflict');
      assert.equal(await page.evaluate(()=>window.__econ.sends),1,'Conflicting answer auto overwritten');
      await page.check('input[name="ep-native-choice"][value="1"]');
      await page.click('[data-ep-native-submit]');
    }
    if(!['revoked','offline_leave','expired_pending'].includes(mode))
      await page.waitForFunction(()=>document.body.textContent.includes('Q2'));
    if(mode==='paper30'){
      assert(await page.locator('.ep-live-meta').allTextContents().then(xs=>xs.some(t=>t.includes('/ 30'))),
        'P3 30-question progress missing');
      assert.equal(await page.evaluate(()=>window.__econ.saved[1]),1,
        'P3 answer was not committed in the synthetic server');
    }
    if(mode==='revised'){
      await page.locator('.ep-live-actions button').filter({hasText:/^(Previous|Предыдущий|Oldingi)$/}).click();
      await page.check('input[name="ep-native-choice"][value="2"]');
      assert.equal(await page.evaluate(()=>window.__econ.sends),1,'A revised choice must not auto-save');
      await page.locator('.ep-live-actions button').filter({hasText:/^(Finish exam|Завершить экзамен|Imtihonni yakunlash)$/}).click();
      assert.equal(await page.evaluate(()=>window.__econ.finish),false,'Unsent revision must block finish');
      await page.click('[data-ep-native-submit]');
      await page.waitForFunction(()=>document.body.textContent.includes('Q2'));
      assert.equal(await page.evaluate(()=>window.__econ.saved[1]),2,'Server must receive revised answer');
    }
    const {sends,reads}=await page.evaluate(()=>window.__econ);
    assert.equal(sends,['before_commit','pending_resume','revised','conflict'].includes(mode)?2:1,
      'unexpected duplicate writes');
    if(mode==='lost_ack'||mode==='before_commit')assert(reads>=2,'Missing server reconciliation');
    assert.equal(errors.length,0,errors.join('; '));
    const x=await page.evaluate(()=>({overflow:document.documentElement.scrollWidth>innerWidth+3}));
    assert.equal(x.overflow,false,'Horizontal overflow on '+width);
  }finally {await page.close();}
}
(async()=>{
 const browser=await chromium.launch({headless:true});
 try{
   let count=0;
   for(const lang of langs)for(const width of widths)for(const mode of ['normal','lost_ack','before_commit','slow','draft','unsubmitted_finish','revised',
     'conflict','revoked','offline_leave','pending_resume','expired_pending','paper30']){
     await scenario(browser,lang,width,mode);count++;
   }
   console.log('PASS Economics native Chromium MCQ submit/recovery',count,'RU/UZ/EN scenarios');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
