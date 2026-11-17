#!/usr/bin/env node
"use strict";
/**
 * Issue #450 / integration #562: actual Chromium Stage-gates-ON learner UI.
 * Invoked INSIDE the existing positive signed PG17/JWT/PostgREST fixture
 * at the exact point where synthetic P1 is operational Stage6 and P5 Stage4.
 * Only disposable localhost DB; never mocks marks, stage status or auth.
 */
const assert=require("node:assert/strict");
const path=require("node:path");
const {chromium}=require("playwright");
const HOST="http://127.0.0.1:3000";
const translations={
  ru:{title:"Учебные этапы",note:"Письменные Paper не оцениваются."},
  uz:{title:"O‘quv bosqichlari",note:"Yozma Paper baholanmaydi."},
  en:{title:"Learning stages",note:"Written Papers receive no marks."}
};
module.exports=async function runStageOnBrowser(jwt){
  assert(process.env.CI==="true"&&process.env.P1P5_E2E_ISOLATED==="true"&&
    process.env.PGHOST==="127.0.0.1"&&process.env.PGDATABASE==="postgres"&&
    process.env.PGUSER==="postgres"&&typeof jwt==="string"&&jwt.length>80,
    "REFUSED: Stage-ON browser requires signed disposable GitHub PG17");
  const browser=await chromium.launch({headless:true});
  try {
    for(const [lang,width] of [["ru",390],["uz",375],["en",1280]]){
      const page=await browser.newPage({viewport:{width,height:850},timezoneId:"Asia/Tashkent"});
      const errors=[];page.on("pageerror",e=>errors.push(e.message));
      try {
        await page.route(HOST+"/",route=>route.fulfill({status:200,contentType:"text/html",
          body:'<!doctype html><html lang="'+lang+'"><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><section id="courses-subject-hub"><div id="subject-hub-exam-prep-entry" hidden aria-hidden="true"><span id="subject-hub-exam-prep-title"></span><span id="subject-hub-exam-prep-sub"></span></div><div id="exam-prep-host-root" hidden aria-hidden="true"></div></section></body></html>'
        }));
        await page.goto(HOST+"/");
        await page.addStyleTag({path:path.resolve("exam-prep/exam-prep-host.css")});
        await page.evaluate(({jwt,lang})=>{
          delete window.iClubExamPrepHybridPaperS4Enabled;
          window.__stageOnTrace=[];
          window.sb={rpc:async(name,args={})=>{
            const res=await fetch("/rpc/"+name,{method:"POST",headers:{
              "Content-Type":"application/json","Authorization":"Bearer "+jwt
            },body:JSON.stringify(args)});
            let data=null;try{data=await res.json()}catch{}
            window.__stageOnTrace.push({name,ok:res.ok,status:res.status,
              enabled:name==="get_exam_prep_hybrid_s4_stage_status_safe_v1"?data?.enabled:undefined});
            return res.ok?{data,error:null}:{data:null,error:{
              code:data?.code||String(res.status),message:data?.message||"HTTP error"
            }};
          }};
          window.i18n={getLang:()=>lang};
        },{jwt,lang});
        for(const file of ["exam-prep/exam-prep-api.js","exam-prep/exam-prep-host.js",
          "exam-prep/exam-prep-live.js","exam-prep/exam-prep-written-understanding-ui.js"])
          await page.addScriptTag({path:path.resolve(file)});
        const opened=await page.evaluate(async(lang)=>{
          const sync=await window.iClubExamPrep.syncSubjectHub({subjectKey:"mathematics",language:lang});
          const open=await window.iClubExamPrep.open({subjectKey:"mathematics",language:lang});
          return {sync,open};
        },lang);
        assert(opened.sync&&opened.open,"signed Math Stage-ON Core unavailable "+lang);
        const p5=page.locator('[data-ep-live-open-component="P5"]');
        await p5.waitFor({timeout:25000});await p5.click();
        await page.locator('[data-ep-component-home="P5"]').waitFor({timeout:25000});
        assert.equal(await page.locator('[data-ep-component-link="readiness"]').count(),0,
          "P5 Stage4 must not show Final Calibration / readiness navigation "+lang);
        const statusP5=await page.evaluate(async()=>{
          const s=await window.sb.rpc("get_exam_prep_hybrid_s4_stage_status_safe_v1",
            {p_component_code:"P5"});
          const c=await window.sb.rpc("get_exam_prep_final_calibration_safe_v1",
            {p_component_code:"P5"});
          return {s,c};
        });
        assert(statusP5.s.error===null&&statusP5.s.data?.enabled===true&&
          statusP5.s.data?.stage5_to_6?.ready===false,
          "P5 signed objective gate must remain independently blocked "+lang);
        assert(statusP5.c.error===null&&statusP5.c.data?.available===false,
          "P5 calibration must remain unavailable without its own L3 "+lang);
        await page.evaluate(()=>window.iClubExamPrep.back());
        await page.locator('[data-ep-live-open-component="P1"]').waitFor({timeout:25000});
        await page.locator('[data-ep-live-open-component="P1"]').click();
        await page.locator('[data-ep-component-home="P1"]').waitFor({timeout:25000});
        const readinessLink=page.locator('[data-ep-component-link="readiness"]');
        await readinessLink.waitFor({timeout:25000});
        await readinessLink.click();
        const stageUI=page.locator('[data-ep-live-operational-readiness]');
        await stageUI.waitFor({timeout:25000});
        const visible=await stageUI.textContent();
        assert(visible.includes(translations[lang].title)&&
          visible.includes(translations[lang].note),
          "Stage-ON actual screen must localize ungraded objective readout "+lang);
        assert(visible.includes("45 / 45"),"P1 must show actual signed 45/45 L3 "+lang);
        assert(!visible.includes("0 / 3")&&!visible.includes("75 / 75"),
          "No legacy comparable Paper score / invented mark on Stage-ON UI "+lang);
        const button=stageUI.locator('[data-ep-live-calibration="P1"]');
        assert.equal(await button.count(),1,"P1 real Stage6 must offer Final Calibration "+lang);
        await button.click();
        const examOps=page.locator('[data-ep-live-exam-ops]');
        await examOps.waitFor({timeout:25000});
        assert.equal(await page.locator('[data-ep-live-calibration="P5"]').count(),0,
          "P1 calibration may never unlock P5");
        const signed=await page.evaluate(()=>window.__stageOnTrace);
        for(const name of ["get_exam_prep_hybrid_s4_stage_status_safe_v1",
          "get_exam_prep_final_calibration_safe_v1"])
          assert(signed.some(x=>x.name===name&&x.ok),
            "Missing signed real PostgREST "+name+" "+lang);
        // Error path: an RPC failure is never permission to return to old
        // scored-Paper readiness. Reopen P1 from the learner dashboard.
        await page.locator('[data-ep-live-dashboard]').click();
        await page.locator('[data-ep-live-open-component="P1"]').waitFor({timeout:25000});
        await page.locator('[data-ep-live-open-component="P1"]').click();
        await page.locator('[data-ep-component-home="P1"]').waitFor({timeout:25000});
        await page.evaluate(()=>{
          const original=window.sb.rpc.bind(window.sb);
          window.sb.rpc=async(name,args)=>name==="get_exam_prep_hybrid_s4_stage_status_safe_v1"
            ?{data:null,error:{code:"SIMULATED_READ_FAILURE",message:"isolated UI error-path fixture"}}
            :original(name,args);
        });
        await page.locator('[data-ep-component-link="readiness"]').click();
        await page.locator('.ep-live-error[role="alert"]').waitFor({timeout:25000});
        const failText=await page.locator('#exam-prep-host-root').textContent();
        assert(!failText.includes("0 / 3")&&
          await page.locator('[data-ep-live-calibration]').count()===0,
          "Failed signed Stage RPC may not fall through to legacy Paper scores "+lang);
        assert.deepEqual(errors,[],"browser JS error "+lang+": "+errors.join("; "));
        console.log("PASS actual Stage-ON Chromium "+lang+" "+width+
          ": signed PG17 P1 Stage6, P5 Stage4 blocked, localized no-Paper-marks, no fallback on RPC error");
      } finally {await page.close()}
    }
  } finally {await browser.close()}
};
