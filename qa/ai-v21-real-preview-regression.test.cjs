"use strict";
// Offline contract for the actual iClub APP QA Preview. NO Supabase, network or users.
// Run from repository root: node --test qa/ai-v21-real-preview-regression.test.cjs
const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const crypto=require("node:crypto");
const vm=require("node:vm");
const {spawnSync}=require("node:child_process");
const root=path.resolve(__dirname,"..");
const read=p=>fs.readFileSync(path.join(root,p),"utf8");
const blobSha=p=>{
  const data=fs.readFileSync(path.join(root,p));
  return crypto.createHash("sha1").update(Buffer.from("blob "+data.length+"\0"))
    .update(data).digest("hex");
};
const app=read("app.js"), index=read("index.html");
const js=read("qa/ai-v21-real-preview-ui-snapshot.js");
const css=read("qa/ai-v21-real-preview-ui-snapshot.css");
const fixture=read("qa/ai-v21-real-preview-fixture.js");
const vercel=JSON.parse(read("vercel.json"));

function shellFor(screen,{title="Biology",hidden=false,skill=""}={}){
  const parts=screen==="home"?"home":"courses";
  const doc={
    readyState:"loading",addEventListener(){},
    querySelector(selector){
      if(selector===".view.is-active")return {dataset:{view:parts}};
      if(selector==="#view-courses .stack-screen.is-active")return {id:"courses-"+screen};
      return null;
    },
    getElementById(id){
      if(id==="subject-hub-title")return {textContent:title};
      if(id==="exam-prep-host-root"&&skill){
        return {hidden, getAttribute:n=>n==="aria-hidden"?"false":null,
          querySelector:()=>({
            getAttribute:n=>n==="data-ep-ai-skill-detail"?skill:"P1"
          })
        };
      }
      return null;
    }
  };
  const window={i18n:{getLang:()=>"ru"}};
  vm.runInNewContext(js,{document:doc,window,setTimeout,clearTimeout,queueMicrotask});
  return window.iClubGlobalAiShell.context();
}

function clientFixture(){
  const store=new Map();
  const storage={
    getItem:key=>store.has(key)?store.get(key):null,
    setItem:(key,value)=>store.set(key,value),
    removeItem:key=>store.delete(key)
  };
  const document={
    body:{appendChild(){}},
    createElement:()=>({setAttribute(){},style:{}}),
    addEventListener(){}
  };
  const window={};
  vm.runInNewContext(fixture,{window,document,localStorage:storage,queueMicrotask});
  return {client:window.supabase.createClient(),profile:store.get("iclub_profile_v1"),window,storage};
}

test("frozen production shell remains unchanged, QA changes stay under qa/",()=>{
  assert.equal(blobSha("global-ai-ui.js"),"023516d2127a838f8b12b398215745304fe11d9e");
  assert.equal(blobSha("global-ai-ui.css"),"27150c82d8204d423f178b56b01715a04cdbc1bc");
  assert.notEqual(js,read("global-ai-ui.js"),"Preview must be separate, never change production UI by import");
  assert.match(js,/iclub-global-ai-mark-logo/);
  assert.match(css,/\.iclub-global-ai-mark-logo/);
  assert.doesNotMatch(read("index.html"),/ai-v21-real-preview-ui-snapshot/);
  assert.doesNotMatch(app,/__ICLUB_AI_QA_PREVIEW__/);
});

