"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict");
const {offlineHtml}=require("./ai-layer-v21-app-look-package.cjs");
test("Review page is one offline file with actual app CSS and logo embedded",()=>{
 const page=offlineHtml();
 assert.ok(page.length>180000,"complete app styles missing");
 assert.match(page,/--primary:\s*#2F6FD6/);
 assert.match(page,/iclub-global-ai-mark/);
 assert.match(page,/data:image\/png;base64,/);
 assert.match(page,/body class="iclub-visual-v3"/);
 assert.match(page,/connect-src 'none'/);
 assert.match(page,/script-src 'unsafe-inline'/);
 assert.doesNotMatch(page,/<link rel="stylesheet"/);
 assert.doesNotMatch(page,/<script src=/);
 assert.doesNotMatch(page,/fetch\(|WebSocket\(|localStorage|sessionStorage|supabase-js/);
});
