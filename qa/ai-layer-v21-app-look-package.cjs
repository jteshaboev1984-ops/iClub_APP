"use strict";
// Produces one completely offline, reviewable, single-file HTML snapshot.
// Copies the ACTUAL root CSS + logo + 100% detached QA controller.
// Never embeds product app.js, Supabase SDK, credentials or learner data.
const fs=require("node:fs"),path=require("node:path"),assert=require("node:assert/strict");
const root=path.resolve(__dirname,".."),source=path.join(root,"qa/ai-layer-v21-app-look-preview");
const read=file=>fs.readFileSync(file,"utf8");
function offlineHtml(){
 let html=read(path.join(source,"index.html"));
 const styleFiles=[
  ["/style.css","style.css"],
  ["/visual/iclub-visual-v3.css","visual/iclub-visual-v3.css"],
  ["/visual/iclub-premium-v3.css","visual/iclub-premium-v3.css"],
  ["/global-ai-ui.css","global-ai-ui.css"],
  ["/qa/ai-layer-v21-app-look-preview/review.css","qa/ai-layer-v21-app-look-preview/review.css"]
 ];
 for(const [web,file] of styleFiles){
  const anchor='<link rel="stylesheet" href="'+web+'">';
  assert.equal(html.split(anchor).length,2,"stylesheet anchor drift: "+web);
  const css=read(path.join(root,file)).replace(/<\/style/gi,"<\\/style");
  html=html.replace(anchor,"<style>\n"+css+"\n</style>");
 }
 const imageData="data:image/png;base64,"+
   fs.readFileSync(path.join(root,"logo.png")).toString("base64");
 html=html.split('href="/logo.png"').join('href="'+imageData+'"');
 html=html.split('src="/logo.png"').join('src="'+imageData+'"');
 const scriptPath="/qa/ai-layer-v21-app-look-preview/review.js";
 const scriptAnchor='<script src="'+scriptPath+'"></script>';
 assert.equal(html.split(scriptAnchor).length,2,"preview controller script drift");
 const script=read(path.join(source,"review.js")).replace(/<\/script/gi,"<\\/script");
 html=html.replace(scriptAnchor,"<script>\n"+script+"\n</script>");
 const oldCsp="script-src 'self'; style-src 'self'";
 assert.ok(html.includes(oldCsp),"CSP anchor drift");
 html=html.replace(oldCsp,"script-src 'unsafe-inline'; style-src 'unsafe-inline'");
 assert.ok(html.includes("connect-src 'none'"),"offline CSP must block network");
 assert.ok(!html.includes('src="/')&&!html.includes('href="/'),"unresolved absolute resource");
 for(const blocked of ["supabase-js","telegram-web-app.js","localStorage","sessionStorage",
  "XMLHttpRequest","fetch(","WebSocket(","service_role"]){
  assert.ok(!html.includes(blocked),"Unexpected product/network capability: "+blocked);
 }
 return html;
}
function build(target=process.argv[2]){
 if(typeof target!=="string"||!target.startsWith("/tmp/"))
  throw Error("Only disposable /tmp output allowed");
 const output=offlineHtml();
 fs.mkdirSync(path.dirname(target),{recursive:true});
 fs.writeFileSync(target,output,{encoding:"utf8",mode:0o600,flag:"w"});
 console.log("ICLUB_OFFLINE_VISUAL_PREVIEW_GREEN "+target+" "+output.length+" bytes");
 return target;
}
if(require.main===module)build();
module.exports={offlineHtml,build};
