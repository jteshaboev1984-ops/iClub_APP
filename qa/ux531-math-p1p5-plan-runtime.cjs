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
const paperSource = fs.readFileSync(path.join(root, "exam-prep/exam-prep-live.js"),"utf8");
assert.equal((paperSource.match(/mentorOptional:/g)||[]).length,3,
  "S4 Paper mentor advice must be localized in RU/UZ/EN");
assert.equal((paperSource.match(/noScore:/g)||[]).length,4,
  "S4 Paper must remain ungraded in RU/UZ/EN and the safe fallback");
assert.match(paperSource,/data-ep-hybrid-s4-mentor-optional/,
  "Paper review should provide optional advice without a required mentor gate");
assert.match(paperSource,/function renderLoading\(scope = "default", component = ""\)/,
  "Exam Prep loading copy must describe the current destination");
for(const expected of ['renderLoading("route")','renderLoading("component", component)',
    'renderLoading("history",component)','renderLoading("plan", component)',
    'renderLoading("paper", component)','renderLoading("answer")']){
  assert(paperSource.includes(expected),"Missing contextual loading message: "+expected);
}
assert(paperSource.includes('ru:["Маршрут","Тренировки","История"'),
  "Route and Practice must describe distinct functions");
const homeStyle=fs.readFileSync(path.join(root,"visual/iclub-academy-ux531-b02b03.css"),"utf8");
// Final owner swatches supersede historical gradients. Both rails still swipe:
// Competitive screenshot 1 is SOLID #174AAB, pinned Study screenshot 2 SOLID #3071E1.
// White labels must remain readable on the brighter solid pinned fill.
assert(homeStyle.includes("body.iclub-visual-v3 #view-home #home-competitive-list .home-competitive-card{\n  background:#174aab;"),
  "All Competitive subject cards must match the exact solid #174AAB swatch");
assert(homeStyle.includes("background:#3071e1;"),
  "Pinned Study cards must match the exact solid #3071E1 swatch");
assert(!homeStyle.includes("linear-gradient(137deg,#174aab")&&
  !homeStyle.includes("linear-gradient(137deg,#5689d2"),
  "Previous mixed-color swatches must not reappear as gradients");
const luminance = hex => {
  const channels=[1,3,5].map(i=>parseInt(hex.slice(i,i+2),16)/255)
    .map(c=>c<=.04045?c/12.92:((c+.055)/1.055)**2.4);
  return .2126*channels[0]+.7152*channels[1]+.0722*channels[2];
};
const contrast = (a,b) => (Math.max(luminance(a),luminance(b))+.05)/
  (Math.min(luminance(a),luminance(b))+.05);
assert(luminance("#3071e1")>luminance("#174aab"),
  "Pinned swatch must be lighter than Competitive");
assert(contrast("#ffffff","#3071e1")>=4.5,
  "White pinned title, header and footer text must remain readable");
assert(homeStyle.includes("box-shadow:0 8px 20px rgba(27,81,160,.14)"),
  "Pinned elevation must stay visibly below Competitive");

