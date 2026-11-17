#!/usr/bin/env node
/* Exact-source UX firewall for 2026-11-17 Mathematics follow-up.
   Read-only, no student/network/database/deployment writes. */
"use strict";
const fs=require("node:fs"),cp=require("node:child_process"),assert=require("node:assert/strict");
const RELEASE="f945228fefe0ec3a013f34b7d0ab9ac6c40cc2e4";
const base=String(process.env.UX531_BASE_SHA||"");
const head=String(process.env.UX531_EXPECTED_SHA||"");
assert(/^[a-f0-9]{40}$/.test(base)&&/^[a-f0-9]{40}$/.test(head),"Full SHA required");
assert.equal(base,RELEASE,"Guard only for approved Academy #555 release");
const git=(...args)=>cp.execFileSync("git",args,{encoding:"utf8",maxBuffer:20000000}).trimEnd();
assert.equal(git("rev-parse","HEAD"),head,"Exact target SHA must be checked out");
assert.equal(git("merge-base",RELEASE,head),RELEASE,"Released SHA must be ancestor");
const changed=git("diff","--name-only",RELEASE,head).split("\n").filter(Boolean);
const allowed=new Set([
 ".github/scripts/visual_v3_home_study_regression.js",
 ".github/workflows/exam-prep-weekly-answer-recovery.yml",
 ".github/workflows/exam-prep-weekly-profile-recovery.yml",
 ".github/workflows/ux531-previewless-release-firewall.yml",
 "docs/ui-redesign/28-ux531-math-history-plan-and-retention-20261117.md",
 "exam-prep/exam-prep-api.js","exam-prep/exam-prep-live.js",
 "index.html","qa/ux531-academy-all-screens.cjs",
 "qa/ux531-academy-browser.cjs","qa/ux531-academy-ui-parity.cjs",
 "qa/ux531-math-p1p5-plan-runtime.cjs",
 "scripts/p1p5-s3-chromium-mobile-three-language.cjs",
 "qa/ux531-registered-navigation-e2e.cjs",
 "qa/ux531-math-history-plan-source-guard.cjs",
 "visual/iclub-academy-ux531-interactions.js",
 "visual/iclub-academy-ux531-b02b03.css",
 "visual/iclub-academy-ux531-b04b08.css"
]);
assert(changed.length>=10,"Expected bounded UI patch");
for(const x of changed)assert(allowed.has(x),"Unexpected release file "+x);
assert(!changed.some(x=>/^supabase\/|^api\/|^security\/|^content\/|^package|^vercel\.json|\.env/.test(x)),
 "No SQL/backend/student records/release or entitlement changes");
const read=p=>fs.readFileSync(p,"utf8");
const live=read("exam-prep/exam-prep-live.js"),api=read("exam-prep/exam-prep-api.js");
const index=read("index.html"),style=read("visual/iclub-academy-ux531-b02b03.css");
const css=read("visual/iclub-academy-ux531-b04b08.css");
assert(style.includes("body.iclub-visual-v3 #view-home #home-competitive-list .home-competitive-card{\n  background:#174aab;"),
 "Competitive cards must use exactly screenshot 1 solid #174AAB");
assert(style.includes("background:#3071e1;"),
 "Pinned Study must use screenshot 2 solid #3071E1");
for(const token of [
 "function renderMyPlan(expand=","function examProfileFormMarkup()",
 'renderMyPlan("profile")',"data-ep-v58-profile-editor",
 "async function saveProfile(event)","isInitialSetup",
 "async function openRecentResults(component)","historyListMarkup(",
 "bindHistoryDisclosure(","recentResults(component,20)",
 "recentResultsWritten(component,20)","data-ep-history-recent",
 "data-ep-history-archive","rows.slice(0,3)","rows.slice(3+shown,3+shown+5)",
 "data-ep-history-paper-session","data-ep-history-session",
 "epComponentTabs(component","data-ep-v58-plan-summary",
 "async function reconcilePendingAnswer(pending)","pending.idempotencyKey"
])assert(live.includes(token),"Required original/updated source invariant absent: "+token);
// Strict no-duplicate setting contract. No saved values, time editor or
// P1/P5 date may be shown twice on the same My plan screen.
const myPlan=live.slice(live.indexOf("function renderMyPlan(expand="),live.indexOf("async function renderDashboard()"));
const routePlan=live.slice(live.indexOf("function epPlanSummary()"),live.indexOf("function renderMyPlan(expand="));
assert(myPlan.includes("const editing=expand===")&&myPlan.includes("hasProfile&&!editing"),
 "Saved profile summary must be replaced (not repeated) while editing");
