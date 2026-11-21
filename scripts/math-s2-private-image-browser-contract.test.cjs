"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");

const moduleSource = fs.readFileSync("security/math-s2-private-images.js","utf8");
const app = fs.readFileSync("app.js","utf8");
const html = fs.readFileSync("index.html","utf8");
const sql = fs.readFileSync("supabase/candidates/math_s2_private_images_v1_uninstalled.sql","utf8");
const oldGuard = fs.readFileSync("supabase/candidates/math_s2_legacy_preflight_shutdown_v1_hold.sql","utf8");
assert(html.indexOf('security/math-s2-private-images.js') < html.indexOf('src="app.js'), "private JS must load before app");
assert(app.includes("privateS2.existingAttempt(tour.id)"), "existing server attempt recovery missing");
assert(app.includes("privateS2.hydrateIssuedQuestions("), "private binary stage missing");
assert(app.includes('const safePreflight = await privateS2.preflight(tour.id);'), "private preflight missing");
assert(app.indexOf('privateS2.hydrateIssuedQuestions(') > app.indexOf('tourApi.questions(Number(startResult?.attempt_id))'), "image bytes retrieved before attempt");
assert(app.includes('window.iclubMathS2PrivateImages?.ownBlobUrl(raw)'), "owned blob URL guard missing");
assert(app.includes('if (mathS2) {\n      const existingId'), "S2 resume not isolated");
assert(oldGuard.includes("math_s2_questions_require_started_attempt"), "cached old clients must be denied before attempt");
assert(sql.includes("storage.allow_only_operation('object.get_authenticated')"), "Storage read route not narrowly authorized");
assert(sql.includes("r.finalized_at IS NULL"), "finalized attempts retain private download access");
assert(!moduleSource.includes("createSignedUrl(") && !moduleSource.includes("getPublicUrl("), "public/bearer asset URL leak");

async function run() {
  const requested = [], revoked = [];
  let failImage = false, failRPC = null, foreignAsset = false;
  const manifestPath = "s2/math/sample.png";
  const rpcCalls = [];
  const rows = Array.from({length: 20}, (_,index) => ({
    id: index+1, question_text_en: "SYNTHETIC", image_url: index===0 ? "https://example.invalid/legacy-public.png" : null
  }));
  const client = {
    from(name) { assert.equal(name, "seasons"); return {
      select(key){assert.equal(key,"season_no");return this;},
      eq(key,value){assert.equal(key,"id");assert.equal(value,902);return this;},
      async maybeSingle(){return {data:{season_no:2},error:null};}
    }; },
    async rpc(name,args) {
      rpcCalls.push(name);
      if (failRPC===name) return {data:null,error:{message:"synthetic denied"}};
      if (name==="get_math_s2_tour_preflight_v1") return {data:{ready:true,question_count:20,image_count:1},error:null};
      if (name==="get_math_s2_resume_attempt_v1") return {data:7001,error:null};
      if (name==="get_math_s2_image_manifest_v1") return {
        data:[{question_id:foreignAsset?999:1,object_path:manifestPath}],error:null
      };
      throw new Error("Unexpected RPC: "+name);
    },
    storage:{ from(bucket){assert.equal(bucket,"iclub-math-s2-private");return {
      async download(path){
        requested.push(path);
        return failImage ? {data:null,error:{message:"synthetic broken"}} :
          {data:{size:1200,type:"image/png"},error:null};
      }
    };}}
  };
  const window = {sb:client,addEventListener(){}};
  class FakeImage {
    constructor(){this.naturalWidth=0;this.complete=false;}
    set src(value) {
      this.naturalWidth = value.startsWith("blob:synthetic:") ? 64 : 0;
      this.complete = true;
      queueMicrotask(() => {if(this.naturalWidth && this.onload)this.onload();else if(this.onerror)this.onerror();});
    }
  }
  let lastUrl=0;
  const context = vm.createContext({
    window,Image:FakeImage,setTimeout,clearTimeout,
    URL:{createObjectURL(){return "blob:synthetic:"+ ++lastUrl;},revokeObjectURL(url){revoked.push(url);}}
  });
  vm.runInContext(moduleSource,context,{filename:"math-s2-private-images.js"});
  const api=window.iclubMathS2PrivateImages;
  assert.equal(await api.isMathSeason2(5,902),true);
  assert.equal(await api.isMathSeason2(4,902),false);
  const pre=await api.preflight(71);
  assert.equal(pre.imageCount,1);
  assert.equal(requested.length,0,"no pre-attempt image bytes");
  assert.equal(await api.existingAttempt(71),7001);
  const hydrated=await api.hydrateIssuedQuestions(7001,rows,1);
  assert.equal(hydrated.length,20);
  assert.equal(hydrated[0].image_url,"blob:synthetic:1");
  assert.equal(hydrated[1].image_url,null);
  assert(api.ownBlobUrl(hydrated[0].image_url));
  assert.equal(requested[0],manifestPath);
  assert(!hydrated.some(x => String(x.image_url||"").startsWith("https:")),"public URL must never reach S2 renderer");
  failImage=true;
  await assert.rejects(api.hydrateIssuedQuestions(7001,rows,1),/math_s2_private_image_unavailable/);
  failImage=false;
  foreignAsset=true;
  await assert.rejects(api.hydrateIssuedQuestions(7001,rows,1),/math_s2_manifest_cross_attempt/);
  foreignAsset=false;
  failRPC="get_math_s2_tour_preflight_v1";
  await assert.rejects(api.preflight(71),/math_s2_secure_service_unavailable/);
  api.releaseImages();
  assert.deepEqual(revoked,["blob:synthetic:1"]);
  assert(rpcCalls.includes("get_math_s2_resume_attempt_v1"));
  console.log("PASS: protected S2 browser source + preflight, owner resume, exact private image decode, public fallback denied, failure/revocation");
}
run().catch(e=>{console.error(e);process.exitCode=1;});
