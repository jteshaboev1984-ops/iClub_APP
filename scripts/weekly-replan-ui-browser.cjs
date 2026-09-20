'use strict';
// A focused student scenario: ONE visible review CTA on a verified weekly goal,
// explicit confirmation, ONE server write, preserved result and safe failure.
// No network or production database access. Real browser and real JS assets.
const assert = require('node:assert/strict');
const { chromium } = require('playwright');
const path = require('node:path');
const OLD = '11111111-1111-4111-8111-111111111111';
const NEW = '22222222-2222-4222-8222-222222222222';
const SESSION = '33333333-3333-4333-8333-333333333333';
(async()=>{
  const browser=await chromium.launch({headless:true});
  try {
    for(const language of ['ru','uz','en']) {
      for(const mode of ['off','success','stale','active','uncertain','unverified']) {
        const page=await browser.newPage({viewport:{width:390,height:780}});
        const errors=[];
        page.on('pageerror',e=>errors.push(e.message));
        await page.route(/^https?:\/\//,route=>route.abort());
        await page.setContent(`<!doctype html><html lang="${language}"><body>
          <div id="exam-prep-host-root" aria-hidden="false"><div class="ep-live-card">
            <div class="ep-live-head"><strong>P1 · Weekly plan</strong><button data-ep-live-dashboard>Overview</button></div>
            <section class="ep-pux-week" ${mode==='unverified'?'':'data-ep-pux-primary-goals="verified"'}></section>
            <button data-ep-live-plan-item="1">Start</button>
          </div></div></body></html>`);
        await page.evaluate(([flag,scenario,oldPlan,newPlan,session])=>{
          window.iClubExamPrepWeeklyFlowEnabled=flag;
          window.__review={calls:[],plan:oldPlan,dashboard:0};
          window.i18n={getLang:()=>document.documentElement.lang};
          window.iClubExamPrepHostInternal={
            lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'},
            api:{weeklyPlan:async()=>{
              const s=window.__review;
              s.calls.push({name:'weeklyPlan'});
              if(scenario==='stale'&&s.calls.filter(x=>x.name==='weeklyPlan').length>1)
                return {ok:true,data:{plan_id:newPlan}};
              return {ok:true,data:{plan_id:s.plan}};
            }}
          };
          document.querySelector('[data-ep-live-dashboard]').addEventListener('click',()=>window.__review.dashboard++);
          window.sb={rpc:async(name,args)=>{
            const s=window.__review;
            s.calls.push({name,args});
            if(name==='get_exam_prep_active_plan_session_safe_v1') return {data:scenario==='active'
              ? {status:'resume',session_id:session,component_code:'P1'}
              : {status:'none',component_code:'P1'},error:null};
            if(name==='request_exam_prep_explicit_weekly_replan_safe_v1') {
              if(scenario==='uncertain') throw new Error('lost acknowledgement');
              s.plan=newPlan;
              return {data:{status:'replanned',plan_id:newPlan,previous_plan_id:oldPlan,
                component_code:'P1',goals_preserved:true},error:null};
            }
            throw new Error(`Unexpected RPC: ${name}`);
          }};
        },[mode!=='off',mode,OLD,NEW,SESSION]);
        await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-weekly-flow-adapter.js')});
        await page.addScriptTag({path:path.resolve('exam-prep/exam-prep-weekly-replan-ui.js')});
        const review=page.locator('.ep-weekly-review-actions button').first();
        if(mode==='off'||mode==='unverified') {
          assert.equal(await page.locator('.ep-weekly-review-actions').count(),0,`${language}/${mode}: unexpected review`);
          assert.equal((await page.evaluate(()=>window.__review.calls)).length,0,`${language}/${mode}: network operation`);
        } else {
          await review.waitFor();
          assert.equal(await page.locator('.ep-weekly-review-actions').count(),1,`${language}/${mode}: duplicate CTA`);
          await review.click();
          if(mode==='stale') {
            await page.getByText({ru:'План изменился в другой вкладке.',uz:'Reja boshqa oynada o‘zgargan.',en:'The plan changed in another tab.'}[language],{exact:false}).waitFor();
          } else {
            await page.locator('.ep-weekly-review-actions button').filter({hasText:{ru:'Да, пересмотреть',uz:'Ha, qayta ko‘rish',en:'Yes, review'}[language]}).waitFor();
            assert.equal((await page.evaluate(()=>window.__review.calls)).filter(x=>x.name==='request_exam_prep_explicit_weekly_replan_safe_v1').length,0,
              `${language}/${mode}: sent write before explicit confirmation`);
            await page.locator('.ep-weekly-review-actions button').filter({hasText:{ru:'Да, пересмотреть',uz:'Ha, qayta ko‘rish',en:'Yes, review'}[language]}).click();
            const expected=mode==='success'
              ? {ru:'План обновлён.',uz:'Reja yangilandi.',en:'Plan updated.'}[language]
              : mode==='active'
                ? {ru:'Сначала завершите',uz:'Avval boshlangan',en:'Finish your current'}[language]
                : {ru:'Не удалось подтвердить результат.',uz:'Natijani tasdiqlab bo‘lmadi.',en:'The outcome could not be confirmed.'}[language];
            await page.getByText(expected,{exact:false}).waitFor();
            const requests=(await page.evaluate(()=>window.__review.calls))
              .filter(x=>x.name==='request_exam_prep_explicit_weekly_replan_safe_v1');
            assert.equal(requests.length,mode==='active'?0:1,`${language}/${mode}: wrong mutation count`);
            if(requests.length) {
              assert.equal(requests[0].args.p_expected_plan_id,OLD);
              assert.equal(requests[0].args.p_component_code,'P1');
              assert.equal(requests[0].args.p_confirmed,true);
              assert.equal(requests[0].args.p_reason_code,'manual_review');
              assert.ok(requests[0].args.p_request_key.length>=16);
            }
            if(mode==='success') assert.equal(await page.locator('[data-ep-live-plan-item]').isDisabled(),true,
              'Stale original task remains clickable after plan change');
          }
          const s=await page.evaluate(()=>window.__review);
          assert.equal(s.calls.filter(x=>x.name==='request_exam_prep_explicit_weekly_replan_safe_v1').length,
            mode==='success'||mode==='uncertain'?1:0,`${language}/${mode}: unexpected replay`);
          await page.locator('.ep-weekly-review-actions button').filter({hasText:{ru:'К обзору',uz:'Umumiy ko‘rinish',en:'Overview'}[language]}).click();
          assert.equal(await page.evaluate(()=>window.__review.dashboard),1);
        }
        assert.deepEqual(errors,[],`${language}/${mode}: browser errors`);
        console.log(`PASS ${language}/${mode}: explicit student review, no duplicate write`);
        await page.close();
      }
    }
    console.log('EXPLICIT WEEKLY REVIEW UI GREEN: 18 isolated real Chromium scenarios, no live data');
  } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exitCode=1;});
