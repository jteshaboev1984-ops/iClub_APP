/* UX531 live Mathematics P1/P5 read-only route after a plan.
   Uses the REAL exam-prep-live.js and CSS, but only synthetic in-memory API.
   No Supabase URL, credentials, real user, HTTP API call, or session start. */
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const http = require("node:http");
const path = require("node:path");
const { chromium } = require("playwright");

const root = path.resolve(__dirname, "..");
const screens = path.join(root, "ux531-academy-all-screens");
const html = [
  '<!doctype html><html lang="ru"><head><meta charset="utf-8">',
  '<meta name="viewport" content="width=device-width, initial-scale=1">',
  '<link rel="stylesheet" href="/exam-prep/exam-prep-host.css">',
  '<link rel="stylesheet" href="/visual/iclub-academy-ux531-b04b08.css">',
  '</head><body class="iclub-visual-v3">',
  '<main style="width:100%;max-width:100%;box-sizing:border-box;padding:10px">',
  '<section id="courses-subject-hub" data-subject-key="mathematics">',
  '<div id="exam-prep-host-root"></div></section></main>',
  '<script src="/exam-prep/exam-prep-live.js"></script>',
  '</body></html>'
].join("");

const server = http.createServer((req, res) => {
  let p;
  try { p = new URL(req.url, "http://127.0.0.1").pathname; }
  catch { res.writeHead(400).end(); return; }
  if (p === "/") {
    res.writeHead(200, { "content-type": "text/html; charset=utf-8" }).end(html);
    return;
  }
  if (!["/exam-prep/exam-prep-live.js", "/exam-prep/exam-prep-host.css", "/visual/iclub-academy-ux531-b04b08.css"].includes(p)) {
    res.writeHead(404).end(); return;
  }
  const file = path.join(root, p.slice(1));
  try {
    res.writeHead(200, { "content-type": p.endsWith(".css") ? "text/css" : "text/javascript" });
    res.end(fs.readFileSync(file));
  } catch { res.writeHead(404).end(); }
});

