"use strict";
/**
 * Disposable QA-only local Auth service: real HMAC-SHA256 signed JWT check.
 * NOT Supabase Auth/GoTrue, NOT real keys, NOT a production JWT verifier.
 * Fresh random key per scratch CI run. This module is never bundled by Vercel.
 */
const {createHmac,timingSafeEqual,randomBytes}=require("node:crypto");
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const ISSUER="iclub-qa-local-scratch-only";
const AUDIENCE="authenticated";
const HEADER=Object.freeze({alg:"HS256",typ:"JWT"});
const strict=(value,fields)=>value&&typeof value==="object"&&!Array.isArray(value)&&
 Object.keys(value).length===fields.length&&fields.every(f=>Object.hasOwn(value,f));
const encode=(x)=>Buffer.from(JSON.stringify(x),"utf8").toString("base64url");
const b64=/^[A-Za-z0-9_-]+$/;
const decode=(s)=>{
 if(typeof s!=="string"||s.length<2||s.length>2400||!b64.test(s))return null;
 try{
  const raw=Buffer.from(s,"base64url");
  if(raw.toString("base64url")!==s)return null;
  const obj=JSON.parse(raw.toString("utf8"));
  return obj&&typeof obj==="object"&&!Array.isArray(obj)?obj:null;
 }catch{return null;}
};
function makeLocalSignedAuth(){
 if(process.env.CI!=="true"||process.env.ICLUB_QA_ALLOW_RESOLVER!=="synthetic-only")
  throw Error("QA signed Auth requires CI scratch guard");
 const secret=randomBytes(32);
 const signature=(unsigned)=>createHmac("sha256",secret).update(unsigned).digest();
 function sign(sub,{iat,exp,nbf,role="authenticated",aud=AUDIENCE,iss=ISSUER}={}){
  if(!UUID.test(sub))throw Error("invalid synthetic subject");
  const now=Math.floor(Date.now()/1000);
  const payload={sub,role,aud,iss,iat:iat??now,nbf:nbf??(iat??now),exp:exp??(now+600)};
  const unsigned=encode(HEADER)+"."+encode(payload);
  return unsigned+"."+signature(unsigned).toString("base64url");
 }
 function verify(token){
  if(typeof token!=="string"||token.length>3200||token.length<30)return null;
  const parts=token.split(".");
  if(parts.length!==3||!parts.every(x=>b64.test(x)))return null;
  const header=decode(parts[0]),payload=decode(parts[1]);
  if(!strict(header,["alg","typ"])||header.alg!=="HS256"||header.typ!=="JWT"||
     !strict(payload,["sub","role","aud","iss","iat","nbf","exp"])||
     !UUID.test(payload.sub)||payload.role!=="authenticated"||
     payload.aud!==AUDIENCE||payload.iss!==ISSUER||
     ![payload.iat,payload.nbf,payload.exp].every(Number.isSafeInteger))
    return null;
  const now=Math.floor(Date.now()/1000);
  if(payload.iat>now+15||payload.nbf>now||payload.exp<=now||
     payload.exp<=payload.iat||payload.exp-payload.iat>900)return null;
  let received;
  try{received=Buffer.from(parts[2],"base64url");}catch{return null;}
  const computed=signature(parts[0]+"."+parts[1]);
  if(received.length!==computed.length||
     !timingSafeEqual(received,computed))return null;
  return Object.freeze({id:payload.sub,role:"authenticated"});
 }
 // Only local tests may create tokens. None of the signing machinery is
 // exported to a learner-facing browser or deployed Edge runtime.
 return Object.freeze({sign,verify});
}
module.exports={makeLocalSignedAuth};
