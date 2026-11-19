"use strict";
// Issue #412 — real iClub Tutor JS in loopback Chromium; mocked server responses.
// Not live-user, live-provider, or authenticated Supabase E2E.
const assert=require("node:assert/strict");
const fs=require("node:fs"),http=require("node:http"),path=require("node:path");
const {chromium}=require("playwright");
const root=path.resolve(__dirname,"..");
const original=fs.readFileSync(path.join(root,"scripts/fixtures/practice-ai-unified-tutor-local-only.html"),"utf8");
const markup=original.replace(
  '<div id="courses-practice-review" class="stack-screen" data-practice-ai-attempt-id="501"></div>',
  '<div id="courses-practice-review" class="stack-screen" data-practice-ai-attempt-id="502"><div id="practice-review-list"><div data-practice-ai-question-id="97">Synthetic completed wrong item</div></div></div>'
);
assert.notEqual(markup,original,"The existing QA fixture must retain its identifiable Review screen");
const client=fs.readFileSync(path.join(root,"iclub-ai-v21-beta-client.js"),"utf8");
const tutor=fs.readFileSync(path.join(root,"iclub-ai-v21-ui.js"),"utf8");
const css=fs.readFileSync(path.join(root,"iclub-ai-v21-ui.css"),"utf8");
const BASE="https://mmmduffgpvwjdpruzikw.supabase.co";
const verified="Проверенный результат: 7 из 10. Обучение продолжается.";
const reviewReply="Подтверждённая ошибка: проверьте применение формулы.";
let web,browser;
async function main(){
  const seen={prepared:[],recoveries:[],academic:[],available:[],external:[],errors:[]};
  try{
    web=http.createServer((req,res)=>{
      res.writeHead(200,{"content-type":"text/html; charset=utf-8","cache-control":"no-store"});
      res.end(markup);
    });
    await new Promise(done=>web.listen(0,"127.0.0.1",done));
    const origin="http://127.0.0.1:"+web.address().port;
    browser=await chromium.launch({headless:true});
    const page=await browser.newPage({viewport:{width:390,height:844}});
    page.on("pageerror",e=>seen.errors.push(e.message));
    await page.addInitScript(()=>{
      window.__qa={lang:"ru",hold:false,release:null,ready:false,academic:[],available:[],
        userId:"00000000-0000-4000-8000-000000000031",authListeners:[]};
      window.i18n={getLang:()=>window.__qa.lang};
      window.sb={
        supabaseUrl:"https://mmmduffgpvwjdpruzikw.supabase.co",
        supabaseKey:"QA_PUBLIC_KEY_"+ "z".repeat(64),
        auth:{
          getUser:async()=>({data:{user:window.__qa.userId?{id:window.__qa.userId}:null},error:null}),
          getSession:async()=>({data:{session:{access_token:"QA_LOCAL_JWT_"+"k".repeat(64)}},error:null}),
          onAuthStateChange:fn=>{
            window.__qa.authListeners.push(fn);
            return {data:{subscription:{unsubscribe(){}}}};
          }
        },
        rpc:async()=>({data:null,error:{message:"No hosted RPC in isolated browser"}}),
        functions:{invoke:async (_name,{body})=>{
          if(body.intent==="status")return {data:{
            ok:true,eligible:true,consented:true,candidate:false},error:null};
          if(body.intent==="academic_available"){
            window.__qa.available.push(body);
            return {data:{ok:true,available:
              body.record_id===502 &&
              window.__qa.userId==="00000000-0000-4000-8000-000000000031"
                ?[97]:[]},error:null};
          }
          if(body.intent==="academic"){
            window.__qa.academic.push(body);
            if(window.__qa.hold){
              window.__qa.ready=true;
              await new Promise(resolve=>{window.__qa.release=resolve;});
            }
            return {data:{ok:true,mode:"prepared",message:"Подтверждённая ошибка: проверьте применение формулы.",
              provider_called:false,academic_state_changed:false},error:null};
          }
          return {data:{ok:false,reason:"isolated_route_not_enabled",
            academic_state_changed:false},error:null};
        }}
      };
    });
    await page.route("**/*",async route=>{
      const url=route.request().url();
      if(url.startsWith(origin+"/"))return route.continue();
      if(url===BASE+"/functions/v1/iclub-ai-practice-prepared"){
        const headers={"content-type":"application/json",
          "access-control-allow-origin":origin,
          "access-control-allow-methods":"POST, OPTIONS",
          "access-control-allow-headers":"authorization, apikey, content-type",
          "vary":"Origin"};
        if(route.request().method()==="OPTIONS")
          return route.fulfill({status:204,headers,body:""});
        const body=route.request().postDataJSON();
        seen.prepared.push(body);
        assert.equal(body.intent,"practice_prepared");
        return route.fulfill({status:200,headers,body:JSON.stringify(
          body.purpose==="practice_visibility"
          ?{ok:true,available:true,mode:"availability",provider_called:false,
              academic_state_changed:false}
          :{ok:true,mode:"verified_summary",message:verified,provider_called:false,
              academic_state_changed:false})});
      }
      // The existing Tutor safely probes canonical PC4 for a previously
      // persisted answer when a verified Practice screen opens. This is
      // a provider-FREE 'resume' read, never a new generated 'ask'.
      if(url===BASE+"/functions/v1/iclub-ai-practice-freeform"){
        const headers={"content-type":"application/json",
          "access-control-allow-origin":origin,
          "access-control-allow-methods":"POST, OPTIONS",
          "access-control-allow-headers":"authorization, apikey, content-type"};
        if(route.request().method()==="OPTIONS")
          return route.fulfill({status:204,headers,body:""});
        const body=route.request().postDataJSON();
        assert.equal(body.operation,"resume",
          "Model dispatch attempted during provider-free Tutor QA");
        seen.recoveries.push(body);
        return route.fulfill({status:409,headers,
          body:JSON.stringify({ok:false,reason:"no_pending_answer",
            provider_called:false,academic_state_changed:false})});
      }
      seen.external.push(url);
      return route.abort("blockedbyclient");
    });
    await page.goto(origin+"/",{waitUntil:"domcontentloaded"});
    await page.addStyleTag({content:css});
    await page.addScriptTag({content:client});
    await page.addScriptTag({content:tutor});
    await page.locator("#iclub-global-ai-mark").waitFor({timeout:8000});
    await page.waitForFunction(()=>window.iClubGlobalAiShell?.context?.().threadKey==="practice_attempt_501",
      null,{timeout:8000});
    await page.evaluate(()=>window.iClubGlobalAiShell.open());
    await page.getByRole("button",{name:"Объяснить результат"}).click({timeout:9000});
    await page.waitForFunction((text)=>document.querySelector("[data-global-ai-messages]")?.textContent?.includes(text),
      verified,{timeout:9000});
    assert(seen.prepared.some(x=>x.purpose==="practice_result"&&x.attempt_ref===501),
      "Real Tutor did not request server-owned completed Practice result");
    assert.equal(await page.locator("[data-global-ai-quick] button").count(),3);
    assert.equal(await page.evaluate(()=>window.iClubGlobalAiShell?.context?.().threadKey),
      "practice_attempt_501");

    // Change attempt number on the SAME Practice screen: UI must close,
    // discard any stale in-flight request and not display attempt 501 results.
    await page.evaluate(()=>document.getElementById("courses-practice-result")
      .dataset.practiceAiAttemptId="502");
    await page.waitForFunction(()=>window.iClubGlobalAiShell?.context?.().threadKey==="practice_attempt_502",
      null,{timeout:8000});
    await page.waitForFunction(()=>document.getElementById("iclub-global-ai-panel")?.hidden===true,
      null,{timeout:8000});
    await page.evaluate(()=>window.iClubGlobalAiShell.open());
    assert.equal((await page.locator("[data-global-ai-messages]").textContent()||"").includes(verified),false,
      "Previous attempt's result was shown in a new attempt's Tutor thread");

    // Same attempt moved into finalized review: server returns only one
    // approved wrong question; actual attached button opens existing Tutor.
    await page.evaluate(()=>{
      document.getElementById("courses-practice-result").classList.remove("is-active");
      document.getElementById("courses-practice-review").classList.add("is-active");
      document.dispatchEvent(new Event("iclub:practice-ai-context-changed"));
    });
    await page.locator('[data-iclub-ai-academic-button="practice_error:502:97"]').waitFor({timeout:9000});
    assert.equal(await page.locator('[data-iclub-ai-academic-button]').count(),1);
    // The floating Tutor panel normally covers content behind it. A real
    // learner closes that panel before pressing a result card's action.
    await page.evaluate(()=>window.iClubGlobalAiShell.close());
    await page.getByRole("button",{name:"Объяснить ошибку"}).click({timeout:8000});
    await page.waitForFunction((text)=>document.querySelector("[data-global-ai-messages]")?.textContent?.includes(text),
      reviewReply,{timeout:8000});
    const selected=await page.evaluate(()=>window.__qa.academic);
    assert(selected.some(x=>x.intent==="academic"&&x.surface==="practice_error"&&
      x.record_id===502&&x.question_id===97),"Server-bounded academic answer not requested");
    assert.equal(await page.locator("[data-global-ai-quick] button").count()<=3,true);
    assert.equal(seen.external.length,0,
      "Unexpected network call from provider-free Tutor: "+JSON.stringify(seen.external));
    assert(seen.recoveries.length>0,"Existing server-side PC4 recovery preflight disappeared");

    // Real browser language mutation must update an already attached button.
    await page.evaluate(()=>{window.__qa.lang="en";document.documentElement.lang="en";});
    await page.getByRole("button",{name:"Explain the mistake"}).waitFor({timeout:8000});
    await page.evaluate(()=>{window.__qa.lang="uz";document.documentElement.lang="uz";});
    await page.getByRole("button",{name:"Xatoni tushuntirish"}).waitFor({timeout:8000});

    // Hold the second provider-free academic response in flight, replace
    // the result with a different attempt and then release the old reply.
    await page.evaluate(()=>{window.__qa.lang="ru";document.documentElement.lang="ru";window.__qa.hold=true;});
    await page.evaluate(()=>window.iClubGlobalAiShell.close());
    await page.getByRole("button",{name:"Объяснить ошибку"}).click({timeout:8000});
    await page.waitForFunction(()=>window.__qa.ready===true,null,{timeout:8000});
    await page.evaluate(()=>document.getElementById("courses-practice-review")
      .dataset.practiceAiAttemptId="503");
    await page.waitForFunction(()=>window.iClubGlobalAiShell.context().threadKey==="practice_attempt_503",
      null,{timeout:8000});
    await page.evaluate(()=>window.__qa.release?.());
    await page.waitForTimeout(250);
    await page.evaluate(()=>window.iClubGlobalAiShell.open());
    assert.equal((await page.locator("[data-global-ai-messages]").textContent()||"").includes(reviewReply),false,
      "Old pending academic reply crossed into another Practice attempt");
    await page.waitForFunction(()=>!document.querySelector('[data-iclub-ai-academic-button="practice_error:502:97"]'),
      null,{timeout:8000});

    // The review DOM can outlive an auth change. A source button authorized
    // for learner A must disappear for learner B even on the same attempt ID.
    await page.evaluate(()=>document.getElementById("courses-practice-review")
      .dataset.practiceAiAttemptId="502");
    await page.locator('[data-iclub-ai-academic-button="practice_error:502:97"]')
      .waitFor({timeout:8000});
    await page.evaluate(()=>{
      window.__qa.userId="00000000-0000-4000-8000-000000000032";
      for(const cb of [...window.__qa.authListeners])
        cb("SIGNED_IN",{user:{id:window.__qa.userId}});
    });
    await page.waitForFunction(()=>!document.querySelector("[data-iclub-ai-academic-button]"),
      null,{timeout:8000});
    await page.waitForTimeout(300);
    assert.equal(await page.locator("[data-iclub-ai-academic-button]").count(),0,
      "Old learner's approved Practice question button survived account switch");

    await page.evaluate(()=>{
      document.getElementById("courses-practice-review").classList.remove("is-active");
      document.getElementById("courses-practice-quiz").classList.add("is-active");
    });
    await page.waitForFunction(()=>document.getElementById("iclub-global-ai-mark")?.hidden===true,
      null,{timeout:8000});
    assert.deepEqual(seen.errors,[],"Unexpected browser JS errors");
    assert.equal(await page.evaluate(()=>localStorage.length),0,"Tutor must not persist academic data locally");
    console.log("PASS: finalized Practice 501 → provider-free verified summary in existing Tutor");
    console.log("PASS: different attempt on same screen uses isolated chat, does not carry old result");
    console.log("PASS: source-approved practice_error 502:97 → same Tutor, RU/EN/UZ action");
    console.log("PASS: held academic reply refused after switch 502→503, stale controls removed");
    console.log("PASS: account 31→32 removes previous learner's approved-source actions");
    console.log("PASS: active Practice quiz hides Tutor; zero external/model network or learner data writes");
  }finally{
    if(browser)await browser.close();
    if(web)await new Promise(done=>web.close(done));
  }
}
main().catch(e=>{console.error("AI TUTOR ATTEMPT BRIDGE BROWSER FAILED",e);process.exitCode=1;});
