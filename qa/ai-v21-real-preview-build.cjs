"use strict";
// Real application bundle for the EXISTING QA branch only. NO prod network/DB.
// Reuses the exact root index.html/app.js/styles and asset paths.
const fs=require("node:fs");
const crypto=require("node:crypto");
const path=require("node:path");
const assert=require("node:assert/strict");
const root=path.resolve(__dirname,"..");
const out=path.join(__dirname,"ai-v21-real-preview-dist");
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
for(const name of fs.readdirSync(root)){
  if(banned.has(name)||name.startsWith("."))continue;
  copySafe(path.join(root,name),path.join(out,name));
}
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
assert.ok(html.includes('src="global-ai-ui.js?'),"Must use the real global-ai-ui.js");
html=html.replace(sdk,'<script src="ai-v21-real-preview-fixture.js"></script>');
html=html.replace(telegram,"<!-- External Telegram SDK disabled in offline QA -->");
// Defense-in-depth: local static servers do not set Vercel response headers.
// Inject the *same* CSP as an early meta element before every script or link.
const vercel=JSON.parse(fs.readFileSync(path.join(root,"vercel.json"),"utf8"));
const csp=vercel.headers?.[0]?.headers?.find(h=>
  h.key.toLowerCase()==="content-security-policy")?.value;
assert.ok(csp && csp.includes("connect-src 'none'") &&
  csp.includes("form-action 'none'"),"Missing mandatory no-network CSP");
assert.equal(html.split("<head>").length,2,"Unexpected HTML head structure");
const htmlAttr=String(csp).replaceAll("&","&amp;").replaceAll('"',"&quot;");
html=html.replace("<head>",
  '<head>\n<meta http-equiv="Content-Security-Policy" content="'+htmlAttr+'">');
fs.writeFileSync(indexFile,html);
fs.copyFileSync(path.join(__dirname,"ai-v21-real-preview-fixture.js"),
  path.join(out,"ai-v21-real-preview-fixture.js"));
assert.ok(!html.includes("cdn.jsdelivr.net/npm/@supabase/"),"SDK must be absent");
assert.ok(html.includes('src="app.js?'),"Real product runtime must remain");
console.log("ICLUB_AI_REAL_APP_PREVIEW_BUILD_GREEN: original app shell, offline synthetic data, no production writes");