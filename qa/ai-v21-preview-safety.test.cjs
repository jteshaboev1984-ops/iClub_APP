"use strict";
const{test}=require("node:test"),a=require("node:assert/strict"),fs=require("node:fs");
const html=fs.readFileSync("index.html","utf8"),js=fs.readFileSync("qa/ai-v21-native-review.js","utf8");
test("Actual APP and new preview sidecar only",()=>{for(const id of ["view-home","view-courses","view-ratings","view-profile","courses-practice-quiz","courses-tour-quiz","exam-prep-host-root"])a.ok(html.includes('id="'+id+'"'));a.ok(html.includes("qa/ai-v21-native-review.js"));a.ok(html.includes('src="app.js?'));});
test("Preview is gated and never writes or sends user records",()=>{for(const p of [/fetch\s*\(/,/XMLHttpRequest/,/WebSocket\s*\(/,/localStorage/,/sessionStorage/,/indexedDB/,/service_role/,/\.insert\s*\(/,/\.update\s*\(/])a.doesNotMatch(js,p);a.match(js,/\.vercel\\\.app/);a.match(js,/iclub-ai-review/);a.match(js,/liveAI:false,academicWrites:false/);a.match(js,/exam-prep-host-root/);a.match(js,/quiz\|diagnostic\|retest\|timed\|paper\|exam/);});