const screens = path.join(root, "ux531-academy-all-screens");
const html = [
  '<!doctype html><html lang="ru"><head><meta charset="utf-8">',
  '<meta name="viewport" content="width=device-width, initial-scale=1">',
  // Production iClub loads the shared sans-serif foundation BEFORE Exam Prep.
  // Omitting it made offline Math screenshots render in browser-default serif.
  '<link rel="stylesheet" href="/style.css">',
  '<link rel="stylesheet" href="/visual/iclub-visual-v3.css">',
  '<link rel="stylesheet" href="/exam-prep/exam-prep-host.css">',
  '<link rel="stylesheet" href="/visual/iclub-academy-ux531-b04b08.css">',
  '</head><body class="iclub-visual-v3">',
  '<main style="width:100%;max-width:100%;box-sizing:border-box;padding:10px">',
  '<section id="courses-subject-hub" data-subject-key="mathematics">',
  '<div id="exam-prep-host-root"></div></section></main>',
  '<script src="/exam-prep/exam-prep-live.js"></script>',
  '<script src="/exam-prep/exam-prep-exam-map.js"></script>',
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
  if (!["/style.css", "/visual/iclub-visual-v3.css", "/exam-prep/exam-prep-live.js", "/exam-prep/exam-prep-exam-map.js", "/exam-prep/exam-prep-host.css", "/visual/iclub-academy-ux531-b04b08.css"].includes(p)) {
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
  // Disposable test data only: owner visual acceptance screenshots.
  // Avoid production, real learner names, Supabase credentials, and answers.
  const capture=async(name,eligible=true)=>{
    if(!eligible)return;
    fs.mkdirSync(screens,{recursive:true});
    await page.screenshot({path:path.join(screens,name),fullPage:true});
  };
  const mobileRu=language==="ru"&&width===390;
  const reviewViewport=mobileRu||(language==="uz"&&width===320)||(language==="en"&&width===1440);
  page.on("pageerror", error => unexpected.push(String(error)));
  await page.route("**/*", route => {
    if (new URL(route.request().url()).hostname === "127.0.0.1") return route.continue();
    externalRequests.push(route.request().url().split("?")[0]);
    return route.abort("blockedbyclient");
  });
  await page.addInitScript(({ deny }) => {
    const tracker = window.__UX531_MATH_TEST = {
      profile: null, saves: [], diag: [], starts: [], serverWrites: [],
      failNextProfileSave:false, failNextWeeklyRead:false,
      weeklyChoice:null, weeklyReads:0, weeklySaves:[]
    };
    const api = {
      async examProfile() { return { ok:true, data:tracker.profile }; },
      async saveExamProfile(values) {
        if(tracker.failNextProfileSave){
          tracker.failNextProfileSave=false;
          return {ok:false,error:{message:"Synthetic transient save failure"}};
        }
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
      async weeklyChoiceS3() {
        tracker.weeklyReads++;
        if(tracker.failNextWeeklyRead){
          tracker.failNextWeeklyRead=false;
          return {ok:false,error:{message:"Synthetic read-back failure"}};
        }
        return {ok:true,data:tracker.weeklyChoice ? {...tracker.weeklyChoice}:null};
      },
      async saveWeeklyChoiceS3(args,id) {
        tracker.weeklySaves.push({args:{...args},id});
        const prior=tracker.weeklyChoice;
        if(!prior || prior.schedule_revision!==args.scheduleRevision)
          return {ok:false,error:{message:"Synthetic stale schedule revision"}};
        tracker.weeklyChoice={
          ...prior, choice_code:args.choice, choice_recorded:true,
          p1_minutes:args.p1Minutes, p5_minutes:args.p5Minutes,
          schedule_revision:prior.schedule_revision+1
        };
        return {ok:true,data:{saved:true}};
      },
      async claimPeriodReportsS3() { return {ok:true,data:{claimed:0}}; },
      async periodReportsS3() { return {ok:true,data:{reports:[]}}; },
      async hybridS4Catalog(component) { return {ok:true,data:{enabled:false,papers:[],component_code:component}}; },
      async hybridS4History(component) {
        return {ok:true,data:{component_code:component,sessions:Array.from(
          {length:component==="P1"?12:0},(_,i)=>({
            session_id:"synthetic-paper-"+(i+1),paper_key:"p1_full_paper_"+(i+1),
            started_at:new Date(Date.UTC(2026,10,16-i)).toISOString(),
            closed_at:new Date(Date.UTC(2026,10,16-i)).toISOString(),
            closure_code:"completed",review_revealed:true
          }))}};
      },
      async recentResults(component,limit) {
        if(limit!==20)throw Error("Core history must request only the supported 20-row cap");
        return {ok:true,data:{component_code:component,results:Array.from(
          {length:component==="P1"?18:0},(_,i)=>({
            session_id:"synthetic-core-"+(i+1),session_type:"learning",
            finalized_at:new Date(Date.UTC(2026,10,16-i)).toISOString(),
            machine_total:5,machine_correct:4,written_total:0,written_advanced:0
          }))}};
      },
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
    await page.waitForFunction(() => window.iClubExamPrepHostInternal?.examMapUiVersion === "p209map3");
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
    const initialFont = await page.evaluate(() =>
      getComputedStyle(document.querySelector("#exam-prep-host-root .ep-host-shell")).fontFamily);
    assert(/ui-sans-serif|system-ui/i.test(initialFont) && !/Times New Roman/i.test(initialFont),
      "Math Exam Prep must inherit the actual iClub sans-serif app typography: "+initialFont);
    assert.equal(await page.locator("[data-ep-v58-plan-page]").count(),1,
      "New learner should edit profile within My plan, not on a duplicate screen");
    assert.equal(await page.locator("[data-ep-v58-profile-editor]").count(),1);
    const form = page.locator("[data-ep-live-profile-form]");
    await form.waitFor();
    await capture("math-my-plan-first-setup-ru-390.png",mobileRu);
    assert.equal(await form.locator("input").count(),2,
      "D3: first entry asks only for exam series and target grade, never study hours");
    assert.equal(await form.locator('[name="total_hours"]').count(),0);
    assert.equal(await form.locator('[name="math_hours"]').count(),0);
    await form.locator('[name="exam_series"]').fill("June 2027");
    await form.locator('[name="target_grade"]').fill("A");
    const regression=language==="ru" && width===390;
    if(regression){
      await page.evaluate(()=>{
        window.__UX531_MATH_TEST.weeklyChoice={
          contract_version:"voluntary_weekly_choice_s3_v1",
          schedule_revision:1, choice_recorded:true, choice_code:"keep",
          chosen_math_minutes:200, total_available_minutes:960,
          p1_minutes:100, p5_minutes:100,
          study_minutes_per_day:40, study_days_per_week:5
        };
      });
    }
    await form.locator('[data-ep-live-save-profile]').click();
    await page.locator(".ep-live-component-entry").first().waitFor({timeout:10000});
    const initial=await page.evaluate(()=>window.__UX531_MATH_TEST);
    assert.equal(initial.saves.length,1,"New learner saves genuine exam details once");
    assert.equal(initial.saves[0].totalHours,null,"Unknown total time must not become zero or estimate");
    assert.equal(initial.saves[0].mathHours,null,"Unknown Maths time must remain null");

    // The same unified My plan later offers VOLUNTARY hours. Exercise both
    // an invalid choice and successful existing-profile edit without a second page.
    await page.locator('[data-ep-v58-plan-open]').click();
    await page.locator('[data-ep-v58-profile-edit]').click();
    const returning=page.locator('[data-ep-live-profile-form]');
    assert.equal(await returning.locator('input').count(),4,
      "Only returning learner's edit view offers two optional time fields");
    await returning.locator('[name="total_hours"]').fill("16");
    await returning.locator('[name="math_hours"]').fill("17");
    await returning.locator('[data-ep-live-save-profile]').click();
    assert.equal(await page.evaluate(()=>window.__UX531_MATH_TEST.saves.length),1,
      "Invalid weekly budget must not produce another profile write");
    await returning.locator('[name="math_hours"]').fill("8");
    await returning.locator('[data-ep-live-save-profile]').click();
    await page.locator('[data-ep-v58-profile-summary]').waitFor();
    await page.locator('[data-ep-v58-plan-back]').click();
    await page.locator(".ep-live-component-entry").first().waitFor({timeout:10000});
    assert.equal(await page.locator(".ep-live-component-entry").count(),2,"P1 and P5 must remain separate");
    const cardP1 = page.locator('[data-ep-live-open-component="P1"]');
    const cardP5 = page.locator('[data-ep-live-open-component="P5"]');
    assert.equal(await cardP1.count(),1);
    assert.equal(await cardP5.count(),1);
    assert.equal(await page.locator(".ep-live-component-open").count(),0,
      "P1/P5 must not repeat the bottom Open text and arrow");
    assert.equal(await page.locator(".ep-live-component-arrow").count(),2,
      "P1 and P5 retain exactly one top-right arrow each");
    assert.equal(await cardP1.getAttribute("type"),"button",
      "Whole P1 card must remain a native tappable button");
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
    // Route overview must show the single My Plan card BELOW P1/P5, not
    // repeat the same hours/profile in a second badge above the cards.
    assert.equal(await page.locator(".ep-live-dashboard-profile").count(),0,
      "Do not duplicate saved plan details beside the route header");
    assert.equal(await page.locator("[data-ep-v58-plan-summary]").count(),1);
    // Real browser regression: BOTH production modules are mounted. Give the
    // old MutationObserver/async profile read enough time to try its hydrate.
    await page.waitForTimeout(90);
    assert.equal(await page.locator("[data-ep-exam-plan-card]").count(),0,
      "No stale Exam Plan overlay may duplicate the v5.8 My plan card");
    assert.equal(await page.locator("[data-ep-exam-plan-edit]").count(),0,
      "The old profile editor must not compete with unified My plan");
    assert.match(await page.locator("[data-ep-v58-plan-summary]").innerText(),
      language==="en"?/My plan/:language==="uz"?/Mening rejam/:/Мой план/);
    const overviewOrder = await page.evaluate(()=>{
      const root=document.getElementById("exam-prep-host-root");
      return ["ep-live-dashboard-intro","ep-v58-main-components","ep-v58-plan-summary"]
        .map(cls=>[...root.querySelectorAll("."+cls)][0])
        .filter(Boolean).map(el=>[...el.parentElement.children].indexOf(el));
    });
    assert.equal(overviewOrder.length,3,"Route, P1/P5 and My Plan must exist");
    assert(overviewOrder[0]<overviewOrder[1] && overviewOrder[1]<overviewOrder[2],
      "Your route, P1/P5, and My Plan must appear in that order: "+overviewOrder);
    await capture("math-p1p5-route-"+language+"-"+width+".png",reviewViewport);
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
    assert.equal(recorded.saves.length,2,"Initial optional-hours NULL save and explicit later time edit");
    assert.deepEqual(recorded.diag,["P1","P5","P1","P5"],"Both dashboard loads separately read P1 and P5");
    assert.deepEqual(recorded.starts,[],"No exam attempt started by the visual test");
    assert.deepEqual(recorded.serverWrites,[],"No persistence outside synthetic memory");
    // The v5.8 overview keeps the two subject components ABOVE configuration.
    assert.equal(await page.locator(".ep-v58-main-components .ep-live-component-entry").count(),2);
    assert.equal(await page.locator("[data-ep-v58-plan-summary]").count(),1);
    const overviewPlan=await page.locator("[data-ep-v58-plan-summary]").innerText();
    assert(!overviewPlan.includes("June 2027")&&!overviewPlan.includes("16")&&!overviewPlan.includes("P1:")&&
      !overviewPlan.includes("P5:"),"Dashboard My plan link must not duplicate profile, dates or budget");
    assert.equal(await page.locator("[data-ep-study-schedule]").count(),0,
      "Dashboard must not expose an always-open schedule form");
    await page.locator("[data-ep-v58-plan-open]").click();
    await page.locator("[data-ep-v58-plan-page]").waitFor();
    await verifyLayout('My plan');
    assert.equal(await page.locator(".ep-v58-section-head .ep-v58-back").count(),0,
      "My plan must not repeat the global topbar Back above its title");
    assert.equal(await page.locator("[data-ep-v58-plan-back]").count(),1,
      "One optional bottom Back is kept for embedded views without a topbar");
    await capture("math-my-plan-overview-"+language+"-"+width+".png",reviewViewport);
    if(mobileRu) {
      const examDates=page.locator('[data-ep-v58-setting="dates"]');
      await examDates.locator('summary').click();
      await capture("math-my-plan-p1p5-dates-ru-390.png");
      await examDates.locator('summary').click();
    }
    assert.equal(await page.locator("[data-ep-v58-setting]").count(),2,
      "Exactly two settings: exam dates, plus ONE schedule/weekly-allocation editor");
    assert.equal(await page.locator(".ep-v58-profile-fact").count(),4,
      "Exam series, target, total time, Maths time appear once in My plan summary");
    assert.equal(await page.locator("[data-ep-v58-profile-editor]").count(),0,
      "Editing form cannot repeat saved values unless user chooses Edit");
    assert.equal(await page.locator('[data-ep-v58-setting="dates"]').count(),1);
    assert.equal(await page.locator("[data-ep-exam-date-component]").count(),2);
    assert.equal(await page.locator('[data-ep-v58-setting="weekly"]').count(),regression?1:0);
    assert.equal(await page.locator('[data-ep-v58-setting="schedule"]').count(),regression?0:1);
    assert.equal(await page.locator("[data-ep-study-minutes]").count(),regression?0:1,
      "Only the appropriate schedule editor may exist in the plan");
    if(regression){
      // A failed profile edit must not erase the form or the user's new values.
      await page.locator("[data-ep-v58-profile-edit]").click();
      assert.equal(await page.locator("[data-ep-v58-profile-summary]").count(),0);
      await page.evaluate(()=>window.iClubExamPrep.back());
      assert.equal(await page.locator(".ep-v58-profile-fact").count(),4,
        "Device back from Edit restores the profile summary, not P1/P5 route");
      assert.equal(await page.locator("[data-ep-v58-profile-editor]").count(),0,
        "Device back must not leave a duplicate profile editor mounted");
      await page.locator("[data-ep-v58-profile-edit]").click();
      await capture("math-my-plan-profile-edit-ru-390.png");
      assert.equal(await page.locator("[data-ep-v58-plan-page] [data-ep-live-profile-form]").count(),1,
        "Saved-profile editing must remain inside the single My plan page");
      assert.equal(await page.locator("[data-ep-v58-profile-summary]").count(),0,
        "No saved-profile summary under the four identical editable values");
      assert.equal(await page.locator("[data-ep-v58-setting]").count(),0,
        "Hide unrelated dates and weekly controls while editing the four fields");
      assert.equal(await page.locator("[data-ep-live-profile-form] input").count(),4,
        "All original profile settings must exist exactly once in My plan editor");
      await page.locator('[name="target_grade"]').fill("A*");
      await page.evaluate(()=>{window.__UX531_MATH_TEST.failNextProfileSave=true;});
      await page.locator("[data-ep-live-save-profile]").click();
      await page.locator("[data-ep-live-profile-error]").getByText(/не удалось|ошиб|сохран/i).waitFor();
      assert.equal(await page.locator('[name="target_grade"]').inputValue(),"A*",
        "Transient save failure must preserve the edited grade");
      assert.equal(await page.locator("[data-ep-live-profile-form]").count(),1,
        "Transient save failure must keep the form mounted");
      await page.locator("[data-ep-live-save-profile]").click();
      await page.locator("[data-ep-v58-plan-page]").waitFor();
      assert.match(await page.locator("[data-ep-v58-plan-page] > .ep-live-notice[role=status]").innerText(),/сохран/i,
        "Plan must show the server-save confirmation on the current screen");
      assert.equal(await page.locator(".ep-v58-profile-fact").count(),4);
      assert.equal(await page.locator("[data-ep-v58-profile-editor]").count(),0,
        "After save, show summary INSTEAD OF editable form");
      assert.equal(await page.locator("[data-ep-study-schedule]").count(),0,
        "S3 weekly choice controls both daily schedule and P1/P5 split; no legacy duplicate");

      const weekly=page.locator('[data-ep-v58-setting="weekly"]');
      await weekly.locator("summary").click();
      await capture("math-my-plan-weekly-s3-ru-390.png");
      await weekly.locator('input[value="redistribute"]').check();
      await weekly.locator("[data-ep-s3-p1]").fill("110");
      await weekly.locator("[data-ep-s3-p5]").fill("90");
      await weekly.locator("[data-ep-s3-save]").click();
      await page.locator("[data-ep-v58-plan-page] > .ep-live-notice[role=status]").waitFor();
      assert.match(await page.locator("[data-ep-v58-plan-page] > .ep-live-notice[role=status]").innerText(),/сохран/i);
      await page.locator('[data-ep-v58-setting="weekly"][open]').waitFor();
      assert.equal(await page.locator("[data-ep-s3-p1]").inputValue(),"110");
      assert.equal(await page.locator("[data-ep-s3-p5]").inputValue(),"90");
      assert.equal(await page.evaluate(()=>window.__UX531_MATH_TEST.weeklyReads>=2),true,
        "Persisted S3 state must be fetched after Save");
      await page.locator("[data-ep-s3-save]").click();
      assert.equal(await page.evaluate(()=>window.__UX531_MATH_TEST.weeklySaves.length),1,
        "A saved and reread identical S3 choice must not create a duplicate write");

      // Server accepted the next choice, but its read-back fails. Do not falsely
      // display the old allocation as saved; tell the learner to reopen My plan.
      await weekly.locator("[data-ep-s3-p1]").fill("120");
      await weekly.locator("[data-ep-s3-p5]").fill("80");
      await page.evaluate(()=>{window.__UX531_MATH_TEST.failNextWeeklyRead=true;});
      await weekly.locator("[data-ep-s3-save]").click();
      await weekly.locator("[data-ep-s3-feedback]").getByText(/сохранён.*не загрузились/i).waitFor();
      assert.equal(await weekly.locator("[data-ep-s3-save]").isDisabled(),true,
        "Stale server revision cannot be submitted a second time");
      await page.locator("[data-ep-v58-plan-back]").click();
      await page.locator("[data-ep-v58-plan-open]").click();
      await page.locator('[data-ep-v58-setting="weekly"] summary').click();
      assert.equal(await page.locator("[data-ep-s3-p1]").inputValue(),"120");
      assert.equal(await page.locator("[data-ep-s3-p5]").inputValue(),"80",
        "Reopening My plan must load the accepted server allocation");
      assert.equal(await page.evaluate(()=>window.__UX531_MATH_TEST.weeklySaves.length),2);
    }
    if(regression) {
      assert.equal(await page.locator('[data-ep-v58-setting="schedule"]').count(),0,
        "Never show duplicate day/minute schedule when S3 is present");
      assert.equal(await page.locator('[data-ep-s3-newtime]').count(),1);
    } else {
      const settings=page.locator('[data-ep-v58-setting="schedule"]');
      assert.equal(await settings.evaluate(el=>el.open),false,"schedule should be collapsed");
      await settings.locator("summary").click();
      await capture("math-my-plan-legacy-schedule-"+language+"-"+width+".png",reviewViewport);
      assert.equal(await settings.evaluate(el=>el.open),true);
      assert.equal(await page.locator("[data-ep-study-schedule] [data-ep-study-minutes]").count(),1);
      assert.equal(await page.locator("[data-ep-study-schedule] [data-ep-study-days]").count(),1);
      assert.equal(await page.locator("[data-ep-study-schedule] .ep-live-study-schedule-summary span.ep-live-meta").count(),0,
        "Do not repeat Maths and total-time budget in schedule preview");
    }
    await page.locator("[data-ep-v58-plan-back]").click();
    await page.locator(".ep-v58-main-components").waitFor();
    await page.waitForTimeout(50);
    assert.equal(await page.locator("[data-ep-exam-plan-card]").count(),0,
      "Returning from My plan must not resurrect the old duplicate card");
    await page.locator('[data-ep-live-open-component="P1"] .ep-live-component-copy').click();
    await page.locator('[data-ep-component-home="P1"]').waitFor();
    await verifyLayout('P1 Route',true);
    assert.equal(await page.locator(".ep-route-header .ep-route-back").count(),0,
      "P1 route must not repeat the topbar arrow within its hero");
    const routeLabel=language==="ru"?"Маршрут":language==="uz"?"Tayyorgarlik":"Route";
    assert.equal(await page.locator('[data-ep-v58-tab="learning"]').innerText(),routeLabel,
      "Route tab describes the next step, progress, topics and corrections");
    assert.equal(await page.locator('[data-ep-v58-tab="learning"]').getAttribute("aria-current"),
      "page","component opens its route, never starts diagnostics");
    assert.deepEqual((await page.evaluate(()=>window.__UX531_MATH_TEST.starts)),[]);
    await page.locator('[data-ep-v58-tab="training"]').click();
    await page.locator('[data-ep-v58-component-training="P1"]').waitFor();
    assert.equal(await page.locator(".ep-v58-training .ep-v58-section-head .ep-v58-back").count(),0,
      "Practice title needs no second top Back control");
    assert.equal(await page.locator(".ep-v58-training-description h3").count(),0,
      "Active Practice tab must not repeat the same heading");
    await verifyLayout('P1 Practice',true);
    await page.locator('[data-ep-v58-tab="history"]').click();
    await page.locator('[data-ep-v58-history="P1"]').waitFor();
    assert.equal(await page.locator("[data-ep-history-back]").count(),1,
      "History fallback Back lives at the bottom only");
    await verifyLayout('P1 History',true);
    assert.equal(await page.locator('[data-ep-history-legacy-section]').count(),1);
    const coreRecent=page.locator('[data-ep-history-recent="core"] .ep-history-row');
    const paperRecent=page.locator('[data-ep-history-recent="paper"] .ep-history-row');
    assert.equal(await coreRecent.count(),3,"Only newest 3 Core rows should render immediately");
    assert.equal(await paperRecent.count(),3,"Only newest 3 ungraded Paper rows should render immediately");
    await capture("math-p1-history-three-recent-ru-390.png",mobileRu);
    const coreOlder=page.locator('[data-ep-history-archive="core"]');
    const paperOlder=page.locator('[data-ep-history-archive="paper"]');
    assert.equal(await coreOlder.locator('.ep-history-row').count(),0,"Older Core hidden before disclosure");
    await coreOlder.locator('summary').click();
    await coreOlder.locator('.ep-history-row').nth(4).waitFor();
    assert.equal(await coreOlder.locator('.ep-history-row').count(),5,"Reveal exactly 5 Core rows");
    await capture("math-p1-history-older-five-ru-390.png",mobileRu);
    await coreOlder.locator('[data-ep-history-more="core"]').click();
    assert.equal(await coreOlder.locator('.ep-history-row').count(),10,"Second batch is exactly five");
    await coreOlder.locator('[data-ep-history-more="core"]').click();
    assert.equal(await coreOlder.locator('.ep-history-row').count(),15,"All 18 synthetic Core rows remain accessible");
    assert.equal(await coreOlder.locator('[data-ep-history-more="core"]').isVisible(),false);
    await paperOlder.locator('summary').click();
    await paperOlder.locator('.ep-history-row').nth(4).waitFor();
    assert.equal(await paperOlder.locator('.ep-history-row').count(),5,"Paper history reveals 5 without scoring");
    await paperOlder.locator('[data-ep-history-more="paper"]').click();
    assert.equal(await paperOlder.locator('.ep-history-row').count(),9,"All 12 Paper rows accessible");
    assert.equal(await paperOlder.locator('[data-ep-history-more="paper"]').isVisible(),false);
    assert.equal(await page.locator('[data-ep-history-delete]').count(),0,"No destructive history UX");

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
    // Legacy-only route compatibility: an older dashboard without v5.8 My plan
    // must still retain its existing edit action; never remove its API path.
    if (language === "ru" && width === 390) {
      await page.evaluate(() => {
        document.getElementById("exam-prep-host-root").innerHTML =
          '<section class="ep-host-shell ep-live">' +
          '<section class="ep-live-dashboard-intro">Legacy route</section>' +
          '<div class="ep-live-grid">' +
          '<button data-ep-live-plan="P1" type="button">P1</button>' +
          '<button data-ep-live-plan="P5" type="button">P5</button>' +
          '</div></section>';
      });
      await page.locator("[data-ep-exam-plan-card]").waitFor();
      assert.equal(await page.locator("[data-ep-exam-plan-card]").count(),1,
        "Older route without v5.8 summary retains its previous Plan control");
      await page.locator("[data-ep-exam-plan-edit]").click();
      await page.locator("[data-ep-exam-plan-editor]").waitFor();
      assert.equal(await page.locator("[data-ep-exam-plan-form]").count(),1,
        "Legacy profile editor remains available for old-only route");
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
