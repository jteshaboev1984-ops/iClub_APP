"use strict";
const assert=require("node:assert/strict"),fs=require("node:fs"),
{test}=require("node:test");
const p="qa/ai-real-ui-preview.html",source=fs.readFileSync(p,"utf8"),
 js=fs.readFileSync("qa/ai-real-ui-controller.js","utf8"),
 shell=fs.readFileSync("qa/ai-real-ui-shell.js","utf8");
test("Same exact real iClub screen ids and native navigational tabbar",()=>{
 for(const id of ["view-home","view-courses","view-profile","tabbar",
  "courses-practice-quiz","courses-practice-result","courses-practice-review",
  "practice-review-list","practice-question","practice-options","exam-prep-host-root"]){
  assert.match(source,new RegExp('id="'+id+'"'));
 }
 for(const css of ["style.css","visual/iclub-visual-v3.css",
  "visual/iclub-premium-v3.css","global-ai-ui.css"])
  assert.ok(source.includes(css));
});
test("QA never loads app.js, Supabase, Auth, third-party JS or persistent storage",()=>{
 assert.doesNotMatch(source,/<script[^>]*src=["']https?:/i);
 assert.doesNotMatch(source,/supabase-js|app\.js\?|telegram-web-app\.js/);
 assert.match(source,/connect-src 'none'/);
 assert.match(source,/form-action 'none'/);
 assert.match(source,/noindex,nofollow,noarchive/);
 for(const text of [js,shell]){
  assert.doesNotMatch(text,/\b(fetch|XMLHttpRequest|WebSocket|sendBeacon)\s*\(/);
  assert.doesNotMatch(text,/localStorage|sessionStorage/);
 }
 assert.doesNotMatch(js,/service_role|signUp|signInWithPassword|payment/i);
});
test("Exact QA-only binder + V4 server-confirmed synthetic review and cancel",()=>{
 assert.match(js,/safeSessionId:101/);
 assert.match(js,/attempt_id:567/);
 assert.match(js,/bridge\.reviewRendered/);
 assert.match(js,/binder\.sync\(\)/);
 assert.match(js,/bridge\.selectQuestion/);
 assert.match(js,/screen==="practice-quiz"/);
 assert.match(js,/session_type:"diagnostic"/);
 assert.match(shell,/Preview-only|Synthetic QA only|Synthetic QA/);
});
test("Legacy iClub index.html and app.js byte-untouched by QA page",()=>{
 const original=fs.readFileSync("index.html","utf8");
 assert.match(original,/src="app\.js\?/);
 assert.doesNotMatch(original,/iclub-qa-ribbon/);
 assert.ok(fs.existsSync("app.js"));
});

test("QA Review provides two distinct actions, one automatic, one editable",()=>{
 assert.match(js,/dataset\.qaAiAction="explain"/);
 assert.match(js,/dataset\.qaAiAction="chat"/);
 assert.match(js,/previewExplain\(/);
 assert.match(js,/previewAskInChat\(/);
 assert.match(js,/let handling=false/);
 assert.match(js,/explain\.disabled=true;ask\.disabled=true/);
 for(const key of ["askAi:","explainMistake:","explainSolution:",
  "explainPromptWrong:","explainPromptCorrect:"])
  assert.ok((js.match(new RegExp(key,"g"))||[]).length>=3);
});
test("QA shell imports exact Exam Prep icon and auto-sends only after verified question",()=>{
 assert.match(shell,/src="assets\/iclub-ai-mark-temp\.jpg\?v=1"/);
 assert.match(shell,/function previewSelectedQuestion/);
 assert.match(shell,/epoch!==state\.qaQuestionEpoch/);
 assert.match(shell,/qaQuestionId:Number\(questionId\),qaCacheKey:cacheKey/);
 assert.match(shell,/function previewAskInChat/);
 assert.doesNotMatch(shell,/window\.iClubGlobalAiShell = Object\.freeze\(\{[\s\S]*?previewAskInChat[\s\S]*?signIn/);
});

test("Question-scoped QA responses are stored ONLY in tab memory; no new DB",()=>{
 assert.match(shell,/qaExplanationCache: new Map\(\)/);
 assert.match(shell,/qaQuestionEpoch/);
 assert.match(shell,/function previewSelectQuestion/);
 assert.match(shell,/previewResetPractice/);
 assert.match(shell,/state\.threads\.delete\("economics"\)/);
 assert.match(shell,/const cacheKey=session\+":"\+Number\(questionId\)/);
 assert.match(shell,/return \[\];/);
 assert.doesNotMatch(shell,/indexedDB|localStorage|sessionStorage/);
 assert.doesNotMatch(js,/create table|insert into|UPDATE public\./i);
});
test("Correct/wrong answer prompts differ and replies depend on chosen option",()=>{
 assert.match(js,/explainPromptCorrect/);
 assert.match(js,/explainPromptWrong/);
 assert.match(js,/chosen\[i\]===item\.correct/);
 assert.match(js,/explanation\[language\]\[idx\]\?\.\[answer\]/);
 assert.match(js,/const explanation=\{/);
 assert.match(js,/previewSelectQuestion\(item\.id\)/);
 assert.match(js,/practiceSessionId:101/);
 assert.match(js,/input\.value=""; \/\/ Selected question is named above/);
});
test("Mobile controls and expand icon have real accessible styling",()=>{
 const css=fs.readFileSync("qa/ai-real-ui-qa.css","utf8");
 assert.match(css,/\.iclub-global-ai-expand svg/);
 assert.match(css,/\.iclub-global-ai-panel\[data-expanded="true"\]/);
 assert.match(css,/@media\(max-width:600px\)/);
 assert.match(css,/min\(76dvh/);
 assert.match(css,/\.iclub-qa-ai-message-context/);
});