assert(myPlan.includes('data-ep-v58-profile-summary')&&myPlan.includes("ep-v58-profile-facts"),
 "All four profile facts must remain in one labeled summary");
assert(myPlan.includes('section("dates",t.dates,examDatesPanel())'),
 "Preserve both confirmed P1/P5 date actions in My plan");
assert(myPlan.includes('hasWeekly?section("weekly",t.weekly,weeklyS3Panel()):')&&
 myPlan.includes('section("schedule",t.schedule,studySchedulePanel())'),
 "Expose exactly one time editor per server S3/legacy contract");
assert(!routePlan.includes("mathematics_hours_budget")&&!routePlan.includes("personalHorizon")&&
 !routePlan.includes("exam_series"),"Route must not repeat saved My plan values");
const legacy=live.slice(live.indexOf("function studySchedulePanel()"),live.indexOf("function bindStudySchedule()"));
assert(!legacy.includes("formatWeeklyHours(math)")&&!legacy.includes("formatWeeklyHours(total)")&&
 !legacy.includes("esc(c.current)"),"Legacy schedule must not reprint profile budgets");
const examDates=live.slice(live.indexOf("function examDatesPanel()"),live.indexOf("function bindExamDatePanel()"));
assert(!examDates.includes("dateText")&&examDates.includes("data-ep-exam-date-input"),
 "P1/P5 dates need one input each, no duplicated displayed date string");
const s3=live.slice(live.indexOf("function weeklyS3Panel()"),live.indexOf("function bindWeeklyS3()"));
assert(s3.includes("data-ep-s3-newtime")&&s3.includes("data-ep-s3-p1")&&
 s3.includes("data-ep-s3-p5"),"S3 must preserve P1/P5 allocation and daily schedule editing");
// Two existing UX test suites were adjusted only to follow the new
// source-backed presentation contract, NEVER to bypass signed owner data.
// The translated section title appears ONCE in its <summary>, and the
// saved weekly total is verified via signed S3 read-back rather than a
// duplicate number inside the UI.
const s3Browser=read("scripts/p1p5-s3-chromium-mobile-three-language.cjs");
assert(s3Browser.includes("weeklyDetails.locator('summary').textContent()"),
 "S3 must check its accessible translated disclosure heading");
assert(s3Browser.includes("get_my_exam_prep_weekly_choice_s3_safe_v1")&&
 s3Browser.includes("chosen_math_minutes,175")&&
 s3Browser.includes("p1_minutes,100")&&s3Browser.includes("p5_minutes,75"),
 "S3 must verify a real signed owner persistence read, not fake repeat UI text");
assert(!s3Browser.includes("panel.textContent()).includes(title)"),
 "Old duplicate S3 heading test must be retired");
const planQA=read("qa/ux531-math-p1p5-plan-runtime.cjs");
assert(planQA.includes(".ep-v58-profile-fact")&&
 !planQA.includes("[data-ep-v58-profile-fact]"),
 "QA must select the actual labeled profile fact class, not nonexistent data attribute");
// Owner visual acceptance uses only disposable fixture data and source CSS.
// The saved screenshot payloads are NOT proofs of production learner state.
const fullScreens=read("qa/ux531-academy-all-screens.cjs");
for(const name of ["home-competitive-and-pinned-blue-",
 "home-competitive-card","home-pinned-tile"])
 assert(fullScreens.includes(name),"Visual Home source-CSS comparison capture missing: "+name);
assert(fullScreens.includes("ПРИМЕР · ТУР")&&
 fullScreens.includes("ЗАКРЕПЛЁН · ПРИМЕР"),
 "Illustrative Home cards must be visibly labeled synthetic");
for(const name of ["math-my-plan-first-setup-ru-390.png",
 "math-my-plan-overview-","math-my-plan-p1p5-dates-ru-390.png",
 "math-my-plan-profile-edit-ru-390.png","math-my-plan-weekly-s3-ru-390.png",
 "math-my-plan-legacy-schedule-","math-p1-history-three-recent-ru-390.png",
 "math-p1-history-older-five-ru-390.png"])
 assert(planQA.includes(name),"Owner requested Math My plan/history capture missing: "+name);
assert(!fullScreens.includes("save_exam_prep")&&!fullScreens.includes("supabase.rpc"),
 "Visual-only Home comparison must not write user/profile/attempt data");
// Clarified owner direction: BOTH Competitive and pinned Study must swipe.
// Every Competitive card retains one identical original blue; only pinned
// Study uses the second, lighter approved blue (not an alternation by swipe).
const railJs=read("visual/iclub-academy-ux531-interactions.js");
const railBrowser=read("qa/ux531-academy-browser.cjs");
const academyParity=read("qa/ux531-academy-ui-parity.cjs");
assert(style.includes("#home-competitive-list,")&&
 style.includes("#home-study-list{")&&
 style.includes("scroll-snap-type:x mandatory"),
 "Both native swipe rails must remain available to mobile learners");
