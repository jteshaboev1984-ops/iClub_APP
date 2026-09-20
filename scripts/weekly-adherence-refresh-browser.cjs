'use strict';
// Real DOM/adapter in isolated Chromium. Synthetic RPC only, all HTTP blocked.
// A finalized learning session must recheck the factual verdict without a write.
const assert = require('node:assert/strict');
const path = require('node:path');
const { chromium } = require('playwright');
const source = n => path.resolve('exam-prep', n);
const verdict = (component,status,nowDone,total) => ({
  contract_version:'previous_week_adherence_v1', component_code:component,
  active_week_no:1,status,can_alert:status==='missed',
  scheduled_goals:total,completed_by_deadline:status==='completed_on_time'?total:0,
  completed_now:nowDone,deferred_goals:0,week_ended_at:'2026-09-19T08:00:00Z'
});
(async()=>{
  const browser=await chromium.launch({headless:true});
  let cases=0;
  try {
    for(const lang of ['ru','uz','en']) for(const width of [390,1280]) {
      for(const kind of ['late_completion','switch_component','out_of_order','server_unavailable','revoked']) {
        const page=await browser.newPage({viewport:{width,height:840}});
        const errors=[];
        page.on('pageerror',e=>errors.push(e.message));
        await page.route(/^https?:\/\//,route=>route.abort());
        await page.setContent(`<!doctype html><html lang="${lang}"><body><div id="exam-prep-host-root" aria-hidden="false"><div data-ep-exam-plan-card="true"><button type="button" data-ep-exam-plan-edit="true">Change exam plan</button></div></div></body></html>`);
        await page.addStyleTag({path:source('exam-prep-host.css')});
        await page.evaluate(([language,k])=>{
          window.i18n={getLang:()=>language};
          window.iClubExamPrepProgressUxEnabled=true;
          window.iClubExamPrepWeeklyFlowEnabled=true;
          window.iClubExamPrepHostInternal={lastCapabilities:{coreAccess:true,killSwitch:false,rolloutState:'controlled_beta'}};
          const v=(component,status,done,total)=>({contract_version:'previous_week_adherence_v1',component_code:component,
            active_week_no:1,status,can_alert:status==='missed',scheduled_goals:total,
            completed_by_deadline:status==='completed_on_time'?total:0,completed_now:done,
            week_ended_at:'2026-09-19T08:00:00Z'});
          const t=window.__refreshTest={calls:[],reply:{P1:v('P1','missed',1,2),P5:v('P5','completed_on_time',1,1)},
            hold:false,release:null,offline:false};
          window.sb={rpc:async(name,args)=>{
            if(name!=='get_exam_prep_previous_week_adherence_safe_v1') throw Error('Unexpected mutation '+name);
            t.calls.push(args.p_component_code);
            if(t.offline) throw Error('disconnected');
            const snapshot=structuredClone(t.reply[args.p_component_code]);
            if(t.hold && args.p_component_code==='P1') {
              t.hold=false;
              await new Promise(resolve=>{t.release=resolve;});
            }
            return {data:snapshot,error:null};
          }};
        },[lang,kind]);
        await page.addScriptTag({path:source('exam-prep-weekly-flow-adapter.js')});
        await page.addScriptTag({path:source('exam-prep-weekly-adherence-ui.js')});
        await page.waitForSelector('[data-ep-weekly-adherence-notice]');
        assert.match(await page.locator('[data-ep-weekly-adherence-notice]').innerText(),/P1/);
        if(kind==='out_of_order') {
          await page.evaluate(()=>{
            const t=window.__refreshTest;t.hold=true;
            window.dispatchEvent(new CustomEvent('iclub:exam-prep-session-ended',{detail:{sessionId:'synthetic'}}));
          });
          await page.waitForFunction(()=>Boolean(window.__refreshTest.release));
        }
        await page.evaluate(k=>{
          const t=window.__refreshTest;
          if(k==='late_completion'||k==='out_of_order') {
            t.reply.P1={...t.reply.P1,status:'caught_up',can_alert:false,completed_now:2};
          } else if(k==='switch_component') {
            t.reply.P1={...t.reply.P1,status:'caught_up',can_alert:false,completed_now:2};
            t.reply.P5={...t.reply.P5,status:'missed',can_alert:true,completed_by_deadline:0,completed_now:0};
          } else if(k==='server_unavailable') t.offline=true;
          else if(k==='revoked') window.iClubExamPrepWeeklyFlowEnabled=false;
          window.dispatchEvent(new CustomEvent('iclub:exam-prep-session-ended',{detail:{sessionId:'synthetic'}}));
        },kind);
        if(kind==='switch_component') {
          await page.waitForFunction(()=>document.querySelector('[data-ep-weekly-adherence-notice]')?.innerText.includes('P5'));
          const text=await page.locator('[data-ep-weekly-adherence-notice]').innerText();
          assert.equal(text.includes('P1'),false,'Old P1 warning was not reconciled');
        } else await page.waitForFunction(()=>!document.querySelector('[data-ep-weekly-adherence-notice]'));
        if(kind==='out_of_order') {
          await page.evaluate(()=>window.__refreshTest.release());
          await page.waitForTimeout(120);
          assert.equal(await page.locator('[data-ep-weekly-adherence-notice]').count(),0,
            'Slower stale RPC resurrected already cleared warning');
        }
        assert.equal(await page.locator('[data-ep-exam-plan-edit]').count(),1);
        assert.equal(await page.locator('button').count(),1,'Extra plan editor added');
        const calls=await page.evaluate(()=>window.__refreshTest.calls);
        assert.equal(calls.length,kind==='out_of_order'?6:4,`${lang}/${width}/${kind} expected one read pair per reconcile`);
        assert.deepEqual(errors,[],`${lang}/${width}/${kind} browser errors`);
        cases++;
        await page.close();
      }
    }
    console.log(`GREEN ${cases} synthetic session-finalized refresh journeys: late completion, cross-component, out-of-order, offline, revoked; no writes or duplicate editor.`);
  }finally{await browser.close();}
})().catch(err=>{console.error(err);process.exitCode=1;});
