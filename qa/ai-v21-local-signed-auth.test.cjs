"use strict";
const {test}=require("node:test");
const assert=require("node:assert/strict");
const {makeLocalSignedAuth}=require("./ai-v21-local-signed-auth.cjs");
const A="11111111-1111-4111-8111-111111111111";
const B="22222222-2222-4222-8222-222222222222";
const now=()=>Math.floor(Date.now()/1000);
function auth(){
 const a=process.env.CI,v=process.env.ICLUB_QA_ALLOW_RESOLVER;
 process.env.CI="true";process.env.ICLUB_QA_ALLOW_RESOLVER="synthetic-only";
 try{return makeLocalSignedAuth();}
 finally{if(a===undefined)delete process.env.CI;else process.env.CI=a;
  if(v===undefined)delete process.env.ICLUB_QA_ALLOW_RESOLVER;
  else process.env.ICLUB_QA_ALLOW_RESOLVER=v;}
}
test("local Auth requires explicit synthetic CI safeguard and fresh secret",()=>{
 const save=process.env.ICLUB_QA_ALLOW_RESOLVER;
 delete process.env.ICLUB_QA_ALLOW_RESOLVER;
 assert.throws(()=>makeLocalSignedAuth(),/CI scratch guard/);
 if(save!==undefined)process.env.ICLUB_QA_ALLOW_RESOLVER=save;
 const a=auth(),b=auth(),token=a.sign(A);
 assert.deepEqual(a.verify(token),{id:A,role:"authenticated"});
 assert.equal(b.verify(token),null,"different ephemeral signing key must reject");
});
test("both signed learner tokens resolve only their own sub",()=>{
 const a=auth();
 for(const sub of [A,B]){
  assert.deepEqual(a.verify(a.sign(sub)),{id:sub,role:"authenticated"});
 }
});
test("unsigned token, header alg none, bogus HS256 and tampered subject always reject",()=>{
 const a=auth(),valid=a.sign(A);
 for(const bad of [
  "qa-local-user-a","Bearer "+valid,valid.slice(0,-2)+"xx",
  valid.slice(0,5)+"x"+valid.slice(6),valid+".extra",
  valid.replace(/^[^.]+/,"eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0"),
  valid.slice(0,valid.indexOf("."))+"."+Buffer.from(JSON.stringify({
   sub:B,role:"authenticated",aud:"authenticated",iss:"iclub-qa-local-scratch-only",
   iat:now(),nbf:now(),exp:now()+600
  })).toString("base64url")+"."+valid.split(".")[2],
  "a.b.c","","a".repeat(3300)
 ])assert.equal(a.verify(bad),null,"Invalid/forged JWT unexpectedly trusted");
});
test("role, issuer, audience, expiry, nbf, future iat fail closed",()=>{
 const a=auth(),t=now();
 const alterations=[
  {role:"service_role"},{role:"anon"},{aud:"service_role"},
  {aud:["authenticated"]},{iss:"https://real-project.supabase.co/auth/v1"},
  {exp:t-1,iat:t-601,nbf:t-601},{nbf:t+180},{iat:t+180,nbf:t+180},
  {iat:t-2000,exp:t+2},{exp:t+1800}
 ];
 for(const patch of alterations){
  const token=a.sign(A,patch);
  assert.equal(a.verify(token),null,JSON.stringify(patch));
 }
});
test("exact signer payload is minimal: never includes profile, plan or admin grants",()=>{
 const a=auth(),jwt=a.sign(A);
 const [h,p,sig]=jwt.split(".");
 const hjson=JSON.parse(Buffer.from(h,"base64url").toString("utf8"));
 const pjson=JSON.parse(Buffer.from(p,"base64url").toString("utf8"));
 assert.deepEqual(hjson,{alg:"HS256",typ:"JWT"});
 assert.deepEqual(Object.keys(pjson).sort(),
  ["sub","role","aud","iss","iat","nbf","exp"].sort());
 assert.match(sig,/^[A-Za-z0-9_-]+$/);
 assert.deepEqual(a.verify(jwt),{id:A,role:"authenticated"});
});
