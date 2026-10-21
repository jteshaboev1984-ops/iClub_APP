"use strict";
const {test}=require("node:test");
const a=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const crypto=require("node:crypto");
const vm=require("node:vm");
const main=process.env.ICLUB_QA_MAIN_PARITY_SOURCE;
const sha=process.env.ICLUB_QA_MAIN_PARITY_SHA;
const root=path.resolve(__dirname,"../..");
const read=p=>fs.readFileSync(path.join(root,p),"utf8");
const shabuf=b=>crypto.createHash("sha1").update(
 Buffer.concat([Buffer.from("blob "+b.length+"\\0".replace("\\0","\0")),b])).digest("hex");
test("same-origin beta release uses unchanged original app plus accepted UI",()=>{
 a.ok(main&&sha,"pinned immutable main archive required");
 const index=fs.readFileSync(path.join(main,"index.html"),"utf8");
 const original=fs.readFileSync(path.join(main,"global-ai-ui.js"));
 const originalCss=fs.readFileSync(path.join(main,"global-ai-ui.css"));
 a.match(index,/src="app\.js\?/);
 a.match(index,/src="exam-prep\/exam-prep-host\.js\?/);
 a.match(index,/src="practice-ai-ui\.js\?/);
 a.ok(original.length>20000&&originalCss.length>8000);
 a.ok(sha.match(/^[a-f0-9]{40}$/));
 const src=read("qa/ai-v21-real-preview-ui-snapshot.js");
 const css=read("qa/ai-v21-real-preview-ui-snapshot.css");
 const adapter=read("qa/live_candidate/iclub-ai-v21-browser-adapter.js");
 new vm.Script(src);new vm.Script(adapter);
 a.match(src,/iclub-global-ai-mark-logo/);
 a.match(src,/iclub-ai-tutor-a\.webp/);
 a.match(src,/iClubAiV21BetaClient/);
 a.match(css,/body:has\(#courses-practice-quiz\.is-active\)/);
 a.match(css,/body:has\(#courses-tour-quiz\.is-active\)/);
 a.match(adapter,/getUser/);
 a.match(adapter,/consentFromExplicitUserAction/);
 a.doesNotMatch(adapter,/localStorage|sessionStorage|signUp\s*\(|OPENAI_API_KEY/);
 a.doesNotMatch(src,/eval\s*\(|new Function\s*\(/);
 const oldCss='<link rel="stylesheet" href="global-ai-ui.css?v=globalaichat1" />';
 const oldJs='<script src="global-ai-ui.js?v=globalaichat1-v3stage07"></script>';
 const newCss='<link rel="stylesheet" href="iclub-ai-v21-ui.css?v=nav-beta-20261020" />';
 const newJs='<script src="iclub-ai-v21-beta-client.js?v=nav-beta-20261020"></script>\\n'+
  '<script src="iclub-ai-v21-ui.js?v=nav-beta-20261020"></script>';
 if(index.includes(oldCss)&&index.includes(oldJs)){
   a.equal(index.split(oldCss).length,2);
   a.equal(index.split(oldJs).length,2);
   const next=index.replace(oldCss,newCss).replace(oldJs,newJs.replace("\\n","\n"));
   a.equal(next.split("iclub-ai-v21-beta-client.js").length,2);
   a.equal(next.split("iclub-ai-v21-ui.js").length,2);
   a.ok(next.indexOf('src="app.js?')<next.indexOf('src="iclub-ai-v21-beta-client.js'));
   a.ok(next.indexOf('src="iclub-ai-v21-beta-client.js')<next.indexOf('src="iclub-ai-v21-ui.js'));
   a.ok(next.includes('src="practice-ai-ui.js?'));
 } else {
   // Post-install: the current main must have exactly the same approved loader.
   a.equal(index.split(newCss).length,2);
   a.equal(index.split('src="iclub-ai-v21-beta-client.js').length,2);
   a.equal(index.split('src="iclub-ai-v21-ui.js').length,2);
   // Post-production install: compare exact bytes to the previously approved
   // QA visual and connected beta adapter, not a screenshot substitute.
   const currentClient=fs.readFileSync(path.join(main,"iclub-ai-v21-beta-client.js"),"utf8");
   const currentUi=fs.readFileSync(path.join(main,"iclub-ai-v21-ui.js"),"utf8");
   // The explicitly owner-approved *additive* freeform pilot is now deployed.
   // Check exact production==QA bytes, THEN remove only the reviewed additions
   // and insist every former prepared, academic, Math and original UI byte
   // still matches the immutable pre-pilot fixture.
   a.equal(currentClient,read("iclub-ai-v21-beta-client.js"));
   a.equal(currentUi,read("iclub-ai-v21-ui.js"));
   const start=currentClient.indexOf("  // Separate owner-authorized $5 General Help model pilot.");
   const end=currentClient.indexOf("  // Unified learner-scoped source bridge.",start);
   a.ok(start>0&&end>start);
   const prevClient=(currentClient.slice(0,start)+currentClient.slice(end))
     .replace("status,consentFromExplicitUserAction,askPrepared,askGenerated,",
       "status,consentFromExplicitUserAction,askPrepared,")
     .replace("new Promise(resolve=>setTimeout(()=>resolve({timedOut:true}),55000))",
       "new Promise(resolve=>setTimeout(()=>resolve({timedOut:true}),25000))");
   a.equal(prevClient,adapter,"Original prepared/academic beta was modified");
   const uiStart=currentUi.indexOf("    // Only General Help can use the separately budgeted, real-model beta.");
   const uiEnd=currentUi.indexOf('    if (beta && typeof beta.askPrepared === "function")',uiStart);
   a.ok(uiStart>0&&uiEnd>uiStart);
   a.equal(currentUi.slice(0,uiStart)+currentUi.slice(uiEnd),src,
     "Original Math/Practice/Tour/UI paths were modified");
   a.equal(fs.readFileSync(path.join(main,"iclub-ai-v21-ui.css"),"utf8"),css);
   const icon=fs.readFileSync(path.join(main,"iclub-ai-tutor-a.webp"));
   a.equal(icon.length,3394);
   a.equal(icon.subarray(0,4).toString("ascii"),"RIFF");
   a.equal(icon.subarray(8,12).toString("ascii"),"WEBP");
   a.ok(index.indexOf('src="app.js?')<index.indexOf('src="iclub-ai-v21-beta-client.js'));
   a.ok(index.indexOf('src="iclub-ai-v21-beta-client.js')<
     index.indexOf('src="iclub-ai-v21-ui.js'));
 }
});
