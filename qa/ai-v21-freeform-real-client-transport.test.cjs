"use strict";
// Execute the REAL production beta adapter, not a handwritten fake of the
// request algorithm. Local VM only: synthetic user/JWT, no network/secrets.
const {test}=require("node:test"),assert=require("node:assert/strict");
const {readFileSync}=require("node:fs");
const vm=require("node:vm");
const file=readFileSync("iclub-ai-v21-beta-client.js","utf8");
const URL="https://mmmduffgpvwjdpruzikw.supabase.co";
const UID="11111111-1111-4111-8111-111111111111";
const RID="22222222-2222-4222-8222-222222222222";
const KEY="synthetic-anon-public-credential-000";
const TOKEN="synthetic-authenticated-user-session-token-001";
function fixture(flags={}){
 let http=[], prepared=[], consented=flags.consented!==false;
 const sb={
  supabaseUrl:flags.badOrigin?"https://hostile.test":URL,
  supabaseKey:KEY,
  auth:{
   getUser:async()=>({data:{user:{id:UID}},error:null}),
   getSession:async()=>({data:{session:{access_token:
     flags.missingToken?"":TOKEN}},error:null}),
   onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}})
  },
  functions:{
   invoke:async(name,{body})=>{
    prepared.push({name,body});
    if(name!=="iclub-ai-v21-prepared")throw Error("Old SDK FREEFORM invoked");
    return {data:{ok:true,candidate:true,eligible:true,consented},error:null};
   }
  }
 };
 const window={sb,crypto:{randomUUID:()=>RID}};
 const document={
  readyState:"loading",
  getElementById:()=>null,
  addEventListener:()=>{}
 };
 const sandbox={window,document,
  console:{warn:()=>{}},crypto:window.crypto,
  MutationObserver:undefined,
  AbortController,setTimeout,clearTimeout,
  fetch:async(url,opts)=>{
   http.push({url,method:opts.method,headers:opts.headers,
    body:JSON.parse(opts.body),mode:opts.mode,credentials:opts.credentials,
    cache:opts.cache,signal:opts.signal});
   return {ok:true,status:200,json:async()=>({
    ok:true,mode:"generated",provider_called:true,
    academic_state_changed:false,
    message:"Поддержка находится в разделе Профиль — Поддержка."
   })};
  }
 };
 vm.runInNewContext(file,vm.createContext(sandbox),{filename:"iclub-ai-v21-beta-client.js"});
 return {api:window.iClubAiV21BetaClient,http,prepared};
}
test("one consenting General Help question sends a direct authenticated POST with exactly 3 safe headers",async()=>{
 const x=fixture();
 const r=await x.api.askGenerated({requestId:RID,locale:"ru",
  userText:"Где в iClub написать в поддержку?"});
 assert.equal(r.ok,true);
 assert.equal(r.mode,"generated");
 assert.equal(x.http.length,1);
 const p=x.http[0];
 assert.equal(p.url,URL+"/functions/v1/iclub-ai-v21-freeform-beta");
 assert.equal(p.method,"POST");assert.equal(p.mode,"cors");
 assert.equal(p.credentials,"omit");assert.equal(p.cache,"no-store");
 assert.deepEqual(Object.keys(p.headers).sort(),
  ["Authorization","apikey","Content-Type"].sort());
 assert.equal(p.headers.Authorization,"Bearer "+TOKEN);
 assert.equal(p.headers.apikey,KEY);
 assert.deepEqual(p.body,{intent:"ask",request_id:RID,locale:"ru",
  question:"Где в iClub написать в поддержку?"});
 assert.ok(x.prepared.length>=1);
 assert.equal(x.prepared.every(x=>x.name==="iclub-ai-v21-prepared"),true);
});
test("unconsented Free beta is never sent to model endpoint",async()=>{
 const x=fixture({consented:false});
 const r=await x.api.askGenerated({requestId:RID,locale:"ru",
 userText:"Где в iClub написать в поддержку?"});
 assert.equal(r.ok,false);assert.equal(x.http.length,0);
});
test("no live JWT cannot reach paid route",async()=>{
 const x=fixture({missingToken:true});
 const r=await x.api.askGenerated({requestId:RID,locale:"ru",
 userText:"Где в iClub написать в поддержку?"});
 assert.equal(r.ok,false);assert.equal(x.http.length,0);
});
test("unexpected Supabase origin cannot be used for model route",async()=>{
 const x=fixture({badOrigin:true});
 const r=await x.api.askGenerated({requestId:RID,locale:"ru",
 userText:"Где в iClub написать в поддержку?"});
 assert.equal(r.ok,false);assert.equal(x.http.length,0);
});
test("malformed UUID or invalid locale cannot call provider",async()=>{
 const x=fixture();
 const r=await x.api.askGenerated({requestId:"not-an-id",locale:"ru",
 userText:"Где в iClub написать в поддержку?"});
 assert.equal(r.ok,false);
 const z=await x.api.askGenerated({requestId:RID,locale:"xx",
 userText:"Где в iClub написать в поддержку?"});
 assert.equal(z.ok,false);assert.equal(x.http.length,0);
});
