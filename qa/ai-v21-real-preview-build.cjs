"use strict";
// Real application bundle for the EXISTING QA branch only. NO prod network/DB.
// Reuses the exact root index.html/app.js/styles and asset paths.
const fs=require("node:fs");
const crypto=require("node:crypto");
const path=require("node:path");
const {execFileSync}=require("node:child_process");
const assert=require("node:assert/strict");
const root=path.resolve(__dirname,"..");
const out=path.join(__dirname,"ai-v21-real-preview-dist");
// Only opt-in, disposable GitHub Actions main-parity source. Not a deploy.
const mainSource=process.env.ICLUB_QA_MAIN_PARITY_SOURCE||"";
const mainSha=process.env.ICLUB_QA_MAIN_PARITY_SHA||"";
if(Boolean(mainSource)!==Boolean(mainSha))throw Error("Both pinned main SHA and archive required");
if(mainSource&&process.env.VERCEL)throw Error("Main parity is CI-only, never deploy");
if(mainSource&&!/^[a-f0-9]{40}$/.test(mainSha))throw Error("Invalid main SHA");
const sourceRoot=mainSource?fs.realpathSync(mainSource):root;
if(mainSource){
  assert.notEqual(sourceRoot,root,"Cannot overwrite QA source with main archive");
  assert.ok(fs.statSync(sourceRoot).isDirectory());
  const remote=execFileSync("git",["rev-parse","refs/remotes/origin/main"],
    {cwd:root,encoding:"utf8",timeout:8000}).trim();
  assert.equal(remote,mainSha,"Main SHA differs from verified origin/main");
  for(const file of [
    "index.html","app.js","i18n.js","style.css",
    "practice-results-tabs.js","practice-results-tabs.css",
    "global-ai-ui.js","global-ai-ui.css",
    "exam-prep/exam-prep-live.js","exam-prep/exam-prep-ai-ui.js",
    "exam-prep/exam-prep-api.js","exam-prep/exam-prep.css"
  ]){
    const expected=execFileSync("git",["rev-parse",mainSha+":"+file],
      {cwd:root,encoding:"utf8",timeout:8000}).trim();
    assert.equal(blobSha(path.join(sourceRoot,file)),expected,
      "Unverified current-main archive file "+file);
  }
}
if (process.env.VERCEL && process.env.VERCEL_ENV !== "preview") {
  throw Error("QA real-app Preview must never deploy to production/staging");
}
if (process.env.VERCEL_GIT_COMMIT_REF &&
    process.env.VERCEL_GIT_COMMIT_REF !== "qa/iclub-ai-layer-v21-20261012") {
  throw Error("QA Preview build attempted from an unauthorized Git branch");
}
function blobSha(file){
  const bytes=fs.readFileSync(file);
  return crypto.createHash("sha1")
    .update(Buffer.from("blob "+bytes.length+"\0"))
    .update(bytes).digest("hex");
}
const frozen={
  "global-ai-ui.js":"023516d2127a838f8b12b398215745304fe11d9e",
  "global-ai-ui.css":"27150c82d8204d423f178b56b01715a04cdbc1bc"
};
for(const [file,hash] of Object.entries(frozen)) {
  assert.equal(blobSha(path.join(root,file)),hash,
    "QA Preview shell changed; review source before allowing overlay: "+file);
}

const banned=new Set([".git",".github","supabase","docs","qa","node_modules",".vercel",".next","dist"]);
const skipFile=(name)=>name.startsWith(".")||
  /(?:\.md$|\.sql$|\.cjs$|\.map$|\.env|\.yml$|\.yaml$|\.log$|\.zip$|\.pdf$|\.docx$|\.xlsx$)/i.test(name);
function copySafe(src,dest){
  const stat=fs.lstatSync(src);
  if(stat.isSymbolicLink())throw Error("Symlink not permitted in QA Preview: "+src);
  if(stat.isDirectory()){
    fs.mkdirSync(dest,{recursive:true});
    for(const item of fs.readdirSync(src)){
      if(banned.has(item)||item.startsWith("."))continue;
      copySafe(path.join(src,item),path.join(dest,item));
    }
    return;
  }
  if(stat.isFile()&&!skipFile(path.basename(src)))fs.copyFileSync(src,dest);
}
assert.ok(fs.existsSync(path.join(root,"index.html")),"Real app index missing");
assert.ok(fs.existsSync(path.join(root,"app.js")),"Real app engine missing");
assert.ok(fs.existsSync(path.join(root,"global-ai-ui.js")),"Real AI interface missing");
fs.rmSync(out,{recursive:true,force:true});
fs.mkdirSync(out,{recursive:true});
for(const name of fs.readdirSync(sourceRoot)){
  if(banned.has(name)||name.startsWith("."))continue;
  copySafe(path.join(sourceRoot,name),path.join(out,name));
}
if(mainSource)fs.writeFileSync(path.join(out,"iclub-ai-main-parity.json"),
  JSON.stringify({qaPreviewOnly:true,source:"main",sha:mainSha,
    studentDataCopied:false,productionWrites:false},null,2)+"\n");
