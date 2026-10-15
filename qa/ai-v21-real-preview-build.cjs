"use strict";
// Real application bundle for the EXISTING QA branch only. NO prod network/DB.
// Reuses the exact root index.html/app.js/styles and asset paths.
const fs=require("node:fs");
const path=require("node:path");
const assert=require("node:assert/strict");
const root=path.resolve(__dirname,"..");
const out=path.join(__dirname,"ai-v21-real-preview-dist");
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
fs.writeFileSync(indexFile,html);
fs.copyFileSync(path.join(__dirname,"ai-v21-real-preview-fixture.js"),
  path.join(out,"ai-v21-real-preview-fixture.js"));
assert.ok(!html.includes("cdn.jsdelivr.net/npm/@supabase/"),"SDK must be absent");
assert.ok(html.includes('src="app.js?'),"Real product runtime must remain");
console.log("ICLUB_AI_REAL_APP_PREVIEW_BUILD_GREEN: original app shell, offline synthetic data, no production writes");