async function caseRun(browser, address, { language, width, mode }) {
  const page = await browser.newPage({ viewport: { width, height: 840 } });
  const unexpected = [], externalRequests = [];
  page.on("pageerror", error => unexpected.push(String(error)));
  await page.route("**/*", route => {
    if (new URL(route.request().url()).hostname === "127.0.0.1") return route.continue();
    externalRequests.push(route.request().url().split("?")[0]);
    return route.abort("blockedbyclient");
  });
  await page.addInitScript(({ deny }) => {
    const tracker = window.__UX531_MATH_TEST = {
      profile: null, saves: [], diag: [], starts: [], serverWrites: []
    };
    const api = {
      async examProfile() { return { ok:true, data:tracker.profile }; },
      async saveExamProfile(values) {
        tracker.saves.push({ ...values });
        tracker.profile = {
          exam_series: values.examSeries,
          target_grade: values.targetGrade,
          total_student_hours_available: values.totalHours,
          mathematics_hours_budget: values.mathHours
        };
        return { ok:true, data:{ ...tracker.profile } };
      },
      async diagnosticProgress(component) {
        tracker.diag.push(component);
        if (component !== "P1" && component !== "P5") throw Error("Unexpected Paper");
        const isP1 = component === "P1";
        return {ok:true, data:{
          component_code:component, stage0_complete:false,
          active_session:isP1 ? {session_id:"FAKE-P1-ONLY"} : null,
          screening:{
            required_items:isP1 ? 7 : 9,
            answered_items:isP1 ? 3 : 0,
            required_areas:isP1 ? 3 : 4,
            answered_areas:isP1 ? 1 : 0
          }
        }};
      },
      async personalHorizon() { return {ok:true,data:null}; },
      async studySchedule() { return {ok:true,data:null}; },
      async weeklyChoiceS3() { return {ok:true,data:null}; },
      async hybridS4Catalog(component) { return {ok:true,data:{enabled:false,papers:[],component_code:component}}; },
      async hybridS4History(component) {return {ok:true,data:{component_code:component,sessions:[]}};},
      async recentResults(component) {return {ok:true,data:{component_code:component,results:[]}};},
      async startNextDiagnostic(component) {
        tracker.starts.push(component);
        throw Error("QA must not start any attempt");
      }
    };
    window.iClubExamPrepHostInternal = {
      lastCapabilities: {coreAccess:!deny, killSwitch:false, rolloutState:"controlled_beta"},
      api
    };
    window.iClubExamPrep = {
      open:async()=>true, close:()=>true, back:()=>true, isOpen:()=>true,
      syncSubjectHub:async()=>true, refreshCapabilities:async()=>true
    };
  }, { deny: mode === "denied" });

  try {
    await page.goto(address, {waitUntil:"domcontentloaded"});
    await page.waitForFunction(() => window.iClubExamPrep?.liveFlowVersion);
    const opened = await page.evaluate(async language =>
      window.iClubExamPrep.open({subjectKey:"mathematics",language}), language);
    if (mode === "denied") {
      assert.equal(await page.locator("[data-ep-live-profile-form]").count(),0,
        "A denied Math capability must never mount the plan form");
      assert.equal(await page.locator(".ep-live-component-entry").count(),0,
        "A denied Math capability must never mount P1/P5");
      return;
    }
    assert.equal(opened,true,"Synthetic authorized host should open");
    const form = page.locator("[data-ep-live-profile-form]");
    await form.waitFor();
    assert.equal(await form.locator("input").count(),4,"Real plan form has four fields");
    await form.locator('[name="exam_series"]').fill("June 2027");
    await form.locator('[name="target_grade"]').fill("A");
    await form.locator('[name="total_hours"]').fill("16");
    await form.locator('[name="math_hours"]').fill("17");
    await form.locator('[data-ep-live-save-profile]').click();
    assert.equal(await page.evaluate(() => window.__UX531_MATH_TEST.saves.length),0,
      "Invalid weekly budget cannot be persisted");
    await form.locator('[name="math_hours"]').fill("8");
    await form.locator('[data-ep-live-save-profile]').click();
    await page.locator(".ep-live-component-entry").first().waitFor({timeout:10000});
    assert.equal(await page.locator(".ep-live-component-entry").count(),2,"P1 and P5 must remain separate");
    const cardP1 = page.locator('[data-ep-live-open-component="P1"]');
    const cardP5 = page.locator('[data-ep-live-open-component="P5"]');
    assert.equal(await cardP1.count(),1);
    assert.equal(await cardP5.count(),1);
    const p1 = await cardP1.innerText(), p5 = await cardP5.innerText();
    assert.match(p1,/Pure Mathematics 1/);
    assert.match(p5,/Probability & Statistics 1/);
    assert.match(p1,/45/);
    assert.match(p5,/36/);
    assert.match(p1,/3\s*\/\s*7/,"P1 must use only P1 diagnostic evidence");
    assert.match(p5,/0\s*\/\s*9/,"P5 must use only P5 diagnostic evidence");
    const copy = await page.locator(".ep-live-dashboard-title").innerText();
    const expected = language==="en" ? "Preparation for P1 and P5" :
      language==="uz" ? "P1 va P5 bo‘yicha tayyorgarlik" : "Подготовка по P1 и P5";
    assert.equal(copy,expected);
    assert.equal(await page.locator(".ep-live-dashboard-profile").count(),1,
      "Saved study plan must be reflected on the P1/P5 dashboard");
    // The exact approved v5.8 plan, learning, practice and history layout
    // must fit across all named widths without reducing touch targets.
    const verifyLayout = async (place, requireTabs=false) => {
      const metrics=await page.evaluate(()=>{
        const tabs=[...document.querySelectorAll('#exam-prep-host-root .ep-v58-tab')]
          .filter(el=>getComputedStyle(el).display!=='none')
          .map(el=>({width:el.getBoundingClientRect().width,height:el.getBoundingClientRect().height}));
        return {width:document.documentElement.scrollWidth,viewport:innerWidth,tabs};
      });
      assert(metrics.width<=metrics.viewport+2,
        place+' horizontal overflow '+language+'/'+width+': '+JSON.stringify(metrics));
      if(requireTabs){
        assert.equal(metrics.tabs.length,3,place+' requires exactly three P1/P5 tabs');
        assert(metrics.tabs.every(t=>t.width>=44&&t.height>=44),
          place+' must keep accessible touch target '+JSON.stringify(metrics.tabs));
        const w=metrics.tabs.map(t=>t.width);
        assert(Math.max(...w)-Math.min(...w)<=2,
          place+' tabs must be symmetrical '+JSON.stringify(metrics.tabs));
      }
    };
    const scope = await page.evaluate(() => ({
      viewport:innerWidth,document:document.documentElement.scrollWidth,
      rootWidth:document.getElementById("exam-prep-host-root").getBoundingClientRect().width
    }));
    assert(scope.document <= scope.viewport + 1,
      "Saved plan and two Paper cards overflow at "+width+": "+JSON.stringify(scope));
    const recorded = await page.evaluate(() => window.__UX531_MATH_TEST);
    assert.equal(recorded.saves.length,1,"Exactly one synthetic save after validation");
    assert.deepEqual(recorded.diag,["P1","P5"],"Independent diagnostic reads");
    assert.deepEqual(recorded.starts,[],"No exam attempt started by the visual test");
    assert.deepEqual(recorded.serverWrites,[],"No persistence outside synthetic memory");
    // The v5.8 overview keeps the two subject components ABOVE configuration.
    assert.equal(await page.locator(".ep-v58-main-components .ep-live-component-entry").count(),2);
    assert.equal(await page.locator("[data-ep-v58-plan-summary]").count(),1);
    assert.equal(await page.locator("[data-ep-study-schedule]").count(),0,
      "Dashboard must not expose an always-open schedule form");
    await page.locator("[data-ep-v58-plan-open]").click();
    await page.locator("[data-ep-v58-plan-page]").waitFor();
    await verifyLayout('My plan');
    assert.equal(await page.locator("[data-ep-v58-setting]").count(),2,
      "Schedule and dates must be grouped behind disclosure");
    const settings=page.locator('[data-ep-v58-setting="schedule"]');
    assert.equal(await settings.evaluate(el=>el.open),false,"schedule should be collapsed");
    await settings.locator("summary").click();
    assert.equal(await settings.evaluate(el=>el.open),true);
    await page.locator("[data-ep-v58-plan-back]").click();
    await page.locator(".ep-v58-main-components").waitFor();
    await page.locator('[data-ep-live-open-component="P1"]').click();
    await page.locator('[data-ep-component-home="P1"]').waitFor();
    await verifyLayout('P1 Learning',true);
    assert.equal(await page.locator('[data-ep-v58-tab="learning"]').getAttribute("aria-current"),
      "page","component opens Learning, never starts diagnostics");
    assert.deepEqual((await page.evaluate(()=>window.__UX531_MATH_TEST.starts)),[]);
    await page.locator('[data-ep-v58-tab="training"]').click();
    await page.locator('[data-ep-v58-component-training="P1"]').waitFor();
    await verifyLayout('P1 Practice',true);
    await page.locator('[data-ep-v58-tab="history"]').click();
    await page.locator('[data-ep-v58-history="P1"]').waitFor();
    await verifyLayout('P1 History',true);
    assert.equal(await page.locator('[data-ep-history-legacy-section]').count(),1);
    await page.locator('[data-ep-v58-tab="learning"]').click();
    await page.locator('[data-ep-component-home="P1"]').waitFor();
    await page.locator('[data-ep-component-back]').click();
    await page.locator('[data-ep-live-open-component="P5"]').click();
    await page.locator('[data-ep-component-home="P5"]').waitFor();
    await verifyLayout('P5 Learning',true);
    assert.equal(await page.locator('[data-ep-v58-tab="learning"]').getAttribute('aria-current'),'page');
    await page.locator('[data-ep-v58-tab="training"]').click();
    await page.locator('[data-ep-v58-component-training="P5"]').waitFor();
    await verifyLayout('P5 Practice',true);
    await page.locator('[data-ep-v58-tab="history"]').click();
    await page.locator('[data-ep-v58-history="P5"]').waitFor();
    await verifyLayout('P5 History',true);
    assert.equal(await page.locator('[data-ep-history-legacy-section]').count(),1);
    await page.locator('[data-ep-v58-tab="learning"]').click();
    await page.locator('[data-ep-component-home="P5"]').waitFor();
    assert.deepEqual((await page.evaluate(()=>window.__UX531_MATH_TEST.starts)),[],
      "P1/P5 browsing must never generate or consume an attempt");
    if (language==="ru" && width===390 || language==="uz" && width===320 ||
        language==="en" && width===1440) {
      fs.mkdirSync(screens,{recursive:true});
      await page.screenshot({
        path:path.join(screens,"math-p1p5-plan-"+language+"-"+width+".png"),
        fullPage:true
      });
    }
    console.log("PASS UX531 Mathematics plan -> real P1/P5 dashboard",
      language,width,"P1 3/7 P5 0/9; no attempts or network");
  } finally {
    assert.equal(externalRequests.length,0,"External requests prohibited: "+externalRequests.join(","));
    assert.equal(unexpected.length,0,"Uncaught runtime errors: "+unexpected.join("; "));
    await page.close();
  }
}

(async () => {
  await new Promise(resolve => server.listen(0,"127.0.0.1",resolve));
  const base = "http://127.0.0.1:"+server.address().port+"/";
  const browser = await chromium.launch({headless:true});
  try {
    await caseRun(browser,base,{language:"ru",width:390,mode:"denied"});
    for (const language of ["ru","uz","en"]) {
      for (const width of [320,375,390,430,1440]) {
        await caseRun(browser,base,{language,width,mode:"plan"});
      }
    }
  } finally {
    await browser.close();
    await new Promise(resolve=>server.close(resolve));
  }
})().catch(error => {console.error("UX531 math P1/P5 mock failed",error.stack||error);process.exitCode=1;});