// The product files remain frozen. Only the emitted disposable Preview
// receives a visually approved QA-only overlay, never imported in main.
for(const [productFile,fixtureFile] of [
  ["global-ai-ui.js","ai-v21-real-preview-ui-snapshot.js"],
  ["global-ai-ui.css","ai-v21-real-preview-ui-snapshot.css"]
]) {
  const src=path.join(__dirname,fixtureFile);
  const dest=path.join(out,productFile);
  assert.ok(fs.existsSync(src),"Missing QA visual overlay: "+fixtureFile);
  const contents=fs.readFileSync(src,"utf8");
  assert.ok(contents.includes("iclub-global-ai-mark-logo"),
    "Architect-approved AI logo marker absent: "+fixtureFile);
  fs.writeFileSync(dest,contents);
}
// Dedicated QA-only approved Option A asset. Product logo.png is untouched.
const aiLogo=path.join(__dirname,"iclub-ai-tutor-a-96.webp");
assert.ok(fs.existsSync(aiLogo),"Approved AI Tutor variant A icon missing");
const asset=fs.readFileSync(aiLogo);
assert.equal(asset.length,3394,"Approved logo asset changed without design approval");
assert.equal(asset.subarray(0,4).toString("ascii"),"RIFF","AI logo must be WebP");
assert.equal(asset.subarray(8,12).toString("ascii"),"WEBP","AI logo content invalid");
fs.writeFileSync(path.join(out,"iclub-ai-tutor-a.webp"),asset);
const indexFile=path.join(out,"index.html");
let html=fs.readFileSync(indexFile,"utf8");
const sdk='<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>';
const telegram='<script src="https://telegram.org/js/telegram-web-app.js"></script>';
assert.equal(html.split(sdk).length,2,"SDK script anchor changed: fail closed");
assert.equal(html.split(telegram).length,2,"Telegram anchor changed: fail closed");
assert.ok(html.includes('src="app.js?'),"Must use the real app.js");
// Current main now includes the approved beta UI and a signed-session
// transport. Offline Chromium deliberately replaces ONLY those two
// bootstrap resources with its pre-existing synthetic QA fixture. It never
// authenticates or accesses a real learner, Supabase or the provider.
if(mainSource && html.includes('src="iclub-ai-v21-ui.js?')){
  const client=/<script src="iclub-ai-v21-beta-client\.js\?[^"]+"><\/script>\s*/g;
  const shell=/src="iclub-ai-v21-ui\.js\?[^"]+"/g;
  const style=/href="iclub-ai-v21-ui\.css\?[^"]+"/g;
  assert.equal((html.match(client)||[]).length,1,
    "Actual main must contain one separately gated client script");
  assert.equal((html.match(shell)||[]).length,1,
    "Actual main must contain one approved AI UI script");
  assert.equal((html.match(style)||[]).length,1,
    "Actual main must contain one approved AI style");
  html=html.replace(client,"");
  html=html.replace(shell,'src="global-ai-ui.js?offline-main-parity"');
  html=html.replace(style,'href="global-ai-ui.css?offline-main-parity"');
  // Never include an authenticated Supabase transport in the disconnected
  // 100% synthetic and CSP-blocked preview.
  fs.rmSync(path.join(out,"iclub-ai-v21-beta-client.js"),{force:true});
}
assert.ok(html.includes('src="global-ai-ui.js?'),"Must load approved offline AI UI");
assert.ok(!html.includes("iclub-ai-v21-beta-client.js"),
  "No signed-session client in disconnected Preview");
const typedHelpSource=path.join(__dirname,"ai-v21-preview-typed-app-help.js");
assert.ok(fs.existsSync(typedHelpSource),"Missing QA typed public-help candidate");
const typedHelp=fs.readFileSync(typedHelpSource,"utf8");
assert.ok(typedHelp.includes("NOT an LLM")&&typedHelp.includes("noProductionWrites===true"),
  "Only explicitly synthetic, local typed help may be emitted");
