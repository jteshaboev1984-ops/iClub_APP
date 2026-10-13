// One QA-only source-overlay assembly. Copies real app sources IN MEMORY;
// original app.js/index.html, production users and Supabase never touched.
"use strict";
const fs=require("node:fs"),path=require("node:path"),
 {createHash}=require("node:crypto"),{tmpdir}=require("node:os");
const root=path.resolve(__dirname,"..");
const sha=s=>createHash("sha256").update(s).digest("hex");
function one(source,anchor,replacement,label){
 const count=source.split(anchor).length-1;
 if(count!==1)throw Error("QA_SOURCE_DRIFT "+label+": "+count);
 return source.replace(anchor,replacement);
}
function assemble({app,index}={}){
 if(typeof app!=="string"||typeof index!=="string")
  throw Error("QA_SOURCE_MISSING");
 if(app.includes("__iclubQaV21Bridge")||
    index.includes("qa/ai-layer-v21-preview-glue.cjs")||
    index.includes("__ICLUB_AI_V21_SYNTHETIC_ONLY__"))
  throw Error("QA_SOURCE_DRIFT already_assembled");
 const before={app:sha(app),index:sha(index)};
 const hooks=[
  ["  function showCoursesScreen(screenName) {\n    COURSES_SCREENS.forEach(sc => {",
   "  function showCoursesScreen(screenName) {\n    try {window.__iclubQaV21Bridge?.screenChanged(screenName);} catch {}\n    COURSES_SCREENS.forEach(sc => {","navigation"],
  ["      quiz._safeFinalizeComplete = true;\n      quiz._safeFinalizeInFlight = false;",
   "      quiz._safeFinalizeComplete = true;\n      try {window.__iclubQaV21Bridge?.finalized({quiz,finalResult,reviewRows});} catch {}\n      quiz._safeFinalizeInFlight = false;","finalize"],
  ["      const safeRows = await safeApi.review(dbAttemptId);\n      renderFromDetails(practiceSafeReviewRowsToDetails(safeRows));",
   "      const safeRows = await safeApi.review(dbAttemptId);\n      renderFromDetails(practiceSafeReviewRowsToDetails(safeRows));\n      try {window.__iclubQaV21Bridge?.reviewRendered({attemptId:dbAttemptId,\n        reviewRows:safeRows,screen:document.getElementById('courses-practice-review')});} catch {}","review"]
 ];
 for(const [find,replacement,label]of hooks)
  app=one(app,find,replacement,label);
 index=one(index,'<script src="app.js?',
  '<!-- QA synthetic copy ONLY, NEVER DEPLOY -->\n'+
  '<script>window.__ICLUB_AI_V21_SYNTHETIC_ONLY__=true;</script>\n'+
  '<script src="qa/ai-layer-v21-evidence-publisher.cjs"></script>\n'+
  '<script src="qa/ai-layer-v21-preview-glue.cjs"></script>\n'+
  '<script src="app.js?',"index_scripts");
 return{app,index,original:before,candidate:{app:sha(app),index:sha(index)},
  hooks:hooks.map(x=>x[2]),status:"OFFLINE_ONLY_NOT_DEPLOYABLE"};
}
function check(){
 const originals={app:fs.readFileSync(path.join(root,"app.js"),"utf8"),
  index:fs.readFileSync(path.join(root,"index.html"),"utf8")};
 const result=assemble(originals);
 const temp=fs.mkdtempSync(path.join(tmpdir(),"iclub-v21-preview-copy-"));
 try{
  fs.writeFileSync(path.join(temp,"app.js"),result.app);
  fs.writeFileSync(path.join(temp,"index.html"),result.index);
  if(sha(fs.readFileSync(path.join(root,"app.js"),"utf8"))!==result.original.app||
     sha(fs.readFileSync(path.join(root,"index.html"),"utf8"))!==result.original.index)
   throw Error("QA_ORIGINAL_FILES_MODIFIED");
 }finally{fs.rmSync(temp,{recursive:true,force:true,maxRetries:3});}
 return{status:result.status,hooks:result.hooks,originalsPreserved:true,
  sourceHashes:result.original};
}
if(require.main===module)console.log(JSON.stringify(check()));
module.exports={assemble,check};