test("actual full app is retained, never replaced by a detached replica",()=>{
  for(const id of ["home","courses","ratings","profile"]){
    assert.ok(index.includes('id="view-'+id+'"'),id);
    assert.ok(index.includes('data-tab="'+id+'"'),id);
  }
  for(const nested of ["all-subjects","subject-hub","lessons","practice-start",
    "practice-quiz","practice-result","practice-review","tours",
    "tour-quiz","tour-result","tour-review"]){
    assert.ok(index.includes('id="courses-'+nested+'"'),nested);
  }
  assert.match(index,/src="app\.js\?/);
  assert.match(index,/src="global-ai-ui\.js\?/);
  assert.match(app,/function showCoursesScreen/);
});

test("Vercel Preview blocks external network and indexing at response level",()=>{
  assert.equal(vercel.buildCommand,"node qa/ai-v21-real-preview-build.cjs");
  assert.equal(vercel.outputDirectory,"qa/ai-v21-real-preview-dist");
  const headers=Object.fromEntries(vercel.headers[0].headers.map(x=>[x.key.toLowerCase(),x.value]));
  assert.match(headers["content-security-policy"],/connect-src 'none'/);
  assert.match(headers["content-security-policy"],/form-action 'none'/);
  assert.match(headers["content-security-policy"],/frame-src 'none'/);
  assert.match(headers["content-security-policy"],/object-src 'none'/);
  assert.match(headers["x-robots-tag"],/noindex/);
  assert.match(read("qa/ai-v21-real-preview-build.cjs"),/VERCEL_ENV !== "preview"/);
  assert.match(read("qa/ai-v21-real-preview-build.cjs"),/unauthorized Git branch/);
});

test("real Preview bundler is deterministic, isolated and fails closed",()=>{
  const run=spawnSync(process.execPath,["qa/ai-v21-real-preview-build.cjs"],{
    cwd:root,env:{PATH:process.env.PATH||"",HOME:process.env.HOME||""},
    encoding:"utf8",timeout:120000
  });
  assert.equal(run.status,0,run.stderr);
  assert.match(run.stdout,/BUILD_GREEN/);
  const dist=path.join(root,vercel.outputDirectory);
  assert.equal(fs.readFileSync(path.join(dist,"app.js"),"utf8"),app);
  assert.equal(fs.readFileSync(path.join(dist,"global-ai-ui.js"),"utf8"),js);
  assert.equal(fs.readFileSync(path.join(dist,"global-ai-ui.css"),"utf8"),css);
  const aiAsset=fs.readFileSync(path.join(dist,"iclub-ai-tutor-a.webp"));
  assert.equal(aiAsset.length,3394);
  assert.equal(aiAsset.subarray(0,4).toString("ascii"),"RIFF");
  assert.equal(fs.readFileSync(path.join(dist,"logo.png")).length,
    fs.readFileSync(path.join(root,"logo.png")).length,"Core logo must remain original");
  assert.match(js,/src="iclub-ai-tutor-a\.webp"/);
  assert.doesNotMatch(js,/mark-symbol|src="logo\.png"/);
  const output=fs.readFileSync(path.join(dist,"index.html"),"utf8");
  const expected=index
    .replace('<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>',
      '<script src="ai-v21-real-preview-fixture.js"></script>\n'+
      '<script src="ai-v21-preview-typed-app-help.js"></script>')
    .replace('<script src="https://telegram.org/js/telegram-web-app.js"></script>',
      "<!-- External Telegram SDK disabled in offline QA -->")
    .replace("<head>",'<head>\n<meta http-equiv="Content-Security-Policy" content="'+
      vercel.headers[0].headers.find(h=>h.key==="Content-Security-Policy").value
       .replaceAll("&","&amp;").replaceAll('"',"&quot;")+'">')
    .replace("</body>",'<script src="ai-v21-real-preview-demo.js"></script>\n</body>')
    .replace("</body>",'<script src="ai-v21-appwide-context-help.js"></script>\n</body>');
  assert.equal(output,expected);
  assert.doesNotMatch(output,/cdn\.jsdelivr\.net\/npm\/@supabase/);
  assert.match(output,/<meta http-equiv="Content-Security-Policy"/);
  assert.match(output,/connect-src 'none'/);
  assert.ok(fs.existsSync(path.join(dist,"logo.png")),"Real app logo is preserved elsewhere");
  for(const banned of ["supabase","docs","qa",".github"]){
    assert.equal(fs.existsSync(path.join(dist,banned)),false,banned);
  }
  const again=spawnSync(process.execPath,["qa/ai-v21-real-preview-build.cjs"],{
    cwd:root,env:{PATH:process.env.PATH||"",HOME:process.env.HOME||""},
    encoding:"utf8",timeout:120000
  });
  assert.equal(again.status,0,again.stderr);
  assert.equal(fs.readFileSync(path.join(dist,"index.html"),"utf8"),output);
  assert.equal(fs.readFileSync(path.join(dist,"ai-v21-real-preview-demo.js"),"utf8"),
    read("qa/ai-v21-real-preview-demo.js"));
  assert.doesNotMatch(app,/__ICLUB_AI_QA_DEMO__/);
  assert.match(output,/src="ai-v21-real-preview-demo.js"/);
  assert.equal(fs.readFileSync(path.join(dist,"ai-v21-appwide-context-help.js"),"utf8"),
    read("qa/ai-v21-appwide-context-help.js"));
  assert.match(output,/src="ai-v21-appwide-context-help.js"/);
  assert.equal(fs.readFileSync(path.join(dist,"ai-v21-preview-typed-app-help.js"),"utf8"),
    read("qa/ai-v21-preview-typed-app-help.js"));
  assert.match(output,/src="ai-v21-preview-typed-app-help.js"/);
  assert.doesNotMatch(app,/__ICLUB_AI_QA_TYPED_APP_HELP__/);
  assert.doesNotMatch(app,/__ICLUB_AI_QA_APPWIDE__/);
});

test("QA bundler refuses production or the wrong existing branch",()=>{
  for(const env of [
    {VERCEL:"1",VERCEL_ENV:"production"},
    {VERCEL:"1",VERCEL_ENV:"preview",VERCEL_GIT_COMMIT_REF:"main"}
  ]){
    const r=spawnSync(process.execPath,["qa/ai-v21-real-preview-build.cjs"],{
      cwd:root,env:{PATH:process.env.PATH||"",HOME:process.env.HOME||"",...env},
      encoding:"utf8",timeout:10000
    });
    assert.notEqual(r.status,0);
    assert.match(r.stderr,/must never deploy|unauthorized Git branch/);
  }
});

test("correct screen context survives real Study route transitions",()=>{
  for(const screen of ["all-subjects","subject-hub","lessons","video","practice-start",
   "practice-result","practice-review","practice-recs","tours","tour-rules",
   "tour-result","tour-review","home"]){
    const c=shellFor(screen);
    assert.equal(c.screenCode,screen,screen);
    assert.equal(c.subjectKey,["home","all-subjects"].includes(screen)?"general":"biology",screen);
  }
  // A cached subject title must not pretend the catalogue is the Biology Tutor.
  assert.equal(shellFor("all-subjects",{title:"Biology"}).academic,false);
  assert.equal(shellFor("lessons",{title:"Unverified subject"}).subjectKey,"general");
});

test("Exam Prep P1/P5 skill context cannot be fabricated from wrong prefix",()=>{
  const skill=shellFor("subject-hub",{skill:"P1-ALG-01"});
  assert.equal(skill.scopeCode,"exam_prep");
  assert.equal(skill.componentCode,"P1");
  assert.equal(skill.skillCode,"P1-ALG-01");
  assert.equal(skill.screenCode,"exam_prep_skill");
  const wrong=shellFor("subject-hub",{skill:"P5-STAT-01"});
  assert.notEqual(wrong.scopeCode,"exam_prep");
});

test("Preview session is synthetic and every database mutation is refused",async()=>{
  const x=clientFixture();
  assert.match(x.profile,/Демонстрационный профиль/);
  assert.ok(x.window.__ICLUB_AI_QA_PREVIEW__.noProductionWrites);
  assert.equal((await x.client.auth.getUser()).data.user.id,"00000000-0000-4000-8000-000000000125");
  const query=x.client.from("practice_sessions_v4");
  for(const mutation of [
    query.insert({score:100}),
    query.upsert({score:100}),
    query.update({score:100}).eq("id",7),
    query.delete().eq("id",7),
    x.client.rpc("unknown_unsafe_rpc"),
    x.client.functions.invoke("exam-prep-ai",{body:{}})
  ]){
    const value=await mutation;
    assert.equal(value.data,null);
    assert.ok(value.error,"No DB writes permitted");
  }
});

test("verified-completion policy: no score or per-question explanation is fabricated",async()=>{
  const {client}=clientFixture();
  const invoke=async(screen,prompt_key,locale="ru")=>
    (await client.functions.invoke("global-ai",{
      body:{screen_code:screen,prompt_key,locale,subject_key:"mathematics"}
    })).data;
  for(const locale of ["ru","uz","en"]){
    const before=await invoke("practice-start","practice_rules",locale);
    assert.equal(before.ok,true);
    assert.ok(before.message.length>30);
    assert.equal(before.academic_state_changed,false);
    const result=await invoke("practice-result","practice_result",locale);
    assert.equal(result.ok,false);
    assert.equal(result.reason,"qa_no_verified_result");
    const review=await invoke("practice-review","practice_error",locale);
    assert.equal(review.reason,"qa_no_verified_question");
    const blocked=await invoke("practice-quiz","practice_rules",locale);
    assert.equal(blocked.reason,"active_assessment");
    const tour=await invoke("tour-quiz","tour_rules",locale);
    assert.equal(tour.reason,"active_assessment");
  }
});

test("CSS safeguards active Practice and Tour, and no accidental product logo as AI",()=>{
  assert.match(css,/body:has\(#courses-practice-quiz\.is-active\)/);
  assert.match(css,/body:has\(#courses-tour-quiz\.is-active\)/);
  assert.match(css,/\.iclub-global-ai-mark\[hidden\]/);
  assert.doesNotMatch(js,/button\.innerHTML = ['"].*src=\\?"logo\.png"/);
  assert.match(js,/state\.contextEpoch === sentContextEpoch/);
  assert.match(js,/state\.threads\.clear\(\)/);
});
