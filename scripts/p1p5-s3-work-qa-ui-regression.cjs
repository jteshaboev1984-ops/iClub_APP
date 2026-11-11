"use strict";

// Regression for the observed 2026-11-11 Work production E2E S3 UI defects.
// Executes the EXACT weekly copy and event binder from the shipping frontend
// with a minimal DOM mock. No production account, network or database access.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const source = fs.readFileSync("exam-prep/exam-prep-live.js", "utf8");

function between(start, end) {
  const from = source.indexOf(start);
  const until = source.indexOf(end, from);
  assert(from >= 0 && until > from, "weekly S3 function boundary missing");
  return source.slice(from, until);
}
const durationCode = between(
  "  function formatWeeklyDurationFromMinutes(value) {",
  "  function formatDateTime(value) {"
);
function checkDuration(locale, input, expected) {
  const ctx={state:{language:locale}};
  vm.runInNewContext(durationCode +
    "\\nglobalThis.__formatMinutes=formatWeeklyDurationFromMinutes;" +
    "\\nglobalThis.__formatHours=formatWeeklyHours;",ctx);
  assert.equal(ctx.__formatHours(input),expected,
    "weekly hours display "+locale+" for "+input);
  return ctx;
}
const weeklyCode =
  between("  function weeklyS3Copy() {", "  function weeklyS3Panel() {") +
  between("  function bindWeeklyS3() {", "  async function renderDashboard() {") +
  "\nglobalThis.__bindWeekly = bindWeeklyS3;";

const savedChoice = Object.freeze({
  contract_version: "voluntary_weekly_choice_s3_v1",
  choice_recorded: true,
  choice_code: "change",
  chosen_math_minutes: 200,
  total_available_minutes: 360,
  p1_minutes: 110,
  p5_minutes: 90,
  study_minutes_per_day: 40,
  study_days_per_week: 5,
  schedule_revision: 4
});

async function clickCase({language="ru",choice="change",row=savedChoice,
  p1="110",p5="90",day="40",days="5"}) {
  let onClick;
  const calls = [];
  const feedback = {textContent:""};
  const button = {
    disabled:false,
    addEventListener(type,handler) {
      assert.equal(type,"click");
      onClick=handler;
    }
  };
  const split = {hidden:false},newtime = {hidden:false};
  const values = {
    "[data-ep-s3-p1]": {value:p1},
    "[data-ep-s3-p5]": {value:p5},
    "[data-ep-s3-daily]": {value:day},
    "[data-ep-s3-days]": {value:days}
  };
  const panel = {
    querySelector(selector) {
      if(selector==="input[name=ep-s3-choice]:checked") return {value:choice};
      if(selector==="[data-ep-s3-save]") return button;
      if(selector==="[data-ep-s3-feedback]") return feedback;
      if(selector==="[data-ep-s3-split]") return split;
      if(selector==="[data-ep-s3-newtime]") return newtime;
      return values[selector] || null;
    },
    querySelectorAll() { return []; }
  };
  const state = {language,busy:false,weeklyChoice:row,s3Retry:null,profile:null};
  const context = {
    state, rootEl:()=>({querySelector:()=>panel}),
    internal: {api:{
      saveWeeklyChoiceS3:async(args,key)=>{calls.push({args,key});return {ok:true,data:{saved:true}};},
      examProfile:async()=>({ok:true,data:{}})
    }},
    key:()=> "s3-ui-work-qa-key-abcdefghijklmnop",
    renderDashboard:async()=>true
  };
  vm.runInNewContext(weeklyCode,context,{filename:"exam-prep-live-extracted.js"});
  context.__bindWeekly();
  assert.equal(typeof onClick,"function","button click handler must be attached");
  await onClick();
  return {calls,feedback:feedback.textContent,buttonDisabled:button.disabled,state};
}

async function main() {
  const cases = [
    ["ru", 3.3333, "3 ч 20 мин"], ["uz",3.3333,"3 soat 20 daq"],
    ["en",3.3333,"3 h 20 min"], ["ru",3.33,"3 ч 20 мин"],
    ["ru",6,"6 ч"], ["uz",0.5,"30 daq"],["en",0.5,"30 min"],
    ["ru",1.9999,"2 ч"],["en",1.0167,"1 h 1 min"]
  ];
  for(const [locale,hours,expected] of cases) checkDuration(locale,hours,expected);
  const blank = checkDuration("ru",null,"");
  assert.equal(blank.__formatMinutes(null),"","unknown time is never zero");
  assert.equal(blank.__formatMinutes(200),"3 ч 20 мин","exact cadence in minutes");

  for(const language of ["ru","uz","en"]) {
    const duplicate = await clickCase({language});
    assert.equal(duplicate.calls.length,0,
      "same displayed choice must not create another S3 row ("+language+")");
    assert(duplicate.feedback.length>15,"saved-choice acknowledgement must be visible");
    const badDaily = await clickCase({
      language,row:{...savedChoice,choice_code:"redistribute",chosen_math_minutes:180},
      day:"36",days:"5",p1:"100",p5:"80"
    });
    assert.equal(badDaily.calls.length,0,"36 minutes is not a valid 5-minute increment");
    assert(/5/.test(badDaily.feedback),
      "wrong daily precision must explain 5-minute rule ("+language+")");
    const valid = await clickCase({
      language,row:{...savedChoice,choice_code:"redistribute",chosen_math_minutes:180},
      day:"40",days:"5",p1:"110",p5:"90"
    });
    assert.equal(valid.calls.length,1,"real change must still be submitted");
    assert.equal(valid.calls[0].args.minutesPerDay,40);
    assert.equal(valid.calls[0].args.daysPerWeek,5);
    assert.equal(valid.calls[0].args.p1Minutes,110);
    assert.equal(valid.calls[0].args.p5Minutes,90);
  }

  const genuineEdit = await clickCase({p1:"115",p5:"85"});
  assert.equal(genuineEdit.calls.length,1,"changed P1/P5 split must remain savable");

  const missing = await clickCase({
    row:{...savedChoice,choice_code:"redistribute",chosen_math_minutes:180},
    p1:"",p5:"180",day:"40",days:"5"
  });
  assert.equal(missing.calls.length,0,"empty minute field is never silently zero");

  const keep = await clickCase({
    choice:"keep",row:{...savedChoice,choice_code:"keep",chosen_math_minutes:180},
    p1:"",p5:"",day:"",days:""
  });
  assert.equal(keep.calls.length,0,"recorded unchanged keep must be a no-op");

  const firstKeep = await clickCase({
    choice:"keep",row:{...savedChoice,choice_code:null,choice_recorded:false,chosen_math_minutes:180},
    p1:"",p5:"",day:"",days:""
  });
  assert.equal(firstKeep.calls.length,1,"first voluntary keep must be recorded");
  console.log("Issue #450 Work S3 UI regression PASS: duplicate no-op, tri-lingual 5-minute error, genuine change, empty input and keep semantics.");
}
main().catch(error=>{console.error(error);process.exitCode=1;});