fs.writeFileSync(path.join(out,"ai-v21-preview-typed-app-help.js"),typedHelp);
html=html.replace(sdk,
  '<script src="ai-v21-real-preview-fixture.js"></script>\n'+
  '<script src="ai-v21-preview-typed-app-help.js"></script>');
html=html.replace(telegram,"<!-- External Telegram SDK disabled in offline QA -->");
// An original, clearly disclosed Practice demonstration runs in the REAL
// app's existing review screen. No detached HTML screens, storage or network.
const demoSrc=path.join(__dirname,"ai-v21-real-preview-demo.js");
assert.ok(fs.existsSync(demoSrc),"Missing protected Practice example");
const demoJs=fs.readFileSync(demoSrc,"utf8");
assert.ok(demoJs.includes("не результат ученика") &&
          demoJs.includes("not a real learner result"),
  "QA demo must disclose that it is an illustrative, non-learner example");
assert.equal(html.split("</body>").length,2,"Unexpected body end");
html=html.replace("</body>",
  '<script src="ai-v21-real-preview-demo.js"></script>\n</body>');
fs.writeFileSync(path.join(out,"ai-v21-real-preview-demo.js"),demoJs);
const appWideFile=path.join(__dirname,"ai-v21-appwide-context-help.js");
assert.ok(fs.existsSync(appWideFile),"QA app-wide contextual helper missing");
const appWideJs=fs.readFileSync(appWideFile,"utf8");
assert.ok(appWideJs.includes("noProductionWrites !== true"),
  "App-wide help must be limited to synthetic no-write Preview");
// This file now updates only the single shell icon's label. Protected
// quiz visibility is still enforced by the actual shell and CSS.
assert.ok(!appWideJs.includes("createHelp(") &&
          appWideJs.includes("iclub-global-ai-mark"),
  "App-wide layer must never inject duplicate in-page buttons");
const liveCss=fs.readFileSync(path.join(out,"global-ai-ui.css"),"utf8");
assert.ok(liveCss.includes("body:has(#courses-practice-quiz.is-active)") &&
          liveCss.includes("body:has(#courses-tour-quiz.is-active)"),
  "AI dock must remain hidden in protected Practice/Tour questions");
assert.equal(html.split("</body>").length,2);
html=html.replace("</body>",
  '<script src="ai-v21-appwide-context-help.js"></script>\n</body>');
fs.writeFileSync(path.join(out,"ai-v21-appwide-context-help.js"),appWideJs);
// This Preview is free-first only: no login button, Auth signup, or paid
// provider bridge. The separate gated backend remains dormant.
assert.ok(!html.includes("ai-v21-connected-chat-bridge.js"),
  "Unexpected paid trial bridge in Preview shell");

// Defense-in-depth: local static servers do not set Vercel response headers.
// Inject the *same* CSP as an early meta element before every script or link.
const vercel=JSON.parse(fs.readFileSync(path.join(root,"vercel.json"),"utf8"));
const csp=vercel.headers?.[0]?.headers?.find(h=>
  h.key.toLowerCase()==="content-security-policy")?.value;
assert.ok(csp && csp.includes("connect-src 'none'") &&
  csp.includes("form-action 'none'") &&
  !csp.includes("connect-src https") && !csp.includes("connect-src *"),
  "Connected QA CSP must allow Supabase ONLY, not arbitrary network");
assert.equal(html.split("<head>").length,2,"Unexpected HTML head structure");
const htmlAttr=String(csp).replaceAll("&","&amp;").replaceAll('"',"&quot;");
html=html.replace("<head>",
  '<head>\n<meta http-equiv="Content-Security-Policy" content="'+htmlAttr+'">');
fs.writeFileSync(indexFile,html);
fs.copyFileSync(path.join(__dirname,"ai-v21-real-preview-fixture.js"),
  path.join(out,"ai-v21-real-preview-fixture.js"));
assert.ok(!html.includes("cdn.jsdelivr.net/npm/@supabase/"),"SDK must be absent");
assert.ok(html.includes('src="app.js?'),"Real product runtime must remain");
console.log("ICLUB_AI_REAL_APP_PREVIEW_BUILD_GREEN: synthetic academic screens; free prepared iClub guidance only"+(mainSource?" MAIN_PARITY_SHA="+mainSha:""));