assert(railJs.includes("{id:'home-competitive-list',child:'.home-competitive-card'}")&&
 railJs.includes("{id:'home-study-list',child:'.home-pinned-tile'}"),
 "Both accessible pagination rails must exist");
assert(railBrowser.includes("Competitive color must NOT change on swipe")&&
 academyParity.includes("Both subject families must keep horizontal swipe"),
 "Browser and source assertions must protect swipe AND uniform Competitive color");
assert(style.includes("background:#174aab;")&&
 style.includes("background:#3071e1;")&&
 !style.includes("linear-gradient(137deg,#174aab")&&
 !style.includes("linear-gradient(137deg,#5689d2"),
 "Exact solid sample 1 stays Competitive; exact solid sample 2 stays pinned");
const componentCards=live.slice(live.indexOf("function componentCard("),live.indexOf("function trackerAreaForSkill("));
assert(componentCards.includes("data-ep-live-open-component=")&&
 componentCards.includes("ep-live-component-arrow")&&
 !componentCards.includes("ep-live-component-open"),
 "P1/P5 must keep a full-card button with exactly one upper arrow, no bottom Open");
const nav=live.slice(live.indexOf("function epNavCopy(){"),live.indexOf("async function renderDashboard()"));
assert(nav.includes("function renderMyPlan(")&&
 !nav.includes('data-ep-v58-plan-back>←')&&
 nav.includes("epBottomBack('data-ep-v58-plan-back'")&&
 live.includes("function epSyncBackFallback(")&&
 live.includes('getComputedStyle(button).visibility==="visible"'),
 "Topbar back is primary; only one fallback bottom Back may appear when absent");
for(const text of ["Ko‘zlangan baho","Imtihon sessiyasi","Haftalik reja va hisobotlar",
 "Tayyorgarlik","Mashg‘ulot jadvali","Haftasiga necha kun"])
 assert(live.includes(text),"Natural Uzbek UI terminology missing: "+text);
assert(!live.includes("data-ep-history-delete"),"History deletion not approved");
assert(css.includes(".ep-history-archive")&&css.includes(".ep-history-more[hidden]"),"History CSS missing");
for(const v of ["ux531-dual-swipe-single-competitive-blue-v5","ux531-math-single-back-v5",
 "ux531-math-single-back-loader-v5","ux531-dual-subject-rail-3"])assert(index.includes(v),"Cache bust missing "+v);
assert(api.includes("ux531-native-back-single-arrow-uz-20261117-v5"),"Dynamic UI cache identity missing");
const a=read(".github/workflows/exam-prep-weekly-answer-recovery.yml")
 .match(/git hash-object exam-prep\/exam-prep-live\.js\)" = '([a-f0-9]{40})'/);
const p=read(".github/workflows/exam-prep-weekly-profile-recovery.yml")
 .match(/git hash-object exam-prep\/exam-prep-api\.js\)" = '([a-f0-9]{40})'/);
assert(a&&p,"Guarded answer/profile pins missing");
assert.equal(git("hash-object","exam-prep/exam-prep-live.js"),a[1],"Answer-ACK full blob changed without pin");
assert.equal(git("hash-object","exam-prep/exam-prep-api.js"),p[1],"Profile API full blob changed without pin");
const apiPlus=git("diff","--unified=0",RELEASE,head,"--","exam-prep/exam-prep-api.js")
 .split("\n").filter(x=>x.startsWith("+")&&!x.startsWith("+++"));
assert(apiPlus.length===1&&apiPlus[0].includes("ux531-native-back-single-arrow-uz-20261117-v5"),
 "API may change only display-client cache version");
const livePlus=git("diff","--unified=0",RELEASE,head,"--","exam-prep/exam-prep-live.js")
 .split("\n").filter(x=>x.startsWith("+")&&!x.startsWith("+++"));
for(const x of livePlus)assert(!/localStorage\.(?:clear|removeItem)|\b(?:drop|truncate)\s+(?:table|schema)\b|\b(?:qa_open_all_core|rollout_state|ai_enabled|mentor_enabled|stage_gates_enabled)\s*[:=]/i.test(x),
 "No storage clearing or authorization changes: "+x.slice(0,150));
console.log("UX531 Mathematics compact plan/history SOURCE-ONLY guard PASS");
console.log("base="+RELEASE+" head="+head+" files="+changed.length+" dbWrites=0");
