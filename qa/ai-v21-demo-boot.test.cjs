"use strict";
const{test}=require("node:test"),a=require("node:assert/strict"),fs=require("node:fs");
const page=fs.readFileSync("ai-visual-review.html","utf8");
const demo=fs.readFileSync("qa/ai-v21-demo-boot.js","utf8");
test("Safe visual snapshot reuses full real native app DOM but strips all real scripts",()=>{
 a.match(page,/id="view-home"/);a.match(page,/id="courses-practice-quiz"/);a.match(page,/id="tabbar"/);
 a.match(page,/visual\/iclub-premium-v3.css/);a.match(page,/connect-src 'none'/);
 a.doesNotMatch(page,/telegram-web-app.js|supabase-js@2|src="app.js\?/);
 a.match(page,/qa\/ai-v21-demo-boot.js/);a.match(page,/qa\/ai-v21-native-review.js/);
});
test("Boot is purely in-memory and has no native data or account interactions",()=>{
 for(const p of [/fetch\s*\(/,/localStorage/,/sessionStorage/,/createClient\s*\(/,/\.from\s*\(/,/\.insert\s*\(/,/\.update\s*\(/])
 a.doesNotMatch(demo,p);
 a.match(demo,/__iclubQaVisualDemo/);
});
