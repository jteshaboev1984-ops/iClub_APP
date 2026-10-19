"use strict";
// QA only; direct source parity to current pinned main in Git history.
const {test}=require("node:test"),a=require("node:assert/strict");
const fs=require("node:fs"),path=require("node:path"),cp=require("node:child_process");
const root=path.resolve(__dirname,".."),out=path.join(__dirname,"ai-v21-real-preview-dist");
const sha=process.env.ICLUB_QA_MAIN_PARITY_SHA,source=process.env.ICLUB_QA_MAIN_PARITY_SOURCE;
const show=p=>cp.execFileSync("git",["show",sha+":"+p],
  {cwd:root,timeout:10000,maxBuffer:12*1024*1024});
const asset=p=>fs.readFileSync(path.join(out,p));
test("Preview source is an immutable current-main tree, never historical QA",()=>{
  a.match(sha||"",/^[a-f0-9]{40}$/);
  a.ok(source&&fs.statSync(source).isDirectory());
  a.deepEqual(JSON.parse(asset("iclub-ai-main-parity.json").toString()),{
    qaPreviewOnly:true,source:"main",sha,studentDataCopied:false,productionWrites:false
  });
  a.equal(cp.execFileSync("git",["rev-parse","refs/remotes/origin/main"],
    {cwd:root,encoding:"utf8"}).trim(),sha);
});
test("Economics shell, recent Practice tabs and all source code use one main commit",()=>{
  for(const p of ["app.js","i18n.js","style.css",
    "practice-results-tabs.js","practice-results-tabs.css"])
    a.deepEqual(asset(p),show(p),p);
  const html=asset("index.html").toString(),app=asset("app.js").toString();
  const mainHtml=show("index.html").toString();
  const mainSection=x=>x.match(/<main\b[^>]*>[\s\S]*?<\/main>/)?.[0];
  a.ok(mainSection(mainHtml),"Main page has no academic <main>");
  a.equal(mainSection(html),mainSection(mainHtml),
    "QA must retain every current-main academic screen unchanged");
  a.match(app,/practiceAiAttemptId/);
  a.match(html,/id="courses-practice-review"/);
  a.match(html,/practice-results-tabs.js/);
});
test("existing Mathematics Tutor and assessment boundaries remain byte-identical",()=>{
  for(const p of ["exam-prep/exam-prep-live.js","exam-prep/exam-prep-ai-ui.js",
    "exam-prep/exam-prep.css","exam-prep/exam-prep-api.js",
    "security/legacy-assessment-safe-api.js"])a.deepEqual(asset(p),show(p),p);
});
test("only emitted Global AI shell is QA-overlaid and is offline",()=>{
  a.notDeepEqual(asset("global-ai-ui.js"),show("global-ai-ui.js"));
  a.notDeepEqual(asset("global-ai-ui.css"),show("global-ai-ui.css"));
  const h=asset("index.html").toString();
  for(const f of ["ai-v21-real-preview-fixture.js",
    "ai-v21-preview-typed-app-help.js","ai-v21-real-preview-demo.js"])
    a.ok(h.includes(f),f);
  a.doesNotMatch(h,/@supabase\/supabase-js@2|telegram-web-app\.js/);
  a.doesNotMatch(h,/ai-v21-connected-chat-bridge\.js/);
  a.match(h,/connect-src 'none'/);
  a.equal(fs.existsSync(path.join(out,"qa")),false);
  a.equal(fs.existsSync(path.join(out,"supabase")),false);
  a.notDeepEqual(asset("app.js"),fs.readFileSync(path.join(root,"app.js")));
});
test("QA main parity cannot be mistaken for unrestricted deployment",()=>{
  const s=fs.readFileSync(path.join(root,"qa/ai-v21-real-preview-build.cjs"),"utf8");
  a.match(s,/if\(mainSource&&process\.env\.VERCEL\)/);
  a.match(s,/refs\/remotes\/origin\/main/);
  a.match(s,/blobSha\(path\.join\(sourceRoot,file\)\)/);
  a.match(s,/copySafe\(path\.join\(sourceRoot,name\)/);
});
